local _, addon = ...
local A = addon.EditModeAnchors
local D = addon.DynamicAnchors
local E = addon.EditMode
local lib = addon.EditModeLib
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

A.ui = { overlays = {}, targets = {}, elapsed = 0 }
A.ui.lineStyles = {
	anchor = { r = .2, g = 1, b = .3, offset = 0 },
	width = { r = .1, g = .85, b = 1, offset = -5 },
	height = { r = 1, g = .4, b = .1, offset = 5 },
}

function A:EntryLabel(entry)
	return entry and (entry.title or entry.frame.editModeName or entry.id) or L["EditModeAnchorSelectSource"]
end

function A:UIResult(ok, reason)
	self.ui.message = not ok and (reason or L["EditModeAnchorUnsupported"]) or nil
	self:RefreshUI()
end

function A:PointLabel(point)
	local options = addon.SharedAnchors and addon.SharedAnchors:GetAnchorPointOptions()
	for _, option in ipairs(options or {}) do
		if option.value == point or option.key == point then return option.label or option.text or point end
	end
	return _G[point] or point
end

function A:MakeButton(parent, label, x, y, width, callback)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetPoint("TOPLEFT", x, y)
	button:SetSize(width, 24)
	button:SetText(label)
	local text = button:GetFontString()
	if text then text:SetWidth(width - 12); text:SetWordWrap(false) end
	button.tooltipText = label
	button:SetScript("OnClick", function() if not A:InCombat() then callback() end end)
	return button
end

function A:MakeText(parent, text, x, y, width, font)
	local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
	label:SetPoint("TOPLEFT", x, y)
	label:SetWidth(width)
	label:SetJustifyH("LEFT")
	label:SetText(text)
	return label
end

function A:UpdatePickButton(button, kind, label)
	local picking = self.picking == kind
	button:SetText(picking and _G.CANCEL or label)
	button.tooltipText = picking and L["EditModeAnchorSelectTarget"] or label
	if picking then button:LockHighlight() else button:UnlockHighlight() end
end

function A:MakePointDropdown(parent, field, label, x, y)
	self:MakeText(parent, label, x, y, 178, "GameFontNormal")
	local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
	dropdown:SetPoint("TOPLEFT", x, y - 19)
	dropdown:SetWidth(178)
	dropdown:SetupMenu(function(_, root)
		for _, point in ipairs(A.points) do
			root:CreateRadio(A:PointLabel(point), function()
				local candidate = A.selected and A:Candidate(A.selected)
				return candidate and candidate.placement[field] == point
			end, function()
				local candidate = A.selected and A:Candidate(A.selected)
				if not candidate then return end
				local p = candidate.placement
				A:UIResult(A:ChangePlacement(A.selected, field == "point" and point or p.point, field == "relativePoint" and point or p.relativePoint, nil, nil, true))
			end)
		end
	end)
	return dropdown
end

function A:WriteOffset(axis, value)
	if not self.active or self:InCombat() or not self.selected or not self:Number(value) then return end
	local candidate = self:Candidate(self.selected)
	if not candidate then return end
	local p = candidate.placement
	self:UIResult(self:ChangePlacement(self.selected, p.point, p.relativePoint, axis == "x" and value or p.x, axis == "y" and value or p.y))
end

function A:MakeOffset(parent, axis, label, x, y)
	self:MakeText(parent, label, x, y, 178, "GameFontNormal")
	local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	input:SetPoint("TOPLEFT", x + 30, y - 21)
	input:SetSize(110, 24)
	input:SetAutoFocus(false)
	input:SetMaxLetters(12)
	input:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			local value = tonumber((self:GetText():gsub(",", ".")))
			if value then A:WriteOffset(axis, value) end
		end
	end)
	input:SetScript("OnEnterPressed", function(self) self:ClearFocus(); A:RefreshUI() end)
	input:SetScript("OnEscapePressed", function(self) self:ClearFocus(); A:CancelOrExit() end)
	input:SetScript("OnEditFocusLost", function() A:RefreshUI() end)
	local function step(direction)
		local candidate = A.selected and A:Candidate(A.selected)
		if candidate then A:WriteOffset(axis, (candidate.placement[axis] or 0) + direction * (IsShiftKeyDown() and 10 or 1)) end
	end
	input.Minus = self:MakeButton(parent, "-", x, y - 21, 24, function() step(-1) end)
	input.Plus = self:MakeButton(parent, "+", x + 148, y - 21, 24, function() step(1) end)
	return input
end

function A:EnsureWindow()
	if self.ui.window then return self.ui.window end
	local window = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	window:SetSize(420, 642)
	window:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
	window:SetFrameStrata("DIALOG")
	window:SetFrameLevel(350)
	window:SetClampedToScreen(true)
	window:EnableMouse(true)
	window:EnableKeyboard(true)
	window:SetPropagateKeyboardInput(true)
	window:SetMovable(true)
	window:RegisterForDrag("LeftButton")
	window:SetScript("OnDragStart", function(self) if not A:InCombat() then self:StartMoving() end end)
	window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	window:SetScript("OnKeyDown", function(self, key)
		if A:InCombat() then return end
		self:SetPropagateKeyboardInput(key ~= "ESCAPE")
		if key == "ESCAPE" then A:CancelOrExit() end
	end)
	window:SetScript("OnKeyUp", function(self) if not A:InCombat() then self:SetPropagateKeyboardInput(true) end end)
	window:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
	window:SetBackdropColor(.025, .035, .045, .96)
	window:SetBackdropBorderColor(.25, .7, .8, 1)
	self.ui.window = window
	self:MakeText(window, L["EditModeAnchorTitle"], 18, -15, 370, "GameFontNormalLarge")
	local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)
	close:SetScript("OnClick", function() A:SetActive(false) end)
	window.SourceLabel = self:MakeText(window, L["EditModeAnchorSource"], 18, -47, 380, "GameFontNormal")
	window.Source = self:MakeText(window, "", 18, -65, 380)
	window.TargetLabel = self:MakeText(window, L["EditModeAnchorTarget"], 18, -94, 380, "GameFontNormal")
	window.Target = self:MakeText(window, "", 18, -112, 380)
	local banner = CreateFrame("Frame", nil, window)
	banner:SetPoint("TOPLEFT", 18, -44)
	banner:SetSize(384, 84)
	banner:EnableMouse(false)
	banner.Fill = banner:CreateTexture(nil, "BACKGROUND")
	banner.Fill:SetAllPoints()
	banner.Fill:SetColorTexture(.25, .04, .34, .96)
	banner.Accent = banner:CreateTexture(nil, "ARTWORK")
	banner.Accent:SetPoint("TOPLEFT"); banner.Accent:SetPoint("BOTTOMLEFT"); banner.Accent:SetWidth(4)
	banner.Accent:SetColorTexture(.9, .2, 1, 1)
	banner.Title = self:MakeText(banner, "", 12, -8, 360, "GameFontNormalLarge")
	banner.Title:SetHeight(32)
	banner.Title:SetJustifyV("TOP")
	banner.Help = self:MakeText(banner, L["EditModeAnchorSelectTarget"], 12, -44, 360, "GameFontHighlightSmall")
	banner.Help:SetHeight(32)
	banner.Help:SetJustifyV("TOP")
	banner:Hide()
	window.PickingBanner = banner
	window.Choose = self:MakeButton(window, L["EditModeAnchorChooseTarget"], 18, -138, 184, function() A:BeginPick("anchor") end)
	window.Detach = self:MakeButton(window, L["EditModeAnchorDetach"], 212, -138, 190, function() if A.selected then A:UIResult(A:Detach(A.selected)) end end)
	window.Point = self:MakePointDropdown(window, "point", L["EditModeAnchorPoint"], 18, -177)
	window.RelativePoint = self:MakePointDropdown(window, "relativePoint", L["EditModeAnchorRelativePoint"], 218, -177)
	window.X = self:MakeOffset(window, "x", L["EditModeAnchorOffsetX"], 18, -231)
	window.Y = self:MakeOffset(window, "y", L["EditModeAnchorOffsetY"], 218, -231)
	window.Presets = {}
	for index, preset in ipairs({ { "Above", "BOTTOM", "TOP" }, { "Below", "TOP", "BOTTOM" }, { "Left", "RIGHT", "LEFT" }, { "Right", "LEFT", "RIGHT" }, { "Center", "CENTER", "CENTER" } }) do
		window.Presets[index] = self:MakeButton(window, L["EditModeAnchor" .. preset[1]], 18 + (index - 1) * 78, -291, 73, function()
			if A.selected then A:UIResult(A:ChangePlacement(A.selected, preset[2], preset[3], 0, 0)) end
		end)
	end
	window.Flush = self:MakeButton(window, L["EditModeAnchorFlush"], 18, -323, 384, function()
		if A.selected then A:UIResult(A:ChangePlacement(A.selected, nil, nil, 0, 0)) end
	end)
	window.Width = self:MakeButton(window, L["EditModeAnchorMatchWidth"], 18, -362, 184, function() A:BeginPick("width") end)
	window.Height = self:MakeButton(window, L["EditModeAnchorMatchHeight"], 218, -362, 184, function() A:BeginPick("height") end)
	window.WidthTarget = self:MakeText(window, "", 18, -393, 184, "GameFontHighlightSmall")
	window.HeightTarget = self:MakeText(window, "", 218, -393, 184, "GameFontHighlightSmall")
	window.WidthTarget:SetTextColor(self.ui.lineStyles.width.r, self.ui.lineStyles.width.g, self.ui.lineStyles.width.b)
	window.HeightTarget:SetTextColor(self.ui.lineStyles.height.r, self.ui.lineStyles.height.g, self.ui.lineStyles.height.b)
	window.ClearWidth = self:MakeButton(window, L["EditModeAnchorClearWidth"], 18, -417, 184, function() if A.selected then A:UIResult(A:SetSizeLink(A.selected, "width")) end end)
	window.ClearHeight = self:MakeButton(window, L["EditModeAnchorClearHeight"], 218, -417, 184, function() if A.selected then A:UIResult(A:SetSizeLink(A.selected, "height")) end end)
	window.Undo = self:MakeButton(window, L["EditModeAnchorUndo"], 18, -455, 384, function() A:Undo(); A:RefreshUI() end)
	window.Status = self:MakeText(window, "", 18, -492, 384)
	window.Status:SetHeight(50)
	window.Status:SetJustifyV("TOP")
	local legend = self:MakeText(window, L["EditModeAnchorLegend"], 18, -551, 384, "GameFontHighlightSmall")
	legend:SetHeight(45)
	legend:SetJustifyV("TOP")
	local lineLegend = self:MakeText(window, L["EditModeAnchorLineLegend"], 18, -594, 384, "GameFontHighlightSmall")
	lineLegend:SetHeight(34)
	lineLegend:SetJustifyV("TOP")
	window:SetScript("OnUpdate", function(_, elapsed)
		A.ui.elapsed = A.ui.elapsed + elapsed
		if A.ui.elapsed < .1 then return end
		A.ui.elapsed = 0
		if not A:IsContextCurrent(A.ui.context) or A:InCombat() or not lib.isEditing then A:SetActive(false); return end
		A:UpdateOverlays()
	end)
	window:Hide()
	return window
end

function A:RefreshUI()
	if not self.active then return end
	local window = self:EnsureWindow()
	local entry = self.selected
	local candidate = entry and self:Candidate(entry)
	local placement = candidate and candidate.placement
	local adapter = entry and self:Adapter(entry) or {}
	local record = entry and self:Store(entry.id) or {}
	record = record or {}
	window.Source:SetText(self:EntryLabel(entry))
	window.Target:SetText(candidate and D:GetTargetLabel(candidate.targetId) or L["EditModeAnchorUnanchored"])
	for _, field in ipairs({ "SourceLabel", "Source", "TargetLabel", "Target" }) do window[field]:SetShown(self.picking == nil) end
	window.PickingBanner:SetShown(self.picking ~= nil)
	window.PickingBanner.Title:SetText(self.picking == "width" and L["EditModeAnchorPickWidth"] or self.picking == "height" and L["EditModeAnchorPickHeight"] or L["EditModeAnchorSelection"])
	self:UpdatePickButton(window.Choose, "anchor", L["EditModeAnchorChooseTarget"])
	self:UpdatePickButton(window.Width, "width", L["EditModeAnchorMatchWidth"])
	self:UpdatePickButton(window.Height, "height", L["EditModeAnchorMatchHeight"])
	window.Choose:SetEnabled(entry ~= nil)
	window.Detach:SetEnabled(candidate ~= nil)
	window.Point:SetEnabled(candidate ~= nil)
	window.RelativePoint:SetEnabled(candidate ~= nil)
	window.Point:SetDefaultText(self:PointLabel(placement and placement.point or "CENTER"))
	window.RelativePoint:SetDefaultText(self:PointLabel(placement and placement.relativePoint or "CENTER"))
	window.Point:GenerateMenu()
	window.RelativePoint:GenerateMenu()
	for _, field in ipairs({ "X", "Y" }) do
		local input = window[field]
		input:SetEnabled(candidate ~= nil)
		input.Plus:SetEnabled(candidate ~= nil)
		input.Minus:SetEnabled(candidate ~= nil)
		if not input:HasFocus() then input:SetText(placement and string.format("%.2f", placement[field:lower()] or 0):gsub("%.?0+$", "") or "0") end
	end
	for _, button in ipairs(window.Presets) do button:SetEnabled(candidate ~= nil) end
	window.Flush:SetEnabled(candidate ~= nil)
	window.Width:SetEnabled(adapter.setWidth ~= nil)
	window.Height:SetEnabled(adapter.setHeight ~= nil)
	window.WidthTarget:SetText(L["EditModeAnchorLinkedWidth"]:format(record.widthTarget and D:GetTargetLabel(record.widthTarget) or _G.NONE or ""))
	window.HeightTarget:SetText(L["EditModeAnchorLinkedHeight"]:format(record.heightTarget and D:GetTargetLabel(record.heightTarget) or _G.NONE or ""))
	window.ClearWidth:SetEnabled(record.widthTarget ~= nil and adapter.setWidth ~= nil)
	window.ClearHeight:SetEnabled(record.heightTarget ~= nil and adapter.setHeight ~= nil)
	window.Undo:SetEnabled(self.undo ~= nil and self.undo.db == addon.db)
	local status = self.ui.message or (self.picking and L["EditModeAnchorSelectTarget"]) or (not entry and L["EditModeAnchorSelectSource"]) or (not candidate and L["EditModeAnchorNoTarget"])
	if not status and candidate and not self:ResolveTarget(candidate.targetId) then status = L["EditModeAnchorTargetUnavailable"] end
	window.Status:SetText(status or L["EditModeAnchorDescription"])
	window:Show()
	self:UpdateOverlays()
end

function A:SelectFrame(frame)
	if not self.active or self:InCombat() then return false end
	local entry = self.byFrame[frame]
	if entry and entry.isAnchorSelectable and not entry.isAnchorSelectable(frame) then return false end
	if self.picking then
		if self:TargetAtCursor() then self:PickAtCursor()
		elseif entry == self.selected then self.picking = nil; self:RefreshUI() end
		return true
	end
	if not entry then return false end
	self.selected, self.ui.message = entry, nil
	lib:HideSettingsDialog()
	if _G.EditModeSystemSettingsDialog then _G.EditModeSystemSettingsDialog:Hide() end
	self:RefreshUI()
	return true
end

function A:BeginPick(kind)
	if not self.selected or self:InCombat() then return end
	if self.picking == kind then self:CancelOrExit(); return end
	local adapter = self:Adapter(self.selected)
	if kind == "width" and not adapter.setWidth or kind == "height" and not adapter.setHeight then return end
	self.picking, self.ui.message = kind, nil
	self.ui.targets = {}
	local context = {}
	for _, option in ipairs(D:GetTargetOptions(self:Consumer(self.selected, context), context)) do
		local frame = self:ResolveTarget(option.value)
		if frame and frame ~= UIParent and not self:WouldCycle(self.selected, option.value, context) then self.ui.targets[#self.ui.targets + 1] = { id = option.value, frame = frame } end
	end
	self:RefreshUI()
end

function A:CancelOrExit()
	if self.picking then self.picking, self.ui.message = nil, nil; self:RefreshUI() else self:SetActive(false) end
end

function A:FrameRect(frame)
	-- Cursor-bound panels must not cover other sources or targets with pick overlays.
	local entry = frame and self.byFrame[frame]
	if entry and entry.isAnchorSelectable and not entry.isAnchorSelectable(frame) then return nil end
	if not frame or not frame.IsShown or not frame:IsShown() or not frame:IsVisible() then return nil end
	local left, bottom, width, height = frame:GetRect()
	left, bottom, width, height = self:Number(left), self:Number(bottom), self:Number(width), self:Number(height)
	local scale = self:Number(frame:GetEffectiveScale())
	local uiScale = self:Number(UIParent:GetEffectiveScale())
	if not left or not bottom or not width or not height or not scale or scale <= 0 or not uiScale or uiScale <= 0 or width <= 0 or height <= 0 then return nil end
	local ratio = scale / uiScale
	return left * ratio, bottom * ratio, width * ratio, height * ratio
end

function A:IsSourceOverlayVisible(frame)
	local selection = lib.selectionRegistry[frame]
	if selection then return selection:IsShown() and not selection.overlayHidden end
	local eye = lib.internal.managerEyeButton
	return not (eye and eye.allHidden)
end

function A:TargetAtCursor()
	local x, y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	x, y = x / scale, y / scale
	local best, area
	for _, target in ipairs(self.ui.targets) do
		local left, bottom, width, height = self:FrameRect(target.frame)
		if left and x >= left and x <= left + width and y >= bottom and y <= bottom + height then
			local current = width * height
			if not area or current < area or current == area and target.id < best.id then best, area = target, current end
		end
	end
	return best
end

function A:SourceAtCursor()
	local x, y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	x, y = x / scale, y / scale
	local best, area
	for _, entry in pairs(self.entries) do
		if self:IsSourceOverlayVisible(entry.frame) and (not entry.isEnabled or entry.isEnabled(entry.frame)) then
			local left, bottom, width, height = self:FrameRect(entry.frame)
			if left and x >= left and x <= left + width and y >= bottom and y <= bottom + height then
				local current = width * height
				if not area or current < area or current == area and entry.id < best.id then best, area = entry, current end
			end
		end
	end
	return best
end

function A:PickAtCursor()
	if not self.picking or not self.selected or self:InCombat() then return end
	local target = self:TargetAtCursor()
	if not target then return end
	local kind, source = self.picking, self.selected
	self.picking = nil
	if kind == "anchor" then self:UIResult(self:SetAnchor(source, target.id)) else self:UIResult(self:SetSizeLink(source, kind, target.id)) end
end

function A:GetOverlay(key)
	local overlay = self.ui.overlays[key]
	if overlay then return overlay end
	overlay = CreateFrame("Frame", nil, UIParent)
	overlay:SetFrameStrata("DIALOG")
	overlay:SetFrameLevel(300)
	overlay:RegisterForDrag("LeftButton")
	overlay.Fill = overlay:CreateTexture(nil, "BACKGROUND")
	overlay.Fill:SetAllPoints()
	overlay.Edges = {}
	for index = 1, 4 do overlay.Edges[index] = overlay:CreateTexture(nil, "OVERLAY") end
	overlay.Edges[1]:SetPoint("TOPLEFT"); overlay.Edges[1]:SetPoint("TOPRIGHT"); overlay.Edges[1]:SetHeight(3)
	overlay.Edges[2]:SetPoint("BOTTOMLEFT"); overlay.Edges[2]:SetPoint("BOTTOMRIGHT"); overlay.Edges[2]:SetHeight(3)
	overlay.Edges[3]:SetPoint("TOPLEFT"); overlay.Edges[3]:SetPoint("BOTTOMLEFT"); overlay.Edges[3]:SetWidth(3)
	overlay.Edges[4]:SetPoint("TOPRIGHT"); overlay.Edges[4]:SetPoint("BOTTOMRIGHT"); overlay.Edges[4]:SetWidth(3)
	overlay.Label = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	overlay.Label:SetPoint("CENTER")
	overlay.Label:SetWordWrap(false)
	overlay:SetScript("OnEnter", function() if not A.ui.updating then A:UpdateOverlays() end end)
	overlay:SetScript("OnMouseDown", function(self)
		self.blockDrag = A.picking ~= nil
		self.dragEntry = nil
		if A.picking then
			if A:TargetAtCursor() then A:PickAtCursor()
			elseif self.entry == A.selected then A.picking = nil; A:RefreshUI() end
		elseif self.entry then
			local entry = A:SourceAtCursor() or self.entry
			A:SelectFrame(entry.frame)
			self.dragEntry = entry
		end
	end)
	overlay:SetScript("OnMouseUp", function(self) self.blockDrag = nil end)
	overlay:SetScript("OnDragStart", function(self)
		local entry = self.dragEntry
		if self.blockDrag or not entry or not A:CanDrag(entry.frame) then return end
		A:DragStart(entry.frame)
		entry.frame:SetMovable(true)
		entry.frame:StartMoving()
	end)
	overlay:SetScript("OnDragStop", function(self)
		local entry = self.dragEntry
		if entry and A.dragging == entry.frame and not A:InCombat() then
			entry.frame:StopMovingOrSizing()
			A:DragStop(entry.frame)
		end
		self.dragEntry = nil
	end)
	self.ui.overlays[key] = overlay
	return overlay
end

function A:PlaceOverlay(key, frame, entry, r, g, b, interactive, label)
	local left, bottom, width, height = self:FrameRect(frame)
	if not left then return end
	local overlay = self:GetOverlay(key)
	overlay.seen, overlay.entry = true, entry
	if overlay.anchorLeft ~= left or overlay.anchorBottom ~= bottom then
		overlay:ClearAllPoints()
		overlay:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
		overlay.anchorLeft, overlay.anchorBottom = left, bottom
	end
	if overlay.anchorWidth ~= width or overlay.anchorHeight ~= height then
		overlay:SetSize(width, height)
		overlay.Label:SetWidth(math.max(1, width - 6))
		overlay.anchorWidth, overlay.anchorHeight = width, height
	end
	if overlay.anchorR ~= r or overlay.anchorG ~= g or overlay.anchorB ~= b then
		overlay.Fill:SetColorTexture(r, g, b, .30)
		for _, edge in ipairs(overlay.Edges) do edge:SetColorTexture(r, g, b, 1) end
		overlay.anchorR, overlay.anchorG, overlay.anchorB = r, g, b
	end
	if issecretvalue and issecretvalue(label) then
		overlay.Label:SetText(label)
		overlay.anchorLabel = nil
	else
		label = label or ""
		if overlay.anchorLabel ~= label then overlay.Label:SetText(label); overlay.anchorLabel = label end
	end
	overlay:EnableMouse(interactive == true and not self.ui.overControls)
	overlay:Show()
	return overlay
end

function A:UpdateOverlays()
	if not self.active or self.ui.updating then return end
	self.ui.updating = true
	self.ui.overControls = (_G.MouseIsOver and ((EditModeManagerFrame and EditModeManagerFrame:IsShown() and MouseIsOver(EditModeManagerFrame)) or (self.ui.window and self.ui.window:IsShown() and MouseIsOver(self.ui.window)))) and true or false
	for _, overlay in pairs(self.ui.overlays) do overlay.seen = nil end
	if self.picking then for _, target in ipairs(self.ui.targets) do target.frame = self:ResolveTarget(target.id) end end
	local hovered = self.picking and self:TargetAtCursor()
	for _, entry in pairs(self.entries) do
		local selection = lib.selectionRegistry[entry.frame]
		local visible = self:IsSourceOverlayVisible(entry.frame)
		if visible and (not entry.isEnabled or entry.isEnabled(entry.frame)) then
			local selected = entry == self.selected
			self:PlaceOverlay("source:" .. entry.id, entry.frame, entry, selected and 1 or .9, selected and .82 or .2, selected and 0 or 1, not selection and not self.picking, self:EntryLabel(entry))
		end
	end
	if self.picking then
		local drawnFrames = {}
		for _, target in ipairs(self.ui.targets) do
			local frame = target.frame
			if frame and not drawnFrames[frame] then
				drawnFrames[frame] = true
				local active = hovered and hovered.frame == frame
				local targetId = active and hovered.id or target.id
				-- A frame can have several registered target aliases. Draw it once,
				-- above source overlays, and keep the hovered target above other targets.
				local overlay = self:PlaceOverlay("target:" .. targetId, frame, nil, active and .15 or .9, active and 1 or .2, active and .2 or 1, true, D:GetTargetLabel(targetId))
				if overlay then overlay:SetFrameLevel(active and 330 or 310) end
			end
		end
		if self.selected then
			local overlay = self:PlaceOverlay("cancel", self.selected.frame, self.selected, 1, .82, 0, true, self:EntryLabel(self.selected))
			if overlay then overlay:SetFrameLevel(320) end
		end
	end
	for _, overlay in pairs(self.ui.overlays) do if not overlay.seen then overlay:Hide(); overlay:EnableMouse(false) end end
	self:UpdateLine(hovered)
	self.ui.updating = nil
end

function A:UpdateLine(hovered)
	if not self.ui.lineFrame then
		self.ui.lineFrame = CreateFrame("Frame", nil, UIParent)
		self.ui.lineFrame:SetAllPoints(UIParent)
		self.ui.lineFrame:SetFrameStrata("HIGH")
		self.ui.lineFrame:EnableMouse(false)
		self.ui.lines = {}
		for kind, style in pairs(self.ui.lineStyles) do
			local line = self.ui.lineFrame:CreateLine(nil, "OVERLAY")
			line:SetThickness(2)
			line:SetColorTexture(style.r, style.g, style.b, .95)
			self.ui.lines[kind] = line
		end
		self.ui.line = self.ui.lines.anchor
	end
	for _, line in pairs(self.ui.lines) do line:Hide() end
	local entry = self.selected
	if not entry or (not self:IsSourceOverlayVisible(entry.frame) and not self.picking) then return end
	local candidate = self:Candidate(entry)
	local record = self:Store(entry.id) or {}
	local targets = {
		anchor = candidate and self:ResolveTarget(candidate.targetId),
		width = record.widthTarget and self:ResolveTarget(record.widthTarget),
		height = record.heightTarget and self:ResolveTarget(record.heightTarget),
	}
	if hovered and self.picking then targets[self.picking] = hovered.frame end
	local x, y = self:Geometry(entry.frame, "CENTER")
	local scale = self:Number(UIParent:GetEffectiveScale())
	if not x or not y or not scale or scale <= 0 then return end
	x, y = x / scale, y / scale
	for kind, line in pairs(self.ui.lines) do
		local tx, ty = self:Geometry(targets[kind], "CENTER")
		if tx and ty then
			tx, ty = tx / scale, ty / scale
			local dx, dy = tx - x, ty - y
			local length = math.sqrt(dx * dx + dy * dy)
			local offset = self.ui.lineStyles[kind].offset
			local ox, oy = 0, 0
			-- Parallel offsets keep all three links visible when they share a target.
			if length > 0 then ox, oy = -dy / length * offset, dx / length * offset end
			line:SetStartPoint("BOTTOMLEFT", UIParent, x + ox, y + oy)
			line:SetEndPoint("BOTTOMLEFT", UIParent, tx + ox, ty + oy)
			line:Show()
		end
	end
end

function A:CanDrag(frame)
	if not (self.active and self:IsContextCurrent(self.ui.context) and not self.picking and self.selected and self.selected.frame == frame and not self:InCombat()) then return false end
	local adapter = self:Adapter(self.selected)
	return not adapter.canDrag or adapter.canDrag(frame) ~= false
end

function A:DragStart(frame)
	if self:CanDrag(frame) then
		self:Snapshot(self.byFrame[frame])
		self.ui.dragUndo, self.dragging = self.undo, frame
	end
end

function A:DragStop(frame)
	local entry = self.byFrame[frame]
	if not entry or not self.active or self:InCombat() then self.dragging = nil; return false end
	if not self.ui.dragUndo or self.ui.dragUndo.entry ~= entry or not self:IsContextCurrent(self.ui.dragUndo.context) then
		self:SetActive(false)
		return false
	end
	local candidate = self:Candidate(entry)
	if candidate then
		local p = candidate.placement
		local x, y = self:Offsets(frame, self:ResolveTarget(candidate.targetId), p.point, p.relativePoint)
		if x then self:UIResult(self:ChangePlacement(entry, p.point, p.relativePoint, x, y)) end
	else
		local x, y = self:Offsets(frame, UIParent, "CENTER", "CENTER")
		if x then
			local adapter = self:Adapter(entry)
			if adapter.detach then adapter.detach("CENTER", "CENTER", x, y)
			else
				E:SetFramePosition(entry.id, "CENTER", x, y, nil, true, "CENTER")
				if entry.onPositionChanged then entry.onPositionChanged(frame, E:GetActiveLayoutName(), E:EnsureLayoutData(entry.id)) end
				E:ApplyLayout(entry.id)
			end
		end
	end
	if self.ui.dragUndo then self.undo, self.ui.dragUndo = self.ui.dragUndo, nil end
	self.dragging = nil
	self:Queue(entry.id)
	self:RefreshUI()
	return true
end

function A:HideDefaultDialog()
	local dialog = _G.EditModeSystemSettingsDialog
	if not dialog then return end
	if not self.ui.dialogHooked then
		self.ui.dialogHooked = true
		dialog:HookScript("OnShow", function(self)
			if not A.active then return end
			C_Timer.After(0, function() if A.active and lib.isEditing and not A:InCombat() and self:IsShown() then self:Hide() end end)
		end)
	end
	if not self:InCombat() then dialog:Hide() end
end

function A:SetActive(active)
	active = active == true and lib.isEditing and not self:InCombat()
	if active == self.active then return end
	if not active then
		local interrupted = self.dragging and self.byFrame[self.dragging]
		local dragUndo = self.ui.dragUndo
		if self.dragging and (not self:InCombat() or not self.dragging:IsProtected()) then self.dragging:StopMovingOrSizing() end
		if lib.internal.CancelSelectionDrag then lib.internal:CancelSelectionDrag() end
		self.dragging, self.active, self.picking, self.selected, self.undo = nil, false, nil, nil, nil
		self.ui.dragUndo, self.ui.targets = nil, {}
		if interrupted then
			if dragUndo and self:IsContextCurrent(dragUndo.context) and not self:InCombat() then
				self.undo = dragUndo
				self:Undo()
			else
				self:QueueLayoutRestore(interrupted)
				self:Queue(interrupted.id)
				D:QueueConsumer(self:Consumer(interrupted), "ANCHOR_EDITOR")
			end
		end
		for _, overlay in pairs(self.ui.overlays) do overlay:Hide(); overlay:EnableMouse(false); overlay.entry = nil end
		if self.ui.window then self.ui.window:Hide() end
		for _, line in pairs(self.ui.lines or {}) do line:Hide() end
	else
		self.active, self.ui.db, self.ui.message = true, addon.db, nil
		self.ui.context = self:CaptureContext()
		self:Discover()
		lib:HideSettingsDialog()
		self:HideDefaultDialog()
		self:RefreshUI()
	end
	lib:RefreshAnchorModeButton()
end

lib:ConfigureAnchorMode({
	label = "A",
	icon = "Interface\\AddOns\\EnhanceQoL\\Icons\\AnchorMode.tga",
	title = L["EditModeAnchorTitle"],
	tooltip = L["EditModeAnchorDescription"],
	isActive = function() return A.active == true end,
	toggle = function() A:SetActive(not A.active) end,
	select = function(frame) return A:SelectFrame(frame) end,
	canDrag = function(frame) return A:CanDrag(frame) end,
	dragStart = function(frame) A:DragStart(frame) end,
	dragStop = function(frame) return A:DragStop(frame) end,
})
lib:RegisterCallback("exit", function() A:SetActive(false) end)
lib:RegisterCallback("context", function() A:SetActive(false) end)
