-- Overachiever2_Tabs: Localization
-- Centralized string management for different languages

local _, ns = ...

-- Metatable to return the key itself if no translation is found
local L = setmetatable({}, {
    __index = function(t, k)
        return k
    end
})

ns.L = L

-- ============================================================================
-- Default: English (enUS / enGB)
-- ============================================================================

-- Common
L["SORT_BY"] = "Sort by:"

L["TAB_WATCH"] = "Watch"
L["TAB_WATCH_DESC"] = "Collect favorite achievements in a personal watch list.\nAlt+Click any achievement to add it."
L["TAB_WATCH_REMOVE_ACHIEVEMENT"] = "Remove achievement from watch list. You can also Alt+Right-click to remove it."

L["TAB_SEARCH"] = "Search"
L["TAB_SEARCH_DESC"] = "Search for achievements by name, description, criteria, or rewards."
L["TAB_SEARCH_NAME"] = "Name/ID:"
L["TAB_SEARCH_FIELD_DESC"] = "Description:"
L["TAB_SEARCH_CRITERIA"] = "Criteria:"
L["TAB_SEARCH_REWARD"] = "Reward:"
L["TAB_SEARCH_ANY"] = "Any field:"
L["TAB_SEARCH_TYPE"] = "Type:"
L["TAB_SEARCH_TYPE_ALL"] = "All"
L["TAB_SEARCH_TYPE_PERSONAL"] = "Personal"
L["TAB_SEARCH_TYPE_GUILD"] = "Guild"
L["TAB_SEARCH_TYPE_OTHER"] = "Unlisted"
L["TAB_SEARCH_INCLUDE_UNLISTED"] = "Include unlisted achievements"
L["TAB_SEARCH_INCLUDE_UNLISTED_TIP"] = "When checked, includes hidden achievements (e.g. Feats of Strength, faction-specific) that aren't normally shown in the achievement UI."
L["TAB_SEARCH_SUBMIT"] = "Search"
L["TAB_SEARCH_RESET"] = "Reset"
L["TAB_SEARCH_RESULTS"] = "Found %d achievement(s)"
L["TAB_SEARCH_SEARCHING"] = "Searching..."
L["TAB_SEARCH_EMPTY_TEXT"] = "Enter search terms and click Search.\nYou can search by achievement name, ID, description, criteria, or rewards."

L["TAB_SUGGESTIONS"] = "Suggestions"
L["TAB_SUGGESTIONS_DESC"] = "Suggested achievements based on your current location."
L["TAB_SUGGESTIONS_RESULTS"] = "%d suggestion(s) found."
L["TAB_SUGGESTIONS_EMPTY"] = "No suggestions for this location."
L["TAB_SUGGESTIONS_LOCATION"] = "Current location:"
L["TAB_SUGGESTIONS_INCLUDE_COMPLETED"] = "Include completed"
L["TAB_SUGGESTIONS_INCLUDE_COMPLETED_TIP"] = "When checked, shows all achievements including those already completed. When unchecked, only incomplete achievements and criteria are shown."
L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION"] = "Include other faction"
L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION_TIP"] = "When checked, shows achievements from both factions regardless of your current faction. When unchecked, only achievements for your faction are shown."

L["CTXMENU_LINK_CHAT"] = "Link to Chat"
L["CTXMENU_LINK_WOWHEAD"] = "Wowhead Link"
L["CTXMENU_WATCH_ADD"] = "Add to Watch List"
L["CTXMENU_WATCH_REMOVE"] = "Remove from Watch List"
L["CTXMENU_TRACK"] = "Track Achievement"
L["CTXMENU_UNTRACK"] = "Untrack Achievement"

local locale = GetLocale()

-- ============================================================================
-- Korean (koKR)
-- ============================================================================

if locale == "koKR" then
    -- Common
    L["SORT_BY"] = "정렬:"

    L["TAB_WATCH"] = "감시"
    L["TAB_WATCH_DESC"] = "개인 감시 목록에 좋아하는 업적을 수집합니다.\nAlt+클릭으로 업적을 추가하세요."
    L["TAB_WATCH_REMOVE_ACHIEVEMENT"] = "감시 목록에서 업적 제거. Alt+오른쪽 클릭으로도 제거할 수 있습니다."

    L["TAB_SEARCH"] = "검색"
    L["TAB_SEARCH_DESC"] = "이름, 설명, 조건 또는 보상으로 업적을 검색합니다."
    L["TAB_SEARCH_NAME"] = "이름/ID:"
    L["TAB_SEARCH_FIELD_DESC"] = "설명:"
    L["TAB_SEARCH_CRITERIA"] = "조건:"
    L["TAB_SEARCH_REWARD"] = "보상:"
    L["TAB_SEARCH_ANY"] = "모든 필드:"
    L["TAB_SEARCH_TYPE"] = "유형:"
    L["TAB_SEARCH_TYPE_ALL"] = "전체"
    L["TAB_SEARCH_TYPE_PERSONAL"] = "개인"
    L["TAB_SEARCH_TYPE_GUILD"] = "길드"
    L["TAB_SEARCH_TYPE_OTHER"] = "미등록"
    L["TAB_SEARCH_INCLUDE_UNLISTED"] = "숨겨진 업적 포함"
    L["TAB_SEARCH_INCLUDE_UNLISTED_TIP"] = "체크하면 일반적으로 업적 UI에 표시되지 않는 숨겨진 업적(예: 업적 점수 미포함, 진영 전용)을 포함합니다."
    L["TAB_SEARCH_SUBMIT"] = "검색"
    L["TAB_SEARCH_RESET"] = "초기화"
    L["TAB_SEARCH_RESULTS"] = "%d개의 업적을 찾았습니다"
    L["TAB_SEARCH_SEARCHING"] = "검색 중..."
    L["TAB_SEARCH_EMPTY_TEXT"] = "검색어를 입력하고 검색 버튼을 클릭하세요.\n업적 이름, ID, 설명, 조건 또는 보상으로 검색할 수 있습니다."

    L["TAB_SUGGESTIONS"] = "추천"
    L["TAB_SUGGESTIONS_DESC"] = "현재 위치에 따른 추천 업적입니다."
    L["TAB_SUGGESTIONS_RESULTS"] = "%d개의 추천 업적을 찾았습니다."
    L["TAB_SUGGESTIONS_EMPTY"] = "이 위치에 대한 추천이 없습니다."
    L["TAB_SUGGESTIONS_LOCATION"] = "현재 위치:"
    L["TAB_SUGGESTIONS_INCLUDE_COMPLETED"] = "완료된 항목 포함"
    L["TAB_SUGGESTIONS_INCLUDE_COMPLETED_TIP"] = "체크하면 이미 완료한 업적을 포함한 모든 업적을 표시합니다. 체크 해제하면 미완료 업적과 조건만 표시됩니다."
    L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION"] = "다른 진영 포함"
    L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION_TIP"] = "체크하면 현재 진영에 관계없이 양쪽 진영의 업적을 모두 표시합니다. 체크 해제하면 현재 진영의 업적만 표시됩니다."

    L["CTXMENU_LINK_CHAT"] = "채팅에 링크"
    L["CTXMENU_LINK_WOWHEAD"] = "Wowhead 링크"
    L["CTXMENU_WATCH_ADD"] = "관심 목록에 추가"
    L["CTXMENU_WATCH_REMOVE"] = "관심 목록에서 제거"
    L["CTXMENU_TRACK"] = "업적 추적"
    L["CTXMENU_UNTRACK"] = "업적 추적 해제"
end

-- ============================================================================
-- Simplified Chinese (zhCN)
-- ============================================================================

if locale == "zhCN" then
    -- Common
    L["SORT_BY"] = "排序："

    L["TAB_WATCH"] = "关注"
    L["TAB_WATCH_DESC"] = "将喜爱的成就加入个人关注列表。\n按住Alt键点击任意成就即可添加。"
    L["TAB_WATCH_REMOVE_ACHIEVEMENT"] = "从关注列表中移除此成就。您也可通过Alt+右键点击直接移除。"

    L["TAB_SEARCH"] = "搜索"
    L["TAB_SEARCH_DESC"] = "按名称、描述、条件或奖励搜索成就。"
    L["TAB_SEARCH_NAME"] = "名称/ID："
    L["TAB_SEARCH_FIELD_DESC"] = "描述："
    L["TAB_SEARCH_CRITERIA"] = "条件："
    L["TAB_SEARCH_REWARD"] = "奖励:"
    L["TAB_SEARCH_ANY"] = "任意字段："
    L["TAB_SEARCH_TYPE"] = "类型："
    L["TAB_SEARCH_TYPE_ALL"] = "全部"
    L["TAB_SEARCH_TYPE_PERSONAL"] = "个人"
    L["TAB_SEARCH_TYPE_GUILD"] = "公会"
    L["TAB_SEARCH_TYPE_OTHER"] = "未列出"
    L["TAB_SEARCH_INCLUDE_UNLISTED"] = "包含未列出的成就"
    L["TAB_SEARCH_INCLUDE_UNLISTED_TIP"] = "勾选后将包含通常不在成就界面显示的隐藏成就（如：壮举、阵营专属）。"
    L["TAB_SEARCH_SUBMIT"] = "搜索"
    L["TAB_SEARCH_RESET"] = "重置"
    L["TAB_SEARCH_RESULTS"] = "找到 %d 个成就"
    L["TAB_SEARCH_SEARCHING"] = "搜索中..."
    L["TAB_SEARCH_EMPTY_TEXT"] = "输入搜索条件后点击搜索。\n您可以按成就名称、ID、描述、条件或奖励进行搜索。"

    L["TAB_SUGGESTIONS"] = "推荐"
    L["TAB_SUGGESTIONS_DESC"] = "根据当前位置推荐的成就。"
    L["TAB_SUGGESTIONS_RESULTS"] = "找到 %d 条推荐。"
    L["TAB_SUGGESTIONS_EMPTY"] = "当前位置没有推荐。"
    L["TAB_SUGGESTIONS_LOCATION"] = "当前位置："
    L["TAB_SUGGESTIONS_INCLUDE_COMPLETED"] = "包含已完成的"
    L["TAB_SUGGESTIONS_INCLUDE_COMPLETED_TIP"] = "勾选后显示所有业绩，包括已完成的。取消勾选后仅显示未完成的成就和条件。"
    L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION"] = "包含其他阵营"
    L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION_TIP"] = "勾选后显示双方阵营的成就，无论您当前属于哪个阵营。取消勾选后仅显示您所在阵营的成就。"

    L["CTXMENU_LINK_CHAT"] = "链接到聊天"
    L["CTXMENU_LINK_WOWHEAD"] = "Wowhead 链接"
    L["CTXMENU_WATCH_ADD"] = "添加到关注列表"
    L["CTXMENU_WATCH_REMOVE"] = "从关注列表移除"
    L["CTXMENU_TRACK"] = "追踪成就"
    L["CTXMENU_UNTRACK"] = "取消追踪成就"
end

-- ============================================================================
-- Traditional Chinese (zhTW)
-- ============================================================================

if locale == "zhTW" then
    -- Common
    L["SORT_BY"] = "排序："

    L["TAB_WATCH"] = "關注"
    L["TAB_WATCH_DESC"] = "將喜愛的成就加入個人關注清單。\n按住Alt鍵點擊任意成就即可新增。"
    L["TAB_WATCH_REMOVE_ACHIEVEMENT"] = "從關注清單中移除此成就。您也可透過Alt+右鍵點擊直接移除。"

    L["TAB_SEARCH"] = "搜尋"
    L["TAB_SEARCH_DESC"] = "按名稱、描述、條件或獎勵搜尋成就。"
    L["TAB_SEARCH_NAME"] = "名稱/ID："
    L["TAB_SEARCH_FIELD_DESC"] = "描述："
    L["TAB_SEARCH_CRITERIA"] = "條件："
    L["TAB_SEARCH_REWARD"] = "獎勵："
    L["TAB_SEARCH_ANY"] = "任意欄位："
    L["TAB_SEARCH_TYPE"] = "類型："
    L["TAB_SEARCH_TYPE_ALL"] = "全部"
    L["TAB_SEARCH_TYPE_PERSONAL"] = "個人"
    L["TAB_SEARCH_TYPE_GUILD"] = "公會"
    L["TAB_SEARCH_TYPE_OTHER"] = "未列出"
    L["TAB_SEARCH_INCLUDE_UNLISTED"] = "包含未列出的成就"
    L["TAB_SEARCH_INCLUDE_UNLISTED_TIP"] = "勾選後將包含通常不在成就介面顯示的隱藏成就（如：壯舉、陣營專屬）。"
    L["TAB_SEARCH_SUBMIT"] = "搜尋"
    L["TAB_SEARCH_RESET"] = "重置"
    L["TAB_SEARCH_RESULTS"] = "找到 %d 個成就"
    L["TAB_SEARCH_SEARCHING"] = "搜尋中..."
    L["TAB_SEARCH_EMPTY_TEXT"] = "輸入搜尋條件後點擊搜尋。\n您可以按成就名稱、ID、描述、條件或獎勵進行搜尋。"

    L["TAB_SUGGESTIONS"] = "推薦"
    L["TAB_SUGGESTIONS_DESC"] = "根據目前位置推薦的成就。"
    L["TAB_SUGGESTIONS_RESULTS"] = "找到 %d 條推薦。"
    L["TAB_SUGGESTIONS_EMPTY"] = "目前位置沒有推薦。"
    L["TAB_SUGGESTIONS_LOCATION"] = "目前位置："
    L["TAB_SUGGESTIONS_INCLUDE_COMPLETED"] = "包含已完成的"
    L["TAB_SUGGESTIONS_INCLUDE_COMPLETED_TIP"] = "勾選後顯示所有成就，包括已完成的。取消勾選後僅顯示未完成的成就和條件。"
    L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION"] = "包含其他陣營"
    L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION_TIP"] = "勾選後顯示雙方陣營的成就，無論您目前屬於哪個陣營。取消勾選後僅顯示您所在陣營的成就。"

    L["CTXMENU_LINK_CHAT"] = "連結到聊天"
    L["CTXMENU_LINK_WOWHEAD"] = "Wowhead 連結"
    L["CTXMENU_WATCH_ADD"] = "加入關注列表"
    L["CTXMENU_WATCH_REMOVE"] = "從關注列表移除"
    L["CTXMENU_TRACK"] = "追蹤成就"
    L["CTXMENU_UNTRACK"] = "取消追蹤成就"
end

-- ============================================================================
-- German (deDE)
-- ============================================================================

if locale == "deDE" then
    -- Common
    L["SORT_BY"] = "Sortieren nach:"

    L["TAB_WATCH"] = "Beobachten"
    L["TAB_WATCH_DESC"] = "Sammle Lieblingserfolge in einer persönlichen Beobachtungsliste.\nAlt+Klick auf einen Erfolg, um ihn hinzuzufügen."
    L["TAB_WATCH_REMOVE_ACHIEVEMENT"] = "Erfolg von der Beobachtungsliste entfernen. Auch per Alt+Rechtsklick möglich."

    L["TAB_SEARCH"] = "Suche"
    L["TAB_SEARCH_DESC"] = "Erfolge nach Name, Beschreibung, Kriterien oder Belohnungen suchen."
    L["TAB_SEARCH_NAME"] = "Name/ID:"
    L["TAB_SEARCH_FIELD_DESC"] = "Beschreibung:"
    L["TAB_SEARCH_CRITERIA"] = "Kriterien:"
    L["TAB_SEARCH_REWARD"] = "Belohnung:"
    L["TAB_SEARCH_ANY"] = "Beliebiges Feld:"
    L["TAB_SEARCH_TYPE"] = "Typ:"
    L["TAB_SEARCH_TYPE_ALL"] = "Alle"
    L["TAB_SEARCH_TYPE_PERSONAL"] = "Persönlich"
    L["TAB_SEARCH_TYPE_GUILD"] = "Gilde"
    L["TAB_SEARCH_TYPE_OTHER"] = "Nicht aufgeführt"
    L["TAB_SEARCH_INCLUDE_UNLISTED"] = "Nicht aufgeführte Erfolge einbeziehen"
    L["TAB_SEARCH_INCLUDE_UNLISTED_TIP"] = "Wenn aktiviert, werden versteckte Erfolge (z.B. Ruhmestaten, fraktionsspezifische) einbezogen, die normalerweise nicht in der Erfolgs-UI angezeigt werden."
    L["TAB_SEARCH_SUBMIT"] = "Suchen"
    L["TAB_SEARCH_RESET"] = "Zurücksetzen"
    L["TAB_SEARCH_RESULTS"] = "%d Erfolg(e) gefunden"
    L["TAB_SEARCH_SEARCHING"] = "Suche läuft..."
    L["TAB_SEARCH_EMPTY_TEXT"] = "Geben Sie Suchbegriffe ein und klicken Sie auf Suchen.\nSie können nach Erfolgsname, ID, Beschreibung, Kriterien oder Belohnungen suchen."

    L["TAB_SUGGESTIONS"] = "Vorschläge"
    L["TAB_SUGGESTIONS_DESC"] = "Vorgeschlagene Erfolge basierend auf Ihrem aktuellen Standort."
    L["TAB_SUGGESTIONS_RESULTS"] = "%d Vorschlag/Vorschläge gefunden."
    L["TAB_SUGGESTIONS_EMPTY"] = "Keine Vorschläge für diesen Standort."
    L["TAB_SUGGESTIONS_LOCATION"] = "Aktueller Standort:"
    L["TAB_SUGGESTIONS_INCLUDE_COMPLETED"] = "Abgeschlossene einbeziehen"
    L["TAB_SUGGESTIONS_INCLUDE_COMPLETED_TIP"] = "Wenn aktiviert, werden alle Erfolge einschließlich der bereits abgeschlossenen angezeigt. Wenn deaktiviert, werden nur unvollständige Erfolge und Kriterien angezeigt."
    L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION"] = "Andere Fraktion einbeziehen"
    L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION_TIP"] = "Wenn aktiviert, werden Erfolge beider Fraktionen unabhängig von Ihrer aktuellen Fraktion angezeigt. Wenn deaktiviert, werden nur Erfolge Ihrer Fraktion angezeigt."

    L["CTXMENU_LINK_CHAT"] = "Im Chat verlinken"
    L["CTXMENU_LINK_WOWHEAD"] = "Wowhead-Link"
    L["CTXMENU_WATCH_ADD"] = "Zur Beobachtungsliste hinzufügen"
    L["CTXMENU_WATCH_REMOVE"] = "Von Beobachtungsliste entfernen"
    L["CTXMENU_TRACK"] = "Erfolg verfolgen"
    L["CTXMENU_UNTRACK"] = "Erfolgsverfolgung aufheben"
end

-- ============================================================================
-- French (frFR)
-- ============================================================================

if locale == "frFR" then
    -- Common
    L["SORT_BY"] = "Trier par :"

    L["TAB_WATCH"] = "Suivi"
    L["TAB_WATCH_DESC"] = "Ajoutez vos hauts faits favoris à une liste de suivi personnelle.\nAlt+Clic sur un haut fait pour l'ajouter."
    L["TAB_WATCH_REMOVE_ACHIEVEMENT"] = "Retirer le haut fait de la liste de suivi. Vous pouvez aussi le retirer par Alt+clic droit."

    L["TAB_SEARCH"] = "Recherche"
    L["TAB_SEARCH_DESC"] = "Rechercher des hauts faits par nom, description, critères ou récompenses."
    L["TAB_SEARCH_NAME"] = "Nom/ID :"
    L["TAB_SEARCH_FIELD_DESC"] = "Description :"
    L["TAB_SEARCH_CRITERIA"] = "Critères :"
    L["TAB_SEARCH_REWARD"] = "Récompense :"
    L["TAB_SEARCH_ANY"] = "N'importe quel champ :"
    L["TAB_SEARCH_TYPE"] = "Type :"
    L["TAB_SEARCH_TYPE_ALL"] = "Tous"
    L["TAB_SEARCH_TYPE_PERSONAL"] = "Personnel"
    L["TAB_SEARCH_TYPE_GUILD"] = "Guilde"
    L["TAB_SEARCH_TYPE_OTHER"] = "Non listé"
    L["TAB_SEARCH_INCLUDE_UNLISTED"] = "Inclure les hauts faits non listés"
    L["TAB_SEARCH_INCLUDE_UNLISTED_TIP"] = "Si coché, inclut les hauts faits cachés (par ex. Exploits, spécifiques aux factions) qui ne sont normalement pas affichés dans l'interface des hauts faits."
    L["TAB_SEARCH_SUBMIT"] = "Rechercher"
    L["TAB_SEARCH_RESET"] = "Réinitialiser"
    L["TAB_SEARCH_RESULTS"] = "%d haut(s) fait(s) trouvé(s)"
    L["TAB_SEARCH_SEARCHING"] = "Recherche en cours..."
    L["TAB_SEARCH_EMPTY_TEXT"] = "Entrez des termes de recherche et cliquez sur Rechercher.\nVous pouvez rechercher par nom, ID, description, critères ou récompenses."

    L["TAB_SUGGESTIONS"] = "Suggestions"
    L["TAB_SUGGESTIONS_DESC"] = "Hauts faits suggérés en fonction de votre position actuelle."
    L["TAB_SUGGESTIONS_RESULTS"] = "%d suggestion(s) trouvée(s)."
    L["TAB_SUGGESTIONS_EMPTY"] = "Aucune suggestion pour cette zone."
    L["TAB_SUGGESTIONS_LOCATION"] = "Position actuelle :"
    L["TAB_SUGGESTIONS_INCLUDE_COMPLETED"] = "Inclure les terminés"
    L["TAB_SUGGESTIONS_INCLUDE_COMPLETED_TIP"] = "Si coché, affiche tous les hauts faits, y compris ceux déjà terminés. Si décoché, seuls les hauts faits et critères incomplets sont affichés."
    L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION"] = "Inclure l'autre faction"
    L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION_TIP"] = "Si coché, affiche les hauts faits des deux factions quelle que soit votre faction actuelle. Si décoché, seuls les hauts faits de votre faction sont affichés."

    L["CTXMENU_LINK_CHAT"] = "Lier dans le chat"
    L["CTXMENU_LINK_WOWHEAD"] = "Lien Wowhead"
    L["CTXMENU_WATCH_ADD"] = "Ajouter à la liste de suivi"
    L["CTXMENU_WATCH_REMOVE"] = "Retirer de la liste de suivi"
    L["CTXMENU_TRACK"] = "Suivre le haut fait"
    L["CTXMENU_UNTRACK"] = "Ne plus suivre le haut fait"
end

-- ============================================================================
-- Russian (ruRU)
-- ============================================================================

if locale == "ruRU" then
    -- Common
    L["SORT_BY"] = "Сортировка:"

    L["TAB_WATCH"] = "Избранное"
    L["TAB_WATCH_DESC"] = "Собирайте любимые достижения в персональном списке.\nAlt+Клик по достижению, чтобы добавить его."
    L["TAB_WATCH_REMOVE_ACHIEVEMENT"] = "Убрать достижение из списка. Также можно убрать через Alt+правый клик."

    L["TAB_SEARCH"] = "Поиск"
    L["TAB_SEARCH_DESC"] = "Поиск достижений по имени, описанию, критериям или наградам."
    L["TAB_SEARCH_NAME"] = "Имя/ID:"
    L["TAB_SEARCH_FIELD_DESC"] = "Описание:"
    L["TAB_SEARCH_CRITERIA"] = "Критерии:"
    L["TAB_SEARCH_REWARD"] = "Награда:"
    L["TAB_SEARCH_ANY"] = "Любое поле:"
    L["TAB_SEARCH_TYPE"] = "Тип:"
    L["TAB_SEARCH_TYPE_ALL"] = "Все"
    L["TAB_SEARCH_TYPE_PERSONAL"] = "Личные"
    L["TAB_SEARCH_TYPE_GUILD"] = "Гильдия"
    L["TAB_SEARCH_TYPE_OTHER"] = "Неперечисленные"
    L["TAB_SEARCH_INCLUDE_UNLISTED"] = "Включить неперечисленные достижения"
    L["TAB_SEARCH_INCLUDE_UNLISTED_TIP"] = "Если отмечено, включает скрытые достижения (например, подвиги, специфичные для фракций), которые обычно не отображаются в интерфейсе достижений."
    L["TAB_SEARCH_SUBMIT"] = "Поиск"
    L["TAB_SEARCH_RESET"] = "Сброс"
    L["TAB_SEARCH_RESULTS"] = "Найдено достижений: %d"
    L["TAB_SEARCH_SEARCHING"] = "Поиск..."
    L["TAB_SEARCH_EMPTY_TEXT"] = "Введите условия поиска и нажмите Поиск.\nВы можете искать по имени, ID, описанию, критериям или наградам."

    L["TAB_SUGGESTIONS"] = "Рекомендации"
    L["TAB_SUGGESTIONS_DESC"] = "Рекомендованные достижения на основе вашего текущего местоположения."
    L["TAB_SUGGESTIONS_RESULTS"] = "Найдено рекомендаций: %d."
    L["TAB_SUGGESTIONS_EMPTY"] = "Нет рекомендаций для этого местоположения."
    L["TAB_SUGGESTIONS_LOCATION"] = "Текущее местоположение:"
    L["TAB_SUGGESTIONS_INCLUDE_COMPLETED"] = "Включить завершённые"
    L["TAB_SUGGESTIONS_INCLUDE_COMPLETED_TIP"] = "Если отмечено, показывает все достижения, включая уже завершённые. Если не отмечено, показываются только незавершённые достижения и критерии."
    L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION"] = "Включить другую фракцию"
    L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION_TIP"] = "Если отмечено, показывает достижения обеих фракций независимо от вашей текущей фракции. Если не отмечено, показываются только достижения вашей фракции."

    L["CTXMENU_LINK_CHAT"] = "Ссылка в чат"
    L["CTXMENU_LINK_WOWHEAD"] = "Ссылка на Wowhead"
    L["CTXMENU_WATCH_ADD"] = "Добавить в список наблюдения"
    L["CTXMENU_WATCH_REMOVE"] = "Убрать из списка наблюдения"
    L["CTXMENU_TRACK"] = "Отслеживать достижение"
    L["CTXMENU_UNTRACK"] = "Прекратить отслеживание"
end

-- ============================================================================
-- Spanish (esES / esMX)
-- ============================================================================

if locale == "esES" or locale == "esMX" then
    -- Common
    L["SORT_BY"] = "Ordenar por:"

    L["TAB_WATCH"] = "Seguimiento"
    L["TAB_WATCH_DESC"] = "Recopila logros favoritos en una lista de seguimiento personal.\nAlt+Clic en cualquier logro para añadirlo."
    L["TAB_WATCH_REMOVE_ACHIEVEMENT"] = "Eliminar logro de la lista de seguimiento. También puedes eliminarlo con Alt+clic derecho."

    L["TAB_SEARCH"] = "Búsqueda"
    L["TAB_SEARCH_DESC"] = "Buscar logros por nombre, descripción, criterios o recompensas."
    L["TAB_SEARCH_NAME"] = "Nombre/ID:"
    L["TAB_SEARCH_FIELD_DESC"] = "Descripción:"
    L["TAB_SEARCH_CRITERIA"] = "Criterios:"
    L["TAB_SEARCH_REWARD"] = "Recompensa:"
    L["TAB_SEARCH_ANY"] = "Cualquier campo:"
    L["TAB_SEARCH_TYPE"] = "Tipo:"
    L["TAB_SEARCH_TYPE_ALL"] = "Todos"
    L["TAB_SEARCH_TYPE_PERSONAL"] = "Personal"
    L["TAB_SEARCH_TYPE_GUILD"] = "Hermandad"
    L["TAB_SEARCH_TYPE_OTHER"] = "No listados"
    L["TAB_SEARCH_INCLUDE_UNLISTED"] = "Incluir logros no listados"
    L["TAB_SEARCH_INCLUDE_UNLISTED_TIP"] = "Si está marcado, incluye logros ocultos (por ejemplo, Proezas, específicos de facción) que normalmente no se muestran en la interfaz de logros."
    L["TAB_SEARCH_SUBMIT"] = "Buscar"
    L["TAB_SEARCH_RESET"] = "Restablecer"
    L["TAB_SEARCH_RESULTS"] = "Se encontraron %d logro(s)"
    L["TAB_SEARCH_SEARCHING"] = "Buscando..."
    L["TAB_SEARCH_EMPTY_TEXT"] = "Ingresa términos de búsqueda y haz clic en Buscar.\nPuedes buscar por nombre, ID, descripción, criterios o recompensas de logros."

    L["TAB_SUGGESTIONS"] = "Sugerencias"
    L["TAB_SUGGESTIONS_DESC"] = "Logros sugeridos según tu ubicación actual."
    L["TAB_SUGGESTIONS_RESULTS"] = "%d sugerencia(s) encontrada(s)."
    L["TAB_SUGGESTIONS_EMPTY"] = "No hay sugerencias para esta ubicación."
    L["TAB_SUGGESTIONS_LOCATION"] = "Ubicación actual:"
    L["TAB_SUGGESTIONS_INCLUDE_COMPLETED"] = "Incluir completados"
    L["TAB_SUGGESTIONS_INCLUDE_COMPLETED_TIP"] = "Si está marcado, muestra todos los logros, incluidos los ya completados. Si no está marcado, solo se muestran los logros y criterios incompletos."
    L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION"] = "Incluir otra facción"
    L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION_TIP"] = "Si está marcado, muestra logros de ambas facciones sin importar tu facción actual. Si no está marcado, solo se muestran los logros de tu facción."

    L["CTXMENU_LINK_CHAT"] = "Enlazar en el chat"
    L["CTXMENU_LINK_WOWHEAD"] = "Enlace de Wowhead"
    L["CTXMENU_WATCH_ADD"] = "Añadir a lista de seguimiento"
    L["CTXMENU_WATCH_REMOVE"] = "Quitar de lista de seguimiento"
    L["CTXMENU_TRACK"] = "Seguir logro"
    L["CTXMENU_UNTRACK"] = "Dejar de seguir logro"
end
