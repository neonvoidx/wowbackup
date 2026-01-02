-- Page_Clipboard.lua
-- 临时板页面（使用 PageBase 基类重构）

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local PageBase = ADT.DockUI.PageBase
local Def = ADT.DockUI.Def

-- ============================================================================
-- 创建页面实例（继承 PageBase）
-- ============================================================================

local PageClipboard = PageBase:New("Clipboard", { categoryType = "decorList" })

--- 覆盖：渲染方法
function PageClipboard:Render(mainFrame, categoryKey)
    local ok, ctx = self:PreRender(mainFrame, categoryKey)
    if not ok then return false end
    
    -- 设置分类状态
    self:SetCategoryState(ctx, "currentDecorCategory")
    
    -- 渲染标题
    self:RenderCategoryHeader(ctx)

    -- 导入/导出按钮区
    self:AdvanceOffset(ctx, 4)
    self:RenderHeader(ctx, ADT.L["Clipboard Import/Export"], {
        showDivider = false,
        color = Def.TextColorHighlight or {1, 0.82, 0},
    })

    local btnH = 26
    local gap = 6

    self:AddContentItem(ctx, {
        templateKey = "CenterButton",
        setupFunc = function(btn)
            if btn.SetText then btn:SetText(ADT.L["Export Placed Decor"]) end
            btn:SetScript("OnClick", function()
                if ADT.ExportImport and ADT.ExportImport.ShowExportDialog then
                    ADT.ExportImport:ShowExportDialog("placed")
                else
                    if ADT.Notify then ADT.Notify(ADT.L["Export module not loaded"], "error") end
                end
            end)
        end,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        top = ctx.offsetY,
        bottom = ctx.offsetY + btnH,
        offsetX = ctx.offsetX,
    })
    self:AdvanceOffset(ctx, btnH + gap)

    self:AddContentItem(ctx, {
        templateKey = "CenterButton",
        setupFunc = function(btn)
            if btn.SetText then btn:SetText(ADT.L["Export Clipboard"]) end
            btn:SetScript("OnClick", function()
                if ADT.ExportImport and ADT.ExportImport.ShowExportDialog then
                    ADT.ExportImport:ShowExportDialog("clipboard")
                else
                    if ADT.Notify then ADT.Notify(ADT.L["Export module not loaded"], "error") end
                end
            end)
        end,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        top = ctx.offsetY,
        bottom = ctx.offsetY + btnH,
        offsetX = ctx.offsetX,
    })
    self:AdvanceOffset(ctx, btnH + gap)

    self:AddContentItem(ctx, {
        templateKey = "CenterButton",
        setupFunc = function(btn)
            if btn.SetText then btn:SetText(ADT.L["Import To Clipboard"]) end
            btn:SetScript("OnClick", function()
                if ADT.ExportImport and ADT.ExportImport.ShowImportDialog then
                    ADT.ExportImport:ShowImportDialog()
                else
                    if ADT.Notify then ADT.Notify(ADT.L["Import module not loaded"], "error") end
                end
            end)
        end,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        top = ctx.offsetY,
        bottom = ctx.offsetY + btnH,
        offsetX = ctx.offsetX,
    })
    self:AdvanceOffset(ctx, btnH + gap)

    self:AddContentItem(ctx, {
        templateKey = "CenterButton",
        setupFunc = function(btn)
            if btn.SetText then btn:SetText(ADT.L["Clear Clipboard"]) end
            btn:SetScript("OnClick", function()
                if ADT.Clipboard and ADT.Clipboard.ClearWithConfirm then
                    ADT.Clipboard:ClearWithConfirm()
                elseif ADT.Clipboard and ADT.Clipboard.Clear then
                    ADT.Clipboard:Clear()
                else
                    if ADT.Notify then ADT.Notify(ADT.L["Clipboard not available"], "error") end
                end
            end)
        end,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        top = ctx.offsetY,
        bottom = ctx.offsetY + btnH,
        offsetX = ctx.offsetX,
    })
    self:AdvanceOffset(ctx, btnH + 8)
    
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

ADT.DockPages:Register("Clipboard", PageClipboard)
ADT.DockPages.PageClipboard = PageClipboard
