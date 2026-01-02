-- Page_Keybinds.lua
-- 快捷键页面渲染器（使用 PageBase 基类重构）

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local PageBase = ADT.DockUI.PageBase
local Def = ADT.DockUI.Def
local GetRightPadding = ADT.DockUI.GetRightPadding

-- ============================================================================
-- 创建页面实例（继承 PageBase）
-- ============================================================================

local PageKeybinds = PageBase:New("Keybinds", { categoryType = "keybinds" })

--- 覆盖：渲染方法
function PageKeybinds:Render(mainFrame, categoryKey)
    if ADT.DebugPrint then
        ADT.DebugPrint("[PageKeybinds] Render called with key=" .. tostring(categoryKey))
    end
    
    local ok, ctx = self:PreRender(mainFrame, categoryKey)
    if not ok then return false end
    
    -- 验证分类类型
    if ctx.cat.categoryType ~= 'keybinds' then return false end
    
    -- 设置分类状态
    self:SetCategoryState(ctx, "currentKeybindsCategory")
    
    -- 渲染标题（带提示文本）
    self:AddContentItem(ctx, {
        templateKey = "Header",
        setupFunc = function(obj)
            obj:SetText(ctx.cat.categoryName)
            if obj.Left then obj.Left:Hide() end
            if obj.Right then obj.Right:Hide() end
            if obj.Divider then obj.Divider:Show() end
            obj.Label:SetJustifyH("LEFT")
            
            -- 创建提示文本
            if not obj._keybindHint then
                local KCFG = (ADT.HousingInstrCFG and ADT.HousingInstrCFG.KeybindUI) or {}
                local hintOffsetX = KCFG.headerHintOffsetX or -8
                local hintOffsetY = KCFG.headerHintOffsetY or 0
                local hint = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                hint:SetDrawLayer("OVERLAY", 7)
                hint:SetPoint("RIGHT", obj, "RIGHT", hintOffsetX, hintOffsetY)
                hint:SetJustifyH("RIGHT")
                hint:SetTextColor(0.6, 0.8, 1, 1)
                
                if not obj._adt_hintHooked then
                    obj:HookScript("OnHide", function() if hint then hint:Hide() end end)
                    obj:HookScript("OnShow", function() if hint then hint:Show() end end)
                    obj._adt_hintHooked = true
                end
                obj._keybindHint = hint
            end
            obj._keybindHint:SetText("")
            obj._keybindHint:Show()
            mainFrame._keybindCategoryHint = obj._keybindHint
        end,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        top = ctx.offsetY,
        bottom = ctx.offsetY + Def.ButtonSize,
        offsetX = GetRightPadding(),
    })
    self:AdvanceOffset(ctx, Def.ButtonSize)
    
    -- 获取快捷键动作
    local actions = ADT.Keybinds and ADT.Keybinds.GetAllActions and ADT.Keybinds:GetAllActions() or {}
    
    if #actions == 0 then
        self:RenderHeader(ctx, ADT.L["Keybinds Module Not Loaded"], {
            showDivider = false,
            color = Def.TextColorDisabled,
        })
    else
        -- 渲染快捷键条目
        for _, actionInfo in ipairs(actions) do
            local top = ctx.offsetY
            local bottom = top + ctx.buttonHeight + 2
            local capAction = actionInfo
            
            self:AddContentItem(ctx, {
                templateKey = "KeybindEntry",
                setupFunc = function(obj)
                    obj:SetKeybindByActionName(capAction.name)
                end,
                point = "TOPLEFT",
                relativePoint = "TOPLEFT",
                top = top,
                bottom = bottom,
                offsetX = ctx.offsetX,
            })
            ctx.offsetY = bottom
        end
        
        -- 底部提示
        self:AdvanceOffset(ctx, Def.ButtonSize)
        self:RenderHeader(ctx, ADT.L["Keybinds Housing Only Hint"], {
            showDivider = false,
            color = Def.TextColorWarn or {1, 0.82, 0},
        })
        
        -- 恢复默认按钮
        self:AdvanceOffset(ctx, 8)
        local resetBtnH = 24
        self:AddContentItem(ctx, {
            templateKey = "CenterButton",
            setupFunc = function(btn)
                if btn.SetText then btn:SetText(ADT.L["Reset All Keybinds"]) end
                btn:SetScript("OnClick", function()
                    if ADT.Keybinds and ADT.Keybinds.ResetAllToDefaults then
                        ADT.Keybinds:ResetAllToDefaults()
                        if ADT.Notify then ADT.Notify(ADT.L["Keybinds Reset Done"]) end
                        local mf = ADT.DockUI.GetMainFrame()
                        if mf then mf:ShowKeybindsCategory(categoryKey) end
                    end
                end)
            end,
            point = "TOPLEFT",
            relativePoint = "TOPLEFT",
            top = ctx.offsetY,
            bottom = ctx.offsetY + resetBtnH,
            offsetX = ctx.offsetX,
        })
    end
    
    -- 提交
    self:CommitRender(ctx)
    
    return true
end

-- ============================================================================
-- 注册页面
-- ============================================================================

-- 同时注册 categoryKey 和 categoryType，确保路由能找到页面
ADT.DockPages:Register("Keybinds", PageKeybinds)
ADT.DockPages:Register("keybinds", PageKeybinds)
ADT.DockPages.PageKeybinds = PageKeybinds

