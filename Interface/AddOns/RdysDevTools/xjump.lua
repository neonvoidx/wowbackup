-- ############################################################
-- RdyXJump Integration for RdysCrateTracker
-- Compact 2-column XFrame with list on right
-- ############################################################

local RCT = LibStub("AceAddon-3.0"):GetAddon("RdysCrateTracker", true)
if not RCT then return end

local AceComm = LibStub("AceComm-3.0")
local COMM_PREFIX = "RdyXJump_dnr"

RCT.XJump = {}
local XJump = RCT.XJump

-- State
XJump.reInvite = {}
XJump.WhisperTarget = nil
XJump.XTarget = "RAID"

-- ############################################################
-- Frame Setup
-- ############################################################
RCT.XFrame = CreateFrame("Frame", "RCT_XFrame", RCT.raidleaderpanel, "BasicFrameTemplateWithInset")
local frame = RCT.XFrame
frame:SetSize(500, 420) -- taller so everything fits

-- Load saved position or set default relative to parent
if RCT.db.profile.xjumpFramePoint then
    frame:SetPoint(RCT.db.profile.xjumpFramePoint, RCT.raidleaderpanel, RCT.db.profile.xjumpFrameRelativePoint, RCT.db.profile.xjumpFrameX, RCT.db.profile.xjumpFrameY)
else
    frame:SetPoint("TOP", RCT.raidleaderpanel, "BOTTOM", 0, -10)
end

frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    RCT.db.profile.xjumpFramePoint, _, RCT.db.profile.xjumpFrameRelativePoint, RCT.db.profile.xjumpFrameX, RCT.db.profile.xjumpFrameY = self:GetPoint()
end)
frame:SetFrameLevel(frame:GetParent():GetFrameLevel() + 5)
frame:Hide()

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.title:SetPoint("TOP", 0, -5)
frame.title:SetText("HatedGaming XJump")

local yStart = -40

-- ===================Logo===================
-- Add logo texture in the top right
local logo = frame:CreateTexture(nil, "ARTWORK")
logo:SetSize(120, 120)  -- width, height (adjust as needed)
logo:SetPoint("TOPRIGHT", -10, -10)  -- 10px from top right corner
logo:SetTexture("Interface\\AddOns\\RdysDevTools\\media\\logo.tga")


-- =============== Whisper Target Section =================
local whisperHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
whisperHeader:SetPoint("TOP", 0, yStart)
whisperHeader:SetText("Whisper Target")
yStart = yStart - 25

-- Current Whisper Target label
local whisperLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
whisperLabel:SetPoint("TOP", 0, yStart)
whisperLabel:SetText("Current Whisper Target: None")
frame.whisperLabel = whisperLabel
yStart = yStart - 25

-- Manual entry + Add button
local entryFrame = CreateFrame("Frame", nil, frame)
entryFrame:SetSize(280, 25)
entryFrame:SetPoint("TOP", 0, yStart)

local editBox = CreateFrame("EditBox", nil, entryFrame, "InputBoxTemplate")
editBox:SetSize(200, 25)
editBox:SetPoint("LEFT", 0, 0)
editBox:SetAutoFocus(false)

local function SetWhisperTargetFromBox()
    local val = editBox:GetText()
    if val and val:match("^[%a%-]+%-[%a%-]+$") then
        XJump.WhisperTarget = val
        frame.whisperLabel:SetText("Current Whisper Target: " .. val)
        print("Whisper Target set to:", val)
    else
        print("Invalid format. Use Name-Realm (e.g., Player-Realm).")
    end
    editBox:ClearFocus()
end
editBox:SetScript("OnEnterPressed", SetWhisperTargetFromBox)

local addBtn = CreateFrame("Button", nil, entryFrame, "UIPanelButtonTemplate")
addBtn:SetSize(60, 25)
addBtn:SetPoint("LEFT", editBox, "RIGHT", 5, 0)
addBtn:SetText("Add")
addBtn:SetScript("OnClick", SetWhisperTargetFromBox)

yStart = yStart - 35

-- Add Target + Clear buttons side by side
local addTargetBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
addTargetBtn:SetSize(160, 25)
addTargetBtn:SetPoint("TOPLEFT", 40, yStart)
addTargetBtn:SetText("Add Current Target")
addTargetBtn:SetScript("OnClick", function()
    if UnitExists("target") and UnitIsPlayer("target") then
        local name, realm = UnitName("target")
        if name then
            if realm and realm ~= "" then
                name = name .. "-" .. realm
            else
                name = name .. "-" .. GetRealmName()
            end
            XJump.WhisperTarget = name
            frame.whisperLabel:SetText("Current Whisper Target: " .. name)
            print("Whisper Target set to:", name)
        end
    else
        print("No valid player target selected.")
    end
end)

local clearBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
clearBtn:SetSize(160, 25)
clearBtn:SetPoint("TOPRIGHT", -40, yStart)
clearBtn:SetText("Clear Whisper Target")
clearBtn:SetScript("OnClick", function()
    XJump.WhisperTarget = nil
    frame.whisperLabel:SetText("Current Whisper Target: None")
    print("Whisper target cleared.")
end)
yStart = yStart - 35

-- Dropdown for XTarget

-- Dropdown for XTarget (centered)
local xTargetLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
xTargetLabel:SetPoint("TOP", 0, yStart)
xTargetLabel:SetText("Send Re-Invite List to:")
yStart = yStart - 25

local dropdown = CreateFrame("Frame", "RCT_XTargetDropDown", frame, "UIDropDownMenuTemplate")
dropdown:SetPoint("TOP", 0, yStart)
UIDropDownMenu_SetWidth(dropdown, 150)
UIDropDownMenu_Initialize(dropdown, function(_, level)
    local info = UIDropDownMenu_CreateInfo()
    for _, v in ipairs({ "RAID", "PARTY", "GUILD", "WHISPER" }) do
        info.text = v
        info.func = function()
            XJump.XTarget = v
            UIDropDownMenu_SetText(dropdown, v)
        end
        UIDropDownMenu_AddButton(info, level)
    end
end)
UIDropDownMenu_SetText(dropdown, "WHISPER")
yStart = yStart - 50


-- =============== Left Column: Buttons =================
local leftY = yStart
local function AddLeftButton(text, func)
    local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btn:SetSize(180, 25)
    btn:SetPoint("TOPLEFT", 40, leftY)
    btn:SetText(text)
    btn:SetScript("OnClick", func)
    leftY = leftY - 30
    return btn
end

AddLeftButton("Write Raid to List", function() XJump:WriteRaidToList() end)
AddLeftButton("Reinvite From List", function() XJump:ReinviteFromList() end)
AddLeftButton("Send Re-Invite List", function() XJump:SendReInviteTable() end)
AddLeftButton("Clear Re-Invite List", function() XJump:ClearReInvite() end)
AddLeftButton("Disband & Reinvite", function() XJump:DisbandAndReinvite() end)
AddLeftButton("Disband", function() XJump:Disband() end)

-- =============== Right Column: Re-Invite List =================
local listHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
listHeader:SetPoint("TOPRIGHT", -100, yStart) -- align with buttons
listHeader:SetText("Re-Invite List")

local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPRIGHT", -40, yStart - 25) -- directly under header
scrollFrame:SetPoint("BOTTOMRIGHT", -40, 20)       -- anchored to bottom of frame
scrollFrame:SetWidth(200)

local listBox = CreateFrame("EditBox", nil, scrollFrame)
listBox:SetMultiLine(true)
listBox:SetFontObject(GameFontHighlightSmall)
listBox:SetWidth(180)
listBox:SetAutoFocus(false)
scrollFrame:SetScrollChild(listBox)

frame.reinviteBox = listBox
frame.reinviteBox:SetText("No players in the re-invite list.")

-- ############################################################
-- Re-Invite Logic
-- ############################################################
XJump.reInviteFrame = CreateFrame("Frame")


-- ############################################################
-- Helper: Invite players with throttling + multiple passes
-- ############################################################
local function InviteQueue(names, passes)
    local queue = {}
    for i = 1, passes do
        for _, name in ipairs(names) do
            table.insert(queue, name)
        end
    end

    local i = 1
    local ticker
    ticker = C_Timer.NewTicker(0.7, function()
        if i > #queue then
            ticker:Cancel()
            return
        end
        C_PartyInfo.InviteUnit(queue[i])
        i = i + 1
    end)
end



function XJump:DisbandAndReinvite()
    if not UnitIsGroupLeader("player") then
        print("You must be the raid leader to use this command.")
        return
    end
    if not IsInRaid() then
        print("You must be in a raid group to use this command.")
        return
    end

    -- Store raid members (except self)
    self.reInvite = {}
    for i = 1, GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i)
        if name and name ~= UnitName("player") then
            table.insert(self.reInvite, name)
        end
    end

    -- Disband
    for i = 1, GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i)
        if name and name ~= UnitName("player") then
            UninviteUnit(name)
        end
    end

    -- Delay a couple of seconds before reinviting
    C_Timer.After(2, function()
        if #self.reInvite > 0 then
            InviteQueue(self.reInvite, 2) -- 2 passes, throttled
            print("Re-inviting stored raid members (2 passes, throttled).")
        end
    end)
end


function XJump:Disband()
    if not UnitIsGroupLeader("player") then
        print("You must be the raid leader to use this command.")
        return
    end
    if not IsInRaid() then
        print("You must be in a raid group to use this command.")
        return
    end
    for i = 1, GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i)
        if name and name ~= UnitName("player") then
            UninviteUnit(name)
        end
    end
end

function XJump:ReinviteFromList()
    if not self.reInvite or #self.reInvite == 0 then
        print("No players in the re-invite list.")
        return
    end
    InviteQueue(self.reInvite, 2) -- 2 passes
    print("Re-inviting players (2 passes, throttled).")
end

function XJump:ClearReInvite()
    self.reInvite = {}
    print("Re-invite list cleared.")
    frame.reinviteBox:SetText("No players in the re-invite list.")
end

function XJump:WriteRaidToList()
    self.reInvite = {}
    for i = 1, GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i)
        if name then
            local realm = GetRealmName()
            if not name:find("-") then
                name = name .. "-" .. realm
            end
            table.insert(self.reInvite, name)
        end
    end
    print("Raid members written to re-invite list.")
    frame.reinviteBox:SetText(table.concat(self.reInvite, "\n"))
end

-- ############################################################
-- Communications
-- ############################################################
function XJump:SendReInviteTable()
    if not self.reInvite or #self.reInvite == 0 then
        print("No players to re-invite.")
        return
    end
    local serialized = table.concat(self.reInvite, ",")
    if self.XTarget == "WHISPER" then
        if not self.WhisperTarget then
            print("No whisper target set.")
            return
        end
        RCT:SendCommMessage(COMM_PREFIX, serialized, "WHISPER", self.WhisperTarget)
    else
        RCT:SendCommMessage(COMM_PREFIX, serialized, self.XTarget)
    end
    print("Sent re-invite list via " .. self.XTarget)
end

function XJump:OnCommReceived(prefix, message, dist, sender)
    if prefix ~= COMM_PREFIX then return end
    local names = { strsplit(",", message) }
    if #names > 0 then
        self.reInvite = names
        print("Received re-invite list from:", sender)
        frame.reinviteBox:SetText(table.concat(self.reInvite, "\n"))
    end
end

RCT:RegisterComm(COMM_PREFIX, function(...) XJump:OnCommReceived(...) end)

-- ############################################################
-- Slash Command: /xjump
-- ############################################################
SLASH_XJUMP1 = "/xjump"
SlashCmdList["XJUMP"] = function()
    if RCT.XFrame:IsShown() then
        RCT.XFrame:Hide()
    else
        RCT.XFrame:Show()
        RCT.XFrame:Raise() -- bring it to top if other frames overlap
    end
end