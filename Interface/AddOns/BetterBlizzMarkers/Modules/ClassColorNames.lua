local addonName, BBM = ...
local addon = BBM.addon

local CVAR = "nameplateUseClassColorForFriendlyPlayerUnitNames"

local addonTurnedItOn = false

local function ApplyClassColorNames(force)
    local v = addon.db.profile.others.classColorNames
    if v == nil then return end
    if not v and not force and not addonTurnedItOn then return end

    addonTurnedItOn = v and true or false
    BBM.RunAfterCombat(function() C_CVar.SetCVar(CVAR, v and "1" or "0") end)
end

BBM.ApplyClassColorNames = ApplyClassColorNames

table.insert(BBM.EnableCallbacks, function(_)
    ApplyClassColorNames()
end)
