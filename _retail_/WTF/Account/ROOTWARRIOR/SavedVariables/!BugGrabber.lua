
BugGrabberDB = {
["session"] = 3,
["lastSanitation"] = 3,
["errors"] = {
{
["message"] = "Interface/AddOns/FrameSort/WoW/WoWEx.lua:164: attempt to compare local 'spec' (a secret number value, while execution tainted by 'FrameSort')",
["time"] = 1794328121,
["locals"] = "id=1\nspec=<secret number>\n(*temporary)=1\n(*temporary)=<secret number>\n(*temporary)=<secret number>\n(*temporary)=nil\n(*temporary)=\"attempt to compare local 'spec' (a secret number value, while execution tainted by 'FrameSort')\"\nfsLog=nil\nwow=<table>{\n MAX_RAID_MEMBERS=40\n RAID_CLASS_COLORS=<table>\n Enum=<table>\n MAX_PARTY_MEMBERS=4\n SettingsPanel=SettingsPanel <Blizzard_SettingsPanel.xml:4>\n C_Map=<table>\n C_PvP=<table>\n EventRegistry=<table>\n Settings=<table>\n SlashCmdList=<table>\n C_Timer=<table>\n C_TooltipInfo=<table>\n MEMBERS_PER_RAID_GROUP=5\n C_AddOns=<table>\n}\n",
["stack"] = "[Interface/AddOns/FrameSort/WoW/WoWEx.lua]:164: in function <Interface/AddOns/FrameSort/WoW/WoWEx.lua:152>\n[Interface/AddOns/FrameSort/Modules/Inspector.lua]:510: in function 'EnemyUnitSpec'\n[Interface/AddOns/FrameSort/Modules/Macro/Parser.lua]:183: in function 'predicate'\n[Interface/AddOns/FrameSort/Collections/Enumerable.lua]:147: in function 'Nth'\n[Interface/AddOns/FrameSort/Modules/Macro/Parser.lua]:182: in function 'UnitForSelector'\n[Interface/AddOns/FrameSort/Modules/Macro/Parser.lua]:243: in function 'GetNewBody'\n[Interface/AddOns/FrameSort/Modules/Macro/Macro.lua]:37: in function <Interface/AddOns/FrameSort/Modules/Macro/Macro.lua:30>\n[Interface/AddOns/FrameSort/Modules/Macro/Macro.lua]:62: in function <Interface/AddOns/FrameSort/Modules/Macro/Macro.lua:50>\n[Interface/AddOns/FrameSort/Modules/Macro/Macro.lua]:82: in function <Interface/AddOns/FrameSort/Modules/Macro/Macro.lua:75>\n[Interface/AddOns/FrameSort/Modules/Macro/Macro.lua]:127: in function 'Run'\n[Interface/AddOns/FrameSort/Modules/Runner.lua]:172: in function 'callback'\n[Interface/AddOns/FrameSort/Scheduling/Scheduler.lua]:21: in function <Interface/AddOns/FrameSort/Scheduling/Scheduler.lua:15>\n[Interface/AddOns/FrameSort/Scheduling/Scheduler.lua]:99: in function 'ProcessEvent'\n[Interface/AddOns/FrameSort/Modules/EventDispatcher.lua]:38: in function <...terface/AddOns/FrameSort/Modules/EventDispatcher.lua:21>\n",
["session"] = 1,
["counter"] = 15,
},
{
["message"] = "Interface/AddOns/BuyEmAll/BuyEmAll.lua:108: attempt to call a nil value",
["time"] = 1794328216,
["locals"] = "self=<table>{\n itemIndex=1\n preset=1\n lines=<table>\n itemLink=\"|cnIQ7:|Hitem:274272::::::::90:267::14::1:28:4240:::::|h[Amani Equipment Chest]|h|r\"\n available=-1\n price=0\n L=<table>\n itemName=\"Amani Equipment Chest\"\n AtVendor=true\n NPCName=\"Agmera\"\n AltCurrencyMode=false\n itemID=274272\n ConfirmNoItemLink=0\n}\nitemID=274272\ncanFit=0\n(*temporary)=nil\n(*temporary)=274272\n(*temporary)=\"attempt to call a nil value\"\n",
["stack"] = "[Interface/AddOns/BuyEmAll/BuyEmAll.lua]:108: in function 'GetFreeBagSpace'\n[Interface/AddOns/BuyEmAll/BuyEmAll.lua]:191: in function 'MerchantItemButton_OnModifiedClick'\n[Interface/AddOns/BuyEmAll/BuyEmAll.lua]:41: in function <Interface/AddOns/BuyEmAll/BuyEmAll.lua:40>\n[C]: in function 'MerchantItemButton_OnModifiedClick'\n[*MerchantFrame.xml:43_OnClick]:2: in function <[string \"*MerchantFrame.xml:43_OnClick\"]:1>\n",
["session"] = 1,
["counter"] = 1,
},
},
}
