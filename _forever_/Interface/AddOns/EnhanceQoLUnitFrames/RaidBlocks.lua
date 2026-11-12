local _, addon = ...
addon = _G.EnhanceQoL or addon
addon.Aura = addon.Aura or {}
addon.Aura.UF = addon.Aura.UF or {}
local UF = addon.Aura.UF
local B = { anchors = {}, preview = true }
UF.RaidBlocks = B
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local function bounded(value, low, high, fallback)
	value = tonumber(value)
	if not value or value ~= value then return fallback end
	return math.max(low, math.min(high, math.floor(value)))
end
local function copy(source)
	local result = {}
	for key, value in pairs(source or {}) do result[key] = value end
	return result
end
local function inCombat() return InCombatLockdown and InCombatLockdown() end
function B.Config() return addon.db and addon.db.ufGroupFrames and addon.db.ufGroupFrames.raid end
function B.Options(create)
	local cfg = B.Config()
	if not cfg then return end
	if create and type(cfg.raidBlocks) ~= "table" then cfg.raidBlocks = { blocks = {} } end
	local options = cfg.raidBlocks
	if type(options) ~= "table" then return end
	if create and type(options.blocks) ~= "table" then options.blocks = {} end
	return options
end
function B.Block(id)
	local options = B.Options()
	local block = options and type(options.blocks) == "table" and options.blocks[id]
	return type(block) == "table" and block or nil
end
function B.EditMode() return addon.EditMode and addon.EditMode.IsInEditMode and addon.EditMode:IsInEditMode() end
function B.ParseGroups(value)
	local result, seen = {}, {}
	if type(value) == "table" then
		for _, group in ipairs(value) do
			if type(group) == "number" and group == math.floor(group) and group >= 1 and group <= 8 and not seen[group] then
				result[#result + 1], seen[group] = group, true
			end
		end
	else
		for token in tostring(value or ""):gmatch("[^,%s]+") do
			local group = tonumber(token)
			if not group or group ~= math.floor(group) or group < 1 or group > 8 or seen[group] then return nil end
			result[#result + 1], seen[group] = group, true
		end
	end
	return result
end
function B.Matches(options, context)
	if type(options) ~= "table" or options.enabled ~= true or type(options.blocks) ~= "table" then return false end
	local hasBlock = false
	for i = 1, 8 do
		local block = options.blocks[i]
		if type(block) == "table" and #(B.ParseGroups(block.groups) or {}) > 0 then hasBlock = true; break end
	end
	if not hasBlock then return false end
	if context.preview then return true end
	if not context.inRaid then return false end
	local count = context.count or 0
	if count < bounded(options.minSize, 1, 40, 1) or count > bounded(options.maxSize, 1, 40, 40) then return false end
	local difficulties = options.difficulties
	local restricted = false
	for _, selected in pairs(type(difficulties) == "table" and difficulties or {}) do if selected == true then restricted = true; break end end
	return not restricted or (context.instanceType == "raid" and difficulties[context.difficulty] == true)
end
function B.IsActive(cfg)
	if not cfg or cfg.enabled ~= true or type(cfg.raidBlocks) ~= "table" or cfg.raidBlocks.enabled ~= true then return false end
	if cfg._raidBlocksActive then return true end
	if B.EditMode() and not (UF.GroupFrames and UF.GroupFrames._editModeExiting) then return false end
	local _, instanceType, difficulty = GetInstanceInfo()
	return B.Matches(cfg.raidBlocks, {
		inRaid = IsInRaid(), count = GetNumGroupMembers(), instanceType = instanceType, difficulty = difficulty,
		preview = false,
	})
end
function B.EffectiveConfig(cfg, force)
	if not cfg or cfg._raidBlocksActive or (not force and not B.IsActive(cfg)) then return cfg end
	local runtime = copy(cfg)
	runtime._raidBlocksActive = true
	-- Block ownership always refers to real raid groups. Keep the saved layout
	-- untouched so it resumes when the activation conditions no longer match.
	runtime.groupBy, runtime.unitsPerColumn = "GROUP", 5
	runtime.maxColumns, runtime.groupsPerRow = 8, 8
	runtime.growth = select(2, UF.GroupFrames.ResolveUnitGrowthDirection(cfg.growth, "DOWN"))
	return runtime
end
function B.WantsPreview()
	local cfg = B.Config()
	return B.EditMode() and B.preview and cfg and cfg.enabled == true and B.Matches(cfg.raidBlocks, { preview = true }) or false
end
function B.PreviewConfig(cfg)
	local preview = B.EffectiveConfig(cfg, true)
	preview._raidBlocksPreview = true
	return preview
end
function B.HidePreview()
	local gf = UF.GroupFrames
	for _, frame in ipairs(gf and gf._previewFrames and gf._previewFrames.raidBlocks or {}) do
		gf:UnitButton_ClearUnit(frame)
		frame:Hide()
	end
end
function B.UpdatePreview(sizeCycle)
	local gf = UF.GroupFrames
	if inCombat() or not gf then return end
	if not B.WantsPreview() or gf._editModeExiting or not (gf._previewActive and gf._previewActive.raid) then B.HidePreview(); return end
	gf._previewFrames = gf._previewFrames or {}
	gf._previewFrames.raidBlocks = gf._previewFrames.raidBlocks or {}
	gf:EnsurePreviewFrames("raid", gf._previewFrames.raidBlocks)
	gf:UpdatePreviewLayout("raid", true, sizeCycle)
end
function B.SyncSettings(id)
	local edit = addon.EditMode
	local raid = edit and edit.frames and edit.frames.EQOL_UF_GROUP_RAID
	local entry = edit and edit.frames and edit.frames["EQOLRaidBlock" .. id]
	local lib = addon.EditModeLib
	if not (raid and entry and raid.preparedSettings and lib and lib.AddFrameSettings) then return end
	-- Share the prepared raid callbacks so fields and resets retain raid ownership.
	if entry._raidSettingsSource ~= raid.preparedSettings then
		entry._raidSettingsSource = raid.preparedSettings
		entry.preparedSettings, entry.settingsByField = raid.preparedSettings, raid.settingsByField
		lib:AddFrameSettings(entry.frame, raid.preparedSettings)
		local navigation = addon.Aura.GroupFrameNavigation and addon.Aura.GroupFrameNavigation.Build("raid")
		if navigation and lib.SetFrameSettingsNavigation then
			navigation.scopeKey = "EQOLRaidBlock" .. id
			if entry.navigationRegistration then
				entry.navigationRegistration.settingsNavigation = navigation
				entry.navigationRegistration.settings = raid.navigationRegistration and raid.navigationRegistration.settings
			end
			lib:SetFrameSettingsNavigation(entry.frame, navigation)
		end
	end
	if raid.buttons and entry._raidButtonsSource ~= raid.buttons then
		entry._raidButtonsSource = raid.buttons
		edit:RegisterButtons(entry.id or ("EQOLRaidBlock" .. id), raid.buttons)
	end
end
function B.DefaultBlock(id)
	return { name = string.format(L["UFRaidBlockNumber"], id), groups = {}, growth = "RIGHT", groupsPerRow = 4,
		point = "CENTER", relativePoint = "CENTER", x = -300 + ((id - 1) % 2) * 500, y = -100 - math.floor((id - 1) / 2) * 150 }
end
function B.AssignGroups(id, groups)
	local options, block = B.Options(), B.Block(id)
	if not options or not block then return end
	local selected = {}
	for _, group in ipairs(groups) do selected[group] = true end
	for i = 1, 8 do
		local other = B.Block(i)
		if other and i ~= id then
			local remaining = {}
			for _, group in ipairs(B.ParseGroups(other.groups) or {}) do if not selected[group] then remaining[#remaining + 1] = group end end
			other.groups = remaining
		end
	end
	block.groups = groups
end
function B.AddBlock()
	if inCombat() then return end
	local options = B.Options(true)
	if not options then return end
	for id = 1, 8 do
		if not B.Block(id) then
			local assigned = {}
			for other = 1, 8 do
				local block = B.Block(other)
				for _, group in ipairs(block and B.ParseGroups(block.groups) or {}) do assigned[group] = true end
			end
			options.blocks[id] = B.DefaultBlock(id)
			for group = 1, 8 do
				if not assigned[group] then options.blocks[id].groups = { group }; break end
			end
			options.enabled = true
			B.StartPreview()
			B.Refresh()
			return id
		end
	end
end
function B.StartPreview()
	local edit, gf = addon.EditMode, UF.GroupFrames
	if inCombat() or not (edit and edit:IsInEditMode() and gf and gf.SetEditModeSampleFrames) then return end
	B.preview = true
	gf:SetEditModeSampleFrames("raid", true)
end
function B.ResetBlock(id)
	if inCombat() or not B.Block(id) then return end
	B.Options().blocks[id] = B.DefaultBlock(id)
	B.Refresh()
end
function B.RemoveBlock(id)
	if inCombat() then return end
	local options = B.Options()
	if options then options.blocks[id] = nil; B.Refresh() end
end
function B.Preset(oddEven)
	if inCombat() then return end
	local options = B.Options(true)
	if not options then return end
	options.blocks = { B.DefaultBlock(1), B.DefaultBlock(2) }
	options.blocks[1].groups = oddEven and { 1, 3, 5, 7 } or { 1, 2, 3, 4 }
	options.blocks[2].groups = oddEven and { 2, 4, 6, 8 } or { 5, 6, 7, 8 }
	options.enabled = true
	B.StartPreview()
	B.Refresh()
end
function B.Title(id)
	local block = B.Block(id)
	local name = block and type(block.name) == "string" and block.name:match("%S") and block.name or string.format(L["UFRaidBlockNumber"], id)
	return L["UFRaidBlocks"] .. ": " .. name
end
function B.SetAnchorPosition(id)
	local anchor, block = B.anchors[id], B.Block(id)
	if not anchor or not block or inCombat() then return end
	local valid = { CENTER = true, TOP = true, BOTTOM = true, LEFT = true, RIGHT = true, TOPLEFT = true, TOPRIGHT = true, BOTTOMLEFT = true, BOTTOMRIGHT = true }
	local point = valid[block.point] and block.point or "CENTER"
	local relativePoint = valid[block.relativePoint] and block.relativePoint or point
	anchor:ClearAllPoints()
	anchor:SetPoint(point, UIParent, relativePoint, bounded(block.x, -4000, 4000, 0), bounded(block.y, -4000, 4000, 0))
	local edit = addon.EditMode
	local data = edit and edit.EnsureLayoutData and edit:EnsureLayoutData("EQOLRaidBlock" .. id)
	if data then data.point, data.relativePoint, data.x, data.y = point, relativePoint, block.x or 0, block.y or 0 end
end
function B.VisibilityFrames(id)
	local targets = {}
	for _, header in ipairs(UF.GroupFrames._raidGroupHeaders or {}) do
		if header._eqolRaidBlockOwner == id then
			targets[#targets + 1] = header
			if header._eqolGroupIndicatorProxy then targets[#targets + 1] = header._eqolGroupIndicatorProxy end
		end
	end
	return targets
end
function B.SyncVisibility()
	local edit = addon.EditMode
	if not (edit and edit.frames and edit._applyVisibility) or inCombat() then return end
	local raid = edit.frames["EQOL_UF_GROUP_RAID"]
	if raid then edit:_applyVisibility(raid) end
	for id = 1, 8 do
		local entry = edit.frames["EQOLRaidBlock" .. id]
		if entry then edit:_applyVisibility(entry) end
	end
end
B.overlayColors = {
	{ .20, .75, 1 }, { 1, .45, .20 }, { .35, .90, .45 }, { .80, .45, 1 },
	{ 1, .80, .20 }, { 1, .40, .70 }, { .25, .95, .85 }, { .65, .75, 1 },
}
function B.EnsureAnchors()
	if inCombat() or B.registering then return end
	local edit = addon.EditMode
	if not (edit and edit.RegisterFrame and UF.GroupFrames and UF.GroupFrames.anchors and UF.GroupFrames.anchors.raid) then return end
	B.registering = true
	for id = 1, 8 do
		if B.Block(id) then
			local anchor = B.anchors[id]
			if not anchor then
				anchor = CreateFrame("Frame", "EQOLRaidBlockAnchor" .. id, UIParent)
				anchor:SetSize(100, 120)
				B.anchors[id] = anchor
			end
			local key = "EQOLRaidBlock" .. id
			if not (edit.frames and edit.frames[key]) then
				edit:RegisterFrame(key, {
					frame = anchor, title = B.Title(id), overlayColor = B.overlayColors[id], managerCategory = "unitFrames", layoutDefaults = B.DefaultBlock(id),
					managePosition = false, persistPosition = false, normalizePosition = true,
					settings = B.BlockSettings(id), settingsNavigation = { direct = true, scopeKey = key, reset = function(_, apply) B.RunSettingsReset(apply) end },
					onApply = function() B.SetAnchorPosition(id) end,
					onPositionChanged = function(_, _, data)
						local block = B.Block(id)
						if not block or type(data) ~= "table" or inCombat() then return end
						block.point, block.relativePoint = data.point, data.relativePoint or data.point
						block.x, block.y = data.x, data.y
						B.SetAnchorPosition(id)
					end,
					isEnabled = function()
						local cfg, options = B.Config(), B.Options()
						return cfg and cfg.enabled == true and options and options.enabled == true and B.Block(id) ~= nil
					end,
					relativeTo = function() return UIParent end,
					visibilityFrames = function() return B.VisibilityFrames(id) end,
					allowDrag = function() return B.Block(id) ~= nil end,
					showOutsideEditMode = false, showReset = false, showSettingsReset = false, enableOverlayToggle = true,
				})
			elseif anchor._raidBlockTitle ~= B.Title(id) then
				edit:SetFrameTitle(key, B.Title(id))
			end
			B.SyncSettings(id)
			anchor._raidBlockTitle = B.Title(id)
			edit:RefreshFrame(key)
		elseif B.anchors[id] and edit.frames and edit.frames["EQOLRaidBlock" .. id] then
			edit:UnregisterFrame("EQOLRaidBlock" .. id, true)
		end
	end
	B.registering = nil
	local raidEntry = edit.frames and edit.frames["EQOL_UF_GROUP_RAID"]
	if raidEntry and edit._applyVisibility then edit:_applyVisibility(raidEntry) end
end
-- Pure layout planner: every visible group gets exactly one owner; imported
-- overlapping assignments are resolved deterministically by block slot.
function B.Plan(options, specs, layout)
	local available, claimed, plan, counts = {}, {}, {}, {}
	for _, spec in ipairs(specs or {}) do available[spec.group] = true end
	local function put(group, owner, slot, blockLayout)
		local x, y = UF.GroupFrames.GetRaidBlockOffset(blockLayout, slot)
		local direction = UF.GroupFrames.ResolveRaidCrossGrowthValue(blockLayout.groupGrowth, blockLayout.growth)
		local point = ({ LEFT = "TOPRIGHT", RIGHT = "TOPLEFT", UP = "BOTTOMLEFT", DOWN = "TOPLEFT" })[direction]
		plan[group] = { owner = owner, slot = slot, x = x, y = y, point = point }
	end
	for id = 1, 8 do
		local block = options.blocks[id]
		if type(block) == "table" then
			counts[id] = 0
			local blockLayout = copy(layout)
			blockLayout.groupGrowth = block.growth or "RIGHT"
			blockLayout.groupsPerRow = bounded(block.groupsPerRow, 1, 8, 4)
			for _, group in ipairs(B.ParseGroups(block.groups) or {}) do
				if not claimed[group] then
					claimed[group] = true
					if available[group] then counts[id] = counts[id] + 1; put(group, id, counts[id], blockLayout) end
				end
			end
		end
	end
	counts[0] = 0
	for _, spec in ipairs(specs or {}) do
		if not claimed[spec.group] then
			counts[0] = counts[0] + 1
			put(spec.group, 0, counts[0] + (layout.normalSlotOffset or 0), layout)
		end
	end
	return plan, counts
end
function B.Prepare(cfg, layout, specs)
	if not B.IsActive(cfg) then return end
	B.EnsureAnchors()
	local plan, counts = B.Plan(cfg.raidBlocks, specs, layout)
	for group, placement in pairs(plan) do
		placement.anchor = placement.owner == 0 and UF.GroupFrames.anchors.raid or B.anchors[placement.owner]
		if not placement.anchor then plan[group] = nil end
	end
	for id = cfg._raidBlocksPreview and 1 or 0, 8 do
		local anchor = id == 0 and UF.GroupFrames.anchors.raid or B.anchors[id]
		if anchor then
			local width, height = 0, 0
			for _, placement in pairs(plan) do
				if placement.owner == id then
					width = math.max(width, math.abs(placement.x) + layout.perHeaderW)
					height = math.max(height, math.abs(placement.y) + layout.perHeaderH)
				end
			end
			-- An attached Spotlight stays with the remaining groups at the main anchor.
			if id == 0 and layout._raidBlocksSpotlight then
				local slot = layout.normalSlotOffset == 1 and 1 or counts[0] + 1
				layout.spotlightOffsetX, layout.spotlightOffsetY = UF.GroupFrames.GetRaidBlockOffset(layout, slot)
				width = math.max(width, math.abs(layout.spotlightOffsetX) + layout.blockStepW)
				height = math.max(height, math.abs(layout.spotlightOffsetY) + layout.blockStepH)
			end
			if id > 0 and (counts[id] or 0) == 0 then
				width, height = math.max(width, 180), math.max(height, 120)
			end
			anchor:SetSize(math.max(layout.w or 100, width), math.max(layout.h or 24, height))
		end
	end
	return plan
end
function B.LayoutPreview(cfg, frames, layout)
	if not B.IsActive(cfg) then return end
	local specs, seen = {}, {}
	for _, frame in ipairs(frames) do
		local entry = frame._eqolRaidBlockPreview
		if frame:IsShown() and entry and not seen[entry.group] then specs[#specs + 1] = { group = entry.group }; seen[entry.group] = true end
	end
	local plan = B.Prepare(cfg, layout, specs)
	for _, frame in ipairs(frames) do
		local entry = frame._eqolRaidBlockPreview
		local placement = entry and plan and plan[entry.group]
		if frame:IsShown() and placement and cfg._raidBlocksPreview and placement.owner == 0 then
			UF.GroupFrames:UnitButton_ClearUnit(frame)
			frame:Hide()
		elseif frame:IsShown() and placement then
			local index = entry.unitIndex - 1
			local x = placement.x - (placement.point:find("RIGHT", 1, true) and layout.perHeaderW or 0)
			local y = placement.y + (placement.point:find("BOTTOM", 1, true) and layout.perHeaderH or 0)
			if layout.growth == "LEFT" then x = x + layout.perHeaderW - layout.w end
			if layout.growth == "UP" then y = y - layout.perHeaderH + layout.h end
			if layout.growth == "LEFT" or layout.growth == "RIGHT" then x = x + index * (layout.w + layout.spacing) * (layout.growth == "LEFT" and -1 or 1)
			else y = y + index * (layout.h + layout.spacing) * (layout.growth == "UP" and 1 or -1) end
			if frame:GetParent() ~= placement.anchor then frame:SetParent(placement.anchor) end
			frame:ClearAllPoints()
			frame:SetPoint("TOPLEFT", placement.anchor, placement.point, x, y)
		end
	end
end
function B.RunSettingsReset(apply)
	B.resetDepth = (B.resetDepth or 0) + 1
	local ok, err = pcall(apply)
	B.resetDepth = B.resetDepth - 1
	if B.resetDepth == 0 and B.resetPending then B.resetPending = nil; B.Refresh() end
	if not ok then error(err) end
end
function B.Refresh()
	if (B.resetDepth or 0) > 0 then B.resetPending = true; return end
	local gf = UF.GroupFrames
	if not gf then return end
	if inCombat() then gf:MarkPendingHeaderRefresh("raid"); return end
	B.EnsureAnchors()
	gf:ApplyHeaderAttributes("raid")
	if not B.WantsPreview() or not (gf._previewActive and gf._previewActive.raid) then B.HidePreview() end
	local edit = addon.EditMode
	if edit and edit.RefreshFrame then
		for id = 1, 8 do if B.Block(id) then edit:RefreshFrame("EQOLRaidBlock" .. id) end end
	end
end

function B.Decorate(row, field, default)
	row.field, row.navigationField = field, field
	local isEnabled = row.isEnabled
	row.isEnabled = function(...)
		if inCombat() then return false end
		if field ~= "raidBlocksEnabled" then
			local options = B.Options()
			if not options or options.enabled ~= true then return false end
		end
		return not isEnabled or isEnabled(...)
	end
	if default ~= nil and addon.EditModeNavigationDefaults then addon.EditModeNavigationDefaults.Set(row, default) end
	return row
end
function B.BlockSettings(id, parentId)
	local T = addon.EditModeLib.SettingType
	local defaults, settings = B.DefaultBlock(id), {}
	if not parentId then
		parentId = "raidBlock" .. id
		settings[1] = { name = L["UFRaidBlocks"], kind = T.Collapsible, id = parentId, navigationReset = function() B.ResetBlock(id) end }
	end
	local function add(row, field, default)
		row.parentId = parentId
		settings[#settings + 1] = B.Decorate(row, "raidBlock" .. id .. field, default)
	end
	local function get(field) local block = B.Block(id); return block and block[field] or defaults[field] end
	local function set(field, value)
		if inCombat() then return end
		local block = B.Block(id)
		if block then block[field] = value; B.Refresh() end
	end
	add({ name = L["Name"], kind = T.Input, maxChars = 48, get = function() return get("name") end,
		set = function(_, value) set("name", tostring(value or ""):sub(1, 192)) end }, "Name", defaults.name)
	local groupOptions = {}
	for group = 1, 8 do groupOptions[#groupOptions + 1] = { value = group, text = tostring(group), label = tostring(group) } end
	add({ name = L["UFRaidBlockGroups"], kind = T.MultiDropdown, values = groupOptions, tooltip = L["UFRaidBlockGroupsDesc"],
		isSelected = function(_, group)
			for _, assigned in ipairs(B.ParseGroups(get("groups")) or {}) do if group == assigned then return true end end
			return false
		end,
		setSelected = function(_, group, selected)
			if inCombat() or not B.Block(id) then return end
			local groups, found = {}, false
			for _, assigned in ipairs(B.ParseGroups(get("groups")) or {}) do
				if assigned == group then found = true end
				if assigned ~= group or selected then groups[#groups + 1] = assigned end
			end
			if selected and not found then groups[#groups + 1] = group end
			B.AssignGroups(id, groups)
			B.Refresh()
		end }, "Groups", {})
	add({ name = L["UFRaidBlockOrder"], kind = T.Input, maxChars = 32, tooltip = L["UFRaidBlockOrderDesc"],
		get = function() return table.concat(B.ParseGroups(get("groups")) or {}, ",") end,
		set = function(_, value)
			if inCombat() then return end
			local groups = B.ParseGroups(value)
			if not groups then
				if UIErrorsFrame then UIErrorsFrame:AddMessage(L["UFRaidBlockInvalidGroups"], 1, 0.2, 0.2) end
				return
			end
			B.AssignGroups(id, groups); B.Refresh()
		end }, "Order", "")
	local directions = { { value = "RIGHT", label = L["Right"] }, { value = "LEFT", label = L["Left"] }, { value = "DOWN", label = L["Down"] }, { value = "UP", label = L["Up"] } }
	add({ name = L["Group Growth"], kind = T.Dropdown, get = function() return get("growth") end,
		set = function(_, value) set("growth", value) end, values = directions }, "Growth", "RIGHT")
	add({ name = L["UFRaidBlockPerLine"], kind = T.Slider, minValue = 1, maxValue = 8, valueStep = 1, allowInput = true,
		get = function() return get("groupsPerRow") end, set = function(_, value) set("groupsPerRow", bounded(value, 1, 8, 4)) end }, "PerLine", 4)
	for _, axis in ipairs({ "x", "y" }) do
		add({ name = L[axis == "x" and "Offset X" or "Offset Y"], kind = T.Slider, minValue = -4000, maxValue = 4000, valueStep = 1, allowInput = true,
			get = function() return get(axis) end, set = function(_, value) set(axis, bounded(value, -4000, 4000, 0)) end }, axis, defaults[axis])
	end
	add({ name = L["UFRaidBlockRemove"], kind = T.Action, navigationResetExcluded = true,
		onClick = function() B.RemoveBlock(id) end,
		isEnabled = function() return not inCombat() and B.Block(id) ~= nil end }, "Remove")
	return settings
end
function B.Difficulties()
	local result = {}
	-- Only offer difficulties this client knows; include legacy raid modes when
	-- supported rather than treating their IDs as modern Normal/Heroic modes.
	for _, id in ipairs({ 14, 15, 16, 17, 3, 4, 5, 6, 7, 9, 148, 192 }) do
		local name, instanceType = GetDifficultyInfo(id)
		if name and instanceType == "raid" then result[#result + 1] = { value = id, text = name, label = name } end
	end
	return result
end
function B.AppendSettings(settings)
	local T = addon.EditModeLib.SettingType
	local function add(row, field, default)
		row.parentId = "raidBlocks"
		settings[#settings + 1] = B.Decorate(row, field, default)
	end
	settings[#settings + 1] = { name = L["UFRaidBlocks"], kind = T.Collapsible, id = "raidBlocks" }
	add({ name = L["UFRaidBlocksEnable"], kind = T.Checkbox, tooltip = L["UFRaidBlocksDesc"],
		get = function() local options = B.Options(); return options and options.enabled == true or false end,
		set = function(_, value) if inCombat() then return end; local options = B.Options(true); if options then options.enabled = value == true; B.Refresh() end end }, "raidBlocksEnabled", false)
	add({ name = L["UFRaidBlocksPreview"], kind = T.Checkbox, get = function() return B.preview end,
		set = function(_, value) if inCombat() then return end; B.preview = value == true; if B.preview then B.StartPreview() end; B.Refresh() end }, "raidBlocksPreview", true)
	add({ name = L["UFRaidBlocksDifficulty"], kind = T.MultiDropdown, optionfunc = B.Difficulties, customDefaultText = _G.ALL or L["All"], tooltip = L["UFRaidBlocksConditionsDesc"],
		isSelected = function(_, id) local options = B.Options(); return options and options.difficulties and options.difficulties[id] == true or false end,
		setSelected = function(_, id, selected)
			if inCombat() then return end
			local options = B.Options(true)
			if options then options.difficulties = options.difficulties or {}; options.difficulties[id] = selected and true or nil; B.Refresh() end
		end }, "raidBlocksDifficulty", {})
	for _, field in ipairs({ "minSize", "maxSize" }) do
		local default = field == "minSize" and 1 or 40
		add({ name = L[field == "minSize" and "UFRaidBlocksMinSize" or "UFRaidBlocksMaxSize"], kind = T.Slider,
			minValue = 1, maxValue = 40, valueStep = 1, allowInput = true, tooltip = L["UFRaidBlocksConditionsDesc"],
			get = function() local options = B.Options(); return options and options[field] or default end,
			set = function(_, value)
				if inCombat() then return end
				local options = B.Options(true)
				if not options then return end
				options[field] = bounded(value, 1, 40, default)
				if (options.minSize or 1) > (options.maxSize or 40) then
					if field == "minSize" then options.maxSize = options.minSize else options.minSize = options.maxSize end
				end
				B.Refresh()
			end }, "raidBlocks" .. field, default)
	end
	add({ name = L["UFRaidBlockAdd"], kind = T.Action, navigationResetExcluded = true,
		onClick = function() B.AddBlock() end,
		isEnabled = function()
			if inCombat() then return false end
			for id = 1, 8 do if not B.Block(id) then return true end end
			return false
		end }, "raidBlocksAdd")
	add({ name = L["UFRaidBlocksPreset"], kind = T.Dropdown, customDefaultText = _G.NONE or L["All"], tooltip = L["UFRaidBlocksPresetDesc"], navigationResetExcluded = true,
		get = function() return "" end,
		set = function(_, value) if value == "odd" or value == "half" then B.Preset(value == "odd") end end,
		values = { { value = "odd", label = L["UFRaidBlocksOddEven"] }, { value = "half", label = L["UFRaidBlocksHalves"] } } }, "raidBlocksPreset")
	for id = 1, 8 do
		local parent = "raidBlock" .. id
		settings[#settings + 1] = { name = string.format(L["UFRaidBlockNumber"], id), kind = T.Collapsible, id = parent,
			isShown = function() return B.Block(id) ~= nil end,
			navigationReset = function() B.ResetBlock(id) end,
			navigationHint = function() return L["UFRaidBlockAdd"], nil, "raidBlocks" end }
		for _, row in ipairs(B.BlockSettings(id, parent)) do settings[#settings + 1] = row end
	end
end
