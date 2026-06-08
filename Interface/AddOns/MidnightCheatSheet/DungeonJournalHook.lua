----------------------------------------------------------------------
-- MidnightCheatSheet – DungeonJournalHook.lua
-- Hooks Encounter Journal item buttons for Alt-click wishlisting.
----------------------------------------------------------------------
local _, MCS = ...

local format, tonumber = format, tonumber
local IsAltKeyDown = IsAltKeyDown
local hooksecurefunc = hooksecurefunc
local C_Timer = C_Timer
local CreateFrame = CreateFrame

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
-- Main entry
----------------------------------------------------------------------
function MCS:HookDungeonJournal()
    local function TryHook()
        if EncounterJournal then
            HookEJButtons()
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
