local FONT_HEADERS = MR_FONT_HEADERS
local FONT_ROWS    = MR_FONT_ROWS
local hex          = MR_HEX
local L            = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local pendingEnabled = {}
local pendingRenown      = false
local pendingRares       = false
local pendingGathering   = false
local checkboxRefs   = {}

local function BuildWelcomeScreen()
    wipe(pendingEnabled)
    wipe(checkboxRefs)

    for _, mod in ipairs(MR:GetOrderedModules()) do
        pendingEnabled[mod.key] = MR:IsModuleEnabled(mod.key)
    end

    pendingRenown   = MR.db and MR.db.profile.renownOpen     or false
    pendingRares    = MR.db and MR.db.profile.raresOpen      or false
    pendingGathering = MR.db and MR.db.profile.gatheringLocOpen or false

    local f = MR_StyledFrame(UIParent, "MRWelcomeFrame", "FULLSCREEN_DIALOG", 200)
    f:SetSize(310, 10)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    f:SetBackdropColor(0.02, 0.04, 0.10, 0.98)
    f:SetBackdropBorderColor(0.16, 0.78, 0.75, 1)

    MR_LeftAccent(f, 0.16, 0.78, 0.75)

    local titleBar = MR_TitleBar(f, 36)
    titleBar:SetBackdropColor(0.04, 0.10, 0.22, 1)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    local icon = titleBar:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    icon:SetTexture("Interface\\AddOns\\MidnightRoutine\\Media\\Icon")
    icon:SetVertexColor(0.16, 0.78, 0.75, 1)

    local titleTxt = titleBar:CreateFontString(nil, "OVERLAY")
    titleTxt:SetFont(FONT_HEADERS, 13, "OUTLINE")
    titleTxt:SetPoint("LEFT", icon, "RIGHT", 7, 0)
    titleTxt:SetText(L["Welcome_Title"])

    local yOff = -46

    local heading = f:CreateFontString(nil, "OVERLAY")
    heading:SetFont(FONT_HEADERS, 12, "OUTLINE")
    heading:SetPoint("TOPLEFT",  f, "TOPLEFT",  14, yOff)
    heading:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, yOff)
    heading:SetJustifyH("LEFT")
    heading:SetText(L["Welcome_Heading"])

    yOff = yOff - 18

    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont(FONT_ROWS, 10, "OUTLINE")
    hint:SetPoint("TOPLEFT",  f, "TOPLEFT",  14, yOff)
    hint:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, yOff)
    hint:SetJustifyH("LEFT")
    hint:SetText(L["Welcome_Hint"])

    yOff = yOff - 16

    local function MakeDivider(y)
        local d = CreateFrame("Frame", nil, f, "BackdropTemplate")
        d:SetPoint("TOPLEFT",  f, "TOPLEFT",   8, y)
        d:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, y)
        d:SetHeight(1)
        d:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        d:SetBackdropColor(0.16, 0.78, 0.75, 0.25)
    end
    MakeDivider(yOff)
    yOff = yOff - 8

    for _, mod in ipairs(MR:GetOrderedModules()) do
        local skip = mod.profSkillLine and not MR.playerProfessions[mod.profSkillLine]
        if not skip then
            local key = mod.key

            local row = CreateFrame("Frame", nil, f)
            row:SetPoint("TOPLEFT",  f, "TOPLEFT",  12, yOff)
            row:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, yOff)
            row:SetHeight(22)

            local dot = row:CreateTexture(nil, "ARTWORK")
            dot:SetSize(5, 5)
            dot:SetPoint("LEFT", row, "LEFT", 0, 0)
            local lr, lg, lb = hex(mod.labelColor or "#aaaaaa")
            dot:SetColorTexture(lr, lg, lb, 1)

            local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("LEFT", dot, "RIGHT", 4, 0)
            cb:SetChecked(pendingEnabled[key])
            cb:SetScript("OnClick", function(s)
                pendingEnabled[key] = s:GetChecked()
            end)
            checkboxRefs[key] = cb

            local lbl = row:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, 11, "OUTLINE")
            lbl:SetPoint("LEFT",  cb,  "RIGHT",  4, 0)
            lbl:SetPoint("RIGHT", row, "RIGHT",  0, 0)
            lbl:SetJustifyH("LEFT")
            local colHex = (mod.labelColor or "#dddddd"):gsub("#","")
            lbl:SetText(string.format("|cff%s%s|r", colHex, mod.label))

            yOff = yOff - 24
        end
    end

    yOff = yOff - 8

    local renownPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    renownPanel:SetPoint("TOPLEFT",  f, "TOPLEFT",   8, yOff)
    renownPanel:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, yOff)
    renownPanel:SetHeight(72)
    renownPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    renownPanel:SetBackdropColor(0.10, 0.08, 0.02, 0.85)
    renownPanel:SetBackdropBorderColor(0.65, 0.50, 0.10, 0.90)

    local renownAccent = renownPanel:CreateTexture(nil, "ARTWORK")
    renownAccent:SetHeight(2)
    renownAccent:SetPoint("TOPLEFT",  renownPanel, "TOPLEFT",  1, -1)
    renownAccent:SetPoint("TOPRIGHT", renownPanel, "TOPRIGHT", -1, -1)
    renownAccent:SetColorTexture(0.85, 0.65, 0.10, 0.85)

    local renownCb = CreateFrame("CheckButton", nil, renownPanel, "UICheckButtonTemplate")
    renownCb:SetSize(22, 22)
    renownCb:SetPoint("LEFT", renownPanel, "LEFT", 8, 4)
    renownCb:SetChecked(pendingRenown)
    renownCb:SetScript("OnClick", function(s)
        pendingRenown = s:GetChecked()
    end)

    local renownLbl = renownPanel:CreateFontString(nil, "OVERLAY")
    renownLbl:SetFont(FONT_HEADERS, 12, "OUTLINE")
    renownLbl:SetPoint("LEFT",  renownCb, "RIGHT", 4, 4)
    renownLbl:SetPoint("RIGHT", renownPanel, "RIGHT", -8, 0)
    renownLbl:SetJustifyH("LEFT")
    renownLbl:SetText(L["Welcome_Renown"])

    local renownDesc = renownPanel:CreateFontString(nil, "OVERLAY")
    renownDesc:SetFont(FONT_ROWS, 10, "OUTLINE")
    renownDesc:SetPoint("TOPLEFT",  renownPanel, "TOPLEFT",  10, -42)
    renownDesc:SetPoint("BOTTOMRIGHT", renownPanel, "BOTTOMRIGHT", -10, 6)
    renownDesc:SetJustifyH("LEFT")
    renownDesc:SetJustifyV("TOP")
    renownDesc:SetText(L["Welcome_Renown_Desc"])

    yOff = yOff - 80

    local raresPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    raresPanel:SetPoint("TOPLEFT",  f, "TOPLEFT",   8, yOff)
    raresPanel:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, yOff)
    raresPanel:SetHeight(72)
    raresPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    raresPanel:SetBackdropColor(0.12, 0.03, 0.03, 0.85)
    raresPanel:SetBackdropBorderColor(0.65, 0.20, 0.10, 0.90)

    local raresAccent = raresPanel:CreateTexture(nil, "ARTWORK")
    raresAccent:SetHeight(2)
    raresAccent:SetPoint("TOPLEFT",  raresPanel, "TOPLEFT",  1, -1)
    raresAccent:SetPoint("TOPRIGHT", raresPanel, "TOPRIGHT", -1, -1)
    raresAccent:SetColorTexture(0.85, 0.25, 0.10, 0.85)

    local raresCb = CreateFrame("CheckButton", nil, raresPanel, "UICheckButtonTemplate")
    raresCb:SetSize(22, 22)
    raresCb:SetPoint("LEFT", raresPanel, "LEFT", 8, 4)
    raresCb:SetChecked(pendingRares)
    raresCb:SetScript("OnClick", function(s)
        pendingRares = s:GetChecked()
    end)

    local raresLbl = raresPanel:CreateFontString(nil, "OVERLAY")
    raresLbl:SetFont(FONT_HEADERS, 12, "OUTLINE")
    raresLbl:SetPoint("LEFT",  raresCb, "RIGHT", 4, 4)
    raresLbl:SetPoint("RIGHT", raresPanel, "RIGHT", -8, 0)
    raresLbl:SetJustifyH("LEFT")
    raresLbl:SetText(L["Welcome_Rares"])

    local raresDesc = raresPanel:CreateFontString(nil, "OVERLAY")
    raresDesc:SetFont(FONT_ROWS, 10, "OUTLINE")
    raresDesc:SetPoint("TOPLEFT",  raresPanel, "TOPLEFT",  10, -42)
    raresDesc:SetPoint("BOTTOMRIGHT", raresPanel, "BOTTOMRIGHT", -10, 6)
    raresDesc:SetJustifyH("LEFT")
    raresDesc:SetJustifyV("TOP")
    raresDesc:SetText(L["Welcome_Rares_Desc"])

    yOff = yOff - 80

    local gatheringPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    gatheringPanel:SetPoint("TOPLEFT",  f, "TOPLEFT",   8, yOff)
    gatheringPanel:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, yOff)
    gatheringPanel:SetHeight(72)
    gatheringPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    gatheringPanel:SetBackdropColor(0.08, 0.10, 0.03, 0.85)
    gatheringPanel:SetBackdropBorderColor(0.65, 0.57, 0.10, 0.90)

    local gatheringAccent = gatheringPanel:CreateTexture(nil, "ARTWORK")
    gatheringAccent:SetHeight(2)
    gatheringAccent:SetPoint("TOPLEFT",  gatheringPanel, "TOPLEFT",  1, -1)
    gatheringAccent:SetPoint("TOPRIGHT", gatheringPanel, "TOPRIGHT", -1, -1)
    gatheringAccent:SetColorTexture(0.80, 0.53, 0.20, 0.85)

    local gatheringCb = CreateFrame("CheckButton", nil, gatheringPanel, "UICheckButtonTemplate")
    gatheringCb:SetSize(22, 22)
    gatheringCb:SetPoint("LEFT", gatheringPanel, "LEFT", 8, 4)
    gatheringCb:SetChecked(pendingGathering)
    gatheringCb:SetScript("OnClick", function(s)
        pendingGathering = s:GetChecked()
    end)

    local gatheringLbl = gatheringPanel:CreateFontString(nil, "OVERLAY")
    gatheringLbl:SetFont(FONT_HEADERS, 12, "OUTLINE")
    gatheringLbl:SetPoint("LEFT",  gatheringCb, "RIGHT", 4, 4)
    gatheringLbl:SetPoint("RIGHT", gatheringPanel, "RIGHT", -8, 0)
    gatheringLbl:SetJustifyH("LEFT")
    gatheringLbl:SetText(L["Welcome_ProfKnowledge"])

    local gatheringDesc = gatheringPanel:CreateFontString(nil, "OVERLAY")
    gatheringDesc:SetFont(FONT_ROWS, 10, "OUTLINE")
    gatheringDesc:SetPoint("TOPLEFT",  gatheringPanel, "TOPLEFT",  10, -42)
    gatheringDesc:SetPoint("BOTTOMRIGHT", gatheringPanel, "BOTTOMRIGHT", -10, 6)
    gatheringDesc:SetJustifyH("LEFT")
    gatheringDesc:SetJustifyV("TOP")
    gatheringDesc:SetText(L["Welcome_ProfKnowledge_Desc"])

    yOff = yOff - 80
    MakeDivider(yOff)
    yOff = yOff - 10

    local allOn = true
    local enableAllBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    enableAllBtn:SetPoint("TOPLEFT",  f, "TOPLEFT",  12, yOff)
    enableAllBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, yOff)
    enableAllBtn:SetHeight(22)
    enableAllBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    enableAllBtn:SetBackdropColor(0.04, 0.14, 0.22, 1)
    enableAllBtn:SetBackdropBorderColor(0.18, 0.55, 0.60, 1)

    local eaLbl = enableAllBtn:CreateFontString(nil, "OVERLAY")
    eaLbl:SetFont(FONT_ROWS, 10, "OUTLINE")
    eaLbl:SetPoint("CENTER")
    eaLbl:SetText(L["Welcome_Disable_All"])

    enableAllBtn:SetScript("OnClick", function()
        allOn = not allOn
        for _, mod in ipairs(MR:GetOrderedModules()) do
            local skip = mod.profSkillLine and not MR.playerProfessions[mod.profSkillLine]
            if not skip then
                pendingEnabled[mod.key] = allOn
                if checkboxRefs[mod.key] then
                    checkboxRefs[mod.key]:SetChecked(allOn)
                end
            end
        end
        eaLbl:SetText(allOn and L["Welcome_Disable_All"] or L["Welcome_Enable_All"])
    end)
    enableAllBtn:SetScript("OnEnter", function()
        enableAllBtn:SetBackdropColor(0.06, 0.22, 0.32, 1)
        enableAllBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
    end)
    enableAllBtn:SetScript("OnLeave", function()
        enableAllBtn:SetBackdropColor(0.04, 0.14, 0.22, 1)
        enableAllBtn:SetBackdropBorderColor(0.18, 0.55, 0.60, 1)
    end)

    yOff = yOff - 32

    local suppressCb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    suppressCb:SetSize(20, 20)
    suppressCb:SetPoint("TOPLEFT", f, "TOPLEFT", 12, yOff + 6)
    suppressCb:SetChecked(false)

    local suppressLbl = f:CreateFontString(nil, "OVERLAY")
    suppressLbl:SetFont(FONT_ROWS, 10, "OUTLINE")
    suppressLbl:SetPoint("LEFT", suppressCb, "RIGHT", 2, 0)
    suppressLbl:SetText(L["Welcome_SuppressAll"])
    suppressLbl:SetTextColor(0.6, 0.6, 0.6)

    yOff = yOff - 24

    local confirmBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    confirmBtn:SetPoint("TOPLEFT",  f, "TOPLEFT",  12, yOff)
    confirmBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, yOff)
    confirmBtn:SetHeight(28)
    confirmBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    confirmBtn:SetBackdropColor(0.05, 0.20, 0.12, 1)
    confirmBtn:SetBackdropBorderColor(0.15, 0.78, 0.42, 1)

    local confirmLbl = confirmBtn:CreateFontString(nil, "OVERLAY")
    confirmLbl:SetFont(FONT_HEADERS, 12, "OUTLINE")
    confirmLbl:SetPoint("CENTER")
    confirmLbl:SetText(L["Welcome_Confirm"])

    confirmBtn:SetScript("OnClick", function()
        local anyEnabled = false
        for key, val in pairs(pendingEnabled) do
            MR:SetModuleEnabled(key, val)
            if val then anyEnabled = true end
        end
        if MR.db then

            local prevRenown   = MR.db.profile.renownOpen
            local prevRares    = MR.db.profile.raresOpen
            local prevGathering = MR.db.profile.gatheringLocOpen

            if pendingRenown ~= prevRenown then
                MR.db.profile.renownOpen = pendingRenown
                if pendingRenown and MR.ToggleRenown then
                    MR:ToggleRenown()
                elseif not pendingRenown and MR.HideRenown then
                    MR:HideRenown(false)
                end
            end
            if pendingRares ~= prevRares then
                MR.db.profile.raresOpen = pendingRares
                if pendingRares and MR.ToggleRares then
                    MR:ToggleRares()
                elseif not pendingRares and MR.HideRares then
                    MR:HideRares(false)
                end
            end
            if pendingGathering ~= prevGathering then
                MR.db.profile.gatheringLocOpen = pendingGathering
                if pendingGathering and MR.ToggleGatheringLocations then
                    MR:ToggleGatheringLocations()
                elseif not pendingGathering and MR.HideGatheringLocations then
                    MR:HideGatheringLocations(false)
                end
            end
        end
        MR.db.profile.firstSeen = true
        MR.db.char.welcomeSeen = true
        if suppressCb:GetChecked() then
            MR.db.profile.welcomeSuppressed = true
        end
        if MR.cfgShine then MR.cfgShine:Stop() end
        f:Hide()
        MR:RefreshUI()
        if anyEnabled and MR.frame then
            MR.frame:Show()
            MR.db.profile.panelOpen = true
        end
    end)
    confirmBtn:SetScript("OnEnter", function()
        confirmBtn:SetBackdropColor(0.08, 0.32, 0.20, 1)
        confirmBtn:SetBackdropBorderColor(0.20, 1.00, 0.55, 1)
        confirmLbl:SetTextColor(1, 1, 1)
    end)
    confirmBtn:SetScript("OnLeave", function()
        confirmBtn:SetBackdropColor(0.05, 0.20, 0.12, 1)
        confirmBtn:SetBackdropBorderColor(0.15, 0.78, 0.42, 1)
        local r, g, b = hex("#00ff96")
        confirmLbl:SetTextColor(r, g, b)
    end)

    yOff = yOff - 38

    f:SetHeight(math.abs(yOff) + 10)

    f:SetAlpha(0)
    local fadeEl = 0
    f:SetScript("OnUpdate", function(self, dt)
        fadeEl = fadeEl + dt
        local a = math.min(fadeEl / 0.4, 1)
        self:SetAlpha(a)
        if a >= 1 then self:SetScript("OnUpdate", nil) end
    end)

    return f
end

function MR:ShowWelcomeScreen()
    if self.welcomeFrame then
        self.welcomeFrame:Hide()
        self.welcomeFrame = nil
    end
    self.welcomeFrame = BuildWelcomeScreen()
    self.welcomeFrame:Show()
end

function MR:MaybeShowWelcomeScreen()
    if self.db.profile.welcomeSuppressed then return end
    if self.db.char.welcomeSeen then return end
    local ticks = 0
    local checker = CreateFrame("Frame")
    checker:SetScript("OnUpdate", function(self, dt)
        ticks = ticks + 1
        if ticks >= 5 then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            MR:ShowWelcomeScreen()
            if MR.cfgShine then MR.cfgShine:Play() end
        end
    end)
end

function MR:DismissFirstTimeGlow()
    if self.cfgShine then self.cfgShine:Stop() end
end
