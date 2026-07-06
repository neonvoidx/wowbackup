local addonName = ...
local L = _G.RCT_LOCALE or {}

-- Use Ace3 and database from the attached file
local RdysCrateTracker = LibStub("AceAddon-3.0"):GetAddon("RdysCrateTracker", true)
if not RdysCrateTracker then
    error(L["ADDON_NOT_FOUND"] or "RdysCrateTracker addon not found. Please ensure it is loaded.")
end

-- Create a new frame for the bounty hunter

-- Register the event for vignette and combat log updates
local bountyframe = CreateFrame("Frame")



-- Initialize tracker if not already present
RdysCrateTracker.seenBounties = RdysCrateTracker.seenBounties or {}

local function announceBounty(self, event, ...)
    -- Safety check for database initialization
    if not RdysCrateTracker.db or not RdysCrateTracker.db.profile then return end
    
    if not RdysCrateTracker.db.profile.enable then return end
    if RdysCrateTracker.db.profile.notPvp then return end
    if not RdysCrateTracker.db.profile.bountyHunter then return end
    if RdysCrateTracker.db.profile.Combatdisable and UnitAffectingCombat("player") then return end


    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    local vignettes = C_VignetteInfo.GetVignettes()
    for _, vignetteGUID in ipairs(vignettes) do
        -- Skip if this bounty was already seen
        if not RdysCrateTracker.seenBounties[vignetteGUID] then
            local vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
            if vignetteInfo then
                local parts = { strsplit("-", vignetteGUID) }
                local factionID = tonumber(parts[6])
                local position = C_VignetteInfo.GetVignettePosition(vignetteGUID, mapID)

                if type(position) == "table" then
                    local posX = position.x or 0
                    local posY = position.y or 0
                    local readableX = math.floor(posX * 10000 + 0.5) / 100
                    local readableY = math.floor(posY * 10000 + 0.5) / 100

                    local playerFaction = UnitFactionGroup("player")

                    local x = position.x
                    local y = position.y
                    local description = vignetteInfo.name or "Unknown"


                

                    if factionID == 2901 and playerFaction == "Horde" then
                        RdysCrateTracker:Print((L["BOUNTY_ALLIANCE"] and L["BOUNTY_ALLIANCE"]:format(readableX, readableY)) or ("HatedGaming Bounty Hunter - Alliance Bounty is in your zone @ " .. readableX .. ", " .. readableY))
                    --    RdysCrateTracker.createMapPin(mapID, x, y, description) -- Create a map pin for the bounty
                        if RdysCrateTracker.db.profile.warningenable then
                        RdysCrateTracker.warningFrame:AddMessage((L["BOUNTY_ALLIANCE"] and L["BOUNTY_ALLIANCE"]:format(readableX, readableY)) or ("HatedGaming Bounty Hunter - Alliance Bounty is in your zone @ " .. readableX .. ", " .. readableY))
                        end
                        RdysCrateTracker.seenBounties[vignetteGUID] = true
                    elseif factionID == 2902 and playerFaction == "Alliance" then
                        RdysCrateTracker:Print((L["BOUNTY_HORDE"] and L["BOUNTY_HORDE"]:format(readableX, readableY)) or ("HatedGaming Bounty Hunter - Horde Bounty is in your zone @ " .. readableX .. ", " .. readableY))
                     --   RdysCrateTracker.createMapPin(mapID, x, y, description) -- Create a map pin for the bounty
                        if RdysCrateTracker.db.profile.warningenable then
                            RdysCrateTracker.warningFrame:AddMessage((L["BOUNTY_HORDE"] and L["BOUNTY_HORDE"]:format(readableX, readableY)) or ("HatedGaming Bounty Hunter - Horde Bounty is in your zone @ " .. readableX .. ", " .. readableY))
                            end
                        RdysCrateTracker.seenBounties[vignetteGUID] = true
                        bountyframe:UnregisterEvent("VIGNETTES_UPDATED")
                        C_Timer.After(30, function()
                            bountyframe:RegisterEvent("VIGNETTES_UPDATED")
                        end)
                    end
                end
            end
        end
    end
end

-- Defer bounty hunter initialization until database is ready
local function initializeBountyHunter()
    if RdysCrateTracker.db and RdysCrateTracker.db.profile and RdysCrateTracker.db.profile.bountyHunter then
        bountyframe:RegisterEvent("VIGNETTES_UPDATED")
        bountyframe:SetScript("OnEvent", announceBounty)
    end
end

-- Check if database is already initialized
if RdysCrateTracker.db and RdysCrateTracker.db.profile then
    initializeBountyHunter()
else
    -- Wait for addon to be fully initialized
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("ADDON_LOADED")
    initFrame:SetScript("OnEvent", function(self, event, addonName)
        if addonName == "RCT" then
            C_Timer.After(0.1, initializeBountyHunter) -- Small delay to ensure full initialization
            initFrame:UnregisterEvent("ADDON_LOADED")
        end
    end)
end

