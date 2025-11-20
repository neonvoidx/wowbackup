-- Cursor Ring - Core (Retail 11.2.x + Midnight 12.0-safe)
-- Anchors a ring to the mouse cursor and (optionally) shows a GCD swipe using Blizzard's Cooldown widget.

local addonName, ns = ...

-- Locals
local UIParent = UIParent
local CreateFrame = CreateFrame
local GetScaledCursorPosition = GetScaledCursorPosition
local UnitClass = UnitClass
local CopyTable = CopyTable
local strlower = string.lower
local strupper = string.upper
local tostring = tostring
local type = type
local InCombatLockdown = InCombatLockdown
local C_ClassColor = C_ClassColor
local math = math

-- Debug flag (chat spam only when true)
ns.DEBUG_GCD = false

-- Normalize a texture name to a known key
function ns.NormalizeTextureKey(name)
    if not name then return "Default" end
    name = strlower(name)
    if name == "default" then return "Default" end
    if name == "thin" then return "Thin" end
    if name == "thick" then return "Thick" end
    if name == "solid" then return "Solid" end
    return string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
end

-- Texture files
ns.textures = {
    Default = "Interface\\AddOns\\CursorRing\\media\\Default.png",
    Thin    = "Interface\\AddOns\\CursorRing\\media\\Thin.png",
    Thick   = "Interface\\AddOns\\CursorRing\\media\\Thick.png",
    Solid   = "Interface\\AddOns\\CursorRing\\media\\Solid.png",
}

-- Account-wide defaults
ns.defaults = {
    ringRadius          = 28,
    textureKey          = "Default",
    inCombatAlpha       = 0.70,
    outCombatAlpha      = 0.30,

    -- Color selection
    -- colorMode:
    --   "class"    = player class
    --   "highvis"  = bright green
    --   "custom"   = customColor
    --   "gradient" = gradientColor1/2 + gradientAngle
    --   <class id> = forced specific class color (for swipe / solid ring)
    useClassColor       = true,       -- legacy, migrated on login
    useHighVis          = false,      -- legacy, migrated on login
    colorMode           = "class",
    customColor         = { r = 1, g = 1, b = 1 },

    visible             = true,
    hideOnRightClick    = true,

    -- Help message behavior
    helpMessageShownOnce = false,
    showHelpOnLogin      = false,

    -- Offsets relative to cursor
    offsetX             = 0,
    offsetY             = 0,

    -- Gradient config (used when colorMode == "gradient")
    -- gradientEnabled is legacy and ignored now
    gradientAngle       = 0,           -- degrees, 0..360
    gradientColor1      = { r = 1, g = 1, b = 1 },
    gradientColor2      = { r = 1, g = 1, b = 1 },
}

-- Per-character defaults
ns.charDefaults = {
    gcdEnabled        = true,          -- GCD swipe ON by default
    gcdStyle          = "simple",      -- "simple" or "blizzard"
    gcdDimMultiplier  = 0.35,          -- Emphasis for hiding the ring under the GCD swipe
    gcdReverse        = false,         -- when true, swipe fills the ring instead of emptying
}

-- Primary frames
local ring = CreateFrame("Frame", nil, UIParent)
ring:SetFrameStrata("TOOLTIP")

local tex = ring:CreateTexture(nil, "ARTWORK")
tex:SetAllPoints()

-- GCD Cooldown overlay (Blizzard template animates; we do not compute times)
local gcd = CreateFrame("Cooldown", nil, ring, "CooldownFrameTemplate")
gcd:SetAllPoints()
gcd:EnableMouse(false)
gcd:SetDrawSwipe(true)
gcd:SetDrawEdge(true)
gcd:SetHideCountdownNumbers(true)
if gcd.SetUseCircularEdge then gcd:SetUseCircularEdge(true) end
gcd:SetFrameStrata("TOOLTIP")
gcd:SetFrameLevel(ring:GetFrameLevel() + 3)

-- State
local lastInCombat = nil

local function GetRingBaseAlpha()
    local db = CursorRingDB
    if not db then return 1 end
    local inAlpha = db.inCombatAlpha or 0.70
    local outAlpha = db.outCombatAlpha or 0.30
    if InCombatLockdown() then
        return inAlpha
    else
        return outAlpha
    end
end

local function Clamp01(v)
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end

-- Color aliases for slash convenience
ns.colorAlias = {
    red         = "deathknight",
    magenta     = "demonhunter",
    orange      = "druid",
    darkgreen   = "evoker",
    green       = "hunter",
    lightgreen  = "monk",
    blue        = "shaman",
    lightblue   = "mage",
    pink        = "paladin",
    white       = "priest",
    yellow      = "rogue",
    purple      = "warlock",
    tan         = "warrior",
}

-- This is used for the GCD swipe color (overlay) and for solid ring mode.
-- It does NOT color the ring when colorMode == "gradient"; the ring is handled in UpdateAppearance.
local function GetColor()
    local db = CursorRingDB
    if not db then
        return 1, 1, 1
    end

    local mode = db.colorMode or "class"

    -- Gradient mode: solid color for the swipe is the average of the two gradient colors.
    if mode == "gradient" then
        local c1 = db.gradientColor1 or {}
        local c2 = db.gradientColor2 or {}

        local r1 = c1.r or 1
        local g1 = c1.g or 1
        local b1 = c1.b or 1

        local r2 = c2.r or r1
        local g2 = c2.g or g1
        local b2 = c2.b or b1

        return (r1 + r2) / 2, (g1 + g2) / 2, (b1 + b2) / 2
    end

    if mode == "highvis" then
        return 0, 1, 0
    end

    if mode == "custom" then
        local c = db.customColor or { r = 1, g = 1, b = 1 }
        return c.r or 1, c.g or 1, c.b or 1
    end

    -- "class" mode: player class color
    if mode == "class" then
        local _, classFile = UnitClass("player")
        local color = C_ClassColor.GetClassColor(classFile)
        if color then
            return color.r, color.g, color.b
        else
            return 1, 1, 1
        end
    end

    -- Specific class token
    local classFile = ns.colorAlias[mode] or mode
    local color2 = C_ClassColor.GetClassColor(strupper(classFile or ""))
    if color2 then
        return color2.r, color2.g, color2.b
    end

    return 1, 1, 1
end

-----------------------------------------------------------------------
-- Right-click hide: hide/show the entire ring frame
-----------------------------------------------------------------------
WorldFrame:HookScript("OnMouseDown", function(_, button)
    if button == "RightButton" and CursorRingDB and CursorRingDB.hideOnRightClick then
        ring:Hide()
    end
end)

WorldFrame:HookScript("OnMouseUp", function(_, button)
    if button == "RightButton" and CursorRingDB and CursorRingDB.hideOnRightClick then
        ring:Show()
    end
end)

-----------------------------------------------------------------------
-- GCD swipe alpha helper (separate from ring emphasis)
-----------------------------------------------------------------------
local function GetSwipeAlpha()
    -- Swipe follows the base in/out-of-combat alpha, but is clamped to 0..1
    return Clamp01(GetRingBaseAlpha())
end

-----------------------------------------------------------------------
-- GCD style / swipe
-----------------------------------------------------------------------
local function UpdateGCDStyle()
    if not (CursorRingCharDB and CursorRingCharDB.gcdEnabled) then
        gcd:Hide()
        return
    end

    local r, g, b = GetColor()
    local key = "Default"
    if CursorRingDB and CursorRingDB.textureKey then
        key = CursorRingDB.textureKey
    end
    local texPath = ns.textures[key] or ns.textures.Default
    if gcd.SetSwipeTexture then
        gcd:SetSwipeTexture(texPath)
    end

    local style = "simple"
    if CursorRingCharDB and CursorRingCharDB.gcdStyle then
        style = CursorRingCharDB.gcdStyle
    end

    local swipeA = GetSwipeAlpha()

    if style == "simple" then
        gcd:SetDrawEdge(false)
        if gcd.SetDrawBling then gcd:SetDrawBling(false) end
        gcd:SetSwipeColor(r, g, b, swipeA)
    else
        gcd:SetDrawEdge(true)
        if gcd.SetDrawBling then gcd:SetDrawBling(false) end
        gcd:SetSwipeColor(r, g, b, swipeA)
    end

    local reverse = CursorRingCharDB and CursorRingCharDB.gcdReverse
    if gcd.SetReverse then
        gcd:SetReverse(not not reverse)
    end

    -- Do NOT decide whether GCD is active here; that is handled by cooldown logic.
end

-----------------------------------------------------------------------
-- Ring appearance (color + alpha) – single source of truth
-----------------------------------------------------------------------
local function UpdateAppearance()
    local db = CursorRingDB or ns.defaults
    local texture = ns.textures[db.textureKey] or ns.textures.Default
    local radius  = db.ringRadius or 28
    local mode    = db.colorMode or "class"

    tex:SetTexture(texture)

    -- Base alpha from in-combat / out-of-combat
    local baseAlpha = GetRingBaseAlpha()

    -- Decide ring alpha:
    --   - If no GCD swipe is actually visible/active, use baseAlpha.
    --   - If GCD swipe is visible and enabled, fade between baseAlpha and 0
    --     based on gcdDimMultiplier:
    --         E = 0 -> ringAlpha = baseAlpha
    --         E = 1 -> ringAlpha = 0
    local ringAlpha
    if gcd:IsShown() and CursorRingCharDB and CursorRingCharDB.gcdEnabled then
        local e = CursorRingCharDB.gcdDimMultiplier or 0
        e = Clamp01(e)
        ringAlpha = baseAlpha * (1 - e)
    else
        ringAlpha = baseAlpha
    end

    -- Reset rotation & clear any previous gradient
    if tex.SetRotation then
        tex:SetRotation(0)
    end
    if tex.SetGradient then
        if CreateColor then
            tex:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 1), CreateColor(1, 1, 1, 1))
        else
            tex:SetGradient("HORIZONTAL", 1, 1, 1, 1, 1, 1, 1, 1)
        end
    end

    if mode == "gradient" and tex.SetGradient then
        -- Gradient ring path: this is the ONLY place that colors the ring when in gradient mode.
        local c1 = db.gradientColor1 or {}
        local c2 = db.gradientColor2 or {}

        local r1 = c1.r or 1
        local g1 = c1.g or 1
        local b1 = c1.b or 1

        local r2 = c2.r or r1
        local g2 = c2.g or g1
        local b2 = c2.b or b1

        tex:SetVertexColor(1, 1, 1) -- neutral base

        -- RGB gradient only; alpha is controlled purely by tex:SetAlpha(ringAlpha)
        if CreateColor then
            tex:SetGradient("HORIZONTAL",
                CreateColor(r1, g1, b1, 1),
                CreateColor(r2, g2, b2, 1)
            )
        else
            tex:SetGradient("HORIZONTAL",
                r1, g1, b1, 1,
                r2, g2, b2, 1
            )
        end

        local angle = db.gradientAngle or 0
        angle = angle % 360
        if tex.SetRotation then
            tex:SetRotation(angle * math.pi / 180)
        end

        tex:SetAlpha(ringAlpha)
    else
        -- Solid color path (class/highvis/custom/forced class)
        local cr, cg, cb = GetColor()
        tex:SetVertexColor(cr, cg, cb)
        tex:SetAlpha(ringAlpha)
    end

    ring:SetSize(radius * 2, radius * 2)
    UpdateGCDStyle()
end
ns.UpdateAppearance = UpdateAppearance

-----------------------------------------------------------------------
-- Cooldown handling (no secret fields)
-----------------------------------------------------------------------
local function ReadSpellCooldown(spellID)
    if C_Spell and C_Spell.GetSpellCooldown then
        local a, b, c, d = C_Spell.GetSpellCooldown(spellID)
        if type(a) == "table" then
            local t = a
            local start = t.startTime or t.start
            local duration = t.duration
            local modRate = t.modRate
            return start, duration, modRate
        else
            -- 11.x tuple: start, duration, enable, modRate
            local start2, duration2, _enable, modRate2 = a, b, c, d
            return start2, duration2, modRate2
        end
    end
    if GetSpellCooldown then
        local s, d = GetSpellCooldown(spellID)
        return s, d, nil
    end
end

local GCD_SPELL_ID = 61304

local function IsCooldownActive(start, duration)
    if not start or not duration then return false end
    if duration <= 0 then return false end
    if start <= 0 then return false end
    return true
end

local function UpdateGCDCooldown()
    if not (CursorRingCharDB and CursorRingCharDB.gcdEnabled) then
        gcd:Hide()
        ns.UpdateAppearance()
        return
    end

    local start, duration, modRate = ReadSpellCooldown(GCD_SPELL_ID)
    if IsCooldownActive(start, duration) then
        gcd:Show()
        if modRate then
            gcd:SetCooldown(start, duration, modRate)
        else
            gcd:SetCooldown(start, duration)
        end
        ns.UpdateAppearance()
    else
        gcd:Hide()
        ns.UpdateAppearance()
    end
end

-----------------------------------------------------------------------
-- Debug helpers
-----------------------------------------------------------------------
local function Say(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00CursorRing:|r " .. tostring(msg))
end

local function PrintDebug(msg)
    if ns.DEBUG_GCD then
        Say(msg)
    end
end

local function DumpGCDState(header)
    if not ns.DEBUG_GCD then return end
    PrintDebug("=== " .. tostring(header) .. " ===")
    local s, d, m = ReadSpellCooldown(GCD_SPELL_ID)
    PrintDebug("Cooldown types -> start=" .. tostring(type(s)) .. ", duration=" .. tostring(type(d)) .. ", modRate=" .. tostring(type(m)))
end

-----------------------------------------------------------------------
-- Events
-----------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("SPELL_UPDATE_COOLDOWN")
f:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

f:SetScript("OnEvent", function(self, event, unit, arg3, spellID)
    if event == "PLAYER_LOGIN" then
        CursorRingDB     = CursorRingDB     or CopyTable(ns.defaults)
        CursorRingCharDB = CursorRingCharDB or CopyTable(ns.charDefaults)

        local db = CursorRingDB

        -- Help flags
        if db.helpMessageShownOnce == nil then
            db.helpMessageShownOnce = false
        end
        if db.showHelpOnLogin == nil then
            db.showHelpOnLogin = false
        end

        -- Offsets
        if db.offsetX == nil then db.offsetX = 0 end
        if db.offsetY == nil then db.offsetY = 0 end

        -- Gradient fields (legacy gradientEnabled is ignored)
        db.gradientEnabled = nil
        if db.gradientAngle == nil then
            db.gradientAngle = 0
        end
        if not db.gradientColor1 then
            db.gradientColor1 = { r = 1, g = 1, b = 1 }
        end
        if not db.gradientColor2 then
            db.gradientColor2 = { r = 1, g = 1, b = 1 }
        end

        -- Color mode migration (one-time from old useClassColor/useHighVis)
        if db.colorMode == nil then
            if db.useHighVis then
                db.colorMode = "highvis"
            elseif db.useClassColor == false then
                db.colorMode = "custom"
            else
                db.colorMode = "class"
            end
        end

        ring:SetShown(db.visible)
        lastInCombat = InCombatLockdown()
        ns.UpdateAppearance()
        UpdateGCDCooldown()

        -- Cursor follow
        ring:SetScript("OnUpdate", function()
            local x, y = GetScaledCursorPosition()
            local db2 = CursorRingDB or ns.defaults
            local ox = db2.offsetX or 0
            local oy = db2.offsetY or 0

            ring:ClearAllPoints()
            ring:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x + ox, y + oy)

            local nowInCombat = InCombatLockdown()
            if nowInCombat ~= lastInCombat then
                lastInCombat = nowInCombat
                ns.UpdateAppearance()
            end
        end)

        -- One-time / optional help message
        local shouldShowHelp = false
        if not db.helpMessageShownOnce then
            shouldShowHelp = true
            db.helpMessageShownOnce = true
        else
            shouldShowHelp = (db.showHelpOnLogin == true)
        end

        C_Timer.After(3, function()
            if shouldShowHelp then
                Say("Type /cr or open Esc -> Options -> AddOns -> Cursor Ring.")
            end
        end)

    elseif event == "PLAYER_ENTERING_WORLD" then
        UpdateGCDStyle()
        UpdateGCDCooldown()

    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        ns.UpdateAppearance()

    elseif event == "SPELL_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_COOLDOWN" then
        UpdateGCDCooldown()

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" and spellID then
        if not (CursorRingCharDB and CursorRingCharDB.gcdEnabled) then
            gcd:Hide()
            ns.UpdateAppearance()
            return
        end

        -- Check the cooldown of the spell we just cast; only show swipe if it has a real cooldown.
        local start, duration, modRate = ReadSpellCooldown(spellID)
        if IsCooldownActive(start, duration) then
            gcd:Show()
            if modRate then
                gcd:SetCooldown(start, duration, modRate)
            else
                gcd:SetCooldown(start, duration)
            end
            ns.UpdateAppearance()
        else
            -- Fall back to the general GCD spell for safety.
            UpdateGCDCooldown()
        end
    end
end)

-----------------------------------------------------------------------
-- Public refresh
-----------------------------------------------------------------------
function ns.Refresh()
    ring:SetShown(CursorRingDB.visible)
    ns.UpdateAppearance()
    UpdateGCDCooldown()
    if not CursorRingDB.visible then
        gcd:Hide()
    end
end

-----------------------------------------------------------------------
-- Slash commands
-----------------------------------------------------------------------
do
    SLASH_CURSORRING1 = "/cr"
    SlashCmdList.CURSORRING = function(msg)
        local args = {}
        for token in string.gmatch(msg or "", "%S+") do
            table.insert(args, strlower(token))
        end
        local cmd = args[1]
        local arg1 = args[2]
        local arg2 = args[3]
        local db = CursorRingDB or ns.defaults

        if cmd == "show" then
            db.visible = true
            ns.Refresh()
            Say("Shown")

        elseif cmd == "hide" then
            db.visible = false
            ns.Refresh()
            Say("Hidden")

        elseif cmd == "toggle" then
            db.visible = not db.visible
            ns.Refresh()
            Say("Toggled to " .. (db.visible and "shown" or "hidden"))

        elseif cmd == "reset" then
            CursorRingDB = CopyTable(ns.defaults)
            ns.Refresh()
            Say("Reset to defaults")

        elseif cmd == "gcd" then
            CursorRingCharDB.gcdEnabled = not CursorRingCharDB.gcdEnabled
            if CursorRingCharDB.gcdEnabled then
                UpdateGCDStyle()
                UpdateGCDCooldown()
                Say("GCD swipe: enabled")
            else
                gcd:Hide()
                ns.UpdateAppearance()
                Say("GCD swipe: disabled")
            end

        elseif cmd == "gcdstyle" and arg1 then
            local v = strlower(arg1)
            if v == "blizzard" or v == "simple" then
                CursorRingCharDB.gcdStyle = v
                ns.Refresh()
                Say("GCD style set to " .. v)
            else
                Say("Usage: /cr gcdstyle blizzard|simple")
            end

        elseif cmd == "gcdtest" and ns.DEBUG_GCD then
            CursorRingCharDB.gcdEnabled = true
            UpdateGCDStyle()
            local now = GetTime()
            gcd:Show()
            gcd:SetCooldown(now, 1.5)
            Say("Test swipe 1.5s")
            DumpGCDState("GCDTEST")

        elseif cmd == "color" and arg1 then
            if arg1 == "rouge" then
                Say("It's spelled R-O-G-U-E, not rouge!")
                return
            end

            if arg1 == "gradient" then
                db.colorMode = "gradient"
                ns.Refresh()
                Say("Color mode set to gradient")
                return
            end

            if arg1 == "default" then
                db.colorMode = "class"
                ns.Refresh()
                Say("Color mode set to class color")
                return
            end

            if arg1 == "highvis" then
                db.colorMode = "highvis"
                ns.Refresh()
                Say("Color mode set to high-visibility")
                return
            end

            if arg1 == "custom" then
                db.colorMode = "custom"
                ns.Refresh()
                Say("Color mode set to custom")
                return
            end

            local classFile = ns.colorAlias[arg1] or arg1
            local color = C_ClassColor.GetClassColor(strupper(classFile or ""))
            if color then
                db.colorMode = classFile
                ns.Refresh()
                Say("Color set to " .. classFile)
            else
                Say("Unknown color: " .. arg1)
            end

        elseif cmd == "alpha" and arg1 and arg2 then
            local val = tonumber(arg2)
            if not val or val < 0 or val > 1 then
                Say("Alpha must be 0-1")
                return
            end
            if arg1 == "in" then
                db.inCombatAlpha = val
            elseif arg1 == "out" then
                db.outCombatAlpha = val
            else
                Say("Usage: /cr alpha in|out 0-1")
                return
            end
            ns.Refresh()
            Say("Alpha " .. arg1 .. " = " .. val)

        elseif cmd == "size" and arg1 then
            local v = tonumber(arg1)
            if not v then
                Say("Size must be a number")
                return
            end
            if v < 10 or v > 100 then
                Say("Size must be 10-100")
                return
            end
            db.ringRadius = math.floor(v)
            ns.Refresh()
            Say("Size set to " .. db.ringRadius)

        elseif cmd == "texture" and arg1 then
            db.textureKey = ns.NormalizeTextureKey(arg1)
            ns.Refresh()
            Say("Texture set to " .. db.textureKey)

        elseif cmd == "right-click" and arg1 then
            if arg1 == "enable" then
                db.hideOnRightClick = true
            elseif arg1 == "disable" then
                db.hideOnRightClick = false
            elseif arg1 == "toggle" then
                db.hideOnRightClick = not db.hideOnRightClick
            else
                Say("Usage: /cr right-click enable|disable|toggle")
                return
            end
            ns.Refresh()
            Say("Hide on right-click: " .. (db.hideOnRightClick and "enabled" or "disabled"))

        else
            Say("Commands:")
            Say("/cr show, /cr hide, /cr toggle, /cr reset")
            Say("/cr gcd               - toggle GCD swipe")
            Say("/cr gcdstyle <style>  - blizzard | simple")
            if ns.DEBUG_GCD then
                Say("/cr gcdtest          - test swipe for 1.5s")
            end
            Say("/cr color <default|highvis|custom|gradient|class/alias>")
            Say("/cr alpha in|out <n>  - 0..1")
            Say("/cr texture <name>")
            Say("/cr size <n>          - 10..100")
            Say("/cr right-click enable|disable|toggle")
        end
    end
end

-- Initial size
local initialRadius = (ns.defaults and ns.defaults.ringRadius) or 28
ring:SetSize(initialRadius * 2, initialRadius * 2)
