local addonName, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local Tracking = { key = "blizzardTrackingBarVisibility", elapsed = 0 }
addon.TrackingBarVisibility = Tracking

function Tracking.AreBlizzardSettingsHidden()
	if not addon.functions.IsResourceBarsAddonLoaded() then return false end
	local rb = addon.Aura and addon.Aura.ResourceBars
	local tracking = rb and rb.blizzardTracking
	return tracking and tracking.HasKillOwner and tracking.HasKillOwner(_G.StatusTrackingBarManager) or false
end

function Tracking:IsMouseOver()
	-- The two containers can be positioned independently in Edit Mode.
	for _, name in ipairs({ "MainStatusTrackingBarContainer", "SecondaryStatusTrackingBarContainer" }) do
		local frame = _G[name]
		if frame and frame:IsShown() and addon.functions.MouseIsOver(frame) then return true end
	end
	return false
end

function Tracking:Apply()
	local manager = _G.StatusTrackingBarManager
	if not manager or not self.config then return end
	local editing = _G.EditModeManagerFrame and _G.EditModeManagerFrame:IsShown()
	local shown = editing or addon.functions.ShouldShowVisibilityConfig(self.config, { isMouseOver = self.config.MOUSEOVER and self:IsMouseOver() or false })
	local alpha = shown and 1 or 0
	-- Fade only the manager; its children retain Blizzard's own transition alpha.
	if manager:GetAlpha() ~= alpha then manager:SetAlpha(alpha) end
end

function Tracking:Refresh()
	self.config = addon.functions.NormalizeUnitFrameVisibilityConfig(self.key)
	local manager = _G.StatusTrackingBarManager
	if not self.config then
		if self.watcher then self.watcher:Hide() end
		if self.managedFrame then self.managedFrame:SetAlpha(self.originalAlpha or 1) end
		self.managedFrame, self.originalAlpha = nil, nil
		return
	end
	if not manager then return end
	if self.managedFrame ~= manager then
		self.managedFrame = manager
		self.originalAlpha = manager:GetAlpha()
	end
	if not self.watcher then
		self.watcher = CreateFrame("Frame")
		self.watcher:SetScript("OnUpdate", function(_, elapsed)
			self.elapsed = self.elapsed + elapsed
			if self.elapsed < 0.1 then return end
			self.elapsed = 0
			self:Apply()
		end)
	end
	self.watcher:Show()
	self:Apply()
end

function Tracking:RegisterSettings(category, parentSection)
	local options, allowed = {}, {}
	for key, data in pairs(addon.functions.GetVisibilityRuleMetadata()) do
		if data.appliesTo and data.appliesTo.actionbar then
			allowed[key] = true
			options[#options + 1] = { value = key, text = data.label or key, order = data.order or 999 }
		end
	end
	table.sort(options, function(a, b) return a.order < b.order end)
	addon.functions.SettingsCreateMultiDropdown(category, {
		var = self.key,
		storage = false,
		text = L["visibilityScenarioGroupTitle"],
		desc = L["visibilityFrameRuleSelectionDesc"],
		options = options,
		emptyText = _G.NONE,
		newTagID = self.key,
		parentSection = parentSection,
		hiddenWhen = Tracking.AreBlizzardSettingsHidden,
		isSelectedFunc = function(key)
			local config = addon.functions.NormalizeUnitFrameVisibilityConfig(self.key)
			return config and config[key] == true or false
		end,
		setSelectedFunc = function(key, selected)
			if not allowed[key] then return end
			local config = addon.functions.NormalizeUnitFrameVisibilityConfig(self.key) or {}
			if selected and key == "ALWAYS_HIDDEN" then
				config = { ALWAYS_HIDDEN = true }
			elseif selected then
				config[key], config.ALWAYS_HIDDEN = true, nil
			else
				config[key] = nil
			end
			addon.functions.NormalizeVisibilityTargetRules(config, key)
			addon.functions.NormalizeUnitFrameVisibilityConfig(self.key, config)
			self:Refresh()
		end,
	})
end
