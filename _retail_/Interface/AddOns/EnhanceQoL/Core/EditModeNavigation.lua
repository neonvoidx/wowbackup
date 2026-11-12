local _, addon = ...
addon = _G.EnhanceQoL or addon
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local lib = addon.EditModeLib
if not (lib and lib.internal and lib.internal.CreateSettingsView) then return end

-- Shared navigation for registered frames and opted-in standalone editors.
-- Their settings, callbacks and profile data remain authoritative.
local Nav = {}
addon.EditModeNavigation = Nav
-- Render the middle dot independently of the active locale's font glyphs.
Nav.inlineSeparator = " |TInterface\\AddOns\\EnhanceQoL\\Assets\\Mouse\\CircleFill.tga:2:2:0:0|t "

function Nav:New(window)
	return setmetatable({ window = window, searchText = "", scrollPositions = {}, categoryTabs = {}, tabButtons = {}, listButtons = {}, actionButtons = {}, states = setmetatable({}, { __mode = "k" }), sharedStates = {}, options = {} }, { __index = self })
end

function Nav:GetSettings()
	if self.window and self.window.GetNavigationSettings then return self.window:GetNavigationSettings() end
	return lib.internal:GetFrameSettings(self.hostFrame)
end

function Nav:Normalize(text)
	text = tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	-- Use the same locale-aware parser as the Settings Center. Byte-wise Lua
	-- lowercasing alone cannot normalize Cyrillic or accented search terms.
	if type(_G.CaseAccentInsensitiveParse) == "function" then return _G.CaseAccentInsensitiveParse(text) end
	return (_G.strlower or string.lower)(text)
end

function Nav:GetSearchAliases()
	local normalizer = type(_G.CaseAccentInsensitiveParse) == "function" and _G.CaseAccentInsensitiveParse or (_G.strlower or string.lower)
	if self.searchAliases and self.searchNormalizer == normalizer then return self.searchAliases end
	self.searchNormalizer = normalizer
	self.searchTextCache = nil
	local aliases = {
		{ terms = "font typeface " .. L["UFNavSearchFont"], seeds = { "font", L["Font"], L["Font outline"], _G.FONT_SIZE or L["Font Size"] } },
		{ terms = "offset position anchor " .. L["UFNavSearchPosition"], seeds = { "offset", "anchor", L["Offset X"], L["Offset Y"], L["Anchor"], L["Position"] } },
		{ terms = "health life hp " .. L["UFNavSearchHealth"], seeds = { "health", L["Health"] } },
		{ terms = "power resource mana energy " .. L["UFNavSearchPower"], seeds = { "power", L["Power"] } },
		{ terms = "size width height scale " .. L["UFNavSearchSize"], seeds = { "size", "width", "height", L["Size"], L["Width"], L["Height"] } },
		{ terms = "border edge " .. L["UFNavSearchBorder"], seeds = { "border", L["Border"] } },
	}
	for _, group in ipairs(aliases) do
		group.terms = self:Normalize(group.terms)
		for index, seed in ipairs(group.seeds) do group.seeds[index] = self:Normalize(seed) end
	end
	self.searchAliases = aliases
	return aliases
end

function Nav:SearchTerms(text, aliases)
	aliases = aliases or self:GetSearchAliases()
	local base = self:Normalize(text)
	local expanded = base
	for _, group in ipairs(aliases) do
		for _, seed in ipairs(group.seeds) do
			if base:find(seed, 1, true) then expanded = expanded .. " " .. group.terms; break end
		end
	end
	return expanded
end

function Nav:VisibilityHint(data)
	return data.navigationHint or (self.options.visibilityHint and self.options.visibilityHint(data))
end

function Nav:BuildModel(settings)
	local aliases = self:GetSearchAliases()
	local previousSearchText = self.searchTextCache or {}
	local searchTextCache = {}
	local headers = {}
	for _, data in ipairs(settings) do
		if data.kind == lib.SettingType.Collapsible then
			local id = data.id or data.name
			headers[id] = data
		end
	end
	local headerVisibility, resolvingHeaders = {}, {}
	local function headerShown(id)
		if headerVisibility[id] ~= nil then return headerVisibility[id] end
		local header = headers[id]
		if not header then return true end
		if resolvingHeaders[id] then return false end
		resolvingHeaders[id] = true
		local shown = lib.internal:IsSettingShown(header) and (not header.parentId or headerShown(header.parentId))
		resolvingHeaders[id] = nil
		headerVisibility[id] = not not shown
		return headerVisibility[id]
	end
	local groups, groupOrder, rawGroups = {}, {}, {}
	local sectionByGroup = {}
	local function add(data, rawId)
		local header = headers[rawId] or { id = rawId, name = L["General"] }
		local shown = headerShown(rawId)
		if not shown and not self:VisibilityHint(header) then return end
		local section = sectionByGroup[rawId] or ""
		if data.kind == lib.SettingType.Divider then section = data.name or ""; sectionByGroup[rawId] = section end
		local id, name = rawId, header.name
		local split = self.options.splitGroups and self.options.splitGroups[rawId]
		if split then
			local splitId, splitName = split(data, section)
			id, name = splitId or id, splitName or name
		end
		local group = groups[id]
		if not group then
			local tabHeader = header
			if split then
				tabHeader = {}
				for key, value in pairs(header) do if key ~= "navigationReset" then tabHeader[key] = value end end
			end
			group = { id = id, sourceGroup = rawId, name = name, header = tabHeader, settings = {}, hidden = not shown }
			groups[id] = group
			groupOrder[#groupOrder + 1] = id
			rawGroups[rawId] = rawGroups[rawId] or {}
			rawGroups[rawId][#rawGroups[rawId] + 1] = id
		end
		group.settings[#group.settings + 1] = data
	end
	-- Retain unparented controls and original row order; no collapse-state dependency.
	for _, data in ipairs(settings) do
		if data.kind ~= lib.SettingType.Collapsible then add(data, data.parentId or "__general") end
	end
	for id, group in pairs(groups) do
		local count, available = 0, 0
		for _, data in ipairs(group.settings) do
			if data.kind ~= lib.SettingType.Divider then
				count = count + 1
				if not data.navigationSearchExcluded or lib.internal:IsSettingShown(data) then available = available + 1 end
			end
		end
		if count == 0 then groups[id] = nil elseif available == 0 then group.hidden = true end
	end
	local model = { categories = {}, tabs = {}, entries = {}, byData = {}, byKey = {} }
	local assigned = {}
	local function category(spec)
		local cat = { id = spec.id, name = spec.name, tabs = {} }
		local candidates, seen = {}, {}
		for _, id in ipairs(spec.groups) do
			for _, tabId in ipairs(rawGroups[id] or { id }) do
				if groups[tabId] and not assigned[tabId] and not seen[tabId] then
					candidates[#candidates + 1] = groups[tabId]; seen[tabId] = true
				end
			end
		end
		for _, tab in ipairs(candidates) do
			assigned[tab.id] = true
			tab.category = cat
			tab.label = (self.options.tabNames and self.options.tabNames[tab.id]) or tab.name
			model.tabs[tab.id] = tab
			if not tab.hidden then cat.tabs[#cat.tabs + 1] = tab end
			local section, duplicates = "", {}
			for _, data in ipairs(tab.settings) do
				if data.kind == lib.SettingType.Divider then section = data.name or ""
				elseif type(data.name) == "string" and data.name ~= "" and not data.navigationSearchExcluded then
					local path = cat.name
					if tab.label ~= cat.name then path = path .. " › " .. tab.label end
					if section ~= "" and section ~= tab.label then path = path .. " › " .. section end
					local key = tostring(data.navigationId or data.navigationField or data.id or (section .. ":" .. data.name))
					duplicates[key] = (duplicates[key] or 0) + 1
					key = tab.id .. ":" .. key .. ":" .. duplicates[key]
					local searchText = path .. " " .. data.name .. " " .. tab.id .. " " .. (data.searchTags or "")
					local search = previousSearchText[searchText] or searchTextCache[searchText] or self:SearchTerms(searchText, aliases)
					searchTextCache[searchText] = search
					local entry = { data = data, tab = tab, path = path, section = section, key = key,
						search = search }
					model.entries[#model.entries + 1] = entry
					model.byData[data], model.byKey[key] = entry, entry
				end
			end
		end
		if #cat.tabs > 0 then model.categories[#model.categories + 1] = cat end
	end
	for _, spec in ipairs(self.options.categories or {}) do category(spec) end
	local rest = {}
	for _, id in ipairs(groupOrder) do if groups[id] and not assigned[id] then rest[#rest + 1] = id end end
	if #rest > 0 then category({ id = "general", name = #model.categories > 0 and L["Other"] or L["General"], groups = rest }) end
	model.direct = self.options.direct == true or #model.categories == 1
	-- Keep only this model's exact search texts; visibility and grouping are
	-- reevaluated on every pass, including in-place setting/profile changes.
	self.searchTextCache = searchTextCache
	return model
end

function Nav:SettingShown(model, data)
	local entry = model.byData[data]
	return lib.internal:IsSettingShown(data) and (not entry or not entry.tab.hidden)
end

function Nav:HiddenPrerequisite(model, data)
	local entry = model.byData[data]
	if not entry or self:SettingShown(model, data) then return end
	local hint = self:VisibilityHint(entry.tab.hidden and entry.tab.header or data)
	if not hint then return end
	local name, section, tabId, explanation = hint()
	if not name then return end
	for _, candidate in ipairs(model.entries) do
		local sameGroup = tabId and (candidate.tab.id == tabId or candidate.tab.sourceGroup == tabId)
			or (not tabId and candidate.tab.sourceGroup == entry.tab.sourceGroup)
		if sameGroup and candidate.data.name == name and (not section or section == candidate.section) then
			if candidate.data ~= data and self:SettingShown(model, candidate.data) then
				return candidate, explanation or string.format(L["UFNavHiddenBy"], name)
			end
		end
	end
end

function Nav:CopyDefault(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for key, item in pairs(value) do copy[key] = self:CopyDefault(item) end
	return copy
end

function Nav:CanReset(tab)
	if not tab or self.options.canReset == false then return false end
	if type(self.options.canReset) == "function" and not self.options.canReset(tab) then return false end
	if tab.header.navigationReset then return true end
	local count = 0
	for _, data in ipairs(tab.settings) do
		if data.kind ~= lib.SettingType.Divider and data.kind ~= lib.SettingType.Label and not data.navigationSearchExcluded and not data.navigationResetExcluded then
			local hasValue = data.navigationReset or (data.default ~= nil and data.set)
			local hasColor = data.colorDefault ~= nil and (data.colorSet or data.setColor)
			if not hasValue and not hasColor then return false end
			count = count + 1
		end
	end
	return count > 0
end

function Nav:ResetTab(tabId)
	if InCombatLockdown() then return end
	local settings = self:GetSettings()
	local tab = settings and self:BuildModel(settings).tabs[tabId]
	if not self:CanReset(tab) then return end
	self.target, self.focusTargetPending, self.resolvedTarget = nil, nil, nil
	local apply = function(target) self:ApplyTabDefaults(target or tab) end
	local ok, err = pcall(function()
		if self.options.reset then self.options.reset(tab, apply) else apply(tab) end
	end)
	self:Queue()
	if not ok then error(err) end
end

function Nav:ColorDefault(value)
	local color = self:CopyDefault(value)
	if type(color) == "table" then
		color.r, color.g, color.b, color.a = color.r or color[1], color.g or color[2], color.b or color[3], color.a or color[4] or 1
		color[1], color[2], color[3], color[4] = color.r, color.g, color.b, color.a
	end
	return color
end

function Nav:ApplyTabDefaults(tab)
	if tab.header.navigationReset then tab.header.navigationReset(); return end
	-- Color setters can change related toggles. Restore values after all colors.
	for _, data in ipairs(tab.settings) do
		if not data.navigationSearchExcluded and not data.navigationResetExcluded then
			local apply = data.colorSet or data.setColor
			if data.kind == lib.SettingType.Color then
				if data.navigationReset then data.navigationReset()
				elseif data.set and data.default ~= nil then data.set(nil, self:ColorDefault(data.default), lib:GetActiveLayoutIndex()) end
			elseif apply and data.colorDefault ~= nil then apply(nil, self:ColorDefault(data.colorDefault), lib:GetActiveLayoutIndex()) end
		end
	end
	for _, data in ipairs(tab.settings) do
		if not data.navigationSearchExcluded and not data.navigationResetExcluded and data.kind ~= lib.SettingType.Color then
			if data.navigationReset then data.navigationReset()
			elseif data.default ~= nil and data.set then data.set(nil, self:CopyDefault(data.default), lib:GetActiveLayoutIndex()) end
		end
	end
end

function Nav:CaptureActionContext()
	local db = addon.db
	return {
		profile = db,
		ufFrames = db and db.ufFrames,
		ufGroupFrames = db and db.ufGroupFrames,
		generation = lib.GetContextGeneration and lib:GetContextGeneration() or 0,
		navigation = self.contextGeneration or 0,
	}
end

function Nav:IsActionContextCurrent(context)
	local db = addon.db
	return context and context.profile == db
		and context.ufFrames == (db and db.ufFrames)
		and context.ufGroupFrames == (db and db.ufGroupFrames)
		and context.generation == (lib.GetContextGeneration and lib:GetContextGeneration() or 0)
		and context.navigation == (self.contextGeneration or 0)
end

function Nav:CloseResetConfirmation()
	local popup = _G.StaticPopup_FindVisible and _G.StaticPopup_FindVisible("EQOL_EDIT_MODE_NAV_RESET")
	if not popup or not popup.data or popup.data.nav ~= self then return end
	-- Match the captured data as well as the dialog type: another navigation
	-- can open its own confirmation while the previous editor is being hidden.
	StaticPopup_Hide("EQOL_EDIT_MODE_NAV_RESET", popup.data)
end

if lib.RegisterCallback then
	lib:RegisterCallback("context", function()
		local popup = _G.StaticPopup_FindVisible and _G.StaticPopup_FindVisible("EQOL_EDIT_MODE_NAV_RESET")
		local data = popup and popup.data
		if data and data.nav and not data.nav:IsActionContextCurrent(data.context) then data.nav:CloseResetConfirmation() end
	end)
end

function Nav:ShowResetConfirmation(label, tabId)
	StaticPopupDialogs.EQOL_EDIT_MODE_NAV_RESET = StaticPopupDialogs.EQOL_EDIT_MODE_NAV_RESET or {
		text = L["UFNavResetConfirm"], button1 = _G.RESET, button2 = _G.CANCEL,
		timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
		OnAccept = function(_, data)
			if data and data.nav.enabled and data.nav.hostFrame == data.frame and data.nav.scopeKey == data.scopeKey and data.nav:IsActionContextCurrent(data.context) and not InCombatLockdown() then
				if data.tabId then data.nav:ResetTab(data.tabId) else data.nav.window:ResetSettings() end
			end
		end,
	}
	StaticPopup_Show("EQOL_EDIT_MODE_NAV_RESET", label, nil, { nav = self, frame = self.hostFrame, scopeKey = self.scopeKey, context = self:CaptureActionContext(), tabId = tabId })
end

function Nav:ConfirmReset()
	local tab = self.model and self.model.tabs[self.tabId]
	if self:CanReset(tab) then self:ShowResetConfirmation(tab.category.name .. " › " .. tab.label, tab.id) end
end

function Nav:ConfirmFrameReset()
	self:ShowResetConfirmation(self.title)
end

function Nav:Search(model, query)
	local results, tokens = {}, {}
	for word in self:Normalize(query):gmatch("%S+") do tokens[#tokens + 1] = word end
	if #tokens == 0 then return results end
	for _, entry in ipairs(model.entries) do
		local match = true
		for _, word in ipairs(tokens) do
			if not entry.search:find(word, 1, true) then match = false; break end
		end
		if match then results[#results + 1] = entry end
	end
	return results
end

function Nav:IsBusy()
	if lib.internal:IsSettingsInteractionActive() then return true end
	local focus = _G.GetCurrentKeyBoardFocus and _G.GetCurrentKeyBoardFocus()
	return focus and focus ~= self.search
end

function Nav:SaveScroll()
	if self.displayedTabId and self.scroll and not self.showingResults and not self.rendering then self.scrollPositions[self.displayedTabId] = self.scroll:GetVerticalScroll() end
end

function Nav:SetScrollOffset(offset)
	self.scroll:UpdateScrollChildRect()
	local maximum = math.max(0, self.content:GetHeight() - self.scroll:GetHeight())
	offset = math.max(0, math.min(offset, maximum))
	-- Keep the native scrollbar's range in sync before its value callback runs.
	self.scroll.ScrollBar:SetMinMaxValues(0, maximum)
	self.scroll.ScrollBar:SetValue(offset)
	self.scroll:SetVerticalScroll(offset)
	return offset
end

function Nav:CancelSearchFocus()
	self.focusGeneration = (self.focusGeneration or 0) + 1
	if self.highlightAnimation then self.highlightAnimation:Stop() end
	if self.highlight then
		self.highlight:Hide()
		self.highlight:ClearAllPoints()
	end
end

function Nav:FlashSearchResult(row)
	if not self.highlightAnimation then
		local group = self.highlight:CreateAnimationGroup()
		local phases = { { 0, 1, 0.15 }, { 1, 0.12, 0.35 }, { 0.12, 1, 0.15 }, { 1, 0, 0.8 } }
		for order, phase in ipairs(phases) do
			local alpha = group:CreateAnimation("Alpha")
			alpha:SetOrder(order)
			alpha:SetFromAlpha(phase[1])
			alpha:SetToAlpha(phase[2])
			alpha:SetDuration(phase[3])
		end
		group:SetScript("OnFinished", function() self.highlight:Hide() end)
		group:SetScript("OnStop", function() self.highlight:Hide() end)
		self.highlightAnimation = group
	end
	self.highlightAnimation:Stop()
	self.highlight:ClearAllPoints()
	self.highlight:SetAllPoints(row)
	self.highlight:SetAlpha(0)
	self.highlight:Show()
	self.highlightAnimation:Play()
end

function Nav:FocusSearchResult(row, data, tabId, requestedTarget)
	local generation = self.focusGeneration
	-- Let the new tab and native row layouts settle before positioning the hit.
	C_Timer.After(0, function()
		if self.focusGeneration ~= generation or not self.enabled or not self.window:IsShown() then return end
		if self.target ~= (requestedTarget or data) or self.tabId ~= tabId or self.view.rows[data] ~= row then return end
		if self:IsBusy() then self:Queue(); return end
		self.focusTargetPending = nil
		self.scrollPositions[tabId] = self:SetScrollOffset(row._settingsViewOffset - 12)
		self:FlashSearchResult(row)
	end)
end

function Nav:SetSearchText(text)
	-- OnTextChanged may arrive after SetText returns. Acknowledge navigation's
	-- text change by value, so its delayed notification cannot clear the target.
	self.searchText = text
	self.search:SetText(text)
end

function Nav:SearchTextChanged()
	local text = self.search:GetText()
	if text == self.searchText then return end
	self.searchText = text
	self:SaveScroll()
	self.target, self.focusTargetPending = nil, nil
	self.resolvedTarget = nil
	self:Queue()
end

function Nav:OpenTab(tab, target)
	self:SaveScroll()
	local query = self.search:GetText()
	if query:find("%S") then self.returnQuery = query end
	self.categoryId, self.tabId, self.target = tab.category.id, tab.id, target
	self.categoryTabs[tab.category.id] = tab.id
	self.focusTargetPending = target ~= nil
	self.resolvedTarget = nil
	self:SetSearchText("")
	self.search:ClearFocus()
	self:Queue()
end

function Nav:Back()
	self:SaveScroll()
	self.target = nil
	self.resolvedTarget = nil
	if self.search:GetText():find("%S") then
		self.returnQuery = nil
		self:SetSearchText("")
	elseif self.returnQuery then
		local query = self.returnQuery
		self.returnQuery = nil
		self.categoryId, self.tabId = nil, nil
		self:SetSearchText(query)
	else
		self.categoryId, self.tabId = nil, nil
	end
	self.search:ClearFocus()
	self:Queue()
end

function Nav:GetListButton(index)
	local button = self.listButtons[index]
	if button then return button end
	button = CreateFrame("Button", nil, self.content)
	button:SetHeight(54)
	button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	button.background = button:CreateTexture(nil, "BACKGROUND")
	button.background:SetAllPoints()
	button.background:SetColorTexture(0.12, 0.10, 0.06, 0.7)
	button.separator = button:CreateTexture(nil, "BACKGROUND")
	button.separator:SetPoint("BOTTOMLEFT", 12, 0)
	button.separator:SetPoint("BOTTOMRIGHT", -12, 0)
	button.separator:SetHeight(1)
	button.separator:SetColorTexture(0.7, 0.65, 0.55, 0.18)
	button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	button.label:SetPoint("TOPLEFT", 12, -9)
	button.label:SetPoint("TOPRIGHT", -28, -9)
	button.label:SetJustifyH("LEFT")
	button.label:SetWordWrap(false)
	button.detail = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.detail:SetPoint("TOPLEFT", button.label, "BOTTOMLEFT", 0, -5)
	button.detail:SetPoint("RIGHT", -28, 0)
	button.detail:SetJustifyH("LEFT")
	button.detail:SetWordWrap(false)
	local arrow = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	button.arrow = arrow
	arrow:SetPoint("RIGHT", -10, 0)
	arrow:SetText("›")
	button:SetScript("OnClick", function()
		if button.entry then self:OpenTab(button.entry.tab, button.entry.data)
		elseif button.tab then self:OpenTab(button.tab) end
	end)
	button:SetScript("OnEnter", function()
		arrow:SetAlpha(1)
		GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
		GameTooltip:SetText(button.label:GetText())
		GameTooltip:AddLine(button.detail:GetText(), 1, 1, 1, true)
		if button.entry and not self:SettingShown(self.model, button.entry.data) then
			local _, hint = self:HiddenPrerequisite(self.model, button.entry.data)
			GameTooltip:AddLine(hint or L["UFNavHiddenSetting"], 1, 0.82, 0, true)
		end
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		arrow:SetAlpha(button.entry and 0.55 or 1)
		GameTooltip:Hide()
	end)
	self.listButtons[index] = button
	return button
end

function Nav:DrawTabs(category)
	for _, button in ipairs(self.tabButtons) do button:Hide() end
	if not category or #category.tabs < 2 then return 0 end
	local x, y, width = 0, 0, self.window:GetWidth() - 40
	for index, tab in ipairs(category.tabs) do
		local button = self.tabButtons[index]
		if not button then
			button = CreateFrame("Button", nil, self.surface, "PanelTopTabButtonTemplate")
			button:SetHeight(32)
			-- Width and wrapping are owned by this fixed navigation strip.
			button:SetScript("OnShow", nil)
			button:UnregisterEvent("DISPLAY_SIZE_CHANGED")
			button:SetScript("OnClick", function() self:OpenTab(button.tab) end)
			self.tabButtons[index] = button
		end
		button.tab = tab
		button:SetText(tab.label)
		_G.PanelTemplates_TabResize(button, 0, nil, 66, width - 8)
		local buttonWidth = button:GetWidth()
		if x > 0 and x + buttonWidth + 8 > width then x, y = 0, y + 34 end
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", self.window, "TOPLEFT", 20 + x, -101 - y)
		if tab.id == self.tabId then _G.PanelTemplates_SelectTab(button) else _G.PanelTemplates_DeselectTab(button) end
		button:GetFontString():SetTextColor(1, tab.id == self.tabId and 0.82 or 1, tab.id == self.tabId and 0 or 1)
		button:Show()
		x = x + buttonWidth + 8
	end
	return y + 40
end

function Nav:DrawActions()
	local buttons = self.window.GetNavigationButtons and self.window:GetNavigationButtons() or lib.internal:GetFrameButtons(self.hostFrame) or {}
	local compact = #buttons > 3
	local columns = compact and 2 or 1
	local width = (self.window:GetWidth() - 40 - (columns - 1) * 6) / columns
	for index, data in ipairs(buttons) do
		local button = self.actionButtons[index]
		if not button then
			button = CreateFrame("Button", nil, self.actions, "UIPanelButtonTemplate")
			button:SetHeight(23)
			button:SetScript("OnEnter", function()
				GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
				GameTooltip:SetText(button:GetText())
				GameTooltip:Show()
			end)
			button:SetScript("OnLeave", GameTooltip_Hide)
			self.actionButtons[index] = button
		end
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", ((index - 1) % columns) * (width + 6), -math.floor((index - 1) / columns) * 29)
		button:SetWidth(width)
		button:SetText(data.text)
		button:SetScript("OnClick", data.click)
		button:Show()
	end
	for index = #buttons + 1, #self.actionButtons do
		self.actionButtons[index]:Hide()
		self.actionButtons[index]:SetScript("OnClick", nil)
	end
	local height = #buttons > 0 and math.ceil(#buttons / columns) * 29 - 6 or 0
	self.actions:SetHeight(math.max(1, height))
	self.actions:SetShown(height > 0)
	self.actionsHeight = height > 0 and height + 12 or 0
	-- Keep the settings viewport when adding fixed actions, within the screen.
	self.window:SetHeight(math.min((self.options.height or 650) + self.actionsHeight, UIParent:GetHeight() - 60))
	self.footer:ClearAllPoints()
	self.footer:SetPoint("BOTTOMLEFT", self.window, "BOTTOMLEFT", 20, 13 + self.actionsHeight)
	self.footer:SetPoint("BOTTOMRIGHT", self.window, "BOTTOMRIGHT", -20, 13 + self.actionsHeight)
end

function Nav:SetFooter(text)
	self.footer:SetText(text or "")
	local height = text and text ~= "" and math.max(48, self.footer:GetStringHeight() + 26) or 28
	self.scroll:SetPoint("BOTTOMRIGHT", self.window, "BOTTOMRIGHT", -35, height + self.actionsHeight)
end

function Nav:Render()
	local settings = self:GetSettings()
	if not settings then return end
	local oldEntry = self.model and self.target and self.model.byData[self.target]
	self.model = self:BuildModel(settings)
	if oldEntry and not self.model.byData[self.target] then
		local replacement = self.model.byKey[oldEntry.key]
		self.target = replacement and replacement.data
		self.resolvedTarget = nil
	end
	local pendingFocus = lib.internal.pendingNavigationFocus
	local focusGroup = pendingFocus and pendingFocus[self.hostFrame]
	if focusGroup then
		local candidate = self:FindVisibleGroup(self.model, focusGroup)
		if candidate then
			self:OpenTab(candidate)
			pendingFocus[self.hostFrame] = nil
		end
	end
	if self.model.direct and not self.model.tabs[self.tabId] and self.model.categories[1] then self.tabId = self.model.categories[1].tabs[1].id end
	self:CancelSearchFocus()
	self.view:Release()
	for _, button in ipairs(self.listButtons) do button:Hide() end
	self.message:Hide()
	local query = self.search:GetText()
	local searching = query:find("%S") ~= nil
	local prerequisite, hint
	if self.target and not searching then
		prerequisite, hint = self:HiddenPrerequisite(self.model, self.target)
		local resolved = prerequisite or self.model.byData[self.target]
		if resolved and (self.focusTargetPending or self.resolvedTarget ~= resolved.data) then
			self.tabId, self.categoryId = resolved.tab.id, resolved.tab.category.id
			self.categoryTabs[self.categoryId] = self.tabId
			self.focusTargetPending = true
		end
		self.resolvedTarget = resolved and resolved.data
	end
	local tab = self.model.tabs[self.tabId]
	if tab and tab.hidden then
		self.tabId, tab = nil, nil
		if self.model.direct and self.model.categories[1] then
			tab = self.model.categories[1].tabs[1]
			self.tabId = tab.id
		end
	end
	local category = tab and tab.category
	self.showingResults = searching
	self.back:SetShown(searching or self.returnQuery ~= nil or (category ~= nil and not self.model.direct))
	self.reset:SetShown(not searching and self:CanReset(tab))
	self.window.Title:SetText((self.title or "") .. (category and not searching and not self.options.hideCategoryTitle and self.inlineSeparator .. category.name or ""))
	local tabsHeight = self:DrawTabs(not searching and category or nil)
	self:DrawActions()
	local top = (searching or category) and 103 + tabsHeight or 78
	self.scroll:ClearAllPoints()
	self.scroll:SetPoint("TOPLEFT", self.window, "TOPLEFT", 20, -top)
	self.content:SetWidth(self.window:GetWidth() - 63)
	local footerText
	if self.target and not searching and not self:SettingShown(self.model, self.target) then footerText = hint or L["UFNavHiddenSetting"] end
	self:SetFooter(footerText)
	if searching or not category then
		local items = searching and self:Search(self.model, query) or self.model.categories
		local rowHeight, rowStride = searching and 48 or 54, searching and 48 or 59
		for index, item in ipairs(items) do
			local button = self:GetListButton(index)
			button:SetWidth(self.content:GetWidth())
			button:SetHeight(rowHeight)
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", 0, -(index - 1) * rowStride)
			button.background:SetShown(not searching)
			button.separator:SetShown(searching and index < #items)
			button:GetHighlightTexture():SetAlpha(searching and 0.3 or 1)
			button.arrow:SetAlpha(searching and 0.55 or 1)
			button.entry, button.tab = nil, nil
			if searching then
				button.entry = item
				button.label:SetText(item.data.name)
				local shown = self:SettingShown(self.model, item.data)
				button.detail:SetText((shown and "" or L["UFNavHidden"] .. self.inlineSeparator) .. item.path)
				button.detail:SetTextColor(0.64, 0.64, 0.61)
				button.label:SetTextColor(1, shown and 0.82 or 0.55, shown and 0 or 0.55)
			else
				local remembered = self.model.tabs[self.categoryTabs[item.id]]
				button.tab = remembered and not remembered.hidden and remembered or item.tabs[1]
				button.label:SetText(item.name)
				button.label:SetTextColor(1, 0.82, 0)
				local labels = {}
				for _, child in ipairs(item.tabs) do labels[#labels + 1] = child.label end
				button.detail:SetText(table.concat(labels, self.inlineSeparator))
				button.detail:SetTextColor(1, 1, 1)
			end
			button:Show()
		end
		self.content:SetHeight(math.max(1, #items * rowStride))
		if #items == 0 then self.message:SetText(L["UFNavNoResults"]); self.message:Show() end
		self:SetScrollOffset(0)
	else
		local rows = self.view:Render(tab.settings, self.window.selection or { parent = self.hostFrame })
		local offset = self.scrollPositions[tab.id] or 0
		if self.target then
			local focusData = prerequisite and prerequisite.data or self.target
			local row = rows[focusData]
			if row then
				if self.focusTargetPending then self:FocusSearchResult(row, focusData, tab.id, self.target) end
			else
				if self.focusTargetPending then offset = 0; self.focusTargetPending = nil end
				self:SetFooter(L["UFNavHiddenSetting"])
			end
		end
		self:SetScrollOffset(offset)
	end
	self.displayedTabId = not searching and tab and tab.id or nil
end

function Nav:Queue()
	if self.rendering or not self.enabled or self.queued then return end
	self.queued = true
	C_Timer.After(0.05, function()
		self.queued = nil
		if not self.enabled or not self.window or not self.window:IsShown() then return end
		if self:IsBusy() then self:Queue(); return end
		self.rendering = true
		local ok, err = pcall(self.Render, self)
		self.rendering = nil
		if not ok then geterrorhandler()(err) end
	end)
end

function Nav:CreateWindow()
	local window = CreateFrame("Frame", nil, self.window)
	self.surface = window
	window:SetAllPoints()
	window.ignoreInLayout = true
	local background = self.window:CreateTexture(nil, "BACKGROUND")
	self.background = background
	background.ignoreInLayout = true
	background:SetPoint("TOPLEFT", 5, -5)
	background:SetPoint("BOTTOMRIGHT", -5, 5)
	background:SetColorTexture(0.025, 0.025, 0.025, 0.94)
	local search = CreateFrame("EditBox", nil, window, "SearchBoxTemplate")
	self.search = search
	search:SetPoint("TOPLEFT", 25, -47)
	search:SetPoint("TOPRIGHT", -20, -47)
	search:SetHeight(22)
	search:SetAutoFocus(false)
	search.Instructions:SetText(L["configCenterSearchPlaceholder"])
	search:HookScript("OnTextChanged", function()
		self:SearchTextChanged()
	end)
	search:SetScript("OnEscapePressed", function() if search:GetText() ~= "" then search:SetText("") end; search:ClearFocus() end)
	self.back = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
	self.back:SetPoint("TOPLEFT", 20, -76)
	self.back:SetSize(92, 23)
	self.back:SetText(_G.BACK or L["UFNavBack"])
	self.back:SetScript("OnClick", function() self:Back() end)
	self.reset = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
	self.reset:SetPoint("TOPRIGHT", search, "BOTTOMRIGHT", 0, -7)
	self.reset:SetSize(180, 23)
	self.reset:SetText(L["UFNavResetTab"])
	self.reset:SetScript("OnClick", function() self:ConfirmReset() end)
	self.scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
	self.scroll:SetScript("OnMouseWheel", function(scroll, delta)
		scroll:SetVerticalScroll(math.max(0, math.min(scroll:GetVerticalScrollRange(), scroll:GetVerticalScroll() - delta * 32)))
	end)
	self.scroll:EnableMouseWheel(true)
	self.scroll:HookScript("OnVerticalScroll", function() self:SaveScroll() end)
	self.content = CreateFrame("Frame", nil, self.scroll)
	self.content:SetSize(347, 1)
	self.scroll:SetScrollChild(self.content)
	self.view = lib.internal:CreateSettingsView(self.content)
	self.highlight = self.content:CreateTexture(nil, "BACKGROUND")
	self.highlight:SetColorTexture(1, 0.72, 0.12, 0.32)
	self.highlight:Hide()
	self.message = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.message:SetPoint("TOPLEFT", self.scroll, "TOPLEFT", 8, -12)
	self.message:SetWidth(320)
	self.message:SetJustifyH("LEFT")
	self.actions = CreateFrame("Frame", nil, window)
	self.actions:SetPoint("BOTTOMLEFT", 20, 13)
	self.actions:SetPoint("BOTTOMRIGHT", -20, 13)
	self.footer = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	self.footer:SetJustifyH("LEFT")
end

function Nav:SaveState()
	if not self.hostFrame then return end
	self:SaveScroll()
	local state = { tabId = self.tabId, categoryTabs = self.categoryTabs, scrollPositions = self.scrollPositions }
	if self.stateKey then
		self.sharedStates[self.stateKey] = state
	else
		self.states[self.hostFrame] = self.states[self.hostFrame] or {}
		self.states[self.hostFrame][self.scopeKey or "edit"] = state
	end
end

function Nav:Activate(frame, options, title)
	if not self.surface then self:CreateWindow() end
	local scopeKey = options.scopeKey or (self.window.context and self.window.context.mode) or "edit"
	if not self.enabled or self.hostFrame ~= frame or self.scopeKey ~= scopeKey or self.stateKey ~= options.stateKey then
		self:CloseResetConfirmation()
		self.contextGeneration = (self.contextGeneration or 0) + 1
	end
	if self.hostFrame ~= frame or self.scopeKey ~= scopeKey or self.stateKey ~= options.stateKey then
		self:SaveState()
		self:CancelSearchFocus()
		self.view:Release()
		for _, button in ipairs(self.listButtons) do button:Hide() end
		for _, button in ipairs(self.actionButtons) do button:Hide() end
		for _, button in ipairs(self.tabButtons) do button:Hide() end
		local state
		if options.stateKey then state = self.sharedStates[options.stateKey] or {}
		else state = self.states[frame] and self.states[frame][scopeKey] or {} end
		self.stateKey = options.stateKey
		self.hostFrame, self.scopeKey, self.tabId = frame, scopeKey, state.tabId
		self.categoryTabs, self.scrollPositions = state.categoryTabs or {}, state.scrollPositions or {}
		self.target, self.resolvedTarget, self.focusTargetPending, self.returnQuery, self.displayedTabId = nil, nil, nil, nil, nil
		self.model = nil
		self.searchTextCache = nil
		self:SetSearchText("")
		self.search:ClearFocus()
	end
	self.options, self.title, self.enabled = options, title, true
	self.surface:Show()
	self.background:Show()
	self.window:SetWidth(self.options.width or 410)
	self.window.Title:ClearAllPoints()
	self.window.Title:SetPoint("TOPLEFT", 20, -17)
	self.window.Title:SetPoint("RIGHT", -76, 0)
	self.window.Title:SetJustifyH("LEFT")
	self.window.Title:SetWordWrap(false)
	self:Queue()
end

function Nav:Deactivate()
	self:CloseResetConfirmation()
	self.contextGeneration = (self.contextGeneration or 0) + 1
	self:SaveState()
	self.enabled = false
	self:CancelSearchFocus()
	if self.surface then self.surface:Hide(); self.view:Release() end
	if self.background then self.background:Hide() end
end

function Nav:FindVisibleGroup(model, groupId)
	if not model then return end
	for _, category in ipairs(model.categories) do
		for _, tab in ipairs(category.tabs) do
			if tab.id == groupId or tab.sourceGroup == groupId then return tab end
		end
	end
end

function Nav:FocusGroup(groupId)
	local settings = self:GetSettings()
	local tab = self:FindVisibleGroup(settings and self:BuildModel(settings), groupId)
	if tab then self:OpenTab(tab); return true end
end

function lib.internal:CreateSettingsNavigation(window) return Nav:New(window) end
