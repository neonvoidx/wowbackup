local _, ns = ...
local addon = ns.Addon

function addon:OpenSettings()
    if InCombatLockdown() then
        ns.Addon:Print("Cannot open settings panel while in combat.")
        return
    end

    local id = ns.WilduSettings.SettingsLayout.rootCategory:GetID()
    Settings.OpenToCategory(id)
end

function addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("CooldownManagerCenteredDB", ns.DEFAULT_SETTINGS, true)
    ns.db = self.db

    -- Register database callbacks for profile changes
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
    self.db.RegisterCallback(self, "OnNewProfile", "OnNewProfile")
    self.db.RegisterCallback(self, "OnProfileDeleted", "OnProfileDeleted")

    ns.WilduSettings:RegisterSettings()
    ns.WilduSettings:InitializeSettings()

    local openCooldownViewerSettings = function()
        if CooldownViewerSettings then
            CooldownViewerSettings:ShowUIPanel(false)
        else
            ns.Addon:Print("Cooldown Viewer settings panel not found - you might have Cooldown Manager disabled")
        end
    end

    self:RegisterChatCommand("cds", openCooldownViewerSettings)
    self:RegisterChatCommand("cdm", openCooldownViewerSettings)
    self:RegisterChatCommand("cd", openCooldownViewerSettings)
    self:RegisterChatCommand("wa", openCooldownViewerSettings)
    self:RegisterChatCommand("cmc", function()
        addon:OpenSettings()
    end)
end

function addon:RefreshConfig()
    ns.StyledIcons:Initialize()
    ns.CooldownManager.Initialize()
    ns.Stacks:Initialize()
    ns.Keybinds:Initialize()
    ns.Assistant:Initialize()

    ns.API:RefreshCooldownManager()
    ns.API:ShowReloadUIConfirmation()
    self:Print("Profile settings applied.")
end

function addon:OnNewProfile(event, db, profile)
    self:Print("Created new profile: " .. profile)
end

function addon:OnProfileDeleted(event, db, profile)
    self:Print("Deleted profile: " .. profile)
end

function addon:OnEnable()
    ns.StyledIcons:Initialize()
    ns.CooldownManager.Initialize()
    ns.Stacks:Initialize()
    ns.Keybinds:Initialize()
    ns.Assistant:Initialize()
end
local gameVersion = select(1, GetBuildInfo())
addon.isMidnight = gameVersion:match("^12")
addon.isRetail = gameVersion:match("^11")
