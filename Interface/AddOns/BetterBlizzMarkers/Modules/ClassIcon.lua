local addonName, BBM = ...

local addon = BBM.addon

local anchorOpposite      = BBM.anchorOpposite
local HealerSpecs         = BBM.HealerSpecs
local classificationIcons = BBM.classificationIcons
local petSpellIcons       = BBM.petSpellIcons
local petClasses          = BBM.petClasses
local ALL_SPECS           = BBM.ALL_SPECS

local isFriend                 = BBM.isFriend
local isEnemy                  = BBM.isEnemy
local GetAnchorFrame           = BBM.GetAnchorFrame
local isInArena                = BBM.isInArena
local isInBG                   = BBM.isInBG
local isInCity                 = BBM.isInCity
local isInWorld                = BBM.isInWorld
local IsForbiddenNameplate     = BBM.IsForbiddenNameplate
local GetNamePlate             = BBM.GetNamePlate
local CreateNameplateContainer = BBM.CreateNameplateContainer
local GetSpecID                = BBM.GetSpecID
local SetColoredText           = BBM.SetColoredText
local SetUnitNameOverride      = BBM.SetUnitNameOverride
local IsPetUnit                = BBM.IsPetUnit
local GetHealthBar             = BBM.GetHealthBar

local playerClass         = UnitClassBase("player")
local currentPetIcon      = nil
local prevTargetNameplate = nil

local function GetBGObjectiveIcon(unit)
    local classification = UnitPvpClassification(unit)
    return classification and classificationIcons[classification]
end

local function UpdateCurrentPetIcon()
    currentPetIcon = nil
    if not UnitExists("pet") then return end
    for spellID, iconID in pairs(petSpellIcons) do
        if IsSpellKnownOrOverridesKnown(spellID, true) then
            currentPetIcon = iconID
            return
        end
    end
end

local function FactionSetting(friend, friendlyVal, enemyVal)
    if friend then return friendlyVal end
    return enemyVal
end

local function getFactionSettings(friend)
    local p = addon.db.profile.classIcons

    local showCCFaction = p.showCC  and FactionSetting(friend, p.showCCFriendly,  p.showCCEnemy)
    local pinFaction    = p.pinMode and FactionSetting(friend, p.pinModeFriendly, p.pinModeEnemy)

    if not p.separateSettings then
        return p.anchor, p.xPos, p.yPos, showCCFaction, pinFaction, p.scale
    end
    if friend then
        return p.friendlyAnchor, p.friendlyXPos, p.friendlyYPos, showCCFaction, pinFaction, p.friendlyScale
    else
        return p.enemyAnchor, p.enemyXPos, p.enemyYPos, showCCFaction, pinFaction, p.enemyScale
    end
end

local function InitCCAuraIcon(auraFrame, f)
    auraFrame:SetSize(42, 42)
    auraFrame:SetPoint("CENTER", f)

    local icon = auraFrame:CreateTexture(nil, "OVERLAY", nil, 6)
    icon:SetAllPoints(auraFrame)
    auraFrame:SetIcon(icon)

    local mask = auraFrame:CreateMaskTexture()
    mask:SetTexture("Interface/Masks/CircleMaskScalable")
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)

    local cooldown = CreateFrame("Cooldown", nil, auraFrame, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetDrawEdge(false)
    cooldown:SetDrawSwipe(true)
    cooldown:SetSwipeColor(0, 0, 0, 0.7)
    cooldown:SetSwipeTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    cooldown:SetUseCircularEdge(true)
    cooldown:SetReverse(true)
    auraFrame:SetDurationCooldown(cooldown)

    local glow = auraFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    glow:SetAtlas("charactercreate-ring-select")
    glow:SetPoint("CENTER", auraFrame)
    glow:SetSize(59, 59)

    auraFrame:SetMouseMotionEnabled(false)
end

local function CreateCCAuraContainer(f)
    if f.auraContainer then return end

    local container = CreateFrame("AuraContainer", nil, f, "CustomAuraContainerTemplate")
    container:SetFrameStrata("HIGH")
    container:SetFrameLevel(1)
    container:SetPoint("CENTER", f)
    container:SetEnabled(false)
    container:Hide()

    container:AddAuraSlot("CC", "HARMFUL|CROWD_CONTROL", {
        sortMethod      = AuraContainerSortMethod.AuraInstanceIDOnly,
        sortDirection   = AuraContainerSortDirection.Reverse,
        initializeFrame = function(auraFrame) InitCCAuraIcon(auraFrame, f) end,
    })

    f.auraContainer = container
end

local function UpdateCCAuraContainer(f, unitToken)
    local container = f.auraContainer
    container:SetUnit(unitToken)
    container:SetEnabled(true)
    container:Show()
end

local function DisableCCAuraContainer(f)
    if not f.auraContainer then return end
    f.auraContainer:SetEnabled(false)
    f.auraContainer:Hide()
end

local function UpdateCCOverlay(nameplate, unitToken, friend)
    local f = nameplate.BetterBlizzMarkers and nameplate.BetterBlizzMarkers.ClassIcon
    if not f then return end
    local _, _, _, showCC = getFactionSettings(friend)

    if not showCC then DisableCCAuraContainer(f); return end
    UpdateCCAuraContainer(f, unitToken)
end

local function CreateIcon(nameplate)
    CreateNameplateContainer(nameplate)
    if nameplate.BetterBlizzMarkers.ClassIcon then return end

    local f = CreateFrame("Frame", nil, nameplate.BetterBlizzMarkers)
    f:SetSize(41, 41)
    f:SetIgnoreParentAlpha(true)
    f:SetFrameStrata("BACKGROUND")
    f:SetFrameLevel(0)

    f.icon = f:CreateTexture(nil, "BORDER")
    f.icon:SetPoint("CENTER", f)
    f.icon:SetSize(37, 37)

    f.mask = f:CreateMaskTexture()
    f.mask:SetTexture("Interface/Masks/CircleMaskScalable")
    f.mask:SetSize(37, 37)
    f.mask:SetPoint("CENTER", f.icon)
    f.icon:AddMaskTexture(f.mask)

    f.border = f:CreateTexture(nil, "OVERLAY", nil, 6)
    f.border:SetAtlas("AutoQuest-badgeborder")
    f.border:SetAllPoints(f)

    f.bg = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    f.bg:SetAtlas("talents-node-choiceflyout-circle-greenglow")
    f.bg:SetPoint("CENTER", f)
    f.bg:SetDesaturated(true)

    f.highlight = f:CreateTexture(nil, "OVERLAY", nil, 7)
    f.highlight:SetAtlas("charactercreate-ring-select")
    f.highlight:SetSize(56, 56)
    f.highlight:SetPoint("CENTER", f)
    f.highlight:Hide()

    f.pin = f:CreateTexture(nil, "BACKGROUND", nil, 0)
    f.pin:SetAtlas("UI-QuestPoiImportant-QuestNumber-SuperTracked")
    f.pin:SetSize(43, 39)
    f.pin:SetPoint("TOP", f.icon, "BOTTOM", 0, 10)
    f.pin:SetDesaturated(true)
    f.pin:SetTexCoord(0, 1, 0.27, 1)
    f.pin:Hide()

    CreateCCAuraContainer(f)

    nameplate.BetterBlizzMarkers.ClassIcon = f
end

local function UpdateIcon(nameplate, friend)
    local f = nameplate.BetterBlizzMarkers and nameplate.BetterBlizzMarkers.ClassIcon
    if not f then return end
    local profile = addon.db.profile.classIcons
    local anchor, xPos, yPos, _, pinMode, scale = getFactionSettings(friend)

    f:SetScale(scale or 1.0)
    f:SetFrameStrata(profile.strata or "BACKGROUND")
    f:ClearAllPoints()
    f:SetPoint(anchorOpposite[anchor], GetAnchorFrame(nameplate), anchor, xPos, yPos + 7)

    if pinMode then
        local classColor = f.pinClass and C_ClassColor.GetClassColor(f.pinClass)
        if classColor then f.pin:SetVertexColor(classColor.r, classColor.g, classColor.b) end
        f.pin:Show()
    else
        f.pin:Hide()
    end
end

local function RenderIcon(nameplate, unitToken, class, friend, bgIcon, isPlayer)
    local f       = nameplate.BetterBlizzMarkers.ClassIcon
    local profile = addon.db.profile.classIcons
    local isPet   = UnitIsUnit(unitToken, "pet")

    f.pinClass = class
    local classColor = C_ClassColor.GetClassColor(class)

    local specID   = nil
    local isHealer = false
    if isPlayer and not bgIcon then
        specID   = GetSpecID(unitToken)
        isHealer = specID and HealerSpecs[specID] or false
    end

    if bgIcon then
        f.icon:SetTexture(bgIcon)
        f.icon:SetTexCoord(0, 1, 0, 1)
    elseif isPet then
        f.icon:SetTexture(currentPetIcon or 618972)
        f.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    elseif profile.showHealerIcon and isHealer then
        f.icon:SetTexture("interface/lfgframe/uilfgprompts")
        f.icon:SetTexCoord(0.015, 0.1077, 0.7684, 0.8606)
    elseif profile.showSpecIcon and specID then
        local specIcon = select(4, GetSpecializationInfoByID(specID))
        if specIcon then
            f.icon:SetTexture(specIcon)
            f.icon:SetTexCoord(0, 1, 0, 1)
        else
            f.icon:SetAtlas(GetClassAtlas(class))
            f.icon:SetTexCoord(-0.06, 1.05, -0.06, 1.05)
        end
    else
        f.icon:SetAtlas(GetClassAtlas(class))
        f.icon:SetTexCoord(-0.06, 1.05, -0.06, 1.05)
    end

    if profile.classColorBorder and classColor then
        f.border:SetDesaturated(true)
        f.border:SetVertexColor(classColor.r, classColor.g, classColor.b)
    else
        f.border:SetDesaturated(false)
        f.border:SetVertexColor(1, 1, 1)
    end

    local bgSize = UnitIsUnit(unitToken, "target") and 67 or 62
    f.bg:SetSize(bgSize, bgSize)
    f.bg:SetVertexColor(0.1, 0.1, 0.1)
    f.bg:Show()

    if profile.showTargetGlow and UnitIsUnit(unitToken, "target") then
        if profile.targetGlowClassColor and classColor then
            f.highlight:SetDesaturated(true)
            f.highlight:SetVertexColor(classColor.r, classColor.g, classColor.b)
        else
            f.highlight:SetDesaturated(false)
            f.highlight:SetVertexColor(1, 0.88, 0)
        end
        f.highlight:Show()
    else
        f.highlight:Hide()
    end

    UpdateIcon(nameplate, friend)
    UpdateCCOverlay(nameplate, unitToken, friend)
    f:Show()
end

local function GetBlizzardNameText(nameplate)
    local uf = nameplate.UnitFrame
    if not uf or uf:IsForbidden() then return nil end
    return uf.name, uf
end

local function ShouldHideName(nameplate, unitToken)
    if not addon.db.profile.classIcons.hideFriendlyNames then return false end
    if not unitToken then return false end

    local f = nameplate.BetterBlizzMarkers and nameplate.BetterBlizzMarkers.ClassIcon
    if not f or not f:IsShown() then return false end
    if not isFriend(unitToken) then return false end

    if BBM.ArenaNamesOwnsNameText(unitToken) then return false end

    return true
end

local function BlankNameText(f, nameText)
    if not nameText then return end
    local current = nameText:GetText()
    if current and current ~= "" then f.savedName = current end
    nameText:SetText("")
end

local function HideName(nameplate, unitToken, f)
    BlankNameText(f, GetBlizzardNameText(nameplate))
    SetUnitNameOverride(nameplate, unitToken, "", true)
end

local function RestoreName(nameplate, unitToken, f)
    SetUnitNameOverride(nameplate, unitToken, nil, true)
    local nameText = GetBlizzardNameText(nameplate)
    if nameText and f.savedName then nameText:SetText(f.savedName) end
    f.savedName = nil
end

local function UpdateNameVisibility(nameplate, unitToken)
    local f = nameplate.BetterBlizzMarkers and nameplate.BetterBlizzMarkers.ClassIcon
    if not f then return end

    if ShouldHideName(nameplate, unitToken) then
        f.nameHidden = true
        HideName(nameplate, unitToken, f)
    elseif f.nameHidden then
        f.nameHidden = nil
        RestoreName(nameplate, unitToken, f)
    end
end

local function RestorePetHealthbar(f)
    if not f.petBar then return end
    local alpha = f.petBarAlpha
    if not alpha or alpha == 0 then alpha = 1 end
    f.petBar:SetAlpha(alpha)
    f.petBar, f.petBarAlpha = nil, nil
end

local function UpdatePetHealthbar(nameplate, unitToken)
    local f = nameplate.BetterBlizzMarkers and nameplate.BetterBlizzMarkers.ClassIcon
    if not f then return end

    local p    = addon.db.profile.classIcons
    local hide = not BBM.OtherNameplateAddonActive
        and p.hidePetHealthbars
        and IsPetUnit(unitToken)
        and FactionSetting(isFriend(unitToken), p.hidePetHealthbarsFriendly, p.hidePetHealthbarsEnemy)
    if not hide then
        RestorePetHealthbar(f)
        return
    end

    local bar = GetHealthBar(nameplate)
    if not bar then return end

    if f.petBar ~= bar then
        RestorePetHealthbar(f)
        f.petBar      = bar
        f.petBarAlpha = bar:GetAlpha()
    end
    bar:SetAlpha(0)
end

local function HookNames()
    if BBM.hooks["ClassIcon_HideNames"] then return end
    BBM.hooks["ClassIcon_HideNames"] = true

    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        if issecretvalue(frame) then return end
        if not frame or frame:IsForbidden() or not frame.unit then return end
        local unit = frame.unit
        if not unit:find("nameplate") then return end

        local nameplate = GetNamePlate(unit)
        if IsForbiddenNameplate(nameplate) then return end
        if frame.name and ShouldHideName(nameplate, unit) then
            local f = nameplate.BetterBlizzMarkers.ClassIcon
            f.nameHidden = true
            BlankNameText(f, frame.name)
        end
    end)

    if Plater and Plater.UpdateUnitName then
        hooksecurefunc(Plater, "UpdateUnitName", function(plateFrame)
            local unit = plateFrame and plateFrame.namePlateUnitToken
            if not unit then return end
            if plateFrame.CurrentUnitNameString and ShouldHideName(plateFrame, unit) then
                SetColoredText(plateFrame.CurrentUnitNameString, "")
            end
        end)
    end
end

local function ApplyNameHook()
    if addon.db.profile.classIcons.hideFriendlyNames then HookNames() end
end

local function UpdateClassIcon(nameplate, unitToken)
    CreateIcon(nameplate)

    local f       = nameplate.BetterBlizzMarkers.ClassIcon
    local profile = addon.db.profile.classIcons

    if isInArena() and not profile.showInArena then f:Hide(); DisableCCAuraContainer(f); return end
    if isInBG()    and not profile.showInBG    then f:Hide(); DisableCCAuraContainer(f); return end
    if isInCity()  and not profile.showInCity  then f:Hide(); DisableCCAuraContainer(f); return end
    if isInWorld() and not profile.showInWorld then f:Hide(); DisableCCAuraContainer(f); return end

    local isPlayer = UnitIsPlayer(unitToken)
    local isPet    = UnitIsUnit(unitToken, "pet")
    if not isPlayer and not isPet then f:Hide(); DisableCCAuraContainer(f); return end

    local friend = isFriend(unitToken)
    local enemy  = isEnemy(unitToken)
    if friend and not profile.showFriendly then f:Hide(); DisableCCAuraContainer(f); return end
    if enemy  and not profile.showEnemy   then f:Hide(); DisableCCAuraContainer(f); return end

    local bgIcon = GetBGObjectiveIcon(unitToken)

    local class
    if isPet then
        if profile.showOnPlayerPet and petClasses[playerClass] then
            class = playerClass
        end
    else
        class = UnitClassBase(unitToken)
    end

    if not class then
        f:Hide()
        DisableCCAuraContainer(f)
        return
    end

    RenderIcon(nameplate, unitToken, class, friend, bgIcon, isPlayer)
end

local function ShowHideIcon(nameplate, unitToken)
    if not nameplate then return end
    UpdateClassIcon(nameplate, unitToken)
    UpdateNameVisibility(nameplate, unitToken)
    UpdatePetHealthbar(nameplate, unitToken)
end

local testClassFiles

local function RandomClassFile()
    if not testClassFiles then
        testClassFiles = {}
        for _, class in ipairs(BBM.GetClassSpecTree()) do
            testClassFiles[#testClassFiles + 1] = class.file
        end
    end
    if #testClassFiles == 0 then return playerClass end
    return testClassFiles[math.random(#testClassFiles)]
end

local function UpdateClassIconTestMode(nameplate, unitToken)
    CreateIcon(nameplate)

    local f       = nameplate.BetterBlizzMarkers.ClassIcon
    local profile = addon.db.profile.classIcons

    local isPlayer = UnitIsPlayer(unitToken)
    local isPet    = UnitIsUnit(unitToken, "pet")

    local friend = isFriend(unitToken)
    local enemy  = isEnemy(unitToken)
    if friend and not profile.showFriendly then f:Hide(); return end
    if enemy  and not profile.showEnemy   then f:Hide(); return end

    local bgIcon = GetBGObjectiveIcon(unitToken)

    local class = f.testClass
    if not class then
        if isPlayer then
            class = UnitClassBase(unitToken)
        elseif isPet and petClasses[playerClass] then
            class = playerClass
        end
        class = class or RandomClassFile()
        f.testClass = class
    end

    if not class then f:Hide(); return end

    RenderIcon(nameplate, unitToken, class, friend, bgIcon, isPlayer)

    DisableCCAuraContainer(f)
end

local function ShowHideIconTestMode(nameplate, unitToken)
    if not nameplate then return end
    UpdateClassIconTestMode(nameplate, unitToken)
    UpdateNameVisibility(nameplate, unitToken)
    UpdatePetHealthbar(nameplate, unitToken)
end

local function ClearTestState(nameplate)
    local f = nameplate.BetterBlizzMarkers and nameplate.BetterBlizzMarkers.ClassIcon
    if f then f.testClass = nil end
end

local function onNamePlateAdded(_, unitToken)
    local nameplate = GetNamePlate(unitToken)
    if IsForbiddenNameplate(nameplate) then return end
    if BBM.IsTestMode("classIcons") then
        ShowHideIconTestMode(nameplate, unitToken)
    else
        ShowHideIcon(nameplate, unitToken)
    end
end

local function onNamePlateRemoved(_, unitToken)
    local nameplate = GetNamePlate(unitToken)
    if IsForbiddenNameplate(nameplate) then return end
    if nameplate.BetterBlizzMarkers then
        local ci = nameplate.BetterBlizzMarkers.ClassIcon
        if ci then
            DisableCCAuraContainer(ci)
            ci.testClass = nil
            ci:Hide()
            if ci.nameHidden then
                ci.nameHidden = nil
                SetUnitNameOverride(nameplate, unitToken, nil, false)
            end
            RestorePetHealthbar(ci)
        end
    end
end

local function onUnitFaction(_, unitToken)
    if not GetNamePlate(unitToken) then return end
    C_Timer.After(0.1, function()
        onNamePlateAdded(_, unitToken)
    end)
end

local function onUnitPet(_, unitToken)
    if unitToken ~= "player" then return end
    if petClasses[playerClass] then UpdateCurrentPetIcon() end
    C_Timer.After(0.5, function()
        local nameplate = GetNamePlate("pet")
        if not IsForbiddenNameplate(nameplate) then
            ShowHideIcon(nameplate, "pet")
        end
    end)
end

local function onPlayerTargetChanged(_)
    if prevTargetNameplate then
        local unit = prevTargetNameplate.namePlateUnitToken
            or (prevTargetNameplate.UnitFrame and prevTargetNameplate.UnitFrame.unit)
        if unit and prevTargetNameplate.BetterBlizzMarkers then
            ShowHideIcon(prevTargetNameplate, unit)
        end
        prevTargetNameplate = nil
    end
    local nameplate = GetNamePlate("target")
    if not IsForbiddenNameplate(nameplate) then
        local unit = nameplate.namePlateUnitToken
            or (nameplate.UnitFrame and nameplate.UnitFrame.unit)
        if unit then ShowHideIcon(nameplate, unit) end
        prevTargetNameplate = nameplate
    end
end

function addon:UpdateEventRegistration()
    local p = self.db.profile.classIcons
    if p.showOnPlayerPet then BBM.On("UNIT_PET", onUnitPet)
    else                      BBM.Off("UNIT_PET", onUnitPet) end
end

table.insert(BBM.RefreshCallbacks, function()
    ApplyNameHook()
    local testMode = BBM.IsTestMode("classIcons")
    for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
        if not IsForbiddenNameplate(nameplate) then
            local unit = nameplate.namePlateUnitToken
                or (nameplate.UnitFrame and nameplate.UnitFrame.unit)
            if unit then
                if testMode then
                    ShowHideIconTestMode(nameplate, unit)
                else
                    ClearTestState(nameplate)
                    ShowHideIcon(nameplate, unit)
                end
            end
        end
    end
end)

table.insert(BBM.EnableCallbacks, function(_)
    BBM.On("NAME_PLATE_UNIT_ADDED",   onNamePlateAdded)
    BBM.On("NAME_PLATE_UNIT_REMOVED", onNamePlateRemoved)
    BBM.On("UNIT_FACTION",            onUnitFaction)
    BBM.On("PLAYER_TARGET_CHANGED",   onPlayerTargetChanged)
    addon:UpdateEventRegistration()
    ApplyNameHook()
    if petClasses[playerClass] then UpdateCurrentPetIcon() end
end)
