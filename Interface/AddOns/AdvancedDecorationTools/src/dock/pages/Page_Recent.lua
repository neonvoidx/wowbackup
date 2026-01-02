-- Page_Recent.lua
-- 最近放置页面（使用 PageBase 基类重构）

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local PageBase = ADT.DockUI.PageBase

-- ============================================================================
-- 创建页面实例（继承 PageBase）
-- ============================================================================

local PageRecent = PageBase:New("History", { categoryType = "decorList" })

--- 覆盖：渲染方法
function PageRecent:Render(mainFrame, categoryKey)
    local ok, ctx = self:PreRender(mainFrame, categoryKey)
    if not ok then return false end
    
    -- 设置分类状态
    self:SetCategoryState(ctx, "currentDecorCategory")
    
    -- 渲染标题
    self:RenderCategoryHeader(ctx)
    
    -- 渲染装饰列表
    self:RenderDecorList(ctx, {
        itemHeight = 36,
        itemGap = 2,
        templateKey = "DecorItem",
    })
    
    -- 提交
    self:CommitRender(ctx)
    
    return true
end

-- ============================================================================
-- 注册页面
-- ============================================================================

ADT.DockPages:Register("History", PageRecent)
ADT.DockPages.PageRecent = PageRecent
