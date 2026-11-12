local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.ChatIM = addon.ChatIM or {}
local ChatIM = addon.ChatIM

function ChatIM:UsesSurnames() return addon.variables and addon.variables.isForever and not addon.variables.isTBC end

function ChatIM:NormalizeCharacterName(name, realm)
	if issecretvalue and issecretvalue(name) then return end
	if type(name) ~= "string" or name == "" then return name end
	if self:UsesSurnames() then
		-- Old conversations and player links may still contain an appended realm.
		local character, suffix = name:match("^(.-)%-([^%-]+)$")
		if suffix and (suffix == (GetRealmName() or ""):gsub("%s+", "") or suffix:match("^CAMWOW")) then return character end
		return name
	end
	if not name:find("-", 1, true) then name = name .. "-" .. (realm or GetRealmName()):gsub("%s+", "") end
	return name
end

function ChatIM:GetNameDisplay(name, isBN, mode)
	if not isBN and self:UsesSurnames() then return self:NormalizeCharacterName(name) end
	return Ambiguate(name, mode or "short")
end

function ChatIM:NormalizeHistoryCharacters()
	if not self:UsesSurnames() or not self.history then return end
	local oldKeys = {}
	for name in pairs(self.history) do
		if type(name) == "string" and not name:find("#", 1, true) and self:NormalizeCharacterName(name) ~= name then oldKeys[#oldKeys + 1] = name end
	end
	for _, oldName in ipairs(oldKeys) do
		local name = self:NormalizeCharacterName(oldName)
		local lines = self.history[oldName]
		if type(lines) == "table" then
			if addon.ChatHistoryStorage then addon.ChatHistoryStorage.MarkIMDirty() end
			local history = self.history[name]
			if not history then
				self.history[name] = lines
			else
				history.timestamps = history.timestamps or {}
				for index = #history.timestamps + 1, #history do history.timestamps[index] = false end
				for index, line in ipairs(lines) do
					history[#history + 1] = line
					history.timestamps[#history] = lines.timestamps and lines.timestamps[index] or false
				end
			end
			self.history[oldName] = nil
		end
	end
end
