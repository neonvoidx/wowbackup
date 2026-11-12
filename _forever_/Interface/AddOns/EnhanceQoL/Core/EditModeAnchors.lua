local _, addon = ...

-- The editor uses the existing anchor consumers; module adapters own geometry.
addon.EditModeAnchors = addon.EditModeAnchors or {}
local A = addon.EditModeAnchors
local D = addon.DynamicAnchors
local E = addon.EditMode
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
A.entries, A.byFrame, A.pending, A.layoutRestores = {}, {}, {}, {}
A.points = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
A.factors = { TOPLEFT = { 0, 1 }, TOP = { .5, 1 }, TOPRIGHT = { 1, 1 }, LEFT = { 0, .5 }, CENTER = { .5, .5 }, RIGHT = { 1, .5 }, BOTTOMLEFT = { 0, 0 }, BOTTOM = { .5, 0 }, BOTTOMRIGHT = { 1, 0 } }

function A:Number(value)
	if issecretvalue and issecretvalue(value) then return nil end
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return nil end
	return value
end

function A:InCombat() return InCombatLockdown and InCombatLockdown() end

function A:Store(id, create)
	if not addon.db then return nil end
	if create then addon.db.editModeAnchorLinks = addon.db.editModeAnchorLinks or {} end
	local store = addon.db.editModeAnchorLinks
	if not store then return nil end
	if create and type(store[id]) ~= "table" then store[id] = {} end
	return store[id]
end

function A:Adapter(entry)
	return self.GetAdapter and self:GetAdapter(entry) or {}
end

function A:ResolveTarget(id, context)
	local cache = context and context.resolvedTargets
	if cache and id and cache[id] ~= nil then return cache[id] or nil end
	local target = id and D.targets[id]
	local frame
	if target and type(target.resolve) == "function" then
		local ok, resolved, state = pcall(target.resolve, target, { mode = self.active and "PREVIEW" or "LIVE" })
		if ok and resolved and not (state and state.available == false) then frame = resolved end
	end
	if context and id then
		context.resolvedTargets = cache or {}
		context.resolvedTargets[id] = frame or false
	end
	return frame
end

function A:TargetConsumer(id, context)
	local target = D.targets[id]
	if not target then return nil end
	if target.getConsumerId then
		local ok, result = pcall(target.getConsumerId, target, context)
		if ok then return result end
	end
	return target.consumerId
end

function A:Consumer(entry, context)
	if context and context.consumers and context.consumers[entry] then return context.consumers[entry] end
	local consumer
	if self.GetConsumerId then consumer = self:GetConsumerId(entry, context) else consumer = self:Adapter(entry).consumerId end
	consumer = consumer or ("editMode:" .. entry.id)
	if context then
		context.consumers = context.consumers or {}
		context.consumers[entry] = consumer
	end
	return consumer
end

function A:Assignment(entry, create)
	local consumer = self:Consumer(entry)
	return create and D:EnsureConsumerAssignment(consumer) or D:GetConsumerAssignment(consumer)
end

function A:Rule(entry)
	local assignment = self:Assignment(entry)
	if not assignment then return nil end
	return assignment.profileId and D:GetProfile(assignment.profileId) or assignment, assignment
end

function A:Candidate(entry)
	local rule, assignment = self:Rule(entry)
	if not rule or not assignment.enabled then return nil end
	local result = D:ResolveConsumer(self:Consumer(entry))
	local winnerId = result.winner and result.winner.candidateId
	for index, candidate in ipairs(rule.candidates or {}) do
		if candidate.id == winnerId then return candidate, index end
	end
	return rule.candidates and rule.candidates[1], 1
end

-- Copy on write prevents a quick edit from changing another frame's profile.
function A:EditableRule(entry)
	local assignment = self:Assignment(entry, true)
	if not assignment then return nil end
	local record = self:Store(entry.id, true)
	local rule = self:Rule(entry)
	local shared = false
	for id in pairs(D.consumers) do
		if id ~= self:Consumer(entry) then
			local other = D:GetConsumerAssignment(id)
			if other and other.profileId and other.profileId == assignment.profileId then shared = true; break end
		end
	end
	if not rule or not record.profileId or record.profileId ~= assignment.profileId or shared then
		local profileId, profile = D:CreateProfile((entry.title or entry.frame.editModeName or entry.id) .. " - " .. L["EditModeAnchorTitle"], rule)
		assignment.profileId, record.profileId, rule = profileId, profileId, profile
		assignment.candidates, assignment.finalFallback = nil, nil
	end
	return rule, assignment
end

function A:Geometry(frame, point)
	if not frame or not self.factors[point] then return nil end
	local left, bottom, width, height = frame:GetRect()
	left, bottom, width, height = self:Number(left), self:Number(bottom), self:Number(width), self:Number(height)
	local scale = self:Number(frame:GetEffectiveScale())
	if not (left and bottom and width and height and scale and scale > 0) then return nil end
	local f = self.factors[point]
	return (left + width * f[1]) * scale, (bottom + height * f[2]) * scale, scale
end

function A:Offsets(frame, target, point, relativePoint)
	local x, y, scale = self:Geometry(frame, point)
	local tx, ty = self:Geometry(target, relativePoint)
	if not x or not tx then return nil end
	return (x - tx) / scale, (y - ty) / scale
end

function A:FrameDependsOn(frame, source)
	local seen, remaining = {}, 128
	local function visit(current)
		if not current then return false end
		if issecretvalue and issecretvalue(current) then return true end
		if current == source then return true end
		if seen[current] then return false end
		if type(current) ~= "table" and type(current) ~= "userdata" then return true end
		seen[current], remaining = true, remaining - 1
		if remaining < 0 then return true end
		if current.GetParent then
			local ok, parent = pcall(current.GetParent, current)
			if not ok or visit(parent) then return true end
		end
		if current.GetPoint then
			local count = 1
			if current.GetNumPoints then
				local ok, value = pcall(current.GetNumPoints, current)
				count = ok and A:Number(value)
				if not count or count > 128 then return true end
			end
			for index = 1, count do
				local ok, _, relative = pcall(current.GetPoint, current, index)
				if not ok or visit(relative) then return true end
			end
		end
		return false
	end
	return visit(frame)
end

function A:WouldCycle(entry, targetId, context)
	context = context or {}
	local source = self:Consumer(entry, context)
	local targetFrame = self:ResolveTarget(targetId, context)
	if self:FrameDependsOn(targetFrame, entry.frame) then return true end
	if targetFrame and targetFrame.IsDescendantOf then
		local ok, descendant = pcall(targetFrame.IsDescendantOf, targetFrame, entry.frame)
		if not ok or (issecretvalue and issecretvalue(descendant)) or descendant then return true end
	end
	local visited = {}
	local function visit(consumer)
		if not consumer then return false end
		if consumer == source then return true end
		if visited[consumer] then return false end
		visited[consumer] = true
		local assignment = D:GetConsumerAssignment(consumer)
		local rule = assignment and (assignment.profileId and D:GetProfile(assignment.profileId) or assignment)
		if assignment and assignment.enabled and rule then
			for _, candidate in ipairs(rule.candidates or {}) do
				if visit(A:TargetConsumer(candidate.targetId, context)) then return true end
			end
		end
		if not context.entriesByConsumer then
			context.entriesByConsumer = {}
			for _, other in pairs(A.entries) do
				local record = A:Store(other.id)
				if record and (record.widthTarget or record.heightTarget) then
					local owner = A:Consumer(other, context)
					local entries = context.entriesByConsumer[owner] or {}
					context.entriesByConsumer[owner] = entries
					entries[#entries + 1] = other
				end
			end
		end
		for _, other in ipairs(context.entriesByConsumer[consumer] or {}) do
			local record = A:Store(other.id)
			if record and (visit(A:TargetConsumer(record.widthTarget, context)) or visit(A:TargetConsumer(record.heightTarget, context))) then return true end
		end
		return false
	end
	return visit(self:TargetConsumer(targetId, context)) or D:WouldCreateCycle(source, targetId, context)
end

function A:CaptureContext()
	local lib = addon.EditModeLib
	local db = addon.db
	return { db = db, ufFrames = db and db.ufFrames, ufGroupFrames = db and db.ufGroupFrames, generation = lib and lib.GetContextGeneration and lib:GetContextGeneration() or 0 }
end

function A:IsContextCurrent(context)
	local db, lib = addon.db, addon.EditModeLib
	return context and context.db == db and context.ufFrames == (db and db.ufFrames) and context.ufGroupFrames == (db and db.ufGroupFrames)
		and context.generation == (lib and lib.GetContextGeneration and lib:GetContextGeneration() or 0)
end

function A:Snapshot(entry)
	local rule, assignment = self:Rule(entry)
	local adapter = self:Adapter(entry)
	local width, height = entry.frame:GetSize()
	if adapter.getSize then width, height = adapter.getSize() end
	local x, y = self:Offsets(entry.frame, UIParent, "CENTER", "CENTER")
	self.undo = { id = entry.id, entry = entry, frame = entry.frame, db = addon.db, context = self:CaptureContext(), record = CopyTable(self:Store(entry.id) or {}), assignment = CopyTable(assignment or {}), rule = rule and CopyTable(rule), width = self:Number(width), height = self:Number(height), x = x, y = y, adapterState = adapter.snapshot and adapter.snapshot() }
end

function A:ApplyPosition(entry)
	local adapter = self:Adapter(entry)
	if adapter.consumerId then
		D:QueueConsumer(adapter.consumerId, "ANCHOR_EDITOR")
		return
	end
	local result = D:ResolveConsumer(self:Consumer(entry))
	local winner = result.winner
	if not winner or not winner.frame or not winner.placement then return end
	if self:WouldCycle(entry, winner.targetId) then return end
	local p = winner.placement
	local point, relative, relativePoint, x, y = entry.frame:GetPoint(1)
	if point == p.point and relative == winner.frame and relativePoint == p.relativePoint and self:Number(x) == p.x and self:Number(y) == p.y then return end
	entry.frame:ClearAllPoints()
	entry.frame:SetPoint(p.point, winner.frame, p.relativePoint, p.x, p.y)
end

function A:ApplySize(entry, axis, targetId)
	if not targetId then return end
	local adapter = self:Adapter(entry)
	local setter
	if axis == "width" then setter = adapter.setWidth elseif axis == "height" then setter = adapter.setHeight end
	if not setter then return end
	local target = self:ResolveTarget(targetId)
	if not target then return end
	if self:WouldCycle(entry, targetId) then return end
	D:EnsureSimpleTargetHooks(targetId, target)
	local size = self:Number(axis == "width" and target:GetWidth() or target:GetHeight())
	local targetScale, sourceScale = self:Number(target:GetEffectiveScale()), self:Number(entry.frame:GetEffectiveScale())
	if not size or size <= 0 or not targetScale or targetScale <= 0 or not sourceScale or sourceScale <= 0 then return end
	local desired = size * targetScale / sourceScale
	local current = self:Number(axis == "width" and entry.frame:GetWidth() or entry.frame:GetHeight())
	entry.anchorSizeCache = entry.anchorSizeCache or {}
	local previous = entry.anchorSizeCache[axis]
	if current and ((math.abs(current - desired) < .01) or (previous and previous.db == addon.db and math.abs(previous.desired - desired) < .01 and math.abs(previous.actual - current) < .01)) then return end
	if setter(desired) == false then return end
	local actual = self:Number(axis == "width" and entry.frame:GetWidth() or entry.frame:GetHeight())
	if actual then entry.anchorSizeCache[axis] = { desired = desired, actual = actual, db = addon.db } end
end

function A:Apply(entry)
	if self.applying or self:InCombat() or not addon.db or self.dragging == entry.frame then return end
	local record = self:Store(entry.id)
	if not record or not (record.widthTarget or record.heightTarget or (record.assignment and record.assignment.enabled)) then return end
	if entry.isEnabled and not entry.isEnabled(entry.frame) then return end
	self.applying = true
	local ok, err = pcall(function()
		if record then
			self:ApplySize(entry, "width", record.widthTarget)
			self:ApplySize(entry, "height", record.heightTarget)
		end
		-- Native consumers already own their refresh cycle. Only apply generic
		-- positions here, avoiding a queue loop with native layout callbacks.
		if not self:Adapter(entry).consumerId then self:ApplyPosition(entry) end
	end)
	self.applying = nil
	if not ok then geterrorhandler()(err) end
end

function A:Queue(id)
	if not self.entries[id] then return end
	local record = self:Store(id)
	if not record or not (record.widthTarget or record.heightTarget or (record.assignment and record.assignment.enabled)) then return end
	self.pending[id] = true
	if self.scheduled or self:InCombat() then return end
	self.scheduled = true
	C_Timer.After(0, function()
		A.scheduled = nil
		if A:InCombat() then return end
		local pending = A.pending
		A.pending = {}
		for entryId in pairs(pending) do if A.entries[entryId] then A:Apply(A.entries[entryId]) end end
	end)
end

function A:FlushLayoutRestores()
	if self:InCombat() then return end
	local pending = self.layoutRestores
	self.layoutRestores = {}
	for id, frame in pairs(pending) do
		local entry = self.entries[id]
		if entry and entry.frame == frame then
			if E.frames[id] == entry then E:ApplyLayout(id) end
			D:QueueConsumer(self:Consumer(entry), "ANCHOR_EDITOR")
		end
	end
end

function A:QueueLayoutRestore(entry)
	self.layoutRestores[entry.id] = entry.frame
	if self.layoutRestoreScheduled or self:InCombat() then return end
	self.layoutRestoreScheduled = true
	C_Timer.After(0, function()
		A.layoutRestoreScheduled = nil
		A:FlushLayoutRestores()
	end)
end

function A:RegisterEntry(entry)
	if not entry or not entry.frame or not entry.id then return end
	local previous = self.entries[entry.id]
	if previous and previous.frame ~= entry.frame then self.byFrame[previous.frame] = nil end
	if previous and self.selected == previous then self.selected = entry end
	self.entries[entry.id], self.byFrame[entry.frame] = entry, entry
	local id, frame = entry.id, entry.frame
	local ownId = "editMode:" .. id
	if not self:Adapter(entry).consumerId then
		D:RegisterConsumer({ id = ownId, owner = "EnhanceQoL", label = entry.title or frame.editModeName or id,
			getRule = function() local r = A:Store(id); return r and r.assignment end,
			ensureRule = function() local r = A:Store(id, true); if not r then return end; r.assignment = r.assignment or { enabled = false }; return r.assignment end,
			apply = function() A:Queue(id) end,
		})
	end
	local category = E.GetManagerCategory and E:GetManagerCategory(entry.managerCategory, L)
	D:RegisterTarget({ id = ownId, owner = "EnhanceQoL", label = entry.anchorLabel or entry.title or frame.editModeName or id,
		selectable = entry.anchorSelectable ~= false,
		anchorContext = entry.anchorContext or category and category.label,
		getConsumerId = function(_, context) local current = A.entries[id]; return current and A:Consumer(current, context) end,
		resolve = function()
			local current = A.entries[id]
			if not current or (current.isEnabled and not current.isEnabled(current.frame)) then return nil, { available = false } end
			return current.frame, { available = true }
		end,
	})
	self.hooked = self.hooked or setmetatable({}, { __mode = "k" })
	if not self.hooked[frame] then
		self.hooked[frame] = true
		frame:HookScript("OnSizeChanged", function()
			local current = A.byFrame[frame]
			if current and not A.applying then A:Queue(current.id) end
			if current then D:NotifyTargetChanged("editMode:" .. current.id, "ANCHOR_SIZE") end
		end)
		-- Only our registered source frames receive this hook, never Blizzard targets.
		hooksecurefunc(frame, "SetPoint", function()
			local current = A.byFrame[frame]
			if not current or A.applying or A.dragging == frame then return end
			local record = A:Store(current.id)
			local assignment = record and record.assignment
			if assignment and assignment.enabled then A:Queue(current.id) end
		end)
	end
	self:Queue(id)
end

function A:UnregisterEntry(id, purge)
	local entry = self.entries[id]
	if not entry then return end
	local selected = self.selected == entry
	if selected then self.selected, self.picking = nil, nil end
	self.byFrame[entry.frame], self.entries[id], self.pending[id], self.layoutRestores[id] = nil, nil, nil, nil
	D:UnregisterTarget("editMode:" .. id)
	D:UnregisterConsumer("editMode:" .. id)
	if purge and addon.db and addon.db.editModeAnchorLinks then addon.db.editModeAnchorLinks[id] = nil end
	if selected and self.RefreshUI then self:RefreshUI() end
end

function A:Discover()
	for _, entry in pairs(E.frames) do self:RegisterEntry(entry) end
	local external = {}
	if self.GetExternalEntries then
		for _, entry in ipairs(self:GetExternalEntries()) do
			external[entry.id] = true
			self:RegisterEntry(entry)
		end
	end
	for id in pairs(self.externalEntries or {}) do
		if not external[id] and not E.frames[id] then self:UnregisterEntry(id) end
	end
	self.externalEntries = external
end

function A:Changed(entry)
	entry.anchorSizeCache = nil
	D:QueueConsumer(self:Consumer(entry), "ANCHOR_EDITOR")
	D:NotifyTargetChanged("editMode:" .. entry.id, "ANCHOR_EDITOR")
	self:Queue(entry.id)
	if self.RefreshUI then self:RefreshUI() end
end

function A:SetAnchor(entry, targetId)
	if self:InCombat() then return false end
	local target = self:ResolveTarget(targetId)
	if not target then return false, L["EditModeAnchorInvalidTarget"] end
	if self:WouldCycle(entry, targetId) then return false, L["EditModeAnchorCycle"] end
	local x, y = self:Offsets(entry.frame, target, "CENTER", "CENTER")
	if not x then return false, L["EditModeAnchorSizeUnavailable"] end
	self:Snapshot(entry)
	local rule, assignment = self:EditableRule(entry)
	if not rule then return false, L["EditModeAnchorUnsupported"] end
	local adapter = self:Adapter(entry)
	if adapter.prepareAnchor then adapter.prepareAnchor() end
	rule.candidates = { { id = "candidate-1", targetId = targetId, placement = { point = "CENTER", relativePoint = "CENTER", x = x, y = y } } }
	rule.candidateCount = 1
	local fx, fy = self:Offsets(entry.frame, UIParent, "CENTER", "CENTER")
	rule.finalFallback = { placement = { point = "CENTER", relativePoint = "CENTER", x = fx or 0, y = fy or 0 } }
	assignment.enabled = true
	self:Changed(entry)
	return true
end

function A:ChangePlacement(entry, point, relativePoint, x, y, preserve)
	if self:InCombat() then return false end
	local candidate, index = self:Candidate(entry)
	if not candidate then return false end
	local p = candidate.placement
	point, relativePoint = point or p.point, relativePoint or p.relativePoint
	if not self.factors[point] or not self.factors[relativePoint] then return false end
	if preserve then x, y = self:Offsets(entry.frame, self:ResolveTarget(candidate.targetId), point, relativePoint); if not x then return false end end
	self:Snapshot(entry)
	local rule = self:EditableRule(entry)
	rule.candidates[index].placement = { point = point, relativePoint = relativePoint, x = x or p.x, y = y or p.y }
	self:Changed(entry)
	return true
end

function A:Detach(entry)
	if self:InCombat() then return false end
	local x, y = self:Offsets(entry.frame, UIParent, "CENTER", "CENTER")
	if not x then return false end
	self:Snapshot(entry)
	local assignment = self:Assignment(entry)
	if assignment then assignment.enabled = false end
	local adapter = self:Adapter(entry)
	if adapter.detach then adapter.detach("CENTER", "CENTER", x, y)
	else
		E:SetFramePosition(entry.id, "CENTER", x, y, nil, true, "CENTER")
		if entry.onPositionChanged then entry.onPositionChanged(entry.frame, E:GetActiveLayoutName(), E:EnsureLayoutData(entry.id)) end
		E:ApplyLayout(entry.id)
	end
	self:Changed(entry)
	return true
end

function A:SetSizeLink(entry, axis, targetId)
	if self:InCombat() or (axis ~= "width" and axis ~= "height") then return false end
	local adapter = self:Adapter(entry)
	if not (axis == "width" and adapter.setWidth or axis == "height" and adapter.setHeight) then return false, L["EditModeAnchorUnsupported"] end
	if targetId then
		local target = self:ResolveTarget(targetId)
		if not target then return false, L["EditModeAnchorInvalidTarget"] end
		if self:WouldCycle(entry, targetId) then return false, L["EditModeAnchorCycle"] end
		local size = self:Number(axis == "width" and target:GetWidth() or target:GetHeight())
		local targetScale, sourceScale = self:Number(target:GetEffectiveScale()), self:Number(entry.frame:GetEffectiveScale())
		if not size or size <= 0 or not targetScale or targetScale <= 0 or not sourceScale or sourceScale <= 0 then return false, L["EditModeAnchorSizeUnavailable"] end
	end
	self:Snapshot(entry)
	if targetId and adapter.prepareSize then adapter.prepareSize(axis) end
	if targetId and axis == "width" then
		local current = self:Rule(entry)
		local matchesWidth = false
		for _, candidate in ipairs(current and current.candidates or {}) do if candidate.matchRelativeWidth then matchesWidth = true; break end end
		if matchesWidth then
			local rule = self:EditableRule(entry)
			for _, candidate in ipairs(rule.candidates) do candidate.matchRelativeWidth = false end
		end
	end
	self:Store(entry.id, true)[axis .. "Target"] = targetId
	if targetId then D:EnsureSimpleTargetHooks(targetId, self:ResolveTarget(targetId)) end
	self:Changed(entry)
	return true
end

function A:Undo()
	local undo = self.undo
	local entry = undo and self.entries[undo.id]
	if not entry or undo.entry ~= entry or undo.frame ~= entry.frame or not self:IsContextCurrent(undo.context) or self:InCombat() then return end
	local currentRecord = self:Store(entry.id)
	local currentProfileId = currentRecord and currentRecord.profileId
	local assignment = self:Assignment(entry, true)
	if assignment then
		for key in pairs(assignment) do assignment[key] = nil end
		for key, value in pairs(undo.assignment) do assignment[key] = type(value) == "table" and CopyTable(value) or value end
	end
	if undo.assignment.profileId and currentProfileId == undo.assignment.profileId and undo.record.profileId == undo.assignment.profileId and undo.rule then
		D:GetProfiles()[undo.assignment.profileId] = CopyTable(undo.rule)
	end
	addon.db.editModeAnchorLinks = addon.db.editModeAnchorLinks or {}
	addon.db.editModeAnchorLinks[entry.id] = CopyTable(undo.record)
	if currentProfileId and currentProfileId ~= undo.record.profileId then
		local used = false
		for id in pairs(D.consumers) do
			local other = D:GetConsumerAssignment(id)
			if other and other.profileId == currentProfileId then used = true; break end
		end
		if not used then D:GetProfiles()[currentProfileId] = nil end
	end
	local adapter = self:Adapter(entry)
	self.applying = true
	local ok, err = pcall(function()
		if adapter.restore and undo.adapterState then
			adapter.restore(undo.adapterState)
		else
			if adapter.setWidth and undo.width then adapter.setWidth(undo.width) end
			if adapter.setHeight and undo.height then adapter.setHeight(undo.height) end
		end
		if not (adapter.restore and undo.adapterState) and not undo.assignment.enabled and undo.x then
			if adapter.detach then adapter.detach("CENTER", "CENTER", undo.x, undo.y)
			else
				E:SetFramePosition(entry.id, "CENTER", undo.x, undo.y, nil, true, "CENTER")
				if entry.onPositionChanged then entry.onPositionChanged(entry.frame, E:GetActiveLayoutName(), E:EnsureLayoutData(entry.id)) end
				E:ApplyLayout(entry.id)
			end
		end
	end)
	self.applying, self.undo = nil, nil
	if not ok then geterrorhandler()(err) end
	self:Changed(entry)
end

hooksecurefunc(D, "NotifyTargetChanged", function(_, targetId)
	for id in pairs(A.entries) do
		local record = A:Store(id)
		if record and (record.widthTarget == targetId or record.heightTarget == targetId) then A:Queue(id) end
	end
end)

A.events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "PLAYER_SPECIALIZATION_CHANGED", "ADDON_LOADED" }) do A.events:RegisterEvent(event) end
A.events:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_REGEN_DISABLED" then if A.SetActive then A:SetActive(false) end; return end
	if A.discoveryScheduled then return end
	A.discoveryScheduled = true
	C_Timer.After(0, function()
		A.discoveryScheduled = nil
		if A:InCombat() then return end
		A:Discover()
		A:FlushLayoutRestores()
		for id in pairs(A.entries) do A:Queue(id) end
		if A.active and A.RefreshUI then A:RefreshUI() end
	end)
end)
