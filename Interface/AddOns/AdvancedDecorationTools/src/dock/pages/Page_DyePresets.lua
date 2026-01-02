-- Page_DyePresets.lua
-- 染色预设页面渲染器（使用 PageBase 基类重构）

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local PageBase = ADT.DockUI.PageBase
local Def = ADT.DockUI.Def

-- ============================================================================
-- 创建页面实例（继承 PageBase）
-- ============================================================================

local PageDyePresets = PageBase:New("DyePresets", { categoryType = "dyePresetList" })

--- 覆盖：渲染方法
function PageDyePresets:Render(mainFrame, categoryKey)
    local ok, ctx = self:PreRender(mainFrame, categoryKey)
    if not ok then return false end
    
    -- 验证分类类型
    if ctx.cat.categoryType ~= 'dyePresetList' then return false end
    
    -- 设置分类状态
    self:SetCategoryState(ctx, "currentDyePresetsCategory")
    
    -- 渲染标题
    self:RenderCategoryHeader(ctx)
    
    -- 保存按钮
    local saveBtnH = 28
    self:AddContentItem(ctx, {
        templateKey = "CenterButton",
        setupFunc = function(btn)
            local btnText = ADT.L["Save Current Dye"] or "保存当前染色"
            if btn.SetText then btn:SetText(btnText) end
            btn:Enable()
            btn:SetScript("OnClick", function()
                local hasClipboard = ADT.DyeClipboard and ADT.DyeClipboard._savedColors and #ADT.DyeClipboard._savedColors > 0
                if not hasClipboard then
                    if ADT.Notify then ADT.Notify(ADT.L["No dye copied"] or "未复制任何染色", "error") end
                    return
                end
                if ctx.cat.onSaveClick then
                    ctx.cat.onSaveClick()
                    C_Timer.After(0.05, function()
                        local mf = ADT.DockUI.GetMainFrame()
                        if mf then mf:ShowDyePresetsCategory(categoryKey) end
                    end)
                end
            end)
        end,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        top = ctx.offsetY,
        bottom = ctx.offsetY + saveBtnH,
        offsetX = ctx.offsetX,
    })
    self:AdvanceOffset(ctx, saveBtnH + 8)
    
    -- 渲染预设列表
    local list = ctx.cat.getListData and ctx.cat.getListData() or {}
    
    if #list == 0 then
        local emptyText = ctx.cat.emptyText or ADT.L["No dye presets"] or "暂无染色预设"
        self:RenderHeader(ctx, emptyText:match("^([^\n]*)") or emptyText, {
            showDivider = false,
            color = Def.TextColorDisabled,
            offsetX = ctx.offsetX,
        })
    else
        local itemHeight = 32
        local itemGap = 2
        for i, preset in ipairs(list) do
            local top = ctx.offsetY
            local bottom = top + itemHeight + itemGap
            local capIndex, capCat, capPreset = i, ctx.cat, preset
            
            self:AddContentItem(ctx, {
                templateKey = "DyePresetItem",
                setupFunc = function(obj)
                    obj:SetPresetData(capIndex, capPreset, capCat)
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
    
    -- 提交
    self:CommitRender(ctx)
    
    return true
end

-- ============================================================================
-- 注册页面
-- ============================================================================

-- 同时注册 categoryKey 和 categoryType，确保路由能找到页面
ADT.DockPages:Register("DyePresets", PageDyePresets)
ADT.DockPages:Register("dyePresetList", PageDyePresets)
ADT.DockPages.PageDyePresets = PageDyePresets

