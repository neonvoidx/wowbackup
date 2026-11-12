local addon = _G.EnhanceQoL
local C = { version = 2, blockLines = 128, blockBytes = 65536, maxBytes = 16 * 1024 * 1024, maxBlocks = 4096, maxManifest = 1024 * 1024, cacheLimit = 16, readCacheBlocks = 128, readCacheBytes = 8 * 1024 * 1024 }
addon.ChatHistoryCodec = C
local serializer = LibStub("AceSerializer-3.0")
local deflate = LibStub("LibDeflate")

function C.Pack(value, level)
	local raw = serializer:Serialize(value)
	local compressed = deflate:CompressDeflate(raw, { level = level or 1 })
	-- Verify before replacing a previously saved block, including during migration.
	assert(deflate:DecompressDeflate(compressed) == raw, "Chat history compression verification failed")
	return tostring(deflate:Adler32(raw)) .. ":" .. deflate:EncodeForPrint(compressed), raw
end

function C.Unpack(data)
	if type(data) ~= "string" then return nil end
	local checksum, encoded = data:match("^(%d+):(.*)$")
	if not checksum then return nil end
	local compressed = deflate:DecodeForPrint(encoded)
	if not compressed then return nil end
	local raw = deflate:DecompressDeflate(compressed)
	if not raw or deflate:Adler32(raw) ~= tonumber(checksum) then return nil end
	local ok, value = serializer:Deserialize(raw)
	if ok and type(value) == "table" then return value, raw end
end

function C.Copy(value, leaves, depth)
	if type(value) ~= "table" then return value end
	depth = (depth or 0) + 1
	assert(depth <= 20, "Chat history metadata is too deeply nested")
	local result = {}
	for key, child in pairs(value) do
		if not (leaves[value] and (key == "lines" or key == "timestamps" or type(key) == "number")) then result[key] = C.Copy(child, leaves, depth) end
	end
	return result
end

function C.At(root, path)
	local value = root
	for _, key in ipairs(path) do
		if type(value) ~= "table" then return nil end
		value = value[key]
	end
	return value
end

function C.Streams(root, kind)
	local streams = {}
	if kind == "im" then
		for key, lines in pairs(root) do
			if type(lines) == "table" then streams[#streams + 1] = { bucket = lines, path = { key } } end
		end
	else
		for faction, realms in pairs(root) do
			if type(realms) == "table" then
				for realm, realmData in pairs(realms) do
					if type(realmData) == "table" then
						for character, characterData in pairs(realmData.characters or {}) do
							for channel, bucket in pairs(characterData.channels or {}) do
								streams[#streams + 1] = { bucket = bucket, path = { faction, realm, "characters", character, "channels", channel } }
							end
						end
					end
				end
			end
		end
	end
	return streams
end

function C.Same(left, right)
	if type(left) ~= type(right) then return false end
	if type(left) ~= "table" then return left == right end
	for key, value in pairs(left) do if not C.Same(value, right[key]) then return false end end
	for key in pairs(right) do if left[key] == nil then return false end end
	return true
end

function C.BlockInfo(block, payload)
	local latest = 0
	for index, item in ipairs(payload.items) do
		local stamp = type(item) == "table" and item.time or payload.timestamps and payload.timestamps[index]
		if type(stamp) == "number" then latest = math.max(latest, stamp) end
	end
	if block.first == payload.first and block.count == #payload.items and block.latest == latest then return block end
	return { data = block.data, time = block.time, first = payload.first, count = #payload.items, latest = latest }
end

function C.EncodeLines(bucket, kind, previous, pause)
	local lines = kind == "im" and bucket or bucket.lines
	local blocks, index = {}, 1
	while index <= #lines do
		local payload = { first = index, items = {}, timestamps = kind == "im" and {} or nil }
		local size, stamp = 0, nil
		repeat
			local item = lines[index]
			local bytes = #serializer:Serialize(item)
			if #payload.items > 0 and size + bytes > C.blockBytes then break end
			payload.items[#payload.items + 1] = item
			local time = kind == "im" and bucket.timestamps and bucket.timestamps[index] or type(item) == "table" and item.time
			if payload.timestamps then payload.timestamps[#payload.items] = bucket.timestamps and bucket.timestamps[index] or false end
			if type(time) == "number" then stamp = stamp and math.min(stamp, time) or time end
			size, index = size + bytes, index + 1
		until index > #lines or #payload.items >= C.blockLines
		local old = previous and previous[#blocks + 1]
		local oldPayload = old and C.Unpack(old.data)
		if oldPayload and C.Same(oldPayload, payload) then
			blocks[#blocks + 1] = C.BlockInfo(old, payload)
		else
			blocks[#blocks + 1] = C.BlockInfo({ data = C.Pack(payload), time = stamp or 0 }, payload)
		end
		if pause then pause() end
	end
	return blocks
end

function C.Restore(bucket, kind, blocks)
	local items, timestamps, valid, damaged, normalized = {}, {}, 0, false, false
	for _, block in ipairs(blocks) do
		local ok, payload = pcall(C.Unpack, block.data)
		if ok and payload and type(payload.first) == "number" and payload.first >= 1 and payload.first % 1 == 0 and type(payload.items) == "table" and #payload.items <= C.blockLines then
			for offset, item in ipairs(payload.items) do
				local index = payload.first + offset - 1
				if index <= 100000 and ((kind == "im" and type(item) == "string") or (kind == "channel" and type(item) == "table")) then
					items[index] = item
					timestamps[index] = payload.timestamps and payload.timestamps[offset] or false
					valid = valid + 1
				else
					damaged = true
				end
			end
		else
			damaged = true
		end
	end
	if kind == "im" then
		for key in pairs(bucket) do if type(key) == "number" then bucket[key] = nil end end
		bucket.timestamps = {}
		local indices = {}
		for index in pairs(items) do indices[#indices + 1] = index end
		table.sort(indices)
		for _, index in ipairs(indices) do
			bucket[#bucket + 1] = items[index]
			bucket.timestamps[#bucket] = timestamps[index]
		end
	elseif valid ~= (bucket._count or valid) or damaged then
		-- Missing/corrupt blocks leave holes in a ring. Keep surviving lines in order.
		normalized = true
		local ordered = {}
		local cap, head = bucket._cap or valid, bucket._head or 1
		for offset = 0, math.min(cap, 100000) - 1 do
			local item = items[(head + offset - 1) % cap + 1]
			if item then ordered[#ordered + 1] = item end
		end
		items = ordered
		bucket._count, bucket._head, bucket._cap = #items, 1, #items
	end
	if kind == "channel" then rawset(bucket, "lines", items) end
	return damaged or normalized
end

function C.Budget(envelopes)
	local bytes, candidates = 0, {}
	for _, envelope in ipairs(envelopes) do
		bytes = bytes + #envelope.manifest
		for _, entry in ipairs(envelope.entries) do
			for _, block in ipairs(entry.blocks) do
				bytes = bytes + #block.data
				candidates[#candidates + 1] = { entry = entry, block = block }
			end
		end
	end
	local count = #candidates
	if bytes <= C.maxBytes and count <= C.maxBlocks then return {}, bytes, count end
	table.sort(candidates, function(a, b) return a.block.time < b.block.time end)
	local removed = {}
	for _, candidate in ipairs(candidates) do
		if bytes <= C.maxBytes and count <= C.maxBlocks then break end
		removed[candidate.block] = true
		bytes, count = bytes - #candidate.block.data, count - 1
	end
	for _, envelope in ipairs(envelopes) do
		for _, entry in ipairs(envelope.entries) do
			local keep = {}
			for _, block in ipairs(entry.blocks) do if not removed[block] then keep[#keep + 1] = block end end
			entry.blocks = keep
		end
	end
	assert(bytes <= C.maxBytes, "Chat history metadata exceeds storage budget")
	return removed, bytes, count
end
