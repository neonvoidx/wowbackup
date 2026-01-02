-- DockUI_Collapse.lua
-- DockUI 折叠/展开与面板显隐逻辑

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local GetDBBool = ADT.GetDBBool

-- ============================================================================
-- 工具函数
-- ============================================================================

local function SetShownSafe(f, shown)
    if not f then return end
    if shown then f:Show() else f:Hide() end
end

local function ReadCollapsed()
    if GetDBBool then return GetDBBool('DockCollapsed') end
    return (ADT and ADT.GetDBValue and ADT.GetDBValue('DockCollapsed')) and true or false
end

-- ============================================================================
-- 折叠/展开逻辑（带动画过渡）
-- ============================================================================

function ADT.DockUI.IsCollapsed()
    return not not ReadCollapsed()
end

-- 折叠/展开动画状态
local CollapseAnimState = {
    isAnimating = false,
    driver = nil,
}

-- 获取折叠动画配置
local function GetCollapseConfig()
    local cfg = ADT.HousingInstrCFG and ADT.HousingInstrCFG.TransitionAnimations
    local sub = cfg and cfg.DockCollapse
    return cfg, sub
end

-- 缓动函数（复用 Housing_Transition 的算法）
local function EaseValue(t, mode)
    t = math.max(0, math.min(1, t or 0))
    mode = (mode or "OUT"):upper()
    
    if mode == "OUT_QUART" or mode == "OUTQUART" then
        local u = 1 - t
        return 1 - u * u * u * u
    elseif mode == "IN_OUT_SINE" or mode == "INOUTSINE" then
        return -(math.cos(math.pi * t) - 1) / 2
    elseif mode == "OUT_SINE" or mode == "OUTSINE" then
        return math.sin(t * math.pi / 2)
    elseif mode == "IN_SINE" or mode == "INSINE" then
        return 1 - math.cos(t * math.pi / 2)
    elseif mode == "IN" then
        return t * t
    elseif mode == "IN_OUT" or mode == "INOUT" then
        if t < 0.5 then
            return 2 * t * t
        else
            local u = 1 - t
            return 1 - 2 * u * u
        end
    end
    -- 默认 OUT
    return t * (2 - t)
end

-- 取消正在进行的折叠动画
local function CancelCollapseAnim()
    if CollapseAnimState.driver then
        CollapseAnimState.driver:SetScript("OnUpdate", nil)
    end
    CollapseAnimState.isAnimating = false
end

-- 执行折叠/展开动画
local function AnimateCollapse(main, toCollapsed, onDone)
    local cfg, sub = GetCollapseConfig()
    local enabled = cfg and cfg.enabled ~= false and sub and sub.enabled ~= false
    
    -- 获取 Header 高度和完整高度
    local headerHeight = main.Header and tonumber(main.Header:GetHeight()) or 68
    local fullHeight = main._ADT_DesiredHeight or tonumber(main:GetHeight()) or 400
    
    -- 如果动画未启用或参数无效，直接应用最终状态
    if not enabled or not main or headerHeight <= 0 then
        if onDone then onDone() end
        return
    end
    
    -- 取消之前的动画
    CancelCollapseAnim()
    
    -- 动画参数
    local duration = toCollapsed 
        and (tonumber(sub.collapseDuration) or 0.35) 
        or (tonumber(sub.expandDuration) or 0.4)
    local easing = toCollapsed 
        and (sub.smoothingOut or "IN_OUT_SINE") 
        or (sub.smoothingIn or "OUT_QUART")
    
    -- 起始和目标高度
    local fromHeight = tonumber(main:GetHeight()) or (toCollapsed and fullHeight or headerHeight)
    local toHeight = toCollapsed and headerHeight or fullHeight
    
    if duration <= 0 or math.abs(fromHeight - toHeight) < 1 then
        main:SetHeight(toHeight)
        if onDone then onDone() end
        return
    end
    
    -- 创建动画驱动 Frame
    if not CollapseAnimState.driver then
        CollapseAnimState.driver = CreateFrame("Frame")
    end
    
    local state = {
        fromHeight = fromHeight,
        toHeight = toHeight,
        duration = duration,
        easing = easing,
        elapsed = 0,
        onDone = onDone,
        main = main,
        toCollapsed = toCollapsed,
    }
    
    CollapseAnimState.isAnimating = true
    
    CollapseAnimState.driver:SetScript("OnUpdate", function(_, dt)
        if dt and dt > 0.05 then dt = 0.05 end
        state.elapsed = state.elapsed + (dt or 0)
        
        local t = state.duration > 0 and math.min(1, state.elapsed / state.duration) or 1
        local e = EaseValue(t, state.easing)
        local currentHeight = state.fromHeight + (state.toHeight - state.fromHeight) * e
        
        state.main:SetHeight(currentHeight)
        
        -- 边框始终跟随主体当前尺寸（动画过程中不跳到 Header）
        local borderFrame = state.main.BorderFrame
        if borderFrame then
            borderFrame:ClearAllPoints()
            borderFrame:SetAllPoints(state.main)
        end
        
        if t >= 1 then
            CollapseAnimState.driver:SetScript("OnUpdate", nil)
            CollapseAnimState.isAnimating = false
            state.main:SetHeight(state.toHeight)
            if state.onDone then state.onDone() end
        end
    end)
end

function ADT.DockUI.SetCollapsed(state)
    local v = not not state
    local wasCollapsed = ReadCollapsed()
    local CommandDock = ADT.CommandDock
    local main = CommandDock and CommandDock.SettingsPanel
    
    -- 进入折叠前，记录当前所处分类
    if v then
        if main then
            local key = main.currentDecorCategory or main.currentDyePresetsCategory or main.currentAboutCategory or main.currentSettingsCategory
            if not key and ADT and ADT.GetDBValue then
                key = ADT.GetDBValue('LastCategoryKey')
            end
            ADT.DockUI._lastCategoryKey = key
        end
    end

    -- 写入 DB
    if ADT and ADT.SetDBValue then ADT.SetDBValue('DockCollapsed', v) end
    
    -- 检查是否应该执行动画
    local shouldAnimate = main and wasCollapsed ~= v
    
    if shouldAnimate then
        -- 先准备 UI 状态
        local collapsed = v
        local mainPanelsVisible = not not ADT.DockUI._mainPanelsVisible
        
        if not mainPanelsVisible then
            -- 主面板不可见时，直接应用状态，无需动画
            ADT.DockUI.ApplyCollapsedAppearance()
            return
        end
        
        if collapsed then
            -- 折叠：内容保持可见，先执行高度动画，动画完成后再隐藏内容
            -- 齿轮按钮选中态
            if main._ADT_GearButton and main._ADT_GearButton.ActiveOverlay then
                main._ADT_GearButton.ActiveOverlay:SetShown(true)
            end
            
            -- 执行折叠动画（内容在动画过程中保持可见，跟随边框向上收缩）
            AnimateCollapse(main, true, function()
                -- 动画完成后隐藏主体内容
                SetShownSafe(main.LeftSlideContainer, false)
                SetShownSafe(main.LeftPanelContainer, false)
                SetShownSafe(main.CenterBackground, false)
                SetShownSafe(main.RightUnifiedBackground, false)
                if main.ModuleTab then SetShownSafe(main.ModuleTab, false) end
                if main.CentralSection then SetShownSafe(main.CentralSection, false) end
                
                -- 调整边框
                if main.BorderFrame and main.Header then
                    main.BorderFrame:ClearAllPoints()
                    main.BorderFrame:SetPoint("TOPLEFT", main.Header, "TOPLEFT", 0, 0)
                    main.BorderFrame:SetPoint("BOTTOMRIGHT", main.Header, "BOTTOMRIGHT", 0, 0)
                end
                -- 通知布局管理器
                if ADT and ADT.HousingLayoutManager and ADT.HousingLayoutManager.RequestLayout then
                    ADT.HousingLayoutManager:RequestLayout('DockCollapsedChanged')
                end
            end)
        else
            -- 展开：先显示内容并设置裁剪，然后执行高度动画（抽屉效果）
            -- 边框跟随主体
            if main.BorderFrame then
                main.BorderFrame:ClearAllPoints()
                main.BorderFrame:SetAllPoints(main)
            end
            
            -- 齿轮按钮选中态
            if main._ADT_GearButton and main._ADT_GearButton.ActiveOverlay then
                main._ADT_GearButton.ActiveOverlay:SetShown(false)
            end
            
            -- 先显示主体内容（它们会跟随 main 的高度变化被裁剪）
            SetShownSafe(main.LeftSlideContainer, true)
            SetShownSafe(main.LeftPanelContainer, true)
            SetShownSafe(main.CenterBackground, true)
            SetShownSafe(main.RightUnifiedBackground, true)
            if main.ModuleTab then SetShownSafe(main.ModuleTab, true) end
            if main.CentralSection then SetShownSafe(main.CentralSection, true) end
            
            -- 执行展开动画（内容跟随边框向下滑出）
            AnimateCollapse(main, false, function()
                -- 刷新内容
                local function _refresh()
                    local m = ADT and ADT.CommandDock and ADT.CommandDock.SettingsPanel
                    if not m then return end
                    local sv = m.ModuleTab and m.ModuleTab.ScrollView
                    if sv and sv.OnSizeChanged then sv:OnSizeChanged(true) end
                    if m._SyncCentralTemplateWidths then m:_SyncCentralTemplateWidths(true) end
                    if m.ModuleTab and m.ModuleTab.ScrollBar and m.ModuleTab.ScrollBar.UpdateThumbRange then
                        m.ModuleTab.ScrollBar:UpdateThumbRange()
                    end
                end
                C_Timer.After(0, _refresh)
                C_Timer.After(0.05, _refresh)
                
                -- 通知布局管理器
                if ADT and ADT.HousingLayoutManager and ADT.HousingLayoutManager.RequestLayout then
                    ADT.HousingLayoutManager:RequestLayout('DockCollapsedChanged')
                end
            end)
        end
    else
        -- 不需要动画时的回退逻辑
        ADT.DockUI.ApplyCollapsedAppearance()
        if ADT and ADT.HousingLayoutManager and ADT.HousingLayoutManager.RequestLayout then
            ADT.HousingLayoutManager:RequestLayout('DockCollapsedChanged')
        end
    end
end

function ADT.DockUI.ToggleCollapsed()
    -- 如果正在动画中，忽略切换请求
    if CollapseAnimState.isAnimating then return end
    ADT.DockUI.SetCollapsed(not ReadCollapsed())
end

-- 根据当前 DB 状态应用显隐
function ADT.DockUI.ApplyCollapsedAppearance()
    local CommandDock = ADT.CommandDock
    local main = CommandDock and CommandDock.SettingsPanel
    if not main then return end
    local collapsed = ReadCollapsed()
    -- 关键修复：当“默认开启设置面板”被关闭（或用户主动隐藏主体面板）时，
    -- 此函数不应再次根据折叠状态把主体各区块显示出来。
    -- 之前的实现会在 ApplyPanelsDefaultVisibility() 之后被调用，
    -- 由于这里无条件按“折叠状态”改写显隐，导致进入编辑器时面板又被显示。
    -- 现在按 ADT.DockUI._mainPanelsVisible 作为总开关：为 false 时，
    -- 直接隐藏主体相关元素并返回，避免误显。
    local mainPanelsVisible = not not ADT.DockUI._mainPanelsVisible
    if not mainPanelsVisible then
        SetShownSafe(main.LeftSlideContainer, false)
        SetShownSafe(main.LeftPanelContainer, false)
        SetShownSafe(main.CenterBackground, false)
        SetShownSafe(main.RightUnifiedBackground, false)
        if main.ModuleTab then SetShownSafe(main.ModuleTab, false) end
        if main.CentralSection then SetShownSafe(main.CentralSection, false) end
        -- 头部与边框也一并隐藏，避免“已关闭默认开启”仍出现齿轮与木框
        SetShownSafe(main.Header, false)
        if main.BorderFrame then SetShownSafe(main.BorderFrame, false) end
        return
    end
    local Def = ADT.DockUI.Def

    -- 左侧独立层
    SetShownSafe(main.LeftSlideContainer, not collapsed)
    SetShownSafe(main.LeftPanelContainer, not collapsed)

    -- 右侧主体
    SetShownSafe(main.CenterBackground, not collapsed)
    SetShownSafe(main.RightUnifiedBackground, not collapsed)
    if main.ModuleTab then SetShownSafe(main.ModuleTab, not collapsed) end
    if main.CentralSection then SetShownSafe(main.CentralSection, not collapsed) end

    -- Header 与 Border 在主体可见时始终可见
    SetShownSafe(main.Header, true)
    if main.BorderFrame then
        main.BorderFrame:ClearAllPoints()
        if collapsed and main.Header then
            main.BorderFrame:SetPoint("TOPLEFT", main.Header, "TOPLEFT", 0, 0)
            main.BorderFrame:SetPoint("BOTTOMRIGHT", main.Header, "BOTTOMRIGHT", 0, 0)
        else
            main.BorderFrame:SetAllPoints(main)
        end
        SetShownSafe(main.BorderFrame, true)
    end

    -- 立即把 Dock 高度收敛到 Header
    if collapsed and main.SetHeight and main.Header and main.Header.GetHeight then
        local hh = tonumber(main.Header:GetHeight() or 0) or 0
        if hh > 0 then main:SetHeight(hh) end
    end

    -- 齿轮按钮选中态
    if main._ADT_GearButton and main._ADT_GearButton.ActiveOverlay then
        main._ADT_GearButton.ActiveOverlay:SetShown(collapsed)
    end

    -- 展开后刷新
    if not collapsed then
        local function _refresh()
            local m = ADT and ADT.CommandDock and ADT.CommandDock.SettingsPanel
            if not m then return end
            local sv = m.ModuleTab and m.ModuleTab.ScrollView
            if sv and sv.OnSizeChanged then sv:OnSizeChanged(true) end
            if m._SyncCentralTemplateWidths then m:_SyncCentralTemplateWidths(true) end
            if m.ModuleTab and m.ModuleTab.ScrollBar and m.ModuleTab.ScrollBar.UpdateThumbRange then
                m.ModuleTab.ScrollBar:UpdateThumbRange()
            end
            local key = m.currentDecorCategory or m.currentDyePresetsCategory or m.currentAboutCategory or m.currentSettingsCategory
            if key and ADT and ADT.CommandDock and ADT.CommandDock.GetCategoryByKey then
                local cat = ADT.CommandDock:GetCategoryByKey(key)
                if cat then
                    if cat.categoryType == 'decorList' and m.ShowDecorListCategory then
                        m:ShowDecorListCategory(key)
                    elseif cat.categoryType == 'dyePresetList' and m.ShowDyePresetsCategory then
                        m:ShowDyePresetsCategory(key)
                    elseif cat.categoryType == 'about' and m.ShowAboutCategory then
                        m:ShowAboutCategory(key)
                    elseif cat.categoryType == 'keybinds' and m.ShowKeybindsCategory then
                        m:ShowKeybindsCategory(key)
                    elseif m.ShowSettingsCategory then
                        m:ShowSettingsCategory(key)
                    end
                end
            end
        end
        C_Timer.After(0, _refresh)
        C_Timer.After(0.05, _refresh)
        C_Timer.After(0.15, _refresh)
    end
end

-- ============================================================================
-- 面板显隐控制
-- ============================================================================

-- 单一权威：外部仅调用这一个入口控制 Dock 主体是否可见
function ADT.DockUI.SetMainPanelsVisible(shown)
    local CommandDock = ADT.CommandDock
    local main = CommandDock and CommandDock.SettingsPanel
    if not main then return end
    local vis = not not shown

    -- 左侧
    SetShownSafe(main.LeftSlideContainer, vis)
    SetShownSafe(main.LeftPanelContainer, vis)

    -- 右侧
    SetShownSafe(main.Header, vis)
    SetShownSafe(main.RightUnifiedBackground, vis)
    SetShownSafe(main.CenterBackground, vis)
    if main.ModuleTab then SetShownSafe(main.ModuleTab, vis) end
    if main.CentralSection then SetShownSafe(main.CentralSection, vis) end
    if main.BorderFrame then SetShownSafe(main.BorderFrame, vis) end

    ADT.DockUI._mainPanelsVisible = vis

    if vis then
        C_Timer.After(0, function()
            local m = ADT and ADT.CommandDock and ADT.CommandDock.SettingsPanel
            if not m then return end
            local sv = m.ModuleTab and m.ModuleTab.ScrollView
            if sv and sv.OnSizeChanged then sv:OnSizeChanged(true) end
            if m._SyncCentralTemplateWidths then m:_SyncCentralTemplateWidths(true) end
            if m.ModuleTab and m.ModuleTab.ScrollBar and m.ModuleTab.ScrollBar.UpdateThumbRange then
                m.ModuleTab.ScrollBar:UpdateThumbRange()
            end
        end)
    end
end

function ADT.DockUI.AreMainPanelsVisible()
    return not not ADT.DockUI._mainPanelsVisible
end

function ADT.DockUI.ApplyPanelsDefaultVisibility()
    local CommandDock = ADT.CommandDock
    local main = CommandDock and CommandDock.SettingsPanel
    if not main then return end
    local v = ADT and ADT.GetDBValue and ADT.GetDBValue('EnableDockAutoOpenInEditor')
    local shouldShowMainPanels = (v ~= false)
    ADT.DockUI.SetMainPanelsVisible(shouldShowMainPanels)
    if ADT and ADT.DockUI and ADT.DockUI.ApplyCollapsedAppearance then
        ADT.DockUI.ApplyCollapsedAppearance()
    end
end
