local _, addon = ...

addon.EditModeAnchors = addon.EditModeAnchors or {}
local Anchors = addon.EditModeAnchors

local function plainNumber(value)
	if issecretvalue and issecretvalue(value) then return nil end
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return nil end
	return value
end

local function getSize(frame)
	if not (frame and frame.GetWidth and frame.GetHeight) then return nil end
	return plainNumber(frame:GetWidth()), plainNumber(frame:GetHeight())
end

local function findConsumer(entry, context)
	local dynamic = addon.DynamicAnchors
	if not (dynamic and dynamic.targets and dynamic.consumers) then return nil end
	if context and context.frameConsumers then return context.frameConsumers[entry.frame] end
	-- A context belongs to one synchronous cycle-check pass, never to the UI session.
	local frameConsumers = context and {}
	for targetId, target in pairs(dynamic.targets) do
		if targetId:sub(1, 9) ~= "editMode:" and type(target.resolve) == "function" then
			local ok, frame = pcall(target.resolve, target, { mode = "EDIT" })
			if ok and frame and (not issecretvalue or not issecretvalue(frame)) and (frameConsumers or frame == entry.frame) then
				local consumerId = target.consumerId
				if type(target.getConsumerId) == "function" then
					local resolved, value = pcall(target.getConsumerId, target)
					if resolved then consumerId = value end
				end
				if consumerId and dynamic.consumers[consumerId] then
					if not frameConsumers then return consumerId end
					if not frameConsumers[frame] then frameConsumers[frame] = consumerId end
				end
			end
		end
	end
	if frameConsumers then
		context.frameConsumers = frameConsumers
		return frameConsumers[entry.frame]
	end
end

function Anchors:GetConsumerId(entry, context)
	if not (entry and entry.frame) then return nil end
	local custom = entry.anchorAdapter
	if type(custom) == "function" then custom = custom(entry) end
	if custom == false then return nil end
	return type(custom) == "table" and custom.consumerId or findConsumer(entry, context)
end

local function dimensionSetter(entry, dimension)
	local setting = entry.settingsByField and entry.settingsByField[dimension]
	if not (setting and type(setting.set) == "function") then return nil end
	return function(value)
		value = plainNumber(value)
		if not value or value <= 0 then return false end
		local layout = addon.EditMode:GetActiveLayoutName()
		if setting.isEnabled and not setting.isEnabled(layout) then return false end
		local minimum = type(setting.minValue) == "function" and setting.minValue(layout) or setting.minValue
		local maximum = type(setting.maxValue) == "function" and setting.maxValue(layout) or setting.maxValue
		if type(minimum) == "number" then value = math.max(minimum, value) end
		if type(maximum) == "number" then value = math.min(maximum, value) end
		setting.set(layout, value)
		return true
	end
end

function Anchors:GetAdapter(entry)
	if not (entry and entry.frame) then return nil end
	local custom = entry.anchorAdapter
	if type(custom) == "function" then custom = custom(entry) end
	if custom == false then return nil end
	local adapter = {}
	if type(custom) == "table" then
		for key, value in pairs(custom) do adapter[key] = value end
	end
	adapter.getSize = adapter.getSize or function() return getSize(entry.frame) end
	adapter.consumerId = adapter.consumerId or findConsumer(entry)
	-- Only known scalar layouts use their width and height settings directly.
	-- Collection layouts need their own adapter because these fields can size children.
	local scalarLayout = adapter.inheritSizeSettings == true or entry.managerCategory == "resourceBars" or entry.managerCategory == "dataPanels"
	if scalarLayout and adapter.inheritSizeSettings ~= false then
		adapter.setWidth = adapter.setWidth or dimensionSetter(entry, "width")
		adapter.setHeight = adapter.setHeight or dimensionSetter(entry, "height")
	end
	adapter.detach = adapter.detach or function(point, relativePoint, x, y)
		local editMode = addon.EditMode
		if not (editMode and editMode.frames and editMode.frames[entry.id] == entry) then return false end
		if entry.id == "combatText" or entry.id == "focusInterruptTracker" or entry.id == "totalAbsorbTracker" then
			local targetSetting = entry.settingsByField and entry.settingsByField.anchorTarget
			if targetSetting and targetSetting.set then targetSetting.set(editMode:GetActiveLayoutName(), "UIParent") end
		end
		editMode:SetFramePosition(entry.id, point, x, y, nil, true, relativePoint)
		local data = editMode:EnsureLayoutData(entry.id)
		if entry.onPositionChanged then entry.onPositionChanged(entry.frame, editMode:GetActiveLayoutName(), data) end
		editMode:ApplyLayout(entry.id)
		return true
	end
	local snapshotOwner, restoreOwner = adapter.snapshot, adapter.restore
	adapter.snapshot = function()
		local editMode = addon.EditMode
		local registered = editMode and editMode.frames and editMode.frames[entry.id] == entry
		return {
			layout = registered and CopyTable(editMode:EnsureLayoutData(entry.id)) or nil,
			owner = snapshotOwner and snapshotOwner() or nil,
		}
	end
	adapter.restore = function(saved)
		local editMode = addon.EditMode
		local registered = editMode and editMode.frames and editMode.frames[entry.id] == entry
		local data
		if registered and saved.layout then
			data = editMode:EnsureLayoutData(entry.id)
			for key in pairs(data) do data[key] = nil end
			for key, value in pairs(saved.layout) do data[key] = type(value) == "table" and CopyTable(value) or value end
			editMode:SetFramePosition(entry.id, data.point, data.x, data.y, nil, true, data.relativePoint)
		end
		if restoreOwner and saved.owner then
			restoreOwner(saved.owner)
		elseif registered then
			if data and entry.onPositionChanged then entry.onPositionChanged(entry.frame, editMode:GetActiveLayoutName(), data) end
			editMode:ApplyLayout(entry.id)
		end
		return true
	end
	return adapter
end

function Anchors:GetExternalEntries()
	local entries, active = {}, {}
	local panels = addon.Aura and addon.Aura.CooldownPanels
	if not (panels and panels.GetPanelOrder and panels.GetPanelRuntimeFrame and panels.GetDynamicAnchorId) then self._panelEntries = nil; return entries end
	self._panelEntries = self._panelEntries or {}
	for _, panelId in ipairs(panels:GetPanelOrder() or {}) do
		local panel = panels:GetPanel(panelId, true)
		local frame = panels:GetPanelRuntimeFrame(panelId)
		if panel and panel.enabled ~= false and frame then
			local id = panels:GetDynamicAnchorId(panelId)
			active[id] = true
			local entry = self._panelEntries[id]
			if not entry or entry.frame ~= frame then
				entry = {
					id = id,
					frame = frame,
					managerCategory = "cooldownPanels",
					managePosition = false,
					persistPosition = false,
					isAnchorSelectable = function()
						local current = panels:GetPanel(panelId, true)
						return current and not (current.anchor and current.anchor.relativeFrame == "EQOL_CooldownPanelsFakeCursor")
					end,
					isEnabled = function()
						local current = panels:GetPanel(panelId, true)
						return current and current.enabled ~= false
					end,
					anchorAdapter = {
						consumerId = id,
						inheritSizeSettings = false,
						snapshot = function()
							local current = panels:GetPanel(panelId, true)
							return current and { anchor = CopyTable(current.anchor or {}), point = current.point, x = current.x, y = current.y }
						end,
						restore = function(saved)
							local current = panels:GetPanel(panelId, true)
							if not current then return end
							current.anchor = CopyTable(saved.anchor)
							current.point, current.x, current.y = saved.point, saved.x, saved.y
							if panels.MarkRelativeFrameEntriesDirty then panels.MarkRelativeFrameEntriesDirty() end
							panels:ApplyPanelPosition(panelId)
						end,
						detach = function(point, relativePoint, x, y)
							local current = panels:GetPanel(panelId, true)
							if not current then return false end
							current.anchor = current.anchor or {}
							current.anchor.relativeFrame = "UIParent"
							panels:HandlePositionChanged(panelId, { point = point, relativePoint = relativePoint, x = x, y = y })
							if panels.MarkRelativeFrameEntriesDirty then panels.MarkRelativeFrameEntriesDirty() end
							panels:ApplyPanelPosition(panelId)
							return true
						end,
					},
				}
				self._panelEntries[id] = entry
			end
			entry.title = panel.name
			entries[#entries + 1] = entry
		end
	end
	for id in pairs(self._panelEntries) do if not active[id] then self._panelEntries[id] = nil end end
	return entries
end
