local addonName, BBM = ...

local addon = BBM.addon

local isInArena                = BBM.isInArena
local isFriend                 = BBM.isFriend
local isEnemy                  = BBM.isEnemy
local IsForbiddenNameplate     = BBM.IsForbiddenNameplate
local GetNamePlate             = BBM.GetNamePlate
local CreateNameplateContainer = BBM.CreateNameplateContainer
local UnitIsProbablyUnit       = BBM.UnitIsProbablyUnit
local SpecNames                = BBM.SpecNames
local ShortSpecNames           = BBM.ShortSpecNames
local GetSpecID                = BBM.GetSpecID
local GetAnchorFrame           = BBM.GetAnchorFrame
local anchorOpposite           = BBM.anchorOpposite
local SetColoredText           = BBM.SetColoredText

local TEST_SPEC_IDS = {}
for id in pairs(SpecNames) do TEST_SPEC_IDS[#TEST_SPEC_IDS + 1] = id end

local unitToArenaIndex = {}
local unitToTestSpecID = {}

local function ArenaTestMode()
    return BBM.IsTestMode("arenaNames")
end

local function getProfile()
    return addon.db.profile.arenaNames
end

local function FactionSetting(friend, friendlyVal, enemyVal)
    if friend then return friendlyVal end
    return enemyVal
end

local function ClassColorText(p, specID, text)
    if not (p.classColorArenaNames and specID and text) then return text end
    local _, _, classColor = BBM.GetSpecDisplay(specID)
    if not classColor then return text end
    return classColor:WrapTextInColorCode(text)
end

local function getSpecName(unitToken)
    local p = getProfile()
    local specID = GetSpecID(unitToken)
    if not specID then return nil end
    local name = (p.abbreviateSpec and ShortSpecNames or SpecNames)[specID]
    if not name then return nil end
    return ClassColorText(p, specID, name)
end

local function BuildReplaceText(unitToken, arenaIndex, friend)
    local p = getProfile()
    local showArenaID = FactionSetting(friend, p.friendlyShowArenaID, p.enemyShowArenaID)
    local showSpec    = FactionSetting(friend, p.friendlyShowSpec,    p.enemyShowSpec)
    local showName    = FactionSetting(friend, p.friendlyShowName,    p.enemyShowName)

    local parts = {}
    if showArenaID and arenaIndex then
        local specID = p.classColorArenaNames and GetSpecID(unitToken) or nil
        parts[#parts + 1] = ClassColorText(p, specID, tostring(arenaIndex))
    end
    if showSpec then
        local specName = getSpecName(unitToken)
        if specName then parts[#parts + 1] = specName end
    end
    if showName then
        local name = UnitName(unitToken)
        if name then parts[#parts + 1] = name end
    end
    return #parts > 0 and table.concat(parts, " ") or nil
end

local function FindArenaIndex(unitToken, friend)
    if friend then
        for i = 1, 4 do
            if UnitIsProbablyUnit(unitToken, "party" .. i) then return i end
        end
        if UnitIsProbablyUnit(unitToken, "player") then return 0 end
    else
        for i = 1, 5 do
            if UnitIsProbablyUnit(unitToken, "arena" .. i) then return i end
        end
    end
    return nil
end

local function EnsureArenaNameFrames(nameplate)
    CreateNameplateContainer(nameplate)
    local container = nameplate.BetterBlizzMarkers
    if container.ArenaNames then return end

    local an = {}

    local specNameFS = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    specNameFS:SetIgnoreParentAlpha(true)
    specNameFS:Hide()
    an.specName = specNameFS

    local arenaIDFS = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arenaIDFS:SetIgnoreParentAlpha(true)
    arenaIDFS:Hide()
    an.arenaID = arenaIDFS

    container.ArenaNames = an
end

local function UpdateCustomLayout(nameplate)
    local p = getProfile()
    local container = nameplate.BetterBlizzMarkers
    if not container or not container.ArenaNames then return end

    local an          = container.ArenaNames
    local anchorFrame = GetAnchorFrame(nameplate)

    local fontPath = (p.fontKey ~= "" and BBM.LSM and BBM.LSM:Fetch("font", p.fontKey)) or STANDARD_TEXT_FONT

    an.specName:SetFont(fontPath, p.specNameFontSize, "OUTLINE")
    an.specName:ClearAllPoints()
    an.specName:SetPoint(
        anchorOpposite[p.specNameAnchor],
        anchorFrame,
        p.specNameAnchor,
        p.specNameXPos,
        p.specNameYPos
    )

    local arenaAnchorTarget = p.arenaIDAnchorTo == "specName" and an.specName or anchorFrame
    an.arenaID:SetFont(fontPath, p.arenaIDFontSize, "OUTLINE")
    an.arenaID:ClearAllPoints()
    an.arenaID:SetPoint(
        anchorOpposite[p.arenaIDAnchor],
        arenaAnchorTarget,
        p.arenaIDAnchor,
        p.arenaIDXPos,
        p.arenaIDYPos
    )
end

local function HideArenaDisplay(nameplate)
    if not nameplate.BetterBlizzMarkers then return end
    local an = nameplate.BetterBlizzMarkers.ArenaNames
    if not an then return end
    if an.specName then an.specName:Hide() end
    if an.arenaID  then an.arenaID:Hide()  end
end

local SetExternalNameOverride = BBM.SetUnitNameOverride

local function ClearExternalNameOverride(nameplate, unitToken, refresh)
    SetExternalNameOverride(nameplate, unitToken, nil, refresh)
end

local function UpdateArenaDisplay(nameplate, unitToken, arenaIndex)
    local p = getProfile()
    local friend = isFriend(unitToken)
    local enemy  = isEnemy(unitToken)
    local shouldShow = p.enabled
        and not (friend and not p.showOnFriendly)
        and not (enemy  and not p.showOnEnemy)

    if p.namesMode == "adapt" then
        HideArenaDisplay(nameplate)
        SetExternalNameOverride(nameplate, unitToken, shouldShow and BuildReplaceText(unitToken, arenaIndex, friend) or nil, true)
        return
    end

    if p.namesMode == "replace" then
        SetExternalNameOverride(nameplate, unitToken, shouldShow and "" or nil, true)
    end

    if not shouldShow then
        HideArenaDisplay(nameplate)
        return
    end

    EnsureArenaNameFrames(nameplate)
    UpdateCustomLayout(nameplate)

    local container   = nameplate.BetterBlizzMarkers
    local an          = container.ArenaNames
    local showArenaID = FactionSetting(friend, p.friendlyShowArenaID, p.enemyShowArenaID)
    local showSpec    = FactionSetting(friend, p.friendlyShowSpec,    p.enemyShowSpec)
    local showName    = FactionSetting(friend, p.friendlyShowName,    p.enemyShowName)

    if showSpec or showName then
        local parts = {}
        if showSpec then
            local specName = getSpecName(unitToken)
            if specName then parts[#parts + 1] = specName end
        end
        if showName then
            local name = UnitName(unitToken)
            if name then parts[#parts + 1] = name end
        end
        if #parts > 0 then
            an.specName:SetText(table.concat(parts, " "))
            an.specName:Show()
        else
            an.specName:Hide()
        end
    else
        an.specName:Hide()
    end

    if showArenaID and arenaIndex then
        local specID = p.classColorArenaNames and GetSpecID(unitToken) or nil
        an.arenaID:SetText(ClassColorText(p, specID, tostring(arenaIndex)))
        an.arenaID:Show()
    else
        an.arenaID:Hide()
    end
end

local function GetTestSpecID(unitToken)
    local cached = unitToTestSpecID[unitToken]
    if cached then return cached end

    local specID = GetSpecID(unitToken)

    if not specID and UnitIsPlayer(unitToken) then
        local class = UnitClassBase(unitToken)
        if class then
            for _, c in ipairs(BBM.GetClassSpecTree()) do
                if c.file == class and #c.specs > 0 then
                    specID = c.specs[math.random(#c.specs)].id
                    break
                end
            end
        end
    end

    if not specID then
        specID = TEST_SPEC_IDS[math.random(#TEST_SPEC_IDS)]
    end

    unitToTestSpecID[unitToken] = specID
    return specID
end

local function TestSpecNameAndID(p, unitToken)
    local specID = GetTestSpecID(unitToken)
    return (p.abbreviateSpec and ShortSpecNames or SpecNames)[specID], specID
end

local function SetReplacementNameText(nameplate, unitToken, text)
    local uf = nameplate.UnitFrame or nameplate.unitFrame
    if text and uf and uf.name and not uf:IsForbidden() then
        SetColoredText(uf.name, text)
    end
    SetExternalNameOverride(nameplate, unitToken, text)
end

local function UpdateOverlayPreview(nameplate, unitToken, arenaIndex, showArenaID, showSpec, showName, p)
    EnsureArenaNameFrames(nameplate)
    UpdateCustomLayout(nameplate)
    local an = nameplate.BetterBlizzMarkers.ArenaNames

    local specName, specID
    if showSpec or showArenaID then
        specName, specID = TestSpecNameAndID(p, unitToken)
    end

    if showSpec or showName then
        local parts = {}
        if showSpec and specName then
            parts[#parts + 1] = ClassColorText(p, specID, specName)
        end
        if showName then
            local name = UnitName(unitToken)
            if name then parts[#parts + 1] = name end
        end
        if #parts > 0 then
            an.specName:SetText(table.concat(parts, " "))
            an.specName:Show()
        else
            an.specName:Hide()
        end
    else
        an.specName:Hide()
    end

    if showArenaID and arenaIndex then
        an.arenaID:SetText(ClassColorText(p, specID, tostring(arenaIndex)))
        an.arenaID:Show()
    else
        an.arenaID:Hide()
    end
end

local function ShowHideArenaNameTestMode(nameplate, unitToken)
    local p = getProfile()
    if not p.enabled then
        HideArenaDisplay(nameplate); ClearExternalNameOverride(nameplate, unitToken)
        return
    end

    local friend = isFriend(unitToken)
    local enemy  = isEnemy(unitToken)
    if friend and not p.showOnFriendly then
        HideArenaDisplay(nameplate); ClearExternalNameOverride(nameplate, unitToken)
        return
    end
    if enemy  and not p.showOnEnemy    then
        HideArenaDisplay(nameplate); ClearExternalNameOverride(nameplate, unitToken)
        return
    end

    local arenaIndex = unitToArenaIndex[unitToken]
    if not arenaIndex then
        arenaIndex = math.random(friend and 4 or 5)
        unitToArenaIndex[unitToken] = arenaIndex
    end

    local showArenaID = FactionSetting(friend, p.friendlyShowArenaID, p.enemyShowArenaID)
    local showSpec    = FactionSetting(friend, p.friendlyShowSpec,    p.enemyShowSpec)
    local showName    = FactionSetting(friend, p.friendlyShowName,    p.enemyShowName)

    if p.namesMode == "add" or p.namesMode == "replace" then
        UpdateOverlayPreview(nameplate, unitToken, arenaIndex, showArenaID, showSpec, showName, p)
        if p.namesMode == "replace" then
            SetReplacementNameText(nameplate, unitToken, "")
        else
            ClearExternalNameOverride(nameplate, unitToken)
        end

    elseif p.namesMode == "adapt" then
        HideArenaDisplay(nameplate)

        local specName, specID
        if showSpec or showArenaID then
            specName, specID = TestSpecNameAndID(p, unitToken)
        end

        local parts = {}
        if showArenaID and arenaIndex then
            parts[#parts + 1] = ClassColorText(p, specID, tostring(arenaIndex))
        end
        if showSpec and specName then
            parts[#parts + 1] = ClassColorText(p, specID, specName)
        end
        if showName then
            local name = UnitName(unitToken)
            if name then parts[#parts + 1] = name end
        end
        local text = #parts > 0 and table.concat(parts, " ") or nil

        SetReplacementNameText(nameplate, unitToken, text)
    end
end

local function onNamePlateAdded(_, unitToken)
    local nameplate = GetNamePlate(unitToken)
    if IsForbiddenNameplate(nameplate) then return end

    if ArenaTestMode() then
        ShowHideArenaNameTestMode(nameplate, unitToken)
        return
    end

    if not isInArena() then return end
    if not UnitIsPlayer(unitToken) then return end

    local p = getProfile()
    if not p.enabled then return end

    local friend = isFriend(unitToken)
    local enemy  = isEnemy(unitToken)
    if friend and not p.showOnFriendly then return end
    if enemy  and not p.showOnEnemy    then return end

    local arenaIndex = FindArenaIndex(unitToken, friend)
    if arenaIndex then
        unitToArenaIndex[unitToken] = arenaIndex
        UpdateArenaDisplay(nameplate, unitToken, arenaIndex)
    end
end

local function onNamePlateRemoved(_, unitToken)
    local nameplate = GetNamePlate(unitToken)
    unitToArenaIndex[unitToken] = nil
    unitToTestSpecID[unitToken] = nil
    ClearExternalNameOverride(nameplate, unitToken)
    if IsForbiddenNameplate(nameplate) then return end
    HideArenaDisplay(nameplate)
end

local function onUnitFaction(_, unitToken)
    if not GetNamePlate(unitToken) then return end
    C_Timer.After(0.1, function()
        onNamePlateAdded(_, unitToken)
    end)
end

local function onPlayerEnteringWorld()
    if isInArena() or ArenaTestMode() then
        BBM.On("NAME_PLATE_UNIT_ADDED",   onNamePlateAdded)
        BBM.On("NAME_PLATE_UNIT_REMOVED", onNamePlateRemoved)
        BBM.On("UNIT_FACTION",            onUnitFaction)
    else
        BBM.Off("NAME_PLATE_UNIT_ADDED",   onNamePlateAdded)
        BBM.Off("NAME_PLATE_UNIT_REMOVED", onNamePlateRemoved)
        BBM.Off("UNIT_FACTION",            onUnitFaction)
        for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
            HideArenaDisplay(nameplate)
            local unit = nameplate.namePlateUnitToken
                or (nameplate.UnitFrame and nameplate.UnitFrame.unit)
            ClearExternalNameOverride(nameplate, unit)
        end
        wipe(unitToArenaIndex)
        wipe(unitToTestSpecID)
    end
end

local function GetReplaceText(unit)
    if not isInArena() then return nil end

    local p = getProfile()
    if not p.enabled then return nil end
    if p.namesMode ~= "adapt" and p.namesMode ~= "replace" then return nil end

    local friend = isFriend(unit)
    local enemy  = isEnemy(unit)
    if friend and not p.showOnFriendly then return nil end
    if enemy  and not p.showOnEnemy    then return nil end

    if p.namesMode == "replace" then
        return ""
    end

    if not UnitIsPlayer(unit) then return nil end

    local arenaIndex = unitToArenaIndex[unit]
    if not arenaIndex then
        arenaIndex = FindArenaIndex(unit, friend)
        if arenaIndex then
            unitToArenaIndex[unit] = arenaIndex
        end
    end

    return BuildReplaceText(unit, arenaIndex, friend)
end

local function OwnsNameText(unit)
    if not unit then return false end
    if not (isInArena() or ArenaTestMode()) then return false end

    local p = getProfile()
    if not p.enabled then return false end
    if p.namesMode ~= "adapt" then return false end
    if not UnitIsPlayer(unit) then return false end

    local friend = isFriend(unit)
    local enemy  = isEnemy(unit)
    if friend and not p.showOnFriendly then return false end
    if enemy  and not p.showOnEnemy    then return false end

    return FactionSetting(friend, p.friendlyShowArenaID, p.enemyShowArenaID)
        or FactionSetting(friend, p.friendlyShowSpec,    p.enemyShowSpec)
        or FactionSetting(friend, p.friendlyShowName,    p.enemyShowName)
        or false
end

BBM.ArenaNamesOwnsNameText = OwnsNameText

local function Hook()
    if BBM.hooks["ArenaNames_UpdateName"] then return end
    BBM.hooks["ArenaNames_UpdateName"] = true

    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        if issecretvalue(frame) then return end
        if not frame or frame:IsForbidden() or not frame.unit then return end
        local unit = frame.unit
        if not unit:find("nameplate") then return end

        if ArenaTestMode() then
            local nameplate = GetNamePlate(unit)
            if nameplate and not IsForbiddenNameplate(nameplate) then
                ShowHideArenaNameTestMode(nameplate, unit)
            end
            return
        end

        local text = GetReplaceText(unit)
        if text and frame.name then
            SetColoredText(frame.name, text)
        end
    end)

    if Plater and Plater.UpdateUnitName then
        hooksecurefunc(Plater, "UpdateUnitName", function(plateFrame)
            local unit = plateFrame and plateFrame.namePlateUnitToken
            if not unit then return end

            if ArenaTestMode() then
                local nameplate = GetNamePlate(unit)
                if nameplate and not IsForbiddenNameplate(nameplate) then
                    ShowHideArenaNameTestMode(nameplate, unit)
                end
                return
            end

            local text = GetReplaceText(unit)
            if text and plateFrame.CurrentUnitNameString then
                SetColoredText(plateFrame.CurrentUnitNameString, text)
            end
        end)
    end
end

local function ApplyHook()
    local p = getProfile()
    if p.enabled and (p.namesMode == "adapt" or p.namesMode == "replace") then
        Hook()
    end
end

table.insert(BBM.RefreshCallbacks, function()
    ApplyHook()

    if isInArena() or ArenaTestMode() then
        BBM.On("NAME_PLATE_UNIT_ADDED",   onNamePlateAdded)
        BBM.On("NAME_PLATE_UNIT_REMOVED", onNamePlateRemoved)
        BBM.On("UNIT_FACTION",            onUnitFaction)
    else
        BBM.Off("NAME_PLATE_UNIT_ADDED",   onNamePlateAdded)
        BBM.Off("NAME_PLATE_UNIT_REMOVED", onNamePlateRemoved)
        BBM.Off("UNIT_FACTION",            onUnitFaction)
    end

    local p = getProfile()
    if not (isInArena() or ArenaTestMode()) or not p.enabled then
        for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
            HideArenaDisplay(nameplate)
            local unit = nameplate.namePlateUnitToken
                or (nameplate.UnitFrame and nameplate.UnitFrame.unit)
            ClearExternalNameOverride(nameplate, unit)
        end
        wipe(unitToArenaIndex)
        wipe(unitToTestSpecID)
        return
    end

    if not ArenaTestMode() then wipe(unitToArenaIndex) end

    for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
        if not IsForbiddenNameplate(nameplate) then
            local unit = nameplate.namePlateUnitToken
                or (nameplate.UnitFrame and nameplate.UnitFrame.unit)
            if unit then
                if ArenaTestMode() then
                    ShowHideArenaNameTestMode(nameplate, unit)
                else
                    local friend     = isFriend(unit)
                    local arenaIndex = FindArenaIndex(unit, friend)
                    if arenaIndex then
                        unitToArenaIndex[unit] = arenaIndex
                        UpdateArenaDisplay(nameplate, unit, arenaIndex)
                    end
                end
            end
        end
    end
end)

table.insert(BBM.EnableCallbacks, function(_)
    BBM.On("PLAYER_ENTERING_WORLD", onPlayerEnteringWorld)
    if isInArena() or ArenaTestMode() then
        BBM.On("NAME_PLATE_UNIT_ADDED",   onNamePlateAdded)
        BBM.On("NAME_PLATE_UNIT_REMOVED", onNamePlateRemoved)
        BBM.On("UNIT_FACTION",            onUnitFaction)
    end
    ApplyHook()
end)
