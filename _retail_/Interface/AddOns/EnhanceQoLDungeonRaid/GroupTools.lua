local _, addon = ...
if _G.EnhanceQoL then addon = _G.EnhanceQoL else error("EnhanceQoL is not loaded") end
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local M = addon.GroupTools or {}
M.id = "GroupTools"
M.buttons = {}
M.defaults = {
	enabled = false, design = "blizzard", scale = 1, iconSize = 24, spacing = 4,
	backgroundAlpha = 0.95, border = true, locked = false, groupOnly = true, leaderOnly = false,
	showTargets = true, showWorld = true, showDisband = false, animation = true,
	countdown1 = 3, countdown2 = 5, countdown3 = 10, collapsed = false, collapseMode = "top", collapseIconID = 0, collapseIconAnchor = "TOPLEFT", expandOnHover = false,
}
M.iconAnchors = {
	{ "TOPLEFT", "Top Left" }, { "TOP", "Top" }, { "TOPRIGHT", "Top Right" },
	{ "LEFT", "Left" }, { "CENTER", "Center" }, { "RIGHT", "Right" },
	{ "BOTTOMLEFT", "Bottom Left" }, { "BOTTOM", "Bottom" }, { "BOTTOMRIGHT", "Bottom Right" },
}
addon.GroupTools = M

function M.Options()
	addon.db.groupTools = addon.db.groupTools or {}
	if addon.functions.CleanupGroupToolsProfile then addon.functions.CleanupGroupToolsProfile(addon.db) end
	for key, value in pairs(M.defaults) do
		if addon.db.groupTools[key] == nil then addon.db.groupTools[key] = value end
	end
	return addon.db.groupTools
end

function M.CanLead()
	return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
end

function M.CanManage()
	return IsInGroup() and UnitIsGroupLeader("player") and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
end

function M.CanRestrictPings()
	return C_Ping and C_Ping.IsPingSystemEnabled and C_Ping.IsPingSystemEnabled()
		and C_PartyInfo and C_PartyInfo.GetRestrictPings and C_PartyInfo.SetRestrictPings
		and Enum and Enum.RestrictPingsTo
end

function M.CanLeaveInstance()
	return _G.PartyUtil and _G.PartyUtil.CanLeaveInstance and _G.PartyUtil.CanLeaveInstance() and _G.ConfirmOrLeaveParty ~= nil
end

function M.LeaveParty()
	if not IsInGroup() then return end
	if C_PartyInfo.IsPartyWalkIn and C_PartyInfo.IsPartyWalkIn() and _G.LeaveWalkInParty then
		_G.LeaveWalkInParty()
	else
		C_PartyInfo.LeaveParty()
	end
end

function M.Tooltip(button, text)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(type(text) == "function" and text() or text)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function M.Button(parent, label, attributes, callback, allowCombat)
	local button = CreateFrame("Button", nil, parent, attributes and "SecureActionButtonTemplate,BackdropTemplate" or "BackdropTemplate")
	button:SetNormalFontObject(GameFontNormalSmall)
	button:SetHighlightFontObject(GameFontHighlightSmall)
	button:SetDisabledFontObject(GameFontDisableSmall)
	button.label = label or ""
	button:SetText(button.label)
	button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
	if attributes then
		button:RegisterForClicks("AnyDown", "AnyUp")
		for key, value in pairs(attributes) do button:SetAttribute(key, value) end
	else
		button:SetScript("OnClick", function() if allowCombat or not InCombatLockdown() then callback() end end)
	end
	M.buttons[#M.buttons + 1] = button
	return button
end

function M.Disband()
	if InCombatLockdown() or not M.CanManage() then return end
	local members = {}
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local unit = "raid" .. i
			if not UnitIsUnit(unit, "player") then members[#members + 1] = { unit = unit, guid = UnitGUID(unit) } end
		end
	else
		for i = 1, GetNumSubgroupMembers() do
			local unit = "party" .. i
			members[#members + 1] = { unit = unit, guid = UnitGUID(unit) }
		end
	end
	StaticPopup_Show("EQOL_GROUP_TOOLS_DISBAND", nil, nil, members)
end

StaticPopupDialogs.EQOL_GROUP_TOOLS_DISBAND = {
	text = L["groupToolsDisbandConfirm"], button1 = YES, button2 = NO,
	timeout = 0, whileDead = true, hideOnEscape = true,
	OnAccept = function(_, members)
		if InCombatLockdown() or not M.CanManage() then return end
		-- Confirm only the roster shown when the dialog opened.
		for _, member in ipairs(members or {}) do
			if UnitGUID(member.unit) ~= member.guid then return end
		end
		if #(members or {}) ~= GetNumGroupMembers() - 1 then return end
		local names = {}
		for _, member in ipairs(members) do names[#names + 1] = GetUnitName(member.unit, true) end
		local uninvite = C_PartyInfo and C_PartyInfo.UninviteUnit or _G.UninviteUnit
		if uninvite then for _, name in ipairs(names) do uninvite(name, nil, true) end end
	end,
}

function M.CollapseBounds(mode, width, height, iconAnchor)
	if mode == "bottom" then return "BOTTOMLEFT", width, 28 end
	if mode == "left" then return "TOPLEFT", 28, height end
	if mode == "right" then return "TOPRIGHT", 28, height end
	if mode == "symbol" then
		for _, entry in ipairs(M.iconAnchors) do
			if entry[1] == iconAnchor then return iconAnchor, 32, 32 end
		end
		return "TOPLEFT", 32, 32
	end
	return "TOPLEFT", width, 28
end

function M.ApplyCollapse(width, height, collapsed)
	local frame, opts = M.frame, M.Options()
	local point, w, h = M.CollapseBounds(opts.collapseMode, width, height, opts.collapseIconAnchor)
	frame.background:ClearAllPoints()
	frame.background:SetPoint(point, frame, point, 0, 0)
	frame.background:SetSize(collapsed and w or width, collapsed and h or height)
	frame.header:ClearAllPoints()
	frame.header:SetPoint(collapsed and point or "TOPLEFT", frame, collapsed and point or "TOPLEFT", 0, 0)
	frame.header:SetSize(collapsed and w or width, collapsed and h or 28)
	frame.title:SetShown(not collapsed or opts.collapseMode == "top" or opts.collapseMode == "bottom")
	frame.toggle:ClearAllPoints()
	if collapsed and opts.collapseMode ~= "top" and opts.collapseMode ~= "bottom" then
		frame.toggle:SetPoint("CENTER", frame.header, "CENTER", 0, 0)
	else
		frame.toggle:SetPoint("RIGHT", frame.header, "RIGHT", -5, 0)
	end
	if collapsed and opts.collapseMode == "symbol" then
		for _, state in ipairs({ "Normal", "Pushed", "Disabled", "Highlight" }) do
			local texture = frame.toggle["Get" .. state .. "Texture"](frame.toggle)
			if texture then texture:SetTexture(nil) end
		end
		frame.toggle:SetText("")
		frame.toggle:SetSize(24, 24)
		frame.toggle:SetNormalTexture(opts.collapseIconID > 0 and opts.collapseIconID or "Interface\\AddOns\\EnhanceQoL\\Icons\\Icon.tga")
		frame.toggle:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
	end
end

function M.UpdateHover(frame, elapsed)
	M.hoverElapsed = (M.hoverElapsed or 0) + elapsed
	if M.hoverElapsed < 0.05 then return end
	M.hoverElapsed = 0
	if InCombatLockdown() or M.preview or M.animating or M.dragging then return end
	if M.hoverSuppressed then
		if not frame:IsMouseOver() and not frame.toggle:IsMouseOver() then M.hoverSuppressed = nil end
		return
	end
	local over = frame.background:IsMouseOver() or frame.toggle:IsMouseOver()
	if M.hoverExpanded and frame.pings:IsMenuOpen() then over = true end
	if over ~= (M.hoverExpanded == true) then M.Toggle(true) end
end

function M.Toggle(hover)
	if InCombatLockdown() or M.animating then return end
	local opts = M.Options()
	if hover then
		M.hoverExpanded = not M.hoverExpanded
	else
		opts.collapsed = M.hoverExpanded or not opts.collapsed
		M.hoverExpanded = nil
		M.hoverSuppressed = opts.collapsed and opts.expandOnHover or nil
	end
	M.Refresh()
	if not opts.animation then return end
	M.animating = true
	local frame = M.frame
	local width, height = frame:GetWidth(), M.fullHeight
	local point, smallWidth, smallHeight = M.CollapseBounds(opts.collapseMode, width, height, opts.collapseIconAnchor)
	local collapsing = opts.collapsed and not M.hoverExpanded
	frame.background:Hide()
	frame.reveal:ClearAllPoints()
	frame.reveal:SetPoint(point, frame, point, 0, 0)
	frame.reveal:SetWidth(collapsing and width or smallWidth)
	frame.reveal:SetHeight(collapsing and height or smallHeight)
	frame.reveal:SetAlpha(1)
	frame.reveal:Show()
	if not collapsing then frame.fade:Play() end
	local elapsedTime = 0
	-- Only the decorative panel animates; secure buttons keep their final geometry.
	frame.reveal:SetScript("OnUpdate", function(self, elapsed)
		elapsedTime = elapsedTime + elapsed
		local progress = math.min(1, elapsedTime / 0.16)
		local fraction = collapsing and (1 - progress) or progress
		self:SetWidth(smallWidth + (width - smallWidth) * fraction)
		self:SetHeight(smallHeight + (height - smallHeight) * fraction)
		if progress == 1 then
			self:SetScript("OnUpdate", nil)
			self:Hide()
			M.animating = false
			frame.background:Show()
			M.Refresh()
		end
	end)
end

function M.Create()
	if M.frame then return end
	local frame = CreateFrame("Frame", "EQOLGroupTools", UIParent, "SecureHandlerStateTemplate,BackdropTemplate")
	M.frame = frame
	frame:SetPoint("CENTER", UIParent, "CENTER", -350, 0)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:SetFrameStrata("MEDIUM")
	frame.background = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.background:SetPoint("TOPLEFT")
	frame.background:SetFrameLevel(frame:GetFrameLevel())
	frame.header = CreateFrame("Frame", nil, frame)
	frame.header:SetPoint("TOPLEFT")
	frame.header:SetPoint("TOPRIGHT")
	frame.header:SetHeight(28)
	frame.header.shade = frame.header:CreateTexture(nil, "BACKGROUND")
	frame.header.shade:SetPoint("TOPLEFT", 1, -1)
	frame.header.shade:SetPoint("BOTTOMRIGHT", -1, 1)
	frame.header.shade:SetColorTexture(0, 0, 0, 1)
	frame.header:EnableMouse(true)
	frame.header:RegisterForDrag("LeftButton")
	frame.header:SetScript("OnDragStart", function()
		if not InCombatLockdown() and not M.Options().locked and not M.preview and not M.animating then
			M.dragging = true
			frame:SetMovable(true)
			frame:StartMoving()
		end
	end)
	frame.header:SetScript("OnDragStop", function()
		M.dragging = nil
		if InCombatLockdown() then return end
		frame:StopMovingOrSizing()
		local point, _, relativePoint, x, y = frame:GetPoint()
		addon.EditMode:SetFramePosition(M.id, point, x, y, nil, false, relativePoint)
	end)
	frame.title = frame.header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.title:SetPoint("LEFT", 10, 0)
	frame.title:SetText(L["groupToolsTitle"])
	frame.toggle = M.Button(frame.header, "−", nil, M.Toggle)
	frame.toggle:SetPoint("RIGHT", -5, 0)
	frame.toggle:SetSize(22, 22)
	frame.toggle:RegisterForDrag("LeftButton")
	frame.toggle:SetScript("OnDragStart", frame.header:GetScript("OnDragStart"))
	frame.toggle:SetScript("OnDragStop", frame.header:GetScript("OnDragStop"))
	M.Tooltip(frame.toggle, L["groupToolsToggle"])
	frame.content = CreateFrame("Frame", nil, frame)
	frame.content:SetPoint("TOPLEFT", 10, -32)
	frame.fade = frame.content:CreateAnimationGroup()
	local fade = frame.fade:CreateAnimation("Alpha")
	fade:SetFromAlpha(0)
	fade:SetToAlpha(1)
	fade:SetDuration(0.16)
	frame.reveal = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	frame.reveal:SetFrameStrata("MEDIUM")
	frame.reveal:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -28)
	frame.reveal:Hide()
	local actions = addon.MarkBarActions
	M.ready = M.Button(frame.content, READY_CHECK, actions.ReadyCheck())
	M.ready.toolbarAtlas = "GM-icon-readyCheck"
	M.Tooltip(M.ready, READY_CHECK)
	M.role = M.Button(frame.content, _G.CRF_ROLE_POLL or L["groupToolsRolePoll"], nil, function()
		if M.CanLead() and InitiateRolePoll then InitiateRolePoll() end
	end)
	M.role.toolbarAtlas = "GM-icon-roles"
	M.Tooltip(M.role, _G.CRF_ROLE_POLL or L["groupToolsRolePoll"])
	M.convert = M.Button(frame.content, CONVERT_TO_RAID, nil, function()
		if not M.CanManage() then return end
		if IsInRaid() then
			if GetNumGroupMembers() <= 5 and C_PartyInfo.ConvertToParty then C_PartyInfo.ConvertToParty() end
		elseif C_PartyInfo.ConvertToRaid then C_PartyInfo.ConvertToRaid() end
	end)
	M.disband = M.Button(frame.content, L["groupToolsDisband"], nil, M.Disband)
	M.countdowns = {}
	for i = 1, 3 do M.countdowns[i] = M.Button(frame.content, "", actions.Countdown(M.Options()["countdown" .. i])) end
	M.stop = M.Button(frame.content, _G.STOP or CANCEL, actions.Countdown(0))
	M.leaveParty = M.Button(frame.content, PARTY_LEAVE, nil, M.LeaveParty, true)
	M.leaveInstance = M.Button(frame.content, INSTANCE_PARTY_LEAVE, nil, function()
		if M.CanLeaveInstance() then _G.ConfirmOrLeaveParty() end
	end, true)
	frame.pingLabel = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.pingLabel:SetText(_G.RAID_MANAGER_RESTRICT_PINGS_TO or L["groupToolsPings"])
	frame.pings = CreateFrame("DropdownButton", nil, frame.content, "WowStyle1DropdownTemplate")
	frame.pings:SetupMenu(function(_, root)
		if not M.CanRestrictPings() then return end
		local options = {
			{ NONE, Enum.RestrictPingsTo.None },
			{ _G.RAID_MANAGER_RESTRICT_PINGS_TO_LEAD, Enum.RestrictPingsTo.Lead },
			{ _G.RAID_MANAGER_RESTRICT_PINGS_TO_ASSIST, Enum.RestrictPingsTo.Assist },
			{ _G.RAID_MANAGER_RESTRICT_PINGS_TO_TANKS_HEALERS, Enum.RestrictPingsTo.TankHealer },
		}
		for _, option in ipairs(options) do
			local entry = root:CreateRadio(option[1], function() return C_PartyInfo.GetRestrictPings() == option[2] end, function()
				if InCombatLockdown() or not UnitIsGroupLeader("player") or not M.CanRestrictPings() then return end
				C_PartyInfo.SetRestrictPings(option[2])
			end)
			entry:SetEnabled(UnitIsGroupLeader("player"))
		end
	end)
	M.rows = {}
	for _, kind in ipairs({ "targets", "world" }) do
		local row = { buttons = {}, label = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") }
		row.label:SetText(L[kind == "targets" and "groupToolsUnit" or "groupToolsGround"])
		local order = { 5, 6, 3, 2, 7, 1, 4, 8 }
		for index = 1, 9 do
			local attributes = kind == "targets" and actions.Target(index == 9 and 0 or index) or actions.World(order[index])
			local button = M.Button(frame.content, "", attributes)
			button.markerIndex = index
			button.markerKind = kind
			button.icon = button:CreateTexture(nil, "ARTWORK")
			button.icon:SetPoint("TOPLEFT", 2, -2)
			button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
			if index == 9 then button.icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
			else button.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. index) end
			M.Tooltip(button, index == 9 and REMOVE or _G["RAID_TARGET_" .. index])
			row.buttons[index] = button
		end
			M.rows[kind] = row
	end
	addon.EditMode:RegisterFrame(M.id, {
		frame = frame, title = L["groupToolsTitle"], managerCategory = "dungeonRaid",
		layoutDefaults = { point = "CENTER", relativePoint = "CENTER", x = -350, y = 0 },
		isEnabled = function() return M.Options().enabled end,
		manageVisibilityOutsideEditMode = false, showOutsideEditMode = true,
		allowDrag = function() return not InCombatLockdown() end,
		settings = M.Settings(), settingsFactoryDefaults = M.defaults,
		settingsNavigation = {
			direct = true, categories = { { id = "tools", name = L["groupToolsTitle"], groups = { "__general" } } },
			splitGroups = { __general = function(data)
				local field = data.navigationField
				if field == "x" or field == "y" or field == "locked" or field == "collapseMode" or field == "collapseIconID" or field == "collapseIconAnchor" or field == "expandOnHover" then return "position", L["Position"] end
				if field == "groupOnly" or field == "leaderOnly" then return "visibility", L["Visibility"] end
				if field == "showTargets" or field == "showWorld" or field == "showDisband" or (field and field:match("^countdown")) then return "actions", L["General"] end
				return "appearance", L["QuickCastCopyAppearance"]
			end },
		},
		onApply = function() M.Refresh() end,
		onEnter = function() M.preview = true; M.Refresh() end,
		onExit = function() M.preview = false; M.Refresh() end,
	})
end

function M.HasAtlas(atlas)
	return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) ~= nil
end

function M.ButtonAtlas(button, state, atlas)
	button.groupStateTextures = button.groupStateTextures or {}
	local texture = button.groupStateTextures[state]
	if not texture then
		texture = button:CreateTexture(nil, "ARTWORK")
		button.groupStateTextures[state] = texture
	end
	texture:SetAtlas(atlas)
	texture:SetAllPoints()
	texture:SetDrawLayer(button.markerIndex and "BACKGROUND" or "ARTWORK")
	button["Set" .. state .. "Texture"](button, texture)
	-- Button setters can assign their own layer; marker artwork must remain above it.
	if button.markerIndex then texture:SetDrawLayer("BACKGROUND", state == "Normal" and 0 or 1) end
end

function M.Skin(frame, design, opacity, border)
	frame:SetBackdrop({
		bgFile = design == "blizzard" and "Interface\\FrameGeneral\\UI-Background-Rock" or "Interface\\Buttons\\WHITE8x8",
		edgeFile = border and "Interface\\Buttons\\WHITE8x8" or nil,
		tile = design == "blizzard", tileSize = 32, edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	frame:SetBackdropColor(design == "blizzard" and 0.65 or 0.06, design == "blizzard" and 0.65 or 0.06, design == "blizzard" and 0.65 or 0.06, opacity)
	frame:SetBackdropBorderColor(0.35, 0.35, 0.35, border and 1 or 0)
end

function M.SkinButton(button, design, border, collapsed)
	for _, state in ipairs({ "Normal", "Pushed", "Disabled", "Highlight" }) do
		local texture = button["Get" .. state .. "Texture"](button)
		if texture then texture:SetTexture(nil) end
	end
	button:SetBackdrop(nil)
	if button.toolbarAtlas then button:SetText(button.label) end
	if button == M.frame.toggle then
		button:SetText(collapsed and "+" or "−")
		button:SetSize(20, 20)
		local mode = M.Options().collapseMode
		if not collapsed or mode == "top" or mode == "bottom" or mode == "symbol" then
			-- Side tabs do not fit inside a horizontal title bar.
			M.Skin(button, "simple", 0.8, true)
			button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
			return
		end
	end
	if button.icon then
		button.icon:SetTexture(button.markerIndex == 9 and "Interface\\Buttons\\UI-GroupLoot-Pass-Up" or "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. button.markerIndex)
		button.icon:ClearAllPoints()
		button.icon:SetPoint("CENTER", 0, 1)
		button.icon:SetSize(M.Options().iconSize, M.Options().iconSize)
	end
	if design == "blizzard" then
		local normal, pushed, disabled, hover
		if button == M.frame.toggle then
			local forward = collapsed
			if M.Options().collapseMode == "right" then forward = not forward end
			local prefix = forward and "gm-btnforward-" or "gm-btnback-"
			normal, pushed, disabled, hover = prefix .. "normal", prefix .. "pressed", prefix .. "disabled", prefix .. "hover"
		elseif button.markerIndex then
			normal, pushed, disabled, hover = "GM-button-marker-available", "GM-button-marker-pressed", "GM-button-marker-disabled", "GM-button-marker-hover"
		elseif button.toolbarAtlas then
			normal, pushed, hover = button.toolbarAtlas, button.toolbarAtlas .. "-pressed", button.toolbarAtlas .. "-hover"
		else
			normal, pushed, disabled, hover = "common-button-tertiary-normal", "common-button-tertiary-pressed", "common-button-tertiary-disabled", "common-button-tertiary-hover"
		end
		if M.HasAtlas(normal) then
			M.ButtonAtlas(button, "Normal", normal)
			for state, atlas in pairs({ Pushed = pushed, Disabled = disabled, Highlight = hover }) do
				if M.HasAtlas(atlas) then M.ButtonAtlas(button, state, atlas) end
			end
			if button.toolbarAtlas or button == M.frame.toggle then button:SetText("") end
			if button == M.frame.toggle then button:SetSize(16, 28) end
			if button.markerIndex then
				local atlas = button.markerIndex == 9 and (button.markerKind == "world" and "GM-raidMarker-reset" or "GM-raidMarker-remove") or "GM-raidMarker" .. (9 - button.markerIndex)
				if M.HasAtlas(atlas) then button.icon:SetAtlas(atlas) end
			end
			return
		end
	end
	-- Clients without the group-manager atlases still get neutral controls.
	if not button.markerIndex then M.Skin(button, design == "blizzard" and "simple" or design, 0.7, border) end
	button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
end

function M.Refresh()
	if not addon.db then return end
	if InCombatLockdown() then M.pending = true; return end
	local opts = M.Options()
	if not M.frame then
		if not opts.enabled then return end
		M.Create()
	end
	local frame = M.frame
	local native = opts.design == "blizzard"
	local columns = native and 5 or 9
	local markerSize = opts.iconSize + (native and 12 or 4)
	local width = math.max(native and 222 or 280, markerSize * columns + opts.spacing * (columns - 1) + 20)
	local inner = width - 20
	local contentTop = native and 48 or 32
	frame.content:ClearAllPoints()
	frame.content:SetPoint("TOPLEFT", 10, -contentTop)
	frame:SetScale(opts.scale)
	frame.content:SetWidth(inner)
	local function place(button, x, y, w, h, shown)
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", frame.content, "TOPLEFT", x, -y)
		button:SetSize(w, h)
		button:SetShown(shown ~= false)
	end
	local half = (inner - 4) / 2
	local toolbarHeight = native and 40 or 25
	place(M.ready, native and (half - 40) / 2 or 0, 0, native and 40 or half, toolbarHeight)
	place(M.role, native and (half + 4 + (half - 40) / 2) or (half + 4), 0, native and 40 or half, toolbarHeight)
	M.role:SetEnabled(M.CanLead() and InitiateRolePoll ~= nil)
	place(M.convert, 0, toolbarHeight + 4, opts.showDisband and half or inner, 25)
	M.convert:SetText(IsInRaid() and CONVERT_TO_PARTY or CONVERT_TO_RAID)
	M.convert:SetEnabled(M.CanManage() and (not IsInRaid() or GetNumGroupMembers() <= 5))
	place(M.disband, half + 4, toolbarHeight + 4, half, 25, opts.showDisband)
	M.disband:SetEnabled(M.CanManage())
	for i, button in ipairs(M.countdowns) do
		local seconds = opts["countdown" .. i]
		button:SetText(tostring(seconds))
		button:SetAttribute("macrotext", addon.MarkBarActions.Countdown(seconds).macrotext)
		place(button, (i - 1) * (inner + 4) / 4, toolbarHeight + 33, (inner - 12) / 4, 25)
	end
	place(M.stop, 3 * (inner + 4) / 4, toolbarHeight + 33, (inner - 12) / 4, 25)
	local y = toolbarHeight + 66
	for _, kind in ipairs({ "targets", "world" }) do
		local row = M.rows[kind]
		local shown = opts[kind == "targets" and "showTargets" or "showWorld"]
		row.label:SetShown(shown)
		row.label:ClearAllPoints()
		row.label:SetPoint("TOPLEFT", 0, -y)
		for i, button in ipairs(row.buttons) do
			place(button, ((i - 1) % columns) * (markerSize + opts.spacing), y + 17 + math.floor((i - 1) / columns) * (markerSize + opts.spacing), markerSize, markerSize, shown)
		end
		if shown then y = y + math.ceil(9 / columns) * (markerSize + opts.spacing) + 26 end
	end
	frame.header:SetHeight(28)
	local pingAvailable = M.CanRestrictPings() and UnitIsGroupLeader("player")
	frame.pingLabel:SetShown(pingAvailable)
	frame.pings:SetShown(pingAvailable)
	if pingAvailable then
		frame.pingLabel:ClearAllPoints()
		frame.pingLabel:SetPoint("TOPLEFT", 17, -y)
		frame.pings:ClearAllPoints()
		frame.pings:SetPoint("TOPLEFT", 17, -y - 17)
		frame.pings:SetWidth(inner - 34)
		frame.pings:GenerateMenu()
		y = y + 48
	end
	place(M.leaveParty, 17, y, inner - 34, 25)
	M.leaveParty:SetEnabled(IsInGroup())
	place(M.leaveInstance, 17, y + 30, inner - 34, 25)
	M.leaveInstance:SetEnabled(M.CanLeaveInstance() == true)
	M.leaveInstance:SetText(C_PartyInfo.IsPartyWalkIn and C_PartyInfo.IsPartyWalkIn() and _G.INSTANCE_WALK_IN_LEAVE or INSTANCE_PARTY_LEAVE)
	y = y + 55
	M.fullHeight = y + contentTop + 8
	if not opts.expandOnHover or not opts.collapsed or M.preview or not opts.enabled then
		M.hoverExpanded, M.hoverSuppressed = nil, nil
	end
	frame:SetScript("OnUpdate", opts.enabled and opts.expandOnHover and opts.collapsed and not M.preview and M.UpdateHover or nil)
	local collapsed = opts.collapsed and not M.preview and not M.hoverExpanded
	frame:SetSize(width, M.fullHeight)
	frame.content:SetHeight(M.fullHeight - contentTop)
	frame.content:SetShown(not collapsed)
	frame.header.shade:SetShown(native)
	frame.header.shade:SetAlpha(opts.backgroundAlpha * 0.85)
	M.Skin(frame.background, opts.design, opts.backgroundAlpha, opts.border)
	frame.reveal:SetWidth(width)
	frame.reveal:SetScale(opts.scale)
	M.Skin(frame.reveal, opts.design, opts.backgroundAlpha, opts.border)
	for _, button in ipairs(M.buttons) do M.SkinButton(button, opts.design, opts.border, collapsed) end
	M.ApplyCollapse(width, M.fullHeight, collapsed)
	local visible = opts.enabled and (M.preview or not opts.leaderOnly or M.CanLead())
	local driver = not visible and "hide" or (M.preview or not opts.groupOnly) and "show" or "[group] show; hide"
	RegisterStateDriver(frame, "visibility", driver)
	M.pending = nil
end

function M.Settings()
	local types = addon.EditMode.lib.SettingType
	local settings = {}
	local function add(key, label, kind, extra)
		local data = { name = label, kind = kind, field = key, navigationField = key,
			default = M.defaults[key], navigationDefaultVerified = true,
			get = function() return M.Options()[key] end,
			set = function(_, value) M.Options()[key] = value; M.Refresh() end,
			isEnabled = function() return not InCombatLockdown() end,
		}
		for k, v in pairs(extra or {}) do data[k] = v end
		settings[#settings + 1] = data
	end
	add("design", L["groupToolsDesign"], types.Dropdown, { generator = function(_, root)
		for _, key in ipairs({ "blizzard", "simple" }) do
			root:CreateRadio(L["groupToolsDesign_" .. key], function() return M.Options().design == key end, function() M.Options().design = key; M.Refresh() end)
		end
	end })
	add("collapseMode", L["groupToolsCollapseMode"], types.Dropdown, { generator = function(_, root)
		for _, mode in ipairs({ "top", "bottom", "left", "right", "symbol" }) do
			root:CreateRadio(L["groupToolsCollapse_" .. mode], function() return M.Options().collapseMode == mode end, function()
				if InCombatLockdown() or M.animating then return end
				M.Options().collapseMode = mode
				M.Refresh()
				addon.EditMode.lib.internal:RequestRefreshSettings()
			end)
		end
	end })
	add("collapseIconAnchor", L["groupToolsCollapseIconAnchor"], types.Dropdown, {
		isShown = function() return M.Options().collapseMode == "symbol" end,
		navigationHint = function() return L["groupToolsCollapseMode"], nil, "position" end,
		isEnabled = function() return not InCombatLockdown() and not M.animating and M.Options().collapseMode == "symbol" end,
		generator = function(_, root)
			for _, entry in ipairs(M.iconAnchors) do
				local point = entry[1]
				root:CreateRadio(L[entry[2]], function() return M.Options().collapseIconAnchor == point end, function()
					if InCombatLockdown() or M.animating then return end
					M.Options().collapseIconAnchor = point
					M.Refresh()
				end)
			end
		end,
	})
	add("expandOnHover", L["groupToolsExpandOnHover"], types.Checkbox)
	add("collapseIconID", L["groupToolsCollapseIconID"], types.Input, {
		isShown = function() return M.Options().collapseMode == "symbol" end,
		navigationHint = function() return L["groupToolsCollapseMode"], nil, "position" end,
		maxChars = 10,
		get = function() return tostring(M.Options().collapseIconID) end,
		isEnabled = function() return not InCombatLockdown() and M.Options().collapseMode == "symbol" end,
		set = function(_, value)
			if InCombatLockdown() then return end
			local id = tonumber(value)
			if not id or id < 0 or id > 4294967295 or id ~= math.floor(id) then return end
			M.Options().collapseIconID = id
			M.Refresh()
		end,
	})
	for _, row in ipairs({ { "scale", "Scale", 0.5, 2, 0.05 }, { "iconSize", "Icon size", 16, 40, 1 }, { "spacing", "Spacing", 0, 12, 1 }, { "backgroundAlpha", "settingsFrameBackgroundOpacityLabel", 0, 1, 0.05 }, { "countdown1", "groupToolsCountdown1", 1, 60, 1 }, { "countdown2", "groupToolsCountdown2", 1, 60, 1 }, { "countdown3", "groupToolsCountdown3", 1, 60, 1 } }) do
		add(row[1], L[row[2]], types.Slider, { minValue = row[3], maxValue = row[4], valueStep = row[5], allowInput = true,
			formatter = row[5] < 1 and function(value) return string.format("%.2f", value) end or nil,
		})
	end
	for _, row in ipairs({ { "border", "groupToolsBorder" }, { "animation", "groupToolsAnimation" }, { "locked", "groupToolsLocked" }, { "groupOnly", "groupToolsGroupOnly" }, { "leaderOnly", "groupToolsLeaderOnly" }, { "showTargets", "groupToolsUnit" }, { "showWorld", "groupToolsGround" }, { "showDisband", "groupToolsShowDisband" } }) do add(row[1], L[row[2]], types.Checkbox) end
	for _, field in ipairs({ "x", "y" }) do
		local fallback = field == "x" and -350 or 0
		add(field, L[field == "x" and "Offset X" or "Offset Y"], types.Slider, {
			default = fallback, minValue = -4000, maxValue = 4000, valueStep = 1, allowInput = true,
			get = function() return addon.EditMode:GetValue(M.id, field) or fallback end,
			set = function(_, value) addon.EditMode:SetValue(M.id, field, value) end,
			navigationReset = field == "x" and function()
				addon.EditMode:SetValue(M.id, "point", "CENTER", nil, true)
				addon.EditMode:SetValue(M.id, "relativePoint", "CENTER", nil, true)
				addon.EditMode:SetValue(M.id, "x", -350, nil, true)
				addon.EditMode:SetValue(M.id, "y", 0)
			end or nil,
		})
	end
	return settings
end

function M.Initialize()
	if not addon.db or not addon.EditMode or not addon.MarkBarActions then return end
	M.Options()
	if not M.settingsBuilt and addon.SettingsLayout and addon.SettingsLayout.rootGAMEPLAY then
		local section = addon.functions.SettingsCreateExpandableSection(nil, {
			name = L["groupToolsTitle"], configPageKey = "GroupTools", description = L["groupToolsDesc"],
			iconKey = "dungeons", modernCategory = "gameplay", modernOnly = true,
			expanded = false, colorizeTitle = false,
		})
		addon.functions.SettingsCreateCheckbox(nil, {
			var = "groupToolsEnabled", newTagID = "groupToolsEnabled", default = false, text = L["groupToolsEnable"], desc = L["groupToolsDesc"],
			get = function() return M.Options().enabled end,
			func = function(value) M.Options().enabled = value; M.Refresh() end,
			parentSection = section,
		})
		addon.functions.SettingsCreateText(nil, "|cff99e599" .. L["groupToolsDesc"] .. "|r", { parentSection = section })
		M.settingsBuilt = true
	end
	M.Refresh()
end

M.events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED", "PLAYER_REGEN_ENABLED" }) do M.events:RegisterEvent(event) end
M.events:SetScript("OnEvent", M.Initialize)
C_Timer.After(0, M.Initialize)
