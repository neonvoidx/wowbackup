-- readycheck.lua: WarGames+ standalone Ready Check
-- A shared panel that shows each team leader's readiness (and their assembled roster),
-- gates the challenge until both leaders confirm, then fires it. Leader <-> leader over
-- whisper (SendV2). Modeled on veto.lua's invite/cancel handshake.
--
-- MVP scope: leader-to-leader gate + an informational roster list. Per-teammate ready
-- sync over the party channel is a documented follow-up (see RC_STATE stub).
--
-- Load order: ... comm.lua -> veto.lua -> readycheck.lua

local WG = _G["WargamesPlus"]
if not WG then return end
local L = WG.L

local ADDON_FONT = WG.ADDON_FONT or "Fonts\\FRIZQT__.TTF"
local RC_TIMEOUT = 120

WG.rcSession = nil
-- { opponent, whisperTarget, iAmInitiator, roster = { {name, class}, ... },
--   myReady = bool, theirReady = bool, deadline = n }
-- opponent      = short character name, used to match incoming messages
-- whisperTarget = realm-qualified name, used for every outgoing SendV2

local rcFrame
local rcTicker
local rcRows = {}

-- ---------- HELPERS ----------
local function Chat(msg)
    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. msg)
end

local function ClassColor(name, classToken)
    if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
        return "|cff" .. RAID_CLASS_COLORS[classToken].colorStr:sub(3) .. (name or "?") .. "|r"
    end
    return "|cff" .. WG.GetActiveTheme().inlineChar .. (name or "?") .. "|r"
end

-- Ordered {name, class} for the player + current party/raid.
local function GetRoster()
    local out = {}
    local _, myClass = UnitClass("player")
    out[#out + 1] = { name = UnitName("player"), class = myClass }

    local prefix, count
    if IsInRaid() then
        prefix, count = "raid", GetNumGroupMembers()
    elseif IsInGroup() then
        prefix, count = "party", GetNumGroupMembers() - 1
    end
    if prefix then
        for i = 1, count do
            local unit = prefix .. i
            if UnitExists(unit) and not UnitIsUnit(unit, "player") then
                local n = UnitName(unit)
                if n then
                    local _, c = UnitClass(unit)
                    out[#out + 1] = { name = n, class = c }
                end
            end
        end
    end
    return out
end

-- ---------- LIFECYCLE ----------
local function StopTicker()
    if rcTicker then rcTicker:Cancel(); rcTicker = nil end
end

-- broadcast=true tells the opponent (user-initiated close); false is a silent local
-- close (we received their cancel, or launched the challenge).
local function CloseRC(broadcast)
    StopTicker()
    local s = WG.rcSession
    WG.rcSession = nil
    if broadcast and s then
        WG.SendV2("RC_CANCEL", s.whisperTarget or s.opponent)
        Chat(L["RC_CANCELLED"])
    end
    if rcFrame and rcFrame:IsShown() then
        rcFrame._suppressHide = true
        rcFrame:Hide()
        rcFrame._suppressHide = nil
    end
end

local function StartTicker()
    StopTicker()
    rcTicker = C_Timer.NewTicker(1, function()
        local s = WG.rcSession
        if not s then StopTicker(); return end
        if time() > s.deadline then
            Chat(L["RC_TIMEOUT"])
            CloseRC(true)
        end
    end)
end

local function SetMyReady(ready)
    local s = WG.rcSession
    if not s then return end
    s.myReady = ready
    s.deadline = time() + RC_TIMEOUT  -- activity resets the idle timeout
    WG.SendV2("RC_TEAM", s.whisperTarget or s.opponent, ready and "1" or "0")
end

-- ---------- FRAME ----------
local function RefreshRCFrame()
    local s = WG.rcSession
    if not rcFrame or not rcFrame:IsShown() or not s then return end
    local t = WG.GetActiveTheme()

    rcFrame.titleText:SetText(L["RC_TITLE"] .. "   |cff" .. t.inlineAccent .. "vs " .. s.opponent .. "|r")

    local dr, dg, db = WG.HexToRGB(t.inlineChar or "cccccc")
    local y = -54
    for i, m in ipairs(s.roster) do
        local row = rcRows[i]
        if not row then
            row = CreateFrame("Frame", nil, rcFrame)
            row:SetSize(280, 20)
            row.dot = row:CreateTexture(nil, "ARTWORK")
            row.dot:SetSize(6, 6)
            row.dot:SetPoint("LEFT", 18, 0)
            row.name = row:CreateFontString(nil, "OVERLAY")
            row.name:SetFont(ADDON_FONT, 11)
            row.name:SetPoint("LEFT", row.dot, "RIGHT", 8, 0)
            rcRows[i] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, y)
        row.dot:SetColorTexture(dr, dg, db, 0.8)
        row.name:SetText(ClassColor(m.name, m.class))
        row:Show()
        y = y - 20
    end
    for i = #s.roster + 1, #rcRows do rcRows[i]:Hide() end

    -- My "Ready" toggle
    y = y - 10
    rcFrame.myToggle:ClearAllPoints()
    rcFrame.myToggle:SetPoint("TOPLEFT", 16, y)
    rcFrame.myToggle:SetChecked(s.myReady)
    rcFrame.myLabel:ClearAllPoints()
    rcFrame.myLabel:SetPoint("LEFT", rcFrame.myToggle, "RIGHT", 6, 0)
    y = y - 26

    -- Opponent section
    rcFrame.oppHeader:ClearAllPoints()
    rcFrame.oppHeader:SetPoint("TOPLEFT", 14, y)
    y = y - 18
    rcFrame.oppLine:ClearAllPoints()
    rcFrame.oppLine:SetPoint("TOPLEFT", 16, y)
    if s.theirReady then
        rcFrame.oppLine:SetText("|cff" .. t.inlineGreen .. L["RC_OPP_READY"] .. "|r")
    else
        rcFrame.oppLine:SetText("|cff888888" .. L["RC_OPP_WAITING"] .. "|r")
    end
    y = y - 28

    -- Footer
    rcFrame.sendBtn:ClearAllPoints()
    rcFrame.sendBtn:SetPoint("TOP", 0, y)
    rcFrame.waitLine:ClearAllPoints()
    rcFrame.waitLine:SetPoint("TOP", 0, y - 4)
    if s.iAmInitiator then
        rcFrame.sendBtn:Show(); rcFrame.waitLine:Hide()
        rcFrame.sendBtn:SetEnabled(s.myReady and s.theirReady)
    else
        rcFrame.sendBtn:Hide(); rcFrame.waitLine:Show()
        rcFrame.waitLine:SetText("|cff888888" .. string.format(L["RC_WAITING_INIT"], s.opponent) .. "|r")
    end
    y = y - 36

    rcFrame:SetHeight(-y + 12)
end

local function CreateRCFrame()
    if rcFrame then return rcFrame end
    local f = CreateFrame("Frame", "WG_ReadyCheckFrame", UIParent, "BackdropTemplate")
    f:SetSize(300, 220)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(120)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    WG.ApplyModernStyle(f)
    if WG.ApplyUIScale then WG.ApplyUIScale(f) end

    local chrome = WG.CreateWindowChrome(f, { title = L["RC_TITLE"], titleSize = 13, closeSize = 18 })
    f.titleText = chrome.title

    f.myHeader = f:CreateFontString(nil, "OVERLAY")
    f.myHeader:SetFont(ADDON_FONT, 9, "OUTLINE")
    f.myHeader:SetPoint("TOPLEFT", 14, -36)
    f.myHeader:SetText(L["RC_MY_TEAM"])
    f.myHeader:SetTextColor(unpack(WG.GetActiveTheme().headerColor))
    WG.RegisterThemedElement(f.myHeader, function(fs) fs:SetTextColor(unpack(WG.GetActiveTheme().headerColor)) end)

    f.myToggle = WG.CreateToggleSwitch(f, { onChange = function(checked) SetMyReady(checked); RefreshRCFrame() end })
    f.myLabel = f:CreateFontString(nil, "OVERLAY")
    f.myLabel:SetFont(ADDON_FONT, 11)
    f.myLabel:SetText(L["RC_READY"])
    f.myLabel:SetTextColor(unpack(WG.GetActiveTheme().normalText))
    WG.RegisterThemedElement(f.myLabel, function(fs) fs:SetTextColor(unpack(WG.GetActiveTheme().normalText)) end)

    f.oppHeader = f:CreateFontString(nil, "OVERLAY")
    f.oppHeader:SetFont(ADDON_FONT, 9, "OUTLINE")
    f.oppHeader:SetText(L["RC_OPPONENT"])
    f.oppHeader:SetTextColor(unpack(WG.GetActiveTheme().headerColor))
    WG.RegisterThemedElement(f.oppHeader, function(fs) fs:SetTextColor(unpack(WG.GetActiveTheme().headerColor)) end)

    f.oppLine = f:CreateFontString(nil, "OVERLAY")
    f.oppLine:SetFont(ADDON_FONT, 11)

    f.sendBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.sendBtn:SetSize(180, 28)
    f.sendBtn:SetText(L["RC_SEND"])
    WG.StyleButton(f.sendBtn)
    f.sendBtn:GetFontString():SetFont(ADDON_FONT, 12, "THINOUTLINE")
    f.sendBtn._hasInlineColor = true
    local function paintSend()
        if f.sendBtn._flatBg then f.sendBtn._flatBg:SetColorTexture(unpack(WG.GetActiveTheme().accent)) end
        f.sendBtn:SetText("|cffffffff" .. L["RC_SEND"]:upper() .. "|r")
    end
    paintSend()
    f.sendBtn:HookScript("OnEnter", paintSend)
    f.sendBtn:HookScript("OnLeave", paintSend)
    f.sendBtn:HookScript("OnMouseUp", paintSend)
    WG.RegisterThemedElement(f.sendBtn, paintSend)
    f.sendBtn:SetScript("OnClick", function()
        local s = WG.rcSession
        if not s then return end
        -- Prefer the realm-qualified name so a cross-realm challenge resolves.
        local opp = s.whisperTarget or s.opponent
        WG.rcSession = nil
        StopTicker()
        f._suppressHide = true; f:Hide(); f._suppressHide = nil
        if WG.mainFrame then
            WG.mainFrame.editBox:SetText(opp)
            WG.mainFrame.challengeBtn:Click()
        end
    end)

    f.waitLine = f:CreateFontString(nil, "OVERLAY")
    f.waitLine:SetFont(ADDON_FONT, 10)

    f:SetScript("OnHide", function(self)
        if self._suppressHide then return end
        CloseRC(true)
    end)

    rcFrame = f
    return f
end

local function ShowRCFrame()
    CreateRCFrame()
    rcFrame:Show()
    RefreshRCFrame()
end

-- ---------- PUBLIC API ----------
-- Shared session bootstrap. `display` is the short name used to match incoming
-- messages; `whisper` is the realm-qualified target for outgoing SendV2.
local function BeginSession(display, whisper, iAmInitiator)
    WG.rcSession = { opponent = display, whisperTarget = whisper, iAmInitiator = iAmInitiator,
                     roster = GetRoster(), myReady = false, theirReady = false,
                     deadline = time() + RC_TIMEOUT }
    ShowRCFrame()
    StartTicker()
end

local function IsDetected(name, short, whisper)
    return WG.HasAddonDetected(name)
        or (short and WG.HasAddonDetected(short))
        or (whisper and WG.HasAddonDetected(whisper))
end

function WG.StartReadyCheck(opponentName)
    if not opponentName or opponentName == "" then Chat(L["RC_NO_OPPONENT"]); return end
    if WG.rcSession or WG.vetoState then return end

    local short   = WG.ShortName(opponentName)
    local whisper = WG.ResolveWhisperName(opponentName)
    if not whisper then
        -- e.g. a BattleTag we can't resolve to an online, same-region character
        Chat(L["RC_NO_ADDON"]); return
    end

    if IsDetected(opponentName, short, whisper) then
        BeginSession(short, whisper, true)
        WG.SendV2("RC_INIT", whisper)
        return
    end

    -- Not heard from yet: probe with a PING and wait briefly. A PONG both proves
    -- the addon and (via addonUserRealms) sharpens the whisper target.
    Chat(string.format(L["RC_DETECTING"], short))
    WG.SendV2("PING", whisper, UnitName("player"))
    local waited, poll = 0
    poll = C_Timer.NewTicker(0.5, function()
        if WG.rcSession or WG.vetoState then poll:Cancel(); return end
        waited = waited + 0.5
        local w2 = WG.ResolveWhisperName(opponentName) or whisper
        if IsDetected(opponentName, short, w2) then
            poll:Cancel()
            BeginSession(short, w2, true)
            WG.SendV2("RC_INIT", w2)
        elseif waited >= 4 then
            poll:Cancel()
            Chat(L["RC_NO_ADDON"])
        end
    end)
end

function WG.CancelReadyCheck()
    CloseRC(true)
end

-- ---------- COMM HANDLERS ----------
function WG.RCOnInit(sender, rest)
    if WG.rcSession or WG.vetoState then return end
    WG.addonUsers[sender] = time()
    local short = WG.ShortName(sender)
    local whisper = WG.ResolveWhisperName(sender) or sender
    BeginSession(short, whisper, false)
    WG.SendV2("RC_ACK", whisper)
    Chat(string.format(L["RC_INVITE_RECEIVED"], short))
end

function WG.RCOnAck(sender, rest)
    local s = WG.rcSession
    if not s or s.opponent ~= sender then return end
    WG.addonUsers[sender] = time()
    RefreshRCFrame()
end

function WG.RCOnTeam(sender, rest)
    local s = WG.rcSession
    if not s or s.opponent ~= sender then return end
    s.theirReady = (rest:match("^%s*(%d)") == "1")
    s.deadline = time() + RC_TIMEOUT
    RefreshRCFrame()
end

-- Follow-up: per-teammate ready sync over the party channel. Stub kept so the comm
-- router has a target and the protocol slot is reserved.
function WG.RCOnState(sender, rest, channel) end

function WG.RCOnCancel(sender, rest)
    if not WG.rcSession then return end
    Chat(L["RC_CANCELLED"])
    CloseRC(false)
end
