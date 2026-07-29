
-- Register Addon Table --
--------------------------
    ConsoleVariableManagerAddon = {}
    local Addon = ConsoleVariableManagerAddon
    local AddonName = "Console Variable Manager"
    local AddonFileName = "ConsoleVariableManager"
    if not CVM_SETTINGS or next(CVM_SETTINGS) == nil then
        CVM_SETTINGS = CVM_SETTINGS or {}
    end

-- Colors --
------------
    Addon.b = "\124cnBATTLENET_FONT_COLOR:"
    Addon.dg = "\124cFF40BC40"
    Addon.g = "\124cFF3CE13F"
    Addon.n = "\124cnNORMAL_FONT_COLOR:"
    Addon.o = "\124cnORANGE_FONT_COLOR:"
    Addon.r = "\124cnWARNING_FONT_COLOR:"
    Addon.p = "\124cnTRANSMOGRIFY_FONT_COLOR:"
    Addon.w = "\124cnWHITE_FONT_COLOR:"
    Addon.y = "\124cnPASSIVE_SPELL_FONT_COLOR:"
    Addon.ly = "\124cnLIGHTYELLOW_FONT_COLOR:"
    Addon.bw = "\124cnPAPER_FRAME_EXPANDED_COLOR:"

-- Truncate Text --
-------------------
    local function TruncateTextWithColor(label, labelColor, text, textColor, maxLength)
        if #text > maxLength then
            return labelColor .. label .. "|r" .. textColor .. text:sub(1, maxLength) .. "..." .. "|r"
        else
            return labelColor .. label .. "|r" .. textColor .. text .. "|r"
        end
    end

    local function TruncateText(text, maxLength)
        if #text > maxLength then
            return text:sub(1, maxLength) .. "..."
        else
            return text
        end
    end

-- Remove Trailing Zeros --
---------------------------
    local function removeTrailingZeros(value)
        local numberValue = tonumber(value)
        if not numberValue then
            return value
        end
        local formatted = string.format("%.10f", numberValue)
        formatted = formatted:match("(.-)%.?0*$")
        return formatted
    end

-- Category Names --
--------------------
    local CategoryNames = {
        [0] = "Debug",
        [1] = "Graphics",
        [2] = "Console",
        [3] = "Combat",
        [4] = "Game",
        [5] = "Default",
        [6] = "Net",
        [7] = "Sound",
        [8] = "GM",
        [9] = "None",
    }

-- Apply CVar Settings --
-------------------------
    function Addon:ApplyCVarSettings(setting, value, caller)
        if type(setting) == "table" then
            for cvar, tableValue in pairs(setting) do
                local currentValue = C_CVar.GetCVar(cvar)
                if tostring(currentValue) ~= tostring(tableValue) then
                    C_CVar.SetCVar(cvar, tableValue)
                end
            end
        elseif type(setting) == "string" then
            local currentValue = C_CVar.GetCVar(setting)
            if tostring(currentValue) ~= tostring(value) then
                C_CVar.SetCVar(setting, value)
            end
        end
    end

-- Developer Console --
-----------------------
    function Addon:OpenDeveloperConsole()
        -- Blizzard_Console only captures output from the moment it is loaded,
        -- so it must be loaded/shown before the command executes.
        if not DeveloperConsole then
            local loadAddOn = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
            if loadAddOn then
                pcall(loadAddOn, "Blizzard_Console")
            end
        end
        if DeveloperConsole then
            DeveloperConsole:Toggle(true)
            return true
        end
        return false
    end

-- Dump CVars --
----------------
    function Addon:DumpCVars()
        Addon.CVars = {}
        local commands = ConsoleGetAllCommands()
        for _, info in pairs(commands) do
            local command = info.command
            if command then
                local isSecure = false
                if info.commandType == 0 then
                    local fn = (C_CVar and C_CVar.GetCVarInfo) or GetCVarInfo
                    if fn then
                        local _, _, _, secureCVar = fn(command)
                        isSecure = secureCVar == true
                    end
                end
                Addon.CVars[command] = {
                    category = info.category,
                    commandType = info.commandType,
                    description = info.help,
                    scriptContents = info.scriptContents,
                    scriptParameters = info.scriptParameters,
                    defaultValue = C_CVar.GetCVarDefault(command),
                    isSecure = isSecure,
                }
            end
        end
    end

-- Hyperframe Managed CVars --
------------------------------
    function Addon:GetHyperframeCVars()
        -- Hyperframe keeps its tables in a private namespace; its SavedVariables
        -- backup (HF_BACKUP.Baseline) holds every CVar the addon manages.
        if type(HF_BACKUP) ~= "table" or type(HF_BACKUP.Baseline) ~= "table" then return nil end

        local set = {}
        for name in pairs(HF_BACKUP.Baseline) do
            if type(name) == "string" then set[name:lower()] = true end
        end

        if next(set) == nil then return nil end
        return set
    end

-- CVar Viewer --
-----------------
    function Addon.CreateUI()
        if HFP_CVarViewerFrame then return end

        Addon:DumpCVars()

        local ROW_HEIGHT = 25
        local POOL_SIZE = 26

        local frame = CreateFrame("Frame", "HFP_CVarViewerFrame", UIParent, "BasicFrameTemplateWithInset")
        frame:SetSize(1000, 600)
        frame:SetPoint("CENTER")
        frame:SetFrameLevel(9997)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:EnableKeyboard(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, -1)
        frame.title:SetText(Addon.p .. "Console Variable Manager")

        local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        searchBox:SetSize(872, 20)
        searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -32)
        searchBox:SetAutoFocus(false)

        if CVM_SETTINGS.RememberLastSearch and CVM_SETTINGS.LastSearch then
            searchBox:SetText(CVM_SETTINGS.LastSearch)
        else
            searchBox:SetText("Search...")
        end

        searchBox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 5)
            GameTooltip:SetText(Addon.ly .. "Search Filters")
            local filters = {
                { "Keyword", "Returns all console variables that contain the keyword in their name, category, or description." },
                { "Modified / NotDefault", "Returns all console variables that are not set to their default value." },
                { "Default", "Returns all console variables that are set to their default value." },
                { "CVars", "Returns only console variables (excludes console commands)." },
                { "Commands", "Returns only console commands (the pink entries)." },
                { "Combat / Secure", "Returns console variables that cannot be modified in combat." },
                { "Hyperframe", "Returns all console variables managed by the Hyperframe addon, if installed." },
            }
            for _, f in ipairs(filters) do
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(Addon.b .. f[1] .. "\n" .. Addon.w .. f[2], nil, nil, nil, true)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(Addon.r .. "Console commands cannot be modified and are displayed in pink.", nil, nil, nil, true)
            GameTooltip:Show()
        end)
        searchBox:SetScript("OnLeave", GameTooltip_Hide)

        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -62)
        scrollFrame:SetPoint("BOTTOMRIGHT", -34, 8)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(952, 1)
        scrollFrame:SetScrollChild(content)

        local copyEditBox = CreateFrame("EditBox", nil, UIParent, "InputBoxTemplate")
        copyEditBox:SetSize(200, 40)
        copyEditBox:SetFrameLevel(10001)
        copyEditBox:SetAutoFocus(false)
        copyEditBox:SetJustifyH("CENTER")
        copyEditBox:Hide()
        copyEditBox:SetScript("OnEditFocusLost", function(self) self:Hide() end)
        copyEditBox:SetScript("OnLeave", function(self) self:Hide() end)
        copyEditBox:SetScript("OnKeyDown", function(self, key)
            if IsControlKeyDown() and key == "C" then self:Hide() end
        end)

        local rowPool = {}
        for i = 1, POOL_SIZE do
            local row = { command = nil, data = nil, editBoxPlaceholder = nil }

            row.frame = CreateFrame("Frame", nil, content)
            row.frame:SetSize(952, ROW_HEIGHT)
            row.frame:Hide()

            row.commandText = row.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.commandText:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 10, -4)
            row.commandText:SetJustifyH("LEFT")
            row.commandText:EnableMouse(true)

            row.defaultValueText = row.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.defaultValueText:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 250, -4)
            row.defaultValueText:SetJustifyH("LEFT")

            row.categoryText = row.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.categoryText:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 399, -4)
            row.categoryText:SetJustifyH("LEFT")

            row.descriptionText = row.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.descriptionText:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 550, -4)
            row.descriptionText:SetJustifyH("LEFT")
            row.descriptionText:EnableMouse(true)

             row.inputBox = CreateFrame("EditBox", nil, row.frame, "InputBoxTemplate")
             row.inputBox:SetSize(100, 20)
             row.inputBox:SetPoint("TOPRIGHT", row.frame, "TOPRIGHT", -68, -2)
             row.inputBox:SetAutoFocus(false)
             row.inputBox:SetJustifyH("CENTER")
             row.inputBox:Hide()

             -- Reset button for CVars
             row.resetButton = CreateFrame("Button", nil, row.frame, "UIPanelButtonTemplate")
             row.resetButton:SetSize(60, 20)
             row.resetButton:SetPoint("TOPRIGHT", row.frame, "TOPRIGHT", -2, -2)
             row.resetButton:SetText("Reset")
             row.resetButton:Hide()
             row.resetButton:SetScript("OnClick", function(self)
                 local cmd = row.command
                 local d = row.data
                 if not cmd or not d then return end
                 local defaultValue = d.defaultValue
                 if defaultValue == nil then return end
                 if InCombatLockdown() and d.isSecure then
                     print("|c00ffff00[|cffdd70ddCVM|c00ffff00]: " .. Addon.r .. "Cannot reset secure CVar while in combat.")
                     return
                 end
                 C_CVar.SetCVar(cmd, defaultValue)
                 print("|c00ffff00[|cffdd70ddCVM|c00ffff00]: Reset |c00ffffff" .. cmd .. "|c00ffff00 to default value.")

                 C_Timer.After(0.25, function()
                     if row.command ~= cmd then return end  -- row was recycled by scrolling
                     local cleanedNew = removeTrailingZeros(C_CVar.GetCVar(cmd) or "")
                     local cleanedDef = removeTrailingZeros(C_CVar.GetCVarDefault(cmd) or "")
                     if cleanedNew == cleanedDef then
                         row.inputBox:SetText(cleanedNew and (Addon.w .. cleanedNew) or "")
                     else
                         row.inputBox:SetText(cleanedNew and (Addon.r .. cleanedNew) or "")
                     end
                     row.inputBox:SetCursorPosition(0)
                 end)
             end)
             row.resetButton:SetScript("OnEnter", function(self)
                 GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 5)
                 GameTooltip:SetText(Addon.b .. "Reset to Default\n" .. Addon.w .. "Click to reset this CVar to its default value.")
             end)
             row.resetButton:SetScript("OnLeave", GameTooltip_Hide)

            local function ExecuteCommand()
                local cmd = row.command
                if not cmd then return end
                local params = row.inputBox:GetText() or ""
                params = params:gsub("%s*[,;]%s*", " "):match("^%s*(.-)%s*$")
                local fullCommand = cmd
                if params ~= "" then
                    fullCommand = cmd .. " " .. params
                end
                local consoleShown = Addon:OpenDeveloperConsole()
                ConsoleExec(fullCommand)
                print("|c00ffff00[|cffdd70ddCVM|c00ffff00]: Executed console command: |c00ffffff" .. fullCommand)
                if not consoleShown then
                    print("|c00ffff00[|cffdd70ddCVM|c00ffff00]: " .. Addon.r .. "Could not open the developer console to show output.")
                end
            end

            row.executeButton = CreateFrame("Button", nil, row.frame, "UIPanelButtonTemplate")
            row.executeButton:SetSize(60, 20)
            row.executeButton:SetPoint("TOPRIGHT", row.frame, "TOPRIGHT", -2, -2)
            row.executeButton:SetText("Run")
            row.executeButton:Hide()
            row.executeButton:SetScript("OnClick", function(self)
                ExecuteCommand()
            end)
            row.executeButton:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 5)
                GameTooltip:SetText(Addon.b .. "Execute Command\n" .. Addon.w .. "Click to execute this console command.\nOptional parameters can be entered in the text box,\nseparated by , or ;\nThe developer console will open to show the output.")
            end)
            row.executeButton:SetScript("OnLeave", GameTooltip_Hide)

            row.inputBox:SetScript("OnEnter", function(self)
                if not row.data or row.data.commandType == 0 then return end
                GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 5)
                GameTooltip:SetText(Addon.b .. "Command Parameters\n" .. Addon.w .. "Optional. Separate multiple parameters with , or ;")
                local expected = row.data.scriptParameters
                if expected and expected:match("%S") then
                    GameTooltip:AddLine(Addon.b .. "Expected: " .. Addon.w .. expected, nil, nil, nil, true)
                end
                GameTooltip:Show()
            end)
            row.inputBox:SetScript("OnLeave", GameTooltip_Hide)

            row.commandText:SetScript("OnEnter", function()
                if not row.data then return end
                local d = row.data
                GameTooltip:SetOwner(row.commandText, "ANCHOR_CURSOR_RIGHT")
                if d.commandType == 0 then
                    GameTooltip:AddLine(Addon.ly .. row.command, 1, 1, 1)
                else
                    GameTooltip:AddLine(Addon.p .. row.command, 1, 1, 1)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(Addon.b .. "Category: " .. Addon.w .. d.categoryName)
                GameTooltip:AddLine(Addon.b .. "Default Value: " .. Addon.w .. (d.defaultValue or ""))
                GameTooltip:AddLine(Addon.b .. "Current Value: " .. Addon.w .. (C_CVar.GetCVar(row.command) or ""))
                GameTooltip:AddLine(Addon.b .. "Command Type: " .. Addon.w .. tostring(d.commandType or ""))
                GameTooltip:AddLine(Addon.b .. "Script Parameters: " .. Addon.w .. (d.scriptParameters or ""))
                GameTooltip:AddLine(Addon.b .. "Script Contents: " .. Addon.w .. (d.scriptContents or ""))
                if d.isSecure then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(Addon.r .. "Secure CVar: " .. Addon.w .. "Cannot be modified in combat.")
                end
                if d.commandType ~= 0 then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(Addon.r .. "Console Command: " .. Addon.w .. "Cannot be modified with CVM.")
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(Addon.dg .. "Click to Copy (CTRL + C)")
                GameTooltip:Show()
            end)
            row.commandText:SetScript("OnLeave", GameTooltip_Hide)

            row.commandText:SetScript("OnMouseDown", function(self, button)
                if button == "LeftButton" and row.command then
                    copyEditBox:SetText(Addon.r .. row.command)
                    copyEditBox:HighlightText(0, -1)
                    copyEditBox:SetTextInsets(4, 4, 4, 4)
                    local scale = UIParent:GetEffectiveScale()
                    local x, y = GetCursorPosition()
                    copyEditBox:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
                    copyEditBox:Show()
                    copyEditBox:SetFocus()
                end
            end)

            row.descriptionText:SetScript("OnEnter", function()
                if not row.data then return end
                local desc = row.data.description
                if not desc:match("%S") then return end
                GameTooltip:SetOwner(row.descriptionText, "ANCHOR_CURSOR_RIGHT")
                GameTooltip:AddLine(Addon.b .. "Description", 1, 1, 1)
                GameTooltip:AddLine(Addon.w .. desc, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            row.descriptionText:SetScript("OnLeave", GameTooltip_Hide)

            local valueSaved = false
            row.inputBox:SetScript("OnEnterPressed", function(self)
                local cmd = row.command
                if not cmd then return end
                if row.data and row.data.commandType ~= 0 then
                    valueSaved = true
                    ExecuteCommand()
                    self:ClearFocus()
                    return
                end
                local newValue = self:GetText()
                local strippedValue = newValue
                    :gsub("\124c%x%x%x%x%x%x%x%x", "")
                    :gsub("\124cn[%a_]+:", "")
                    :gsub("\124r", "")
                local previousValue = C_CVar.GetCVar(cmd)

                if strippedValue == "" or not strippedValue:match("%S") then
                    self:SetText("")
                    Addon:ApplyCVarSettings(cmd, "")
                else
                    Addon:ApplyCVarSettings(cmd, strippedValue)
                end
                valueSaved = true

                C_Timer.After(0.25, function()
                    local updatedValue = C_CVar.GetCVar(cmd)
                    if updatedValue == previousValue then
                        self:SetText(previousValue or "")
                        print("|c00ffff00[|cffdd70ddCVM|c00ffff00]: " .. Addon.r .. "Failed to update |c00ffffff" .. cmd .. Addon.r .. " due to invalid input.")
                    else
                        local displayValue = (updatedValue == "" and "Empty") or updatedValue
                        print("|c00ffff00[|cffdd70ddCVM|c00ffff00]: Updated |c00ffffff" .. cmd .. "|c00ffff00 to |c00ffffff" .. displayValue .. "|c00ffff00.")
                    end

                    local cleanedNew = removeTrailingZeros(C_CVar.GetCVar(cmd))
                    local cleanedDef = removeTrailingZeros(C_CVar.GetCVarDefault(cmd))
                    if cleanedNew == cleanedDef then
                        self:SetText(cleanedNew and (Addon.w .. cleanedNew) or "")
                    else
                        self:SetText(cleanedNew and (Addon.r .. cleanedNew) or "")
                    end
                end)

                self:ClearFocus()
            end)

            row.inputBox:SetScript("OnEditFocusGained", function(self)
                row.editBoxPlaceholder = self:GetText()
                valueSaved = false
            end)

            row.inputBox:SetScript("OnEditFocusLost", function(self)
                if row.data and row.data.commandType ~= 0 then return end
                if valueSaved then return end
                local value = self:GetText()
                if value == "" or value:match("^%s*$") then
                    self:SetText(row.editBoxPlaceholder or "")
                elseif value ~= row.editBoxPlaceholder then
                    self:SetText(row.editBoxPlaceholder or "")
                    if row.command then
                        print("|c00ffff00[|cffdd70ddCVM|c00ffff00]: You must press the " .. Addon.w .. "Enter" .. "|c00ffff00 key to save the " .. Addon.w .. row.command .. "|c00ffff00 setting.")
                    end
                end
            end)

            rowPool[i] = row
        end

        local sortedData = {}

        local function FilterData(filterText)
            wipe(sortedData)
            local lowerFilter = filterText and filterText:lower()

            local checkNotDefault = lowerFilter == "notdefault" or lowerFilter == "modified"
            local checkDefault    = lowerFilter == "default"
            local checkCommands   = lowerFilter == "commands"
            local checkCVars      = lowerFilter == "cvars"
            local checkSecure     = lowerFilter == "secure" or lowerFilter == "combat"
            local hfpSet
            if lowerFilter == "hyperframe" or lowerFilter == "hf" or lowerFilter == "hyperframeplus" or lowerFilter == "hyperframe+" then
                hfpSet = Addon:GetHyperframeCVars()
            end

            for command, info in pairs(Addon.CVars) do
                local currentValue = C_CVar.GetCVar(command) or ""
                local defaultValue = info.defaultValue or ""
                local categoryName = CategoryNames[info.category] or ""
                local description = info.description or ""

                local include
                if checkNotDefault or checkDefault then
                    local cleanCurrent = tostring(removeTrailingZeros(currentValue))
                    local cleanDefault = tostring(removeTrailingZeros(defaultValue))
                    if checkDefault then
                        include = cleanCurrent == cleanDefault
                    else
                        include = cleanCurrent ~= cleanDefault
                    end
                elseif checkCommands then
                    include = info.commandType ~= 0
                elseif checkCVars then
                    include = info.commandType == 0
                elseif checkSecure then
                    include = info.isSecure == true
                elseif hfpSet then
                    include = hfpSet[command:lower()] ~= nil
                elseif not lowerFilter then
                    include = true
                else
                    include = command:lower():find(lowerFilter, 1, true) ~= nil
                        or defaultValue:lower():find(lowerFilter, 1, true) ~= nil
                        or categoryName:lower():find(lowerFilter, 1, true) ~= nil
                        or description:lower():find(lowerFilter, 1, true) ~= nil
                end

                if include then
                    sortedData[#sortedData + 1] = {
                        command = command,
                        commandLower = command:lower(),
                        commandType = info.commandType,
                        categoryName = categoryName,
                        description = description,
                        defaultValue = defaultValue,
                        cleanedDefault = removeTrailingZeros(defaultValue),
                        currentValue = currentValue,
                        scriptParameters = info.scriptParameters or "",
                        scriptContents = info.scriptContents or "",
                        isSecure = info.isSecure or false,
                    }
                end
            end

            -- Pre-lowercased keys avoid repeated lower() calls during sort comparisons
            table.sort(sortedData, function(a, b)
                return a.commandLower < b.commandLower
            end)

            content:SetHeight(math.max(1, #sortedData * ROW_HEIGHT))
        end

        local function UpdateVisibleRows()
            local scrollOffset = scrollFrame:GetVerticalScroll()
            local topIndex = math.floor(scrollOffset / ROW_HEIGHT)

            for i = 1, POOL_SIZE do
                local dataIndex = topIndex + i
                local row = rowPool[i]

                if dataIndex <= #sortedData then
                    local entry = sortedData[dataIndex]
                    row.command = entry.command
                    row.data = entry

                    row.frame:ClearAllPoints()
                    row.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((dataIndex - 1) * ROW_HEIGHT))

                    if entry.commandType == 0 then
                        if entry.isSecure then
                        row.commandText:SetText(Addon.r .. TruncateText(entry.command, 32))
                        else
                            row.commandText:SetText(Addon.ly .. TruncateText(entry.command, 35))
                        end
                    else
                        row.commandText:SetText(Addon.p .. TruncateText(entry.command, 35))
                    end

                    row.defaultValueText:SetText(TruncateTextWithColor("Default: ", Addon.b, entry.cleanedDefault, Addon.w, 14))
                    row.categoryText:SetText(Addon.b .. "Category: " .. Addon.w .. entry.categoryName)
                    row.descriptionText:SetText(TruncateTextWithColor("Description: ", Addon.b, entry.description, Addon.w, 22))

                    if entry.commandType == 0 then
                        local cleanedValue = removeTrailingZeros(C_CVar.GetCVar(entry.command) or "")
                        if cleanedValue ~= entry.cleanedDefault then
                            row.inputBox:SetText(Addon.r .. (cleanedValue or ""))
                        else
                            row.inputBox:SetText(cleanedValue or "")
                        end
                        row.inputBox:SetCursorPosition(0)
                        row.inputBox:Show()
                        row.resetButton:Show()
                        row.executeButton:Hide()
                    else
                        row.inputBox:SetText("")
                        row.inputBox:Show()
                        row.resetButton:Hide()
                        row.executeButton:Show()
                    end

                    row.frame:Show()
                else
                    row.command = nil
                    row.data = nil
                    row.frame:Hide()
                end
            end
        end

        scrollFrame:HookScript("OnVerticalScroll", function(self, offset)
            UpdateVisibleRows()
        end)

        local rememberSearchCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        rememberSearchCheckbox:SetPoint("LEFT", searchBox, "RIGHT", 0, 0)

        local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        refreshButton:SetSize(23, 22)
        refreshButton:SetPoint("RIGHT", rememberSearchCheckbox, "RIGHT", 20, 1)

        local tex = refreshButton:CreateTexture(nil, "ARTWORK")
        tex:SetSize(10, 10)
        tex:SetPoint("CENTER", refreshButton, "CENTER", 0, -1)
        tex:SetTexture("Interface\\Buttons\\UI-RefreshButton")
        refreshButton:SetNormalTexture(tex)

        refreshButton:SetScript("OnClick", function()
            Addon:DumpCVars()
            local currentSearch = searchBox:GetText()
            if currentSearch == "" or currentSearch == "Search..." then
                FilterData(nil)
            else
                FilterData(currentSearch)
            end
            scrollFrame:SetVerticalScroll(0)
            UpdateVisibleRows()
        end)

        refreshButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 5)
            GameTooltip:SetText(Addon.b .. "Refresh CVar List\n" .. Addon.w .. "Click to reload CVars and update their displayed values.")
        end)
        refreshButton:SetScript("OnLeave", GameTooltip_Hide)

        rememberSearchCheckbox:SetChecked(CVM_SETTINGS.RememberLastSearch or false)
        rememberSearchCheckbox:SetScript("OnClick", function(self)
            CVM_SETTINGS.RememberLastSearch = self:GetChecked()
        end)
        rememberSearchCheckbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 5)
            GameTooltip:SetText(Addon.b .. "Remember Last Search\n" .. Addon.w .. "When enabled, your last search will be saved and\nrestored when reopening the CVar Viewer.")
        end)
        rememberSearchCheckbox:SetScript("OnLeave", GameTooltip_Hide)

        local pendingSearch = nil
        searchBox:SetScript("OnTextChanged", function(self)
            local text = self:GetText()
            pendingSearch = text
            C_Timer.After(0.3, function()
                if pendingSearch ~= text then return end
                pendingSearch = nil
                if text == "" or text == "Search..." then
                    FilterData(nil)
                else
                    FilterData(text)
                    if CVM_SETTINGS.RememberLastSearch then
                        CVM_SETTINGS.LastSearch = text
                    end
                end
                scrollFrame:SetVerticalScroll(0)
                UpdateVisibleRows()
            end)
        end)

        local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        clearButton:SetText("x")
        clearButton:SetSize(23, 22)
        clearButton:SetPoint("LEFT", refreshButton, "RIGHT", 1, 0)
        clearButton:SetFrameLevel(9999)
        clearButton:SetScript("OnClick", function()
            rememberSearchCheckbox:SetChecked(false)
            CVM_SETTINGS.RememberLastSearch = false
            pendingSearch = nil
            searchBox:SetText("Search...")
            FilterData(nil)
            scrollFrame:SetVerticalScroll(0)
            UpdateVisibleRows()
        end)
        clearButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 5)
            GameTooltip:SetText(Addon.b .. "Clear Search\n" .. Addon.w .. "Click to clear the search box and resets the list.")
        end)
        clearButton:SetScript("OnLeave", GameTooltip_Hide)

        local consoleButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        consoleButton:SetText(">_")
        consoleButton:SetSize(23, 22)
        consoleButton:SetPoint("LEFT", clearButton, "RIGHT", 1, 0)
        consoleButton:SetFrameLevel(9999)
        consoleButton:SetScript("OnClick", function()
            if not Addon:OpenDeveloperConsole() then
                print("|c00ffff00[|cffdd70ddCVM|c00ffff00]: " .. Addon.r .. "Could not open the developer console.")
            end
        end)
        consoleButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 5)
            GameTooltip:SetText(Addon.b .. "Developer Console\n" .. Addon.w .. "Click to open the in-game developer console (/console),\nwhere console command output is displayed.")
        end)
        consoleButton:SetScript("OnLeave", GameTooltip_Hide)

        frame:SetScript("OnHide", function(self)
            if CVM_SETTINGS.RememberLastSearch then
                CVM_SETTINGS.LastSearch = searchBox:GetText()
            end
            frame = nil
            Addon.CVars = {}
            wipe(sortedData)
            HFP_CVarViewerFrame = nil
            collectgarbage()
        end)

        frame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                self:Hide()
            end
        end)

        FilterData(nil)
        UpdateVisibleRows()
        frame:Show()
    end

-- Slash Command --
-------------------
    SLASH_CVM1 = "/cvm"
    SlashCmdList["CVM"] = function(msg, editBox)
        if InCombatLockdown() then
            print("|c00ffff00[|cffdd70ddCVM|c00ffff00]: " .. Addon.r .. "Cannot open while in combat.")
            return
        end
        Addon.CreateUI()
    end
