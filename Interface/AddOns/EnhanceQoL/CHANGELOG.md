# Changelog

## [11.7.3] - 2026-07-13

### 🐛 Fixed

- Cooldown Panels: State textures no longer disable glow or cooldown swipe settings, allowing the effects to be used together.

---

## [11.7.2] - 2026-07-12

### 🐛 Fixed

- Crosshair: Moved the range indicator setting next to the main Screen Crosshair option.
- Cooldown Panels: Restored optional Cooldown Manager synchronization for Essential Cooldowns, Utility Cooldowns, and Buff Icons.
- Resource Bars: Ebon Might is now displayed as a continuous duration bar instead of individual segments.
- Resource Bars: Fixed the expanded Text settings overlapping the text threshold color section.
- Resource Bars: The Fury Warrior Whirlwind tracker is now only shown when Improved Whirlwind is talented.
- Resource Bars: Shared bars now use the correct segment count for Whirlwind, Icicles, Soul Fragments, and other segmented resources.

---

## [11.7.1] - 2026-07-12

### 🐛 Fixed

- Settings Center: Corrected several misplaced settings and restored alphabetical sorting.
- Settings Center: Moved the EQoL Castbar option into Castbars & Cooldowns.
- Bags: Restored the missing Enable Bags module option.
- Cooldown Panels: Improved State texture defaults and disabled conflicting cooldown and glow effects.
- PTR 12.1: Fixed aura duration texts showing an extra seconds suffix.

---

## [11.7.0] - 2026-07-11

### ✨ Added

- UI & Quality of Life: Added an instance visibility rule for frames, action bars, cooldown viewers, spell activation overlays, Resource Bars, and Cooldown Panels.
- Group Frames: Added an optional combat indicator for party, raid, Main Tank, and Main Assist frames.
- Nameplates: Added an option to hide target marker arrows on friendly targets.
- Nameplates: Added separate default-color toggles for bosses, mini-bosses, casters, melee enemies, neutral units, tapped units, trivial units, threat warnings, and lost threat.
- Action Tracker: Added an option to track actions only during combat.
- Focus Interrupt Tracker: Added configurable glow styles, colors, insets, thickness, and Pixel glow options for text and icon displays.
- Resource Bars: Added a four-stack Whirlwind tracker for Fury Warriors.
- Quest Automation: Added separate options to prevent automatic quest completion when a quest requires a gold or currency payment.
- Cooldown Panels: Added an optional multiple-stack mode for custom durations started by cooldown updates.
- Healer Buff Placement: Added a Preview All editor option, a separate expiration-pulse color, per-indicator cooldown and charge text sizes, and a `/hbp` command for opening the editor.
- Crosshair: Added an optional range indicator based on a configurable spell for each specialization, a separate out-of-range color, and an adjustable center gap.
- Shared Media: Added a voice-line variant for Berserking.

### 🔄 Changed

- Settings Center: Reworked navigation around consolidated feature pages with a fixed sidebar search, compact matrix-style setting rows, and section tabs.
- Settings Center: Consolidated related settings across Gameplay, Interface, General, Social, Sound, Vendor, Profiles, and EQoL feature pages instead of keeping many small single-setting pages.
- Settings Center: Moved EQoL Unit Frames, custom aura containers, and the Aura Ignore Matrix into Interface; moved Mythic+ Timer into Dungeons & Mythic+; and placed Cooldown Panels and the EQoL Castbar under Bars & Cooldowns.
- Settings Center: Modernized dropdowns, toggles, text fields, buttons, changed-setting counters, search-result contrast, and navigation feedback.
- Bags: Increased the maximum number of columns from 24 to 40.
- Crosshair: Updated the default range-check spells for individual specializations so the indicator better matches each specialization's available abilities.
- Unit Frames: Improved target-switch and steady-state performance by reducing redundant cast, health, absorb, text-formatting, aura-container, Focus, and backdrop updates.

### 🧪 PTR 12.1 Only

- Unit Frames and Group Frames: Migrated aura rendering to Blizzard's AuraContainer system for restricted encounters.
- Healer Buff Placement: Added AuraContainer-backed rendering for built-in healer-buff families and arbitrary Spell IDs.
- Cooldown Panels: Added direct player-aura and enemy-target debuff tracking by Spell ID, including icon and bar layouts, alternative Aura Spell ID lists, single-aura overlays, and LibSharedMedia sounds when an aura is applied.
- Cooldown Panels: Replaced continuous Cooldown Manager aura synchronization with addon-owned tracked-aura entries; manual Cooldown Manager imports remain available as a one-time migration path.
- Resource Bars: Restored Maelstrom Weapon, Icicles, Tip of the Spear, Void Metamorphosis, and Ebon Might through AuraContainer-backed displays; Ebon Might retains a native duration fill while stack resources use protected presence and count displays.
- Resource Bars: Updated Stagger through a visibility-scoped frequent-update path matching Blizzard's behavior instead of depending on aura events.
- Mythic+ Bloodlust Tracker: Switched from Sated and Exhaustion debuffs to the active Bloodlust-family buff, including native duration display and aura-applied LibSharedMedia sounds.

### 🐛 Fixed

- Cooldown Panels and Healer Buff Placement: Fixed downward drag-and-drop ordering for panels, entries, groups, and rules.
- Resource Bars: Fixed Experience, Reputation, Honor, and resource bars briefly reappearing while visibility rules such as Hide while Skyriding should keep them hidden.
- Resource Bars: Fixed Essence segments flickering after texture or segment-inset changes.
- Resource Bars: Fixed automatic reputation watching not reacting when a reputation-gain event reported a different standing than the faction list.
- Unit Frames: Fixed player, target, focus, pet, and target-of-target frames initially appearing in the wrong position after login when anchored to a Cooldown Panel.
- Group Frames: Fixed centered raid layouts shifting outside their configured frame area when multiple groups are displayed.
- Ignore List: Fixed saved entries not loading after restarting the game following the Chat & Social child-addon split.
- Talent Reminder: Fixed the setup list being unavailable when the Teleport Compendium child addon is disabled.
- Teleport Compendium and Tooltips: Fixed Mythic+ dungeon score labels so run timing is rounded consistently with the in-game display.
- Tooltips and Group Finder: Corrected the Portuguese realm flag and aligned realm flags consistently in search results and group applications.
