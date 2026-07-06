-- Overachiever2: CopyURLDialog
-- Reusable popup dialog that displays a URL with pre-selected text for easy copying.

local OA2 = Overachiever2

StaticPopupDialogs["OVERACHIEVER2_COPY_URL"] = {
    text = "%s\nCTRL-C to copy",
    button1 = CLOSE,
    OnShow = function(self, data)
        local function HidePopup(self)
            self:GetParent():Hide()
        end

        local editBox = self.editBox or self.EditBox
        if not editBox then return end

        editBox:SetScript("OnEscapePressed", HidePopup)
        editBox:SetScript("OnEnterPressed", HidePopup)
        editBox:SetScript("OnKeyUp", function(self, key)
            if IsControlKeyDown() and key == "C" then
                HidePopup(self)
            end
        end)
        editBox:SetMaxLetters(0)
        editBox:SetText(data)
        editBox:HighlightText()
    end,
    hasEditBox = true,
    editBoxWidth = 240,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function OA2.ShowCopyURLDialog(header, url)
    StaticPopup_Show("OVERACHIEVER2_COPY_URL", header, nil, url)
end