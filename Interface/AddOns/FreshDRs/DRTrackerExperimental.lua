local ADDON_NAME = ...

local DRTracker = {}
_G.NameplateDRs_Experimental = DRTracker

local DEFAULT_CHAT_FRAME = _G.DEFAULT_CHAT_FRAME
local CreateFrame = _G.CreateFrame
local C_Timer = _G.C_Timer
local GetTime = _G.GetTime
local C_Spell = _G.C_Spell
local GetSpellInfo = _G.GetSpellInfo
local LibStub = _G.LibStub
local UnitGUID = _G.UnitGUID
local wipe = _G.wipe
local issecretvalue = _G.issecretvalue

local db
local enabled = false
local DRList

local states = {}
local overlays = {}
local eventFrame
local pruneTicker
local nameToCategory

local maxAuras = 40
local DR_RESET_TIME = 16
local ICON_SIZE = 48
local ICON_SPACING = 2
local TIMER_UPDATE_RATE = 0.1

local function RefreshDB()
    if type(_G.FreshDRsDB) == "table" then
        db = _G.FreshDRsDB
    end
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

local function IsSecret(value)
    if type(issecretvalue) ~= "function" then
        return false
    end
    local ok, secret = pcall(issecretvalue, value)
    return ok and secret == true
end

local function SafeIsCrowdControl(spellId)
    if not spellId then
        return false
    end
    local ok, result = pcall(C_Spell.IsSpellCrowdControl, spellId)
    if not ok then
        return false
    end
    local okBool, isCC = pcall(function()
        return result == true
    end)
    if okBool then
        return isCC
    end
    return false
end

local function SafeGetSpellName(spellId)
    if not spellId then
        return nil
    end
    if C_Spell and C_Spell.GetSpellName then
        local ok, name = pcall(C_Spell.GetSpellName, spellId)
        if ok then
            return name
        end
    end
    if GetSpellInfo then
        local ok, name = pcall(GetSpellInfo, spellId)
        if ok then
            return name
        end
    end
    return nil
end

local function BuildNameMap()
    if nameToCategory then
        return
    end
    nameToCategory = {}
    local nameCounts = {}
    local spells = DRList and DRList.GetSpells and DRList:GetSpells() or nil
    if type(spells) ~= "table" then
        return
    end
    for spellId, category in pairs(spells) do
        local name = SafeGetSpellName(spellId)
        if name then
            if type(category) == "table" then
                category = category[1]
            end
            if category then
                nameCounts[name] = (nameCounts[name] or 0) + 1
                nameToCategory[name] = category
            end
        end
    end
    for name, count in pairs(nameCounts) do
        if count > 1 then
            nameToCategory[name] = nil
        end
    end
end

local function GetCategoryByName(name)
    if not name then
        return nil
    end
    BuildNameMap()
    return nameToCategory and nameToCategory[name] or nil
end

local function Debug(msg)
    if db and (db.debug or db.experimentalTracking) and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("Nameplate DRs: " .. msg)
    end
end

local function IsCategoryVisible(category)
    if type(_G.FreshDRs_IsCategoryVisible) == "function" then
        local ok, visible = pcall(_G.FreshDRs_IsCategoryVisible, category)
        if ok then
            return visible ~= false
        end
    end
    return true
end

local function GetIconSpacing()
    if type(_G.FreshDRs_GetIconSpacing) == "function" then
        local ok, spacing = pcall(_G.FreshDRs_GetIconSpacing)
        if ok and type(spacing) == "number" then
            return spacing
        end
    end
    return ICON_SPACING
end

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

local function GetUnitLabel(guid, fallback)
    return fallback or guid
end

local function GetStateForGuid(guid)
    if type(guid) ~= "string" then
        return nil
    end
    local ok, value = pcall(function()
        return states[guid]
    end)
    if ok then
        return value
    end
    return nil
end

local function SetStateForGuid(guid, value)
    if type(guid) ~= "string" then
        return false
    end
    local ok = pcall(function()
        states[guid] = value
    end)
    return ok
end

local function ResetState(state, now)
    if not state then
        return
    end
    if state.resetAt and now > state.resetAt then
        state.count = 0
        state.active = false
    end
end

local function FormatStage(count, category)
    if not DRList then
        return tostring(count)
    end
    if count >= 2 then
        return "IMM"
    end
    if count == 1 then
        return "1/2"
    end
    return "full"
end

local function OnAuraApplied(unit, guid, category)
    local now = GetTime()
    local unitState = GetStateForGuid(guid)
    if not unitState then
        return
    end
    local catState = unitState[category]
    if not catState then
        catState = { count = 0, resetAt = 0, active = false }
        unitState[category] = catState
    end
    ResetState(catState, now)

    catState.count = math.min(catState.count + 1, 2)
    catState.active = true
    catState.resetAt = nil
    catState.lastSeen = now
    Debug(string.format("exp %s %s %s", GetUnitLabel(guid, unit), category, FormatStage(catState.count, category)))
end

local function OnAuraRemoved(unit, guid, category)
    local now = GetTime()
    local unitState = GetStateForGuid(guid)
    if not unitState then
        return
    end
    local catState = unitState[category]
    if not catState then
        catState = { count = 0, resetAt = 0, active = false }
        unitState[category] = catState
    end
    ResetState(catState, now)
    catState.active = false
    catState.resetAt = now + DR_RESET_TIME
    catState.lastSeen = now
    catState.expires = nil
    Debug(string.format("exp %s %s removed", GetUnitLabel(guid, unit), category))
end

local function ProcessUnitAuras(unit, filter)
    local okGuid, guid = pcall(UnitGUID, unit)
    if not okGuid then
        return
    end
    if not guid or IsSecret(guid) or type(guid) ~= "string" then
        return
    end
    local okGuidIndex = pcall(function()
        local _ = states[guid]
    end)
    if not okGuidIndex then
        return
    end
    if not EnsureDRList() then
        return
    end

    local now = GetTime()
    local unitState = GetStateForGuid(guid)
    if not unitState then
        unitState = {}
        if not SetStateForGuid(guid, unitState) then
            return
        end
    end
    unitState.unit = unit

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
        local name = nil
        if not spellId then
            name = SafeAuraValue(data, "name")
        end
        local auraInstanceID = SafeAuraValue(data, "auraInstanceID")
        local category = nil
        if spellId and SafeIsCrowdControl(spellId) then
            local okCategory, resolvedCategory = pcall(DRList.GetCategoryBySpellID, DRList, spellId)
            if okCategory then
                category = resolvedCategory
            end
        elseif name then
            category = GetCategoryByName(name)
        end
        if category then
            if IsSecret(category) then
                category = nil
            end
        end
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
                instanceForCategory[category] = auraInstanceID
            end
            if not applicationsForCategory[category] then
                applicationsForCategory[category] = SafeAuraValue(data, "applications")
            end
        elseif db and db.experimentalTracking and db.debug then
            if not spellId and not name then
                Debug("exp " .. unit .. " aura skipped (secret spellId/name)")
            end
        end
    end

    for category, catState in pairs(unitState) do
        if catState.active and not present[category] then
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
                Debug(string.format("exp %s %s %s", GetUnitLabel(guid, unit), category, FormatStage(catState.count, category)))
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

    DRTracker.UpdateOverlay(unit, guid, unitState, iconForCategory, durationForCategory, expiresForCategory)
end

local function EnsureOverlay(unit)
    local overlay = overlays[unit]
    if overlay then
        return overlay
    end
    overlay = CreateFrame("Frame", nil, UIParent)
    overlay.items = {}
    overlay.NPDRS_TimerElapsed = 0
    overlays[unit] = overlay
    return overlay
end

local function UpdateOverlayLayout(overlay, items)
    local count = #items
    if count == 0 then
        overlay:SetSize(1, 1)
        return
    end
    local spacing = GetIconSpacing()
    local width = (count * ICON_SIZE) + math.max(0, (count - 1) * spacing)
    overlay:SetSize(width, ICON_SIZE)
    for i = 1, count do
        local item = overlay.items[i]
        item:ClearAllPoints()
        if i == 1 then
            item:SetPoint("RIGHT", overlay, "RIGHT", 0, 0)
        else
            item:SetPoint("RIGHT", overlay.items[i - 1], "LEFT", -spacing, 0)
        end
    end
end

function DRTracker.UpdateOverlay(unit, guid, unitState, iconForCategory, durationForCategory, expiresForCategory)
    local overlay = EnsureOverlay(unit)
    local anchor = _G.NameplateDRs_GetAnchorForUnit and _G.NameplateDRs_GetAnchorForUnit(unit)
    if not anchor then
        overlay:Hide()
        return
    end
    local now = GetTime()

    overlay:ClearAllPoints()
    overlay:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", db and db.offsetX or 0, (db and db.offsetY or 4) - 85)
    overlay:SetScale(db and db.trayScale or 1)
    overlay:SetFrameStrata("HIGH")
    if anchor.GetFrameLevel then
        overlay:SetFrameLevel(anchor:GetFrameLevel() + 10)
    end

    local items = {}
    for category, catState in pairs(unitState) do
        if category ~= "unit" then
            if catState.resetAt and catState.resetAt > 0 and now > catState.resetAt then
                catState.count = 0
                catState.active = false
            end
        end
        if category ~= "unit" and (catState.active or (catState.resetAt and catState.resetAt > now)) then
            if IsCategoryVisible(category) then
            items[#items + 1] = {
                category = category,
                stage = FormatStage(catState.count, category),
                icon = iconForCategory[category] or catState.icon,
                active = catState.active,
                resetAt = catState.resetAt,
                duration = durationForCategory and durationForCategory[category] or nil,
                expires = expiresForCategory and expiresForCategory[category] or nil,
            }
            end
        end
    end
    table.sort(items, function(a, b)
        return tostring(a.category) < tostring(b.category)
    end)

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
            item.stageText = item.text
            if item.text.SetFont then
                item.text:SetFont("Fonts\\FRIZQT__.TTF", 7, "OUTLINE")
            end
            if item.timerText.SetFont then
                item.timerText:SetFont("Fonts\\FRIZQT__.TTF", 7, "OUTLINE")
            end
            overlay.items[i] = item
        end
        if items[i].icon then
            item.NPDRS_DefaultTexture = items[i].icon
            if _G.FreshDRs_ApplyIconVisual then
                _G.FreshDRs_ApplyIconVisual(item, items[i].category, item.NPDRS_DefaultTexture, (items[i].stage == "IMM"))
            else
                item.icon:SetTexture(item.NPDRS_DefaultTexture)
            end
            item.icon:Show()
        else
            item.icon:Hide()
        end
        item.NPDRS_CurrentStage = items[i].stage
        if not items[i].active and items[i].resetAt and items[i].resetAt > now then
            local start = items[i].resetAt - DR_RESET_TIME
            item.cooldown:SetCooldown(start, DR_RESET_TIME)
            item.cooldown:Show()
            local remaining = items[i].resetAt - now
            if _G.FreshDRs_ApplyTextStyle then
                _G.FreshDRs_ApplyTextStyle(item, items[i].stage, remaining, true)
            else
                item.timerText:SetText(string.format("%.0f", remaining))
            end
        else
            item.cooldown:SetCooldown(0, 0)
            item.cooldown:Hide()
            if _G.FreshDRs_ApplyTextStyle then
                _G.FreshDRs_ApplyTextStyle(item, items[i].stage, nil, false)
            else
                item.timerText:SetText("")
            end
        end
        if not _G.FreshDRs_ApplyTextStyle then
            item.text:SetText(items[i].stage == "full" and "" or items[i].stage)
            if items[i].stage == "1/2" then
                item.text:SetTextColor(0, 1, 0, 1)
            elseif items[i].stage == "IMM" then
                item.text:SetTextColor(1, 0, 0, 1)
            else
                item.text:SetTextColor(1, 1, 1, 1)
            end
        end
        item:Show()
    end

    for i = #items + 1, #overlay.items do
        overlay.items[i]:Hide()
    end

    UpdateOverlayLayout(overlay, items)
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
                    if _G.FreshDRs_ApplyTextStyle then
                        _G.FreshDRs_ApplyTextStyle(item, item.NPDRS_CurrentStage, remaining, true)
                    else
                        item.timerText:SetText(string.format("%.0f", remaining))
                    end
                else
                    if _G.FreshDRs_ApplyTextStyle then
                        _G.FreshDRs_ApplyTextStyle(item, item.NPDRS_CurrentStage, nil, false)
                    else
                        item.timerText:SetText("")
                    end
                end
            else
                if _G.FreshDRs_ApplyTextStyle then
                    _G.FreshDRs_ApplyTextStyle(item, item.NPDRS_CurrentStage, nil, false)
                else
                    item.timerText:SetText("")
                end
            end
        end
    end)
    for i, data in ipairs(items) do
        local item = overlay.items[i]
        item.resetAt = data.resetAt
    end
    overlay:Show()
end

local function ClearStates()
    if wipe then
        wipe(states)
    else
        for key in pairs(states) do
            states[key] = nil
        end
    end
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
            DRTracker.UpdateOverlay(unit, guid, unitState, {})
        end
    end
end

function DRTracker.SetEnabled(value)
    RefreshDB()
    value = not not value
    if value == enabled then
        return
    end
    enabled = value
    if enabled then
        if not EnsureDRList() then
            Debug("exp DRList-1.0 missing")
            enabled = false
            return
        end
        if not eventFrame then
            eventFrame = CreateFrame("Frame")
            eventFrame:RegisterUnitEvent("UNIT_AURA", "target", "focus", "mouseover", "arena1", "arena2", "arena3")
            eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
            eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
            eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
            eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
            eventFrame:SetScript("OnEvent", function(_, event, arg1)
                if not enabled then
                    return
                end
                if event == "UNIT_AURA" then
                    ProcessUnitAuras(arg1, "HARMFUL")
                elseif event == "PLAYER_TARGET_CHANGED" then
                    ProcessUnitAuras("target", "HARMFUL")
                elseif event == "PLAYER_FOCUS_CHANGED" then
                    ProcessUnitAuras("focus", "HARMFUL")
                elseif event == "UPDATE_MOUSEOVER_UNIT" then
                    ProcessUnitAuras("mouseover", "HARMFUL")
                elseif event == "ARENA_OPPONENT_UPDATE" then
                    ProcessUnitAuras("arena1", "HARMFUL")
                    ProcessUnitAuras("arena2", "HARMFUL")
                    ProcessUnitAuras("arena3", "HARMFUL")
                end
            end)
        end
        Debug("exp tracker enabled (unit auras)")
        if not pruneTicker and C_Timer and C_Timer.NewTicker then
            pruneTicker = C_Timer.NewTicker(0.5, PruneExpired)
        end
    else
        if pruneTicker then
            pruneTicker:Cancel()
            pruneTicker = nil
        end
        ClearStates()
        Debug("exp tracker disabled")
    end
end

local function OnLoaded()
    db = type(_G.FreshDRsDB) == "table" and _G.FreshDRsDB or {}
    if db.experimentalTracking == nil then
        db.experimentalTracking = false
    end
    DRTracker.SetEnabled(db.experimentalTracking and db.enabled ~= false)
end

OnLoaded()
