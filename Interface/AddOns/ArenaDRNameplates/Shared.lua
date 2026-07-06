local _, ns = ...
ns = ns or {}

local Shared = ns.Shared or {}
ns.Shared = Shared

local defaults = {
    enabled = true,
    scale = 1.0,
    scaleWithNameplate = true,
    opacity = 1.0,
    iconLayout = "HORIZONTAL",
    iconGrowth = "RIGHT",
    iconVerticalGrowth = "UP",
    iconPadding = 2,
    timerTextColor = { 1, 1, 1 },
    timerTextScale = 1.0,
    timerTextOffsetX = 0,
    timerTextOffsetY = 0,
    showTimerText = true,
    showTimerDecimals = true,
    timerDecimalThreshold = 5,
    showTimerSwipe = true,
    showTimerSwipeEdge = false,
    showDRText = true,
    showImmunityIndicator = false,
    drTextAnchor = "BOTTOMRIGHT",
    drTextScale = 1.0,
    drTextOffsetX = 4,
    drTextOffsetY = -4,
    drTextColor = { 0, 1, 0 },
    drTextImmuneColor = { 1, 0, 0 },
    drBorderStyle = "SOLID",
    drBorderColor = { 0, 1, 0 },
    drBorderImmuneColor = { 1, 0, 0 },
    drBorderWidth = 1.5,
    anchorPreset = "BELOW",
    point = "TOP",
    relativePoint = "BOTTOM",
    offsetX = 0,
    offsetY = 0,
    trinket = {
        enabled = false,
        visibility = "COOLDOWN_ONLY",
        size = 22,
        opacity = 1.0,
        borderStyle = "SOLID",
        borderColor = { 0.95, 0.82, 0.24 },
        borderWidth = 1,
        anchorPreset = "ABOVE",
        point = "BOTTOM",
        relativePoint = "TOP",
        offsetX = 34,
        offsetY = 0,
    },
}

local validDRTextAnchors = {
    TOPLEFT = true,
    TOP = true,
    TOPRIGHT = true,
    LEFT = true,
    CENTER = true,
    RIGHT = true,
    BOTTOMLEFT = true,
    BOTTOM = true,
    BOTTOMRIGHT = true,
}

local validBasicAnchorPoints = {
    TOP = true,
    BOTTOM = true,
    LEFT = true,
    RIGHT = true,
    CENTER = true,
}

local validAnchorPresets = {
    ABOVE = true,
    BELOW = true,
    LEFT = true,
    RIGHT = true,
    CENTER = true,
    ADVANCED = true,
}

local validIconGrowth = {
    LEFT = true,
    RIGHT = true,
    CENTER = true,
}

local validIconLayouts = {
    HORIZONTAL = true,
    VERTICAL = true,
}

local validVerticalIconGrowth = {
    UP = true,
    DOWN = true,
}

local validDRBorderStyles = {
    NONE = true,
    SOLID = true,
    CLASSIC = true,
}

local validTrinketVisibilityModes = {
    ALWAYS = true,
    COOLDOWN_ONLY = true,
}

local validTrinketBorderStyles = {
    NONE = true,
    SOLID = true,
    CLASSIC = true,
}

local blizzardDRCVars = {
    enemiesEnabled = {
        cvar = "spellDiminishPVPEnemiesEnabled",
        defaultValue = true,
    },
    onlyTriggerableByMe = {
        cvar = "spellDiminishPVPOnlyTriggerableByMe",
        defaultValue = false,
    },
}

local frameNameCounter = 0
local deprecatedDBKeys = {
    timerColor = true,
    timerPosition = true,
    drBorderPadding = true,
}

Shared.defaults = defaults
Shared.validDRTextAnchors = validDRTextAnchors
Shared.validIconGrowth = validIconGrowth
Shared.validIconLayouts = validIconLayouts
Shared.validVerticalIconGrowth = validVerticalIconGrowth
Shared.validDRBorderStyles = validDRBorderStyles
Shared.validTrinketVisibilityModes = validTrinketVisibilityModes
Shared.validTrinketBorderStyles = validTrinketBorderStyles
Shared.blizzardDRCVars = blizzardDRCVars
Shared.EXPORT_PREFIX = "ArenaDRNameplates:1:"

function Shared.S(key)
    local localeTable = ns and ns.L
    if type(localeTable) == "table" then
        local value = localeTable[key]
        if value ~= nil then
            return value
        end
    end
    return key
end

local function SanitizeFrameNamePart(value, fallback)
    value = tostring(value or fallback or "Frame"):gsub("[^%w_]", "")
    if value == "" then
        return fallback or "Frame"
    end
    return value
end

function Shared.NextFrameName(scope, kind, explicitID)
    local scopePart = SanitizeFrameNamePart(scope, "General")
    local kindPart = SanitizeFrameNamePart(kind, "Frame")

    if explicitID ~= nil then
        return string.format(
            "ArenaDrNP_%s_%s_%s",
            scopePart,
            kindPart,
            SanitizeFrameNamePart(explicitID, "0")
        )
    end

    frameNameCounter = frameNameCounter + 1
    return string.format("ArenaDrNP_%s_%s_%03d", scopePart, kindPart, frameNameCounter)
end

local function CopyTable(source)
    local copy = {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            copy[key] = CopyTable(value)
        else
            copy[key] = value
        end
    end
    return copy
end

Shared.CopyTable = CopyTable

function Shared.CopyDefaultsIntoTable(target, clearExisting)
    if type(target) ~= "table" then
        return target
    end

    if clearExisting then
        for key in pairs(target) do
            target[key] = nil
        end
    end

    for key, value in pairs(defaults) do
        if type(value) == "table" then
            target[key] = CopyTable(value)
        else
            target[key] = value
        end
    end

    return target
end

function Shared.ClampColorChannel(value, fallback)
    value = tonumber(value)
    if value == nil then
        value = fallback
    end

    if value < 0 then
        return 0
    end
    if value > 1 then
        return 1
    end
    return value
end

function Shared.NormalizeColorTable(color, fallback)
    fallback = fallback or { 1, 1, 1 }
    local source = type(color) == "table" and color or fallback

    return {
        Shared.ClampColorChannel(source[1] or source.r, fallback[1] or 1),
        Shared.ClampColorChannel(source[2] or source.g, fallback[2] or 1),
        Shared.ClampColorChannel(source[3] or source.b, fallback[3] or 1),
    }
end

function Shared.ClampNumber(value, minimum, maximum, fallback)
    value = tonumber(value)
    if value == nil then
        value = fallback
    end

    if minimum ~= nil and value < minimum then
        value = minimum
    end
    if maximum ~= nil and value > maximum then
        value = maximum
    end

    return value
end

function Shared.NormalizeIconGrowth(value)
    value = tostring(value or "")
    if validIconGrowth[value] then
        return value
    end
    return defaults.iconGrowth
end

function Shared.NormalizeIconLayout(value)
    value = tostring(value or "")
    if validIconLayouts[value] then
        return value
    end
    return defaults.iconLayout
end

function Shared.NormalizeVerticalIconGrowth(value)
    value = tostring(value or "")
    if validVerticalIconGrowth[value] then
        return value
    end
    return defaults.iconVerticalGrowth
end

function Shared.NormalizeDRBorderStyle(value)
    value = tostring(value or "")
    if validDRBorderStyles[value] then
        return value
    end
    return defaults.drBorderStyle
end

function Shared.NormalizeTrinketVisibility(value)
    value = tostring(value or "")
    if validTrinketVisibilityModes[value] then
        return value
    end
    return defaults.trinket.visibility
end

function Shared.NormalizeTrinketBorderStyle(value)
    value = tostring(value or "")
    if validTrinketBorderStyles[value] then
        return value
    end
    return defaults.trinket.borderStyle
end

local function CVarValueToBool(value, fallback)
    if value == nil then
        return fallback == true
    end
    if value == true or value == 1 then
        return true
    end
    if value == false or value == 0 then
        return false
    end

    value = string.lower(tostring(value))
    if value == "1" or value == "true" then
        return true
    end
    if value == "0" or value == "false" then
        return false
    end

    return fallback == true
end

local function SafeCall(func, ...)
    if type(func) ~= "function" then
        return nil
    end

    local ok, result = pcall(func, ...)
    if ok then
        return result
    end
end

function Shared.IsCVarAvailable(cvarName)
    cvarName = tostring(cvarName or "")
    if cvarName == "" then
        return false
    end

    if C_CVar and type(C_CVar.GetCVarInfo) == "function" then
        return SafeCall(C_CVar.GetCVarInfo, cvarName) ~= nil
    end

    if type(GetCVar) == "function" then
        return SafeCall(GetCVar, cvarName) ~= nil
    end

    return false
end

function Shared.GetCVarBool(cvarName, fallback)
    cvarName = tostring(cvarName or "")
    if cvarName == "" then
        return fallback == true
    end

    if C_CVar and type(C_CVar.GetCVarBool) == "function" then
        local value = SafeCall(C_CVar.GetCVarBool, cvarName)
        if value ~= nil then
            return CVarValueToBool(value, fallback)
        end
    end

    if type(GetCVarBool) == "function" then
        local value = SafeCall(GetCVarBool, cvarName)
        if value ~= nil then
            return CVarValueToBool(value, fallback)
        end
    end

    if C_CVar and type(C_CVar.GetCVar) == "function" then
        local value = SafeCall(C_CVar.GetCVar, cvarName)
        if value ~= nil then
            return CVarValueToBool(value, fallback)
        end
    end

    if type(GetCVar) == "function" then
        local value = SafeCall(GetCVar, cvarName)
        if value ~= nil then
            return CVarValueToBool(value, fallback)
        end
    end

    return fallback == true
end

function Shared.GetCVarDefaultBool(cvarName, fallback)
    cvarName = tostring(cvarName or "")
    if cvarName == "" then
        return fallback == true
    end

    if C_CVar and type(C_CVar.GetCVarDefault) == "function" then
        local value = SafeCall(C_CVar.GetCVarDefault, cvarName)
        if value ~= nil then
            return CVarValueToBool(value, fallback)
        end
    end

    if type(GetCVarDefault) == "function" then
        local value = SafeCall(GetCVarDefault, cvarName)
        if value ~= nil then
            return CVarValueToBool(value, fallback)
        end
    end

    return fallback == true
end

function Shared.SetCVarBool(cvarName, enabled)
    cvarName = tostring(cvarName or "")
    if cvarName == "" then
        return false
    end

    local value = enabled and "1" or "0"
    if C_CVar and type(C_CVar.SetCVar) == "function" then
        local ok = pcall(C_CVar.SetCVar, cvarName, value)
        if ok then
            return true
        end
    end

    if type(SetCVar) == "function" then
        local ok = pcall(SetCVar, cvarName, value)
        if ok then
            return true
        end
    end

    return false
end

function Shared.ResetBlizzardDRCVarsToDefaults()
    for _, info in pairs(blizzardDRCVars) do
        if type(info) == "table" and Shared.IsCVarAvailable(info.cvar) then
            Shared.SetCVarBool(info.cvar, Shared.GetCVarDefaultBool(info.cvar, info.defaultValue))
        end
    end
end

local exportDBFields = {
    { key = "scale", path = { "scale" }, kind = "number" },
    { key = "scaleWithNameplate", path = { "scaleWithNameplate" }, kind = "boolean" },
    { key = "opacity", path = { "opacity" }, kind = "number" },
    { key = "iconLayout", path = { "iconLayout" }, kind = "string", valid = validIconLayouts },
    { key = "iconGrowth", path = { "iconGrowth" }, kind = "string", valid = validIconGrowth },
    { key = "iconVerticalGrowth", path = { "iconVerticalGrowth" }, kind = "string", valid = validVerticalIconGrowth },
    { key = "iconPadding", path = { "iconPadding" }, kind = "number" },
    { key = "anchorPreset", path = { "anchorPreset" }, kind = "string", valid = validAnchorPresets },
    { key = "point", path = { "point" }, kind = "string", valid = validBasicAnchorPoints },
    { key = "relativePoint", path = { "relativePoint" }, kind = "string", valid = validBasicAnchorPoints },
    { key = "offsetX", path = { "offsetX" }, kind = "number" },
    { key = "offsetY", path = { "offsetY" }, kind = "number" },
    { key = "showTimerSwipe", path = { "showTimerSwipe" }, kind = "boolean" },
    { key = "showTimerSwipeEdge", path = { "showTimerSwipeEdge" }, kind = "boolean" },
    { key = "showTimerText", path = { "showTimerText" }, kind = "boolean" },
    { key = "showTimerDecimals", path = { "showTimerDecimals" }, kind = "boolean" },
    { key = "timerDecimalThreshold", path = { "timerDecimalThreshold" }, kind = "number" },
    { key = "timerTextColor", path = { "timerTextColor" }, kind = "color" },
    { key = "timerTextScale", path = { "timerTextScale" }, kind = "number" },
    { key = "timerTextOffsetX", path = { "timerTextOffsetX" }, kind = "number" },
    { key = "timerTextOffsetY", path = { "timerTextOffsetY" }, kind = "number" },
    { key = "showDRText", path = { "showDRText" }, kind = "boolean" },
    { key = "drTextAnchor", path = { "drTextAnchor" }, kind = "string", valid = validDRTextAnchors },
    { key = "drTextScale", path = { "drTextScale" }, kind = "number" },
    { key = "drTextOffsetX", path = { "drTextOffsetX" }, kind = "number" },
    { key = "drTextOffsetY", path = { "drTextOffsetY" }, kind = "number" },
    { key = "drTextColor", path = { "drTextColor" }, kind = "color" },
    { key = "drTextImmuneColor", path = { "drTextImmuneColor" }, kind = "color" },
    { key = "showImmunityIndicator", path = { "showImmunityIndicator" }, kind = "boolean" },
    { key = "drBorderStyle", path = { "drBorderStyle" }, kind = "string", valid = validDRBorderStyles },
    { key = "drBorderColor", path = { "drBorderColor" }, kind = "color" },
    { key = "drBorderImmuneColor", path = { "drBorderImmuneColor" }, kind = "color" },
    { key = "drBorderWidth", path = { "drBorderWidth" }, kind = "number" },
    { key = "trinket.enabled", path = { "trinket", "enabled" }, kind = "boolean" },
    { key = "trinket.visibility", path = { "trinket", "visibility" }, kind = "string", valid = validTrinketVisibilityModes },
    { key = "trinket.size", path = { "trinket", "size" }, kind = "number" },
    { key = "trinket.opacity", path = { "trinket", "opacity" }, kind = "number" },
    { key = "trinket.borderStyle", path = { "trinket", "borderStyle" }, kind = "string", valid = validTrinketBorderStyles },
    { key = "trinket.borderColor", path = { "trinket", "borderColor" }, kind = "color" },
    { key = "trinket.borderWidth", path = { "trinket", "borderWidth" }, kind = "number" },
    { key = "trinket.anchorPreset", path = { "trinket", "anchorPreset" }, kind = "string", valid = validAnchorPresets },
    { key = "trinket.point", path = { "trinket", "point" }, kind = "string", valid = validBasicAnchorPoints },
    { key = "trinket.relativePoint", path = { "trinket", "relativePoint" }, kind = "string", valid = validBasicAnchorPoints },
    { key = "trinket.offsetX", path = { "trinket", "offsetX" }, kind = "number" },
    { key = "trinket.offsetY", path = { "trinket", "offsetY" }, kind = "number" },
}

local importErrorMessageKeys = {
    EMPTY = "ERR_IMPORT_EMPTY",
    INVALID_PREFIX = "ERR_IMPORT_INVALID_PREFIX",
    UNSUPPORTED_VERSION = "ERR_IMPORT_UNSUPPORTED_VERSION",
    INVALID_FORMAT = "ERR_IMPORT_INVALID_FORMAT",
    NO_SETTINGS = "ERR_IMPORT_NO_SETTINGS",
}

local function TrimString(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function FormatExportNumber(value)
    value = tonumber(value) or 0
    if math.floor(value) == value then
        return tostring(value)
    end

    return string.format("%.4f", value):gsub("0+$", ""):gsub("%.$", "")
end

local function EncodeExportString(value)
    return tostring(value or ""):gsub("([^%w_%.%-])", function(character)
        return string.format("%%%02X", string.byte(character))
    end)
end

local function DecodeExportString(value)
    return tostring(value or ""):gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
end

local function GetPathValue(source, path)
    local current = source
    for _, segment in ipairs(path) do
        if type(current) ~= "table" then
            return nil
        end
        current = current[segment]
    end
    return current
end

local function SetPathValue(target, path, value)
    local current = target
    for index = 1, #path - 1 do
        local segment = path[index]
        if type(current[segment]) ~= "table" then
            current[segment] = {}
        end
        current = current[segment]
    end
    current[path[#path]] = value
end

local function SerializeExportValue(field, value)
    if field.kind == "boolean" then
        return value == true and "1" or "0"
    end

    if field.kind == "number" then
        return FormatExportNumber(value)
    end

    if field.kind == "color" then
        local color = Shared.NormalizeColorTable(value, { 1, 1, 1 })
        return table.concat({
            FormatExportNumber(color[1]),
            FormatExportNumber(color[2]),
            FormatExportNumber(color[3]),
        }, ",")
    end

    return EncodeExportString(value)
end

local function DeserializeExportValue(field, value)
    if field.kind == "boolean" then
        value = string.lower(tostring(value or ""))
        if value == "1" or value == "true" then
            return true
        end
        if value == "0" or value == "false" then
            return false
        end
        return nil
    end

    if field.kind == "number" then
        return tonumber(value)
    end

    if field.kind == "color" then
        local r, g, b = tostring(value or ""):match("^([^,]+),([^,]+),([^,]+)$")
        r, g, b = tonumber(r), tonumber(g), tonumber(b)
        if r == nil or g == nil or b == nil then
            return nil
        end
        return { r, g, b }
    end

    value = DecodeExportString(value)
    if field.valid and not field.valid[value] then
        return nil
    end
    return value
end

local function ParseExportString(serialized)
    serialized = TrimString(serialized)
    if serialized == "" then
        return nil, "EMPTY"
    end

    if serialized:sub(1, #Shared.EXPORT_PREFIX) ~= Shared.EXPORT_PREFIX then
        if serialized:match("^ArenaDRNameplates:%d+:") then
            return nil, "UNSUPPORTED_VERSION"
        end
        return nil, "INVALID_PREFIX"
    end

    local payload = serialized:sub(#Shared.EXPORT_PREFIX + 1)
    local values = {}
    for entry in payload:gmatch("[^;]+") do
        local key, value = entry:match("^([^=]+)=(.*)$")
        if key and key ~= "" then
            values[key] = value
        end
    end

    if not next(values) then
        return nil, "INVALID_FORMAT"
    end

    return values
end

function Shared.GetImportErrorMessageKey(reason)
    return importErrorMessageKeys[reason] or "ERR_IMPORT_INVALID_FORMAT"
end

function Shared.ExportSettings()
    local db = Shared.EnsureDB()
    local parts = { "defaults=1" }

    for _, field in ipairs(exportDBFields) do
        local value = GetPathValue(db, field.path)
        local defaultValue = GetPathValue(defaults, field.path)
        local serializedValue = SerializeExportValue(field, value)
        if serializedValue ~= SerializeExportValue(field, defaultValue) then
            parts[#parts + 1] = field.key .. "=" .. serializedValue
        end
    end

    return Shared.EXPORT_PREFIX .. table.concat(parts, ";")
end

function Shared.ImportSettings(serialized)
    local values, reason = ParseExportString(serialized)
    if not values then
        return false, reason
    end

    local importedDB = CopyTable(defaults)
    local appliedSettings = 0

    for _, field in ipairs(exportDBFields) do
        local rawValue = values[field.key]
        if rawValue ~= nil then
            local parsedValue = DeserializeExportValue(field, rawValue)
            if parsedValue ~= nil then
                SetPathValue(importedDB, field.path, parsedValue)
                appliedSettings = appliedSettings + 1
            end
        end
    end

    if appliedSettings == 0 and values.defaults ~= "1" then
        return false, "NO_SETTINGS"
    end

    local db = Shared.EnsureDB()
    for key in pairs(db) do
        db[key] = nil
    end
    for key, value in pairs(importedDB) do
        if type(value) == "table" then
            db[key] = CopyTable(value)
        else
            db[key] = value
        end
    end

    Shared.EnsureDB()

    return true, "IMPORTED", appliedSettings
end

function Shared.DetectAnchorPreset(point, relativePoint)
    if point == "BOTTOM" and relativePoint == "TOP" then
        return "ABOVE"
    end
    if point == "TOP" and relativePoint == "BOTTOM" then
        return "BELOW"
    end
    if point == "RIGHT" and relativePoint == "LEFT" then
        return "LEFT"
    end
    if point == "LEFT" and relativePoint == "RIGHT" then
        return "RIGHT"
    end
    if point == "CENTER" and relativePoint == "CENTER" then
        return "CENTER"
    end
    return "ADVANCED"
end

function Shared.GetEffectiveHorizontalIconGrowthForValues(anchorPreset, iconGrowth)
    anchorPreset = tostring(anchorPreset or "")

    if anchorPreset == "LEFT" then
        return "LEFT"
    end
    if anchorPreset == "RIGHT" then
        return "RIGHT"
    end
    if anchorPreset == "ABOVE" or anchorPreset == "BELOW" or anchorPreset == "CENTER" then
        return "CENTER"
    end

    return Shared.NormalizeIconGrowth(iconGrowth)
end

function Shared.GetEffectiveVerticalIconGrowthForValues(anchorPreset, iconVerticalGrowth)
    return Shared.NormalizeVerticalIconGrowth(iconVerticalGrowth)
end

function Shared.GetEffectiveIconLayoutForTable(source)
    if type(source) ~= "table" then
        return defaults.iconLayout
    end

    return Shared.NormalizeIconLayout(source.iconLayout)
end

function Shared.GetEffectiveIconGrowthForValues(anchorPreset, iconLayout, iconGrowth, iconVerticalGrowth)
    if Shared.NormalizeIconLayout(iconLayout) == "VERTICAL" then
        return Shared.GetEffectiveVerticalIconGrowthForValues(anchorPreset, iconVerticalGrowth)
    end

    return Shared.GetEffectiveHorizontalIconGrowthForValues(anchorPreset, iconGrowth)
end

function Shared.GetEffectiveIconGrowthForTable(source)
    if type(source) ~= "table" then
        return Shared.GetEffectiveIconGrowthForValues(
            nil,
            defaults.iconLayout,
            defaults.iconGrowth,
            defaults.iconVerticalGrowth
        )
    end

    return Shared.GetEffectiveIconGrowthForValues(
        source.anchorPreset,
        source.iconLayout,
        source.iconGrowth,
        source.iconVerticalGrowth
    )
end

function Shared.ApplyAnchorPresetToTable(targetDB, preset)
    if type(targetDB) ~= "table" then
        return targetDB
    end

    local previousLayout = Shared.GetEffectiveIconLayoutForTable(targetDB)
    local previousHorizontalGrowth = Shared.GetEffectiveHorizontalIconGrowthForValues(
        targetDB.anchorPreset,
        targetDB.iconGrowth
    )
    local previousVerticalGrowth = Shared.GetEffectiveVerticalIconGrowthForValues(
        targetDB.anchorPreset,
        targetDB.iconVerticalGrowth
    )
    preset = tostring(preset or "")
    targetDB.anchorPreset = preset

    if preset == "ADVANCED" then
        if previousLayout == "VERTICAL" then
            targetDB.iconVerticalGrowth = previousVerticalGrowth
        else
            targetDB.iconGrowth = previousHorizontalGrowth
        end
    elseif preset == "ABOVE" then
        targetDB.point = "BOTTOM"
        targetDB.relativePoint = "TOP"
    elseif preset == "BELOW" then
        targetDB.point = "TOP"
        targetDB.relativePoint = "BOTTOM"
    elseif preset == "LEFT" then
        targetDB.point = "RIGHT"
        targetDB.relativePoint = "LEFT"
    elseif preset == "RIGHT" then
        targetDB.point = "LEFT"
        targetDB.relativePoint = "RIGHT"
    elseif preset == "CENTER" then
        targetDB.point = "CENTER"
        targetDB.relativePoint = "CENTER"
    elseif preset ~= "ADVANCED" then
        targetDB.anchorPreset = Shared.DetectAnchorPreset(targetDB.point, targetDB.relativePoint)
    end

    return targetDB
end

function Shared.EnsureDB()
    if not ArenaDRNameplatesDB then
        ArenaDRNameplatesDB = {}
    end

    local db = ArenaDRNameplatesDB

    for key in pairs(deprecatedDBKeys) do
        db[key] = nil
    end

    for key, value in pairs(defaults) do
        if db[key] == nil then
            if type(value) == "table" then
                db[key] = CopyTable(value)
            else
                db[key] = value
            end
        end
    end

    db.enabled = true
    if type(db.scale) ~= "number" then
        db.scale = defaults.scale
    end
    if type(db.scaleWithNameplate) ~= "boolean" then
        db.scaleWithNameplate = defaults.scaleWithNameplate
    end
    if type(db.opacity) ~= "number" then
        db.opacity = defaults.opacity
    end
    if type(db.timerTextScale) ~= "number" then
        db.timerTextScale = defaults.timerTextScale
    end
    if type(db.timerTextOffsetX) ~= "number" then
        db.timerTextOffsetX = defaults.timerTextOffsetX
    end
    if type(db.timerTextOffsetY) ~= "number" then
        db.timerTextOffsetY = defaults.timerTextOffsetY
    end
    if type(db.showTimerText) ~= "boolean" then
        db.showTimerText = defaults.showTimerText
    end
    if type(db.showTimerDecimals) ~= "boolean" then
        db.showTimerDecimals = defaults.showTimerDecimals
    end
    db.timerDecimalThreshold = math.floor(
        Shared.ClampNumber(db.timerDecimalThreshold, 1, 20, defaults.timerDecimalThreshold) + 0.5
    )
    db.iconLayout = Shared.NormalizeIconLayout(db.iconLayout)
    db.iconGrowth = Shared.NormalizeIconGrowth(db.iconGrowth)
    db.iconVerticalGrowth = Shared.NormalizeVerticalIconGrowth(db.iconVerticalGrowth)
    db.iconPadding = Shared.ClampNumber(db.iconPadding, 0, 20, defaults.iconPadding)
    if type(db.offsetX) ~= "number" then
        db.offsetX = defaults.offsetX
    end
    if type(db.offsetY) ~= "number" then
        db.offsetY = defaults.offsetY
    end
    if type(db.showTimerSwipe) ~= "boolean" then
        db.showTimerSwipe = defaults.showTimerSwipe
    end
    if type(db.showTimerSwipeEdge) ~= "boolean" then
        db.showTimerSwipeEdge = defaults.showTimerSwipeEdge
    end
    if type(db.showDRText) ~= "boolean" then
        db.showDRText = defaults.showDRText
    end
    if type(db.showImmunityIndicator) ~= "boolean" then
        db.showImmunityIndicator = defaults.showImmunityIndicator
    end
    if type(db.trinket) ~= "table" then
        db.trinket = CopyTable(defaults.trinket)
    end
    db.timerTextColor = Shared.NormalizeColorTable(db.timerTextColor, defaults.timerTextColor)
    if type(db.drTextAnchor) ~= "string"
        or db.drTextAnchor == ""
        or not validDRTextAnchors[db.drTextAnchor] then
        db.drTextAnchor = defaults.drTextAnchor
    end
    if type(db.drTextScale) ~= "number" then
        db.drTextScale = defaults.drTextScale
    end
    if type(db.drTextOffsetX) ~= "number" then
        db.drTextOffsetX = defaults.drTextOffsetX
    end
    if type(db.drTextOffsetY) ~= "number" then
        db.drTextOffsetY = defaults.drTextOffsetY
    end
    db.drTextColor = Shared.NormalizeColorTable(db.drTextColor, defaults.drTextColor)
    db.drTextImmuneColor = Shared.NormalizeColorTable(db.drTextImmuneColor, defaults.drTextImmuneColor)
    db.drBorderStyle = Shared.NormalizeDRBorderStyle(db.drBorderStyle)
    db.drBorderColor = Shared.NormalizeColorTable(db.drBorderColor, defaults.drBorderColor)
    db.drBorderImmuneColor = Shared.NormalizeColorTable(db.drBorderImmuneColor, defaults.drBorderImmuneColor)
    db.drBorderWidth = Shared.ClampNumber(db.drBorderWidth, 1, 8, defaults.drBorderWidth)
    if type(db.anchorPreset) ~= "string" or db.anchorPreset == "" then
        db.anchorPreset = Shared.DetectAnchorPreset(db.point, db.relativePoint)
    end

    db.trinket.enabled = db.trinket.enabled == true
    db.trinket.visibility = Shared.NormalizeTrinketVisibility(db.trinket.visibility)
    db.trinket.size = Shared.ClampNumber(db.trinket.size, 12, 80, defaults.trinket.size)
    db.trinket.opacity = Shared.ClampNumber(db.trinket.opacity, 0.1, 1.0, defaults.trinket.opacity)
    db.trinket.borderStyle = Shared.NormalizeTrinketBorderStyle(db.trinket.borderStyle)
    db.trinket.borderColor = Shared.NormalizeColorTable(db.trinket.borderColor, defaults.trinket.borderColor)
    db.trinket.borderWidth = Shared.ClampNumber(db.trinket.borderWidth, 1, 8, defaults.trinket.borderWidth)
    if type(db.trinket.offsetX) ~= "number" then
        db.trinket.offsetX = defaults.trinket.offsetX
    end
    if type(db.trinket.offsetY) ~= "number" then
        db.trinket.offsetY = defaults.trinket.offsetY
    end
    if type(db.trinket.point) ~= "string" or db.trinket.point == "" then
        db.trinket.point = defaults.trinket.point
    end
    if type(db.trinket.relativePoint) ~= "string" or db.trinket.relativePoint == "" then
        db.trinket.relativePoint = defaults.trinket.relativePoint
    end
    if type(db.trinket.anchorPreset) ~= "string" or db.trinket.anchorPreset == "" then
        db.trinket.anchorPreset = Shared.DetectAnchorPreset(db.trinket.point, db.trinket.relativePoint)
    end

    return db
end
