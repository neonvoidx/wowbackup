-- DockUI_Dropdown.lua
-- DockUI 统一下拉菜单系统
-- 单一权威：所有下拉菜单均使用 Blizzard 原生 MenuUtil.CreateContextMenu 样式

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local L = ADT.L or {}

-- ============================================================================
-- 公共工具函数（单一权威）
-- ============================================================================

--- 比较两个值是否相等（支持浮点数容差）
--- @param a any 值1
--- @param b any 值2
--- @return boolean 是否相等
local function ValuesEqual(a, b)
    local na, nb = tonumber(a), tonumber(b)
    if na and nb then
        return math.abs(na - nb) < 0.01
    end
    return a == b
end

--- 在选项列表中查找匹配值对应的文本
--- @param options table 选项数组 { {value=..., text=...}, ... }
--- @param currentValue any 当前值（可以是 nil）
--- @return string|nil 匹配的文本，或 nil
local function FindOptionText(options, currentValue)
    if not options then return nil end
    for _, opt in ipairs(options) do
        if opt then
            -- 支持 value=nil 的选项（如语言的 "Auto" 选项）
            if opt.value == nil and currentValue == nil then
                local t = type(opt.text) == 'function' and opt.text() or opt.text
                return t
            elseif opt.value ~= nil and ValuesEqual(opt.value, currentValue) then
                local t = type(opt.text) == 'function' and opt.text() or opt.text
                return t
            end
        end
    end
    return nil
end

-- 导出公共工具函数
ADT.DockUI.ValuesEqual = ValuesEqual
ADT.DockUI.FindOptionText = FindOptionText

-- ============================================================================
-- 统一下拉菜单模块（单例）
-- ============================================================================

local DropdownMenu = {}
ADT.DockUI.DropdownMenu = DropdownMenu

--[[
    ShowMenu - 统一下拉菜单入口（单一权威）
    
    所有下拉菜单弹出逻辑的唯一实现，使用 Blizzard 原生 MenuUtil.CreateContextMenu。
    
    支持两种模式：
    
    模式1：dbKey 绑定（EntryFactory 数据驱动条目使用）
        ShowMenu(owner, options, dbKey, toggleFunc)
        
    模式2：Callback 绑定（Bespoke Row 使用）
        ShowMenu(owner, options, nil, nil, {
            getValue = function() return currentValue end,
            setValue = function(v) ... end,
            onSelect = function() ... end,  -- 可选
        })
    
    options 格式：
        { value = 15, text = "15°" },                                      -- 普通选项
        { action = 'button', text = "自定义...", onClick = function() end }, -- 按钮
]]
function DropdownMenu:ShowMenu(owner, options, dbKey, toggleFunc, opts)
    if not owner or not options then return end
    
    ADT.DebugPrint(string.format("[Dropdown] ShowMenu called, dbKey=%s, options count=%d, callbackMode=%s",
        tostring(dbKey), #options, tostring(opts ~= nil)))
    
    -- 判断模式：callback 模式 vs dbKey 模式
    local useCallback = opts and type(opts.getValue) == 'function' and type(opts.setValue) == 'function'
    
    -- 获取当前值
    local function getCurrentValue()
        if useCallback then
            return opts.getValue()
        elseif dbKey then
            return ADT.GetDBValue(dbKey)
        end
        return nil
    end
    
    -- 设置新值
    local function setNewValue(value)
        if useCallback then
            opts.setValue(value)
            if opts.onSelect then opts.onSelect() end
        elseif dbKey then
            ADT.SetDBValue(dbKey, value)
            if toggleFunc then toggleFunc(value) end
            -- 刷新 EntryFactory 条目标签
            if owner.UpdateDropdownLabel then
                owner:UpdateDropdownLabel()
            end
            -- 刷新设置面板
            local MainFrame = ADT.CommandDock and ADT.CommandDock.SettingsPanel
            if MainFrame and MainFrame.UpdateSettingsEntries then
                MainFrame:UpdateSettingsEntries()
            end
        end
    end
    
    -- 使用 Blizzard 原生菜单
    local menu = MenuUtil.CreateContextMenu(owner, function(ownerRegion, rootDescription)
        local currentValue = getCurrentValue()
        
        for _, opt in ipairs(options) do
            if opt.action == 'button' and opt.onClick then
                -- 按钮类型（如"自定义..."）
                local label = (type(opt.text) == 'function' and opt.text() or opt.text) or ""
                rootDescription:CreateButton(label, function()
                    opt.onClick()
                end)
            else
                -- 普通单选项
                local function IsSelected()
                    return ValuesEqual(getCurrentValue(), opt.value)
                end
                local function SetSelected()
                    setNewValue(opt.value)
                end
                local label = (type(opt.text) == 'function' and opt.text() or opt.text) or ""
                rootDescription:CreateRadio(label, IsSelected, SetSelected, opt.value)
            end
        end
    end)

    if menu and owner and owner._adtSetMenuOpen then
        owner._adtSetMenuOpen(true, menu)
        if menu.SetClosedCallback then
            menu:SetClosedCallback(function()
                if owner and owner._adtSetMenuOpen then
                    owner._adtSetMenuOpen(false, menu)
                end
            end)
        end
    end
end

-- ============================================================================
-- CreateDropdownRow - 通用"标签 + 下拉按钮"一行控件（单一权威布局）
-- ============================================================================

-- 临时 FontString 用于测量文本宽度
local measureFS = nil
local function MeasureTextWidth(text, fontObject)
    if not measureFS then
        measureFS = UIParent:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
        measureFS:Hide()
    end
    if fontObject then
        measureFS:SetFontObject(fontObject)
    end
    measureFS:SetText(text or "")
    return measureFS:GetStringWidth() or 0
end

--- 根据选项列表计算下拉按钮所需宽度
--- @param options table 选项数组
--- @return number 计算出的宽度
local function ComputeDropdownWidth(options)
    local Def = ADT.DockUI.Def
    local rl = Def.RowLayout or {}
    local minW = rl.DropdownMinWidth or 80
    local maxW = rl.DropdownMaxWidth or 140
    local padding = rl.DropdownPadding or 24
    
    local maxTextWidth = 0
    if options then
        for _, opt in ipairs(options) do
            -- 跳过 action='button' 类型的选项（如"自定义..."），只计算普通选项
            if opt and opt.text and opt.action ~= 'button' then
                local txt = type(opt.text) == 'function' and opt.text() or opt.text
                local w = MeasureTextWidth(txt)
                if w > maxTextWidth then maxTextWidth = w end
            end
        end
    end
    
    local computed = maxTextWidth + padding
    return math.max(minW, math.min(computed, maxW))
end

--[[
    CreateDropdownRow - 创建带标签的下拉按钮行（单一权威布局）
    
    布局模型（左右对齐）：
        |<---- width ---->|
        | [Label]  [Btn→] |
        |   ↑         ↑    |
        | LEFT     RIGHT   |
    
    参数：
        parent      - 父容器
        width       - 行宽
        label       - 左侧标签文本
        options     - 下拉项数组 { {value=..., text=...}, ... }
        getValue()  - 读取当前值
        setValue(v) - 设置新值
        opts        - 可选配置 { onSet }（已移除硬编码布局参数）
    
    返回：
        row         - Frame，带有 UpdateLabel() 方法
]]
function ADT.DockUI.CreateDropdownRow(parent, width, label, options, getValue, setValue, opts)
    local Def = ADT.DockUI.Def
    local rl = Def.RowLayout or {}
    local rowHeight = rl.RowHeight or 28
    local labelLeftInset = rl.LabelLeftInset or 0
    local controlRightInset = rl.ControlRightInset or 4
    
    local row = CreateFrame("Frame", nil, parent)
    -- 只设置高度，宽度由外部锚点决定（支持双锚点拉伸）
    row:SetHeight(rowHeight)

    -- 动态计算按钮宽度
    local buttonWidth = ComputeDropdownWidth(options)

    -- 标签 - 锚定于行左侧
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", row, "LEFT", labelLeftInset, 0)
    text:SetPoint("RIGHT", row, "RIGHT", -(controlRightInset + buttonWidth + 8), 0)  -- 留出按钮空间+间距
    text:SetJustifyH("LEFT")
    text:SetText(label)
    row.label = text

    -- 下拉按钮 - 锚定于行右侧
    local btn = CreateFrame("Button", nil, row)
    btn:SetSize(buttonWidth, 22)
    btn:SetPoint("RIGHT", row, "RIGHT", -controlRightInset, 0)

    -- 统一使用“common-dropdown-b”风格（四态）：
    -- normal/hover/pressed/pressedHover
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetAtlas("common-dropdown-b-button")

    btn.hover = btn:CreateTexture(nil, "ARTWORK")
    btn.hover:SetAllPoints()
    btn.hover:SetAtlas("common-dropdown-b-button-hover")
    btn.hover:Hide()

    btn.pressed = btn:CreateTexture(nil, "ARTWORK", nil, 1)
    btn.pressed:SetAllPoints()
    btn.pressed:SetAtlas("common-dropdown-b-button-pressed")
    btn.pressed:Hide()

    btn.pressedHover = btn:CreateTexture(nil, "ARTWORK", nil, 2)
    btn.pressedHover:SetAllPoints()
    btn.pressedHover:SetAtlas("common-dropdown-b-button-pressedhover")
    btn.pressedHover:Hide()

    btn.valueText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    -- 居中逻辑（修复视觉左偏）：
    -- 关键在于右侧箭头会占位 ARROW_AREA，使得文本可用区域相对按钮中心左移。
    -- 解决方案：对文本层使用对称的 L/R 锚点（在两侧都加上 ARROW_AREA/2 的“折中”），
    -- 从而保证文本可用区域关于按钮中心对称，再配合 JustifyH("CENTER") 达到真正居中。
    local ARROW_W, ARROW_RIGHT_PAD, TEXT_SIDE_PAD = 12, 4, 4
    local ARROW_AREA = ARROW_W + ARROW_RIGHT_PAD
    btn.valueText:ClearAllPoints()
    btn.valueText:SetPoint("LEFT", btn, "LEFT", TEXT_SIDE_PAD + ARROW_AREA/2, 0)
    btn.valueText:SetPoint("RIGHT", btn, "RIGHT", -(TEXT_SIDE_PAD + ARROW_AREA/2), 0)
    btn.valueText:SetJustifyH("CENTER")
    btn.valueText:SetTextColor(1, 0.82, 0)

    local arrow = btn:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(ARROW_W, ARROW_W)
    arrow:SetPoint("RIGHT", btn, "RIGHT", -ARROW_RIGHT_PAD, 0)
    -- 暂未发现 b 套装独立箭头贴图，沿用现有箭头资源。
    arrow:SetAtlas("common-dropdown-c-button-arrow-down")


    row.options = options or {}
    row._get = getValue
    row._set = setValue
    row.button = btn

    -- 更新按钮显示文本（使用公共工具函数）
    function row:UpdateLabel()
        local current = self._get and self._get() or nil
        local optText = FindOptionText(self.options, current)
        btn.valueText:SetText(optText or tostring(current or ""))
        -- 文本变更后可能影响计算宽度（特别是语言选项），
        -- 重新计算按钮宽度并更新锚点，保持视觉居中与不截断。
        local newW = ComputeDropdownWidth(self.options)
        btn:SetWidth(newW)
        -- 重新应用对称锚点（左右各让出 ARROW_AREA/2）
        local ARROW_W, ARROW_RIGHT_PAD, TEXT_SIDE_PAD = 12, 4, 4
        local ARROW_AREA = ARROW_W + ARROW_RIGHT_PAD
        btn.valueText:ClearAllPoints()
        btn.valueText:SetPoint("LEFT", btn, "LEFT", TEXT_SIDE_PAD + ARROW_AREA/2, 0)
        btn.valueText:SetPoint("RIGHT", btn, "RIGHT", -(TEXT_SIDE_PAD + ARROW_AREA/2), 0)
    end

    -- 状态刷新（四态 + open）
    local isOver, isDown, isOpen = false, false, false
    local function RefreshStates()
        if not btn:IsEnabled() then
            -- 禁用态：直接使用 b-disabled，隐藏其他层
            btn.bg:SetAtlas("common-dropdown-b-button-disabled")
            btn.hover:Hide(); btn.pressed:Hide(); btn.pressedHover:Hide()
            return
        else
            if isOpen and (not isOver) and (not isDown) then
                btn.bg:SetAtlas("common-dropdown-b-button-open")
            else
                btn.bg:SetAtlas("common-dropdown-b-button")
            end
        end

        if isDown and isOver then
            btn.pressedHover:Show(); btn.hover:Hide(); btn.pressed:Hide()
        else
            btn.pressedHover:Hide()
            if isDown then
                btn.pressed:Show(); btn.hover:Hide()
            elseif isOver then
                btn.hover:Show(); btn.pressed:Hide()
            else
                btn.hover:Hide(); btn.pressed:Hide()
            end
        end
    end

    btn._adtSetMenuOpen = function(open, menu)
        if open then
            isOpen = true
            btn._adtOpenMenu = menu
        else
            if (not menu) or btn._adtOpenMenu == menu then
                isOpen = false
                btn._adtOpenMenu = nil
            end
        end
        RefreshStates()
    end

    btn:SetScript("OnEnter", function() isOver = true; RefreshStates() end)
    btn:SetScript("OnLeave", function() isOver = false; RefreshStates() end)
    btn:SetScript("OnMouseDown", function() isDown = true; RefreshStates() end)
    btn:SetScript("OnMouseUp", function() isDown = false; RefreshStates() end)
    btn:SetScript("OnEnable", RefreshStates)
    btn:SetScript("OnDisable", RefreshStates)

    -- 点击按钮时，调用统一的下拉菜单模块
    btn:SetScript("OnClick", function()
        DropdownMenu:ShowMenu(btn, row.options, nil, nil, {
            getValue = row._get,
            setValue = function(v)
                if row._set then row._set(v) end
            end,
            onSelect = function()
                row:UpdateLabel()
            end,
        })
    end)

    -- 初始化显示
    row:UpdateLabel()
    RefreshStates()

    return row
end

-- ============================================================================
-- CreateCVarDropdownRow - CVar 绑定的下拉行（消除重复的 getValue/setValue）
-- ============================================================================

--[[
    CreateCVarDropdownRow - 创建 CVar 绑定的下拉按钮行
    
    专门用于控制 CVar 的下拉菜单，消除页面文件中重复的 getValue/setValue 定义。
    
    参数：
        parent      - 父容器
        width       - 行宽
        cvarName    - CVar 名称（如 "housingExpertGizmos_Rotation_SnapDegrees"）
        label       - 左侧标签文本
        options     - 下拉项数组 { {value=..., text=...}, ... }
        opts        - 可选配置 { labelOffsetX, buttonOffsetX, buttonWidth, onSet }
    
    返回：
        row         - Frame，带有 UpdateLabel() 方法
]]
function ADT.DockUI.CreateCVarDropdownRow(parent, width, cvarName, label, options, opts)
    local cfg = opts or {}
    
    local function getValue()
        local val = GetCVar(cvarName)
        return tonumber(val) or val
    end
    
    local function setValue(v)
        SetCVar(cvarName, v)
        if ADT.DebugPrint then
            ADT.DebugPrint(string.format("[CVar] SetCVar %s = %s", cvarName, tostring(v)))
        end
        if cfg.onSet then cfg.onSet(v) end
    end
    
    return ADT.DockUI.CreateDropdownRow(parent, width, label, options, getValue, setValue, cfg)
end

-- ============================================================================
-- CreateDBDropdownRow - DB 绑定的下拉行（消除重复的 getValue/setValue）
-- ============================================================================

--[[
    CreateDBDropdownRow - 创建 DB 绑定的下拉按钮行
    
    专门用于控制 ADT.GetDBValue/SetDBValue 的下拉菜单。
    
    参数：
        parent      - 父容器
        width       - 行宽
        dbKey       - DB 键名（如 "ExpertPulseDegrees"）
        label       - 左侧标签文本
        options     - 下拉项数组 { {value=..., text=...}, ... }
        opts        - 可选配置 { onSet }（布局参数由 Def.RowLayout 统一控制）
    
    返回：
        row         - Frame，带有 UpdateLabel() 方法
]]
function ADT.DockUI.CreateDBDropdownRow(parent, width, dbKey, label, options, opts)
    local cfg = opts or {}
    
    local function getValue()
        return ADT.GetDBValue and ADT.GetDBValue(dbKey)
    end
    
    local function setValue(v)
        if ADT.SetDBValue then ADT.SetDBValue(dbKey, v) end
        if ADT.DebugPrint then
            ADT.DebugPrint(string.format("[DB] SetDBValue %s = %s", dbKey, tostring(v)))
        end
        if cfg.onSet then cfg.onSet(v) end
    end
    
    return ADT.DockUI.CreateDropdownRow(parent, width, label, options, getValue, setValue, cfg)
end
