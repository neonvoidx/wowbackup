local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

local cat = addon.SettingsLayout and addon.SettingsLayout.rootUI
if not (cat and addon.functions and addon.functions.SettingsCreateExpandableSection) then return end

local expandable = addon.functions.SettingsCreateExpandableSection(cat, {
	name = L["Cooldown Panels"] or "Cooldown Panels",
	description = L["configCenterPageDescCooldownPanels"]
		or "Create and manage custom cooldown panels, then edit tracked abilities, layout and visibility in the panel editor.",
	newTagID = "CooldownPanels",
	iconKey = "cooldownpanels",
	modernCategory = "suites",
	expanded = false,
	colorizeTitle = false,
})

local function withCooldownPanels(action)
	local panels = addon.Aura and addon.Aura.CooldownPanels
	if not panels then return end
	action(panels)
end

local function openEditorExclusively(panels)
	if not panels then return end
	local editorFrame
	if panels.OpenPreferredEditor then
		editorFrame = panels:OpenPreferredEditor()
	elseif panels.OpenBlizzardEditor then
		editorFrame = panels:OpenBlizzardEditor()
	elseif panels.OpenEditor then
		editorFrame = panels:OpenEditor()
	end
	if editorFrame and addon.functions.HideConfigCenterUntilFrameHidden then
		addon.functions.HideConfigCenterUntilFrameHidden(editorFrame)
	end
end

addon.functions.SettingsCreateButton(cat, {
	text = L["CooldownPanelOpenEditor"] or "Open Cooldown Panel Editor",
	func = function()
		withCooldownPanels(function(panels)
			openEditorExclusively(panels)
		end)
	end,
	parentSection = expandable,
})

local function refreshConfigCenter()
	local frame = addon.ConfigCenterFrame
	local state = frame and frame._LibSettingsDesignerState
	if frame and frame:IsShown() and state and state.RenderContent then state:RenderContent() end
end

local function registerDynamicAnchoringSettings()
	local app = addon.ConfigApp
	local dynamicAnchors = addon.DynamicAnchors
	if not (app and dynamicAnchors and app.RegisterPage and app.RegisterControl) then return end
	if addon._dynamicAnchoringSettingsRegistered then return end
	addon._dynamicAnchoringSettingsRegistered = true

	local pageID = "suites.dynamic-anchoring"
	local selectedProfileId
	local pointList = {
		TOPLEFT = "TOPLEFT",
		TOP = "TOP",
		TOPRIGHT = "TOPRIGHT",
		LEFT = "LEFT",
		CENTER = "CENTER",
		RIGHT = "RIGHT",
		BOTTOMLEFT = "BOTTOMLEFT",
		BOTTOM = "BOTTOM",
		BOTTOMRIGHT = "BOTTOMRIGHT",
	}
	local pointOrder = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }

	local function getSelectedProfileId(create)
		if selectedProfileId and dynamicAnchors:GetProfile(selectedProfileId) then return selectedProfileId end
		local options = dynamicAnchors:GetProfileOptions()
		selectedProfileId = options[1] and options[1].value or nil
		if not selectedProfileId and create then selectedProfileId = dynamicAnchors:CreateProfile(L["Dynamic Anchor New Profile"]) end
		return selectedProfileId
	end
	local function getRule(create)
		local profileId = getSelectedProfileId(create)
		local profile = profileId and dynamicAnchors:GetProfile(profileId) or nil
		if profile then
			local normalized = dynamicAnchors:NormalizeRule(profile)
			normalized.name = profile.name
			addon.db.dynamicAnchorProfiles[profileId] = normalized
			return normalized
		end
		return nil
	end
	local function notifyChanged(rebuild)
		dynamicAnchors:QueueAllConsumers("PROFILE_CHANGED")
		if rebuild then refreshConfigCenter() end
	end
	local function getCandidate(index, create)
		local rule = getRule(create)
		if not rule then return nil end
		local candidate = rule.candidates[index]
		if not candidate and create and #rule.candidates < dynamicAnchors.MAX_CANDIDATES then
			candidate = {
				id = "candidate-" .. tostring(index),
				placement = { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = 0, y = 0 },
			}
			rule.candidates[index] = candidate
		end
		return candidate
	end
	local function profileOptions()
		local list, order = {}, {}
		for _, option in ipairs(dynamicAnchors:GetProfileOptions()) do
			list[option.value] = option.label
			order[#order + 1] = option.value
		end
		return list, order
	end
	local function targetList(index)
		local list = {}
		for _, option in ipairs(dynamicAnchors:GetTargetOptions()) do
			list[option.value] = {
				value = option.value,
				label = option.label,
				menuGroup = option.menuGroup,
				menuGroupLabel = option.menuGroupLabel,
				menuGroupOrder = option.menuGroupOrder,
			}
		end
		local candidate = getCandidate(index, false)
		if candidate and candidate.targetId and not list[candidate.targetId] then list[candidate.targetId] = { value = candidate.targetId, label = dynamicAnchors:GetTargetLabel(candidate.targetId) } end
		return list
	end
	local function targetOrder(index)
		local order = {}
		for _, option in ipairs(dynamicAnchors:GetTargetOptions()) do order[#order + 1] = option.value end
		local candidate = getCandidate(index, false)
		if candidate and candidate.targetId then
			local found = false
			for _, targetId in ipairs(order) do
				if targetId == candidate.targetId then found = true break end
			end
			if not found then order[#order + 1] = candidate.targetId end
		end
		return order
	end
	StaticPopupDialogs["EQOL_DYNAMIC_ANCHOR_PROFILE_DELETE"] = {
		text = L["Dynamic Anchor Delete Profile Confirm"],
		button1 = _G.YES,
		button2 = _G.NO,
		OnAccept = function(_, data)
			if data and type(data.onAccept) == "function" then data.onAccept() end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	app:RegisterPage({
		id = pageID,
		category = "profiles",
		title = L["Dynamic Anchoring"] or "Dynamic Anchoring",
		description = L["Dynamic Anchoring Desc"] or "Build an ordered fallback chain for EnhanceQoL frames without changing the saved preferred targets at runtime.",
		iconKey = "cooldownpanels",
		order = 25,
		newTagID = "DynamicAnchoring",
		sidePanel = false,
		groupColumns = 1,
	})
	app:RegisterGroup(pageID, { id = "profiles", title = L["Dynamic Anchor Profiles"], order = 100 })
	app:RegisterControl(pageID, {
		id = "dynamicAnchorEditProfile",
		type = "dropdown",
		label = L["Dynamic Anchor Profile"],
		groupID = "profiles",
		listFunc = profileOptions,
		getValue = function() return getSelectedProfileId(false) end,
		setValue = function(value) selectedProfileId = value end,
		refreshOnChange = true,
		default = nil,
		order = 10,
	})
	app:RegisterControl(pageID, {
		id = "dynamicAnchorProfileName",
		type = "input",
		label = L["Profile name"],
		groupID = "profiles",
		getValue = function()
			local profile = dynamicAnchors:GetProfile(getSelectedProfileId(false))
			return profile and profile.name or ""
		end,
		setValue = function(value)
			local profile = dynamicAnchors:GetProfile(getSelectedProfileId(false))
			if profile and type(value) == "string" and value ~= "" then profile.name = value end
		end,
		default = "",
		maxChars = 64,
		order = 20,
	})
	app:RegisterControl(pageID, {
		id = "dynamicAnchorCreateProfile",
		type = "button",
		label = L["Create profile"],
		buttonText = L["Create profile"],
		groupID = "profiles",
		onClick = function()
			selectedProfileId = dynamicAnchors:CreateProfile(L["Dynamic Anchor New Profile"])
			refreshConfigCenter()
		end,
		order = 30,
	})
	app:RegisterControl(pageID, {
		id = "dynamicAnchorDuplicateProfile",
		type = "button",
		label = L["Duplicate profile"],
		buttonText = L["Duplicate profile"],
		groupID = "profiles",
		onClick = function()
			local profile = dynamicAnchors:GetProfile(getSelectedProfileId(false))
			if profile then selectedProfileId = dynamicAnchors:CreateProfile((profile.name or "Profile") .. " " .. (L["Copy"] or "Copy"), profile) end
			refreshConfigCenter()
		end,
		isEnabled = function() return getSelectedProfileId(false) ~= nil end,
		order = 40,
	})
	app:RegisterControl(pageID, {
		id = "dynamicAnchorDeleteProfile",
		type = "button",
		label = L["Delete profile"],
		buttonText = L["Delete profile"],
		groupID = "profiles",
		onClick = function()
			local profileId = getSelectedProfileId(false)
			local profile = dynamicAnchors:GetProfile(profileId)
			if not (profileId and profile) then return end
			StaticPopup_Show("EQOL_DYNAMIC_ANCHOR_PROFILE_DELETE", profile.name or profileId, nil, {
				onAccept = function()
					dynamicAnchors:DeleteProfile(profileId)
					selectedProfileId = nil
					refreshConfigCenter()
				end,
			})
		end,
		isEnabled = function() return getSelectedProfileId(false) ~= nil end,
		order = 50,
	})
	local candidateCountList, candidateCountOrder = {}, {}
	for count = 1, dynamicAnchors.MAX_CANDIDATES do
		candidateCountList[count] = tostring(count)
		candidateCountOrder[#candidateCountOrder + 1] = count
	end
	app:RegisterControl(pageID, {
		id = "dynamicAnchorCandidateCount",
		type = "dropdown",
		label = L["Dynamic Anchor Candidate Count"],
		groupID = "profiles",
		list = candidateCountList,
		orderList = candidateCountOrder,
		getValue = function()
			local profile = getRule(false)
			return profile and profile.candidateCount or 1
		end,
		setValue = function(value)
			local profile = getRule(true)
			if not profile then return end
			local count = math.max(1, math.min(dynamicAnchors.MAX_CANDIDATES, math.floor(tonumber(value) or 1)))
			profile.candidateCount = count
			for index = #profile.candidates, count + 1, -1 do table.remove(profile.candidates, index) end
			notifyChanged(false)
		end,
		isEnabled = function() return getSelectedProfileId(false) ~= nil end,
		refreshOnChange = true,
		default = 1,
		order = 60,
	})

	for index = 1, dynamicAnchors.MAX_CANDIDATES do
		local groupID = "profiles"
		local baseOrder = 1000 + (index * 200)
		local function candidateVisible()
			local profile = getRule(false)
			return profile ~= nil and (tonumber(profile.candidateCount) or 1) >= index
		end
		local function registerCandidateControl(control)
			control.groupID = groupID
			control.order = baseOrder + (tonumber(control.order) or 0)
			control.visibleWhen = candidateVisible
			app:RegisterControl(pageID, control)
		end
		registerCandidateControl({
			id = "dynamicAnchorCandidateHeader" .. tostring(index),
			type = "sectionheader",
			label = (L["Dynamic Anchor Priority"] or "Priority %d"):format(index),
			trackCustomized = false,
			order = 0,
		})
		registerCandidateControl({
			id = "dynamicAnchorTarget" .. tostring(index),
			type = "dropdown",
			label = L["Anchor target"] or "Anchor target",
			groupID = groupID,
			listFunc = function() return targetList(index), targetOrder(index) end,
			getValue = function()
				local candidate = getCandidate(index, false)
				return candidate and candidate.targetId or nil
			end,
			setValue = function(value)
				local candidate = getCandidate(index, true)
				if candidate then candidate.targetId = value end
				notifyChanged(false)
			end,
			customDefaultText = _G.NONE or "None",
			refreshOnChange = true,
			default = nil,
			order = 10,
		})
		for _, field in ipairs({ "point", "relativePoint" }) do
			local fieldName = field
			registerCandidateControl({
				id = "dynamicAnchor" .. fieldName .. tostring(index),
				type = "dropdown",
				label = fieldName == "point" and (L["Anchor point"] or "Anchor point") or (L["Relative anchor point"] or "Relative anchor point"),
				groupID = groupID,
				list = pointList,
				orderList = pointOrder,
				getValue = function()
					local candidate = getCandidate(index, false)
					return candidate and candidate.placement and candidate.placement[fieldName] or (fieldName == "point" and "TOPLEFT" or "BOTTOMLEFT")
				end,
				setValue = function(value)
					local candidate = getCandidate(index, true)
					if candidate then candidate.placement[fieldName] = value end
					notifyChanged(false)
				end,
				isEnabled = function() return getCandidate(index, false) ~= nil end,
				default = fieldName == "point" and "TOPLEFT" or "BOTTOMLEFT",
				order = fieldName == "point" and 20 or 30,
			})
		end
		for _, field in ipairs({ "x", "y" }) do
			local fieldName = field
			registerCandidateControl({
				id = "dynamicAnchorOffset" .. string.upper(fieldName) .. tostring(index),
				type = "slider",
				label = fieldName == "x" and (L["Horizontal offset"] or "Horizontal offset") or (L["Vertical offset"] or "Vertical offset"),
				groupID = groupID,
				min = -500,
				max = 500,
				step = 1,
				getValue = function()
					local candidate = getCandidate(index, false)
					return candidate and candidate.placement and tonumber(candidate.placement[fieldName]) or 0
				end,
				setValue = function(value)
					local candidate = getCandidate(index, true)
					if candidate then candidate.placement[fieldName] = tonumber(value) or 0 end
					notifyChanged(false)
				end,
				isEnabled = function() return getCandidate(index, false) ~= nil end,
				default = 0,
				order = fieldName == "x" and 40 or 50,
			})
		end
		registerCandidateControl({
			id = "dynamicAnchorMatchWidth" .. tostring(index),
			type = "toggle",
			label = L["Match relative frame width"],
			getValue = function()
				local candidate = getCandidate(index, false)
				return candidate and candidate.matchRelativeWidth == true or false
			end,
			setValue = function(value)
				local candidate = getCandidate(index, true)
				if candidate then candidate.matchRelativeWidth = value == true end
				notifyChanged(false)
			end,
			isEnabled = function()
				local candidate = getCandidate(index, false)
				return candidate and candidate.targetId ~= nil
			end,
			default = false,
			order = 55,
		})
		registerCandidateControl({
			id = "dynamicAnchorMatchWidthOffset" .. tostring(index),
			type = "slider",
			label = L["Offset"],
			min = -200,
			max = 200,
			step = 1,
			getValue = function()
				local candidate = getCandidate(index, false)
				return candidate and tonumber(candidate.matchRelativeWidthOffset) or 0
			end,
			setValue = function(value)
				local candidate = getCandidate(index, true)
				if candidate then candidate.matchRelativeWidthOffset = tonumber(value) or 0 end
				notifyChanged(false)
			end,
			isEnabled = function()
				local candidate = getCandidate(index, false)
				return candidate and candidate.targetId ~= nil and candidate.matchRelativeWidth == true
			end,
			default = 0,
			order = 57,
		})
		registerCandidateControl({
			id = "dynamicAnchorConditions" .. tostring(index),
			type = "custom",
			label = L["Dynamic Anchor Conditions"],
			description = L["Dynamic Anchor Conditions Desc"],
			getHeight = function()
				local candidate = getCandidate(index, false)
				return candidate and (dynamicAnchors:GetConditionEditorHeight(candidate) + 78) or 120
			end,
			render = function(parent)
				local candidate = getCandidate(index, true)
				if not candidate then return nil end
				return dynamicAnchors:RenderConditionEditor(parent, candidate, function(rebuild) notifyChanged(rebuild) end, function(action, nodeId, value)
					local current = getCandidate(index, true)
					if not current then return nil end
					if action == "ADD_CONDITION" then return dynamicAnchors:AddConditionNode(current, nodeId, value) end
					if action == "ADD_GROUP" then return dynamicAnchors:AddConditionGroup(current, nodeId, value) end
					if action == "REMOVE" then return dynamicAnchors:RemoveConditionNode(current, nodeId) end
					local node = dynamicAnchors:FindConditionNode(current, nodeId)
					if not node then return nil end
					if action == "GROUP_OPERATOR" then node.operator = value
					elseif action == "TYPE" then
						node.conditionType, node.value = value, value == "TALENT" and 0 or ""
						node.operator = value == "TALENT" and "KNOWN" or (value == "CLASS" or value == "SPEC" or value == "ROLE") and "ANY_OF" or "IS"
					elseif action == "OPERATOR" then node.operator = value
					elseif action == "VALUE" then node.value = value end
					return node
				end)
			end,
			trackCustomized = false,
			order = 60,
		})
		registerCandidateControl({
			id = "dynamicAnchorTest" .. tostring(index),
			type = "button",
			label = L["Test"],
			buttonText = L["Test"],
			groupID = groupID,
			onClick = function()
				local profileId = getSelectedProfileId(false)
				if profileId and getCandidate(index, false) then dynamicAnchors:PreviewProfileCandidate(profileId, index) end
			end,
			isEnabled = function()
				local candidate = getCandidate(index, false)
				return candidate and candidate.targetId ~= nil
			end,
			order = 70,
		})
		registerCandidateControl({
			id = "dynamicAnchorMoveUp" .. tostring(index),
			type = "button",
			label = L["Move Up"] or "Move Up",
			buttonText = L["Move Up"] or "Move Up",
			groupID = groupID,
			onClick = function()
				local rule = getRule(true)
				if rule and index > 1 and rule.candidates[index] then
					rule.candidates[index - 1], rule.candidates[index] = rule.candidates[index], rule.candidates[index - 1]
					notifyChanged(true)
				end
			end,
			isEnabled = function() return index > 1 and getCandidate(index, false) ~= nil end,
			order = 80,
		})
		registerCandidateControl({
			id = "dynamicAnchorRemove" .. tostring(index),
			type = "button",
			label = _G.REMOVE or "Remove",
			buttonText = _G.REMOVE or "Remove",
			groupID = groupID,
			onClick = function()
				local rule = getRule(true)
				if rule and rule.candidates[index] then
					table.remove(rule.candidates, index)
					notifyChanged(true)
				end
			end,
			isEnabled = function() return getCandidate(index, false) ~= nil end,
			order = 90,
		})
	end
end

registerDynamicAnchoringSettings()

addon.functions.SettingsCreateButton(cat, {
	text = L["Add Panel"] or "Add Panel",
	func = function()
		withCooldownPanels(function(panels)
			local panelId = panels:CreatePanel(L["CooldownPanelNewPanel"] or "New Panel")
			if panelId then panels:SelectPanel(panelId) end
			openEditorExclusively(panels)
		end)
	end,
	parentSection = expandable,
})
