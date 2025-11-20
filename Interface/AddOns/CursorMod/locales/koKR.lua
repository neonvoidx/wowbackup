if GetLocale() ~= "koKR" then
	return
end

local _, ns = ...
local L = ns.L

L["author"] = "제작자"
L["%s Configuration"] = "%s 설정"
L["Profile"] = "프로필"
L["New profile"] = "새 프로필"
L["Create"] = "생성"
L["Copy current"] = "현재 복사"
L["Set as default"] = "기본으로 설정"
L["A profile with the same name exists."] = "같은 이름의 프로필이 존재합니다."
L["Are you sure you want to delete profile %s?"] = "프로필 %s을 삭제하시겠습니까?"
-- L["Resize cursor"] = ""
-- L["Autoscaling"] = ""
-- L["Scale"] = ""
-- L["Opacity"] = ""
-- L["Use class color"] = ""
-- L["Show only in combat"] = ""
-- L["Cursor freelook start delta"] = ""