-- Housing_UIVisibilityEye.lua
-- 住宅编辑模式：Dock Header 左侧“眼睛按钮”（隐藏住宅编辑 UI + ADT UI）

local _, ADT = ...
if not ADT then return end

local Eye = {}
ADT.HousingUIVisibilityEye = Eye

local function GetConfig()
    local cfg = ADT.HousingInstrCFG or {}
    return cfg.EyeButton or {}
end

local function IsEditorActive()
    return C_HouseEditor and C_HouseEditor.IsHouseEditorActive and C_HouseEditor.IsHouseEditorActive()
end

local function IsInCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function GetHeader()
    local main = ADT.DockUI and ADT.DockUI.GetMainFrame and ADT.DockUI.GetMainFrame()
    return main and main.Header
end

local function GetEditorFrame()
    return _G.HouseEditorFrame or HouseEditorFrame
end

local function ApplyScale(btn)
    if not btn then return end
    local s = UIParent and UIParent.GetScale and UIParent:GetScale() or 1
    btn:SetScale(s)
end

local function ApplyAnchor(btn)
    local header = GetHeader()
    if not header then return false end
    local cfg = GetConfig()
    btn:ClearAllPoints()
    local p  = cfg.point or "RIGHT"
    local rp = cfg.relPoint or "LEFT"
    local x  = tonumber(cfg.offsetX) or -8
    local y  = tonumber(cfg.offsetY) or -2
    btn:SetPoint(p, header, rp, x, y)
    return true
end

local MODE_KEYS = {
    "ExpertDecorModeFrame",
    "BasicDecorModeFrame",
    "CustomizeModeFrame",
    "CleanupModeFrame",
    "LayoutModeFrame",
    "ExteriorCustomizationModeFrame",
}

local function CollectOverlayFrames()
    local hf = GetEditorFrame()
    if not hf then return {}, {} end

    local list = {}
    local seen = {}
    local forceMap = {}
    local function Add(f, forceHidden)
        if not f or seen[f] then return end
        seen[f] = true
        table.insert(list, f)
        if forceHidden then
            forceMap[f] = true
        end
    end

    for _, key in ipairs(MODE_KEYS) do
        local frm = hf[key]
        if frm then
            Add(frm.DecorCount, true)
            Add(frm.RoomCount, true)
            Add(frm.BudgetCount, true)
        end
    end

    return list, forceMap
end

local function EnsureButton()
    if Eye.Button then return Eye.Button end

    local header = GetHeader()
    if not header then return nil end

    local cfg = GetConfig()
    local parent = WorldFrame or UIParent
    local btn = CreateFrame("Button", "ADT_HousingUIVisibilityEye", parent)
    Eye.Button = btn

    local size = tonumber(cfg.size) or 36
    btn:SetSize(size, size)

    if cfg.strata then btn:SetFrameStrata(cfg.strata) end
    local baseLevel = header:GetFrameLevel() or 0
    local bias = tonumber(cfg.levelBias) or 10
    btn:SetFrameLevel(baseLevel + bias)

    btn:SetNormalAtlas(cfg.atlasNormal or "GM-icon-visible")
    btn:SetHighlightAtlas(cfg.atlasHover or "GM-icon-visible-hover")
    btn:SetPushedAtlas(cfg.atlasPressed or "GM-icon-visible-pressed")
    if btn.GetHighlightTexture then
        local alpha = tonumber(cfg.highlightAlpha)
        if alpha then btn:GetHighlightTexture():SetAlpha(alpha) end
    end

    ApplyScale(btn)
    ApplyAnchor(btn)

    btn:SetScript("OnClick", function()
        if IsInCombat() then return end
        Eye:ToggleUI()
    end)

    btn:Hide()
    return btn
end

function Eye:IsUIHidden()
    return self._uiHidden == true
end

function Eye:SetUIHidden(hidden)
    self._uiHidden = hidden and true or false
end

function Eye:CaptureEditorState(frame)
    if self._editorState or not frame then return end
    local state = {}
    state.alpha = frame.GetAlpha and frame:GetAlpha() or 1
    if frame.IsMouseEnabled then
        state.mouseEnabled = frame:IsMouseEnabled()
    end
    if frame.GetPropagateMouseClicks then
        state.propagateClicks = frame:GetPropagateMouseClicks()
    end
    if frame.GetPropagateMouseMotion then
        state.propagateMotion = frame:GetPropagateMouseMotion()
    end
    self._editorState = state
end

function Eye:CaptureUIParentState()
    if self._uiParentState or not UIParent then return end
    local state = {}
    if UIParent.IsShown then
        state.shown = UIParent:IsShown()
    end
    if UIParent.GetAlpha then
        state.alpha = UIParent:GetAlpha()
    end
    self._uiParentState = state
end

function Eye:ApplyEditorHidden(hidden)
    local frame = GetEditorFrame()
    if not frame then return end

    if hidden then
        self:CaptureEditorState(frame)
        if frame.SetAlpha then frame:SetAlpha(0) end
        if frame.EnableMouse then frame:EnableMouse(false) end
        if frame.SetPropagateMouseClicks then frame:SetPropagateMouseClicks(false) end
        if frame.SetPropagateMouseMotion then frame:SetPropagateMouseMotion(false) end
    else
        local state = self._editorState
        if state then
            if frame.SetAlpha and state.alpha ~= nil then frame:SetAlpha(state.alpha) end
            if frame.EnableMouse and state.mouseEnabled ~= nil then frame:EnableMouse(state.mouseEnabled) end
            if frame.SetPropagateMouseClicks and state.propagateClicks ~= nil then
                frame:SetPropagateMouseClicks(state.propagateClicks)
            end
            if frame.SetPropagateMouseMotion and state.propagateMotion ~= nil then
                frame:SetPropagateMouseMotion(state.propagateMotion)
            end
        end
        self._editorState = nil
    end
end

function Eye:ApplyOverlayHidden(hidden)
    local frames, forceMap = CollectOverlayFrames()
    self._overlayState = self._overlayState or {}
    for _, f in ipairs(frames) do
        if hidden then
            if not self._overlayState[f] then
                local st = {}
                if f.GetAlpha then st.alpha = f:GetAlpha() end
                if f.IsMouseEnabled then st.mouseEnabled = f:IsMouseEnabled() end
                if f.GetIgnoreParentAlpha then st.ignoreParentAlpha = f:GetIgnoreParentAlpha() end
                if f.GetIgnoreParentScale then st.ignoreParentScale = f:GetIgnoreParentScale() end
                self._overlayState[f] = st
            end
            if f.SetAlpha then f:SetAlpha(0) end
            if f.EnableMouse then f:EnableMouse(false) end
            if f.SetIgnoreParentAlpha then f:SetIgnoreParentAlpha(false) end
            if f.SetIgnoreParentScale then f:SetIgnoreParentScale(false) end
            if forceMap and forceMap[f] then
                f._ADTForceHidden = true
            end
        else
            local st = self._overlayState[f]
            if st then
                if f.SetAlpha and st.alpha ~= nil then f:SetAlpha(st.alpha) end
                if f.EnableMouse and st.mouseEnabled ~= nil then f:EnableMouse(st.mouseEnabled) end
                if f.SetIgnoreParentAlpha and st.ignoreParentAlpha ~= nil then f:SetIgnoreParentAlpha(st.ignoreParentAlpha) end
                if f.SetIgnoreParentScale and st.ignoreParentScale ~= nil then f:SetIgnoreParentScale(st.ignoreParentScale) end
            end
            f._ADTForceHidden = nil
            self._overlayState[f] = nil
        end
    end
end

function Eye:ApplyUIParentHidden(hidden)
    if not SetUIVisibility then return end

    if hidden then
        self:CaptureUIParentState()
        SetUIVisibility(false)
    else
        local state = self._uiParentState
        if not state or state.shown ~= false then
            SetUIVisibility(true)
        end
        self._uiParentState = nil
    end
end

function Eye:ToggleUI()
    if not SetUIVisibility then return end
    if not IsEditorActive() then return end
    if IsInCombat() then return end

    if self:IsUIHidden() then
        self:ApplyUIParentHidden(false)
        self:ApplyEditorHidden(false)
        self:ApplyOverlayHidden(false)
        self:SetUIHidden(false)
    else
        self:ApplyUIParentHidden(true)
        self:ApplyEditorHidden(true)
        self:ApplyOverlayHidden(true)
        self:SetUIHidden(true)
    end
end

function Eye:UpdateVisibility()
    local btn = EnsureButton()
    if not btn then
        if not self._retryPending then
            self._retryPending = true
            C_Timer.After(0.2, function()
                Eye._retryPending = false
                Eye:UpdateVisibility()
            end)
        end
        return
    end

    ApplyAnchor(btn)

    if IsEditorActive() and not IsInCombat() then
        btn:Show()
    else
        btn:Hide()
        if not IsEditorActive() then
            if self:IsUIHidden() then
                self:ApplyUIParentHidden(false)
                self:ApplyEditorHidden(false)
                self:ApplyOverlayHidden(false)
            end
            self:SetUIHidden(false)
        end
    end
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("HOUSE_EDITOR_MODE_CHANGED")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:RegisterEvent("UI_SCALE_CHANGED")
watcher:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        local btn = EnsureButton()
        if btn then btn:Hide() end
        return
    end
    if event == "UI_SCALE_CHANGED" then
        ApplyScale(Eye.Button)
        return
    end

    C_Timer.After(0.05, function()
        Eye:UpdateVisibility()
    end)
end)

C_Timer.After(0.2, function()
    Eye:UpdateVisibility()
end)
