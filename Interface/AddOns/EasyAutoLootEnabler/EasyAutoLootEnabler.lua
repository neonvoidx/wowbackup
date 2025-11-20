local CreateFrame = CreateFrame
local GetCVarBool = GetCVarBool
local SetCVar = SetCVar
local print = print

-- Create a frame to handle events
local frame = CreateFrame("FRAME", "EasyAutoLootEnablerFrame")

-- Register for the PLAYER_LOGIN event
frame:RegisterEvent("PLAYER_LOGIN")

-- Define the event handler function
local function eventHandler(self, event, ...)
    -- Check if the event is PLAYER_LOGIN
    if event == "PLAYER_LOGIN" then
        -- Check if Auto Loot is not enabled
        if not GetCVarBool("autoLootDefault") then
            -- Enable Auto Loot
            SetCVar("autoLootDefault", 1)
            -- Print a message confirming auto loot has been enabled
            print("EasyAutoLootEnabler: Auto loot has been enabled.")
        end
    end
end

-- Set the script to handle events
frame:SetScript("OnEvent", eventHandler)
