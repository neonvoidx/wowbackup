## 1.0.4

### New Features

- **Account-wide settings and macro**: Set up your kick marker and macro once and share them across all your characters. Turn it on in Options; your current character's setup is copied over the first time, so nothing is lost, and switching back to per-character keeps everything you had.
- **Custom kick spell**: Set your own kick spell by name or spell ID if you want something other than your class default, handy for a pet ability or an unusual setup. It stays with that one character, so it never follows you to an alt of another class, and the box shows which spell is in use.

### Improvements

- **New look**: The whole interface has been rebuilt in the Arc UI style, with a clean dark panel, tabs, grouped sections and modern checkboxes. Prefer the old one? Turn on "Classic marker window" in Options.
- **Macro editing moved into Options**: Editing your macros now happens on a Macros tab inside the settings window instead of a separate pop-up, so the slot, name, templates and body all sit in one place. You can also copy the commands from any of your existing macros as a starting point.
- **Resizable options window**: Drag the bottom-right corner to whatever size suits you and it is remembered.
- **Discord button**: A one-click way to grab the Arc UI Discord invite if you need help or want to report something.

### Bug Fixes

- **Demonology warlocks now have a kick**: Demonology was missing an interrupt entirely and fell back to the Felhunter's Spell Lock. It now uses Axe Toss, your Felguard's stop.
- **Macro list error**: Fixed a Lua error about macro limits that could interrupt browsing or updating your macros.

## 1.0.3

### Bug Fixes

- **Interrupt Alert toggle**: Fixed a Lua error ("attempt to call a nil value") when turning the "Play a sound when your focus casts" option on or off.

## 1.0.2

### New Features

- **Interrupt Alert**: Get a sound or spoken (text-to-speech) alert the moment your focus starts casting and your interrupt is off cooldown, so you know to look and kick. Pick from built-in alert sounds or any LibSharedMedia sound, choose the sound channel, set your own spoken word, and preview it. Off by default; enable it from the main window or Options.
