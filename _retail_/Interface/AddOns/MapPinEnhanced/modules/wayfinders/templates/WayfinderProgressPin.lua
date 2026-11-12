---@class MapPinEnhanced
local MapPinEnhanced = select(2, ...)
local Pins = MapPinEnhanced:GetModule("Pins")

---@class MapPinEnhancedWayfinderProgressPin : Button
---@field pin Texture
---@field pinMask MaskTexture
---@field separator Texture
---@field destinationPin MapPinEnhancedBasePinTemplate
---@field active boolean?
---@field entry WayfinderProgressEntry?
MapPinEnhancedWayfinderProgressPinMixin = {}

---@param active boolean
function MapPinEnhancedWayfinderProgressPinMixin:SetActive(active)
    self.active = active
    local texture = self.entry and self.entry.icon
    local icon = Pins.PIN_ICONS[Pins:ResolveIcon(texture)]
    self.pin:SetTexture(icon and icon.icon or texture)
    -- Pooled entries can switch between catalog artwork and raw item/toy icons.
    self.pin:RemoveMaskTexture(self.pinMask)
    if texture and not icon then self.pin:AddMaskTexture(self.pinMask) end
    local destination = self.entry and self.entry.destination
    self.pin:SetShown(destination == nil)
    self.destinationPin:SetShown(destination ~= nil)
    self.destinationPin:SetColor(destination and destination.color)
    self.destinationPin:SetTracked(true)
    if destination then
        local hasIcon = self.destinationPin:SetIconTexture(destination.texture, destination.usesAtlas, destination.useFrameMask)
        if not hasIcon and destination.targetType == "blizzard" then
            self.destinationPin:SetIconTexture("Navigation-Tracked-Icon", true)
        end
    end
    self:UpdateActiveAlpha()
end

function MapPinEnhancedWayfinderProgressPinMixin:UpdateActiveAlpha()
    -- Show/reuse must restore both artwork regions from the current step state.
    local alpha = self.active and 1 or 0.5
    self.destinationPin:SetAlpha(alpha)
    self.pin:SetAlpha(alpha)
end

function MapPinEnhancedWayfinderProgressPinMixin:OnEnter()
    local entry = self.entry
    if not entry then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(entry.title, entry.r, entry.g, entry.b)
    GameTooltip:AddLine(entry.instruction, 1, 1, 1, true)
    GameTooltip:AddLine(entry.location, 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
end

function MapPinEnhancedWayfinderProgressPinMixin:OnLeave()
    if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
end

function MapPinEnhancedWayfinderProgressPinMixin:OnHide()
    self:OnLeave()
end
