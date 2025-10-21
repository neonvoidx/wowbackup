# Transmog Loot Helper

## [v11.2.5-002](https://github.com/Slackluster/TransmogLootHelper/tree/v11.2.5-002) (2025-10-18)
[Full Changelog](https://github.com/Slackluster/TransmogLootHelper/compare/v11.2.5-001...v11.2.5-002) [Previous Releases](https://github.com/Slackluster/TransmogLootHelper/releases)

- Ignore Magic Broom. It is a mount, and it is unlearned, but it is also unlearnable.  
- BoA items no longer show as being BoP items with the item overlay bindtext  
- Pedantic edit of a variable flag  
- FInally, a decent solution for containers from vendors not showing as containers right after buying them  
- Revert not using a cache to evaluate items - this causes major lagspikes when opening big inventories  
- Removed an unreliable evaluation  
- Changed some numbers to enums  
- Specific gold bags now also qualify as containers  
- No longer cache item evaluations for the overlay, as they can change  
- Update README.md  
- Update ruRU.lua (#29)  
