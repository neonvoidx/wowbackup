sArenaMixin = {}
sArenaFrameMixin = {}

local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
sArenaMixin.isRetail = isRetail

sArenaMixin.layouts = {}
sArenaMixin.defaultSettings = {
    profile = {
        currentLayout = "Gladiuish",
        classColors = true,
        classColorFrameTexture = (BetterBlizzFramesDB and BetterBlizzFramesDB.classColorFrameTexture) or nil,
        showNames = true,
        hidePowerText = true,
        showDecimalsDR = true,
        showDecimalsClassIcon = true,
        decimalThreshold = 6,
        darkMode = (BetterBlizzFramesDB and BetterBlizzFramesDB.darkModeUi) or C_AddOns.IsAddOnLoaded("FrameColor") or nil,
        forceShowTrinketOnHuman = not isRetail and true or nil,
        darkModeValue = 0.2,
        desaturateTrinketCD = true,
        desaturateDispelCD = true,
        darkModeDesaturate = true,
        statusText = {
            alwaysShow = true,
            formatNumbers = true,
        },
        layoutSettings = {},
        invertClassIconCooldown = true,
    }
}

sArenaMixin.playerClass = select(2, UnitClass("player"))
sArenaMixin.maxArenaOpponents = (isRetail and 3) or 5
sArenaMixin.noTrinketTexture = 638661
sArenaMixin.trinketTexture = (isRetail and 1322720) or 133453
sArenaMixin.trinketID = (isRetail and 336126) or 42292
sArenaMixin.pFont = "Interface\\AddOns\\sArena_Reloaded\\Textures\\Prototype.ttf"
C_AddOns.EnableAddOn("sArena_Reloaded")
local LSM = LibStub("LibSharedMedia-3.0")
local decimalThreshold = 6 -- Default value, will be updated from db
LSM:Register("statusbar", "Blizzard RetailBar", [[Interface\AddOns\sArena_Reloaded\Textures\BlizzardRetailBar]])
LSM:Register("statusbar", "sArena Default", [[Interface\AddOns\sArena_Reloaded\Textures\sArenaDefault]])
LSM:Register("statusbar", "sArena Stripes", [[Interface\AddOns\sArena_Reloaded\Textures\sArenaHealer]])
LSM:Register("statusbar", "sArena Stripes 2", [[Interface\AddOns\sArena_Reloaded\Textures\sArenaRetailHealer]])
LSM:Register("font", "Prototype", [[Interface\AddOns\sArena_Reloaded\Textures\Prototype.ttf]])
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture
local stealthAlpha = 0.4

local healerSpecNames = {
    ["Discipline"] = true,
    ["Restoration"] = true,
    ["Mistweaver"] = true,
    ["Holy"] = true,
    ["Preservation"] = true,
}

local classPowerType = {
    WARRIOR = "RAGE",
    ROGUE = "ENERGY",
    DRUID = "MANA",
    PALADIN = "MANA",
    HUNTER = "FOCUS",
    DEATHKNIGHT = "RUNIC_POWER",
    SHAMAN = "MANA",
    MAGE = "MANA",
    WARLOCK = "MANA",
    PRIEST = "MANA",
    DEMONHUNTER = "FURY",
    EVOKER = "ESSENCE",
}

function sArenaMixin:Print(fmt, ...)
    local prefix = "|cffffffffsArena |cffff8000Reloaded|r |T135884:13:13|t:"
    print(prefix, string.format(fmt, ...))
end

function sArenaMixin:FontValues()
    local t, keys = {}, {}
    for k in pairs(LSM:HashTable(LSM.MediaType.FONT)) do keys[#keys+1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do t[k] = k end
    return t
end

function sArenaMixin:FontOutlineValues()
    return {
        [""] = "No outline",
        ["OUTLINE"] = "Outline",
        ["THICKOUTLINE"] = "Thick outline"
    }
end

sArenaMixin.classIcons = {
    ["DRUID"] = 625999,
    ["HUNTER"] = 135495, -- 626000
    ["MAGE"] = 135150, -- 626001
    ["MONK"] = 626002,
    ["PALADIN"] = 626003,
    ["PRIEST"] = 626004,
    ["ROGUE"] = 626005,
    ["SHAMAN"] = 626006,
    ["WARLOCK"] = 626007,
    ["WARRIOR"] = 135328, -- 626008
    ["DEATHKNIGHT"] = 135771,
    ["DEMONHUNTER"] = 1260827,
	["EVOKER"] = 4574311,
}

sArenaMixin.healerSpecIDs = {
    [65] = true,    -- Holy Paladin
    [105] = true,   -- Restoration Druid
    [256] = true,   -- Discipline Priest
    [257] = true,   -- Holy Priest
    [264] = true,   -- Restoration Shaman
    [270] = true,   -- Mistweaver Monk
    [1468] = true   -- Preservation Evoker
}

local castToAuraMap -- Spellcasts with non-duration aura spell ids

if isRetail then
    castToAuraMap = {
        [212182] = 212183, -- Smoke Bomb
        [359053] = 212183, -- Smoke Bomb
        [198838] = 201633, -- Earthen Wall Totem
        [62618]  = 81782,  -- Power Word: Barrier
        [204336] = 8178,   -- Grounding Totem
        [443028] = 456499, -- Celestial Conduit (Absolute Serenity)
        [289655] = 289655, -- Sanctified Ground
    }
    sArenaMixin.nonDurationAuras = {
        [212183] = {duration = 5, helpful = false, texture = 458733}, -- Smoke Bomb
        [201633] = {duration = 18, helpful = true, texture = 136098}, -- Earthen Wall Totem
        [81782]  = {duration = 10, helpful = true, texture = 253400}, -- Power Word: Barrier
        [8178]   = {duration = 3,  helpful = true, texture = 136039}, -- Grounding Totem
        [456499] = {duration = 4,  helpful = true, texture = 988197}, -- Celestial Conduit (Absolute Serenity)
        [289655] = {duration = 5,  helpful = true, texture = 237544}, -- Sanctified Ground
    }
else
    castToAuraMap = {
        [212182] = 212183, -- Smoke Bomb
        [359053] = 212183, -- Smoke Bomb
        [198838] = 201633, -- Earthen Wall Totem
        [62618]  = 81782,  -- Power Word: Barrier
        [204336] = 8178,   -- Grounding Totem
        [443028] = 456499, -- Celestial Conduit (Absolute Serenity)
        [289655] = 289655, -- Sanctified Ground
    }
        sArenaMixin.nonDurationAuras = {
        [212183] = {duration = 5, helpful = false, texture = 458733}, -- Smoke Bomb
        [201633] = {duration = 18, helpful = true, texture = 136098}, -- Earthen Wall Totem
        [81782]  = {duration = 10, helpful = true, texture = 253400}, -- Power Word: Barrier
        [8178]   = {duration = 3,  helpful = true, texture = 136039}, -- Grounding Totem
        [456499] = {duration = 4,  helpful = true, texture = 988197}, -- Celestial Conduit (Absolute Serenity)
        [289655] = {duration = 5,  helpful = true, texture = 237544}, -- Sanctified Ground
    }
end

sArenaMixin.activeNonDurationAuras = {}

local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGUID = UnitGUID
local GetTime = GetTime
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local UnitPowerMax = UnitPowerMax
local UnitPower = UnitPower
local UnitPowerType = UnitPowerType
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local GetSpellName = GetSpellName or C_Spell.GetSpellName
local testActive
local masqueOn
local TestTitle
local feignDeathID = 5384
local FEIGN_DEATH = GetSpellName(feignDeathID) -- Localized name for Feign Death



--[[
    ImportOtherForkSettings: Migrates settings from other sArena versions to sArena Reloaded
    
    This function handles the import process when users have multiple sArena versions installed
    and want to migrate their existing settings to sArena Reloaded. It searches for saved
    variables from other sArena versions, copies the data, and handles the addon switching.
]]
function sArenaMixin:ImportOtherForkSettings()
    -- Try to find the saved variables database from other sArena versions
    -- Priority order: sArena3DB -> sArena2DB -> sArenaDB (oldest to newest naming conventions)
    local oldDB = sArena3DB or sArena2DB or sArenaDB

    -- Validate that we found a valid database with the required structure
    -- Both profileKeys and profiles are essential for AceDB addon profiles
    if not oldDB or not oldDB.profileKeys or not oldDB.profiles then
        -- Display error message to user if no valid sArena database found
        sArenaMixin.conversionStatusText = "|cffFF0000No other sArena found. Are you sure it's enabled?|r"
        -- Refresh the config UI to show the error message
        LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
        return
    end

    -- Get reference to sArena Reloaded's database
    local newDB = sArena_ReloadedDB

    -- Initialize the database structure if it doesn't exist yet
    -- This ensures we have the proper AceDB structure before migration
    if not newDB.profileKeys then newDB.profileKeys = {} end
    if not newDB.profiles then newDB.profiles = {} end

    -- Migrate all character profile assignments from old database
    for character, profileName in pairs(oldDB.profileKeys) do
        -- Append "(Imported)" to distinguish imported profiles from new ones
        -- This prevents conflicts and makes it clear which profiles came from the other version
        local newProfileName = profileName .. "(Imported)"
        newDB.profileKeys[character] = newProfileName

        -- Copy the actual profile data if it exists and hasn't been imported already
        if oldDB.profiles[profileName] and not newDB.profiles[newProfileName] then
            newDB.profiles[newProfileName] = CopyTable(oldDB.profiles[profileName])
        end
    end

    -- Ensure comp
    self:CompatibilityEnsurer()

    -- Ensure sArena Reloaded is enabled (should already be, but being safe)
    C_AddOns.EnableAddOn("sArena_Reloaded")

    -- Set flag to reopen the options panel after UI reload
    -- This provides better UX by returning the user to the config screen
    sArena_ReloadedDB.reOpenOptions = true

    -- Reload the UI to finalize the addon changes and load the imported settings
    ReloadUI()
end

function sArenaMixin:CompatibilityEnsurer()
    -- Disable any other active sArena versions due to compatibility issues, two sArenas cannot coexist
    -- This is only done with the user's specific consent by choosing to import as thoroughly explained in the GUI
    -- List of known sArena addon variants that needs to be disabled for compatibility's sake
    local otherSArenaVersions = {
        "sArena", -- Original
        "sArena Updated",
        "sArena_Pinaclonada",
        "sArena_Updated2_by_sammers",
    }

    -- Ensure compatibility
    for _, addonName in ipairs(otherSArenaVersions) do
        if C_AddOns.IsAddOnLoaded(addonName) then
            C_AddOns.DisableAddOn(addonName)
        end
    end
end

local db
local emptyLayoutOptionsTable = {
    notice = {
        name = "The selected layout doesn't appear to have any settings.",
        type = "description",
    }
}
local blizzFrame
local changedParent
local UpdateBlizzVisibility
if isRetail then
    UpdateBlizzVisibility = function()
        -- Hide Blizzard Arena Frames while in Arena
        if CompactArenaFrame.isHidden then return end
        CompactArenaFrame.isHidden = true
        local ArenaAntiMalware = CreateFrame("Frame")
        ArenaAntiMalware:Hide()

        --Event list
        local events = {
            "PLAYER_ENTERING_WORLD",
            "ZONE_CHANGED_NEW_AREA",
            "ARENA_OPPONENT_UPDATE",
            "ARENA_PREP_OPPONENT_SPECIALIZATIONS",
            "PVP_MATCH_STATE_CHANGED"
        }

        -- Change parent and hide
        local function MalwareProtector()
            if InCombatLockdown() then return end
            local instanceType = select(2, IsInInstance())
            if instanceType == "arena" then
                CompactArenaFrame:SetParent(ArenaAntiMalware)
                CompactArenaFrameTitle:SetParent(ArenaAntiMalware)
            end
        end

        -- Event handler function
        ArenaAntiMalware:SetScript("OnEvent", function(self, event, ...)
            MalwareProtector()
            C_Timer.After(0, MalwareProtector)     --been instances of this god forsaken frame popping up so lets try to also do it one frame later
        end)

        -- Register the events
        for _, event in ipairs(events) do
            ArenaAntiMalware:RegisterEvent(event)
        end

        -- Shouldn't be needed, but you know what, fuck it
        CompactArenaFrame:HookScript("OnLoad", MalwareProtector)
        CompactArenaFrame:HookScript("OnShow", MalwareProtector)
        CompactArenaFrameTitle:HookScript("OnLoad", MalwareProtector)
        CompactArenaFrameTitle:HookScript("OnShow", MalwareProtector)

        MalwareProtector()
    end
else
    UpdateBlizzVisibility = function(instanceType)
        -- Hide Blizzard Arena Frames while in Arena
        if InCombatLockdown() then return end
        local prepFrame = _G["ArenaPrepFrames"]
        local enemyFrame = _G["ArenaEnemyFrames"]

        if (not blizzFrame) then
            blizzFrame = CreateFrame("Frame")
            blizzFrame:Hide()
        end

        if instanceType == "arena" then
            if prepFrame then
                prepFrame:SetParent(blizzFrame)
                changedParent = true
            end
            if enemyFrame then
                enemyFrame:SetParent(blizzFrame)
                changedParent = true
            end
        else
            if changedParent then
                if prepFrame then
                    prepFrame:SetParent(UIParent)
                end
                if enemyFrame then
                    enemyFrame:SetParent(UIParent)
                end
            end
        end
    end
end


function sArenaMixin:CheckClassStacking()
    local classCount = {}
    local classHasHealer = {}

    -- Count all players by class and track which classes have healers
    for i = 1, self.maxArenaOpponents do
        local frame = _G["sArenaEnemyFrame"..i]
        if frame.class then
            classCount[frame.class] = (classCount[frame.class] or 0) + 1
            if frame.isHealer then
                classHasHealer[frame.class] = true
            end
        end
    end

    -- Check if any class has multiple players AND at least one healer
    for class, count in pairs(classCount) do
        if count > 1 and classHasHealer[class] then
            return true
        end
    end

    return false
end


local function captureFont(fs)
    if not fs or not fs.GetFont then return nil end
    local path, size, flags = fs:GetFont()
    if not path then return nil end
    return { path, size, flags }
end
local function applyFont(fs, fontTbl)
    if fs and fontTbl and fontTbl[1] then
        fs:SetFont(fontTbl[1], fontTbl[2], fontTbl[3])
    end
end

function sArenaMixin:UpdateFonts()
    local fontCfg  = db.profile.layoutSettings[db.profile.currentLayout]
    if not fontCfg.changeFont then
        local og = sArenaMixin.ogFonts
        if og then
            for i = 1, sArenaMixin.maxArenaOpponents do
                local f = _G["sArenaEnemyFrame"..i]
                if f then
                    applyFont(f.Name,        og.Name)
                    applyFont(f.HealthText,  og.HealthText)
                    applyFont(f.SpecNameText, og.SpecNameText)
                    applyFont(f.PowerText,   og.PowerText)
                    applyFont(f.CastBar and f.CastBar.Text, og.CastBarText)
                    local fontName, s, o = f.CastBar.Text:GetFont()
                    f.CastBar.Text:SetFont(fontName, s, "THINOUTLINE")
                end
            end
            sArenaMixin.ogFonts = nil
        else
            for i = 1, sArenaMixin.maxArenaOpponents do
                local f = _G["sArenaEnemyFrame"..i]
                if f then
                    local fontName, s, o = f.CastBar.Text:GetFont()
                    f.CastBar.Text:SetFont(fontName, s, "THINOUTLINE")
                end
            end
        end
        return
    end
    local frameKey = fontCfg.frameFont
    local cdKey    = fontCfg.cdFont

    local frameFontPath = frameKey and LSM:Fetch(LSM.MediaType.FONT, frameKey) or nil
    --local cdFontPath    = cdKey   and LSM:Fetch(LSM.MediaType.FONT, cdKey)   or nil

    local size    = fontCfg.size or 10
    local outline = fontCfg.fontOutline
    if outline == nil then
        outline = "OUTLINE"
    end

    local function setFont(fs, path)
        if fs and path and fs.SetFont then
            local _, s = fs:GetFont()
            fs:SetFont(path, size, outline)
            if outline ~= "OUTLINE" and outline ~= "THICKOUTLINE" then
                fs:SetShadowOffset(1, -1)
            else
                fs:SetShadowOffset(0, 0)
            end
        end
    end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena"..i]
        if not frame or not frame.HealthBar then return end

        if frameFontPath then
            if not sArenaMixin.ogFonts then
                sArenaMixin.ogFonts = {
                    Name        = captureFont(frame.Name),
                    HealthText  = captureFont(frame.HealthText),
                    SpecNameText = captureFont(frame.SpecNameText),
                    PowerText   = captureFont(frame.PowerText),
                    CastBarText = captureFont(frame.CastBar and frame.CastBar.Text),
                }
            end
            setFont(frame.Name, frameFontPath)
            setFont(frame.HealthText, frameFontPath)
            setFont(frame.SpecNameText, frameFontPath)
            setFont(frame.PowerText,  frameFontPath)
            setFont(frame.CastBar.Text,   frameFontPath)
        end
    end
end

function sArenaMixin:UpdateTextures()
    if not db then return end

    local layout = db.profile.layoutSettings[db.profile.currentLayout]
    local texKeys = layout.textures or {
        generalStatusBarTexture   = "sArena Default",
        healStatusBarTexture      = "sArena Stripes",
        castbarStatusBarTexture   = "sArena Default",
    }

    local castTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarStatusBarTexture)
    local dpsTexture     = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.generalStatusBarTexture)
    local healerTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.healStatusBarTexture)
    local modernCastbars            = layout.castBar.useModernCastbars
    local keepDefaultModernTextures = layout.castBar.keepDefaultModernTextures
    local classStacking = self:CheckClassStacking()

    -- Store castTexture and keepDefaultTextures for use in ModernCastbar hooks
    self.castTexture = castTexture
    self.keepDefaultModernTextures = keepDefaultModernTextures

    for i = 1, self.maxArenaOpponents do
        local frame = _G["sArenaEnemyFrame" .. i]
        local textureToUse = dpsTexture

        if frame.isHealer then
            if layout.retextureHealerClassStackOnly then
                if classStacking then
                    textureToUse = healerTexture
                end
            else
                textureToUse = healerTexture
            end
        end

        frame.HealthBar:SetStatusBarTexture(textureToUse)
        frame.PowerBar:SetStatusBarTexture(dpsTexture)

        if modernCastbars then
            if not keepDefaultModernTextures then
                frame.CastBar:SetStatusBarTexture(castTexture)
            end
        else
            frame.CastBar:SetStatusBarTexture(castTexture)
        end

        if db.profile.currentLayout == "BlizzRetail" then
            frame.PowerBar:GetStatusBarTexture():SetDrawLayer("BACKGROUND", 2)
        end
    end
end

local MAX_INCOMING_HEAL_OVERFLOW = 1.0;
function sArenaFrameMixin:UpdateHealPrediction()
	if ( not self.myHealPredictionBar and not self.otherHealPredictionBar and not self.healAbsorbBar and not self.totalAbsorbBar ) then
		return;
	end

	local _, maxHealth = self.healthbar:GetMinMaxValues();
	local health = self.healthbar:GetValue();
	if ( maxHealth <= 0 ) then
		return;
	end

	local myIncomingHeal = UnitGetIncomingHeals(self.unit, "player") or 0;
	local allIncomingHeal = UnitGetIncomingHeals(self.unit) or 0;
	local totalAbsorb = UnitGetTotalAbsorbs(self.unit) or 0;

	local myCurrentHealAbsorb = 0;
	if ( self.healAbsorbBar ) then
		myCurrentHealAbsorb = UnitGetTotalHealAbsorbs(self.unit) or 0;

		--We don't fill outside the health bar with healAbsorbs.  Instead, an overHealAbsorbGlow is shown.
		if ( health < myCurrentHealAbsorb ) then
			self.overHealAbsorbGlow:Show();
			myCurrentHealAbsorb = health;
		else
			self.overHealAbsorbGlow:Hide();
		end
	end

	--See how far we're going over the health bar and make sure we don't go too far out of the self.
	if ( health - myCurrentHealAbsorb + allIncomingHeal > maxHealth * MAX_INCOMING_HEAL_OVERFLOW ) then
		allIncomingHeal = maxHealth * MAX_INCOMING_HEAL_OVERFLOW - health + myCurrentHealAbsorb;
	end

	local otherIncomingHeal = 0;

	--Split up incoming heals.
	if ( allIncomingHeal >= myIncomingHeal ) then
		otherIncomingHeal = allIncomingHeal - myIncomingHeal;
	else
		myIncomingHeal = allIncomingHeal;
	end

	--We don't fill outside the the health bar with absorbs.  Instead, an overAbsorbGlow is shown.
	local overAbsorb = false;
	if ( health - myCurrentHealAbsorb + allIncomingHeal + totalAbsorb >= maxHealth or health + totalAbsorb >= maxHealth ) then
		if ( totalAbsorb > 0 ) then
			overAbsorb = true;
		end

		if ( allIncomingHeal > myCurrentHealAbsorb ) then
			totalAbsorb = max(0,maxHealth - (health - myCurrentHealAbsorb + allIncomingHeal));
		else
			totalAbsorb = max(0,maxHealth - health);
		end
	end

	if ( overAbsorb ) then
		self.overAbsorbGlow:Show();
	else
		self.overAbsorbGlow:Hide();
	end

	local healthTexture = self.healthbar:GetStatusBarTexture();
	local myCurrentHealAbsorbPercent = 0;
	local healAbsorbTexture = nil;

	if ( self.healAbsorbBar ) then
		myCurrentHealAbsorbPercent = myCurrentHealAbsorb / maxHealth;

		--If allIncomingHeal is greater than myCurrentHealAbsorb, then the current
		--heal absorb will be completely overlayed by the incoming heals so we don't show it.
		if ( myCurrentHealAbsorb > allIncomingHeal ) then
			local shownHealAbsorb = myCurrentHealAbsorb - allIncomingHeal;
			local shownHealAbsorbPercent = shownHealAbsorb / maxHealth;

			healAbsorbTexture = self.healAbsorbBar:UpdateFillPosition(healthTexture, shownHealAbsorb, -shownHealAbsorbPercent);

			--If there are incoming heals the left shadow would be overlayed by the incoming heals
			--so it isn't shown.
			-- self.healAbsorbBar.LeftShadow:SetShown(allIncomingHeal <= 0);

			-- The right shadow is only shown if there are absorbs on the health bar.
			-- self.healAbsorbBar.RightShadow:SetShown(totalAbsorb > 0)
		else
			self.healAbsorbBar:Hide();
		end
	end

	--Show myIncomingHeal on the health bar.
	local incomingHealTexture;
	if ( self.myHealPredictionBar ) then
		incomingHealTexture = self.myHealPredictionBar:UpdateFillPosition(healthTexture, myIncomingHeal, -myCurrentHealAbsorbPercent);
	end

	local otherHealLeftTexture = (myIncomingHeal > 0) and incomingHealTexture or healthTexture;
	local xOffset = (myIncomingHeal > 0) and 0 or -myCurrentHealAbsorbPercent;

	--Append otherIncomingHeal on the health bar
	if ( self.otherHealPredictionBar ) then
		incomingHealTexture = self.otherHealPredictionBar:UpdateFillPosition(otherHealLeftTexture, otherIncomingHeal, xOffset);
	end

	--Append absorbs to the correct section of the health bar.
	local appendTexture = nil;
	if ( healAbsorbTexture ) then
		--If there is a healAbsorb part shown, append the absorb to the end of that.
		appendTexture = healAbsorbTexture;
	else
		--Otherwise, append the absorb to the end of the the incomingHeals or health part;
		appendTexture = incomingHealTexture or healthTexture;
	end

	if ( self.totalAbsorbBar ) then
		self.totalAbsorbBar:UpdateFillPosition(appendTexture, totalAbsorb);
	end
end

local ABSORB_GLOW_ALPHA = 0.6
local ABSORB_GLOW_OFFSET = -5
function sArenaFrameMixin:UpdateAbsorb()
    local healthBar = self.healthbar or self.HealthBar
    if not healthBar or healthBar:IsForbidden() then return end

    local absorbBar = self.totalAbsorbBar
    local absorbOverlay = absorbBar and absorbBar.TiledFillOverlay or self.totalAbsorbBarOverlay
    local glow = self.overAbsorbGlow
    if not absorbBar or not absorbOverlay or absorbBar:IsForbidden() or absorbOverlay:IsForbidden() then return end

    local _, maxHealth = healthBar:GetMinMaxValues()
    local currentHealth = healthBar:GetValue()
    if maxHealth <= 0 then return end

    local totalAbsorb = UnitGetTotalAbsorbs(self.unit) or 0
    if totalAbsorb > maxHealth then totalAbsorb = maxHealth end

    local isOverAbsorb = currentHealth + totalAbsorb > maxHealth

    local healthWidth = healthBar:GetWidth()
    local healthHeight = healthBar:GetHeight()

    local absorbWidth = totalAbsorb / maxHealth * healthWidth
    local missingHealthWidth = (maxHealth - currentHealth) / maxHealth * healthWidth
    local absorbBarWidth = math.min(absorbWidth, missingHealthWidth)

    -- Show absorb bar only for missing health
    if absorbBarWidth > 0 then
        absorbBar:ClearAllPoints()
        absorbBar:SetPoint("TOPLEFT", healthBar, "TOPLEFT", currentHealth / maxHealth * healthWidth, 0)
        absorbBar:SetWidth(absorbBarWidth)
        absorbBar:SetHeight(healthHeight)
        absorbBar:Show()
    else
        absorbBar:Hide()
    end

    -- Show striped overlay for full absorb width (wraps onto filled health if needed)
    if absorbWidth > 0 then
        absorbOverlay:SetParent(healthBar)
        absorbOverlay:ClearAllPoints()
        if isOverAbsorb then
            absorbOverlay:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 0, 0)
            absorbOverlay:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
        else
            absorbOverlay:SetPoint("TOPRIGHT", absorbBar, "TOPRIGHT", 0, 0)
            absorbOverlay:SetPoint("BOTTOMRIGHT", absorbBar, "BOTTOMRIGHT", 0, 0)
        end
        absorbOverlay:SetWidth(absorbWidth)
        absorbOverlay:SetHeight(healthHeight)

        if absorbOverlay.tileSize then
            absorbOverlay:SetTexCoord(1 - (absorbWidth / absorbOverlay.tileSize), 1, 0, healthHeight / absorbOverlay.tileSize)
        end

        absorbOverlay:Show()
    else
        absorbOverlay:Hide()
    end

    -- Glow if over-absorb occurs
    glow:ClearAllPoints()
    if isOverAbsorb then
        glow:SetPoint("TOPLEFT", absorbOverlay, "TOPLEFT", ABSORB_GLOW_OFFSET, 0)
        glow:SetPoint("BOTTOMLEFT", absorbOverlay, "BOTTOMLEFT", ABSORB_GLOW_OFFSET, 0)
        glow:SetAlpha(ABSORB_GLOW_ALPHA)
        glow:Show()
    else
        glow:Hide()
    end
end

function sArenaMixin:HandleArenaStart()
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        if frame:IsShown() then break end
        if UnitExists("arena"..i) then
            frame:UpdateVisible()
            frame:UpdatePlayer("seen")
        end
    end
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        if not UnitIsVisible("arena"..i) then
            frame:SetAlpha(stealthAlpha)
        end
    end
end

local matchStartedMessages = {
    ["The Arena battle has begun!"] = true, -- English / Default
    ["¡La batalla en arena ha comenzado!"] = true, -- esES / esMX
    ["A batalha na Arena começou!"] = true, -- ptBR
    ["Der Arenakampf hat begonnen!"] = true, -- deDE
    ["Le combat d'arène commence\194\160!"] = true, -- frFR
    ["Бой начался!"] = true, -- ruRU
    ["투기장 전투가 시작되었습니다!"] = true, -- koKR
    ["竞技场战斗开始了！"] = true, -- zhCN
    ["竞技场的战斗开始了！"] = true, -- zhCN (Wotlk)
    ["競技場戰鬥開始了！"] = true, -- zhTW
}

local function IsMatchStartedMessage(msg)
    return matchStartedMessages[msg]
end

-- Parent Frame
function sArenaMixin:OnLoad()
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
end

local combatEvents = {
    ["SPELL_CAST_SUCCESS"] = true,
    ["SPELL_AURA_APPLIED"] = true,
    ["SPELL_INTERRUPT"] = true,
    ["SPELL_AURA_REMOVED"] = true,
    ["SPELL_AURA_BROKEN"] = true,
    ["SPELL_AURA_REFRESH"] = true,
    ["SPELL_DISPEL"] = true,
}

function sArenaMixin:OnEvent(event, ...)
    if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
        local _, combatEvent, _, sourceGUID, sourceName, _, _, destGUID, _, _, _, spellID, _, _, auraType = CombatLogGetCurrentEventInfo()
        if not combatEvents[combatEvent] then return end

        if combatEvent == "SPELL_CAST_SUCCESS" or combatEvent == "SPELL_AURA_APPLIED" then

            -- Non-duration auras
            if castToAuraMap[spellID] and combatEvent == "SPELL_CAST_SUCCESS" then
                local auraID = castToAuraMap[spellID]
                sArenaMixin.activeNonDurationAuras[auraID] = GetTime()

                for i = 1, sArenaMixin.maxArenaOpponents do
                    local ArenaFrame = self["arena" .. i]
                    ArenaFrame:FindAura()
                end

                C_Timer.After(sArenaMixin.nonDurationAuras[auraID].duration, function()
                    sArenaMixin.activeNonDurationAuras[auraID] = nil
                end)
            end

            -- Racials
            if sArenaMixin.racialSpells[spellID] then
                for i = 1, sArenaMixin.maxArenaOpponents do
                    if (sourceGUID == UnitGUID("arena" .. i)) then
                        local ArenaFrame = self["arena" .. i]
                        ArenaFrame:FindRacial(spellID)
                    end
                end
            end

        end

        -- Dispels
        if combatEvent == "SPELL_DISPEL" then
            if sArenaMixin.dispelData[spellID] and db.profile.showDispels then
                for i = 1, sArenaMixin.maxArenaOpponents do
                    local ArenaFrame = self["arena" .. i]

                    local arenaGUID = UnitGUID("arena" .. i)
                    local petGUID = UnitGUID("arena" .. i .. "pet")

                    --print("3: Checking dispel for", ArenaFrame.unit, "sourceGUID:", sourceGUID, "arenaGUID:", arenaGUID, "petGUID:", petGUID)

                    -- Check if dispel was cast by arena player or their pet
                    if sourceGUID == arenaGUID or (sourceGUID == petGUID and spellID == 119905) then
                        ArenaFrame:FindDispel(spellID)
                        --print("4: Dispel registered for", ArenaFrame.unit, "spellID:", spellID)
                        break
                    end
                end
            end
        end

        -- DRs
        if sArenaMixin.drList[spellID] then
            for i = 1, sArenaMixin.maxArenaOpponents do
                if ( destGUID == UnitGUID("arena" .. i) and (auraType == "DEBUFF") ) then
                    local ArenaFrame = self["arena" .. i]
                    ArenaFrame:FindDR(combatEvent, spellID)
                    break
                end
            end
        end

        -- Interrupts
        if sArenaMixin.interruptList[spellID] then
            if combatEvent == "SPELL_INTERRUPT" then
                for i = 1, sArenaMixin.maxArenaOpponents do
                    if (destGUID == UnitGUID("arena" .. i)) then
                        local ArenaFrame = self["arena" .. i]
                        ArenaFrame:FindInterrupt(combatEvent, spellID)
                        local castBar = ArenaFrame.CastBar

                        if sourceName then
                            local name, server = strsplit("-", sourceName)
                            local colorStr = "ffFFFFFF"

                            if C_PlayerInfo.GUIDIsPlayer(sourceGUID) then
                                local _, englishClass = GetPlayerInfoByGUID(sourceGUID)
                                if englishClass then
                                    colorStr = RAID_CLASS_COLORS[englishClass].colorStr
                                end
                            end

                            local interruptedByName = string.format("|c%s[%s]|r", colorStr, name)
                            castBar.interruptedBy = interruptedByName
                            castBar.Text:SetText(interruptedByName)
                            castBar:Show()
                            C_Timer.After(1, function()
                                castBar.interruptedBy = nil
                            end)
                        end
                        break
                    end
                end
            end
        end

    elseif (event == "PLAYER_LOGIN") then
        self:Initialize()
        if sArenaMixin:CompatibilityIssueExists() then return end
        self:UpdatePlayerSpec()
        self:SetupCastColor()
        self:SetupGrayTrinket()
        self:AddMasqueSupport()
        self:SetupCustomCD()
        self:SetDRBorderShownStatus()
        if sArena_ReloadedDB.reOpenOptions then
            sArena_ReloadedDB.reOpenOptions = nil
            C_Timer.After(0.5, function()
                LibStub("AceConfigDialog-3.0"):Open("sArena")
            end)
        end
        self:UnregisterEvent("PLAYER_LOGIN")
    elseif (event == "PLAYER_ENTERING_WORLD") then
        local _, instanceType = IsInInstance()
        UpdateBlizzVisibility(instanceType)
        self:SetMouseState(true)

        if (instanceType == "arena") then
            self:UpdatePlayerSpec()
            self:ResetDetectedDispels()
            if TestTitle then
                TestTitle:Hide()
                for i = 1, sArenaMixin.maxArenaOpponents do
                    local frame = self["arena" .. i]
                    frame.tempName = nil
                    frame.tempSpecName = nil
                    frame.tempClass = nil
                    frame.tempSpecIcon = nil
                    frame.isHealer = nil
                end
            end
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
        else
            self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
        end
    elseif event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" then
        local msg = ...
        if IsMatchStartedMessage(msg) then
            C_Timer.After(0.5, function()
                self:HandleArenaStart()
            end)
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:UpdatePlayerSpec()
    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        self:ResetDetectedDispels()
    end
end

local function ChatCommand(input)
    local cmd = (input or ""):trim():lower()
    if cmd == "" then
        LibStub("AceConfigDialog-3.0"):Open("sArena")
    elseif cmd == "convert" then
        sArenaMixin:ImportOtherForkSettings()
    elseif cmd == "ver" or cmd == "version" then
        sArenaMixin:Print("Current Version: " .. C_AddOns.GetAddOnMetadata("sArena_Reloaded", "Version"))
    elseif cmd:match("^test%s*[1-5]$") then
        sArenaMixin.testUnits = tonumber(cmd:match("(%d)"))
        input = "test"
        LibStub("AceConfigCmd-3.0").HandleCommand("sArena", "sarena", "sArena", input)
    else
        LibStub("AceConfigCmd-3.0").HandleCommand("sArena", "sarena", "sArena", input)
    end
end

function sArenaMixin:UpdateCleanups(db)
    if not db then return end
    -- Migrate old swapHumanTrinket setting to new swapRacialTrinket
    if db.profile.swapHumanTrinket ~= nil and db.profile.swapRacialTrinket == nil then
        db.profile.swapRacialTrinket = db.profile.swapHumanTrinket
        db.profile.swapHumanTrinket = nil
    end
end

function sArenaMixin:UpdatePlayerSpec()
    local currentSpec = isRetail and GetSpecialization() or C_SpecializationInfo.GetSpecialization()
    if currentSpec and currentSpec > 0 then
        local specID, specName
        if isRetail then
            specID, specName = GetSpecializationInfo(currentSpec)
        else
            specID, specName = C_SpecializationInfo.GetSpecializationInfo(currentSpec)
        end

        -- Only update if we actually got valid spec data
        if specID and specID > 0 and specName then
            sArenaMixin.playerSpecID = specID
            sArenaMixin.playerSpecName = specName
            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
        end
    end
end

function sArenaMixin:Initialize()
    if (db) then return end

    local compatIssue = self:CompatibilityIssueExists()

    self.db = LibStub("AceDB-3.0"):New("sArena_ReloadedDB", self.defaultSettings, true)
    db = self.db

    db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
    self.optionsTable.handler = self
    self.optionsTable.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("sArena", self.optionsTable)
    LibStub("AceConfigDialog-3.0"):SetDefaultSize("sArena", compatIssue and 520 or 860, compatIssue and 300 or 690)
    LibStub("AceConsole-3.0"):RegisterChatCommand("sarena", ChatCommand)
    if not compatIssue then
        self:UpdateCleanups(db)
        self:UpdateDRTimeSetting()
        self:UpdateDecimalThreshold()
        LibStub("AceConfigDialog-3.0"):AddToBlizOptions("sArena", "sArena |cffff8000Reloaded|r |T135884:13:13|t")
        self:SetLayout(_, db.profile.currentLayout)
    else
        C_Timer.After(5, function()
            sArenaMixin:Print("Two different versions of sArena are loaded. Please select how you want to continue by typing /sarena")
        end)
    end
end

function sArenaMixin:RefreshConfig()
    self:SetLayout(_, db.profile.currentLayout)
end


function sArenaMixin:ApplyPrototypeFont(frame)
    local layout = db.profile.currentLayout
    local isProtoLayout = (layout == "Gladiuish" or layout == "Pixelated")
    local enable = isProtoLayout and not db.profile.layoutSettings[layout].changeFont

    if not enable and (not frame.changedFonts or next(frame.changedFonts) == nil) then
        return
    end

    if not frame.changedFonts then
        frame.changedFonts = {}
    end

    local function updateFont(obj, newSize, newFlags)
        if not obj then return end

        local currentFont, currentSize, currentFlags = obj:GetFont()

        if enable then
            -- Save original font only once
            if not frame.changedFonts[obj] then
                frame.changedFonts[obj] = { currentFont, currentSize, currentFlags }
            end

            obj:SetFont(sArenaMixin.pFont, newSize or currentSize, newFlags or currentFlags)
        else
            local original = frame.changedFonts[obj]
            if original then
                obj:SetFont(unpack(original))
                frame.changedFonts[obj] = nil
            end
        end
    end

    updateFont(frame.Name)
    updateFont(frame.SpecNameText, 9)
    updateFont(frame.HealthText)
    updateFont(frame.PowerText)
    updateFont(frame.CastBar and frame.CastBar.Text)
end

function sArenaMixin:SetupCastColor()
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        local castBar = frame.CastBar
        castBar:HookScript("OnEvent", function(self)
            if self.BorderShield:IsShown() then
                self:SetStatusBarColor(0.7, 0.7, 0.7, 1)
            end
        end)
    end
end

function sArenaFrameMixin:SetTextureCrop(texture, crop, type)
    if not texture then return end
    if type == "aura" then
        texture:SetTexCoord(0.03, 0.97, 0.03, 0.93)
    elseif type == "healer" then
        texture:SetTexCoord(0.205, 0.765, 0.22, 0.745)
    else
        if crop then
            texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        else
            if type == "class" and ((db and db.profile.currentLayout == "BlizzRetail") or (db and db.profile.currentLayout == "BlizzArena")) then -- TODO: Fix this mess
                texture:SetTexCoord(0.05, 0.95, 0.1, 0.9)
            else
                texture:SetTexCoord(0, 1, 0, 1)
            end
        end
    end
end

function sArenaMixin:SetupGrayTrinket()
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        local cooldown = frame.Trinket.Cooldown
        cooldown:HookScript("OnCooldownDone", function()
            frame.Trinket.Texture:SetDesaturated(false)
        end)
        local dispelCooldown = frame.Dispel.Cooldown
        dispelCooldown:HookScript("OnCooldownDone", function()
            frame.Dispel.Texture:SetDesaturated(false)
        end)
    end
end

function sArenaMixin:UpdateDecimalThreshold()
    decimalThreshold = self.db.profile.decimalThreshold or 6
end

function sArenaMixin:CreateCustomCooldown(cooldown, showDecimals)
    local text = cooldown.sArenaText or cooldown:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    if not cooldown.sArenaText then
        cooldown.sArenaText = text

        local f, s, o = cooldown.Text:GetFont()
        text:SetFont(f, s, o)

        local r, g, b, a = cooldown.Text:GetShadowColor()
        local x, y = cooldown.Text:GetShadowOffset()
        text:SetShadowColor(r, g, b, a)
        text:SetShadowOffset(x, y)

        text:SetPoint("CENTER", cooldown, "CENTER", 0, -1)
        text:SetJustifyH("CENTER")
        text:SetJustifyV("MIDDLE")
    end

    cooldown:SetHideCountdownNumbers(showDecimals)

    if showDecimals then
        cooldown:SetScript("OnUpdate", function()
            local start, duration = cooldown:GetCooldownTimes()
            start, duration = start / 1000, duration / 1000
            local remaining = (start + duration) - GetTime()

            if remaining > 0 then
                if remaining < decimalThreshold then
                    text:SetFormattedText("%.1f", remaining)
                elseif remaining < 60 then
                    text:SetFormattedText("%d", remaining)
                elseif remaining < 3600 then
                    local m, s = math.floor(remaining / 60), math.floor(remaining % 60)
                    text:SetFormattedText("%d:%02d", m, s)
                else
                    text:SetFormattedText("%dh", math.floor(remaining / 3600))
                end
            else
                text:SetText("")
            end
        end)
    else
        cooldown:SetScript("OnUpdate", nil)
        text:SetText(nil)
    end
end

function sArenaMixin:SetupCustomCD()
    if C_AddOns.IsAddOnLoaded("OmniCC") then return end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]

        -- Class icon cooldown
        self:CreateCustomCooldown(frame.ClassIconCooldown, self.db.profile.showDecimalsClassIcon)

        -- DR frames
        for _, category in ipairs(self.drCategories) do
            local drFrame = frame[category]
            if drFrame and drFrame.Cooldown then
                self:CreateCustomCooldown(drFrame.Cooldown, self.db.profile.showDecimalsDR)
            end
        end
    end
end

function sArenaMixin:SetDRBorderShownStatus()
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        -- DR frames
        for _, category in ipairs(self.drCategories) do
            local drFrame = frame[category]
            if drFrame then
                if self.db.profile.disableDRBorder then
                    drFrame.Border:Hide()
                    drFrame.Border.hidden = true
                elseif drFrame.Border.hidden then
                    drFrame.Border:Show()
                    drFrame.Border.hidden = nil
                end
            end
        end
    end
end

function sArenaMixin:DarkMode()
    if db.profile.darkMode == false then
        return false
    end

    if (BetterBlizzFramesDB and BetterBlizzFramesDB.darkModeUi) or C_AddOns.IsAddOnLoaded("FrameColor") or db.profile.darkMode then
        return true
    end
end

function sArenaMixin:DarkModeColor()
    if BetterBlizzFramesDB and BetterBlizzFramesDB.darkModeUi then
        return BetterBlizzFramesDB.darkModeColor
    elseif db.profile.darkMode then
        return db.profile.darkModeValue
    end
end

function sArenaFrameMixin:DarkModeFrame()
    if not sArenaMixin:DarkMode() then return end

    local darkModeColor = sArenaMixin:DarkModeColor()
    local lighter = darkModeColor + 0.1
    local shouldDesaturate = db.profile.darkModeDesaturate

    local frameTexture = self.frameTexture
    local specBorder = self.SpecIcon.Border
    local trinketBorder = self.Trinket.Border
    local trinketCircleBorder = self.Trinket.CircleBorder
    local racialBorder = self.Racial.Border
    local dispelBorder = self.Dispel.Border
    local castBorder = self.CastBar.Border


    if frameTexture then
        frameTexture:SetDesaturated(shouldDesaturate)
        frameTexture:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
    end
    if specBorder then
        specBorder:SetDesaturated(shouldDesaturate)
        specBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
    end
    if castBorder then
        castBorder:SetDesaturated(shouldDesaturate)
        castBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
    end
    if trinketBorder then
        trinketBorder:SetDesaturated(shouldDesaturate)
        trinketBorder:SetVertexColor(lighter, lighter, lighter)
    end
    if trinketCircleBorder then
        trinketCircleBorder:SetDesaturated(shouldDesaturate)
        trinketCircleBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
    end
    if racialBorder then
        racialBorder:SetDesaturated(shouldDesaturate)
        racialBorder:SetVertexColor(lighter, lighter, lighter)
    end
    if dispelBorder then
        dispelBorder:SetDesaturated(shouldDesaturate)
        dispelBorder:SetVertexColor(lighter, lighter, lighter)
    end

end

function sArenaFrameMixin:ClassColorFrameTexture()
    if not db.profile.classColorFrameTexture then return end

    -- Check for real class first, then fallback to tempClass
    local class = self.class or self.tempClass
    local color = RAID_CLASS_COLORS[class]

    if not color then return end

    local frameTexture = self.frameTexture
    local specBorder = self.SpecIcon.Border
    local trinketBorder = self.Trinket.Border
    local racialBorder = self.Racial.Border
    local dispelBorder = self.Dispel.Border
    local castBorder = self.CastBar.Border

    if frameTexture then
        frameTexture:SetDesaturated(true)
        frameTexture:SetVertexColor(color.r, color.g, color.b)
    end
    if specBorder then
        specBorder:SetDesaturated(true)
        specBorder:SetVertexColor(color.r, color.g, color.b)
    end
    if castBorder then
        castBorder:SetDesaturated(true)
        castBorder:SetVertexColor(color.r, color.g, color.b)
    end
    if trinketBorder then
        trinketBorder:SetDesaturated(true)
        local lighter_r = math.min(1, color.r + 0.2)
        local lighter_g = math.min(1, color.g + 0.2)
        local lighter_b = math.min(1, color.b + 0.2)
        trinketBorder:SetVertexColor(lighter_r, lighter_g, lighter_b)
    end
    if racialBorder then
        racialBorder:SetDesaturated(true)
        local lighter_r = math.min(1, color.r + 0.2)
        local lighter_g = math.min(1, color.g + 0.2)
        local lighter_b = math.min(1, color.b + 0.2)
        racialBorder:SetVertexColor(lighter_r, lighter_g, lighter_b)
    end
    if dispelBorder then
        dispelBorder:SetDesaturated(true)
        local lighter_r = math.min(1, color.r + 0.2)
        local lighter_g = math.min(1, color.g + 0.2)
        local lighter_b = math.min(1, color.b + 0.2)
        dispelBorder:SetVertexColor(lighter_r, lighter_g, lighter_b)
    end
end

function sArenaFrameMixin:UpdateFrameColors()
    if db.profile.classColorFrameTexture then
        self:ClassColorFrameTexture()
    elseif sArenaMixin:DarkMode() then
        self:DarkModeFrame()
    else
        if self.frameTexture then
            self.frameTexture:SetDesaturated(false)
            self.frameTexture:SetVertexColor(1, 1, 1)
        end
        if self.SpecIcon.Border then
            self.SpecIcon.Border:SetDesaturated(false)
            self.SpecIcon.Border:SetVertexColor(1, 1, 1)
        end
        if self.CastBar.Border then
            self.CastBar.Border:SetDesaturated(false)
            self.CastBar.Border:SetVertexColor(1, 1, 1)
        end
        if self.Trinket.Border then
            self.Trinket.Border:SetDesaturated(false)
            self.Trinket.Border:SetVertexColor(1, 1, 1)
        end
        if self.Racial.Border then
            self.Racial.Border:SetDesaturated(false)
            self.Racial.Border:SetVertexColor(1, 1, 1)
        end
    end
end

function sArenaMixin:SetLayout(_, layout)
    if (InCombatLockdown()) then return end

    if not self.db then
        self.db = db
    end
    if not self.arena1 then
        for i = 1, sArenaMixin.maxArenaOpponents do
            local globalName = "sArenaEnemyFrame" .. i
            self["arena" .. i] = _G[globalName]
        end
    end

    layout = sArenaMixin.layouts[layout] and layout or "Gladiuish"

    db.profile.currentLayout = layout
    self.layoutdb = self.db.profile.layoutSettings[layout]

    self:RemovePixelBorders()

    self:UpdateTextures()

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        frame:ResetLayout()
        self.layouts[layout]:Initialize(frame)
        frame:UpdatePlayer()
        sArenaMixin:ApplyPrototypeFont(frame)
        frame:UpdateDRCooldownReverse()
        frame:UpdateClassIconCooldownReverse()
        frame:UpdateTrinketRacialCooldownReverse()
        frame:UpdateClassIconSwipeSettings()
        frame:UpdateTrinketRacialSwipeSettings()
        frame:UpdateFrameColors()
        frame:UpdateNameColor()
    end

    self:ModernOrClassicCastbar()
    self:UpdateFonts()

    self.optionsTable.args.layoutSettingsGroup.args = self.layouts[layout].optionsTable and self.layouts[layout].optionsTable or emptyLayoutOptionsTable
    LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")

    local _, instanceType = IsInInstance()
    if (instanceType ~= "arena" and self.arena1:IsShown()) then
        self:Test()
    end
end

function sArenaMixin:SetupDrag(frameToClick, frameToMove, settingsTable, updateMethod)
    frameToClick:HookScript("OnMouseDown", function()
        if (InCombatLockdown()) then return end

        if (IsShiftKeyDown() and IsControlKeyDown() and not frameToMove.isMoving) then
            frameToMove:StartMoving()
            frameToMove.isMoving = true
        end
    end)

    frameToClick:HookScript("OnMouseUp", function()
        if (InCombatLockdown()) then return end

        if (frameToMove.isMoving) then
            frameToMove:StopMovingOrSizing()
            frameToMove.isMoving = false

            local settings = db.profile.layoutSettings[db.profile.currentLayout]

            if (settingsTable) then
                settings = settings[settingsTable]
            end

            local parentX, parentY = frameToMove:GetParent():GetCenter()
            local frameX, frameY = frameToMove:GetCenter()
            local scale = frameToMove:GetScale()

            frameX = ((frameX * scale) - parentX) / scale
            frameY = ((frameY * scale) - parentY) / scale

            -- Round to 1 decimal place
            frameX = floor(frameX * 10 + 0.5) / 10
            frameY = floor(frameY * 10 + 0.5) / 10

            settings.posX, settings.posY = frameX, frameY
            self[updateMethod](self, settings)
            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
        end
    end)
end

function sArenaMixin:SetMouseState(state)
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        frame.CastBar:EnableMouse(state)
        for i = 1, #self.drCategories do
            frame[self.drCategories[i]]:EnableMouse(state)
        end
        frame.SpecIcon:EnableMouse(state)
        frame.Trinket:EnableMouse(state)
        frame.Racial:EnableMouse(state)
    end
end

-- Arena Frames

local function ResetTexture(texturePool, t)
    if (texturePool) then
        t:SetParent(texturePool.parent)
    end

    t:SetTexture(nil)
    t:SetColorTexture(0, 0, 0, 0)
    t:SetVertexColor(1, 1, 1, 1)
    t:SetDesaturated(false)
    t:SetTexCoord(0, 1, 0, 1)
    t:ClearAllPoints()
    t:SetSize(0, 0)
    t:Hide()
end

function sArenaFrameMixin:OnLoad()
    if sArenaMixin:CompatibilityIssueExists() then return end
    local unit = "arena" .. self:GetID()
    self.parent = self:GetParent()

    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("UNIT_NAME_UPDATE")
    self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    self:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
    self:RegisterEvent("ARENA_OPPONENT_UPDATE")
    self:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
    self:RegisterUnitEvent("UNIT_HEALTH", unit)
    self:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
    self:RegisterUnitEvent("UNIT_POWER_UPDATE", unit)
    self:RegisterUnitEvent("UNIT_MAXPOWER", unit)
    self:RegisterUnitEvent("UNIT_DISPLAYPOWER", unit)
    self:RegisterUnitEvent("UNIT_AURA", unit)
    self:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)
    self:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", unit)

    self:RegisterForClicks("AnyDown", "AnyUp")
    self:SetAttribute("*type1", "target")
    self:SetAttribute("*type2", "focus")
    self:SetAttribute("unit", unit)
    self.unit = unit

    if isRetail then
        self.CastBar:SetUnit(unit, false, true)
    else
        CastingBarFrame_SetUnit(self.CastBar, unit, false, true)
    end

    local CastStopEvents  = {
        UNIT_SPELLCAST_STOP                = true,
        UNIT_SPELLCAST_CHANNEL_STOP        = true,
        UNIT_SPELLCAST_INTERRUPTED         = true,
        UNIT_SPELLCAST_EMPOWER_STOP        = true,
    }

    self.CastBar:HookScript("OnEvent", function(castBar, event, eventUnit)
        if CastStopEvents[event] and eventUnit == unit then
            if castBar.interruptedBy then
                castBar:Show()
            else
                if not UnitCastingInfo(unit) and not UnitChannelInfo(unit) then
                    castBar:Hide()
                end
            end
        end
    end)

    self.healthbar = self.HealthBar

    self.myHealPredictionBar:ClearAllPoints()
    self.otherHealPredictionBar:ClearAllPoints()
    self.totalAbsorbBar:ClearAllPoints()
    self.overAbsorbGlow:ClearAllPoints()
    self.overHealAbsorbGlow:ClearAllPoints()

    self.totalAbsorbBar:SetTexture(self.totalAbsorbBar.fillTexture)
    self.totalAbsorbBar:SetVertexColor(1, 1, 1)
    self.totalAbsorbBar:SetHeight(self.healthbar:GetHeight())

    self.overAbsorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
    self.overAbsorbGlow:SetBlendMode("ADD")
    self.overAbsorbGlow:SetPoint("TOPLEFT", self.healthbar, "TOPRIGHT", -7, 0)
    self.overAbsorbGlow:SetPoint("BOTTOMLEFT", self.healthbar, "BOTTOMRIGHT", -7, 0)

    self.overHealAbsorbGlow:SetPoint("BOTTOMRIGHT", self.healthbar, "BOTTOMLEFT", 7, 0)
    self.overHealAbsorbGlow:SetPoint("TOPRIGHT", self.healthbar, "TOPLEFT", 7, 0)

    self.AuraStacks:SetTextColor(1,1,1,1)
    self.AuraStacks:SetJustifyH("LEFT")
    self.AuraStacks:SetJustifyV("BOTTOM")

    self.DispelStacks:SetTextColor(1,1,1,1)
    self.DispelStacks:SetJustifyH("LEFT")
    self.DispelStacks:SetJustifyV("BOTTOM")

    if not self.Dispel.Overlay then
        self.Dispel.Overlay = CreateFrame("Frame", nil, self.Dispel)
        self.Dispel.Overlay:SetFrameStrata("MEDIUM")
        self.Dispel.Overlay:SetFrameLevel(10)
    end

    self.DispelStacks:SetParent(self.Dispel.Overlay)

    self.TexturePool = CreateTexturePool(self, "ARTWORK", nil, nil, ResetTexture)
end

function sArenaFrameMixin:OnEvent(event, eventUnit, arg1)
    local unit = self.unit

    if (eventUnit and eventUnit == unit) then
        if (event == "UNIT_NAME_UPDATE") then
            if (db.profile.showArenaNumber) then
                self.Name:SetText(unit)
            elseif (db.profile.showNames) then
                self.Name:SetText(UnitName(unit))
            end
        elseif (event == "ARENA_OPPONENT_UPDATE") then
            self:UpdatePlayer(arg1)
        elseif (event == "ARENA_COOLDOWNS_UPDATE") then
             self:UpdateTrinket()
        elseif (event == "ARENA_CROWD_CONTROL_SPELL_UPDATE") then
            -- arg1 == spellID
            if (arg1 ~= self.Trinket.spellID) then
                if arg1 ~= 0 then
                    local _, spellTextureNoOverride = GetSpellTexture(arg1)

                    -- Check if we had racial on trinket slot before
                    local wasRacialOnTrinketSlot = self.updateRacialOnTrinketSlot

                    self.Trinket.spellID = arg1

                    -- Determine if we should put racial on trinket slot
                    local swapEnabled = db.profile.swapRacialTrinket or db.profile.swapHumanTrinket
                    local shouldPutRacialOnTrinket = swapEnabled and self.race and not spellTextureNoOverride

                    -- Set the trinket texture
                    local trinketTexture
                    if spellTextureNoOverride then
                        if isRetail then
                            trinketTexture = spellTextureNoOverride
                        else
                            trinketTexture = self:GetFactionTrinketIcon()
                        end
                    else
                        if not isRetail and self.race == "Human" and db.profile.forceShowTrinketOnHuman then
                            trinketTexture = self:GetFactionTrinketIcon()
                            self.Trinket.spellID = sArenaMixin.trinketID
                        else
                            trinketTexture = sArenaMixin.noTrinketTexture     -- Surrender flag if no trinket
                        end
                    end

                    -- Handle racial updates based on trinket state (same logic as UpdateTrinket)
                    if spellTextureNoOverride and wasRacialOnTrinketSlot then
                        -- We found a real trinket and had racial on trinket slot, restore racial to its proper place
                        self.updateRacialOnTrinketSlot = nil
                        self.Trinket.Texture:SetTexture(trinketTexture)
                        self:UpdateRacial()
                    elseif shouldPutRacialOnTrinket then
                        -- We should put racial on trinket slot (no real trinket found)
                        self.updateRacialOnTrinketSlot = true
                        -- Don't set trinket texture yet - let UpdateRacial handle it for racial display
                        self:UpdateRacial()
                    else
                        -- Normal case: set trinket texture and clear racial from trinket slot
                        self.updateRacialOnTrinketSlot = nil
                        self.Trinket.Texture:SetTexture(trinketTexture)
                        -- Update racial to ensure it shows in racial slot if needed
                        if wasRacialOnTrinketSlot then
                            self:UpdateRacial()
                        end
                    end

                    self:UpdateTrinketIcon(true)
                else
                    -- No trinket - check if we should put racial on trinket slot
                    local swapEnabled = db.profile.swapRacialTrinket or db.profile.swapHumanTrinket
                    local shouldPutRacialOnTrinket = swapEnabled and self.race

                    if shouldPutRacialOnTrinket then
                        self.updateRacialOnTrinketSlot = true
                        self:UpdateRacial()
                        return
                    else
                        self.updateRacialOnTrinketSlot = nil
                        -- Ensure racial shows in racial slot if it was on trinket before
                        self:UpdateRacial()
                    end

                    if not isRetail and self.race == "Human" and db.profile.forceShowTrinketOnHuman then
                        self.Trinket.spellID = sArenaMixin.trinketID
                        self.Trinket.Texture:SetTexture(self:GetFactionTrinketIcon())
                        self:UpdateTrinketIcon(true)
                    else
                        self.Trinket.Texture:SetTexture(sArenaMixin.noTrinketTexture)
                        self:UpdateTrinketIcon(false)
                    end
                end
            end
        elseif (event == "UNIT_AURA") then
            self:FindAura()
        elseif (event == "UNIT_HEALTH") then
            local currentHealth = UnitHealth(unit)
            if currentHealth ~= 0 then
                self:SetStatusText()
                self.HealthBar:SetValue(currentHealth)
                self:UpdateHealPrediction()
                self:UpdateAbsorb()
                self.DeathIcon:SetShown(false)
                self.hideStatusText = false
                self.currentHealth = currentHealth
                if self.isFeigningDeath then
                    self.HealthBar:SetAlpha(1)
                    self.isFeigningDeath = nil
                end
            else
                self:SetLifeState()
            end
        elseif (event == "UNIT_MAXHEALTH") then
            self.HealthBar:SetMinMaxValues(0, UnitHealthMax(unit))
            self.HealthBar:SetValue(UnitHealth(unit))
            self:UpdateHealPrediction()
            self:UpdateAbsorb()
        elseif (event == "UNIT_POWER_UPDATE") then
            self:SetStatusText()
            self.PowerBar:SetValue(UnitPower(unit))
        elseif (event == "UNIT_MAXPOWER") then
            self.PowerBar:SetMinMaxValues(0, UnitPowerMax(unit))
            self.PowerBar:SetValue(UnitPower(unit))
        elseif (event == "UNIT_DISPLAYPOWER") then
            local _, powerType = UnitPowerType(unit)
            self:SetPowerType(powerType)
            self.PowerBar:SetMinMaxValues(0, UnitPowerMax(unit))
            self.PowerBar:SetValue(UnitPower(unit))
        elseif (event == "UNIT_ABSORB_AMOUNT_CHANGED") then
            self:UpdateHealPrediction()
            self:UpdateAbsorb()
        elseif (event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED") then
            self:UpdateHealPrediction()
            self:UpdateAbsorb()
        end
    elseif (event == "PLAYER_LOGIN") then
        self:UnregisterEvent("PLAYER_LOGIN")

        if (not db) then
            self.parent:Initialize()
        end

        self:Initialize()
    elseif (event == "PLAYER_ENTERING_WORLD") or (event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS") then
        self.Name:SetText("")
        self.CastBar:Hide()
        self.specTexture = nil
        self.class = nil
        self.currentClassIconTexture = nil
        self.currentClassIconStartTime = 0
        self.updateRacialOnTrinketSlot = nil
        self:UpdateVisible()
        self:ResetTrinket()
        self:ResetRacial()
        self:ResetDispel()
        self:ResetDR()
        self:UpdateHealPrediction()
        self:UpdateAbsorb()
        if UnitExists(self.unit) then
            self:UpdatePlayer("seen")
        else
            self:UpdatePlayer()
        end
        self:SetAlpha(1)
        self.HealthBar:SetAlpha(1)
        if TestTitle then
            TestTitle:Hide()
        end
    elseif (event == "PLAYER_REGEN_ENABLED") then
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self:UpdateVisible()
    end
end

function sArenaFrameMixin:Initialize()
    self:SetMysteryPlayer()
    self.parent:SetupDrag(self, self.parent, nil, "UpdateFrameSettings")
    self.parent:SetupDrag(self.CastBar, self.CastBar, "castBar", "UpdateCastBarSettings")
    self.parent:SetupDrag(self[sArenaMixin.drCategories[1]], self[sArenaMixin.drCategories[1]], "dr", "UpdateDRSettings")
    self.parent:SetupDrag(self.SpecIcon, self.SpecIcon, "specIcon", "UpdateSpecIconSettings")
    self.parent:SetupDrag(self.Trinket, self.Trinket, "trinket", "UpdateTrinketSettings")
    self.parent:SetupDrag(self.Racial, self.Racial, "racial", "UpdateRacialSettings")
    self.parent:SetupDrag(self.Dispel, self.Dispel, "dispel", "UpdateDispelSettings")
end

function sArenaFrameMixin:OnEnter()
    UnitFrame_OnEnter(self)

    self.HealthText:Show()
    self.PowerText:Show()
end

function sArenaFrameMixin:OnLeave()
    UnitFrame_OnLeave(self)

    self:UpdateStatusTextVisible()
end

local function GetNumArenaOpponentsFallback()
    local count = 0
    for i = 1, sArenaMixin.maxArenaOpponents do
        if UnitExists("arena" .. i) then
            count = count + 1
        end
    end
    return count
end

function sArenaFrameMixin:UpdateVisible()
    if InCombatLockdown() then
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    local _, instanceType = IsInInstance()
    if instanceType ~= "arena" then
        self:Hide()
        return
    end

    local id = self:GetID()
    local numSpecs = GetNumArenaOpponentSpecs()
    local numOpponents = (numSpecs == 0) and GetNumArenaOpponentsFallback() or numSpecs

    if numOpponents >= id then
        self:Show()
    else
        self:Hide()
    end
end


local function addToMasque(frame, masqueGroup)
    masqueGroup:AddButton(frame)
end

function sArenaMixin:AddMasqueSupport()
    if not self.db.profile.enableMasque or masqueOn or not C_AddOns.IsAddOnLoaded("Masque") then return end
    local Masque = LibStub("Masque", true)
    masqueOn = true

    local sArenaClass = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Class/Aura")
    local sArenaTrinket = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Trinket")
    local sArenaSpecIcon = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "SpecIcon")
    local sArenaRacial = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Racial")
    local sArenaDispel = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Dispel")
    local sArenaDRs = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "DRs")
    local sArenaFrame = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Frame")
    local sArenaCastbar = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Castbar")
    local sArenaCastbarIcon = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Castbar Icon")

    function sArenaMixin:RefreshMasque()
        sArenaClass:ReSkin(true)
        sArenaTrinket:ReSkin(true)
        sArenaSpecIcon:ReSkin(true)
        sArenaRacial:ReSkin(true)
        sArenaDispel:ReSkin(true)
        sArenaDRs:ReSkin(true)
        sArenaFrame:ReSkin(true)
        sArenaCastbarIcon:ReSkin(true)
    end

    local function MsqSkinIcon(frame, group)
        local skinWrapper = CreateFrame("Frame")
        skinWrapper:SetParent(frame)
        skinWrapper:SetSize(30, 30)
        skinWrapper:SetAllPoints(frame.Icon)
        frame.MSQ = skinWrapper
        frame.Icon:Hide()
        frame.SkinnedIcon = skinWrapper:CreateTexture(nil, "BACKGROUND")
        frame.SkinnedIcon:SetSize(30, 30)
        frame.SkinnedIcon:SetPoint("CENTER")
        frame.SkinnedIcon:SetTexture(frame.Icon:GetTexture())
        hooksecurefunc(frame.Icon, "SetTexture", function(_, tex)
            skinWrapper:SetScale(frame.Icon:GetScale())
            frame.SkinnedIcon:SetTexture(tex)
        end)
        group:AddButton(skinWrapper, {
            Icon = frame.SkinnedIcon,
        })
    end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        frame.FrameMsq = CreateFrame("Frame", nil, frame)
        frame.FrameMsq:SetFrameStrata("HIGH")
        frame.FrameMsq:SetPoint("TOPLEFT", frame.HealthBar, "TOPLEFT", 0, 0)
        frame.FrameMsq:SetPoint("BOTTOMRIGHT", frame.PowerBar, "BOTTOMRIGHT", 0, 0)

        frame.ClassIconMsq = CreateFrame("Frame", nil, frame)
        frame.ClassIconMsq:SetFrameStrata("DIALOG")
        frame.ClassIconMsq:SetAllPoints(frame.ClassIcon)

        frame.SpecIconMsq = CreateFrame("Frame", nil, frame)
        frame.SpecIconMsq:SetFrameStrata("DIALOG")
        frame.SpecIconMsq:SetAllPoints(frame.SpecIcon)

        frame.TrinketMsq = CreateFrame("Frame", nil, frame)
        frame.TrinketMsq:SetFrameStrata("DIALOG")
        frame.TrinketMsq:SetAllPoints(frame.Trinket)

        frame.RacialMsq = CreateFrame("Frame", nil, frame)
        frame.RacialMsq:SetFrameStrata("DIALOG")
        frame.RacialMsq:SetAllPoints(frame.Racial)

        frame.DispelMsq = CreateFrame("Frame", nil, frame)
        frame.DispelMsq:SetFrameStrata("DIALOG")
        frame.DispelMsq:SetAllPoints(frame.Dispel)

        frame.CastBarMsq = CreateFrame("Frame", nil, frame.CastBar)
        frame.CastBarMsq:SetFrameStrata("HIGH")
        frame.CastBarMsq:SetAllPoints(frame.CastBar)

        addToMasque(frame.FrameMsq, sArenaFrame)
        addToMasque(frame.ClassIconMsq, sArenaClass)
        addToMasque(frame.SpecIconMsq, sArenaSpecIcon)
        addToMasque(frame.TrinketMsq, sArenaTrinket)
        addToMasque(frame.RacialMsq, sArenaRacial)
        addToMasque(frame.DispelMsq, sArenaDispel)
        addToMasque(frame.CastBarMsq, sArenaCastbar)
        MsqSkinIcon(frame.CastBar, sArenaCastbarIcon)

        frame.CastBar.MSQ:SetFrameStrata("DIALOG")

        -- Add MasqueBorderHook for Trinket
        if not frame.Trinket.MasqueBorderHook then
            hooksecurefunc(frame.Trinket.Texture, "SetTexture", function(self, t)
                if t == nil or t == "" or t == 0 or t == "nil" then
                    if frame.TrinketMsq then
                        frame.TrinketMsq:Hide()
                    end
                else
                    if frame.TrinketMsq and frame.parent.db.profile.enableMasque then
                        frame.TrinketMsq:Hide()
                        frame.TrinketMsq:Show()
                    end
                end
            end)
            frame.Trinket.MasqueBorderHook = true
        end

        -- Add MasqueBorderHook for Racial
        if not frame.Racial.MasqueBorderHook then
            hooksecurefunc(frame.Racial.Texture, "SetTexture", function(self, t)
                if t == nil or t == "" or t == 0 or t == "nil" then
                    if frame.RacialMsq then
                        frame.RacialMsq:Hide()
                    end
                else
                    if frame.RacialMsq and frame.parent.db.profile.enableMasque then
                        frame.RacialMsq:Hide()
                        frame.RacialMsq:Show()
                    end
                end
            end)
            frame.Racial.MasqueBorderHook = true
        end

        -- Add MasqueBorderHook for Dispel
        if not frame.Dispel.MasqueBorderHook then
            hooksecurefunc(frame.Dispel.Texture, "SetTexture", function(self, t)
                if t == nil or t == "" or t == 0 or t == "nil" then
                    if frame.DispelMsq then
                        frame.DispelMsq:Hide()
                    end
                else
                    if frame.DispelMsq and frame.parent.db.profile.enableMasque then
                        frame.DispelMsq:Hide()
                        frame.DispelMsq:Show()
                    end
                end
            end)
            frame.Dispel.MasqueBorderHook = true
        end

        -- DR frames
        for _, category in ipairs(self.drCategories) do
            local drFrame = frame[category]
            if drFrame then
                addToMasque(drFrame, sArenaDRs)
            end
        end
    end
end

function sArenaFrameMixin:UpdateNameColor()
    if not self.Name:IsShown() then return end

    local class = (self.unit and select(2, UnitClass(self.unit))) or self.tempClass
    if not class then return end

    local color = RAID_CLASS_COLORS[class]
    if self.parent.db.profile.classColorNames and color then
        if not self.oldNameColor then
            local r, g, b, a = self.Name:GetTextColor()
            self.oldNameColor = {r, g, b, a}
        end
        self.Name:SetTextColor(color.r, color.g, color.b, 1)
    else
        if self.oldNameColor then
            self.Name:SetTextColor(unpack(self.oldNameColor))
            self.oldNameColor = nil
        end
    end
end

function sArenaFrameMixin:UpdatePlayer(unitEvent)
    local unit = self.unit

    self:GetClass()
    self:FindAura()

    if (unitEvent and unitEvent ~= "seen") or (UnitGUID(self.unit) == nil) then
        self:SetMysteryPlayer()
        return
    end

    C_PvP.RequestCrowdControlSpell(unit)

    self:UpdateRacial()
    self:UpdateDispel()

    -- Prevent castbar and other frames from intercepting mouse clicks during a match
    if (unitEvent == "seen") then
        self.parent:SetMouseState(false)
    end

    self.hideStatusText = false

    if (db.profile.showNames) then
        self.Name:SetText(UnitName(unit))
        self:UpdateNameColor()
        self.Name:SetShown(true)
    elseif (db.profile.showArenaNumber) then
        self.Name:SetText(self.unit)
        self:UpdateNameColor()
        self.Name:SetShown(true)
    end

    self:UpdateStatusTextVisible()
    self:SetStatusText()

    self:OnEvent("UNIT_MAXHEALTH", unit)
    self:OnEvent("UNIT_HEALTH", unit)
    self:OnEvent("UNIT_MAXPOWER", unit)
    self:OnEvent("UNIT_POWER_UPDATE", unit)
    self:OnEvent("UNIT_DISPLAYPOWER", unit)
    self:OnEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)

    local color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]

    if (color and db.profile.classColors) then
        self.HealthBar:SetStatusBarColor(color.r, color.g, color.b, 1.0)
    else
        self.HealthBar:SetStatusBarColor(0, 1.0, 0, 1.0)
    end

    self:SetAlpha(1)
end

function sArenaFrameMixin:SetMysteryPlayer()
    local hp = self.HealthBar
    hp:SetMinMaxValues(0, 100)
    hp:SetValue(100)

    local pp = self.PowerBar
    pp:SetMinMaxValues(0, 100)
    pp:SetValue(100)

    if self.parent.db and self.parent.db.profile.colorMysteryGray then -- TODO: Figure out cleaner fix, why db is nil here.
        hp:SetStatusBarColor(0.5, 0.5, 0.5)
        pp:SetStatusBarColor(0.5, 0.5, 0.5)
    else
        local class = self.class or self.tempClass
        local color = class and RAID_CLASS_COLORS[class]

        if color and self.parent.db and self.parent.db.profile.classColors then
            hp:SetStatusBarColor(color.r, color.g, color.b)
        else
            hp:SetStatusBarColor(0, 1.0, 0)
        end

        local powerType
        if class == "DRUID" then
            local specName = self.specName
            if specName == "Feral" then
                powerType = "ENERGY"
            elseif specName == "Guardian" then
                powerType = "RAGE"
            else
                powerType = "MANA"
            end
        elseif class == "MONK" then
            local specName = self.specName
            if specName == "Mistweaver" then
                powerType = "MANA"
            else
                powerType = "ENERGY"
            end
        else
            powerType = class and classPowerType[class] or "MANA"
        end

        local powerColor = PowerBarColor[powerType]
        if powerColor then
            pp:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)
        else
            pp:SetStatusBarColor(0, 0, 1.0)
        end

        self:SetAlpha(stealthAlpha)
    end

    self.hideStatusText = true
    self:SetStatusText()

    self.DeathIcon:Hide()
end

function sArenaFrameMixin:GetClass()
    local _, instanceType = IsInInstance()

    if (instanceType ~= "arena") then
        self.specTexture = nil
        self.class = nil
        self.classLocal = nil
        self.specName = nil
        self.specID = nil
        self.isHealer = nil
        self.SpecIcon:Hide()
        self.SpecNameText:SetText("")
    elseif (not self.class) then
        local id = self:GetID()
        if (GetNumArenaOpponentSpecs() >= id) then
            local specID = GetArenaOpponentSpec(id) or 0
            if (specID > 0) then
                local _, specName, _, specTexture, _, class, classLocal = GetSpecializationInfoByID(specID)
                self.class = class
                self.classLocal = classLocal
                self.specID = specID
                self.specName = specName
                self.isHealer = sArenaMixin.healerSpecIDs[specID] or false
                self.SpecNameText:SetText(specName)
                self.SpecNameText:SetShown(db.profile.layoutSettings[db.profile.currentLayout].showSpecManaText)
                self.specTexture = specTexture
                self.class = class
                self:UpdateSpecIcon()
                self:UpdateFrameColors()
                sArenaMixin:UpdateTextures()
            end
        end

        if (not self.class and UnitExists(self.unit)) then
            self.classLocal, self.class = UnitClass(self.unit)
        end
    end
end


function sArenaFrameMixin:UpdateClassIcon()
	if (self.currentAuraSpellID and self.currentAuraDuration > 0 and self.currentClassIconStartTime ~= self.currentAuraStartTime) then
		self.ClassIconCooldown:SetCooldown(self.currentAuraStartTime, self.currentAuraDuration)
		self.currentClassIconStartTime = self.currentAuraStartTime
	elseif (self.currentAuraDuration == 0) then
		self.ClassIconCooldown:Clear()
		self.currentClassIconStartTime = 0
	end

	local texture = self.currentAuraSpellID and self.currentAuraTexture or self.class and "class" or 134400

	if (self.currentClassIconTexture == texture) then return end

	self.currentClassIconTexture = texture

    local useHealerTexture

    if (texture == "class") then

        if db.profile.replaceHealerIcon and self.isHealer then
            useHealerTexture = true
        end

        if db.profile.hideClassIcon then
            texture = nil
            if self.ClassIconMsq then
                self.ClassIconMsq:Hide()
            end
            if self.PixelBorders and self.PixelBorders.classIcon then
                self.PixelBorders.classIcon:Hide()
            end
        elseif db.profile.layoutSettings[db.profile.currentLayout].replaceClassIcon and self.specTexture then
            texture = self.specTexture
            if self.ClassIconMsq then
                self.ClassIconMsq:Show()
            end
            if self.PixelBorders and self.PixelBorders.classIcon then
                self.PixelBorders.classIcon:Show()
            end
        else
            texture = sArenaMixin.classIcons[self.class]
            if self.ClassIconMsq then
                self.ClassIconMsq:Show()
            end
            if self.PixelBorders and self.PixelBorders.classIcon then
                self.PixelBorders.classIcon:Show()
            end
        end

        if useHealerTexture then
            self.ClassIcon:SetAtlas("UI-LFG-RoleIcon-Healer")
        else
            self.ClassIcon:SetTexture(texture)
        end

        local cropType = useHealerTexture and "healer" or "class"
        self:SetTextureCrop(self.ClassIcon, db.profile.layoutSettings[db.profile.currentLayout].cropIcons, cropType)

		return
	end
	self:SetTextureCrop(self.ClassIcon, db and db.profile.layoutSettings[db.profile.currentLayout].cropIcons, "class")
	self.ClassIcon:SetTexture(texture)
    if self.ClassIconMsq then
        self.ClassIconMsq:Show()
    end
    if self.PixelBorders and self.PixelBorders.classIcon then
        self.PixelBorders.classIcon:Show()
    end
end

-- Returns the spec icon texture based on arena unit ID (1-5)
function sArenaFrameMixin:UpdateSpecIcon()
    if not db.profile.layoutSettings[db.profile.currentLayout].replaceClassIcon then
        self.SpecIcon.Texture:SetTexture(self.specTexture)
        self.SpecIcon:Show()
        if self.SpecIconMsq then
            self.SpecIconMsq:Show()
        end
        if self.PixelBorders and self.PixelBorders.classIcon then
            self.PixelBorders.classIcon:Show()
        end
    else
        self.SpecIcon:Hide()
        if self.SpecIconMsq then
            self.SpecIconMsq:Hide()
        end
        if self.PixelBorders and self.PixelBorders.specIcon then
            self.PixelBorders.specIcon:Hide()
        end
    end
end

local function ResetStatusBar(f)
    f:ClearAllPoints()
    f:SetSize(0, 0)
    f:SetScale(1)
end

local function ResetFontString(f)
    f:SetDrawLayer("OVERLAY", 1)
    f:SetJustifyH("CENTER")
    f:SetJustifyV("MIDDLE")
    f:SetTextColor(1, 0.82, 0, 1)
    f:SetShadowColor(0, 0, 0, 1)
    f:SetShadowOffset(1, -1)
    f:ClearAllPoints()
    f:Hide()
end

function sArenaFrameMixin:ResetLayout()
    self.currentClassIconTexture = nil
    self.currentClassIconStartTime = 0
    self.oldNameColor = nil

    ResetTexture(nil, self.ClassIcon)
    ResetStatusBar(self.HealthBar)
    ResetStatusBar(self.PowerBar)
    ResetStatusBar(self.CastBar)
    self.CastBar:SetHeight(16)

    local ogBg = select(1, self.CastBar:GetRegions())
    if ogBg then
        ogBg:Show()
    end

    if self.CastBar.BorderShield then
        self.CastBar.BorderShield:SetTexture(330124)
    end

    self.ClassIconCooldown:SetUseCircularEdge(false)
    self.ClassIconCooldown:SetSwipeTexture(1)
    self.AuraStacks:SetPoint("BOTTOMLEFT", self.ClassIcon, "BOTTOMLEFT", 2, 0)
    self.AuraStacks:SetFont("Interface\\AddOns\\sArena_Reloaded\\Textures\\arialn.ttf", 13, "THICKOUTLINE")
    self.DispelStacks:SetPoint("BOTTOMLEFT", self.Dispel.Texture, "BOTTOMLEFT", 2, 0)
    self.DispelStacks:SetFont("Interface\\AddOns\\sArena_Reloaded\\Textures\\arialn.ttf", 15, "THICKOUTLINE")

    self.ClassIcon:RemoveMaskTexture(self.ClassIconMask)
    self.ClassIcon:SetDrawLayer("BORDER", 1)
    if self.frameTexture then
        self.frameTexture:SetDrawLayer("ARTWORK", 2)
        self.frameTexture:SetDesaturated(false)
        self.frameTexture:SetVertexColor(1, 1, 1)
        self.frameTexture:Hide()
    end

    if self.ppUnderlay then
        self.hpUnderlay:SetColorTexture(0, 0, 0, 0.65)
        self.ppUnderlay:SetColorTexture(0, 0, 0, 0.65)
    end

    if self.CastBar.Border then
        self.CastBar.Border:SetDesaturated(false)
        self.CastBar.Border:SetVertexColor(1, 1, 1)
    end

    if self.Trinket.Border then
        self.Trinket.Border:SetDesaturated(false)
        self.Trinket.Border:SetVertexColor(1, 1, 1)
        self.Racial.Border:SetDesaturated(false)
        self.Racial.Border:SetVertexColor(1, 1, 1)
        self.Dispel.Border:SetDesaturated(false)
        self.Dispel.Border:SetVertexColor(1, 1, 1)
    end

    if self.SpecIcon.Border then
        self.SpecIcon.Border:SetDesaturated(false)
        self.SpecIcon.Border:SetVertexColor(1, 1, 1)
        self.SpecIcon.Border:SetTexture(nil)
    end

    if self.SpecIcon.Mask then
        self.SpecIcon.Texture:RemoveMaskTexture(self.SpecIcon.Mask)
    end
    self.SpecIcon.Texture:SetTexCoord(0, 1, 0, 1)

    if self.NameBackground then
        self.NameBackground:Hide()
    end

    local cropIcons = db.profile.layoutSettings[db.profile.currentLayout].cropIcons

    local f = self.Trinket
    f:ClearAllPoints()
    f:SetSize(0, 0)
    if f.Mask then
        f.Texture:RemoveMaskTexture(f.Mask)
        f.Cooldown:SetSwipeTexture(1)
    end
    self:SetTextureCrop(f.Texture, cropIcons)

    local f = self.Dispel
    f:ClearAllPoints()
    f:SetSize(0, 0)
    if f.Mask then
        f.Texture:RemoveMaskTexture(f.Mask)
        f.Cooldown:SetSwipeTexture(1)
    end
    self:SetTextureCrop(f.Texture, cropIcons)

    f = self.ClassIcon
    self:SetTextureCrop(f, cropIcons)

    f = self.Racial
    f:ClearAllPoints()
    f:SetSize(0, 0)
    if f.Mask then
        f.Texture:RemoveMaskTexture(f.Mask)
        f.Cooldown:SetSwipeTexture(1)
    end
    self:SetTextureCrop(f.Texture, cropIcons)

    f = self.SpecIcon
    f:ClearAllPoints()
    f:SetSize(0, 0)
    f:SetScale(1)
    f.Texture:RemoveMaskTexture(f.Mask)
    self:SetTextureCrop(f.Texture, cropIcons)

    f = self.Name
    ResetFontString(f)
    f:SetDrawLayer("ARTWORK", 2)
    f:SetFontObject("SystemFont_Shadow_Small2")
    f:SetShadowColor(0, 0, 0, 1)
    f:SetShadowOffset(1, -1)

    f = self.SpecNameText
    ResetFontString(f)
    f:SetDrawLayer("OVERLAY", 6)
    f:SetFontObject("SystemFont_Shadow_Small2")
    f:SetScale(1)
    f:SetShadowColor(0, 0, 0, 1)
    f:SetShadowOffset(1, -1)

    f = self.HealthText
    ResetFontString(f)
    f:SetDrawLayer("ARTWORK", 2)
    f:SetFontObject("SystemFont_Shadow_Small2")
    f:SetTextColor(1, 1, 1, 1)
    f:SetShadowColor(0, 0, 0, 1)
    f:SetShadowOffset(1, -1)

    f = self.PowerText
    ResetFontString(f)
    f:SetDrawLayer("ARTWORK", 2)
    f:SetFontObject("SystemFont_Shadow_Small2")
    f:SetTextColor(1, 1, 1, 1)
    f:SetShadowColor(0, 0, 0, 1)
    f:SetShadowOffset(1, -1)

    f = self.CastBar
    f.Icon:SetTexCoord(0, 1, 0, 1)
    local fontName,s,o = f.Text:GetFont()
    f.Text:SetFont(fontName, s, "THINOUTLINE")

    self.TexturePool:ReleaseAll()
end

function sArenaFrameMixin:SetPowerType(powerType)
    local color = PowerBarColor[powerType]
    if color then
        self.PowerBar:SetStatusBarColor(color.r, color.g, color.b)
    end
end

function sArenaFrameMixin:SetLifeState()
    local unit = self.unit
    local isFeigningDeath = self.class == "HUNTER" and AuraUtil.FindAuraByName(FEIGN_DEATH, unit, "HELPFUL")
    local isDead = UnitIsDeadOrGhost(unit) and not isFeigningDeath

    self.DeathIcon:SetShown(isDead)
    self.hideStatusText = isDead
    if (isDead) then
        self:SetStatusText()
        self.HealthBar:SetValue(0)
        self:UpdateHealPrediction()
        self:UpdateAbsorb()
        self.currentHealth = 0
        self.SpecNameText:SetText("")
        self:ResetDR()
    elseif isFeigningDeath then
        self.HealthBar:SetAlpha(0.55)
        self.isFeigningDeath = true
    end
end

local function FormatLargeNumbers(value)
    if value >= 1000000 then
        -- For millions, show 2 decimal places (e.g., 1.80M)
        return string.format("%.2f M", value / 1000000)
    elseif value >= 1000 then
        -- For thousands, show no decimals (e.g., 392K)
        return string.format("%d K", value / 1000)
    else
        return tostring(value)
    end
end

function sArenaFrameMixin:SetStatusText(unit)
    if (self.hideStatusText) then
        self.HealthText:SetFontObject("SystemFont_Shadow_Small2")
        self.HealthText:SetText("")
        self.PowerText:SetFontObject("SystemFont_Shadow_Small2")
        self.PowerText:SetText("")
        return
    end

    if self.isFeigningDeath then return end

    if (not unit) then
        unit = self.unit
    end

    local hp = UnitHealth(unit)
    local hpMax = UnitHealthMax(unit)
    local pp = UnitPower(unit)
    local ppMax = UnitPowerMax(unit)

    if (db.profile.statusText.usePercentage) then
        local hpPercent = (hpMax > 0) and ceil((hp / hpMax) * 100) or 0
        local ppPercent = (ppMax > 0) and ceil((pp / ppMax) * 100) or 0

        self.HealthText:SetText(hpPercent .. "%")
        self.PowerText:SetText(ppPercent .. "%")
    else
        if db.profile.statusText.formatNumbers then
            self.HealthText:SetText(FormatLargeNumbers(hp))
            self.PowerText:SetText(FormatLargeNumbers(pp))
        else
            self.HealthText:SetText(AbbreviateLargeNumbers(hp))
            self.PowerText:SetText(AbbreviateLargeNumbers(pp))
        end
    end
end

function sArenaFrameMixin:UpdateStatusTextVisible()
    self.HealthText:SetShown(db.profile.statusText.alwaysShow)
    self.PowerText:SetShown(db.profile.statusText.alwaysShow)
    self.PowerText:SetAlpha(db.profile.hidePowerText and 0 or 1)
end

local specTemplates = {
    BM_HUNTER = {
        class = "HUNTER",
        specIcon = 461112,
        castName = "Cobra Shot",
        castIcon = 461114,
        racial = 132089,
        race = "Orc",
        specName = "Beast Mastery",
        unint = true,
    },
    MM_HUNTER = {
        class = "HUNTER",
        specIcon = 461113,
        castName = "Aimed Shot",
        castIcon = 132222,
        racial = 136225,
        race = "NightElf",
        specName = "Marksmanship",
        unint = true,
    },
    SURV_HUNTER = {
        class = "HUNTER",
        specIcon = 461113,
        castName = "Mending Bandage",
        castIcon = isRetail and 1014022 or 133690,
        racial = 136225,
        race = "NightElf",
        specName = "Survival",
        channel = true,
    },
    ELE_SHAMAN = {
        class = "SHAMAN",
        specIcon = 136048,
        castName = "Lightning Bolt",
        castIcon = 136048,
        racial = 135923,
        race = "Orc",
        specName = "Elemental",
    },
    ENH_SHAMAN = {
        class = "SHAMAN",
        specIcon = 237581,
        castName = "Stormstrike",
        castIcon = 132314,
        racial = 135923,
        race = "Orc",
        specName = "Enhancement",
    },
    RESTO_SHAMAN = {
        class = "SHAMAN",
        specIcon = 136052,
        castName = "Healing Wave",
        castIcon = 136052,
        racial = 135726,
        race = "Troll",
        specName = "Restoration",
    },
    RESTO_DRUID = {
        class = "DRUID",
        specIcon = 136041,
        castName = "Regrowth",
        castIcon = 136085,
        racial = 132089,
        race = "NightElf",
        specName = "Restoration",
    },
    AFF_WARLOCK = {
        class = "WARLOCK",
        specIcon = 136145,
        castName = "Fear",
        castIcon = 136183,
        racial = 135726,
        race = "Scourge",
        specName = "Affliction",
    },
    DESTRO_WARLOCK = {
        class = "WARLOCK",
        specIcon = 136145,
        castName = "Chaos Bolt",
        castIcon = 136186,
        racial = 135726,
        race = "Scourge",
        specName = "Destruction",
    },
    ARMS_WARRIOR = {
        class = "WARRIOR",
        specIcon = 132355,
        castName = "Slam",
        castIcon = 132340,
        racial = 132309,
        race = "Human",
        specName = "Arms",
        unint = true,
    },
    DISC_PRIEST = {
        class = "PRIEST",
        specIcon = 135940,
        castName = "Penance",
        castIcon = 237545,
        racial = 136187,
        race = "Human",
        specName = "Discipline",
        channel = true,
    },
    HOLY_PRIEST = {
        class = "PRIEST",
        specIcon = 237542,
        castName = "Holy Fire",
        castIcon = 135972,
        racial = 136187,
        race = "Human",
        specName = "Holy",
    },
    FERAL_DRUID = {
        class = "DRUID",
        specIcon = 132115,
        castName = "Cyclone",
        castIcon = 132469,
        racial = 132089,
        race = "NightElf",
        specName = "Feral",
    },
    FROST_MAGE = {
        class = "MAGE",
        specIcon = 135846,
        castName = "Frostbolt",
        castIcon = 135846,
        racial = 136129,
        race = "Human",
        specName = "Frost",
    },
    ARCANE_MAGE = {
        class = "MAGE",
        specIcon = 135932,
        castName = "Arcane Blast",
        castIcon = 135735,
        racial = 136129,
        race = "Human",
        specName = "Arcane",
    },
    FIRE_MAGE = {
        class = "MAGE",
        specIcon = 135810,
        castName = "Pyroblast",
        castIcon = 135808,
        racial = 135991,
        race = "Gnome",
        specName = "Fire",
    },
    RET_PALADIN = {
        class = "PALADIN",
        specIcon = 135873,
        castName = "Feet Up",
        castIcon = 133029,
        racial = 136129,
        race = "Human",
        specName = "Retribution",
    },
    UNHOLY_DK = {
        class = "DEATHKNIGHT",
        specIcon = 135775,
        racial = 135726,
        race = "Scourge",
        specName = "Unholy",
        castName = "Army of the Dead",
        castIcon = 237511,
        channel = true,
    },
    SUB_ROGUE = {
        class = "ROGUE",
        specIcon = 132320,
        castName = "Crippling Poison",
        castIcon = 132273,
        racial = 132089,
        race = "Orc",
        specName = "Subtlety",
        unint = true,
    },
}

local testPlayers = {
    { template = "BM_HUNTER", name = "Despytimes" },
    { template = "MM_HUNTER", name = "Jellybeans" },
    { template = "SURV_HUNTER", name = "Bicmex" },
    { template = "ELE_SHAMAN", name = "Bluecheese" },
    { template = "ENH_SHAMAN", name = "Saul" },
    { template = "RESTO_SHAMAN", name = "Cdew" },
    { template = "RESTO_SHAMAN", name = "Absterge" },
    { template = "RESTO_SHAMAN", name = "Lontarito" },
    { template = "RESTO_SHAMAN", name = "Foxyllama" },
    { template = "ELE_SHAMAN", name = "Whaazzlasso", castName = "Feet Up", castIcon = 133029 },
    { template = "RESTO_DRUID", name = "Metaphors" },
    { template = "RESTO_DRUID", name = "Flop" },
    { template = "FERAL_DRUID", name = "Sodapoopin" },
    { template = "FERAL_DRUID", name = "Bean" },
    { template = "FERAL_DRUID", name = "Snupy" },
    { template = "FERAL_DRUID", name = "Whaazzform" },
    { template = "AFF_WARLOCK", name = "Chan" },
    { template = "DESTRO_WARLOCK", name = "Merce" },
    { template = "DESTRO_WARLOCK", name = "Infernion" },
    { template = "DESTRO_WARLOCK", name = "Jazggz" },
    { template = "ARMS_WARRIOR", name = "Trillebartom" },
    { template = "DISC_PRIEST", name = "Hydra" },
    { template = "HOLY_PRIEST", name = "Mehh" },
    { template = "FROST_MAGE", name = "Raiku" },
    { template = "FROST_MAGE", name = "Samiyam" },
    { template = "FROST_MAGE", name = "Aeghis" },
    { template = "FROST_MAGE", name = "Venruki" },
    { template = "FROST_MAGE", name = "Xaryu" },
    { template = "FIRE_MAGE", name = "Hansol" },
    { template = "ARCANE_MAGE", name = "Ziqo" },
    { template = "ARCANE_MAGE", name = "Mmrklepter" },
    { template = "RET_PALADIN", name = "Judgewhaazz" },
    { template = "UNHOLY_DK", name = "Darthchan" },
    { template = "UNHOLY_DK", name = "Mes" },
    { template = "SUB_ROGUE", name = "Nahj" },
    { template = "SUB_ROGUE", name = "Invisbull", racial = 132368, race = "Human" },
    { template = "SUB_ROGUE", name = "Cshero" },
    { template = "SUB_ROGUE", name = "Pshero" },
    { template = "SUB_ROGUE", name = "Whaazz" },
    { template = "SUB_ROGUE", name = "Pikawhoo" },
    { template = "ARMS_WARRIOR", name = "Magnusz" },
}

local function ExpandTemplates()
    for _, player in ipairs(testPlayers) do
        local template = specTemplates[player.template]
        if template then
            for k, v in pairs(template) do
                if player[k] == nil then
                    player[k] = v
                end
            end
            player.template = nil
        end
    end
    testActive = true
end

local function Shuffle()
    local MAX = (sArenaMixin and sArenaMixin.maxArenaOpponents) or 3
    if MAX < 1 then return {} end

    local HEALER_SPECS = { Restoration = true, Discipline = true, Holy = true, Mistweaver = true, Preservation = true }
    local function isHealer(p) return HEALER_SPECS[p.specName] == true end

    local byClass, nonHealerByClass, healerList, classes = {}, {}, {}, {}

    for _, p in ipairs(testPlayers) do
        local cls = p.class
        if not byClass[cls] then
            byClass[cls] = {}
            nonHealerByClass[cls] = {}
            table.insert(classes, cls)
        end
        table.insert(byClass[cls], p)
        if isHealer(p) then
            table.insert(healerList, p)
        else
            table.insert(nonHealerByClass[cls], p)
        end
    end

    local chosen, usedClass = {}, {}

    -- 1) Pick exactly one healer (if any)
    if #healerList > 0 then
        local hp = healerList[math.random(#healerList)]
        table.insert(chosen, hp)
        --usedClass[hp.class] = true
    end

    -- 2) Fill remaining slots with NON-healers, preferring unique classes
    local candidateClasses = {}
    for _, cls in ipairs(classes) do
        if not usedClass[cls] and #nonHealerByClass[cls] > 0 then
            table.insert(candidateClasses, cls)
        end
    end
    -- shuffle classes
    for i = #candidateClasses, 2, -1 do
        local j = math.random(i)
        candidateClasses[i], candidateClasses[j] = candidateClasses[j], candidateClasses[i]
    end
    -- pick one non-healer from as many unique classes as possible
    for _, cls in ipairs(candidateClasses) do
        if #chosen >= MAX then break end
        local pool = nonHealerByClass[cls]
        table.insert(chosen, pool[math.random(#pool)])
        usedClass[cls] = true
    end

    -- 3) If still short of MAX (e.g., not enough unique classes), allow duplicates but still NO extra healers
    if #chosen < MAX then
        local flatNonHealers = {}
        for _, pool in pairs(nonHealerByClass) do
            for _, p in ipairs(pool) do table.insert(flatNonHealers, p) end
        end
        -- Fallback: if there were zero non-healers at all, fill with healers (only case we can’t enforce “only 1”)
        local fallbackPool = (#flatNonHealers > 0) and flatNonHealers or healerList
        while #chosen < MAX and #fallbackPool > 0 do
            table.insert(chosen, fallbackPool[math.random(#fallbackPool)])
        end
    end

    -- 4) Final shuffle so healer isn’t always first
    for i = #chosen, 2, -1 do
        local j = math.random(i)
        chosen[i], chosen[j] = chosen[j], chosen[i]
    end

    -- Trim just in case (shouldn't happen, but safe)
    while #chosen > MAX do table.remove(chosen) end

    return chosen
end

function sArenaMixin:Test()
    local _, instanceType = IsInInstance()
    if (InCombatLockdown() or instanceType == "arena") then return end

    local currTime = GetTime()
    if not testActive then
        ExpandTemplates()
    end
    local shuffledPlayers = Shuffle()
    local cropIcons = db.profile.layoutSettings[db.profile.currentLayout].cropIcons
    local replaceClassIcon = db.profile.layoutSettings[db.profile.currentLayout].replaceClassIcon
    local hideClassIcon = db.profile.hideClassIcon
    local colorTrinket = db.profile.colorTrinket
    local modernCastbars = db.profile.layoutSettings[db.profile.currentLayout].castBar.useModernCastbars
    local keepDefaultModernTextures = db.profile.layoutSettings[db.profile.currentLayout].castBar.keepDefaultModernTextures

    local topFrame
    local numUnits = math.min(sArenaMixin.testUnits or sArenaMixin.maxArenaOpponents, sArenaMixin.maxArenaOpponents)

    for i = 1, numUnits do
        local frame = self["arena" .. i]
        local data = shuffledPlayers[i]

        if i == 1 then
            topFrame = frame
        end

        if masqueOn and frame.masqueHidden then
            frame.FrameMsq:Show()
            frame.ClassIconMsq:Show()
            frame.SpecIconMsq:Show()
            frame.CastBarMsq:Show()
            if frame.CastBar.MSQ then
                frame.CastBar.MSQ:Show()
                frame.CastBar.Icon:Hide()
            end
            frame.TrinketMsq:Show()
            frame.RacialMsq:Show()
            frame.DispelMsq:Show()
            frame.masqueHidden = false
        end

        frame.tempName = data.name
        frame.tempSpecName = data.specName
        frame.tempClass = data.class
        frame.class = data.class
        frame.tempSpecIcon = data.specIcon
        frame.replaceClassIcon = replaceClassIcon
        frame.isHealer = healerSpecNames[data.specName] or false

        frame:Show()
        frame:SetAlpha(1)
        frame.HealthBar:SetAlpha(1)

        frame.HealthBar:SetMinMaxValues(0, 100)
        frame.HealthBar:SetValue(100)

        if i == 2 then
            frame.HealthBar:SetValue(75)
        elseif i == 3 then
            frame.HealthBar:SetValue(45)
        end

        frame.PowerBar:SetMinMaxValues(0, 100)
        frame.PowerBar:SetValue(100)

        -- Class Icon and Spec Icon + Spec Name
        if hideClassIcon then
            frame.ClassIcon:SetTexture(nil)
            if frame.ClassIconMsq then
                frame.ClassIconMsq:Hide()
            end
            if frame.SpecIconMsq then
                frame.SpecIconMsq:Hide()
            end
        else
            if replaceClassIcon then
                frame.SpecIcon:Hide()
                frame.SpecIcon.Texture:SetTexture(nil)
                if frame.SpecIconMsq then
                    frame.SpecIconMsq:Hide()
                end
                frame.ClassIcon:SetTexture(data.specIcon, true)
            else
                frame.SpecIcon:Show()
                frame.SpecIcon.Texture:SetTexture(data.specIcon)
                if frame.SpecIconMsq then
                    frame.SpecIconMsq:Show()
                end
                frame.ClassIcon:SetTexture(self.classIcons[data.class])
            end
            if frame.ClassIconMsq then
                frame.ClassIconMsq:Show()
            end
        end

        local cropType
        if db.profile.replaceHealerIcon and frame.isHealer then
            frame.ClassIcon:SetAtlas("UI-LFG-RoleIcon-Healer")
            cropType = "healer"
        else
            cropType = "class"
        end

        frame:SetTextureCrop(frame.ClassIcon, cropIcons, cropType)

        frame.SpecNameText:SetText(data.specName)
        frame.SpecNameText:SetShown(db.profile.layoutSettings[db.profile.currentLayout].showSpecManaText)

        frame.ClassIconCooldown:SetCooldown(currTime, math.random(5, 35))

        frame.Name:SetText((db.profile.showArenaNumber and "arena" .. i) or data.name)
        frame.Name:SetShown(db.profile.showNames or db.profile.showArenaNumber)
        frame:UpdateNameColor()

        frame.race = data.race
        frame.unit = "arena" .. i

        local shouldForceHumanTrinket = not isRetail and data.race == "Human" and db.profile.forceShowTrinketOnHuman
        local shouldReplaceHumanRacial = not isRetail and data.race == "Human" and db.profile.replaceHumanRacialWithTrinket
        local shouldSwapRacialToTrinket = false

        frame.Trinket.Cooldown:SetCooldown(currTime, math.random(5, 35))
        if colorTrinket then
            if i <= 2 then
                frame.Trinket.Texture:SetColorTexture(0,1,0)
                frame.Trinket.Cooldown:Clear()
            else
                frame.Trinket.Texture:SetColorTexture(1,0,0)
            end
        else
            if shouldSwapRacialToTrinket then
                frame.Trinket.Texture:SetTexture(data.racial or 132089)
            elseif shouldForceHumanTrinket then
                frame.Trinket.Texture:SetTexture(133452)
            else
                frame.Trinket.Texture:SetTexture(sArenaMixin.trinketTexture)
            end
            frame.Trinket.Texture:SetDesaturated(false)
        end

        frame.updateRacialOnTrinketSlot = shouldSwapRacialToTrinket
        local shouldShowRacial = false

        if data.race and db.profile.racialCategories and db.profile.racialCategories[data.race] then
            shouldShowRacial = true
        end

        if shouldReplaceHumanRacial then
            frame.Racial.Texture:SetTexture(133452)
            frame.Racial.Cooldown:SetCooldown(currTime, math.random(5, 35))
            if frame.RacialMsq then
                frame.RacialMsq:Show()
            end
        elseif shouldShowRacial and not shouldSwapRacialToTrinket then
            frame.Racial.Texture:SetTexture(data.racial or 132089)
            frame.Racial.Cooldown:SetCooldown(currTime, math.random(5, 35))
            if frame.RacialMsq then
                frame.RacialMsq:Show()
            end
        else
            frame.Racial.Texture:SetTexture(nil)
            frame.Racial.Cooldown:Clear()
            if frame.RacialMsq then
                frame.RacialMsq:Hide()
            end
        end

        if db.profile.showDispels then
            local dispelInfo = frame:GetTestModeDispelData()
            if dispelInfo then
                frame.Dispel.Texture:SetTexture(dispelInfo.texture)
                frame.Dispel:Show()
                frame.Dispel.Cooldown:SetCooldown(currTime, math.random(5, 35))
            else
                frame.Dispel.Texture:SetTexture(nil)
                frame.Dispel:Hide()
            end
        else
            frame.Dispel.Texture:SetTexture(nil)
            frame.Dispel:Hide()
        end

        -- Colors
        local color = RAID_CLASS_COLORS[data.class]
        if (db.profile.classColors and color) then
            frame.HealthBar:SetStatusBarColor(color.r, color.g, color.b, 1)
        else
            frame.HealthBar:SetStatusBarColor(0, 1, 0, 1)
        end

        local powerType
        if data.class == "DRUID" then
            -- Check if druid is feral/guardian (energy) or balance/restoration (mana)
            if data.specName == "Feral" or data.specName == "Guardian" then
                powerType = "ENERGY"
            else
                powerType = "MANA"
            end
        else
            powerType = classPowerType[data.class] or "MANA"
        end
        local powerColor = PowerBarColor[powerType] or { r = 0, g = 0, b = 1 }

        frame.PowerBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)

        frame:UpdateFrameColors()

        -- DR Frames
        local drsEnabled = #self.drCategories
        if drsEnabled > 0 then
            local drCategoryOrder = {
                "Incapacitate",
                "Stun",
                "Root",
                "Disorient",
                "Silence",
            }
            local drCategoryTextures = {
                [1] = 136071,  -- Incap (Poly)
                [2] = 132298,  -- Stun (Kidney)
                [3] = 135848,  -- Root (Frost Nova)
                [4] = 136184,  -- Fear (Psychic Scream)
                [5] = 458230,  -- Silence
            }

            for n = 1, 4 do
                local drFrame = frame[drCategoryOrder[n]]
                local textureID = drCategoryTextures[n]
                drFrame.Icon:SetTexture(textureID)
                drFrame:Show()
                drFrame.Cooldown:SetCooldown(currTime, math.random(12, 25))

                local layout = self.db.profile.layoutSettings[self.db.profile.currentLayout]
                local blackDRBorder = layout.dr and layout.dr.blackDRBorder

                if (n == 1) then
                    local borderColor = blackDRBorder and {0, 0, 0, 1} or {1, 0, 0, 1}
                    local pixelBorderColor = blackDRBorder and {0, 0, 0, 1} or {1, 0, 0, 1}
                    drFrame.Border:SetVertexColor(unpack(borderColor))
                    if frame.PixelBorder then
                        frame.PixelBorder:SetVertexColor(unpack(pixelBorderColor))
                    end
                    drFrame.DRTextFrame.DRText:SetText("%")
                    drFrame.DRTextFrame.DRText:SetTextColor(1, 0, 0)
                    if drFrame.__MSQ_New_Normal then
                        drFrame.__MSQ_New_Normal:SetDesaturated(true)
                        drFrame.__MSQ_New_Normal:SetVertexColor(1, 0, 0, 1)
                    end
                else
                    local borderColor = blackDRBorder and {0, 0, 0, 1} or {0, 1, 0, 1}
                    local pixelBorderColor = blackDRBorder and {0, 0, 0, 1} or {0, 1, 0, 1}
                    drFrame.Border:SetVertexColor(unpack(borderColor))
                    if frame.PixelBorder then
                        frame.PixelBorder:SetVertexColor(unpack(pixelBorderColor))
                    end
                    drFrame.DRTextFrame.DRText:SetText("½")
                    drFrame.DRTextFrame.DRText:SetTextColor(0, 1, 0)
                    if drFrame.__MSQ_New_Normal then
                        drFrame.__MSQ_New_Normal:SetDesaturated(true)
                        drFrame.__MSQ_New_Normal:SetVertexColor(0, 1, 0, 1)
                    end
                end
            end
        end

        -- Cast Bar
        if data.castName then
            local layout = self.db.profile.layoutSettings[self.db.profile.currentLayout]
            local texKeys = layout.textures or {
                generalStatusBarTexture = "sArena Default",
                healStatusBarTexture    = "sArena Default",
                castbarStatusBarTexture = "sArena Default",
            }
            frame.CastBar.fadeOut = nil
            frame.CastBar:Show()
            frame.CastBar:SetAlpha(1)
            frame.CastBar.Icon:SetTexture(data.castIcon)
            frame.CastBar.Text:SetText(data.castName)

            if data.unint then
                frame.CastBar.BorderShield:Show()
                frame.CastBar:SetStatusBarColor(0.7, 0.7, 0.7, 1)
            else
                frame.CastBar.BorderShield:Hide()
                if data.channel then
                    frame.CastBar:SetStatusBarColor(0, 1, 0, 1)
                else
                    frame.CastBar:SetStatusBarColor(1, 0.7, 0, 1)
                end
            end

            if modernCastbars then
                if keepDefaultModernTextures then
                    frame.CastBar:SetStatusBarColor(1,1,1,1)
                    if isRetail then
                        frame.CastBar:SetStatusBarTexture(data.unint and "UI-CastingBar-Uninterruptable" or data.channel and "UI-CastingBar-Filling-Channel" or "ui-castingbar-filling-standard")
                    else
                        frame.CastBar:SetStatusBarTexture(data.unint and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Uninterruptable" or data.channel and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel" or "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard")
                    end
                else
                    local castPath = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarStatusBarTexture)
                    frame.CastBar:SetStatusBarTexture(castPath)
                end
            else
                local castPath = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarStatusBarTexture)
                frame.CastBar:SetStatusBarTexture(castPath)
            end
        else
            frame.CastBar.fadeOut = nil
            frame.CastBar:Hide()
            frame.CastBar:SetAlpha(0)
        end

        frame.hideStatusText = false

        local playerHpMax = UnitHealthMax("player")
        local playerPpMax = UnitPowerMax("player")

        local hpPercent = 100
        if i == 2 then
            hpPercent = 75
        elseif i == 3 then
            hpPercent = 45
        end

        local testHp = math.floor((playerHpMax * hpPercent) / 100)

        if (db.profile.statusText.usePercentage) then
            frame.HealthText:SetText(hpPercent .. "%")
            frame.PowerText:SetText("100%")
        else
            if db.profile.statusText.formatNumbers then
                frame.HealthText:SetText(FormatLargeNumbers(testHp))
                frame.PowerText:SetText(FormatLargeNumbers(playerPpMax))
            else
                frame.HealthText:SetText(AbbreviateLargeNumbers(testHp))
                frame.PowerText:SetText(AbbreviateLargeNumbers(playerPpMax))
            end
        end

        frame:UpdateStatusTextVisible()

        if masqueOn and not db.profile.enableMasque and frame.FrameMsq then
            frame.FrameMsq:Hide()
            frame.ClassIconMsq:Hide()
            frame.SpecIconMsq:Hide()
            frame.CastBarMsq:Hide()
            if frame.CastBar.MSQ then
                frame.CastBar.MSQ:Hide()
                frame.CastBar.Icon:Show()
            end
            frame.TrinketMsq:Hide()
            frame.RacialMsq:Hide()
            frame.DispelMsq:Hide()
            frame.masqueHidden = true
        end
    end

    if not TestTitle then
        local f = CreateFrame("Frame")
        TestTitle = f
        TestTitle:EnableMouse(true)

        local t = f:CreateFontString(nil, "OVERLAY")
        t:SetFontObject("GameFontHighlightLarge")
        t:SetFont(self.pFont, 12, "OUTLINE")
        t:SetText("|T132961:16|t Ctrl+Shift+Click to drag|r")
        t:SetPoint("BOTTOM", topFrame, "TOP", 17, 17)

        local bg = f:CreateTexture(nil, "BACKGROUND", nil, -1)
        bg:SetPoint("TOPLEFT", t, "TOPLEFT", -6, 4)
        bg:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", 6, -3)
        bg:SetAtlas("PetList-ButtonBackground")

        local t2 = f:CreateFontString(nil, "OVERLAY")
        t2:SetFontObject("GameFontHighlightLarge")
        t2:SetFont(self.pFont, 21, "OUTLINE")
        t2:SetText("sArena |cffff8000Reloaded|r |T135884:13:13|t")
        t2:SetPoint("BOTTOM", t, "TOP", 3, 5)

        TestTitle:SetPoint("TOPLEFT", t, "TOPLEFT", -5, 45)
        TestTitle:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", 5, -5)

        self:SetupDrag(TestTitle, self, nil, "UpdateFrameSettings")
    end

    TestTitle:Show()

    self:UpdateTextures()

    if masqueOn then
        sArenaMixin:RefreshMasque()
        for i = 1, sArenaMixin.maxArenaOpponents do
            local frame = self["arena" .. i]
            for n = 1, 5 do
                local drFrame = frame[self.drCategories[n]]
                if drFrame.__MSQ_New_Normal then
                    drFrame.__MSQ_New_Normal:SetDesaturated(true)
                    drFrame.__MSQ_New_Normal:SetVertexColor(0, 1, 0, 1)
                end
            end
        end
    end

    local testCount = sArenaMixin.testUnits or sArenaMixin.maxArenaOpponents
    if testCount < sArenaMixin.maxArenaOpponents then
        for i = testCount + 1, sArenaMixin.maxArenaOpponents do
            local frame = self["arena" .. i]
            if frame then
                frame:Hide()
            end
        end
    end
end

function sArenaMixin:ModernOrClassicCastbar()
    local layoutSettings = db.profile.layoutSettings[db.profile.currentLayout]
    local useModern = layoutSettings.castBar.useModernCastbars
    local simpleCastbar = layoutSettings.castBar.simpleCastbar
    local castbarSettings = layoutSettings.castBar

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = _G["sArenaEnemyFrame" .. i]
        if (frame and useModern) or frame.CastBar.__modernHooked then
            local unit = "arena"..i
            self:ApplyCastbarStyle(frame, unit, useModern, simpleCastbar)
            if i == sArenaMixin.maxArenaOpponents then
                frame.parent:UpdateCastBarSettings(castbarSettings)
                sArenaMixin:UpdateFonts()
            end
            local fontName, s = frame.CastBar.Text:GetFont()
            frame.CastBar.Text:SetFont(fontName, s, "THINOUTLINE")
        end
    end

    -- Update text positioning after castbar changes
    local currentLayout = self.layouts[db.profile.currentLayout]
    if currentLayout and currentLayout.UpdateOrientation then
        for i = 1, sArenaMixin.maxArenaOpponents do
            local frame = _G["sArenaEnemyFrame" .. i]
            if frame then
                currentLayout:UpdateOrientation(frame)
            end
        end
    end

end