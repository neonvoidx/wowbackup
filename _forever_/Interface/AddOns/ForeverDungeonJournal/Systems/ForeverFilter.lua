-- WoW Forever emblem at the top left of the home page: click it to show only the
-- dungeons that are new in WoW Forever, click again to show every dungeon.
local FDJ = _G.ForeverDungeonJournal_NS
if not FDJ then return end

local ICON = "Interface\\AddOns\\ForeverDungeonJournal\\Media\\ForeverIcon"

-- Dungeons added by WoW Forever (not in the original Classic game).
FDJ.FOREVER_DUNGEONS = {
    ["Hall of Thanes"] = true,
    ["Ruins of Lordaeron"] = true,
    ["Excavation Site: Wetlands"] = true,
    ["City of Dalaran"] = true,
    ["The Drowned City"] = true,
    ["Krol'dok Stronghold"] = true,
    ["Alcaz Prison"] = true,
    ["Blackmaw Hold"] = true,
    ["Shaper's Terrace"] = true,
}

local function L(key, ...)
    if FDJ.L then return FDJ.L(key, ...) end
    return key
end

local function Active()
    return ForeverDungeonJournalDB and ForeverDungeonJournalDB.foreverOnly and true or false
end

-- The emblem and the "Forever Dungeons Only" option (Systems/SettingsPanel.lua)
-- are the same switch: either one turns it on and off.
function FDJ.IsForeverOnly()
    return Active()
end

function FDJ.SetForeverOnly(on)
    ForeverDungeonJournalDB = ForeverDungeonJournalDB or {}
    ForeverDungeonJournalDB.foreverOnly = on and true or nil
    if FDJ.RefreshSettingsChecks then pcall(FDJ.RefreshSettingsChecks) end
end

-- Asked by the home list for every dungeon.
function FDJ.HomeFilterHides(dungeonName)
    return Active() and not FDJ.FOREVER_DUNGEONS[dungeonName]
end

local function Paint(btn)
    local on = Active()
    btn.icon:SetAlpha(1)
    -- Always a soft golden glow (same as the LFG / Show Location buttons) so
    -- it reads as clickable; brighter with a gold ring while the filter is on.
    btn.halo:SetAlpha(on and 1 or 0.75)
    local w = btn:GetWidth() or 26
    if w < 1 then w = 26 end
    local halo = math.floor(w * (on and 2.15 or 1.92) + 0.5)
    btn.halo:SetSize(halo, halo)
    btn.glow:SetSize(math.floor(w * 1.92 + 0.5), math.floor(w * 1.92 + 0.5))
    btn.glow:SetShown(on)
end

-- The first time ever the emblem is clicked (the list now shows only WoW
-- Forever dungeons), a note with a red arrow, fading in and out like the
-- Group Browser one, points at the emblem from its left: Switch back to full
-- view. It goes away once the full list is back (or the page is left).
local HINT = {
    enUS = "Switch back to full view", deDE = "Zurück zur vollen Ansicht",
    frFR = "Revenir à la vue complète", esES = "Volver a la vista completa", esMX = "Volver a la vista completa",
    itIT = "Torna alla vista completa", ptBR = "Voltar à visão completa",
    ruRU = "Вернуться к полному списку", koKR = "전체 보기로 돌아가기",
    zhCN = "切换回完整视图", zhTW = "切換回完整檢視",
}
local function ShowFullViewHint(btn)
    ForeverDungeonJournalDB = ForeverDungeonJournalDB or {}
    if ForeverDungeonJournalDB.foreverHintShown then return end
    ForeverDungeonJournalDB.foreverHintShown = true
    local h = FDJ.foreverHint
    if not h then
        h = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        FDJ.foreverHint = h
        h:SetFrameStrata("FULLSCREEN_DIALOG")
        h:SetSize(240, 32)
        h:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        h:SetBackdropColor(0, 0, 0, 0.92)
        h:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        h.arrow = h:CreateTexture(nil, "OVERLAY")
        h.arrow:SetTexture("Interface\\AddOns\\ForeverDungeonJournal\\Media\\QuestNextArrow")
        h.arrow:SetVertexColor(1, 0.12, 0.08)
        h.arrow:SetSize(24, 24)
        h.arrow:SetPoint("RIGHT", -6, 0)
        h.text = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        h.text:SetPoint("RIGHT", h.arrow, "LEFT", -6, 0)
        h.text:SetTextColor(1, 1, 1)
        h.text:SetShadowColor(0, 0, 0, 1)
        h.text:SetShadowOffset(1, -1)
        h:SetScript("OnUpdate", function(self, elapsed)
            self.t = (self.t or 0) + elapsed
            -- Fade in and out, and nudge the arrow toward the emblem.
            self:SetAlpha(0.55 + 0.45 * math.sin(self.t * 4))
            self.arrow:SetPoint("RIGHT", -6 + 3 * math.abs(math.sin(self.t * 4)), 0)
            if not Active() or not (self.fdjTarget and self.fdjTarget:IsVisible()) then self:Hide() end
        end)
    end
    local lang = FDJ.GetLanguage and FDJ.GetLanguage() or "enUS"
    h.text:SetText(HINT[lang] or HINT.enUS)
    h:SetWidth((h.text:GetStringWidth() or 180) + 50)
    h:ClearAllPoints()
    h:SetPoint("RIGHT", btn, "LEFT", -8, 0)
    h.fdjTarget = btn
    h.t = 0
    h:Show()
end

local function Build(frame)
    local home = frame.homePanel
    local btn = CreateFrame("Button", nil, home)
    btn:SetSize(26, 26)
    btn:SetFrameLevel(home:GetFrameLevel() + 5)

    local halo = btn:CreateTexture(nil, "BACKGROUND", nil, -1)
    halo:SetTexture("Interface\\AddOns\\ForeverDungeonJournal\\Media\\TickGlow")
    halo:SetBlendMode("ADD")
    halo:SetVertexColor(1, 0.82, 0.35)
    halo:SetPoint("CENTER")
    btn.halo = halo

    local glow = btn:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(1, 0.82, 0.3, 0.95)
    glow:SetPoint("CENTER")
    glow:SetSize(50, 50)
    btn.glow = glow

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON)
    icon:SetAllPoints()
    btn.icon = icon

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture(ICON)
    hl:SetAllPoints()
    hl:SetBlendMode("ADD")
    hl:SetAlpha(0.35)

    btn:SetScript("OnMouseDown", function() icon:SetPoint("TOPLEFT", 1, -1); icon:SetPoint("BOTTOMRIGHT", 1, -1) end)
    btn:SetScript("OnMouseUp", function() icon:ClearAllPoints(); icon:SetAllPoints() end)
    btn:SetScript("OnClick", function(self)
        FDJ.SetForeverOnly(not Active())
        if PlaySound and SOUNDKIT then pcall(PlaySound, SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
        Paint(self)
        if FDJ.RefreshHomeCards then FDJ.RefreshHomeCards() end
        if Active() then ShowFullViewHint(self) end
        if self:IsMouseOver() and self:GetScript("OnEnter") then self:GetScript("OnEnter")(self) end
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L("FOREVER_FILTER_TITLE"), 1, 0.82, 0)
        GameTooltip:AddLine(Active() and L("FOREVER_FILTER_ON") or L("FOREVER_FILTER_TIP"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.foreverFilterButton = btn
    return btn
end

-- Raids medallion next to the Forever emblem: greyed out until raids are added.
local RAID_ICON = "Interface\\AddOns\\ForeverDungeonJournal\\Media\\RaidExpansionIcon"
local function BuildRaid(frame)
    local home = frame.homePanel
    local btn = CreateFrame("Button", nil, home)
    btn:SetSize(40, 40)
    btn:SetFrameLevel(home:GetFrameLevel() + 5)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(RAID_ICON)
    icon:SetAllPoints()
    icon:SetDesaturated(true)
    icon:SetAlpha(0.45)
    btn.icon = icon
    btn:SetScript("OnEnter", function(self)
        icon:SetAlpha(0.6)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L("RAIDS_TITLE"), 1, 0.82, 0)
        GameTooltip:AddLine(L("COMING_SOON"), 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        icon:SetAlpha(0.45)
        GameTooltip:Hide()
    end)
    frame.foreverRaidButton = btn
    return btn
end

local function PlaceRaid(frame, emblem, size)
    local btn = frame.foreverRaidButton or BuildRaid(frame)
    btn:SetSize(size, size)
    btn:ClearAllPoints()
    btn:SetPoint("LEFT", emblem, "RIGHT", size >= 40 and 12 or (size >= 30 and 10 or 8), 0)
    btn:Show()
end

local function Place(frame)
    local home = frame and frame.homePanel
    if not home then return end
    local btn = frame.foreverFilterButton or Build(frame)
    btn:ClearAllPoints()
    local rpg = FDJ.IsRPGMode and FDJ.IsRPGMode()
    local emblemSize = 40
    if rpg and frame.rpgBar and frame.rpgBar:IsShown() then
        -- RPG Mode: sits above the left end of the progress bar. The bar is
        -- under the header's row of buttons (RPG Mode, Favourites...), so the
        -- emblem lines up with them.
        frame.rpgBar:ClearAllPoints()
        frame.rpgBar:SetPoint("TOPLEFT", home, "TOPLEFT", 26, -(FDJ.RPG_BAR_Y or 37))
        -- rpgicons (1.9.8): 32, was 22 (too small).
        btn:SetSize(32, 32)
        emblemSize = 32
        btn:SetPoint("BOTTOMLEFT", frame.rpgBar, "TOPLEFT", 2, 2)
    else
        -- Gamer Mode: no "Browse Dungeons" heading; the emblem sits alone at the
        -- left of the header row, level with the Favourites / Loot Filter buttons
        -- (same layout as the TBC journal's round expansion icons).
        if frame.homeTitle then frame.homeTitle:Hide() end
        if frame.homeSubtitle then frame.homeSubtitle:Hide() end
        btn:SetSize(40, 40)
        btn:SetPoint("TOPLEFT", home, "TOPLEFT", 22, -10)
    end
    Paint(btn)
    btn:Show()
    PlaceRaid(frame, btn, emblemSize)
    -- The Cozy Sleeping Bag's medallion, right of the Raids one (Systems/QuestText.lua).
    if FDJ.PlaceSleepingBagButton and frame.foreverRaidButton then
        pcall(FDJ.PlaceSleepingBagButton, frame, frame.foreverRaidButton, emblemSize)
    end
end

-- The home list calls UpdateRPGHeader after every refresh; place the emblem
-- there too so it follows the title (Gamer Mode) or the bar (RPG Mode).
local orig = FDJ.UpdateRPGHeader
FDJ.UpdateRPGHeader = function(frame, ...)
    if orig then pcall(orig, frame, ...) end
    pcall(Place, frame)
end
