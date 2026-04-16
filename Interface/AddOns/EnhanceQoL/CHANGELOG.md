# Changelog

## [10.2.0] - 2026-04-13

### ✨ Added

- Edit Mode / Anchoring: Combat Resurrection Tracker, Bloodlust Tracker, Standalone Private Auras, Combat Text, and Total Absorb Tracker can now be anchored to the same supported UI elements as Cooldown Panels.
- Group Frames / Party & Raid: Added an `Anchor to` option in Edit Mode so party and raid frames can be attached to other supported UI elements instead of only the screen.
- Unit Frames / Cooldown Viewer Anchoring: Player, party, and raid frames can now be anchored directly to the original Blizzard Cooldown Manager viewers, including `EssentialCooldownViewer`, `UtilityCooldownViewer`, and `BuffIconCooldownViewer`.
- UI / Bars & Resources: Added `Frame strata` and `Frame level offset` settings for resource bars, with the same layering applied consistently to borders, absorb overlays, and segmented resource elements.
- Unit Frames / Player Highlight: Added a separate `Highlight in combat` toggle with its own combat highlight color.
- Action Bars: Added anchor and X/Y offset controls for `Charges/Stacks` and `Keybinds` when their text override settings are enabled.
- Data Panels / Coordinates: Added a precision setting for the coordinates stream, so displayed coordinates can use `0`, `1`, or `2` decimal places.
- Map Navigation / Instance Difficulty: Added an `Anchor` setting for the Minimap difficulty text, so it can align to Minimap points like `TOPLEFT`, `TOP`, or `TOPRIGHT` and be adjusted with `x/y` offsets.
- UI / Interface: Added a `Custom` UI-scale option with a numeric input, so any value between `0.1` and `2` can be entered instead of only using fixed presets.
- Health Macro: Added `Refreshing Serum` to the combat potion pool so the macro can use it on the shared combat potion cooldown.
- Sound: Added a mute toggle for the `Gaze of the Alnseer` trinket under `Trinkets`.

### 🐛 Fixed

- Group Frames / Party & Raid: Fixed `Frame texture` selections using `Use health/power textures` resetting to `SOLID` after reload.
- Pet Frame: Fixed the pet frame sometimes staying visible even without an active pet when a visibility condition was configured.
- Group Frames / Auras: Fixed aura stack counts rendering behind custom aura borders, aura tooltips blocking clicks on party and raid frames, and debuff sub-filters hiding too many harmful auras.
- Group Frames / Auras: Restored the previous layering so party and raid buffs and debuffs stay above role icons and raid markers again.
- Group Frames: Reduced pixel-snapping jitter on party frame text, including player names and centered health or level text.
- Group Frames / Party: Fixed switching UF profiles in Delves and similar party-instance content with `Show Player` enabled sometimes throwing Lua errors and stretching the party frame to full screen height.
- Group Frames / Health: Fixed `Smooth fill` not animating party and raid health bars, so the setting works again instead of behaving the same in both states.
- Group Frames / Healer Buffs: Added the missing `Ebon Might` aura ID `395296` so the buff is tracked correctly.
- Unit Frames / Cast Bar: Fixed cast icon borders sometimes triggering a `Backdrop.lua` secret-number taint error and restored proper rendering for non-`SOLID` SharedMedia borders.
- Unit Frames / Visibility: Fixed `Show when Skyriding` and `Show when Flying` sometimes keeping unit frames visible while dead or flying as a ghost.
- Unit Frames / Status Text: Fixed `Group number font` on player and target frames using the regular status text font instead of its own dedicated font setting.
- Combat Resurrection Tracker / Bloodlust Tracker: Fixed anchored positions and anchor restoration after login or reload so the frames no longer fall back to the top-left corner.
- Focus Interrupt Tracker: Fixed missing Warlock interrupt entries so `Spell Lock` and `Axe Toss` are tracked correctly.
- Cooldown Panels: Fixed some spells occasionally showing a global cooldown swipe or timer when they should not.
- Cooldown Panels: Fixed talent-choice spell variants collapsing too aggressively onto their base spell, so legitimate combinations such as `Wild Charge` with `Dash` can be tracked together while mutually exclusive variants still deduplicate correctly.

---

## [10.1.4] - 2026-04-09

### 🐛 Fixed

- Cooldown Panels: Fixed some spells not updating their cooldown displays correctly when other abilities reduced or refreshed them.

---

## [10.1.3] - 2026-04-08

### 🐛 Fixed

- Focus Interrupt Tracker: Fixed edit mode positioning behaving erratically and not updating anchor offset controls correctly while moving the tracker.
- Vendor: Fixed auto-sell sometimes selling upgradeable gear even when upgradeable items were set to be ignored.

---

## [10.1.2] - 2026-04-08

### 🐛 Fixed

- Cooldown Panels (Tracked Auras): Fixed some spec-specific tracked aura panels and related duplicated panel states not recovering correctly after specialization changes and loading screens.

---

## [10.1.1] - 2026-04-08

### 🐛 Fixed

- Tooltip: Fixed player tooltip details such as item level, specialization, and Mythic+ score sometimes not showing.

---

## [10.1.0] - 2026-04-08

### ✨ Added

- Shared Media / Sounds: Added `Stormkeeper` as a new EQOL voiceover and added icons to the `Stormkeeper` and `Bloodlust` sound labels.

### 🐛 Fixed

- Cooldown Panels (Tracked Auras): Fixed tracked aura panels sometimes not showing correctly in combat unless a tracked aura was already active beforehand.

---

## [10.0.3] - 2026-04-08

### 🐛 Fixed

- Profiles / Export & Import: Fixed profile export and profile copy sometimes failing.
- Cooldown Panels: Fixed cooldown ready sounds sometimes not playing when another spell was cast shortly before the cooldown finished.

---

## [10.0.2] - 2026-04-08

### 🐛 Fixed

- Class Buff Reminder: Fixed Shaman `Water Shield` and `Lightning Shield` sometimes still showing as missing in Mythic+ and similar content even though the correct shield was active.
- GCD Bar: Reverted the recent GCD timing change so the bar and spark feel smooth and stable again.

---

## [10.0.1] - 2026-04-08

### 🐛 Fixed

- Chat / ChatIM: Fixed a Blizzard taint error in restricted content such as Mythic+ by no longer pushing protected Battle.net whisper targets into the global last-tell history.
- Unit Frames (Party / Raid): Fixed `Enable frame scale adjustment` only affecting Blizzard party frames. The setting now also applies to Blizzard raid frames.
- Cooldown Panels (Tracked Auras): Fixed some tracked auras such as `Hunter's Mark` not showing immediately after `/reload` or on the first target.

---

## [10.0.0] - 2026-04-06

### ✨ Added

- Cooldown Panels: Added an `Only show Panels of my Spec` editor filter and vertical mirroring for state textures.
- Group Frames: Added role-aware `Main Tank / Main Assist` controls, a separate raid `MT / MA` icon option, per-group raid visibility toggles, private-aura text scaling, and `Name` / `Level` frame strata and level settings.
- Group Frames / Auras: Added multi-select debuff filters for `Party` and `Raid` debuffs plus configurable aura borders for `Buffs`, `Debuffs`, and `Externals`, including custom external border colors and a new `Solid` style.
- Class Buff Reminder: Added food tracking with shared macro settings, per-consumable content filters for flasks, food, and weapon buffs, a global `Don't show in rested areas` option, a configurable glow color, Druid party tracking for `Symbiotic Relationship`, and an optional configurable border in Edit Mode.
- Class Buff Reminder: Added augment-rune tracking with shared bag-cache support, content-based reminder visibility, and Shaman shield reminders for `Lightning Shield`, `Water Shield`, and `Earth Shield`.
- Action Tracker: Added optional Edit Mode border styling with SharedMedia border selection, size, offset, color, and preview support.
- UI / Action Buttons: Added `Use class color` as an alternative to `Custom border color` for custom action-button borders.
- Data Panels: Added new display options for `Item Level`, `Stats`, and `Pet Tracker`, including pet reminder layouts and rested hiding.
- UI: Added standalone cast-icon border styling, expanded Square Minimap border/background styling, a detached `Minimap Button Sink` toggle, and a new Experience Bar `Current / Max (needed)` text mode.
- Mythic+: Expanded Combat Resurrection / Bloodlust tracker styling and added `Lightcalled Hearthstone` and `Preyseeker's Hearthstone` to the hearthstone list.
- Resource Bars (Brewmaster / Stagger): Added scaling beyond `100%` plus configurable `Low`, `Medium`, `High`, `Very high`, `Extreme`, `Critical`, and `Deadly` stagger colors and thresholds.
- Sound: Added mute toggles for `Belath Dawnblade`, `Lirath Windrunner`, and `Zul'Jarra`.
- Unit Frames (Boss): Increased the configurable boss-frame count to `8`.
- Group Frames (Healer Buffs / Mistweaver Monk): Added PTR prep for `Coalescence` (`1292922`) with a fallback icon.

### 🐛 Fixed

- Cooldown Panels: Fixed centered fixed-slot subgroup anchoring, tracked-aura lag spikes, spell icon dimming, charges and text overrides snapping back after refreshes, ghost previews after Edit Mode, ready sounds failing in combat, dynamic icons, and a module loading error.
- UI / Action Buttons: Fixed `Hide Border` and custom action-button borders not applying to `ZoneAbilityFrame` buttons.
- Cooldown Panels (Tracked Auras / Fixed Slots): Full fixed-slot panels now show the proper full-panel error when adding another tracked aura.
- Resource Bars / Group Frames: Fixed resource bars losing their configured positions or resolving relative-width anchors incorrectly after spec, zone, or instance changes, and corrected specialization update event handling.
- Unit Frames: Fixed boss frame reliability in some encounters, spec-mapped profile updates after role changes, and missing specialization assignments in profile export/import.
- Group Frames / Auras: Fixed centered aura layouts drifting off-center and raid `Group Growth` issues when raid frames were grouped by role.
- GCD Bar: Fixed the bar sometimes starting from `0` or briefly filling the wrong way before smoothing into the active global cooldown progress.
- Class Buff Reminder: Fixed Holy Paladin beacon tracking, Rogue poison reminders, and role-based hiding when no group role was assigned.
- Class Buff Reminder: Fixed Shaman shield detection to fall back more reliably for known spells and active shield auras.
- Chat / Group Finder: Fixed truncated copied chat history, prevented ChatIM from opening its own whisper window during chat lockdown, and reduced Blizzard UI errors on the Mythic+ score panel.
- UI: Fixed some glows not showing reliably after login or other state changes, and restored shortened actionbar labels for `Backspace` and `Space`.

### ❌ Removed

- Masque: Removed the integration from `EnhanceQoL` for now due to multiple bugs and inconsistent behavior across several modules.
- Mouse & Accessibility: Removed the separate `Enable Mouseover Cast` option.

---

## [9.11.0] - 2026-03-26

### ✨ Added

- Cooldown Panels (Fixed Slots / Dynamic Subgroups): Added configurable `Start point` and `Growth direction` options for dynamic subgroups.
- Cooldown Panels (Fixed Slots / Dynamic Subgroups): Added subgroup-wide `Icon X` / `Icon Y` offsets so grouped icons can be nudged together without moving every entry manually.

### 🐛 Fixed

- Container Actions: `Crystallized Ethereal Voidsplinter` (`240175`) is now always ignored by the container action button, so Catalyst-charge items no longer get queued there or trigger error messages.
- Groupframes: Smoothing wasn't working as expected
- Talent Reminder: Fixed dungeon-specific talent reminders not reliably triggering in some seasonal dungeons.
- Unit Frames (Target / Boss): Fixed the missing enemy-debuff filter option. Custom target and boss frames can now be switched between `Only my debuffs` and `All debuffs`, so teammate debuffs no longer stay hidden unintentionally.
- Group Finder (Mythic+ score panel): Reduced occasional Blizzard UI errors when opening or updating the score panel next to Group Finder and Raider.IO tooltips.
- Mythic+ (Chest Timers): Fixed the `+2` and `+3` timer labels overlapping each other next to the challenge timer. The labels now use a smaller font and stable relative anchoring so the vertical spacing stays consistent.
- Cooldown Panels (Fixed Slots / Layout Edit): Fixed moved icons in fixed-slot edit mode being hard to interact with. The visible shifted icon can now still be edited outside the panel area, while the ghost slot remains usable as an edit target.
- Group Frames (Party / Raid): Fixed absorb and heal-absorb overlays sometimes extending outside the frame, overlapping nearby group frames, or no longer filling correctly after the power bar was hidden.

---

## [9.10.1] - 2026-03-25

### 🐛 Fixed

- Cooldown Panels: Fixed tracked aura totem timers to keep showing correctly after the latest WoW update.

---

## [9.10.0] - 2026-03-25

### ✨ Added

- Group Frames (Party / Raid / Main Tanks / Main Assists): Added optional `Smooth fill` settings for health and power bars.

### 🐛 Fixed

- Cooldown Panels: Fixed tracked aura cooldowns sometimes showing incorrectly.
- Cooldown Panels: Fixed panels sometimes overlapping after switching spec until a reload.
- Unit Frames (Player / Target / ToT / Focus / Boss): Fixed highlight borders not lining up correctly with the health bar.

---

## [9.9.4] - 2026-03-24

### 🐛 Fixed

- Missing locale

---

## [9.9.3] - 2026-03-24

### 🐛 Fixed

- Group Frames (Party / Raid / Edit Mode): Fixed the action buttons at the bottom of the settings panel using an uneven layout. They now use a consistent grid and the panel height behaves more cleanly when many options are visible.
- Group Frames (Party / Raid / Edit Mode): Fixed `Hover`, `Target`, and `Aggro highlight` borders not showing anymore, including their sample preview.

---

## [9.9.2] - 2026-03-24

### 🐛 Fixed

- Cooldown Panels (Items / Healthstones): Fixed `Show item uses` not updating immediately after enabling it on item entries.
- Unit Frames (Boss): Highlight color wasn't working correctly

---

## [9.9.1] - 2026-03-24

### 🐛 Fixed

- Group Finder (Party Keystone): Fixed party keystone sharing continuing in the background even while the option was turned off.

## [9.9.0] - 2026-03-24

### ✨ Added

- Shared Media: 6 new border assets in midnight style
- UI / Bars & Resources: Added a standalone `Total Absorb Tracker` for the player. It can be positioned in Edit Mode and supports custom icon, text, and border settings.
- UI / Nameplates: Added Blizzard default nameplate enhancements with aura click-through and optional enemy color coding by unit type, including configurable `Boss`, `Mini-boss`, `Caster`, `Melee`, and `Trivial` colors.
- Unit Frames (Player / Target / Focus): Added incoming heal bars to the regular unit frames. The feature can now be adjusted there just like on the group frames.
- Group Frames (Party / Raid): Added an optional `Aggro highlight` border in Edit Mode with `All` / `Only non-tanks` mode, sample preview, configurable texture/layer/size/offset, and adjustable color (default orange).
- Cooldown Panels (Spells): Added an optional `Hide when no resource` setting, so spells can stay hidden until you have enough resource again. This can be set for a whole panel or adjusted per entry.
- GCD Bar: Added an optional Blizzard `XPBarAnim-OrangeSpark` overlay that tracks the active fill edge, so the bar can be hidden for a spark-only look over resource bars.
- GCD Bar: Added a configurable `Frame strata` setting in Edit Mode, matching the standalone castbar layering controls and persisting correctly through Edit Mode hydration.
- Unit Frames (Target): Added `Show group number` unit-status settings to the target unit frame, matching the existing player-frame option set.

### 🔄 Changed

- GCD Bar: Lowered the minimum configurable bar height from `6` to `1`.
- Unit Frames / Group Frames (Aura max): Lowered the minimum configurable aura count to `1` for buff, debuff, and external displays, so boss and group frames can be limited to a single aura.
- Group Frames (Party / Raid): Improved the overall performance of group-frame updates, especially for custom raid sorting. Larger roster and layout updates should now feel noticeably smoother.
- Group Frames (Party / Raid): Made group-frame refreshes more stable during sort and roster changes, so frames keep their layout more reliably while the order updates in the background.

### 🐛 Fixed

- Group Finder (Raider.IO applicant link): Fixed the LFG applicant context-menu URL builder for cross-realm names so Raider.IO profile links no longer pick up the player's own realm, and skip link generation entirely when the applicant identity is secret.
- Group Finder (Applicants / secret values): Hardened applicant sorting, ignore highlighting, and applicant-cover tweaks against secret LFG data so raid listings no longer spam taint errors when Group Finder updates while restricted content is active.
- Gear & Upgrades (Equipment Flyout): Added a separate item-level position setting for equipment flyouts and stopped reusing the Character Frame `Outside` placement there, so upgrade/replace comparisons no longer end up in confusing off-slot positions.
- Unit Frames (Player): Fixed the player-frame name sometimes staying empty after login or loading screens by refreshing the label again when the EQoL frame is shown and once more after entering the world.
- Unit Frames / Group Frames: Main group anchors and secure headers are now clamped to the screen so moved layouts cannot be dragged off-screen as easily.
- Minimap (Instance Difficulty Indicator): Stopped overriding the Blizzard difficulty icon until the EQoL text-replacement option is actually enabled, and restore the default indicator correctly when that option is turned off again.
- Square Minimap / Instance Difficulty: Delves now show `D<tier>` (for example `D8`) on the minimap difficulty indicator instead of falling back to the full `Delves` label.
- Resource Bars (Warlock / Soul Shards): Fixed `Use custom color at maximum` getting stuck after entering dungeons because the Soul Shard max-value refresh could switch between raw and non-raw power ranges.
- Resource Bars (Runic Power / Maelstrom): Fixed protected Midnight values still using absolute threshold-color handling. Both resource types now use the percent-based secret threshold path instead of absolute threshold colors.
- Group Frames (Raid / Dynamic Scaling): Fixed `Level` text and `Group <number>` indicators growing with `Preserve content size`. Those two labels now keep their normal size while the slider still compensates the rest of the raid-frame content.
- Group Frames (Raid / Edit Mode Preview): Fixed grouped raid preview resolving against the current live raid subgroup layout instead of the requested sample size, so preview blocks now stay correct while already inside a raid.
- Questing & Cinematics (Quest Automation): Reverted the split auto accept / turn-in / gossip workflow after the new model proved unreliable. Quest automation now uses the previous combined `Automatically accept and complete quests` setting again, while keeping the Retail-compatible gossip selection path.
- Questing & Cinematics (Auto Gossip / Quest Turn-In): Fixed mixed quest-and-gossip NPCs immediately jumping into RP dialogue even while quest turn-in automation was off. Auto gossip no longer overrides quest interactions, and single-option gossip only auto-continues when no quest entries are present.
- Questing & Cinematics (Auto Accept / Turn-In): Fixed stale pending auto-accept quest state causing modifier-based quest turn-ins to close the quest frame instead of completing the hand-in, and leaving later quest interactions stuck in the same broken state.
- Questing & Cinematics (Auto Gossip Settings): Fixed the broken `Configured gossip IDs` picker causing Blizzard Settings type errors. Gossip IDs are now managed via `/eqol aag <id>` and `/eqol rag <id>` instead.

### ❌ Removed

- Dialogs & Confirmations: Removed the `Replace enchant` auto-confirm option because it could block enchant replacements instead of helping.
