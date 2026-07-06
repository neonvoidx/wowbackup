local addonName, addonTable = ...

-- Get locale table with proper fallback
local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("RdysCrateTracker", true) or {}
RdyCrateGlobal2 = addonTable


local RdysCrateTracker = LibStub("AceAddon-3.0"):GetAddon("RdysCrateTracker", true)
if not RdysCrateTracker then
    error("RdysCrateTracker addon not found. Please ensure it is loaded.")
end



local function CreateProgressBar(parent, width, height)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(width, height)
    bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")

    
    local bgColors = {
            {0.0, 0.3, 0.6, 1},  -- dark blue
            {0.4, 0.0, 0.4, 1},  -- purple
            {0.0, 0.6, 0.6, 1},  -- teal
            {0.6, 0.0, 0.6, 1},  -- magenta
            {1.0, 0.5, 0.0, 1},  -- orange
            {0.5, 0.0, 1.0, 1},  -- pink

            {0.2, 0.2, 0.2, 1},  -- dark grey
            {0.8, 0.8, 0.8, 1},  -- light grey
            {0.0, 0.5, 0.3, 1},  -- sea green
            {0.3, 0.6, 0.0, 1},  -- olive
            {0.6, 0.3, 0.0, 1},  -- brown
            {0.1, 0.1, 0.5, 1},  -- navy
            {0.5, 0.1, 0.1, 1},  -- maroon
            {0.2, 0.4, 0.6, 1},  -- steel blue
            {0.6, 0.4, 0.2, 1},  -- russet
            {0.4, 0.6, 0.8, 1},  -- sky blue
            {0.8, 0.4, 0.6, 1},  -- rose
            {0.6, 0.8, 0.4, 1},  -- lime
            {0.4, 0.2, 0.6, 1},  -- indigo
            {0.2, 0.6, 0.4, 1},  -- moss
            {0.6, 0.2, 0.4, 1},  -- plum
            {0.3, 0.3, 0.7, 1},  -- violet
            {0.7, 0.3, 0.3, 1},  -- salmon
            {0.3, 0.7, 0.3, 1},  -- light green
            {0.3, 0.7, 0.7, 1},  -- aquamarine
            {0.7, 0.7, 0.3, 1},  -- golden
        }

        
    local c = bgColors[math.random(#bgColors)]
    -- initial fill color (grey) with 50% opacity
    bar:SetStatusBarColor(0.5, 0.5, 0.5, 0.5)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetColorTexture(c[1], c[2], c[3], RdysCrateTracker.db.profile.timerbaropacity or c[4])  -- use the randomly selected color
    bar.bg = bg

    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bar.text:SetPoint("CENTER", bar, "CENTER")

    bar.flashing = false

    bar:SetScript("OnValueChanged", function(self, value)
        local min, max = self:GetMinMaxValues()
        local remain = max - value

        -- warning colors
        if remain <= 15 then
            self:SetStatusBarColor(1, 0, 0)  -- red
            if not self.flashing then
                UIFrameFlash(self, 0.5, 0.5, -1, false, 0)
                self.flashing = true
            end
        else
            if self.flashing then
                UIFrameFlashStop(self)
                self.flashing = false
            end
            if remain <= 120 then
                self:SetStatusBarColor(0, 1, 0)  -- green
            elseif remain <= 300 then
                self:SetStatusBarColor(1, 1, 0)        -- yellow
            else
                -- back to grey with 50% opacity
                self:SetStatusBarColor(0.5, 0.5, 0.5, 0.75)
            end
        end
    end)

    return bar
end
RdysCrateTracker.CreateProgressBar = CreateProgressBar


local function SaveSettings()
    RdysCrateTracker.db.profile.show = RdysCrateTracker.titlepanel:IsShown() -- Save frame state
end
RdysCrateTracker.SaveSettings = SaveSettings


local function HideAllFrames()
    if RdysCrateTracker.titlepanel then
        RdysCrateTracker.titlepanel:Hide()
    end
end
RdysCrateTracker.HideAllFrames = HideAllFrames

local function ShowFrames()
    -- Check if RdysCrateTracker.titlepanel and RdysCrateTracker.panel1 are valid and not already shown
    if RdysCrateTracker.titlepanel and not RdysCrateTracker.titlepanel:IsShown() then
        RdysCrateTracker.titlepanel:Show()  -- Show titlepanel if it's hidden
    end
end


-- Make the ShowFrames function available globally or as part of RD
RdysCrateTracker.ShowFrames = ShowFrames


------------------------------------------------------------
-- Instance Detection & Control
------------------------------------------------------------
function RdysCrateTracker:IsInPvPInstance()
    -- Get instance info safely
    local isInInstance, instanceType = IsInInstance()

    -- Defensive fallback
    if type(isInInstance) ~= "boolean" or type(instanceType) ~= "string" then
        return false
    end

    -- Ensure windowClosed has a defined default
    if self.db and self.db.profile and self.db.profile.windowClosed == nil then
        self.db.profile.windowClosed = false
    end

    -- Determine if this is a restricted instance type
    local inRestrictedInstance = (
        instanceType == "pvp" or
        instanceType == "arena" or
        instanceType == "party" or
        instanceType == "raid" or
        instanceType == "scenario"
    )

    if isInInstance and inRestrictedInstance then
        -- Disable addon visuals and timers if not already disabled
        if not self.disabledInInstance then
            self.disabledInInstance = true
            if self.timer then
                self.timer:Cancel()
                self.timer = nil
            end
            if self.HideAllFrames then
                self:HideAllFrames()
            elseif self.titlepanel then
                self.titlepanel:Hide()
            end
            if self.db.profile.debugged then
                print("|cff33ff99[RCT]|r Disabled inside instance:", instanceType)
            end
        end
        return true
    else
        -- Not in a restricted instance; re-enable if previously disabled
        if self.disabledInInstance then
            self.disabledInInstance = false
            if not (self.db.profile and self.db.profile.windowClosed) then
                if self.ShowFrames then
                    self:ShowFrames()
                elseif self.titlepanel then
                    self.titlepanel:Show()
                end
            end
            if not self.timer then
                self.timer = C_Timer.NewTicker(1, self.checkTimers)
            end
            if self.db.profile.debugged then
                print("|cff33ff99[RCT]|r Re-enabled outside instance:", instanceType)
            end
        end
        return false
    end
end

------------------------------------------------------------
-- Event handler (AceEvent-compatible)
------------------------------------------------------------
function RdysCrateTracker:OnInstanceEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "GROUP_ROSTER_UPDATE"
    then
        self:IsInPvPInstance()
    end
end

-- Register events directly on the addon (Ace3-safe)
RdysCrateTracker:RegisterEvent("PLAYER_ENTERING_WORLD", "OnInstanceEvent")
RdysCrateTracker:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnInstanceEvent")
RdysCrateTracker:RegisterEvent("GROUP_ROSTER_UPDATE", "OnInstanceEvent")



local SHARD_RESET_TIME = 400

local function checkShard()
    local profile = RdysCrateTracker.db and RdysCrateTracker.db.profile
    if not profile or not profile.enable or profile.notPvp then return false end
    if profile.Combatdisable and UnitAffectingCombat("player") then return false end
    
    local settings = profile.settings or profile
    if not settings.zverifyshard then return false end

    -- Current normalized zone only
    local rawMapID = C_Map.GetBestMapForUnit("player")
    if not rawMapID then return false end

    local zoneID = RdysCrateTracker:NormalizeZoneID(rawMapID)
    if not zoneID or not RdysCrateTracker.ALLOWED_CRATE_ZONES[zoneID] then
        return false
    end

    profile.crateDB = profile.crateDB or {}
    local zoneData = profile.crateDB[zoneID]
    if not zoneData then return false end

    local shardID = RdysCrateTracker.ShardID
    if not shardID or shardID == "N/A" then
        return false
    end

    local now = GetServerTime()

    --------------------------------------------------
    -- 400s RESET WINDOW (zone-scoped)
    --------------------------------------------------
    if zoneData.announceTime
       and (now - zoneData.announceTime) >= SHARD_RESET_TIME
    then
        zoneData.matchPosted = false
        zoneData.diffposted  = false
        zoneData.announced   = false
        zoneData.announceTime = nil
    end

    -- Seed shard once (no announce)
    if not zoneData.shardhist or zoneData.shardhist == "N/A" then
        zoneData.shardhist    = shardID
        zoneData._lastShard   = shardID
        zoneData.matchPosted  = false
        zoneData.diffposted   = false
        zoneData.announced    = false
        zoneData.announceTime = now
        return true
    end

    -- Shard changed since last evaluation
    if shardID ~= zoneData._lastShard then
        zoneData.matchPosted = false
        zoneData.diffposted  = false
        zoneData.announced   = false
        zoneData._lastShard  = shardID
    end

    local zoneName =
        (C_Map.GetMapInfo(zoneID) and C_Map.GetMapInfo(zoneID).name)
        or ("Zone " .. zoneID)

    -- MATCH
    if shardID == zoneData.shardhist then
        if zoneData.matchPosted then return true end

        local msg = (L["SHARD_MATCH_WARNING"]
            and L["SHARD_MATCH_WARNING"]:format(zoneName, shardID))
            or ("Hated Gaming Warning: Shard MATCH for "
                .. zoneName .. " (" .. shardID .. ")")

        if IsInGroup() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
            SendChatMessage(msg, "RAID_WARNING")
        elseif profile.warningenable and RdysCrateTracker.warningFrame then
            RdysCrateTracker.warningFrame:AddMessage(msg)
        end

        zoneData.matchPosted  = true
        zoneData.diffposted   = false
        zoneData.announced    = true
        zoneData.announceTime = now
        return true
    end

    -- CHANGED
    if zoneData.diffposted then return true end

    local msg = (L["SHARD_CHANGED_WARNING"]
        and L["SHARD_CHANGED_WARNING"]:format(
            zoneName,
            zoneData.shardhist or "N/A",
            shardID
        ))
        or ("Hated Gaming Warning: Shard CHANGED for "
            .. zoneName .. " (" .. (zoneData.shardhist or "N/A")
            .. " → " .. shardID .. ")")

    if IsInGroup() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        SendChatMessage(msg, "RAID_WARNING")
    elseif profile.warningenable and RdysCrateTracker.warningFrame then
        RdysCrateTracker.warningFrame:AddMessage(msg)
    end

    zoneData.diffposted   = true
    zoneData.matchPosted  = false
    zoneData.announced    = true
    zoneData.announceTime = now
    return true
end

RdysCrateTracker.checkShard = checkShard

local function updateFrame(curTime)
    local profile = RdysCrateTracker.db.profile
        if (RdysCrateTracker and ((RdysCrateTracker.IsBlockedInstance and RdysCrateTracker:IsBlockedInstance()) or (RdysCrateTracker.WarmodeTS and RdysCrateTracker:WarmodeTS()))) then return end
    if not profile or not profile.enable then return end
    if profile.notPvp then return end
    ----------------------------------------------------------------

    ----------------------------------------------------------------
    -- BASIC UI CONFIGURATION
    ----------------------------------------------------------------
    local maxVisibleRows = 16
    local rowHeight      = 20
    local rowSpacing     = 2
    local rowWidth       = RdysCrateTracker.titlepanel:GetWidth()
    local visibleHeight  = maxVisibleRows * (rowHeight + rowSpacing)

    ----------------------------------------------------------------
    -- CONTAINER INITIALIZATION
    ----------------------------------------------------------------
    if not RdysCrateTracker.contentFrame then
        local cf = CreateFrame("Frame", "zRdyCrateContentFrame", RdysCrateTracker.titlepanel)
        cf:SetPoint("TOPLEFT", RdysCrateTracker.titlepanel, "TOPLEFT", 0, -25)
        cf:SetSize(rowWidth, visibleHeight)
        RdysCrateTracker.contentFrame = cf
    end

    local container = RdysCrateTracker.contentFrame
    RdysCrateTracker.progressRows = RdysCrateTracker.progressRows or {}
    RdysCrateTracker.menu         = {}

    local menuIndex = 1

    ----------------------------------------------------------------
    -- PURE ZONEID LOOP
    ----------------------------------------------------------------
    for _, zoneID in ipairs(RdysCrateTracker.sortedZones()) do
        local crateInfo = profile.crateDB[zoneID]
        if crateInfo then
            
            ------------------------------------------------------------
            -- NEW: zoneID-only filtering (shouldTrack(zoneID))
            ------------------------------------------------------------
            if RdysCrateTracker:shouldTrack(crateInfo.zoneID) then

                local nextTime = RdysCrateTracker.nextCrateTime(crateInfo, curTime)
                local stale    = RdysCrateTracker.lastCrateStaleness(crateInfo, curTime)

                local mapInfo = C_Map.GetMapInfo(crateInfo.zoneID)
                local mapName = (mapInfo and mapInfo.name) or "Unknown Zone"

                --------------------------------------------------------
                -- STALE FILTERING (zoneID-only)
                --------------------------------------------------------
                if stale and stale <= profile.zstaleness then

                    ----------------------------------------------------
                    -- ENSURE ROW EXISTS
                    ----------------------------------------------------
                    local row = RdysCrateTracker.progressRows[menuIndex]
                    if not row then
                        row = RdysCrateTracker.CreateProgressBar(container, rowWidth, rowHeight)
                        RdysCrateTracker.progressRows[menuIndex] = row
                    end

                    ----------------------------------------------------
                    -- POSITION & TEXT STYLE
                    ----------------------------------------------------
                    row:SetParent(container)
                    row:ClearAllPoints()
                    row:SetPoint(
                        "TOPLEFT", container, "TOPLEFT",
                        0, -(menuIndex - 1) * (rowHeight + rowSpacing)
                    )

                    row.text:SetFont(
                        "Interface\\AddOns\\RCT\\fonts\\Accidental Presidency.ttf",
                        profile.timerbarfontsize or 15
                    )
                    row.text:SetTextColor(1, 1, 1)

                    ----------------------------------------------------
                    -- STORE ACTIVE CRATE DATA
                    ----------------------------------------------------
                    row.zoneID    = crateInfo.zoneID
                    row.crateInfo = crateInfo
                    row.index     = menuIndex

                    ----------------------------------------------------
                    -- TIMER BAR VALUES
                    ----------------------------------------------------
                    if nextTime then
                        local total  = crateInfo.interval or 900
                        local remain = math.max(0, nextTime - curTime)

                        row:SetMinMaxValues(0, total)
                        row:SetValue(total - remain)

                        local mins = math.floor(remain / 60)
                        local secs = remain % 60
                        local tm   = string.format("%02d:%02d", mins, secs)

                        row.text:SetJustifyH("RIGHT")
                        row.text:ClearAllPoints()
                        row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                        row.text:SetText(("%s - %s - %d - (%s)"):format(
                            mapName,
                            crateInfo.shardhist or "N/A",
                            stale or 0,
                            tm
                        ))

                        row:Show()
                    else
                        row:Hide()
                    end

                    ----------------------------------------------------
                    -- ONCLICK + TOOLTIP
                    ----------------------------------------------------
                    if not row._handlers then
                        row._handlers = true
                        row:EnableMouse(true)
                        if row.RegisterForClicks then row:RegisterForClicks("AnyUp") end

                        row:SetScript("OnEnter", function(self)
                            if not self.crateInfo then return end
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                            GameTooltip:ClearLines()
                            GameTooltip:AddLine(mapName, 1,1,1)
                            GameTooltip:AddLine("Shard ID: " .. (self.crateInfo.shardhist or "N/A"), .8,.8,.8)
                            GameTooltip:AddLine("Left-click to Announce", 1,1,0)
                            GameTooltip:AddLine("Shift + Right-click to Delete", 1,0,0)
                            GameTooltip:Show()
                        end)

                        row:SetScript("OnLeave", GameTooltip_Hide)

                        row:SetScript("OnMouseUp", function(self, button)
                            if button == "LeftButton" then
                                RdysCrateTracker.announceLabelText(self.index)
                            elseif button == "RightButton" and IsShiftKeyDown() then
                                RdysCrateTracker.deleteCrateOnCtrlClick(self.index)
                            end
                        end)
                    end

                    ----------------------------------------------------
                    -- CONTEXT MENU MAPPING
                    ----------------------------------------------------
                    RdysCrateTracker.menu[tostring(menuIndex)] = crateInfo.zoneID
                    menuIndex = menuIndex + 1
                end
            end
        end
    end

    ----------------------------------------------------------------
    -- HIDE UNUSED ROWS
    ----------------------------------------------------------------
    for i = menuIndex, #RdysCrateTracker.progressRows do
        RdysCrateTracker.progressRows[i]:Hide()
    end
end

RdysCrateTracker.updateFrame = updateFrame



-- ================================
-- Announce Function (row-aware)
-- ================================
function RdysCrateTracker.announceLabelText(idx)
    local row = RdysCrateTracker.progressRows and RdysCrateTracker.progressRows[idx]
    if not row or not row.crateInfo then return end

    local crateInfo = row.crateInfo
    local now       = GetServerTime()
    local nextTime  = RdysCrateTracker.nextCrateTime(crateInfo, now)
    local remain    = nextTime and (nextTime - now) or 0
    local mapName = C_Map.GetMapInfo(crateInfo.zoneID) and C_Map.GetMapInfo(crateInfo.zoneID).name or "Unknown Zone"
    -- format remaining time as MM:SS
    local mins  = math.floor(remain / 60)
    local secs  = remain % 60
    local timeText = string.format("%02d:%02d", mins, secs)

    local msg = ("Next Crate: %s - %s in %s"):format(
        mapName,
        crateInfo.shardhist or "N/A",
        timeText
    )

    if IsInGroup() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        SendChatMessage(msg, "RAID_WARNING")
    else
        print(msg)
    end
end

-- ================================
-- Delete Function (row-aware)
-- ================================
-- Function to delete crate on Ctrl-Click
local function deleteCrateOnCtrlClick(lineIndex)
    if not RdysCrateTracker.db.profile.enable or RdysCrateTracker.db.profile.notPvp then
        return
    end

    -- Grab the row created by updateFrame
    local row = RdysCrateTracker.progressRows and RdysCrateTracker.progressRows[lineIndex]
    if not row or not row.crateInfo or not row.crateInfo.zoneID then
        return
    end

    -- Remove from saved DB
    local zoneID = row.crateInfo.zoneID
    RdysCrateTracker.db.profile.crateDB[zoneID] = nil

    -- Refresh the UI
    RdysCrateTracker.updateFrame(GetServerTime())
end
RdysCrateTracker.deleteCrateOnCtrlClick = deleteCrateOnCtrlClick


local function NachoZone()
    local profile = RdysCrateTracker.db.profile
    if not profile or not profile.enable then return "Unknown Zone" end
    if profile.notPvp then return "Unknown Zone" end

    -- Always get the player's best mapID
    local rawID = C_Map.GetBestMapForUnit("player")
    if not rawID then
        return L["UNKNOWN_ZONE"] or "Unknown Zone"
    end

    -- Normalize to expansion root zone (your zoneID standard)
    local nz = RdysCrateTracker:NormalizeZoneID(rawID)
    if not nz then
        return L["UNKNOWN_ZONE"] or "Unknown Zone"
    end

    -- Retrieve map info for normalized zone
    local info = C_Map.GetMapInfo(nz)
    if not info or not info.name then
        return L["UNKNOWN_ZONE"] or "Unknown Zone"
    end

    return info.name
end

RdysCrateTracker.NachoZone = NachoZone




local function announceFirstCrate()
    if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    local firstCrateID = RdysCrateTracker.menu["1"]
    if firstCrateID then
        local crateInfo = RdysCrateTracker.db.profile.crateDB[firstCrateID]
        local mapName = C_Map.GetMapInfo(crateInfo.zoneID) and C_Map.GetMapInfo(crateInfo.zoneID).name or "Unknown Zone"
        if crateInfo then
            local nextCrateText = RdysCrateTracker.nextCrateText(crateInfo, GetServerTime())
            local message = "Next Crate: " .. mapName .. " - " .. (crateInfo.shardhist or "N/A") .. " in - " .. nextCrateText
            if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
            SendChatMessage(message, "RAID_WARNING")
            end
        end
    end
end

RdysCrateTracker.announceFirstCrate = announceFirstCrate


-- ================================
-- Cleaned-up checkTimers
-- ================================
local function checkTimers()
    if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end

    local curTime = GetServerTime()
    RdysCrateTracker.db.profile.crateDB = RdysCrateTracker.db.profile.crateDB or {}

    for _, crateInfo in pairs(RdysCrateTracker.db.profile.crateDB) do
        if crateInfo and crateInfo.zoneID then
            -- NEW: use zoneID, not zoneParentID
            if RdysCrateTracker:shouldWarn(crateInfo.zoneID) then
                RdysCrateTracker.warnCrate(crateInfo, curTime)
            end
        end
    end

    RdysCrateTracker.updateFrame(curTime)
end

RdysCrateTracker.checkTimers = checkTimers

local lastVignetteAnnouncements = {} -- Table to track last announcement times for each vignetteID in each zone

local function handleVignetteMessage(vignetteInfo)
    local profile = RdysCrateTracker.db.profile
    if not profile or not profile.enable or profile.notPvp then return end
    if profile.Combatdisable and UnitAffectingCombat("player") then return end
    if not vignetteInfo then return end
        if (RdysCrateTracker and ((RdysCrateTracker.IsBlockedInstance and RdysCrateTracker:IsBlockedInstance()) or (RdysCrateTracker.WarmodeTS and RdysCrateTracker:WarmodeTS()))) then  return end
    ------------------------------------------------------------
    -- RESOLVE RAW MAP FOR API + NORMALIZED MAP FOR LOGIC
    ------------------------------------------------------------
    local rawMap = RdysCrateTracker.currentZoneID or C_Map.GetBestMapForUnit("player")
    if not rawMap then return end

    -- Normalize for ALL logic (throttle, tracking, filtering)
    local nz = RdysCrateTracker:NormalizeZoneID(rawMap)
    if not nz then return end

    -- Optional debug
    if profile.debugged then
        print("|cff8888ff[RCT:VIGNETTE]|r RawMap:", rawMap, "Normalized:", nz)
    end

    ------------------------------------------------------------
    -- Only respond in TWW outdoor zones (optional safety)
    ------------------------------------------------------------
    local validNZ = RdysCrateTracker.ALLOWED_CRATE_ZONES


    if not validNZ[nz] then
        if profile.debugged then
            print("|cffff8800[RCT:VIGNETTE]|r Ignored vignette in non-TWW zone:", nz)
        end
        return
    end

    ------------------------------------------------------------
    -- VIGNETTE ID RESOLUTION
    ------------------------------------------------------------
    local vignetteID = vignetteInfo.vignetteID or vignetteInfo.vignetteGUID
    if not vignetteID then return end
    ------------------------------------------------------------
    -- POSITION LOOKUP (MUST USE RAW MAP ID)
    ------------------------------------------------------------
    local position = C_VignetteInfo.GetVignettePosition(vignetteInfo.vignetteGUID, rawMap)
    if not position then
        if profile.debugged then
            print("|cffff4444[RCT:VIGNETTE]|r NO POSITION — likely city/phased/normalized issue")
        end
        return
    end

    local readableX = math.floor((position.x or 0) * 10000 + 0.5) / 100
    local readableY = math.floor((position.y or 0) * 10000 + 0.5) / 100

    local zoneName = C_Map.GetMapInfo(nz) and C_Map.GetMapInfo(nz).name or "Unknown Zone"

    ------------------------------------------------------------
    -- PER-ZONE THROTTLE (5 minutes)
    ------------------------------------------------------------
    lastVignetteAnnouncements[nz] = lastVignetteAnnouncements[nz] or {}
    
    local last = lastVignetteAnnouncements[nz][vignetteID]
    local now  = GetServerTime()

    if last and (now - last < 300) then
        if profile.debugged then
            print("|cffffff00[RCT:VIGNETTE]|r Throttled vignette", vignetteID, "in", nz)
        end
        return
    end

    ------------------------------------------------------------
    -- MESSAGE SELECTION
    ------------------------------------------------------------
    local message = nil

    if vignetteID == 6067 or vignetteID == 6068 then
        message = "Hated Gaming Supply Crate Claimed in " .. zoneName
    end
    -- others intentionally disabled: 3689/2967/6066

    if not message then return end

    ------------------------------------------------------------
    -- OUTPUT LOGIC (RAID_WARNING if leader/assist)
    ------------------------------------------------------------
    if IsInGroup() and IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        SendChatMessage(message, "RAID_WARNING")
    else
        RdysCrateTracker:Print(message)
    end

    ------------------------------------------------------------
    -- RECORD ANNOUNCE TIME
    ------------------------------------------------------------
    lastVignetteAnnouncements[nz][vignetteID] = now

    if profile.debugged then
        print("|cff33ff99[RCT:VIGNETTE]|r Announced:", message)
    end
end

RdysCrateTracker.handleVignetteMessage = handleVignetteMessage


C_ChatInfo.RegisterAddonMessagePrefix("zRdyCrate")
C_ChatInfo.RegisterAddonMessagePrefix("zrdycrate_main")

------------------------------------------------------------Call out DabbnGrandpa for stealing my code----------------------------------------------------
-- Initialize seenVignetteGUIDs as an empty table
RdysCrateTracker.seenVignetteGUIDs = {}




--------------------------------------------ALL RIGHTS RESERVED - use this way to do stuff and we will all know and you will be shamed------------------------------------

--[[
RdysCrateTracker.titlepanel:SetScript("OnShow", function()
    if RdysCrateTracker.timer ~= nil then
        RdysCrateTracker.timer:Cancel()
      --  RdysCrateTracker.timer = C_Timer.NewTicker(1, checkTimers)
    end
end)

RdysCrateTracker.titlepanel:SetScript("OnHide", function()
    if RdysCrateTracker.timer ~= nil then
        RdysCrateTracker.timer:Cancel()
     --   RdysCrateTracker.timer = C_Timer.NewTicker(10, checkTimers)
    end
end)

]]



local function TitlePanel_OnEvent(self, event, ...)
    local profile = RdysCrateTracker.db and RdysCrateTracker.db.profile
    if not profile or not profile.enable or profile.notPvp then return end

    if (RdysCrateTracker and ((RdysCrateTracker.IsBlockedInstance and RdysCrateTracker:IsBlockedInstance()) or (RdysCrateTracker.WarmodeTS and RdysCrateTracker:WarmodeTS()))) then return end
    if profile.Combatdisable and UnitAffectingCombat("player") then return end

    if event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
        RdysCrateTracker:HandleZoneShardTransition(5, 1)

        return
    end

    if event == "PLAYER_FLAGS_CHANGED" then
        updateFrame(GetServerTime())
        return
    end

    if event == "CHAT_MSG_MONSTER_SAY" then
        local text, npcName = ...
        if type(text) ~= "string" or type(npcName) ~= "string" then
            return
        end

        if npcName == "Ruffious"
        or npcName == "Ziadan"
        or npcName == "Vidious" then
            local t = string.lower(text)
            if t:find("opportunity")
            or t:find("valuable resources")
            or t:find("treasure nearby")
            or t:find("cache of resources")
            or t:find("you like goods") then
                RdysCrateTracker:crateSpotted("SPOT")
            end
        end
        return
    end

    if event == "GROUP_JOINED" then
        if not UnitIsGroupLeader("player") then
            RdysCrateTracker.db.profile.crateDB = {}
        end
        return
    end

    if event == "PLAYER_LOGOUT" then
        SaveSettings()
        return
    end
end

RdysCrateTracker.titlepanel:SetScript("OnEvent", TitlePanel_OnEvent)

RdysCrateTracker.titlepanel:RegisterEvent("ZONE_CHANGED")
RdysCrateTracker.titlepanel:RegisterEvent("ZONE_CHANGED_NEW_AREA")
RdysCrateTracker.titlepanel:RegisterEvent("PLAYER_FLAGS_CHANGED")
RdysCrateTracker.titlepanel:RegisterEvent("CHAT_MSG_MONSTER_SAY")
RdysCrateTracker.titlepanel:RegisterEvent("GROUP_JOINED")
RdysCrateTracker.titlepanel:RegisterEvent("PLAYER_LOGOUT")
