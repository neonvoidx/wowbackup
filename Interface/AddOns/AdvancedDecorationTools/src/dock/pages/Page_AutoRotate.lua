-- Page_AutoRotate.lua
-- 高级旋转页面（使用 PageBase 基类重构）

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local PageBase = ADT.DockUI.PageBase
local Def = ADT.DockUI.Def
local L = ADT.L or {}

-- ============================================================================
-- 创建页面实例（继承 PageBase）
-- ============================================================================

local PageAutoRotate = PageBase:New("AutoRotate", { categoryType = "settings" })

-- 下拉选项
local INCREMENT_DEGREES_OPTIONS = {
    { value = 5, text = "5°" },
    { value = 15, text = "15°" },
    { value = 30, text = "30°" },
    { value = 45, text = "45°" },
    { value = 90, text = "90°" },
    { value = -1, text = function() return L["Custom..."] or "自定义..." end, action = 'button', onClick = function()
        if ADT.IncrementRotate and ADT.IncrementRotate.OpenCustomAngleDialog then
            ADT.IncrementRotate.OpenCustomAngleDialog()
        end
    end },
}

local PULSE_DEGREES_OPTIONS = {
    { value = 5, text = "5°" },
    { value = 15, text = "15°" },
    { value = 45, text = "45°" },
    { value = 90, text = "90°" },
}

--- 覆盖：渲染方法
function PageAutoRotate:Render(mainFrame, categoryKey)
    local ok, ctx = self:PreRender(mainFrame, categoryKey)
    if not ok then return false end
    
    -- 设置分类状态
    self:SetCategoryState(ctx, "currentSettingsCategory")
    
    -- 渲染标题
    self:RenderCategoryHeader(ctx)
    
    -- 渲染设置条目
    self:RenderSettingsEntries(ctx)
    
    -- 递增角度下拉（使用基类统一方法）
    self:RenderDBDropdownPanel(ctx, "IncrementDegreesPanel", "IncrementRotateDegrees", "Increment Angle", INCREMENT_DEGREES_OPTIONS, {
        onSet = function(v)
            if ADT.UI and ADT.UI.PlaySoundCue then ADT.UI.PlaySoundCue('ui.checkbox.on') end
            if ADT.IncrementRotate and ADT.IncrementRotate.LoadSettings then ADT.IncrementRotate:LoadSettings() end
        end
    })
    
    -- 脉冲角度下拉（使用正确的本地化键）
    self:RenderDBDropdownPanel(ctx, "PulseDegreesPanel", "PulseRotateDegrees", "Expert Pulse Degrees", PULSE_DEGREES_OPTIONS, {
        onSet = function(v)
            if ADT.UI and ADT.UI.PlaySoundCue then ADT.UI.PlaySoundCue('ui.checkbox.on') end
        end
    })
    
    -- 误差说明文字
    local disclaimerKey = "DisclaimerText"
    local disclaimerHeight = 48
    local sv = mainFrame.ModuleTab.ScrollView
    local panelWidth = (mainFrame.centerButtonWidth or 300) - ctx.offsetX * 2
    
    if sv and sv._templates and not sv._templates[disclaimerKey] then
        sv:AddTemplate(disclaimerKey, function()
            local frame = CreateFrame("Frame", nil, sv)
            frame:SetSize(panelWidth, disclaimerHeight)
            local text = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            text:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            text:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            text:SetJustifyH("LEFT")
            text:SetWordWrap(true)
            frame.text = text
            return frame
        end)
    end
    
    self:AddContentItem(ctx, {
        templateKey = disclaimerKey,
        setupFunc = function(obj)
            if obj.text then
                obj.text:SetText(L["Rotation Accuracy Disclaimer"] or "")
            end
        end,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        top = ctx.offsetY,
        bottom = ctx.offsetY + disclaimerHeight,
        offsetX = ctx.offsetX,
    })
    
    -- 提交
    self:CommitRender(ctx)
    
    -- 设置首个模块数据
    mainFrame.firstModuleData = ctx.cat.modules and ctx.cat.modules[1] or nil
    
    return true
end

-- ============================================================================
-- 注册页面
-- ============================================================================

ADT.DockPages:Register("AutoRotate", PageAutoRotate)
ADT.DockPages.PageAutoRotate = PageAutoRotate
