if GetLocale() ~= "itIT" then
	return
end

local _, ns = ...
local L = ns.L

L["author"] = "Autore"
L["%s Configuration"] = "Configurazione %s"
L["Profile"] = "Profilo"
L["New profile"] = "Nuovo profilo"
L["Create"] = "Crea"
L["Copy current"] = "Copia attuale"
L["Set as default"] = "Imposta come predefinito"
L["A profile with the same name exists."] = "Esiste un profilo con lo stesso nome."
L["Are you sure you want to delete profile %s?"] = "Sei sicuro di voler eliminare il profilo %s?"
-- L["Resize cursor"] = ""
-- L["Autoscaling"] = ""
-- L["Scale"] = ""
-- L["Opacity"] = ""
-- L["Use class color"] = ""
-- L["Show only in combat"] = ""
-- L["Cursor freelook start delta"] = ""