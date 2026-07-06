-- Overachiever2: Localization
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

L["CORE_INIT"] = "Initialization complete."
L["DEBUG_ENABLED"] = "Debug mode enabled."
L["DEBUG_DISABLED"] = "Debug mode disabled."
L["OPTIONS"] = "Options"

L["SLASH_CMD_HELP"] = "Overachiever2 Commands:"
L["SLASH_CMD_DEBUG"] = "/oa debug: Toggle debug mode (Tooltip ID display)."
L["SLASH_CMD_SEARCH"] = "/oa search <query>: Search achievements by name or ID (for debug)."

-- Tooltip feature
L["OPT_DEBUG_TITLE"] = "Tooltip ID Display (Debug Mode)"
L["OPT_DEBUG_DESC"] = "Show NPC, Item, and Achievement IDs in tooltips."

L["OPT_NPC_TOOLTIP_TITLE"] = "Enable NPC tooltip"
L["OPT_NPC_TOOLTIP_DESC"] = "Show achievement progress lines when hovering over NPCs."

L["OPT_ITEM_TOOLTIP_TITLE"] = "Enable item tooltip"
L["OPT_ITEM_TOOLTIP_DESC"] = "Show achievement progress lines when hovering over items."

L["OPT_ACH_TOOLTIP_TITLE"] = "Enable achievement tooltip"
L["OPT_ACH_TOOLTIP_DESC"] = "Show enhanced achievement tooltips with additional details."

L["OPT_ACH_WINDOW_TOOLTIP_TITLE"] = "Achievement Window"
L["OPT_ACH_WINDOW_TOOLTIP_DESC"] = "Show an enhanced tooltip when hovering over achievements in the Achievement Window."

L["OPT_CHAT_HOVER_TOOLTIP_TITLE"] = "Chat Links (Hover)"
L["OPT_CHAT_HOVER_TOOLTIP_DESC"] = "Show an enhanced tooltip when hovering over achievement links in chat."

L["OPT_CHAT_CLICK_TOOLTIP_TITLE"] = "Chat Links (Click)"
L["OPT_CHAT_CLICK_TOOLTIP_DESC"] = "Show an enhanced tooltip when clicking achievement links in chat."

L["OPT_CHAT_MIDDLE_CLICK_OPEN_TITLE"] = "Middle-click chat link opens Achievement UI"
L["OPT_CHAT_MIDDLE_CLICK_OPEN_DESC"] = "Middle-clicking an achievement link in chat opens the Achievement window and selects that achievement."

L["OPT_TRACKED_TOOLTIP_TITLE"] = "Tracked Achievements"
L["OPT_TRACKED_TOOLTIP_DESC"] = "Show an enhanced tooltip when hovering over tracked achievements in the Objective Tracker."

L["OPT_ANCHOR_TITLE"] = "Anchor"
L["OPT_ANCHOR_DESC"] = "Choose where the tooltip appears: anchored to the left, right, or following the cursor."
L["OPT_ANCHOR_LEFT"] = "Left"
L["OPT_ANCHOR_CURSOR"] = "Cursor"
L["OPT_ANCHOR_RIGHT"] = "Right"

L["SERIESTIP"] = "Part of a series"
L["META_ACHIEVEMENT"] = "Meta-achievement"

-- SessionState feature
L["OPT_SESSION_STATE_TITLE"] = "Restore last view"
L["OPT_SESSION_STATE_DESC"] = "Remember the selected tab, category, and achievement in the Achievement window, and restore them across game sessions.\n(Saved per character.)"

-- History feature
L["OPT_HISTORY_TITLE"] = "Enable history navigation"
L["OPT_HISTORY_DESC"] = "Track viewed achievements and navigate back/forward through your browsing history.\nBack/Forward buttons appear next to the achievement points display."
L["OPT_HISTORY_MAX_TITLE"] = "History size"
L["OPT_HISTORY_MAX_DESC"] = "Maximum number of entries to keep in the browsing history."
L["OPT_HISTORY_PERSIST_TITLE"] = "Persist across sessions"
L["OPT_HISTORY_PERSIST_DESC"] = "Save the browsing history when you log out, so it's available next time you log in.\n(Saved per character.)"
L["OPT_HISTORY_BACK_KEY_TITLE"] = "History: Back"
L["OPT_HISTORY_FORWARD_KEY_TITLE"] = "History: Forward"
L["HISTORY_HELP_TITLE"] = "History"
L["HISTORY_HELP_DESC"] = "Track viewed achievements and navigate back/forward through your browsing history.\n\nShortcuts\n- Back: %s\n- Forward: %s\n\nYou can change these in Overachiever2's options or the game's Key Bindings options."
L["HISTORY_TIP_RIGHTCLICK"] = "Right-click for history list"
L["HISTORY_CLEARED"] = "History cleared."
L["HISTORY_EMPTY"] = "History is empty."
L["HISTORY_STATUS"] = "History: %d entries, position %d."
L["SLASH_CMD_HISTORY"] = "/oa history: Show current history status."
L["SLASH_CMD_HISTORY_CLEAR"] = "/oa history clear: Clear the browsing history."
L["SLASH_CMD_HISTORY_BACK"] = "/oa history back: Navigate back."
L["SLASH_CMD_HISTORY_FORWARD"] = "/oa history forward: Navigate forward."

-- Keybindings (globals for WoW Key Bindings UI)
BINDING_HEADER_OVERACHIEVER2 = "Overachiever2"  -- addon name; kept as-is across all locales to preserve brand identity
BINDING_NAME_OA2_KB_HISTORY_BACK = "History: Back"
BINDING_NAME_OA2_KB_HISTORY_FORWARD = "History: Forward"


local locale = GetLocale()

-- ============================================================================
-- Korean (koKR)
-- ============================================================================

if locale == "koKR" then
    L["CORE_INIT"] = "초기화가 완료되었습니다."
    L["DEBUG_ENABLED"] = "디버그 모드가 활성화되었습니다."
    L["DEBUG_DISABLED"] = "디버그 모드가 비활성화되었습니다."
    L["OPTIONS"] = "옵션"

    L["SLASH_CMD_HELP"] = "Overachiever2 명령어:"
    L["SLASH_CMD_DEBUG"] = "/oa debug: 디버그 모드(툴팁 ID 표시)를 켜거나 끕니다."
    L["SLASH_CMD_SEARCH"] = "/oa search <검색어>: 이름 또는 ID로 업적을 검색합니다 (디버그용)."

    -- Tooltip feature
    L["OPT_DEBUG_TITLE"] = "툴팁 ID 표시 (디버그 모드)"
    L["OPT_DEBUG_DESC"] = "NPC, 아이템, 업적 ID를 툴팁에 추가로 표시합니다."

    L["OPT_NPC_TOOLTIP_TITLE"] = "NPC 툴팁 활성화"
    L["OPT_NPC_TOOLTIP_DESC"] = "NPC에 마우스를 올렸을 때 업적 진행 상황을 표시합니다."

    L["OPT_ITEM_TOOLTIP_TITLE"] = "아이템 툴팁 활성화"
    L["OPT_ITEM_TOOLTIP_DESC"] = "아이템에 마우스를 올렸을 때 업적 진행 상황을 표시합니다."

    L["OPT_ACH_TOOLTIP_TITLE"] = "업적 툴팁 활성화"
    L["OPT_ACH_TOOLTIP_DESC"] = "추가 정보가 포함된 향상된 업적 툴팁을 표시합니다."

    L["OPT_ACH_WINDOW_TOOLTIP_TITLE"] = "업적 창"
    L["OPT_ACH_WINDOW_TOOLTIP_DESC"] = "업적 창에서 업적 항목에 마우스를 올렸을 때 향상된 툴팁을 표시합니다."

    L["OPT_CHAT_HOVER_TOOLTIP_TITLE"] = "채팅 링크 (마우스 오버)"
    L["OPT_CHAT_HOVER_TOOLTIP_DESC"] = "채팅에서 업적 링크에 마우스를 올렸을 때 향상된 툴팁을 표시합니다."

    L["OPT_CHAT_CLICK_TOOLTIP_TITLE"] = "채팅 링크 (클릭)"
    L["OPT_CHAT_CLICK_TOOLTIP_DESC"] = "채팅에서 업적 링크를 클릭했을 때 향상된 툴팁을 표시합니다."

    L["OPT_CHAT_MIDDLE_CLICK_OPEN_TITLE"] = "채팅 링크 가운데 클릭으로 업적 창 열기"
    L["OPT_CHAT_MIDDLE_CLICK_OPEN_DESC"] = "채팅에서 업적 링크를 마우스 가운데 버튼으로 클릭하면 업적 창을 열고 해당 업적을 선택합니다."

    L["OPT_TRACKED_TOOLTIP_TITLE"] = "추적 중인 업적"
    L["OPT_TRACKED_TOOLTIP_DESC"] = "목표 추적기에서 추적 중인 업적에 마우스를 올렸을 때 향상된 툴팁을 표시합니다."

    L["OPT_ANCHOR_TITLE"] = "고정 위치"
    L["OPT_ANCHOR_DESC"] = "툴팁 표시 위치를 선택합니다: 왼쪽, 오른쪽, 또는 커서를 따라갑니다."
    L["OPT_ANCHOR_LEFT"] = "왼쪽"
    L["OPT_ANCHOR_CURSOR"] = "커서"
    L["OPT_ANCHOR_RIGHT"] = "오른쪽"

    L["SERIESTIP"] = "업적 세트"
    L["META_ACHIEVEMENT"] = "상위 업적"

    -- SessionState feature
    L["OPT_SESSION_STATE_TITLE"] = "마지막 보기 복원"
    L["OPT_SESSION_STATE_DESC"] = "업적 창에서 선택한 탭, 카테고리, 업적을 기억하고 게임 세션 간에 복원합니다.\n(캐릭터별로 저장됩니다.)"

    -- History feature
    L["OPT_HISTORY_TITLE"] = "히스토리 탐색 활성화"
    L["OPT_HISTORY_DESC"] = "열람한 업적을 추적하고 탐색 기록을 앞/뒤로 이동할 수 있습니다.\n앞/뒤로 버튼이 업적 점수 표시 옆에 나타납니다."
    L["OPT_HISTORY_MAX_TITLE"] = "히스토리 크기"
    L["OPT_HISTORY_MAX_DESC"] = "탐색 기록에 보관할 최대 항목 수입니다."
    L["OPT_HISTORY_PERSIST_TITLE"] = "세션 간 유지"
    L["OPT_HISTORY_PERSIST_DESC"] = "로그아웃할 때 탐색 기록을 저장하여 다음 접속 시에도 사용할 수 있습니다.\n(캐릭터별로 저장됩니다.)"
    L["OPT_HISTORY_BACK_KEY_TITLE"] = "히스토리: 뒤로"
    L["OPT_HISTORY_FORWARD_KEY_TITLE"] = "히스토리: 앞으로"
    L["HISTORY_HELP_TITLE"] = "히스토리"
    L["HISTORY_HELP_DESC"] = "열람한 업적을 추적하고 탐색 기록을 앞/뒤로 이동할 수 있습니다.\n\n단축키\n- 뒤로: %s\n- 앞으로: %s\n\nOverachiever2 옵션이나 게임의 단축키 설정에서 변경할 수 있습니다."
    L["HISTORY_TIP_RIGHTCLICK"] = "오른쪽 클릭으로 히스토리 목록 보기"
    L["HISTORY_CLEARED"] = "히스토리가 초기화되었습니다."
    L["HISTORY_EMPTY"] = "히스토리가 비어 있습니다."
    L["HISTORY_STATUS"] = "히스토리: %d개 항목, 위치 %d."
    L["SLASH_CMD_HISTORY"] = "/oa history: 현재 히스토리 상태를 표시합니다."
    L["SLASH_CMD_HISTORY_CLEAR"] = "/oa history clear: 탐색 기록을 초기화합니다."
    L["SLASH_CMD_HISTORY_BACK"] = "/oa history back: 뒤로 이동합니다."
    L["SLASH_CMD_HISTORY_FORWARD"] = "/oa history forward: 앞으로 이동합니다."
    BINDING_NAME_OA2_KB_HISTORY_BACK = "히스토리: 뒤로"
    BINDING_NAME_OA2_KB_HISTORY_FORWARD = "히스토리: 앞으로"
end

-- ============================================================================
-- Simplified Chinese (zhCN)
-- ============================================================================

if locale == "zhCN" then
    L["CORE_INIT"] = "初始化完成。"
    L["DEBUG_ENABLED"] = "调试模式已启用。"
    L["DEBUG_DISABLED"] = "调试模式已禁用。"
    L["OPTIONS"] = "选项"

    L["SLASH_CMD_HELP"] = "Overachiever2 命令："
    L["SLASH_CMD_DEBUG"] = "/oa debug：切换调试模式（显示提示信息ID）。"
    L["SLASH_CMD_SEARCH"] = "/oa search <查询>：按名称或ID搜索成就（用于调试）。"

    -- Tooltip feature
    L["OPT_DEBUG_TITLE"] = "显示提示信息ID（调试模式）"
    L["OPT_DEBUG_DESC"] = "在提示信息中显示NPC、物品与成就的ID。"

    L["OPT_NPC_TOOLTIP_TITLE"] = "启用NPC提示信息"
    L["OPT_NPC_TOOLTIP_DESC"] = "鼠标悬停在NPC上时显示成就进度。"

    L["OPT_ITEM_TOOLTIP_TITLE"] = "启用物品提示信息"
    L["OPT_ITEM_TOOLTIP_DESC"] = "鼠标悬停在物品上时显示成就进度。"

    L["OPT_ACH_TOOLTIP_TITLE"] = "启用成就提示信息"
    L["OPT_ACH_TOOLTIP_DESC"] = "显示包含额外详情的增强成就提示信息。"

    L["OPT_ACH_WINDOW_TOOLTIP_TITLE"] = "成就窗口"
    L["OPT_ACH_WINDOW_TOOLTIP_DESC"] = "鼠标悬停在成就窗口中的成就上时显示增强提示信息。"

    L["OPT_CHAT_HOVER_TOOLTIP_TITLE"] = "聊天链接（悬停）"
    L["OPT_CHAT_HOVER_TOOLTIP_DESC"] = "鼠标悬停在聊天中的成就链接上时显示增强提示信息。"

    L["OPT_CHAT_CLICK_TOOLTIP_TITLE"] = "聊天链接（点击）"
    L["OPT_CHAT_CLICK_TOOLTIP_DESC"] = "点击聊天中的成就链接时显示增强提示信息。"

    L["OPT_CHAT_MIDDLE_CLICK_OPEN_TITLE"] = "中键点击聊天链接打开成就窗口"
    L["OPT_CHAT_MIDDLE_CLICK_OPEN_DESC"] = "用鼠标中键点击聊天中的成就链接时，打开成就窗口并选中该成就。"

    L["OPT_TRACKED_TOOLTIP_TITLE"] = "追踪中的成就"
    L["OPT_TRACKED_TOOLTIP_DESC"] = "鼠标悬停在目标追踪器中追踪的成就上时显示增强提示信息。"

    L["OPT_ANCHOR_TITLE"] = "锚点"
    L["OPT_ANCHOR_DESC"] = "选择提示信息的显示位置：锚定在左侧、右侧，或跟随光标。"
    L["OPT_ANCHOR_LEFT"] = "左侧"
    L["OPT_ANCHOR_CURSOR"] = "光标"
    L["OPT_ANCHOR_RIGHT"] = "右侧"

    L["SERIESTIP"] = "系列成就的一部分"
    L["META_ACHIEVEMENT"] = "综合成就"

    -- SessionState feature
    L["OPT_SESSION_STATE_TITLE"] = "恢复上次视图"
    L["OPT_SESSION_STATE_DESC"] = "记住成就窗口中选定的标签页、分类和成就，并在游戏会话间恢复。\n(按角色保存。)"

    -- History feature
    L["OPT_HISTORY_TITLE"] = "启用历史导航"
    L["OPT_HISTORY_DESC"] = "追踪已浏览的成就，并在浏览历史中前后导航。\n前进/后退按钮显示在成就点数旁边。"
    L["OPT_HISTORY_MAX_TITLE"] = "历史记录大小"
    L["OPT_HISTORY_MAX_DESC"] = "浏览历史中保留的最大条目数。"
    L["OPT_HISTORY_PERSIST_TITLE"] = "跨会话保留"
    L["OPT_HISTORY_PERSIST_DESC"] = "登出时保存浏览历史，以便下次登录时使用。\n(按角色保存。)"
    L["OPT_HISTORY_BACK_KEY_TITLE"] = "历史：后退"
    L["OPT_HISTORY_FORWARD_KEY_TITLE"] = "历史：前进"
    L["HISTORY_HELP_TITLE"] = "历史"
    L["HISTORY_HELP_DESC"] = "追踪已浏览的成就，并在浏览历史中前后导航。\n\n快捷键\n- 后退：%s\n- 前进：%s\n\n可在 Overachiever2 选项或游戏的按键设置中更改。"
    L["HISTORY_TIP_RIGHTCLICK"] = "右键单击查看历史列表"
    L["HISTORY_CLEARED"] = "历史记录已清除。"
    L["HISTORY_EMPTY"] = "历史记录为空。"
    L["HISTORY_STATUS"] = "历史：%d 条记录，位置 %d。"
    L["SLASH_CMD_HISTORY"] = "/oa history：显示当前历史状态。"
    L["SLASH_CMD_HISTORY_CLEAR"] = "/oa history clear：清除浏览历史。"
    L["SLASH_CMD_HISTORY_BACK"] = "/oa history back：后退。"
    L["SLASH_CMD_HISTORY_FORWARD"] = "/oa history forward：前进。"
    BINDING_NAME_OA2_KB_HISTORY_BACK = "历史：后退"
    BINDING_NAME_OA2_KB_HISTORY_FORWARD = "历史：前进"
end

-- ============================================================================
-- Traditional Chinese (zhTW)
-- ============================================================================

if locale == "zhTW" then
    L["CORE_INIT"] = "初始化完成。"
    L["DEBUG_ENABLED"] = "除錯模式已啟用。"
    L["DEBUG_DISABLED"] = "除錯模式已停用。"
    L["OPTIONS"] = "選項"

    L["SLASH_CMD_HELP"] = "Overachiever2 指令："
    L["SLASH_CMD_DEBUG"] = "/oa debug：切換除錯模式（顯示提示資訊ID）。"
    L["SLASH_CMD_SEARCH"] = "/oa search <查詢>：按名稱或ID搜尋成就（用於除錯）。"

    -- Tooltip feature
    L["OPT_DEBUG_TITLE"] = "顯示提示資訊ID（除錯模式）"
    L["OPT_DEBUG_DESC"] = "在提示資訊中顯示NPC、物品與成就的ID。"

    L["OPT_NPC_TOOLTIP_TITLE"] = "啟用NPC提示資訊"
    L["OPT_NPC_TOOLTIP_DESC"] = "滑鼠懸停在NPC上時顯示成就進度。"

    L["OPT_ITEM_TOOLTIP_TITLE"] = "啟用物品提示資訊"
    L["OPT_ITEM_TOOLTIP_DESC"] = "滑鼠懸停在物品上時顯示成就進度。"

    L["OPT_ACH_TOOLTIP_TITLE"] = "啟用成就提示資訊"
    L["OPT_ACH_TOOLTIP_DESC"] = "顯示包含額外詳情的增強成就提示資訊。"

    L["OPT_ACH_WINDOW_TOOLTIP_TITLE"] = "成就視窗"
    L["OPT_ACH_WINDOW_TOOLTIP_DESC"] = "滑鼠懸停在成就視窗中的成就上時顯示增強提示資訊。"

    L["OPT_CHAT_HOVER_TOOLTIP_TITLE"] = "聊天連結（懸停）"
    L["OPT_CHAT_HOVER_TOOLTIP_DESC"] = "滑鼠懸停在聊天中的成就連結上時顯示增強提示資訊。"

    L["OPT_CHAT_CLICK_TOOLTIP_TITLE"] = "聊天連結（點擊）"
    L["OPT_CHAT_CLICK_TOOLTIP_DESC"] = "點擊聊天中的成就連結時顯示增強提示資訊。"

    L["OPT_CHAT_MIDDLE_CLICK_OPEN_TITLE"] = "中鍵點擊聊天連結開啟成就視窗"
    L["OPT_CHAT_MIDDLE_CLICK_OPEN_DESC"] = "用滑鼠中鍵點擊聊天中的成就連結時，開啟成就視窗並選取該成就。"

    L["OPT_TRACKED_TOOLTIP_TITLE"] = "追蹤中的成就"
    L["OPT_TRACKED_TOOLTIP_DESC"] = "滑鼠懸停在目標追蹤器中追蹤的成就上時顯示增強提示資訊。"

    L["OPT_ANCHOR_TITLE"] = "錨點"
    L["OPT_ANCHOR_DESC"] = "選擇提示資訊的顯示位置：錨定在左側、右側，或跟隨游標。"
    L["OPT_ANCHOR_LEFT"] = "左側"
    L["OPT_ANCHOR_CURSOR"] = "游標"
    L["OPT_ANCHOR_RIGHT"] = "右側"

    L["SERIESTIP"] = "系列成就的一部分"
    L["META_ACHIEVEMENT"] = "綜合成就"

    -- SessionState feature
    L["OPT_SESSION_STATE_TITLE"] = "恢復上次檢視"
    L["OPT_SESSION_STATE_DESC"] = "記住成就視窗中選定的分頁、分類和成就，並在遊戲工作階段間恢復。\n(按角色儲存。)"

    -- History feature
    L["OPT_HISTORY_TITLE"] = "啟用歷史導覽"
    L["OPT_HISTORY_DESC"] = "追蹤已瀏覽的成就，並在瀏覽歷史中前後導覽。\n前進/後退按鈕顯示在成就點數旁邊。"
    L["OPT_HISTORY_MAX_TITLE"] = "歷史記錄大小"
    L["OPT_HISTORY_MAX_DESC"] = "瀏覽歷史中保留的最大項目數。"
    L["OPT_HISTORY_PERSIST_TITLE"] = "跨工作階段保留"
    L["OPT_HISTORY_PERSIST_DESC"] = "登出時儲存瀏覽歷史，以便下次登入時使用。\n(按角色儲存。)"
    L["OPT_HISTORY_BACK_KEY_TITLE"] = "歷史：後退"
    L["OPT_HISTORY_FORWARD_KEY_TITLE"] = "歷史：前進"
    L["HISTORY_HELP_TITLE"] = "歷史"
    L["HISTORY_HELP_DESC"] = "追蹤已瀏覽的成就，並在瀏覽歷史中前後導覽。\n\n快捷鍵\n- 後退：%s\n- 前進：%s\n\n可在 Overachiever2 選項或遊戲的按鍵設定中變更。"
    L["HISTORY_TIP_RIGHTCLICK"] = "右鍵點擊檢視歷史清單"
    L["HISTORY_CLEARED"] = "歷史記錄已清除。"
    L["HISTORY_EMPTY"] = "歷史記錄為空。"
    L["HISTORY_STATUS"] = "歷史：%d 筆記錄，位置 %d。"
    L["SLASH_CMD_HISTORY"] = "/oa history：顯示目前歷史狀態。"
    L["SLASH_CMD_HISTORY_CLEAR"] = "/oa history clear：清除瀏覽歷史。"
    L["SLASH_CMD_HISTORY_BACK"] = "/oa history back：後退。"
    L["SLASH_CMD_HISTORY_FORWARD"] = "/oa history forward：前進。"
    BINDING_NAME_OA2_KB_HISTORY_BACK = "歷史：後退"
    BINDING_NAME_OA2_KB_HISTORY_FORWARD = "歷史：前進"
end

-- ============================================================================
-- German (deDE)
-- ============================================================================

if locale == "deDE" then
    L["CORE_INIT"] = "Initialisierung abgeschlossen."
    L["DEBUG_ENABLED"] = "Debug-Modus aktiviert."
    L["DEBUG_DISABLED"] = "Debug-Modus deaktiviert."
    L["OPTIONS"] = "Optionen"

    L["SLASH_CMD_HELP"] = "Overachiever2-Befehle:"
    L["SLASH_CMD_DEBUG"] = "/oa debug: Debug-Modus umschalten (Tooltip-ID-Anzeige)."
    L["SLASH_CMD_SEARCH"] = "/oa search <Suchbegriff>: Erfolge nach Name oder ID suchen (für Debugging)."

    -- Tooltip feature
    L["OPT_DEBUG_TITLE"] = "Tooltip-ID-Anzeige (Debug-Modus)"
    L["OPT_DEBUG_DESC"] = "NPC-, Gegenstands- und Erfolgs-IDs in Tooltips anzeigen."

    L["OPT_NPC_TOOLTIP_TITLE"] = "NPC-Tooltip aktivieren"
    L["OPT_NPC_TOOLTIP_DESC"] = "Erfolgsfortschritt anzeigen, wenn die Maus über einen NPC bewegt wird."

    L["OPT_ITEM_TOOLTIP_TITLE"] = "Gegenstand-Tooltip aktivieren"
    L["OPT_ITEM_TOOLTIP_DESC"] = "Erfolgsfortschritt anzeigen, wenn die Maus über einen Gegenstand bewegt wird."

    L["OPT_ACH_TOOLTIP_TITLE"] = "Erfolgs-Tooltip aktivieren"
    L["OPT_ACH_TOOLTIP_DESC"] = "Erweiterte Erfolgs-Tooltips mit zusätzlichen Details anzeigen."

    L["OPT_ACH_WINDOW_TOOLTIP_TITLE"] = "Erfolgsfenster"
    L["OPT_ACH_WINDOW_TOOLTIP_DESC"] = "Erweiterten Tooltip anzeigen, wenn die Maus über Erfolge im Erfolgsfenster bewegt wird."

    L["OPT_CHAT_HOVER_TOOLTIP_TITLE"] = "Chat-Links (Hover)"
    L["OPT_CHAT_HOVER_TOOLTIP_DESC"] = "Erweiterten Tooltip anzeigen, wenn die Maus über Erfolgslinks im Chat bewegt wird."

    L["OPT_CHAT_CLICK_TOOLTIP_TITLE"] = "Chat-Links (Klick)"
    L["OPT_CHAT_CLICK_TOOLTIP_DESC"] = "Erweiterten Tooltip anzeigen, wenn auf Erfolgslinks im Chat geklickt wird."

    L["OPT_CHAT_MIDDLE_CLICK_OPEN_TITLE"] = "Mittelklick auf Chat-Link öffnet Erfolgsfenster"
    L["OPT_CHAT_MIDDLE_CLICK_OPEN_DESC"] = "Beim Mittelklick auf einen Erfolgslink im Chat wird das Erfolgsfenster geöffnet und der Erfolg ausgewählt."

    L["OPT_TRACKED_TOOLTIP_TITLE"] = "Verfolgte Erfolge"
    L["OPT_TRACKED_TOOLTIP_DESC"] = "Erweiterten Tooltip anzeigen, wenn die Maus über verfolgte Erfolge im Zielverfolgungsfenster bewegt wird."

    L["OPT_ANCHOR_TITLE"] = "Verankerung"
    L["OPT_ANCHOR_DESC"] = "Wähle, wo der Tooltip erscheint: links, rechts verankert oder dem Cursor folgend."
    L["OPT_ANCHOR_LEFT"] = "Links"
    L["OPT_ANCHOR_CURSOR"] = "Cursor"
    L["OPT_ANCHOR_RIGHT"] = "Rechts"

    L["SERIESTIP"] = "Teil einer Serie"
    L["META_ACHIEVEMENT"] = "Meta-Erfolg"

    -- SessionState feature
    L["OPT_SESSION_STATE_TITLE"] = "Letzte Ansicht wiederherstellen"
    L["OPT_SESSION_STATE_DESC"] = "Ausgewählten Tab, Kategorie und Erfolg im Erfolgsfenster merken und über Spielsitzungen hinweg wiederherstellen.\n(Pro Charakter gespeichert.)"

    -- History feature
    L["OPT_HISTORY_TITLE"] = "Verlaufsnavigation aktivieren"
    L["OPT_HISTORY_DESC"] = "Angesehene Erfolge verfolgen und im Browserverlauf vor- und zurücknavigieren.\nVor-/Zurück-Schaltflächen erscheinen neben der Erfolgspunkteanzeige."
    L["OPT_HISTORY_MAX_TITLE"] = "Verlaufsgröße"
    L["OPT_HISTORY_MAX_DESC"] = "Maximale Anzahl an Einträgen im Browserverlauf."
    L["OPT_HISTORY_PERSIST_TITLE"] = "Sitzungsübergreifend speichern"
    L["OPT_HISTORY_PERSIST_DESC"] = "Den Browserverlauf beim Ausloggen speichern, damit er beim nächsten Einloggen verfügbar ist.\n(Pro Charakter gespeichert.)"
    L["OPT_HISTORY_BACK_KEY_TITLE"] = "Verlauf: Zurück"
    L["OPT_HISTORY_FORWARD_KEY_TITLE"] = "Verlauf: Vorwärts"
    L["HISTORY_HELP_TITLE"] = "Verlauf"
    L["HISTORY_HELP_DESC"] = "Angesehene Erfolge verfolgen und im Browserverlauf vor- und zurücknavigieren.\n\nTastenkürzel\n- Zurück: %s\n- Vorwärts: %s\n\nDiese können in den Optionen von Overachiever2 oder in den Tastaturbelegungen des Spiels geändert werden."
    L["HISTORY_TIP_RIGHTCLICK"] = "Rechtsklick für Verlaufsliste"
    L["HISTORY_CLEARED"] = "Verlauf gelöscht."
    L["HISTORY_EMPTY"] = "Verlauf ist leer."
    L["HISTORY_STATUS"] = "Verlauf: %d Einträge, Position %d."
    L["SLASH_CMD_HISTORY"] = "/oa history: Aktuellen Verlaufsstatus anzeigen."
    L["SLASH_CMD_HISTORY_CLEAR"] = "/oa history clear: Browserverlauf löschen."
    L["SLASH_CMD_HISTORY_BACK"] = "/oa history back: Zurück navigieren."
    L["SLASH_CMD_HISTORY_FORWARD"] = "/oa history forward: Vorwärts navigieren."
    BINDING_NAME_OA2_KB_HISTORY_BACK = "Verlauf: Zurück"
    BINDING_NAME_OA2_KB_HISTORY_FORWARD = "Verlauf: Vorwärts"
end

-- ============================================================================
-- French (frFR)
-- ============================================================================

if locale == "frFR" then
    L["CORE_INIT"] = "Initialisation terminée."
    L["DEBUG_ENABLED"] = "Mode débogage activé."
    L["DEBUG_DISABLED"] = "Mode débogage désactivé."
    L["OPTIONS"] = "Options"

    L["SLASH_CMD_HELP"] = "Commandes Overachiever2 :"
    L["SLASH_CMD_DEBUG"] = "/oa debug : Activer/désactiver le mode débogage (affichage des ID dans les infobulles)."
    L["SLASH_CMD_SEARCH"] = "/oa search <requête> : Rechercher des hauts faits par nom ou ID (pour débogage)."

    -- Tooltip feature
    L["OPT_DEBUG_TITLE"] = "Affichage des ID dans les infobulles (Mode débogage)"
    L["OPT_DEBUG_DESC"] = "Afficher les ID des PNJ, objets et hauts faits dans les infobulles."

    L["OPT_NPC_TOOLTIP_TITLE"] = "Activer l'infobulle PNJ"
    L["OPT_NPC_TOOLTIP_DESC"] = "Afficher la progression des hauts faits au survol des PNJ."

    L["OPT_ITEM_TOOLTIP_TITLE"] = "Activer l'infobulle d'objet"
    L["OPT_ITEM_TOOLTIP_DESC"] = "Afficher la progression des hauts faits au survol des objets."

    L["OPT_ACH_TOOLTIP_TITLE"] = "Activer l'infobulle de haut fait"
    L["OPT_ACH_TOOLTIP_DESC"] = "Afficher des infobulles de hauts faits améliorées avec des détails supplémentaires."

    L["OPT_ACH_WINDOW_TOOLTIP_TITLE"] = "Fenêtre des hauts faits"
    L["OPT_ACH_WINDOW_TOOLTIP_DESC"] = "Afficher une infobulle améliorée au survol des hauts faits dans la fenêtre des hauts faits."

    L["OPT_CHAT_HOVER_TOOLTIP_TITLE"] = "Liens de discussion (Survol)"
    L["OPT_CHAT_HOVER_TOOLTIP_DESC"] = "Afficher une infobulle améliorée au survol des liens de hauts faits dans le chat."

    L["OPT_CHAT_CLICK_TOOLTIP_TITLE"] = "Liens de discussion (Clic)"
    L["OPT_CHAT_CLICK_TOOLTIP_DESC"] = "Afficher une infobulle améliorée en cliquant sur les liens de hauts faits dans le chat."

    L["OPT_CHAT_MIDDLE_CLICK_OPEN_TITLE"] = "Clic milieu sur un lien de chat ouvre la fenêtre des hauts faits"
    L["OPT_CHAT_MIDDLE_CLICK_OPEN_DESC"] = "Le clic milieu sur un lien de haut fait dans le chat ouvre la fenêtre des hauts faits et sélectionne ce haut fait."

    L["OPT_TRACKED_TOOLTIP_TITLE"] = "Hauts faits suivis"
    L["OPT_TRACKED_TOOLTIP_DESC"] = "Afficher une infobulle améliorée au survol des hauts faits suivis dans le suivi des objectifs."

    L["OPT_ANCHOR_TITLE"] = "Ancrage"
    L["OPT_ANCHOR_DESC"] = "Choisir où l'infobulle apparaît : ancrée à gauche, à droite ou suivant le curseur."
    L["OPT_ANCHOR_LEFT"] = "Gauche"
    L["OPT_ANCHOR_CURSOR"] = "Curseur"
    L["OPT_ANCHOR_RIGHT"] = "Droite"

    L["SERIESTIP"] = "Fait partie d'une série"
    L["META_ACHIEVEMENT"] = "Méta haut fait"

    -- SessionState feature
    L["OPT_SESSION_STATE_TITLE"] = "Restaurer la dernière vue"
    L["OPT_SESSION_STATE_DESC"] = "Mémoriser l'onglet, la catégorie et le haut fait sélectionnés dans la fenêtre des hauts faits, et les restaurer entre les sessions de jeu.\n(Sauvegardé par personnage.)"

    -- History feature
    L["OPT_HISTORY_TITLE"] = "Activer la navigation dans l'historique"
    L["OPT_HISTORY_DESC"] = "Suivre les hauts faits consultés et naviguer en avant/arrière dans l'historique de navigation.\nLes boutons Précédent/Suivant apparaissent à côté de l'affichage des points de hauts faits."
    L["OPT_HISTORY_MAX_TITLE"] = "Taille de l'historique"
    L["OPT_HISTORY_MAX_DESC"] = "Nombre maximum d'entrées conservées dans l'historique de navigation."
    L["OPT_HISTORY_PERSIST_TITLE"] = "Conserver entre les sessions"
    L["OPT_HISTORY_PERSIST_DESC"] = "Sauvegarder l'historique de navigation à la déconnexion, pour qu'il soit disponible à la prochaine connexion.\n(Sauvegardé par personnage.)"
    L["OPT_HISTORY_BACK_KEY_TITLE"] = "Historique : Précédent"
    L["OPT_HISTORY_FORWARD_KEY_TITLE"] = "Historique : Suivant"
    L["HISTORY_HELP_TITLE"] = "Historique"
    L["HISTORY_HELP_DESC"] = "Suivre les hauts faits consultés et naviguer en avant/arrière dans l'historique de navigation.\n\nRaccourcis\n- Précédent : %s\n- Suivant : %s\n\nVous pouvez les modifier dans les options d'Overachiever2 ou dans les raccourcis clavier du jeu."
    L["HISTORY_TIP_RIGHTCLICK"] = "Clic droit pour la liste de l'historique"
    L["HISTORY_CLEARED"] = "Historique effacé."
    L["HISTORY_EMPTY"] = "L'historique est vide."
    L["HISTORY_STATUS"] = "Historique : %d entrées, position %d."
    L["SLASH_CMD_HISTORY"] = "/oa history : Afficher l'état actuel de l'historique."
    L["SLASH_CMD_HISTORY_CLEAR"] = "/oa history clear : Effacer l'historique de navigation."
    L["SLASH_CMD_HISTORY_BACK"] = "/oa history back : Naviguer en arrière."
    L["SLASH_CMD_HISTORY_FORWARD"] = "/oa history forward : Naviguer en avant."
    BINDING_NAME_OA2_KB_HISTORY_BACK = "Historique : Précédent"
    BINDING_NAME_OA2_KB_HISTORY_FORWARD = "Historique : Suivant"
end

-- ============================================================================
-- Russian (ruRU)
-- ============================================================================

if locale == "ruRU" then
    L["CORE_INIT"] = "Инициализация завершена."
    L["DEBUG_ENABLED"] = "Режим отладки включён."
    L["DEBUG_DISABLED"] = "Режим отладки отключён."
    L["OPTIONS"] = "Настройки"

    L["SLASH_CMD_HELP"] = "Команды Overachiever2:"
    L["SLASH_CMD_DEBUG"] = "/oa debug: Переключить режим отладки (отображение ID в подсказках)."
    L["SLASH_CMD_SEARCH"] = "/oa search <запрос>: Поиск достижений по имени или ID (для отладки)."

    -- Tooltip feature
    L["OPT_DEBUG_TITLE"] = "Отображение ID в подсказках (Режим отладки)"
    L["OPT_DEBUG_DESC"] = "Показывать ID НПС, предметов и достижений в подсказках."

    L["OPT_NPC_TOOLTIP_TITLE"] = "Включить подсказки для НПС"
    L["OPT_NPC_TOOLTIP_DESC"] = "Показывать прогресс достижений при наведении на НПС."

    L["OPT_ITEM_TOOLTIP_TITLE"] = "Включить подсказки для предметов"
    L["OPT_ITEM_TOOLTIP_DESC"] = "Показывать прогресс достижений при наведении на предметы."

    L["OPT_ACH_TOOLTIP_TITLE"] = "Включить подсказки достижений"
    L["OPT_ACH_TOOLTIP_DESC"] = "Показывать расширенные подсказки достижений с дополнительными деталями."

    L["OPT_ACH_WINDOW_TOOLTIP_TITLE"] = "Окно достижений"
    L["OPT_ACH_WINDOW_TOOLTIP_DESC"] = "Показывать расширенную подсказку при наведении на достижения в окне достижений."

    L["OPT_CHAT_HOVER_TOOLTIP_TITLE"] = "Ссылки в чате (Наведение)"
    L["OPT_CHAT_HOVER_TOOLTIP_DESC"] = "Показывать расширенную подсказку при наведении на ссылки достижений в чате."

    L["OPT_CHAT_CLICK_TOOLTIP_TITLE"] = "Ссылки в чате (Клик)"
    L["OPT_CHAT_CLICK_TOOLTIP_DESC"] = "Показывать расширенную подсказку при нажатии на ссылки достижений в чате."

    L["OPT_CHAT_MIDDLE_CLICK_OPEN_TITLE"] = "Клик средней кнопкой по ссылке в чате открывает окно достижений"
    L["OPT_CHAT_MIDDLE_CLICK_OPEN_DESC"] = "Клик средней кнопкой мыши по ссылке достижения в чате открывает окно достижений и выбирает это достижение."

    L["OPT_TRACKED_TOOLTIP_TITLE"] = "Отслеживаемые достижения"
    L["OPT_TRACKED_TOOLTIP_DESC"] = "Показывать расширенную подсказку при наведении на отслеживаемые достижения в трекере целей."

    L["OPT_ANCHOR_TITLE"] = "Привязка"
    L["OPT_ANCHOR_DESC"] = "Выберите, где появляется подсказка: привязана слева, справа или следует за курсором."
    L["OPT_ANCHOR_LEFT"] = "Слева"
    L["OPT_ANCHOR_CURSOR"] = "Курсор"
    L["OPT_ANCHOR_RIGHT"] = "Справа"

    L["SERIESTIP"] = "Часть серии"
    L["META_ACHIEVEMENT"] = "Мета-достижение"

    -- SessionState feature
    L["OPT_SESSION_STATE_TITLE"] = "Восстановить последний вид"
    L["OPT_SESSION_STATE_DESC"] = "Запоминать выбранную вкладку, категорию и достижение в окне достижений и восстанавливать их между игровыми сессиями.\n(Сохраняется для каждого персонажа.)"

    -- History feature
    L["OPT_HISTORY_TITLE"] = "Включить навигацию по истории"
    L["OPT_HISTORY_DESC"] = "Отслеживать просмотренные достижения и перемещаться по истории просмотра вперёд и назад.\nКнопки «Назад»/«Вперёд» отображаются рядом с очками достижений."
    L["OPT_HISTORY_MAX_TITLE"] = "Размер истории"
    L["OPT_HISTORY_MAX_DESC"] = "Максимальное количество записей в истории просмотра."
    L["OPT_HISTORY_PERSIST_TITLE"] = "Сохранять между сессиями"
    L["OPT_HISTORY_PERSIST_DESC"] = "Сохранять историю просмотра при выходе из игры, чтобы она была доступна при следующем входе.\n(Сохраняется для каждого персонажа.)"
    L["OPT_HISTORY_BACK_KEY_TITLE"] = "История: Назад"
    L["OPT_HISTORY_FORWARD_KEY_TITLE"] = "История: Вперёд"
    L["HISTORY_HELP_TITLE"] = "История"
    L["HISTORY_HELP_DESC"] = "Отслеживать просмотренные достижения и перемещаться по истории просмотра вперёд и назад.\n\nГорячие клавиши\n- Назад: %s\n- Вперёд: %s\n\nИзменить можно в настройках Overachiever2 или в настройках клавиш игры."
    L["HISTORY_TIP_RIGHTCLICK"] = "Щёлкните правой кнопкой для списка истории"
    L["HISTORY_CLEARED"] = "История очищена."
    L["HISTORY_EMPTY"] = "История пуста."
    L["HISTORY_STATUS"] = "История: %d записей, позиция %d."
    L["SLASH_CMD_HISTORY"] = "/oa history: Показать текущее состояние истории."
    L["SLASH_CMD_HISTORY_CLEAR"] = "/oa history clear: Очистить историю просмотра."
    L["SLASH_CMD_HISTORY_BACK"] = "/oa history back: Перейти назад."
    L["SLASH_CMD_HISTORY_FORWARD"] = "/oa history forward: Перейти вперёд."
    BINDING_NAME_OA2_KB_HISTORY_BACK = "История: Назад"
    BINDING_NAME_OA2_KB_HISTORY_FORWARD = "История: Вперёд"
end

-- ============================================================================
-- Spanish (esES / esMX)
-- ============================================================================

if locale == "esES" or locale == "esMX" then
    L["CORE_INIT"] = "Inicialización completada."
    L["DEBUG_ENABLED"] = "Modo de depuración activado."
    L["DEBUG_DISABLED"] = "Modo de depuración desactivado."
    L["OPTIONS"] = "Opciones"

    L["SLASH_CMD_HELP"] = "Comandos de Overachiever2:"
    L["SLASH_CMD_DEBUG"] = "/oa debug: Alternar el modo de depuración (mostrar ID en información emergente)."
    L["SLASH_CMD_SEARCH"] = "/oa search <consulta>: Buscar logros por nombre o ID (para depuración)."

    -- Tooltip feature
    L["OPT_DEBUG_TITLE"] = "Mostrar ID en información emergente (Modo de depuración)"
    L["OPT_DEBUG_DESC"] = "Mostrar ID de PNJ, objetos y logros en la información emergente."

    L["OPT_NPC_TOOLTIP_TITLE"] = "Activar información emergente de PNJ"
    L["OPT_NPC_TOOLTIP_DESC"] = "Mostrar el progreso de logros al pasar el cursor sobre los PNJ."

    L["OPT_ITEM_TOOLTIP_TITLE"] = "Activar información emergente de objetos"
    L["OPT_ITEM_TOOLTIP_DESC"] = "Mostrar el progreso de logros al pasar el cursor sobre los objetos."

    L["OPT_ACH_TOOLTIP_TITLE"] = "Activar información emergente de logros"
    L["OPT_ACH_TOOLTIP_DESC"] = "Mostrar información emergente mejorada de logros con detalles adicionales."

    L["OPT_ACH_WINDOW_TOOLTIP_TITLE"] = "Ventana de logros"
    L["OPT_ACH_WINDOW_TOOLTIP_DESC"] = "Mostrar información emergente mejorada al pasar el cursor sobre logros en la ventana de logros."

    L["OPT_CHAT_HOVER_TOOLTIP_TITLE"] = "Enlaces de chat (Pasar el cursor)"
    L["OPT_CHAT_HOVER_TOOLTIP_DESC"] = "Mostrar información emergente mejorada al pasar el cursor sobre enlaces de logros en el chat."

    L["OPT_CHAT_CLICK_TOOLTIP_TITLE"] = "Enlaces de chat (Clic)"
    L["OPT_CHAT_CLICK_TOOLTIP_DESC"] = "Mostrar información emergente mejorada al hacer clic en enlaces de logros en el chat."

    L["OPT_CHAT_MIDDLE_CLICK_OPEN_TITLE"] = "Clic central en enlace de chat abre la ventana de logros"
    L["OPT_CHAT_MIDDLE_CLICK_OPEN_DESC"] = "Al hacer clic con el botón central del ratón en un enlace de logro en el chat se abre la ventana de logros y se selecciona ese logro."

    L["OPT_TRACKED_TOOLTIP_TITLE"] = "Logros rastreados"
    L["OPT_TRACKED_TOOLTIP_DESC"] = "Mostrar información emergente mejorada al pasar el cursor sobre logros rastreados en el rastreador de objetivos."

    L["OPT_ANCHOR_TITLE"] = "Anclaje"
    L["OPT_ANCHOR_DESC"] = "Elige dónde aparece la información emergente: anclada a la izquierda, a la derecha o siguiendo el cursor."
    L["OPT_ANCHOR_LEFT"] = "Izquierda"
    L["OPT_ANCHOR_CURSOR"] = "Cursor"
    L["OPT_ANCHOR_RIGHT"] = "Derecha"

    L["SERIESTIP"] = "Parte de una serie"
    L["META_ACHIEVEMENT"] = "Meta-logro"

    -- SessionState feature
    L["OPT_SESSION_STATE_TITLE"] = "Restaurar última vista"
    L["OPT_SESSION_STATE_DESC"] = "Recordar la pestaña, categoría y logro seleccionados en la ventana de logros, y restaurarlos entre sesiones de juego.\n(Guardado por personaje.)"

    -- History feature
    L["OPT_HISTORY_TITLE"] = "Activar navegación del historial"
    L["OPT_HISTORY_DESC"] = "Rastrear los logros visitados y navegar hacia adelante/atrás por el historial de navegación.\nLos botones Atrás/Adelante aparecen junto a la puntuación de logros."
    L["OPT_HISTORY_MAX_TITLE"] = "Tamaño del historial"
    L["OPT_HISTORY_MAX_DESC"] = "Número máximo de entradas a conservar en el historial de navegación."
    L["OPT_HISTORY_PERSIST_TITLE"] = "Conservar entre sesiones"
    L["OPT_HISTORY_PERSIST_DESC"] = "Guardar el historial de navegación al cerrar sesión, para que esté disponible la próxima vez.\n(Guardado por personaje.)"
    L["OPT_HISTORY_BACK_KEY_TITLE"] = "Historial: Atrás"
    L["OPT_HISTORY_FORWARD_KEY_TITLE"] = "Historial: Adelante"
    L["HISTORY_HELP_TITLE"] = "Historial"
    L["HISTORY_HELP_DESC"] = "Rastrear los logros visitados y navegar hacia adelante/atrás por el historial de navegación.\n\nAtajos\n- Atrás: %s\n- Adelante: %s\n\nPuedes cambiarlos en las opciones de Overachiever2 o en las opciones de atajos de teclado del juego."
    L["HISTORY_TIP_RIGHTCLICK"] = "Clic derecho para la lista del historial"
    L["HISTORY_CLEARED"] = "Historial borrado."
    L["HISTORY_EMPTY"] = "El historial está vacío."
    L["HISTORY_STATUS"] = "Historial: %d entradas, posición %d."
    L["SLASH_CMD_HISTORY"] = "/oa history: Mostrar el estado actual del historial."
    L["SLASH_CMD_HISTORY_CLEAR"] = "/oa history clear: Borrar el historial de navegación."
    L["SLASH_CMD_HISTORY_BACK"] = "/oa history back: Navegar hacia atrás."
    L["SLASH_CMD_HISTORY_FORWARD"] = "/oa history forward: Navegar hacia adelante."
    BINDING_NAME_OA2_KB_HISTORY_BACK = "Historial: Atrás"
    BINDING_NAME_OA2_KB_HISTORY_FORWARD = "Historial: Adelante"
end
