local _, ns = ...

local ProfileSettings = {}
ns.ProfileSettings = ProfileSettings

local SettingsLib = LibStub("WildForkLibEQOLSettingsMode-1.0")

ProfileSettings._pendingExportString = nil
ProfileSettings._pendingImportString = nil
ProfileSettings._copyDialog = nil

local COPY_SECTIONS = {
    {
        key = "general",
        name = "General addon settings",
        desc = "Appearance, fonts, visibility, behavior, and other viewer settings.",
    },
    {
        key = "editMode",
        name = "Edit Mode layout",
        desc = "Positions, sizes, anchors, spacing, and frame-specific layout settings.",
    },
    {
        key = "trackers",
        name = "Custom trackers",
        desc = "Tracker enable state, tracked items and spells, ordering, and tracker count.",
    },
    {
        key = "buffs",
        name = "Buff containers",
        desc = "Container enable state, assignments, ordering, and custom auras.",
    },
    {
        key = "spellStyles",
        name = "Per-spell styles",
        desc = "Individual spell and item appearance overrides.",
    },
}

local playerClassName, playerClassId = UnitClassBase("player")

local classSpecs = {}
local function loadClassSpecs()
    for i = 1, GetNumClasses() do
        for j = 1, 4 do
            local id, name = GetSpecializationInfoForClassID(i, j)
            if id and name then
                classSpecs[i] = classSpecs[i] or {}
                classSpecs[i][j] = name
            end
        end
    end
end

StaticPopupDialogs["CMC_CREATE_NEW_PROFILE"] = {
    text = "Enter a name for the new profile:",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = true,
    maxLetters = 32,
    OnAccept = function(self)
        local editBox = self.editBox or (self.GetEditBox and self:GetEditBox())
        local text = editBox:GetText()
        if text and strtrim(text) ~= "" then
            local trimmed = strtrim(text)
            local profiles = ns.ProfileAPI:GetProfiles()
            local exists = false
            for _, name in ipairs(profiles) do
                if name:lower() == trimmed:lower() then
                    exists = true
                    break
                end
            end
            if exists then
                ns.Addon:Print("A profile with that name already exists.")
            else
                if ns.ProfileAPI:CreateProfile(trimmed) then
                    ns.Addon:Print("Created and switched to profile: " .. trimmed)
                end
            end
        else
            ns.Addon:Print("Please enter a valid profile name.")
        end
    end,
    OnShow = function(self)
        local editBox = self.editBox or (self.GetEditBox and self:GetEditBox())
        editBox:SetText("")
        editBox:SetFocus()
    end,
    EditBoxOnEnterPressed = function(self)
        StaticPopup_OnClick(self:GetParent(), 1)
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["CMC_CONFIRM_DELETE_PROFILE"] = {
    text = "Are you sure you want to delete the profile:\n\n|cffff0000%s|r\n\nThis cannot be undone.",
    button1 = "Delete",
    button2 = "Cancel",
    OnAccept = function(self, profileName)
        if profileName and ns.ProfileAPI:DeleteProfile(profileName) then
            ns.Addon:Print("Deleted profile: " .. profileName)
        else
            ns.Addon:Print("Failed to delete profile.")
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["CMC_EXPORT_PROFILE"] = {
    text = "Copy this export string (Ctrl+C):\n\nProfile: |cff00ff00%s|r",
    button1 = "Close",
    hasEditBox = true,
    editBoxWidth = 350,
    OnShow = function(self, data)
        local exportString = ns.ProfileSettings._pendingExportString or ""
        local editBox = self.editBox or (self.GetEditBox and self:GetEditBox())
        editBox:SetText(exportString)
        editBox:SetFocus()
        editBox:HighlightText()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function CreateCopyProfileDialog()
    local dialog = CreateFrame("Frame", "CMCCopyProfileDialog", UIParent, "BasicFrameTemplateWithInset")
    dialog:SetSize(500, 390)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    dialog:SetClampedToScreen(true)
    dialog:EnableMouse(true)
    dialog:Hide()
    dialog.TitleText:SetText("Copy Profile Settings")

    local intro = dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    intro:SetPoint("TOPLEFT", 24, -42)
    intro:SetPoint("TOPRIGHT", -24, -42)
    intro:SetJustifyH("LEFT")
    intro:SetText("Choose which settings to copy from:")

    local profileName = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    profileName:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -7)
    profileName:SetPoint("TOPRIGHT", intro, "BOTTOMRIGHT", 0, -7)
    profileName:SetJustifyH("LEFT")
    dialog.ProfileName = profileName

    local controls = {}
    local previous
    for _, section in ipairs(COPY_SECTIONS) do
        local check = CreateFrame("CheckButton", nil, dialog, "UICheckButtonTemplate")
        check:SetSize(26, 26)
        if previous then
            check:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -28)
        else
            check:SetPoint("TOPLEFT", profileName, "BOTTOMLEFT", -4, -17)
        end

        local label = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("LEFT", check, "RIGHT", 3, 1)
        label:SetText(section.name)

        local desc = dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
        desc:SetPoint("RIGHT", dialog, "RIGHT", -28, 0)
        desc:SetJustifyH("LEFT")
        desc:SetText(section.desc)

        check:SetScript("OnClick", function()
            dialog.CopyButton:SetEnabled(ProfileSettings:HasCopySelection())
        end)
        controls[section.key] = check
        previous = check
    end
    dialog.Controls = controls

    local copyButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    copyButton:SetSize(110, 24)
    copyButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -5, 14)
    copyButton:SetText("Copy selected")
    dialog.CopyButton = copyButton

    local cancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    cancelButton:SetSize(110, 24)
    cancelButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 5, 14)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        dialog:Hide()
    end)

    copyButton:SetScript("OnClick", function()
        if InCombatLockdown() then
            ns.Addon:Print("Cannot copy profile settings while in combat.")
            return
        end

        local selected = {}
        for _, section in ipairs(COPY_SECTIONS) do
            selected[section.key] = controls[section.key]:GetChecked() == true
        end

        local sourceProfile = tostring(dialog.SourceProfile or "")
        if sourceProfile ~= "" and ns.ProfileAPI:CopyProfile(sourceProfile, selected) then
            ns.Addon:Print("Copied selected settings from profile: " .. sourceProfile .. ".")
            dialog:Hide()
        else
            ns.Addon:Print("Failed to copy profile settings.")
        end
    end)

    dialog:SetScript("OnHide", function()
        dialog.SourceProfile = nil
    end)

    tinsert(UISpecialFrames, dialog:GetName())
    return dialog
end

function ProfileSettings:HasCopySelection()
    local dialog = self._copyDialog
    if not dialog then
        return false
    end
    for _, section in ipairs(COPY_SECTIONS) do
        if dialog.Controls[section.key]:GetChecked() then
            return true
        end
    end
    return false
end

function ProfileSettings:ShowCopyDialog(sourceProfile)
    local dialog = self._copyDialog or CreateCopyProfileDialog()
    self._copyDialog = dialog
    dialog.SourceProfile = sourceProfile
    dialog.ProfileName:SetText("|cff00ff00" .. sourceProfile .. "|r")
    for _, section in ipairs(COPY_SECTIONS) do
        dialog.Controls[section.key]:SetChecked(true)
    end
    dialog.CopyButton:SetEnabled(true)
    dialog:Show()
    dialog:Raise()
end

StaticPopupDialogs["CMC_IMPORT_PROFILE_STRING"] = {
    text = "Paste the profile export string below:",
    button1 = "Next",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 350,
    OnAccept = function(self)
        local editBox = self.editBox or (self.GetEditBox and self:GetEditBox())
        local text = editBox:GetText()
        if text and strtrim(text) ~= "" then
            local data, errorMsg = ns.ProfileAPI:DecodeExportString(text)
            if data then
                ns.ProfileSettings._pendingImportString = text
                StaticPopup_Show("CMC_IMPORT_PROFILE_NAME")
            else
                ns.Addon:Print("|cffff0000Import Error:|r " .. (errorMsg or "Invalid import string."))
            end
        else
            ns.Addon:Print("Please paste a valid export string.")
        end
    end,
    OnShow = function(self)
        local editBox = self.editBox or (self.GetEditBox and self:GetEditBox())
        editBox:SetText("")
        editBox:SetFocus()
    end,
    EditBoxOnEnterPressed = function(self)
        StaticPopup_OnClick(self:GetParent(), 1)
    end,
    EditBoxOnEscapePressed = function(self)
        ns.ProfileSettings._pendingImportString = nil
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["CMC_IMPORT_PROFILE_NAME"] = {
    text = "Enter a name for the imported profile:",
    button1 = "Import",
    button2 = "Cancel",
    hasEditBox = true,
    maxLetters = 32,
    OnAccept = function(self)
        local editBox = self.editBox or (self.GetEditBox and self:GetEditBox())
        local profileName = editBox:GetText()
        local importString = ns.ProfileSettings._pendingImportString

        if not importString then
            ns.Addon:Print("|cffff0000Import Error:|r No import data found.")
            return
        end

        if profileName and strtrim(profileName) ~= "" then
            local trimmed = strtrim(profileName)
            local success, errorMsg = ns.ProfileAPI:ImportFromString(importString, trimmed)
            if success then
                ns.Addon:Print("|cff00ff00Successfully imported profile:|r " .. trimmed)
            else
                ns.Addon:Print("|cffff0000Import Error:|r " .. (errorMsg or "Failed to import profile."))
            end
        else
            ns.Addon:Print("Please enter a valid profile name.")
        end

        ns.ProfileSettings._pendingImportString = nil
    end,
    OnShow = function(self)
        local editBox = self.editBox or (self.GetEditBox and self:GetEditBox())
        editBox:SetFocus()
    end,
    OnCancel = function()
        ns.ProfileSettings._pendingImportString = nil
    end,
    EditBoxOnEnterPressed = function(self)
        StaticPopup_OnClick(self:GetParent(), 1)
    end,
    EditBoxOnEscapePressed = function(self)
        ns.ProfileSettings._pendingImportString = nil
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function ProfileSettings:BuildSettings(parentCategory)
    loadClassSpecs()

    local profileCategory = SettingsLib:CreateCategory(parentCategory, "Profiles", false)
    ns.AddonSettings.SettingsLayout.profileCategory = profileCategory

    SettingsLib:CreateText(profileCategory, {
        name = "Manage your addon profiles.",
    })

    SettingsLib:CreateDropdown(profileCategory, {
        prefix = "CMC_",
        key = "profile_current",
        name = "Active Profile",
        default = "",
        optionfunc = function()
            local profiles = ns.ProfileAPI:GetProfiles()
            local values = {}
            for _, name in ipairs(profiles) do
                values[name] = name
            end
            return values
        end,
        get = function()
            return ns.ProfileAPI:GetCurrentProfile()
        end,
        set = function(value)
            if InCombatLockdown() then
                return
            end
            if value and value ~= ns.ProfileAPI:GetCurrentProfile() then
                ns.ProfileAPI:SetProfile(value)
            end
        end,
    })

    SettingsLib:CreateCheckbox(profileCategory, {
        prefix = "CMC_",
        key = "profile_auto_switch",
        name = "Auto-Switch Profiles",
        desc = "Automatically switch profiles based on your current specialization.",
        get = function()
            return ns.db.global.autoSwitchProfiles or false
        end,
        set = function(value)
            ns.db.global.autoSwitchProfiles = value
            if value then
                ns.ProfileAPI:CheckAutoSwitch()
            end
        end,
    })

    for i = 1, #classSpecs[playerClassId] do
        local _, specName, _, icon = C_SpecializationInfo.GetSpecializationInfo(i)
        SettingsLib:CreateDropdown(profileCategory, {
            prefix = "CMC_",
            key = "profile_auto_switch_spec_" .. i,
            name = "|T" .. icon .. ":16|t " .. specName,
            default = "",
            optionfunc = function()
                local profiles = ns.ProfileAPI:GetProfiles()
                local values = { [""] = "|cffff0000Disable auto switch for " .. specName .. "|r" }
                for _, name in ipairs(profiles) do
                    values[name] = name
                end
                return values
            end,
            get = function()
                return ns.db.global["autoSwitchProfile" .. playerClassId .. "Spec" .. i] or ""
            end,
            set = function(value)
                if value == "" then
                    value = nil
                end
                ns.db.global["autoSwitchProfile" .. playerClassId .. "Spec" .. i] = value
                if ns.db.global.autoSwitchProfiles then
                    ns.ProfileAPI:CheckAutoSwitch()
                end
            end,
        })
    end

    SettingsLib:CreateButton(profileCategory, {
        text = "Create New",
        func = function()
            if InCombatLockdown() then
                return
            end
            StaticPopup_Show("CMC_CREATE_NEW_PROFILE")
        end,
        desc = "Create a new profile with a custom name.",
    })

    SettingsLib:CreateHeader(profileCategory, {
        name = "Import / Export / Copy",
    })

    SettingsLib:CreateButton(profileCategory, {
        text = "Export",
        func = function()
            if InCombatLockdown() then
                return
            end
            local exportString = ns.ProfileAPI:GetExportString()
            if exportString and exportString ~= "" then
                ns.ProfileSettings._pendingExportString = exportString
                local currentProfile = ns.ProfileAPI:GetCurrentProfile()
                StaticPopup_Show("CMC_EXPORT_PROFILE", currentProfile)
            else
                ns.Addon:Print("Failed to generate export string.")
            end
        end,
        desc = "Export current profile as a shareable string.",
    })

    SettingsLib:CreateButton(profileCategory, {
        text = "Import",
        func = function()
            if InCombatLockdown() then
                return
            end
            StaticPopup_Show("CMC_IMPORT_PROFILE_STRING")
        end,
        desc = "Import a profile from an export string.",
    })

    SettingsLib:CreateDropdown(profileCategory, {
        prefix = "CMC_",
        key = "profile_copy",
        name = "Copy from profile:",
        default = "",
        optionfunc = function()
            local profiles = ns.ProfileAPI:GetProfiles()
            local values = { [""] = "Select a profile..." }
            local current = ns.ProfileAPI:GetCurrentProfile()
            for _, name in ipairs(profiles) do
                if name ~= current then
                    values[name] = name
                end
            end
            return values
        end,
        get = function()
            return ""
        end,
        set = function(value)
            if InCombatLockdown() then
                return
            end
            if value and value ~= "" then
                ProfileSettings:ShowCopyDialog(value)
            end
        end,
        desc = "Select a profile, then choose which groups of settings to copy.",
    })

    SettingsLib:CreateHeader(profileCategory, {
        name = "|cffff0000Delete Profile|r",
    })

    SettingsLib:CreateDropdown(profileCategory, {
        prefix = "CMC_",
        key = "profile_delete",
        name = "Select Profile to Delete",
        default = "",
        optionfunc = function()
            local profiles = ns.ProfileAPI:GetProfiles()
            local values = { [""] = "Select a profile..." }
            local current = ns.ProfileAPI:GetCurrentProfile()
            for _, name in ipairs(profiles) do
                if name ~= current then
                    values[name] = name
                end
            end
            return values
        end,
        get = function()
            return ""
        end,
        set = function(value)
            if InCombatLockdown() then
                return
            end
            if value and value ~= "" then
                StaticPopup_Show("CMC_CONFIRM_DELETE_PROFILE", value, nil, value)
            end
        end,
        desc = "Select a profile to delete (cannot delete active profile).",
    })
end

EventRegistry:RegisterCallback("PLAYER_SPECIALIZATION_CHANGED", function()
    C_Timer.After(0.5, function() -- Delay to ensure specialization info is updated
        ns.ProfileAPI:CheckAutoSwitch()
    end)
end)

EventRegistry:RegisterCallback("ACTIVE_PLAYER_SPECIALIZATION_CHANGED", function()
    C_Timer.After(0.5, function() -- Delay to ensure specialization info is updated
        ns.ProfileAPI:CheckAutoSwitch()
    end)
end)
