local ADDON_NAME = ...
local PANEL_NAME = "Frogski’s Instant Cast Bar"
local GRADIENT_LEFT = "FFD200" -- #3c73ff
local GRADIENT_RIGHT = "00eeff" -- #00eeff

-- =========
-- NUKE ALL
-- =========
local POPUP_KEY_NUKE = "FROGICB_NUKE_ALL_SETTINGS"

local StaticPopupDialogs = _G.StaticPopupDialogs
if not StaticPopupDialogs then
    StaticPopupDialogs = {}
    _G.StaticPopupDialogs = StaticPopupDialogs
end

if not StaticPopupDialogs[POPUP_KEY_NUKE] then
    StaticPopupDialogs[POPUP_KEY_NUKE] = {
        text = "NUKE ALL SETTINGS?\n\nThis will DELETE ALL settings for Frogski’s Instant Cast Bar.\n\nThis cannot be undone.\n\nThe UI will reload.",
        button1 = "NUKE",
        button2 = "Cancel",
        OnAccept = function()
            FrogskiInstantCastBarDB = nil
            ReloadUI()
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 4
    }
end

local function HexToRGB01(hex)
    hex = (hex or ""):gsub("#", "")
    if #hex ~= 6 then
        return 1, 1, 1
    end
    local r = tonumber(hex:sub(1, 2), 16) or 255
    local g = tonumber(hex:sub(3, 4), 16) or 255
    local b = tonumber(hex:sub(5, 6), 16) or 255
    return r / 255, g / 255, b / 255
end

local function RGB01ToHex(r, g, b)
    r = math.floor((math.max(0, math.min(1, r)) * 255) + 0.5)
    g = math.floor((math.max(0, math.min(1, g)) * 255) + 0.5)
    b = math.floor((math.max(0, math.min(1, b)) * 255) + 0.5)
    return string.format("%02X%02X%02X", r, g, b)
end

local function Utf8Chars(text)
    local t = {}
    for ch in tostring(text):gmatch("([%z\1-\127\194-\244][\128-\191]*)") do
        t[#t + 1] = ch
    end
    return t
end

local function MakePerLetterColoredName(text, leftHex, rightHex, prefix)
    if type(text) ~= "string" or text == "" then
        return (prefix or "") .. (text or "")
    end

    local chars = Utf8Chars(text)
    local n = #chars
    if n == 0 then
        return (prefix or "") .. text
    end

    local lr, lg, lb = HexToRGB01(leftHex)
    local rr, rg, rb = HexToRGB01(rightHex)

    local out = {}
    if prefix and prefix ~= "" then
        out[#out + 1] = prefix
    end

    if n == 1 then
        out[#out + 1] = ("|cff%s%s|r"):format(RGB01ToHex(lr, lg, lb), chars[1])
        return table.concat(out)
    end

    for i = 1, n do
        local t = (i - 1) / (n - 1)
        local r = lr + (rr - lr) * t
        local g = lg + (rg - lg) * t
        local b = lb + (rb - lb) * t
        out[#out + 1] = ("|cff%s%s|r"):format(RGB01ToHex(r, g, b), chars[i])
    end

    return table.concat(out)
end

local function HSVtoRGB(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6

    local r, g, b
    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    else
        r, g, b = v, p, q
    end
    return r, g, b
end

local function RGBHexLower(r, g, b)
    r = math.floor((r or 1) * 255 + 0.5)
    g = math.floor((g or 1) * 255 + 0.5)
    b = math.floor((b or 1) * 255 + 0.5)
    return string.format("%02x%02x%02x", r, g, b)
end

local function RainbowTextPerCharUTF8(text, hueOffset)
    if text == nil then
        return ""
    end
    text = tostring(text)
    hueOffset = hueOffset or 0

    local chars = Utf8Chars(text)
    local n = #chars
    if n == 0 then
        return ""
    end

    local out = {}
    for i = 1, n do
        local h = ((i - 1) / math.max(1, (n - 1)) + hueOffset) % 1
        local r, g, b = HSVtoRGB(h, 1, 1)
        out[#out + 1] = "|cff" .. RGBHexLower(r, g, b) .. chars[i]
    end
    out[#out + 1] = "|r"
    return table.concat(out)
end

local function MakeFirstLetterPlainThenGradient(text, leftHex, rightHex)
    if type(text) ~= "string" or text == "" then
        return text or ""
    end

    local chars = Utf8Chars(text)
    local n = #chars
    if n == 0 then
        return text
    end

    -- Keep first UTF-8 char plain, gradient the rest
    local first = chars[1]
    if n == 1 then
        return first
    end

    local rest = table.concat(chars, "", 2, n)
    return first .. MakePerLetterColoredName(rest, leftHex, rightHex)
end
local function ColorHex(hex, text)
    hex = tostring(hex or ""):gsub("#", "")
    return ("|cff%s%s|r"):format(hex, tostring(text or ""))
end

local function PanelName_SortSafeSplit(leftHex, rightHex)
    -- IMPORTANT: keep the very first character plain for sorting
    local firstPlain = "F"

    local mid = "rogski's Instant Ca" -- gradient only here
    local tail = "st Bar" -- solid right color here

    local midColored = MakePerLetterColoredName(mid, leftHex, rightHex)
    local tailColored = ColorHex(rightHex, tail)

    return firstPlain .. midColored .. tailColored
end

local PANEL_NAME_COLORED = PanelName_SortSafeSplit(GRADIENT_LEFT, GRADIENT_RIGHT)

local panel = CreateFrame("Frame", nil, UIParent)
panel.name = PANEL_NAME
panel:Hide()

panel:SetScript("OnShow", function(self)
    if self._built then
        return
    end
    self._built = true

    local scroll = CreateFrame("ScrollFrame", nil, self, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -8)
    scroll:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -28, 8)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetPoint("TOPLEFT", 0, 0)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    local title = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 0, -14)

    do
        local font, _, flags = title:GetFont()
        title:SetFont(font, 28, flags)
    end

    local anim = CreateFrame("Frame", nil, self)
    local hue = 0
    local SPEED = 0.22

    FrogskiInstantCastBarDB = FrogskiInstantCastBarDB or {}
    FrogskiInstantCastBarDB.overwrites = FrogskiInstantCastBarDB.overwrites or {}
    local function GetOverwrites()
        FrogskiInstantCastBarDB = FrogskiInstantCastBarDB or {}
        FrogskiInstantCastBarDB.overwrites = FrogskiInstantCastBarDB.overwrites or {}
        return FrogskiInstantCastBarDB.overwrites
    end
    FrogskiInstantCastBarDB.appearance = FrogskiInstantCastBarDB.appearance or {}
    local function GetAppearance()
        FrogskiInstantCastBarDB = FrogskiInstantCastBarDB or {}
        FrogskiInstantCastBarDB.appearance = FrogskiInstantCastBarDB.appearance or {}
        return FrogskiInstantCastBarDB.appearance
    end
    local function ResolveSpellIDFromInput(text)
        text = tostring(text or ""):match("^%s*(.-)%s*$")
        if text == "" then
            return nil
        end

        local n = tonumber(text)
        if n then
            return n
        end

        local linkID = text:match("Hspell:(%d+)")
        if linkID then
            return tonumber(linkID)
        end

        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(text)
            if info and info.spellID then
                return info.spellID
            end
        end

        return nil
    end

    local function CreateLabel(parent, text, x, y)
        local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        fs:SetText(text or "")
        return fs
    end

    local function CreateButton(parent, text, w, h, x, y)
        local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        b:SetSize(w, h)
        b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        b:SetText(text)
        return b
    end

    local function CreateEditBox(parent, w, h)
        local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        eb:SetSize(w, h)
        eb:SetAutoFocus(false)
        eb:SetFontObject("ChatFontNormal")

        eb:SetTextInsets(4, 8, 0, 0)

        eb:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)
        eb:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)
        return eb
    end

    local function CreateCheckBox(parent, labelText)
        local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        cb.text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        cb.text:SetText(labelText or "")
        return cb
    end
    local function CreateSlider(parent, labelText, minVal, maxVal, step)
        local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
        s:SetMinMaxValues(minVal, maxVal)
        s:SetValueStep(step or 0.05)
        s:SetObeyStepOnDrag(true)

        s:SetWidth(240)
        s:SetHeight(18)

        local name = s:GetName()
        if name then
            _G[name .. "Low"]:SetText(tostring(minVal))
            _G[name .. "High"]:SetText(tostring(maxVal))
            _G[name .. "Text"]:SetText(labelText or "")
        end

        return s
    end

    local function CreateGCDDropdown(parent, w, h, onChanged)
        local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
        dd:SetSize(w, h)

        dd._value = 1.5

        function dd:SetValue(v, silent)
            v = tonumber(v) or 1.5
            if v ~= 0 and v ~= 1 and v ~= 1.5 then
                v = 1.5
            end

            self._value = v

            local label = (v == 0 and "0 sec") or (v == 1 and "1 sec") or "1.5 sec"
            UIDropDownMenu_SetText(self, label)
            UIDropDownMenu_SetSelectedValue(self, v)

            if not silent and onChanged then
                onChanged(v)
            end
        end

        function dd:GetValue()
            return self._value
        end

        UIDropDownMenu_Initialize(dd, function(self, level)
            local function AddItem(label, value)
                local info = UIDropDownMenu_CreateInfo()
                info.text = label
                info.value = value
                info.func = function()
                    dd:SetValue(value)
                end
                info.checked = (dd._value == value)
                UIDropDownMenu_AddButton(info, level)
            end

            AddItem("0 sec", 0)
            AddItem("1 sec", 1)
            AddItem("1.5 sec", 1.5)
        end)

        dd:SetValue(dd._value, true)
        return dd
    end

    local LEFT_X = 0
    local ROW_W = 620
    local TOP_Y = -60

    CreateLabel(content, "Appearance modification (if adodns like BetterBlizzFrames make it look bad)", LEFT_X, TOP_Y)

    local ap = GetAppearance()

    if ap.bgAlpha == nil then
        ap.bgAlpha = 1
    end
    if ap.bgHidden == nil then
        ap.bgHidden = false
    end
    if ap.textBgAlpha == nil then
        ap.textBgAlpha = 1
    end
    if ap.textBgHidden == nil then
        ap.textBgHidden = false
    end
    if ap.borderAlpha == nil then
        ap.borderAlpha = 1
    end
    if ap.borderHidden == nil then
        ap.borderHidden = false
    end
    if ap.shineAlpha == nil then
        ap.shineAlpha = 0.6
    end
    if ap.shineHidden == nil then
        ap.shineHidden = false
    end
    if ap.sparkAlpha == nil then
        ap.sparkAlpha = 1
    end
    if ap.sparkHidden == nil then
        ap.sparkHidden = false
    end
    if ap.disableWhileMounted == nil then
        ap.disableWhileMounted = false
    end
    if ap.disableWhileDruidFlightForm == nil then
        ap.disableWhileDruidFlightForm = false
    end
    -- Row 1: Background
    local bgHide = CreateCheckBox(content, "Hide background")
    bgHide:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_X, TOP_Y - 24)
    bgHide:SetChecked(ap.bgHidden)

    local bgAlpha = CreateSlider(content, "Background alpha", 0, 1, 0.05)
    bgAlpha:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_X + 260, TOP_Y - 28)
    bgAlpha:SetValue(ap.bgAlpha)

    -- Row 2: Text backdrop
    local tbgHide = CreateCheckBox(content, "Hide text backdrop")
    tbgHide:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_X, TOP_Y - 58)
    tbgHide:SetChecked(ap.textBgHidden)

    local tbgAlpha = CreateSlider(content, "Text backdrop alpha", 0, 1, 0.05)
    tbgAlpha:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_X + 260, TOP_Y - 62)
    tbgAlpha:SetValue(ap.textBgAlpha)

    -- Row 3: Border
    local borderHide = CreateCheckBox(content, "Hide border")
    borderHide:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_X, TOP_Y - 92)
    borderHide:SetChecked(ap.borderHidden)

    local borderAlpha = CreateSlider(content, "Border alpha", 0, 1, 0.05)
    borderAlpha:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_X + 260, TOP_Y - 96)
    borderAlpha:SetValue(ap.borderAlpha)

    -- Row 4: Shine
    local shineHide = CreateCheckBox(content, "Hide shine")
    shineHide:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_X, TOP_Y - 126)
    shineHide:SetChecked(ap.shineHidden)

    local shineAlpha = CreateSlider(content, "Shine alpha", 0, 1, 0.05)
    shineAlpha:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_X + 260, TOP_Y - 130)
    shineAlpha:SetValue(ap.shineAlpha)

    -- Row 5: Spark
    local sparkHide = CreateCheckBox(content, "Hide spark")
    sparkHide:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_X, TOP_Y - 160)
    sparkHide:SetChecked(ap.sparkHidden)

    local sparkAlpha = CreateSlider(content, "Spark alpha", 0, 1, 0.05)
    sparkAlpha:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_X + 260, TOP_Y - 164)
    sparkAlpha:SetValue(ap.sparkAlpha)

    -- Row 6: Disable while mounted
    local mountDisable = CreateCheckBox(content, "Disable bar while mounted")
    mountDisable:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_X, TOP_Y - 194)
    mountDisable:SetChecked(ap.disableWhileMounted)

    -- Row 7: Disable in Druid Flight Form
    local flightDisable = CreateCheckBox(content, "Disable bar while Druid Flight Form")
    flightDisable:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_X, TOP_Y - 224)
    flightDisable:SetChecked(ap.disableWhileDruidFlightForm)

    local function PushAppearance()
        ap.bgHidden = bgHide:GetChecked() and true or false
        ap.bgAlpha = bgAlpha:GetValue()

        ap.textBgHidden = tbgHide:GetChecked() and true or false
        ap.textBgAlpha = tbgAlpha:GetValue()

        ap.borderHidden = borderHide:GetChecked() and true or false
        ap.borderAlpha = borderAlpha:GetValue()

        ap.shineHidden = shineHide:GetChecked() and true or false
        ap.shineAlpha = shineAlpha:GetValue()

        ap.sparkHidden = sparkHide:GetChecked() and true or false
        ap.sparkAlpha = sparkAlpha:GetValue()

        ap.disableWhileMounted = mountDisable:GetChecked() and true or false
        ap.disableWhileDruidFlightForm = flightDisable:GetChecked() and true or false

        if _G.FrogskiInstantCastBar_ApplyAppearance then
            _G.FrogskiInstantCastBar_ApplyAppearance()
        end
    end

    bgHide:SetScript("OnClick", PushAppearance)
    tbgHide:SetScript("OnClick", PushAppearance)
    borderHide:SetScript("OnClick", PushAppearance)
    shineHide:SetScript("OnClick", PushAppearance)
    sparkHide:SetScript("OnClick", PushAppearance)
    mountDisable:SetScript("OnClick", PushAppearance)
    flightDisable:SetScript("OnClick", PushAppearance)

    bgAlpha:SetScript("OnValueChanged", function()
        PushAppearance()
    end)
    tbgAlpha:SetScript("OnValueChanged", function()
        PushAppearance()
    end)
    borderAlpha:SetScript("OnValueChanged", function()
        PushAppearance()
    end)
    shineAlpha:SetScript("OnValueChanged", function()
        PushAppearance()
    end)
    sparkAlpha:SetScript("OnValueChanged", function()
        PushAppearance()
    end)

    TOP_Y = TOP_Y - 270

    CreateLabel(content, "Spell base GCD overwrites", LEFT_X, TOP_Y)

    local addBtn = CreateButton(content, "Add a spell base GCD overwrite", 260, 22, LEFT_X, TOP_Y - 24)

    local rowsHolder = CreateFrame("Frame", nil, content)
    rowsHolder:SetPoint("TOPLEFT", content, "TOPLEFT", LEFT_X, TOP_Y - 56)
    rowsHolder:SetSize(ROW_W, 1)

    local ROW_H = 28
    local ROW_GAP = 6
    local rows = {}

    local function SaveRowToDB(row)
        local spellID = tonumber(row._spellID)
        if not spellID then
            return
        end

        local base = tonumber(row.dd:GetValue())
        if not base then
            return
        end

        local ow = GetOverwrites()
        ow[spellID] = {
            base = base
        }
    end

    local function RemoveRowFromDB(row)
        local spellID = row._spellID
        if not spellID then
            return
        end
        local ow = GetOverwrites()
        ow[spellID] = nil
    end

    local function ReflowRows()
        local y = 0
        for i = 1, #rows do
            rows[i]:SetPoint("TOPLEFT", rowsHolder, "TOPLEFT", 0, -y)
            y = y + ROW_H + ROW_GAP
        end
        rowsHolder:SetHeight(math.max(1, y))
        content:SetHeight(math.max(900, 200 + y))

    end

    local function CreateOverwriteRow(initialSpellID, initialName, initialBase)
        local row = CreateFrame("Frame", nil, rowsHolder)
        row:SetSize(ROW_W, ROW_H)

        row.spellBox = CreateEditBox(row, 220, 28)
        row.spellBox:SetPoint("LEFT", row, "LEFT", 20, 0)
        row.spellIDSuffix = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        row.spellIDSuffix:SetPoint("LEFT", row.spellBox, "RIGHT", 6, 0)
        row.spellIDSuffix:SetText("")
        row.spellIDSuffix:SetTextColor(0.6, 0.6, 0.6)
        row.spellBox:SetText(initialName or "")
        if initialSpellID then
            row.spellIDSuffix:SetText("(" .. initialSpellID .. ")")
        end
        row._lastInputText = row.spellBox:GetText() or ""
        row._lastResolvedSpellID = initialSpellID

        row.dd = CreateGCDDropdown(row, 120, 22, function()
            if row._spellID then
                SaveRowToDB(row)
            end
        end)
        row.dd:SetPoint("LEFT", row.spellBox, "RIGHT", 60, -2)
        if initialBase ~= nil then
            row.dd:SetValue(initialBase)
        end

        row.removeBtn = CreateButton(row, "X", 22, 22, 0, 0)
        row.removeBtn:ClearAllPoints()
        row.removeBtn:SetPoint("LEFT", row.dd, "RIGHT", 36, 3)

        local function RefreshSpellIDFromBox()
            row.spellBox:ClearFocus()
            row.spellBox:HighlightText(0, 0)

            local input = row.spellBox:GetText() or ""
            input = tostring(input):match("^%s*(.-)%s*$") or ""

            if input == (row._lastInputText or "") then
                return
            end

            local sid = ResolveSpellIDFromInput(input)

            if not sid then
                row.spellBox:SetText(row._lastInputText or "")
                row.spellBox:SetCursorPosition(0)

                if row._lastResolvedSpellID then
                    row.spellIDSuffix:SetText("(" .. row._lastResolvedSpellID .. ")")
                else
                    row.spellIDSuffix:SetText("")
                end
                return
            end

            if sid == row._lastResolvedSpellID then
                local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(sid)
                local name = (info and info.name) or input

                row.spellBox:SetText(name)
                row.spellBox:SetCursorPosition(0)
                row.spellIDSuffix:SetText("(" .. sid .. ")")

                row._lastInputText = name
                return
            end

            row._spellID = sid
            row._lastResolvedSpellID = sid

            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(sid)
            local name = (info and info.name) or input

            row.spellBox:SetText(name)
            row.spellBox:SetCursorPosition(0)
            row.spellIDSuffix:SetText("(" .. sid .. ")")

            row._lastInputText = name

            SaveRowToDB(row)
        end

        row.spellBox:SetScript("OnEditFocusLost", RefreshSpellIDFromBox)
        row.spellBox:SetScript("OnEnterPressed", function()
            RefreshSpellIDFromBox()
        end)

        row.removeBtn:SetScript("OnClick", function()
            RemoveRowFromDB(row)
            for i = #rows, 1, -1 do
                if rows[i] == row then
                    table.remove(rows, i)
                    break
                end
            end
            row:Hide()
            row:SetParent(nil)
            ReflowRows()
        end)

        row._spellID = initialSpellID
        if initialSpellID then
            SaveRowToDB(row)
        end

        rows[#rows + 1] = row
        ReflowRows()
        return row
    end

    do
        local ow = GetOverwrites()
        for spellID, data in pairs(ow) do
            local sid = tonumber(spellID)
            if sid then
                local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(sid)
                local name = (info and info.name) or tostring(sid)
                CreateOverwriteRow(sid, name, tonumber(data.base) or 0)
            end
        end
    end

    addBtn:SetScript("OnClick", function()
        CreateOverwriteRow(nil, "", 1.5)
        ReflowRows()
    end)

    local function UpdateTitle()
        title:SetText(RainbowTextPerCharUTF8(PANEL_NAME, hue))
    end

    local function Start()
        anim:SetScript("OnUpdate", function(_, elapsed)
            hue = (hue + (elapsed or 0) * SPEED) % 1
            UpdateTitle()
        end)
    end

    local function Stop()
        anim:SetScript("OnUpdate", nil)
    end

    UpdateTitle()
    Start()
    self:HookScript("OnShow", function()
        UpdateTitle();
        Start()
    end)
    self:HookScript("OnHide", function()
        Stop()
    end)
    -- =========================
    -- NUKE ALL SETTINGS BUTTON 
    -- ========================
    local nukeBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    nukeBtn:SetSize(260, 28)
    nukeBtn:SetText("|cffffff00!!! NUKE ALL SETTINGS !!!|r")
    nukeBtn:SetPoint("TOPLEFT", rowsHolder, "BOTTOMLEFT", 0, -120)

    nukeBtn:SetScript("OnClick", function()
        StaticPopup_Show(POPUP_KEY_NUKE)
    end)

    nukeBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Nuke all settings")
        GameTooltip:AddLine("Deletes ALL settings for this addon.", 1, 0.2, 0.2, true)
        GameTooltip:AddLine("This cannot be undone.", 1, 0.2, 0.2, true)
        GameTooltip:Show()
    end)
    nukeBtn:SetScript("OnLeave", GameTooltip_Hide)

    content:SetWidth(620)
    content:SetHeight(900)
end)

local function RegisterSettingsCategory()
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, PANEL_NAME_COLORED)
        Settings.RegisterAddOnCategory(category)
        return
    end

    if InterfaceOptions_AddCategory then
        panel.name = PANEL_NAME_COLORED
        InterfaceOptions_AddCategory(panel)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", RegisterSettingsCategory)
