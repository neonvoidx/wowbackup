local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then addon = _G[parentAddonName] else error(parentAddonName .. " is not loaded") end
local CP = addon.Aura.CooldownPanels
local Helper, Bars = CP.helper, CP.Bars
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local BG = { views = setmetatable({}, { __mode = "k" }), editors = setmetatable({}, { __mode = "k" }) }
CP.BarGroups = BG
BG.SECTION = "eqolCooldownBarGroups"
BG.GENERAL = "eqolCooldownBarGroupGeneral"
BG.LAYOUT = "eqolCooldownBarGroupLayout"
BG.OWNER_PREFIX = "__BAR_GROUP__:"
BG.LAYOUT_FIELDS = { "barPanelWidth", "barPanelHeight", "barPanelOrientation", "barPanelIconSize", "spacing", "direction", "wrapCount", "wrapDirection", "growthPoint" }

-- A group stores only explicitly changed fields; other fields continue following the panel.
function BG.MigrateStyle(group)
	if group.barStyleVersion == 1 then return end
	if group.usePanelStyle == false then
		group.barStyleOverrides = group.barStyleOverrides or {}
		for _, scope in pairs(Bars.PANEL_STYLE_GROUPS or {}) do group.barStyleOverrides[scope] = true end
	end
	if group.layout and group.layout.barPanelIconSize ~= nil then
		group.barStyleOverrides = group.barStyleOverrides or {}
		group.barStyleOverrides.Icon = true
	end
	group.usePanelStyle, group.barStyleVersion = nil, 1
end
function BG.StyleOverridden(group, scope)
	return group.barStyleOverrides and group.barStyleOverrides[scope] == true or false
end
function BG.FieldOverridden(group, field)
	for scope, enabled in pairs(group.barStyleOverrides or {}) do
		if enabled and Helper.BarStyleBelongsToScope(field, scope) then return true end
	end
	return false
end
function BG.Enabled(layout) return Helper.IsBarLayout(layout) and layout.barGroupsEnabled == true end
BG.SIDES = { "TOP", "BOTTOM", "LEFT", "RIGHT" }
BG.SIDE_DEFAULTS = {
	TOP = { point = "BOTTOM", relativePoint = "TOP", x = 0, y = 16, direction = "UP", orientation = "HORIZONTAL", icon = "LEFT" },
	BOTTOM = { point = "TOP", relativePoint = "BOTTOM", x = 0, y = -16, direction = "DOWN", orientation = "HORIZONTAL", icon = "LEFT" },
	LEFT = { point = "RIGHT", relativePoint = "LEFT", x = -16, y = 0, direction = "LEFT", orientation = "VERTICAL", icon = "BOTTOM" },
	RIGHT = { point = "LEFT", relativePoint = "RIGHT", x = 16, y = 0, direction = "RIGHT", orientation = "VERTICAL", icon = "BOTTOM" },
}
function BG.Label(group)
	return L[({ TOP = "Top", BOTTOM = "Bottom", LEFT = "Left", RIGHT = "Right" })[group.side]]
end
function BG.DefaultLayout(side, parent)
	local defaults = BG.SIDE_DEFAULTS[side]
	local width = Helper.ClampInt(parent.barPanelWidth, 5, 2000, 26)
	local height = Helper.ClampInt(parent.barPanelHeight, 5, 2000, 240)
	local length, thickness = math.max(width, height), math.min(width, height)
	return { barPanelOrientation = defaults.orientation, barPanelWidth = defaults.orientation == "VERTICAL" and thickness or length,
		barPanelHeight = defaults.orientation == "VERTICAL" and length or thickness, direction = defaults.direction, growthPoint = "TOPLEFT" }
end
function BG.ApplyStyleDefaults(group, scope)
	if scope == "Icon" and (group.side == "LEFT" or group.side == "RIGHT") then
		group.barStyleOverrides = group.barStyleOverrides or {}
		group.barStyleOverrides.Icon = true
		group.barStyle = group.barStyle or {}
		group.barStyle.barIconPosition = "BOTTOM"
	end
end
function BG.Ensure(panel)
	local layout = panel and panel.layout
	if not layout or layout.barGroupsVersion == 2 or not (BG.Enabled(layout) or type(layout.barGroups) == "table") then return end
	local old = type(layout.barGroups) == "table" and layout.barGroups or {}
	local assigned, mapping, groups = {}, {}, {}
	for index, side in ipairs(BG.SIDES) do
		local defaults = BG.SIDE_DEFAULTS[side]
		groups[index] = { id = index, side = side, layout = BG.DefaultLayout(side, layout), x = defaults.x, y = defaults.y }
		BG.ApplyStyleDefaults(groups[index], "Icon")
	end
	for _, previous in ipairs(old) do
		local side = BG.SIDE_DEFAULTS[previous.side] and previous.side or BG.SIDE_DEFAULTS[previous.relativePoint] and previous.relativePoint
		if not side or assigned[side] then
			for _, candidate in ipairs({ "BOTTOM", "TOP", "LEFT", "RIGHT" }) do if not assigned[candidate] then side = candidate; break end end
		end
		side = side or "BOTTOM"
		local target = 2
		for index, value in ipairs(BG.SIDES) do if value == side then target = index end end
		if not assigned[side] then
			groups[target].usePanelStyle = previous.usePanelStyle
			groups[target].barStyleOverrides = previous.barStyleOverrides
			groups[target].barStyle = previous.barStyle
			groups[target].compact = previous.compact
			assigned[side] = true
		end
		if previous.id then mapping[previous.id] = target end
	end
	for _, entry in pairs(panel.entries or {}) do entry.barGroupId = mapping[entry.barGroupId] or 2 end
	layout.barGroups, layout.barGroupsVersion, layout.barGroupNextId = groups, 2, nil
end
function BG.Groups(layout, create)
	if create and layout.barGroupsVersion ~= 2 then BG.Ensure({layout=layout}) end
	local groups = type(layout.barGroups) == "table" and layout.barGroups or {}
	for _, group in ipairs(groups) do BG.MigrateStyle(group) end
	return groups
end
function BG.Find(layout, id)
	for _, group in ipairs(BG.Groups(layout)) do if group.id == id then return group end end
end
function BG.EntryGroup(entry, layout)
	if not BG.Enabled(layout) then return end
	local groups = BG.Groups(layout, true)
	return BG.Find(layout, entry and entry.barGroupId) or BG.Find(layout, 2) or groups[1]
end
function BG.Layout(group, layout)
	BG.MigrateStyle(group)
	layout = rawget(layout, "_eqolBarGroupParent") or layout
	local cached = BG.views[group]
	local version = Helper.barPanelStyleVersions[layout] or 0
	if not cached or cached.parent ~= layout or cached.version ~= version or cached.parentStyle ~= layout.barStyle then
		local view = {}
		for _, field in ipairs(BG.LAYOUT_FIELDS) do
			local value = group.layout and group.layout[field]
			if value ~= nil and (field ~= "barPanelIconSize" or BG.StyleOverridden(group, "Icon")) then view[field] = value end
		end
		view.barStyle = setmetatable({}, { __index = function(_, field)
			local value = group.barStyle and group.barStyle[field]
			if value ~= nil and BG.FieldOverridden(group, field) then return value end
			return layout.barStyle and layout.barStyle[field]
		end })
		view._eqolBarGroupId = group.id
		view._eqolBarGroupParent = layout
		view = setmetatable(view, { __index = layout })
		cached = { parent = layout, version = version, parentStyle = layout.barStyle, view = view }
		BG.views[group] = cached
	end
	return cached.view
end
function BG.EntryLayout(entry, layout)
	layout = rawget(layout, "_eqolBarGroupParent") or layout
	local group = BG.EntryGroup(entry, layout)
	return group and BG.Layout(group, layout) or layout
end
function BG.Binding(panel, entry)
	local sync = CP.SpellGroups and CP.SpellGroups.Sync
	if sync and sync.GetBarGroupBinding then return sync:GetBarGroupBinding(panel, entry) end
end
function BG.HandleBinding(handle)
	local panelId = handle._eqolBarGroupPanelId
	if not panelId or not CP:IsPanelLayoutEditActive(panelId) then return end
	local panel = CP:GetPanel(panelId)
	local entry = panel and panel.entries and panel.entries[handle._eqolLayoutEntryId]
	return BG.Binding(panel, entry)
end
function BG.ShowBindingTooltip(handle)
	local destination, ownerId = BG.HandleBinding(handle)
	local panel = CP:GetPanel(handle._eqolBarGroupPanelId)
	local target = destination and panel and BG.Find(panel.layout, destination)
	local owner = ownerId and CP.SpellGroups:GetGroup(ownerId)
	local tooltip = _G.GameTooltip
	if not (target and owner and tooltip) then return end
	tooltip:SetOwner(handle, "ANCHOR_RIGHT")
	tooltip:SetText(L["CDLSpellGroupsTitle"])
	tooltip:AddLine(string.format(L["CooldownPanelBarGroupLockedTooltip"], owner.name, BG.Label(target)), 1, 1, 1, true)
	tooltip:Show()
end
function BG.HandleEnter(handle, ...)
	if handle._eqolBarGroupEnter then handle._eqolBarGroupEnter(handle, ...) end
	BG.ShowBindingTooltip(handle)
end
function BG.HandleLeave(handle, ...)
	if handle._eqolBarGroupLeave then handle._eqolBarGroupLeave(handle, ...) end
	local tooltip = _G.GameTooltip
	if tooltip and tooltip:IsOwned(handle) then tooltip:Hide() end
end
function BG.HandleDragStart(handle, ...)
	if BG.HandleBinding(handle) then BG.ShowBindingTooltip(handle); return end
	if handle._eqolBarGroupDragStart then return handle._eqolBarGroupDragStart(handle, ...) end
end
function BG.HandleHide(handle, ...)
	if handle._eqolBarGroupHide then handle._eqolBarGroupHide(handle, ...) end
	local tooltip = _G.GameTooltip
	if tooltip and tooltip:IsOwned(handle) then tooltip:Hide() end
end
BG.HANDLE_SCRIPTS = {
	OnEnter = { callback = BG.HandleEnter, field = "_eqolBarGroupEnter" },
	OnLeave = { callback = BG.HandleLeave, field = "_eqolBarGroupLeave" },
	OnDragStart = { callback = BG.HandleDragStart, field = "_eqolBarGroupDragStart" },
	OnHide = { callback = BG.HandleHide, field = "_eqolBarGroupHide" },
}
function BG.ConfigureEntryHandle(panelId, icon)
	local handle = icon and icon.layoutHandle
	if not handle then return end
	handle._eqolBarGroupPanelId = panelId
	local locked = BG.HandleBinding(handle) ~= nil
	local badge = handle._eqolBarGroupLock
	if locked and not badge then
		badge = handle:CreateTexture(nil, "OVERLAY", nil, 7)
		badge:SetTexture("Interface\\AddOns\\EnhanceQoL\\Icons\\ClosedLock.tga")
		badge:SetSize(12, 12)
		badge:SetPoint("TOPRIGHT", handle, "TOPRIGHT", -1, -1)
		handle._eqolBarGroupLock = badge
	end
	if badge then badge:SetShown(locked) end
	if not CP:IsPanelLayoutEditActive(panelId) then return end
	for event, config in pairs(BG.HANDLE_SCRIPTS) do
		local current = handle:GetScript(event)
		if current ~= config.callback and (current or event == "OnHide") then
			handle[config.field] = current
			handle:SetScript(event, config.callback)
		end
	end
end
if CP.ConfigureLayoutEditPanelIcon then
	BG.originalConfigureLayoutIcon = CP.ConfigureLayoutEditPanelIcon
	function CP:ConfigureLayoutEditPanelIcon(panelId, icon, ...)
		BG.originalConfigureLayoutIcon(self, panelId, icon, ...)
		BG.ConfigureEntryHandle(panelId, icon)
	end
end
function BG.CanAssign(source, entry, target, groupId)
	local sourceGroup = BG.Binding(source, entry)
	if sourceGroup and (source ~= target or sourceGroup ~= groupId) then return false end
	if source == target then return true end
	local targetGroup = BG.Binding(target, entry)
	return not targetGroup or targetGroup == groupId
end
function BG.SetEntryGroup(panelId, entryId, groupId)
	if InCombatLockdown() then return end
	local panel = CP:GetPanel(panelId)
	local entry = panel and panel.entries and panel.entries[entryId]
	if not entry or not BG.Enabled(panel.layout) or BG.Binding(panel, entry) or not BG.Find(panel.layout, groupId) then return end
	entry.barGroupId = groupId
	BG.Refresh(panelId)
end
function BG.Refresh(panelId)
	local panel = CP:GetPanel(panelId)
	if not panel then return end
	for _, group in ipairs(BG.Groups(panel.layout)) do BG.views[group] = nil end
	Helper.InvalidateBarPanelStyle(panel.layout)
	if CP.AuraContainers and CP.AuraContainers.ReleasePanelStates then CP.AuraContainers:ReleasePanelStates(panelId) end
	CP:RefreshPanel(panelId)
	CP:RefreshEditor()
	local runtime = CP.runtime and CP.runtime[panelId]
	if runtime then Helper.RefreshBarPanelSettings(runtime.layoutPanelSettings) end
	local opened = runtime and runtime.barGroupDialog
	local group = opened and BG.Find(panel.layout, opened.groupId)
	if group and opened.dialog then
		if opened.dialog.context then opened.dialog.context.title = BG.Label(group) end
		if opened.dialog.Title then opened.dialog.Title:SetText(BG.Label(group)) end
	end
end
function BG.Order(panel, groupId)
	local order = {}
	for _, id in ipairs(panel.order or {}) do
		local entry = panel.entries and panel.entries[id]
		local group = entry and BG.EntryGroup(entry, panel.layout)
		if group and group.id == groupId then order[#order + 1] = id end
	end
	return order
end
function BG.MoveEntry(panelId, entryId, step)
	if InCombatLockdown() then return end
	local panel = CP:GetPanel(panelId)
	local entry = panel and panel.entries[entryId]
	local group = entry and BG.EntryGroup(entry, panel.layout)
	if not group then return end
	local order = BG.Order(panel, group.id)
	for index, id in ipairs(order) do
		local other = order[index + step]
		if id == entryId and other then
			local first, second
			for i, value in ipairs(panel.order) do if value == id then first = i elseif value == other then second = i end end
			panel.order[first], panel.order[second] = panel.order[second], panel.order[first]
			BG.Refresh(panelId)
			return
		end
	end
end

-- Reserved editor IDs keep group appearance on the existing bar controls.
function BG.EditorId(groupId, scopeId) return -1000 - groupId * 3 + scopeId end
BG.originalStyleEditor = Bars.GetPanelStyleEditor
function Bars.GetPanelStyleEditor(panel, scopeId)
	if scopeId > -1003 then return BG.originalStyleEditor(panel, scopeId) end
	local encoded = -scopeId - 1000
	local groupId, modeIndex = math.floor(encoded / 3), encoded % 3
	local group = BG.Find(panel.layout, groupId)
	if not group then return end
	local editors = BG.editors[group]
	if not editors then editors = {}; BG.editors[group] = editors end
	if not editors[modeIndex] then
		editors[modeIndex] = setmetatable({}, {
			__index = function(_, field)
				if field == "_eqolPanelBarSettings" then return true end
				if field == "type" then return "SPELL" end
				if field == "displayMode" then return "BAR" end
				if field == "barMode" then return modeIndex == 1 and "CHARGES" or modeIndex == 2 and "STACKS" or "COOLDOWN" end
				local layout = BG.Layout(group, panel.layout)
				if field == "barOrientation" then return layout.barPanelOrientation end
				if field == "barIconSize" then return layout.barPanelIconSize end
				local style = layout.barStyle
				if style and style[field] ~= nil then return style[field] end
				if field == "barDurationTextProfile" then return nil end
				if field == "showStacks" then return false end
				return Helper.GetBarPanelStyleDefault(field, Bars.DEFAULTS[field], layout)
			end,
			__newindex = function(view, field, value)
				if field == "barIconSize" then group.layout.barPanelIconSize = value
				elseif Helper.IsSharedBarStyleField(field, Bars.DEFAULTS) then
					group.barStyle = group.barStyle or {}; group.barStyle[field] = value
				elseif type(field) == "string" and field:find("_eqol", 1, true) == 1 then rawset(view, field, value) end
				BG.views[group] = nil
			end,
		})
	end
	return editors[modeIndex]
end

function BG.Frame(panelId, group, parent)
	local runtime = CP.runtime[panelId]
	runtime.barGroupFrames = runtime.barGroupFrames or {}
	local frame = runtime.barGroupFrames[group.id]
	if not frame then
		frame = CreateFrame("Frame", nil, parent)
		frame:SetSize(1, 1)
		local handle = CreateFrame("Button", nil, frame)
		handle:SetSize(72, 18)
		handle.background = handle:CreateTexture(nil, "BACKGROUND")
		handle.background:SetAllPoints()
		handle.background:SetColorTexture(0.06, 0.07, 0.09, 0)
		local accent = handle:CreateTexture(nil, "BORDER")
		accent:SetPoint("BOTTOMLEFT", 6, 0); accent:SetPoint("BOTTOMRIGHT", -6, 0); accent:SetHeight(1)
		accent:SetColorTexture(0.35, 0.65, 0.9, 0.8); accent:Hide()
		handle.accent = accent
		handle.label = handle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		handle.label:SetPoint("LEFT", 6, 0); handle.label:SetPoint("RIGHT", -6, 0)
		handle.label:SetJustifyH("CENTER"); handle.label:SetTextColor(0.78, 0.82, 0.88, 0.9)
		handle:SetScript("OnEnter", function() BG.UpdateDropFeedback(frame) end)
		handle:SetScript("OnLeave", function() BG.UpdateDropFeedback(frame) end)
		handle:SetScript("OnUpdate", function(_, elapsed)
			frame.feedbackElapsed = (frame.feedbackElapsed or 0) + elapsed
			if frame.feedbackElapsed < 0.05 then return end
			frame.feedbackElapsed = 0
			BG.UpdateDropFeedback(frame)
		end)
		handle:SetScript("OnHide", function() if frame.indicator then frame.indicator:Hide() end; if frame.dropZone then frame.dropZone:Hide() end end)
		handle:SetFrameLevel(parent:GetFrameLevel() + 30)
		handle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		handle.panelId, handle.groupId = panelId, group.id
		handle:SetScript("OnReceiveDrag", function(self) BG.Receive(self.panelId, self.groupId) end)
		handle:SetScript("OnClick", function(self, button)
			if button == "LeftButton" and BG.Receive(self.panelId, self.groupId) then return end
			BG.Open(self.panelId, self.groupId, self)
		end)
		local drop = CreateFrame("Button", nil, frame)
		drop:SetPoint("TOPLEFT", frame, "TOPLEFT", -6, 6); drop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 6, -6)
		drop:SetFrameLevel(parent:GetFrameLevel() + 1)
		drop.background = drop:CreateTexture(nil, "BACKGROUND"); drop.background:SetAllPoints()
		drop.background:SetColorTexture(0.2, 0.48, 0.75, 0.08)
		drop:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		drop:SetScript("OnReceiveDrag", function() BG.Receive(panelId, group.id) end)
		drop:SetScript("OnMouseUp", function(_, button)
			if button == "LeftButton" then BG.Receive(panelId, group.id) elseif button == "RightButton" then BG.Open(panelId, group.id, handle) end
		end)
		drop:SetScript("OnEnter", function() BG.UpdateDropFeedback(frame) end)
		drop:SetScript("OnLeave", function() BG.UpdateDropFeedback(frame) end)
		frame.dropZone = drop
		frame.handle = handle
		frame.panelId, frame.groupId = panelId, group.id
		local marker = CreateFrame("Frame", nil, frame)
		marker:SetSize(8, 32); marker:SetFrameLevel(parent:GetFrameLevel() + 40); marker:EnableMouse(false)
		marker.Shadow = marker:CreateTexture(nil, "ARTWORK"); marker.Shadow:SetPoint("CENTER")
		marker.Shadow:SetColorTexture(0.015, 0.025, 0.045, 0.95)
		marker.Texture = marker:CreateTexture(nil, "OVERLAY"); marker.Texture:SetAllPoints()
		marker.Texture:SetColorTexture(0.5, 0.86, 1, 1)
		marker.caps = {}
		for index = 1, 2 do
			local shadow = marker:CreateTexture(nil, "ARTWORK")
			shadow:SetColorTexture(0.015, 0.025, 0.045, 0.95)
			local texture = marker:CreateTexture(nil, "OVERLAY")
			texture:SetColorTexture(0.75, 0.94, 1, 1)
			marker.caps[index] = { shadow = shadow, texture = texture }
		end
		marker:Hide(); frame.indicator = marker
		runtime.barGroupFrames[group.id] = frame
	end
	frame:ClearAllPoints()
	local defaults = BG.SIDE_DEFAULTS[group.side]
	frame:SetPoint(defaults.point, parent, defaults.relativePoint, Helper.ClampInt(group.x, -2000, 2000, defaults.x), Helper.ClampInt(group.y, -2000, 2000, defaults.y))
	frame:Show()
	frame.handle.label:SetText(BG.Label(group) or _G.DEFAULT)
	local horizontal = group.side == "TOP" or group.side == "BOTTOM"
	frame.handleWidth = math.max(horizontal and 64 or 40, math.min(180, frame.handle.label:GetStringWidth() + 16))
	frame.handle:ClearAllPoints()
	local inset = ({TOP={"TOP",0,-4},BOTTOM={"BOTTOM",0,4},LEFT={"LEFT",4,0},RIGHT={"RIGHT",-4,0}})[group.side]
	frame.handle:SetPoint(inset[1], parent, inset[1], inset[2], inset[3])
	frame.handle:SetSize(frame.handleWidth, 20)
	local editing = not InCombatLockdown() and CP:IsPanelLayoutEditActive(panelId)
	frame.handle:SetShown(editing)
	if editing then BG.UpdateDropFeedback(frame) else frame.dropZone:Hide(); frame.indicator:Hide() end
	return frame
end
function BG.HideHandles(runtime)
	for _, frame in pairs(runtime.barGroupFrames or {}) do frame.handle:Hide(); frame.dropZone:Hide() end
end
function BG.AnchorSetting(value)
	local size = Helper.ClampInt(value, 0, 2000, 250)
	return size == 0 and 0 or math.max(100, size)
end
function BG.AnchorSize(value)
	local size = BG.AnchorSetting(value)
	return size == 0 and 250 or size
end
function BG.Pack(panelId, items, layout, frame)
	local buckets, active = {}, {}
	for _, group in ipairs(BG.Groups(layout, true)) do
		buckets[group.id] = {}
		active[group.id] = true
	end
	for _, item in ipairs(items) do
		local group = BG.EntryGroup(item.entry, layout)
		local list = buckets[group.id]; list[#list + 1] = item
	end
	for _, group in ipairs(BG.Groups(layout)) do
		local host = BG.Frame(panelId, group, frame)
		local effective = BG.Layout(group, layout)
		local width, height = Helper.LayoutBarPanelItems(buckets[group.id], effective)
		host:SetSize(math.max(width, effective.barPanelWidth), math.max(height, effective.barPanelHeight))
		host.items = buckets[group.id]
		host.layoutWidth, host.layoutHeight = math.max(width, effective.barPanelWidth), math.max(height, effective.barPanelHeight)
		for _, item in ipairs(buckets[group.id]) do item.host = host; item.growthPoint = effective.growthPoint end
	end
	for id, host in pairs(CP.runtime[panelId].barGroupFrames or {}) do if not active[id] then host:Hide() end end
	-- A stable reference rectangle prevents shrinking groups from moving other anchors.
	return BG.AnchorSize(layout.barGroupAnchorWidth), BG.AnchorSize(layout.barGroupAnchorHeight)
end

function BG.Options(values)
	local options = {}
	local labels = { HORIZONTAL = L["Horizontal"], VERTICAL = L["Vertical"] }
	for _, option in ipairs(Helper.AnchorOptions) do labels[option.value] = option.label end
	for _, option in ipairs(Helper.DirectionOptions) do labels[option.value] = option.label end
	for _, value in ipairs(values) do options[#options + 1] = { value = value, label = labels[value] or value } end
	return options
end
function BG.AddRow(settings, row, section)
	row.parentId = section
	row.isEnabled = row.isEnabled or function() return not InCombatLockdown() end
	settings[#settings + 1] = row
	return row
end
function BG.AppendManager(settings, panelId)
	local panel = CP:GetPanel(panelId)
	BG.Ensure(panel)
	local T = addon.EditModeLib.SettingType
	local function enabled() return BG.Enabled(panel.layout) end
	settings[#settings + 1] = { id = BG.SECTION, kind = T.Collapsible, name = L["CooldownPanelBarGroups"], isShown = function() return Helper.IsBarLayout(panel.layout) end,
		navigationHint = function() return L["CooldownPanelLayoutMode"], nil, "cooldownPanelLayout" end }
	BG.AddRow(settings, { name = L["CooldownPanelBarGroupsEnable"], tooltip = L["CooldownPanelBarGroupDropHint"], kind = T.Checkbox, navigationField = "barGroupsEnabled", navigationResetExcluded = true,
		get = function() return enabled() end, set = function(_, value)
			if InCombatLockdown() then return end
			panel.layout.barGroupsEnabled = value == true
			if value then
				BG.Ensure(panel)
				if CP.SpellGroups and CP.SpellGroups.Sync then CP.SpellGroups.Sync:Request(panelId) end
			end
			BG.Refresh(panelId)
		end }, BG.SECTION)
	for id = 1, 4 do
		BG.AddRow(settings, { name = ({L["Top"],L["Bottom"],L["Left"],L["Right"]})[id], kind = T.Action, navigationResetExcluded = true, isShown = enabled,
			onClick = function() BG.Open(panelId, id) end }, BG.SECTION)
	end
	for _, field in ipairs({ "barGroupAnchorWidth", "barGroupAnchorHeight" }) do
		BG.AddRow(settings, { name = L[field == "barGroupAnchorWidth" and "CooldownPanelBarGroupAnchorWidth" or "CooldownPanelBarGroupAnchorHeight"], kind = T.Slider, navigationField = field, navigationResetExcluded = true,
			minValue = 0, maxValue = 1000, valueStep = 1, allowInput = true, isShown = enabled,
			get = function() return BG.AnchorSetting(panel.layout[field]) end,
			formatter = function(value) return value == 0 and "0 = 250" or tostring(value) end,
			set = function(_, value) if not InCombatLockdown() then panel.layout[field] = BG.AnchorSetting(value); BG.Refresh(panelId) end end }, BG.SECTION)
	end
	for _, row in ipairs(settings) do
		if row.parentId == BG.SECTION and row.isShown == enabled then
			row.navigationHint = function() return L["CooldownPanelBarGroupsEnable"], nil, BG.SECTION end
		end
	end
end

function BG.AppendEntry(settings, panelId, entryId)
	local panel = CP:GetPanel(panelId)
	if not panel or not BG.Enabled(panel.layout) or entryId <= 0 then return end
	local T = addon.EditModeLib.SettingType
	for _, row in ipairs(settings) do
		if row.navigationField == "barPanelOrientation" or row.navigationField == "barPanelOffsetX" or row.navigationField == "barPanelOffsetY" then
			row.isShown = function() return false end; row.navigationSearchExcluded = true
		end
	end
	local destination, ownerId = BG.Binding(panel, panel.entries[entryId])
	local owner = ownerId and CP.SpellGroups:GetGroup(ownerId)
	local target = destination and BG.Find(panel.layout, destination)
	BG.AddRow(settings, { name = L[destination and "CooldownPanelBarGroupLocked" or "Group"], kind = T.Dropdown, navigationField = "barGroupId", navigationResetExcluded = true,
		tooltip = owner and target and string.format(L["CooldownPanelBarGroupLockedTooltip"], owner.name, BG.Label(target)) or nil,
		isEnabled = function() return not InCombatLockdown() and not BG.Binding(panel, panel.entries[entryId]) end,
		get = function() return BG.Binding(panel, panel.entries[entryId]) or BG.EntryGroup(panel.entries[entryId], panel.layout).id end,
		set = function(_, value) BG.SetEntryGroup(panelId, entryId, value) end,
		generator = function(_, menu)
			for _, group in ipairs(BG.Groups(panel.layout)) do menu:CreateRadio(BG.Label(group), function() return BG.EntryGroup(panel.entries[entryId], panel.layout).id == group.id end,
				function() BG.SetEntryGroup(panelId, entryId, group.id) end) end
		end }, "eqolCooldownPanelStandaloneBarLayout")
	for _, step in ipairs({ -1, 1 }) do
		BG.AddRow(settings, { name = L[step == -1 and "CooldownPanelBarGroupEarlier" or "CooldownPanelBarGroupLater"], kind = T.Action, navigationResetExcluded = true,
			onClick = function() BG.MoveEntry(panelId, entryId, step) end }, "eqolCooldownPanelStandaloneBarLayout")
	end
end

function BG.Settings(panelId, groupId)
	local panel = CP:GetPanel(panelId)
	local group = panel and BG.Find(panel.layout, groupId)
	if not group then return end
	group.layout = group.layout or {}
	local T, settings = addon.EditModeLib.SettingType, {}
	local function current() local p = CP:GetPanel(panelId); return p and BG.Find(p.layout, groupId), p end
	local function set(field, value, geometry)
		if InCombatLockdown() then return end
		local g, p = current(); if not g then return end
		if geometry then
			if field == "barPanelOrientation" then
				local layout = BG.Layout(g, p.layout)
				if layout.barPanelOrientation ~= value then
					g.layout.barPanelWidth = Helper.ClampInt(layout.barPanelHeight, 5, 2000, 240)
					g.layout.barPanelHeight = Helper.ClampInt(layout.barPanelWidth, 5, 2000, 26)
				end
			end
			g.layout[field] = value
		else g[field] = value end
		BG.Refresh(panelId)
	end
	settings[#settings + 1] = { id = BG.GENERAL, name = L["General"], kind = T.Collapsible }

	if CP.SpellGroups and CP.SpellGroups.SetBarGroupGroups then
		local spellGroups = CP.SpellGroups
		BG.AddRow(settings, { name = L["CDLSpellGroupsTitle"], tooltip = L["CooldownPanelBarGroupSpellGroupsTooltip"], kind = T.MultiDropdown,
			navigationField = "spellGroupBarGroups", navigationResetExcluded = true, customText = _G.NONE,
			get = function() return nil end, set = function() end,
			optionfunc = function()
				local options = {}
				for _, id in ipairs(spellGroups:GetGroupIDs()) do options[#options + 1] = { value = id, label = spellGroups:GetGroup(id).name } end
				return options
			end,
			isSelected = function(_, id) local _, p = current(); return p and p.spellGroupBarGroups and p.spellGroupBarGroups[id] == groupId or false end,
			setSelected = function(_, id, enabled)
				local _, p = current(); if not p then return end
				local refs = {}
				for _, value in ipairs(p.spellGroupIDs or {}) do
					if value ~= id and p.spellGroupBarGroups and p.spellGroupBarGroups[value] == groupId then refs[#refs + 1] = value end
				end
				if enabled then refs[#refs + 1] = id end
				spellGroups:SetBarGroupGroups(panelId, groupId, refs)
			end }, BG.GENERAL)
		BG.AddRow(settings, { name = L["CDLSpellGroupsOpenEditor"], kind = T.Action, navigationResetExcluded = true,
			onClick = function() CP:OpenSpellGroupsEditor() end }, BG.GENERAL)
	end
	settings[#settings + 1] = { id = BG.LAYOUT, name = L["Layout"], kind = T.Collapsible }
	for _, spec in ipairs({
		{ "barPanelOrientation", "CooldownPanelBarOrientation", { "HORIZONTAL", "VERTICAL" }, true },
		{ "direction", "Group Growth", { "LEFT", "RIGHT", "UP", "DOWN" }, true },
		{ "wrapDirection", "CooldownPanelWrapDirection", { "LEFT", "RIGHT", "UP", "DOWN" }, true },
		{ "growthPoint", "CooldownPanelGrowthPoint", nil, true },
	}) do
		local field, key, values, geometry = spec[1], spec[2], spec[3], spec[4]
		local options = BG.Options(values or {})
		local function get() local g, p = current(); if not g then return end; return geometry and BG.Layout(g, p.layout)[field] or g[field] end
		BG.AddRow(settings, { name = L[key], kind = T.Dropdown, navigationField = field, get = get,
			set = function(_, value) set(field, value, geometry) end,
			generator = function(_, menu)
				local g, p = current()
				local choices = field == "growthPoint" and Helper.GetGrowthPointOptions(g and BG.Layout(g, p.layout).direction) or options
				for _, option in ipairs(choices) do menu:CreateRadio(option.label, function() return get() == option.value end, function() set(field, option.value, geometry) end) end
			end }, BG.LAYOUT)
	end
	for _, spec in ipairs({
		{ "x", "Offset X", -2000, 2000 }, { "y", "Offset Y", -2000, 2000 },
		{ "barPanelWidth", "Bar width", 5, 2000, true }, { "barPanelHeight", "Bar height", 5, 2000, true },
		{ "spacing", "Spacing", 0, 200, true }, { "wrapCount", "CooldownPanelWrapCount", 0, 40, true },
	}) do
		local field, key, low, high, geometry = spec[1], spec[2], spec[3], spec[4], spec[5]
		BG.AddRow(settings, { name = L[key], kind = T.Slider, navigationField = field, minValue = low, maxValue = high, valueStep = 1, allowInput = true,
			get = function() local g, p = current(); if not g then return 0 end; return Helper.ClampInt(geometry and BG.Layout(g, p.layout)[field] or g[field], low, high, 0) end,
			set = function(_, value) set(field, Helper.ClampInt(value, low, high, low), geometry) end }, BG.LAYOUT)
	end
	BG.AddRow(settings, { name = L["CooldownPanelBarGroupCompact"], kind = T.Checkbox, navigationField = "compact",
		get = function() local g = current(); return g and g.compact ~= false end,
		set = function(_, value) set("compact", value == true) end }, BG.LAYOUT)
	Bars.AppendPanelBarSettings(settings, panelId, groupId)
	local rebuilt = {}
	for _, row in ipairs(settings) do
		local scope = Bars.PANEL_STYLE_GROUPS[row.parentId or row.id]
		if scope and row.navigationPanelBarStyle and row.parentId then
			local original, disabled = row.isEnabled, row.disabled
			row.isEnabled = function(...)
				local g = current()
				if not g or not BG.StyleOverridden(g, scope) or InCombatLockdown() then return false end
				if original then return original(...) end
				if type(disabled) == "function" then return not disabled(...) end
				return not disabled
			end
		end
		rebuilt[#rebuilt + 1] = row
		if scope and row.kind == T.Collapsible then
			BG.AddRow(rebuilt, { name = L["CooldownPanelBarGroupUsePanelStyle"], kind = T.Checkbox,
				navigationField = "barGroupUsePanelStyle" .. scope, navigationResetExcluded = true,
				get = function() local g = current(); return g and not BG.StyleOverridden(g, scope) end,
				set = function(_, value)
					if InCombatLockdown() then return end
					local g = current(); if not g then return end
					g.barStyleOverrides = g.barStyleOverrides or {}
					g.barStyleOverrides[scope] = value ~= true or nil
					if not next(g.barStyleOverrides) then g.barStyleOverrides = nil end
					BG.Refresh(panelId)
				end }, row.id)
		end
	end
	settings = rebuilt
	return settings
end
function BG.Open(panelId, groupId, anchor)
	if InCombatLockdown() then return end
	local panel = CP:GetPanel(panelId)
	local group = panel and BG.Find(panel.layout, groupId)
	local runtime = CP.runtime and CP.runtime[panelId]
	if not group or not runtime or not BG.Enabled(panel.layout) then return end
	local settings = BG.Settings(panelId, groupId)
	local options = CP.Navigation.Build(settings, "panel", panelId)
	options.scopeKey = "cooldownPanels:barGroup:" .. panelId .. ":" .. groupId
	options.stateKey = "cooldownPanels:barGroups"
	table.insert(options.categories, 1, { id = "group", name = L["Group"], groups = { BG.GENERAL, BG.LAYOUT } })
	for _, row in ipairs(settings) do
		if row.kind == addon.EditModeLib.SettingType.Collapsible then
			local section = row.id
			row.navigationReset = function()
				if InCombatLockdown() then return end
				local livePanel = CP:GetPanel(panelId)
				local live = livePanel and BG.Find(livePanel.layout, groupId)
				if not live then return end
				if section == BG.GENERAL then -- Source bindings are not appearance settings.
				elseif section == BG.LAYOUT then
					live.layout = BG.DefaultLayout(live.side, livePanel.layout)
					local defaults = BG.SIDE_DEFAULTS[live.side]
					live.x, live.y, live.compact = defaults.x, defaults.y, true
				else
					local scope = Bars.PANEL_STYLE_GROUPS[section]
					if scope then
						if live.barStyleOverrides then
							live.barStyleOverrides[scope] = nil
							if not next(live.barStyleOverrides) then live.barStyleOverrides = nil end
						end
						for field in pairs(live.barStyle or {}) do if Helper.BarStyleBelongsToScope(field, scope) then live.barStyle[field] = nil end end
						if scope == "Icon" then live.layout.barPanelIconSize = nil end
						BG.ApplyStyleDefaults(live, scope)
					end
				end
				BG.Refresh(panelId)
			end
		end
	end
	-- A dedicated host keeps the group entity separate from the panel's registered settings.
	runtime.barGroupDialogHosts = runtime.barGroupDialogHosts or {}
	local host = runtime.barGroupDialogHosts[groupId]
	if not host then host = CreateFrame("Frame", nil, UIParent); host:SetSize(1, 1); runtime.barGroupDialogHosts[groupId] = host end
	local spawn = CP:GetStandaloneDialogSpawnPosition(anchor, runtime.frame, 12, 0)
	local editor = CP.runtime.editor and CP.runtime.editor.editor
	local fromBlizzard = editor and editor._eqolBlizzardEditorLayoutEdit == true
	local previousSuppress = editor and editor._eqolSuppressBlizzardEditorLayoutEditEnd
	if fromBlizzard then editor._eqolSuppressBlizzardEditorLayoutEditEnd = true end
	local dialog = addon.EditModeLib:ShowStandaloneSettingsDialog(host, {
		title = BG.Label(group), settings = settings, settingsNavigation = options, showReset = false, showSettingsReset = false, settingsMaxHeight = 620,
		point = spawn.point, relativePoint = spawn.relativePoint, relativeTo = spawn.relativeTo, x = spawn.x, y = spawn.y,
		onHide = function()
			runtime.barGroupDialog = nil
			if fromBlizzard and not editor._eqolSuppressBlizzardEditorLayoutEditEnd then CP:SetEditorLayoutEditEnabled(false) end
		end,
	})
	if fromBlizzard then editor._eqolSuppressBlizzardEditorLayoutEditEnd = previousSuppress end
	if dialog then runtime.barGroupDialog = { groupId = groupId, dialog = dialog }; CP:DockStandaloneDialogToEditor(dialog) end
end

BG.originalAppendPanel = Bars.AppendPanelBarSettings
function Bars.AppendPanelBarSettings(settings, panelId, groupId)
	BG.originalAppendPanel(settings, panelId, groupId)
	if not groupId then BG.AppendManager(settings, panelId) end
end
BG.originalEntrySettings = Bars.BuildBarStandaloneSettings
function Bars.BuildBarStandaloneSettings(panelId, entryId)
	local settings = BG.originalEntrySettings(panelId, entryId)
	if settings then
		BG.AppendEntry(settings, panelId, entryId)
		local panel = CP:GetPanel(panelId)
		if panel and BG.Enabled(panel.layout) then
			for _, row in ipairs(settings) do
				if row.navigationField and row.navigationField:match("^barStyleOverride") then row.name = L["CooldownPanelBarGroupOverride"] end
			end
		end
	end
	return settings
end
BG.originalUpdateVisibility = CP.UpdateVisibility
function CP:UpdateVisibility(panelId, ...)
	local result = BG.originalUpdateVisibility(self, panelId, ...)
	local runtime = self.runtime and self.runtime[panelId]
	if runtime then
		local panel = self:GetPanel(panelId)
		for _, frame in pairs(runtime.barGroupFrames or {}) do
			local editing = panel and BG.Enabled(panel.layout) and not InCombatLockdown() and self:IsPanelLayoutEditActive(panelId)
			frame.handle:SetShown(editing)
			if editing then BG.UpdateDropFeedback(frame) else frame.dropZone:Hide(); frame.indicator:Hide() end
		end
	end
	return result
end

BG.originalNormalizePanel = Helper.NormalizePanel
function Helper.NormalizePanel(panel, ...)
	local result = BG.originalNormalizePanel(panel, ...)
	BG.Ensure(panel)
	return result
end
BG.originalPrepareEntries = Bars.PrepareBarPanelEntries
function Bars.PrepareBarPanelEntries(panel)
	BG.Ensure(panel)
	return BG.originalPrepareEntries(panel)
end

-- Hit testing stays on public editor targets and uses the shared client helper.
function BG.Target()
	if InCombatLockdown() then return end
	for panelId, runtime in pairs(CP.runtime or {}) do
		if type(panelId) == "number" and runtime.barGroupFrames and CP:IsPanelLayoutEditActive(panelId) then
			local panel = CP:GetPanel(panelId)
			if panel and BG.Enabled(panel.layout) then
				for _, group in ipairs(BG.Groups(panel.layout)) do
					local frame = runtime.barGroupFrames[group.id]
					if frame and frame.handle:IsShown() and addon.functions.MouseIsOver(frame.handle) then return panelId, group.id end
				end
				for _, group in ipairs(BG.Groups(panel.layout)) do
					local frame = runtime.barGroupFrames[group.id]
					if frame and frame.dropZone:IsShown() and addon.functions.MouseIsOver(frame.dropZone) then return panelId, group.id end
				end
			end
		end
	end
end
function BG.Assign(panelId, entryId, groupId, beforeEntryId)
	if InCombatLockdown() then return false end
	local panel = CP:GetPanel(panelId)
	local entry = panel and panel.entries and panel.entries[entryId]
	if not entry or not BG.Enabled(panel.layout) or not BG.Find(panel.layout, groupId) then return false end
	if not BG.CanAssign(panel, entry, panel, groupId) then return false end
	entry.barGroupId = groupId
	-- The marker and the committed drop use the same insertion boundary.
	panel.order = panel.order or {}
	for index, id in ipairs(panel.order) do if id == entryId then table.remove(panel.order, index); break end end
	local insertIndex = #panel.order + 1
	for index, id in ipairs(panel.order) do if id == beforeEntryId then insertIndex = index; break end end
	table.insert(panel.order, insertIndex, entryId)
	BG.Refresh(panelId)
	return true
end
function BG.DropInternal(panelId, entryId)
	local targetPanel, groupId = BG.Target()
	if targetPanel ~= panelId then return false end
	local panel = CP:GetPanel(panelId)
	if panel and not BG.CanAssign(panel, panel.entries[entryId], panel, groupId) then return true end
	local before = BG.Insertion(panelId, groupId, entryId)
	return BG.Assign(panelId, entryId, groupId, before)
end
function BG.DropModern(editor, panelId, groupId)
	local drag = editor.state and editor.state.drag
	if not drag or InCombatLockdown() then return false end
	if not panelId then panelId, groupId = BG.Target() end
	local panel = panelId and CP:GetPanel(panelId)
	local source = CP:GetPanel(drag.panelId)
	local entry = source and source.entries and source.entries[drag.entryId]
	if not panel or not entry or not BG.Enabled(panel.layout) or not BG.Find(panel.layout, groupId) or Helper.IsFixedLayout(source.layout) then return false end
	if not BG.CanAssign(source, entry, panel, groupId) then editor:CancelDrag(); return true end
	local previous = entry.barGroupId
	entry.barGroupId = groupId
	local before = BG.Insertion(panelId, groupId, drag.panelId == panelId and drag.entryId or nil)
	editor:MoveEntry(drag.panelId, drag.entryId, panelId, before)
	local moved
	for id, value in pairs(panel.entries) do if value == entry then moved = id; break end end
	if not moved then entry.barGroupId = previous; return false end
	BG.Refresh(panelId)
	return true
end
function BG.Receive(panelId, groupId)
	if InCombatLockdown() or not CP:IsPanelLayoutEditActive(panelId) then return false end
	local panel = CP:GetPanel(panelId)
	if not panel or not BG.Enabled(panel.layout) or not BG.Find(panel.layout, groupId) then return false end
	local modern = CP.BlizzardEditor
	if modern and modern.state and modern.state.drag then return BG.DropModern(modern, panelId, groupId) end
	local legacy = CP.runtime.editor and CP.runtime.editor.editor
	if legacy and legacy.draggingEntry then return true end
	local api = Helper.Api or {}
	local cursorType, cursorId, _, spellId
	if api.GetCursorInfo then cursorType, cursorId, _, spellId = api.GetCursorInfo() end
	if cursorType == "action" and api.GetActionInfo then cursorType, cursorId = api.GetActionInfo(cursorId); spellId = nil end
	local entryType = ({spell="SPELL",item="ITEM",macro="MACRO"})[cursorType]
	local existing = entryType and CP:FindEntryByValue(panelId, entryType, cursorType == "spell" and (spellId or cursorId) or cursorId)
	if existing then
		if BG.Assign(panelId, existing, groupId, BG.Insertion(panelId, groupId, existing)) then if api.ClearCursor then api.ClearCursor() end; return true, existing end
		return true
	end
	-- Reject a linked spell before creating it on an incompatible side.
	local candidate = entryType and { type = entryType, spellID = spellId or cursorId, itemID = cursorId }
	if candidate and not BG.CanAssign(panel, candidate, panel, groupId) then return true end
	local before = BG.Insertion(panelId, groupId)
	local added, entryId = BG.originalCursorDrop(CP, panelId)
	if added and entryId then return BG.Assign(panelId, entryId, groupId, before), entryId end
	return false
end
if CP.BlizzardEditor then
	BG.originalEndDrag = CP.BlizzardEditor.EndDrag
	function CP.BlizzardEditor:EndDrag(...)
		if BG.DropModern(self) then return true end
		return BG.originalEndDrag(self, ...)
	end
end

function BG.IsDragging()
	local modern = CP.BlizzardEditor
	if modern and modern.state and modern.state.drag then return true end
	local legacy = CP.runtime and CP.runtime.editor and CP.runtime.editor.editor
	if legacy and legacy.draggingEntry then return true end
	local api = Helper.Api or {}
	local kind = api.GetCursorInfo and api.GetCursorInfo()
	return kind == "spell" or kind == "item" or kind == "macro" or kind == "action"
end
function BG.DraggedEntry(panelId)
	local drag = CP.BlizzardEditor and CP.BlizzardEditor.state and CP.BlizzardEditor.state.drag
	if drag then return drag.panelId == panelId and drag.entryId or nil end
	local legacy = CP.runtime and CP.runtime.editor and CP.runtime.editor.editor
	if legacy and legacy.draggingEntry then return legacy.selectedPanelId == panelId and legacy.dragEntryId or nil end
	local api = Helper.Api or {}
	if not api.GetCursorInfo or not CP.FindEntryByValue then return end
	local kind, id, _, spellId = api.GetCursorInfo()
	if kind == "action" and api.GetActionInfo then kind, id = api.GetActionInfo(id); spellId = nil end
	local entryType = ({spell="SPELL",item="ITEM",macro="MACRO"})[kind]
	if entryType then return CP:FindEntryByValue(panelId, entryType, kind == "spell" and (spellId or id) or id) end
end
function BG.Insertion(panelId, groupId, ignoredEntryId)
	local runtime = CP.runtime and CP.runtime[panelId]
	local frame = runtime and runtime.barGroupFrames and runtime.barGroupFrames[groupId]
	local panel = CP:GetPanel(panelId)
	local group = panel and BG.Find(panel.layout, groupId)
	if not frame or not group then return end
	local layout = BG.Layout(group, panel.layout)
	local direction = Helper.NormalizeDirection(layout.direction, "DOWN")
	local horizontal = direction == "LEFT" or direction == "RIGHT"
	local width, height = frame.layoutWidth or layout.barPanelWidth, frame.layoutHeight or layout.barPanelHeight
	local left = Bars.ReadAnchorFrameNumber and Bars.ReadAnchorFrameNumber(frame, frame.GetLeft)
	local top = Bars.ReadAnchorFrameNumber and Bars.ReadAnchorFrameNumber(frame, frame.GetTop)
	local scale = Bars.GetAnchorFrameScale and Bars.GetAnchorFrameScale(frame)
	local uiScale = Bars.GetAnchorFrameScale and Bars.GetAnchorFrameScale(UIParent)
	local cursorX, cursorY
	if CP.GetCursorPositionOnUIParent then cursorX, cursorY = CP:GetCursorPositionOnUIParent() end
	local x, y
	if left and top and scale and scale > 0 and uiScale and uiScale > 0 and cursorX and cursorY then
		x, y = cursorX * uiScale / scale - left, cursorY * uiScale / scale - top
	end
	local point = Helper.NormalizeGrowthPoint(layout.growthPoint, "TOPLEFT")
	local originX = point:find("RIGHT") and width or point:find("LEFT") and 0 or width / 2
	local originY = point:find("BOTTOM") and -height or point:find("TOP") and 0 or -height / 2
	local items = {}
	for _, item in ipairs(frame.items or {}) do
		if item.icon.entryId ~= ignoredEntryId then items[#items + 1] = item end
	end
	local best, distance
	local function candidate(item, before, leading)
		local ix, iy = item.x + originX, item.y + originY
		local edgeX = direction == "LEFT" and (leading and ix + item.width or ix) or (leading and ix or ix + item.width)
		local edgeY = direction == "UP" and (leading and iy - item.height or iy) or (leading and iy or iy - item.height)
		local px, py = horizontal and edgeX or ix + item.width / 2, horizontal and iy - item.height / 2 or edgeY
		local sign = (direction == "RIGHT" or direction == "UP") and 1 or -1
		local gap = Helper.ClampInt(layout.spacing, 0, 200, 2) / 2
		if horizontal then px = px + (leading and -sign or sign) * gap
		else py = py + (leading and -sign or sign) * gap end
		local current
		if x and y then
			local dx = horizontal and x - px or math.max(ix - x, 0, x - ix - item.width)
			local dy = horizontal and math.max(iy - item.height - y, 0, y - iy) or y - py
			current = dx * dx + dy * dy
		else current = before and 1 or 0 end
		if not distance or current < distance then best, distance = { before = before, x = px, y = py, vertical = horizontal, span = horizontal and item.height or item.width }, current end
	end
	for index, item in ipairs(items) do
		candidate(item, item.icon.entryId, true)
		candidate(item, items[index + 1] and items[index + 1].icon.entryId, false)
	end
	if not best then
		best = { x = horizontal and (direction == "LEFT" and width or 0) or width / 2,
			y = horizontal and -height / 2 or direction == "UP" and -height or 0, vertical = horizontal, span = horizontal and height or width }
	end
	return best.before, best
end
function BG.UpdateDropFeedback(frame)
	local editing = not InCombatLockdown() and CP:IsPanelLayoutEditActive(frame.panelId)
	local dragging = editing and BG.IsDragging()
	local padding = dragging and 20 or 4
	if frame.dropPadding ~= padding then
		frame.dropPadding = padding
		frame.dropZone:ClearAllPoints()
		frame.dropZone:SetPoint("TOPLEFT", frame, "TOPLEFT", -padding, padding)
		frame.dropZone:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", padding, -padding)
	end
	frame.dropZone:SetShown(dragging == true)
	frame.handle:SetSize((frame.handleWidth or 64) + (dragging and 16 or 0), dragging and 28 or 20)
	local targetPanel, targetGroup
	if dragging then targetPanel, targetGroup = BG.Target() end
	local selected = targetPanel == frame.panelId and targetGroup == frame.groupId
	if selected then
		local drag = CP.BlizzardEditor and CP.BlizzardEditor.state and CP.BlizzardEditor.state.drag
		local source = CP:GetPanel(drag and drag.panelId or frame.panelId)
		local entryId = drag and drag.entryId or BG.DraggedEntry(frame.panelId)
		local entry = source and source.entries and source.entries[entryId]
		if entry and not BG.CanAssign(source, entry, CP:GetPanel(frame.panelId), frame.groupId) then selected = false end
	end
	local hovered = editing and addon.functions.MouseIsOver(frame.handle)
	frame.handle.background:SetColorTexture(0.08, 0.14, 0.21, selected and 0.95 or hovered and 0.65 or dragging and 0.5 or 0)
	frame.handle.label:SetTextColor(selected and 0.65 or 0.78, selected and 0.88 or 0.82, 1, selected and 1 or 0.9)
	frame.handle.accent:SetShown(selected or hovered or dragging)
	frame.dropZone.background:SetColorTexture(0.2, 0.48, 0.75, selected and 0.18 or 0.045)
	if selected then
		local _, position = BG.Insertion(frame.panelId, frame.groupId, BG.DraggedEntry(frame.panelId))
		if position then
			BG.StyleMarker(frame.indicator, position)
			local pixels = addon.PixelUtil
			local x = pixels and pixels.Snap and pixels.Snap(position.x, frame) or position.x
			local y = pixels and pixels.Snap and pixels.Snap(position.y, frame) or position.y
			frame.indicator:ClearAllPoints()
			frame.indicator:SetPoint("CENTER", frame, "TOPLEFT", x, y)
			frame.indicator:Show()
		else frame.indicator:Hide() end
	else frame.indicator:Hide() end
end
if CP.ShowLayoutEditHint then
	BG.originalShowHint = CP.ShowLayoutEditHint
	function CP:ShowLayoutEditHint(panelId, show)
		local panel = self:GetPanel(panelId)
		return BG.originalShowHint(self, panelId, show and not (panel and BG.Enabled(panel.layout)))
	end
end

-- Existing bar handles also receive external drops; route them through the same target.
BG.originalCursorDrop = CP.HandleCursorDrop
function CP:HandleCursorDrop(panelId, targetSlot)
	local api = Helper.Api or {}
	local kind = api.GetCursorInfo and api.GetCursorInfo()
	if kind == "spell" or kind == "item" or kind == "macro" or kind == "action" then
		local targetPanel, groupId = BG.Target()
		if targetPanel and targetPanel == tonumber(panelId) then return BG.Receive(targetPanel, groupId) end
	end
	return BG.originalCursorDrop(self, panelId, targetSlot)
end

-- Solid pixel-aligned strokes stay legible over bars without stretched atlas glows.
function BG.StyleMarker(marker, position)
	local pixels = addon.PixelUtil
	local pixel = pixels and pixels.OnePixel and pixels.OnePixel(marker) or 1
	local length = math.max(24, math.min(48, (position.span or 64) * 0.5))
	length = math.floor(length / (2 * pixel) + 0.5) * 2 * pixel
	local vertical = position.vertical
	if marker.vertical == vertical and marker.lineLength == length and marker.onePixel == pixel then return end
	marker.vertical, marker.lineLength, marker.onePixel = vertical, length, pixel
	marker:SetSize(vertical and 2 * pixel or length, vertical and length or 2 * pixel)
	marker.Shadow:SetSize(vertical and 4 * pixel or length + 2 * pixel, vertical and length + 2 * pixel or 4 * pixel)
	for index, cap in ipairs(marker.caps) do
		local point = vertical and (index == 1 and "TOP" or "BOTTOM") or (index == 1 and "LEFT" or "RIGHT")
		cap.texture:ClearAllPoints(); cap.shadow:ClearAllPoints()
		cap.texture:SetPoint("CENTER", marker, point); cap.shadow:SetPoint("CENTER", marker, point)
		cap.texture:SetSize(vertical and 6 * pixel or 2 * pixel, vertical and 2 * pixel or 6 * pixel)
		cap.shadow:SetSize(vertical and 8 * pixel or 4 * pixel, vertical and 4 * pixel or 8 * pixel)
	end
end
