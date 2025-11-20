local _, addonTable = ...

local LEM = addonTable.LEM or LibStub("LibEditMode")

local SecondaryResourceBarMixin = Mixin({}, addonTable.PowerBarMixin)

function SecondaryResourceBarMixin:GetResourceNumberColor()
    return addonTable:GetOverrideTextColor(addonTable.RegistereredBar.SecondaryResourceBar.frameName, addonTable.TextId.ResourceNumber) or { r = 1, b = 1, g = 1}
end

function SecondaryResourceBarMixin:GetResourceChargeTimerColor()
    return addonTable:GetOverrideTextColor(addonTable.RegistereredBar.SecondaryResourceBar.frameName, addonTable.TextId.ResourceChargeNumber) or { r = 1, b = 1, g = 1}
end

function SecondaryResourceBarMixin:GetResource()
    local playerClass = select(2, UnitClass("player"))
    local secondaryResources = {
        ["DEATHKNIGHT"] = Enum.PowerType.Runes,
        ["DEMONHUNTER"] = {
            [1480] = "SOUL_FRAGMENTS", -- Devourer
        },
        ["DRUID"]       = {
            [DRUID_CAT_FORM]        = Enum.PowerType.ComboPoints,
            [DRUID_MOONKIN_FORM_1]  = Enum.PowerType.Mana,
            [DRUID_MOONKIN_FORM_2]  = Enum.PowerType.Mana,
        },
        ["EVOKER"]      = Enum.PowerType.Essence,
        ["HUNTER"]      = nil,
        ["MAGE"]        = {
            [62]   = Enum.PowerType.ArcaneCharges, -- Arcane
        },
        ["MONK"]        = {
            [268]  = "STAGGER", -- Brewmaster
            [269]  = Enum.PowerType.Chi, -- Windwalker
        },
        ["PALADIN"]     = Enum.PowerType.HolyPower,
        ["PRIEST"]      = {
            [258]  = Enum.PowerType.Mana, -- Shadow
        },
        ["ROGUE"]       = Enum.PowerType.ComboPoints,
        ["SHAMAN"]      = {
            [262]  = Enum.PowerType.Mana, -- Elemental
            [263] =  Enum.PowerType.Mana, -- Enhancement
        },
        ["WARLOCK"]     = Enum.PowerType.SoulShards,
        ["WARRIOR"]     = nil,
    }

    local spec = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

    -- Druid: form-based
    if playerClass == "DRUID" then
        local formID = GetShapeshiftFormID()
        return secondaryResources[playerClass] and secondaryResources[playerClass][formID or 0]
    end

    if type(secondaryResources[playerClass]) == "table" then
        return secondaryResources[playerClass][specID]
    else
        return secondaryResources[playerClass]
    end
end

function SecondaryResourceBarMixin:GetResourceValue(resource)
    if not resource then return nil, nil, nil, nil end

    if resource == "STAGGER" then
        local stagger = UnitStagger("player") or 0
        local maxHealth = UnitHealthMax("player") or 1
        return maxHealth, stagger, stagger, "number"
    end

    if resource == "SOUL_FRAGMENTS" then
        -- The hack needs the PlayerFrame
        if not PlayerFrame:IsShown() then return nil, nil, nil, nil end

        local current = DemonHunterSoulFragmentsBar:GetValue() 
        local max = select(2, DemonHunterSoulFragmentsBar:GetMinMaxValues()) -- Secret values

        if not self._SCRB_DDH_Meta then
            hooksecurefunc(DemonHunterSoulFragmentsBar.CollapsingStarBackground, "Show", function() self:ApplyLayout() end)
            hooksecurefunc(DemonHunterSoulFragmentsBar.CollapsingStarBackground, "Hide", function() self:ApplyLayout() end)
            self._SCRB_DDH_Meta = true
        end
        
        return max, current, current, "number"
    end

    if resource == Enum.PowerType.Runes then
        local current = 0
        local max = UnitPowerMax("player", resource)
        if max <= 0 then return nil, nil, nil, nil end

        for i = 1, max do
            local runeReady = select(3, GetRuneCooldown(i))
            if runeReady then
                current = current + 1
            end
        end
        
        return max, current, current, "number"
    end

    if resource == Enum.PowerType.SoulShards then
        local currentDisplay = UnitPower("player", resource)
        local current = UnitPower("player", resource, true)
        local max = UnitPowerMax("player", resource, true)
        if max <= 0 then return nil, nil, nil, nil end

        local spec = C_SpecializationInfo.GetSpecialization()
        local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

        -- For destruction only, display half shard
        if specID == 267 then
            return max, current, current, "number"
        end

        return max, current, currentDisplay, "number"
    end

    -- Regular secondary resource types
    local current = UnitPower("player", resource)
    local max = UnitPowerMax("player", resource)
    if max <= 0 then return nil, nil, nil, nil end

    return max, current, current, "number"
end

addonTable.SecondaryResourceBarMixin = SecondaryResourceBarMixin

addonTable.RegistereredBar = addonTable.RegistereredBar or {}
addonTable.RegistereredBar.SecondaryResourceBar = {
    mixin = addonTable.SecondaryResourceBarMixin,
    dbName = "SecondaryResourceBarDB",
    editModeName = "Secondary Resource Bar",
    frameName = "SecondaryResourceBar",
    frameLevel = 2,
    defaultValues = {
        point = "CENTER",
        x = 0,
        y = -40,
        hideBlizzardSecondaryResourceUi = false,
        hideManaOnDps = false,
        showTicks = true,
        tickThickness = 1,
        useResourceAtlas = false,
    },
    lemSettings = function(bar, defaults)
        local dbName = bar:GetConfig().dbName

        return {
            {
                order = 2,
                name = "Hide Blizzard UI",
                kind = LEM.SettingType.Checkbox,
                default = defaults.hideBlizzardSecondaryResourceUi,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.hideBlizzardSecondaryResourceUi ~= nil then
                        return data.hideBlizzardSecondaryResourceUi
                    else
                        return defaults.hideBlizzardSecondaryResourceUi
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].hideBlizzardSecondaryResourceUi = value
                    bar:HideBlizzardSecondaryResource(layoutName)
                end,
            },
            {
                order = 41,
                name = "Show Resource Charge Timer (e.g. Runes)",
                kind = LEM.SettingType.Checkbox,
                default = defaults.showFragmentedPowerBarText,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.showFragmentedPowerBarText ~= nil then
                        return data.showFragmentedPowerBarText
                    else
                        return defaults.showFragmentedPowerBarText
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].showFragmentedPowerBarText = value
                    bar:ApplyTextVisibilitySettings(layoutName)
                end,
            },
            {
                order = 42,
                name = "Hide Mana On Damage Dealers",
                kind = LEM.SettingType.Checkbox,
                default = defaults.hideManaOnDps,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.hideManaOnDps ~= nil then
                        return data.hideManaOnDps
                    else
                        return defaults.hideManaOnDps
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].hideManaOnDps = value
                end,
            },
            {
                order = 43,
                name = "Show Ticks When Available",
                kind = LEM.SettingType.Checkbox,
                default = defaults.showTicks,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    if data and data.showTicks ~= nil then
                        return data.showTicks
                    else
                        return defaults.showTicks
                    end
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].showTicks = value
                    bar:UpdateTicksLayout(layoutName)
                end,
            },
            {
                order = 44,
                name = "Tick Thickness",
                kind = LEM.SettingType.Slider,
                default = defaults.tickThickness,
                minValue = 1,
                maxValue = 5,
                valueStep = 1,
                get = function(layoutName)
                    local data = SenseiClassResourceBarDB[dbName][layoutName]
                    return data and data.tickThickness or defaults.tickThickness
                end,
                set = function(layoutName, value)
                    SenseiClassResourceBarDB[dbName][layoutName] = SenseiClassResourceBarDB[dbName][layoutName] or CopyTable(defaults)
                    SenseiClassResourceBarDB[dbName][layoutName].tickThickness = value
                    bar:UpdateTicksLayout(layoutName)
                end,
            },
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
