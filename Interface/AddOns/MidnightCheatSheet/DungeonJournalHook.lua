----------------------------------------------------------------------
-- MidnightCheatSheet – DungeonJournalHook.lua
-- Hooks Encounter Journal item buttons for Alt-click wishlisting.
-- Includes spec + list selector overlay.
----------------------------------------------------------------------
local _, MCS = ...

local format, tonumber = format, tonumber
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local IsAltKeyDown = IsAltKeyDown
local hooksecurefunc = hooksecurefunc
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT
local C_Timer = C_Timer

MCS.journalTargetSpecKey = nil
MCS.journalTargetList    = nil

local function GetTargetSpec()
    return MCS.journalTargetSpecKey or MCS:SpecKey()
end
local function GetTargetList()
    if MCS.journalTargetList then return MCS.journalTargetList end
    if MCS.activeListName then return MCS.activeListName end
    local names = MCS:GetListNames(GetTargetSpec())
    return names and names[1] or "Raid ST"
end

local function GetItemFromButton(button)
    local itemID
    if button.link then
        itemID = tonumber(button.link:match("item:(%d+)"))
    elseif button.itemID then
        itemID = button.itemID
    end

    -- Build rich source string: "Instance (N/Total) — BossName"
    local source = "Encounter Journal"
    local bossName, instanceName, bossIndex, totalBosses

    -- Get boss name from current encounter
    if EncounterJournal and EncounterJournal.encounterID then
        bossName = EJ_GetEncounterInfo(EncounterJournal.encounterID)
    end

    -- Get instance name and boss count from the EJ instance context
    local instanceID = EncounterJournal and EncounterJournal.instanceID
        or (EJ_GetCurrentInstance and EJ_GetCurrentInstance())
    if instanceID and instanceID > 0 then
        instanceName = EJ_GetInstanceInfo(instanceID)
        -- Count bosses and find current boss index
        if EJ_GetNumEncountersForInstance then
            totalBosses = EJ_GetNumEncountersForInstance(instanceID) or 0
            if bossName and totalBosses > 0 then
                for i = 1, totalBosses do
                    local eName = EJ_GetEncounterInfoByIndex(i, instanceID)
                    if eName == bossName then
                        bossIndex = i
                        break
                    end
                end
            end
        end
    end

    -- Assemble source string
    if instanceName and bossName and bossIndex and totalBosses then
        source = format("%s (%d/%d) — %s", instanceName, bossIndex, totalBosses, bossName)
    elseif instanceName and bossName then
        source = format("%s — %s", instanceName, bossName)
    elseif bossName then
        source = bossName
    end

    return itemID, source
end

local function OnItemClick(button, mouseButton)
    if not IsAltKeyDown() or mouseButton ~= "LeftButton" then return end
    local itemID, source = GetItemFromButton(button)
    if not itemID then return end
    -- Show the wishlist picker popup
    if MCS.ShowWishlistPicker then
        MCS:ShowWishlistPicker(itemID, source, button)
    end
end

local function HookEJButtons()
    if not EncounterJournal then return end
    local lc = EncounterJournal.encounter and EncounterJournal.encounter.info
        and EncounterJournal.encounter.info.LootContainer
    if lc and lc.ScrollBox then
        hooksecurefunc(lc.ScrollBox, "Update", function(self)
            self:ForEachFrame(function(frame)
                if frame and not frame._mcsHooked then
                    frame._mcsHooked = true
                    -- Only hook Button-type frames that support OnClick
                    local ok, handler = pcall(frame.GetScript, frame, "OnClick")
                    if ok and handler then
                        pcall(frame.HookScript, frame, "OnClick", OnItemClick)
                    end
                end
            end)
        end)
    end
    for i = 1, 20 do
        local btn = _G["EncounterJournalEncounterFrameInfoLootScrollFrameButton" .. i]
        if btn and not btn._mcsHooked then
            btn._mcsHooked = true
            local ok, handler = pcall(btn.GetScript, btn, "OnClick")
            if ok and handler then
                pcall(btn.HookScript, btn, "OnClick", OnItemClick)
            end
        end
    end
end

----------------------------------------------------------------------
-- EJ overlay: spec + list selector
----------------------------------------------------------------------
local function CreateSpecSelector()
    if not EncounterJournal then return end
    local f = CreateFrame("Frame", nil, EncounterJournal, "BackdropTemplate")
    f:SetSize(260, 26)
    local pos = MCS.db and MCS.db.ejSelectorPos
    if pos then
        f:SetPoint(pos.point, EncounterJournal, pos.relPoint, pos.x, pos.y)
    else
        f:SetPoint("TOPRIGHT", -60, -30)
    end
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not IsShiftKeyDown() and not IsControlKeyDown() then return end
        self._dragging = true
        self:StartMoving()
    end)
    f:SetScript("OnDragStop", function(self)
        if not self._dragging then return end
        self._dragging = nil
        self:StopMovingOrSizing()
        -- Convert position to be relative to EncounterJournal
        local s = self:GetEffectiveScale()
        local ejs = EncounterJournal:GetEffectiveScale()
        local cx = (self:GetLeft() * s - EncounterJournal:GetLeft() * ejs) / ejs
        local cy = (self:GetTop() * s - EncounterJournal:GetTop() * ejs) / ejs
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", EncounterJournal, "TOPLEFT", cx, cy)
        if MCS.db then
            MCS.db.ejSelectorPos = { point = "TOPLEFT", relPoint = "TOPLEFT", x = cx, y = cy }
        end
    end)
    f:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize=10, insets={left=2,right=2,top=2,bottom=2} })
    f:SetBackdropColor(0.05,0.05,0.12,0.95)
    f:SetBackdropBorderColor(0,0.7,1,0.8)

    local lbl = f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    lbl:SetPoint("LEFT",6,0); lbl:SetText("|cff00ccff[MCS]|r")

    f.specTxt = f:CreateFontString(nil,"OVERLAY","GameFontNormal")
    f.specTxt:SetPoint("LEFT", lbl, "RIGHT", 4, 0)
    f.specTxt:SetFont(STANDARD_TEXT_FONT, 10, "")

    function f:Refresh()
        local specKey = GetTargetSpec()
        local listName = GetTargetList()
        f.specTxt:SetText(MCS:FormatSpecKey(specKey) .. " |cffcccccc/|r |cffFFD100" .. listName .. "|r")
    end

    f:EnableMouse(true)
    f:SetScript("OnMouseDown", function(self, btn)
        if IsShiftKeyDown() or IsControlKeyDown() then return end
        if btn == "LeftButton" then
            -- Cycle spec (within class)
            local cls = MCS:GetPlayerClass()
            local specs = MCS.ALL_SPECS[cls]
            if not specs then return end
            local curKey = GetTargetSpec()
            local nextIdx = 1
            for i, spec in ipairs(specs) do
                if MCS:MakeSpecKey(cls, spec) == curKey then nextIdx = (i % #specs) + 1; break end
            end
            MCS.journalTargetSpecKey = MCS:MakeSpecKey(cls, specs[nextIdx])
            self:Refresh()
        elseif btn == "RightButton" then
            -- Cycle list name for current target spec
            local specKey = GetTargetSpec()
            local names = MCS:GetListNames(specKey)
            local cur = GetTargetList()
            local nextIdx = 1
            for i, n in ipairs(names) do
                if n == cur then nextIdx = (i % #names) + 1; break end
            end
            MCS.journalTargetList = names[nextIdx]
            self:Refresh()
        end
    end)

    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("|cff00ccffMCS Wishlist Target|r")
        GameTooltip:AddLine("|cffccccccLeft-click|r: cycle specs")
        GameTooltip:AddLine("|cffccccccRight-click|r: cycle lists")
        GameTooltip:AddLine("|cffccccccAlt-click|r items below to wishlist")
        GameTooltip:AddLine("|cffccccccShift/Ctrl-drag|r to reposition (saved between sessions)")
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    f:Refresh()
    MCS.ejSelector = f
end

----------------------------------------------------------------------
-- Main entry
----------------------------------------------------------------------
function MCS:HookDungeonJournal()
    local function TryHook()
        if EncounterJournal then
            HookEJButtons()
            CreateSpecSelector()
        end
    end
    if EncounterJournal then TryHook() end
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function(_, _, addon)
        if addon == "Blizzard_EncounterJournal" then C_Timer.After(0.3, TryHook) end
    end)
    if EncounterJournal then
        hooksecurefunc("EJ_ContentTab_Select", function()
            C_Timer.After(0.3, HookEJButtons)
        end)
    end
end
