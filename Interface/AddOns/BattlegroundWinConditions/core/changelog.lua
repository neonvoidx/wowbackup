local AddonName, NS = ...

local LibStub = LibStub

local LibChangelog = LibStub("LibChangelog")

local Changelog = {}
NS.Changelog = Changelog

local changelog = {
  {
    Version = "9.8.4",
    General = "General updates",
    Sections = {
      {
        Header = "Changes",
        Entries = {
          "Lua cleanup",
          "Adding orb stack persistence through reload"
        },
      },
    },
  },
  {
    Version = "9.8.3",
    General = "Minor updates",
    Sections = {
      {
        Header = "Changes",
        Entries = {
          "Fixing new font api changes from recent patch",
        },
      },
    },
  },
  {
    Version = "9.8.2",
    General = "Midnight refactors",
    Sections = {
      {
        Header = "Changes",
        Entries = {
          "Updating how objective tracking works for flag and orb maps based on the new limitations in midnight",
        },
      },
      {
        Header = "Bugfixes",
        Entries = {
          "Fixing tiny tick gap check for win cons",
        },
      },
    },
  },
  {
    Version = "9.8.1",
    General = "Major Performance Improvements",
    Sections = {
      {
        Header = "Changes",
        Entries = {
          "Updates Blitz EOTS flag cap to not reset the banner anymore to account for map changes",
          "Updates Blitz EOTS info conditions and resource information to account for map changes",
          "Fixing win calculation repeated calls for performance",
          "Variable name cleanup",
          "Performance improvements",
        },
      },
      {
        Header = "Bugfixes",
        Entries = {
          "Fixing localization issue with faction names",
          "Fixing tick 'drift' to account for logic and mid-tick calculations",
        },
      },
    },
  },
  {
    Version = "9.8.0",
    General = "Midnight prepatch + launch updates",
    Sections = {
      {
        Header = "Changes",
        Entries = {
          "Updating match state check",
          "Updating toc for midnight prepatch + launch",
          "Handling secret values for moving frames while in-combat or in instances",
          "General cleanup",
        },
      },
    },
  },
  {
    Version = "9.7.5",
    General = "Minor updates",
    Sections = {
      {
        Header = "Changes",
        Entries = {
          "Store variable for reference",
          "Proper type referencing",
          "Update toc",
        },
      },
    },
  },
  {
    Version = "9.7.4",
    General = "Various bugfixes and improvements",
    Sections = {
      {
        Header = "Changes",
        Entries = {
          "Stripping the placement info back down to just the basic info text and win banner",
          "Updating order of operations in the bases prediction code",
          "Assigning addon to my own category for organization",
          "Update toc",
        },
      },
      {
        Header = "Bugfixes",
        Entries = {
          "Fixing the info background code to 100% properly set the width and height, and ONLY update when absolutely needed",
          "Adding check to not show eots flag ahead/behind info during a tie game",
          "Updating orb info anchor since there is no banner",
          "Minor cleanup",
        },
      },
    },
  },
  {
    Version = "9.7.3",
    General = "EOTS changes + bugfixes",
    Sections = {
      {
        Header = "Changes",
        Entries = {
          "Shows flag info on EOTS even during tie game since you can still win with a flag",
          "Update toc",
        },
      },
      {
        Header = "Bugfixes",
        Entries = {
          "Hiding previous game info when leaving a battleground",
        },
      },
    },
  },
  {
    Version = "9.7.2",
    General = "EOTS additions + bugfixes",
    Sections = {
      {
        Header = "New",
        Entries = {
          "Adding back in EOTS Flag Value text line so you know when to cap to win in blitz",
        },
      },
      {
        Header = "Bugfixes",
        Entries = {
          "Hiding test info when loading into non-battleground instances or not outdoors",
          "Updating EOTS Blitz base reset timer to be the correct 20 seconds instead of 15",
        },
      },
    },
  },
  {
    Version = "9.7.1",
    General = "Fixing minor background bug",
    Sections = {
      {
        Header = "Bugfixes",
        Entries = {
          "Updating info and banner size updates based on recent bugs and testing",
        },
      },
    },
  },
  {
    Version = "9.7.0",
    General = "Major overhaul and cleanup",
    Sections = {
      {
        Header = "Overhaul",
        Entries = {
          "Complete overhaul of map controller managing entering/exiting bgs and their state",
          "New supporting helpers from event and state refactoring",
          "Leveraging blizzard api enums over hard coded values in conditionals",
          "Using variables for max scores instead of hard coded values",
          "Reverting flag cap functions back to inline handling logic per battleground message",
          "Adding early out on orbs if unit isn't a carrier",
          "Map settings overhaul for all maps to create common configs for easy switching between blitz and regular bgs",
          "Adding additional checks for win con triggers to include inc base changes not just point changes",
        },
      },
      {
        Header = "New Map Support",
        Entries = {
          "Adding Deephaul Ravine to the list of maps, but not yet completed",
        },
      },
      {
        Header = "General",
        Entries = {
          "New simplified interface start function",
          "New changelog manager and dialog lib",
          "Adding version check code",
          "Minor Cleanup",
          "Update toc",
        },
      },
      {
        Header = "Bugfixes",
        Entries = {
          "Adding some additional conditional checks from recent testing and bugs",
          "Changing checks in base caps to proper conditional lua statements",
          "Fixing base reset on blitz eots to always show correctly",
          "Adding an additional check for flag caps to reset stacks",
          "Updating db cleanup function to ignore lastReadVersion and lastFlagCapBy as those are set dynamically",
          "Drag and Click control updates to ensure click through when hidden or locked",
          "Fixing font dropdown list",
          "Updating font size range",
        },
      },
    },
  },
  {
    Version = "9.6.22",
    General = "Fixing various bugs",
    Sections = {
      {
        Header = "Bugfixes",
        Entries = {
          "Adding back in EOTS helper function to check if we're on EOTS",
          "Adding in a new debug feature to easily leave out prints when not debugging",
          "Fixed group size check from wrong variable/api",
          "Fixed faction setting by updating and adding placements for setting it upon entering a bg",
          "Fixed load in game check when toggling zones in and out of instances",
          "Updated flag cap check on base maps (EOTS) to remove old dwg check which no longer exists",
        },
      },
    },
  },
  {
    Version = "9.6.21",
    General = "Adding eots blitz support",
    Sections = {
      {
        Header = "EOTS Blitz Support",
        Entries = {
          "Adding EOTS Battleground Blitz mode support",
          "NEW feature that shows reset timer in the banner after capping",
        },
      },
      {
        Header = "New setting",
        Entries = {
          "Added new setting for the new reset banner timer",
          "Fixed being able to see your banner color changes real time",
        },
      },
      {
        Header = "General",
        Entries = {
          "Removed old helper functions",
          "Fixed incorrect win time in info text when winning with 1 base",
          "Added some null checks based on recent testing and bugs caught",
          "Added new 'they can still win with' condition based on EOTS blitz testing",
          "Adding failsafe for map zone toggle",
          "Minor cleanup",
        },
      },
    },
  },
  {
    Version = "9.6.11",
    General = "New TOK feature and start of blitz support",
    Sections = {
      {
        Header = "Blitz Support",
        Entries = {
          "All new Battleground Blitz support for the following maps with EXISTING features:",
          "The Battle for Gilneas",
          "Twin Peaks",
          "Warsong Gulch",
        },
      },
      {
        Header = "New TOK Feature",
        Entries = {
          "NEW Temple of Kotmogu feature that shows available orbs, and when an orb is taken it shows the damage taken increase percentage for that orb carrier",
          "This new feature can be toggled on/off in the settings",
        },
      },
      {
        Header = "General",
        Entries = {
          "Lots of performance enhancements that aims to reduce and reuse duplicate code in loops and aura checking into helper functions",
          "Updates the default font-size to 14",
          "Prep work to add support for Battleground Blitz for the remaining maps",
          "Minor cleanup and fixes",
        },
      },
    },
  },
  {
    Version = "9.5.10",
    General = "Latest round of bugs and refactors and updates",
    Sections = {
      {
        Header = "General",
        Entries = {
          "Lib updates",
          "TOC updates",
          "Refactor of the Win Conditions algorithm and incoming base info to be fully tick based and not time based which has TIE game implications and should provide more accurate results",
          "Updating the placeholder text win condition info",
          "Adds check upon joining game to ensure you're not in an 8v8 blitz mode game since that will have its own code and or addon",
          "Simplifying win/lose text on banner upon timer expiring",
          "Adding various win condition text info to help the user know in tricky situations what the loser wins with or not",
          "Adding simplified lose text upon timer expiring",
          "Refactor win condition table to only grab first win condition for performance reasons since bases can change all the time we don't need to process and store all future conditions if they never get used for the most part",
          "Triggering win condition prediction upon first win condition timer expiring based on new refactor",
          "Fixing flag map stack issues resetting after dropping then someone else picking up while stacks are counting",
          "Moving all flag stack logic to pvp channel messages instead of arena updates apis for consistency and reliability",
        },
      },
    },
  },
  {
    Version = "9.4.22",
    General = "Fixing text anchor",
    Sections = {
      {
        Header = "General",
        Entries = {
          "Fixing text anchor from not being set correctly after Temple of Kotmogu",
        },
      },
    },
  },
  {
    Version = "9.4.21",
    General = "New settings and setting bug fixes",
    Sections = {
      {
        Header = "General",
        Entries = {
          "Added a new setting to be able to add a background to the info text",
          "Added a new setting to be able to change the info text color",
          "Added a new setting to be able to turn off Temple orb buff text",
          "Added a new setting to be able to turn off flag map info on EOTS",
          "Updated setting descriptions",
          "Fixed various bugs with turning off and on settings and combinations of settings to hide/show properly",
          "Fixing 10.2.7 bugs for incorrect setting of text justification",
          "Updated some file names to better match their usage",
          "Update toc",
        },
      },
    },
  },
  {
    Version = "9.3.21",
    General = "Various fixes based on recent testing",
    Sections = {
      {
        Header = "Fixes incorrect stack syncing on flag maps",
        Entries = {
          "Removes the arena opponent api checks as they're unreliable and fire at times not just when someone picks",
          "Fixes resetting the stack timer if the flag drops and someone else picks",
          "Better ensures you're only tracking flag carriers and resetting only when needed",
          "Falls back to timer based stacks when dead since UNIT_AURA doesn't track enemies while dead",
        },
      },
      {
        Header = "General",
        Entries = {
          "Adjusts the time to win on base maps when capping the first base or just a single base in general, time is now banner win time",
          "Enables the debuff info on flag map info incase people haven't seen that option yet",
        },
      },
    },
  },
  {
    Version = "9.3.20",
    General = "Fixing flag map stack + removing base info minimum",
    Sections = {
      {
        Header = "Bugfixes",
        Entries = {
          "Fixing slash commands",
          "Removing flag cap maximum stacks since there is no more limit from what i found in recent testing",
          "Removing the need for points on the board to see if you win or not in base maps, so now you can know immediately upon first cap",
          "Fixing incorrect stack resetting based on arena frame updates since it's not reliable and has the ability to mess with stack counts",
        },
      },
    },
  },
  {
    Version = "9.3.19",
    Sections = {
      {
        Header = "Bugfixes",
        Entries = {
          "Fixing eots flags needed calculation when ahead in points and bases",
          "adding updated descriptions for individual map enabling toggles",
          "always clearing interface upon joining new games",
          "updating banner scale minimum",
        },
      },
    },
  },
  {
    Version = "9.3.18",
    General = "Adding new option to settings",
    Sections = {
      {
        Header = "General",
        Entries = {
          "Adding a new setting to turn off the GG Banner and only show the win text",
          "Updated some setting descriptions and labels",
          "Updating the minimums for banner scale and font size",
        },
      },
    },
  },
  {
    Version = "9.3.17",
    Sections = {
      {
        Header = "Bugfixes",
        Entries = {
          "Fixing setting some vars once joining a game",
        },
      },
    },
  },
  {
    Version = "9.3.16",
    General = "Major refactor for all new feature sets",
    Sections = {
      {
        Header = "Complete overhaul of the settings options to include",
        Entries = {
          "Choosing your font size",
          "Banner Scaling",
          "Banner colors for TIE, WIN, LOSE",
          "Enable or Disable by Map",
          "Enable or Disable certain features on EOTS and Flag maps",
        },
      },
      {
        Header = "NEW flag map features",
        Entries = {
          "Shows a Next stack timer",
          "Shows how many stacks are currently applied",
          "Shows timer to 6 stacks",
          "Shows healing received reduction %",
          "Shows damage taken increase %",
        },
      },
      {
        Header = "NEW refactored EOTS flag text",
        Entries = {
          "Instead of showing the point value of a flag i now show how many flags you are either ahead or behind by so you know an additional win condition",
        },
      },
      {
        Header = "Performance improvements",
        Entries = {
          "amidst various random cleanup and refactor is now only the necessary code runs on certain maps reducing the amount of processing needed real time",
        },
      },
      {
        Header = "General",
        Entries = {
          "Refactored the win algorithm to be TICK based instead of TIME based to more accurately detect TIE games and reduce loops to run increasing performance",
          "Win Timer bug fixes during incoming bases",
        },
      },
    },
  },
  {
    Version = "8.2.15",
    Sections = {
      {
        Header = "Bugfixes",
        Entries = {
          "fixing bugs on eots",
        },
      },
    },
  },
  {
    Version = "8.2.14",
    Sections = {
      {
        Header = "General",
        Entries = {
          "refactoring the predictor code to be its own function so it can be called on base update events and not just score updates",
          "removing old unused code for cleanup",
          "fixing a drag issue upon locking",
        },
      },
    },
  },
  {
    Version = "8.1.13",
    Sections = {
      {
        Header = "Bugfixes",
        Entries = {
          "fixing potential win time algorithm",
        },
      },
    },
  },
  {
    Version = "8.1.12",
    Sections = {
      {
        Header = "General",
        Entries = {
          "refactor update check to fix an issue where the it wasn't properly getting the the correct incoming base counts",
        },
      },
    },
  },
  {
    Version = "8.1.11",
    Sections = {
      {
        Header = "General",
        Entries = {
          "updating implementation of new version handling",
          "main file event re-order to remove hoisting",
          "win info variable cleanup",
          "update slash commands to all be toggle based",
        },
      },
    },
  },
  {
    Version = "8.1.10",
    Sections = {
      {
        Header = "Bugfixes",
        Entries = {
          "fixing a bug where the enemy base timer wasn't getting reset when you got a base back them before it finished capping or if you stole a base from them mid-cap",
        },
      },
    },
  },
  {
    Version = "8.1.9",
    General = "First major refactor",
    Sections = {
      {
        Header = "General",
        Entries = {
          "fixing TIE game support",
          "making sure you cant click the anchor when its set to hidden while locked",
          "adding all new slash commands (see description for info)",
          "major code cleanup on code warnings to make things as clean and performant as possible",
          "refactoring some of the algorithm based on recent testing and bugs found to reduce code and sync mid-cap to end of cap data",
          "refactoring the all of the event for base tracking, flag tracking, and score tracking to use a single event UPDATE_UI_WIDGET",
          "added new support for mid-game loading where i make an initial call to get active bases by mapID instead of widgetID",
          "fixed a bug related to the algorithm to ensure the correct minimum bases you need to hold",
          "fixed missing variable assignments in the score trigger checks",
          "clearing the interface upon joining any pvp game in order to hide it on maps that aren't yet supported or in arena",
          "removed unused code and some remnants of the old ways of getting bases and handling bars",
          "adding foundational code for silvershard mines, warsong gulch, and twin peaks",
          "update to mod events in the new cleanup",
          "making some remaining static strings config variables to be fully dynamic",
        },
      },
    },
  },
  {
    Version = "8.0.8",
    General = "Adding tie game support",
    Sections = {
      {
        Header = "General",
        Entries = {
          "adding support for TIE games",
          "adding WoW Interface project ID",
          "update the user experience for the anchor",
        },
      },
    },
  },
  {
    Version = "8.0.7",
    General = "Creating new banner only option",
    Sections = {
      {
        Header = "General",
        Entries = {
          "providing an option to be able to only show the win banner if desired",
          "abstracting out all global functions and utils possible to local vars for performance",
        },
      },
    },
  },
  {
    Version = "8.0.6",
    General = "Matching cap needs to owned needs",
    Sections = {
      {
        Header = "General",
        Entries = {
          "making sure future need info during an assault matches what you need after the bases cap over and become owned",
        },
      },
    },
  },
  {
    Version = "8.0.5",
    General = "Fixing EOTS",
    Sections = {
      {
        Header = "Bugfixes",
        Entries = {
          "removing the check for if you're in a random eots game as it produced incorrect results, and realistically we dont need to exclude eots from incoming base code because there will never trigger an incoming base on eots as that mechanism doesn't exist there, and on rated eots we always want the normal code anyways so its a win win to just remove the extra logic",
        },
      },
    },
  },
  {
    Version = "8.0.4",
    General = "Clearing info leaving a battleground",
    Sections = {
      {
        Header = "General",
        Entries = {
          "resetting game info when leaving battleground",
          "update the user experience for the anchor",
        },
      },
    },
  },
  {
    Version = "8.0.3",
    Sections = {
      {
        Header = "General",
        Entries = {
          "update toc",
        },
      },
    },
  },
  {
    Version = "8.0.2",
    Sections = {
      {
        Header = "Bugfixes",
        Entries = {
          "fixing orb buff timer team name color",
        },
      },
    },
  },
  {
    Version = "8.0.1",
    Sections = {
      {
        Header = "General",
        Entries = {
          "addon uploaded to github + curseforge",
        },
      },
    },
  },
}

function Changelog:Setup()
  LibChangelog:Register(AddonName, changelog, NS.db, "lastReadVersion", "onlyShowWhenNewVersion")
  LibChangelog:ShowChangelog(AddonName)
end
