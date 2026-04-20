-- The Module List of the current Category.
local _, private = ...

local frame = CreateFrame("Frame", nil, nil, "InsetFrameTemplate")
function private:GetRightInsetFrame()
  return frame
end

-- AceGUI Container for profiles.
local AceGUI = LibStub("AceGUI-3.0")
local aceScrollBox = AceGUI:Create("ScrollFrame")
aceScrollBox:SetLayout("Fill")
aceScrollBox.frame:SetParent(frame)
aceScrollBox.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
aceScrollBox.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
aceScrollBox.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
aceScrollBox.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
aceScrollBox.frame:SetClipsChildren(true)
frame.aceScrollBox = aceScrollBox

-- Scroll Box.
frame.scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
frame.scrollBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
frame.scrollBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)

-- Scroll Bar.
frame.ScrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
frame.ScrollBar:SetPoint("TOPLEFT", frame, "TOPRIGHT", 7, 0)
frame.ScrollBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 7, 0)
frame.ScrollBar:SetHideIfUnscrollable(true)

-- Initialize the Scroll View.
local ScrollView = CreateScrollBoxListTreeListView()
ScrollView:SetPadding(10, 10, 10, 10, 4)
ScrollUtil.InitScrollBoxListWithScrollBar(frame.scrollBox, frame.ScrollBar, ScrollView)


--
function private.SetScrollViewMethods_RightInset(factory, resetter)
  ScrollView:SetElementFactory(factory)
  ScrollView:SetElementResetter(resetter)
end

function private.SetDataProvider_RightInset(dataProvider)
  ScrollView:SetDataProvider(dataProvider)
end





