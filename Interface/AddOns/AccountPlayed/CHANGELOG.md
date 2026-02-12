# Account Played

## [v1.0.3](https://github.com/Jeremy-Gstein/AccountPlayed/tree/v1.0.3) (2026-02-08)
[Full Changelog](https://github.com/Jeremy-Gstein/AccountPlayed/compare/v1.0.2...v1.0.3) [Previous Releases](https://github.com/Jeremy-Gstein/AccountPlayed/releases)

- Release: v1.0.3 - Patch: Improved minimap button (drag or snap to minimap), press escape to close, and hover on classes to see the characters that makeup the data... TY everyone for checking out the addon and sharing your screenshots online <3  
- New: support installs on wago.io  
- Feature: tested classic client (11508) and it works! added tbh, and mop tocs for now but have NOT tested those version  
- Revise README with additional features and credits  
    Updated the README to include new features and acknowledgments.  
- Refactor: merge community PRs with new features: on hover character stats, move the minimap icon as you please OR snap it to the minimap (#3)  
- Fix: merge issues with #3 and update README  
- Show total played time in days when >= 24 hours  
    FormatTimeSmart now displays "#d #h #m" instead of "#h #m" when the total account time is 24 hours or more (e.g., "241d 1h 52m" instead of "5785h 52m").  
- Feature: hover over classes to see a popup of characters that make up the data  
- Feature: hover over classes to see a popup of characters that make up the data  
- Widen class name column to fit DEATHKNIGHT and DEMONHUNTER without truncation  
- Replace angle-based minimap icon positioning with hybrid snap/free-form drag system  
- THANK YOU FOR ALL THE FEEDBACK/SUPPORT ON REDDIT/WOWHEAD/DISCORD/TWITCH I love seeing all the screenshots!! <3  
- Patch: fix size from resetting on reload or exit by saving window size state to AccountPlayedPopupDB  
- Patch: Attempt to fix missing minimap bug by changing name of frame from generic 'f' to 'AP'  
- Feature: new functions for other addons to safley read from AccountPlayedDB. list, query, and return total time played see githup README or AccountPlayed.lua for more detailed descriptions.  
- Update CurseForge Downloads badge  