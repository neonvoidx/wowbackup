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
local UnitExists = _G.UnitExists
local wipe = _G.wipe

local db
local enabled = false
local DRList
local nameToCategory

local states = {}
local overlays = {}
local eventFrame
local pruneTicker
local pollTicker
local pollNextAt = 0

local DR_RESET_TIME = 16
local ICON_SIZE = 22
local ICON_SPACING = 2
local TIMER_UPDATE_RATE = 0.1
local ARENA_POLL_RATE = 0.10
local ROSTER_POLL_RATE = 0.40
local PLAYER_MISS_HOLD = 0.35

local TRACKED_CATEGORIES = {
    stun = true,
    incapacitate = true,
    incap = true,
    disorient = true,
    silence = true,
    disarm = true,
    root = true,
}

local LOC_FALLBACK = {
    STUN = "stun",
    STUN_MECHANIC = "stun",
    ROOT = "root",
    SILENCE = "silence",
    DISARM = "disarm",
    DISORIENT = "disorient",
    FEAR = "disorient",
    CHARM = "incap",
    CONFUSE = "incap",
    PACIFY = "incap",
    PACIFYSILENCE = "incap",
    POSSESS = "incap",
}

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

local function SafeSpellTexture(spellId)
    if not spellId then
        return nil
    end
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, texture = pcall(C_Spell.GetSpellTexture, spellId)
        if ok and texture then
            return texture
        end
    end
    if GetSpellInfo then
        local ok, _, _, icon = pcall(GetSpellInfo, spellId)
        if ok and icon then
            return icon
        end
    end
    return nil
end

local function NormalizeCategory(category)
    if type(category) == "table" then
        category = category[1]
    end
    if type(category) ~= "string" then
        return nil
    end
    category = string.lower(category)
    if category == "incapacitate" then
        category = "incap"
    end
    if TRACKED_CATEGORIES[category] then
        return category
    end
    return nil
end

local function IsInArenaMatch()
    local fn = _G.IsActiveBattlefieldArena
    if type(fn) ~= "function" then
        return false
    end
    local ok, inArena = pcall(fn)
    return ok and inArena == true
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
            local cat = NormalizeCategory(category)
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

local function SafeUnitExists(unit)
    if not unit or not UnitExists then
        return false
    end
    local ok, exists = pcall(UnitExists, unit)
    return ok and exists == true
end

local function GetStateForUnit(unit)
    if type(unit) ~= "string" then
        return nil
    end
    return states[unit]
end

local function GetOrCreateStateForUnit(unit)
    if type(unit) ~= "string" then
        return nil
    end
    local unitState = states[unit]
    if not unitState then
        unitState = {}
        states[unit] = unitState
    end
    unitState.unit = unit
    return unitState
end

local function IsLikelyNewInstance(oldState, candidate)
    if not (oldState and candidate) then
        return false
    end

    local prevStart = oldState.startTime
    local newStart = candidate.startTime
    if type(prevStart) == "number" and type(newStart) == "number" and newStart > (prevStart + 0.12) then
        return true
    end

    local prevSpell = oldState.spellID
    local newSpell = candidate.spellID
    if type(prevSpell) == "number" and type(newSpell) == "number" and newSpell ~= prevSpell then
        local prevEnd = oldState.endTime
        local newEnd = candidate.endTime
        if type(prevEnd) == "number" and type(newEnd) == "number" and newEnd >= (prevEnd - 0.05) then
            return true
        end
    end

    return false
end

local function GetEndTime(startTime, duration)
    if type(startTime) == "number" and type(duration) == "number" and duration > 0 then
        return startTime + duration
    end
    return nil
end

local function SafeGetCategory(spellId, auraName, locType)
    local category = nil

    if spellId and DRList and DRList.GetCategoryBySpellID then
        local ok, raw = pcall(DRList.GetCategoryBySpellID, DRList, spellId)
        if ok then
            category = NormalizeCategory(raw)
        end
    end

    if not category and type(locType) == "string" then
        category = NormalizeCategory(LOC_FALLBACK[locType])
    end

    if not category and auraName and EnsureNameMap() then
        category = NormalizeCategory(SafeLookupName(auraName))
    end

    return category
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
    -- Modern non-raid-style party frames.
    local partyFrame = _G.PartyFrame
    if partyFrame then
        for i = 1, 4 do
            local member = partyFrame["MemberFrame" .. i]
            if member and member:IsShown() then
                local token = member.unitToken or member.unit
                if token == unit then
                    return member
                end
            end
        end

        local pool = partyFrame.PartyMemberFramePool
        if pool and pool.EnumerateActive then
            for member in pool:EnumerateActive() do
                if member and member:IsShown() then
                    local token = member.unitToken or member.unit
                    if token == unit then
                        return member
                    end
                end
            end
        end
    end

    -- Raid-style party frame container.
    local compactParty = _G.CompactPartyFrame
    if compactParty and type(compactParty.memberUnitFrames) == "table" then
        for _, member in ipairs(compactParty.memberUnitFrames) do
            if member and member:IsShown() then
                local token = member.unitToken or member.unit
                if token == unit then
                    return member
                end
            end
        end
    end

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
    local spacing = GetIconSpacing()
    direction = direction or "left"
    local width = (count * ICON_SIZE) + math.max(0, (count - 1) * spacing)
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
                item:SetPoint("LEFT", overlay.items[i - 1], "RIGHT", spacing, 0)
            end
        elseif direction == "up" then
            if i == 1 then
                item:SetPoint("BOTTOM", overlay, "BOTTOM", 0, 0)
            else
                item:SetPoint("BOTTOM", overlay.items[i - 1], "TOP", 0, spacing)
            end
        elseif direction == "down" then
            if i == 1 then
                item:SetPoint("TOP", overlay, "TOP", 0, 0)
            else
                item:SetPoint("TOP", overlay.items[i - 1], "BOTTOM", 0, -spacing)
            end
        else
            if i == 1 then
                item:SetPoint("RIGHT", overlay, "RIGHT", 0, 0)
            else
                item:SetPoint("RIGHT", overlay.items[i - 1], "LEFT", -spacing, 0)
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

    local visibleItems = {}
    for i = 1, #items do
        local item = items[i]
        if item and IsCategoryVisible(item.category) then
            visibleItems[#visibleItems + 1] = item
        end
    end
    items = visibleItems

    local now = GetTime()
    overlay:ClearAllPoints()
    local anchorPoint = point or "TOPRIGHT"
    local relPoint = relativePoint or anchorPoint
    overlay:SetPoint(anchorPoint, anchor, relPoint, offsetX or 0, offsetY or 0)
    overlay:SetFrameStrata("HIGH")
    if anchor.GetFrameLevel then
        overlay:SetFrameLevel(anchor:GetFrameLevel() + 10)
    end

    local function ApplyStageVisual(item, stage)
        item.text:SetText(stage or "")
        if stage == "1/2" then
            item.text:SetTextColor(0, 1, 0, 1)
        elseif stage == "IMM" then
            item.text:SetTextColor(1, 0, 0, 1)
        else
            item.text:SetTextColor(1, 1, 1, 1)
        end
    end

    local function ApplyBGVisual(item, bgColor)
        if bgColor then
            item.bg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 0.35)
            item.bg:Show()
        else
            item.bg:Hide()
        end
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
            item.stageText = item.text
            if item.text.SetFont then
                item.text:SetFont("Fonts\\FRIZQT__.TTF", 7, "OUTLINE")
            end
            if item.timerText.SetFont then
                item.timerText:SetFont("Fonts\\FRIZQT__.TTF", 7, "OUTLINE")
            end
            overlay.items[i] = item
        end
        local iconTexture = items[i].icon or "Interface\\Icons\\INV_Misc_QuestionMark"
        item.NPDRS_DefaultTexture = iconTexture
        if _G.FreshDRs_ApplyIconVisual then
            _G.FreshDRs_ApplyIconVisual(item, items[i].category, item.NPDRS_DefaultTexture, (items[i].stage == "IMM"))
        else
            item.icon:SetTexture(item.NPDRS_DefaultTexture)
        end
        item.icon:SetVertexColor(1, 1, 1, 1)
        item.icon:SetAlpha(1)
        item.icon:SetDrawLayer("ARTWORK", 1)
        item.icon:Show()

        if not item.bg then
            item.bg = item:CreateTexture(nil, "BACKGROUND")
            item.bg:SetAllPoints(item)
        end
        item.NPDRS_TestLoop = items[i].testLoop == true
        item.NPDRS_TestToggle = items[i].testToggle == true
        item.NPDRS_CurrentStage = items[i].stage or ""
        ApplyBGVisual(item, items[i].bgColor)

        local resetAt = items[i].resetAt
        if item.NPDRS_TestLoop and (not resetAt or resetAt <= now) then
            resetAt = now + DR_RESET_TIME
        end
        local remaining = nil
        if not items[i].active and resetAt and resetAt > now then
            local start = resetAt - DR_RESET_TIME
            item.cooldown:SetCooldown(start, DR_RESET_TIME)
            item.cooldown:Show()
            item.resetAt = resetAt
            remaining = resetAt - now
        else
            item.cooldown:SetCooldown(0, 0)
            item.cooldown:Hide()
            item.resetAt = resetAt
        end
        if _G.FreshDRs_ApplyTextStyle then
            _G.FreshDRs_ApplyTextStyle(item, item.NPDRS_CurrentStage, remaining, remaining and remaining > 0)
        else
            ApplyStageVisual(item, item.NPDRS_CurrentStage)
            if remaining and remaining > 0 then
                item.timerText:SetText(string.format("%.0f", remaining))
            else
                item.timerText:SetText("")
            end
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
                    if _G.FreshDRs_ApplyTextStyle then
                        _G.FreshDRs_ApplyTextStyle(item, item.NPDRS_CurrentStage, remaining, true)
                    else
                        item.timerText:SetText(string.format("%.0f", remaining))
                    end
                else
                    if item.NPDRS_TestLoop then
                        item.resetAt = nowTime + DR_RESET_TIME
                        item.cooldown:SetCooldown(item.resetAt - DR_RESET_TIME, DR_RESET_TIME)
                        if item.NPDRS_TestToggle then
                            local nextStage = (item.NPDRS_CurrentStage == "IMM") and "1/2" or "IMM"
                            item.NPDRS_CurrentStage = nextStage
                            ApplyStageVisual(item, nextStage)
                            if nextStage == "IMM" then
                                ApplyBGVisual(item, { 0.8, 0.2, 0.2, 0.25 })
                            else
                                ApplyBGVisual(item, { 0, 1, 0, 0.25 })
                            end
                        end
                        if _G.FreshDRs_ApplyTextStyle then
                            _G.FreshDRs_ApplyTextStyle(item, item.NPDRS_CurrentStage, DR_RESET_TIME, true)
                        else
                            item.timerText:SetText(string.format("%.0f", DR_RESET_TIME))
                        end
                    else
                        if _G.FreshDRs_ApplyTextStyle then
                            _G.FreshDRs_ApplyTextStyle(item, item.NPDRS_CurrentStage, nil, false)
                        else
                            item.timerText:SetText("")
                        end
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
        if item and not item.NPDRS_TestLoop then
            item.resetAt = data.resetAt
        end
    end
    overlay:Show()
end

local function UpdateOverlay(unit, unitState, iconForCategory, durationForCategory, expiresForCategory)
    local overlayKey = unit
    local anchor, isPlayerSeparate, point, relativePoint = GetOverlayAnchor(unit)
    if isPlayerSeparate then
        overlayKey = "player_separate"
    end
    local overlay = EnsureOverlay(overlayKey)
    if not (db and db.friendlyPlayerSeparate) then
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

    if #items > 0 then
        overlay.NPDRS_LastNonEmpty = now
    else
        if overlayKey == "player_separate" then
            local lastSeen = overlay.NPDRS_LastNonEmpty or 0
            if (now - lastSeen) < PLAYER_MISS_HOLD then
                return
            end
        end
        overlay:Hide()
        return
    end

    local offsetX = isPlayerSeparate and (db and db.friendlyPlayerOffsetX or 0) or (db and db.friendlyOffsetX or 0)
    local offsetY = isPlayerSeparate and (db and db.friendlyPlayerOffsetY or 0) or (db and db.friendlyOffsetY or 0)
    local direction = db and db.friendlyDirection or "left"
    if isPlayerSeparate then
        direction = db and db.playerDirection or direction
    end
    RenderOverlay(overlay, anchor, offsetX, offsetY, items, point, relativePoint, direction)
end

local function CollectTrackedFriendlyUnits(out)
    out[#out + 1] = "player"
    for i = 1, 4 do
        out[#out + 1] = "party" .. i
    end
    for i = 1, 40 do
        out[#out + 1] = "raid" .. i
    end
end

local function ShouldHideGroupedPlayer(unit)
    if not (db and db.friendlyHidePlayerInGroup) then
        return false
    end
    if unit == "player" then
        return false
    end
    if UnitIsUnit then
        local okSame, same = pcall(UnitIsUnit, unit, "player")
        if okSame and same == true then
            return true
        end
    end
    return false
end

local function UpdateUnitFromLossOfControl(unit)
    if not (enabled and unit and EnsureDRList() and _G.C_LossOfControl and _G.C_LossOfControl.GetActiveLossOfControlDataByUnit) then
        return
    end
    if not SafeUnitExists(unit) then
        local overlay = overlays[unit]
        if overlay then
            overlay:Hide()
        end
        states[unit] = nil
        return
    end
    if ShouldHideGroupedPlayer(unit) then
        local overlay = overlays[unit]
        if overlay then
            overlay:Hide()
        end
        return
    end

    local now = GetTime()
    local unitState = GetOrCreateStateForUnit(unit)
    if not unitState then
        return
    end

    local seen = {}
    local activeCountByCategory = {}
    local bestByCategory = {}
    local iconForCategory = {}
    local durationForCategory = {}
    local expiresForCategory = {}

    for i = 1, 20 do
        local okData, data = pcall(_G.C_LossOfControl.GetActiveLossOfControlDataByUnit, unit, i)
        if not okData or not data then
            break
        end

        local spellID = SafeAuraValue(data, "spellID") or SafeAuraValue(data, "spellId")
        local locType = SafeAuraValue(data, "locType")
        local auraName = SafeAuraValue(data, "displayText") or SafeAuraValue(data, "text")
        local category = SafeGetCategory(spellID, auraName, locType)
        if category then
            seen[category] = true
            activeCountByCategory[category] = (activeCountByCategory[category] or 0) + 1

            local startTime = SafeAuraValue(data, "startTime")
            local duration = SafeAuraValue(data, "duration")
            local endTime = GetEndTime(startTime, duration)
            local icon = SafeSpellTexture(spellID) or SafeAuraValue(data, "iconTexture")

            local candidate = bestByCategory[category]
            if not candidate then
                bestByCategory[category] = {
                    spellID = spellID,
                    startTime = startTime,
                    duration = duration,
                    endTime = endTime,
                    icon = icon,
                }
            else
                local currentEnd = candidate.endTime
                local replace = false
                if type(endTime) == "number" then
                    if type(currentEnd) ~= "number" or endTime > currentEnd then
                        replace = true
                    end
                elseif type(currentEnd) ~= "number" and type(duration) == "number" and type(candidate.duration) ~= "number" then
                    replace = true
                end
                if replace then
                    candidate.spellID = spellID
                    candidate.startTime = startTime
                    candidate.duration = duration
                    candidate.endTime = endTime
                    candidate.icon = icon
                elseif not candidate.icon and icon then
                    candidate.icon = icon
                end
            end
        end
    end

    for category, candidate in pairs(bestByCategory) do
        local catState = unitState[category]
        if not catState then
            catState = { count = 0, active = false }
            unitState[category] = catState
        elseif catState.active and IsLikelyNewInstance(catState, candidate) then
            catState.count = math.min((catState.count or 0) + 1, 2)
            catState.resetAt = nil
        end

        catState.active = true
        catState.spellID = candidate.spellID
        catState.startTime = candidate.startTime
        catState.duration = candidate.duration
        catState.endTime = candidate.endTime
        if candidate.icon then
            catState.icon = candidate.icon
        end
        if candidate.icon then
            iconForCategory[category] = candidate.icon
        end
        durationForCategory[category] = candidate.duration
        expiresForCategory[category] = candidate.endTime
    end

    -- Fast-track to IMM when multiple control effects of same DR category overlap.
    for category, count in pairs(activeCountByCategory) do
        if count > 1 then
            local catState = unitState[category]
            if catState then
                catState.count = math.max(catState.count or 0, 1)
            end
        end
    end

    for category, catState in pairs(unitState) do
        if category ~= "unit" then
            if catState.active and not seen[category] then
                catState.active = false
                catState.count = math.min((catState.count or 0) + 1, 2)
                catState.resetAt = now + DR_RESET_TIME
                catState.startTime = nil
                catState.duration = nil
                catState.endTime = nil
            elseif not catState.active then
                if catState.resetAt and now >= catState.resetAt then
                    catState.count = 0
                    catState.resetAt = nil
                end
                if (catState.count or 0) <= 0 and not catState.resetAt and not catState.icon then
                    unitState[category] = nil
                end
            end
        end
    end

    UpdateOverlay(unit, unitState, iconForCategory, durationForCategory, expiresForCategory)
end

local function UpdateAllFriendlyUnits()
    local units = {}
    CollectTrackedFriendlyUnits(units)
    for i = 1, #units do
        UpdateUnitFromLossOfControl(units[i])
    end
end

local function PruneExpired()
    local now = GetTime()
    for unit, unitState in pairs(states) do
        local changed = false
        if not SafeUnitExists(unit) then
            states[unit] = nil
            local overlay = overlays[unit]
            if overlay then
                overlay:Hide()
            end
        else
            for category, catState in pairs(unitState) do
                if category ~= "unit" and not catState.active and catState.resetAt and now >= catState.resetAt then
                    catState.resetAt = nil
                    catState.count = 0
                    changed = true
                end
            end
            if changed then
                UpdateOverlay(unit, unitState, {}, {}, {})
            end
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
    local items
    if type(_G.FreshDRs_GetRandomTestItems) == "function" then
        local ok, generated = pcall(_G.FreshDRs_GetRandomTestItems, 3, now)
        if ok and type(generated) == "table" then
            items = {}
            for i = 1, #generated do
                local src = generated[i]
                items[i] = {
                    category = src.category,
                    stage = src.stage or "",
                    icon = src.icon,
                    bgColor = src.bgColor,
                    active = src.active == true,
                    resetAt = src.resetAt,
                    testLoop = true,
                    testToggle = (src.stage == "1/2" or src.stage == "IMM"),
                }
            end
        end
    end
    if not items then
        items = {
            {
                category = "stun",
                stage = "1/2",
                icon = "Interface\\Icons\\Ability_Rogue_Sap",
                bgColor = { 0, 1, 0, 0.25 },
                active = false,
                resetAt = now + DR_RESET_TIME,
                testLoop = true,
            },
            {
                category = "disorient",
                stage = "IMM",
                icon = "Interface\\Icons\\Spell_Shadow_MindSteal",
                bgColor = { 0, 1, 0, 0.25 },
                active = false,
                resetAt = now + (DR_RESET_TIME - 4),
                testLoop = true,
                testToggle = true,
            },
            {
                category = "silence",
                stage = "",
                icon = "Interface\\Icons\\Ability_Rogue_Garrote",
                bgColor = nil,
                active = true,
                resetAt = nil,
                testLoop = true,
            },
        }
    end
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
    local items
    if type(_G.FreshDRs_GetRandomTestItems) == "function" then
        local ok, generated = pcall(_G.FreshDRs_GetRandomTestItems, 3, now)
        if ok and type(generated) == "table" then
            items = {}
            for i = 1, #generated do
                local src = generated[i]
                local bgColor = src.bgColor
                if not bgColor then
                    bgColor = { 0, 1, 0, 0.35 }
                end
                items[i] = {
                    category = src.category,
                    stage = src.stage or "",
                    icon = src.icon,
                    bgColor = bgColor,
                    active = src.active == true,
                    resetAt = src.resetAt,
                    testLoop = true,
                    testToggle = (src.stage == "1/2" or src.stage == "IMM"),
                }
            end
        end
    end
    if not items then
        items = {
            {
                category = "stun",
                stage = "1/2",
                icon = "Interface\\Icons\\Ability_Rogue_Sap",
                bgColor = { 0, 1, 0, 0.35 },
                active = false,
                resetAt = now + DR_RESET_TIME,
                testLoop = true,
                testToggle = true,
            },
            {
                category = "disorient",
                stage = "IMM",
                icon = "Interface\\Icons\\Spell_Shadow_MindSteal",
                bgColor = { 0.8, 0.2, 0.2, 0.35 },
                active = false,
                resetAt = now + (DR_RESET_TIME - 4),
                testLoop = true,
                testToggle = true,
            },
            {
                category = "silence",
                stage = "",
                icon = "Interface\\Icons\\Ability_Rogue_Garrote",
                bgColor = { 0, 1, 0, 0.25 },
                active = true,
                resetAt = nil,
                testLoop = true,
            },
        }
    end
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
            UpdateUnitFromLossOfControl(arg1)
        elseif event == "GROUP_ROSTER_UPDATE" then
            UpdateAllFriendlyUnits()
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
        if not pollTicker and C_Timer and C_Timer.NewTicker then
            pollNextAt = 0
            pollTicker = C_Timer.NewTicker(ARENA_POLL_RATE, function()
                if not enabled then
                    return
                end
                local now = GetTime()
                if now < (pollNextAt or 0) then
                    return
                end
                UpdateAllFriendlyUnits()
                if IsInArenaMatch() then
                    pollNextAt = now + ARENA_POLL_RATE
                else
                    pollNextAt = now + ROSTER_POLL_RATE
                end
            end)
        end
        UpdateAllFriendlyUnits()
        Friendly.ApplySettings()
    else
        if pruneTicker then
            pruneTicker:Cancel()
            pruneTicker = nil
        end
        if pollTicker then
            pollTicker:Cancel()
            pollTicker = nil
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
    if db.playerDirection == nil then
        db.playerDirection = "left"
    end
    Friendly.SetEnabled(db.friendlyTracking and db.enabled ~= false)
end

OnLoaded()
