local ADDON_NAME, ADT = ...
ADT = ADT or {}
ADT.UI = ADT.UI or {}

function ADT.UI.PlaySoundCue(key)
    local kit = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 1204
    if key == 'ui.checkbox.off' then
        kit = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF or 1203
    elseif key == 'ui.scroll.step' or key == 'ui.scroll.thumb' then
        kit = SOUNDKIT and SOUNDKIT.IG_MINIMAP_OPEN or 891
    elseif key == 'ui.tab.switch' then
        kit = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION or 857
    end
    if PlaySound then pcall(PlaySound, kit) end
end

