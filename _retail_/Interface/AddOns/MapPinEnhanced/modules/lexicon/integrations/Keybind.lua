---@class MapPinEnhanced
local MapPinEnhanced = select(2, ...)
local Lexicon = MapPinEnhanced:GetModule("Lexicon")

---@class MapPinEnhancedLexiconKeybindButton : Button
MapPinEnhancedLexiconKeybindMixin = {}

function MapPinEnhancedLexiconKeybindMixin:OnClick()
    if Lexicon:IsEnabled() then Lexicon:Show() end
end
