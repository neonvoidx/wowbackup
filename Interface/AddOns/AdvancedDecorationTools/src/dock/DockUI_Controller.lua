-- DockUI_Controller.lua
-- Controller 层：事件监听、用户交互响应、分类切换、数据变化刷新
-- 从 DockUI.lua 拆分，遵循 MVC 架构

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local CommandDock = ADT.CommandDock
local UI = ADT.DockUI

-- ============================================================================
-- 暴雪按钮采纳事件监听（从 DockUI.lua 迁移）
-- ============================================================================

local function _IsExpertMode()
    local HEM = C_HouseEditor and C_HouseEditor.GetActiveHouseEditorMode and C_HouseEditor.GetActiveHouseEditorMode()
    return HEM == (Enum and Enum.HouseEditorMode and Enum.HouseEditorMode.ExpertDecor)
end

local function SetupPlacedListButtonWatcher()
    local EL = CreateFrame("Frame")
    EL:RegisterEvent("HOUSE_EDITOR_MODE_CHANGED")
    EL:RegisterEvent("ADDON_LOADED")
    EL:RegisterEvent("PLAYER_LOGIN")
    EL:SetScript("OnEvent", function(_, event, arg1)
        if event == "ADDON_LOADED" and arg1 == "Blizzard_HouseEditor" then
            if UI.AttachPlacedListButton then UI.AttachPlacedListButton() end
        elseif event == "PLAYER_LOGIN" then
            if UI.AttachPlacedListButton then UI.AttachPlacedListButton() end
        elseif event == "HOUSE_EDITOR_MODE_CHANGED" then
            if C_HouseEditor and C_HouseEditor.IsHouseEditorActive and C_HouseEditor.IsHouseEditorActive() and _IsExpertMode() then
                if UI.AttachPlacedListButton then UI.AttachPlacedListButton() end
            else
                if UI.RestorePlacedListButton then UI.RestorePlacedListButton() end
            end
        end
    end)
end

-- 立即设置暴雪按钮监听（不需要等待 MainFrame）
SetupPlacedListButtonWatcher()

-- ============================================================================
-- 分类切换事件（通过 EventBus 监听）
-- ============================================================================

-- 设置 EventBus 事件监听
local function SetupEventBusListeners()
    if not ADT.EventBus then return end
    
    -- 监听分类选择事件
    ADT.EventBus:OnCategorySelected(function(categoryKey, categoryType)
        local MainFrame = ADT.CommandDock and ADT.CommandDock.SettingsPanel
        if not MainFrame then return end
        
        ADT.DebugPrint(string.format("[Controller] EventBus: CATEGORY_SELECTED key=%s type=%s", 
            tostring(categoryKey), tostring(categoryType)))
        
        -- 使用 PageRouter 进行页面路由（单一权威；去除 View 直呼回退）
        if ADT.PageRouter then
            ADT.PageRouter:Route(categoryKey, categoryType)
        end
        
        -- 高亮当前分类
        if MainFrame.HighlightCategoryByKey then
            MainFrame:HighlightCategoryByKey(categoryKey)
        end
        
        -- 记录最后选中的分类
        if ADT.SetDBValue then
            ADT.SetDBValue('LastCategoryKey', categoryKey)
        end
        
        -- 播放切换音效
        if ADT.UI and ADT.UI.PlaySoundCue then
            ADT.UI.PlaySoundCue('ui.tab.switch')
        end
    end)
    
    if ADT.DebugPrint then
        ADT.DebugPrint("[Controller] EventBus listeners registered")
    end
end

-- 兼容旧调用：保留 UI.OnCategorySelected（逐步废弃）
-- 分类选择回调（由 LeftPanel.OnClick 触发）
function UI.OnCategorySelected(categoryKey, categoryType)
    -- 兼容旧调用：统一委派到 EventBus；不再内联处理逻辑
    if ADT.EventBus then
        ADT.EventBus:Fire(ADT.EventBus.Events.CATEGORY_SELECTED, categoryKey, categoryType)
    end
end

-- ============================================================================
-- OnShow 分类恢复逻辑（从 DockUI.lua 迁移）
-- ============================================================================

local function SetupOnShowHandler()
    local MainFrame = ADT.CommandDock and ADT.CommandDock.SettingsPanel
    if not MainFrame or not MainFrame.ModuleTab then return end
    
    local Tab1 = MainFrame.ModuleTab
    
    Tab1:SetScript("OnShow", function()
        if MainFrame.ApplyDockPlacement then MainFrame:ApplyDockPlacement() end
        
        -- KISS：优先使用“当前内存中的已选分类”；若无，统一回退到 DockUI 的单一权威默认分类
        local defaultKey = (ADT and ADT.DockUI and ADT.DockUI.GetDefaultCategoryKey and ADT.DockUI.GetDefaultCategoryKey()) or 'Housing'
        local key = MainFrame.currentDecorCategory
            or MainFrame.currentDyePresetsCategory
            or MainFrame.currentAboutCategory
            or MainFrame.currentSettingsCategory
            or defaultKey
        
        -- 首次无记录时，可选地将默认分类写入持久化（不改变“默认显示 General”的行为）
        if (ADT and ADT.GetDBValue and not ADT.GetDBValue('LastCategoryKey')) then
            if ADT and ADT.SetDBValue then ADT.SetDBValue('LastCategoryKey', defaultKey) end
        end
        
        -- 显式首选默认分类作为回退；若无则再选第一个设置类
        if not key then
            local housing = CommandDock:GetCategoryByKey(defaultKey)
            if housing and housing.categoryType == 'settings' then
                key = defaultKey
            end
        end
        
        if ADT and ADT.DebugPrint then
            local cw = MainFrame.CentralSection and MainFrame.CentralSection:GetWidth() or 0
            local ch = MainFrame.CentralSection and MainFrame.CentralSection:GetHeight() or 0
            ADT.DebugPrint(string.format("[Controller] OnShow: key=%s, center=%.1fx%.1f", tostring(key), cw, ch))
        end
        
        -- 顶部标签系统（如启用）
        local USE_TOP_TABS = MainFrame.USE_TOP_TABS or false
        if USE_TOP_TABS and MainFrame.TopTabOwner and MainFrame.__tabIDFromKey then
            local id = MainFrame.__tabIDFromKey[key] or MainFrame.__tabIDFromKey[defaultKey] or 1
            MainFrame.TopTabOwner:SetTab(id)
            return
        end

        -- 使用 PageRouter 统一路由。若 key 无效，则回退到 Housing 或首个设置类。
        local cat = key and CommandDock:GetCategoryByKey(key) or nil
        if (not cat) and CommandDock and CommandDock.GetSortedModules then
            -- 寻找回退目标
            local all = CommandDock:GetSortedModules() or {}
            local firstSettings
            for _, info in ipairs(all) do
                if info.key == defaultKey and info.categoryType ~= 'decorList' and info.categoryType ~= 'about' then
                    firstSettings = defaultKey; break
                end
            end
            if not firstSettings then
                for _, info in ipairs(all) do
                    if info.categoryType ~= 'decorList' and info.categoryType ~= 'about' then
                        firstSettings = info.key; break
                    end
                end
            end
            key = firstSettings or defaultKey
            cat = CommandDock:GetCategoryByKey(key) or { categoryType = 'settings' }
        end
        if ADT.PageRouter then
            ADT.PageRouter:Route(key, cat and cat.categoryType or 'settings')
        end
        if MainFrame.HighlightCategoryByKey then
            MainFrame:HighlightCategoryByKey(key)
        end
        
        if MainFrame.UpdateAutoWidth then MainFrame:UpdateAutoWidth() end
        
        -- 静态左窗跟随定位
        if (ADT.DockLeft and ADT.DockLeft.IsStatic and ADT.DockLeft.IsStatic()) 
           and MainFrame.UpdateStaticLeftPlacement then
            C_Timer.After(0, function()
                if MainFrame:IsShown() then
                    MainFrame:UpdateStaticLeftPlacement()
                end
            end)
        end
    end)
end

-- ============================================================================
-- AnchorWatcher：分辨率/缩放变化事件（从 DockUI.lua 迁移）
-- ============================================================================

local function SetupAnchorWatcher()
    local MainFrame = ADT.CommandDock and ADT.CommandDock.SettingsPanel
    if not MainFrame then return end
    
    local AnchorWatcher = CreateFrame("Frame", nil, MainFrame)
    AnchorWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
    AnchorWatcher:RegisterEvent("UI_SCALE_CHANGED")
    AnchorWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    AnchorWatcher:RegisterEvent("HOUSE_EDITOR_MODE_CHANGED")
    AnchorWatcher:SetScript("OnEvent", function()
        C_Timer.After(0, function()
            if MainFrame and MainFrame.ApplyDockPlacement then
                MainFrame:ApplyDockPlacement()
            end
            if MainFrame and MainFrame.UpdateAutoWidth then
                MainFrame:UpdateAutoWidth()
            end
        end)
    end)
end

-- ============================================================================
-- 数据变化回调（Clipboard/History）（从 DockUI.lua 迁移）
-- ============================================================================

local _clipboardCallbackHooked = false
local _historyCallbackHooked = false

local function SetupDataChangeCallbacks()
    local MainFrame = ADT.CommandDock and ADT.CommandDock.SettingsPanel
    if not MainFrame then return end
    
    -- Clipboard 数据变化时刷新
    if ADT.Clipboard and not _clipboardCallbackHooked then
        local origOnChanged = ADT.Clipboard.OnChanged
        ADT.Clipboard.OnChanged = function(self)
            if origOnChanged then origOnChanged(self) end
            -- 如果当前显示的是临时板分类，则刷新列表
            if MainFrame:IsShown() and MainFrame.currentDecorCategory == 'Clipboard' then
                MainFrame:ShowDecorListCategory('Clipboard')
            end
            -- 刷新分类列表的数量角标
            MainFrame:RefreshCategoryList()
        end
        _clipboardCallbackHooked = true
    end

    -- History 数据变化时刷新
    if ADT.History and not _historyCallbackHooked then
        local origOnHistoryChanged = ADT.History.OnHistoryChanged
        ADT.History.OnHistoryChanged = function(self)
            if origOnHistoryChanged then origOnHistoryChanged(self) end
            -- 如果当前显示的是最近放置分类，则刷新列表
            if MainFrame:IsShown() and MainFrame.currentDecorCategory == 'History' then
                MainFrame:ShowDecorListCategory('History')
            end
            -- 刷新分类列表的数量角标
            MainFrame:RefreshCategoryList()
        end
        _historyCallbackHooked = true
    end

    -- 延迟重试：等待 Housing 模块加载后再绑定
    if (not _clipboardCallbackHooked) or (not _historyCallbackHooked) then
        C_Timer.After(0.1, SetupDataChangeCallbacks)
    end
end

-- ============================================================================
-- 设置订阅（从 DockUI.lua 迁移）
-- ============================================================================

local function SetupSettingsSubscriptions()
    -- 订阅"进入编辑器自动打开 Dock"设置，实时应用默认显隐
    if ADT and ADT.Settings and ADT.Settings.On then
        ADT.Settings.On('EnableDockAutoOpenInEditor', function()
            if ADT and ADT.DockUI and ADT.DockUI.ApplyPanelsDefaultVisibility then
                ADT.DockUI.ApplyPanelsDefaultVisibility()
            end
        end)
    end
end

-- ============================================================================
-- ESC 关闭逻辑（从 DockUI.lua 迁移）
-- ============================================================================

local function SetupEscapeHandler()
    local MainFrame = ADT.CommandDock and ADT.CommandDock.SettingsPanel
    if not MainFrame then return end
    
    -- HandleEscape is defined in DockUI.lua (View layer)
    
    -- ESC 关闭功能（按 ESC 关闭面板）
    local CloseDummy = CreateFrame("Frame", "ADTSettingsPanelSpecialFrame", UIParent)
    CloseDummy:Hide()
    table.insert(UISpecialFrames, CloseDummy:GetName())

    CloseDummy:SetScript("OnHide", function()
        if MainFrame:HandleEscape() then
            CloseDummy:Show()
        end
    end)

    MainFrame:HookScript("OnShow", function()
        if MainFrame.mode == "standalone" then
            CloseDummy:Show()
        end
    end)

    MainFrame:HookScript("OnHide", function()
        CloseDummy:Hide()
    end)
end

-- ============================================================================
-- EditorWatcher：编辑模式自动打开/关闭（从 DockUI.lua 迁移）
-- ============================================================================

local function SetupEditorWatcher()
    local MainFrame = ADT.CommandDock and ADT.CommandDock.SettingsPanel
    if not MainFrame then return end
    
    local EditorWatcher = CreateFrame("Frame")
    local wasEditorActive = false
    
    local function HideDockUI()
        if not MainFrame then return end
        local function AfterHide()
            MainFrame:SetParent(UIParent)
            MainFrame:SetFrameStrata("FULLSCREEN_DIALOG")
            MainFrame:SetAlpha(1)
        end
        if ADT.HousingTransition and ADT.HousingTransition.PlayExit then
            ADT.HousingTransition:PlayExit(MainFrame, "DockUI", { onHidden = AfterHide })
        else
            AfterHide()
            MainFrame:Hide()
        end
    end

    local function UpdateEditorState()
        local isActive = C_HouseEditor and C_HouseEditor.IsHouseEditorActive and C_HouseEditor.IsHouseEditorActive()
        
        if isActive then
            -- 先切换 Parent，避免先显示在 UIParent 再切到编辑器导致闪烁
            if HouseEditorFrame then
                MainFrame:SetParent(HouseEditorFrame)
                MainFrame:SetFrameStrata("FULLSCREEN_DIALOG")
            end

            if not wasEditorActive then
                -- 进入编辑模式
                -- 1. ShowUI 负责初始化并触发入场动画（编辑模式）
                MainFrame:ShowUI("editor")
                
                -- 2. 若默认开启，则聚焦到"通用"分类
                local v = ADT and ADT.GetDBValue and ADT.GetDBValue('EnableDockAutoOpenInEditor')
                local shouldAutoOpen = (v ~= false)
                if shouldAutoOpen then
                    C_Timer.After(0, function()
                        local defaultKey = (ADT and ADT.DockUI and ADT.DockUI.GetDefaultCategoryKey and ADT.DockUI.GetDefaultCategoryKey()) or 'Housing'
                        local key = defaultKey
                        local cat = CommandDock and CommandDock.GetCategoryByKey and CommandDock:GetCategoryByKey(key)
                        if (not cat) and CommandDock and CommandDock.GetSortedModules then
                            local all = CommandDock:GetSortedModules() or {}
                            for _, info in ipairs(all) do
                                if info.categoryType ~= 'decorList' and info.categoryType ~= 'about' then
                                    key = info.key; break
                                end
                            end
                            cat = CommandDock and CommandDock.GetCategoryByKey and CommandDock:GetCategoryByKey(key)
                        end
                        if cat and ADT.PageRouter then
                            ADT.PageRouter:Route(key, cat.categoryType)
                        end
                    end)
                end
                
                -- 3. 应用默认显隐
                C_Timer.After(0, function()
                    if ADT and ADT.DockUI and ADT.DockUI.ApplyPanelsDefaultVisibility then
                        ADT.DockUI.ApplyPanelsDefaultVisibility()
                    end
                end)
                
                -- 入场动画统一交给 Housing_Transition（单一权威）
            end
            
        else
            -- 退出编辑模式：统一走过渡动画管理器
            HideDockUI()
        end
        
        wasEditorActive = isActive
    end
    
    EditorWatcher:RegisterEvent("HOUSE_EDITOR_MODE_CHANGED")
    EditorWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    EditorWatcher:SetScript("OnEvent", function(_, event)
        if event == "HOUSE_EDITOR_MODE_CHANGED" then
            local isActive = C_HouseEditor and C_HouseEditor.IsHouseEditorActive and C_HouseEditor.IsHouseEditorActive()
            if not isActive then
                UpdateEditorState()
                return
            end
        end
        -- 进入或其它情况：短延迟以确保编辑器框架已就位
        C_Timer.After(0.05, UpdateEditorState)
    end)
end

-- ShowUI is defined in DockUI.lua (View layer)

-- ============================================================================
-- Controller 初始化入口
-- ============================================================================

local function InitController()
    local MainFrame = ADT.CommandDock and ADT.CommandDock.SettingsPanel
    if not MainFrame then
        -- 延迟初始化，等待 View 创建完成
        C_Timer.After(0.1, InitController)
        return
    end
    
    -- 如果已初始化则跳过
    if MainFrame._ControllerInitialized then return end
    MainFrame._ControllerInitialized = true
    
    -- 首先设置 EventBus 事件监听（解耦架构的核心）
    SetupEventBusListeners()
    
    -- 按顺序设置各个 Controller 组件
    SetupSettingsSubscriptions()
    SetupEscapeHandler()
    SetupEditorWatcher()
    
    if ADT.DebugPrint then
        ADT.DebugPrint("[Controller] DockUI Controller initialized")
    end
end

-- 在 CreateUI 完成后设置 OnShow/AnchorWatcher/DataCallbacks
-- 这些需要在 UI 创建完成后才能设置
function UI.InitControllerPostCreate()
    local MainFrame = ADT.CommandDock and ADT.CommandDock.SettingsPanel
    if not MainFrame then return end
    
    SetupOnShowHandler()
    SetupAnchorWatcher()
    SetupDataChangeCallbacks()
    
    if ADT.DebugPrint then
        ADT.DebugPrint("[Controller] Post-create handlers initialized")
    end
end

-- 启动初始化
InitController()
