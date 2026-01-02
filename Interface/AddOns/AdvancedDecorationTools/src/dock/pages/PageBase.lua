-- PageBase.lua
-- DockUI 页面基类：抽象公共渲染逻辑，消除 Page_* 重复代码
-- 设计原则：子类只需定义差异部分，基类处理通用模板

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local CommandDock = ADT.CommandDock
local Def = ADT.DockUI.Def
local GetRightPadding = ADT.DockUI.GetRightPadding

-- ============================================================================
-- PageBase 类定义
-- ============================================================================

local PageBase = {}
PageBase.__index = PageBase

ADT.DockUI.PageBase = PageBase

--- 创建新页面实例
--- @param categoryKey string 分类键名（如 "Housing", "Clipboard"）
--- @param opts table|nil 可选配置 { categoryType = "settings"|"decorList"|... }
--- @return table 页面实例
function PageBase:New(categoryKey, opts)
    local instance = setmetatable({}, self)
    instance.categoryKey = categoryKey
    instance.opts = opts or {}
    instance._cachedFrames = {}
    return instance
end

--- 辅助：设置文本颜色
--- @param obj FontString 文本对象
--- @param color table {r, g, b} 或 {[1]=r, [2]=g, [3]=b}
local function SetTextColor(obj, color)
    if not obj or not color then return end
    obj:SetTextColor(color[1], color[2], color[3])
end

--- 导出给子类使用
PageBase.SetTextColor = SetTextColor

-- ============================================================================
-- 缓存管理（统一实现）
-- ============================================================================

--- 注册缓存的 Frame（语言切换时自动清理）
--- @param key string 缓存键名
--- @param frame Frame 缓存的 Frame
function PageBase:RegisterCachedFrame(key, frame)
    self._cachedFrames[key] = frame
end

--- 获取缓存的 Frame
--- @param key string 缓存键名
--- @return Frame|nil
function PageBase:GetCachedFrame(key)
    return self._cachedFrames[key]
end

--- 销毁所有缓存的 Frame（语言切换时调用）
function PageBase:InvalidateCachedFrames()
    for key, frame in pairs(self._cachedFrames) do
        if frame and frame.Hide then
            frame:Hide()
        end
    end
    wipe(self._cachedFrames)
end

-- ============================================================================
-- 渲染状态管理
-- ============================================================================

--- 渲染上下文：封装渲染过程中的共享状态
--- @return table 上下文对象
function PageBase:CreateRenderContext(mainFrame, categoryKey)
    local ctx = {
        mainFrame = mainFrame,
        categoryKey = categoryKey,
        cat = CommandDock:GetCategoryByKey(categoryKey),
        content = {},
        n = 0,
        offsetY = Def.ButtonSize,
        offsetX = GetRightPadding(),
        buttonHeight = Def.ButtonSize,
    }
    return ctx
end

--- 添加内容项（自动管理 dataIndex）
--- @param ctx table 渲染上下文
--- @param item table 内容项配置
function PageBase:AddContentItem(ctx, item)
    ctx.n = ctx.n + 1
    item.dataIndex = ctx.n
    ctx.content[ctx.n] = item
end

--- 更新 offsetY（渲染后移动光标）
--- @param ctx table 渲染上下文
--- @param height number 增加的高度
function PageBase:AdvanceOffset(ctx, height)
    ctx.offsetY = ctx.offsetY + height
end

-- ============================================================================
-- 通用渲染组件
-- ============================================================================

--- 渲染标准 Header
--- @param ctx table 渲染上下文
--- @param text string|function 标题文本或返回文本的函数
--- @param opts table|nil 可选 { showDivider = true, color = nil }
function PageBase:RenderHeader(ctx, text, opts)
    opts = opts or {}
    local showDivider = opts.showDivider ~= false
    local color = opts.color
    local height = opts.height or ctx.buttonHeight
    
    self:AddContentItem(ctx, {
        templateKey = "Header",
        setupFunc = function(obj)
            local displayText = type(text) == "function" and text() or text
            obj:SetText(displayText)
            if obj.Left then obj.Left:Hide() end
            if obj.Right then obj.Right:Hide() end
            if obj.Divider then obj.Divider:SetShown(showDivider) end
            obj.Label:SetJustifyH("LEFT")
            if color then
                SetTextColor(obj.Label, color)
            end
        end,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        top = ctx.offsetY,
        bottom = ctx.offsetY + height,
        offsetX = opts.offsetX or ctx.offsetX,
    })
    self:AdvanceOffset(ctx, height)
end

--- 渲染分类标题（带分隔线）
--- @param ctx table 渲染上下文
function PageBase:RenderCategoryHeader(ctx)
    if not ctx.cat then return end
    self:RenderHeader(ctx, ctx.cat.categoryName, { showDivider = true })
end

--- 渲染设置条目列表（处理 modules + subOptions）
--- @param ctx table 渲染上下文
function PageBase:RenderSettingsEntries(ctx)
    if not ctx.cat or not ctx.cat.modules then return end
    
    for _, data in ipairs(ctx.cat.modules) do
        local top = ctx.offsetY
        local bottom = top + ctx.buttonHeight
        
        self:AddContentItem(ctx, {
            templateKey = "Entry",
            setupFunc = function(obj)
                obj.parentDBKey = nil
                obj:SetData(data)
            end,
            point = "TOPLEFT",
            relativePoint = "TOPLEFT",
            top = top,
            bottom = bottom,
            offsetX = ctx.offsetX,
        })
        ctx.offsetY = bottom
        
        -- 子选项（缩进）
        if data.subOptions then
            for _, v in ipairs(data.subOptions) do
                top = ctx.offsetY
                bottom = top + ctx.buttonHeight
                local parentKey = data.dbKey
                
                self:AddContentItem(ctx, {
                    templateKey = "Entry",
                    setupFunc = function(obj)
                        obj.parentDBKey = parentKey
                        obj:SetData(v)
                    end,
                    point = "TOPLEFT",
                    relativePoint = "TOPLEFT",
                    top = top,
                    bottom = bottom,
                    offsetX = ctx.offsetX + 0.5 * Def.ButtonSize,
                })
                ctx.offsetY = bottom
            end
        end
    end
end

--- 渲染装饰列表（处理 getListData）
--- @param ctx table 渲染上下文
--- @param opts table|nil { itemHeight = 36, itemGap = 2, templateKey = "DecorItem" }
function PageBase:RenderDecorList(ctx, opts)
    opts = opts or {}
    local itemHeight = opts.itemHeight or 36
    local itemGap = opts.itemGap or 2
    local templateKey = opts.templateKey or "DecorItem"
    
    local list = ctx.cat.getListData and ctx.cat.getListData() or {}
    
    if #list == 0 then
        -- 空列表提示
        local emptyText = ctx.cat.emptyText or ADT.L["List Is Empty"]
        self:RenderHeader(ctx, emptyText:match("^([^\n]*)") or emptyText, {
            showDivider = false,
            color = Def.TextColorDisabled,
        })
    else
        for i, item in ipairs(list) do
            local top = ctx.offsetY
            local bottom = top + itemHeight + itemGap
            local capCat, capItem = ctx.cat, item
            
            self:AddContentItem(ctx, {
                templateKey = templateKey,
                setupFunc = function(obj)
                    obj:SetData(capItem, capCat)
                end,
                point = "TOPLEFT",
                relativePoint = "TOPLEFT",
                top = top,
                bottom = bottom,
                offsetX = ctx.offsetX,
            })
            ctx.offsetY = bottom
        end
    end
end

-- ============================================================================
-- 统一下拉面板渲染（消除 Page 文件中的重复代码）
-- ============================================================================

--- 创建下拉面板容器（内部辅助）
--- @param parent Frame 父容器
--- @param width number 面板宽度
--- @param dbKey string DB 键名
--- @param label string 标签文本
--- @param options table 下拉选项
--- @param onSet function|nil 设置回调
--- @return Frame 面板容器
local function CreateDBDropdownPanelFrame(parent, width, dbKey, label, options, onSet)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, 36)

    local row = ADT.DockUI.CreateDBDropdownRow(
        frame, width,
        dbKey,
        label,
        options,
        { onSet = onSet }
    )
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
    row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -4)
    frame.dropdown = row
    
    return frame
end

--- 渲染 DB 绑定的下拉面板（带缓存管理）
--- @param ctx table 渲染上下文
--- @param key string 缓存键名（也用作模板名）
--- @param dbKey string DB 键名
--- @param label string 标签文本（支持本地化键）
--- @param options table 下拉选项数组
--- @param opts table|nil 可选 { height = 36, onSet = function(v) end }
function PageBase:RenderDBDropdownPanel(ctx, key, dbKey, label, options, opts)
    opts = opts or {}
    local height = opts.height or 36
    local onSet = opts.onSet
        
    local sv = ctx.mainFrame.ModuleTab.ScrollView
    local totalWidth = ctx.mainFrame.centerButtonWidth or 300
    local panelWidth = totalWidth - ctx.offsetX * 2
    
    -- 保存本地化键（不在此处求值，延迟到 setupFunc）
    local labelKey = label
    
    -- 注册模板
    if sv and sv._templates then
        sv._templates[key] = nil  -- 清除旧模板以支持语言切换
        sv:AddTemplate(key, function()
            local cached = self:GetCachedFrame(key)
            if cached then
                cached:SetParent(sv)
                cached:SetWidth(panelWidth)
                -- 动态刷新标签文本（支持语言切换）
                if cached.dropdown and cached.dropdown.label then
                    local L = ADT.L or {}
                    local newLabel = L[labelKey] or labelKey
                    if type(newLabel) ~= "string" then newLabel = tostring(labelKey) end
                    cached.dropdown.label:SetText(newLabel)
                end
                if cached.dropdown and cached.dropdown.UpdateLabel then
                    cached.dropdown:UpdateLabel()
                end
                return cached
            end
            -- 首次创建时求值标签
            local L = ADT.L or {}
            local labelText = L[labelKey] or labelKey
            if type(labelText) ~= "string" then labelText = tostring(labelKey) end
            local panel = CreateDBDropdownPanelFrame(sv, panelWidth, dbKey, labelText, options, onSet)
            -- 保存本地化键到面板，便于后续刷新
            panel._labelKey = labelKey
            self:RegisterCachedFrame(key, panel)
            return panel
        end)
    end
    
    -- 添加到内容
    self:AddContentItem(ctx, {
        templateKey = key,
        setupFunc = function(obj)
            -- 每次显示时动态刷新标签（支持语言切换）
            if obj.dropdown and obj.dropdown.label and obj._labelKey then
                local L = ADT.L or {}
                local newLabel = L[obj._labelKey] or obj._labelKey
                if type(newLabel) ~= "string" then newLabel = tostring(obj._labelKey) end
                obj.dropdown.label:SetText(newLabel)
            end
            if obj.dropdown and obj.dropdown.UpdateLabel then
                obj.dropdown:UpdateLabel()
            end
        end,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        top = ctx.offsetY,
        bottom = ctx.offsetY + height,
        offsetX = ctx.offsetX,
    })
    self:AdvanceOffset(ctx, height)
end

--- 渲染 CVar 绑定的下拉面板（带缓存管理）
--- @param ctx table 渲染上下文
--- @param key string 缓存键名
--- @param cvarName string CVar 名称
--- @param label string 标签文本（本地化键）
--- @param options table 下拉选项数组
--- @param opts table|nil 可选 { height = 36, onSet = function(v) end }
function PageBase:RenderCVarDropdownPanel(ctx, key, cvarName, label, options, opts)
    opts = opts or {}
    local height = opts.height or 36
    local onSet = opts.onSet
    
    local sv = ctx.mainFrame.ModuleTab.ScrollView
    local totalWidth = ctx.mainFrame.centerButtonWidth or 300
    local panelWidth = totalWidth - ctx.offsetX * 2
    
    -- 保存本地化键（不在此处求值，延迟到 setupFunc）
    local labelKey = label
    
    if sv and sv._templates then
        sv._templates[key] = nil
        sv:AddTemplate(key, function()
            local cached = self:GetCachedFrame(key)
            if cached then
                cached:SetParent(sv)
                cached:SetWidth(panelWidth)
                -- 动态刷新标签文本（支持语言切换）
                if cached.dropdown and cached.dropdown.label then
                    local L = ADT.L or {}
                    local newLabel = L[labelKey] or labelKey
                    if type(newLabel) ~= "string" then newLabel = tostring(labelKey) end
                    cached.dropdown.label:SetText(newLabel)
                end
                if cached.dropdown and cached.dropdown.UpdateLabel then
                    cached.dropdown:UpdateLabel()
                end
                return cached
            end
            
            -- 首次创建时求值标签
            local L = ADT.L or {}
            local labelText = L[labelKey] or labelKey
            if type(labelText) ~= "string" then labelText = tostring(labelKey) end
            
            local frame = CreateFrame("Frame", nil, sv)
            frame:SetSize(panelWidth, 36)
            
            local row = ADT.DockUI.CreateCVarDropdownRow(
                frame, panelWidth,
                cvarName,
                labelText,
                options,
                { onSet = onSet }
            )
            row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
            row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -4)
            frame.dropdown = row
            -- 保存本地化键到面板，便于后续刷新
            frame._labelKey = labelKey
            
            self:RegisterCachedFrame(key, frame)
            return frame
        end)
    end
    
    self:AddContentItem(ctx, {
        templateKey = key,
        setupFunc = function(obj)
            -- 每次显示时动态刷新标签（支持语言切换）
            if obj.dropdown and obj.dropdown.label and obj._labelKey then
                local L = ADT.L or {}
                local newLabel = L[obj._labelKey] or obj._labelKey
                if type(newLabel) ~= "string" then newLabel = tostring(obj._labelKey) end
                obj.dropdown.label:SetText(newLabel)
            end
            if obj.dropdown and obj.dropdown.UpdateLabel then
                obj.dropdown:UpdateLabel()
            end
        end,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        top = ctx.offsetY,
        bottom = ctx.offsetY + height,
        offsetX = ctx.offsetX,
    })
    self:AdvanceOffset(ctx, height)
end

-- ============================================================================
-- 主渲染入口
-- ============================================================================

--- 渲染前置检查
--- @param mainFrame Frame 主框架
--- @param categoryKey string 分类键
--- @return boolean, table|nil 是否通过检查，渲染上下文
function PageBase:PreRender(mainFrame, categoryKey)
    categoryKey = categoryKey or self.categoryKey
    
    -- 检查 ScrollView 是否就绪
    if not (mainFrame.ModuleTab and mainFrame.ModuleTab.ScrollView) then
        mainFrame.__pendingTabKey = categoryKey
        return false, nil
    end
    
    -- 获取分类
    local ctx = self:CreateRenderContext(mainFrame, categoryKey)
    if not ctx.cat then
        return false, nil
    end
    
    return true, ctx
end

--- 设置分类状态（更新 mainFrame 当前分类标记）
--- @param ctx table 渲染上下文
--- @param stateKey string 状态键名（如 "currentSettingsCategory"）
function PageBase:SetCategoryState(ctx, stateKey)
    local mainFrame = ctx.mainFrame
    
    -- 清除所有分类状态
    mainFrame.currentSettingsCategory = nil
    mainFrame.currentDecorCategory = nil
    mainFrame.currentAboutCategory = nil
    mainFrame.currentDyePresetsCategory = nil
    mainFrame.currentKeybindsCategory = nil
    
    -- 设置当前分类
    if stateKey then
        mainFrame[stateKey] = ctx.categoryKey
    end
    
    -- 持久化移除：分类选择的落盘统一由 Controller 处理（单一权威）。
end

--- 提交渲染内容
--- @param ctx table 渲染上下文
function PageBase:CommitRender(ctx)
    local mainFrame = ctx.mainFrame
    mainFrame.ModuleTab.ScrollView:SetContent(ctx.content, false)
    if mainFrame.UpdateAutoWidth then
        mainFrame:UpdateAutoWidth()
    end
end

--- 主渲染方法（子类可覆盖）
--- @param mainFrame Frame 主框架
--- @param categoryKey string 分类键
--- @return boolean 是否渲染成功
function PageBase:Render(mainFrame, categoryKey)
    local ok, ctx = self:PreRender(mainFrame, categoryKey)
    if not ok then return false end
    
    -- 设置分类状态（默认 settings 类型）
    self:SetCategoryState(ctx, "currentSettingsCategory")
    
    -- 渲染标题
    self:RenderCategoryHeader(ctx)
    
    -- 根据分类类型渲染内容
    if ctx.cat.categoryType == "decorList" then
        self:RenderDecorList(ctx)
    elseif ctx.cat.categoryType == "settings" or ctx.cat.modules then
        self:RenderSettingsEntries(ctx)
    end
    
    -- 子类扩展点：渲染额外内容
    if self.RenderExtra then
        self:RenderExtra(ctx)
    end
    
    -- 提交
    self:CommitRender(ctx)
    
    -- 设置首个模块数据（用于高亮）
    mainFrame.firstModuleData = ctx.cat.modules and ctx.cat.modules[1] or nil
    
    return true
end

-- ============================================================================
-- 导出
-- ============================================================================

ADT.DockUI.PageBase = PageBase

return PageBase
