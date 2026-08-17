local addonName, BBM = ...
local addon = BBM.addon

local function clearOption(tbl, key)
    TextureLoadingGroupMixin.RemoveTexture({ textures = tbl }, key)
end

local function setOption(tbl, key)
    TextureLoadingGroupMixin.AddTexture({ textures = tbl }, key)
end

local function HideRealmNames()
    if addon.db.profile.others.hideRealmNames then
        clearOption(NamePlateFriendlyFrameOptions, "updateNameUsesGetUnitName")
        clearOption(NamePlateEnemyFrameOptions, "updateNameUsesGetUnitName")
    else
        setOption(NamePlateFriendlyFrameOptions, "updateNameUsesGetUnitName")
        setOption(NamePlateEnemyFrameOptions, "updateNameUsesGetUnitName")
    end
end

local function Hook()
    if BBM.hooks.hideRealmNames then return end
    BBM.hooks.hideRealmNames = true
    hooksecurefunc(NamePlateDriverFrame, "UpdateNamePlateOptions", HideRealmNames)
end

function BBM.ApplyHideRealmNames()
    Hook()
    HideRealmNames()
end

table.insert(BBM.EnableCallbacks, function(_)
    if addon.db.profile.others.hideRealmNames then
        Hook()
    end
end)
