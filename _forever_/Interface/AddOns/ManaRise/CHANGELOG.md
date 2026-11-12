# ManaRise changelog

Newest first. ManaRise has not been tested in-game yet; please report anything that looks wrong.

## 1.12.29

- The options page is simpler. "Style per resource" and "Behavior colors" each have one Resource dropdown and show only that resource's rows (the player's main resource is chosen at first, and each area remembers its own choice). Row names are shorter. Every saved setting and the /mr resset and /mr fxcolor commands work as before.
- Not checked in a running game.

## 1.12.28

- The Cooldown Manager (Essential and Utility viewers) now gets the same resource fill as the action bars. Each icon shows the fill for its spell's cost, with the per-resource colors, styles and settings, and follows spell changes and layout changes. There is a new "Cooldown Manager" entry under Bar categories with "Use global settings", its own look and an on/off switch. Buff icons and buff bars are not touched. `/mr status` lists the icons found, or says the Cooldown Manager is not on this client. Nothing is written onto the viewer, and new icons are only set up out of combat. Like stance buttons, the icons hide while your resource is a secret value in combat.
- Not checked in a running game.

## 1.12.27

- Style per resource now has its own settings. Under each resource's style, set that resource's fill opacity and darkness, and (for styles that use them) wave speed, wave intensity and bubbles. Each one offers "Same as the main setting" or its own value, and is remembered per resource and style, so switching Mana from Liquid to Ice and back keeps the Liquid values. The wave and bubble rows hide for Flat. The separate "Waves per resource" group is gone; wave speed and intensity you had set per resource move to that resource's current style. `/mr resset <resource> <waves|intensity|bubbles|opacity|dark> <value>|default` sets one, and `/mr status` lists them. Buttons, the live preview and `/mr test` use them. Saved per profile; bar categories follow the global settings.
- Not checked in a running game.

## 1.12.26

- New "Behavior colors" group in the Behavior section: pick a color for the ready flash, the edge pulse and the sweep / double animation, separately for mana, rage, energy and focus. Opacity sets the strength of the effect. Every color starts as automatic (the resource color made lighter), so nothing changes until you pick one. A picked flash color also replaces the fixed orange of burning styles. `/mr fxcolor <flash|pulse|sweep> <resource> <hex>|auto` sets one, `/mr fxcolor reset` resets all. Saved per profile; bar categories follow the global colors.
- Not checked in a running game.

## 1.12.25

- Settings can now be saved per character. The "Separate settings for each class" checkbox is now a "Settings profile" dropdown (Whole account, Per class, Per character), and `/mr profile account | class | character` sets it. A character's profile starts as a copy of the account settings the first time it is used. Characters are told apart by name and realm. Switching modes keeps every stored profile. Old per-class settings keep working.
- Not checked in a running game.

## 1.12.24

- New color picker: clicking a color swatch opens ManaRise's own picker with Red, Green, Blue and Opacity sliders and a preview. Changes apply and save as you move the sliders; Cancel puts the old color back. It replaces the game's color picker, which did not save the color for some players.
- Each resource color now has its own opacity. It is multiplied with the Fill opacity setting. `/mr color <hex>` keeps the opacity; `/mr color reset` and "Reset colors" restore full opacity.
- Not checked in a running game.

## 1.12.23

- No more duplicate settings: the per-resource style and wave dropdowns (Style per resource, Waves per resource) now exist only once, in the main part of the options page. They apply to every bar category. Bar categories keep their own main style, waves, colors, ready flash and indicator.
- Not checked in a running game.

## 1.12.22

- Tidier options page: in Bar categories, the style, wave, color and flash settings only show when "Use global settings" is unticked, so they no longer repeat the settings above. "Other" (minimap button, per-class settings) now comes before Bar categories.
- Not checked in a running game.

## 1.12.21

- New "Waves per resource" options: set wave speed and wave intensity separately for Mana, Rage, Energy and Focus, or keep "Same as the main setting" (default). The same choices are in the Bar categories section; a category with its own settings has its own per-resource waves.
- A button that changes resource (for example a druid changing form) switches to that resource's wave settings.
- Not checked in a running game.

## 1.12.20

- Smaller download and folder: the options-page logo is stored at half size (131 KB instead of 512 KB). It is drawn at the same size, so it looks the same.
- Not checked in a running game.

## 1.12.19

- New "Style per resource" options: pick Liquid, Flat, Ice, Burning or Burning parchment separately for Mana, Rage, Energy and Focus, or keep "Same as the main style" (default). The same choices are in the Bar categories section; a category with its own settings has its own per-resource styles.
- The preview window and `/mr test` show the per-resource style. A button that changes resource (for example a druid changing form) switches style; in combat the change waits until combat ends.
- New command `/mr resourcestyle <mana|rage|energy|focus> <style|default>`. `/mr status` lists per-resource styles when any is set.
- Not checked in a running game.

## 1.12.18

- A "Reset colors" button in the Bar categories section. It puts the four resource colors of the selected category back to the defaults.
- Not checked in a running game.

## 1.12.17

- **Settings per bar category.** A new "Bar categories" section on the options page. Pick **Main action bar**, **Additional action bars**, **Stance / form bar** or **Other detected bars** (Bartender4, Dominos, ElvUI, EllesmereUI and registered bars), then set that group on its own:
  - enabled (switches ManaRise off or on for that group only),
  - use global settings (on by default),
  - style, wave intensity, wave speed, ready flash, out-of-resource indicator (the fill) and the four resource colors.
  Changing any look setting for a category gives it its own settings, starting from the current global values. Ticking "Use global settings" again returns it to the global look. The global settings are not changed by any of this.
- Saved settings are kept: profiles without category data simply read the global settings, and nothing is reset.
- With the out-of-resource indicator off for a category, the fill is not drawn there, but the ready flash still plays if it is on.
- New texts are English in other languages until translated.
- Not checked in a running game. DaylightUI and the Cooldown Manager have no category yet: I have no way to inspect them here.

## 1.12.16

- **Calmer liquid waves.** New **Wave intensity** option (Low / Medium / High, `/mr intensity low|medium|high`). **Low is the new default**: the wave band is squeezed to about 40% of its old height, so the surface stays close to the real fill line and a wave peak no longer looks like a full bar. Medium (70%) and High (the old size) are still there, with a stronger back wave on the higher settings.
- **Wave speed** is now its own option (Slow / Normal / Fast). It is the old "wave intensity" setting under a clearer name, so your saved choice is kept (`/mr waves slow|normal|fast`; `calm` and `lively` still work).
- Whether a spell is affordable has always come from its real resource cost, never from the drawn wave height. This did not change. The ready flash is unchanged.
- **Stance and form buttons** (Warrior stances, Druid forms and similar on `StanceButton1-10`, including the same buttons on Bartender4/Dominos stance bars) now get the overlay when their spell costs a resource you do not have enough of. Stances that cost nothing show nothing. The active form is skipped so the game's own "active" look stays clear.
- Translations of the new texts were machine-made. Status, help and usage lines for the new `/mr intensity` command are English in other languages.
- Not checked in a running game. The Cooldown Manager and DaylightUI are not part of this version.

## 1.12.15

- **ManaRise logo on the options page**, in the empty space at the top right next to "Enable ManaRise" and Preview. It is a new texture (`Media/logo.tga`).

## 1.12.14

- **Real dropdowns on the options page.** Each choice is now a button that opens a list of its options, instead of the `<` `>` stepper. The list is ManaRise's own (one shared list, not the game's dropdown menu, so it cannot cause the "blocked from an action" errors). The current choice is highlighted in gold, long lists (SharedMedia sounds) scroll with the mouse wheel, and clicking anywhere else closes it.
- Not checked in a running game: the list was only run in the test harness.

## 1.12.13

- **The settings page is rebuilt with ManaRise's own controls.** The game's own settings pages (Game > Social and others) still reported "ManaRise has been blocked from an action only available to the Blizzard UI" after you had opened the ManaRise page. The game reuses its checkbox, dropdown and slider frames between pages, and ManaRise's page ran through them. The page now holds only ManaRise's own frames and uses none of the game's shared settings controls.
- Same settings, same order, same Preview row. Differences: dropdowns are now a small stepper (click `<` or `>`, or the value, to move to the next choice), and the page scrolls with the mouse wheel or its scroll bar. Long lists (SharedMedia sounds) are stepped through one by one; `/mr sound <name>` still sets one directly.
- The page has no "Defaults" button of its own any more; `/mr reset` still resets everything.
- Not checked in a running game: the new page was only run in the test harness.

## 1.12.12

- **Fixed the "blocked from an action only available to the Blizzard UI" errors in the game's own settings** (Game > Social, and changing dropdowns such as Text on Target). They came from the Preview button: it was attached to the game's settings window and hooked into it, which tainted the game's own pages. Testing confirmed the errors stop without it.
- **Preview is now a row on the ManaRise page** (right under "Enable ManaRise") instead of a button next to the Defaults button. It opens the same live preview window. ManaRise no longer hooks, hooks into or adds anything to the game's settings window.
- The old "Preview" simulation row at the bottom of the page is gone; `/mr test` still runs the simulation on your real buttons.
- `/mr panel nopreview` was removed; `/mr panel off` and `/mr panel on` stay for troubleshooting.

## 1.12.11

- **No hover tooltip on the section titles** (Look, Resources, Liquid, Behavior, Signals, Other) in the options page. Settings and buttons keep their tooltips.

## 1.12.10

- **Troubleshooting switch for the "blocked from an action" popup:** `/mr panel off` (then `/reload`) removes ManaRise's page from the game's settings completely; `/mr panel nopreview` keeps the page but removes the Preview button and its hooks; `/mr panel on` restores normal behavior. Use them to find out which part still affects the game's own pages. The commands are English-only.

## 1.12.9

- **Fixed "ManaRise has been blocked from an action only available to the Blizzard UI" in the game's own settings** (seen on Game > Social as `IsUserOAuthed()`). ManaRise wrapped the settings window's page-display function to move the Preview button; that wrapper tainted the window while it drew the game's own pages. It now listens to the window's page-change event instead and no longer touches any of the window's functions.

## 1.12.8

- **The minimap right-click menu no longer has "Open ManaRise".** It opened the same page as "Options", so only Options remains, followed by Unlock/Lock Position of Icon, Reset Position and Hide Minimap Button.

## 1.12.7

- **The Preview button now lines up with the Defaults button** (same size, same row, just to its left). It finds Defaults by its label, so it no longer depends on the client's internal field name.
- **The "Live preview" title is centered** across the preview window. Not tested in-game.

## 1.12.6

- **The Preview button moved to the top of the ManaRise page**, just left of the Defaults button, in the page header row.
- **The preview window now matches the game's Options window**: the same gold dialog border, dark panel and title plate. If a client lacks those textures it falls back to the plain dark panel. Not tested in-game.

## 1.12.5

- **Burning parchment now fills from the top down.** The parchment grows from the top of the icon and the jagged burn line travels down as the resource rises; the dark charcoal is below the line. The ready flash and fade-out work as before. Burning, Ice, Liquid and Flat still fill from the bottom. If a client cannot reverse the fill, parchment fills upward as before. Not tested in-game.

## 1.12.4

- **Burning no longer shows a paper texture.** The fill under the flames is now a smooth, see-through orange gradient, brightest at the burn edge and fading toward the bottom, to match the fire. Other styles are unchanged. Not tested in-game.

## 1.12.3

- **Burning no longer has a blue-green tint under the flames.** The paper fill was tinted with your resource color (blue for mana), which showed as a cyan-green cast under the orange fire. It is now warm, ember-toned paper that only slightly follows the resource color. Other styles are unchanged. Not tested in-game.

## 1.12.2

- **"Burning page" is now just "Burning".** Only the name changes (options, help, tooltip, README, all languages); the command is still `/mr style paper` and saved settings are kept.
- **The Burning embers look like fire rising.** The round bubbles are replaced by small, irregular glowing specks tinted in flame colors, from yellow-orange to deeper orange-red, that drift up from the burn edge and fade. They still follow the bubbles on/off and waves settings. Each particle keeps one color for its whole rise (it does not shift color along the way). Other styles are unchanged. Not tested in-game.

## 1.12.1

- **Ice is now icy blue.** The Ice fill, crystal edge, shade and sparks were lightened so much that the default mana blue looked pale green-white. They now lean toward a clear blue, still semi-transparent so the icon shows through. Rage, energy and focus keep their own color family with a cooler tint. Other styles are unchanged. Not tested in-game.

## 1.12.0

- **New fill style: Burning parchment.** Pick it in the Style dropdown or with `/mr style parchment`. The empty part of the button is darkened with a charcoal tint, and the filled part is cracked, scorched parchment (still showing the icon) that follows your resource exactly. A jagged burn line with a yellow core, orange glow, dark red scorched rim and short flame tongues climbs with the fill, with embers, sparks and ash rising from it. Embers and ash follow the bubbles on/off setting, and everything follows the waves speed setting. When a spell becomes affordable, a golden-orange flash plays only on that change, then everything fades out. It uses the same icon clipping as the other styles, works with every resource color, fill opacity and darkness, and falls back to the flat fill if its textures or animations cannot load. Ice and Burning page are unchanged. The jagged line is a fixed shape and the glow does not get stronger near the top. Not tested in-game; the look is a layered approximation of the reference art.

## 1.11.0

- **The live preview is now its own window.** On the ManaRise options page, a **Preview** button appears next to the settings window's Defaults button. Clicking it opens a small movable window (close it with X or Escape; click the button again to close it too) showing sample buttons that loop fill and clear with made-up resources, using your current style, colors, fill opacity, darkness, waves, bubbles, flash and edge pulse. It updates the moment a setting changes, from the page or a slash command, and keeps looping after Enable is toggled. It runs only while the window is open. The sample frames are created once, out of combat (clicking the button in combat only prints a message), and never touch your real bars. The sample strip that used to sit on the settings window is gone. If the button cannot be placed next to Defaults on your client, it appears at the bottom left of the settings window instead. The placement is not tested in-game.

## 1.10.0

- **Live preview in the options panel.** While the ManaRise page of the settings window is open, a few sample spell buttons appear with a "Live preview" label. They fill and clear in a loop with made-up resources (mana, rage, energy, focus), flash when "full", and use your current style (liquid, flat, ice, burning page), resource colors, fill opacity, darkness, waves, bubbles, flash and edge pulse. Any change, from the page or from a slash command, shows up at once. The preview uses the same drawing code as your real buttons, but only on its own sample buttons: it never touches your bars or other addons' frames. It runs only while the page is visible and stops when you leave it. Its frames are created once, out of combat (if you open the panel in combat they appear after combat). If the settings window of your client cannot host it, the page and `/mr test` work as before and nothing is shown. The placement is not tested in-game.

## 1.9.0

- **Two new fill styles: Ice and Burning page.** Choose them in the options panel (Style) or with `/mr style ice` and `/mr style paper`. *Ice* builds frost crystals as the resource regenerates, with a jagged crystal edge and twinkling sparks. *Burning page* is a paper-like fill whose top edge burns and glows, with embers rising from it. Both fill from the bottom, clear and flash when ready, follow your colors, fill opacity, darkness, waves (animation speed), bubbles (particles on or off) and smooth settings, and work on the default bars, Bartender4, Dominos, ElvUI and EllesmereUI. They use the game's built-in animations only (no extra polling), create nothing in combat and write nothing onto button tables. If their textures or animations cannot be built, that button uses the flat fill. Liquid and flat look the same as before, and an unknown saved style still falls back to liquid.

## 1.8.0

- **Addon authors can register their own action bars.** `ManaRise_RegisterBarAddon({ ... })` takes the addon name and one way to find its buttons: a LibActionButton library (`lib`, optionally filtered by `prefix`), global button names (`prefix` and `max`), or a `buttons` function, plus how to read a button's action slot (`slot`). It works whether the other addon loads before or after ManaRise, can wait for an addon with `waitFor`, and returns `false` with a printed reason for a bad registration instead of causing a Lua error. `ManaRise_RefreshBarAddons()` makes ManaRise look for buttons created later. Registered addons appear in `/mr status`, `/mr scan` and `/mr report` like the built-in ones, with a clear message when nothing is found or the library is missing. ManaRise still never writes to the other addon's buttons and creates nothing in combat. See the README.

## 1.7.0

- **Out-of-range mark, more control**: choose the look (color over the icon, grey over the icon, or a colored border), the color, and the strength. All in the options panel, or `/mr range color <hex>`, `/mr range opacity <5-100>`, `/mr range style tint|grey|border`.
- **Spells you could not cast anyway are not marked** (not enough resource, wrong form), so an icon never carries two warnings. Turn this off with `/mr range usable off` or in the panel.

## 1.6.8

- **Removed the low-resource warning entirely**: the red border, the "Warn below" slider, the low-resource sound and the `/mr low` and `/mr lowsound` commands. On WoW: Forever 1.60.1 the game hides your resource numbers at all times, so a percentage check could never work. The ready sound and everything else are unchanged.

## 1.6.7

- **Low-resource sound: nothing is dropped any more.** If another sound had just played, the low-resource sound used to be skipped; now it follows a moment later.
- **`/mr status` shows what the low check sees**: for each resource its current percentage, your "Warn below" limit, and whether it is above the limit, below it, off, or paused because the game hides the value, plus how many times the low sound was due. If the sound stays silent, send this line.

## 1.6.6

- **Ready sound only for the abilities you choose.** Turn on "Ready sound only for chosen abilities" in the options panel (or `/mr soundspell only on`), then add the abilities with the "Add ability..." button or `/mr soundspell add <name, spell ID or spell link>`. `/mr soundspell remove`, `list` and `clear` manage the list. It is off by default, so the ready sound still plays for every ability until you turn it on. The low-resource sound is not affected.

## 1.6.5

- **28 more sounds included.** The ready and low-resource sound lists now contain the sounds from the SharedMedia Alert Media Pack (all `.ogg`), for example Air Horn, Sonar, Warning Siren, Water Drop and Temple Bell. They work without SharedMedia installed. Type `/mr sound airhorn` (or `/mr lowsound sonar`), or pick one in the options panel. The names are the file names without spaces, in any letter case.
- The sounds are licensed CC0, CC BY 3.0 or MIT; credits and license texts are in `ManaRise/Sounds/Licenses`.

## 1.6.4

- **Removed the gradient and bar fill styles** (added in 1.6.2). If you had one selected, ManaRise switches you to the liquid style. `/mr style` now offers `liquid` and `flat`.

## 1.6.3

- **Your own sounds.** The ready sound can now be a built-in sound, a sound file of your own (`/mr sound custom Interface\AddOns\ManaRiseSounds\ding.ogg`), a numeric game sound ID, or any sound registered with SharedMedia by another addon. The options panel has a "Custom ready sound..." button for typing the path or ID.
- **New low-resource sound.** `/mr lowsound` (or the options panel) plays a sound when a resource falls below the "Warn below" percentage. It plays once on the way down and again only after the resource has recovered. It works with or without the red border, shares a short pause with the ready sound, and pauses while the game hides the value.
- A sound that cannot be played is reported once in chat and listed in `/mr status` and `/mr report`.
- `/mr test` also plays the sounds you have switched on.
- Keep custom sound files in their own addon folder (for example `Interface\AddOns\ManaRiseSounds`) so ManaRise updates do not delete them.

## 1.6.2

- **Gamepad bar frames are skipped.** The game lists about 190 hidden Gamepad buttons that have no real action slot; ManaRise no longer puts overlays on them. `/mr status` and `/mr report` show how many were skipped.
- **New optional signals** (all off by default):
  - `/mr range on|off`: tint an icon red while the target is out of range.
  - `/mr low on|off|5-50`: red border while a resource is below the chosen percentage.
  - `/mr sound off|tick|chime|bell|test`: a short sound when a spell becomes ready (game sounds, effects channel).
  - When the game hides a value, the signal pauses itself instead of guessing, and says so in `/mr status`.
- **New ready animations:** `/mr anim flash|sweep|double`. `/mr test` shows the one you picked.
- **Better diagnostics:** `/mr report` now lists the button counts, features running in a reduced way (with the reason in plain words) and the last errors ManaRise caught. `/mr status` shows the same reasons.
- All new texts are in every language (machine-made translations).
- Still not tested in-game: the sound names and the range event are checked at run time on the client and reported if missing.

- **EllesmereUI** action bars are supported: its buttons get the same fill and flash. `/mr status` shows how many were found.
- **Retail (12.x)**: the addon now lists the Retail interface versions, so it loads on Retail as well as Forever.
- **Minimap menu restyled** to look like the game's mouse-over tooltip: dark frame, gold "ManaRise" title, white entries that turn gold on hover, a divider before the position entries.
- **Removed "Casts left"** completely: the number on the buttons, its option, `/mr casts` and its texts. It could not work while the game hides your resource value.
- **Minimap button right-click menu**: Open ManaRise, Options, Unlock/Lock Position of Icon, Reset Position, Hide Minimap Button. The icon is locked until you unlock it. Right-click no longer turns ManaRise on or off; use `/mr on` and `/mr off`.
- **New minimap icon** (the ManaRise liquid effect).
- Fixed the build check that sometimes reported a file as missing from the ZIP.

## 1.6.0

New: a **minimap button** (left-click opens the options, right-click turns ManaRise on or off, drag to move it; `/mr minimap on|off`). **Casts left**: an optional small number on each button showing how many casts you can afford (`/mr casts on`; not shown while the game hides your resource value). **Color presets**: Classic, Fel, Frost and a colorblind-friendly palette (`/mr preset ...`, or the options panel). **Settings per class**: `/mr profile class` gives each class its own settings. **`/mr report`** opens a window with the status text to copy into a bug report. A one-time message after installing or updating. Added Traditional Chinese and Italian; Italian is a partial translation (commands, options and the new texts), the rest shows in English. All translations are machine-made. Not yet tested in-game; the minimap button in particular needs checking on the Forever client.

## 1.5.0

ManaRise now speaks German, French, Spanish, Russian, Brazilian Portuguese, Korean and Simplified Chinese: chat messages, `/mr` help, `/mr status` and the options panel follow your game language, with English for everything else. The translations are machine-made; corrections are welcome. Slash commands stay the same in every language. The README is now a player guide, and the ZIP includes a CHANGELOG.

## 1.4.0

Bartender4, Dominos and ElvUI support. When one of them is loaded, its action buttons get the same fill, liquid look and ready flash as the default bars, and keep up when the addon creates, hides, pages or rearranges buttons. ElvUI's square icons get a square fill that stays inside the border. `/mr status` and `/mr scan` show which bar addon was detected and how many of its buttons are tracked. Nothing changes if none of them is installed. Not yet tested in-game with these addons.

## 1.3.0

Rage, energy and focus support. Warriors, rogues and druids in cat or bear form now see abilities fill in the resource's color (rage red, energy yellow, focus orange), and the ready flash uses that color too. A druid's buttons switch between mana, energy and rage when changing form. Rage decaying out of combat drains smoothly. Each resource has its own color: `/mr color rage C41F3B` or the new swatches in the options panel (`/mr color reset` resets all four). New `/mr resource all | mana` (also in the panel) to keep the mana-only behavior. Your 1.2.0 fill color is kept as the mana color.

## 1.2.0

New options page in Game Menu → Options → AddOns → ManaRise (or `/mr options`): enable, style, fill opacity, empty-part darkness, fill color with a reset button, wave intensity, bubbles, ready flash, smooth fill, edge pulse, and a Preview button. It stays in sync with the slash commands. New commands: `/mr color <hex> | reset`, `/mr waves calm | normal | lively`, `/mr bubbles on | off`.

## 1.1.4

New `/mr opacity 0-100` and `/mr dark 0-100` commands to set how see-through the blue fill is and how dark the empty part is. `/mr status` shows both.

## 1.1.3

Fixed the liquid look never appearing ("animations failed ... Animation.lua:221"). This client can't create the wave-scrolling animation from Lua, so the waves now come from XML templates (`ManaRise.xml`), the same way Blizzard's own UI defines that animation. If that is unavailable too, the waves slide sideways instead. `/mr status` shows which method is in use ("waves: xml", "lua" or "move").

## 1.1.2

The liquid look is now sized for real action buttons: waves about twice as tall and broader, a thicker bright wave edge, and five bigger, brighter bubbles. Before, the detail was only 2-3 pixels tall on a button and looked almost like the flat style. If the liquid look can't be built (missing Media files or an animation the client rejects), ManaRise now says so in chat instead of silently using the flat look, and `/mr status` shows a "liquid look" line.

## 1.1.1

Addon-list icon, and the addon-list tooltip now ends with "Type /mr for options". Fixed a faint straight line that could show just above the liquid surface.

## 1.1.0

New liquid look (default): rolling wave surface with two layers, depth shading and rising bubbles, all driven by the client's built-in animations. `/mr style flat` restores the previous look.

## 1.0.1

Fixed: the ready-flash layer was visible on every action button all the time (it showed as a green-tinted inner border). Flash layers are now hidden whenever they aren't playing.

## 1.0.0

First release.
