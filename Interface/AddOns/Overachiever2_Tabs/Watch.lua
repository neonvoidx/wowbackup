-- Overachiever2_Tabs: Watch Tab
-- Collect favorite achievements in a personal watch list.
-- Alt+Click any achievement to add it. Click the X button in the list to remove.

local addonName, ns = ...

local GetAchievementInfo = GetAchievementInfo
local PlaySound = PlaySound
local IsAltKeyDown = IsAltKeyDown

local Overachiever2 = _G["Overachiever2"]
local Utils = Overachiever2 and Overachiever2.Utils

-- State
local settings -- reference to Overachiever2_Tabs_Settings
local WatchList -- reference to settings.WatchList
local achievementList -- the shared list widget
local sortMode = 0
local frame, tab

local SORT_LABELS = { "Name", "Complete", "Points", "ID" }

-- ============================================================================
-- Core Functions
-- ============================================================================

local function Refresh()
	if not WatchList or not achievementList then
		return
	end
	local ids = {}
	for id in pairs(WatchList) do
		ids[#ids + 1] = id
	end
	ns.SortAchievements(ids, sortMode)
	achievementList:SetAchievements(ids)
end

local function AddToWatchList(id)
	if not WatchList then
		return
	end
	if not GetAchievementInfo(id) then
		return
	end
	WatchList[id] = true
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	if frame and frame:IsShown() then
		Refresh()
	elseif tab then
		ns.FlashTab(tab)
	end
end

local function RemoveFromWatchList(id)
	if not WatchList then
		return
	end
	WatchList[id] = nil
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
	if frame and frame:IsShown() then
		Refresh()
	end
end

-- ============================================================================
-- Sort Dropdown
-- ============================================================================

local leftPane -- container for all Watch-specific left pane UI

local function SetSortMode(newMode)
	sortMode = newMode
	if settings then
		settings.WatchSort = sortMode
	end
	Refresh()
end

-- ============================================================================
-- Initialization (called once on first tab show)
-- ============================================================================

local function InitWatch(self)
	-- Saved variables
	settings = Overachiever2_Tabs_Settings or {}
	Overachiever2_Tabs_Settings = settings

	settings.WatchList = settings.WatchList or {}
	settings.WatchSort = settings.WatchSort or 0

	WatchList = settings.WatchList
	sortMode = settings.WatchSort

	-- Validate existing IDs
	for id in pairs(WatchList) do
		if not GetAchievementInfo(id) then
			WatchList[id] = nil
			if Overachiever2 and Overachiever2.Print then
				Overachiever2.Print("Watch: Removed invalid achievement ID " .. id)
			end
		end
	end

	-- Left pane container (holds title, help icon, sort dropdown)
	leftPane = CreateFrame("Frame", nil, AchievementFrameCategories)
	leftPane:SetAllPoints()
	leftPane:Hide()

	-- Title label
	local titleLabel = leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	titleLabel:SetPoint("TOPLEFT", leftPane, "TOPLEFT", 12, -10)
	titleLabel:SetText(ns.L["TAB_WATCH"])

	-- Help icon
	local helpIcon = CreateFrame("Frame", nil, leftPane)
	helpIcon:SetSize(32, 32)
	helpIcon:SetPoint("LEFT", titleLabel, "RIGHT", 0, 0)

	local helpTexture = helpIcon:CreateTexture(nil, "ARTWORK")
	helpTexture:SetAllPoints()
	helpTexture:SetTexture("Interface\\common\\help-i")

	helpIcon:SetScript("OnEnter", function(self)
		Utils.ShowTip(self, "ANCHOR_RIGHT", ns.L["TAB_WATCH"], ns.L["TAB_WATCH_DESC"])
	end)
	helpIcon:SetScript("OnLeave", function()
		Utils.HideTip()
	end)

	-- Sort dropdown (with lable)
	local sortLabel = leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	sortLabel:SetPoint("TOPLEFT", titleLabel, "BOTTOMLEFT", 0, -15)
	sortLabel:SetText(Utils.WhiteText(ns.L["SORT_BY"]))

	local sortDropdown = CreateFrame("DropdownButton", nil, leftPane, "WowStyle2DropdownTemplate")
	sortDropdown:SetSize(173, 22)
	sortDropdown:SetPoint("TOPLEFT", sortLabel, "BOTTOMLEFT", 0, -3)
	sortDropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_OVERACHIEVER2_WATCH_SORT")
		for i, label in ipairs(SORT_LABELS) do
			local mode = i - 1
			rootDescription:CreateRadio(label, function()
				return sortMode == mode
			end, SetSortMode, mode)
		end
	end)
	sortDropdown:SetDefaultText("Sort: " .. SORT_LABELS[sortMode + 1])

	-- Achievement list widget (no topOffset needed since sort button moved to left pane)
	achievementList = ns.CreateAchievementList(self, {
		showRemoveButton = true,
		onRemove = RemoveFromWatchList,
		emptyText = "No achievements watched.\nAlt+Click an achievement to add it.",
	})

	-- Logout cleanup
	self:RegisterEvent("PLAYER_LOGOUT")
	self:SetScript("OnEvent", function()
		if not WatchList then
			return
		end
		for id in pairs(WatchList) do
			if not GetAchievementInfo(id) then
				WatchList[id] = nil
			end
		end
	end)
end

-- ============================================================================
-- Tab Registration
-- ============================================================================

local function OnWatchShow()
	if leftPane then
		leftPane:Show()
	end
	Refresh()
end

local function OnWatchHide()
	if leftPane then
		leftPane:Hide()
	end
end

-- Custom left-pane watermark for the Watch tab.
-- Change .texture to any valid texture path (e.g. "Interface\\AddOns\\YourAddon\\watermark").
-- Optional .texCoords = {left, right, top, bottom} defaults to {0, 1, 0, 1}.
local WATCH_CATEGORY_WATERMARK = {
	texture = "Interface\\ARCHEOLOGY\\ArchRare-QueenAzsharaGown",
	texCoords = { 0.35, 0.85, 0, 1 },
}

frame, tab = ns.RegisterTab("Overachiever2_WatchFrame", ns.L["TAB_WATCH"], {
	showCategories = false,
	loadFunc = InitWatch,
	onShow = OnWatchShow,
	onHide = OnWatchHide,
	categoryWaterMark = WATCH_CATEGORY_WATERMARK,
})

-- ============================================================================
-- Public API (for other tabs to add achievements to watch list)
-- ============================================================================

-- Expose AddToWatchList so other tabs (like Search) can add achievements
ns.AddToWatchList = function(id)
	AddToWatchList(id)
end

ns.RemoveFromWatchList = function(id)
	RemoveFromWatchList(id)
end

ns.IsWatchTabShown = function()
	return frame and frame:IsShown()
end

-- ============================================================================
-- Alt+LeftClick Hook (AchievementTemplateMixin.ProcessClick for 12.0+)
-- ============================================================================

if AchievementTemplateMixin and AchievementTemplateMixin.ProcessClick then
	-- Use hooksecurefunc so the original (secure) ProcessClick runs first.
	-- Replacing it would taint the chat edit box on shift+left-click and break
	-- SendChatMessage in protected channels (e.g. INSTANCE_CHAT in battlegrounds).
	hooksecurefunc(AchievementTemplateMixin, "ProcessClick", function(self, buttonName, down)
		-- Don't allow adding from Guild tab (tab 2)
		if self.id and IsAltKeyDown() and buttonName == "LeftButton" and AchievementFrame.selectedTab ~= 2 then
			AddToWatchList(self.id)
		end
	end)
end
