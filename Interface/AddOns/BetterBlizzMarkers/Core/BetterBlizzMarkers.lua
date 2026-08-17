local addonName, BBM = ...

BBM.addonName      = "BetterBlizzMarkers"
BBM.addonNameColor = "Better|cff00c0ffBlizz|rMarkers"
BBM.addonNameLogo  = "Better|cff00c0ffBlizz|rMarkers |A:gmchat-icon-blizz:16:16|a"

local addon = {}
BBM.addon   = addon

local eventFrame    = CreateFrame("Frame")
local eventHandlers = {}

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local list = eventHandlers[event]
    if list then
        for i = 1, #list do list[i](event, ...) end
    end
end)

function BBM.On(event, handler)
    if not eventHandlers[event] then
        eventHandlers[event] = {}
        eventFrame:RegisterEvent(event)
    end
    local list = eventHandlers[event]
    for _, fn in ipairs(list) do
        if fn == handler then return end
    end
    list[#list + 1] = handler
end

function BBM.Off(event, handler)
    local list = eventHandlers[event]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i] == handler then table.remove(list, i) end
    end
    if #list == 0 then
        eventHandlers[event] = nil
        eventFrame:UnregisterEvent(event)
    end
end

local runAfterCombatQueue = {}
local function onRunAfterCombatRegen(_)
    local queue = runAfterCombatQueue
    runAfterCombatQueue = {}
    BBM.Off("PLAYER_REGEN_ENABLED", onRunAfterCombatRegen)
    for _, fn in ipairs(queue) do fn() end
end
function BBM.RunAfterCombat(fn)
    if not InCombatLockdown() then
        fn()
    else
        runAfterCombatQueue[#runAfterCombatQueue + 1] = fn
        BBM.On("PLAYER_REGEN_ENABLED", onRunAfterCombatRegen)
    end
end

local function DeepFill(target, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then target[k] = {} end
            DeepFill(target[k], v)
        elseif target[k] == nil then
            target[k] = v
        end
    end
end
BBM.DeepFill = DeepFill

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("ADDON_LOADED")
bootFrame:SetScript("OnEvent", function(_, _, name)
    if name == addonName then
        bootFrame:UnregisterEvent("ADDON_LOADED")
        addon:OnInitialize()
        addon:OnEnable()
    end
end)

BBM.EnableCallbacks = {}

BBM.RefreshCallbacks = {}

BBM.hooks = {}

local pendingOpenAfterCombat = false

function addon:OnInitialize()
    BBM.InitProfiles()

    SLASH_BBM1 = "/bbm"
    SlashCmdList["BBM"] = function(msg) self:OpenConfig(msg) end

    BBM.BuildBBGPanel()
end

function addon:OnEnable()
    BBM.On("ZONE_CHANGED_NEW_AREA", function(_) addon:RefreshAll() end)

    for _, fn in ipairs(BBM.EnableCallbacks) do fn(self) end
end

BBM.OtherNameplateAddonActive = false
BBM.On("PLAYER_LOGIN", function()
    BBM.OtherNameplateAddonActive = BBM.IsNameplateAddonActive()
end)

function BBM.EnsureStackingBoundsFrame(nameplate)
    if BBM.OtherNameplateAddonActive then return end

    local container = BBM.CreateNameplateContainer(nameplate)

    if nameplate.BetterBlizzMarkers.bbmStackingZone then
        nameplate:SetStackingBoundsFrame(nameplate.BetterBlizzMarkers.bbmStackingZone)
        return
    end

    local zone = CreateFrame("Frame", nil, container)
    zone:SetPoint("TOPLEFT", nameplate.UnitFrame.HealthBarsContainer, "TOPLEFT", -4, 5)
    zone:SetPoint("BOTTOMRIGHT", nameplate.UnitFrame.HealthBarsContainer, "BOTTOMRIGHT", 4, -5)
    local tex = zone:CreateTexture(nil, "BACKGROUND")
    tex:SetColorTexture(0, 0, 0, 0)
    tex:SetAllPoints(zone)
    zone.tex = tex

    nameplate.BetterBlizzMarkers.bbmStackingZone = zone
    nameplate:SetStackingBoundsFrame(zone)
end

local function onNamePlateAdded(_, unitToken)
    local nameplate = BBM.GetNamePlate(unitToken)
    if BBM.IsForbiddenNameplate(nameplate) then return end
    BBM.EnsureStackingBoundsFrame(nameplate)
end

local function onUnitFaction(_, unitToken)
    if not BBM.GetNamePlate(unitToken) then return end
    C_Timer.After(0.1, function()
        onNamePlateAdded(_, unitToken)
    end)
end

table.insert(BBM.EnableCallbacks, function(_)
    BBM.On("NAME_PLATE_UNIT_ADDED", onNamePlateAdded)
    BBM.On("UNIT_FACTION", onUnitFaction)
end)

function addon:RefreshAll()
    for _, fn in ipairs(BBM.RefreshCallbacks) do fn() end
end

BBM.testModes = {
    classIcons = false,
    totemIcons = false,
    arenaNames = false,
}

function BBM.IsTestMode(key)
    return key ~= nil and BBM.testModes[key] == true
end

function BBM.AnyTestMode()
    for _, on in pairs(BBM.testModes) do
        if on then return true end
    end
    return false
end

function BBM.SetExclusiveTestMode(key)
    local changed = false
    for k in pairs(BBM.testModes) do
        local want = (k == key)
        if BBM.testModes[k] ~= want then
            BBM.testModes[k] = want
            changed = true
        end
    end
    if not changed then return end

    addon:RefreshAll()
    if BBM.RefreshGUI then BBM.RefreshGUI() end
end

function BBM.ToggleTestMode(key)
    if BBM.IsTestMode(key) then
        BBM.SetExclusiveTestMode(nil)
    else
        BBM.SetExclusiveTestMode(key)
    end
end

function BBM.ClearTestModes()
    BBM.SetExclusiveTestMode(nil)
end

function BBM.OnSettingsPageShown(key)
    if not BBM.AnyTestMode() then return end
    BBM.SetExclusiveTestMode(key)
end

BBM.On("PLAYER_ENTERING_WORLD", BBM.ClearTestModes)

function addon:Message(msg)
    print(BBM.addonNameLogo .. ": " .. tostring(msg))
end

local subCategoryAliases = {
    totem       = "totem",
    totems      = "totem",
    totemicon   = "totem",
    totemicons  = "totem",
    class       = "class",
    classicon   = "class",
    classicons  = "class",
    arena       = "arena",
    arenaname   = "arena",
    arenanames  = "arena",
    names       = "arena",
    other       = "misc",
    misc        = "misc",
    profile     = "profiles",
    profiles    = "profiles",
}

local pendingOpenAfterCombatKey = nil

local function onPlayerRegenEnabled(_)
    if pendingOpenAfterCombat then
        pendingOpenAfterCombat = false
        BBM.Off("PLAYER_REGEN_ENABLED", onPlayerRegenEnabled)
        addon:OpenConfig(pendingOpenAfterCombatKey)
    end
end

function addon:OpenConfig(subCategory)
    if InCombatLockdown() then
        if not pendingOpenAfterCombat then
            pendingOpenAfterCombat = true
            pendingOpenAfterCombatKey = subCategory
            BBM.On("PLAYER_REGEN_ENABLED", onPlayerRegenEnabled)
            self:Message("Waiting for combat to end before opening settings...")
        end
        return
    end
    local BBG = BetterBlizzGUI
    if not (BBG and BBG.OpenPanel and addon.bbgPanel) then return end

    local panel = addon.bbgPanel
    if subCategory and subCategory ~= "" then
        local key = subCategoryAliases[subCategory:lower():gsub("%s+", "")]
        local subPanel = key and panel.subPanels and panel.subPanels[key]
        if subPanel then
            panel = subPanel
        else
            self:Message("Unknown settings category: \"" .. subCategory .. "\"")
        end
    end
    BBG.OpenPanel(panel)
end
