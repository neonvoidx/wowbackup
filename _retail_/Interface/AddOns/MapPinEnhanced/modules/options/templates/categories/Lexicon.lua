---@class MapPinEnhanced
local MapPinEnhanced = select(2, ...)

---@class MapPinEnhancedOptionLexiconKeybindTemplate : MapPinEnhancedFormElementTemplate
---@field child MapPinEnhancedKeybindTemplate
MapPinEnhancedOptionLexiconKeybindMixin = {}

function MapPinEnhancedOptionLexiconKeybindMixin:OnLoad()
    -- WoW owns binding persistence; this row is not an addon saved preference.
    self.child:Setup("CLICK MapPinEnhancedLexiconKeybindButton:LeftButton")
    self.label:SetFontObject(MapPinEnhancedFontOptionsLeft)
    self.description:SetFontObject(MapPinEnhancedFontOptionsHighlight)
    MapPinEnhancedFormFieldMixin.OnLoad(self)
end

---@param enabled boolean
function MapPinEnhancedOptionLexiconKeybindMixin:SetEnabledState(enabled)
    self.optionEnabled = enabled
    self.child:SetAvailable(enabled)
end
