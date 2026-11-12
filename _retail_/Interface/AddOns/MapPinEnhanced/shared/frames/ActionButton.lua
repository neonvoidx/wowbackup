---@class MapPinEnhancedActionButtonTemplate : Button
---@field icon Texture
---@field border Texture
---@field iconMask MaskTexture
---@field highlight Texture
MapPinEnhancedActionButtonMixin = {}

---@param texture string|number? file path or file ID; nil clears the icon
function MapPinEnhancedActionButtonMixin:SetIconTexture(texture)
    self.icon:SetTexture(texture)
end

function MapPinEnhancedActionButtonMixin:OnActionButtonLoad()
    self:GetPushedTexture():SetDrawLayer("OVERLAY")
end
