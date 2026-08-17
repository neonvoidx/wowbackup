local BBG = {}
_G["BetterBlizzGUI"] = BBG

local PAD_X          = 1
local PAD_TOP        = -17
local SPACING        = 6
local TITLE_HEIGHT   = 20
local TITLE_SPACING  = 16
local CB_HEIGHT      = 22
local CB_GAP         = -1
local CB_SUB_HEIGHT  = 19
local CB_XPOS        = -6
local CB_AFTER_TITLE = 5
local DD_LABEL_H     = 16
local DD_BTN_H       = 24
local SLIDER_ROW_H   = 20
local ROW_LABEL_W    = 195
local BTN_HEIGHT     = 24
local GROUP_PAD      = 10
local FONT_OBJ       = "GameFontHighlight"
local SCROLLBAR_W    = 8
local SCROLL_STEP    = 45
local CONTENT_INSET_X = 11
local CONTENT_INSET_Y = 6
local PAD_BOTTOM     = 24
local WIDGET_CATS    = { "checkboxes", "sliders", "dropdowns", "titles", "dividers", "buttons", "labels" }

local function roundToStep(value, step)
    return math.floor(value / step + 0.5) * step
end

local function labelToKey(label)
    local words = {}
    for w in label:gmatch("[%a%d]+") do words[#words+1] = w end
    if #words == 0 then return label end
    local result = words[1]:lower()
    for i = 2, #words do
        local w = words[i]
        result = result .. w:sub(1,1):upper() .. w:sub(2):lower()
    end
    return result
end

local function registerWidget(parent, category, key, widget)
    if not parent[category] then parent[category] = {} end
    local cat = parent[category]
    cat[key] = widget
    if widget and widget.SetParent and cat.SetParent then
        widget:SetParent(cat)
    end
end

local function OwningPanel(frame)
    while frame do
        if frame._refreshers then return frame end
        frame = frame._panel
    end
end

local function addRefresher(parent, fn)
    local panel = OwningPanel(parent)
    if not panel then return end
    panel._refreshers[#panel._refreshers + 1] = fn
end

function BBG.RefreshPanel(panel)
    if not (panel and panel._refreshers) then return end
    for _, fn in ipairs(panel._refreshers) do fn() end
    if panel._layoutRefresh then panel._layoutRefresh() end
    BBG.UpdateScrollHeight(panel)
end

local function nextIncKey(parent, category, prefix)
    if not parent[category] then parent[category] = {} end
    local i = 1
    while parent[category][prefix..i] do i = i + 1 end
    return prefix..i
end

local function InitCursor(frame, startY, padX)
    frame._cursorY = startY or -PAD_TOP
    frame._padX    = padX   or PAD_X
end

local function CursorY(frame)
    return frame._cursorY
end

local function Advance(frame, height, spacing)
    frame._justHadTitle = nil
    frame._cursorY = frame._cursorY - height - (spacing or SPACING)
end

local function WidgetSpacing(config, default)
    if config and config.spacing ~= nil then return config.spacing end
    return default or SPACING
end

function BBG.GetCursor(frame)  return frame._cursorY end
function BBG.SetCursor(frame, y) frame._cursorY = y  end

function BBG.MakeSection(parent)
    local s = CreateFrame("Frame", nil, parent)
    s:SetWidth(parent:GetWidth())
    s:SetHeight(1)
    s:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, CursorY(parent))
    InitCursor(s, 0, parent._padX)
    s._panel = parent

    local panel = OwningPanel(parent)
    if panel then
        panel._sections = panel._sections or {}
        panel._sections[#panel._sections + 1] = s
    end
    return s
end

function BBG.FinaliseSection(section)
    local h = math.abs(section._cursorY)
    section:SetHeight(math.max(h, 1))
    return h
end

function BBG.MakeSubTitleGroup(title, parent, iconColor)
    local padX = parent._padX
    local yPos = CursorY(parent) - 6

    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetText(title)
    fs:SetJustifyH("LEFT")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", padX + 9, yPos)

    if iconColor then
        local icon = parent:CreateTexture(nil, "ARTWORK")
        icon:SetAtlas("GM-icon-headCount", false)
        icon:SetSize(17, 17)
        icon:SetDesaturated(true)
        icon:SetVertexColor(iconColor[1], iconColor[2], iconColor[3])
        icon:SetPoint("RIGHT", fs, "LEFT", 1, 0)
    end

    Advance(parent, TITLE_HEIGHT - 2, 0)

    return { parent = parent }
end

function BBG.FinaliseSubTitleGroup(handle)
    handle.parent._cursorY = handle.parent._cursorY - 6
end

local function SetScroll(panel, value)
    local scroll = panel._scroll
    local range  = scroll:GetVerticalScrollRange()
    if value < 0     then value = 0     end
    if value > range then value = range end
    scroll:SetVerticalScroll(value)
    BBG.UpdateScrollBar(panel)
end

function BBG.UpdateScrollBar(panel)
    local scroll, bar = panel._scroll, panel._scrollBar
    if not (scroll and bar) then return end

    local range = scroll:GetVerticalScrollRange()
    if range <= 1 then
        bar:Hide()
        if scroll:GetVerticalScroll() ~= 0 then scroll:SetVerticalScroll(0) end
        return
    end
    bar:Show()

    local trackH  = bar:GetHeight()
    local visible = scroll:GetHeight()
    local thumbH  = math.max(28, trackH * visible / (visible + range))
    if thumbH > trackH then thumbH = trackH end

    local current = scroll:GetVerticalScroll()
    if current > range then
        scroll:SetVerticalScroll(range)
        current = range
    end

    bar.thumb:SetHeight(thumbH)
    bar.thumb:ClearAllPoints()
    bar.thumb:SetPoint("LEFT",  bar, "LEFT",  0, 0)
    bar.thumb:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    bar.thumb:SetPoint("TOP",   bar, "TOP",   0, -(current / range) * (trackH - thumbH))
end

function BBG.UpdateScrollHeight(panel)
    if not (panel and panel._scroll) then return end

    local h = math.abs(panel._cursorY or 0)
    if panel._contentBottom and panel._contentBottom > h then
        h = panel._contentBottom
    end
    for _, s in ipairs(panel._sections or {}) do
        if s:IsShown() then
            local _, _, _, _, y = s:GetPoint(1)
            local bottom = math.abs(y or 0) + s:GetHeight()
            if bottom > h then h = bottom end
        end
    end

    h = h + PAD_BOTTOM
    if math.abs((panel._contentHeight or 0) - h) > 0.5 then
        panel._contentHeight = h
        panel:SetHeight(h)
    end
    panel._scroll:UpdateScrollChildRect()
    BBG.UpdateScrollBar(panel)
end

local function NoteContentBottom(frame, bottom)
    local panel = OwningPanel(frame)
    if not panel then return end
    if not panel._contentBottom or bottom > panel._contentBottom then
        panel._contentBottom = bottom
    end
end
BBG.NoteContentBottom = NoteContentBottom

local function BuildScrollPanel(uniqueName, width, height)
    local canvas = CreateFrame("Frame", uniqueName, UIParent)
    canvas:SetSize(width, height)
    canvas:Hide()

    local scroll = CreateFrame("ScrollFrame", uniqueName .. "_Scroll", canvas)
    scroll:SetPoint("TOPLEFT",     canvas, "TOPLEFT",      0, 0)
    scroll:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", -(SCROLLBAR_W + 4), 0)

    local panel = CreateFrame("Frame", uniqueName .. "_Content", scroll)
    panel:SetSize(width, height)
    scroll:SetScrollChild(panel)

    local bar = CreateFrame("Frame", nil, canvas)
    bar:SetWidth(SCROLLBAR_W)
    bar:SetPoint("TOPLEFT",    scroll, "TOPRIGHT", 2, -2)
    bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 2, 2)

    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints(bar)
    track:SetColorTexture(0, 0, 0, 0.35)

    local thumb = CreateFrame("Button", nil, bar)
    thumb:SetHeight(40)
    thumb:SetPoint("TOP",   bar, "TOP",   0, 0)
    thumb:SetPoint("LEFT",  bar, "LEFT",  0, 0)
    thumb:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    local thumbTex = thumb:CreateTexture(nil, "ARTWORK")
    thumbTex:SetAllPoints(thumb)
    thumbTex:SetColorTexture(0.45, 0.45, 0.45, 0.9)
    thumb:SetScript("OnEnter", function() thumbTex:SetColorTexture(0.6, 0.6, 0.6, 0.95) end)
    thumb:SetScript("OnLeave", function() thumbTex:SetColorTexture(0.45, 0.45, 0.45, 0.9) end)
    bar.thumb = thumb

    thumb:SetScript("OnMouseDown", function(self)
        local _, cursorY = GetCursorPosition()
        local grabY      = cursorY / UIParent:GetEffectiveScale()
        local grabScroll = scroll:GetVerticalScroll()
        self:SetScript("OnUpdate", function(dragThumb)
            if not IsMouseButtonDown("LeftButton") then
                dragThumb:SetScript("OnUpdate", nil)
                return
            end
            local trackH = bar:GetHeight() - self:GetHeight()
            local range  = scroll:GetVerticalScrollRange()
            if trackH <= 0 or range <= 0 then return end
            local _, y = GetCursorPosition()
            local delta = grabY - (y / UIParent:GetEffectiveScale())
            SetScroll(panel, grabScroll + delta * (range / trackH))
        end)
    end)
    thumb:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)
    thumb:SetScript("OnHide",    function(self) self:SetScript("OnUpdate", nil) end)

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        SetScroll(panel, scroll:GetVerticalScroll() - delta * SCROLL_STEP)
    end)
    scroll:SetScript("OnSizeChanged", function(self)
        local w = self:GetWidth()
        panel:SetWidth(w)
        for _, s in ipairs(panel._sections or {}) do
            s:SetWidth(w)
        end
        BBG.UpdateScrollHeight(panel)
    end)

    local function ClampCanvasHeight(self)
        local container = self:GetParent()
        if not (container and container ~= UIParent and container:GetHeight() > 1) then return end
        if self:GetHeight() <= container:GetHeight() + 1 then return end

        local myLeft, myTop = self:GetLeft(), self:GetTop()
        local cLeft, cTop   = container:GetLeft(), container:GetTop()
        if not (myLeft and myTop and cLeft and cTop) then return end

        local myWidth = self:GetWidth()
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", container, "TOPLEFT", myLeft - cLeft, math.min(0, myTop - cTop))
        self:SetPoint("BOTTOM",  container, "BOTTOM",  0, 0)
        self:SetWidth(myWidth)
    end

    canvas:SetScript("OnShow", function(self)
        ClampCanvasHeight(self)
        BBG.UpdateScrollHeight(panel)
    end)

    canvas:SetScript("OnUpdate", function(self, elapsed)
        self._sinceUpdate = (self._sinceUpdate or 0) + elapsed
        if self._sinceUpdate < 0.2 then return end
        self._sinceUpdate = 0
        ClampCanvasHeight(self)
        BBG.UpdateScrollHeight(panel)
    end)

    panel._uniqueName = uniqueName
    panel._canvas     = canvas
    panel._scroll     = scroll
    panel._scrollBar  = bar
    panel._refreshers = {}
    panel._sections   = {}
    for _, cat in ipairs(WIDGET_CATS) do
        local cf = CreateFrame("Frame", uniqueName .. "_" .. cat, panel)
        cf:Show()
        panel[cat] = cf
    end

    InitCursor(panel, -PAD_TOP - CONTENT_INSET_Y, PAD_X + CONTENT_INSET_X)
    return panel, canvas
end

function BBG.CreatePanel(uniqueName, title, width, height)
    local panel, canvas = BuildScrollPanel(uniqueName, width or 620, height or 580)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(canvas, title or uniqueName)
        Settings.RegisterAddOnCategory(category)
        panel._category   = category
        panel._categoryID = category:GetID()
    end

    return panel
end

function BBG.OpenPanel(panel)
    if panel._categoryID and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(panel._categoryID)
    end
end

function BBG.CreateSubPanel(parentCategory, uniqueName, title, width, height)
    local panel, canvas = BuildScrollPanel(uniqueName, width or 620, height or 580)

    if Settings and Settings.RegisterCanvasLayoutSubcategory and parentCategory then
        local category = Settings.RegisterCanvasLayoutSubcategory(parentCategory, canvas, title or uniqueName)
        Settings.RegisterAddOnCategory(category)
        panel._category   = category
        panel._categoryID = category:GetID()
    end

    return panel
end

function BBG.MakeTitle(text, parent, icon)
    local yTop       = CursorY(parent) - TITLE_SPACING

    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLargeOutline")
    fs:SetText(text)
    fs:SetJustifyH("LEFT")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", parent._padX + 10, yTop)

    local backplate = parent:CreateTexture(nil, "BACKGROUND", nil, 1)
    backplate:SetAtlas("ui-damagemeters-header-bar", false)
    backplate:SetSize(678, 25)
    backplate:SetPoint("LEFT", fs, "LEFT", -26, 0)

    if icon then
        local iconTex = parent:CreateTexture(nil, "ARTWORK")
        iconTex:SetSize(icon.sizeX or 20, icon.sizeY or 20)
        iconTex:SetPoint("RIGHT", fs, "LEFT", icon.offsetX or 0, icon.offsetY or 0)
        if icon.atlas then
            iconTex:SetAtlas(icon.atlas, false)
        elseif icon.texture then
            iconTex:SetTexture(icon.texture)
        end
    end

    Advance(parent, TITLE_HEIGHT + 8)
    parent._justHadTitle = true
    registerWidget(parent, "titles", nextIncKey(parent, "titles", "title"), fs)
    return fs
end

function BBG.MakeDivider(parent)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetHeight(1)
    t:SetColorTexture(0.3, 0.3, 0.3, 0.7)
    t:SetPoint("TOPLEFT",  parent, "TOPLEFT",  parent._padX,              CursorY(parent) - 4)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -(parent._padX) - 12,           CursorY(parent) - 4)
    Advance(parent, 1 + 8)
    registerWidget(parent, "dividers", nextIncKey(parent, "dividers", "divider"), t)
    return t
end

function BBG.MakeGroup(name, parent, width)
    width = width or (parent:GetWidth() - parent._padX * 2)

    local g = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    g:SetWidth(width)
    g:SetPoint("TOPLEFT", parent, "TOPLEFT", parent._padX, CursorY(parent))

    g:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    g:SetBackdropColor(0.04, 0.04, 0.04, 0.65)
    g:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.9)

    local innerStartY = -GROUP_PAD
    if name and name ~= "" then
        local header = g:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        header:SetText(name)
        header:SetJustifyH("LEFT")
        header:SetPoint("TOPLEFT", g, "TOPLEFT", GROUP_PAD, -GROUP_PAD)
        innerStartY = innerStartY - TITLE_HEIGHT - 4
    end

    InitCursor(g, innerStartY, GROUP_PAD)
    g:SetHeight(32)
    g._panel = parent
    return g
end

function BBG.FinaliseGroup(group, parent)
    local innerH = math.abs(group._cursorY) + GROUP_PAD
    group:SetHeight(innerH)
    if parent then
        Advance(parent, innerH)
    end
end

function BBG.MakeCheckbox(config, parent)
    local parentCb = config.subsettingOf

    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")

    local afterTitleGap = (not parentCb and parent._justHadTitle) and CB_AFTER_TITLE or 0

    if parentCb then
        cb:SetSize(CB_SUB_HEIGHT, CB_SUB_HEIGHT)
        cb:SetPoint("LEFT", parentCb.text, "RIGHT", 8, 0)
    else
        cb:SetSize(CB_HEIGHT, CB_HEIGHT)
        cb:SetPoint("TOPLEFT", parent, "TOPLEFT", parent._padX + CB_XPOS, CursorY(parent) - afterTitleGap)
    end

    local checkTexture = cb:CreateTexture(nil, "OVERLAY")
    checkTexture:SetAtlas("common-icon-checkmark-yellow")
    checkTexture:SetPoint("CENTER", cb, "CENTER", 0, 0)
    checkTexture:SetSize(17, 17)
    cb.Check = checkTexture

    cb:SetNormalTexture("common-button-square-gray-up")
    cb:SetHighlightTexture("common-button-square-gray-up")
    cb:SetPushedTexture("common-button-square-gray-up")
    cb:SetDisabledTexture("common-button-square-gray-up")
    cb:SetCheckedTexture(checkTexture)

    cb:SetChecked(config.get())
    cb.text:SetText(config.label)
    cb.text:SetFontObject(FONT_OBJ)
    cb.text:SetPoint("LEFT", cb, "RIGHT", 0, 0)

    if config.desc then
        cb.tooltipText = config.desc
        cb:SetHitRectInsets(0, -math.ceil(cb.text:GetStringWidth()), 0, 0)
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(config.label, 1, 0.82, 0, 1, true)
            GameTooltip:AddLine(self.tooltipText, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    local function SetSubEnabled(enabled)
        if enabled then
            cb:SetAlpha(1.0)
            cb.text:SetTextColor(1, 1, 1)
        else
            cb:SetAlpha(0.6)
            cb.text:SetTextColor(0.5, 0.5, 0.5)
        end
    end

    if parentCb then
        SetSubEnabled(parentCb:GetChecked())
        parentCb:HookScript("OnClick", function(self)
            SetSubEnabled(self:GetChecked())
        end)
    end

    cb:SetScript("OnClick", function(self)
        if parentCb and not parentCb:GetChecked() then
            self:SetChecked(config.get())
            return
        end
        config.set(self:GetChecked() == true)
    end)

    if not parentCb then
        Advance(parent, CB_HEIGHT + afterTitleGap, WidgetSpacing(config, CB_GAP))
    end

    addRefresher(parent, function()
        cb:SetChecked(config.get())
        if parentCb then SetSubEnabled(parentCb:GetChecked()) end
    end)

    registerWidget(parent, "checkboxes", labelToKey(config.label), cb)
    return cb
end

function BBG.MakeDropdown(config, parent)
    local padX     = parent._padX
    local parentCb = config.subsettingOf
    local options  = config.options

    local labelFS, dropdown
    local SetDropEnabled = function() end

    if parentCb then
        dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
        dropdown:SetWidth(config.width or 200)
        dropdown:SetPoint("LEFT", parentCb.text, "RIGHT", 16, 0)
        dropdown:SetScale(config.dropdownScale or 0.75)

        SetDropEnabled = function(enabled)
            if enabled then
                dropdown:SetAlpha(1.0)
                dropdown:Enable()
            else
                dropdown:SetAlpha(0.5)
                dropdown:Disable()
            end
        end
        SetDropEnabled(parentCb:GetChecked())
        parentCb:HookScript("OnClick", function(self)
            SetDropEnabled(self:GetChecked())
        end)
    else
        local rowWidth = config.width or (parent:GetWidth() - padX * 2)
        local labelW   = config.labelWidth or ROW_LABEL_W

        local row = CreateFrame("Frame", nil, parent)
        row:SetSize(rowWidth, SLIDER_ROW_H)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", padX - 2, CursorY(parent) - 6)

        labelFS = row:CreateFontString(nil, "ARTWORK", FONT_OBJ)
        labelFS:SetText(config.label)
        labelFS:SetJustifyH("LEFT")
        labelFS:SetWidth(labelW)
        labelFS:SetHeight(SLIDER_ROW_H)
        labelFS:SetPoint("LEFT", row, "LEFT", 0, 0)

        dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
        dropdown:SetPoint("LEFT",  labelFS, "RIGHT", 34, 0)
        dropdown:SetPoint("RIGHT", row,     "RIGHT", 0, 0)
        dropdown:SetScale(0.92)

        Advance(parent, SLIDER_ROW_H)
    end

    dropdown:SetupMenu(function(owner, rootDescription)
        for _, opt in ipairs(options) do
            rootDescription:CreateRadio(
                opt.label,
                function(v) return config.get() == v end,
                function(v)
                    config.set(v)
                    dropdown:GenerateMenu()
                end,
                opt.value
            )
        end
    end)

    addRefresher(parent, function()
        dropdown:GenerateMenu()
        if parentCb then SetDropEnabled(parentCb:GetChecked()) end
    end)

    local regLabel = config.label or (parentCb and parentCb.text:GetText()) or "dropdown"
    registerWidget(parent, "dropdowns", labelToKey(regLabel), dropdown)
    return dropdown, labelFS
end

function BBG.MakeLargeCheckDropdown(config, parent)
    local padX     = parent._padX
    local rowWidth = config.width or (parent:GetWidth() - padX * 2)
    local labelW   = config.labelWidth or ROW_LABEL_W
    local options  = config.options
    local textNone = config.textNone or "None"
    local textAll  = config.textAll  or "All"

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(rowWidth, SLIDER_ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", padX - 2, CursorY(parent) - 6)

    local labelFS = row:CreateFontString(nil, "ARTWORK", FONT_OBJ)
    labelFS:SetText(config.label)
    labelFS:SetJustifyH("LEFT")
    labelFS:SetWidth(labelW)
    labelFS:SetHeight(SLIDER_ROW_H)
    labelFS:SetPoint("LEFT", row, "LEFT", 0, 0)

    local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("LEFT",  labelFS, "RIGHT", 34, 0)
    dropdown:SetPoint("RIGHT", row,     "RIGHT", 0, 0)
    dropdown:SetScale(0.92)

    dropdown:SetDefaultText(textNone)
    dropdown:SetSelectionText(function(_)
        local labels = {}
        for _, opt in ipairs(options) do
            if opt.get() then labels[#labels + 1] = opt.label end
        end
        local n = #labels
        if n == 0 then return textNone end
        if n == 1 then return labels[1] end
        local last = table.remove(labels)
        return table.concat(labels, ", ") .. " & " .. last
    end)
    dropdown:SetupMenu(function(owner, rootDescription)
        for _, opt in ipairs(options) do
            local o = opt
            rootDescription:CreateCheckbox(
                o.label,
                function() return o.get() end,
                function() o.set(not o.get()) end
            )
        end
    end)

    Advance(parent, SLIDER_ROW_H)
    addRefresher(parent, function() dropdown:GenerateMenu() end)
    registerWidget(parent, "dropdowns", labelToKey(config.label), dropdown)
    return dropdown, labelFS
end

function BBG.MakeSmallCheckDropdown(config, parent)
    local padX     = parent._padX
    local width    = config.width    or 200
    local options  = config.options
    local textNone = config.textNone or "None"
    local textAll  = config.textAll  or "All"
    local parentCb = config.subsettingOf

    local labelFS
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(width)

    local function SetDropEnabled(enabled)
        if enabled then
            dropdown:SetAlpha(1.0)
            dropdown:Enable()
        else
            dropdown:SetAlpha(0.6)
            dropdown:Disable()
        end
    end

    if parentCb then
        dropdown:SetPoint("LEFT", parentCb.text, "RIGHT", 16, 0)
        dropdown:SetScale(0.75)

        SetDropEnabled(parentCb:GetChecked())
        parentCb:HookScript("OnClick", function(self)
            SetDropEnabled(self:GetChecked())
        end)
    else
        local dropY = CursorY(parent)
        if config.label then
            labelFS = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            labelFS:SetText(config.label)
            labelFS:SetJustifyH("LEFT")
            labelFS:SetHeight(DD_LABEL_H)
            labelFS:SetPoint("TOPLEFT", parent, "TOPLEFT", padX, dropY)
            dropY = dropY - DD_LABEL_H - 2
        end
        dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", padX, dropY)
    end

    local menuScale = parentCb and 0.7 or config.menuScale
    local function BuildMenuItems(rootDescription)
        local menuScaled = false
        for _, opt in ipairs(options) do
            local o = opt
            local cbDesc = rootDescription:CreateCheckbox(
                o.label,
                function() return o.get() end,
                function() o.set(not o.get()) end
            )
            if menuScale and not menuScaled then
                cbDesc:AddInitializer(function(button, description, menu)
                    menu:SetScale(menuScale)
                end)
                menuScaled = true
            end
            local isWarn = o.warnGet and o.warnGet()
            if isWarn then
                cbDesc:AddInitializer(function(button)
                    button.fontString:SetTextColor(1, 0.2, 0.2)
                end)
            end
            if (isWarn and o.warnText) or o.desc then
                cbDesc:SetTooltip(function(tooltip)
                    tooltip:SetText(o.label, 1, 0.82, 0, 1, true)
                    if isWarn and o.warnText then
                        GameTooltip_AddErrorLine(tooltip, o.warnText)
                    end
                    if o.desc then
                        tooltip:AddLine(o.desc, 1, 1, 1, true)
                    end
                end)
            end
        end
    end

    if config.buttonText then
        dropdown:SetupMenu(function(owner, rootDescription)
            BuildMenuItems(rootDescription)
        end)
        dropdown:OverrideText(config.buttonText)
    else
        dropdown:SetDefaultText(textNone)
        dropdown:SetSelectionText(function(selections)
            local n = #selections
            if n == 0        then return textNone end
            if n == #options then return textAll  end
            return n .. " / " .. #options
        end)
        dropdown:SetupMenu(function(owner, rootDescription)
            BuildMenuItems(rootDescription)
        end)
    end

    if not parentCb then
        local totalH = (config.label and (DD_LABEL_H + 2) or 0) + DD_BTN_H
        Advance(parent, totalH)
    end

    addRefresher(parent, function()
        dropdown:GenerateMenu()
        if parentCb then SetDropEnabled(parentCb:GetChecked()) end
    end)

    local regKey = labelToKey(config.buttonText or config.label or "multiDropdown")
    registerWidget(parent, "dropdowns", regKey, dropdown)
    return dropdown, labelFS
end

function BBG.MakeSpecGridDropdown(config, parent)
    local padX    = parent._padX
    local classes = config.classes

    local specTotal = 0
    local widestClass = 1
    for _, class in ipairs(classes) do
        if not class.hideSpecs then
            specTotal = specTotal + #class.specs
            if #class.specs > widestClass then widestClass = #class.specs end
        end
    end
    local columns = widestClass + 1

    local rowWidth = config.width or (parent:GetWidth() - padX * 2)
    local labelW   = config.labelWidth or ROW_LABEL_W

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(rowWidth, SLIDER_ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", padX - 2, CursorY(parent) - 6)

    local labelFS = row:CreateFontString(nil, "ARTWORK", FONT_OBJ)
    labelFS:SetText(config.label or "")
    labelFS:SetJustifyH("LEFT")
    labelFS:SetWidth(labelW)
    labelFS:SetHeight(SLIDER_ROW_H)
    labelFS:SetPoint("LEFT", row, "LEFT", 0, 0)

    local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("LEFT",  labelFS, "RIGHT", 34, 0)
    dropdown:SetPoint("RIGHT", row,     "RIGHT", 0, 0)
    dropdown:SetScale(0.92)

    dropdown:SetDefaultText(config.textNone or "None")
    dropdown:SetSelectionText(function(selections)
        local n = #selections
        if n == 0 then return config.textNone or "None" end
        return n .. " / " .. specTotal
    end)

    dropdown:SetupMenu(function(owner, rootDescription)
        rootDescription:SetGridMode(MenuConstants.HorizontalGridDirection, columns, 0)

        local playerSpecID = config.playerSpecID
        if type(playerSpecID) == "function" then playerSpecID = playerSpecID() end

        local selectedProfile = config.selectedProfile
        if type(selectedProfile) == "function" then selectedProfile = selectedProfile() end

        for _, class in ipairs(classes) do
            local localClass = class

            local function SelectedCount()
                local n = 0
                for _, spec in ipairs(localClass.specs) do
                    if config.getSpec(spec.id) then n = n + 1 end
                end
                return n
            end

            local function IsChecked()
                if localClass.hideSpecs then
                    return #localClass.specs > 0 and SelectedCount() == #localClass.specs
                end
                return SelectedCount() > 0
            end

            local classCb = rootDescription:CreateCheckbox(localClass.name, IsChecked, function()
                local turnOn = not IsChecked()
                if config.setSpecs then
                    local ids = {}
                    for i, spec in ipairs(localClass.specs) do ids[i] = spec.id end
                    config.setSpecs(ids, turnOn)
                else
                    for _, spec in ipairs(localClass.specs) do
                        config.setSpec(spec.id, turnOn)
                    end
                end
            end)

            classCb:SetSelectionIgnored()

            classCb:AddInitializer(function(button)
                button.fontString:SetTextColor(localClass.color:GetRGB())
            end)
            classCb:SetTooltip(function(tooltip)
                GameTooltip_AddNormalLine(tooltip,
                    string.format("%d of %d %s specs use this profile.",
                        SelectedCount(), #localClass.specs, localClass.name))
                GameTooltip_AddInstructionLine(tooltip, localClass.hideSpecs
                    and ("Click to toggle every " .. localClass.name .. " spec.")
                    or "Click to toggle the whole class.")
            end)

            for i = 1, columns - 1 do
                local spec = (not localClass.hideSpecs) and localClass.specs[i]
                if spec then
                    local localSpec = spec
                    local isPlayerSpec = (playerSpecID == localSpec.id)

                    local ownedBy = config.getSpecOwner and config.getSpecOwner(localSpec.id)

                    local specLabel = localSpec.name
                        .. (isPlayerSpec and " *" or "")
                        .. (ownedBy and " |cff00c0ff*|r" or "")

                    local specCb = rootDescription:CreateCheckbox(specLabel,
                        function() return config.getSpec(localSpec.id) end,
                        function() config.setSpec(localSpec.id, not config.getSpec(localSpec.id)) end)

                    if isPlayerSpec then
                        specCb:AddInitializer(function(button)
                            button.fontString:SetTextColor(1, 0.82, 0)
                        end)
                    end

                    if ownedBy or isPlayerSpec then
                        specCb:SetTooltip(function(tooltip)
                            if isPlayerSpec then
                                GameTooltip_AddColoredLine(tooltip, "This is your current specialization.", NORMAL_FONT_COLOR)
                            end
                            if ownedBy then
                                GameTooltip_AddNormalLine(tooltip, string.format(
                                    "This spec is using \"|cff00c0ff%s|r\" profile. Click to instead make it use \"|cff00c0ff%s|r\".",
                                    ownedBy, selectedProfile or "?"))
                            end
                        end)
                    end
                else
                    rootDescription:CreateSpacer()
                end
            end
        end
    end)

    Advance(parent, SLIDER_ROW_H)
    addRefresher(parent, function() dropdown:GenerateMenu() end)
    registerWidget(parent, "dropdowns", labelToKey(config.label or "specGrid"), dropdown)
    return dropdown, labelFS
end

function BBG.MakeFontDropdown(config, parent)
    local padX     = parent._padX
    local rowWidth = config.width or (parent:GetWidth() - padX * 2)
    local labelW   = config.labelWidth or ROW_LABEL_W
    local items    = config.items

    local previewFontObjects = {}
    for _, item in ipairs(items) do
        if item.previewFont then
            local fontObj = CreateFont("BetterBlizzMarkersFontPreview" .. tostring(item.value))
            fontObj:SetFont(item.previewFont, config.previewSize or 14, "")
            previewFontObjects[item] = fontObj
        end
    end

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(rowWidth, SLIDER_ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", padX - 2, CursorY(parent) - 6)

    local labelFS = row:CreateFontString(nil, "ARTWORK", FONT_OBJ)
    labelFS:SetText(config.label or "")
    labelFS:SetJustifyH("LEFT")
    labelFS:SetWidth(labelW)
    labelFS:SetHeight(SLIDER_ROW_H)
    labelFS:SetPoint("LEFT", row, "LEFT", 0, 0)

    local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("LEFT",  labelFS, "RIGHT", 34, 0)
    dropdown:SetPoint("RIGHT", row,     "RIGHT", 0, 0)
    dropdown:SetScale(0.92)

    dropdown:SetupMenu(function(owner, rootDescription)
        rootDescription:SetGridMode(MenuConstants.VerticalGridDirection, MenuConstants.AutoCalculateColumns, 0, 100)

        for _, item in ipairs(items) do
            local localItem = item
            local radio = rootDescription:CreateRadio(
                item.label,
                function(v) return config.get() == v end,
                function(v)
                    config.set(v)
                    dropdown:GenerateMenu()
                end,
                item.value
            )

            local fontObj = previewFontObjects[localItem]
            if fontObj then
                radio:AddInitializer(function(button)
                    button.fontString:SetFontObject(fontObj)
                end)
            end
        end
    end)

    Advance(parent, SLIDER_ROW_H)
    addRefresher(parent, function() dropdown:GenerateMenu() end)
    registerWidget(parent, "dropdowns", labelToKey(config.label or "fontDropdown"), dropdown)
    return dropdown, labelFS
end

function BBG.AlignSubsettings(items)
    if not items or #items == 0 then return end

    local maxTextW = 0
    for _, item in ipairs(items) do
        local cb = item[1]
        if cb and cb.text then
            local w = cb.text:GetStringWidth()
            if w > maxTextW then maxTextW = w end
        end
    end

    local dropX = CB_HEIGHT + 2 + maxTextW + 8

    for _, item in ipairs(items) do
        local cb, dd = item[1], item[2]
        if cb and dd and dd.ClearAllPoints then
            dd:ClearAllPoints()
            dd:SetPoint("LEFT", cb, "LEFT", dropX + 40, 0)
        end
    end
end

function BBG.MakeSlider(config, parent)
    local padX     = parent._padX
    local min      = config.min
    local max      = config.max
    local step     = config.step or 1
    local fmt      = config.fmt  or "%.4g"
    local rowWidth = config.width or (parent:GetWidth() - padX * 2)
    local labelW   = config.labelWidth or ROW_LABEL_W
    local editW    = 58

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(rowWidth, SLIDER_ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", padX - 2, CursorY(parent) - 6)

    local labelFS = row:CreateFontString(nil, "ARTWORK", FONT_OBJ)
    labelFS:SetText(config.label)
    labelFS:SetJustifyH("LEFT")
    labelFS:SetWidth(labelW)
    labelFS:SetHeight(SLIDER_ROW_H)
    labelFS:SetPoint("LEFT", row, "LEFT", 0, 0)

    local editBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    editBox:SetSize(editW, SLIDER_ROW_H - 6)
    editBox:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(10)
    editBox:SetText(string.format(fmt, config.get()))

    local slider
    local syncing   = false
    local refreshing = false

    if Settings and Settings.CreateSliderOptions then
        slider = CreateFrame("Frame", nil, row, "MinimalSliderWithSteppersTemplate")
        slider:SetHeight(SLIDER_ROW_H)
        slider:SetPoint("LEFT",  labelFS, "RIGHT", 28, 0)
        slider:SetPoint("RIGHT", editBox, "LEFT", -8, 0)

        local opts = Settings.CreateSliderOptions(min, max, step)
        slider:Init(config.get(), opts.minValue, opts.maxValue, opts.steps, opts.formatters)

        slider:RegisterCallback("OnValueChanged", function(_, value)
            if refreshing then return end
            local v = roundToStep(value, step)
            config.set(v)
            if not syncing then
                editBox:SetText(string.format(fmt, v))
            end
        end, slider)

    else
        slider = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
        slider:SetHeight(SLIDER_ROW_H)
        slider:SetPoint("LEFT",  labelFS, "RIGHT", 28, 0)
        slider:SetPoint("RIGHT", editBox, "LEFT", -8, 0)
        slider:SetMinMaxValues(min, max)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        slider:SetValue(config.get())
        if slider.Low  then slider.Low:SetText("")  end
        if slider.High then slider.High:SetText("") end
        if slider.Text then slider.Text:SetText("") end

        slider:SetScript("OnValueChanged", function(self, value, userInput)
            if refreshing or not userInput then return end
            config.set(value)
            if not syncing then
                editBox:SetText(string.format(fmt, value))
            end
        end)
    end

    local function CommitEditBox()
        local val = tonumber(editBox:GetText())
        if val then
            val = math.max(min, math.min(max, val))
            val = roundToStep(val, step)
            syncing = true
            slider:SetValue(val)
            syncing = false
            editBox:SetText(string.format(fmt, val))
        else
            editBox:SetText(string.format(fmt, config.get()))
        end
        editBox:ClearFocus()
    end

    editBox:SetScript("OnEnterPressed", CommitEditBox)
    editBox:SetScript("OnEditFocusLost", CommitEditBox)
    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(string.format(fmt, config.get()))
        self:ClearFocus()
    end)

    Advance(parent, SLIDER_ROW_H)

    addRefresher(parent, function()
        local v = config.get()
        refreshing = true
        slider:SetValue(v)
        refreshing = false
        editBox:SetText(string.format(fmt, v))
    end)

    registerWidget(parent, "sliders", labelToKey(config.label), row)
    return row, slider, labelFS, editBox
end

function BBG.MakeButton(config, parent)
    local btn = CreateFrame("Button", nil, parent, "SharedButtonTemplate")
    btn:SetSize(config.width or 140, BTN_HEIGHT)
    local labelText = type(config.label) == "function" and config.label() or config.label
    btn:SetText(labelText)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", parent._padX, CursorY(parent))
    btn:SetScript("OnClick", function(self)
        config.func()
        if type(config.label) == "function" then
            self:SetText(config.label())
        end
    end)
    Advance(parent, BTN_HEIGHT)

    if type(config.label) == "function" then
        addRefresher(parent, function() btn:SetText(config.label()) end)
    end

    local btnLabel = type(config.label) == "function" and "button" or config.label
    registerWidget(parent, "buttons", labelToKey(btnLabel), btn)
    return btn
end

function BBG.MakeButtonRow(configs, parent, opts)
    local gap  = 6
    local yPos = CursorY(parent)  + (opts and opts.yOffset or 0)
    local xPos = parent._padX     + (opts and opts.xOffset or 0)
    local btns = {}

    for i, config in ipairs(configs) do
        local btn = CreateFrame("Button", nil, parent, "SharedButtonTemplate")
        btn:SetSize(config.width or 90, BTN_HEIGHT)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xPos, yPos)

        local labelText = type(config.label) == "function" and config.label() or config.label
        btn:SetText(labelText)
        btn:SetScript("OnClick", function(self)
            config.func()
            if type(config.label) == "function" then
                self:SetText(config.label())
            end
        end)

        if config.desc then
            btn:SetScript("OnEnter", function()
                local text = type(config.desc) == "function" and config.desc() or config.desc
                if not text then return end
                GameTooltip:SetOwner(btn, "ANCHOR_TOP")
                GameTooltip:SetText(text, 1, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end

        if config.enabled then
            addRefresher(parent, function() btn:SetEnabled(config.enabled()) end)
            btn:SetEnabled(config.enabled())
        end
        if type(config.label) == "function" then
            addRefresher(parent, function() btn:SetText(config.label()) end)
        end

        xPos = xPos + btn:GetWidth() + gap
        btns[i] = btn
        registerWidget(parent, "buttons", labelToKey(labelText or ("button" .. i)), btn)
    end

    Advance(parent, BTN_HEIGHT)
    return btns
end

function BBG.MakeTextArea(config, parent)
    local padX   = parent._padX
    local width  = config.width  or (parent:GetWidth() - padX * 2 - 10)
    local height = config.height or 60

    local afterTitleGap = parent._justHadTitle and CB_AFTER_TITLE or 0
    local extraBoxGap   = afterTitleGap > 0 and 4 or 0

    local baseY    = CursorY(parent)
    local labelGap = afterTitleGap + (config.labelGap or 0)
    local boxGap   = afterTitleGap + extraBoxGap + (config.boxGap or 0)
    local labelY   = baseY - labelGap

    local labelFS

    if config.label then
        labelFS = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        labelFS:SetText(config.label)
        labelFS:SetJustifyH("LEFT")
        labelFS:SetHeight(DD_LABEL_H)
        labelFS:SetPoint("TOPLEFT", parent, "TOPLEFT", padX, labelY)
    end

    local headerH = (config.label or config.buttonLabel) and (DD_LABEL_H + 4) or 0

    local scroll = CreateFrame("ScrollFrame", nil, parent, "InputScrollFrameTemplate")
    scroll:SetSize(width, height)
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", padX, baseY - boxGap - headerH)
    if scroll.CharCount then scroll.CharCount:Hide() end

    scroll.MiddleTex:SetVertexColor(0.05, 0.05, 0.05)
    for _, tex in ipairs({
        scroll.TopLeftTex, scroll.TopRightTex, scroll.TopTex,
        scroll.BottomLeftTex, scroll.BottomRightTex, scroll.BottomTex,
        scroll.LeftTex, scroll.RightTex,
    }) do
        tex:SetVertexColor(0.32, 0.32, 0.32)
    end

    local editBox = scroll.EditBox
    editBox:SetWidth(width - 18)
    editBox:SetFontObject(FONT_OBJ)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(0)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local actionBtn
    local buttonBelowGap = config.buttonGap or 6
    local buttonH = 0
    if config.buttonLabel then
        actionBtn = CreateFrame("Button", nil, parent, "SharedButtonTemplate")
        actionBtn:SetSize(config.buttonWidth or 90, BTN_HEIGHT - 2)
        actionBtn:SetPoint("TOPLEFT", scroll, "BOTTOMLEFT", 0, -buttonBelowGap)
        actionBtn:SetText(config.buttonLabel)
        buttonH = buttonBelowGap + (BTN_HEIGHT - 2)
    end

    local handle = { editBox = editBox, container = scroll, button = actionBtn }

    function handle:SetText(text)
        editBox:SetText(text or "")
    end

    function handle:GetText()
        return editBox:GetText()
    end

    function handle:Clear()
        editBox:SetText("")
    end

    function handle:SelectAll()
        editBox:SetFocus()
        editBox:HighlightText()
    end

    if config.readOnly then
        local settingText = false
        local shown = ""
        function handle:SetText(text)
            shown = text or ""
            settingText = true
            editBox:SetText(shown)
            settingText = false
        end
        function handle:Clear() handle:SetText("") end

        editBox:HookScript("OnTextChanged", function(self)
            if settingText then return end
            if self:GetText() ~= shown then
                settingText = true
                self:SetText(shown)
                settingText = false
            end
            self:HighlightText()
        end)
        editBox:HookScript("OnEditFocusGained", function(self) self:HighlightText() end)
        editBox:HookScript("OnMouseUp", function(self) self:HighlightText() end)
        editBox:HookScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
    end

    if actionBtn and config.buttonFunc then
        actionBtn:SetScript("OnClick", function() config.buttonFunc(handle) end)
    end

    Advance(parent, headerH + height + buttonH + math.max(labelGap, boxGap))
    return handle
end

function BBG.MakeLabel(text, parent, fontObj, xOffset, yOffset, maxWidth)
    xOffset, yOffset = xOffset or 0, yOffset or 0
    local fs = parent:CreateFontString(nil, "ARTWORK", fontObj or FONT_OBJ)
    fs:SetPoint("TOPLEFT",  parent, "TOPLEFT",  parent._padX + xOffset, CursorY(parent) + yOffset)
    if maxWidth then
        fs:SetWidth(maxWidth)
    else
        fs:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -parent._padX, CursorY(parent) + yOffset)
    end
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(true)
    fs:SetText(text)
    local h = math.max(fs:GetStringHeight(), 14)
    Advance(parent, h)
    registerWidget(parent, "labels", nextIncKey(parent, "labels", "label"), fs)
    return fs
end

function BBG.MakeCategoryTile(config, parent)
    local width    = config.width  or 270
    local height   = config.height or 90
    local iconSize = config.iconSize or 64

    local tile = CreateFrame("Button", nil, parent)
    tile:SetSize(width, height)
    tile:SetPoint("TOPLEFT", parent, "TOPLEFT", config.x, config.y)
    NoteContentBottom(parent, math.abs(config.y or 0) + height)

    local bg = tile:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(tile)
    bg:SetAtlas("evergreen-scenario-widget-frame-2x", false)
    bg:SetVertexColor(0.85, 0.85, 0.85)

    tile:SetScript("OnEnter", function() bg:SetVertexColor(1, 1, 1) end)
    tile:SetScript("OnLeave", function() bg:SetVertexColor(0.85, 0.85, 0.85) end)

    local iconAnchor = CreateFrame("Frame", nil, tile)
    iconAnchor:SetSize(iconSize, iconSize)
    iconAnchor:SetPoint("RIGHT", tile, "RIGHT", -24 + (config.iconOffsetX or 0), config.iconOffsetY or 0)

    local iconHolder = CreateFrame("Frame", nil, iconAnchor)
    iconHolder:SetSize(iconSize, iconSize)
    iconHolder:SetPoint("CENTER", iconAnchor, "CENTER")
    if config.iconScale then
        iconHolder:SetScale(config.iconScale)
    end

    if config.buildIcon then
        config.buildIcon(iconHolder, iconSize)
    elseif config.icon then
        local tex = iconHolder:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        if config.icon.atlas then
            tex:SetAtlas(config.icon.atlas, false)
        elseif config.icon.texture then
            tex:SetTexture(config.icon.texture)
        end
    end

    local label = tile:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    label:SetText(config.title)
    label:SetPoint("LEFT", tile, "LEFT", 23, -11)
    local a,b,c = label:GetFont()
    label:SetFont(a,18,"OUTLINE")

    if config.onClick then
        tile:SetScript("OnClick", config.onClick)
    end

    registerWidget(parent, "buttons", labelToKey(config.title), tile)
    return tile
end

function BBG.MakePanelHeader(config, panel)
    local canvas   = panel._canvas or panel
    local iconSize = config.iconSize or 40

    local header = CreateFrame("Frame", nil, canvas)
    header:SetSize(canvas:GetWidth(), config.height or 34)
    header:SetPoint("TOPLEFT", canvas, "TOPLEFT", config.x or 0, config.y or 39)

    local label = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    label:SetText(config.title)
    label:SetPoint("LEFT", header, "LEFT", 0, 0)
    local fontPath = label:GetFont()
    label:SetFont(fontPath, config.fontSize or 18, "OUTLINE")

    local iconAnchor = CreateFrame("Frame", nil, header)
    iconAnchor:SetSize(iconSize, iconSize)
    iconAnchor:SetPoint("LEFT", label, "RIGHT", (config.iconGap or 8) + (config.iconOffsetX or 0), config.iconOffsetY or 0)

    local iconHolder = CreateFrame("Frame", nil, iconAnchor)
    iconHolder:SetSize(iconSize, iconSize)
    iconHolder:SetPoint("CENTER", iconAnchor, "CENTER")
    if config.iconScale then
        iconHolder:SetScale(config.iconScale)
    end

    if config.buildIcon then
        config.buildIcon(iconHolder, iconSize)
    elseif config.icon then
        local tex = iconHolder:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        if config.icon.atlas then
            tex:SetAtlas(config.icon.atlas, false)
        elseif config.icon.texture then
            tex:SetTexture(config.icon.texture)
        end
    end

    header.label      = label
    header.iconAnchor = iconAnchor
    header.iconHolder = iconHolder
    panel._header     = header
    return header
end

function BBG.MakeHeaderButton(config, panel)
    local header = panel._header
    if not header then return nil end

    local btn = CreateFrame("Button", nil, header, "SharedButtonTemplate")
    btn:SetSize(config.width or 150, config.height or 26)
    btn:SetPoint("LEFT", header, "LEFT", config.xOffset or 160, config.yOffset or 0)

    local function Apply()
        btn:SetText(type(config.label) == "function" and config.label() or config.label)
    end
    Apply()

    btn:SetScript("OnClick", function()
        config.func()
        Apply()
    end)

    if config.desc then
        btn:SetScript("OnEnter", function()
            local text = type(config.desc) == "function" and config.desc() or config.desc
            if not text then return end
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText(text, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    addRefresher(panel, Apply)

    header[config.key or "headerButton"] = btn
    return btn
end

function BBG.MakeColorRow(config, parent)
    local items       = config.items
    local anchorLeft  = config.anchorLeft
    local anchorBelow = config.anchorBelow
    local offsetY     = config.offsetY or 0
    local rowGap      = config.rowGap or 2
    local padX        = parent._padX + (config.indent or 30)
    local ROW_H      = 16
    local SW         = 13
    local SL_GAP     = 5
    local IT_GAP     = 14
    local SLOT_W     = SW + SL_GAP + 72 + IT_GAP

    local startY   = CursorY(parent)
    local swatches = {}
    local fills    = {}
    local labels   = {}

    for i, item in ipairs(items) do
        local localItem = item

        local swatch = CreateFrame("Button", nil, parent)
        swatch:SetSize(SW, SW)

        if anchorBelow and i == 1 then
            swatch:SetPoint("TOPLEFT", anchorBelow, "BOTTOMLEFT", 0, -rowGap + offsetY)
        elseif anchorLeft or anchorBelow then
            local anchor = (i == 1) and anchorLeft or labels[i - 1]
            local gap    = (i == 1) and 10 or IT_GAP
            swatch:SetPoint("LEFT", anchor, "RIGHT", gap, (i == 1) and offsetY or 0)
        else
            local x = padX + (i - 1) * SLOT_W
            swatch:SetPoint("TOPLEFT", parent, "TOPLEFT", x, startY - 2 + offsetY)
        end

        local borderTex = swatch:CreateTexture(nil, "BACKGROUND")
        borderTex:SetAllPoints(swatch)
        borderTex:SetColorTexture(0, 0, 0, 1)

        local fillTex = swatch:CreateTexture(nil, "ARTWORK")
        fillTex:SetPoint("TOPLEFT",     swatch, "TOPLEFT",     1, -1)
        fillTex:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", -1, 1)
        fills[i] = fillTex

        local highlightTex = swatch:CreateTexture(nil, "HIGHLIGHT")
        highlightTex:SetAllPoints(swatch)
        highlightTex:SetColorTexture(1, 1, 1, 0.3)

        local labelFS = parent:CreateFontString(nil, "ARTWORK", FONT_OBJ)
        labelFS:SetText(item.label)
        labelFS:SetPoint("LEFT", swatch, "RIGHT", SL_GAP, 0)
        labelFS:SetHeight(ROW_H)
        labels[i] = labelFS

        local function Refresh()
            local c = localItem.getColor()
            local r, g, b = c.r or c[1], c.g or c[2], c.b or c[3]
            fillTex:SetColorTexture(r, g, b)
            labelFS:SetTextColor(r, g, b)
        end
        Refresh()
        addRefresher(parent, Refresh)

        swatch:SetScript("OnClick", function()
            local c = localItem.getColor()
            local r, g, b = c.r or c[1], c.g or c[2], c.b or c[3]
            ColorPickerFrame:SetupColorPickerAndShow({
                r = r, g = g, b = b,
                swatchFunc = function()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    localItem.setColor(nr, ng, nb)
                    Refresh()
                end,
                cancelFunc = function(prev)
                    localItem.setColor(prev.r, prev.g, prev.b)
                    Refresh()
                end,
                hasOpacity = false,
            })
        end)

        swatch:SetScript("OnEnter", function()
            GameTooltip:SetOwner(swatch, "ANCHOR_TOP")
            GameTooltip:SetText(localItem.label)
            GameTooltip:AddLine("Click to change color", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        swatch:SetScript("OnLeave", function() GameTooltip:Hide() end)

        swatches[i] = swatch
    end

    local function SetEnabled(enabled)
        for i, sw in ipairs(swatches) do
            sw:SetAlpha(enabled and 1.0 or 0.5)
            if enabled then
                sw:Enable()
                local c = items[i].getColor()
                local r, g, b = c.r or c[1], c.g or c[2], c.b or c[3]
                fills[i]:SetColorTexture(r, g, b)
                labels[i]:SetTextColor(r, g, b)
            else
                sw:Disable()
                fills[i]:SetColorTexture(0.5, 0.5, 0.5)
                labels[i]:SetTextColor(0.5, 0.5, 0.5)
            end
        end
    end

    if not anchorLeft and not anchorBelow then
        Advance(parent, ROW_H + 4)
    end

    return swatches, SetEnabled
end
