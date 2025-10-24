-- By D4KiR
local _, SpecBisTooltip = ...
local s = {}
if SpecBisTooltip:GetWoWBuild() == "MISTS" then
    function SpecBisTooltip:GetTranslationMap()
        return s
    end
end

-- SOURCE FROM: 17.07.2025
if SpecBisTooltip:GetWoWBuild() == "MISTS" then
    function SpecBisTooltip:TranslationenUS()
        s["npc;drop=55265"] = {"Morchok", "Dragon Soul"}
        s["npc;drop=56427"] = {"Warmaster Blackhorn", "Dragon Soul"}
        s["npc;sold=44245"] = {"Faldren Tillsdale <Valor Quartermaster>", "Stormwind City"}
        s["npc;drop=52571"] = {"Majordomo Staghelm <Archdruid of the Flame>", "Firelands"}
        s["npc;drop=53879"] = {"Deathwing <The Destroyer>", "Dragon Soul"}
        s["npc;drop=55294"] = {"Ultraxion", "Dragon Soul"}
    end

    function SpecBisTooltip:TranslationdeDE()
        s["npc;drop=56427"] = {"Kriegsmeister Schwarzhorn", "Drachenseele"}
        s["npc;sold=44245"] = {"Faldren Tillsdale <Rüstmeister für Tapferkeitspunkte>", "Sturmwind"}
        s["npc;drop=52571"] = {"Majordomus Hirschhaupt <Erzdruide der Flamme>", "Feuerlande"}
        s["npc;drop=53879"] = {"Todesschwinge <Der Zerstörer>", "Drachenseele"}
    end

    function SpecBisTooltip:TranslationesES()
        s["npc;drop=56427"] = {"Maestro de guerra Cuerno Negro", "Alma de Dragón"}
        s["npc;sold=44245"] = {"Faldren Labravalle <Intendente de valor>", "Ciudad de Ventormenta"}
        s["npc;drop=52571"] = {"Mayordomo Corzocelada <Archidruida de la Llama>", "Tierras de Fuego"}
        s["npc;drop=53879"] = {"Alamuerte <El Destructor>", "Alma de Dragón"}
    end

    function SpecBisTooltip:TranslationfrFR()
        s["npc;drop=56427"] = {"Maître de guerre Corne-Noire", "L’Âme des dragons"}
        s["npc;sold=44245"] = {"Faldren Tillsdale <Intendant des emblèmes de vaillance>", "Hurlevent"}
        s["npc;drop=52571"] = {"Chambellan Forteramure <Archidruide de la Flamme>", "Terres de Feu"}
        s["npc;drop=53879"] = {"Aile de mort <Le Destructeur>", "L’Âme des dragons"}
    end

    function SpecBisTooltip:TranslationitIT()
        s["npc;drop=52571"] = {"Majordomo Staghelm <Archdruid of the Flame>", "Firelands"}
    end

    function SpecBisTooltip:TranslationkoKR()
        s["npc;drop=55265"] = {"[Morchok]", "용의 영혼"}
        s["npc;drop=56427"] = {"[Warmaster Blackhorn]", "용의 영혼"}
        s["npc;sold=44245"] = {"폴드런 틸스데일 <용맹 병참장교>", "스톰윈드"}
        s["npc;drop=52571"] = {"청지기 스태그헬름 <화염의 대드루이드>", "불의 땅"}
        s["npc;drop=53879"] = {"[Deathwing] <[The Destroyer]>", "용의 영혼"}
        s["npc;drop=55294"] = {"[Ultraxion]", "용의 영혼"}
    end

    function SpecBisTooltip:TranslationptBR()
        s["npc;drop=55265"] = {"[Morchok]", "Alma Dragônica"}
        s["npc;drop=56427"] = {"[Warmaster Blackhorn]", "Alma Dragônica"}
        s["npc;sold=44245"] = {"Fernão Thadeo <Intendente de Bravura>", "Ventobravo"}
        s["npc;drop=52571"] = {"[Majordomo Staghelm] <[Archdruid of the Flame]>", "Terras do Fogo"}
        s["npc;drop=53879"] = {"[Deathwing] <[The Destroyer]>", "Alma Dragônica"}
        s["npc;drop=55294"] = {"[Ultraxion]", "Alma Dragônica"}
    end

    function SpecBisTooltip:TranslationruRU()
        s["npc;drop=55265"] = {"Морхок", "Душа Дракона"}
        s["npc;drop=56427"] = {"Воевода Черный Рог", "Душа Дракона"}
        s["npc;sold=44245"] = {"Фалдрен Тиллсдейл <Награды за очки доблести>", "Штормград"}
        s["npc;drop=52571"] = {"Мажордом Фэндрал Олений Шлем <Верховный друид пламени>", "Огненные Просторы"}
        s["npc;drop=53879"] = {"Смертокрыл <Разрушитель>", "Душа Дракона"}
        s["npc;drop=55294"] = {"Ультраксион", "Душа Дракона"}
    end

    function SpecBisTooltip:TranslationzhCN()
        s["npc;drop=55265"] = {"[Morchok]", "巨龙之魂"}
        s["npc;drop=56427"] = {"[Warmaster Blackhorn]", "巨龙之魂"}
        s["npc;sold=44245"] = {"[Faldren Tillsdale] <[Valor Quartermaster]>", "暴风城"}
        s["npc;drop=52571"] = {"[Majordomo Staghelm] <[Archdruid of the Flame]>", "火焰之地"}
        s["npc;drop=53879"] = {"[Deathwing] <[The Destroyer]>", "巨龙之魂"}
        s["npc;drop=55294"] = {"[Ultraxion]", "巨龙之魂"}
    end

    function SpecBisTooltip:TranslationzhTW()
        s["npc;drop=55265"] = {"[Morchok]", "巨龙之魂"}
        s["npc;drop=56427"] = {"[Warmaster Blackhorn]", "巨龙之魂"}
        s["npc;sold=44245"] = {"[Faldren Tillsdale] <[Valor Quartermaster]>", "暴风城"}
        s["npc;drop=52571"] = {"[Majordomo Staghelm] <[Archdruid of the Flame]>", "火焰之地"}
        s["npc;drop=53879"] = {"[Deathwing] <[The Destroyer]>", "巨龙之魂"}
        s["npc;drop=55294"] = {"[Ultraxion]", "巨龙之魂"}
    end
end
