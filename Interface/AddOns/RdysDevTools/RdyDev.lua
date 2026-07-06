local addonName, _ = ...
local RdysCrateTracker = LibStub("AceAddon-3.0"):GetAddon("RdysCrateTracker", true)
if not RdysCrateTracker then
    error("RdysCrateTracker addon not found. Please ensure it is loaded.")
end

local RCT = RdysCrateTracker




do
    local origChatCommand = RCT.ChatCommand
    function RCT:ChatCommand(input)
        if not self.db.profile.enable then
            self:Print("HatedGaming Crate Tracker is currently disabled.")
            return
        end

        if self.db.profile.notPvp then
            self:Print("HatedGaming Crate Tracker is disabled in PvP/instances.")
            return
        end

        -- If user typed /rct with no args, we want to extend the toggle
        if input == "" or not input then
            -- Check BEFORE running the original
            local wasShown = self.titlepanel:IsShown()

            -- Run original command logic
            origChatCommand(self, input)

            -- Now sync your dev frames
            if wasShown then
                -- It was visible, so now it just got hidden
                RdysCrateTracker.HideAllFramesDev()
            else
                -- It was hidden, so now it just got shown
                RdysCrateTracker.ShowAllFramesDev()
            end

            return
        end

        -- For all other commands, just run the original
        origChatCommand(self, input)
    end
end


RCT.titlepanel.close:HookScript("OnMouseUp", function()
    RCT:HideAllFramesDev()
end)
