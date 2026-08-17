local addonName, BBM = ...
local addon = BBM.addon

local LibSerialize = LibStub("LibSerialize", true)
local LibDeflate   = LibStub:GetLibrary("LibDeflate", true)

local DEFAULT_PROFILE  = "Default"
local EXPORT_PREFIX    = "!BBM!"
local EXPORT_VERSION   = 1
local SECTIONS         = { "classIcons", "totemIcons", "arenaNames", "others" }

local GetSpecIndex        = C_SpecializationInfo.GetSpecialization
local GetSpecInfo         = C_SpecializationInfo.GetSpecializationInfo
local GetNumSpecsForClass = C_SpecializationInfo.GetNumSpecializationsForClassID
local GetSpecInfoForClass = GetSpecializationInfoForClassID

function BBM.DeepCopy(src)
    if type(src) ~= "table" then return src end
    local out = {}
    for k, v in pairs(src) do out[k] = BBM.DeepCopy(v) end
    return out
end

function BBM.NormalizeProfileName(name)
    if type(name) ~= "string" then return nil end
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end
    return name
end

local classSpecTree

function BBM.GetClassSpecTree()
    if classSpecTree then return classSpecTree end
    classSpecTree = {}

    for classID = 1, GetNumClasses() do
        local className, classFile = GetClassInfo(classID)
        if className and classFile then
            local entry = {
                classID = classID,
                file    = classFile,
                name    = className,
                color   = C_ClassColor.GetClassColor(classFile) or CreateColor(1, 1, 1),
                specs   = {},
            }
            for index = 1, (GetNumSpecsForClass(classID) or 0) do
                local specID, specName, _, specIcon = GetSpecInfoForClass(classID, index)
                if specID and specName then
                    entry.specs[#entry.specs + 1] = { id = specID, name = specName, icon = specIcon }
                end
            end
            if #entry.specs > 0 then
                classSpecTree[#classSpecTree + 1] = entry
            end
        end
    end

    return classSpecTree
end

function BBM.GetSpecDisplay(specID)
    if not specID then return nil end
    for _, class in ipairs(BBM.GetClassSpecTree()) do
        for _, spec in ipairs(class.specs) do
            if spec.id == specID then
                return spec.name .. " " .. class.name, spec.icon, class.color
            end
        end
    end
    return BBM.SpecNames[specID]
end

function BBM.GetPlayerSpecID()
    local index = GetSpecIndex()
    if not index or index == 0 then return nil end
    local specID = GetSpecInfo(index)
    if not specID or specID == 0 then return nil end
    return specID
end

function BBM.GetProfileNames()
    local names = {}
    for name in pairs(BetterBlizzMarkersDB.profiles) do
        if name ~= DEFAULT_PROFILE then names[#names + 1] = name end
    end
    table.sort(names)
    table.insert(names, 1, DEFAULT_PROFILE)
    return names
end

function BBM.ResolveProfileName()
    local db = BetterBlizzMarkersDB

    if db.autoSwitch then
        local specID = BBM.GetPlayerSpecID()
        local bound  = specID and db.specOwner[specID]
        if bound and db.profiles[bound] then return bound end
    end

    if db.global and db.profiles[db.global] then return db.global end
    return DEFAULT_PROFILE
end

function BBM.ApplyProfile()
    addon:RefreshAll()

    BBM.RunAfterCombat(function()
        if BBM.ApplyNameOnlyMode          then BBM.ApplyNameOnlyMode()          end
        if BBM.ApplyHideRealmNames        then BBM.ApplyHideRealmNames()        end
        if BBM.ApplyClassColorNames       then BBM.ApplyClassColorNames()       end
        if BBM.ApplyMoveableSettingsPanel then BBM.ApplyMoveableSettingsPanel() end
    end)

    if addon.UpdateEventRegistration then addon:UpdateEventRegistration() end
    if BBM.RefreshGUI then BBM.RefreshGUI() end
end

function BBM.SetActiveProfile(name, apply)
    local db = BetterBlizzMarkersDB
    if not db.profiles[name] then name = DEFAULT_PROFILE end

    BBM.ActiveProfileName = name
    addon.db = addon.db or {}
    addon.db.profile = db.profiles[name]

    if apply then BBM.ApplyProfile() end
end

local awaitingSpecData = false

function BBM.RefreshActiveProfile()
    local db = BetterBlizzMarkersDB
    if not db or not db.profiles then return end

    if db.autoSwitch and not BBM.GetPlayerSpecID() then
        if not awaitingSpecData then
            awaitingSpecData = true
            C_Timer.After(1, function()
                awaitingSpecData = false
                BBM.RefreshActiveProfile()
            end)
        end
        return
    end

    local resolved = BBM.ResolveProfileName()
    if resolved == BBM.ActiveProfileName then
        if BBM.RefreshProfilesPanel then BBM.RefreshProfilesPanel() end
        return
    end
    BBM.SetActiveProfile(resolved, true)
end

function BBM.SetGlobalProfile(name)
    local db = BetterBlizzMarkersDB
    if not db.profiles[name] then return end
    db.global = name
    BBM.RefreshActiveProfile()
end

function BBM.GetSpecProfile(specID)
    return BetterBlizzMarkersDB.specOwner[specID]
end

function BBM.SetSpecProfile(specID, profileName)
    BetterBlizzMarkersDB.specOwner[specID] = profileName
    BBM.RefreshActiveProfile()
end

function BBM.SetSpecProfiles(specIDs, profileName)
    local specOwner = BetterBlizzMarkersDB.specOwner
    for _, specID in ipairs(specIDs) do
        specOwner[specID] = profileName
    end
    BBM.RefreshActiveProfile()
end

function BBM.CreateProfile(name, copyFrom)
    local db = BetterBlizzMarkersDB
    name = BBM.NormalizeProfileName(name)
    if not name then return nil, "Profile name cannot be empty." end
    if db.profiles[name] then
        return nil, string.format("A profile named \"%s\" already exists.", name)
    end

    local new = (copyFrom and db.profiles[copyFrom]) and BBM.DeepCopy(db.profiles[copyFrom]) or {}
    BBM.DeepFill(new, BBM.defaultSettings)
    db.profiles[name] = new
    return name
end

function BBM.RenameProfile(old, new)
    local db = BetterBlizzMarkersDB
    if old == DEFAULT_PROFILE then return nil, "The Default profile cannot be renamed." end
    if not db.profiles[old] then return nil, "That profile no longer exists." end

    new = BBM.NormalizeProfileName(new)
    if not new then return nil, "Profile name cannot be empty." end
    if new == old then return old end
    if db.profiles[new] then
        return nil, string.format("A profile named \"%s\" already exists.", new)
    end

    db.profiles[new] = db.profiles[old]
    db.profiles[old] = nil

    for specID, owner in pairs(db.specOwner) do
        if owner == old then db.specOwner[specID] = new end
    end
    if db.global == old then db.global = new end
    if BBM.ActiveProfileName == old then BBM.SetActiveProfile(new, false) end

    return new
end

function BBM.DeleteProfile(name)
    local db = BetterBlizzMarkersDB
    if name == DEFAULT_PROFILE then return nil, "The Default profile cannot be deleted." end
    if not db.profiles[name] then return nil, "That profile no longer exists." end

    db.profiles[name] = nil
    for specID, owner in pairs(db.specOwner) do
        if owner == name then db.specOwner[specID] = nil end
    end
    if db.global == name then db.global = DEFAULT_PROFILE end

    BBM.SetActiveProfile(BBM.ResolveProfileName(), true)
    return true
end

function BBM.ResetProfile(name)
    local db = BetterBlizzMarkersDB
    local profile = db.profiles[name]
    if not profile then return nil, "That profile no longer exists." end

    wipe(profile)
    BBM.DeepFill(profile, BBM.defaultSettings)

    if name == BBM.ActiveProfileName then BBM.ApplyProfile() end
    return true
end

function BBM.ExportProfile(name)
    if not (LibSerialize and LibDeflate) then
        return nil, "The import/export libraries are not loaded."
    end

    local db = BetterBlizzMarkersDB
    local profile = db.profiles[name]
    if not profile then return nil, "That profile no longer exists." end

    local specs
    for specID, owner in pairs(db.specOwner) do
        if owner == name then
            specs = specs or {}
            specs[#specs + 1] = specID
        end
    end
    if specs then table.sort(specs) end

    local payload = {
        addon    = "BetterBlizzMarkers",
        version  = EXPORT_VERSION,
        name     = name,
        settings = BBM.DeepCopy(profile),
        specs    = specs,
    }

    local serialized = LibSerialize:SerializeEx({ errorOnUnserializableType = false }, payload)
    local compressed = LibDeflate:CompressDeflate(serialized, { level = 9 })
    if not compressed then return nil, "The profile could not be compressed." end

    return EXPORT_PREFIX .. LibDeflate:EncodeForPrint(compressed)
end

function BBM.DecodeProfileString(str)
    if not (LibSerialize and LibDeflate) then
        return nil, "The import/export libraries are not loaded."
    end
    if type(str) ~= "string" then return nil, "There is nothing to import." end

    str = str:gsub("%s+", "")
    if str == "" then return nil, "There is nothing to import." end
    if str:sub(1, #EXPORT_PREFIX) ~= EXPORT_PREFIX then
        return nil, "That does not look like a BetterBlizzMarkers profile string."
    end

    local decoded = LibDeflate:DecodeForPrint(str:sub(#EXPORT_PREFIX + 1))
    if not decoded then return nil, "The profile string is damaged or incomplete." end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil, "The profile string is damaged or incomplete." end

    local ok, payload = LibSerialize:Deserialize(decompressed)
    if not ok or type(payload) ~= "table" then
        return nil, "The profile string could not be read."
    end
    if payload.addon ~= "BetterBlizzMarkers" then
        return nil, "That profile string is from a different addon."
    end
    if payload.version ~= EXPORT_VERSION then
        return nil, "That profile string was made with an incompatible version."
    end
    if type(payload.settings) ~= "table" then
        return nil, "That profile string contains no settings."
    end

    return payload
end

local function SanitizeAgainstDefaults(input, defaults)
    local out = {}
    for key, default in pairs(defaults) do
        local value = input and input[key]
        if type(default) == "table" then
            out[key] = SanitizeAgainstDefaults(type(value) == "table" and value or nil, default)
        elseif type(value) == type(default) then
            out[key] = value
        else
            out[key] = default
        end
    end
    return out
end

function BBM.ImportProfile(payload, targetName)
    local db = BetterBlizzMarkersDB
    targetName = BBM.NormalizeProfileName(targetName)
    if not targetName then return nil, "Profile name cannot be empty." end

    local settings = SanitizeAgainstDefaults(payload.settings, BBM.defaultSettings)

    local existing = db.profiles[targetName]
    if existing then
        wipe(existing)
        for key, value in pairs(settings) do existing[key] = value end
    else
        db.profiles[targetName] = settings
    end

    if type(payload.specs) == "table" then
        local valid = {}
        for _, class in ipairs(BBM.GetClassSpecTree()) do
            for _, spec in ipairs(class.specs) do valid[spec.id] = true end
        end
        for _, specID in ipairs(payload.specs) do
            if valid[specID] then db.specOwner[specID] = targetName end
        end
    end

    BBM.RefreshActiveProfile()

    return targetName
end

function BBM.ProfileExists(name)
    return BetterBlizzMarkersDB.profiles[name] ~= nil
end

function BBM.InitProfiles()
    if type(BetterBlizzMarkersDB) ~= "table" then BetterBlizzMarkersDB = {} end
    local db = BetterBlizzMarkersDB

    if type(db.profiles) ~= "table" then
        local legacy, hadLegacy = {}, false
        for _, key in ipairs(SECTIONS) do
            if type(db[key]) == "table" then
                legacy[key] = db[key]
                hadLegacy = true
            end
            db[key] = nil
        end
        db.profiles = { [DEFAULT_PROFILE] = hadLegacy and legacy or {} }
    end

    if type(db.profiles[DEFAULT_PROFILE]) ~= "table" then db.profiles[DEFAULT_PROFILE] = {} end
    if type(db.specOwner) ~= "table" then db.specOwner = {} end
    if type(db.global) ~= "string" or not db.profiles[db.global] then db.global = DEFAULT_PROFILE end
    if db.autoSwitch == nil then db.autoSwitch = true end
    db.dbVersion = EXPORT_VERSION

    if not db.namesModeMigrated then
        for _, profile in pairs(db.profiles) do
            local an = profile.arenaNames
            if type(an) == "table" then
                if an.namesMode == "custom" then an.namesMode = "add"
                elseif an.namesMode == "replace" then an.namesMode = "adapt"
                end
            end
        end
        db.namesModeMigrated = true
    end

    for _, profile in pairs(db.profiles) do
        BBM.DeepFill(profile, BBM.defaultSettings)
    end

    BBM.SetActiveProfile(BBM.ResolveProfileName(), false)
end

table.insert(BBM.EnableCallbacks, function()
    BBM.On("PLAYER_ENTERING_WORLD", BBM.RefreshActiveProfile)

    BBM.On("PLAYER_SPECIALIZATION_CHANGED", function(_, unit)
        if unit == nil or unit == "player" then
            BBM.RefreshActiveProfile()
        end
    end)
end)
