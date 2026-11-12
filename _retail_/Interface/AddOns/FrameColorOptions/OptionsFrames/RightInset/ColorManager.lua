-- The Color Manager
-- This is for the most part hard coded as there is no real pattern.
local _, private = ...
local FrameColor = _G["FrameColor"]

-- Lua API
local table_sort = table.sort
local table_insert = table.insert

local function updateCollapseButton(button, node)
  local data = node:GetData()
  if FrameColor.db.profile.protected.leadingColors[data.category].enabled then
    button:Enable()
    button.name:SetTextColor(GameFontNormalLeft:GetTextColor())
  else
    button:Disable()
    node:SetCollapsed(true)
    button.name:SetTextColor(0.5, 0.5, 0.5, 1)
  end

  button.Right:SetAtlas(button:IsCollapsed() and "Options_ListExpand_Right" or "Options_ListExpand_Right_Expanded", TextureKitConstants.UseAtlasSize)
  button.HighlightRight:SetAtlas(button:IsCollapsed() and "Options_ListExpand_Right" or "Options_ListExpand_Right_Expanded", TextureKitConstants.UseAtlasSize)
end

-- Top level data initializer. This is the initializer for the expandable module buttons.
local function topLevelDataInitializer(button, node)
  local data = node:GetData()

  updateCollapseButton(button, node)

  button.name:SetText(data.name)

  button:SetScript("OnClick", function(self)
    node:ToggleCollapsed()
    updateCollapseButton(self, node)
  end)

  button.enableButton:SetChecked(FrameColor.db.profile.protected.leadingColors[data.category].enabled)

  button.enableButton:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    FrameColor.db.profile.protected.leadingColors[data.category].enabled = isChecked
    FrameColor:ReloadAllSkinsOfCategory(data.category)

    updateCollapseButton(button, node)
  end)
end

local function updateColorButton(button, data)
  local leadingColorObj = FrameColor.db.profile.protected.leadingColors[data.category].colors[data.key]
  button.followClassColor:SetChecked(leadingColorObj.followClassColor)
  button.colorPicker:SetEnabled(leadingColorObj.followClassColor ~= true)
  if leadingColorObj.followClassColor then
    local className = string.lower(select(2, UnitClass("player")))
    button.colorPicker.backgroundTexture:SetAtlas("classicon-" .. className)
  else
    button.colorPicker.backgroundTexture:SetColorTexture(unpack(leadingColorObj.rgbaValues))
  end
end

-- Nested data initializer.
local function colorButtonInitializer(button, node)
  -- Get the data for the node.
  local data = node:GetData()

  -- Update the button.
  updateColorButton(button, data)

  -- Set the name of the color.
  button.name:SetText(data.name)

  -- Follow class color toggle button.
  button.followClassColor:SetScript("OnClick", function(self)
    FrameColor.db.profile.protected.leadingColors[data.category].colors[data.key]["followClassColor"] = self:GetChecked()
    FrameColor:ReloadAllSkinsOfCategory(data.category)
    updateColorButton(button, data)
  end)

  -- Color Picker
  button.colorPicker:SetScript("OnClick", function(self)
    -- Callback when the user changes the color.
    local function onColorChanged()
      local r, g, b = ColorPickerFrame:GetColorRGB()
      local a = ColorPickerFrame:GetColorAlpha()
      button.colorPicker.backgroundTexture:SetColorTexture(r, g, b, a)
      FrameColor.db.profile.protected.leadingColors[data.category].colors[data.key].rgbaValues = {r, g, b, a}
      FrameColor:ReloadAllSkinsOfCategory(data.category)
    end

    -- Save the old colors to restore and set the inital color picker color.
    local oldR, oldG, oldB, oldA = unpack(FrameColor.db.profile.protected.leadingColors[data.category].colors[data.key].rgbaValues)
    local function onCancel()
      button.colorPicker.backgroundTexture:SetColorTexture(oldR, oldG, oldB, oldA)
      FrameColor.db.profile.protected.leadingColors[data.category].colors[data.key].rgbaValues = {oldR, oldG, oldB, oldA}
      FrameColor:ReloadAllSkinsOfCategory(data.category)
    end

    -- Set the color picker options.
    local colorPickerOptions = {
      swatchFunc = onColorChanged,
      opacityFunc = onColorChanged,
      cancelFunc = onCancel,
      hasOpacity = data.hasAlpha,
      opacity = oldA,
      r = oldR,
      g = oldG,
      b = oldB,
    }

    -- Show the color picker frame with the options.
    ColorPickerFrame:Hide() -- This is for the case that the user clicks another color button while the color picker is still open. Only OnShow will set the frame, and OnShow will only fire if it was previously hidden.
    ColorPickerFrame:SetupColorPickerAndShow(colorPickerOptions)
  end)
end

-- This function will be used to sort the modules by the Order key.
local function sortByOrderKey(inputTable)
  local orderedTable = {}
  local noOrderKey = {}


  for key, value in pairs(inputTable) do
    if not value.order then
      table_insert(noOrderKey, value)
    else
      table_insert(orderedTable, value)
    end
    value.key = key -- The key is needed to save values to the db.
  end

  -- Sort modules by order value
  table_sort(orderedTable, function(a, b) return a.order < b.order end)

  for _, value in pairs(noOrderKey) do
    table_insert(orderedTable, value)
  end

  return orderedTable
end


local function customElementFactory(factory, node)
  local data = node:GetData()
  if data.template == "FrameColorOptions_ColorButtonTemplate" then
    factory(data.template, colorButtonInitializer)
  elseif data.template == "" then

  else
    factory(data.template, topLevelDataInitializer)
  end
end

-- This function will be used to reset the elements of the ScrollView.
local function resetter(button, node)
  local data = node:GetData()
  if data.template == "FrameColorOptions_ModuleButtonTemplate" then
    updateCollapseButton(button, node)
  end
end

function private:PopulateRightInset_ColorManager()
  local DataProvider = CreateTreeDataProvider()

  local leadingColorList = sortByOrderKey(CopyTable(FrameColor.db.profile.protected.leadingColors))

  for _, leadingColor in ipairs(leadingColorList) do
    -- Define the top level data.
    local topLevelData = {
      name = leadingColor.name,
      category = leadingColor.key,
      template = "FrameColorOptions_ModuleButtonTemplate",
    }
    local topLevelNode = DataProvider:Insert(topLevelData)
    topLevelNode:SetCollapsed(true)

    -- Colors
    -- Loop through all colors of the module to define the nested data.
    local orderedColorList = sortByOrderKey(leadingColor.colors)
    for _, color in ipairs(orderedColorList) do
      local nestedData = {
        key = color.key, -- The key is needed to save values to the db.
        category = leadingColor.key, -- The name of the module to access the db.
        name = color.name, -- The name of the color to show in the menu.
        hasAlpha = color.hasAlpha or false,
        template = "FrameColorOptions_ColorButtonTemplate",
      }
      topLevelNode:Insert(nestedData)
    end
  end


  self.SetScrollViewMethods_RightInset(customElementFactory, resetter)
  self.SetDataProvider_RightInset(DataProvider)
end
