# Changelog

## [11.6.0] - 2026-07-06

### ✨ Added

- Cooldown Panels: Added export support, action bar anchoring, per-entry specialization filters, hide-unavailable editor views, custom spell/item tracking, automatic racial durations, and a persistent switch between the modern editor and the classic editor with classic group management.
- Resource Bars: Added customizable Reputation and Honor bars with Edit Mode positioning, styling controls, session rates, estimates, and Experience bar style copying.
- Mythic+ Timer: Added profile export/import support and more List layout controls.
- UI & Quality of Life: Added a focus-target visibility rule, a separate enemy nameplate threat-color toggle, a Damage Meter tooltip trigger option, and new Teleport Compendium hearthstone and portal data.

### 🔄 Changed

- Modular Addons: Split major features into standalone Enhance QoL child addons while keeping shared settings, profiles, locales, and core integration in the main addon.
- Settings: Moved module-specific Profile pages and feature settings into their owning child addons so disabled child addons no longer leave inactive settings pages behind.
- Resource Bars: Simplified segmented resource layouts and improved separated segment rendering.

### 🧪 PTR 12.1 Only

- Added compatibility handling for Blizzard's restricted aura data and AuraContainer-backed Unit Frame and Group Frame aura rendering.
- Temporarily gates aura-dependent features on PTR 12.1 when Blizzard does not expose usable aura information, including custom default aura containers, aura-driven resource bars, Cooldown Manager aura entries, private aura handling, reminder checks, dungeon/raid aura trackers, and tooltip aura fallback helpers.

### 🐛 Fixed

- Cooldown Panels: Fixed editor drag-and-drop issues, duplicated panel positioning, synced cooldown entries disappearing or flickering, resource/usability checks for special spells, and several anchoring/update edge cases after the modular addon split.
- Unit Frames and Group Frames: Fixed Party/Raid anchor resolution, class-colored Data Bar updates, Boss Frame detached power bar behavior, and player-frame border reloads.
- Resource Bars: Fixed login anchoring, Edit Mode availability, segmented border/gradient rendering, threshold display, and custom Reputation/Experience interactions.
- Settings and Child Addons: Fixed missing settings pages, child addon startup initialization, Vendor filter setup, Tooltip custom anchoring, Mover handle activation, and several split-related runtime paths.
- Teleport Compendium and Dungeon & Raid: Fixed portal metadata, dungeon portal score labels, Bloodlust/BR anchoring, and Mythic+ Timer List layout behavior.
