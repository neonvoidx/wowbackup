local addon = _G.EnhanceQoL
local Reminder = addon.ClassBuffReminder

function Reminder:OpenTrackerMatrix()
	local app = addon.ConfigApp
	local pageID = app and app.legacySections and app.legacySections[self.settingsSection]
	if addon.functions and addon.functions.OpenConfigCenter then addon.functions.OpenConfigCenter(pageID, "ClassBuffReminderClassTable") end
end
