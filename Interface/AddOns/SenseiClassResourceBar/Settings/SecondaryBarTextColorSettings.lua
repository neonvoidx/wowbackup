local _, addonTable = ...

local featureId = "SCRB_SECONDARY_BAR_TEXT_COLOR"

addonTable.AvailableFeatures = addonTable.AvailableFeatures or {}
table.insert(addonTable.AvailableFeatures, featureId)

addonTable.FeaturesMetadata = addonTable.FeaturesMetadata or {}
addonTable.FeaturesMetadata[featureId] = {
	panel = "SCRBSecondaryBarTextColorSettings",
	searchTags = { "Text Colors" },
}

SCRBSecondaryBarTextColorSettingsMixin = {
    TextData = {
		{
			text  = "Resource Number",
			textId = addonTable.TextId.ResourceNumber,
		},
		{
			text  = "Resource Charge Timer",
			textId = addonTable.TextId.ResourceChargeTimer,
		},
	},
}

function SCRBSecondaryBarTextColorSettingsMixin:Init(initializer)
	if not SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.SecondaryResourceBar.frameName] then
		SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.SecondaryResourceBar.frameName] = {}
	end
	if not SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.SecondaryResourceBar.frameName]["TextColors"] then
		SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.SecondaryResourceBar.frameName]["TextColors"] = {}
	end

	self.categoryID = initializer.data.categoryID;

	for _, data in ipairs(SCRBSecondaryBarTextColorSettingsMixin.TextData) do
		initializer:AddSearchTags(data.text);
	end

	self.NewFeature:SetShown(not SenseiClassResourceBarDB["_Settings"]["NewFeaturesShown"][featureId])
	self.Header:SetText(addonTable.RegistereredBar.SecondaryResourceBar.editModeName or "Secondary Resource Bar")

	SenseiClassResourceBarDB["_Settings"]["NewFeaturesShown"][featureId] = true
end

function SCRBSecondaryBarTextColorSettingsMixin:OnLoad()
	self.ColorOverrideFramePool = CreateFramePool("FRAME", self.SCRBSecondaryBarTextColorSetting, "ColorOverrideTemplate", nil)
	self.colorOverrideFrames = {}

	local function ResetColorSwatches()
		for _, frame in ipairs(self.colorOverrideFrames) do
			SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.SecondaryResourceBar.frameName]["TextColors"][frame.data.textId] = nil -- Remove override
			addonTable.updateBars()

			local color = { r = 1, g = 1, b = 1 } -- Default
			if color then
				frame.Text:SetTextColor(CreateColor(color.r, color.g, color.b):GetRGB())
				frame.ColorSwatch.Color:SetVertexColor(CreateColor(color.r, color.g, color.b):GetRGB())
			end
		end
	end
	EventRegistry:RegisterCallback("Settings.Defaulted", ResetColorSwatches)

	local function CategoryDefaulted(_, category)
		if self.categoryID == category:GetID() then
			ResetColorSwatches()
		end
	end
	EventRegistry:RegisterCallback("Settings.CategoryDefaulted", CategoryDefaulted)

	for index, data in ipairs(SCRBSecondaryBarTextColorSettingsMixin.TextData) do
		local frame = self.ColorOverrideFramePool:Acquire()
		frame.layoutIndex = index
		self:SetupColorSwatch(frame, data)
		frame:Show()

		table.insert(self.colorOverrideFrames, frame)
	end
end

function SCRBSecondaryBarTextColorSettingsMixin:SetupColorSwatch(frame, data)
	frame.data = data

    frame.Text:SetText(frame.data.text)

	local color = addonTable:GetOverrideTextColor(addonTable.RegistereredBar.SecondaryResourceBar.frameName, frame.data.textId)
	if color then
		frame.Text:SetTextColor(CreateColor(color.r, color.g, color.b):GetRGB())
		frame.ColorSwatch.Color:SetVertexColor(CreateColor(color.r, color.g, color.b):GetRGB())
	end

	frame.ColorSwatch:SetScript("OnClick", function()
		self:OpenColorPicker(frame)
	end)
end

function SCRBSecondaryBarTextColorSettingsMixin:OpenColorPicker(frame)
	local info = UIDropDownMenu_CreateInfo()

	local overrideInfo = SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.SecondaryResourceBar.frameName]["TextColors"][frame.data.textId] -- Override

	local color = addonTable:GetOverrideTextColor(addonTable.RegistereredBar.SecondaryResourceBar.frameName, frame.data.textId)
	if color then
		info.r, info.g, info.b = color.r or 1, color.g or 1, color.b or 1
	end

	info.extraInfo = nil
	info.swatchFunc = function ()
		local r, g, b = ColorPickerFrame:GetColorRGB()
		frame.Text:SetTextColor(r, g, b)
		frame.ColorSwatch.Color:SetVertexColor(r, g, b)

		SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.SecondaryResourceBar.frameName]["TextColors"][frame.data.textId] = { r = r, g = g, b = b } -- Set override
		addonTable.updateBars()
	end

	info.cancelFunc = function ()
		local r, g, b = ColorPickerFrame:GetPreviousValues()
		frame.Text:SetTextColor(r, g, b)
		frame.ColorSwatch.Color:SetVertexColor(r, g, b)

		if overrideInfo then
			SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.SecondaryResourceBar.frameName]["TextColors"][frame.data.textId] = { r = r, g = g, b = b } -- Set override
		else
			SenseiClassResourceBarDB["_Settings"][addonTable.RegistereredBar.SecondaryResourceBar.frameName]["TextColors"][frame.data.textId] = nil -- Remove override
		end
		addonTable.updateBars()
	end

	ColorPickerFrame:SetupColorPickerAndShow(info)
end
