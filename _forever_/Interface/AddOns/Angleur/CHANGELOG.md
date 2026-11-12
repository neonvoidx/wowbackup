# Angleur

## [2.9.81-EqManAndLuaErrorHotfixes](https://github.com/LegolandoBloom/Angleur/tree/2.9.81-EqManAndLuaErrorHotfixes) (2026-11-11)
[Full Changelog](https://github.com/LegolandoBloom/Angleur/compare/2.9.8-AutoEquipFishingRod...2.9.81-EqManAndLuaErrorHotfixes) [Previous Releases](https://github.com/LegolandoBloom/Angleur/releases)

- fixed UI bug caused by search bar taint:  
    - disabled "search tags" in Angleur's Addons Tab entry for the "Open Config Panel" button.  
    May re-enable if this is fixed in the future.  
- eqMan will no longer equip offhand/mainhand weapons or trinkets in the wrong slots  
- Legolando\_HelpTipTemplate:  
    - removed the superfluous self.partActive field  
    - added methods: GetActivePartIndex() and GetActivePartTable()  
- startingPart argument to Activate is now optional(HelpTip)  
- added addon compartment to Forever(same as Retail)  
- Big Important Changes to HelpTip Template:  
    - added method :ResetTutorial()  
        sets tutorial savedVar to part 1  
        calls :ResetAttempts()  
    - added method :ResetAttempts()  
    - added method :HasRunOutOfAttempts()  
    now possible to give an optional "max attempts" to the HelpTip template. If not completed previously, it will show the user the tutorial again, until the max attempts reached, upon which :SkipTutorial() will be called.  
    :SkipTutorial() now calls :ResetAttempts()  
    :Activate() will call :HasRunOutOfAttemts and if true, will call SkipTutorial and return early  
    Made changes to tiny\_base.lua and firstInstall.lua to fit new HelpTipTemplate  
    init.lua -> Init\_AngleurSavedVariables now also sets AngleurTutorial.attemptsRemaining  
- Legolando\_HelpTipTemplate CloseButton now has the same, built-in texture on all flavors with proper normal, pushed and hilight textures.  
- Renamed AngleurVanilla\_FishingSpellTable and AngleurVanilla\_FishingPoleTable to AngleurVanillaForever  
    Vanilla and Forever fishing spell and pole tables will be merged for now. In case vanilla fishing rods get ported to Forever over the year. Eventually I will separate them.  
