# Transmog Loot Helper

## [v12.0.7-03](https://github.com/Slackluster/TransmogLootHelper/tree/v12.0.7-03) (2026-07-05)
[Full Changelog](https://github.com/Slackluster/TransmogLootHelper/compare/v12.0.7-02...v12.0.7-03) [Previous Releases](https://github.com/Slackluster/TransmogLootHelper/releases)

- Add DF dragon manuscriots  
- Capitalisation for settings consistency  
- Alphabetical integration loading  
- Add Bagforge bag addon integration (#91)  
    ## Summary  
    - Adds `integrations/Bagforge.lua`, mirroring the existing OneWoW\_Bags  
    integration pattern.  
    - Registers TLH overlays on Bagforge item buttons via  
    `Bagforge.API:RegisterItemButtonCallback`.  
    - Calls `Bagforge.API:RequestItemButtonsRefresh()` when overlay settings  
    change (same as Baganator).  
    - Lists Bagforge in README supported addons.  
    ## Bagforge API (upstream addon)  
    Bagforge exposes this plugin surface for third-party bag overlays:  
    ```lua  
    Bagforge.API:RegisterItemButtonCallback("TransmogLootHelper", function(button, bagID, slotID, entry) ... end)  
    Bagforge.API:RequestItemButtonsRefresh()  
    ```  
    Maintainer: happy to adjust if you prefer a different hook shape.  
    ## Test plan  
    - [x] Enable TransmogLootHelper + Bagforge; open backpack —  
    transmog/collection icons appear on eligible items.  
    - [x] Open bank (Bagforge bank view) — overlays appear on bank items.  
    - [x] Change TLH icon style in settings — Bagforge buttons refresh  
    without `/reload`.  
    - [x] Toggle TLH overlay off — icons disappear from Bagforge buttons.  
    - [x] Verify no errors with only one of the two addons loaded.  
    ---------  
    Co-authored-by: Cursor <cursoragent@cursor.com>  
- Update OneWoW\_Bags integration  
