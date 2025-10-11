local LibDeflate = LibStub("LibDeflate")
local LibSerialize = LibStub("LibSerialize")

function sArenaMixin:ExportProfile()
    local name, realm = UnitName("player")
    realm = realm or GetRealmName()
    local fullKey = name .. " - " .. realm

    local profileKey = sArena_ReloadedDB.profileKeys[fullKey]
    if not profileKey then
        return nil, "No profile found for current character."
    end

    local profileTable = sArena_ReloadedDB.profiles[profileKey]
    if not profileTable then
        return nil, "Profile data not found."
    end

    local exportTable = {
        dataType = "sArenaProfile",
        profileName = profileKey,
        data = profileTable,
    }

    local serialized = LibSerialize:Serialize(exportTable)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)
    return "!sArena:" .. encoded .. ":sArena!"
end

function sArenaMixin:ImportProfile(encodedString)
    if not encodedString:match("^!sArena:.+:sArena!$") then
        return nil, "Invalid format."
    end

    local encoded = encodedString:match("^!sArena:(.+):sArena!$")
    local compressed = LibDeflate:DecodeForPrint(encoded)
    local serialized, decompressErr = LibDeflate:DecompressDeflate(compressed)

    if not serialized then
        return nil, "Decompression error: " .. (decompressErr or "unknown")
    end

    local success, importTable = LibSerialize:Deserialize(serialized)
    if not success or type(importTable) ~= "table" then
        return nil, "Deserialization error or invalid format."
    end

    if importTable.dataType ~= "sArenaProfile" or type(importTable.data) ~= "table" then
        return nil, "Incorrect data type."
    end

    -- Smarter profile naming
    local baseName = importTable.profileName or "Imported"

    -- If profile already exists, strip off old time suffix like "MyProfile 13:37"
    if sArena_ReloadedDB.profiles[baseName] then
        -- Strip " HH:MM" if present at the end of the profile name
        baseName = baseName:gsub(" %d%d:%d%d$", "")
    end

    local newName = baseName
    if sArena_ReloadedDB.profiles[newName] then
        local timeString = date("%H:%M")
        newName = baseName .. " " .. timeString
    end

    -- Insert the imported profile
    sArena_ReloadedDB.profiles[newName] = importTable.data

    -- Apply profile to current character
    for nameRealm in pairs(sArena_ReloadedDB.profileKeys) do
        sArena_ReloadedDB.profileKeys[nameRealm] = newName
    end

    sArena_ReloadedDB.reOpenOptions = true
    ReloadUI()
    return true
end