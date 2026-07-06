local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:NewLocale("RdysCrateTracker", "esES")

if not L then return end

-- Spanish locale translations
-- Translation notes: Please maintain the formatting of %s placeholders
-- and keep the color codes |cff... intact
L["RDYZ"] = "Solicita temporizadores de cajas al líder de la banda."
-- Addon Info
L["ADDON_NAME"] = "Rastreador de Cajas Odiadas"
L["ADDON_TITLE"] = "Rastreador de Cajas Odiadas"
L["ADDON_SHORT_NAME"] = "Rastreador Odiado"

-- Discord and Links
L["DISCORD_POPUP_TEXT"] = "Copia este enlace y ábrelo en un navegador."
L["JOIN_DISCORD"] = "Unirse a Discord"

-- Version Update Messages
L["VERSION_UPDATE_TITLE"] = "¡Hated Crate Tracker!"
L["VERSION_UPDATE_WELCOME"] = "Bienvenido a 8.0"
L["VERSION_UPDATE_MESSAGE"] = [[Esta versión trae mejoras de seguridad 
para proteger tus incursiones. Esto no funciona 
con versiones anteriores del addon.

Tendrás que limpiar tu antigua crateDB si 
quieres usar esta versión. Una forma fácil 
de asegurar que esto funcione para ti es 
simplemente restablecer tu perfil del addon. ¡Haz clic en el 
botón Restablecer a continuación para hacerlo!

HatedGaming

¡Rastrea el odio!]]

-- Buttons
L["RESET"] = "Restablecer"
L["CLOSE"] = "Cerrar"
L["DONT_SHOW_AGAIN"] = "No mostrar de nuevo"

-- Warning Messages
L["CRATE_ALERT_MESSAGE"] = "¡Alerta de Caja HatedGaming! Volando en %s - Fragmento = %s"
L["CRATE_ANNOUNCE_MESSAGE"] = "%s acaba de anunciar una caja de guerra en %s - %s (escuchado por %s)"
L["CRATE_SPOT_MESSAGE"] = "Caja de guerra en %s - %s (avistada por %s - %s)"
L["SHARD_MATCH_WARNING"] = "Advertencia HatedGaming: El fragmento coincide para %s. ID del Fragmento: %s"
L["SHARD_CHANGED_WARNING"] = "Advertencia HatedGaming: El fragmento cambió para %s. Anterior: %s, Nuevo: %s"

-- Vignette Messages
L["SUPPLY_CRATE_CLAIMED"] = "Caja de Suministros HatedGaming Reclamada en %s"

-- Addon Loading Messages
L["ADDON_LOADED"] = "¡Hated Crate Tracker Cargado!"
L["TOGGLE_HELP"] = "Usa /rct toggle para mostrar/ocultar el addon."

-- Command Responses
L["ADDON"] = "Addon"
L["ENABLED"] = "habilitado"
L["DISABLED"] = "deshabilitado"
L["DEBUG_MODE"] = "Modo de depuración"
L["DEVELOPER_MODE"] = "Modo de desarrollador"
L["CLEARED_CRATE_DB"] = "Base de datos de cajas limpiada."
L["CLEARED_ALL_HISTORY"] = "Todo el historial limpiado."
L["MANUALLY_SPOTTED"] = "Caja avistada manualmente."
L["CENTERED_PANEL"] = "Panel principal centrado."

-- Help Commands
L["AVAILABLE_COMMANDS"] = "Comandos disponibles:"
L["HELP_MAIN"] = "/rct  Abrir/Cerrar el addon."
L["HELP_TOGGLE"] = "/rct toggle - Habilitar/deshabilitar el addon."
L["HELP_DEBUG"] = "/rct debug - Cambiar modo de depuración."
L["HELP_CLEAR"] = "/rct clear - Limpia la base de datos de cajas."
L["HELP_CLEARALL"] = "/rct clearall - Limpia todo el historial."
L["HELP_DEL"] = "/rct del <arg> - Elimina una caja específica."

-- Frame Messages  
L["UNABLE_DETERMINE_MAP"] = "No se puede determinar tu mapa actual. No se puede compartir el ID del Fragmento."
L["SHARD_ID_MESSAGE"] = "ID del Fragmento: %s (ID del Mapa: %s)"

-- UI Button Labels
L["MINIMIZE_BUTTON"] = "+/-"
L["OPTIONS_BUTTON"] = "Opc"
L["CLOSE_BUTTON"] = "X"
L["SYNC_BUTTON"] = "Sinc"
L["SHARE_BUTTON"] = "Compartir"

-- UI Tooltips
L["CLOSE_WINDOW"] = "Cerrar Ventana"
L["HIDE_SHOW_TIMERS"] = "Ocultar/Mostrar Temporizadores"
L["CLICK_SHARE_SHARD"] = "Haz clic para compartir ID del Fragmento"
L["CLICK_SYNC_TIMERS"] = "Haz clic para Sincronizar Temporizadores de Cajas"
L["CLICK_SHARE_ADDON"] = "Haz clic para Compartir Addon"

-- Options Labels
L["PREDICTION"] = "Predicción"
L["PREDICTION_DESC"] = "Activar o Desactivar Predicción"
L["BOUNTY_HUNTER"] = "Cazarrecompensas"
L["BOUNTY_HUNTER_DESC"] = "Activar o desactivar la función de Cazarrecompensas"
L["DEVELOPER_MODE_DESC"] = "Activar Modo de Desarrollador para propósitos de prueba"
L["DISABLE_PVP"] = "Desactivar en JcJ"
L["DISABLE_PVP_DESC"] = "Detener el funcionamiento del addon durante Arena/CdB/Mazmorras/Bandas"
L["RESET_DESC"] = "Restablecer la configuración del addon a valores predeterminados"
L["TEST"] = "Prueba"
L["TEST_DESC"] = "Probar la funcionalidad del addon"
L["PLACEMENT_TEXT"] = "HatedGaming Rastreador de Cajas: Texto de Posición del Addon"
L["SCALE_UPDATED"] = "HatedGaming Rastreador de Cajas: Escala actualizada"
L["BACKGROUND_COLOR_PICKER_DESC"] = "Elige el color de fondo"
L["CRATE_TRACKING"] = "Rastreo de Cajas"
L["CRATE_TRACKING_DESC"] = "Configuración relacionada con el rastreo de cajas"
L["DF_ANNOUNCE_DESC"] = "Hacer un sonido y anunciar cajas de DF"
L["DF_TRACK"] = "DF - Rastrear"
L["DF_TRACK_DESC"] = "Mostrar cajas de DF en la salida de /rct"

-- Undermine Options
L["UNDERMINE_ANNOUNCE"] = "Undermina - Anunciar"
L["UNDERMINE_ANNOUNCE_DESC"] = "Hacer un sonido y anunciar cajas de Undermina"
L["UNDERMINE_TRACK"] = "Undermina - Rastrear"
L["UNDERMINE_TRACK_DESC"] = "Mostrar cajas de Undermina en la salida de /rct"
L["UNDERMINE_WARN"] = "Undermina - Advertir"
L["UNDERMINE_WARN_DESC"] = "Hacer un sonido y advertir antes de que caigan las cajas de Undermina"

-- TWW Options
L["TWW_ANNOUNCE"] = "TWW - Anunciar"
L["TWW_ANNOUNCE_DESC"] = "Hacer un sonido y anunciar cajas de TWW"
L["TWW_TRACK"] = "TWW - Rastrear"
L["TWW_TRACK_DESC"] = "Mostrar cajas de TWW en la salida de /rct"
L["TWW_WARN"] = "TWW - Advertir"
L["TWW_WARN_DESC"] = "Hacer un sonido y advertir antes de que caigan las cajas de TWW"

-- Dragonflight Options
L["DRAGONFLIGHT_ANNOUNCE"] = "Vuelo del Dragón - Anunciar"
L["DRAGONFLIGHT_ANNOUNCE_DESC"] = "Hacer un sonido y anunciar cajas de Vuelo del Dragón"
L["DRAGONFLIGHT_TRACK"] = "Vuelo del Dragón - Rastrear"
L["DRAGONFLIGHT_TRACK_DESC"] = "Mostrar cajas de Vuelo del Dragón en la salida de /rct"
L["DRAGONFLIGHT_WARN"] = "Vuelo del Dragón - Advertir"
L["DRAGONFLIGHT_WARN_DESC"] = "Hacer un sonido y advertir antes de que caigan las cajas de Vuelo del Dragón"

-- Midnight Options
L["MIDNIGHT_ANNOUNCE"] = "Medianoche - Anunciar"
L["MIDNIGHT_ANNOUNCE_DESC"] = "Hacer un sonido y anunciar cajas de Medianoche"
L["MIDNIGHT_TRACK"] = "Medianoche - Rastrear"
L["MIDNIGHT_TRACK_DESC"] = "Mostrar cajas de Medianoche en la salida de /rct"
L["MIDNIGHT_WARN"] = "Medianoche - Advertir"
L["MIDNIGHT_WARN_DESC"] = "Hacer un sonido y advertir antes de que caigan las cajas de Medianoche"

-- Support and Community
L["SUPPORT_HATEDGAMING"] = "Apoyar a HatedGaming"
L["SUPPORT_HELP_DESC"] = "Formas de ayudar a apoyar Hated Crate Tracker y HatedGaming"
L["SUPPORT_HATEDGAMING_DESC"] = "Apoyar a HatedGaming y Hated Crate Tracker"
L["DONATE"] = "Donar"
L["DONATE_DESC"] = "Apoyar a HatedGaming con una donación"
L["JOIN_MY_DISCORD"] = "Únete a Mi Discord"
L["JOIN_DISCORD_DESC"] = "Únete a la comunidad Discord de HatedGaming/RdyGaming Warband"
L["COMMUNITY_MESSAGE"] = "¡No seas un Odiador! - ¡Únete a la comunidad! - HatedGaming en Curseforge"
L["JOIN_SUPPORTERS"] = "Únete a los Partidarios en Discord"
L["MONTHLY_SUPPORTERS_DESC"] = "Partidarios mensuales de HatedGaming"

-- Crate Farming Guide
L["CRATE_FARMING_HOWTO"] = "Cultivo de Cajas: Cómo Hacer"
L["OFFICIAL_GUIDELINES"] = "Guías Oficiales de Cajas de Suministros de Guerra de HatedGaming"
L["OFFICIAL_GUIDELINES_DESC"] = "Guías Oficiales de Cajas de Suministros de Guerra de HatedGaming"
L["OFFICIAL_GUIDELINES_SHORT"] = "Guías Oficiales de Cajas de Suministros de Guerra."

-- Staleness Settings
L["ALLOWED_MISSED_TIMERS"] = "Temporizadores de Cajas Perdidas Permitidas"
L["VERIFY_SHARD"] = "Verificar Fragmento"
L["VERIFY_SHARD_DESC"] = "Verificar el ID del fragmento de la caja"

-- Combat and Warning Settings
L["COMBAT_DISABLE"] = "Desactivar en Combate"
L["COMBAT_DISABLE_DESC"] = "Desactivar la funcionalidad del addon mientras está en combate"
L["WARNING_FRAME"] = "Marco de Advertencia"
L["WARNING_FRAME_DESC"] = "Configuración relacionada con el marco de advertencia"
L["ENABLE_WARNING_FRAME"] = "Activar Marco de Advertencia"
L["ENABLE_WARNING_FRAME_DESC"] = "Activar o desactivar el marco de advertencia"
L["WARNING_X_POSITION"] = "Posición X de Advertencia"
L["WARNING_X_POSITION_DESC"] = "Establecer la posición X del texto de advertencia"
L["WARNING_Y_POSITION"] = "Posición Y de Advertencia"
L["WARNING_Y_POSITION_DESC"] = "Establecer la posición Y del texto de advertencia"
L["WARNING_FRAME_FONT"] = "Fuente del Marco de Advertencia"
L["WARNING_FRAME_FONT_DESC"] = "Seleccionar la fuente para el marco de advertencia"
L["WARNING_FRAME_FONT_SIZE"] = "Tamaño de Fuente del Marco de Advertencia"
L["WARNING_FRAME_FONT_SIZE_DESC"] = "Establecer el tamaño de fuente para el marco de advertencia"

-- Timer Options
L["CRATE_TIMER_BAR_OPTIONS"] = "Opciones de Barra de Temporizador de Cajas"
L["TIMER_OPTIONS"] = "Opciones de Temporizador"
L["TIMER_OPTIONS_DESC"] = "Configurar las opciones de temporizador para Hated Crate Tracker"
L["TIMER_BAR_FONT_SIZE"] = "Tamaño de Fuente de Barra de Temporizador"
L["TIMER_BAR_FONT_SIZE_DESC"] = "Establecer el tamaño de fuente para las barras de temporizador de cajas"

-- UI Elements
L["CLOSE_WINDOW"] = "Cerrar Ventana"
L["HIDE_SHOW_TIMERS"] = "Ocultar/Mostrar Cronómetros"
L["OPEN_OPTIONS"] = "Abrir Opciones"
L["PLACEMENT_TEXT"] = "HatedGaming Crate Tracker: Texto de Colocación del Addon"

-- Zone Names
L["UNKNOWN_ZONE"] = "Zona Desconocida"

-- Settings Labels
L["GENERAL_SETTINGS"] = "Configuración General"
L["ENABLE"] = "Activar"
L["ENABLE_DESC"] = "Activar o desactivar el addon"

-- Warning Frame Settings
L["WARNING_FRAME"] = "Marco de Advertencia"
L["WARNING_FRAME_DESC"] = "Configuraciones relacionadas con el marco de advertencia"
L["ENABLE_WARNING_FRAME"] = "Activar Marco de Advertencia"
L["ENABLE_WARNING_FRAME_DESC"] = "Activar o desactivar el marco de advertencia"

-- Zone-specific Settings
L["UNDERMINE_ANNOUNCE"] = "Socavar - Anunciar"
L["UNDERMINE_ANNOUNCE_DESC"] = "Reproducir sonido y anunciar cajas de Socavar"
L["UNDERMINE_TRACK"] = "Socavar - Rastrear"
L["UNDERMINE_TRACK_DESC"] = "Mostrar cajas de Socavar en la salida de /rct"

-- Command Help
L["HELP_SPOT"] = "/rct spot - Marca manualmente una caja."
L["HELP_CENTER"] = "/rct center - Centra la ventana principal."
L["HELP_HELP"] = "/rct help - Muestra este mensaje de ayuda."
L["HELP_RDYZ"] = "/rct rdyz - Solicita cajas recientes de otros usuarios."
L["HELP_SHARE"] = "/rct share - Comparte información del addon con otros usuarios."

-- Command Responses
L["RDYZ_RESPONSE"] = "¡Eres el jefe! Aquí tienes tus cronómetros..."

-- Bounty Hunter Messages
L["BOUNTY_ALLIANCE"] = "HatedGaming Cazarrecompensas - Recompensa de la Alianza está en tu zona @ %s, %s"
L["BOUNTY_HORDE"] = "HatedGaming Cazarrecompensas - Recompensa de la Horda está en tu zona @ %s, %s"

-- Error Messages
L["ADDON_NOT_FOUND"] = "Addon RdysCrateTracker no encontrado. Por favor, asegúrate de que esté cargado."

-- Test Messages
L["TEST_MESSAGE"] = "Mensaje de prueba"

-- Communications
L["RAID_TOKEN_NOT_RECEIVED"] = "Token de banda no recibido después de %d intentos; solicitudes adicionales suprimidas (enfriamiento de %d min)."
L["BROADCASTED_ALERT"] = "ALERTA transmitida para zona:"
L["WARNING_CRATE_IMMINENT"] = "Advertencia caja inminente:"