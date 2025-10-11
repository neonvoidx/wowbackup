-- Load AceAddon, AceConsole, AceEvent, AceGUI, and AceConfig libraries
local AceAddon = LibStub("AceAddon-3.0")
local AceConsole = LibStub("AceConsole-3.0")
local AceEvent = LibStub("AceEvent-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfig = LibStub("AceConfig-3.0")

-- Create a new AceAddon instance
local SilentShuffle = AceAddon:NewAddon("SilentShuffle", "AceConsole-3.0", "AceEvent-3.0")

-- Define addon metadata
local silentShuffleTitle = "|cff00ff88Silent Shuffle|r"
local AddonVersion = C_AddOns.GetAddOnMetadata("SilentShuffle", "Version")

-- Variables for chat control
local setChatDisabled = C_SocialRestrictions.SetChatDisabled
local IsChatDisabled = C_SocialRestrictions.IsChatDisabled

local chatSettingsMemory
enableRatedArena = ...
enableSkirmish = ...

local defaults = {
    profile = {
        enabled            = true,
        chatSettingsMemory = IsChatDisabled(),
        debug              = false,
        enableRatedArena   = false,
        enableSkirmish     = false,
    }
}

-- Variables for instance checking
local IsInInstance = IsInInstance

-- Print welcome message
local welcomeMsg = "%s: Silent Shuffle version |cff00e5ff%s|r loaded successfully"
print(string.format(welcomeMsg, silentShuffleTitle, AddonVersion))

-- Function to handle enabling the addon
function SilentShuffle:EnableAddon()
    print(silentShuffleTitle .. ": Addon Enabled")
end

-- Function to handle disabling the addon
function SilentShuffle:DisableAddon()
    print(silentShuffleTitle .. ": Addon Disabled")
end

-- Function to log debug messages
function SilentShuffle:DebugLog(message)
    if self.db.profile.debug then
        print(silentShuffleTitle .. ": " .. message)
    end
end

function SetLastMatchType(matchType)
   lastMatchType = matchType
end

function GetLastMatchType()
    return lastMatchType
end

function delayedExecution()
    SilentShuffle:OnArenaJoin()
    SilentShuffle:DebugLog("Delayed Execution")
end

function SilentShuffle:ArenaJoinType(matchType)
    if IsChatDisabled() == true and self.db.profile.chatSettingsMemory == true then
        print(silentShuffleTitle .. ": In "..matchType.." - Chat was already Disabled")
    else
        setChatDisabled(true)
        print(silentShuffleTitle .. ": In "..matchType.." - Chat Disabled")
    end
    self:DebugLog("Last Match Type is ".. matchType)
end

-- Function to handle arena join
function SilentShuffle:OnArenaJoin()
    local lastMatch
    self:DebugLog("Joined Arena, Checking if it's Shuffle")
    if not (C_PvP.IsRatedSoloShuffle() or C_PvP.IsRatedArena()) then
        self:DebugLog("Protecting conditions not met")
        self:DebugLog("IsRatedArena(): " .. tostring(C_PvP.IsRatedArena()))
        self:DebugLog("self.db.profile.enableRatedArena: " .. tostring(self.db.profile.enableRatedArena))
        self:DebugLog("IsSkirmish(): " .. tostring(C_PvP.IsArena()))
        self:DebugLog("self.db.profile.enableSkirmish: " .. tostring(self.db.profile.enableSkirmish))
        self:DebugLog("IsSoloShuffle(): ".. tostring(C_PvP.IsRatedSoloShuffle()))
        return
    end

    if C_PvP.IsRatedSoloShuffle() then
        SetLastMatchType("Solo Shuffle")
    elseif C_PvP.IsRatedArena() and self.db.profile.enableRatedArena then
        SetLastMatchType("Arena")
    elseif C_PvP.IsRatedArena() and not self.db.profile.enableRatedArena then 
        SetLastMatchType("Arena")
        self:DebugLog("No action taken")
        return

    end

    lastMatch = GetLastMatchType()
    if lastMatch == nil then
        self:DebugLog("lastMatch is NIL")
        self:DebugLog("IsRatedArena(): " .. tostring(C_PvP.IsRatedArena()))
        self:DebugLog("self.db.profile.enableRatedArena: " .. tostring(self.db.profile.enableRatedArena))
        self:DebugLog("IsSkirmish(): " .. tostring(C_PvP.IsArena()))
        self:DebugLog("self.db.profile.enableSkirmish: " .. tostring(self.db.profile.enableSkirmish))
        return
    else
    self:ArenaJoinType(lastMatch)
    end

     -- Print additional debug information
     self:DebugLog("IsRatedArena(): " .. tostring(C_PvP.IsRatedArena()))
     self:DebugLog("self.db.profile.enableRatedArena: " .. tostring(self.db.profile.enableRatedArena))
     self:DebugLog("IsSkirmish(): " .. tostring(C_PvP.IsArena()))
     self:DebugLog("self.db.profile.enableSkirmish: " .. tostring(self.db.profile.enableSkirmish))
        

end

-- Function to handle arena leave
function SilentShuffle:OnArenaLeave()
    self:DebugLog("Left Arena, Checking arena type")
    local lastMatch = GetLastMatchType()
    self:DebugLog("Last Match type was " .. lastMatch)
    if C_PvP.IsRatedSoloShuffle() == true or C_PvP.IsRatedArena() == true then
        self:DebugLog("Protective conditions are not met")
        return
    end
    if lastMatch == "Solo Shuffle" or lastMatch == "Rated Arena" or lastMatch == "Arena" then
        setChatDisabled(false)
        print(silentShuffleTitle .. ": Not in ".. lastMatch .. " - Chat restored to previous settings")
        SetLastMatchType(nil)
    end
end

-- Function to open the configuration GUI
function SilentShuffle:OpenConfig()
    AceConfigDialog:Open("SilentShuffle")
end

-- Refresh runtime state from profile (called on profile change)
function SilentShuffle:RefreshFromProfile()
    if not self.db or not self.db.profile then return end
    -- Ensure chatSettingsMemory exists in profile; if not seed it now
    if self.db.profile.chatSettingsMemory == nil then
        self.db.profile.chatSettingsMemory = IsChatDisabled()
    end
    -- restore chat memory if desired at login (you already do this in OnInitialize)
    -- chatSettingsMemory runtime var is also kept for convenience:
    chatSettingsMemory = self.db.profile.chatSettingsMemory
end

-- Function to test C_PvP API calls with temporary debug mode
function SilentShuffle:TestPvPAPICalls()
    -- Store current debug state
    local originalDebugState = self.db.profile.debug

    -- Enable debug mode
    self.db.profile.debug = true
    self:DebugLog("Testing C_PvP API Calls... (Debug mode temporarily enabled)")

    local isRatedSoloShuffle_test = C_PvP.IsRatedSoloShuffle()
    local isRatedArena_test = C_PvP.IsRatedArena()
    local isArena_test = C_PvP.IsArena()
    local isBattleground_test = C_PvP.IsBattleground()
    local isRatedBattleground_test = C_PvP.IsRatedBattleground()

    self:DebugLog("C_PvP.IsRatedSoloShuffle(): " .. tostring(isRatedSoloShuffle_test))
    self:DebugLog("C_PvP.IsRatedArena(): " .. tostring(isRatedArena_test))
    self:DebugLog("C_PvP.IsArena(): " .. tostring(isArena_test))
    self:DebugLog("C_PvP.IsBattleground(): " .. tostring(isBattleground_test))
    self:DebugLog("C_PvP.IsRatedBattleground(): " .. tostring(isRatedBattleground_test))

    -- Restore original debug state
    self.db.profile.debug = originalDebugState
    self:DebugLog("Test completed. Restoring previous debug state: " .. tostring(originalDebugState))
end

-- Function to initialize the addon
function SilentShuffle:OnInitialize()
-- Initialize saved variables
    self.db = LibStub("AceDB-3.0"):New("SilentShuffleDB", defaults, true)
    self:RegisterChatCommand("ssconfig", "OpenConfig")
    self:RegisterChatCommand("sstest", "TestPvPAPICalls") -- New test command
    self:SetConfigHandler()

    if self.db.profile.chatSettingsMemory ~= nil then
        setChatDisabled(self.db.profile.chatSettingsMemory)
    end

    -- Register DB callbacks so profile changes are reflected immediately
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshFromProfile")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshFromProfile")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshFromProfile")

    self:RefreshFromProfile() -- apply profile to runtime vars

    self:DebugLog("Initialized")

    if self.db.profile.enabled then
        print(silentShuffleTitle..": Addon Enabled")
    elseif not self.db.profile.enabled then
        print(silentShuffleTitle..": Addon Disabled")
    end

    -- Register events
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "EventHandler")
    self:RegisterEvent("PLAYER_LOGOUT", "LogoutHandler")
end

-- Set up the configuration handler for AceConfig
-- Function to set up the configuration handler for AceConfig
function SilentShuffle:SetConfigHandler()
    local profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    local options = {
        type = "group",
        inline = false,
        args = {
            enable = {
                type = "toggle",
                name = "Enable Silent Shuffle",
                desc = "Enable or disable Silent Shuffle",
                get = function() return self.db.profile.enabled end,
                set = function(_, val)
                    self.db.profile.enabled = val
                    if val then
                        self:EnableAddon()
                    else
                        self:DisableAddon()
                    end
                end,
                order = 1,
            },
            debug = {
                type = "toggle",
                name = "Enable Debug",
                desc = "Enable or disable debug messages",
                get = function() return self.db.profile.debug end,
                set = function(_, val)
                    self.db.profile.debug = val
                end,
                order = 30,
            },
            enableRatedArena = {
                type = "toggle",
                name = "Enable in Arena",
                desc = "Enable or disable functionality for Arena",
                get = function() return self.db.profile.enableRatedArena end,
                set = function(_, val)
                    self.db.profile.enableRatedArena = val
                end,
                order = 10,
            },
            testAPICalls = { 
                type = "execute",
                name = "Test PvP API",
                desc = "Run the PvP API test function",
                func = function() SilentShuffle:TestPvPAPICalls() end,
                order = 40,
            },
        },
    }
    --options.args.profile = profileOptions
    AceConfig:RegisterOptionsTable("SilentShuffle", options)
    AceConfig:RegisterOptionsTable("SilentShuffle_Profiles", profileOptions)
    AceConfigDialog:AddToBlizOptions("SilentShuffle", "Silent Shuffle")
    AceConfigDialog:AddToBlizOptions("SilentShuffle_Profiles", "Profiles", "Silent Shuffle")
end

-- Event handler function
function SilentShuffle:EventHandler()
    local _, currentInstanceType = IsInInstance()
    if not self.db.profile.enabled then
        self:DebugLog("You disabled the addon from the menu")
         return
    end
    self:DebugLog("Zone Changed..")        
    if self.db.profile.enabled then
        if currentInstanceType == "arena" then
            self:DebugLog(currentInstanceType)
            C_Timer.After(3, delayedExecution)
         elseif currentInstanceType ~= "arena" and self.currentInstanceType == "arena" then
            self:DebugLog("Arena leaving")
            self:OnArenaLeave()
        elseif currentInstanceType == "none" then
            self:DebugLog("Current Instance Type is "..currentInstanceType)
        end
    end
    self.currentInstanceType = currentInstanceType
    self:DebugLog("self.currentInstanceType After updating: "..self.currentInstanceType.." vs. currentInstanceType "..currentInstanceType)
end

-- Logout handler function to restore the value of Chat Disabled obtained during previous login/reload
function SilentShuffle:LogoutHandler()
    self.db.profile.chatSettingsMemory = IsChatDisabled()
    setChatDisabled(self.db.profile.chatSettingsMemory)
end
