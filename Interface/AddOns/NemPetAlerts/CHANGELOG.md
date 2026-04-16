## v12.0.17 (2026-04-12)

## Options Panel Improvements

- Non-pet specs now show a clean "Spec Not Supported" panel on first click — no more blank panel or flashing options
- All unsupported specs now show the same unified message instead of separate "Class Not Supported" handling
- Options panel uses the default cyan theme for non-pet specs instead of showing class colors

## Code Cleanup

- Removed overlay system — the unsupported-spec panel is now built directly into the UI rather than layered on top
- Removed class-based support checks (`SUPPORTED_CLASSES`, `IsSupportedClass`) — support is now determined entirely by whether a spec module is active
- Slash commands now show a clearer message for unsupported specs

---

## v12.0.16 (2026-04-11)

## Full Spec Support

Nem: Pet Alerts now works on a **per-spec system** instead of grouping support by class. The addon now loads the correct module for your active specialization, making spec swaps cleaner and more accurate.

### Supported Specs

- Beast Mastery Hunter
- Marksmanship Hunter
- Survival Hunter
- Affliction Warlock
- Demonology Warlock
- Destruction Warlock
- Frost Mage
- Unholy Death Knight

### What changed

- The addon now loads the correct alert module based on your active spec
- Switching specs now fully updates the addon immediately
- Each supported spec now has its own independent module
- Internal structure was cleaned up for consistency and easier maintenance
- TOC updated to load all spec files correctly

### What stayed the same

This update does **not** change gameplay behavior.

You still get the same:

- alerts
- priority order
- display layout
- options panel
- slash commands
- sounds
- test mode behavior
- saved settings compatibility

No settings reset or migration is needed.

---

## v12.0.15 (2026-04-05)

## Quality of Life

- Test mode is now fully disabled for unsupported classes
- Unsupported classes can no longer use addon control slash commands

This prevents confusion and avoids exposing features that do not work for that class.

---

## v12.0.14 (2026-04-05)

## Unsupported Class Improvements

Unsupported classes now get a cleaner and clearer experience.

### New Features

- A **Class Not Supported** message in the options panel
- A visible list of supported classes
- Four new bundled sounds:
  - Bell
  - Lamp
  - Ping
  - Redfox

### Changes

- Unsupported classes now use a cleaner blue panel theme
- Mage and Death Knight option panels now show for all specs in those classes
- The addon now skips unnecessary settings logic on unsupported classes
- Bundled sound list was cleaned up

### Notes

- On first install, unsupported classes are disabled by default
- Existing saved settings on older characters are unchanged

---

## v12.0.13 (2026-03-30)

## Slash Commands

Added chat commands for easier addon control:

- `/npa on`
- `/npa off`
- `/npa toggle`
- `/npa test`
- `/npa status`
- `/npa help`
- `/npa version`

Also added:

- `/petalerts` as a full alias for `/npa`

### Changes

- `/npa` is now the main slash command
- `/nem` was removed to avoid conflicts with future Nem addons
- Slash command behavior now better matches the options panel
- Help text formatting was improved
- Options subtitle updated to reference `/npa`

---

## v12.0.12 (2026-03-27)

## Visual Updates

- Default alert colors were updated for new installs and resets
- Alert order in the right column of the options panel was improved

Existing custom colors are unchanged.

---

## v12.0.11 (2026-03-25)

## New Feature: Pet Not Attacking

Added a new alert that warns when your pet is in combat but not actively attacking.

### Highlights

- Uses a short grace period to avoid false warnings
- Resets cleanly when combat ends
- Works in difficult content like Mythic+ and rated PvP
- Updates quickly when your pet changes target

### New Features

- New **Pet Not Attacking** checkbox in the options panel
- Per-class text for this alert
- Better test mode support for all classes
- Extra event handling for faster updates in combat

### Changes

- Alert layout rebuilt into a cleaner 6-row stack
- Test mode now shows more complete coverage for all supported classes
- Options panel alert ordering was improved
- Heal Pet behavior was cleaned up across classes
- Test mode no longer hides frames for spec-gated classes

### Bug Fixes

- Fixed Heal Pet and similar alerts not showing correctly in test mode without a pet active
- Fixed Pet Not Attacking timer keeping stale state between pulls
- Fixed Death Knight test mode showing too few alerts

---

## v12.0.10 (2026-03-24)

## New Features

- Added two new bundled sounds:
  - Bleeper
  - MetalGearSpotted

### Changes

- Wake Up Pet now appears immediately when Play Dead is used
- Wake Up Pet now correctly takes priority over Heal Pet while fake death is active

### Removed

- Heal Pet sound trigger was removed for now

WoW currently restricts safe health value handling in some content, which makes a reliable sound trigger impossible right now.

---

## v12.0.9 (2026-03-23)

## New Features

- **Heal Pet threshold setting**
  - Set the health percent where the alert appears
  - Range: 1-99%
  - Default: 30%
- **Heal Pet alert**
  - Warns when your pet drops below the selected health threshold
- **Pet On Passive alert**
  - Warns when your pet is set to Passive during combat
- **Class-colored options panel**
  - The panel now matches your class theme

### Changes

- The options panel was reorganized into:
  - Display
  - Sounds
  - Alerts

---

## v12.0.8 (2026-03-22)

## Sound Options Update

### New Features

- Sound dropdowns for:
  - Pet CC
  - Pet Died
- Preview buttons for sound testing
- New bundled sounds:
  - RobotBlip
  - SharpPunch
  - Shotgun
  - WaterDrop
- LibSharedMedia sound support

### Changes

- Sound selection is now saved per character

---

## v12.0.7 (2026-03-20)

## Options Panel Upgrade

- Added a font picker with preview
- Added a scale slider
- Added a font size slider
- Redesigned the options panel with cleaner section styling

---

## v12.0.6 (2026-03-18)

## Frame and Positioning Update

### New Features

- AddOn Compartment support
- Draggable alert frame
- Lock / Unlock button
- Reset Position button
- Saved frame position between sessions

### Changes

- Frame position saving is now more reliable across different resolutions

---

## v12.0.5 (2026-03-16)

## Fixes and Background Improvements

### New Features

- Better suppression while mounted, flying, or on flight paths
- Faster Water Elemental death detection
- Locale-safe Warlock taunt spell handling

### Changes

- Warlock taunt detection improved
- Pet alive check cleaned up
- Pet CC detection improved
- Party taunt checking cleaned up

### Bug Fixes

- Fixed false No Pet alerts during travel
- Fixed wrong Felguard taunt spell ID
- Fixed fake death detection crashes
- Fixed Pet In CC triggering on slows and snares
- Fixed Grimoire of Sacrifice wrongly triggering pet death sound

---

## v12.0.4 (2026-03-15)

## Multi-Class Expansion

### New Features

Added support for:

- Warlock
- Frost Mage
- Unholy Death Knight

Also added on-demand tickers for Mage and Death Knight.

### Changes

- Addon renamed to **Nem: Pet Alerts**
- Saved variables renamed to `NemPetAlertsSV`

---

## v12.0.3 (2026-03-13)

## New Features

- Added Pet Died sound: **OhNo.ogg**

---

## v12.0.2 (2026-03-10)

## Bug Fixes

- Fixed a taint crash in `UNIT_SPELLCAST_SUCCEEDED`

---

## v12.0.1 (2026-03-09)

## Bug Fixes

- Fixed a taint crash in fake death detection
- Removed the polling ticker and made detection fully event-driven
- Added bundled sound: **Sonar.ogg**

---

## v12.0.0 (2026-03-07)

## Initial Release

First release of **Nem: Pet Alerts**.

### Included Alerts

- No Pet
- Pet Died
- Pet Fake Death
- Turn Off Autocast Taunt
- Pet In CC

### Included Features

- CC sound
- options panel
- test mode
- draggable frame

### Hunter Support

- Beast Mastery
- Survival
- Marksmanship with Unbreakable Bond
