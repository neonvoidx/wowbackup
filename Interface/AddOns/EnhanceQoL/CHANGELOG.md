# Changelog

## [12.7.0] - 2026-08-24

### ✨ Added

- Class Buff Reminder: Added interactive, content-aware reminders with configurable actions, tracker matrix, class-color glow, Healthstone tracking, and stance reminders.
- Cooldown Panels: Added a context-menu action to remove all panel entries after confirmation.
- Damage Meter: Added a Current/Overall switch to the Quick Switch menu.
- Interface: Added options to close the Button Sink click-toggle flyout automatically.
- Nameplates: Added configurable default healthbar textures with separate focus color and texture options.
- Talent Reminder: Added a default build per specialization for dungeons set to Use default.
- Unit Frames: Added group-frame dispel icons, dedicated Boss aura filtering and sizing, and detachable Data Bars across supported unit frames.

### 🔄 Changed

- Questing: Separated automatic quest and Gossip handling, with content-specific Gossip controls and reusable saved selections.

### 🐛 Fixed

- Auras: Prevented native aura rows from wrapping early at some UI scales.
- Character Frame: Prevented temporarily unavailable enchant tooltips from being cached as missing enchants.
- Cooldown Panels: Prevented existing Cooldown Manager entries from being duplicated when enabling panel sync.
- Data Panels: Kept Data Text settings grouped with their corresponding entries.
- Mover: Kept the Macro icon selector attached to the Macro window so it opens without errors.
- Mythic Plus: Aligned +2/+3 timer bar markers with the configured fill direction.
- Resource Bars: Corrected Shared Resource Bar anchoring and background insets on separated segments.
- Unit Frames: Corrected Boss aura positioning and combat restoration, Castbar textures and icon borders, and independent Healer Buff Placement cooldown settings.
