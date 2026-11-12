---@diagnostic disable: no-unknown
---@class MapPinEnhanced
local MapPinEnhanced = select(2, ...)
local L = MapPinEnhanced.L
local Groups = MapPinEnhanced:GetModule("Groups")
local Pins = MapPinEnhanced:GetModule("Pins")
local Options = MapPinEnhanced:GetModule("Options")
local OPTION_KEY = "Pins.TomTom"
local integrationEnabled = Options:GetOptionInitValue(OPTION_KEY) == true

---@type table<UUID, TomTomPinLink>
local links = {}
---@type table<TomTomUID, UUID>
local bindings = {}
---@type table<TomTomUID, boolean>
local clearedWaypoints = setmetatable({}, { __mode = "k" })
---@type TomTomUID?
local selected
---@type TomTomUID?
local nativeSelected
local synchronizing, loggedIn = false, false
local needsRebind = true
---@type FunctionContainer?
local pendingSync

local savedLinks = MapPinEnhanced:GetVar("tomtomPins")
if type(savedLinks) == "table" then
    for pinID, link in pairs(savedLinks) do
        if type(pinID) == "string" and type(link) == "table" and type(link.groupID) == "string" and
            type(link.character) == "string" and type(link.profile) == "string" and
            MapPinEnhanced:IsReadablePositiveInteger(link.mapID) and
            MapPinEnhanced:IsCoordinate(link.x) and MapPinEnhanced:IsCoordinate(link.y) and
            (link.title == nil or type(link.title) == "string") and type(link.cleared) == "boolean" and
            type(link.persistent) == "boolean" then
            links[pinID] = CopyTable(link)
        end
    end
end

local function GetNativeProfile()
    return TomTom and TomTom.waydb and TomTom.waydb:GetCurrentProfile()
end

---@param link TomTomPinLink
---@return boolean
local function IsCurrentLink(link)
    return link.character == MapPinEnhanced:GetCharacterKey() and link.profile == GetNativeProfile()
end

---@param pinID UUID
local function PersistLink(pinID)
    MapPinEnhanced:SetVar("tomtomPins", pinID, CopyTable(links[pinID]))
end

-- A move retains the pin ID, including when the destination group is hidden.
---@param pinID UUID
---@return MapPinEnhancedGroupMixin?
local function FindLinkedGroup(pinID)
    local link = links[pinID]
    local group = link and Groups:GetGroupByID(link.groupID)
    if group and (group:GetPinByID(pinID) or group:GetArchivedPinByID(pinID)) then return group end
    for candidate in Groups:EnumerateGroups() do
        if candidate:GetPinByID(pinID) or candidate:GetArchivedPinByID(pinID) then return candidate end
    end
end

---@param uid TomTomUID
---@param group MapPinEnhancedGroupMixin
---@param pinID UUID
local function BindWaypoint(uid, group, pinID)
    local character, profile = MapPinEnhanced:GetCharacterKey(), GetNativeProfile()
    if not character or not profile then return end
    for oldUID, boundID in pairs(bindings) do
        if boundID == pinID then bindings[oldUID] = nil end
    end
    bindings[uid] = pinID
    local link = links[pinID]
    if not link then
        link = { groupID = group:GetGroupID(), character = character, profile = profile,
            mapID = uid[1], x = uid[2], y = uid[3], title = uid.title,
            persistent = uid.persistent == true, cleared = false }
        links[pinID] = link
        PersistLink(pinID)
    elseif link.groupID ~= group:GetGroupID() then
        link.groupID = group:GetGroupID()
        PersistLink(pinID)
    end
end

---@param uid any
---@return MapPinEnhancedGroupMixin?, UUID?
local function GetBoundGroup(uid)
    if not MapPinEnhanced:IsReadableTable(uid) then return end
    local pinID = bindings[uid]
    if pinID and links[pinID] and IsCurrentLink(links[pinID]) then
        return FindLinkedGroup(pinID), pinID
    end
end

---@param uid any
---@return MapPinEnhancedPinMixin?
local function GetBoundPin(uid)
    local group, pinID = GetBoundGroup(uid)
    return group and group:GetPinByID(pinID)
end

---@param uid TomTomUID
---@return boolean
local function IsKalielWaypoint(uid)
    -- Kaliel's arrow mirrors an existing native source. Tracking an MPE copy
    -- clears that source, making Kaliel remove the waypoint we just selected.
    return MapPinEnhanced:IsSecretValue(uid.KTid) or uid.KTid ~= nil
end

---@param uid any
---@param existingOnly boolean?
---@return MapPinEnhancedPinMixin?
local function AddTomTomWaypoint(uid, existingOnly)
    if not MapPinEnhanced:GetCharacterKey() or not GetNativeProfile() then return end
    if not MapPinEnhanced:IsReadableTable(uid) or MapPinEnhanced:IsSecretValue(uid.corpse) or uid.corpse then return end
    if IsKalielWaypoint(uid) then return end
    if not MapPinEnhanced:IsReadablePositiveInteger(uid[1]) or
        not MapPinEnhanced:IsCoordinate(uid[2]) or not MapPinEnhanced:IsCoordinate(uid[3]) then
        return
    end
    if MapPinEnhanced:IsSecretValue(uid.title) or
        (uid.title ~= nil and type(uid.title) ~= "string") or MapPinEnhanced:IsSecretValue(uid.persistent) then return end
    if not bindings[uid] then
        for pinID, link in pairs(links) do
            if IsCurrentLink(link) and link.mapID == uid[1] and link.x == uid[2] and
                link.y == uid[3] and link.title == uid.title then
                local group = FindLinkedGroup(pinID)
                if group then
                    BindWaypoint(uid, group, pinID)
                else
                    bindings[uid] = pinID
                end
                break
            end
        end
    end
    local boundGroup, boundPinID = GetBoundGroup(uid)
    -- A retained link may be awaiting intake or deletion reconciliation. Native
    -- profile restoration must not recreate a pin that MPE has already deleted.
    if boundPinID and not boundGroup then return end
    if boundGroup then
        if not existingOnly and not boundGroup:GetPinByID(boundPinID) then boundGroup:RestorePin(boundPinID) end
        return boundGroup:GetPinByID(boundPinID)
    end
    local mapID, x, y = Pins:ResolvePinPosition(uid[1], uid[2], uid[3])
    if not mapID then return end
    local title = uid.title
    if MapPinEnhanced:IsSecretValue(title) or type(title) ~= "string" then title = "" end
    title = MapPinEnhanced:CompactChatLabel(title, 64)
    if title == "" then title = L["TomTom Waypoint"] end
    local texture = uid.minimap_icon
    if MapPinEnhanced:IsSecretValue(texture) or
        not ((type(texture) == "string" and texture ~= "") or MapPinEnhanced:IsReadablePositiveInteger(texture)) then
        texture = "Interface\\Icons\\INV_Misc_Map_01"
    end
    local group = Groups:GetTomTomGroup()
    if not group then return end
    -- Native handles are session-local. Reattach matching saved pins after reload.
    for _, entry in ipairs(group:GetPinEntries()) do
        local data = entry.data
        if entry.state ~= "cleared" and data.mapID == mapID and data.x == x and data.y == y and data.title == title then
            local claimed = false
            for _, binding in pairs(bindings) do
                if binding == entry.pinID then
                    claimed = true
                    break
                end
            end
            if not claimed and not links[entry.pinID] then
                BindWaypoint(uid, group, entry.pinID)
                return entry.pin
            end
        end
    end
    if existingOnly then return end
    local pin, pinID = group:AddPin({ mapID = mapID, x = x, y = y, title = title, texture = texture })
    if pinID then BindWaypoint(uid, group, pinID) end
    return pin
end

---@param uid any
local function UntrackWaypoint(uid)
    local pin = GetBoundPin(uid)
    if pin and pin:IsTracked() then pin:Untrack() end
end

---@param uid any
local function SelectWaypoint(uid)
    local pin = AddTomTomWaypoint(uid)
    if not GetBoundGroup(uid) then return end
    if selected ~= uid then UntrackWaypoint(selected) end
    selected = uid
    if pin and not pin:IsTracked() then pin:Track() end
end

---@param link TomTomPinLink
---@return TomTomUID?
local function FindNativeWaypoint(link)
    local native = TomTom
    local waypoints = native and native.waypoints and native.waypoints[link.mapID]
    if not waypoints or not native or type(native.GetKeyArgs) ~= "function" then return end
    return waypoints[native:GetKeyArgs(link.mapID, link.x, link.y, link.title)]
end

---@param pinID UUID
local function ForgetLink(pinID)
    links[pinID] = nil
    MapPinEnhanced:DeleteVar("tomtomPins", pinID)
    for uid, boundID in pairs(bindings) do
        if boundID == pinID then
            bindings[uid] = nil
            if selected == uid then selected = nil end
        end
    end
end

---@param native TomTom
---@param pinID UUID
---@param link TomTomPinLink
local function SyncLink(native, pinID, link)
    if not IsCurrentLink(link) then return end
    local group = FindLinkedGroup(pinID)
    -- Resource draining, saved intake and temporarily unavailable external groups
    -- retain ownership. Their completion publishes another GROUP_UPDATED callback.
    if group and group.pinsUpdating then return end
    if not group and (Groups:IsPinIDInUse(pinID) or Groups:GetDeferredGroupSource(link.groupID)) then return end
    local uid = FindNativeWaypoint(link)
    if uid and IsKalielWaypoint(uid) then
        -- Older versions linked native-source mirrors. Keep both pins, but stop
        -- propagating their removals now that Kaliel retains source ownership.
        ForgetLink(pinID)
        return
    end
    if not group then
        if uid then native:RemoveWaypoint(uid) end
        ForgetLink(pinID)
        return
    end
    if link.groupID ~= group:GetGroupID() then
        link.groupID = group:GetGroupID()
        PersistLink(pinID)
    end
    local archived = group:GetArchivedPinByID(pinID)
    if archived and archived.state == "cleared" then
        if not link.cleared then
            link.cleared = true
            PersistLink(pinID)
        end
        if uid then native:RemoveWaypoint(uid) end
    elseif link.cleared then
        -- Explicit restoration recreates the native target without changing selection.
        -- Use its original identity so renames/edits do not attach to an unrelated target.
        uid = uid or native:AddWaypoint(link.mapID, link.x, link.y,
            { title = link.title, persistent = link.persistent, crazy = false, silent = true })
        if uid then
            clearedWaypoints[uid] = nil
            BindWaypoint(uid, group, pinID)
            link.cleared = false
            PersistLink(pinID)
        end
    elseif uid and not clearedWaypoints[uid] then
        BindWaypoint(uid, group, pinID)
    else
        -- Defer this decision until TomTom has finished rebuilding a profile.
        -- Native removal clears through the group owner, retaining restorable archives.
        local pin = group:GetPinByID(pinID)
        if pin and pin:IsTracked() then pin:Untrack() end
        if group:ClearPin(pinID, nil, false) then
            -- Retain identity until the next pass: a clear callback may restore/move it.
            link.cleared = true
            PersistLink(pinID)
            if uid then native:RemoveWaypoint(uid) end
        end
    end
end

local function SyncLinks()
    if pendingSync then
        pendingSync:Cancel()
        pendingSync = nil
    end
    local native = TomTom
    if not integrationEnabled or not loggedIn or synchronizing or not native or not C_AddOns.IsAddOnLoaded("TomTom") or
        not native.waypoints or not GetNativeProfile() then return end
    synchronizing = true
    -- Always release the guard if a native or domain callback fails.
    local success, message = pcall(function()
        local group = Groups:GetTomTomGroup()
        if needsRebind and (not group or not group.pinsUpdating) then
            -- Upgrade existing saved mirrors after both addons finish loading.
            for _, waypoints in pairs(native.waypoints) do
                for _, uid in pairs(waypoints) do AddTomTomWaypoint(uid, true) end
            end
            needsRebind = false
        end
        for pinID, link in pairs(links) do SyncLink(native, pinID, link) end
    end)
    synchronizing = false
    if not success then geterrorhandler()(message) end
end

local function ScheduleSync()
    if not integrationEnabled or not loggedIn or pendingSync or not C_AddOns.IsAddOnLoaded("TomTom") or
        (not next(links) and not needsRebind) then return end
    pendingSync = C_Timer.NewTimer(0, SyncLinks)
end

-- These notifications cover single/bulk deletion, restoration and completed moves.
-- Inspect current membership after the command, never a pooled object's release.
for _, event in ipairs({ "PIN_CLEARED", "PIN_REMOVED", "GROUP_UPDATED", "GROUP_DELETED" }) do
    MapPinEnhanced:RegisterCallback(event, ScheduleSync)
end

---@type table<table, table<string, function>>
local hookedMethods = {}
local observedProfile

local function HookTomTom()
    local native = TomTom
    if not native or not C_AddOns.IsAddOnLoaded("TomTom") or
        not MapPinEnhanced:IsReadableTable(native) then
        return
    end
    local methods = hookedMethods[native] or {}
    hookedMethods[native] = methods
    local function Hook(name, callback)
        local method = native[name]
        if MapPinEnhanced:IsSecretValue(method) or type(method) ~= "function" or methods[name] == method then return end
        hooksecurefunc(native, name, function(...)
            if not integrationEnabled or TomTom ~= native or synchronizing then return end
            local profile = GetNativeProfile()
            if observedProfile ~= profile then
                bindings = {}
                selected, nativeSelected, observedProfile = nil, nil, profile
                needsRebind = true
            end
            callback(...)
        end)
        methods[name] = native[name]
    end
    -- Rebind saved pins on restoration without importing or selecting background waypoints.
    Hook("SetWaypoint", function(_, uid)
        if MapPinEnhanced:IsReadableTable(uid) then clearedWaypoints[uid] = nil end
        AddTomTomWaypoint(uid, true)
        ScheduleSync()
    end)
    local function SelectNativeWaypoint(uid)
        -- TomTom rejects selection while its sticky corpse arrow is active.
        local profile = native.db and native.db.profile
        if nativeSelected and nativeSelected.corpse and profile and profile.arrow and profile.arrow.stickycorpse and
            type(native.IsCrazyArrowEmpty) == "function" and not native:IsCrazyArrowEmpty() then
            return
        end
        nativeSelected = MapPinEnhanced:IsReadableTable(uid) and uid or nil
        if nativeSelected and MapPinEnhanced:IsSecretValue(nativeSelected.corpse) then
            nativeSelected = nil
            return
        end
        if nativeSelected and IsKalielWaypoint(nativeSelected) then
            -- Native source changes untrack the previous pin through Pins' event
            -- handler; do not issue tracking commands inside Kaliel's arrow call.
            selected = nil
            return
        end
        if not nativeSelected or nativeSelected.corpse then
            UntrackWaypoint(selected)
            selected = nil
            return
        end
        SelectWaypoint(uid)
        ScheduleSync()
    end
    Hook("SetCrazyArrow", function(_, uid) SelectNativeWaypoint(uid) end)
    Hook("AddWaypoint", function(_, mapID, x, y, info)
        -- TomTom returns an existing handle before SetCrazyArrow on repeated adds.
        -- Provided options already contain TomTom's defaults; omitted options use its profile.
        if info == nil then
            info = { crazy = native.profile and native.profile.arrow and native.profile.arrow.autoqueue }
        end
        if not MapPinEnhanced:IsReadableTable(info) or MapPinEnhanced:IsSecretValue(info.crazy) or
            info.crazy ~= true or not MapPinEnhanced:IsReadablePositiveInteger(mapID) or
            not MapPinEnhanced:IsCoordinate(x) or not MapPinEnhanced:IsCoordinate(y) or
            MapPinEnhanced:IsSecretValue(info.title) or
            (info.title ~= nil and type(info.title) ~= "string") then
            return
        end
        local waypoints = native.waypoints and native.waypoints[mapID]
        if not waypoints or not MapPinEnhanced:IsReadableTable(waypoints) or type(native.GetKeyArgs) ~= "function" then return end
        local uid = waypoints[native:GetKeyArgs(mapID, x, y, info.title)]
        if uid then SelectNativeWaypoint(uid) end
    end)
    Hook("RemoveWaypoint", ScheduleSync)
    -- ClearWaypoint also releases display objects during a profile rebuild.
    -- A later SetWaypoint in the same operation cancels this pending removal.
    Hook("ClearWaypoint", function(_, uid)
        if MapPinEnhanced:IsReadableTable(uid) and bindings[uid] then clearedWaypoints[uid] = true end
        ScheduleSync()
    end)
    Hook("ReloadWaypoints", function()
        needsRebind = true
        ScheduleSync()
    end)
    Hook("ClearCrazyArrowPoint", function()
        -- Clearing may select the closest waypoint inside TomTom. Keep that nested selection.
        if type(native.IsCrazyArrowEmpty) == "function" and native:IsCrazyArrowEmpty() then
            UntrackWaypoint(selected)
            selected, nativeSelected = nil, nil
        end
    end)
end

local function ApplyIntegrationOption(enabled)
    integrationEnabled = enabled == true
    if integrationEnabled then
        ScheduleSync()
    else
        if pendingSync then
            pendingSync:Cancel()
            pendingSync = nil
        end
        UntrackWaypoint(selected)
        selected, nativeSelected = nil, nil
        bindings = {}
        clearedWaypoints = setmetatable({}, { __mode = "k" })
        needsRebind = true
    end
end

-- Only actual option changes persist. Refresh the untouched default silently so
-- either addon load order (including late TomTom loading) keeps the choice unset.
local function CheckForTomTom()
    MapPinEnhanced.isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
    Options.DEFAULTS[OPTION_KEY] = MapPinEnhanced.isTomTomLoaded and true or false
    if MapPinEnhanced:GetVar("options", OPTION_KEY) == nil then
        local frame = Options.options[OPTION_KEY]
        local enabled = Options:GetDefaultValue(OPTION_KEY)
        frame:SetValue(enabled)
        frame.lastValue = enabled
        ApplyIntegrationOption(enabled)
    end
    if MapPinEnhanced.isTomTomLoaded then
        HookTomTom()
        ScheduleSync()
    end
end

-- Session-long subscription; Options owns persistence of explicit choices.
Options:SubscribeToOptionChanges(OPTION_KEY, ApplyIntegrationOption)

MapPinEnhanced:RegisterEvent("ADDON_LOADED", function(addon)
    if addon == "TomTom" then CheckForTomTom() end
end)

-- Install before TomTom restores saved waypoints at PLAYER_LOGIN, in either load order.
MapPinEnhanced:OnLoad(CheckForTomTom)
MapPinEnhanced:RegisterEvent("PLAYER_LOGIN", function()
    loggedIn = true
    CheckForTomTom()
end)
MapPinEnhanced:RegisterEvent("PLAYER_LOGOUT", function()
    SyncLinks()
    loggedIn = false
    if pendingSync then
        pendingSync:Cancel()
        pendingSync = nil
    end
end)
