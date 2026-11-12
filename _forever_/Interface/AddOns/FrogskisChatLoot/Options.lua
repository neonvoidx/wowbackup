local ADDON, ns = ...

local panel

local QUALITY_COLORS = {
    [0] = "9d9d9d",
    "ffffff",
    "1eff00",
    "0070dd",
    "a335ee",
    "ff8000"
}

---------------------------------------------------------------------------
-- Dialogs
---------------------------------------------------------------------------

StaticPopupDialogs["FROGSKISCHATLOOT_RESTORE_DEFAULTS"] = {
    text = "Restore the settings of the profile \"%s\" and of the History window to their defaults?\n\nYour loot history and your other profiles are kept.",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        ns.RestoreDefaults()
        ns.RefreshOptions()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

StaticPopupDialogs["FROGSKISCHATLOOT_NUKE_ALL"] = {
    text = "Reset ALL settings to their defaults?\n\nEvery profile you made is deleted, the ready-made ones start again from their defaults, and the automation of every character starts again too. Your remembered loot history is kept. This cannot be undone.",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        ns.NukeAll()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

StaticPopupDialogs["FROGSKISCHATLOOT_CLEAR_HISTORY"] = {
    text = "Delete all remembered loot history?\n\nThis cannot be undone.",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        for _, W in ipairs(ns.ActiveWindows()) do
            ns.ClearHistory(W)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

-- One popup with a text box asks for a profile name (data = { initial, apply }).
StaticPopupDialogs["FROGSKISCHATLOOT_PROFILE_NAME"] = {
    text = "%s",
    button1 = ACCEPT or "Accept",
    button2 = CANCEL or "Cancel",
    hasEditBox = 1,
    editBoxWidth = 260,
    OnShow = function(self, data)
        local eb = self.editBox or self.EditBox
        if eb then
            eb:SetMaxLetters(data and data.max or 24)
            eb:SetText(data and data.initial or "")
            eb:HighlightText()
            eb:SetFocus()
        end
    end,
    OnAccept = function(self, data)
        local eb = self.editBox or self.EditBox
        if eb and data then
            data.apply(strtrim(eb:GetText() or ""))
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        StaticPopupDialogs["FROGSKISCHATLOOT_PROFILE_NAME"].OnAccept(parent, parent.data)
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

StaticPopupDialogs["FROGSKISCHATLOOT_PROFILE_DELETE"] = {
    text = "Delete the profile \"%s\"?\n\nCharacters and places that used it fall back to another profile. This cannot be undone.",
    button1 = YES,
    button2 = NO,
    OnAccept = function(_, name)
        ns.DeleteProfile(name)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

local function AskName(text, initial, apply, max)
    StaticPopup_Show("FROGSKISCHATLOOT_PROFILE_NAME", text, nil, {
        initial = initial,
        apply = apply,
        max = max
    })
end

---------------------------------------------------------------------------
-- Widgets. Every widget has a Refresh that reads its value again; the page it sits on keeps the list.
---------------------------------------------------------------------------

local function MakeCheck(parent, label, x, y, get, set)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetSize(24, 24)
    cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb.text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cb.text:SetText(label)
    cb:SetScript("OnClick", function(self)
        set(self:GetChecked() and true or false)
        ns.Refresh()
    end)
    cb.Refresh = function(self)
        self:SetChecked(get())
    end
    parent.widgets[#parent.widgets + 1] = cb
    return cb
end

local function MakeQualityCheck(parent, q, x, y)
    local cb = MakeCheck(parent, "", x, y, function()
        return ns.db.qualities[q]
    end, function(v)
        ns.db.qualities[q] = v
    end)
    local names = {
        [0] = "Poor",
        "Common",
        "Uncommon",
        "Rare",
        "Epic",
        "Legendary"
    }
    cb.text:SetText("|cff" .. QUALITY_COLORS[q] .. names[q] .. "|r")
    return cb
end

local function MakeHeader(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

-- Small grey explanation; wraps at `width`.
local function Hint(parent, text, x, y, width)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetWidth(width)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    return fs
end

-- Number text box with an OK button; the value is applied on OK or Enter.
local function MakeNumberBox(parent, label, x, y, field, labelW, boxW, min, max)
    labelW = labelW or 146
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(label)

    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetPoint("TOPLEFT", x + labelW, y + 5)
    box:SetSize(boxW or 60, 20)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetMaxLetters(4)

    local function Apply()
        local v = tonumber(box:GetText()) or min or 0
        ns.db[field] = math.max(min or 0, math.min(max or 9999, v))
        box:SetText(ns.db[field])
        box:ClearFocus()
        ns.Refresh()
    end

    local ok = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    ok:SetSize(50, 22)
    ok:SetPoint("LEFT", box, "RIGHT", 8, 0)
    ok:SetText("OK")
    ok:SetScript("OnClick", Apply)

    box:SetScript("OnEnterPressed", Apply)
    box:SetScript("OnEscapePressed", function(self)
        self:SetText(ns.db[field])
        self:ClearFocus()
    end)
    box.Refresh = function(self)
        self:SetText(ns.db[field])
    end
    parent.widgets[#parent.widgets + 1] = box
    return box
end

-- Short text box with its label on the left and an OK button; applied on OK, on Enter or when it loses focus.
local function MakeTextBox(parent, label, x, y, field, labelW, boxW)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(label)

    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetPoint("TOPLEFT", x + labelW, y + 5)
    box:SetSize(boxW, 20)
    box:SetAutoFocus(false)
    box:SetMaxLetters(20)
    box:SetScript("OnEnterPressed", box.ClearFocus)
    box:SetScript("OnEscapePressed", function(self)
        self:SetText(ns.db[field])
        self:ClearFocus()
    end)
    box:SetScript("OnEditFocusLost", function(self)
        ns.db[field] = self:GetText()
        ns.Refresh()
    end)

    local ok = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    ok:SetSize(50, 22)
    ok:SetPoint("LEFT", box, "RIGHT", 8, 0)
    ok:SetText("OK")
    ok:SetScript("OnClick", function()
        if box:HasFocus() then
            box:ClearFocus() -- letting go of the box applies the text
        elseif ns.db[field] ~= box:GetText() then
            ns.db[field] = box:GetText()
            ns.Refresh()
        end
    end)
    box.Refresh = function(self)
        self:SetText(ns.db[field]);
        self:SetCursorPosition(0)
    end
    parent.widgets[#parent.widgets + 1] = box
    return box
end

-- Blizzard's own dropdown (the same one the game's settings use).
local function MakeDropdown(parent, x, y, width, setup)
    local dd = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dd:SetPoint("TOPLEFT", x, y)
    dd:SetWidth(width)
    dd:SetupMenu(setup)
    return dd
end

-- The colors are kept as hex text ("rrggbb"); the game's color picker works with 0 - 1 numbers.
local function HexToRGB(hex)
    if type(hex) ~= "string" or not hex:match("^%x%x%x%x%x%x$") then
        hex = "888888"
    end
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

local function RGBToHex(r, g, b)
    local function Byte(v)
        return math.floor(math.max(0, math.min(1, v)) * 255 + 0.5)
    end
    return ("%02x%02x%02x"):format(Byte(r), Byte(g), Byte(b))
end

-- The lines are drawn again a moment after the last change, not on every step of the picker.
local colorRefreshQueued
local function QueueColorRefresh()
    if colorRefreshQueued then
        return
    end
    colorRefreshQueued = true
    C_Timer.After(0.1, function()
        colorRefreshQueued = false
        ns.Refresh()
    end)
end

-- A small square in the color of a line's text; a click opens the game's color picker.
local function MakeColorSwatch(parent, anchor, field, what)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", anchor, "RIGHT", 12, 0)
    label:SetText("Font color:")
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(22, 22)
    btn:SetPoint("LEFT", label, "RIGHT", 6, 0)
    local edge = btn:CreateTexture(nil, "BACKGROUND")
    edge:SetAllPoints()
    edge:SetColorTexture(0.62, 0.5, 0.28, 1)
    local back = btn:CreateTexture(nil, "BORDER")
    back:SetPoint("TOPLEFT", 1, -1)
    back:SetPoint("BOTTOMRIGHT", -1, 1)
    back:SetColorTexture(0, 0, 0, 1)
    local color = btn:CreateTexture(nil, "ARTWORK")
    color:SetPoint("TOPLEFT", 3, -3)
    color:SetPoint("BOTTOMRIGHT", -3, 3)

    btn.Refresh = function()
        color:SetColorTexture(HexToRGB(ns.db[field]))
    end
    btn:Refresh()

    local function Set(hex)
        if ns.db[field] == hex then
            return
        end
        ns.db[field] = hex
        btn:Refresh()
        QueueColorRefresh()
    end
    btn:SetScript("OnClick", function()
        local r, g, b = HexToRGB(ns.db[field])
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r,
            g = g,
            b = b,
            swatchFunc = function()
                Set(RGBToHex(ColorPickerFrame:GetColorRGB()))
            end,
            cancelFunc = function(previous)
                Set(RGBToHex(previous.r, previous.g, previous.b))
            end
        })
        ColorPickerFrame:Raise()
    end)
    btn:SetScript("OnEnter", function(self)
        edge:SetColorTexture(1, 0.82, 0, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Font color", 1, 1, 1)
        GameTooltip:AddLine("The color of the " .. what .. " line. Click to change it.", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        edge:SetColorTexture(0.62, 0.5, 0.28, 1)
        GameTooltip:Hide()
    end)
    parent.widgets[#parent.widgets + 1] = btn
    return btn
end

-- The chat stays at full opacity while a menu of this addon is displayed.
local function HoldMenu(menu)
    if menu and menu.SetClosedCallback then
        ns.SetChatHold("menu", true)
        menu:SetClosedCallback(function()
            ns.SetChatHold("menu", false)
        end)
    end
end

---------------------------------------------------------------------------
-- The window: a profile bar on top (always visible), three tabs, the buttons at the bottom.
---------------------------------------------------------------------------

local PAGE_TOP, PAGE_BOTTOM = 132, 56

local function NewPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", 0, -PAGE_TOP)
    page:SetPoint("BOTTOMRIGHT", 0, PAGE_BOTTOM)
    page.widgets = {}
    return page
end

local function SelectTab(key)
    panel.selectedTab = key
    for k, page in pairs(panel.pages) do
        page:SetShown(k == key)
    end
    for k, tab in pairs(panel.tabs) do
        tab:SetSelected(k == key)
    end
end

local function MakeTab(parent, key, label, index)
    local tab = CreateFrame("Button", nil, parent)
    tab:SetSize(112, 26)
    tab:SetPoint("TOPLEFT", 24 + (index - 1) * 118, -98)
    tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tab.text:SetPoint("CENTER", 0, 1)
    tab.text:SetText(label)
    -- each tab has its own glow (the gap between tabs stays empty); the open one is brighter
    tab.glow = tab:CreateTexture(nil, "BACKGROUND")
    tab.glow:SetAllPoints()
    tab.line = tab:CreateTexture(nil, "ARTWORK")
    tab.line:SetColorTexture(1, 0.82, 0, 1)
    tab.line:SetPoint("BOTTOMLEFT", 0, 0)
    tab.line:SetPoint("BOTTOMRIGHT", 0, 0)
    tab.line:SetHeight(2)
    local highlight = tab:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.08)
    function tab:SetSelected(on)
        self.line:SetShown(on)
        self.glow:SetColorTexture(1, 0.82, 0, on and 0.2 or 0.05)
        self.text:SetFontObject(on and "GameFontHighlight" or "GameFontNormal")
    end
    tab:SetScript("OnClick", function()
        SelectTab(key)
    end)
    return tab
end

local function OpenManageMenu(anchor)
    local menu = MenuUtil.CreateContextMenu(anchor, function(_, root)
        local name = ns.ActiveProfileName()
        root:CreateTitle("Profile \"" .. name .. "\"")
        root:CreateButton("New profile...", function()
            AskName("Name of the new profile (it starts with the default settings):", "", ns.NewProfile)
        end)
        root:CreateButton("Copy this profile...", function()
            AskName("Name of the copy of \"" .. name .. "\":", name .. " copy", ns.CopyProfile)
        end)
        root:CreateButton("Rename this profile...", function()
            AskName("New name for \"" .. name .. "\":", name, ns.RenameProfile)
        end)
        local delete = root:CreateButton("Delete this profile...", function()
            StaticPopup_Show("FROGSKISCHATLOOT_PROFILE_DELETE", name, nil, name)
        end)
        if #ns.GetProfiles() < 2 then
            delete:SetEnabled(false)
        end
        root:CreateDivider()
        root:CreateButton("Reset this profile to defaults...", function()
            StaticPopup_Show("FROGSKISCHATLOOT_RESTORE_DEFAULTS", name)
        end)
    end)
    HoldMenu(menu)
end

-- Everything on screen reads its value again (after a profile change, a reset ...).
local function RefreshAll()
    if not panel then
        return
    end
    for _, page in pairs(panel.pages) do
        for _, w in ipairs(page.widgets) do
            w:Refresh()
        end
    end
    panel.profileDD:GenerateMenu()
    local auto = ns.GetAuto()
    for _, row in ipairs(panel.rows) do
        row.dd:GenerateMenu()
        row.dd:SetEnabled(auto)
        row.label:SetFontObject(auto and "GameFontHighlight" or "GameFontDisable")
    end
    local scenario = ns.CurrentScenario()
end
ns.RefreshOptions = RefreshAll

local function BuildFiltersPage()
    local db = ns.db
    local page = NewPage(panel)
    panel.pages.filters = page

    -- left column: what is hidden
    -- a soft gold glow behind the binding section so it stands out
    local glow = page:CreateTexture(nil, "BACKGROUND")
    glow:SetPoint("TOPLEFT", 14, -2)
    glow:SetSize(312, 136)
    glow:SetColorTexture(1, 0.82, 0, 0.045)
    local edge = page:CreateTexture(nil, "BACKGROUND")
    edge:SetPoint("TOPLEFT", glow, "TOPLEFT", 0, 0)
    edge:SetPoint("BOTTOMLEFT", glow, "BOTTOMLEFT", 0, 0)
    edge:SetWidth(2)
    edge:SetColorTexture(1, 0.82, 0, 0.35)
    MakeHeader(page, "Show by binding", 24, -8)
    MakeCheck(page, "Soulbound", 24, -28, function()
        return db.showSoulbound
    end, function(v)
        db.showSoulbound = v
    end)
    MakeCheck(page, "Warbound", 140, -28, function()
        return db.showWarbound
    end, function(v)
        db.showWarbound = v
    end)
    MakeCheck(page, "Binds when equipped", 24, -54, function()
        return db.showBoE
    end, function(v)
        db.showBoE = v
    end)

    -- a sound when an item that binds when equipped drops: on or off, and which sound
    local soundCheck = MakeCheck(page, "Play a sound when one drops", 24, -80, function()
        return db.boeSound
    end, function(v)
        db.boeSound = v
    end)
    local soundDD = MakeDropdown(page, 40, -106, 170, function(_, root)
        for _, item in ipairs(ns.BOE_SOUNDS) do
            root:CreateRadio(item[2], function(id)
                return db.boeSoundId == id
            end, function(id)
                db.boeSoundId = id
                ns.PlayBoESound(id) -- hear it when it is picked
            end, item[1])
        end
        -- the sounds other addons put in the shared media list (LibSharedMedia-3.0), in a scrolling list of their own
        local media = _G.LibStub and _G.LibStub("LibSharedMedia-3.0", true)
        local names = {}
        for _, name in ipairs(media and media:List("sound") or {}) do
            if name ~= "None" then
                names[#names + 1] = name
            end
        end
        if #names > 0 then
            local more = root:CreateButton("Shared media sounds")
            more:SetScrollMode(400)
            for _, name in ipairs(names) do
                more:CreateRadio(name, function(n)
                    return db.boeSoundId == n
                end, function(n)
                    db.boeSoundId = n
                    ns.PlayBoESound(n) -- hear it when it is picked
                end, name)
            end
        end
    end)
    local preview = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    preview:SetSize(80, 24)
    preview:SetPoint("TOPLEFT", 218, -106)
    preview:SetText("Preview")
    preview:SetScript("OnClick", function()
        ns.PlayBoESound(db.boeSoundId)
    end)
    local baseCheckRefresh = soundCheck.Refresh
    soundCheck.Refresh = function(self)
        baseCheckRefresh(self)
        soundDD:GenerateMenu()
        soundDD:SetEnabled(db.boeSound and true or false)
        preview:SetEnabled(db.boeSound and true or false)
    end
    soundCheck:HookScript("OnClick", function()
        soundCheck:Refresh()
    end)

    MakeHeader(page, "Hide these item types", 24, -156)
    for i, entry in ipairs(ns.ITEM_CLASSES) do
        local classID = entry[1]
        MakeCheck(page, entry[2], 24, -176 - (i - 1) * 26, function()
            return db.hideClass[classID]
        end, function(v)
            db.hideClass[classID] = v or nil
        end)
    end

    -- right column: the rest
    MakeHeader(page, "Who", 340, -8)
    MakeCheck(page, "Show my loot", 340, -28, function()
        return db.showSelf
    end, function(v)
        db.showSelf = v
    end)
    MakeCheck(page, "Show other players' loot", 340, -54, function()
        return db.showOthers
    end, function(v)
        db.showOthers = v
    end)

    MakeHeader(page, "Quality", 340, -90)
    for q = 0, 5 do
        MakeQualityCheck(page, q, 340 + (q % 3) * 92, -110 - math.floor(q / 3) * 26)
    end
    MakeNumberBox(page, "Min gear item level:", 340, -172, "minItemLevel", 126)
    Hint(page, "Weapons and armor below this item level are hidden. 0 turns it off.", 340, -198, 270)

    MakeHeader(page, "Show these other lines", 340, -246)
    MakeCheck(page, "Trade, mail, vendor items", 340, -266, function()
        return db.showReceived
    end, function(v)
        db.showReceived = v
    end)
    MakeCheck(page, "Money (gold, silver, copper)", 340, -292, function()
        return db.showMoney
    end, function(v)
        db.showMoney = v
    end)
    MakeCheck(page, "Show it as: Name -> 3g 22s 84c", 358, -318, function()
        return db.moneyLines
    end, function(v)
        db.moneyLines = v
    end)
    MakeCheck(page, "Coin pictures instead of g s c", 358, -344, function()
        return db.moneyIcons
    end, function(v)
        db.moneyIcons = v
    end)
    MakeNumberBox(page, "Coin picture size:", 358, -374, "moneyIconSize", 130, 40, 6, 32)
    MakeNumberBox(page, "Coin picture lower:", 358, -400, "moneyIconDrop", 130, 40, 0, 12)
    local rolls = MakeCheck(page, "Loot rolls (need/greed/pass)", 340, -430, function()
        return db.showRolls
    end, function(v)
        db.showRolls = v
    end)
    rolls:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Loot rolls", 1, 1, 1)
        GameTooltip:AddLine(
            "While this is on, the loot line of whoever wins a roll is shown too, whatever the filters above say, so you can see who won.",
            nil, nil, nil, true)
        GameTooltip:Show()
    end)
    rolls:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    MakeCheck(page, "Crafting messages (creates...)", 340, -456, function()
        return db.showCrafts
    end, function(v)
        db.showCrafts = v
    end)
    MakeCheck(page, "Boss drops (what a boss drops)", 340, -482, function()
        return db.showDrops
    end, function(v)
        db.showDrops = v
    end)
    MakeCheck(page, "Draw lines from the boss to its items", 358, -508, function()
        return db.dropTree
    end, function(v)
        db.dropTree = v
    end)

    local allDrops = MakeCheck(page, "Show all its drops", 358, -534, function()
        return db.showAllDrops ~= false
    end, function(v)
        db.showAllDrops = v
    end)
    allDrops:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("All drops", 1, 1, 1)
        GameTooltip:AddLine(
            "The game lists only the items you can roll on. With this on, the other items of the kill are added from the loot history of the encounter.",
            nil, nil, nil, true)
        GameTooltip:Show()
    end)
    allDrops:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local lists = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    lists:SetSize(270, 24)
    lists:SetPoint("TOPLEFT", 340, -574)
    lists:SetText("Always hide / always show lists...")
    lists:SetScript("OnClick", function()
        ns.OpenItemLists("chat")
    end)
end

local function BuildDisplayPage()
    local db = ns.db
    local page = NewPage(panel)
    panel.pages.display = page

    MakeHeader(page, "Lines", 24, -8)
    local stamp = MakeCheck(page, "Timestamp", 24, -28, function()
        return db.timestamp
    end, function(v)
        db.timestamp = v
    end)
    -- Greyed out while another addon (Prat, ...) already stamps the chat lines.
    local baseRefresh = stamp.Refresh
    stamp.Refresh = function(self)
        baseRefresh(self)
        local external, source = ns.ExternalTimestamps()
        self:SetEnabled(not external)
        if external then
            self.text:SetText("|cff808080Timestamp (" .. source .. ")|r")
        else
            self.text:SetText("Timestamp")
        end
    end
    stamp:SetScript("OnEnter", function(self)
        local external, source = ns.ExternalTimestamps()
        if not external then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Timestamps are added by " .. source)
        GameTooltip:AddLine("This addon adds none of its own to the Loot window.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    stamp:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    MakeCheck(page, "Class colored names", 340, -28, function()
        return db.classColor
    end, function(v)
        db.classColor = v
    end)
    MakeCheck(page, "Show item level", 24, -54, function()
        return db.showItemLevel
    end, function(v)
        db.showItemLevel = v
    end)
    MakeCheck(page, "Show stack count", 340, -54, function()
        return db.showQuantity
    end, function(v)
        db.showQuantity = v
    end)

    MakeHeader(page, "Layout", 24, -96)
    MakeTextBox(page, "Separator:", 24, -122, "separator", 70, 90)
    MakeNumberBox(page, "Left margin (px):", 340, -122, "leftMargin", 110, 40)
    MakeCheck(page, "Show the dungeon / raid name", 340, -150, function()
        return db.instanceSeparator
    end, function(v)
        db.instanceSeparator = v
    end)
    MakeCheck(page, "Always show where it was looted", 340, -176, function()
        return db.zoneSeparator
    end, function(v)
        db.zoneSeparator = v
    end)
    -- long player names cut to a set width; the width can also be changed by dragging the "->" column in the chat
    MakeCheck(page, "Shorten long player names", 340, -202, function()
        return db.shortenNames
    end, function(v)
        db.shortenNames = v
    end)
    MakeNumberBox(page, "Longest name:", 358, -228, "nameMaxWidth", 96, 50, 30, 400)
    MakeCheck(page, "Align items in a column", 24, -150, function()
        return db.alignColumn
    end, function(v)
        db.alignColumn = v
    end)
    local dateCheck = MakeCheck(page, "Show the date between days (Monday 10-Oct-2026)", 24, -176, function()
        return db.dateSeparator
    end, function(v)
        db.dateSeparator = v
    end)
    -- wrapped, so it stays clear of the column on the right
    dateCheck.text:SetWidth(270)
    dateCheck.text:SetJustifyH("LEFT")
    MakeCheck(page, "One chat line per loot entry", 24, -208, function()
        return db.shortenItems
    end, function(v)
        db.shortenItems = v
    end)
    MakeCheck(page, "End cut names with ...", 24, -234, function()
        return db.nameEllipsis ~= false
    end, function(v)
        db.nameEllipsis = v
    end)

    MakeHeader(page, "Date and place lines", 24, -288)
    MakeNumberBox(page, "Indent (spaces):", 24, -314, "separatorIndent", 126, 60, 0, 30)
    -- the texture atlases added by hand (each with a red sign to take it out again) and the line that adds one
    local REMOVE_ATLAS = "GM-raidMarker-remove"
    local REMOVE_SIGN = "Interface\\PaperDollInfoFrame\\UI-GearManager-LeaveItem-Opaque" -- where a game version has no such atlas
    local ROOM = "|TInterface\\AddOns\\FrogskisChatLoot\\blank:1:22|t" -- keeps the text clear of the red sign
    local function AddCustomEntries(root, group, field)
        for _, name in ipairs(ns.CustomIcons(group, ns.db[field])) do
            local markup = ns.IconMarkup(name, 17, "raid")
            local radio = root:CreateRadio((markup and (markup .. " ") or "") .. name .. ROOM, function(k)
                return ns.db[field] == k
            end, function(k)
                ns.db[field] = k;
                ns.Refresh()
            end, name)
            radio:AddInitializer(function(button, _, menu)
                if not (MenuTemplates and MenuTemplates.AttachBasicButton) then
                    return
                end
                local remove = MenuTemplates.AttachBasicButton(button, 16, 16)
                remove:ClearAllPoints()
                remove:SetPoint("RIGHT", button, "RIGHT", -2, 0)
                if remove.SetNormalAtlas and C_Texture.GetAtlasInfo(REMOVE_ATLAS) then
                    remove:SetNormalAtlas(REMOVE_ATLAS)
                else
                    remove:SetNormalTexture(REMOVE_SIGN)
                end
                remove:SetScript("OnClick", function()
                    menu:Close()
                    ns.RemoveCustomIcon(group, field, name)
                end)
                remove:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Remove from the list", 1, 1, 1)
                    GameTooltip:Show()
                end)
                remove:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
            end)
        end
        root:CreateDivider()
        root:CreateButton("Add a texture atlas by name...", function()
            AskName("Name of the texture atlas to add, as the atlas viewer shows it (for example vignettekillboss):",
                "", function(name)
                    ns.AddCustomIcon(group, field, name)
                end, 80)
        end)
    end
    -- a little picture on either side of the text: which one, on which side, and how big
    local function IconChoice(x, y, list, field, sideField, scaleField, colorField, what, group)
        local dd = MakeDropdown(page, x, y + 6, 150, function(_, root)
            for _, item in ipairs(list) do
                local markup = ns.IconMarkup(item[1], 17, "raid")
                root:CreateRadio((markup and (markup .. " ") or "") .. item[2], function(k)
                    return ns.db[field] == k
                end, function(k)
                    ns.db[field] = k;
                    ns.Refresh()
                end, item[1])
            end
            AddCustomEntries(root, group, field)
        end)
        local side = MakeDropdown(page, x + 156, y + 6, 76, function(_, root)
            for _, item in ipairs({{"left", "Left"}, {"right", "Right"}}) do
                root:CreateRadio(item[2], function(k)
                    return ns.db[sideField] == k
                end, function(k)
                    ns.db[sideField] = k;
                    ns.Refresh()
                end, item[1])
            end
        end)
        -- how big the picture is, 50% to 150% of its normal size
        local size = MakeDropdown(page, x + 238, y + 6, 70, function(_, root)
            for step = 5, 15 do
                root:CreateRadio(("%d%%"):format(step * 10), function(v)
                    return math.abs((ns.db[scaleField] or 1) - v) < 0.001
                end, function(v)
                    ns.db[scaleField] = v;
                    ns.Refresh()
                end, step / 10)
            end
        end)
        size:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Icon size", 1, 1, 1)
            GameTooltip:AddLine("Compared to the normal size, from 50% to 150%.", nil, nil, nil, true)
            GameTooltip:Show()
        end)
        size:HookScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        MakeColorSwatch(page, size, colorField, what)
        dd.Refresh = function(self)
            self:GenerateMenu()
        end
        side.Refresh = dd.Refresh
        size.Refresh = dd.Refresh
        page.widgets[#page.widgets + 1] = dd
        page.widgets[#page.widgets + 1] = side
        page.widgets[#page.widgets + 1] = size
    end
    local function IconRow(y, label, list, field, sideField, scaleField, colorField, what, group)
        local fs = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("TOPLEFT", 24, y)
        fs:SetText(label)
        IconChoice(150, y, list, field, sideField, scaleField, colorField, what, group)
    end
    IconRow(-346, "Date icon:", ns.DATE_ICONS, "dateIcon", "dateIconSide", "dateIconScale", "dateColor", "date", "date")
    IconRow(-378, "Instance icon:", ns.PLACE_ICONS, "placeIcon", "placeIconSide", "placeIconScale", "placeColor",
        "instance", "place")
    IconRow(-410, "Town icon:", ns.TOWN_ICONS, "townIcon", "townIconSide", "townIconScale", "townColor", "town", "town")
    IconRow(-442, "World icon:", ns.WORLD_ICONS, "worldIcon", "worldIconSide", "worldIconScale", "worldColor",
        "open world", "world")
    IconRow(-474, "Elite boss icon:", ns.RANK_ICONS, "eliteBossIcon", "eliteBossIconSide", "eliteBossIconScale",
        "eliteBossColor", "elite boss", "eliteboss")
    IconRow(-506, "Rare boss icon:", ns.RANK_ICONS, "rareBossIcon", "rareBossIconSide", "rareBossIconScale",
        "rareBossColor", "rare boss", "rareboss")
    -- Hint(page, "After each icon: the side it sits on, then its size (50% to 150%), then the color of the line's text. The instance icon is only for dungeons and raids. Towns, inns and the player housing neighbourhood use the town icon; every other place in the open world uses the world icon. The boss icons are for the \"<boss> drops:\" line in front of the items a boss drops: the rare one for a rare, the elite one for every other boss. The last line of each list adds a picture of your own: the name of a texture atlas, as the atlas viewer shows it.", 24, -532, 570)

    MakeHeader(page, "After a reload", 24, -550)
    MakeNumberBox(page, "Chat window history lines:", 24, -576, "chatLines", 176, 60, 0, 1000)
    Hint(page, "Entries put back after a reload, 0 to 1000. Default 1000.", 24, -600, 290)

    MakeHeader(page, "History", 340, -550)
    MakeNumberBox(page, "History max entries:", 340, -576, "maxHistory", 136, 60, ns.MIN_HISTORY, ns.MAX_HISTORY)
    Hint(page,
        ("Remembered per character and the same for every profile, %d to %d. Default 5000."):format(ns.MIN_HISTORY,
            ns.MAX_HISTORY), 340, -600, 280)
end

local function BuildAutomationPage()
    local page = NewPage(panel)
    panel.pages.auto = page

    MakeHeader(page, "Change profile by where I am", 24, -8)
    MakeCheck(page, "Switch profiles automatically", 24, -28, function()
        return (ns.GetAuto())
    end, function(v)
        ns.SetAuto(v)
    end)
    Hint(page,
        "When you change area (a loading screen), the profile chosen for that place is loaded. A profile you pick yourself stays until the next area change. This is set for each character.",
        24, -58, 570)

    MakeHeader(page, "Where", 24, -118)
    MakeHeader(page, "Loads this profile", 250, -118)
    for i, entry in ipairs(ns.SCENARIOS) do
        local scenario, label = entry[1], entry[2]
        local y = -142 - (i - 1) * 34
        local text = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOPLEFT", 24, y - 4)
        text:SetText(label)
        local dd = MakeDropdown(page, 246, y + 2, 260, function(_, root)
            for _, name in ipairs(ns.GetProfiles()) do
                root:CreateRadio(name, function(n)
                    return ns.GetRule(scenario) == n
                end, function(n)
                    ns.SetRule(scenario, n)
                end, name)
            end
        end)
        panel.rows[#panel.rows + 1] = {
            dd = dd,
            label = text
        }
    end

    MakeCheck(page, "Tell me in chat when the profile changes", 24, -142 - #ns.SCENARIOS * 34 - 8, function()
        return select(2, ns.GetAuto())
    end, function(v)
        ns.SetAnnounce(v)
    end)
end

local function Build()
    panel = CreateFrame("Frame", "FrogskisChatLootOptions", UIParent, "BackdropTemplate")
    panel:SetSize(640, 894)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(20) -- below the history window, which uses 60
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    ns.ApplyWindowStyle(panel)
    panel.pages, panel.tabs, panel.rows = {}, {}, {}
    tinsert(UISpecialFrames, "FrogskisChatLootOptions")

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("Frogski's Chat Loot Filter")

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    -- The profile bar: the profile in use, what to do with it, and what the automation is doing.
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 24, -54)
    label:SetText("Profile")
    panel.profileDD = MakeDropdown(panel, 84, -48, 250, function(_, root)
        for _, name in ipairs(ns.GetProfiles()) do
            root:CreateRadio(name, function(n)
                return ns.ActiveProfileName() == n
            end, function(n)
                ns.SwitchProfile(n)
            end, name)
        end
    end)
    local manage = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    manage:SetSize(110, 24)
    manage:SetPoint("TOPLEFT", 346, -48)
    manage:SetText("Manage...")
    manage:SetScript("OnClick", function(self)
        OpenManageMenu(self)
    end)
    panel.status = Hint(panel, "", 24, -80, 590)

    panel.tabs.filters = MakeTab(panel, "filters", "Filters", 1)
    panel.tabs.display = MakeTab(panel, "display", "Display", 2)
    panel.tabs.auto = MakeTab(panel, "auto", "Automation", 3)
    local line = panel:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 1, 1, 0.15)
    line:SetPoint("TOPLEFT", 16, -125)
    line:SetPoint("TOPRIGHT", -16, -125)
    line:SetHeight(1)

    BuildFiltersPage()
    BuildDisplayPage()
    BuildAutomationPage()

    -- the buttons at the bottom
    local function Bottom(index, text, onClick)
        local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        button:SetSize(112, 24)
        button:SetPoint("BOTTOMLEFT", 24 + (index - 1) * 120, 20)
        button:SetText(text)
        button:SetScript("OnClick", onClick)
        return button
    end
    Bottom(1, "Test output", ns.Test)
    Bottom(2, "History...", ns.ToggleAllHistory)
    Bottom(3, "Nuke all settings", function()
        StaticPopup_Show("FROGSKISCHATLOOT_NUKE_ALL")
    end)
    Bottom(4, "Clear history", function()
        StaticPopup_Show("FROGSKISCHATLOOT_CLEAR_HISTORY")
    end)
    Bottom(5, "Close", function()
        panel:Hide()
    end)

    panel:SetScript("OnShow", function(self)
        ns.SetChatHold("options", true) -- the chat stays at full opacity while this window is open
        SelectTab(self.selectedTab or "filters")
        RefreshAll()
        -- Shrink on small screens so the whole window stays visible.
        local avail = UIParent:GetHeight() * 0.95
        self:SetScale(math.min(1, avail / self:GetHeight()))
    end)
    panel:Hide() -- frames start shown; hide so the first toggle opens it and OnShow fires
    panel:SetScript("OnHide", function() -- set after the Hide above
        ns.StopTest()
        ns.SetChatHold("options", false)
    end)
end

function ns.OptionsShown()
    return panel and panel:IsShown() or false
end

function ns.ToggleOptions()
    if not panel then
        Build()
    end
    panel:SetShown(not panel:IsShown())
end

---------------------------------------------------------------------------
-- Quick filter menu (opened from the gear button on the loot window).
-- Uses Blizzard's own dropdown menu so it looks like the minimap menus.
---------------------------------------------------------------------------

local QUALITY_LABELS = {
    [0] = "Poor",
    "Common",
    "Uncommon",
    "Rare",
    "Epic",
    "Legendary"
}

-- The history windows' own filters that need typing: the two item lists and the minimum
-- item level. One popup with an edit box serves all three (data = { field, number }).
local function RedrawHistories()
    for _, W in ipairs(ns.ActiveWindows()) do
        ns.OnHistoryChanged(W)
    end
end

StaticPopupDialogs["FROGSKISCHATLOOT_HIST_EDIT"] = {
    text = "%s",
    button1 = ACCEPT or "Accept",
    button2 = CANCEL or "Cancel",
    hasEditBox = 1,
    editBoxWidth = 320,
    OnShow = function(self, data)
        local eb = self.editBox or self.EditBox
        if eb and data then
            eb:SetText(tostring(ns.db.hist[data.field] or ""))
            eb:HighlightText()
            eb:SetFocus()
        end
    end,
    OnAccept = function(self, data)
        local eb = self.editBox or self.EditBox
        if not (eb and data) then
            return
        end
        local value = strtrim(eb:GetText() or "")
        if data.number then
            value = math.max(0, tonumber(value) or 0)
        end
        ns.db.hist[data.field] = value
        RedrawHistories()
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        StaticPopupDialogs["FROGSKISCHATLOOT_HIST_EDIT"].OnAccept(parent, parent.data)
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

local function EditHistorySetting(field, label, number)
    StaticPopup_Show("FROGSKISCHATLOOT_HIST_EDIT", label, nil, {
        field = field,
        number = number
    })
end

-- The always-hide / always-show lists of the loot windows ("chat") or of the history windows
-- ("hist"): one window with the two lists side by side, each with its own scrolling. One item
-- name or ID per line (commas work too). A list is saved when you click out of it or close the window.
local listWindows = {}

local function ListText(text)
    return (tostring(text or ""):gsub("%s*,%s*", "\n"))
end

local function BuildListWindow(kind)
    local cfg = kind == "hist" and ns.db.hist or ns.db
    local name = "FrogskisChatLootLists" .. kind
    local win = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    win:SetSize(580, 400)
    win:SetPoint("CENTER", 40, 0)
    win:SetFrameStrata("DIALOG")
    win:SetFrameLevel(70)
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    ns.ApplyWindowStyle(win)
    tinsert(UISpecialFrames, name)

    local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -14)
    title:SetText(kind == "hist" and "History: always hide / always show" or "Loot windows: always hide / always show")

    local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    local boxes = {}

    local function Save(field)
        local text = strtrim(boxes[field]:GetText() or "")
        if text == strtrim(ListText(cfg[field])) then
            return
        end -- nothing changed
        cfg[field] = text
        if kind == "hist" then
            RedrawHistories()
        else
            ns.Refresh()
        end
    end

    local function Column(x, label, hint, field)
        local head = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        head:SetPoint("TOPLEFT", x, -44)
        head:SetText(label)
        local sub = win:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        sub:SetPoint("TOPLEFT", x, -62)
        sub:SetText(hint)

        local sf = CreateFrame("ScrollFrame", nil, win, "InputScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", x, -86)
        sf:SetSize(240, 250)
        local box = sf.EditBox
        box:SetWidth(240 - 18)
        box:SetMaxLetters(4000)
        if sf.CharCount then
            sf.CharCount:Hide()
        end
        box:SetScript("OnEditFocusLost", function()
            Save(field)
        end)
        boxes[field] = box
    end
    Column(24, "Always hide", "Hidden even if they pass every filter", "blacklist")
    Column(310, "Always show", "Shown even if a filter would hide them", "whitelist")

    local hint = win:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", 24, 22)
    hint:SetText("Item names or item IDs, one per line.")

    local done = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    done:SetSize(100, 24)
    done:SetPoint("BOTTOMRIGHT", -24, 16)
    done:SetText("Close")
    done:SetScript("OnClick", function()
        win:Hide()
    end)

    local hold = "lists" .. kind -- the chat stays at full opacity while this window is open
    win:SetScript("OnShow", function()
        ns.SetChatHold(hold, true)
        boxes.blacklist:SetText(ListText(cfg.blacklist))
        boxes.whitelist:SetText(ListText(cfg.whitelist))
    end)
    win:Hide() -- frames start shown; hide so the first open fires OnShow
    win:SetScript("OnHide", function()
        boxes.blacklist:ClearFocus()
        boxes.whitelist:ClearFocus()
        Save("blacklist")
        Save("whitelist")
        ns.SetChatHold(hold, false)
    end)
    return win
end

function ns.OpenItemLists(kind)
    local win = listWindows[kind]
    if not win then
        win = BuildListWindow(kind)
        listWindows[kind] = win
    end
    win:Show()
    win:Raise()
end

-- cfg is the settings table the menu edits: the addon db for the Loot windows,
-- db.hist for the history windows. onChange redraws whichever window it is. W is the loot
-- window the gear belongs to (its own history opens from the menu).
function ns.ToggleQuickFilters(anchor, cfg, onChange, isMain, W)
    local function Toggle(key)
        return function()
            cfg[key] = not cfg[key]
            onChange()
            return MenuResponse.Refresh
        end
    end

    local menu = MenuUtil.CreateContextMenu(anchor, function(_, root)
        if isMain then
            -- the chat window's menu starts with what is shown by binding
            root:CreateTitle("Show by binding")
            root:CreateCheckbox("Soulbound", function()
                return cfg.showSoulbound
            end, Toggle("showSoulbound"))
            root:CreateCheckbox("Warbound", function()
                return cfg.showWarbound
            end, Toggle("showWarbound"))
            root:CreateCheckbox("Binds when equipped", function()
                return cfg.showBoE
            end, Toggle("showBoE"))
            root:CreateDivider()
        end
        root:CreateTitle("Show quality")
        for q = 0, 5 do
            root:CreateCheckbox("|cff" .. QUALITY_COLORS[q] .. QUALITY_LABELS[q] .. "|r", function()
                return cfg.qualities[q]
            end, function()
                cfg.qualities[q] = not cfg.qualities[q]
                onChange()
                return MenuResponse.Refresh
            end)
        end
        root:CreateDivider()
        root:CreateTitle("Show loot from")
        root:CreateCheckbox("Me", function()
            return cfg.showSelf
        end, Toggle("showSelf"))
        root:CreateCheckbox("Others", function()
            return cfg.showOthers
        end, Toggle("showOthers"))
        if not isMain then
            root:CreateDivider()
            root:CreateCheckbox("Timestamp", function()
                return cfg.timestamp
            end, Toggle("timestamp"))
            root:CreateCheckbox("Date", function()
                return cfg.dates
            end, Toggle("dates"))
            root:CreateCheckbox("Date between days", function()
                return cfg.dateSeparator
            end, Toggle("dateSeparator"))
            root:CreateCheckbox("Dungeon / raid name", function()
                return cfg.instanceSeparator
            end, Toggle("instanceSeparator"))
            root:CreateCheckbox("Where it was looted", function()
                return cfg.zoneSeparator
            end, Toggle("zoneSeparator"))
            -- The history's own filters (the chat windows' are in the options window)
            root:CreateDivider()
            root:CreateTitle("History filters")
            root:CreateCheckbox("Trade, mail, vendor items", function()
                return cfg.showReceived
            end, Toggle("showReceived"))
            root:CreateCheckbox("Crafted items", function()
                return cfg.showCrafts
            end, Toggle("showCrafts"))
            root:CreateDivider()
            root:CreateTitle("Show by binding")
            root:CreateCheckbox("Soulbound", function()
                return cfg.showSoulbound
            end, Toggle("showSoulbound"))
            root:CreateCheckbox("Warbound", function()
                return cfg.showWarbound
            end, Toggle("showWarbound"))
            root:CreateCheckbox("Binds when equipped", function()
                return cfg.showBoE
            end, Toggle("showBoE"))
            root:CreateDivider()
            local types = root:CreateButton("Hide item types")
            for _, entry in ipairs(ns.ITEM_CLASSES) do
                local classID = entry[1]
                types:CreateCheckbox(entry[2], function()
                    return cfg.hideClass[classID]
                end, function()
                    cfg.hideClass[classID] = (not cfg.hideClass[classID]) or nil
                    onChange()
                    return MenuResponse.Refresh
                end)
            end
            root:CreateButton("Min gear item level (" .. (cfg.minItemLevel or 0) .. ")...", function()
                EditHistorySetting("minItemLevel",
                    "Weapons and armor below this item level are hidden in the history. 0 turns it off.", true)
            end)
            root:CreateButton("Always hide / always show lists...", function()
                ns.OpenItemLists("hist")
            end)
        end
        if isMain then
            root:CreateDivider()
            root:CreateButton("History...", function()
                ns.ToggleHistory(W)
            end)
            root:CreateButton("More options...", ns.ToggleOptions)
        end
    end)
    -- The chat stays at full opacity while the menu is displayed.
    if menu and menu.SetClosedCallback then
        ns.SetChatHold("menu", true)
        menu:SetClosedCallback(function()
            ns.SetChatHold("menu", false)
        end)
    end
end
