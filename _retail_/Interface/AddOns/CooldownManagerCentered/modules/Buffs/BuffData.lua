local _, ns = ...

local BuffData = {}
ns.BuffData = BuffData

local MAX_CONTAINERS = ns.CONSTANTS and ns.CONSTANTS.MAX_TRACKERS or 10

local function BuildStableKey(cooldownID, spellID, overrideTooltipSpellID)
    if overrideTooltipSpellID then
        return "t:" .. overrideTooltipSpellID
    end
    if spellID then
        return "s:" .. spellID
    end
    if cooldownID then
        return "c:" .. cooldownID
    end
    return nil
end

local infoByCooldownID = {}
local scanCache = nil
local blizzardAuraSpellIDs = nil

local function AddCooldownInfoSpellIDs(spellIDs, info)
    if not info then
        return
    end
    if info.spellID then
        spellIDs[info.spellID] = true
    end
    if info.overrideSpellID then
        spellIDs[info.overrideSpellID] = true
    end
    if info.overrideTooltipSpellID then
        spellIDs[info.overrideTooltipSpellID] = true
    end
    for _, linkedSpellID in ipairs(info.linkedSpellIDs or {}) do
        spellIDs[linkedSpellID] = true
    end
end

local function GetBlizzardAuraSpellIDs()
    if blizzardAuraSpellIDs then
        return blizzardAuraSpellIDs
    end

    blizzardAuraSpellIDs = {}
    if not C_CooldownViewer or not C_CooldownViewer.GetCooldownViewerCategorySet then
        return blizzardAuraSpellIDs
    end

    local categories = {
        Enum.CooldownViewerCategory.TrackedBuff,
        Enum.CooldownViewerCategory.TrackedBar,
    }
    for _, category in ipairs(categories) do
        -- allowUnlearned also returns entries Blizzard places in Not Displayed
        -- Buffs, including HideByDefault definitions.
        local cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(category, true)
        for _, cooldownID in ipairs(cooldownIDs) do
            AddCooldownInfoSpellIDs(
                blizzardAuraSpellIDs,
                C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
            )
        end
    end
    return blizzardAuraSpellIDs
end

local function CacheCustomAuraDisplayData(definition)
    if type(definition) ~= "table" then
        return
    end

    local spellID = tonumber(definition.spellID)
    if not spellID then
        return
    end

    if definition.name and definition.iconID then
        return
    end

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then
        definition.name = definition.name or spellInfo.name
        definition.iconID = definition.iconID or spellInfo.iconID
    end
    definition.iconID = definition.iconID or C_Spell.GetSpellTexture(spellID)
end

---@return table config The profile.buffContainers table, created on first access.
function BuffData.GetDB()
    ns.db.profile.buffContainers = ns.db.profile.buffContainers or {}
    local db = ns.db.profile.buffContainers
    db.assignments = db.assignments or {}
    db.orders = db.orders or {}
    db.customAuras = db.customAuras or {}
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
    local spellID = info.overrideTooltipSpellID or info.overrideSpellID or info.spellID
    local stableKey = BuildStableKey(cooldownID, spellID, info.overrideTooltipSpellID)
    local resolved = {
        source = "cooldownViewer",
        cooldownID = cooldownID,
        spellID = spellID,
        stableKey = stableKey,
        name = spellID and C_Spell.GetSpellName(spellID) or nil,
        iconID = spellID and C_Spell.GetSpellTexture(spellID) or nil,
    }

    infoByCooldownID[cooldownID] = resolved
    return resolved
end

local function BuildCustomAuraEntry(stableKey, definition)
    local spellID = definition and definition.spellID
    CacheCustomAuraDisplayData(definition)
    return {
        source = "customAura",
        stableKey = stableKey,
        spellID = spellID,
        name = definition.name,
        iconID = definition.iconID,
        custom = true,
    }
end

function BuffData.GetCustomAuraDefinitions()
    return BuffData.GetDB().customAuras
end

function BuffData.GetCustomAuraStackColor(stableKey)
    local definition = stableKey and BuffData.GetDB().customAuras[stableKey]
    local color = definition and definition.stackColor
    if type(color) == "table" and color[1] ~= nil and color[2] ~= nil and color[3] ~= nil then
        return color
    end
    return nil
end

function BuffData.SetCustomAuraStackColor(stableKey, r, g, b)
    local definition = stableKey and BuffData.GetDB().customAuras[stableKey]
    if not definition then
        return
    end
    definition.stackColor = r ~= nil and { r, g, b } or nil
end

function BuffData.ContainerHasCustomAura(containerIndex)
    if not ns.CustomAuraProvider then
        return false
    end
    local db = BuffData.GetDB()
    for stableKey, definition in pairs(db.customAuras) do
        if
            type(definition) == "table"
            and tonumber(definition.spellID)
            and db.assignments[stableKey] == containerIndex
        then
            return true
        end
    end
    return false
end

function BuffData.HasCustomAura(spellID)
    return BuffData.GetDB().customAuras["a:" .. tostring(spellID)] ~= nil
end

function BuffData.HasBlizzardAura(spellID)
    spellID = tonumber(spellID)
    return spellID ~= nil and GetBlizzardAuraSpellIDs()[spellID] == true
end

function BuffData.AddCustomAura(spellID)
    spellID = tonumber(spellID)
    if not spellID or spellID <= 0 or spellID ~= math.floor(spellID) then
        return nil, "Unknown spell ID"
    end

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if not spellInfo or not spellInfo.name then
        return nil, "Unknown spell ID"
    end

    local stableKey = "a:" .. spellID
    local db = BuffData.GetDB()
    if db.customAuras[stableKey] or BuffData.HasBlizzardAura(spellID) then
        return nil, "Aura already added"
    end

    local definition = {
        spellID = spellID,
        name = spellInfo.name,
        iconID = spellInfo.iconID or C_Spell.GetSpellTexture(spellID),
    }
    db.customAuras[stableKey] = definition

    BuffData.InsertEntryAt(1, BuildCustomAuraEntry(stableKey, definition), nil, false)
    return stableKey
end

function BuffData.RemoveCustomAura(stableKey)
    local db = BuffData.GetDB()
    if not stableKey or not db.customAuras[stableKey] then
        return false
    end
    db.customAuras[stableKey] = nil
    db.assignments[stableKey] = nil
    db.orders[stableKey] = nil
    return true
end

function BuffData.GetAllEntries()
    local entries = {}
    for _, entry in ipairs(BuffData.ScanTrackedBuffs()) do
        entries[#entries + 1] = entry
    end

    -- The provider module does not exist on 12.0.7. Keeping this conditional also
    -- keeps saved 12.1 definitions completely absent from the 12.0.7 editor.
    if ns.CustomAuraProvider then
        for stableKey, definition in pairs(BuffData.GetCustomAuraDefinitions()) do
            if type(definition) == "table" and tonumber(definition.spellID) then
                entries[#entries + 1] = BuildCustomAuraEntry(stableKey, definition)
            end
        end
    end
    return entries
end

---Tracked buffs with live frames in BuffIconCooldownViewer.
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
                    info.layoutIndex = item.layoutIndex
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
    blizzardAuraSpellIDs = nil
    wipe(infoByCooldownID)
end

function BuffData.GetStableKeyForCooldownID(cooldownID)
    local info = ResolveCooldownInfo(cooldownID)
    return info and info.stableKey or BuildStableKey(cooldownID, nil)
end

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

function BuffData.AssignKey(key, containerIndex)
    if not key then
        return false
    end
    local db = BuffData.GetDB()
    if db.customAuras[key] and (not containerIndex or containerIndex < 1 or containerIndex > MAX_CONTAINERS) then
        return false
    end
    db.assignments[key] = containerIndex
    return true
end

local function SortEntries(entries)
    local orders = BuffData.GetDB().orders
    table.sort(entries, function(a, b)
        local aOrder = orders[a.stableKey] or math.huge
        local bOrder = orders[b.stableKey] or math.huge
        if aOrder ~= bOrder then
            return aOrder < bOrder
        end

        local aLayoutIndex = a.layoutIndex or math.huge
        local bLayoutIndex = b.layoutIndex or math.huge
        if aLayoutIndex ~= bLayoutIndex then
            return aLayoutIndex < bLayoutIndex
        end
        return (a.stableKey or "") < (b.stableKey or "")
    end)
end

local function GetBuffsForAssignment(containerIndex)
    local result = {}
    local assignments = BuffData.GetDB().assignments
    for _, entry in ipairs(BuffData.GetAllEntries()) do
        if assignments[entry.stableKey] == containerIndex then
            result[#result + 1] = entry
        end
    end
    SortEntries(result)
    return result
end

function BuffData.GetBuffsForContainer(containerIndex)
    return GetBuffsForAssignment(containerIndex)
end

function BuffData.GetUnassignedBuffs()
    local count = BuffData.GetContainerCount()
    local result = {}
    for _, entry in ipairs(BuffData.GetAllEntries()) do
        local index = BuffData.GetDB().assignments[entry.stableKey]
        if not index or index < 1 or index > count then
            result[#result + 1] = entry
        end
    end
    SortEntries(result)
    return result
end

function BuffData.InsertEntryAt(containerIndex, entry, targetEntry, insertBefore)
    if not entry or not entry.stableKey then
        return false
    end
    if entry.custom and (not containerIndex or containerIndex < 1 or containerIndex > MAX_CONTAINERS) then
        return false
    end

    local entries = containerIndex and GetBuffsForAssignment(containerIndex) or BuffData.GetUnassignedBuffs()
    for index = #entries, 1, -1 do
        if entries[index].stableKey == entry.stableKey then
            table.remove(entries, index)
            break
        end
    end

    local insertIndex = #entries + 1
    if targetEntry and targetEntry.stableKey then
        for index, candidate in ipairs(entries) do
            if candidate.stableKey == targetEntry.stableKey then
                insertIndex = insertBefore and index or (index + 1)
                break
            end
        end
    end

    table.insert(entries, insertIndex, entry)
    local orders = BuffData.GetDB().orders
    for index, candidate in ipairs(entries) do
        orders[candidate.stableKey] = index
    end
    BuffData.AssignKey(entry.stableKey, containerIndex)
    return true
end

function BuffData.SortCooldownFrames(frames)
    local orders = BuffData.GetDB().orders
    table.sort(frames, function(a, b)
        local aCooldownID = a.cooldownID or (a.GetCooldownID and a:GetCooldownID())
        local bCooldownID = b.cooldownID or (b.GetCooldownID and b:GetCooldownID())
        local aOrder = orders[BuffData.GetStableKeyForCooldownID(aCooldownID)] or math.huge
        local bOrder = orders[BuffData.GetStableKeyForCooldownID(bCooldownID)] or math.huge
        if aOrder ~= bOrder then
            return aOrder < bOrder
        end

        local aLayoutIndex = a.layoutIndex or math.huge
        local bLayoutIndex = b.layoutIndex or math.huge
        if aLayoutIndex ~= bLayoutIndex then
            return aLayoutIndex < bLayoutIndex
        end
        return (aCooldownID or 0) < (bCooldownID or 0)
    end)
end

-- Emptiness is judged from the persistent assignment table, not the current-spec
-- scan: a container "used" only by another spec's buff must keep its slot so the
-- count (and every higher container's index) stays stable across spec swaps.
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
