local _, ns = ...

-- Native 12.1 aura overlays. AuraContainer owns aura matching, secret visibility,
-- and duration; CMC only anchors and styles the resulting AuraSlot.
local AuraTracking = {}
ns.AuraTracking = AuraTracking

local AURA_CONTAINER_ADDON = "Blizzard_AuraContainer"
local AURA_CONTAINER_TEMPLATE = "CustomAuraContainerTemplate"
local AURA_SLOT_KEY = "cmcTrackedAura"
local PLAYER_AURA_FILTER = "HELPFUL"
local REQUIRED_CONTAINER_METHODS = {
    "AddAuraSlot",
    "SetAuraSlotCandidateFilters",
    "SetEnabled",
    "SetUnit",
    "UpdateAllAuras",
}

local states = setmetatable({}, { __mode = "k" })
local pendingRequests = setmetatable({}, { __mode = "k" })
local supportChecked = false
local supported = false
local flushFrame = CreateFrame("Frame")

local function SchedulePostCombatFlush()
    flushFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

local function QueueRequest(host, auraSpellID, options)
    if not host then
        return
    end
    pendingRequests[host] = {
        auraSpellID = auraSpellID or false,
        options = options,
    }
    SchedulePostCombatFlush()
end

local function HasRequiredContainerMethods(container)
    if not container then
        return false
    end
    for _, methodName in ipairs(REQUIRED_CONTAINER_METHODS) do
        if type(container[methodName]) ~= "function" then
            return false
        end
    end
    return true
end

local function SyncBaseIconCover(state)
    local source = state and state.host and state.host.Icon
    local cover = state and state.iconCover
    if not source or not cover then
        return
    end

    cover:SetTexture(source:GetTexture())
    cover:SetTexCoord(source:GetTexCoord())
    cover:SetVertexColor(source:GetVertexColor())
    if source.GetDesaturation and cover.SetDesaturation then
        cover:SetDesaturation(source:GetDesaturation())
    end

    local mask
    if ns.MasqueModule and ns.MasqueModule.GetIconMask then
        mask = ns.MasqueModule:GetIconMask(state.host)
    elseif source.GetMaskTexture then
        mask = source:GetMaskTexture(1)
    end
    if state.iconCoverMask ~= mask then
        if state.iconCoverMask then
            cover:RemoveMaskTexture(state.iconCoverMask)
        end
        if mask then
            cover:AddMaskTexture(mask)
        end
        state.iconCoverMask = mask
    end
end

local function ApplyApplicationCountStyle(state, stackColor)
    local count = state and state.applicationCount
    local host = state and state.host
    local profile = ns.db and ns.db.profile
    if not count or not host or not profile then
        return
    end

    local fontPath
    local fontSize
    local fontFlags
    local point = "BOTTOMRIGHT"
    local offsetX = -2
    local offsetY = 2

    local parent = host:GetParent()
    local viewerName = parent and parent:GetName()
    local viewerScope = viewerName == "EssentialCooldownViewer" and "Essential"
        or viewerName == "UtilityCooldownViewer" and "Utility"
        or viewerName == "BuffIconCooldownViewer" and "BuffIcons"

    if viewerScope then
        local nativeCount = host.Applications and host.Applications.Applications
            or host.ChargeCount and host.ChargeCount.Current
        if nativeCount and nativeCount.GetFont then
            fontPath, fontSize, fontFlags = nativeCount:GetFont()
        end

        if profile["cooldownManager_stackAnchor" .. viewerScope .. "_enabled"] then
            local configuredSize = profile["cooldownManager_stackFontSize" .. viewerScope]
            if configuredSize ~= nil and configuredSize ~= "NIL" then
                fontSize = configuredSize
            end
            point = profile["cooldownManager_stackAnchor" .. viewerScope .. "_point"] or point
            offsetX = profile["cooldownManager_stackAnchor" .. viewerScope .. "_offsetX"] or offsetX
            offsetY = profile["cooldownManager_stackAnchor" .. viewerScope .. "_offsetY"] or offsetY
            fontPath = ns.API:GetFontPath(profile.cooldownManager_stackFontName) or fontPath
            fontFlags = ns.API:GetFontFlags(profile.cooldownManager_stackFontFlags)
        end
    else
        local trackerConfig = host.trackerConfigKey
            and profile.editMode
            and profile.editMode[host.trackerConfigKey]
        if trackerConfig then
            fontPath = ns.API:GetFontPath(trackerConfig.stackFontName) or fontPath
            fontSize = trackerConfig.stackFontSize or 14
            fontFlags = ns.API:GetFontFlags(trackerConfig.stackFontFlags or {})
            point = trackerConfig.stackAnchor or point
            offsetX = trackerConfig.stackOffsetX or -1
            offsetY = trackerConfig.stackOffsetY or 1
        elseif host.count then
            -- Essential custom entries reuse the already-applied Essential count style.
            fontPath, fontSize, fontFlags = host.count:GetFont()
            local countPoint, _, _, countOffsetX, countOffsetY = host.count:GetPoint()
            point = countPoint or point
            offsetX = countOffsetX or offsetX
            offsetY = countOffsetY or offsetY
        end
    end

    fontPath = fontPath or ns.CONSTANTS.DEFAULT_NUMBER_FONT[1]
    fontSize = tonumber(fontSize) or 14
    count:SetFont(fontPath, fontSize, fontFlags or "")
    count:ClearAllPoints()
    count:SetPoint(point, state.countOverlay, point, offsetX, offsetY)
    if stackColor then
        if not state.applicationCountOriginalColor then
            state.applicationCountOriginalColor = { count:GetTextColor() }
        end
        count:SetTextColor(stackColor[1], stackColor[2], stackColor[3], 1)
    elseif state.applicationCountOriginalColor then
        count:SetTextColor(unpack(state.applicationCountOriginalColor))
        state.applicationCountOriginalColor = nil
    end
end

local function UpdateContainerVisibility(state)
    if not state or not state.container then
        return
    end
    if InCombatLockdown() then
        SchedulePostCombatFlush()
        return
    end
    local shouldShow = state.enabled and state.host and state.host:IsShown()
    if shouldShow then
        if not state.containerVisible then
            state.container:SetEnabled(true)
            state.container:Show()
            state.container:SetAlpha(1)
            state.container:UpdateAllAuras()
            state.containerVisible = true
        end
    elseif state.containerVisible ~= false then
        state.container:SetEnabled(false)
        state.container:SetAlpha(0)
        state.container:Hide()
        state.containerVisible = false
    end
end

local function SetContainerActive(state, active)
    if not state then
        return
    end
    state.enabled = active == true
    UpdateContainerVisibility(state)
end

function AuraTracking:IsSupported()
    if supportChecked then
        return supported
    end
    -- Loading Blizzard_AuraContainer creates secure/private template state.
    -- Never initiate that load from tainted addon execution during lockdown.
    if InCombatLockdown() then
        return false
    end
    supportChecked = true

    local interfaceVersion = select(4, GetBuildInfo())
    if (tonumber(interfaceVersion) or 0) < 120100 then
        return false
    end

    if C_AddOns and C_AddOns.IsAddOnLoaded and not C_AddOns.IsAddOnLoaded(AURA_CONTAINER_ADDON) then
        if not C_AddOns.LoadAddOn or not C_AddOns.LoadAddOn(AURA_CONTAINER_ADDON) then
            supportChecked = false
            return false
        end
    end

    supported = type(CreateFrame) == "function"
    return supported
end

local function ApplyStyle(state, options)
    local cooldown = state and state.cooldown
    if not cooldown then
        return
    end
    if InCombatLockdown() then
        SchedulePostCombatFlush()
        return
    end

    SyncBaseIconCover(state)
    ApplyApplicationCountStyle(state, options.stackColor)
    cooldown:SetDrawEdge(options.drawEdge == true)
    cooldown:SetDrawBling(false)
    cooldown:SetDrawSwipe(true)
    cooldown:SetReverse(options.reverse == true)
    cooldown:SetHideCountdownNumbers(options.hideCountdownNumbers == true)
    if cooldown.SetUseAuraDisplayTime then
        cooldown:SetUseAuraDisplayTime(true)
    end
    if options.swipeTexture then
        cooldown:SetSwipeTexture(options.swipeTexture)
    end
    if options.r then
        cooldown:SetSwipeColor(options.r, options.g or 1, options.b or 1, options.a or 1)
    end
    if ns.CooldownStyle and state.slot then
        if options.glowWhenActive then
            ns.CooldownStyle:ShowFrameGlow(state.slot)
        else
            ns.CooldownStyle:HideFrameGlow(state.slot)
        end
    end
    local anchor = options.anchor or state.host.Cooldown or state.host
    state.slot:ClearAllPoints()
    state.slot:SetAllPoints(anchor)

    local host = state.host
    local baseCooldownLevel = host.Cooldown and host.Cooldown:GetFrameLevel() or host:GetFrameLevel()
    local coverLevel = baseCooldownLevel + 1
    local auraCooldownLevel = coverLevel + 1
    local textLevel = auraCooldownLevel + 1
    state.container:SetFrameStrata(host:GetFrameStrata())
    state.container:SetFrameLevel(math.max(0, baseCooldownLevel - 1))
    state.slot:SetFrameLevel(coverLevel)
    state.cooldown:SetFrameLevel(auraCooldownLevel)
    if state.countOverlay then
        state.countOverlay:SetFrameLevel(textLevel)
    end

    -- Keep charge/stack counters above the aura swipe while the base cooldown
    -- frame (including its own countdown text) remains below the icon cover.
    if host.ChargeCount and host.ChargeCount.SetFrameLevel then
        host.ChargeCount:SetFrameLevel(textLevel)
    end
    local customCountParent = host.count and host.count.GetParent and host.count:GetParent()
    if customCountParent and customCountParent ~= host and customCountParent.SetFrameLevel then
        customCountParent:SetFrameLevel(textLevel)
    end
end

local function CreateState(host, auraSpellID, options)
    -- Defense in depth: keep this constructor safe even if a future caller
    -- bypasses Attach's combat queue.
    if InCombatLockdown() then
        QueueRequest(host, auraSpellID, options)
        return nil
    end

    local baseIcon = host.Icon
    if not baseIcon or type(baseIcon.GetTexture) ~= "function" then
        return nil
    end
    local state = {
        host = host,
        auraSpellID = auraSpellID,
    }
    local container = CreateFrame("AuraContainer", nil, UIParent, AURA_CONTAINER_TEMPLATE)
    if not HasRequiredContainerMethods(container) then
        supported = false
        return nil
    end
    state.container = container
    container:SetAllPoints(UIParent)
    container:SetUnit("player")

    local slot = container:AddAuraSlot(AURA_SLOT_KEY, PLAYER_AURA_FILTER, {
        candidateFilters = { includeSpellIDs = { [auraSpellID] = true } },
        initializeFrame = function(button)
            button:EnableMouse(false)
            -- A child region inherits the AuraButton's secret-controlled
            -- visibility without observing it in Lua. It reproduces the host
            -- icon above the host cooldown, hiding that swipe while the child
            -- aura cooldown remains visible above the cover.
            local iconCover = button:CreateTexture(nil, "ARTWORK")
            iconCover:SetAllPoints(button)
            state.iconCover = iconCover

            local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
            cooldown:SetAllPoints(button)
            button:SetDurationCooldown(cooldown)
            state.cooldown = cooldown

            -- Blizzard writes the possibly-secret application count directly
            -- to this FontString. CMC only styles the region outside combat.
            if type(button.SetApplicationCount) == "function" then
                local countOverlay = CreateFrame("Frame", nil, button)
                countOverlay:SetAllPoints(button)
                local applicationCount = countOverlay:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
                applicationCount:SetPoint("BOTTOMRIGHT", countOverlay, "BOTTOMRIGHT", -2, 2)
                button:SetApplicationCount(applicationCount)
                state.countOverlay = countOverlay
                state.applicationCount = applicationCount
            end
        end,
    })
    if not slot or not state.cooldown then
        container:SetEnabled(false)
        container:Hide()
        return nil
    end

    state.slot = slot
    ns.API.Affected(slot).glowStyleSource = host
    states[host] = state
    host:HookScript("OnShow", function()
        local current = states[host]
        UpdateContainerVisibility(current)
    end)
    host:HookScript("OnHide", function()
        local current = states[host]
        UpdateContainerVisibility(current)
    end)

    ApplyStyle(state, options)
    SetContainerActive(state, true)
    return state
end

function AuraTracking:Attach(host, auraSpellID, options)
    auraSpellID = tonumber(auraSpellID)
    if not host or not auraSpellID or auraSpellID <= 0 then
        self:Detach(host)
        return false
    end

    options = options or {}
    -- CustomAuraContainerTemplate uses a forbidden object table and secure
    -- delegates. Creating it or calling its inbound methods during combat can
    -- leave a partially initialized container and taint later template loads.
    if InCombatLockdown() then
        QueueRequest(host, auraSpellID, options)
        return true
    end
    if not self:IsSupported() then
        self:Detach(host)
        return false
    end

    pendingRequests[host] = nil
    local state = states[host]
    if not state then
        state = CreateState(host, auraSpellID, options)
        return state ~= nil
    end

    if state.auraSpellID ~= auraSpellID then
        state.auraSpellID = auraSpellID
        state.container:SetAuraSlotCandidateFilters(AURA_SLOT_KEY, {
            includeSpellIDs = { [auraSpellID] = true },
        })
    end
    ApplyStyle(state, options)
    SetContainerActive(state, true)
    return true
end

function AuraTracking:Detach(host)
    if not host then
        return
    end
    if InCombatLockdown() then
        QueueRequest(host, false, nil)
        return
    end

    pendingRequests[host] = nil
    local state = host and states[host]
    if state then
        SetContainerActive(state, false)
    end
end

flushFrame:SetScript("OnEvent", function(self, event)
    if event ~= "PLAYER_REGEN_ENABLED" or InCombatLockdown() then
        return
    end
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")

    -- Last request wins for each pooled host frame. Clear before applying so a
    -- request that somehow requeues itself is preserved for the next flush.
    local requests = pendingRequests
    pendingRequests = setmetatable({}, { __mode = "k" })
    for host, request in pairs(requests) do
        if request.auraSpellID then
            AuraTracking:Attach(host, request.auraSpellID, request.options)
        else
            AuraTracking:Detach(host)
        end
    end

    -- Host visibility may have changed while its container was intentionally
    -- untouched in combat. Reconcile every live container once lockdown ends.
    for _, state in pairs(states) do
        UpdateContainerVisibility(state)
    end
end)
