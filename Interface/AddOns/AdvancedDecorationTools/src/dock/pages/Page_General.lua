-- Page_General.lua
-- 通用设置页面（使用 PageBase 基类重构）

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local PageBase = ADT.DockUI.PageBase
local L = ADT.L or {}

-- ============================================================================
-- 创建页面实例（继承 PageBase）
-- ============================================================================

local PageGeneral = PageBase:New("Housing", { categoryType = "settings" })

-- ============================================================================
-- 渲染方法
-- ============================================================================

function PageGeneral:Render(mainFrame, categoryKey)
    local ok, ctx = self:PreRender(mainFrame, categoryKey)
    if not ok then return false end
    
    -- 设置分类状态
    self:SetCategoryState(ctx, "currentSettingsCategory")
    
    -- 渲染标题
    self:RenderCategoryHeader(ctx)
    
    -- 渲染设置条目
    self:RenderSettingsEntries(ctx)
    
    -- 渲染语言下拉面板（使用基类统一方法）
    self:RenderDBDropdownPanel(ctx, "LanguagePanel", "SelectedLanguage", "Language", ADT.LanguageOptions or {}, {
        onSet = function(v)
            if ADT.UI and ADT.UI.PlaySoundCue then ADT.UI.PlaySoundCue('ui.checkbox.on') end
            
            -- 销毁所有缓存的 frame
            for _, page in pairs(ADT.DockPages._pages or {}) do
                if page and page.InvalidateCachedFrames then
                    page:InvalidateCachedFrames()
                end
            end
            
            local Main = ADT.CommandDock and ADT.CommandDock.SettingsPanel
            if Main and Main.UpdateAutoWidth then Main:UpdateAutoWidth() end
            if Main and Main.RefreshLanguageLayout then Main:RefreshLanguageLayout(true) end
            print("|cFF00FF00[ADT]|r " .. (L["Language Reload Hint"] or "Language changed, /reload to apply"))
        end
    })

    -- 渲染界面风格下拉面板
    self:RenderDBDropdownPanel(ctx, "InterfaceStylePanel", "InterfaceStyle", "Interface Style", ADT.InterfaceStyleOptions or {}, {
        onSet = function(v)
            if ADT.UI and ADT.UI.PlaySoundCue then ADT.UI.PlaySoundCue('ui.checkbox.on') end
            -- 界面风格切换由 Housing_InterfaceStyle.lua 监听并自动应用
        end
    })

    -- 说明：本页的所有“通用设置”开关均来自 DockCore 的模块清单；
    -- “启用 装饰信息面板”已按相同范式在 DockCore 注册为模块项，
    -- 此处不再重复渲染，以遵守单一权威与 DRY。
    
    -- 提交
    self:CommitRender(ctx)
    
    -- 设置首个模块数据
    mainFrame.firstModuleData = ctx.cat.modules and ctx.cat.modules[1] or nil
    
    return true
end

-- ============================================================================
-- 注册页面
-- ============================================================================

ADT.DockPages:Register("Housing", PageGeneral)
ADT.DockPages.PageGeneral = PageGeneral
