---@class MapPinEnhanced
local MapPinEnhanced = select(2, ...)
local Navigation = MapPinEnhanced:GetModule("Navigation")

-- The introduction has quest-only flight options. These normal menus are
-- used after Into the Vaults of Atal'Utek (98388) is complete.
---@type NavigationRequirement
local WINDCALLER_REQUIREMENT = { operation = "check", kind = "questCompleted", value = 98388 }

-- Feather of Tok'jara / quest 97662 unlocks the choice, not the flight service.
-- Wago DB2 12.1.7.70493: TraitDefinition 141875 -> entry 137111, node 110463.
---@type NavigationRequirement
local SPECTRAL_SHIPPING_REQUIREMENT = {
    operation = "all",
    children = {
        WINDCALLER_REQUIREMENT,
        {
            operation = "check",
            kind = "traitEntry",
            value = { treeID = 1191, nodeID = 110463, entryID = 137111 },
        },
    },
}

local GOSSIP = {

    -- Zone: Boralus (map 1161)
    -- Boralus (map 1161 67.95,26.69) -> Vol'dun (map 864 35.60,33.17) via gossip
    {
        fromPointID = 800076,
        fromMap = 1161,
        fromX = 0.6795,
        fromY = 0.2669,
        toPointID = 900056,
        toMap = 864,
        toX = 0.356,
        toY = 0.3317,
        type = "gossip",
        travelDuration = 1,
        gossip = {
            gossipOptionID = 48169,
            npcID = 135681,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "faction",
                    value = "Alliance",
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 51572,
                },
            },
        },
    },
    -- Boralus (map 1161 67.95,26.69) -> Zuldazar (map 862 40.68,70.86) via gossip
    {
        fromPointID = 800076,
        fromMap = 1161,
        fromX = 0.6795,
        fromY = 0.2669,
        toPointID = 900010,
        toMap = 862,
        toX = 0.4068,
        toY = 0.7086,
        type = "gossip",
        travelDuration = 1,
        gossip = {
            gossipOptionID = 48171,
            npcID = 135681,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "faction",
                    value = "Alliance",
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 51308,
                },
            },
        },
    },
    -- Boralus (map 1161 67.95,26.69) -> Nazmir (map 863 61.95,39.92) via gossip
    {
        fromPointID = 800076,
        fromMap = 1161,
        fromX = 0.6795,
        fromY = 0.2669,
        toPointID = 900048,
        toMap = 863,
        toX = 0.6195,
        toY = 0.3992,
        type = "gossip",
        travelDuration = 1,
        gossip = {
            gossipOptionID = 48170,
            npcID = 135681,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "faction",
                    value = "Alliance",
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 51571,
                },
            },
        },
    },

    -- Zone: Dazar'alor (map 1165)
    -- Dazar'alor (map 1165 41.83,87.61) -> Mechagon Island (map 1462 75.73,21.32) via gossip
    {
        fromPointID = 900086,
        fromMap = 1165,
        fromX = 0.4183,
        fromY = 0.8761,
        toPointID = 800104,
        toMap = 1462,
        toX = 0.7573,
        toY = 0.2132,
        type = "gossip",
        travelDuration = 20,
        gossip = {
            gossipOptionID = 50480,
            npcID = 152506,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "faction",
                    value = "Horde",
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 55651,
                },
            },
        },
    },

    -- Zone: Dornogal (map 2339)
    -- Dornogal (map 2339 73.55,5.29) -> Siren Isle (map 2369 70.69,53.49) via gossip
    {
        fromPointID = 1200134,
        fromMap = 2339,
        fromX = 0.7355,
        fromY = 0.0529,
        toPointID = 1200158,
        toMap = 2369,
        toX = 0.7069,
        toY = 0.5349,
        type = "gossip",
        travelDuration = 10,
        gossip = {
            gossipOptionID = 125352,
            npcID = 231541,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "any",
                    children = {
                        {
                            operation = "check",
                            kind = "questActive",
                            value = 84720,
                        },
                        {
                            operation = "check",
                            kind = "questCompleted",
                            value = 84720,
                        },
                    },
                },
            },
        },
    },

    -- Zone: Drustvar (map 896)
    -- Drustvar (map 896 20.60,43.34) -> Zuldazar (map 862 58.40,62.50) via gossip
    {
        fromPointID = 800022,
        fromMap = 896,
        fromX = 0.206,
        fromY = 0.4334,
        toPointID = 900023,
        toMap = 862,
        toX = 0.584,
        toY = 0.625,
        type = "gossip",
        travelDuration = 1,
        gossip = {
            gossipOptionID = 48793,
            npcID = 139519,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "faction",
                    value = "Horde",
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 51340,
                },
            },
        },
    },

    -- Zone: Mechagon Island (map 1462)
    -- Mechagon Island (map 1462 75.49,22.66) -> Dazar'alor (map 1165 41.75,87.43) via gossip
    {
        fromPointID = 800103,
        fromMap = 1462,
        fromX = 0.7549,
        fromY = 0.2266,
        toPointID = 900085,
        toMap = 1165,
        toX = 0.4175,
        toY = 0.8743,
        type = "gossip",
        travelDuration = 20,
        gossip = {
            gossipOptionID = 50481,
            npcID = 152510,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "faction",
                    value = "Horde",
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 55651,
                },
            },
        },
    },

    -- Zone: Nazmir (map 863)
    -- Nazmir (map 863 62.06,40.08) -> Boralus (map 1161 70.22,27.06) via gossip
    {
        fromPointID = 900049,
        fromMap = 863,
        fromX = 0.6206,
        fromY = 0.4008,
        toPointID = 800083,
        toMap = 1161,
        toX = 0.7022,
        toY = 0.2706,
        type = "gossip",
        travelDuration = 1,
        gossip = {
            gossipOptionID = 48827,
            npcID = 139620,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "faction",
                    value = "Alliance",
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 51571,
                },
            },
        },
    },

    -- Zone: Orgrimmar (map 85)
    -- Orgrimmar (map 85 48.23,62.17) -> Mulgore (map 7 36.49,35.11) via gossip
    {
        fromPointID = 100261,
        fromMap = 85,
        fromX = 0.4823,
        fromY = 0.6217,
        toPointID = 100032,
        toMap = 7,
        toX = 0.3649,
        toY = 0.3511,
        type = "gossip",
        gossip = {
            gossipOptionID = 40007,
            npcID = 55382,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "event",
                    value = "DARKMOON FAIRE",
                },
                {
                    operation = "check",
                    kind = "faction",
                    value = "Horde",
                },
            },
        },
    },

    -- Zone: Oribos (map 1670)
    -- Oribos (map 1670 38.88,70.00) -> Zereth Mortis (map 1970 33.27,69.43) via gossip
    {
        fromPointID = 1000169,
        fromMap = 1670,
        fromX = 0.3888,
        fromY = 0.7,
        toPointID = 1000323,
        toMap = 1970,
        toX = 0.3327,
        toY = 0.6943,
        type = "gossip",
        travelDuration = 10,
        gossip = {
            gossipOptionID = 53550,
            npcID = 159478,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "not",
                    children = {
                        {
                            operation = "check",
                            kind = "questCompleted",
                            value = 64957,
                        },
                    },
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 64944,
                },
            },
        },
    },

    -- Zone: Silithus (map 81)
    -- Silithus (map 81 78.93,21.97) -> Chamber of Heart (map 1021 50.22,35.92) via gossip
    {
        fromPointID = 100246,
        fromMap = 81,
        fromX = 0.7893,
        fromY = 0.2197,
        toPointID = 100459,
        toMap = 1021,
        toX = 0.5022,
        toY = 0.3592,
        type = "gossip",
        travelDuration = 10,
        gossip = {
            gossipOptionID = 47635,
            npcID = 128607,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "any",
                    children = {
                        {
                            operation = "all",
                            children = {
                                {
                                    operation = "check",
                                    kind = "faction",
                                    value = "Horde",
                                },
                                {
                                    operation = "check",
                                    kind = "questActiveOrComplete",
                                    value = 50769,
                                },
                            },
                        },
                        {
                            operation = "all",
                            children = {
                                {
                                    operation = "check",
                                    kind = "faction",
                                    value = "Alliance",
                                },
                                {
                                    operation = "check",
                                    kind = "questActiveOrComplete",
                                    value = 46728,
                                },
                            },
                        },
                    },
                },
                {
                    operation = "check",
                    kind = "mapArtID",
                    value = {
                        81,
                        86,
                    },
                },
            },
        },
    },

    -- Zone: Siren Isle (map 2369)
    -- Siren Isle (map 2369 70.69,53.49) -> Dornogal (map 2339 73.55,5.29) via gossip
    {
        fromPointID = 1200158,
        fromMap = 2369,
        fromX = 0.7069,
        fromY = 0.5349,
        toPointID = 1200134,
        toMap = 2339,
        toX = 0.7355,
        toY = 0.0529,
        type = "gossip",
        travelDuration = 10,
        gossip = {
            gossipOptionID = 125349,
            npcID = 231541,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "any",
                    children = {
                        {
                            operation = "check",
                            kind = "questActive",
                            value = 84720,
                        },
                        {
                            operation = "check",
                            kind = "questCompleted",
                            value = 84720,
                        },
                    },
                },
            },
        },
    },

    -- Zone: Stormsong Valley (map 942)
    -- Stormsong Valley (map 942 51.43,33.75) -> Zuldazar (map 862 58.40,62.50) via gossip
    {
        fromPointID = 800048,
        fromMap = 942,
        fromX = 0.5143,
        fromY = 0.3375,
        toPointID = 900023,
        toMap = 862,
        toX = 0.584,
        toY = 0.625,
        type = "gossip",
        travelDuration = 1,
        gossip = {
            gossipOptionID = 48826,
            npcID = 138097,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "faction",
                    value = "Horde",
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 51696,
                },
            },
        },
    },
    -- Stormsong Valley (map 942 51.95,24.46) -> Zuldazar (map 862 58.40,62.50) via gossip
    {
        fromPointID = 800049,
        fromMap = 942,
        fromX = 0.5195,
        fromY = 0.2446,
        toPointID = 900023,
        toMap = 862,
        toX = 0.584,
        toY = 0.625,
        type = "gossip",
        travelDuration = 1,
        gossip = {
            gossipOptionID = 49160,
            npcID = 143282,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "faction",
                    value = "Horde",
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 51532,
                },
            },
        },
    },

    -- Zone: Stormwind City (map 84)
    -- Stormwind City (map 84 62.26,72.96) -> Elwynn Forest (map 37 41.87,68.17) via gossip
    {
        fromPointID = 200310,
        fromMap = 84,
        fromX = 0.6226,
        fromY = 0.7296,
        toPointID = 200180,
        toMap = 37,
        toX = 0.4187,
        toY = 0.6817,
        type = "gossip",
        gossip = {
            gossipOptionID = 40457,
            npcID = 54334,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "event",
                    value = "DARKMOON FAIRE",
                },
                {
                    operation = "check",
                    kind = "faction",
                    value = "Alliance",
                },
            },
        },
    },

    -- Zone: The Vindicaar (map 831)
    -- Krokuun (map 831 43.42,23.19) -> Arcatraz L (map 889 41.20,74.29) via gossip
    {
        fromPointID = 700288,
        fromMap = 831,
        fromX = 0.4342,
        fromY = 0.2319,
        toPointID = 300163,
        toMap = 889,
        toX = 0.412,
        toY = 0.7429,
        type = "gossip",
        travelDuration = 10,
        gossip = {
            gossipOptionID = 46719,
            npcID = 121263,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "questActive",
                    value = 47134,
                },
            },
        },
    },

    -- Zone: Tiragarde Sound (map 895)
    -- Tiragarde Sound (map 895 87.85,51.18) -> Zuldazar (map 862 58.40,62.50) via gossip
    {
        fromPointID = 800017,
        fromMap = 895,
        fromX = 0.8785,
        fromY = 0.5118,
        toPointID = 900023,
        toMap = 862,
        toX = 0.584,
        toY = 0.625,
        type = "gossip",
        travelDuration = 1,
        gossip = {
            gossipOptionID = 48794,
            npcID = 139524,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "faction",
                    value = "Horde",
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 51421,
                },
            },
        },
    },

    -- Zone: Vaults of Atal'Utek (map 2509)
    -- All five stations use NPC 272197. Neither taxi discovery nor personal flight unlocks them.
    -- Amani Foothold -> Eastern Amani Outpost via Amani Windcaller
    {
        fromPointID = 1500036,
        fromMap = 2509,
        fromX = 0.4999,
        fromY = 0.6189,
        toPointID = 1500037,
        toMap = 2509,
        toX = 0.5431,
        toY = 0.3947,
        type = "gossip",
        travelDuration = 24,
        gossip = {
            gossipOptionID = 141707,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Eastern Amani Outpost",
        },
        requirement = WINDCALLER_REQUIREMENT,
    },
    -- Amani Foothold -> Northern Amani Bulwark via Amani Windcaller
    {
        fromPointID = 1500036,
        fromMap = 2509,
        fromX = 0.4999,
        fromY = 0.6189,
        toPointID = 1500038,
        toMap = 2509,
        toX = 0.4153,
        toY = 0.2341,
        type = "gossip",
        travelDuration = 34,
        gossip = {
            gossipOptionID = 141705,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Northern Amani Bulwark",
        },
        requirement = WINDCALLER_REQUIREMENT,
    },
    -- Amani Foothold -> The Venomous Abyss via Amani Windcaller
    {
        fromPointID = 1500036,
        fromMap = 2509,
        fromX = 0.4999,
        fromY = 0.6189,
        toPointID = 1500039,
        toMap = 2509,
        toX = 0.4845,
        toY = 0.2704,
        type = "gossip",
        travelDuration = 27,
        gossip = {
            gossipOptionID = 141706,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Venomous Abyss",
        },
        requirement = SPECTRAL_SHIPPING_REQUIREMENT,
    },
    -- Amani Foothold -> The Underbelly via Amani Windcaller
    {
        fromPointID = 1500036,
        fromMap = 2509,
        fromX = 0.4999,
        fromY = 0.6189,
        toPointID = 1500040,
        toMap = 2509,
        toX = 0.4557,
        toY = 0.1165,
        type = "gossip",
        travelDuration = 43,
        gossip = {
            gossipOptionID = 141704,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Underbelly",
        },
        requirement = SPECTRAL_SHIPPING_REQUIREMENT,
    },
    -- Eastern Amani Outpost -> Amani Foothold via Amani Windcaller
    {
        fromPointID = 1500037,
        fromMap = 2509,
        fromX = 0.5431,
        fromY = 0.3947,
        toPointID = 1500036,
        toMap = 2509,
        toX = 0.4999,
        toY = 0.6189,
        type = "gossip",
        travelDuration = 24,
        gossip = {
            gossipOptionID = 141712,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Amani Foothold",
        },
        requirement = WINDCALLER_REQUIREMENT,
    },
    -- Eastern Amani Outpost -> Northern Amani Bulwark via Amani Windcaller
    {
        fromPointID = 1500037,
        fromMap = 2509,
        fromX = 0.5431,
        fromY = 0.3947,
        toPointID = 1500038,
        toMap = 2509,
        toX = 0.4153,
        toY = 0.2341,
        type = "gossip",
        travelDuration = 23,
        gossip = {
            gossipOptionID = 141710,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Northern Amani Bulwark",
        },
        requirement = WINDCALLER_REQUIREMENT,
    },
    -- Eastern Amani Outpost -> The Venomous Abyss via Amani Windcaller
    {
        fromPointID = 1500037,
        fromMap = 2509,
        fromX = 0.5431,
        fromY = 0.3947,
        toPointID = 1500039,
        toMap = 2509,
        toX = 0.4845,
        toY = 0.2704,
        type = "gossip",
        travelDuration = 15,
        gossip = {
            gossipOptionID = 141711,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Venomous Abyss",
        },
        requirement = SPECTRAL_SHIPPING_REQUIREMENT,
    },
    -- Eastern Amani Outpost -> The Underbelly via Amani Windcaller
    {
        fromPointID = 1500037,
        fromMap = 2509,
        fromX = 0.5431,
        fromY = 0.3947,
        toPointID = 1500040,
        toMap = 2509,
        toX = 0.4557,
        toY = 0.1165,
        type = "gossip",
        travelDuration = 32,
        gossip = {
            gossipOptionID = 141709,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Underbelly",
        },
        requirement = SPECTRAL_SHIPPING_REQUIREMENT,
    },
    -- Northern Amani Bulwark -> Amani Foothold via Amani Windcaller
    {
        fromPointID = 1500038,
        fromMap = 2509,
        fromX = 0.4153,
        fromY = 0.2341,
        toPointID = 1500036,
        toMap = 2509,
        toX = 0.4999,
        toY = 0.6189,
        type = "gossip",
        travelDuration = 35,
        gossip = {
            gossipOptionID = 141722,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Amani Foothold",
        },
        requirement = WINDCALLER_REQUIREMENT,
    },
    -- Northern Amani Bulwark -> Eastern Amani Outpost via Amani Windcaller
    {
        fromPointID = 1500038,
        fromMap = 2509,
        fromX = 0.4153,
        fromY = 0.2341,
        toPointID = 1500037,
        toMap = 2509,
        toX = 0.5431,
        toY = 0.3947,
        type = "gossip",
        travelDuration = 23,
        gossip = {
            gossipOptionID = 141721,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Eastern Amani Outpost",
        },
        requirement = WINDCALLER_REQUIREMENT,
    },
    -- Northern Amani Bulwark -> The Venomous Abyss via Amani Windcaller
    {
        fromPointID = 1500038,
        fromMap = 2509,
        fromX = 0.4153,
        fromY = 0.2341,
        toPointID = 1500039,
        toMap = 2509,
        toX = 0.4845,
        toY = 0.2704,
        type = "gossip",
        travelDuration = 8,
        gossip = {
            gossipOptionID = 141720,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Venomous Abyss",
        },
        requirement = SPECTRAL_SHIPPING_REQUIREMENT,
    },
    -- Northern Amani Bulwark -> The Underbelly via Amani Windcaller
    {
        fromPointID = 1500038,
        fromMap = 2509,
        fromX = 0.4153,
        fromY = 0.2341,
        toPointID = 1500040,
        toMap = 2509,
        toX = 0.4557,
        toY = 0.1165,
        type = "gossip",
        travelDuration = 10,
        gossip = {
            gossipOptionID = 141719,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Underbelly",
        },
        requirement = SPECTRAL_SHIPPING_REQUIREMENT,
    },
    -- The Venomous Abyss -> Amani Foothold via Amani Windcaller
    {
        fromPointID = 1500039,
        fromMap = 2509,
        fromX = 0.4845,
        fromY = 0.2704,
        toPointID = 1500036,
        toMap = 2509,
        toX = 0.4999,
        toY = 0.6189,
        type = "gossip",
        travelDuration = 27,
        gossip = {
            gossipOptionID = 141717,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Amani Foothold",
        },
        requirement = WINDCALLER_REQUIREMENT,
    },
    -- The Venomous Abyss -> Eastern Amani Outpost via Amani Windcaller
    {
        fromPointID = 1500039,
        fromMap = 2509,
        fromX = 0.4845,
        fromY = 0.2704,
        toPointID = 1500037,
        toMap = 2509,
        toX = 0.5431,
        toY = 0.3947,
        type = "gossip",
        travelDuration = 15,
        gossip = {
            gossipOptionID = 141716,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Eastern Amani Outpost",
        },
        requirement = WINDCALLER_REQUIREMENT,
    },
    -- The Venomous Abyss -> Northern Amani Bulwark via Amani Windcaller
    {
        fromPointID = 1500039,
        fromMap = 2509,
        fromX = 0.4845,
        fromY = 0.2704,
        toPointID = 1500038,
        toMap = 2509,
        toX = 0.4153,
        toY = 0.2341,
        type = "gossip",
        travelDuration = 8,
        gossip = {
            gossipOptionID = 141715,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Northern Amani Bulwark",
        },
        requirement = WINDCALLER_REQUIREMENT,
    },
    -- The Venomous Abyss -> The Underbelly via Amani Windcaller
    {
        fromPointID = 1500039,
        fromMap = 2509,
        fromX = 0.4845,
        fromY = 0.2704,
        toPointID = 1500040,
        toMap = 2509,
        toX = 0.4557,
        toY = 0.1165,
        type = "gossip",
        travelDuration = 19,
        gossip = {
            gossipOptionID = 141714,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Underbelly",
        },
        requirement = SPECTRAL_SHIPPING_REQUIREMENT,
    },
    -- The Underbelly -> Amani Foothold via Amani Windcaller
    {
        fromPointID = 1500040,
        fromMap = 2509,
        fromX = 0.4557,
        fromY = 0.1165,
        toPointID = 1500036,
        toMap = 2509,
        toX = 0.4999,
        toY = 0.6189,
        type = "gossip",
        travelDuration = 43,
        gossip = {
            gossipOptionID = 141727,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Amani Foothold",
        },
        requirement = WINDCALLER_REQUIREMENT,
    },
    -- The Underbelly -> Eastern Amani Outpost via Amani Windcaller
    {
        fromPointID = 1500040,
        fromMap = 2509,
        fromX = 0.4557,
        fromY = 0.1165,
        toPointID = 1500037,
        toMap = 2509,
        toX = 0.5431,
        toY = 0.3947,
        type = "gossip",
        travelDuration = 32,
        gossip = {
            gossipOptionID = 141726,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Eastern Amani Outpost",
        },
        requirement = WINDCALLER_REQUIREMENT,
    },
    -- The Underbelly -> Northern Amani Bulwark via Amani Windcaller
    {
        fromPointID = 1500040,
        fromMap = 2509,
        fromX = 0.4557,
        fromY = 0.1165,
        toPointID = 1500038,
        toMap = 2509,
        toX = 0.4153,
        toY = 0.2341,
        type = "gossip",
        travelDuration = 10,
        gossip = {
            gossipOptionID = 141724,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Northern Amani Bulwark",
        },
        requirement = WINDCALLER_REQUIREMENT,
    },
    -- The Underbelly -> The Venomous Abyss via Amani Windcaller
    {
        fromPointID = 1500040,
        fromMap = 2509,
        fromX = 0.4557,
        fromY = 0.1165,
        toPointID = 1500039,
        toMap = 2509,
        toX = 0.4845,
        toY = 0.2704,
        type = "gossip",
        travelDuration = 19,
        gossip = {
            gossipOptionID = 141725,
            npcID = 272197,
            destinationNameKey = "Navigation Destination Venomous Abyss",
        },
        requirement = SPECTRAL_SHIPPING_REQUIREMENT,
    },

    -- Zone: Vol'dun (map 864)
    -- Vol'dun (map 864 36.69,34.28) -> Boralus (map 1161 70.22,27.06) via gossip
    {
        fromPointID = 900057,
        fromMap = 864,
        fromX = 0.3669,
        fromY = 0.3428,
        toPointID = 800083,
        toMap = 1161,
        toX = 0.7022,
        toY = 0.2706,
        type = "gossip",
        travelDuration = 1,
        gossip = {
            gossipOptionID = 49007,
            npcID = 135383,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "faction",
                    value = "Alliance",
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 51229,
                },
            },
        },
    },

    -- Zone: Zuldazar (map 862)
    -- Zuldazar (map 862 40.46,71.03) -> Boralus (map 1161 70.22,27.06) via gossip
    {
        fromPointID = 900006,
        fromMap = 862,
        fromX = 0.4046,
        fromY = 0.7103,
        toPointID = 800083,
        toMap = 1161,
        toX = 0.7022,
        toY = 0.2706,
        type = "gossip",
        travelDuration = 1,
        gossip = {
            gossipOptionID = 49161,
            npcID = 143334,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "faction",
                    value = "Alliance",
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 51418,
                },
            },
        },
    },
    -- Zuldazar (map 862 58.46,62.99) -> Tiragarde Sound (map 895 88.20,51.16) via gossip
    {
        fromPointID = 900024,
        fromMap = 862,
        fromX = 0.5846,
        fromY = 0.6299,
        toPointID = 800019,
        toMap = 895,
        toX = 0.882,
        toY = 0.5116,
        type = "gossip",
        travelDuration = 1,
        gossip = {
            gossipOptionID = 48350,
            npcID = 135690,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "faction",
                    value = "Horde",
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 51800,
                },
            },
        },
    },
    -- Zuldazar (map 862 58.46,62.99) -> Drustvar (map 896 20.61,43.69) via gossip
    {
        fromPointID = 900024,
        fromMap = 862,
        fromX = 0.5846,
        fromY = 0.6299,
        toPointID = 800023,
        toMap = 896,
        toX = 0.2061,
        toY = 0.4369,
        type = "gossip",
        travelDuration = 1,
        gossip = {
            gossipOptionID = 48348,
            npcID = 135690,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "faction",
                    value = "Horde",
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 51801,
                },
            },
        },
    },
    -- Zuldazar (map 862 58.46,62.99) -> Stormsong Valley (map 942 51.98,24.49) via gossip
    {
        fromPointID = 900024,
        fromMap = 862,
        fromX = 0.5846,
        fromY = 0.6299,
        toPointID = 800050,
        toMap = 942,
        toX = 0.5198,
        toY = 0.2449,
        type = "gossip",
        travelDuration = 1,
        gossip = {
            gossipOptionID = 48349,
            npcID = 135690,
        },
        requirement = {
            operation = "all",
            children = {
                {
                    operation = "check",
                    kind = "faction",
                    value = "Horde",
                },
                {
                    operation = "check",
                    kind = "questCompleted",
                    value = 51802,
                },
            },
        },
    },
}

Navigation:RegisterPathData("gossip", GOSSIP)
