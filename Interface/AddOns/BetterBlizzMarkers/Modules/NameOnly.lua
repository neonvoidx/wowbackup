local addonName, BBM = ...
local addon = BBM.addon

local isInArena = BBM.isInArena
local isInBG    = BBM.isInBG
local isInCity  = BBM.isInCity
local isInWorld = BBM.isInWorld
local isInPvE   = BBM.isInPvE

local CVAR = "nameplateShowOnlyNameForFriendlyPlayerUnits"

local addonTurnedItOn = false

local function ApplyNameOnlyMode(force)
    local p = addon.db.profile.others.nameOnlyMode
    local anyEnabled = p.showInArena or p.showInBG or p.showInCity or p.showInWorld or p.showInPvE

    local active = anyEnabled and (
                       (isInArena() and p.showInArena)
                    or (isInBG()    and p.showInBG)
                    or (isInCity()  and p.showInCity)
                    or (isInWorld() and p.showInWorld)
                    or (isInPvE()   and p.showInPvE)
                   ) or false

    if not active and not force and not addonTurnedItOn then return end

    addonTurnedItOn = active and true or false
    BBM.RunAfterCombat(function() C_CVar.SetCVar(CVAR, active and "1" or "0") end)
end

BBM.ApplyNameOnlyMode = ApplyNameOnlyMode

local function onZoneNameOnly(_)
    ApplyNameOnlyMode()
end

table.insert(BBM.EnableCallbacks, function(_)
    BBM.On("PLAYER_ENTERING_WORLD", onZoneNameOnly)
    BBM.On("ZONE_CHANGED_NEW_AREA", onZoneNameOnly)
end)

