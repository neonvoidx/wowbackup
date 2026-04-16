----------------------------------------------------------------------
-- MidnightCheatSheet – Wishlist.lua
-- Two types of lists:
--   PRESET (addon-provided BiS): MCS.PRESET_LISTS[specKey][listName]
--     Read-only, shipped with addon code, updated with addon versions.
--   USER (player-created): db.wishlists[specKey][listName]
--     Editable, stored in SavedVariables, never overwritten by addon updates.
----------------------------------------------------------------------
local _, MCS = ...

local pairs, ipairs, format = pairs, ipairs, format
local table_insert, table_sort, table_remove = table.insert, table.sort, table.remove

MCS.DEFAULT_LISTS = {}

local function EnsureSpec(specKey)
    if not MCS.db.wishlists[specKey] then MCS.db.wishlists[specKey] = {} end
end

local function EnsureList(specKey, listName)
    EnsureSpec(specKey)
    if not MCS.db.wishlists[specKey][listName] then
        MCS.db.wishlists[specKey][listName] = {}
    end
end

----------------------------------------------------------------------
-- List type queries
----------------------------------------------------------------------

--- Check if a list name is a preset (addon-provided) list for a spec
function MCS:IsPresetList(specKey, listName)
    return self.PRESET_LISTS
        and self.PRESET_LISTS[specKey]
        and self.PRESET_LISTS[specKey][listName]
        and true or false
end

--- Check if a list name is a user list for a spec
function MCS:IsUserList(specKey, listName)
    return not self:IsPresetList(specKey, listName)
end

----------------------------------------------------------------------
-- Getters
----------------------------------------------------------------------

--- Get the items for a specific list (preset or user)
function MCS:GetWishlist(specKey, listName)
    specKey  = specKey  or self:SpecKey()
    listName = listName or self.activeListName
    if not specKey or not listName then return {} end

    -- Check preset lists first
    if self:IsPresetList(specKey, listName) then
        return self.PRESET_LISTS[specKey][listName]
    end

    -- User list
    EnsureList(specKey, listName)
    return self.db.wishlists[specKey][listName]
end

--- Get all list names for a spec (user lists first, then presets)
function MCS:GetListNames(specKey)
    specKey = specKey or self:SpecKey()
    if not specKey then return {} end

    local names, seen = {}, {}

    -- User lists first
    EnsureSpec(specKey)
    for n in pairs(self.db.wishlists[specKey]) do
        if not seen[n] then table_insert(names, n); seen[n] = true end
    end

    -- Then preset (addon) lists last
    if self.PRESET_LISTS and self.PRESET_LISTS[specKey] then
        local presetNames = {}
        for n in pairs(self.PRESET_LISTS[specKey]) do
            if not seen[n] then table_insert(presetNames, n) end
        end
        table_sort(presetNames)
        for _, n in ipairs(presetNames) do
            table_insert(names, n); seen[n] = true
        end
    end

    return names
end

--- Get only user list names (excluding presets)
function MCS:GetUserListNames(specKey)
    specKey = specKey or self:SpecKey()
    if not specKey then return {} end
    EnsureSpec(specKey)
    local names, seen = {}, {}
    for n in pairs(self.db.wishlists[specKey]) do
        if not seen[n] then table_insert(names, n); seen[n] = true end
    end
    return names
end

----------------------------------------------------------------------
-- Item queries
----------------------------------------------------------------------

function MCS:IsOnWishlist(itemID, specKey, listName)
    local wl = self:GetWishlist(specKey, listName)
    for _, e in ipairs(wl) do if e.itemID == itemID then return true end end
    return false
end

--- Check if an item is on any preset list for a spec
function MCS:IsOnPresetList(itemID, specKey)
    if not self.PRESET_LISTS or not self.PRESET_LISTS[specKey] then return false end
    for listName, wl in pairs(self.PRESET_LISTS[specKey]) do
        for _, e in ipairs(wl) do
            if e.itemID == itemID then return true, listName end
        end
    end
    return false
end

--- Check if an item is on ANY preset list across all specs
function MCS:FindItemOnPresetLists(itemID)
    if not itemID or not self.PRESET_LISTS then return {} end
    local results = {}
    for specKey, lists in pairs(self.PRESET_LISTS) do
        for listName, wl in pairs(lists) do
            for _, e in ipairs(wl) do
                if e.itemID == itemID then
                    table_insert(results, {
                        specKey   = specKey,
                        listName  = listName,
                        specLabel = self:FormatSpecKey(specKey),
                        preset    = true,
                    })
                    break
                end
            end
        end
    end
    return results
end

----------------------------------------------------------------------
-- Mutations (USER lists only — preset lists are read-only)
----------------------------------------------------------------------

function MCS:AddToWishlist(itemID, specKey, listName, source, slot)
    specKey  = specKey  or self:SpecKey()
    listName = listName or self.activeListName
    if not specKey or not itemID or not listName then return false end
    -- Block writes to preset lists
    if self:IsPresetList(specKey, listName) then return false end
    if self:IsOnWishlist(itemID, specKey, listName) then return false end
    local wl = self:GetWishlist(specKey, listName)
    table_insert(wl, { itemID = itemID, source = source or "", slot = slot or "" })
    return true
end

function MCS:RemoveFromWishlist(itemID, specKey, listName)
    specKey  = specKey  or self:SpecKey()
    listName = listName or self.activeListName
    -- Block writes to preset lists
    if self:IsPresetList(specKey, listName) then return false end
    local wl = self:GetWishlist(specKey, listName)
    for i, e in ipairs(wl) do
        if e.itemID == itemID then table_remove(wl, i); return true end
    end
    return false
end

function MCS:ToggleWishlistItem(itemID, specKey, listName, source, slot)
    specKey  = specKey  or self.viewingSpecKey or self:SpecKey()
    listName = listName or self.activeListName
    -- Block writes to preset lists
    if self:IsPresetList(specKey, listName) then return nil end
    if self:IsOnWishlist(itemID, specKey, listName) then
        self:RemoveFromWishlist(itemID, specKey, listName)
        return false
    else
        self:AddToWishlist(itemID, specKey, listName, source, slot)
        return true
    end
end

function MCS:CreateList(specKey, listName)
    if not specKey or not listName or listName == "" then return false end
    -- Don't allow creating a user list with the same name as a preset
    if self:IsPresetList(specKey, listName) then return false end
    EnsureList(specKey, listName); return true
end

function MCS:DeleteList(specKey, listName)
    if not specKey then return end
    -- Can't delete preset lists
    if self:IsPresetList(specKey, listName) then return end
    EnsureSpec(specKey)
    self.db.wishlists[specKey][listName] = nil
end

function MCS:DuplicateList(specKey, srcListName, destListName)
    if not specKey or not srcListName or not destListName or destListName == "" then return false end
    -- Don't overwrite a preset list
    if self:IsPresetList(specKey, destListName) then return false end
    -- Don't overwrite an existing user list
    EnsureSpec(specKey)
    if self.db.wishlists[specKey][destListName] and #self.db.wishlists[specKey][destListName] > 0 then return false end
    -- Deep copy items from source (preset or user)
    local src = self:GetWishlist(specKey, srcListName)
    local copy = {}
    for _, e in ipairs(src) do
        table_insert(copy, { itemID = e.itemID, source = e.source or "", slot = e.slot or "" })
    end
    self.db.wishlists[specKey][destListName] = copy
    return true
end

----------------------------------------------------------------------
-- Counts
----------------------------------------------------------------------

function MCS:TotalWishlistCount(specKey)
    specKey = specKey or self:SpecKey()
    if not specKey then return 0 end
    local t = 0
    -- Count user list items
    if self.db.wishlists[specKey] then
        for _, wl in pairs(self.db.wishlists[specKey]) do t = t + #wl end
    end
    -- Count preset list items
    if self.PRESET_LISTS and self.PRESET_LISTS[specKey] then
        for _, wl in pairs(self.PRESET_LISTS[specKey]) do t = t + #wl end
    end
    return t
end

function MCS:WishlistCount(specKey, listName)
    return #self:GetWishlist(specKey, listName)
end

----------------------------------------------------------------------
-- Formatting
----------------------------------------------------------------------

function MCS:FormatSpecKey(specKey)
    if not specKey then return "?" end
    local cls, spec = specKey:match("^(%w+)_(.+)$")
    if not cls then return specKey end
    spec = spec:gsub("_", " "):lower():gsub("(%a)([%w]*)", function(a,b) return a:upper()..b end)
    local r, g, b = self:ClassColor(cls)
    return format("|cff%02x%02x%02x%s|r %s", r*255, g*255, b*255, spec,
        cls:sub(1,1) .. cls:sub(2):lower())
end

----------------------------------------------------------------------
-- Cross-list lookups (for tooltips and UI)
----------------------------------------------------------------------

--- Find ALL wishlists (user + preset) an item appears on.
function MCS:FindItemOnLists(itemID)
    if not itemID then return {} end
    local results = {}
    -- User lists
    for specKey, lists in pairs(self.db.wishlists) do
        for listName, wl in pairs(lists) do
            for _, e in ipairs(wl) do
                if e.itemID == itemID then
                    table_insert(results, {
                        specKey   = specKey,
                        listName  = listName,
                        specLabel = self:FormatSpecKey(specKey),
                        preset    = false,
                    })
                    break
                end
            end
        end
    end
    -- Preset lists
    if self.PRESET_LISTS then
        for specKey, lists in pairs(self.PRESET_LISTS) do
            for listName, wl in pairs(lists) do
                for _, e in ipairs(wl) do
                    if e.itemID == itemID then
                        table_insert(results, {
                            specKey   = specKey,
                            listName  = listName,
                            specLabel = self:FormatSpecKey(specKey),
                            preset    = true,
                        })
                        break
                    end
                end
            end
        end
    end
    return results
end

--- Check if a list should show in tooltips (default: true)
function MCS:IsTooltipListEnabled(specKey, listName)
    if not self.db or not self.db.tooltipLists then return true end
    local key = specKey .. ":" .. listName
    if self.db.tooltipLists[key] == false then return false end
    return true
end

--- Toggle whether a list shows in tooltips
function MCS:ToggleTooltipList(specKey, listName)
    if not self.db then return end
    if not self.db.tooltipLists then self.db.tooltipLists = {} end
    local key = specKey .. ":" .. listName
    if self.db.tooltipLists[key] == false then
        self.db.tooltipLists[key] = nil  -- default = enabled, so remove the key
    else
        self.db.tooltipLists[key] = false
    end
end

--- Build tooltip text showing which lists an item is on.
function MCS:GetWishlistTooltipText(itemID)
    local hits = self:FindItemOnLists(itemID)
    if #hits == 0 then return nil end
    local myClass = self:GetPlayerClass()
    local parts = {}
    for _, h in ipairs(hits) do
        if self:IsTooltipListEnabled(h.specKey, h.listName) then
            -- Filter out other classes if the global toggle is off
            local hClass = h.specKey:match("^(%w+)_")
            if hClass == myClass or self.db.tooltipOtherClasses then
                local tag = h.preset and "|cff6688cc[BiS]|r " or ""
                table_insert(parts, tag .. h.specLabel .. " / |cffFFD100" .. h.listName .. "|r")
            end
        end
    end
    if #parts == 0 then return nil end
    return parts
end
