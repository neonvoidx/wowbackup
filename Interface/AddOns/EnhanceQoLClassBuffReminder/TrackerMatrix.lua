local parentAddonName = "EnhanceQoL"
local _, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local Reminder = addon.ClassBuffReminder
if not (Reminder and Reminder.settingsSection) then return end

local MATRIX_ID = "ClassBuffReminderTrackerMatrix"
local DB = {
	FLASKS = "classBuffReminderTrackFlasks",
	FOOD = "classBuffReminderTrackFood",
	RUNES = "classBuffReminderTrackRunes",
	WEAPON_BUFFS = "classBuffReminderTrackWeaponBuffs",
	PETS = "classBuffReminderTrackPets",
	HEALTHSTONES = "classBuffReminderTrackHealthstones",
	STANCES = "classBuffReminderTrackStances",
}

local CONTENT_SHORT_LABELS = {
	openWorld = "W",
	scenario = "S",
	partyFollower = "FD",
	partyNormal = "N",
	partyHeroic = "H",
	partyMythic = "M",
	partyMythicPlus = "M+",
	raidLfr = "LFR",
	raidNormal = "RN",
	raidHeroic = "RH",
	raidMythic = "RM",
}

local function refreshReminder()
	if Reminder.OnSettingChanged then Reminder:OnSettingChanged() end
end

local function getSelection(method)
	if method and Reminder[method] then return Reminder[method](Reminder) end
	return {}
end

local function setSelection(method, selection)
	if method and Reminder[method] then Reminder[method](Reminder, selection) end
end

local function buildRows()
	local rows = {
		{
			label = L["ClassBuffReminderSectionFlasks"] or "Flasks",
			enabledDb = DB.FLASKS,
			getter = "GetFlaskTrackingContentSelection",
			setter = "SetFlaskTrackingContentSelection",
			invalidate = "InvalidateFlaskCache",
		},
		{
			label = L["ClassBuffReminderSectionFood"] or "Food",
			enabledDb = DB.FOOD,
			getter = "GetFoodTrackingContentSelection",
			setter = "SetFoodTrackingContentSelection",
			invalidate = "InvalidateFoodCache",
		},
		{
			label = L["ClassBuffReminderSectionRunes"] or "Augment Runes",
			enabledDb = DB.RUNES,
			getter = "GetRuneTrackingContentSelection",
			setter = "SetRuneTrackingContentSelection",
			invalidate = "InvalidateRuneCache",
		},
		{
			label = L["ClassBuffReminderSectionWeaponBuffs"] or "Weapon Buffs",
			enabledDb = DB.WEAPON_BUFFS,
			getter = "GetWeaponBuffTrackingContentSelection",
			setter = "SetWeaponBuffTrackingContentSelection",
			invalidate = "InvalidateWeaponBuffCache",
		},
		{
			label = L["CooldownPanelStanceType"] or _G.STANCE or "Stance",
			enabledDb = DB.STANCES,
			getter = "GetStanceTrackingContentSelection",
			setter = "SetStanceTrackingContentSelection",
		},
		{
			label = L["ClassBuffReminderSectionPets"] or "Pets",
			enabledDb = DB.PETS,
			getter = "GetPetTrackingContentSelection",
			setter = "SetPetTrackingContentSelection",
		},
	}
	if Reminder:GetClassToken() == "WARLOCK" then
		rows[#rows + 1] = {
			label = L["ClassBuffReminderHealthstone"] or "Healthstone",
			enabledDb = DB.HEALTHSTONES,
			getter = "GetHealthstoneTrackingContentSelection",
			setter = "SetHealthstoneTrackingContentSelection",
		}
	end
	return rows
end

local function showTooltip(owner, title, description)
	if not GameTooltip then return end
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:AddLine(title or "", 1, 0.82, 0)
	if description and description ~= "" then GameTooltip:AddLine(description, 1, 1, 1, true) end
	GameTooltip:Show()
end

local function renderMatrix(parent, state)
	if not parent then return nil end
	local rows = buildRows()
	local content = Reminder:GetTrackingContentOptions()
	local handle = { frames = {}, checks = {} }
	local enabledOffset = -354
	local function track(frame)
		handle.frames[#handle.frames + 1] = frame
		return frame
	end

	local header = track(CreateFrame("Frame", nil, parent))
	header:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -8)
	header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -8)
	header:SetHeight(26)
	local trackerHeader = track(header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
	trackerHeader:SetPoint("LEFT", header, "LEFT", 6, 0)
	trackerHeader:SetPoint("RIGHT", header, "RIGHT", enabledOffset - 18, 0)
	trackerHeader:SetJustifyH("LEFT")
	trackerHeader:SetText(L["ClassBuffReminderTrackerMatrixTracker"] or "Reminder")
	local enabledHeader = track(header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
	enabledHeader:SetPoint("RIGHT", header, "RIGHT", enabledOffset, 0)
	enabledHeader:SetWidth(26)
	enabledHeader:SetJustifyH("CENTER")
	enabledHeader:SetText(L["ClassBuffReminderTrackerMatrixEnabledShort"] or "On")

	for i = 1, #content do
		local option = content[i]
		local offset = -24 - ((#content - i) * 30)
		local label = track(header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
		label:SetPoint("RIGHT", header, "RIGHT", offset, 0)
		label:SetWidth(28)
		label:SetJustifyH("CENTER")
		label:SetText(CONTENT_SHORT_LABELS[option.value] or "?")
		label:EnableMouse(true)
		label:SetScript("OnEnter", function(self) showTooltip(self, option.text, L["ClassBuffReminderTrackingContentDesc"]) end)
		label:SetScript("OnLeave", GameTooltip_Hide)
	end

	local previous = header
	for rowIndex = 1, #rows do
		local row = rows[rowIndex]
		local frame = track(CreateFrame("Frame", nil, parent))
		frame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -2)
		frame:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -2)
		frame:SetHeight(28)
		local name = track(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
		name:SetPoint("LEFT", frame, "LEFT", 6, 0)
		name:SetPoint("RIGHT", frame, "RIGHT", enabledOffset - 18, 0)
		name:SetJustifyH("LEFT")
		name:SetText(row.label)

		local enabled = track(CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate"))
		enabled:SetSize(24, 24)
		enabled:SetPoint("RIGHT", frame, "RIGHT", enabledOffset, 0)
		enabled:SetChecked(addon.db and addon.db[row.enabledDb] == true)
		enabled:SetScript("OnClick", function(self)
			if addon.db then addon.db[row.enabledDb] = self:GetChecked() == true end
			if row.invalidate and Reminder[row.invalidate] then Reminder[row.invalidate](Reminder) end
			refreshReminder()
			local designer = addon.LibSettingsDesigner and addon.LibSettingsDesigner.UI
			if designer and designer.RefreshVisibleRows then designer.RefreshVisibleRows(state) end
		end)
		enabled:SetScript("OnEnter", function(self) showTooltip(self, row.label, L["ClassBuffReminderTrackerMatrixEnableDesc"]) end)
		enabled:SetScript("OnLeave", GameTooltip_Hide)

		local selection = getSelection(row.getter)
		for i = 1, #content do
			local option = content[i]
			local offset = -24 - ((#content - i) * 30)
			local check = track(CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate"))
			check:SetSize(24, 24)
			check:SetPoint("RIGHT", frame, "RIGHT", offset, 0)
			check:SetChecked(selection[option.value] == true)
			check:SetScript("OnClick", function(self)
				local updated = getSelection(row.getter)
				if self:GetChecked() == true then updated[option.value] = true else updated[option.value] = nil end
				setSelection(row.setter, updated)
			end)
			check:SetScript("OnEnter", function(self) showTooltip(self, row.label, option.text) end)
			check:SetScript("OnLeave", GameTooltip_Hide)
			handle.checks[#handle.checks + 1] = check
		end
		previous = frame
	end

	function handle:Release()
		for i = 1, #(self.frames or {}) do
			local frame = self.frames[i]
			if frame and frame.Hide then frame:Hide() end
			if frame and frame.SetParent then frame:SetParent(nil) end
		end
		wipe(self.frames)
		wipe(self.checks)
	end
	return handle
end

local app = addon.ConfigApp
local section = Reminder.settingsSection
local pageID = app and app.legacySections and app.legacySections[section]
local groupID = addon.ConfigCurrentGroupBySection and addon.ConfigCurrentGroupBySection[section]
if pageID and groupID and app.GetPage and app:GetPage(pageID) and app.RegisterControl then
	app:RegisterControl(pageID, {
		id = MATRIX_ID,
		type = "custom",
		label = L["ClassBuffReminderTrackerMatrixTitle"] or "Reminder matrix",
		description = L["ClassBuffReminderTrackerMatrixDesc"] or "Enable reminders and choose the content in which each one is active.",
		groupID = groupID,
		groupTitle = (addon.ConfigGroupTitleBySection and addon.ConfigGroupTitleBySection[section]) or L["Class Buff Reminder"] or "Class Buff Reminder",
		getHeight = function() return 132 + (#buildRows() * 30) end,
		render = function(parent, _, _, state) return renderMatrix(parent, state) end,
		release = function(handle)
			if handle and handle.Release then handle:Release() end
		end,
		keywords = { "Class Buff Reminder", "Flask", "Food", "Augment Rune", "Weapon Buff", "Stance", "Pet", "Healthstone" },
		order = (addon.ConfigControlOrder or 0) + 1,
		newTagID = MATRIX_ID,
	})
end

function Reminder:OpenTrackerMatrix()
	if addon.functions and addon.functions.OpenConfigCenter then addon.functions.OpenConfigCenter(pageID, MATRIX_ID) end
end
