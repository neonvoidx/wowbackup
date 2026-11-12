---@class MapPinEnhanced
local MapPinEnhanced = select(2, ...)

local Wayfinders = MapPinEnhanced:GetModule("Wayfinders")
local Groups = MapPinEnhanced:GetModule("Groups")

-- Foreign integrations retain their stack-based exclusion. Owned writes are identified before inspection.
local BLOCKED_ADDON_LIST = {
    "WorldQuestTracker",
}

local function isBlockedAddon(stack)
    for _, blockedAddon in ipairs(BLOCKED_ADDON_LIST) do
        if stack.find(stack, blockedAddon) then
            return true
        end
    end
    return false
end


---@enum PIN_TEXTURE_OVERRIDES
local PIN_TEXTURE_OVERRIDES = {
    ["worldquest-questmarker-questbang"] = "worldquest-tracker-questmarker",
}

---@param value any
---@return string?
local function ReadPinText(value)
    if not MapPinEnhanced:IsSecretValue(value) and type(value) == "string" and value ~= "" then
        return MapPinEnhanced:ToPlainText(value)
    end
end

---@class BlizzardWaypointPin : Frame
---@field pinTemplate string?
---@field GetMap fun(self: BlizzardWaypointPin): MapCanvasMixin?
---@field GetPosition fun(self: BlizzardWaypointPin): number?, number?
---@field GetDisplayName (fun(self: BlizzardWaypointPin): string?)?
---@field GetBestNameAndDescription (fun(self: BlizzardWaypointPin): string?)?
---@field name string?
---@field questName string?
---@field questID number?
---@field texture string|number?
---@field poiInfo AreaPOIInfo?
---@field vignetteInfo VignetteInfo?
---@field Display {Icon: Texture}?
---@field Texture Texture?
---@field Icon Texture?

---@class BlizzardWaypointPinInfo
---@field name string?
---@field texture string|number?
---@field isAtlas boolean
---@field x number?
---@field y number?

---@param pin BlizzardWaypointPin
---@return BlizzardWaypointPinInfo
local function ParseBlizzardMapPinInfo(pin)
    -- Every MapCanvas pin inherits an asserting stub; only call concrete overrides.
    local name = pin.GetDisplayName and pin.GetDisplayName ~= MapCanvasPinMixin.GetDisplayName
        and ReadPinText(pin:GetDisplayName())
    if not name and pin.GetBestNameAndDescription then name = ReadPinText(pin:GetBestNameAndDescription()) end
    name = name or ReadPinText(pin.name) or ReadPinText(pin.questName)
    if not name and MapPinEnhanced:IsReadablePositiveInteger(pin.questID) then
        name = ReadPinText(C_QuestLog.GetTitleForQuestID(pin.questID)) or
            ReadPinText(C_TaskQuest.GetQuestInfoByQuestID(pin.questID))
    end

    local texture, isAtlas = nil, false
    -- Read the displayed artwork: POIs can apply texture kits and POI buttons use a separate icon.
    local icon = pin.Display and pin.Display.Icon or pin.Texture or pin.Icon
    if icon and MapPinEnhanced:IsReadableTable(icon) then
        texture = ReadPinText(icon:GetAtlas())
        isAtlas = texture ~= nil
        if not texture then
            local file = icon:GetTexture()
            texture = ReadPinText(file) or (MapPinEnhanced:IsReadablePositiveInteger(file) and file or nil)
        end
    end
    if not texture then
        local info = pin.poiInfo or pin.vignetteInfo
        if info and MapPinEnhanced:IsReadableTable(info) then
            texture = ReadPinText(info.atlasName)
            isAtlas = texture ~= nil
            name = name or ReadPinText(info.name)
        end
        texture = texture or ReadPinText(pin.texture) or
            (MapPinEnhanced:IsReadablePositiveInteger(pin.texture) and pin.texture or nil)
    end
    if isAtlas and texture then texture = PIN_TEXTURE_OVERRIDES[texture] or texture end

    local x, y = pin:GetPosition()
    if not MapPinEnhanced:IsCoordinate(x) or not MapPinEnhanced:IsCoordinate(y) then x, y = nil, nil end
    return { name = name, texture = texture, isAtlas = isAtlas, x = x, y = y }
end

---@param mapID number
---@return BlizzardWaypointPinInfo?
local function DetectMouseFocusPinInfo(mapID)
    for _, focus in ipairs(GetMouseFoci() or {}) do
        ---@cast focus BlizzardWaypointPin?
        -- A widget child can receive focus; MapCanvas owns pin identity regardless of template spelling.
        while focus and MapPinEnhanced:IsReadableTable(focus) do
            if focus:IsForbidden() then break end
            if ReadPinText(focus.pinTemplate) and focus.GetMap and focus.GetPosition then
                local map = focus:GetMap()
                local pinMapID = map and map:GetMapID()
                if MapPinEnhanced:IsReadablePositiveInteger(pinMapID) and pinMapID == mapID then
                    return ParseBlizzardMapPinInfo(focus)
                end
                break
            end
            focus = focus:GetParent()
        end
    end
end


---@param uiMapPoint {uiMapID: number, position: {x: number, y: number}}
local function OnUserWaypoint(uiMapPoint)
    if not uiMapPoint or Wayfinders:IsOwnedUserWaypoint(uiMapPoint) then return end
    local stack = debugstack(2) ---@type string
    if isBlockedAddon(stack) then return end -- ignore calls from this function

    -- A slash/link/background write must not inherit metadata from a pin merely being hovered.
    local fromMapClick = stack:find("WaypointLocationDataProvider.lua:", 1, true)
    local mouseFocusInfo = fromMapClick and DetectMouseFocusPinInfo(uiMapPoint.uiMapID) or nil
    local mapID, x, y = MapPinEnhanced:GetModule("Pins"):ResolvePinPosition(uiMapPoint.uiMapID,
        mouseFocusInfo and mouseFocusInfo.x or uiMapPoint.position.x,
        mouseFocusInfo and mouseFocusInfo.y or uiMapPoint.position.y)
    if not mapID then return end
    local isSuperTracking = C_SuperTrack.IsSuperTrackingAnything()
    local isSuperTrackingUserWaypoint = C_SuperTrack.IsSuperTrackingUserWaypoint()
    local isSuperTrackingCorpse = C_SuperTrack.IsSuperTrackingCorpse()

    if isSuperTracking and not isSuperTrackingUserWaypoint and not isSuperTrackingCorpse then
        C_SuperTrack.ClearAllSuperTracked()
    end
    local uncategorizedGroup = Groups:GetUngroupedGroup()
    if not uncategorizedGroup then return end
    local _, pinID = uncategorizedGroup:AddPin({
        mapID = mapID,
        x = x,
        y = y,
        title = mouseFocusInfo and mouseFocusInfo.name or nil,
        texture = mouseFocusInfo and mouseFocusInfo.texture or nil,
        usesAtlas = mouseFocusInfo and mouseFocusInfo.isAtlas or false,
        setTracked = not isSuperTrackingCorpse
    })
    -- Only Blizzard's explicit map/slash/link entry points carry user-add intent.
    -- Other addons may call the waypoint API for background updates.
    local userCreated = fromMapClick or stack:find("ItemRefHandlers.lua:", 1, true)
    if pinID and userCreated then MapPinEnhanced:GetModule("Tracker"):OnUserPinsAdded() end
end


local isHooked = false
local function HookSetUserWaypoint()
    if isHooked then return end
    if not C_Map.SetUserWaypoint then return end
    hooksecurefunc(C_Map, "SetUserWaypoint", OnUserWaypoint)
    isHooked = true
end

MapPinEnhanced:RegisterEvent("PLAYER_LOGIN", HookSetUserWaypoint)
