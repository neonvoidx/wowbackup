-- The Module List Loader.
local _, private = ...
local FrameColor = _G["FrameColor"]

-- Lua API
local table_sort = table.sort
local table_insert = table.insert
local string_find = string.find

local function updateCollapseButton(button, node)
  local data = node:GetData()
  if FrameColor:IsSkinEnabled(data.module) then
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
    updateCollapseButton(button, node)
  end)

  button.enableButton:SetChecked(FrameColor:IsSkinEnabled(data.module))

  button.enableButton:SetScript("OnClick", function()
    local isChecked = button.enableButton:GetChecked()
    FrameColor:DB_SetModuleKey(data.module, "enabled", isChecked)
    updateCollapseButton(button, node)
  end)
end

local function updateColorButton(button, data)
  local colorObj = FrameColor:DB_GetColorObj(data.module, data.key)
  button.lockColorButton:SetChecked(colorObj.lockedColor)
  button.followClassColor:SetChecked(colorObj.followClassColor)
  button.colorPicker:SetEnabled(colorObj.followClassColor ~= true)
  if colorObj.followClassColor then
    local className = string.lower(select(2, UnitClass("player")))
    button.colorPicker.backgroundTexture:SetAtlas("classicon-" .. className)
  else
    button.colorPicker.backgroundTexture:SetColorTexture(unpack(colorObj.rgbaValues))
  end
end

-- Nested data initializer. This is the initializer for the color entrys of each module.
local function colorButtonInitializer(button, node)
  -- Get the data for the node.
  local data = node:GetData()

  -- Update the button.
  updateColorButton(button, data)

  button.lockColorButton:SetScript("OnClick", function(self)
    FrameColor:DB_SetColorKey(data.module, data.key, "lockedColor", self:GetChecked())
    updateColorButton(button, data)
  end)

  -- Set the name of the color.
  button.name:SetText(data.name)

  -- Follow class color toggle button.
  button.followClassColor:SetScript("OnClick", function(self)
    FrameColor:DB_SetColorKey(data.module, data.key, "followClassColor", self:GetChecked())
    updateColorButton(button, data)
  end)

  -- Color Picker
  button.colorPicker:SetScript("OnClick", function(self)
    -- Callback when the user changes the color.
    local function onColorChanged()
      local r, g, b = ColorPickerFrame:GetColorRGB()
      local a = ColorPickerFrame:GetColorAlpha()
      button.colorPicker.backgroundTexture:SetColorTexture(r, g, b, a)
      FrameColor:DB_SetColor(data.module, data.key, r, g, b, a)
    end

    -- Save the old colors to restore and set the inital color picker color.
    local oldR, oldG, oldB, oldA = FrameColor:DB_GetColor(data.module, data.key)
    local function onCancel()
      button.colorPicker.backgroundTexture:SetColorTexture(oldR, oldG, oldB, oldA)
      FrameColor:DB_SetColor(data.module, data.key, oldR, oldG, oldB, oldA)
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

local function toggleButtonInitializer(button, node)
  -- Get the data for the node.
  local data = node:GetData()

  -- Set the name of the color.
  button.name:SetText(data.name)

  -- Set the initial toggle state.
  button.toggle:SetChecked(FrameColor:DB_GetToggleKey(data.module, data.key))

  -- Set the click behavior
  button.toggle:SetScript("OnClick", function(self)
    FrameColor:DB_SetToggleKey(data.module, data.key, self:GetChecked())
  end)
end

-- Custom element factory this will handle which initializer will be used based on the Template key of the provided data.
local function customElementFactory(factory, node)
  local data = node:GetData()
  if data.Template == "FrameColorOptions_ModuleColorButtonTemplate" then
    factory(data.Template, colorButtonInitializer)
  elseif data.Template == "FrameColorOptions_ToggleButtonTemplate" then
    factory(data.Template, toggleButtonInitializer)
  else
    factory(data.Template, topLevelDataInitializer)
  end
end

-- This function will be used to reset the elements of the ScrollView.
local function resetter(button, node)
  local data = node:GetData()
  if data.Template == "FrameColorOptions_ModuleButtonTemplate" then
    updateCollapseButton(button, node)
  end
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

--- This function will be used to populate the ScrollView with the data.
--- @param moduleList table The list of modules to be displayed.
--- @param isSearch boolean If the data is being populated from a search query. This should not overwrite the currentModuleList or the next search will be based on the filtered data.
--- The table will be extracted from the FrameColorDB were modules are categorized by category = {module same structure as below.}
--[[
  Data Structure:
  moduleList = {
    	Module = {
        category = "Name of the Category", e.g. "ActionBars"
        order = 1, -- The order of the module in the category. Optional.
        name = "The Name of the Module",
        toggles = {
          SomeToggleEntry = {
            order = 1,
            name = "What the toggle is used for",
          }
        },
        colors = { -- The list of colors for the module.
          SomeColorEntry = {
            order = 1, -- The order of the color in the module.
            hasAlpha = true/false.
            name = "What the color is used for",
            rgbaValues = {r, g, b, a}, --rgba are numbers between 0 and 1.
          },
        },
		  }.
      -- And the next modules..
	  }
  }
--]]

local currentModuleList = {} -- This will be used for the search filtering.

function private:PopulateRightInset_ModuleList(moduleList, isSearch)
  if not isSearch then
    currentModuleList = moduleList
    -- Setup the ScrollView
    self.SetScrollViewMethods_RightInset(customElementFactory, resetter)
  end

  -- The system is smart, a new Data Provider will still reuse the frames.
  local DataProvider = CreateTreeDataProvider()
  local orderedModuleList = sortByOrderKey(moduleList)

  -- Loop through the provided data.
  for _, module in ipairs(orderedModuleList) do
    -- Define the top level data.
    local topLevelData = {
      module = module.name,
      name = module.displayedName,
      Template = "FrameColorOptions_ModuleButtonTemplate",
    }
    local topLevelNode = DataProvider:Insert(topLevelData)
    topLevelNode:SetCollapsed(true) -- The frames for FrameColorOptions_ModuleColorButtonTemplate will only be created when the node is expanded. Since most nodes will not be used this will save memory.
    -- Toggles
    local orderedToggleList = sortByOrderKey(module.toggles)
    for _, toggle in ipairs(orderedToggleList) do
      local nestedData = {
        key = toggle.key, -- The key is needed to save values to the db.
        module = module.name, -- The name of the module to access the db.
        name = toggle.name, -- The name of the color to show in the menu.
        Template = "FrameColorOptions_ToggleButtonTemplate",
      }
      topLevelNode:Insert(nestedData)
    end
    -- Colors
    -- Loop through all colors of the module to define the nested data.
    local orderedColorList = sortByOrderKey(module.colors)
    for _, color in ipairs(orderedColorList) do
      local nestedData = {
        key = color.key, -- The key is needed to save values to the db.
        module = module.name, -- The name of the module to access the db.
        name = color.name, -- The name of the color to show in the menu.
        hasAlpha = color.hasAlpha or false,
        Template = "FrameColorOptions_ModuleColorButtonTemplate",
      }
      topLevelNode:Insert(nestedData)
    end
  end

  self.SetDataProvider_RightInset(DataProvider)
end


-- This function will be used to filter the module list based on the search query.
function private:FilterRightInset(searchQuery)
  local filteredModuleList = {}

  for _, module in pairs(currentModuleList) do
    if string_find(module.displayedName:lower(), searchQuery:lower()) then
      filteredModuleList[module.name] = module
    end
  end

  if searchQuery == "" then
    filteredModuleList = currentModuleList
  end

  self:PopulateRightInset_ModuleList(filteredModuleList, true)
end








