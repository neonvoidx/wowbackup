local addonName, addon = ...

local _, _, _, interfaceVersion = GetBuildInfo()
if (tonumber(interfaceVersion) or 0) < 120100 then
	return
end

addon.AuraCompat = addon.AuraCompat or {}
local AuraCompat = addon.AuraCompat

local C_AddOns = _G.C_AddOns
local C_Secrets = _G.C_Secrets
local CreateFrame = _G.CreateFrame
local GetTime = _G.GetTime
local UIParent = _G.UIParent
local issecretvalue = _G.issecretvalue

local AURA_CONTAINER_ADDON = "Blizzard_AuraContainer"
local DEFAULT_CONTAINER_TEMPLATE = "CustomAuraContainerTemplate"
local DEFAULT_BUTTON_TEMPLATE = "CustomAuraButtonTemplate"

AuraCompat.interfaceVersion = interfaceVersion
AuraCompat.containerAddonName = AURA_CONTAINER_ADDON
AuraCompat.defaultContainerTemplate = DEFAULT_CONTAINER_TEMPLATE
AuraCompat.defaultButtonTemplate = DEFAULT_BUTTON_TEMPLATE

function AuraCompat:IsSecretValue(value)
	return issecretvalue and issecretvalue(value) or false
end

function AuraCompat:ShouldAurasBeSecret()
	return C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() == true or false
end

function AuraCompat:CanReadAuraData()
	return not self:ShouldAurasBeSecret()
end

function AuraCompat:ShouldUseAuraContainer()
	return self:ShouldAurasBeSecret() and self:HasAuraContainerSupport()
end

function AuraCompat:EnsureAuraContainerLoaded()
	if self._auraContainerLoadChecked then return self._auraContainerLoadOK == true end
	self._auraContainerLoadChecked = true

	if not C_AddOns then
		self._auraContainerLoadOK = true
		return true
	end

	if C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(AURA_CONTAINER_ADDON) then
		self._auraContainerLoadOK = true
		return true
	end

	if C_AddOns.LoadAddOn then
		local ok, loaded = pcall(C_AddOns.LoadAddOn, AURA_CONTAINER_ADDON)
		self._auraContainerLoadOK = ok == true and loaded ~= false
		return self._auraContainerLoadOK
	end

	self._auraContainerLoadOK = false
	return false
end

function AuraCompat:HasAuraContainerSupport()
	if self._hasAuraContainerSupport ~= nil then return self._hasAuraContainerSupport == true end
	self._hasAuraContainerSupport = type(CreateFrame) == "function" and self:EnsureAuraContainerLoaded() == true
	return self._hasAuraContainerSupport == true
end

function AuraCompat:CreateAuraContainer(parent, name, template)
	if type(CreateFrame) ~= "function" or not self:EnsureAuraContainerLoaded() then return nil end
	parent = parent or UIParent
	template = template or DEFAULT_CONTAINER_TEMPLATE

	local ok, container = pcall(CreateFrame, "AuraContainer", name, parent, template)
	if ok then return container end
	return nil
end

function AuraCompat:CreateAuraButton(parent, name, template)
	if type(CreateFrame) ~= "function" or not parent or not self:EnsureAuraContainerLoaded() then return nil end
	template = template or DEFAULT_BUTTON_TEMPLATE

	local ok, button = pcall(CreateFrame, "AuraButton", name, parent, template)
	if ok then return button end
	return nil
end

function AuraCompat:ConfigureContainerFilters(container, filters)
	if not container then return false end
	if container.ClearAuraFilters then container:ClearAuraFilters() end
	if type(filters) ~= "table" then return true end

	for i = 1, #filters do
		local filter = filters[i]
		if type(filter) == "table" and filter.filterString and container.AddAuraFilter then
			container:AddAuraFilter(filter.filterString, filter.options)
		elseif type(filter) == "string" and container.AddAuraFilter then
			container:AddAuraFilter(filter)
		end
	end

	return true
end

function AuraCompat:ReparseAuraContainer(container, filters)
	return self:ConfigureContainerFilters(container, filters)
end

function AuraCompat:UpdateAuraContainer(container, filters)
	if not container then return false end
	if container.UpdateAllAuras then
		container:UpdateAllAuras()
		return true
	end
	return self:ReparseAuraContainer(container, filters)
end

function AuraCompat:RefreshAuraContainer(container, unit, configureFunc)
	if not container then return false end
	if unit ~= nil and container.SetUnit then container:SetUnit(unit) end
	if configureFunc then configureFunc(container, unit) end
	return true
end

function AuraCompat:ClearAuraContainer(container)
	if not container then return false end
	if container.SetEnabled then container:SetEnabled(false) end
	if container.ClearAuraFilters then container:ClearAuraFilters() end
	return true
end

function AuraCompat:MarkAurasBlocked(unit)
	self._restrictionSeen = true
	self._lastBlockedUnit = unit
	self._lastBlockedAuraInstanceID = nil
	self._lastBlockedAt = GetTime and GetTime() or nil
end

function AuraCompat:GetLastBlockedInfo()
	return self._restrictionSeen == true, self._lastBlockedUnit, self._lastBlockedAuraInstanceID, self._lastBlockedAt
end

function AuraCompat:RegisterRestrictionEvents(ownerFrame)
	if ownerFrame and ownerFrame.RegisterEvent then
		self._eventFrame = ownerFrame
	else
		if not self._eventFrame and type(CreateFrame) == "function" then self._eventFrame = CreateFrame("Frame") end
	end

	local frame = self._eventFrame
	if not frame then return false end
	if self._restrictionEventsRegistered then return true end

	if frame.RegisterEvent then pcall(frame.RegisterEvent, frame, "UNIT_AURA_BLOCKED") end
	if frame.SetScript then
		frame:SetScript("OnEvent", function(_, event, unit)
			if event == "UNIT_AURA_BLOCKED" then AuraCompat:MarkAurasBlocked(unit) end
		end)
	end

	self._restrictionEventsRegistered = true
	return true
end

AuraCompat:RegisterRestrictionEvents()
