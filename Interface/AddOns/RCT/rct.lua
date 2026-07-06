local addonName, addonTable = ...
RdyCrateGlobal2 = addonTable
local LibStub = LibStub or _G.LibStub
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local RdysCrateTracker = LibStub("AceAddon-3.0"):NewAddon("RdysCrateTracker", "AceConsole-3.0", "AceEvent-3.0")
local AceComm = LibStub("AceComm-3.0")

-- Get locale table with proper fallback
local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("RdysCrateTracker", true) or {}

function RdysCrateTracker:IsBlockedInstance()
    local _, instanceType = GetInstanceInfo()

    if instanceType == "arena"
    or instanceType == "pvp"
    or instanceType == "party"
    or instanceType == "raid"
    or instanceType == "scenario"
    then
        return true
    end

    return false
end

function RdysCrateTracker:WarmodeTS()
    local WarmodeUnixTS = 1798783199
    return GetServerTime() > WarmodeUnixTS
end

local WarCrateGuidelines = [[
DOs:
- Do join our Discord and use /rct help for addon info.
- Do join with friends or guildies; full groups have a blast.
- Do use voice comms; we coordinate and call out crates.
- Do be ready; crates drop fast, and we move quickly.
- Do help newbies; we all started somewhere, and we grow the community.
- Do Join Hated Gaming guild on Whisperwind (In Horde guild finder)
DM @Rdy on Discord for invite on Alliance.
]]
RdysCrateTracker.WarCrateGuidelines = WarCrateGuidelines


StaticPopupDialogs["RDYS_CRATE_TRACKER_POPUP"] = {
    text = L["DISCORD_POPUP_TEXT"] or "Copy this link and open it in a Browser.",
    hasEditBox = 1,
    url = "https://discord.gg/qHHSMFsJ9f",
    OnShow = function(self)
        local eb = self.editBox or self.EditBox
        eb:SetAutoFocus(false)
        eb.width = eb:GetWidth()
        eb:SetWidth(220)
        eb:SetText(StaticPopupDialogs["RDYS_CRATE_TRACKER_POPUP"].url)
        eb:HighlightText()
        ChatEdit_FocusActiveWindow()
    end,
    OnHide = function(self)
        local eb = self.editBox or self.EditBox
        eb:SetWidth(eb.width or 50)
        eb.width = nil
    end,
    hideOnEscape = 1,
    button1 = OKAY,
    EditBoxOnEnterPressed = function(self)
        ChatEdit_FocusActiveWindow()
        self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        ChatEdit_FocusActiveWindow()
        self:GetParent():Hide()
    end,
    EditBoxOnTextChanged = function(self)
        if (self:GetText() ~= StaticPopupDialogs["RDYS_CRATE_TRACKER_POPUP"].url) then
            self:SetText(StaticPopupDialogs["RDYS_CRATE_TRACKER_POPUP"].url)
        end
        self:HighlightText()
        self:ClearFocus()
        ChatEdit_FocusActiveWindow()
    end,
    OnEditFocusGained = function(self)
        self:HighlightText()
    end,
    showAlert = 1
}


-- Create the main frame
local popupFrame = CreateFrame("Frame", "RdyEarlyAccessFrame", UIParent, "BackdropTemplate")
popupFrame:SetSize(400, 350)
popupFrame:SetPoint("CENTER")
popupFrame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Gold-Background", 
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Gold-Border", 
    tile = false, 
    tileSize = 32, 
    edgeSize = 32, 
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
popupFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
popupFrame:SetFrameStrata("TOOLTIP")
popupFrame:Hide()

-- Set up the title
local title = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("TOP", 0, -20)
title:SetText(L["ADDON_TITLE"] or "Hated Crate Tracker")

-- Set up the main text
local text = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("TOPLEFT", 30, -50)
text:SetPoint("BOTTOMRIGHT", -30, 80)
text:SetJustifyH("LEFT")
text:SetJustifyV("TOP")
text:SetText(L["VERSION_UPDATE_MESSAGE"] or [[Hated Crate Tracker!

Welcome to Hated Crate Tracker!

This version brings security enhancements 
to protect your raids from outside interference.
Thank you for supporting HG.


Rdy from HG (Hated Gaming)

Track the hate!]])
-- Create the "Reset" button
local resetButton = CreateFrame("Button", nil, popupFrame, "UIPanelButtonTemplate")
resetButton:SetSize(80, 25)
resetButton:SetPoint("BOTTOM", 0, 20)
resetButton:SetText(L["RESET"] or "Reset")
resetButton:SetScript("OnClick", function(self)
    RdysCrateTracker.db:ResetProfile()
    popupFrame:Hide()
end)
-- Create the "Join Discord" button
local joinButton = CreateFrame("Button", nil, popupFrame, "UIPanelButtonTemplate")
joinButton:SetSize(90, 25)
joinButton:SetPoint("BOTTOMLEFT", 60, 20)
joinButton:SetText(L["JOIN_DISCORD"] or "Join Discord")
joinButton:SetScript("OnClick", function(self)
    -- Open the Discord link
    StaticPopupDialogs["RDYS_CRATE_TRACKER_POPUP"].url = "https://discord.gg/qHHSMFsJ9f"
    StaticPopup_Show("RDYS_CRATE_TRACKER_POPUP")
    popupFrame:Hide()
end)

-- Create the "Close" button
local closeButton = CreateFrame("Button", nil, popupFrame, "UIPanelButtonTemplate")
closeButton:SetSize(80, 25)
closeButton:SetPoint("BOTTOMRIGHT", -60, 20)
closeButton:SetText(L["CLOSE"] or "Close")
closeButton:SetScript("OnClick", function(self)
    popupFrame:Hide()
end)

-- Create the "Don't show again" checkbox
local checkbox = CreateFrame("CheckButton", nil, popupFrame, "UICheckButtonTemplate")
checkbox:SetSize(20, 20)
checkbox:SetPoint("BOTTOMLEFT", 50, 50)
checkbox:SetHitRectInsets(0, -100, 0, 0) -- This makes the hit area larger for easier clicking

local checkboxText = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
checkboxText:SetText(L["DONT_SHOW_AGAIN"] or "Don't show again")
checkboxText:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
checkbox:SetScript("OnClick", function(self)
    if self:GetChecked() then
        -- This is where we save the setting
        if RdysCrateTracker.db and RdysCrateTracker.db.profile then
            RdysCrateTracker.db.profile.dontShowEarlyAccess = true
        end
    else
        -- If they uncheck it, we should reset the setting
        if RdysCrateTracker.db and RdysCrateTracker.db.profile then
            RdysCrateTracker.db.profile.dontShowEarlyAccess = false
        end
    end
end)

-- Show the frame if the option is not set
C_Timer.After(1, function()
    if RdysCrateTracker.db and RdysCrateTracker.db.profile
        and not RdysCrateTracker.db.profile.dontShowEarlyAccess then
        popupFrame:Show()
    end
end)


function RdysCrateTracker:UpdateCurrentZone()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    local normalized = self:NormalizeZoneID(mapID)
    self.currentZoneID = mapID
    self.normalizedZoneID = normalized or mapID

    if self.debugged then
        print(string.format("|cff33ff99[RCT]|r Zone update: map=%d → normalized=%d", mapID, self.normalizedZoneID))
    end
end

local function IsUsableShardID(shardID)
    return shardID ~= nil and shardID ~= "" and shardID ~= "N/A"
end

function RdysCrateTracker:HandleZoneShardTransition(delaySeconds, retryCount)
    local profile = self.db and self.db.profile
    local previousZone = self.normalizedZoneID or self:NormalizeZoneID(self.currentZoneID)
    local previousShard = self.ShardID
    local previousShardZone = self._shardZone or previousZone

    self:UpdateCurrentZone()

    local currentZone = self.normalizedZoneID
    local keepExistingShard = IsUsableShardID(previousShard)
        and currentZone
        and (previousZone == currentZone or previousShardZone == currentZone)

    if keepExistingShard then
        self.ShardID = previousShard
        self._shardZone = currentZone
        if profile then
            profile.ShardID = previousShard
        end
        if type(self.UpdateShardID2) == "function" then
            self:UpdateShardID2()
        end
    end

    self._zoneShardTransitionToken = (self._zoneShardTransitionToken or 0) + 1
    local token = self._zoneShardTransitionToken
    local waitSeconds = delaySeconds or 5
    local retriesLeft = retryCount

    if retriesLeft == nil then
        retriesLeft = 1
    end

    local function finalizeTransition()
        if self._zoneShardTransitionToken ~= token then
            return
        end

        self:UpdateCurrentZone()

        local activeZone = self.normalizedZoneID
        local activeShard = self.ShardID
        local shardMatchesZone = IsUsableShardID(activeShard)
            and activeZone
            and self._shardZone == activeZone

        if shardMatchesZone then
            if type(self.UpdateShardID2) == "function" then
                self:UpdateShardID2()
            end
            if type(self.checkShard) == "function" then
                self.checkShard()
            end
            return
        end

        if type(self.checkShard) == "function" and self.checkShard() then
            if type(self.UpdateShardID2) == "function" then
                self:UpdateShardID2()
            end
            return
        end

        if retriesLeft > 0 then
            retriesLeft = retriesLeft - 1
            C_Timer.After(waitSeconds, finalizeTransition)
            return
        end

        if not keepExistingShard then
            self.ShardID = "N/A"
            self._shardZone = nil
            if profile then
                profile.ShardID = "N/A"
            end
            if type(self.UpdateShardID2) == "function" then
                self:UpdateShardID2()
            elseif self.titlepanel and self.titlepanel.shardLabel then
                self.titlepanel.shardLabel:SetText("N/A")
            end
        end
    end

    C_Timer.After(waitSeconds, finalizeTransition)
end

function RdysCrateTracker:SaveTitlePanelPosition()
    local profile = self.db and self.db.profile
    if not profile or not self.titlepanel then return end

    local point, _, relativePoint, x, y = self.titlepanel:GetPoint(1)
    profile.titlePanelPoint = point or "CENTER"
    profile.titlePanelRelativePoint = relativePoint or "CENTER"
    profile.titlePanelX = x or 0
    profile.titlePanelY = y or -10
end

function RdysCrateTracker:RestoreTitlePanelPosition()
    local profile = self.db and self.db.profile
    if not profile or not self.titlepanel then return end

    local point = profile.titlePanelPoint
    local relativePoint = profile.titlePanelRelativePoint
    local x = profile.titlePanelX
    local y = profile.titlePanelY

    self.titlepanel:ClearAllPoints()
    if point and relativePoint and x and y then
        self.titlepanel:SetPoint(point, UIParent, relativePoint, x, y)
    else
        self.titlepanel:SetPoint("CENTER", UIParent, "CENTER", 0, -10)
    end
end



function RdysCrateTracker:OnInitialize()
    -- Initialize database defaults
    local defaults = {
        profile = {
            enable = true,
            enableTomTom = true,
            debugged = false,
            warningenable = true,
            warningX = 0,
            warningY = 200,
            warningframefont = "Fonts\\FRIZQT__.TTF",
            warningframefontsize = 14,
            scale = 1.0,
            backgroundColor = {0, 0, 0, 1},
            UMAnnounce = true,
            UMTrack = true,
            UMWarn = true,
            zdfAnnounce = true,
            zdfTrack = true,
            zdfWarn = true,
            ztwwAnnounce = true,
            ztwwTrack = true,
            ztwwWarn = true,
            zdrgfAnnounce = true,
            zdrgfTrack = true,
            zdrgfWarn = true,
            zstaleness = 200,
            MidAnnounce = true,
            MidTrack = true,
            MidWarn = true,
            warningsoundEnabled = true,
            windowClosed = false,
            titlePanelPoint = "CENTER",
            titlePanelRelativePoint = "CENTER",
            titlePanelX = 0,
            titlePanelY = -10,
            zverifyshard = true,
            Devmode = false,
            -- Database tables
            crateDB = {},
            rotationDB = {},
            crateDBSecondary = {},
            DBshardHistory = {},
            lastAnnounced = {},
        },
    }

    -- Initialize the database (single source of truth)
    self.db = LibStub("AceDB-3.0"):New("RdysCrateTrackerDB", defaults, true)
    
    -- Create convenient cached references for performance
    self.profile = self.db.profile
    
    -- Initialize ShardID from profile or set default
    self.ShardID = self.profile.ShardID or "N/A"
    self.profile.ShardID = self.ShardID
    
    -- Make global reference available
    _G.RdysCrateTracker = self

    -- Create Warning Frame
    self.warningFrame = CreateFrame("MessageFrame", "RdysCrateTrackerWarningFrame", UIParent)
    self.warningFrame:SetSize(400, 50)
    self.warningFrame:SetPoint("CENTER", 0, 200)
    self.warningFrame:SetInsertMode("TOP")
    self.warningFrame:SetFontObject(GameFontNormalLarge)
    self.warningFrame:SetFading(true)
    self.warningFrame:SetFadeDuration(2)
    self.warningFrame:SetTimeVisible(3)
    
    -- Set initial font from profile
    self.warningFrame:SetFont(
        self.profile.warningframefont or "Fonts\\FRIZQT__.TTF", 
        self.profile.warningframefontsize or 14, 
        "OUTLINE"
    )
    -- Current zone tracking
self.currentZoneID = nil
self.normalizedZoneID = nil
self.zoneUID = nil or "N/A"
self.addonName = L["ADDON_NAME"] or "Hated Crate Tracker"
self.recent = {}
self.last_timestamp = 0
self.zdebug = false
self.alerted = {}
self.menu = {}
self.timer = nil
self.settingsCategoryID = nil
self.seenVignetteGUIDs = {}


self.frequency = {
    [2248] = 1100,  -- Isle of Dorn
    [2214] = 1096,  -- Ringing Deeps
    [2215] = 1093,  -- Hallowfall  -  -  1093 and 1095 timers 
    [2255] = 1092,  -- Azj-Kahet  - - confirmed
    [2346] = 1100,  -- Undermine
    [2369] = 1100,  -- Siren Isle
    [2022] = 2700,  -- Waking Shores
    [2023] = 2700,  -- Ohn'ahran Plains
    [2024] = 2700,  -- The Azure Span
    [2025] = 2700,  -- Thaldraszus
    [2371] = 1100,  -- K'aresh
    [2405] = 1099,  -- VoidStorm
    [2444] = 1096,  -- Slayer's Rise
    [2413] = 1099,  -- Harandar
    [2395] = 1098,  -- EverSong Woods
    [2437] = 1099,  -- Zul'Aman
}



self.methods = {
    heard="!", -- announced by NPC in zone
    plane="^", -- plane spotted
    parachute="*", -- parachute spotted
    unclaimed="X", -- unclaimed crate spotted (up to 10 minutes late)
    claimed="_", -- claimed crate spotted (up to 10 minutes late)
    manual="/", -- a manually added spot
    unknown="?", -- migrated from old db
}

self.MSG_CRATE_WARN = L["CRATE_ALERT_MESSAGE"] or "Hated Gaming Crate Alert! Flying in %s - Shard = %s"
self.MSG_CRATE = L["CRATE_ANNOUNCE_MESSAGE"] or "%s just announced a war crate in %s - %s (heard by %s)"
self.MSG_CRATE_SPOT = L["CRATE_SPOT_MESSAGE"] or "War crate in %s - %s (spotted by %s - %s)"

self.WINDOW_LABEL = L["WINDOW_LABEL"] or "%i. %s - %s - %ix - "
self.WINDOW_TIMER = L["WINDOW_TIMER"] or "%s"

self.zoneMapID = C_Map.GetBestMapForUnit("player")
self.zoneName = self.zoneMapID and C_Map.GetMapInfo(self.zoneMapID) and C_Map.GetMapInfo(self.zoneMapID).name or L["UNKNOWN_ZONE"] or "Unknown Zone"
self.mapInfo = self.zoneMapID and C_Map.GetMapInfo(self.zoneMapID) or nil
self.mapID = self.mapInfo and self.mapInfo.mapID or nil

self.playerFaction = UnitFactionGroup("player")
self.playerClass = select(2, UnitClass("player"))
self.playerLevel = UnitLevel("player")
self.playerRace = UnitRace("player")
self.playerName = UnitName("player")
self.playerGUID = UnitGUID("player")
self.playerRealm = GetRealmName()
self.playerFactionID = self.playerFaction == "Horde" and 1 or 2
self.playerFactionName = self.playerFaction == "Horde" and "Horde" or "Alliance"
self.playerFactionShort = self.playerFaction == "Horde" and "H" or "A"
self.playerFactionColor = self.playerFaction == "Horde" and "|cffff0000" or "|cff00ff00"

local function AmIaLeader()
    if IsInGroup() then
        if IsInRaid() then
            return UnitIsGroupLeader("player")
        else
            return UnitIsGroupLeader("player")
        end
    end
    return false
end
self.AmIaLeader = AmIaLeader

    AceConfig:RegisterOptionsTable("Hated Crate Tracker", {
        name = L["ADDON_NAME"] or "Hated Gaming Crate Tracker",
        handler = self,
        type = "group",
        args = {
            enable = {
                type = "toggle",
                order = 2,
                name = L["ENABLE"] or "Enable",
                desc = L["ENABLE_DESC"] or "Enable or disable the addon",
                get = function(info) return RdysCrateTracker.db.profile.enable end,
                set = function(info, value) RdysCrateTracker.db.profile.enable = value end,
            },
enableTomTom = {
    type = "toggle",
    order = 1,
    name = L["PREDICTION"] or "Prediction",
    desc = L["PREDICTION_DESC"] or "Enable or Disable Prediction",
    -- Disable only if neither TomTom nor RdysDevTools is loaded
    disabled = function()
        if type(C_AddOns) ~= "table" or type(C_AddOns.IsAddOnLoaded) ~= "function" then
            return true -- API not ready, disable toggle
        end
        local tomtomLoaded = C_AddOns.IsAddOnLoaded("RCT")
        return not (tomtomLoaded)
    end,
    get = function(info)
        return RdysCrateTracker.db.profile.enableTomTom or false
    end,
    set = function(info, value)
        RdysCrateTracker.db.profile.enableTomTom = value
    end,
},
            bountyHunter = {
                type = "toggle",
                order = 3,
                name = L["BOUNTY_HUNTER"] or "Bounty Hunter",
                desc = L["BOUNTY_HUNTER_DESC"] or "Enable or disable the Bounty Hunter feature",
                get = function(info) return RdysCrateTracker.db.profile.bountyHunter end,
                set = function(info, value) RdysCrateTracker.db.profile.bountyHunter = value end,
            },
            debugged = {
                type = "toggle",
                order = 4,
                name = L["DEBUG_MODE"] or "Debug Mode",
                desc = L["DEBUG_MODE_DESC"] or "Show additional debug info",
                get = function(info) return RdysCrateTracker.db.profile.debugged end,
                set = function(info, value)
                    RdysCrateTracker.db.profile.debugged = value
                    print((L["DEBUG_MODE"] or "Debug mode") .. " " .. (value and (L["ENABLED"] or "enabled") or (L["DISABLED"] or "disabled")))
                end,
            },
--[=[
            Devmode = {
                type = "toggle",
                order = 6,
                name = L["DEVELOPER_MODE"] or "Developer Mode",
                desc = L["DEVELOPER_MODE_DESC"] or "Enable Developer Mode for testing purposes",
                get = function(info) return RdysCrateTracker.db.profile.Devmode end,
                set = function(info, value)
                    RdysCrateTracker.db.profile.Devmode = value
                    print((L["DEVELOPER_MODE"] or "Developer mode") .. " " .. (value and (L["ENABLED"] or "enabled") or (L["DISABLED"] or "disabled")))
                end,
            },

]=]

            Combatdisable = {
                type = "toggle",
                order = 5,
                name = L["COMBAT_DISABLE"] or "Combat Disable",
                desc = L["COMBAT_DISABLE_DESC"] or "Check to disable the addon in combat",
                    get = function(info) return RdysCrateTracker.db.profile.Combatdisable end, -- add   if RdysCrateTracker.db.profile.Combatdisable and UnitAffectingCombat("player") then return end
                    set = function(info, value) RdysCrateTracker.db.profile.Combatdisable = value end,
            },
            notPvp = {
                type = "toggle",
                name = L["DISABLE_PVP"] or "Disable in PvP",
                desc = L["DISABLE_PVP_DESC"] or "Stop addon from working during Arena/BG/Dungeons/Raids",
                hidden = true,  -- Keeps this setting hidden in the UI
                get = function()
                    -- Simply return the value from the database
                    return RdysCrateTracker.db.profile.notPvp or false  -- Default to false if not set
                end,
                set = function(value)
                    -- Save the value to the database when manually changed
                    RdysCrateTracker.db.profile.notPvp = value

                end,
            },              
            warningFrame = {
                type = "group",
                order = 3,
                name = L["WARNING_FRAME"] or "Warning Frame",
                desc = L["WARNING_FRAME_DESC"] or "Settings related to the warning frame",
                args = {
                    warningenable = {
                        type = "toggle",
                        name = L["ENABLE_WARNING_FRAME"] or "Enable Warning Frame",
                        desc = L["ENABLE_WARNING_FRAME_DESC"] or "Enable or disable the warning frame",
                        get = function(info) return RdysCrateTracker.db.profile.warningenable end,
                        set = function(info, value)
                            RdysCrateTracker.db.profile.warningenable = value
                            if value then
                                RdysCrateTracker.warningFrame:Show()
                            else
                                RdysCrateTracker.warningFrame:Hide()
                            end
                        end,
                    },
                    warningX = {
                        type = "range",
                        name = L["WARNING_X_POSITION"] or "Warning X Position",
                        desc = L["WARNING_X_POSITION_DESC"] or "Set the X position of the warning text",
                        min = -1500, max = 1500, step = 1,
                        get = function(info) return RdysCrateTracker.db.profile.warningX or 0 end,
                        set = function(info, value)
                            RdysCrateTracker.db.profile.warningX = value
                            RdysCrateTracker:UpdateWarningPosition()
                            RdysCrateTracker.warningFrame:AddMessage(L["PLACEMENT_TEXT"] or "Hated Gaming Crate Tracker: Addon Placement Text") -- Show reference text while moving
                        end,
                    },
                    warningY = {
                        type = "range",
                        name = L["WARNING_Y_POSITION"] or "Warning Y Position",
                        desc = L["WARNING_Y_POSITION_DESC"] or "Set the Y position of the warning text",
                        min = -1500, max = 1500, step = 1,
                        get = function(info) return RdysCrateTracker.db.profile.warningY or 0 end,
                        set = function(info, value)
                            RdysCrateTracker.db.profile.warningY = value
                            RdysCrateTracker:UpdateWarningPosition()
                            RdysCrateTracker.warningFrame:AddMessage(L["PLACEMENT_TEXT"] or "Hated Gaming Crate Tracker: Addon Placement Text") -- Show reference text while moving
                        end,
                    },
                    reset = {
                        type = "execute",
                        name = L["RESET"] or "Reset",
                        desc = L["RESET_DESC"] or "Reset the addon settings to default",
                        func = function()
                            RdysCrateTracker.db:ResetProfile()
                            RdysCrateTracker:UpdateWarningPosition()
                            RdysCrateTracker.warningFrame:AddMessage(L["PLACEMENT_TEXT"] or "Hated Gaming Crate Tracker: Addon Placement Text") -- Show reference text while moving
                        end,
                    },
                    test = {
                        type = "execute",
                        name = L["TEST"] or "Test",
                        desc = L["TEST_DESC"] or "Test the addon functionality",
                        func = function()
                            RdysCrateTracker.warningFrame:AddMessage(L["PLACEMENT_TEXT"] or "Hated Gaming Crate Tracker: Addon Placement Text") -- Show reference text while moving
                            print(L["TEST_MESSAGE"] or "Test message")
                        end,
                    },
                    warningframefont = {
                        type = "select",
                        name = L["WARNING_FRAME_FONT"] or "Warning Frame Font",
                        desc = L["WARNING_FRAME_FONT_DESC"] or "Select the font for the warning frame",
                        values = {
                            ["Fonts\\FRIZQT__.TTF"] = "Friz Quadrata TT",
                            ["Fonts\\ARIALN.TTF"] = "Arial Narrow",
                            ["Fonts\\SKURRI.TTF"] = "Skurri",
                            ["Fonts\\MORPHEUS.ttf"] = "Morpheus",
                            ["Fonts\\ARKai_T.ttf"] = "ARKai T",
                            ["Fonts\\ARKai_C.ttf"] = "ARKai C",
                            ["Fonts\\ARKai_L.ttf"] = "ARKai L",
                        },
                        get = function(info) return RdysCrateTracker.db.profile.warningframefont or "Fonts\\FRIZQT__.TTF" end,
                        set = function(info, value)
                            RdysCrateTracker.db.profile.warningframefont = value
                            RdysCrateTracker.warningFrame:SetFont(value, RdysCrateTracker.db.profile.warningframefontsize or 14, "OUTLINE")
                            RdysCrateTracker.warningFrame:AddMessage(L["PLACEMENT_TEXT"] or "Hated Gaming Crate Tracker: Addon Placement Text") -- Show reference text while moving
                        end,
                    },
                    warningframefontsize = {
                        type = "range",
                        name = L["WARNING_FRAME_FONT_SIZE"] or "Warning Frame Font Size",
                        desc = L["WARNING_FRAME_FONT_SIZE_DESC"] or "Set the font size for the warning frame",
                        min = 8, max = 40, step = 1,
                        get = function(info) return RdysCrateTracker.db.profile.warningframefontsize or 14 end,
                        set = function(info, value)
                            RdysCrateTracker.db.profile.warningframefontsize = value
                            RdysCrateTracker.warningFrame:SetFont(RdysCrateTracker.db.profile.warningframefont or "Fonts\\FRIZQT__.TTF", value, "OUTLINE")
                            RdysCrateTracker.warningFrame:AddMessage(L["PLACEMENT_TEXT"] or "Hated Gaming Crate Tracker: Addon Placement Text") -- Show reference text while moving
                        end,
                    },
                },
            },
            scale = {
                type = "range",
                name = L["SCALE"] or "Addon Scale",
                order = 4,
                desc = L["SCALE_DESC"] or "Set the scale of the addon window",
                min = 0.5, max = 2.0, step = 0.1,
                get = function(info) return RdysCrateTracker.db.profile.scale or 1.0 end,
                set = function(info, value)
                    RdysCrateTracker.db.profile.scale = value
                    RdysCrateTracker.titlepanel:SetScale(value)

                    RdysCrateTracker.warningFrame:AddMessage(L["SCALE_UPDATED"] or "Hated Gaming Crate Tracker: Scale updated") -- Show reference text while adjusting scale
                end,
            },
            BackgroundColor = {
                type = "group",
                order = 2,
                name = L["BACKGROUND_COLOR"] or "Background Color",
                desc = L["BACKGROUND_COLOR_DESC"] or "Set a single background color for all frames",
                args = {
                    colorPicker = {
                        type = "color",
                        name = L["BACKGROUND_COLOR"] or "Background Color",
                        desc = L["BACKGROUND_COLOR_PICKER_DESC"] or "Choose the background color",
                        hasAlpha = true,
                        get = function()
                            local r, g, b, a = unpack(RdysCrateTracker.db.profile.backgroundColor or {0, 0, 0, 1})
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            RdysCrateTracker.db.profile.backgroundColor = {r, g, b, a}
                            RdysCrateTracker.titlepanel:SetBackdropColor(r, g, b, a)
                            RdysCrateTracker.titlepanel.close:SetBackdropColor(r, g, b, a)
                            RdysCrateTracker.titlepanel.minimize:SetBackdropColor(r, g, b, a)
                            RdysCrateTracker.titlepanel.options:SetBackdropColor(r, g, b, a)
                            RdysCrateTracker.titlepanel.refresh:SetBackdropColor(r, g, b, a)
                            for _, button in ipairs(RdysCrateTracker.buttonFrames or {}) do
                                button:SetBackdropColor(r, g, b, a)
                            end
                        end,
                    },
                },
            },
            CrateTracking = {
                type = "group",
                order = 1,
                name = L["CRATE_TRACKING"] or "Crate Tracking",
                desc = L["CRATE_TRACKING_DESC"] or "Settings related to crate tracking",
                args = {
                    UMAnnounce = {
                        type = "toggle",
                        order = 4,
                        name = L["UNDERMINE_ANNOUNCE"] or "Undermine - Announce",
                        desc = L["UNDERMINE_ANNOUNCE_DESC"] or "Make a sound and announce Undermine crates",
                        get = function() return RdysCrateTracker.db.profile.UMAnnounce end,
                        set = function(_, value) RdysCrateTracker.db.profile.UMAnnounce = value end,
                    },
                    UMTrack = {
                        type = "toggle",
                        order = 5,
                        name = L["UNDERMINE_TRACK"] or "Undermine - Track",
                        desc = L["UNDERMINE_TRACK_DESC"] or "Show Undermine crates in /rct output",
                        get = function() return RdysCrateTracker.db.profile.UMTrack end,
                        set = function(_, value) RdysCrateTracker.db.profile.UMTrack = value end,
                    },
                    UMWarn = {
                        type = "toggle",
                        order = 6,
                        name = L["UNDERMINE_WARN"] or "Undermine - Warn",
                        desc = L["UNDERMINE_WARN_DESC"] or "Make a sound and warn before Undermine crates will drop",
                        get = function() return RdysCrateTracker.db.profile.UMWarn end,
                        set = function(_, value) RdysCrateTracker.db.profile.UMWarn = value end,
                    },
                    zdfAnnounce = {
                        type = "toggle",
                        order = 7,
                        name = L["DF_ANNOUNCE"] or "DF - Announce",
                        desc = L["DF_ANNOUNCE_DESC"] or "Make a sound and announce DF crates",
                        get = function() return RdysCrateTracker.db.profile.zdfAnnounce end,
                        set = function(_, value) RdysCrateTracker.db.profile.zdfAnnounce = value end,
                    },
                    zdfTrack = {
                        type = "toggle",
                        order = 8,
                        name = L["DF_TRACK"] or "DF - Track",
                        desc = L["DF_TRACK_DESC"] or "Show DF crates in /rct output",
                        get = function() return RdysCrateTracker.db.profile.zdfTrack end,
                        set = function(_, value) RdysCrateTracker.db.profile.zdfTrack = value end,
                    },
                    zdfWarn = {
                        type = "toggle",
                        name = "DF- Warn",
                        order = 9,
                        desc = "Make a sound and warn before DF crates will drop",
                        get = function() return RdysCrateTracker.db.profile.zdfWarn end,
                        set = function(_, value) RdysCrateTracker.db.profile.zdfWarn = value end,
                    },
                    ztwwAnnounce = {
                        type = "toggle",
                        order = 10,
                        name = L["TWW_ANNOUNCE"] or "TWW - Announce",
                        desc = L["TWW_ANNOUNCE_DESC"] or "Make a sound and announce TWW crates",
                        get = function() return RdysCrateTracker.db.profile.ztwwAnnounce end,
                        set = function(_, value) RdysCrateTracker.db.profile.ztwwAnnounce = value end,
                    },
                    ztwwTrack = {
                        type = "toggle",
                        order = 11,
                        name = L["TWW_TRACK"] or "TWW - Track",
                        desc = L["TWW_TRACK_DESC"] or "Show TWW crates in /rct output",
                        get = function() return RdysCrateTracker.db.profile.ztwwTrack end,
                        set = function(_, value) RdysCrateTracker.db.profile.ztwwTrack = value end,
                    },
                    ztwwWarn = {
                        type = "toggle",
                        order = 12,
                        name = L["TWW_WARN"] or "TWW - Warn",
                        desc = L["TWW_WARN_DESC"] or "Make a sound and warn before TWW crates will drop",
                        get = function() return RdysCrateTracker.db.profile.ztwwWarn end,
                        set = function(_, value) RdysCrateTracker.db.profile.ztwwWarn = value end,
                    },
                    zdrgfAnnounce = {
                        type = "toggle",
                        order = 13,
                        name = L["DRAGONFLIGHT_ANNOUNCE"] or "DragonFlight - Announce",
                        desc = L["DRAGONFLIGHT_ANNOUNCE_DESC"] or "Make a sound and announce DragonFlight crates",
                        get = function() return RdysCrateTracker.db.profile.zdrgfAnnounce end,
                        set = function(_, value) RdysCrateTracker.db.profile.zdrgfAnnounce = value end,
                    },
                    zdrgfTrack = {
                        type = "toggle",
                        order = 14,
                        name = L["DRAGONFLIGHT_TRACK"] or "DragonFlight - Track",
                        desc = L["DRAGONFLIGHT_TRACK_DESC"] or "Show DragonFlight crates in /rct output",
                        get = function() return RdysCrateTracker.db.profile.zdrgfTrack end,
                        set = function(_, value) RdysCrateTracker.db.profile.zdrgfTrack = value end,
                    },
                    zdrgfWarn = {
                        type = "toggle",
                        order = 15,
                        name = L["DRAGONFLIGHT_WARN"] or "DragonFlight - Warn",
                        desc = L["DRAGONFLIGHT_WARN_DESC"] or "Make a sound and warn before DragonFlight crates will drop",
                        get = function() return RdysCrateTracker.db.profile.zdrgfWarn end,
                        set = function(_, value) RdysCrateTracker.db.profile.zdrgfWarn = value end,
                    },
                    MidAnnounce = {
                        type = "toggle",
                        order = 16,
                        name = L["MIDNIGHT_ANNOUNCE"] or "Midnight - Announce",
                        desc = L["MIDNIGHT_ANNOUNCE_DESC"] or "Make a sound and announce Midnight crates",
                        get = function() return RdysCrateTracker.db.profile.MidAnnounce end,
                        set = function(_, value) RdysCrateTracker.db.profile.MidAnnounce = value end,
                    },
                    MidTrack = {
                        type = "toggle",
                        order = 17,
                        name = L["MIDNIGHT_TRACK"] or "Midnight - Track",
                        desc = L["MIDNIGHT_TRACK_DESC"] or "Show Midnight crates in /rct output",
                        get = function() return RdysCrateTracker.db.profile.MidTrack end,
                        set = function(_, value) RdysCrateTracker.db.profile.MidTrack = value end,
                    },
                    MidWarn = {
                        type = "toggle",
                        order = 18,
                        name = L["MIDNIGHT_WARN"] or "Midnight - Warn",
                        desc = L["MIDNIGHT_WARN_DESC"] or "Make a sound and warn before Midnight crates will drop",
                        get = function() return RdysCrateTracker.db.profile.MidWarn end,
                        set = function(_, value) RdysCrateTracker.db.profile.MidWarn = value end,
                    },
                    zstaleness = {
                        type = "range",
                        name = L["ALLOWED_MISSED_TIMERS"] or "Allowed Missed Crate Timers",
                        desc = L["STALENESS_DESC"] or "Set the staleness of the crate data",
                        min = 1, max = 500, step = 1,
                        get = function(info) return RdysCrateTracker.db.profile.zstaleness or 5 end,
                        set = function(info, value) RdysCrateTracker.db.profile.zstaleness = value end,
                    },
                    warningsound = {
                        type = "toggle",
                        name = L["WARNING_SOUND"] or "Enable Warning Sound",
                        desc = L["WARNING_SOUND_DESC"] or "Enable or disable the warning sound",
                        get = function(info) return RdysCrateTracker.db.profile.warningsoundEnabled or false end,
                        set = function(info, value) RdysCrateTracker.db.profile.warningsoundEnabled = value end,
                    },
                    zverifyshard = {
                        type = "toggle",
                        name = L["VERIFY_SHARD"] or "Verify Shard",
                        desc = L["VERIFY_SHARD_DESC"] or "Verify the shard ID of the crate",
                        get = function(info) return RdysCrateTracker.db.profile.zverifyshard or false end,
                        set = function(info, value) RdysCrateTracker.db.profile.zverifyshard = value end,
                    },
                },
            },
            TimerOptions = {
                type = "group",
                order = 3,
                name = L["CRATE_TIMER_BAR_OPTIONS"] or "Crate Timer Bar Options",
                args = {
                    title = {
                        type  = "header",
                        order = 1,
                        name  = L["TIMER_OPTIONS"] or "Timer Options",
                        desc  = L["TIMER_OPTIONS_DESC"] or "Configure the timer options for Hated Crate Tracker",
                    },
                    timerbarfontsize = {
                        type  = "range",
                        order = 2,
                        name  = L["TIMER_BAR_FONT_SIZE"] or "Timer Bar Font Size",
                        desc  = L["TIMER_BAR_FONT_SIZE_DESC"] or "Set the font size for crate timer bars",
                        min   = 8,
                        max   = 20,
                        step  = 1,
                        get   = function(info)
                            return RdysCrateTracker.db.profile.timerbarfontsize or 14
                        end,
                        set   = function(info, value)
                            RdysCrateTracker.db.profile.timerbarfontsize = value
                            for _, bar in ipairs(RdysCrateTracker.timerBars or {}) do
                                if bar.text then
                                    bar.text:SetFont(
                                        "Interface\\AddOns\\RCT\\fonts\\Accidental Presidency.ttf",
                                        value,
                                        "OUTLINE"
                                    )
                                end
                            end
                        end,
                    },
                    timerbaropacity = {
                        type      = "range",
                        order     = 3,
                        name      = "Timer Bar Opacity - requires /reload",
                        desc      = "Set the opacity for crate timer bars - Requires /reload",
                        min       = 0.1,
                        max       = 1.0,
                        step      = 0.1,
                        isPercent = true,
                        get       = function(info)
                            return RdysCrateTracker.db.profile.timerbaropacity or 1.0
                        end,
                        set       = function(_, value)
                            RdysCrateTracker.db.profile.timerbaropacity = value
                            for _, bar in ipairs(RdysCrateTracker.timerBars or {}) do
                                local c = bar.color or {1, 1, 1, 1}
                                if bar.bg then
                                    bar.bg:SetColorTexture(c[1], c[2], c[3], value)
                                else
                                    local bg = bar:CreateTexture(nil, "BACKGROUND")
                                    bg:SetAllPoints(true)
                                    bg:SetColorTexture(c[1], c[2], c[3], value)
                                    bar.bg = bg
                                end
                            end
                        end,
                    },
                },
            },
            WarCrateGuidelines = {
                type = "group",
                order = 5,
                name = L["CRATE_FARMING_HOWTO"],
                desc = L["OFFICIAL_GUIDELINES_DESC"],
                args = {
                    title = {
                        type = "header",
                        order = 1,
                        name = L["OFFICIAL_GUIDELINES"],
                        desc = L["OFFICIAL_GUIDELINES_SHORT"],
                    },
                    guidelines = {
                        type = "description",
                        order = 2,
                        name = RdysCrateTracker.WarCrateGuidelines,
                        fontSize = "medium",
                    },
                },
            },
            SupportDev = {
                type = "group",
                order = 4,
                name = L["SUPPORT_HATEDGAMING"],
                desc = L["SUPPORT_HELP_DESC"],
                args = {
                    title = {
                        type = "header",
                        order = 1,
                        name = L["SUPPORT_HATEDGAMING"],
                        desc = L["SUPPORT_HATEDGAMING_DESC"],
                    },
                    donate = {
                        type = "execute",
                        order = 3,
                        name = L["DONATE"],
                        desc = L["DONATE_DESC"],
                        image = "Interface\\Addons\\RCT\\Media\\bmc.tga", -- Add the path to the icon
                        imageWidth = 150, -- Set the desired width of the image
                        imageHeight = 100, -- Set the desired height of the image
                        func = function()
                            StaticPopupDialogs["RDYS_CRATE_TRACKER_POPUP"].url =
                                "https://www.buymeacoffee.com/rdygaming"
                            StaticPopup_Show("RDYS_CRATE_TRACKER_POPUP")
                        end
                    },
                    about = {
                        type = "description",
                        order = 2,
                        name = L["COMMUNITY_MESSAGE"],
                        fontSize = "medium",
                    },
                    discord = {
                        type = "execute",
                        order = 4,
                        name = L["JOIN_MY_DISCORD"],
                        desc = L["JOIN_DISCORD_DESC"],
                        image = "Interface\\Addons\\RCT\\Media\\discord.png", -- Add the path to the icon
                        imageWidth = 150, -- Set the desired width of the image
                        imageHeight = 150, -- Set the desired height of the image
                        func = function()
                            StaticPopupDialogs["RDYS_CRATE_TRACKER_POPUP"].url =
                                "https://discord.gg/qHHSMFsJ9f"
                            StaticPopup_Show("RDYS_CRATE_TRACKER_POPUP")
                        end
                    },
                    supportertitle = {
                        type = "header",
                        order = 5,
                        name = L["JOIN_SUPPORTERS"],
                        desc = L["MONTHLY_SUPPORTERS_DESC"],
                    },
                    aboutmonthly = {
                        type = "description",
                        order = 6,
                        name = L["COMMUNITY_MESSAGE"],
                        fontSize = "medium",
                    },
            },
            }
        }
    })



    self:RestoreTitlePanelPosition()

    if RdysCrateTracker.db.profile.windowClosed then
        RdysCrateTracker.titlepanel:Hide()
 -- Hide the window if it was closed previously
    else
        RdysCrateTracker.titlepanel:Show()
 -- Show it if it was open previously
    end



    -- Function to handle version check
    function RdysCrateTracker:HandleVersionCheck(prefix, message, channel, sender)
        if prefix == "RCTUPD" and sender ~= UnitName("player") then
            local remoteVersion = tonumber(message)
            local localVersion = tonumber(C_AddOns.GetAddOnMetadata("RCT", "Version"))
            if remoteVersion and localVersion and remoteVersion > localVersion then
                if remoteVersion and localVersion and remoteVersion > localVersion then
                    self:Print("|cffff0000[Hated Crate Tracker]|r Addon is an outdated version, it may start to stop working. Please update to version " .. remoteVersion)
                end
                self:Print("|cffff0000[Hated Crate Tracker]|r A new version is available! Please update to version " .. remoteVersion)
            end
        end
    end

    -- Function to send version check message
    function RdysCrateTracker:SendVersionCheck()
        local version = C_AddOns.GetAddOnMetadata("RCT", "Version")
        if version then
        -- Skip sending version checks while in blocked instances or during warmode period
        if (RdysCrateTracker and ((RdysCrateTracker.IsBlockedInstance and RdysCrateTracker:IsBlockedInstance()) or (RdysCrateTracker.WarmodeTS and RdysCrateTracker:WarmodeTS())))
        or (self and ((type(self.IsBlockedInstance) == "function" and self:IsBlockedInstance()) or (type(self.WarmodeTS) == "function" and self:WarmodeTS()))) then
            if self.db and self.db.profile and self.db.profile.debugged then
                print("|cffff9966[RCT]|r Skipping SendVersionCheck due to blocked instance or warmode period.")
            end
            return
        end

        --    AceComm:SendCommMessage("RCTUPD", version, "CHANNEL", self.channelID)
            AceComm:SendCommMessage("RCTUPD", version, "GUILD")
            AceComm:SendCommMessage("RCTUPD", version, "PARTY")
            AceComm:SendCommMessage("RCTUPD", version, "RAID")
        end
    end

    -- Function to join custom channel
    function RdysCrateTracker:JoinCustomChannel()
        local channelName = "RCTUPD"
     --   JoinChannelByName(channelName)
        local id, name = GetChannelName(channelName)
        if id > 0 then
            self.channelID = id
        else
            self:Print("|cffff0000[Hated Crate Tracker]|r Failed to join channel: " .. channelName)
        end
    end

    -- Register the addon message prefix and event
    AceComm:RegisterComm("RCTUPD", function(prefix, message, distribution, sender)
        if prefix == "RCTUPD" then
            RdysCrateTracker:HandleVersionCheck(prefix, message, distribution, sender)
        end
    end)

    function RdysCrateTracker:OnEnable()
        self:Print("|cffff0000" .. (L["ADDON_LOADED"] or "Hated Crate Tracker Loaded!!") .. "|r  - |cff00ff00Hated Gaming on Curseforge|r")
        self:Print("|cff00ccff" .. (L["TOGGLE_HELP"] or "Use /rct toggle to show/hide the addon.") .. "|r")
        if self.timer then
            self.timer:Cancel()
            self.timer = nil
        end
        self.timer = C_Timer.NewTicker(1, RdysCrateTracker.checkTimers)
            -- Join the custom channel and send version check on enable
         --   C_Timer.After(3, function() self:JoinCustomChannel() end)
            C_Timer.After(8, function() self:SendVersionCheck() end) -- Delay to ensure channel join is complete
        end

    self.optionsFrame = AceConfigDialog:AddToBlizOptions("Hated Crate Tracker", "Hated Crate Tracker")
    AceConfig:RegisterOptionsTable("Hated Crate Tracker_Profiles", AceDBOptions:GetOptionsTable(self.db))
    AceConfigDialog:AddToBlizOptions("Hated Crate Tracker_Profiles", "Profiles", "Hated Crate Tracker")
    self:UpdateWarningPosition()
    self:RegisterChatCommand("rct", "ChatCommand")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA" )
    self:UpdateCurrentZone()
end

function RdysCrateTracker:PLAYER_ENTERING_WORLD()
    if not RdysCrateTracker.db.profile.enable then return end
    RdysCrateTracker:IsInPvPInstance()
    -- Initialize the addon and set up the UI
 --   RdysCrateTracker.checkShard()
    local scale = RdysCrateTracker.db.profile.scale or 1
    RdysCrateTracker.titlepanel:SetScale(scale)

    -- Load background colors from options
    if RdysCrateTracker.db.profile.backgroundColor then
        local r, g, b, a = unpack(RdysCrateTracker.db.profile.backgroundColor)
        RdysCrateTracker.titlepanel:SetBackdropColor(r, g, b, a)
        RdysCrateTracker.titlepanel.close:SetBackdropColor(r, g, b, a)
        RdysCrateTracker.titlepanel.minimize:SetBackdropColor(r, g, b, a)
        RdysCrateTracker.titlepanel.options:SetBackdropColor(r, g, b, a)
    end
end

-- Handle Chat Commands
function RdysCrateTracker:ChatCommand(input)
    if input == "dumpstatic" then
        local db = self.db and self.db.profile and self.db.profile.staticPointsDB
        if not db or next(db) == nil then
            self:Print("No learned static points found.")
            return
        end
        self:Print("--- Learned Static Points (staticPointsDB) ---")
        for mapID, points in pairs(db) do
            local out = {}
            for _, pt in ipairs(points) do
                table.insert(out, string.format("{%.2f, %.2f}", pt[1], pt[2]))
            end
            self:Print(string.format("[%d] = { %s }", mapID, table.concat(out, ", ")))
        end
        self:Print("--- End of Dump ---")
        return
    elseif input == "toggle" then
        self.db.profile.enable = not self.db.profile.enable
        self:Print((L["ADDON"] or "Addon") .. " " .. (self.db.profile.enable and (L["ENABLED"] or "enabled") or (L["DISABLED"] or "disabled")))
    elseif input == "debug" then
        self.db.profile.debugged = not self.db.profile.debugged
        self:Print((L["DEBUG_MODE"] or "Debug mode") .. " " .. (self.db.profile.debugged and (L["ENABLED"] or "enabled") or (L["DISABLED"] or "disabled")))
    elseif input == "locale" then
        -- Test locale loading
        local clientLocale = GetLocale()
        local localeName = L["ADDON_NAME"] or "English fallback"
        self:Print("Client locale: " .. clientLocale)
        self:Print("Addon name in current locale: " .. localeName)
        self:Print("Sample localized string: " .. (L["ENABLE"] or "English fallback"))
    elseif input == "clear" then
        RdysCrateTracker.db.profile.crateDB = {}
        self:Print(L["CLEARED_CRATE_DB"] or "Cleared crate DB.")
    elseif input == "clearall" then
        RdysCrateTracker.db.profile.crateDB = {}
        RdysCrateTracker.db.profile.rotationDB = {}
        self:Print(L["CLEARED_ALL_HISTORY"] or "Cleared all history.")
    elseif input:sub(1, 4) == "del " then
        local arg = input:match("%w+$")
        RdysCrateTracker.db.profile.crateDB[RdysCrateTracker.menu[arg]] = nil
    elseif input == "spot" then
        self:crateSpotted("ManualTest", UnitName("player"))
        self:Print(L["MANUALLY_SPOTTED"] or "Manually spotted a crate.")
    elseif input == "center" then
        RdysCrateTracker.titlepanel:ClearAllPoints()
        RdysCrateTracker.titlepanel:SetPoint("CENTER", UIParent, "CENTER", 0, -10)
        RdysCrateTracker:SaveTitlePanelPosition()
        self:Print(L["CENTERED_PANEL"] or "Centered title panel.")
    elseif input == "status" then
        local panel = RdysCrateTracker.titlepanel
        local shown = panel and panel:IsShown() or false
        local timerActive = RdysCrateTracker.timer ~= nil
        local p = RdysCrateTracker.db.profile

        self:Print("|cff33ff99[RCT]|r Status")
        self:Print("enabled=" .. tostring(p.enable) .. ", windowClosed=" .. tostring(p.windowClosed) .. ", shown=" .. tostring(shown))
        self:Print("timerActive=" .. tostring(timerActive) .. ", shard=" .. tostring(RdysCrateTracker.ShardID or "N/A") .. ", zone=" .. tostring(RdysCrateTracker.normalizedZoneID or "N/A"))
        self:Print("warningsoundEnabled=" .. tostring(p.warningsoundEnabled) .. ", UMWarn=" .. tostring(p.UMWarn) .. ", ztwwWarn=" .. tostring(p.ztwwWarn) .. ", MidWarn=" .. tostring(p.MidWarn))
        self:Print("UMAnnounce=" .. tostring(p.UMAnnounce) .. ", ztwwAnnounce=" .. tostring(p.ztwwAnnounce) .. ", MidAnnounce=" .. tostring(p.MidAnnounce))

        if panel then
            self:Print("events: ZONE_CHANGED=" .. tostring(panel:IsEventRegistered("ZONE_CHANGED")) ..
                ", ZONE_CHANGED_NEW_AREA=" .. tostring(panel:IsEventRegistered("ZONE_CHANGED_NEW_AREA")) ..
                ", PLAYER_FLAGS_CHANGED=" .. tostring(panel:IsEventRegistered("PLAYER_FLAGS_CHANGED")) ..
                ", CHAT_MSG_MONSTER_SAY=" .. tostring(panel:IsEventRegistered("CHAT_MSG_MONSTER_SAY")) ..
                ", GROUP_JOINED=" .. tostring(panel:IsEventRegistered("GROUP_JOINED")) ..
                ", PLAYER_LOGOUT=" .. tostring(panel:IsEventRegistered("PLAYER_LOGOUT")))
        end
    elseif input == "help" then
        self:Print(L["AVAILABLE_COMMANDS"] or "Available commands:")
        self:Print(L["HELP_MAIN"] or "/rct  Open/Close the addon.")
        self:Print(L["HELP_TOGGLE"] or "/rct toggle - Enable/disable the addon.")
        self:Print(L["HELP_DEBUG"] or "/rct debug - Toggle debug mode.")
        self:Print(L["HELP_CLEAR"] or "/rct clear - Clears the crate DB.")
        self:Print(L["HELP_CLEARALL"] or "/rct clearall - Clears all history.")
        self:Print(L["HELP_DEL"] or "/rct del <arg> - Deletes a specific crate.")
        self:Print(L["HELP_SPOT"] or "/rct spot - Manually spots a crate.")
        self:Print(L["HELP_CENTER"] or "/rct center - Centers the main frame.")
        self:Print("/rct status - Shows runtime status and key event registrations.")
        self:Print(L["HELP_HELP"] or "/rct help - Shows this help message.")
        self:Print(L["HELP_RDYZ"] or "/rct rdyz - Requests recent crates from other users.")
        self:Print(L["HELP_SHARE"] or "/rct share - Share Addon information with other users.")
    elseif input == "rdyz" then
      RdysCrateTracker:RequestSync()
        self:Print(L["RDYZ_RESPONSE"] or "You da Boss man! Here are your Timers...")
    elseif input == "share" then
        RdysCrateTracker:addonadvertise()
    else
        if RdysCrateTracker.titlepanel:IsShown() then
            RdysCrateTracker.titlepanel:Hide()

            RdysCrateTracker.db.profile.windowClosed = true
        else
            local curTime = GetServerTime()
            RdysCrateTracker.updateFrame(curTime)
            RdysCrateTracker.titlepanel:Show()
            RdysCrateTracker.db.profile.windowClosed = false
        end
    end
end

function RdysCrateTracker:UpdateWarningPosition()
    if RdysCrateTracker.warningFrame then
        RdysCrateTracker.warningFrame:ClearAllPoints()
        RdysCrateTracker.warningFrame:SetPoint("CENTER", UIParent, "CENTER", self.db.profile.warningX or 0, self.db.profile.warningY or 200)
    end
end

function RdysCrateTracker:ZONE_CHANGED_NEW_AREA()
if not RdysCrateTracker.db.profile.enable then return end

local zoneMapID = C_Map.GetBestMapForUnit("player")
if zoneMapID then
    local mapInfo = C_Map.GetMapInfo(zoneMapID)
end
end