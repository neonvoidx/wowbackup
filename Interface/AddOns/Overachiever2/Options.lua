-- Overachiever2: Options
-- Modern Options UI using Settings API

local addonName, ns = ...

local Utils = Overachiever2.Utils

-- Default settings
local function SetDefaultSettings()
    Overachiever2_Settings = Overachiever2_Settings or {}
    if Overachiever2_Settings.Debug == nil then
        Overachiever2_Settings.Debug = false
    end
    if Overachiever2_Settings.EnableNPCTooltip == nil then
        Overachiever2_Settings.EnableNPCTooltip = true
    end
    if Overachiever2_Settings.EnableItemTooltip == nil then
        Overachiever2_Settings.EnableItemTooltip = true
    end
    if Overachiever2_Settings.EnableAchievementTooltip == nil then
        Overachiever2_Settings.EnableAchievementTooltip = true
    end
    if Overachiever2_Settings.EnableAchievementWindowTooltip == nil then
        Overachiever2_Settings.EnableAchievementWindowTooltip = true
    end
    if Overachiever2_Settings.EnableChatHoverAchievementTooltip == nil then
        Overachiever2_Settings.EnableChatHoverAchievementTooltip = true
    end
    if Overachiever2_Settings.EnableChatClickAchievementTooltip == nil then
        Overachiever2_Settings.EnableChatClickAchievementTooltip = true
    end
    if Overachiever2_Settings.EnableMiddleClickOpenAchievement == nil then
        Overachiever2_Settings.EnableMiddleClickOpenAchievement = true
    end
    if Overachiever2_Settings.EnableTrackedAchievementTooltip == nil then
        Overachiever2_Settings.EnableTrackedAchievementTooltip = true
    end
    if Overachiever2_Settings.AchWindowTooltipAnchor == nil then
        Overachiever2_Settings.AchWindowTooltipAnchor = "ANCHOR_RIGHT"
    end
    if Overachiever2_Settings.TrackedTooltipAnchor == nil then
        Overachiever2_Settings.TrackedTooltipAnchor = "ANCHOR_LEFT"
    end
    if Overachiever2_Settings.RestoreLastView == nil then
        Overachiever2_Settings.RestoreLastView = true
    end
    if Overachiever2_Settings.EnableHistory == nil then
        Overachiever2_Settings.EnableHistory = true
    end
    if Overachiever2_Settings.HistoryMaxSize == nil then
        Overachiever2_Settings.HistoryMaxSize = 10
    end
    if Overachiever2_Settings.HistoryPersist == nil then
        Overachiever2_Settings.HistoryPersist = true
    end
end

-- Modern Settings API (Retail / 10.0+)
local function RegisterOptions()
    local category, layout = Settings.RegisterVerticalLayoutCategory("Overachiever2")
    Settings.RegisterAddOnCategory(category)

    -- Enable NPC Tooltip checkbox
    do
        local variable = "EnableNPCTooltip"
        local name = ns.L["OPT_NPC_TOOLTIP_TITLE"]
        local tooltip = ns.L["OPT_NPC_TOOLTIP_DESC"]

        local setting = Settings.RegisterProxySetting(category, "Overachiever2_" .. variable,
            Settings.VarType.Boolean, name, Overachiever2_Settings.EnableNPCTooltip,
            function() return Overachiever2_Settings[variable] end,
            function(value) Overachiever2_Settings[variable] = value end)

        Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Enable Item Tooltip checkbox
    do
        local variable = "EnableItemTooltip"
        local name = ns.L["OPT_ITEM_TOOLTIP_TITLE"]
        local tooltip = ns.L["OPT_ITEM_TOOLTIP_DESC"]

        local setting = Settings.RegisterProxySetting(category, "Overachiever2_" .. variable,
            Settings.VarType.Boolean, name, Overachiever2_Settings.EnableItemTooltip,
            function() return Overachiever2_Settings[variable] end,
            function(value) Overachiever2_Settings[variable] = value end)

        Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Enable Achievement Tooltip checkbox (parent)
    local achTooltipInitializer
    do
        local variable = "EnableAchievementTooltip"
        local name = ns.L["OPT_ACH_TOOLTIP_TITLE"]
        local tooltip = ns.L["OPT_ACH_TOOLTIP_DESC"]

        local setting = Settings.RegisterProxySetting(category, "Overachiever2_" .. variable,
            Settings.VarType.Boolean, name, Overachiever2_Settings.EnableAchievementTooltip,
            function() return Overachiever2_Settings[variable] end,
            function(value) Overachiever2_Settings[variable] = value end)

        achTooltipInitializer = Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Blizzard bug workaround: SettingsCheckboxDropdownControlMixin:Init() builds the
    -- dropdown tooltip from initializer:GetName()/GetTooltip() (the checkbox label/desc)
    -- instead of the dropDownLabel/dropDownTooltip fields. This hook re-sets the dropdown
    -- tooltip with the correct values after Init runs.
    hooksecurefunc(SettingsCheckboxDropdownControlMixin, "Init", function(self, initializer)
        local ddLabel = initializer.data.dropDownLabel
        local ddTooltip = initializer.data.dropDownTooltip
        if ddLabel and ddTooltip and self.Control and self.Control.Dropdown then
            local ddSetting = initializer.data.dropdownSetting
            local ddOptions = initializer.data.dropdownOptions
            local fixedTooltip = Settings.CreateOptionsInitTooltip(ddSetting, ddLabel, ddTooltip, ddOptions)
            self.Control.Dropdown:SetTooltipFunc(fixedTooltip)
        end
    end)

    -- Shared dropdown options for tooltip anchor selection
    local function GetAnchorOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("ANCHOR_LEFT", ns.L["OPT_ANCHOR_LEFT"])
        container:Add("ANCHOR_CURSOR", ns.L["OPT_ANCHOR_CURSOR"])
        container:Add("ANCHOR_RIGHT", ns.L["OPT_ANCHOR_RIGHT"])
        return container:GetData()
    end

    -- Sub-option: Achievement Window Tooltip (checkbox + anchor dropdown)
    do
        local cbVariable = "EnableAchievementWindowTooltip"
        local cbSetting = Settings.RegisterProxySetting(category, "Overachiever2_" .. cbVariable,
            Settings.VarType.Boolean, ns.L["OPT_ACH_WINDOW_TOOLTIP_TITLE"],
            Overachiever2_Settings.EnableAchievementWindowTooltip,
            function() return Overachiever2_Settings[cbVariable] end,
            function(value) Overachiever2_Settings[cbVariable] = value end)

        local ddVariable = "AchWindowTooltipAnchor"
        local ddSetting = Settings.RegisterProxySetting(category, "Overachiever2_" .. ddVariable,
            Settings.VarType.String, ns.L["OPT_ANCHOR_TITLE"],
            Overachiever2_Settings.AchWindowTooltipAnchor,
            function() return Overachiever2_Settings[ddVariable] end,
            function(value) Overachiever2_Settings[ddVariable] = value end)

        local initializer = CreateSettingsCheckboxDropdownInitializer(
            cbSetting, ns.L["OPT_ACH_WINDOW_TOOLTIP_TITLE"], ns.L["OPT_ACH_WINDOW_TOOLTIP_DESC"],
            ddSetting, GetAnchorOptions, ns.L["OPT_ANCHOR_TITLE"], ns.L["OPT_ANCHOR_DESC"])
        initializer:SetParentInitializer(achTooltipInitializer, function()
            return Overachiever2_Settings.EnableAchievementTooltip
        end)
        initializer:AddSearchTags(ns.L["OPT_ACH_WINDOW_TOOLTIP_TITLE"])
        layout:AddInitializer(initializer)
    end

    -- Sub-option: Tracked Achievement Tooltip (checkbox + anchor dropdown)
    do
        local cbVariable = "EnableTrackedAchievementTooltip"
        local cbSetting = Settings.RegisterProxySetting(category, "Overachiever2_" .. cbVariable,
            Settings.VarType.Boolean, ns.L["OPT_TRACKED_TOOLTIP_TITLE"],
            Overachiever2_Settings.EnableTrackedAchievementTooltip,
            function() return Overachiever2_Settings[cbVariable] end,
            function(value) Overachiever2_Settings[cbVariable] = value end)

        local ddVariable = "TrackedTooltipAnchor"
        local ddSetting = Settings.RegisterProxySetting(category, "Overachiever2_" .. ddVariable,
            Settings.VarType.String, ns.L["OPT_ANCHOR_TITLE"],
            Overachiever2_Settings.TrackedTooltipAnchor,
            function() return Overachiever2_Settings[ddVariable] end,
            function(value) Overachiever2_Settings[ddVariable] = value end)

        local initializer = CreateSettingsCheckboxDropdownInitializer(
            cbSetting, ns.L["OPT_TRACKED_TOOLTIP_TITLE"], ns.L["OPT_TRACKED_TOOLTIP_DESC"],
            ddSetting, GetAnchorOptions, ns.L["OPT_ANCHOR_TITLE"], ns.L["OPT_ANCHOR_DESC"])
        initializer:SetParentInitializer(achTooltipInitializer, function()
            return Overachiever2_Settings.EnableAchievementTooltip
        end)
        initializer:AddSearchTags(ns.L["OPT_TRACKED_TOOLTIP_TITLE"])
        layout:AddInitializer(initializer)
    end

    -- Sub-option: Chat Hover Tooltip
    do
        local variable = "EnableChatHoverAchievementTooltip"
        local name = ns.L["OPT_CHAT_HOVER_TOOLTIP_TITLE"]
        local tooltip = ns.L["OPT_CHAT_HOVER_TOOLTIP_DESC"]

        local setting = Settings.RegisterProxySetting(category, "Overachiever2_" .. variable,
            Settings.VarType.Boolean, name, Overachiever2_Settings.EnableChatHoverAchievementTooltip,
            function() return Overachiever2_Settings[variable] end,
            function(value) Overachiever2_Settings[variable] = value end)

        local initializer = Settings.CreateCheckbox(category, setting, tooltip)
        initializer:SetParentInitializer(achTooltipInitializer, function()
            return Overachiever2_Settings.EnableAchievementTooltip
        end)
    end

    -- Sub-option: Chat Click Tooltip
    do
        local variable = "EnableChatClickAchievementTooltip"
        local name = ns.L["OPT_CHAT_CLICK_TOOLTIP_TITLE"]
        local tooltip = ns.L["OPT_CHAT_CLICK_TOOLTIP_DESC"]

        local setting = Settings.RegisterProxySetting(category, "Overachiever2_" .. variable,
            Settings.VarType.Boolean, name, Overachiever2_Settings.EnableChatClickAchievementTooltip,
            function() return Overachiever2_Settings[variable] end,
            function(value) Overachiever2_Settings[variable] = value end)

        local initializer = Settings.CreateCheckbox(category, setting, tooltip)
        initializer:SetParentInitializer(achTooltipInitializer, function()
            return Overachiever2_Settings.EnableAchievementTooltip
        end)
    end

    -- Middle-click chat achievement link opens the Achievement UI
    do
        local variable = "EnableMiddleClickOpenAchievement"
        local name = ns.L["OPT_CHAT_MIDDLE_CLICK_OPEN_TITLE"]
        local tooltip = ns.L["OPT_CHAT_MIDDLE_CLICK_OPEN_DESC"]

        local setting = Settings.RegisterProxySetting(category, "Overachiever2_" .. variable,
            Settings.VarType.Boolean, name, Overachiever2_Settings.EnableMiddleClickOpenAchievement,
            function() return Overachiever2_Settings[variable] end,
            function(value) Overachiever2_Settings[variable] = value end)

        Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Restore Last View checkbox
    do
        local variable = "RestoreLastView"
        local name = ns.L["OPT_SESSION_STATE_TITLE"]
        local tooltip = ns.L["OPT_SESSION_STATE_DESC"]

        local setting = Settings.RegisterProxySetting(category, "Overachiever2_" .. variable,
            Settings.VarType.Boolean, name, Overachiever2_Settings.RestoreLastView,
            function() return Overachiever2_Settings[variable] end,
            function(value) Overachiever2_Settings[variable] = value end)

        Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Enable History checkbox (parent)
    local historyInitializer
    do
        local variable = "EnableHistory"
        local name = ns.L["OPT_HISTORY_TITLE"]
        local tooltip = ns.L["OPT_HISTORY_DESC"]

        local setting = Settings.RegisterProxySetting(category, "Overachiever2_" .. variable,
            Settings.VarType.Boolean, name, Overachiever2_Settings.EnableHistory,
            function() return Overachiever2_Settings[variable] end,
            function(value)
                Overachiever2_Settings[variable] = value
                if ns.HistoryOnSettingChanged then
                    ns.HistoryOnSettingChanged()
                end
            end)

        historyInitializer = Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Sub-option: History Max Size (slider)
    do
        local variable = "HistoryMaxSize"
        local name = ns.L["OPT_HISTORY_MAX_TITLE"]
        local tooltip = ns.L["OPT_HISTORY_MAX_DESC"]

        local setting = Settings.RegisterProxySetting(category, "Overachiever2_" .. variable,
            Settings.VarType.Number, name, Overachiever2_Settings.HistoryMaxSize,
            function() return Overachiever2_Settings[variable] end,
            function(value)
                Overachiever2_Settings[variable] = value
                if ns.HistoryOnMaxSizeChanged then
                    ns.HistoryOnMaxSizeChanged()
                end
            end)

        local options = Settings.CreateSliderOptions(5, 50, 1)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, tostring)
        local initializer = Settings.CreateSlider(category, setting, options, tooltip)
        initializer:SetParentInitializer(historyInitializer, function()
            return Overachiever2_Settings.EnableHistory
        end)
    end

    -- Sub-option: Persist across sessions (checkbox)
    do
        local variable = "HistoryPersist"
        local name = ns.L["OPT_HISTORY_PERSIST_TITLE"]
        local tooltip = ns.L["OPT_HISTORY_PERSIST_DESC"]

        local setting = Settings.RegisterProxySetting(category, "Overachiever2_" .. variable,
            Settings.VarType.Boolean, name, Overachiever2_Settings.HistoryPersist,
            function() return Overachiever2_Settings[variable] end,
            function(value) Overachiever2_Settings[variable] = value end)

        local initializer = Settings.CreateCheckbox(category, setting, tooltip)
        initializer:SetParentInitializer(historyInitializer, function()
            return Overachiever2_Settings.EnableHistory
        end)
    end

    -- Sub-option: Keybind rows (Blizzard KeyBindingFrameBindingTemplate)
    -- Render the back/forward history keybinds inline so users can rebind them
    -- without leaving the Overachiever2 options panel. The template reads its
    -- label from _G["BINDING_NAME_"..action] (already localized), so we only
    -- need to supply the binding index.
    do
        local backIdx, forwardIdx
        for i = 1, GetNumBindings() do
            local action = GetBinding(i)
            if action == "OA2_KB_HISTORY_BACK" then
                backIdx = i
            elseif action == "OA2_KB_HISTORY_FORWARD" then
                forwardIdx = i
            end
        end

        local function AddKeybindRow(idx, searchTag)
            if not idx then return end
            local initializer = Settings.CreateElementInitializer(
                "KeyBindingFrameBindingTemplate", { bindingIndex = idx })
            layout:AddInitializer(initializer)
            initializer:SetParentInitializer(historyInitializer, function()
                return Overachiever2_Settings.EnableHistory
            end)
            initializer:AddSearchTags(searchTag)
        end

        AddKeybindRow(backIdx, ns.L["OPT_HISTORY_BACK_KEY_TITLE"])
        AddKeybindRow(forwardIdx, ns.L["OPT_HISTORY_FORWARD_KEY_TITLE"])
    end

    ns.OptionsCategory = category
end

function ns.OpenOptions()
    if not ns.OptionsCategory then return end
    -- Settings.OpenToCategory calls the combat-protected OpenSettingsPanel.
    -- The achievement window can now be opened mid-combat (see History.lua),
    -- so guard this path explicitly.
    if InCombatLockdown() then
        Utils.Print(ERR_AFFECTING_COMBAT)
        return
    end
    Settings.OpenToCategory(ns.OptionsCategory:GetID())
end

function ns.ToggleDebugMode()
    Overachiever2_Settings.Debug = not Overachiever2_Settings.Debug
    local msg = Utils.IsDebugMode() and ns.L["DEBUG_ENABLED"] or ns.L["DEBUG_DISABLED"]
    Utils.Print(msg)
end

-- Initialization
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
    if name == addonName then
        SetDefaultSettings()
        -- Ensure Settings API is available (Retail)
        if Settings and Settings.RegisterAddOnCategory then
            RegisterOptions()
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
