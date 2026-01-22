-- Cursor Ring - Options
local addonName, ns = ...

-- Suppress the 12.0 beta SetText(alpha) range error from AceConfig/Settings,
do
    local oldHandler = geterrorhandler()

    seterrorhandler(function(msg)
        if type(msg) == "string" and msg:find("Usage: self:SetText(text [, color, alpha, wrap])", 1, true) then
            -- Swallow only this known harmless error (AceConfig dropdown hover in 12.0)
            return
        end

        -- Everything else goes to the normal error handler
        return oldHandler(msg)
    end)
end

-- ---------------------------------------------------------------------------
-- Patch AceGUI widget SetText to clamp bad alpha values
-- ---------------------------------------------------------------------------
do
    local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
    if AceGUI and AceGUI.WidgetRegistry and not ns._aceSetTextPatched then
        for _, widget in pairs(AceGUI.WidgetRegistry) do
            if type(widget) == "table" and type(widget.SetText) == "function" then
                local orig = widget.SetText
                widget.SetText = function(self, text, r, g, b, a, wrap, ...)
                    if type(a) ~= "number" or a ~= a or a < -3.402823e+38 or a > 3.402823e+38 then
                        a = 1
                    end
                    return orig(self, text, r, g, b, a, wrap, ...)
                end
            end
        end
        ns._aceSetTextPatched = true
    end
end

-- ---------------------------------------------------------------------------
-- Libs
-- ---------------------------------------------------------------------------
local AceConfig       = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Clamp helper
local function Clamp(v, minV, maxV)
    if v < minV then return minV end
    if v > maxV then return maxV end
    return v
end

-- Ensure DB exists
local function GetDB()
    CursorRingDB     = CursorRingDB     or CopyTable(ns.defaults)
    CursorRingCharDB = CursorRingCharDB or CopyTable(ns.charDefaults)
    return CursorRingDB, CursorRingCharDB
end

local function Refresh()
    if ns and ns.Refresh then
        ns.Refresh()
    end
end

-- --------------------------------------------------
-- Shared getter/setter for Ace options
-- --------------------------------------------------
local function getter(info)
    local key = info[#info]
    local db, cdb = GetDB()
    if key == "gcdEnabled" or key == "gcdStyle" or key == "gcdDimMultiplier" or key == "gcdReverse" then
        return cdb[key]
    end
    return db[key]
end

local function setter(info, val)
    local key = info[#info]
    local db, cdb = GetDB()
    if key == "gcdEnabled" or key == "gcdStyle" or key == "gcdDimMultiplier" or key == "gcdReverse" then
        cdb[key] = val
    else
        db[key] = val
    end
    Refresh()
end

-- --------------------------------------------------
-- Color mode helpers
-- --------------------------------------------------
local colorModeChoices = {
    class   = "Player Class Color",
    highvis = "High-Visibility Green",
    custom  = "Custom Color",
    gradient= "Gradient",
}

local function getColorMode()
    local db = GetDB()
    db = db
    if db.colorMode == "gradient" then
        return "gradient"
    end
    if db.useHighVis or db.colorMode == "highvis" then
        return "highvis"
    end
    if db.useClassColor or db.colorMode == "class" then
        return "class"
    end
    return "custom"
end

local function setColorMode(mode)
    local db = GetDB()
    db = db

    if mode == "gradient" then
        db.colorMode      = "gradient"
        db.useClassColor  = false
        db.useHighVis     = false
    elseif mode == "class" then
        db.useClassColor  = true
        db.useHighVis     = false
        db.colorMode      = "class"
    elseif mode == "highvis" then
        db.useClassColor  = false
        db.useHighVis     = true
        db.colorMode      = "highvis"
    else
        db.useClassColor  = false
        db.useHighVis     = false
        db.colorMode      = "custom"
    end

    Refresh()
end

-- Force class color select
local classForceChoices = {
    NONE         = "None",
    warrior      = "Warrior",
    paladin      = "Paladin",
    hunter       = "Hunter",
    rogue        = "Rogue",
    priest       = "Priest",
    deathknight  = "Death Knight",
    shaman       = "Shaman",
    mage         = "Mage",
    warlock      = "Warlock",
    monk         = "Monk",
    druid        = "Druid",
    demonhunter  = "Demon Hunter",
    evoker       = "Evoker",
}

local function getForcedClass()
    local db = GetDB()
    db = db
    local mode = db.colorMode
    if not mode then return "NONE" end
    if mode == "class" or mode == "custom" or mode == "highvis" or mode == "gradient" then
        return "NONE"
    end
    return mode
end

local function setForcedClass(value)
    local db = GetDB()
    db = db
    if value == "NONE" then
        if db.useHighVis then
            db.colorMode = "highvis"
        elseif db.useClassColor then
            db.colorMode = "class"
        else
            db.colorMode = "custom"
        end
    else
        db.colorMode = value
    end
    Refresh()
end

-- Texture choices
local textureChoices = {
    Default = "Default",
    Thin    = "Thin",
    Thick   = "Thick",
    Solid   = "Solid",
}

-- Size
local function setSize(_, v)
    local db = GetDB()
    db = db
    db.ringRadius = Clamp(math.floor(tonumber(v) or 28), 10, 100)
    Refresh()
end
local function getSize()
    local db = GetDB()
    db = db
    return Clamp(db.ringRadius or 28, 10, 100)
end

-- Offsets
local function setOffsetX(_, v)
    local db = GetDB()
    db = db
    db.offsetX = Clamp(math.floor(tonumber(v) or 0), -300, 300)
    Refresh()
end
local function getOffsetX()
    local db = GetDB()
    db = db
    return Clamp(db.offsetX or 0, -300, 300)
end

local function setOffsetY(_, v)
    local db = GetDB()
    db = db
    db.offsetY = Clamp(math.floor(tonumber(v) or 0), -300, 300)
    Refresh()
end
local function getOffsetY()
    local db = GetDB()
    db = db
    return Clamp(db.offsetY or 0, -300, 300)
end

-- Custom color
local function setCustomColor(_, r, g, b)
    local db = GetDB()
    db = db
    db.customColor = db.customColor or { r = 1, g = 1, b = 1 }
    db.customColor.r, db.customColor.g, db.customColor.b = r, g, b
    db.useClassColor = false
    db.useHighVis    = false
    db.colorMode     = "custom"
    Refresh()
end
local function getCustomColor()
    local db = GetDB()
    db = db
    local c = db.customColor or { r = 1, g = 1, b = 1 }
    return c.r or 1, c.g or 1, c.b or 1
end

-- Gradient colors
local function setGradientColor1(_, r, g, b)
    local db = GetDB()
    db = db
    db.gradientColor1 = db.gradientColor1 or { r = 1, g = 1, b = 1 }
    db.gradientColor1.r, db.gradientColor1.g, db.gradientColor1.b = r, g, b
    Refresh()
end

local function getGradientColor1()
    local db = GetDB()
    db = db
    local c = db.gradientColor1 or { r = 1, g = 1, b = 1 }
    return c.r or 1, c.g or 1, c.b or 1
end

local function setGradientColor2(_, r, g, b)
    local db = GetDB()
    db = db
    db.gradientColor2 = db.gradientColor2 or { r = 1, g = 1, b = 1 }
    db.gradientColor2.r, db.gradientColor2.g, db.gradientColor2.b = r, g, b
    Refresh()
end

local function getGradientColor2()
    local db = GetDB()
    db = db
    local c = db.gradientColor2 or { r = 1, g = 1, b = 1 }
    return c.r or 1, c.g or 1, c.b or 1
end

local function setGradientAngle(_, v)
    local db = GetDB()
    db = db
    v = tonumber(v) or 0
    v = v % 360
    db.gradientAngle = v
    Refresh()
end

local function getGradientAngle()
    local db = GetDB()
    db = db
    return db.gradientAngle or 0
end

-- --------------------------------------------------
-- AceConfig options table
-- --------------------------------------------------
local options = {
    type = "group",
    name = "Cursor Ring",
    args = {
        header = {
            type  = "header",
            name  = "Cursor Ring",
            order = 0,
        },
        desc = {
            type  = "description",
            name  = "Anchors a ring to your cursor and optionally shows a GCD swipe using Blizzard's Cooldown widget.",
            order = 1,
        },

        gradientWarning = {
            type  = "description",
            name  = "Gradient mode now respects alpha settings, in/out-of-combat changes, and the GCD swipe.",
            order = 2,
        },

        appearance = {
            type   = "group",
            name   = "Appearance",
            inline = true,
            order  = 10,
            args   = {
                textureKey = {
                    type   = "select",
                    name   = "Texture",
                    desc   = "Ring texture art.",
                    values = textureChoices,
                    get    = getter,
                    set    = setter,
                    order  = 10,
                    width  = "full",
                },
                ringRadius = {
                    type  = "range",
                    name  = "Size",
                    desc  = "Ring radius in pixels (visual diameter is 2x).",
                    min   = 10,
                    max   = 100,
                    step  = 1,
                    get   = getSize,
                    set   = setSize,
                    order = 11,
                    width = "full",
                },
                offsetX = {
                    type  = "range",
                    name  = "Horizontal Offset",
                    desc  = "Move the ring left or right relative to your cursor.",
                    min   = -300,
                    max   = 300,
                    step  = 1,
                    get   = getOffsetX,
                    set   = setOffsetX,
                    order = 12,
                    width = "full",
                },
                offsetY = {
                    type  = "range",
                    name  = "Vertical Offset",
                    desc  = "Move the ring up or down relative to your cursor.",
                    min   = -300,
                    max   = 300,
                    step  = 1,
                    get   = getOffsetY,
                    set   = setOffsetY,
                    order = 13,
                    width = "full",
                },

                sep1 = {
                    type  = "description",
                    name  = " ",
                    order = 14,
                },

                colorMode = {
                    type   = "select",
                    name   = "Color Mode",
                    desc   = "Choose how the ring is colored.",
                    values = colorModeChoices,
                    get    = function() return getColorMode() end,
                    set    = function(_, v) setColorMode(v) end,
                    order  = 20,
                    width  = "full",
                },

                forceClass = {
                    type   = "select",
                    name   = "Force Class Color",
                    desc   = "Optionally force a specific class color.",
                    values = classForceChoices,
                    get    = function() return getForcedClass() end,
                    set    = function(_, v) setForcedClass(v) end,
                    order  = 21,
                    width  = "full",
                },

                customColor = {
                    type   = "color",
                    name   = "Custom Color",
                    desc   = "Custom color used when Color Mode is set to Custom.",
                    hasAlpha = false,
                    get    = getCustomColor,
                    set    = setCustomColor,
                    order  = 22,
                    width  = "full",
                },

                gradientHeader = {
                    type  = "header",
                    name  = "Gradient",
                    order = 30,
                },
                gradientColor1 = {
                    type   = "color",
                    name   = "Gradient Color 1",
                    desc   = "First color used for the gradient ring.",
                    hasAlpha = false,
                    get    = getGradientColor1,
                    set    = setGradientColor1,
                    order  = 31,
                    width  = "full",
                    disabled = function()
                        local db = GetDB()
                        db = db
                        return db.colorMode ~= "gradient"
                    end,
                },
                gradientColor2 = {
                    type   = "color",
                    name   = "Gradient Color 2",
                    desc   = "Second color used for the gradient ring.",
                    hasAlpha = false,
                    get    = getGradientColor2,
                    set    = setGradientColor2,
                    order  = 32,
                    width  = "full",
                    disabled = function()
                        local db = GetDB()
                        db = db
                        return db.colorMode ~= "gradient"
                    end,
                },
                gradientAngle = {
                    type  = "range",
                    name  = "Gradient Angle",
                    desc  = "Rotate the gradient around the ring (degrees).",
                    min   = 0,
                    max   = 359,
                    step  = 1,
                    get   = getGradientAngle,
                    set   = setGradientAngle,
                    order = 33,
                    width = "full",
                    disabled = function()
                        local db = GetDB()
                        db = db
                        return db.colorMode ~= "gradient"
                    end,
                },

                sep2 = {
                    type  = "description",
                    name  = " ",
                    order = 40,
                },

                inCombatAlpha = {
                    type  = "range",
                    name  = "In-Combat Alpha",
                    desc  = "Opacity of the ring while you are in combat.",
                    min   = 0,
                    max   = 1,
                    step  = 0.01,
                    get   = getter,
                    set   = setter,
                    order = 41,
                    width = "full",
                },
                outCombatAlpha = {
                    type  = "range",
                    name  = "Out-of-Combat Alpha",
                    desc  = "Opacity of the ring while you are out of combat.",
                    min   = 0,
                    max   = 1,
                    step  = 0.01,
                    get   = getter,
                    set   = setter,
                    order = 42,
                    width = "full",
                },
            },
        },

        behavior = {
            type   = "group",
            name   = "Behavior",
            inline = true,
            order  = 20,
            args   = {
                visible = {
                    type  = "toggle",
                    name  = "Show Ring",
                    desc  = "Toggle the ring on or off.",
                    get   = getter,
                    set   = setter,
                    order = 10,
                    width = "full",
                },
                hideOnRightClick = {
                    type  = "toggle",
                    name  = "Hide on Right-Click (Hold)",
                    desc  = "Temporarily hides the ring while the right mouse button is held.",
                    get   = getter,
                    set   = setter,
                    order = 11,
                    width = "full",
                },
                showHelpOnLogin = {
                    type  = "toggle",
                    name  = "Show Help Message on Login",
                    desc  = "If enabled, prints a short help message to chat each time you log in.",
                    get   = getter,
                    set   = setter,
                    order = 12,
                    width = "full",
                },
            },
        },

        gcd = {
            type   = "group",
            name   = "GCD Swipe",
            inline = true,
            order  = 30,
            args   = {
                gcdEnabled = {
                    type  = "toggle",
                    name  = "Enable GCD Swipe",
                    desc  = "Show a cooldown swipe on the ring during the global cooldown.",
                    get   = getter,
                    set   = setter,
                    order = 10,
                    width = "full",
                },
                gcdStyle = {
                    type   = "select",
                    name   = "GCD Swipe Style",
                    desc   = "Choose which visual style to use for the GCD swipe.",
                    values = {
                        simple   = "Simple (No Edge)",
                        blizzard = "Blizzard-Style Edge",
                    },
                    get   = getter,
                    set   = setter,
                    disabled = function()
                        local _, cdb = GetDB()
                        return not cdb.gcdEnabled
                    end,
                    order  = 11,
                    width  = "full",
                },
                gcdDimMultiplier = {
                    type  = "range",
                    name  = "Background Ring Hide During GCD",
                    desc  = "While the GCD swipe is active: 0 = ring at out-of-combat alpha, 1 = ring fully hidden under the swipe.",
                    min   = 0,
                    max   = 1,
                    step  = 0.01,
                    get   = getter,
                    set   = setter,
                    disabled = function()
                        local _, cdb = GetDB()
                        return not cdb.gcdEnabled
                    end,
                    order = 12,
                    width = "full",
                },
                gcdReverse = {
                    type  = "toggle",
                    name  = "Reverse GCD Swipe (Fill Ring)",
                    desc  = "If enabled, the GCD swipe will fill the ring instead of emptying it.",
                    get   = getter,
                    set   = setter,
                    disabled = function()
                        local _, cdb = GetDB()
                        return not cdb.gcdEnabled
                    end,
                    order = 13,
                    width = "full",
                },
            },
        },

        help = {
            type   = "group",
            name   = "Help",
            inline = true,
            order  = 40,
            args   = {
                helpText = {
                    type  = "description",
                    name  = [[
Slash commands:
  /cr show        - Show the ring
  /cr hide        - Hide the ring
  /cr toggle      - Toggle visibility
  /cr reset       - Reset to defaults

  /cr gcd         - Toggle the GCD swipe
  /cr gcdstyle    - Set GCD style (simple / blizzard)
  /cr color       - Set color mode (class, highvis, custom, gradient, or class token)
  /cr alpha       - Set in/out-of-combat alpha
  /cr texture     - Change ring texture
  /cr size        - Change ring size
  /cr right-click - Configure hide-on-right-click behavior]],
                    order = 10,
                },
            },
        },
    },
}

AceConfig:RegisterOptionsTable("CursorRing", options)
local panel = AceConfigDialog:AddToBlizOptions("CursorRing", "Cursor Ring")

local function AddSub(name, path)
    return AceConfigDialog:AddToBlizOptions("CursorRing", name, "Cursor Ring", path)
end

AddSub("Appearance", "appearance")
AddSub("Behavior", "behavior")
AddSub("GCD Swipe", "gcd")
AddSub("Help", "help")

-- Ensure DB exists even if options opened before PLAYER_LOGIN
GetDB()
