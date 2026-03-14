-- #region Main Tweaks
local function OnEvent(self, event, ...)
	if event == "ADDON_LOADED" then
		local addOnName = ...
		if addonName == "Custom" then
			print("Custom tweaks loaded...")
		end
	elseif event == "PLAYER_LOGIN" then
		-- EditModeManagerFrame:SelectLayout(3)
	elseif event == "PLAYER_ENTERING_WORLD" then
		-- This event is fired anytime you see a load screen, i.e on login, on UI reload, on new area etc
		-- #region Hide/Show UI elements
		-- Hide micromenu
		-- MicroMenu:Hide()
		-- Hide totem frame
		-- TotemFrame:Hide()
		-- Class resource bars
		-- RogueComboPointBarFrame:Hide()
		-- RuneFrame:Hide()
		--TargetFrameToT:Hide() -- Target of Target frame
		-- Disable default cast bar
		-- PlayerCastingBarFrame:UnregisterAllEvents()
		-- Auto collapse buffs
		BuffFrame.CollapseAndExpandButton:SetAlpha(0)
		BuffFrame.CollapseAndExpandButton:SetChecked(false)
		BuffFrame.CollapseAndExpandButton:UpdateOrientation()
		BuffFrame:SetBuffsExpandedState()
		BuffFrame.CollapseAndExpandButton:HookScript("OnEnter", function()
			BuffFrame.CollapseAndExpandButton:SetAlpha(1)
		end)
		BuffFrame.CollapseAndExpandButton:HookScript("OnLeave", function()
			BuffFrame.CollapseAndExpandButton:SetAlpha(0)
		end)
		-- Hide micromenu
		-- MicroMenuContainer:Hide()
		-- -- Hide bag bar
		-- MainMenuBarBackpackButton:Hide()
		-- BagsBar:Hide()
		-- #endregion

		-- #region CVARs
		-- Player silhouette behind objects
		SetCVar("cameraIndirectVisibility", 1)
		-- Uber tooltip, 2 sets items/spells to cursor while rest to edit mode position
		SetCVar("UberTooltips", 2)
		-- Player camera weird shit inside buildings
		SetCVar("cameraIndirectOffset", 10)
		-- Mage invisibility fx
		SetCVar("ffxNether", 1)
		-- Fixes issue where if you fel rush or monk roll and continue moving forward you stop
		SetCVar("CursorFreeLookStartDelta", 0)
		-- Stops spells autopushing to bars
		SetCVar("AutoPushSpellToActionBar", 0)
		-- Unit frame health
		SetCVar("statusText", 1)
		SetCVar("statusTextDisplay", "BOTH")
		-- Raid frames
		SetCVar("raidFramesDisplayClassColor", 1)
		SetCVar("raidFramesDisplayDebuffs", 1)
		SetCVar("raidFramesDisplayOnlyHealerPowerBars", 1)
		SetCVar("raidFramesDisplayIncomingHeals", 1)
		SetCVar("raidFramesHealthText", "perc")
		-- Character highlight
		SetCVar("findYourselfAnywhere", 1)
		SetCVar("findYourselfAnywhereOnlyInCombat", 1)
		SetCVar("findYourselfInBG", 0)
		SetCVar("findYourselfInBGOnlyInCombat", 1)
		SetCVar("findYourselfInRaid", 0)
		SetCVar("findYourselfInRaidOnlyInCombat", 1)
		SetCVar("findYourselfMode", 1)
		SetCVar("findYourselfModeCircle", 0)
		SetCVar("findYourselfModeIcon", 0)
		SetCVar("findYourselfModeOutline", 1)
		-- Silhouette
		SetCVar("occludedSilhouettePlayer", 1)

		-- #region Nameplates
		-- Nameplate max distance
		SetCVar("nameplateMaxAlphaDistance", 60)
		SetCVar("nameplateGameObjectMaxDistance", 60)

		-- Unit Names
		SetCVar("UnitNameInteractiveNPC", 1)
		SetCVar("UnitNameHostleNPC", 1)
		SetCVar("UnitNameEnemyPlayerName", 1)
		SetCVar("UnitNameNPC", 1)
		SetCVar("UnitNameFriendlyPlayerName", 1) -- Show friendly player names always
		SetCVar("UnitNamePlayerGuild", 1) -- Show guild
		SetCVar("UnitNamePlayerPVPTitle", 0) -- Show titles
		SetCVar("UnitNameOwn", 1) -- Show own name
		SetCVar("UnitNamePlayerPVPTitle", 1) -- Show character title

		-- Personal Resource Display
		SetCVar("nameplateShowSelf", 1)
		SetCVar("NameplatePersonalShowAlways", 0)
		SetCVar("NameplatePersonalShowInCombat", 1)
		SetCVar("NameplatePersonalShowWithTarget", 1)

		SetCVar("damageMeterEnabled", 1)
		SetCVar("damageMeterResetOnNewInstance", 1)

		SetCVar("assistedCombatHighlight", 0)
		SetCVar("combatWarningsEnabled", 1)
		SetCVar("externalDefensivesEnabled", 1)
		SetCVar("cooldownViewerEnabled", 1)
		SetCVar("spellDiminishPVPEnemiesEnabled", 1)

		-- Floating Combat
		SetCVar("floatingCombatTextCombatHealing", 0)

		-- Auto dismount
		SetCVar("autoDismount", 1)
		SetCVar("autoDismountFlying", 1)

		-- Comparison tooltips, 0 = hold shift to show, 1 = always show
		SetCVar("alwaysCompareItems", 0)

		-- Audio
		SetCVar("Sound_EnableEmoteSounds", 1) -- Allow emote sounds
		-- Spell Queue Latency window
		-- This is default setting but want to make sure
		SetCVar("SpellQueueWindow", 400)

		-- If BetterBlizzPlates loaded
		local bbpLoaded, _ = C_AddOns.IsAddOnLoaded("BetterBlizzPlates")
		local platynatorLoaded, _ = C_AddOns.IsAddOnLoaded("Platynator")
		if not bbpLoaded and not platynatorLoaded then
			SetCVar("NamePlateHorizontalScale", 1) -- reduce horizontal scale
			SetCVar("NamePlateVerticalScale", 3) -- reduce horizontal scale
			SetCVar("nameplateLargerScale", 1)
			SetCVar("NamePlateClassificationScale", 1)
			SetCVar("nameplateSelectedScale", 1.05)
			SetCVar("nameplateMinScale", 1)
			SetCVar("nameplateMaxScale", 1)
			SetCVar("nameplateGlobalScale", 1.1)
			SetCVar("nameplateOverlapV", 1.1) -- Vertical overlap
			SetCVar("nameplateOverlapH", 0.8) -- Horizontal overlap
			SetCVar("nameplateMaxAlpha", 1)
			SetCVar("nameplateMinAlpha", 0.6)
			SetCVar("nameplateOccludedAlphaMult", 1)
			-- Show friendly plates for arena
			local isInInstance, instanceType = IsInInstance()
			-- check if we are entering or leaving an arena/bg
			if isInInstance and instanceType == "arena" then
				-- turn on
				SetCVar("nameplateShowFriends", 1)
			else
				-- turn off
				SetCVar("nameplateShowFriends", 0)
			end
		end
		-- #endregion
		--#endregion

		-- Set edit mode profile to 1st custom profile by default
		-- C_EditMode.SetActiveLayout(3)
	elseif event == "CHAT_MSG_CHANNEL" then
		-- Chat Message event
		local text, playerName, _, channelName = ...
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		-- Zone changed event i.e entering a new zone or instance or arena or bg etc

		-- Show friendly nameplates in arena (handled by betterblizzplates and plater)
		-- local isInInstance, instanceType = IsInInstance()
		-- -- check if we are entering or leaving an arena/bg
		-- if isInInstance and instanceType == "arena" then
		--   -- turn on
		--   SetCVar("nameplateShowFriends", 1)
		-- else
		--   -- turn off
		--   SetCVar("nameplateShowFriends", 0)
		-- end
	end

	-- if event == "UPDATE_BINDINGS" or event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
	-- 	updateHotkeyText()
	-- end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED") -- Addon loaded event
f:RegisterEvent("PLAYER_ENTERING_WORLD") -- Event for when player enters the world, reloads U logins etc
f:RegisterEvent("GROUP_JOINED")
f:RegisterEvent("PLAYER_LOGIN") -- Event for when player logs in
f:RegisterEvent("UPDATE_BINDINGS") -- Event for when keybindings are updated
-- f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED") -- Event for when player specialization changes
--f:RegisterEvent("CHAT_MSG_CHANNEL") -- Event for chat messages in channels
f:RegisterEvent("PLAYER_LOGIN") -- Happens only on login
f:SetScript("OnEvent", OnEvent)
-- #endregion

-- hooksecurefunc("CompactUnitFrame_UpdateRoleIcon", function(f)
-- 	if f.optionTable == DefaultCompactUnitFrameOptions then
-- 		if f.roleIcon:GetTexture() == 337497 then
-- 			f.roleIcon:Show()
-- 		end
-- 	end
-- end)

-- hooksecurefunc("CompactUnitFrame_UpdateAll", function(f)
-- 	local buffSize = 25
-- 	local debuffSize = 25
-- 	if f.buffFrames then
-- 		for _, d in ipairs(f.buffFrames) do
-- 			d:SetSize(buffSize, buffSize)
-- 		end
-- 	end
-- 	-- if f.debuffFrames then
-- 	-- 	for _, d in ipairs(f.debuffFrames) do
-- 	-- 		d:SetSize(debuffSize, debuffSize)
-- 	-- 	end
-- 	-- end
-- end)

-- Slash commands
SLASH_RELOAD1 = "/rl"
function SlashCmdList.RELOAD(msg, editBox)
	ReloadUI()
end
