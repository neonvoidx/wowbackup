-- slaughterhouse.lua: WarGames+ Slaughterhouse
-- Pre-match ritual: randomizes a turn order across two groups (any fixed-team
-- bracket) and has each player publicly declare which character they're
-- bringing, one at a time, in that order.
-- Load order: core.lua -> tracker.lua -> advanced.lua -> comm.lua -> veto.lua -> slaughterhouse.lua

local WG = _G["WargamesPlus"]
if not WG then return end
local L = WG.L

local ADDON_FONT = WG.ADDON_FONT or "Fonts\\FRIZQT__.TTF"

-- ---------- STATE ----------
WG.shState = nil    -- nil | "invited" | "active" | "resolved"
WG.shSession = nil  -- session data table

-- ---------- HELPERS ----------

-- Fixed-team brackets only (2v2/3v3/5v5) — Solo Shuffle/BG/Blitz have bracket==0
-- and no fixed 2-team structure, so they're not eligible for a draft.
local function GetEligibleBrackets()
    local list = {}
    for _, gm in pairs(WG.GAME_MODES or {}) do
        if gm.bracket and gm.bracket > 0 then
            local dup = false
            for _, e in ipairs(list) do
                if e.bracket == gm.bracket then dup = true; break end
            end
            if not dup then
                table.insert(list, {bracket = gm.bracket, label = gm.label})
            end
        end
    end
    table.sort(list, function(a, b) return a.bracket < b.bracket end)
    return list
end

-- Enumerates the player's own home-party members by name. Nothing like this
-- exists elsewhere in the addon (veto/comm only ever address a single named
-- opponent and blind-broadcast to "whoever's on party channel").
local function GetHomeGroupRoster()
    local roster = { (UnitName("player")) }
    if IsInGroup(LE_PARTY_CATEGORY_HOME) and not IsInRaid() then
        local n = GetNumGroupMembers()
        for i = 1, n do
            local unit = "party" .. i
            if UnitExists(unit) then
                local name = UnitName(unit)
                if name then table.insert(roster, name) end
            end
        end
    end
    return roster
end
WG.SH_GetHomeGroupRoster = GetHomeGroupRoster

local function ShuffleOrder(names)
    local order = {}
    for i, n in ipairs(names) do order[i] = n end
    for i = #order, 2, -1 do
        local j = math.random(1, i)
        order[i], order[j] = order[j], order[i]
    end
    return order
end

local function AllNames(s)
    local list = {}
    for _, n in ipairs(s.groupA or {}) do table.insert(list, n) end
    for _, n in ipairs(s.groupB or {}) do table.insert(list, n) end
    return list
end

local function OtherNames(s)
    local me = UnitName("player")
    local list = {}
    for _, n in ipairs(AllNames(s)) do
        if n ~= me then table.insert(list, n) end
    end
    return list
end

local function FanOut(s, msgType, ...)
    for _, name in ipairs(OtherNames(s)) do
        WG.SendV2(msgType, name, ...)
    end
end

local function GroupOf(s, name)
    for _, n in ipairs(s.groupA or {}) do if n == name then return "A" end end
    for _, n in ipairs(s.groupB or {}) do if n == name then return "B" end end
    return "?"
end

local function CurrentPlayerName()
    local s = WG.shSession
    if not s or not s.turnOrder then return nil end
    return s.turnOrder[s.currentTurn]
end

local function IsMyTurn()
    local s = WG.shSession
    if not s or WG.shState ~= "active" or not s.turnOrder then return false end
    if s._testMode then return true end
    return s.turnOrder[s.currentTurn] == (UnitName("player"))
end

local function OrderPayloadArgs(s)
    local args = { tostring(s.bracket) }
    for _, n in ipairs(s.groupA) do table.insert(args, n) end
    for _, n in ipairs(s.groupB) do table.insert(args, n) end
    for _, n in ipairs(s.turnOrder) do table.insert(args, n) end
    return args
end

-- ---------- FRAME ----------
local shFrame
local slotRows = {}
local MAX_SLOTS = 10
local SLOT_H = 20

-- ---------- TIMER SYSTEM ----------
local timerTicker
local function StartTurnTimer()
    local s = WG.shSession
    if not s then return end
    local duration = WG_History.slaughterTurnTimer or 30
    if duration <= 0 then return end

    s.turnTimer = duration
    s.turnExpires = GetTime() + duration

    if timerTicker then timerTicker:Cancel() end
    timerTicker = C_Timer.NewTicker(0.1, function()
        if WG.shState ~= "active" then
            timerTicker:Cancel()
            timerTicker = nil
            return
        end
        local remaining = s.turnExpires - GetTime()
        if remaining <= 0 then
            timerTicker:Cancel()
            timerTicker = nil
            if IsMyTurn() then
                WG.SlaughterHouseDeclare(nil)
            end
            return
        end
        if shFrame and shFrame.timerBar:IsShown() then
            shFrame.timerBar:SetValue(remaining / s.turnTimer)
        end
    end)
end

local function StopTurnTimer()
    if timerTicker then timerTicker:Cancel(); timerTicker = nil end
    local s = WG.shSession
    if s then s.turnTimer = nil; s.turnExpires = nil end
end

-- ---------- RESOLVE ----------
local function ResolveSlaughterHouse()
    local s = WG.shSession
    if not s then return end

    WG.shState = "resolved"
    StopTurnTimer()

    local history = WG_History.slaughterHistory or {}
    table.insert(history, 1, {
        timestamp = time(),
        bracket = s.bracket,
        turnOrder = s.turnOrder,
        declarations = s.declarations,
    })
    while #history > 20 do table.remove(history) end
    WG_History.slaughterHistory = history

    WG.RefreshSlaughterHouseUI()
end

-- ---------- DECLARE (local action) ----------
function WG.SlaughterHouseDeclare(toonName)
    local s = WG.shSession
    if not s or WG.shState ~= "active" or not s.turnOrder then return end
    if not IsMyTurn() then return end

    local actor = s._testMode and CurrentPlayerName() or (UnitName("player"))
    if not actor then return end

    toonName = (toonName or ""):trim()
    if toonName == "" then toonName = actor end

    StopTurnTimer()
    local turnIdx = s.currentTurn
    s.declarations[actor] = toonName
    s.currentTurn = s.currentTurn + 1

    if not s._testMode then
        FanOut(s, "SH_DECLARE", tostring(turnIdx), actor, toonName)
    end

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["SLAUGHTER_DECLARED"], actor, toonName))

    if s.currentTurn > #s.turnOrder then
        ResolveSlaughterHouse()
    else
        StartTurnTimer()
        WG.RefreshSlaughterHouseUI()
    end
end

-- ---------- COMM HANDLERS ----------
function WG.SlaughterHouseOnInvite(sender, rest)
    local parts = {}
    for part in rest:gmatch("[^\t]+") do table.insert(parts, part) end
    if #parts < 2 then return end

    local bracket = tonumber(parts[1])
    if not bracket or bracket <= 0 then return end

    local groupA = {}
    for i = 2, #parts do table.insert(groupA, parts[i]) end
    if #groupA ~= bracket then return end

    WG.addonUsers[sender] = time()

    local myRoster = GetHomeGroupRoster()
    if #myRoster ~= bracket then
        WG.SendV2("SH_DECLINE", sender, string.format(L["SLAUGHTER_GROUP_SIZE_MISMATCH"], bracket, #myRoster))
        local t = WG.GetActiveTheme()
        print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["SLAUGHTER_GROUP_SIZE_MISMATCH"], bracket, #myRoster))
        return
    end

    WG.shState = "active" -- auto-accept, mirrors veto.lua's invite handling
    WG.shSession = {
        bracket = bracket,
        isHost = false,
        myGroup = "B",
        groupA = groupA,
        groupB = myRoster,
        turnOrder = nil,
        currentTurn = 1,
        declarations = {},
        opponentContact = sender,
    }

    WG.SendV2("SH_ACCEPT", sender, unpack(myRoster))

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["SLAUGHTER_INVITE_RECEIVED"], sender))

    WG.ShowSlaughterHouseFrame()
end

function WG.SlaughterHouseOnAccept(sender, rest)
    local s = WG.shSession
    if not s or s.opponentContact ~= sender then return end
    if WG.shState ~= "invited" then return end

    local groupB = {}
    for part in rest:gmatch("[^\t]+") do table.insert(groupB, part) end
    if #groupB ~= s.bracket then return end

    WG.addonUsers[sender] = time()
    s.groupB = groupB
    WG.shState = "active"
    s.turnOrder = ShuffleOrder(AllNames(s))

    FanOut(s, "SH_ORDER", unpack(OrderPayloadArgs(s)))

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["SLAUGHTER_ACCEPTED"], sender))

    StartTurnTimer()
    WG.RefreshSlaughterHouseUI()
end

function WG.SlaughterHouseOnDecline(sender, rest)
    local s = WG.shSession
    if not s or s.opponentContact ~= sender then return end

    WG.shState = nil
    WG.shSession = nil
    StopTurnTimer()

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["SLAUGHTER_DECLINED"], sender, rest or ""))
    if shFrame then shFrame:Hide() end
end

function WG.SlaughterHouseOnOrder(sender, rest)
    local parts = {}
    for part in rest:gmatch("[^\t]+") do table.insert(parts, part) end
    if #parts < 1 then return end

    local bracket = tonumber(parts[1])
    if not bracket or bracket <= 0 then return end
    if #parts < 1 + bracket * 4 then return end

    local groupA, groupB, turnOrder = {}, {}, {}
    local idx = 2
    for i = 1, bracket do groupA[i] = parts[idx]; idx = idx + 1 end
    for i = 1, bracket do groupB[i] = parts[idx]; idx = idx + 1 end
    for i = 1, bracket * 2 do turnOrder[i] = parts[idx]; idx = idx + 1 end

    local me = UnitName("player")
    local myGroup
    for _, n in ipairs(groupA) do if n == me then myGroup = "A" end end
    for _, n in ipairs(groupB) do if n == me then myGroup = "B" end end
    if not myGroup then return end -- not actually a participant in this session

    WG.addonUsers[sender] = time()

    local existing = WG.shSession
    WG.shState = "active"
    WG.shSession = {
        bracket = bracket,
        isHost = existing and existing.isHost or false,
        myGroup = myGroup,
        groupA = groupA,
        groupB = groupB,
        turnOrder = turnOrder,
        currentTurn = (existing and existing.currentTurn) or 1,
        declarations = (existing and existing.declarations) or {},
        opponentContact = sender,
    }

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["SLAUGHTER_ORDER_RECEIVED"])

    WG.ShowSlaughterHouseFrame()
    if IsMyTurn() then StartTurnTimer() end
    WG.RefreshSlaughterHouseUI()
end

function WG.SlaughterHouseOnDeclare(sender, rest)
    local s = WG.shSession
    if not s or WG.shState ~= "active" or not s.turnOrder then return end

    local parts = {}
    for part in rest:gmatch("[^\t]+") do table.insert(parts, part) end
    if #parts < 3 then return end

    local turnIdx = tonumber(parts[1])
    local playerName, toonName = parts[2], parts[3]

    if turnIdx ~= s.currentTurn then return end
    if s.turnOrder[s.currentTurn] ~= playerName then return end
    if playerName ~= sender then return end -- only the declaring player may announce their own slot
    if s.declarations[playerName] then return end

    StopTurnTimer()
    s.declarations[playerName] = toonName
    s.currentTurn = s.currentTurn + 1

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["SLAUGHTER_DECLARED"], playerName, toonName))

    if s.currentTurn > #s.turnOrder then
        ResolveSlaughterHouse()
    else
        StartTurnTimer()
        WG.RefreshSlaughterHouseUI()
    end
end

function WG.SlaughterHouseOnCancel(sender)
    local s = WG.shSession
    if not s then return end

    local known = (s.opponentContact == sender)
    if not known then
        for _, n in ipairs(AllNames(s)) do
            if n == sender then known = true; break end
        end
    end
    if not known then return end

    WG.shState = nil
    WG.shSession = nil
    StopTurnTimer()

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["SLAUGHTER_CANCELLED"])
    if shFrame then shFrame:Hide() end
end

-- ---------- PUBLIC: START / CANCEL ----------
function WG.StartSlaughterHouse(opponentContact, bracket)
    if not opponentContact or opponentContact == "" then return end
    if not WG.addonUsers[opponentContact] or (time() - WG.addonUsers[opponentContact]) > 3600 then
        local t = WG.GetActiveTheme()
        print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["SLAUGHTER_NO_ADDON"])
        return
    end

    local myRoster = GetHomeGroupRoster()
    if #myRoster ~= bracket then
        local t = WG.GetActiveTheme()
        print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["SLAUGHTER_GROUP_SIZE_MISMATCH"], bracket, #myRoster))
        return
    end

    WG.shState = "invited"
    WG.shSession = {
        bracket = bracket,
        isHost = true,
        myGroup = "A",
        groupA = myRoster,
        groupB = nil,
        turnOrder = nil,
        currentTurn = 1,
        declarations = {},
        opponentContact = opponentContact,
    }

    WG.SendV2("SH_INVITE", opponentContact, tostring(bracket), unpack(myRoster))

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["SLAUGHTER_INVITE_SENT"], opponentContact))

    WG.ShowSlaughterHouseFrame()

    C_Timer.After(60, function()
        if WG.shState == "invited" and WG.shSession and WG.shSession.opponentContact == opponentContact then
            WG.shState = nil
            WG.shSession = nil
            print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["SLAUGHTER_TIMEOUT"])
            if shFrame then shFrame:Hide() end
        end
    end)
end

function WG.CancelSlaughterHouse()
    local s = WG.shSession
    if not s then return end

    if WG.shState == "invited" and s.opponentContact then
        WG.SendV2("SH_CANCEL", s.opponentContact)
    else
        for _, n in ipairs(OtherNames(s)) do
            WG.SendV2("SH_CANCEL", n)
        end
    end

    WG.shState = nil
    WG.shSession = nil
    StopTurnTimer()

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["SLAUGHTER_CANCELLED"])
    if shFrame then shFrame:Hide() end
end

-- ---------- CREATE FRAME ----------
local function CreateSlaughterHouseFrame()
    if shFrame then return shFrame end

    local f = CreateFrame("Frame", "WG_SlaughterHouseFrame", UIParent, "BackdropTemplate")
    f:SetSize(420, 560)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    WG.ApplyModernStyle(f)
    if WG.ApplyUIScale then WG.ApplyUIScale(f) end

    local theme = WG.GetActiveTheme()

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -8, -8)
    closeBtn.label = closeBtn:CreateFontString(nil, "OVERLAY")
    closeBtn.label:SetFont(ADDON_FONT, 14, "OUTLINE")
    closeBtn.label:SetPoint("CENTER", 0, 0)
    closeBtn.label:SetText("X")
    closeBtn.label:SetTextColor(unpack(theme.closeNormal))
    closeBtn:SetScript("OnClick", function()
        if WG.shSession then WG.CancelSlaughterHouse() else f:Hide() end
    end)
    closeBtn:HookScript("OnEnter", function()
        closeBtn.label:SetTextColor(unpack(WG.GetActiveTheme().closeHover))
    end)
    closeBtn:HookScript("OnLeave", function()
        closeBtn.label:SetTextColor(unpack(WG.GetActiveTheme().closeNormal))
    end)
    WG.RegisterThemedElement(closeBtn, function(c)
        c.label:SetTextColor(unpack(WG.GetActiveTheme().closeNormal))
    end)

    -- Title
    f.titleText = f:CreateFontString(nil, "OVERLAY")
    f.titleText:SetFont(ADDON_FONT, 14, "OUTLINE")
    f.titleText:SetPoint("TOPLEFT", 12, -12)
    f.titleText:SetPoint("RIGHT", closeBtn, "LEFT", -5, 0)
    f.titleText:SetJustifyH("LEFT")
    f.titleText:SetText(L["SLAUGHTER_TITLE"])
    f.titleText:SetTextColor(unpack(theme.headerColor))
    WG.RegisterThemedElement(f.titleText, function(fs)
        fs:SetTextColor(unpack(WG.GetActiveTheme().headerColor))
    end)

    -- Status text
    f.statusText = f:CreateFontString(nil, "OVERLAY")
    f.statusText:SetFont(ADDON_FONT, 12, "OUTLINE")
    f.statusText:SetPoint("TOPLEFT", 12, -34)
    f.statusText:SetPoint("RIGHT", -12, 0)
    f.statusText:SetJustifyH("LEFT")
    f.statusText:SetTextColor(unpack(theme.normalText))

    -- Progress text
    f.progressText = f:CreateFontString(nil, "OVERLAY")
    f.progressText:SetFont(ADDON_FONT, 10)
    f.progressText:SetPoint("TOPRIGHT", -30, -34)
    f.progressText:SetJustifyH("RIGHT")
    f.progressText:SetTextColor(unpack(theme.footerColor))
    WG.RegisterThemedElement(f.progressText, function(fs)
        fs:SetTextColor(unpack(WG.GetActiveTheme().footerColor))
    end)

    -- Timer bar
    f.timerBar = CreateFrame("StatusBar", nil, f)
    f.timerBar:SetSize(396, 6)
    f.timerBar:SetPoint("TOPLEFT", 12, -52)
    f.timerBar:SetMinMaxValues(0, 1)
    f.timerBar:SetValue(1)
    f.timerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    f.timerBar:SetStatusBarColor(unpack(theme.accent))
    f.timerBar:Hide()
    local timerBg = f.timerBar:CreateTexture(nil, "BACKGROUND")
    timerBg:SetAllPoints()
    timerBg:SetColorTexture(0, 0, 0, 0.5)
    WG.RegisterThemedElement(f.timerBar, function(bar)
        bar:SetStatusBarColor(unpack(WG.GetActiveTheme().accent))
    end)

    -- ===== Pre-invite setup panel =====
    local setup = CreateFrame("Frame", nil, f)
    setup:SetPoint("TOPLEFT", 12, -64)
    setup:SetPoint("RIGHT", -12, 0)
    setup:SetHeight(220)
    f.setupPanel = setup

    local formatLabel = setup:CreateFontString(nil, "OVERLAY")
    formatLabel:SetFont(ADDON_FONT, 11)
    formatLabel:SetPoint("TOPLEFT", 0, 0)
    formatLabel:SetText(L["SLAUGHTER_FORMAT_LABEL"])
    formatLabel:SetTextColor(unpack(theme.footerColor))
    WG.RegisterThemedElement(formatLabel, function(fs)
        fs:SetTextColor(unpack(WG.GetActiveTheme().footerColor))
    end)

    local eligible = GetEligibleBrackets()
    local selectedBracket = eligible[1] and eligible[1].bracket or 2

    local formatDrop = CreateFrame("Frame", "WG_SlaughterFormatDropdown", setup, "UIDropDownMenuTemplate")
    formatDrop:SetPoint("TOPLEFT", -16, -14)
    UIDropDownMenu_SetWidth(formatDrop, 140)
    local function RefreshFormatDropdownText()
        for _, e in ipairs(eligible) do
            if e.bracket == selectedBracket then
                UIDropDownMenu_SetText(formatDrop, e.label)
            end
        end
    end
    UIDropDownMenu_Initialize(formatDrop, function(self, level)
        for _, e in ipairs(eligible) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = e.label
            info.func = function()
                selectedBracket = e.bracket
                RefreshFormatDropdownText()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    RefreshFormatDropdownText()
    WG.StyleDropdown(formatDrop)
    f.formatDrop = formatDrop

    local rosterLabel = setup:CreateFontString(nil, "OVERLAY")
    rosterLabel:SetFont(ADDON_FONT, 11)
    rosterLabel:SetPoint("TOPLEFT", 0, -46)
    rosterLabel:SetText(L["SLAUGHTER_MY_GROUP_LABEL"])
    rosterLabel:SetTextColor(unpack(theme.footerColor))
    WG.RegisterThemedElement(rosterLabel, function(fs)
        fs:SetTextColor(unpack(WG.GetActiveTheme().footerColor))
    end)

    local rosterText = setup:CreateFontString(nil, "OVERLAY")
    rosterText:SetFont(ADDON_FONT, 11)
    rosterText:SetPoint("TOPLEFT", 0, -62)
    rosterText:SetPoint("RIGHT", 0, 0)
    rosterText:SetJustifyH("LEFT")
    rosterText:SetTextColor(unpack(theme.normalText))
    WG.RegisterThemedElement(rosterText, function(fs)
        fs:SetTextColor(unpack(WG.GetActiveTheme().normalText))
    end)
    f.rosterText = rosterText

    local contactLabel = setup:CreateFontString(nil, "OVERLAY")
    contactLabel:SetFont(ADDON_FONT, 11)
    contactLabel:SetPoint("TOPLEFT", 0, -96)
    contactLabel:SetText(L["SLAUGHTER_CONTACT_LABEL"])
    contactLabel:SetTextColor(unpack(theme.footerColor))
    WG.RegisterThemedElement(contactLabel, function(fs)
        fs:SetTextColor(unpack(WG.GetActiveTheme().footerColor))
    end)

    local contactInput = CreateFrame("EditBox", nil, setup, "InputBoxTemplate")
    contactInput:SetSize(280, 22)
    contactInput:SetPoint("TOPLEFT", 4, -112)
    contactInput:SetAutoFocus(false)
    WG.StyleInput(contactInput)
    f.contactInput = contactInput

    local startBtn = CreateFrame("Button", nil, setup, "UIPanelButtonTemplate")
    startBtn:SetSize(200, 30)
    startBtn:SetPoint("TOPLEFT", 0, -146)
    startBtn:SetText(L["SLAUGHTER_START"])
    WG.StyleButton(startBtn)
    startBtn:SetScript("OnClick", function()
        local contact = (contactInput:GetText() or ""):trim()
        WG.StartSlaughterHouse(contact, selectedBracket)
    end)
    f.startBtn = startBtn

    -- ===== Draft slot list =====
    local listFrame = CreateFrame("Frame", nil, f)
    listFrame:SetPoint("TOPLEFT", 12, -64)
    listFrame:SetPoint("RIGHT", -12, 0)
    listFrame:SetHeight(SLOT_H * MAX_SLOTS)
    listFrame:Hide()
    f.listFrame = listFrame

    for i = 1, MAX_SLOTS do
        local row = CreateFrame("Frame", nil, listFrame)
        row:SetSize(396, SLOT_H)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * SLOT_H)
        row.text = row:CreateFontString(nil, "OVERLAY")
        row.text:SetFont(ADDON_FONT, 11)
        row.text:SetPoint("LEFT", 4, 0)
        row.text:SetPoint("RIGHT", -4, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetTextColor(unpack(theme.normalText))
        row:Hide()
        slotRows[i] = row
    end

    -- Declare input + button (shown only on your turn)
    local declareInput = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    declareInput:SetSize(250, 24)
    declareInput:SetPoint("BOTTOMLEFT", 16, 48)
    declareInput:SetAutoFocus(false)
    WG.StyleInput(declareInput)
    f.declareInput = declareInput

    local declareBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    declareBtn:SetSize(110, 24)
    declareBtn:SetPoint("LEFT", declareInput, "RIGHT", 8, 0)
    declareBtn:SetText(L["SLAUGHTER_DECLARE_BTN"])
    WG.StyleButton(declareBtn)
    local function SubmitDeclare()
        local text = declareInput:GetText()
        WG.SlaughterHouseDeclare(text)
        declareInput:SetText("")
    end
    declareBtn:SetScript("OnClick", SubmitDeclare)
    declareInput:SetScript("OnEnterPressed", SubmitDeclare)
    f.declareBtn = declareBtn

    -- Resolved footer: post-to-chat + done
    local postBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    postBtn:SetSize(160, 26)
    postBtn:SetPoint("BOTTOM", -85, 12)
    postBtn:SetText(L["SLAUGHTER_POST_CHAT"])
    WG.StyleButton(postBtn)
    postBtn:SetScript("OnClick", function()
        local s = WG.shSession
        if not s or WG.shState ~= "resolved" or not s.turnOrder then return end
        if not IsInGroup(LE_PARTY_CATEGORY_HOME) then return end
        SendChatMessage(L["SLAUGHTER_TITLE"] .. ":", "PARTY")
        for i, name in ipairs(s.turnOrder) do
            SendChatMessage(i .. ". " .. name .. " - " .. (s.declarations[name] or "?"), "PARTY")
        end
    end)
    f.postBtn = postBtn
    postBtn:Hide()

    local doneBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    doneBtn:SetSize(100, 26)
    doneBtn:SetPoint("LEFT", postBtn, "RIGHT", 10, 0)
    doneBtn:SetText(CLOSE or "Close")
    WG.StyleButton(doneBtn)
    doneBtn:SetScript("OnClick", function()
        WG.shState = nil
        WG.shSession = nil
        StopTurnTimer()
        f:Hide()
    end)
    f.doneBtn = doneBtn
    doneBtn:Hide()

    f:Hide()
    shFrame = f
    return f
end

-- ---------- REFRESH UI ----------
function WG.RefreshSlaughterHouseUI()
    if not shFrame or not shFrame:IsShown() then return end
    local s = WG.shSession
    local t = WG.GetActiveTheme()

    if not s or not WG.shState then
        shFrame.titleText:SetText(L["SLAUGHTER_TITLE"])
        shFrame.statusText:SetText(L["SLAUGHTER_SETUP_HINT"])
        shFrame.progressText:SetText("")
        shFrame.timerBar:Hide()
        shFrame.setupPanel:Show()
        shFrame.listFrame:Hide()
        shFrame.declareInput:Hide()
        shFrame.declareBtn:Hide()
        shFrame.postBtn:Hide()
        shFrame.doneBtn:Hide()
        shFrame.rosterText:SetText(table.concat(GetHomeGroupRoster(), ", "))
        return
    end

    shFrame.setupPanel:Hide()
    shFrame.listFrame:Show()
    shFrame.titleText:SetText(L["SLAUGHTER_TITLE"] .. " - " .. (s.bracket * 2) .. " players")

    if WG.shState == "invited" then
        shFrame.statusText:SetText(string.format(L["SLAUGHTER_WAITING_ACCEPT"], s.opponentContact or "?"))
    elseif WG.shState == "active" and not s.turnOrder then
        shFrame.statusText:SetText(L["SLAUGHTER_WAITING_ORDER"])
    elseif WG.shState == "active" then
        if IsMyTurn() then
            shFrame.statusText:SetText("|cff" .. t.inlineGreen .. L["SLAUGHTER_YOUR_TURN"] .. "|r")
        else
            shFrame.statusText:SetText(string.format(L["SLAUGHTER_WAITING_ON"], CurrentPlayerName() or "?"))
        end
    elseif WG.shState == "resolved" then
        shFrame.statusText:SetText("|cff" .. t.inlineGreen .. L["SLAUGHTER_COMPLETE"] .. "|r")
    end

    if s.turnOrder then
        local total = #s.turnOrder
        local current = math.min(s.currentTurn, total + 1)
        shFrame.progressText:SetText(string.format(L["SLAUGHTER_TURN_PROGRESS"], current - 1, total))
    else
        shFrame.progressText:SetText("")
    end

    if WG.shState == "active" and s.turnTimer and s.turnExpires then
        shFrame.timerBar:Show()
        local remaining = s.turnExpires - GetTime()
        if remaining < 0 then remaining = 0 end
        shFrame.timerBar:SetValue(remaining / s.turnTimer)
    else
        shFrame.timerBar:Hide()
    end

    for i = 1, MAX_SLOTS do
        local row = slotRows[i]
        local name = s.turnOrder and s.turnOrder[i]
        if not name then
            row:Hide()
        else
            row:Show()
            local group = GroupOf(s, name)
            local groupColorKey = group == "A" and "inlineAccent" or "inlineLoss"
            local toon = s.declarations[name]
            local line
            if toon then
                line = string.format("%d. |cff%s%s|r (Group %s) - |cff%s%s|r", i, t[groupColorKey], name, group, t.inlineGreen, toon)
            else
                line = string.format("%d. |cff%s%s|r (Group %s) - ...", i, t[groupColorKey], name, group)
            end
            row.text:SetText(line)
        end
    end

    if WG.shState == "active" and IsMyTurn() then
        shFrame.declareInput:Show()
        shFrame.declareBtn:Show()
        if shFrame.declareInput:GetText() == "" then
            local prefill = s._testMode and CurrentPlayerName() or (UnitName("player"))
            shFrame.declareInput:SetText(prefill or "")
        end
    else
        shFrame.declareInput:Hide()
        shFrame.declareBtn:Hide()
    end

    if WG.shState == "resolved" then
        shFrame.postBtn:Show()
        shFrame.doneBtn:Show()
    else
        shFrame.postBtn:Hide()
        shFrame.doneBtn:Hide()
    end
end

function WG.ShowSlaughterHouseFrame()
    if not shFrame then CreateSlaughterHouseFrame() end
    shFrame:Show()
    WG.RefreshSlaughterHouseUI()
end

function WG.ToggleSlaughterHouse()
    if not shFrame then CreateSlaughterHouseFrame() end
    if shFrame:IsShown() then
        shFrame:Hide()
        return
    end

    if not WG.shSession then
        local prefillContact = ""
        if WG.lastChallenge and WG.lastChallenge.opponent and WG.lastChallenge.timestamp
           and (time() - WG.lastChallenge.timestamp) < 3600 then
            prefillContact = WG.lastChallenge.opponent
        elseif WG.vetoSession and WG.vetoSession.opponent then
            prefillContact = WG.vetoSession.opponent
        end
        shFrame.contactInput:SetText(prefillContact)
    end

    shFrame:Show()
    WG.RefreshSlaughterHouseUI()
end

-- ================================================================
-- DEBUG TEST MODE
-- Usage: /run WargamesPlus.SlaughterHouseTest(3)
-- Simulates a full local draft (fake teammates/opponents) so the panel,
-- turn gating, and timer can be exercised without a second account.
-- ================================================================
function WG.SlaughterHouseTest(bracket)
    bracket = tonumber(bracket) or 3

    if WG.shState then
        WG.shState = nil
        WG.shSession = nil
        StopTurnTimer()
        if shFrame then shFrame:Hide() end
    end

    local groupA, groupB = {}, {}
    groupA[1] = UnitName("player")
    for i = 2, bracket do groupA[i] = "TeamMate" .. i end
    for i = 1, bracket do groupB[i] = "Enemy" .. i end

    local all = {}
    for _, n in ipairs(groupA) do table.insert(all, n) end
    for _, n in ipairs(groupB) do table.insert(all, n) end

    WG.shState = "active"
    WG.shSession = {
        bracket = bracket,
        isHost = true,
        myGroup = "A",
        groupA = groupA,
        groupB = groupB,
        turnOrder = ShuffleOrder(all),
        currentTurn = 1,
        declarations = {},
        opponentContact = "TestOpponent",
        _testMode = true,
    }

    print("|cffffcc00[SlaughterHouseTest]|r Started " .. bracket .. "v" .. bracket .. " test draft. You control every turn.")
    WG.ShowSlaughterHouseFrame()
    StartTurnTimer()
end
