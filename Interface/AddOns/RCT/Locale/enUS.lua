local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:NewLocale("RdysCrateTracker", "enUS", true)

if not L then return end

-- Addon Info
L["ADDON_NAME"] = "Hated Crate Tracker"
L["ADDON_TITLE"] = "Hated Crate Tracker"
L["ADDON_SHORT_NAME"] = "HG Tracker"

-- Discord and Links
L["DISCORD_POPUP_TEXT"] = "Copy this link and open it in a Browser."
L["JOIN_DISCORD"] = "Join Discord"
L["DISCORD_LINK"] = "https://discord.gg/qHHSMFsJ9f"

-- Version Update Messages
L["VERSION_UPDATE_TITLE"] = "Hated Crate Tracker!"
L["VERSION_UPDATE_WELCOME"] = "Welcome to 8.0"
L["VERSION_UPDATE_MESSAGE"] = [[This version brings security enhancements 
to protect your raids. This does not work 
with previous versions of the addon.

You will have to clear your old crateDB if 
you want to use this version. An easy way 
to make sure this will work for you is to 
just reset your addon profile. Click the 
Reset button below to do so!

Hated Gaming

Track the hate!]]

-- Buttons
L["RESET"] = "Reset"
L["CLOSE"] = "Close"
L["DONT_SHOW_AGAIN"] = "Don't show again"

-- Guidelines
L["WAR_CRATE_GUIDELINES"] = [[
DOs:
- Do join our Discord and use /rct help for addon info.
- Do join with friends or guildies; full groups have a blast.
- Do use voice comms; we coordinate and call out crates.
- Do be ready; crates drop fast, and we move quickly.
- Do help newbies; we all started somewhere, and we grow the community.
- Do Join Hated Gaming guild on Whisperwind (In Horde guild finder)
DM @Rdy on Discord for invite on Alliance.
]]

-- Warning Messages
L["CRATE_ALERT_MESSAGE"] = "Hated Gaming Crate Alert! Flying in %s - Shard = %s"
L["CRATE_ANNOUNCE_MESSAGE"] = "%s just announced a war crate in %s - %s (heard by %s)"
L["CRATE_SPOT_MESSAGE"] = "War crate in %s - %s (spotted by %s - %s)"
L["SHARD_MATCH_WARNING"] = "Hated Gaming Warning: The shard matches for %s. Shard ID: %s"
L["SHARD_CHANGED_WARNING"] = "Hated Gaming Warning: The shard changed for %s. Old: %s, New: %s"

-- Vignette Messages
L["SUPPLY_CRATE_CLAIMED"] = "Hated Gaming Supply Crate Claimed in %s"
L["CRATE_FLYING"] = "War Supply Crate - Flying"
L["CRATE_HOVERING"] = "War Supply Crate - Hovering"
L["CRATE_CLAIMED"] = "War Supply Crate - Claimed"
L["CRATE_STILL_FIGHTING"] = "War Supply Crate - Still Fighting"

-- UI Elements
L["CLOSE_WINDOW"] = "Close Window"
L["HIDE_SHOW_TIMERS"] = "Hide/Show Timers"
L["OPEN_OPTIONS"] = "Open Options"
L["PLACEMENT_TEXT"] = "Hated Gaming Crate Tracker: Addon Placement Text"

-- Zone Names
L["ISLE_OF_DORN"] = "Isle of Dorn"
L["RINGING_DEEPS"] = "The Ringing Deeps"
L["HALLOWFALL"] = "HallowFall"
L["AZJ_KAHET"] = "Azj-Kahet"
L["SIREN_ISLE"] = "Siren Isle"
L["UNDERMINE"] = "UnderMine(d)"
L["UNKNOWN_ZONE"] = "Unknown Zone"

-- Settings Labels
L["GENERAL_SETTINGS"] = "General Settings"
L["ENABLE"] = "Enable"
L["ENABLE_DESC"] = "Enable or disable the addon"
L["DEBUG_MODE"] = "Debug Mode"
L["DEBUG_MODE_DESC"] = "Enable debug messages"
L["SCALE"] = "Scale"
L["SCALE_DESC"] = "Set the scale of the main frame"

-- Warning Frame Settings
L["WARNING_FRAME"] = "Warning Frame"
L["WARNING_FRAME_DESC"] = "Settings related to the warning frame"
L["ENABLE_WARNING_FRAME"] = "Enable Warning Frame"
L["ENABLE_WARNING_FRAME_DESC"] = "Enable or disable the warning frame"
L["WARNING_X_POSITION"] = "Warning X Position"
L["WARNING_X_POSITION_DESC"] = "Set the X position of the warning text"
L["WARNING_Y_POSITION"] = "Warning Y Position"
L["WARNING_Y_POSITION_DESC"] = "Set the Y position of the warning text"
L["WARNING_FRAME_FONT"] = "Warning Frame Font"
L["WARNING_FRAME_FONT_DESC"] = "Select the font for the warning frame"
L["WARNING_FRAME_FONT_SIZE"] = "Warning Frame Font Size"
L["WARNING_FRAME_FONT_SIZE_DESC"] = "Set the font size for the warning frame"

-- Zone-specific Settings
L["UNDERMINE_ANNOUNCE"] = "Undermine - Announce"
L["UNDERMINE_ANNOUNCE_DESC"] = "Make a sound and announce Undermine crates"
L["UNDERMINE_TRACK"] = "Undermine - Track"
L["UNDERMINE_TRACK_DESC"] = "Show Undermine crates in /rct output"
L["UNDERMINE_WARN"] = "Undermine - Warn"
L["UNDERMINE_WARN_DESC"] = "Make a sound and warn before Undermine crates will drop"

L["DF_ANNOUNCE"] = "DF - Announce"
L["DF_ANNOUNCE_DESC"] = "Make a sound and announce DF crates"
L["DF_TRACK"] = "DF - Track"
L["DF_TRACK_DESC"] = "Show DF crates in /rct output"
L["DF_WARN"] = "DF - Warn"
L["DF_WARN_DESC"] = "Make a sound and warn before DF crates will drop"

L["TWW_ANNOUNCE"] = "TWW - Announce"
L["TWW_ANNOUNCE_DESC"] = "Make a sound and announce TWW crates"
L["TWW_TRACK"] = "TWW - Track"
L["TWW_TRACK_DESC"] = "Show TWW crates in /rct output"
L["TWW_WARN"] = "TWW - Warn"
L["TWW_WARN_DESC"] = "Make a sound and warn before TWW crates will drop"

L["DRGF_ANNOUNCE"] = "DRGF - Announce"
L["DRGF_ANNOUNCE_DESC"] = "Make a sound and announce DRGF crates"
L["DRGF_TRACK"] = "DRGF - Track" 
L["DRGF_TRACK_DESC"] = "Show DRGF crates in /rct output"
L["DRGF_WARN"] = "DRGF - Warn"
L["DRGF_WARN_DESC"] = "Make a sound and warn before DRGF crates will drop"

L["MID_ANNOUNCE"] = "Mid - Announce"
L["MID_ANNOUNCE_DESC"] = "Make a sound and announce Mid crates"
L["MID_TRACK"] = "Mid - Track"
L["MID_TRACK_DESC"] = "Show Mid crates in /rct output"
L["MID_WARN"] = "Mid - Warn"
L["MID_WARN_DESC"] = "Make a sound and warn before Mid crates will drop"

-- Sound Settings
L["WARNING_SOUND"] = "Warning Sound"
L["WARNING_SOUND_DESC"] = "Enable sound alerts for crate warnings"

-- Background Settings
L["BACKGROUND_COLOR"] = "Background Color"
L["BACKGROUND_COLOR_DESC"] = "Set the background color of frames"

-- Staleness Settings
L["STALENESS"] = "Staleness"
L["STALENESS_DESC"] = "How stale data should be before being removed (in minutes)"
L["ALLOWED_MISSED_TIMERS"] = "Allowed Missed Crate Timers"
L["VERIFY_SHARD"] = "Verify Shard"
L["VERIFY_SHARD_DESC"] = "Verify the shard ID of the crate"

-- Timer Options
L["CRATE_TIMER_BAR_OPTIONS"] = "Crate Timer Bar Options"
L["TIMER_OPTIONS"] = "Timer Options"
L["TIMER_OPTIONS_DESC"] = "Configure the timer options for Hated Crate Tracker"
L["TIMER_BAR_FONT_SIZE"] = "Timer Bar Font Size"
L["TIMER_BAR_FONT_SIZE_DESC"] = "Set the font size for crate timer bars"

-- Combat Settings
L["COMBAT_DISABLE"] = "Disable in Combat"
L["COMBAT_DISABLE_DESC"] = "Disable addon functionality while in combat"

-- TomTom Integration
L["ENABLE_TOMTOM"] = "Enable TomTom"
L["ENABLE_TOMTOM_DESC"] = "Enable TomTom waypoint integration"

-- About Section
L["ABOUT"] = "About"
L["ABOUT_DESC"] = "Information about this addon"
L["SUPPORT_TITLE"] = "Join the Supporters on Discord"
L["SUPPORT_DESC"] = "Monthly supporters of Hated Gaming"
L["SUPPORT_MESSAGE"] = "Don't be a Hater!! - Join the community! - Hated Gaming on Curseforge"

-- Command Help
L["HELP_HEADER"] = "Hated Crate Tracker Commands:"
L["HELP_SPOT"] = "/rct spot - Manually spots a crate."
L["HELP_CENTER"] = "/rct center - Centers the main frame."
L["HELP_HELP"] = "/rct help - Shows this help message."
L["HELP_RDYZ"] = "/rct rdyz - Requests recent crates from other users."
L["RDYZ"] = "Requests crate timers from Raid Leader."
L["HELP_SHARE"] = "/rct share - Share Addon information with other users."

-- Command Responses
L["RDYZ_RESPONSE"] = "You da Boss man! Here are your Timers..."

-- Addon Advertisement
L["ADDON_ADVERTISEMENT"] = 'Hated Crate Tracker by Rdy @ Hated Gaming — "Be Hated! Don\'t just play, dominate." Track crates, sync raids, log timers and dominate War Mode with Hated Gaming - And remember kids if it ain\'t Hated, it ain\'t worth it. Available now on Curseforge!'

-- Bounty Hunter Messages
L["BOUNTY_ALLIANCE"] = "Hated Gaming Bounty Hunter - Alliance Bounty is in your zone @ %s, %s"
L["BOUNTY_HORDE"] = "Hated Gaming Bounty Hunter - Horde Bounty is in your zone @ %s, %s"

-- Error Messages
L["ADDON_NOT_FOUND"] = "RdysCrateTracker addon not found. Please ensure it is loaded."

-- Test Messages
L["TEST_MESSAGE"] = "Test message"

-- Timer and Status Messages
L["NEXT_CRATE"] = "Next Crate: %s - %s in %s"
L["WARNING_CRATE_IMMINENT"] = "Warning crate imminent:"

-- Font Options
L["FONTS"] = {
    ["Fonts\\FRIZQT__.TTF"] = "Friz Quadrata TT",
    ["Fonts\\ARIALN.TTF"] = "Arial Narrow",
    ["Fonts\\skurri.ttf"] = "Skurri",
    ["Fonts\\MORPHEUS.ttf"] = "Morpheus",
    ["Interface\\AddOns\\RCT\\fonts\\PT_Sans_Narrow_Bold.ttf"] = "PT Sans Narrow Bold",
}

-- Window Labels and Timer Format
L["WINDOW_LABEL"] = "%i. %s - %s - %ix - "
L["WINDOW_TIMER"] = "%s"

-- Communications
L["RAID_TOKEN_NOT_RECEIVED"] = "Raid token not received after %d attempts; further requests suppressed (%d min cooldown)."
L["BROADCASTED_ALERT"] = "Broadcasted ALERT for zone:"

-- Debug Messages  
L["ZONE_UPDATE"] = "Zone update: map=%d → normalized=%d"

-- Addon Loading Messages
L["ADDON_LOADED"] = "Hated Crate Tracker Loaded!!"
L["TOGGLE_HELP"] = "Use /rct toggle to show/hide the addon."

-- Command Responses
L["ADDON"] = "Addon"
L["ENABLED"] = "enabled"
L["DISABLED"] = "disabled"
L["DEVELOPER_MODE"] = "Developer mode"
L["CLEARED_CRATE_DB"] = "Cleared crate DB."
L["CLEARED_ALL_HISTORY"] = "Cleared all history."
L["MANUALLY_SPOTTED"] = "Manually spotted a crate."
L["CENTERED_PANEL"] = "Centered title panel."

-- Help Commands
L["AVAILABLE_COMMANDS"] = "Available commands:"
L["HELP_MAIN"] = "/rct  Open/Close the addon."
L["HELP_TOGGLE"] = "/rct toggle - Enable/disable the addon."
L["HELP_DEBUG"] = "/rct debug - Toggle debug mode."
L["HELP_CLEAR"] = "/rct clear - Clears the crate DB."
L["HELP_CLEARALL"] = "/rct clearall - Clears all history."
L["HELP_DEL"] = "/rct del <arg> - Deletes a specific crate."

-- Frame Messages  
L["UNABLE_DETERMINE_MAP"] = "Unable to determine your current map. Cannot share Shard ID."
L["SHARD_ID_MESSAGE"] = "Shard ID: %s (Map ID: %s)"

-- UI Button Labels
L["MINIMIZE_BUTTON"] = "+/-"
L["OPTIONS_BUTTON"] = "Opt"
L["CLOSE_BUTTON"] = "X"
L["SYNC_BUTTON"] = "Sync"
L["SHARE_BUTTON"] = "Share"

-- UI Tooltips
L["CLOSE_WINDOW"] = "Close Window"
L["HIDE_SHOW_TIMERS"] = "Hide/Show Timers" 
L["CLICK_SHARE_SHARD"] = "Click to share Shard ID"
L["CLICK_SYNC_TIMERS"] = "Click to Sync Crate Timers"
L["CLICK_SHARE_ADDON"] = "Click to Share Addon"

-- Options Labels
L["PREDICTION"] = "Prediction"
L["PREDICTION_DESC"] = "Enable or Disable Prediction"
L["BOUNTY_HUNTER"] = "Bounty Hunter"
L["BOUNTY_HUNTER_DESC"] = "Enable or disable the Bounty Hunter feature"
L["DEVELOPER_MODE_DESC"] = "Enable Developer Mode for testing purposes"
L["DISABLE_PVP"] = "Disable in PvP"
L["DISABLE_PVP_DESC"] = "Stop addon from working during Arena/BG/Dungeons/Raids"
L["RESET_DESC"] = "Reset the addon settings to default"
L["TEST"] = "Test"
L["TEST_DESC"] = "Test the addon functionality"
L["PLACEMENT_TEXT"] = "Hated Gaming Crate Tracker: Addon Placement Text"
L["SCALE_UPDATED"] = "Hated Gaming Crate Tracker: Scale updated"
L["BACKGROUND_COLOR_PICKER_DESC"] = "Choose the background color"
L["CRATE_TRACKING"] = "Crate Tracking"
L["CRATE_TRACKING_DESC"] = "Settings related to crate tracking"
L["DF_ANNOUNCE_DESC"] = "Make a sound and announce DF crates"
L["DF_TRACK"] = "DF - Track"
L["DF_TRACK_DESC"] = "Show DF crates in /rct output"

-- Dragonflight Options
L["DRAGONFLIGHT_ANNOUNCE"] = "DragonFlight - Announce"
L["DRAGONFLIGHT_ANNOUNCE_DESC"] = "Make a sound and announce DragonFlight crates"
L["DRAGONFLIGHT_TRACK"] = "DragonFlight - Track"
L["DRAGONFLIGHT_TRACK_DESC"] = "Show DragonFlight crates in /rct output"
L["DRAGONFLIGHT_WARN"] = "DragonFlight - Warn"
L["DRAGONFLIGHT_WARN_DESC"] = "Make a sound and warn before DragonFlight crates will drop"

-- Midnight Options
L["MIDNIGHT_ANNOUNCE"] = "Midnight - Announce"
L["MIDNIGHT_ANNOUNCE_DESC"] = "Make a sound and announce Midnight crates"
L["MIDNIGHT_TRACK"] = "Midnight - Track"
L["MIDNIGHT_TRACK_DESC"] = "Show Midnight crates in /rct output"
L["MIDNIGHT_WARN"] = "Midnight - Warn"
L["MIDNIGHT_WARN_DESC"] = "Make a sound and warn before Midnight crates will drop"

-- Support and Community
L["SUPPORT_HATEDGAMING"] = "Support Hated Gaming"
L["SUPPORT_HELP_DESC"] = "Ways to help support Hated Crate Tracker and Hated Gaming"
L["SUPPORT_HATEDGAMING_DESC"] = "Support Hated Gaming and Hated Crate Tracker"
L["DONATE"] = "Donate"
L["DONATE_DESC"] = "Support Hated Gaming with a donation"
L["JOIN_MY_DISCORD"] = "Join My Discord"
L["JOIN_DISCORD_DESC"] = "Join the Hated Gaming/RdyGaming Warband Discord community"
L["COMMUNITY_MESSAGE"] = "Don't be a Hater!! - Join the community! - Hated Gaming on Curseforge"
L["JOIN_SUPPORTERS"] = "Join the Supporters on Discord"
L["MONTHLY_SUPPORTERS_DESC"] = "Monthly supporters of Hated Gaming"

-- Crate Farming Guide
L["CRATE_FARMING_HOWTO"] = "Crate Farming: How-To"
L["OFFICIAL_GUIDELINES"] = "Official War Supply Crate Guidelines from Hated Gaming"
L["OFFICIAL_GUIDELINES_DESC"] = "Official War Supply Crate Guidelines from Hated Gaming"
L["OFFICIAL_GUIDELINES_SHORT"] = "Official War Supply Crate Guidelines."