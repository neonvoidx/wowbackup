-- Many thanks to https://warcraft.wiki.gg/wiki/Making_scrollable_frames for the detailed explanation of how to create a scrollable frame.
local _, private = ...

-- Main Frame
local frame = CreateFrame("Frame", "FrameColorOptions", UIParent, "PortraitFrameTemplate")

-- Set the title text.
frame.title = _G["FrameColorOptionsTitleText"]
frame.title:SetText("FrameColor")

function private:GetMainFrame()
  return frame
end

FrameColorOptionsPortrait:SetTexture("Interface\\AddOns\\FrameColor\\Assets\\Icon.tga")
frame:Hide()
--local r,g,b = PANEL_BACKGROUND_COLOR:GetRGB()
--frame.Bg:SetColorTexture(r,g,b,0.9)
frame:SetFrameStrata("DIALOG") -- @TODO: Check best options.
table.insert(UISpecialFrames, frame:GetName())
frame:SetSize(950,550)
frame:SetResizeBounds(700, 400)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetMovable(true)
frame:SetResizable(true)
frame.TitleContainer:SetScript("OnMouseDown", function()
  frame:StartMoving()
  frame:SetAlpha(0.9)
end)
frame.TitleContainer:SetScript("OnMouseUp", function()
  frame:StopMovingOrSizing()
  frame:SetAlpha(1)
end)

-- Resize Handle
frame.resizeHandle = CreateFrame("Button", nil, frame)
frame.resizeHandle:SetPoint("BOTTOMRIGHT",-1,1)
frame.resizeHandle:SetSize(26, 26)
frame.resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
frame.resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
frame.resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
frame.resizeHandle:SetScript("OnMouseDown", function(_, button)
  if button == "LeftButton" then
    frame:StartSizing("BOTTOMRIGHT")
  end
end)
frame.resizeHandle:SetScript("OnMouseUp", function(_, button)
  if button == "LeftButton" then
    frame:StopMovingOrSizing()
  end
end)

-- Left Inset
frame.leftInset = private:GetLeftInsetFrame()
frame.leftInset:SetParent(frame)
frame.leftInset:SetPoint("TOPLEFT", 25, -60)
frame.leftInset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 250, 35)

-- Right Inset
frame.rightInset = private:GetRightInsetFrame()
frame.rightInset:SetParent(frame)
frame.rightInset:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -25, -60)
frame.rightInset:SetPoint("BOTTOMLEFT", frame.leftInset, "BOTTOMRIGHT", 5, 0 )

-- Search Box
frame.searchBox = private:GetSearchBox()
frame.searchBox:SetParent(frame)
frame.searchBox:SetPoint("BOTTOMLEFT", frame.rightInset, "TOPLEFT", 150, 5)
frame.searchBox:SetPoint("BOTTOMRIGHT", frame.rightInset, "TOPRIGHT", -150, 5)


