local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:NewLocale("RdysCrateTracker", "frFR")

if not L then return end

-- French locale translations
-- Translation notes: Please maintain the formatting of %s placeholders
-- and keep the color codes |cff... intact
L["RDYZ"] = "Demande les minuteurs de caisse au chef de raid."
-- Addon Info
L["ADDON_NAME"] = "Hated Crate Tracker"
L["ADDON_TITLE"] = "Hated Crate Tracker"
L["ADDON_SHORT_NAME"] = "Hated Tracker"

-- Discord and Links
L["DISCORD_POPUP_TEXT"] = "Copiez ce lien et ouvrez-le dans un navigateur."
L["JOIN_DISCORD"] = "Rejoindre Discord"

-- Version Update Messages
L["VERSION_UPDATE_TITLE"] = "Hated Crate Tracker!"
L["VERSION_UPDATE_WELCOME"] = "Bienvenue en 8.0"
L["VERSION_UPDATE_MESSAGE"] = [[Cette version apporte des améliorations de sécurité 
pour protéger vos raids. Cela ne fonctionne pas 
avec les versions précédentes de l'addon.

Vous devrez effacer votre ancienne crateDB si 
vous voulez utiliser cette version. Un moyen facile 
de vous assurer que cela fonctionne pour vous est 
de simplement réinitialiser votre profil d'addon. Cliquez sur le 
bouton Réinitialiser ci-dessous pour le faire!

HatedGaming

Tracez la haine!]]

-- Buttons
L["RESET"] = "Réinitialiser"
L["CLOSE"] = "Fermer"
L["DONT_SHOW_AGAIN"] = "Ne plus afficher"

-- Warning Messages
L["CRATE_ALERT_MESSAGE"] = "Alerte Caisse HatedGaming! Volant dans %s - Éclat = %s"
L["CRATE_ANNOUNCE_MESSAGE"] = "%s vient d'annoncer une caisse de guerre dans %s - %s (entendu par %s)"
L["CRATE_SPOT_MESSAGE"] = "Caisse de guerre dans %s - %s (repérée par %s - %s)"
L["SHARD_MATCH_WARNING"] = "Avertissement HatedGaming: L'éclat correspond pour %s. ID d'Éclat: %s"
L["SHARD_CHANGED_WARNING"] = "Avertissement HatedGaming: L'éclat a changé pour %s. Ancien: %s, Nouveau: %s"

-- Vignette Messages
L["SUPPLY_CRATE_CLAIMED"] = "Caisse de Fournitures HatedGaming Réclamée dans %s"

-- UI Elements
L["CLOSE_WINDOW"] = "Fermer la Fenêtre"
L["HIDE_SHOW_TIMERS"] = "Masquer/Afficher les Minuteurs"
L["OPEN_OPTIONS"] = "Ouvrir les Options"
L["PLACEMENT_TEXT"] = "HatedGaming Crate Tracker: Texte de Placement de l'Addon"

-- Zone Names
L["UNKNOWN_ZONE"] = "Zone Inconnue"

-- Settings Labels
L["GENERAL_SETTINGS"] = "Paramètres Généraux"
L["ENABLE"] = "Activer"
L["ENABLE_DESC"] = "Activer ou désactiver l'addon"

-- Warning Frame Settings
L["WARNING_FRAME"] = "Cadre d'Avertissement"
L["WARNING_FRAME_DESC"] = "Paramètres liés au cadre d'avertissement"
L["ENABLE_WARNING_FRAME"] = "Activer le Cadre d'Avertissement"
L["ENABLE_WARNING_FRAME_DESC"] = "Activer ou désactiver le cadre d'avertissement"

-- Zone-specific Settings
L["UNDERMINE_ANNOUNCE"] = "Saper - Annoncer"
L["UNDERMINE_ANNOUNCE_DESC"] = "Jouer un son et annoncer les caisses de Saper"
L["UNDERMINE_TRACK"] = "Saper - Suivre"
L["UNDERMINE_TRACK_DESC"] = "Afficher les caisses de Saper dans la sortie /rct"

-- Command Help
L["HELP_SPOT"] = "/rct spot - Repère manuellement une caisse."
L["HELP_CENTER"] = "/rct center - Centre la fenêtre principale."
L["HELP_HELP"] = "/rct help - Affiche ce message d'aide."
L["HELP_RDYZ"] = "/rct rdyz - Demande des caisses récentes aux autres utilisateurs."
L["HELP_SHARE"] = "/rct share - Partage les informations de l'addon avec d'autres utilisateurs."

-- Command Responses
L["RDYZ_RESPONSE"] = "Tu es le patron! Voici tes minuteurs..."

-- Bounty Hunter Messages
L["BOUNTY_ALLIANCE"] = "HatedGaming Chasseur de Prime - Prime de l'Alliance est dans votre zone @ %s, %s"
L["BOUNTY_HORDE"] = "HatedGaming Chasseur de Prime - Prime de la Horde est dans votre zone @ %s, %s"

-- Error Messages
L["ADDON_NOT_FOUND"] = "Addon RdysCrateTracker non trouvé. Veuillez vous assurer qu'il est chargé."

-- Test Messages
L["TEST_MESSAGE"] = "Message de test"

-- Communications
L["RAID_TOKEN_NOT_RECEIVED"] = "Token de raid non reçu après %d tentatives; demandes supplémentaires supprimées (temps de recharge de %d min)."
L["BROADCASTED_ALERT"] = "ALERTE diffusée pour la zone:"
L["WARNING_CRATE_IMMINENT"] = "Avertissement caisse imminente:"

-- Staleness Settings
L["ALLOWED_MISSED_TIMERS"] = "Minuteurs de caisses manqués autorisés"
L["VERIFY_SHARD"] = "Vérifier le fragment"
L["VERIFY_SHARD_DESC"] = "Vérifier l'ID du fragment de la caisse"

-- Timer Options
L["CRATE_TIMER_BAR_OPTIONS"] = "Options de barre de minuteur de caisses"
L["TIMER_OPTIONS"] = "Options de minuteur"
L["TIMER_OPTIONS_DESC"] = "Configurer les options de minuteur pour Hated Crate Tracker"
L["TIMER_BAR_FONT_SIZE"] = "Taille de police de barre de minuteur"
L["TIMER_BAR_FONT_SIZE_DESC"] = "Définir la taille de police pour les barres de minuteur de caisses"