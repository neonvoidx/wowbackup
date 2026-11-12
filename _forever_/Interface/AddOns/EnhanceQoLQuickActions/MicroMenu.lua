local addon = _G.EnhanceQoL
local QC = addon.QuickCast
local L = _G.LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local isForever = addon.variables and addon.variables.isForever
local isTBC = addon.variables and addon.variables.isTBC
local MicroMenu = { tabButtons = {} }
QC.MicroMenu = MicroMenu

MicroMenu.order = {
	"character", "spellbook", "talents", "achievements", "quests", "groupFinder", "guild", "social",
	"collections", "adventureGuide", "professions", "calendar", "worldMap", "housing", "shop", "macros", "gameMenu",
}

MicroMenu.definitions = {
	character = { label = "CHARACTER_BUTTON", atlas = "hud-microbutton-Character-Up", button = "CharacterMicroButton" },
	spellbook = { label = "SPELLBOOK", atlas = "UI-HUD-MicroMenu-SpellbookAbilities-Up", tab = "spellBookTabID" },
	talents = { label = "TALENT_FRAME_TAB_LABEL_TALENTS", atlas = "UI-HUD-MicroMenu-SpecTalents-Up", tab = "talentTabID" },
	achievements = { label = "ACHIEVEMENT_BUTTON", atlas = "UI-HUD-MicroMenu-Achievements-Up", button = "AchievementMicroButton" },
	quests = { label = "QUESTLOG_BUTTON", atlas = "UI-HUD-MicroMenu-Questlog-Up", button = "QuestLogMicroButton" },
	groupFinder = { label = "DUNGEONS_BUTTON", atlas = "UI-HUD-MicroMenu-Groupfinder-Up", button = "LFDMicroButton" },
	guild = { label = "GUILD_AND_COMMUNITIES", atlas = "UI-HUD-MicroMenu-GuildCommunities-Up", button = "GuildMicroButton" },
	social = { label = "SOCIAL_BUTTON", icon = "Interface\\Icons\\UI_Chat", fallback = true, gameRule = "IngameFriendsListDisabled" },
	collections = { label = "COLLECTIONS", atlas = "UI-HUD-MicroMenu-Collections-Up", button = "CollectionsMicroButton" },
	adventureGuide = { label = "ADVENTURE_JOURNAL", atlas = "UI-HUD-MicroMenu-AdventureGuide-Up", button = "EJMicroButton", unsupportedInForever = true },
	professions = { label = "PROFESSIONS_BUTTON", atlas = "UI-HUD-MicroMenu-Professions-Up", button = "ProfessionMicroButton" },
	calendar = { labelKey = "Calendar", atlas = "ui-hud-calendar-1-up", button = "GameTimeFrame" },
	worldMap = { label = "WORLD_MAP", atlas = "completiondialog-dragonflightcampaign-adventuremode-icon" },
	housing = { label = "HOUSING_MICRO_BUTTON", atlas = "UI-HUD-MicroMenu-Housing-Up", button = "HousingMicroButton", unsupportedInForever = true },
	shop = { label = "BLIZZARD_STORE", atlas = "UI-HUD-MicroMenu-Shop-Up", button = "StoreMicroButton" },
	macros = { label = "MACROS", icon = "Interface\\Icons\\INV_Misc_Note_06", fallback = true, gameRule = "MacrosDisabled" },
	gameMenu = { label = "MAINMENU_BUTTON", atlas = "UI-HUD-MicroMenu-GameMenu-Up", fallback = true },
}

if isTBC then
	MicroMenu.order = { "character", "spellbook", "talents", "quests", "guild", "social", "worldMap", "macros" }
	MicroMenu.definitions.spellbook.label = "SPELLBOOK_ABILITIES_BUTTON"
	MicroMenu.definitions.talents.label = "TALENTS"
	MicroMenu.definitions.guild.label = "GUILD"
	MicroMenu.definitions.character.fallback = true
	MicroMenu.definitions.worldMap.button = "WorldMapMicroButton"
	MicroMenu.definitions.social = { label = "SOCIAL_BUTTON", button = "SocialsMicroButton" }
	local icons = {
		character = "INV_Misc_GroupLooking", spellbook = "INV_Misc_Book_09", talents = "Ability_Marksmanship",
		quests = "INV_Misc_Book_08", guild = "INV_Shirt_GuildTabard_01", social = "UI_Chat",
		worldMap = "INV_Misc_Map_01", gameMenu = "INV_Misc_Gear_01",
	}
	for id, icon in pairs(icons) do
		MicroMenu.definitions[id].atlas = nil
		MicroMenu.definitions[id].icon = "Interface\\Icons\\" .. icon
	end
elseif isForever then
	MicroMenu.order = { "character", "spellbook", "talents", "quests", "groupFinder", "guild", "social", "collections", "professions", "calendar", "worldMap", "shop", "macros", "gameMenu" }
end

if isForever or isTBC then
	local supported = {}
	for _, id in ipairs(MicroMenu.order) do supported[id] = MicroMenu.definitions[id] end
	MicroMenu.definitions = supported
	MicroMenu.definitions.spellbook.tab = nil
	MicroMenu.definitions.spellbook.button = "SpellbookMicroButton"
	MicroMenu.definitions.talents.tab = nil
	MicroMenu.definitions.talents.button = "TalentMicroButton"
end

function MicroMenu:GetTarget(id)
	local definition = self.definitions[id]
	if not definition then return nil end
	if isForever and definition.unsupportedInForever then return nil end
	if definition.tab then return _G.PlayerSpellsMicroButton end
	if id == "worldMap" and not definition.button then return _G.MinimapCluster and _G.MinimapCluster.ZoneTextButton end
	return definition.button and _G[definition.button] or nil
end

function MicroMenu:GetInfo(id)
	local definition = self.definitions[id]
	if not definition then return nil, nil, false end
	local label = definition.labelKey and L[definition.labelKey] or _G[definition.label]
	local atlas = definition.atlas
	if id == "calendar" and _G.C_DateAndTime and _G.C_DateAndTime.GetCurrentCalendarTime then
		local date = _G.C_DateAndTime.GetCurrentCalendarTime()
		local day = date and date.monthDay
		if type(day) == "number" and day >= 1 and day <= 31 and day == math.floor(day) then atlas = string.format("ui-hud-calendar-%d-up", day) end
	end
	return label or id, definition.icon, true, id, atlas
end

function MicroMenu:GetAvailability(id)
	local definition = self.definitions[id]
	local unavailable = L["QuickCastMicroMenuUnavailable"] or "This menu is currently unavailable."
	if not definition then return false, unavailable end
	if _G.DISALLOW_FRAME_TOGGLING
		or (_G.AreAllPanelsDisallowed and _G.AreAllPanelsDisallowed())
		or (_G.Kiosk and _G.Kiosk.IsEnabled())
		or (_G.KeybindFrames_InQuickKeybindMode and _G.KeybindFrames_InQuickKeybindMode())
	then
		return false, unavailable
	end
	local gameRule = definition.gameRule and _G.Enum and _G.Enum.GameRule and _G.Enum.GameRule[definition.gameRule]
	if gameRule and _G.C_GameRules and _G.C_GameRules.IsGameRuleActive and _G.C_GameRules.IsGameRuleActive(gameRule) then return false, unavailable end
	if definition.fallback then
		if id == "character" and not _G.ToggleCharacter then return false, unavailable end
		if id == "gameMenu" and not (_G.GameMenuFrame and _G.GameMenuFrame_Show and _G.HideUIPanel) then return false, unavailable end
		if id == "social" and not (_G.ToggleFriendsFrame and _G.FRIEND_TAB_FRIENDS) then return false, unavailable end
		if id == "macros" and not (_G.ShowMacroFrame and _G.HideUIPanel) then return false, unavailable end
		if _G.UnitAffectingCombat("player") or _G.InCombatLockdown() then return false, _G.ERR_NOT_IN_COMBAT end
		return true
	end
	local target = self:GetTarget(id)
	if not target or (target.IsEnabled and not target:IsEnabled()) then return false, unavailable end
	if definition.tab then
		local frame = _G.PlayerSpellsFrame
		if frame and frame.IsTabAvailable and not frame:IsTabAvailable(frame[definition.tab]) then return false, unavailable end
		if (_G.UnitAffectingCombat("player") or _G.InCombatLockdown()) and not self.tabButtons[id] then
			return false, L["QuickCastMicroMenuLoadFirst"] or "Open this menu once outside combat before using it in combat."
		end
	end
	return true
end

function MicroMenu:AddTooltip(tooltip, id)
	local available, reason = self:GetAvailability(id)
	if not available and reason then tooltip:AddLine(reason, 1, 0.35, 0.35, true) end
end

function MicroMenu:PrepareTabButton(id)
	if _G.InCombatLockdown() then return self.tabButtons[id] end
	local definition = self.definitions[id]
	local frame = definition and definition.tab and _G.PlayerSpellsFrame
	local tabID = frame and frame[definition.tab]
	local target = tabID and frame.GetTabButton and frame:GetTabButton(tabID)
	if not (target and _G.PlayerSpellsFrameCloseButton and self:GetTarget(id)) then return nil end
	local button = self.tabButtons[id]
	if not button then
		button = _G.CreateFrame("Button", "EQOLQuickActionsMicroMenuTab_" .. id, _G.UIParent, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
		button:RegisterForClicks("AnyUp")
		button:SetAttribute("useOnKeyDown", false)
		button:WrapScript(button, "OnClick", [=[
			local tab = self:GetFrameRef("tab")
			if not tab or not tab:IsVisible() then return false end
			return "LeftButton"
		]=])
		button:Hide()
		self.tabButtons[id] = button
	end
	button:SetAttribute("type", "click")
	button:SetAttribute("clickbutton", target)
	button:SetFrameRef("tab", target)
	return button
end

function MicroMenu:ActivateFallback(id)
	local available, reason = self:GetAvailability(id)
	if not available or _G.InCombatLockdown() then
		if reason and _G.UIErrorsFrame then _G.UIErrorsFrame:AddMessage(reason, 1, 0.2, 0.2) end
		return false
	end
	if id == "character" and isTBC then
		_G.ToggleCharacter("PaperDollFrame")
		return true
	elseif id == "gameMenu" then
		if _G.GameMenuFrame:IsShown() then
			_G.HideUIPanel(_G.GameMenuFrame)
		else
			if _G.SettingsPanel and _G.SettingsPanel:IsShown() then _G.SettingsPanel:Hide() end
			if _G.CloseMenus then _G.CloseMenus() end
			if _G.CloseAllWindows then _G.CloseAllWindows() end
			_G.GameMenuFrame_Show()
		end
		return true
	elseif id == "social" then
		_G.ToggleFriendsFrame(_G.FRIEND_TAB_FRIENDS)
		return true
	elseif id == "macros" then
		if _G.MacroFrame and _G.MacroFrame:IsShown() then
			_G.HideUIPanel(_G.MacroFrame)
		else
			_G.ShowMacroFrame()
		end
		return true
	end
	local definition = self.definitions[id]
	if not (definition and definition.tab) then return false end
	if not _G.PlayerSpellsFrame and _G.PlayerSpellsFrame_LoadUI then _G.PlayerSpellsFrame_LoadUI() end
	local frame = _G.PlayerSpellsFrame
	local util = _G.PlayerSpellsUtil
	if not (frame and util and util.TogglePlayerSpellsFrame and util.FrameTabs) then return false end
	local tab = id == "spellbook" and util.FrameTabs.SpellBook or util.FrameTabs.ClassTalents
	util.TogglePlayerSpellsFrame(tab)
	self:PrepareTabButton("spellbook")
	self:PrepareTabButton("talents")
	if QC.QueueSecureRebuild then QC:QueueSecureRebuild() end
	return true
end

function MicroMenu:ConfigureButton(button, id)
	local definition = self.definitions[id]
	if not definition or _G.InCombatLockdown() then return false end
	if definition.tab then
		local tabButton = self:PrepareTabButton(id)
		if tabButton then
			-- Close the shared window before opening and selecting the requested tab through native clicks.
			button:SetAttribute("type", "macro")
			button:SetAttribute("macrotext", "/click PlayerSpellsFrameCloseButton\n/click PlayerSpellsMicroButton\n/click " .. tabButton:GetName())
			return true
		end
	elseif not definition.fallback then
		local target = self:GetTarget(id)
		if not target then return false end
		button:SetAttribute("type", "click")
		button:SetAttribute("clickbutton", target)
		return true
	end
	button._microMenuAction = id
	button:SetScript("PostClick", function(self, _, down)
		if not down then MicroMenu:ActivateFallback(self._microMenuAction) end
	end)
	return true
end

-- Existing windows can load through their own bindings before a QuickActions ring is opened.
MicroMenu.events = _G.CreateFrame("Frame")
MicroMenu.events:RegisterEvent("ADDON_LOADED")
MicroMenu.events:SetScript("OnEvent", function(_, _, addonName)
	if addonName == "Blizzard_PlayerSpells" and QC.QueueSecureRebuild then
		_G.C_Timer.After(0, function() QC:QueueSecureRebuild() end)
	end
end)
