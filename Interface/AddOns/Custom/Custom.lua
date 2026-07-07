local applyDarkMode = function()
	-- CONFIGURE THESE
	local darkModeColor = 0.1
	local classicFrames = false

	local desat = true
	local vc = darkModeColor
	local cf = classicFrames

	local function applySettings(frame, desaturate, colorValue, hook)
		if frame then
			if desaturate ~= nil and frame.SetDesaturated then
				frame:SetDesaturated(desaturate)
			end
			if frame.SetVertexColor then
				frame:SetVertexColor(colorValue, colorValue, colorValue)
				if hook then
					if not frame.bbfHooked then
						frame.bbfHooked = true
						hooksecurefunc(frame, "SetVertexColor", function(self)
							if self.changing or self:IsProtected() then
								return
							end
							self.changing = true
							self:SetDesaturated(desaturate)
							self:SetVertexColor(colorValue, colorValue, colorValue)
							self.changing = false
						end)
					end
				end
			end
		end
	end

	if PlayerFrame.PlayerFrameContainer.PlayerElite then
		PlayerFrame.PlayerFrameContainer.PlayerElite:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
	end

	local prdBars = {
		PersonalResourceDisplayFrame.HealthBarsContainer.healthBar,
		PersonalResourceDisplayFrame.PowerBar,
		PersonalResourceDisplayFrame.AlternatePowerBar,
	}

	for _, frame in ipairs(prdBars) do
		for _, region in ipairs({ frame:GetRegions() }) do
			if region:GetObjectType() == "Texture" and region:GetAtlas() == "UI-HUD-CoolDownManager-Bar-BG" then
				region:SetVertexColor(0.1, 0.1, 0.1)
			end
		end
	end

	-- Death Knight Runes
	local runes = _G.RuneFrame
	if runes then
		for i = 1, 6 do
			applySettings(runes["Rune" .. i].BG_Active, desat, vc)
			applySettings(runes["Rune" .. i].BG_Inactive, desat, vc)
		end
	end

	-- Death Knight Nameplate Runes
	local dkNp = _G.DeathKnightResourceOverlayFrame
	if dkNp and not dkNp:IsForbidden() then
		for i = 1, 6 do
			applySettings(dkNp["Rune" .. i].BG_Active, desat, vc)
			applySettings(dkNp["Rune" .. i].BG_Inactive, desat, vc)
		end
	end

	-- Warlock Soul Shards (player frame)
	local soulShards = _G.WarlockPowerFrame
	if soulShards then
		for _, v in pairs({ soulShards:GetChildren() }) do
			applySettings(v.Background, desat, vc + (cf and 0 or 0.2))
		end
	end

	-- Warlock Soul Shards (nameplate)
	local ssNp = _G.ClassNameplateBarWarlockFrame
	if ssNp and not ssNp:IsForbidden() then
		for _, v in pairs({ ssNp:GetChildren() }) do
			applySettings(v.Background, desat, vc)
		end
	end

	-- Druid Combo Points
	local druidCp = _G.DruidComboPointBarFrame
	if druidCp then
		for _, v in pairs({ druidCp:GetChildren() }) do
			applySettings(v.BG_Inactive, desat, vc + (cf and 0 or 0.2))
			applySettings(v.BG_Active, desat, vc + (cf and -0.1 or 0.1))
		end
	end

	-- Druid Combo Points (nameplate)
	local druidNp = _G.ClassNameplateBarFeralDruidFrame
	if druidNp and not druidNp:IsForbidden() then
		local inactive = vc + (cf and 0 or 0.2)
		local active = vc + (cf and -0.1 or 0.1)
		for _, v in pairs({ druidNp:GetChildren() }) do
			applySettings(v.BG_Inactive, desat, inactive)
			applySettings(v.BG_Active, desat, active)
		end
	end

	-- Mage Arcane Charges
	local mage = _G.MageArcaneChargesFrame
	if mage then
		for _, v in pairs({ mage:GetChildren() }) do
			applySettings(v.ArcaneBG, desat, vc + 0.15)
		end
	end

	-- Mage Arcane Charges (nameplate)
	local mageNp = _G.ClassNameplateBarMageFrame
	if mageNp and not mageNp:IsForbidden() then
		for _, v in pairs({ mageNp:GetChildren() }) do
			applySettings(v.ArcaneBG, desat, vc + 0.15)
		end
	end

	-- Monk Chi
	local monk = _G.MonkHarmonyBarFrame
	if monk then
		for _, v in pairs({ monk:GetChildren() }) do
			applySettings(v.Chi_BG, desat, vc + (cf and -0.10 or 0.10))
			applySettings(v.Chi_BG_Active, desat, vc + (cf and -0.21 or 0))
		end
	end

	-- Monk Chi (nameplate)
	local monkNp = _G.ClassNameplateBarWindwalkerMonkFrame
	if monkNp and not monkNp:IsForbidden() then
		local chi = vc + (cf and -0.10 or 0.10)
		local chiActive = vc + (cf and -0.21 or 0)
		for _, v in pairs({ monkNp:GetChildren() }) do
			applySettings(v.Chi_BG, desat, chi)
			applySettings(v.Chi_BG_Active, desat, chiActive)
		end
	end

	-- Rogue Combo Points
	local rogue = _G.RogueComboPointBarFrame
	if rogue then
		for _, v in pairs({ rogue:GetChildren() }) do
			applySettings(v.BGInactive, desat, vc + (cf and 0.15 or 0.45))
			applySettings(v.BGActive, desat, vc + (cf and -0.1 or 0.20))
		end
	end

	-- Rogue Combo Points (nameplate)
	local rogueNp = _G.ClassNameplateBarRogueFrame
	if rogueNp and not rogueNp:IsForbidden() then
		local ri = vc + (cf and 0.15 or 0.45)
		local ra = vc + (cf and -0.1 or 0.20)
		for _, v in pairs({ rogueNp:GetChildren() }) do
			applySettings(v.BGInactive, desat, ri)
			applySettings(v.BGActive, desat, ra)
		end
	end

	-- Paladin Holy Power (nameplate)
	local palaNp = _G.ClassNameplateBarPaladinFrame
	if palaNp and not palaNp:IsForbidden() then
		applySettings(palaNp.Background, desat, vc)
		applySettings(palaNp.ActiveTexture, desat, vc)
	end

	-- Evoker Essence (player frame)
	local evoker = _G.EssencePlayerFrame
	local ev1 = vc + (cf and -0.30 or 0.10)
	local ev2 = vc + (cf and -0.20 or 0)
	if evoker then
		for _, v in pairs({ evoker:GetChildren() }) do
			if v.EssenceFillDone and v.EssenceFillDone.CircBG then
				applySettings(v.EssenceFillDone.CircBG, desat, ev1)
			end
			if v.EssenceFilling and v.EssenceFilling.EssenceBG then
				applySettings(v.EssenceFilling.EssenceBG, desat, ev2)
			end
			if v.EssenceEmpty and v.EssenceEmpty.EssenceBG then
				applySettings(v.EssenceEmpty.EssenceBG, desat, ev2)
			end
			if v.EssenceFillDone and v.EssenceFillDone.CircBGActive then
				applySettings(v.EssenceFillDone.CircBGActive, desat, ev2)
			end
			if v.EssenceDepleting and v.EssenceDepleting.EssenceBG then
				applySettings(v.EssenceDepleting.EssenceBG, desat, ev2)
			end
			if v.EssenceDepleting and v.EssenceDepleting.CircBGActive then
				applySettings(v.EssenceDepleting.CircBGActive, desat, ev2)
			end
			if v.EssenceFillDone and v.EssenceFillDone.RimGlow then
				applySettings(v.EssenceFillDone.RimGlow, desat, ev1)
			end
			if v.EssenceDepleting and v.EssenceDepleting.RimGlow then
				applySettings(v.EssenceDepleting.RimGlow, desat, ev1)
			end
		end
	end

	-- Evoker Essence (nameplate)
	local evokerNp = _G.ClassNameplateBarDracthyrFrame
	if evokerNp and not evokerNp:IsForbidden() then
		local e1 = vc + (cf and -0.30 or 0.10)
		local e2 = vc + (cf and -0.20 or 0)
		for _, v in pairs({ evokerNp:GetChildren() }) do
			if v.EssenceFillDone and v.EssenceFillDone.CircBG then
				applySettings(v.EssenceFillDone.CircBG, desat, e1)
			end
			if v.EssenceFilling and v.EssenceFilling.EssenceBG then
				applySettings(v.EssenceFilling.EssenceBG, desat, e2)
			end
			if v.EssenceEmpty and v.EssenceEmpty.EssenceBG then
				applySettings(v.EssenceEmpty.EssenceBG, desat, e2)
			end
			if v.EssenceFillDone and v.EssenceFillDone.CircBGActive then
				applySettings(v.EssenceFillDone.CircBGActive, desat, e2)
			end
			if v.EssenceDepleting and v.EssenceDepleting.EssenceBG then
				applySettings(v.EssenceDepleting.EssenceBG, desat, e2)
			end
			if v.EssenceDepleting and v.EssenceDepleting.CircBGActive then
				applySettings(v.EssenceDepleting.CircBGActive, desat, e2)
			end
			if v.EssenceFillDone and v.EssenceFillDone.RimGlow then
				applySettings(v.EssenceFillDone.RimGlow, desat, e1)
			end
			if v.EssenceDepleting and v.EssenceDepleting.RimGlow then
				applySettings(v.EssenceDepleting.RimGlow, desat, e1)
			end
		end
	end
end

-- #region Main Tweaks
local function OnEvent(self, event, ...)
	if event == "ADDON_LOADED" then
		local addOnName = ...
		if addonName == "Custom" then
			print("Custom tweaks loaded...")
		end
	elseif event == "PLAYER_LOGIN" then
	elseif event == "PLAYER_ENTERING_WORLD" then
		applyDarkMode()
		-- fix chat navigation
		local editBox = ChatFrame1EditBox
		if editBox and editBox.SetAltArrowKeyMode then
			editBox:SetAltArrowKeyMode(false)
		end

		-- Enable action bars 2,3,4,5 on reload
		local bars = { 2, 3, 4, 5, 6 }
		local p = "PROXY_SHOW_ACTIONBAR_"
		for k, v in pairs(bars) do
			if not Settings.GetSetting(p .. v):GetValue() then
				Settings.GetSetting(p .. v):SetValue(true)
			end
		end
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
		-- Auto collapse buffs, currently causes errors if you do this
		-- BuffFrame.CollapseAndExpandButton:SetAlpha(1)
		-- BuffFrame.CollapseAndExpandButton:SetChecked(false)
		-- BuffFrame.CollapseAndExpandButton:UpdateOrientation()
		-- BuffFrame:SetBuffsExpandedState()
		-- BuffFrame.CollapseAndExpandButton:HookScript("OnEnter", function()
		-- 	BuffFrame.CollapseAndExpandButton:SetAlpha(1)
		-- end)
		-- BuffFrame.CollapseAndExpandButton:HookScript("OnLeave", function()
		-- 	BuffFrame.CollapseAndExpandButton:SetAlpha(1)
		-- end)
		-- Hide micromenu
		-- MicroMenuContainer:Hide()
		-- -- Hide bag bar
		-- MainMenuBarBackpackButton:Hide()
		-- BagsBar:Hide()
		-- #endregion

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
		SetCVar("UnitNamePlayerGuild", 0) -- Show guild
		SetCVar("UnitNameOwn", 1) -- Show own name
		SetCVar("UnitNamePlayerPVPTitle", 0) -- Show character title

		-- Personal Resource Display
		local personalResource = 1
		SetCVar("nameplateShowSelf", personalResource)
		SetCVar("NameplatePersonalShowAlways", 0)
		SetCVar("NameplatePersonalShowInCombat", personalResource)
		SetCVar("NameplatePersonalShowWithTarget", personalResource)

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
		SetCVar("WorldTextScale_v2", 0.6)
		-- Name size
		SetCVar("WorldTextMinSize", 12)

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

		-- Just sets default nameplate stuff if not using a nameplate addon
		local bbpLoaded, _ = C_AddOns.IsAddOnLoaded("BetterBlizzPlates")
		local platynatorLoaded, _ = C_AddOns.IsAddOnLoaded("Platynator")
		if not bbpLoaded and not platynatorLoaded then
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
			SetCVar("nameplateMinAlpha", 0.6)
			SetCVar("nameplateOccludedAlphaMult", 0.4)
			SetCVar("nameplateSelectedScale", 1.1)
			SetCVar("nameplateAuraScale", 1.2)
			SetCVar("nameplateDebuffPadding", 6)
			SetCVar("nameplateShowAll", 1)
			SetCVar("nameplateShowCastBars", 1)
			SetCVar("nameplateShowDebuffsOnFriendly", 1)
			SetCVar("nameplateShowEnemies", 1)
			SetCVar("nameplateShowEnemyGuardians", 1)
			SetCVar("nameplateShowEnemyMinions", 1)
			SetCVar("nameplateShowEnemyMinus", 0)
			SetCVar("nameplateShowEnemyPets", 1)
			SetCVar("nameplateShowEnemyTotems", 1)
			-- Show friendly plates for arena
			local isInInstance, instanceType = IsInInstance()
			-- check if we are entering or leaving an arena/bg
			if isInInstance and instanceType == "arena" or isInInstance and instanceType == "pvp" then
				-- turn on
				SetCVar("nameplateShowFriendlyPlayers", 1)
			else
				-- turn off
				SetCVar("nameplateShowFriendlyPlayers", 0)
			end
		end
		-- #endregion
		--#endregion

		-- Set edit mode profile to 1st custom profile by default
		-- C_EditMode.SetActiveLayout(3) -- 3 is 1 for some reason, probably because blizzard 1/2 default and legacy profiles
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

-- Slash commands
SLASH_RELOAD1 = "/rl"
function SlashCmdList.RELOAD(msg, editBox)
	ReloadUI()
end
