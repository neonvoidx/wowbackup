-- veto.lua: WarGames+ Map Veto System
-- CS2/Valorant-style alternating map ban/pick system.
-- Load order: core.lua -> tracker.lua -> comm.lua -> veto.lua

local WG = _G["WargamesPlus"]
if not WG then return end
local L = WG.L

local ADDON_FONT = WG.ADDON_FONT or "Fonts\\FRIZQT__.TTF"

-- ---------- VETO STATE ----------
WG.vetoState = nil   -- nil | "invited" | "active" | "resolved"
WG.vetoSession = nil -- session data table

-- ---------- TURN ORDER GENERATION ----------
local function BuildTurnOrder(format, poolSize)
    local turns = {}
    if format == "Bo1" then
        -- Alternating bans until 1 map remains
        for i = 1, poolSize - 1 do
            local player = (i % 2 == 1) and "initiator" or "opponent"
            table.insert(turns, {action = "ban", player = player})
        end
    elseif format == "Bo3" then
        -- Ban-Ban-Pick-Pick-Ban-Ban, remaining = decider
        local sequence = {"ban","ban","pick","pick","ban","ban"}
        local players  = {"initiator","opponent","initiator","opponent","opponent","initiator"}
        for i = 1, math.min(#sequence, poolSize - 1) do
            table.insert(turns, {action = sequence[i], player = players[i]})
        end
    elseif format == "Bo5" then
        -- Ban-Ban-Pick-Pick-Pick-Pick, remaining = decider
        local sequence = {"ban","ban","pick","pick","pick","pick"}
        local players  = {"initiator","opponent","initiator","opponent","opponent","initiator"}
        for i = 1, math.min(#sequence, poolSize - 1) do
            table.insert(turns, {action = sequence[i], player = players[i]})
        end
    end
    return turns
end

-- Minimum pool size for each format
local MIN_POOL = { Bo1 = 3, Bo3 = 7, Bo5 = 7 }

-- ---------- VETO FRAME ----------
local vetoFrame
local mapButtons = {}
local seriesSlots = {}
local MAPS_PER_ROW = 4
local MAP_BTN_W = 138
local MAP_BTN_H = 52
local MAP_BTN_PAD = 6

local function GetMyRole()
    local s = WG.vetoSession
    if not s then return nil end
    return s.isInitiator and "initiator" or "opponent"
end

local function IsMyTurn()
    local s = WG.vetoSession
    if not s or WG.vetoState ~= "active" then return false end
    local turn = s.turnOrder[s.currentTurn]
    if not turn then return false end
    return turn.player == GetMyRole()
end

local function GetCurrentAction()
    local s = WG.vetoSession
    if not s then return nil end
    local turn = s.turnOrder[s.currentTurn]
    return turn and turn.action or nil
end

local function GetRemainingMaps()
    local s = WG.vetoSession
    if not s then return {} end
    local remaining = {}
    for _, m in ipairs(s.mapPool) do
        if not s.bannedMaps[m] and not s.pickedMaps[m] then
            table.insert(remaining, m)
        end
    end
    return remaining
end

-- Count picked maps in order
local function GetPickedMapList()
    local s = WG.vetoSession
    if not s then return {} end
    return s.pickedOrder or {}
end

local function ResolveVeto()
    local s = WG.vetoSession
    if not s then return end

    local remaining = GetRemainingMaps()

    -- For Bo3/Bo5, remaining map is decider
    if s.format ~= "Bo1" and #remaining == 1 then
        table.insert(s.pickedOrder, remaining[1])
        s.pickedMaps[remaining[1]] = "decider"
    end

    WG.vetoState = "resolved"
    s.myReady = false
    s.theirReady = false

    -- Save veto history
    local history = WG_History.vetoHistory or {}
    local oppKey = s.opponent
    if not history[oppKey] then history[oppKey] = {} end
    table.insert(history[oppKey], 1, {
        timestamp = time(),
        format = s.format,
        maps = s.pickedOrder,
        banLog = s.banLog,
    })
    -- Keep last 20 entries per opponent
    while #history[oppKey] > 20 do
        table.remove(history[oppKey])
    end
    WG_History.vetoHistory = history

    WG.RefreshVetoUI()
end

-- ---------- REFRESH UI ----------
function WG.RefreshVetoUI()
    if not vetoFrame or not vetoFrame:IsShown() then return end
    local s = WG.vetoSession
    if not s then return end

    local t = WG.GetActiveTheme()

    -- Title: "MAP VETO  ·  BEST OF N   vs Opponent"
    local bestOf = ({ Bo1 = "1", Bo3 = "3", Bo5 = "5" })[s.format] or s.format
    vetoFrame.titleText:SetText(
        L["VETO_TITLE"] .. "  |cff" .. t.inlineAccent .. "\194\183|r  " ..
        (string.format(L["VETO_BEST_OF"], bestOf)) ..
        "   |cff" .. t.inlineAccent .. "vs " .. s.opponent .. "|r")

    -- Status text (inside the tinted banner)
    if WG.vetoState == "invited" then
        vetoFrame.statusText:SetText(string.format(L["VETO_OPPONENT_TURN"], s.opponent))
    elseif WG.vetoState == "active" then
        if IsMyTurn() then
            local action = GetCurrentAction()
            if action == "ban" then
                vetoFrame.statusText:SetText("|cff" .. t.inlineLoss .. L["VETO_YOUR_TURN_BAN"] .. "|r")
            else
                vetoFrame.statusText:SetText("|cff" .. t.inlineGreen .. L["VETO_YOUR_TURN_PICK"] .. "|r")
            end
        else
            vetoFrame.statusText:SetText(string.format(L["VETO_OPPONENT_TURN"], s.opponent))
        end
    elseif WG.vetoState == "resolved" then
        local picks = GetPickedMapList()
        if #picks == 1 then
            vetoFrame.statusText:SetText("|cff" .. t.inlineGreen .. string.format(L["VETO_FINAL_MAP"], picks[1]) .. "|r")
        else
            vetoFrame.statusText:SetText("|cff" .. t.inlineGreen .. L["VETO_COMPLETE"] .. "|r")
        end
    end

    -- Turn counter + progress bar (countdown while a turn timer runs, else series progress)
    local totalTurns = #s.turnOrder
    local currentTurn = math.min(s.currentTurn, totalTurns + 1)
    vetoFrame.progressText:SetText(string.format(L["VETO_TURN_PROGRESS"], currentTurn - 1, totalTurns))
    if WG.vetoState == "active" and s.turnTimer and s.turnExpires then
        local remaining = s.turnExpires - GetTime()
        if remaining < 0 then remaining = 0 end
        vetoFrame.progressBar:SetProgress(remaining / s.turnTimer)
    else
        vetoFrame.progressBar:SetProgress(totalTurns > 0 and (currentTurn - 1) / totalTurns or 1)
    end

    -- Map tiles — grow the grid + window when the pool needs more than 4 rows so
    -- larger arena pools (17+ maps) aren't clipped.
    local shownCount = math.min(#s.mapPool, #mapButtons)
    local rows = math.max(1, math.ceil(shownCount / MAPS_PER_ROW))
    vetoFrame.gridFrame:SetHeight(MAP_BTN_H * rows + MAP_BTN_PAD * math.max(0, rows - 1))
    local extraRows = math.max(0, rows - 4)
    vetoFrame:SetHeight(440 + extraRows * (MAP_BTN_H + MAP_BTN_PAD))

    local myTurnNow = WG.vetoState == "active" and IsMyTurn()
    for i, tile in ipairs(mapButtons) do
        local mapName = s.mapPool[i]
        if not mapName then
            tile:Hide()
        else
            tile:Show()
            tile._mapName = mapName
            tile._label:SetText(mapName)
            tile:SetMapTexture(WG.MAP_TEXTURES and WG.MAP_TEXTURES[mapName] or nil)

            local banned = s.bannedMaps[mapName] and true or false
            local picked = s.pickedMaps[mapName] and true or false
            tile._chosen = banned or picked
            tile:SetBanned(banned)
            tile:SetPicked(picked)
            if not tile._chosen then tile:SetSelected(false) end
            tile:SetEnabled((not tile._chosen) and myTurnNow)

            if banned then
                tile._label:SetTextColor(0.85, 0.72, 0.72, 1)
            elseif picked then
                local pr, pg, pb = WG.HexToRGB(t.inlineGreen)
                tile._label:SetTextColor(pr, pg, pb, 1)
            else
                tile._label:SetTextColor(1, 1, 1, 1)
            end
        end
    end

    -- Series panel (Bo3/Bo5): horizontal cells
    if s.format ~= "Bo1" then
        vetoFrame.seriesPanel:Show()
        local picks = GetPickedMapList()
        local totalMaps = s.format == "Bo3" and 3 or 5
        local panelW = vetoFrame.seriesPanel:GetWidth() or 560
        local labelW = 44
        local gap = 6
        local cellW = math.floor((panelW - labelW - gap * totalMaps) / totalMaps)
        for i = 1, 5 do
            local slot = seriesSlots[i]
            if i <= totalMaps then
                slot:Show()
                slot:ClearAllPoints()
                slot:SetWidth(cellW)
                slot:SetPoint("LEFT", vetoFrame.seriesPanel, "LEFT", labelW + (i - 1) * (cellW + gap), 0)

                local prefix = (i == totalMaps) and L["VETO_SERIES_DECIDER"] or (L["VETO_SERIES_MAP_SHORT"] .. " " .. i)
                if picks[i] then
                    slot.check:Show()
                    slot.text:ClearAllPoints()
                    slot.text:SetPoint("LEFT", slot.check, "RIGHT", 4, 0)
                    slot.text:SetPoint("RIGHT", -4, 0)
                    local gr, gg, gb = WG.HexToRGB(t.inlineGreen)
                    slot.text:SetTextColor(gr, gg, gb, 1)
                    slot.text:SetText(prefix .. ": " .. picks[i])
                else
                    slot.check:Hide()
                    slot.text:ClearAllPoints()
                    slot.text:SetPoint("LEFT", 6, 0)
                    slot.text:SetPoint("RIGHT", -4, 0)
                    slot.text:SetTextColor(unpack(t.footerColor))
                    slot.text:SetText(prefix .. ": \226\128\148\226\128\148\226\128\148")
                end
            else
                slot:Hide()
            end
        end
    else
        vetoFrame.seriesPanel:Hide()
    end

    -- Ready button
    if WG.vetoState == "resolved" then
        vetoFrame.readyBtn:Show()
        if s.myReady then
            vetoFrame.readyBtn:SetText(L["VETO_WAITING_OPPONENT"])
            vetoFrame.readyBtn:SetEnabled(false)
        else
            vetoFrame.readyBtn:SetText(L["VETO_READY"])
            vetoFrame.readyBtn:SetEnabled(true)
        end
    else
        vetoFrame.readyBtn:Hide()
    end
end

-- ---------- TIMER SYSTEM ----------
local timerTicker
local function StartTurnTimer()
    local s = WG.vetoSession
    if not s then return end
    local duration = WG_History.vetoTurnTimer or 30
    if duration <= 0 then return end

    s.turnTimer = duration
    s.turnExpires = GetTime() + duration

    if timerTicker then timerTicker:Cancel() end
    timerTicker = C_Timer.NewTicker(0.1, function()
        if WG.vetoState ~= "active" then
            timerTicker:Cancel()
            timerTicker = nil
            return
        end
        local remaining = s.turnExpires - GetTime()
        if remaining <= 0 then
            timerTicker:Cancel()
            timerTicker = nil
            -- Auto-ban a random map if it's our turn
            if IsMyTurn() then
                local available = GetRemainingMaps()
                if #available > 0 then
                    local pick = available[math.random(1, #available)]
                    WG.VetoAction(pick)
                end
            end
            return
        end
        -- Update the countdown on the shared progress bar
        if vetoFrame and vetoFrame:IsShown() and vetoFrame.progressBar then
            vetoFrame.progressBar:SetProgress(remaining / s.turnTimer)
        end
    end)
end

local function StopTurnTimer()
    if timerTicker then timerTicker:Cancel(); timerTicker = nil end
    local s = WG.vetoSession
    if s then s.turnTimer = nil; s.turnExpires = nil end
end

-- ---------- VETO ACTIONS ----------
function WG.VetoAction(mapName)
    local s = WG.vetoSession
    if not s or WG.vetoState ~= "active" then return end
    if not IsMyTurn() then return end
    if s.bannedMaps[mapName] or s.pickedMaps[mapName] then return end

    local turn = s.turnOrder[s.currentTurn]
    if not turn then return end

    StopTurnTimer()

    if turn.action == "ban" then
        s.bannedMaps[mapName] = GetMyRole()
        table.insert(s.banLog, {map = mapName, player = GetMyRole(), action = "ban"})
        WG.SendV2("VETO_BAN", s.opponent, tostring(s.currentTurn), mapName)
        local t = WG.GetActiveTheme()
        print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["VETO_BANNED"], UnitName("player"), mapName))
    else
        s.pickedMaps[mapName] = GetMyRole()
        table.insert(s.pickedOrder, mapName)
        table.insert(s.banLog, {map = mapName, player = GetMyRole(), action = "pick"})
        WG.SendV2("VETO_PICK", s.opponent, tostring(s.currentTurn), mapName)
        local t = WG.GetActiveTheme()
        print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["VETO_PICKED"], UnitName("player"), mapName))
    end

    s.currentTurn = s.currentTurn + 1

    -- Check if veto is complete
    if s.currentTurn > #s.turnOrder then
        ResolveVeto()
    else
        StartTurnTimer()
        WG.RefreshVetoUI()
    end
end

-- ---------- COMM HANDLERS ----------
function WG.VetoOnInvite(sender, rest)
    -- Format: format\tturnIdx\tmap1\tmap2\t...
    local parts = {}
    for part in rest:gmatch("[^\t]+") do
        table.insert(parts, part)
    end
    if #parts < 3 then return end

    local format = parts[1]
    if format ~= "Bo1" and format ~= "Bo3" and format ~= "Bo5" then return end

    local mapPool = {}
    for i = 2, #parts do
        table.insert(mapPool, parts[i])
    end

    local minPool = MIN_POOL[format] or 3
    if #mapPool < minPool then return end

    WG.addonUsers[sender] = time()

    -- Auto-accept: set up veto session as receiver
    WG.vetoState = "active"
    local turnOrder = BuildTurnOrder(format, #mapPool)
    WG.vetoSession = {
        opponent = sender,
        format = format,
        mapPool = mapPool,
        bannedMaps = {},
        pickedMaps = {},
        pickedOrder = {},
        banLog = {},
        turnOrder = turnOrder,
        currentTurn = 1,
        isInitiator = false,
        myReady = false,
        theirReady = false,
    }

    WG.SendV2("VETO_ACCEPT", sender)
    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["VETO_INVITE_RECEIVED"], sender, format))

    WG.ShowVetoFrame()
    StartTurnTimer()
end

function WG.VetoOnAccept(sender)
    local s = WG.vetoSession
    if not s or s.opponent ~= sender then return end
    if WG.vetoState ~= "invited" then return end

    WG.vetoState = "active"
    WG.addonUsers[sender] = time()

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. sender .. " accepted the veto.")

    StartTurnTimer()
    WG.RefreshVetoUI()
end

function WG.VetoOnDecline(sender)
    local s = WG.vetoSession
    if not s or s.opponent ~= sender then return end

    WG.vetoState = nil
    WG.vetoSession = nil
    StopTurnTimer()

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. sender .. " declined the veto.")
    if vetoFrame then vetoFrame:Hide() end
end

function WG.VetoOnBan(sender, rest)
    local s = WG.vetoSession
    if not s or s.opponent ~= sender or WG.vetoState ~= "active" then return end

    local parts = {}
    for part in rest:gmatch("[^\t]+") do
        table.insert(parts, part)
    end
    if #parts < 2 then return end

    local turnIdx = tonumber(parts[1])
    local mapName = parts[2]

    -- Validate turn
    if turnIdx ~= s.currentTurn then return end
    local turn = s.turnOrder[s.currentTurn]
    if not turn or turn.action ~= "ban" then return end
    if s.bannedMaps[mapName] or s.pickedMaps[mapName] then return end

    StopTurnTimer()

    s.bannedMaps[mapName] = "opponent"
    table.insert(s.banLog, {map = mapName, player = "opponent", action = "ban"})
    s.currentTurn = s.currentTurn + 1

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["VETO_BANNED"], sender, mapName))

    if s.currentTurn > #s.turnOrder then
        ResolveVeto()
    else
        StartTurnTimer()
        WG.RefreshVetoUI()
    end
end

function WG.VetoOnPick(sender, rest)
    local s = WG.vetoSession
    if not s or s.opponent ~= sender or WG.vetoState ~= "active" then return end

    local parts = {}
    for part in rest:gmatch("[^\t]+") do
        table.insert(parts, part)
    end
    if #parts < 2 then return end

    local turnIdx = tonumber(parts[1])
    local mapName = parts[2]

    if turnIdx ~= s.currentTurn then return end
    local turn = s.turnOrder[s.currentTurn]
    if not turn or turn.action ~= "pick" then return end
    if s.bannedMaps[mapName] or s.pickedMaps[mapName] then return end

    StopTurnTimer()

    s.pickedMaps[mapName] = "opponent"
    table.insert(s.pickedOrder, mapName)
    table.insert(s.banLog, {map = mapName, player = "opponent", action = "pick"})
    s.currentTurn = s.currentTurn + 1

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["VETO_PICKED"], sender, mapName))

    if s.currentTurn > #s.turnOrder then
        ResolveVeto()
    else
        StartTurnTimer()
        WG.RefreshVetoUI()
    end
end

function WG.VetoOnCancel(sender)
    local s = WG.vetoSession
    if not s or s.opponent ~= sender then return end

    WG.vetoState = nil
    WG.vetoSession = nil
    StopTurnTimer()

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["VETO_CANCELLED"])
    if vetoFrame then vetoFrame:Hide() end
end

function WG.VetoOnReady(sender)
    local s = WG.vetoSession
    if not s or s.opponent ~= sender or WG.vetoState ~= "resolved" then return end

    s.theirReady = true

    if s.myReady then
        -- Both ready — auto-launch
        WG.VetoLaunchChallenge()
    else
        WG.RefreshVetoUI()
    end
end

-- ---------- LAUNCH CHALLENGE ----------
function WG.VetoLaunchChallenge()
    local s = WG.vetoSession
    if not s then return end

    local picks = GetPickedMapList()
    local mapName
    if s.format == "Bo1" then
        -- For Bo1, the sole remaining map
        local remaining = GetRemainingMaps()
        mapName = remaining[1] or (picks[1])
    else
        -- For series, use the first picked map (subsequent maps handled after match)
        mapName = picks[1]
    end

    if mapName and WG.mainFrame then
        WG.mainFrame:SelectMapByName(mapName)
    end

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["VETO_FINAL_MAP"], mapName or "?"))

    -- Clean up
    StopTurnTimer()
    WG.vetoState = nil
    WG.vetoSession = nil
    if vetoFrame then vetoFrame:Hide() end
end

-- ---------- PUBLIC: START VETO ----------
function WG.StartVeto(opponentName, format, mapPool)
    if not opponentName or opponentName == "" then return end
    if not WG.addonUsers[opponentName] or (time() - WG.addonUsers[opponentName]) > 3600 then
        local t = WG.GetActiveTheme()
        print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["VETO_NO_ADDON"])
        return
    end

    local minPool = MIN_POOL[format] or 3
    if #mapPool < minPool then
        local t = WG.GetActiveTheme()
        print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["VETO_MIN_MAPS"], minPool, format))
        return
    end

    -- Save preferred format
    WG_History.vetoFormat = format

    local turnOrder = BuildTurnOrder(format, #mapPool)
    WG.vetoState = "invited"
    WG.vetoSession = {
        opponent = opponentName,
        format = format,
        mapPool = mapPool,
        bannedMaps = {},
        pickedMaps = {},
        pickedOrder = {},
        banLog = {},
        turnOrder = turnOrder,
        currentTurn = 1,
        isInitiator = true,
        myReady = false,
        theirReady = false,
    }

    -- Send invite
    local parts = {format}
    for _, m in ipairs(mapPool) do
        table.insert(parts, m)
    end
    WG.SendV2("VETO_INVITE", opponentName, unpack(parts))

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["VETO_INVITE_SENT"], opponentName, format))

    WG.ShowVetoFrame()

    -- Timeout for invite
    C_Timer.After(60, function()
        if WG.vetoState == "invited" and WG.vetoSession and WG.vetoSession.opponent == opponentName then
            WG.vetoState = nil
            WG.vetoSession = nil
            print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["VETO_TIMEOUT"])
            if vetoFrame then vetoFrame:Hide() end
        end
    end)
end

-- ---------- PUBLIC: CANCEL VETO ----------
function WG.CancelVeto()
    local s = WG.vetoSession
    if not s then return end

    if s.opponent and s.opponent ~= "" then
        WG.SendV2("VETO_CANCEL", s.opponent)
    end

    WG.vetoState = nil
    WG.vetoSession = nil
    StopTurnTimer()

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["VETO_CANCELLED"])
    if vetoFrame then vetoFrame:Hide() end
end

-- ---------- CREATE VETO FRAME ----------
local function CreateVetoFrame()
    if vetoFrame then return vetoFrame end

    local f = CreateFrame("Frame", "WG_VetoFrame", UIParent, "BackdropTemplate")
    f:SetSize(600, 440)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    WG.ApplyModernStyle(f)
    if WG.ApplyUIScale then WG.ApplyUIScale(f) end

    -- Shared chrome (accent stripe + title + close button), standardized on
    -- theme.titleColor — this frame previously used theme.headerColor for its title,
    -- the only window in the addon that did, and had no accent stripe at all.
    local chrome = WG.CreateWindowChrome(f, {
        onClose = function() WG.CancelVeto() end,
    })
    f.titleText = chrome.title
    f.titleText:SetPoint("RIGHT", chrome.close, "LEFT", -5, 0)
    f.titleText:SetJustifyH("LEFT")

    local theme = WG.GetActiveTheme()

    -- Turn-status banner: a tinted, accent-bordered pill holding the "your turn" text
    -- (left) and the "Turn X / Y" counter (right), matching the redesign mockup.
    f.banner = CreateFrame("Frame", nil, f, "BackdropTemplate")
    f.banner:SetPoint("TOPLEFT", 12, -30)
    f.banner:SetPoint("RIGHT", -12, 0)
    f.banner:SetHeight(28)
    f.banner:SetBackdrop(WG.FLAT_BACKDROP)
    local function PaintBanner()
        local a = WG.GetActiveTheme().accent
        f.banner:SetBackdropColor(a[1], a[2], a[3], 0.12)
        f.banner:SetBackdropBorderColor(a[1], a[2], a[3], 0.45)
    end
    PaintBanner()
    WG.RegisterThemedElement(f.banner, PaintBanner)

    f.statusText = f.banner:CreateFontString(nil, "OVERLAY")
    f.statusText:SetFont(ADDON_FONT, 12, "OUTLINE")
    f.statusText:SetPoint("LEFT", 12, 0)
    f.statusText:SetJustifyH("LEFT")
    f.statusText:SetTextColor(unpack(theme.normalText))

    f.progressText = f.banner:CreateFontString(nil, "OVERLAY")
    f.progressText:SetFont(ADDON_FONT, 10)
    f.progressText:SetPoint("RIGHT", -12, 0)
    f.progressText:SetJustifyH("RIGHT")
    f.progressText:SetTextColor(unpack(theme.footerColor))
    f.statusText:SetPoint("RIGHT", f.progressText, "LEFT", -8, 0)
    WG.RegisterThemedElement(f.progressText, function(fs)
        fs:SetTextColor(unpack(WG.GetActiveTheme().footerColor))
    end)

    -- Single progress bar under the banner: shows the per-turn countdown while a turn
    -- timer is running, otherwise the overall ban/pick progress through the series.
    f.progressBar = WG.CreateProgressBar(f, { height = 5, bgAlpha = 0.5 })
    f.progressBar:SetPoint("TOPLEFT", f.banner, "BOTTOMLEFT", 0, -4)
    f.progressBar:SetPoint("RIGHT", f.banner, "RIGHT", 0, 0)
    f.progressBar:SetProgress(1)

    -- Map grid container
    local gridTop = -76
    local gridFrame = CreateFrame("Frame", nil, f)
    gridFrame:SetPoint("TOPLEFT", 12, gridTop)
    gridFrame:SetPoint("RIGHT", -12, 0)
    gridFrame:SetHeight(MAP_BTN_H * 4 + MAP_BTN_PAD * 3)
    f.gridFrame = gridFrame

    -- Map tiles (shared CreateMapTile primitive: real map art + banned/picked/selected
    -- states). 20 covers the largest arena pool with headroom; RefreshVetoUI grows the
    -- grid + window height when the live pool needs more than 4 rows.
    for i = 1, 20 do
        local tile = WG.CreateMapTile(gridFrame, { width = MAP_BTN_W, height = MAP_BTN_H, fontSize = 10 })
        local row = math.floor((i - 1) / MAPS_PER_ROW)
        local col = (i - 1) % MAPS_PER_ROW
        tile:SetPoint("TOPLEFT", col * (MAP_BTN_W + MAP_BTN_PAD), -(row * (MAP_BTN_H + MAP_BTN_PAD)))

        -- Center the label (no favorite star in veto, so the full width is free)
        tile._label:ClearAllPoints()
        tile._label:SetPoint("BOTTOMLEFT", 4, 5)
        tile._label:SetPoint("BOTTOMRIGHT", -4, 5)
        tile._label:SetJustifyH("CENTER")

        tile:SetScript("OnClick", function(self)
            if self._mapName and self:IsEnabled() then
                WG.VetoAction(self._mapName)
            end
        end)
        tile:SetScript("OnEnter", function(self)
            if self:IsEnabled() and not self._chosen then self:SetSelected(true) end
        end)
        tile:SetScript("OnLeave", function(self)
            if not self._chosen then self:SetSelected(false) end
        end)

        tile:Hide()
        mapButtons[i] = tile
    end

    -- Series panel (Bo3/Bo5): a horizontal row of bordered cells — resolved maps show a
    -- green check + name, pending maps show a muted placeholder.
    f.seriesPanel = CreateFrame("Frame", nil, f)
    f.seriesPanel:SetPoint("BOTTOMLEFT", 12, 46)
    f.seriesPanel:SetPoint("RIGHT", -12, 0)
    f.seriesPanel:SetHeight(30)
    f.seriesPanel:Hide()

    local seriesLabel = f.seriesPanel:CreateFontString(nil, "OVERLAY")
    seriesLabel:SetFont(ADDON_FONT, 9, "OUTLINE")
    seriesLabel:SetPoint("LEFT", 0, 0)
    seriesLabel:SetText(L["VETO_SERIES_LABEL"])
    seriesLabel:SetTextColor(unpack(theme.headerColor))
    WG.RegisterThemedElement(seriesLabel, function(fs)
        fs:SetTextColor(unpack(WG.GetActiveTheme().headerColor))
    end)

    for i = 1, 5 do
        local slot = CreateFrame("Frame", nil, f.seriesPanel, "BackdropTemplate")
        slot:SetHeight(24)
        slot:SetBackdrop(WG.FLAT_BACKDROP)
        local function PaintSlot()
            local th = WG.GetActiveTheme()
            slot:SetBackdropColor(unpack(th.cardBg))
            slot:SetBackdropBorderColor(unpack(th.cardBorder))
        end
        PaintSlot()
        WG.RegisterThemedElement(slot, PaintSlot)

        slot.check = slot:CreateTexture(nil, "OVERLAY")
        slot.check:SetSize(12, 12)
        slot.check:SetPoint("LEFT", 5, 0)
        slot.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        slot.check:Hide()

        slot.text = slot:CreateFontString(nil, "OVERLAY")
        slot.text:SetFont(ADDON_FONT, 10)
        slot.text:SetPoint("LEFT", 6, 0)
        slot.text:SetPoint("RIGHT", -4, 0)
        slot.text:SetJustifyH("LEFT")
        slot.text:SetWordWrap(false)
        slot.text:SetTextColor(unpack(theme.footerColor))
        slot:Hide()
        seriesSlots[i] = slot
    end

    -- Ready button (bottom-right, per the mockup's footer)
    f.readyBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.readyBtn:SetSize(180, 30)
    f.readyBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    f.readyBtn:SetText(L["VETO_READY"])
    WG.StyleButton(f.readyBtn)
    f.readyBtn:SetScript("OnClick", function()
        local s = WG.vetoSession
        if not s or WG.vetoState ~= "resolved" then return end
        s.myReady = true
        WG.SendV2("VETO_READY", s.opponent)
        if s.theirReady then
            WG.VetoLaunchChallenge()
        else
            WG.RefreshVetoUI()
        end
    end)
    f.readyBtn:Hide()

    -- Slaughterhouse entry point: lets players jump from an in-progress
    -- veto straight into the toon-declaration draft against the same opponent.
    f.slaughterBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.slaughterBtn:SetSize(150, 22)
    f.slaughterBtn:SetPoint("BOTTOMLEFT", 12, 12)
    f.slaughterBtn:SetText(L["SLAUGHTER_TITLE"])
    WG.StyleButton(f.slaughterBtn)
    f.slaughterBtn:SetScript("OnClick", function()
        if WG.ToggleSlaughterHouse then WG.ToggleSlaughterHouse() end
    end)

    f:Hide()
    vetoFrame = f
    return f
end

function WG.ShowVetoFrame()
    if not vetoFrame then CreateVetoFrame() end
    vetoFrame:Show()
    WG.RefreshVetoUI()
end

-- ---------- VETO HISTORY HELPER (for tracker) ----------
function WG.GetVetoHistory(opponentName)
    if not WG_History.vetoHistory then return nil end
    return WG_History.vetoHistory[opponentName]
end

-- ================================================================
-- DEBUG TEST MODE
-- Usage: /run WargamesPlus.VetoTest("Bo1")
--        /run WargamesPlus.VetoTest("Bo3")
--        /run WargamesPlus.VetoTest("Bo5")
-- Simulates a full veto session locally. You play BOTH sides.
-- Every turn is yours — click a map to ban/pick, alternating
-- between "initiator" and "opponent" roles each turn.
-- No comms are sent, no opponent is needed.
-- ================================================================

local testMode = false

function WG.VetoTest(format)
    format = format or "Bo1"
    if format ~= "Bo1" and format ~= "Bo3" and format ~= "Bo5" then
        print("|cffff6060[VetoTest]|r Invalid format. Use Bo1, Bo3, or Bo5.")
        return
    end

    -- Cancel any existing veto
    if WG.vetoState then
        WG.vetoState = nil
        WG.vetoSession = nil
        if vetoFrame then vetoFrame:Hide() end
    end

    -- Use the live arena pool as test maps (skip index 1 = "Random Map"), so the
    -- test covers every shipped arena map rather than a stale hardcoded subset.
    local mapPool = {}
    local arena = WG.ARENA_LIST or {}
    for j = 2, #arena do
        table.insert(mapPool, arena[j])
    end
    if #mapPool == 0 then
        mapPool = {
            "Nagrand Arena", "Blade's Edge Arena", "Ruins of Lordaeron",
            "Dalaran Arena", "Ring of Valor", "Tol'viron Arena", "Tiger's Peak",
            "Ashamane's Fall", "Black Rook Hold Arena", "Hook Point",
            "Mugambala", "Maldraxxus Coliseum", "Nokhudon Proving Grounds",
        }
    end

    local minPool = MIN_POOL[format] or 3
    if #mapPool < minPool then
        print("|cffff6060[VetoTest]|r Not enough maps for " .. format)
        return
    end

    testMode = true

    local turnOrder = BuildTurnOrder(format, #mapPool)
    WG.vetoState = "active"
    WG.vetoSession = {
        opponent = "TestOpponent",
        format = format,
        mapPool = mapPool,
        bannedMaps = {},
        pickedMaps = {},
        pickedOrder = {},
        banLog = {},
        turnOrder = turnOrder,
        currentTurn = 1,
        isInitiator = true,  -- starts as initiator, flips each turn
        myReady = false,
        theirReady = false,
        _testMode = true,
    }

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. "[VetoTest]|r Started " .. format .. " test veto with " .. #mapPool .. " maps, " .. #turnOrder .. " turns.")
    print("|cff" .. t.inlineAccent .. "[VetoTest]|r You play both sides. Click maps to ban/pick.")

    WG.ShowVetoFrame()
end

-- Override VetoAction in test mode: player controls both sides
local OrigVetoAction = WG.VetoAction
WG.VetoAction = function(mapName)
    local s = WG.vetoSession
    if not s or not s._testMode then
        return OrigVetoAction(mapName)
    end

    -- In test mode, every turn is clickable regardless of role
    if WG.vetoState ~= "active" then return end
    if s.bannedMaps[mapName] or s.pickedMaps[mapName] then return end

    local turn = s.turnOrder[s.currentTurn]
    if not turn then return end

    local role = turn.player  -- use the real role for this turn
    local roleName = role == "initiator" and "You" or "Opponent"
    local t = WG.GetActiveTheme()

    if turn.action == "ban" then
        s.bannedMaps[mapName] = role
        table.insert(s.banLog, {map = mapName, player = role, action = "ban"})
        print("|cff" .. t.inlineAccent .. "[VetoTest]|r " .. roleName .. " banned |cff" .. t.inlineLoss .. mapName .. "|r  (turn " .. s.currentTurn .. "/" .. #s.turnOrder .. ")")
    else
        s.pickedMaps[mapName] = role
        table.insert(s.pickedOrder, mapName)
        table.insert(s.banLog, {map = mapName, player = role, action = "pick"})
        print("|cff" .. t.inlineAccent .. "[VetoTest]|r " .. roleName .. " picked |cff" .. t.inlineGreen .. mapName .. "|r  (turn " .. s.currentTurn .. "/" .. #s.turnOrder .. ")")
    end

    s.currentTurn = s.currentTurn + 1

    if s.currentTurn > #s.turnOrder then
        ResolveVeto()
        -- In test mode, auto-set theirReady so clicking Ready ends it
        if s then s.theirReady = true end
        print("|cff" .. t.inlineAccent .. "[VetoTest]|r Veto complete! Click Ready to finish.")
    else
        -- Update role display for next turn
        local nextTurn = s.turnOrder[s.currentTurn]
        local nextRole = nextTurn.player == "initiator" and "Your" or "Opponent's"
        local nextAction = nextTurn.action:upper()
        print("|cff" .. t.inlineAccent .. "[VetoTest]|r Next: " .. nextRole .. " turn to " .. nextAction)
        WG.RefreshVetoUI()
    end
end

-- In test mode, RefreshVetoUI needs to always enable buttons (player controls both sides)
local OrigRefreshVetoUI = WG.RefreshVetoUI
WG.RefreshVetoUI = function()
    OrigRefreshVetoUI()

    local s = WG.vetoSession
    if not s or not s._testMode or WG.vetoState ~= "active" then return end
    if not vetoFrame or not vetoFrame:IsShown() then return end

    local t = WG.GetActiveTheme()

    -- Override status text to show whose turn it is
    local turn = s.turnOrder[s.currentTurn]
    if turn then
        local roleName = turn.player == "initiator" and "YOUR" or "OPPONENT'S"
        local actionColor = turn.action == "ban" and t.inlineLoss or t.inlineGreen
        vetoFrame.statusText:SetText("|cff" .. actionColor .. roleName .. " TURN — " .. turn.action:upper() .. " a map|r  |cffaaaaaa(test mode)|r")
    end

    -- Enable all available map buttons
    for i, btn in ipairs(mapButtons) do
        local mapName = s.mapPool[i]
        if mapName and not s.bannedMaps[mapName] and not s.pickedMaps[mapName] then
            btn:SetEnabled(true)
        end
    end
end

-- Stop test mode on cancel/launch
local OrigCancelVeto = WG.CancelVeto
WG.CancelVeto = function()
    testMode = false
    OrigCancelVeto()
end

local OrigVetoLaunchChallenge = WG.VetoLaunchChallenge
WG.VetoLaunchChallenge = function()
    local s = WG.vetoSession
    local isTest = s and s._testMode
    if isTest then
        -- In test mode, just print result and clean up (don't try to select map)
        local picks = GetPickedMapList()
        local remaining = GetRemainingMaps()
        local t = WG.GetActiveTheme()

        print("|cff" .. t.inlineAccent .. "[VetoTest]|r === VETO RESULT ===")
        if s.format == "Bo1" then
            local finalMap = remaining[1] or picks[1] or "?"
            print("|cff" .. t.inlineAccent .. "[VetoTest]|r Final map: |cff" .. t.inlineGreen .. finalMap .. "|r")
        else
            for i, m in ipairs(picks) do
                print("|cff" .. t.inlineAccent .. "[VetoTest]|r  Map " .. i .. ": |cff" .. t.inlineGreen .. m .. "|r")
            end
        end
        print("|cff" .. t.inlineAccent .. "[VetoTest]|r Ban log:")
        for _, entry in ipairs(s.banLog) do
            local role = entry.player == "initiator" and "You" or "Opponent"
            print("  " .. role .. " " .. entry.action .. ": " .. entry.map)
        end

        testMode = false
        WG.vetoState = nil
        WG.vetoSession = nil
        if vetoFrame then vetoFrame:Hide() end
    else
        OrigVetoLaunchChallenge()
    end
end
