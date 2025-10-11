if GetLocale() ~= "zhTW" then
	return
end

local _, ns = ...
local L = ns.L

L["author"] = "作者"
L["%s Configuration"] = "%s 設定"
L["Profile"] = "設定檔"
L["New profile"] = "新設定檔"
L["Create"] = "建立"
L["Copy current"] = "複製當前的"
L["Set as default"] = "設定為預設"
L["A profile with the same name exists."] = "相同名稱的設定檔已存在。"
L["Are you sure you want to delete profile %s?"] = "你確定要刪除設定檔%s嗎？"
-- L["Resize cursor"] = ""
-- L["Autoscaling"] = ""
-- L["Scale"] = ""
-- L["Opacity"] = ""
-- L["Use class color"] = ""
-- L["Show only in combat"] = ""
-- L["Cursor freelook start delta"] = ""