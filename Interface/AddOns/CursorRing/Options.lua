-- Cursor Ring - Options (row-based layout)
local _, ns = ...

local function Refresh() ns.Refresh() end

local function isGCDDisabled() return not (CursorRingCharDB and CursorRingCharDB.gcdEnabled) end

local options = {
    name = "Cursor Ring",
    type = "group",
    childGroups = "tab",
    args = {
        appearance = {
            name = "Appearance",
            type = "group",
            order = 1,
            args = {
                -- Row 1: [ ] GCD timer | GCD Style dropdown | GCD emphasis slider
                rowGCD = {
                    type = "group",
                    name = "GCD",
                    order = 0,
                    inline = true,
                    args = {
                        gcdEnabled = {
                            name  = "GCD timer",
                            desc  = "Show a swipe around the ring while the global cooldown is active.",
                            type  = "toggle",
                            width = "quarter",
                            order = 1,
                            get   = function() return CursorRingCharDB and CursorRingCharDB.gcdEnabled end,
                            set   = function(_, v)
                                CursorRingCharDB.gcdEnabled = v and true or false
                                Refresh()
                            end,
                        },
                        gcdStyle = {
                            name  = "GCD style",
                            desc  = "Choose between Square, Blizzard-style and a simple sweep.",
                            type  = "select",
                            width = "third",
                            order = 2,
                            values = { blizzard = "Square", classic = "Blizzard", simple = "Simple" },
                            get = function() return CursorRingCharDB and (CursorRingCharDB.gcdStyle or "simple") end,
                            set = function(_, v)
                                CursorRingCharDB.gcdStyle = v
                                Refresh()
                            end,
                            disabled = isGCDDisabled,
                        },
                        gcdDim = {
                            name  = "GCD emphasis",
                            desc  = "How strongly to dim the base ring while the GCD swipe is visible.",
                            type  = "range",
                            width = "third",
                            order = 3,
                            isPercent = true,
                            min = 0, max = 1, step = 0.05,
                            get = function() return (CursorRingCharDB and CursorRingCharDB.gcdDimMultiplier) or 0.35 end,
                            set = function(_, v)
                                if v < 0 then v = 0 elseif v > 1 then v = 1 end
                                CursorRingCharDB.gcdDimMultiplier = v
                                Refresh()
                            end,
                            disabled = isGCDDisabled,
                        },
                    },
                },

                -- Row 2: [ ] Show/Hide | [ ] Hide on right-click | Ring Radius slider
                rowVis = {
                    type  = "group",
                    name  = "Visibility",
                    order = 1,
                    inline = true,
                    args = {
                        visible = {
                            name  = "Show / Hide",
                            type  = "toggle",
                            width = "quarter",
                            order = 1,
                            get = function() return CursorRingDB.visible end,
                            set = function(_, v) CursorRingDB.visible = v; Refresh() end,
                        },
                        hideOnRightClick = {
                            name  = "Hide on right-click",
                            type  = "toggle",
                            width = "third",
                            order = 2,
                            get = function() return CursorRingDB.hideOnRightClick end,
                            set = function(_, v) CursorRingDB.hideOnRightClick = v; Refresh() end,
                        },
                        ringRadius = {
                            name  = "Ring radius",
                            type  = "range",
                            width = "third",
                            order = 3,
                            min = 10, max = 100, step = 1,
                            get = function() return CursorRingDB.ringRadius end,
                            set = function(_, v)
                                v = math.max(10, math.min(100, math.floor(v or 28)))
                                CursorRingDB.ringRadius = v
                                Refresh()
                            end,
                        },
                    },
                },

                -- Row 3: [ ] Use Class C | [ ] High-vis Color | Class preset dropdown | [ ] Use custom color | color swatch
                rowColor = {
                    type  = "group",
                    name  = "Color",
                    order = 2,
                    inline = true,
                    args = {
                        useClassColor = {
                            name  = "Use class color",
                            type  = "toggle",
                            width = "quarter",
                            order = 1,
                            get = function() return CursorRingDB.useClassColor end,
                            set = function(_, v)
                                CursorRingDB.useClassColor = v
                                if v then
                                    CursorRingDB.useHighVis = false
                                    CursorRingDB.colorMode = "class"
                                end
                                Refresh()
                            end,
                        },
                        useHighVis = {
                            name  = "High-vis color",
                            type  = "toggle",
                            width = "third",
                            order = 2,
                            get = function() return CursorRingDB.useHighVis end,
                            set = function(_, v)
                                CursorRingDB.useHighVis = v
                                CursorRingDB.useClassColor = false
                                if v then CursorRingDB.colorMode = "highvis" end
                                Refresh()
                            end,
                        },
                        classColorSelect = {
                            name  = "Class preset",
                            type  = "select",
                            width = "third",
                            order = 3,
                            values = {
                                deathknight = "Death Knight",
                                demonhunter = "Demon Hunter",
                                druid       = "Druid",
                                evoker      = "Evoker",
                                hunter      = "Hunter",
                                mage        = "Mage",
                                monk        = "Monk",
                                paladin     = "Paladin",
                                priest      = "Priest",
                                rogue       = "Rogue",
                                shaman      = "Shaman",
                                warlock     = "Warlock",
                                warrior     = "Warrior",
                            },
                            get = function()
                                if CursorRingDB.useHighVis then return "highvis" end
                                if CursorRingDB.useClassColor then return "default" end
                                return CursorRingDB.colorMode
                            end,
                            set = function(_, v)
                                if v == "default" then
                                    CursorRingDB.useClassColor = true
                                    CursorRingDB.useHighVis = false
                                    CursorRingDB.colorMode = "class"
                                elseif v == "highvis" then
                                    CursorRingDB.useClassColor = false
                                    CursorRingDB.useHighVis = true
                                    CursorRingDB.colorMode = "highvis"
                                else
                                    CursorRingDB.useClassColor = false
                                    CursorRingDB.useHighVis = false
                                    CursorRingDB.colorMode = v
                                end
                                Refresh()
                            end,
                            disabled = function() return CursorRingDB.useClassColor or CursorRingDB.useHighVis end,
                        },
                        useCustom = {
                            name  = "Use custom color",
                            type  = "toggle",
                            width = "quarter",
                            order = 4,
                            get = function() return (not CursorRingDB.useClassColor) and (not CursorRingDB.useHighVis) and CursorRingDB.colorMode == "custom" end,
                            set = function(_, v)
                                if v then
                                    CursorRingDB.useClassColor = false
                                    CursorRingDB.useHighVis    = false
                                    CursorRingDB.colorMode     = "custom"
                                else
                                    CursorRingDB.useClassColor = true
                                    CursorRingDB.colorMode     = "class"
                                end
                                Refresh()
                            end,
                        },
                        customColor = {
                            name  = "Custom",
                            type  = "color",
                            hasAlpha = false,
                            width = "quarter",
                            order = 5,
                            get = function()
                                local c = CursorRingDB.customColor
                                return c.r, c.g, c.b
                            end,
                            set = function(_, r, g, b)
                                CursorRingDB.useClassColor = false
                                CursorRingDB.useHighVis    = false
                                CursorRingDB.colorMode     = "custom"
                                CursorRingDB.customColor   = { r = r, g = g, b = b }
                                Refresh()
                            end,
                            disabled = function() return not ((not CursorRingDB.useClassColor) and (not CursorRingDB.useHighVis) and CursorRingDB.colorMode == "custom") end,
                        },
                    },
                },

                -- Row 4: Out-of-combat slider | In-combat slider | Texture dropdown
                rowAlphaTex = {
                    type  = "group",
                    name  = "Alpha & Texture",
                    order = 3,
                    inline = true,
                    args = {
                        outCombatAlpha = {
                            name  = "Out-of-combat alpha",
                            type  = "range",
                            width = "third",
                            order = 1,
                            isPercent = true,
                            min = 0, max = 1, step = 0.01,
                            get = function() return CursorRingDB.outCombatAlpha end,
                            set = function(_, v)
                                v = tonumber(v) or CursorRingDB.outCombatAlpha
                                if v < 0 then v = 0 end
                                if v > 1 then v = 1 end
                                CursorRingDB.outCombatAlpha = v
                                Refresh()
                            end,
                        },
                        inCombatAlpha = {
                            name  = "In-combat alpha",
                            type  = "range",
                            width = "third",
                            order = 2,
                            isPercent = true,
                            min = 0, max = 1, step = 0.01,
                            get = function() return CursorRingDB.inCombatAlpha end,
                            set = function(_, v)
                                v = tonumber(v) or CursorRingDB.inCombatAlpha
                                if v < 0 then v = 0 end
                                if v > 1 then v = 1 end
                                CursorRingDB.inCombatAlpha = v
                                Refresh()
                            end,
                        },
                        textureSelect = {
                            name  = "Texture",
                            type  = "select",
                            width = "third",
                            order = 3,
                            values = { Default = "Default", Thin = "Thin", Thick = "Thick", Solid = "Solid" },
                            get = function() return CursorRingDB.textureKey end,
                            set = function(_, v)
                                local NormalizeTextureKey = ns and ns.NormalizeTextureKey
                                if NormalizeTextureKey then v = NormalizeTextureKey(v) end
                                CursorRingDB.textureKey = v
                                Refresh()
                            end,
                        },
                    },
                },

                -- Slash commands helper box
                slashHelp = {
                    name  = "Slash Commands",
                    type  = "group",
                    order = 10,
                    inline = true,
                    args = {
                        line1 = { type="description", order=1, name="|cff00ff00/cr gcd|r – toggle GCD swipe" },
                        line2 = { type="description", order=2, name="|cff00ff00/cr gcdstyle blizzard|simple|r – pick the GCD visual" },
                        line3 = { type="description", order=3, name="|cff00ff00/cr color <name>|r – default | highvis | custom | class or alias" },
                        line4 = { type="description", order=4, name="|cff00ff00/cr alpha in|out 0-1|r  |  |cff00ff00/cr size 10-100|r" },
                        line5 = { type="description", order=5, name="|cff00ff00/cr texture <name>|r  |  |cff00ff00/cr right-click enable | disable | toggle|r" },
                        extra = {
                            type="description", order=6, hidden=function() return not (ns and ns.DEBUG_GCD) end,
                            name="|cff00ff00/cr gcdtest|r – force a 1.5s test swipe and print debug info",
                        },
                    },
                },

                reset = {
                    name = "Reset to defaults",
                    type = "execute",
                    order = 99,
                    func = function()
                        CursorRingDB = CopyTable(ns.defaults)
                        Refresh()
                    end,
                },
            },
        },
    },
}

-- Loader
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    CursorRingDB     = CursorRingDB     or CopyTable(ns.defaults)
    CursorRingCharDB = CursorRingCharDB or CopyTable(ns.charDefaults)

    local AceConfig    = LibStub("AceConfig-3.0")
    local AceConfigDlg = LibStub("AceConfigDialog-3.0")
    AceConfig:RegisterOptionsTable("Cursor Ring", options)
    AceConfigDlg:AddToBlizOptions("Cursor Ring", "Cursor Ring")
end)
