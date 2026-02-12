local ADDON_NAME = ...
local C_NamePlate = _G.C_NamePlate
local C_Timer = _G.C_Timer
local CreateFrame = _G.CreateFrame
local IsAddOnLoaded = _G.IsAddOnLoaded
local issecure = _G.issecure
local UIParent = _G.UIParent
local EnumerateFrames = _G.EnumerateFrames
local UnitGUID = _G.UnitGUID

local defaults = {
    enabled = true,
    useBlizzardTray = true,
    offsetX = 0,
    offsetY = 4,
    trayScale = 0.75,
    enemyDRMode = "nameplate",
    enemyTargetOffsetX = 0,
    enemyTargetOffsetY = 0,
    enemyFocusOffsetX = 0,
    enemyFocusOffsetY = 0,
    enemyTargetFocusTestMode = false,
    enemyTargetScale = 1.0,
    enemyFocusScale = 1.0,
    debug = false,
    experimentalTracking = false,
    friendlyTracking = true,
    friendlyOffsetX = 0,
    friendlyOffsetY = 0,
    friendlyPlayerSeparate = false,
    friendlyPlayerOffsetX = 0,
    friendlyPlayerOffsetY = 0,
    friendlyPlayerAnchor = "player",
    friendlyDirection = "left",
    playerDirection = "left",
    friendlyHidePlayerInGroup = true,
    friendlyNameFallback = true,
    friendlyTestMode = false,
    playerTestMode = false,
}

local db
local ticker
local testTray
local testTrays
local saveFrame
local RestoreAllTrays

local function RefreshDB()
    if type(_G.FreshDRsDB) == "table" then
        db = _G.FreshDRsDB
    end
end

local function SafeGetField(obj, key)
    if not obj then
        return nil
    end
    local ok, value = pcall(function()
        return obj[key]
    end)
    if ok then
        local okBool = pcall(function()
            return not not value
        end)
        if not okBool then
            return nil
        end
        return value
    end
    return nil
end

local function SafeUnitGUID(unit)
    if not unit or not UnitGUID then
        return nil
    end
    local ok, guid = pcall(UnitGUID, unit)
    if not ok then
        return nil
    end
    local okBool = pcall(function()
        return guid ~= nil
    end)
    if not okBool then
        return nil
    end
    return guid
end

local function SafeGetChildren(frame)
    if not (frame and frame.GetChildren) then
        return nil
    end
    local ok, children = pcall(function()
        return { frame:GetChildren() }
    end)
    if ok then
        return children
    end
    return nil
end

local function SafeIndex(tbl, key)
    if not tbl then
        return nil
    end
    local ok, value = pcall(function()
        return tbl[key]
    end)
    if ok then
        local okBool = pcall(function()
            return not not value
        end)
        if not okBool then
            return nil
        end
        return value
    end
    return nil
end

local function SafeType(value)
    local ok, t = pcall(type, value)
    if ok then
        return t
    end
    return nil
end

local function SafeIsObject(value)
    local t = SafeType(value)
    return t == "table" or t == "userdata"
end

local function SafeIsTrue(value)
    if type(value) == "boolean" then
        return value
    end
    return false
end

local function SafeIsForbidden(frame)
    if not frame or not frame.IsForbidden then
        return false
    end
    local ok, forbidden = pcall(frame.IsForbidden, frame)
    if ok and type(forbidden) == "boolean" then
        return forbidden
    end
    return false
end

local function SafeCopyArray(tbl)
    if type(tbl) ~= "table" then
        return nil
    end
    local ok, copied = pcall(function()
        local out = {}
        for i = 1, #tbl do
            out[i] = tbl[i]
        end
        return out
    end)
    if ok then
        return copied
    end
    return nil
end

local function IsPlatynatorLoaded()
    if type(IsAddOnLoaded) == "function" and IsAddOnLoaded("Platynator") then
        return true
    end
    return type(_G.Platynator) == "table"
end

local platynatorManager

local function FindPlatynatorManager()
    if not (IsPlatynatorLoaded() and EnumerateFrames) then
        return nil
    end
    local frame = EnumerateFrames()
    while frame do
        local displays = SafeGetField(frame, "nameplateDisplays")
        local unitMap = SafeGetField(frame, "unitToNameplate")
        if type(displays) == "table" and type(unitMap) == "table" then
            return frame
        end
        frame = EnumerateFrames(frame)
    end
end

local function GetPlatynatorNameplate(unit)
    if not IsPlatynatorLoaded() then
        return nil
    end
    if not platynatorManager then
        platynatorManager = FindPlatynatorManager()
    end
    if not platynatorManager then
        return nil
    end
    local unitMap = SafeGetField(platynatorManager, "unitToNameplate")
    if type(unitMap) ~= "table" then
        return nil
    end
    return SafeIndex(unitMap, unit)
end

local function GetPlatynatorDisplay(unit)
    if not IsPlatynatorLoaded() then
        return nil
    end
    if not platynatorManager then
        platynatorManager = FindPlatynatorManager()
    end
    if not platynatorManager then
        return nil
    end
    local displays = SafeGetField(platynatorManager, "nameplateDisplays")
    if type(displays) ~= "table" then
        return nil
    end
    return SafeIndex(displays, unit)
end

local function GetNameplateToken(plate)
    if not SafeIsObject(plate) then
        return nil
    end
    local token = SafeGetField(plate, "namePlateUnitToken")
    if SafeType(token) ~= "string" then
        token = SafeGetField(plate, "unitToken")
    end
    if SafeType(token) ~= "string" then
        local uf = SafeGetField(plate, "UnitFrame")
        if SafeIsObject(uf) then
            token = SafeGetField(uf, "unit")
        end
    end
    if SafeType(token) == "string" then
        return token
    end
    return nil
end

local function IsDisplayFrame(frame)
    return frame and SafeGetField(frame, "widgets") and SafeGetField(frame, "InitializeWidgets") and SafeGetField(frame, "SetUnit")
end

local function FindPlatynatorDisplay(nameplate)
    if IsDisplayFrame(nameplate) then
        return nameplate
    end
    for _, child in ipairs(SafeGetChildren(nameplate) or {}) do
        if IsDisplayFrame(child) then
            return child
        end
        for _, grand in ipairs(SafeGetChildren(child) or {}) do
            if IsDisplayFrame(grand) then
                return grand
            end
        end
    end
    local unitFrame = nameplate and SafeGetField(nameplate, "UnitFrame")
    if unitFrame then
        if IsDisplayFrame(unitFrame) then
            return unitFrame
        end
        for _, child in ipairs(SafeGetChildren(unitFrame) or {}) do
            if IsDisplayFrame(child) then
                return child
            end
        end
    end
end

local function FindHealthBar(display)
    local widgets = display and SafeGetField(display, "widgets")
    if SafeType(widgets) ~= "table" then
        return nil
    end
    for _, w in ipairs(widgets) do
        local kind = SafeGetField(w, "kind")
        if SafeType(kind) == "string" and kind == "bars" then
            local details = SafeGetField(w, "details")
            if SafeType(details) == "table" then
                local detailKind = SafeGetField(details, "kind")
                if SafeType(detailKind) == "string" and detailKind == "health" then
                    local statusBar = SafeGetField(w, "statusBar")
                    if SafeIsObject(statusBar) then
                        return statusBar
                    end
                end
            end
        end
    end
end

local function IsPlatynatorHealthBar(frame)
    local details = SafeGetField(frame, "details")
    if SafeType(details) ~= "table" then
        return false
    end
    local kind = SafeGetField(details, "kind")
    return SafeType(kind) == "string" and kind == "health"
end

local function FindHealthBarInTree(root)
    if not root then
        return nil
    end
    local seen = {}
    local stack = { root }
    while #stack > 0 do
        local frame = table.remove(stack)
        if frame and not seen[frame] then
            seen[frame] = true
            local details = SafeGetField(frame, "details")
            if SafeType(details) == "table" then
                local kind = SafeGetField(details, "kind")
                if SafeType(kind) == "string" and kind == "health" then
                    local statusBar = SafeGetField(frame, "statusBar")
                    if SafeIsObject(statusBar) then
                        return frame
                    end
                end
            end
            local children = SafeGetChildren(frame)
            if children then
                for _, child in ipairs(children) do
                    table.insert(stack, child)
                end
            end
        end
    end
end

local function InitDB()
    if type(_G.FreshDRsDB) ~= "table" and type(_G.NameplateDRsDB) == "table" then
        _G.FreshDRsDB = {}
        for k, v in pairs(_G.NameplateDRsDB) do
            _G.FreshDRsDB[k] = v
        end
    end

    FreshDRsDB = FreshDRsDB or {}
    for key, value in pairs(defaults) do
        if FreshDRsDB[key] == nil then
            FreshDRsDB[key] = value
        end
    end
    if FreshDRsDB.enemyDRMode == nil then
        FreshDRsDB.enemyDRMode = "nameplate"
    end
    if FreshDRsDB.enemyDRModePersist ~= nil then
        FreshDRsDB.enemyDRMode = FreshDRsDB.enemyDRModePersist
    end
    if FreshDRsDB.enemyTargetScale == nil then
        FreshDRsDB.enemyTargetScale = 1.0
    end
    if FreshDRsDB.enemyFocusScale == nil then
        FreshDRsDB.enemyFocusScale = 1.0
    end
    if FreshDRsDB.playerDirection == nil then
        FreshDRsDB.playerDirection = "left"
    end
    db = FreshDRsDB
end

local function SaveDB()
    if not db then
        return
    end
    FreshDRsDB = db
end

local function SetDBValue(key, value)
    if not db then
        InitDB()
    end
    if type(FreshDRsDB) ~= "table" then
        FreshDRsDB = {}
    end
    FreshDRsDB[key] = value
    if key == "enemyDRMode" then
        FreshDRsDB.enemyDRModePersist = value
    end
    db = FreshDRsDB
    SaveDB()
end

local function DebugPrint(...)
    if db and db.debug then
        print("Nameplate DRs:", ...)
    end
end

local function IsInArena()
    local _, instanceType = IsInInstance()
    return instanceType == "arena"
end

local function GetArenaTray(index)
    local frame = _G["CompactArenaFrameMember" .. index]
    if frame and frame.SpellDiminishStatusTray then
        return frame.SpellDiminishStatusTray
    end
    return nil
end

local function FindNameplateForArenaUnit(unit)
    if not (C_NamePlate and C_NamePlate.GetNamePlates) then
        return nil
    end
    local ok, plates = pcall(C_NamePlate.GetNamePlates)
    if not ok or type(plates) ~= "table" then
        return nil
    end
    for _, plate in ipairs(plates) do
        local token = GetNameplateToken(plate)
        if token then
            local okMatch, isMatch = pcall(UnitIsUnit, token, unit)
            local isTrue = false
            if okMatch then
                local okCmp, cmp = pcall(function()
                    return isMatch == true
                end)
                if okCmp and cmp then
                    isTrue = true
                end
            end
            if isTrue then
                return plate
            end
        end
    end
    return nil
end

local function GetArenaNameplate(index)
    if not C_NamePlate or not C_NamePlate.GetNamePlateForUnit then
        return nil
    end
    local unit = "arena" .. index
    local secure = (type(issecure) == "function") and issecure() or nil
    local plate = C_NamePlate.GetNamePlateForUnit(unit, secure)
    if SafeIsObject(plate) then
        return plate
    end
    plate = FindNameplateForArenaUnit(unit)
    if SafeIsObject(plate) then
        return plate
    end
    plate = GetPlatynatorNameplate(unit)
    if SafeIsObject(plate) then
        return plate
    end
    return nil
end

local function SaveOriginalTrayState(tray)
    if not tray or tray.NPDRS_Original then
        return
    end

    local original = {
        parent = tray:GetParent(),
        scale = tray:GetScale(),
        strata = tray:GetFrameStrata(),
        level = tray:GetFrameLevel(),
        points = {},
    }

    local numPoints = tray:GetNumPoints()
    for i = 1, numPoints do
        original.points[i] = { tray:GetPoint(i) }
    end

    tray.NPDRS_Original = original
end

local function RestoreOriginalTrayState(tray)
    if not tray or not tray.NPDRS_Original then
        return
    end

    local original = tray.NPDRS_Original
    tray:SetParent(original.parent)
    tray:SetScale(original.scale or 1)
    if original.strata then
        tray:SetFrameStrata(original.strata)
    end
    if original.level then
        tray:SetFrameLevel(original.level)
    end
    tray:ClearAllPoints()
    for _, point in ipairs(original.points) do
        tray:SetPoint(unpack(point))
    end
end

local function GetPlateAnchor(plate)
    if not plate then
        return nil
    end
    if IsPlatynatorLoaded() then
        local display = FindPlatynatorDisplay(plate)
        if SafeIsObject(display) then
            local bar = FindHealthBar(display) or FindHealthBarInTree(display)
            if SafeIsObject(bar) then
                return bar
            end
        end
        local fallback = FindHealthBarInTree(plate)
        if SafeIsObject(fallback) then
            return fallback
        end
    end
    local unitFrame = plate.UnitFrame
    if SafeIsObject(unitFrame) then
        local healthBar = SafeGetField(unitFrame, "healthBar")
        if SafeIsObject(healthBar) then
            return healthBar
        end
    end
    return unitFrame or plate
end

local function GetAnchorParent(anchor, plate, fallback)
    local parent = fallback
    if anchor and anchor.GetParent then
        parent = anchor:GetParent() or parent
    end
    if SafeIsForbidden(parent) then
        return plate or anchor
    end
    return parent or anchor
end

local function GetTrayItems(tray)
    local items = {}
    local order = tray and SafeGetField(tray, "trayItemOrder")
    local active = tray and SafeGetField(tray, "activeItemForCategory")
    local orderCopy = SafeCopyArray(order)
    if orderCopy and type(active) == "table" then
        for _, category in ipairs(orderCopy) do
            local item = SafeIndex(active, category)
            if item then
                items[#items + 1] = item
            end
        end
    end

    if #items == 0 and tray then
        local children = SafeGetChildren(tray)
        if children then
            for _, child in ipairs(children) do
                items[#items + 1] = child
            end
        end
    end

    return items
end

local function GetArenaAnchor(index)
    local unit = "arena" .. index
    local display = GetPlatynatorDisplay(unit)
    if SafeIsObject(display) then
        local bar = FindHealthBar(display) or FindHealthBarInTree(display)
        if SafeIsObject(bar) then
            local border = SafeGetField(bar, "border")
            if SafeIsObject(border) then
                return border, display, "platynator-bar"
            end
            return bar, display, "platynator-bar"
        end
        return display, display, "platynator-display"
    end

    local plate = GetArenaNameplate(index) or GetPlatynatorNameplate(unit)
    if SafeIsObject(plate) then
        local token = GetNameplateToken(plate)
        if token then
            local displayFromToken = GetPlatynatorDisplay(token)
            if SafeIsObject(displayFromToken) then
                local bar = FindHealthBar(displayFromToken) or FindHealthBarInTree(displayFromToken)
                if SafeIsObject(bar) then
                    local border = SafeGetField(bar, "border")
                    if SafeIsObject(border) then
                        return border, displayFromToken, "platynator-bar"
                    end
                    return bar, displayFromToken, "platynator-bar"
                end
                return displayFromToken, displayFromToken, "platynator-display"
            end
        end
        local anchor = GetPlateAnchor(plate)
        if SafeIsObject(anchor) then
            return anchor, plate, "plate"
        end
        return plate, plate, "plate"
    end

    return nil, nil, "none"
end

local function GetEnemyDRMode()
    local mode = db and db.enemyDRMode
    if mode then
        return mode
    end
    if db and db.useBlizzardTray == false then
        return "arena"
    end
    return "nameplate"
end

local function GetTargetFocusAnchorForArena(index)
    local unit = "arena" .. index
    local okTarget, isTarget = pcall(UnitIsUnit, unit, "target")
    if okTarget and isTarget then
        local frame = _G.TargetFrame
        if frame and frame:IsShown() then
            return frame, "target"
        end
    end
    local okFocus, isFocus = pcall(UnitIsUnit, unit, "focus")
    if okFocus and isFocus then
        local frame = _G.FocusFrame
        if frame and frame:IsShown() then
            return frame, "focus"
        end
    end
    return nil, "arena"
end

local function GetTestAnchor()
    if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then
        return nil, "none"
    end
    local secure = (type(issecure) == "function") and issecure() or nil
    local units = { "target", "mouseover", "focus" }
    for _, unit in ipairs(units) do
        local plate = C_NamePlate.GetNamePlateForUnit(unit, secure)
        if SafeIsObject(plate) then
            local token = GetNameplateToken(plate)
            if token then
                local display = GetPlatynatorDisplay(token)
                if SafeIsObject(display) then
                    local bar = FindHealthBar(display) or FindHealthBarInTree(display)
                    if SafeIsObject(bar) then
                        local border = SafeGetField(bar, "border")
                        if SafeIsObject(border) then
                            return border, "platynator"
                        end
                        return bar, "platynator"
                    end
                    return display, "platynator"
                end
            end
            local anchor = GetPlateAnchor(plate)
            if SafeIsObject(anchor) then
                local source = "plate"
                local bar = anchor
                if IsPlatynatorHealthBar(anchor) then
                    source = "platynator"
                    local border = SafeGetField(anchor, "border")
                    if SafeIsObject(border) then
                        bar = border
                    end
                end
                return bar, source
            end
        end
    end
    return nil, "none"
end

function _G.NameplateDRs_GetAnchorForUnit(unit)
    if not unit then
        return nil
    end
    local arenaIndex = unit:match("^arena(%d)$")
    if arenaIndex then
        local index = tonumber(arenaIndex)
        if index then
            local anchor = GetArenaAnchor(index)
            return anchor
        end
    end

    if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then
        return nil
    end
    local secure = (type(issecure) == "function") and issecure() or nil
    local plate = C_NamePlate.GetNamePlateForUnit(unit, secure)
    if not SafeIsObject(plate) then
        return nil
    end
    local token = GetNameplateToken(plate)
    if token then
        local display = GetPlatynatorDisplay(token)
        if SafeIsObject(display) then
            local bar = FindHealthBar(display) or FindHealthBarInTree(display)
            if SafeIsObject(bar) then
                local border = SafeGetField(bar, "border")
                if SafeIsObject(border) then
                    return border
                end
                return bar
            end
            return display
        end
    end
    local anchor = GetPlateAnchor(plate)
    if SafeIsObject(anchor) then
        return anchor
    end
    return plate
end

local function EnsureSolidBorder(item)
    if not item or item.NPDRS_Border then
        return
    end

    local r, g, b, a = 0, 1, 0, 1
    local border = CreateFrame("Frame", nil, item)
    border:SetAllPoints(item)
    if item.GetFrameLevel then
        border:SetFrameLevel(item:GetFrameLevel() + 2)
    end

    local thickness = 1
    local top = border:CreateTexture(nil, "OVERLAY")
    top:SetColorTexture(r, g, b, a)
    top:SetPoint("TOPLEFT", -1, 1)
    top:SetPoint("TOPRIGHT", 1, 1)
    top:SetHeight(thickness)

    local bottom = border:CreateTexture(nil, "OVERLAY")
    bottom:SetColorTexture(r, g, b, a)
    bottom:SetPoint("BOTTOMLEFT", -1, -1)
    bottom:SetPoint("BOTTOMRIGHT", 1, -1)
    bottom:SetHeight(thickness)

    local left = border:CreateTexture(nil, "OVERLAY")
    left:SetColorTexture(r, g, b, a)
    left:SetPoint("TOPLEFT", -1, 1)
    left:SetPoint("BOTTOMLEFT", -1, -1)
    left:SetWidth(thickness)

    local right = border:CreateTexture(nil, "OVERLAY")
    right:SetColorTexture(r, g, b, a)
    right:SetPoint("TOPRIGHT", 1, 1)
    right:SetPoint("BOTTOMRIGHT", 1, -1)
    right:SetWidth(thickness)

    item.NPDRS_Border = border
end

local function EnsureTestTrayFor(key)
    if not testTrays then
        testTrays = {}
    end
    if testTrays[key] then
        return testTrays[key]
    end

    local tray = CreateFrame("Frame", nil, UIParent)
    tray.items = {}
    tray.iconSize = 26
    tray.iconSpacing = 2

    local textures = {
        "Interface\\Icons\\Ability_Rogue_Sap",
        "Interface\\Icons\\Spell_Frost_Glacier",
        "Interface\\Icons\\Ability_Rogue_Garrote",
    }

    for i = 1, #textures do
        local item = CreateFrame("Frame", nil, tray)
        item:SetSize(tray.iconSize, tray.iconSize)
        item.icon = item:CreateTexture(nil, "ARTWORK")
        item.icon:SetAllPoints(item)
        item.icon:SetTexture(textures[i])
        EnsureSolidBorder(item)
        tray.items[i] = item
    end

    testTrays[key] = tray
    return tray
end

local function EnsureTestTray()
    if testTray then
        return testTray
    end
    testTray = EnsureTestTrayFor("nameplate")
    return testTray
end

local function HideTestTrayFor(key)
    if testTrays and testTrays[key] then
        testTrays[key]:Hide()
    end
end

local function HideAllTestTrays()
    if testTray then
        testTray:Hide()
    end
    if testTrays then
        for _, tray in pairs(testTrays) do
            tray:Hide()
        end
    end
end

local function LayoutTestTray(tray, anchor, offsetX, offsetY, scale, source)
    if not (tray and anchor) then
        return
    end
    tray:SetParent(UIParent)
    tray:ClearAllPoints()
    tray:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", offsetX or 0, offsetY or 0)
    tray:SetScale(scale or 1)
    tray:SetFrameStrata("HIGH")
    if anchor.GetFrameLevel then
        tray:SetFrameLevel(anchor:GetFrameLevel() + 10)
    end

    local count = #tray.items
    local width = (count * tray.iconSize) + math.max(0, (count - 1) * tray.iconSpacing)
    tray:SetSize(width, tray.iconSize)

    for i, item in ipairs(tray.items) do
        item:ClearAllPoints()
        if i == 1 then
            item:SetPoint("RIGHT", tray, "RIGHT", 0, 0)
        else
            item:SetPoint("RIGHT", tray.items[i - 1], "LEFT", -tray.iconSpacing, 0)
        end
        item:Show()
    end

    tray:Show()

    if db and db.debug then
        local tag = string.format("test src=%s offx=%s offy=%s", tostring(source), tostring(offsetX), tostring(offsetY))
        if tray.NPDRS_LastDebug ~= tag then
            tray.NPDRS_LastDebug = tag
            DebugPrint(tag)
        end
    end
end

local function UpdateTestTray()
    if not db or not db.testMode or IsInArena() then
        if testTray then
            testTray:Hide()
        end
        return
    end

    local anchor, source = GetTestAnchor()
    if not SafeIsObject(anchor) then
        if testTray then
            testTray:Hide()
        end
        return
    end

    local tray = EnsureTestTray()
    local offsetX = db.offsetX
    local offsetY = db.offsetY
    LayoutTestTray(tray, anchor, offsetX, offsetY, db.trayScale or 1, source)
end

local function UpdateTargetFocusTestTrays()
    if not db or not db.enemyTargetFocusTestMode or IsInArena() then
        HideTestTrayFor("target")
        HideTestTrayFor("focus")
        return
    end

    local targetFrame = _G.TargetFrame
    if targetFrame and targetFrame:IsShown() then
        local tray = EnsureTestTrayFor("target")
        LayoutTestTray(tray, targetFrame, db.enemyTargetOffsetX or 0, db.enemyTargetOffsetY or 0, db.enemyTargetScale or db.trayScale or 1, "target")
    else
        HideTestTrayFor("target")
    end

    local focusFrame = _G.FocusFrame
    if focusFrame and focusFrame:IsShown() then
        local tray = EnsureTestTrayFor("focus")
        LayoutTestTray(tray, focusFrame, db.enemyFocusOffsetX or 0, db.enemyFocusOffsetY or 0, db.enemyFocusScale or db.trayScale or 1, "focus")
    else
        HideTestTrayFor("focus")
    end
end

local function MoveArenaTrays()
    if not db or not db.enabled then
        return false
    end
    local mode = GetEnemyDRMode()
    if mode == "arena" then
        RestoreAllTrays()
        return true
    end

    if not IsInArena() then
        for i = 1, 3 do
            local tray = GetArenaTray(i)
            if tray then
                RestoreOriginalTrayState(tray)
            end
        end
        return true
    end

    for i = 1, 3 do
        local tray = GetArenaTray(i)
        local anchor, owner, source
        local offsetX = db.offsetX
        local offsetY = db.offsetY
        if mode == "nameplate" then
            anchor, owner, source = GetArenaAnchor(i)
        elseif mode == "targetfocus" then
            anchor, source = GetTargetFocusAnchorForArena(i)
            if source == "target" then
                offsetX = db.enemyTargetOffsetX or 0
                offsetY = db.enemyTargetOffsetY or 0
            elseif source == "focus" then
                offsetX = db.enemyFocusOffsetX or 0
                offsetY = db.enemyFocusOffsetY or 0
            end
        end
        if db.debug then
            DebugPrint("arena", i, "tray", tray and "yes" or "no", "anchor", SafeIsObject(anchor) and "yes" or "no", "src", source, "mode", mode)
        end

        if tray and SafeIsObject(anchor) then
            SaveOriginalTrayState(tray)
            local originalParent = tray.NPDRS_Original and tray.NPDRS_Original.parent or tray:GetParent()
            tray:SetParent(originalParent)
            tray:ClearAllPoints()
            tray:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", offsetX, offsetY)
            if mode == "targetfocus" then
                if source == "target" then
                    tray:SetScale(db.enemyTargetScale or db.trayScale or 1)
                elseif source == "focus" then
                    tray:SetScale(db.enemyFocusScale or db.trayScale or 1)
                else
                    tray:SetScale(db.trayScale or 1)
                end
            else
                tray:SetScale(db.trayScale or 1)
            end
            tray:SetFrameStrata("HIGH")
            if anchor.GetFrameLevel then
                tray:SetFrameLevel(anchor:GetFrameLevel() + 10)
            end

            local items = GetTrayItems(tray)
            for _, item in ipairs(items) do
                EnsureSolidBorder(item)
            end
        elseif tray then
            RestoreOriginalTrayState(tray)
        end
    end

    return true
end

RestoreAllTrays = function()
    for i = 1, 3 do
        local tray = GetArenaTray(i)
        if tray then
            RestoreOriginalTrayState(tray)
        end
    end
end

local configFrame
local optionSliderCounter = 0

local function ApplySettings()
    if not db then
        InitDB()
    end
    RefreshDB()
    SaveDB()
    local experimental = _G.NameplateDRs_Experimental
    if experimental and experimental.SetEnabled then
        experimental.SetEnabled(db.experimentalTracking and db.enabled)
    end
    local friendly = _G.NameplateDRs_Friendly
    if friendly and friendly.SetEnabled then
        friendly.SetEnabled(db.friendlyTracking and db.enabled)
    end
    if friendly and friendly.ApplySettings then
        friendly.ApplySettings()
    end
    if not db.enabled then
        RestoreAllTrays()
        HideAllTestTrays()
        SaveDB()
        return
    end
    local mode = GetEnemyDRMode()
    if mode == "arena" then
        RestoreAllTrays()
    else
        MoveArenaTrays()
    end
    if mode == "nameplate" and db.testMode and not IsInArena() then
        UpdateTestTray()
    else
        HideTestTrayFor("nameplate")
    end
    if mode == "targetfocus" and db.enemyTargetFocusTestMode and not IsInArena() then
        UpdateTargetFocusTestTrays()
    else
        HideTestTrayFor("target")
        HideTestTrayFor("focus")
    end
    SaveDB()
end

local function CreateCheckbox(parent, label, initial, onToggle)
    local checkbox = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    checkbox.Text:SetText(label)
    checkbox:SetChecked(initial)
    checkbox:SetScript("OnClick", function(self)
        onToggle(self:GetChecked())
    end)
    return checkbox
end

local function CreateSliderRow(parent, label, minValue, maxValue, step, initial, onChange, isFloat, rowWidth, sliderWidth)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(rowWidth or 440, 28)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    title:SetText(label)

    local slider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    slider:SetWidth(sliderWidth or 280)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    editBox:SetPoint("LEFT", slider, "RIGHT", 8, 0)
    editBox:SetSize(60, 18)
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(false)

    local function FormatValue(value)
        if isFloat then
            return string.format("%.2f", value)
        end
        return string.format("%d", value)
    end

    local function SetValue(value)
        if value == nil then
            value = minValue
        end
        slider:SetValue(value)
        editBox:SetText(FormatValue(value))
    end

    slider:SetScript("OnValueChanged", function(self, value)
        if isFloat then
            value = tonumber(string.format("%.2f", value)) or value
        else
            value = math.floor(value + 0.5)
        end
        editBox:SetText(FormatValue(value))
        onChange(value)
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        local value = tonumber(text)
        if not value then
            value = initial
        end
        if value < minValue then
            value = minValue
        elseif value > maxValue then
            value = maxValue
        end
        SetValue(value)
        onChange(value)
        self:ClearFocus()
    end)

    SetValue(initial)
    return frame
end

local function CreateOptionSliderRow(parent, label, options, initialValue, onChange)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(440, 44)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    title:SetText(label)

    optionSliderCounter = optionSliderCounter + 1
    local sliderName = "NameplateDRsOptionSlider" .. optionSliderCounter
    local slider = CreateFrame("Slider", sliderName, frame, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    slider:SetWidth(220)
    slider:SetMinMaxValues(1, #options)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)

    local low = _G[sliderName .. "Low"]
    if low then
        low:Hide()
    end
    local high = _G[sliderName .. "High"]
    if high then
        high:Hide()
    end
    local text = _G[sliderName .. "Text"]
    if text then
        text:Hide()
    end

    local valueText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueText:Hide()

    local valueToIndex = {}
    for i, opt in ipairs(options) do
        valueToIndex[opt.value] = i
    end

    local optionLabels = {}
    for i, opt in ipairs(options) do
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetText(opt.label)
        if #options == 1 then
            label:SetPoint("TOP", slider, "BOTTOM", 0, -2)
        elseif #options == 2 then
            if i == 1 then
                label:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
            else
                label:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
            end
        elseif #options == 3 then
            if i == 1 then
                label:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
            elseif i == 2 then
                label:SetPoint("TOP", slider, "BOTTOM", 0, -2)
            else
                label:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
            end
        else
            local width = slider:GetWidth()
            local x = ((i - 1) / (#options - 1)) * width
            label:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", x, -2)
        end
        optionLabels[i] = label
    end

    local function SetIndex(idx)
        local index = math.floor(idx + 0.5)
        if index < 1 then
            index = 1
        elseif index > #options then
            index = #options
        end
        slider:SetValue(index)
        for i, label in ipairs(optionLabels) do
            if i == index then
                label:SetTextColor(1, 0.82, 0, 1)
            else
                label:SetTextColor(0.7, 0.7, 0.7, 1)
            end
        end
        onChange(options[index].value)
    end

    slider:SetScript("OnValueChanged", function(self, value)
        SetIndex(value)
    end)

    SetIndex(valueToIndex[initialValue] or 1)
    return frame
end

local function CreateDropdownRow(parent, label, options, initial, onChange, rowWidth, dropdownWidth)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(rowWidth or 440, 30)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    title:SetText(label)

    local dropdown = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(dropdown, dropdownWidth or 200)
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.value = option.value
            info.func = function()
                UIDropDownMenu_SetSelectedValue(dropdown, option.value)
                onChange(option.value)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetSelectedValue(dropdown, initial)
    return frame
end

local function ShowConfig()
    if configFrame then
        configFrame:SetShown(not configFrame:IsShown())
        return
    end
    RefreshDB()

    configFrame = CreateFrame("Frame", "NameplateDRsConfig", UIParent, "BackdropTemplate")
    configFrame:SetSize(620, 520)
    configFrame:SetPoint("CENTER")
    configFrame:SetFrameStrata("DIALOG")
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    configFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })

    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 16, -16)
    title:SetText("Fresh DRs")

    local byline = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    byline:SetPoint("LEFT", title, "RIGHT", 8, 0)
    byline:SetText("by lesh")

    local close = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -4, -4)

    local donate1 = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    donate1:SetPoint("LEFT", byline, "RIGHT", 12, 0)
    donate1:SetText("Please donate for my ill friend <3")

    local donateBox = CreateFrame("EditBox", nil, configFrame, "InputBoxTemplate")
    donateBox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    donateBox:SetSize(configFrame:GetWidth() - 32, 20)
    donateBox:SetAutoFocus(false)
    donateBox:SetText("https://www.gofundme.com/f/help-michael-survive-myalgic-encephalomyelitis")
    donateBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    donateBox:SetScript("OnMouseUp", function(self)
        self:SetFocus()
        self:HighlightText()
    end)

    local tab1 = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    tab1:SetPoint("TOPLEFT", donateBox, "BOTTOMLEFT", 0, -10)
    tab1:SetSize(150, 22)
    tab1:SetText("Arena Enemy DRs")

    local tab2 = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    tab2:SetPoint("LEFT", tab1, "RIGHT", 6, 0)
    tab2:SetSize(230, 22)
    tab2:SetText("Friendly DRs |cffff0000(EXPERIMENTAL)|r")
 

    local enemyFrame = CreateFrame("Frame", nil, configFrame)
    enemyFrame:SetPoint("TOPLEFT", tab1, "BOTTOMLEFT", 0, -8)
    enemyFrame:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -16, 0)
    enemyFrame:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 16, 16)

    local friendlyFrame = CreateFrame("Frame", nil, configFrame)
    friendlyFrame:SetPoint("TOPLEFT", enemyFrame, "TOPLEFT", 0, 0)
    friendlyFrame:SetPoint("BOTTOMRIGHT", enemyFrame, "BOTTOMRIGHT", 0, 0)
    friendlyFrame:Hide()

    local function SelectTab(index)
        enemyFrame:SetShown(index == 1)
        friendlyFrame:SetShown(index == 2)
        tab1:SetEnabled(index ~= 1)
        tab2:SetEnabled(index ~= 2)
    end

    tab1:SetScript("OnClick", function()
        SelectTab(1)
    end)
    tab2:SetScript("OnClick", function()
        SelectTab(2)
    end)

    local function CreateSeparator(parent, anchor, offsetY)
        local sep = parent:CreateTexture(nil, "ARTWORK")
        sep:SetColorTexture(1, 1, 1, 0.08)
        sep:SetHeight(1)
        sep:SetPoint("LEFT", parent, "LEFT", 0, 0)
        sep:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
        sep:SetPoint("TOP", anchor, "BOTTOM", 0, offsetY or -12)
        return sep
    end

    local UpdateEnemyModeVisibility
    local enemyModeOptions = {
        { value = "arena", label = "Arena Frames" },
        { value = "nameplate", label = "Nameplates" },
        { value = "targetfocus", label = "Target/Focus" },
    }
    local enemyModeRow = CreateOptionSliderRow(enemyFrame, "Enemy DR Position", enemyModeOptions, GetEnemyDRMode(), function(v)
        SetDBValue("enemyDRMode", v)
        if UpdateEnemyModeVisibility then
            UpdateEnemyModeVisibility(v)
        end
        ApplySettings()
    end)
    local enemyModeHint = enemyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    enemyModeHint:SetPoint("TOPLEFT", enemyFrame, "TOPLEFT", 0, 0)
    enemyModeHint:SetWidth(420)
    enemyModeHint:SetJustifyH("LEFT")
    enemyModeHint:SetText("Click on the slider to choose your preferred DR display mode.")

    enemyModeRow:SetPoint("TOPLEFT", enemyModeHint, "BOTTOMLEFT", -2, -8)

    local checkboxTest = CreateCheckbox(enemyFrame, "Test mode (target something in open world)", db.testMode, function(checked)
        SetDBValue("testMode", checked)
        ApplySettings()
    end)
    checkboxTest:SetPoint("TOPLEFT", enemyModeRow, "BOTTOMLEFT", 0, -22)
    if checkboxTest.Text then
        checkboxTest.Text:SetWidth(420)
        checkboxTest.Text:SetWordWrap(true)
    end

    local checkboxTargetFocusTest = CreateCheckbox(enemyFrame, "Test mode (target/focus)", db.enemyTargetFocusTestMode, function(checked)
        SetDBValue("enemyTargetFocusTestMode", checked)
        ApplySettings()
    end)
    checkboxTargetFocusTest:SetPoint("TOPLEFT", enemyModeRow, "BOTTOMLEFT", 0, -22)
    if checkboxTargetFocusTest.Text then
        checkboxTargetFocusTest.Text:SetWidth(420)
        checkboxTargetFocusTest.Text:SetWordWrap(true)
    end

    local note = enemyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", checkboxTest, "BOTTOMLEFT", 2, -6)
    note:SetWidth(420)
    note:SetJustifyH("LEFT")
    note:SetText("Offsets apply to the active nameplate system (Platynator if loaded).")

    local row1 = CreateSliderRow(enemyFrame, "Nameplate DR Offset X", -50, 50, 1, db.offsetX, function(v)
        SetDBValue("offsetX", v)
        ApplySettings()
    end, false)
    row1:SetPoint("TOPLEFT", note, "BOTTOMLEFT", -2, -6)

    local row2 = CreateSliderRow(enemyFrame, "Nameplate DR Offset Y", -50, 50, 1, db.offsetY, function(v)
        SetDBValue("offsetY", v)
        ApplySettings()
    end, false)
    row2:SetPoint("TOPLEFT", row1, "BOTTOMLEFT", 0, -8)

    local row3 = CreateSliderRow(enemyFrame, "Nameplate DR Scale", 0.5, 1.5, 0.01, db.trayScale, function(v)
        SetDBValue("trayScale", v)
        ApplySettings()
    end, true)
    row3:SetPoint("TOPLEFT", row2, "BOTTOMLEFT", 0, -6)

    local row4 = CreateSliderRow(enemyFrame, "Target Frame DR Offset X", -300, 300, 1, db.enemyTargetOffsetX, function(v)
        SetDBValue("enemyTargetOffsetX", v)
        ApplySettings()
    end, false)
    row4:SetPoint("TOPLEFT", row3, "BOTTOMLEFT", 0, -10)

    local row5 = CreateSliderRow(enemyFrame, "Target Frame DR Offset Y", -300, 300, 1, db.enemyTargetOffsetY, function(v)
        SetDBValue("enemyTargetOffsetY", v)
        ApplySettings()
    end, false)
    row5:SetPoint("TOPLEFT", row4, "BOTTOMLEFT", 0, -8)

    local row5b = CreateSliderRow(enemyFrame, "Target Frame DR Scale", 0.5, 1.5, 0.01, db.enemyTargetScale, function(v)
        SetDBValue("enemyTargetScale", v)
        ApplySettings()
    end, true)
    row5b:SetPoint("TOPLEFT", row5, "BOTTOMLEFT", 0, -8)

    local row6 = CreateSliderRow(enemyFrame, "Focus Frame DR Offset X", -300, 300, 1, db.enemyFocusOffsetX, function(v)
        SetDBValue("enemyFocusOffsetX", v)
        ApplySettings()
    end, false)
    row6:SetPoint("TOPLEFT", row5b, "BOTTOMLEFT", 0, -8)

    local row7 = CreateSliderRow(enemyFrame, "Focus Frame DR Offset Y", -300, 300, 1, db.enemyFocusOffsetY, function(v)
        SetDBValue("enemyFocusOffsetY", v)
        ApplySettings()
    end, false)
    row7:SetPoint("TOPLEFT", row6, "BOTTOMLEFT", 0, -8)

    local row7b = CreateSliderRow(enemyFrame, "Focus Frame DR Scale", 0.5, 1.5, 0.01, db.enemyFocusScale, function(v)
        SetDBValue("enemyFocusScale", v)
        ApplySettings()
    end, true)
    row7b:SetPoint("TOPLEFT", row7, "BOTTOMLEFT", 0, -8)

    local sep1 = CreateSeparator(enemyFrame, row7b, -12)
    sep1:Hide()

    -- moved experimental to Friendly tab

    UpdateEnemyModeVisibility = function(mode)
        local isNameplate = mode == "nameplate"
        local isTargetFocus = mode == "targetfocus"

        checkboxTest:SetShown(isNameplate)
        checkboxTargetFocusTest:SetShown(isTargetFocus)
        note:SetShown(isNameplate)
        row1:SetShown(isNameplate)
        row2:SetShown(isNameplate)
        row3:SetShown(isNameplate)

        row4:SetShown(isTargetFocus)
        row5:SetShown(isTargetFocus)
        row6:SetShown(isTargetFocus)
        row7:SetShown(isTargetFocus)
        row5b:SetShown(isTargetFocus)
        row7b:SetShown(isTargetFocus)

        if isTargetFocus then
            row4:ClearAllPoints()
            row4:SetPoint("TOPLEFT", checkboxTargetFocusTest, "BOTTOMLEFT", 0, -6)
            row5:ClearAllPoints()
            row5:SetPoint("TOPLEFT", row4, "BOTTOMLEFT", 0, -8)
            row6:ClearAllPoints()
            row5b:ClearAllPoints()
            row5b:SetPoint("TOPLEFT", row5, "BOTTOMLEFT", 0, -8)
            row6:SetPoint("TOPLEFT", row5b, "BOTTOMLEFT", 0, -8)
            row7:ClearAllPoints()
            row7:SetPoint("TOPLEFT", row6, "BOTTOMLEFT", 0, -8)
            row7b:ClearAllPoints()
            row7b:SetPoint("TOPLEFT", row7, "BOTTOMLEFT", 0, -8)
        else
            row4:ClearAllPoints()
            row4:SetPoint("TOPLEFT", row3, "BOTTOMLEFT", 0, -10)
            row5:ClearAllPoints()
            row5:SetPoint("TOPLEFT", row4, "BOTTOMLEFT", 0, -8)
            row5b:ClearAllPoints()
            row5b:SetPoint("TOPLEFT", row5, "BOTTOMLEFT", 0, -8)
            row6:ClearAllPoints()
            row6:SetPoint("TOPLEFT", row5b, "BOTTOMLEFT", 0, -8)
            row7:ClearAllPoints()
            row7:SetPoint("TOPLEFT", row6, "BOTTOMLEFT", 0, -8)
            row7b:ClearAllPoints()
            row7b:SetPoint("TOPLEFT", row7, "BOTTOMLEFT", 0, -8)
        end

        sep1:ClearAllPoints()
        if isTargetFocus then
            sep1:SetPoint("LEFT", enemyFrame, "LEFT", 0, 0)
            sep1:SetPoint("RIGHT", enemyFrame, "RIGHT", 0, 0)
            sep1:SetPoint("TOP", row7b, "BOTTOM", 0, -12)
        elseif isNameplate then
            sep1:SetPoint("LEFT", enemyFrame, "LEFT", 0, 0)
            sep1:SetPoint("RIGHT", enemyFrame, "RIGHT", 0, 0)
            sep1:SetPoint("TOP", row3, "BOTTOM", 0, -12)
        else
            sep1:SetPoint("LEFT", enemyFrame, "LEFT", 0, 0)
            sep1:SetPoint("RIGHT", enemyFrame, "RIGHT", 0, 0)
            sep1:SetPoint("TOP", enemyModeRow, "BOTTOM", 0, -18)
        end
    end

    UpdateEnemyModeVisibility(GetEnemyDRMode())

    local friendlyNote = friendlyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    friendlyNote:SetPoint("TOPLEFT", friendlyFrame, "TOPLEFT", 0, -2)
    friendlyNote:SetWidth(540)
    friendlyNote:SetHeight(16)
    friendlyNote:SetJustifyH("LEFT")
    friendlyNote:SetTextColor(1, 0, 0)
    friendlyNote:SetText("Important: Currently these ONLY work for CC debuffs with IDs.")

    local columnWidth = 260
    local sliderWidth = 160

    local friendlyLeft = CreateFrame("Frame", nil, friendlyFrame)
    friendlyLeft:SetPoint("TOPLEFT", friendlyNote, "BOTTOMLEFT", 0, -10)
    friendlyLeft:SetSize(columnWidth, 400)

    local friendlyRight = CreateFrame("Frame", nil, friendlyFrame)
    friendlyRight:SetPoint("TOPRIGHT", friendlyLeft, "TOPRIGHT", (columnWidth + 20), 0)
    friendlyRight:SetSize(columnWidth, 400)

    local sepV = friendlyFrame:CreateTexture(nil, "ARTWORK")
    sepV:SetColorTexture(1, 1, 1, 0.08)
    sepV:SetWidth(1)
    sepV:SetPoint("TOP", friendlyLeft, "TOPRIGHT", 10, 0)
    sepV:SetPoint("BOTTOM", friendlyLeft, "BOTTOMRIGHT", 10, 0)

    local midTitle = friendlyLeft:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    midTitle:SetPoint("TOPLEFT", friendlyLeft, "TOPLEFT", 0, 0)
    midTitle:SetText("Raid/Party DRs")

    local checkboxFriendly = CreateCheckbox(friendlyLeft, "Show DRs on raid frames", db.friendlyTracking, function(checked)
        SetDBValue("friendlyTracking", checked)
        ApplySettings()
    end)
    checkboxFriendly:SetPoint("TOPLEFT", midTitle, "BOTTOMLEFT", -2, -6)
    if checkboxFriendly.Text then
        checkboxFriendly.Text:SetWidth(columnWidth - 10)
        checkboxFriendly.Text:SetWordWrap(true)
    end

    local checkboxHidePlayer = CreateCheckbox(friendlyLeft, "Hide player DRs in party/raid frame", db.friendlyHidePlayerInGroup, function(checked)
        SetDBValue("friendlyHidePlayerInGroup", checked)
        ApplySettings()
    end)
    checkboxHidePlayer:SetPoint("TOPLEFT", checkboxFriendly, "BOTTOMLEFT", 14, -4)
    if checkboxHidePlayer.Text then
        checkboxHidePlayer.Text:SetWidth(columnWidth - 24)
        checkboxHidePlayer.Text:SetWordWrap(true)
    end

    local checkboxFriendlyTest = CreateCheckbox(friendlyLeft, "Test mode", db.friendlyTestMode, function(checked)
        SetDBValue("friendlyTestMode", checked)
        ApplySettings()
    end)
    checkboxFriendlyTest:SetPoint("TOPLEFT", checkboxHidePlayer, "BOTTOMLEFT", -14, -6)

    local checkboxNameFallback = CreateCheckbox(friendlyLeft, "Use name fallback for DR categories", db.friendlyNameFallback, function(checked)
        SetDBValue("friendlyNameFallback", checked)
        ApplySettings()
    end)
    checkboxNameFallback:SetPoint("TOPLEFT", checkboxFriendlyTest, "BOTTOMLEFT", 0, -4)
    if checkboxNameFallback.Text then
        checkboxNameFallback.Text:SetWidth(columnWidth - 10)
        checkboxNameFallback.Text:SetWordWrap(true)
    end

    local directionOptions = {
        { value = "left", label = "Left" },
        { value = "right", label = "Right" },
        { value = "up", label = "Up" },
        { value = "down", label = "Down" },
    }
    local directionRow = CreateDropdownRow(friendlyLeft, "DR Icon Direction", directionOptions, db.friendlyDirection, function(v)
        SetDBValue("friendlyDirection", v)
        ApplySettings()
    end, columnWidth, 150)
    directionRow:SetPoint("TOPLEFT", checkboxNameFallback, "BOTTOMLEFT", -2, -10)

    local row4 = CreateSliderRow(friendlyLeft, "Friendly DR Offset X", -50, 50, 1, db.friendlyOffsetX, function(v)
        SetDBValue("friendlyOffsetX", v)
        ApplySettings()
    end, false, columnWidth, sliderWidth)
    row4:SetPoint("TOPLEFT", directionRow, "BOTTOMLEFT", 0, -21)

    local row5 = CreateSliderRow(friendlyLeft, "Friendly DR Offset Y", -50, 50, 1, db.friendlyOffsetY, function(v)
        SetDBValue("friendlyOffsetY", v)
        ApplySettings()
    end, false, columnWidth, sliderWidth)
    row5:SetPoint("TOPLEFT", row4, "BOTTOMLEFT", 0, -8)

    local sepFriendly = CreateSeparator(friendlyLeft, row5, -20)

    local expTitle = friendlyLeft:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    expTitle:SetPoint("TOPLEFT", sepFriendly, "BOTTOMLEFT", 0, -8)
    expTitle:SetText("Open World Nameplate DRs")

    local checkboxExperimental = CreateCheckbox(friendlyLeft, "Enable (experimental)", db.experimentalTracking, function(checked)
        SetDBValue("experimentalTracking", checked)
        ApplySettings()
    end)
    checkboxExperimental:SetPoint("TOPLEFT", expTitle, "BOTTOMLEFT", -2, -6)
    if checkboxExperimental.Text then
        checkboxExperimental.Text:SetTextColor(1, 0.3, 0.3)
    end

    local rightTitle = friendlyRight:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rightTitle:SetPoint("TOPLEFT", friendlyRight, "TOPLEFT", 0, 0)
    rightTitle:SetText("Player DRs")

    local checkboxPlayerSeparate = CreateCheckbox(friendlyRight, "Show player DRs", db.friendlyPlayerSeparate, function(checked)
        SetDBValue("friendlyPlayerSeparate", checked)
        if checked then
            SetDBValue("friendlyHidePlayerInGroup", true)
            if checkboxHidePlayer then
                checkboxHidePlayer:SetChecked(true)
            end
        end
        ApplySettings()
    end)
    checkboxPlayerSeparate:SetPoint("TOPLEFT", rightTitle, "BOTTOMLEFT", -2, -6)
    if checkboxPlayerSeparate.Text then
        checkboxPlayerSeparate.Text:SetWidth(columnWidth - 10)
        checkboxPlayerSeparate.Text:SetWordWrap(true)
    end

    local checkboxPlayerTest = CreateCheckbox(friendlyRight, "Test mode", db.playerTestMode, function(checked)
        SetDBValue("playerTestMode", checked)
        ApplySettings()
    end)
    checkboxPlayerTest:SetPoint("TOPLEFT", checkboxPlayerSeparate, "BOTTOMLEFT", 0, -4)

    local anchorOptions = {
        { value = "player", label = "Player frame" },
        { value = "center", label = "Screen center" },
    }
    local playerAnchorRow = CreateDropdownRow(friendlyRight, "Player DR Anchor", anchorOptions, db.friendlyPlayerAnchor, function(v)
        SetDBValue("friendlyPlayerAnchor", v)
        ApplySettings()
    end, columnWidth, 150)
    playerAnchorRow:SetPoint("TOPLEFT", checkboxPlayerTest, "BOTTOMLEFT", -2, -18)

    local playerDirectionOptions = {
        { value = "left", label = "Left" },
        { value = "right", label = "Right" },
        { value = "up", label = "Up" },
        { value = "down", label = "Down" },
    }
    local playerDirectionRow = CreateDropdownRow(friendlyRight, "Player DR Direction", playerDirectionOptions, db.playerDirection or "left", function(v)
        SetDBValue("playerDirection", v)
        ApplySettings()
    end, columnWidth, 150)
    playerDirectionRow:SetPoint("TOPLEFT", playerAnchorRow, "BOTTOMLEFT", 0, -19)

    local row6 = CreateSliderRow(friendlyRight, "Player DR Offset X", -2000, 2000, 1, db.friendlyPlayerOffsetX, function(v)
        SetDBValue("friendlyPlayerOffsetX", v)
        ApplySettings()
    end, false, columnWidth, sliderWidth)
    row6:SetPoint("TOPLEFT", playerDirectionRow, "BOTTOMLEFT", 0, -21)

    local row7 = CreateSliderRow(friendlyRight, "Player DR Offset Y", -2000, 2000, 1, db.friendlyPlayerOffsetY, function(v)
        SetDBValue("friendlyPlayerOffsetY", v)
        ApplySettings()
    end, false, columnWidth, sliderWidth)
    row7:SetPoint("TOPLEFT", row6, "BOTTOMLEFT", 0, -21)

    SelectTab(1)
end

local function Start()
    if not db then
        InitDB()
    end
    RefreshDB()
    if not saveFrame then
        saveFrame = CreateFrame("Frame")
        saveFrame:RegisterEvent("PLAYER_LOGOUT")
        saveFrame:SetScript("OnEvent", function()
            SaveDB()
        end)
    end

    if not ticker then
        ticker = C_Timer.NewTicker(0.2, function()
            if db and not IsInArena() then
                local mode = GetEnemyDRMode()
                if mode == "nameplate" and db.testMode then
                    UpdateTestTray()
                    return
                end
                if mode == "targetfocus" and db.enemyTargetFocusTestMode then
                    UpdateTargetFocusTestTrays()
                    return
                end
            end
            MoveArenaTrays()
        end)
    end

    C_Timer.After(0, function()
        if db and not IsInArena() then
            local mode = GetEnemyDRMode()
            if mode == "nameplate" and db.testMode then
                UpdateTestTray()
                return
            end
            if mode == "targetfocus" and db.enemyTargetFocusTestMode then
                UpdateTargetFocusTestTrays()
                return
            end
        end
        MoveArenaTrays()
    end)
end

InitDB()
Start()

SLASH_NAMEPLATEDRS1 = "/ndr"
SLASH_NAMEPLATEDRS2 = "/fdr"
SlashCmdList.NAMEPLATEDRS = function(msg)
    ShowConfig()
end
