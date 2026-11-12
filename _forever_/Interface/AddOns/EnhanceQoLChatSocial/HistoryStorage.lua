local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.variables = addon.variables or {}
local C = addon.ChatHistoryCodec
local S = { states = setmetatable({}, { __mode = "k" }), imGeneration = 0, clock = 0, interval = 0, manifests = {}, readCache = {}, readBytes = 0, readCount = 0 }
addon.ChatHistoryStorage = S
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

function S.MarkChannelDirty(bucket)
	local state = S.states[bucket]
	if state then
		S.clock = S.clock + 1
		state.generation, state.access = state.generation + 1, S.clock
	end
end

function S.MarkIMDirty() S.imGeneration = S.imGeneration + 1 end

function S.ReadClock() return debugprofilestop() end

function S.ReadCheckpoint(force)
	if S.readerThread and coroutine.running() == S.readerThread and (force or S.ReadClock() >= S.readDeadline) then coroutine.yield() end
end

function S.TrimReadCache()
	while S.readCount > C.readCacheBlocks or S.readBytes > C.readCacheBytes do
		local oldestData, oldest
		for data, entry in pairs(S.readCache) do
			if not oldest or entry.access < oldest.access then oldestData, oldest = data, entry end
		end
		if not oldest then return end
		S.readCache[oldestData] = nil
		S.readCount, S.readBytes = S.readCount - 1, S.readBytes - oldest.bytes
	end
end

function S.ReadBlock(block)
	if type(block) ~= "table" or type(block.data) ~= "string" then return nil end
	S.clock = S.clock + 1
	local entry = S.readCache[block.data]
	if entry then entry.access = S.clock; return entry.payload or nil end
	local ok, payload, raw = pcall(C.Unpack, block.data)
	if not ok or not payload or type(payload.first) ~= "number" or payload.first < 1 or payload.first % 1 ~= 0 or type(payload.items) ~= "table" or #payload.items > C.blockLines then payload, raw = nil, nil end
	entry = { payload = payload or false, bytes = raw and #raw or 0, access = S.clock }
	S.readCache[block.data] = entry
	S.readCount, S.readBytes = S.readCount + 1, S.readBytes + entry.bytes
	S.TrimReadCache()
	-- At most one newly decoded message block per reader continuation.
	S.ReadCheckpoint(true)
	return payload
end

function S.ReadLine(bucket, index)
	S.ReadCheckpoint(false)
	local lines = rawget(bucket, "lines")
	if lines then return lines[index] end
	local state = S.states[bucket]
	if not state then return bucket.lines and bucket.lines[index] end
	state.info = state.info or {}
	for _, block in ipairs(state.blocks) do
		local info = state.info[block.data] or block
		local payload
		if not info.first or not info.count then
			payload = S.ReadBlock(block)
			if payload then info = C.BlockInfo(block, payload); state.info[block.data] = info end
		end
		if info.first and index >= info.first and index < info.first + info.count then
			payload = payload or S.ReadBlock(block)
			local item = payload and payload.items[index - payload.first + 1]
			return type(item) == "table" and item or nil
		end
	end
end

function S.LatestTime(bucket)
	local state = S.states[bucket]
	if not state or state.generation ~= state.savedGeneration then return math.huge end
	local latest = 0
	for _, block in ipairs(state.blocks) do
		local info = state.info and state.info[block.data] or block
		if type(info.latest) ~= "number" then return math.huge end
		latest = math.max(latest, info.latest)
	end
	return latest
end

function S.Attach(bucket, blocks)
	local state = { blocks = blocks, generation = 0, savedGeneration = 0, access = 0 }
	S.states[bucket] = state
	setmetatable(bucket, { __index = function(_, key)
		if key ~= "lines" then return end
		S.clock = S.clock + 1
		state.access = S.clock
		if C.Restore(bucket, "channel", state.blocks) then state.generation = state.generation + 1 end
		return rawget(bucket, "lines")
	end })
	return state
end

function S.Decode(saved, kind)
	if saved.format == nil then return saved end
	assert(saved.format == C.version, "Unsupported chat history storage version")
	local manifest = C.Unpack(saved.manifest)
	assert(manifest and type(manifest.root) == "table" and type(manifest.paths) == "table" and type(saved.entries) == "table", "Invalid chat history manifest")
	assert(#manifest.paths <= 2048 and #saved.entries == #manifest.paths, "Invalid chat history stream count")
	S.manifests[kind] = { value = C.Copy(manifest, {}), data = saved.manifest }
	local root = manifest.root
	for index, path in ipairs(manifest.paths) do
		assert(type(path) == "table" and #path == (kind == "im" and 1 or 6), "Invalid chat history path")
		local bucket, entry = C.At(root, path), saved.entries[index]
		assert(type(bucket) == "table" and type(entry) == "table" and type(entry.blocks) == "table", "Invalid chat history stream")
		if kind == "channel" then
			S.Attach(bucket, entry.blocks)
		else
			local damaged = C.Restore(bucket, kind, entry.blocks)
			S.states[bucket] = { blocks = entry.blocks, savedGeneration = damaged and -1 or S.imGeneration }
		end
	end
	return root
end

function S.TrimStreams(root, kind)
	local streams = C.Streams(root, kind)
	if #streams > 2048 then
		table.sort(streams, function(a, b) return (a.bucket.lastUpdated or (a.bucket.timestamps and a.bucket.timestamps[#a.bucket]) or 0) > (b.bucket.lastUpdated or (b.bucket.timestamps and b.bucket.timestamps[#b.bucket]) or 0) end)
		for index = #streams, 2049, -1 do
			local path, parent = streams[index].path, root
			for part = 1, #path - 1 do parent = parent[path[part]] end
			parent[path[#path]] = nil
			if kind == "channel" and next(parent) == nil then
				local realms = root[path[1]]
				local realm = realms[path[2]]
				realm.characters[path[4]] = nil
				if next(realm.characters) == nil then realms[path[2]] = nil end
				if next(realms) == nil then root[path[1]] = nil end
			end
			streams[index] = nil
		end
	end
	return streams
end

function S.EvictCache()
	local cached = {}
	for bucket, state in pairs(S.states) do
		if state.generation and rawget(bucket, "lines") and state.savedGeneration == state.generation then cached[#cached + 1] = { bucket = bucket, state = state } end
	end
	table.sort(cached, function(a, b) return (a.state.access or 0) > (b.state.access or 0) end)
	for index = C.cacheLimit + 1, #cached do rawset(cached[index].bucket, "lines", nil) end
	if #cached > C.cacheLimit then addon.ChatIM.ChannelHistory.runtime.eqolIndex = nil end
end

function S.Build(pause)
	local envelopes, pending, manifests = {}, {}, {}
	for index, kind in ipairs({ "im", "channel" }) do
		local root = kind == "im" and addon.ChatIM.history or addon.ChatIM.ChannelHistory.history
		local streams, leaves = S.TrimStreams(root, kind), {}
		for _, stream in ipairs(streams) do leaves[stream.bucket] = true end
		local skeleton, paths, entries = C.Copy(root, leaves), {}, {}
		for _, stream in ipairs(streams) do
			local bucket = stream.bucket
			local state = S.states[bucket]
			if not state then
				state = { generation = kind == "channel" and 0 or nil }
				S.states[bucket] = state
			end
			local generation = kind == "im" and S.imGeneration or state.generation
			local snapshot = bucket
			if state.savedGeneration ~= generation then
				-- A bounded stream snapshot lets compression yield between blocks while
				-- incoming messages continue changing the live ring independently.
				if kind == "channel" then local _ = bucket.lines end
				snapshot = C.Copy(bucket, {})
				state.blocks = C.EncodeLines(snapshot, kind, state.blocks, pause)
				state.savedGeneration = generation
			end
			local snapshotLeaves = { [snapshot] = true }
			local copy, parent = C.Copy(snapshot, snapshotLeaves), skeleton
			for part = 1, #stream.path - 1 do parent = parent[stream.path[part]] end
			parent[stream.path[#stream.path]] = copy
			paths[#paths + 1] = stream.path
			local blocks = {}
			for blockIndex, block in ipairs(state.blocks) do
				-- Persist only indexes learned through actual reads. Idle saves must
				-- never deserialize an old archive merely to enrich its metadata.
				blocks[blockIndex] = state.info and state.info[block.data] or block
			end
			local entry = { blocks = blocks }
			entries[#entries + 1] = entry
			pending[#pending + 1] = { bucket = bucket, state = state, entry = entry, kind = kind }
			if pause then pause() end
		end
		local value = { root = skeleton, paths = paths }
		local previous = S.manifests[kind]
		local manifest
		if previous and C.Same(previous.value, value) then
			manifest = previous.data
		else
			-- Metadata is small relative to message blocks. Stored DEFLATE blocks
			-- avoid a synchronous compression spike and retain format compatibility.
			local raw
			manifest, raw = C.Pack(value, 0)
			assert(#raw <= C.maxManifest, "Chat history manifest exceeds metadata budget")
		end
		manifests[kind] = { value = value, data = manifest }
		envelopes[index] = { format = C.version, manifest = manifest, entries = entries }
	end
	local removed, bytes, blocks = C.Budget(envelopes)
	-- Publish only fully encoded and verified snapshots. Runtime tables never enter SV.
	_G.EnhanceQoL_IMHistory, _G.EnhanceQoL_ChannelHistory = envelopes[1], envelopes[2]
	if S.privateDB then S.privateDB.chatSocialHistoryMigration = nil end
	S.bytes, S.blocks, S.manifests = bytes, blocks, manifests
	for _, item in ipairs(pending) do
		local changed = false
		for _, block in ipairs(item.state.blocks) do if removed[block] then changed = true; break end end
		item.state.blocks = item.entry.blocks
		if changed and item.state.savedGeneration == (item.kind == "im" and S.imGeneration or item.state.generation) then
			if item.kind == "im" then
				C.Restore(item.bucket, "im", item.state.blocks)
			else
				rawset(item.bucket, "lines", nil)
			end
		end
		if item.kind == "channel" and not getmetatable(item.bucket) then
			local generation, saved = item.state.generation, item.state.savedGeneration
			item.state = S.Attach(item.bucket, item.state.blocks)
			item.state.generation, item.state.savedGeneration = generation, saved
		end
	end
	addon.ChatIM.ChannelHistory.runtime = addon.ChatIM.ChannelHistory.runtime or {}
	addon.ChatIM.ChannelHistory.runtime.eqolIndex = nil
	S.EvictCache()
end

function S.Report(message)
	S.lastError = tostring(message)
	if geterrorhandler then geterrorhandler()(S.lastError) end
end

function S.Step()
	if not S.worker then return end
	local ok, message = coroutine.resume(S.worker)
	if not ok then S.worker = nil; S.Report(message); return end
	if coroutine.status(S.worker) == "dead" then S.worker = nil end
end

function S.Flush()
	S.lastError = nil
	while S.worker do
		S.Step()
		if S.lastError then return false, S.lastError end
	end
	S.lastError = nil
	local ok, message = pcall(S.Build)
	if not ok then S.Report(message) end
	return ok, message
end

-- Called after the central loader returns, or by ADDON_LOADED for other loaders.
-- A listener created while Core handles ADDON_LOADED can miss the nested event.
function addon.functions.InitializeChatSocialHistory()
	if addon.variables.chatSocialSavedVariablesReady then return end
	local privateDB = addon.functions.GetPrivateDB()
	local legacy = privateDB.chatSocialHistoryMigration
	local im = type(_G.EnhanceQoL_IMHistory) == "table" and _G.EnhanceQoL_IMHistory or type(legacy) == "table" and legacy.EnhanceQoL_IMHistory or {}
	local channel = type(_G.EnhanceQoL_ChannelHistory) == "table" and _G.EnhanceQoL_ChannelHistory or type(legacy) == "table" and legacy.EnhanceQoL_ChannelHistory or {}
	-- Decode both before changing runtime ownership or removing a staged migration.
	local runtimeIM, runtimeChannel = S.Decode(im, "im"), S.Decode(channel, "channel")
	addon.ChatIM.history, addon.ChatIM.ChannelHistory.history = runtimeIM, runtimeChannel
	S.privateDB = privateDB
	addon.variables.chatSocialSavedVariablesReady = true
	frame:UnregisterEvent("ADDON_LOADED")
	frame:RegisterEvent("PLAYER_LOGOUT")
	addon.functions.InitChatSocial()
	S.worker = coroutine.create(function() S.Build(coroutine.yield) end)
	frame:SetScript("OnUpdate", function(_, elapsed)
		S.interval = S.interval + elapsed
		if S.interval >= 15 and not S.worker then
			S.interval = 0
			S.worker = coroutine.create(function() S.Build(coroutine.yield) end)
		end
		S.Step()
	end)
end

frame:SetScript("OnEvent", function(_, event, loadedAddon)
	if event == "PLAYER_LOGOUT" then
		S.Flush()
	elseif loadedAddon == addonName then
		addon.functions.InitializeChatSocialHistory()
	end
end)
