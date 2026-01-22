if GetLocale() ~= "zhCN" then
	return
end

local _, ns = ...
local L = ns.L

L["author"] = "作者"
L["%s Configuration"] = "%s 配置"
L["Profile"] = "配置"
L["New profile"] = "新建配置"
L["Create"] = "创建"
L["Copy current"] = "复制当前配置"
L["Set as default"] = "设为默认值"
L["A profile with the same name exists."] = "存在同名的配置文件。"
L["Are you sure you want to delete profile %s?"] = "你确定要删除配置文件 %s 吗？"
--L["Resize cursor"] = ""
--L["Autoscaling"] = ""
--L["Scale"] = ""
--L["Opacity"] = ""
--L["Use class color"] = ""
--L["Show only in combat"] = ""
--L["Show always"] = ""
--L["Cursor freelook start delta"] = ""
