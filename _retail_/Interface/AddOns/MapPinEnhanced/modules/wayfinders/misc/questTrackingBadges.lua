---@class MapPinEnhanced
local MapPinEnhanced = select(2, ...)
local Navigation = MapPinEnhanced:GetModule("Navigation")

---@class MapPinEnhancedQuestTrackingBadgeTemplate : Frame

---@class QuestTrackingBadgeHost : Frame
---@field questID number?
---@field poiInfo AreaPOIInfo?
---@field id number?
---@field GetQuestID fun(self: QuestTrackingBadgeHost): number?
---@field HeaderText FontString?
---@field poiButton Button?
---@field parentModule QuestTrackingBadgeModule?

---@class QuestTrackingBadgeModule : Frame
---@field EnumerateActiveBlocks fun(self: QuestTrackingBadgeModule, callback: fun(block: QuestTrackingBadgeHost))
---@field EndLayout function

---@class QuestTrackingBadgeBinding
---@field kind "map"|"list"|"tracker"
---@field module QuestTrackingBadgeModule?
---@field badge MapPinEnhancedQuestTrackingBadgeTemplate?

---@type table<QuestTrackingBadgeHost, QuestTrackingBadgeBinding>
local bindings = setmetatable({}, { __mode = "k" })
---@type table<Frame, boolean>
local hooked = setmetatable({}, { __mode = "k" })
local refreshQueued = false
local questListHooked = false
local trackerNames = {
    "QuestObjectiveTracker", "CampaignQuestObjectiveTracker",
    "WorldQuestObjectiveTracker", "BonusObjectiveTracker",
    -- Kaliel's modules retain Blizzard's block identity and layout interface.
    "KT_QuestObjectiveTracker", "KT_CampaignQuestObjectiveTracker",
    "KT_WorldQuestObjectiveTracker", "KT_BonusObjectiveTracker",
    "KT_EventObjectiveTracker",
}

---@param pool FramePool<MapPinEnhancedQuestTrackingBadgeTemplate>
---@param badge MapPinEnhancedQuestTrackingBadgeTemplate
local function ResetBadge(pool, badge)
    badge:Hide()
    badge:ClearAllPoints()
    badge:SetParent(UIParent)
end

local badgePool = CreateFramePool("Frame", UIParent, "MapPinEnhancedQuestTrackingBadgeTemplate", ResetBadge)

---@param host QuestTrackingBadgeHost
---@return boolean
local function CanChangeHost(host)
    return not InCombatLockdown() or not host:IsProtected()
end

---@param host QuestTrackingBadgeHost
local function ReleaseBadge(host)
    local binding = bindings[host]
    if binding and binding.badge and CanChangeHost(host) then
        badgePool:Release(binding.badge)
        binding.badge = nil
    end
end

local Refresh ---@type fun()
local function QueueRefresh()
    if refreshQueued then return end
    refreshQueued = true
    -- Map providers assign quest IDs after AcquirePin/RegisterPin returns.
    C_Timer.After(0, function()
        refreshQueued = false
        Refresh()
    end)
end

---@param host QuestTrackingBadgeHost
---@param kind "map"|"list"|"tracker"
---@param module QuestTrackingBadgeModule?
local function BindHost(host, kind, module)
    local binding = bindings[host]
    if not binding then
        binding = { kind = kind }
        bindings[host] = binding
        host:HookScript("OnHide", ReleaseBadge)
        host:HookScript("OnShow", QueueRefresh)
    end
    binding.kind = kind
    binding.module = module
end

local function DiscoverHosts()
    if WorldMapFrame and WorldMapFrame.ExecuteOnAllPins then
        if not hooked[WorldMapFrame] then
            hooked[WorldMapFrame] = true
            hooksecurefunc(WorldMapFrame, "RegisterPin", QueueRefresh)
            WorldMapFrame:HookScript("OnShow", QueueRefresh)
        end
        WorldMapFrame:ExecuteOnAllPins(function(pin)
            if pin.GetQuestID or pin.questID then BindHost(pin, "map") end
        end)
    end
    if not questListHooked and type(QuestLogQuests_Update) == "function" then
        questListHooked = true
        hooksecurefunc("QuestLogQuests_Update", QueueRefresh)
    end
    if QuestScrollFrame and QuestScrollFrame.titleFramePool then
        local titleFramePool = QuestScrollFrame.titleFramePool ---@type FramePool<QuestTrackingBadgeHost>
        ---@param row QuestTrackingBadgeHost
        for row in titleFramePool:EnumerateActive() do
            BindHost(row, "list")
        end
    end
    for _, name in ipairs(trackerNames) do
        local module = _G[name] ---@type QuestTrackingBadgeModule?
        if module and module.EnumerateActiveBlocks and module.EndLayout then
            if not hooked[module] then
                hooked[module] = true
                hooksecurefunc(module, "EndLayout", QueueRefresh)
                module:HookScript("OnShow", QueueRefresh)
            end
            module:EnumerateActiveBlocks(function(block) BindHost(block, "tracker", module) end)
        end
    end
end

---@param host QuestTrackingBadgeHost
---@param binding QuestTrackingBadgeBinding
---@param owner string?
---@return string?
local function GetDestinationID(host, binding, owner)
    ---@type number?
    local questID
    if binding.kind == "tracker" then
        -- Blocks can be reused across modules; scenario blocks use negative IDs.
        if host.parentModule ~= binding.module then return nil end
        local isEvent = binding.module and binding.module:GetName() == "KT_EventObjectiveTracker"
        if owner == "mapPin" then
            local info = host.poiInfo
            -- Event block IDs survive Kaliel releasing its hidden POI button/info.
            local poiID = isEvent and host.id or info and MapPinEnhanced:IsReadableTable(info) and info.areaPoiID
            if MapPinEnhanced:IsReadablePositiveInteger(poiID) then
                return string.format("mapPin:%d:%d", Enum.SuperTrackingMapPinType.AreaPOI, poiID)
            end
            return nil
        end
        if isEvent then return nil end
        questID = host.id
    else
        questID = host.GetQuestID and host:GetQuestID() or host.questID
    end
    if owner == "quest" and MapPinEnhanced:IsReadablePositiveInteger(questID) then
        return string.format("quest:%d", questID)
    end
end

---@param host QuestTrackingBadgeHost
---@param binding QuestTrackingBadgeBinding
local function ShowBadge(host, binding)
    local badge = binding.badge
    if not badge then
        badge = badgePool:Acquire()
        binding.badge = badge
        badge:SetParent(host)
    end
    badge:SetFrameStrata(host:GetFrameStrata())
    badge:SetFrameLevel(host:GetFrameLevel() + 10)
    badge:ClearAllPoints()
    -- Anchor to the current native icon when available; tracker headings still
    -- identify their quest when Blizzard's optional POI buttons are disabled.
    if binding.kind == "tracker" and host.poiButton and host.poiButton:IsShown() then
        badge:SetPoint("CENTER", host.poiButton, "BOTTOMRIGHT", -2, 2)
    elseif binding.kind == "tracker" and host.HeaderText then
        badge:SetPoint("RIGHT", host.HeaderText, "LEFT", -2, 0)
    elseif binding.kind == "list" then
        badge:SetPoint("CENTER", host, "TOPLEFT", 22, -18)
    else
        badge:SetPoint("CENTER", host, "BOTTOMRIGHT", -2, 2)
    end
    badge:Show()
end

Refresh = function()
    DiscoverHosts()
    local owner, destinationID = Navigation:GetActiveDestinationState()
    for host, binding in pairs(bindings) do
        if CanChangeHost(host) then
            if destinationID and GetDestinationID(host, binding, owner) == destinationID and host:IsVisible() then
                ShowBadge(host, binding)
            else
                ReleaseBadge(host)
            end
        end
    end
end

-- Present Navigation's original quest/event through temporary Steps without selecting it.
MapPinEnhanced:RegisterCallback("NAVIGATION_DESTINATION_CHANGED", QueueRefresh)
MapPinEnhanced:RegisterEvent("SUPER_TRACKING_CHANGED", QueueRefresh)
MapPinEnhanced:RegisterEvent("ADDON_LOADED", QueueRefresh)
MapPinEnhanced:RegisterEvent("PLAYER_ENTERING_WORLD", QueueRefresh)
MapPinEnhanced:RegisterEvent("PLAYER_REGEN_ENABLED", QueueRefresh)
