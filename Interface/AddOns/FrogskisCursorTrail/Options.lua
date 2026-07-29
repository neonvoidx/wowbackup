local ADDON_NAME = ...
local FCT = _G.FrogskisCursorTrail2
local db
local dbm

local POPUP_KEY_RESET = "FCT_RESET_DEFAULTS_RELOAD"
local POPUP_KEY_NEWPROFILE = "FCT_CREATE_PROFILE"
local POPUP_KEY_NUKE = "FCT_NUKE_ALL_SETTINGS"
local POPUP_KEY_CANT_DELETE_MANAGED = "FCT_CANT_DELETE_MANAGED_PROFILE"

local GRADIENT_LEFT = "FFD200"
local GRADIENT_RIGHT = "4ff3ff" -- #4ff3ff

local COND_ROW_W = 660
local COND_ROW_H = 96
local COND_ROW_STEP = 116
local COND_NUKE_GAP = 40

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

local function MakeFirstLetterPlainThenGradient(text, leftHex, rightHex)
    if type(text) ~= "string" or text == "" then
        return text or ""
    end
    local chars = Utf8Chars(text)
    local n = #chars
    if n == 0 then
        return text
    end

    local first = chars[1]
    if n == 1 then
        return first
    end

    local rest = table.concat(chars, "", 2, n)
    return first .. MakePerLetterColoredName(rest, leftHex, rightHex)
end

local StaticPopupDialogs = _G.StaticPopupDialogs
if not StaticPopupDialogs then
    StaticPopupDialogs = {}
    _G.StaticPopupDialogs = StaticPopupDialogs
end

if not StaticPopupDialogs[POPUP_KEY_RESET] then
    StaticPopupDialogs[POPUP_KEY_RESET] = {
        text = "Reset the 'Default' profile to factory defaults?\n\nThis overwrites the Default profile.\nOther profiles stay unchanged.\n\nThis will reload your UI.",
        button1 = "Reload UI",
        button2 = "Cancel",
        OnAccept = function()
            if FCT and FCT.ResetDefaultProfileToFactory then
                FCT:ResetDefaultProfileToFactory()
            end
            ReloadUI()
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 3
    }
end
if not StaticPopupDialogs[POPUP_KEY_CANT_DELETE_MANAGED] then
    StaticPopupDialogs[POPUP_KEY_CANT_DELETE_MANAGED] = {
        text = "This profile is managed by %s.\nIt cannot be deleted from this character.",
        button1 = "OK",
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 4
    }
end

if not StaticPopupDialogs[POPUP_KEY_NUKE] then
    StaticPopupDialogs[POPUP_KEY_NUKE] = {
        text = "NUKE ALL SETTINGS?\n\nThis will DELETE ALL profiles and settings for Frogski's Cursor Trail.\n\nThis cannot be undone.\n\nThe UI will reload.",
        button1 = "NUKE",
        button2 = "Cancel",
        OnAccept = function()
            FrogskisCursorTrailDB = nil
            ReloadUI()
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 4
    }
end

local function GetPopupEditText(dialog)
    local eb = dialog and (dialog.editBox or dialog.EditBox)
    if not eb and dialog and dialog.GetEditBox then
        eb = dialog:GetEditBox()
    end
    if not eb and dialog and dialog.GetName then
        local n = dialog:GetName()
        if n then
            eb = _G[n .. "EditBox"]
        end
    end
    if not eb then
        for i = 1, 4 do
            local f = _G["StaticPopup" .. i]
            if f and f:IsShown() and f.which == POPUP_KEY_NEWPROFILE then
                eb = _G["StaticPopup" .. i .. "EditBox"]
                break
            end
        end
    end
    local txt = eb and eb:GetText() or ""
    txt = tostring(txt or ""):match("^%s*(.-)%s*$") or ""
    return txt
end

local RefreshAllWidgets
local RefreshProfileControls
local RefreshConditionsUI
local UpdateAutomationBottomY
local nukeBtn
local RecalcScrollHeight
local BuildProfileItems

if not StaticPopupDialogs[POPUP_KEY_NEWPROFILE] then
    StaticPopupDialogs[POPUP_KEY_NEWPROFILE] = {
        text = "Create a new profile\n\nEnter profile name:",
        button1 = "Create",
        button2 = "Cancel",
        hasEditBox = 1,
        editBoxWidth = 220,
        maxLetters = 32,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 4,

        OnShow = function(self)
            local eb = self.editBox or self.EditBox or _G[self:GetName() .. "EditBox"]
            if eb then
                eb:SetText("")
                eb:SetFocus()
            end
        end,

        OnAccept = function(self)
            local ok, err = pcall(function()
                local name = GetPopupEditText(self)
                if not name or name == "" then
                    return
                end
                dbm:CreateProfile(name, true)
                dbm:SetProfile(name)
                db = dbm:GetProfileTable()

                if FCT and FCT.Refresh then
                    FCT:Refresh()
                end
                if RefreshProfileControls then
                    RefreshProfileControls()
                end
                if RefreshAllWidgets then
                    RefreshAllWidgets()
                end
            end)

            if not ok then
                print("|cffff0000FCT profile creation error:|r " .. tostring(err))
            end
        end
    }
end

local function Clamp(v, mn, mx)
    if v < mn then
        return mn
    end
    if v > mx then
        return mx
    end
    return v
end

local IS_SYNCING = false

local function MakeNumberBox(parent, label, tooltip, width, getFunc, setFunc)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetText(label)

    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(width or 80, 24)
    eb:SetAutoFocus(false)
    eb:SetJustifyH("CENTER")

    local function Refresh()
        local v = getFunc()
        if v == nil then
            v = 0
        end
        eb:SetText(tostring(v))
        eb:SetCursorPosition(0)
    end

    local function Apply()
        if IS_SYNCING then
            return
        end
        local txt = (eb:GetText() or ""):gsub(",", ".")
        local v = tonumber(txt)
        if not v then
            Refresh()
            eb:ClearFocus()
            return
        end

        setFunc(v)
        if FCT and FCT.Refresh then
            FCT:Refresh()
        end
        eb:ClearFocus()
    end

    eb:SetScript("OnEnterPressed", Apply)
    eb:SetScript("OnEditFocusLost", Apply)
    eb:SetScript("OnEscapePressed", function()
        Refresh()
        eb:ClearFocus()
    end)

    if tooltip then
        eb:SetScript("OnEnter", function()
            GameTooltip:SetOwner(eb, "ANCHOR_RIGHT")
            GameTooltip:SetText(label)
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        eb:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        title:SetScript("OnEnter", function()
            GameTooltip:SetOwner(title, "ANCHOR_RIGHT")
            GameTooltip:SetText(label)
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        title:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    eb.Refresh = Refresh
    Refresh()
    return eb, title
end

local function FormatSliderValue(v, step)
    if step and step < 1 then
        local decimals = 0
        local s = tostring(step)
        local dot = s:find("%.")
        if dot then
            decimals = #s - dot
        end
        decimals = Clamp(decimals, 1, 3)
        return string.format("%." .. decimals .. "f", v)
    end
    return tostring(math.floor(v + 0.5))
end

local function RoundToStep(v, step)
    if not step or step <= 0 then
        return v
    end
    return math.floor((v / step) + 0.5) * step
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

local function RGBHex(r, g, b)
    r = math.floor((r or 1) * 255 + 0.5)
    g = math.floor((g or 1) * 255 + 0.5)
    b = math.floor((b or 1) * 255 + 0.5)
    return string.format("%02x%02x%02x", r, g, b)
end

local function RainbowTextPerChar(text, hueOffset)
    if text == nil then
        return ""
    end
    text = tostring(text)

    hueOffset = hueOffset or 0
    local n = #text
    if n == 0 then
        return ""
    end

    local out = {}
    for i = 1, n do
        local ch = text:sub(i, i)
        local h = ((i - 1) / math.max(1, (n - 1)) + hueOffset) % 1
        local r, g, b = HSVtoRGB(h, 1, 1)
        out[#out + 1] = "|cff" .. RGBHex(r, g, b) .. ch
    end
    out[#out + 1] = "|r"
    return table.concat(out)
end

local function MakeSlider(parent, label, tooltip, minV, maxV, step, getFunc, setFunc)
    local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)

    s.Text:SetText(label)
    s.Low:SetText(tostring(minV))
    s.High:SetText(tostring(maxV))

    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(60, 20)
    eb:SetAutoFocus(false)
    eb:SetJustifyH("CENTER")
    eb:SetPoint("LEFT", s, "RIGHT", 12, 0)

    local function ApplyValue(v)
        v = Clamp(v, minV, maxV)
        v = RoundToStep(v, step)

        if not IS_SYNCING then
            setFunc(v)
            if FCT and FCT.Refresh then
                FCT:Refresh()
            end
        end

        s:SetValue(v)
        eb:SetText(FormatSliderValue(v, step))
    end

    if tooltip and s:HasScript("OnEnter") then
        s:SetScript("OnEnter", function()
            GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
            GameTooltip:SetText(label)
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        s:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    s:SetScript("OnValueChanged", function(_, value)
        value = RoundToStep(value, step)
        eb:SetText(FormatSliderValue(value, step))

        if IS_SYNCING then
            return
        end

        setFunc(value)
        if FCT and FCT.Refresh then
            FCT:Refresh()
        end
    end)

    eb:SetScript("OnEnterPressed", function(self2)
        local txt = self2:GetText() or ""
        txt = txt:gsub(",", ".")
        local v = tonumber(txt)
        if v then
            ApplyValue(v)
        else
            eb:SetText(FormatSliderValue(s:GetValue(), step))
        end
        self2:ClearFocus()
    end)

    eb:SetScript("OnEscapePressed", function(self2)
        eb:SetText(FormatSliderValue(s:GetValue(), step))
        self2:ClearFocus()
    end)

    eb:SetScript("OnEditFocusLost", function()
        if IS_SYNCING then
            return
        end
        local txt = eb:GetText() or ""
        txt = txt:gsub(",", ".")
        local v = tonumber(txt)
        if v then
            ApplyValue(v)
        else
            eb:SetText(FormatSliderValue(s:GetValue(), step))
        end
    end)

    function s:Refresh()
        local init = getFunc()
        init = Clamp(init, minV, maxV)
        init = RoundToStep(init, step)
        self:SetValue(init)
        eb:SetText(FormatSliderValue(init, step))
    end

    s.ValueBox = eb
    s:Refresh()
    return s
end

local function MakeCheckbox(parent, label, tooltip, getFunc, setFunc)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb.Text:SetText(label or "")
    cb.tooltipRequirement = tooltip

    cb:SetScript("OnEnter", function()
        if cb.tooltipText then
            GameTooltip:SetOwner(cb, "ANCHOR_RIGHT")
            GameTooltip:SetText(cb.tooltipText)
            if cb.tooltipRequirement then
                GameTooltip:AddLine(cb.tooltipRequirement, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end
    end)
    cb:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    cb:SetScript("OnClick", function(self2)
        if IS_SYNCING then
            return
        end
        setFunc(self2:GetChecked() and true or false)
        if FCT and FCT.Refresh then
            FCT:Refresh()
        end
    end)

    function cb:Refresh()
        self:SetChecked(getFunc() and true or false)
    end

    cb:Refresh()
    cb.tooltipText = label or ""
    return cb
end

local function MakeDropdown(parent, label, tooltip, itemsFunc, getFunc, setFunc)
    local f = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetText(label)

    UIDropDownMenu_SetWidth(f, 180)

    UIDropDownMenu_Initialize(f, function()
        local items = itemsFunc()
        for _, it in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = it.text
            info.value = it.value
            info.func = function()
                if IS_SYNCING then
                    return
                end
                setFunc(it.value)
                UIDropDownMenu_SetSelectedValue(f, it.value)
                UIDropDownMenu_SetText(f, it.text)
                if FCT and FCT.Refresh then
                    FCT:Refresh()
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    function f:Refresh()
        local items = itemsFunc()
        if not items or not items[1] then
            return
        end

        local val = getFunc()
        local txt
        for _, it in ipairs(items) do
            if it.value == val then
                txt = it.text
                break
            end
        end

        if not txt then
            val = items[1].value
            txt = items[1].text
            if not IS_SYNCING then
                IS_SYNCING = true
                setFunc(val)
                IS_SYNCING = false
            end
        end

        UIDropDownMenu_SetSelectedValue(f, val)
        UIDropDownMenu_SetText(f, txt)
    end

    f:HookScript("OnShow", function()
        f:Refresh()

    end)

    f:Refresh()

    if tooltip then
        f:EnableMouse(true)
        f:SetScript("OnEnter", function()
            GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
            GameTooltip:SetText(label)
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        f:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    return f, title
end

local function MakeColorSwatch(parent, label, getFunc, setFunc)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(20, 20)

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 1)

    local sw = b:CreateTexture(nil, "ARTWORK")
    sw:SetPoint("TOPLEFT", 2, -2)
    sw:SetPoint("BOTTOMRIGHT", -2, 2)

    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetText(label)

    local function Refresh()
        local c = getFunc()
        sw:SetColorTexture(c[1], c[2], c[3], 1)
    end

    local function Apply(r, g, bl)
        if IS_SYNCING then
            return
        end
        setFunc({r, g, bl})
        Refresh()
        if FCT and FCT.Refresh then
            FCT:Refresh()
        end
    end

    b:SetScript("OnClick", function()
        if IS_SYNCING then
            return
        end
        local c = getFunc()
        local r, g, bl = c[1], c[2], c[3]

        if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
            local info = {
                r = r,
                g = g,
                b = bl,
                hasOpacity = false,

                swatchFunc = function()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    Apply(nr, ng, nb)
                end,

                cancelFunc = function(restore)
                    if restore and restore.r and restore.g and restore.b then
                        Apply(restore.r, restore.g, restore.b)
                    else
                        Apply(r, g, bl)
                    end
                end
            }

            ColorPickerFrame:SetupColorPickerAndShow(info)
            return
        end

        if ColorPickerFrame then
            ColorPickerFrame:Hide()
            ColorPickerFrame.hasOpacity = false
            ColorPickerFrame.previousValues = {r, g, bl}

            ColorPickerFrame.func = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                Apply(nr, ng, nb)
            end

            ColorPickerFrame.cancelFunc = function()
                local pv = ColorPickerFrame.previousValues
                Apply(pv[1], pv[2], pv[3])
            end

            if ColorPickerFrame.SetColorRGB then
                ColorPickerFrame:SetColorRGB(r, g, bl)
            end
            ColorPickerFrame:Show()
        end
    end)

    b.Refresh = Refresh
    Refresh()
    return b, text
end

-- =========================
-- Animated rainbow checkbox 
-- =========================
local function AttachAnimatedRainbowLabel(panel, cb, plainText, speed)
    plainText = tostring(plainText or "")
    speed = speed or 0.35

    cb.Text:SetText("")
    cb.Text:Hide()

    local fs = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    fs:SetJustifyH("LEFT")
    fs:SetWidth(600)
    fs:SetWordWrap(false)

    local t = 0
    local function Update()
        local fancy = RainbowTextPerChar(plainText, t)
        fs:SetText(fancy)
        cb.tooltipText = fancy
    end

    local anim = CreateFrame("Frame", nil, cb)

    local function Start()
        anim:SetScript("OnUpdate", function(_, elapsed)
            t = (t + elapsed * speed) % 1
            Update()

            if GameTooltip and GameTooltip:IsOwned(cb) then
                GameTooltip:ClearLines()
                GameTooltip:SetText(cb.tooltipText)
                if cb.tooltipRequirement then
                    GameTooltip:AddLine(cb.tooltipRequirement, 1, 1, 1, true)
                end
                GameTooltip:Show()
            end
        end)
    end

    local function Stop()
        anim:SetScript("OnUpdate", nil)
    end

    Update()
    Start()
    panel:HookScript("OnShow", function()
        Update()
        Start()
    end)
    panel:HookScript("OnHide", function()
        Stop()
    end)

end

-- =========================
-- Settings panel registration
-- =========================
local function ColorHex(hex, text)
    hex = tostring(hex or ""):gsub("#", "")
    return ("|cff%s%s|r"):format(hex, tostring(text or ""))
end
local function PanelName_SortSafeSplit(leftHex, rightHex)
    local firstPlain = "F"
    local mid = "rogski's Cursor T"
    local tail = "rail"
    local midColored = MakePerLetterColoredName(mid, leftHex, rightHex)
    local tailColored = ColorHex("4ff3ff", tail)
    return firstPlain .. midColored .. tailColored
end

local PANEL_NAME_COLORED = PanelName_SortSafeSplit(GRADIENT_LEFT, GRADIENT_RIGHT)

local panel = CreateFrame("Frame", nil, UIParent)
panel.name = PANEL_NAME_COLORED
panel:Hide()

panel:SetScript("OnShow", function(self)
    if self._built then
        return
    end
    self._built = true

    dbm = FCT and FCT.db
    if not dbm then
        return
    end
    db = dbm:GetProfileTable()
    db.maxdots = math.min(db.maxdots or DEFAULTS.maxdots, 800)

    local function GetConditions()
        FrogskisCursorTrailDB = FrogskisCursorTrailDB or {}
        FrogskisCursorTrailDB.conditions = FrogskisCursorTrailDB.conditions or {}
        return FrogskisCursorTrailDB.conditions
    end

    local WIDGETS = {}
    local function Track(w)
        if w then
            WIDGETS[#WIDGETS + 1] = w
        end
        return w
    end

    RefreshAllWidgets = function()
        IS_SYNCING = true
        for _, w in ipairs(WIDGETS) do
            if w and w.Refresh then
                w:Refresh()
            end
        end
        IS_SYNCING = false
    end

    function FCT:RefreshOptionsUI()
        if not dbm then
            return
        end
        db = dbm:GetProfileTable()
        if RefreshProfileControls then
            RefreshProfileControls()
        end
        if RefreshAllWidgets then
            RefreshAllWidgets()
        end
        if RefreshConditionsUI then
            RefreshConditionsUI()
        end
        if UpdateAutomationBottomY then
            UpdateAutomationBottomY()
        end
    end

    -- ======
    -- Scroll
    -- ======
    local scroll = CreateFrame("ScrollFrame", nil, self, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -8)
    scroll:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -28, 8)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetPoint("TOPLEFT", 0, 0)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    local title = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 0, -14)
    title:SetText("Frogski's Cursor Trail")

    do
        local font, _, flags = title:GetFont()
        title:SetFont(font, 28, flags)

        local t = 0
        local anim = CreateFrame("Frame", nil, self)

        local function Start()
            anim:SetScript("OnUpdate", function(_, elapsed)
                t = t + elapsed * 1.2
                local r = 0.5 + 0.5 * math.sin(t * 2.0)
                local g = 0.5 + 0.5 * math.sin(t * 2.0 + 2.094)
                local b = 0.5 + 0.5 * math.sin(t * 2.0 + 4.188)
                title:SetTextColor(r, g, b, 1)
            end)
        end

        local function Stop()
            anim:SetScript("OnUpdate", nil)
        end

        Start()
        self:HookScript("OnShow", Start)
        self:HookScript("OnHide", Stop)
    end

    local y = -(title:GetStringHeight() + 36)
    local adaptiveAnchor
    local sAdaptiveTarget
    -- ====================
    -- Left column settings
    -- ====================
    local cbCombat = Track(MakeCheckbox(content, "Only in combat",
        "If enabled, trail only shows while you are in combat.", function()
            return db.combatoption
        end, function(v)
            db.combatoption = v
        end))
    cbCombat:SetPoint("TOPLEFT", 16, y)
    y = y - 28

    local cbRainbowText = "Rainbow flow"
    local cbRainbow = Track(MakeCheckbox(content, cbRainbowText,
        "If enabled: time-based color cycling. If disabled: transition along lifetime.", function()
            return db.changeWithTime
        end, function(v)
            db.changeWithTime = v
        end))
    cbRainbow:SetPoint("TOPLEFT", 16, y)
    y = y - 28
    AttachAnimatedRainbowLabel(self, cbRainbow, cbRainbowText, 0.35)

    -- Color speed (moved under Rainbow flow)
    y = y - 12
    local sSpeed = Track(MakeSlider(content, "Colour speed", "Color change speed.", 0.1, 10.0, 0.1, function()
        return db.colourspeed
    end, function(v)
        db.colourspeed = v
    end))
    sSpeed:SetPoint("TOPLEFT", 16, y)
    y = y - 30

    local cbClass = Track(MakeCheckbox(content, "Use class color (override palette)",
        "If enabled, the whole trail uses your class color. If disabled, palette colours 1..10 are used.", function()
            return db.useClassColor
        end, function(v)
            db.useClassColor = v
        end))
    cbClass:SetPoint("TOPLEFT", 16, y)
    y = y - 28

    local cbShrinkTime = Track(MakeCheckbox(content, "Shrink with time",
        "If enabled, dots shrink (and fade) as they age. If disabled, dots keep full size over lifetime.", function()
            return db.shrinkWithTime
        end, function(v)
            db.shrinkWithTime = v
        end))
    cbShrinkTime:SetPoint("TOPLEFT", 16, y)
    y = y - 28

    local cbShrinkDist = Track(MakeCheckbox(content, "Shrink with distance",
        "If enabled, dots shrink along the trail (head bigger, tail smaller). If disabled, trail keeps uniform thickness.",
        function()
            return db.shrinkWithDistance
        end, function(v)
            db.shrinkWithDistance = v
        end))
    cbShrinkDist:SetPoint("TOPLEFT", 16, y)
    y = y - 50

    local sDot = Track(MakeSlider(content, "Dot distance", "Spacing threshold between dots.", 1, 10, 1, function()
        return db.dotdistance
    end, function(v)
        db.dotdistance = v
    end))
    sDot:SetPoint("TOPLEFT", 16, y)
    y = y - 50

    local sLife = Track(MakeSlider(content, "Lifetime", "How long a dot stays alive.", 0.1, 5.0, 0.05, function()
        return db.lifetime
    end, function(v)
        db.lifetime = v
    end))
    sLife:SetPoint("TOPLEFT", 16, y)
    y = y - 50

    local sMax = Track(MakeSlider(content, "Max dots", "Total number of pooled dots. Higher = grater fps impact.", 1,
        800, 5, function()
            return db.maxdots
        end, function(v)
            db.maxdots = math.floor(v)
        end))
    sMax:SetPoint("TOPLEFT", 16, y)
    y = y - 50

    local sW = Track(MakeSlider(content, "Dot width", "Base dot width.", 1, 256, 1, function()
        return db.widthx
    end, function(v)
        db.widthx = v
    end))
    sW:SetPoint("TOPLEFT", 16, y)
    y = y - 50

    local sH = Track(MakeSlider(content, "Dot height", "Base dot height.", 1, 256, 1, function()
        return db.heightx
    end, function(v)
        db.heightx = v
    end))
    sH:SetPoint("TOPLEFT", 16, y)
    y = y - 50

    local sA = Track(MakeSlider(content, "Alpha", "Alpha multiplier.", 0.0, 1.0, 0.05, function()
        return db.Alphax
    end, function(v)
        db.Alphax = v
    end))
    sA:SetPoint("TOPLEFT", 16, y)
    y = y - 50

    -- =====================
    -- Right column settings
    -- =====================
    local baseRightY = -(title:GetStringHeight() + 40)

    local ddLayer, ddLayerLabel = MakeDropdown(content, "Cursor layer", "Frame strata for trail textures.", function()
        return {{
            text = "TOOLTIP",
            value = 1
        }, {
            text = "BACKGROUND",
            value = 2
        }}
    end, function()
        return db.cursorlayer
    end, function(v)
        db.cursorlayer = v
    end)
    Track(ddLayer)
    ddLayerLabel:SetPoint("TOPLEFT", 320, baseRightY)
    ddLayer:SetPoint("TOPLEFT", 310, baseRightY - 22)

    local offLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    offLabel:SetPoint("TOPLEFT", 360, -573)
    offLabel:SetText("Trail offset from the cursor (px)")

    local offXBox, offXTitle = MakeNumberBox(content, "Offset X",
        "Horizontal offset in pixels. +X moves right, -X moves left.", 80, function()
            return db.offsetX
        end, function(v)
            db.offsetX = v
        end)
    Track(offXBox)
    offXTitle:SetPoint("TOPLEFT", 360, -600)
    offXBox:SetPoint("TOPLEFT", 430, -604)

    local offYBox, offYTitle = MakeNumberBox(content, "Offset Y",
        "Vertical offset in pixels. +Y moves up, -Y moves down.", 80, function()
            return db.offsetY
        end, function(v)
            db.offsetY = v
        end)
    Track(offYBox)
    offYTitle:SetPoint("TOPLEFT", 360, -628)
    offYBox:SetPoint("TOPLEFT", 430, -632)

    local ddBlend, ddBlendLabel = MakeDropdown(content, "Blend mode", "Glow or Regular", function()
        return {{
            text = "GLOW",
            value = 1
        }, {
            text = "DISABLE GLOW",
            value = 2
        }}
    end, function()
        return db.blendmode
    end, function(v)
        db.blendmode = v
    end)
    Track(ddBlend)
    ddBlendLabel:SetPoint("TOPLEFT", 320, baseRightY - 78)
    ddBlend:SetPoint("TOPLEFT", 310, baseRightY - 100)

    local texLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    texLabel:SetPoint("TOPLEFT", 320, baseRightY - 156)
    texLabel:SetText("Texture (atlas name OR file path)")

    local texEB = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    texEB:SetPoint("TOPLEFT", 320, baseRightY - 176)
    texEB:SetSize(260, 24)
    texEB:SetAutoFocus(false)
    texEB:SetText(db.textureInput or "")
    texEB:SetCursorPosition(0)

    texEB:SetScript("OnEnterPressed", function(self2)
        if IS_SYNCING then
            self2:ClearFocus()
            return
        end
        db.textureInput = self2:GetText()
        self2:ClearFocus()
        if FCT and FCT.Refresh then
            FCT:Refresh()
        end
    end)

    function texEB:Refresh()
        self:SetText(db.textureInput or "")
        self:SetCursorPosition(0)
    end
    Track(texEB)

    local hint = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 320, baseRightY - 202)
    hint:SetJustifyH("LEFT")
    hint:SetText("Example atlas: titleprestige-starglow\n")

    local palTitle = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    palTitle:SetPoint("TOPLEFT", 320, baseRightY - 236)
    palTitle:SetText("Palette colors (colour1..colour10)")

    local cx, cy = 320, baseRightY - 261
    for i = 1, 10 do
        local key = "colour" .. i
        local sw, txt = MakeColorSwatch(content, key, function()
            return db[key]
        end, function(v)
            db[key] = v
        end)
        Track(sw)

        txt:SetPoint("TOPLEFT", cx + 28, cy - 2)
        sw:SetPoint("TOPLEFT", cx, cy)

        cy = cy - 26
        if i == 5 then
            cx = 520
            cy = baseRightY - 261
        end
    end

    local sPhases = Track(MakeSlider(content, "Number of colours used", "How many palette colors to use.", 1, 10, 1,
        function()
            return db.phasecount
        end, function(v)
            db.phasecount = Clamp(math.floor(v), 1, 10)
        end))
    sPhases:SetPoint("TOPLEFT", 320, baseRightY - 420)

    -- =================
    -- RMB LOOK SECTION 
    -- =================
    local rmbTitle = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    rmbTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 20, y)
    rmbTitle:SetText("Camera rotation over UI elements")
    do
        local font, _, flags = rmbTitle:GetFont()
        rmbTitle:SetFont(font, 18, flags)
    end
    y = y - 26

    local cbLook = Track(MakeCheckbox(content, "Enable camera movement look over UI elements",
        "Allows to look around while holding RMB over a UI element", function()
            return db.enableLook
        end, function(v)
            db.enableLook = v
        end))
    cbLook:SetPoint("TOPLEFT", 16, y)
    y = y - 28

    local cbCombatLook = Track(MakeCheckbox(content, "Only in combat", "Only in combat", function()
        return db.enableCombatLook
    end, function(v)
        db.enableCombatLook = v
    end))
    cbCombatLook:SetPoint("TOPLEFT", 16, y)
    y = y - 28

    local cbIndicator = Track(MakeCheckbox(content, "Highlight cursor when RMB pressed",
        "Shows/hides the cursor highlight texture while mouselooking (independent from the camera look option).",
        function()
            return db.enableIndicator
        end, function(v)
            db.enableIndicator = v
        end))
    cbIndicator:SetPoint("TOPLEFT", 16, y)
    y = y - 60

    local sIndicatorSize = Track(MakeSlider(content, "Cursor highlight size",
        "Size of the cursor highlight frame in pixels. Adjust depending on your cursor size.", 10, 128, 1, function()
            return db.cursorFrameSize
        end, function(v)
            db.cursorFrameSize = math.floor(v)
        end))
    sIndicatorSize:SetPoint("TOPLEFT", 16, y)
    y = y - 60

    -- =================
    -- PROFILES SECTION
    -- =================
    local profTitle = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    profTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 20, y)
    profTitle:SetText("Profiles")
    do
        local font, _, flags = profTitle:GetFont()
        profTitle:SetFont(font, 26, flags)
    end
    y = y - 26

    -- Reset button
    y = y - 10
    local resetBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetBtn:SetSize(200, 26)
    resetBtn:SetText("Reset Default profile")
    resetBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 20, y)
    y = y - 40

    local function RefreshResetButtonState()
        local cur = dbm:GetCurrentProfile()
        local enabled = (cur == "Default")
        resetBtn:SetEnabled(enabled)
        resetBtn:SetAlpha(enabled and 1 or 0.4)
    end

    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show(POPUP_KEY_RESET)
    end)

    local profDD = CreateFrame("Frame", nil, content, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(profDD, 220)
    profDD:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
    y = y - 44

    local deleteBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    deleteBtn:SetSize(220, 26)
    deleteBtn:SetText("Delete Current Profile")
    deleteBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 22, y)
    y = y - 40

    local cbAccountWide = Track(MakeCheckbox(content, "Make this profile account wide",
        "If enabled, this profile will be visible across all characters.", function()
            local cur = dbm:GetCurrentProfile()
            return dbm:IsProfileAccountWide(cur)
        end, function(v)
            local cur = dbm:GetCurrentProfile()
            dbm:SetProfileAccountWide(cur, v)
            db = dbm:GetProfileTable()
            if FCT and FCT.Refresh then
                FCT:Refresh()
            end
            if RefreshProfileControls then
                RefreshProfileControls()
            end
            if RefreshAllWidgets then
                RefreshAllWidgets()
            end
        end))
    cbAccountWide:SetPoint("LEFT", profDD, "RIGHT", -6, 2)

    local function BuildProfileItems()
        local items = {}
        local list = dbm:ListProfilesSorted()
        for _, name in ipairs(list) do
            items[#items + 1] = {
                text = name,
                value = name
            }
        end
        items[#items + 1] = {
            text = " ",
            value = "__SPACER__"
        }
        items[#items + 1] = {
            text = "New Profile...",
            value = "__NEW__"
        }
        return items
    end

    local function SetProfileSelection(value)
        if value == "__SPACER__" then
            return
        end
        if value == "__NEW__" then
            StaticPopup_Show(POPUP_KEY_NEWPROFILE)
            return
        end
        userTouchedProfileAt = GetTime()

        dbm:SetProfile(value)
        db = dbm:GetProfileTable()

        if FCT and FCT.Refresh then
            FCT:Refresh()
        end
        if RefreshProfileControls then
            RefreshProfileControls()
        end
        if RefreshAllWidgets then
            RefreshAllWidgets()
        end
    end

    RefreshProfileControls = function()
        local actual = dbm:GetCurrentProfile()
        local cur = actual

        UIDropDownMenu_Initialize(profDD, function()
            local items = BuildProfileItems()
            for _, it in ipairs(items) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = it.text
                info.value = it.value
                info.notCheckable = true

                if it.value == "__SPACER__" then
                    info.isTitle = true
                else
                    info.func = function()
                        SetProfileSelection(it.value)
                    end
                end
                UIDropDownMenu_AddButton(info)
            end
        end)

        UIDropDownMenu_SetSelectedValue(profDD, cur)
        UIDropDownMenu_SetText(profDD, cur)

        local canDelete = (actual ~= "Default")
        deleteBtn:SetEnabled(canDelete)
        deleteBtn:SetAlpha(canDelete and 1 or 0.4)

        RefreshResetButtonState()
    end
    if FCT and FCT.UpdateConditionOverride and not panel._hookedCondDropdownSync then
        panel._hookedCondDropdownSync = true

        hooksecurefunc(FCT, "UpdateConditionOverride", function()
            if not panel:IsShown() then
                return
            end
            if not dbm or not RefreshProfileControls then
                return
            end
            local now = GetTime()
            if (now - (userTouchedProfileAt or 0)) < 1.5 then
                return
            end
            if (now - (lastAutoSyncAt or 0)) < 2.0 then
                return
            end
            local cur = dbm:GetCurrentProfile()
            local shown = UIDropDownMenu_GetSelectedValue(profDD)
            if shown ~= cur then
                lastAutoSyncAt = now
                RefreshProfileControls()
            end
        end)
    end

    RefreshProfileControls()

    local profWatch = CreateFrame("Frame", nil, panel)
    local profWatchElapsed = 0
    local lastSeenProfile = nil

    local function StartProfileWatch()
        profWatchElapsed = 0
        lastSeenProfile = dbm and dbm:GetCurrentProfile() or nil

        profWatch:SetScript("OnUpdate", function(_, elapsed)
            profWatchElapsed = profWatchElapsed + elapsed
            if profWatchElapsed < 0.20 then
                return
            end
            profWatchElapsed = 0

            if not dbm then
                return
            end
            local cur = dbm:GetCurrentProfile()
            if cur ~= lastSeenProfile then
                lastSeenProfile = cur

                db = dbm:GetProfileTable()
                if RefreshProfileControls then
                    RefreshProfileControls()
                end
                if RefreshAllWidgets then
                    RefreshAllWidgets()
                end
            end
        end)
    end

    local function StopProfileWatch()
        profWatch:SetScript("OnUpdate", nil)
    end

    StartProfileWatch()
    panel:HookScript("OnShow", StartProfileWatch)
    panel:HookScript("OnHide", StopProfileWatch)

    deleteBtn:SetScript("OnClick", function()
        local cur = dbm:GetCurrentProfile()
        if cur == "Default" then
            return
        end

        if dbm:IsProfileAccountWide(cur) then
            local owner = dbm:GetProfileOwner(cur)
            local meName, meRealm = UnitFullName("player")
            local me = (meRealm and meRealm ~= "") and (meName .. "-" .. meRealm) or (meName or UnitName("player"))

            if owner and owner ~= "" and me and owner ~= me then
                StaticPopup_Show(POPUP_KEY_CANT_DELETE_MANAGED, owner)
                return
            end
        end

        dbm:DeleteProfile(cur)

        FrogskisCursorTrailDB = FrogskisCursorTrailDB or {}
        FrogskisCursorTrailDB.conditions = FrogskisCursorTrailDB.conditions or {}
        local conds = FrogskisCursorTrailDB.conditions
        for i = 1, #conds do
            if conds[i] and conds[i].profile == cur then
                conds[i].profile = "Default"
            end
        end

        db = dbm:GetProfileTable()

        if FCT and FCT.Refresh then
            FCT:Refresh()
        end
        if RefreshProfileControls then
            RefreshProfileControls()
        end
        if RefreshAllWidgets then
            RefreshAllWidgets()
        end
        if RefreshConditionsUI then
            RefreshConditionsUI()
        end
        if UpdateAutomationBottomY then
            UpdateAutomationBottomY()
        end
        if FCT and FCT.UpdateConditionOverride then
            FCT:UpdateConditionOverride()
        end
    end)

    -- =======================
    -- Export / Import 
    -- =======================
    local exBG = CreateFrame("Frame", nil, content, "BackdropTemplate")
    exBG:SetPoint("TOPLEFT", content, "TOPLEFT", 22, y)
    exBG:SetSize(290, 96)
    exBG:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4
        }
    })
    exBG:SetBackdropColor(0, 0, 0, 0.35)
    exBG:EnableMouse(true)

    local exScroll = CreateFrame("ScrollFrame", "FrogskiExportScroll", exBG, "UIPanelScrollFrameTemplate")
    exScroll:SetPoint("TOPLEFT", exBG, "TOPLEFT", 8, -8)
    exScroll:SetPoint("BOTTOMRIGHT", exBG, "BOTTOMRIGHT", -28, 8)

    local exBox = CreateFrame("EditBox", nil, exScroll)
    exBox:SetMultiLine(true)
    exBox:SetMaxLetters(0)
    exBox:SetAutoFocus(false)
    exBox:SetFontObject("GameFontHighlightSmall")
    exBox:SetWidth(520)
    exBox:SetHeight(80)
    exBox:SetTextInsets(2, 2, 2, 2)

    exBox:SetScript("OnTextChanged", function(self2)
        ScrollingEdit_OnTextChanged(self2, self2:GetParent())
    end)
    exBox:SetScript("OnCursorChanged", function(self2, x, y2, w, h)
        ScrollingEdit_OnCursorChanged(self2, x, y2, w, h)
    end)
    exBox:SetScript("OnMouseDown", function(self2)
        self2:SetFocus()
    end)
    exBox:SetScript("OnEscapePressed", function(self2)
        self2:ClearFocus()
    end)
    exBG:SetScript("OnMouseDown", function()
        exBox:SetFocus()
    end)

    exScroll:SetScrollChild(exBox)
    y = y - 106

    local btnExport = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    btnExport:SetSize(120, 24)
    btnExport:SetText("Export profile")
    btnExport:SetPoint("TOPLEFT", content, "TOPLEFT", 22, y)

    local btnImport = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    btnImport:SetSize(120, 24)
    btnImport:SetText("Import profile")
    btnImport:SetPoint("LEFT", btnExport, "RIGHT", 10, 0)

    btnExport:SetScript("OnClick", function()
        local cur = dbm:GetCurrentProfile()
        local s, err = dbm:ExportProfileString(cur)
        if not s then
            print("|cffff4444FCT: Export failed:|r " .. tostring(err))
            return
        end
        exBox:SetText(s)
        exBox:HighlightText()
        exBox:SetFocus()
    end)

    btnImport:SetScript("OnClick", function()
        local txt = exBox:GetText() or ""
        local name, err = dbm:ImportProfileString(txt)
        if not name then
            print("|cffff4444FCT: Import failed:|r " .. tostring(err))
            return
        end

        db = dbm:GetProfileTable()

        if FCT and FCT.Refresh then
            FCT:Refresh()
        end
        if RefreshProfileControls then
            RefreshProfileControls()
        end
        if RefreshAllWidgets then
            RefreshAllWidgets()
        end

        print("|cff33ff99FCT: Imported profile:|r " .. tostring(name))
    end)

    y = y - 134

    -- ========================
    -- CONDITIONS / AUTOMATION
    -- ========================
    local automationTitle = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    automationTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 20, y + 80)
    automationTitle:SetText("Profile Automation")
    do
        local font, _, flags = automationTitle:GetFont()
        automationTitle:SetFont(font, 22, flags)
    end

    local conditionsBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    conditionsBtn:SetSize(200, 26)
    conditionsBtn:SetText("Add conditions")
    conditionsBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 30, y + 44)

    local conditionsRows = {}
    local conditionsAnchorY = y - 10
    local function TitleCaseFirst(s)
        s = tostring(s or "")
        return s:gsub("^%l", string.upper)
    end
    local function BuildWhenItems()
        local items = {{
            text = "Mounted",
            value = "mounted"
        }, {
            text = "Mounted on a specific mount",
            value = "mount_specific"
        }, {
            text = "In Sanctuary / Resting",
            value = "resting"
        }, {
            text = "Open world / Not instanced",
            value = "openworld"
        }, {
            text = "Dungeon / Mythic+",
            value = "dungeon"
        }, {
            text = "Raid",
            value = "raid"
        }, {
            text = "Arena / Battleground",
            value = "pvp"
        }, {
            text = "Scenario / Delve",
            value = "scenario"
        }, {
            text = "Not in combat",
            value = "notcombat"
        }, {
            text = "In combat",
            value = "combat"
        }}
        if type(GetNumSpecializations) == "function" and type(GetSpecializationInfo) == "function" and type(UnitClass) ==
            "function" then
            local className = select(1, UnitClass("player"))

            local n = GetNumSpecializations() or 0

            for i = 1, n do
                local specID, specName = GetSpecializationInfo(i)
                if specID and specName and specName ~= "" then
                    items[#items + 1] = {
                        text = className .. ": " .. specName,
                        value = "spec:" .. tostring(specID)
                    }
                end
            end
        end

        return items
    end

    local function BuildProfileItemsForConditions()
        local items = {}
        local list = dbm:ListProfilesSorted()
        for _, name in ipairs(list) do
            items[#items + 1] = {
                text = name,
                value = name
            }
        end
        return items
    end

    local function DeleteConditionAt(index)
        local conds = GetConditions()
        if not conds[index] then
            return
        end
        table.remove(conds, index)

        if RefreshConditionsUI then
            RefreshConditionsUI()
        end
        if UpdateAutomationBottomY then
            UpdateAutomationBottomY()
        end
        if FCT and FCT.UpdateConditionOverride then
            FCT:UpdateConditionOverride()
        end
    end

    local MoveCondition

    local function AddConditionRow(ruleIndex)
        local conds = GetConditions()
        conds[ruleIndex] = conds[ruleIndex] or {
            when = "combat",
            profile = dbm:GetCurrentProfile(),
            mount = ""
        }

        local ROW_W = COND_ROW_W
        local ROW_H = COND_ROW_H
        local ROW_STEP = COND_ROW_STEP

        local row = CreateFrame("Frame", nil, content)
        row:SetSize(ROW_W, ROW_H)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 20, conditionsAnchorY - ((ruleIndex - 1) * ROW_STEP))

        local upBtn = CreateFrame("Button", nil, row)
        upBtn:SetSize(18, 24)
        upBtn:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -4)
        local upTex = upBtn:CreateTexture(nil, "ARTWORK")
        upTex:SetAllPoints()
        upTex:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
        upBtn:SetNormalTexture(upTex)
        upBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        upBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")

        local downBtn = CreateFrame("Button", nil, row)
        downBtn:SetSize(18, 24)
        downBtn:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -22)
        local downTex = downBtn:CreateTexture(nil, "ARTWORK")
        downTex:SetAllPoints()
        downTex:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
        downBtn:SetNormalTexture(downTex)
        downBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        downBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")

        if ruleIndex <= 1 then
            upBtn:Disable()
            upBtn:SetAlpha(0.35)
        end
        if ruleIndex >= #conds then
            downBtn:Disable()
            downBtn:SetAlpha(0.35)
        end

        upBtn:SetScript("OnClick", function()
            MoveCondition(ruleIndex, -1)
        end)
        downBtn:SetScript("OnClick", function()
            MoveCondition(ruleIndex, 1)
        end)

        row.upBtn = upBtn
        row.downBtn = downBtn

        local ddWhen, ddWhenLabel = MakeDropdown(row, "When", nil, BuildWhenItems, function()
            local r = conds[ruleIndex]
            return (r and r.when) or "combat"
        end, function(v)
            local r = conds[ruleIndex]
            if not r then
                return
            end
            r.when = v
            if row.RefreshMountField then
                row:RefreshMountField()
            end
            if FCT and FCT.UpdateConditionOverride then
                FCT:UpdateConditionOverride()
            end
        end)
        Track(ddWhen)
        ddWhenLabel:SetPoint("TOPLEFT", row, "TOPLEFT", 26, 10)
        ddWhen:SetPoint("TOPLEFT", row, "TOPLEFT", 16, -10)

        local ddProf, ddProfLabel = MakeDropdown(row, "Profile", nil, BuildProfileItemsForConditions, function()
            local r = conds[ruleIndex]
            return (r and r.profile) or "Default"
        end, function(v)
            local r = conds[ruleIndex]
            if not r then
                return
            end
            r.profile = v
            if FCT and FCT.UpdateConditionOverride then
                FCT:UpdateConditionOverride()
            end
        end)
        Track(ddProf)
        ddProfLabel:SetPoint("TOPLEFT", row, "TOPLEFT", 260, 10)
        ddProf:SetPoint("TOPLEFT", row, "TOPLEFT", 250, -10)

        row.ddWhen = ddWhen
        row.ddProfile = ddProf

        local sep = row:CreateTexture(nil, "BACKGROUND")
        sep:SetColorTexture(1, 1, 1, 0.22)
        sep:SetHeight(1)
        sep:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 26, -2)
        sep:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -10, -2)
        sep:SetShown(ruleIndex < #conds)
        row.sep = sep

        local mountLabel = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        mountLabel:SetPoint("TOPLEFT", row, "TOPLEFT", 48, -50)
        mountLabel:SetText("Mount name / spellID / mountID (comma-separated)")

        local mountEB = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
        mountEB:SetSize(460, 22)
        mountEB:SetAutoFocus(false)
        mountEB:SetPoint("TOPLEFT", row, "TOPLEFT", 52, -64)
        mountEB:SetJustifyH("LEFT")
        mountEB:SetScript("OnEnter", function()
            GameTooltip:SetOwner(mountEB, "ANCHOR_RIGHT")
            GameTooltip:SetText("Examples: 12345, 67890, Sandstone Drake, The Prestigious Butt-Wiggling Thundergoat")
            GameTooltip:Show()
        end)
        mountEB:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        local function RefreshMountField()
            local r = conds[ruleIndex]
            local v = (r and r.mount) or ""
            mountEB:SetText(v)
            mountEB:SetCursorPosition(0)

            local show = (r and r.when == "mount_specific")
            mountLabel:SetShown(show)
            mountEB:SetShown(show)
        end

        mountEB:SetScript("OnEnterPressed", function(self2)
            local r = conds[ruleIndex]
            if not r then
                self2:ClearFocus()
                return
            end
            r.mount = (self2:GetText() or ""):match("^%s*(.-)%s*$") or ""
            self2:ClearFocus()
            if FCT and FCT.UpdateConditionOverride then
                FCT:UpdateConditionOverride()
            end
        end)

        mountEB:SetScript("OnEditFocusLost", function(self2)
            local r = conds[ruleIndex]
            if not r then
                return
            end
            r.mount = (self2:GetText() or ""):match("^%s*(.-)%s*$") or ""
            if FCT and FCT.UpdateConditionOverride then
                FCT:UpdateConditionOverride()
            end
        end)

        row.mountEB = mountEB
        row.RefreshMountField = RefreshMountField
        RefreshMountField()

        local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        delBtn:SetSize(70, 24)
        delBtn:SetText("Delete")
        delBtn:SetPoint("TOPLEFT", row, "TOPLEFT", 480, -11)
        delBtn:SetScript("OnClick", function()
            DeleteConditionAt(ruleIndex)
        end)
        delBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Delete this condition")
            GameTooltip:AddLine("Removes this automation rule.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        delBtn:SetScript("OnLeave", GameTooltip_Hide)
        row.delBtn = delBtn

        conditionsRows[#conditionsRows + 1] = row
        return row
    end

    MoveCondition = function(index, delta)
        local conds = GetConditions()
        local n = #conds
        if index < 1 or index > n then
            return
        end

        local newIndex = index + (delta or 0)
        if newIndex < 1 or newIndex > n then
            return
        end

        conds[index], conds[newIndex] = conds[newIndex], conds[index]

        if RefreshConditionsUI then
            RefreshConditionsUI()
        end
        if UpdateAutomationBottomY then
            UpdateAutomationBottomY()
        end
        if FCT and FCT.UpdateConditionOverride then
            FCT:UpdateConditionOverride()
        end
    end

    RefreshConditionsUI = function()
        local conds = GetConditions()

        for i = 1, #conditionsRows do
            if conditionsRows[i] then
                conditionsRows[i]:Hide()
            end
        end
        wipe(conditionsRows)

        for i = 1, #conds do
            AddConditionRow(i)
        end
    end

    UpdateAutomationBottomY = function()
        local conds = GetConditions()
        local rows = #conds
        local lastTopY = conditionsAnchorY - ((math.max(rows, 1) - 1) * COND_ROW_STEP)
        local lastBottomY = lastTopY - COND_ROW_H
        local nukeTopY = lastBottomY - COND_NUKE_GAP

        if nukeBtn then
            nukeBtn:ClearAllPoints()
            nukeBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 20, nukeTopY)
        end
        if adaptiveAnchor then
            adaptiveAnchor:ClearAllPoints()
            adaptiveAnchor:SetPoint("TOPLEFT", content, "TOPLEFT", 20, nukeTopY)
        end
        y = nukeTopY - 40

        if RecalcScrollHeight then
            RecalcScrollHeight()
        end
    end

    conditionsBtn:SetScript("OnClick", function()
        local conds = GetConditions()
        local idx = #conds + 1
        conds[idx] = {
            when = "combat",
            profile = dbm:GetCurrentProfile(),
            mount = ""
        }
        if RefreshConditionsUI then
            RefreshConditionsUI()
        else
            AddConditionRow(idx)
        end

        if UpdateAutomationBottomY then
            UpdateAutomationBottomY()
        end
        if FCT and FCT.UpdateConditionOverride then
            FCT:UpdateConditionOverride()
        end
    end)

    RefreshConditionsUI()
    UpdateAutomationBottomY()

    -- ========================
    -- NUKE ALL SETTINGS BUTTON
    -- ========================
    nukeBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    nukeBtn:SetSize(260, 28)
    nukeBtn:SetText("|cffffff00!!! NUKE ALL SETTINGS !!!|r")
    nukeBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 20, y - 40)
    adaptiveAnchor = CreateFrame("Frame", nil, content)
    adaptiveAnchor:SetSize(1, 1)
    adaptiveAnchor:SetPoint("TOPLEFT", content, "TOPLEFT", 20, y - 40)
    -- =========
    -- Debug FPS 
    -- =========
    local cbDebug = Track(MakeCheckbox(content, "Show FPS", "Shows texture count + FPS overlay.", function()
        return (FCT and FCT.IsDebugEnabled and FCT:IsDebugEnabled()) or false
    end, function(v)
        if FCT and FCT.SetDebugEnabled then
            FCT:SetDebugEnabled(v)
        end
    end))

    cbDebug:ClearAllPoints()
    cbDebug:SetPoint("LEFT", nukeBtn, "RIGHT", 14, 0)
    sAdaptiveTarget = Track(MakeSlider(content, "Adaptive target updates (in Hz)",
        "When Adaptive Update Rate is enabled and your FPS is above 90,\n" ..
            "the trail will update about this many times per second.\n\n" .. "Examples:\n" ..
            "• 240 FPS + target 90 => ~90 updates/sec\n" .. "• 90 FPS or below => every frame (ignores target)", 1,
        240, 1, function()
            return db.adaptiveTargetFPS or 90
        end, function(v)
            db.adaptiveTargetFPS = math.floor(v)
        end))
    sAdaptiveTarget:ClearAllPoints()
    sAdaptiveTarget:SetPoint("TOPLEFT", adaptiveAnchor, "TOPLEFT", 370, 30)

    local function RefreshAdaptiveSliderEnabled()
        local on = (db.updateEveryOther == true)

        if sAdaptiveTarget and sAdaptiveTarget.SetEnabled then
            sAdaptiveTarget:SetEnabled(on)
            sAdaptiveTarget:SetAlpha(on and 1 or 0.4)
        end

        if sAdaptiveTarget and sAdaptiveTarget.ValueBox then
            sAdaptiveTarget.ValueBox:SetEnabled(on)
            sAdaptiveTarget.ValueBox:SetAlpha(on and 1 or 0.4)
        end
    end
    RefreshAdaptiveSliderEnabled()

    local cbEveryOther = Track(MakeCheckbox(content, "Adaptive Update Rate (reduces CPU usage)",
        "Tries to keep your FPS healthy by reducing how often the trail updates.\n\n" .. "Rules:\n" ..
            "• 90 FPS or below: updates every frame (smoothest)\n" ..
            "• Above 90 FPS: updates about the Target Updates value (slider)\n" ..
            "  (but never more than your current FPS)", function()
            return db.updateEveryOther == true
        end, function(v)
            db.updateEveryOther = v
            RefreshAdaptiveSliderEnabled()
        end))
    cbEveryOther:ClearAllPoints()
    cbEveryOther:SetPoint("LEFT", cbDebug, "RIGHT", 60, 0)

    RefreshAdaptiveSliderEnabled()
    if UpdateAutomationBottomY then
        UpdateAutomationBottomY()
    end

    nukeBtn:SetScript("OnClick", function()
        StaticPopup_Show(POPUP_KEY_NUKE)
    end)
    nukeBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Nuke all settings")
        GameTooltip:AddLine("Deletes ALL profiles and settings.", 1, 0.2, 0.2, true)
        GameTooltip:AddLine("This cannot be undone.", 1, 0.2, 0.2, true)
        GameTooltip:Show()
    end)
    nukeBtn:SetScript("OnLeave", GameTooltip_Hide)

    -- =========================
    -- Finalize scroll child size
    -- =========================
    RecalcScrollHeight = function()
        local needed = math.max((-y) + 80, 900)
        content:SetWidth(620)
        content:SetHeight(needed)
    end

    RecalcScrollHeight()
end)

local function RegisterSettingsCategory()
    if not Settings or not Settings.RegisterCanvasLayoutCategory then
        return
    end
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    RegisterSettingsCategory()
end)
