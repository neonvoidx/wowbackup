-- The Cetegory List
local _, private = ...

local L = FrameColor.API:GetLocale()

-- Lua API
local table_sort = table.sort
local table_insert = table.insert
local string_find = string.find

local frame = CreateFrame("Frame", nil, nil, "InsetFrameTemplate")
function private:GetLeftInsetFrame()
  return frame
end

-- Scroll Box.
frame.scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
frame.scrollBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
frame.scrollBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)

-- Scroll Bar.
frame.scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
frame.scrollBar:SetPoint("TOPLEFT", frame, "TOPRIGHT", 7, 0)
frame.scrollBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 7, 0)
frame.scrollBar:Hide()

-- Initialize the Scroll View.
local ScrollView = CreateScrollBoxListLinearView()
ScrollView:SetPadding(10, 10, 10, 10, 4)
ScrollUtil.InitScrollBoxListWithScrollBar(frame.scrollBox, frame.scrollBar, ScrollView)

local function setButtonSelected(clickedButton)
  -- This will just loop over all child frames. This is not the intent of the function but we just need all buttons.
  ScrollView:FindFrameByPredicate(function(button)
    button.selectedTexture:Hide()
  end)

  clickedButton.selectedTexture:Show()
end

-- Initializer.
local function initializer(button, data)
  button.name:SetText(data.name)
  data.button = button

  button:SetScript("OnClick", function (self)
    -- Do net handle clicks if the content is already shown.
    if self.selectedTexture:IsShown() then
      return
    end

    -- Set the new button as selected.
    setButtonSelected(self)

    -- Check if a searchBox should be shown for the current view.
    if data.showSearchBox then
      private.ShowSearchBox()
    else
      private.HideSearchBox()
    end

    -- Execute the callbck.
    data.callback()
  end)

  if data.name == L["unit_frames"] then
    -- Set the button visually selected.
    setButtonSelected(button)
    -- Populate the right inset.
    data.callback()
    -- Check if a searchBox should be shown.
    if data.showSearchBox then
      private.ShowSearchBox()
    else
      private.HideSearchBox()
    end
  end
end

-- Set the initializer.
ScrollView:SetElementInitializer("FrameColorOptions_CategoryListTemplate", initializer)

-- This function will be used to sort the modules by the Order key.
local function sortByOrderKey(inputTable)
  local orderedTable = {}
  local noOrderKey = {}


  for _, value in pairs(inputTable) do
    if not value.order then
      table_insert(noOrderKey, value)
    else
      table_insert(orderedTable, value)
    end
  end

  -- Sort modules by order value
  table_sort(orderedTable, function(a, b) return a.order < b.order end)

  for _, value in pairs(noOrderKey) do
    table_insert(orderedTable, value)
  end

  return orderedTable
end

--- This function will be used to populate the ScrollView with the data.
--- @param categoryList table The list of modules to be displayed.
--[[
  Data Structure:
  categoryList = {
    [1] = {
      order = 1, -- The order in which the category will be displayed.
      name = "Category Name", -- The name of the category.
      callback = function,
    },
    -- And the next ategory..
  }
--]]

function private:PopulateLeftInset(categoryList)
  -- The system is smart, a new Data Provider will still reuse the frames.
  local DataProvider = CreateDataProvider()
  local orderedCategoryList = sortByOrderKey(categoryList)
  -- Loop through the ordered table and insert the data.
  for _, category in ipairs(orderedCategoryList) do
    local data = {
      name = category.name,
      callback = category.callback,
      showSearchBox = category.showSearchBox
    }
    DataProvider:Insert(data)
  end
  ScrollView:SetDataProvider(DataProvider)
end
