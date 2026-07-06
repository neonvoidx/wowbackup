local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:NewLocale("RdysCrateTracker", "deDE")

if not L then return end

-- German locale translations
-- Translation notes: Please maintain the formatting of %s placeholders
-- and keep the color codes |cff... intact
L["RDYZ"] = "Fordert Kisten-Timer vom Schlachtzugsleiter an."
-- Addon Info
L["ADDON_NAME"] = "Hated Crate Tracker"
L["ADDON_TITLE"] = "Hated Crate Tracker"
L["ADDON_SHORT_NAME"] = "Hated Tracker"

-- Discord and Links
L["DISCORD_POPUP_TEXT"] = "Kopieren Sie diesen Link und öffnen Sie ihn in einem Browser."
L["JOIN_DISCORD"] = "Discord beitreten"

-- Version Update Messages
L["VERSION_UPDATE_TITLE"] = "Hated Crate Tracker!"
L["VERSION_UPDATE_WELCOME"] = "Willkommen zu 8.0"
L["VERSION_UPDATE_MESSAGE"] = [[Diese Version bringt Sicherheitsverbesserungen 
zum Schutz Ihrer Raids. Das funktioniert nicht 
mit früheren Versionen des Addons.

Sie müssen Ihre alte CrateDB löschen, wenn 
Sie diese Version verwenden möchten. Ein einfacher Weg 
um sicherzustellen, dass dies für Sie funktioniert, ist 
Ihr Addon-Profil zurückzusetzen. Klicken Sie die 
Reset-Taste unten um dies zu tun!

HatedGaming

Verfolge den Hass!]]

-- Buttons
L["RESET"] = "Zurücksetzen"
L["CLOSE"] = "Schließen"
L["DONT_SHOW_AGAIN"] = "Nicht wieder anzeigen"

-- Warning Messages
L["CRATE_ALERT_MESSAGE"] = "HatedGaming Kisten Alarm! Fliegend in %s - Shard = %s"
L["CRATE_ANNOUNCE_MESSAGE"] = "%s hat gerade eine Kriegskiste in %s - %s angekündigt (gehört von %s)"
L["CRATE_SPOT_MESSAGE"] = "Kriegskiste in %s - %s (gesichtet von %s - %s)"
L["SHARD_MATCH_WARNING"] = "HatedGaming Warnung: Der Shard stimmt für %s überein. Shard ID: %s"
L["SHARD_CHANGED_WARNING"] = "HatedGaming Warnung: Der Shard hat sich für %s geändert. Alt: %s, Neu: %s"

-- Vignette Messages
L["SUPPLY_CRATE_CLAIMED"] = "HatedGaming Versorgungskiste beansprucht in %s"

-- UI Elements
L["CLOSE_WINDOW"] = "Fenster schließen"
L["HIDE_SHOW_TIMERS"] = "Timer verstecken/anzeigen"
L["OPEN_OPTIONS"] = "Optionen öffnen"
L["PLACEMENT_TEXT"] = "HatedGaming Crate Tracker: Addon-Platzierungstext"

-- Zone Names
L["UNKNOWN_ZONE"] = "Unbekannte Zone"

-- Settings Labels
L["GENERAL_SETTINGS"] = "Allgemeine Einstellungen"
L["ENABLE"] = "Aktivieren"
L["ENABLE_DESC"] = "Addon aktivieren oder deaktivieren"

-- Warning Frame Settings
L["WARNING_FRAME"] = "Warnrahmen"
L["WARNING_FRAME_DESC"] = "Einstellungen zum Warnrahmen"
L["ENABLE_WARNING_FRAME"] = "Warnrahmen aktivieren"
L["ENABLE_WARNING_FRAME_DESC"] = "Warnrahmen aktivieren oder deaktivieren"

-- Zone-specific Settings
L["UNDERMINE_ANNOUNCE"] = "Untermine - Ankündigen"
L["UNDERMINE_ANNOUNCE_DESC"] = "Ton abspielen und Untermine-Kisten ankündigen"
L["UNDERMINE_TRACK"] = "Untermine - Verfolgen"
L["UNDERMINE_TRACK_DESC"] = "Untermine-Kisten in /rct-Ausgabe anzeigen"

-- Command Help
L["HELP_SPOT"] = "/rct spot - Markiert manuell eine Kiste."
L["HELP_CENTER"] = "/rct center - Zentriert das Hauptfenster."
L["HELP_HELP"] = "/rct help - Zeigt diese Hilfemeldung."
L["HELP_RDYZ"] = "/rct rdyz - Fordert aktuelle Kisten von anderen Benutzern an."
L["HELP_SHARE"] = "/rct share - Addon-Informationen mit anderen Benutzern teilen."

-- Command Responses
L["RDYZ_RESPONSE"] = "Du bist der Boss! Hier sind deine Timer..."

-- Bounty Hunter Messages
L["BOUNTY_ALLIANCE"] = "HatedGaming Kopfgeldjäger - Allianz-Kopfgeld ist in deiner Zone @ %s, %s"
L["BOUNTY_HORDE"] = "HatedGaming Kopfgeldjäger - Horde-Kopfgeld ist in deiner Zone @ %s, %s"

-- Error Messages
L["ADDON_NOT_FOUND"] = "RdysCrateTracker-Addon nicht gefunden. Bitte stellen Sie sicher, dass es geladen ist."

-- Test Messages
L["TEST_MESSAGE"] = "Testnachricht"

-- Communications
L["RAID_TOKEN_NOT_RECEIVED"] = "Raid-Token nach %d Versuchen nicht erhalten; weitere Anfragen unterdrückt (%d Min Abklingzeit)."
L["BROADCASTED_ALERT"] = "ALERT für Zone gesendet:"
L["WARNING_CRATE_IMMINENT"] = "Warnung Kiste steht unmittelbar bevor:"

-- Staleness Settings
L["ALLOWED_MISSED_TIMERS"] = "Erlaubte verpasste Kisten-Timer"
L["VERIFY_SHARD"] = "Shard überprüfen"
L["VERIFY_SHARD_DESC"] = "Die Shard-ID der Kiste überprüfen"

-- Timer Options
L["CRATE_TIMER_BAR_OPTIONS"] = "Kisten-Timer-Balken Optionen"
L["TIMER_OPTIONS"] = "Timer Optionen"
L["TIMER_OPTIONS_DESC"] = "Timer-Optionen für Hated Crate Tracker konfigurieren"
L["TIMER_BAR_FONT_SIZE"] = "Timer-Balken Schriftgröße"
L["TIMER_BAR_FONT_SIZE_DESC"] = "Schriftgröße für Kisten-Timer-Balken festlegen"