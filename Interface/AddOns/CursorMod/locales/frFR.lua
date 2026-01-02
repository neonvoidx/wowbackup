if GetLocale() ~= "frFR" then
	return
end

local _, ns = ...
local L = ns.L

L["author"] = "Auteur"
L["%s Configuration"] = "%s Configuration"
L["Profile"] = "Profil"
L["New profile"] = "Nouveau profile"
L["Create"] = "Créer"
L["Copy current"] = "Copiez l'actuel"
L["Set as default"] = "Définir par défaut"
L["A profile with the same name exists."] = "Un profil portant le même nom existe."
L["Are you sure you want to delete profile %s?"] = "Êtes-vous sûr de vouloir supprimer le profil %s ?"
-- L["Resize cursor"] = ""
-- L["Autoscaling"] = ""
-- L["Scale"] = ""
-- L["Opacity"] = ""
-- L["Use class color"] = ""
-- L["Show only in combat"] = ""
-- L["Cursor freelook start delta"] = ""