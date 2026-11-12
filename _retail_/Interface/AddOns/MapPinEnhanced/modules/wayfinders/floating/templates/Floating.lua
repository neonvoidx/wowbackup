---@class MapPinEnhanced
local MapPinEnhanced = select(2, ...)
local Wayfinders = MapPinEnhanced:GetModule("Wayfinders")
local Options = MapPinEnhanced:GetModule("Options")

local scaleNearDistance, scaleFarDistance = 100, 750
local scaleRangeSet = false
local function SetUpDistanceScaleRange()
    if scaleRangeSet then return end
    scaleRangeSet = true
    -- Learned ability is fixed for this load; zone and mount changes do not alter scaling.
    local movement = MapPinEnhanced:GetModule("Navigation"):GetMovementCapabilities()
    if movement.canFly then
        scaleNearDistance, scaleFarDistance = 250, 1500
    elseif movement.groundSpeed > 7 then
        scaleNearDistance, scaleFarDistance = 200, 1000
    end
end
MapPinEnhanced:OnLoad(SetUpDistanceScaleRange)

local MIN_CLOSE_DISTANCE = 50
local MAX_CLOSE_DISTANCE = 200
local FALLBACK_DELAY = 1
local STATE_UPDATE_INTERVAL = 0.1
local NEEDLE_SETTLE_ANGLE = 0.0001 -- Radians; below a visible rotation at the needle's size.

---@class MapPinEnhancedWayfinderFloatingTemplate : Frame, MapPinEnhancedWayfinderDistanceMixin, MapPinEnhancedWayfinderDirectionMixin, MapPinEnhancedFadingFrameTemplate
---@field fallbackPosition Frame
---@field navigationOpacity Frame | { content: MapPinEnhancedWayfinderFloatingContentTemplate }
---@field content MapPinEnhancedWayfinderFloatingContentTemplate
---@field pin MapPinEnhancedBasePinTemplate
---@field needle MapPinEnhancedWayfinderFloatingNeedleTemplate
---@field titleContainer MapPinEnhancedWayfinderFloatingTitleTemplate
---@field readout MapPinEnhancedWayfinderReadoutTemplate
---@field displayType 'close' | 'far'?
---@field isFallbackClose boolean?
---@field presentationInitialized boolean?
---@field needleRotation number?
---@field newNeedleRotation number?
---@field blizzardArtworkAlpha table<Texture|FontString, number>?
---@field navFrame ScriptRegion?
---@field isClamped boolean?
---@field customDirection boolean?
---@field fallbackReadyAt number?
---@field lastNavigationTargetCheck number?
---@field navigationTargetDirty boolean?
---@field stateTicker FunctionContainer?
---@field trackingActive boolean?
---@field nativePositionReady boolean?
---@field navigationReady boolean?
---@field scaleWithDistance boolean?
---@field scaleDistance number?
MapPinEnhancedWayfinderFloatingMixin = CreateFromMixins(MapPinEnhancedWayfinderDistanceMixin,
    MapPinEnhancedWayfinderDirectionMixin)

local mathSin = math.sin
local mathCos = math.cos
local mathAtan2 = math.atan2
local DeltaLerp = DeltaLerp

---@param color PinColor
function MapPinEnhancedWayfinderFloatingMixin:SetColor(color)
    self.pin:SetColor(color)
    self.content:SetColor(self.pin:GetActiveStyleColor())
end

---@param texture string|number?
---@param usesAtlas boolean?
---@param useFrameMask boolean?
---@return boolean? hasIcon
function MapPinEnhancedWayfinderFloatingMixin:SetTexture(texture, usesAtlas, useFrameMask)
    if not texture then return end
    local hasIcon = self.pin:SetIconTexture(texture, usesAtlas, useFrameMask)
    self.content:SetColor(self.pin:GetActiveStyleColor())
    return hasIcon
end

---@param title string?
function MapPinEnhancedWayfinderFloatingMixin:SetTitle(title)
    self.content:SetTitle(title)
end

---@param distance number?
function MapPinEnhancedWayfinderFloatingMixin:UpdatePinScale(distance)
    self.scaleDistance = distance
    local scale = self.customDirection and 42 / 25 or 1
    if not self.customDirection and self.scaleWithDistance and distance then
        SetUpDistanceScaleRange()
        scale = 1 -
            0.25 * math.min(1, math.max(0, (distance - scaleNearDistance) / (scaleFarDistance - scaleNearDistance)))
    end
    if self.pin:GetScale() ~= scale then self.pin:SetScale(scale) end
    if self.content.beam:GetScale() ~= scale then self.content.beam:SetScale(scale) end
end

---@param enabled boolean
function MapPinEnhancedWayfinderFloatingMixin:SetScaleWithDistance(enabled)
    self.scaleWithDistance = enabled
    self:UpdatePinScale(self.scaleDistance)
end

function MapPinEnhancedWayfinderFloatingMixin:PrepareForTarget()
    MapPinEnhanced:UnregisterDraggableFrame(self.fallbackPosition)
    self:ResetDistanceReadout()
    self:ResetDirectionSampling()
    self.displayType = "far"
    self.isFallbackClose = nil
    self.presentationInitialized = nil
    self.customDirection = nil
    self:UpdatePinScale(nil)
    self.fallbackReadyAt = nil
    self.content:PrepareForTarget()
    self.needleRotation = nil
    self.newNeedleRotation = nil
    self.needle:SetRotation(0)
end

function MapPinEnhancedWayfinderFloatingMixin:SetLocation(mapID, x, y)
    self:SetTargetLocation(mapID, x, y)
    self:PrepareForTarget()
    self:RefreshNavigationTarget()
    self:RefreshState()
end

function MapPinEnhancedWayfinderFloatingMixin:RefreshNavigationTarget()
    self.lastNavigationTargetCheck = GetTime()
    self.navigationTargetDirty = nil
    self:SetCustomDirectionEnabled(not Wayfinders:CanFollowNavigationTarget(self.targetMapID, self.targetX, self.targetY))
end

---@param self MapPinEnhancedWayfinderFloatingTemplate
local function RegisterFallbackDragging(self)
    MapPinEnhanced:RegisterDraggableFrame(self.fallbackPosition, "floatingFallbackFrame", self.titleContainer, function()
        return not self.customDirection or self.visibilityHiding or not self.navigationReady or
            MapPinEnhanced:GetVar("frames", "floatingFallbackFrame", "locked") == true
    end)
end

---@param enabled boolean
function MapPinEnhancedWayfinderFloatingMixin:SetCustomDirectionEnabled(enabled)
    if self.customDirection == enabled then return end
    -- Save an in-progress drag before native guidance replaces the fallback anchor.
    MapPinEnhanced:UnregisterDraggableFrame(self.fallbackPosition)
    self.customDirection = enabled
    self:UpdatePinScale(self.scaleDistance)
    -- Native frame/path setup can lag behind tracking. Only show a persistent fallback.
    self.fallbackReadyAt = enabled and GetTime() + FALLBACK_DELAY or nil
    self.isClamped = nil
    self:ResetDirectionSampling()
    self.presentationInitialized = nil
    self:ClearAllPoints()
    if enabled then
        -- LibWindow needs inherited parent scale; the projected marker keeps its independent scale.
        local position = self.fallbackPosition
        position:ClearAllPoints()
        position:SetPoint("CENTER", WorldFrame, "CENTER", 0, 200 / position:GetEffectiveScale())
        RegisterFallbackDragging(self)
        if MapPinEnhanced:GetVar("frames", "floatingFallbackFrame", "point") then
            MapPinEnhanced:RestoreFrame(position)
        end
        self:SetPoint("CENTER", position, "CENTER")
        self.navigationReady = false
    elseif self.navFrame then
        self.navigationReady = true
        self:SetPoint("CENTER", SuperTrackedFrame, "CENTER")
    else
        self:ShutdownNavigationFrame()
    end
    self:RefreshNavigationVisibility()
end

function MapPinEnhancedWayfinderFloatingMixin:RefreshNavigationVisibility()
    -- Hide only the presentation so readiness sampling can restore it when the target recovers.
    -- Readiness uses visibility: the root alpha animation can restore a child's
    -- old alpha after native guidance replaces a hidden fallback during its fade.
    self.navigationOpacity:SetShown(self.navigationReady == true and self.presentationInitialized == true and
        (self.customDirection or SuperTrackedFrame:IsShown()) and
        (not self.customDirection or Round(self.scaleDistance or 1) > 0))
end

function MapPinEnhancedWayfinderFloatingMixin:SetupNavigationFrame()
    local navFrame = C_Navigation.GetFrame()
    if not self.customDirection then
        self.navigationReady = navFrame ~= nil
    end
    if self.navFrame == navFrame then
        self:RefreshNavigationVisibility()
        return
    end
    self.navFrame = navFrame
    self.isClamped = nil
    self.presentationInitialized = nil
    self:RefreshNavigationVisibility()
    if self.customDirection then return end

    if self.navFrame then
        self:ClearAllPoints()
        self:SetPoint("CENTER", SuperTrackedFrame, "CENTER")
    end
end

function MapPinEnhancedWayfinderFloatingMixin:ShutdownNavigationFrame()
    self:ClearAllPoints()
    self.navigationReady = false
    self:RefreshNavigationVisibility()
    self.navFrame = nil
    self.isClamped = nil
    self.presentationInitialized = nil
    self.content:Reset()
end

---@return FloatingPresentation
function MapPinEnhancedWayfinderFloatingMixin:GetPresentation()
    if self.customDirection then return self.isFallbackClose and "fallback-close" or "fallback" end
    if self.isClamped then return "clamped" end
    if not Options:GetOptionValue("Wayfinder.SwitchToCloseState") then return "far" end
    return self.displayType or "far"
end

function MapPinEnhancedWayfinderFloatingMixin:RefreshPresentation()
    self.content:SetPresentation(self:GetPresentation())
    -- Apply clamp/fallback layout before readiness reveals the container.
    self:RefreshNavigationVisibility()
end

---@param displayType 'close' | 'far'
function MapPinEnhancedWayfinderFloatingMixin:SetDisplayType(displayType)
    if self.displayType == displayType then return end
    self.displayType = displayType
    if not self.content:IsShown() or not self.presentationInitialized or
        self.isClamped and not self.customDirection then
        return
    end
    self:RefreshPresentation()
end

---@param distance number?
---@param timeToTarget number?
---@param closingSpeed number
---@param nextUpdateInterval number
---@param movementState DistanceMovementState
function MapPinEnhancedWayfinderFloatingMixin:OnDistanceUpdate(distance, timeToTarget, closingSpeed, nextUpdateInterval,
                                                               movementState)
    self:UpdatePinScale(distance)
    self:RefreshNavigationVisibility()
    -- The bearing fallback matches Arrow; native marker layout anticipates approach speed.
    local isFallbackClose = distance ~= nil and distance < 10
    local fallbackChanged = self.isFallbackClose ~= isFallbackClose
    self.isFallbackClose = isFallbackClose
    local closeDistance = MIN_CLOSE_DISTANCE
    if movementState == "approaching" then
        -- Like dynamic arrival, allow for travel before the next distance sample.
        closeDistance = math.min(MAX_CLOSE_DISTANCE,
            MIN_CLOSE_DISTANCE + math.max(0, closingSpeed) * nextUpdateInterval)
    end
    self:SetDisplayType(distance and distance < closeDistance and "close" or "far")
    if self.content:IsShown() and fallbackChanged and self.customDirection and self.presentationInitialized then
        self:RefreshPresentation()
    end
end

---@param elapsed number
function MapPinEnhancedWayfinderFloatingMixin:UpdateNeedlePosition(elapsed)
    local angle = self:SampleTargetAngle(elapsed)
    if self.customDirection then
        local ready = angle ~= nil and not self.fallbackReadyAt
        if self.navigationReady ~= ready then
            self.navigationReady = ready
            self:RefreshNavigationVisibility()
        end
    end
    if angle ~= nil then
        self.newNeedleRotation = angle
    end
end

---@param elapsed number
function MapPinEnhancedWayfinderFloatingMixin:AnimateNeedleRotation(elapsed)
    if not self.isClamped then return end
    local currentRotation = self.needleRotation or 0
    local targetRotation = self.newNeedleRotation or 0
    if currentRotation ~= targetRotation then
        local angleDifference = mathAtan2(
            mathSin(targetRotation - currentRotation),
            mathCos(targetRotation - currentRotation)
        )
        currentRotation = math.abs(angleDifference) < NEEDLE_SETTLE_ANGLE and targetRotation or
            DeltaLerp(currentRotation, currentRotation + angleDifference, .1, elapsed)
    end
    self.needleRotation = currentRotation
    -- The needle caches actual texture writes and restores them after presentation changes.
    self.needle:SetRotation(-currentRotation)
end

---@param self MapPinEnhancedWayfinderFloatingTemplate
local function RefreshNavigationReadiness(self)
    self:SetupNavigationFrame()
    local ready = self.navFrame ~= nil and C_Navigation.HasValidScreenPosition()
    if ready ~= self.nativePositionReady or self.fallbackReadyAt then self.lastNavigationTargetCheck = nil end
    self.nativePositionReady = ready
end

---@param self MapPinEnhancedWayfinderFloatingTemplate
---@param elapsed number
local function UpdateFloatingText(self, elapsed)
    if not self.visibilityFadeIn:IsPlaying() and not self.visibilityHiding then
        self.content:UpdateFarText(elapsed)
    end
end

--[==[@debug@
RefreshNavigationReadiness = MapPinEnhanced.profiler:WrapScope("Wayfinders.Floating.Readiness",
    RefreshNavigationReadiness)
UpdateFloatingText = MapPinEnhanced.profiler:WrapScope("Wayfinders.Floating.TextUpdate", UpdateFloatingText)
--@end-debug@]==]

-- Native anchoring moves an on-screen marker without an addon frame callback.
-- Content input/animation callbacks and the state timer wake visual work as needed.
function MapPinEnhancedWayfinderFloatingMixin:RefreshUpdateScript()
    local active = self.trackingActive and self:IsVisible() and not self.visibilityHiding and
        self.content:IsShown() and not self.content.visibilityHiding
    if active then
        if not self.stateTicker then
            self.stateTicker = C_Timer.NewTicker(STATE_UPDATE_INTERVAL, function() self:RefreshState() end)
        end
    elseif self.stateTicker then
        self.stateTicker:Cancel()
        self.stateTicker = nil
    end
    local needsUpdate = active and self.content:IsVisible() and
        (self.customDirection or self.isClamped or self.content:NeedsTextUpdate())
    local script = needsUpdate and self.OnUpdate or nil
    if self:GetScript("OnUpdate") ~= script then self:SetScript("OnUpdate", script) end
end

function MapPinEnhancedWayfinderFloatingMixin:RefreshState()
    self:RefreshUpdateScript()
    if not self.stateTicker then return end
    local now = GetTime()
    RefreshNavigationReadiness(self)
    -- Path-only bursts share a 100 ms validation cadence; marker motion stays live.
    -- Owned target/selection changes remain immediate, with a full-match recovery poll.
    if not self.lastNavigationTargetCheck or now - self.lastNavigationTargetCheck >= 1 or
        self.navigationTargetDirty and now - self.lastNavigationTargetCheck >= STATE_UPDATE_INTERVAL or
        self.fallbackReadyAt and now >= self.fallbackReadyAt then
        self:RefreshNavigationTarget()
    end
    if self.fallbackReadyAt and now >= self.fallbackReadyAt then self.fallbackReadyAt = nil end
    if self.customDirection then
        self.isClamped = true
        if not self.presentationInitialized then
            self.presentationInitialized = true
            self:RefreshPresentation()
        end
        -- Hidden fallback still probes for usable coordinates at the state cadence.
        self:UpdateNeedlePosition(0)
        self:RefreshUpdateScript()
        return
    end
    if not self.navFrame then
        self:RefreshUpdateScript()
        return
    end

    self:RefreshNativeClampedState()
end

function MapPinEnhancedWayfinderFloatingMixin:RefreshNativeClampedState()
    if not self.stateTicker or self.customDirection or not self.navFrame then return end
    -- PingNavFrame runs before Blizzard updates Arrow visibility for this frame.
    local clamped = C_Navigation.WasClampedToScreen()
    if self.isClamped ~= clamped or not self.presentationInitialized then
        self.isClamped = clamped
        self.presentationInitialized = true
        self:RefreshPresentation()
    end

    self:RefreshUpdateScript()
end

---@param elapsed number
function MapPinEnhancedWayfinderFloatingMixin:OnUpdate(elapsed)
    if not self.trackingActive or self.visibilityHiding or not self.content:IsVisible() or
        self.content.visibilityHiding then
        self:RefreshUpdateScript()
        return
    end
    if self.customDirection then
        self:UpdateNeedlePosition(elapsed)
        self:AnimateNeedleRotation(elapsed)
        return
    elseif self.isClamped then
        -- Blizzard owns screen-relative direction; only the fallback samples world bearings.
        local needle = self.needle
        local rotation = SuperTrackedFrame.Arrow:GetRotation()
        -- Fallback can change the requested angle while the native texture is hidden.
        if needle.rotation ~= rotation or needle.nativeRotation ~= rotation then needle:SetRotation(rotation) end
        return
    end
    if self.content:NeedsTextUpdate() then UpdateFloatingText(self, elapsed) end
    self:RefreshUpdateScript()
end

---@param shown boolean
function MapPinEnhancedWayfinderFloatingMixin:SetDirectionShown(shown)
    if shown and (not self.content:IsShown() or self.content.visibilityHiding) then
        self.lastNavigationTargetCheck = nil
        self.presentationInitialized = nil
    end
    self.content:SetShown(shown)
    self:RefreshState()
end

function MapPinEnhancedWayfinderFloatingMixin:OnLoad()
    self.fallbackPosition = CreateFrame("Frame", nil, UIParent,
        "MapPinEnhancedFloatingFallbackPositionTemplate")
    MapPinEnhancedFadingFrameMixin.SetupVisibilityFade(self)
    -- Navigation availability must not overwrite the root visibility fade.
    self.content = self.navigationOpacity.content
    self.content.owner = self
    self.pin = self.content.pin
    self.needle = self.content.needle
    self.titleContainer = self.content.title
    self.readout = self.content.readout

    -- Setup runs outside combat; later fallback activation only reuses the drag hooks.
    RegisterFallbackDragging(self)
    self.titleContainer:SetPropagateMouseClicks(false)
    self.pin:SetTracked(true)
    self:Reset()
    -- This native method runs only on clamp transitions, not every frame. The
    -- singleton hook stays installed; RefreshNativeClampedState ignores inactive
    -- tracking/fallback. The state timer also recovers missed or unavailable hooks.
    if SuperTrackedFrame.PingNavFrame then
        hooksecurefunc(SuperTrackedFrame, "PingNavFrame", function() self:RefreshNativeClampedState() end)
    end
end

function MapPinEnhancedWayfinderFloatingMixin:OnEvent(event)
    if event == "SUPER_TRACKING_PATH_UPDATED" then
        self.navigationTargetDirty = true
        return
    end
    self.lastNavigationTargetCheck = nil
    if event == "NAVIGATION_FRAME_DESTROYED" and not self.customDirection then
        self:ShutdownNavigationFrame()
    end
    self:RefreshState()
end

function MapPinEnhancedWayfinderFloatingMixin:OnShow()
    -- The facade also calls OnShow directly when replacing an active target.
    if not UIParent:IsShown() then return end
    self.trackingActive = true
    if self.customDirection then RegisterFallbackDragging(self) end
    self.lastNavigationTargetCheck = nil
    self:RegisterEvent("NAVIGATION_FRAME_CREATED")
    self:RegisterEvent("NAVIGATION_FRAME_DESTROYED")
    self:RegisterEvent("SUPER_TRACKING_CHANGED")
    self:RegisterEvent("SUPER_TRACKING_PATH_UPDATED")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    -- Leave native scripts, events and control fields alone. Region alpha survives
    -- Blizzard's Show/SetShown calls without a hook or a per-frame hiding worker.
    if not self.blizzardArtworkAlpha then
        self.blizzardArtworkAlpha = {}
        for _, region in ipairs({ SuperTrackedFrame.Icon, SuperTrackedFrame.IconBorder,
            SuperTrackedFrame.Arrow, SuperTrackedFrame.DistanceText }) do
            self.blizzardArtworkAlpha[region] = region:GetAlpha()
            region:SetAlpha(0)
        end
    end

    self:StartDistanceUpdates(self.readout,
        function(distance, timeToTarget, closingSpeed, nextUpdateInterval, movementState)
            self:OnDistanceUpdate(distance, timeToTarget, closingSpeed, nextUpdateInterval, movementState)
        end)
    self:RefreshState()
end

-- Restore native artwork when hiding starts. OnHide may run again after the fade;
-- only the display that still owns the saved alpha values may restore them.
function MapPinEnhancedWayfinderFloatingMixin:StopTracking()
    self.trackingActive = nil
    self:RefreshUpdateScript()
    MapPinEnhanced:UnregisterDraggableFrame(self.fallbackPosition)
    self.content:StopTextTransition()
    self:UnregisterEvent("NAVIGATION_FRAME_CREATED")
    self:UnregisterEvent("NAVIGATION_FRAME_DESTROYED")
    self:UnregisterEvent("SUPER_TRACKING_CHANGED")
    self:UnregisterEvent("SUPER_TRACKING_PATH_UPDATED")
    self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    self:StopDistanceUpdates()
    self:ResetDirectionSampling()
    if self.blizzardArtworkAlpha then
        for region, alpha in pairs(self.blizzardArtworkAlpha) do
            region:SetAlpha(alpha)
        end
        self.blizzardArtworkAlpha = nil
    end
end

function MapPinEnhancedWayfinderFloatingMixin:OnHide()
    self:StopTracking()
    -- Ancestor hiding suspends updates without discarding the active target.
    if self:IsShown() then return end
    self:ShutdownNavigationFrame()
    self:SetDestinationText(nil, nil)
    self:Reset()
end

function MapPinEnhancedWayfinderFloatingMixin:Reset()
    MapPinEnhanced:UnregisterDraggableFrame(self.fallbackPosition)
    self.displayType = "far"
    self.isFallbackClose = nil
    self.presentationInitialized = nil
    self.content:Reset()
    self.needleRotation = nil
    self.newNeedleRotation = nil
    self.needle:SetRotation(0)
    self.customDirection = nil
    self:UpdatePinScale(nil)
    self.fallbackReadyAt = nil
    self.lastNavigationTargetCheck = nil
    self.navigationTargetDirty = nil
    self.nativePositionReady = nil
end

---@param title string?
---@param description string?
function MapPinEnhancedWayfinderFloatingMixin:SetDestinationText(title, description)
    self.content:SetDestinationText(title, description)
end

--[==[@debug@
local floatingMethods = MapPinEnhancedWayfinderFloatingMixin --[[@as table<string, function>]]
for _, method in ipairs({ "OnUpdate", "RefreshState", "RefreshNativeClampedState", "RefreshNavigationTarget",
    "UpdateNeedlePosition", "AnimateNeedleRotation", "RefreshPresentation", "OnDistanceUpdate", "SetupNavigationFrame" }) do
    floatingMethods[method] = MapPinEnhanced.profiler:WrapScope("Wayfinders.Floating." .. method, floatingMethods
        [method])
end
--@end-debug@]==]
