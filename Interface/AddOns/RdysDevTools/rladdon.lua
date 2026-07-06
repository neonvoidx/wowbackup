
local addonName, addonTable = ...

-- Use Ace3 and database from the attached file
local RdysCrateTracker = LibStub("AceAddon-3.0"):GetAddon("RdysCrateTracker", true)
if not RdysCrateTracker then
    error("RdysCrateTracker addon not found. Please ensure it is loaded.")
end

local db = RdysCrateTracker.db.profile
local FONT_PATH = "Interface\\AddOns\\RCT\\fonts\\Accidental Presidency.ttf"

-- Helper to safely set a font, falling back to a default if the custom one fails.
local function SafeSetFont(fontString, size, style)
    local success, _ = pcall(fontString.SetFont, fontString, FONT_PATH, size, style)
    if not success then
        fontString:SetFont("Fonts\\FRIZQT__.TTF", size, style) -- Fallback to a standard game font
    end
end

--- =================== Raid Leader Stuff

-- Raid leader panel attached above titlepanel
RdysCrateTracker.raidleaderpanel = CreateFrame("Frame", "RdysCrateTrackerRaidLeaderPanel", UIParent, "BackdropTemplate")
RdysCrateTracker.raidleaderpanel:SetSize(
    (RdysCrateTracker.titlepanel and RdysCrateTracker.titlepanel:GetWidth() or 300),
    75
)
RdysCrateTracker.raidleaderpanel:SetBackdrop({
    bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 12,
    insets   = { left = 2, right = 2, top = 2, bottom = 2 },
})
RdysCrateTracker.raidleaderpanel:SetBackdropColor(0, 0, 0, 0.8)
RdysCrateTracker.raidleaderpanel:SetFrameStrata("HIGH")
-- Create logo texture instead of text
RdysCrateTracker.raidleaderpanel.logo = RdysCrateTracker.raidleaderpanel:CreateTexture(nil, "OVERLAY")
RdysCrateTracker.raidleaderpanel.logo:SetSize(120, 120)
RdysCrateTracker.raidleaderpanel.logo:SetPoint("BOTTOM", RdysCrateTracker.raidleaderpanel, "TOP", 0, -44)
RdysCrateTracker.raidleaderpanel.logo:SetTexture("Interface\\AddOns\\RdysDevTools\\media\\logoR.png")


-- Anchor to the parent titlepanel
RdysCrateTracker.raidleaderpanel:SetPoint("BOTTOM", RdysCrateTracker.titlepanel, "TOP", 0, 96)
RdysCrateTracker.raidleaderpanel:EnableMouse(true)
RdysCrateTracker.raidleaderpanel:SetMovable(true)
RdysCrateTracker.raidleaderpanel:RegisterForDrag("LeftButton")
RdysCrateTracker.raidleaderpanel:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
RdysCrateTracker.raidleaderpanel:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

-- Helper to create a standard button with a backdrop
local function CreateButton(parent, name, width, height, text, font)
    local btn = CreateFrame("Button", name, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    btn:SetBackdropColor(0, 0, 0, 0.8)
    btn.text = btn:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    return btn
end

-- Button to open the XFrame
local openXFrame = CreateButton(RdysCrateTracker.raidleaderpanel, "RdysCrateTrackerOpenXFrame", 80, 20, "Open XJump")
openXFrame:SetPoint("TOPLEFT", 5, -5)

openXFrame:SetScript("OnClick", function(self)
    if RdysCrateTracker.XFrame then
        RdysCrateTracker.XFrame:Show()
    end
end)
openXFrame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Click to open XJump", 1, 1, 1, 1, true)
    GameTooltip:Show()
end)
openXFrame:SetScript("OnLeave", GameTooltip_Hide)




-- Raid leader quick-select buttons
local function RLNextFrame(parent, text, xOffset, name)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    frame:SetSize((parent:GetWidth() - 20) / 6, 20)
    frame:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", xOffset, 5)
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.text:SetTextColor(1, 1, 1, 1)
    frame.text:SetPoint("CENTER", frame, "CENTER")
    frame.text:SetText(text)

    frame:EnableMouse(true)
    frame:SetScript("OnMouseUp", function()
        if (IsInRaid() or IsInGroup()) and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
            SendChatMessage("You want to be in: " .. text, "RAID_WARNING")
        else
            print("You must be the raid leader or party leader to use this frame.")
        end
    end)

    return frame
end

RdysCrateTracker.Config = RdysCrateTracker.Config or {}
RdysCrateTracker.Config.Zones = {
    { short = "ES", long = "Eversong Woods" },
    { short = "ZA", long = "Zul'Aman" },
    { short = "HD", long = "Harandar" },
    { short = "VS", long = "VoidStorm" },
    { short = "SR", long = "Slayers Rise" },
}

local zones = RdysCrateTracker.Config.Zones
local columns = #zones
local spacing = 5
local frameWidth = (RdysCrateTracker.raidleaderpanel:GetWidth() - (spacing * (columns + 1))) / columns

local function AddTooltip(frame, text)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", GameTooltip_Hide)
end
-- Data-driven quick-select buttons
for i, zoneInfo in ipairs(zones) do
    local xOffset = spacing + ((i - 1) * (frameWidth + spacing))
    local frame = RLNextFrame(RdysCrateTracker.raidleaderpanel, zoneInfo.short, xOffset, "RLFrame_Zone_"..zoneInfo.short)
    if frame then -- Check if RLNextFrame returned a valid frame
        AddTooltip(frame, "Announce next in: " .. zoneInfo.long)
    end
end

---------------------------- CLear and Sync ---------------------------------------

-- Add a “Clear n' Sync Raid” button to the raidleaderpanel
local clearSyncRaid = CreateFrame("Button", nil, RdysCrateTracker.raidleaderpanel)
clearSyncRaid:SetSize(100, 20)
clearSyncRaid:SetPoint("TOPLEFT", 5, -30)

clearSyncRaid.text = clearSyncRaid:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
SafeSetFont(clearSyncRaid.text, 16, "OUTLINE")
clearSyncRaid.text:SetPoint("LEFT")
clearSyncRaid.text:SetText("Clear n' Sync")

clearSyncRaid:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Clear all raid data and Sync your data to raid", nil, nil, nil, nil, true)
    GameTooltip:Show()
end)
clearSyncRaid:SetScript("OnLeave", GameTooltip_Hide)
clearSyncRaid:SetScript("OnClick", function()
    if UnitIsGroupLeader("player") then
        RdysCrateTracker:sendAndDeleteCrate()
        C_Timer.After(1, function()
            RdysCrateTracker:BroadcastSync()
        end)
    else
        print("You must be raid or party leader/assist to sync.")
    end
end)

-- HGLog button
local hglogBtn = CreateFrame("Button", nil, RdysCrateTracker.raidleaderpanel)
hglogBtn:SetSize(60, 20)
hglogBtn:SetPoint("TOP", 0, -30)

hglogBtn.text = hglogBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
SafeSetFont(hglogBtn.text, 16, "OUTLINE")
hglogBtn.text:SetPoint("CENTER")
hglogBtn.text:SetText("HGLog")

hglogBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Open HGLog", nil, nil, nil, nil, true)
    GameTooltip:Show()
end)
hglogBtn:SetScript("OnLeave", GameTooltip_Hide)
hglogBtn:SetScript("OnClick", function()
    -- Get the HGLog addon instance and call its ToggleWindow function
    local HGLog = LibStub("AceAddon-3.0"):GetAddon("HGLog", true)
    if HGLog and type(HGLog.ToggleWindow) == "function" then
        HGLog:ToggleWindow()
    end
end)

local rlsyncpanel = CreateFrame("Button", nil, RdysCrateTracker.raidleaderpanel)
rlsyncpanel:SetSize(40, 20)
rlsyncpanel:SetPoint("TOPRIGHT", -5, -30)

rlsyncpanel.text = rlsyncpanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
SafeSetFont(rlsyncpanel.text, 16, "OUTLINE")
rlsyncpanel.text:SetPoint("RIGHT")
rlsyncpanel.text:SetText("Sync")

rlsyncpanel:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Sync your data to raid", nil, nil, nil, nil, true)
    GameTooltip:Show()
end)
rlsyncpanel:SetScript("OnLeave", GameTooltip_Hide)
rlsyncpanel:SetScript("OnClick", function()
    if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
        RdysCrateTracker:BroadcastSync()
    else
        print("You must be raid leader or assistant to sync.")
    end
end)

-- Store child frames that should only be visible for leaders
RdysCrateTracker.raidleaderpanel.leaderOnlyFrames = {
    clearSyncRaid,
    rlsyncpanel,
    hglogBtn,
    openXFrame,
    -- The rotation toggle is added in rlrot.lua
}

-- Expose for rlrot.lua
RdysCrateTracker.rlsyncpanel = rlsyncpanel

-- This function will be the single source of truth for the raid leader panel's visibility
local function UpdateLeaderPanelVisibility()
    -- Determine if the panel should be visible based on all conditions
    local shouldShow = RdysCrateTracker.db.profile.enable and
                       not RdysCrateTracker.db.profile.notPvp and
                       RdysCrateTracker.titlepanel:IsShown() and
                       RdysCrateTracker:AmIaLeader()

    RdysCrateTracker.raidleaderpanel:SetShown(shouldShow)
end

-- The Dev functions are called when the main panel is toggled. We can just re-evaluate visibility.
RdysCrateTracker.ShowAllFramesDev = UpdateLeaderPanelVisibility
RdysCrateTracker.HideAllFramesDev = UpdateLeaderPanelVisibility

RdysCrateTracker.raidleaderpanel:RegisterEvent("PLAYER_ENTERING_WORLD")
RdysCrateTracker.raidleaderpanel:RegisterEvent("GROUP_ROSTER_UPDATE")
RdysCrateTracker.raidleaderpanel:RegisterEvent("PLAYER_REGEN_ENABLED") -- Fires after combat
RdysCrateTracker.raidleaderpanel:SetScript("OnEvent", function(_, event)
    UpdateLeaderPanelVisibility()
end)

-- Run an initial check when the addon loads
UpdateLeaderPanelVisibility()
