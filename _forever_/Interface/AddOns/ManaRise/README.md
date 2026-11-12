# ManaRise

**Watch your mana rise. Cast the moment you're ready.**

An addon for **World of Warcraft: Forever 1.60.1** and **Retail (12.x)**. When a spell on your action bars costs more
than you have, its icon darkens and fills up from the bottom as your mana, rage, energy or focus
comes back. When you can afford the spell, the fill disappears and the button gives a short flash.

> ManaRise has **not been tested in-game yet**, including with Bartender4, Dominos, ElvUI and EllesmereUI.
> If something looks wrong, please report it (see [Reporting a problem](#reporting-a-problem)).

## What it does

- **Liquid fill (default).** The fill looks like liquid: a rolling wave on top, a dimmer wave
  drifting behind it, darker at the bottom, with small bubbles rising. `/mr style flat` gives a
  plain fill with a thin bright edge instead. `/mr style ice` builds frost crystals with twinkling
  sparks as the resource regenerates, and `/mr style paper` ("Burning") draws a paper fill
  whose top edge burns and glows, with embers rising from it.
- **Mana, rage, energy and focus**, each in its own color: mana blue, rage red, energy yellow,
  focus orange. A druid's buttons switch color as you change form.
- **Ready flash.** A short flash in the same color when the spell becomes affordable.
- **Default bars and bar addons.** All Blizzard action bars, plus Bartender4, Dominos, ElvUI and EllesmereUI.
- **Your bars stay as they are.** Cooldown swipes, keybinds, charges and borders still draw on top;
  clicking, tooltips and drag-and-drop work as before.
- **Languages.** English, Deutsch, Français, Español, Русский, Português (Brasil), 한국어, 简体中文, 繁體中文 and Italiano (Italian is partial),
  following your game language. The translations are machine-made; corrections are welcome.

## Installation

1. Download `ManaRise-1.12.29.zip`.
2. If you have an older ManaRise, delete the old `ManaRise` folder first.
3. Extract the ZIP into your WoW: Forever AddOns folder, for example:
   ```
   World of Warcraft/_classic_beta_/Interface/AddOns/
   ```
   On Retail, use `World of Warcraft/_retail_/Interface/AddOns/`.
   If your Forever client lives in a different subfolder, use that folder's `Interface/AddOns/`.
4. You should end up with `Interface/AddOns/ManaRise/ManaRise.toc`, not
   `AddOns/ManaRise/ManaRise/ManaRise.toc` (a doubled folder).
5. Restart the game, or type `/reload` if it is running.
6. On the character select screen, open **AddOns** and make sure ManaRise is enabled. If it shows as
   "Out of date", tick **Load out of date AddOns**.

Try `/mr test` to see a preview on your bars. The **Preview** row at the top of the ManaRise options page opens a live preview window of sample buttons that follows every setting you change.

## Options

Open **Game Menu → Options → AddOns → ManaRise**, or type `/mr options`.

| Setting | What it does | Default |
|---|---|---|
| Enable ManaRise | Turn the addon on or off | on |
| Style | Liquid waves and bubbles, a flat fill, ice crystals or burning | Liquid |
| Fill opacity | How solid the colored fill is | 70% |
| Empty-part darkness | How dark the empty part of the icon is | 55% |
| Resources | Mana, rage, energy and focus, or mana only | all |
| Mana / Rage / Energy / Focus color | Fill color for each resource, plus a Reset colors button | blue / red / yellow / orange |
| Wave intensity | Calm, Normal or Lively | Normal |
| Bubbles | Rising bubbles in the liquid | on |
| Ready flash | Flash when a spell becomes affordable | on |
| Smooth fill | Smooth movement instead of steps | on |
| Edge pulse on gain | Small pulse each time the resource rises | off |
| Color preset | Classic, Fel, Frost, Colorblind-friendly or Custom (changing one color switches to Custom) | Classic |
| Show minimap button | Left-click opens options, right-click opens a menu (open, options, unlock/lock position, reset position, hide button). Drag to move once unlocked | on |
| Separate settings for each class | Each class keeps its own settings | off |
| Preview | Shows the effect with made-up values for a few seconds | |

Changes apply right away, and the panel and the commands always agree. The panel's **Defaults**
button restores everything. Settings are saved for your whole account unless you turn on separate settings per class.

## Commands

Type `/mr` (or `/manarise`) in chat. The command words are the same in every language.

| Command | What it does |
|---|---|
| `/mr` | Show help |
| `/mr options` | Open the options panel (also `/mr config`) |
| `/mr on` / `off` | Turn ManaRise on or off |
| `/mr status` | Show your settings and what ManaRise is tracking |
| `/mr style liquid` / `flat` / `ice` / `paper` / `parchment` | Liquid look, flat fill, ice crystals, burning or burning parchment. A change in combat applies when combat ends |
| `/mr range color <hex>` / `opacity <5-100>` / `style tint` / `grey` / `border` / `usable on` / `off` | Look of the out-of-range mark; `usable on` skips spells you could not cast anyway |
| `/mr range on` / `off` | Tint icons red while the target is out of range (off by default) |
| `/mr sound off` / `tick` / `chime` / `bell` / `test` | Sound when a spell becomes ready (off by default) |
| `/mr sound custom <file or ID>` | Use your own sound file path or a numeric game sound ID |
| `/mr soundspell add <ability>` / `remove` / `list` / `clear` / `only on` / `only off` | Play the ready sound only for the abilities you choose (off by default) |
| `/mr anim flash` / `sweep` / `double` | Ready animation |
| `/mr resource all` / `mana` | Track all four resources, or mana only |
| `/mr color <hex>` | Mana fill color, e.g. `/mr color 8A2BE2` |
| `/mr color rage` / `energy` / `focus` `<hex>` | Color for another resource, e.g. `/mr color rage C41F3B` |
| `/mr color reset` | Reset all colors (`/mr color rage reset` resets one) |
| `/mr opacity 0-100` | How solid the fill is (default 70) |
| `/mr dark 0-100` | How dark the empty part is (default 55) |
| `/mr waves calm` / `normal` / `lively` | How lively the liquid surface moves |
| `/mr bubbles on` / `off` | Rising bubbles |
| `/mr smooth on` / `off` | Smooth fill movement |
| `/mr glow on` / `off` | Ready flash |
| `/mr pulse on` / `off` | Edge pulse when the resource rises |
| `/mr preset classic` / `fel` / `frost` / `colorblind` | Color preset for all four resources |
| `/mr minimap on` / `off` | Show or hide the minimap button |
| `/mr profile account` / `class` | One settings set for the account, or one per class |
| `/mr report` | Open a window with a copyable report for bug reports |
| `/mr scan` | List every tracked button and why it is or isn't filling |
| `/mr debug` | Print why a button has no fill whenever its state changes |
| `/mr test` | Preview with **made-up** mana on your visible buttons (out of combat; `/mr test stop` ends it) |
| `/mr reset` | Restore default settings |

## FAQ

**Does it work with Bartender4, Dominos, ElvUI or EllesmereUI?**
It is built to: when one of them is loaded, its buttons get the same fill and flash, and ElvUI's
square icons get a square fill. There is nothing to set up and none of their settings change.
`/mr status` shows which one was detected and how many buttons are tracked. It is not known yet
whether these addons run on Forever 1.60.1, and ManaRise has not been tried with them in-game.
Other bar addons are not supported; their buttons are left alone.

**What does "secret" mean in `/mr status`?**
In some situations the game hides your exact mana (or rage, energy, focus) from addons. ManaRise
then hands the value straight to the game to draw the fill, and asks the game whether the spell is
affordable. If the game won't say, ManaRise hides the fill instead of guessing. It never tries to
work around this. The edge pulse can't fire while the value is hidden.

**Do rage and energy work too?**
Yes. Warriors see rage abilities fill red, rogues and cat-form druids see energy fill yellow, and
bear-form druids see rage. Rage draining out of combat lowers the fill smoothly. If you only want
mana spells, type `/mr resource mana`. Focus fills orange if your class or pet uses it on Forever.

**Some buttons never fill. Why?**
Only spells that cost mana, rage, energy or focus fill. Items, macros without a spell, free spells
and spells waiting for a free-cast proc are left alone. `/mr scan` lists every button with the
reason.

**Does it slow the game down?**
It only updates when your resource or your bars change, never every frame, and the waves use the
game's built-in animations. If you notice a drop with many buttons filling, try `/mr style flat`.

**Is it safe in combat?**
It doesn't touch secure button settings or protected actions, and creates nothing during combat.
Changes that need new parts (like switching style) wait until combat ends.

**What isn't tracked?**
Combo points, runes, holy power and other secondary resources, and spells that cost health.

**A translation is wrong.**
The translations are machine-made. Please send the correct wording; slash commands and the
`%s` / `%d` parts must stay as they are.

## For addon authors: register your own bars

If your action bar addon is not one of the supported ones, you can tell ManaRise about it. Call `ManaRise_RegisterBarAddon` once your buttons exist (or when your addon loads: ManaRise lists its optional dependencies, so add `## OptionalDeps: ManaRise` to your TOC to load after it). It returns `true`, or `false` plus the reason (the reason is also printed once in chat). It never raises a Lua error. ManaRise does not change your button tables, secure attributes or settings, and creates nothing in combat.

```lua
-- 1. A LibActionButton-based addon (the usual case)
if ManaRise_RegisterBarAddon then
    ManaRise_RegisterBarAddon({
        name = "MyBars",                        -- shown in /mr status
        lib = "LibActionButton-1.0-MyBars",     -- the LibStub name of your copy
        prefix = "MyBarsButton",                -- optional: only buttons whose name starts with this
    })
end

-- 2. Buttons with global names MyBarButton1 .. MyBarButton60
ManaRise_RegisterBarAddon({ name = "MyBars", prefix = "MyBarButton", max = 60 })

-- 3. Your own list of buttons, and your own way to read the slot
ManaRise_RegisterBarAddon({
    name = "MyBars",
    buttons = function() return MyBars.allButtons end,   -- array of buttons, or [button] = true
    slot = function(button) return button.mySlot end,    -- action slot number, or nil
})
```

Fields:

| Field | Meaning |
|---|---|
| `name` | Short text shown in `/mr status`, `/mr scan` and `/mr report` (required, at most 40 characters) |
| `lib` | LibStub name of a LibActionButton copy. ManaRise follows its callbacks, so paging and new buttons are picked up |
| `prefix` | With `lib`: optional filter on button names. With `max`: the name start of your global buttons |
| `max` | With `prefix`: how many buttons to look for (1-500) |
| `buttons` | Function returning your buttons (use instead of `lib` or `prefix`/`max`). Call `ManaRise_RefreshBarAddons()` after you create new buttons |
| `slot` | How to read a button's action slot: `"lab"` (default with `lib`, uses `button:GetAction()`), `"attribute"` (the `action` attribute, then `button.action`; default otherwise) or a function returning the slot number |
| `waitFor` | Optional addon name; ManaRise waits until it is loaded before looking for buttons |

Use exactly one of `lib`, `prefix` with `max`, or `buttons`. Buttons need an `icon` texture like Blizzard's action buttons. `/mr status` shows whether your registration was found, is waiting, or why it was rejected.

## Reporting a problem

Leave a comment on the addon page with what you saw, your class, and the output of `/mr status`
(and `/mr scan` if a button behaves oddly). Turn on Lua errors with `/console scriptErrors 1` and
include any error text.

## Included sounds

Besides tick, chime and bell, 28 sounds are included and work without any other addon: Air Horn (`airhorn`), Alert Toast Warm (`alerttoastwarm`), Applause (`applause`), Blast (`blast`), Bleat (`bleat`), Boxing Arena Gong (`boxingarenasound`), Cartoon Voice Baritone (`cartoonvoicebaritone`), Cartoon Walking (`cartoonwalking`), Cat Meow (`catmeow2`), Cow Mooing (`cowmooing`), Focus (`focus`), Heartbeat Single (`heartbeatsingle`), Kitten Meow (`kittenmeow`), Lossa Healer Trinket (`lossahealertrinket`), Lossa Trinket (`lossatrinket`), Notification 18 (`notification18`), Notification 38 (`notification38`), Ringing Phone (`ringingphone`), Roaring Lion (`roaringlion`), Robot Blip (`robotblip`), Sheep Bleat (`sheepbleat`), Shotgun (`shotgun`), Sonar (`sonar`), Temple Bell (`templebellhuge`), Torch (`torch`), Warning Siren (`warningsiren`), Watch Out (`watchout`), Water Drop (`waterdrop`). Pick one in the options panel or type for example `/mr sound airhorn`. Credits and licenses (CC0, CC BY 3.0, MIT) are in `ManaRise/Sounds/Licenses`.

## Changelog

See `CHANGELOG.md` for details.

- **1.12.29** - Simpler options: Style per resource and Behavior colors show one resource at a time, picked from a Resource dropdown. Not tested in-game.
- **1.12.28** - Cooldown Manager support: Essential and Utility viewer icons show the resource fill, with their own bar category in the options. Not tested in-game.
- **1.12.27** - Per-resource settings under each resource's style: fill opacity, darkness, wave speed, intensity and bubbles, remembered per style (`/mr resset`). Replaces "Waves per resource". Not tested in-game.
- **1.12.26** - Colors for the ready flash, edge pulse and sweep per resource (Behavior colors, `/mr fxcolor`).
- **1.12.25** - Settings per character: new "Settings profile" dropdown and `/mr profile character`.
- **1.12.24** - Own color picker with an opacity slider; colors now keep an opacity.
- **1.12.23** - Per-resource styles and waves are set once and apply to every bar category (no duplicate rows in Bar categories).
- **1.12.22** - Bar categories only show their own settings when "Use global settings" is unticked.
- **1.12.21** - Wave speed and intensity per resource (Mana, Rage, Energy, Focus), also per bar category.
- **1.12.20** - Smaller logo file (about 380 KB less).
- **1.12.19** - Style per resource (Mana, Rage, Energy, Focus), also per bar category; `/mr resourcestyle`.
- **1.12.18** - "Reset colors" button for each bar category.
- **1.12.17** - Settings per bar category (main, additional, stance/form, other bars), each with its own style, waves, colors, flash and indicator.
- **1.12.16** - Calmer waves: new Wave intensity (Low default) and Wave speed options; stance and form buttons get the overlay.
- **1.12.15** - ManaRise logo at the top right of the options page.
- **1.12.14** - Real dropdowns on the options page (ManaRise's own list, not the game's menu).
- **1.12.13** - The options page is rebuilt with ManaRise's own controls (no more "blocked from an action" errors on the game's settings pages). Dropdowns are steppers in this version (see 1.12.14).
- **1.12.12** - Fixed the "blocked from an action" errors in the game's own settings. Preview is now a row on the ManaRise page and nothing is attached to the settings window.
- **1.12.11** - No hover tooltip on the options page section titles.
- **1.12.10** - Troubleshooting commands `/mr panel off|nopreview|on` (then /reload) for the "blocked from an action" popup.
- **1.12.9** - Fixed the "blocked from an action only available to the Blizzard UI" popup in the game's own settings (Game > Social).
- **1.12.8** - The minimap right-click menu no longer lists "Open ManaRise" (same as "Options").
- **1.12.7** - The Preview button lines up with Defaults, and the preview window title is centered. Not tested in-game.
- **1.12.6** - The Preview button now sits left of Defaults at the top of the ManaRise page, and the preview window uses the game Options window look. Not tested in-game.
- **1.12.5** - Burning parchment now fills from the top down: the burn line travels down the icon as the resource rises. Not tested in-game.
- **1.12.4** - Burning: the paper texture is gone; the fill is now a see-through orange gradient matching the flames. Not tested in-game.
- **1.12.3** - Burning: removed the blue-green tint under the flames; the fill is now warm paper. Not tested in-game.
- **1.12.2** - "Burning page" is now just "Burning" (command unchanged: `/mr style paper`), and its rising particles are flame-colored embers instead of bubbles. Not tested in-game.
- **1.12.1** - The Ice style is now a clearer icy blue instead of pale green-white. Not tested in-game.
- **1.12.0** - New fill style: Burning parchment (`/mr style parchment` or the Style dropdown): cracked, scorched parchment with a jagged glowing burn line, rising embers, sparks and ash, and a golden-orange ready flash. Ice and Burning page are unchanged. Not tested in-game.
- **1.11.0** - The live preview now opens in its own window. A **Preview** button next to the settings window's Defaults button (shown on the ManaRise page) opens a small window you can move and close (X or Escape) with sample buttons that loop fill and clear using your current settings and update the moment you change anything. It runs only while that window is open. Not tested in-game; if the button cannot be placed, the page works without it.
- **1.10.0** - Live preview: while the ManaRise options page is open, a strip of sample buttons next to it fills and clears with made-up resources, using your current style, colors and sliders, and updates the moment you change anything (from the page or with slash commands). It runs only while the page is visible. Not tested in-game; if the settings window cannot host it, the page works without it.
- **1.9.0** - New fill styles: Ice (frost crystals build up as it regenerates) and Burning page (a paper fill with a burning, glowing top edge and rising embers). `/mr style ice` / `paper`, or the Style dropdown.
- **1.8.0** - Addon authors can register their own action bars with `ManaRise_RegisterBarAddon` (LibActionButton libraries, named buttons or a button list), and see them in `/mr status`, `/mr scan` and `/mr report`.
- **1.7.0** - Out-of-range mark: choose look (tint / grey / border), color and strength; spells you could not cast anyway are not marked.
- **1.6.8** - Removed the low-resource warning (border, slider, sound, `/mr low`, `/mr lowsound`); the game hides resource values on 1.60.1.
- **1.6.7** - Low-resource sound no longer skipped when another sound just played; `/mr status` shows the low-resource check.
- **1.6.6** - Optional: play the ready sound only for abilities you choose (`/mr soundspell`).
- **1.6.5** - 28 bundled alert sounds (from the SharedMedia Alert Media Pack) selectable for the ready and low-resource sounds.
- **1.6.4** - Removed the gradient and bar fill styles (a saved one switches to liquid).
- **1.6.3** - Custom sounds (file path, sound ID or a SharedMedia sound) for the ready sound, and a separate low-resource sound that plays once when a resource drops below your percentage.
- **1.6.2** - Gamepad bar frames skipped, optional range / low-resource / ready-sound signals, sweep and double-flash ready animations, richer `/mr report` diagnostics.
- **1.6.1** - EllesmereUI action bar support, Retail (12.x) support, a minimap right-click menu styled like the game's tooltips (open, options, unlock/lock position, reset position, hide), a new minimap icon, and "Casts left" removed.
- **1.6.0** - Minimap button, casts-left numbers, color presets (with a colorblind-friendly one), settings per class, `/mr report`, a one-time update message, and Traditional Chinese and (partial) Italian. Not yet tested in-game.
- **1.5.0** - ManaRise now speaks German, French, Spanish, Russian, Brazilian Portuguese, Korean and Simplified Chinese: chat messages, `/mr` help, `/mr status` and the options panel follow your game language, with English for everything else. The translations are machine-made; corrections are welcome. Slash commands stay the same in every language. The README is now a player guide, and the ZIP includes a CHANGELOG.
- **1.4.0** - Bartender4, Dominos and ElvUI support. When one of them is loaded, its action buttons get the same fill, liquid look and ready flash as the default bars, and keep up when the addon creates, hides, pages or rearranges buttons. ElvUI's square icons get a square fill that stays inside the border. `/mr status` and `/mr scan` show which bar addon was detected and how many of its buttons are tracked. Nothing changes if none of them is installed. Not yet tested in-game with these addons.
- **1.3.0** - Rage, energy and focus support. Warriors, rogues and druids in cat or bear form now see abilities fill in the resource's color (rage red, energy yellow, focus orange), and the ready flash uses that color too. A druid's buttons switch between mana, energy and rage when changing form. Rage decaying out of combat drains smoothly. Each resource has its own color: `/mr color rage C41F3B` or the new swatches in the options panel (`/mr color reset` resets all four). New `/mr resource all | mana` (also in the panel) to keep the mana-only behavior. Your 1.2.0 fill color is kept as the mana color.

- **1.2.0** - New options page in Game Menu → Options → AddOns → ManaRise (or `/mr options`): enable, style, fill opacity, empty-part darkness, fill color with a reset button, wave intensity, bubbles, ready flash, smooth fill, edge pulse, and a Preview button. It stays in sync with the slash commands. New commands: `/mr color <hex> | reset`, `/mr waves calm | normal | lively`, `/mr bubbles on | off`.
- **1.1.4** - New `/mr opacity 0-100` and `/mr dark 0-100` commands to set how see-through the blue fill is and how dark the empty part is. `/mr status` shows both.
- **1.1.3** - Fixed the liquid look never appearing ("animations failed ... Animation.lua:221"). This client can't create the wave-scrolling animation from Lua, so the waves now come from XML templates (`ManaRise.xml`), the same way Blizzard's own UI defines that animation. If that is unavailable too, the waves slide sideways instead. `/mr status` shows which method is in use ("waves: xml", "lua" or "move").
- **1.1.2** - The liquid look is now sized for real action buttons: waves about twice as tall and broader, a thicker bright wave edge, and five bigger, brighter bubbles. Before, the detail was only 2-3 pixels tall on a button and looked almost like the flat style. If the liquid look can't be built (missing Media files or an animation the client rejects), ManaRise now says so in chat instead of silently using the flat look, and `/mr status` shows a "liquid look" line.
- **1.1.1** - Addon-list icon, and the addon-list tooltip now ends with "Type /mr for options". Fixed a faint straight line that could show just above the liquid surface.
- **1.1.0** - New liquid look (default): rolling wave surface with two layers, depth shading and rising bubbles, all driven by the client's built-in animations. `/mr style flat` restores the previous look.
- **1.0.1** - Fixed: the ready-flash layer was visible on every action button all the time (it showed as a green-tinted inner border). Flash layers are now hidden whenever they aren't playing.
- **1.0.0** - First release.
