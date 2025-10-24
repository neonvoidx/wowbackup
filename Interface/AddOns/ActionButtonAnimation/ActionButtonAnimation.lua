-- Function to animate the button press with a shake effect
local function AnimateButton(button)
    if not button then return end
    
    if not button.ShakeAnimation then
        button.ShakeAnimation = button:CreateAnimationGroup()
        
        local moveLeft = button.ShakeAnimation:CreateAnimation("Translation")
        moveLeft:SetOffset(2, -2)
        moveLeft:SetDuration(0.05)
        moveLeft:SetOrder(1)
        moveLeft:SetSmoothing("IN")
        
        local moveRight = button.ShakeAnimation:CreateAnimation("Translation")
        moveRight:SetOffset(-2, 2)
        moveRight:SetDuration(0.1)
        moveRight:SetOrder(2)
        
        local moveBack = button.ShakeAnimation:CreateAnimation("Translation")
        moveBack:SetOffset(0, 0)
        moveBack:SetDuration(0.05)
        moveBack:SetOrder(3)
        
  --[[      -- Add the shrink animation here
        local shrink = button.ShakeAnimation:CreateAnimation("Scale")
        shrink:SetScaleFrom(1.0, 1.0) -- Start at 100% size
        shrink:SetScaleTo(0.98, 0.98) -- Shrink to 90% size
        shrink:SetDuration(0.05) -- Duration of the shrink effect
        shrink:SetOrder(1) -- Start at the same time as moveLeft
        --shrink:SetSmoothing("IN_OUT")
		
		        -- Add the shrink animation here
        local shrink2 = button.ShakeAnimation:CreateAnimation("Scale")
        shrink2:SetScaleFrom(0.99, 0.99) -- Start at 100% size
        shrink2:SetScaleTo(1.1, 1.1) -- Shrink to 90% size
        shrink2:SetDuration(0.11) -- Duration of the shrink effect
        shrink2:SetOrder(2) -- Start at the same time as moveLeft
        --shrink:SetSmoothing("IN_OUT") ]]--
        
        button.ShakeAnimation:SetLooping("NONE")
    end
    
    button.ShakeAnimation:Stop()
    button.ShakeAnimation:Play()
end

-- Function to handle ActionButtonDown event for the main action bar
local function HandleMainActionBarButton(id)
    local button = _G["ActionButton" .. id]
    if button then
        AnimateButton(button)
    end
end

-- Function to handle MultiActionButtonDown event for multi-bars
local function HandleMultiActionBarButton(id, buttonNumber)
    -- Define the multi-bar prefixes (e.g., MultiBarBottomRightButton1, MultiBarLeftButton2, etc.)
    local multiBars = {
        ["MultiBarBottomLeft"] = "MultiBarBottomLeftButton",
        ["MultiBarBottomRight"] = "MultiBarBottomRightButton",
        ["MultiBarLeft"] = "MultiBarLeftButton",
        ["MultiBarRight"] = "MultiBarRightButton"
    }
    -- Check if the ID corresponds to a base multi-bar name
    for baseBarName, buttonPrefix in pairs(multiBars) do
        -- If the ID matches one of the base names (e.g., "MultiBarBottomRight")
        if id == baseBarName then
            -- Construct the button name with the buttonNumber (e.g., MultiBarBottomRightButton9)
            local buttonName = buttonPrefix .. buttonNumber
            local button = _G[buttonName]
            -- Check if the button exists and animate the correct button
            if button then
                -- Animate the button
                AnimateButton(button)
                return
            end
        end
    end
end

-- Hook into the ActionButtonDown function to detect button presses on the main bar
hooksecurefunc("ActionButtonDown", function(id)
    HandleMainActionBarButton(id)
end)

-- Hook into the MultiActionButtonDown function to detect button presses on multi-bars
hooksecurefunc("MultiActionButtonDown", function(id, buttonNumber)
    -- Ensure the correct button number is passed to identify the exact button being pressed
    HandleMultiActionBarButton(id, buttonNumber)
end)

-- Your existing code stays the same above this line...

-- Add mouse click detection
local function SetupMouseHooks()
    -- Hook main action bar buttons (1-12)
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            button:HookScript("OnMouseDown", function(self, mouseButton)
                if mouseButton == "LeftButton" then
                    AnimateButton(self)
                end
            end)
        end
    end
    
    -- Hook multi-bar buttons
    local multiBars = {
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton", 
        "MultiBarLeftButton",
        "MultiBarRightButton"
    }
    
    for _, barPrefix in pairs(multiBars) do
        for i = 1, 12 do
            local button = _G[barPrefix .. i]
            if button then
                button:HookScript("OnMouseDown", function(self, mouseButton)
                    if mouseButton == "LeftButton" then
                        AnimateButton(self)
                    end
                end)
            end
        end
    end
end

-- Set up the hooks when the player logs in
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
    SetupMouseHooks()
end)