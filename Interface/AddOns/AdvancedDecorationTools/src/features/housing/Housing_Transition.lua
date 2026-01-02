-- Housing_Transition.lua
-- 统一管理住宅编辑模式的进入/离开过渡动画（单一权威）

local ADDON_NAME, ADT = ...
if not ADT then return end

local Transition = {}
ADT.HousingTransition = Transition

local function GetRootCFG()
    return ADT.HousingInstrCFG and ADT.HousingInstrCFG.TransitionAnimations
end

local function GetKeyCFG(key)
    local cfg = GetRootCFG()
    local sub = (cfg and key and cfg[key]) or nil
    return cfg, sub
end

local function GetState(frame)
    if not frame then return nil end
    local st = frame.__ADT_TransitionState
    if not st then
        st = { state = "hidden", timer = nil }
        frame.__ADT_TransitionState = st
    end
    return st
end

local function SaveAnchors(frame)
    if not frame then return nil end
    local anchors = {}
    for i = 1, frame:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = frame:GetPoint(i)
        anchors[i] = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            x = x,
            y = y,
        }
    end
    return anchors
end

local function ApplyAnchorsWithOffset(frame, anchors, dy)
    if not (frame and anchors) then return end
    frame:ClearAllPoints()
    for _, a in ipairs(anchors) do
        frame:SetPoint(a.point, a.relativeTo, a.relativePoint, a.x, (a.y or 0) + (dy or 0))
    end
end

local function EaseValue(t, mode)
    t = math.max(0, math.min(1, t or 0))
    mode = (mode or "OUT"):upper()

    -- 高阶缓动曲线（更丝滑）
    if mode == "OUT_QUART" or mode == "OUTQUART" then
        -- 快速启动，缓慢着陆
        local u = 1 - t
        return 1 - u * u * u * u
    elseif mode == "OUT_QUINT" or mode == "OUTQUINT" then
        -- 更强的缓慢着陆
        local u = 1 - t
        return 1 - u * u * u * u * u
    elseif mode == "OUT_SINE" or mode == "OUTSINE" then
        -- 正弦曲线，最平滑的过渡
        return math.sin(t * math.pi / 2)
    elseif mode == "IN_SINE" or mode == "INSINE" then
        return 1 - math.cos(t * math.pi / 2)
    elseif mode == "IN_OUT_SINE" or mode == "INOUTSINE" then
        return -(math.cos(math.pi * t) - 1) / 2
    elseif mode == "IN_QUART" or mode == "INQUART" then
        return t * t * t * t
    elseif mode == "IN_QUINT" or mode == "INQUINT" then
        return t * t * t * t * t
    -- 原有曲线（保持向后兼容）
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
    -- 默认 OUT（二次缓动）
    return t * (2 - t)
end


local function CancelSlide(st)
    if st and st._slideGroup then
        st._slideGroup:Stop()
    end
    if st and st._anchorDriver then
        st._anchorDriver:SetScript("OnUpdate", nil)
    end
    if st then st._slideOnFinished = nil end
    if st then st._anchorSlide = nil end
end

local function NormalizeSmoothing(s)
    s = (s or "OUT"):upper()
    -- WoW Animation API 的 SetSmoothing 只支持 "IN", "OUT", "IN_OUT", "NONE"
    -- 将自定义曲线名映射回基础值
    if s == "INOUT" then return "IN_OUT" end
    if s == "OUTIN" then return "OUT_IN" end
    -- 高阶曲线回落到对应的基础曲线
    if s == "OUT_QUART" or s == "OUTQUART" or s == "OUT_QUINT" or s == "OUTQUINT" or s == "OUT_SINE" or s == "OUTSINE" then
        return "OUT"
    end
    if s == "IN_QUART" or s == "INQUART" or s == "IN_QUINT" or s == "INQUINT" or s == "IN_SINE" or s == "INSINE" then
        return "IN"
    end
    if s == "IN_OUT_SINE" or s == "INOUTSINE" then
        return "IN_OUT"
    end
    return s
end


local function EnsureSlideGroup(frame, st)
    if st._slideGroup and st._slideGroup._owner == frame then
        return st._slideGroup
    end
    local g = frame:CreateAnimationGroup()
    g._owner = frame
    g:SetLooping("NONE")
    local anim = g:CreateAnimation("Translation")
    g._anim = anim
    g:SetScript("OnFinished", function()
        if st._slideOnFinished then
            local cb = st._slideOnFinished
            st._slideOnFinished = nil
            cb()
        end
    end)
    st._slideGroup = g
    return g
end

local function StartAnchorSlide(frame, st, anchors, fromY, toY, duration, easing, onDone)
    if not (frame and st and anchors) then return end
    if not st._anchorDriver then
        st._anchorDriver = CreateFrame("Frame")
    end
    st._anchorSlide = {
        anchors = anchors,
        fromY = fromY,
        toY = toY,
        duration = math.max(0, tonumber(duration) or 0),
        elapsed = 0,
        easing = easing,
        onDone = onDone,
    }
    st._anchorDriver:SetScript("OnUpdate", function(_, dt)
        local s = st._anchorSlide
        if not s then
            st._anchorDriver:SetScript("OnUpdate", nil)
            return
        end
        if dt and dt > 0.05 then dt = 0.05 end
        s.elapsed = s.elapsed + (dt or 0)
        local t = (s.duration > 0) and math.min(1, s.elapsed / s.duration) or 1
        local e = EaseValue(t, s.easing)
        local y = s.fromY + (s.toY - s.fromY) * e
        ApplyAnchorsWithOffset(frame, s.anchors, y)
        if t >= 1 then
            st._anchorDriver:SetScript("OnUpdate", nil)
            st._anchorSlide = nil
            ApplyAnchorsWithOffset(frame, s.anchors, s.toY)
            if s.onDone then s.onDone() end
        end
    end)
end

local function CancelTimer(st)
    if st and st.timer then
        st.timer:Cancel()
        st.timer = nil
    end
end

local function StopFade(frame)
    if UIFrameFadeRemoveFrame then UIFrameFadeRemoveFrame(frame) end
    if frame and frame.fadeInfo then frame.fadeInfo = nil end
end

local function IsEnabled(cfg, sub)
    if not cfg or cfg.enabled == false then return false end
    if sub and sub.enabled == false then return false end
    return true
end

local function UseSlide(sub)
    if not sub then return false end
    return sub.motion == "slide"
end

local function GetSlideMode(sub)
    local mode = sub and sub.slideMode or "translate"
    mode = tostring(mode or "translate"):lower()
    if mode == "translation" then mode = "translate" end
    if mode == "anchor" then return "anchor" end
    return "translate"
end

local function SetClamp(frame, st, enabled)
    if not (frame and frame.SetClampedToScreen) then return end
    if st and st._clampOriginal == nil and frame.IsClampedToScreen then
        st._clampOriginal = frame:IsClampedToScreen()
    end
    frame:SetClampedToScreen(enabled)
end

local function RestoreClamp(frame, st)
    if not (frame and frame.SetClampedToScreen and st) then return end
    if st._clampOriginal ~= nil then
        frame:SetClampedToScreen(st._clampOriginal)
        st._clampOriginal = nil
    end
end

local function SetAnchorLock(frame, locked)
    if not frame then return end
    frame.__ADT_TransitionLockAnchor = locked and true or nil
end

function Transition:IsLocked(frame)
    return frame and frame.__ADT_TransitionLockAnchor or false
end

local function RunCallback(opts, key, frame)
    if opts and opts[key] then
        opts[key](frame)
    end
end

local function ResetCommon(frame, st)
    CancelTimer(st)
    CancelSlide(st)
    StopFade(frame)
    SetAnchorLock(frame, false)
    RestoreClamp(frame, st)
end

local function SetShown(frame, st, opts)
    frame:SetAlpha(1)
    frame:Show()
    st.state = "shown"
    SetAnchorLock(frame, false)
    RestoreClamp(frame, st)
    RunCallback(opts, "onShown", frame)
end

local function SetHidden(frame, st, opts, alpha)
    frame:SetAlpha(alpha or 1)
    frame:Hide()
    st.state = "hidden"
    SetAnchorLock(frame, false)
    RestoreClamp(frame, st)
    RunCallback(opts, "onHidden", frame)
end

-- 立即隐藏并重置 Alpha（用于非编辑器或强制隐藏）
function Transition:HideNow(frame)
    if not frame then return end
    local st = GetState(frame)
    ResetCommon(frame, st)
    SetHidden(frame, st, nil, 1)
end

-- 立即显示并重置 Alpha（用于非编辑器或强制展示）
function Transition:ShowNow(frame)
    if not frame then return end
    local st = GetState(frame)
    ResetCommon(frame, st)
    SetShown(frame, st, nil)
end

-- 预隐藏：避免“先出现再消失”的闪烁
function Transition:PrepareHidden(frame)
    if not frame then return end
    local st = GetState(frame)
    ResetCommon(frame, st)
    SetHidden(frame, st, nil, 0)
end

-- 进入动画（默认淡入；由配置控制时长与延迟）
function Transition:PlayEnter(frame, key, opts)
    if not frame then return end
    local st = GetState(frame)
    local cfg, sub = GetKeyCFG(key)
    local enabled = IsEnabled(cfg, sub)
    local useSlide = enabled and UseSlide(sub)
    local slideMode = useSlide and GetSlideMode(sub) or "translate"

    if st.state == "entering" and not (opts and opts.force) then
        return
    end

    if st.state == "shown" and not (opts and opts.force) then
        frame:Show()
        frame:SetAlpha(1)
        SetAnchorLock(frame, false)
        return
    end

    ResetCommon(frame, st)
    st.state = "entering"

    if opts and opts.onPrepare then opts.onPrepare(frame) end

    local delay = tonumber(sub and sub.enterDelay) or 0
    local duration = tonumber(sub and sub.enterDuration) or 0
    local offsetY = tonumber(sub and sub.offsetY) or 0
    local easing = sub and sub.smoothingIn or "OUT_QUART"

    -- 捕获最终锚点（作为滑动目标）
    st._baseAnchors = SaveAnchors(frame)

    local function Start()
        if st.state ~= "entering" then return end
        if useSlide and duration > 0 and offsetY ~= 0 and st._baseAnchors then
            SetAnchorLock(frame, true)
            SetClamp(frame, st, false)
            frame:SetAlpha(1)
            frame:Show()
            ApplyAnchorsWithOffset(frame, st._baseAnchors, offsetY)
            if slideMode == "anchor" then
                StartAnchorSlide(frame, st, st._baseAnchors, offsetY, 0, duration, easing, function()
                    ApplyAnchorsWithOffset(frame, st._baseAnchors, 0)
                    SetShown(frame, st, opts)
                end)
            else
                local g = EnsureSlideGroup(frame, st)
                local anim = g._anim
                local off = (0) - (offsetY or 0)
                anim:SetOffset(0, off)
                anim:SetDuration(math.max(0, tonumber(duration) or 0))
                anim:SetSmoothing(NormalizeSmoothing(easing))
                st._slideOnFinished = function()
                    ApplyAnchorsWithOffset(frame, st._baseAnchors, 0)
                    SetShown(frame, st, opts)
                end
                g:Play()
            end
        elseif enabled and duration > 0 and UIFrameFade then
            frame:SetAlpha(0)
            frame:Show()
            local fadeInfo = {
                mode = "IN",
                timeToFade = duration,
                startAlpha = 0,
                endAlpha = 1,
                finishedFunc = function()
                    SetShown(frame, st, opts)
                end,
            }
            UIFrameFade(frame, fadeInfo)
        else
            SetShown(frame, st, opts)
        end
    end

    if enabled and delay > 0 then
        frame:SetAlpha(0)
        frame:Hide()
        st.timer = C_Timer.After(delay, Start)
    else
        Start()
    end
end

-- 离开动画（默认淡出；由配置控制时长）
function Transition:PlayExit(frame, key, opts)
    if not frame then return end
    local st = GetState(frame)
    local cfg, sub = GetKeyCFG(key)
    local enabled = IsEnabled(cfg, sub)
    local useSlide = enabled and UseSlide(sub)
    local slideMode = useSlide and GetSlideMode(sub) or "translate"

    local duration = tonumber(sub and sub.leaveDuration) or 0
    local wasHidden = (st.state == "hidden") or (not frame:IsShown())
    local offsetY = tonumber(sub and sub.offsetY) or 0
    local easing = sub and sub.smoothingOut or "IN_SINE"

    ResetCommon(frame, st)

    local function Finish()
        if not frame then return end
        SetHidden(frame, st, opts, 1)
    end

    if wasHidden and not (opts and opts.force) then
        Finish()
        return
    end

    st.state = "exiting"

    if useSlide and duration > 0 and offsetY ~= 0 then
        if not st._baseAnchors then
            st._baseAnchors = SaveAnchors(frame)
        end
        SetAnchorLock(frame, true)
        SetClamp(frame, st, false)
        frame:SetAlpha(1)
        frame:Show()
        ApplyAnchorsWithOffset(frame, st._baseAnchors, 0)
        if slideMode == "anchor" then
            StartAnchorSlide(frame, st, st._baseAnchors, 0, offsetY, duration, easing, function()
                ApplyAnchorsWithOffset(frame, st._baseAnchors, 0)
                SetHidden(frame, st, opts, 1)
            end)
        else
            local g = EnsureSlideGroup(frame, st)
            local anim = g._anim
            local off = (offsetY or 0) - 0
            anim:SetOffset(0, off)
            anim:SetDuration(math.max(0, tonumber(duration) or 0))
            anim:SetSmoothing(NormalizeSmoothing(easing))
            st._slideOnFinished = function()
                ApplyAnchorsWithOffset(frame, st._baseAnchors, 0)
                SetHidden(frame, st, opts, 1)
            end
            g:Play()
        end
    elseif enabled and duration > 0 and UIFrameFade then
        local fadeInfo = {
            mode = "OUT",
            timeToFade = duration,
            startAlpha = frame:GetAlpha() or 1,
            endAlpha = 0,
            finishedFunc = Finish,
        }
        UIFrameFade(frame, fadeInfo)
    else
        Finish()
    end
end
