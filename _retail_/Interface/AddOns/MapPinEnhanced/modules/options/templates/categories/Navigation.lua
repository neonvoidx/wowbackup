---@class MapPinEnhanced
local MapPinEnhanced = select(2, ...)
local Options = MapPinEnhanced:GetModule("Options")

---@class MapPinEnhancedOptionCategoryNavigationTemplate : MapPinEnhancedOptionCategoryBaseTemplate
---@field lock MapPinEnhancedFormElementTemplate
---@field unsubscribeSelection fun()?
MapPinEnhancedOptionCategoryNavigationMixin = CreateFromMixins(MapPinEnhancedOptionCategoryBaseMixin)

function MapPinEnhancedOptionCategoryNavigationMixin:RefreshEnabledOptions()
    MapPinEnhancedOptionCategoryBaseMixin.RefreshEnabledOptions(self)
    self.lock:SetShown(Options:GetOptionValue("Navigation.Enable") == true and
        Options:GetOptionValue("Wayfinder.Selection") == Options.WAYFINDER_SELECTION_FLOATING)
    if not self.lock:IsShown() then self.lock.searchHighlight:Hide() end
    if Options.frame then Options.frame:UpdateLayout() end
end

function MapPinEnhancedOptionCategoryNavigationMixin:OnShow()
    MapPinEnhancedOptionCategoryBaseMixin.OnShow(self)
    local showNumber = self.showNumber
    self.unsubscribeSelection = Options:SubscribeToOptionChanges("Wayfinder.Selection", function()
        -- Startup subscriptions can deliver their initial value after this show ends.
        if self.showNumber ~= showNumber then return end
        self:RefreshEnabledOptions()
    end)
end

function MapPinEnhancedOptionCategoryNavigationMixin:OnHide()
    MapPinEnhancedOptionCategoryBaseMixin.OnHide(self)
    if self.unsubscribeSelection then self.unsubscribeSelection() end
    self.unsubscribeSelection = nil
end
