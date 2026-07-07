# Changelog

All notable changes to this project should be documented in this file.

## 1.4.2 - Setup Sharing
- Added setup export and import strings.
- Added a Share tab to the standalone options window.
- Added slash commands for setup export and import.

## 1.4.1 - Arena DR Icon Error Fix
- Fixed an error when arena DR icons show or hide during combat

## 1.4.0 - Configurable Timer Decimals
- Added optional decimal countdowns with an adjustable 1-20 second threshold (5 seconds by default)
- Applies to DR icons, previews, and the optional trinket icon

## 1.3.9 - Midnight 12.0.7 TOC Update
- Updated addon interface compatibility metadata to include Midnight 12.0.7.

## 1.3.8 - Reset Confirmation Prompt
- Added a confirmation prompt before resetting all settings
- Localized the reset confirmation message for supported languages

## 1.3.7 - Timer Text Visibility Option
- Added a Timers option to hide DR countdown text while keeping cooldown swipes available

## 1.3.6 - Trinket and DR Border Styles
- Added trinket border controls for style, color, and width, including Classic and None style choices
- Added a None style for DR borders

## 1.3.5 - Fixed DR Icon Size
- Added a setting to keep DR icon size fixed instead of following nameplate scaling
- Updated preview mode to show randomized DR samples on all nearby enemy nameplates

## 1.3.4 - Blizzard Arena DR Options
- Added General options for Blizzard's arena DR frames
- Added a filter to show only DR categories your character can apply

## 1.3.3 - Midnight 12.0.5 TOC Update
- Updated the TOC file to include the 12.0.5 interface versions

## 1.3.2 - Immunity Badge and Trinket Fixes
- Fixed the immunity badge icon to use the addon shield texture and render above the DR border
- Fixed Solo Shuffle trinket mirrors retaining cooldown state between rounds

## 1.3.1 - DR Tray Recovery Fixes
- Fixed DR icons getting stuck or disappearing after vanish and other temporary nameplate loss cases
- Prevented this recovery flow from affecting Blizzard's default arena DR frames

## 1.3.0 - Midnight-Safe DR Tray Mirroring
- Switch live DR nameplate rendering from reparenting Blizzard's tray to mirroring it into addon-owned frames
- Keep Blizzard's original arena DR tray in place while the addon copies textures, cooldowns, and immunity state into Midnight-safe nameplate frames
- Restyle the standalone options window to match the dark blue panel style used by the other addon configuration panels

## 1.2.5 - Enemy Trinket Cooldown Icon
- Added an optional enemy trinket cooldown icon on arena nameplates
- Added localization and a dedicated settings page for the trinket feature
- Added trinket defaults, appearance controls, positioning options, and README updates

## 1.2.4 - Friendly Nameplate Arena Mapping Filter
- Improve arena mapping by filtering friendly player nameplates

## 1.2.3 - Icon Layout and Border Options
- Added icon layout and border style options

## 1.2.2 - DR Tray Recovery Improvements
- Improve DR tray recovery after vanish, feign death, and other temporary enemy target loss cases

## 1.2.1 - Arena Mapping Recovery
- Restore arena mapping after transient target/nameplate loss

## 1.2.0 - Standalone Options Window
- Added a new standalone options window
- Added preview buttons
- Improved page layout and scrolling

## 1.1.1 - Slash Command Cleanup
- Removed the `/arenadr on` and `/arenadr off` commands to keep the command list clear. Arena DR tracking still turns on automatically when it should.
- Cleaned up the README and in-game slash handler so the documented commands match the ones players can actually use.

## 1.1.0 - Localization Support
- Add localization support with a dedicated `Locales` folder
- Add default/fallback English locale (`enUS`) and translated locale files for `deDE`, `frFR`, `esES`, `ruRU`, `ptBR`, `koKR`, `zhCN`, and `zhTW`
- Localize settings UI labels and addon chat/status messages through `ns.L`

## 1.0.9 - Settings UI Improvements
- Improve settings UI

## 1.0.8 - Icon Padding and Color Picker
- Add icon padding setting
- Reduce color picker size

## 1.0.7 - Plater and Threat Plates Adapters

- Add a dedicated Plater adapter that anchors to Plater's custom unit frame instead of the Blizzard fallback
- Add a Threat Plates adapter that resolves the active `TPFrame` anchor for healthbar and headline layouts

## 1.0.6 - Adapter File Refactor

- Refactor nameplate adapters into an `Adapters` folder
- Split Blizzard, Platynator, and ElvUI adapters into separate files

## 1.0.5 - ElvUI Nameplate Adapter

- Add ElvUI nameplate adapter support
- Anchor ElvUI integration to the ElvUI health bar instead of the full plate

## 1.0.4 - Modular Nameplate Adapter Registry

- Add a modular nameplate adapter registry for future third-party integrations
- Add first external adapter for Platynator nameplates
- Reuse adapter-based anchor resolution for live trays and preview mode

## 1.0.3 - Cooldown Preview Cleanup

- Refactor frame naming with `NextFrameName`
- Improve cooldown preview (swipe + edge options)
- Clean up DR text and border color handling
## 1.0.2 - Border Width and Icon Growth Options
- Add border width setting and enhance icon growth options in settings

## 1.0.1 - DR Text and Immunity Settings
- Add DR text overlay and immunity indicator settings to the UI
- Update timer color and position settings; enhance UI controls for DR text and immunity indicators

## 1.0.0 - Initial Arena DR Nameplate Release

- Includes arena DR nameplate anchoring, timer styling, preview mode, placement controls, DR text overlays, immunity options, and Blizzard Settings integration.
