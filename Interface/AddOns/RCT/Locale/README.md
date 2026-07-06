# RCT Locale System

This document describes the localization system for the Hated Crate Tracker (RCT) addon.

## Overview

The RCT addon now supports multiple languages through AceLocale-3.0. The locale system allows users to see the addon interface in their preferred language.

## Current Language Support

- **English (enUS)** - Complete (Default)
- **German (deDE)** - Complete
- **Spanish (esES)** - Complete  
- **French (frFR)** - Complete
- **Russian (ruRU)** - Complete

## File Structure

```
Locale/
├── enUS.lua     # English (default/fallback)
├── deDE.lua     # German
├── esES.lua     # Spanish
├── frFR.lua     # French
├── ruRU.lua     # Russian
└── locale.lua   # Initialization
```

## How It Works

1. The addon loads all available locale files based on the TOC file
2. The `locale.lua` file initializes the localization system
3. AceLocale-3.0 automatically selects the appropriate language based on the client's locale
4. If a translation is missing, it falls back to the English default

## Adding New Languages

To add support for a new language:

1. Create a new file `Locale/{locale}.lua` (e.g., `itIT.lua` for Italian)
2. Copy the structure from `enUS.lua`
3. Translate all the string values, keeping the keys unchanged
4. Add the new file to the TOC file loading order
5. Test with a client set to that locale

## Translation Guidelines

When translating:

- **Keep format placeholders**: Maintain `%s`, `%d`, and similar placeholders in the same positions
- **Preserve color codes**: Keep `|cff...` color codes intact
- **Maintain structure**: Don't change the bracketed keys like `L["KEY_NAME"]`
- **Test lengths**: Some UI elements have space constraints
- **Context matters**: Consider the gaming context and WoW terminology

## Key Categories

- **Addon Info**: Basic addon identification strings
- **UI Elements**: Button labels, tooltips, window titles
- **Messages**: Warning messages, announcements, notifications
- **Settings**: Configuration option labels and descriptions  
- **Commands**: Help text for slash commands
- **Errors**: Error messages and notifications
- **Zone Names**: Game zone references
- **Communications**: Network/chat related messages

## Usage in Code

Strings are accessed using the global locale table:

```lua
local L = _G.RCT_LOCALE or {}
-- Usage: L["KEY_NAME"] or "fallback text"
someFrame:SetText(L["ADDON_TITLE"] or "Hated Crate Tracker")
```

## Contributing Translations

To contribute translations:

1. Fork the addon repository
2. Create/modify the appropriate locale file
3. Test your translations in-game
4. Submit a pull request with your changes

## Testing

To test locale changes:

1. Set your WoW client to the target language
2. Reload the addon (`/reload`)
3. Check that all text displays correctly
4. Verify that formatting and placeholders work properly
5. Test all addon functions to ensure strings appear correctly

## Future Enhancements

Potential future improvements:

- Additional language support (Portuguese, Italian, Korean, Chinese, etc.)
- Dynamic locale switching without reload
- Locale-specific formatting for dates/times
- Region-specific server/community references

## Technical Notes

- Uses AceLocale-3.0 for locale management
- English (enUS) serves as the fallback for all missing translations
- Locale files are loaded in TOC order during addon initialization
- The system is backwards compatible - if locales fail to load, the addon will still function with English text