local addonName, BBM = ...

local CITY_MAPS = {
    -- Alliance capitals
    [84]   = true, -- Stormwind City
    [1012] = true, -- Stormwind City
    [1264] = true, -- Stormwind City
    [87]   = true, -- Ironforge
    [1265] = true, -- Ironforge
    [89]   = true, -- Darnassus
    [1324] = true, -- Darnassus
    [103]  = true, -- The Exodar
    [775]  = true, -- The Exodar
    [1326] = true, -- The Exodar
    [1331] = true, -- The Exodar

    -- Horde capitals
    [85]   = true, -- Orgrimmar
    [86]   = true, -- Orgrimmar
    [1534] = true, -- Orgrimmar
    [88]   = true, -- Thunder Bluff
    [1323] = true, -- Thunder Bluff
    [90]   = true, -- Undercity
    [998]  = true, -- Undercity
    [1266] = true, -- Undercity
    [110]  = true, -- Silvermoon City
    [1269] = true, -- Silvermoon City
    [2393] = true, -- Silvermoon City
    [2443] = true, -- Silvermoon City

    -- Neutral hubs
    [111]  = true, -- Shattrath City (Outland)
    [594]  = true, -- Shattrath City (Draenor)
    [125]  = true, -- Dalaran (Northrend)
    [126]  = true, -- Dalaran (Northrend)
    [501]  = true, -- Dalaran (Northrend)
    [502]  = true, -- Dalaran (Northrend)
    [626]  = true, -- Dalaran (Broken Isles)
    [627]  = true, -- Dalaran (Broken Isles)
    [628]  = true, -- Dalaran (Broken Isles)
    [629]  = true, -- Dalaran (Broken Isles)
    [2305] = true, -- Dalaran (Azeroth)
    [2306] = true, -- Dalaran (Azeroth)
    [2307] = true, -- Dalaran (Azeroth)
    [391]  = true, -- Shrine of Two Moons
    [392]  = true, -- Shrine of Two Moons
    [393]  = true, -- Shrine of Seven Stars
    [394]  = true, -- Shrine of Seven Stars
    [622]  = true, -- Stormshield
    [624]  = true, -- Warspear
    [1161] = true, -- Boralus
    [1163] = true, -- Dazar'alor
    [1164] = true, -- Dazar'alor
    [1165] = true, -- Dazar'alor
    [1670] = true, -- Oribos
    [1671] = true, -- Oribos
    [1672] = true, -- Oribos
    [1673] = true, -- Oribos
    [2112] = true, -- Valdrakken
    [2134] = true, -- Valdrakken
    [2135] = true, -- Valdrakken
    [2239] = true, -- Bel'ameth
    [2268] = true, -- Bel'ameth
    [2339] = true, -- Dornogal
}

local function InCity(mapID)
    if mapID == nil then return false end
    return CITY_MAPS[mapID]
end

local cachedInArena, cachedInBG, cachedInPvE, cachedInCity, cachedInWorld = false, false, false, false, false

local function RefreshZoneState()
    local inInstance, instanceType = IsInInstance()

    cachedInArena = instanceType == "arena"
    cachedInBG    = instanceType == "pvp"
    cachedInPvE   = inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "scenario")

    if inInstance then
        cachedInCity = false
    elseif C_PvP.GetZonePVPInfo() == "sanctuary" then
        cachedInCity = true
    else
        cachedInCity = InCity(C_Map.GetBestMapForUnit("player")) == true
    end

    cachedInWorld = not cachedInArena and not cachedInBG and not cachedInCity
end

function BBM.isInArena() return cachedInArena end
function BBM.isInBG()    return cachedInBG end
function BBM.isInPvP()   return cachedInArena or cachedInBG end
function BBM.isInCity()  return cachedInCity end
function BBM.isInPvE()   return cachedInPvE end
function BBM.isInWorld() return cachedInWorld end

RefreshZoneState()
BBM.On("PLAYER_ENTERING_WORLD", RefreshZoneState)
BBM.On("ZONE_CHANGED_NEW_AREA", RefreshZoneState)

function BBM.isFriend(unit)
    local reaction = UnitReaction(unit, "player")
    return reaction and reaction >= 5
end

function BBM.isEnemy(unit)
    local reaction = UnitReaction(unit, "player")
    return reaction and reaction <= 4
end

function BBM.GetAnchorFrame(nameplate)
    if nameplate.unitFrame and nameplate.unitFrame.healthBar then
        return nameplate.unitFrame.healthBar
    end
    local uf = nameplate.UnitFrame
    if uf and uf.healthBar then return uf.healthBar end
    return nameplate
end

local disallowedUnitBases = {
    arena = true, arenapet = true,
    party = true, partypet = true,
    raid  = true, raidpet  = true,
    boss  = true,
}

local function IsDisallowedUnit(unit)
    if #unit > 6 and strsub(unit, -6) == "target" then return true end
    local base = strmatch(unit, "^(%a+)%d+$")
    return base ~= nil and disallowedUnitBases[base] == true
end

local unitIsDisallowed = setmetatable({}, { __index = function(cache, unit)
    local disallowed = IsDisallowedUnit(unit)
    cache[unit] = disallowed
    return disallowed
end })

local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit

function BBM.GetNamePlate(unit, includeForbidden)
    if type(unit) ~= "string" or unitIsDisallowed[unit] then return nil end
    return GetNamePlateForUnit(unit, includeForbidden)
end

function BBM.IsForbiddenNameplate(nameplate)
    return not nameplate or nameplate:IsForbidden()
end

local colorMixins = setmetatable({}, { __mode = "k" })

function BBM.GetColorMixin(color)
    if not color then return nil end
    local r = color.r or color[1]
    local g = color.g or color[2]
    local b = color.b or color[3]
    if not (r and g and b) then return nil end

    local mixin = colorMixins[color]
    if mixin then
        mixin:SetRGB(r, g, b)
    else
        mixin = CreateColor(r, g, b)
        colorMixins[color] = mixin
    end
    return mixin
end

function BBM.WrapTextInColor(text, color)
    if not text then return text end
    local mixin = BBM.GetColorMixin(color)
    if not mixin then return text end
    return mixin:WrapTextInColorCode(text)
end

function BBM.StripColorCodes(text)
    if not text then return text end
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

function BBM.SetColoredText(fontString, text)
    fontString:SetText(text)
    if text and text:find("|c", 1, true) then
        fontString:SetVertexColor(1, 1, 1)
    end
end

function BBM.IsPetUnit(unit)
    if not unit then return false end
    return UnitIsUnit(unit, "pet") or UnitIsOtherPlayersPet(unit) or false
end

function BBM.GetHealthBar(nameplate)
    if nameplate.unitFrame and nameplate.unitFrame.healthBar then
        return nameplate.unitFrame.healthBar
    end
    local uf = nameplate.UnitFrame
    if not uf then return nil end
    return uf.healthBar or (uf.HealthBarsContainer and uf.HealthBarsContainer.healthBar)
end

function BBM.GetPlatynatorHealthBar(nameplate)
    if not Platynator then return nil end

    local container = nameplate.BetterBlizzMarkers
    local cached = container and container.platynatorHealthBar
    if cached then
        local display = cached:GetParent()
        if display and display:GetParent() == nameplate then return cached end
    end

    for _, child in ipairs({ nameplate:GetChildren() }) do
        if child.widgets then
            for _, w in ipairs(child.widgets) do
                if w.kind == "bars" and w.details and w.details.kind == "health" and w.SetColor then
                    if container then container.platynatorHealthBar = w end
                    return w
                end
            end
        end
    end
    return nil
end

function BBM.GetVisibleHealthBar(nameplate)
    local platynatorBar = BBM.GetPlatynatorHealthBar(nameplate)
    if platynatorBar then return platynatorBar.statusBar or platynatorBar end
    return BBM.GetHealthBar(nameplate)
end

function BBM.SetUnitNameOverride(nameplate, unitToken, text, refresh)
    if Platynator and Platynator.API and Platynator.API.SetUnitTextOverride then
        if unitToken then Platynator.API.SetUnitTextOverride(unitToken, text) end
        return
    end
    if not (Plater and nameplate and nameplate.unitFrame and nameplate.unitFrame.PlaterOnScreen) then return end
    if text and nameplate.CurrentUnitNameString then
        BBM.SetColoredText(nameplate.CurrentUnitNameString, text)
    end
    if refresh and Plater.UpdateUnitName then
        Plater.UpdateUnitName(nameplate)
    end
end

function BBM.CreateNameplateContainer(nameplate)
    if not nameplate.BetterBlizzMarkers then
        local container = CreateFrame("Frame", nil, nameplate)
        container:SetAllPoints(nameplate)
        nameplate.BetterBlizzMarkers = container
    end
    return nameplate.BetterBlizzMarkers
end

function BBM.IsNameplateAddonActive()
    for _, name in ipairs(BBM.NAMEPLATE_ADDONS) do
        if C_AddOns.IsAddOnLoaded(name) then
            if name == "ElvUI" then
                local private = _G.ElvUI and _G.ElvUI[1] and _G.ElvUI[1].private
                if private and private.nameplates and private.nameplates.enable then
                    return true
                end
            else
                return true
            end
        end
    end
    return false
end

function BBM.GetDefaultHealthbarHeight()
    local C = NamePlateConstants
    local S = Enum.NamePlateStyle
    local style = GetCVarNumberOrDefault(C.STYLE_CVAR)
    local scaleTable = style == S.Classic and C.NAME_PLATE_SCALES_CLASSIC_STYLE or C.NAME_PLATE_SCALES
    local scale = scaleTable[GetCVarNumberOrDefault(C.SIZE_CVAR)] or scaleTable[Enum.NamePlateSize.Medium]

    if style == S.Classic then
        return C.CLASSIC_HEALTH_BAR_HEIGHT * scale.vertical
    elseif style == S.Modern or style == S.Block or style == S.HealthFocus then
        return C.LARGE_HEALTH_BAR_HEIGHT * scale.vertical
    else
        return C.SMALL_HEALTH_BAR_HEIGHT * scale.vertical
    end
end

function BBM.ApplyMidnightMask(bar, targetTexture)
    if not bar or not targetTexture then return end

    local mask = bar.bbmMidnightMask
    if not mask then
        mask = bar:CreateMaskTexture()
        mask:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Assets\\Textures\\midnightNpMask")
        bar.bbmMidnightMask = mask
    end

    local height = BBM.GetDefaultHealthbarHeight()
    local bottom
    if height <= 23 then
        bottom = -0.5
    elseif height <= 32 then
        bottom = -1
    elseif height <= 40 then
        bottom = -1.5
    else
        bottom = -2
    end

    mask:ClearAllPoints()
    mask:SetPoint("TOPLEFT",     bar, "TOPLEFT",     -0.5, 1)
    mask:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT",  0.5, bottom)
    mask:Show()

    if not targetTexture.bbmMidnightMasked then
        targetTexture:AddMaskTexture(mask)
        targetTexture.bbmMidnightMasked = true
    end
end

local GetUnitTooltip = C_TooltipInfo and C_TooltipInfo.GetUnit or function() return nil end

function BBM.UnitIsProbablyUnit(unit1, unit2)
    if not UnitExists(unit1) or not UnitExists(unit2) then return end

    local name1, name2 = UnitName(unit1), UnitName(unit2)
    if issecretvalue(name1) or issecretvalue(name2) then return end

    return name1 == name2
end

function BBM.GetSpecID(unitToken)
    if not UnitIsPlayer(unitToken) then return nil end
    local guid = UnitGUID(unitToken)
    if issecretvalue(guid) then
        if BBM.isInArena() then
            for i = 1, 3 do
                if BBM.UnitIsProbablyUnit(unitToken, "arena"..i) then
                    return GetArenaOpponentSpec(i)
                end
            end
        end
        return nil
    end
    local tooltipData = GetUnitTooltip(unitToken)
    if not tooltipData or not tooltipData.lines then return nil end
    for _, line in ipairs(tooltipData.lines) do
        if line and line.type == Enum.TooltipDataLineType.None
            and line.leftText and line.leftText ~= "" then
            local specID = BBM.ALL_SPECS[line.leftText]
            if specID then return specID end
        end
    end
    return nil
end
