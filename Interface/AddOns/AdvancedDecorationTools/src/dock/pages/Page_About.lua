-- Page_About.lua
-- 关于页面渲染器（使用 PageBase 基类重构）

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local PageBase = ADT.DockUI.PageBase
local Def = ADT.DockUI.Def
local GetRightPadding = ADT.DockUI.GetRightPadding

-- ============================================================================
-- 创建页面实例（继承 PageBase）
-- ============================================================================

local PageAbout = PageBase:New("About", { categoryType = "about" })

--- 覆盖：渲染方法
function PageAbout:Render(mainFrame, categoryKey)
    local ok, ctx = self:PreRender(mainFrame, categoryKey)
    if not ok then return false end
    
    -- 验证分类类型
    if ctx.cat.categoryType ~= 'about' then return false end
    
    -- 设置分类状态
    self:SetCategoryState(ctx, "currentAboutCategory")
    
    -- 渲染标题
    self:RenderCategoryHeader(ctx)
    self:AdvanceOffset(ctx, Def.ButtonSize) -- 额外间距
    
    -- 渲染信息文本
    if ctx.cat.getInfoText then
        local infoText = ctx.cat.getInfoText()
        for line in infoText:gmatch("[^\n]+") do
            self:RenderHeader(ctx, line, {
                showDivider = false,
                offsetX = GetRightPadding() + (Def.AboutTextExtraLeft or 0),
            })
        end
    end
    
    -- 提交
    self:CommitRender(ctx)
    
    return true
end

-- ============================================================================
-- 注册页面
-- ============================================================================

-- 同时注册 categoryKey 和 categoryType，确保路由能找到页面
ADT.DockPages:Register("About", PageAbout)
ADT.DockPages:Register("about", PageAbout)
ADT.DockPages.PageAbout = PageAbout

