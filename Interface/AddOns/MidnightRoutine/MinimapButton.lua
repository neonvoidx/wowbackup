local LDB     = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local L       = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local GLOW_PULSE_INTERVAL = 1.5

local glowTimer

local function StartGlow()
    local shine = MR.cfgShine
    if not shine then return end
    shine:Play()
    if glowTimer then glowTimer:Cancel() end
    glowTimer = C_Timer.NewTicker(GLOW_PULSE_INTERVAL, function()
        if not MR.db or MR.db.profile.firstSeen then
            MR:DismissFirstTimeGlow()
        end
    end)
end

function MR:DismissFirstTimeGlow()
    if not self.db or self.db.profile.firstSeen then return end
    self.db.profile.firstSeen = true
    if glowTimer then
        glowTimer:Cancel()
        glowTimer = nil
    end
    local shine = self.cfgShine
    if shine then
        shine:Stop()
    end
end

local minimapObject = LDB:NewDataObject("MidnightRoutine", {
    type = "launcher",
    text = "MidnightRoutine",
    icon = "Interface\\AddOns\\MidnightRoutine\\Media\\Icon.tga",

    OnClick = function(_, button)
        if button == "LeftButton" then
            if MR.frame then
                if MR.frame:IsShown() then
                    MR.frame:Hide()
                    MR.db.profile.panelOpen = false
                else
                    MR.frame:Show()
                    MR.db.profile.panelOpen = true
                end
            end
        elseif button == "RightButton" then
            if MR.ToggleConfig then MR:ToggleConfig() end
        end
    end,

    OnTooltipShow = function(tt)
        tt:AddLine(L["Title"], 1, 1, 1)
        tt:AddLine(L["Minimap_LeftClick"],  0.8, 0.8, 0.8)
        tt:AddLine(L["Minimap_RightClick"],     0.8, 0.8, 0.8)
        tt:AddLine(L["Minimap_HideHint"], 0.5, 0.5, 0.5)
    end,
})

local mmLoader = CreateFrame("Frame")
mmLoader:RegisterEvent("PLAYER_LOGIN")
mmLoader:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()

    if not LDBIcon:IsRegistered("MidnightRoutine") then
        LDBIcon:Register("MidnightRoutine", minimapObject, MR.db.profile.minimap)
    end

    if not MR.db.profile.firstSeen then
        C_Timer.After(2.0, function()
            StartGlow()
        end)
    end
end)

function MR:SetMinimapHidden(hide)
    if not self.db then return end
    self.db.profile.minimap.hide = hide and true or false
    if LDBIcon:IsRegistered("MidnightRoutine") then
        if hide then LDBIcon:Hide("MidnightRoutine")
        else         LDBIcon:Show("MidnightRoutine") end
    end
end
