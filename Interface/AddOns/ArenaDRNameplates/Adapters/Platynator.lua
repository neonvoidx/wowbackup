local _, ns = ...
ns = ns or {}

local Registry = ns.NameplateAdapters
if not Registry then
    return
end

local isFrame = Registry.IsFrame
local getDefaultTokenFromPlate = Registry.GetDefaultTokenFromPlate

local function isPlatynatorLoaded()
    if _G.Platynator then
        return true
    end

    return Registry:IsAddOnLoaded("Platynator")
end

local function isPlatynatorDisplay(frame)
    return isFrame(frame)
        and type(frame.widgets) == "table"
        and isFrame(frame.BuffDisplay)
        and isFrame(frame.DebuffDisplay)
        and isFrame(frame.CrowdControlDisplay)
        and type(frame.SetUnit) == "function"
end

local function getPlatynatorDisplay(plate, token)
    if not isFrame(plate) then
        return nil
    end

    token = token or getDefaultTokenFromPlate(plate)
    local fallbackDisplay

    for _, child in ipairs({ plate:GetChildren() }) do
        if isPlatynatorDisplay(child) then
            if token and (child.unit == token or child.interactUnit == token) then
                return child
            end

            if not fallbackDisplay and (type(child.IsShown) ~= "function" or child:IsShown()) then
                fallbackDisplay = child
            end
        end
    end

    return fallbackDisplay
end

local function getPlatynatorPrimaryWidget(display)
    if not isPlatynatorDisplay(display) then
        return nil
    end

    local firstBar
    for _, widget in ipairs(display.widgets) do
        if isFrame(widget) then
            local details = widget.details
            if type(details) == "table" then
                if details.kind == "health" then
                    return widget
                end
                if not firstBar and widget.kind == "bars" then
                    firstBar = widget
                end
            end
        end
    end

    return firstBar
end

Registry:RegisterAdapter({
    id = "Platynator",
    priority = 100,
    IsAvailable = function()
        return isPlatynatorLoaded()
    end,
    GetTokenFromPlate = function(_, plate)
        return getDefaultTokenFromPlate(plate)
    end,
    MatchesPlate = function(_, plate, token)
        return getPlatynatorDisplay(plate, token) ~= nil
    end,
    GetAnchorParent = function(_, plate, token)
        local display = getPlatynatorDisplay(plate, token)
        if not display then
            return nil
        end

        return getPlatynatorPrimaryWidget(display) or display
    end,
})
