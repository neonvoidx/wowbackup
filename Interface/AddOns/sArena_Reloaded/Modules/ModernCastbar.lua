local isRetail = sArenaMixin.isRetail

local CastStopEvents = {
    UNIT_SPELLCAST_STOP                = true,
    UNIT_SPELLCAST_FAILED              = true,
    UNIT_SPELLCAST_FAILED_QUIET        = true,
    UNIT_SPELLCAST_INTERRUPTED         = true,
    UNIT_SPELLCAST_CHANNEL_STOP        = true,
    UNIT_SPELLCAST_CHANNEL_INTERRUPTED = true,
}

if isRetail then
    sArenaCastingBarExtensionMixin = {}
    -- default bars
    local typeInfoTexture = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill";
    sArenaCastingBarExtensionMixin.typeInfo = {
        filling = typeInfoTexture,
        full = typeInfoTexture,
        glow = typeInfoTexture
    }

    local actionColors = {
        applyingcrafting = { 1.0, 0.7, 0.0, 1 },
        applyingtalents = { 1.0, 0.7, 0.0, 1 },
        filling = { 1.0, 0.7, 0.0, 1 },
        full = { 0.0, 1.0, 0.0, 1 },
        standard = { 1.0, 0.7, 0.0, 1 },
        empowered = { 1.0, 0.7, 0.0, 1 },
        channel = { 0.0, 1.0, 0.0, 1 },
        uninterruptable = { 0.7, 0.7, 0.7, 1 },
        interrupted = { 1.0, 0.0, 0.0, 1 }
    }


    function sArenaCastingBarExtensionMixin:GetTypeInfo(barType)
        barType = barType or "standard";
        self:SetStatusBarColor(unpack(actionColors[barType]));
        return self.typeInfo
    end

    ----------------------------------------
    -- Helpers
    ----------------------------------------
    local function CopyAnchors(from, to)
        to:ClearAllPoints()
        for i = 1, from:GetNumPoints() do
            local pt, rel, relPt, x, y = from:GetPoint(i)
            to:SetPoint(pt, rel, relPt, x, y)
        end
    end

    local function DisableCastBar(bar)
        if not bar then return end
        bar:SetUnit(nil)
        bar:Hide()
    end

    local function EnableCastBar(bar, unit, style)
        if not bar then return end

        bar:SetUnit(unit, true, false)
        if bar.UpdateInterruptibleState then bar:UpdateInterruptibleState() end
        if bar.UpdateDisplayedVisuals then bar:UpdateDisplayedVisuals() end
        if bar.UpdateDisplayType then bar:UpdateDisplayType() end

        if style == "modern" then
            -- bar.Text:ClearAllPoints()
            -- bar.Text:SetPoint("BOTTOM", bar, 0, -14)
            bar:SetHeight(9)
        else
            -- bar.Text:ClearAllPoints()
            -- bar.Text:SetPoint("CENTER", bar, "CENTER", 0, 0)
            bar:SetHeight(16)
        end

        bar:Show()
    end

    ----------------------------------------
    -- Creation
    ----------------------------------------

    local function EnsureClassicBar(frame)
        if frame.classicCastBar and frame.classicCastBar ~= frame.CastBar then
            return frame.classicCastBar
        end
        frame.classicCastBar = frame.CastBar
        return frame.classicCastBar
    end

    local function UpdateSparkPosition(castBar)
        local val = castBar:GetValue()
        local minVal, maxVal = castBar:GetMinMaxValues()
        if maxVal == 0 then return end
        local progressPercent = val / maxVal
        local newX = castBar:GetWidth() * progressPercent
        castBar.Spark:ClearAllPoints()
        castBar.Spark:SetPoint("CENTER", castBar, "LEFT", newX, 0)
    end

    local function HideChargeTiers(castBar)
        castBar.ChargeTier1:Hide()
        castBar.ChargeTier2:Hide()
        castBar.ChargeTier3:Hide()
        if castBar.ChargeTier4 then
            castBar.ChargeTier4:Hide()
        end
    end

    local function EnsureModernBar(frame, unit, templateName)
        if frame.modernCastBar and frame.modernCastBar:IsObjectType("StatusBar") then
            return frame.modernCastBar
        end

        local old = EnsureClassicBar(frame)
        local parent = old:GetParent() or frame
        local template = templateName or "SmallCastingBarFrameTemplate"

        local newBar = CreateFrame("StatusBar", nil, parent, template)


        if newBar.OnLoad then
            newBar:OnLoad(nil, true, false)
        end

        if not newBar.empoweredFix then
            newBar:HookScript("OnEvent", function(self)
                if self:IsForbidden() then return end
                if self.barType == "uninterruptable" then
                    if self.ChargeTier1 then
                        self:SetStatusBarTexture("UI-CastingBar-Uninterruptable")
                        HideChargeTiers(self)
                    end
                elseif self.barType == "empowered" then
                    self:SetStatusBarTexture("ui-castingbar-filling-standard")
                    HideChargeTiers(self)
                end
            end)

            newBar:HookScript("OnUpdate", function(self)
                if self:IsForbidden() then return end
                if self.barType == "uninterruptable" then
                    if self.ChargeTier1 then
                        self.Spark:SetAtlas("UI-CastingBar-Pip")
                        self.Spark:SetSize(6, 16)
                        UpdateSparkPosition(newBar)
                    end
                elseif self.barType == "empowered" then
                    self.Spark:SetAtlas("UI-CastingBar-Pip")
                    self.Spark:SetSize(6, 16)
                    UpdateSparkPosition(newBar)
                end
            end)

            newBar.empoweredFix = true
        end
        if not newBar.quickHide then
            newBar:HookScript("OnEvent", function(self, event)
                if CastStopEvents[event] then
                    self:Hide()
                end
            end)
            newBar.quickHide= true
        end
        newBar.__modernHooked = true

        if sArenaMixin:DarkMode() then
            local darkModeColor = sArenaMixin:DarkModeColor()
            newBar.TextBorder:SetDesaturated(true)
            newBar.TextBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
            newBar.Border:SetDesaturated(true)
            newBar.Border:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
        end

        -- Copy placement & sizing
        newBar:SetSize(old:GetWidth(), old:GetHeight())
        CopyAnchors(old, newBar)
        newBar:SetFrameStrata(old:GetFrameStrata())
        newBar:SetFrameLevel(old:GetFrameLevel())
        newBar:Hide()
        newBar.Spark:SetSize(3, 16)

        frame.modernCastBar = newBar
        return newBar
    end

    ----------------------------------------
    -- Style switching (single frame)
    ----------------------------------------

    function sArenaMixin:ApplyCastbarStyle(frame, unit, modern)
        if InCombatLockdown and InCombatLockdown() then
            -- mark for later
            frame.__pendingCastbarStyle = modern and "modern" or "classic"
            return
        end

        local classic = EnsureClassicBar(frame)
        local modernBar = EnsureModernBar(frame, unit)

        if modern then
            -- turn off classic, turn on modern
            DisableCastBar(classic)
            EnableCastBar(modernBar, unit or classic.unit, "modern")
            frame.CastBar = modernBar
        else
            -- turn off modern, turn on classic
            DisableCastBar(modernBar)
            EnableCastBar(classic, unit or modernBar.unit or classic.unit, "classic")
            frame.CastBar = classic
        end

        frame.__pendingCastbarStyle = nil
    end
else
    -- Mists of Pandaria

    local MOD_NONINT_TEX  = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Uninterruptable"
    local MOD_CHANNEL_TEX = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel"
    local MOD_CAST_TEX    = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard"
    local MOD_BG_TEX      = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Background.tga"
    local MOD_FRAME_TEX   = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Frame.tga"
    local MOD_TEXTBOX_TEX = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-TextBox.tga"
    local MOD_SHIELD_TEX  = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Shield.tga"

    local function EnsureModernPieces(bar)
        if bar.TextBorder and bar.Background and bar.Border then return end
        bar.TextBorder = bar.TextBorder or bar:CreateTexture(nil, "BACKGROUND", nil, 2)
        bar.Background = bar.Background or bar:CreateTexture(nil, "BACKGROUND", nil, 2)
        bar.Border     = bar.Border or bar:CreateTexture(nil, "OVERLAY", nil, 7)
    end

    local function ApplyModern(bar)
        EnsureModernPieces(bar)

        bar.TextBorder:SetTexture(MOD_TEXTBOX_TEX)
        bar.Background:SetTexture(MOD_BG_TEX)
        bar.Border:SetTexture(MOD_FRAME_TEX)
        bar.BorderShield:SetTexture(MOD_SHIELD_TEX)
        bar.BorderShield:SetDrawLayer("BACKGROUND", 0)

        local function _snapColor(c)
            if c and c.GetRGBA then
                local r, g, b, a = c:GetRGBA()
                return { r = r, g = g, b = b, a = a }
            end
        end

        if not bar.__origColorsSaved then
            bar.__origColors = {
                failed   = _snapColor(bar.failedCastColor),
                finished = _snapColor(bar.finishedCastColor),
                nonint   = _snapColor(bar.nonInterruptibleColor),
                start    = _snapColor(bar.startCastColor),
                channel  = _snapColor(bar.startChannelColor),
            }
            bar.__origColorsSaved = true
        end

        bar.failedCastColor       = CreateColor(1, 1, 1, 1)
        bar.finishedCastColor     = CreateColor(1, 1, 1, 1)
        bar.nonInterruptibleColor = CreateColor(1, 1, 1, 1)
        bar.startCastColor        = CreateColor(1, 1, 1, 1)
        bar.startChannelColor     = CreateColor(1, 1, 1, 1)

        bar.Background:SetAllPoints(bar)
        bar.Background:Show()
        bar.Border:ClearAllPoints()
        bar.Border:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
        bar.Border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
        bar.Border:Show()

        bar.TextBorder:ClearAllPoints()
        bar.TextBorder:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, 1)
        bar.TextBorder:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -1, -13.5)
        bar.TextBorder:Show()

        local ogBg = select(1, bar:GetRegions())
        if ogBg then
            ogBg:Hide()
        end

        if not bar.MaskTexture then
            bar.MaskTexture = bar:CreateMaskTexture()
        end
        local castTexture = bar:GetStatusBarTexture()
        bar.MaskTexture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\RetailCastMask.tga",
            "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        bar.MaskTexture:SetAllPoints(bar)
        bar.MaskTexture:Show()
        castTexture:AddMaskTexture(bar.MaskTexture)

        -- bar.Text:ClearAllPoints()
        -- bar.Text:SetPoint("BOTTOM", bar, 0, -10.5)
        bar:SetHeight(12)
        if bar.Icon then bar.Icon:SetSize(21, 21) end

        if not bar.__modernHooked then
            -- TODO: Figure out better method for this.
            -- It's this way because OnEvent doesn't fire for aura updates like aura mastery etc
            -- This just bruteforces correct texture in non-interrupt scenarios
            bar:HookScript("OnUpdate", function(self)
                if not self.__modernActive then return end
                if self.notInterruptible and self.__tex ~= MOD_NONINT_TEX then
                    self:SetStatusBarTexture(MOD_NONINT_TEX); self.__tex = MOD_NONINT_TEX
                elseif self.channeling and self.__tex ~= MOD_CHANNEL_TEX then
                    self:SetStatusBarTexture(MOD_CHANNEL_TEX); self.__tex = MOD_CHANNEL_TEX
                elseif self.casting and self.__tex ~= MOD_CAST_TEX then
                    self:SetStatusBarTexture(MOD_CAST_TEX); self.__tex = MOD_CAST_TEX
                end
            end)
            bar:HookScript("OnEvent", function(self, event)
                if CastStopEvents[event] then
                    self:Hide()
                end
            end)
            bar.__modernHooked = true
        end

        bar.__modernActive = true
        bar:Show()
    end

    local function RestoreClassic(bar)
        bar.Text:ClearAllPoints()
        bar.Text:SetPoint("CENTER", bar, "CENTER", 0, 0)
        bar:SetHeight(16)
        if bar.Icon then bar.Icon:SetSize(16, 16) end

        if bar.TextBorder then bar.TextBorder:Hide() end
        if bar.Background then bar.Background:Hide() end
        if bar.Border then bar.Border:Hide() end

        local o = bar.__origColors
        if o then
            if o.failed then bar.failedCastColor = CreateColor(o.failed.r, o.failed.g, o.failed.b, o.failed.a) end
            if o.finished then bar.finishedCastColor = CreateColor(o.finished.r, o.finished.g, o.finished.b, o.finished
                .a) end
            if o.nonint then bar.nonInterruptibleColor = CreateColor(o.nonint.r, o.nonint.g, o.nonint.b, o.nonint.a) end
            if o.start then bar.startCastColor = CreateColor(o.start.r, o.start.g, o.start.b, o.start.a) end
            if o.channel then bar.startChannelColor = CreateColor(o.channel.r, o.channel.g, o.channel.b, o.channel.a) end
        end

        local ogBg = select(1, bar:GetRegions())
        if ogBg then
            ogBg:Show()
        end

        if bar.MaskTexture then
            bar.MaskTexture:Hide()
        end

        if bar.BorderShield then
            bar.BorderShield:SetTexture(330124)
        end

        bar.__modernActive = false
        bar:Show()
    end

    local function EnableCastBarClassicMode(bar, modern)
        if not bar then return end
        if modern then
            ApplyModern(bar)
        else
            RestoreClassic(bar)
        end
    end

    function sArenaMixin:ApplyCastbarStyle(frame, unit, modern)
        if InCombatLockdown and InCombatLockdown() then
            frame.__pendingCastbarStyle = modern and "modern" or "classic"
            return
        end
        EnableCastBarClassicMode(frame.CastBar, modern)
        frame.__pendingCastbarStyle = nil
    end
end
