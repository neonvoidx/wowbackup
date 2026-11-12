local _, ns = ...

local DB = ns.TrackerDB
local ItemsData = ns.TrackerItemsData
local Affected = ns.API.Affected

local ItemVisuals = ns.TrackerItemVisuals or {}
ns.TrackerItemVisuals = ItemVisuals
local GCD_SPELL_ID = 61304

local FALLBACK_ICON = 134400
local ITEM_COOLDOWN_TRIGGER_THRESHOLD = 0.1
local WILDCARD_SLOT_TRINKET1 = ItemsData.WILDCARD_SLOT_TRINKET1 or "trinket1"
local WILDCARD_SLOT_TRINKET2 = ItemsData.WILDCARD_SLOT_TRINKET2 or "trinket2"

local activeStartByEntry = {}
local activeUntilByEntry = {}
local lastItemCooldownRemainingByEntry = {}
local itemCastEntriesBySpellID = {}
local itemCastCacheDirty = true

local desaturationCurve = C_CurveUtil.CreateCurve()
desaturationCurve:AddPoint(0, 0)
desaturationCurve:AddPoint(0.001, 1)

-- 1 at zero remaining (ready), 0 otherwise. Lets us turn a secret remaining-duration
-- into a glow alpha without comparing it.
local readyCurve = C_CurveUtil.CreateCurve()
readyCurve:AddPoint(0, 1)
readyCurve:AddPoint(0.001, 0)

local function BuildEntryKey(kind, id)
    if not kind or id == nil then
        return nil
    end
    return kind .. ":" .. tostring(id)
end

local RANGE_TINT = { 1, 0.1, 0.1 }
local MANA_TINT = { 0.5, 0.5, 1 }
local UNUSABLE_TINT = { 0.4, 0.4, 0.4 }

-- Mirrors Blizzard's action-button usable tinting: usable -> white, not enough
-- power -> blue, otherwise unusable -> grey. Range (when enabled) wins over the
-- resource states so an out-of-range cast still reads as red.
function ItemVisuals:ApplyUsabilityTint(frame)
    local Usability = ns.TrackerUsability
    local spellID = frame.spellID
    local tint
    local isOutOfRange = false
    if spellID then
        isOutOfRange = frame.rangeIndicator and Usability:IsOutOfRange(spellID) or false
        if isOutOfRange then
            tint = RANGE_TINT
        elseif frame.requireResource then
            if Usability:IsResourceInsufficient(spellID) then
                tint = MANA_TINT
            elseif Usability:IsNotUsable(spellID) then
                tint = UNUSABLE_TINT
            end
        end
    end
    if tint then
        frame.Icon:SetVertexColor(tint[1], tint[2], tint[3])
    else
        frame.Icon:SetVertexColor(1, 1, 1)
    end
    if frame.OutOfRange then
        frame.OutOfRange:SetShown(isOutOfRange)
    end
end

local itemStaticInfo = {}
local function GetItemStaticInfo(itemID)
    local info = itemStaticInfo[itemID]
    if info and info.spellID then
        return info
    end

    -- GetItemSpell may temporarily return nil while the item data is loading.
    -- Do not permanently cache that negative result: it makes an on-use item look
    -- spell-less, so the cooldown-edge fallback below can mistake its GCD for use.
    local classID = select(6, C_Item.GetItemInfoInstant(itemID))
    local _, spellID = C_Item.GetItemSpell(itemID)
    info = info or {}
    info.isConsumable = (classID == Enum.ItemClass.Consumable)
    if spellID and not info.spellID then
        info.spellID = spellID
        itemCastCacheDirty = true
    end
    itemStaticInfo[itemID] = info
    return info
end

local function GetCooldownSwipeColor()
    if not (ns.db and ns.db.profile and ns.db.profile.cooldownManager_customSwipeColor_enabled) then
        return {
            ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.r,
            ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.g,
            ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.b,
            ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.a,
        }
    end
    return {
        (ns.db and ns.db.profile and ns.db.profile.cooldownManager_customCDSwipeColor_r)
            or ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.r,
        (ns.db and ns.db.profile and ns.db.profile.cooldownManager_customCDSwipeColor_g)
            or ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.g,
        (ns.db and ns.db.profile and ns.db.profile.cooldownManager_customCDSwipeColor_b)
            or ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.b,
        (ns.db and ns.db.profile and ns.db.profile.cooldownManager_customCDSwipeColor_a)
            or ns.CONSTANTS.DEFAULT_COOLDOWN_SWIPE_COLOR.a,
    }
end

local function ApplyCustomActiveOverlay(frame, startTime, duration)
    if not frame or not frame.Cooldown or duration <= 0 or not startTime then
        return
    end

    local now = GetTime()
    if startTime < (now - duration) then
        return
    end

    frame.Cooldown:SetCooldown(startTime, duration)
    frame.Cooldown:SetDrawSwipe(true)

    if ns.db.profile.cooldownManager_customSwipeColor_enabled then
        frame.Cooldown:SetSwipeColor(
            ns.db.profile.cooldownManager_customActiveColor_r or ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.r,
            ns.db.profile.cooldownManager_customActiveColor_g or ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.g,
            ns.db.profile.cooldownManager_customActiveColor_b or ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.b,
            ns.db.profile.cooldownManager_customActiveColor_a or ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.a
        )
    else
        frame.Cooldown:SetSwipeColor(
            ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.r,
            ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.g,
            ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.b,
            ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR.a
        )
    end
end

function ItemVisuals:GetEntryIcon(kind, id)
    if kind == "wildcardSlots" and ItemsData and ItemsData.GetWildcardSlotItemID then
        local itemID = ItemsData:GetWildcardSlotItemID(id)
        if itemID then
            return C_Item.GetItemIconByID(itemID) or FALLBACK_ICON
        end
        return FALLBACK_ICON
    end
    if kind == "spell" then
        local displaySpellID = ItemsData:GetDisplaySpellID(id) or id
        return C_Spell.GetSpellTexture(displaySpellID) or FALLBACK_ICON
    end

    return C_Item.GetItemIconByID(id) or FALLBACK_ICON
end

function ItemVisuals:ApplyEntryIcon(frame, kind, id)
    if not frame or not frame.Icon then
        return
    end
    frame.Icon:SetTexture(self:GetEntryIcon(kind, id))
end

function ItemVisuals:SetEmptySlot(frame)
    if not frame then
        return
    end
    if frame.Icon then
        frame.Icon:SetTexture(nil)
        frame.Icon:SetAtlas("cdm-empty", true)
        frame.Icon:SetDesaturated(false)
    end
    if frame.Cooldown then
        CooldownFrame_Clear(frame.Cooldown)
    end
    ns.CooldownStyle:HideFrameGlow(frame)
end

function ItemVisuals:ClearCooldown(frame, desaturation)
    if not frame then
        return
    end
    if frame.Cooldown then
        CooldownFrame_Clear(frame.Cooldown)
        frame.Cooldown:SetDrawSwipe(false)
    end
    if desaturation ~= nil and frame.Icon then
        frame.Icon:SetDesaturation(desaturation)
    end
    ns.CooldownStyle:HideFrameGlow(frame)
end

function ItemVisuals:GetCustomActiveDuration(kind, id)
    return DB.GetCustomActiveDuration(kind, id) or 0
end

-- Active-overlay duration to use when no live aura is readable. Prefers the
-- user's manual custom time; if the entry opted into real-aura timing and has no
-- manual value, falls back to the curated on-use buff duration data.
function ItemVisuals:GetEffectiveActiveDuration(kind, id)
    -- A configured AuraSlot is the timing source. Keep any manual duration in the
    -- profile so clearing the aura restores it, but never run both sources at once.
    if DB.GetAuraSpellID and DB.GetAuraSpellID(kind, id) then
        return 0
    end
    -- Auto durations are the default. For entries we have curated data on, use it
    -- and ignore any old manual customActiveDuration. For entries with no data,
    -- fall back to the user's manual custom time (still offered in the menu).
    local AuraDurations = ns.TrackerAuraDurations
    if AuraDurations and AuraDurations.GetKnownDuration then
        local known = AuraDurations:GetKnownDuration(kind, id)
        if known and known > 0 then
            return known
        end
    end
    return self:GetCustomActiveDuration(kind, id)
end

function ItemVisuals:IsEntryActive(kind, id)
    local key = BuildEntryKey(kind, id)
    if not key then
        return false
    end

    local activeUntil = activeUntilByEntry[key] or 0
    if activeUntil <= GetTime() then
        activeUntilByEntry[key] = nil
        activeStartByEntry[key] = nil
        return false
    end

    return true
end

function ItemVisuals:SetEntryActiveNow(kind, id)
    local duration = self:GetEffectiveActiveDuration(kind, id)
    if duration <= 0 then
        return false
    end

    local key = BuildEntryKey(kind, id)
    if not key then
        return false
    end

    local now = GetTime()
    activeStartByEntry[key] = now
    activeUntilByEntry[key] = now + duration
    C_Timer.After(duration + 0.05, function()
        if ns.TrackerItemViewer and ns.TrackerItemViewer.RefreshItemViewerFrames then
            ns.TrackerItemViewer:RefreshItemViewerFrames()
        end
    end)

    return true
end

function ItemVisuals:MarkSpellCastActive(spellID)
    local matched = false
    if self:SetEntryActiveNow("spell", spellID) then
        matched = true
    end

    local baseSpellID = C_Spell.GetBaseSpell(spellID) or spellID
    if baseSpellID ~= spellID and self:SetEntryActiveNow("spell", baseSpellID) then
        matched = true
    end

    return matched
end

function ItemVisuals:InvalidateItemCastCache()
    itemCastCacheDirty = true
end

local function AddItemCastCandidate(spellID, itemID)
    if not spellID then
        return
    end
    local entries = itemCastEntriesBySpellID[spellID]
    if not entries then
        entries = {}
        itemCastEntriesBySpellID[spellID] = entries
    end
    entries[#entries + 1] = itemID
end

local function RebuildItemCastCache()
    wipe(itemCastEntriesBySpellID)
    local db = DB.GetDB and DB.GetDB() or nil
    local itemCandidates = {}

    if db and db.itemSettings then
        for itemID, settings in pairs(db.itemSettings) do
            if settings and settings.state then
                itemCandidates[itemID] = true
            end
        end
    end

    if ItemsData and ItemsData.GetWildcardSlotItemID and DB.GetWildcardSlotState then
        for _, slotID in ipairs({ WILDCARD_SLOT_TRINKET1, WILDCARD_SLOT_TRINKET2 }) do
            if DB.GetWildcardSlotState(slotID) ~= nil then
                local itemID = ItemsData:GetWildcardSlotItemID(slotID)
                if itemID then
                    itemCandidates[itemID] = true
                end
            end
        end
    end

    for itemID in pairs(itemCandidates) do
        if ItemVisuals:GetEffectiveActiveDuration("item", itemID) > 0 then
            local itemSpellID = GetItemStaticInfo(itemID).spellID
            if itemSpellID then
                local baseSpellID = C_Spell.GetBaseSpell(itemSpellID) or itemSpellID
                AddItemCastCandidate(baseSpellID, itemID)
            end
        end
    end
    itemCastCacheDirty = false
end

function ItemVisuals:MarkItemCastActive(spellID)
    if not spellID then
        return false
    end

    if itemCastCacheDirty then
        RebuildItemCastCache()
    end

    local baseSpellID = C_Spell.GetBaseSpell(spellID) or spellID
    local entries = itemCastEntriesBySpellID[baseSpellID]
    if not entries then
        return false
    end

    local matched = false
    for _, itemID in ipairs(entries) do
        if self:SetEntryActiveNow("item", itemID) then
            matched = true
        end
    end

    return matched
end

-- Drive the active overlay from the live aura's actual remaining duration. This
-- is the default now (no per-entry opt-in). Returns true when an aura was found
-- and applied.
function ItemVisuals:TryApplyLiveAura(frame, kind, id)
    if not frame or not frame.Cooldown then
        return false
    end
    if DB.GetAuraSpellID and DB.GetAuraSpellID(kind, id) then
        return false
    end
    local AuraDurations = ns.TrackerAuraDurations
    if not AuraDurations then
        return false
    end

    local startTime, duration, stacks = AuraDurations:GetLiveActive(kind, id)
    if not startTime then
        return false
    end

    if frame.count then
        frame.count:SetText((stacks and stacks > 1) and stacks or "")
    end
    if frame.Icon then
        frame.Icon:SetDesaturation(0)
    end
    ApplyCustomActiveOverlay(frame, startTime, duration)
    return true
end

-- Returns hasReadyState, readyAlpha, hasCharges, chargeAlpha. The alphas are secret
-- duration values, so they're only ever fed to SetAlpha, never compared.
function ItemVisuals:UpdateSpellCooldown(frame, spellID)
    if not frame or not frame.Cooldown then
        return
    end

    if self:TryApplyLiveAura(frame, "spell", spellID) then
        return false, nil, false, nil, true
    end

    local overrideSpellID = C_Spell.GetOverrideSpell(spellID) or spellID

    if self:IsEntryActive("spell", spellID) then
        local entryKey = BuildEntryKey("spell", spellID)
        local duration = self:GetEffectiveActiveDuration("spell", spellID)
        local startTime = entryKey and activeStartByEntry[entryKey] or nil
        frame.count:SetText("")
        frame.Icon:SetDesaturation(0)
        ApplyCustomActiveOverlay(frame, startTime, duration)
        return false, nil, false, nil, true
    end

    frame.Cooldown:SetSwipeColor(unpack(GetCooldownSwipeColor(), 1, 4))

    local spellCharges = C_Spell.GetSpellCharges(overrideSpellID)
    local hasCharges = spellCharges and spellCharges.maxCharges > 1
    if hasCharges then
        frame.count:SetText(spellCharges.currentCharges)
    else
        frame.count:SetText(C_StringUtil.TruncateWhenZero(C_Spell.GetSpellCastCount(overrideSpellID)))
    end

    local spellCooldownInfo = C_Spell.GetSpellCooldown(overrideSpellID)
    local isOnGCD = spellCooldownInfo and spellCooldownInfo.isOnGCD

    local cooldownDuration = C_Spell.GetSpellCooldownDuration(overrideSpellID)
    local chargeDuration
    if hasCharges then
        chargeDuration = C_Spell.GetSpellChargeDuration(overrideSpellID)
        frame.Cooldown:SetCooldownFromDurationObject(chargeDuration)
    elseif frame.showGCD or not isOnGCD then
        frame.Cooldown:SetCooldownFromDurationObject(cooldownDuration)
        frame.Cooldown:SetDrawSwipe(true)
    else
        frame.Cooldown:Clear()
    end

    local readyAlpha
    if isOnGCD then
        frame.Icon:SetDesaturation(0)
        readyAlpha = 1
    else
        frame.Icon:SetDesaturation(cooldownDuration:EvaluateRemainingDuration(desaturationCurve))
        readyAlpha = cooldownDuration:EvaluateRemainingDuration(readyCurve)
    end

    local _, notEnoughPower = C_Spell.IsSpellUsable(overrideSpellID)
    if notEnoughPower then
        readyAlpha = 0
    end

    local chargeAlpha
    if hasCharges then
        chargeAlpha = chargeDuration:EvaluateRemainingDuration(readyCurve)
    end

    return true, readyAlpha, hasCharges, chargeAlpha
end

function ItemVisuals:UpdateItemCooldown(frame, itemID)
    if not frame or not frame.Cooldown then
        return
    end

    if self:TryApplyLiveAura(frame, "item", itemID) then
        return false, nil, false, nil, true
    end

    local staticInfo = GetItemStaticInfo(itemID)
    local isConsumable = staticInfo.isConsumable

    local count = 0
    if isConsumable then
        count = C_Item.GetItemCount(itemID, false, true)
    end
    -- Consumable with no charges: always show as unusable regardless of cooldown
    local forceDesaturated = isConsumable and count == 0

    if count > 1 then
        frame.count:SetText(count)
    else
        frame.count:SetText("")
    end

    local startTime, duration, isCDEnabled = C_Item.GetItemCooldown(itemID)

    local spellID = staticInfo.spellID
    local customDuration = self:GetEffectiveActiveDuration("item", itemID)
    local hasCustomActive = customDuration > 0

    local cooldownRemaining = startTime + duration - GetTime()

    local gcd = C_Spell.GetSpellCooldown(GCD_SPELL_ID)
    local gcdRemaining = 0
    if gcd.startTime > 0 then
        gcdRemaining = gcd.startTime + gcd.duration - GetTimePreciseSec() + 0.01
    end

    local entryKey = BuildEntryKey("item", itemID)
    local previousRemaining = entryKey and lastItemCooldownRemainingByEntry[entryKey] or nil
    if entryKey then
        lastItemCooldownRemainingByEntry[entryKey] = cooldownRemaining
    end

    if
        hasCustomActive
        and not spellID
        and previousRemaining ~= nil
        and cooldownRemaining > ITEM_COOLDOWN_TRIGGER_THRESHOLD
        and previousRemaining <= ITEM_COOLDOWN_TRIGGER_THRESHOLD
        and cooldownRemaining > gcdRemaining + ITEM_COOLDOWN_TRIGGER_THRESHOLD
    then
        self:SetEntryActiveNow("item", itemID)
    end

    if hasCustomActive and self:IsEntryActive("item", itemID) then
        local entryKey = BuildEntryKey("item", itemID)
        local startTime = entryKey and activeStartByEntry[entryKey] or nil
        frame.Icon:SetDesaturation(forceDesaturated and 1 or 0)
        ApplyCustomActiveOverlay(frame, startTime, customDuration)
        return false, nil, false, nil, true
    end

    frame.Cooldown:SetSwipeColor(unpack(GetCooldownSwipeColor(), 1, 4))

    local isOnGCD = spellID and C_Spell.GetSpellCooldown(spellID).isOnGCD
    -- The GCD isn't a real cooldown, so the item still counts as ready under it.

    local isReady = not forceDesaturated and (cooldownRemaining <= gcdRemaining)

    local isWithingGCDRange
    if isCDEnabled and (not isOnGCD or frame.showGCD or cooldownRemaining > gcdRemaining) then
        frame.Cooldown:SetCooldown(startTime, duration)
        frame.Cooldown:SetDrawSwipe(true)
        -- Desaturate only while the long cooldown is clearly active; clear when ≤2s or expired
        if cooldownRemaining <= gcdRemaining or cooldownRemaining <= 1 then
            frame.Icon:SetDesaturation(forceDesaturated and 1 or 0)
        elseif forceDesaturated or cooldownRemaining > 2 then
            frame.Icon:SetDesaturation(1)
        end

        return true, isReady and 1 or 0, false, nil
    end
    if not isCDEnabled and cooldownRemaining > 0 and cooldownRemaining <= 0.1 then
        -- healthstone?
        frame.Cooldown:Clear()
        frame.Icon:SetDesaturation(1)
    elseif not isCDEnabled then
        frame.Cooldown:Clear()
        frame.Icon:SetDesaturation(forceDesaturated and 1 or 0)
    end

    return true, isReady and 1 or 0, false, nil
end

local function IsSpellProcGlowActive(spellID)
    local numericSpellID = tonumber(spellID)
    if not numericSpellID or not C_SpellActivationOverlay or not C_SpellActivationOverlay.IsSpellOverlayed then
        return false
    end

    local candidates = { numericSpellID }
    local overrideSpellID = tonumber(C_Spell.GetOverrideSpell(numericSpellID))
    if overrideSpellID and overrideSpellID ~= numericSpellID then
        candidates[#candidates + 1] = overrideSpellID
    end
    local baseSpellID = tonumber(C_Spell.GetBaseSpell(numericSpellID))
    if baseSpellID and baseSpellID ~= numericSpellID and baseSpellID ~= overrideSpellID then
        candidates[#candidates + 1] = baseSpellID
    end

    for _, candidateID in ipairs(candidates) do
        if C_SpellActivationOverlay.IsSpellOverlayed(candidateID) then
            return true
        end
    end
    return false
end

function ItemVisuals:ApplyEntryGlow(frame, kind, id, hasReadyState, readyAlpha, hasCharges, chargeAlpha, auraActive)
    local glow, alpha = false, nil
    local procActive = kind == "spell" and DB.GetProcGlowEnabled(id) and IsSpellProcGlowActive(id)
    if procActive then
        glow = true
    elseif auraActive and DB.GetGlowFlag(kind, id, "glowWhenAuraActive") then
        glow = true
    elseif
        kind == "spell"
        and DB.GetGlowFlag(kind, id, "glowWhenSuggested")
        and ns.Assistant
        and ns.Assistant:IsSpellSuggested(id)
    then
        glow = true
    elseif hasCharges and DB.GetGlowFlag(kind, id, "glowOnFullCharges") then
        glow, alpha = true, chargeAlpha
    elseif hasReadyState and DB.GetGlowFlag(kind, id, "glowWhenReady") then
        glow, alpha = true, readyAlpha
    end

    if glow then
        if procActive then
            ns.CooldownStyle:ShowFrameProcGlow(frame)
        else
            ns.CooldownStyle:ShowFrameGlow(frame, alpha)
        end
    else
        ns.CooldownStyle:HideFrameGlow(frame)
    end
end

function ItemVisuals:RefreshEntryUsabilityGlow(frame)
    local affected = Affected(frame)
    local kind, id = affected.resolvedTrackerEntryKind, affected.resolvedTrackerEntryId
    if kind ~= "spell" or not id then
        return
    end
    local glowWhenReady = DB.GetGlowFlag(kind, id, "glowWhenReady")
    local glowOnFullCharges = DB.GetGlowFlag(kind, id, "glowOnFullCharges")
    if not glowWhenReady and not glowOnFullCharges then
        return
    end

    local overrideSpellID = C_Spell.GetOverrideSpell(id) or id
    local hasCharges, chargeAlpha = false, nil
    if glowOnFullCharges then
        local charges = C_Spell.GetSpellCharges(overrideSpellID)
        hasCharges = charges and charges.maxCharges > 1
        if hasCharges then
            chargeAlpha = C_Spell.GetSpellChargeDuration(overrideSpellID):EvaluateRemainingDuration(readyCurve)
        end
    end

    local readyAlpha = affected.trackerReadyAlpha
    if glowWhenReady then
        local _, notEnoughPower = C_Spell.IsSpellUsable(overrideSpellID)
        local cooldown = C_Spell.GetSpellCooldown(overrideSpellID)
        readyAlpha = notEnoughPower and 0 or (cooldown and (cooldown.isOnGCD or not cooldown.isActive) and 1 or 0)
    end
    self:ApplyEntryGlow(frame, kind, id, glowWhenReady, readyAlpha, hasCharges, chargeAlpha, affected.trackerAuraActive)
end

function ItemVisuals:RefreshEntrySuggestedGlow(frame)
    local affected = Affected(frame)
    local kind, id = affected.resolvedTrackerEntryKind, affected.resolvedTrackerEntryId
    if not kind or not id or not DB.GetGlowFlag(kind, id, "glowWhenSuggested") then
        return
    end
    self:ApplyEntryGlow(
        frame,
        kind,
        id,
        affected.trackerHasReadyState,
        affected.trackerReadyAlpha,
        affected.trackerHasCharges,
        affected.trackerChargeAlpha,
        affected.trackerAuraActive
    )
end

function ItemVisuals:ApplyEntryStackColor(frame, kind, id)
    local count = frame and frame.count
    if not count then
        return
    end
    local affected = Affected(count)
    local color = kind and id and DB.GetEntryColor(kind, id, "stackColor") or nil
    if color then
        if not affected.entryColorOriginal then
            affected.entryColorOriginal = { count:GetTextColor() }
        end
        count:SetTextColor(color[1], color[2], color[3], 1)
    elseif affected.entryColorOriginal then
        count:SetTextColor(unpack(affected.entryColorOriginal))
        affected.entryColorOriginal = nil
    end
end

function ItemVisuals:UpdateEntryCooldown(frame, kind, id)
    local hasReadyState, readyAlpha, hasCharges, chargeAlpha, auraActive

    local auraKind, auraID = kind, id
    if kind == "wildcardSlots" and ItemsData and ItemsData.GetWildcardSlotItemID then
        auraKind, auraID = "item", ItemsData:GetWildcardSlotItemID(id)
    end
    Affected(frame).resolvedTrackerEntryKind = auraKind
    Affected(frame).resolvedTrackerEntryId = auraID
    self:ApplyEntryStackColor(frame, auraKind, auraID)
    local auraSpellID = auraID and DB.GetAuraSpellID and DB.GetAuraSpellID(auraKind, auraID) or nil
    if ns.AuraTracking then
        local activeColor = ns.CONSTANTS.DEFAULT_ACTIVE_SWIPE_COLOR
        local activeR, activeG, activeB, activeA = activeColor.r, activeColor.g, activeColor.b, activeColor.a
        if ns.db.profile.cooldownManager_customSwipeColor_enabled then
            activeR = ns.db.profile.cooldownManager_customActiveColor_r or activeR
            activeG = ns.db.profile.cooldownManager_customActiveColor_g or activeG
            activeB = ns.db.profile.cooldownManager_customActiveColor_b or activeB
            activeA = ns.db.profile.cooldownManager_customActiveColor_a or activeA
        end
        ns.AuraTracking:Attach(frame, auraSpellID, {
            anchor = frame.Cooldown,
            reverse = false,
            r = activeR,
            g = activeG,
            b = activeB,
            a = activeA,
            swipeTexture = ns.API:GetIsAffected(frame, "squareStyle")
                    and "Interface\\AddOns\\CooldownManagerCentered\\Media\\Art\\Square"
                or "Interface\\AddOns\\CooldownManagerCentered\\Media\\Art\\CooldownManager",
            stackColor = auraID and DB.GetEntryColor(auraKind, auraID, "stackColor") or nil,
            glowWhenActive = auraID and DB.GetGlowFlag(auraKind, auraID, "glowWhenAuraActive") or false,
        })
    end

    if kind == "wildcardSlots" and ItemsData and ItemsData.GetWildcardSlotItemID then
        local itemID = ItemsData:GetWildcardSlotItemID(id)
        if not itemID then
            if frame.count then
                frame.count:SetText("")
            end
            if frame.Cooldown then
                CooldownFrame_Clear(frame.Cooldown)
                frame.Cooldown:SetDrawSwipe(false)
            end
            if frame.Icon then
                frame.Icon:SetDesaturation(0)
            end
        else
            hasReadyState, readyAlpha, hasCharges, chargeAlpha, auraActive = self:UpdateItemCooldown(frame, itemID)
        end
    elseif kind == "spell" then
        hasReadyState, readyAlpha, hasCharges, chargeAlpha, auraActive = self:UpdateSpellCooldown(frame, id)
    else
        local entryKey = BuildEntryKey(kind, id)
        if entryKey and kind ~= "item" then
            lastItemCooldownRemainingByEntry[entryKey] = nil
        end
        hasReadyState, readyAlpha, hasCharges, chargeAlpha, auraActive = self:UpdateItemCooldown(frame, id)
    end

    local affected = Affected(frame)
    affected.trackerHasReadyState = hasReadyState
    affected.trackerReadyAlpha = readyAlpha
    affected.trackerHasCharges = hasCharges
    affected.trackerChargeAlpha = chargeAlpha
    affected.trackerAuraActive = auraActive
    self:ApplyEntryGlow(frame, auraKind, auraID, hasReadyState, readyAlpha, hasCharges, chargeAlpha, auraActive)
    self:ApplyUsabilityTint(frame)
    return true
end
