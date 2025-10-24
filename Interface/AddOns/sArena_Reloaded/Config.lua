local LSM = LibStub("LibSharedMedia-3.0")
local isRetail = sArenaMixin.isRetail

local function GetSpellInfoCompat(spellID)
    if not spellID then
        return nil
    end

    if GetSpellInfo then
        return GetSpellInfo(spellID)
    end

    if C_Spell and C_Spell.GetSpellInfo then
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
            return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
        end
    end

    return nil
end

local function GetSpellDescriptionCompat(spellID)
    if not spellID then
        return ""
    end

    if GetSpellDescription then
        return GetSpellDescription(spellID) or ""
    end

    if C_Spell and C_Spell.GetSpellDescription then
        return C_Spell.GetSpellDescription(spellID) or ""
    end

    return ""
end

local function getLayoutTable()
    local t = {}

    for k, _ in pairs(sArenaMixin.layouts) do
        t[k] = sArenaMixin.layouts[k].name and sArenaMixin.layouts[k].name or k
    end

    return t
end

local function validateCombat()
    if (InCombatLockdown()) then
        return "Must leave combat first."
    end

    return true
end

local growthValues = { "Down", "Up", "Right", "Left" }
local drCategories
local racialCategories
local dispelCategories
local drIcons
local drCategorieslist

if isRetail then

    racialCategories = {}
    for raceKey, data in pairs(sArenaMixin.racialData or {}) do
        local name = raceKey
        local texture = data and data.texture
        if texture then
            if type(texture) == "string" then
                racialCategories[raceKey] = "|T" .. texture .. ":16|t " .. name
            else
                racialCategories[raceKey] = "|T" .. tostring(texture) .. ":16|t " .. name
            end
        else
            racialCategories[raceKey] = name
        end
    end

    -- Load dispel categories from dispelData
    dispelCategories = {}
    for spellID, data in pairs(sArenaMixin.dispelData or {}) do
        dispelCategories[spellID] = "|T" .. data.texture .. ":16|t " .. data.name .. " (" .. data.classes .. ")"
    end

    drIcons = {
        ["Stun"] = 132298,
        ["Incapacitate"] = 136071,
        ["Disorient"] = 136183,
        ["Silence"] = 458230,
        ["Root"] = 136100,
        ["Knock"] = 237589,
        ["Disarm"] = 132343,
    }

    drCategories = {}
    for category, tex in pairs(drIcons) do
        drCategories[category] = "|T" .. tostring(tex) .. ":16|t " .. category
    end
    drCategorieslist = {
        "Incapacitate",
        "Stun",
        "Root",
        "Disarm",
        "Disorient",
        "Silence",
        "Knock",
    }
else
    drCategories = {
        ["Incapacitate"] = "Incapacitate",
        ["Stun"] = "Stun",
        ["Root"] = "Root",
        ["Fear"] = "Fear",
        ["Silence"] = "Silence",
        ["Disarm"] = "Disarm",
        ["Disorient"] = "Disorient",
        ["Horror"] = "Horror",
        ["Cyclone"] = "Cyclone",
        ["MindControl"] = "MindControl",
        ["RandomStun"] = "RandomStun",
        ["RandomRoot"] = "RandomRoot",
        ["Charge"] = "Charge",
    }

    racialCategories = {}
    for raceKey, data in pairs(sArenaMixin.racialData or {}) do
        local name = raceKey
        local texture = data and data.texture
        if texture then
            if type(texture) == "string" then
                racialCategories[raceKey] = "|T" .. texture .. ":16|t " .. name
            else
                racialCategories[raceKey] = "|T" .. tostring(texture) .. ":16|t " .. name
            end
        else
            racialCategories[raceKey] = name
        end
    end

    -- Load dispel categories from dispelData  
    dispelCategories = {}
    for spellID, data in pairs(sArenaMixin.dispelData or {}) do
        dispelCategories[spellID] = "|T" .. (data.texture or "134400") .. ":16|t " .. data.name .. " (" .. data.classes .. ")"
    end

    drIcons = {
        ["Incapacitate"] = 136071,
        ["Stun"] = 132298,
        ["RandomStun"] = 133477,
        ["RandomRoot"] = 135852,
        ["Root"] = 135848,
        ["Disarm"] = 132343,
        ["Fear"] = 136183,
        ["Disorient"] = 134153,
        ["Silence"] = 458230,
        ["Horror"] = 237568,
        ["MindControl"] = 136206,
        ["Cyclone"] = 136022,
        ["Charge"] = 132337,
    }

    drCategories = {}
    for category, tex in pairs(drIcons) do
        drCategories[category] = "|T" .. tostring(tex) .. ":16|t " .. category
    end
    drCategorieslist = {
        "Incapacitate",
        "Stun",
        "RandomStun",
        "RandomRoot",
        "Root",
        "Disarm",
        "Fear",
        "Disorient",
        "Silence",
        "Horror",
        "MindControl",
        "Cyclone",
        "Charge",
    }
end


local function StatusbarValues()
    local t, keys = {}, {}
    for k in pairs(LSM:HashTable(LSM.MediaType.STATUSBAR)) do keys[#keys+1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do t[k] = k end
    return t
end

function sArenaMixin:GetLayoutOptionsTable(layoutName)
        local function LDB(info)
        return info.handler.db.profile.layoutSettings[layoutName]
    end
    local function getSetting(info)
        return LDB(info)[info[#info]]
    end
    local function getFontOutlineSetting(info)
        local value = LDB(info)[info[#info]]
        if value == nil then
            return "OUTLINE"
        end
        return value
    end
    local function setSetting(info, val)
        local db = LDB(info)
        db[info[#info]] = val

        if self.RefreshConfig then self:RefreshConfig() end
    end

    local optionsTable = {
        arenaFrames = {
            order = 1,
            name = "Arena Frames",
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName][info[#info]] end,
            set = function(info, val)
                self:UpdateFrameSettings(info.handler.db.profile.layoutSettings[layoutName], info,
                    val)
            end,
            args = {
                textures = {
                    order  = 0.1,
                    name   = "Textures",
                    type   = "group",
                    inline = true,
                    args   = {
                        generalTexture = {
                            order         = 1,
                            type          = "select",
                            name          = "|A:UI-LFG-RoleIcon-DPS-Micro:20:20|a General Texture",
                            desc          = "Tip: If you have replaced your default WoW Textures with custom ones and want that then select \"Blizzard Raid Bar\".",
                            style         = "dropdown",
                            dialogControl = "LSM30_Statusbar",
                            values        = StatusbarValues,
                            get           = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local t = layout.textures
                                return (t and t.generalStatusBarTexture) or "sArena Default"
                            end,
                            set           = function(info, key)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                }
                                layout.textures.generalStatusBarTexture = key
                                info.handler:UpdateTextures()
                            end,
                        },
                        healerTexture = {
                            order         = 2,
                            type          = "select",
                            name          = "|A:UI-LFG-RoleIcon-Healer-Micro:20:20|a Healer Texture",
                            desc          = "Tip: Only active when there is Class Stacking by default. Uncheck \"Class Stacking Only\" if you want it to always change the texture.",
                            style         = "dropdown",
                            dialogControl = "LSM30_Statusbar",
                            values        = StatusbarValues,
                            get           = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local t = layout.textures
                                return (t and t.healStatusBarTexture) or "sArena Default"
                            end,
                            set           = function(info, key)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                }
                                layout.textures.healStatusBarTexture = key
                                info.handler:UpdateTextures()
                            end,
                        },
                        healerClassStackOnly = {
                            order = 3,
                            type  = "toggle",
                            name  = "Class Stacking Only",
                            desc  =
                            "Only change the Healer texture when there is class stacking.\n\nFor example when there is both a Resto and a Feral Druid on the enemy team.",
                            get   = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                return layout.retextureHealerClassStackOnly or false
                            end,
                            set   = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.retextureHealerClassStackOnly = val
                                info.handler:UpdateTextures()
                            end,
                            width = "75%",
                        },
                    },
                },
                other = {
                    order  = 0.5,
                    name   = "Options",
                    type   = "group",
                    inline = true,
                    args   = {
                        replaceClassIcon = {
                            order = 2,
                            type  = "toggle",
                            name  = "Replace Class Icon",
                            desc  = "Replace the class icon with spec icon instead and hide the little \"spec icon button\"",
                            get   = getSetting,
                            set   = setSetting,
                        },
                    },
                },
                positioning = {
                    order = 1,
                    name = "Positioning",
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = "Horizontal",
                            type = "range",
                            min = -1000,
                            max = 1000,
                            step = 0.1,
                            bigStep = 1,
                        },
                        posY = {
                            order = 2,
                            name = "Vertical",
                            type = "range",
                            min = -1000,
                            max = 1000,
                            step = 0.1,
                            bigStep = 1,
                        },
                        spacing = {
                            order = 3,
                            name = "Spacing",
                            desc = "Spacing between each arena frame",
                            type = "range",
                            min = 0,
                            max = 100,
                            step = 1,
                        },
                        growthDirection = {
                            order = 4,
                            name = "Growth Direction",
                            type = "select",
                            style = "dropdown",
                            values = growthValues,
                        },
                    },
                },
                sizing = {
                    order = 0.3,
                    name = "Sizing",
                    type = "group",
                    inline = true,
                    args = {
                        scale = {
                            order = 1,
                            name = "Scale",
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.1,
                            isPercent = true,
                        },
                        classIconFontSize = {
                            order = 2,
                            name = "Class Icon CD Font Size",
                            desc = "Only works with Blizzard cooldown count (not OmniCC)",
                            type = "range",
                            min = 2,
                            max = 48,
                            softMin = 4,
                            softMax = 32,
                            step = 1,
                        },
                    },
                },
            },
        },
        specIcon = {
            order = 2,
            name = "Spec Icons",
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].specIcon[info[#info]] end,
            set = function(info, val)
                self:UpdateSpecIconSettings(
                    info.handler.db.profile.layoutSettings[layoutName].specIcon, info, val)
            end,
            args = {
                positioning = {
                    order = 1,
                    name = "Positioning",
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = "Horizontal",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                        posY = {
                            order = 2,
                            name = "Vertical",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                    },
                },
                sizing = {
                    order = 2,
                    name = "Sizing",
                    type = "group",
                    inline = true,
                    args = {
                        scale = {
                            order = 1,
                            name = "Scale",
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.1,
                            isPercent = true,
                        },
                    },
                },
            },
        },
        trinket = {
            order = 3,
            name = "Trinkets",
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].trinket[info[#info]] end,
            set = function(info, val)
                self:UpdateTrinketSettings(
                    info.handler.db.profile.layoutSettings[layoutName].trinket, info, val)
            end,
            args = {
                positioning = {
                    order = 1,
                    name = "Positioning",
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = "Horizontal",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                        posY = {
                            order = 2,
                            name = "Vertical",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                    },
                },
                sizing = {
                    order = 2,
                    name = "Sizing",
                    type = "group",
                    inline = true,
                    args = {
                        scale = {
                            order = 1,
                            name = "Scale",
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.001,
                            bigStep = 0.1,
                            isPercent = true,
                        },
                        fontSize = {
                            order = 3,
                            name = "Font Size",
                            desc = "Only works with Blizzard cooldown count (not OmniCC)",
                            type = "range",
                            min = 2,
                            max = 48,
                            softMin = 4,
                            softMax = 32,
                            step = 1,
                        },
                    },
                },
            },
        },
        racial = {
            order = 4,
            name = "Racials",
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].racial[info[#info]] end,
            set = function(info, val)
                self:UpdateRacialSettings(
                    info.handler.db.profile.layoutSettings[layoutName].racial, info, val)
            end,
            args = {
                positioning = {
                    order = 1,
                    name = "Positioning",
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = "Horizontal",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                        posY = {
                            order = 2,
                            name = "Vertical",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                    },
                },
                sizing = {
                    order = 2,
                    name = "Sizing",
                    type = "group",
                    inline = true,
                    args = {
                        scale = {
                            order = 1,
                            name = "Scale",
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.001,
                            bigStep = 0.1,
                            isPercent = true,
                        },
                        fontSize = {
                            order = 3,
                            name = "Font Size",
                            desc = "Only works with Blizzard cooldown count (not OmniCC)",
                            type = "range",
                            min = 2,
                            max = 48,
                            softMin = 4,
                            softMax = 32,
                            step = 1,
                        },
                    },
                },
            },
        },
        dispel = {
            order = 4.5,
            name = "Dispels",
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].dispel[info[#info]] end,
            set = function(info, val)
                self:UpdateDispelSettings(
                    info.handler.db.profile.layoutSettings[layoutName].dispel, info, val)
            end,
            args = {
                positioning = {
                    order = 1,
                    name = "Positioning",
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = "Horizontal",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                        posY = {
                            order = 2,
                            name = "Vertical",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                    },
                },
                sizing = {
                    order = 2,
                    name = "Sizing",
                    type = "group",
                    inline = true,
                    args = {
                        scale = {
                            order = 1,
                            name = "Scale",
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.001,
                            bigStep = 0.1,
                            isPercent = true,
                        },
                        fontSize = {
                            order = 3,
                            name = "Font Size",
                            desc = "Only works with Blizzard cooldown count (not OmniCC)",
                            type = "range",
                            min = 2,
                            max = 48,
                            softMin = 4,
                            softMax = 32,
                            step = 1,
                        },
                    },
                },
            },
        },
        castBar = {
            order = 5,
            name = "Cast Bars",
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].castBar[info[#info]] end,
            set = function(info, val)
                self:UpdateCastBarSettings(info.handler.db.profile.layoutSettings[layoutName].castBar, info, val)
                if sArenaMixin.RefreshMasque then
                    sArenaMixin:RefreshMasque()
                end
            end,
            args = {
                castBarLook = {
                    order  = 0,
                    name   = "Castbar Look",
                    type   = "group",
                    inline = true,
                    args   = {
                        useModernCastbars = {
                            order = 1,
                            type  = "toggle",
                            name  = "Use modern castbars",
                            desc  = "Use the new modern retail castbars.",
                            width = "75%",
                            set   = function(info, val)
                                local castDB = info.handler.db.profile.layoutSettings[layoutName].castBar
                                castDB.useModernCastbars = val
                                info.handler:RefreshConfig()
                            end,
                        },

                        keepDefaultModernTextures = {
                            order    = 2,
                            type     = "toggle",
                            name     = "Keep default modern textures",
                            width    = "90%",
                            desc     = "Keeps the new modern textures for modern castbars. Ignores the set texture.",
                            disabled = function(info)
                                return not info.handler.db.profile.layoutSettings[layoutName].castBar.useModernCastbars
                            end,
                            set      = function(info, val)
                                local castDB = info.handler.db.profile.layoutSettings[layoutName].castBar
                                castDB.keepDefaultModernTextures = val
                                info.handler:RefreshConfig()
                            end,
                        },

                        simpleCastbar = {
                            order    = 2.3,
                            type     = "toggle",
                            name     = "Simple Castbar",
                            width    = "75%",
                            desc     = "Hides the castbar text background and moves the castbar text inside the castbar.",
                            disabled = function(info)
                                return not info.handler.db.profile.layoutSettings[layoutName].castBar.useModernCastbars
                            end,
                            get      = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.simpleCastbar
                            end,
                            set      = function(info, val)
                                local castDB = info.handler.db.profile.layoutSettings[layoutName].castBar
                                castDB.simpleCastbar = val
                                info.handler:RefreshConfig()
                            end,
                        },

                        spacerOne = {
                            order = 2.4,
                            type  = "description",
                            name  = "",
                            width = "full",
                        },

                        hideBorderShield = {
                            order = 2.5,
                            name = "Hide Shield on Un-Interruptible",
                            desc = "Hides the shield texture around spell icon on un-interruptible casts.",
                            type = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.hideBorderShield
                            end,
                            set = function(info, val)
                                info.handler.db.profile.layoutSettings[layoutName].castBar.hideBorderShield = val
                                info.handler:UpdateCastBarSettings(info.handler.db.profile.layoutSettings[layoutName].castBar, info, val)
                            end,
                        },

                        hideCastbarSpark = {
                            order = 2.6,
                            name = "Hide Castbar Spark",
                            desc = "Hides the trailing spark on the castbar",
                            type = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.hideCastbarSpark
                            end,
                            set = function(info, val)
                                info.handler.db.profile.layoutSettings[layoutName].castBar.hideCastbarSpark = val
                                info.handler:UpdateCastBarSettings(info.handler.db.profile.layoutSettings[layoutName].castBar, info, val)
                            end,
                        },

                        spacer = {
                            order = 2.9,
                            type  = "description",
                            name  = "",
                            width = "full",
                        },

                        castbarStatusBarTexture = {
                            order         = 3,
                            type          = "select",
                            name          = "|A:GarrMission_ClassIcon-DemonHunter-Outcast:20:20|a Castbar Texture",
                            style         = "dropdown",
                            dialogControl = "LSM30_Statusbar",
                            values        = StatusbarValues,
                            get           = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local t = layout.textures
                                return (t and t.castbarStatusBarTexture) or "sArena Default"
                            end,
                            set           = function(info, key)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                }
                                layout.textures.castbarStatusBarTexture = key
                                info.handler:UpdateTextures()
                            end,
                            width         = "75%",
                            disabled      = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.useModernCastbars and info.handler.db.profile.layoutSettings[layoutName].castBar.keepDefaultModernTextures
                            end,
                        },
                    },
                },
                castbarPosition = {
                    order = 1,
                    name = "Castbar Position",
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = "Horizontal",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                        posY = {
                            order = 2,
                            name = "Vertical",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                    },
                },
                iconPosition = {
                    order = 3,
                    name = "Icon Position",
                    type = "group",
                    inline = true,
                    args = {
                        iconPosX = {
                            order = 1,
                            name = "Horizontal",
                            type = "range",
                            min = -500,
                            max = 500,
                            softMin = -200,
                            softMax = 200,
                            step = 0.1,
                            bigStep = 1,
                        },
                        iconPosY = {
                            order = 2,
                            name = "Vertical",
                            type = "range",
                            min = -500,
                            max = 500,
                            softMin = -200,
                            softMax = 200,
                            step = 0.1,
                            bigStep = 1,
                        },
                    },
                },
                castbarSize = {
                    order = 2,
                    name = "Castbar Size",
                    type = "group",
                    inline = true,
                    args = {
                        scale = {
                            order = 1,
                            name = "Scale",
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.1,
                            isPercent = true,
                        },
                        width = {
                            order = 2,
                            name = "Width",
                            type = "range",
                            min = 10,
                            max = 400,
                            step = 1,
                        },
                    },
                },
                iconSize = {
                    order = 4,
                    name = "Icon Size",
                    type = "group",
                    inline = true,
                    args = {
                        iconScale = {
                            order = 1,
                            name = "Icon Scale",
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.1,
                            isPercent = true,
                        },
                    },
                },
            },
        },
        dr = {
            order = 6,
            name = "Diminishing Returns",
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].dr[info[#info]] end,
            set = function(info, val)
                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                if sArenaMixin.RefreshMasque then
                    sArenaMixin:RefreshMasque()
                end
            end,
            args = {
                brightDRBorder = {
                    order = 0,
                    name  = "Bright DR Border",
                    type  = "toggle",
                    get = function(info)
                        return info.handler.db.profile.layoutSettings[layoutName].dr.brightDRBorder
                    end,
                    set = function(info, val)
                        local db = info.handler.db.profile.layoutSettings[layoutName].dr
                        db.brightDRBorder = val
                        self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                    end,
                },
                blackDRBorder = {
                    order = 0.5,
                    name  = "Black DR Border",
                    type  = "toggle",
                    desc  = "Makes DR borders black. Combine this with Global Settings -> DR -> Show DR Text",
                    get = function(info)
                        return info.handler.db.profile.layoutSettings[layoutName].dr.blackDRBorder
                    end,
                    set = function(info, val)
                        local db = info.handler.db.profile.layoutSettings[layoutName].dr
                        db.blackDRBorder = val
                        self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                        info.handler:RefreshConfig()
                        info.handler:Test()
                    end,
                },
                positioning = {
                    order = 1,
                    name = "Positioning",
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = "Horizontal",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                        posY = {
                            order = 2,
                            name = "Vertical",
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                        spacing = {
                            order = 3,
                            name = "Spacing",
                            type = "range",
                            min = 0,
                            max = 32,
                            softMin = 0,
                            softMax = 32,
                            step = 1,
                        },
                        growthDirection = {
                            order = 4,
                            name = "Growth Direction",
                            type = "select",
                            style = "dropdown",
                            values = growthValues,
                        },
                    },
                },
                sizing = {
                    order = 2,
                    name = "Sizing",
                    type = "group",
                    inline = true,
                    args = {
                        size = {
                            order = 1,
                            name = "Size",
                            type = "range",
                            min = 2,
                            max = 128,
                            softMin = 8,
                            softMax = 64,
                            step = 1,
                        },
                        borderSize = {
                            order = 2,
                            name = "Border Size",
                            type = "range",
                            min = 0,
                            max = 24,
                            softMin = 1,
                            softMax = 16,
                            step = 0.1,
                            bigStep = 1,
                            disabled = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].dr.brightDRBorder
                            end,
                        },
                        fontSize = {
                            order = 3,
                            name = "Font Size",
                            desc = "Only works with Blizzard cooldown count (not OmniCC)",
                            type = "range",
                            min = 2,
                            max = 48,
                            softMin = 4,
                            softMax = 32,
                            step = 1,
                        },
                    },
                },
                drCategorySizing = {
                    order = 3,
                    name = "DR Specific Size Adjustment",
                    type = "group",
                    inline = true,
                    args = {},
                },
            },
        },
    }

    local drCategoryOrder = {
        Incapacitate = 1,
        Stun         = 2,
        Root         = 3,
        Silence      = 4,
        Disarm       = 5,
        Disorient    = 6,
        Knock        = 7,
    }

    for categoryKey, categoryName in pairs(drCategories) do
        optionsTable.dr.args.drCategorySizing.args[categoryKey] = {
            order = drCategoryOrder[categoryKey],
            name = categoryName,
            type = "range",
            min = -25,
            max = 25,
            softMin = -10,
            softMax = 20,
            step = 1,
            get = function(info)
                local dr = info.handler.db.profile.layoutSettings[layoutName].dr
                dr.drCategorySizeOffsets = dr.drCategorySizeOffsets or {}
                return dr.drCategorySizeOffsets[info[#info]] or 0
            end,
            set = function(info, val)
                local dr = info.handler.db.profile.layoutSettings[layoutName].dr
                dr.drCategorySizeOffsets = dr.drCategorySizeOffsets or {}
                dr.drCategorySizeOffsets[info[#info]] = val
                self:UpdateDRSettings(dr, info)
            end,
        }
    end

    -- Text Settings options
    optionsTable.textSettings = {
        order = 1.1,
        name = "Text Settings",
        type = "group",
        args = {
            fonts = {
                order  = 0,
                name   = "Fonts",
                type   = "group",
                inline = true,
                args   = {
                    changeFont = {
                        order = 0,
                        type = "toggle",
                        name  = "Change Font",
                        desc  = "Change the fonts used by sArena",
                        width = "full",
                        get   = getSetting,
                        set   = setSetting,
                    },
                    frameFont = {
                        order = 1, type = "select",
                        name  = "Frame Font",
                        desc  = "Used for labels like name, health/power values, cast text, etc.",
                        style = "dropdown",
                        width = 0.7,
                        dialogControl = "LSM30_Font",
                        values = sArenaMixin.FontValues,
                        get    = getSetting,
                        set    = setSetting,
                        disabled = function(info)
                            return not info.handler.db.profile.layoutSettings[layoutName].changeFont
                        end,
                    },
                    cdFont = {
                        order = 2, type = "select",
                        name  = "Cooldown Font",
                        desc  = "Used for cooldown numbers (trinket, DRs, racials, etc.).",
                        style = "dropdown",
                        width = 0.7,
                        dialogControl = "LSM30_Font",
                        values = sArenaMixin.FontValues,
                        get    = getSetting,
                        set    = setSetting,
                        disabled = function(info)
                            return not info.handler.db.profile.layoutSettings[layoutName].changeFont
                        end,
                    },
                    fontOutline = {
                        order = 3, type = "select",
                        name  = "Font Outline",
                        desc  = "Choose font outline style for all text elements.",
                        style = "dropdown",
                        width = 0.7,
                        values = sArenaMixin.FontOutlineValues,
                        get    = getFontOutlineSetting,
                        set    = setSetting,
                        disabled = function(info)
                            return not info.handler.db.profile.layoutSettings[layoutName].changeFont
                        end,
                    },
                },
            },
            nameText = {
                order = 1,
                name = "Name Text",
                type = "group",
                inline = true,
                args = {
                    nameAnchor = {
                        order = 1,
                        name = "Anchor Point",
                        type = "select",
                        style = "dropdown",
                        width = 0.5,
                        values = {
                            ["LEFT"] = "Left",
                            ["CENTER"] = "Center",
                            ["RIGHT"] = "Right",
                        },
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.nameAnchor or "CENTER"
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.nameAnchor = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    nameSize = {
                        order = 2,
                        name = "Size",
                        type = "range",
                        min = 0.2,
                        max = 3,
                        softMin = 0.05,
                        softMax = 5,
                        step = 0.01,
                        width = 0.8,
                        isPercent = true,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.nameSize or 1.0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.nameSize = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    nameOffsetX = {
                        order = 3,
                        name = "Horizontal",
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.nameOffsetX or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.nameOffsetX = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    nameOffsetY = {
                        order = 4,
                        name = "Vertical",
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.nameOffsetY or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.nameOffsetY = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    resetNameText = {
                        order = 5,
                        name = "Reset",
                        width = 0.4,
                        type = "execute",
                        func = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            local currentLayout = info.handler.layouts[layoutName]
                            local defaults = currentLayout.defaultSettings.textSettings
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.nameAnchor = defaults.nameAnchor
                            layout.textSettings.nameSize = defaults.nameSize
                            layout.textSettings.nameOffsetX = defaults.nameOffsetX
                            layout.textSettings.nameOffsetY = defaults.nameOffsetY
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, nil)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                        end,
                    },
                },
            },
            healthText = {
                order = 2,
                name = "Health Text",
                type = "group",
                inline = true,
                args = {
                    healthAnchor = {
                        order = 1,
                        name = "Anchor Point",
                        type = "select",
                        style = "dropdown",
                        width = 0.5,
                        values = {
                            ["LEFT"] = "Left",
                            ["CENTER"] = "Center",
                            ["RIGHT"] = "Right",
                        },
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.healthAnchor or "CENTER"
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.healthAnchor = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    healthSize = {
                        order = 2,
                        name = "Size",
                        type = "range",
                        min = 0.05,
                        max = 5,
                        step = 0.01,
                        width = 0.8,
                        isPercent = true,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.healthSize or 1.0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.healthSize = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    healthOffsetX = {
                        order = 3,
                        name = "Horizontal",
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.healthOffsetX or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.healthOffsetX = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    healthOffsetY = {
                        order = 4,
                        name = "Vertical",
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.healthOffsetY or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.healthOffsetY = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    resetHealthText = {
                        order = 5,
                        name = "Reset",
                        width = 0.4,
                        type = "execute",
                        func = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            local currentLayout = info.handler.layouts[layoutName]
                            local defaults = currentLayout.defaultSettings.textSettings
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.healthAnchor = defaults.healthAnchor
                            layout.textSettings.healthSize = defaults.healthSize
                            layout.textSettings.healthOffsetX = defaults.healthOffsetX
                            layout.textSettings.healthOffsetY = defaults.healthOffsetY
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, nil)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                        end,
                    },
                },
            },
            powerText = {
                order = 2.5,
                name = "Mana Text",
                type = "group",
                inline = true,
                args = {
                    powerAnchor = {
                        order = 1,
                        name = "Anchor Point",
                        type = "select",
                        style = "dropdown",
                        width = 0.5,
                        values = {
                            ["LEFT"] = "Left",
                            ["CENTER"] = "Center",
                            ["RIGHT"] = "Right",
                        },
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.powerAnchor or "CENTER"
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.powerAnchor = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    powerSize = {
                        order = 2,
                        name = "Size",
                        type = "range",
                        min = 0.05,
                        max = 5,
                        step = 0.01,
                        width = 0.8,
                        isPercent = true,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.powerSize or 1.0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.powerSize = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    powerOffsetX = {
                        order = 3,
                        name = "Horizontal",
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.powerOffsetX or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.powerOffsetX = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    powerOffsetY = {
                        order = 4,
                        name = "Vertical",
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.powerOffsetY or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.powerOffsetY = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    resetPowerText = {
                        order = 5,
                        name = "Reset",
                        width = 0.4,
                        type = "execute",
                        func = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            local currentLayout = info.handler.layouts[layoutName]
                            local defaults = currentLayout.defaultSettings.textSettings
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.powerAnchor = defaults.powerAnchor
                            layout.textSettings.powerSize = defaults.powerSize
                            layout.textSettings.powerOffsetX = defaults.powerOffsetX
                            layout.textSettings.powerOffsetY = defaults.powerOffsetY
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, nil)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                        end,
                    },
                },
            },
            specNameText = {
                order = 3,
                name = "Spec Name Text",
                type = "group",
                inline = true,
                args = {
                    specNameAnchor = {
                        order = 1,
                        name = "Anchor Point",
                        type = "select",
                        style = "dropdown",
                        width = 0.5,
                        values = {
                            ["LEFT"] = "Left",
                            ["CENTER"] = "Center",
                            ["RIGHT"] = "Right",
                        },
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.specNameAnchor or "CENTER"
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.specNameAnchor = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    specNameSize = {
                        order = 2,
                        name = "Size",
                        type = "range",
                        min = 0.05,
                        max = 5,
                        step = 0.01,
                        width = 0.8,
                        isPercent = true,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.specNameSize or 1.0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.specNameSize = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    specNameOffsetX = {
                        order = 3,
                        name = "Horizontal",
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.specNameOffsetX or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.specNameOffsetX = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    specNameOffsetY = {
                        order = 4,
                        name = "Vertical",
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.specNameOffsetY or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.specNameOffsetY = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    resetSpecNameText = {
                        order = 5,
                        name = "Reset",
                        width = 0.4,
                        type = "execute",
                        func = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            local currentLayout = info.handler.layouts[layoutName]
                            local defaults = currentLayout.defaultSettings.textSettings
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.specNameAnchor = defaults.specNameAnchor
                            layout.textSettings.specNameSize = defaults.specNameSize
                            layout.textSettings.specNameOffsetX = defaults.specNameOffsetX
                            layout.textSettings.specNameOffsetY = defaults.specNameOffsetY
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, nil)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                        end,
                    },
                },
            },
            castbarText = {
                order = 4,
                name = "Castbar Text",
                type = "group",
                inline = true,
                args = {
                    castbarAnchor = {
                        order = 1,
                        name = "Anchor Point",
                        type = "select",
                        style = "dropdown",
                        width = 0.5,
                        values = {
                            ["LEFT"] = "Left",
                            ["CENTER"] = "Center",
                            ["RIGHT"] = "Right",
                        },
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.castbarAnchor or "CENTER"
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.castbarAnchor = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    castbarSize = {
                        order = 2,
                        name = "Size",
                        type = "range",
                        min = 0.05,
                        max = 5,
                        step = 0.01,
                        width = 0.8,
                        isPercent = true,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.castbarSize or 1.0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.castbarSize = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    castbarOffsetX = {
                        order = 3,
                        name = "Horizontal",
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.castbarOffsetX or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.castbarOffsetX = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    castbarOffsetY = {
                        order = 4,
                        name = "Vertical",
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.castbarOffsetY or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.castbarOffsetY = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    resetCastbarText = {
                        order = 5,
                        name = "Reset",
                        width = 0.4,
                        type = "execute",
                        func = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            local currentLayout = info.handler.layouts[layoutName]
                            local defaults = currentLayout.defaultSettings.textSettings
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.castbarAnchor = defaults.castbarAnchor
                            layout.textSettings.castbarSize = defaults.castbarSize
                            layout.textSettings.castbarOffsetX = defaults.castbarOffsetX
                            layout.textSettings.castbarOffsetY = defaults.castbarOffsetY
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, nil)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                        end,
                    },
                },
            },
        },
    }

    return optionsTable
end

function sArenaMixin:UpdateFrameSettings(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "CENTER", db.posX, db.posY)
    self:SetScale(db.scale)

    local growthDirection = db.growthDirection
    local spacing = db.spacing

    for i = 1, sArenaMixin.maxArenaOpponents do
        local text = self["arena" .. i].ClassIconCooldown.Text
        local layoutCF = (self.layoutdb and self.layoutdb.changeFont)
        local fontToUse = text.fontFile
        if layoutCF then
            fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
        end
        text:SetFont(fontToUse, db.classIconFontSize, "OUTLINE")
        local sArenaText = self["arena" .. i].ClassIconCooldown.sArenaText
        if sArenaText then
            sArenaText:SetFont(fontToUse, db.classIconFontSize, "OUTLINE")
        end
    end

    for i = 2, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        local prevFrame = self["arena" .. i - 1]

        frame:ClearAllPoints()
        if (growthDirection == 1) then
            frame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -spacing)
        elseif (growthDirection == 2) then
            frame:SetPoint("BOTTOM", prevFrame, "TOP", 0, spacing)
        elseif (growthDirection == 3) then
            frame:SetPoint("LEFT", prevFrame, "RIGHT", spacing, 0)
        elseif (growthDirection == 4) then
            frame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
        end
    end
end

function sArenaMixin:UpdateCastBarSettings(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame.CastBar:ClearAllPoints()
        frame.CastBar:SetPoint("CENTER", frame, "CENTER", db.posX, db.posY)

        frame.CastBar.Icon:ClearAllPoints()
        if isRetail then
            frame.CastBar.Icon:SetPoint("RIGHT", frame.CastBar, "LEFT", -5 + (db.iconPosX or 0), (db.iconPosY or 0) + (db.useModernCastbars and -4.5 or 0))
        else
            frame.CastBar.Icon:SetPoint("RIGHT", frame.CastBar, "LEFT", -5 + (db.iconPosX or 0), (db.iconPosY or 0) + (db.useModernCastbars and -5.5 or 0))
        end

        frame.CastBar:SetScale(db.scale)
        frame.CastBar:SetWidth(db.width)
        frame.CastBar.BorderShield:ClearAllPoints()
        if db.useModernCastbars then
            if isRetail then
                frame.CastBar.BorderShield:SetAtlas("UI-CastingBar-Shield")
                frame.CastBar.BorderShield:SetPoint("CENTER", frame.CastBar.Icon, "CENTER", -0.2, -3)
                frame.CastBar.BorderShield:SetSize(30, 34)
            else
                frame.CastBar.BorderShield:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Shield.tga")
                frame.CastBar.BorderShield:SetPoint("CENTER", frame.CastBar.Icon, "CENTER", 0, -3)
                frame.CastBar.BorderShield:SetSize(49, 47)
            end
        else
            frame.CastBar.BorderShield:SetTexture(330124)
            frame.CastBar.BorderShield:SetSize(48, 48)
            frame.CastBar.BorderShield:SetPoint("CENTER", frame.CastBar.Icon, "CENTER", 9, -1)
        end

        if db.hideBorderShield then
            frame.CastBar.BorderShield:SetTexture(nil)
        end

        if db.hideCastbarSpark then
            frame.CastBar.Spark:SetAlpha(0)
        else
            frame.CastBar.Spark:SetAlpha(1)
        end

        frame.CastBar.BorderShield:SetScale(db.iconScale or 1)
        frame.CastBar.Icon:SetScale(db.iconScale or 1)
    end
end

function sArenaMixin:UpdateDRSettings(db, info, val)
    local categories = drCategorieslist

    if (val) then
        db[info[#info]] = val
    end

    local categorySizeOffsets = db.drCategorySizeOffsets or {}

    sArenaMixin.drBaseSize = db.size

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        frame:UpdateDRPositions()

        for n = 1, #categories do
            local category = categories[n]
            local dr = frame[category]

            local offset = categorySizeOffsets[category] or 0
            local borderSize = (db.brightDRBorder and 1) or db.borderSize or 1
            local size = db.size + offset

            dr:SetSize(size, size)
            dr.Border:SetPoint("TOPLEFT", dr, "TOPLEFT", -borderSize, borderSize)
            dr.Border:SetPoint("BOTTOMRIGHT", dr, "BOTTOMRIGHT", borderSize, -borderSize)

            local text = dr.Cooldown.Text
            local layoutCF = (self.layoutdb and self.layoutdb.changeFont)
            local fontToUse = text.fontFile
            if layoutCF then
                fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
            end
            text:SetFont(fontToUse, db.fontSize, "OUTLINE")
            local sArenaText = dr.Cooldown.sArenaText
            if sArenaText then
                sArenaText:SetFont(fontToUse, db.fontSize, "OUTLINE")
            end

            if db.brightDRBorder then
                if not dr.Mask then
                    dr.Mask = dr:CreateMaskTexture()
                    --dr.Mask:SetAllPoints(dr.Icon)
                    dr.Mask:SetPoint("TOPLEFT", dr.Icon, "TOPLEFT", -1, 1)
                    dr.Mask:SetPoint("BOTTOMRIGHT", dr.Icon, "BOTTOMRIGHT", 1, -1)
                end
                if isRetail then
                    dr.Border:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-HUD-ActionBar-PetAutoCast-Mask.tga")
                    dr.Cooldown:SetSwipeTexture("Interface\\TalentFrame\\talentsmasknodechoiceflyout")
                    dr.Mask:SetTexture("Interface\\TalentFrame\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                else
                    dr.Border:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-HUD-ActionBar-PetAutoCast-Mask.tga")
                    dr.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout")
                    dr.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                end
                dr.Icon:SetTexCoord(0.05, 0.95, 0.05, 0.9)

                dr.Icon:AddMaskTexture(dr.Mask)

                if not dr.Boverlay then
                    dr.Boverlay = CreateFrame("Frame", nil, dr)
                    dr.Boverlay:SetFrameStrata("HIGH")
                end
                dr.Boverlay:Show()
                dr.Border:SetParent(dr.Boverlay)

                dr.brightDRBorder = true
            else
                if dr.brightDRBorder then
                    -- revert to normal
                    dr.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
                    dr.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    dr.Cooldown:SetSwipeTexture(1)

                    if dr.Mask then
                        dr.Icon:RemoveMaskTexture(dr.Mask)
                    end

                    if dr.Boverlay then
                        dr.Border:SetParent(dr)
                        dr.Boverlay:Hide()
                    end

                    dr.brightDRBorder = nil
                end
            end

        end
    end

    self:UpdateGlobalDRSettings()
end

function sArenaMixin:UpdateGlobalDRSettings()
    local categories = drCategorieslist

    local drSwipeOff = self.db.profile.drSwipeOff
    local drTextOn = self.db.profile.drTextOn
    local disableSwipeEdge = self.db.profile.disableSwipeEdge

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        frame:UpdateDRPositions()

        for n = 1, #categories do
            local category = categories[n]
            local dr = frame[category]
            if drSwipeOff then
                dr.Cooldown:SetDrawSwipe(false)
                dr.Cooldown:SetDrawEdge(false)
            else
                dr.Cooldown:SetDrawSwipe(true)
                dr.Cooldown:SetDrawEdge(not disableSwipeEdge)
            end

            if drTextOn then
                dr.DRTextFrame:Show()
            else
                dr.DRTextFrame:Hide()
            end
        end
    end
end

function sArenaMixin:UpdateSpecIconSettings(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame.SpecIcon:ClearAllPoints()
        frame.SpecIcon:SetPoint("CENTER", frame, "CENTER", db.posX, db.posY)
        frame.SpecIcon:SetScale(db.scale)
    end
end

function sArenaMixin:UpdateTrinketSettings(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame.Trinket:ClearAllPoints()
        frame.Trinket:SetPoint("CENTER", frame, "CENTER", db.posX, db.posY)
        frame.Trinket:SetScale(db.scale)

        local text = self["arena" .. i].Trinket.Cooldown.Text
        local layoutCF = (self.layoutdb and self.layoutdb.changeFont)
        local fontToUse = text.fontFile
        if layoutCF then
            fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
        end
        text:SetFont(fontToUse, db.fontSize, "OUTLINE")
    end
end

function sArenaMixin:UpdateRacialSettings(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame.Racial:ClearAllPoints()
        frame.Racial:SetPoint("CENTER", frame, "CENTER", db.posX, db.posY)
        frame.Racial:SetScale(db.scale)

        local text = self["arena" .. i].Racial.Cooldown.Text
        local layoutCF = (self.layoutdb and self.layoutdb.changeFont)
        local fontToUse = text.fontFile
        if layoutCF then
            fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
        end
        text:SetFont(fontToUse, db.fontSize, "OUTLINE")
    end
end

function sArenaMixin:UpdateDispelSettings(db, info, val)
    if (val ~= nil) then
        db[info[#info]] = val
    end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame.Dispel:ClearAllPoints()
        frame.Dispel:SetPoint("CENTER", frame, "CENTER", db.posX, db.posY)
        frame.Dispel:SetScale(db.scale)

        local text = self["arena" .. i].Dispel.Cooldown.Text
        local layoutCF = (self.layoutdb and self.layoutdb.changeFont)
        local fontToUse = text.fontFile
        if layoutCF then
            fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
        end
        text:SetFont(fontToUse, db.fontSize, "OUTLINE")

        frame.Dispel:SetShown(self.db.profile.showDispels)
    end
end

function sArenaMixin:UpdateTextPositions(db, info, val)
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = info.handler["arena" .. i]
        local layout = info.handler.layouts[info.handler.db.profile.currentLayout]

        if frame and layout and layout.UpdateOrientation then
            layout:UpdateOrientation(frame)
        end
    end
end

function sArenaFrameMixin:UpdateClassIconCooldownReverse()
    local reverse = self.parent.db.profile.invertClassIconCooldown

    self.ClassIconCooldown:SetReverse(reverse)
end

function sArenaFrameMixin:UpdateTrinketRacialCooldownReverse()
    local reverse = self.parent.db.profile.invertTrinketRacialCooldown

    self.Trinket.Cooldown:SetReverse(reverse)
    self.Racial.Cooldown:SetReverse(reverse)
end

function sArenaFrameMixin:UpdateClassIconSwipeSettings()
    local disableSwipe = self.parent.db.profile.disableClassIconSwipe
    local disableSwipeEdge = self.parent.db.profile.disableSwipeEdge

    if self.ClassIconCooldown then
        if disableSwipe then
            self.ClassIconCooldown:SetDrawSwipe(false)
            self.ClassIconCooldown:SetDrawEdge(false)
        else
            self.ClassIconCooldown:SetDrawSwipe(true)
            self.ClassIconCooldown:SetDrawEdge(not disableSwipeEdge)
        end
    end
end

function sArenaFrameMixin:UpdateTrinketRacialSwipeSettings()
    local disableSwipe = self.parent.db.profile.disableTrinketRacialSwipe
    local disableSwipeEdge = self.parent.db.profile.disableSwipeEdge

    if self.Trinket and self.Trinket.Cooldown then
        if disableSwipe then
            self.Trinket.Cooldown:SetDrawSwipe(false)
            self.Trinket.Cooldown:SetDrawEdge(false)
        else
            self.Trinket.Cooldown:SetDrawSwipe(true)
            self.Trinket.Cooldown:SetDrawEdge(not disableSwipeEdge)
        end
    end

    if self.Racial and self.Racial.Cooldown then
        if disableSwipe then
            self.Racial.Cooldown:SetDrawSwipe(false)
            self.Racial.Cooldown:SetDrawEdge(false)
        else
            self.Racial.Cooldown:SetDrawSwipe(true)
            self.Racial.Cooldown:SetDrawEdge(not disableSwipeEdge)
        end
    end
end

function sArenaFrameMixin:UpdateSwipeEdgeSettings()
    local disableEdge = self.parent.db.profile.disableSwipeEdge

    self.ClassIconCooldown:SetDrawEdge(not disableEdge)
    self.Trinket.Cooldown:SetDrawEdge(not disableEdge)
    self.Racial.Cooldown:SetDrawEdge(not disableEdge)
end

local function setDRIcons()
    local inputs = {
        drIconsTitle = {
            order = 1,
            type = "description",
            name = function(info)
                local db = info.handler.db
                if db.profile.drStaticIconsPerSpec then
                    local className = select(1, UnitClass("player")) or "Unknown"
                    local classKey = select(2, UnitClass("player"))
                    local specName = sArenaMixin.playerSpecName or "Unknown"
                    local classColor = RAID_CLASS_COLORS[classKey]
                    local coloredText = specName .. " " .. className
                    if classColor then
                        coloredText = "|c" .. classColor.colorStr .. coloredText .. "|r"
                    end
                    return "Configure DR Icons (Per Spec: " .. coloredText .. ")"
                elseif db.profile.drStaticIconsPerClass then
                    local className = select(1, UnitClass("player")) or "Unknown"
                    local classKey = select(2, UnitClass("player"))
                    local classColor = RAID_CLASS_COLORS[classKey]
                    local coloredText = className
                    if classColor then
                        coloredText = "|c" .. classColor.colorStr .. coloredText .. "|r"
                    end
                    return "Configure DR Icons (Per Class: " .. coloredText .. ")"
                else
                    return "Configure DR Icons (Global)"
                end
            end,
            fontSize = "medium",
        }
    }

    local order = 2

    for category, defaultIcon in pairs(drIcons) do
        inputs[category] = {
            order = order,
            name = function(info)
                local db = info.handler.db
                local icon = nil
                if db.profile.drStaticIconsPerSpec then
                    local specKey = sArenaMixin.playerSpecID or 0
                    local perSpec = db.profile.drIconsPerSpec or {}
                    local specIcons = perSpec[specKey] or {}
                    icon = specIcons[category]
                elseif db.profile.drStaticIconsPerClass then
                    local classKey = sArenaMixin.playerClass
                    local perClass = db.profile.drIconsPerClass or {}
                    local classIcons = perClass[classKey] or {}
                    icon = classIcons[category]
                end
                if not icon then
                    local dbIcons = db.profile.drIcons or {}
                    icon = dbIcons[category] or defaultIcon
                end
                local textureString = ""
                if type(icon) == "number" then
                    textureString = "|T" .. icon .. ":24:24:0:0:64:64:5:59:5:59|t "
                elseif type(icon) == "string" then
                    textureString = "|T" .. icon .. ":24|t "
                end
                return textureString .. category .. ":"
            end,
            desc = "Default icon: " .. defaultIcon .. " |T" .. defaultIcon .. ":24|t",
            type = "input",
            width = "full",
            get = function(info)
                local db = info.handler.db
                -- If per-spec is enabled, prefer the spec-specific value when present.
                -- If the spec-specific value is missing, show the global saved icon or the default icon
                -- so the edit box isn't empty and the user sees the effective icon.
                if db.profile.drStaticIconsPerSpec then
                    local perSpec = db.profile.drIconsPerSpec or {}
                    local specIcons = perSpec[sArenaMixin.playerSpecID or 0] or {}
                    local specVal = specIcons[category]
                    if specVal ~= nil and specVal ~= "" then
                        return tostring(specVal)
                    end
                    -- fallback to global saved icon or default icon
                    local dbIcons = db.profile.drIcons or {}
                    return tostring(dbIcons[category] or defaultIcon or "")
                elseif db.profile.drStaticIconsPerClass then
                    local perClass = db.profile.drIconsPerClass or {}
                    local classIcons = perClass[sArenaMixin.playerClass] or {}
                    local classVal = classIcons[category]
                    if classVal ~= nil and classVal ~= "" then
                        return tostring(classVal)
                    end
                    -- fallback to global saved icon or default icon
                    local dbIcons = db.profile.drIcons or {}
                    return tostring(dbIcons[category] or defaultIcon or "")
                else
                    local dbIcons = db.profile.drIcons or {}
                    return tostring(dbIcons[category] or defaultIcon or "")
                end
            end,
            set = function(info, value)
                local db = info.handler.db
                if db.profile.drStaticIconsPerSpec then
                    db.profile.drIconsPerSpec = db.profile.drIconsPerSpec or {}
                    local specKey = sArenaMixin.playerSpecID or 0
                    db.profile.drIconsPerSpec[specKey] = db.profile.drIconsPerSpec[specKey] or {}
                    -- treat empty string as removal of the spec-specific override so we fall back
                    -- to the global saved icon/default.
                    if value == nil or tostring(value) == "" then
                        db.profile.drIconsPerSpec[specKey][category] = nil
                    else
                        local num = tonumber(value)
                        db.profile.drIconsPerSpec[specKey][category] = num or value
                    end
                elseif db.profile.drStaticIconsPerClass then
                    db.profile.drIconsPerClass = db.profile.drIconsPerClass or {}
                    db.profile.drIconsPerClass[sArenaMixin.playerClass] = db.profile.drIconsPerClass[sArenaMixin.playerClass] or {}
                    -- treat empty string as removal of the class-specific override so we fall back
                    -- to the global saved icon/default.
                    if value == nil or tostring(value) == "" then
                        db.profile.drIconsPerClass[sArenaMixin.playerClass][category] = nil
                    else
                        local num = tonumber(value)
                        db.profile.drIconsPerClass[sArenaMixin.playerClass][category] = num or value
                    end
                else
                    db.profile.drIcons = db.profile.drIcons or {}
                    if value == nil or tostring(value) == "" then
                        db.profile.drIcons[category] = nil
                    else
                        local num = tonumber(value)
                        db.profile.drIcons[category] = num or value
                    end
                end
                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
            end,
        }

        order = order + 1
    end

    return inputs
end


function sArenaMixin:CompatibilityIssueExists()
    -- List of known sArena addon variants that will conflict
    local otherSArenaVersions = {
        "sArena", -- Original
        "sArena Updated",
        "sArena_Pinaclonada",
        "sArena_Updated2_by_sammers",
    }

    -- Check each known version to see if it's loaded
    for _, addonName in ipairs(otherSArenaVersions) do
        if C_AddOns.IsAddOnLoaded(addonName) then
            return true, addonName  -- Return true and the name of the first conflicting addon found
        end
    end

    return false, nil  -- No conflicts found
end


if sArenaMixin:CompatibilityIssueExists() then
    sArenaMixin.optionsTable = {
        type = "group",
        childGroups = "tab",
        validate = validateCombat,
        args = {
            ImportOtherForkSettings = {
                order = 1,
                name = "Addon Conflict",
                desc = "Multiple sArena versions detected",
                type = "group",
                args = {
                    warningTitle = {
                        order = 1,
                        type = "description",
                        name = "|A:services-icon-warning:20:20|a |cffff4444Two different versions of sArena are enabled|r |A:services-icon-warning:20:20|a",
                        fontSize = "large",
                    },
                    spacer1 = {
                        order = 1.1,
                        type = "description",
                        name = " ",
                    },
                    explanation = {
                        order = 1.2,
                        type = "description",
                        name = "|cffffffffTwo different versions of sArena cannot function properly together.\nYou will have to use only one. You have 3 options:|r",
                        fontSize = "medium",
                    },
                    spacer2 = {
                        order = 1.3,
                        type = "description",
                        name = " ",
                    },
                    option1 = {
                        order = 2,
                        type = "execute",
                        name = "|cffffffffUse other sArena|r",
                        desc = "This will disable |cffffffffsArena |cffff8000Reloaded|r |T135884:13:13|t and instead use your other sArena and reload your UI.",
                        func = function()
                            C_AddOns.DisableAddOn("sArena_Reloaded")
                            ReloadUI()
                        end,
                        width = "full",
                        confirm = true,
                        confirmText = "This will disable |cffffffffsArena |cffff8000Reloaded|r |T135884:13:13|t and use the other sArena instead and reload your UI.\n\nContinue?",
                    },
                    option2 = {
                        order = 3,
                        type = "execute",
                        name = "|cffffffffUse sArena |cffff8000Reloaded|r |T135884:13:13|t: Import other settings",
                        desc = "This will copy your current profile and existing settings from the other sArena, disable the other sArena for compatibility, and reload your UI so you can start using sArena |cffff8000Reloaded|r |T135884:13:13|t",
                        func = function()
                            if sArenaMixin.ImportOtherForkSettings then
                                sArenaMixin:ImportOtherForkSettings()
                            end
                        end,
                        width = "full",
                        confirm = true,
                        confirmText = "This will copy your current profile and existing settings from the other sArena, disable the other sArena for compatibility, and reload your UI so you can start using sArena |cffff8000Reloaded|r |T135884:13:13|t\n\nContinue?",
                    },
                    option3 = {
                        order = 4,
                        type = "execute",
                        name = "|cffffffffUse sArena |cffff8000Reloaded|r |T135884:13:13|t: Don't import other settings",
                        desc = "This will disable the other sArena for compatibility and reload your UI so you can start using sArena |cffff8000Reloaded|r |T135884:13:13|t without your other settings.",
                        func = function()
                            sArenaMixin:CompatibilityEnsurer()
                            ReloadUI()
                        end,
                        width = "full",
                        confirm = true,
                        confirmText = "This will disable the other sArena for compatibility and reload your UI so you can start using sArena |cffff8000Reloaded|r |T135884:13:13|t without your other settings.\n\nContinue?",
                    },
                    spacer3 = {
                        order = 4.5,
                        type = "description",
                        name = " ",
                    },
                    conversionStatus = {
                        order = 5,
                        type = "description",
                        name = function() return sArenaMixin.conversionStatusText or "" end,
                        fontSize = "large",
                        hidden = function() return not sArenaMixin.conversionStatusText end,
                    },
                },
            },
        },
    }
else
    sArenaMixin.optionsTable = {
        type = "group",
        childGroups = "tab",
        validate = validateCombat,
        args = {
            setLayout = {
                order = 1,
                name = "Layout",
                type = "select",
                style = "dropdown",
                get = function(info) return info.handler.db.profile.currentLayout end,
                set = "SetLayout",
                values = getLayoutTable,
            },
            test = {
                order = 2,
                name = "Test",
                type = "execute",
                func = "Test",
                width = "half",
            },
            hide = {
                order = 3,
                name = "Hide",
                type = "execute",
                func = function(info)
                    for i = 1, sArenaMixin.maxArenaOpponents do
                        info.handler["arena" .. i]:OnEvent("PLAYER_ENTERING_WORLD")
                    end
                end,
                width = "half",
            },
            dragNotice = {
                order = 4,
                name = "|cffff3300     |T132961:16|t Ctrl+shift+click to drag stuff|r",
                type = "description",
                fontSize = "medium",
                width = 1.5,
            },
            layoutSettingsGroup = {
                order = 5,
                name = "Layout Settings",
                desc = "These settings apply only to the selected layout",
                type = "group",
                args = {},
            },
            globalSettingsGroup = {
                order = 6,
                name = "Global Settings",
                desc = "These settings apply to all layouts",
                type = "group",
                childGroups = "tree",
                args = {
                    framesGroup = {
                        order = 1,
                        name = "Arena Frames",
                        type = "group",
                        args = {
                            statusText = {
                                order = 5,
                                name = "Status Text",
                                type = "group",
                                inline = true,
                                args = {
                                    alwaysShow = {
                                        order = 1,
                                        name = "Always Show",
                                        desc = "If disabled, text only shows on mouseover",
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.statusText.alwaysShow end,
                                        set = function(info, val)
                                            info.handler.db.profile.statusText.alwaysShow = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateStatusTextVisible()
                                            end
                                        end,
                                    },
                                    usePercentage = {
                                        order = 2,
                                        name = "Use Percentage",
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.statusText.usePercentage end,
                                        set = function(info, val)
                                            info.handler.db.profile.statusText.usePercentage = val
                                            if val then
                                                info.handler.db.profile.statusText.formatNumbers = false
                                            end

                                            local _, instanceType = IsInInstance()
                                            if (instanceType ~= "arena" and info.handler.arena1:IsShown()) then
                                                info.handler:Test()
                                            end
                                        end,
                                    },
                                    formatNumbers = {
                                        order = 3,
                                        name = "Format Numbers",
                                        desc = "Format large numbers. 18888 K -> 18.88 M",
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.statusText.formatNumbers end,
                                        set = function(info, val)
                                            info.handler.db.profile.statusText.formatNumbers = val
                                            if val then
                                                info.handler.db.profile.statusText.usePercentage = false
                                            end

                                            local _, instanceType = IsInInstance()
                                            if (instanceType ~= "arena" and info.handler.arena1:IsShown()) then
                                                info.handler:Test()
                                            end
                                        end,
                                    },
                                    hidePowerText = {
                                        order = 4,
                                        name = "Hide Power Text",
                                        desc = "Hide mana/rage/energy text",
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.hidePowerText end,
                                        set = function(info, val)
                                            info.handler.db.profile.hidePowerText = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateStatusTextVisible()
                                            end
                                        end,
                                    },
                                },
                            },
                            darkModeGroup = {
                                order = 5.5,
                                name = "Dark Mode",
                                type = "group",
                                inline = true,
                                args = {
                                    darkMode = {
                                        order = 1,
                                        name = "Enable Dark Mode",
                                        type = "toggle",
                                        width = 1,
                                        desc = "Enable Dark Mode for Arena Frames.\n\nIf Better|cff00c0ffBlizz|rFrames is installed it will pick your set Dark Mode color from there.",
                                        get = function(info) return info.handler.db.profile.darkMode end,
                                        set = function(info, val)
                                            info.handler.db.profile.darkMode = val
                                            if val then
                                                info.handler.db.profile.classColorFrameTexture = false
                                            end
                                            info.handler:RefreshConfig()
                                            info.handler:Test()
                                        end,
                                    },
                                    darkModeValue = {
                                        order = 2,
                                        name = "Dark Mode Value",
                                        type = "range",
                                        width = 0.75,
                                        desc = "Set the darkness value for Dark Mode frames (0 = black, 1 = normal brightness).",
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        hidden = function()
                                            return BetterBlizzFramesDB and BetterBlizzFramesDB.darkModeUi
                                        end,
                                        disabled = function(info)
                                            return not info.handler.db.profile.darkMode
                                        end,
                                        get = function(info) return info.handler.db.profile.darkModeValue end,
                                        set = function(info, val)
                                            info.handler.db.profile.darkModeValue = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                local frame = info.handler["arena"..i]
                                                if frame then
                                                    frame:UpdateFrameColors()
                                                end
                                            end
                                        end,
                                    },
                                    darkModeDesaturate = {
                                        order = 3,
                                        name = "Desaturate",
                                        type = "toggle",
                                        width = 0.75,
                                        desc = "Remove all color from textures getting dark moded.\n\n|cff888888This is the default behaviour but with some layouts you might prefer to have some original color shine through.|r",
                                        hidden = function()
                                            return BetterBlizzFramesDB and BetterBlizzFramesDB.darkModeUi
                                        end,
                                        disabled = function(info)
                                            return not info.handler.db.profile.darkMode
                                        end,
                                        get = function(info) return info.handler.db.profile.darkModeDesaturate end,
                                        set = function(info, val)
                                            info.handler.db.profile.darkModeDesaturate = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                local frame = info.handler["arena"..i]
                                                if frame then
                                                    frame:UpdateFrameColors()
                                                end
                                            end
                                        end,
                                    },
                                },
                            },
                            misc = {
                                order = 6,
                                name = "Options",
                                type = "group",
                                inline = true,
                                args = {
                                    classColors = {
                                        order = 1,
                                        name = "Class Color Healthbars",
                                        desc = "When disabled, health bars will be green",
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.classColors end,
                                        set = function(info, val)
                                            local db = info.handler.db
                                            db.profile.classColors = val

                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                local class = frame.tempClass
                                                local color = RAID_CLASS_COLORS[class]

                                                if val and color then
                                                    frame.HealthBar:SetStatusBarColor(color.r, color.g, color.b, 1)
                                                else
                                                    frame.HealthBar:SetStatusBarColor(0, 1, 0, 1)
                                                end
                                            end
                                        end,
                                    },
                                    classColorFrameTexture = {
                                        order = 1.05,
                                        name = "Class Color FrameTexture",
                                        desc = "Apply class colors to frame textures (Borders)",
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.classColorFrameTexture end,
                                        set = function(info, val)
                                            info.handler.db.profile.classColorFrameTexture = val
                                            if val then
                                                info.handler.db.profile.darkMode = false
                                            end
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                local frame = info.handler["arena"..i]
                                                if frame then
                                                    frame:UpdateFrameColors()
                                                end
                                            end
                                        end,
                                    },
                                    classColorNames = {
                                        order = 1.1,
                                        name = "Class Color Names",
                                        desc = "When enabled, player names will be colored by class",
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.classColorNames end,
                                        set = function(info, val)
                                            info.handler.db.profile.classColorNames = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                if frame.Name:IsShown() then
                                                    frame:UpdateNameColor()
                                                end
                                            end
                                        end,
                                    },
                                    replaceHealerIcon = {
                                        order = 2,
                                        name = "Replace Healer Icon",
                                        type = "toggle",
                                        width = "full",
                                        desc = "Replace Healers Class/Spec Icon with a Healer Icon.",
                                        get = function(info) return info.handler.db.profile.replaceHealerIcon end,
                                        set = function(info, val)
                                            info.handler.db.profile.replaceHealerIcon = val
                                            info.handler:Test()
                                        end,
                                    },
                                    showNames = {
                                        order = 4,
                                        name = "Show Names",
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.showNames end,
                                        set = function(info, val)
                                            info.handler.db.profile.showNames = val
                                            info.handler.db.profile.showArenaNumber = false
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                frame.Name:SetShown(val)
                                                frame.Name:SetText(frame.tempName or "name")
                                            end
                                        end,
                                    },
                                    showArenaNumber = {
                                        order = 5,
                                        name = "Show Arena Number",
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.showArenaNumber end,
                                        set = function(info, val)
                                            info.handler.db.profile.showArenaNumber = val
                                            info.handler.db.profile.showNames = false
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i].Name:SetShown(val)
                                                info.handler["arena" .. i].Name:SetText("arena"..i)
                                            end
                                        end,
                                    },
                                    hideClassIcon = {
                                        order = 6,
                                        name = "Hide Class Icon",
                                        type = "toggle",
                                        width = "full",
                                        desc = "Hide the Class Icon and only show Auras when they are active.",
                                        get = function(info) return info.handler.db.profile.hideClassIcon end,
                                        set = function(info, val)
                                            info.handler.db.profile.hideClassIcon = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                if val then
                                                    info.handler["arena" .. i].ClassIcon:SetTexture(nil)
                                                else
                                                    if info.handler["arena" .. i].replaceClassIcon then
                                                        info.handler["arena" .. i].ClassIcon:SetTexture(info.handler["arena" .. i].tempSpecIcon)
                                                    else
                                                        info.handler["arena" .. i].ClassIcon:SetTexture(info.handler.classIcons[info.handler["arena" .. i].tempClass])
                                                    end
                                                end
                                            end
                                            info.handler:Test()
                                        end,
                                    },
                                    colorTrinket = {
                                        order = 7,
                                        name = "Color Trinket",
                                        type = "toggle",
                                        width = "full",
                                        desc = "Replace Trinket texture with a solid green color when it's up and red when it's on cooldown.",
                                        get = function(info) return info.handler.db.profile.colorTrinket end,
                                        set = function(info, val)
                                            info.handler.db.profile.colorTrinket = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                if val then
                                                    if i <= 2 then
                                                        info.handler["arena" .. i].Trinket.Texture:SetColorTexture(0,1,0)
                                                        info.handler["arena" .. i].Trinket.Cooldown:Clear()
                                                    else
                                                        info.handler["arena" .. i].Trinket.Texture:SetColorTexture(1,0,0)
                                                    end
                                                else
                                                    info.handler["arena" .. i].Trinket.Texture:SetTexture(sArenaMixin.trinketTexture)
                                                end
                                            end
                                        end,
                                    },
                                    colorMysteryGray = {
                                        order = 8,
                                        name = "Color Non-Visible Frames Gray",
                                        type = "toggle",
                                        width = "full",
                                        desc = "Colors mystery players with gray status bars instead of their class colors. Mystery players are unseen players, aka before gates open and stealthed ones.",
                                        get = function(info) return info.handler.db.profile.colorMysteryGray end,
                                        set = function(info, val)
                                            info.handler.db.profile.colorMysteryGray = val
                                        end,
                                    },
                                    showDecimalsClassIcon = {
                                        order = 9,
                                        name = "Show Decimals on Class Icon",
                                        desc =
                                        "Show Decimals on Class Icon when duration is below 6 seconds.\n\nOnly for non-OmniCC users.",
                                        type = "toggle",
                                        width = 1.4,
                                        get = function(info) return info.handler.db.profile.showDecimalsClassIcon end,
                                        set = function(info, val)
                                            info.handler.db.profile.showDecimalsClassIcon = val
                                            info.handler:SetupCustomCD()
                                        end
                                    },
                                    decimalThreshold = {
                                        order = 10,
                                        name = "Decimal Threshold",
                                        desc = "Show decimals when remaining time is below this threshold. Default is 6 seconds.",
                                        type = "range",
                                        min = 1,
                                        max = 10,
                                        step = 0.1,
                                        width = 0.75,
                                        disabled = function(info) return not info.handler.db.profile.showDecimalsClassIcon end,
                                        get = function(info) return info.handler.db.profile.decimalThreshold or 6 end,
                                        set = function(info, val)
                                            info.handler.db.profile.decimalThreshold = val
                                            info.handler:UpdateDecimalThreshold()
                                            info.handler:SetupCustomCD()
                                        end
                                    },

                                },
                            },
                            swipeAnimations = {
                                order = 7,
                                name = "Swipe Animations",
                                type = "group",
                                inline = true,
                                args = {
                                    disableSwipeEdge = {
                                        order = 0,
                                        name = "Disable Cooldown Swipe Edge",
                                        type = "toggle",
                                        width = "full",
                                        desc = "Disables the bright edge on cooldown spirals for all icons.",
                                        get = function(info) return info.handler.db.profile.disableSwipeEdge end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableSwipeEdge = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateSwipeEdgeSettings()
                                            end
                                            info.handler:UpdateGlobalDRSettings()
                                        end,
                                    },
                                    disableClassIconSwipe = {
                                        order = 1,
                                        name = "Disable Class Icon Swipe",
                                        type = "toggle",
                                        width = "full",
                                        desc = "Disables the spiral cooldown swipe animation on Class Icon.",
                                        get = function(info) return info.handler.db.profile.disableClassIconSwipe end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableClassIconSwipe = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateClassIconSwipeSettings()
                                            end
                                        end,
                                    },
                                    drSwipeOff = {
                                        order = 2,
                                        name = "Disable DR Swipe Animation",
                                        desc = "Disables the spiral cooldown swipe on DR icons.",
                                        type = "toggle",
                                        width = "full",
                                        get = function(info)
                                            return info.handler.db.profile.drSwipeOff
                                        end,
                                        set = function(info, val)
                                            info.handler.db.profile.drSwipeOff = val
                                            info.handler:UpdateGlobalDRSettings()
                                        end,
                                    },
                                    disableTrinketRacialSwipe = {
                                        order = 3,
                                        name = "Disable Trinket & Racial Swipe",
                                        type = "toggle",
                                        width = "full",
                                        desc = "Disables the spiral cooldown swipe animation on Trinket and Racial icons.",
                                        get = function(info) return info.handler.db.profile.disableTrinketRacialSwipe end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableTrinketRacialSwipe = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateTrinketRacialSwipeSettings()
                                            end
                                        end,
                                    },
                                    invertClassIconCooldown = {
                                        order = 4,
                                        name = "Reverse Class Icon Swipe",
                                        type = "toggle",
                                        width = "full",
                                        desc = "Reverses the cooldown sweep direction for Class Icon cooldowns. Changes whether they start empty and fill up, or start full and empty out.",
                                        disabled = function(info) return info.handler.db.profile.disableClassIconSwipe end,
                                        get = function(info) return info.handler.db.profile.invertClassIconCooldown end,
                                        set = function(info, val)
                                            info.handler.db.profile.invertClassIconCooldown = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateClassIconCooldownReverse()
                                            end
                                        end,
                                    },
                                    invertDRCooldown = {
                                        order = 5,
                                        name = "Reverse DR Swipe Animation",
                                        desc = "Reverses the DR cooldown swipe direction.",
                                        type = "toggle",
                                        width = "full",
                                        disabled = function(info) return info.handler.db.profile.drSwipeOff end,
                                        get = function(info) return info.handler.db.profile.invertDRCooldown end,
                                        set = function(info, val)
                                            info.handler.db.profile.invertDRCooldown = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateDRCooldownReverse()
                                            end
                                        end
                                    },
                                    invertTrinketRacialCooldown = {
                                        order = 6,
                                        name = "Reverse Trinket & Racial Swipe",
                                        type = "toggle",
                                        width = "full",
                                        desc = "Reverses the cooldown sweep direction for Trinket and Racial cooldowns. Changes whether they start empty and fill up, or start full and empty out.",
                                        disabled = function(info) return info.handler.db.profile.disableTrinketRacialSwipe end,
                                        get = function(info) return info.handler.db.profile.invertTrinketRacialCooldown end,
                                        set = function(info, val)
                                            info.handler.db.profile.invertTrinketRacialCooldown = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateTrinketRacialCooldownReverse()
                                            end
                                        end,
                                    },
                                },
                            },
                            masque = {
                                order = 8,
                                name = "Miscellaneous",
                                type = "group",
                                inline = true,
                                args = {
                                    enableMasque = {
                                        order = 1,
                                        name = "Enable Masque Support",
                                        desc = "Click to enable Masque support to reskin Icon borders.",
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.enableMasque end,
                                        set = function(info, val)
                                            info.handler.db.profile.enableMasque = val
                                            info.handler:AddMasqueSupport()
                                            info.handler:Test()
                                        end
                                    },
                                    removeUnequippedTrinketTexture = {
                                        order = 2,
                                        name = "Remove Un-Equipped Trinket Texture",
                                        desc = "Enable this setting to hide the Trinket entirely when the enemy does have a one equipped, instead of showing the default White Flag indicating no Trinket.",
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.removeUnequippedTrinketTexture end,
                                        set = function(info, val)
                                            info.handler.db.profile.removeUnequippedTrinketTexture = val
                                            if val then
                                                sArenaMixin.noTrinketTexture = nil
                                            else
                                                sArenaMixin.noTrinketTexture = 638661
                                            end
                                        end
                                    },
                                    desaturateTrinketCD = {
                                        order = 2.1,
                                        name = "Desaturate Trinket CD",
                                        desc = "Desaturate the Trinket icon when it is on cooldown.",
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.desaturateTrinketCD end,
                                        set = function(info, val)
                                            info.handler.db.profile.desaturateTrinketCD = val
                                        end
                                    },
                                    desaturateDispelCD = {
                                        order = 2.2,
                                        name = "Desaturate Dispel CD",
                                        desc = "Desaturate the Dispel icon when it is on cooldown.",
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.desaturateDispelCD end,
                                        set = function(info, val)
                                            info.handler.db.profile.desaturateDispelCD = val
                                        end
                                    },
                                },
                            },
                        },
                    },
                    drGroup = {
                        order = 2,
                        name = "Diminishing Returns",
                        type = "group",
                        args = {
                            drOptions = {
                                order = 1,
                                type = "group",
                                name = "Options",
                                inline = true,
                                args = {
                                    drResetTime = {
                                        order = 1,
                                        name = "DR Reset Time",
                                        desc =
                                        "Blizzard no longer uses a dynamic timer for DR resets, it is 18 seconds\n\nBy default sArena has a 0.5 leeway added so a total of 18.5 seconds.",
                                        type = "range",
                                        min = 18,
                                        max = 20,
                                        step = 0.1,
                                        width = "normal",
                                        get = function(info)
                                            return info.handler.db.profile.drResetTime or 18.5
                                        end,
                                        set = function(info, val)
                                            info.handler.db.profile.drResetTime = val
                                            info.handler:UpdateDRTimeSetting()
                                        end,
                                    },
                                    drResetTime_break = {
                                        order = 1.1,
                                        type = "description",
                                        name = " ",
                                        width = "full",
                                    },
                                    showDecimalsDR = {
                                        order = 2,
                                        name = "Show Decimals on DR's",
                                        desc =
                                        "Show Decimals on DR's when duration is below 6 seconds.\n\nOnly for non-OmniCC users.",
                                        type = "toggle",
                                        width = 1.2,
                                        get = function(info) return info.handler.db.profile.showDecimalsDR end,
                                        set = function(info, val)
                                            info.handler.db.profile.showDecimalsDR = val
                                            info.handler:SetupCustomCD()
                                        end
                                    },
                                    decimalThresholdDR = {
                                        order = 2.5,
                                        name = "Decimal Threshold",
                                        desc = "Show decimals when remaining time is below this threshold. Default is 6 seconds.",
                                        type = "range",
                                        min = 1,
                                        max = 10,
                                        step = 0.1,
                                        width = 0.75,
                                        disabled = function(info) return not info.handler.db.profile.showDecimalsDR end,
                                        get = function(info) return info.handler.db.profile.decimalThreshold or 6 end,
                                        set = function(info, val)
                                            info.handler.db.profile.decimalThreshold = val
                                            info.handler:UpdateDecimalThreshold()
                                            info.handler:SetupCustomCD()
                                        end
                                    },
                                    drTextOn = {
                                        order = 6,
                                        name = "Show DR Text",
                                        desc = "Show text on DR icons displaying the current DR status.",
                                        type = "toggle",
                                        width = "full",
                                        get = function(info)
                                            return info.handler.db.profile.drTextOn
                                        end,
                                        set = function(info, val)
                                            info.handler.db.profile.drTextOn = val
                                            info.handler:UpdateGlobalDRSettings()
                                        end,
                                    },
                                    disableDRBorder = {
                                        order = 5,
                                        name = "Disable DR Border",
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.disableDRBorder end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableDRBorder = val
                                            info.handler:SetDRBorderShownStatus()
                                            info.handler:Test()
                                        end
                                    },
                                },
                            },
                            categories = {
                                order = 2,
                                name = "DR Categories",
                                type = "group",
                                inline = true,
                                args = {
                                    drCategoriesPerClass = {
                                        order = 1,
                                        name = "Per Class",
                                        desc = "When enabled, the DR categories below become class-specific for your current class.\n\n|cff888888It still includes all default categories so you won't see an immediate change, you must manually change any you want to customize.|r",
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.drCategoriesPerClass end,
                                        set = function(info, val)
                                            info.handler.db.profile.drCategoriesPerClass = val
                                            if val then
                                                info.handler.db.profile.drCategoriesPerSpec = false
                                            end
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    },
                                    drCategoriesPerSpec = {
                                        order = 2,
                                        name = "Per Spec",
                                        desc = "When enabled, the DR categories below become specialization-specific for your current spec.\n\n|cff888888It still includes all default categories so you won't see an immediate change, you must manually change any you want to customize.|r",
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.drCategoriesPerSpec end,
                                        set = function(info, val)
                                            info.handler.db.profile.drCategoriesPerSpec = val
                                            if val then
                                                info.handler.db.profile.drCategoriesPerClass = false
                                            end
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    },

                                    categoriesMultiselect = {
                                        order = 4,
                                        name = function(info)
                                            local db = info.handler.db
                                            if db.profile.drCategoriesPerSpec then
                                                local className = select(1, UnitClass("player")) or "Unknown"
                                                local classKey = select(2, UnitClass("player"))
                                                local specName = sArenaMixin.playerSpecName or "Unknown"
                                                local classColor = RAID_CLASS_COLORS[classKey]
                                                local coloredText = specName .. " " .. className
                                                if classColor then
                                                    coloredText = "|c" .. classColor.colorStr .. coloredText .. "|r"
                                                end
                                                return "Categories (Per Spec: " .. coloredText .. ")"
                                            elseif db.profile.drCategoriesPerClass then
                                                local className = select(1, UnitClass("player")) or "Unknown"
                                                local classKey = select(2, UnitClass("player"))
                                                local classColor = RAID_CLASS_COLORS[classKey]
                                                local coloredText = className
                                                if classColor then
                                                    coloredText = "|c" .. classColor.colorStr .. coloredText .. "|r"
                                                end
                                                return "Categories (Per Class: " .. coloredText .. ")"
                                            else
                                                return "Categories (Global)"
                                            end
                                        end,
                                        type = "multiselect",
                                        get = function(info, key) 
                                            local db = info.handler.db
                                            if db.profile.drCategoriesPerSpec then
                                                local specKey = sArenaMixin.playerSpecID or 0
                                                local perSpec = db.profile.drCategoriesSpec or {}
                                                local specCategories = perSpec[specKey] or {}
                                                if specCategories[key] ~= nil then
                                                    return specCategories[key]
                                                else
                                                    return db.profile.drCategories[key]
                                                end
                                            elseif db.profile.drCategoriesPerClass then
                                                local classKey = sArenaMixin.playerClass
                                                local perClass = db.profile.drCategoriesClass or {}
                                                local classCategories = perClass[classKey] or {}
                                                if classCategories[key] ~= nil then
                                                    return classCategories[key]
                                                else
                                                    return db.profile.drCategories[key]
                                                end
                                            else
                                                return db.profile.drCategories[key]
                                            end
                                        end,
                                        set = function(info, key, val) 
                                            local db = info.handler.db
                                            if db.profile.drCategoriesPerSpec then
                                                db.profile.drCategoriesSpec = db.profile.drCategoriesSpec or {}
                                                local specKey = sArenaMixin.playerSpecID or 0
                                                db.profile.drCategoriesSpec[specKey] = db.profile.drCategoriesSpec[specKey] or {}
                                                db.profile.drCategoriesSpec[specKey][key] = val
                                            elseif db.profile.drCategoriesPerClass then
                                                db.profile.drCategoriesClass = db.profile.drCategoriesClass or {}
                                                local classKey = sArenaMixin.playerClass
                                                db.profile.drCategoriesClass[classKey] = db.profile.drCategoriesClass[classKey] or {}
                                                db.profile.drCategoriesClass[classKey][key] = val
                                            else
                                                db.profile.drCategories[key] = val
                                            end
                                        end,
                                        values = drCategories,
                                    },
                                },
                            },
                            dynamicIcons = {
                                order = 3,
                                name = "DR Icons",
                                type = "group",
                                inline = true,
                                args = {
                                    drStaticIcons = {
                                        order = 1,
                                        name = "Enable Static Icons",
                                        desc = "DR icons will always use a specific icon for each DR category.",
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.drStaticIcons end,
                                        set = function(info, val)
                                            info.handler.db.profile.drStaticIcons = val
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    },
                                    dynamicIconsPerClass = {
                                        order = 2,
                                        name = "Per Class",
                                        desc = "When enabled, the icons below become class-specific for your current class.\n\n|cff888888It still includes all default icons so you won't see an immediate change, you must manually change any you want to customize.|r",
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.drStaticIcons end,
                                        get = function(info) return info.handler.db.profile.drStaticIconsPerClass end,
                                        set = function(info, val)
                                            info.handler.db.profile.drStaticIconsPerClass = val
                                            if val then
                                                info.handler.db.profile.drStaticIconsPerSpec = false
                                            end
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    },
                                    dynamicIconsPerSpec = {
                                        order = 3,
                                        name = "Per Spec",
                                        desc = "When enabled, the icons below become specialization-specific for your current spec.\n\n|cff888888It still includes all default icons so you won't see an immediate change, you must manually change any you want to customize.|r",
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.drStaticIcons end,
                                        get = function(info) return info.handler.db.profile.drStaticIconsPerSpec end,
                                        set = function(info, val)
                                            info.handler.db.profile.drStaticIconsPerSpec = val
                                            if val then
                                                info.handler.db.profile.drStaticIconsPerClass = false
                                            end
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    },
                                    staticIconsSeparator = {
                                        order = 4,
                                        name = "",
                                        type = "header",
                                    },
                                                                drIconsSection = {
                                order = 4,
                                type = "group",
                                name = "",
                                inline = true,
                                disabled = function(info) return not info.handler.db.profile.drStaticIcons end,
                                get = function(info)
                                    local key = info[#info]
                                    local db = info.handler.db
                                    if db.profile.drStaticIconsPerSpec then
                                        local specKey = sArenaMixin.playerSpecID or 0
                                        local perSpec = db.profile.drIconsPerSpec or {}
                                        local specIcons = perSpec[specKey] or {}
                                        return tostring(specIcons[key] or "")
                                    elseif db.profile.drStaticIconsPerClass then
                                        local classKey = sArenaMixin.playerClass
                                        local perClass = db.profile.drIconsPerClass or {}
                                        local classIcons = perClass[classKey] or {}
                                        return tostring(classIcons[key] or "")
                                    else
                                        return tostring(db.profile.drIcons[key] or drIcons[key])
                                    end
                                end,
                                set = function(info, value)
                                    local key = info[#info]
                                    local db = info.handler.db
                                    local num = tonumber(value)
                                    if db.profile.drStaticIconsPerSpec then
                                        db.profile.drIconsPerSpec = db.profile.drIconsPerSpec or {}
                                        local specKey = sArenaMixin.playerSpecID or 0
                                        db.profile.drIconsPerSpec[specKey] = db.profile.drIconsPerSpec[specKey] or {}
                                        db.profile.drIconsPerSpec[specKey][key] = num or value
                                    elseif db.profile.drStaticIconsPerClass then
                                        db.profile.drIconsPerClass = db.profile.drIconsPerClass or {}
                                        local classKey = sArenaMixin.playerClass
                                        db.profile.drIconsPerClass[classKey] = db.profile.drIconsPerClass[classKey] or {}
                                        db.profile.drIconsPerClass[classKey][key] = num or value
                                    else
                                        db.profile.drIcons = db.profile.drIcons or {}
                                        db.profile.drIcons[key] = num or value
                                    end
                                    LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                end,
                                args = setDRIcons(),
                            },
                                },
                            },
                        },
                    },
                    racialGroup = {
                        order = 3,
                        name = "Racials",
                        type = "group",
                        args = (function()
                            local args = {
                                categories = {
                                    order = 1,
                                    name = "Categories",
                                    type = "multiselect",
                                    get = function(info, key) return info.handler.db.profile.racialCategories[key] end,
                                    set = function(info, key, val) info.handler.db.profile.racialCategories[key] = val end,
                                    values = racialCategories,
                                },
                            }
                            args.racialOptions = {
                                order = 2,
                                type = "group",
                                name = "Options",
                                inline = true,
                                args = {
                                    swapRacialTrinket = {
                                        order = 1,
                                        name = "Swap missing Trinket with Racial",
                                        desc = "If the enemy doesn't have a Trinket equipped, remove the gap and show their Racial ability in the spot of the Trinket instead.",
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.swapRacialTrinket end,
                                        set = function(info, val)
                                            info.handler.db.profile.swapRacialTrinket = val
                                        end,
                                    },
                                    forceShowTrinketOnHuman = {
                                        order = 2,
                                        name = "Force Show Trinket on Human (Beta)",
                                        desc = "Always show the Alliance trinket texture on Human players, even if they don't have a trinket equipped.",
                                        type = "toggle",
                                        width = "full",
                                        hidden = function() return isRetail end,
                                        get = function(info) return info.handler.db.profile.forceShowTrinketOnHuman end,
                                        set = function(info, val)
                                            info.handler.db.profile.forceShowTrinketOnHuman = val
                                            if val then
                                                info.handler.db.profile.replaceHumanRacialWithTrinket = false
                                            end
                                        end,
                                    },
                                    replaceHumanRacialWithTrinket = {
                                        order = 3,
                                        name = "Replace Human Racial with Trinket (Beta)",
                                        desc = "Replace the Human racial ability with the Alliance trinket texture in the racial slot.",
                                        type = "toggle",
                                        width = "full",
                                        hidden = function() return isRetail end,
                                        get = function(info) return info.handler.db.profile.replaceHumanRacialWithTrinket end,
                                        set = function(info, val)
                                            info.handler.db.profile.replaceHumanRacialWithTrinket = val
                                            if val then
                                                info.handler.db.profile.forceShowTrinketOnHuman = false
                                            end
                                        end,
                                    },
                                }
                            }

                            return args
                        end)(),
                    },
                    dispelGroup = {
                        order = 4,
                        name = "Dispels (BETA)",
                        type = "group",
                        args = (function()
                            local args = {
                                showDispels = {
                                    order = 0,
                                    name = "Show Dispels (BETA)",
                                    desc = "Enable to show Dispel Cooldown on Arena Frames.",
                                    type = "toggle",
                                    width = "full",
                                    get = function(info) return info.handler.db.profile.showDispels end,
                                    set = function(info, val)
                                        info.handler.db.profile.showDispels = val
                                        info.handler:Test()
                                    end,
                                },
                                spacer0 = {
                                    order = 0.5,
                                    type = "description",
                                    name = "",
                                    width = "full",
                                },
                            }

                            local healerDispels = {}
                            local dpsDispels = {}

                            for spellID, data in pairs(sArenaMixin.dispelData or {}) do
                                if data.healer or data.sharedSpecSpellID then
                                    healerDispels[spellID] = data
                                end
                                if not data.healer or data.sharedSpecSpellID then
                                    dpsDispels[spellID] = data
                                end
                            end

                            local order = 1

                            if next(healerDispels) then
                                args["healer_dispels"] = {
                                    order = order,
                                    name = "Healer Dispels",
                                    type = "group",
                                    inline = true,
                                    disabled = function(info) return not info.handler.db.profile.showDispels end,
                                    args = {}
                                }
                                order = order + 1

                                local healerOrder = 1
                                for spellID, data in pairs(healerDispels) do
                                    -- For MoP shared spells, use separate setting key
                                    local settingKey = spellID
                                    if not isRetail and data.sharedSpecSpellID then
                                        settingKey = spellID .. "_healer"
                                    end

                                    args["healer_dispels"].args["spell_" .. spellID] = {
                                        order = healerOrder,
                                        name = "|T" .. data.texture .. ":16|t " .. data.name,
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.showDispels end,
                                        get = function(info) return info.handler.db.profile.dispelCategories[settingKey] end,
                                        set = function(info, val)
                                            info.handler.db.profile.dispelCategories[settingKey] = val
                                            for i = 1, 3 do
                                                local frame = info.handler["arena" .. i]
                                                if frame then
                                                    frame:UpdateDispel()
                                                end
                                            end
                                        end,
                                        desc = function()
                                            local spellName = GetSpellInfoCompat(spellID)
                                            local spellDesc = GetSpellDescriptionCompat(spellID)

                                            spellName = spellName or data.name or "Unknown Spell"
                                            local cooldownText = data.cooldown and ("Cooldown: " .. data.cooldown .. " seconds") or ""

                                            local tooltipLines = {}
                                            table.insert(tooltipLines, "|cFFFFD700" .. spellName .. "|r")
                                            table.insert(tooltipLines, "|cFF87CEEB" .. data.classes .. "|r")
                                            if spellDesc and spellDesc ~= "" then
                                                table.insert(tooltipLines, spellDesc)
                                            end
                                            if cooldownText ~= "" then
                                                table.insert(tooltipLines, "|cFF00FF00" .. cooldownText .. "|r")
                                            end
                                            table.insert(tooltipLines, "|cFF808080Spell ID: " .. spellID .. "|r")

                                            return table.concat(tooltipLines, "\n\n")
                                        end,
                                    }
                                    healerOrder = healerOrder + 1
                                end
                            end

                            if next(dpsDispels) then
                                args["dps_dispels"] = {
                                    order = order,
                                    name = "DPS Dispels",
                                    type = "group",
                                    inline = true,
                                    disabled = function(info) return not info.handler.db.profile.showDispels end,
                                    args = {
                                        description = {
                                            order = 1,
                                            type = "description",
                                            name = "|cFFFFFF00Note:|r DPS dispels only appear after having been used once.",
                                            fontSize = "medium",
                                        }
                                    }
                                }
                                order = order + 1

                                local dpsOrder = 2
                                for spellID, data in pairs(dpsDispels) do

                                    local settingKey = spellID
                                    if not sArenaMixin.isRetail and data.sharedSpecSpellID then
                                        settingKey = spellID .. "_dps"
                                    end

                                    args["dps_dispels"].args["spell_" .. spellID] = {
                                        order = dpsOrder,
                                        name = "|T" .. (data.texture or "134400") .. ":16|t " .. data.name,
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.showDispels end,
                                        get = function(info) return info.handler.db.profile.dispelCategories[settingKey] end,
                                        set = function(info, val)
                                            info.handler.db.profile.dispelCategories[settingKey] = val
                                            for i = 1, 3 do
                                                local frame = info.handler["arena" .. i]
                                                if frame then
                                                    frame:UpdateDispel()
                                                end
                                            end
                                        end,
                                        desc = function()
                                            local spellName = GetSpellInfoCompat(spellID)
                                            local spellDesc = GetSpellDescriptionCompat(spellID)

                                            spellName = spellName or data.name or "Unknown Spell"
                                            local cooldownText = data.cooldown and ("Cooldown: " .. data.cooldown .. " seconds") or ""

                                            local tooltipLines = {}
                                            table.insert(tooltipLines, "|cFFFFD700" .. spellName .. "|r")
                                            table.insert(tooltipLines, "|cFF87CEEB" .. data.classes .. "|r")
                                            if spellDesc and spellDesc ~= "" then
                                                table.insert(tooltipLines, spellDesc)
                                            end
                                            if cooldownText ~= "" then
                                                table.insert(tooltipLines, "|cFF00FF00" .. cooldownText .. "|r")
                                            end
                                            table.insert(tooltipLines, "|cFF808080Spell ID: " .. spellID .. "|r")
                                            table.insert(tooltipLines, "|cFFFFA500Only shows after having been used once|r")

                                            return table.concat(tooltipLines, "\n\n")
                                        end,
                                    }
                                    dpsOrder = dpsOrder + 1
                                end
                            end

                            args["betaNotice"] = {
                                order = 999,
                                type = "description",
                                name = "\n|cFF808080Dispels are in BETA.\nStill need to confirm some spell ids, especially in Mists of Pandaria.\nThings still need more testing (waiting for PTR) and things may see changes along the way.\nIf you want to contribute info/feedback/spell ids please do!|r",
                                fontSize = "medium",
                                width = "full",
                            }

                            return args
                        end)(),
                    },
                },
            },
            ImportOtherForkSettings = {
                order = 7,
                name = "Other sArena",
                desc = "Import settings from another sArena",
                type = "group",
                args = {
                    description = {
                        order = 1,
                        type = "description",
                        name = "This will import your other sArena settings into the new sArena |cffff8000Reloaded|r |T135884:13:13|t version.\n\nMake sure both addons are enabled, then click the button below.",
                        fontSize = "medium",
                    },
                    convertButton = {
                        order = 2,
                        type = "execute",
                        name = "Import settings",
                        desc = "Import your settings from the other sArena version.",
                        func = sArenaMixin.ImportOtherForkSettings,
                        width = "normal",
                        disabled = function() return sArenaMixin.conversionInProgress end,
                    },
                    conversionStatus = {
                        order = 2.5,
                        type = "description",
                        name = function() return sArenaMixin.conversionStatusText or "" end,
                        fontSize = "medium",
                        hidden = function() return not sArenaMixin.conversionStatusText or sArenaMixin.conversionStatusText == "" end,
                    },
                },
            },
            midnightExpansion = {
                order = 8,
                name = "|cffcc66ffMidnight|r |T136221:16:16|t",
                desc = "World of Warcraft: Midnight plans",
                type = "group",
                args = {
                    description = {
                        order = 1,
                        type = "description",
                        name = "I'm planning to continue developing |cffffffffsArena |cffff8000Reloaded|r |T135884:13:13|t for Midnight as well.\n\nSome features will need to be adjusted or removed but the addon should stick around.\nMidnight is still in early Alpha and I haven't started preparing yet (14th Oct), but I will soon.\n\nPlans might change, but I'm confident |cffffffffsArena |cffff8000Reloaded|r |T135884:13:13|t and my other addons\n|A:gmchat-icon-blizz:16:16|aBetter|cff00c0ffBlizz|rFrames & |A:gmchat-icon-blizz:16:16|aBetter|cff00c0ffBlizz|rPlates will stick around for Midnight (with changes/removals).\n\nI have a lot of work ahead of me, and any support is greatly appreciated. (|cff00c0ff@bodify|r)\nI'll update this section with more detailed information as I know more in some weeks/months.",
                        fontSize = "medium",
                        width = "full",
                    },
                },
            },
            shareProfile = {
                order = 9,
                name = "Share Profile",
                desc = "Export or import a sArena profile",
                type = "group",
                args = {
                    exportHeader = {
                        order = 0,
                        type = "description",
                        name = "|cffffff00Export Profile:|r",
                        fontSize = "large",
                    },
                    exportButton = {
                        order = 1,
                        name = "Export Current Profile",
                        type = "execute",
                        func = function(info)
                            local exportString, err = sArenaMixin:ExportProfile()
                            if not err then
                                sArenaMixin.exportString = exportString
                                sArenaMixin.importInputText = ""
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            else
                                sArenaMixin:Print("Export failed:", err)
                            end
                        end,
                        width = "normal",
                    },
                    exportText = {
                        order = 2,
                        name = "Export String",
                        type = "input",
                        desc = "|cff32f795Ctrl+A|r to select all, |cff32f795Ctrl+C|r to copy",
                        width = "full",
                        multiline = 5,
                        get = function()
                            return sArenaMixin.exportString or ""
                        end,
                        set = function() end,
                    },
                    spacer = {
                        order = 3,
                        type = "description",
                        name = " ",
                    },
                    importHeader = {
                        order = 4,
                        type = "description",
                        name = "|cffffff00Import Profile:|r",
                        fontSize = "large",
                    },
                    importInput = {
                        order = 5,
                        name = "Paste Profile String",
                        desc = "|cff32f795Ctrl+V|r to paste copied profile string",
                        type = "input",
                        width = "full",
                        multiline = 5,
                        get = function()
                            return sArenaMixin.importInputText or ""
                        end,
                        set = function(info, val)
                            sArenaMixin.importInputText = val
                            local str = sArenaMixin.importInputText
                            local success, err = sArenaMixin:ImportProfile(str)
                            if not success then
                                sArenaMixin:Print("|cffff4040Import failed:|r", err)
                            else
                                sArena_ReloadedDB.reOpenOptions = true
                            end
                        end,
                    },
                },
            }
        },
    }
end

