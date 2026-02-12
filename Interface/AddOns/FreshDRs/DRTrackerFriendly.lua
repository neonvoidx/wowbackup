local ADDON_NAME = ...

local Friendly = {}
_G.NameplateDRs_Friendly = Friendly

local CreateFrame = _G.CreateFrame
local C_Timer = _G.C_Timer
local GetTime = _G.GetTime
local C_Spell = _G.C_Spell
local GetSpellInfo = _G.GetSpellInfo
local LibStub = _G.LibStub
local UnitGUID = _G.UnitGUID
local UnitIsUnit = _G.UnitIsUnit
local wipe = _G.wipe

local db
local enabled = false
local DRList
local nameToCategory

local states = {}
local overlays = {}
local eventFrame
local pruneTicker

local maxAuras = 40
local DR_RESET_TIME = 16
local ICON_SIZE = 22
local ICON_SPACING = 2
local TIMER_UPDATE_RATE = 0.1

local function EnsureDRList()
    if DRList then
        return true
    end
    if not LibStub then
        return false
    end
    local ok, lib = pcall(LibStub, "DRList-1.0")
    if ok and lib then
        DRList = lib
        return true
    end
    return false
end

local function SafeGetSpellName(spellId)
    if not spellId then
        return nil
    end
    if C_Spell and C_Spell.GetSpellName then
        local ok, name = pcall(C_Spell.GetSpellName, spellId)
        if ok and name then
            return name
        end
    end
    if GetSpellInfo then
        local ok, name = pcall(GetSpellInfo, spellId)
        if ok and name then
            return name
        end
    end
    return nil
end

local function EnsureNameMap()
    if nameToCategory then
        return true
    end
    if not EnsureDRList() then
        return false
    end
    local spells = DRList.GetSpells and DRList:GetSpells()
    if type(spells) ~= "table" then
        return false
    end
    nameToCategory = {}
    for spellId, category in pairs(spells) do
        local name = SafeGetSpellName(spellId)
        if name then
            local cat = category
            if type(category) == "table" then
                cat = category[1]
            end
            if cat and not nameToCategory[name] then
                nameToCategory[name] = cat
            end
        end
    end
    return true
end

local function SafeLookupName(name)
    if not name or not nameToCategory then
        return nil
    end
    local ok, value = pcall(function()
        return nameToCategory[name]
    end)
    if ok then
        return value
    end
    return nil
end

local function RefreshDB()
    if type(_G.FreshDRsDB) == "table" then
        db = _G.FreshDRsDB
    end
end

local function GetPlayerAnchorFromSetting()
    local mode = db and db.friendlyPlayerAnchor or "player"
    if mode == "center" then
        return _G.UIParent, "CENTER", "CENTER"
    end

    local playerFrame = _G.PlayerFrame
    if playerFrame and playerFrame:IsShown() then
        return playerFrame, "TOPRIGHT", "TOPRIGHT"
    end
    return _G.UIParent, "CENTER", "CENTER"
end

local function SafeAuraValue(data, key)
    if not data then
        return nil
    end
    local ok, value = pcall(function()
        return data[key]
    end)
    if not ok then
        return nil
    end
    local okBool = pcall(function()
        return not not value
    end)
    if not okBool then
        return nil
    end
    return value
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
    local okKey = pcall(function()
        local t = {}
        t[guid] = true
    end)
    if not okKey then
        return nil
    end
    return guid
end

local function SafeGetCategory(spellId, auraName)
    if not spellId or not DRList then
        if auraName and db and db.friendlyNameFallback and EnsureNameMap() then
            return SafeLookupName(auraName)
        end
        return nil
    end
    local ok, category = pcall(DRList.GetCategoryBySpellID, DRList, spellId)
    if ok then
        if type(category) == "table" then
            return category[1]
        end
        if category then
            return category
        end
    end
    if auraName and db and db.friendlyNameFallback and EnsureNameMap() then
        return SafeLookupName(auraName)
    end
    return nil
end

local function FormatStage(count)
    if count >= 2 then
        return "IMM"
    end
    if count == 1 then
        return "1/2"
    end
    return ""
end

local function GetFriendlyFrame(unit)
    for i = 1, 40 do
        local frame = _G["CompactRaidFrame" .. i]
        if frame and frame.unit == unit and frame:IsShown() then
            return frame
        end
    end
    for i = 1, 4 do
        local frame = _G["CompactPartyFrameMember" .. i]
        if frame and frame.unit == unit and frame:IsShown() then
            return frame
        end
    end
    if unit == "player" then
        local playerFrame = _G.PlayerFrame
        if playerFrame and playerFrame:IsShown() then
            return playerFrame
        end
    end
    return nil
end

local function EnsureOverlay(unit)
    local overlay = overlays[unit]
    if overlay then
        return overlay
    end
    overlay = CreateFrame("Frame", nil, _G.UIParent)
    overlay.items = {}
    overlay.NPDRS_TimerElapsed = 0
    overlays[unit] = overlay
    return overlay
end

local function UpdateOverlayLayout(overlay, items, direction)
    local count = #items
    if count == 0 then
        overlay:SetSize(1, 1)
        return
    end
    direction = direction or "left"
    local width = (count * ICON_SIZE) + math.max(0, (count - 1) * ICON_SPACING)
    if direction == "up" or direction == "down" then
        overlay:SetSize(ICON_SIZE, width)
    else
        overlay:SetSize(width, ICON_SIZE)
    end
    for i = 1, count do
        local item = overlay.items[i]
        item:ClearAllPoints()
        if direction == "right" then
            if i == 1 then
                item:SetPoint("LEFT", overlay, "LEFT", 0, 0)
            else
                item:SetPoint("LEFT", overlay.items[i - 1], "RIGHT", ICON_SPACING, 0)
            end
        elseif direction == "up" then
            if i == 1 then
                item:SetPoint("BOTTOM", overlay, "BOTTOM", 0, 0)
            else
                item:SetPoint("BOTTOM", overlay.items[i - 1], "TOP", 0, ICON_SPACING)
            end
        elseif direction == "down" then
            if i == 1 then
                item:SetPoint("TOP", overlay, "TOP", 0, 0)
            else
                item:SetPoint("TOP", overlay.items[i - 1], "BOTTOM", 0, -ICON_SPACING)
            end
        else
            if i == 1 then
                item:SetPoint("RIGHT", overlay, "RIGHT", 0, 0)
            else
                item:SetPoint("RIGHT", overlay.items[i - 1], "LEFT", -ICON_SPACING, 0)
            end
        end
    end
end

local function GetOverlayAnchor(unit)
    RefreshDB()
    if db and db.friendlyPlayerSeparate and UnitIsUnit and UnitIsUnit(unit, "player") then
        local frame, point, relativePoint = GetPlayerAnchorFromSetting()
        return frame, true, point, relativePoint
    end
    return GetFriendlyFrame(unit), false, "TOPRIGHT", "TOPRIGHT"
end

local function RenderOverlay(overlay, anchor, offsetX, offsetY, items, point, relativePoint, direction)
    if not anchor then
        overlay:Hide()
        return
    end

    local now = GetTime()
    overlay:ClearAllPoints()
    local anchorPoint = point or "TOPRIGHT"
    local relPoint = relativePoint or anchorPoint
    overlay:SetPoint(anchorPoint, anchor, relPoint, offsetX or 0, offsetY or 0)
    overlay:SetFrameStrata("HIGH")
    if anchor.GetFrameLevel then
        overlay:SetFrameLevel(anchor:GetFrameLevel() + 10)
    end

    for i = 1, #items do
        local item = overlay.items[i]
        if not item then
            item = CreateFrame("Frame", nil, overlay)
            item:SetSize(ICON_SIZE, ICON_SIZE)
            item.icon = item:CreateTexture(nil, "ARTWORK")
            item.icon:SetAllPoints(item)
            item.cooldown = CreateFrame("Cooldown", nil, item, "CooldownFrameTemplate")
            item.cooldown:SetAllPoints(item)
            item.cooldown:SetDrawEdge(false)
            item.cooldown:SetDrawSwipe(false)
            item.cooldown:SetHideCountdownNumbers(true)
            item.cooldown:SetAlpha(0)
            item.timerText = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            item.timerText:SetPoint("TOPLEFT", item, "TOPLEFT", 1, -1)
            item.text = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            item.text:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -1, 1)
            if item.text.SetFont then
                item.text:SetFont("Fonts\\FRIZQT__.TTF", 7, "OUTLINE")
            end
            if item.timerText.SetFont then
                item.timerText:SetFont("Fonts\\FRIZQT__.TTF", 7, "OUTLINE")
            end
            overlay.items[i] = item
        end
        local iconTexture = items[i].icon or "Interface\\Icons\\INV_Misc_QuestionMark"
        item.icon:SetTexture(iconTexture)
        item.icon:SetVertexColor(1, 1, 1, 1)
        item.icon:SetAlpha(1)
        item.icon:SetDrawLayer("ARTWORK", 1)
        item.icon:Show()

        if not item.bg then
            item.bg = item:CreateTexture(nil, "BACKGROUND")
            item.bg:SetAllPoints(item)
        end
        if items[i].bgColor then
            item.bg:SetColorTexture(items[i].bgColor[1], items[i].bgColor[2], items[i].bgColor[3], items[i].bgColor[4] or 0.35)
            item.bg:Show()
        else
            item.bg:Hide()
        end

        if not items[i].active and items[i].resetAt and items[i].resetAt > now then
            local start = items[i].resetAt - DR_RESET_TIME
            item.cooldown:SetCooldown(start, DR_RESET_TIME)
            item.cooldown:Show()
        else
            item.cooldown:SetCooldown(0, 0)
            item.cooldown:Hide()
        end
        item.text:SetText(items[i].stage)
        if items[i].stage == "1/2" then
            item.text:SetTextColor(0, 1, 0, 1)
        elseif items[i].stage == "IMM" then
            item.text:SetTextColor(1, 0, 0, 1)
        else
            item.text:SetTextColor(1, 1, 1, 1)
        end
        item:Show()
    end

    for i = #items + 1, #overlay.items do
        overlay.items[i]:Hide()
    end

    UpdateOverlayLayout(overlay, items, direction)
    overlay:SetScript("OnUpdate", function(self, elapsed)
        self.NPDRS_TimerElapsed = (self.NPDRS_TimerElapsed or 0) + elapsed
        if self.NPDRS_TimerElapsed < TIMER_UPDATE_RATE then
            return
        end
        self.NPDRS_TimerElapsed = 0
        local nowTime = GetTime()
        for _, item in ipairs(self.items) do
            if item:IsShown() and item.cooldown and item.cooldown:IsShown() and item.resetAt then
                local remaining = item.resetAt - nowTime
                if remaining > 0 then
                    item.timerText:SetText(string.format("%.0f", remaining))
                else
                    item.timerText:SetText("")
                end
            else
                item.timerText:SetText("")
            end
        end
    end)
    for i, data in ipairs(items) do
        local item = overlay.items[i]
        item.resetAt = data.resetAt
    end
    overlay:Show()
end

local function UpdateOverlay(unit, guid, unitState, iconForCategory, durationForCategory, expiresForCategory)
    local overlayKey = unit
    local anchor, isPlayerSeparate, point, relativePoint = GetOverlayAnchor(unit)
    if isPlayerSeparate then
        overlayKey = "player_separate"
    end
    local overlay = EnsureOverlay(overlayKey)
    if not isPlayerSeparate then
        local separate = overlays.player_separate
        if separate then
            separate:Hide()
        end
    end

    local now = GetTime()
    local items = {}
    for category, catState in pairs(unitState) do
        if category ~= "unit" then
            if catState.resetAt and now > catState.resetAt then
                catState.count = 0
                catState.active = false
            end
            if catState.active or (catState.resetAt and catState.resetAt > now) then
                local item = {
                    category = category,
                    stage = FormatStage(catState.count),
                    icon = iconForCategory[category] or catState.icon,
                    active = catState.active,
                    resetAt = catState.resetAt,
                    duration = durationForCategory[category],
                    expires = expiresForCategory[category],
                }
                if isPlayerSeparate then
                    item.bgColor = { 0, 1, 0, 0.25 }
                end
                items[#items + 1] = item
            end
        end
    end

    table.sort(items, function(a, b)
        return tostring(a.category) < tostring(b.category)
    end)

    local offsetX = isPlayerSeparate and (db and db.friendlyPlayerOffsetX or 0) or (db and db.friendlyOffsetX or 0)
    local offsetY = isPlayerSeparate and (db and db.friendlyPlayerOffsetY or 0) or (db and db.friendlyOffsetY or 0)
    local direction = db and db.friendlyDirection or "left"
    if isPlayerSeparate then
        direction = db and db.playerDirection or direction
    end
    RenderOverlay(overlay, anchor, offsetX, offsetY, items, point, relativePoint, direction)
end

local function OnAuraApplied(unit, guid, category)
    if not guid then
        return
    end
    local unitState = states[guid]
    if not unitState then
        return
    end
    local catState = unitState[category]
    if not catState then
        return
    end
    local now = GetTime()

    catState.count = math.min(catState.count + 1, 2)
    catState.active = true
    catState.resetAt = nil
    catState.lastSeen = now
end

local function OnAuraRemoved(unit, guid, category)
    if not guid then
        return
    end
    local unitState = states[guid]
    if not unitState then
        return
    end
    local catState = unitState[category]
    if not catState then
        return
    end
    local now = GetTime()
    catState.active = false
    catState.resetAt = now + DR_RESET_TIME
    catState.lastSeen = now
    catState.expires = nil
end

local function ProcessUnitAuras(unit, filter)
    local guid = SafeUnitGUID(unit)
    if not guid then
        return
    end
    if not EnsureDRList() then
        return
    end

    local now = GetTime()
    local unitState = states[guid]
    if not unitState then
        unitState = {}
        states[guid] = unitState
    end
    unitState.unit = unit

    if db and db.friendlyHidePlayerInGroup and UnitIsUnit and UnitIsUnit(unit, "player") and unit ~= "player" then
        return
    end

    local present = {}
    local iconForCategory = {}
    local expiresForCategory = {}
    local durationForCategory = {}
    local instanceForCategory = {}
    local applicationsForCategory = {}
    for i = 1, maxAuras do
        local data = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
        if not data then
            break
        end
        local spellId = SafeAuraValue(data, "spellId")
        local auraName = SafeAuraValue(data, "name")
        local category = SafeGetCategory(spellId, auraName)
        if category then
            present[category] = true
            if not iconForCategory[category] then
                iconForCategory[category] = SafeAuraValue(data, "icon")
            end
            if not expiresForCategory[category] then
                expiresForCategory[category] = SafeAuraValue(data, "expirationTime")
            end
            if not durationForCategory[category] then
                durationForCategory[category] = SafeAuraValue(data, "duration")
            end
            if not instanceForCategory[category] then
                instanceForCategory[category] = SafeAuraValue(data, "auraInstanceID")
            end
            if not applicationsForCategory[category] then
                applicationsForCategory[category] = SafeAuraValue(data, "applications")
            end
        end
    end

    for category, catState in pairs(unitState) do
        if category ~= "unit" and catState.active and not present[category] then
            OnAuraRemoved(unit, guid, category)
        end
    end

    for category in pairs(present) do
        local catState = unitState[category]
        if not catState then
            catState = { count = 0, resetAt = 0, active = false }
            unitState[category] = catState
        end
        if not catState.active then
            OnAuraApplied(unit, guid, category)
        else
            local reapply = false
            local newInstance = instanceForCategory[category]
            if newInstance and catState.lastInstance and newInstance ~= catState.lastInstance then
                reapply = true
            end
            local newExpires = expiresForCategory[category]
            if newExpires and catState.lastExpires and newExpires > (catState.lastExpires + 0.2) then
                reapply = true
            end
            local newApps = applicationsForCategory[category]
            if newApps and catState.lastApplications and newApps > catState.lastApplications then
                reapply = true
            end
            if reapply and (not catState.lastCountTime or (now - catState.lastCountTime) > 0.2) then
                catState.count = math.min(catState.count + 1, 2)
                catState.lastCountTime = now
            end
        end
        catState.lastSeen = now
        catState.expires = expiresForCategory[category] or catState.expires
        catState.lastExpires = expiresForCategory[category] or catState.lastExpires
        catState.lastInstance = instanceForCategory[category] or catState.lastInstance
        catState.lastApplications = applicationsForCategory[category] or catState.lastApplications
        if iconForCategory[category] then
            catState.icon = iconForCategory[category]
        end
    end

    UpdateOverlay(unit, guid, unitState, iconForCategory, durationForCategory, expiresForCategory)
end

local function PruneExpired()
    local now = GetTime()
    for guid, unitState in pairs(states) do
        local unit = unitState.unit
        local changed = false
        for category, catState in pairs(unitState) do
            if category ~= "unit" and catState.active then
                if catState.expires and now > catState.expires then
                    catState.active = false
                    catState.resetAt = now + DR_RESET_TIME
                    catState.expires = nil
                    changed = true
                end
            elseif category ~= "unit" and catState.resetAt and now > catState.resetAt then
                catState.resetAt = nil
                catState.count = 0
                changed = true
            end
        end
        if changed and unit then
            UpdateOverlay(unit, guid, unitState, {}, {}, {})
        end
    end
end

local function ShowFriendlyTest()
    RefreshDB()
    if not (db and db.friendlyTestMode) then
        local overlay = overlays.friendly_test
        if overlay then
            overlay:Hide()
        end
        return
    end
    local anchor = GetFriendlyFrame("party1") or GetFriendlyFrame("player") or _G.PlayerFrame or _G.UIParent
    local overlay = EnsureOverlay("friendly_test")
    local now = GetTime()
    local items = {
        {
            category = "stun",
            stage = "1/2",
            icon = "Interface\\Icons\\Ability_Rogue_Sap",
            bgColor = { 0, 1, 0, 0.25 },
            active = false,
            resetAt = now + DR_RESET_TIME,
        },
        {
            category = "disorient",
            stage = "IMM",
            icon = "Interface\\Icons\\Spell_Shadow_MindSteal",
            bgColor = { 0, 1, 0, 0.25 },
            active = false,
            resetAt = now + (DR_RESET_TIME - 4),
        },
    }
    local direction = db and db.friendlyDirection or "left"
    RenderOverlay(overlay, anchor, db and db.friendlyOffsetX or 0, db and db.friendlyOffsetY or 0, items, "TOPRIGHT", "TOPRIGHT", direction)
end

local function ShowPlayerTest()
    RefreshDB()
    if not (db and db.playerTestMode) then
        local overlay = overlays.player_test
        if overlay then
            overlay:Hide()
        end
        return
    end
    local anchor, point, relativePoint = GetPlayerAnchorFromSetting()
    local overlay = EnsureOverlay("player_test")
    local now = GetTime()
    local items = {
        {
            category = "stun",
            stage = "1/2",
            icon = "Interface\\Icons\\Ability_Rogue_Sap",
            bgColor = { 0, 1, 0, 0.35 },
            active = false,
            resetAt = now + DR_RESET_TIME,
        },
    }
    local direction = db and db.playerDirection or (db and db.friendlyDirection or "left")
    RenderOverlay(overlay, anchor, db and db.friendlyPlayerOffsetX or 0, db and db.friendlyPlayerOffsetY or 0, items, point, relativePoint, direction)
    -- Force a layout tick so the icon shows even if the overlay was hidden before.
    overlay:Show()
end

function Friendly.ApplySettings()
    RefreshDB()
    ShowFriendlyTest()
    ShowPlayerTest()
end

local function RegisterEvents()
    if eventFrame then
        return
    end
    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterUnitEvent("UNIT_AURA", "player", "party1", "party2", "party3", "party4",
        "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8",
        "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16",
        "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24",
        "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32",
        "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:SetScript("OnEvent", function(_, event, arg1)
        if not enabled then
            return
        end
        if event == "UNIT_AURA" then
            ProcessUnitAuras(arg1, "HARMFUL")
        elseif event == "GROUP_ROSTER_UPDATE" then
            ProcessUnitAuras("player", "HARMFUL")
            for i = 1, 4 do
                ProcessUnitAuras("party" .. i, "HARMFUL")
            end
            for i = 1, 40 do
                ProcessUnitAuras("raid" .. i, "HARMFUL")
            end
        end
    end)
end

function Friendly.SetEnabled(value)
    RefreshDB()
    value = not not value
    if value == enabled then
        return
    end
    enabled = value
    if enabled then
        if not EnsureDRList() then
            enabled = false
            return
        end
        RegisterEvents()
        if not pruneTicker and C_Timer and C_Timer.NewTicker then
            pruneTicker = C_Timer.NewTicker(0.5, PruneExpired)
        end
        Friendly.ApplySettings()
    else
        if pruneTicker then
            pruneTicker:Cancel()
            pruneTicker = nil
        end
        if wipe then
            wipe(states)
        else
            for key in pairs(states) do
                states[key] = nil
            end
        end
        ShowFriendlyTest()
        ShowPlayerTest()
    end
end

local function OnLoaded()
    db = type(_G.FreshDRsDB) == "table" and _G.FreshDRsDB or {}
    if db.friendlyTracking == nil then
        db.friendlyTracking = false
    end
    if db.friendlyPlayerAnchor == nil then
        db.friendlyPlayerAnchor = "player"
    end
    if db.friendlyDirection == nil then
        db.friendlyDirection = "left"
    end
    if db.friendlyNameFallback == nil then
        db.friendlyNameFallback = true
    end
    if db.playerDirection == nil then
        db.playerDirection = "left"
    end
    Friendly.SetEnabled(db.friendlyTracking and db.enabled ~= false)
end

OnLoaded()
