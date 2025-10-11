-- Define the folder and namespace from the vararg
local folder, ns = ...

-- Create a frame for the addon
local addon = CreateFrame('Frame', 'EasyDeleteFrame')

-- Function to hide the edit box and enable the confirmation button
local function hideEditBox()
    -- Hide the edit box in the static popup
    StaticPopup1EditBox:Hide()
    -- Enable the first button in the static popup (usually the "Yes" button)
    StaticPopup1Button1:Enable()
end

-- Function to show the item link in the addon frame
local function showLink(link)
    -- Set the text of the link font string to the provided item link
    addon.link:SetText(link)
    -- Show the link font string
    addon.link:Show()
end

-- Event handler for DELETE_ITEM_CONFIRM event
function addon:DELETE_ITEM_CONFIRM(...)
    -- Check if the edit box is currently shown
    if StaticPopup1EditBox:IsShown() then
        -- Hide the edit box and enable the confirmation button
        hideEditBox()
        -- Get the item link from the cursor info (third return value)
        local link = select(3, GetCursorInfo())
        -- Show the item link in the addon frame
        showLink(link)
    end
end

-- Event handler for ADDON_LOADED event
function addon:ADDON_LOADED(loaded_addon)
    -- Check if the loaded addon is the current addon
    if loaded_addon ~= folder then return end

    -- Create a font string to display the item link
    addon.link = StaticPopup1:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    -- Set the position of the link font string to be centered on the edit box
    addon.link:SetPoint('CENTER', StaticPopup1EditBox)
    -- Initially hide the link font string
    addon.link:Hide()

    -- Hook the OnHide script of the static popup to hide the link font string
    StaticPopup1:HookScript('OnHide', function()
        addon.link:Hide()
    end)
end

-- Set the script to handle events
addon:SetScript('OnEvent', function(self, event, ...)
    -- Call the appropriate event handler based on the event name
    self[event](self, ...)
end)

-- Register the events to be handled by the addon
addon:RegisterEvent('ADDON_LOADED')
addon:RegisterEvent('DELETE_ITEM_CONFIRM')