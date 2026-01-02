-- Housing_InterfaceStyle.lua
-- 界面风格控制器（最小侵入式实现）
-- 职责：管理现代/传统界面切换，协调 QuickbarUI、HoverInfoPanel、ModeBarRelocate

local ADDON_NAME, ADT = ...
if not ADT or not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local L = ADT.L or {}

--------------------------------------------------------------------------------
-- 模块
--------------------------------------------------------------------------------

local InterfaceStyle = {}
ADT.InterfaceStyle = InterfaceStyle

--------------------------------------------------------------------------------
-- 查询函数（单一权威）
--------------------------------------------------------------------------------

function InterfaceStyle:IsClassic()
    return ADT.GetDBValue and ADT.GetDBValue("InterfaceStyle") == "classic"
end

function InterfaceStyle:IsModern()
    return not self:IsClassic()
end

--------------------------------------------------------------------------------
-- 应用界面风格
--------------------------------------------------------------------------------

function InterfaceStyle:Apply()
    local isActive = C_HouseEditor and C_HouseEditor.IsHouseEditorActive and C_HouseEditor.IsHouseEditorActive()
    
    if ADT.DebugPrint then
        ADT.DebugPrint("[InterfaceStyle] Apply: isClassic=" .. tostring(self:IsClassic()) .. ", editorActive=" .. tostring(isActive))
    end
    
    if self:IsClassic() then
        -- 传统界面：隐藏部分现代 UI 组件（保留 Quickbar 走设置开关）
        if ADT.HoverInfoPanel then
            ADT.HoverInfoPanel:Hide()
        end
        if ADT.ModeBarRelocate then
            if isActive and ADT.QuickbarUI and ADT.ModeBarRelocate.ApplyClassicLayout then
                ADT.ModeBarRelocate:ApplyClassicLayout(ADT.QuickbarUI.uiFrame)
            elseif ADT.ModeBarRelocate.RestoreDefault then
                ADT.ModeBarRelocate:RestoreDefault()
            end
        end
    else
        -- 现代界面：恢复现代 UI 组件（仅在编辑器激活时）
        if isActive then
            if ADT.QuickbarUI and ADT.QuickbarUI.OnEditorEnter then
                ADT.QuickbarUI:OnEditorEnter()
            end
            if ADT.ModeBarRelocate and ADT.ModeBarRelocate.ApplyLayout then
                ADT.ModeBarRelocate:ApplyLayout()
            end
        end
    end
end

--------------------------------------------------------------------------------
-- 设置变更监听
--------------------------------------------------------------------------------

if ADT.Settings and ADT.Settings.On then
    local _lastStyle = nil -- 跟踪上次值，防止重载后重复弹窗
    
    ADT.Settings.On("InterfaceStyle", function(newValue)
        -- 初始化时记录值，不触发弹窗
        if _lastStyle == nil then
            _lastStyle = newValue
            return
        end
        
        -- 值没变，不处理
        if _lastStyle == newValue then
            return
        end
        
        if ADT.DebugPrint then
            ADT.DebugPrint("[InterfaceStyle] Setting changed: " .. tostring(_lastStyle) .. " -> " .. tostring(newValue))
        end
        
        _lastStyle = newValue
        
        if newValue == "classic" then
            -- 切换到传统界面：弹出确认对话框
            local L = ADT.L or {}
            local msg = L["Interface Style Reload Message"] or "Switching to Classic style requires a UI reload. Reload now?"
            
            StaticPopupDialogs["ADT_INTERFACE_STYLE_RELOAD"] = {
                text = msg,
                button1 = OKAY,
                button2 = CANCEL,
                OnAccept = function()
                    ReloadUI()
                end,
                OnCancel = function()
                    -- 取消：恢复为现代界面
                    _lastStyle = "modern"
                    ADT.SetDBValue("InterfaceStyle", "modern")
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = false,
                preferredIndex = 3,
            }
            StaticPopup_Show("ADT_INTERFACE_STYLE_RELOAD")
        else
            -- 切换到现代界面：立即应用
            C_Timer.After(0, function()
                InterfaceStyle:Apply()
            end)
        end
    end)
end

--------------------------------------------------------------------------------
-- 调试命令
--------------------------------------------------------------------------------

SLASH_ADTSTYLE1 = "/adtstyle"
SlashCmdList["ADTSTYLE"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "classic" then
        ADT.SetDBValue("InterfaceStyle", "classic")
        print("|cFF00FF00[ADT]|r Interface style set to: Classic")
    elseif msg == "modern" then
        ADT.SetDBValue("InterfaceStyle", "modern")
        print("|cFF00FF00[ADT]|r Interface style set to: Modern")
    else
        local current = ADT.GetDBValue("InterfaceStyle") or "modern"
        print("|cFF00FF00[ADT]|r Current interface style: " .. current)
        print("Usage: /adtstyle classic|modern")
    end
end

if ADT.DebugPrint then
    ADT.DebugPrint("[InterfaceStyle] Module loaded")
end
