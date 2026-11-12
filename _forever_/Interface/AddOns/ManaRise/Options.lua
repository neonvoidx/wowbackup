-- ManaRise - Options.lua
-- Page under Game Menu > Options > AddOns: a canvas category holding one
-- frame of ours (see the note above Build).
--
-- Every control is a "proxy" setting: the panel reads and writes ns.db
-- through ns:SetOption, the same path the /mr commands use. When a /mr
-- command changes something, Refresh() tells the panel to redraw.
--
-- Nothing here touches action buttons. Building the page and opening the
-- panel are kept out of combat.
-- If the Settings API is missing, the /mr commands keep working on their own.

local _, ns = ...

local O = {}
ns.Options = O

O.settings = {}       -- [db key] = setting object (get/set/redraw)
O.category = nil
O.problem = nil       -- why the panel is unavailable, for /mr status

local L = ns.L

local function HasSettingsAPI()
    return type(Settings) == "table"
        and type(Settings.RegisterCanvasLayoutCategory) == "function"
        and type(Settings.RegisterAddOnCategory) == "function"
        and type(Settings.OpenToCategory) == "function"
end

---------------------------------------------------------------------------
-- The page is a "canvas" category: one frame of ours that the game shows in
-- the AddOns tab. Every control on it (checkboxes, sliders, steppers,
-- swatches, buttons) is a plain frame built here. We deliberately do not use
-- the game's own settings controls (Settings.CreateCheckbox, CreateDropdown,
-- ...): the game reuses those frames between pages, and running our code
-- through them made the game's own pages (Game > Social, ...) report
-- "ManaRise has been blocked from an action only available to the Blizzard UI".
---------------------------------------------------------------------------
local LABEL_X, CTRL_X, ROW_H = 24, 290, 30

local function TryTemplate(kind, parent, template)
    local ok, f = pcall(CreateFrame, kind, nil, parent, template)
    if ok and f then return f end
    return CreateFrame(kind, nil, parent)
end

local function Tooltip(frame, label, tip)
    frame:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(label, 1, 1, 1)
        if tip and tip ~= "" then GameTooltip:AddLine(tip, nil, nil, nil, true) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

local function Percent(value)
    return string.format("%d%%", math.floor((tonumber(value) or 0) + 0.5))
end

local function HexToRGB(hex)
    hex = tostring(hex or "FFFFFFFF")
    local r = tonumber(string.sub(hex, 3, 4), 16) or 255
    local g = tonumber(string.sub(hex, 5, 6), 16) or 255
    local b = tonumber(string.sub(hex, 7, 8), 16) or 255
    local a = tonumber(string.sub(hex, 1, 2), 16) or 255
    return r / 255, g / 255, b / 255, a / 255
end

local function Build()
    local canvas = CreateFrame("Frame", nil, UIParent)
    canvas:Hide()
    local scroll = TryTemplate("ScrollFrame", canvas, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", canvas, "TOPLEFT", 4, -8)
    scroll:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", -28, 8)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(580, 100)
    scroll:SetScrollChild(content)
    scroll:SetScript("OnSizeChanged", function(_, w) if w and w > 100 then content:SetWidth(w) end end)
    if scroll.EnableMouseWheel then
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local range = self:GetVerticalScrollRange() or 0
            local pos = (self:GetVerticalScroll() or 0) - delta * ROW_H * 2
            self:SetVerticalScroll(math.max(0, math.min(range, pos)))
        end)
    end

    local rows = {}
    O.rows = rows
    local y = 6                          -- next row's distance from the top

    -- While a list is set, every control a row creates is added to it, so a
    -- group of rows can be shown or hidden together.
    local tracked
    -- Every control in creation order, with the points it was anchored to the
    -- page with, so the rows below a hidden group can move up (see
    -- O:ApplyResourceLayout). grp: the group being built, if any.
    local all, grp = {}, nil
    O.allControls = all
    local function Track(obj)
        if not obj then return obj end
        if tracked then tracked[#tracked + 1] = obj end
        if grp then grp[#grp + 1] = obj end
        all[#all + 1] = obj
        local pts, orig = {}, obj.SetPoint
        obj.mrPoints, obj.mrRawSetPoint = pts, orig
        obj.SetPoint = function(self, ...)
            pts[#pts + 1] = { ... }
            return orig(self, ...)
        end
        return obj
    end

    local function NewLabel(text, font, x, top)
        local fs = Track(content:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight"))
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", x or LABEL_X, -(top or y))
        fs:SetText(text)
        return fs
    end

    -- A setting: reads and writes ns.db through the same ns:SetOption path
    -- the /mr commands use. `redraw` repaints its control from the stored value.
    local function Proxy(key, varType, label, default, get, set)
        local s = { key = key, name = label, vtype = varType, default = default,
            get = get, set = set, notifies = 0 }
        function s:GetName() return self.name end
        function s:GetValue() return self.get() end
        function s:SetValue(v)
            if type(v) ~= self.vtype then error("setting " .. self.key .. ": value is not a " .. self.vtype) end
            if self.get() ~= v then self.set(v) end
            self.displayed = v
            if self.redraw then self.redraw(self) end
        end
        function s:SetValueToDefault() self:SetValue(self.default) end
        function s:NotifyUpdate()
            self.notifies = self.notifies + 1
            self.displayed = self.get()
            if self.redraw then self.redraw(self) end
        end
        O.settings[key] = s
        return s
    end

    local function Header(_, text)
        y = y + 10
        NewLabel(text, "GameFontNormalLarge", LABEL_X - 8)
        local line = Track(content:CreateTexture(nil, "ARTWORK"))
        line:SetColorTexture(1, 1, 1, 0.15)
        line:SetHeight(1)
        line:SetPoint("TOPLEFT", content, "TOPLEFT", LABEL_X - 8, -(y + 22))
        line:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, -(y + 22))
        rows[#rows + 1] = { kind = "header", name = text }
        y = y + 30
    end

    local function AddCheckbox(s, tip)
        local label = NewLabel(s.name, "GameFontHighlight", LABEL_X, y + 5)
        local cb = Track(TryTemplate("CheckButton", content, "UICheckButtonTemplate"))
        cb:SetSize(26, 26)
        cb:SetPoint("TOPLEFT", content, "TOPLEFT", CTRL_X - 4, -y)
        cb:SetScript("OnClick", function(self)
            if not s.updating then s:SetValue(self:GetChecked() and true or false) end
        end)
        Tooltip(cb, s.name, tip)
        s.redraw = function(self) cb:SetChecked(self.get() == true) end
        s.redraw(s)
        rows[#rows + 1] = { kind = "checkbox", setting = s, tooltip = tip, label = label }
        y = y + ROW_H
    end

    local function AddSlider(s, options, tip)
        NewLabel(s.name, "GameFontHighlight", LABEL_X, y + 5)
        local sl = Track(TryTemplate("Slider", content, "OptionsSliderTemplate"))
        sl:SetOrientation("HORIZONTAL")
        sl:SetSize(190, 16)
        sl:SetPoint("TOPLEFT", content, "TOPLEFT", CTRL_X, -(y + 6))
        sl:SetMinMaxValues(options.min, options.max)
        if sl.SetValueStep then sl:SetValueStep(1) end
        if sl.SetObeyStepOnDrag then sl:SetObeyStepOnDrag(true) end
        for _, k in ipairs({ "Low", "High", "Text" }) do
            if sl[k] and sl[k].SetText then sl[k]:SetText("") end
        end
        if sl.SetThumbTexture and not sl.Thumb and not sl.GetThumbTexture then
            sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        end
        local value = NewLabel("", "GameFontHighlightSmall", CTRL_X + 200, y + 7)
        sl:SetScript("OnValueChanged", function(_, v)
            if not s.updating then s:SetValue(math.floor((tonumber(v) or 0) + 0.5)) end
        end)
        Tooltip(sl, s.name, tip)
        s.redraw = function(self)
            local v = self.get()
            self.updating = true
            sl:SetValue(v)
            self.updating = false
            value:SetText(Percent(v))
        end
        s.redraw(s)
        rows[#rows + 1] = { kind = "slider", setting = s, tooltip = tip,
            options = { minValue = options.min, maxValue = options.max, steps = options.max - options.min } }
        y = y + ROW_H
    end

    -- One shared list for every dropdown on the page, built here (out of
    -- combat) so nothing has to be created when it is used. At most
    -- LIST_ROWS entries show at once; longer lists scroll with the mouse wheel.
    local LIST_ROWS, LIST_ROW_H = 12, 20
    local catcher = CreateFrame("Button", nil, UIParent)      -- a click anywhere else closes the list
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN")
    catcher:Hide()
    local okT, popup = pcall(CreateFrame, "Frame", nil, UIParent, "BackdropTemplate")
    if not okT then popup = CreateFrame("Frame", nil, UIParent) end
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:EnableMouse(true)
    popup:EnableMouseWheel(true)
    popup:Hide()
    local styled = false
    if popup.SetBackdrop then
        styled = pcall(function()
            popup:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 14,
                insets = { left = 3, right = 3, top = 3, bottom = 3 } })
            popup:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
        end)
    end
    if not styled then
        local bg = popup:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(popup)
        bg:SetColorTexture(0.05, 0.05, 0.08, 0.97)
    end
    popup.rows = {}
    popup.offset = 0
    local function FillList()
        local list = popup.list or {}
        local cur = popup.setting and popup.setting.get()
        for i = 1, LIST_ROWS do
            local r, o = popup.rows[i], list[popup.offset + i]
            if o then
                r.value = o[1]
                r.text:SetText(o[2])
                if r.text.SetTextColor then
                    if o[1] == cur then r.text:SetTextColor(1, 0.82, 0) else r.text:SetTextColor(1, 1, 1) end
                end
                r:Show()
            else
                r.value = nil
                r:Hide()
            end
        end
    end
    for i = 1, LIST_ROWS do
        local r = CreateFrame("Button", nil, popup)
        r:SetHeight(LIST_ROW_H)
        r:SetPoint("TOPLEFT", popup, "TOPLEFT", 6, -(6 + (i - 1) * LIST_ROW_H))
        r:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -6, -(6 + (i - 1) * LIST_ROW_H))
        local hl = r:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(r)
        hl:SetColorTexture(1, 1, 1, 0.15)
        r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.text:SetPoint("LEFT", r, "LEFT", 6, 0)
        r:SetScript("OnClick", function(self)
            local s, v = popup.setting, self.value
            popup:Hide()
            if s and v ~= nil then s:SetValue(v) end
        end)
        popup.rows[i] = r
    end
    popup:SetScript("OnMouseWheel", function(_, delta)
        local n = #(popup.list or {})
        popup.offset = math.max(0, math.min(math.max(0, n - LIST_ROWS), popup.offset - delta * 3))
        FillList()
    end)
    popup:SetScript("OnHide", function() catcher:Hide(); popup.setting = nil end)
    catcher:SetScript("OnClick", function() popup:Hide() end)
    O.dropdownPopup = popup

    local function OpenList(anchor, s, list)
        if popup:IsShown() and popup.setting == s then popup:Hide() return end
        popup.setting, popup.list, popup.offset = s, list, 0
        local cur = s.get()
        for i = 1, #list do        -- start with the current choice in view
            if list[i][1] == cur then popup.offset = math.max(0, math.min(i - 1, #list - LIST_ROWS)) end
        end
        local shown = math.min(#list, LIST_ROWS)
        popup:SetSize(anchor:GetWidth(), shown * LIST_ROW_H + 12)
        popup:ClearAllPoints()
        popup:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 2)
        FillList()
        catcher:Show()
        popup:Show()
    end

    -- A choice: a button showing the current value; it opens the shared list
    local function AddDropdown(s, choices, tip)
        NewLabel(s.name, "GameFontHighlight", LABEL_X, y + 5)
        local function List() return type(choices) == "function" and choices() or choices end
        local btn = Track(TryTemplate("Button", content, "UIPanelButtonTemplate"))
        btn:SetSize(220, 22)
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", CTRL_X, -(y + 2))
        local arrow = btn:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(16, 16)
        arrow:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
        arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
        btn:SetScript("OnClick", function(self) OpenList(self, s, List()) end)
        Tooltip(btn, s.name, tip)
        s.redraw = function(self)
            local cur, text = self.get(), nil
            for _, o in ipairs(List()) do if o[1] == cur then text = o[2] end end
            btn:SetText(text or tostring(cur))
            if popup:IsShown() and popup.setting == self then FillList() end
        end
        s.redraw(s)
        rows[#rows + 1] = { kind = "dropdown", setting = s, tooltip = tip, button = btn, options = function()
            local out = {}
            for _, o in ipairs(List()) do out[#out + 1] = { value = o[1], label = o[2] } end
            return out
        end }
        y = y + ROW_H
    end

    -- ManaRise's own color picker: red, green, blue and opacity sliders with a
    -- preview. Built here (out of combat) like the rest of the page; changes
    -- apply immediately and Cancel puts the old color back.
    local picker = TryTemplate("Frame", UIParent, "BackdropTemplate")
    picker:SetSize(300, 230)
    picker:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    picker:SetFrameStrata("FULLSCREEN_DIALOG")
    picker:SetClampedToScreen(true)
    picker:SetMovable(true)
    picker:EnableMouse(true)
    picker:RegisterForDrag("LeftButton")
    picker:SetScript("OnDragStart", function(self) self:StartMoving() end)
    picker:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    picker:Hide()
    do
        local styledP = false
        if picker.SetBackdrop then
            styledP = pcall(function()
                picker:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32,
                    edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
            end)
        end
        if not styledP then
            local bg = picker:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(picker)
            bg:SetColorTexture(0.08, 0.08, 0.1, 0.97)
        end
    end
    local pickerTitle = picker:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    pickerTitle:SetPoint("TOPLEFT", picker, "TOPLEFT", 22, -20)
    local pickerBack = picker:CreateTexture(nil, "ARTWORK")      -- shows the opacity against a dark panel
    pickerBack:SetSize(44, 44)
    pickerBack:SetPoint("TOPRIGHT", picker, "TOPRIGHT", -22, -16)
    pickerBack:SetColorTexture(0.15, 0.15, 0.15, 1)
    local pickerSwatch = picker:CreateTexture(nil, "OVERLAY")
    pickerSwatch:SetSize(40, 40)
    pickerSwatch:SetPoint("CENTER", pickerBack, "CENTER")
    local pickerSetting, pickerOriginal, pickerBusy
    local pickerSliders = {}
    local PICK_ROWS = { { "R", "PICK_RED", 255 }, { "G", "PICK_GREEN", 255 },
        { "B", "PICK_BLUE", 255 }, { "A", "PICK_OPACITY", 100 } }
    local function PickerApply()
        if pickerBusy or not pickerSetting then return end
        local v = {}
        for i, row in ipairs(PICK_ROWS) do
            local n = math.floor((pickerSliders[row[1]].slider:GetValue() or 0) + 0.5)
            pickerSliders[row[1]].text:SetText(row[1] == "A" and (n .. "%") or tostring(n))
            v[row[1]] = row[1] == "A" and math.floor(n / 100 * 255 + 0.5) or n
        end
        pickerSwatch:SetColorTexture(v.R / 255, v.G / 255, v.B / 255, v.A / 255)
        pickerSetting:SetValue(string.format("%02X%02X%02X%02X", v.A, v.R, v.G, v.B))
    end
    for i, row in ipairs(PICK_ROWS) do
        local top = 70 + (i - 1) * 28
        local label = picker:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("TOPLEFT", picker, "TOPLEFT", 22, -top)
        label:SetText(L[row[2]])
        local sl = TryTemplate("Slider", picker, "OptionsSliderTemplate")
        sl:SetOrientation("HORIZONTAL")
        sl:SetSize(130, 16)
        sl:SetPoint("TOPLEFT", picker, "TOPLEFT", 100, -(top + 2))
        sl:SetMinMaxValues(0, row[3])
        if sl.SetValueStep then sl:SetValueStep(1) end
        if sl.SetObeyStepOnDrag then sl:SetObeyStepOnDrag(true) end
        for _, k in ipairs({ "Low", "High", "Text" }) do
            if sl[k] and sl[k].SetText then sl[k]:SetText("") end
        end
        if sl.SetThumbTexture and not sl.Thumb and not sl.GetThumbTexture then
            sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        end
        local text = picker:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        text:SetPoint("LEFT", sl, "RIGHT", 10, 0)
        sl:SetScript("OnValueChanged", PickerApply)
        pickerSliders[row[1]] = { slider = sl, text = text }
    end
    local function PickerClose(revert)
        if revert and pickerSetting and pickerOriginal then pickerSetting:SetValue(pickerOriginal) end
        pickerSetting = nil
        picker:Hide()
    end
    local okBtn = TryTemplate("Button", picker, "UIPanelButtonTemplate")
    okBtn:SetSize(110, 24)
    okBtn:SetPoint("BOTTOMLEFT", picker, "BOTTOMLEFT", 30, 20)
    okBtn:SetText(ACCEPT or "OK")
    okBtn:SetScript("OnClick", function() PickerClose(false) end)
    local cancelBtn = TryTemplate("Button", picker, "UIPanelButtonTemplate")
    cancelBtn:SetSize(110, 24)
    cancelBtn:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -30, 20)
    cancelBtn:SetText(CANCEL or "Cancel")
    cancelBtn:SetScript("OnClick", function() PickerClose(true) end)
    O.colorPicker = picker

    local function OpenColorPicker(s)
        pickerSetting, pickerOriginal = s, s.get()
        local r, g, b, a = HexToRGB(pickerOriginal)
        pickerBusy = true
        pickerSliders.R.slider:SetValue(math.floor(r * 255 + 0.5))
        pickerSliders.G.slider:SetValue(math.floor(g * 255 + 0.5))
        pickerSliders.B.slider:SetValue(math.floor(b * 255 + 0.5))
        pickerSliders.A.slider:SetValue(math.floor(a * 100 + 0.5))
        pickerBusy = false
        pickerTitle:SetText(s.name)
        pickerSwatch:SetColorTexture(r, g, b, a)
        for _, row in ipairs(PICK_ROWS) do
            local n = math.floor(pickerSliders[row[1]].slider:GetValue() + 0.5)
            pickerSliders[row[1]].text:SetText(row[1] == "A" and (n .. "%") or tostring(n))
        end
        picker:Show()
    end

    local function AddColor(s, tip)
        NewLabel(s.name, "GameFontHighlight", LABEL_X, y + 5)
        local b = Track(CreateFrame("Button", nil, content))
        b:SetSize(24, 24)
        b:SetPoint("TOPLEFT", content, "TOPLEFT", CTRL_X, -(y + 1))
        local border = b:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints(b)
        border:SetColorTexture(1, 1, 1, 0.8)
        local swatch = b:CreateTexture(nil, "ARTWORK")
        swatch:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
        swatch:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
        b:SetScript("OnClick", function() OpenColorPicker(s) end)
        Tooltip(b, s.name, tip)
        s.redraw = function(self)
            local r, g, bl, a = HexToRGB(self.get())
            swatch:SetColorTexture(r, g, bl, a)
        end
        s.redraw(s)
        rows[#rows + 1] = { kind = "color", setting = s, tooltip = tip, open = function() OpenColorPicker(s) end }
        y = y + ROW_H
    end

    local function Button(_, _, text, onClick, tip)
        local b = Track(TryTemplate("Button", content, "UIPanelButtonTemplate"))
        b:SetSize(220, 24)
        b:SetPoint("TOPLEFT", content, "TOPLEFT", LABEL_X, -(y + 2))
        b:SetText(text)
        b:SetScript("OnClick", onClick)
        Tooltip(b, text, tip)
        rows[#rows + 1] = { kind = "button", text = text, click = onClick, tooltip = tip }
        y = y + ROW_H
        return true
    end

    local VT = { Boolean = "boolean", Number = "number", String = "string" }
    local category                       -- the row helpers keep their old first argument
    local db = function() return ns.db end

    local function Toggle(key, label, tip)
        AddCheckbox(Proxy(key, VT.Boolean, label, ns.defaults[key],
            function() return db()[key] == true end,
            function(v) ns:SetOption(key, v == true, true) end), tip)
    end

    local function PercentSlider(key, label, tip, min)
        AddSlider(Proxy(key, VT.Number, label, math.floor(ns.defaults[key] * 100 + 0.5),
            function() return math.floor(db()[key] * 100 + 0.5) end,
            function(v) ns:SetOption(key, math.floor((tonumber(v) or 0) + 0.5) / 100, true) end),
            { min = min or 0, max = 100 }, tip)
    end

    local function Choice(key, label, choices, tip)
        AddDropdown(Proxy(key, VT.String, label, ns.defaults[key],
            function() return db()[key] end,
            function(v) ns:SetOption(key, v, true) end), choices, tip)
    end

    -- logo in the free space at the top right of the page
    local logo = content:CreateTexture(nil, "ARTWORK")
    logo:SetTexture("Interface\\AddOns\\ManaRise\\Media\\logo")
    logo:SetSize(220, 110)
    logo:SetPoint("TOPRIGHT", content, "TOPRIGHT", -12, 0)

    Toggle("enabled", L.OPT_ENABLE, L.TIP_ENABLED)
    -- the live preview window opens from here
    Button(category, "", L.OPT_PREVIEW, function() O:TogglePreview() end, L.TIP_PREVIEW_WINDOW)

    Header(category, L.OPT_HEADER_LOOK)
    Choice("style", L.OPT_STYLE, { { "liquid", L.OPT_STYLE_LIQUID }, { "flat", L.OPT_STYLE_FLAT },
        { "ice", L.OPT_STYLE_ICE }, { "paper", L.OPT_STYLE_PAPER },
        { "parchment", L.OPT_STYLE_PARCHMENT } }, L.TIP_STYLE)
    PercentSlider("fillAlpha", L.OPT_FILL, L.TIP_FILL)
    PercentSlider("darkAlpha", L.OPT_DARK, L.TIP_DARK)

    Choice("preset", L.OPT_PRESET, {
        { "classic", L.PRESET_classic }, { "fel", L.PRESET_fel }, { "frost", L.PRESET_frost },
        { "colorblind", L.PRESET_colorblind }, { "custom", L.PRESET_custom } }, L.TIP_PRESET)

    Header(category, L.OPT_HEADER_RESOURCES)
    Choice("resource", L.OPT_RESOURCES,
        { { "all", L.OPT_RESOURCES_ALL }, { "mana", L.OPT_RESOURCES_MANA } }, L.TIP_RESOURCE)
    -- One fill color per resource. The swatch works with "AARRGGBB" strings.
    for _, res in ipairs(ns.RESOURCE_KEYS) do
        local key = "color_" .. res
        local s = Proxy(key, VT.String, L["OPT_COLOR_" .. res], "FF" .. ns.DEFAULT_COLOR_HEX[res],
            function() return ns.ColorHexA(db().colors[res]) end,
            function(v) ns:SetOption(key, v, true) end)
        AddColor(s, string.format(L.TIP_COLOR, ns.ResourceName(res)))
    end
    Button(category, "", L.OPT_RESET_COLORS, function()
        for _, res in ipairs(ns.RESOURCE_KEYS) do
            ns:SetOption("color_" .. res, "FF" .. ns.DEFAULT_COLOR_HEX[res])
        end
    end, L.TIP_RESET)

    local function StyleChoices()
        return { { "default", L.OPT_RESSTYLE_DEFAULT }, { "liquid", L.OPT_STYLE_LIQUID },
            { "flat", L.OPT_STYLE_FLAT }, { "ice", L.OPT_STYLE_ICE }, { "paper", L.OPT_STYLE_PAPER },
            { "parchment", L.OPT_STYLE_PARCHMENT } }
    end
    Header(category, L.OPT_HEADER_RESSTYLE)
    -- Under each resource's style: that resource's own settings for the style
    -- it uses. "Same as the main setting" (the default) follows the settings
    -- further down; the wave and bubble rows only show for styles that use them.
    local function PercentChoices(cur)
        local list = { { "default", L.OPT_RESWAVE_DEFAULT } }
        local seen = cur == nil or cur == "default"
        for n = 0, 100, 10 do
            list[#list + 1] = { tostring(n), n .. "%" }
            if tostring(n) == cur then seen = true end
        end
        if not seen then list[#list + 1] = { cur, cur .. "%" } end
        return list
    end
    local function OwnPercent(res, setting)
        local v = ns:ResSettingOwn(res, setting)
        return v and tostring(math.floor(v * 100 + 0.5)) or "default"
    end
    O.resGroups = {}
    O.resProxies = {}
    -- One "Resource" dropdown per area picks which resource's rows show. The
    -- choice starts on the player's main resource and each area keeps its own.
    local function ResourceChoices()
        local list = {}
        for _, r in ipairs(ns.RESOURCE_KEYS) do list[#list + 1] = { r, (string.gsub(ns.ResourceName(r), "^%l", string.upper)) } end
        return list
    end
    local startRes = "mana"
    do
        local ok, pt = pcall(function() return UnitPowerType and UnitPowerType("player") end)
        local byType = { [1] = "rage", [2] = "focus", [3] = "energy" }
        if ok and pt and byType[pt] then startRes = byType[pt] end
    end
    O.selectedStyleRes, O.selectedFxRes = startRes, startRes
    local function Selector(key, field)
        AddDropdown(Proxy(key, VT.String, L.OPT_RES_SELECT, startRes,
            function() return O[field] end,
            function(v) O[field] = v; O:RefreshResource() end),
            ResourceChoices(), L.TIP_RES_SELECT)
    end
    Selector("resSelect", "selectedStyleRes")
    for _, res in ipairs(ns.RESOURCE_KEYS) do
        local rname = ns.ResourceName(res)
        local key = "resstyle_" .. res
        grp = {}
        AddDropdown(Proxy(key, VT.String, L.OPT_RESSTYLE_SHORT, "default",
            function() return (db().resStyles and db().resStyles[res]) or "default" end,
            function(v) ns:SetOption(key, v, true) end),
            StyleChoices(), string.format(L.TIP_RESSTYLE, rname))
        O.resProxies[#O.resProxies + 1] = O.settings[key]
        for _, f in ipairs({
            { "resopacity", "fillAlpha", L.OPT_RESOPACITY_SHORT, L.TIP_RESOPACITY },
            { "resdark", "darkAlpha", L.OPT_RESDARK_SHORT, L.TIP_RESDARK } }) do
            local k = f[1] .. "_" .. res
            AddDropdown(Proxy(k, VT.String, f[3], "default",
                function() return OwnPercent(res, f[2]) end,
                function(v) ns:SetOption(k, v == "default" and v or (tonumber(v) or 0) / 100, true) end),
                function() return PercentChoices(OwnPercent(res, f[2])) end, string.format(f[4], rname))
            O.resProxies[#O.resProxies + 1] = O.settings[k]
        end
        O.resGroups[#O.resGroups + 1] = { res = res, kind = "style", objs = grp, last = #all, height = 3 * ROW_H }
        grp = {}
        for _, f in ipairs({
            { "reswaves", "OPT_RESWAVES_SHORT", "TIP_RESWAVES" },
            { "reswaveheight", "OPT_RESWAVEHEIGHT_SHORT", "TIP_RESWAVEHEIGHT" } }) do
            local k = f[1] .. "_" .. res
            local setting = ns.RES_FIELDS[f[1]].setting
            local choices = f[1] == "reswaves"
                and { { "default", L.OPT_RESWAVE_DEFAULT }, { "calm", L.OPT_WAVES_CALM },
                      { "normal", L.OPT_WAVES_NORMAL }, { "lively", L.OPT_WAVES_LIVELY } }
                or { { "default", L.OPT_RESWAVE_DEFAULT }, { "low", L.OPT_WAVE_LOW },
                      { "medium", L.OPT_WAVE_MEDIUM }, { "high", L.OPT_WAVE_HIGH } }
            AddDropdown(Proxy(k, VT.String, L[f[2]], "default",
                function() return ns:ResSettingOwn(res, setting) or "default" end,
                function(v) ns:SetOption(k, v, true) end),
                choices, string.format(L[f[3]], rname))
            O.resProxies[#O.resProxies + 1] = O.settings[k]
        end
        do
            local k = "resbubbles_" .. res
            AddDropdown(Proxy(k, VT.String, L.OPT_RESBUBBLES_SHORT, "default",
                function()
                    local v = ns:ResSettingOwn(res, "bubbles")
                    if v == nil then return "default" end
                    return v and "on" or "off"
                end,
                function(v) ns:SetOption(k, v == "default" and v or v == "on", true) end),
                { { "default", L.OPT_RESWAVE_DEFAULT }, { "on", L.ON }, { "off", L.OFF } },
                string.format(L.TIP_RESBUBBLES, rname))
            O.resProxies[#O.resProxies + 1] = O.settings[k]
        end
        O.resGroups[#O.resGroups + 1] = { res = res, kind = "waves", objs = grp, last = #all, height = 3 * ROW_H }
        grp = nil
    end

    Header(category, L.OPT_HEADER_LIQUID)
    Choice("waveHeight", L.OPT_WAVE_HEIGHT,
        { { "low", L.OPT_WAVE_LOW }, { "medium", L.OPT_WAVE_MEDIUM }, { "high", L.OPT_WAVE_HIGH } }, L.TIP_WAVE_HEIGHT)
    Choice("waves", L.OPT_WAVES,
        { { "calm", L.OPT_WAVES_CALM }, { "normal", L.OPT_WAVES_NORMAL }, { "lively", L.OPT_WAVES_LIVELY } }, L.TIP_WAVES)
    Toggle("bubbles", L.OPT_BUBBLES, L.TIP_BUBBLES)

    Header(category, L.OPT_HEADER_BEHAVIOR)
    Toggle("glow", L.OPT_GLOW, L.TIP_GLOW)
    Toggle("smooth", L.OPT_SMOOTH, L.TIP_SMOOTH)
    Toggle("pulse", L.OPT_PULSE, L.TIP_PULSE)
    Choice("readyAnim", L.OPT_ANIM, { { "flash", L.OPT_ANIM_FLASH }, { "sweep", L.OPT_ANIM_SWEEP },
        { "double", L.OPT_ANIM_DOUBLE } }, L.TIP_ANIM)

    Header(category, L.OPT_HEADER_FXCOLORS)
    Selector("fxSelect", "selectedFxRes")
    for _, res in ipairs(ns.RESOURCE_KEYS) do
        grp = {}
        for _, fx in ipairs(ns.FX_ORDER) do
            local key = "fx_" .. fx .. "_" .. res
            local s = Proxy(key, VT.String, L["OPT_FX_" .. fx], "FFFFFFFF",
                function()
                    local r, g, b, a = ns.EffectRGB(res, fx, db().colors[res])
                    return ns.ColorHexA({ r = r, g = g, b = b, a = a })
                end,
                function(v) ns:SetOption(key, v, true) end)
            AddColor(s, string.format(L.TIP_FXCOLOR, L["OPT_FX_" .. fx], ns.ResourceName(res)))
        end
        O.resGroups[#O.resGroups + 1] = { res = res, kind = "fx", objs = grp, last = #all, height = 3 * ROW_H }
        grp = nil
    end
    Button(category, "", L.OPT_RESET_FXCOLORS, function()
        for _, fx in ipairs(ns.FX_ORDER) do
            for _, res in ipairs(ns.RESOURCE_KEYS) do ns:SetOption("fx_" .. fx .. "_" .. res, "auto") end
        end
    end, L.TIP_RESET_FXCOLORS)

    Header(category, L.OPT_HEADER_SIGNALS)
    Toggle("range", L.OPT_RANGE, L.TIP_RANGE)
    Choice("rangeStyle", L.OPT_RANGE_STYLE, { { "tint", L.OPT_RANGE_STYLE_TINT },
        { "grey", L.OPT_RANGE_STYLE_GREY }, { "border", L.OPT_RANGE_STYLE_BORDER } }, L.TIP_RANGE_STYLE)
    AddColor(Proxy("rangeColor", VT.String, L.OPT_RANGE_COLOR, "FF" .. ns.defaults.rangeColor,
        function() return "FF" .. db().rangeColor end,
        function(v) ns:SetOption("rangeColor", v, true) end), L.TIP_RANGE_COLOR)
    PercentSlider("rangeAlpha", L.OPT_RANGE_ALPHA, L.TIP_RANGE_ALPHA, 5)
    Toggle("rangeUsable", L.OPT_RANGE_USABLE, L.TIP_RANGE_USABLE)
    -- sound dropdowns: built-in sounds, Custom, and any sounds LibSharedMedia
    -- (provided by another addon) has registered
    local function SoundChoices()
        local list = { { "off", L.OPT_SOUND_OFF }, { "tick", L.OPT_SOUND_TICK },
            { "chime", L.OPT_SOUND_CHIME }, { "bell", L.OPT_SOUND_BELL }, { "custom", L.OPT_SOUND_CUSTOM } }
        for _, e in ipairs(ns.SOUND_PACK) do list[#list + 1] = { "pack:" .. e[1], e[2] } end
        local ok, names = pcall(function()
            local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
            return lsm and lsm.List and lsm:List("sound")
        end)
        if ok and type(names) == "table" then
            for i = 1, #names do list[#list + 1] = { "lsm:" .. names[i], names[i] } end
        end
        return list
    end
    local function SoundRows(slot, key, label, tip, customText, testText)
        Choice(key, label, SoundChoices, tip)
        -- no text box exists in the Settings API: a small popup takes the path or ID
        if type(StaticPopup_Show) == "function" and type(StaticPopupDialogs) == "table" then
            Button(category, "", customText, function()
                StaticPopupDialogs["MANARISE_CUSTOM_SOUND"] = {
                    text = "%s", button1 = ACCEPT or "OK", button2 = CANCEL or "Cancel",
                    hasEditBox = true, editBoxWidth = 330, maxLetters = 240,
                    timeout = 0, whileDead = true, hideOnEscape = true,
                    OnShow = function(self, data)
                        local box = self.editBox or self.EditBox
                        if box then box:SetText(ns.db[data.key .. "Custom"] or ""); box:HighlightText() end
                    end,
                    OnAccept = function(self, data)
                        local box = self.editBox or self.EditBox
                        if not box then return end
                        if ns:SetOption(data.key .. "Custom", box:GetText()) then
                            ns:SetOption(data.key, "custom")
                            ns.ActionBars:PlaySlot(data.slot, "custom", true)
                        end
                    end,
                    EditBoxOnEnterPressed = function(box)
                        local parent = box:GetParent()
                        if parent and parent.button1 then parent.button1:Click() end
                    end,
                }
                StaticPopup_Show("MANARISE_CUSTOM_SOUND", string.format(L.POPUP_CUSTOM_SOUND, L.SLOT_READY),
                    nil, { key = key, slot = slot })
            end, L.TIP_SOUND_CUSTOM)
        end
        Button(category, "", testText, function()
            if ns.ActionBars then
                ns.ActionBars:PlaySlot(slot, ns.db[key] ~= "off" and ns.db[key] or "tick", true)
            end
        end, L.TIP_SOUND_TEST)
    end
    SoundRows("ready", "sound", L.OPT_SOUND, L.TIP_SOUND, L.OPT_SOUND_CUSTOM_BUTTON, L.OPT_SOUND_TEST)
    Toggle("soundOnly", L.OPT_SOUNDONLY, L.TIP_SOUNDONLY)
    if type(StaticPopup_Show) == "function" and type(StaticPopupDialogs) == "table" then
        Button(category, "", L.OPT_SOUNDSPELL_BUTTON, function()
            StaticPopupDialogs["MANARISE_SOUND_SPELL"] = {
                text = "%s", button1 = ACCEPT or "OK", button2 = CANCEL or "Cancel",
                hasEditBox = true, editBoxWidth = 260, maxLetters = 120,
                timeout = 0, whileDead = true, hideOnEscape = true,
                OnAccept = function(self)
                    local box = self.editBox or self.EditBox
                    if not box then return end
                    local id, name = ns.ActionBars:ResolveSpellText(box:GetText())
                    if id then
                        ns.db.soundSpells[id] = true
                        ns:Print(L.SOUNDSPELL_ADDED, name or box:GetText(), id)
                    else
                        ns:Print(L.SOUNDSPELL_UNKNOWN, box:GetText())
                    end
                end,
                EditBoxOnEnterPressed = function(box)
                    local parent = box:GetParent()
                    if parent and parent.button1 then parent.button1:Click() end
                end,
            }
            StaticPopup_Show("MANARISE_SOUND_SPELL", L.POPUP_SOUNDSPELL)
        end, L.TIP_SOUNDSPELL)
    end

    Header(category, L.OPT_HEADER_OTHER)
    AddCheckbox(Proxy("minimap", VT.Boolean, L.OPT_MINIMAP, true,
        function() return not ns.root.minimap.hide end,
        function(v) ns:SetOption("minimap", v == true, true) end), L.TIP_MINIMAP)
    AddDropdown(Proxy("profileMode", VT.String, L.OPT_PROFILE, "account",
        function() return ns.root.profileMode end,
        function(v) ns:SetOption("profileMode", v, true) end),
        { { "account", L.OPT_PROFILE_ACCOUNT }, { "class", L.OPT_PROFILE_CLASS },
          { "character", L.OPT_PROFILE_CHARACTER } }, L.TIP_PROFILE)

    -- Bar categories: pick a category, then its settings. A category that
    -- uses the global settings switches to its own values on the first change.
    Header(category, L.OPT_HEADER_CATEGORIES)
    O.selectedCat = O.selectedCat or ns.CATEGORIES[1]
    O.catSettings = {}
    local catChoices = {}
    for _, c in ipairs(ns.CATEGORIES) do catChoices[#catChoices + 1] = { c, L["CAT_" .. c] } end
    local function CatProxy(key, varType, label, default)
        local s = Proxy("cat_" .. key, varType, label, default,
            function() return ns:CatValue(O.selectedCat, key) end,
            function(v)
                if key ~= "enabled" and key ~= "custom" and not ns:CatCustom(O.selectedCat) then
                    ns:SetCatOption(O.selectedCat, "custom", true, true)
                end
                ns:SetCatOption(O.selectedCat, key, v, true)
                O:RefreshCategory()
            end)
        O.catSettings[#O.catSettings + 1] = s
        return s
    end
    AddDropdown(Proxy("catSelect", VT.String, L.OPT_CAT_SELECT, ns.CATEGORIES[1],
        function() return O.selectedCat end,
        function(v) O.selectedCat = v; O:RefreshCategory() end), catChoices, L.TIP_CAT_SELECT)
    AddCheckbox(CatProxy("enabled", VT.Boolean, L.OPT_CAT_ENABLED, true), L.TIP_CAT_ENABLED)
    do
        local g = Proxy("cat_global", VT.Boolean, L.OPT_CAT_GLOBAL, true,
            function() return not ns:CatCustom(O.selectedCat) end,
            function(v)
                ns:SetCatOption(O.selectedCat, "custom", not v, true)
                O:RefreshCategory()
            end)
        O.catSettings[#O.catSettings + 1] = g
        AddCheckbox(g, L.TIP_CAT_GLOBAL)
    end
    -- everything below only shows while the category has its own settings
    O.catBaseY = y
    tracked = {}
    O.catOwnControls = tracked
    AddDropdown(CatProxy("style", VT.String, L.OPT_STYLE, ns.defaults.style), { { "liquid", L.OPT_STYLE_LIQUID },
        { "flat", L.OPT_STYLE_FLAT }, { "ice", L.OPT_STYLE_ICE }, { "paper", L.OPT_STYLE_PAPER },
        { "parchment", L.OPT_STYLE_PARCHMENT } }, L.TIP_STYLE)
    AddDropdown(CatProxy("waveHeight", VT.String, L.OPT_WAVE_HEIGHT, ns.defaults.waveHeight),
        { { "low", L.OPT_WAVE_LOW }, { "medium", L.OPT_WAVE_MEDIUM }, { "high", L.OPT_WAVE_HIGH } }, L.TIP_WAVE_HEIGHT)
    AddDropdown(CatProxy("waves", VT.String, L.OPT_WAVES, ns.defaults.waves),
        { { "calm", L.OPT_WAVES_CALM }, { "normal", L.OPT_WAVES_NORMAL }, { "lively", L.OPT_WAVES_LIVELY } }, L.TIP_WAVES)
    AddCheckbox(CatProxy("glow", VT.Boolean, L.OPT_GLOW, true), L.TIP_GLOW)
    AddCheckbox(CatProxy("overlay", VT.Boolean, L.OPT_CAT_OVERLAY, true), L.TIP_CAT_OVERLAY)
    for _, res in ipairs(ns.RESOURCE_KEYS) do
        local key = "color_" .. res
        AddColor(CatProxy(key, VT.String, L["OPT_COLOR_" .. res], "FF" .. ns.DEFAULT_COLOR_HEX[res]),
            string.format(L.TIP_COLOR, ns.ResourceName(res)))
    end
    Button(category, "", L.OPT_RESET_COLORS, function()
        for _, res in ipairs(ns.RESOURCE_KEYS) do
            ns:SetCatOption(O.selectedCat, "color_" .. res, "FF" .. ns.DEFAULT_COLOR_HEX[res], true)
        end
        O:RefreshCategory()
    end, L.TIP_RESET)

    tracked = nil
    O.catFullY = y
    O.content = content
    O:ApplyResourceLayout()
    O:ApplyCategoryLayout()
    -- values may have changed while the page was closed (slash commands)
    canvas:SetScript("OnShow", function() O:Refresh() end)
    canvas:SetScript("OnHide", function() popup:Hide(); picker:Hide() end)

    local cat = Settings.RegisterCanvasLayoutCategory(canvas, "ManaRise")
    Settings.RegisterAddOnCategory(cat)
    O.category = cat
end

---------------------------------------------------------------------------
-- Live preview. The "Preview" row on the ManaRise page opens a separate
-- window you can close (X, or Escape) with a few sample buttons that loop
-- fill/clear with made-up resources and follow every setting change. The
-- sample buttons are ManaRise's own, drawn by the same code as the real ones
-- (ActionBars.lua). Nothing is attached to the game's settings window.
---------------------------------------------------------------------------
-- The window with the sample buttons. Created once, out of combat.
function O:BuildPreviewWindow()
    if self.previewWindow or ns:InCombat() or not ns.ActionBars then return self.previewWindow end
    local AB = ns.ActionBars
    local ok, err = pcall(function()
        -- same dialog look as the game's Options window (gold border, dark
        -- panel); falls back to a plain dark panel if backdrops are missing
        local okT, w = pcall(CreateFrame, "Frame", "ManaRisePreviewWindow", UIParent, "BackdropTemplate")
        if not okT then w = CreateFrame("Frame", "ManaRisePreviewWindow", UIParent) end
        w:SetSize(AB.PREVIEW_WIDTH + 48, AB.PREVIEW_HEIGHT + 78)
        w:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        w:SetFrameStrata("DIALOG")
        w:SetClampedToScreen(true)
        w:SetMovable(true)
        w:EnableMouse(true)
        w:RegisterForDrag("LeftButton")
        w:SetScript("OnDragStart", function(self) self:StartMoving() end)
        w:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        local styled = false
        if w.SetBackdrop then
            styled = pcall(function()
                w:SetBackdrop({
                    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                    tile = true, tileSize = 32, edgeSize = 32,
                    insets = { left = 11, right = 12, top = 12, bottom = 11 },
                })
            end)
        end
        if not styled then
            local bg = w:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(w)
            bg:SetColorTexture(0.05, 0.05, 0.08, 0.92)
        end
        -- title centered across the window, between the borders
        local title = w:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", w, "TOPLEFT", 24, styled and -16 or -10)
        title:SetPoint("TOPRIGHT", w, "TOPRIGHT", -24, styled and -16 or -10)
        if title.SetJustifyH then title:SetJustifyH("CENTER") end
        title:SetText(L.PREVIEW_LABEL)
        local close = CreateFrame("Button", nil, w, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", w, "TOPRIGHT", styled and -6 or 2, styled and -6 or 2)
        local strip = CreateFrame("Frame", nil, w)
        strip:SetSize(AB.PREVIEW_WIDTH, AB.PREVIEW_HEIGHT)
        strip:SetPoint("BOTTOM", w, "BOTTOM", 0, 22)
        if not AB:CreatePreview(strip) then error("sample buttons could not be built") end
        w:SetScript("OnShow", function() AB:SetPreviewRunning(true) end)
        w:SetScript("OnHide", function() AB:SetPreviewRunning(false) end)
        w:Hide()
        if UISpecialFrames then table.insert(UISpecialFrames, "ManaRisePreviewWindow") end
        self.previewWindow = w
    end)
    if not ok then
        self.previewProblem = tostring(err)
        ns:LogError("options preview", err)
    end
    return self.previewWindow
end

function O:TogglePreview()
    local w = self.previewWindow
    if w and w:IsShown() then w:Hide() return end
    if not w then
        if ns:InCombat() then ns:Print(L.PREVIEW_COMBAT) return end
        w = self:BuildPreviewWindow()
    end
    if w then w:Show() end
end

-- Called at login. Deferred to the end of combat after a /reload in combat.
function O:Register()
    if self.category or self.problem then return end
    -- troubleshooting switch (/mr panel off): leave the game's settings alone
    if ns.root and ns.root.panelMode == "off" then
        self.problem = "settings page turned off with /mr panel off"
        return
    end
    if not HasSettingsAPI() then
        self.problem = L.PANEL_NO_API
        return
    end
    if ns:InCombat() then
        self.registerAfterCombat = true
        return
    end
    self.registerAfterCombat = false
    local ok, err = pcall(Build)
    if not ok then
        self.category = nil
        wipe(self.settings)
        self.problem = tostring(err)
        ns:LogError("options panel", err)
        ns:Print(L.PANEL_FAILED, self.problem)
    end
end

-- Redraw panel controls after a change made outside the panel.
-- key: one db key, or nil for all of them.
function O:Refresh(key)
    if key then
        local s = self.settings[key]
        if s and s.NotifyUpdate then s:NotifyUpdate() end
        return
    end
    for _, s in pairs(self.settings) do
        if s.NotifyUpdate then s:NotifyUpdate() end
    end
    self:ApplyResourceLayout()
end

-- The per-resource settings follow the style the resource uses: repaint them
-- and show or hide the wave and bubble rows (the argument is unused: the
-- main style can change every resource at once).
function O:RefreshResource()
    for _, s in ipairs(self.resProxies or {}) do s:NotifyUpdate() end
    for _, k in ipairs({ "resSelect", "fxSelect" }) do
        if self.settings[k] then self.settings[k]:NotifyUpdate() end
    end
    self:ApplyResourceLayout()
end

-- Wave and bubble rows only show for styles that use them. A hidden group
-- takes no room: everything below it moves up.
function O:ApplyResourceLayout()
    local groups, all, content = self.resGroups, self.allControls, self.content
    if not groups or not all or not content then return end
    for _, g in ipairs(groups) do
        if g.kind == "fx" then
            g.hidden = g.res ~= self.selectedFxRes
        elseif g.kind == "style" then
            g.hidden = g.res ~= self.selectedStyleRes
        else
            g.hidden = g.res ~= self.selectedStyleRes or not ns:StyleUses(ns:StyleFor(nil, g.res), "waves")
        end
        for _, obj in ipairs(g.objs) do
            if g.hidden then obj:Hide() else obj:Show() end
        end
    end
    local total, gi, shift = 0, 1, 0
    for i, obj in ipairs(all) do
        while groups[gi] and groups[gi].last < i do
            if groups[gi].hidden then shift = shift + groups[gi].height end
            gi = gi + 1
        end
        if (obj.mrShift or 0) ~= shift and obj.mrPoints and #obj.mrPoints > 0 then
            obj.mrShift = shift
            obj:ClearAllPoints()
            for _, p in ipairs(obj.mrPoints) do
                if p[2] == content and p[5] then
                    obj:mrRawSetPoint(p[1], p[2], p[3], p[4], p[5] + shift)
                else
                    obj:mrRawSetPoint(unpack(p))
                end
            end
        end
    end
    for _, g in ipairs(groups) do if g.hidden then total = total + g.height end end
    self.hiddenHeight = total
    if self.catOwnControls then self:ApplyCategoryLayout() end
end

-- Redraw the category controls (after another category or a change was picked).
function O:RefreshCategory()
    for _, s in ipairs(self.catSettings or {}) do s:NotifyUpdate() end
    if self.settings.catSelect then self.settings.catSelect:NotifyUpdate() end
    self:ApplyCategoryLayout()
end

-- The look settings of a category only show while it has its own settings
-- ("Use global settings" unticked). They are the last rows on the page, so
-- hiding them only shortens the page.
function O:ApplyCategoryLayout()
    if not self.content or not self.catOwnControls then return end
    local own = ns:CatCustom(self.selectedCat)
    for _, obj in ipairs(self.catOwnControls) do
        if own then obj:Show() else obj:Hide() end
    end
    self.content:SetHeight((own and self.catFullY or self.catBaseY) - (self.hiddenHeight or 0) + 20)
end

function O:Open()
    if not self.category then
        if self.registerAfterCombat then
            self.openAfterCombat = true
            ns:Print(L.PANEL_AFTER_COMBAT)
        else
            ns:Print(L.PANEL_UNAVAILABLE, self.problem or L.PANEL_NOT_READY)
        end
        return
    end
    if ns:InCombat() then
        self.openAfterCombat = true
        ns:Print(L.PANEL_AFTER_COMBAT)
        return
    end
    Settings.OpenToCategory(self.category:GetID())
end

function O:OnCombatEnded()
    if self.registerAfterCombat then self:Register() end
    if self.openAfterCombat then
        self.openAfterCombat = false
        self:Open()
    end
end

function O:StatusText()
    if self.category then return L.PANEL_LOCATION end
    if self.registerAfterCombat then return L.PANEL_WAITING end
    return string.format(L.PANEL_UNAVAILABLE_STATUS, tostring(self.problem or L.PANEL_NOT_REGISTERED))
end
