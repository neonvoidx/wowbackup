local addonName, addon = ...

addon.DynamicAnchors = addon.DynamicAnchors or {}
local DynamicAnchors = addon.DynamicAnchors
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

DynamicAnchors.SCHEMA_VERSION = 3
DynamicAnchors.MAX_CANDIDATES = 6
DynamicAnchors.targets = DynamicAnchors.targets or {}
DynamicAnchors.consumers = DynamicAnchors.consumers or {}
DynamicAnchors.diagnostics = DynamicAnchors.diagnostics or {}
DynamicAnchors.pendingConsumers = DynamicAnchors.pendingConsumers or {}
DynamicAnchors.previewCandidates = DynamicAnchors.previewCandidates or {}

local VALID_POINTS = {
	TOPLEFT = true,
	TOP = true,
	TOPRIGHT = true,
	LEFT = true,
	CENTER = true,
	RIGHT = true,
	BOTTOMLEFT = true,
	BOTTOM = true,
	BOTTOMRIGHT = true,
}

local function normalizePoint(value, fallback)
	value = type(value) == "string" and string.upper(value) or nil
	if value and VALID_POINTS[value] then return value end
	fallback = type(fallback) == "string" and string.upper(fallback) or "CENTER"
	return VALID_POINTS[fallback] and fallback or "CENTER"
end

local function normalizePlacement(value, fallback)
	value = type(value) == "table" and value or {}
	fallback = type(fallback) == "table" and fallback or {}
	local point = normalizePoint(value.point, fallback.point or "TOPLEFT")
	return {
		point = point,
		relativePoint = normalizePoint(value.relativePoint, fallback.relativePoint or point),
		x = tonumber(value.x) or tonumber(fallback.x) or 0,
		y = tonumber(value.y) or tonumber(fallback.y) or 0,
	}
end

local CONDITION_TYPES = { CLASS = true, SPEC = true, ROLE = true, TALENT = true, RAID_SIZE = true }
local function normalizeConditionNode(node, fallbackId, depth, state)
	if type(node) ~= "table" or depth > 4 or state.count >= 32 then return nil end
	state.count = state.count + 1
	local nodeId = type(node.id) == "string" and node.id ~= "" and node.id or fallbackId
	if node.nodeType == "condition" or node.type == "condition" then
		local conditionType = type(node.conditionType) == "string" and string.upper(node.conditionType) or nil
		if not CONDITION_TYPES[conditionType] then return nil end
		local operator = type(node.operator) == "string" and string.upper(node.operator) or "IS"
		if conditionType == "TALENT" then
			operator = operator == "NOT_KNOWN" and "NOT_KNOWN" or "KNOWN"
		elseif conditionType == "RAID_SIZE" then
			operator = operator == "AT_LEAST" and "AT_LEAST" or "AT_MOST"
		elseif conditionType == "CLASS" or conditionType == "SPEC" or conditionType == "ROLE" then
			operator = (operator == "NOT_ANY_OF" or operator == "IS_NOT") and "NOT_ANY_OF" or "ANY_OF"
		else
			operator = operator == "IS_NOT" and "IS_NOT" or "IS"
		end
		local value = node.value
		if conditionType == "CLASS" or conditionType == "SPEC" or conditionType == "ROLE" then
			local values = type(node.value) == "table" and node.value or { node.value }
			value = {}
			local seen = {}
			for _, entry in ipairs(values) do
				entry = conditionType == "SPEC" and tonumber(entry) or entry
				if entry ~= nil and entry ~= "" and not seen[entry] then
					seen[entry] = true
					value[#value + 1] = entry
				end
			end
		end
		if conditionType == "TALENT" then value = tonumber(node.value) end
		if conditionType == "RAID_SIZE" then value = math.max(1, math.min(40, math.floor(tonumber(node.value) or 20))) end
		return { nodeType = "condition", id = nodeId, conditionType = conditionType, operator = operator, value = value }
	end
	local group = { nodeType = "group", id = nodeId, operator = node.operator == "OR" and "OR" or "AND", children = {} }
	for index, child in ipairs(type(node.children) == "table" and node.children or {}) do
		local normalized = normalizeConditionNode(child, nodeId .. "-" .. tostring(index), depth + 1, state)
		if normalized then group.children[#group.children + 1] = normalized end
	end
	return group
end

local function normalizeConditions(conditions, candidateId)
	conditions = type(conditions) == "table" and conditions or {}
	if conditions.nodeType == "group" or conditions.nodeType == "condition" or type(conditions.children) == "table" then
		return normalizeConditionNode(conditions, candidateId .. "-conditions", 0, { count = 0 }) or { nodeType = "group", id = candidateId .. "-conditions", operator = "AND", children = {} }
	end
	local root = { nodeType = "group", id = candidateId .. "-conditions", operator = "AND", children = {} }
	local function add(conditionType, operator, value)
		if value == nil or value == "" then return end
		root.children[#root.children + 1] = {
			nodeType = "condition",
			id = root.id .. "-" .. tostring(#root.children + 1),
			conditionType = conditionType,
			operator = operator,
			value = value,
		}
	end
	add("CLASS", "IS", conditions.class)
	add("SPEC", "IS", tonumber(conditions.specID))
	add("ROLE", "IS", conditions.role)
	add("TALENT", conditions.talentMode == "NOT_KNOWN" and "NOT_KNOWN" or "KNOWN", tonumber(conditions.talentSpellID))
	return root
end

local function canMatchRelativeWidth(targetId)
	return type(targetId) == "string" and targetId ~= "core:uiparent"
end

local function copyCandidate(candidate, index)
	candidate = type(candidate) == "table" and candidate or {}
	local candidateId = type(candidate.id) == "string" and candidate.id or ("candidate-" .. tostring(index))
	local targetId = type(candidate.targetId) == "string" and candidate.targetId or nil
	local allowsWidthMatch = canMatchRelativeWidth(targetId)
	return {
		id = candidateId,
		targetId = targetId,
		placement = normalizePlacement(candidate.placement),
		matchRelativeWidth = allowsWidthMatch and candidate.matchRelativeWidth == true,
		matchRelativeWidthOffset = allowsWidthMatch and (tonumber(candidate.matchRelativeWidthOffset) or 0) or 0,
		conditions = normalizeConditions(candidate.conditions, candidateId),
	}
end

local function getProfileStore()
	addon.db = addon.db or {}
	addon.db.dynamicAnchorProfiles = type(addon.db.dynamicAnchorProfiles) == "table" and addon.db.dynamicAnchorProfiles or {}
	return addon.db.dynamicAnchorProfiles
end

function DynamicAnchors:GetProfiles() return getProfileStore() end

function DynamicAnchors:CanMatchRelativeWidth(targetId) return canMatchRelativeWidth(targetId) end

function DynamicAnchors:GetFrameAssignments()
	addon.db = addon.db or {}
	addon.db.dynamicAnchorAssignments = type(addon.db.dynamicAnchorAssignments) == "table" and addon.db.dynamicAnchorAssignments or {}
	return addon.db.dynamicAnchorAssignments
end

function DynamicAnchors:GetFrameAssignment(consumerId, create)
	local assignments = self:GetFrameAssignments()
	if create and type(assignments[consumerId]) ~= "table" then assignments[consumerId] = { enabled = false } end
	return assignments[consumerId]
end

function DynamicAnchors:IsFrameAssignmentEnabled(consumerId)
	local assignment = self:GetFrameAssignment(consumerId, false)
	return assignment and assignment.enabled == true and assignment.profileId and self:GetProfile(assignment.profileId) ~= nil or false
end

DynamicAnchors._simpleTargetHookedFrames = DynamicAnchors._simpleTargetHookedFrames or setmetatable({}, { __mode = "k" })

function DynamicAnchors:EnsureSimpleTargetHooks(targetId, frame)
	if type(targetId) ~= "string" or targetId == "" or not frame or not frame.HookScript then return end
	local hookState = self._simpleTargetHookedFrames[frame]
	if type(hookState) == "table" then
		hookState.targetIds[targetId] = true
		return
	end
	hookState = { targetIds = { [targetId] = true } }
	local function changed()
		for registeredTargetId in pairs(hookState.targetIds) do
			self:NotifyTargetChanged(registeredTargetId, "SIMPLE_TARGET_GEOMETRY", registeredTargetId)
		end
	end
	local okSize = pcall(frame.HookScript, frame, "OnSizeChanged", changed)
	local okShow = pcall(frame.HookScript, frame, "OnShow", changed)
	local okHide = pcall(frame.HookScript, frame, "OnHide", changed)
	if okSize or okShow or okHide then self._simpleTargetHookedFrames[frame] = hookState end
end

function DynamicAnchors:RegisterSimpleFrame(definition)
	if type(definition) ~= "table" or type(definition.id) ~= "string" or definition.id == "" then return false end
	local currentTarget = self.targets[definition.id]
	local currentConsumer = self.consumers[definition.id]
	if currentTarget and currentTarget.owner ~= definition.owner then return false end
	if currentConsumer and currentConsumer.owner ~= definition.owner then return false end
	local targetRegistered = self:RegisterTarget({
		id = definition.id,
		owner = definition.owner,
		consumerId = definition.id,
		label = definition.label,
		menuGroup = definition.menuGroup,
		menuGroupLabel = definition.menuGroupLabel,
		menuGroupOrder = definition.menuGroupOrder,
		resolve = function()
			local frame = type(definition.getFrame) == "function" and definition.getFrame() or nil
			if frame then self:EnsureSimpleTargetHooks(definition.id, frame) end
			local available = frame ~= nil and (type(definition.isAvailable) ~= "function" or definition.isAvailable(frame) == true)
			return frame, { available = available, reason = available and nil or "FRAME_NOT_CREATED" }
		end,
	})
	local consumerRegistered = self:RegisterConsumer({
		id = definition.id,
		owner = definition.owner,
		label = definition.label,
		ensureRule = function() return self:GetFrameAssignment(definition.id, true) end,
		getRule = function()
			local assignment = self:GetFrameAssignment(definition.id, false)
			if assignment then self:EnsureAssignmentProfile(assignment, definition.label) end
			return assignment
		end,
		apply = function()
			if self:IsFrameAssignmentEnabled(definition.id) and type(definition.apply) == "function" then definition.apply() end
		end,
	})
	return targetRegistered == true and consumerRegistered == true
end

function DynamicAnchors:GetSimpleFrameWinner(consumerId)
	if not self:IsFrameAssignmentEnabled(consumerId) then return nil end
	local result = self:ResolveConsumer(consumerId, { mode = "LIVE" })
	return result and result.winner or nil
end

function DynamicAnchors:AddEditModeAssignmentSettings(settings, settingType, options)
	if type(settings) ~= "table" or type(settingType) ~= "table" or type(options) ~= "table" then return end
	local consumerId = options.consumerId
	local parentId = options.parentId
	local refresh = type(options.refresh) == "function" and options.refresh or function() end
	local function refreshSettingValues()
		local internal = addon.EditModeLib and addon.EditModeLib.internal
		if internal and internal.RefreshSettingValues then internal:RefreshSettingValues() end
	end
	local function assignment(create) return self:GetFrameAssignment(consumerId, create) end
	local enabledSetting = {
		name = L["Enable Dynamic Anchoring"],
		kind = settingType.Checkbox,
		field = "dynamicAnchorEnabled",
		parentId = parentId,
		newTagID = options.enabledNewTagID,
		default = false,
		get = function() local value = assignment(false) return value and value.enabled == true or false end,
		set = function(_, value)
			local current = assignment(true)
			current.enabled = value == true
			if current.enabled and not current.profileId then
				local profiles = self:GetProfileOptions()
				current.profileId = profiles[1] and profiles[1].value or nil
			end
			self:RefreshRaidSizeConsumerTracking()
			refresh(true)
			refreshSettingValues()
		end,
	}
	local profileSetting = {
		name = L["Dynamic Anchor Profile"],
		kind = settingType.Dropdown,
		field = "dynamicAnchorProfile",
		parentId = parentId,
		newTagID = options.profileNewTagID,
		height = 180,
		get = function() local value = assignment(false) return value and value.profileId or nil end,
		set = function(_, value)
			assignment(true).profileId = value
			self:RefreshRaidSizeConsumerTracking()
			refresh(false)
			refreshSettingValues()
		end,
		generator = function(_, root)
			for _, option in ipairs(self:GetProfileOptions()) do
				root:CreateRadio(option.label, function() local value = assignment(false) return value and value.profileId == option.value end, function()
					assignment(true).profileId = option.value
					self:RefreshRaidSizeConsumerTracking()
					refresh(false)
					refreshSettingValues()
				end)
			end
		end,
		isShown = function() local value = assignment(false) return value and value.enabled == true or false end,
	}
	local insertAt = tonumber(options.insertAt)
	if options.insertAfterId then
		for index, setting in ipairs(settings) do
			if setting.id == options.insertAfterId then insertAt = index + 1 break end
		end
	end
	if insertAt then
		table.insert(settings, insertAt, profileSetting)
		table.insert(settings, insertAt, enabledSetting)
	else
		settings[#settings + 1] = enabledSetting
		settings[#settings + 1] = profileSetting
	end
	local staticFields = options.staticFields or {}
	for _, setting in ipairs(settings) do
		if staticFields[setting.field] then
			local previous = setting.isShown
			setting.isShown = function(...)
				if self:IsFrameAssignmentEnabled(consumerId) then return false end
				return type(previous) ~= "function" or previous(...)
			end
		end
	end
end

function DynamicAnchors:GetProfile(profileId)
	return type(profileId) == "string" and getProfileStore()[profileId] or nil
end

function DynamicAnchors:CreateProfile(name, sourceRule)
	local profiles = getProfileStore()
	local index = 1
	while profiles["profile-" .. tostring(index)] do index = index + 1 end
	local profileId = "profile-" .. tostring(index)
	local profile = self:NormalizeRule(sourceRule)
	profile.enabled = true
	profile.name = type(name) == "string" and name ~= "" and name or ("Profile " .. tostring(index))
	profiles[profileId] = profile
	self:QueueAllConsumers("PROFILE_CREATED")
	return profileId, profile
end

function DynamicAnchors:DeleteProfile(profileId)
	local profiles = getProfileStore()
	if not profiles[profileId] then return false end
	for _, definition in pairs(self.consumers) do
		local assignment
		if type(definition.getRule) == "function" then
			local ok, value = pcall(definition.getRule, definition)
			if ok then assignment = value end
		end
		if type(assignment) == "table" and assignment.profileId == profileId then
			assignment.enabled = false
			assignment.profileId = nil
		end
	end
	profiles[profileId] = nil
	self:QueueAllConsumers("PROFILE_DELETED")
	return true
end

function DynamicAnchors:GetProfileOptions()
	local options = {}
	for profileId, profile in pairs(getProfileStore()) do
		options[#options + 1] = { value = profileId, label = type(profile.name) == "string" and profile.name ~= "" and profile.name or profileId }
	end
	table.sort(options, function(a, b) return tostring(a.label) < tostring(b.label) end)
	return options
end

function DynamicAnchors:EnsureAssignmentProfile(assignment, defaultName)
	if type(assignment) ~= "table" then return nil end
	if assignment.profileId and self:GetProfile(assignment.profileId) then return assignment.profileId end
	if type(assignment.candidates) == "table" and #assignment.candidates > 0 then
		local profileId = self:CreateProfile(defaultName, assignment)
		assignment.profileId = profileId
		assignment.candidates = nil
		assignment.finalFallback = nil
		assignment.schemaVersion = nil
		return profileId
	end
	return nil
end

function DynamicAnchors:NormalizeRule(rule)
	rule = type(rule) == "table" and rule or {}
	local normalized = {
		schemaVersion = self.SCHEMA_VERSION,
		enabled = rule.enabled == true,
		candidateCount = math.max(1, math.min(self.MAX_CANDIDATES, math.floor(tonumber(rule.candidateCount) or math.max(1, #(type(rule.candidates) == "table" and rule.candidates or {}))))),
		candidates = {},
		finalFallback = {
			targetId = "core:uiparent",
			placement = normalizePlacement(rule.finalFallback and rule.finalFallback.placement, {
				point = "CENTER",
				relativePoint = "CENTER",
			}),
		},
	}
	for index, candidate in ipairs(type(rule.candidates) == "table" and rule.candidates or {}) do
		if #normalized.candidates >= self.MAX_CANDIDATES then break end
		local copied = copyCandidate(candidate, index)
		if copied.targetId then normalized.candidates[#normalized.candidates + 1] = copied end
	end
	return normalized
end

function DynamicAnchors:EnsureCandidateConditionRoot(candidate)
	if type(candidate) ~= "table" then return nil end
	candidate.conditions = normalizeConditions(candidate.conditions, candidate.id or "candidate")
	return candidate.conditions
end

local function findConditionNode(root, nodeId, parent)
	if type(root) ~= "table" then return nil end
	if root.id == nodeId then return root, parent end
	for _, child in ipairs(root.children or {}) do
		local found, foundParent = findConditionNode(child, nodeId, root)
		if found then return found, foundParent end
	end
end

function DynamicAnchors:FindConditionNode(candidate, nodeId)
	return findConditionNode(self:EnsureCandidateConditionRoot(candidate), nodeId)
end

function DynamicAnchors:CreateConditionNode(conditionType)
	self._conditionSequence = (self._conditionSequence or 0) + 1
	conditionType = CONDITION_TYPES[conditionType] and conditionType or "CLASS"
	local defaults = { CLASS = "", SPEC = 0, ROLE = "", TALENT = 0, RAID_SIZE = 20 }
	return {
		nodeType = "condition",
		id = "condition-" .. tostring(GetTime and math.floor(GetTime() * 1000) or 0) .. "-" .. tostring(self._conditionSequence),
		conditionType = conditionType,
		operator = conditionType == "TALENT" and "KNOWN" or conditionType == "RAID_SIZE" and "AT_MOST" or (conditionType == "CLASS" or conditionType == "SPEC" or conditionType == "ROLE") and "ANY_OF" or "IS",
		value = defaults[conditionType],
	}
end

function DynamicAnchors:AddConditionNode(candidate, parentId, conditionType)
	local parent = self:FindConditionNode(candidate, parentId)
	if not parent or parent.nodeType ~= "group" then return nil end
	local node = self:CreateConditionNode(conditionType)
	parent.children[#parent.children + 1] = node
	return node
end

function DynamicAnchors:AddConditionGroup(candidate, parentId, operator)
	local parent = self:FindConditionNode(candidate, parentId)
	if not parent or parent.nodeType ~= "group" then return nil end
	self._conditionSequence = (self._conditionSequence or 0) + 1
	local node = {
		nodeType = "group",
		id = "condition-group-" .. tostring(GetTime and math.floor(GetTime() * 1000) or 0) .. "-" .. tostring(self._conditionSequence),
		operator = operator == "OR" and "OR" or "AND",
		children = {},
	}
	parent.children[#parent.children + 1] = node
	return node
end

function DynamicAnchors:RemoveConditionNode(candidate, nodeId)
	local node, parent = self:FindConditionNode(candidate, nodeId)
	if not node or not parent then return false end
	for index, child in ipairs(parent.children or {}) do
		if child == node then table.remove(parent.children, index) return true end
	end
	return false
end

function DynamicAnchors:RegisterTarget(definition)
	if type(definition) ~= "table" or type(definition.id) ~= "string" or definition.id == "" then return false end
	local current = self.targets[definition.id]
	if current and current.owner ~= definition.owner then return false end
	self.targets[definition.id] = definition
	-- Same-owner registration updates the definition without pretending the
	-- target changed. Runtime changes must use NotifyTargetChanged explicitly.
	if not current then self:QueueAllConsumers("TARGET_REGISTERED") end
	return true
end

function DynamicAnchors:UnregisterTarget(targetId)
	if not self.targets[targetId] then return end
	self.targets[targetId] = nil
	self:QueueAllConsumers("TARGET_UNREGISTERED")
end

function DynamicAnchors:RegisterConsumer(definition)
	if type(definition) ~= "table" or type(definition.id) ~= "string" or definition.id == "" then return false end
	local current = self.consumers[definition.id]
	if current and current.owner ~= definition.owner then return false end
	self.consumers[definition.id] = definition
	self:RefreshRaidSizeConsumerTracking()
	-- Replacing a same-owner callback is side-effect free. Call QueueConsumer
	-- explicitly when the updated definition also needs to be applied.
	if not current then self:QueueConsumer(definition.id, "CONSUMER_REGISTERED") end
	return true
end

function DynamicAnchors:UnregisterConsumer(consumerId)
	self.consumers[consumerId] = nil
	self.pendingConsumers[consumerId] = nil
	self.diagnostics[consumerId] = nil
	self:RefreshRaidSizeConsumerTracking()
end

function DynamicAnchors:UnregisterOwner(owner)
	for targetId, definition in pairs(self.targets) do
		if definition.owner == owner then self.targets[targetId] = nil end
	end
	for consumerId, definition in pairs(self.consumers) do
		if definition.owner == owner then
			self.consumers[consumerId] = nil
			self.pendingConsumers[consumerId] = nil
			self.diagnostics[consumerId] = nil
		end
	end
	self:QueueAllConsumers("OWNER_UNREGISTERED")
end

function DynamicAnchors:GetTargetLabel(targetId)
	local definition = self.targets[targetId]
	if not definition then return targetId end
	if type(definition.getLabel) == "function" then
		local ok, label = pcall(definition.getLabel, definition)
		if ok and type(label) == "string" and label ~= "" then return label end
	end
	return definition.label or targetId
end

function DynamicAnchors:GetConsumerLabel(consumerId)
	local definition = self.consumers[consumerId]
	if not definition then return consumerId end
	if type(definition.getLabel) == "function" then
		local ok, label = pcall(definition.getLabel, definition)
		if ok and type(label) == "string" and label ~= "" then return label end
	end
	return definition.label or consumerId
end

function DynamicAnchors:GetConsumerOptions()
	local options = {}
	for consumerId in pairs(self.consumers) do options[#options + 1] = { value = consumerId, label = self:GetConsumerLabel(consumerId) } end
	table.sort(options, function(a, b) return tostring(a.label) < tostring(b.label) end)
	return options
end

function DynamicAnchors:GetTargetOptions(consumerId)
	local options = {}
	for targetId, definition in pairs(self.targets) do
		local selectable = definition.selectable
		if type(selectable) == "function" then
			local ok, value = pcall(selectable, definition)
			selectable = ok and value ~= false
		end
		if selectable ~= false and not self:WouldCreateCycle(consumerId, targetId) then
			options[#options + 1] = {
				value = targetId,
				label = self:GetTargetLabel(targetId),
				menuGroup = definition.menuGroup,
				menuGroupLabel = definition.menuGroupLabel,
				menuGroupOrder = definition.menuGroupOrder,
			}
		end
	end
	table.sort(options, function(a, b) return tostring(a.label) < tostring(b.label) end)
	return options
end

local function getRuleForConsumer(definition)
	if not definition or type(definition.getRule) ~= "function" then return nil end
	local ok, rule = pcall(definition.getRule, definition)
	return ok and rule or nil
end

local function getTargetConsumerId(definition)
	if not definition then return nil end
	if type(definition.getConsumerId) == "function" then
		local ok, consumerId = pcall(definition.getConsumerId, definition)
		if ok then return consumerId end
	end
	return definition.consumerId
end

function DynamicAnchors:GetConsumerAssignment(consumerId)
	return getRuleForConsumer(self.consumers[consumerId])
end

function DynamicAnchors:EnsureConsumerAssignment(consumerId)
	local definition = self.consumers[consumerId]
	if not definition then return nil end
	local assignment = getRuleForConsumer(definition)
	if type(assignment) == "table" then return assignment end
	if type(definition.ensureRule) == "function" then
		local ok, value = pcall(definition.ensureRule, definition)
		if ok and type(value) == "table" then return value end
	end
	return nil
end

local function resolveAssignedRule(self, assignment)
	if type(assignment) ~= "table" then return assignment end
	if type(assignment.profileId) == "string" then
		local profile = self:GetProfile(assignment.profileId)
		if not profile then return { enabled = assignment.enabled == true, candidates = {} } end
		local rule = self:NormalizeRule(profile)
		rule.enabled = assignment.enabled == true
		return rule
	end
	return assignment
end

function DynamicAnchors:ConsumerUsesTarget(consumerId, targetId)
	if type(targetId) ~= "string" or targetId == "" then return false end
	local assignment = getRuleForConsumer(self.consumers[consumerId])
	if type(assignment) ~= "table" or assignment.enabled ~= true then return false end

	local rule = assignment
	if type(assignment.profileId) == "string" then
		rule = self:GetProfile(assignment.profileId)
		if type(rule) ~= "table" then return false end
	end

	local candidateCount = 0
	for _, candidate in ipairs(type(rule.candidates) == "table" and rule.candidates or {}) do
		candidateCount = candidateCount + 1
		if candidateCount > self.MAX_CANDIDATES then break end
		if type(candidate) == "table" and candidate.targetId == targetId then return true end
	end
	return false
end

local function conditionTreeContainsType(node, conditionType)
	if type(node) ~= "table" then return false end
	if node.nodeType == "condition" then return node.conditionType == conditionType end
	for _, child in ipairs(node.children or {}) do
		if conditionTreeContainsType(child, conditionType) then return true end
	end
	return false
end

local function ruleContainsConditionType(rule, conditionType)
	for _, candidate in ipairs(rule and rule.candidates or {}) do
		if conditionTreeContainsType(candidate.conditions, conditionType) then return true end
	end
	return false
end

function DynamicAnchors:RefreshRaidSizeConsumerTracking()
	if self._refreshingRaidSizeConsumerTracking then return end
	self._refreshingRaidSizeConsumerTracking = true
	local tracked = {}
	for consumerId, definition in pairs(self.consumers) do
		local assignment = getRuleForConsumer(definition)
		if type(assignment) == "table" and assignment.enabled == true then
			local rule = self:NormalizeRule(resolveAssignedRule(self, assignment))
			if rule.enabled and ruleContainsConditionType(rule, "RAID_SIZE") then tracked[consumerId] = true end
		end
	end
	self._raidSizeConsumers = tracked

	local eventFrame = self.eventFrame
	if eventFrame then
		local shouldRegister = next(tracked) ~= nil
		if shouldRegister and not self._raidSizeEventRegistered then
			eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
			self._raidSizeEventRegistered = true
			self._raidSizeWasInRaid = IsInRaid and IsInRaid() == true or false
		elseif not shouldRegister and self._raidSizeEventRegistered then
			eventFrame:UnregisterEvent("GROUP_ROSTER_UPDATE")
			self._raidSizeEventRegistered = nil
			self._raidSizeWasInRaid = nil
		end
	end
	self._refreshingRaidSizeConsumerTracking = nil
end

function DynamicAnchors:HandleRaidSizeRosterUpdate()
	local isInRaid = IsInRaid and IsInRaid() == true or false
	local wasInRaid = self._raidSizeWasInRaid == true
	self._raidSizeWasInRaid = isInRaid
	if not isInRaid and not wasInRaid then return end
	for consumerId in pairs(self._raidSizeConsumers or {}) do
		self:QueueConsumer(consumerId, "GROUP_ROSTER_UPDATE")
	end
end

function DynamicAnchors:WouldCreateCycle(consumerId, targetId)
	if not consumerId or not targetId then return false end
	local startTarget = self.targets[targetId]
	local nextConsumer = getTargetConsumerId(startTarget)
	if nextConsumer == consumerId then return true end
	local visited = {}
	local function visitsConsumer(currentConsumer)
		if not currentConsumer or visited[currentConsumer] then return false end
		if currentConsumer == consumerId then return true end
		visited[currentConsumer] = true
		local definition = self.consumers[currentConsumer]
		local rule = self:NormalizeRule(resolveAssignedRule(self, getRuleForConsumer(definition)))
		if not rule.enabled then return false end
		for _, candidate in ipairs(rule.candidates) do
			local target = self.targets[candidate.targetId]
			if target and visitsConsumer(getTargetConsumerId(target)) then return true end
		end
		return false
	end
	return visitsConsumer(nextConsumer)
end

local function getPlayerConditionState()
	local _, class = UnitClass("player")
	local specIndex = GetSpecialization and GetSpecialization() or nil
	local specID, role
	if specIndex and GetSpecializationInfo then specID, _, _, _, role = GetSpecializationInfo(specIndex) end
	return class, specID, role
end

local function isTalentKnown(spellID)
	if not spellID then return nil end
	if C_SpellBook and C_SpellBook.IsSpellKnownOrInSpellBook then return C_SpellBook.IsSpellKnownOrInSpellBook(spellID) == true end
	return IsPlayerSpell and IsPlayerSpell(spellID) == true or false
end

local function candidateConditionsMatch(candidate)
	local class, specID, role = getPlayerConditionState()
	local function evaluate(node, depth)
		if type(node) ~= "table" or depth > 4 then return true end
		if node.nodeType == "group" then
			local isOr = node.operator == "OR"
			if #(node.children or {}) == 0 then return true end
			for _, child in ipairs(node.children or {}) do
				local matches, reason = evaluate(child, depth + 1)
				if isOr and matches then return true end
				if not isOr and not matches then return false, reason end
			end
			return not isOr, isOr and "CONDITION_OR_UNMATCHED" or nil
		end
		local actual
		if node.conditionType == "CLASS" then
			actual = class
		elseif node.conditionType == "SPEC" then
			actual = specID
		elseif node.conditionType == "ROLE" then
			actual = role
		elseif node.conditionType == "TALENT" then
			local known = isTalentKnown(tonumber(node.value))
			local matches = known
			if node.operator == "NOT_KNOWN" then matches = not known end
			return matches, matches and nil or (node.operator == "NOT_KNOWN" and "TALENT_KNOWN" or "TALENT_NOT_KNOWN")
		elseif node.conditionType == "RAID_SIZE" then
			if not (IsInRaid and IsInRaid()) then return false, "RAID_SIZE_NOT_IN_RAID" end
			local raidSize = GetNumGroupMembers and GetNumGroupMembers() or 0
			local threshold = math.max(1, math.min(40, math.floor(tonumber(node.value) or 20)))
			local matches
			if node.operator == "AT_LEAST" then
				matches = raidSize >= threshold
			else
				matches = raidSize <= threshold
			end
			return matches, matches and nil or (node.operator == "AT_LEAST" and "RAID_SIZE_BELOW_MINIMUM" or "RAID_SIZE_ABOVE_MAXIMUM")
		else
			return true
		end
		local equals = false
		if type(node.value) == "table" then
			for _, value in ipairs(node.value) do
				if tostring(actual or "") == tostring(value or "") then equals = true break end
			end
		else
			equals = tostring(actual or "") == tostring(node.value or "")
		end
		local matches = equals
		if node.operator == "IS_NOT" or node.operator == "NOT_ANY_OF" then matches = not equals end
		return matches, matches and nil or (node.conditionType .. "_MISMATCH")
	end
	return evaluate(candidate and candidate.conditions, 0)
end

local function resolveTarget(definition, context)
	if not definition then return nil, { available = false, reason = "TARGET_NOT_REGISTERED" } end
	if type(definition.resolve) ~= "function" then return nil, { available = false, reason = "NO_RESOLVER" } end
	local ok, frame, state = pcall(definition.resolve, definition, context)
	if not ok then return nil, { available = false, reason = "RESOLVER_ERROR" } end
	state = type(state) == "table" and state or {}
	if state.available == nil then state.available = frame ~= nil end
	if not state.available and not state.reason then state.reason = "UNAVAILABLE" end
	if state.available and not frame then
		state.available = false
		state.reason = state.reason or "FRAME_NOT_CREATED"
	end
	if state.available and frame and definition.id then DynamicAnchors:EnsureSimpleTargetHooks(definition.id, frame) end
	return frame, state
end

function DynamicAnchors:ResolveConsumer(consumerId, context)
	local definition = self.consumers[consumerId]
	local assignment = getRuleForConsumer(definition)
	local rule = self:NormalizeRule(resolveAssignedRule(self, assignment))
	local result = {
		consumerId = consumerId,
		rejected = {},
		rule = rule,
	}
	if not definition then
		result.reason = "CONSUMER_NOT_REGISTERED"
		return result
	end
	if not rule.enabled then
		result.reason = "DISABLED"
		return result
	end
	local preview = self.previewCandidates[consumerId]
	self.previewCandidates[consumerId] = nil
	if preview and type(assignment) == "table" and assignment.profileId == preview.profileId then
		local candidate = rule.candidates[preview.candidateIndex]
		if candidate and not self:WouldCreateCycle(consumerId, candidate.targetId) then
			local frame, state = resolveTarget(self.targets[candidate.targetId], context)
			if frame and state.available then
				result.winner = {
					candidateId = candidate.id,
					targetId = candidate.targetId,
					frame = frame,
					placement = candidate.placement,
					matchRelativeWidth = canMatchRelativeWidth(candidate.targetId) and candidate.matchRelativeWidth == true,
					matchRelativeWidthOffset = canMatchRelativeWidth(candidate.targetId) and (tonumber(candidate.matchRelativeWidthOffset) or 0) or 0,
					state = state,
					preview = true,
				}
				self.diagnostics[consumerId] = result
				return result
			end
		end
	end
	for _, candidate in ipairs(rule.candidates) do
		local reason
		local matches, conditionReason = candidateConditionsMatch(candidate)
		if not matches then
			reason = conditionReason
		elseif self:WouldCreateCycle(consumerId, candidate.targetId) then
			reason = "CYCLE"
		else
			local target = self.targets[candidate.targetId]
			local frame, state = resolveTarget(target, context)
			if frame and state.available then
				result.winner = {
					candidateId = candidate.id,
					targetId = candidate.targetId,
					frame = frame,
					placement = candidate.placement,
					matchRelativeWidth = canMatchRelativeWidth(candidate.targetId) and candidate.matchRelativeWidth == true,
					matchRelativeWidthOffset = canMatchRelativeWidth(candidate.targetId) and (tonumber(candidate.matchRelativeWidthOffset) or 0) or 0,
					state = state,
				}
				break
			end
			reason = state.reason
		end
		result.rejected[#result.rejected + 1] = {
			candidateId = candidate.id,
			targetId = candidate.targetId,
			reason = reason,
		}
	end
	if not result.winner then
		local fallback = self.targets["core:uiparent"]
		local frame = resolveTarget(fallback, context)
		result.winner = {
			targetId = "core:uiparent",
			frame = frame or UIParent,
			placement = rule.finalFallback.placement,
			fallback = true,
		}
	end
	self.diagnostics[consumerId] = result
	return result
end

function DynamicAnchors:GetDiagnostics(consumerId)
	return self.diagnostics[consumerId]
end

function DynamicAnchors:PreviewCandidate(consumerId, profileId, candidateIndex)
	if not self.consumers[consumerId] or not self:GetProfile(profileId) then return false end
	self.previewCandidates[consumerId] = { profileId = profileId, candidateIndex = tonumber(candidateIndex) }
	self:QueueConsumer(consumerId, "CANDIDATE_PREVIEW")
	return true
end

function DynamicAnchors:PreviewProfileCandidate(profileId, candidateIndex)
	local queued = false
	for consumerId, definition in pairs(self.consumers) do
		local assignment = getRuleForConsumer(definition)
		if type(assignment) == "table" and assignment.enabled == true and assignment.profileId == profileId then
			self.previewCandidates[consumerId] = { profileId = profileId, candidateIndex = tonumber(candidateIndex) }
			self:QueueConsumer(consumerId, "CANDIDATE_PREVIEW")
			queued = true
		end
	end
	return queued
end

function DynamicAnchors:QueueConsumer(consumerId, reason)
	if not self.consumers[consumerId] then return end
	self.pendingConsumers[consumerId] = reason or true
	if self._flushScheduled or self._flushDeferredForCombat then return end
	if InCombatLockdown and InCombatLockdown() then
		self._flushDeferredForCombat = true
		return
	end
	self._flushScheduled = true
	C_Timer.After(0, function()
		DynamicAnchors._flushScheduled = nil
		if InCombatLockdown and InCombatLockdown() then
			DynamicAnchors._flushDeferredForCombat = true
			return
		end
		local pending = DynamicAnchors.pendingConsumers
		DynamicAnchors.pendingConsumers = {}
		for id in pairs(pending) do
			local consumer = DynamicAnchors.consumers[id]
			if consumer and type(consumer.apply) == "function" then pcall(consumer.apply, consumer, id) end
		end
	end)
end

function DynamicAnchors:QueueAllConsumers(reason)
	self:RefreshRaidSizeConsumerTracking()
	for consumerId in pairs(self.consumers) do
		self:QueueConsumer(consumerId, reason)
	end
end

function DynamicAnchors:NotifyTargetChanged(targetId, reason, excludedConsumerId)
	for consumerId in pairs(self.consumers) do
		if consumerId ~= excludedConsumerId and self:ConsumerUsesTarget(consumerId, targetId) then self:QueueConsumer(consumerId, reason or targetId or "TARGET_CHANGED") end
	end
end

function DynamicAnchors:NotifyOwnerChanged(owner, reason)
	self:QueueAllConsumers(reason or owner or "OWNER_CHANGED")
end

DynamicAnchors:RegisterTarget({
	id = "core:uiparent",
	owner = addonName,
	label = L["Screen (UIParent)"] or "Screen (UIParent)",
	selectable = true,
	resolve = function()
		return UIParent, { available = UIParent ~= nil }
	end,
})

if addon.SharedAnchors then
	for _, entry in ipairs(addon.SharedAnchors:GetActionBarEntries() or {}) do
		local target = entry
		DynamicAnchors:RegisterTarget({
			id = "actionBar:" .. target.key,
			owner = addonName,
			label = target.label,
			menuGroup = "ACTION_BARS",
			menuGroupLabel = L["Dynamic Anchor Group Action Bars"],
			menuGroupOrder = 100,
			resolve = function()
				local frame = _G[target.key]
				return frame, { available = frame ~= nil, reason = frame and nil or "FRAME_NOT_CREATED" }
			end,
		})
	end
	for _, entry in ipairs(addon.SharedAnchors:GetUnitFrameEntries() or {}) do
		local target = entry
		DynamicAnchors:RegisterTarget({
			id = "unitFrame:" .. target.key,
			owner = addonName,
			getConsumerId = function() return addon.SharedAnchors:GetUnitFrameDynamicAnchorConsumerId(target.key) end,
			label = target.label,
			menuGroup = "UNIT_FRAMES",
			menuGroupLabel = L["Unit Frames"],
			menuGroupOrder = 500,
			resolve = function()
				local frame = addon.SharedAnchors:ResolveFrame(target.key)
				if frame and frame ~= UIParent then DynamicAnchors:EnsureSimpleTargetHooks("unitFrame:" .. target.key, frame) end
				return frame ~= UIParent and frame or nil, { available = frame ~= nil and frame ~= UIParent, reason = "FRAME_NOT_CREATED" }
			end,
		})
	end
end

if CreateFrame then
	local eventFrame = CreateFrame("Frame")
	DynamicAnchors.eventFrame = eventFrame
	eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
	eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
	eventFrame:SetScript("OnEvent", function(_, event)
		if event == "PLAYER_REGEN_ENABLED" then DynamicAnchors._flushDeferredForCombat = nil end
		if event == "GROUP_ROSTER_UPDATE" then
			DynamicAnchors:HandleRaidSizeRosterUpdate()
		else
			DynamicAnchors:QueueAllConsumers(event)
		end
	end)
	DynamicAnchors:RefreshRaidSizeConsumerTracking()
end
