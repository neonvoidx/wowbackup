local _, addon = ...
local E = {}
addon.FeatureEditor = E
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

function E:SetAtlas(texture, atlas, useSize)
	if addon.variables.isTBC then return addon.FeatureEditorArt.SetAtlas(texture, atlas, useSize) end
	if addon.variables.isForever and atlas == "common-icon-sound" then
		texture:SetTexture("Interface\\AddOns\\EnhanceQoL\\Assets\\PulseSound.tga")
		texture:SetTexCoord(0, 0.78125, 0, 0.78125)
		if useSize then texture:SetSize(100, 100) end
		return
	end
	texture:SetAtlas(atlas, useSize)
end

function E:Targets()
	local panels = addon.Aura and addon.Aura.CooldownPanels
	local quick = addon.QuickCast and addon.QuickCast.Editor
	local pulse = addon.CooldownPulse
	return {
		{ id = "panels", name = L["CooldownPanelOpenEditor"], icon = "Interface\\AddOns\\EnhanceQoL\\Assets\\NewSettings\\CastbarsCooldowns.tga", available = panels and panels.OpenBlizzardEditor, open = function() panels:OpenBlizzardEditor() end },
		{ id = "groups", name = L["CDLSpellGroupsOpenEditor"], icon = "Interface\\Icons\\INV_Misc_Book_11", available = panels and panels.OpenSpellGroupsEditor, open = function() panels:OpenSpellGroupsEditor() end },
		{ id = "quick", name = L["QuickCastOpenEditor"], icon = "Interface\\Icons\\INV_Misc_Gear_01", atlas = "common-icon-undo", available = quick and quick.Open, open = function() quick:Open() end },
		{ id = "pulse", name = L["CooldownPulse"], icon = "Interface\\Icons\\INV_Misc_PocketWatch_01", atlas = "common-icon-sound", available = pulse and pulse.OpenEditor, open = function() pulse:OpenEditor() end },
	}
end

function E:AttachTabs(frame, selected)
	if frame.featureEditorTabs then self:UpdateTabs(frame); return end
	frame.featureEditorTabs, frame.featureEditorSelected = {}, selected
	for index, target in ipairs(self:Targets()) do
		local tab = CreateFrame("Button", nil, frame, addon.variables.isTBC and "EQOLCooldownPanelsEditorSideTabTemplate" or "LargeSideTabButtonTemplate")
		tab:SetFrameLevel(frame:GetFrameLevel() + 10)
		if target.atlas then
			self:SetAtlas(tab.Icon, target.atlas)
		else tab.Icon:SetTexture(target.icon) end
		tab.Icon:SetSize(26, 26)
		tab.Icon:SetAlpha(target.id == selected and 1 or 0.55)
		if tab.SelectedTexture then tab.SelectedTexture:SetShown(target.id == selected) end
		tab.tooltipText = target.name
		local function click()
			local current = E:Targets()[index]
			if current.id == selected or not current.available then return end
			addon.functions.SaveSharedEditorPosition(frame)
			frame:Hide(); current.open()
		end
		if tab.SetCustomOnMouseUpHandler then
			tab:SetCustomOnMouseUpHandler(function(_, button, inside) if button == "LeftButton" and inside then click() end end)
		else
			tab:SetScript("OnClick", click)
			tab:SetScript("OnEnter", function() GameTooltip:SetOwner(tab, "ANCHOR_RIGHT"); GameTooltip:SetText(target.name); GameTooltip:Show() end)
			tab:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end
		frame.featureEditorTabs[index] = tab
	end
	frame:HookScript("OnShow", function() E:UpdateTabs(frame) end)
	self:UpdateTabs(frame)
end

function E:UpdateTabs(frame)
	local previous
	for index, target in ipairs(self:Targets()) do
		local tab = frame.featureEditorTabs[index]
		local shown = target.available ~= nil and target.available ~= false
		tab:SetShown(shown); tab:ClearAllPoints()
		if shown then
			if previous then tab:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -3) else tab:SetPoint("TOPLEFT", frame, "TOPRIGHT", 3, -28) end
			previous = tab
		end
	end
end
