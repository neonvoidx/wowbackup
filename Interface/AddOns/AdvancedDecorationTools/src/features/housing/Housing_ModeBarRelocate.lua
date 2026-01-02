-- Housing_ModeBarRelocate.lua
-- ADT 功能：将暴雪住宅编辑模式栏移动到右下角垂直布局
-- 最小侵入式实现：仅 Hook/移动暴雪 Frame，不修改原始文件

local ADDON_NAME, ADT = ...
if not ADT or not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local L = ADT and ADT.L or {}

--------------------------------------------------------------------------------
-- 配置（从 Housing_Config.lua 读取，单一权威）
--------------------------------------------------------------------------------

local function GetCFG()
    return ADT and ADT.HousingInstrCFG and ADT.HousingInstrCFG.ModeBarRelocate or {
        AnchorOffsetX = -20,
        AnchorOffsetY = 40,
        ButtonSpacing = -8,
        SubBarOffset = -10,
        ArrowOffsetX = -5,
        ArrowOffsetY = 0,
        FloorSelectOffsetX = -60,
        FloorSelectOffsetY = 0,
    }
end

--------------------------------------------------------------------------------
-- 状态
--------------------------------------------------------------------------------

local ModeBarRelocate = {}
ADT.ModeBarRelocate = ModeBarRelocate

-- 是否已应用自定义布局
ModeBarRelocate.isRelocated = false
-- 是否启用拖拽（默认关闭）
ModeBarRelocate.isDraggable = false
-- 传统界面：是否已恢复默认布局
ModeBarRelocate.classicPrepared = false
-- 传统界面：已应用的锚点签名
ModeBarRelocate._classicAnchorKey = nil

-- 保存原始锚点和状态
local originalState = {
    modeBarAnchors = nil,
    buttonAnchors = {},
    subBarAnchors = {},
    subButtonAnchors = {},
    arrowRotations = {},
    floorSelectAnchors = nil,
}

--------------------------------------------------------------------------------
-- 工具函数
--------------------------------------------------------------------------------

-- 保存 frame 的所有锚点
local function SaveAnchors(frame)
    if not frame then return nil end
    local anchors = {}
    for i = 1, frame:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = frame:GetPoint(i)
        table.insert(anchors, {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            x = x,
            y = y,
        })
    end
    return anchors
end

-- 恢复 frame 的所有锚点
local function RestoreAnchors(frame, anchors)
    if not frame or not anchors then return end
    frame:ClearAllPoints()
    for _, anchor in ipairs(anchors) do
        frame:SetPoint(anchor.point, anchor.relativeTo, anchor.relativePoint, anchor.x, anchor.y)
    end
end

-- 获取当前模式框架映射（单一权威）
local function GetModeFrameMappings(ModeBar)
    if not (HouseEditorFrame and ModeBar) then return {} end
    return {
        { frame = HouseEditorFrame.BasicDecorModeFrame, button = ModeBar.BasicDecorModeButton },
        { frame = HouseEditorFrame.ExpertDecorModeFrame, button = ModeBar.ExpertDecorModeButton },
        { frame = HouseEditorFrame.CustomizeModeFrame, button = ModeBar.CustomizeModeButton },
        { frame = HouseEditorFrame.CleanupModeFrame, button = ModeBar.CleanupModeButton },
        { frame = HouseEditorFrame.LayoutModeFrame, button = ModeBar.LayoutModeButton },
        { frame = HouseEditorFrame.ExteriorCustomizationModeFrame, button = ModeBar.ExteriorCustomizationModeButton },
    }
end

-- 获取子模式栏（兼容基础/专家模式的命名差异）
local function GetSubBar(modeFrame)
    if not modeFrame then return nil end
    if modeFrame.SubButtonBar then return modeFrame.SubButtonBar end
    if modeFrame.SubmodeBar then return modeFrame.SubmodeBar end
    return nil
end

local function GetFloorSelectFrame()
    local layoutFrame = HouseEditorFrame and HouseEditorFrame.LayoutModeFrame
    return layoutFrame and layoutFrame.FloorSelect
end

local function GetClassicGap()
    local cfg = ADT and ADT.HousingInstrCFG and ADT.HousingInstrCFG.QuickbarUI or nil
    return (cfg and cfg.modeBarGap) or 0
end

local function BuildClassicAnchorKey(modeBar, quickbarFrame, gap)
    return tostring(modeBar) .. "|" .. tostring(quickbarFrame) .. "|" .. tostring(gap)
end

--------------------------------------------------------------------------------
-- 传统界面布局：恢复暴雪默认样式 + 将 ModeBar 放到 Quickbar 上方
--------------------------------------------------------------------------------

function ModeBarRelocate:RestoreDefaultLayout()
    local ModeBar = HouseEditorFrame and HouseEditorFrame.ModeBar
    if not ModeBar then return end

    -- 恢复默认背景
    if ModeBar.GradientBackground then ModeBar.GradientBackground:Show() end
    if ModeBar.Background then ModeBar.Background:Show() end
    if ModeBar.BookendLeft then ModeBar.BookendLeft:Show() end
    if ModeBar.BookendRight then ModeBar.BookendRight:Show() end
    if ModeBar.Divider then ModeBar.Divider:Show() end

    -- 恢复主栏锚点
    if originalState.modeBarAnchors then
        RestoreAnchors(ModeBar, originalState.modeBarAnchors)
    else
        ModeBar:ClearAllPoints()
        ModeBar:SetPoint("BOTTOM", HouseEditorFrame or UIParent, "BOTTOM", 0, 0)
    end

    -- 恢复按钮与子栏锚点
    for btn, anchors in pairs(originalState.buttonAnchors) do
        RestoreAnchors(btn, anchors)
    end
    for subBar, anchors in pairs(originalState.subBarAnchors) do
        RestoreAnchors(subBar, anchors)
    end
    for subBtn, anchors in pairs(originalState.subButtonAnchors) do
        RestoreAnchors(subBtn, anchors)
    end
    for arrow, data in pairs(originalState.arrowRotations) do
        if data and data.anchors then
            RestoreAnchors(arrow, data.anchors)
        end
        if data and data.rotation and arrow.SetRotation then
            arrow:SetRotation(data.rotation or 0)
        end
    end

    self:RestoreFloorSelect()

    -- 触发默认 Layout（恢复水平排列）
    if ModeBar.Layout then ModeBar:Layout() end
    local modeFrames = GetModeFrameMappings(ModeBar)
    for _, mapping in ipairs(modeFrames) do
        local subBar = GetSubBar(mapping.frame)
        if subBar and subBar.Layout then
            subBar:Layout()
        end
    end
end

function ModeBarRelocate:ApplyClassicLayout(quickbarFrame)
    if not (ADT.InterfaceStyle and ADT.InterfaceStyle.IsClassic and ADT.InterfaceStyle:IsClassic()) then
        return false
    end
    local ModeBar = HouseEditorFrame and HouseEditorFrame.ModeBar
    if not ModeBar then return false end
    
    -- 仅首次恢复默认布局与样式，避免反复改动
    if not self.classicPrepared then
        if self.isRelocated then
            self:RestoreDefaultLayout()
            self.isRelocated = false
        else
            -- 确保背景可见（防止现代布局残留）
            if ModeBar.GradientBackground then ModeBar.GradientBackground:Show() end
            if ModeBar.Background then ModeBar.Background:Show() end
            if ModeBar.BookendLeft then ModeBar.BookendLeft:Show() end
            if ModeBar.BookendRight then ModeBar.BookendRight:Show() end
            if ModeBar.Divider then ModeBar.Divider:Show() end
            if ModeBar.Layout then ModeBar:Layout() end
        end
        self.classicPrepared = true
        self._classicAnchorKey = nil
    end

    -- Quickbar 关闭时不强行贴靠
    if ADT.GetDBValue and ADT.GetDBValue("EnableQuickbar") == false then
        return false
    end
    if not quickbarFrame then return false end

    local gap = GetClassicGap()
    local key = BuildClassicAnchorKey(ModeBar, quickbarFrame, gap)
    if self._classicAnchorKey ~= key then
        ModeBar:ClearAllPoints()
        ModeBar:SetPoint("BOTTOM", quickbarFrame, "TOP", 0, gap)
        self._classicAnchorKey = key
        if ADT and ADT.DebugPrint then
            ADT.DebugPrint("[ModeBarRelocate] 传统界面：ModeBar 锚到 Quickbar 上方，间距=" .. tostring(gap))
        end
    end
    return true
end

--------------------------------------------------------------------------------
-- 核心功能：应用自定义布局
--------------------------------------------------------------------------------

function ModeBarRelocate:ApplyLayout()
    -- 传统界面下恢复暴雪默认布局
    if ADT.InterfaceStyle and ADT.InterfaceStyle:IsClassic() then
        local qb = ADT.QuickbarUI and ADT.QuickbarUI.uiFrame
        self:ApplyClassicLayout(qb)
        return
    end
    
    -- 退出传统界面，清理经典状态
    if self.classicPrepared then
        self.classicPrepared = false
        self._classicAnchorKey = nil
    end
    
    local ModeBar = HouseEditorFrame and HouseEditorFrame.ModeBar
    if not ModeBar then return end
    
    -- 保存原始状态（仅首次）
    if not originalState.modeBarAnchors then
        originalState.modeBarAnchors = SaveAnchors(ModeBar)
    end
    
    -- 1. 隐藏背景素材
    if ModeBar.GradientBackground then ModeBar.GradientBackground:Hide() end
    if ModeBar.Background then ModeBar.Background:Hide() end
    if ModeBar.BookendLeft then ModeBar.BookendLeft:Hide() end
    if ModeBar.BookendRight then ModeBar.BookendRight:Hide() end
    if ModeBar.Divider then ModeBar.Divider:Hide() end
    
    -- 2. 移动主模式栏到右下角
    local cfg = GetCFG()
    ModeBar:ClearAllPoints()
    ModeBar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", cfg.AnchorOffsetX, cfg.AnchorOffsetY)
    
    -- 3. 垂直重排主按钮（从底部向上生长）
    local buttons = ModeBar.Buttons or {}
    local prevBtn = nil
    local visibleCount = 0
    local firstButton, lastButton = nil, nil
    
    for i, btn in ipairs(buttons) do
        if btn:IsShown() then
            visibleCount = visibleCount + 1
            -- 保存原始锚点（仅首次）
            if not originalState.buttonAnchors[btn] then
                originalState.buttonAnchors[btn] = SaveAnchors(btn)
            end
            
            btn:ClearAllPoints()
            if prevBtn then
                -- 后续按钮向上堆叠
                btn:SetPoint("BOTTOM", prevBtn, "TOP", 0, -cfg.ButtonSpacing)
            else
                -- 第一个按钮贴着右下角
                btn:SetPoint("BOTTOMRIGHT", ModeBar, "BOTTOMRIGHT", 0, 0)
                firstButton = btn
            end
            lastButton = btn
            prevBtn = btn
        end
    end
    
    -- 4. 创建/更新背景框
    self:CreateOrUpdateBackgroundFrame(ModeBar, firstButton, lastButton, visibleCount, cfg)
    
    -- 5. 处理各模式框架的子模式栏
    self:RelocateSubBars()

    -- 5.1 处理楼层切换 UI（Layout 模式）
    self:RelocateFloorSelect()
    
    -- 6. 设置拖拽（如果启用）
    self:UpdateDraggable()
    
    self.isRelocated = true
    
    if ADT and ADT.DebugPrint then
        ADT.DebugPrint("[ModeBarRelocate] 布局已应用")
    end
end

-- 创建或更新背景框
function ModeBarRelocate:CreateOrUpdateBackgroundFrame(ModeBar, firstButton, lastButton, buttonCount, cfg)
    if not firstButton or not lastButton then return end
    
    -- 创建背景框（仅首次）
    if not self.backgroundFrame then
        local bg = CreateFrame("Frame", nil, ModeBar)
        bg:SetFrameStrata("BACKGROUND")
        bg:SetFrameLevel(ModeBar:GetFrameLevel() - 1)
        
        -- 使用 housing-basic-container 素材
        bg.texture = bg:CreateTexture(nil, "BACKGROUND")
        bg.texture:SetAtlas("housing-basic-container")
        bg.texture:SetAllPoints(bg)

        -- 初始隐藏，避免创建瞬间闪烁
        if ADT.HousingTransition and ADT.HousingTransition.PrepareHidden then
            ADT.HousingTransition:PrepareHidden(bg)
        else
            bg:SetAlpha(0)
            bg:Hide()
        end

        self.backgroundFrame = bg
    end
    
    local bg = self.backgroundFrame
    
    -- 计算背景框大小和位置
    local buttonWidth = firstButton:GetWidth() or 64
    local buttonHeight = firstButton:GetHeight() or 64
    local spacing = cfg.ButtonSpacing or -8
    local padding = cfg.BackgroundPadding or 8
    
    local totalHeight = (buttonCount * buttonHeight) + ((buttonCount - 1) * spacing) + (padding * 2)
    local totalWidth = buttonWidth + (padding * 2)
    
    bg:ClearAllPoints()
    bg:SetSize(totalWidth, totalHeight)
    -- 背景框定位到第一个按钮（底部）并向下扩展 padding
    bg:SetPoint("BOTTOM", firstButton, "BOTTOM", 0, -padding)
    bg:SetPoint("TOP", lastButton, "TOP", 0, padding)
    bg:SetWidth(totalWidth)
    
    
    -- 进入动画统一由 Housing_Transition 管理
    if ADT.HousingTransition and ADT.HousingTransition.PlayEnter then
        ADT.HousingTransition:PlayEnter(bg, "ModeBar")
    else
        bg:Show()
        bg:SetAlpha(1)
    end
end

--------------------------------------------------------------------------------
-- 过渡动画：暴雪原生框体与背景统一淡入/淡出
--------------------------------------------------------------------------------

function ModeBarRelocate:PlayTransition(isActive)
    local transition = ADT and ADT.HousingTransition
    if not transition then return end
    
    local ModeBar = HouseEditorFrame and HouseEditorFrame.ModeBar
    if isActive then
        if transition.PlayEnter then
            if self.backgroundFrame then
                transition:PlayEnter(self.backgroundFrame, "ModeBar")
            end
            if ModeBar then
                transition:PlayEnter(ModeBar, "ModeBar")
                local modeFrames = GetModeFrameMappings(ModeBar)
                for _, mapping in ipairs(modeFrames) do
                    local modeFrame = mapping.frame
                    local subBar = GetSubBar(modeFrame)
                    if subBar and modeFrame and modeFrame:IsShown() then
                        transition:PlayEnter(subBar, "ModeBar")
                    end
                end
            end
        end
        -- 事件触发先后无保证：下一帧补一次“当前激活模式”的子模式栏显示
        self:ScheduleEnsureActiveSubBarVisible("PlayTransition")
    else
        if transition.PlayExit then
            if self.backgroundFrame then
                transition:PlayExit(self.backgroundFrame, "ModeBar")
            end
            if ModeBar then
                transition:PlayExit(ModeBar, "ModeBar")
                local modeFrames = GetModeFrameMappings(ModeBar)
                for _, mapping in ipairs(modeFrames) do
                    local subBar = GetSubBar(mapping.frame)
                    if subBar then
                        transition:PlayExit(subBar, "ModeBar")
                    end
                end
            end
        end
    end
end

-- 补偿：确保当前激活模式的子模式栏可见（避免二次进入时被隐藏后不再恢复）
function ModeBarRelocate:EnsureActiveSubBarVisible(reason)
    if not self.isRelocated then return end
    if not (C_HouseEditor and C_HouseEditor.IsHouseEditorActive and C_HouseEditor.IsHouseEditorActive()) then return end
    if not (HouseEditorFrame and HouseEditorFrame.GetActiveModeFrame) then return end
    
    local modeFrame = HouseEditorFrame:GetActiveModeFrame()
    if not (modeFrame and modeFrame.IsShown and modeFrame:IsShown()) then return end
    
    local subBar = GetSubBar(modeFrame)
    if not subBar then return end
    
    -- 先同步锚点与布局，再补显示
    self:RelocateSubBars()
    
    local transition = ADT and ADT.HousingTransition
    if transition and transition.PlayEnter then
        transition:PlayEnter(subBar, "ModeBar")
    else
        subBar:Show()
        subBar:SetAlpha(1)
    end
    
    if ADT and ADT.DebugPrint then
        local tag = reason and ("(" .. tostring(reason) .. ")") or ""
        ADT.DebugPrint("[ModeBarRelocate] 已补显示子模式栏" .. tag)
    end
end

function ModeBarRelocate:ScheduleEnsureActiveSubBarVisible(reason)
    if self._ensureSubBarPending then return end
    self._ensureSubBarPending = true
    C_Timer.After(0, function()
        self._ensureSubBarPending = nil
        if ModeBarRelocate and ModeBarRelocate.EnsureActiveSubBarVisible then
            ModeBarRelocate:EnsureActiveSubBarVisible(reason)
        end
    end)
end

-- 处理子模式栏
function ModeBarRelocate:RelocateSubBars()
    local ModeBar = HouseEditorFrame and HouseEditorFrame.ModeBar
    if not ModeBar then return end
    
    local modeFrames = GetModeFrameMappings(ModeBar)
    
    for _, mapping in ipairs(modeFrames) do
        local modeFrame = mapping.frame
        local modeButton = mapping.button
        -- 兼容两种子模式栏命名：SubButtonBar（基础模式）和 SubmodeBar（专家模式）
        local subBar = GetSubBar(modeFrame)
        
        if subBar then
            -- 保存原始锚点（仅首次）
            if not originalState.subBarAnchors[subBar] then
                originalState.subBarAnchors[subBar] = SaveAnchors(subBar)
            end
            
            -- 处理箭头：旋转90°指向右侧（母模式），重新锚定到子模式栏右侧居中
            if subBar.Arrow then
                if originalState.arrowRotations[subBar.Arrow] == nil then
                    -- 保存原始旋转和锚点
                    originalState.arrowRotations[subBar.Arrow] = {
                        rotation = subBar.Arrow:GetRotation() or 0,
                        anchors = SaveAnchors(subBar.Arrow),
                    }
                end
                -- 旋转90°使箭头指向右侧
                subBar.Arrow:SetRotation(math.rad(90))
                -- 重新锚定到子模式栏右侧居中（在子按钮和母按钮之间）
                local arrowCfg = GetCFG()
                subBar.Arrow:ClearAllPoints()
                subBar.Arrow:SetPoint("LEFT", subBar, "RIGHT", arrowCfg.ArrowOffsetX, arrowCfg.ArrowOffsetY)
                subBar.Arrow:Show()
            end
            
            -- 重新锚定到对应主按钮左侧（垂直居中）
            local cfg = GetCFG()
            subBar:ClearAllPoints()
            subBar:SetPoint("RIGHT", modeButton, "LEFT", cfg.SubBarOffset, 0)
            
            -- 垂直排列子按钮（居中对齐）
            local subButtons = subBar.Buttons or {}
            local visibleButtons = {}
            local resetButton = nil
            
            -- 区分普通子按钮和 ResetButton（专家模式特有）
            for _, btn in ipairs(subButtons) do
                if btn:IsShown() then
                    -- 判断是否为 ResetButton（通过 ignoreInLayout 属性或 parentKey 判断）
                    if btn.ignoreInLayout or (subBar.ResetButton and btn == subBar.ResetButton) then
                        resetButton = btn
                    else
                        table.insert(visibleButtons, btn)
                    end
                end
            end
            
            -- 检查是否有独立的 ResetButton（专家模式）
            if subBar.ResetButton and subBar.ResetButton:IsShown() then
                resetButton = subBar.ResetButton
            end
            
            local numButtons = #visibleButtons
            if numButtons > 0 then
                local buttonHeight = visibleButtons[1]:GetHeight() or 64
                -- 使用暴雪原始的 spacing 值（从 subBar 读取，保持紧凑度）
                local subSpacing = subBar.spacing or -12
                
                for j, subBtn in ipairs(visibleButtons) do
                    -- 保存原始锚点（仅首次）
                    if not originalState.subButtonAnchors[subBtn] then
                        originalState.subButtonAnchors[subBtn] = SaveAnchors(subBtn)
                    end
                    
                    subBtn:ClearAllPoints()
                    local yOffset
                    if numButtons % 2 == 1 then
                        -- 奇数按钮：中间按钮在 Y=0（与母按钮对齐）
                        local middleIndex = math.ceil(numButtons / 2)
                        yOffset = (middleIndex - j) * (buttonHeight + subSpacing)
                    else
                        -- 偶数按钮：两个按钮的中心与母按钮对齐
                        local totalHeight = (numButtons * buttonHeight) + ((numButtons - 1) * subSpacing)
                        local startY = totalHeight / 2 - buttonHeight / 2
                        yOffset = startY - (j - 1) * (buttonHeight + subSpacing)
                    end
                    subBtn:SetPoint("RIGHT", subBar, "RIGHT", 0, yOffset)
                end
                
                -- 处理 ResetButton：相对于子按钮水平居中、位于最顶部子按钮上方
                if resetButton then
                    if not originalState.subButtonAnchors[resetButton] then
                        originalState.subButtonAnchors[resetButton] = SaveAnchors(resetButton)
                    end
                    
                    -- 获取最顶部的子按钮
                    local topButton = visibleButtons[1]
                    resetButton:ClearAllPoints()
                    -- 水平居中于子按钮，位于顶部按钮上方
                    resetButton:SetPoint("BOTTOM", topButton, "TOP", 0, -subSpacing)
                end
            end
        end
    end
end

-- 处理楼层切换 UI（Layout 模式下的 FloorSelect）
function ModeBarRelocate:RelocateFloorSelect()
    if ADT.InterfaceStyle and ADT.InterfaceStyle:IsClassic() then
        self:RestoreFloorSelect()
        return
    end

    local floorSelect = GetFloorSelectFrame()
    if not floorSelect then return end

    local cfg = GetCFG()
    local offsetX = tonumber(cfg.FloorSelectOffsetX) or 0
    local offsetY = tonumber(cfg.FloorSelectOffsetY) or 0
    if offsetX == 0 and offsetY == 0 then return end

    if not originalState.floorSelectAnchors then
        originalState.floorSelectAnchors = SaveAnchors(floorSelect)
    end
    if not originalState.floorSelectAnchors then return end

    floorSelect:ClearAllPoints()
    for _, anchor in ipairs(originalState.floorSelectAnchors) do
        floorSelect:SetPoint(anchor.point, anchor.relativeTo, anchor.relativePoint, anchor.x + offsetX, anchor.y + offsetY)
    end
end

function ModeBarRelocate:RestoreFloorSelect()
    local floorSelect = GetFloorSelectFrame()
    if not floorSelect then return end
    if originalState.floorSelectAnchors then
        RestoreAnchors(floorSelect, originalState.floorSelectAnchors)
    end
end

--------------------------------------------------------------------------------
-- 恢复暴雪默认布局
--------------------------------------------------------------------------------

function ModeBarRelocate:RestoreDefault()
    -- 完整恢复暴雪布局（用于传统界面/切换回默认）
    if self.isRelocated or self.classicPrepared then
        -- 隐藏自定义背景框
        if self.backgroundFrame then
            self.backgroundFrame:Hide()
            self.backgroundFrame:SetAlpha(0)
        end
        self:RestoreDefaultLayout()
    end
    
    self.isRelocated = false
    self.classicPrepared = false
    self._classicAnchorKey = nil
    
    -- 禁用拖拽
    self:SetDraggable(false)
    
    if ADT and ADT.DebugPrint then
        ADT.DebugPrint("[ModeBarRelocate] 已恢复暴雪默认布局")
    end
end

--------------------------------------------------------------------------------
-- 拖拽功能
--------------------------------------------------------------------------------

function ModeBarRelocate:SetDraggable(enable)
    self.isDraggable = enable
    self:UpdateDraggable()
end

function ModeBarRelocate:UpdateDraggable()
    local ModeBar = HouseEditorFrame and HouseEditorFrame.ModeBar
    if not ModeBar then return end
    
    if self.isDraggable then
        ModeBar:SetMovable(true)
        ModeBar:EnableMouse(true)
        ModeBar:RegisterForDrag("LeftButton")
        ModeBar:SetScript("OnDragStart", function(self) self:StartMoving() end)
        ModeBar:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    else
        ModeBar:SetMovable(false)
        ModeBar:EnableMouse(false)
        ModeBar:RegisterForDrag()
        ModeBar:SetScript("OnDragStart", nil)
        ModeBar:SetScript("OnDragStop", nil)
    end
end

--------------------------------------------------------------------------------
-- 事件监听与 Layout Hook
--------------------------------------------------------------------------------

local EL = CreateFrame("Frame")
local layoutHooked = false

-- Hook 暴雪的 Layout 方法，避免闪烁
local function HookLayoutMethods()
    if layoutHooked then return end
    
    local ModeBar = HouseEditorFrame and HouseEditorFrame.ModeBar
    if not ModeBar then return end
    
    -- Hook 主模式栏的 Layout 方法
    -- 当暴雪调用 Layout() 后，我们立即同步应用自定义布局
    -- 关键：传统界面时不能应用自定义布局
    hooksecurefunc(ModeBar, "Layout", function()
        -- 传统界面下跳过
        if ADT.InterfaceStyle and ADT.InterfaceStyle:IsClassic() then
            if ADT and ADT.DebugPrint then
                ADT.DebugPrint("[ModeBarRelocate] Hook: 传统界面，跳过自定义布局")
            end
            return
        end
        if ModeBarRelocate.isRelocated and not ModeBarRelocate._isApplying then
            if ADT and ADT.DebugPrint then
                ADT.DebugPrint("[ModeBarRelocate] Hook: 应用自定义布局")
            end
            ModeBarRelocate._isApplying = true
            ModeBarRelocate:ApplyLayoutInternal()
            ModeBarRelocate._isApplying = nil
        elseif ADT and ADT.DebugPrint then
            ADT.DebugPrint("[ModeBarRelocate] Hook: 跳过 (isRelocated=" .. tostring(ModeBarRelocate.isRelocated) .. ", _isApplying=" .. tostring(ModeBarRelocate._isApplying) .. ")")
        end
    end)
    
    -- Hook 子模式栏的 Layout 方法
    local modeFrames = GetModeFrameMappings(ModeBar)
    
    for _, mapping in ipairs(modeFrames) do
        local modeFrame = mapping.frame
        local subBar = GetSubBar(modeFrame)
        if subBar and subBar.Layout then
            hooksecurefunc(subBar, "Layout", function()
                -- 传统界面下跳过
                if ADT.InterfaceStyle and ADT.InterfaceStyle:IsClassic() then return end
                if ModeBarRelocate.isRelocated and not ModeBarRelocate._isApplyingSub then
                    ModeBarRelocate._isApplyingSub = true
                    ModeBarRelocate:RelocateSubBars()
                    ModeBarRelocate._isApplyingSub = nil
                end
            end)
        end
    end
    
    layoutHooked = true
    
    if ADT and ADT.DebugPrint then
        ADT.DebugPrint("[ModeBarRelocate] Layout hooks 已安装")
    end
end

-- 内部布局函数（不触发 hook 递归）
function ModeBarRelocate:ApplyLayoutInternal()
    -- 传统界面下不应用自定义布局
    if ADT.InterfaceStyle and ADT.InterfaceStyle:IsClassic() then return end
    
    local ModeBar = HouseEditorFrame and HouseEditorFrame.ModeBar
    if not ModeBar then return end
    local cfg = GetCFG()
    
    -- 隐藏背景素材
    if ModeBar.GradientBackground then ModeBar.GradientBackground:Hide() end
    if ModeBar.Background then ModeBar.Background:Hide() end
    if ModeBar.BookendLeft then ModeBar.BookendLeft:Hide() end
    if ModeBar.BookendRight then ModeBar.BookendRight:Hide() end
    if ModeBar.Divider then ModeBar.Divider:Hide() end
    
    -- 移动主模式栏到右下角
    ModeBar:ClearAllPoints()
    ModeBar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", cfg.AnchorOffsetX, cfg.AnchorOffsetY)
    
    -- 垂直重排主按钮
    local buttons = ModeBar.Buttons or {}
    local prevBtn = nil
    local visibleCount = 0
    local firstButton, lastButton = nil, nil
    
    for i, btn in ipairs(buttons) do
        if btn:IsShown() then
            visibleCount = visibleCount + 1
            if not originalState.buttonAnchors[btn] then
                originalState.buttonAnchors[btn] = SaveAnchors(btn)
            end
            
            btn:ClearAllPoints()
            if prevBtn then
                btn:SetPoint("BOTTOM", prevBtn, "TOP", 0, -cfg.ButtonSpacing)
            else
                btn:SetPoint("BOTTOMRIGHT", ModeBar, "BOTTOMRIGHT", 0, 0)
                firstButton = btn
            end
            lastButton = btn
            prevBtn = btn
        end
    end
    
    -- 更新背景框
    self:CreateOrUpdateBackgroundFrame(ModeBar, firstButton, lastButton, visibleCount, cfg)
    
    -- 处理子模式栏
    self:RelocateSubBars()

    -- 处理楼层切换 UI（Layout 模式）
    self:RelocateFloorSelect()
    
    -- 设置拖拽
    self:UpdateDraggable()
end

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "Blizzard_HouseEditor" then
            -- 安装 Layout hooks
            HookLayoutMethods()
            -- 首次应用布局
            ModeBarRelocate:ApplyLayout()
            -- 若已在编辑模式，补一次过渡动画同步
            local isActive = C_HouseEditor and C_HouseEditor.IsHouseEditorActive and C_HouseEditor.IsHouseEditorActive()
            ModeBarRelocate:PlayTransition(isActive)
        end
    elseif event == "HOUSE_EDITOR_MODE_CHANGED" then
        -- 进入/离开编辑器时，统一走过渡动画管理器
        local isActive = C_HouseEditor and C_HouseEditor.IsHouseEditorActive and C_HouseEditor.IsHouseEditorActive()
        if ADT.InterfaceStyle and ADT.InterfaceStyle:IsClassic() then
            if isActive and ModeBarRelocate.ApplyClassicLayout then
                local qb = ADT.QuickbarUI and ADT.QuickbarUI.uiFrame
                ModeBarRelocate:ApplyClassicLayout(qb)
            end
            return
        end
        ModeBarRelocate:PlayTransition(isActive)
    end
end

EL:RegisterEvent("ADDON_LOADED")
EL:RegisterEvent("HOUSE_EDITOR_MODE_CHANGED")
EL:SetScript("OnEvent", OnEvent)

-- 如果 Blizzard_HouseEditor 已加载，立即安装 hooks 并应用布局
if C_AddOns.IsAddOnLoaded("Blizzard_HouseEditor") then
    C_Timer.After(0.1, function()
        HookLayoutMethods()
        ModeBarRelocate:ApplyLayout()
        local isActive = C_HouseEditor and C_HouseEditor.IsHouseEditorActive and C_HouseEditor.IsHouseEditorActive()
        ModeBarRelocate:PlayTransition(isActive)
    end)
end

if ADT and ADT.DebugPrint then
    ADT.DebugPrint("[ModeBarRelocate] 模块已加载")
end
