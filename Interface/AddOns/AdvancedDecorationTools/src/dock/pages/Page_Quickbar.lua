-- Page_Quickbar.lua
-- 快捷栏设置页面（使用 PageBase 基类重构）

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local PageBase = ADT.DockUI.PageBase

-- ============================================================================
-- 创建页面实例（继承 PageBase）
-- ============================================================================

local PageQuickbar = PageBase:New("Quickbar", { categoryType = "settings" })

--- 覆盖：设置分类状态
function PageQuickbar:Render(mainFrame, categoryKey)
    local ok, ctx = self:PreRender(mainFrame, categoryKey)
    if not ok then return false end
    
    -- 设置分类状态
    self:SetCategoryState(ctx, "currentSettingsCategory")
    
    -- 渲染标题
    self:RenderCategoryHeader(ctx)
    
    -- 渲染设置条目
    self:RenderSettingsEntries(ctx)
    
    -- 提交
    self:CommitRender(ctx)
    
    -- 设置首个模块数据
    mainFrame.firstModuleData = ctx.cat.modules and ctx.cat.modules[1] or nil
    
    return true
end

-- ============================================================================
-- 注册页面
-- ============================================================================

ADT.DockPages:Register("Quickbar", PageQuickbar)
ADT.DockPages.PageQuickbar = PageQuickbar
