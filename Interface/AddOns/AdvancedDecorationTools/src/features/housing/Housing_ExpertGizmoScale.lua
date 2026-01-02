-- Housing_ExpertGizmoScale.lua
-- 专家模式操控器缩放（通过 CVar 组统一控制）

local ADDON_NAME, ADT = ...
if not ADT or not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local GizmoScale = {}
ADT.HousingGizmoScale = GizmoScale

-- DB 键（单一权威：用户设置的倍率存储在 DB）
local DB_KEYS = {
    Translation = "ExpertGizmoScaleTranslation",
    Rotation = "ExpertGizmoScaleRotation",
}

local function GetDBMultiplier(key)
    if not ADT.GetDBValue then return nil end
    local dbKey = DB_KEYS[key]
    if not dbKey then return nil end
    local v = ADT.GetDBValue(dbKey)
    if v == nil then return nil end
    return tonumber(v)
end

local function SetDBMultiplier(key, value)
    if not ADT.SetDBValue then return end
    local dbKey = DB_KEYS[key]
    if not dbKey then return end
    ADT.SetDBValue(dbKey, value)
end

local function GetCVarNumber(name)
    local v = GetCVar and GetCVar(name)
    if v == nil and C_CVar and C_CVar.GetCVar then
        v = C_CVar.GetCVar(name)
    end
    return tonumber(v)
end

local function NearlyEqual(a, b)
    if a == nil or b == nil then return false end
    return math.abs(a - b) <= 0.0005
end

local function ApplyCVarNumber(name, value)
    local valueStr = tostring(value)
    local ok
    if C_CVar and C_CVar.SetCVar then
        ok = C_CVar.SetCVar(name, valueStr)
    end
    if ok ~= true and SetCVar then
        ok = SetCVar(name, valueStr)
    end

    local target = tonumber(valueStr)
    local after = GetCVarNumber(name)
    if target and after and NearlyEqual(after, target) then
        return true, after
    end

    if ConsoleExec then
        ConsoleExec(string.format("%s %s", name, valueStr))
        after = GetCVarNumber(name)
        if target and after and NearlyEqual(after, target) then
            return true, after
        end
    end

    return ok == true, after
end

local function CanSwitchSubmode(submode)
    if not C_HousingExpertMode or not C_HousingExpertMode.GetPrecisionSubmodeRestriction then
        return true
    end
    if not Enum or not Enum.HousingExpertSubmodeRestriction then
        return true
    end
    local restriction = C_HousingExpertMode.GetPrecisionSubmodeRestriction(submode)
    return restriction == Enum.HousingExpertSubmodeRestriction.None
end

local function ForceRefreshPrecisionSubmode()
    if not C_HouseEditor or not C_HousingExpertMode then return end
    if not C_HouseEditor.IsHouseEditorActive or not C_HouseEditor.GetActiveHouseEditorMode then return end
    if not Enum or not Enum.HouseEditorMode then return end
    if not C_HouseEditor.IsHouseEditorActive() then return end
    if C_HouseEditor.GetActiveHouseEditorMode() ~= Enum.HouseEditorMode.ExpertDecor then return end
    if not C_HousingExpertMode.GetPrecisionSubmode or not C_HousingExpertMode.SetPrecisionSubmode then return end
    local submode = C_HousingExpertMode.GetPrecisionSubmode()
    if submode ~= nil then
        local fallback = Enum.HousingPrecisionSubmode and Enum.HousingPrecisionSubmode.Translate or nil
        if fallback ~= nil and fallback ~= submode and CanSwitchSubmode(fallback) then
            C_HousingExpertMode.SetPrecisionSubmode(fallback)
        end
        C_HousingExpertMode.SetPrecisionSubmode(submode)
    end
end

local function RequestRefreshPrecisionSubmode()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, ForceRefreshPrecisionSubmode)
    else
        ForceRefreshPrecisionSubmode()
    end
end

local GROUP_DEFS = {
    Translation = {
        key = "Translation",
        names = {
            "housingExpertGizmos_Translation_BaseArrowHeadScale",
            "housingExpertGizmos_Translation_BaseArrowStemScale",
            "housingExpertGizmos_Translation_BaseCubeScale",
        },
    },
    Rotation = {
        key = "Rotation",
        names = {
            "housingExpertGizmos_Rotation_BaseRingScale",
            "housingExpertGizmos_Rotation_BaseOrbScale",
        },
    },
}

local function BuildGroups()
    local map = ADT.HousingCVars and ADT.HousingCVars.map
    if not map then return {} end

    local groups = {}
    for _, def in pairs(GROUP_DEFS) do
        local group = { key = def.key, items = {} }
        for _, name in ipairs(def.names) do
            local item = map[name]
            if item and item.default ~= nil then
                local defVal = tonumber(item.default)
                if defVal ~= nil then
                    table.insert(group.items, { name = name, default = defVal })
                end
            end
        end
        group.primary = group.items[1]
        groups[def.key] = group
    end

    return groups
end

function GizmoScale:Refresh(force)
    if self._ready and not force then return end
    self._groups = BuildGroups()
    self._ready = true
end

function GizmoScale:GetGroup(key)
    self:Refresh(false)
    if not self._groups then return nil end
    return self._groups[key]
end

function GizmoScale:GetMultiplier(key)
    local dbValue = GetDBMultiplier(key)
    if dbValue ~= nil then
        return dbValue
    end
    return self:GetMultiplierFromCVar(key)
end

function GizmoScale:GetMultiplierFromCVar(key)
    local group = self:GetGroup(key)
    if not group or not group.primary or not group.primary.default then return nil end
    if group.primary.default == 0 then return nil end
    local current = GetCVarNumber(group.primary.name)
    if not current then return nil end
    return current / group.primary.default
end

function GizmoScale:ApplyMultiplier(key, multiplier, opts)
    local group = self:GetGroup(key)
    if not group or not group.items then return end
    local skipRefresh = opts and opts.skipRefresh
    for _, item in ipairs(group.items) do
        if item.default ~= nil then
            local v = item.default * multiplier
            local ok, after = ApplyCVarNumber(item.name, string.format("%.6f", v))
            if ADT.DebugPrint then
                ADT.DebugPrint(string.format("[CVar] SetCVar %s = %s (ok=%s after=%s)", item.name, tostring(v), tostring(ok), tostring(after)))
            end
        end
    end
    if not skipRefresh then
        RequestRefreshPrecisionSubmode()
    end
end

function GizmoScale:SetMultiplier(key, multiplier)
    multiplier = tonumber(multiplier)
    if multiplier == nil then return end
    SetDBMultiplier(key, multiplier)
    self:ApplyMultiplier(key, multiplier)
end

function GizmoScale:ResetToDefault(key)
    SetDBMultiplier(key, 1.0)
    self:ApplyMultiplier(key, 1.0)
    if ADT.DebugPrint then
        ADT.DebugPrint(string.format("[CVar] Reset multiplier %s = 1.0", tostring(key)))
    end
end

function GizmoScale:ApplyAll()
    local applied = false
    for key, _ in pairs(GROUP_DEFS) do
        local v = GetDBMultiplier(key)
        if v ~= nil then
            self:ApplyMultiplier(key, v, { skipRefresh = true })
            applied = true
        end
    end
    if applied then
        RequestRefreshPrecisionSubmode()
    end
end

-- 进入专家模式或 HouseEditor 加载后，重应用用户倍率（持久化）
do
    local function IsExpertModeActive()
        if not C_HouseEditor or not C_HouseEditor.IsHouseEditorActive or not C_HouseEditor.GetActiveHouseEditorMode then return false end
        if not Enum or not Enum.HouseEditorMode then return false end
        if not C_HouseEditor.IsHouseEditorActive() then return false end
        return C_HouseEditor.GetActiveHouseEditorMode() == Enum.HouseEditorMode.ExpertDecor
    end

    local function ApplyIfReady()
        if IsExpertModeActive() then
            GizmoScale:ApplyAll()
        end
    end

    local EL = CreateFrame("Frame")
    EL:RegisterEvent("ADDON_LOADED")
    EL:RegisterEvent("HOUSE_EDITOR_MODE_CHANGED")
    EL:SetScript("OnEvent", function(_, event, arg1)
        if event == "ADDON_LOADED" then
            if arg1 ~= "Blizzard_HouseEditor" then return end
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, ApplyIfReady)
        else
            ApplyIfReady()
        end
    end)

    if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_HouseEditor") then
        if C_Timer and C_Timer.After then
            C_Timer.After(0, ApplyIfReady)
        else
            ApplyIfReady()
        end
    end
end
