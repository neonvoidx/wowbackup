local addon, ns = ...
local L = ns.L
local config = CreateFrame("FRAME", "CursorModConfig")
config:Hide()


local glow = {"Interface/AddOns/CursorMod/texture/midnight-fx.png", .5, 1, 0, 1, 64, 64, -1.75, 1.75}
local outline = {"Interface/AddOns/CursorMod/texture/midnight-fx.png", 0, .5, 0, 1, 64, 64, -1.75, 1.75}
config.textures = {
	"Interface/AddOns/CursorMod/texture/point",
	{
		{"Interface/cursor/UICursor2x", 261/512, 293/512, 67/256, 99/256},
		{"Interface/cursor/UICursor2x", 393/512, 441/512, 1/256, 49/256},
		{"Interface/cursor/UICursor2x", 261/512, 325/512, 1/256, 65/256},
		{"Interface/cursor/UICursor2x", 1/512, 97/512, 131/256, 227/256},
		{"Interface/cursor/UICursor2x", 1/512, 129/512, 1/256, 129/256},
	},
	{
		{"Interface/cursor/UICursor2x", 261/512, 293/512, 101/256, 133/256},
		{"Interface/cursor/UICursor2x", 443/512, 491/512, 1/256, 49/256},
		{"Interface/cursor/UICursor2x", 327/512, 391/512, 1/256, 65/256},
		{"Interface/cursor/UICursor2x", 131/512, 227/512, 131/256, 227/256},
		{"Interface/cursor/UICursor2x", 131/512, 259/512, 1/256, 129/256},
	},
	-- "Interface/cursor/unablepoint",
	"Interface/AddOns/CursorMod/texture/point-inverse",
	"Interface/AddOns/CursorMod/texture/point-ghostly",
	{"talents-search-notonactionbar", 84, 84, -2, 3},
	{"talents-search-notonactionbarhidden", 84, 84, -2, 3},
	{"Interface/AddOns/CursorMod/texture/midnight-glow.png", 64, 64, -1.75, 1.75},
	"Interface/AddOns/CursorMod/texture/midnight-inverse.png",
	{"Interface/AddOns/CursorMod/texture/midnight-inverse-glow.png", 64, 64, -1.75, 1.75},
	{
		{"Interface/cursor/UICursor2x", 261/512, 293/512, 67/256, 99/256, glow, outline},
		{"Interface/cursor/UICursor2x", 393/512, 441/512, 1/256, 49/256, glow, outline},
		{"Interface/cursor/UICursor2x", 261/512, 325/512, 1/256, 65/256, glow, outline},
		{"Interface/cursor/UICursor2x", 1/512, 97/512, 131/256, 227/256, glow, outline},
		{"Interface/cursor/UICursor2x", 1/512, 129/512, 1/256, 129/256, glow, outline},
	},
	{"Interface/AddOns/CursorMod/texture/midnight-inverse.png", 32, 32, 0, 0, glow, outline},
}


config:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
config:RegisterEvent("ADDON_LOADED")
config:RegisterEvent("PLAYER_LOGIN")


function config:ADDON_LOADED(addonName)
	if addonName == addon then
		self:UnregisterEvent("ADDON_LOADED")
		self.ADDON_LOADED = nil
		self.sizes = {[0] = 32, 48, 64, 96, 128}

		CursorModDBChar = CursorModDBChar or {}
		self.charDB = CursorModDBChar
		CursorModDB = CursorModDB or {}
		self.globalDB = CursorModDB
		self.globalDB.profiles = self.globalDB.profiles or {
			{name = L["Profile"].." 1", isDefault = true}
		}
		self.profiles = self.globalDB.profiles

		for i = 1, #self.profiles do
			self:checkProfile(self.profiles[i])
		end

		if self.globalDB.config then
			local config = self.profiles[1].config
			for k, v in pairs(self.globalDB.config) do
				config[k] = v
			end
			self.globalDB.config = nil
		end

		hooksecurefunc(UIParent, "SetScale", function() self:setAutoScale() end)
		self:RegisterEvent("UI_SCALE_CHANGED")
		self:setProfile()
	end
end


function config:checkProfile(profile)
	profile.config = profile.config or {}
	profile.config.texPoint = profile.config.texPoint or 1
	if not self.sizes[profile.config.size] then
		local cursorSizePreferred = tonumber(GetCVar("cursorSizePreferred"))
		if not self.sizes[cursorSizePreferred] then cursorSizePreferred = 0 end
		profile.config.size = cursorSizePreferred
	end
	if type(profile.config.autoScale) ~= "boolean" then
		profile.config.autoScale = true
	end
	profile.config.scale = profile.config.scale or 1
	profile.config.opacity = profile.config.opacity or 1
	profile.config.color = profile.config.color or {1, 1, 1}
	profile.config.outlineOpacity = profile.config.outlineOpacity or .75
	profile.config.outlineColor = profile.config.outlineColor or {1, 1, 1}
	profile.config.glowOpacity = profile.config.glowOpacity or .35
	profile.config.glowColor = profile.config.glowColor or {1, 1, 1}
	profile.config.lookStartDelta = profile.config.lookStartDelta or tonumber(GetCVar("CursorFreelookStartDelta")) or .001
end


function config:setProfile(profileName)
	if profileName then
		self.charDB.currentProfileName = profileName
	end
	local currentProfileName, currentProfile, default = self.charDB.currentProfileName

	for i = 1, #self.profiles do
		local profile = self.profiles[i]
		if profile.name == currentProfileName then
			currentProfile = profile
			break
		end
		if profile.isDefault then
			default = profile
		end
	end

	if not currentProfile then
		self.charDB.currentProfileName = nil
		currentProfile = default
	end
	self.currentProfile = currentProfile
	self.pConfig = currentProfile.config

	self:setAutoScale()
	self:setCombatTracking()
	if self.refresh then self:refresh() end
end


local function copyTable(t)
	local n = {}
	for k, v in pairs(t) do
		n[k] = type(v) == "table" and copyTable(v) or v
	end
	return n
end


function config:createProfile(copy)
	local dialog = StaticPopup_Show(self.addonName.."NEW_PROFILE", nil, nil, function(popup)
		local text = popup.EditBox:GetText()
		popup:Hide()
		if text and text ~= "" then
			for _, profile in ipairs(config.profiles) do
				if profile.name == text then
					self.lastProfileName = text
					StaticPopup_Show(self.addonName.."PROFILE_EXISTS", nil, nil, copy)
					return
				end
			end
			local profile = copy and copyTable(self.currentProfile) or {}
			profile.name = text
			profile.isDefault = nil
			self:checkProfile(profile)
			tinsert(self.profiles, profile)
			sort(self.profiles, function(a, b) return a.name < b.name end)
			self:setProfile(text)
		end
	end)
	if dialog and self.lastProfileName then
		dialog.EditBox:SetText(self.lastProfileName)
		dialog.EditBox:HighlightText()
		self.lastProfileName = nil
	end
end


function config:removeProfile(profileName)
	StaticPopup_Show(self.addonName.."DELETE_PROFILE", NORMAL_FONT_COLOR:WrapTextInColorCode(profileName), nil, function()
		for i, profile in ipairs(config.profiles) do
			if profile.name == profileName then
				tremove(config.profiles, i)
				if profile.isDefault then
					config.profiles[1].isDefault = true
				end
				break
			end
		end
		if self.currentProfile.name == profileName then
			self:setProfile()
		end
	end)
end


config:SetScript("OnShow", function(self)
	self:SetScript("OnShow", function(self)
		self:SetPoint("TOPLEFT", -12, 8)
		self:refresh()
	end)
	self:SetPoint("TOPLEFT", -12, 8)

	local lsfdd = LibStub("LibSFDropDown-1.5")

	self.addonName = ("%s_ADDON_"):format(addon:upper())
	StaticPopupDialogs[self.addonName.."NEW_PROFILE"] = {
		text = addon..": "..L["New profile"],
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 48,
		editBoxWidth = 350,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(self, cb) cb(self) end,
		EditBoxOnEnterPressed = function(self)
			StaticPopup_OnClick(self:GetParent(), 1)
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self)
			self.EditBox:SetText(UnitName("player").." - "..GetRealmName())
			self.EditBox:HighlightText()
		end,
	}
	local function profileExistsAccept(popup, data)
		if not popup then return end
		popup:Hide()
		config:createProfile(data)
	end
	StaticPopupDialogs[self.addonName.."PROFILE_EXISTS"] = {
		text = addon..": "..L["A profile with the same name exists."],
		button1 = OKAY,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = profileExistsAccept,
		OnCancel = profileExistsAccept,
	}
	StaticPopupDialogs[self.addonName.."DELETE_PROFILE"] = {
		text = addon..": "..L["Are you sure you want to delete profile %s?"],
		button1 = DELETE,
		button2 = CANCEL,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(self, cb) cb() end,
	}

	-- ADDON INFO
	local info = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	info:SetPoint("TOPLEFT", 40, 20)
	info:SetTextColor(.5, .5, .5, 1)
	info:SetJustifyH("RIGHT")
	info:SetText(("%s %s: %s"):format(C_AddOns.GetAddOnMetadata(addon, "Version"), L["author"], C_AddOns.GetAddOnMetadata(addon, "Author")))

	-- TITLE
	local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetJustifyH("LEFT")
	title:SetText(L["%s Configuration"]:format(addon))

	-- PROFILES COMBOBOX
	local profilesCombobox = lsfdd:CreateStretchButton(config, 150, 22)
	profilesCombobox:SetPoint("TOPRIGHT", -16, -12)

	profilesCombobox:ddSetInitFunc(function(self, level)
		local info = {}

		if level == 1 then
			local function removeProfile(btn)
				config:removeProfile(btn.value)
			end

			local function selectProfile(btn)
				config:setProfile(btn.value)
			end

			info.list = {}
			for i, profile in ipairs(config.profiles) do
				local subInfo = {
					text = profile.isDefault and profile.name.." "..DARKGRAY_COLOR:WrapTextInColorCode(DEFAULT) or profile.name,
					value = profile.name,
					checked = profile.name == config.currentProfile.name,
					func = selectProfile,
				}
				if #config.profiles > 1 then
					subInfo.remove = removeProfile
				end
				tinsert(info.list, subInfo)
			end
			self:ddAddButton(info, level)
			info.list = nil

			self:ddAddSeparator(level)

			info.keepShownOnClick = true
			info.notCheckable = true
			info.hasArrow = true
			info.text = L["New profile"]
			self:ddAddButton(info, level)

			if not config.currentProfile.isDefault then
				info.keepShownOnClick = nil
				info.hasArrow = nil
				info.text = L["Set as default"]
				info.func = function()
					for _, profile in ipairs(config.profiles) do
						profile.isDefault = nil
					end
					config.currentProfile.isDefault = true
				end
				self:ddAddButton(info, level)
			end
		else
			info.notCheckable = true

			info.text = L["Create"]
			info.func = function() config:createProfile() end
			self:ddAddButton(info, level)

			info.text = L["Copy current"]
			info.func = function() config:createProfile(true) end
			self:ddAddButton(info, level)
		end
	end)

	-- PROFILES TEXT
	local profilesText = config:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	profilesText:SetPoint("RIGHT", profilesCombobox, "LEFT", -5, 0)
	profilesText:SetText(L["Profile"])

	-- PREVIEW
	self.previewBg = self:CreateTexture(nil, "BACKGROUND") -- bg
	self.previewBg:SetTexture("Interface/ChatFrame/ChatFrameBackground")
	self.previewBg:SetVertexColor(.1, .1, .1, .5)
	self.previewBg:SetSize(128, 128)
	self.previewBg:SetPoint("TOPLEFT", 16, -115)
	self.previewBg.glow = self:CreateTexture(nil, "BORDER") -- glow
	self.previewBg.outline = self:CreateTexture(nil, "ARTWORK") -- outline
	self.previewBg.cursor = self:CreateTexture(nil, "OVERLAY") -- cursor

	-- PREVIEW CONTROL
	local function controlBtnClick(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		if self.controlBtnChecked then
			self.controlBtnChecked.check:Hide()
		end
		self.controlBtnChecked = btn
		btn.check:Show()

		local isCursor = btn.key == nil
		self.opacityKey = isCursor and "opacity" or btn.key.."Opacity"
		self.colorKey = isCursor and "color" or btn.key.."Color"
		self.useClassColorKey = isCursor and "useClassColor" or btn.key.."UseClassColor"
		self:refresh()
		self.sizeCombobox:SetEnabled(isCursor)
		self.changeCursorSize:SetEnabled(isCursor)
		self.autoScaleCheckbox:SetEnabled(isCursor)
	end

	self.outlineBtn = CreateFrame("BUTTON", nil, self, "CursorModTextureButtonTemplate")
	self.outlineBtn:SetSize(22, 22)
	self.outlineBtn:SetPoint("BOTTOM", self.previewBg, "TOP", 0, 1)
	self.outlineBtn:SetScript("OnClick", controlBtnClick)
	self.outlineBtn.cursor:SetAlpha(.75)
	self.outlineBtn.key = "outline"

	self.cursorBtn = CreateFrame("BUTTON", nil, self, "CursorModTextureButtonTemplate")
	self.cursorBtn:SetSize(22, 22)
	self.cursorBtn:SetPoint("RIGHT", self.outlineBtn, "LEFT", -1, 0)
	self.cursorBtn:SetScript("OnClick", controlBtnClick)

	self.glowBtn = CreateFrame("BUTTON", nil, self, "CursorModTextureButtonTemplate")
	self.glowBtn:SetSize(22, 22)
	self.glowBtn:SetPoint("LEFT", self.outlineBtn, "RIGHT", 1, 0)
	self.glowBtn:SetScript("OnClick", controlBtnClick)
	self.glowBtn.cursor:SetAlpha(.35)
	self.glowBtn.key = "glow"

	-- TEXTURE SELECT
	local function textureBtnClick(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		if self.textureBtn[self.pConfig.texPoint] then
			self.textureBtn[self.pConfig.texPoint].check:Hide()
		end
		btn.check:Show()
		self.pConfig.texPoint = btn.id
		self:setCursorSettings()
		self.cursorBtn:Click()
	end

	self.textureBtn = {}
	local function createTextureButton(id)
		local btn = CreateFrame("BUTTON", nil, self, "CursorModTextureSelectTemplate")

		if id == 1 then
			btn:SetPoint("BOTTOMLEFT", self.previewBg, "TOPLEFT", 0, 30)
		else
			btn:SetPoint("LEFT", self.textureBtn[id - 1], "RIGHT")
		end

		btn.id = id
		self:setCursorTex(btn, 22, id)
		btn:SetScript("OnClick", textureBtnClick)
		tinsert(self.textureBtn, btn)
	end

	for i = 1, #self.textures do
		createTextureButton(i, self:getTexInfo(i))
	end

	-- SIZE COMBOBOX
	self.sizeCombobox = lsfdd:CreateButton(self)
	self.sizeCombobox:SetPoint("TOPLEFT", self.previewBg, "TOPRIGHT", 30, 3)

	self.sizeCombobox:ddSetInitFunc(function(self, level)
		local info = {}
		for i = 0, #config.sizes do
			local size = config.sizes[i]
			info.text = size.."x"..size
			info.value = i
			info.func = function(btn)
				config.pConfig.size = btn.value
				config:setCursorSettings()
				self:ddSetSelectedValue(btn.value)
			end
			self:ddAddButton(info, level)
		end
	end)

	-- CHANGE CURSOR SIZE
	self.changeCursorSize = CreateFrame("CheckButton", nil, self, "CursorModCheckButtonTemplate")
	self.changeCursorSize:SetPoint("LEFT", self.sizeCombobox, "RIGHT", 10, 0)
	self.changeCursorSize.Text:SetText(L["Resize cursor"])
	self.changeCursorSize:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
		PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		config.pConfig.changeCursorSize = checked
		config:setCursorSettings()
	end)

	-- SCALE
	self.scaleSlider = CreateFrame("FRAME", nil, self, "CursorModSliderTemplate")
	self.scaleSlider:SetPoint("TOPLEFT", self.sizeCombobox, "BOTTOMLEFT", 0, -15)
	self.scaleSlider.text:SetText(L["Scale"])
	self.scaleSlider.RightText:Show()
	self.scaleSlider.OnSliderValueChanged = function(self, value)
		value = math.floor(value * 100 + .5) / 100
		config.pConfig.scale = value
		config:setCursorSettings()
		self.RightText:SetText(value)
	end
	self.scaleSlider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, self.scaleSlider.OnSliderValueChanged, self.scaleSlider)

	-- AUTO SCALE
	self.autoScaleCheckbox = CreateFrame("CheckButton", nil, self, "CursorModCheckButtonArtTemplate")
	self.autoScaleCheckbox:SetPoint("RIGHT", self.scaleSlider, "LEFT", 0, 0)
	self.autoScaleCheckbox.tooltipOwnerPoint = "ANCHOR_TOP"
	self.autoScaleCheckbox.tooltipText = L["Autoscaling"]
	self.autoScaleCheckbox:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
		PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		config.scaleSlider:SetEnabled(not checked)
		config.pConfig.autoScale = checked
		config:setAutoScale()
	end)

	-- OPACITY
	local opacitySlider = CreateFrame("SLIDER", nil, self, "CursorModSliderTemplate")
	opacitySlider:SetPoint("TOPLEFT", self.scaleSlider, "BOTTOMLEFT", 0, -15)
	opacitySlider.text:SetText(L["Opacity"])
	opacitySlider.RightText:Show()
	opacitySlider.OnSliderValueChanged = function(self, value)
		value = math.floor(value * 100 + .5) / 100
		config.pConfig[config.opacityKey] = value
		config:setCursorSettings()
		self.RightText:SetText(value)
	end
	opacitySlider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, opacitySlider.OnSliderValueChanged, opacitySlider)

	-- COLOR
	local colorBtn =  CreateFrame("BUTTON", nil, self)
	colorBtn:SetSize(30, 30)
	colorBtn:SetPoint("TOPLEFT", opacitySlider, "BOTTOMLEFT", -3, -15)
	colorBtn:SetNormalTexture("Interface/ChatFrame/ChatFrameColorSwatch")
	local colorTex = colorBtn:GetNormalTexture()

	colorBtn.swatchFunc = function()
		colorTex:SetVertexColor(ColorPickerFrame:GetColorRGB())
		config.pConfig[config.colorKey] = {ColorPickerFrame:GetColorRGB()}
		config:setCursorSettings()
	end
	colorBtn.cancelFunc = function(color)
		config.pConfig[config.colorKey] = {color.r, color.g, color.b}
		colorTex:SetVertexColor(color.r, color.g, color.b)
		config:setCursorSettings()
	end
	colorBtn:SetScript("OnClick", function(btn)
		btn.r, btn.g, btn.b = unpack(config.pConfig[config.colorKey])
		if OpenColorPicker then
			OpenColorPicker(btn)
		else
			ColorPickerFrame:SetupColorPickerAndShow(btn)
		end
	end)

	local btnResetColor = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	btnResetColor:SetSize(60, 22)
	btnResetColor:SetPoint("LEFT", colorBtn, "RIGHT", 3, 0)
	btnResetColor:SetText(RESET)
	btnResetColor:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		colorTex:SetVertexColor(1, 1, 1)
		config.pConfig[config.colorKey] = {1, 1, 1}
		config:setCursorSettings()
	end)

	-- USE CLASS COLOR
	self.useClassColor = CreateFrame("CheckButton", nil, self, "CursorModCheckButtonTemplate")
	self.useClassColor:SetPoint("LEFT", btnResetColor, "RIGHT", 10, 0)
	self.useClassColor.Text:SetText(L["Use class color"])
	self.useClassColor:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
		PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		colorBtn:SetEnabled(not checked)
		btnResetColor:SetEnabled(not checked)
		config.pConfig[config.useClassColorKey] = checked
		config:setCursorSettings()
	end)

	-- SHOW ONLY IN COMBAT
	local showOnlyInCombat = CreateFrame("CheckButton", nil, self, "CursorModCheckButtonTemplate")
	showOnlyInCombat:SetPoint("TOPLEFT", self.previewBg, "BOTTOMLEFT", 0, -15)
	showOnlyInCombat.Text:SetText(L["Show only in combat"])
	showOnlyInCombat:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
		PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		config.pConfig.showOnlyInCombat = checked
		config:setCombatTracking()
	end)

	-- SHOW ALWAYS
	local showAlways = CreateFrame("CheckButton", nil, self, "CursorModCheckButtonTemplate")
	showAlways:SetPoint("LEFT", showOnlyInCombat.Text, "RIGHT", 10, 1)
	showAlways.Text:SetText(L["Show always"])
	showAlways:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
		PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		config.pConfig.showAlways = checked
		config:setShowAlways()
	end)

	-- CursorFreelookStartDelta
	local cursorDelta = CreateFrame("SLIDER", nil, self, "CursorModSliderTemplate")
	cursorDelta:SetPoint("TOPLEFT", showOnlyInCombat, "BOTTOMLEFT", 0, -15)
	cursorDelta.text:SetText(L["Cursor freelook start delta"])
	cursorDelta.RightText:Show()
	cursorDelta.OnSliderValueChanged = function(self, value)
		value = math.floor(value * 10000 + .5) / 10000
		config.pConfig.lookStartDelta = value
		config:setCursorSettings()
		self.RightText:SetText(value)
	end
	cursorDelta:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, cursorDelta.OnSliderValueChanged, cursorDelta)

	-- REFRESH
	function self:refresh()
		profilesCombobox:SetText(self.currentProfile.name)

		for i = 1, #self.textureBtn do
			self.textureBtn[i].check:Hide()
		end
		if self.textureBtn[self.pConfig.texPoint] then
			self.textureBtn[self.pConfig.texPoint].check:Show()
		end

		self.sizeCombobox:ddSetSelectedValue(self.pConfig.size)
		local size = self.sizes[self.pConfig.size]
		self.sizeCombobox:ddSetSelectedText(size.."x"..size)

		self.changeCursorSize:SetChecked(self.pConfig.changeCursorSize)

		local value = math.floor(self.pConfig.scale * 100 + .5) / 100
		local options = Settings.CreateSliderOptions(.1, 2, .01)
		self.scaleSlider:Init(value, options.minValue, options.maxValue, options.steps, options.formatters)
		self.scaleSlider.RightText:SetText(value)
		self.scaleSlider:SetEnabled(not self.pConfig.autoScale and self.opacityKey == "opacity")

		self.autoScaleCheckbox:SetChecked(self.pConfig.autoScale)

		options = Settings.CreateSliderOptions(0, 1, .01)
		opacitySlider:Init(self.pConfig[self.opacityKey], options.minValue, options.maxValue, options.steps, options.formatters)
		opacitySlider.RightText:SetText(self.pConfig[self.opacityKey])

		colorBtn:SetEnabled(not self.pConfig[self.useClassColorKey])
		colorTex:SetVertexColor(unpack(self.pConfig[self.colorKey]))

		btnResetColor:SetEnabled(not self.pConfig[self.useClassColorKey])

		self.useClassColor:SetChecked(self.pConfig[self.useClassColorKey])

		showOnlyInCombat:SetChecked(self.pConfig.showOnlyInCombat)
		
		showAlways:SetChecked(self.pConfig.showAlways)

		options = Settings.CreateSliderOptions(0, .01, .0001)
		cursorDelta:Init(self.pConfig.lookStartDelta, options.minValue, options.maxValue, options.steps, options.formatters)
		cursorDelta.RightText:SetText(self.pConfig.lookStartDelta)
	end
	self.cursorBtn:Click()

	-- SET SETTINGS
	self:setCursorSettings()
end)


function config:setAutoScale()
	if self.pConfig.autoScale then
		local width
		if GetCVarBool("gxMaximize") then
			width = C_VideoOptions.GetGameWindowSizes(GetCVar("gxMonitor"), true)[1].x
		else
			width = GetPhysicalScreenSize()
		end
		self.autoScale = WorldFrame:GetWidth() / width / UIParent:GetScale()
	else
		self.autoScale = nil
	end

	self:setCursorSettings()
end
config.UI_SCALE_CHANGED = config.setAutoScale


function config:setCombatTracking()
	if self.pConfig.showOnlyInCombat then
		self.cursorFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
		self.cursorFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		self.cursorFrame[3] = not InCombatLockdown()
	else
		self.cursorFrame:UnregisterEvent("PLAYER_REGEN_DISABLED")
		self.cursorFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self.cursorFrame[3] = false
	end
	self:setShowAlways()
end


function config:setShowAlways()
	if self.pConfig.showAlways then
		self.cursorFrame:UnregisterEvent("PLAYER_STARTED_LOOKING")
		self.cursorFrame:UnregisterEvent("PLAYER_STARTED_TURNING")
		self.cursorFrame:UnregisterEvent("PLAYER_STOPPED_LOOKING")
		self.cursorFrame:UnregisterEvent("PLAYER_STOPPED_TURNING")
		self.cursorFrame:SetShown(not (self.pConfig.showOnlyInCombat and self.cursorFrame[3]))
		self.cursorFrame:SetScript("OnUpdate", self.cursorFrame:GetScript("OnShow"))
	else
		self.cursorFrame:SetScript("OnUpdate", nil)
		self.cursorFrame:RegisterEvent("PLAYER_STARTED_LOOKING")
		self.cursorFrame:RegisterEvent("PLAYER_STARTED_TURNING")
		self.cursorFrame:RegisterEvent("PLAYER_STOPPED_LOOKING")
		self.cursorFrame:RegisterEvent("PLAYER_STOPPED_TURNING")
		self.cursorFrame:Hide()
	end
end


function config:getTexInfo(index)
	local texture = self.textures[index] or self.textures[1]
	if type(texture) == "table" then
		if type(texture[1]) == "table" then
			texture = texture[self.pConfig.size + 1]
		end
		return unpack(texture)
	else
		return texture, 0,1,0,1
	end
end


local function setTex(tex, rFrame, size, path, l,r,t,b,w,h,x,y)
	local atlasInfo = C_Texture.GetAtlasInfo(path)
	if atlasInfo then
		tex:SetAtlas(path)
	else
		tex:SetTexture(path)
	end
	if l > 1 then
		w,h,x,y = l,r,t,b
		l,r,t,b = 0,1,0,1
	end
	tex:SetTexCoord(l,r,t,b)
	tex:ClearAllPoints()
	tex:SetPoint("CENTER", rFrame, x,y)
	if w then
		tex:SetSize(w,h)
		tex:SetScale(size / 32)
	else
		tex:SetSize(size, size)
		tex:SetScale(1)
	end
end


function config:getColor(key)
	if self.pConfig[key and key.."UseClassColor" or "useClassColor"] then
		return C_ClassColor.GetClassColor(select(2, UnitClass("player"))):GetRGB()
	else
		return unpack(self.pConfig[key and key.."Color" or "color"])
	end
end


function config:setCursorTex(bg, size, index, hasColor)
	local path, left, right, top, bottom, glow, outline = self:getTexInfo(index)

	if glow then
		setTex(bg.glow, bg, size, unpack(glow))
		bg.glow:SetAlpha(self.pConfig.glowOpacity)
		bg.glow:Show()

		setTex(bg.outline, bg, size, unpack(outline))
		bg.outline:SetAlpha(self.pConfig.outlineOpacity)
		bg.outline:Show()
	else
		bg.glow:Hide()
		bg.outline:Hide()
	end

	setTex(bg.cursor, bg, size, path, left, right, top, bottom)
	bg.cursor:SetAlpha(self.pConfig.opacity)

	if hasColor then
		if glow then
			bg.glow:SetVertexColor(self:getColor("glow"))
			bg.outline:SetVertexColor(self:getColor("outline"))
		end
		bg.cursor:SetVertexColor(self:getColor())
	end
end


function config:setCursorSettings()
	local scale = self.autoScale or self.pConfig.scale
	local size = (self.sizes[self.pConfig.size] or 32) * scale

	self:setCursorTex(self.cursorFrame, size, self.pConfig.texPoint, true)
	self.cursorFrame:SetSize(size, size)
	self.cursorFrame.scale = UIParent:GetScale()

	local cursorSizePreferred = tonumber(GetCVar("cursorSizePreferred"))
	if self.pConfig.changeCursorSize then
		if cursorSizePreferred ~= self.pConfig.size then
			SetCVar("cursorSizePreferred", self.pConfig.size)
		end
	elseif cursorSizePreferred ~= -1 then
		SetCVar("cursorSizePreferred", -1)
	end
	SetCVar("CursorFreelookStartDelta", self.pConfig.lookStartDelta)

	if self.previewBg then
		if size > 128 then size = 128 end
		local path, l,r,t,b, glow, outline = self:getTexInfo(self.pConfig.texPoint)
		if glow then
			setTex(self.cursorBtn.cursor, self.cursorBtn, 16, path, l,r,t,b)
			self.cursorBtn:Show()
			setTex(self.outlineBtn.cursor, self.outlineBtn, 16, unpack(outline))
			self.outlineBtn:Show()
			setTex(self.glowBtn.cursor, self.glowBtn, 16, unpack(glow))
			self.glowBtn:Show()
		else
			self.cursorBtn:Hide()
			self.outlineBtn:Hide()
			self.glowBtn:Hide()
		end
		self:setCursorTex(self.previewBg, size, self.pConfig.texPoint, true)
	end

	if self.ldbButton then
		self.ldbButton.icon, self.ldbButton.iconCoords = self:getLdbIcon()
	end
end


-- ADD CATEGORY
local category, layout = Settings.RegisterCanvasLayoutCategory(config, addon)
-- layout:AddAnchorPoint("TOPLEFT", -12, 8)
-- layout:AddAnchorPoint("BOTTOMRIGHT", 0, 0)
Settings.RegisterAddOnCategory(category)


-- OPEN CONFIG
function config:openConfig()
	if SettingsPanel:IsVisible() and self:IsVisible() then
		if InCombatLockdown() then return end
		HideUIPanel(SettingsPanel)
	else
		Settings.OpenToCategory(category:GetID(), addon)
	end
end


SLASH_CURSORMODCONFIG1 = "/cursormod"
SlashCmdList["CURSORMODCONFIG"] = function() config:openConfig() end


-- ADD BUTTON TO DATABROKER
function config:PLAYER_LOGIN()
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
	local ldb = LibStub("LibDataBroker-1.1", true)
	if ldb then
		function self:getLdbIcon()
			local texPath, left, right, top, bottom = self:getTexInfo(self.pConfig.texPoint)
			local atlasInfo = C_Texture.GetAtlasInfo(texPath)
			if atlasInfo or left > 1 then
				local h = (left - 32) / 2
				local v = (right - 32) / 2
				local kLeft = (h - top) / left
				local kRight = (h + top) / left
				local kTop = (v + bottom) / right
				local kBottom = (v - bottom) / right
				if atlasInfo then
					local width = atlasInfo.rightTexCoord - atlasInfo.leftTexCoord
					local height = atlasInfo.bottomTexCoord - atlasInfo.topTexCoord
					texPath = atlasInfo.file
					left = atlasInfo.leftTexCoord + width * kLeft
					right = atlasInfo.rightTexCoord - width * kRight
					top = atlasInfo.topTexCoord + height * kTop
					bottom = atlasInfo.bottomTexCoord - height * kBottom
				else
					left = kLeft
					right = 1 - kRight
					top = kTop
					bottom = 1 - kBottom
				end
			end

			return texPath, {left, right - (right - left) * .1, top, bottom - (bottom - top) * .1}
		end

		local updateFrame = CreateFrame("FRAME")
		local icon, coords = self:getLdbIcon()
		local r, g, b = unpack(self.pConfig.color)
		local r2, g2, b2 = 1, 1, 1

		self.ldbButton = ldb:NewDataObject("CursorMod", {
			type = "launcher",
			text = "CursorMod",
			icon = icon,
			iconCoords = coords,
			iconR = r,
			iconG = g,
			iconB = b,
			OnTooltipShow = function(tooltip)
				tooltip:SetText(("%s (|cffff7f3f%s|r)"):format(addon, C_AddOns.GetAddOnMetadata(addon, "Version")))
			end,
			OnClick = function() self:openConfig() end,
			OnEnter = function()
				updateFrame:SetScript("OnUpdate", function(_, elaps)
					elaps = elaps / 2
					if r > 1 then r2 = -1
					elseif r < 0 then r2 = 1 end
					r = r + r2 * (elaps - elaps / random(3))
					if g > 1 then g2 = -1
					elseif g < 0 then g2 = 1 end
					g = g + g2 * elaps
					if b > 1 then b2 = -1
					elseif b < 0 then b2 = 1 end
					b = b + b2 * (elaps + elaps / random(3))
					self.ldbButton.iconR = r
					self.ldbButton.iconG = g
					self.ldbButton.iconB = b
				end)
			end,
			OnLeave = function()
				updateFrame:SetScript("OnUpdate", nil)
			end,
		})
	end
end