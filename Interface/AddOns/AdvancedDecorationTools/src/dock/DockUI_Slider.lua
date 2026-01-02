-- DockUI_Slider.lua


local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local Def = ADT.DockUI.Def

local function ClampValue(value, minValue, maxValue)
    if value == nil then return minValue end
    if minValue ~= nil and value < minValue then return minValue end
    if maxValue ~= nil and value > maxValue then return maxValue end
    return value
end

local function RoundToStep(value, step, minValue)
    if not step or step <= 0 then return value end
    local base = minValue or 0
    return math.floor(((value - base) / step) + 0.5) * step + base
end

local ValueFormatter = {
    NoChange = function(value) return value end,
    Decimal0 = function(value) return string.format("%.0f", value) end,
    Decimal1 = function(value) return string.format("%.1f", value) end,
    Decimal2 = function(value) return string.format("%.2f", value) end,
    Percentage = function(value) return string.format("%.0f%%", value * 100) end,
}

local function ResolveFormatFunc(opts)
    if not opts then return ValueFormatter.NoChange end
    if type(opts.formatValueFunc) == "function" then
        return opts.formatValueFunc
    end
    if opts.formatValueMethod and ValueFormatter[opts.formatValueMethod] then
        return ValueFormatter[opts.formatValueMethod]
    end
    return ValueFormatter.NoChange
end

-- ============================================================================
-- CreateSliderRow - 通用滑块行（单一权威布局）
-- ============================================================================

function ADT.DockUI.CreateSliderRow(parent, width, label, getValue, setValue, opts)
    opts = opts or {}
    local rl = Def.RowLayout or {}
    local rowHeight = rl.RowHeight or 28
    local labelWidth = rl.SliderLabelWidth or 120
    local labelMinWidth = rl.SliderLabelMinWidth or 64
    local valueWidth = rl.SliderValueWidth or 34
    local gap = rl.SliderGap or 2
    local sliderMinWidth = rl.SliderMinWidth or 110
    local sliderTrackInset = rl.SliderTrackInset or 10
    local leftInset = rl.LabelLeftInset or 0
    local rightInset = rl.ControlRightInset or 4
    local twoLine = opts.twoLine
    if twoLine == nil then
        twoLine = rl.SliderTwoLine
    end
    local labelLineHeight = rl.SliderLabelLineHeight or 16
    local labelLineGap = rl.SliderLabelLineGap or 4
    local sliderHeight = rl.SliderControlHeight or 20
    local sliderLineRightInset = rl.SliderLineRightInset
    if sliderLineRightInset == nil then sliderLineRightInset = rightInset end
    local valueRightInset = rl.SliderValueRightInset
    if valueRightInset == nil then valueRightInset = 0 end

    if twoLine then
        rowHeight = rl.SliderRowHeight or (labelLineHeight + labelLineGap + sliderHeight)
    end

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(rowHeight)
    if width then row:SetWidth(width) end
    row._twoLine = twoLine
    row._get = getValue
    row._set = setValue
    row._min = opts.min
    row._max = opts.max
    row._step = opts.step or 1
    row._formatValueFunc = ResolveFormatFunc(opts)
    row._tooltip = opts.tooltip
    row._onSet = opts.onSet
    row._onMouseDown = opts.onMouseDown
    row._onMouseUp = opts.onMouseUp

    -- 左侧标签
    local labelFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelFS:SetJustifyH("LEFT")
    if twoLine then
        labelFS:SetPoint("TOPLEFT", row, "TOPLEFT", leftInset, 0)
        labelFS:SetPoint("TOPRIGHT", row, "TOPRIGHT", -rightInset, 0)
        labelFS:SetHeight(labelLineHeight)
        if labelFS.SetMaxLines then labelFS:SetMaxLines(1) end
        if labelFS.SetWordWrap then labelFS:SetWordWrap(false) end
    else
        labelFS:SetPoint("LEFT", row, "LEFT", leftInset, 0)
        labelFS:SetWidth(labelWidth)
    end
    labelFS:SetText(label or "")
    row.label = labelFS

    -- 第二行容器（两行布局）
    local line = nil
    if twoLine then
        line = CreateFrame("Frame", nil, row)
        line:SetPoint("TOPLEFT", row, "TOPLEFT", leftInset, -(labelLineHeight + labelLineGap))
        line:SetPoint("TOPRIGHT", row, "TOPRIGHT", -sliderLineRightInset, -(labelLineHeight + labelLineGap))
        line:SetHeight(sliderHeight)
        row._line = line
    end

    -- 右侧数值
    local valueParent = twoLine and line or row
    local valueFS = valueParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueFS:SetJustifyH("RIGHT")
    if twoLine then
        valueFS:SetPoint("RIGHT", line, "RIGHT", -valueRightInset, 0)
    else
        valueFS:SetPoint("RIGHT", row, "RIGHT", -rightInset, 0)
    end
    valueFS:SetWidth(valueWidth)
    valueFS:SetTextColor(1, 0.82, 0)
    row.valueText = valueFS

    -- 中部滑块
    local sliderParent = twoLine and line or row
    local slider = CreateFrame("Frame", nil, sliderParent, "MinimalSliderWithSteppersTemplate")
    if twoLine then
        slider:SetPoint("LEFT", line, "LEFT", 0, 0)
        slider:SetPoint("RIGHT", valueFS, "LEFT", -gap, 0)
        slider:SetHeight(sliderHeight)
    else
        slider:SetPoint("LEFT", labelFS, "RIGHT", gap, 0)
        slider:SetPoint("RIGHT", valueFS, "LEFT", -gap, 0)
        slider:SetHeight(rowHeight)
    end
    row.slider = slider

    -- 调整滑块轨道内边距，避免轨道过短
    if slider.Slider then
        slider.Slider:ClearAllPoints()
        slider.Slider:SetPoint("TOPLEFT", slider, "TOPLEFT", sliderTrackInset, 0)
        slider.Slider:SetPoint("BOTTOMRIGHT", slider, "BOTTOMRIGHT", -sliderTrackInset, 0)
    end

    -- 隐藏模板自带文案
    if slider.LeftText then slider.LeftText:Hide() end
    if slider.RightText then slider.RightText:Hide() end
    if slider.TopText then slider.TopText:Hide() end
    if slider.MinText then slider.MinText:Hide() end
    if slider.MaxText then slider.MaxText:Hide() end

    local function UpdateValueText(value)
        if value == nil then
            if row._min ~= nil then
                value = row._min
            else
                value = 0
            end
        end
        local fmt = row._formatValueFunc or ValueFormatter.NoChange
        row.valueText:SetText(fmt(value))
    end

    local function ApplyValue(value, fromUser)
        value = ClampValue(value, row._min, row._max)
        value = RoundToStep(value, row._step, row._min)
        if value == nil then
            if row._min ~= nil then
                value = row._min
            else
                value = 0
            end
        end
        UpdateValueText(value)
        if fromUser then
            if row._set then row._set(value) end
            if row._onSet then row._onSet(value) end
        end
    end

    local function OnValueChanged(_, value)
        if row._suppress then return end
        ApplyValue(value, true)
    end

    slider.Slider:SetScript("OnValueChanged", OnValueChanged)
    local minValue = row._min
    if minValue == nil then minValue = 0 end
    local maxValue = row._max
    if maxValue == nil then maxValue = 1 end
    slider.Slider:SetMinMaxValues(minValue, maxValue)
    slider.Slider:SetValueStep(row._step)
    slider.Slider:SetObeyStepOnDrag(true)

    slider.Slider:HookScript("OnMouseDown", function()
        if row._onMouseDown then row._onMouseDown(row) end
    end)
    slider.Slider:HookScript("OnMouseUp", function()
        if row._onMouseUp then row._onMouseUp(row) end
    end)

    local function ShowTooltip()
        if not row._tooltip then return end
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:SetText(row.label:GetText() or "", 1, 1, 1)
        GameTooltip:AddLine(row._tooltip, 1, 0.82, 0, true)
        GameTooltip:Show()
    end

    local function HideTooltip()
        GameTooltip:Hide()
    end

    row:SetScript("OnEnter", ShowTooltip)
    row:SetScript("OnLeave", HideTooltip)
    slider:SetScript("OnEnter", ShowTooltip)
    slider:SetScript("OnLeave", HideTooltip)

    function row:SetEnabled(enabled)
        if enabled then
            slider:SetEnabled(true)
            row.label:SetTextColor(Def.TextColorNormal[1], Def.TextColorNormal[2], Def.TextColorNormal[3])
            row.valueText:SetTextColor(1, 0.82, 0)
        else
            slider:SetEnabled(false)
            row.label:SetTextColor(Def.TextColorDisabled[1], Def.TextColorDisabled[2], Def.TextColorDisabled[3])
            row.valueText:SetTextColor(Def.TextColorDisabled[1], Def.TextColorDisabled[2], Def.TextColorDisabled[3])
        end
    end

    function row:SetValue(value)
        value = ClampValue(value, row._min, row._max)
        value = RoundToStep(value, row._step, row._min)
        if value == nil then
            if row._min ~= nil then
                value = row._min
            else
                value = 0
            end
        end
        row._suppress = true
        slider.Slider:SetValue(value)
        row._suppress = false
        UpdateValueText(value)
    end

    function row:Refresh()
        local v
        if row._get then
            v = row._get()
        end
        if v == nil and slider.Slider then
            v = slider.Slider:GetValue()
        end
        if v == nil then
            v = row._min
        end
        if v == nil then
            v = 0
        end
        row:SetValue(v)
    end

    function row:UpdateLabel(text)
        row.label:SetText(text or "")
        if row.UpdateLayout then
            row:UpdateLayout()
        end
    end

    -- 根据行宽动态压缩标签，保障滑块可视宽度
    function row:UpdateLayout()
        local rowWidth = row:GetWidth()
        if not rowWidth or rowWidth <= 0 then return end
        if row._twoLine then
            local labelAvail = rowWidth - leftInset - rightInset
            if labelAvail < 0 then labelAvail = 0 end
            row.label:SetWidth(labelAvail)
            row.valueText:SetWidth(valueWidth)
            return
        end

        local available = rowWidth - valueWidth - gap * 2
        if available < 0 then available = 0 end

        local maxLabelWithMinSlider = available - sliderMinWidth
        local finalLabelWidth
        if maxLabelWithMinSlider >= labelMinWidth then
            finalLabelWidth = math.min(labelWidth, maxLabelWithMinSlider)
            if finalLabelWidth < labelMinWidth then
                finalLabelWidth = labelMinWidth
            end
        else
            -- 空间不足：优先保证标签可见，允许滑块缩短
            if available >= labelMinWidth then
                finalLabelWidth = math.min(labelWidth, available)
                if finalLabelWidth < labelMinWidth then
                    finalLabelWidth = labelMinWidth
                end
            else
                finalLabelWidth = math.max(0, math.min(labelWidth, available))
            end
        end
        row.label:SetWidth(finalLabelWidth)
        row.valueText:SetWidth(valueWidth)
    end

    row:SetScript("OnSizeChanged", function()
        row:UpdateLayout()
    end)

    row:UpdateLayout()
    row:Refresh()

    return row
end

-- ============================================================================
-- CreateCVarSliderRow - CVar 绑定的滑块行
-- ============================================================================

function ADT.DockUI.CreateCVarSliderRow(parent, width, cvarName, label, minValue, maxValue, step, opts)
    opts = opts or {}
    opts.min = minValue
    opts.max = maxValue
    opts.step = step

    local function getValue()
        local v = GetCVar and GetCVar(cvarName)
        if v == nil and C_CVar and C_CVar.GetCVar then
            v = C_CVar.GetCVar(cvarName)
        end
        return tonumber(v)
    end

    local function setValue(v)
        if SetCVar then
            SetCVar(cvarName, tostring(v))
        elseif C_CVar and C_CVar.SetCVar then
            C_CVar.SetCVar(cvarName, tostring(v))
        end
        if ADT.DebugPrint then
            ADT.DebugPrint(string.format("[CVar] SetCVar %s = %s", cvarName, tostring(v)))
        end
    end

    return ADT.DockUI.CreateSliderRow(parent, width, label, getValue, setValue, opts)
end
