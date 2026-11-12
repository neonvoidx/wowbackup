-- #region Main Tweaks
local function OnEvent(self, event, ...)
	if event == "ADDON_LOADED" then
		local addOnName = ...
		if addonName == "Custom" then
			print("Custom tweaks loaded...")
		end
	elseif event == "PLAYER_LOGIN" then
	elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
	elseif event == "PLAYER_ENTERING_WORLD" then
		-- #region CVARs
		-- Player silhouette behind objects
		SetCVar("cameraIndirectVisibility", 1)
		SetCVar("showTutorials", 0)
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
		SetCVar("raidFramesHealthText", "none")
		-- Character highlight
		SetCVar("findYourselfAnywhere", 0)
		SetCVar("findYourselfAnywhereOnlyInCombat", 0)
		SetCVar("findYourselfInBG", 0)
		SetCVar("findYourselfInBGOnlyInCombat", 0)
		SetCVar("findYourselfInRaid", 0)
		SetCVar("findYourselfInRaidOnlyInCombat", 0)
		SetCVar("findYourselfMode", 0)
		SetCVar("findYourselfModeCircle", 0)
		SetCVar("findYourselfModeIcon", 0)
		SetCVar("findYourselfModeOutline", 0)

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
		SetCVar("UnitNameOwn", 0) -- Show own name
		SetCVar("UnitNamePlayerPVPTitle", 0) -- Show character title
		SetCVar("UnitNamePlayerGuild", 0) -- Show guild
		SetCVar("UnitNameFriendlyPetName", 1) -- Pet name

		-- Targeting
		SetCVar("SoftTargetEnemy", 3) -- target where looking
		-- Name size
		SetCVar("WorldTextMinSize", 0)

		-- Battlepets and critters
		SetCVar("UnitNameNonCombatCreatureName", 0) -- Show character title

		SetCVar("damageMeterEnabled", 0)
		SetCVar("damageMeterResetOnNewInstance", 0)

		-- Assisted rotation highlight
		SetCVar("assistedCombatHighlight", 0)
		-- Boss mods
		SetCVar("combatWarningsEnabled", 1)
		-- external defensives
		SetCVar("externalDefensivesEnabled", 1)
		-- CDM
		SetCVar("cooldownViewerEnabled", 1)
		SetCVar("spellDiminishPVPEnemiesEnabled", 1)

		-- Floating Combat
		SetCVar("floatingCombatTextCombatHealing", 0)

		-- Auto dismount
		SetCVar("autoDismount", 1)
		SetCVar("autoDismountFlying", 1)

		-- Comparison tooltips, 0 = hold shift to show, 1 = always show
		SetCVar("alwaysCompareItems", 1)

		-- Loot
		SetCVar("autoLootDefault", 1)

		-- Damage number size
		SetCVar("WorldTextScale_v2", 1)

		-- Spell overlays HUD
		SetCVar("spellActivationOverlayOpacity", 0)

		-- Secure ability toggle, prevents quick double presses
		SetCVar("secureAbilityToggle", 1)

		-- Targeting
		SetCVar("SoftTargetEnemy", 0)

		-- Audio
		SetCVar("Sound_EnableEmoteSounds", 1) -- Allow emote sounds
		-- Spell Queue Latency window
		-- This is default setting but want to make sure
		SetCVar("SpellQueueWindow", 400)

		-- Graphical tweaks for Forever
		--
		--
		--
		-- Max settings
		SetCVar("graphicsQuality", 9) -- this is actually 10 in game (i.e Max quality settings)

		-- Better graphics
		-- https://www.reddit.com/r/wowforever/comments/1wk9fiy/cinematic_ultra_config_tweak_guide_with_heavy_snow/

		-- Can set to 1.33 if your card can handle it, if you are under target frames leave at 1
		-- SetCVar("RenderScale", 1) -- Uncomment this if you want to change, default is 1
		SetCVar("ffxAntiAliasingMode", 0)
		SetCVar("ResampleQuality", 3)
		SetCVar("ResampleSharpness", 0.7)
		SetCVar("shadowTextureSize", 4096)
		SetCVar("reflectionMode", 3)
		SetCVar("rippleDetail", 3)
		-- Eliminate Small Object & Prop Pop-In
		SetCVar("lodObjectFadeScale", 200)
		SetCVar("lodObjectCullSize", 8)
		SetCVar("doodadLodScale", 200)
		-- Long range mountain geometry
		SetCVar("terrainLodDist", 1000)
		-- Atmospheric Storms & Blizzards
		SetCVar("weatherDensity", 3)
		-- Full Spell Particle Effects
		SetCVar("graphicsSpellDensity", 5)
		SetCVar("spellClutter", 0)

		-- Lush Ground Clutter Beyond the UI Slider
		SetCVar("groundEffectDensity", 256) -- Overrides the values from post for higher ground detail, 128 was value in post
		SetCVar("groundEffectFade", 375)
		SetCVar("groundEffectDist", 500)

		-- Lighting tweaks
		SetCVar("Contrast", 56)
		SetCVar("Brightness", 47)
		SetCVar("Gamma", 1.1)
		-- #endregion
		--#endregion

		-- Set edit mode profile to 1st custom profile by default
		-- C_EditMode.SetActiveLayout(3) -- 3 is 1 for some reason, probably because blizzard 1/2 default and legacy profiles
		-- Just sets default nameplate stuff if not using a nameplate addon
		local bbpLoaded, _ = C_AddOns.IsAddOnLoaded("BetterBlizzPlates")
		if not bbpLoaded then
			-- SetCVar("NamePlateHorizontalScale", 1) -- reduce horizontal scale
			-- SetCVar("NamePlateVerticalScale", 3) -- reduce horizontal scale
			-- SetCVar("nameplateLargerScale", 1)
			-- SetCVar("NamePlateClassificationScale", 1)
			-- SetCVar("nameplateSelectedScale", 1.05)
			-- SetCVar("nameplateMinScale", 1)
			-- SetCVar("nameplateMaxScale", 1)
			-- SetCVar("nameplateGlobalScale", 1.1)
			SetCVar("nameplateOverlapV", 1.1) -- Vertical overlap
			SetCVar("nameplateOverlapH", 0.8) -- Horizontal overlap
			SetCVar("nameplateMaxAlpha", 1)
			SetCVar("nameplateMaxScale", 1.0)
			SetCVar("nameplateMinScale", 0.9)
			SetCVar("nameplateSelectedScale", 1.0)
			SetCVar("nameplateMinAlpha", 0.7)
			SetCVar("nameplateOccludedAlphaMult", 1.0)
			SetCVar("nameplateAuraScale", 1.8)
			SetCVar("nameplateDebuffPadding", 6)
			SetCVar("nameplateShowAll", 1)
			SetCVar("nameplateShowCastBars", 1)
			SetCVar("nameplateShowDebuffsOnFriendly", 1)
			SetCVar("nameplateShowEnemies", 1)
			SetCVar("nameplateShowFriendlyNpcs", 0)
			SetCVar("nameplateShowEnemyGuardians", 1)
			SetCVar("nameplateShowEnemyMinions", "0")
			SetCVar("nameplateShowEnemyGuardians", "0")
			SetCVar("nameplateShowEnemyMinus", "0")
			SetCVar("nameplateSimplifiedScale", 0.5)
			SetCVar("nameplateShowEnemyPets", 1)
			SetCVar("nameplateShowEnemyTotems", 1)
			-- Show friendly plates for arena
			local isInInstance, instanceType = IsInInstance()
			-- check if we are entering or leaving an arena/bg
			if isInInstance and instanceType == "arena" then
				-- turn on
				SetCVar("nameplateShowFriendlyPlayers", 1)
				SetCVar("nameplateShowFriendlyPlayerPets", 1)
			else
				-- turn off
				SetCVar("nameplateShowFriendlyPlayers", 0)
				SetCVar("nameplateShowFriendlyPlayerPets", 0)
			end
		end
	elseif event == "CHAT_MSG_CHANNEL" then
	elseif event == "ZONE_CHANGED_NEW_AREA" then
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED") -- Addon loaded event
f:RegisterEvent("PLAYER_ENTERING_WORLD") -- Event for when player enters the world, reloads U logins etc
f:RegisterEvent("GROUP_JOINED")
f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
f:RegisterEvent("PLAYER_LOGIN") -- Event for when player logs in
f:RegisterEvent("UPDATE_BINDINGS") -- Event for when keybindings are updated
f:RegisterEvent("PLAYER_LOGIN") -- Happens only on login
f:SetScript("OnEvent", OnEvent)
-- #endregion

-- Slash commands
SLASH_RELOAD1 = "/rl"
function SlashCmdList.RELOAD(msg, editBox)
	ReloadUI()
end
