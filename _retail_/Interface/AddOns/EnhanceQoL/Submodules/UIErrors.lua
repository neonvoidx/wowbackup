local _, addon = ...

local UIErrors = {}
addon.UIErrors = UIErrors

UIErrors.entries = {
	{ key = "ERR_SPELL_OUT_OF_RANGE", label = "ERR_SPELL_OUT_OF_RANGE" },
	{ key = "ERR_OUT_OF_RANGE", label = "ERR_OUT_OF_RANGE" },
	{ key = "ERR_USE_TOO_FAR", label = "ERR_USE_TOO_FAR" },
	{ key = "ERR_BADATTACKFACING", label = "ERR_BADATTACKFACING" },
	{ key = "ERR_BADATTACKPOS", label = "ERR_BADATTACKPOS" },
	{ key = "ERR_OUT_OF_MANA", label = "ERR_OUT_OF_MANA" },
	{ key = "ERR_OUT_OF_RAGE", label = "ERR_OUT_OF_RAGE" },
	{ key = "ERR_OUT_OF_FOCUS", label = "ERR_OUT_OF_FOCUS" },
	{ key = "ERR_OUT_OF_ENERGY", label = "ERR_OUT_OF_ENERGY" },
	{ key = "ERR_OUT_OF_CHI", label = "ERR_OUT_OF_CHI" },
	{ key = "ERR_OUT_OF_RUNIC_POWER", label = "ERR_OUT_OF_RUNIC_POWER" },
	{ key = "ERR_OUT_OF_HOLY_POWER", label = "ERR_OUT_OF_HOLY_POWER" },
	{ key = "ERR_OUT_OF_MAELSTROM", label = "ERR_OUT_OF_MAELSTROM" },
	{ key = "ERR_OUT_OF_INSANITY", label = "ERR_OUT_OF_INSANITY" },
	{ key = "ERR_OUT_OF_ARCANE_CHARGES", label = "ERR_OUT_OF_ARCANE_CHARGES" },
	{ key = "ERR_OUT_OF_FURY", label = "ERR_OUT_OF_FURY" },
	{ key = "ERR_OUT_OF_PAIN", label = "ERR_OUT_OF_PAIN" },
	{ key = "ERR_OUT_OF_COMBO_POINTS", label = "ERR_OUT_OF_COMBO_POINTS" },
	{ key = "ERR_GENERIC_NO_TARGET", label = "ERR_GENERIC_NO_TARGET" },
	{ key = "ERR_NO_ATTACK_TARGET", label = "ERR_NO_ATTACK_TARGET" },
	{ key = "ERR_GENERIC_NO_VALID_TARGETS", label = "ERR_GENERIC_NO_VALID_TARGETS" },
	{ key = "ERR_INVALID_ATTACK_TARGET", label = "ERR_INVALID_ATTACK_TARGET" },
	{ key = "ERR_ITEM_COOLDOWN", label = "ERR_ITEM_COOLDOWN" },
	{ key = "ERR_SPELL_COOLDOWN", label = "ERR_SPELL_COOLDOWN" },
	{ key = "ERR_ABILITY_COOLDOWN", label = "ERR_ABILITY_COOLDOWN" },
	{ key = "ERR_POTION_COOLDOWN", label = "ERR_POTION_COOLDOWN" },
	{ key = "ERR_NOEMOTEWHILERUNNING", label = "ERR_NOEMOTEWHILERUNNING" },
	{ key = "ERR_NO_ITEMS_WHILE_SHAPESHIFTED", label = "ERR_NO_ITEMS_WHILE_SHAPESHIFTED" },
	{ key = "ERR_PET_SPELL_OUT_OF_RANGE", label = "ERR_PET_SPELL_OUT_OF_RANGE" },
	{ key = "ERR_PET_SPELL_NOT_BEHIND", label = "ERR_PET_SPELL_NOT_BEHIND" },
	{ key = "ERR_PET_SPELL_NOPATH", label = "ERR_PET_SPELL_NOPATH" },
	{ key = "ERR_NOT_ENOUGH_MONEY", label = "ERR_NOT_ENOUGH_MONEY" },
	{ key = "ERR_NOT_EQUIPPABLE", label = "ERR_NOT_EQUIPPABLE" },
	{ key = "ERR_CANT_STACK", label = "ERR_CANT_STACK" },
	{ key = "ERR_CANT_SWAP", label = "ERR_CANT_SWAP" },
	{ key = "ERR_ITEM_MAX_COUNT", label = "ERR_ITEM_MAX_COUNT" },
}
UIErrors.previousEnabledByID = {}
UIErrors.knownKeys = {}
for _, entry in ipairs(UIErrors.entries) do
	UIErrors.knownKeys[entry.key] = true
end

function UIErrors:InitDB()
	if not addon.db then return end
	local defaults = {}
	for _, entry in ipairs(self.entries) do
		defaults[entry.key] = true
	end
	addon.functions.InitDBValue("uiErrorFilterEnabled", false)
	addon.functions.InitDBValue("uiErrorFilterMessages", defaults)
	if type(addon.db.uiErrorFilterMessages) ~= "table" then addon.db.uiErrorFilterMessages = defaults end
	for key in pairs(defaults) do
		if addon.db.uiErrorFilterMessages[key] == nil then addon.db.uiErrorFilterMessages[key] = true end
	end
end

function UIErrors:IsMessageEnabled(key)
	if not self.knownKeys[key] then return false end
	local choices = addon.db and addon.db.uiErrorFilterMessages
	return type(choices) ~= "table" or choices[key] ~= false
end

function UIErrors:Restore()
	if not self.frame then return end
	for messageID, enabled in pairs(self.previousEnabledByID) do
		self.frame:SetMessageTypeEnabled(messageID, enabled)
		self.previousEnabledByID[messageID] = nil
	end
end

function UIErrors:Apply()
	self:InitDB()
	local frame = _G.UIErrorsFrame
	if self.frame and self.frame ~= frame then self:Restore() end
	self.frame = frame
	if not (frame and frame.SetMessageTypeEnabled and frame.ShouldDisplayMessageType) then return end
	if not (addon.db and addon.db.uiErrorFilterEnabled == true) then
		self:Restore()
		return
	end

	for _, entry in ipairs(self.entries) do
		local messageID = _G["LE_GAME_" .. entry.key]
		if not (_G.issecretvalue and _G.issecretvalue(messageID)) and type(messageID) == "number" then
			local previous = self.previousEnabledByID[messageID]
			if self:IsMessageEnabled(entry.key) then
				if previous == nil then
					-- Empty text avoids matching and flashing an existing error while querying the native filter.
					-- Leave the type alone if another handler or restricted text prevents a reliable result.
					local ok, enabled = pcall(frame.ShouldDisplayMessageType, frame, messageID, "")
					if ok and not (_G.issecretvalue and _G.issecretvalue(enabled)) and type(enabled) == "boolean" then
						self.previousEnabledByID[messageID] = enabled
						frame:SetMessageTypeEnabled(messageID, false)
					end
				end
			elseif previous ~= nil then
				frame:SetMessageTypeEnabled(messageID, previous)
				self.previousEnabledByID[messageID] = nil
			end
		end
	end
end

function UIErrors:SetEnabled(enabled)
	self:InitDB()
	if not addon.db then return end
	addon.db.uiErrorFilterEnabled = enabled == true
	self:Apply()
end

function UIErrors:SetMessageEnabled(key, enabled)
	if not self.knownKeys[key] then return end
	self:InitDB()
	if not addon.db then return end
	addon.db.uiErrorFilterMessages[key] = enabled == true
	self:Apply()
end
