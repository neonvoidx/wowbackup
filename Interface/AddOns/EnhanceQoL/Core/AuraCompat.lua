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

local REQUIRED_CONTAINER_METHODS = {
	"AddAuraGroup",
	"AddAuraSlot",
	"HasAuraGroup",
	"SetAuraGroupCandidateFilters",
	"SetAuraGroupLayout",
	"SetAuraGroupMaxFrameCount",
	"SetAuraGroupSortMethod",
	"SetAuraSlotCandidateFilters",
	"SetAuraSlotFilterString",
	"SetAuraSlotSortMethod",
	"SetAuraLayoutAnchorPoint",
	"SetAuraLayoutGrowthDirection",
	"SetAuraLayoutPadding",
	"SetAuraLayoutRowWidth",
	"SetEnabled",
	"SetUnit",
	"UpdateAllAuras",
}
local groupFiltersByContainer = setmetatable({}, { __mode = "k" })
local slotFramesByContainer = setmetatable({}, { __mode = "k" })

AuraCompat.interfaceVersion = interfaceVersion
AuraCompat.containerAddonName = AURA_CONTAINER_ADDON
AuraCompat.defaultContainerTemplate = DEFAULT_CONTAINER_TEMPLATE

local function CallContainerMethod(container, methodName, ...)
	local method = container and container[methodName]
	if type(method) ~= "function" then return false end
	return true, method(container, ...)
end

local function HasRequiredContainerMethods(container)
	if not container then return false end
	for i = 1, #REQUIRED_CONTAINER_METHODS do
		if type(container[REQUIRED_CONTAINER_METHODS[i]]) ~= "function" then return false end
	end
	return true
end

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
	-- AuraContainers are the only 12.1 renderer. Building them only after
	-- auras become secret defers forbidden-frame creation until combat.
	return self:HasAuraContainerSupport()
end

function AuraCompat:EnsureAuraContainerLoaded()
	if self._auraContainerLoadChecked then return self._auraContainerLoadOK == true end

	if not C_AddOns then
		self._auraContainerLoadChecked = true
		self._auraContainerLoadOK = true
		return true
	end

	if C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(AURA_CONTAINER_ADDON) then
		self._auraContainerLoadChecked = true
		self._auraContainerLoadOK = true
		return true
	end

	if C_AddOns.LoadAddOn then
		local loaded = C_AddOns.LoadAddOn(AURA_CONTAINER_ADDON)
		local isLoaded = loaded == true or (C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(AURA_CONTAINER_ADDON) == true)
		if isLoaded then
			self._auraContainerLoadChecked = true
			self._auraContainerLoadOK = true
			return true
		end
	end

	self._auraContainerLoadOK = false
	return false
end

function AuraCompat:HasAuraContainerSupport()
	if self._hasAuraContainerSupport ~= nil then return self._hasAuraContainerSupport == true end
	if type(CreateFrame) ~= "function" or not self:EnsureAuraContainerLoaded() then
		return false
	end

	local probe = CreateFrame("AuraContainer", nil, UIParent, DEFAULT_CONTAINER_TEMPLATE)
	if not HasRequiredContainerMethods(probe) then return false end
	self._hasAuraContainerSupport = true
	if probe then
		CallContainerMethod(probe, "SetEnabled", false)
		CallContainerMethod(probe, "Hide")
		self._supportProbe = probe
	end
	return self._hasAuraContainerSupport == true
end

function AuraCompat:CreateAuraContainer(parent, name, template)
	if type(CreateFrame) ~= "function" or not self:HasAuraContainerSupport() then return nil end
	parent = parent or UIParent
	template = template or DEFAULT_CONTAINER_TEMPLATE

	local container = CreateFrame("AuraContainer", name, parent, template)
	if HasRequiredContainerMethods(container) then return container end
	return nil
end

function AuraCompat:ConfigureAuraContainerLayout(container, options)
	if not HasRequiredContainerMethods(container) then return false end
	options = options or {}
	if type(options) ~= "table" then return false end

	if options.anchorPoint ~= nil and not CallContainerMethod(container, "SetAuraLayoutAnchorPoint", options.anchorPoint) then return false end
	if (options.horizontalGrowthDirection ~= nil or options.verticalGrowthDirection ~= nil)
		and (options.horizontalGrowthDirection == nil or options.verticalGrowthDirection == nil
			or not CallContainerMethod(container, "SetAuraLayoutGrowthDirection", options.horizontalGrowthDirection, options.verticalGrowthDirection)) then
		return false
	end
	if options.padding ~= nil then
		local padding = options.padding
		if type(padding) ~= "table"
			or not CallContainerMethod(container, "SetAuraLayoutPadding", padding.left or 0, padding.right or 0, padding.top or 0, padding.bottom or 0) then
			return false
		end
	end
	if options.rowWidth ~= nil and not CallContainerMethod(container, "SetAuraLayoutRowWidth", options.rowWidth) then return false end
	return true
end

function AuraCompat:UpdateAuraGroup(container, groupKey, options)
	if not HasRequiredContainerMethods(container) or type(groupKey) ~= "string" or groupKey == "" or type(options) ~= "table" then return false end
	local hasGroupOK, hasGroup = CallContainerMethod(container, "HasAuraGroup", groupKey)
	if not hasGroupOK or hasGroup ~= true then return false end

	if options.maxFrameCount ~= nil and not CallContainerMethod(container, "SetAuraGroupMaxFrameCount", groupKey, options.maxFrameCount) then return false end
	if options.candidateFilters ~= nil and not CallContainerMethod(container, "SetAuraGroupCandidateFilters", groupKey, options.candidateFilters) then return false end
	if options.sortMethod ~= nil or options.sortDirection ~= nil then
		if options.sortMethod == nil or options.sortDirection == nil
			or not CallContainerMethod(container, "SetAuraGroupSortMethod", groupKey, options.sortMethod, options.sortDirection) then
			return false
		end
	end
	if options.layout ~= nil and not CallContainerMethod(container, "SetAuraGroupLayout", groupKey, options.layout) then return false end
	return true
end

function AuraCompat:RegisterAuraGroup(container, groupKey, filterString, options)
	if not HasRequiredContainerMethods(container) or type(groupKey) ~= "string" or groupKey == "" or type(filterString) ~= "string" then return false end
	options = options or {}
	if type(options) ~= "table" then return false end

	local hasGroupOK, hasGroup = CallContainerMethod(container, "HasAuraGroup", groupKey)
	if not hasGroupOK then return false end
	local registeredFilters = groupFiltersByContainer[container]
	if not registeredFilters then
		registeredFilters = {}
		groupFiltersByContainer[container] = registeredFilters
	end

	if hasGroup == true then
		-- PTR4 exposes setters for group options, but intentionally no setter for
		-- a group's filter string and no public unregister/clear operation.
		if registeredFilters[groupKey] ~= filterString then return false end
		return self:UpdateAuraGroup(container, groupKey, options)
	end

	if not CallContainerMethod(container, "AddAuraGroup", groupKey, filterString, options) then return false end
	registeredFilters[groupKey] = filterString
	return true
end

function AuraCompat:RegisterAuraSlot(container, slotKey, filterString, options)
	if not HasRequiredContainerMethods(container) or type(slotKey) ~= "string" or slotKey == "" or type(filterString) ~= "string" then return nil end
	options = options or {}
	if type(options) ~= "table" then return nil end

	local slots = slotFramesByContainer[container]
	if not slots then
		slots = {}
		slotFramesByContainer[container] = slots
	end
	-- PTR4 exposes AddAuraSlot on the public container, but HasAuraSlot only on
	-- its private mixin. AuraCompat owns the slot keys, so the local cache is
	-- the public-side idempotence guard.
	if slots[slotKey] then return slots[slotKey] end

	local added, slotFrame = CallContainerMethod(container, "AddAuraSlot", slotKey, filterString, options)
	if not added or not slotFrame then return nil end
	slots[slotKey] = slotFrame
	return slotFrame
end

function AuraCompat:UpdateAuraSlot(container, slotKey, options)
	if not HasRequiredContainerMethods(container) or type(slotKey) ~= "string" or slotKey == "" or type(options) ~= "table" then return false end
	local slots = slotFramesByContainer[container]
	if not (slots and slots[slotKey]) then return false end
	if options.filterString ~= nil and not CallContainerMethod(container, "SetAuraSlotFilterString", slotKey, options.filterString) then return false end
	if options.candidateFilters ~= nil and not CallContainerMethod(container, "SetAuraSlotCandidateFilters", slotKey, options.candidateFilters) then return false end
	if options.sortMethod ~= nil or options.sortDirection ~= nil then
		if options.sortMethod == nil or options.sortDirection == nil
			or not CallContainerMethod(container, "SetAuraSlotSortMethod", slotKey, options.sortMethod, options.sortDirection) then
			return false
		end
	end
	return true
end

function AuraCompat:UpdateAuraContainer(container)
	if not HasRequiredContainerMethods(container) then return false end
	return CallContainerMethod(container, "UpdateAllAuras")
end

function AuraCompat:RefreshAuraContainer(container, unit, configureFunc)
	if not HasRequiredContainerMethods(container) then return false end
	if unit ~= nil and not CallContainerMethod(container, "SetUnit", unit) then return false end
	if configureFunc then
		if type(configureFunc) ~= "function" then return false end
		if configureFunc(container, unit) == false then return false end
	end
	if not CallContainerMethod(container, "SetEnabled", true) then return false end
	CallContainerMethod(container, "Show")
	return self:UpdateAuraContainer(container)
end

function AuraCompat:DisableAuraContainer(container)
	if not HasRequiredContainerMethods(container) then return false end
	if not CallContainerMethod(container, "SetEnabled", false) then return false end
	CallContainerMethod(container, "Hide")
	return true
end

-- Kept as a semantic compatibility alias. PTR4 deliberately does not expose
-- ClearAuraGroups, so this disables the container without discarding groups.
function AuraCompat:ClearAuraContainer(container)
	return self:DisableAuraContainer(container)
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

	if frame.RegisterEvent then frame:RegisterEvent("UNIT_AURA_BLOCKED") end
	if frame.SetScript then
		frame:SetScript("OnEvent", function(_, event, unit)
			if event == "UNIT_AURA_BLOCKED" then AuraCompat:MarkAurasBlocked(unit) end
		end)
	end

	self._restrictionEventsRegistered = true
	return true
end

AuraCompat:RegisterRestrictionEvents()
