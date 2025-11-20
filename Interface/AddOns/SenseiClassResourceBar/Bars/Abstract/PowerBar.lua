local _, addonTable = ...

local PowerBarMixin = Mixin({}, addonTable.BarMixin)

function PowerBarMixin:GetBarColor(resource)
    return addonTable:GetOverrideResourceColor(resource)
end

function PowerBarMixin:OnLoad()
    self.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.Frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    self.Frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.Frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.Frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")

    local playerClass = select(2, UnitClass("player"))

    if playerClass == "DRUID" then
        self.Frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    end
end

function PowerBarMixin:OnEvent(event, ...)
    local unit = ...

    if event == "PLAYER_ENTERING_WORLD"
        or event == "UPDATE_SHAPESHIFT_FORM"
        or (event == "PLAYER_SPECIALIZATION_CHANGED" and unit == "player") then

        self:ApplyVisibilitySettings()
        self:ApplyLayout()

    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_TARGET_CHANGED" then

        self:ApplyVisibilitySettings(nil, event == "PLAYER_REGEN_DISABLED")

    elseif event == "UNIT_MAXPOWER" and unit == "player" then
        self:UpdateTicksLayout()
    end
end

addonTable.PowerBarMixin = PowerBarMixin
