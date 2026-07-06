do -- Encapsulate the entire file to prevent global scope pollution
    local addonName, addonTable = ...
    local RdysCrateTracker = LibStub("AceAddon-3.0"):GetAddon("RdysCrateTracker", true)
    if not RdysCrateTracker then error("RdysCrateTracker not found") end

    -- embed comm & db
    LibStub("AceComm-3.0"):Embed(RdysCrateTracker)
    local db = RdysCrateTracker.db.profile
    db.crateDBSecondary = db.crateDBSecondary or {}
    db.rotationDB       = db.rotationDB       or {}

    -- Layout constants
    local PADDING = 10

-- create panel
local panel = CreateFrame("Frame", "RaidLeaderRotation", RdysCrateTracker.raidleaderpanel, "BackdropTemplate")
panel:SetWidth(RdysCrateTracker.raidleaderpanel:GetWidth())
panel:SetPoint("TOP", RdysCrateTracker.raidleaderpanel, "BOTTOM", 0, -5)
panel:SetBackdrop({
    bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 12,
    insets   = { left = 2, right = 2, top = 2, bottom = 2 },
})

-- toggle show/hide rotation panel
local toggleFrame = CreateFrame("Frame", "ShowHideRotationFrame", RdysCrateTracker.raidleaderpanel)
toggleFrame:SetSize(80, 20)
toggleFrame:SetPoint("TOPRIGHT", RdysCrateTracker.raidleaderpanel, "TOPRIGHT", 0, 0)
toggleFrame:EnableMouse(true)

local toggleText = toggleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
toggleText:SetAllPoints(toggleFrame)
toggleText:SetTextColor(0, 1, 0, 1)
toggleText:SetText("+/- Rotation")

toggleFrame:SetScript("OnMouseUp", function()
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
    end
end)

-- Add to parent's list of leader-only frames to handle visibility automatically
if RdysCrateTracker.raidleaderpanel.leaderOnlyFrames then
    table.insert(RdysCrateTracker.raidleaderpanel.leaderOnlyFrames, toggleFrame)
end

toggleFrame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("Show or Hide Rotation Panel", 1, 1, 1, true)
    GameTooltip:Show()
end)

toggleFrame:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)





local faction = UnitFactionGroup("player")
panel:SetBackdropColor(faction=="Horde" and 1 or 0, 0, faction=="Alliance" and 1 or 0, 1)

-- options & holders
-- Use the centralized config, build the options table
local options = {"None"}
if RdysCrateTracker.Config and RdysCrateTracker.Config.Zones then
    for _, zoneInfo in ipairs(RdysCrateTracker.Config.Zones) do
        table.insert(options, zoneInfo.short)
    end
end
local dropdowns = {}

-- helpers
local function Save()
    if not db.crateDBSecondary then
        db.crateDBSecondary = {}
    end
    for i, dd in ipairs(dropdowns) do
        -- The raw value is already saved in the info.func, this is a fallback
        db.crateDBSecondary["DDRaidleader"..i] = db.crateDBSecondary["DDRaidleader"..i] or "None"
    end
end

-- create dropdowns in 3 columns, max 3 per row
local numDropdowns = (#options - 1) -- Number of zones + "None" option
local columns      = 2 -- Two dropdowns per row
local spacingX     = (panel:GetWidth() - (PADDING * 2)) / columns
local spacingY     = 24 -- Vertical space per row
 
-- Helper to set the display text (e.g., "1. ES")
local function SetDisplay(dropdown, index, value)
    UIDropDownMenu_SetText(dropdown, index .. ". " .. (value or "None"))
end

for i = 1, numDropdowns do
    local col   = (i - 1) % columns
    local row   = math.floor((i - 1) / columns)
    local xOff  = PADDING + col * spacingX
    local yOff  = -PADDING - row * spacingY

    local dd = CreateFrame("Frame", "DDRaidleader"..i, panel, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", panel, "TOPLEFT", xOff, yOff)
    UIDropDownMenu_SetWidth(dd, spacingX / 2)

    -- shrink the selected text
    local txt = _G[dd:GetName() .. "Text"]
    if txt then
        txt:SetFontObject(GameFontHighlightSmall)
    end

    -- initialize dropdown
    UIDropDownMenu_Initialize(dd, function(self)
        for _, opt in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt
            info.func = function()
                -- Save only the raw option
                db.crateDBSecondary["DDRaidleader" .. i] = opt
                SetDisplay(dd, i, opt)
            end
            info.fontObject = GameFontHighlightSmall
            UIDropDownMenu_AddButton(info)
        end
    end)

    dropdowns[i] = dd
end

local function Load()
    for i, dd in ipairs(dropdowns) do
        local savedValue = db.crateDBSecondary["DDRaidleader" .. i] or "None"
        SetDisplay(dd, i, savedValue)
    end
end


-- Create the Send button
local sendBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
sendBtn:SetSize(40, 25)
sendBtn:SetText("Send")

-- Anchor under the last dropdown if it exists
if numDropdowns > 0 then
    sendBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -PADDING, PADDING)
else
    -- fallback: hide button if there are no dropdowns
    sendBtn:Hide()
end

-- Click handler
sendBtn:SetScript("OnClick", function()
    if not RdysCrateTracker:AmIaLeader() then
        print("You are not the group leader.")
        return
    end

    local parts = {}
    for i, dd in ipairs(dropdowns) do
        -- Use raw saved value instead of displayed text
        local raw = db.crateDBSecondary["DDRaidleader"..i]
        if raw and raw ~= "None" then
            parts[#parts + 1] = raw
        end
    end

    local msg = "Rotation is: " .. table.concat(parts, " - ")
    db.rotationDB[1] = msg

    local chan = IsInRaid() and "RAID_WARNING" or "PARTY"
    RdysCrateTracker:SendCommMessage("RDrotation", msg, chan)
    SendChatMessage(msg, chan)
end)

-- Dynamically set panel size based on content
local numRows = math.ceil(numDropdowns / columns)
local dropdownsHeight = numRows > 0 and (numRows * spacingY) or 0
local panelHeight = dropdownsHeight + sendBtn:GetHeight()
panel:SetHeight(panelHeight)

-- visibility & events
local function UpdateSendButton()
    if sendBtn then
        sendBtn:SetEnabled(RdysCrateTracker:AmIaLeader())
    end
end 

panel:RegisterEvent("PLAYER_ENTERING_WORLD")
panel:RegisterEvent("GROUP_ROSTER_UPDATE")
panel:RegisterEvent("PLAYER_LEAVING_WORLD")
panel:RegisterEvent("PLAYER_LOGOUT")

panel:SetScript("OnEvent", function(_, event)
    -- Corrected logic: should run if addon is enabled and not in PvP mode
    if not RdysCrateTracker.db.profile.enable or RdysCrateTracker.db.profile.notPvp then return end
    if event == "PLAYER_ENTERING_WORLD" then
        UpdateSendButton()
        Load()
    elseif event == "GROUP_ROSTER_UPDATE" then
        UpdateSendButton()
    elseif event == "PLAYER_LOGOUT" or event == "PLAYER_LEAVING_WORLD" then
        Save()
    end
end)


C_ChatInfo.RegisterAddonMessagePrefix("RDrotation")
C_ChatInfo.RegisterAddonMessagePrefix("zRdyCrate_status")
C_ChatInfo.RegisterAddonMessagePrefix("zRdyCrate_update")

end