-- Function to animate the button press with a shake effect
local function AnimateButton(button)
    if not button then return end
    
    if not button.ShakeAnimation then
        button.ShakeAnimation = button:CreateAnimationGroup()
        
        local moveLeft = button.ShakeAnimation:CreateAnimation("Translation")
        moveLeft:SetOffset(3, -3) --moveLeft:SetOffset(-5, 0)
        moveLeft:SetDuration(0.05) --moveLeft:SetDuration(0.05)
        moveLeft:SetOrder(1)
		moveLeft:SetSmoothing("IN")
        
        local moveRight = button.ShakeAnimation:CreateAnimation("Translation")
        moveRight:SetOffset(-3, 3) --(10, 0)
        moveRight:SetDuration(0.1) --(0.1)
        moveRight:SetOrder(2)
        
        local moveBack = button.ShakeAnimation:CreateAnimation("Translation")
        moveBack:SetOffset(0, 0) --(-5, 0)
        moveBack:SetDuration(0.05) --(0.05)
        moveBack:SetOrder(3)
        
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