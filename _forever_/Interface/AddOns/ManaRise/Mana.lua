-- ManaRise - Mana.lua
-- Resource reading and per-spell cost lookup for mana, rage, energy and
-- focus. (The module keeps its original name; it covers every resource.)
--
-- Each action is matched to ONE resource: the first cost entry of the spell
-- in a tracked power type whose required aura/form (if any) is active. The
-- current value of that resource is read with UnitPower under the same
-- secret-value rules as mana: a secret value is never compared or used in
-- arithmetic, only handed to the engine's StatusBar.

local _, ns = ...

local M = {}
ns.Mana = M

local IsSecret = ns.IsSecret
local CanAccessTable = ns.CanAccessTable

-- Order matters only for display (status, options panel).
M.ORDER = { "mana", "rage", "energy", "focus" }
M.RESOURCES = {
    mana   = { key = "mana",   label = "Mana",   token = "MANA",   enum = "Mana",   fallback = 0 },
    rage   = { key = "rage",   label = "Rage",   token = "RAGE",   enum = "Rage",   fallback = 1 },
    focus  = { key = "focus",  label = "Focus",  token = "FOCUS",  enum = "Focus",  fallback = 2 },
    energy = { key = "energy", label = "Energy", token = "ENERGY", enum = "Energy", fallback = 3 },
}

local byPowerType = {}   -- [powerType number] = resource
local byToken = {}       -- ["RAGE"] = resource

local costCache = {}     -- [spellID] = { cost, resource } | false
local reasonCache = {}   -- [spellID] = reason string when not tracked

M.last = {}              -- [resource key] = last observed NON-secret value

function M:Init()
    wipe(byPowerType)
    wipe(byToken)
    local PT = Enum and Enum.PowerType
    for _, r in pairs(self.RESOURCES) do
        local pt = PT and PT[r.enum]
        if type(pt) ~= "number" then pt = r.fallback end
        r.powerType = pt
        byPowerType[pt] = r
        byToken[r.token] = r
    end
    self:InvalidateCosts()
end

-- Resources ManaRise follows with the current setting.
function M:IsTracked(key)
    if key == "mana" then return true end
    return ns.db == nil or ns.db.resource ~= "mana"
end

---------------------------------------------------------------------------
-- Current value of one resource (default mana).
-- Returns value, isSecret. value is nil when unavailable.
---------------------------------------------------------------------------
function M:GetCurrent(key)
    local r = self.RESOURCES[key or "mana"]
    local v = ns.api.UnitPower("player", r.powerType)
    if IsSecret(v) then
        return v, true
    end
    if type(v) ~= "number" then
        return nil, false
    end
    return v, false
end

-- Does the player have this resource right now? Per the client docs, power
-- values are only secret if the unit actually has that power type, so a
-- secret max implies the pool exists.
function M:HasPool(key)
    local r = self.RESOURCES[key or "mana"]
    local max = ns.api.UnitPowerMax("player", r.powerType)
    if IsSecret(max) then
        return true
    end
    return type(max) == "number" and max > 0
end

-- Which resource a UNIT_POWER_UPDATE payload is about.
-- Returns a resource key, true (unknown / secret: update everything), or nil
-- (a power type ManaRise doesn't track, e.g. combo points).
function M:TokenResource(token)
    if token == nil or IsSecret(token) then return true end
    local r = byToken[token]
    if r and self:IsTracked(r.key) then return r.key end
    return nil
end

---------------------------------------------------------------------------
-- Spell cost
-- Returns required amount (number > 0) and resource key, or nil plus a
-- reason. Uses minCost (the minimum required to cast), not the optional
-- extra cost. Costs whose requiredAuraID is not active (e.g. wrong form) are
-- ignored, so a druid's costs follow the current form.
---------------------------------------------------------------------------
local function LookupCost(spellID)
    local costs = ns.api.GetSpellPowerCost(spellID)
    if costs == nil then
        return nil, nil, "no-resource-cost"
    end
    if IsSecret(costs) or not CanAccessTable(costs) then
        return nil, nil, "secret-cost"
    end

    local reason = (ns.db and ns.db.resource == "mana") and "no-mana-cost" or "no-tracked-cost"
    for i = 1, #costs do
        local info = costs[i]
        if type(info) == "table" then
            local t = info.type
            if IsSecret(t) then
                reason = "secret-cost"
            else
                local r = byPowerType[t]
                if r and M:IsTracked(r.key) then
                    local req, has = info.requiredAuraID, info.hasRequiredAura
                    local applies = true
                    if IsSecret(req) or IsSecret(has) then
                        applies = false
                        reason = "secret-cost"
                    elseif type(req) == "number" and req ~= 0 and not has then
                        applies = false
                        reason = "cost-aura-inactive"
                    end

                    if applies then
                        local mc = info.minCost
                        if mc == nil then mc = info.cost end
                        if IsSecret(mc) then
                            reason = "secret-cost"
                        elseif type(mc) == "number" and mc > 0 then
                            return mc, r.key, nil
                        else
                            reason = "zero-cost"
                        end
                    end
                end
            end
        end
    end
    return nil, nil, reason
end

function M:GetRequiredCost(spellID)
    local cached = costCache[spellID]
    if cached ~= nil then
        if cached then return cached[1], cached[2], nil end
        return nil, nil, reasonCache[spellID]
    end
    local cost, key, reason = LookupCost(spellID)
    costCache[spellID] = cost and { cost, key } or false
    reasonCache[spellID] = reason
    return cost, key, reason
end

function M:InvalidateCosts()
    wipe(costCache)
    wipe(reasonCache)
end
