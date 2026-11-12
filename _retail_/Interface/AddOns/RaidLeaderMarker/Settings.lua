local addonName, addon = ...

-- Utility functions

local function CreateCheckbox(category, tableName, name, label, tooltip, onChange)
	local table = RaidLeaderMarkerDB[tableName]
  local setting = Settings.RegisterAddOnSetting(category, addonName.."_"..tableName.."_"..name, name, table, "boolean", label, table[name] or false)

  if onChange then
    setting:SetValueChangedCallback(onChange)
  end

  Settings.CreateCheckbox(category, setting, tooltip)
end

local function CreateDropdown(category, tableName, name, label, tooltip, items, onChange)
	local table = RaidLeaderMarkerDB[tableName]
  local setting = Settings.RegisterAddOnSetting(category, addonName.."_"..tableName.."_"..name, name, table, "string", label, table[name] or items[1].value)

  if onChange then
    setting:SetValueChangedCallback(onChange)
  end

  local function GetOptions()
    local container = Settings.CreateControlTextContainer()
    for _, item in ipairs(items) do
      container:Add(item.value, item.label)
    end
    return container:GetData()
  end

  Settings.CreateDropdown(category, setting, GetOptions, tooltip)
end

local function CreateSlider(category, tableName, name, label, tooltip, minValue, maxValue, step, onChange)
	local table = RaidLeaderMarkerDB[tableName]
  local setting = Settings.RegisterAddOnSetting(category, addonName.."_"..tableName.."_"..name, name, table, "number", label, table[name] or minValue)

  if onChange then
    setting:SetValueChangedCallback(onChange)
  end

  local options = Settings.CreateSliderOptions(minValue, maxValue, step)
  options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
  Settings.CreateSlider(category, setting, options, tooltip)
end

-- Initialization of the settings panel

local anchorOptions = {
  { value = "TOPLEFT", label = "Top Left" },
  { value = "TOP", label = "Top" },
  { value = "TOPRIGHT", label = "Top Right" },
  { value = "LEFT", label = "Left" },
  { value = "CENTER", label = "Center" },
  { value = "RIGHT", label = "Right" },
  { value = "BOTTOMLEFT", label = "Bottom Left" },
  { value = "BOTTOM", label = "Bottom" },
  { value = "BOTTOMRIGHT", label = "Bottom Right" },
}

local function CreateSettingCategory(tableName, settingsCategory, settingsLayout, name, tooltip)
  settingsLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer(name, tooltip))

  -- Checkbox to enable/disable the icon
  CreateCheckbox(settingsCategory, tableName, "enabled", "Enable", "Toggle the display of the icon.", function(setting, value)
    RaidLeaderMarkerDB[tableName].enabled = value
    addon.UpdateAll()
  end)

  -- Dropdown for anchor point
  CreateDropdown(settingsCategory, tableName, "anchor", "Anchor Point", "Choose the anchor point for the icon.", anchorOptions, function(setting, value)
    RaidLeaderMarkerDB[tableName].anchor = value
    RaidLeaderMarkerDB[tableName].offsetX = 0
    RaidLeaderMarkerDB[tableName].offsetY = 0
    addon.UpdateAll()
  end)

  -- Slider for offsetX
  CreateSlider(settingsCategory, tableName, "offsetX", "Offset X", "Horizontal offset from the anchor.", -50, 50, 1, function(setting, value)
    RaidLeaderMarkerDB[tableName].offsetX = value
    addon.UpdateAll()
  end)

  -- Slider for offsetY
  CreateSlider(settingsCategory, tableName, "offsetY", "Offset Y", "Vertical offset from the anchor.", -50, 50, 1, function(setting, value)
    RaidLeaderMarkerDB[tableName].offsetY = value
    addon.UpdateAll()
  end)

  -- Slider for size
  CreateSlider(settingsCategory, tableName, "size", "Icon Size", "Size of the icon.", 16, 32, 1, function(setting, value)
    RaidLeaderMarkerDB[tableName].size = value
    addon.UpdateAll()
  end)
end

local function InitializeSettings()
  local settingsCategory, settingsLayout = Settings.RegisterVerticalLayoutCategory("Raid Leader Marker")

	CreateSettingCategory("leaderIcon", settingsCategory, settingsLayout, "Leader icon", "Configure the leader icon's position and size.")
	CreateSettingCategory("targetMarker", settingsCategory, settingsLayout, "Target marker", "Configure the target marker's position and size.")

  Settings.RegisterAddOnCategory(settingsCategory)
end

addon.InitializeSettings = InitializeSettings
