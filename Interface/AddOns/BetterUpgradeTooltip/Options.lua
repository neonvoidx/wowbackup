local ADDON_NAME = ...
local Private = select(2, ...)

function Private:InitSettings()
    ------------------------------------------------------------
    -- Canvas frame
    ------------------------------------------------------------
    local frame = CreateFrame("Frame")

    -- Optional background (for debugging / layout)
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetColorTexture(0, 0, 0, 0)

    ------------------------------------------------------------
    -- Title
    ------------------------------------------------------------
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("BetterUpgradeTooltip")

    ------------------------------------------------------------
    -- Checkbox helper
    ------------------------------------------------------------
    local function CreateCheckbox(label, key, yOffset)
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, yOffset)
        cb.Text:SetText(label)
        cb:SetChecked(BetterUpgradeTooltipDB[key])

        cb:SetScript("OnClick", function(self)
            BetterUpgradeTooltipDB[key] = self:GetChecked()
        end)

        return cb
    end

    ------------------------------------------------------------
    -- Checkboxes
    ------------------------------------------------------------
    CreateCheckbox("Color upgrade rank", "colorRank", -60)
    CreateCheckbox("Color item level range", "colorRange", -90)
    CreateCheckbox("Show crest requirement", "showUpgradeCurrency", -120)

    ------------------------------------------------------------
    -- Item level range color swatch (clickable)
    ------------------------------------------------------------
    local colorBox = CreateFrame("Button", nil, frame)
    colorBox:SetSize(18, 18)
    colorBox:SetPoint("TOPLEFT", 22, -160)

    local border = colorBox:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0, 0, 0, 1)

    local colorTex = colorBox:CreateTexture(nil, "ARTWORK")
    colorTex:SetPoint("TOPLEFT", 0, 0)
    colorTex:SetPoint("BOTTOMRIGHT", 0, 0)

    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", colorBox, "RIGHT", 8, 0)
    label:SetText("Item level range color")

    local resetBtn = CreateFrame("Button", nil, frame)
    resetBtn:SetSize(14, 14)
    resetBtn:SetPoint("LEFT", label, "RIGHT", 8, 0)
    resetBtn:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
    resetBtn:SetPushedTexture("Interface\\Buttons\\UI-RefreshButton")
    resetBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    -- Flip horizontally
    local normalTex = resetBtn:GetNormalTexture()
    if normalTex then normalTex:SetTexCoord(1, 0, 0, 1) end
    local pushedTex = resetBtn:GetPushedTexture()
    if pushedTex then pushedTex:SetTexCoord(1, 0, 0, 1) end

    resetBtn:SetScript("OnClick", function()
        BetterUpgradeTooltipDB.ilvlRangeColor = {1, 1, 1, 1}
        if colorTex then colorTex:SetColorTexture(1, 1, 1, 1) end
        if UpdateSwatch then UpdateSwatch() end
    end)
    resetBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reset color to default (#FFFFFF)")
    end)
    resetBtn:SetScript("OnLeave", GameTooltip_Hide)

    local function UpdateSwatch()
        local r, g, b, a = unpack(BetterUpgradeTooltipDB.ilvlRangeColor or {1,1,1,1})
        colorTex:SetColorTexture(r, g, b, a or 1)
    end

    UpdateSwatch()

    local function ShowColorPicker(r, g, b, a, callback)
        -- Only preview changes while the picker is open. Persist on OK (picker close without cancel).
        local canceled = false

        local function OnColorChanged()
            local newR, newG, newB = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
            local newA = ColorPickerFrame.Content.ColorPicker:GetColorAlpha()
            -- update preview only
            colorTex:SetColorTexture(newR, newG, newB, newA or 1)
        end

        local function OnCancel(previousValues)
            canceled = true
            -- revert preview to previous (if provided) or saved value
            if previousValues and #previousValues >= 3 then
                local pr, pg, pb, pa = unpack(previousValues)
                colorTex:SetColorTexture(pr, pg, pb, pa or 1)
            else
                local pr, pg, pb, pa = unpack(BetterUpgradeTooltipDB.ilvlRangeColor or {1,1,1,1})
                colorTex:SetColorTexture(pr, pg, pb, pa or 1)
            end
        end

        local options = {
            swatchFunc  = OnColorChanged,
            opacityFunc = OnColorChanged,
            cancelFunc  = OnCancel,
            hasOpacity  = true,
            opacity     = a or 1,
            r           = r or 1,
            g           = g or 1,
            b           = b or 1,
        }

        -- Hook OnHide to detect OK (closed without cancel) and persist selection
        local prevOnHide = ColorPickerFrame:GetScript("OnHide")
        ColorPickerFrame:SetScript("OnHide", function(self)
            -- preserve previous onhide behavior
            if prevOnHide then
                pcall(prevOnHide, self)
            end

            if not canceled then
                local finalR, finalG, finalB = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
                local finalA = ColorPickerFrame.Content.ColorPicker:GetColorAlpha()
                if callback then
                    callback(finalR, finalG, finalB, finalA)
                end
            end

            -- restore original OnHide
            ColorPickerFrame:SetScript("OnHide", prevOnHide)
        end)

        ColorPickerFrame:SetupColorPickerAndShow(options)
    end

    colorBox:SetScript("OnClick", function()
        local r, g, b, a = unpack(BetterUpgradeTooltipDB.ilvlRangeColor or {1,1,1,1})

        ShowColorPicker(r, g, b, a, function(nr, ng, nb, na)
            BetterUpgradeTooltipDB.ilvlRangeColor = {nr, ng, nb, na}
            UpdateSwatch()
        end)
    end)

    ------------------------------------------------------------
    -- Register canvas category
    ------------------------------------------------------------
    local category = Settings.RegisterCanvasLayoutCategory(frame, "BetterUpgradeTooltip")
    Settings.RegisterAddOnCategory(category)
end
