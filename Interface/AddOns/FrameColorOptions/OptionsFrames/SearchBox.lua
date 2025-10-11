-- The Module List of the current Category.
local _, private = ...

local frame = CreateFrame("EditBox", nil, nil, "SearchBoxTemplate")
function private:GetSearchBox()
  return frame
end

frame:SetHeight(20)
frame:SetAutoFocus(false)
-- OnChar only fires when there is in acutal input while OnTextChanged also fires when resizing etc.
-- To not always filter the right inset and with that close all open buttons OnChar is better.
frame:HookScript("OnChar", function(self)
  private:FilterRightInset(self:GetText())
end)
frame:HookScript("OnTextSet", function()
  private:FilterRightInset("")
end)

function private.HideSearchBox()
  frame:Disable()
  frame:Hide()
end

function private.ShowSearchBox()
  frame:Enable()
  frame:Show()
end

private.HideSearchBox()
