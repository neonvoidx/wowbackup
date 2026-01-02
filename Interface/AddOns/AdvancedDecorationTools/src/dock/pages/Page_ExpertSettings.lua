-- Page_ExpertSettings.lua
-- 专家模式设置页面（使用 PageBase 基类重构）

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local PageBase = ADT.DockUI.PageBase
local Def = ADT.DockUI.Def
local GetRightPadding = ADT.DockUI.GetRightPadding
local L = ADT.L or {}
local function GetGizmoScale()
    return ADT.HousingGizmoScale
end
local GetHousingCVarDefaultNumber = ADT.GetHousingCVarDefaultNumber

-- ============================================================================
-- 创建页面实例（继承 PageBase）
-- ============================================================================

local PageExpertSettings = PageBase:New("ExpertSettings", { categoryType = "settings" })

-- CVar 配置
local CVARS = {
    SnapOnHold = { name = "housingExpertGizmos_SnapOnHold" },
    RotationSnapDegrees = { name = "housingExpertGizmos_Rotation_SnapDegrees" },
    ScaleSnap = { name = "housingExpertGizmos_Scale_Snap" },
}

-- 辅助函数
local function GetCVarNum(name)
    local v = C_CVar and C_CVar.GetCVar and C_CVar.GetCVar(name)
    return tonumber(v) or 0
end

local function SetCVarNum(name, value)
    if SetCVar then
        SetCVar(name, tostring(value))
    elseif C_CVar and C_CVar.SetCVar then
        C_CVar.SetCVar(name, tostring(value))
    end
end

-- 控件引用
local checkboxSnapOnHold, dropdownRotation, dropdownScale, sliderMove, sliderRotate, cbLabel, resetBtn

local function FormatScaleValue(value)
    return string.format("%.1f", value)
end

local function GetExpertPanelMetrics()
    local rowHeight = 32
    local sliderRowHeight = (Def.RowLayout and Def.RowLayout.SliderRowHeight) or 44
    local dropdownGap = 8
    local sliderGap = 8
    local resetHeight = 26
    local bottomPadding = 6
    local totalHeight = rowHeight * 3 + dropdownGap + sliderRowHeight * 2 + sliderGap + resetHeight + bottomPadding
    return rowHeight, sliderRowHeight, totalHeight
end

local function RefreshGizmoScaleSliders()
    local gizmo = GetGizmoScale()
    if not gizmo then return end
    gizmo:Refresh(true)

    local function RefreshRow(row, key)
        if not row then return end
        local v = gizmo:GetMultiplier(key)
        if v then
            row:SetEnabled(true)
            row:SetValue(v)
        else
            row:SetEnabled(false)
            row:SetValue(1.0)
        end
    end

    RefreshRow(sliderMove, "Translation")
    RefreshRow(sliderRotate, "Rotation")
end

-- 刷新控件状态（支持语言切换后动态更新）
local function RefreshControls()
    local L = ADT.L or {}
    if checkboxSnapOnHold then
        local snapVal = GetCVarNum(CVARS.SnapOnHold.name)
        checkboxSnapOnHold:SetChecked(snapVal == 0)
    end
    -- 动态刷新下拉框标签文本（支持语言切换）
    if dropdownRotation then
        if dropdownRotation.label then
            dropdownRotation.label:SetText(L["Rotation Snap Degrees"] or "Rotation Snap")
        end
        if dropdownRotation.UpdateLabel then
            dropdownRotation:UpdateLabel()
        end
    end
    if dropdownScale then
        if dropdownScale.label then
            dropdownScale.label:SetText(L["Scale Snap"] or "Scale Snap")
        end
        if dropdownScale.UpdateLabel then
            dropdownScale:UpdateLabel()
        end
    end
    if sliderMove and sliderMove.UpdateLabel then
        sliderMove:UpdateLabel(L["Move Gizmo Scale"] or "移动控件大小")
    end
    if sliderRotate and sliderRotate.UpdateLabel then
        sliderRotate:UpdateLabel(L["Rotate Gizmo Scale"] or "旋转控件大小")
    end
    if cbLabel then
        cbLabel:SetText(L["Default Snap Enabled"] or "Default Snap Enabled")
    end
    if resetBtn and resetBtn.SetText then
        resetBtn:SetText(L["Reset to Default"] or "Reset Default")
    end
    RefreshGizmoScaleSliders()
end

-- 创建专家面板
local function CreateExpertPanel(parent, width)
    local rowHeight, sliderRowHeight, panelHeight = GetExpertPanelMetrics()
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetSize(width, panelHeight)
    
    local offsetX = GetRightPadding()
    local y = 0
    
    -- 行1：SnapOnHold 复选框
    local row1 = CreateFrame("Frame", nil, panel)
    row1:SetPoint("TOPLEFT", panel, "TOPLEFT", offsetX, y)
    row1:SetSize(width - offsetX * 2, rowHeight)
    
    local cb = CreateFrame("CheckButton", nil, row1, "UICheckButtonTemplate")
    cb:SetPoint("LEFT", row1, "LEFT", 0, 0)
    cb:SetSize(24, 24)
    cb:SetChecked(GetCVarNum(CVARS.SnapOnHold.name) == 0)
    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        SetCVarNum(CVARS.SnapOnHold.name, checked and 0 or 1)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        print("|cFF00FF00[ADT]|r " .. (L["Default Snap Enabled"] or "Default Snap Enabled") .. " = " .. (checked and "ON" or "OFF"))
    end)
    
    cbLabel = row1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cbLabel:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cbLabel:SetText(L["Default Snap Enabled"] or "Default Snap Enabled")
    
    checkboxSnapOnHold = cb
    y = y - rowHeight
    
    -- 行2：旋转精度下拉
    local rotOptions = {
        {value = 5, text = "5°"},
        {value = 15, text = "15°"},
        {value = 30, text = "30°"},
        {value = 45, text = "45°"},
        {value = 90, text = "90°"},
    }
    
    dropdownRotation = ADT.DockUI.CreateCVarDropdownRow(
        panel, width - offsetX * 2,
        CVARS.RotationSnapDegrees.name,
        (L["Rotation Snap Degrees"] or "Rotation Snap"),
        rotOptions
    )
    dropdownRotation:SetPoint("TOPLEFT", panel, "TOPLEFT", offsetX, y)
    dropdownRotation:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -offsetX, y)
    y = y - rowHeight
    
    -- 行3：缩放精度下拉
    local scaleOptions = {
        {value = 0.1, text = "10%"},
        {value = 0.2, text = "20%"},
        {value = 0.5, text = "50%"},
        {value = 1, text = "100%"},
    }
    
    dropdownScale = ADT.DockUI.CreateCVarDropdownRow(
        panel, width - offsetX * 2,
        CVARS.ScaleSnap.name,
        (L["Scale Snap"] or "Scale Snap"),
        scaleOptions
    )
    dropdownScale:SetPoint("TOPLEFT", panel, "TOPLEFT", offsetX, y)
    dropdownScale:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -offsetX, y)
    y = y - rowHeight - 8

    -- 行4-5：操控器缩放滑块
    do
        local gizmo = GetGizmoScale()
        if gizmo then gizmo:Refresh(true) end
    end

    local sliderWidth = width - offsetX * 2
    local sliderOpts = {
        min = 0.1,
        max = 10.0,
        step = 0.1,
        formatValueFunc = FormatScaleValue,
    }

    sliderMove = ADT.DockUI.CreateSliderRow(
        panel, sliderWidth,
        (L["Move Gizmo Scale"] or "移动控件大小"),
        function()
            local gizmo = GetGizmoScale()
            return gizmo and gizmo:GetMultiplier("Translation") or nil
        end,
        function(v)
            local gizmo = GetGizmoScale()
            if gizmo then gizmo:SetMultiplier("Translation", v) end
        end,
        sliderOpts
    )
    sliderMove:SetPoint("TOPLEFT", panel, "TOPLEFT", offsetX, y)
    sliderMove:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -offsetX, y)
    y = y - sliderRowHeight

    sliderRotate = ADT.DockUI.CreateSliderRow(
        panel, sliderWidth,
        (L["Rotate Gizmo Scale"] or "旋转控件大小"),
        function()
            local gizmo = GetGizmoScale()
            return gizmo and gizmo:GetMultiplier("Rotation") or nil
        end,
        function(v)
            local gizmo = GetGizmoScale()
            if gizmo then gizmo:SetMultiplier("Rotation", v) end
        end,
        sliderOpts
    )
    sliderRotate:SetPoint("TOPLEFT", panel, "TOPLEFT", offsetX, y)
    sliderRotate:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -offsetX, y)
    y = y - sliderRowHeight

    y = y - 8
    
    -- 行7：重置按钮
    resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(100, 26)
    resetBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", offsetX, y)
    resetBtn:SetText(L["Reset to Default"] or "Reset Default")
    resetBtn:SetScript("OnClick", function()
        local snapDefault = GetHousingCVarDefaultNumber(CVARS.SnapOnHold.name)
        local rotDefault = GetHousingCVarDefaultNumber(CVARS.RotationSnapDegrees.name)
        local scaleDefault = GetHousingCVarDefaultNumber(CVARS.ScaleSnap.name)
        if snapDefault ~= nil then SetCVarNum(CVARS.SnapOnHold.name, snapDefault) end
        if rotDefault ~= nil then SetCVarNum(CVARS.RotationSnapDegrees.name, rotDefault) end
        if scaleDefault ~= nil then SetCVarNum(CVARS.ScaleSnap.name, scaleDefault) end
        do
            local gizmo = GetGizmoScale()
            if gizmo then
                gizmo:ResetToDefault("Translation")
                gizmo:ResetToDefault("Rotation")
            end
        end
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        print("|cFF00FF00[ADT]|r " .. (L["Expert Settings Reset"] or "Expert settings reset"))
        RefreshControls()
    end)
    
    return panel
end

--- 覆盖：渲染方法
function PageExpertSettings:Render(mainFrame, categoryKey)
    local ok, ctx = self:PreRender(mainFrame, categoryKey)
    if not ok then return false end
    
    -- 设置分类状态
    self:SetCategoryState(ctx, "currentSettingsCategory")
    
    -- 渲染标题
    self:RenderCategoryHeader(ctx)
    
    -- 注册专家面板模板
    local sv = mainFrame.ModuleTab.ScrollView
    local totalWidth = mainFrame.centerButtonWidth or 300
    local panelWidth = totalWidth - ctx.offsetX * 2
    local _, _, panelHeight = GetExpertPanelMetrics()
    local panelKey = "ExpertSettingsPanel"
    
    if sv and sv._templates then
        sv._templates[panelKey] = nil
        sv:AddTemplate(panelKey, function()
            local cached = self:GetCachedFrame(panelKey)
            if cached then
                cached:SetParent(sv)
                cached:SetWidth(panelWidth)
                RefreshControls()
                return cached
            end
            local panel = CreateExpertPanel(sv, panelWidth)
            self:RegisterCachedFrame(panelKey, panel)
            return panel
        end)
    end
    
    self:AddContentItem(ctx, {
        templateKey = panelKey,
        setupFunc = function(obj)
            RefreshControls()
        end,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        top = ctx.offsetY,
        bottom = ctx.offsetY + panelHeight,
        offsetX = ctx.offsetX,
    })
    
    -- 提交
    self:CommitRender(ctx)
    
    return true
end

-- 销毁缓存
function PageExpertSettings:InvalidateCachedFrames()
    PageBase.InvalidateCachedFrames(self)
    checkboxSnapOnHold = nil
    dropdownRotation = nil
    dropdownScale = nil
    sliderMove = nil
    sliderRotate = nil
    cbLabel = nil
    resetBtn = nil
end

-- ============================================================================
-- 注册页面
-- ============================================================================

ADT.DockPages:Register("ExpertSettings", PageExpertSettings)
ADT.DockPages.PageExpertSettings = PageExpertSettings
