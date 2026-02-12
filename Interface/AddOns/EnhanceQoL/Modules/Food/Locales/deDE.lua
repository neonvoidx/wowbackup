local L = LibStub("AceLocale-3.0"):NewLocale("EnhanceQoL_DrinkMacro", "deDE")
if not L then return end

-- Drink
L["Add SpellID"] = "Zauber-ID hinzufügen"
L["allowRecuperate"] = "Gesundung zum Heilen erlauben"
L["allowRecuperateDesc"] = "Ermöglicht Klassen mit dem Zauber Gesundung, sich zu heilen. Dieser Zauber stellt kein Mana wieder her."
L["CategoryCombatPotions"] = "Kampftränke"
L["CategoryCustomSpells"] = "Benutzerdefinierte Zauber"
L["CategoryHealthstones"] = "Gesundheitssteine"
L["CategoryPotions"] = "Tränke"
L["Custom Spells"] = "Benutzerdefinierte Zauber"
L["Drink Macro"] = "Trink Makro"
L["Drinks & Food"] = "Getränke & Speisen"
L["Enable Drink Macro"] = "Trink-Makro aktivieren"
L["Enable Health Macro"] = "Gesundheits-Makro aktivieren"
L["Health Macro"] = "Gesundheits-Makro"
L["healthCustomSpellsHint"] = [=[Wenn du einen Zauber im Dropdown auswählst, wird er entfernt (das Feld bleibt absichtlich leer).
Das Makro nutzt alle benutzerdefinierten Zauber, die du kennst.]=]
L["healthMacroLimitReached"] = "Health-Makro: Makro-Limit erreicht. Bitte einen Slot freigeben."
L["healthMacroPlaceOnBar"] = "%s – auf deine Leiste legen (aktualisiert sich außerhalb des Kampfes)"
L["healthMacroTipReset"] = "Tipp: Damit der Dämonische Gesundheitsstein im Kampf ggf. erneut genutzt werden kann, verwende `reset=60`."
L["healthMacroWillUse"] = "Wird verwenden (in Reihenfolge): %s"
L["mageFoodLeaveText"] = "Begleiter-Dungeon verlassen\\n\\nKlicken, um die Gruppe zu verlassen"
L["mageFoodReminder"] = "Erinnerung anzeigen, um Magier Nahrung aus einem Anhängerdungeon abzuholen"
L["mageFoodReminderDefaultSound"] = "Standardton"
L["mageFoodReminderDesc2"] = [=[Klicke auf die Erinnerung, um automatisch für einen Gefolgschafts-Dungeon anzumelden.
Halte Alt, um das Symbol zu verschieben.]=]
L["mageFoodReminderEditModeHint"] = "Konfiguriere Details der Essens-Erinnerung über den Edit Mode."
L["MageFoodReminderHeadline"] = "Magieressen-Erinnerung für Heiler"
L["mageFoodReminderJoinSound"] = "Beitritts-Sound"
L["mageFoodReminderLeaveSound"] = "Verlassens-Sound"
L["mageFoodReminderReset"] = "Position zurücksetzen"
L["mageFoodReminderSize"] = "Erinnerungsgröße"
L["mageFoodReminderSound"] = "Sound abspielen, wenn Erinnerung erscheint"
L["mageFoodReminderText"] = [=[Mage‑Nahrung aus einem Anhängerdungeon abholen

Klicken, um dich automatisch anzumelden]=]
L["mageFoodReminderUseCustomSound"] = "Eigene Erinnerungssounds verwenden"
L["Minimum mana restore for food"] = "Mindest Manawiederherstellung des Essens"
L["None"] = "Keiner"
L["Prefer Healthstone first"] = "Gesundheitsstein bevorzugen"
L["Prefer mage food"] = "Magier-Essen bevorzugen"
L["PriorityOrder"] = "Prioritätsreihenfolge"
L["PrioritySlot"] = "Priorität %d"
L["Reset condition"] = "Reset-Bedingung"
L["Reset: 10s"] = "Nach 10 s"
L["Reset: 30s"] = "Nach 30 s"
L["Reset: 60s"] = "Nach 60 s"
L["Reset: Combat"] = "Nach Kampfende"
L["Reset: Target"] = "Beim Zielwechsel"
L["Use Combat potions for health macro"] = "Kampftränke für Gesundheitsmakro verwenden"
L["Use custom spells"] = "Benutzerdefinierte Zauber verwenden"
L["Use Recuperate out of combat"] = "Gesundung außerhalb des Kampfes verwenden"
L["useManaPotionInCombat"] = "Manatrank im Kampf verwenden"
L["useManaPotionInCombatDesc"] = "Fügt eine [combat]-Zeile hinzu, um den Algari-Manatrank (höchste verfügbare Qualität) zu verwenden. Gilt nur für Klassen mit Mana; andere nutzen weiterhin Gesundung/Nahrung wie konfiguriert."

