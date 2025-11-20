local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEditMode")

local TertiaryResourceBarMixin = Mixin({}, addonTable.PowerBarMixin)

function TertiaryResourceBarMixin:GetResourceNumberColor()
    return addonTable:GetOverrideTextColor(addonTable.RegistereredBar.TertiaryResourceBar.frameName, addonTable.TextId.ResourceNumber) or { r = 1, b = 1, g = 1}
end

function TertiaryResourceBarMixin:GetResourceChargeTimerColor()
    return addonTable:GetOverrideTextColor(addonTable.RegistereredBar.TertiaryResourceBar.frameName, addonTable.TextId.ResourceChargerTimer) or { r = 1, b = 1, g = 1}
end

function TertiaryResourceBarMixin:GetResource()
    local playerClass = select(2, UnitClass("player"))
    local tertiaryResources = {
        ["DEATHKNIGHT"] = nil,
        ["DEMONHUNTER"] = nil,
        ["DRUID"]       = nil,
        ["EVOKER"]      = {
            [1473] = "EBON_MIGHT", -- Augmentation
        },
        ["HUNTER"]      = nil,
        ["MAGE"]        = nil,
        ["MONK"]        = nil,
        ["PALADIN"]     = nil,
        ["PRIEST"]      = nil,
        ["ROGUE"]       = nil,
        ["SHAMAN"]      = nil,
        ["WARLOCK"]     = nil,
        ["WARRIOR"]     = nil,
    }

    local spec = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

    -- Druid: form-based
    if playerClass == "DRUID" then
        local formID = GetShapeshiftFormID()
        return tertiaryResources[playerClass] and tertiaryResources[playerClass][formID or 0]
    end

    if type(tertiaryResources[playerClass]) == "table" then
        return tertiaryResources[playerClass][specID]
    else 
        return tertiaryResources[playerClass]
    end
end

function TertiaryResourceBarMixin:GetResourceValue(resource)
    if not resource then return nil, nil, nil, nil end

    if resource == "EBON_MIGHT" then
        -- The hack needs the PlayerFrame
        if not PlayerFrame:IsShown() then return nil, nil, nil, nil end

        local current = EvokerEbonMightBar:GetValue() 
        local max = select(2, EvokerEbonMightBar:GetMinMaxValues()) -- Secret values

        return max, current, current, "timer", 0
    end

    -- Regular secondary resource types
    local current = UnitPower("player", resource)
    local max = UnitPowerMax("player", resource)
    if max <= 0 then return nil, nil, nil, nil end

    return max, current, current, "number"
end

addonTable.TertiaryResourceBarMixin = TertiaryResourceBarMixin

addonTable.RegistereredBar = addonTable.RegistereredBar or {}
addonTable.RegistereredBar.TertiaryResourceBar = {
    mixin = addonTable.TertiaryResourceBarMixin,
    dbName = "tertiaryResourceBarDB",
    editModeName = "Ebon Might Bar",
    frameName = "TertiaryResourceBar",
    frameLevel = 1,
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = -80,
        useResourceAtlas = false,
    },
    allowEditPredicate = function()
        local spec = C_SpecializationInfo.GetSpecialization()
        local specID = C_SpecializationInfo.GetSpecializationInfo(spec)
        return specID == 1473 -- Augmentation
    end,
    loadPredicate = function()
        local playerClass = select(2, UnitClass("player"))
        return playerClass == "EVOKER"
    end,
    lemSettings = function(bar, defaults)
        local dbName = bar:GetConfig().dbName

        return {
            {
                order = 63,
                name = "Use Resource Foreground And Color",
                kind = LEM.SettingType.Checkbox,
                default = defaults.useResourceAtlas,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.useResourceAtlas ~= nil then
                        return data.useResourceAtlas
                    else
                        return defaults.useResourceAtlas
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].useResourceAtlas = value
                    bar:ApplyLayout(layoutName)
                end,
            },
        }
    end
}
