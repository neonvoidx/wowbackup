
local addonName, addonTable = ...

local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("RdysCrateTracker", true) or {}

RdyCrateGlobal2 = addonTable
local RdysCrateTracker = LibStub("AceAddon-3.0"):GetAddon("RdysCrateTracker", true)
if not RdysCrateTracker then
    error("RdysCrateTracker addon not found. Please ensure it is loaded.")
end
AceComm = LibStub("AceComm-3.0")


_G.RdysCrateTracker = RdysCrateTracker

------------------------------------------------------------
-- Ignore locations / helpers
------------------------------------------------------------
local ignoreLocations = {
    [2255] = { -- Azh-Kahet
        ["0.620412,0.869144"] = true
    },
    [2215] = { -- Hallowfall
        ["0.327974,0.215208"] = true
    },
    [2248] = { -- Isle of Dorn
        ["0.699204,0.758197"] = true
    },
    [2214] = { -- Ringing Deeps
        ["0.620949,0.979688"] = true
    },
    [2369] = { -- Siren Isle
        ["0.956188,0.539799"] = true
    },
    [2346] = { -- Undermine
        ["0.229750,0.500907"] = true
    }
}
RdysCrateTracker.ignoreLocations = ignoreLocations

local function getPositionKey(x, y)
        if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    return string.format("%.6f,%.6f", x, y)
end

local function isIgnoredLocation(position, mapID)
        if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    if type(position) ~= "table" or not position.x or not position.y or not mapID then
        return false
    end
    local ignoredCoords = RdysCrateTracker.ignoreLocations[mapID]
    if not ignoredCoords then return false end
    local key = getPositionKey(position.x, position.y)
    return not not ignoredCoords[key]
end
RdysCrateTracker.isIgnoredLocation = isIgnoredLocation


local function compareZones(z1, z2)
    local profile = RdysCrateTracker.db.profile
    if not profile or not profile.enable or profile.notPvp then
        -- Fallback to stable numeric sorting
        return z1 < z2
    end

    local curTime = GetServerTime()
    local ts1 = RdysCrateTracker.nextCrateTime(profile.crateDB[z1], curTime)
    local ts2 = RdysCrateTracker.nextCrateTime(profile.crateDB[z2], curTime)

    if ts1 == nil and ts2 == nil then
        return z1 < z2
    elseif ts1 == nil then
        return false
    elseif ts2 == nil then
        return true
    end

    return ts1 < ts2
end

RdysCrateTracker.compareZones = compareZones

local CROSS_ZONE_SHARD_RESET_WINDOW  = 600  -- seconds: how long ago a same-shard entry in another zone is still relevant
local CROSS_ZONE_CONFIRM_MIN_DELAY   = 10   -- seconds: minimum wait before a second report counts as confirmation
local CROSS_ZONE_CONFIRM_WINDOW      = 120  -- seconds: maximum hold time for a pending cross-zone shard spot

local function FindRecentCrossZoneShardConflict(zoneID, shardID)
    local profile = RdysCrateTracker.db and RdysCrateTracker.db.profile
    if not profile or not profile.crateDB or not zoneID or not shardID or shardID == "N/A" then
        return nil
    end

    local now = GetServerTime()

    for otherZoneID, existing in pairs(profile.crateDB) do
        local normalizedOtherZone = RdysCrateTracker:NormalizeZoneID(otherZoneID)
        if normalizedOtherZone
           and normalizedOtherZone ~= zoneID
           and type(existing) == "table"
           and existing.shardhist == shardID
           and existing.ts
           and (now - existing.ts) < CROSS_ZONE_SHARD_RESET_WINDOW
        then
            return normalizedOtherZone, existing
        end
    end

    return nil
end

local function ShouldDelayCrossZoneShardSpot(crateInfo, sender)
    local profile = RdysCrateTracker.db and RdysCrateTracker.db.profile
    if not profile or not profile.enable or profile.notPvp then
        return false
    end

    if sender and sender ~= UnitName("player") then
        return false
    end

    if type(crateInfo) ~= "table" or not crateInfo.zoneID then
        return false
    end

    local zoneID = RdysCrateTracker:NormalizeZoneID(crateInfo.zoneID)
    local shardID = crateInfo.shardhist
    if not zoneID or not shardID or shardID == "N/A" then
        return false
    end

    local conflictZoneID = FindRecentCrossZoneShardConflict(zoneID, shardID)
    if not conflictZoneID then
        return false
    end

    RdysCrateTracker.pendingCrossZoneShardSpots = RdysCrateTracker.pendingCrossZoneShardSpots or {}

    local key = tostring(zoneID) .. ":" .. tostring(shardID)
    local pending = RdysCrateTracker.pendingCrossZoneShardSpots[key]
    local now = GetServerTime()

    if pending
       and pending.conflictZoneID == conflictZoneID
       and (now - pending.ts) >= CROSS_ZONE_CONFIRM_MIN_DELAY
       and (now - pending.ts) <= CROSS_ZONE_CONFIRM_WINDOW
    then
        RdysCrateTracker.pendingCrossZoneShardSpots[key] = nil
        return false
    end

    if pending
       and pending.conflictZoneID == conflictZoneID
       and (now - pending.ts) < CROSS_ZONE_CONFIRM_MIN_DELAY
    then
        return true
    end

    RdysCrateTracker.pendingCrossZoneShardSpots[key] = {
        ts = now,
        zoneID = zoneID,
        shardID = shardID,
        conflictZoneID = conflictZoneID,
    }

    if profile.debugged then
        print(string.format(
            "|cffff9966[RCT]|r Holding crate spot for zone %d on shard %s; same shard was recently recorded in zone %d. Waiting for second confirmation.",
            zoneID,
            tostring(shardID),
            conflictZoneID
        ))
    end

    return true
end



local function sortedZones()
    local profile = RdysCrateTracker.db.profile
    if not profile or not profile.enable then return {} end
    if profile.notPvp then return {} end

    local zones = {}

    for k, v in pairs(profile.crateDB or {}) do
        if v ~= nil then
            local nz = tonumber(k)
            if nz then
                table.insert(zones, nz)
            end
        end
    end

    table.sort(zones, RdysCrateTracker.compareZones)
    return zones
end

RdysCrateTracker.sortedZones = sortedZones

local function SafeShardFromGUID(guid)
    -- Some GUID-like values can be "secret" and explode on string ops.
    if guid == nil then
        return nil, nil
    end

    -- Must be a plain Lua string to even attempt parsing.
    if type(guid) ~= "string" then
        return nil, nil
    end

    -- Protected parse (prevents "secret value" hard error)
    local ok, instance, shard = pcall(function()
        -- Fast parse without allocating a table:
        -- Format: Creature-0-....-<shard>-....
        local a, b, c, d, e = strsplit("-", guid)
        return tonumber(d), tonumber(e)
    end)

    if not ok then
        return nil, nil
    end

    return shard, instance
end


function RdysCrateTracker:PlayGlobalCrateAlert(alertData)
   --placeholder
end

local function SafeShardFromVignetteGUID(guid)
    if type(guid) ~= "string" or guid == "" then
        return nil
    end

    -- 1) Try your existing unit GUID shard parser first (sometimes works)
    local shard = SafeShardFromGUID(guid)
    if shard then
        return shard
    end

    -- 2) Vignette GUIDs can include a zoneUID/shard-like numeric segment
    -- We extract the last big numeric token as a best-effort shard/zoneUID.
    local lastNum
    for n in guid:gmatch("(%d+)") do
        lastNum = n
    end

    if lastNum then
        local v = tonumber(lastNum)
        if v and v > 0 then
            return v
        end
    end

    return nil
end


-------------------------------------------------
-- Shard Display Updater
-------------------------------------------------
function RdysCrateTracker:UpdateShardID2()
    local shard = self.ShardID or self.db.profile.ShardID or "N/A"
    if not shard or shard == "" then
        shard = "N/A"
    end

    self.ShardID = shard
    self.db.profile.ShardID = shard

    if self.titlepanel and self.titlepanel.shardLabel then
        self.titlepanel.shardLabel:SetText(shard)
    end

    if self.db.profile.debug then
        print("Shard updated:", shard)
    end
end

-------------------------------------------------
-- Vignette Scanner Integration
-------------------------------------------------
---
RdysCrateTracker.vigCooldown = RdysCrateTracker.vigCooldown or {}
RdysCrateTracker.vigCooldownTime = RdysCrateTracker.vigCooldownTime or 30
---------------------------------------------------------
-- FIXED VIGNETTE SCANNER (Zone-scoped cooldowns)
---------------------------------------------------------
local function checkWorldMapForWarSupplyCaseOrPlane()
    local profile = RdysCrateTracker.db and RdysCrateTracker.db.profile
    if not profile or not profile.enable or profile.notPvp then return end
    if profile.Combatdisable and UnitAffectingCombat("player") then return end

    local inInstance, instanceType = IsInInstance()
if inInstance and instanceType == "pvp" then
    return
end
    --------------------------------------------------------
    -- ALWAYS normalize zone for vignette lookup
    --------------------------------------------------------
    local rawZone = RdysCrateTracker.normalizedZoneID or RdysCrateTracker.currentZoneID
    if not rawZone then return end

    local zoneID = RdysCrateTracker:NormalizeZoneID(rawZone)
    if not zoneID then return end

    --------------------------------------------------------
    -- Ensure zone-scoped cooldown table exists
    --------------------------------------------------------
    RdysCrateTracker.vigCooldown = RdysCrateTracker.vigCooldown or {}
    RdysCrateTracker.vigCooldown[zoneID] = RdysCrateTracker.vigCooldown[zoneID] or {}
    local zoneCooldown = RdysCrateTracker.vigCooldown[zoneID]

    --------------------------------------------------------
    -- Get active vignettes
    --------------------------------------------------------
    local vignettes = C_VignetteInfo.GetVignettes()
    if not vignettes then return end

    for _, vignetteGUID in ipairs(vignettes) do
        local info = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
        if info then
            ------------------------------------------------
            -- MIDNIGHT-SAFE SHARD ID EXTRACTION
            ------------------------------------------------
            local shardID = SafeShardFromVignetteGUID(vignetteGUID) or RdysCrateTracker.ShardID or profile.ShardID or "N/A"

        if shardID and shardID ~= "N/A" and shardID ~= RdysCrateTracker.ShardID then
                RdysCrateTracker.ShardID = shardID
                RdysCrateTracker._shardZone = zoneID  -- tag which zone this shard belongs to
                profile.ShardID = shardID
                RdysCrateTracker:UpdateShardID2()
        end

            ------------------------------------------------
            -- Zone+GUID-based cooldown 
            ------------------------------------------------
            local guidKey = vignetteGUID or "none"
            local now = GetServerTime()
            local last = zoneCooldown[guidKey]
            local cdTime = RdysCrateTracker.vigCooldownTime or 30

            -- Soft cooldown check (prevents spam without hard-locking)
            if not last or (now - last) >= cdTime then
                -- Start cooldown immediately for this zone+GUID
                zoneCooldown[guidKey] = now

                -- 3-second confirmation window
                C_Timer.After(3, function()
                    local freshInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
                    if not freshInfo then return end

                    local pos = C_VignetteInfo.GetVignettePosition(vignetteGUID, zoneID)
                    if not pos then return end

                    -- Must be a crate-type vignette
                    if not RdysCrateTracker.vignetteids
                       or not RdysCrateTracker.vignetteids[freshInfo.vignetteID] then
                        return
                    end

                    -- Ignored location?
                    if RdysCrateTracker.isIgnoredLocation
                       and RdysCrateTracker.isIgnoredLocation(pos, zoneID) then
                        return
                    end

                    -- Finally notify crate handler
                    if type(RdysCrateTracker.handleVignetteMessage) == "function" then
                        RdysCrateTracker.handleVignetteMessage(freshInfo)
                    end


                    local vigType = RdysCrateTracker.vignetteids and RdysCrateTracker.vignetteids[freshInfo.vignetteID]
                    local isActiveCrate = vigType and vigType ~= "Claimed" and vigType ~= "On Ground" and vigType ~= "Falling To Ground"
                    if isActiveCrate and type(RdysCrateTracker.crateSpotted) == "function" then
                        RdysCrateTracker:crateSpotted("HatedCrate1", UnitName("player"))
                    end
                end)
            end
        end
    end
end

RdysCrateTracker.checkWorldMapForWarSupplyCaseOrPlane = checkWorldMapForWarSupplyCaseOrPlane

---------------------------------------------------------
-- 
---------------------------------------------------------
RdysCrateTracker:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
    RdysCrateTracker.vigCooldown = {}
end)

RdysCrateTracker:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    RdysCrateTracker.vigCooldown = {}
end)

---------------------------------------------------------
-- Keep existing vignette listener
---------------------------------------------------------
RdysCrateTracker:RegisterEvent("VIGNETTES_UPDATED", checkWorldMapForWarSupplyCaseOrPlane)


-------------------------------------------------
-- Mouseover Integration (still valid)
-------------------------------------------------

local function HandleMouseover()
    -- Optimization: Skip processing if we already have a valid shard for the current zone
    local currentZone = RdysCrateTracker.normalizedZoneID or RdysCrateTracker.currentZoneID
    local hasValidShard = RdysCrateTracker.ShardID and RdysCrateTracker.ShardID ~= "N/A" and RdysCrateTracker.ShardID ~= ""
    if hasValidShard and RdysCrateTracker._shardZone == currentZone then
        return
    end

    local guid = UnitGUID("mouseover")
    if not guid then return end

    local inInstance, instanceType = IsInInstance()
    if inInstance and instanceType == "pvp" then return end

    local shard, unitInstance = SafeShardFromGUID(guid)

    if RdysCrateTracker.db.profile.debugged then
        print(string.format("|cff33ff99[RCT]|r Mouseover GUID check: %s -> Shard: %s", tostring(guid), tostring(shard)))
    end

    if not shard then return end

    -- Prevent bleeding through instance portals or macro-continent anomalies
    local _, _, _, _, _, _, _, playerInstance = GetInstanceInfo()
    if unitInstance and playerInstance and unitInstance ~= playerInstance then
        return
    end

    if shard == RdysCrateTracker.ShardID then return end

    -- Capture the zone this shard was read in
    local capturedZone = RdysCrateTracker.normalizedZoneID or RdysCrateTracker.currentZoneID

    -- Store as pending (any new mouseover overwrites the prior pending)
    RdysCrateTracker._pendingMouseoverShard = shard
    RdysCrateTracker._pendingMouseoverZone  = capturedZone

    -- Wait 5 seconds to confirm shard is stable and zone hasn't changed
    C_Timer.After(5, function()
        -- Discard if a newer mouseover replaced this one
        if RdysCrateTracker._pendingMouseoverShard ~= shard then return end

        local currentZone = RdysCrateTracker.normalizedZoneID or RdysCrateTracker.currentZoneID
        if currentZone ~= capturedZone then
            -- Zone changed during the wait; shard belongs to a different zone, discard
            RdysCrateTracker._pendingMouseoverShard = nil
            RdysCrateTracker._pendingMouseoverZone  = nil
            return
        end

        -- Confirmed: same shard, same zone after 5s
        RdysCrateTracker.ShardID = shard
        RdysCrateTracker._shardZone = currentZone
        RdysCrateTracker.db.profile.ShardID = shard
        RdysCrateTracker._pendingMouseoverShard = nil
        RdysCrateTracker._pendingMouseoverZone  = nil
        RdysCrateTracker:UpdateShardID2()
    end)
end

RdysCrateTracker.mouseoverFrame = CreateFrame("Frame")
RdysCrateTracker.mouseoverFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
RdysCrateTracker.mouseoverFrame:SetScript("OnEvent", HandleMouseover)

-------------------------------------------------
-- Nameplate Integration
-------------------------------------------------
local function OnHealthDetection(self, event, unit)
    -- Optimization: Skip processing if we already have a valid shard for the current zone
    local currentZone = RdysCrateTracker.normalizedZoneID or RdysCrateTracker.currentZoneID
    local hasValidShard = RdysCrateTracker.ShardID and RdysCrateTracker.ShardID ~= "N/A" and RdysCrateTracker.ShardID ~= ""
    if hasValidShard and RdysCrateTracker._shardZone == currentZone then
        return
    end

    if not unit then return end
    if not UnitExists(unit) then return end
    
    local guid = UnitGUID(unit) 
    if not guid then return end

    local inInstance, instanceType = IsInInstance()
    if inInstance and instanceType == "pvp" then return end

    local shard, unitInstance = SafeShardFromGUID(guid)

    if RdysCrateTracker.db.profile.debugged then
        print(string.format("|cff33ff99[RCT]|r Nameplate GUID check: %s -> Shard: %s", tostring(guid), tostring(shard)))
    end

    if not shard then return end

    
    local _, _, _, _, _, _, _, playerInstance = GetInstanceInfo()
    if unitInstance and playerInstance and unitInstance ~= playerInstance then
        return
    end

    if shard == RdysCrateTracker.ShardID then return end

    local capturedZone = RdysCrateTracker.normalizedZoneID or RdysCrateTracker.currentZoneID

    RdysCrateTracker._pendingNameplateShard = shard
    RdysCrateTracker._pendingNameplateZone  = capturedZone

    if RdysCrateTracker.db.profile.debugged then
        print(string.format("|cff33ff99[RCT]|r Nameplate detected new shard: %s - waiting 5s to confirm.", tostring(shard)))
    end

    -- Wait 5 seconds to confirm shard is stable and zone hasn't changed
    C_Timer.After(5, function()
        if RdysCrateTracker._pendingNameplateShard ~= shard then return end

        local currentZone = RdysCrateTracker.normalizedZoneID or RdysCrateTracker.currentZoneID
        if currentZone ~= capturedZone then return end

        RdysCrateTracker.ShardID = shard
        RdysCrateTracker._shardZone = currentZone
        RdysCrateTracker.db.profile.ShardID = shard
        RdysCrateTracker._pendingNameplateShard = nil
        RdysCrateTracker._pendingNameplateZone  = nil
        RdysCrateTracker:UpdateShardID2()

        if RdysCrateTracker.db.profile.debugged then
            print(string.format("|cff33ff99[RCT]|r Shard updated from Nameplate: %s", tostring(shard)))
        end
    end)
end

RdysCrateTracker.nameplateFrame = CreateFrame("Frame")
RdysCrateTracker.nameplateFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
RdysCrateTracker.nameplateFrame:SetScript("OnEvent", OnHealthDetection)

-------------------------------------------------
-- Zone Reset Handler
-------------------------------------------------
local shardWatcher = CreateFrame("Frame")
--shardWatcher:RegisterEvent("ZONE_CHANGED")
shardWatcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
shardWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")

shardWatcher:SetScript("OnEvent", function()
    RdysCrateTracker:HandleZoneShardTransition(1.5, 1)
end)





local function announceCrate(crateInfo)
    if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end

    local self = self or RdysCrateTracker
    if type(self.crateIsDupe) == "function" and self.crateIsDupe(crateInfo) then
        if self.db.profile.debugged then print("|cffaaaaaa[RCT]|r crateSpotted ignored (dupe).") end
        return
    end


    if RdysCrateTracker:shouldAnnounce(crateInfo) and RdysCrateTracker.checkDelta(crateInfo) then
        if not RdysCrateTracker.warningFrame then
            RdysCrateTracker.warningFrame = CreateFrame("MessageFrame", nil, UIParent)
            RdysCrateTracker.warningFrame:SetSize(300, 100)
            RdysCrateTracker.warningFrame:SetPoint("CENTER", UIParent, "CENTER")
            RdysCrateTracker.warningFrame:SetFontObject(GameFontNormalLarge)
            RdysCrateTracker.warningFrame:SetInsertMode("TOP")
            RdysCrateTracker.warningFrame:SetFading(true)
        end
        local message = (L["CRATE_ALERT_MESSAGE"] and L["CRATE_ALERT_MESSAGE"]:format(crateInfo.zoneName, crateInfo.shardhist or "N/A")) or string.format("Hated Gaming Crate Alert! Flying in %s - Shard = %s", crateInfo.zoneName, crateInfo.shardhist or "N/A")
        if RdysCrateTracker.db.profile.warningenable then
            RdysCrateTracker.warningFrame:AddMessage(message)
        end
        if RdysCrateTracker.db.profile.warningsoundEnabled then
            PlaySoundFile("Interface\\AddOns\\RCT\\Media\\cratealert.ogg", "Dialog")
        end
        -- Ensure the same zone is only announced once within 30 seconds
        if not RdysCrateTracker.db.profile.lastAnnounced then
            RdysCrateTracker.db.profile.lastAnnounced = {}
        end
        local lastAnnouncedTime = RdysCrateTracker.db.profile.lastAnnounced[crateInfo.zoneID]
        local currentTime = GetServerTime()

        if not lastAnnouncedTime or (currentTime - lastAnnouncedTime > 420) then
            RdysCrateTracker.db.profile.lastAnnounced[crateInfo.zoneID] = currentTime
            if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
                SendChatMessage("Hated Gaming - War Crate Alert! Flying in " .. crateInfo.zoneName .. " - Shard: " .. (crateInfo.shardhist or "N/A"), "RAID_WARNING")
            end
        else
        end
    end
end
RdysCrateTracker.announceCrate = announceCrate








------------------------------------------------------------
-- Encode / Decode helpers
------------------------------------------------------------
local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub("LibDeflate")
RdysCrateTracker.MODERN_PREFIX = "RCT"
local MODERN_PREFIX = RdysCrateTracker.MODERN_PREFIX
RdysCrateTracker.TOKEN_TTL = 300
local TOKEN_TTL = RdysCrateTracker.TOKEN_TTL


local function Wire_Encode(tbl)
        if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    local serialized = AceSerializer:Serialize(tbl)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)
    return encoded
end

local function Wire_Decode(str)
        if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    if not str then return false, nil end
    local decoded = LibDeflate:DecodeForPrint(str)
    if not decoded then return false, nil end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return false, nil end
    local ok, data = AceSerializer:Deserialize(decompressed)
    if not ok then return false, nil end
    return true, data
end


------------------------------------------------------------
-- Raid token generation and validation
------------------------------------------------------------
function RdysCrateTracker:GenerateRaidToken()
    if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end

    local newToken = tostring(time()) .. tostring(math.random(100000, 999999))
    self.raidToken = newToken
    self.raidTokenExpiry = GetServerTime() + TOKEN_TTL


    self.secureRoster = {}

    if self.db.profile.debugged then
        print("|cff33ff99[RCT]|r Generated raid token:", newToken)
    end
end

function RdysCrateTracker:HasValidRaidToken(token)
        if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    if not token or token ~= self.raidToken then return false end
    if not self.raidTokenExpiry then return false end
    return GetServerTime() < self.raidTokenExpiry
end

function RdysCrateTracker:OnToken(msg, sender)
        if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    local token = msg:match("^TOKEN~([%w_-]+)$")
    if not token then return end

    local leader = self:GetPartyLeader()
    if sender ~= leader then
        if self.db.profile.debugged then
            print("|cffff0000[RCT]|r Ignored TOKEN (not from leader):", sender)
        end
        return
    end

    self.secureRoster = {}
    self.raidToken = token
    self.raidTokenOwner = sender
    self.raidTokenExpiry = GetServerTime() + TOKEN_TTL

    AceComm:SendCommMessage(MODERN_PREFIX, ("TOKEN_ACK~%s"):format(token), "WHISPER", sender)
    if self.db.profile.debugged then
        print("|cff33ff99[RCT]|r Received token from leader:", sender)
    end
end

function RdysCrateTracker:OnTokenAck(msg, sender)
    if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end

    local token = msg:match("^TOKEN_ACK~([%w_-]+)$")
    if not token then return end
    if token ~= self.raidToken then return end

    self.secureRoster = self.secureRoster or {}

    self.secureRoster[sender] = true

    if self.db.profile.debugged then
        print("|cff33ff99[RCT]|r Token ACK from", sender)
    end
end

local function genCrateInfo(method, sender)
    local profile = RdysCrateTracker.db and RdysCrateTracker.db.profile
    if not profile or not profile.enable or profile.notPvp then
        return nil
    end

    -- ALWAYS pull zone fresh from C_Map rather than relying on stored values
    local zid = C_Map.GetBestMapForUnit("player")
    if not zid then return nil end

    -- Normalize root zone
    local zoneID = RdysCrateTracker:NormalizeZoneID(zid)
    if not zoneID then return nil end

    local zoneInfo = C_Map.GetMapInfo(zoneID)
    if not zoneInfo then return nil end

    local parent = zoneInfo.parentMapID or 0
    local parentInfo = parent > 0 and C_Map.GetMapInfo(parent)

    local crate = {
        type           = "SPOT",
        method         = method or "Manual",
        ts             = GetServerTime(),
        zoneID         = zoneID,
        zoneParentID   = parent,
        zoneName       = zoneInfo.name or "Unknown",
        zoneParentName = parentInfo and parentInfo.name or "Unknown",
        vignetteGUID   = RdysCrateTracker.zoneUID or 0,
        spotter        = UnitName("player") or "Unknown",
        -- Only use ShardID if it was read from this same zone (prevent cross-zone shard bleed)
        shardhist      = (RdysCrateTracker._shardZone == zoneID and RdysCrateTracker.ShardID) or "N/A",
        sender         = sender or UnitName("player") or "Unknown",
    }


    for k, v in pairs(crate) do
        local t = type(v)
        if t ~= "string" and t ~= "number" and t ~= "boolean" and v ~= nil then
            crate[k] = tostring(v)
        end
    end

    if RdysCrateTracker.debugged then
        print(string.format(
            "|cff99ccff[RCT]|r genCrateInfo: method=%s zone=%s parent=%s shard=%s",
            crate.method, crate.zoneID, crate.zoneParentID, crate.shardhist
        ))
    end

    return crate
end

RdysCrateTracker.genCrateInfo = genCrateInfo

------------------------------------------------------------
-- Core wire send
------------------------------------------------------------
function RdysCrateTracker:Wire_HMAC(token, payload)
        if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    if not token or not payload then return "0" end
    local LibDeflate = LibStub("LibDeflate")
    local hash = LibDeflate:Adler32(token .. payload)
    return string.format("%08x", hash)
end

function RdysCrateTracker:Wire_Send(tag, data)
    if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end

    -- Prevent sending while in blocked instances or after Warmode timestamp (use global-safe call)
    if (RdysCrateTracker and ((RdysCrateTracker.IsBlockedInstance and RdysCrateTracker:IsBlockedInstance()) or (RdysCrateTracker.WarmodeTS and RdysCrateTracker:WarmodeTS())))
    or (self and ((type(self.IsBlockedInstance) == "function" and self:IsBlockedInstance()) or (type(self.WarmodeTS) == "function" and self:WarmodeTS()))) then
        if self.db and self.db.profile and self.db.profile.debugged then
            print("|cffff9966[RCT]|r [Wire_Send] In blocked instance or warmode period; aborting send.")
        end
        return
    end

    local inRaid  = IsInRaid()
    local inGroup = IsInGroup()
    local channel = (inRaid and "RAID") or (inGroup and "PARTY") or nil
    if not channel then return end


    if not self:HasValidRaidToken(self.raidToken) then
        if UnitIsGroupLeader("player") then
            self:GenerateRaidToken()
        end
        return
    end

    local payload = Wire_Encode(data)
    if not payload then return end

    local sig = self:Wire_HMAC(self.raidToken, payload)
    local msg = string.format("%s~%s~%s~%s", self.raidToken, tag, payload, sig)

    ---------------------------------------------------------------------
    -- Level ≤ 20 → whisper leader only (no group broadcast)
    ---------------------------------------------------------------------
    local playerLevel = UnitLevel("player")
    if playerLevel <= 20 then
        local leaderName

        if inRaid then
            -- Find raid leader by rank
            for i = 1, GetNumGroupMembers() do
                local name, rank = GetRaidRosterInfo(i)
                if rank == 2 then
                    leaderName = name
                    break
                end
            end
        elseif inGroup then
            -- Find party leader reliably
            for i = 1, GetNumSubgroupMembers() do
                local unit = "party" .. i
                if UnitIsGroupLeader(unit) then
                    leaderName = UnitName(unit)
                    break
                end
            end
        end

        if leaderName then
            AceComm:SendCommMessage(MODERN_PREFIX, msg, "WHISPER", leaderName)
            if self.db.profile.debugged then
                print(string.format("|cff33ff99[RCT]|r [Wire_Send] Lvl ≤ 20 → Whispered leader '%s'", leaderName))
            end
        else
            if self.db.profile.debugged then
                print("|cffff0000[RCT]|r [Wire_Send] Lvl ≤ 20 but no leader found")
            end
        end
        return
    end

    ---------------------------------------------------------------------
    ---------------------------------------------------------------------
    AceComm:SendCommMessage(MODERN_PREFIX, msg, channel)
    if self.db.profile.debugged then
        print(string.format("|cff33ff99[RCT]|r [Wire_Send] Sent %s via %s", tag, channel))
    end
end




------------------------------------------------------------
------------------------------------------------------------
function RdysCrateTracker:OnCommReceived(prefix, msg, dist, sender)
    if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    if prefix ~= MODERN_PREFIX then return end

        -- Never process our own comms
    if sender == UnitName("player") then
        return
    end

    -- Group-only restriction (prevents spoof / non-group spam)
    if sender and sender ~= UnitName("player") then
        if not UnitInParty(sender) and not UnitInRaid(sender) then
            return
        end
    end
    ------------------------------------------------------------
    -- CONTROL: TOKEN REQUEST (followers → leader)
    ------------------------------------------------------------
    if msg == "TOKEN_REQ" then
        self:OnTokenReq(sender)
        return
    end
    ------------------------------------------------------------
    -- Token handshakes
    ------------------------------------------------------------
    if msg:match("^TOKEN~") then self:OnToken(msg, sender) return end
    if msg:match("^TOKEN_ACK~") then self:OnTokenAck(msg, sender) return end

    ------------------------------------------------------------
    -- Parse the general message pattern:
    ------------------------------------------------------------
    local token, tag, encoded, sig = msg:match("^([%w_-]+)~([A-Z_]+)~([^~]+)~?(.*)$")
    if not token or not tag or not encoded then return end
    ------------------------------------------------------------
    -- Verify active raid token
    ------------------------------------------------------------
    if not self:HasValidRaidToken(token) then
        if self.db.profile.debugged then
            print("|cffff0000[RCT]|r Dropped (bad token) from", sender)
        end
        return
    end
    ------------------------------------------------------------
    -- Verify integrity signature (HMAC)
    ------------------------------------------------------------
    if not sig or sig == "" then return end
    local expected = self:Wire_HMAC(token, encoded)
    if sig ~= expected then
        if self.db.profile.debugged then
            print("|cffff0000[RCT]|r Dropped (bad sig) from", sender)
        end
        return
    end
    -----------------------------------------------------------
    -- REQUEST (ask leader to broadcast sync)
    ------------------------------------------------------------
    if tag == "REQUEST" then
        if UnitIsGroupLeader("player") then
            C_Timer.After(0.5, function() self:BroadcastSync() end)
        end
        return
    end

    ------------------------------------------------------------
    -- ALERT (broadcast from leader)
    ------------------------------------------------------------
    if tag == "ALERT" then
        local ok, alertData = Wire_Decode(encoded)
        if ok and type(alertData) == "table" then
            RdysCrateTracker:PlayGlobalCrateAlert(alertData)
        end
        return
    end

    ------------------------------------------------------------
    -- DATA (single crate spot)
    ------------------------------------------------------------
    if tag == "DATA" then
        local ok, crate = Wire_Decode(encoded)
        if not ok or type(crate) ~= "table" then
            if self.db.profile.debugged then
                print("|cffff0000[RCT]|r DATA decode failed from", sender)
            end
            return
        end
        self:ProcessCrate(crate, crate.type or "SPOT", sender)
        return
    end

    ------------------------------------------------------------
    -- SYNC (batch crate data)
    ------------------------------------------------------------
    if tag == "SYNC" then
        local ok, batch = Wire_Decode(encoded)
        if not ok or type(batch) ~= "table" then
            if self.db.profile.debugged then
                print("|cffff0000[RCT]|r SYNC decode failed from", sender)
            end
            return
        end
        for i = 1, #batch do
            local c = batch[i]
            if type(c) == "table" then
                self:ProcessCrate(c, "SYNC", sender)
            end
        end
        return
    end

    ------------------------------------------------------------
    -- DELETE_ALL (leader only)
    ------------------------------------------------------------
    if tag == "DELETE_ALL" then
        local ok, deleteInfo = Wire_Decode(encoded)
        if not ok or type(deleteInfo) ~= "table" then
            if self.db.profile.debugged then
                print("|cffff0000[RCT]|r DELETE_ALL decode failed from", sender)
            end
            return
        end

        -- Validate sender is current raid/party leader
        local isLeader = false

        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do
                local name, rank = GetRaidRosterInfo(i)
                if name == sender and rank == 2 then
                    isLeader = true
                    break
                end
            end
        elseif IsInGroup() then
            for i = 1, GetNumSubgroupMembers() do
                local unitID = "party" .. i
                if UnitName(unitID) == sender and UnitIsGroupLeader(unitID) then
                    isLeader = true
                    break
                end
            end
            if sender == UnitName("player") and UnitIsGroupLeader("player") then
                isLeader = true
            end
        end

        if not isLeader then
            if self.db.profile.debugged then
                print("|cffff0000[RCT]|r DELETE_ALL ignored: not from raid leader (" .. tostring(sender) .. ")")
            end
            return
        end

        -- Leader never wipes their own DB
        if UnitIsGroupLeader("player") then
            if self.db.profile.debugged then
                print("|cff55ff55[RCT]|r Leader received own DELETE_ALL; keeping crateDB.")
            end
            return
        end

        -- Wipe local crateDB for followers
        self.db.profile.crateDB = {}
        self.recent = {}

        if self.db.profile.debugged then
            print("|cff33ff99[RCT]|r Crate data wiped by leader command from " .. tostring(sender))
        end

        if type(self.refreshTimers) == "function" then
            self:refreshTimers()
        end

        return
    end
end

function RdysCrateTracker:crateSpotted(method, sender)
    if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    if not self.db or not self.db.profile or not self.db.profile.enable then
        if self.db.profile.debugged then print("|cffff0000[RCT]|r crateSpotted aborted: DB not ready") end
        return
    end
    if self.db.profile.notPvp then
        if self.db.profile.debugged then print("|cffff0000[RCT]|r crateSpotted aborted: PvP disabled") end
        return
    end

    sender = sender or UnitName("player")
    method = method or "Manual"

    if not self.ShardID or self.ShardID == "N/A" then
        if self.db.profile.debugged then print("|cffff9966[RCT]|r crateSpotted aborted: no ShardID.") end
        return
    end
    
    if self.db.profile.debugged then print("|cff33ff99[RCT]|r crateSpotted invoked by", sender, "method", method) end
    -- Build crate info
    local info = genCrateInfo(method, sender)
    if not info then
        if self.db.profile.debugged then print("|cffff0000[RCT]|r genCrateInfo failed") end
        return
    end

    -- Prevent dupes
    if type(self.crateIsDupe) == "function" and self.crateIsDupe(info) then
        if self.db.profile.debugged then print("|cffaaaaaa[RCT]|r crateSpotted ignored (dupe).") end
        return
    end

    if ShouldDelayCrossZoneShardSpot(info, sender) then
        return
    end

    -- Always process locally (solo-safe)
    self:ProcessCrate(info, "SPOT", sender)
        
    -- Only attempt a network send if grouped
    local channel = (IsInRaid() and "RAID") or (IsInGroup() and "PARTY") or nil
    if not channel then
        if self.db.profile.debugged then print("|cffaaaaaa[RCT]|r Solo mode: crate processed locally, no broadcast.") end
        return
    end

    -- Ensure token exists/valid
    if not self:HasValidRaidToken(self.raidToken) then
        if (RdysCrateTracker and ((RdysCrateTracker.IsBlockedInstance and RdysCrateTracker:IsBlockedInstance()) or (RdysCrateTracker.WarmodeTS and RdysCrateTracker:WarmodeTS())))
        or (self and ((type(self.IsBlockedInstance) == "function" and self:IsBlockedInstance()) or (type(self.WarmodeTS) == "function" and self:WarmodeTS()))) then
            if self.db.profile.debugged then
                print("|cffff9966[RCT]|r In blocked instance or warmode period; cannot generate/request raid token.")
            end
            return
        end
        if UnitIsGroupLeader("player") then
            self:GenerateRaidToken()
        else
            -- follower: ask leader for token (limited to 5 attempts, resets every 3 minutes)
            self.tokenRequestCount = (self.tokenRequestCount or 0) + 1

            if not self.tokenRequestTimer then
                C_Timer.After(180, function()
                    self.tokenRequestCount = 0
                    self.tokenRequestTimer = nil
                    if self.db.profile.debugged then
                        print("|cff33ff99[RCT]|r Token request limiter reset after 3 minutes.")
                    end
                end)
                self.tokenRequestTimer = true
            end

            if self.tokenRequestCount <= 2 then
                AceComm:SendCommMessage(MODERN_PREFIX, "TOKEN_REQ", channel)
                if self.db.profile.debugged then
                    print(string.format("|cffff9966[RCT]|r No raid token yet; requested from leader (attempt %d/5).", self.tokenRequestCount))
                end
            elseif self.tokenRequestCount == 3 then
                if self.db.profile.debugged then
                    print(L["RAID_TOKEN_NOT_RECEIVED"] and L["RAID_TOKEN_NOT_RECEIVED"]:format(5, 3) or "|cffff0000[RCT]|r Raid token not received after 5 attempts; further requests suppressed (3 min cooldown).")
                end
            end
            return
        end
    end


    -- Use the local Wire_Send helper with the TAG your receiver handles: "DATA"
    if self.Wire_Send then
        self:Wire_Send("DATA", info)
        -- Optional: leader sends ALERT if crate qualifies for global announce
    if UnitIsGroupLeader("player") and type(self.shouldAnnounce) == "function" then
        if self:shouldAnnounce(info) then
            local alertPayload = {
            zoneName = info.zoneName,
            shard = info.shardhist or "N/A",
            ts = GetServerTime(),
            zoneID = info.zoneID,
            parentID = info.zoneParentID,
        }
        self:Wire_Send("ALERT", alertPayload)
                if self.db.profile.debugged then
                      print("|cff33ff99[RCT]|r Broadcasted ALERT for zone:", alertPayload.zoneName)
                 end
         end
    end

        if self.db.profile.debugged then print("|cff33ff99[RCT]|r Sent SPOT crate via", channel) end
    else
        print("|cffff0000[RCT]|r Wire_Send missing (make sure it's a local function above this).")
    end
end









-----------------------------------------------------------
-- Sync request (followers)
------------------------------------------------------------
function RdysCrateTracker:RequestSync()
            if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    if not (IsInRaid() or IsInGroup()) then return end
    if not self.raidToken then
        if UnitIsGroupLeader("player") then self:GenerateRaidToken() end
        return
    end
    self:Wire_Send("REQUEST", { who = UnitName("player"), ts = GetServerTime() })
end

------------------------------------------------------------
-- Leader broadcast (full db snapshot)
------------------------------------------------------------
function RdysCrateTracker:BroadcastSync()
            if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    self = self or RdysCrateTracker
    if not UnitIsGroupLeader("player") then return end
    if not self.raidToken then self:GenerateRaidToken() end
    if not self.raidToken then return end

    local batch = {}
    if self.recent and type(self.recent) == "table" and #self.recent > 0 then
        for i = 1, #self.recent do
            batch[#batch+1] = self.recent[i]
        end
    else
        for _, v in pairs(self.db.profile.crateDB or {}) do
            batch[#batch+1] = v
        end
    end

    if self.db and self.db.profile and self.db.profile.debugged then
        print("|cff33ff99[RCT]|r BroadcastSync preparing batch size:", #batch)
    end

    if #batch == 0 then
        if self.db.profile.debugged then
            print("|cffff9966[RCT]|r BroadcastSync aborted (empty batch)")
        end
        return
    end

    -- Optional: split if batch too large for AceComm
    local MAX_PER_PACKET = 200
    if #batch > MAX_PER_PACKET then
        local chunk = {}
        for i = 1, #batch do
            chunk[#chunk+1] = batch[i]
            if #chunk >= MAX_PER_PACKET then
                self:Wire_Send("SYNC", chunk)
                if self.db.profile.debugged then
                    print("|cff33ff99[RCT]|r Broadcasted partial SYNC chunk of", #chunk)
                end
                chunk = {}
            end
        end
        if #chunk > 0 then
            self:Wire_Send("SYNC", chunk)
            if self.db.profile.debugged then
                print("|cff33ff99[RCT]|r Broadcasted final SYNC chunk of", #chunk)
            end
        end
    else
        self:Wire_Send("SYNC", batch)
        if self.db and self.db.profile and self.db.profile.debugged then
            print("|cff33ff99[RCT]|r BroadcastSync sent full SYNC batch:", #batch)
        end
    end
end

------------------------------------------------------------
-- Enhanced recordCrate: trace, validate, persist
------------------------------------------------------------
function RdysCrateTracker:recordCrate(crateInfo, sender)
    --------------------------------------------------------------------
    -- BASIC SAFETY
    --------------------------------------------------------------------
    local profile = self.db and self.db.profile
    if not profile or not profile.enable then
        if profile and profile.debugged then
            print("|cffff0000[RCT]|r recordCrate aborted: DB not ready")
        end
        return
    end

    if profile.notPvp then
        if profile.debugged then
            print("|cffff0000[RCT]|r recordCrate aborted: PvP disabled")
        end
        return
    end

    if type(crateInfo) ~= "table" or not crateInfo.zoneID then
        if profile.debugged then
            print("|cffff0000[RCT]|r recordCrate aborted: invalid crateInfo")
        end
        return
    end

    --------------------------------------------------------------------
    -- NORMALIZE ZONE (core of the new system)
    --------------------------------------------------------------------
    local rawZoneID = tonumber(crateInfo.zoneID)
    local nz        = self:NormalizeZoneID(rawZoneID)

    if not nz then
        if profile.debugged then
            print("|cffff0000[RCT]|r recordCrate aborted: invalid zone normalization ("..tostring(rawZoneID)..")")
        end
        return
    end

    crateInfo.rawZoneID = rawZoneID
    crateInfo.zoneID    = nz

    --------------------------------------------------------------------
    -- INITIALIZE DB / ZONE ENTRY
    --------------------------------------------------------------------
    profile.crateDB = profile.crateDB or {}
    local zoneKey   = nz

    local existing = profile.crateDB[zoneKey]
    if not existing then
        existing = {}
        profile.crateDB[zoneKey] = existing
    end

    --------------------------------------------------------------------
    -- DUPE DETECTION (use your new zoneID-based dupe system)
    --------------------------------------------------------------------
    if type(self.crateIsDupe) == "function" and self.crateIsDupe(crateInfo) then
        if profile.debugged then
            print(string.format(
                "|cffaaaaaa[RCT]|r Skipped dupe crate in zone %d",
                zoneKey
            ))
        end
        return
    end

    --------------------------------------------------------------------
    -- SAME-SHARD WITHIN RESET WINDOW (prevent re-recording before 400s)
    --------------------------------------------------------------------
    local incomingShard = (crateInfo.shardhist ~= "N/A" and crateInfo.shardhist) or self.ShardID
    if existing.ts and existing.shardhist
       and existing.shardhist == incomingShard
       and (GetServerTime() - existing.ts) < 400
    then
        if profile.debugged then
            print(string.format(
                "|cffaaaaaa[RCT]|r recordCrate: same shard (%s) within 400s in zone %d, skipping overwrite",
                tostring(incomingShard), zoneKey
            ))
        end
        return
    end

    --------------------------------------------------------------------
    -- ZONE FILTERING (zoneID-only)
    --------------------------------------------------------------------
    if not self:shouldTrack(nz) then
        if profile.debugged then
            print("|cffff8800[RCT]|r Ignored crate in untracked zone: "..tostring(nz))
        end
        return
    end

    --------------------------------------------------------------------
    -- STORE ALL FIELDS SAFELY
    --------------------------------------------------------------------
    existing.ts           = crateInfo.ts or GetServerTime()
    existing.zoneID       = nz
    existing.rawZoneID    = rawZoneID

    -- Parent ID is stored ONLY as metadata (never used in logic)
    existing.zoneParentID = crateInfo.zoneParentID or 0
    existing.zoneParentName = crateInfo.zoneParentName or "Unknown"

    existing.spotter      = crateInfo.spotter or sender or UnitName("player")
    -- Only fall back to live ShardID if it was read from this same zone
    local liveShardForZone = (self._shardZone == nz and self.ShardID) or nil
    existing.shardhist    = (crateInfo.shardhist ~= "N/A" and crateInfo.shardhist)
                            or liveShardForZone or "UNKNOWN"
    existing.method       = crateInfo.method or "Unknown"
    existing.sender       = sender
    existing.token        = self.raidToken or "none"

    if profile.debugged then
        print(string.format(
            "|cff00ff00[RCT]|r Recorded crate: NZ=%d RAW=%d PARENT=%d SHARD=%s spot=%s sender=%s",
            nz, rawZoneID, existing.zoneParentID,
            tostring(existing.shardhist),
            tostring(existing.spotter),
            tostring(sender)
        ))
    end

    --------------------------------------------------------------------
    -- CALLBACKS (refresh timers + hook)
    --------------------------------------------------------------------
    if type(self.refreshTimers) == "function" then
        self:refreshTimers()
        if profile.debugged then
            print("|cff33ff99[RCT]|r Timers refreshed after recordCrate")
        end
    end

    if type(self.OnCrateRecorded) == "function" then
        self:OnCrateRecorded(existing, sender)
    end
end



-----------------------------------------------------------
-- Process received data (called by OnCommReceived)
------------------------------------------------------------
-----------------------------------------------------------
-- Process received crate data (from comms)
------------------------------------------------------------
function RdysCrateTracker:ProcessCrate(entry, mType, sender)
            if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    if not entry or type(entry) ~= "table" then return end

    mType = mType or "CRATE"
    sender = sender or "unknown"

    -- SYNC bypass: allow missing shardhist on trusted sync data
    if (not entry.shardhist or entry.shardhist == "N/A") and mType ~= "SYNC" then
        if self.db.profile.debugged then
            print("|cffff9966[RCT]|r Ignored (no valid shardhist) from", sender)
        end
        return
    end

    -- Dispatch behavior
if mType == "SPOT" then
    local normalizedZone = entry.zoneID and self:NormalizeZoneID(entry.zoneID)
    local conflictZoneID = normalizedZone and FindRecentCrossZoneShardConflict(normalizedZone, entry.shardhist)

    -- Followers can briefly see the neighboring-zone crate in fringe areas.
    -- Do not let a shared SPOT overwrite/duplicate the same shard into a second zone.
    if sender ~= UnitName("player") and conflictZoneID and conflictZoneID ~= normalizedZone then
        if self.db.profile.debugged then
            print(string.format(
                "|cffff9966[RCT]|r Ignored shared SPOT from %s for zone %s on shard %s; same shard already exists in zone %s.",
                tostring(sender),
                tostring(normalizedZone or entry.zoneID or "?"),
                tostring(entry.shardhist or "?"),
                tostring(conflictZoneID)
            ))
        end
        return
    end

    -- Prevent re-announcing the same zone/shard too soon
    RdysCrateTracker.lastSpotAlert = RdysCrateTracker.lastSpotAlert or {}
    local key = string.format("%s-%s", entry.zoneID or "?", entry.shardhist or "?")
    local now = GetTime()
    local last = RdysCrateTracker.lastSpotAlert[key]

    if not last or (now - last) > 20 then
        RdysCrateTracker.lastSpotAlert[key] = now
        if type(RdysCrateTracker.announceCrate) == "function" then
            RdysCrateTracker.announceCrate(entry)
        end
    else
        if self.db.profile.debugged then
            print("|cff33ff99[RCT]|r Skipped duplicate SPOT announce for", key)
        end
    end

    if type(self.recordCrate) == "function" then
        self:recordCrate(entry, sender)
    end

    elseif mType == "CRATE" or mType == "UPDATE" or mType == "LEGACY" then
        if type(self.recordCrate) == "function" then self:recordCrate(entry, sender) end
    elseif mType == "REQUEST" and UnitIsGroupLeader("player") then
        self:BroadcastSync()
    elseif mType == "SYNC" then
        -- Received from leader: record crates directly
        if type(self.recordCrate) == "function" then self:recordCrate(entry, sender) end
    end

    if type(self.refreshTimers) == "function" then
        self:refreshTimers()
    end

    if self.db and self.db.profile and self.db.profile.debugged then
        print(string.format("|cff55ff55[RCT]|r Processed %s from %s (zone %s, shard %s)",
            mType, sender,
            tostring(entry.zoneID or "?"),
            tostring(entry.shardhist or "?")))
    end
end
------------------------------------------------------------
------------------------------------------------------------
-- Token handling
------------------------------------------------------------

function RdysCrateTracker:OnTokenReq(sender)
            if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    if not UnitIsGroupLeader("player") then return end
    if not self.raidToken then self:GenerateRaidToken() end
    if not self.raidToken then return end
    local channel = (IsInRaid() and "RAID") or (IsInGroup() and "PARTY")
    if channel then
        -- Avoid broadcasting tokens from inside blocked instances or after Warmode timestamp
        if (RdysCrateTracker and ((RdysCrateTracker.IsBlockedInstance and RdysCrateTracker:IsBlockedInstance()) or (RdysCrateTracker.WarmodeTS and RdysCrateTracker:WarmodeTS())))
        or (self and ((type(self.IsBlockedInstance) == "function" and self:IsBlockedInstance()) or (type(self.WarmodeTS) == "function" and self:WarmodeTS()))) then
            if self.db and self.db.profile and self.db.profile.debugged then
                print("|cffff9966[RCT]|r In blocked instance or warmode period; not sending TOKEN to group.")
            end
            return
        end

        AceComm:SendCommMessage(MODERN_PREFIX, ("TOKEN~%s"):format(self.raidToken), channel)
        if self.db.profile.debugged then
            print("|cff33ff99[RCT]|r Sent TOKEN to", sender)
        end
    end
end


------------------------------------------------------------
-- Group event: roster change or world entry
------------------------------------------------------------
local commFrame = CreateFrame("Frame")
commFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
commFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
commFrame:SetScript("OnEvent", function(_, evt)
    if evt ~= "PLAYER_ENTERING_WORLD" and evt ~= "GROUP_ROSTER_UPDATE" then return end

    local self = RdysCrateTracker
    local channel = (IsInRaid() and "RAID") or (IsInGroup() and "PARTY")
    if not channel then return end

    if UnitIsGroupLeader("player") then
        if not self:HasValidRaidToken(self.raidToken) then
            self:GenerateRaidToken()
            if self.db.profile.debugged then
                print("|cff33ff99[RCT]|r Minted new raid token (roster changed)")
            end
        end

                if self.raidToken then
            local currentTime = GetServerTime()
            self.lastTokenBroadcast = self.lastTokenBroadcast or 0
            if (currentTime - self.lastTokenBroadcast) >= 3 then
                -- Global-safe guard: blocked instances or warmode timestamp
                if (RdysCrateTracker and ((RdysCrateTracker.IsBlockedInstance and RdysCrateTracker:IsBlockedInstance()) or (RdysCrateTracker.WarmodeTS and RdysCrateTracker:WarmodeTS())))
                or (self and ((type(self.IsBlockedInstance) == "function" and self:IsBlockedInstance()) or (type(self.WarmodeTS) == "function" and self:WarmodeTS()))) then
                    if self.db and self.db.profile and self.db.profile.debugged then
                        print("|cffff9966[RCT]|r In blocked instance or warmode period; cannot broadcast raid token.")
                    end
                else
                    AceComm:SendCommMessage(MODERN_PREFIX, ("TOKEN~%s"):format(self.raidToken), channel)
                    self.lastTokenBroadcast = currentTime
                end
            end
        end
    else
                if (RdysCrateTracker and ((RdysCrateTracker.IsBlockedInstance and RdysCrateTracker:IsBlockedInstance()) or (RdysCrateTracker.WarmodeTS and RdysCrateTracker:WarmodeTS())))
            or (self and ((type(self.IsBlockedInstance) == "function" and self:IsBlockedInstance()) or (type(self.WarmodeTS) == "function" and self:WarmodeTS()))) then
            if self.db.profile.debugged then
                print("|cffff9966[RCT]|r In blocked instance or warmode period; cannot generate/request raid token.")
            end
            return
        end
        if (not self.raidToken) or (not self:HasValidRaidToken(self.raidToken)) then
            AceComm:SendCommMessage(MODERN_PREFIX, "TOKEN_REQ", channel)
            if self.db.profile.debugged then
                print("|cffff9966[RCT]|r Requested raid token from leader (roster changed)")
            end
        end
    end
end)

------------------------------------------------------------
-- Receiver
------------------------------------------------------------
AceComm:RegisterComm(MODERN_PREFIX, function(prefix, message, dist, sender)
    RdysCrateTracker:OnCommReceived(prefix, message, dist, sender)
end)
------------------------------------------------------------

function RdysCrateTracker:sendAndDeleteCrate()
    if not RdysCrateTracker.db.profile.enable or RdysCrateTracker.db.profile.notPvp then return end
    if not UnitIsGroupLeader("player") then return end

    if not RdysCrateTracker.raidToken then
        RdysCrateTracker:GenerateRaidToken()
    end

    self:Wire_Send("DELETE_ALL", {
        who = UnitName("player"),
        ts  = GetServerTime(),
    })

    if self.db.profile.debugged then
        print("|cff55ff55[RCT]|r Sent DELETE_ALL command to group")
    end
end

local function ProfileFlag(profile, key, defaultValue)
    local v = profile and profile[key]
    if v == nil then return defaultValue end
    return v
end


function RdysCrateTracker:shouldAnnounce(crateInfo)
    local profile = self.db.profile

    -- 1. Global disables
    if not profile.enable then return false end
    if profile.notPvp then return false end

    -- 2. Developer mode: always announce
    if profile.Devmode then return true end
    if not crateInfo or not crateInfo.zoneID then return false end

    -- Normalize the zoneID
    local nz = self:NormalizeZoneID(crateInfo.zoneID)
    if not nz then return false end

    --------------------------------------------------------------------
    -- EXPANSION ZONE TABLES (numeric only, locale-safe)
    --------------------------------------------------------------------

    -- Dragonflight (DF)
    local DF_Zones = {
        [2022] = true, [2023] = true, [2024] = true, [2025] = true,
        [2133] = true, [2151] = true, [2200] = true,
    }

    -- The War Within (TWW) — EXCLUDES Undermine
    local TWW_Zones = {
        [2248] = true, -- Isle of Dorn
        [2214] = true, -- Ringing Deeps
        [2215] = true, -- Hallowfall
        [2255] = true, -- Azj-Kahet
    }

    -- Midnight
    local MID_Zones = {
        [2369] = true, -- Siren Isle
        [2371] = true, -- K'aresh
        [2405] = true, -- Voidstorm
        [2413] = true, -- Harandar
        [2395] = true, -- Eversong Woods
        [2437] = true, -- Zul'Aman
        [2444] = true, -- Slayer's Rise
        [2537] = true, -- Quel'thalas
    }

    --------------------------------------------------------------------
    -- ANNOUNCE BY EXPANSION
    --------------------------------------------------------------------

    if DF_Zones[nz] then
        return ProfileFlag(profile, "zdrgfAnnounce", true)
    end

    if TWW_Zones[nz] then
        return ProfileFlag(profile, "ztwwAnnounce", true)
    end

    if MID_Zones[nz] then
        return ProfileFlag(profile, "MidAnnounce", true)
    end

    --------------------------------------------------------------------
    -- SPECIAL CASE: Undermine (unique island, zoneID = 2346)
    --------------------------------------------------------------------
    if nz == 2346 then
        return ProfileFlag(profile, "UMAnnounce", true)
    end

    --------------------------------------------------------------------
    -- DEFAULT: Unknown zones do not announce
    --------------------------------------------------------------------
    return false
end




function RdysCrateTracker:shouldTrack(zoneID)
    local profile = self.db.profile

    -- 1. Global disables
    if not profile.enable then return false end
    if profile.notPvp then return false end

    -- 2. Developer mode: track everything
    if profile.Devmode then return true end

    -- 3. Normalize zoneID for safe matching
    local nz = self:NormalizeZoneID(zoneID)
    if not nz then return false end

    --------------------------------------------------------------------
    -- EXPANSION ZONE TABLES (numeric only, locale-safe)
    --------------------------------------------------------------------

    -- Dragonflight
    local DF_Zones = {
        [2022] = true, [2023] = true, [2024] = true, [2025] = true,
        [2133] = true, [2151] = true, [2200] = true,
    }

    -- The War Within (EXCLUDES Undermine)
    local TWW_Zones = {
        [2248] = true, -- Isle of Dorn
        [2214] = true, -- Ringing Deeps
        [2215] = true, -- Hallowfall
        [2255] = true, -- Azj-Kahet
    }

    -- Midnight
    local MID_Zones = {
        [2369] = true, -- Siren Isle
        [2371] = true, -- K'aresh
        [2405] = true, -- Voidstorm
        [2413] = true, -- Harandar
        [2395] = true, -- Eversong Woods
        [2437] = true, -- Zul'Aman
        [2444] = true, -- Slayer's Rise
        [2537] = true, -- Quel'thalas
    }

    --------------------------------------------------------------------
    -- Tracking per expansion
    --------------------------------------------------------------------

    if DF_Zones[nz] then
        return ProfileFlag(profile, "zdrgfTrack", true)
    end

    if TWW_Zones[nz] then
        return ProfileFlag(profile, "ztwwTrack", true)
    end

    if MID_Zones[nz] then
        return ProfileFlag(profile, "MidTrack", true)
    end

    --------------------------------------------------------------------
    -- Special case: Undermine (zoneID = 2346)
    --------------------------------------------------------------------
    if nz == 2346 then
        return ProfileFlag(profile, "UMTrack", true)
    end

    --------------------------------------------------------------------
    -- Default behavior
    --------------------------------------------------------------------
    return true
end




function RdysCrateTracker:shouldWarn(zoneID)
    local profile = self.db.profile

    -- 1. Global disables
    if not profile.enable then return false end
    if profile.notPvp then return false end

    -- 2. Developer mode allows all warnings
    if profile.Devmode then return true end

    -- 3. Normalize zoneID (critical)
    local nz = self:NormalizeZoneID(zoneID)
    if not nz then return false end

    --------------------------------------------------------------------
    -- EXPANSION ZONE TABLES (numeric, locale-safe)
    --------------------------------------------------------------------

    -- Dragonflight
    local DF_Zones = {
        [2022] = true, [2023] = true, [2024] = true, [2025] = true,
        [2133] = true, [2151] = true, [2200] = true,
    }

    -- The War Within
    local TWW_Zones = {
        [2248] = true, -- Isle of Dorn
        [2214] = true, -- Ringing Deeps
        [2215] = true, -- Hallowfall
        [2255] = true, -- Azj-Kahet
    }

    -- Midnight
    local MID_Zones = {
        [2369] = true, -- Siren Isle
        [2371] = true, -- K'aresh
        [2405] = true, -- Voidstorm
        [2413] = true, -- Harandar
        [2395] = true, -- Eversong Woods
        [2437] = true, -- Zul'Aman
        [2444] = true, -- Slayer's Rise
        [2537] = true, -- Quel'thalas
    }

    --------------------------------------------------------------------
    -- WARNING PER EXPANSION
    --------------------------------------------------------------------

    if DF_Zones[nz] then
        return ProfileFlag(profile, "zdrgfWarn", true)
    end

    if TWW_Zones[nz] then
        return ProfileFlag(profile, "ztwwWarn", true)
    end

    if MID_Zones[nz] then
        return ProfileFlag(profile, "MidWarn", true)
    end

    --------------------------------------------------------------------
    -- SPECIAL CASE: Undermine (actual main zoneID = 2346)
    --------------------------------------------------------------------
    -- (Note: This must come BEFORE return true)
    if nz == 2346 then
        return ProfileFlag(profile, "UMWarn", true)
    end

    --------------------------------------------------------------------
    -- DEFAULT: Allow warnings for unclassified zones
    --------------------------------------------------------------------
    return true
end



local function warnCrate(crateInfo, curTime)
    if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    if not crateInfo or not crateInfo.zoneID then return end
    if RdysCrateTracker.db.profile.Devmode then return true end

    local self = RdysCrateTracker

    -- Normalize zone ID
    local nz = self:NormalizeZoneID(crateInfo.zoneID)
    if not nz then return end

    -- Fetch next spawn timestamp
    local nextTS = self.nextCrateTime(crateInfo, curTime)
    if not nextTS then return end

    ---------------------------------------------------------
    -- TIME UNTIL NEXT CRATE
    ---------------------------------------------------------
    local nextIn = nextTS - curTime

    -- Too far away — no warnings yet
    if nextIn > 1200 then
        return
    end

    ---------------------------------------------------------
    -- CRATE IS IMMINENT (20s threshold)
    ---------------------------------------------------------
    if nextIn <= 20 then
        -- Unique key per zoneID + spawn time
        self.alerted = self.alerted or {}
        local alertKey = string.format("%d_%d", nz, nextTS)

        if not self.alerted[alertKey] then
            -- First crate announcement
            if type(self.announceFirstCrate) == "function" then
                self:announceFirstCrate(crateInfo)
            end

            self.alerted[alertKey] = true

            if self.debugged then
                print(
                    "|cffff9900[RCT]|r " ..
                    (L["WARNING_CRATE_IMMINENT"] or "Warning crate imminent:") ..
                    " ZoneID=" .. tostring(nz)
                )
            end
        end
    end
end

RdysCrateTracker.warnCrate = warnCrate





-- Map pin helper
local function createMapPin(mapID, x, y, description)
            if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    if not mapID or not x or not y then return end
    if not C_Map.CanSetUserWaypointOnMap(mapID) then return end
    local position = CreateVector2D(x, y)
    local uiMapPoint = UiMapPoint.CreateFromCoordinates(mapID, position.x, position.y)
    C_Map.SetUserWaypoint(uiMapPoint)
end
RdysCrateTracker.createMapPin = createMapPin


local vignetteids = {
    [3689] = "Flying",
    [6068] = "Claimed",
    [6067] = "Claimed",
    [6069] = "plane-unknown1",
    [6070] = "plane-unknown2",
    [6071] = "plane-unknown2",
    [6072] = "Unbound Spoils",
    [290129] = "OBJ-ID1",
    [290135] = "OBJ-ID2",
    [135181] = "Alliance-Capped",
    [6066] = "On Ground",
    [2967] = "Falling To Ground"
}
RdysCrateTracker.vignetteids = vignetteids


local function GetZoneInfo()
    if not RdysCrateTracker.db.profile.enable then return nil end
    if RdysCrateTracker.db.profile.notPvp then return nil end

    -- Use normalized ID for ALL logic
    local zoneID = RdysCrateTracker.normalizedZoneID or RdysCrateTracker.currentZoneID
    if not zoneID then return nil end

    -- Normalize the zone ID (ensures phasing/layers all match)
    local nz = RdysCrateTracker:NormalizeZoneID(zoneID)
    if not nz then return nil end

    -- Main zone info
    local zoneInfo = C_Map.GetMapInfo(nz)
    local zoneName = zoneInfo and zoneInfo.name or "Unknown Zone"

    ------------------------------------------------------------
    -- Parent map info (METADATA ONLY — never used for logic)
    ------------------------------------------------------------
    local parentID   = zoneInfo and zoneInfo.parentMapID or 0
    local parentInfo = parentID and C_Map.GetMapInfo(parentID) or nil
    local parentName = parentInfo and parentInfo.name or "Unknown Parent"

    return {
        zoneID        = nz,         -- normalized, logic-safe
        zoneName      = zoneName,   -- localized name
        zoneParentID  = parentID,   -- metadata only
        zoneParentName= parentName, -- metadata only
    }
end

RdysCrateTracker.GetZoneInfo = GetZoneInfo


local function GetShardID(unitID)
    -- DO NOT parse GUIDs directly (Blizzard may return secret values)
    if not RdysCrateTracker.db or not RdysCrateTracker.db.profile then return end
    if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end

    -- We intentionally do nothing here now.
    -- ShardID is maintained by SafeShardFromGUID() via mouseover/vignette.
    return
end
RdysCrateTracker.GetShardID = GetShardID



local function crateIsDupe(crateInfo)
    if not RdysCrateTracker.db.profile.enable then return false end
    if RdysCrateTracker.db.profile.notPvp then return false end
    if not crateInfo or not crateInfo.zoneID then return false end

    -- Normalize zone ID so layered/phase zones match correctly
    local nz = RdysCrateTracker:NormalizeZoneID(crateInfo.zoneID)
    if not nz then return false end

    local existing = RdysCrateTracker.db.profile.crateDB[nz]
    if not existing or not existing.ts then
        return false
    end

    -- Dupe window: 180 seconds
    return (crateInfo.ts - existing.ts) <= 180
end

RdysCrateTracker.crateIsDupe = crateIsDupe



-- Group leader lookup
function RdysCrateTracker:GetPartyLeader()
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name, rank = GetRaidRosterInfo(i)
            if rank == 2 then return name end
        end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            local unitID = "party" .. i
            if UnitIsGroupLeader(unitID) then return UnitName(unitID) end
        end
        if UnitIsGroupLeader("player") then
            return UnitName("player")
        end
    end
    return nil
end

function RdysCrateTracker.checkDelta(crateInfo)
    if not RdysCrateTracker.db.profile.enable then return false end
    if RdysCrateTracker.db.profile.notPvp then return false end
    if not crateInfo or not crateInfo.zoneID then return false end

    -- Normalize zone ID
    local nz = RdysCrateTracker:NormalizeZoneID(crateInfo.zoneID)
    if not nz then return false end  -- Cannot throttle without a correct zone root

    -- Create table if missing
    RdysCrateTracker.recent = RdysCrateTracker.recent or {}
    RdysCrateTracker.recent[nz] = RdysCrateTracker.recent[nz] or { ts = 0 }

    -- Time since last allowed announcement for this zone
    local lastTs = RdysCrateTracker.recent[nz].ts or 0
    local now    = GetServerTime()
    local delta  = now - lastTs

    -- 30-second throttle
    if delta < 30 then
        return false
    end

    -- Update to NOW (not crateInfo.ts)
    RdysCrateTracker.recent[nz].ts = now

    return true
end



local function displayTime(t)
    if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    local days = floor(t/86400)
    local d_unit = (days > 1 and "days" or "day")
    local hours = floor(mod(t, 86400)/3600)
    local minutes = floor(mod(t,3600)/60)
    local seconds = floor(mod(t,60))
    if days > 0 then
        return format("%d %s %02d h %02d m %02d s",days,d_unit,hours,minutes,seconds)
    elseif hours > 0 then
        return format("%02d:%02d:%02d",hours,minutes,seconds)
    elseif minutes > 0 then
        return format("%02d:%02d",minutes,seconds)
    else
        return format("%02d s",seconds)
    end
end
RdysCrateTracker.displayTime = displayTime

local function nextCrateTime(crateInfo, curTime)
    if not RdysCrateTracker.db.profile.enable then return nil end
    if RdysCrateTracker.db.profile.notPvp then return nil end
    if not crateInfo or not crateInfo.zoneID then return nil end

    -- Normalize root zone for frequency lookup
    local nz = RdysCrateTracker:NormalizeZoneID(crateInfo.zoneID)
    if not nz then return nil end

    -- NEW: zoneID-based frequency (no more parentMapID)
    local freq = RdysCrateTracker.frequency[nz]
    if not freq then return nil end

    -- timestamp progression logic (unchanged)
    local elapsed    = curTime - crateInfo.ts
    local crateCount = floor(elapsed / freq)
    local nextCrate  = crateInfo.ts + (crateCount + 1) * freq

    return nextCrate
end

RdysCrateTracker.nextCrateTime = nextCrateTime


local function lastCrateStaleness(crateInfo, curTime)
    if not RdysCrateTracker.db.profile.enable then return nil end
    if RdysCrateTracker.db.profile.notPvp then return nil end
    if not crateInfo or not crateInfo.zoneID then return nil end

    -- Normalize root zoneID
    local nz = RdysCrateTracker:NormalizeZoneID(crateInfo.zoneID)
    if not nz then return nil end

    -- ZoneID frequency
    local freq = RdysCrateTracker.frequency[nz]
    if not freq then return nil end

    -- Calculate "crate cycles" elapsed since last recorded crate
    local duration = curTime - crateInfo.ts
    return floor(duration / freq)
end

RdysCrateTracker.lastCrateStaleness = lastCrateStaleness

local function nextCrateText(crateInfo, curTime)
    if not RdysCrateTracker.db.profile.enable then return nil end
    if RdysCrateTracker.db.profile.notPvp then return nil end
    if not crateInfo or not crateInfo.zoneID then return "Unknown" end

    -- zoneID-only calculation
    local ts = nextCrateTime(crateInfo, curTime)
    if ts then
        return tostring(displayTime(ts - curTime))
    end

    -- fallback: no zone frequency configured
    local nz    = RdysCrateTracker:NormalizeZoneID(crateInfo.zoneID)
    local mInfo = C_Map.GetMapInfo(nz)
    local zName = mInfo and mInfo.name or ("ZoneID " .. tostring(nz))

    -- We *can* still display parent info if you want, but it's purely cosmetic
    local pName = crateInfo.zoneParentName or "Unknown Parent"
    local pID   = crateInfo.zoneParentID or 0

    return string.format("Unknown: %s (%d) - no frequency for zone %s (%d)",
        pName, pID, zName, nz)
end

RdysCrateTracker.nextCrateText = nextCrateText


-- Version hello (guild)
function RdysCrateTracker:AnnounceVersion()
    if self.helloSent then return end
    -- Avoid announcing version from inside blocked instances or during warmode period
    if (RdysCrateTracker and ((RdysCrateTracker.IsBlockedInstance and RdysCrateTracker:IsBlockedInstance()) or (RdysCrateTracker.WarmodeTS and RdysCrateTracker:WarmodeTS())))
    or (self and ((type(self.IsBlockedInstance) == "function" and self:IsBlockedInstance()) or (type(self.WarmodeTS) == "function" and self:WarmodeTS()))) then
        if self.db and self.db.profile and self.db.profile.debugged then
            print("|cffff9966[RCT]|r In blocked instance or warmode period; not announcing version.")
        end
        return
    end
    self.helloSent = true
    AceComm:SendCommMessage(MODERN_PREFIX, "HELLO~" .. tostring(self.version or "1.0"), "GUILD")
end
