-- 自动生成：Housing CVar 快照
-- 来源：WTF/Account/*/SavedVariables/AdvancedDecorationTools.lua -> ADT_DB.HousingCVarDump
-- 访问日期：2025-12-25

local ADDON_NAME, ADT = ...
if not ADT then return end

local data = {
    { name = "housingDecorFreePlaceEnabled", default = "0" },
    { name = "housingDecorGridSnapEnabled", default = "0" },
    { name = "housingDecorGridVisible", default = "1" },
    { name = "housingExpertGizmos_Rotation_BaseOrbScale", default = "0.080000" },
    { name = "housingExpertGizmos_Rotation_BaseRingScale", default = "0.080000" },
    { name = "housingExpertGizmos_Rotation_DistScaleMax", default = "2.250000" },
    { name = "housingExpertGizmos_Rotation_DistScaleMin", default = "1.000000" },
    { name = "housingExpertGizmos_Rotation_HighlightDefault", default = "0.800000" },
    { name = "housingExpertGizmos_Rotation_HighlightDragging", default = "1.000000" },
    { name = "housingExpertGizmos_Rotation_HighlightHovered", default = "0.900000" },
    { name = "housingExpertGizmos_Rotation_HighlightKeybind", default = "1.000000" },
    { name = "housingExpertGizmos_Rotation_HighlightSelected", default = "1.000000" },
    { name = "housingExpertGizmos_Rotation_OrbPosOffset", default = "-0.800000" },
    { name = "housingExpertGizmos_Rotation_ScaleDistanceMax", default = "60.000000" },
    { name = "housingExpertGizmos_Rotation_ScaleDistanceMin", default = "0.000000" },
    { name = "housingExpertGizmos_Rotation_SnapDegrees", default = "15.000000" },
    { name = "housingExpertGizmos_Rotation_TextMode", default = "1" },
    { name = "housingExpertGizmos_Rotation_XRayCheckerSize", default = "7" },
    { name = "housingExpertGizmos_Rotation_XRayDarkAlpha", default = "0.100000" },
    { name = "housingExpertGizmos_Rotation_XRayLightAlpha", default = "0.250000" },
    { name = "housingExpertGizmos_Scale_FrameOffset", default = "0.500000" },
    { name = "housingExpertGizmos_Scale_Snap", default = "0.100000" },
    { name = "housingExpertGizmos_SnapOnHold", default = "1" },
    { name = "housingExpertGizmos_Translation_BaseArrowHeadScale", default = "0.250000" },
    { name = "housingExpertGizmos_Translation_BaseArrowStemScale", default = "0.300000" },
    { name = "housingExpertGizmos_Translation_BaseCubeScale", default = "0.050000" },
    { name = "housingExpertGizmos_Translation_DistScaleMax", default = "8.000000" },
    { name = "housingExpertGizmos_Translation_DistScaleMin", default = "1.000000" },
    { name = "housingExpertGizmos_Translation_HighlightDefault", default = "0.800000" },
    { name = "housingExpertGizmos_Translation_HighlightDragging", default = "1.000000" },
    { name = "housingExpertGizmos_Translation_HighlightHovered", default = "0.900000" },
    { name = "housingExpertGizmos_Translation_HighlightKeybind", default = "1.000000" },
    { name = "housingExpertGizmos_Translation_HighlightSelected", default = "1.000000" },
    { name = "housingExpertGizmos_Translation_MaxDistanceFromCamera", default = "1000.000000" },
    { name = "housingExpertGizmos_Translation_Padding", default = "0.050000" },
    { name = "housingExpertGizmos_Translation_ScaleDistanceMax", default = "60.000000" },
    { name = "housingExpertGizmos_Translation_ScaleDistanceMin", default = "0.000000" },
    { name = "housingExpertGizmos_Translation_XRayCheckerSize", default = "7" },
    { name = "housingExpertGizmos_Translation_XRayDarkAlpha", default = "0.600000" },
    { name = "housingExpertGizmos_Translation_XRayLightAlpha", default = "0.250000" },
    { name = "housingLayout_Camera_DefaultDistance", default = "50.000000" },
    { name = "housingLayout_Camera_DragFriction", default = "8.000000" },
    { name = "housingLayout_Camera_DragMomentum", default = "0.300000" },
    { name = "housingLayout_Camera_MaxDistance", default = "80.000000" },
    { name = "housingLayout_Camera_MaxDistanceIncr", default = "5.000000" },
    { name = "housingLayout_Camera_MinDistance", default = "30.000000" },
    { name = "housingLayout_Camera_Smoothness", default = "15.000000" },
    { name = "housingLayout_Camera_Speed", default = "15.000000" },
    { name = "housingStoragePanelCollapsed", default = "0" },
    { name = "housingStoragePanelHeight", default = "615.000000" },
    { name = "housingStoragePanelWidth", default = "530.000000" },
    { name = "housingTutorialsEnabled", default = "1" },
}

local map = {}
for _, item in ipairs(data) do
    if item.name then
        map[item.name] = item
    end
end

ADT.HousingCVars = {
    list = data,
    map = map,
}

function ADT.GetHousingCVarDefaultNumber(name)
    local item = map[name]
    if not item or item.default == nil then return nil end
    return tonumber(item.default)
end
