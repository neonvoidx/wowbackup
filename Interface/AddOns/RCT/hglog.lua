local addonName, addonTable = ...
local LibStub = LibStub or _G.LibStub
local HGLog = LibStub("AceAddon-3.0"):NewAddon("HGLog", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceComm-3.0")
local RdysCrateTracker = LibStub("AceAddon-3.0"):GetAddon("RdysCrateTracker", true)

local CLEANUP_AGE = 7 * 24 * 60 * 60
local ROW_HEIGHT = 48
local MAX_VISIBLE_ROWS = 7

local COMM_PREFIX = "HGLOG1"
local COMM_VER = 1
local COMM_TYPE_FULL = "FULL"
local COMM_TYPE_PULL = "PULL"
local COMM_MAX_CHUNK = 220
local COMM_INCOMING_TTL = 30
local COMM_INCOMING_MAX_BYTES = 12000
local COMM_INCOMING_MAX_CHUNKS = 200

local COLOR_PINK = "|cffff33ff"
local COLOR_GREEN = "|cff00ff00"
local COLOR_WHITE = "|cffffffff"
local COLOR_GRAY = "|cff888888"
local COLOR_RED = "|cffff3333"
local COLOR_LIGHTBLUE = "|cff00ccff"

local OBS_INTERVAL_MIN = 1090
local OBS_INTERVAL_MAX = 1105

local ZONE_FILTER_ALL = "ALL"
local ZONE_FILTER_CURRENT = "CURRENT"

local function IsInAnyInstance()
    local inInstance = IsInInstance()
    return inInstance == true
end

local function StateBool(v) return v == true end

local function FormatCountdown(seconds)
    seconds = tonumber(seconds) or 0
    if seconds < 0 then seconds = 0 end
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

local function GetZoneInterval(zoneID)
    if not zoneID then return 0 end
    if not RdysCrateTracker then return 0 end
    if type(RdysCrateTracker.frequency) ~= "table" then return 0 end
    return tonumber(RdysCrateTracker.frequency[zoneID]) or 0
end

local function GetZoneName(zoneID)
    local info = zoneID and C_Map.GetMapInfo(zoneID)
    return (info and info.name) or ("Zone " .. tostring(zoneID or "?"))
end

local function GetCurrentShardID()
    if RdysCrateTracker and RdysCrateTracker.ShardID then
        return tostring(RdysCrateTracker.ShardID)
    end
    return nil
end

local function GetCurrentZoneID()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID and RdysCrateTracker and RdysCrateTracker.currentZoneID then 
        mapID = tonumber(RdysCrateTracker.currentZoneID) 
    end
    if mapID then
        if RdysCrateTracker and type(RdysCrateTracker.NormalizeZoneID) == "function" then
            local nz = RdysCrateTracker:NormalizeZoneID(mapID)
            if nz then return tonumber(nz) end
        end
        return tonumber(mapID)
    end
    return nil
end

local function ComputeNextDrop(droppedTS, freq, now)
    droppedTS = tonumber(droppedTS) or 0
    freq = tonumber(freq) or 0
    now = tonumber(now) or GetServerTime()
    if droppedTS <= 0 or freq <= 0 then return 0,0,0 end
    local elapsed = now - droppedTS
    if elapsed < 0 then elapsed = 0 end
    local cycles = math.floor(elapsed / freq)
    local nextTS = droppedTS + ((cycles + 1) * freq)
    local remain = nextTS - now
    local missed = cycles - 1
    if missed < 0 then missed = 0 end
    return nextTS, remain, missed
end

local function GetBestIntervalForEntry(entry)
    if type(entry) ~= "table" then return 0, "NONE" end
    local observed = tonumber(entry.interval) or 0
    local count = tonumber(entry.intervalCount) or 0
    local lastKnown = tonumber(entry.lastKnownInterval) or 0
    local highestStreak = tonumber(entry.highestStreak) or 0
    if observed >= OBS_INTERVAL_MIN and observed <= OBS_INTERVAL_MAX and count >= 1 then
        return observed, "OBS"
    end
    if lastKnown >= OBS_INTERVAL_MIN and lastKnown <= OBS_INTERVAL_MAX and highestStreak >= 1 then
        return lastKnown, "OBS-HIST"
    end
    local zoneID = tonumber(entry.zoneID)
    local fallback = GetZoneInterval(zoneID)
    if fallback > 0 then return fallback, "RCT" end
    return 0, "NONE"
end

-- DB helpers
local function MakeKey(zoneID, shardID)
    return tostring(zoneID) .. "-" .. tostring(shardID)
end

function HGLog:MarkDataDirty()
    self._dataRevision = (tonumber(self._dataRevision) or 0) + 1
    self._sortedCache = nil
    self._sortedCacheKey = nil
end

function HGLog:AddLogEntry(zoneID, timestamp, shardID)
    if IsInAnyInstance() then return end
    if not zoneID or not timestamp or not shardID then return end

    local nz = RdysCrateTracker and type(RdysCrateTracker.NormalizeZoneID) == "function" and RdysCrateTracker:NormalizeZoneID(zoneID)
    if not nz then return end
    zoneID = nz

    zoneID = tonumber(zoneID)
    timestamp = tonumber(timestamp)
    shardID = tostring(shardID)
    if not zoneID or not timestamp or shardID == "" then return end
    local key = MakeKey(zoneID, shardID)
    local existing = self.db[key]
    local changed = false
    if not existing then
        self.db[key] = { zoneID=zoneID, timestamp=timestamp, prevTimestamp=0, shardID=shardID, interval=0, intervalCount=0, lastKnownInterval=0, highestStreak=0 }
        changed = true
    else
        local prevTS = tonumber(existing.timestamp) or 0
        if timestamp > prevTS then
            existing.prevTimestamp = prevTS
            existing.timestamp = timestamp
            existing.zoneID = zoneID
            existing.shardID = shardID
            if prevTS > 0 then
                local observed = timestamp - prevTS
                if observed >= OBS_INTERVAL_MIN and observed <= OBS_INTERVAL_MAX then
                    existing.interval = observed
                    existing.intervalCount = (tonumber(existing.intervalCount) or 0) + 1
                    existing.lastKnownInterval = observed
                    if existing.intervalCount > (tonumber(existing.highestStreak) or 0) then
                        existing.highestStreak = existing.intervalCount
                    end
                else
                    existing.intervalCount = 0
                end
            end
            changed = true
        end
    end
    if changed then self:MarkDataDirty() end
    if self.frame and self.frame:IsShown() then self:UpdateZoneDropdownText(); self:UpdateLog() end
end

function HGLog:UpsertLogEntryIfNewer(zoneID, timestamp, shardID)
    if IsInAnyInstance() then return false, false end
    if not zoneID or not timestamp or not shardID then return false, false end

    local nz = RdysCrateTracker and type(RdysCrateTracker.NormalizeZoneID) == "function" and RdysCrateTracker:NormalizeZoneID(zoneID)
    if not nz then return false, false end
    zoneID = nz

    zoneID = tonumber(zoneID)
    timestamp = tonumber(timestamp)
    shardID = tostring(shardID)
    if not zoneID or not timestamp or shardID == "" then return false, false end
    local key = MakeKey(zoneID, shardID)
    local existing = self.db[key]
    if not existing then
        self.db[key] = { zoneID=zoneID, timestamp=timestamp, prevTimestamp=0, shardID=shardID, interval=0, intervalCount=0, lastKnownInterval=0, highestStreak=0 }
        self:MarkDataDirty()
        return true, true
    end
    local existingTS = tonumber(existing.timestamp) or 0
    if timestamp > existingTS then
        existing.prevTimestamp = existingTS
        existing.zoneID = zoneID
        existing.timestamp = timestamp
        existing.shardID = shardID
        if existingTS > 0 then
            local observed = timestamp - existingTS
            if observed >= OBS_INTERVAL_MIN and observed <= OBS_INTERVAL_MAX then
                existing.interval = observed
                existing.intervalCount = (tonumber(existing.intervalCount) or 0) + 1
                    existing.lastKnownInterval = observed
                    if existing.intervalCount > (tonumber(existing.highestStreak) or 0) then
                        existing.highestStreak = existing.intervalCount
                    end
            else
                existing.intervalCount = 0
            end
        end
        self:MarkDataDirty()
        return true, false
    end
    return false, false
end

function HGLog:DeleteLogEntry(zoneID, shardID)
    if not zoneID or not shardID then return end
    local key = MakeKey(zoneID, shardID)
    if self.db[key] then self.db[key] = nil; self:MarkDataDirty() end
end

function HGLog:ClearAll()
    local changed = false
    for k in pairs(self.db) do self.db[k] = nil; changed = true end
    if changed then self:MarkDataDirty() end
end

function HGLog:Cleanup()
    local now = GetServerTime()
    local count = 0
    for key, data in pairs(self.db) do
        local nz = data.zoneID and RdysCrateTracker and type(RdysCrateTracker.NormalizeZoneID) == "function" and RdysCrateTracker:NormalizeZoneID(data.zoneID)
        if not nz or (now - (data.timestamp or 0)) > CLEANUP_AGE then
            self.db[key] = nil
            count = count + 1
        end
    end
    if count > 0 then
        self:MarkDataDirty()
        if StateBool(self.settings and self.settings.debug) then print("|cff00ff00[HGLog]|r Removed " .. count .. " old or invalid logs.") end
    end
end

-- Hook into RCT.recordCrate if available
function HGLog:HookRCTRecordCrate()
    if not RdysCrateTracker then return end
    if type(RdysCrateTracker.recordCrate) ~= "function" then return end
    if self._hookedRecordCrate then return end
    self._hookedRecordCrate = true
    self:SecureHook(RdysCrateTracker, "recordCrate", function(_, crateInfo, sender)
        if type(crateInfo) ~= "table" then return end
        local zoneID = crateInfo.zoneID
        local ts = crateInfo.ts or GetServerTime()
        local shardID = crateInfo.shardhist or (RdysCrateTracker and RdysCrateTracker.ShardID) or "N/A"
        if zoneID and shardID and shardID ~= "N/A" then self:AddLogEntry(zoneID, ts, shardID) end
    end)
end

-- COMM and export
function HGLog:BuildExportString()
    if IsInAnyInstance() then return "" end
    local parts = {}
    for _, v in pairs(self.db) do
        if type(v) == "table" and v.zoneID and v.timestamp and v.shardID then
            local nz = RdysCrateTracker and type(RdysCrateTracker.NormalizeZoneID) == "function" and RdysCrateTracker:NormalizeZoneID(v.zoneID)
            if nz then
                local zoneID = tonumber(nz) or 0
                local ts = tonumber(v.timestamp) or 0
                local shardID = tostring(v.shardID):gsub("[^0-9]", "")
                if shardID ~= "" and zoneID > 0 and ts > 0 then
                    table.insert(parts, string.format("%d,%d,%s", zoneID, ts, shardID))
                end
            end
        end
    end
    return table.concat(parts, ";")
end

function HGLog:SendComm(payload, channel)
    if IsInAnyInstance() then return end
    if channel == "GUILD" then
        if not IsInGuild() then return end
    elseif channel == "RAID" then
        if not IsInRaid() then return end
    end
    self:SendCommMessage(COMM_PREFIX, payload, channel)
end

function HGLog:ShareDBToChannels(targetChannel)
    if IsInAnyInstance() then return end
    local export = self:BuildExportString()
    if export == "" then return end
    
    local totalLen = #export
    local idx = 1
    local chunkNum = 0
    local messages = {}
    
    while idx <= totalLen do
        chunkNum = chunkNum + 1
        local chunk = export:sub(idx, idx + COMM_MAX_CHUNK - 1)
        idx = idx + COMM_MAX_CHUNK
        local msg = string.format("%d|%s|%d|%s", COMM_VER, COMM_TYPE_FULL, chunkNum, chunk)
        table.insert(messages, msg)
    end
    table.insert(messages, string.format("%d|%s|END|", COMM_VER, COMM_TYPE_FULL))
    
    -- Determine channels to send to
    local channels = {}
    if targetChannel then
        table.insert(channels, targetChannel)
    else
        -- Default: send to both if available
        if IsInGuild() then table.insert(channels, "GUILD") end
        if IsInRaid() then table.insert(channels, "RAID") end
    end
    
    -- Send to target channels
    for _, channel in ipairs(channels) do
        if channel == "GUILD" and IsInGuild() then
            for _, msg in ipairs(messages) do
                self:SendComm(msg, "GUILD")
            end
        elseif channel == "RAID" and IsInRaid() then
            for _, msg in ipairs(messages) do
                self:SendComm(msg, "RAID")
            end
        end
    end
end

function HGLog:ShareDBToGuild()
    if IsInAnyInstance() then if StateBool(self.settings and self.settings.debug) then print("|cffff0000[HGLog]|r Share blocked in instances.") end; return end
    if not IsInGuild() then if StateBool(self.settings and self.settings.debug) then print("|cffff0000[HGLog]|r You are not in a guild.") end; return end
    self:ShareDBToChannels()
    if StateBool(self.settings and self.settings.debug) then print("|cff00ff00[HGLog]|r Shared DB to guild.") end
end

function HGLog:OnCommReceived(prefix, message, distribution, sender)
    if IsInAnyInstance() then return end
    if distribution ~= "GUILD" and distribution ~= "RAID" then return end
    if prefix ~= COMM_PREFIX then return end
    if type(message) ~= "string" or message == "" then return end
    if sender == UnitName("player") then return end

    -- Explicit protection: if receiving via raid, ensure sender is actually in our raid roster
    if distribution == "RAID" and not UnitInRaid(sender) then return end

    self._incoming = self._incoming or {}
    self:CleanupIncomingBuffers()
    local ver, msgType, chunkID, data = string.match(message, "^(%d+)|([^|]+)|([^|]+)|?(.*)$")
    ver = tonumber(ver or 0)
    if ver ~= COMM_VER then return end
    if msgType == COMM_TYPE_PULL then
        C_Timer.After(math.random() * 2, function()
            self:ShareDBToChannels(distribution)
        end)
        return
    end
    if msgType ~= COMM_TYPE_FULL then return end
    self._incoming[sender] = self._incoming[sender] or { buf = {}, bytes = 0, chunks = 0, lastSeen = GetServerTime() }
    local state = self._incoming[sender]
    state.lastSeen = GetServerTime()
    if chunkID == "END" then
        local full = table.concat(state.buf, "")
        state.buf = {}
        state.bytes = 0
        state.chunks = 0
        local added = 0
        local updated = 0
        for entry in string.gmatch(full, "([^;]+)") do
            local zoneID, ts, shardID = string.match(entry, "^(%d+),(%d+),([^,]+)$")
            zoneID = tonumber(zoneID)
            ts = tonumber(ts)
            if zoneID and ts and shardID and shardID ~= "" then
                local changed, wasNew = self:UpsertLogEntryIfNewer(zoneID, ts, shardID)
                if changed then
                    if wasNew then added = added + 1 else updated = updated + 1 end
                end
            end
        end
        if (added + updated) > 0 then
            self:MarkDataDirty()
            if StateBool(self.settings and self.settings.debug) then print("|cff00ff00[HGLog]|r Imported from " .. string.lower(distribution) .. " (" .. tostring(sender) .. "): +" .. added .. " new, ~" .. updated .. " updated.") end
        end
        if self.frame and self.frame:IsShown() then self:UpdateZoneDropdownText(); self:UpdateLog() end
        return
    end
    local chunkNum = tonumber(chunkID)
    if not chunkNum then return end
    local part = data or ""
    state.chunks = (state.chunks or 0) + 1
    state.bytes = (state.bytes or 0) + #part
    if state.chunks > COMM_INCOMING_MAX_CHUNKS or state.bytes > COMM_INCOMING_MAX_BYTES then
        self._incoming[sender] = nil
        if StateBool(self.settings and self.settings.debug) then print("|cffff0000[HGLog]|r Dropped oversized " .. string.lower(distribution) .. " payload from " .. tostring(sender)) end
        return
    end
    table.insert(state.buf, part)
end

function HGLog:ImportToRCT(data)
    if not data then return end
    if IsInGroup() and not UnitIsGroupLeader("player") then
        print("|cffff0000[HGLog]|r Only the group leader can import timers while in a group.")
        return
    end
    if not RdysCrateTracker then return end

    local crateInfo = {
        zoneID = data.zoneID,
        ts = data.timestamp,
        shardhist = data.shardID,
        method = "HGLog",
    }

    if type(RdysCrateTracker.recordCrate) == "function" then
        RdysCrateTracker:recordCrate(crateInfo, UnitName("player"))
        if StateBool(self.settings and self.settings.debug) then
            print("|cff00ff00[HGLog]|r Imported timer for " .. GetZoneName(data.zoneID) .. " (Shard: " .. tostring(data.shardID) .. ") into Crate Tracker.")
        end
        
        if IsInGroup() and UnitIsGroupLeader("player") and type(RdysCrateTracker.BroadcastSync) == "function" then
            RdysCrateTracker:BroadcastSync()
        end

        if type(RdysCrateTracker.updateFrame) == "function" then
            RdysCrateTracker.updateFrame(GetServerTime())
        end
    end
end

function HGLog:CreateWindow()
    self.frame = CreateFrame("Frame", "HGLogFrame", UIParent, "BackdropTemplate")
    local f = self.frame
    f:SetSize(300, 420)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); HGLog:SaveWindowPosition() end)
    f:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 }, })
    f:SetBackdropColor(0, 0, 0, 0.9)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.title:SetPoint("TOPLEFT", 12, -12)
    f.title:SetText("|cff00ff00HG|r Multi-Shard Log")
    f.currentShardText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.currentShardText:SetPoint("BOTTOMLEFT", 12, 12)
    f.currentShardText:SetTextColor(0, 0.8, 1)
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -2, -2)
    f.close:SetScript("OnClick", function() f:Hide(); if HGLog.StopTicker then HGLog:StopTicker() end end)
    f.clearAll = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.clearAll:SetSize(90, 18)
    f.clearAll:SetPoint("TOPRIGHT", f.close, "TOPLEFT", -6, -2)
    f.clearAll:SetText("Clear All")
    f.clearAll:SetScript("OnClick", function() HGLog:ClearAll(); local scrollbar = _G[f.scrollFrame:GetName() .. "ScrollBar"]; if scrollbar then scrollbar:SetValue(0) end; HGLog:UpdateZoneDropdownText(); HGLog:UpdateLog(true) end)
    
    f.zoneFilterButton = CreateFrame("Button", "HGLogZoneFilterDropDown", f, "UIDropDownMenuTemplate")
    f.zoneFilterButton:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -6)
    UIDropDownMenu_SetWidth(f.zoneFilterButton, 140)
    UIDropDownMenu_JustifyText(f.zoneFilterButton, "LEFT")
    UIDropDownMenu_Initialize(f.zoneFilterButton, function(_, level)
        local items = HGLog:BuildZoneFilterMenuList()
        for _, item in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.text
            info.value = item.value
            info.checked = (tostring(HGLog:GetZoneFilterValue()) == tostring(item.value))
            info.func = function() HGLog:SetZoneFilterValue(item.value); CloseDropDownMenus() end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    f.scrollFrame = CreateFrame("ScrollFrame", "HGLogScrollFrame", f, "UIPanelScrollFrameTemplate")
    f.scrollFrame:SetPoint("TOPLEFT", 12, -64)
    f.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 12)
    f.content = CreateFrame("Frame", nil, f.scrollFrame)
    f.content:SetSize(258, 1)
    f.scrollFrame:SetScrollChild(f.content)
    f.scrollFrame:EnableMouseWheel(true)
    f.scrollFrame:SetScript("OnMouseWheel", function(_, delta) HGLog:ScrollBy(-delta) end)
    f.scrollFrame:SetScript("OnVerticalScroll", function(self, offset) self:SetVerticalScroll(0); HGLog:UpdateLog() end)
    f.rows = {}
    for i = 1, MAX_VISIBLE_ROWS do
        local row = CreateFrame("Frame", nil, f.content, "BackdropTemplate")
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_HEIGHT)
        row:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = nil, tile = false, })
        row:SetBackdropColor(0, 0, 0, 0)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("TOPLEFT", 6, -2)
        row.text:SetPoint("RIGHT", row, "RIGHT", -48, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetJustifyV("TOP")

        local delBtn = CreateFrame("Button", nil, row, "UIPanelCloseButton")
        delBtn:SetSize(16, 16)
        delBtn:SetPoint("RIGHT", -2, 0)
        delBtn:SetScript("OnClick", function()
            if not row._data then return end
            HGLog:DeleteLogEntry(row._data.zoneID, row._data.shardID)
            HGLog:UpdateLog(true)
        end)
        delBtn:SetScript("OnEnter", function(selfBtn)
            GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Delete this entry", 1, 0, 0)
            GameTooltip:Show()
        end)
        delBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row.delBtn = delBtn

        local impBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        impBtn:SetSize(16, 16)
        impBtn:SetPoint("RIGHT", delBtn, "LEFT", 0, 0)
        impBtn:SetText("+")
        impBtn:SetScript("OnClick", function()
            if not row._data then return end
            if HGLog.ImportToRCT then HGLog:ImportToRCT(row._data) end
        end)
        impBtn:SetScript("OnEnter", function(selfBtn)
            if not row._data then return end
            GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(GetZoneName(row._data.zoneID) .. " - Shard: " .. tostring(row._data.shardID), 1, 1, 1)
            GameTooltip:AddLine("Add/Import to main Crate Tracker", 0, 1, 0)
            GameTooltip:Show()
        end)
        impBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row.impBtn = impBtn

        f.rows[i] = row
    end
    self:UpdateZoneDropdownText()
    self:RestoreWindowPosition()
    f:Hide()
end

function HGLog:ScrollBy(deltaRows)
    if not (self.frame and self.frame.scrollFrame) then return end
    local sf = self.frame.scrollFrame
    local scrollbar = _G[sf:GetName() .. "ScrollBar"]
    if not scrollbar then return end
    local step = ROW_HEIGHT
    local newValue = (scrollbar:GetValue() or 0) + (deltaRows * step)
    local minV, maxV = scrollbar:GetMinMaxValues()
    if newValue < minV then newValue = minV end
    if newValue > maxV then newValue = maxV end
    scrollbar:SetValue(newValue)
end

function HGLog:StartTicker()
    if self._ticker then return end
    self._ticker = C_Timer.NewTicker(1, function()
        if self.frame and self.frame:IsShown() then
            self:UpdateLog()
        else
            self:StopTicker()
        end
    end)
end

function HGLog:StopTicker()
    if self._ticker then self._ticker:Cancel(); self._ticker = nil end
end

function HGLog:BuildZoneFilterMenuList()
    local zones = {}
    for _, v in pairs(self.db) do 
        if type(v) == "table" and v.zoneID then 
            local nz = RdysCrateTracker and type(RdysCrateTracker.NormalizeZoneID) == "function" and RdysCrateTracker:NormalizeZoneID(v.zoneID)
            if nz then zones[tonumber(nz)] = true end
        end 
    end
    local list = { { text = "All Zones", value = ZONE_FILTER_ALL }, { text = "Current Zone", value = ZONE_FILTER_CURRENT } }
    local zoneIDs = {}
    for zoneID in pairs(zones) do table.insert(zoneIDs, zoneID) end
    table.sort(zoneIDs, function(a,b) return GetZoneName(a) < GetZoneName(b) end)
    for _, zoneID in ipairs(zoneIDs) do table.insert(list, { text = GetZoneName(zoneID), value = tostring(zoneID) }) end
    return list
end

function HGLog:GetZoneFilterValue()
    if not self.settings then return ZONE_FILTER_ALL end
    return self.settings.zoneFilter or ZONE_FILTER_ALL
end

function HGLog:SetZoneFilterValue(value)
    if not self.settings then return end
    self.settings.zoneFilter = value or ZONE_FILTER_ALL
    if self.frame and self.frame.scrollFrame then local scrollbar = _G[self.frame.scrollFrame:GetName() .. "ScrollBar"] if scrollbar then scrollbar:SetValue(0) end end
    self:UpdateZoneDropdownText()
    self:UpdateLog(true)
end

function HGLog:GetZoneFilterDisplayText()
    local filter = self:GetZoneFilterValue()
    if filter == ZONE_FILTER_ALL then return "All Zones" end
    if filter == ZONE_FILTER_CURRENT then return "Current Zone" end
    local zoneID = tonumber(filter)
    if zoneID then return GetZoneName(zoneID) end
    return "All Zones"
end

function HGLog:UpdateZoneDropdownText()
    if not (self.frame and self.frame.zoneFilterButton and self.frame.zoneFilterButton.text) then return end
    self.frame.zoneFilterButton.text:SetText(self:GetZoneFilterDisplayText())
end

function HGLog:BuildSortedList()
    local currentZoneID = GetCurrentZoneID()
    local filter = self:GetZoneFilterValue()
    local rev = tonumber(self._dataRevision) or 0
    local cacheKey = table.concat({ tostring(rev), tostring(filter), tostring(currentZoneID or 0) }, "|")
    if self._sortedCacheKey == cacheKey and type(self._sortedCache) == "table" then return self._sortedCache end
    local list = {}
    local function PassesFilter(zoneID)
        zoneID = tonumber(zoneID)
        if not zoneID then return false end

        local nz = RdysCrateTracker and type(RdysCrateTracker.NormalizeZoneID) == "function" and RdysCrateTracker:NormalizeZoneID(zoneID)
        if not nz then return false end
        zoneID = tonumber(nz)

        if filter == ZONE_FILTER_ALL then return true end
        if filter == ZONE_FILTER_CURRENT then return (currentZoneID and zoneID == currentZoneID) end
        return tostring(zoneID) == tostring(filter)
    end
    for _, v in pairs(self.db) do if type(v) == "table" and v.zoneID and v.timestamp and v.shardID then if PassesFilter(v.zoneID) then table.insert(list, v) end end end
    table.sort(list, function(a, b)
        local aInZone = (a.zoneID == currentZoneID)
        local bInZone = (b.zoneID == currentZoneID)
        if aInZone ~= bInZone then return aInZone end
        local aName = GetZoneName(a.zoneID)
        local bName = GetZoneName(b.zoneID)
        if aName ~= bName then return aName < bName end
        return (a.timestamp or 0) > (b.timestamp or 0)
    end)
    self._sortedCacheKey = cacheKey
    self._sortedCache = list
    return list
end

function HGLog:UpdateLog(forceScrollTop)
    if not (self.frame and self.frame:IsShown()) then return end
    if IsInAnyInstance() then
        self.frame.currentShardText:SetText("Instance detected: HGLog listing and comms blocked")
        for i=1,MAX_VISIBLE_ROWS do local row = self.frame.rows and self.frame.rows[i] if row then row:Hide(); row._data = nil end end
        return
    end
    local now = GetServerTime()
    local liveZone = GetCurrentZoneID()
    local liveShard = GetCurrentShardID()
    if liveZone and liveZone ~= self._lastZoneID then self._lastZoneID = liveZone; forceScrollTop = true end
    if self:GetZoneFilterValue() == ZONE_FILTER_CURRENT then self:UpdateZoneDropdownText() end
    local list = self:BuildSortedList()
    self._sortedList = list
    local total = #list
    self.frame.content:SetHeight(MAX_VISIBLE_ROWS * ROW_HEIGHT)
    local scrollbar = _G[self.frame.scrollFrame:GetName() .. "ScrollBar"]
    if scrollbar then local maxScroll = 0 if total > MAX_VISIBLE_ROWS then maxScroll = (total - MAX_VISIBLE_ROWS) * ROW_HEIGHT end scrollbar:SetMinMaxValues(0, maxScroll) if forceScrollTop then scrollbar:SetValue(0) end end
    self.frame.scrollFrame:SetVerticalScroll(0)
    local scrollPos = (scrollbar and scrollbar:GetValue()) or 0
    local offset = math.floor(scrollPos / ROW_HEIGHT)
    if offset < 0 then offset = 0 end
    local maxOffset = math.max(0, total - MAX_VISIBLE_ROWS)
    if offset > maxOffset then offset = maxOffset end
    self._scrollOffset = offset
    self.frame.currentShardText:SetText(liveShard and ("Current Shard: " .. liveShard) or "Current Shard: None")
    for i=1,MAX_VISIBLE_ROWS do
        local idx = offset + i
        local row = self.frame.rows[i]
        local data = list[idx]
        if data then
            row:Show()
            row._data = data
            local zoneID = tonumber(data.zoneID)
            local shardID = tostring(data.shardID or "")
            local droppedTS = tonumber(data.timestamp) or 0
            local zoneName = GetZoneName(zoneID)
            local interval, intervalSource = GetBestIntervalForEntry(data)
            local nextText = "N/A"
            if interval > 0 then
                local nextTS, remain, missed = ComputeNextDrop(droppedTS, interval, now)
                nextText = FormatCountdown(remain) .. "  " .. COLOR_GRAY .. "(" .. date("%H:%M:%S", nextTS) .. ")|r"
                if missed > 0 then nextText = nextText .. "  " .. COLOR_RED .. "M: " .. tostring(missed) .. "|r" end
            end
            local intervalLabel = ""
            if interval > 0 then intervalLabel = string.format("   Interval: %d (%s)\n", interval, intervalSource) end
            
            local lineColor = COLOR_WHITE
            if liveZone and liveShard and zoneID == liveZone and shardID == liveShard then
                lineColor = COLOR_PINK
            else
                local age = now - droppedTS
                if age < 600 then
                    lineColor = COLOR_GREEN
                elseif age > 3600 then
                    lineColor = COLOR_GRAY
                end
            end

            row.text:SetText(string.format("%s%s|r  %s[Shard :: %s]|r\n   Dropped: %s (%s)\n%s   |cff33ff99Next In: %s|r", 
                lineColor, zoneName, COLOR_LIGHTBLUE, shardID, date("%H:%M:%S", droppedTS), date("%m/%d", droppedTS), intervalLabel, nextText))
        else
            row:Hide(); row._data = nil; row.text:SetText("")
        end
    end
end

function HGLog:ChatCommand(input)
    local cmd = string.lower((input or ""):match("^%s*(.-)%s*$"))
    if cmd == "" or cmd == "toggle" then self:ToggleWindow(); return end
    if cmd == "status" then
        local entries = 0 for _, v in pairs(self.db or {}) do if type(v)=="table" and v.zoneID and v.timestamp and v.shardID then entries = entries + 1 end end
        local incomingCount = 0 for _ in pairs(self._incoming or {}) do incomingCount = incomingCount + 1 end
        self:Print("|cff00ff00[HGLog]|r Status")
        self:Print("inInstance=" .. tostring(IsInAnyInstance()) .. ", windowShown=" .. tostring(self.frame and self.frame:IsShown() or false) .. ", tickerActive=" .. tostring(self._ticker ~= nil))
        self:Print("entries=" .. tostring(entries) .. ", zoneFilter=" .. tostring(self:GetZoneFilterValue()) .. ", dataRevision=" .. tostring(self._dataRevision or 0))
        self:Print("incomingSenders=" .. tostring(incomingCount) .. ", debug=" .. tostring(StateBool(self.settings and self.settings.debug)))
        return
    end
    if cmd == "debug" then self.settings.debug = not StateBool(self.settings.debug); self:Print("|cff00ff00[HGLog]|r Debug " .. (self.settings.debug and "enabled" or "disabled")); return end
    if cmd == "share" then self:ShareDBToChannels(); if StateBool(self.settings and self.settings.debug) then print("|cff00ff00[HGLog]|r Manually triggered share to guild/raid.") end; return end
    if cmd == "pull" then
        if IsInRaid() then
            self:SendComm(string.format("%d|%s|REQ|", COMM_VER, COMM_TYPE_PULL), "RAID")
            self:Print("|cff00ff00[HGLog]|r Sent pull request to raid.")
        else
            self:Print("|cffff0000[HGLog]|r You must be in a raid to pull data.")
        end
        return
    end
    if cmd == "intervals" then
        self:Print("|cff00ff00[HGLog]|r Learned Shard Intervals:")
        local found = false
        local entries = {}
        for _, data in pairs(self.db or {}) do
            if type(data) == "table" and data.zoneID and data.shardID then 
                local nz = RdysCrateTracker and type(RdysCrateTracker.NormalizeZoneID) == "function" and RdysCrateTracker:NormalizeZoneID(data.zoneID)
                if nz then table.insert(entries, data) end
            end
        end
        table.sort(entries, function(a, b)
            local aName = GetZoneName(a.zoneID)
            local bName = GetZoneName(b.zoneID)
            if aName == bName then return tostring(a.shardID) < tostring(b.shardID) end
            return aName < bName
        end)
        for _, data in ipairs(entries) do
            local interval, source = GetBestIntervalForEntry(data)
            -- Only print shards where we actively proved the interval, ignoring generic RCT fallback
            if source == "OBS" or source == "OBS-HIST" then
                local zoneName = GetZoneName(data.zoneID)
                local highestStreak = tonumber(data.highestStreak) or 0
                self:Print(string.format(" %s [%s]: |cff00ff00%ds|r (%s) |cff00ccff[Max Streak: %d]|r", 
                    zoneName, data.shardID, interval, source, highestStreak))
                found = true
            end
        end
        if not found then self:Print(" No observed intervals recorded yet.") end
        return
    end
    if cmd == "help" then
        self:Print("|cff00ff00[HGLog]|r Commands:")
        self:Print("/hglog toggle  - Show/hide window")
        self:Print("/hglog status  - Show runtime status")
        self:Print("/hglog debug   - Toggle debug logging")
        self:Print("/hglog share   - Share DB to guild")
        self:Print("/hglog pull    - Request DB share from raid members")
        self:Print("/hglog intervals - Show learned zones and best intervals")
        return
    end
    self:Print("|cffff0000[HGLog]|r Unknown command. Try /hglog help")
end

function HGLog:ToggleWindow()
    if not self.frame then return end
    if IsInAnyInstance() then if StateBool(self.settings and self.settings.debug) then print("|cffff0000[HGLog]|r HGLog is blocked in all instance types.") end; if self.frame:IsShown() then self.frame:Hide() end; self:StopTicker(); return end
    if self.frame:IsShown() then self.frame:Hide(); self:StopTicker() else self.frame:Show(); self._scrollOffset = self._scrollOffset or 0; if self.frame.scrollFrame and self.frame.scrollFrame.SetVerticalScroll then self.frame.scrollFrame:SetVerticalScroll(0) end; self:UpdateZoneDropdownText(); self:StartTicker(); self:UpdateLog() end
end

function HGLog:OnZoneChanged()
    C_Timer.After(0.20, function()
        if IsInAnyInstance() then if self.frame and self.frame:IsShown() then self.frame:Hide() end; self:StopTicker(); return end
        local liveZone = GetCurrentZoneID()
        if not liveZone then return end
        if liveZone ~= self._lastZoneID then self._lastZoneID = liveZone; self._scrollOffset = 0; if self.frame and self.frame:IsShown() then local scrollbar = _G[self.frame.scrollFrame:GetName() .. "ScrollBar"] if scrollbar then scrollbar:SetValue(0) end; self:UpdateLog() end end
    end)
end

function HGLog:OnGroupJoined()
    if IsInAnyInstance() then return end
    if IsInRaid() then
        C_Timer.After(0.50, function() self:ShareDBToChannels("RAID") end)
    end
end

function HGLog:OnGroupLeft()
    if IsInAnyInstance() then return end
    C_Timer.After(0.20, function() self:ShareDBToChannels("GUILD") end)
end

function HGLog:OnPlayerLogin()
    if IsInAnyInstance() then return end
    C_Timer.After(1.0, function() self:ShareDBToChannels("GUILD") end)
end

function HGLog:RestoreWindowPosition()
    if not (self.frame and self.settings) then return end
    local p = self.settings.windowPoint
    local rp = self.settings.windowRelativePoint
    local x = self.settings.windowX
    local y = self.settings.windowY
    self.frame:ClearAllPoints()
    if p and rp and x and y then self.frame:SetPoint(p, UIParent, rp, x, y) else self.frame:SetPoint("CENTER") end
end

function HGLog:SaveWindowPosition()
    if not (self.frame and self.settings) then return end
    local p, _, rp, x, y = self.frame:GetPoint(1)
    self.settings.windowPoint = p or "CENTER"
    self.settings.windowRelativePoint = rp or "CENTER"
    self.settings.windowX = x or 0
    self.settings.windowY = y or 0
end

function HGLog:CleanupIncomingBuffers()
    if not self._incoming then return end
    local now = GetServerTime()
    for sender, state in pairs(self._incoming) do
        local lastSeen = state and tonumber(state.lastSeen) or 0
        if (now - lastSeen) > COMM_INCOMING_TTL then self._incoming[sender] = nil end
    end
end

function HGLog:OnInitialize()
    HGLogDB = HGLogDB or {}
    self.db = HGLogDB
    HGLogSettingsDB = HGLogSettingsDB or {}
    self.settings = HGLogSettingsDB
    if not self.settings.zoneFilter then self.settings.zoneFilter = ZONE_FILTER_ALL end
    if self.settings.debug == nil then self.settings.debug = false end
    if self.settings.startupMessage == nil then self.settings.startupMessage = false end
    self._dataRevision = tonumber(self._dataRevision) or 0
    self:Cleanup()
    self:RegisterChatCommand("hglog", "ChatCommand")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneChanged")
    self:RegisterEvent("ZONE_CHANGED", "OnZoneChanged")
    self:RegisterEvent("ZONE_CHANGED_INDOORS", "OnZoneChanged")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnZoneChanged")
    self:RegisterEvent("GROUP_JOINED", "OnGroupJoined")
    self:RegisterEvent("GROUP_LEFT", "OnGroupLeft")
    self:RegisterEvent("PLAYER_LOGIN", "OnPlayerLogin")
    self:RegisterComm(COMM_PREFIX, "OnCommReceived")
    self:CreateWindow()
    self:HookRCTRecordCrate()
    if StateBool(self.settings.startupMessage) or StateBool(self.settings.debug) then self:Print("Loaded. Use /hglog help") end
end
