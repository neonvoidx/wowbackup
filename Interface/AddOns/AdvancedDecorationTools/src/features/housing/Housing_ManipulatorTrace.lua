-- 专家模式操控器调试追踪：定位“子模式切换/模式切换后操控器残留”问题

local ADDON_NAME, ADT = ...
if not ADT or not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local Trace = {}
ADT.HousingManipulatorTrace = Trace

local COLORS = {
    Mode = "FF66CCFF",      -- 模式切换
    Submode = "FFFFD166",   -- 子模式切换
    Manip = "FFFF6B6B",     -- 操控事件/状态
    Api = "FF7CFC99",       -- API 调用
    Select = "FFA78BFA",    -- 选中/悬停
    Hook = "FFB0BEC5",      -- 钩子/混入
}

local function D(tag, color, ...)
    if ADT and ADT.DebugPrintColor then
        ADT.DebugPrintColor(tag, color, ...)
        return
    end
    if ADT and ADT.DebugPrint then
        local first = select(1, ...)
        if first == nil then
            ADT.DebugPrint("[" .. tostring(tag) .. "]")
        else
            ADT.DebugPrint("[" .. tostring(tag) .. "] " .. tostring(first))
        end
    end
end

local function EnumName(enumTable, value)
    if value == nil then return "nil" end
    if not enumTable then return tostring(value) end
    for k, v in pairs(enumTable) do
        if v == value then return k end
    end
    return tostring(value)
end

local function GetActiveMode()
    if C_HouseEditor and C_HouseEditor.GetActiveHouseEditorMode then
        return C_HouseEditor.GetActiveHouseEditorMode()
    end
end

local function GetSubmode()
    if C_HousingExpertMode and C_HousingExpertMode.GetPrecisionSubmode then
        return C_HousingExpertMode.GetPrecisionSubmode()
    end
end

local function IsDecorSelected()
    if C_HousingExpertMode and C_HousingExpertMode.IsDecorSelected then
        return C_HousingExpertMode.IsDecorSelected()
    end
    return false
end

local function IsHouseSelected()
    if C_HousingExpertMode and C_HousingExpertMode.IsHouseExteriorSelected then
        return C_HousingExpertMode.IsHouseExteriorSelected()
    end
    return false
end

local function ModeName(value)
    local enumTable = Enum and Enum.HouseEditorMode
    return EnumName(enumTable, value)
end

local function SubmodeName(value)
    local enumTable = Enum and Enum.HousingPrecisionSubmode
    return EnumName(enumTable, value)
end

local function ManipEventName(value)
    local enumTable = Enum and Enum.TransformManipulatorEvent
    return EnumName(enumTable, value)
end

local function TargetTypeName(value)
    local enumTable = Enum and Enum.HousingExpertModeTargetType
    return EnumName(enumTable, value)
end

local function FrameName(frame)
    if frame and frame.GetName then
        return frame:GetName()
    end
    return "nil"
end

Trace.lastMode = nil
Trace.lastSubmode = nil
Trace.lastManipulating = nil

local function LogState(prefix)
    local mode = GetActiveMode()
    local submode = GetSubmode()
    D(prefix, COLORS.Mode,
        "mode=", ModeName(mode),
        "submode=", SubmodeName(submode),
        "decorSelected=", tostring(IsDecorSelected()),
        "houseSelected=", tostring(IsHouseSelected()),
        "isManipulating=", tostring(Trace.lastManipulating))
end

local function InstallHooks()
    if Trace._hooksInstalled then return end
    Trace._hooksInstalled = true

    if C_HouseEditor and C_HouseEditor.ActivateHouseEditorMode then
        hooksecurefunc(C_HouseEditor, "ActivateHouseEditorMode", function(mode)
            D("接口", COLORS.Api,
                "调用 ActivateHouseEditorMode:", ModeName(mode),
                "当前=", ModeName(GetActiveMode()),
                "操控=", tostring(Trace.lastManipulating))
        end)
    end

    if C_HousingExpertMode and C_HousingExpertMode.SetPrecisionSubmode then
        hooksecurefunc(C_HousingExpertMode, "SetPrecisionSubmode", function(submode)
            D("接口", COLORS.Api,
                "调用 SetPrecisionSubmode:", SubmodeName(submode),
                "当前=", SubmodeName(GetSubmode()),
                "操控=", tostring(Trace.lastManipulating))
        end)
    end

    if C_HousingExpertMode and C_HousingExpertMode.SetPrecisionIncrementingActive then
        hooksecurefunc(C_HousingExpertMode, "SetPrecisionIncrementingActive", function(incrementType, active)
            D("接口", COLORS.Api,
                "调用 SetPrecisionIncrementingActive:", EnumName(Enum and Enum.HousingIncrementType, incrementType),
                "active=", tostring(active),
                "submode=", SubmodeName(GetSubmode()))
        end)
    end

    if C_HousingExpertMode and C_HousingExpertMode.CancelActiveEditing then
        hooksecurefunc(C_HousingExpertMode, "CancelActiveEditing", function()
            D("接口", COLORS.Api, "调用 CancelActiveEditing", "操控=", tostring(Trace.lastManipulating))
        end)
    end

    if C_HousingExpertMode and C_HousingExpertMode.CommitDecorMovement then
        hooksecurefunc(C_HousingExpertMode, "CommitDecorMovement", function()
            D("接口", COLORS.Api, "调用 CommitDecorMovement", "操控=", tostring(Trace.lastManipulating))
        end)
    end

    if C_HousingExpertMode and C_HousingExpertMode.CommitHouseExteriorPosition then
        hooksecurefunc(C_HousingExpertMode, "CommitHouseExteriorPosition", function()
            D("接口", COLORS.Api, "调用 CommitHouseExteriorPosition", "操控=", tostring(Trace.lastManipulating))
        end)
    end

    if C_HousingExpertMode and C_HousingExpertMode.ResetPrecisionChanges then
        hooksecurefunc(C_HousingExpertMode, "ResetPrecisionChanges", function(activeSubmodeOnly)
            D("接口", COLORS.Api,
                "调用 ResetPrecisionChanges:", "activeSubmodeOnly=", tostring(activeSubmodeOnly),
                "submode=", SubmodeName(GetSubmode()))
        end)
    end

    if HouseEditorFrameMixin and HouseEditorFrameMixin.OnActiveModeChanged then
        hooksecurefunc(HouseEditorFrameMixin, "OnActiveModeChanged", function(self, newMode)
            D("钩子", COLORS.Hook,
                "Frame.OnActiveModeChanged:", ModeName(newMode),
                "activeFrame=", FrameName(self and self.activeModeFrame))
        end)
    end

    if HouseEditorExpertDecorModeMixin and HouseEditorExpertDecorModeMixin.HandleManipulatorEvent then
        hooksecurefunc(HouseEditorExpertDecorModeMixin, "HandleManipulatorEvent", function(self, manipulatorEvent)
            local name = ManipEventName(manipulatorEvent)
            if name == "Change" then return end
            D("操控", COLORS.Manip,
                "Mixin.HandleManipulatorEvent:", name,
                "submode=", SubmodeName(GetSubmode()),
                "isManipulating=", tostring(self and self.isManipulating))
        end)
    end
end

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("HOUSE_EDITOR_MODE_CHANGED")
EventFrame:RegisterEvent("HOUSE_EDITOR_MODE_CHANGE_FAILURE")
EventFrame:RegisterEvent("HOUSING_DECOR_PRECISION_SUBMODE_CHANGED")
EventFrame:RegisterEvent("HOUSING_DECOR_PRECISION_MANIPULATION_STATUS_CHANGED")
EventFrame:RegisterEvent("HOUSING_DECOR_PRECISION_MANIPULATION_EVENT")
EventFrame:RegisterEvent("HOUSING_EXPERT_MODE_SELECTED_TARGET_CHANGED")
EventFrame:RegisterEvent("HOUSING_EXPERT_MODE_HOVERED_TARGET_CHANGED")

EventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "Blizzard_HouseEditor" then
            InstallHooks()
            D("钩子", COLORS.Hook, "已安装操控器追踪钩子")
            LogState("状态")
        end
        return
    end

    if event == "HOUSE_EDITOR_MODE_CHANGED" then
        local mode = ...
        local prev = Trace.lastMode
        Trace.lastMode = mode
        D("模式", COLORS.Mode,
            "HOUSE_EDITOR_MODE_CHANGED:", "prev=", ModeName(prev), "new=", ModeName(mode),
            "submode=", SubmodeName(GetSubmode()),
            "操控=", tostring(Trace.lastManipulating))
        return
    end

    if event == "HOUSE_EDITOR_MODE_CHANGE_FAILURE" then
        local result = ...
        D("模式", COLORS.Mode, "HOUSE_EDITOR_MODE_CHANGE_FAILURE:", tostring(result))
        return
    end

    if event == "HOUSING_DECOR_PRECISION_SUBMODE_CHANGED" then
        local submode = ...
        local prev = Trace.lastSubmode
        Trace.lastSubmode = submode
        D("子模式", COLORS.Submode,
            "HOUSING_DECOR_PRECISION_SUBMODE_CHANGED:", "prev=", SubmodeName(prev), "new=", SubmodeName(submode),
            "mode=", ModeName(GetActiveMode()),
            "操控=", tostring(Trace.lastManipulating))
        return
    end

    if event == "HOUSING_DECOR_PRECISION_MANIPULATION_STATUS_CHANGED" then
        local isManipulating = ...
        local prev = Trace.lastManipulating
        Trace.lastManipulating = isManipulating
        D("操控", COLORS.Manip,
            "HOUSING_DECOR_PRECISION_MANIPULATION_STATUS_CHANGED:",
            "prev=", tostring(prev), "new=", tostring(isManipulating),
            "submode=", SubmodeName(GetSubmode()),
            "mode=", ModeName(GetActiveMode()))
        return
    end

    if event == "HOUSING_DECOR_PRECISION_MANIPULATION_EVENT" then
        local manipEvent = ...
        local name = ManipEventName(manipEvent)
        if name == "Change" then return end
        D("操控", COLORS.Manip,
            "HOUSING_DECOR_PRECISION_MANIPULATION_EVENT:", name,
            "submode=", SubmodeName(GetSubmode()),
            "操控=", tostring(Trace.lastManipulating))
        return
    end

    if event == "HOUSING_EXPERT_MODE_SELECTED_TARGET_CHANGED" then
        local hasSelected, targetType = ...
        D("选中", COLORS.Select,
            "HOUSING_EXPERT_MODE_SELECTED_TARGET_CHANGED:",
            "selected=", tostring(hasSelected),
            "targetType=", TargetTypeName(targetType),
            "submode=", SubmodeName(GetSubmode()),
            "操控=", tostring(Trace.lastManipulating))
        return
    end

    if event == "HOUSING_EXPERT_MODE_HOVERED_TARGET_CHANGED" then
        local hasHovered, targetType = ...
        D("选中", COLORS.Select,
            "HOUSING_EXPERT_MODE_HOVERED_TARGET_CHANGED:",
            "hovered=", tostring(hasHovered),
            "targetType=", TargetTypeName(targetType))
        return
    end
end)

if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_HouseEditor") then
    InstallHooks()
    D("钩子", COLORS.Hook, "已安装操控器追踪钩子（立即）")
    LogState("状态")
end

if EventRegistry and EventRegistry.RegisterCallback then
    EventRegistry:RegisterCallback("HouseEditor.StateUpdated", function(_, isActive)
        D("模式", COLORS.Mode, "HouseEditor.StateUpdated:", tostring(isActive))
        LogState("状态")
    end)
end

if ADT and ADT.DebugPrint then
    ADT.DebugPrint("[操控追踪] 模块已加载")
end
