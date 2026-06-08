# Nem: Pet Alerts — Changelog

---

## v12.0.26 — May 31, 2026

### Settings — Now Account-Wide

Every per-alert setting is now shared across your entire account. Enable toggles, sound choices, colors, and custom alert text persist across **both** spec changes and character changes — set them once on any character and they apply everywhere, for every pet class. Previously each spec kept its own settings, so you had to configure every spec separately and start over again on each alt. That's gone; there's now one shared configuration.

This also closes a long-standing annoyance where a setting you changed during a spec swap could quietly revert on your next reload. With a single shared configuration there's nothing spec-specific left to drop, so it can't happen anymore. Your existing settings carry over automatically the first time you log in on v12.0.26; if the same alert was set up differently on two specs, the version from your current class wins.

Because sounds are shared now too, the addon is smarter about class-specific voice clips: if you pick one of the bundled class voice packs as your shared choice and then play a different pet class, it automatically falls back to that class's matching default cue instead of playing the wrong class's voice. Generic sounds — Bell, Sonar, Whistle, and the rest — play everywhere unchanged.

### Pet in CC — Countdown Timer Removed

The crowd-control countdown timer added in v12.0.25 has been removed. In Mythic+, raid, and rated PvP, the game hides how much time is left on crowd-control effects, so the timer had no reliable number to count down from in exactly the content where it mattered most. Rather than show a timer that silently breaks in instances, it's gone. The "PET IN CC" alert itself is unaffected — it still fires whenever your pet is crowd-controlled. Only the numeric countdown underneath it is removed.

### Heal Pet — Overlay Fixed in Instanced Content

The Heal Pet overlay could still break and disappear in Mythic+, raid, and rated PvP after the v12.0.25 changes. In that content the game hides your pet's exact health, and the overlay was still depending on it — so it failed in the very places you most need it. It no longer relies on that hidden health value, and it fades in and out correctly across all content again.

Turning the addon off now also fully stops the Heal Pet overlay in the background — previously it kept updating quietly even with the addon disabled.

### Warlock — Voidwalker Taunt Detection

The Taunt Autocast warning now recognizes the Voidwalker's Threatening Presence. Previously the addon didn't account for this ability when checking whether your demon's taunt was set correctly, so Voidwalker users could get an inaccurate warning. Fixed.

### Alert Fonts — Friz Quadrata Bundled

The Friz Quadrata font now ships with the addon, so it's available in the Alert Font dropdown without relying on another addon to provide it. A duplicate Friz Quadrata entry that could show up in the dropdown has been hidden — one clean entry instead of two.

### Bug Fixes

- **Options panel now refreshes when you switch specs with it open.** Changing specs while the options window was open could leave its rows showing the previous spec's alerts until you reopened it. The panel now refreshes on a spec change so it always matches your active spec.

## v12.0.25 — May 17, 2026

### Alert System — Cascade Isolation, TTS Priority Queue, and Event-Driven Evaluation

Every alert and module hook now runs inside an isolation boundary. Previously, a single failing alert — for example, picking a missing or malformed sound for Heal Pet — could throw a Lua error mid-evaluation and silence every other alert in the addon until the user reloaded the UI. One bad row took the whole panel offline. Now a fault in any individual alert is caught and contained: the failing alert stops firing, but every other alert keeps working as if nothing happened. The error is recorded with a timestamp instead of vanishing into the chat log, and `/npa status` lists any logged errors so you can see at a glance whether anything has gone wrong since you logged in. No more silent failure modes — if something breaks, you'll see it the next time you check status.

Voice clips — the bundled "Class: ..." TTS sounds — now route through a four-tier priority queue (LOW / NORMAL / HIGH / CRITICAL) modeled after the cue system in Nem: Healer Alerts. Higher-priority clips preempt lower-priority ones, identical-priority clips drop instead of stacking on top of each other, and each individual alert has a 4-second per-alert cooldown so a flickering condition can't machine-gun the same cue. A 1.5-second grace window at combat start lets the very first cue at pull time skip the normal post-cue gap, so you hear it immediately rather than waiting for the queue to settle. Generic SFX (Bell, Sonar, Whistle, and the rest of the non-voice library) bypass the queue entirely and overlap freely — the queue exists only to keep the voice pack from talking over itself. Priority assignments per alert: Pet Dead and Call Pet are CRITICAL, Pet in CC / Pet Not Attacking / Wake Up Pet are HIGH, and Pet on Passive / Pet Taunt Autocast are NORMAL — so a "PET DEAD" cue can talk over a "PET ON PASSIVE" cue, but not the other way around.

The Heal Pet alert is now driven by the ColorCurve API instead of a raw health-percentage read. In WoW 12.0+ restricted-aura content — Mythic+, raid, rated PvP — pet health is masked as a secret value, which broke the old "is the pet below the threshold" boolean check: any attempt to read the number out of the engine threw, and the alert went silent in exactly the content where you most want it. The overlay now refreshes its alpha at 500ms via a ColorCurve hook that produces a secret-safe alpha value, and that alpha is fed directly into the overlay frame — the tainted health number never enters Lua as a number, so the restricted contexts are no longer a wall. The visual overlay works in M+, raid, and rated PvP again. As a related constraint: the Heal Pet *voice cue* is disabled at the engine level for the foreseeable future because there is no API path to a reliable boolean ("is the pet below threshold, yes or no") in those restricted contexts — ColorCurve gives you a graduated alpha, not a crossing event. The sound row for Heal Pet is hidden in the options panel to reflect that, but your previously selected sound name is preserved in saved variables, so if the API ever opens up the row will reappear with your old choice intact.

The 0.25-second polling ticker that used to re-run every alert four times a second is gone. Alert state changes are now driven entirely by the WoW events that already cover them — UNIT_HEALTH, UNIT_AURA, UNIT_PET, UNIT_TARGET, PLAYER_REGEN_DISABLED, PLAYER_REGEN_ENABLED — so the addon only does work when something actually changed instead of waking up four times a second to ask. The Frost Mage and Unholy Death Knight modules previously ran their own private 0.25-second "wait for the pet to appear" fallback ticker on top of the global one; that's been replaced by pure UNIT_PET handling with a single-shot 0.5-second safety net at module activation, which exists only to cover the narrow case where UNIT_PET fires before the module finishes registering its handler. The 500ms Heal Pet alpha refresh is the only periodic ticker that survives, and it survives only because the ColorCurve API genuinely requires polling — there is no event to listen to.

`/npa test` now cycles alerts visually only — sounds do not play during the test loop. Test cycles previously poured every alert's cue into the voice queue at full speed, which both polluted the per-alert cooldowns (so a real alert that fired right after the test ended could get suppressed) and turned the test mode into a wall of overlapping TTS. The test loop is now strictly a visual sanity check: walk through what each alert looks like on screen, with no sonic clutter and no impact on the queue's state.

### Alert Sounds — Display-Coupled Cue Gating

Audio cues now fire when an alert actually appears on screen, not when the underlying condition first becomes true. If a higher-priority alert is already showing — say "WAKE UP PET" — and a lower-priority condition becomes true at the same time — say "PET ON PASSIVE" — the lower alert's cue is held silent. The moment you wake the pet and the lower alert pops up on screen, you hear its cue.

A 0.5-second grace gap between consecutive cues keeps rapid alert switches from dogpiling audio. If a queued cue's alert vanishes from the screen before the gap elapses, the cue drops — you don't hear sound for an alert you never actually saw. Critical-priority alerts — "PET DIED" and "CALL PET" — bypass this grace and fire as soon as they appear, since those cues are time-sensitive enough that a delay would defeat the point.

Logging in or switching specs no longer triggers a wave of cues for whatever was already true at the moment you arrived: a 1-second silence on activation lets the addon settle without blasting you on entry. The same brief silence applies when leaving `/npa test`, so the test loop can never tail off into an unexpected real cue.

Voice preemption between alerts is also fixed: when a higher-priority cue interrupts a lower-priority one (for example, "CALL PET" cutting in over "WAKE UP PET"), the higher cue actually plays through. Previously the lower cue would be cut off mid-word but the higher cue would silently drop, leaving you with the hard stop and no replacement audio.

### Pet in CC — Countdown Timer

When the "Pet in CC" alert is active, a countdown timer now appears directly below the alert text showing the remaining duration of the longest crowd-control aura on your pet. The timer renders in white at roughly 70% of your configured font size, anchored just below the main alert — visible enough to read at a glance without competing with the alert itself.

The timer updates at ~10Hz and clears automatically within a tick of the CC expiring, driven by the existing UNIT_AURA event chain. A per-character "Show CC Timer" checkbox in Alert Options (default on) lets you turn it off if you prefer the plain alert. In `/npa test`, the timer loops a synthetic 5.0 → 0.1 → 5.0 countdown so you can see what it looks like without needing an active CC.

### Hunter — Voice Pack and Full Sound Coverage

The Hunter module now ships a dedicated set of voice cues — seven bundled TTS sounds, one per sounded alert. Open any sound dropdown in the options panel and they appear under a new "Class TTS" header at the bottom: Pet Died, Wake Up Pet, Call Pet, Toggle Pet Taunt, Pet in CC, Pet on Passive, Pet Not Attacking. They are now the default sound for every Hunter alert that plays sound — first-time installs (and anyone who hits Restore Defaults) hear the new voice pack out of the gate. Previous sound choices stored on existing characters are preserved.

Every sounded Hunter alert now plays its sound on the rising edge of the alert firing — previously only "Pet Died" and "Pet in CC" actually played anything. Wake Up Pet, Call Pet, Pet Taunt Autocast, Pet on Passive, and Pet Not Attacking now each fire their cue once when the condition first becomes true and stay silent until the condition clears and re-occurs. No spam if a state lingers; one chirp per real transition.

Sounds are suppressed on initial spec activation so logging in or reloading with an active alert (e.g., a passive pet in combat) doesn't immediately blast a cue — the first transition you hear is one that happens after you finish loading.

### Hunter — Bug Fixes

- **Wake Up Pet alert no longer sticks on screen.** After casting Wake Up Pet on a feigning pet, the "WAKE UP PET" alert could remain visible even though the pet was already up and acting normally. The alert now clears reliably as soon as the pet is woken and stays cleared. Affects Beast Mastery, Marksmanship, and Survival.

### Sound Dropdowns — Scrollable and Wider

Every sound dropdown in the options panel now scrolls when the list is long, matching the behavior of the Alert Font dropdown. With the Hunter voice pack added, the sound list is now too long to fit comfortably on screen — the new scroll mode keeps the dropdown a fixed height and lets you scroll through the full list instead of running off the bottom of the panel.

Sound dropdowns also widened from 160px to 220px to fit the longer Class TTS labels without truncation. The Preview button stays anchored to the dropdown's right edge and shifts over with it.

### Warlock — Voice Pack and Full Sound Coverage

The Warlock module now ships a dedicated set of voice cues — eight bundled TTS sounds covering every alert. Open any sound dropdown on a Warlock spec and they appear under "Class TTS": Demon Died, Sacrifice Demon, Summon Demon, Toggle Demon Taunt, Demon in CC, Demon on Passive, Demon Not Attacking, and Heal Demon. They are now the default sound for every sounded Warlock alert across Affliction, Demonology, and Destruction.

Previously the only Warlock sounds were the generic "OhNo" (Demon Died) and "Sonarr" (Demon in CC); the other six alerts were silent by default. Every sounded Warlock alert now plays its dedicated voice clip on the rising edge of the alert firing — one chirp per real transition.

The Heal Demon clip is bundled but the alert stays silent for now, mirroring Hunter's Heal Pet treatment — pet health detection is blocked by the restricted-aura API in M+, raid, and rated PvP, so the cue can't fire reliably. The clip is in the box ready for the day that API restriction lifts.

### Frost Mage — Voice Pack and Full Sound Coverage

The Frost Mage module now ships a dedicated set of Water Elemental voice cues. Each of the six sounded Frost Mage alerts comes in two pronunciations — the full "Water Ele" and the shortened "Wele" — so every Class TTS dropdown on a Frost Mage gets twelve new entries: Summon Water Ele, Water Ele Died, Water Ele in CC, Water Ele Not Attacking, Water Ele on Passive, and Water Ele Health Low, plus a matching "Wele" line for each. Pick whichever pronunciation reads more naturally to you. The "Water Ele" set is the default on fresh installs and after Restore Defaults; previous sound choices on existing characters are preserved.

Every sounded Frost Mage alert now plays its dedicated voice clip on the rising edge of the alert firing — previously the spec leaned on the generic "OhNo" (Pet Died) and "Sonarr" (Pet in CC), and was silent for Summon Water Ele, Pet on Passive, and Pet Not Attacking entirely.

The Water Ele Health Low clip is bundled but the alert itself stays silent for now, matching the Hunter and Warlock heal treatments — pet health detection is blocked by the restricted-aura API in M+, raid, and rated PvP, so the cue can't fire reliably. The clip sits ready in the dropdown for the day that API restriction lifts.

### Sound Dropdowns — Per-Class TTS Filter

The Class TTS section of every sound dropdown is now filtered to the active spec's class. On a Frost Mage you see only the Water Elemental cues; on a Hunter you see only the Hunter pet cues; on a Warlock only the demon cues. Previously the dropdown listed every Class TTS clip in the bundled pack regardless of which spec you were configuring, which made the list noisy — picking "Warlock: Demon Died" as your Frost Mage's Pet Died sound technically worked but obviously wasn't the design intent.

Generic SFX (Bell, Sonar, RobotBlip, and the rest of the non-voice library) continue to appear in full so any class can fall back to a pure-tone sound. Specs that don't yet ship a class voice pack get a Generic-only dropdown with no orphan "Class TTS" header.

### Unholy Death Knight — Voice Pack and Default Sound Coverage

The Unholy Death Knight module now ships a dedicated set of Ghoul voice cues — four bundled TTS sounds covering every sounded alert: Raise Ghoul, Ghoul in CC, Ghoul on Passive, and Ghoul Not Attacking. Open any sound dropdown on Unholy DK and they appear under "Class TTS". They are now the default sound for every sounded Unholy DK alert; previous sound choices on existing characters are preserved.

Heal Ghoul stays intentionally silent — no clip is bundled. Pet health detection is blocked by the restricted-aura API in M+, raid, and rated PvP, so the cue can't fire reliably, mirroring the Hunter, Warlock, and Frost Mage heal treatments.

### Per-Spec Settings — Independent Configuration

Sound choices, alert toggles, colors, and custom alert text now save independently per spec. Previously, choosing "Hunter: Pet Died" as your Pet Died sound on a Hunter would silently overwrite the demon-pack default that a Warlock spec expected — every per-alert setting was sharing a single account-wide slot regardless of which spec was active. That cross-spec bleed is gone: Hunter, Warlock, Mage, and DK each maintain their own sound dropdowns, toggles, color picks, and custom text, and switching specs no longer disturbs any of them.

What stays shared across all specs, because they are display-level decisions: master enable/disable, alert font and font size, frame position, and the screen-flash effect.

Existing characters with customizations from earlier versions: on first `/reload` after the upgrade, your existing per-alert settings transfer to whichever spec you log in to first. Other specs you haven't activated yet start fresh on the new defaults — which is the correction that lets the new Warlock voice pack actually take effect on Warlock specs and the Hunter pack on Hunters. **Restore Defaults** in the options panel now factory-resets the active spec's per-alert settings (sounds, toggles, colors, custom text) without touching other specs or your global display settings, so wholesale wiping one spec back to its new defaults is a single click.

### Options Panel — Show CC Timer Promoted to Display

The "Show CC Timer" checkbox has moved from each spec's Alert Options section up to the global Display section, sitting underneath Flash Animation. It is now a single account-wide toggle — flipping it once applies to every pet spec. Previously every spec had its own copy of the same checkbox, which made it easy to think you'd disabled the CC timer when you'd only disabled it on one spec. Existing per-spec values are migrated into the new global on first `/reload`.

### Heal Pet Threshold — Default Raised to 50%

The default Heal Pet Threshold for fresh installs is now 50% (was 30%). Existing characters keep whatever value they already had set; clicking **Restore Defaults** on a spec will reset that spec's threshold to the new 50% default along with the other per-spec defaults.

### Warlock — Felguard Taunt Autocast Detection Fix

The "TURN OFF DEMON TAUNT" alert now fires correctly when the Felguard's Threatening Presence autocast is enabled in a group with a tank. Previously the alert only fired for the Voidwalker's Suffering — the Felguard case was looking for the wrong spell ID, so the pet bar scan never matched and the alert silently never appeared. Voidwalker behavior is unchanged.

### Display — Alert Spacing Auto-Scales with Font Size

The vertical spacing between stacked alerts (and the position of the Pet in CC timer beneath the CC alert) now scales with your chosen Font Size. Previously the gaps were fixed in absolute pixels tuned for the 25px default — so at a 10px font, alerts sat with wide empty bands between them that looked orphaned, and at 50px the stack stayed cramped against itself. The slider now adjusts both the text height and the inter-alert gap proportionally, so any font size you pick produces a clean, evenly-spaced stack with no manual tuning needed.

---

## v12.0.24 — May 9, 2026

### All Warlock Specs — "Summon Demon" / "Demon Died" False Alerts In Combat

The "SUMMON DEMON" and "DEMON DIED" alerts no longer fire incorrectly during combat when you are talented into Grimoire of Sacrifice. Previously both alerts could lock on for the rest of the fight in Mythic+, battlegrounds, arenas, or open-world combat — even though the Sacrifice buff was active. The "DEMON DIED" alert specifically fired every time you sacrificed your demon mid-pull, since the brief dead-state during sacrifice was being treated as a real pet death.

Both alerts now stay silent during combat, and for 1.5 seconds afterward to give the buff state time to settle. The alert state then re-evaluates automatically at 1.5s and 2.5s after combat ends without polling anything in between.

The "Sacrifice Demon" alert (the one telling you to sacrifice when you have the talent but no buff yet) is unaffected and still fires the same way out of combat.

**What changed under the hood:** in restricted execution contexts (M+ combat, rated PvP, and certain open-world combat scenarios) the WoW engine masks the Sacrifice buff's spell ID as a secret value, making the buff invisible to addons regardless of which aura API they use — the index walk and `C_UnitAuras.GetPlayerAuraBySpellID` both return as if the buff weren't there. Since direct buff inspection cannot work in those contexts, the talent branches in each Warlock spec's `GetHighestPriorityAlert` (both the no-pet path and the dead-pet path) and the `sacSuppressed` check in `PreEvaluate` now treat any active combat as "buff present" for a Grimoire-of-Sacrifice warlock. A new `state.sacGraceUntil` field, set to `GetTime() + 1.5` on `PLAYER_REGEN_ENABLED` (only when the talent is taken), extends that suppression for 1.5 seconds after combat ends; two `C_Timer.After` one-shots at 1.5s and 2.5s force re-evaluation once the engine has uncovered the aura, so the alert state catches up promptly without any polling. As a small secondary win, the buff scan now tries `GetPlayerAuraBySpellID` as a fast path before falling back to the 40-aura index walk in unrestricted contexts. Applied identically to Affliction, Demonology, and Destruction.

### Options Panel — Brought Up To Suite Standards

The options panel has been rebuilt to match the canonical Nem: Alerts suite layout. Most of these changes are layout polish, but one — the removal of the Alert Text Scale slider — will be visible if you customized it.

- **Alert Text Scale slider removed.** The Display section now controls alert text sizing with the **Font Size** slider alone, matching the rest of the suite. If you previously had Alert Text Scale set to anything other than the default (1.0), your alert text will appear at a different size on first login after this update — adjust **Font Size** up or down to compensate. Your saved scale value is cleared automatically.
- **Alert Font dropdown moved.** The font selector now lives in the **Display** section (right column, beneath the Font Size slider) instead of in Alert Options. Same dropdown, same fonts — just a more sensible home.
- **Sounds section alignment.** The sound dropdown next to each row was sitting 40px too far right. It now lines up with the dropdowns in the other Nem: Alerts addons.
- **Alerts grid spacing.** The alert checkboxes were a few pixels off in column position and a few pixels tight in row spacing. Both now match the suite standard, so the section feels less cramped.
- **Heal Pet Threshold reformatting.** The input is now labeled "Heal Pet Threshold (%)" with the percent baked into the label — the separate "%" suffix is gone. Functionality is unchanged.
- **Alert Options spacing.** Closed the oversized gap between the Heal Pet Threshold row and the eight alert text edit boxes underneath it. The block now sits at the same tightness as the equivalent section in Nem: Healer Alerts.
- **Class-colored text inputs.** Every text input on the options panel — the Heal Pet Threshold field and all eight alert text override boxes in Alert Options — now renders its text in your active spec's class color, matching the slider value field, section borders, and scrollbar thumb. Switching specs retints them automatically.
- **Pixel-level alignment polish.** The Font Size slider and Alert Font dropdown in the Display section nudged a few pixels right so they sit directly above the right column of alert checkboxes. The alert text override boxes in Alert Options shifted similarly so each box's left edge lines up with the checkbox icon directly above it. Nothing functional — the panel just looks cleaner now.
- **Scrollbar bottom flush with Alert Options.** When scrolled all the way down, the bottom of the Alert Options section box now lines up exactly with the bottom of the scrollbar track — the previous ~16px of empty padding below the box is gone. Top edge alignment is unchanged.

**What changed under the hood:** the panel now exposes the canonical `specHelpers` contract (`MakeCheckbox`, `MakeCheckboxAt`, `MakeCheckboxRow`, `MakeCheckboxWithNumeric`, `MakeNumericInput`, `Spacer`) and calls `mod:BuildAlertOptions(box, db, specHelpers)` on the active module, matching the rest of the Nem: Alerts suite. Each pet spec now declares its own `BuildAlertOptions` block that registers the heal pet threshold via `helpers:MakeNumericInput`. The Alert Font dropdown is created once at panel-init time (parented to `displayBox` so hide/show propagates) instead of being rebuilt on every spec change. Saved variables bumped to `ver=3`; one-shot migration scrubs the stale `db.scale` field.

---

## v12.0.23 — May 8, 2026

### All Warlock Specs — Sacrifice Demon Alert Fix

The "SACRIFICE DEMON" alert now fires correctly when you have the Grimoire of Sacrifice talent taken and your demon is still summoned. Previously the alert was silently suppressed as long as your demon was alive — even though the whole point of the talent is that the demon shouldn't be out at all. Affects Affliction, Demonology, and Destruction.

**What changed under the hood:** in the sac-talented branch of each Warlock spec's priority resolver, the heal-pet check was firing first and claiming the display slot with an invisible heal-pet alert (alpha=0 when the pet is healthy), preventing the sacrifice alert from ever rendering. The heal-pet check is now bypassed entirely when Grimoire of Sacrifice is talented — pet health is irrelevant if the demon's purpose is to be sacrificed. Pet death detection (the "DEMON DIED" alert) is unaffected and still fires as before.

### Options Panel — Bottom Button Alignment

The four buttons at the bottom of the options panel (Test, Unlock Frame, Center Position, Restore Defaults) are now all the same width and remain perfectly centered as a group. Previously each button was a different size, which left the row looking uneven and slightly off-center.

### Options Panel — Display Sliders Repositioned

The Alert Text Scale and Font Size sliders in the Display section have moved back to the standard position used by the rest of the Nem: Alerts suite. Previously they sat 40px farther to the right than the matching sliders in Nem: Healer Alerts.

### Options Panel — Scrollbar Color on Spec Change

The thin scrollbar on the right side of the options panel now updates its color to match your active spec's class color when you change specs. Previously the thumb could keep the previous spec's color (or the default cyan) until a UI reload.

---

## v12.0.22 — April 24, 2026

## Core Refactor — NPA / NHA Alignment

Structural refactor to align **Nem: Pet Alerts** and **Nem: Healer Alerts** to a shared core layout. No gameplay behavior changes.

### What changed

- **Database access** — all reads and writes now route through a single internal alias. Behavior is unchanged.
- **Event debouncing** — burst events (e.g. spec change firing multiple events at once) now coalesce into a single re-evaluate instead of one per event.
- **File layout** — sections reorganized to match the canonical NHA structure.
- **`IsFullyImplemented`** moved to sit immediately after `FindActiveModule`.

### Bug fix

- `CreateDisplay` was ignoring the saved frame anchor and hardcoding `CENTER`. The frame still ended up in the right spot because `ApplyDisplaySettings` ran immediately after, but the initial placement could flicker on login for non-center anchors. Fixed.

### Slash command cleanup

- `/npa off` and `/npa toggle` now fully reset alert state instead of just hiding the display.
- Duplicate test-mode teardown logic removed from both commands — both now delegate to `ToggleTest()`.

### Dead code removed

- `CORE_DEFAULTS.alertColors = {}` — redundant; `ActivateModule` always initializes this.

### Spec module contract

- The optional `Debug` hook is now officially documented in the spec module contract.

---

## v12.0.21 — April 22, 2026

## Bug Fix — Spec Detection Broken in Patch 12.0.5

`GetSpecialization()` can return a secret value in certain restricted execution contexts since patch 12.0.5. The previous code passed that value directly into `GetSpecializationInfo()` and then compared the result to a plain number — both operations throw a Lua error when a secret value is involved, causing the addon to fail to identify the active spec on login or spec swap.

### Fix

- `GetSpecID()` now wraps `GetSpecializationInfo()` in `pcall` and checks the return with `issecretvalue()` before using it
- A secondary fallback walks spec slots 1–4 to find a non-secret specID that matches the player's class and a registered module, then verifies the active slot with a second `pcall`
- `FindActiveModule()` wraps the `mod.specID == currentSpecID` comparison in `pcall` as an additional safeguard, so a secret value that slips through `GetSpecID()` fails silently instead of crashing the addon

---

## v12.0.20 — April 19, 2026

## Options Panel — Layout and Spec Cleanup

### Dynamic Section Sizing

The Sounds, Alerts, and Alert Options sections now resize and reposition themselves dynamically based on the active spec's alert count. Sections no longer have hardcoded heights or positions — each section measures its content and the sections below it flow accordingly. The total scroll content height is also recalculated each time, so the scrollbar always reflects the true panel size.

### Frost Mage — Alert Cleanup

Removed two inapplicable alerts from the Frost Mage module:

- **Wake Up Pet** (Hunter only)
- **Taunt** (Hunter/Warlock only)

These were placeholder entries carried over from the shared layout. The Mage module now has 6 clean alerts with updated indices, test slots, defaults, and `healPetAlertIndex`.

### Unholy Death Knight — Alert Cleanup

Removed three inapplicable alerts from the Unholy Death Knight module (`DeathKnightUnholy.lua`):

- **Pet Died** (no reliable Ghoul death detection)
- **Wake Up Pet** (Hunter only)
- **Taunt** (Hunter/Warlock only)

The DK module now has 5 clean alerts with updated indices, test slots, defaults, and `healPetAlertIndex`.

### Subtitle

Updated the options panel subtitle from the explicit class list to: *"Pet status warnings for all pet classes. Type /npa to open this panel."*

---

## v12.0.19 — April 18, 2026

## Options Panel — Alert Options Section (new)

A dedicated fourth section, **Alert Options**, now appears below the Alerts section. The panel is fully scrollable with a slim class-colored scrollbar on the right margin.

### Scrollbar

The options panel now scrolls instead of overflowing the WoW Settings UI boundary. A 4px scrollbar with drag, click-to-jump, and mousewheel support sits in the right margin and only appears when content exceeds the visible area.

### Alert Options Section

- **Font picker** moved here from the Display section
- **Heal Pet Threshold** moved here from sitting inline next to the alert checkbox. The edit box is now class-colored and registered to update with the panel theme
- **Alert text editors** — every alert for the active spec gets a labeled two-column edit box. Edits apply live on focus-lost. Clearing a box resets it to the built-in default. Values are saved per character
- **Restore Defaults button** added as a fourth button alongside Test, Unlock Frame, and Center Position. Resets alert colors, alert texts, font, scale, font size, heal pet threshold, and frame position back to built-in defaults

### Display Section

- Checkboxes (Enable Addon, Flash Animation) shifted to x=8 with 40px row spacing, matching the Sounds section layout
- Display section height tightened to remove excess empty space
- Font picker removed from this section
- Min/max labels removed from both sliders

### Sounds Section

- Dropdowns shifted right to align their left edge with the slider tracks above

### Buttons

- **Reset Position** renamed to **Center Position**
- Four buttons now: Test, Unlock Frame, Center Position, Restore Defaults

---

## v12.0.18 — April 16, 2026

### Changes

- All alerts are now suppressed while the player is resting (in a city or inn)
- Alerts resume immediately upon leaving the resting area
- Registers `PLAYER_UPDATE_RESTING` so the display clears/restores instantly on zone change

---

## v12.0.17 — April 12, 2026

## Options Panel Improvements

- Non-pet specs now show a clean "Spec Not Supported" panel on first click — no more blank panel or flashing options
- All unsupported specs now show the same unified message instead of separate "Class Not Supported" handling
- Options panel uses the default cyan theme for non-pet specs instead of showing class colors

## Code Cleanup

- Removed overlay system — the unsupported-spec panel is now built directly into the UI rather than layered on top
- Removed class-based support checks (`SUPPORTED_CLASSES`, `IsSupportedClass`) — support is now determined entirely by whether a spec module is active
- Slash commands now show a clearer message for unsupported specs

---

## v12.0.16 — April 11, 2026

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

No settings reset or migration is needed.

---

## v12.0.15 — April 5, 2026

## Quality of Life

- Test mode is now fully disabled for unsupported classes
- Unsupported classes can no longer use addon control slash commands

This prevents confusion and avoids exposing features that do not work for that class.

---

## v12.0.14 — April 5, 2026

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

## v12.0.13 — March 30, 2026

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

## v12.0.12 — March 27, 2026

## Visual Updates

- Default alert colors were updated for new installs and resets
- Alert order in the right column of the options panel was improved

Existing custom colors are unchanged.

---

## v12.0.11 — March 25, 2026

## New Feature: Pet Not Attacking

Added a new alert that warns when your pet is in combat but not actively attacking. Uses a short grace period to avoid false warnings, resets cleanly when combat ends, and works in M+ and rated PvP.

### New Features

- **Pet Not Attacking** alert and checkbox in the options panel
- Per-class alert text
- Alert layout rebuilt into a cleaner 6-row stack

### Changes

- Test mode now shows complete coverage for all supported classes
- Options panel alert ordering improved
- Heal Pet behavior cleaned up across classes
- Test mode no longer hides frames for spec-gated classes

### Bug Fixes

- Fixed Heal Pet and similar alerts not showing correctly in test mode without a pet active
- Fixed Pet Not Attacking timer keeping stale state between pulls
- Fixed Death Knight test mode showing too few alerts

---

## v12.0.10 — March 24, 2026

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

## v12.0.9 — March 23, 2026

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

## v12.0.8 — March 22, 2026

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

## v12.0.7 — March 20, 2026

## Options Panel Upgrade

- Added a font picker with preview
- Added a scale slider
- Added a font size slider
- Redesigned the options panel with cleaner section styling

---

## v12.0.6 — March 18, 2026

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

## v12.0.5 — March 16, 2026

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

## v12.0.4 — March 15, 2026

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

## v12.0.3 — March 13, 2026

## New Features

- Added Pet Died sound: **OhNo.ogg**

---

## v12.0.2 — March 10, 2026

## Bug Fixes

- Fixed a taint crash in `UNIT_SPELLCAST_SUCCEEDED`

---

## v12.0.1 — March 9, 2026

## Bug Fixes

- Fixed a taint crash in fake death detection
- Removed the polling ticker and made detection fully event-driven
- Added bundled sound: **Sonar.ogg**

---

## v12.0.0 — March 7, 2026

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
