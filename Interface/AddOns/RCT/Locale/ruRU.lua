local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:NewLocale("RdysCrateTracker", "ruRU")

if not L then return end

-- Russian locale translations
-- Translation notes: Please maintain the formatting of %s placeholders
-- and keep the color codes |cff... intact
L["RDYZ"] = "Запрашивает таймеры ящиков у лидера рейда."
-- Addon Info
L["ADDON_NAME"] = "Hated Crate Tracker"
L["ADDON_TITLE"] = "Hated Crate Tracker"
L["ADDON_SHORT_NAME"] = "Hated Tracker"

-- Discord and Links
L["DISCORD_POPUP_TEXT"] = "Скопируйте эту ссылку и откройте её в браузере."
L["JOIN_DISCORD"] = "Присоединиться к Discord"

-- Version Update Messages
L["VERSION_UPDATE_TITLE"] = "Hated Crate Tracker!"
L["VERSION_UPDATE_WELCOME"] = "Добро пожаловать в 8.0"
L["VERSION_UPDATE_MESSAGE"] = [[Эта версия включает улучшения безопасности 
для защиты ваших рейдов. Это не работает 
с предыдущими версиями аддона.

Вам нужно будет очистить старую crateDB, если 
вы хотите использовать эту версию. Простой способ 
убедиться, что это будет работать для вас - это 
просто сбросить ваш профиль аддона. Нажмите 
кнопку Сброс ниже, чтобы сделать это!

HatedGaming

Отслеживай ненависть!]]

-- Buttons
L["RESET"] = "Сброс"
L["CLOSE"] = "Закрыть"
L["DONT_SHOW_AGAIN"] = "Больше не показывать"

-- Warning Messages
L["CRATE_ALERT_MESSAGE"] = "Предупреждение о Ящике HatedGaming! Летит в %s - Шард = %s"
L["CRATE_ANNOUNCE_MESSAGE"] = "%s только что объявил о военном ящике в %s - %s (услышано %s)"
L["CRATE_SPOT_MESSAGE"] = "Военный ящик в %s - %s (замечен %s - %s)"
L["SHARD_MATCH_WARNING"] = "Предупреждение HatedGaming: Шард совпадает для %s. ID Шарда: %s"
L["SHARD_CHANGED_WARNING"] = "Предупреждение HatedGaming: Шард изменился для %s. Старый: %s, Новый: %s"

-- Vignette Messages
L["SUPPLY_CRATE_CLAIMED"] = "Ящик Припасов HatedGaming Захвачен в %s"

-- UI Elements
L["CLOSE_WINDOW"] = "Закрыть Окно"
L["HIDE_SHOW_TIMERS"] = "Скрыть/Показать Таймеры"
L["OPEN_OPTIONS"] = "Открыть Настройки"
L["PLACEMENT_TEXT"] = "HatedGaming Crate Tracker: Текст Размещения Аддона"

-- Zone Names
L["UNKNOWN_ZONE"] = "Неизвестная Зона"

-- Settings Labels
L["GENERAL_SETTINGS"] = "Общие Настройки"
L["ENABLE"] = "Включить"
L["ENABLE_DESC"] = "Включить или отключить аддон"

-- Warning Frame Settings
L["WARNING_FRAME"] = "Рамка Предупреждения"
L["WARNING_FRAME_DESC"] = "Настройки, связанные с рамкой предупреждения"
L["ENABLE_WARNING_FRAME"] = "Включить Рамку Предупреждения"
L["ENABLE_WARNING_FRAME_DESC"] = "Включить или отключить рамку предупреждения"

-- Zone-specific Settings
L["UNDERMINE_ANNOUNCE"] = "Подрыв - Объявлять"
L["UNDERMINE_ANNOUNCE_DESC"] = "Воспроизводить звук и объявлять ящики Подрыва"
L["UNDERMINE_TRACK"] = "Подрыв - Отслеживать"
L["UNDERMINE_TRACK_DESC"] = "Показывать ящики Подрыва в выводе /rct"

-- Command Help
L["HELP_SPOT"] = "/rct spot - Вручную помечает ящик."
L["HELP_CENTER"] = "/rct center - Центрирует основное окно."
L["HELP_HELP"] = "/rct help - Показывает это справочное сообщение."
L["HELP_RDYZ"] = "/rct rdyz - Запрашивает последние ящики у других пользователей."
L["HELP_SHARE"] = "/rct share - Делится информацией об аддоне с другими пользователями."

-- Command Responses
L["RDYZ_RESPONSE"] = "Ты главный! Вот твои таймеры..."

-- Bounty Hunter Messages
L["BOUNTY_ALLIANCE"] = "HatedGaming Охотник за Головами - Награда Альянса в вашей зоне @ %s, %s"
L["BOUNTY_HORDE"] = "HatedGaming Охотник за Головами - Награда Орды в вашей зоне @ %s, %s"

-- Error Messages
L["ADDON_NOT_FOUND"] = "Аддон RdysCrateTracker не найден. Пожалуйста, убедитесь, что он загружен."

-- Test Messages
L["TEST_MESSAGE"] = "Тестовое сообщение"

-- Communications
L["RAID_TOKEN_NOT_RECEIVED"] = "Токен рейда не получен после %d попыток; дальнейшие запросы подавлены (откат %d мин)."
L["BROADCASTED_ALERT"] = "ПРЕДУПРЕЖДЕНИЕ передано для зоны:"
L["WARNING_CRATE_IMMINENT"] = "Предупреждение ящик неминуем:"

-- Staleness Settings
L["ALLOWED_MISSED_TIMERS"] = "Разрешенные пропущенные таймеры ящиков"
L["VERIFY_SHARD"] = "Проверить сегмент"
L["VERIFY_SHARD_DESC"] = "Проверить ID сегмента ящика"

-- Timer Options
L["CRATE_TIMER_BAR_OPTIONS"] = "Опции полосы таймера ящиков"
L["TIMER_OPTIONS"] = "Опции таймера"
L["TIMER_OPTIONS_DESC"] = "Настроить опции таймера для Hated Crate Tracker"
L["TIMER_BAR_FONT_SIZE"] = "Размер шрифта полосы таймера"
L["TIMER_BAR_FONT_SIZE_DESC"] = "Установить размер шрифта для полос таймера ящиков"