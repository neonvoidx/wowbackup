local addonName, addonTable = ...
RdyCrateGlobal2 = addonTable
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local RdysCrateTracker = LibStub("AceAddon-3.0"):GetAddon("RdysCrateTracker", true)

-- Get locale table with proper fallback
local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("RdysCrateTracker", true) or {}

if not RdysCrateTracker then
    error(L["ADDON_NOT_FOUND"] or "RdysCrateTracker addon not found. Please ensure it is loaded.")
end


local lastSyncRequestAt = 0

---------------------------
function RdysCrateTracker:addonadvertise()
    local msg = L["ADDON_ADVERTISEMENT"] or 'Hated Crate Tracker by Rdy @ Hated Gaming — "Be Hated! Don\'t just play, dominate." Track crates, sync raids, log timers and dominate War Mode with Hated Gaming - And remember kids if it ain\'t Hated, it ain\'t worth it. Available now on Curseforge!'
    if IsInRaid() then
        SendChatMessage(msg, "RAID")
    elseif IsInGroup() then
        SendChatMessage(msg, "PARTY")
    else
        SendChatMessage(msg, "SAY")
    end
end


-- Title panel 
RdysCrateTracker.titlepanel = CreateFrame("Frame", "RdysCrateTrackerTitlePanel", UIParent, "BackdropTemplate")
RdysCrateTracker.titlepanel:SetSize(250, 25)
RdysCrateTracker.titlepanel:SetPoint("CENTER", UIParent, "CENTER", 0, -10)
RdysCrateTracker.titlepanel:SetBackdrop({
    bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 12,
    insets   = { left = 2, right = 2, top = 2, bottom = 2 },
})
RdysCrateTracker.titlepanel:SetBackdropColor(0, 0, 0, 0.8)




-- Title text
RdysCrateTracker.titlepanel.text = RdysCrateTracker.titlepanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
RdysCrateTracker.titlepanel.text:SetPoint("LEFT", 8, 0)
RdysCrateTracker.titlepanel.text:SetText(L["ADDON_SHORT_NAME"] or "HG Tracker")

-- Helper to toggle all progress rows and pause/restart timer
local function ToggleRows()
    RdysCrateTracker.titlepanel.isMinimized = not RdysCrateTracker.titlepanel.isMinimized

    if RdysCrateTracker.titlepanel.isMinimized then
        -- Hide rows
        for _, row in ipairs(RdysCrateTracker.progressRows or {}) do
            row:Hide()
        end
        -- Pause timer
        if RdysCrateTracker.timer then
            RdysCrateTracker.timer:Cancel()
            RdysCrateTracker.timer = nil
        end
    else
        -- Show rows
        for _, row in ipairs(RdysCrateTracker.progressRows or {}) do
            row:Show()
        end
        -- Restart timer
        RdysCrateTracker.timer = C_Timer.NewTicker(1, RdysCrateTracker.checkTimers)
    end
end



-- Close button (The anchor for the rest)
RdysCrateTracker.titlepanel.close = CreateFrame("Frame", nil, RdysCrateTracker.titlepanel, "BackdropTemplate")
RdysCrateTracker.titlepanel.close:SetSize(20, 20)
RdysCrateTracker.titlepanel.close:SetPoint("RIGHT", -5, 0)
RdysCrateTracker.titlepanel.close:SetScript("OnMouseUp", function()
    RdysCrateTracker.titlepanel:Hide()
    RdysCrateTracker.db.profile.windowClosed = true
end)
RdysCrateTracker.titlepanel.close.text = RdysCrateTracker.titlepanel.close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
RdysCrateTracker.titlepanel.close.text:SetPoint("CENTER")
RdysCrateTracker.titlepanel.close.text:SetText(L["CLOSE_BUTTON"] or "X")


-- Minimize button next to close
RdysCrateTracker.titlepanel.minimize = CreateFrame("Frame", nil, RdysCrateTracker.titlepanel, "BackdropTemplate")
RdysCrateTracker.titlepanel.minimize:SetSize(20, 20)
RdysCrateTracker.titlepanel.minimize:SetPoint("RIGHT", RdysCrateTracker.titlepanel.close, "LEFT", -5, 0)
RdysCrateTracker.titlepanel.minimize:SetScript("OnMouseUp", ToggleRows)
RdysCrateTracker.titlepanel.minimize.text = RdysCrateTracker.titlepanel.minimize:CreateFontString(nil, "OVERLAY", "GameFontNormal")
RdysCrateTracker.titlepanel.minimize.text:SetPoint("CENTER")
RdysCrateTracker.titlepanel.minimize.text:SetText(L["MINIMIZE_BUTTON"] or "+/-")

-- Options button next to minimize
RdysCrateTracker.titlepanel.options = CreateFrame("Frame", nil, RdysCrateTracker.titlepanel, "BackdropTemplate")
RdysCrateTracker.titlepanel.options:SetSize(20, 20)
RdysCrateTracker.titlepanel.options:SetPoint("RIGHT", RdysCrateTracker.titlepanel.minimize, "LEFT", -5, 0)
RdysCrateTracker.titlepanel.options:SetScript("OnMouseUp", function()
    if RdysCrateTracker.titlepanel.isMinimized then ToggleRows() end
    AceConfigDialog:Open("Hated Crate Tracker")
end)
RdysCrateTracker.titlepanel.options.text = RdysCrateTracker.titlepanel.options:CreateFontString(nil, "OVERLAY", "GameFontNormal")
RdysCrateTracker.titlepanel.options.text:SetPoint("CENTER")
RdysCrateTracker.titlepanel.options.text:SetText(L["OPTIONS_BUTTON"] or "Opt")

-- Refresh button next to options
RdysCrateTracker.titlepanel.refresh = CreateFrame("Frame", nil, RdysCrateTracker.titlepanel, "BackdropTemplate")
RdysCrateTracker.titlepanel.refresh:SetSize(15, 15) -- Match size of others
RdysCrateTracker.titlepanel.refresh:SetPoint("RIGHT", RdysCrateTracker.titlepanel.options, "LEFT", -5, 0)
RdysCrateTracker.titlepanel.refresh.tex = RdysCrateTracker.titlepanel.refresh:CreateTexture(nil, "OVERLAY")
RdysCrateTracker.titlepanel.refresh.tex:SetAllPoints()
RdysCrateTracker.titlepanel.refresh.tex:SetTexture("Interface\\Buttons\\UI-RefreshButton")
RdysCrateTracker.titlepanel.refresh:SetScript("OnMouseUp", function()
    local now = GetServerTime()
    if now - lastSyncRequestAt < 3 then
        return
    end
    lastSyncRequestAt = now
    RdysCrateTracker:RequestSync()
    print("|cff33ff99[RCT]|r " .. (L["RDYZ_RESPONSE"] or "Requesting recent timers..."))
end)
-- Added Tooltip logic
RdysCrateTracker.titlepanel.refresh:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    -- Uses your locale for "Request recent crates from others"
    GameTooltip:SetText(L["RDYZ"] or "Request recent crates from others", nil, nil, nil, nil, true)
    GameTooltip:Show()
end)

RdysCrateTracker.titlepanel.refresh:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Shard ID label (Shifted further left to make room for the new button)
RdysCrateTracker.titlepanel.shardLabel = RdysCrateTracker.titlepanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
RdysCrateTracker.titlepanel.shardLabel:SetPoint("RIGHT", RdysCrateTracker.titlepanel.refresh, "LEFT", 0, 0)
RdysCrateTracker.titlepanel.shardLabel:SetTextColor(0, 1, 0, 1)
RdysCrateTracker.titlepanel.shardLabel:SetText(RdysCrateTracker.ShardID or "N/A")
RdysCrateTracker.titlepanel.shardLabel:EnableMouse(true)

RdysCrateTracker.titlepanel.shardLabel:SetScript("OnMouseUp", function(self)
-- Get the accurate, normalized zone for shard display
local rawMapID = C_Map.GetBestMapForUnit("player")

-- PTR/phasing fix: force map system to update if map is nil or 0
if not rawMapID or rawMapID == 0 then
    C_Map.GetPlayerMapPosition(0, "player") -- forces internal refresh
    rawMapID = C_Map.GetBestMapForUnit("player")
end

if not rawMapID or rawMapID == 0 then
    print(L["UNABLE_DETERMINE_MAP"] or "Unable to determine your current map. Cannot share Shard ID.")
    return
end

-- Normalize the zone using your addon logic
local normalizedID = RdysCrateTracker:NormalizeZoneID(rawMapID)

if not normalizedID then
    print("|cffff0000[RCT]|r Unable to normalize this zone (" .. tostring(rawMapID) .. ").")
    return
end

-- Get normalized zone info
local mapInfo = C_Map.GetMapInfo(normalizedID)
local zoneName = mapInfo and mapInfo.name or (L["UNKNOWN_ZONE"] or "Unknown Zone")

-- Build message
local shard = RdysCrateTracker.ShardID or "N/A"
local msg = (L["SHARD_ID_MESSAGE"] or "Shard ID: %s (Zone: %s, Map ID: %s)"):format(shard, zoneName, tostring(normalizedID))
    if IsInRaid() then
        SendChatMessage(msg, "RAID")
    elseif IsInGroup() then
        SendChatMessage(msg, "PARTY")
    else
        print(msg)
    end
end)

RdysCrateTracker.titlepanel.shardLabel:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["CLICK_SHARE_SHARD"] or "Click to share Shard ID", nil, nil, nil, nil, true)
    GameTooltip:Show()
end)

RdysCrateTracker.titlepanel.shardLabel:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)



-- Status indicator "S" for raid leader/assistant
-- Status/Sync/Share labels (Anchored to the left of the Shard label)
RdysCrateTracker.titlepanel.status = RdysCrateTracker.titlepanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
RdysCrateTracker.titlepanel.status:SetPoint("RIGHT", RdysCrateTracker.titlepanel.text, "RIGHT", 35, 0)
RdysCrateTracker.titlepanel.status:SetTextColor(1, 0, 0, .5)
RdysCrateTracker.titlepanel.status:SetText(L["SYNC_BUTTON"] or "Sync")
RdysCrateTracker.titlepanel.status:Hide()
RdysCrateTracker.titlepanel.status:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["CLICK_SYNC_TIMERS"] or "Click to Sync Crate Timers", nil, nil, nil, nil, true)
    GameTooltip:Show()
end)
RdysCrateTracker.titlepanel.status:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
RdysCrateTracker.titlepanel.status:SetScript("OnMouseUp", function()
    RdysCrateTracker:BroadcastSync()
end)

-- Share indicator next to status
RdysCrateTracker.titlepanel.share = RdysCrateTracker.titlepanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
RdysCrateTracker.titlepanel.share:SetPoint("RIGHT", RdysCrateTracker.titlepanel.text, "RIGHT", 35, 0)
RdysCrateTracker.titlepanel.share:SetTextColor(0, 0, 1, 1)
RdysCrateTracker.titlepanel.share:SetText(L["SHARE_BUTTON"] or "Share")
RdysCrateTracker.titlepanel.share:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["CLICK_SHARE_ADDON"] or "Click to Share Addon", nil, nil, nil, nil, true)
    GameTooltip:Show()
end)
RdysCrateTracker.titlepanel.share:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
RdysCrateTracker.titlepanel.share:SetScript("OnMouseUp", function()
    RdysCrateTracker:addonadvertise()
end)

-- standalone frame to toggle the "S" indicator
local statusVisibility = CreateFrame("Frame")
statusVisibility:RegisterEvent("GROUP_ROSTER_UPDATE")
statusVisibility:RegisterEvent("PLAYER_ENTERING_WORLD")
statusVisibility:RegisterEvent("GROUP_JOINED")
statusVisibility:RegisterEvent("GROUP_LEFT")
statusVisibility:SetScript("OnEvent", function()
    if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
        RdysCrateTracker.titlepanel.status:Show()
        RdysCrateTracker.titlepanel.share:Hide()
    else
        RdysCrateTracker.titlepanel.status:Hide()
        RdysCrateTracker.titlepanel.share:Show()
    end
end)



-- Make title panel draggable on its own
RdysCrateTracker.titlepanel:EnableMouse(true)
RdysCrateTracker.titlepanel:SetMovable(true)
RdysCrateTracker.titlepanel:RegisterForDrag("LeftButton")
RdysCrateTracker.titlepanel:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
RdysCrateTracker.titlepanel:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self:SetUserPlaced(true)
    if type(RdysCrateTracker.SaveTitlePanelPosition) == "function" then
        RdysCrateTracker:SaveTitlePanelPosition()
    end
end)