-- dock.lua: WG+ Dock Mode — docks next to the default WoW Friends List
local WG = _G["WargamesPlus"]
local L = WG.L

local ADDON_FONT = WG.ADDON_FONT
local GAME_MODES = WG.GAME_MODES
local MAP_TEXTURES = WG.MAP_TEXTURES
local DOCK_WIDTH = 300
local DOCK_HEIGHT = 424

-- Game mode keys in display order, split by tab
local ARENA_MODES = {"ARENA_2V2", "ARENA_3V3", "ARENA_5V5", "SOLO_SHUFFLE"}
local BG_MODES = {"BG", "BLITZ"}
local MODE_LABELS = {
    ARENA_2V2 = "2v2", ARENA_3V3 = "3v3", ARENA_5V5 = "5v5",
    SOLO_SHUFFLE = "Shuffle", BG = "Normal", BLITZ = "Blitz",
}

local dockFrame  -- forward ref

-- ---------- HELPER: Get map list for current mode ----------
local function GetMapsForMode(gameModeKey)
    local gm = GAME_MODES[gameModeKey]
    if not gm then return {"Random Map"} end
    return WG.GetSortedMapList(gm.mapMode)
end

-- ---------- HELPER: Read selected BNet friend ----------
local function GetSelectedBNetFriend()
    if not FriendsFrame or not FriendsFrame:IsShown() then return nil end
    local friendType = FriendsFrame.selectedFriendType
    local idx = FriendsFrame.selectedFriend
    if not idx or idx < 1 then return nil end
    if friendType == 2 then -- FRIENDS_BUTTON_TYPE_BNET
        return C_BattleNet.GetFriendAccountInfo(idx)
    end
    return nil
end

-- ---------- HELPER: Create a thin accent separator line ----------
local function CreateSeparator(parent, yOffset)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("LEFT", 12, 0)
    line:SetPoint("RIGHT", -12, 0)
    line:SetPoint("TOP", 0, yOffset)
    local t = WG.GetActiveTheme()
    line:SetColorTexture(t.accent[1], t.accent[2], t.accent[3], 0.25)
    WG.RegisterThemedElement(line, function(tex)
        local th = WG.GetActiveTheme()
        tex:SetColorTexture(th.accent[1], th.accent[2], th.accent[3], 0.25)
    end)
    return line
end

-- ---------- HELPER: Create a styled toggle button for game modes ----------
local function CreateModeButton(parent, label, width, gameMode, dockState)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, 22)
    WG.StyleButton(btn)
    btn:SetText(label)
    btn:GetFontString():SetFont(ADDON_FONT, 9)
    btn._modeKey = gameMode

    local function UpdateHighlight()
        local t = WG.GetActiveTheme()
        if dockState.gameMode == gameMode then
            btn._active = true
            if btn._flatBg then btn._flatBg:SetColorTexture(unpack(t.selectionDim)) end
        else
            btn._active = false
            if btn._flatBg then btn._flatBg:SetColorTexture(unpack(t.buttonNormal)) end
        end
    end
    btn._updateHighlight = UpdateHighlight
    return btn
end

-- ---------- CREATE DOCK FRAME ----------
local function CreateDockFrame()
    if dockFrame then return dockFrame end

    local theme = WG.GetActiveTheme()
    local PAD = 12

    local f = CreateFrame("Frame", "WG_DockFrame", UIParent, "BackdropTemplate")
    f:SetSize(DOCK_WIDTH, DOCK_HEIGHT)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(100)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    WG.ApplyModernStyle(f)
    if WG.ApplyUIScale then WG.ApplyUIScale(f) end

    -- ====== CHROME (accent stripe + title + close) ======
    -- Standardized via CreateWindowChrome: fixes the title never being theme-reactive
    -- (it was baked into the text string as inline |cff hex instead of a real
    -- SetTextColor, so WG.OnThemeChanged had nothing to re-run) and the lowercase "x"
    -- close glyph that diverged from the rest of the addon's uppercase "X".
    local chrome = WG.CreateWindowChrome(f, {
        title = L["DOCK_TITLE"],
        titleSize = 13,
        closeSize = 16,
    })

    local logo = f:CreateTexture(nil, "ARTWORK")
    logo:SetSize(18, 18)
    logo:SetPoint("TOPLEFT", PAD, -8)
    logo:SetTexture("Interface\\AddOns\\Wargames\\media\\wglogo.blp")

    local title = chrome.title
    title:ClearAllPoints()
    title:SetPoint("LEFT", logo, "RIGHT", 6, 0)

    -- "Expand" — swap the dock for the full War Room window
    local expandBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    expandBtn:SetSize(66, 18)
    expandBtn:SetPoint("RIGHT", chrome.close, "LEFT", -6, 0)
    expandBtn:SetText(L["EXPAND"] or "Expand")
    expandBtn:GetFontString():SetFont(ADDON_FONT, 9, "OUTLINE")
    WG.StyleButton(expandBtn)
    expandBtn:SetScript("OnClick", function()
        f:Hide()
        if WG.ShowMainFrame then WG.ShowMainFrame() end
        PlaySound(856)
    end)

    CreateSeparator(f, -30)

    -- ====== SELECTED FRIEND CARD ======
    local card = CreateFrame("Frame", nil, f, "BackdropTemplate")
    card:SetPoint("TOPLEFT", PAD, -36)
    card:SetPoint("RIGHT", -PAD, 0)
    card:SetHeight(56)
    WG.ApplyModernStyle(card)

    -- Online status dot
    local statusDot = card:CreateTexture(nil, "OVERLAY")
    statusDot:SetSize(8, 8)
    statusDot:SetPoint("TOPLEFT", 10, -12)
    statusDot:SetColorTexture(0.4, 0.4, 0.4, 1) -- grey = no selection

    local friendName = card:CreateFontString(nil, "OVERLAY")
    friendName:SetFont(ADDON_FONT, 12, "OUTLINE")
    friendName:SetPoint("LEFT", statusDot, "RIGHT", 6, 0)
    friendName:SetTextColor(unpack(theme.normalText))
    friendName:SetText(L["DOCK_NO_FRIEND"])
    WG.RegisterThemedElement(friendName, function(fs) fs:SetTextColor(unpack(WG.GetActiveTheme().normalText)) end)
    f.friendName = friendName

    local charName = card:CreateFontString(nil, "OVERLAY")
    charName:SetFont(ADDON_FONT, 10)
    charName:SetPoint("TOPLEFT", statusDot, "BOTTOMLEFT", 6, -4)
    charName:SetTextColor(unpack(theme.headerColor))
    charName:SetText(L["DOCK_SELECT_FRIEND"])
    WG.RegisterThemedElement(charName, function(fs) fs:SetTextColor(unpack(WG.GetActiveTheme().headerColor)) end)
    f.charName = charName

    -- Refresh/Update button inside card
    local refreshBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    refreshBtn:SetSize(50, 18)
    refreshBtn:SetPoint("TOPRIGHT", -6, -6)
    refreshBtn:SetText(L["REFRESH"])
    refreshBtn:GetFontString():SetFont(ADDON_FONT, 8)
    WG.StyleButton(refreshBtn)

    f.selectedTarget = nil
    f.selectedBTag = nil

    local function UpdateFriendCard()
        local info = GetSelectedBNetFriend()
        if not info then
            friendName:SetText(L["DOCK_NO_FRIEND"])
            charName:SetText(L["DOCK_SELECT_FRIEND"])
            statusDot:SetColorTexture(0.4, 0.4, 0.4, 1)
            f.selectedTarget = nil
            f.selectedBTag = nil
            return
        end

        local t = WG.GetActiveTheme()
        local bTag = info.battleTag or ""
        local accName = info.accountName or bTag
        friendName:SetText("|cff" .. t.inlineBnet .. accName .. "|r")
        f.selectedBTag = bTag

        local ga = info.gameAccountInfo
        if ga and ga.characterName and ga.isOnline then
            local charStr = ga.characterName
            local r = ga.realmName or ""
            if r ~= "" then charStr = charStr .. "-" .. r:gsub("%s+", "") end
            charName:SetText("|cff" .. t.inlineChar .. charStr .. "|r")
            statusDot:SetColorTexture(0.2, 0.9, 0.2, 1) -- green = online
            f.selectedTarget = bTag ~= "" and bTag or charStr
        else
            charName:SetText("|cff" .. t.inlineLoss .. L["DOCK_NOT_ONLINE"] .. "|r")
            statusDot:SetColorTexture(0.6, 0.15, 0.15, 1) -- red = offline
            f.selectedTarget = nil
        end
    end

    refreshBtn:SetScript("OnClick", function() UpdateFriendCard(); PlaySound(856) end)
    f.UpdateFriendCard = UpdateFriendCard

    -- ====== GAME MODE SECTION ======
    CreateSeparator(f, -96)

    local modeHeader = f:CreateFontString(nil, "OVERLAY")
    modeHeader:SetFont(ADDON_FONT, 9, "OUTLINE")
    modeHeader:SetPoint("TOPLEFT", PAD, -102)
    modeHeader:SetText("GAME MODE")
    modeHeader:SetTextColor(unpack(theme.headerColor))
    WG.RegisterThemedElement(modeHeader, function(fs) fs:SetTextColor(unpack(WG.GetActiveTheme().headerColor)) end)

    f.gameMode = WG_History.dockMode.lastGameMode or "ARENA_3V3"
    f.modeButtons = {}

    -- Arena mode row
    local arenaRow = CreateFrame("Frame", nil, f)
    arenaRow:SetSize(DOCK_WIDTH - PAD * 2, 22)
    arenaRow:SetPoint("TOPLEFT", PAD, -116)

    local prevBtn = nil
    for _, key in ipairs(ARENA_MODES) do
        local btn = CreateModeButton(arenaRow, MODE_LABELS[key], 60, key, f)
        if not prevBtn then
            btn:SetPoint("LEFT", 0, 0)
        else
            btn:SetPoint("LEFT", prevBtn, "RIGHT", 3, 0)
        end
        table.insert(f.modeButtons, btn)
        prevBtn = btn
    end

    -- BG mode row
    local bgRow = CreateFrame("Frame", nil, f)
    bgRow:SetSize(DOCK_WIDTH - PAD * 2, 22)
    bgRow:SetPoint("TOPLEFT", PAD, -140)

    prevBtn = nil
    for _, key in ipairs(BG_MODES) do
        local btn = CreateModeButton(bgRow, MODE_LABELS[key], 60, key, f)
        if not prevBtn then
            btn:SetPoint("LEFT", 0, 0)
        else
            btn:SetPoint("LEFT", prevBtn, "RIGHT", 3, 0)
        end
        table.insert(f.modeButtons, btn)
        prevBtn = btn
    end

    local function UpdateAllModeButtons()
        for _, btn in ipairs(f.modeButtons) do
            btn._updateHighlight()
        end
    end

    for _, btn in ipairs(f.modeButtons) do
        btn:SetScript("OnClick", function()
            f.gameMode = btn._modeKey
            WG_History.dockMode.lastGameMode = btn._modeKey
            UpdateAllModeButtons()
            f:RefreshMapDropdown()
            f:UpdateMapPreview()
            PlaySound(856)
        end)
    end
    UpdateAllModeButtons()

    -- ====== MAP SECTION ======
    CreateSeparator(f, -166)

    local mapHeader = f:CreateFontString(nil, "OVERLAY")
    mapHeader:SetFont(ADDON_FONT, 9, "OUTLINE")
    mapHeader:SetPoint("TOPLEFT", PAD, -172)
    mapHeader:SetText("MAP")
    mapHeader:SetTextColor(unpack(theme.headerColor))
    WG.RegisterThemedElement(mapHeader, function(fs) fs:SetTextColor(unpack(WG.GetActiveTheme().headerColor)) end)

    local mapDrop = CreateFrame("Frame", "WG_DockMapDropdown", f, "UIDropDownMenuTemplate")
    mapDrop:SetPoint("TOPLEFT", PAD - 16, -184)
    UIDropDownMenu_SetWidth(mapDrop, DOCK_WIDTH - 50)
    WG.StyleDropdown(mapDrop)
    f.mapDrop = mapDrop
    f.selectedMap = "Random Map"

    -- Map preview thumbnail
    local mapPreview = CreateFrame("Frame", nil, f, "BackdropTemplate")
    mapPreview:SetSize(DOCK_WIDTH - PAD * 2, 70)
    mapPreview:SetPoint("TOPLEFT", PAD, -214)
    WG.ApplyModernStyle(mapPreview)

    local mapTex = mapPreview:CreateTexture(nil, "ARTWORK")
    mapTex:SetPoint("TOPLEFT", 1, -1)
    mapTex:SetPoint("BOTTOMRIGHT", -1, 1)
    mapTex:SetTexCoord(0, 1, 0.15, 0.85) -- crop for widescreen look

    local mapOverlay = mapPreview:CreateTexture(nil, "OVERLAY")
    mapOverlay:SetAllPoints(mapTex)
    mapOverlay:SetColorTexture(0, 0, 0, 0.3) -- subtle darkening overlay

    local mapNameText = mapPreview:CreateFontString(nil, "OVERLAY")
    mapNameText:SetFont(ADDON_FONT, 11, "OUTLINE")
    mapNameText:SetPoint("BOTTOMLEFT", 6, 6)
    mapNameText:SetTextColor(1, 1, 1, 0.9)

    -- "No preview" fallback text
    local noPreviewText = mapPreview:CreateFontString(nil, "OVERLAY")
    noPreviewText:SetFont(ADDON_FONT, 10)
    noPreviewText:SetPoint("CENTER")
    noPreviewText:SetTextColor(unpack(theme.footerColor))
    noPreviewText:SetText("Select a map")
    WG.RegisterThemedElement(noPreviewText, function(fs) fs:SetTextColor(unpack(WG.GetActiveTheme().footerColor)) end)

    function f:UpdateMapPreview()
        local mapName = f.selectedMap
        if mapName == "Random Map" then
            mapTex:SetTexture(nil)
            mapOverlay:Hide()
            mapNameText:SetText("")
            noPreviewText:SetText("Random Map")
            noPreviewText:Show()
            return
        end
        local texPath = MAP_TEXTURES and MAP_TEXTURES[mapName]
        if texPath then
            mapTex:SetTexture(texPath)
            mapOverlay:Show()
            mapNameText:SetText(mapName)
            noPreviewText:Hide()
        else
            mapTex:SetTexture(nil)
            mapOverlay:Hide()
            mapNameText:SetText("")
            noPreviewText:SetText(mapName)
            noPreviewText:Show()
        end
    end

    function f:RefreshMapDropdown()
        local maps = GetMapsForMode(f.gameMode)
        local found = false
        for _, m in ipairs(maps) do
            if m == f.selectedMap then found = true; break end
        end
        if not found then f.selectedMap = "Random Map" end
        UIDropDownMenu_SetText(mapDrop, f.selectedMap)

        UIDropDownMenu_Initialize(mapDrop, function(_, level)
            for _, mapName in ipairs(maps) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = mapName
                info.func = function()
                    f.selectedMap = mapName
                    UIDropDownMenu_SetText(mapDrop, mapName)
                    f:UpdateMapPreview()
                    CloseDropDownMenus()
                end
                info.checked = (mapName == f.selectedMap)
                UIDropDownMenu_AddButton(info)
            end
        end)
    end
    f:RefreshMapDropdown()
    f:UpdateMapPreview()

    -- ====== OPTIONS ROW ======
    CreateSeparator(f, -290)

    local optY = -298

    -- Tournament Rules
    local tourneyCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    tourneyCheck:SetSize(20, 20)
    tourneyCheck:SetPoint("TOPLEFT", PAD, optY)
    tourneyCheck:SetChecked(WG_History.dockMode.tournamentRules or WG_History.tournamentRules ~= false)
    tourneyCheck:SetScript("OnClick", function(self)
        WG_History.dockMode.tournamentRules = self:GetChecked()
        PlaySound(self:GetChecked() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    end)
    f.tourneyCheck = tourneyCheck

    local tourneyLabel = f:CreateFontString(nil, "OVERLAY")
    tourneyLabel:SetFont(ADDON_FONT, 9)
    tourneyLabel:SetPoint("LEFT", tourneyCheck, "RIGHT", 1, 0)
    tourneyLabel:SetText(L["TOURNAMENT_RULES"])
    tourneyLabel:SetTextColor(unpack(theme.normalText))
    WG.RegisterThemedElement(tourneyLabel, function(fs) fs:SetTextColor(unpack(WG.GetActiveTheme().normalText)) end)

    -- Spectator toggle button
    local specBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    specBtn:SetSize(75, 20)
    specBtn:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
    specBtn:SetPoint("TOP", 0, optY)
    specBtn:SetText(L["DOCK_SPECTATOR_TOGGLE"])
    specBtn:GetFontString():SetFont(ADDON_FONT, 9)
    WG.StyleButton(specBtn)
    f.spectatorMode = WG_History.dockMode.spectatorMode or false
    f.specBtn = specBtn

    -- ====== SPECTATOR SECTION ======
    local specSection = CreateFrame("Frame", nil, f)
    specSection:SetSize(DOCK_WIDTH - PAD * 2, 64)
    specSection:SetPoint("TOPLEFT", PAD, optY - 26)
    f.specSection = specSection

    local function MakeLeaderRow(parent, labelText, yOff)
        local lbl = parent:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(ADDON_FONT, 9)
        lbl:SetPoint("TOPLEFT", 0, yOff)
        lbl:SetText(labelText)
        lbl:SetTextColor(unpack(theme.headerColor))
        WG.RegisterThemedElement(lbl, function(fs) fs:SetTextColor(unpack(WG.GetActiveTheme().headerColor)) end)

        local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        edit:SetSize(150, 20)
        edit:SetPoint("LEFT", lbl, "RIGHT", 4, 0)
        edit:SetAutoFocus(false)
        WG.StyleInput(edit)

        local selBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        selBtn:SetSize(45, 18)
        selBtn:SetPoint("LEFT", edit, "RIGHT", 3, 0)
        selBtn:SetText(L["DOCK_UPDATE"])
        selBtn:GetFontString():SetFont(ADDON_FONT, 8)
        WG.StyleButton(selBtn)
        selBtn:SetScript("OnClick", function()
            local info = GetSelectedBNetFriend()
            if info then
                local ga = info.gameAccountInfo
                if ga and ga.characterName and ga.isOnline then
                    local charStr = ga.characterName
                    local r = ga.realmName or ""
                    if r ~= "" then charStr = charStr .. "-" .. r:gsub("%s+", "") end
                    edit:SetText(info.battleTag or charStr)
                end
            end
        end)
        return edit
    end

    local ldr1Edit = MakeLeaderRow(specSection, L["DOCK_LEADER_1"], 0)
    local ldr2Edit = MakeLeaderRow(specSection, L["DOCK_LEADER_2"], -28)
    f.ldr1Edit = ldr1Edit
    f.ldr2Edit = ldr2Edit

    local function UpdateSpectatorUI()
        local t = WG.GetActiveTheme()
        if f.spectatorMode then
            specSection:Show()
            specBtn._active = true
            if specBtn._flatBg then specBtn._flatBg:SetColorTexture(unpack(t.selectionDim)) end
            -- Grow the frame to accommodate spectator inputs
            f:SetHeight(DOCK_HEIGHT + 70)
        else
            specSection:Hide()
            specBtn._active = false
            if specBtn._flatBg then specBtn._flatBg:SetColorTexture(unpack(t.buttonNormal)) end
            f:SetHeight(DOCK_HEIGHT)
        end
    end

    specBtn:SetScript("OnClick", function()
        f.spectatorMode = not f.spectatorMode
        WG_History.dockMode.spectatorMode = f.spectatorMode
        UpdateSpectatorUI()
        PlaySound(856)
    end)
    UpdateSpectatorUI()

    -- ====== SEND CHALLENGE BUTTON ======
    local challengeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    challengeBtn:SetSize(DOCK_WIDTH - PAD * 2, 34)
    challengeBtn:SetPoint("BOTTOM", 0, 28)
    WG.StyleButton(challengeBtn)
    challengeBtn._hasInlineColor = true

    local function UpdateChallengeText()
        local t = WG.GetActiveTheme()
        if f.spectatorMode then
            challengeBtn:SetText("|cff" .. t.inlineAccent .. L["SPECTATE_MATCH"]:upper() .. "|r")
        else
            challengeBtn:SetText("|cff" .. t.inlineAccent .. L["SEND_CHALLENGE"]:upper() .. "|r")
        end
    end
    UpdateChallengeText()
    WG.RegisterThemedElement(challengeBtn, function() UpdateChallengeText() end)

    challengeBtn:SetScript("OnClick", function()
        local tournRules = tourneyCheck:GetChecked()
        if f.spectatorMode then
            WG.SendChallengeByParams({
                gameMode = f.gameMode,
                mapName = f.selectedMap,
                tournamentRules = tournRules,
                spectator = true,
                leader1 = ldr1Edit:GetText():trim(),
                leader2 = ldr2Edit:GetText():trim(),
            })
        else
            if not f.selectedTarget then
                local t = WG.GetActiveTheme()
                print("|cff" .. t.inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["DOCK_NO_FRIEND"])
                return
            end
            WG.SendChallengeByParams({
                target = f.selectedTarget,
                gameMode = f.gameMode,
                mapName = f.selectedMap,
                tournamentRules = tournRules,
                spectator = false,
            })
        end
    end)

    -- ====== FOOTER ======
    local footer = f:CreateFontString(nil, "OVERLAY")
    footer:SetFont(ADDON_FONT, 8)
    footer:SetPoint("BOTTOM", 0, 10)
    local function UpdateFooter()
        local t = WG.GetActiveTheme()
        footer:SetText("|cff" .. t.inlineAccent .. "WG+|r Dock Mode")
    end
    UpdateFooter()
    footer:SetTextColor(unpack(theme.footerColor))
    WG.RegisterThemedElement(footer, function(fs)
        local t = WG.GetActiveTheme()
        fs:SetTextColor(unpack(t.footerColor))
        UpdateFooter()
    end)

    -- ====== EVENT HANDLING ======
    f:SetScript("OnShow", function(self)
        self:RegisterEvent("BN_FRIEND_INFO_CHANGED")
        -- Open FriendsFrame if not visible
        if not FriendsFrame or not FriendsFrame:IsShown() then
            ToggleFriendsFrame()
        end
        -- Position next to FriendsFrame
        self:ClearAllPoints()
        if FriendsFrame and FriendsFrame:IsShown() then
            self:SetPoint("TOPLEFT", FriendsFrame, "TOPRIGHT", 2, 0)
        else
            self:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
        end
        UpdateFriendCard()
        UpdateAllModeButtons()
        self:UpdateMapPreview()
    end)

    f:SetScript("OnHide", function(self)
        self:UnregisterEvent("BN_FRIEND_INFO_CHANGED")
    end)

    f:SetScript("OnEvent", function(self, event)
        if event == "BN_FRIEND_INFO_CHANGED" then
            UpdateFriendCard()
        end
    end)

    -- Reposition when FriendsFrame moves or shows
    if FriendsFrame then
        hooksecurefunc(FriendsFrame, "Show", function()
            if f:IsShown() then
                f:ClearAllPoints()
                f:SetPoint("TOPLEFT", FriendsFrame, "TOPRIGHT", 2, 0)
            end
        end)
    end

    f:Hide()
    dockFrame = f
    return f
end

-- ---------- TOGGLE ----------
function WG.ToggleDock()
    local f = dockFrame or CreateDockFrame()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
    end
end
