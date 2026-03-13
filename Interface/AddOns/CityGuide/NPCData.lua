-- NPC Data for all maps
-- Format: [mapID] = { {x = coord/100, y = coord/100, name = "Name", icon = "path", minimapIcon = "path"} }
-- minimapIcon should be a path to a minimap-style icon texture file
--
-- Common minimap icon paths (from Interface\Minimap\Tracking\):

local MINIMAP_ICONS = {
    -- Services
    BANKER = "Interface\\Minimap\\Tracking\\Banker",
    AUCTIONEER = "Interface\\Minimap\\Tracking\\Auctioneer",
    INNKEEPER = "Interface\\Minimap\\Tracking\\Innkeeper",
    FLIGHTMASTER = "Interface\\Minimap\\Tracking\\FlightMaster",
    STABLEMASTER = "Interface\\Minimap\\Tracking\\StableMaster",
    FOCUS = "Interface\\Minimap\\Tracking\\focus",
    MAILBOX = "Interface\\Minimap\\Tracking\\Mailbox",
    REPAIR = "Interface\\Minimap\\Tracking\\Repair",
    BARBER = "Interface\\Minimap\\Tracking\\Barbershop", -- Added in 9.0.1
    TRANSMOGRIFIER = "Interface\\Minimap\\Tracking\\Transmogrifier", -- Added in 7.2.0
    UPGRADE = "Interface\\Minimap\\Tracking\\upgradeitem-32x32", 
    REFORGE = "Interface\\Cursor\\Crosshair\\reforge", 
    PVP = "Interface\\Cursor\\Crosshair\\missions",
    PVP_OLD = "Interface\\Minimap\\Tracking\\battlemaster",
    GOLD_HAMMER = "Interface\\Minimap\\trapinactive_hammergold",
    WORK_ORDERS = "Interface\\Cursor\\Crosshair\\workorders",
    COMET = "Interface\\Cursor\\Crosshair\\bastionteleporter",
    ARGUS = "Interface\\Cursor\\Crosshair\\argusteleporter",
    COIN = "Interface\\Buttons\\ui-grouploot-coin-up",
    
    -- Trainers
    CLASS_TRAINER = "Interface\\Minimap\\Tracking\\Class",
    PROF_TRAINER = "Interface\\Minimap\\Tracking\\Profession",
    FISHING = "Interface\\Cursor\\Crosshair\\fishing",
    
    -- Vendors
    VENDOR_AMMO = "Interface\\Minimap\\Tracking\\Ammunition",
    VENDOR_FOOD = "Interface\\Minimap\\Tracking\\Food",
    VENDOR_POISON = "Interface\\Minimap\\Tracking\\Poisons",
    VENDOR_REAGENT = "Interface\\Minimap\\Tracking\\Reagent",
    
    QUESTGIVER = "Interface\\GossipFrame\\AvailableQuestIcon",
    TRIVIAL_QUESTS = "Interface\\Minimap\\Tracking\\TrivialQuests",
    
    PORTAL_HORDE = "Interface\\Minimap\\vehicle-hordemageportal",
    PORTAL_ALLY = "Interface\\Minimap\\vehicle-alliancemageportal",
    PORTAL_MYTHIC = "Interface\\Minimap\\vehicle-alliancewarlockportal",

    ROSTRUM = "Interface\\AddOns\\CityGuide\\Icons\\rostrum",
    ORDERS = "Interface\\AddOns\\CityGuide\\Icons\\craftingorders",
    CATALYST = "Interface\\AddOns\\CityGuide\\Icons\\catalyst",
    DECOR = "Interface\\AddOns\\CityGuide\\Icons\\decor",
    RENOWN = "Interface\\AddOns\\CityGuide\\Icons\\renown",
    DELVES = "Interface\\AddOns\\CityGuide\\Icons\\delves",
    TRADINGPOST = "Interface\\AddOns\\CityGuide\\Icons\\tp",
    VENDOR = "Interface\\AddOns\\CityGuide\\Icons\\vendor",
    BMAH = "Interface\\AddOns\\CityGuide\\Icons\\BMAH",
    HARANDAR = "Interface\\AddOns\\CityGuide\\Icons\\harandar",
}

-- IMPORTANT: Only define CityGuideNPCData ONCE!
CityGuideNPCData = {
    [84] = { -- Stormwind
        {
            x = 61.79 / 100, 
            y = 73.00 / 100, 
            name = "AH", 
            icon = "Interface\\Icons\\INV_Misc_Coin_01",
            minimapIcon = MINIMAP_ICONS.AUCTIONEER
        },
        {
            x = 62.24 / 100, 
            y = 76.53 / 100, 
            name = "Bank", 
            icon = "Interface\\Icons\\INV_Misc_Bag_07",
            minimapIcon = MINIMAP_ICONS.BANKER
        },
        {
            x = 49.24 / 100, 
            y = 84.20 / 100, 
            name = "Portal Room", 
            icon = "Interface\\Icons\\Spell_Arcane_PortalDalaran",
            minimapIcon = MINIMAP_ICONS.PORTAL_ALLY
        },
        {x = 61.42 / 100,
         y = 66.14 / 100,
            name = "Barber", 
            icon = MINIMAP_ICONS.BARBER, 
            minimapIcon = MINIMAP_ICONS.BARBER,
            noCluster = true,
        },
        {
            x = 80.08 / 100, 
            y = 62.51 / 100, 
            name = "Dummies", 
            icon = "Interface\\Icons\\achievement_legionpvp2tier3", 
            minimapIcon = MINIMAP_ICONS.PVP,
            color = "FF2020",
            textDirection = "top"
        },
            {
            x = 49.32/ 100, 
            y = 80.08 / 100, 
            name = "Decor\n(Books)", 
            icon = "Interface\\Housing\\inv_12ph_genericfixture",
            minimapIcon = MINIMAP_ICONS.DECOR,
            textDirection = "top",
            noCluster = true, 
            labelDistance = 1.5
        },
        {
            x = 77.87/ 100, 
            y = 65.89 / 100, 
            name = "Decor\n(PvP)", 
            icon = "Interface\\Housing\\inv_12ph_genericfixture",
            minimapIcon = MINIMAP_ICONS.DECOR,
            noCluster = true, 
        },
        {
            x = 67.62/ 100, 
            y = 72.98 / 100, 
            name = "Decor", 
            icon = "Interface\\Housing\\inv_12ph_genericfixture",
            minimapIcon = MINIMAP_ICONS.DECOR,
            noCluster = true,
            textDirection = "right",
            labelDistance = 1.3
        },
        {
            x = 74.50/ 100, 
            y = 18.26 / 100, 
            name = "Cata Portals", 
            icon = "Interface\\Icons\\Spell_Arcane_PortalStormWind",
            minimapIcon = MINIMAP_ICONS.PORTAL_MYTHIC,
            noCluster = true,
            textDirection = "right",
            labelDistance = 1.3
        },
    },
    [85] = { -- Orgrimmar
        {
            x = 0.54, 
            y = 0.73, 
            name = "AH", 
            icon = "Interface\\Icons\\INV_Misc_Coin_01",
            minimapIcon = MINIMAP_ICONS.AUCTIONEER
        },
        {
            x = 0.49, 
            y = 0.82, 
            name = "Bank", 
            icon = "Interface\\Icons\\INV_Misc_Bag_07",
            minimapIcon = MINIMAP_ICONS.BANKER
        },
        {
        x = 48.66 / 100, 
        y = 76.04 / 100, 
        name = "TP", 
        icon = "Interface\\Icons\\Tradingpostcurrency", 
        minimapIcon = MINIMAP_ICONS.TRADINGPOST,
        textDirection = "top",
        noCluster = true, 
        color = "99CCFF"
    },
        {
            x = 52.78/ 100, 
            y = 89.06 / 100, 
            name = "Decor", 
            icon = "Interface\\Housing\\inv_12ph_genericfixture",
            minimapIcon = MINIMAP_ICONS.DECOR
        },
        {
            x = 50.35/ 100, 
            y = 58.28 / 100, 
            name = "Decor\n(Org Quartermaster)", 
            icon = "Interface\\Housing\\inv_12ph_genericfixture",
            minimapIcon = MINIMAP_ICONS.DECOR
        },
        {
            x = 58.58/ 100, 
            y = 50.43 / 100, 
            name = "Decor\n(Books)", 
            icon = "Interface\\Housing\\inv_12ph_genericfixture",
            minimapIcon = MINIMAP_ICONS.DECOR
        },
        {
            x = 38.85/ 100, 
            y = 72.01 / 100, 
            name = "Decor\n(PvP)", 
            icon = "Interface\\Housing\\inv_12ph_genericfixture",
            minimapIcon = MINIMAP_ICONS.DECOR
        },
    },
    [2339] = { -- Dornogal
        -- Main Services
        {x = 58.86 / 100,
         y = 51.41 / 100,
            name = "Barber", 
            icon = MINIMAP_ICONS.BARBER, 
            minimapIcon = MINIMAP_ICONS.BARBER,
            noCluster = true,
            textDirection = "top", 
        }, 
        {
            x = 45.42 / 100, 
            y = 47.51 / 100, 
            name = "Inn", 
            icon = "Interface\\Icons\\inv_misc_rune_01", 
            minimapIcon = MINIMAP_ICONS.INNKEEPER,
            noCluster = true
        }, 
        {
            x = 52.50 / 100, 
            y = 45.41 / 100, 
            name = "Bank", 
            icon = "Interface\\Icons\\INV_Misc_Bag_07", 
            minimapIcon = MINIMAP_ICONS.BANKER,
            noCluster = true, 
            textDirection = "right", 
            color = "FFD700"
        }, 
        {
            x = 55.81 / 100, 
            y = 48.60 / 100, 
            name = "AH", 
            icon = "Interface\\Icons\\INV_Misc_Coin_01", 
            minimapIcon = MINIMAP_ICONS.AUCTIONEER,
            noCluster = true
        },
        {
            x = 57.96 / 100, 
            y = 56.48 / 100, 
            name = "Orders", 
            icon = "Interface\\Icons\\INV_Misc_Note_06", 
            minimapIcon = MINIMAP_ICONS.ORDERS,
            noCluster = true, 
            textDirection = "right", 
            labelDistance = 1.2
        },
        {
            x = 51.66 / 100, 
            y = 42.06 / 100, 
            name = "Upgrades", 
            icon = "Interface\\Icons\\ui_itemupgrade", 
            minimapIcon = MINIMAP_ICONS.UPGRADE,
            noCluster = true, 
            textDirection = "left", 
            labelDistance = 1.3
        },
        {
            x = 47.92 / 100, 
            y = 67.89 / 100, 
            name = "Rostrum", 
            icon = "Interface\\Icons\\Ability_Mount_Drake_Azure", 
            minimapIcon = MINIMAP_ICONS.ROSTRUM,
            noCluster = true, 
            textDirection = "left", 
            labelDistance = 1.3
        },
        {
            x = 44.60 / 100, 
            y = 55.91 / 100, 
            name = "Trading\nPost", 
            icon = "Interface\\Icons\\Tradingpostcurrency", 
            minimapIcon = MINIMAP_ICONS.TRADINGPOST,
            noCluster = true, 
            color = "99CCFF"
        },
        {
            x = 55.45 / 100, 
            y = 77.18 / 100, 
            name = "PvP\nDecor\nDummies", 
            icon = "Interface\\Icons\\achievement_legionpvp2tier3", 
            minimapIcon = MINIMAP_ICONS.PVP,
            color = "FF2020"
        },
        {
            x = 53.78 / 100, 
            y = 57.19 / 100, 
            name = "Decor", 
            icon = "Interface\\Housing\\inv_12ph_genericfixture",
            minimapIcon = MINIMAP_ICONS.DECOR,
            textDirection = "top", 
            noCluster = true,
        },
       
        -- Portals
        {
            x = 41.11 / 100, 
            y = 22.89 / 100, 
            name = "Portal to SW", 
            icon = "Interface\\Icons\\Spell_Arcane_PortalStormWind", 
            minimapIcon = MINIMAP_ICONS.PORTAL_ALLY,
            noCluster = true,
            textDirection = "top",
        },
        {
            x = 38.29 / 100, 
            y = 27.13 / 100, 
            name = "Portal to Org", 
            icon = "Interface\\Icons\\Spell_Arcane_PortalOrgrimmar", 
            minimapIcon = MINIMAP_ICONS.PORTAL_HORDE,
            noCluster = true
        },
        {
            x = 53.86 / 100, 
            y = 38.72 / 100, 
            name = "M+ Teleports", 
            icon = "Interface\\Icons\\Spell_Shadow_Teleport", 
            minimapIcon = MINIMAP_ICONS.PORTAL_MYTHIC,
            noCluster = true, 
            textDirection = "top", 
            labelDistance = 0.9
        },
       
        -- Profession Tables
        {
            x = 44.15 / 100, 
            y = 45.83 / 100, 
            name = "Cook", 
            icon = "Interface\\Icons\\INV_Misc_Food_15", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00", 
            noCluster = true, 
            textDirection = "left"
        },
        {
            x = 50.48 / 100, 
            y = 26.84 / 100, 
            name = "Fishing", 
            icon = "Interface\\Icons\\ui_profession_fishing", 
            minimapIcon = MINIMAP_ICONS.FISHING,
            color = "00FF00", 
            noCluster = true, 
            textDirection = "top"
        },
        {
            x = 47.28 / 100, 
            y = 70.45 / 100, 
            name = "Alch", 
            icon = "Interface\\Icons\\Trade_Alchemy", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00"
        },
        {
            x = 49.07 / 100, 
            y = 63.20 / 100, 
            name = "BS", 
            icon = "Interface\\Icons\\Trade_BlackSmithing", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00"
        },
        {
            x = 48.62 / 100, 
            y = 71.16 / 100, 
            name = "Insc", 
            icon = "Interface\\Icons\\INV_Inscription_Tradeskill01", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00"
        },
        {
            x = 52.46 / 100, 
            y = 71.29 / 100, 
            name = "Ench", 
            icon = "Interface\\Icons\\Trade_Engraving", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00"
        },
        {
            x = 49.05 / 100, 
            y = 56.06 / 100, 
            name = "Engi", 
            icon = "Interface\\Icons\\Trade_Engineering", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00"
        },
        {
            x = 49.56 / 100, 
            y = 71.16 / 100, 
            name = "Jewel", 
            icon = "Interface\\Icons\\INV_Misc_Gem_01", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00"
        },
        {
            x = 54.51 / 100, 
            y = 58.94 / 100, 
            name = "LW", 
            icon = "Interface\\Icons\\INV_Misc_ArmorKit_17", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00", 
            labelDistance = 0.8
        },
        {
            x = 54.66 / 100, 
            y = 63.37 / 100, 
            name = "Tailor", 
            icon = "Interface\\Icons\\Trade_Tailoring", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00", 
            noCluster = true
        },
        
    },
    [627] = { --Legion / Remix Dalaran
        -- Main
        {
            x = 55.32 / 100, 
            y = 23.98 / 100, 
            name = "Org", 
            icon = "Interface\\Icons\\Spell_Arcane_PortalOrgrimmar",
            minimapIcon = MINIMAP_ICONS.PORTAL
        },
        {
            x = 39.15 / 100, 
            y = 63.01 / 100, 
            name = "SW", 
            icon = "Interface\\Icons\\Spell_Arcane_PortalStormWind",
            minimapIcon = MINIMAP_ICONS.PORTAL
        },
        {
            x = 47.57 / 100, 
            y = 70.31 / 100, 
            name = "Bazaar", 
            icon = "Interface\\Icons\\Spell_arcane_portalvaldrakken", 
            minimapIcon = MINIMAP_ICONS.PORTAL,
            noCluster = true, 
            textDirection = "top", 
            labelDistance = 1.2
        },
        {
            x = 44.46 / 100, 
            y = 74.38 / 100, 
            name = "Bank", 
            icon = "Interface\\Icons\\INV_Misc_Bag_07", 
            minimapIcon = MINIMAP_ICONS.BANKER,
            color = "FFD700"
        },
        {
            x = 47.65 / 100, 
            y = 89.17 / 100, 
            name = "Remix vendors", 
            icon = "Interface\\Icons\\INV_Misc_Coin_01",
            minimapIcon = MINIMAP_ICONS.QUESTGIVER
        },
        {
            x = 43.38/ 100, 
            y = 49.42 / 100, 
            name = "Decor", 
            icon = "Interface\\Housing\\inv_12ph_genericfixture",
            minimapIcon = MINIMAP_ICONS.DECOR
        },
        {
            x = 67.41 / 100, 
            y = 33.64 / 100, 
            name = "Decor (Horde)", 
            icon = "Interface\\Housing\\inv_12ph_genericfixture",
            minimapIcon = MINIMAP_ICONS.DECOR,
            faction = "Horde"
        },
        {
            x = 59.60 / 100, 
            y = 47.64 / 100, 
            name = "Decor Remix\n(Sewers)", 
            icon = "Interface\\Housing\\inv_12ph_genericfixture",
            minimapIcon = MINIMAP_ICONS.DECOR,
            labelDistance = 1.5
        },
    },
    [628] = { --Legion sewers
        {
        x = 67.52/ 100, 
        y = 63.06 / 100, 
        name = "Decor", 
        icon = "Interface\\Housing\\inv_12ph_genericfixture",
        minimapIcon = MINIMAP_ICONS.DECOR,
        },
    },
    [2112] = { -- Valdrakken (Dragonflight)
        -- Main Services
        {
            x = 55.18 / 100, 
            y = 57.36 / 100, 
            name = "Bank", 
            icon = "Interface\\Icons\\INV_Misc_Bag_07", 
            minimapIcon = MINIMAP_ICONS.BANKER,
            noCluster = true, 
            color = "FFD700"
        },
        {
            x = 42.65 / 100, 
            y = 59.79 / 100, 
            name = "AH", 
            icon = "Interface\\Icons\\INV_Misc_Coin_01", 
            minimapIcon = MINIMAP_ICONS.AUCTIONEER,
            noCluster = true, 
            textDirection = "top"
        },
        {
            x = 47.44 / 100, 
            y = 46.66 / 100, 
            name = "Inn\nCook", 
            icon = "Interface\\Icons\\inv_misc_rune_01", 
            minimapIcon = MINIMAP_ICONS.INNKEEPER,
            noCluster = true
        },
        {
            x = 34.86 / 100, 
            y = 61.61 / 100, 
            name = "Orders", 
            icon = "Interface\\Icons\\INV_Misc_Note_06", 
            minimapIcon = MINIMAP_ICONS.ORDERS,
            noCluster = true, 
            textDirection = "top"
        },
        {
            x = 41.00 / 100, 
            y = 44.20 / 100, 
            name = "PvP", 
            icon = "Interface\\Icons\\achievement_legionpvp2tier3", 
            minimapIcon = MINIMAP_ICONS.PVP,
            noCluster = true, 
            color = "FF2020"
        },
        {
            x = 44.24 / 100, 
            y = 67.84 / 100, 
            name = "Flight\nMaster", 
            icon = "Interface\\Icons\\ability_mount_tawnywindrider",
            minimapIcon = MINIMAP_ICONS.FLIGHTMASTER
        },
        {
            x = 38.42 / 100, 
            y = 37.21 / 100, 
            name = "Primal\nVendors", 
            icon = "Interface\\Icons\\ability_vehicle_electrocharge",
            minimapIcon = MINIMAP_ICONS.QUESTGIVER
        },
        {
            x = 46.90 / 100, 
            y = 78.90 / 100, 
            name = "Stable", 
            icon = "Interface\\Icons\\classicon_hunter",
            minimapIcon = MINIMAP_ICONS.STABLEMASTER
        },
        
        
        -- Portals
        {
            x = 58.15 / 100, 
            y = 40.05 / 100, 
            name = "Portals", 
            icon = "Interface\\Icons\\Spell_Arcane_PortalDalaran", 
            minimapIcon = MINIMAP_ICONS.PORTAL_ALLY,
            noCluster = true
        },
        {
            x = 26.04 / 100, 
            y = 40.82 / 100, 
            name = "Badlands\nPortal", 
            icon = "Interface\\Icons\\Spell_Arcane_PortalOrgrimmar", 
            minimapIcon = MINIMAP_ICONS.PORTAL_HORDE,
            textDirection = "top"
        },
        {
            x = 62.88 / 100, 
            y = 57.47 / 100, 
            name = "Dream\nPortal", 
            icon = "Interface\\Icons\\inv_achievement_raidemeralddream_raid", 
            minimapIcon = MINIMAP_ICONS.PORTAL_ALLY,
            textDirection = "top"
        },
        {
            x = 25.03 / 100, 
            y = 50.59 / 100, 
            name = "Rostrum", 
            icon = "Interface\\Icons\\Ability_Mount_Drake_Azure", 
            minimapIcon = MINIMAP_ICONS.ROSTRUM,
            noCluster = true, 
            textDirection = "left", 
            labelDistance = 1.3
        },
        {
            x = 71.66/ 100, 
            y = 49.41 / 100, 
            name = "Decor", 
            icon = "Interface\\Housing\\inv_12ph_genericfixture",
            minimapIcon = MINIMAP_ICONS.DECOR,
            noCluster = true,
        },
        
        -- Profession Trainers & Stations
        {
            x = 44.89 / 100, 
            y = 74.88 / 100, 
            name = "Fishing", 
            icon = "Interface\\Icons\\ui_profession_fishing", 
            minimapIcon = MINIMAP_ICONS.FISHING,
            color = "00FF00", 
            textDirection = "right", 
            noCluster = true
        },
        {
            x = 36.72 / 100, 
            y = 72.20 / 100, 
            name = "Alch", 
            icon = "Interface\\Icons\\Trade_Alchemy", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00"
        },
        {
            x = 36.39 / 100, 
            y = 50.24 / 100, 
            name = "BS", 
            icon = "Interface\\Icons\\Trade_BlackSmithing", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00"
        },
        {
            x = 30.83 / 100, 
            y = 59.72 / 100, 
            name = "Ench", 
            icon = "Interface\\Icons\\Trade_Engraving", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00"
        },
        {
            x = 42.29 / 100, 
            y = 48.83 / 100, 
            name = "Engi", 
            icon = "Interface\\Icons\\Trade_Engineering", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00"
        },
        {
            x = 39.61 / 100, 
            y = 73.73 / 100, 
            name = "Insc", 
            icon = "Interface\\Icons\\INV_Inscription_Tradeskill01", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00"
        },
        {
            x = 40.81 / 100, 
            y = 60.55 / 100, 
            name = "Jewel", 
            icon = "Interface\\Icons\\INV_Misc_Gem_01", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00"
        },
        {
            x = 28.52 / 100, 
            y = 60.79 / 100, 
            name = "LW", 
            icon = "Interface\\Icons\\INV_Misc_ArmorKit_17", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00", 
            noCluster = true
        },
        {
            x = 31.88 / 100, 
            y = 67.68 / 100, 
            name = "Tailor", 
            icon = "Interface\\Icons\\Trade_Tailoring", 
            minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
            color = "00FF00"
        },
    },
    [2472] = { -- Tazavesh (K'aresh)
        {
            x = 40.65 / 100, 
            y = 29.11 / 100, 
            name = "Renown\nDecor", 
            icon = "Interface\\Icons\\ability_racial_etherealconnection",
            minimapIcon = MINIMAP_ICONS.RENOWN
        },
        {
            x = 43.30/ 100, 
            y = 35.53 / 100, 
            name = "Decor", 
            icon = "Interface\\Housing\\inv_12ph_genericfixture",
            minimapIcon = MINIMAP_ICONS.DECOR
        },
        {
            x = 41.07 / 100, 
            y = 25.16 / 100, 
            name = "Inn", 
            icon = "Interface\\Icons\\inv_misc_rune_01", 
            minimapIcon = MINIMAP_ICONS.INNKEEPER,
            textDirection = "top", 
            noCluster = true
        },
        {
            x = 47.36 / 100, 
            y = 26.79 / 100, 
            name = "Stable", 
            icon = "Interface\\Icons\\classicon_hunter",
            minimapIcon = MINIMAP_ICONS.STABLEMASTER
        },
        {
            x = 48.99 / 100, 
            y = 20.21 / 100, 
            name = "Portals", 
            icon = "Interface\\Icons\\spell_arcane_portaldalarancrater",
            minimapIcon = MINIMAP_ICONS.PORTAL
        },
        {
            x = 43.52 / 100, 
            y = 8.18 / 100, 
            name = "Al'dani", 
            icon = "Interface\\Icons\\inv_112_achievement_dungeon_ecodome",
            minimapIcon = MINIMAP_ICONS.QUESTGIVER
        },
        {
            x = 36.57 / 100, 
            y = 13.51 / 100, 
            name = "Tazavesh", 
            icon = "Interface\\Icons\\achievement_dungeon_brokerdungeon",
            minimapIcon = MINIMAP_ICONS.QUESTGIVER
        },
        {
            x = 46.80 / 100, 
            y = 56.83 / 100, 
            name = "Phase", 
            icon = "Interface\\Icons\\spell_arcane_prismaticcloak",
            minimapIcon = "Interface\\Icons\\spell_arcane_prismaticcloak"
        },
        {
            x = 38.64 / 100, 
            y = 51.02 / 100, 
            name = "Ky'veza", 
            icon = "Interface\\Icons\\inv_achievement_raidnerubian_etherealassasin",
            minimapIcon = MINIMAP_ICONS.QUESTGIVER
        },
    },
    
[2393] = { --Silvermoon
    -- Main Services
    {
        x = 49.93 / 100, 
        y = 64.54 / 100, 
        name = "Bank", 
        icon = "Interface\\Icons\\INV_Misc_Bag_07", 
        minimapIcon = MINIMAP_ICONS.BANKER,
        noCluster = true, 
        color = "FFD700"
    },
    {
        x = 48.61 / 100, 
        y = 61.98 / 100, 
        name = "Upgrades", 
        icon = "Interface\\Icons\\ui_itemupgrade", 
        minimapIcon = MINIMAP_ICONS.UPGRADE,
        noCluster = true, 
        textDirection = "right", 
        labelDistance = "1.5"
    },
    {
        x = 51.50 / 100, 
        y = 74.68 / 100, 
        name = "AH", 
        icon = "Interface\\Icons\\INV_Misc_Coin_01", 
        minimapIcon = MINIMAP_ICONS.AUCTIONEER,
        noCluster = true,
        textDirection = "left",
        labelDistance = "0.8",
    },
    {
        x = 53.37 / 100, 
        y = 66.31 / 100, 
        name = "Portals", 
        icon = "Interface\\Icons\\spell_arcane_portaldalarancrater", 
        minimapIcon = MINIMAP_ICONS.PORTAL_HORDE,
        noCluster = true
    },
    {
        x = 40.19 / 100, 
        y = 65.19 / 100, 
        name = "Catalyst", 
        icon = MINIMAP_ICONS.CATALYST,
        minimapIcon = MINIMAP_ICONS.CATALYST,
        noCluster = true, 
        textDirection = "top",
        labelDistance = "0.8",
    },
    {
        x = 56.28 / 100, 
        y = 70.33 / 100, 
        name = "Inn\nCook", 
        icon = "Interface\\Icons\\inv_misc_rune_01", 
        minimapIcon = MINIMAP_ICONS.INNKEEPER,
        noCluster = true
    },
    {
        x = 43.18 / 100, 
        y = 78.23 / 100, 
        name = "Barber", 
        icon = MINIMAP_ICONS.BARBER, 
        minimapIcon = MINIMAP_ICONS.BARBER,
        noCluster = true
    },
    {
        x = 52.50 / 100, 
        y = 78.21 / 100, 
        name = "Delves", 
        icon = "Interface\\Icons\\ui_delves",
        minimapIcon = MINIMAP_ICONS.DELVES
    },
    {
        x = 45.05 / 100, 
        y = 55.59 / 100, 
        name = "Orders", 
        icon = "Interface\\Icons\\INV_Misc_Note_06", 
        minimapIcon = MINIMAP_ICONS.WORK_ORDERS,
        noCluster = true
    },
    {
        x = 42.03 / 100, 
        y = 58.30 / 100, 
        name = "M+ Teleports", 
        icon = "Interface\\Icons\\Spell_Shadow_Teleport", 
        minimapIcon = MINIMAP_ICONS.PORTAL_MYTHIC,
        noCluster = true, 
    },
    {
        x = 48.88 / 100, 
        y = 78.15 / 100, 
        name = "TP", 
        icon = "Interface\\Icons\\Tradingpostcurrency", 
        minimapIcon = MINIMAP_ICONS.TRADINGPOST,
        noCluster = true, 
        color = "99CCFF"
    },
    {
        x = 36.30 / 100, 
        y = 81.06 / 100, 
        name = "PvP", 
        icon = "Interface\\Icons\\achievement_legionpvp2tier3", 
        minimapIcon = MINIMAP_ICONS.PVP_OLD,
        color = "FF2020",
        labelDistance = 1.8
    },
    {
        x = 36.78 / 100, 
        y = 85.65 / 100, 
        name = "Dummy", 
        icon = "Interface\\Icons\\Ability_rogue_combatexpertise", 
        minimapIcon = MINIMAP_ICONS.PVP,
        color = "FF2020",
    },
    {
        x = 36.91 / 100,
        y = 68.07 / 100,
        name = "Harandar", 
        icon = "Interface\\Icons\\inv_achievement_zone_harandar", 
        minimapIcon = MINIMAP_ICONS.HARANDAR,        
    },
    {
        x = 35.28 / 100,
        y = 65.70 / 100,
        name = "Void", 
        icon = "Interface\\Icons\\inv_zone_voidstorm", 
        minimapIcon = MINIMAP_ICONS.COMET, 
        noCluster = true, 
        textDirection = "left", 
        labelDistance = 1.3
    },
    {
        x = 51.06 / 100,
        y = 56.49 / 100,
        name = "Decor", 
        icon = "Interface\\Housing\\inv_12ph_genericfixture",
        minimapIcon = MINIMAP_ICONS.DECOR,
        noCluster = true, 
        textDirection = "top", 
    },
    {
        x = 41.60/ 100,
        y = 66.90 / 100,
        name = "Finery", 
        icon = "Interface\\Icons\\ui_plundercoins",
        minimapIcon = MINIMAP_ICONS.VENDOR,
        noCluster = true, 
        textDirection = "right", 
    },
    {
        x = 51.86/ 100,
        y = 48.56 / 100,
        name = "BMAH", 
        icon = "Interface\\Icons\\inv_misc_coin_16",
        minimapIcon = MINIMAP_ICONS.BMAH,
        noCluster = true, 
        textDirection = "top", 
    },

    -- Horde Only
        {
        x = 72.56 / 100, 
        y = 64.55 / 100, 
        name = "Bank", 
        icon = "Interface\\Icons\\INV_Misc_Bag_07", 
        minimapIcon = MINIMAP_ICONS.BANKER,
        noCluster = true, 
        color = "FFD700",
        faction = "Horde"
    },
    {
        x = 66.94 / 100, 
        y = 62.14 / 100, 
        name = "Inn", 
        icon = "Interface\\Icons\\inv_misc_rune_01", 
        minimapIcon = MINIMAP_ICONS.INNKEEPER,
        noCluster = true, 
        faction = "Horde"
    },
    {
        x = 67.61 / 100, 
        y = 72.50 / 100, 
        name = "AH", 
        icon = "Interface\\Icons\\INV_Misc_Coin_01", 
        minimapIcon = MINIMAP_ICONS.AUCTIONEER,
        noCluster = true, 
        textDirection = "top",  
        faction = "Horde"
    },
    {
        x = 70.12 / 100, 
        y = 83.29 / 100, 
        name = "Catalyst", 
        icon = MINIMAP_ICONS.CATALYST,
        minimapIcon = MINIMAP_ICONS.CATALYST,
        faction = "Horde"
    },
    {
        x = 73.89 / 100, 
        y = 74.34 / 100, 
        name = "Alch", 
        icon = "Interface\\Icons\\Trade_Alchemy", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00", 
        faction = "Horde"
    },
        {
        x = 69.69 / 100, 
        y = 84.51 / 100, 
        name = "BS", 
        icon = "Interface\\Icons\\Trade_BlackSmithing", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00", 
        faction = "Horde"
    },
    {
        x = 72.89/ 100, 
        y = 71.54 / 100, 
        name = "Ench", 
        icon = "Interface\\Icons\\Trade_Engraving", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00",
        faction = "Horde"
    },
    {
        x = 69.40 / 100, 
        y = 84.35 / 100, 
        name = "Engi", 
        icon = "Interface\\Icons\\Trade_Engineering", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00", 
        faction = "Horde"
    },
    {
        x = 72.58 / 100, 
        y = 71.16 / 100, 
        name = "Insc", 
        icon = "Interface\\Icons\\INV_Inscription_Tradeskill01", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00", 
        faction = "Horde"
    },
    {
        x = 73.70 / 100, 
        y = 70.57 / 100, 
        name = "Jewel", 
        icon = "Interface\\Icons\\INV_Misc_Gem_01", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00",
        faction = "Horde"
    },
    {
        x = 69.81 / 100, 
        y = 81.17 / 100, 
        name = "LW", 
        icon = "Interface\\Icons\\INV_Misc_ArmorKit_17", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00", 
        faction = "Horde"
    },
    {
        x = 73.38 / 100, 
        y = 72.71 / 100, 
        name = "Tailor", 
        icon = "Interface\\Icons\\Trade_Tailoring", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00",
        faction = "Horde"
    },

    -- Profession Tables
    {
        x = 47.02 / 100, 
        y = 51.88 / 100, 
        name = "Alch", 
        icon = "Interface\\Icons\\Trade_Alchemy", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00", 
        textDirection = "top"
    },
    {
        x = 43.74 / 100, 
        y = 51.33 / 100, 
        name = "BS", 
        icon = "Interface\\Icons\\Trade_BlackSmithing", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00", 
        noCluster = true,
        textDirection = "top"
    },
    {
        x = 47.97 / 100, 
        y = 53.63 / 100, 
        name = "Ench", 
        icon = "Interface\\Icons\\Trade_Engraving", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00"
    },
    {
        x = 43.53 / 100, 
        y = 54.01 / 100, 
        name = "Engi", 
        icon = "Interface\\Icons\\Trade_Engineering", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00", 
        noCluster = true
    },
    {
        x = 46.78 / 100, 
        y = 51.48 / 100, 
        name = "Insc", 
        icon = "Interface\\Icons\\INV_Inscription_Tradeskill01", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00", 
        textDirection = "top"
    },
    {
        x = 47.93 / 100, 
        y = 55.15 / 100, 
        name = "Jewel", 
        icon = "Interface\\Icons\\INV_Misc_Gem_01", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00"
    },
    {
        x = 43.15 / 100, 
        y = 55.70 / 100, 
        name = "LW", 
        icon = "Interface\\Icons\\INV_Misc_ArmorKit_17", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00", 
        textDirection = "top",
        noCluster = true
    },
    {
        x = 48.25 / 100, 
        y = 54.15 / 100, 
        name = "Tailor", 
        icon = "Interface\\Icons\\Trade_Tailoring", 
        minimapIcon = MINIMAP_ICONS.PROF_TRAINER,
        color = "00FF00"
    },
},
}

-- Profession Hub Markers (optional - define custom position for "Profession Tables" label)
CityGuideProfessionHubs = {
    [2393] = {  --  Silvermoon 
        {  -- First hub (neutral)
            x = 45.67 / 100, 
            y = 48.91 / 100,
            name = "Profession\nTables",
            color = "00FF00",
        },
        {  -- Second hub (Horde)
            x = 73.21 / 100, 
            y = 73.58 / 100,
            name = "Profession\nTables",
            color = "00FF00",
            faction = "Horde"
        },
    },  
    
    [2339] = {
        x = 52.29 / 100,
        y = 71.34 / 100,
        name = "Profession\nTables",  
        color = "00FF00",  
    },
    
    [2112] = {
        x = 35.00 / 100,
        y = 60.00 / 100,
        name = "Profession Tables",
        color = "00FF00",  
    },
}