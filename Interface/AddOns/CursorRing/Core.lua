-- Cursor Ring - Core (finalized with emphasis semantics)
local _, ns = ...
local UIParent, CreateFrame = UIParent, CreateFrame
local GetScaledCursorPosition, UnitClass = GetScaledCursorPosition, UnitClass
local CopyTable, strlower, strupper, tostring, type = CopyTable, strlower, strupper, tostring, type
local InCombatLockdown = InCombatLockdown
local C_ClassColor = C_ClassColor
local lastInCombat = nil

-- Debug flag (set false to hide /cr gcdtest and logs)
ns.DEBUG_GCD = false

-- Normalize a texture name to a known key
function ns.NormalizeTextureKey(name)
    if not name then return "Default" end
    name = strlower(name)
    if name == "default" then return "Default" end
    if name == "thin" then return "Thin" end
    if name == "thick" then return "Thick" end
    if name == "solid" then return "Solid" end
    return name:gsub("^%l", string.upper)
end
ns.NormalizeTextureKey = ns.NormalizeTextureKey

-- Texture files
ns.textures = {
    Default = "Interface\\AddOns\\CursorRing\\media\\Default.png",
    Thin    = "Interface\\AddOns\\CursorRing\\media\\Thin.png",
    Thick   = "Interface\\AddOns\\CursorRing\\media\\Thick.png",
    Solid   = "Interface\\AddOns\\CursorRing\\media\\Solid.png",
}

-- Defaults (account-wide)
ns.defaults = {
    ringRadius       = 28,
    textureKey       = "Default",
    inCombatAlpha    = 0.70,
    outCombatAlpha   = 0.30,
    useClassColor    = true,
    useHighVis       = false,
    colorMode        = "class",
    customColor      = { r = 1, g = 1, b = 1 },
    visible          = true,
    hideOnRightClick = true,
}

-- Per-character defaults
ns.charDefaults = {
    gcdEnabled        = true,          -- GCD swipe ON by default
    gcdStyle          = "simple",      -- "simple" or "blizzard"
    gcdDimMultiplier  = 0.35,          -- emphasis E: 0=no dim, 1=max dim (runtime uses 1 - E)
}

-- Ring frame
local ring = CreateFrame("Frame", nil, UIParent)
ring:SetFrameStrata("TOOLTIP")
ring:SetSize(ns.defaults.ringRadius * 2, ns.defaults.ringRadius * 2)

-- Ring texture
local tex = ring:CreateTexture(nil, "ARTWORK")
tex:SetAllPoints()

-- GCD Cooldown overlay (self-animating, no polling)
local gcd = CreateFrame("Cooldown", nil, ring, "CooldownFrameTemplate")
gcd:SetAllPoints()
gcd:EnableMouse(false)
gcd:SetDrawSwipe(true)
gcd:SetDrawEdge(true)                 -- spark edge (toggled by style)
gcd:SetHideCountdownNumbers(true)
if gcd.SetUseCircularEdge then gcd:SetUseCircularEdge(true) end
gcd:SetFrameStrata("TOOLTIP")                 -- match parent strata
gcd:SetFrameLevel(ring:GetFrameLevel() + 3)   -- ensure above ring texture

-- Helpers defined BEFORE any hooks use them
local function GetRingBaseAlpha()
    local db = CursorRingDB
    if not db then return 1 end
    return (InCombatLockdown() and db.inCombatAlpha) or db.outCombatAlpha or 1
end

-- Saved value is "emphasis" E in [0..1]; actual dim multiplier M = 1 - E
local function GetGCDDimMultiplier()
    local e = CursorRingCharDB and CursorRingCharDB.gcdDimMultiplier or 0.35
    if e < 0 then e = 0 elseif e > 1 then e = 1 end
    return 1 - e
end

-- Dim/restore the base ring while GCD swipe is visible
gcd:HookScript("OnShow", function()
    tex:SetAlpha(GetRingBaseAlpha() * GetGCDDimMultiplier())
end)
gcd:HookScript("OnHide", function()
    tex:SetAlpha(GetRingBaseAlpha())
end)

-- Right-click temporary hide
WorldFrame:HookScript("OnMouseDown", function(_, button)
    if button == "RightButton" and CursorRingDB.hideOnRightClick then
        tex:Hide()
        if CursorRingCharDB.gcdEnabled then gcd:Hide() end
    end
end)
WorldFrame:HookScript("OnMouseUp", function(_, button)
    if button == "RightButton" and CursorRingDB.hideOnRightClick then
        tex:Show()
        if CursorRingCharDB.gcdEnabled then gcd:Show() end
    end
end)

-- Color aliases (slash convenience)
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

-- Helper: compute ring color (r,g,b)
local function GetColor()
    local db = CursorRingDB
    if db.useHighVis then
        return 0, 1, 0
    end
    if db.useClassColor then
        local _, classFile = UnitClass("player")
        local color = C_ClassColor.GetClassColor(classFile)
        if color then
            return color.r, color.g, color.b
        end
        return 1, 1, 1
    end
    if db.colorMode == "highvis" then
        return 0, 1, 0
    end
    if db.colorMode == "custom" then
        local c = db.customColor
        return c.r, c.g, c.b
    end
    local classFile = ns.colorAlias[db.colorMode] or db.colorMode
    local color = C_ClassColor.GetClassColor(strupper(classFile))
    if color then
        return color.r, color.g, color.b
    end
    return 1, 1, 1
end

-- Keep GCD overlay styled to match current ring and chosen style
local function UpdateGCDStyle()
    if not CursorRingCharDB.gcdEnabled then gcd:Hide() return end

    -- match ring color; no overrides
    local r, g, b = GetColor()
    local style = (CursorRingCharDB.gcdStyle or "simple")
    local swipeA = (CursorRingDB and CursorRingDB.inCombatAlpha) or 0.70

    if style == "simple" then
        -- Simple: ring mask, no spark
        local texPath = ns.textures[CursorRingDB.textureKey] or ns.textures.Default
        if gcd.SetSwipeTexture then gcd:SetSwipeTexture(texPath) end
        gcd:SetDrawEdge(false)  -- no spark
        if gcd.SetDrawBling then gcd:SetDrawBling(false) end
        if gcd.SetUseCircularEdge then gcd:SetUseCircularEdge(true) end
        gcd:SetSwipeColor(r, g, b, swipeA)
        gcd:SetReverse(false)

    elseif style == "blizzard" then
        local texPath = ns.textures[CursorRingDB.textureKey] or ns.textures.Default
        if gcd.SetSwipeTexture then gcd:SetSwipeTexture(texPath) end
        gcd:SetDrawEdge(true)   -- spark
        if gcd.SetDrawBling then gcd:SetDrawBling(false) end
        if gcd.SetUseCircularEdge then gcd:SetUseCircularEdge(true) end
        gcd:SetSwipeColor(r, g, b, swipeA)
        gcd:SetReverse(false)

    else
        -- Blizzard: default circular swipe texture + spark
        if gcd.SetSwipeTexture then gcd:SetSwipeTexture("Interface\Cooldown\star4") end
        gcd:SetDrawEdge(true)   -- spark
        if gcd.SetDrawBling then gcd:SetDrawBling(false) end
        if gcd.SetUseCircularEdge then gcd:SetUseCircularEdge(true) end
        gcd:SetSwipeColor(r, g, b, swipeA)
        gcd:SetReverse(false)
    end

    gcd:Show()
end

-- Appearance update
local function UpdateAppearance()
    local db      = CursorRingDB
    local texture = ns.textures[db.textureKey] or ns.textures.Default
    local radius  = db.ringRadius
    local baseAlpha = GetRingBaseAlpha()

    tex:SetTexture(texture)
    tex:SetVertexColor(GetColor())

    -- If GCD is currently visible, apply dim factor; otherwise use base alpha
    if gcd:IsShown() then
        tex:SetAlpha(baseAlpha * GetGCDDimMultiplier())
    else
        tex:SetAlpha(baseAlpha)
    end

    ring:SetSize(radius * 2, radius * 2)

    UpdateGCDStyle()
end
ns.UpdateAppearance = UpdateAppearance

-- Robust cooldown reader: handles tuple or table returns
local function ReadSpellCooldown(spellID)
    if not C_Spell or not C_Spell.GetSpellCooldown then return end
    local a, b, c, d = C_Spell.GetSpellCooldown(spellID)
    if type(a) == "table" then
        local t = a
        local start = t.startTime or t.start or 0
        local duration = t.duration or 0
        local enable = (t.isEnabled == true or t.enabled == 1) and 1 or 0
        local modRate = t.modRate
        return start, duration, enable, modRate
    else
        return a, b, c, d
    end
end

-- Helper to start the swipe if args look like a GCD
local function TryStartGCD(start, duration, modRate)
    if not CursorRingCharDB.gcdEnabled then return end
    if not start or not duration or duration <= 0 then return end
    -- Most GCDs live up to ~2.5s with single-button-assist; treat <= 3s as GCD
    if duration <= 3.0 then
        gcd:Show()
        if modRate then
            gcd:SetCooldown(start, duration, modRate)
        else
            gcd:SetCooldown(start, duration)
        end
    end
end

-- Start or clear the GCD cooldown swipe
local GCD_SPELL_ID = 61304  -- standard GCD token
local function UpdateGCDCooldown()
    if not CursorRingCharDB.gcdEnabled then return end
    local start, duration, enable, modRate = ReadSpellCooldown(GCD_SPELL_ID)
    if (enable == 1 or enable == true) and duration and duration > 0 then
        TryStartGCD(start, duration, modRate)
        tex:SetAlpha(GetRingBaseAlpha() * GetGCDDimMultiplier())
    else
        gcd:Hide()
        tex:SetAlpha(GetRingBaseAlpha())
    end
end

-- Debug helpers (only if enabled)
local function Print(msg) if ns.DEBUG_GCD then DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00CursorRing:|r "..tostring(msg)) end end
local function DumpGCDState(header)
    if not ns.DEBUG_GCD then return end
    Print("=== "..tostring(header).." ===")
    local ringStrata = ring:GetFrameStrata() or "nil"
    local ringLevel  = ring:GetFrameLevel() or 0
    local gcdStrata  = gcd:GetFrameStrata() or "nil"
    local gcdLevel   = gcd:GetFrameLevel() or 0
    local layer, sublayer = tex:GetDrawLayer()
    local texPath = tex:GetTexture()
    local shown   = ring:IsShown()
    local gcdShown= gcd:IsShown()
    local r,g,b,a = 0,0,0,0
    if gcd.GetSwipeColor then r,g,b,a = gcd:GetSwipeColor() end

    Print(("Ring strata=%s level=%d size=%dx%d shown=%s"):format(ringStrata, ringLevel, ring:GetWidth(), ring:GetHeight(), tostring(shown)))
    Print(("GCD  strata=%s level=%d shown=%s drawSwipe=%s drawEdge=%s"):format(gcdStrata, gcdLevel, tostring(gcdShown), tostring(gcd:GetDrawSwipe()), tostring(gcd:GetDrawEdge())))
    Print(("Tex drawLayer=%s sub=%s path=%s"):format(tostring(layer), tostring(sublayer), tostring(texPath)))
    Print(("SwipeColor=%s,%s,%s,%s"):format(tostring(r), tostring(g), tostring(b), tostring(a)))

    local s,d,e,m = ReadSpellCooldown(61304)
    Print(("GCD cd -> start=%s dur=%s enable=%s modRate=%s"):format(tostring(s), tostring(d), tostring(e), tostring(m)))
end

-- Events
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("SPELL_UPDATE_COOLDOWN")
f:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
f:SetScript("OnEvent", function(_, event, unit, lineID, spellID)
    if event == "PLAYER_LOGIN" then
        CursorRingDB      = CursorRingDB      or CopyTable(ns.defaults)
        CursorRingCharDB  = CursorRingCharDB  or CopyTable(ns.charDefaults)

        ring:SetShown(CursorRingDB.visible)
        lastInCombat = InCombatLockdown()
        UpdateAppearance()
        UpdateGCDCooldown()

        ring:SetScript("OnUpdate", function()
            local x, y = GetScaledCursorPosition()
            ring:ClearAllPoints()
            ring:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)

            local nowInCombat = InCombatLockdown()
            if nowInCombat ~= lastInCombat then
                lastInCombat = nowInCombat
                UpdateAppearance()
            end
        end)

        C_Timer.After(3, function()
            if not ns._greeted then
                ns._greeted = true
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00CursorRing:|r type |cffffd100/cr|r or open |cff00ff00Esc -> Options -> AddOns -> Cursor Ring|r.")
            end
        end)

    elseif event == "PLAYER_ENTERING_WORLD" then
        UpdateGCDStyle()
        UpdateGCDCooldown()

    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        UpdateAppearance()

    elseif event == "SPELL_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_COOLDOWN" then
        UpdateGCDCooldown()

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" and spellID then
        local start, duration, enable, modRate = ReadSpellCooldown(spellID)
        if enable == 1 or enable == true then
            TryStartGCD(start, duration, modRate)
            tex:SetAlpha(GetRingBaseAlpha() * GetGCDDimMultiplier())
        end
    end
end)

-- Public refresh used by options/slash
function ns.Refresh()
    ring:SetShown(CursorRingDB.visible)
    UpdateAppearance()
    UpdateGCDCooldown()
    if not CursorRingDB.visible then gcd:Hide() end
end

-- Slash commands
SLASH_CURSORRING1 = "/cr"
SlashCmdList["CURSORRING"] = function(msg)
    local args = {}
    for token in string.gmatch(msg or "", "%S+") do
        table.insert(args, strlower(token))
    end
    local cmd, arg1, arg2 = args[1], args[2], args[3]
    local db = CursorRingDB

    local function PrintCmd(s) DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00CursorRing:|r "..s) end

    if cmd == "show" then
        db.visible = true
        ns.Refresh()
        PrintCmd("Shown")

    elseif cmd == "hide" then
        db.visible = false
        ns.Refresh()
        PrintCmd("Hidden")

    elseif cmd == "toggle" then
        db.visible = not db.visible
        ns.Refresh()
        PrintCmd("Toggled to "..(db.visible and "shown" or "hidden"))

    elseif cmd == "reset" then
        CursorRingDB = CopyTable(ns.defaults)
        ns.Refresh()
        PrintCmd("Reset to defaults")

    elseif cmd == "gcd" then
        CursorRingCharDB.gcdEnabled = not CursorRingCharDB.gcdEnabled
        if CursorRingCharDB.gcdEnabled then
            UpdateGCDStyle()
            UpdateGCDCooldown()
            PrintCmd("GCD swipe: |cff00ff00enabled|r")
        else
            gcd:Hide()
            tex:SetAlpha(GetRingBaseAlpha())
            PrintCmd("GCD swipe: |cffff0000disabled|r")
        end

    elseif cmd == "gcdstyle" and arg1 then
        local v = string.lower(arg1)
        if v == "square" or v == "simple" or v == "blizzard" then
            CursorRingCharDB.gcdStyle = v
            ns.Refresh()
            -- If a GCD is in progress, reapply to update visuals immediately
            local s,d,e,m = ReadSpellCooldown(61304)
            if (e == 1 or e == true) and d and d > 0 then
                TryStartGCD(s, d, m)
            end
            PrintCmd("GCD style set to "..v)
        else
            PrintCmd("Usage: /cr gcdstyle square | blizzard | simple")
        end

    elseif cmd == "gcdtest" and ns.DEBUG_GCD then
        CursorRingCharDB.gcdEnabled = true
        UpdateGCDStyle()
        local now = GetTime()
        gcd:Show()
        gcd:SetCooldown(now, 1.5)
        PrintCmd("Invoked test swipe for 1.5s. Dumping state...")
        DumpGCDState("GCDTEST SNAPSHOT")
        C_Timer.After(0.10, function() DumpGCDState("GCDTEST +0.10s") end)
        C_Timer.After(0.50, function() DumpGCDState("GCDTEST +0.50s") end)

    elseif cmd == "color" and arg1 then
        if arg1 == "rouge" then
            PrintCmd("|cffFF0000It's spelled |cffffd100R-O-G-U-E|r|cffFF0000, not rouge!|r")
            return
        end
        local classFile = ns.colorAlias[arg1] or arg1
        local color = C_ClassColor.GetClassColor(strupper(classFile))
        if color or arg1 == "default" or arg1 == "highvis" then
            db.useClassColor = (arg1 == "default")
            db.useHighVis    = (arg1 == "highvis")
            if arg1 ~= "default" and arg1 ~= "highvis" then
                db.colorMode = classFile
            end
            ns.Refresh()
            PrintCmd("Color set to "..arg1)
        elseif arg1 == "custom" then
            db.useClassColor = false
            db.useHighVis    = false
            db.colorMode     = "custom"
            ns.Refresh()
            PrintCmd("Color set to custom")
        else
            PrintCmd("Unknown color: "..arg1)
        end

    elseif cmd == "alpha" and arg1 and arg2 then
        local val = tonumber(arg2)
        if not val or val < 0 or val > 1 then PrintCmd("Alpha must be 0–1"); return end
        if arg1 == "in" then
            db.inCombatAlpha = val
        elseif arg1 == "out" then
            db.outCombatAlpha = val
        else
            PrintCmd("Usage: /cr alpha in|out 0-1"); return
        end
        ns.Refresh()
        PrintCmd("Alpha "..arg1.." = "..val)

    elseif cmd == "size" and arg1 then
        local v = tonumber(arg1)
        if not v then PrintCmd("Size must be a number"); return end
        if v < 10 or v > 100 then PrintCmd("Size must be 10–100"); return end
        db.ringRadius = math.floor(v)
        ns.Refresh()
        PrintCmd("Size set to "..db.ringRadius)

    elseif cmd == "texture" and arg1 then
        db.textureKey = ns.NormalizeTextureKey(arg1)
        ns.Refresh()
        PrintCmd("Texture set to "..db.textureKey)

    elseif cmd == "right-click" and arg1 then
        if arg1 == "enable" then
            db.hideOnRightClick = true
        elseif arg1 == "disable" then
            db.hideOnRightClick = false
        elseif arg1 == "toggle" then
            db.hideOnRightClick = not db.hideOnRightClick
        else
            PrintCmd("Usage: /cr right-click enable|disable|toggle"); return
        end
        ns.Refresh()
        PrintCmd("Hide on right-click: "..(db.hideOnRightClick and "enabled" or "disabled"))

    else
        PrintCmd("|cffaaaaaaCommands:|r")
        PrintCmd("|cff00ff00/cr show|r, |cff00ff00/cr hide|r, |cff00ff00/cr toggle|r, |cff00ff00/cr reset|r")
        PrintCmd("|cff00ff00/cr gcd|r – toggle GCD swipe")
        PrintCmd("|cff00ff00/cr gcdstyle blizzard|simple|r – pick the GCD visual")
        if ns.DEBUG_GCD then
            PrintCmd("|cff00ff00/cr gcdtest|r – force a 1.5s test swipe and print debug info")
        end
        PrintCmd("|cff00ff00/cr color <name>|r – default | highvis | custom | class or alias")
        PrintCmd("|cff00ff00/cr alpha in|out 0-1|r, |cff00ff00/cr texture <name>|r, |cff00ff00/cr size 10-100|r")
        PrintCmd("|cff00ff00/cr right-click enable | disable | toggle|r")
    end
end
