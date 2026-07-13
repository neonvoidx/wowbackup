local _, ns = ...

-- Reads the game's tracked-buff set (BuffIconCooldownViewer / the TrackedBuff
-- cooldown category) and owns the per-profile assignment of each buff to a custom
-- container. Unassigned buffs stay in the default Blizzard buff row; assigned ones
-- are re-anchored into CMCBuffContainer{N} by the layout engine (cooldownManager.lua).
local BuffData = {}
ns.BuffData = BuffData

local MAX_CONTAINERS = ns.CONSTANTS and ns.CONSTANTS.MAX_TRACKERS or 10

-- The cooldownID assigned to a buff icon frame is a per-build content ID and can
-- shift between patches/hotfixes; the spellID behind it is stable. We persist a
-- string stable key ("s:"..spellID when known, else "c:"..cooldownID) so container
-- membership survives cooldownID reshuffles wherever a spellID exists.
local function BuildStableKey(cooldownID, spellID)
    if spellID then
        return "s:" .. spellID
    end
    if cooldownID then
        return "c:" .. cooldownID
    end
    return nil
end

-- cooldownID -> resolved info, rebuilt each scan (frames reuse cooldownIDs across
-- spec swaps, so we never trust a stale mapping across a scan boundary).
local infoByCooldownID = {}
local scanCache = nil

---@return table config The profile.buffContainers table, created on first access.
function BuffData.GetDB()
    ns.db.profile.buffContainers = ns.db.profile.buffContainers or {}
    local db = ns.db.profile.buffContainers
    db.assignments = db.assignments or {}
    return db
end

function BuffData.IsEnabled()
    return BuffData.GetDB().enabled == true
end

function BuffData.SetEnabled(value)
    BuffData.GetDB().enabled = value and true or false
end

function BuffData.GetContainerCount()
    local count = BuffData.GetDB().count or 1
    if count < 1 then
        return 1
    elseif count > MAX_CONTAINERS then
        return MAX_CONTAINERS
    end
    return count
end

function BuffData.GetMaxContainers()
    return MAX_CONTAINERS
end

-- Resolves (and caches for this scan) the spellID / name / icon behind a cooldownID.
-- selfAura buffs expose their real buff via spellID; some categories only populate
-- overrideSpellID, so fall back to it. Returns nil for cooldownIDs the client can't
-- describe yet.
local function ResolveCooldownInfo(cooldownID)
    if not cooldownID then
        return nil
    end
    local cached = infoByCooldownID[cooldownID]
    if cached ~= nil then
        return cached
    end
    local info = C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
    if not info then
        infoByCooldownID[cooldownID] = false
        return nil
    end
    local spellID = info.spellID or info.overrideSpellID
    local resolved = {
        cooldownID = cooldownID,
        spellID = spellID,
        stableKey = BuildStableKey(cooldownID, spellID),
        name = spellID and C_Spell.GetSpellName(spellID) or nil,
        iconID = spellID and C_Spell.GetSpellTexture(spellID) or nil,
    }
    infoByCooldownID[cooldownID] = resolved
    return resolved
end

---Ordered list of the tracked buffs actually shown in the Blizzard buff viewer for
---the current spec. Built from the live BuffIconCooldownViewer item frames rather
---than the raw category set, so buffs the player moved to "not displayed" (which
---have no frame in the viewer) are excluded even though they're learned — matching
---exactly what the layout engine partitions.
---@param force? boolean Rebuild instead of returning the cached scan.
---@return table entries Array of { cooldownID, spellID, stableKey, name, iconID }.
function BuffData.ScanTrackedBuffs(force)
    if scanCache and not force then
        return scanCache
    end
    wipe(infoByCooldownID)
    local entries = {}
    local viewer = _G["BuffIconCooldownViewer"]
    if viewer and viewer.GetItemFrames then
        local frames = viewer:GetItemFrames()
        local ordered = {}
        for _, frame in ipairs(frames) do
            local cooldownID = frame.cooldownID or (frame.GetCooldownID and frame:GetCooldownID())
            if cooldownID and frame.layoutIndex ~= nil then
                ordered[#ordered + 1] = { cooldownID = cooldownID, layoutIndex = frame.layoutIndex }
            end
        end
        table.sort(ordered, function(a, b)
            return a.layoutIndex < b.layoutIndex
        end)
        local seen = {}
        for _, item in ipairs(ordered) do
            if not seen[item.cooldownID] then
                seen[item.cooldownID] = true
                local info = ResolveCooldownInfo(item.cooldownID)
                if info and info.stableKey then
                    entries[#entries + 1] = info
                end
            end
        end
    end
    scanCache = entries
    return entries
end

function BuffData.InvalidateScan()
    scanCache = nil
    wipe(infoByCooldownID)
end

-- Stable key for a live buff icon frame (or raw cooldownID). Resolves through the
-- current scan so we reuse the cached spellID lookup.
function BuffData.GetStableKeyForCooldownID(cooldownID)
    local info = ResolveCooldownInfo(cooldownID)
    return info and info.stableKey or BuildStableKey(cooldownID, nil)
end

---Container index a buff belongs to, or nil when it stays in the default row.
function BuffData.GetContainerForCooldownID(cooldownID)
    if not cooldownID then
        return nil
    end
    local key = BuffData.GetStableKeyForCooldownID(cooldownID)
    if not key then
        return nil
    end
    local index = BuffData.GetDB().assignments[key]
    if index and index >= 1 and index <= BuffData.GetContainerCount() then
        return index
    end
    return nil
end

function BuffData.GetContainerForStableKey(key)
    return key and BuffData.GetDB().assignments[key] or nil
end

---Assign a buff (by stable key) to a container, or to the default row (index nil).
function BuffData.AssignKey(key, containerIndex)
    if not key then
        return
    end
    BuffData.GetDB().assignments[key] = containerIndex
end

function BuffData.UnassignKey(key)
    BuffData.AssignKey(key, nil)
end

---Buffs currently assigned to a container, in game (category-set) order.
function BuffData.GetBuffsForContainer(containerIndex)
    local result = {}
    for _, entry in ipairs(BuffData.ScanTrackedBuffs()) do
        if BuffData.GetDB().assignments[entry.stableKey] == containerIndex then
            result[#result + 1] = entry
        end
    end
    return result
end

---Buffs not assigned to any (active) container: they render in the default row.
function BuffData.GetUnassignedBuffs()
    local count = BuffData.GetContainerCount()
    local result = {}
    for _, entry in ipairs(BuffData.ScanTrackedBuffs()) do
        local index = BuffData.GetDB().assignments[entry.stableKey]
        if not index or index < 1 or index > count then
            result[#result + 1] = entry
        end
    end
    return result
end

-- Emptiness is judged from the persistent assignment table, not the current-spec
-- scan: a container "used" only by another spec's buff must keep its slot so the
-- count (and every higher container's index) stays stable across spec swaps.
function BuffData.IsContainerEmpty(containerIndex)
    for _, index in pairs(BuffData.GetDB().assignments) do
        if index == containerIndex then
            return false
        end
    end
    return true
end

-- Keeps exactly one empty trailing container (mirrors the custom-tracker
-- "always one spare" rule). Grows the count the moment the last container gains a
-- buff and trims surplus trailing empties. Returns the resolved count.
function BuffData.ReconcileContainerCount()
    local maxUsed = 0
    for _, index in pairs(BuffData.GetDB().assignments) do
        if type(index) == "number" and index > maxUsed and index <= MAX_CONTAINERS then
            maxUsed = index
        end
    end
    local desired = math.min(math.max(maxUsed + 1, 1), MAX_CONTAINERS)
    BuffData.GetDB().count = desired
    return desired
end
