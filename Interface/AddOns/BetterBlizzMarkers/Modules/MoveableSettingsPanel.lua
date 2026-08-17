local addonName, BBM = ...
local addon = BBM.addon

local FRAME_MOVER_ADDONS = { "BlizzMove", "MoveAny" }

local function FrameMoverAddonLoaded()
    for _, name in ipairs(FRAME_MOVER_ADDONS) do
        if C_AddOns.IsAddOnLoaded(name) then return true end
    end
    return false
end

local installedByBBM = false

local function ApplyMoveableSettingsPanel()
    if FrameMoverAddonLoaded() then return end

    local frame = SettingsPanel
    if not frame then return end

    if addon.db.profile.others.moveableSettingsPanel then
        if frame:GetScript("OnDragStart") then return end
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        installedByBBM = true
    elseif installedByBBM then
        frame:SetScript("OnDragStart", nil)
        frame:SetScript("OnDragStop", nil)
        frame:RegisterForDrag()
        installedByBBM = false
    end
end

BBM.ApplyMoveableSettingsPanel = ApplyMoveableSettingsPanel
BBM.On("PLAYER_LOGIN", ApplyMoveableSettingsPanel)
