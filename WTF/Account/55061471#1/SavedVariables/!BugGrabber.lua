
BugGrabberDB = {
["session"] = 4696,
["lastSanitation"] = 3,
["errors"] = {
{
["message"] = "[ADDON_ACTION_BLOCKED] AddOn 'BetterBlizzFrames' tried to call the protected function 'StatusBar:SetSize()'.",
["time"] = "2025/11/19 12:34:03",
["locals"] = "self = <table> {\n}\nevent = \"ADDON_ACTION_BLOCKED\"\naddonName = \"BetterBlizzFrames\"\naddonFunc = \"StatusBar:SetSize()\"\nname = \"BetterBlizzFrames\"\nbadAddons = <table> {\n BetterBlizzFrames = true\n}\nL = <table> {\n ADDON_CALL_PROTECTED_MATCH = \"^%[(.*)%] (AddOn '.*' tried to call the protected function '.*'.)$\"\n NO_DISPLAY_2 = \"|cffffff00The standard display is called BugSack, and can probably be found on the same site where you found !BugGrabber.|r\"\n ERROR_DETECTED = \"%s |cffffff00captured, click the link for more information.|r\"\n USAGE = \"|cffffff00Usage: /buggrabber <1-%d>.|r\"\n BUGGRABBER_STOPPED = \"|cffffff00There are too many errors in your UI. As a result, your game experience may be degraded. Disable or update the failing addons if you don't want to see this message again.|r\"\n STOP_NAG = \"|cffffff00!BugGrabber will not nag about missing a display addon again until next patch.|r\"\n ADDON_DISABLED = \"|cffffff00!BugGrabber and %s cannot coexist; %s has been forcefully disabled. If you want to, you may log out, disable !BugGrabber, and enable %s.|r\"\n NO_DISPLAY_STOP = \"|cffffff00If you don't want to be reminded about this again, run /stopnag.|r\"\n NO_DISPLAY_1 = \"|cffffff00You seem to be running !BugGrabber with no display addon to go along with it. Although a slash command is provided for accessing error reports, a display can help you manage these errors in a more convenient way.|r\"\n ERROR_UNABLE = \"|cffffff00!BugGrabber is unable to retrieve errors from other players by itself. Please install BugSack or a similar display addon that might give you this functionality.|r\"\n ADDON_CALL_PROTECTED = \"[%s] AddOn '%s' tried to call the protected function '%s'.\"\n}\n",
["stack"] = "[Interface/AddOns/!BugGrabber/BugGrabber.lua]:583: in function '?'\n[Interface/AddOns/!BugGrabber/BugGrabber.lua]:507: in function <Interface/AddOns/!BugGrabber/BugGrabber.lua:507>\n[C]: in function 'SetSize'\n[Interface/AddOns/BetterBlizzFrames/retail/modules/noPortrait.lua]:2182: in function <...dOns/BetterBlizzFrames/retail/modules/noPortrait.lua:2145>\n[Interface/AddOns/BetterBlizzFrames/retail/modules/noPortrait.lua]:2201: in function <...dOns/BetterBlizzFrames/retail/modules/noPortrait.lua:2198>\n[C]: in function 'ToPlayerArt'\n[Interface/AddOns/Blizzard_UnitFrame/PartyMemberFrame.lua]:160: in function 'UpdateArt'\n[Interface/AddOns/Blizzard_UnitFrame/PartyMemberFrame.lua]:620: in function 'OnEvent'\n[Interface/AddOns/Blizzard_UnitFrame/UnitFrame.lua]:1033: in function <Interface/AddOns/Blizzard_UnitFrame/UnitFrame.lua:1031>",
["session"] = 4696,
["counter"] = 1,
},
},
}
