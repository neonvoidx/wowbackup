-- Cooldown Manager Tweaks (Retail 11.x-12.x, Lua 5.1)
-- Grid re-layout for Blizzard cooldown viewers with preserved order,
-- optional Reverse, custom row pattern, alignment, and spacing.
-- v2.8.0: FIX Utility Frame Order changing with abilities that morph on essentials bar.
-- v3.0.1: FIX Buff icons jumping when buffs refresh/update (same morph fix as utility)
-- v3.0.2: FIX Aspect ratio reverting on buff refresh - now hooks new children and retries aspect application
-- v3.0.3: FIX Aspect ratio not applying when entering combat - now applies with retries on visibility changes
-- v3.0.4: FIX Profile selection now per-character - each character remembers their own profile and spec assignments
-- v3.0.5: FIX Icons rearranging when Player/Target Frame anchored to Essential Cooldowns - ignores anchor-triggered Layout calls
-- v3.0.6: NEW Warning dialog with "Fix It" button to automatically reverse anchor relationship (anchors Essential Cooldowns TO the frame)
-- v3.1.0: NEW Items & Consumables tracker with drag & drop UI - track custom items (potions, trinkets, food) with full CMT layout customization
-- v3.1.1: NEW Buff Icon Styling - desaturate and fade inactive buffs (works with Edit Mode's "Hide When Inactive" option)
-- v3.2.0: NEW Persistent Buff Display - show all tracked buffs with visual indication of active vs inactive state
-- v4.1.0: NEW Spell tracking - Custom Tracker now supports spells/abilities in addition to items
-- v4.2.0: NEW Live Preview Panel - see real-time layout changes while adjusting settings
-- v4.3.0: NEW Per-Icon Settings - customize visibility, size, zoom, aspect ratio, border color per icon
-- v4.4.0: NEW Visibility Controls - show/hide trackers based on combat, mouseover, target, group, instance type
-- v4.4.1: FIX Icon scrambling - frame reference sync on cooldown updates, combat exit, and Layout hooks
-- v4.4.2: NEW Per-icon timer and count text size/color customization for buffs
-- v4.5.2: FIX Buff icon scrambling during long fights - use spellID for buff matching (auraInstanceID changes on refresh)
-- v4.5.3: NEW Border scaling option - border thickness now scales with icon size (can be disabled)
-- v4.6.0: NEW Masque support - optional integration with Masque button skinning addon for custom icon skins
-- v4.6.2: NEW Count text size slider for each tracker, NEW /cmtpanel reset command to relocate lost panels
local ADDON_NAME = "CooldownManagerTweaks"
local VERSION    = "4.6.2"

-- Debug mode (toggle with /cmtdebug)
local DEBUG_MODE = false
local debugLog = {}
local debugFrame = nil

-- Verbose mode for guardian fixes (toggle with /cmt verbose, resets on reload)
local VERBOSE_FIXES = false

-- Health monitoring (always on)
local healthLog = {}
local healthFrame = nil
local HEALTH_LOG_MAX = 10000  -- Keep last 10000 entries (~14 minutes with 3 trackers at 0.25s intervals)

-- Position tracking for guardian diagnostics
local iconPositions = {}  -- [tracker_key][icon] = {x=, y=, t=}

local function addHealthLog(entry)
  table.insert(healthLog, entry)
  if #healthLog > HEALTH_LOG_MAX then
    table.remove(healthLog, 1) -- Remove oldest
  end
end

local function formatHealthLog()
  local lines = {}
  for i, entry in ipairs(healthLog) do
    local timeStr = date("%H:%M:%S", entry.t)
    local status = entry.ok and "OK" or "ISSUE"
    local line = string.format("[%s] %s (%s): ", timeStr, entry.tracker, status)
    
    if entry.fixed then
      line = line .. "FIXED - " .. entry.reason
    elseif not entry.ok then
      line = line .. "FAILED - " .. entry.reason
    else
      line = line .. string.format("hooks=%s, baseOrder=%d, sigMatch=%s", 
        tostring(entry.hooked), entry.baseOrderSize or 0, tostring(entry.sigMatch))
    end
    
    -- Add position change information if present
    if entry.positionChanges and #entry.positionChanges > 0 then
      line = line .. string.format(" | POSITION CHANGES: %d icon(s) moved", #entry.positionChanges)
      table.insert(lines, line)
      
      -- Add detailed position info for each moved icon
      for _, change in ipairs(entry.positionChanges) do
        local detailLine = string.format("    Icon #%d (%s): (%.1f, %.1f) -> (%.1f, %.1f) | delta=(%.1f, %.1f) | dt=%.3fs",
          change.idx,
          change.iconID,
          change.oldX, change.oldY,
          change.newX, change.newY,
          change.deltaX, change.deltaY,
          change.timeSinceLastCheck)
        table.insert(lines, detailLine)
      end
    else
      table.insert(lines, line)
    end
  end
  return table.concat(lines, "\n")
end

local function addDebug(msg)
  if DEBUG_MODE then
    table.insert(debugLog, msg)
    if #debugLog > 500 then
      table.remove(debugLog, 1) -- Keep only last 500 lines
    end
    if debugFrame and debugFrame:IsShown() then
      debugFrame.text:SetText(table.concat(debugLog, "\n"))
    end
  end
end

local function dprint(...)
  if DEBUG_MODE then
    local msg = string.format(...)
    addDebug(msg)
    print(msg)
  end
end

-- --------------------------------------------------------------------
-- Trackers
-- --------------------------------------------------------------------
local TRACKERS = {
  { name = "EssentialCooldownViewer", displayName = "Essential Cooldowns", key = "essential", isBarType = false },
  { name = "UtilityCooldownViewer",   displayName = "Utility Cooldowns",   key = "utility",   isBarType = false },
  { name = "BuffIconCooldownViewer",  displayName = "Buff Tracker",        key = "buffs",     isBarType = false },
  { name = "CMT_ItemsTrackerFrame",   displayName = "Items & Consumables", key = "items",     isBarType = false, isCMTOwned = true },
  -- Note: BuffIconCooldownViewer is Blizzard's buff tracker in the Cooldown Manager system
  -- It shows player buffs from Blizzard's curated list, positioned by Blizzard
  -- We detect and layout these the same way we do Essential/Utility cooldowns
}

-- Saved vars (declared in TOC: ## SavedVariables: CMT_DB)
CMT_DB = CMT_DB or {}
CMT_DB.profiles = CMT_DB.profiles or {}
CMT_DB.showMinimapButton = (CMT_DB.showMinimapButton == nil) and true or CMT_DB.showMinimapButton -- Default to true
CMT_DB.editModeSetupDismissed = CMT_DB.editModeSetupDismissed or false -- Track if user dismissed Edit Mode setup
CMT_DB.anchorWarningDismissed = CMT_DB.anchorWarningDismissed or false -- Track if user dismissed anchor warning
CMT_DB.lastSeenVersion = CMT_DB.lastSeenVersion or "0.0.0" -- Track last version user saw patch notes for
CMT_DB.masqueEnabled = (CMT_DB.masqueEnabled == nil) and true or CMT_DB.masqueEnabled -- Enable Masque support by default if Masque is installed

-- Per-character saved vars (declared in TOC: ## SavedVariablesPerCharacter: CMT_CharDB)
CMT_CharDB = CMT_CharDB or {}
CMT_CharDB.currentProfile = CMT_CharDB.currentProfile or "Default" -- Per-character profile selection
CMT_CharDB.specProfiles = CMT_CharDB.specProfiles or {} -- Maps specID to profileName (per-character)
CMT_CharDB.itemCache = CMT_CharDB.itemCache or {} -- Cache item info (texture, name) for instant loading
CMT_CharDB.customItemsBySpec = CMT_CharDB.customItemsBySpec or {} -- Per-character, per-spec custom item lists
CMT_CharDB.buffIconMappings = CMT_CharDB.buffIconMappings or {} -- Store texture-to-spellID mappings for persistent buff display

-- Ensure Default profile exists
if not CMT_DB.profiles["Default"] then
  CMT_DB.profiles["Default"] = {}
end

-- Only fill missing defaults; do NOT overwrite existing saved values
local DEFAULTS = {
  alignment     = "CENTER",
  hSpacing      = 2,
  vSpacing      = 2,
  compactMode   = false,
  compactOffset = -4,
  rowPattern    = {1,3,4,3},
  reverseOrder  = false,
  iconSize      = 40,             -- Base icon size in pixels (longest dimension, 20-80)
  iconOpacity   = 1.0,            -- Base icon opacity (0.0 to 1.0) - can be overridden per-icon
  zoom          = 1.0,            -- Icon texture zoom (1.0 to 3.0) - zooms into center
  aspectRatio   = "1:1",          -- Icon aspect ratio: "1:1", "16:9", "9:16", "21:9", "4:3", "3:4", or custom "WxH" (e.g., "40x30")
  customAspectW = 40,             -- Custom aspect ratio width (used when aspectRatio is "custom")
  customAspectH = 40,             -- Custom aspect ratio height (used when aspectRatio is "custom")
  layoutDirection = "ROWS",       -- "ROWS" or "COLUMNS"
  borderAlpha   = 1.0,            -- Border/frame alpha (0.0 to 1.0) - 0 = invisible, 1 = fully visible
  borderScale   = true,           -- Scale border with icon size (true) or keep original size (false)
  cooldownTextScale = 1.0,        -- Cooldown text scale multiplier (0.5 to 2.0)
  countTextScale = 1.0,           -- Stack/count text scale multiplier (0.5 to 2.0)
  -- Persistent Buff Display settings (v3.2.0)
  persistentDisplay = true,       -- Enable persistent buff display with desaturation
  greyscaleInactive = true,       -- Desaturate inactive buffs (greyscale)
  inactiveAlpha = 0.5,            -- Alpha for inactive buffs (0.0 to 1.0) - multiplied by iconOpacity
  -- Bar-specific settings
  barIconSide   = "LEFT",     -- "LEFT" or "RIGHT"
  barSpacing    = 2,          -- vertical spacing between bars
  barIconGap    = 0,          -- horizontal gap between icon and bar
  -- Visibility Settings (v4.4.0)
  visibilityEnabled = false,         -- Master toggle for visibility controls
  visibilityCombat = false,          -- Show in combat
  visibilityMouseover = false,       -- Show on mouseover
  visibilityTarget = false,          -- Show when player has target
  visibilityGroup = false,           -- Show in party/raid
  visibilityInstance = false,        -- Show by instance type
  visibilityInstanceTypes = {},      -- Which instance types to show in
  visibilityFadeAlpha = 0,           -- Alpha when hidden (0-100)
  visibilityOverrideEMT = false,     -- Use CMT visibility even if EMT is managing frame
  -- Masque Settings (v4.6.0)
  masqueDisabled = false,            -- Per-tracker toggle to disable Masque skinning
  masqueSavedAspect = nil,           -- Saved aspect ratio when Masque enabled (to restore when disabled)
  masqueSavedZoom = nil,             -- Saved zoom when Masque enabled
  masqueSavedBorderAlpha = nil,      -- Saved border alpha when Masque enabled
}

local function ensureDefaults()
  -- Ensure basic structure exists first
  CMT_DB.profiles = CMT_DB.profiles or {}
  CMT_CharDB = CMT_CharDB or {}
  CMT_CharDB.currentProfile = CMT_CharDB.currentProfile or "Default"
  CMT_CharDB.specProfiles = CMT_CharDB.specProfiles or {}  -- Initialize spec profiles mapping (per-character)
  
  -- Ensure current profile exists
  local profileName = CMT_CharDB.currentProfile
  CMT_DB.profiles[profileName] = CMT_DB.profiles[profileName] or {}
  local profile = CMT_DB.profiles[profileName]
  
  -- Migrate old data structure to profiles if needed
  for _, t in ipairs(TRACKERS) do
    if CMT_DB[t.key] and not profile[t.key] then
      -- Old structure: CMT_DB[key] had settings directly or in .all
      if CMT_DB[t.key].all then
        -- Was using spec system
        profile[t.key] = CMT_DB[t.key].all
      elseif type(CMT_DB[t.key]) == "table" then
        -- Was using flat structure
        profile[t.key] = CMT_DB[t.key]
      end
      -- Clear old data
      CMT_DB[t.key] = nil
    end
  end
  
  -- Ensure each tracker has settings in current profile
  for _, t in ipairs(TRACKERS) do
    profile[t.key] = profile[t.key] or {}
    local bucket = profile[t.key]
    
    -- Migrate old scale to iconSize (one-time conversion)
    if bucket.scale and not bucket.iconSize then
      -- Old scale was 0.5 to 2.0, with 1.0 = 40px default
      -- Convert: iconSize = 40 * scale
      bucket.iconSize = math.floor(40 * bucket.scale + 0.5)
      -- Keep old scale for a version in case of rollback
      bucket._oldScale = bucket.scale
      bucket.scale = nil
    end
    
    -- Fill defaults if missing
    for k, v in pairs(DEFAULTS) do
      if bucket[k] == nil then
        if k == "rowPattern" and type(v) == "table" then
          local copy = {}; for i=1,#v do copy[i]=v[i] end
          bucket[k] = copy
        else
          bucket[k] = v
        end
      end
    end
  end
  
  -- Clean up old spec mode data
  CMT_DB.currentSpecMode = nil
end

-- fwd decls
local layoutCustomGrid
local layoutBars
local getBlizzardOrderedIcons
local minimapButton  -- Forward declaration for minimap button

-- Preview panel system (v4.2.0)
local previewPanel = nil
local previewIcons = {}  -- Pool of preview icon frames
local previewCurrentKey = nil  -- Currently previewed tracker
local previewSelectedSlot = nil  -- Currently selected slot index for per-icon settings
local UpdatePreviewLayout  -- Forward declaration
local PopulatePreview  -- Forward declaration
local PREVIEW_ICON_POOL_SIZE = 30  -- Max preview icons

-- Helper functions for tracker info (must be defined early)
local function getTrackerNameByKey(key)
  for _,t in ipairs(TRACKERS) do if t.key==key then return t.name end end
end

local function getTrackerInfoByKey(key)
  for _,t in ipairs(TRACKERS) do if t.key==key then return t end end
end

-- GetCurrentProfile (defined early for custom items system)
local function GetCurrentProfile()
  local profileName = CMT_CharDB.currentProfile or "Default"
  CMT_DB.profiles[profileName] = CMT_DB.profiles[profileName] or {}
  return CMT_DB.profiles[profileName]
end

-- Shared Reload UI popup (used by both CMT and EMT if present)
if not StaticPopupDialogs["PROFILE_RELOAD_UI"] then
  StaticPopupDialogs["PROFILE_RELOAD_UI"] = {
    text = "Profile switched. Reload UI to apply all changes and prevent errors?",
    button1 = "Reload UI",
    button2 = "Later",
    OnAccept = function()
      ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }
end

local _fastRepairUntil = 0

-- Position settling period - don't try to restore positions until frames have settled
-- This prevents fighting Blizzard's initial layout adjustments
local _positionSettlingUntil = 0
local POSITION_SETTLING_PERIOD = 15  -- seconds after login before we trust positions

-- Position debugging mode - toggle with /cmt posdebug
local POSITION_DEBUG = false

-- Position watch mode - shows ALL position changes including SetPoint calls
-- Toggle with /cmt poswatch
local POSITION_WATCH = false

-- Helper to print position debug info (drift detection)
local function posDebug(fmt, ...)
  if POSITION_DEBUG then
    print("|cffff9900CMT POS:|r " .. string.format(fmt, ...))
  end
end

-- Helper to print position watch info (all changes)
local function posWatch(fmt, ...)
  if POSITION_WATCH then
    print("|cffff00ffCMT WATCH:|r " .. string.format(fmt, ...))
  end
end

-- Check if we're still in the settling period
local function IsSettlingPeriod()
  return GetTime() < _positionSettlingUntil
end

-- --------------------------------------------------------------------
-- Helpers

-- --------------------------------------------------------------------
-- Edit Mode Detection
-- Returns true if Blizzard's Edit Mode is currently active
-- Used to skip applying nudges during Edit Mode to preserve tracker bounds
-- --------------------------------------------------------------------
local _forceEditModeBehavior = false  -- Set true during Edit Mode open/close transitions

local function IsEditModeActive()
  if _forceEditModeBehavior then return true end
  return EditModeManagerFrame and EditModeManagerFrame:IsShown()
end

-- --------------------------------------------------------------------
-- Cross-Tracker Position Restoration
-- When one tracker's layout runs, Blizzard may shift ALL trackers
-- This helper checks and restores all trackers except the one currently being laid out
-- --------------------------------------------------------------------
local function RestoreAllTrackerPositions(excludeKey)
  if IsEditModeActive() then return end
  if IsSettlingPeriod() then return end  -- Don't restore during settling
  
  for _, t in ipairs(TRACKERS) do
    if t.key ~= excludeKey then
      local v = _G[t.name]
      if v and v._CMT_knownGoodPosition then
        local pos = v._CMT_knownGoodPosition
        local _, _, _, currentX, currentY = v:GetPoint(1)
        if currentX and pos.x and (math.abs(currentX - pos.x) > 0.5 or math.abs(currentY - pos.y) > 0.5) then
          posDebug("[%s] CROSS-TRACKER DRIFT (from [%s] layout): was %.1f,%.1f should be %.1f,%.1f - RESTORING", 
            t.key, excludeKey or "unknown", currentX, currentY, pos.x, pos.y)
          v:ClearAllPoints()
          v:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.x, pos.y)
        end
      end
    end
  end
end

-- --------------------------------------------------------------------
-- Aspect Ratio Parsing
-- Supports both preset formats ("16:9") and custom pixel formats ("40x30")
-- Returns aspectW, aspectH as numbers representing the ratio
-- For presets: returns the ratio values (e.g., 16, 9)
-- For custom: returns the pixel values (e.g., 40, 30)
-- --------------------------------------------------------------------
local function ParseAspectRatio(aspectRatio)
  if not aspectRatio or aspectRatio == "" then
    return 1, 1  -- Default to square
  end
  
  -- Try preset format first: "W:H" (e.g., "16:9")
  local presetW, presetH = aspectRatio:match("^(%d+):(%d+)$")
  if presetW and presetH then
    return tonumber(presetW), tonumber(presetH)
  end
  
  -- Try custom format: "WxH" (e.g., "40x30")
  local customW, customH = aspectRatio:match("^(%d+)x(%d+)$")
  if customW and customH then
    return tonumber(customW), tonumber(customH)
  end
  
  -- Invalid format, return square
  return 1, 1
end

-- Check if an aspect ratio string is a custom pixel-based format
local function IsCustomAspectRatio(aspectRatio)
  if not aspectRatio then return false end
  return aspectRatio:match("^%d+x%d+$") ~= nil
end

-- Format a custom aspect ratio string from width and height
local function FormatCustomAspectRatio(width, height)
  return string.format("%dx%d", width or 40, height or 40)
end

-- Get display text for an aspect ratio
local function GetAspectRatioDisplayText(aspectRatio)
  if not aspectRatio then return "Square (1:1)" end
  
  -- Check for custom format
  if IsCustomAspectRatio(aspectRatio) then
    local w, h = ParseAspectRatio(aspectRatio)
    return string.format("Custom (%dx%d)", w, h)
  end
  
  -- Preset display names
  local presetNames = {
    ["1:1"] = "Square (1:1)",
    ["16:9"] = "Widescreen (16:9)",
    ["21:9"] = "Ultrawide (21:9)",
    ["4:3"] = "Classic Wide (4:3)",
    ["9:16"] = "Portrait (9:16)",
    ["3:4"] = "Tall Portrait (3:4)",
  }
  
  return presetNames[aspectRatio] or aspectRatio
end

-- ============================================================================
-- CUSTOM ITEMS TRACKING SYSTEM (v3.1.0)
-- ============================================================================

-- Forward declarations
local relayoutOne

-- Storage for custom item icons
local customItemIcons = {} -- [itemID] = iconFrame
local itemsTrackerFrame = nil -- The Items tracker frame

-- Helper function to get current spec's tracker entries (items and spells)
local function GetCurrentSpecEntries()
  -- Ensure CMT_CharDB exists first
  if not CMT_CharDB then return {} end
  
  -- Ensure the table exists
  CMT_CharDB.customEntriesBySpec = CMT_CharDB.customEntriesBySpec or {}
  
  local specIndex = GetSpecialization()
  if not specIndex then return {} end
  
  local specID = GetSpecializationInfo(specIndex)
  if not specID then return {} end
  
  CMT_CharDB.customEntriesBySpec[specID] = CMT_CharDB.customEntriesBySpec[specID] or {}
  
  -- Migrate old item-only data if it exists
  if CMT_CharDB.customItemsBySpec and CMT_CharDB.customItemsBySpec[specID] then
    local oldItems = CMT_CharDB.customItemsBySpec[specID]
    for _, itemID in ipairs(oldItems) do
      -- Check if already migrated
      local found = false
      for _, entry in ipairs(CMT_CharDB.customEntriesBySpec[specID]) do
        if entry.type == "item" and entry.id == itemID then
          found = true
          break
        end
      end
      if not found then
        table.insert(CMT_CharDB.customEntriesBySpec[specID], {type = "item", id = itemID})
      end
    end
    -- Clear old data after migration
    CMT_CharDB.customItemsBySpec[specID] = nil
  end
  
  return CMT_CharDB.customEntriesBySpec[specID]
end

-- Legacy function for compatibility
local function GetCurrentSpecItems()
  return GetCurrentSpecEntries()
end

local function CreateCustomTrackerIcon(entry, parent)
  if not entry or not entry.type or not entry.id then return nil end
  
  local entryType = entry.type  -- "item" or "spell"
  local entryID = entry.id
  local entryName, entryTexture
  
  -- Ensure cache exists
  CMT_CharDB.trackerCache = CMT_CharDB.trackerCache or {}
  
  -- Get info based on type
  if entryType == "item" then
    -- Item handling
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, 
          itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(entryID)
    
    if not itemName then
      C_Item.RequestLoadItemDataByID(entryID)
      
      -- Check cache
      local cache = CMT_CharDB.trackerCache[entryType .. "_" .. entryID]
      if cache then
        entryName = cache.name
        entryTexture = cache.texture
        dprint("%s %d not in WoW cache, using saved cache: %s", entryType, entryID, entryName)
      else
        dprint("%s %d not cached anywhere, requesting data...", entryType, entryID)
        return nil
      end
    else
      entryName = itemName
      entryTexture = itemTexture
      -- Update cache
      CMT_CharDB.trackerCache[entryType .. "_" .. entryID] = {
        name = entryName,
        texture = entryTexture
      }
    end
    
  elseif entryType == "spell" then
    -- Spell handling
    local spellInfo = C_Spell.GetSpellInfo(entryID)
    if spellInfo then
      entryName = spellInfo.name
      entryTexture = C_Spell.GetSpellTexture(entryID)
      
      -- Update cache
      CMT_CharDB.trackerCache[entryType .. "_" .. entryID] = {
        name = entryName,
        texture = entryTexture
      }
    else
      -- Check cache
      local cache = CMT_CharDB.trackerCache[entryType .. "_" .. entryID]
      if cache then
        entryName = cache.name
        entryTexture = cache.texture
        dprint("%s %d not in WoW cache, using saved cache: %s", entryType, entryID, entryName)
      else
        dprint("%s %d not found", entryType, entryID)
        return nil
      end
    end
  else
    dprint("Unknown entry type: %s", tostring(entryType))
    return nil
  end
  
  -- Create button frame
  local frame = CreateFrame("Button", "CMT_CustomTracker_" .. entryType .. "_" .. entryID, parent)
  frame:SetSize(40, 40)
  
  -- Create icon texture
  local icon = frame:CreateTexture(nil, "BACKGROUND")
  icon:SetAllPoints(frame)
  icon:SetTexture(entryTexture)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  
  -- Create cooldown frame overlay
  local cd = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
  cd:SetAllPoints(frame)
  cd:SetDrawEdge(true)
  cd:SetDrawSwipe(true)
  cd:SetSwipeColor(0, 0, 0, 0.8)
  cd:SetHideCountdownNumbers(false)
  cd:SetReverse(false)
  
  -- For spells, store the spell ID on the cooldown frame so it can track automatically
  if entryType == "spell" then
    cd._spellID = entryID
  end
  
  -- Apply saved cooldown text scale
  local profile = GetCurrentProfile()
  local cdScale = (profile.items and profile.items.cooldownTextScale) or 1.0
  cd:SetScale(cdScale)
  
  -- Count text (for items with stacks, or spell charges)
  local countText = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  countText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
  countText:SetJustifyH("RIGHT")
  countText:SetTextColor(1, 1, 1, 1)
  countText:SetShadowOffset(1, -1)
  countText:SetShadowColor(0, 0, 0, 1)
  countText:SetDrawLayer("OVERLAY", 7)
  
  -- Apply saved font size
  local fontSize = (profile.items and profile.items.countFontSize) or 14
  local fontPath = countText:GetFont()
  countText:SetFont(fontPath, fontSize, "OUTLINE")
  
  frame._CMT_customTracker = true
  frame._CMT_entryType = entryType
  frame._CMT_entryID = entryID
  frame._CMT_entryName = entryName
  frame.icon = icon
  frame.Icon = icon
  frame.cooldown = cd
  frame.Cooldown = cd
  frame.count = countText
  
  -- Enable mouse for tooltips and dragging
  frame:EnableMouse(true)
  
  -- Add tooltips (blocked during combat to avoid secret value errors)
  frame:SetScript("OnEnter", function(self)
    -- Don't show tooltips during combat
    if InCombatLockdown() then
      return
    end
    
    -- Use pcall to safely show tooltip (vendor prices can be secret values even out of combat)
    pcall(function()
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      if entryType == "item" then
        GameTooltip:SetItemByID(entryID)
      elseif entryType == "spell" then
        GameTooltip:SetSpellByID(entryID)
      end
      GameTooltip:Show()
    end)
  end)
  
  frame:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)
  
  -- Allow Shift+drag to propagate to parent tracker frame
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() and self:GetParent() then
      self:GetParent():StartMoving()
    end
  end)
  frame:SetScript("OnDragStop", function(self)
    if self:GetParent() then
      self:GetParent():StopMovingOrSizing()
      
      -- Trigger parent's save position logic
      local parent = self:GetParent()
      if parent.OnDragStop then
        parent:OnDragStop()
      end
    end
  end)
  
  dprint("Created %s icon for ID %d", entryType, entryID)
  
  -- Register with Masque if enabled (delayed slightly to ensure frame is fully set up)
  C_Timer.After(0.1, function()
    if MasqueModule and MasqueModule.OnCustomIconCreated then
      MasqueModule.OnCustomIconCreated(frame)
    end
  end)
  
  return frame
end

-- Legacy function for compatibility
local function CreateCustomItemIcon(itemID, parent)
  return CreateCustomTrackerIcon({type = "item", id = itemID}, parent)
end

local function UpdateCustomTrackerCooldown(iconFrame)
  if not iconFrame or not iconFrame.cooldown or not iconFrame.icon then return end
  if not iconFrame._CMT_entryType or not iconFrame._CMT_entryID then return end
  
  local entryType = iconFrame._CMT_entryType
  local entryID = iconFrame._CMT_entryID
  
  local start, duration, enable
  local count = 0
  local hasResource = true
  
  if entryType == "item" then
    -- Item handling - use pcall during combat to avoid tainting tooltip system
    if InCombatLockdown() then
      -- During combat, use pcall to safely get item data without tainting tooltips
      local success = pcall(function()
        count = C_Item.GetItemCount(entryID, false, false, false)
        hasResource = (count > 0)
        start, duration, enable = GetItemCooldown(entryID)
        
        -- Show item count
        if iconFrame.count then
          iconFrame.count:SetText(count)
          iconFrame.count:Show()
          
          -- Color code the count
          if count == 0 then
            iconFrame.count:SetTextColor(0.5, 0.5, 0.5, 1)
          else
            iconFrame.count:SetTextColor(1, 1, 1, 1)
          end
        end
      end)
      
      -- If pcall failed, just return and keep existing display
      if not success then
        return
      end
    else
      -- Out of combat - normal item handling
      count = C_Item.GetItemCount(entryID, false, false, false)
      hasResource = (count > 0)
      start, duration, enable = GetItemCooldown(entryID)
      
      -- Show item count
      if iconFrame.count then
        iconFrame.count:SetText(count)
        iconFrame.count:Show()
        
        -- Color code the count
        if count == 0 then
          iconFrame.count:SetTextColor(0.5, 0.5, 0.5, 1)  -- Gray when 0
        else
          iconFrame.count:SetTextColor(1, 1, 1, 1)  -- White when > 0
        end
      end
    end
    
  elseif entryType == "spell" then
    -- Spell handling - During combat, don't touch the cooldown at all
    
    -- If in combat, skip all spell cooldown updates and let existing display continue
    if InCombatLockdown() then
      -- Still update resource availability (spell known check is safe)
      local spellInfo = C_Spell.GetSpellInfo(entryID)
      hasResource = (spellInfo ~= nil and IsSpellKnown(entryID))
      
      -- Desaturate/dim if resource not available
      if not hasResource then
        iconFrame.icon:SetDesaturated(true)
        iconFrame.icon:SetAlpha(0.5)
      else
        iconFrame.icon:SetDesaturated(false)
        iconFrame.icon:SetAlpha(1.0)
      end
      
      -- Return early - don't touch the cooldown display
      return
    end
    
    -- Out of combat - safe to read spell cooldown data
    local spellInfo = C_Spell.GetSpellInfo(entryID)
    hasResource = (spellInfo ~= nil and IsSpellKnown(entryID))
    
    -- Get spell cooldown info
    local cooldownInfo = C_Spell.GetSpellCooldown(entryID)
    if cooldownInfo then
      start = cooldownInfo.startTime
      duration = cooldownInfo.duration
      enable = cooldownInfo.isEnabled
    end
    
    -- Update charges display
    local chargeInfo = C_Spell.GetSpellCharges(entryID)
    if chargeInfo and chargeInfo.currentCharges and chargeInfo.maxCharges then
      count = chargeInfo.currentCharges
      if iconFrame.count then
        iconFrame.count:SetText(count)
        iconFrame.count:Show()
        iconFrame.count:SetTextColor(1, 1, 1, 1)
      end
    else
      if iconFrame.count then
        iconFrame.count:Hide()
      end
    end
  end
  
  -- Desaturate/dim if resource not available
  if not hasResource then
    iconFrame.icon:SetDesaturated(true)
    iconFrame.icon:SetAlpha(0.5)
  else
    iconFrame.icon:SetDesaturated(false)
    iconFrame.icon:SetAlpha(1.0)
  end
  
  -- Update cooldown display
  if duration and duration > 1.5 then
    if not iconFrame._lastCooldownDuration or math.abs(iconFrame._lastCooldownDuration - duration) > 0.1 then
      iconFrame.cooldown:SetCooldown(start, duration)
      iconFrame._lastCooldownDuration = duration
    else
      iconFrame.cooldown:SetCooldown(start, duration)
    end
  else
    if iconFrame._lastCooldownDuration then
      iconFrame.cooldown:Clear()
      iconFrame._lastCooldownDuration = nil
    end
  end
end

-- Legacy function
local function UpdateCustomItemCooldown(itemID, iconFrame)
  UpdateCustomTrackerCooldown(iconFrame)
end

local function UpdateAllCustomItemCooldowns()
  for _, iconFrame in pairs(customItemIcons) do
    UpdateCustomTrackerCooldown(iconFrame)
  end
end

local function AddCustomEntry(entry)
  if not entry or not entry.type or not entry.id then
    print("CMT: Invalid entry")
    return false
  end
  
  local key = entry.type .. "_" .. entry.id
  if customItemIcons[key] then
    dprint("%s %d already tracked", entry.type, entry.id)
    return false
  end
  
  local icon = CreateCustomTrackerIcon(entry, itemsTrackerFrame)
  if not icon then
    C_Timer.After(1, function() AddCustomEntry(entry) end)
    return false
  end
  
  customItemIcons[key] = icon
  
  -- Store entry per-character per-spec
  local specEntries = GetCurrentSpecEntries()
  
  local found = false
  for _, e in ipairs(specEntries) do
    if e.type == entry.type and e.id == entry.id then
      found = true
      break
    end
  end
  
  if not found then
    table.insert(specEntries, {type = entry.type, id = entry.id})
  end
  
  UpdateCustomTrackerCooldown(icon)
  relayoutOne("items")
  
  local entryName = icon._CMT_entryName or (entry.type .. " " .. entry.id)
  print(string.format("CMT: Added %s to Custom tracker", entryName))
  return true
end

local function RemoveCustomEntry(entry)
  if not entry or not entry.type or not entry.id then return false end
  
  local key = entry.type .. "_" .. entry.id
  local icon = customItemIcons[key]
  if not icon then return false end
  
  icon:Hide()
  icon:SetParent(nil)
  customItemIcons[key] = nil
  
  -- Remove from current spec's list
  local specEntries = GetCurrentSpecEntries()
  for i, e in ipairs(specEntries) do
    if e.type == entry.type and e.id == entry.id then
      table.remove(specEntries, i)
      break
    end
  end
  
  relayoutOne("items")
  
  local entryName = icon._CMT_entryName or (entry.type .. " " .. entry.id)
  print(string.format("CMT: Removed %s from Custom tracker", entryName))
  return true
end

-- Legacy item functions
local function AddCustomItem(itemID)
  return AddCustomEntry({type = "item", id = itemID})
end

local function RemoveCustomItem(itemID)
  return RemoveCustomEntry({type = "item", id = itemID})
end

-- New spell functions
local function AddCustomSpell(spellID)
  return AddCustomEntry({type = "spell", id = spellID})
end

local function RemoveCustomSpell(spellID)
  return RemoveCustomEntry({type = "spell", id = spellID})
end

-- Original function - now redirects to unified version
local function AddCustomItem_OLD(itemID)
  if customItemIcons[itemID] then
    dprint("Item %d already tracked", itemID)
    return false
  end
  
  local icon = CreateCustomItemIcon(itemID, itemsTrackerFrame)
  if not icon then
    C_Timer.After(1, function() AddCustomItem(itemID) end)
    return false
  end
  
  customItemIcons[itemID] = icon
  
  -- Store items per-character per-spec
  local specItems = GetCurrentSpecItems()
  
  local found = false
  for _, id in ipairs(specItems) do
    if id == itemID then found = true; break end
  end
  
  if not found then
    table.insert(specItems, itemID)
  end
  
  UpdateCustomItemCooldown(itemID, icon)
  relayoutOne("items")
  
  local itemName = GetItemInfo(itemID)
  print(string.format("CMT: Added %s to Items tracker", itemName or ("Item " .. itemID)))
  return true
end

local function RemoveCustomItem_OLD(itemID)
  local icon = customItemIcons[itemID]
  if not icon then return false end
  
  icon:Hide()
  icon:SetParent(nil)
  customItemIcons[itemID] = nil
  
  -- Remove from current spec's list
  local specItems = GetCurrentSpecItems()
  for i, id in ipairs(specItems) do
    if id == itemID then
      table.remove(specItems, i)
      break
    end
  end
  
  relayoutOne("items")
  
  local itemName = GetItemInfo(itemID)
  print(string.format("CMT: Removed %s from Items tracker", itemName or ("Item " .. itemID)))
  return true
end

local function ClearAllCustomItems()
  for itemID, icon in pairs(customItemIcons) do
    if icon then icon:Hide(); icon:SetParent(nil) end
  end
  
  customItemIcons = {}
  
  -- Clear current spec's list
  local specItems = GetCurrentSpecItems()
  for i = #specItems, 1, -1 do
    specItems[i] = nil
  end
  
  relayoutOne("items")
  print("CMT: Cleared all custom items for current spec")
end

local function LoadCustomItems()
  -- Clear existing icons
  for key, icon in pairs(customItemIcons) do
    if icon then icon:Hide(); icon:SetParent(nil) end
  end
  customItemIcons = {}
  
  -- Get current spec's entries (items and spells)
  local specEntries = GetCurrentSpecEntries()
  
  -- Early return if no entries for this spec
  if not specEntries or #specEntries == 0 then
    return  -- Nothing to load, icons cleared above
  end
  
  -- Phase 1: Create ALL icons immediately using cached data
  local entriesToRefresh = {}
  
  for _, entry in ipairs(specEntries) do
    if entry.type and entry.id then
      local key = entry.type .. "_" .. entry.id
      local icon = CreateCustomTrackerIcon(entry, itemsTrackerFrame)
      if icon then
        customItemIcons[key] = icon
        -- Mark for refresh (update cooldown/count after layout)
        table.insert(entriesToRefresh, entry)
      else
        -- Request data load for uncached entries
        if entry.type == "item" then
          C_Item.RequestLoadItemDataByID(entry.id)
        end
        dprint("%s %d has no cache, requesting initial load", entry.type, entry.id)
      end
    end
  end
  
  -- Phase 2: Layout immediately with all icons visible
  C_Timer.After(0.05, function() 
    relayoutOne("items")
    
    -- Phase 3: Update cooldowns/counts in background
    C_Timer.After(0.1, function()
      for _, entry in ipairs(entriesToRefresh) do
        local key = entry.type .. "_" .. entry.id
        local icon = customItemIcons[key]
        if icon then
          UpdateCustomTrackerCooldown(icon)
        end
      end
    end)
    
    -- Phase 4: Retry any entries that had no cache
    C_Timer.After(1.0, function()
      local anyNewIcons = false
      for _, entry in ipairs(specEntries) do
        if entry.type and entry.id then
          local key = entry.type .. "_" .. entry.id
          if not customItemIcons[key] then
            local retryIcon = CreateCustomTrackerIcon(entry, itemsTrackerFrame)
            if retryIcon then
              customItemIcons[key] = retryIcon
              UpdateCustomTrackerCooldown(retryIcon)
              anyNewIcons = true
              dprint("Successfully loaded uncached %s %d on retry", entry.type, entry.id)
            end
          end
        end
      end
      if anyNewIcons then
        relayoutOne("items")
      end
    end)
  end)
end

local function CreateItemsTrackerFrame()
  if itemsTrackerFrame then return itemsTrackerFrame end
  
  local frame = CreateFrame("Frame", "CMT_ItemsTrackerFrame", UIParent)
  frame:SetSize(200, 40)
  frame:SetFrameStrata("MEDIUM")
  frame:SetClampedToScreen(true)
  
  -- Default position (will be overridden by Edit Mode if user moves it)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
  
  frame._CMT_ItemsTracker = true
  frame._CMT_Hooked = true
  frame._CMT_baseOrder = {}
  
  dprint("Created CMT_ItemsTrackerFrame")
  
  itemsTrackerFrame = frame
  
  -- Load saved position if exists (works for both LibEditMode and fallback)
  if CMT_DB.itemsTrackerPosition then
    local pos = CMT_DB.itemsTrackerPosition
    frame:ClearAllPoints()
    frame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or -200)
    dprint("Loaded saved Items tracker position")
  end
  
  -- Set up callback function for when frame position changes
  local function OnFramePositionChanged()
    local point, relativeTo, relativePoint, x, y = frame:GetPoint()
    CMT_DB.itemsTrackerPosition = {
      point = point,
      relativePoint = relativePoint,
      x = x,
      y = y,
    }
    dprint("Items tracker position saved via Edit Mode: %s %.1f, %.1f", point, x, y)
    
    -- Try to trigger Edit Mode save button (may not always work with LibEditMode)
    if EditModeManagerFrame and EditModeManagerFrame.SetLayoutModified then
      EditModeManagerFrame:SetLayoutModified()
    end
  end
  
  -- Try to register with LibEditMode (if available)
  local hasLibEditMode = false
  if LibStub then
    local LibEditMode = LibStub("LibEditMode", true)
    if LibEditMode then
      -- Try to register with LibEditMode
      local success, err = pcall(function()
        -- AddFrame(frame, callback, default)
        -- callback: function called when frame settings change
        -- default: table with default position {point, x, y}
        LibEditMode:AddFrame(frame, OnFramePositionChanged, {
          point = "CENTER",
          x = 0,
          y = -200,
        })
      end)
      
      if success then
        hasLibEditMode = true
        dprint("Registered Items tracker with LibEditMode")
        print("CMT: Items tracker registered with Edit Mode (Esc > Edit Mode)")
        
        -- Tooltip for Edit Mode
        frame:EnableMouse(true)
        frame:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_TOP")
          GameTooltip:SetText("Items & Consumables Tracker", 1, 1, 1)
          GameTooltip:AddLine("Move via Edit Mode (Esc > Edit Mode)", 0.7, 0.7, 0.7)
          GameTooltip:Show()
        end)
        frame:SetScript("OnLeave", function(self)
          GameTooltip:Hide()
        end)
      else
        dprint("LibEditMode registration failed: %s", tostring(err))
        print("CMT: LibEditMode error: " .. tostring(err))
        print("CMT: Using Shift+drag fallback.")
      end
    end
  end
  
  -- Fallback: If LibEditMode not found, use Shift+drag with position saving
  if not hasLibEditMode then
    dprint("LibEditMode not found - using Shift+drag fallback with position saving")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    
    -- Load saved position if exists
    if CMT_DB.itemsTrackerPosition then
      local pos = CMT_DB.itemsTrackerPosition
      frame:ClearAllPoints()
      frame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or -200)
      dprint("Loaded saved Items tracker position")
    end
    
    frame:SetScript("OnDragStart", function(self)
      if IsShiftKeyDown() then
        self:StartMoving()
      end
    end)
    
    -- Store as method so child icons can call it
    frame.OnDragStop = function(self)
      self:StopMovingOrSizing()
      
      -- Save position
      local point, _, relativePoint, x, y = self:GetPoint()
      CMT_DB.itemsTrackerPosition = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
      }
      dprint("Saved Items tracker position: %s %.1f, %.1f", point, x, y)
    end
    
    frame:SetScript("OnDragStop", frame.OnDragStop)
    
    -- Tooltip to show how to move
    frame:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText("Items & Consumables Tracker", 1, 1, 1)
      GameTooltip:AddLine("Shift+drag to move", 0.7, 0.7, 0.7)
      GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)
  end
  
  return frame
end

local function LayoutItemsTracker()
  if not itemsTrackerFrame then return end
  
  -- Use the order from current spec's entry list
  local baseOrder = {}
  local specEntries = GetCurrentSpecEntries()
  
  if specEntries then
    -- Iterate in spec's entry order
    for _, entry in ipairs(specEntries) do
      if entry.type and entry.id then
        local key = entry.type .. "_" .. entry.id
        local iconFrame = customItemIcons[key]
        if iconFrame then
          table.insert(baseOrder, iconFrame)
        end
      end
    end
  end
  
  itemsTrackerFrame._CMT_baseOrder = baseOrder
  
  if #baseOrder > 0 then
    layoutCustomGrid(itemsTrackerFrame, "items", baseOrder)
    itemsTrackerFrame:Show()  -- Show tracker when entries exist
  else
    itemsTrackerFrame:SetSize(40, 40)
    itemsTrackerFrame:Hide()  -- Hide tracker when no entries
  end
  
  dprint("Laid out custom tracker with %d entries for current spec", #baseOrder)
end

local itemsEventFrame = CreateFrame("Frame")
itemsEventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
itemsEventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
itemsEventFrame:RegisterEvent("BAG_UPDATE")  -- Update when bags change
itemsEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")  -- Catch spell casts immediately
itemsEventFrame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
  if event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
    -- Spell was just cast - set cooldown without reading/comparing values
    C_Timer.After(0.1, function()
      for key, icon in pairs(customItemIcons) do
        if icon._CMT_entryType == "spell" and icon._CMT_entryID == spellID then
          -- Use pcall to attempt getting cooldown info
          local success, result = pcall(function()
            local info = C_Spell.GetSpellCooldown(spellID)
            if info and info.startTime and info.duration then
              -- Pass values directly to SetCooldown without comparing
              icon.cooldown:SetCooldown(info.startTime, info.duration)
              return true
            end
            return false
          end)
          -- If pcall succeeded and returned true, mark that we set a cooldown
          if success and result then
            icon._lastCooldownDuration = 1  -- Mark as having a cooldown (can't store actual value)
          end
        end
      end
    end)
  else
    -- Other events - update all
    UpdateAllCustomItemCooldowns()
  end
end)

C_Timer.NewTicker(0.5, UpdateAllCustomItemCooldowns)

dprint("Custom Items Tracking Module loaded")

-- ============================================================================
-- END CUSTOM ITEMS TRACKING SYSTEM
-- ============================================================================

-- ============================================================================
-- MASQUE INTEGRATION (v4.6.0)
-- ============================================================================
-- Provides optional integration with Masque button skinning addon.
-- When Masque is installed and enabled, CMT registers its icons with Masque
-- allowing users to apply custom skins to cooldown tracker icons.
-- NOTE: All functions are methods on MasqueModule table to avoid local variable limit

local MasqueModule = {
  API = nil,           -- Masque API reference
  groups = {},         -- Masque groups by tracker key
  registeredIcons = {} -- Track which icons are registered [icon] = trackerKey
}

-- Check if Masque is available
function MasqueModule.IsAvailable()
  if not LibStub then return false end
  local MSQ = LibStub("Masque", true)
  return MSQ ~= nil
end

-- Check if Masque controls visuals for a specific tracker (skip CMT texture/aspect modifications)
-- NOTE: Masque controls skin/appearance (textures, borders) but CMT should still handle:
-- - Size (SetSize)
-- - Scale (SetScale) 
-- - Opacity (SetAlpha)
-- - Position
-- We only skip: aspect ratio texture cropping (SetTexCoord), zoom, border alpha on Blizzard borders
function MasqueModule.ControlsVisualsForTracker(trackerKey)
  if not CMT_DB.masqueEnabled then return false end
  if not MasqueModule.IsAvailable() then return false end
  if not MasqueModule.API then return false end
  
  -- Check per-tracker setting
  local profile = GetCurrentProfile()
  if profile and profile[trackerKey] then
    if profile[trackerKey].masqueDisabled then
      return false
    end
  end
  
  return true
end

-- Check if Masque is enabled for a specific tracker
function MasqueModule.IsEnabledForTracker(trackerKey)
  if not CMT_DB.masqueEnabled then return false end
  if not MasqueModule.IsAvailable() then return false end
  
  -- Check per-tracker setting
  local profile = GetCurrentProfile()
  if profile and profile[trackerKey] then
    if profile[trackerKey].masqueDisabled then
      return false
    end
  end
  
  return true
end

-- Callback when Masque skin changes for a group
function MasqueModule.OnSkinChanged(group, skinID, gloss, backdrop, colors, disabled)
  -- Find which tracker this group belongs to
  local trackerKey = nil
  for key, g in pairs(MasqueModule.groups) do
    if g == group then
      trackerKey = key
      break
    end
  end
  
  if trackerKey then
    dprint("CMT Masque: Skin changed for '%s' to '%s' (disabled=%s)", trackerKey, tostring(skinID), tostring(disabled))
    
    -- Force a relayout to apply the new skin properly
    if relayoutOne then
      C_Timer.After(0.1, function()
        relayoutOne(trackerKey)
      end)
    end
  end
end

-- Initialize Masque groups for all trackers
function MasqueModule.Init()
  if not CMT_DB.masqueEnabled then return false end
  if not MasqueModule.IsAvailable() then return false end
  
  local MSQ = LibStub("Masque", true)
  if not MSQ then return false end
  
  MasqueModule.API = MSQ
  
  -- Create a group for each tracker with callbacks
  local trackerDisplayNames = {
    essential = "Essential Cooldowns",
    utility = "Utility Cooldowns",
    buffs = "Buff Tracker",
    items = "Custom Tracker"
  }
  
  for _, t in ipairs(TRACKERS) do
    local displayName = trackerDisplayNames[t.key] or t.displayName
    -- Create group with callback for skin changes
    local group = MSQ:Group("Cooldown Manager Tweaks", displayName, nil, MasqueModule.OnSkinChanged)
    MasqueModule.groups[t.key] = group
    dprint("CMT Masque: Created group for '%s'", displayName)
  end
  
  dprint("CMT Masque: Initialized %d groups", 4)
  return true
end

-- Get the regions table for a button (tells Masque where to find components)
function MasqueModule.GetRegions(button, trackerKey)
  if not button then return nil end
  
  local regions = {}
  
  -- Icon texture - try multiple common locations
  regions.Icon = button.Icon or button.icon or (button.GetRegions and select(1, button:GetRegions()))
  
  -- Cooldown frame
  regions.Cooldown = button.cooldown or button.Cooldown
  
  -- Normal texture (border) - Blizzard icons have this
  if button.GetNormalTexture then
    regions.Normal = button:GetNormalTexture()
  end
  
  -- Pushed texture (when clicked)
  if button.GetPushedTexture then
    regions.Pushed = button:GetPushedTexture()
  end
  
  -- Highlight texture (on mouseover)
  if button.GetHighlightTexture then
    regions.Highlight = button:GetHighlightTexture()
  end
  
  -- Count text (stack count)
  regions.Count = button.count or button.Count
  
  -- Duration text (for buffs)
  regions.Duration = button.duration or button.Duration
  
  -- Icon border (quality color)
  regions.IconBorder = button.IconBorder
  
  return regions
end

-- Register a single icon with Masque
function MasqueModule.RegisterIcon(icon, trackerKey)
  if not MasqueModule.API then return false end
  if not CMT_DB.masqueEnabled then return false end
  if not icon then return false end
  
  -- Check per-tracker setting
  if not MasqueModule.IsEnabledForTracker(trackerKey) then
    return false
  end
  
  local group = MasqueModule.groups[trackerKey]
  if not group then return false end
  
  -- Don't register the same icon twice
  if MasqueModule.registeredIcons[icon] == trackerKey then
    return true
  end
  
  -- If icon was registered with a different group, remove it first
  if MasqueModule.registeredIcons[icon] then
    local oldGroup = MasqueModule.groups[MasqueModule.registeredIcons[icon]]
    if oldGroup then
      oldGroup:RemoveButton(icon)
    end
  end
  
  -- Get regions for the button
  local regions = MasqueModule.GetRegions(icon, trackerKey)
  
  -- Determine button type
  -- Blizzard cooldown icons are aura-like (buff/cooldown display)
  local buttonType = "Aura"
  
  -- Custom tracker items might be action-like
  if trackerKey == "items" then
    buttonType = "Action"
  end
  
  -- Add button to group
  group:AddButton(icon, regions, buttonType)
  MasqueModule.registeredIcons[icon] = trackerKey
  
  dprint("CMT Masque: Registered icon with group '%s'", trackerKey)
  return true
end

-- Unregister an icon from Masque
function MasqueModule.UnregisterIcon(icon)
  if not MasqueModule.API then return end
  if not icon then return end
  
  local trackerKey = MasqueModule.registeredIcons[icon]
  if not trackerKey then return end
  
  local group = MasqueModule.groups[trackerKey]
  if group then
    group:RemoveButton(icon)
  end
  
  MasqueModule.registeredIcons[icon] = nil
  dprint("CMT Masque: Unregistered icon from group '%s'", trackerKey)
end

-- Register all icons for a tracker
function MasqueModule.RegisterTracker(trackerKey)
  if not MasqueModule.API then return end
  if not CMT_DB.masqueEnabled then return end
  
  -- Check per-tracker setting
  if not MasqueModule.IsEnabledForTracker(trackerKey) then
    dprint("CMT Masque: Skipping tracker '%s' - Masque disabled for this tracker", trackerKey)
    return
  end
  
  local trackerInfo = getTrackerInfoByKey(trackerKey)
  if not trackerInfo then return end
  
  local viewer = _G[trackerInfo.name]
  if not viewer then return end
  
  -- Get all icons (from baseOrder if available, otherwise collect)
  local icons = viewer._CMT_baseOrder or {}
  
  -- If no baseOrder, try to collect icons
  if #icons == 0 and viewer.GetNumChildren then
    local n = viewer:GetNumChildren() or 0
    for i = 1, n do
      local child = select(i, viewer:GetChildren())
      if child and child.Icon or child.icon or child.cooldown or child.Cooldown then
        table.insert(icons, child)
      end
    end
  end
  
  -- Register each icon
  local count = 0
  for _, icon in ipairs(icons) do
    if MasqueModule.RegisterIcon(icon, trackerKey) then
      count = count + 1
    end
  end
  
  dprint("CMT Masque: Registered %d icons for tracker '%s'", count, trackerKey)
end

-- Unregister all icons for a specific tracker
function MasqueModule.UnregisterTracker(trackerKey)
  if not MasqueModule.API then return end
  
  local group = MasqueModule.groups[trackerKey]
  if not group then return end
  
  -- Find and remove all icons registered to this tracker
  local toRemove = {}
  for icon, key in pairs(MasqueModule.registeredIcons) do
    if key == trackerKey then
      table.insert(toRemove, icon)
    end
  end
  
  for _, icon in ipairs(toRemove) do
    group:RemoveButton(icon)
    MasqueModule.registeredIcons[icon] = nil
  end
  
  dprint("CMT Masque: Unregistered %d icons from tracker '%s'", #toRemove, trackerKey)
end

-- Register custom tracker icons (items/spells)
function MasqueModule.RegisterCustomTracker()
  if not MasqueModule.API then return end
  if not CMT_DB.masqueEnabled then return end
  
  -- Check per-tracker setting
  if not MasqueModule.IsEnabledForTracker("items") then
    dprint("CMT Masque: Skipping custom tracker - Masque disabled for this tracker")
    return
  end
  
  local count = 0
  for key, icon in pairs(customItemIcons) do
    if MasqueModule.RegisterIcon(icon, "items") then
      count = count + 1
    end
  end
  
  dprint("CMT Masque: Registered %d custom tracker icons", count)
end

-- Re-skin all registered icons (called when user changes skin in Masque)
function MasqueModule.Reskin()
  if not MasqueModule.API then return end
  
  for trackerKey, group in pairs(MasqueModule.groups) do
    group:ReSkin()
  end
  
  dprint("CMT Masque: Re-skinned all groups")
end

-- Check if Masque is enabled globally
function MasqueModule.IsEnabled()
  return CMT_DB.masqueEnabled and MasqueModule.IsAvailable()
end

-- Save current aspect ratios and visual settings before enabling Masque
function MasqueModule.SaveTrackerSettings()
  local profile = GetCurrentProfile()
  if not profile then return end
  
  for _, t in ipairs(TRACKERS) do
    local settings = profile[t.key]
    if settings then
      -- Only save if not already saved (don't overwrite previous save)
      if settings.masqueSavedAspect == nil then
        settings.masqueSavedAspect = settings.aspectRatio or "1:1"
        settings.masqueSavedZoom = settings.zoom or 1.0
        settings.masqueSavedBorderAlpha = settings.borderAlpha or 1.0
        settings.masqueSavedCustomW = settings.customAspectW
        settings.masqueSavedCustomH = settings.customAspectH
        dprint("CMT Masque: Saved settings for '%s': aspect=%s, zoom=%s", t.key, tostring(settings.masqueSavedAspect), tostring(settings.masqueSavedZoom))
      end
    end
  end
end

-- Reset to square aspect ratio for Masque compatibility
function MasqueModule.ApplyMasqueDefaults()
  local profile = GetCurrentProfile()
  if not profile then return end
  
  for _, t in ipairs(TRACKERS) do
    -- Skip trackers that have Masque disabled
    if MasqueModule.IsEnabledForTracker(t.key) then
      local settings = profile[t.key]
      if settings then
        settings.aspectRatio = "1:1"
        settings.zoom = 1.0
        -- Keep border alpha as user may still want to adjust it
        dprint("CMT Masque: Applied defaults for '%s'", t.key)
      end
    end
  end
end

-- Restore saved settings when disabling Masque
function MasqueModule.RestoreTrackerSettings()
  local profile = GetCurrentProfile()
  if not profile then return end
  
  for _, t in ipairs(TRACKERS) do
    local settings = profile[t.key]
    if settings and settings.masqueSavedAspect then
      settings.aspectRatio = settings.masqueSavedAspect
      settings.zoom = settings.masqueSavedZoom or 1.0
      settings.borderAlpha = settings.masqueSavedBorderAlpha or 1.0
      if settings.masqueSavedCustomW then
        settings.customAspectW = settings.masqueSavedCustomW
      end
      if settings.masqueSavedCustomH then
        settings.customAspectH = settings.masqueSavedCustomH
      end
      
      -- Clear saved values
      settings.masqueSavedAspect = nil
      settings.masqueSavedZoom = nil
      settings.masqueSavedBorderAlpha = nil
      settings.masqueSavedCustomW = nil
      settings.masqueSavedCustomH = nil
      
      dprint("CMT Masque: Restored settings for '%s': aspect=%s", t.key, tostring(settings.aspectRatio))
    end
  end
end

-- Enable Masque support
function MasqueModule.Enable()
  if not MasqueModule.IsAvailable() then
    print("|cff00ff00CMT:|r Masque not installed - skin support unavailable")
    return false
  end
  
  -- Save current settings before enabling
  MasqueModule.SaveTrackerSettings()
  
  CMT_DB.masqueEnabled = true
  
  if not MasqueModule.API then
    if not MasqueModule.Init() then
      return false
    end
  end
  
  -- Apply Masque-friendly defaults (square icons)
  MasqueModule.ApplyMasqueDefaults()
  
  -- Register all existing icons
  for _, t in ipairs(TRACKERS) do
    if t.key == "items" then
      MasqueModule.RegisterCustomTracker()
    else
      MasqueModule.RegisterTracker(t.key)
    end
  end
  
  -- Show reload confirmation popup
  StaticPopupDialogs["CMT_MASQUE_RELOAD"] = {
    text = "Enabling Masque skinning requires a UI reload to take full effect.\n\nReload now?",
    button1 = "Reload",
    button2 = "Later",
    OnAccept = function()
      ReloadUI()
    end,
    OnCancel = function()
      print("|cff00ff00CMT:|r Masque enabled - reload UI when ready for changes to take effect")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }
  StaticPopup_Show("CMT_MASQUE_RELOAD")
  
  return true
end

-- Disable Masque support
function MasqueModule.Disable()
  CMT_DB.masqueEnabled = false
  
  -- Restore saved settings
  MasqueModule.RestoreTrackerSettings()
  
  if MasqueModule.API then
    -- Remove all icons from Masque groups (restores default appearance)
    for icon, trackerKey in pairs(MasqueModule.registeredIcons) do
      local group = MasqueModule.groups[trackerKey]
      if group then
        group:RemoveButton(icon)
      end
    end
    
    MasqueModule.registeredIcons = {}
  end
  
  -- Trigger relayout to apply restored settings
  C_Timer.After(0.2, function()
    for _, t in ipairs(TRACKERS) do
      if relayoutOne then relayoutOne(t.key) end
    end
  end)
  
  print("|cff00ff00CMT:|r Masque support |cffff0000disabled|r - using default icon appearance")
end

-- Toggle Masque support
function MasqueModule.Toggle()
  if CMT_DB.masqueEnabled then
    MasqueModule.Disable()
  else
    MasqueModule.Enable()
  end
end

-- Enable Masque for a specific tracker
function MasqueModule.EnableForTracker(trackerKey)
  local profile = GetCurrentProfile()
  if not profile or not profile[trackerKey] then return end
  
  local settings = profile[trackerKey]
  
  -- Save current settings if not already saved
  if settings.masqueSavedAspect == nil then
    settings.masqueSavedAspect = settings.aspectRatio or "1:1"
    settings.masqueSavedZoom = settings.zoom or 1.0
    settings.masqueSavedBorderAlpha = settings.borderAlpha or 1.0
    settings.masqueSavedCustomW = settings.customAspectW
    settings.masqueSavedCustomH = settings.customAspectH
  end
  
  -- Apply Masque defaults
  settings.aspectRatio = "1:1"
  settings.zoom = 1.0
  settings.masqueDisabled = false
  
  -- Register icons
  if trackerKey == "items" then
    MasqueModule.RegisterCustomTracker()
  else
    MasqueModule.RegisterTracker(trackerKey)
  end
  
  -- Show reload confirmation popup
  StaticPopupDialogs["CMT_MASQUE_RELOAD"] = {
    text = "Enabling Masque skinning requires a UI reload to take full effect.\n\nReload now?",
    button1 = "Reload",
    button2 = "Later",
    OnAccept = function()
      ReloadUI()
    end,
    OnCancel = function()
      print("|cff00ff00CMT:|r Masque enabled for " .. trackerKey .. " - reload UI when ready for changes to take effect")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }
  StaticPopup_Show("CMT_MASQUE_RELOAD")
end

-- Disable Masque for a specific tracker
function MasqueModule.DisableForTracker(trackerKey)
  local profile = GetCurrentProfile()
  if not profile or not profile[trackerKey] then return end
  
  local settings = profile[trackerKey]
  settings.masqueDisabled = true
  
  -- Restore saved settings
  if settings.masqueSavedAspect then
    settings.aspectRatio = settings.masqueSavedAspect
    settings.zoom = settings.masqueSavedZoom or 1.0
    settings.borderAlpha = settings.masqueSavedBorderAlpha or 1.0
    if settings.masqueSavedCustomW then
      settings.customAspectW = settings.masqueSavedCustomW
    end
    if settings.masqueSavedCustomH then
      settings.customAspectH = settings.masqueSavedCustomH
    end
    
    -- Clear saved values
    settings.masqueSavedAspect = nil
    settings.masqueSavedZoom = nil
    settings.masqueSavedBorderAlpha = nil
    settings.masqueSavedCustomW = nil
    settings.masqueSavedCustomH = nil
  end
  
  -- Unregister icons for this tracker
  MasqueModule.UnregisterTracker(trackerKey)
  
  -- Relayout to apply restored settings
  if relayoutOne then
    C_Timer.After(0.1, function()
      relayoutOne(trackerKey)
      -- Also refresh preview if it's showing this tracker
      if previewPanel and previewPanel:IsShown() and previewCurrentKey == trackerKey then
        PopulatePreview(trackerKey)
      end
    end)
  end
  
  print("|cff00ff00CMT:|r Masque |cffff0000disabled|r for " .. trackerKey)
end

-- Toggle Masque for a specific tracker
function MasqueModule.ToggleForTracker(trackerKey)
  if MasqueModule.IsEnabledForTracker(trackerKey) then
    MasqueModule.DisableForTracker(trackerKey)
  else
    MasqueModule.EnableForTracker(trackerKey)
  end
end

-- Hook into icon registration - called when CMT creates/discovers icons
function MasqueModule.OnIconDiscovered(icon, trackerKey)
  if MasqueModule.IsEnabledForTracker(trackerKey) then
    MasqueModule.RegisterIcon(icon, trackerKey)
  end
end

-- Hook into custom tracker icon creation
function MasqueModule.OnCustomIconCreated(icon)
  if MasqueModule.IsEnabledForTracker("items") then
    MasqueModule.RegisterIcon(icon, "items")
  end
end

-- Make globally accessible
_G.CMT_MasqueModule = MasqueModule

dprint("Masque Integration Module loaded")

-- ============================================================================
-- END MASQUE INTEGRATION
-- ============================================================================

-- ============================================================================
-- BUFF ICON STYLING SYSTEM (v3.1.1)
-- ============================================================================
-- Styles buff icons based on active/inactive state. Works with Blizzard's
-- native "Hide When Inactive" setting in Edit Mode. When buffs are visible
-- but inactive (cooldown running), we desaturate and fade them.

-- Forward declarations: GetSetting and SetSetting will be defined later
local GetSetting
local SetSetting

local UPDATE_INTERVAL = 0.1  -- Update 10 times per second
-- --------------------------------------------------------------------
local function isProtectedTree(root)
  if not root or not root.IsProtected then return false end
  if root:IsProtected() then return true end
  if root.GetNumChildren then
    local n = root:GetNumChildren()
    for i = 1, (n or 0) do
      local c = select(i, root:GetChildren())
      if c and c.IsProtected and c:IsProtected() then return true end
    end
  end
  return false
end

local function r2(x) if not x then return 0 end return math.floor(x*100+0.5)/100 end

local function sig(viewer)
  if not viewer or not viewer.GetNumChildren then return "" end
  local parts = {}
  local n = viewer:GetNumChildren() or 0
  for i = 1, n do
    local f = select(i, viewer:GetChildren())
    if f and f.IsShown and f:IsShown() and f.GetLeft then
      -- Include spell ID in signature to detect when abilities swap positions
      local spellID = f.spellID or 0
      parts[#parts+1] = r2(f:GetLeft() or 0) .. ":" .. r2(f:GetTop() or 0) .. ":" ..
                        r2(f:GetWidth() or 0) .. "x" .. r2(f:GetHeight() or 0) .. ":" .. spellID
    end
  end
  return table.concat(parts, "|")
end

local function setApplying(viewer, on)
  viewer._CMT_applying = on and true or nil
  if on then
    viewer._CMT_applyingStartTime = GetTime()
  else
    viewer._CMT_applyingStartTime = nil
  end
end

-- Apply border/frame alpha to an icon (controls border visibility)
local function applyBorderAlpha(icon, alpha)
  if not icon then return end
  
  alpha = alpha or 1.0
  
  -- Find and set alpha on border/frame elements
  -- These are the common frame elements that create the visible border
  
  -- Try common border texture names
  if icon.Border then
    icon.Border:SetAlpha(alpha)
  end
  
  if icon.border then
    icon.border:SetAlpha(alpha)
  end
  
  if icon.IconBorder then
    icon.IconBorder:SetAlpha(alpha)
  end
  
  -- Some icons use NormalTexture for the border
  if icon.GetNormalTexture then
    local normalTexture = icon:GetNormalTexture()
    if normalTexture then
      normalTexture:SetAlpha(alpha)
    end
  end
  
  -- Search through all regions for textures that might be borders
  -- (excluding the main icon texture which we want to keep visible)
  if icon.GetRegions then
    for _, region in ipairs({icon:GetRegions()}) do
      if region and region:GetObjectType() == "Texture" then
        local texturePath = region:GetTexture()
        -- If it's a border texture (not the spell icon), adjust alpha
        if texturePath and type(texturePath) == "string" then
          if texturePath:find("Border") or texturePath:find("border") or 
             texturePath:find("Highlight") or texturePath:find("Normal") then
            region:SetAlpha(alpha)
          end
        elseif texturePath and type(texturePath) == "number" then
          -- Border textures are often file IDs, but we can't easily identify them
          -- So we check if this is NOT the Icon texture (which we already handled)
          if region ~= icon.Icon and region ~= icon.icon then
            -- This might be a border, set its alpha
            region:SetAlpha(alpha)
          end
        end
      end
    end
  end
end

-- Scale border textures proportionally with icon size
-- scale: ratio of current icon size to default (40px), e.g., 0.5 for 20px icons
-- Approach: Instead of using SetSize(), we keep the frame at 40px and use SetScale()
-- This naturally scales the borders proportionally
-- Returns the effective visual size for positioning calculations
local function applyBorderScale(icon, scale, iconWidth, iconHeight)
  if not icon then return end
  
  -- Default to 1.0 (no scaling)
  scale = scale or 1.0
  
  -- Clamp scale to reasonable range  
  if scale < 0.25 then scale = 0.25 end
  if scale > 2.0 then scale = 2.0 end
  
  -- For scale of 1.0, nothing special needed
  if math.abs(scale - 1.0) < 0.01 then
    if icon._CMT_borderScaleApplied then
      icon:SetScale(1.0)
      icon._CMT_borderScaleApplied = nil
    end
    return
  end
  
  -- Apply scale to the icon frame
  -- The frame should already be sized to 40x40 (or the base size)
  -- SetScale will shrink/grow everything proportionally including borders
  icon:SetScale(scale)
  icon._CMT_borderScaleApplied = true
end

-- Apply cooldown text scale to an icon
local function applyCooldownTextScale(icon, scale)
  if not icon then return end
  
  scale = scale or 1.0
  
  -- Method 1: Direct cooldown.text (OmniCC style)
  local cd = icon.cooldown or icon.Cooldown
  if cd then
    if cd.text then
      -- Store original font size on first application
      if not cd.text._CMT_origFontSize then
        local font, size, flags = cd.text:GetFont()
        if font and size then
          cd.text._CMT_origFontSize = size
          cd.text._CMT_origFont = font
          cd.text._CMT_origFlags = flags
        end
      end
      -- Apply scale to original size
      if cd.text._CMT_origFontSize then
        cd.text:SetFont(cd.text._CMT_origFont, cd.text._CMT_origFontSize * scale, cd.text._CMT_origFlags)
      end
    end
    
    -- Method 2: Check for Text fontstring in cooldown frame
    if cd.Text then
      if not cd.Text._CMT_origFontSize then
        local font, size, flags = cd.Text:GetFont()
        if font and size then
          cd.Text._CMT_origFontSize = size
          cd.Text._CMT_origFont = font
          cd.Text._CMT_origFlags = flags
        end
      end
      if cd.Text._CMT_origFontSize then
        cd.Text:SetFont(cd.Text._CMT_origFont, cd.Text._CMT_origFontSize * scale, cd.Text._CMT_origFlags)
      end
    end
    
    -- Method 3: Search cooldown frame regions for fontstrings
    if cd.GetRegions then
      for _, region in ipairs({cd:GetRegions()}) do
        if region and region:GetObjectType() == "FontString" then
          if not region._CMT_origFontSize then
            local font, size, flags = region:GetFont()
            if font and size then
              region._CMT_origFontSize = size
              region._CMT_origFont = font
              region._CMT_origFlags = flags
            end
          end
          if region._CMT_origFontSize then
            region:SetFont(region._CMT_origFont, region._CMT_origFontSize * scale, region._CMT_origFlags)
          end
        end
      end
    end
  end
  
  -- Method 4: Search icon frame itself for cooldown text fontstrings
  if icon.GetRegions then
    for _, region in ipairs({icon:GetRegions()}) do
      if region and region:GetObjectType() == "FontString" then
        -- Check if this looks like a cooldown text (typically shows numbers/time)
        local text = region:GetText()
        if text and (text:match("%d") or text == "") then
          if not region._CMT_origFontSize then
            local font, size, flags = region:GetFont()
            if font and size then
              region._CMT_origFontSize = size
              region._CMT_origFont = font
              region._CMT_origFlags = flags
            end
          end
          if region._CMT_origFontSize then
            region:SetFont(region._CMT_origFont, region._CMT_origFontSize * scale, region._CMT_origFlags)
          end
        end
      end
    end
  end
end

-- Apply count/stack text scale to an icon
local function applyCountTextScale(icon, scale)
  if not icon then return end
  
  scale = scale or 1.0
  
  -- Method 1: Direct Count property (Blizzard buff icons)
  local countText = icon.Count or icon.count
  if countText and countText.GetObjectType and countText:GetObjectType() == "FontString" then
    if not countText._CMT_origCountFontSize then
      local font, size, flags = countText:GetFont()
      if font and size then
        countText._CMT_origCountFontSize = size
        countText._CMT_origCountFont = font
        countText._CMT_origCountFlags = flags
      end
    end
    if countText._CMT_origCountFontSize then
      countText:SetFont(countText._CMT_origCountFont, countText._CMT_origCountFontSize * scale, countText._CMT_origCountFlags)
    end
    return -- Found and applied, done
  end
  
  -- Helper to check if position is count-like (bottom area)
  local function isCountPosition(fontString)
    if not fontString or not fontString.GetPoint then return false end
    local point = fontString:GetPoint()
    if not point then return false end
    -- point could be a string like "BOTTOMRIGHT" or something else
    if type(point) == "string" then
      return point:find("BOTTOM") or point:find("RIGHT")
    end
    return false
  end
  
  -- Method 2: Search icon regions for count-like FontStrings
  -- Count text is typically in bottom-right, shows pure integers (no decimals like cooldown timers)
  if icon.GetRegions then
    for _, region in ipairs({icon:GetRegions()}) do
      if region and region:GetObjectType() == "FontString" then
        local text = region:GetText()
        -- Count text shows pure integers (1, 2, 5, 10, etc.)
        -- Cooldown text shows decimals or time format (5.2, 1:30, etc.)
        if text and text:match("^%d+$") then
          if isCountPosition(region) then
            if not region._CMT_origCountFontSize then
              local font, size, flags = region:GetFont()
              if font and size then
                region._CMT_origCountFontSize = size
                region._CMT_origCountFont = font
                region._CMT_origCountFlags = flags
              end
            end
            if region._CMT_origCountFontSize then
              region:SetFont(region._CMT_origCountFont, region._CMT_origCountFontSize * scale, region._CMT_origCountFlags)
            end
          end
        end
      end
    end
  end
  
  -- Method 3: Check children frames for count text (some icons nest it)
  if icon.GetChildren then
    for _, child in ipairs({icon:GetChildren()}) do
      -- Check for Count property on child
      local childCount = child.Count or child.count
      if childCount and childCount.GetObjectType and childCount:GetObjectType() == "FontString" then
        if not childCount._CMT_origCountFontSize then
          local font, size, flags = childCount:GetFont()
          if font and size then
            childCount._CMT_origCountFontSize = size
            childCount._CMT_origCountFont = font
            childCount._CMT_origCountFlags = flags
          end
        end
        if childCount._CMT_origCountFontSize then
          childCount:SetFont(childCount._CMT_origCountFont, childCount._CMT_origCountFontSize * scale, childCount._CMT_origCountFlags)
        end
      end
      
      -- Also check child regions
      if child and child.GetRegions then
        for _, region in ipairs({child:GetRegions()}) do
          if region and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            if text and text:match("^%d+$") then
              if isCountPosition(region) then
                if not region._CMT_origCountFontSize then
                  local font, size, flags = region:GetFont()
                  if font and size then
                    region._CMT_origCountFontSize = size
                    region._CMT_origCountFont = font
                    region._CMT_origCountFlags = flags
                  end
                end
                if region._CMT_origCountFontSize then
                  region:SetFont(region._CMT_origCountFont, region._CMT_origCountFontSize * scale, region._CMT_origCountFlags)
                end
              end
            end
          end
        end
      end
    end
  end
end

-- Apply texture zoom to an icon (zooms into the center of the texture)
local function applyIconAspectAndZoom(icon, aspectRatio, zoomLevel)
  if not icon then return end
  
  -- Find the icon texture - try common locations
  local texture = nil
  
  -- Method 1: Direct Icon property
  if icon.Icon and icon.Icon.SetTexCoord then
    texture = icon.Icon
  -- Method 2: Check for common texture names
  elseif icon.icon and icon.icon.SetTexCoord then
    texture = icon.icon
  -- Method 3: Search for first texture region
  else
    for _, region in ipairs({icon:GetRegions()}) do
      if region and region:GetObjectType() == "Texture" and region.SetTexCoord then
        texture = region
        break
      end
    end
  end
  
  if texture and texture.SetTexCoord then
    -- Parse aspect ratio (supports both "W:H" preset and "WxH" custom formats)
    local aspectW, aspectH = ParseAspectRatio(aspectRatio)
    
    -- Calculate which dimension to crop
    -- If aspectW > aspectH (like 16:9), we crop top/bottom
    -- If aspectH > aspectW (like 9:16), we crop left/right
    local cropHorizontal = aspectH > aspectW
    local cropVertical = aspectW > aspectH
    
    -- Start with full texture (0 to 1)
    local left, right, top, bottom = 0, 1, 0, 1
    
    -- Apply aspect ratio cropping first
    if cropVertical then
      -- Wider than tall (16:9, 21:9, 4:3) - crop top/bottom
      local targetRatio = aspectW / aspectH
      local cropAmount = 1.0 - (1.0 / targetRatio)
      local offset = cropAmount / 2.0
      top = offset
      bottom = 1.0 - offset
    elseif cropHorizontal then
      -- Taller than wide (9:16, 3:4) - crop left/right
      local targetRatio = aspectH / aspectW
      local cropAmount = 1.0 - (1.0 / targetRatio)
      local offset = cropAmount / 2.0
      left = offset
      right = 1.0 - offset
    end
    
    -- Apply zoom on top of aspect ratio
    if zoomLevel and zoomLevel > 1.0 then
      -- Calculate how much of the already-cropped texture to show
      local visibleSize = 1.0 / zoomLevel
      
      -- Calculate current visible range after aspect crop
      local currentWidth = right - left
      local currentHeight = bottom - top
      
      -- Zoom into center of visible area
      local zoomedWidth = currentWidth * visibleSize
      local zoomedHeight = currentHeight * visibleSize
      
      local centerX = (left + right) / 2.0
      local centerY = (top + bottom) / 2.0
      
      left = centerX - (zoomedWidth / 2.0)
      right = centerX + (zoomedWidth / 2.0)
      top = centerY - (zoomedHeight / 2.0)
      bottom = centerY + (zoomedHeight / 2.0)
    end
    
    -- Apply final texture coordinates
    texture:SetTexCoord(left, right, top, bottom)
  end
end

-- Keep old function name for compatibility but redirect to new one
local function applyIconZoom(icon, zoomLevel)
  applyIconAspectAndZoom(icon, "1:1", zoomLevel)
end

-- Border color presets (defined early for use in applyPerIconOverrides)
local BORDER_COLOR_PRESETS = {
  { name = "White", color = {1, 1, 1} },
  { name = "Gold", color = {1, 0.82, 0} },
  { name = "Red", color = {1, 0.2, 0.2} },
  { name = "Green", color = {0.2, 1, 0.2} },
  { name = "Blue", color = {0.3, 0.5, 1} },
  { name = "Purple", color = {0.7, 0.3, 1} },
  { name = "Orange", color = {1, 0.5, 0} },
  { name = "Black", color = {0, 0, 0} },
}

-- Apply or remove a custom uniform border overlay on an icon
-- borderColor: color name from BORDER_COLOR_PRESETS, or nil to remove border
-- borderWidth: width in pixels (1-6)
-- borderAlpha: opacity (0-1)
local function applyCustomBorder(icon, borderColor, borderWidth, borderAlpha)
  if not icon then return end
  
  -- Get or create border frame
  local borderFrame = icon._CMT_customBorder
  
  if not borderColor then
    -- Remove border
    if borderFrame then
      borderFrame:Hide()
    end
    return
  end
  
  -- Find the color
  local color = {1, 1, 1}  -- Default white
  for _, preset in ipairs(BORDER_COLOR_PRESETS) do
    if preset.name == borderColor and preset.color then
      color = preset.color
      break
    end
  end
  
  local width = borderWidth or 2
  local alpha = borderAlpha or 1.0
  
  -- Create border frame if needed
  if not borderFrame then
    borderFrame = CreateFrame("Frame", nil, icon, "BackdropTemplate")
    borderFrame:SetFrameLevel(icon:GetFrameLevel() + 5)
    icon._CMT_customBorder = borderFrame
  end
  
  -- Position border frame to surround icon
  borderFrame:ClearAllPoints()
  borderFrame:SetPoint("TOPLEFT", icon, "TOPLEFT", -width, width)
  borderFrame:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", width, -width)
  
  -- Set backdrop with border only (no background)
  borderFrame:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = width,
  })
  borderFrame:SetBackdropBorderColor(color[1], color[2], color[3], alpha)
  borderFrame:Show()
end

-- Apply per-icon overrides to a live tracker icon
-- Returns the effective settings (after merging override with defaults)
-- Also returns position adjustment (nudgeX, nudgeY) that caller should apply
local function applyPerIconOverrides(icon, trackerKey, identifier, baseIconSize, baseAspectRatio, baseZoom, baseBorderAlpha, isBuffActive)
  if not icon or not identifier then return nil end
  
  -- Skip visual modifications if Masque controls this tracker
  local masqueControlsVisuals = MasqueModule and MasqueModule.ControlsVisualsForTracker and MasqueModule.ControlsVisualsForTracker(trackerKey)
  if masqueControlsVisuals then
    -- Still return override info for positioning/nudge, but skip visual changes
    local override = GetIconOverride(trackerKey, identifier)
    if not override then return nil end
    
    local settings
    if trackerKey == "buffs" then
      local stateKey = isBuffActive and "activeState" or "inactiveState"
      settings = override[stateKey] or {}
    else
      settings = override
    end
    
    -- When Masque is active, apply size/opacity/nudge but skip texture coord changes
    local sizeMultiplier = settings.sizeMultiplier or 1.0
    local opacity = settings.opacity or 1.0
    local nudgeX = settings.nudgeX or 0
    local nudgeY = settings.nudgeY or 0
    
    -- Apply size using scale (Masque uses 40px base)
    if sizeMultiplier ~= 1.0 then
      icon:SetSize(40, 40)
      icon:SetScale((baseIconSize * sizeMultiplier) / 40)
    end
    
    -- Apply opacity
    icon:SetAlpha(opacity)
    
    -- Apply desaturate (this doesn't conflict with Masque)
    if settings.desaturate then
      local texture = icon.Icon or icon.icon
      if texture and texture.SetDesaturated then
        texture:SetDesaturated(true)
      end
    end
    
    return {
      nudgeX = nudgeX,
      nudgeY = nudgeY,
      sizeMultiplier = sizeMultiplier,
    }
  end
  
  local override = GetIconOverride(trackerKey, identifier)
  if not override then return nil end
  
  -- For buffs tracker, get state-specific settings
  local settings
  if trackerKey == "buffs" then
    local stateKey = isBuffActive and "activeState" or "inactiveState"
    settings = override[stateKey] or {}
  else
    settings = override
  end
  
  -- Calculate final values with fallbacks to tracker defaults
  local sizeMultiplier = settings.sizeMultiplier or 1.0
  local opacity = settings.opacity or 1.0
  local iconZoom = settings.zoomOverride or baseZoom
  local iconAspect = settings.aspectOverride or baseAspectRatio
  local iconDesaturate = settings.desaturate or false
  local nudgeX = settings.nudgeX or 0
  local nudgeY = settings.nudgeY or 0
  
  -- Calculate icon dimensions with size multiplier
  local finalSize = baseIconSize * sizeMultiplier
  local iconWidth, iconHeight = finalSize, finalSize
  
  -- Parse aspect ratio for sizing (supports both preset and custom formats)
  if iconAspect and iconAspect ~= "1:1" then
    local aspectW, aspectH = ParseAspectRatio(iconAspect)
    if aspectW and aspectH and aspectW > 0 and aspectH > 0 then
      if aspectW > aspectH then
        iconWidth = finalSize
        iconHeight = (finalSize * aspectH) / aspectW
      elseif aspectH > aspectW then
        iconWidth = (finalSize * aspectW) / aspectH
        iconHeight = finalSize
      end
    end
  end
  
  -- Apply size
  icon:SetSize(iconWidth, iconHeight)
  
  -- Apply opacity
  icon:SetAlpha(opacity)
  
  -- Apply zoom and aspect ratio texture cropping
  applyIconAspectAndZoom(icon, iconAspect, iconZoom)
  
  -- Apply custom border (new uniform border system)
  if settings.borderColor then
    applyCustomBorder(icon, settings.borderColor, settings.borderWidth, settings.borderAlpha)
  else
    applyCustomBorder(icon, nil)  -- Remove any existing border
  end
  
  -- Apply desaturation
  local texture = icon.Icon or icon.icon
  if not texture then
    for _, region in ipairs({icon:GetRegions()}) do
      if region and region:GetObjectType() == "Texture" and region.SetDesaturated then
        texture = region
        break
      end
    end
  end
  if texture and texture.SetDesaturated then
    texture:SetDesaturated(iconDesaturate)
  end
  
  -- Apply timer (cooldown) text scale and color
  local timerScale = settings.timerScale
  local timerColor = settings.timerColor
  if timerScale or timerColor then
    local cooldown = icon.Cooldown or icon.cooldown
    if cooldown then
      -- Find the cooldown text element
      for _, region in ipairs({cooldown:GetRegions()}) do
        if region and region:GetObjectType() == "FontString" then
          if timerScale then
            local font, size, flags = region:GetFont()
            if font and size then
              -- Store original size if not stored
              if not region._CMT_originalSize then
                region._CMT_originalSize = size
              end
              region:SetFont(font, region._CMT_originalSize * timerScale, flags)
            end
          end
          if timerColor then
            region:SetTextColor(timerColor[1], timerColor[2], timerColor[3], 1)
          end
          break
        end
      end
    end
  end
  
  -- Apply count (stack) text scale and color
  local countScale = settings.countScale
  local countColor = settings.countColor
  if countScale or countColor then
    local countText = icon.Count or icon.count
    if countText and countText:GetObjectType() == "FontString" then
      if countScale then
        local font, size, flags = countText:GetFont()
        if font and size then
          -- Store original size if not stored
          if not countText._CMT_originalSize then
            countText._CMT_originalSize = size
          end
          countText:SetFont(font, countText._CMT_originalSize * countScale, flags)
        end
      end
      if countColor then
        countText:SetTextColor(countColor[1], countColor[2], countColor[3], 1)
      end
    end
  end
  
  return {
    nudgeX = nudgeX,
    nudgeY = nudgeY,
    iconWidth = iconWidth,
    iconHeight = iconHeight,
    sizeMultiplier = sizeMultiplier,
    timerScale = timerScale,
    timerColor = timerColor,
    countScale = countScale,
    countColor = countColor
  }
end

-- GetCurrentProfile is now defined early in the file (after getTrackerInfoByKey)

GetSetting = function(key, name)
  local profile = GetCurrentProfile()
  local value = nil
  if profile[key] and profile[key][name] ~= nil then
    value = profile[key][name]
  end
  -- Debug: Show what we're retrieving
  if DEBUG_MODE then
    dprint("CMT: GetSetting(%s, %s) -> %s from profile '%s'", 
      tostring(key), tostring(name), tostring(value), CMT_CharDB.currentProfile or "Default")
  end
  return value
end

SetSetting = function(key, name, val)
  local profile = GetCurrentProfile()
  profile[key] = profile[key] or {}
  profile[key][name] = val
  
  -- Verify the value is actually in CMT_DB (only log errors)
  if DEBUG_MODE then
    local profileName = CMT_CharDB.currentProfile or "Default"
    local verifyValue = CMT_DB.profiles[profileName] and 
                        CMT_DB.profiles[profileName][key] and 
                        CMT_DB.profiles[profileName][key][name]
    
    dprint("CMT: SetSetting(%s, %s, %s) -> profile '%s'", 
      tostring(key), tostring(name), tostring(val), profileName)
      
    if tostring(val) ~= tostring(verifyValue) then
      print("CMT ERROR: Value mismatch! Set " .. tostring(val) .. " but got " .. tostring(verifyValue))
    end
  end
end

-- --------------------------------------------------------------------
-- Visibility Manager Module (v4.4.0)
-- Handles conditional visibility for tracker frames based on combat,
-- mouseover, target, group status, and instance type
-- --------------------------------------------------------------------
local VisibilityManager = {
  trackerStates = {},        -- [trackerKey] = { alpha, fading, mouseOver }
  mouseoverDetectors = {},   -- [trackerKey] = detector frame
}

-- Check if Edit Mode Tweaks is managing a specific frame
local function IsEMTManagingFrame(frameName)
  if not _G.EditModeTweaks or not _G.EditModeTweaksDB then
    return false
  end
  
  local db = _G.EditModeTweaksDB
  local mouseOver = db.mouseOverFrames and db.mouseOverFrames[frameName]
  local combat = db.combatFrames and db.combatFrames[frameName]
  local target = db.targetFrames and db.targetFrames[frameName]
  
  return mouseOver or combat or target
end

-- Check if CMT should manage visibility (respects override setting)
local function ShouldCMTManageVisibility(trackerKey, frameName)
  local emtManaging = frameName and IsEMTManagingFrame(frameName)
  if not emtManaging then
    return true -- EMT not managing, CMT can proceed
  end
  
  -- EMT is managing - check if user wants CMT to override
  local override = GetSetting(trackerKey, "visibilityOverrideEMT")
  return override == true
end

-- Get the frame for a tracker key
local function GetTrackerFrameByKey(key)
  for _, t in ipairs(TRACKERS) do
    if t.key == key then
      return _G[t.name], t
    end
  end
  return nil, nil
end

-- Evaluate if a tracker should be visible based on its settings
local function ShouldTrackerBeVisible(trackerKey)
  local enabled = GetSetting(trackerKey, "visibilityEnabled")
  if not enabled then return true end
  
  local combat = GetSetting(trackerKey, "visibilityCombat")
  local mouseover = GetSetting(trackerKey, "visibilityMouseover")
  local target = GetSetting(trackerKey, "visibilityTarget")
  local group = GetSetting(trackerKey, "visibilityGroup")
  local instance = GetSetting(trackerKey, "visibilityInstance")
  
  -- If no conditions enabled, HIDE (nothing can trigger visibility)
  -- User must enable at least one condition to make the tracker visible
  if not combat and not mouseover and not target and not group and not instance then
    return false
  end
  
  -- OR logic: show if ANY enabled condition is met
  if combat and UnitAffectingCombat("player") then 
    return true 
  end
  
  if mouseover then
    local state = VisibilityManager.trackerStates[trackerKey]
    if state and state.mouseOver then return true end
  end
  
  if target and UnitExists("target") then 
    return true 
  end
  
  if group and (IsInGroup() or IsInRaid()) then return true end
  
  if instance then
    local _, instanceType = IsInInstance()
    local allowedTypes = GetSetting(trackerKey, "visibilityInstanceTypes") or {}
    if allowedTypes[instanceType or "none"] then return true end
  end
  
  return false
end

-- Apply visibility with fade
function VisibilityManager:ApplyVisibility(trackerKey, instant)
  local frame, trackerInfo = GetTrackerFrameByKey(trackerKey)
  if not frame then return end
  
  -- Check if CMT should manage this frame's visibility
  local frameName = frame:GetName()
  if not ShouldCMTManageVisibility(trackerKey, frameName) then
    return -- EMT is managing and user hasn't overridden
  end
  
  local enabled = GetSetting(trackerKey, "visibilityEnabled")
  if not enabled then
    -- Restore original alpha if we had stored it
    if frame._CMT_VisOriginalAlpha then
      frame:SetAlpha(frame._CMT_VisOriginalAlpha)
    end
    return
  end
  
  -- Store original alpha (only once, and never store 0)
  if not frame._CMT_VisOriginalAlpha then
    local currentAlpha = frame:GetAlpha()
    frame._CMT_VisOriginalAlpha = (currentAlpha > 0) and currentAlpha or 1
  end
  
  local shouldShow = ShouldTrackerBeVisible(trackerKey)
  local originalAlpha = frame._CMT_VisOriginalAlpha or 1
  local fadeAlpha = (GetSetting(trackerKey, "visibilityFadeAlpha") or 0) / 100
  local targetAlpha = shouldShow and originalAlpha or fadeAlpha
  
  if instant or math.abs(frame:GetAlpha() - targetAlpha) < 0.01 then
    frame:SetAlpha(targetAlpha)
    return
  end
  
  -- Fade animation
  local state = self.trackerStates[trackerKey] or {}
  self.trackerStates[trackerKey] = state
  
  state.fadeStart = GetTime()
  state.fadeStartAlpha = frame:GetAlpha()
  state.fadeTargetAlpha = targetAlpha
  state.fadeDuration = 0.2
  state.fading = true
  
  if not frame._CMT_VisFadeHooked then
    frame:HookScript("OnUpdate", function(self)
      local st = VisibilityManager.trackerStates[trackerKey]
      if not st or not st.fading then return end
      
      local progress = (GetTime() - st.fadeStart) / st.fadeDuration
      if progress >= 1 then
        self:SetAlpha(st.fadeTargetAlpha)
        st.fading = false
      else
        self:SetAlpha(st.fadeStartAlpha + (st.fadeTargetAlpha - st.fadeStartAlpha) * progress)
      end
    end)
    frame._CMT_VisFadeHooked = true
  end
end

-- Mouseover detector management
function VisibilityManager:UpdateMouseoverDetector(trackerKey)
  local frame, trackerInfo = GetTrackerFrameByKey(trackerKey)
  if not frame then return end
  
  local enabled = GetSetting(trackerKey, "visibilityEnabled")
  local mouseover = GetSetting(trackerKey, "visibilityMouseover")
  
  -- Check if CMT should manage visibility
  local frameName = frame:GetName()
  local canManage = ShouldCMTManageVisibility(trackerKey, frameName)
  
  -- Remove existing
  if self.mouseoverDetectors[trackerKey] then
    self.mouseoverDetectors[trackerKey]:SetScript("OnUpdate", nil)
    self.mouseoverDetectors[trackerKey]:Hide()
    self.mouseoverDetectors[trackerKey] = nil
  end
  
  if not enabled or not mouseover or not canManage then
    local state = self.trackerStates[trackerKey]
    if state then state.mouseOver = false end
    return
  end
  
  -- Create new detector
  local detector = CreateFrame("Frame", nil, frame)
  detector:SetAllPoints(frame)
  detector:EnableMouse(false)
  
  local throttle = 0
  detector:SetScript("OnUpdate", function(self, elapsed)
    throttle = throttle + elapsed
    if throttle < 0.05 then return end
    throttle = 0
    
    local state = VisibilityManager.trackerStates[trackerKey] or {}
    VisibilityManager.trackerStates[trackerKey] = state
    
    local wasOver = state.mouseOver
    state.mouseOver = frame:IsMouseOver()
    
    if wasOver ~= state.mouseOver then
      VisibilityManager:ApplyVisibility(trackerKey, false)
    end
  end)
  
  self.mouseoverDetectors[trackerKey] = detector
end

-- Initialize event handling - called from ADDON_LOADED
-- Main visibility application happens on PLAYER_ENTERING_WORLD event
function VisibilityManager:Initialize()
  -- Nothing needed here - PLAYER_ENTERING_WORLD handles it
end

-- Create event frame at module level (like EMT does - more reliable)
local CMT_VisEventFrame = CreateFrame("Frame")
CMT_VisEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
CMT_VisEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
CMT_VisEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
CMT_VisEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
CMT_VisEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
CMT_VisEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- Helper function to apply visibility to all enabled trackers
local function ApplyAllVisibility()
  for _, t in ipairs(TRACKERS) do
    local enabled = GetSetting(t.key, "visibilityEnabled")
    if enabled then
      VisibilityManager:UpdateMouseoverDetector(t.key)
      VisibilityManager:ApplyVisibility(t.key, true)
    end
  end
end

CMT_VisEventFrame:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_ENTERING_WORLD" then
    -- On login OR reload, apply visibility for ALL enabled trackers
    -- Use delays because tracker frames may not exist immediately
    C_Timer.After(0.5, ApplyAllVisibility)
    C_Timer.After(2, ApplyAllVisibility)
    C_Timer.After(4, ApplyAllVisibility)
    return
  end
  
  for _, t in ipairs(TRACKERS) do
    local key = t.key
    local enabled = GetSetting(key, "visibilityEnabled")
    if enabled then
      if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        if GetSetting(key, "visibilityCombat") then
          VisibilityManager:ApplyVisibility(key, true)
        end
      elseif event == "PLAYER_TARGET_CHANGED" then
        if GetSetting(key, "visibilityTarget") then
          VisibilityManager:ApplyVisibility(key, true)
        end
      elseif event == "GROUP_ROSTER_UPDATE" then
        if GetSetting(key, "visibilityGroup") then
          VisibilityManager:ApplyVisibility(key, true)
        end
      elseif event == "ZONE_CHANGED_NEW_AREA" then
        if GetSetting(key, "visibilityInstance") then
          VisibilityManager:ApplyVisibility(key, true)
        end
      end
    end
  end
end)

-- Debug command for visibility system
SLASH_CMTVIS1 = "/cmtvis"
SlashCmdList.CMTVIS = function(msg)
  print("|cff00ff00CMT Visibility Debug:|r")
  for _, t in ipairs(TRACKERS) do
    local key = t.key
    local frame = _G[t.name]
    local enabled = GetSetting(key, "visibilityEnabled")
    local combat = GetSetting(key, "visibilityCombat")
    local target = GetSetting(key, "visibilityTarget")
    local mouseover = GetSetting(key, "visibilityMouseover")
    local group = GetSetting(key, "visibilityGroup")
    local instance = GetSetting(key, "visibilityInstance")
    
    local shouldShow = ShouldTrackerBeVisible(key)
    
    print(string.format("  [%s] enabled=%s, combat=%s, target=%s, mouseover=%s, group=%s, instance=%s",
      key, tostring(enabled), tostring(combat), tostring(target), tostring(mouseover), tostring(group), tostring(instance)))
    print(string.format("    -> ShouldShow=%s", tostring(shouldShow)))
    
    if frame then
      print(string.format("    Frame: alpha=%.2f, shown=%s, origAlpha=%s", 
        frame:GetAlpha(), tostring(frame:IsShown()), tostring(frame._CMT_VisOriginalAlpha)))
    else
      print("    Frame NOT FOUND")
    end
  end
  print(string.format("  Game State: target=%s, combat=%s, group=%s", 
    tostring(UnitExists("target")), 
    tostring(UnitAffectingCombat("player")), 
    tostring(IsInGroup())))
end

-- Force apply visibility (for debugging)
SLASH_CMTVISAPPLY1 = "/cmtvisapply"
SlashCmdList.CMTVISAPPLY = function(msg)
  print("|cff00ff00CMT: Force applying visibility to all trackers...|r")
  for _, t in ipairs(TRACKERS) do
    VisibilityManager:ApplyVisibility(t.key, true)
  end
end

-- Make globally accessible
_G.CMT_VisibilityManager = VisibilityManager

-- Deep copy utility (needed by per-icon override system)
local function deepCopy(tbl)
  if type(tbl) ~= "table" then return tbl end
  local copy = {}
  for k, v in pairs(tbl) do
    if type(v) == "table" then
      copy[k] = deepCopy(v)
    else
      copy[k] = v
    end
  end
  return copy
end

-- ============================================================================
-- PER-ICON OVERRIDE SYSTEM
-- ============================================================================
-- Allows customization of individual icons within a tracker

-- Default override values (returned when no override exists)
local DEFAULT_ICON_OVERRIDE = {
  sizeMultiplier = 1.0,
  zoomOverride = nil,  -- nil=use tracker default
  aspectOverride = nil,  -- nil=use tracker default
  borderColor = nil,  -- nil=no border, or color name string
  borderAlpha = nil,  -- nil=use 1.0, or 0-1
  borderWidth = nil,  -- nil=use 2, or 1-6
  opacity = 1.0,
  nudgeX = 0,  -- X offset in pixels
  nudgeY = 0,  -- Y offset in pixels
  desaturate = false,
  -- State-specific settings (for buffs) - each state has complete settings
  activeState = nil,
  inactiveState = nil,
}

-- Default state-specific override values (complete set of all properties)
local DEFAULT_STATE_OVERRIDE = {
  sizeMultiplier = 1.0,
  zoomOverride = nil,
  aspectOverride = nil,
  borderColor = nil,
  borderAlpha = nil,
  borderWidth = nil,
  opacity = 1.0,
  nudgeX = 0,
  nudgeY = 0,
  desaturate = false,
}

-- Generate identifier for an icon
-- For Blizzard trackers: uses slot position (slot:1, slot:2, etc.)
-- For Custom tracker: uses "item:123" or "spell:456" format
local function GetIconIdentifier(trackerKey, iconOrEntry, slotIndex)
  if trackerKey == "items" then
    -- Custom tracker entry - use type:id format
    if iconOrEntry and iconOrEntry.type and iconOrEntry.id then
      return iconOrEntry.type .. ":" .. iconOrEntry.id
    end
  else
    -- Blizzard tracker - use slot position
    if slotIndex then
      return "slot:" .. slotIndex
    end
  end
  return nil
end

-- Get all icon overrides for a tracker
local function GetIconOverrides(trackerKey)
  local profile = GetCurrentProfile()
  if profile[trackerKey] and profile[trackerKey].iconOverrides then
    return profile[trackerKey].iconOverrides
  end
  return {}
end

-- Get override for a specific icon (returns table with all override values)
local function GetIconOverride(trackerKey, identifier)
  if not identifier then return deepCopy(DEFAULT_ICON_OVERRIDE) end
  
  local overrides = GetIconOverrides(trackerKey)
  if overrides[identifier] then
    -- Merge with defaults to ensure all fields exist
    local result = deepCopy(DEFAULT_ICON_OVERRIDE)
    for k, v in pairs(overrides[identifier]) do
      result[k] = v
    end
    return result
  end
  return deepCopy(DEFAULT_ICON_OVERRIDE)
end

-- Set a specific override property for an icon
local function SetIconOverride(trackerKey, identifier, property, value)
  if not identifier then return end
  
  local profile = GetCurrentProfile()
  profile[trackerKey] = profile[trackerKey] or {}
  profile[trackerKey].iconOverrides = profile[trackerKey].iconOverrides or {}
  profile[trackerKey].iconOverrides[identifier] = profile[trackerKey].iconOverrides[identifier] or {}
  
  -- If setting to default value, remove the property to save space
  if value == DEFAULT_ICON_OVERRIDE[property] then
    profile[trackerKey].iconOverrides[identifier][property] = nil
    
    -- If override table is now empty, remove it entirely
    local isEmpty = true
    for _ in pairs(profile[trackerKey].iconOverrides[identifier]) do
      isEmpty = false
      break
    end
    if isEmpty then
      profile[trackerKey].iconOverrides[identifier] = nil
    end
  else
    profile[trackerKey].iconOverrides[identifier][property] = value
  end
  
  dprint("CMT: SetIconOverride(%s, %s, %s, %s)", trackerKey, tostring(identifier), property, tostring(value))
end

-- Clear all overrides for a specific icon
local function ClearIconOverrides(trackerKey, identifier)
  if not identifier then return end
  
  local profile = GetCurrentProfile()
  if profile[trackerKey] and profile[trackerKey].iconOverrides then
    profile[trackerKey].iconOverrides[identifier] = nil
  end
end

-- Check if an icon has any non-default overrides
local function HasIconOverrides(trackerKey, identifier)
  if not identifier then return false end
  
  local overrides = GetIconOverrides(trackerKey)
  if overrides[identifier] then
    for k, v in pairs(overrides[identifier]) do
      if v ~= DEFAULT_ICON_OVERRIDE[k] then
        return true
      end
    end
  end
  return false
end

-- Calculate the maximum bounds expansion needed for per-icon overrides
-- Returns extra padding needed on each side to contain all possible icon configurations
local function CalculateMaxBoundsExpansion(trackerKey)
  local overrides = GetIconOverrides(trackerKey)
  if not overrides or not next(overrides) then
    return 0, 0, 0, 0, 1.0  -- No expansion needed: left, right, top, bottom, maxScale
  end
  
  local maxNudgeLeft = 0   -- Negative nudgeX (icons pushed left)
  local maxNudgeRight = 0  -- Positive nudgeX (icons pushed right)
  local maxNudgeUp = 0     -- Negative nudgeY (icons pushed up)
  local maxNudgeDown = 0   -- Positive nudgeY (icons pushed down)
  local maxSizeMultiplier = 1.0
  
  for identifier, override in pairs(overrides) do
    if trackerKey == "buffs" then
      -- Check both active and inactive states for buffs
      for _, stateKey in ipairs({"activeState", "inactiveState"}) do
        local state = override[stateKey]
        if state then
          local nudgeX = state.nudgeX or 0
          local nudgeY = state.nudgeY or 0
          local sizeMult = state.sizeMultiplier or 1.0
          
          if nudgeX < 0 then maxNudgeLeft = math.max(maxNudgeLeft, math.abs(nudgeX)) end
          if nudgeX > 0 then maxNudgeRight = math.max(maxNudgeRight, nudgeX) end
          if nudgeY < 0 then maxNudgeUp = math.max(maxNudgeUp, math.abs(nudgeY)) end
          if nudgeY > 0 then maxNudgeDown = math.max(maxNudgeDown, nudgeY) end
          maxSizeMultiplier = math.max(maxSizeMultiplier, sizeMult)
        end
      end
    else
      -- Regular tracker - check direct settings
      local nudgeX = override.nudgeX or 0
      local nudgeY = override.nudgeY or 0
      local sizeMult = override.sizeMultiplier or 1.0
      
      if nudgeX < 0 then maxNudgeLeft = math.max(maxNudgeLeft, math.abs(nudgeX)) end
      if nudgeX > 0 then maxNudgeRight = math.max(maxNudgeRight, nudgeX) end
      if nudgeY < 0 then maxNudgeUp = math.max(maxNudgeUp, math.abs(nudgeY)) end
      if nudgeY > 0 then maxNudgeDown = math.max(maxNudgeDown, nudgeY) end
      maxSizeMultiplier = math.max(maxSizeMultiplier, sizeMult)
    end
  end
  
  return maxNudgeLeft, maxNudgeRight, maxNudgeUp, maxNudgeDown, maxSizeMultiplier
end

local function copyArray(src) local out = {}; for i=1,#src do out[i]=src[i] end; return out end

-- --------------------------------------------------------------------
-- Profile Import/Export
-- --------------------------------------------------------------------
local function serializeValue(val)
  local t = type(val)
  if t == "string" then
    return "\"" .. val:gsub("\\", "\\\\"):gsub("\"", "\\\"") .. "\""
  elseif t == "number" then
    return tostring(val)
  elseif t == "boolean" then
    return val and "true" or "false"
  elseif t == "table" then
    local parts = {}
    -- Check if it's an array
    local isArray = true
    local maxIndex = 0
    for k, v in pairs(val) do
      if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
        isArray = false
        break
      end
      maxIndex = math.max(maxIndex, k)
    end
    
    if isArray and maxIndex > 0 then
      -- Serialize as array
      for i = 1, maxIndex do
        table.insert(parts, serializeValue(val[i]))
      end
      return "[" .. table.concat(parts, ",") .. "]"
    else
      -- Serialize as object
      for k, v in pairs(val) do
        table.insert(parts, serializeValue(tostring(k)) .. ":" .. serializeValue(v))
      end
      return "{" .. table.concat(parts, ",") .. "}"
    end
  end
  return "null"
end

local function serializeProfile(data)
  local json = serializeValue(data)
  -- Base64-like encoding for easier copy/paste
  local compressed = LibDeflate and LibDeflate:CompressDeflate(json) or json
  local encoded = LibDeflate and LibDeflate:EncodeForPrint(compressed) or json
  return "CMT1:" .. encoded
end

local function deserializeValue(str, pos)
  pos = pos or 1
  -- Skip whitespace
  while pos <= #str and str:sub(pos, pos):match("%s") do
    pos = pos + 1
  end
  
  if pos > #str then return nil, pos end
  
  local char = str:sub(pos, pos)
  
  -- String
  if char == '"' then
    local endPos = pos + 1
    local result = ""
    while endPos <= #str do
      local c = str:sub(endPos, endPos)
      if c == "\\" and endPos < #str then
        local next = str:sub(endPos + 1, endPos + 1)
        if next == "\\" or next == '"' then
          result = result .. next
          endPos = endPos + 2
        else
          endPos = endPos + 1
        end
      elseif c == '"' then
        return result, endPos + 1
      else
        result = result .. c
        endPos = endPos + 1
      end
    end
    return nil, pos
  end
  
  -- Number
  if char:match("[%-0-9]") then
    local numStr = str:match("^%-?[0-9]+%.?[0-9]*", pos)
    if numStr then
      return tonumber(numStr), pos + #numStr
    end
  end
  
  -- Boolean/null
  if str:sub(pos, pos + 3) == "true" then
    return true, pos + 4
  elseif str:sub(pos, pos + 4) == "false" then
    return false, pos + 5
  elseif str:sub(pos, pos + 3) == "null" then
    return nil, pos + 4
  end
  
  -- Array
  if char == "[" then
    local result = {}
    pos = pos + 1
    while pos <= #str do
      -- Skip whitespace
      while pos <= #str and str:sub(pos, pos):match("%s") do
        pos = pos + 1
      end
      if str:sub(pos, pos) == "]" then
        return result, pos + 1
      end
      local val, newPos = deserializeValue(str, pos)
      if not val and newPos == pos then break end
      table.insert(result, val)
      pos = newPos
      -- Skip whitespace and comma
      while pos <= #str and (str:sub(pos, pos):match("%s") or str:sub(pos, pos) == ",") do
        pos = pos + 1
      end
    end
    return result, pos
  end
  
  -- Object
  if char == "{" then
    local result = {}
    pos = pos + 1
    while pos <= #str do
      -- Skip whitespace
      while pos <= #str and str:sub(pos, pos):match("%s") do
        pos = pos + 1
      end
      if str:sub(pos, pos) == "}" then
        return result, pos + 1
      end
      -- Key
      local key, newPos = deserializeValue(str, pos)
      if not key then break end
      pos = newPos
      -- Skip whitespace and colon
      while pos <= #str and (str:sub(pos, pos):match("%s") or str:sub(pos, pos) == ":") do
        pos = pos + 1
      end
      -- Value
      local val
      val, pos = deserializeValue(str, pos)
      result[key] = val
      -- Skip whitespace and comma
      while pos <= #str and (str:sub(pos, pos):match("%s") or str:sub(pos, pos) == ",") do
        pos = pos + 1
      end
    end
    return result, pos
  end
  
  return nil, pos
end

local function deserializeProfile(encoded)
  if not encoded or not encoded:match("^CMT1:") then
    return nil, "Invalid profile string format"
  end
  
  local data = encoded:sub(6) -- Remove "CMT1:" prefix
  local decoded = LibDeflate and LibDeflate:DecodeForPrint(data) or data
  local json = LibDeflate and LibDeflate:DecompressDeflate(decoded) or decoded
  
  if not json then
    return nil, "Failed to decode profile string"
  end
  
  local profile, _ = deserializeValue(json)
  
  if not profile or type(profile) ~= "table" then
    return nil, "Invalid profile data"
  end
  
  return profile
end

-- --------------------------------------------------------------------
-- Icon discovery
-- --------------------------------------------------------------------
local function isIcon(f)
  if not f or not f.GetWidth or not f.GetHeight then return false end
  local w,h = f:GetWidth() or 0, f:GetHeight() or 0
  -- Don't check aspect ratio - icons may have custom aspect ratios applied
  if w <= 0 or h <= 0 then return false end
  local tex = f.icon or f.Icon or (f.GetRegions and select(1,f:GetRegions()))
  if tex and tex.GetObjectType and tex:GetObjectType()=="Texture" then return true end
  if f.cooldown or f.Cooldown then return true end
  return false
end

local function isBar(f)
  if not f then return false end
  
  -- Most reliable: Check for bar-specific properties
  if f.Icon and f.Bar then 
    return true 
  end
  
  -- Second most reliable: Check if it has a StatusBar child
  if f.GetNumChildren then
    local numChildren = f:GetNumChildren() or 0
    if numChildren >= 1 then
      for i = 1, numChildren do
        local child = select(i, f:GetChildren())
        if child and child.GetObjectType and child:GetObjectType() == "StatusBar" then
          return true
        end
      end
    end
  end
  
  -- Don't use size or aspect ratio checks - they're unreliable
  return false
end

local function collectIcons(viewer)
  local out = {}
  if not viewer or not viewer.GetNumChildren then return out end
  
  -- Standard icon collection
  local n = viewer:GetNumChildren() or 0
  
  for i=1,n do
    local c = select(i, viewer:GetChildren())
    if c and isIcon(c) then 
      out[#out+1]=c
    elseif c and c.GetNumChildren then
      local m = c:GetNumChildren() or 0
      for j=1,m do 
        local g = select(j, c:GetChildren())
        if g and isIcon(g) then 
          out[#out+1]=g
        end
      end
    end
  end
  
  return out
end

local function collectBars(viewer, debugMode)
  local out = {}
  if not viewer or not viewer.GetNumChildren then return out end
  local n = viewer:GetNumChildren() or 0
  if debugMode then print(string.format("collectBars: viewer has %d children", n)) end
  
  for i=1,n do
    local c = select(i, viewer:GetChildren())
    if c then
      local isBarResult = isBar(c)
      if debugMode then
        local w, h = c:GetWidth() or 0, c:GetHeight() or 0
        dprint("  Child %d: size=%.0fx%.0f, isBar=%s, shown=%s", 
          i, w, h, tostring(isBarResult), tostring(c:IsShown()))
        if c.Icon then dprint("    Has Icon table: %s", type(c.Icon)) end
        if c.Bar then dprint("    Has Bar table: %s", type(c.Bar)) end
      end
      
      if isBarResult then 
        out[#out+1]=c
        if debugMode then dprint("    -> Added as bar #%d", #out) end
      end
    end
  end
  
  if debugMode then print(string.format("collectBars: found %d bars total", #out)) end
  return out
end

-- --------------------------------------------------------------------
-- Read Blizzard order *this pass* (before we touch positions)
-- --------------------------------------------------------------------
local function sortVisual(a,b)
  local at,bt = a:GetTop() or 0, b:GetTop() or 0
  local al,bl = a:GetLeft() or 0, b:GetLeft() or 0
  
  -- Sort top-to-bottom first (higher Y = higher on screen)
  if math.abs(at-bt) > 5 then return at > bt end
  
  -- Then left-to-right for icons in same row
  return al < bl
end

getBlizzardOrderedIcons = function(viewer, isBarType, debugMode, key)
  local all = isBarType and collectBars(viewer, debugMode) or collectIcons(viewer)
  local shown = {}
  
  -- Filter to only shown icons
  for _,f in ipairs(all) do 
    if f:IsShown() then shown[#shown+1]=f end 
  end
  
  dprint("getBlizzardOrderedIcons [%s]: collected %d icons, %d shown", 
    tostring(key), #all, #shown)
  
  -- Sort by visual position (reading order: top-to-bottom, left-to-right)
  table.sort(shown, sortVisual)
  
  return shown
end

-- Helper to get the best identifier for matching frames
-- For buffs, prefer spellID since auraInstanceID changes on buff refresh
-- For cooldowns, auraInstanceID doesn't exist so spellID is used anyway
-- MUST be defined early (before Layout hook) since it's called during layout processing
-- Fully protected against secret values during Midnight combat
local function getMatchIdentifier(icon, key)
  if not icon then return nil end
  
  -- Helper to safely check if a value is a usable number (not secret)
  local function safeNumber(val)
    -- Wrap in pcall because even accessing/checking secret values can error
    local ok, result = pcall(function()
      if val == nil then return nil end
      if type(val) ~= "number" then return nil end
      -- Try to use it in an arithmetic operation - this will fail if it's secret
      local _ = val + 0
      return val
    end)
    if ok then return result end
    return nil
  end
  
  -- For buffs, ALWAYS prefer spellID over auraInstanceID
  -- because auraInstanceID changes when a buff refreshes mid-fight
  if key == "buffs" then
    -- Try to get spellID first
    local spellID = safeNumber(icon.spellID)
    if spellID then return spellID end
    
    -- Fall back to cached spellID - this is safe even in combat
    local cachedID = safeNumber(icon._CMT_cachedSpellID)
    if cachedID then return cachedID end
    
    -- If icon has auraInstanceID, try to look up the spellID via API
    local auraID = safeNumber(icon.auraInstanceID)
    if auraID then
      -- Wrap API call in pcall
      local success, result = pcall(function()
        for i = 1, 40 do
          local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
          if not auraData then break end
          local dataAuraID = safeNumber(auraData.auraInstanceID)
          if dataAuraID and dataAuraID == auraID then
            local foundSpellID = safeNumber(auraData.spellId)
            if foundSpellID then
              return foundSpellID
            end
          end
        end
        return nil
      end)
      
      if success and result then
        -- Cache it for future use
        icon._CMT_cachedSpellID = result
        return result
      end
    end
    
    -- No valid identifier found
    return nil
  end
  
  -- For cooldowns, try auraInstanceID then spellID
  local auraID = safeNumber(icon.auraInstanceID)
  if auraID then return auraID end
  
  local spellID = safeNumber(icon.spellID)
  if spellID then return spellID end
  
  return nil
end

-- --------------------------------------------------------------------
-- Grid helpers
-- --------------------------------------------------------------------
local function computeGrid(icons, pattern)
  local grid, idx = {}, 1
  for _,w in ipairs(pattern) do
    if w == 0 then
      -- Add blank row for spacing
      grid[#grid+1] = {}
    else
      local row = {}
      for _=1,w do
        if idx <= #icons then row[#row+1] = icons[idx]; idx=idx+1 end
      end
      if #row>0 then grid[#grid+1]=row end
    end
  end
  return grid
end

-- Compute grid organized by columns instead of rows
-- Pattern defines number of icons per column
local function computeGridByColumns(icons, pattern)
  local numCols = #pattern
  local totalIcons = #icons
  
  -- First, organize icons into columns based on pattern
  local columns = {}
  local idx = 1
  for colNum, height in ipairs(pattern) do
    if height == 0 then
      -- Add blank column for spacing
      columns[#columns+1] = { isBlank = true }
    else
      local col = {}
      for i = 1, height do
        if idx <= totalIcons then
          col[#col+1] = icons[idx]
          idx = idx + 1
        end
      end
      columns[#columns+1] = col
    end
  end
  
  -- Now convert columns to rows for rendering
  -- Find max column height
  local maxHeight = 0
  for _, col in ipairs(columns) do
    if not col.isBlank and #col > maxHeight then 
      maxHeight = #col 
    end
  end
  
  -- Build rows by reading across columns
  local grid = {}
  for rowIdx = 1, maxHeight do
    local row = {}
    local rowSize = 0  -- Track actual size including nils
    local hasIcon = false  -- Track if row has at least one icon
    for colIdx, col in ipairs(columns) do
      rowSize = rowSize + 1
      if col.isBlank then
        -- For blank columns, add a placeholder (nil)
        row[rowSize] = nil
      elseif col[rowIdx] then
        row[rowSize] = col[rowIdx]
        hasIcon = true  -- Found an icon
      else
        row[rowSize] = nil  -- No icon at this position
      end
    end
    if hasIcon then  -- Only add row if it has at least one icon
      row._size = rowSize  -- Store the actual size
      grid[#grid+1] = row
    end
  end
  
  return grid
end

local function maxRowWidth(grid, iconSize, h)
  local maxW=0
  for _,row in ipairs(grid) do
    -- Count only non-nil icons, but check full row size
    local iconCount = 0
    local rowSize = row._size or #row
    for i = 1, rowSize do
      if row[i] then iconCount = iconCount + 1 end
    end
    local w = (iconCount*iconSize)+((iconCount-1)*h)
    if w>maxW then maxW=w end
  end
  return maxW
end

local function reversed(list)
  local n=#list; local out={}
  for i=1,n do out[i]=list[n-i+1] end
  return out
end

-- --------------------------------------------------------------------
-- Layout (uses cached baseline order ONLY)
-- --------------------------------------------------------------------
local function baselineOrderFor(viewer) return (viewer and viewer._CMT_baseOrder) or {} end

layoutCustomGrid = function(viewer, key, orderFromBlizz)
  if not viewer or not viewer.IsShown or not viewer:IsShown() then 
    return false 
  end
  
  -- HARD LOCK: Absolutely prevent concurrent layout calls for the same viewer
  if viewer._CMT_applying then
    return false
  end
  
  -- DIAGNOSTIC: Warn if being called with explicit Blizzard order instead of cached baseline
  if orderFromBlizz and viewer._CMT_baseOrder and #orderFromBlizz > 0 and #viewer._CMT_baseOrder > 0 then
    -- Check if the order is different from our cached baseline
    local isDifferent = false
    if #orderFromBlizz == #viewer._CMT_baseOrder then
      for i = 1, #orderFromBlizz do
        if orderFromBlizz[i] ~= viewer._CMT_baseOrder[i] then
          isDifferent = true
          break
        end
      end
    end
    if isDifferent then
      dprint("CMT WARNING: layoutCustomGrid called with NEW order for [%s] (ignoring cached baseline!)", key)
    end
  end
  
  if InCombatLockdown and InCombatLockdown() and isProtectedTree(viewer) then
    viewer._CMT_pending = true
    CMT_DB._pendingApply = CMT_DB._pendingApply or {}
    CMT_DB._pendingApply[key] = true
    return false
  end

  setApplying(viewer, true)
  
  local base = orderFromBlizz or baselineOrderFor(viewer)
  
  -- SPECIAL HANDLING FOR BUFFS: If we don't have baseOrder yet, just apply settings without layout
  if #base == 0 and key == "buffs" then
    dprint("CMT: No baseOrder for [%s] yet, applying settings only", key)
    
    -- Check if Masque controls visuals for this tracker
    local masqueControlsVisuals = MasqueModule and MasqueModule.ControlsVisualsForTracker and MasqueModule.ControlsVisualsForTracker(key)
    
    -- Get settings
    local iconSize = GetSetting(key,"iconSize") or 40
    local zoom = GetSetting(key,"zoom") or 1.0
    local aspectRatio = GetSetting(key,"aspectRatio") or "1:1"
    local borderAlpha = GetSetting(key,"borderAlpha") or 1.0
    local cooldownTextScale = GetSetting(key,"cooldownTextScale") or 1.0
    local countTextScale = GetSetting(key,"countTextScale") or 1.0
    
    -- Calculate icon dimensions based on aspect ratio
    local iconWidth = iconSize
    local iconHeight = iconSize
    if aspectRatio and aspectRatio ~= "1:1" then
      local aspectW, aspectH = ParseAspectRatio(aspectRatio)
      if aspectW and aspectH and aspectW > 0 and aspectH > 0 then
        if aspectW > aspectH then
          iconWidth = iconSize
          iconHeight = (iconSize * aspectH) / aspectW
        elseif aspectH > aspectW then
          iconWidth = (iconSize * aspectW) / aspectH
          iconHeight = iconSize
        end
      end
    end
    
    -- Apply settings to all visible icons
    local allIcons = getBlizzardOrderedIcons(viewer, false, false, key)
    for _, icon in ipairs(allIcons) do
      if icon and icon:IsShown() then
        if masqueControlsVisuals then
          -- Masque active: use square icons with scale
          icon:SetSize(40, 40)
          icon:SetScale(iconSize / 40)
        else
          icon:SetSize(iconWidth, iconHeight)
          applyBorderAlpha(icon, borderAlpha)
          applyIconAspectAndZoom(icon, aspectRatio, zoom)
        end
        applyCooldownTextScale(icon, cooldownTextScale)
        -- Apply count text scale (not for items - it uses pixel-based countFontSize)
        if key ~= "items" then
          applyCountTextScale(icon, countTextScale)
        end
        -- Register with Masque if enabled
        if MasqueModule and MasqueModule.OnIconDiscovered then
          MasqueModule.OnIconDiscovered(icon, key)
        end
      end
    end
    
    setApplying(viewer, false)
    dprint("CMT: Applied settings to %d buff icons (no baseOrder yet)", #allIcons)
    return true
  end
  
  if #base == 0 then 
    setApplying(viewer,false) 
    return false 
  end
  
  -- Wrap everything in pcall to catch errors
  local success, err = pcall(function()
  
  -- ORIGINAL CODE CONTINUES HERE

  local ordered = copyArray(base)
  
  -- FOR BUFFS: Never reverse order, always keep Blizzard's order
  local reverseOrderSetting = key ~= "buffs" and GetSetting(key,"reverseOrder") or false
  
  dprint("CMT layoutCustomGrid [%s]: reverseOrder setting = %s", key, tostring(reverseOrderSetting))
  if reverseOrderSetting then 
    ordered = reversed(ordered)
    dprint("CMT: Applied reverse order for [%s]", key)
  end

  local pattern     = GetSetting(key,"rowPattern") or {1,3,4,3}
  local compactMode = GetSetting(key,"compactMode") or false

  local h,v
  if compactMode then
    local off = GetSetting(key,"compactOffset") or -4
    h,v = off,off
  else
    h = GetSetting(key,"hSpacing") or 2
    v = GetSetting(key,"vSpacing") or 2
  end

  local align  = GetSetting(key,"alignment") or "CENTER"
  local iconSize = GetSetting(key,"iconSize") or 40  -- Base pixel size of longest dimension
  local iconOpacity = GetSetting(key,"iconOpacity") or 1.0  -- Base icon opacity
  local zoom   = GetSetting(key,"zoom") or 1.0
  local aspectRatio = GetSetting(key,"aspectRatio") or "1:1"
  local layoutDirection = GetSetting(key,"layoutDirection") or "ROWS"
  
  -- Calculate maximum bounds expansion from per-icon overrides
  -- This tells us how much extra space we need around the base grid
  -- ALWAYS calculate this (even in Edit Mode) so frame size and icon positions are consistent
  local maxNudgeLeft, maxNudgeRight, maxNudgeUp, maxNudgeDown, maxSizeMult = CalculateMaxBoundsExpansion(key)
  
  -- Calculate extra size expansion (how much larger scaled icons extend beyond base grid)
  -- An icon scaled 1.5x will extend 0.25 * iconSize beyond each edge
  local sizeExpansion = iconSize * (maxSizeMult - 1) / 2
  
  -- Total padding needed on each side
  local padLeft = maxNudgeLeft + sizeExpansion
  local padRight = maxNudgeRight + sizeExpansion
  local padTop = maxNudgeUp + sizeExpansion
  local padBottom = maxNudgeDown + sizeExpansion
  
  -- Store padding for use in icon positioning
  viewer._CMT_padLeft = padLeft
  viewer._CMT_padTop = padTop
  
  dprint("CMT layoutCustomGrid [%s] BOUNDS EXPANSION: L=%.1f R=%.1f T=%.1f B=%.1f (maxScale=%.2f)", 
    key, padLeft, padRight, padTop, padBottom, maxSizeMult)
  
  dprint("CMT layoutCustomGrid [%s] SETTINGS: align=%s, iconSize=%d, zoom=%.2f, aspect=%s, dir=%s, pattern=%s", 
    key, align, iconSize, zoom, aspectRatio, layoutDirection, table.concat(pattern, ","))
  
  -- Safety check - if no icons, return early
  if #ordered == 0 then
    setApplying(viewer, false)
    return true
  end
  
  -- Use iconSize directly as the base - no more reading from current icons!
  local baseSize = iconSize
  
  dprint("CMT: Using baseSize=%d (from iconSize setting) for [%s]", baseSize, key)
  
  -- Calculate dimensions based on aspect ratio BEFORE applying to icons
  -- Don't rely on reading dimensions back as UI might not update immediately
  local iconWidth = baseSize
  local iconHeight = baseSize
  
  if aspectRatio and aspectRatio ~= "1:1" then
    local aspectW, aspectH = ParseAspectRatio(aspectRatio)
    if aspectW and aspectH and aspectW > 0 and aspectH > 0 then
      -- Keep the LONGEST side at baseSize, calculate the shorter side
      if aspectW > aspectH then
        -- Wider (16:9, 21:9) - width is longest, so width = baseSize
        iconWidth = baseSize
        iconHeight = (baseSize * aspectH) / aspectW
      elseif aspectH > aspectW then
        -- Taller (9:16, 3:4) - height is longest, so height = baseSize
        iconWidth = (baseSize * aspectW) / aspectH
        iconHeight = baseSize
      end
    end
  end
  
  dprint("CMT: Calculated icon dimensions for [%s]: %.1fx%.1f (aspect=%s, baseSize=%d)", 
    key, iconWidth, iconHeight, aspectRatio, baseSize)
  
  -- Check if border scaling is enabled
  local borderScaleEnabled = GetSetting(key, "borderScale")
  if borderScaleEnabled == nil then borderScaleEnabled = true end
  local borderScaleRatio = iconSize / 40  -- Ratio to default 40px size
  
  -- Check if Masque is controlling visuals for this tracker
  local masqueControlsVisuals = MasqueModule and MasqueModule.ControlsVisualsForTracker and MasqueModule.ControlsVisualsForTracker(key)
  
  -- When Masque is active, force square icons (Masque skins expect square)
  local effectiveWidth = masqueControlsVisuals and iconSize or iconWidth
  local effectiveHeight = masqueControlsVisuals and iconSize or iconHeight
  
  -- Apply aspect ratio to all icons using our calculated dimensions
  -- Also tag each icon with its slot index and base values for per-icon override lookup
  for i, icon in ipairs(ordered) do
    -- Apply size - always do this, but use square when Masque active
    if masqueControlsVisuals then
      -- Masque active: use square icons, apply scale for size
      icon:SetSize(40, 40)
      icon:SetScale(iconSize / 40)
      icon._CMT_borderScaleApplied = true
      icon._CMT_borderScaleRatio = iconSize / 40
    elseif borderScaleEnabled and math.abs(borderScaleRatio - 1.0) > 0.01 then
      -- Border scaling: keep frame at 40px base, use SetScale for visual size
      -- Calculate what the 40px equivalent dimensions would be for the aspect ratio
      local baseWidth40, baseHeight40
      if aspectRatio == "1:1" then
        baseWidth40, baseHeight40 = 40, 40
      else
        local ratioW, ratioH = ParseAspectRatio(aspectRatio)
        if ratioW > ratioH then
          baseWidth40 = 40
          baseHeight40 = 40 * (ratioH / ratioW)
        else
          baseHeight40 = 40
          baseWidth40 = 40 * (ratioW / ratioH)
        end
      end
      icon:SetSize(baseWidth40, baseHeight40)
      icon:SetScale(borderScaleRatio)
      icon._CMT_borderScaleApplied = true
      icon._CMT_borderScaleRatio = borderScaleRatio
    else
      -- Normal sizing: use SetSize directly, no scale
      icon:SetSize(effectiveWidth, effectiveHeight)
      if icon._CMT_borderScaleApplied then
        icon:SetScale(1.0)
        icon._CMT_borderScaleApplied = nil
      end
    end
    
    icon._CMT_slotIndex = i  -- Tag with slot index for override lookup
    -- Store base values for state switching
    icon._CMT_baseIconSize = iconSize  -- The base size before aspect ratio
    icon._CMT_baseWidth = masqueControlsVisuals and iconSize or iconWidth
    icon._CMT_baseHeight = masqueControlsVisuals and iconSize or iconHeight
    icon._CMT_baseAspect = aspectRatio
    icon._CMT_baseZoom = zoom
    icon._CMT_baseBorderAlpha = GetSetting(key, "borderAlpha") or 1.0
    icon._CMT_baseOpacity = iconOpacity
    -- Apply base opacity (will be overridden by per-icon settings if set)
    -- For buffs, this is handled separately in ApplyBuffVisualState
    if key ~= "buffs" then
      icon:SetAlpha(iconOpacity)
    end
    
    -- Register with Masque if enabled
    if MasqueModule and MasqueModule.OnIconDiscovered then
      MasqueModule.OnIconDiscovered(icon, key)
    end
  end
  
  -- Use appropriate grid computation based on layout direction
  local grid
  if layoutDirection == "COLUMNS" then
    grid = computeGridByColumns(ordered, pattern)
    
    -- Debug: show what order we're using
    if key == "utility" then
      dprint("CMT COLUMN DEBUG [%s]: Input order has %d icons", key, #ordered)
      for i = 1, math.min(8, #ordered) do
        dprint("  Icon %d at ordered[%d]", i, i)
      end
    end
  else
    grid = computeGrid(ordered, pattern)
  end
  
  local maxW   = maxRowWidth(grid, iconWidth, h)
  
  dprint("CMT layoutCustomGrid [%s]: %d icons, iconSize=%.1fx%.1f, maxW=%.1f, align=%s, zoom=%.2f, aspect=%s, dir=%s", 
    key, #ordered, iconWidth, iconHeight, maxW, align, zoom, aspectRatio, layoutDirection)

  local y=0
  
  -- For column mode, calculate per-column heights for alignment
  local columnHeights = {}
  local maxColumnHeight = 0
  if layoutDirection == "COLUMNS" then
    -- Calculate height of each column (number of icons in that column)
    local rowSize = grid[1]._size or #grid[1]
    for colIdx = 1, rowSize do
      local colHeight = 0
      -- Count how many rows have an icon in this column
      for rowIdx = 1, #grid do
        local row = grid[rowIdx]
        local rs = row._size or #row
        if colIdx <= rs and row[colIdx] then
          colHeight = colHeight + 1
        end
      end
      columnHeights[colIdx] = colHeight
      if colHeight > maxColumnHeight then
        maxColumnHeight = colHeight
      end
    end
  end
  
  for rowIdx,row in ipairs(grid) do
    -- Count non-nil icons in row for width calculation
    -- For buffs: count ALL icons (shown and hidden) to keep positions stable
    local iconCountRow = 0
    local rowSize = row._size or #row
    for i = 1, rowSize do
      if row[i] then
        iconCountRow = iconCountRow + 1
      end
    end
    local rowW = (iconCountRow*iconWidth)+((iconCountRow-1)*h)
    local x0 = 0
    local y0 = 0
    
    if layoutDirection == "COLUMNS" then
      -- Column mode: each column aligns independently based on its height
      -- y0 will be calculated per-icon based on column height
    else
      -- In row mode, align horizontally: LEFT/CENTER/RIGHT
      if align=="CENTER" then 
        x0=(maxW-rowW)/2
      elseif align=="RIGHT" then 
        x0=maxW-rowW
      end
    end
    
    if rowIdx == 1 then
      if layoutDirection == "COLUMNS" then
        dprint("  Row 1 (across columns): %d icons, maxColumnHeight=%d, align=%s", 
          iconCountRow, maxColumnHeight, align)
      else
        dprint("  Row 1: %d icons, rowW=%.1f, x0=%.1f", #row, rowW, x0)
      end
    end
    
    -- Use numeric for loop to handle nil entries (ipairs stops at first nil)
    local rowSize = row._size or #row  -- Use stored size or fallback to #
    for idx = 1, rowSize do
      local icon = row[idx]
      if icon then  -- Skip nil entries (blank spaces)
        -- For buffs: skip positioning hidden icons (but they still reserve their spot in the grid)
        if key == "buffs" and not icon:IsShown() then
          dprint("CMT: Skipping hidden buff icon at grid[%d][%d]", rowIdx, idx)
          -- Don't position it, just continue to next icon
        else
          local x, y_pos
          if layoutDirection == "COLUMNS" then
            -- Column layout: grid rows represent horizontal rows across columns
            -- idx = column number (horizontal position)
            -- rowIdx = row number (vertical position)
            
            -- Calculate per-column y offset based on this column's height
            local colHeight = columnHeights[idx] or 0
            local colTotalHeight = (colHeight * iconHeight) + ((colHeight - 1) * v)
            local maxTotalHeight = (maxColumnHeight * iconHeight) + ((maxColumnHeight - 1) * v)
            
            local colYOffset = 0
            if align == "MIDDLE" then
              colYOffset = (maxTotalHeight - colTotalHeight) / 2
            elseif align == "BOTTOM" then
              colYOffset = maxTotalHeight - colTotalHeight
            end
            -- TOP alignment uses colYOffset = 0 (default)
            
            x = ((idx-1)*(iconWidth+h))  -- idx is the column number
            y_pos = colYOffset + ((rowIdx-1)*(iconHeight+v))  -- rowIdx is the row number within this column
          else
            -- Row layout: x advances per icon in row, y advances per row
            x = x0 + ((idx-1)*(iconWidth+h))
            y_pos = y
          end
          
          -- Position the icon with padding offset to center grid in expanded viewer
          -- If border scaling is applied, we need to adjust position for the scale factor
          -- SetPoint coordinates are in parent space, but a scaled frame's anchor is also scaled
          icon:ClearAllPoints()
          local posX = x + padLeft
          local posY = y_pos + padTop
          
          if icon._CMT_borderScaleApplied and icon._CMT_borderScaleRatio then
            -- Adjust position to compensate for scale
            -- Divide by scale so the visual position is correct
            posX = posX / icon._CMT_borderScaleRatio
            posY = posY / icon._CMT_borderScaleRatio
          end
          
          icon:SetPoint("TOPLEFT", viewer, "TOPLEFT", posX, -posY)
          
          -- Store base position for state switching (before nudge is applied)
          -- Store the actual position values used (adjusted for scale)
          icon._CMT_baseX = posX
          icon._CMT_baseY = posY
          icon._CMT_baseFrameLevel = icon:GetFrameLevel()
          
          -- Debug: Show first few icon placements in column mode
          if layoutDirection == "COLUMNS" and rowIdx <= 2 and idx <= 4 then
            dprint("CMT Column [%s]: grid[%d][%d] = icon at x=%.1f, y=%.1f (col=%d, row=%d)", 
              key, rowIdx, idx, x, -y_pos, idx, rowIdx)
          end
          
          -- Apply visual settings only if Masque is not controlling this tracker
          if not masqueControlsVisuals then
            -- Apply border alpha (controls icon frame/border visibility)
            local borderAlpha = GetSetting(key,"borderAlpha") or 1.0
            applyBorderAlpha(icon, borderAlpha)
            
            -- Apply texture zoom and aspect cropping (icon frame already resized above)
            applyIconAspectAndZoom(icon, aspectRatio, zoom)
          end
          
          -- Note: Border scaling is now handled during icon sizing above
          -- (SetScale is applied there when borderScale is enabled)
          
          -- Apply cooldown text scale (always apply, doesn't interfere with Masque)
          local cooldownTextScale = GetSetting(key,"cooldownTextScale") or 1.0
          applyCooldownTextScale(icon, cooldownTextScale)
          
          -- Apply count text scale (not for items - it uses pixel-based countFontSize)
          if key ~= "items" then
            local countTextScale = GetSetting(key,"countTextScale") or 1.0
            applyCountTextScale(icon, countTextScale)
          end
          
          if rowIdx == 1 and idx == 1 then
            -- Show where first icon was placed and its properties
            C_Timer.After(0.05, function()
              if icon then
                local iconX, iconY = icon:GetCenter()
                local iconScale = icon:GetScale()
                local iconEffScale = icon:GetEffectiveScale()
                local iconParent = icon:GetParent()
                local iconParentName = iconParent and iconParent:GetName() or "nil"
                dprint("    Icon 1: offset=(%.1f,%.1f) → actualCenter=(%.1f,%.1f)", 
                  x, -y_pos, iconX or 0, iconY or 0)
                dprint("           scale=%.3f, effectiveScale=%.3f, parent=%s", 
                  iconScale, iconEffScale, iconParentName)
              end
            end)
          end
        end -- end of else block for shown icons
      end -- end of if icon then
    end -- end of for idx loop
    
    -- Only advance y for row mode; column mode uses calculated positions
    if layoutDirection ~= "COLUMNS" then
      y = y + iconHeight + v
    end
  end

  viewer._CMT_desiredSig = sig(viewer)
  viewer._CMT_pending = nil
  if CMT_DB._pendingApply then CMT_DB._pendingApply[key]=nil end
  
  -- Resize the viewer frame to match the actual icon layout PLUS expansion padding
  -- This ensures the viewer is always big enough to contain scaled/nudged icons
  local totalHeight = 0
  if layoutDirection == "COLUMNS" then
    -- For column layout, height = tallest column * (iconHeight + vSpacing)
    totalHeight = maxColumnHeight * iconHeight + (maxColumnHeight - 1) * v
  else
    -- For row layout, height = number of rows * (iconHeight + vSpacing)
    totalHeight = #grid * iconHeight + (#grid - 1) * v
  end
  
  -- Add padding to dimensions for expanded bounds
  local expandedWidth = maxW + padLeft + padRight
  local expandedHeight = totalHeight + padTop + padBottom
  
  -- ALWAYS set viewer to expanded size - this ensures:
  -- 1. Edit Mode shows the correct frame size for positioning
  -- 2. Icons are always in their correct positions with padding offset
  -- 3. No drift when icons change size/position (bounds don't change)
  viewer:SetSize(expandedWidth, expandedHeight)
  dprint("CMT: Set [%s] viewer to expanded size %.1fx%.1f (base: %.1fx%.1f, pad: L%.1f R%.1f T%.1f B%.1f)", 
    key, expandedWidth, expandedHeight, maxW, totalHeight, padLeft, padRight, padTop, padBottom)
  
  -- CRITICAL FIX: Apply settings to ALL visible icons, not just ones in our ordered list
  -- This ensures new buffs that appear get aspect ratio/zoom even if they're not in baseOrder yet
  local allCurrentIcons = getBlizzardOrderedIcons(viewer, false, false, key)
  for _, icon in ipairs(allCurrentIcons) do
    if icon and icon:IsShown() then
      if masqueControlsVisuals then
        -- Masque active: use square icons with scale
        icon:SetSize(40, 40)
        icon:SetScale(iconSize / 40)
      elseif borderScaleEnabled and math.abs(borderScaleRatio - 1.0) > 0.01 then
        -- Apply size (with border scaling if enabled)
        local baseWidth40, baseHeight40
        if aspectRatio == "1:1" then
          baseWidth40, baseHeight40 = 40, 40
        else
          local ratioW, ratioH = ParseAspectRatio(aspectRatio)
          if ratioW > ratioH then
            baseWidth40 = 40
            baseHeight40 = 40 * (ratioH / ratioW)
          else
            baseHeight40 = 40
            baseWidth40 = 40 * (ratioW / ratioH)
          end
        end
        icon:SetSize(baseWidth40, baseHeight40)
        icon:SetScale(borderScaleRatio)
      else
        icon:SetSize(effectiveWidth, effectiveHeight)
        if icon._CMT_borderScaleApplied then
          icon:SetScale(1.0)
        end
      end
      
      -- Apply border/zoom only if Masque not active
      if not masqueControlsVisuals then
        local borderAlpha = GetSetting(key,"borderAlpha") or 1.0
        applyBorderAlpha(icon, borderAlpha)
        applyIconAspectAndZoom(icon, aspectRatio, zoom)
      end
      
      -- Apply cooldown text scale (always apply, doesn't interfere with Masque)
      local cooldownTextScale = GetSetting(key,"cooldownTextScale") or 1.0
      applyCooldownTextScale(icon, cooldownTextScale)
      
      -- Apply count text scale (not for items - it uses pixel-based countFontSize)
      if key ~= "items" then
        local countTextScale = GetSetting(key,"countTextScale") or 1.0
        applyCountTextScale(icon, countTextScale)
      end
    end
  end
  
  -- Save viewer position BEFORE applying per-icon overrides
  -- This is our "known good" position that we'll restore after overrides are applied
  local savedPoint, savedRelativeTo, savedRelativePoint, savedX, savedY
  if viewer.GetPoint then
    savedPoint, savedRelativeTo, savedRelativePoint, savedX, savedY = viewer:GetPoint(1)
  end
  
  -- Apply per-icon overrides AFTER main layout completes
  -- Skip ALL per-icon overrides when Edit Mode is active to preserve tracker bounds
  local overrides = GetIconOverrides(key)
  if overrides and next(overrides) and not IsEditModeActive() then
    -- We have some overrides for this tracker
    for i, icon in ipairs(ordered) do
      if icon and icon:IsShown() then
        local identifier = GetIconIdentifier(key, nil, i)
        
        -- For items tracker, use entry-based identifier
        if key == "items" and icon._CMT_entryType and icon._CMT_entryID then
          local entry = { type = icon._CMT_entryType, id = icon._CMT_entryID }
          identifier = GetIconIdentifier(key, entry)
        end
        
        if identifier and overrides[identifier] then
          local override = GetIconOverride(key, identifier)
          
          -- For buffs, determine active state and get state-specific settings
          local settings = override
          if key == "buffs" then
            local isActive = (icon.auraInstanceID ~= nil)
            local stateKey = isActive and "activeState" or "inactiveState"
            if override[stateKey] then
              settings = override[stateKey]
            else
              settings = {}  -- No state-specific override
            end
          end
          
          -- Calculate effective icon dimensions
          local effectiveWidth, effectiveHeight = iconWidth, iconHeight
          local effectiveAspect = settings.aspectOverride or aspectRatio
          
          if settings.aspectOverride then
            -- Recalculate dimensions from base icon size using new aspect ratio
            local aspectW, aspectH = ParseAspectRatio(effectiveAspect)
            
            if aspectW > aspectH then
              -- Wide aspect (16:9, 21:9, 4:3)
              effectiveWidth = iconSize
              effectiveHeight = (iconSize * aspectH) / aspectW
            elseif aspectH > aspectW then
              -- Tall aspect (9:16, 3:4)
              effectiveWidth = (iconSize * aspectW) / aspectH
              effectiveHeight = iconSize
            else
              -- Square (1:1)
              effectiveWidth = iconSize
              effectiveHeight = iconSize
            end
          end
          
          -- Apply size multiplier using SetSize
          local sizeMultiplier = settings.sizeMultiplier or 1.0
          if masqueControlsVisuals then
            -- With Masque, apply size multiplier using scale on 40px base
            if sizeMultiplier ~= 1.0 then
              icon:SetSize(40, 40)
              icon:SetScale((iconSize * sizeMultiplier) / 40)
            end
          elseif sizeMultiplier ~= 1.0 or settings.aspectOverride then
            icon:SetSize(effectiveWidth * sizeMultiplier, effectiveHeight * sizeMultiplier)
            icon:SetScale(1.0)  -- Reset any previous scale
          end
          
          -- Apply opacity (fall back to base iconOpacity if not overridden)
          if settings.opacity then
            icon:SetAlpha(settings.opacity)
          elseif key ~= "buffs" then
            -- For non-buff trackers, apply base opacity if no per-icon override
            icon:SetAlpha(iconOpacity)
          end
          
          -- Apply desaturate
          if settings.desaturate then
            local texture = icon.Icon or icon.icon
            if texture and texture.SetDesaturated then
              texture:SetDesaturated(true)
            end
          end
          
          -- Apply nudge offset and raise frame level for overlapping icons
          local nudgeX = settings.nudgeX or 0
          local nudgeY = settings.nudgeY or 0
          if nudgeX ~= 0 or nudgeY ~= 0 then
            local point, relativeTo, relativePoint, xOfs, yOfs = icon:GetPoint(1)
            if point then
              icon:ClearAllPoints()
              icon:SetPoint(point, relativeTo, relativePoint, 
                xOfs + nudgeX, 
                yOfs - nudgeY)
            end
            -- Raise frame level so nudged icons appear on top of others
            local currentLevel = icon:GetFrameLevel()
            icon:SetFrameLevel(currentLevel + 10)
          end
          
          -- Raise frame level for any icon with overrides (ensures visibility)
          if sizeMultiplier > 1.0 then
            local currentLevel = icon:GetFrameLevel()
            icon:SetFrameLevel(currentLevel + 5)
          end
          
          -- Apply zoom and aspect texture coords (skip if Masque active)
          if not masqueControlsVisuals then
            local effectiveZoom = settings.zoomOverride or zoom
            applyIconAspectAndZoom(icon, effectiveAspect, effectiveZoom)
          end
          
          -- Apply custom border (skip if Masque active)
          if not masqueControlsVisuals and settings.borderColor then
            applyCustomBorder(icon, settings.borderColor, settings.borderWidth, settings.borderAlpha)
          end
          
          -- Apply timer (cooldown) text scale and color
          local timerScale = settings.timerScale
          local timerColor = settings.timerColor
          if timerScale or timerColor then
            local cooldown = icon.Cooldown or icon.cooldown
            if cooldown then
              for _, region in ipairs({cooldown:GetRegions()}) do
                if region and region:GetObjectType() == "FontString" then
                  if timerScale then
                    local font, size, flags = region:GetFont()
                    if font and size then
                      if not region._CMT_originalSize then
                        region._CMT_originalSize = size
                      end
                      region:SetFont(font, region._CMT_originalSize * timerScale, flags)
                    end
                  end
                  if timerColor then
                    region:SetTextColor(timerColor[1], timerColor[2], timerColor[3], 1)
                  end
                  break
                end
              end
            end
          end
          
          -- Apply count (stack) text scale and color
          local countScale = settings.countScale
          local countColor = settings.countColor
          if countScale or countColor then
            local countText = icon.Count or icon.count
            if countText and countText.GetObjectType and countText:GetObjectType() == "FontString" then
              if countScale then
                local font, size, flags = countText:GetFont()
                if font and size then
                  if not countText._CMT_originalSize then
                    countText._CMT_originalSize = size
                  end
                  countText:SetFont(font, countText._CMT_originalSize * countScale, flags)
                end
              end
              if countColor then
                countText:SetTextColor(countColor[1], countColor[2], countColor[3], 1)
              end
            end
          end
        end
      end
    end
    dprint("CMT: Applied per-icon overrides for [%s]", key)
    
    -- Restore viewer position after applying per-icon overrides
    -- Blizzard may have shifted the tracker to "contain" the moved/enlarged icons
    if savedPoint and savedRelativeTo and savedX and savedY then
      local currentPoint, currentRelativeTo, currentRelativePoint, currentX, currentY = viewer:GetPoint(1)
      if currentX and (math.abs(currentX - savedX) > 0.5 or math.abs(currentY - savedY) > 0.5) then
        posDebug("[%s] DRIFT after per-icon overrides: was %.1f,%.1f should be %.1f,%.1f - RESTORING", 
          key, currentX, currentY, savedX, savedY)
        viewer:ClearAllPoints()
        viewer:SetPoint(savedPoint, savedRelativeTo, savedRelativePoint, savedX, savedY)
      end
    end
  end
  
  end) -- End of pcall for layoutCustomGrid
  
  setApplying(viewer,false)
  
  -- Save "known good" position after successful layout (for drift detection/restoration)
  -- Skip during settling period - positions may not be correct yet
  -- Use the pre-override position we saved, not current position
  if not IsSettlingPeriod() then
    if savedPoint and savedX and savedY then
      posWatch("[%s] Updating knownGoodPosition to pre-override: %.1f, %.1f", key, savedX, savedY)
      viewer._CMT_knownGoodPosition = {
        point = savedPoint,
        relativeTo = savedRelativeTo,
        relativePoint = savedRelativePoint,
        x = savedX,
        y = savedY
      }
    elseif viewer.GetPoint then
      local point, relativeTo, relativePoint, x, y = viewer:GetPoint(1)
      if point and x and y then
        posWatch("[%s] Updating knownGoodPosition to current: %.1f, %.1f", key, x, y)
        viewer._CMT_knownGoodPosition = {
          point = point,
          relativeTo = relativeTo,
          relativePoint = relativePoint,
          x = x,
          y = y
        }
      end
    end
  else
    posWatch("[%s] Skipping knownGoodPosition save (settling period)", key)
  end
  
  -- Set grace period to allow Blizzard's post-layout cleanup without triggering drift
  viewer._CMT_blizzCleanup = true
  C_Timer.After(0.2, function()
    if viewer then viewer._CMT_blizzCleanup = nil end
  end)
  
  if not success then
    dprint("CMT ERROR: layoutCustomGrid for [%s] failed: %s", key, tostring(err))
    return false
  end
  
  -- Check and restore ALL other trackers - Blizzard may have shifted them
  -- when we applied our layout (especially with per-icon overrides)
  RestoreAllTrackerPositions(key)
  
  -- Also do a deferred check - Blizzard might shift things after a frame delay
  C_Timer.After(0.05, function()
    RestoreAllTrackerPositions(key)
  end)
  
  return true
end

-- --------------------------------------------------------------------
-- Bar Layout (for vertical stacked bars with icons)
-- --------------------------------------------------------------------
layoutBars = function(viewer, key, orderFromBlizz)
  if not viewer or not viewer.IsShown or not viewer:IsShown() then return false end
  if InCombatLockdown and InCombatLockdown() and isProtectedTree(viewer) then
    viewer._CMT_pending = true
    CMT_DB._pendingApply = CMT_DB._pendingApply or {}
    CMT_DB._pendingApply[key] = true
    return false
  end

  setApplying(viewer, true)

  local base = orderFromBlizz or baselineOrderFor(viewer)
  
  -- If we have no baseline, capture it now (happens on first bar)
  if #base == 0 then
    base = getBlizzardOrderedIcons(viewer, true, false, key)  -- Pass key for buff age tracking
    viewer._CMT_baseOrder = base
  end
  
  if #base == 0 then setApplying(viewer,false) return false end

  local ordered = copyArray(base)
  if GetSetting(key,"reverseOrder") then ordered = reversed(ordered) end

  local barSpacing = GetSetting(key,"barSpacing") or 2
  local iconSide   = GetSetting(key,"barIconSide") or "LEFT"
  local iconGap    = GetSetting(key,"barIconGap") or 0
  local iconSize   = GetSetting(key,"iconSize") or 40
  local zoom       = GetSetting(key,"zoom") or 1.0
  
  local debug = false -- Set to true to enable debug output
  
  if debug then
    dprint("CMT Bar Layout: spacing=%d, iconSide=%s, iconGap=%d, bars=%d, iconSize=%d, zoom=%.2f", 
      barSpacing, iconSide, iconGap, #ordered, iconSize, zoom)
  end

  -- Stack bars vertically
  local y = 0
  for idx, bar in ipairs(ordered) do
    if bar and bar:IsShown() then
      local barHeight = bar:GetHeight() or 30
      
      bar:ClearAllPoints()
      bar:SetPoint("TOPLEFT", viewer, "TOPLEFT", 0, -y)
      -- Don't apply scale to bars - they manage their own sizing
      
      -- Don't try to reposition Blizzard's internal bar structure
      -- Just let Blizzard handle the icon and statusBar positioning
      
      y = y + barHeight + barSpacing
    end
  end

  viewer._CMT_desiredSig = sig(viewer)
  viewer._CMT_pending = nil
  if CMT_DB._pendingApply then CMT_DB._pendingApply[key]=nil end
  
  setApplying(viewer,false)
  
  -- Check and restore ALL other trackers - Blizzard may have shifted them
  RestoreAllTrackerPositions(key)
  
  -- Also do a deferred check - Blizzard might shift things after a frame delay
  C_Timer.After(0.05, function()
    RestoreAllTrackerPositions(key)
  end)
  
  return true
end

-- --------------------------------------------------------------------
-- Watchdog
-- --------------------------------------------------------------------
local function ensureFrozen(viewer, key)
  if not viewer or not viewer:IsShown() or not viewer._CMT_desiredSig then return end
  
  -- Prevent rapid re-layout loops - but be more responsive for anchor issues
  -- Reduced from 0.5 to 0.1 seconds to catch anchor repositioning faster
  local now = GetTime()
  if viewer._CMT_lastEnsureFrozen and (now - viewer._CMT_lastEnsureFrozen) < 0.1 then
    return
  end
  
  if sig(viewer) ~= viewer._CMT_desiredSig then
    viewer._CMT_lastEnsureFrozen = now
    
    if InCombatLockdown and InCombatLockdown() and isProtectedTree(viewer) then
      viewer._CMT_pending = true
      CMT_DB._pendingApply = CMT_DB._pendingApply or {}
      CMT_DB._pendingApply[key]=true
      return
    end
    if not viewer._CMT_applying then
      dprint("CMT: ensureFrozen detected sig change for [%s], re-laying out", key)
      local trackerInfo = getTrackerInfoByKey(key)
      local layoutFunc = (trackerInfo and trackerInfo.isBarType) and layoutBars or layoutCustomGrid
      layoutFunc(viewer, key, baselineOrderFor(viewer))
      _fastRepairUntil = GetTime()+0.5  -- Activate fast repair mode
    end
  end
end

local function hookChildPointChanges(viewer)
  if not viewer then return end
  
  -- Mark function detects when icons are moved by something OTHER than us
  -- But we need a grace period after OUR layout for Blizzard's cleanup
  local function mark() 
    if viewer._CMT_applying then return end -- During our layout
    if viewer._CMT_blizzCleanup then return end -- Blizzard's post-layout cleanup (0.2s grace)
    viewer._CMT_drift = true 
  end
  
  -- Always check for new children - don't bail early with _CMT_pointsHooked flag
  if viewer.GetNumChildren then
    local n=viewer:GetNumChildren() or 0
    for i=1,n do
      local f = select(i, viewer:GetChildren())
      -- Hook each child that hasn't been hooked yet
      if f and not f._CMT_hooked then
        f._CMT_hooked = true
        if f.SetPoint       then hooksecurefunc(f,"SetPoint",mark) end
        if f.SetAllPoints   then hooksecurefunc(f,"SetAllPoints",mark) end
        if f.ClearAllPoints then hooksecurefunc(f,"ClearAllPoints",mark) end
        if f.SetSize        then hooksecurefunc(f,"SetSize",mark) end
      end
    end
  end
end

local function hookChildLifecycle(viewer, key)
  if not viewer then return end
  
  local trackerInfo = getTrackerInfoByKey(key)
  local layoutFunc = (trackerInfo and trackerInfo.isBarType) and layoutBars or layoutCustomGrid
  
  local function onChange()
    if viewer._CMT_applying then return end
    
    -- Throttle: Don't trigger onChange more than once per 0.08 seconds
    -- Reduced from 0.1 to be more responsive to buff appearance
    local now = GetTime()
    if viewer._CMT_lastOnChange and (now - viewer._CMT_lastOnChange) < 0.08 then
      return
    end
    viewer._CMT_lastOnChange = now
    
    -- Apply with retry to ensure aspect ratio sticks
    local function applyWithRetry(attempt)
      if attempt > 2 then return end
      
      C_Timer.After(attempt * 0.05, function()
        if viewer and viewer:IsShown() and not viewer._CMT_applying and baselineOrderFor(viewer) then
          layoutFunc(viewer, key, baselineOrderFor(viewer))
          dprint("CMT: Child onChange layout for [%s] (attempt %d)", key, attempt)
          
          if attempt < 2 then
            applyWithRetry(attempt + 1)
          end
        end
      end)
    end
    
    applyWithRetry(1)
    
    -- Set fast repair mode for watchdog
    _fastRepairUntil = GetTime() + 0.3
  end
  
  -- Always check for new children - don't bail early with _CMT_lifeHooked flag
  if viewer.GetNumChildren then
    local n=viewer:GetNumChildren() or 0
    for i=1,n do
      local f = select(i, viewer:GetChildren())
      -- Hook each child that hasn't been hooked yet
      if f and not f._CMT_life then
        f._CMT_life = true
        if f.HookScript then
          f:HookScript("OnShow", onChange)
          f:HookScript("OnHide", onChange)
        end
        if f.SetSize then hooksecurefunc(f,"SetSize", onChange) end
      end
    end
  end
end

-- --------------------------------------------------------------------
-- Hook viewers & bootstrap
-- --------------------------------------------------------------------
local function forceRecaptureOrder(key)
  local trackerInfo = getTrackerInfoByKey(key)
  if trackerInfo then
    local v = _G[trackerInfo.name]
    if v then
      -- Don't call v:Layout() at all - it moves the viewer!
      -- Instead, just capture icons from their current Blizzard-managed positions
      -- (Edit Mode has already positioned them correctly)
      
      -- Clear existing baseline to force fresh capture
      v._CMT_baseOrder = nil
      v._CMT_desiredSig = nil
      
      -- Small delay to ensure icons are stable
      C_Timer.After(0.1, function()
        if v and v:IsShown() then
          -- Capture from current state (Edit Mode positioning)
          local isBarType = trackerInfo.isBarType
          v._CMT_baseOrder = getBlizzardOrderedIcons(v, isBarType, false, key)
          
          dprint("CMT: Recaptured %d icons for [%s] from current state", #v._CMT_baseOrder, key)
          
          -- Apply our custom layout (icons only, viewer position untouched)
          local layoutFunc = isBarType and layoutBars or layoutCustomGrid
          layoutFunc(v, key, v._CMT_baseOrder)
        end
      end)
    end
  end
end

relayoutOne = function(key)
  -- Handle items tracker specially (CMT-owned, not Blizzard)
  if key == "items" then
    LayoutItemsTracker()
    -- Update preview if showing items
    if previewPanel and previewPanel:IsShown() and previewCurrentKey == "items" then
      PopulatePreview("items")
    end
    return
  end
  
  local trackerInfo = getTrackerInfoByKey(key)
  if trackerInfo then
    local v=_G[trackerInfo.name]
    if v then
      -- Set flag to prevent the Layout hook from overriding this manual change
      v._CMT_manualLayout = true
      
      -- Get icon order - use cached baseOrder, or get fresh icons if empty
      local iconOrder = baselineOrderFor(v)
      if #iconOrder == 0 then
        -- Try to get current visible icons directly
        iconOrder = getBlizzardOrderedIcons(v, false, false, key)
        -- Update baseOrder if we found icons
        if #iconOrder > 0 then
          v._CMT_baseOrder = iconOrder
        end
      end
      
      if trackerInfo.isBarType then
        local success, err = pcall(layoutBars, v, key, iconOrder)
        if not success then
          print("CMT ERROR in layoutBars: " .. tostring(err))
        end
      else
        local success, err = pcall(layoutCustomGrid, v, key, iconOrder)
        if not success then
          print("CMT ERROR in layoutCustomGrid: " .. tostring(err))
        end
      end
      
      -- Check if aspect ratio is non-standard
      local aspectRatio = GetSetting(key, "aspectRatio") or "1:1"
      if aspectRatio ~= "1:1" then
        -- Keep manual layout flag SET to prevent Blizzard from overriding
        -- Don't clear it! This prevents the Layout hook from fighting us
        dprint("CMT: Keeping manual layout flag for [%s] (aspect=%s)", key, aspectRatio)
      else
        -- Clear flag after delay for standard aspect
        C_Timer.After(2.0, function()
          if v then v._CMT_manualLayout = nil end
        end)
      end
    end
  end
  
  -- Update preview if showing this tracker
  if previewPanel and previewPanel:IsShown() and previewCurrentKey == key then
    UpdatePreviewLayout(key)
  end
end

local function hookViewer(viewer, key)
  if viewer._CMT_Hooked then return end
  viewer._CMT_Hooked=true; viewer._CMT_Key=key
  
  local trackerInfo = getTrackerInfoByKey(key)
  local layoutFunc = (trackerInfo and trackerInfo.isBarType) and layoutBars or layoutCustomGrid
  local isBarType = trackerInfo and trackerInfo.isBarType

  -- Hook SetPoint on the viewer itself to catch ANY position changes
  if viewer.SetPoint and not viewer._CMT_SetPointHooked then
    viewer._CMT_SetPointHooked = true
    hooksecurefunc(viewer, "SetPoint", function(self, point, relativeTo, relativePoint, x, y)
      if POSITION_WATCH then
        -- Get call stack to identify source
        local source = debugstack(2, 1, 0) or "unknown"
        -- Extract just the relevant part (file:line)
        local shortSource = source:match("([^/\\]+%.lua:%d+)") or source:sub(1, 60)
        posWatch("[%s] SetPoint: %.1f, %.1f (from %s)", key, x or 0, y or 0, shortSource)
      end
    end)
    hooksecurefunc(viewer, "ClearAllPoints", function(self)
      if POSITION_WATCH then
        local source = debugstack(2, 1, 0) or "unknown"
        local shortSource = source:match("([^/\\]+%.lua:%d+)") or source:sub(1, 60)
        posWatch("[%s] ClearAllPoints (from %s)", key, shortSource)
      end
    end)
  end

  -- Capture Blizzard baseline ONLY here (never from our own layout)
  if type(viewer.Layout)=="function" then
    hooksecurefunc(viewer,"Layout", function(s)
      -- Debug: Check if Buff tracker drifted when another tracker's Layout is called
      if POSITION_DEBUG and key ~= "buffs" then
        local buffViewer = _G["BuffIconCooldownViewer"]
        if buffViewer and buffViewer._CMT_knownGoodPosition then
          local pos = buffViewer._CMT_knownGoodPosition
          local _, _, _, bx, by = buffViewer:GetPoint(1)
          if bx and pos.x and (math.abs(bx - pos.x) > 0.5 or math.abs(by - pos.y) > 0.5) then
            posDebug("  WARNING: [buffs] drifted during [%s] Layout! was %.1f,%.1f should be %.1f,%.1f", 
              key, bx, by, pos.x, pos.y)
          end
        end
      end
      
      -- Skip if we're triggering Layout just to fix position
      if s._CMT_skipNextLayout then
        s._CMT_skipNextLayout = nil
        dprint("CMT: Skipping Layout hook (position fix trigger)")
        return
      end
      
      -- Skip if already in a layout operation
      if s._CMT_applying then 
        return 
      end
      
      -- Get current icon list
      local currentIcons = getBlizzardOrderedIcons(s, isBarType, false, key)
      
      -- ANCHOR FIX: If we have a baseline and icon count/identities haven't changed,
      -- this is likely an anchor-triggered Layout call (e.g., Player Frame anchored to us)
      -- These calls happen when the anchored frame updates, not when our icons change
      if s._CMT_baseOrder and #currentIcons == #s._CMT_baseOrder then
        local iconsChanged = false
        for i = 1, #currentIcons do
          if currentIcons[i] ~= s._CMT_baseOrder[i] then
            iconsChanged = true
            break
          end
        end
        
        -- If icons are identical, this is just an anchor update - ignore it
        if not iconsChanged then
          dprint("CMT: Ignoring Layout call for [%s] - icons unchanged (likely anchor update)", key)
          return
        end
      end
      
      -- If manual layout flag is set (for aspect ratio), we still need to check for NEW icons
      -- Just don't recapture the order from Blizzard's positioning
      if s._CMT_manualLayout then
        -- Check if icon COUNT changed (new icons added/removed)
        if s._CMT_baseOrder and #currentIcons ~= #s._CMT_baseOrder then
          dprint("CMT: Icon count changed for [%s] while manual layout active: %d -> %d", 
            key, #s._CMT_baseOrder, #currentIcons)
          -- New icons appeared - need to recapture and reapply multiple times
          -- Blizzard may reset icons after we set them, so we need to be persistent
          
          local function applyWithRetry(attempt)
            if attempt > 5 then return end -- Stop after 5 attempts
            
            C_Timer.After(attempt * 0.1, function()
              if s and s:IsShown() and not s._CMT_applying then
                -- Recapture fresh to get the new icons
                local freshIcons = getBlizzardOrderedIcons(s, isBarType, false, key)
                s._CMT_baseOrder = freshIcons
                layoutFunc(s, key, s._CMT_baseOrder)
                dprint("CMT: Applied layout for [%s] (attempt %d, %d icons)", key, attempt, #freshIcons)
                
                -- Schedule next attempt
                if attempt < 5 then
                  applyWithRetry(attempt + 1)
                end
              end
            end)
          end
          
          applyWithRetry(1)
        end
        -- Manual layout is active, don't process Blizzard's layout further
        return
      end
      
      -- Check if icons morphed (changed identity but same count)
      local iconsMorphed = false
      if s._CMT_baseOrder and #currentIcons == #s._CMT_baseOrder then
        for i = 1, #currentIcons do
          if currentIcons[i] ~= s._CMT_baseOrder[i] then
            iconsMorphed = true
            break
          end
        end
      end
      
      -- Check if this is a rapid spam (multiple Layout calls within threshold)
      -- When frames are anchored TO us, Blizzard calls our Layout() frequently
      -- BUT: Always process if icons morphed (must reapply layout after morph)
      local now = GetTime()
      local spamThreshold = 0.25  -- Increased from 0.2 to better catch anchor spam
      
      if s._CMT_lastLayoutTime and (now - s._CMT_lastLayoutTime) < spamThreshold then
        -- If icons morphed, we need to process it even if it's rapid
        if not iconsMorphed then
          -- Rapid spam detected and no morph - completely ignore it
          dprint("CMT: Ignoring rapid Layout spam for [%s] (%.3fs since last)", key, now - s._CMT_lastLayoutTime)
          return
        else
          -- Icons morphed during rapid spam - this is the real event, process it
          dprint("CMT: Icons morphed during rapid spam for [%s] - processing", key)
        end
      end
      
      -- Check if viewer just became visible (combat-only showing up)
      if not s._CMT_wasVisible and s:IsShown() then
        -- Viewer just became visible - don't recapture yet, just reapply with retries
        s._CMT_wasVisible = true
        dprint("CMT: Viewer [%s] just became visible, reapplying with retries", key)
        
        local function applyWithRetry(attempt)
          if attempt > 3 then return end
          
          C_Timer.After(attempt * 0.05, function()
            if s and s:IsShown() and not s._CMT_applying and s._CMT_baseOrder then
              layoutFunc(s, key, s._CMT_baseOrder)
              dprint("CMT: Visibility layout for [%s] (attempt %d)", key, attempt)
              
              if attempt < 3 then
                applyWithRetry(attempt + 1)
              end
            end
          end)
        end
        
        applyWithRetry(1)
        
        s._CMT_lastLayoutTime = now
        _fastRepairUntil = GetTime() + 0.5
        return
      end
      s._CMT_wasVisible = s:IsShown()
      
      s._CMT_lastLayoutTime = now
      
      -- Check if we need to recapture baseline
      -- Reasons to recapture:
      -- 1. No baseline exists yet (first time)
      -- 2. Icon count changed (icons added/removed)
      -- BUT NOT: Icon identities changed with same count (ability morphing/swapping) - preserve custom order!
      -- For same-count changes, let the guardian watchdog fix mismatches
      local needsRecapture = not s._CMT_baseOrder or #s._CMT_baseOrder == 0 or #currentIcons ~= #s._CMT_baseOrder
      
      -- ANCHOR FIX: Add a cooldown on recaptures to prevent anchor-triggered Layout calls
      -- from interfering during morph handling. If we just recaptured/reapplied recently,
      -- and it's not a count change, skip this Layout call.
      if needsRecapture and s._CMT_lastRecaptureTime then
        local timeSinceRecapture = GetTime() - s._CMT_lastRecaptureTime
        if timeSinceRecapture < 0.5 and #currentIcons == #s._CMT_baseOrder then
          -- Recently recaptured with same count - probably anchor spam during morph
          dprint("CMT: Skipping recapture for [%s] - too soon after last recapture (%.3fs)", key, timeSinceRecapture)
          needsRecapture = false
        end
      end
      
      -- If count is same but icon references changed, check if it's ACTUAL morphing
      -- (same spell IDs, different icon frames) vs REORDERING (different spell IDs)
      if not needsRecapture and s._CMT_baseOrder and #currentIcons == #s._CMT_baseOrder then
        -- Build a map from current icons (visual order from Blizzard)
        -- Use getMatchIdentifier to get stable IDs (spellID for buffs)
        local currentIdentifierMap = {}
        for i = 1, #currentIcons do
          local identifier = getMatchIdentifier(currentIcons[i], key)
          if identifier then
            -- Store the icon frame for each identifier
            currentIdentifierMap[identifier] = currentIcons[i]
          end
        end
        
        -- Build a set of identifiers from cached baseline (our custom order)
        local baselineIdentifiers = {}
        for i = 1, #s._CMT_baseOrder do
          local identifier = getMatchIdentifier(s._CMT_baseOrder[i], key)
          if identifier then
            baselineIdentifiers[identifier] = (baselineIdentifiers[identifier] or 0) + 1
          end
        end
        
        -- Check if identifier sets are identical (true morph) or different (reorder by Blizzard)
        local identifiersMatch = true
        for identifier, _ in pairs(currentIdentifierMap) do
          if not baselineIdentifiers[identifier] then
            identifiersMatch = false
            break
          end
        end
        if identifiersMatch then
          for identifier, count in pairs(baselineIdentifiers) do
            if not currentIdentifierMap[identifier] then
              identifiersMatch = false
              break
            end
          end
        end
        
        -- If identifiers match, update icon frame references by matching identifiers
        -- This preserves our custom order while updating the frame pointers
        if identifiersMatch then
          local morphDetected = false
          for i = 1, #s._CMT_baseOrder do
            local oldFrame = s._CMT_baseOrder[i]
            local identifier = getMatchIdentifier(oldFrame, key)
            local newFrame = currentIdentifierMap[identifier]
            
            -- If the frame reference changed for this identifier, update it
            if newFrame and newFrame ~= oldFrame then
              morphDetected = true
              dprint("CMT: Updating frame reference for spell %d at position %d in [%s]", 
                identifier or 0, i, key)
              s._CMT_baseOrder[i] = newFrame
            end
          end
          
          if morphDetected then
            dprint("CMT: Updated icon frame references for [%s] after morph (custom order preserved)", key)
            -- Reapply layout with updated references in our custom order
            -- Use multiple retries to ensure aspect ratio sticks on new frames
            local function applyWithRetry(attempt)
              if attempt > 3 then return end
              
              C_Timer.After(attempt * 0.05, function()
                if s and s:IsShown() and not s._CMT_applying then
                  layoutFunc(s, key, s._CMT_baseOrder)
                  dprint("CMT: Applied layout after morph for [%s] (attempt %d)", key, attempt)
                  
                  -- Continue retrying to ensure aspect ratio sticks
                  if attempt < 3 then
                    applyWithRetry(attempt + 1)
                  end
                end
              end)
            end
            
            applyWithRetry(1)
            
            -- Also set fast repair mode for watchdog
            _fastRepairUntil = GetTime() + 0.5
            return
          end
        else
          -- Identifiers don't match but count is same - this is Blizzard scrambling frames
          -- FIX: Update frame references immediately by matching spellIDs to current frames
          dprint("CMT: Identifier set changed for [%s] but count unchanged (%d) - updating frame references", 
            key, #currentIcons)
          
          -- Build map of identifier -> current frame
          local currentFrameMap = {}
          for _, icon in ipairs(currentIcons) do
            local identifier = getMatchIdentifier(icon, key)
            if identifier then
              currentFrameMap[identifier] = icon
            end
          end
          
          -- Update baseOrder frame references while preserving order
          local updatedBaseOrder = {}
          local usedIdentifiers = {}
          local updateCount = 0
          
          for i, oldFrame in ipairs(s._CMT_baseOrder) do
            local identifier = getMatchIdentifier(oldFrame, key)
            if identifier and currentFrameMap[identifier] and not usedIdentifiers[identifier] then
              -- Found matching current frame - use it
              if currentFrameMap[identifier] ~= oldFrame then
                updateCount = updateCount + 1
              end
              updatedBaseOrder[i] = currentFrameMap[identifier]
              usedIdentifiers[identifier] = true
            else
              -- Frame no longer exists or already used - will be handled in layout
              updatedBaseOrder[i] = oldFrame
            end
          end
          
          -- Add any new icons that weren't in baseOrder
          for _, icon in ipairs(currentIcons) do
            local identifier = getMatchIdentifier(icon, key)
            if identifier and not usedIdentifiers[identifier] then
              table.insert(updatedBaseOrder, icon)
              usedIdentifiers[identifier] = true
            end
          end
          
          if updateCount > 0 then
            s._CMT_baseOrder = updatedBaseOrder
            dprint("CMT: Updated %d frame references for [%s]", updateCount, key)
          end
        end
      end
      
      if needsRecapture then
        s._CMT_baseOrder = currentIcons
        s._CMT_desiredSig = nil
        s._CMT_lastRecaptureTime = GetTime()  -- Track when we recaptured
        dprint("CMT: Recaptured baseline for [%s]: %d icons", key, #currentIcons)
      else
        dprint("CMT: Skipping recapture for [%s]: icons unchanged (%d)", key, #currentIcons)
      end
      
      -- Cancel any pending layout timer
      if s._CMT_layoutTimer then
        s._CMT_layoutTimer:Cancel()
      end
      
      -- Apply our layout immediately
      C_Timer.After(0, function()
        if s and s:IsShown() and not s._CMT_applying then
          layoutFunc(s, key, s._CMT_baseOrder)
          
          -- Debug: Check if processing this tracker caused Buff tracker to drift
          if POSITION_DEBUG and key ~= "buffs" then
            local buffViewer = _G["BuffIconCooldownViewer"]
            if buffViewer and buffViewer._CMT_knownGoodPosition then
              local pos = buffViewer._CMT_knownGoodPosition
              local _, _, _, bx, by = buffViewer:GetPoint(1)
              if bx and pos.x and (math.abs(bx - pos.x) > 0.5 or math.abs(by - pos.y) > 0.5) then
                posDebug("  WARNING: [buffs] drifted AFTER [%s] layout! was %.1f,%.1f should be %.1f,%.1f - RESTORING", 
                  key, bx, by, pos.x, pos.y)
                -- Auto-restore Buff tracker
                buffViewer:ClearAllPoints()
                buffViewer:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.x, pos.y)
              end
            end
          end
          
          -- Deferred position restoration - catch any post-layout drift from Blizzard
          -- This runs after Blizzard has had a chance to recalculate bounds
          C_Timer.After(0.05, function()
            if s and s._CMT_knownGoodPosition and not IsEditModeActive() then
              local pos = s._CMT_knownGoodPosition
              local currentPoint, currentRelativeTo, currentRelativePoint, currentX, currentY = s:GetPoint(1)
              if currentX and pos.x and (math.abs(currentX - pos.x) > 0.5 or math.abs(currentY - pos.y) > 0.5) then
                posDebug("[%s] DRIFT in Layout hook: was %.1f,%.1f should be %.1f,%.1f - RESTORING", 
                  key, currentX, currentY, pos.x, pos.y)
                s:ClearAllPoints()
                s:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.x, pos.y)
              end
            end
            
            -- Also check/restore Buff tracker after any tracker's deferred position check
            if key ~= "buffs" then
              local buffViewer = _G["BuffIconCooldownViewer"]
              if buffViewer and buffViewer._CMT_knownGoodPosition and not IsEditModeActive() then
                local pos = buffViewer._CMT_knownGoodPosition
                local _, _, _, bx, by = buffViewer:GetPoint(1)
                if bx and pos.x and (math.abs(bx - pos.x) > 0.5 or math.abs(by - pos.y) > 0.5) then
                  posDebug("  [buffs] CROSS-TRACKER DRIFT from [%s]: was %.1f,%.1f should be %.1f,%.1f - RESTORING", 
                    key, bx, by, pos.x, pos.y)
                  buffViewer:ClearAllPoints()
                  buffViewer:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.x, pos.y)
                end
              end
            end
          end)
        end
      end)
      
      -- Also set fast repair mode so the watchdog catches any further drift immediately
      _fastRepairUntil = GetTime() + 0.3
    end)
  end

  -- Re-layout from cached baseline; never overwrite it here
  -- Add recursion protection to prevent feedback loops
  -- CRITICAL: Don't pass orderFromBlizz parameter - always use cached _CMT_baseOrder
  -- BUFFS: Allow layout even without cached baseline (will fetch fresh)
  viewer:HookScript("OnSizeChanged", function(s)
    if not s._CMT_applying and (s._CMT_baseOrder or key == "buffs") then
      layoutFunc(s, key, nil) -- nil = use cached order (or fresh for buffs)
    end
  end)
  viewer:HookScript("OnShow", function(s)
    if not s._CMT_applying and (s._CMT_baseOrder or key == "buffs") then
      -- Apply multiple times with short delays to ensure aspect ratio sticks
      -- This is especially important when entering combat and buffs appear
      local function applyWithRetry(attempt)
        if attempt > 3 then return end
        
        C_Timer.After(attempt * 0.05, function()
          if s and s:IsShown() and not s._CMT_applying and (s._CMT_baseOrder or key == "buffs") then
            layoutFunc(s, key, nil)
            dprint("CMT: OnShow layout for [%s] (attempt %d)", key, attempt)
            
            -- Continue retrying to ensure aspect ratio sticks
            if attempt < 3 then
              applyWithRetry(attempt + 1)
            end
          end
        end)
      end
      
      applyWithRetry(1)
      
      -- Set fast repair mode for watchdog
      _fastRepairUntil = GetTime() + 0.5
    end
  end)
end

-- ====================================================================
-- PERSISTENT BUFF DISPLAY SYSTEM (v3.2.0)
-- ====================================================================
-- Shows all available buffs with visual indication of active vs inactive state.
-- Inactive buffs are desaturated and faded to improve cooldown awareness.
-- This system works with Blizzard's buff selections (respects Cooldown Settings).

-- Track buff states
local buffStates = {} -- [icon] = { spellID, lastActiveState, texture }
local buffUpdateFrame = nil
local UPDATE_INTERVAL = 0.1 -- Check buff states 10 times per second

-- Get spell ID from a buff icon (BuffIconCooldownViewer doesn't set .spellID directly)
local function GetIconSpellID(icon)
  if not icon then return nil end
  
  -- Try direct spellID field first  
  if icon.spellID then return icon.spellID end
  
  -- Try auraInstanceID (most reliable method for buff icons)
  local success, result = pcall(function()
    if icon.auraInstanceID then
      -- Look up the spell ID using the aura instance ID
      for i = 1, 40 do
        local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not auraData then break end
        
        if auraData.auraInstanceID == icon.auraInstanceID then
          return auraData.spellId
        end
      end
    end
    
    -- Fall back to texture matching if auraInstanceID not available
    if icon.Icon then
      local texture = icon.Icon:GetTexture()
      if texture then
        for i = 1, 40 do
          local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
          if not auraData then break end
          
          if auraData.icon and auraData.icon == texture then
            return auraData.spellId
          end
        end
      end
    end
    
    return nil
  end)
  
  if success then
    return result
  else
    return nil
  end
end

-- Get all active buff spell IDs on player
local function GetActiveBuffSpellIDs()
  local activeBuffs = {}
  
  -- Scan player's helpful auras
  for i = 1, 40 do
    local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
    if not auraData then break end
    
    -- Only include buffs that have actual duration (not permanent passive auras)
    -- A buff with duration=0 is a permanent effect, not a temporary buff
    if auraData.spellId and auraData.duration > 0 then
      activeBuffs[auraData.spellId] = auraData.name  -- Store name too for debugging
    end
  end
  
  return activeBuffs
end

-- Apply visual state to a buff icon based on whether it's active
local function ApplyBuffVisualState(icon, isActive, forceUpdate)
  if not icon or not icon:IsShown() then return end
  
  -- Check if Masque controls visuals for this tracker
  local masqueControlsVisuals = MasqueModule and MasqueModule.ControlsVisualsForTracker and MasqueModule.ControlsVisualsForTracker("buffs")
  
  -- Get settings
  local enabled = GetSetting("buffs", "persistentDisplay")
  if not enabled then
    -- Feature disabled - ensure normal appearance
    if icon.Icon then
      icon.Icon:SetDesaturated(false)
      icon:SetAlpha(1.0)
    end
    if icon.Cooldown then
      icon.Cooldown:Show()
    end
    return
  end
  
  local inactiveAlpha = GetSetting("buffs", "inactiveAlpha") or 0.5
  local iconOpacity = GetSetting("buffs", "iconOpacity") or 1.0
  local greyscaleInactive = GetSetting("buffs", "greyscaleInactive")
  if greyscaleInactive == nil then greyscaleInactive = true end  -- Default to true
  
  -- Store current state if not already tracked
  if not buffStates[icon] then
    buffStates[icon] = {
      spellID = icon.spellID,
      lastActiveState = nil,
      texture = icon.Icon and icon.Icon:GetTexture()
    }
  end
  
  -- Only update if state changed or forced
  if not forceUpdate and buffStates[icon].lastActiveState == isActive then
    return
  end
  
  buffStates[icon].lastActiveState = isActive
  
  -- Get base values stored during layout
  local baseWidth = icon._CMT_baseWidth or 36
  local baseHeight = icon._CMT_baseHeight or 36
  local baseX = icon._CMT_baseX
  local baseY = icon._CMT_baseY
  local baseAspect = icon._CMT_baseAspect or "1:1"
  local baseZoom = icon._CMT_baseZoom or 0
  local baseBorderAlpha = icon._CMT_baseBorderAlpha or 1.0
  local baseFrameLevel = icon._CMT_baseFrameLevel or icon:GetFrameLevel()
  
  -- Check for per-icon state-specific overrides
  -- Skip ALL per-icon overrides when Edit Mode is active to preserve tracker bounds
  local slotIndex = icon._CMT_slotIndex
  local identifier = slotIndex and GetIconIdentifier("buffs", nil, slotIndex) or nil
  local stateSettings = nil
  
  if identifier and not IsEditModeActive() then
    local overrides = GetIconOverrides("buffs")
    if overrides and overrides[identifier] then
      local override = GetIconOverride("buffs", identifier)
      local stateKey = isActive and "activeState" or "inactiveState"
      stateSettings = override[stateKey]
    end
  end
  
  -- Save parent position BEFORE any icon changes
  local parent = icon:GetParent()
  local savedParentPoint, savedParentRelativeTo, savedParentRelativePoint, savedParentX, savedParentY
  if parent and parent.GetPoint then
    savedParentPoint, savedParentRelativeTo, savedParentRelativePoint, savedParentX, savedParentY = parent:GetPoint(1)
  end
  
  if stateSettings and next(stateSettings) then
    -- Apply state-specific override settings, inheriting from global where not set
    
    -- Calculate effective icon dimensions
    -- If there's an aspect override, recalculate from base icon size
    local effectiveWidth, effectiveHeight = baseWidth, baseHeight
    local effectiveAspect = stateSettings.aspectOverride or baseAspect
    
    if stateSettings.aspectOverride then
      -- Recalculate dimensions from base icon size using new aspect ratio
      local baseIconSize = icon._CMT_baseIconSize or math.max(baseWidth, baseHeight)
      local aspectW, aspectH = ParseAspectRatio(effectiveAspect)
      
      if aspectW > aspectH then
        -- Wide aspect (16:9, 21:9, 4:3)
        effectiveWidth = baseIconSize
        effectiveHeight = (baseIconSize * aspectH) / aspectW
      elseif aspectH > aspectW then
        -- Tall aspect (9:16, 3:4)
        effectiveWidth = (baseIconSize * aspectW) / aspectH
        effectiveHeight = baseIconSize
      else
        -- Square (1:1)
        effectiveWidth = baseIconSize
        effectiveHeight = baseIconSize
      end
    end
    
    -- Apply size multiplier using SetSize
    local sizeMultiplier = stateSettings.sizeMultiplier or 1.0
    -- Set applying flag to prevent hook cascade during size/position changes
    if parent then parent._CMT_applying = true end
    
    -- Apply size with multiplier
    icon:SetSize(effectiveWidth * sizeMultiplier, effectiveHeight * sizeMultiplier)
    icon:SetScale(1.0)  -- Reset any previous scale
    
    -- Opacity - inherit from global iconOpacity/inactiveAlpha if not set
    -- For inactive buffs, multiply inactiveAlpha by iconOpacity
    local opacity = stateSettings.opacity
    if opacity == nil then
      if isActive then
        opacity = iconOpacity
      else
        opacity = inactiveAlpha * iconOpacity
      end
    end
    icon:SetAlpha(opacity)
    
    -- Desaturate - inherit from global greyscaleInactive setting if not explicitly set
    local desaturate = stateSettings.desaturate
    if desaturate == nil then
      -- For active buffs: never desaturate. For inactive: use global setting
      desaturate = (not isActive) and greyscaleInactive
    end
    if icon.Icon then
      icon.Icon:SetDesaturated(desaturate)
    end
    
    -- Position with nudge (skip when Edit Mode active to preserve tracker bounds)
    local nudgeX = stateSettings.nudgeX or 0
    local nudgeY = stateSettings.nudgeY or 0
    local applyNudge = (nudgeX ~= 0 or nudgeY ~= 0) and not IsEditModeActive()
    if baseX and baseY then
      icon:ClearAllPoints()
      if applyNudge then
        icon:SetPoint("TOPLEFT", parent, "TOPLEFT", baseX + nudgeX, -(baseY + nudgeY))
      else
        icon:SetPoint("TOPLEFT", parent, "TOPLEFT", baseX, -baseY)
      end
    end
    
    -- Clear applying flag now that size/position changes are done
    if parent then parent._CMT_applying = nil end
    
    -- Frame level for overlapping
    if applyNudge or sizeMultiplier > 1.0 then
      icon:SetFrameLevel(baseFrameLevel + 10)
    else
      icon:SetFrameLevel(baseFrameLevel)
    end
    
    -- Zoom and aspect overrides (texture coords) - skip if Masque controls visuals
    if not masqueControlsVisuals then
      local effectiveZoom = stateSettings.zoomOverride or baseZoom
      applyIconAspectAndZoom(icon, effectiveAspect, effectiveZoom)
    end
    
    -- Apply custom border (skip if Masque active - it controls borders)
    if not masqueControlsVisuals then
      if stateSettings.borderColor then
        applyCustomBorder(icon, stateSettings.borderColor, stateSettings.borderWidth, stateSettings.borderAlpha)
      else
        applyCustomBorder(icon, nil)  -- Remove any existing border
      end
    end
    
    -- Apply timer (cooldown) text scale and color
    local timerScale = stateSettings.timerScale
    local timerColor = stateSettings.timerColor
    if timerScale or timerColor then
      local cooldown = icon.Cooldown or icon.cooldown
      if cooldown then
        for _, region in ipairs({cooldown:GetRegions()}) do
          if region and region:GetObjectType() == "FontString" then
            if timerScale then
              local font, size, flags = region:GetFont()
              if font and size then
                if not region._CMT_originalSize then
                  region._CMT_originalSize = size
                end
                region:SetFont(font, region._CMT_originalSize * timerScale, flags)
              end
            end
            if timerColor then
              region:SetTextColor(timerColor[1], timerColor[2], timerColor[3], 1)
            end
            break
          end
        end
      end
    end
    
    -- Apply count (stack) text scale and color
    local countScale = stateSettings.countScale
    local countColor = stateSettings.countColor
    if countScale or countColor then
      local countText = icon.Count or icon.count
      if countText and countText.GetObjectType and countText:GetObjectType() == "FontString" then
        if countScale then
          local font, size, flags = countText:GetFont()
          if font and size then
            if not countText._CMT_originalSize then
              countText._CMT_originalSize = size
            end
            countText:SetFont(font, countText._CMT_originalSize * countScale, flags)
          end
        end
        if countColor then
          countText:SetTextColor(countColor[1], countColor[2], countColor[3], 1)
        end
      end
    end
  else
    -- No per-icon overrides, use default behavior
    -- Reset to base values
    local parent = icon:GetParent()
    -- Set applying flag to prevent hook cascade
    if parent then parent._CMT_applying = true end
    
    -- When Masque active, use square icons
    if masqueControlsVisuals then
      icon:SetSize(40, 40)
      icon:SetScale((icon._CMT_baseIconSize or 40) / 40)
    else
      icon:SetSize(baseWidth, baseHeight)
      icon:SetScale(1.0)  -- Reset any previous scale
    end
    
    if baseX and baseY then
      icon:ClearAllPoints()
      icon:SetPoint("TOPLEFT", parent, "TOPLEFT", baseX, -baseY)
    end
    
    if parent then parent._CMT_applying = nil end
    
    icon:SetFrameLevel(baseFrameLevel)
    
    -- Skip texture coord changes if Masque active
    if not masqueControlsVisuals then
      applyIconAspectAndZoom(icon, baseAspect, baseZoom)
      -- Remove any custom border
      applyCustomBorder(icon, nil)
    end
    
    -- Reset timer text to original size/color if it was modified
    local cooldown = icon.Cooldown or icon.cooldown
    if cooldown then
      for _, region in ipairs({cooldown:GetRegions()}) do
        if region and region:GetObjectType() == "FontString" then
          if region._CMT_originalSize then
            local font, _, flags = region:GetFont()
            if font then
              region:SetFont(font, region._CMT_originalSize, flags)
            end
          end
          -- Reset to default white color
          region:SetTextColor(1, 1, 1, 1)
          break
        end
      end
    end
    
    -- Reset count text to original size/color if it was modified
    local countText = icon.Count or icon.count
    if countText and countText.GetObjectType and countText:GetObjectType() == "FontString" then
      if countText._CMT_originalSize then
        local font, _, flags = countText:GetFont()
        if font then
          countText:SetFont(font, countText._CMT_originalSize, flags)
        end
      end
      -- Reset to default white color
      countText:SetTextColor(1, 1, 1, 1)
    end
    
    if icon.Icon then
      if isActive then
        icon.Icon:SetDesaturated(false)
        icon:SetAlpha(iconOpacity)
      else
        icon.Icon:SetDesaturated(greyscaleInactive)
        icon:SetAlpha(inactiveAlpha * iconOpacity)
      end
    end
  end
  
  -- Handle cooldown display (timer and sweep)
  if icon.Cooldown then
    if isActive then
      icon.Cooldown:Show()
    else
      -- Hide cooldown on inactive buffs (no timer/sweep when buff not active)
      icon.Cooldown:Hide()
    end
  end
  
  -- Restore parent position if it moved during our changes
  if savedParentPoint and savedParentX and parent and not IsEditModeActive() then
    local currentPoint, currentRelativeTo, currentRelativePoint, currentX, currentY = parent:GetPoint(1)
    if currentX and (math.abs(currentX - savedParentX) > 0.5 or math.abs(currentY - savedParentY) > 0.5) then
      parent:ClearAllPoints()
      parent:SetPoint(savedParentPoint, savedParentRelativeTo, savedParentRelativePoint, savedParentX, savedParentY)
      posDebug("[buffs] Parent moved during ApplyBuffVisualState - restored to %.1f,%.1f", savedParentX, savedParentY)
    end
  end
end

-- Update all buff icons' visual states
local function UpdateAllBuffVisuals(forceUpdate)
  local viewer = _G["BuffIconCooldownViewer"]
  if not viewer or not viewer:IsShown() then 
    return 
  end
  
  -- Save viewer position before making changes (in case Blizzard tries to move it)
  local savedPoint, savedRelativeTo, savedRelativePoint, savedX, savedY
  if viewer.GetPoint then
    savedPoint, savedRelativeTo, savedRelativePoint, savedX, savedY = viewer:GetPoint(1)
  end
  
  -- Set applying flag on viewer to prevent drift detection and hook cascades
  viewer._CMT_applying = true
  
  -- Check if feature is enabled
  local enabled = GetSetting("buffs", "persistentDisplay")
  if enabled == nil then enabled = true end  -- Default to true if not set
  
  if not enabled then
    -- Feature disabled - ensure all buffs show normally
    for icon in pairs(buffStates) do
      if icon and icon:IsShown() then
        if icon.Icon then
          icon.Icon:SetDesaturated(false)
        end
        icon:SetAlpha(1.0)
        if icon.Cooldown then
          icon.Cooldown:Show()
        end
      end
    end
    -- Clear state tracking
    buffStates = {}
    return
  end
  
  -- Get all buff icons from viewer
  local icons = collectIcons(viewer)
  -- Debug disabled to prevent secret value errors
  -- if not InCombatLockdown() then
  --   print("CMT DEBUG: collectIcons returned", #icons, "icons")
  -- end
  
  for idx, icon in ipairs(icons) do
    -- Try to get spellID from the icon itself
    local spellID = GetIconSpellID(icon)
    
    -- Get the icon texture (stable identifier that persists even when auraInstanceID is gone)
    -- Skip texture reading in combat as it becomes a secret value
    local texture = nil
    
    if not InCombatLockdown() and icon.Icon then
      local success, tex = pcall(function() return icon.Icon:GetTexture() end)
      if success and tex then
        -- Verify we can actually use this texture (not a secret value)
        local testSuccess = pcall(function()
          local _ = tostring(tex) -- Try to convert to string
          local __ = tex == tex   -- Try to compare to itself
        end)
        if testSuccess then
          texture = tex
        end
      end
    end
    
    -- If we successfully identified this icon, save the texture-to-spellID mapping
    -- Only do this out of combat to avoid secret value issues
    if not InCombatLockdown() and spellID and texture then
      -- Ensure buffIconMappings exists first
      if not CMT_CharDB.buffIconMappings then
        CMT_CharDB.buffIconMappings = {}
      end
      
      -- Protect against secret values even out of combat (brief window after combat)
      local success = pcall(function()
        CMT_CharDB.buffIconMappings[texture] = spellID
      end)
      -- If it fails, texture is still secret - ignore silently
    end
    
    -- Always update in-memory cache regardless of combat state
    if spellID then
      if not buffStates[icon] then
        buffStates[icon] = {}
      end
      buffStates[icon].spellID = spellID
      if texture then
        -- Protect against secret texture value
        pcall(function()
          buffStates[icon].texture = texture
        end)
      end
    end
    
    -- If we couldn't identify directly, try multiple fallback methods:
    if not spellID then
      -- Method 1: Check our in-memory buffStates cache (works in combat!)
      if buffStates[icon] and buffStates[icon].spellID then
        spellID = buffStates[icon].spellID
      end
      
      -- Method 2: Check saved variables using texture (only out of combat)
      if not InCombatLockdown() and not spellID and texture then
        -- Protect against secret texture values
        local success, result = pcall(function()
          -- Ensure buffIconMappings exists first
          if not CMT_CharDB.buffIconMappings then
            CMT_CharDB.buffIconMappings = {}
          end
          
          if CMT_CharDB.buffIconMappings[texture] then
            return CMT_CharDB.buffIconMappings[texture]
          end
          return nil
        end)
        
        if success and result then
          spellID = result
          -- Also update in-memory cache
          if not buffStates[icon] then
            buffStates[icon] = {}
          end
          buffStates[icon].spellID = spellID
          -- Store texture in another pcall
          pcall(function()
            buffStates[icon].texture = texture
          end)
        end
      end
    end
    
    local spellName = "Unknown"
    if spellID then
      local spellInfo = C_Spell.GetSpellInfo(spellID)
      if spellInfo and spellInfo.name then
        spellName = spellInfo.name
      end
    end
    
    -- CRITICAL: Determine if buff is active by checking if icon has auraInstanceID
    -- No need to query C_UnitAuras - the icon itself tells us if the buff is active!
    local isActive = (icon.auraInstanceID ~= nil)
    
    -- Debug output disabled to prevent secret value errors
    -- if not InCombatLockdown() then
    --   print("CMT DEBUG: Icon", idx)
    --   print("  IsShown:", icon:IsShown())
    --   print("  auraInstanceID:", icon.auraInstanceID)
    --   -- Texture might still be secret right after combat, protect it
    --   local textureStr = "nil"
    --   if texture then
    --     local success, result = pcall(tostring, texture)
    --     textureStr = success and result or "[secret]"
    --   end
    --   print("  texture:", textureStr)
    --   print("  spellID (via GetIconSpellID):", spellID)
    --   print("  spellName:", spellName)
    --   print("  isActive (has auraInstanceID):", isActive)
    --   print("  .Icon type:", type(icon.Icon))
    --   print("  .icon type:", type(icon.icon))
    -- end
    
    -- Investigation debug disabled to prevent secret value errors
    -- if icon:IsShown() and not icon.auraInstanceID and not spellID then
    --   print("  === INVESTIGATING UNIDENTIFIED ICON ===")
    --   
    --   -- Check for item-related fields
    --   if icon.itemID then print("    itemID:", icon.itemID) end
    --   if icon.itemLink then print("    itemLink:", icon.itemLink) end
    --   
    --   -- Check for spell-related fields
    --   if icon.spell then print("    spell:", icon.spell) end
    --   if icon.spellName then print("    spellName:", icon.spellName) end
    --   
    --   -- Check cooldown info
    --   if icon.Cooldown then
    --     local start, duration = icon.Cooldown:GetCooldownTimes()
    --     if start and start > 0 then
    --       print("    Cooldown active: start=" .. start .. ", duration=" .. duration)
    --     end
    --   end
    --   
    --   -- Try to get texture info
    --   if icon.Icon then
    --     local success, tex = pcall(function() return icon.Icon:GetTexture() end)
    --     if success and tex then
    --       -- Protect against secret values
    --       local texSuccess, texStr = pcall(tostring, tex)
    --       if texSuccess then
    --         print("    Texture:", texStr)
    --       end
    --     end
    --   end
    --   
    --   print("  === END INVESTIGATION ===")
    -- end
    
    if icon and icon:IsShown() then
      -- Even if we don't have spellID yet, we can still apply visuals based on auraInstanceID
      -- Per-icon overrides use slotIndex, not spellID, so they still work
      local tempIsActive = (icon.auraInstanceID ~= nil)
      
      if not spellID then
        -- No spellID yet - use a simplified path but still respect per-icon overrides
        -- Skip per-icon overrides when Edit Mode is active to preserve tracker bounds
        local slotIndex = icon._CMT_slotIndex
        local identifier = slotIndex and GetIconIdentifier("buffs", nil, slotIndex) or nil
        local stateSettings = nil
        
        -- Check for per-icon overrides (same logic as ApplyBuffVisualState)
        if identifier and not IsEditModeActive() then
          local overrides = GetIconOverrides("buffs")
          if overrides and overrides[identifier] then
            local override = GetIconOverride("buffs", identifier)
            local stateKey = tempIsActive and "activeState" or "inactiveState"
            stateSettings = override[stateKey]
          end
        end
        
        if icon.Icon then
          local greyscaleInactive = GetSetting("buffs", "greyscaleInactive")
          if greyscaleInactive == nil then greyscaleInactive = true end
          local inactiveAlpha = GetSetting("buffs", "inactiveAlpha") or 0.5
          local iconOpacity = GetSetting("buffs", "iconOpacity") or 1.0
          
          if stateSettings and next(stateSettings) then
            -- Apply per-icon override settings
            local opacity = stateSettings.opacity
            if opacity == nil then
              if tempIsActive then
                opacity = iconOpacity
              else
                opacity = inactiveAlpha * iconOpacity
              end
            end
            icon:SetAlpha(opacity)
            
            local desaturate = stateSettings.desaturate
            if desaturate == nil then
              desaturate = (not tempIsActive) and greyscaleInactive
            end
            icon.Icon:SetDesaturated(desaturate)
          else
            -- No per-icon override, use global settings
            if tempIsActive then
              icon.Icon:SetDesaturated(false)
              icon:SetAlpha(iconOpacity)
            else
              icon.Icon:SetDesaturated(greyscaleInactive)
              icon:SetAlpha(inactiveAlpha * iconOpacity)
            end
          end
        end
      else
        -- We have spellID, use normal flow
        ApplyBuffVisualState(icon, isActive, forceUpdate)
      end
    end
  end
  
  -- Clear applying flag
  viewer._CMT_applying = nil
  
  -- Restore viewer position if it drifted (Blizzard may recalculate bounds based on children)
  if savedPoint and savedRelativeTo then
    local currentPoint, currentRelativeTo, currentRelativePoint, currentX, currentY = viewer:GetPoint(1)
    if currentX and savedX and (math.abs(currentX - savedX) > 1 or math.abs(currentY - savedY) > 1) then
      -- Position drifted - restore it
      posDebug("[buffs] DRIFT in UpdateAllBuffVisuals: was %.1f,%.1f should be %.1f,%.1f - RESTORING", 
        currentX, currentY, savedX, savedY)
      viewer:ClearAllPoints()
      viewer:SetPoint(savedPoint, savedRelativeTo, savedRelativePoint, savedX, savedY)
    end
  end
end

-- Start the buff update loop
local function StartBuffUpdateLoop()
  if buffUpdateFrame then
    buffUpdateFrame:SetScript("OnUpdate", nil)
  end
  
  buffUpdateFrame = CreateFrame("Frame")
  local elapsed = 0
  
  buffUpdateFrame:SetScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    
    if elapsed >= UPDATE_INTERVAL then
      elapsed = 0
      
      -- Only update if feature is enabled
      if GetSetting("buffs", "persistentDisplay") then
        UpdateAllBuffVisuals(false)
      end
    end
  end)
  
  dprint("CMT: Buff update loop started (interval: %.2fs)", UPDATE_INTERVAL)
end

-- Stop the buff update loop
local function StopBuffUpdateLoop()
  if buffUpdateFrame then
    buffUpdateFrame:SetScript("OnUpdate", nil)
  end
  
  -- Clear all visual states
  for icon in pairs(buffStates) do
    if icon and icon:IsShown() then
      if icon.Icon then
        icon.Icon:SetDesaturated(false)
      end
      icon:SetAlpha(1.0)
      if icon.Cooldown then
        icon.Cooldown:Show()
      end
    end
  end
  
  buffStates = {}
  dprint("CMT: Buff update loop stopped")
end

-- Clean up stale buff icon mappings (remove mappings for buffs no longer tracked)
local function CleanupBuffIconMappings()
  -- Get currently tracked buff spell IDs
  local trackedSpells = {}
  local viewer = _G["BuffIconCooldownViewer"]
  if viewer and viewer.systemInfo and viewer.systemInfo.spells then
    for _, spellID in ipairs(viewer.systemInfo.spells) do
      trackedSpells[spellID] = true
    end
  end
  
  -- Remove mappings for spells that are no longer tracked
  if CMT_CharDB.buffIconMappings then
    for texture, spellID in pairs(CMT_CharDB.buffIconMappings) do
      if not trackedSpells[spellID] then
        CMT_CharDB.buffIconMappings[texture] = nil
      end
    end
  end
end

-- Initialize or refresh the persistent buff display system
local function RefreshPersistentBuffDisplay()
  local enabled = GetSetting("buffs", "persistentDisplay")
  
  if enabled then
    -- Clean up stale mappings first
    CleanupBuffIconMappings()
    
    -- Start update loop if not running
    if not buffUpdateFrame or not buffUpdateFrame:GetScript("OnUpdate") then
      StartBuffUpdateLoop()
    end
    
    -- Force immediate update
    UpdateAllBuffVisuals(true)
    dprint("CMT: Persistent buff display enabled")
  else
    -- Stop update loop and restore normal appearance
    StopBuffUpdateLoop()
    dprint("CMT: Persistent buff display disabled")
  end
end

-- Hook into spec changes to refresh buff states
local specChangeFrame = CreateFrame("Frame")
specChangeFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
specChangeFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Leaving combat
specChangeFrame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Entering combat
specChangeFrame:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_SPECIALIZATION_CHANGED" then
    -- Wait a moment for buff changes to settle
    C_Timer.After(0.5, function()
      if GetSetting("buffs", "persistentDisplay") then
        -- Clear old state and force refresh
        buffStates = {}
        UpdateAllBuffVisuals(true)
        dprint("CMT: Refreshed buff display after spec change")
      end
    end)
  elseif event == "PLAYER_REGEN_DISABLED" then
    -- Entering combat - save current positions as "known good"
    -- Skip during settling period - positions may not be correct yet
    if not IsSettlingPeriod() then
      for _, t in ipairs(TRACKERS) do
        local v = _G[t.name]
        if v and v.GetPoint then
          local point, relativeTo, relativePoint, x, y = v:GetPoint(1)
          if point and x and y then
            v._CMT_knownGoodPosition = {
              point = point,
              relativeTo = relativeTo,
              relativePoint = relativePoint,
              x = x,
              y = y
            }
          end
        end
      end
    end
    
    -- CRITICAL: Cache spellIDs for all buff icons before we lose API access
    -- During combat on Midnight boss, C_UnitAuras may return secret values
    local buffViewer = _G["BuffIconCooldownViewer"]
    if buffViewer and buffViewer._CMT_baseOrder then
      for _, icon in ipairs(buffViewer._CMT_baseOrder) do
        if icon and not icon._CMT_cachedSpellID and icon.auraInstanceID then
          -- Try to look up and cache the spellID now
          local success, _ = pcall(function()
            for i = 1, 40 do
              local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
              if not auraData then break end
              if auraData.auraInstanceID == icon.auraInstanceID then
                icon._CMT_cachedSpellID = auraData.spellId
                break
              end
            end
          end)
        end
      end
      dprint("CMT: Cached buff spellIDs before entering combat")
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- Left combat - apply any pending visual changes
    if GetSetting("buffs", "persistentDisplay") then
      UpdateAllBuffVisuals(true)
    end
    
    -- Restore any drifted tracker positions after combat
    -- Skip during settling period
    if not IsSettlingPeriod() then
      C_Timer.After(0.1, function()
      for _, t in ipairs(TRACKERS) do
        local v = _G[t.name]
        if v and v._CMT_knownGoodPosition and not IsEditModeActive() then
          local pos = v._CMT_knownGoodPosition
          local currentPoint, currentRelativeTo, currentRelativePoint, currentX, currentY = v:GetPoint(1)
          if currentX and pos.x then
            if math.abs(currentX - pos.x) > 0.5 or math.abs(currentY - pos.y) > 0.5 then
              posDebug("[%s] DRIFT after combat: was %.1f,%.1f should be %.1f,%.1f - RESTORING", 
                t.key, currentX, currentY, pos.x, pos.y)
              v:ClearAllPoints()
              v:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.x, pos.y)
            end
          end
        end
      end
    end)
    end  -- end of IsSettlingPeriod check
  end
end)

-- Initialize persistent buff display on load
local function InitializePersistentBuffDisplay()
  -- Wait for player to be fully loaded
  C_Timer.After(2, function()
    RefreshPersistentBuffDisplay()
  end)
end

-- --------------------------------------------------------------------
-- Edit Mode Settings Helper
-- --------------------------------------------------------------------

-- Edit Mode setting enums
local SETTING_ORIENTATION = 0
local SETTING_ICON_DIRECTION = 1
local SETTING_NUM_COLUMNS = 2
local SETTING_ICON_SIZE = 3
local SETTING_ICON_PADDING = 4

local ORIENTATION_HORIZONTAL = 0
local ORIENTATION_VERTICAL = 1

-- Check if Edit Mode settings are optimal for CMT
local function CheckEditModeSettings()
  local issues = {}
  
  if not EditModeManagerFrame then
    return issues
  end
  
  -- registeredSystemFrames is an array of frames
  if EditModeManagerFrame.registeredSystemFrames then
    for i, frame in ipairs(EditModeManagerFrame.registeredSystemFrames) do
      if frame and frame.GetName and frame.GetSettingValue then
        local frameName = frame:GetName() or "unnamed"
        
        -- Look for our cooldown viewers
        local trackerName = nil
        if frameName == "EssentialCooldownViewer" then
          trackerName = "Essential Cooldowns"
        elseif frameName == "UtilityCooldownViewer" then
          trackerName = "Utility Cooldowns"
        elseif frameName == "BuffIconCooldownViewer" then
          trackerName = "Tracked Buffs"
        end
        
        if trackerName then
          local orientation = frame:GetSettingValue(SETTING_ORIENTATION)
          local numColumns = frame:GetSettingValue(SETTING_NUM_COLUMNS)
          
          -- Check orientation (should be horizontal = 1 for all)
          if orientation ~= ORIENTATION_HORIZONTAL then
            table.insert(issues, {
              frame = frame,
              tracker = trackerName,
              setting = "Orientation",
              settingEnum = SETTING_ORIENTATION,
              current = orientation == ORIENTATION_VERTICAL and "Vertical" or "Unknown",
              currentValue = orientation,
              needed = "Horizontal",
              neededValue = ORIENTATION_HORIZONTAL
            })
          end
          
          -- Check column count (should be 1 for Essential and Utility)
          -- Buffs doesn't matter as much but 1 is still optimal
          if numColumns and numColumns ~= 1 then
            table.insert(issues, {
              frame = frame,
              tracker = trackerName,
              setting = "Columns",
              settingEnum = SETTING_NUM_COLUMNS,
              current = tostring(numColumns),
              currentValue = numColumns,
              needed = "1",
              neededValue = 1
            })
          end
        end
      end
    end
  end
  
  return issues
end

-- Check if any frames are anchored to Essential Cooldowns
-- NOTE: We only flag frames anchored TO Essential Cooldowns (the problem)
-- We ignore Essential Cooldowns anchored TO other frames (the correct fix)
local function CheckForAnchoredFrames()
  local essentialViewer = _G["EssentialCooldownViewer"]
  if not essentialViewer then
    return {}
  end
  
  local anchoredFrames = {}
  
  -- Check all registered Edit Mode frames
  if EditModeManagerFrame and EditModeManagerFrame.registeredSystemFrames then
    for i, frame in ipairs(EditModeManagerFrame.registeredSystemFrames) do
      if frame and frame ~= essentialViewer and frame.GetNumPoints then
        local numPoints = frame:GetNumPoints()
        for pointIndex = 1, numPoints do
          local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(pointIndex)
          -- Only flag if THIS FRAME is anchored to Essential Cooldowns
          -- (not if Essential Cooldowns is anchored to this frame - that's the correct state)
          if relativeTo == essentialViewer then
            local frameName = frame:GetName() or "Unknown Frame"
            table.insert(anchoredFrames, {
              frame = frame,
              name = frameName,
              point = point,
              relativePoint = relativePoint,
              xOfs = xOfs,
              yOfs = yOfs,
              pointIndex = pointIndex
            })
          end
        end
      end
    end
  end
  
  return anchoredFrames
end

-- Fix anchored frames by opening Edit Mode with a helper window
local function FixAnchoredFrames()
  local anchoredFrames = CheckForAnchoredFrames()
  
  if #anchoredFrames == 0 then
    print("CMT: No frames are anchored to Essential Cooldowns")
    return false
  end
  
  local essentialViewer = _G["EssentialCooldownViewer"]
  if not essentialViewer then
    print("CMT: Essential Cooldowns frame not found")
    return false
  end
  
  -- Build list of frames for user guidance
  local frameNames = {}
  local framesList = {}
  for _, info in ipairs(anchoredFrames) do
    -- Make frame names more user-friendly
    local displayName = info.name
    if displayName == "PlayerFrame" then
      displayName = "Player Frame"
    elseif displayName == "TargetFrame" then
      displayName = "Target Frame"
    elseif displayName == "FocusFrame" then
      displayName = "Focus Frame"
    end
    table.insert(frameNames, displayName)
    table.insert(framesList, info)
  end
  
  print("|cffFFD700CMT: Opening Edit Mode with anchor fix helper...|r")
  print("|cffFFFF00Problem: " .. table.concat(frameNames, ", ") .. " anchored to Essential Cooldowns|r")
  
  -- Open Edit Mode first
  if EditModeManagerFrame and EditModeManagerFrame.Show then
    EditModeManagerFrame:Show()
  end
  
  -- Create helper window after a short delay (let Edit Mode open first)
  C_Timer.After(0.5, function()
    -- Create helper frame
    local helper = CreateFrame("Frame", "CMT_AnchorFixHelper", UIParent, "BasicFrameTemplateWithInset")
    helper:SetSize(480, 450)
    helper:SetPoint("CENTER", 0, 100)
    helper:SetFrameStrata("DIALOG")
    helper:SetFrameLevel(1000)
    helper:EnableMouse(true)
    helper:SetMovable(true)
    helper:RegisterForDrag("LeftButton")
    helper:SetScript("OnDragStart", helper.StartMoving)
    helper:SetScript("OnDragStop", helper.StopMovingOrSizing)
    
    helper.title = helper:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    helper.title:SetPoint("TOP", 0, -5)
    helper.title:SetText("Anchor Fix Instructions")
    
    -- Warning icon
    local icon = helper:CreateTexture(nil, "ARTWORK")
    icon:SetSize(48, 48)
    icon:SetPoint("TOP", 0, -35)
    icon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
    
    -- Problem description
    local problemText = helper:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    problemText:SetPoint("TOP", 0, -90)
    problemText:SetWidth(440)
    problemText:SetJustifyH("CENTER")
    problemText:SetTextColor(1, 0.3, 0.3)
    problemText:SetText("PROBLEM DETECTED:")
    
    -- Frame list
    local frameListText = helper:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frameListText:SetPoint("TOP", 0, -115)
    frameListText:SetWidth(440)
    frameListText:SetJustifyH("CENTER")
    frameListText:SetTextColor(1, 0.82, 0)
    frameListText:SetText(table.concat(frameNames, ", ") .. " is anchored to Essential Cooldowns")
    
    -- Explanation
    local explainText = helper:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    explainText:SetPoint("TOP", 0, -155)
    explainText:SetWidth(440)
    explainText:SetJustifyH("CENTER")
    explainText:SetTextColor(0.9, 0.9, 0.9)
    explainText:SetText("This causes icons to rearrange when the frame updates.")
    
    -- Instructions title
    local instructTitle = helper:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    instructTitle:SetPoint("TOP", 0, -185)
    instructTitle:SetWidth(440)
    instructTitle:SetJustifyH("CENTER")
    instructTitle:SetTextColor(0, 1, 0)
    instructTitle:SetText("Follow these steps to fix:")
    
    -- Instructions
    local instructionsText = helper:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructionsText:SetPoint("TOPLEFT", 20, -210)
    instructionsText:SetWidth(440)
    instructionsText:SetJustifyH("LEFT")
    instructionsText:SetSpacing(4)
    instructionsText:SetText(
      "|cffFFFFFF1.|r In Edit Mode, |cffFFD700uncheck 'Snap to Elements'|r\n" ..
      "\n" ..
      "|cffFFFFFF2.|r Click on |cffFFD700" .. table.concat(frameNames, ", ") .. "|r to select it\n" ..
      "\n" ..
      "|cffFFFFFF3.|r |cffFFD700Drag it slightly|r (even just a tiny bit)\n" ..
      "   This breaks the anchor to Essential Cooldowns\n" ..
      "\n" ..
      "|cffFFFFFF4.|r Optional: Move it back to where you want it\n" ..
      "\n" ..
      "|cffFFFFFF5.|r Now |cffFFD700drag Essential Cooldowns|r and position it\n" ..
      "   where you want (it's no longer linked)\n" ..
      "\n" ..
      "|cffFFFFFF6.|r Click |cff00FF00'Save'|r in Edit Mode - Done!"
    )
    
    -- Important note
    local noteText = helper:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noteText:SetPoint("BOTTOM", 0, 50)
    noteText:SetWidth(440)
    noteText:SetJustifyH("CENTER")
    noteText:SetTextColor(1, 0.82, 0)
    noteText:SetText("|cffFF6B6BIMPORTANT:|r Do NOT use 'Snap to Elements' when fixing this issue!")
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, helper, "UIPanelButtonTemplate")
    closeBtn:SetSize(120, 25)
    closeBtn:SetPoint("BOTTOM", 0, 15)
    closeBtn:SetText("Got It!")
    closeBtn:SetScript("OnClick", function()
      helper:Hide()
    end)
    
    helper.CloseButton:SetScript("OnClick", function()
      helper:Hide()
    end)
    
    -- Auto-hide when Edit Mode closes
    local checkEditMode
    checkEditMode = function()
      if not EditModeManagerFrame or not EditModeManagerFrame:IsShown() then
        if helper and helper:IsShown() then
          helper:Hide()
        end
      else
        C_Timer.After(0.5, checkEditMode)
      end
    end
    C_Timer.After(0.5, checkEditMode)
    
    helper:Show()
  end)
  
  return true
end

-- Apply optimal Edit Mode settings
local function ApplyOptimalEditModeSettings()
  local changes = {}
  
  if not EditModeManagerFrame then
    print("CMT: EditModeManagerFrame not found")
    return changes
  end
  
  if EditModeManagerFrame.registeredSystemFrames then
    for i, frame in ipairs(EditModeManagerFrame.registeredSystemFrames) do
      if frame and frame.GetName then
        local frameName = frame:GetName() or "unnamed"
        
        local trackerName = nil
        if frameName == "EssentialCooldownViewer" then
          trackerName = "Essential Cooldowns"
        elseif frameName == "UtilityCooldownViewer" then
          trackerName = "Utility Cooldowns"
        elseif frameName == "BuffIconCooldownViewer" then
          trackerName = "Tracked Buffs"
        end
        
        if trackerName then
          local changed = false
          local orientation = frame:GetSettingValue(SETTING_ORIENTATION)
          local numColumns = frame:GetSettingValue(SETTING_NUM_COLUMNS)
          
          print(string.format("CMT: Checking %s - Orientation=%s, Columns=%s", 
            trackerName, tostring(orientation), tostring(numColumns)))
          
          -- Set orientation to horizontal
          if orientation ~= ORIENTATION_HORIZONTAL then
            print(string.format("  Changing orientation from %d to %d", orientation, ORIENTATION_HORIZONTAL))
            
            -- Try the specific method for orientation
            if frame.UpdateSystemSettingOrientation then
              print("  Using UpdateSystemSettingOrientation")
              frame:UpdateSystemSettingOrientation(ORIENTATION_HORIZONTAL)
            elseif frame.UpdateSystemSetting then
              print("  Using UpdateSystemSetting")
              frame:UpdateSystemSetting(SETTING_ORIENTATION, ORIENTATION_HORIZONTAL)
            end
            
            changed = true
            
            -- Verify it changed
            local newOrientation = frame:GetSettingValue(SETTING_ORIENTATION)
            print(string.format("  After update: orientation = %s", tostring(newOrientation)))
          end
          
          -- Set columns to 1 (num columns setting)
          if numColumns ~= 1 then
            print(string.format("  Changing columns from %d to 1", numColumns))
            
            -- There might be a specific method for this too
            if frame.UpdateSystemSetting then
              frame:UpdateSystemSetting(SETTING_NUM_COLUMNS, 1)
            end
            
            changed = true
            
            -- Verify it changed
            local newColumns = frame:GetSettingValue(SETTING_NUM_COLUMNS)
            print(string.format("  After update: columns = %s", tostring(newColumns)))
          end
          
          if changed then
            table.insert(changes, trackerName)
          end
        end
      end
    end
  end
  
  print(string.format("CMT: Attempted changes to: %s", #changes > 0 and table.concat(changes, ", ") or "none"))
  return changes
end

-- Show Edit Mode setup dialog
local function ShowEditModeSetupDialog()
  -- First check for anchored frames - this is more critical than Edit Mode settings
  local anchoredFrames = CheckForAnchoredFrames()
  
  if #anchoredFrames > 0 and not CMT_DB.anchorWarningDismissed then
    -- Build list of anchored frames
    local frameList = "\n\n"
    for _, info in ipairs(anchoredFrames) do
      frameList = frameList .. "• " .. info.name .. "\n"
    end
    
    -- Show anchor warning dialog
    StaticPopupDialogs["CMT_ANCHOR_WARNING"] = {
      text = "⚠️ Frame Anchor Issue Detected\n\nThe following frames are anchored to Essential Cooldowns:" .. frameList .. "\nThis causes icons to rearrange unexpectedly when these frames update.\n\nClick 'Fix It' to open Edit Mode with step-by-step instructions to reverse the anchor relationship.",
      button1 = "Fix It",
      button2 = "Remind Me Later",
      button3 = "Ignore Forever",
      OnAccept = function()
        FixAnchoredFrames()
      end,
      OnCancel = function()
        -- User declined but will see it again next time
      end,
      OnAlt = function()
        -- Ignore Forever - set the flag permanently
        CMT_DB.anchorWarningDismissed = true
        print("CMT: Anchor warnings disabled. Use '/cmt resetanchorwarning' to re-enable")
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    
    StaticPopup_Show("CMT_ANCHOR_WARNING")
    return -- Don't show Edit Mode dialog if we're showing anchor warning
  end
  
  -- Then check Edit Mode settings
  local issues = CheckEditModeSettings()
  
  -- Only show if there are actual issues
  if #issues == 0 then
    return
  end
  
  -- If user explicitly chose "Ignore Forever", respect that
  if CMT_DB.editModeSetupDismissed then
    return
  end
  
  -- Build the issue list for display
  local issueText = "\n\nRequired changes:\n"
  for _, issue in ipairs(issues) do
    issueText = issueText .. string.format("• %s: Set %s to %s\n", 
      issue.tracker, issue.setting, issue.needed)
  end
  
  -- Create dialog with manual instructions
  StaticPopupDialogs["CMT_EDITMODE_SETUP"] = {
    text = "⚠️ Cooldown Manager Tweaks Setup\n\nCMT works best with specific Edit Mode settings.\n\nBlizzard prevents addons from changing these automatically.\nPlease configure them manually:" .. issueText .. "\nSteps:\n1. Press ESC → Edit Mode\n2. Click each tracker listed above\n3. Change the settings as shown\n4. Click 'Save' in Edit Mode",
    button1 = "Open Edit Mode",
    button2 = "Remind Me Later", 
    button3 = "Ignore Forever",
    OnAccept = function()
      -- Open Edit Mode for them
      if EditModeManagerFrame and EditModeManagerFrame.Show then
        EditModeManagerFrame:Show()
      end
      -- Don't set dismissed flag - will check again next login
    end,
    OnCancel = function()
      -- User declined but will see it again next time - don't set dismissed flag
    end,
    OnAlt = function()
      -- Ignore Forever - set the flag permanently
      CMT_DB.editModeSetupDismissed = true
      print("CMT: Edit Mode warnings disabled. Use '/cmt resetwarning' to re-enable or check manually from Settings tab")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }
  
  StaticPopup_Show("CMT_EDITMODE_SETUP")
end

-- Manual setup assistant (for Settings button) - Shows a panel instead of popup
local function ShowEditModeSetupAssistant()
  local issues = CheckEditModeSettings()
  
  if #issues == 0 then
    -- Create success panel
    local frame = CreateFrame("Frame", "CMT_EditModeCheckFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(450, 200)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", 0, -5)
    frame.title:SetText("Edit Mode Settings Check")
    
    -- Success icon (green checkmark)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(48, 48)
    icon:SetPoint("TOP", 0, -40)
    icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    
    local successText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    successText:SetPoint("TOP", 0, -100)
    successText:SetTextColor(0, 1, 0)
    successText:SetText("All Settings Optimal!")
    
    local infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoText:SetPoint("TOP", 0, -130)
    infoText:SetWidth(400)
    infoText:SetJustifyH("CENTER")
    infoText:SetText("Your Edit Mode settings are configured correctly for CMT.")
    
    local okBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    okBtn:SetSize(80, 22)
    okBtn:SetPoint("BOTTOM", 0, 10)
    okBtn:SetText("OK")
    okBtn:SetScript("OnClick", function() frame:Hide() end)
    
    frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)
    
    frame:Show()
    return
  end
  
  -- Create issues panel
  local frame = CreateFrame("Frame", "CMT_EditModeCheckFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(500, 400)
  frame:SetPoint("CENTER")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetFrameStrata("DIALOG")
  
  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.title:SetPoint("TOP", 0, -5)
  frame.title:SetText("Edit Mode Settings Check")
  
  -- Warning icon
  local icon = frame:CreateTexture(nil, "ARTWORK")
  icon:SetSize(48, 48)
  icon:SetPoint("TOP", 0, -35)
  icon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
  
  local headerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  headerText:SetPoint("TOP", 0, -90)
  headerText:SetTextColor(1, 0.82, 0)
  headerText:SetText("Settings Need Adjustment")
  
  local infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  infoText:SetPoint("TOP", 0, -120)
  infoText:SetWidth(460)
  infoText:SetJustifyH("LEFT")
  infoText:SetText("CMT works best with specific Edit Mode settings.\nThe following need to be changed:")
  
  -- Build issue list
  local issueList = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  issueList:SetPoint("TOPLEFT", 30, -170)
  issueList:SetWidth(440)
  issueList:SetJustifyH("LEFT")
  local issueText = ""
  for _, issue in ipairs(issues) do
    issueText = issueText .. string.format("• %s: Set %s to %s (currently %s)\n", 
      issue.tracker, issue.setting, issue.needed, issue.current)
  end
  issueList:SetText(issueText)
  
  -- Instructions
  local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  instructions:SetPoint("TOPLEFT", 30, -240)
  instructions:SetWidth(440)
  instructions:SetJustifyH("LEFT")
  instructions:SetTextColor(0.8, 0.8, 0.8)
  instructions:SetText("How to fix:\n1. Press ESC → Edit Mode\n2. Click each tracker listed above\n3. Adjust settings as shown\n4. Click 'Save' in Edit Mode")
  
  -- Open Edit Mode button
  local editModeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  editModeBtn:SetSize(120, 22)
  editModeBtn:SetPoint("BOTTOM", -60, 10)
  editModeBtn:SetText("Open Edit Mode")
  editModeBtn:SetScript("OnClick", function()
    if EditModeManagerFrame and EditModeManagerFrame.Show then
      EditModeManagerFrame:Show()
    end
    frame:Hide()
  end)
  
  local okBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  okBtn:SetSize(80, 22)
  okBtn:SetPoint("BOTTOM", 60, 10)
  okBtn:SetText("OK")
  okBtn:SetScript("OnClick", function() frame:Hide() end)
  
  frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)
  
  frame:Show()
end

-- --------------------------------------------------------------------
-- Patch Notes Dialog
-- --------------------------------------------------------------------
local function ShowPatchNotesDialog(forceShow)
  -- Check if we should skip showing (only on auto-show, not manual)
  -- forceShow=true means button or slash command clicked, always show
  if not forceShow and CMT_DB.lastSeenVersion == VERSION then
    return
  end
  
  local frame = CreateFrame("Frame", "CMTPatchNotesFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(550, 600)  -- Taller to show more patch notes
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  
  -- Allow ESC to close
  tinsert(UISpecialFrames, "CMTPatchNotesFrame")
  
  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.title:SetPoint("TOP", 0, -5)
  frame.title:SetText("Cooldown Manager Tweaks - Patch Notes")
  
  -- Current version header
  local versionText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  versionText:SetPoint("TOP", 0, -30)
  versionText:SetText("|cff00ff00Current Version: " .. VERSION .. "|r")
  
  -- Scroll frame for patch notes
  local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 10, -55)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 60)  -- Leave room for scroll hint and buttons
  
  -- Enable mouse wheel scrolling
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local step = 60
    if delta > 0 then
      self:SetVerticalScroll(math.max(0, current - step))
    else
      self:SetVerticalScroll(math.min(maxScroll, current + step))
    end
  end)
  
  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetSize(490, 300)
  scrollFrame:SetScrollChild(scrollChild)
  
  -- Patch notes content
  local content = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  content:SetPoint("TOPLEFT", 5, -5)
  content:SetWidth(480)
  content:SetJustifyH("LEFT")
  content:SetSpacing(3)
  
  -- Define patch notes for all versions (newest first in the ordered list)
  local patchNotes = {
    ["4.6.2"] = {
      title = "NEW: Count Text Size & Panel Reset Command",
      notes = [[
|cffFFD700Count Text Size Slider (NEW!):|r

Adjust the size of stack/count numbers on your tracker icons!

|cff00FF00Features:|r
• |cffffffffNew slider|r in each tracker's settings panel (Essential, Utility, Buffs)
• |cffffffffRange|r from 50% to 200% of the default size
• |cffffffffWorks with stackable buffs|r - shows on buffs that have stack counts
• |cffffffffItems tracker|r continues to use its existing "Item Count Font Size" pixel-based slider

|cffFFD700Panel Reset Command (NEW!):|r

Lost your CMT settings panel off-screen? Now you can get it back!

|cff00FF00Usage:|r
• Type |cff87CEEB/cmtpanel reset|r to relocate the control panel to the center of your screen
• The panel will appear immediately if it was hidden
• Your saved position will be cleared so the panel opens centered next time

|cff87CEEBTip:|r This is useful if you accidentally dragged the panel off-screen or changed monitor resolutions.


Type /cmt to access the new Count Text Size slider!
]]
    },
    ["4.6.0"] = {
      title = "NEW: Masque Skin Support",
      notes = [[
|cffFFD700Masque Integration (NEW!):|r

Apply beautiful custom skins to your cooldown icons! CMT now integrates with Masque (ButtonFacade successor) to let you completely customize the appearance of your tracker icons.

|cff00FF00Features:|r
• |cffFFFFFFull Masque Support|r - Apply any Masque skin to your cooldown trackers
• |cffffffffGlobal Toggle|r - Enable/disable Masque skinning in General Settings
• |cffffffffPer-Tracker Control|r - Enable Masque for specific trackers while keeping others with default appearance
• |cffffffffAutomatic Aspect Ratio|r - Icons automatically switch to square (1:1) when Masque is enabled
• |cffffffffSettings Preservation|r - Your aspect ratio and zoom settings are saved when enabling Masque and restored when disabling

|cff87CEEBHow to Use:|r
1. Install the Masque addon and your preferred skin pack
2. Enable "Masque Skin Support" in CMT's General Settings
3. Use /msq to open Masque's configuration and select skins for CMT trackers
4. Optionally disable Masque for specific trackers in their individual settings panels

|cff87CEEBNote:|r
Masque controls icon appearance (textures, borders, overlays) while CMT continues to handle size, opacity, spacing, and layout. Different Masque skins have varying border sizes which may affect spacing.


Type /cmt to access General Settings and enable Masque support!
]]
    },
    ["4.5.1"] = {
      title = "NEW: Hub-Based UI & Icon Opacity Control",
      notes = [[
|cffFFD700New Hub-Based Settings UI:|r

The settings panel has been completely redesigned with a modern hub layout!

|cff00FF00What's New:|r
• |cffFFFFFFHub Panel|r - A compact menu on the left with buttons for each section
• |cffFFFFFFDocked Panels|r - Click a button to open that section's panel to the right
• |cffFFFFFFDraggable|r - Move the hub anywhere and it remembers its position
• |cffFFFFFFPer-Icon Settings|r - Click the button at the bottom of any tracker panel to open the preview and per-icon controls

|cff87CEEBNavigation:|r
• Trackers: Essential, Utility, Buffs, Custom - each with full layout and visibility controls
• Configuration: Items & Spells, Profiles, General Settings
• Closing a panel is easy - just click another button or the X

|cffFFD700Icon Opacity Slider (NEW!):|r

Control the base transparency of all icons in a tracker!

|cff00FF00Features:|r
• |cffFFFFFFNew slider|r between Icon Size and Icon Texture Zoom
• |cffFFFFFFRange|r from 10% to 100% opacity
• |cffFFFFFFPer-icon override|r - Per-icon settings can still override the base opacity
• |cffFFFFFFSmart buff handling|r - For inactive buffs, the Inactive Alpha setting multiplies with Icon Opacity (50% inactive × 50% opacity = 25% final)

|cff87CEEBUse Cases:|r
• Make a tracker more subtle when not actively needed
• Reduce visual clutter while keeping cooldowns visible
• Combine with visibility controls for maximum flexibility


Type /cmt to try the new hub UI!
]]
    },
    ["4.4.0"] = {
      title = "NEW: Visibility Controls - Show/Hide Trackers Conditionally",
      notes = [[
|cffFFD700Visibility Controls (NEW!):|r

Finally! Control when your trackers appear on screen based on game conditions. Hide trackers until you need them - perfect for a cleaner UI!

|cff00FF00Show Trackers When:|r
• |cffFFFFFFIn Combat|r - Show only during combat encounters
• |cffFFFFFFMouse Over|r - Show when hovering over the tracker area
• |cffFFFFFFHave a Target|r - Show when you have an enemy/friendly targeted
• |cffFFFFFFIn Party/Raid|r - Show when grouped with other players
• |cffFFFFFFIn Instances|r - Show in dungeons, raids, arenas, battlegrounds, scenarios

|cff87CEEBHow It Works:|r
• Tracker is hidden by default when visibility controls are enabled
• Tracker appears when ANY checked condition is met (OR logic)
• Combine conditions - e.g., show when in combat OR have a target
• Set "Hidden Opacity" to make trackers semi-transparent instead of invisible
• Smooth fade animations for a polished feel

|cff87CEEBPer-Tracker Settings:|r
Each tracker (Essential, Utility, Buffs, Custom) has its own visibility settings. Configure them independently in each tracker's tab!

|cffFFD700Additional Improvements:|r

|cff00FF00Edit Mode Tweaks Compatibility:|r
If EMT is also managing a frame's visibility, CMT will detect this and offer an override option.

|cff00FF00ESC to Close:|r
The settings panel now closes when you press Escape.

|cff00FF00Expanded Settings Panel:|r
Scroll area now uses the full panel height for easier navigation.


Type /cmt to open settings and find Visibility Settings in each tracker tab!
]]
    },
    ["4.3.0"] = {
      title = "NEW: Per-Icon Customization Settings",
      notes = [[
|cffFFD700Per-Icon Settings (NEW!):|r

Customize individual icons in the Live Preview! Each cooldown icon can now have its own unique settings.

|cff00FF00Per-Icon Options:|r
• |cffFFFFFFVisibility|r - Hide specific icons you don't want to see
• |cffFFFFFFSize Override|r - Make important cooldowns larger or smaller
• |cffFFFFFFZoom Override|r - Adjust texture zoom per icon
• |cffFFFFFFAspect Ratio Override|r - Custom aspect ratio per icon
• |cffFFFFFFBorder Color|r - Color-code icons for quick recognition

|cff87CEEBHow to Use:|r
1. Open /cmt and go to any tracker tab
2. Click on an icon in the Live Preview panel (right side)
3. Adjust settings in the "Selected Icon Settings" section below the preview
4. Changes apply instantly!

|cffFFD700Perfect For:|r
• Hiding cooldowns you don't need to track
• Making important abilities stand out with larger size
• Color-coding by ability type (interrupts, defensives, etc.)
• Fine-tuning your UI for optimal gameplay
]]
    },
    ["4.2.0"] = {
      title = "NEW: Live Preview Panel",
      notes = [[
|cffFFD700Live Preview Panel (NEW!):|r

See your layout changes in real-time! The settings panel now includes an integrated preview that updates instantly as you adjust settings.

|cff00FF00Features:|r
• |cffFFFFFFReal-time updates|r - See changes instantly as you move sliders
• |cffFFFFFFIntegrated design|r - Preview panel built into the right side of settings
• |cffFFFFFFAccurate representation|r - Shows actual icon sizes, spacing, and layout
• |cffFFFFFFNo more guessing|r - Perfect your layout without constant /reload

|cff87CEEBHow to Use:|r
1. Open /cmt settings
2. Go to any tracker tab (Essential, Utility, Buffs, Custom Layout)
3. The Live Preview appears on the right side
4. Adjust any setting and watch the preview update instantly!

|cffFFD700Settings That Update Live:|r
• Icon size and aspect ratio
• Grid layout (rows/columns)
• Spacing (horizontal and vertical)
• Compact mode toggle
• Icon texture zoom
• And more!

No more reloading to see your changes - what you see is what you get!
]]
    },
    ["4.1.0"] = {
      title = "MAJOR UPDATE: Items Tracker & Persistent Buff Display",
      notes = [[
|cffFFD700Items & Spell Tracker (NEW!):|r

Finally! Track your potions, trinkets, food, racials and any item with a cooldown alongside your abilities!

|cff00FF00Features:|r
• Per-character, per-spec item and spell lists - different items for each spec
• Full layout controls - icon size, grid patterns, spacing, aspect ratios
• Drag & drop management - add items from bags, reorder with drag & drop
• Edit Mode integration - move via Edit Mode (Esc > Edit Mode)
• Instant cooldown tracking - updates in real-time
• Position persistence - remembers location across reloads

|cff87CEEBHow to Use:|r
1. Type /cmt and go to "Items & Spells" tab (second row, left side)
2. Drag items from your bags or spells from your spellbook into the drop zone
3. Icons appear in the tracker - right-click to remove
4. Go to "Custom Layout" tab to customize appearance
5. Move via Edit Mode or load a different profile

|cffFF6B6BNote:|r Custom tracker has no borders by design - clean, minimal appearance.


|cffFFD700Persistent Buff Display (v3.2.0):|r

Complete rebuild of buff tracking! Now shows ALL tracked buffs at all times with clear active/inactive visual distinction.

|cff00FF00How It Works:|r
• Active buffs: Full color, bright, with cooldown sweep
• Inactive buffs: Grayscale + faded (adjustable transparency)
• Works perfectly in combat using combat-safe detection
• Zero "secret value" errors - fully compatible with Midnight expansion
• Updates 5x per second for instant visual feedback

|cff87CEEBSetup:|r
1. /cmt → Buffs tab
2. Enable "Persistent Buff Display"
3. Set inactive transparency (default 40%)
4. Set Edit Mode to "Always Show" for buffs
5. System automatically learns buff mappings - works instantly in combat!


Type /cmt help for all commands!
]]
    },
    ["3.0.6"] = {
      title = "Major Update: Per-Character Profiles + Quality of Life Features",
      notes = [[
|cffFFD700Profile System Update (v3.0.6):|r
Profile selection is now saved per-character instead of account-wide!

|cffFF6B6BWhat This Means:|r
Each character now remembers its own profile selection independently. Previously, changing profiles on one character would affect all your other characters.

|cff00FF00Action Required:|r
• Log in to each character and re-select your preferred profile
• Re-configure spec-to-profile assignments for each character
• This is a one-time setup per character

|cff87CEEBBenefit:|r Each character can now have different spec-to-profile assignments! Your Tank Warrior can use "Tank Profile" while your DPS Warrior uses "DPS Profile" - even for the same spec.

|cff87CEEBNote:|r Your profile data is safe and unchanged - you just need to tell each character which profile to use.


|cffFFD700New Features (v3.0.6):|r

|cff00FF00Health Monitoring System:|r
CMT now continuously monitors all trackers for issues and automatically fixes them. A new Health Log is available in Settings → General Settings to view diagnostic information for troubleshooting.

|cff00FF00Anchor Fix Assistant:|r
CMT now detects when frames (like Player Frame) are anchored to Essential Cooldowns - which causes icons to rearrange unexpectedly. When detected, a dialog appears with a "Fix It" button that opens Edit Mode with clear step-by-step instructions to reverse the anchor relationship.

This warning appears both on login and when leaving Edit Mode, making it easy to catch and fix anchor problems immediately.
]]
    },
    ["3.0.4"] = {
      title = "Profile Selection Now Per-Character!",
      notes = [[
|cffFFD700Important Change:|r Profile selection is now saved per-character instead of account-wide.

|cffFF6B6BWhat This Means:|r
Each character now remembers its own profile selection independently. Previously, changing profiles on one character would affect all your other characters.

|cff00FF00What You Need To Do:|r
• Log in to each character and re-select your preferred profile
• Re-configure spec-to-profile assignments for each character
• This is a one-time setup per character

|cff87CEEBNew Feature:|r
Each character can now have different spec-to-profile assignments! For example:
• Your Tank Warrior can assign "Tank Profile" to Protection spec
• Your DPS Warrior (different character) can assign "DPS Profile" to Fury spec

Your profile data is safe and unchanged - you just need to tell each character which profile to use.
]]
    }
  }
  
  -- Ordered list of versions (newest first)
  local versionOrder = { "4.6.2", "4.6.0", "4.5.1", "4.4.0", "4.3.0", "4.2.0", "4.1.0", "3.0.6", "3.0.4" }
  
  -- Build combined patch notes text with all versions
  local allNotesText = ""
  for i, ver in ipairs(versionOrder) do
    local notes = patchNotes[ver]
    if notes then
      -- Add separator between versions (except first)
      if i > 1 then
        allNotesText = allNotesText .. "\n\n|cff555555" .. string.rep("─", 55) .. "|r\n\n"
      end
      
      -- Version header with color based on whether it's current
      if ver == VERSION then
        allNotesText = allNotesText .. "|cff00ff00---------- Version " .. ver .. " (NEW!) ----------|r\n\n"
      else
        allNotesText = allNotesText .. "|cff888888---------- Version " .. ver .. " ----------|r\n\n"
      end
      
      -- Title and notes
      allNotesText = allNotesText .. "|cffFFFFFF" .. notes.title .. "|r\n\n" .. notes.notes
    end
  end
  
  content:SetText(allNotesText)
  
  -- Adjust scroll child height based on content
  local textHeight = content:GetStringHeight()
  scrollChild:SetHeight(math.max(500, textHeight + 40))
  
  -- Scroll hint at bottom of frame
  local scrollHint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  scrollHint:SetPoint("BOTTOM", 0, 42)
  scrollHint:SetText("|cff888888Scroll down to see older patch notes|r")
  
  -- Buttons
  local okBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  okBtn:SetSize(120, 25)
  okBtn:SetPoint("BOTTOM", -65, 12)
  okBtn:SetText("Got It!")
  okBtn:SetScript("OnClick", function()
    CMT_DB.lastSeenVersion = VERSION
    frame:Hide()
    print("|cff00ff00CMT: Thank you! You won't see this message again for this version.|r")
  end)
  
  local laterBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  laterBtn:SetSize(120, 25)
  laterBtn:SetPoint("BOTTOM", 65, 12)
  laterBtn:SetText("Remind Me Later")
  laterBtn:SetScript("OnClick", function()
    frame:Hide()
    print("|cffFFFF00CMT: Patch notes will show again on next login. Type /cmt to access settings.|r")
  end)
  
  frame.CloseButton:SetScript("OnClick", function()
    frame:Hide()
  end)
  
  frame:Show()
end

local function bootstrap()
  ensureDefaults()
  
  -- Auto-enable persistent display for all existing profiles (v4.3.0+)
  -- This ensures users upgrading from older versions get the feature enabled
  -- Only do this once per profile (tracked by _persistentDisplayMigrated flag)
  for profileName, profile in pairs(CMT_DB.profiles) do
    -- Ensure buffs table exists
    profile.buffs = profile.buffs or {}
    
    -- Only migrate if we haven't done so before AND it's currently nil
    if not profile.buffs._persistentDisplayMigrated and profile.buffs.persistentDisplay == nil then
      profile.buffs.persistentDisplay = true
      profile.buffs._persistentDisplayMigrated = true
      print("CMT: Enabled persistent buff display for profile '" .. profileName .. "'")
    elseif not profile.buffs._persistentDisplayMigrated then
      -- Already has a value (true or false), just mark as migrated so we don't touch it again
      profile.buffs._persistentDisplayMigrated = true
    end
  end
  
  for _,t in ipairs(TRACKERS) do
    local v=_G[t.name]
    if v then hookViewer(v, t.key) end
  end
  
  -- Hook Edit Mode to check for anchor issues when it closes
  if EditModeManagerFrame and not EditModeManagerFrame._CMT_Hooked then
    EditModeManagerFrame._CMT_Hooked = true
    
    -- Hook the Hide function to detect when Edit Mode closes
    hooksecurefunc(EditModeManagerFrame, "Hide", function()
      -- Check for anchor issues when Edit Mode closes
      C_Timer.After(0.5, function()
        local anchoredFrames = CheckForAnchoredFrames()
        if #anchoredFrames > 0 and not CMT_DB.anchorWarningDismissed then
          -- Build list of anchored frames
          local frameList = "\n\n"
          for _, info in ipairs(anchoredFrames) do
            frameList = frameList .. "• " .. info.name .. "\n"
          end
          
          -- Show anchor warning dialog
          StaticPopupDialogs["CMT_ANCHOR_WARNING"] = {
            text = "⚠️ Frame Anchor Issue Detected\n\nThe following frames are anchored to Essential Cooldowns:" .. frameList .. "\nThis causes icons to rearrange unexpectedly when these frames update.\n\nClick 'Fix It' to open Edit Mode with step-by-step instructions to reverse the anchor relationship.",
            button1 = "Fix It",
            button2 = "Remind Me Later",
            button3 = "Ignore Forever",
            OnAccept = function()
              FixAnchoredFrames()
            end,
            OnCancel = function()
              -- User declined but will see it again next time
            end,
            OnAlt = function()
              -- Ignore Forever - set the flag permanently
              CMT_DB.anchorWarningDismissed = true
              print("CMT: Anchor warnings disabled. Use '/cmt resetanchorwarning' to re-enable")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
          }
          
          StaticPopup_Show("CMT_ANCHOR_WARNING")
        end
      end)
    end)
  end
  
  -- Create Items tracker frame (v3.1.0)
  CreateItemsTrackerFrame()
  
  -- Load custom items with multiple retries (wait for item cache)
  -- Attempt 1: Quick load (0.5s)
  C_Timer.After(0.5, function()
    LoadCustomItems()
  end)
  
  -- Attempt 2: Standard retry (2s) for items that weren't cached
  C_Timer.After(2.5, function()
    LoadCustomItems()
  end)
  
  -- Attempt 3: Final retry (5s) for stubborn items
  C_Timer.After(5, function()
    LoadCustomItems()
  end)
end

local ev_loaded = CreateFrame("Frame")
ev_loaded:RegisterEvent("ADDON_LOADED")
ev_loaded:SetScript("OnEvent", function(_, addon)
  if addon == ADDON_NAME then
    ensureDefaults()
    -- Initialize visibility system (v4.4.0)
    VisibilityManager:Initialize()
  end
end)

local ev_login = CreateFrame("Frame")
ev_login:RegisterEvent("PLAYER_LOGIN")
ev_login:SetScript("OnEvent", function() 
  bootstrap()
  
  -- Initialize Masque support if enabled and available (v4.6.0)
  C_Timer.After(1, function()
    if CMT_DB.masqueEnabled and MasqueModule and MasqueModule.Init then
      if MasqueModule.Init() then
        -- Register existing icons after a delay to let trackers populate
        C_Timer.After(2, function()
          for _, t in ipairs(TRACKERS) do
            if t.key == "items" then
              MasqueModule.RegisterCustomTracker()
            else
              MasqueModule.RegisterTracker(t.key)
            end
          end
        end)
      end
    end
  end)
  
  -- Check for new version and show patch notes
  C_Timer.After(2, function()
    if CMT_DB.lastSeenVersion ~= VERSION then
      ShowPatchNotesDialog()
    end
  end)
  
  -- Check Edit Mode settings after a delay (let UI settle)
  C_Timer.After(3, function()
    ShowEditModeSetupDialog()
  end)
  
  -- Show welcome message
  C_Timer.After(2.5, function()
    print("|cff00ff00Cooldown Manager Tweaks Loaded: Cooldown Manager Tweaks is in active development by one person, if you have any issues or feedback please send a private message to the author on Curseforge. If you like CMT you might also want to check out our other addon Edit Mode Tweaks.|r")
  end)
end)

-- Force initial layout after entering world
local ev_world = CreateFrame("Frame")
ev_world:RegisterEvent("PLAYER_ENTERING_WORLD")
ev_world:SetScript("OnEvent", function(self, event, isInitialLogin, isReloadingUi)
  if isInitialLogin or isReloadingUi then
    -- Set position settling period - don't restore positions until frames have settled
    _positionSettlingUntil = GetTime() + POSITION_SETTLING_PERIOD
    dprint("CMT: Position settling period active for %d seconds", POSITION_SETTLING_PERIOD)
    
    -- Apply existing saved layouts after reload
    C_Timer.After(1.5, function()
      for _,t in ipairs(TRACKERS) do
        local v=_G[t.name]
        if v then
          -- If we don't have a baseOrder yet, try to capture it
          if not v._CMT_baseOrder or #v._CMT_baseOrder == 0 then
            dprint("CMT: No baseOrder on reload for [%s], attempting capture", t.key)
            forceRecaptureOrder(t.key)
            -- Wait a bit for capture to complete
            C_Timer.After(0.5, function()
              if v._CMT_baseOrder and #v._CMT_baseOrder > 0 then
                local layoutFunc = t.isBarType and layoutBars or layoutCustomGrid
                layoutFunc(v, t.key, v._CMT_baseOrder)
                dprint("CMT: Applied layout for [%s] after capture (%d icons)", t.key, #v._CMT_baseOrder)
              end
            end)
          elseif #v._CMT_baseOrder > 0 then
            -- We have baseOrder, apply layout
            local layoutFunc = t.isBarType and layoutBars or layoutCustomGrid
            layoutFunc(v, t.key, v._CMT_baseOrder)
            dprint("CMT: Applied layout for [%s] with existing baseOrder (%d icons)", t.key, #v._CMT_baseOrder)
            
            -- After our layout, trigger Blizzard's Layout to fix viewer position
            -- This mimics opening/closing Edit Mode
            C_Timer.After(0.3, function()
              if v and v.Layout then
                -- Temporarily flag so our hook doesn't interfere
                v._CMT_skipNextLayout = true
                v:Layout()
                dprint("CMT: Triggered Layout for [%s] to fix position", t.key)
              end
            end)
          end
        end
      end
    end)
  end
  
  -- Initialize persistent buff display system
  if isInitialLogin or isReloadingUi then
    InitializePersistentBuffDisplay()
    
    -- Delayed "final" position capture - frames may not be settled for several seconds
    -- This overwrites any wrong positions captured during initial load
    C_Timer.After(10, function()
      for _, t in ipairs(TRACKERS) do
        local v = _G[t.name]
        if v and v:IsShown() then
          local point, relativeTo, relativePoint, x, y = v:GetPoint(1)
          local cx, cy = v:GetCenter()
          if point and x and y then
            v._CMT_knownGoodPosition = {
              point = point,
              relativeTo = relativeTo,
              relativePoint = relativePoint,
              x = x,
              y = y
            }
            v._CMT_positionSettled = true
            dprint("CMT: Captured settled position for [%s]: offset %.1f,%.1f screen %.1f,%.1f", 
              t.key, x, y, cx or 0, cy or 0)
          end
        end
      end
    end)
    
    -- Hook EditModeManagerFrame to handle nudges during Edit Mode
    -- Nudges must be removed BEFORE Edit Mode calculates frame bounds
    -- We need a pre-hook, so we wrap the Show function
    C_Timer.After(0.5, function()
      if EditModeManagerFrame and not EditModeManagerFrame._CMT_hooked then
        -- Store original Show function
        local originalShow = EditModeManagerFrame.Show
        
        -- Replace with our version that resets positions first
        EditModeManagerFrame.Show = function(self, ...)
          -- Set flag to force Edit Mode behavior during this transition
          -- This ensures layouts don't apply padding expansion
          _forceEditModeBehavior = true
          
          -- Reset all tracker icons to base positions BEFORE Edit Mode initializes
          for _, t in ipairs(TRACKERS) do
            local v = _G[t.name]
            if v and v._CMT_baseOrder and #v._CMT_baseOrder > 0 then
              local layoutFunc = t.isBarType and layoutBars or layoutCustomGrid
              layoutFunc(v, t.key, v._CMT_baseOrder)
            end
          end
          
          -- Clear the force flag now that layouts are done
          _forceEditModeBehavior = false
          
          -- Save positions AFTER resetting layouts - this is the "clean" position
          -- without per-icon overrides affecting bounds
          for _, t in ipairs(TRACKERS) do
            local v = _G[t.name]
            if v and v.GetPoint then
              local point, relativeTo, relativePoint, x, y = v:GetPoint(1)
              if point and x and y then
                v._CMT_knownGoodPosition = {
                  point = point,
                  relativeTo = relativeTo,
                  relativePoint = relativePoint,
                  x = x,
                  y = y
                }
              end
            end
          end
          
          -- Call original Show
          return originalShow(self, ...)
        end
        
        -- When Edit Mode closes, reapply layouts WITH nudges
        EditModeManagerFrame:HookScript("OnHide", function()
          -- Capture position BEFORE we apply per-icon overrides
          -- This is the position Edit Mode set, which is correct
          local savedPositions = {}
          for _, t in ipairs(TRACKERS) do
            local v = _G[t.name]
            if v and v.GetPoint then
              local point, relativeTo, relativePoint, x, y = v:GetPoint(1)
              if point and x and y then
                savedPositions[t.key] = {
                  point = point,
                  relativeTo = relativeTo,
                  relativePoint = relativePoint,
                  x = x,
                  y = y
                }
                -- Also update known good position
                v._CMT_knownGoodPosition = savedPositions[t.key]
              end
            end
          end
          
          C_Timer.After(0.1, function()
            -- Apply per-icon overrides
            for _, t in ipairs(TRACKERS) do
              local v = _G[t.name]
              if v and v._CMT_baseOrder and #v._CMT_baseOrder > 0 then
                local layoutFunc = t.isBarType and layoutBars or layoutCustomGrid
                layoutFunc(v, t.key, v._CMT_baseOrder)
              end
            end
            
            -- Restore positions that Edit Mode set (before Blizzard shifts them)
            C_Timer.After(0.05, function()
              for _, t in ipairs(TRACKERS) do
                local v = _G[t.name]
                local pos = savedPositions[t.key]
                if v and pos then
                  local currentPoint, currentRelativeTo, currentRelativePoint, currentX, currentY = v:GetPoint(1)
                  if currentX and (math.abs(currentX - pos.x) > 0.5 or math.abs(currentY - pos.y) > 0.5) then
                    posDebug("[%s] DRIFT after Edit Mode close: was %.1f,%.1f should be %.1f,%.1f - RESTORING", 
                      t.key, currentX, currentY, pos.x, pos.y)
                    v:ClearAllPoints()
                    v:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.x, pos.y)
                  end
                end
              end
            end)
          end)
        end)
        
        EditModeManagerFrame._CMT_hooked = true
        dprint("CMT: Hooked EditModeManagerFrame for Edit Mode nudge handling")
      end
    end)
  end
end)

-- Spec change handler for auto-switching profiles
local ev_spec = CreateFrame("Frame")
ev_spec:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
ev_spec:SetScript("OnEvent", function()
  local specIndex = GetSpecialization()
  if not specIndex then return end
  
  local specID = GetSpecializationInfo(specIndex)
  if not specID then return end
  
  -- Reload items for new spec (always, even if profile doesn't change)
  C_Timer.After(0.3, function()
    LoadCustomItems()
  end)
  
  -- Check if this spec has an assigned profile
  local profileName = CMT_CharDB.specProfiles[specID]
  if profileName and CMT_DB.profiles[profileName] then
    local oldProfile = CMT_CharDB.currentProfile
    CMT_CharDB.currentProfile = profileName
    
    -- Clear cached baselines and recapture for the new spec
    C_Timer.After(0.5, function()
      for _,t in ipairs(TRACKERS) do
        local v=_G[t.name]
        if v then
          -- Clear old baseline so it recaptures with new spec's abilities
          v._CMT_baseOrder = nil
          v._CMT_desiredSig = nil
          
          -- Trigger recapture and layout
          if v:IsShown() then
            local layoutFunc = t.isBarType and layoutBars or layoutCustomGrid
            local currentIcons = getBlizzardOrderedIcons(v, t.isBarType, false, t.key)
            if #currentIcons > 0 then
              v._CMT_baseOrder = currentIcons
              layoutFunc(v, t.key, currentIcons)
            end
          end
        end
      end
    end)
    
    print("CMT: Switched to profile: " .. profileName)
    
    -- Only show reload popup if profile actually changed
    if oldProfile ~= profileName then
      StaticPopup_Show("PROFILE_RELOAD_UI")
    end
  end
end)

-- watchdog ticker
local tick=CreateFrame("Frame"); local acc,interval=0,0.25
tick:SetScript("OnUpdate", function(_,dt)
  local now=GetTime(); local iv=(now<_fastRepairUntil) and 0 or interval
  acc=acc+dt; if acc<iv then return end; acc=0
  
  local anchorDriftDetected = false  -- Track if we detect anchor-caused position changes
  
  for _,t in ipairs(TRACKERS) do
    local v=_G[t.name]
    if v then
      -- Hook the viewer if it wasn't hooked yet (e.g., BuffIconCooldownViewer created after bootstrap)
      if not v._CMT_Hooked then
        hookViewer(v, t.key)
        dprint("CMT: Hooked viewer [%s] that appeared after bootstrap", t.key)
        
        -- Immediately try to capture order and apply layout
        C_Timer.After(0.1, function()
          if v and v:IsShown() then
            local isBarType = t.isBarType
            local currentIcons = getBlizzardOrderedIcons(v, isBarType, false, t.key)
            if #currentIcons > 0 then
              v._CMT_baseOrder = currentIcons
              dprint("CMT: Captured %d icons for late-appearing [%s]", #currentIcons, t.key)
              
              -- Apply layout with retries
              local layoutFunc = isBarType and layoutBars or layoutCustomGrid
              local function applyWithRetry(attempt)
                if attempt > 3 then return end
                C_Timer.After(attempt * 0.05, function()
                  if v and v:IsShown() and not v._CMT_applying and v._CMT_baseOrder then
                    layoutFunc(v, t.key, v._CMT_baseOrder)
                    dprint("CMT: Applied initial layout for [%s] (attempt %d)", t.key, attempt)
                    if attempt < 3 then applyWithRetry(attempt + 1) end
                  end
                end)
              end
              applyWithRetry(1)
              _fastRepairUntil = GetTime() + 0.5
            end
          end
        end)
      end
      
      hookChildPointChanges(v); hookChildLifecycle(v, t.key)
      
      -- If drift detected, fix it and extend fast repair mode aggressively
      if v._CMT_drift then 
        v._CMT_drift=nil
        ensureFrozen(v, t.key)
        anchorDriftDetected = true
        _fastRepairUntil = GetTime() + 1.0  -- Extended fast repair when drift detected
      elseif v._CMT_desiredSig then 
        ensureFrozen(v, t.key) 
      end
    end
  end
  
  -- If we detected anchor drift, keep fast mode active longer
  if anchorDriftDetected then
    _fastRepairUntil = math.max(_fastRepairUntil, GetTime() + 1.0)
  end
end)

-- --------------------------------------------------------------------
-- Guardian Health Check System
-- --------------------------------------------------------------------

-- Helper: Get unique identifier for an icon
local function getIconID(icon)
  if not icon then return "nil" end
  
  -- For buff icons, try to get auraInstanceID
  if icon.auraInstanceID then
    return "aura:" .. tostring(icon.auraInstanceID)
  end
  
  -- For ability icons, try to get spellID
  if icon.spellID then
    return "spell:" .. tostring(icon.spellID)
  end
  
  -- Fallback: use frame name or memory address
  local name = icon:GetName()
  if name then
    return "frame:" .. name
  end
  
  return "ptr:" .. tostring(icon)
end

-- Helper: Get icon position relative to parent
local function getIconPosition(icon)
  if not icon or not icon.GetPoint then return nil end
  
  local numPoints = icon:GetNumPoints()
  if numPoints == 0 then return nil end
  
  -- Get first anchor point
  local point, relativeTo, relativePoint, x, y = icon:GetPoint(1)
  
  -- If anchored to parent, return position
  if relativeTo and relativeTo == icon:GetParent() then
    return {
      x = x or 0,
      y = y or 0,
      point = point,
      relativePoint = relativePoint
    }
  end
  
  -- Otherwise try to get center position relative to parent
  local parent = icon:GetParent()
  if parent then
    local iconX, iconY = icon:GetCenter()
    local parentX, parentY = parent:GetCenter()
    if iconX and iconY and parentX and parentY then
      return {
        x = iconX - parentX,
        y = iconY - parentY,
        point = "CENTER",
        relativePoint = "CENTER"
      }
    end
  end
  
  return nil
end

local function checkTrackerHealth(viewer, key, trackerInfo)
  if not viewer then return end
  
  -- Skip items tracker (CMT-owned, not Blizzard - doesn't need guardian monitoring)
  if key == "items" or (trackerInfo and trackerInfo.isCMTOwned) then
    return
  end
  
  local now = GetTime()
  local issues = {}
  local fixed = false
  
  -- Skip if currently applying (don't interfere)
  if viewer._CMT_applying then
    return
  end
  
  -- Check 1: Is viewer hooked?
  local isHooked = viewer._CMT_Hooked == true
  if not isHooked then
    table.insert(issues, "not hooked")
  end
  
  -- Check 2: Does it have baseOrder?
  local hasBaseOrder = viewer._CMT_baseOrder and #viewer._CMT_baseOrder > 0
  local baseOrderSize = (viewer._CMT_baseOrder and #viewer._CMT_baseOrder) or 0
  if not hasBaseOrder and viewer:IsShown() then
    table.insert(issues, "missing baseOrder")
  end
  
  -- Check 3: Is applying lock stuck? (shouldn't be applying for more than 1 second)
  if viewer._CMT_applyingStartTime and (now - viewer._CMT_applyingStartTime) > 1.0 then
    table.insert(issues, "applying lock stuck")
  end
  
  -- Check 4: Do positions match desired signature?
  local sigMatch = true
  if viewer._CMT_desiredSig and viewer._CMT_desiredSig ~= "" then
    local currentSig = sig(viewer)
    sigMatch = currentSig == viewer._CMT_desiredSig
    if not sigMatch then
      table.insert(issues, "signature mismatch")
    end
  end
  
  -- Check 5: Track icon positions and detect changes
  local positionChanges = {}
  if viewer._CMT_baseOrder and #viewer._CMT_baseOrder > 0 then
    -- Initialize position tracking for this tracker if needed
    if not iconPositions[key] then
      iconPositions[key] = {}
    end
    
    -- Check each icon's position
    for idx, icon in ipairs(viewer._CMT_baseOrder) do
      if icon and icon:IsShown() then
        local iconID = getIconID(icon)
        local currentPos = getIconPosition(icon)
        
        if currentPos then
          local prevPos = iconPositions[key][iconID]
          
          if prevPos then
            -- Compare positions (detect changes > 0.5 pixels to avoid floating point noise)
            local dx = math.abs(currentPos.x - prevPos.x)
            local dy = math.abs(currentPos.y - prevPos.y)
            
            if dx > 0.5 or dy > 0.5 then
              -- Position changed!
              table.insert(positionChanges, {
                iconID = iconID,
                idx = idx,
                oldX = prevPos.x,
                oldY = prevPos.y,
                newX = currentPos.x,
                newY = currentPos.y,
                deltaX = currentPos.x - prevPos.x,
                deltaY = currentPos.y - prevPos.y,
                timeSinceLastCheck = now - prevPos.t
              })
            end
          end
          
          -- Update stored position
          iconPositions[key][iconID] = {
            x = currentPos.x,
            y = currentPos.y,
            t = now,
            point = currentPos.point,
            relativePoint = currentPos.relativePoint
          }
        end
      end
    end
    
    -- Clean up positions for icons that no longer exist
    local currentIDs = {}
    for _, icon in ipairs(viewer._CMT_baseOrder) do
      if icon and icon:IsShown() then
        currentIDs[getIconID(icon)] = true
      end
    end
    for iconID in pairs(iconPositions[key]) do
      if not currentIDs[iconID] then
        iconPositions[key][iconID] = nil
      end
    end
  end
  
  -- Log the check
  local entry = {
    t = now,
    tracker = trackerInfo.displayName,
    key = key,
    ok = #issues == 0,
    hooked = isHooked,
    baseOrderSize = baseOrderSize,
    sigMatch = sigMatch,
    positionChanges = positionChanges  -- Always include (empty table if no changes)
  }
  
  -- Attempt recovery if issues found
  if #issues > 0 then
    entry.reason = table.concat(issues, ", ")
    
    -- Recovery: Stuck applying lock
    if viewer._CMT_applyingStartTime and (now - viewer._CMT_applyingStartTime) > 1.0 then
      viewer._CMT_applying = nil
      viewer._CMT_applyingStartTime = nil
      dprint("CMT Guardian: Cleared stuck applying lock for [%s]", key)
      fixed = true
    end
    
    -- Recovery: Not hooked
    if not isHooked then
      hookViewer(viewer, key)
      dprint("CMT Guardian: Re-hooked viewer [%s]", key)
      fixed = true
    end
    
    -- Recovery: Missing baseOrder
    if not hasBaseOrder and viewer:IsShown() then
      local isBarType = trackerInfo.isBarType
      local currentIcons = getBlizzardOrderedIcons(viewer, isBarType, false, key)
      if #currentIcons > 0 then
        viewer._CMT_baseOrder = currentIcons
        dprint("CMT Guardian: Recaptured baseOrder for [%s] (%d icons)", key, #currentIcons)
        fixed = true
      end
    end
    
    -- Recovery: Signature mismatch (positions wrong)
    if not sigMatch and hasBaseOrder then
      -- FIX: Update frame references by matching spellIDs before reapplying layout
      -- This preserves the user's desired ORDER while using current frame references
      local isBarType = trackerInfo.isBarType
      local currentIcons = getBlizzardOrderedIcons(viewer, isBarType, false, key)
      
      -- Build map of identifier -> current frame
      -- Use getMatchIdentifier for stable buff matching (spellID instead of auraInstanceID)
      local currentFrameMap = {}
      for _, icon in ipairs(currentIcons) do
        local identifier = getMatchIdentifier(icon, key)
        if identifier then
          currentFrameMap[identifier] = icon
        end
      end
      
      -- Update baseOrder frame references while preserving order
      local updatedBaseOrder = {}
      local usedIdentifiers = {}
      
      for i, oldFrame in ipairs(viewer._CMT_baseOrder) do
        local identifier = getMatchIdentifier(oldFrame, key)
        if identifier and currentFrameMap[identifier] and not usedIdentifiers[identifier] then
          -- Found matching current frame - use it
          updatedBaseOrder[i] = currentFrameMap[identifier]
          usedIdentifiers[identifier] = true
        else
          -- Frame no longer exists or already used - keep old reference (will be filtered in layout)
          updatedBaseOrder[i] = oldFrame
        end
      end
      
      -- Add any new icons that weren't in baseOrder
      for _, icon in ipairs(currentIcons) do
        local identifier = getMatchIdentifier(icon, key)
        if identifier and not usedIdentifiers[identifier] then
          table.insert(updatedBaseOrder, icon)
          usedIdentifiers[identifier] = true
        end
      end
      
      viewer._CMT_baseOrder = updatedBaseOrder
      
      local layoutFunc = trackerInfo.isBarType and layoutBars or layoutCustomGrid
      layoutFunc(viewer, key, viewer._CMT_baseOrder)
      dprint("CMT Guardian: Updated frame refs and reapplied layout for [%s] (signature mismatch)", key)
      fixed = true
    end
    
    entry.fixed = fixed
    
    -- Alert user on first fix (only if verbose mode enabled)
    if fixed and VERBOSE_FIXES and not viewer._CMT_guardianAlerted then
      print("|cff00ff00CMT:|r Detected and fixed issue with " .. trackerInfo.displayName .. " - type /cmt health for details")
      viewer._CMT_guardianAlerted = true
      -- Clear alert flag after 30 seconds
      C_Timer.After(30, function()
        if viewer then viewer._CMT_guardianAlerted = nil end
      end)
    end
  end
  
  -- Position drift check (runs every tick, regardless of other issues)
  -- Skip during Edit Mode - positions are intentionally different there
  -- Skip during settling period - frames may still be moving to correct positions
  if viewer._CMT_knownGoodPosition and not IsEditModeActive() and not IsSettlingPeriod() then
    local pos = viewer._CMT_knownGoodPosition
    local currentPoint, currentRelativeTo, currentRelativePoint, currentX, currentY = viewer:GetPoint(1)
    if currentX and pos.x and (math.abs(currentX - pos.x) > 0.5 or math.abs(currentY - pos.y) > 0.5) then
      posDebug("[%s] GUARDIAN DRIFT: was %.1f,%.1f should be %.1f,%.1f - RESTORING", 
        key, currentX, currentY, pos.x, pos.y)
      viewer:ClearAllPoints()
      viewer:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.x, pos.y)
    end
  end
  
  -- Also check against static position (if set) - this never auto-updates
  if viewer._CMT_staticPosition and not IsEditModeActive() then
    local staticPos = viewer._CMT_staticPosition
    local _, _, _, currentX, currentY = viewer:GetPoint(1)
    if currentX and staticPos.x and (math.abs(currentX - staticPos.x) > 0.5 or math.abs(currentY - staticPos.y) > 0.5) then
      posDebug("[%s] STATIC DRIFT: was %.1f,%.1f should be %.1f,%.1f (static locked position)", 
        key, currentX, currentY, staticPos.x, staticPos.y)
      -- Don't auto-restore from static - just report it
    end
  end
  
  -- Always log (even successful checks, for diagnostic history)
  addHealthLog(entry)
end

-- Guardian ticker (runs every 0.1s alongside watchdog)
local guardianTick = CreateFrame("Frame")
local guardianAcc = 0
local GUARDIAN_INTERVAL = 0.1

-- Frame reference sync - validates frame references against spellIDs
-- Note: getMatchIdentifier is defined earlier in the file (after getBlizzardOrderedIcons)

-- Proactively cache spellIDs for all buff icons when not in combat
-- This ensures we have identifiers available during combat when API calls may fail
local function warmBuffSpellIDCache(icons, key)
  if key ~= "buffs" then return end
  if InCombatLockdown() then return end  -- Only cache when safe
  
  for _, icon in ipairs(icons) do
    if icon and not icon._CMT_cachedSpellID then
      -- Try to get and cache spellID now while we can
      getMatchIdentifier(icon, key)
    end
  end
end

local function syncFrameReferences(viewer, key, trackerInfo)
  if not viewer or not viewer._CMT_baseOrder or #viewer._CMT_baseOrder == 0 then return end
  if viewer._CMT_applying then return end
  
  local inCombat = InCombatLockdown()
  
  local isBarType = trackerInfo and trackerInfo.isBarType
  local currentIcons = getBlizzardOrderedIcons(viewer, isBarType, false, key)
  if #currentIcons == 0 then return end
  
  -- Warm the cache when not in combat - ensures we have spellIDs for later
  if not inCombat and key == "buffs" then
    warmBuffSpellIDCache(currentIcons, key)
    warmBuffSpellIDCache(viewer._CMT_baseOrder, key)
  end
  
  -- Build map of identifier -> current frame
  -- Use getMatchIdentifier to get stable identifiers (spellID for buffs)
  local currentFrameMap = {}
  for _, icon in ipairs(currentIcons) do
    local identifier = getMatchIdentifier(icon, key)
    if identifier then
      currentFrameMap[identifier] = icon
    end
  end
  
  -- Check if any frame references are stale
  local needsUpdate = false
  local updateCount = 0
  for i, oldFrame in ipairs(viewer._CMT_baseOrder) do
    local identifier = getMatchIdentifier(oldFrame, key)
    if identifier and currentFrameMap[identifier] and currentFrameMap[identifier] ~= oldFrame then
      needsUpdate = true
      updateCount = updateCount + 1
    end
  end
  
  if not needsUpdate then return end
  
  -- Update baseOrder frame references while preserving order
  -- This is SAFE to do even during combat - we're just updating our internal data structure
  local updatedBaseOrder = {}
  local usedIdentifiers = {}
  
  for i, oldFrame in ipairs(viewer._CMT_baseOrder) do
    local identifier = getMatchIdentifier(oldFrame, key)
    if identifier and currentFrameMap[identifier] and not usedIdentifiers[identifier] then
      updatedBaseOrder[i] = currentFrameMap[identifier]
      usedIdentifiers[identifier] = true
    else
      updatedBaseOrder[i] = oldFrame
    end
  end
  
  -- Add any new icons
  for _, icon in ipairs(currentIcons) do
    local identifier = getMatchIdentifier(icon, key)
    if identifier and not usedIdentifiers[identifier] then
      table.insert(updatedBaseOrder, icon)
    end
  end
  
  viewer._CMT_baseOrder = updatedBaseOrder
  dprint("CMT: Updated %d frame references for [%s]%s", updateCount, key, inCombat and " (in combat)" or "")
  
  -- Only apply layout if NOT in combat (layout can't run on protected frames in combat)
  if not inCombat then
    local layoutFunc = (trackerInfo and trackerInfo.isBarType) and layoutBars or layoutCustomGrid
    layoutFunc(viewer, key, viewer._CMT_baseOrder)
    dprint("CMT: Frame ref sync applied layout for [%s]", key)
  else
    -- Mark as pending so it applies when combat ends
    viewer._CMT_pending = true
    CMT_DB._pendingApply = CMT_DB._pendingApply or {}
    CMT_DB._pendingApply[key] = true
  end
end

-- Cooldown update handler - syncs frame references when cooldowns change
local cooldownSyncFrame = CreateFrame("Frame")
local cooldownSyncAcc = 0
local COOLDOWN_SYNC_INTERVAL = 0.25  -- Check every 250ms after cooldown updates

cooldownSyncFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
cooldownSyncFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
cooldownSyncFrame:SetScript("OnEvent", function()
  -- Set a flag to trigger sync in next OnUpdate
  cooldownSyncFrame._needsSync = true
  cooldownSyncAcc = 0
end)

cooldownSyncFrame:SetScript("OnUpdate", function(self, dt)
  if not self._needsSync then return end
  
  cooldownSyncAcc = cooldownSyncAcc + dt
  if cooldownSyncAcc < COOLDOWN_SYNC_INTERVAL then return end
  
  self._needsSync = false
  cooldownSyncAcc = 0
  
  -- Sync frame references for all trackers
  for _, t in ipairs(TRACKERS) do
    if t.key ~= "items" and not t.isCMTOwned then
      local v = _G[t.name]
      if v and v:IsShown() then
        syncFrameReferences(v, t.key, t)
      end
    end
  end
end)

guardianTick:SetScript("OnUpdate", function(_, dt)
  guardianAcc = guardianAcc + dt
  if guardianAcc < GUARDIAN_INTERVAL then return end
  guardianAcc = 0
  
  -- Check health of all trackers
  for _, t in ipairs(TRACKERS) do
    local v = _G[t.name]
    if v then
      checkTrackerHealth(v, t.key, t)
      
      -- Screen position watcher - tracks actual pixel position via GetCenter()
      if (POSITION_DEBUG or POSITION_WATCH) and v:IsShown() then
        local cx, cy = v:GetCenter()
        if cx and cy then
          -- Store last known screen position
          if not v._CMT_lastScreenPos then
            v._CMT_lastScreenPos = { x = cx, y = cy }
          else
            local dx = math.abs(cx - v._CMT_lastScreenPos.x)
            local dy = math.abs(cy - v._CMT_lastScreenPos.y)
            if dx > 0.5 or dy > 0.5 then
              -- Get anchor info at moment of change
              local point, relativeTo, relativePoint, offX, offY = v:GetPoint(1)
              local relName = relativeTo and (relativeTo.GetName and relativeTo:GetName() or tostring(relativeTo)) or "nil"
              posDebug("[%s] SCREEN POS CHANGED: was %.1f,%.1f now %.1f,%.1f (delta: %.1f,%.1f)", 
                t.key, v._CMT_lastScreenPos.x, v._CMT_lastScreenPos.y, cx, cy, dx, dy)
              posDebug("  Anchor: %s on %s at %s, offset: %.1f,%.1f", 
                point or "?", relName, relativePoint or "?", offX or 0, offY or 0)
              v._CMT_lastScreenPos = { x = cx, y = cy }
              
              -- If the new position is LOWER (smaller Y), it might be correcting to the right position
              -- Update knownGoodPosition if this looks like a correction after load
              if not v._CMT_positionSettled and GetTime() < 30 then  -- Within 30s of load
                posDebug("  Early position change detected - may be settling")
              end
            end
          end
        end
      end
    end
  end
end)

local regen=CreateFrame("Frame")
regen:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Leaving combat
regen:SetScript("OnEvent", function(self, event)
  -- Update frame references and apply pending layouts after leaving combat
  -- This fixes scrambling that occurred during combat
  for _,t in ipairs(TRACKERS) do
    local v=_G[t.name]
    if v and v:IsShown() and v._CMT_baseOrder and #v._CMT_baseOrder > 0 then
      local isBarType = t.isBarType
      local currentIcons = getBlizzardOrderedIcons(v, isBarType, false, t.key)
      
      -- Build map of identifier -> current frame
      -- Use getMatchIdentifier for stable buff matching (spellID instead of auraInstanceID)
      local currentFrameMap = {}
      for _, icon in ipairs(currentIcons) do
        local identifier = getMatchIdentifier(icon, t.key)
        if identifier then
          currentFrameMap[identifier] = icon
        end
      end
      
      -- Update baseOrder frame references while preserving order
      local updatedBaseOrder = {}
      local usedIdentifiers = {}
      
      for i, oldFrame in ipairs(v._CMT_baseOrder) do
        local identifier = getMatchIdentifier(oldFrame, t.key)
        if identifier and currentFrameMap[identifier] and not usedIdentifiers[identifier] then
          updatedBaseOrder[i] = currentFrameMap[identifier]
          usedIdentifiers[identifier] = true
        else
          updatedBaseOrder[i] = oldFrame
        end
      end
      
      -- Add any new icons
      for _, icon in ipairs(currentIcons) do
        local identifier = getMatchIdentifier(icon, t.key)
        if identifier and not usedIdentifiers[identifier] then
          table.insert(updatedBaseOrder, icon)
          usedIdentifiers[identifier] = true
        end
      end
      
      v._CMT_baseOrder = updatedBaseOrder
      
      -- Apply layout
      local layoutFunc = t.isBarType and layoutBars or layoutCustomGrid
      layoutFunc(v, t.key, v._CMT_baseOrder)
      v._CMT_drift=nil
      dprint("CMT: Updated frame refs and reapplied layout for [%s] after combat", t.key)
    end
  end
  CMT_DB._pendingApply = nil
end)

-- --------------------------------------------------------------------
-- Config UI (alignment text fix)
-- --------------------------------------------------------------------
local configPanel
local tabHeader

local function SafeTabResize(btn, padding)
  padding = padding or 20
  if not btn.Text and btn.GetFontString then
    local fs=btn:GetFontString(); if fs then btn.Text=fs end
  end
  if type(PanelTemplates_TabResize)=="function" then
    local ok=pcall(PanelTemplates_TabResize, btn, 0); if ok then return end
  end
  local base=80
  if btn.Text and btn.Text:GetStringWidth() then base=btn.Text:GetStringWidth()+padding end
  btn:SetWidth(base)
end

-- Create visibility controls UI section for a tracker tab (v4.4.0)
local function CreateVisibilitySection(content, key, y)
  -- Section header
  local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  header:SetPoint("TOPLEFT", 15, y)
  header:SetText("Visibility Settings")
  header:SetTextColor(1, 0.8, 0)
  y = y - 25
  
  -- Check for EMT conflict
  local trackerInfo = getTrackerInfoByKey(key)
  local frameName = trackerInfo and trackerInfo.name
  local emtConflict = frameName and IsEMTManagingFrame(frameName)
  local emtOverride = GetSetting(key, "visibilityOverrideEMT") or false
  
  -- EMT override section (only shown when EMT is managing this frame)
  if emtConflict then
    local warning = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    warning:SetPoint("TOPLEFT", 15, y)
    warning:SetWidth(600)
    warning:SetText("|cffff9900Note:|r Edit Mode Tweaks has visibility settings for this frame.")
    warning:SetTextColor(1, 0.7, 0.3)
    y = y - 20
    
    local overrideCB = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
    overrideCB:SetPoint("TOPLEFT", 15, y)
    overrideCB.Text:SetText("Use CMT visibility instead of Edit Mode Tweaks")
    overrideCB.Text:SetTextColor(1, 0.8, 0.4)
    overrideCB:SetChecked(emtOverride)
    overrideCB:SetScript("OnClick", function(self)
      local override = self:GetChecked() and true or false
      SetSetting(key, "visibilityOverrideEMT", override)
      VisibilityManager:UpdateMouseoverDetector(key)
      VisibilityManager:ApplyVisibility(key, true)
    end)
    y = y - 30
  end
  
  -- Master enable
  local enableCB = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
  enableCB:SetPoint("TOPLEFT", 15, y)
  enableCB.Text:SetText("Enable visibility controls")
  enableCB:SetChecked(GetSetting(key, "visibilityEnabled") or false)
  enableCB:SetScript("OnClick", function(self)
    SetSetting(key, "visibilityEnabled", self:GetChecked() and true or false)
    VisibilityManager:UpdateMouseoverDetector(key)
    VisibilityManager:ApplyVisibility(key, true)
  end)
  y = y - 28
  
  -- Description
  local desc = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  desc:SetPoint("TOPLEFT", 15, y)
  desc:SetWidth(600)
  desc:SetText("Tracker hides until ANY checked condition below is met.")
  desc:SetTextColor(0.6, 0.6, 0.6)
  y = y - 30
  
  -- Conditions label
  local condLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  condLabel:SetPoint("TOPLEFT", 15, y)
  condLabel:SetText("Show tracker when:")
  y = y - 22
  
  -- Combat
  local combatCB = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
  combatCB:SetPoint("TOPLEFT", 25, y)
  combatCB.Text:SetText("In combat")
  combatCB:SetChecked(GetSetting(key, "visibilityCombat") or false)
  combatCB:SetScript("OnClick", function(self)
    SetSetting(key, "visibilityCombat", self:GetChecked() and true or false)
    C_Timer.After(0.05, function()
      VisibilityManager:ApplyVisibility(key, true)
    end)
  end)
  y = y - 24
  
  -- Mouseover
  local mouseoverCB = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
  mouseoverCB:SetPoint("TOPLEFT", 25, y)
  mouseoverCB.Text:SetText("Mouse over tracker")
  mouseoverCB:SetChecked(GetSetting(key, "visibilityMouseover") or false)
  mouseoverCB:SetScript("OnClick", function(self)
    SetSetting(key, "visibilityMouseover", self:GetChecked() and true or false)
    VisibilityManager:UpdateMouseoverDetector(key)
    VisibilityManager:ApplyVisibility(key, false)
  end)
  y = y - 24
  
  -- Target
  local targetCB = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
  targetCB:SetPoint("TOPLEFT", 25, y)
  targetCB.Text:SetText("Have a target")
  targetCB:SetChecked(GetSetting(key, "visibilityTarget") or false)
  targetCB:SetScript("OnClick", function(self)
    SetSetting(key, "visibilityTarget", self:GetChecked() and true or false)
    -- Don't apply visibility here - let the PLAYER_TARGET_CHANGED event handle it
    -- Just trigger one check in case they already have a target
    C_Timer.After(0.1, function()
      VisibilityManager:ApplyVisibility(key, true)
    end)
  end)
  y = y - 24
  
  -- Group
  local groupCB = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
  groupCB:SetPoint("TOPLEFT", 25, y)
  groupCB.Text:SetText("In a party or raid")
  groupCB:SetChecked(GetSetting(key, "visibilityGroup") or false)
  groupCB:SetScript("OnClick", function(self)
    SetSetting(key, "visibilityGroup", self:GetChecked() and true or false)
    C_Timer.After(0.05, function()
      VisibilityManager:ApplyVisibility(key, true)
    end)
  end)
  y = y - 24
  
  -- Instance types header
  local instanceCB = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
  instanceCB:SetPoint("TOPLEFT", 25, y)
  instanceCB.Text:SetText("In specific instances:")
  instanceCB:SetChecked(GetSetting(key, "visibilityInstance") or false)
  instanceCB:SetScript("OnClick", function(self)
    SetSetting(key, "visibilityInstance", self:GetChecked() and true or false)
    VisibilityManager:ApplyVisibility(key, true)
  end)
  y = y - 22
  
  -- Instance type sub-options
  local instanceTypes = {
    { id = "party", text = "Dungeons" },
    { id = "raid", text = "Raids" },
    { id = "arena", text = "Arenas" },
    { id = "pvp", text = "Battlegrounds" },
    { id = "scenario", text = "Scenarios" },
  }
  
  local currentTypes = GetSetting(key, "visibilityInstanceTypes") or {}
  for _, inst in ipairs(instanceTypes) do
    local cb = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 45, y)
    cb.Text:SetText(inst.text)
    cb.Text:SetFontObject("GameFontNormalSmall")
    cb:SetChecked(currentTypes[inst.id] or false)
    cb:SetScript("OnClick", function(self)
      local types = GetSetting(key, "visibilityInstanceTypes") or {}
      types[inst.id] = self:GetChecked() and true or false
      SetSetting(key, "visibilityInstanceTypes", types)
      VisibilityManager:ApplyVisibility(key, true)
    end)
    y = y - 20
  end
  y = y - 10
  
  -- Fade alpha slider
  local fadeLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fadeLabel:SetPoint("TOPLEFT", 15, y)
  local currentFade = GetSetting(key, "visibilityFadeAlpha") or 0
  fadeLabel:SetText(string.format("Hidden opacity: %d%%", currentFade))
  y = y - 20
  
  local fadeSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
  fadeSlider:SetPoint("TOPLEFT", 15, y)
  fadeSlider:SetMinMaxValues(0, 100)
  fadeSlider:SetValueStep(5)
  fadeSlider:SetObeyStepOnDrag(true)
  fadeSlider:SetWidth(200)
  fadeSlider.Low:SetText("0%")
  fadeSlider.High:SetText("100%")
  
  local initFade = true
  fadeSlider:SetScript("OnValueChanged", function(self, value)
    if initFade then return end
    fadeLabel:SetText(string.format("Hidden opacity: %d%%", value))
    SetSetting(key, "visibilityFadeAlpha", value)
    VisibilityManager:ApplyVisibility(key, true)
  end)
  fadeSlider:SetValue(currentFade)
  initFade = false
  y = y - 45  -- Increased spacing for slider Low/High labels
  
  local fadeDesc = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  fadeDesc:SetPoint("TOPLEFT", 15, y)
  fadeDesc:SetWidth(600)
  fadeDesc:SetText("0% = invisible when hidden, higher = partially visible")
  fadeDesc:SetTextColor(0.5, 0.5, 0.5)
  y = y - 30  -- Extra spacing before next section
  
  return y
end

local function CreateTrackerTab(parent, key, display)
  -- Outer container that fills the left content area
  local container = CreateFrame("Frame", nil, parent)
  -- Width and height will be set by anchor points when positioned
  
  -- Create ScrollFrame that fills the container (leaving room for scrollbar)
  local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 0, 0)
  scrollFrame:SetPoint("BOTTOMRIGHT", -25, 0)  -- Leave room for scrollbar
  
  -- Enable mouse wheel scrolling
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local step = 40  -- Scroll step in pixels
    
    if delta > 0 then
      self:SetVerticalScroll(math.max(0, current - step))
    else
      self:SetVerticalScroll(math.min(maxScroll, current + step))
    end
  end)
  
  -- Scroll child that holds all content (will be sized dynamically)
  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetWidth(650)  -- Use available width (container is ~680 wide minus scrollbar)
  scrollFrame:SetScrollChild(content)
  
  local y = -15

  local title=content:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  title:SetPoint("TOPLEFT",15,y); title:SetText(display); y=y-30

  -- Profile Display (read-only, managed in Profiles tab)
  local profileLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  profileLabel:SetPoint("TOPLEFT",15,y)
  profileLabel:SetText("Current Profile: " .. (CMT_CharDB.currentProfile or "Default"))
  profileLabel:SetTextColor(0.7, 0.7, 0.7)
  y=y-25

  -- Per-tracker Masque toggle (only show if Masque is globally enabled)
  if MasqueModule and MasqueModule.IsAvailable and MasqueModule.IsAvailable() and CMT_DB.masqueEnabled then
    local masqueCB = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
    masqueCB:SetPoint("TOPLEFT", 15, y)
    masqueCB.Text:SetText("Use Masque Skinning")
    
    local masqueDisabled = GetSetting(key, "masqueDisabled") or false
    masqueCB:SetChecked(not masqueDisabled)
    
    masqueCB:SetScript("OnClick", function(self)
      if self:GetChecked() then
        -- Enable Masque for this tracker
        if MasqueModule.EnableForTracker then
          MasqueModule.EnableForTracker(key)
        end
      else
        -- Disable Masque for this tracker
        if MasqueModule.DisableForTracker then
          MasqueModule.DisableForTracker(key)
        end
      end
    end)
    
    local masqueNote = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    masqueNote:SetPoint("LEFT", masqueCB.Text, "RIGHT", 10, 0)
    masqueNote:SetText("(disabling restores aspect ratio)")
    masqueNote:SetTextColor(0.6, 0.6, 0.6)
    
    y = y - 30
  end

  -- Check if this is a bar type tracker
  local trackerInfo = getTrackerInfoByKey(key)
  local isBarTracker = trackerInfo and trackerInfo.isBarType

  -- Only show grid-specific options for non-bar trackers
  if not isBarTracker then
    -- Layout Direction
    local dirLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    dirLabel:SetPoint("TOPLEFT",15,y); dirLabel:SetText("Layout Direction:")

    local dirDD=CreateFrame("Frame", nil, content, "UIDropDownMenuTemplate")
    dirDD:SetPoint("LEFT", dirLabel, "RIGHT", -10, -5)

    local function dirToText(v)
      if v == "COLUMNS" then return "Columns"
      else return "Rows" end
    end
    
    -- Translation between horizontal and vertical alignments (define early for use in SetupDirection)
    local function horizontalToVertical(h)
      if h == "LEFT" then return "TOP"
      elseif h == "RIGHT" then return "BOTTOM"
      else return "MIDDLE" end
    end

    local function verticalToHorizontal(v)
      if v == "TOP" then return "LEFT"
      elseif v == "BOTTOM" then return "RIGHT"
      else return "CENTER" end
    end
    
    -- Forward declaration - will be defined below
    local SetupAlign

    local function SetupDirection()
      UIDropDownMenu_Initialize(dirDD, function()
        local function add(text,val)
          local info=UIDropDownMenu_CreateInfo()
          info.text=text
          info.func=function()
            local oldDir = GetSetting(key,"layoutDirection") or "ROWS"
            local newDir = val
            
            -- Auto-convert alignment when switching modes
            if oldDir ~= newDir then
              local currentAlign = GetSetting(key,"alignment")
              if currentAlign then
                if newDir == "COLUMNS" then
                  -- Switching to columns: convert horizontal to vertical
                  SetSetting(key,"alignment", horizontalToVertical(currentAlign))
                else
                  -- Switching to rows: convert vertical to horizontal
                  SetSetting(key,"alignment", verticalToHorizontal(currentAlign))
                end
              end
              
              -- Force recapture baseline order when direction changes
              -- This ensures icons are read in the correct sequence for the new layout
              forceRecaptureOrder(key)
            end
            
            SetSetting(key,"layoutDirection",val)
            UIDropDownMenu_SetSelectedValue(dirDD,val)
            UIDropDownMenu_SetText(dirDD, dirToText(val))
            -- Refresh the alignment dropdown when direction changes
            if SetupAlign then SetupAlign() end
            relayoutOne(key)
          end
          info.checked=(GetSetting(key,"layoutDirection") or "ROWS")==val
          UIDropDownMenu_AddButton(info)
        end
        add("Rows","ROWS"); add("Columns","COLUMNS")
      end)

      UIDropDownMenu_SetWidth(dirDD,100)
      local cur = GetSetting(key,"layoutDirection") or "ROWS"
      UIDropDownMenu_SetSelectedValue(dirDD, cur)
      UIDropDownMenu_SetText(dirDD, dirToText(cur))
    end

    SetupDirection(); y=y-50

    -- Row/Column Alignment (changes based on layout direction)
    local alignLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    alignLabel:SetPoint("TOPLEFT",15,y)

    local alignDD=CreateFrame("Frame", nil, content, "UIDropDownMenuTemplate")
    alignDD:SetPoint("LEFT", alignLabel, "RIGHT", -10, -5)

    local function valToText(v, isColumns)
      if isColumns then
        -- Column mode: TOP/MIDDLE/BOTTOM
        if v == "TOP" then return "Top"
        elseif v == "BOTTOM" then return "Bottom"
        else return "Middle" end
      else
        -- Row mode: LEFT/CENTER/RIGHT
        if v == "LEFT" then return "Left"
        elseif v == "RIGHT" then return "Right"
        else return "Center" end
      end
    end

    SetupAlign = function()
      local isColumns = (GetSetting(key,"layoutDirection") or "ROWS") == "COLUMNS"
      
      -- Update label based on direction
      if isColumns then
        alignLabel:SetText("Column Alignment:")
      else
        alignLabel:SetText("Row Alignment:")
      end

      UIDropDownMenu_Initialize(alignDD, function()
        local function add(text,val)
          local info=UIDropDownMenu_CreateInfo()
          info.text=text
          info.func=function()
            SetSetting(key,"alignment",val)
            UIDropDownMenu_SetSelectedValue(alignDD,val)
            UIDropDownMenu_SetText(alignDD, valToText(val, isColumns))
            relayoutOne(key)
          end
          local current = GetSetting(key,"alignment")
          if not current then
            current = isColumns and "MIDDLE" or "CENTER"
          end
          info.checked = current == val
          UIDropDownMenu_AddButton(info)
        end
        
        if isColumns then
          add("Top","TOP"); add("Middle","MIDDLE"); add("Bottom","BOTTOM")
        else
          add("Left","LEFT"); add("Center","CENTER"); add("Right","RIGHT")
        end
      end)

      UIDropDownMenu_SetWidth(alignDD,100)
      local cur = GetSetting(key,"alignment")
      
      -- Just use default if no saved value - don't auto-translate or overwrite!
      if not cur then
        cur = isColumns and "MIDDLE" or "CENTER"
      end
      
      UIDropDownMenu_SetSelectedValue(alignDD, cur)
      UIDropDownMenu_SetText(alignDD, valToText(cur, isColumns))
    end

    SetupAlign(); y=y-50

    -- Row/Column Pattern (label changes based on layout direction)
    local patLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    patLabel:SetPoint("TOPLEFT",15,y)
    
    local function updatePatternLabel()
      local dir = GetSetting(key,"layoutDirection") or "ROWS"
      if dir == "COLUMNS" then
        patLabel:SetText("Column Pattern (e.g. 3,4,4):")
      else
        patLabel:SetText("Row Pattern (e.g. 1,3,4,3):")
      end
    end
    updatePatternLabel()
    
    local patBox=CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    patBox:SetSize(220,25); patBox:SetPoint("LEFT", patLabel, "RIGHT", 10,0)
    patBox:SetAutoFocus(false); patBox:SetNumeric(false); patBox:SetMaxLetters(64)
    local function patToStr(p) local out={}; for _,v in ipairs(p or {}) do out[#out+1]=tostring(v) end; return table.concat(out,",") end
    local function strToPat(s) local p={}; for num in string.gmatch(s or "", "%d+") do p[#p+1]=tonumber(num) end; if #p==0 then p={1,3,4,3} end; return p end
    patBox:SetText(patToStr(GetSetting(key,"rowPattern")))
    patBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    patBox:SetScript("OnEditFocusLost", function(self) SetSetting(key,"rowPattern", strToPat(self:GetText() or "1,3,4,3")); relayoutOne(key) end)
    y=y-35
  end

  -- Reverse (available for cooldowns, but not buffs since they're dynamic)
  if key ~= "buffs" then
    local rev=CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
    rev:SetPoint("TOPLEFT",15,y); rev.Text:SetText("Reverse order")
    rev:SetChecked(GetSetting(key,"reverseOrder") or false)
    rev:SetScript("OnClick", function(self) SetSetting(key,"reverseOrder", self:GetChecked() and true or false); relayoutOne(key) end)
    y=y-30
  end

  -- Icon Size Slider (available for both types)
  local sizeLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormal")
  sizeLabel:SetPoint("TOPLEFT",15,y)
  local currentSize = GetSetting(key,"iconSize") or 40
  sizeLabel:SetText(string.format("Icon Size: %dpx", currentSize))
  y=y-20
  
  local sizeSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
  sizeSlider:SetPoint("TOPLEFT", 15, y)
  sizeSlider:SetMinMaxValues(20, 80)
  sizeSlider:SetValueStep(1)
  sizeSlider:SetObeyStepOnDrag(true)
  sizeSlider:SetWidth(300)
  sizeSlider.Low:SetText("20px")
  sizeSlider.High:SetText("80px")
  
  local initializingSize = true
  sizeSlider:SetScript("OnValueChanged", function(self, value)
    if initializingSize then return end
    sizeLabel:SetText(string.format("Icon Size: %dpx", value))
    SetSetting(key,"iconSize", value)
    relayoutOne(key)
  end)
  
  sizeSlider:SetValue(currentSize)
  initializingSize = false
  y=y-40

  -- Icon Opacity Slider (available for both types)
  local opacityLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormal")
  opacityLabel:SetPoint("TOPLEFT",15,y)
  local currentOpacity = GetSetting(key,"iconOpacity")
  if currentOpacity == nil then currentOpacity = 1.0 end
  opacityLabel:SetText(string.format("Icon Opacity: %d%%", currentOpacity * 100))
  y=y-20
  
  local opacitySlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
  opacitySlider:SetPoint("TOPLEFT", 15, y)
  opacitySlider:SetMinMaxValues(0.1, 1.0)
  opacitySlider:SetValueStep(0.05)
  opacitySlider:SetObeyStepOnDrag(true)
  opacitySlider:SetWidth(300)
  opacitySlider.Low:SetText("10%")
  opacitySlider.High:SetText("100%")
  
  local initializingOpacity = true
  opacitySlider:SetScript("OnValueChanged", function(self, value)
    if initializingOpacity then return end
    opacityLabel:SetText(string.format("Icon Opacity: %d%%", value * 100))
    SetSetting(key,"iconOpacity", value)
    relayoutOne(key)
  end)
  
  opacitySlider:SetValue(currentOpacity)
  initializingOpacity = false
  y=y-40

  -- Zoom Slider (available for both types)
  local zoomLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormal")
  zoomLabel:SetPoint("TOPLEFT",15,y)
  zoomLabel:SetText("Icon Texture Zoom: 100%")
  y=y-20
  
  local zoomSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
  zoomSlider:SetPoint("TOPLEFT", 15, y)
  zoomSlider:SetMinMaxValues(1.0, 3.0)
  zoomSlider:SetValueStep(0.1)
  zoomSlider:SetObeyStepOnDrag(true)
  zoomSlider:SetWidth(300)
  zoomSlider.Low:SetText("100%")
  zoomSlider.High:SetText("300%")
  
  local initializingZoom = true
  zoomSlider:SetScript("OnValueChanged", function(self, value)
    if initializingZoom then return end
    zoomLabel:SetText(string.format("Icon Texture Zoom: %d%%", value * 100))
    SetSetting(key,"zoom", value)
    relayoutOne(key)
  end)
  
  local currentZoom = GetSetting(key,"zoom")
  if currentZoom == nil then currentZoom = 1.0 end
  zoomSlider:SetValue(currentZoom)
  zoomLabel:SetText(string.format("Icon Texture Zoom: %d%%", currentZoom * 100))
  initializingZoom = false
  y=y-40
  
  -- Aspect Ratio Dropdown (available for both types)
  local aspectLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormal")
  aspectLabel:SetPoint("TOPLEFT",15,y); aspectLabel:SetText("Icon Aspect Ratio:")
  y=y-20
  
  local aspectDD=CreateFrame("Frame", nil, content, "UIDropDownMenuTemplate")
  aspectDD:SetPoint("TOPLEFT",5,y)
  UIDropDownMenu_SetWidth(aspectDD,200)
  
  local aspectOptions = {
    {text="Square (1:1)", value="1:1"},
    {text="Widescreen (16:9)", value="16:9"},
    {text="Ultrawide (21:9)", value="21:9"},
    {text="Classic Wide (4:3)", value="4:3"},
    {text="Portrait (9:16)", value="9:16"},
    {text="Tall Portrait (3:4)", value="3:4"},
    {text="Custom...", value="custom"},
  }
  
  -- Custom aspect ratio input container (hidden by default) - positioned to the RIGHT of dropdown
  local customAspectContainer = CreateFrame("Frame", nil, content)
  customAspectContainer:SetPoint("LEFT", aspectDD, "RIGHT", -15, 0)
  customAspectContainer:SetSize(200, 30)
  customAspectContainer:Hide()
  
  local widthLabel = customAspectContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  widthLabel:SetPoint("LEFT", 0, 0)
  widthLabel:SetText("W:")
  
  local widthEditBox = CreateFrame("EditBox", nil, customAspectContainer, "InputBoxTemplate")
  widthEditBox:SetPoint("LEFT", widthLabel, "RIGHT", 2, 0)
  widthEditBox:SetSize(40, 20)
  widthEditBox:SetAutoFocus(false)
  widthEditBox:SetNumeric(true)
  widthEditBox:SetMaxLetters(3)
  
  local heightLabel = customAspectContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  heightLabel:SetPoint("LEFT", widthEditBox, "RIGHT", 8, 0)
  heightLabel:SetText("H:")
  
  local heightEditBox = CreateFrame("EditBox", nil, customAspectContainer, "InputBoxTemplate")
  heightEditBox:SetPoint("LEFT", heightLabel, "RIGHT", 2, 0)
  heightEditBox:SetSize(40, 20)
  heightEditBox:SetAutoFocus(false)
  heightEditBox:SetNumeric(true)
  heightEditBox:SetMaxLetters(3)
  
  local applyCustomBtn = CreateFrame("Button", nil, customAspectContainer, "UIPanelButtonTemplate")
  applyCustomBtn:SetPoint("LEFT", heightEditBox, "RIGHT", 5, 0)
  applyCustomBtn:SetSize(50, 22)
  applyCustomBtn:SetText("Apply")
  applyCustomBtn:SetScript("OnClick", function()
    local w = tonumber(widthEditBox:GetText()) or 40
    local h = tonumber(heightEditBox:GetText()) or 40
    -- Clamp values to reasonable range
    w = math.max(10, math.min(200, w))
    h = math.max(10, math.min(200, h))
    local customValue = FormatCustomAspectRatio(w, h)
    SetSetting(key, "aspectRatio", customValue)
    UIDropDownMenu_SetText(aspectDD, string.format("Custom (%dx%d)", w, h))
    relayoutOne(key)
  end)
  
  -- Set up enter key to apply
  widthEditBox:SetScript("OnEnterPressed", function() applyCustomBtn:Click() end)
  heightEditBox:SetScript("OnEnterPressed", function() applyCustomBtn:Click() end)
  
  UIDropDownMenu_Initialize(aspectDD, function()
    local currentAspect = GetSetting(key,"aspectRatio") or "1:1"
    local isCustom = IsCustomAspectRatio(currentAspect)
    
    for _, opt in ipairs(aspectOptions) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = opt.text
      info.value = opt.value
      info.func = function()
        if opt.value == "custom" then
          -- Show custom input fields
          customAspectContainer:Show()
          -- Pre-populate with current values if already custom
          if isCustom then
            local w, h = ParseAspectRatio(currentAspect)
            widthEditBox:SetText(tostring(w))
            heightEditBox:SetText(tostring(h))
          else
            -- Default to current icon size
            local iconSize = GetSetting(key, "iconSize") or 40
            widthEditBox:SetText(tostring(iconSize))
            heightEditBox:SetText(tostring(iconSize))
          end
          UIDropDownMenu_SetText(aspectDD, "Custom...")
        else
          customAspectContainer:Hide()
          SetSetting(key,"aspectRatio", opt.value)
          UIDropDownMenu_SetSelectedValue(aspectDD, opt.value)
          UIDropDownMenu_SetText(aspectDD, opt.text)
          relayoutOne(key)
        end
        CloseDropDownMenus()
      end
      -- Check custom option if current aspect is custom format
      if opt.value == "custom" then
        info.checked = isCustom
      else
        info.checked = (currentAspect == opt.value)
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
  
  -- Set initial text and show custom inputs if needed
  local currentAspect = GetSetting(key,"aspectRatio") or "1:1"
  if IsCustomAspectRatio(currentAspect) then
    local w, h = ParseAspectRatio(currentAspect)
    UIDropDownMenu_SetText(aspectDD, string.format("Custom (%dx%d)", w, h))
    customAspectContainer:Show()
    widthEditBox:SetText(tostring(w))
    heightEditBox:SetText(tostring(h))
  else
    for _, opt in ipairs(aspectOptions) do
      if opt.value == currentAspect then
        UIDropDownMenu_SetText(aspectDD, opt.text)
        break
      end
    end
  end
  y=y-40
  
  -- Border Alpha Slider (skip for items tracker - it has no borders)
  if key ~= "items" then
    local borderAlphaLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    borderAlphaLabel:SetPoint("TOPLEFT",15,y)
    borderAlphaLabel:SetText("Border Visibility: 100%")
    y=y-20
    
    local borderAlphaSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    borderAlphaSlider:SetPoint("TOPLEFT",15,y)
    borderAlphaSlider:SetMinMaxValues(0, 1)
    borderAlphaSlider:SetValueStep(0.05)
    borderAlphaSlider:SetObeyStepOnDrag(true)
    borderAlphaSlider:SetWidth(200)
    
    -- Set up the callback before setting the value, with initialization guard
    local initializing = true
    borderAlphaSlider:SetScript("OnValueChanged", function(self, value)
      if initializing then return end
      SetSetting(key,"borderAlpha", value)
      borderAlphaLabel:SetText(string.format("Border Visibility: %d%%", value * 100))
      relayoutOne(key)
    end)
    
    -- Now set the initial value
    local currentBorderAlpha = GetSetting(key,"borderAlpha")
    if currentBorderAlpha == nil then
      currentBorderAlpha = 1.0
    end
    borderAlphaSlider:SetValue(currentBorderAlpha)
    borderAlphaLabel:SetText(string.format("Border Visibility: %d%%", currentBorderAlpha * 100))
    initializing = false
    
    borderAlphaSlider.Low:SetText("0%")
    borderAlphaSlider.High:SetText("100%")
    y=y-30
    
    -- Border Scale Checkbox
    local borderScaleCB = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
    borderScaleCB:SetPoint("TOPLEFT", 15, y)
    borderScaleCB.Text:SetText("Scale border with icon size")
    borderScaleCB.tooltipText = "When enabled, border thickness scales proportionally with icon size.\nDisable to keep Blizzard's default border thickness regardless of icon size."
    
    local currentBorderScale = GetSetting(key, "borderScale")
    if currentBorderScale == nil then currentBorderScale = true end
    borderScaleCB:SetChecked(currentBorderScale)
    
    borderScaleCB:SetScript("OnClick", function(self)
      SetSetting(key, "borderScale", self:GetChecked() and true or false)
      relayoutOne(key)
    end)
    y=y-30
  end
  
  -- Cooldown Text Scale Slider
  local cdTextScaleLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormal")
  cdTextScaleLabel:SetPoint("TOPLEFT",15,y)
  local currentCDScale = GetSetting(key,"cooldownTextScale") or 1.0
  cdTextScaleLabel:SetText(string.format("Cooldown Text Size: %d%%", currentCDScale * 100))
  y=y-20
  
  local cdTextScaleSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
  cdTextScaleSlider:SetPoint("TOPLEFT",15,y)
  cdTextScaleSlider:SetMinMaxValues(0.5, 2.0)
  cdTextScaleSlider:SetValueStep(0.05)
  cdTextScaleSlider:SetObeyStepOnDrag(true)
  cdTextScaleSlider:SetWidth(200)
  cdTextScaleSlider.Low:SetText("50%")
  cdTextScaleSlider.High:SetText("200%")
  
  local initializingCDScale = true
  cdTextScaleSlider:SetScript("OnValueChanged", function(self, value)
    if initializingCDScale then return end
    SetSetting(key,"cooldownTextScale", value)
    cdTextScaleLabel:SetText(string.format("Cooldown Text Size: %d%%", value * 100))
    relayoutOne(key)
  end)
  
  cdTextScaleSlider:SetValue(currentCDScale)
  initializingCDScale = false
  y=y-40

  -- Count Text Scale Slider (not for items - it has its own pixel-based slider)
  if key ~= "items" then
    local countTextScaleLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    countTextScaleLabel:SetPoint("TOPLEFT",15,y)
    local currentCountScale = GetSetting(key,"countTextScale") or 1.0
    countTextScaleLabel:SetText(string.format("Count Text Size: %d%%", currentCountScale * 100))
    y=y-20
    
    local countTextScaleSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    countTextScaleSlider:SetPoint("TOPLEFT",15,y)
    countTextScaleSlider:SetMinMaxValues(0.5, 2.0)
    countTextScaleSlider:SetValueStep(0.05)
    countTextScaleSlider:SetObeyStepOnDrag(true)
    countTextScaleSlider:SetWidth(200)
    countTextScaleSlider.Low:SetText("50%")
    countTextScaleSlider.High:SetText("200%")
    
    local initializingCountScale = true
    countTextScaleSlider:SetScript("OnValueChanged", function(self, value)
      if initializingCountScale then return end
      SetSetting(key,"countTextScale", value)
      countTextScaleLabel:SetText(string.format("Count Text Size: %d%%", value * 100))
      relayoutOne(key)
    end)
    
    countTextScaleSlider:SetValue(currentCountScale)
    initializingCountScale = false
    y=y-40
  end

  -- Only show compact/spacing options for non-bar trackers
  if not isBarTracker then
    -- Compact mode
    local compact=CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
    compact:SetPoint("TOPLEFT",15,y); compact.Text:SetText("Compact mode (touching icons)")
    compact:SetChecked(GetSetting(key,"compactMode") or false)
    compact:SetScript("OnClick", function(self) SetSetting(key,"compactMode", self:GetChecked() and true or false); relayoutOne(key) end)
    y=y-30

    local spInfo=content:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    spInfo:SetPoint("TOPLEFT",15,y); spInfo:SetWidth(360); spInfo:SetJustifyH("LEFT")
    spInfo:SetText("Manual spacing (disabled in compact mode):"); y=y-25

    local hLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    hLabel:SetPoint("TOPLEFT",15,y); hLabel:SetText("Horizontal spacing:")
    local hBox=CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    hBox:SetSize(60,25); hBox:SetPoint("LEFT", hLabel, "RIGHT", 10,0)
    hBox:SetAutoFocus(false); hBox:SetNumeric(false); hBox:SetMaxLetters(4)
    hBox:SetText(tostring(GetSetting(key,"hSpacing") or 2))
    hBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    hBox:SetScript("OnEditFocusLost", function(self) SetSetting(key,"hSpacing", tonumber(self:GetText()) or 2); relayoutOne(key) end)
    y=y-30

    local vLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    vLabel:SetPoint("TOPLEFT",15,y); vLabel:SetText("Vertical spacing:")
    local vBox=CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    vBox:SetSize(60,25); vBox:SetPoint("LEFT", vLabel, "RIGHT", 10,0)
    vBox:SetAutoFocus(false); vBox:SetNumeric(false); vBox:SetMaxLetters(4)
    vBox:SetText(tostring(GetSetting(key,"vSpacing") or 2))
    vBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    vBox:SetScript("OnEditFocusLost", function(self) SetSetting(key,"vSpacing", tonumber(self:GetText()) or 2); relayoutOne(key) end)
    y=y-40
  end

  -- Bar-specific controls
  local trackerInfo = getTrackerInfoByKey(key)
  if trackerInfo and trackerInfo.isBarType then
    local barHeader=content:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    barHeader:SetPoint("TOPLEFT",15,y); barHeader:SetText("Bar Settings")
    barHeader:SetTextColor(1, 0.8, 0); y=y-30

    -- Icon Position
    local iconPosLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    iconPosLabel:SetPoint("TOPLEFT",15,y); iconPosLabel:SetText("Icon Position:")

    local iconPosDD=CreateFrame("Frame", nil, content, "UIDropDownMenuTemplate")
    iconPosDD:SetPoint("LEFT", iconPosLabel, "RIGHT", -10, -5)

    local function iconPosToText(v)
      if v == "LEFT" then return "Left"
      else return "Right" end
    end

    local function SetupIconPos()
      UIDropDownMenu_Initialize(iconPosDD, function()
        local function add(text,val)
          local info=UIDropDownMenu_CreateInfo()
          info.text=text
          info.func=function()
            dprint("CMT: Setting barIconSide to '%s' for key '%s'", val, key)
            SetSetting(key,"barIconSide",val)
            UIDropDownMenu_SetSelectedValue(iconPosDD,val)
            UIDropDownMenu_SetText(iconPosDD, iconPosToText(val))
            dprint("CMT: Saved value is now '%s'", GetSetting(key,"barIconSide") or "nil")
            relayoutOne(key)
          end
          info.checked=(GetSetting(key,"barIconSide") or "LEFT")==val
          UIDropDownMenu_AddButton(info)
        end
        add("Left","LEFT"); add("Right","RIGHT")
      end)

      UIDropDownMenu_SetWidth(iconPosDD,100)
      local cur = GetSetting(key,"barIconSide") or "LEFT"
      UIDropDownMenu_SetSelectedValue(iconPosDD, cur)
      UIDropDownMenu_SetText(iconPosDD, iconPosToText(cur))
    end

    SetupIconPos(); y=y-50

    -- Bar Spacing
    local barSpacingLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    barSpacingLabel:SetPoint("TOPLEFT",15,y); barSpacingLabel:SetText("Bar spacing (vertical):")
    local barSpacingBox=CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    barSpacingBox:SetSize(60,25); barSpacingBox:SetPoint("LEFT", barSpacingLabel, "RIGHT", 10,0)
    barSpacingBox:SetAutoFocus(false); barSpacingBox:SetNumeric(false); barSpacingBox:SetMaxLetters(4)
    barSpacingBox:SetText(tostring(GetSetting(key,"barSpacing") or 2))
    barSpacingBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    barSpacingBox:SetScript("OnEditFocusLost", function(self) SetSetting(key,"barSpacing", tonumber(self:GetText()) or 2); relayoutOne(key) end)
    y=y-30

    -- Icon Gap
    local iconGapLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    iconGapLabel:SetPoint("TOPLEFT",15,y); iconGapLabel:SetText("Icon-bar gap:")
    local iconGapBox=CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    iconGapBox:SetSize(60,25); iconGapBox:SetPoint("LEFT", iconGapLabel, "RIGHT", 10,0)
    iconGapBox:SetAutoFocus(false); iconGapBox:SetNumeric(false); iconGapBox:SetMaxLetters(4)
    iconGapBox:SetText(tostring(GetSetting(key,"barIconGap") or 0))
    iconGapBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    iconGapBox:SetScript("OnEditFocusLost", function(self) SetSetting(key,"barIconGap", tonumber(self:GetText()) or 0); relayoutOne(key) end)
  end

  -- ============================================================
  -- PERSISTENT BUFF DISPLAY SETTINGS (only for buffs tracker)
  -- ============================================================
  -- BUFF ICON STYLING SETTINGS
  -- ============================================================
  -- ============================================================
  -- END BUFF ICON STYLING SETTINGS
  -- ============================================================

  -- ============================================================
  -- INACTIVE BUFF APPEARANCE (only for buffs tracker) (v4.4.0 - moved into scroll)
  -- ============================================================
  if key == "buffs" then
    y = y - 10
    
    -- Separator
    local separator = content:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    separator:SetPoint("TOPLEFT", 15, y)
    separator:SetText("Inactive Buff Appearance")
    separator:SetTextColor(1, 0.82, 0)
    y = y - 25
    
    -- Greyscale checkbox
    local greyscaleCheckbox = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
    greyscaleCheckbox:SetPoint("TOPLEFT", 15, y)
    greyscaleCheckbox.Text:SetText("Greyscale Inactive Buffs")
    greyscaleCheckbox.Text:SetFontObject("GameFontNormal")
    
    local descText = content:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    descText:SetPoint("TOPLEFT", 35, y - 20)
    descText:SetWidth(350)
    descText:SetJustifyH("LEFT")
    descText:SetTextColor(0.7, 0.7, 0.7)
    descText:SetText("Enable persistent buff display with inactive buffs shown as greyscale.")
    
    greyscaleCheckbox:SetScript("OnClick", function(self)
      local enabled = self:GetChecked() and true or false
      SetSetting("buffs", "greyscaleInactive", enabled)
      SetSetting("buffs", "persistentDisplay", enabled)
      
      StaticPopupDialogs["CMT_RELOAD_UI_BUFFS"] = {
        text = "Buff display settings changed. Reload UI for full effect?",
        button1 = "Reload Now",
        button2 = "Later",
        OnAccept = function() ReloadUI() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
      }
      StaticPopup_Show("CMT_RELOAD_UI_BUFFS")
    end)
    
    local persistentEnabled = GetSetting("buffs", "persistentDisplay")
    if persistentEnabled == nil then persistentEnabled = true end
    greyscaleCheckbox:SetChecked(persistentEnabled)
    y = y - 50
    
    -- Inactive Alpha Slider
    local alphaLabel = content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    alphaLabel:SetPoint("TOPLEFT", 15, y)
    local curAlpha = GetSetting("buffs", "inactiveAlpha") or 0.5
    alphaLabel:SetText(string.format("Inactive Buff Opacity: %d%%", curAlpha * 100))
    y = y - 20
    
    local alphaSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    alphaSlider:SetPoint("TOPLEFT", 15, y)
    alphaSlider:SetWidth(200)
    alphaSlider:SetMinMaxValues(0, 100)
    alphaSlider:SetValueStep(5)
    alphaSlider:SetObeyStepOnDrag(true)
    alphaSlider.Low:SetText("0%")
    alphaSlider.High:SetText("100%")
    
    local initAlpha = true
    alphaSlider:SetScript("OnValueChanged", function(self, val)
      if initAlpha then return end
      val = math.floor(val + 0.5)
      alphaLabel:SetText(string.format("Inactive Buff Opacity: %d%%", val))
      SetSetting("buffs", "inactiveAlpha", val / 100)
      if GetSetting("buffs", "persistentDisplay") then
        UpdateAllBuffVisuals(true)
      end
    end)
    
    alphaSlider:SetValue(curAlpha * 100)
    initAlpha = false
    y = y - 40
    
    -- Help text
    local helpText = content:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    helpText:SetPoint("TOPLEFT", 15, y)
    helpText:SetWidth(350)
    helpText:SetJustifyH("LEFT")
    helpText:SetSpacing(2)
    helpText:SetTextColor(0.6, 0.8, 1.0)
    helpText:SetText("How it works:\n• Set Edit Mode to 'Always Show' for buffs\n• Active buffs appear colorized at full opacity\n• Inactive buffs use greyscale and opacity above\n• Per-icon settings in preview can override these")
    y = y - 70
  end

  -- ============================================================
  -- VISIBILITY SETTINGS SECTION (v4.4.0)
  -- ============================================================
  y = CreateVisibilitySection(content, key, y)

  -- ============================================================
  -- ITEMS-SPECIFIC SETTINGS (only for items/Custom Layout tab)
  -- ============================================================
  if key == "items" then
    y = y - 15
    
    -- Separator
    local separator = content:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    separator:SetPoint("TOPLEFT", 15, y)
    separator:SetText("Items-Specific Settings")
    separator:SetTextColor(1, 0.82, 0)  -- Gold color
    y = y - 25
    
    -- Count Font Size
    local countSizeLabel = content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    countSizeLabel:SetPoint("TOPLEFT", 15, y)
    countSizeLabel:SetText("Item Count Font Size:")
    y = y - 20
    
    local countSizeSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    countSizeSlider:SetPoint("TOPLEFT", 15, y)
    countSizeSlider:SetWidth(200)
    countSizeSlider:SetMinMaxValues(8, 24)
    countSizeSlider:SetValueStep(1)
    countSizeSlider:SetObeyStepOnDrag(true)
    
    local countSizeValue = content:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    countSizeValue:SetPoint("LEFT", countSizeSlider, "RIGHT", 10, 0)
    
    countSizeSlider:SetScript("OnValueChanged", function(self, val)
      val = math.floor(val + 0.5)
      countSizeValue:SetText(val .. "px")
      
      -- Save setting
      local profile = GetCurrentProfile()
      if not profile.items then profile.items = {} end
      profile.items.countFontSize = val
      
      -- Update all item icons
      for itemID, iconFrame in pairs(customItemIcons) do
        if iconFrame.count then
          iconFrame.count:SetFont(iconFrame.count:GetFont(), val, "OUTLINE")
        end
      end
    end)
    
    -- Initialize slider
    local profile = GetCurrentProfile()
    local curCountSize = (profile.items and profile.items.countFontSize) or 14
    countSizeSlider:SetValue(curCountSize)
    countSizeValue:SetText(curCountSize .. "px")
    
    y = y - 35
    
    -- Cooldown Text Scale
    local cdSizeLabel = content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    cdSizeLabel:SetPoint("TOPLEFT", 15, y)
    cdSizeLabel:SetText("Cooldown Text Scale:")
    y = y - 20
    
    local cdSizeSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    cdSizeSlider:SetPoint("TOPLEFT", 15, y)
    cdSizeSlider:SetWidth(200)
    cdSizeSlider:SetMinMaxValues(50, 150)
    cdSizeSlider:SetValueStep(5)
    cdSizeSlider:SetObeyStepOnDrag(true)
    
    local cdSizeValue = content:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    cdSizeValue:SetPoint("LEFT", cdSizeSlider, "RIGHT", 10, 0)
    
    cdSizeSlider:SetScript("OnValueChanged", function(self, val)
      val = math.floor(val + 0.5)
      cdSizeValue:SetText(val .. "%")
      
      local scale = val / 100
      
      -- Save setting
      local profile = GetCurrentProfile()
      if not profile.items then profile.items = {} end
      profile.items.cooldownTextScale = scale
      
      -- Update all item cooldown frames
      for itemID, iconFrame in pairs(customItemIcons) do
        if iconFrame.cooldown then
          iconFrame.cooldown:SetScale(scale)
        end
      end
    end)
    
    -- Initialize slider
    local curCdScale = (profile.items and profile.items.cooldownTextScale) or 1.0
    cdSizeSlider:SetValue(curCdScale * 100)
    cdSizeValue:SetText(math.floor(curCdScale * 100 + 0.5) .. "%")
    
    y = y - 40
  end

  -- Set the scroll child height based on content (y is negative, so negate it and add padding)
  content:SetHeight(math.abs(y) + 20)
  
  return container
end

-- --------------------------------------------------------------------
-- Profile Import/Export Windows
-- --------------------------------------------------------------------
local function ShowProfileExportWindow(exportString, profileName)
  local frame = CreateFrame("Frame", "CMT_ExportFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(500, 300)
  frame:SetPoint("CENTER")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetFrameStrata("DIALOG")
  
  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.title:SetPoint("TOP", 0, -5)
  frame.title:SetText("Export Profile: " .. profileName)
  
  local info = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  info:SetPoint("TOPLEFT", 15, -35)
  info:SetText("Copy this string to share your profile:")
  
  local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 10, -55)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 45)
  
  local editBox = CreateFrame("EditBox", nil, scrollFrame)
  editBox:SetMultiLine(true)
  editBox:SetFontObject("ChatFontNormal")
  editBox:SetWidth(scrollFrame:GetWidth())
  editBox:SetText(exportString)
  editBox:SetAutoFocus(false)
  editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
  scrollFrame:SetScrollChild(editBox)
  
  local selectBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  selectBtn:SetSize(100, 22)
  selectBtn:SetPoint("BOTTOMLEFT", 10, 10)
  selectBtn:SetText("Select All")
  selectBtn:SetScript("OnClick", function()
    editBox:SetFocus()
    editBox:HighlightText()
  end)
  
  local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  closeBtn:SetSize(80, 22)
  closeBtn:SetPoint("BOTTOMRIGHT", -10, 10)
  closeBtn:SetText("Close")
  closeBtn:SetScript("OnClick", function() frame:Hide() end)
  
  frame:Show()
end

local function ShowProfileImportWindow()
  local frame = CreateFrame("Frame", "CMT_ImportFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(500, 350)
  frame:SetPoint("CENTER")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetFrameStrata("DIALOG")
  
  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.title:SetPoint("TOP", 0, -5)
  frame.title:SetText("Import Profile")
  
  local info = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  info:SetPoint("TOPLEFT", 15, -35)
  info:SetWidth(470)
  info:SetJustifyH("LEFT")
  info:SetText("Paste a profile string below:")
  
  local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 10, -55)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 95)
  
  local editBox = CreateFrame("EditBox", nil, scrollFrame)
  editBox:SetMultiLine(true)
  editBox:SetFontObject("ChatFontNormal")
  editBox:SetWidth(scrollFrame:GetWidth())
  editBox:SetAutoFocus(true)
  editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
  scrollFrame:SetScrollChild(editBox)
  
  local nameLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  nameLabel:SetPoint("BOTTOMLEFT", 15, 65)
  nameLabel:SetText("Save as:")
  
  local nameBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  nameBox:SetSize(200, 25)
  nameBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
  nameBox:SetAutoFocus(false)
  
  local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  statusText:SetPoint("BOTTOMLEFT", 15, 40)
  statusText:SetPoint("BOTTOMRIGHT", -15, 40)
  statusText:SetJustifyH("LEFT")
  statusText:SetTextColor(1, 0.82, 0) -- Yellow
  
  local importBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  importBtn:SetSize(100, 22)
  importBtn:SetPoint("BOTTOMLEFT", 10, 10)
  importBtn:SetText("Import")
  importBtn:SetScript("OnClick", function()
    local importString = editBox:GetText()
    local profileName = nameBox:GetText()
    
    if not importString or importString == "" then
      statusText:SetTextColor(1, 0, 0)
      statusText:SetText("Error: Please paste a profile string")
      return
    end
    
    if not profileName or profileName == "" then
      statusText:SetTextColor(1, 0, 0)
      statusText:SetText("Error: Please enter a profile name")
      return
    end
    
    if CMT_DB.profiles[profileName] then
      statusText:SetTextColor(1, 0, 0)
      statusText:SetText("Error: Profile '" .. profileName .. "' already exists")
      return
    end
    
    local data, err = deserializeProfile(importString)
    if not data then
      statusText:SetTextColor(1, 0, 0)
      statusText:SetText("Error: " .. (err or "Invalid profile string"))
      return
    end
    
    -- Create new profile with imported data
    CMT_DB.profiles[profileName] = {}
    if data.trackers then
      for key, settings in pairs(data.trackers) do
        CMT_DB.profiles[profileName][key] = deepCopy(settings)
      end
    end
    
    statusText:SetTextColor(0, 1, 0)
    statusText:SetText("Success! Imported profile: " .. profileName)
    print("CMT: Imported profile: " .. profileName)
    
    C_Timer.After(2, function()
      frame:Hide()
    end)
  end)
  
  local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  closeBtn:SetSize(80, 22)
  closeBtn:SetPoint("BOTTOMRIGHT", -10, 10)
  closeBtn:SetText("Close")
  closeBtn:SetScript("OnClick", function() frame:Hide() end)
  
  frame:Show()
  editBox:SetFocus()
end

-- --------------------------------------------------------------------
-- Health Log Window
-- --------------------------------------------------------------------
local function ShowHealthLogWindow()
  if healthFrame and healthFrame:IsShown() then
    healthFrame:Hide()
    return
  end
  
  if healthFrame then
    healthFrame.text:SetText(formatHealthLog())
    healthFrame:Show()
    return
  end
  
  -- Create health log window
  local f = CreateFrame("Frame", "CMT_HealthLogFrame", UIParent, "BasicFrameTemplateWithInset")
  f:SetSize(700, 500)
  f:SetPoint("CENTER")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetFrameStrata("DIALOG")
  
  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  f.title:SetPoint("TOP", 0, -5)
  f.title:SetText("CMT Health Log (Last " .. HEALTH_LOG_MAX .. " entries)")
  
  -- Scroll frame
  local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 10, -30)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 80)
  
  -- Edit box for text
  local editBox = CreateFrame("EditBox", nil, scrollFrame)
  editBox:SetMultiLine(true)
  editBox:SetFontObject(GameFontNormal)
  editBox:SetWidth(650)
  editBox:SetAutoFocus(false)
  editBox:SetScript("OnEscapePressed", function() f:Hide() end)
  scrollFrame:SetScrollChild(editBox)
  
  f.text = editBox
  
  -- Info text
  local info = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  info:SetPoint("BOTTOMLEFT", 15, 45)
  info:SetWidth(650)
  info:SetJustifyH("LEFT")
  info:SetTextColor(0.7, 0.7, 0.7)
  info:SetText("Guardian monitors all trackers every 0.25s and automatically fixes issues. Select all (Ctrl+A) and copy (Ctrl+C) to send to developer.")
  
  -- Refresh button
  local refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  refreshBtn:SetSize(80, 22)
  refreshBtn:SetPoint("BOTTOMRIGHT", -100, 10)
  refreshBtn:SetText("Refresh")
  refreshBtn:SetScript("OnClick", function()
    editBox:SetText(formatHealthLog())
  end)
  
  -- Clear button
  local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  clearBtn:SetSize(80, 22)
  clearBtn:SetPoint("BOTTOMRIGHT", -10, 10)
  clearBtn:SetText("Clear Log")
  clearBtn:SetScript("OnClick", function()
    healthLog = {}
    iconPositions = {}  -- Also clear position tracking
    editBox:SetText("")
    print("CMT: Health log and position tracking cleared")
  end)
  
  -- Close button
  f.CloseButton:SetScript("OnClick", function() f:Hide() end)
  
  -- Initial text
  editBox:SetText(formatHealthLog())
  
  healthFrame = f
  f:Show()
end

-- ============================================================================
-- LIVE PREVIEW SYSTEM (v4.2.0)
-- ============================================================================
-- Integrated preview panel showing real-time layout changes
-- Groundwork for future per-icon adjustment feature

-- Preview area dimensions (right side of expanded config panel)
local PREVIEW_AREA_WIDTH = 500
local PREVIEW_BOX_HEIGHT = 250  -- Dark preview box at top (smaller to give more room to settings)
local PREVIEW_PADDING = 15

local function CreatePreviewIcon(parent, index)
  local icon = CreateFrame("Button", nil, parent, "BackdropTemplate")
  icon:SetSize(40, 40)
  icon:Hide()
  
  -- Background/border
  icon:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  icon:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
  icon:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
  
  -- Icon texture (the actual ability icon)
  icon.texture = icon:CreateTexture(nil, "ARTWORK")
  icon.texture:SetPoint("TOPLEFT", 1, -1)
  icon.texture:SetPoint("BOTTOMRIGHT", -1, 1)
  icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  
  -- Index number (for placeholder mode)
  icon.indexText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  icon.indexText:SetPoint("CENTER")
  icon.indexText:SetTextColor(1, 1, 1, 0.9)
  icon.indexText:Hide()
  
  -- Selection highlight (for future per-icon selection)
  icon.highlight = icon:CreateTexture(nil, "HIGHLIGHT")
  icon.highlight:SetAllPoints()
  icon.highlight:SetColorTexture(1, 0.82, 0, 0.3)
  
  -- Selected indicator (for future per-icon selection)
  icon.selected = icon:CreateTexture(nil, "OVERLAY")
  icon.selected:SetPoint("TOPLEFT", -2, 2)
  icon.selected:SetPoint("BOTTOMRIGHT", 2, -2)
  icon.selected:SetColorTexture(1, 0.82, 0, 0.5)
  icon.selected:Hide()
  
  -- Store references
  icon.previewIndex = index
  icon.sourceIcon = nil
  icon.entry = nil  -- For custom tracker entries
  
  -- Click handler for per-icon selection
  icon:SetScript("OnClick", function(self)
    -- Track selected slot for identification (but don't show highlight)
    previewSelectedSlot = self.slotIndex
    
    -- Get identifier for this icon
    local identifier = nil
    if previewCurrentKey == "items" and self.entry then
      -- Custom tracker: use entry type:id
      identifier = GetIconIdentifier(previewCurrentKey, self.entry)
    elseif self.slotIndex then
      -- Blizzard tracker: use slot position
      identifier = GetIconIdentifier(previewCurrentKey, nil, self.slotIndex)
    end
    
    -- Pass the actual texture from the preview icon
    local iconTexture = self.texture:GetTexture()
    
    -- Refresh the settings panel
    if previewPanel and previewPanel.settingsArea then
      if identifier and previewPanel.settingsArea.RefreshForIcon then
        previewPanel.settingsArea:RefreshForIcon(identifier, self.spellID, self.itemID, self.entry, self.slotIndex, iconTexture)
      end
    end
  end)
  
  -- Tooltip
  icon:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.spellID then
      GameTooltip:SetSpellByID(self.spellID)
    elseif self.itemID then
      GameTooltip:SetItemByID(self.itemID)
    else
      GameTooltip:SetText("Icon " .. (self.previewIndex or "?"))
      GameTooltip:AddLine("Click to select", 0.7, 0.7, 0.7)
    end
    GameTooltip:Show()
  end)
  
  icon:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  
  return icon
end

-- Create the preview area as part of the config panel (right side)
local function CreatePreviewArea(parent)
  -- Container frame for the entire right side
  local previewArea = CreateFrame("Frame", "CMT_PreviewArea", parent)
  previewArea:SetPoint("TOPLEFT", parent, "TOPLEFT", 700, -25)  -- Right side of expanded panel
  previewArea:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)
  
  -- Dark preview box at top
  local previewBox = CreateFrame("Frame", "CMT_PreviewBox", previewArea, "BackdropTemplate")
  previewBox:SetPoint("TOPLEFT", 0, 0)
  previewBox:SetPoint("TOPRIGHT", 0, 0)
  previewBox:SetHeight(PREVIEW_BOX_HEIGHT)
  previewBox:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  previewBox:SetBackdropColor(0.03, 0.03, 0.03, 1)
  previewBox:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
  
  -- Header inside preview box
  previewBox.title = previewBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  previewBox.title:SetPoint("TOPLEFT", 12, -8)
  previewBox.title:SetText("Live Preview")
  previewBox.title:SetTextColor(1, 0.82, 0)
  
  -- Tracker name
  previewBox.subtitle = previewBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  previewBox.subtitle:SetPoint("LEFT", previewBox.title, "RIGHT", 8, 0)
  previewBox.subtitle:SetText("")
  previewBox.subtitle:SetTextColor(0.6, 0.6, 0.6)
  
  -- Icon count
  previewBox.iconCount = previewBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  previewBox.iconCount:SetPoint("TOPRIGHT", -12, -8)
  previewBox.iconCount:SetText("")
  previewBox.iconCount:SetTextColor(0.6, 0.6, 0.6)
  
  -- Scale indicator
  previewBox.scaleText = previewBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  previewBox.scaleText:SetPoint("BOTTOMLEFT", 12, 8)
  previewBox.scaleText:SetText("")
  previewBox.scaleText:SetTextColor(0.5, 0.5, 0.5)
  
  -- Icon container (centered within preview box)
  previewBox.iconContainer = CreateFrame("Frame", nil, previewBox)
  previewBox.iconContainer:SetPoint("TOPLEFT", PREVIEW_PADDING, -30)
  previewBox.iconContainer:SetPoint("BOTTOMRIGHT", -PREVIEW_PADDING, 25)
  
  -- Status text (when no icons)
  previewBox.statusText = previewBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  previewBox.statusText:SetPoint("CENTER", previewBox.iconContainer)
  previewBox.statusText:SetText("Tracker not visible\n\nShow the tracker in-game\nto see live preview\n\n(Using placeholders)")
  previewBox.statusText:SetTextColor(0.4, 0.4, 0.4)
  previewBox.statusText:SetJustifyH("CENTER")
  previewBox.statusText:Hide()
  
  -- Per-icon settings area below preview box
  local settingsArea = CreateFrame("Frame", "CMT_IconSettingsArea", previewArea, "BackdropTemplate")
  settingsArea:SetPoint("TOPLEFT", previewBox, "BOTTOMLEFT", 0, -10)
  settingsArea:SetPoint("BOTTOMRIGHT", 0, 0)
  settingsArea:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  settingsArea:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
  settingsArea:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
  
  -- Pending changes buffer - changes are stored here until Apply is clicked
  settingsArea.pendingChanges = {}
  
  -- Get pending changes for an identifier (merged with saved overrides)
  settingsArea.GetPendingOverride = function(self, trackerKey, identifier)
    local saved = GetIconOverride(trackerKey, identifier)
    local pending = self.pendingChanges[identifier]
    if not pending then return saved end
    
    -- Merge pending on top of saved
    local result = deepCopy(saved)
    for k, v in pairs(pending) do
      if type(v) == "table" then
        result[k] = result[k] or {}
        for k2, v2 in pairs(v) do
          result[k][k2] = v2
        end
      else
        result[k] = v
      end
    end
    return result
  end
  
  -- Commit pending changes to saved profile
  settingsArea.CommitPendingChanges = function(self, trackerKey)
    for identifier, changes in pairs(self.pendingChanges) do
      for property, value in pairs(changes) do
        if type(value) == "table" then
          -- State-specific settings (activeState, inactiveState)
          -- Need to merge with existing state, not replace it!
          local existing = GetIconOverride(trackerKey, identifier)
          local existingState = existing[property] or {}
          
          -- Merge pending state properties into existing state
          local mergedState = {}
          for k, v in pairs(existingState) do
            mergedState[k] = v
          end
          for k, v in pairs(value) do
            mergedState[k] = v
          end
          
          SetIconOverride(trackerKey, identifier, property, mergedState)
        else
          SetIconOverride(trackerKey, identifier, property, value)
        end
      end
    end
    -- Clear pending after commit
    self.pendingChanges = {}
  end
  
  -- Clear pending changes without saving
  settingsArea.ClearPendingChanges = function(self, identifier)
    if identifier then
      self.pendingChanges[identifier] = nil
    else
      self.pendingChanges = {}
    end
  end
  
  -- Settings area header
  settingsArea.header = settingsArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  settingsArea.header:SetPoint("TOPLEFT", 12, -10)
  settingsArea.header:SetText("Per-Icon Settings")
  settingsArea.header:SetTextColor(1, 0.82, 0)
  
  -- Selected icon display
  settingsArea.selectedIcon = CreateFrame("Frame", nil, settingsArea, "BackdropTemplate")
  settingsArea.selectedIcon:SetPoint("TOPLEFT", 12, -32)
  settingsArea.selectedIcon:SetSize(28, 28)
  settingsArea.selectedIcon:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  settingsArea.selectedIcon:SetBackdropColor(0.1, 0.1, 0.1, 1)
  settingsArea.selectedIcon:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
  
  settingsArea.selectedIcon.texture = settingsArea.selectedIcon:CreateTexture(nil, "ARTWORK")
  settingsArea.selectedIcon.texture:SetPoint("TOPLEFT", 1, -1)
  settingsArea.selectedIcon.texture:SetPoint("BOTTOMRIGHT", -1, 1)
  settingsArea.selectedIcon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  
  settingsArea.selectedName = settingsArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  settingsArea.selectedName:SetPoint("LEFT", settingsArea.selectedIcon, "RIGHT", 8, 0)
  settingsArea.selectedName:SetText("No icon selected")
  settingsArea.selectedName:SetTextColor(0.8, 0.8, 0.8)
  settingsArea.selectedName:SetWidth(380)
  settingsArea.selectedName:SetJustifyH("LEFT")
  
  -- Override indicator
  settingsArea.overrideIndicator = settingsArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  settingsArea.overrideIndicator:SetPoint("TOPRIGHT", -12, -10)
  settingsArea.overrideIndicator:SetText("")
  settingsArea.overrideIndicator:SetTextColor(0.5, 0.8, 0.5)
  
  -- Buff state tabs (shown only for buffs tracker)
  settingsArea.buffStateTabs = CreateFrame("Frame", nil, settingsArea)
  settingsArea.buffStateTabs:SetPoint("TOPLEFT", 12, -62)
  settingsArea.buffStateTabs:SetSize(440, 28)
  settingsArea.buffStateTabs:Hide()
  
  local function CreateStateTab(parent, text, xOffset)
    local tab = CreateFrame("Button", nil, parent, "BackdropTemplate")
    tab:SetPoint("TOPLEFT", xOffset, 0)
    tab:SetSize(130, 26)
    tab:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8x8",
      edgeFile = "Interface\\Buttons\\WHITE8x8",
      edgeSize = 1,
    })
    tab:SetBackdropColor(0.15, 0.15, 0.15, 1)
    tab:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tab.text:SetPoint("CENTER")
    tab.text:SetText(text)
    tab.text:SetTextColor(0.7, 0.7, 0.7)
    
    tab.SetSelected = function(self, selected)
      if selected then
        self:SetBackdropColor(0.2, 0.2, 0.25, 1)
        self:SetBackdropBorderColor(1, 0.82, 0, 1)
        self.text:SetTextColor(1, 0.82, 0)
      else
        self:SetBackdropColor(0.15, 0.15, 0.15, 1)
        self:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        self.text:SetTextColor(0.7, 0.7, 0.7)
      end
    end
    
    return tab
  end
  
  settingsArea.buffActiveTab = CreateStateTab(settingsArea.buffStateTabs, "Buff Active", 0)
  settingsArea.buffMissingTab = CreateStateTab(settingsArea.buffStateTabs, "Buff Missing", 140)
  settingsArea.currentBuffState = "active"  -- Track which state we're editing
  
  settingsArea.buffActiveTab:SetSelected(true)
  settingsArea.buffMissingTab:SetSelected(false)
  
  settingsArea.buffActiveTab:SetScript("OnClick", function()
    settingsArea.currentBuffState = "active"
    settingsArea.buffActiveTab:SetSelected(true)
    settingsArea.buffMissingTab:SetSelected(false)
    if settingsArea.RefreshStateControls then
      settingsArea:RefreshStateControls()
    end
    -- Update preview to show active state appearance
    if previewCurrentKey == "buffs" then
      PopulatePreview(previewCurrentKey)
    end
  end)
  
  settingsArea.buffMissingTab:SetScript("OnClick", function()
    settingsArea.currentBuffState = "inactive"
    settingsArea.buffActiveTab:SetSelected(false)
    settingsArea.buffMissingTab:SetSelected(true)
    if settingsArea.RefreshStateControls then
      settingsArea:RefreshStateControls()
    end
    -- Update preview to show inactive/missing state appearance
    if previewCurrentKey == "buffs" then
      PopulatePreview(previewCurrentKey)
    end
  end)
  
  -- Button pane at bottom (always visible when icon selected)
  settingsArea.buttonPane = CreateFrame("Frame", nil, settingsArea, "BackdropTemplate")
  settingsArea.buttonPane:SetPoint("BOTTOMLEFT", 8, 8)
  settingsArea.buttonPane:SetPoint("BOTTOMRIGHT", -8, 8)
  settingsArea.buttonPane:SetHeight(40)
  settingsArea.buttonPane:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  settingsArea.buttonPane:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
  settingsArea.buttonPane:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
  settingsArea.buttonPane:Hide()
  
  settingsArea.resetBtn = CreateFrame("Button", nil, settingsArea.buttonPane, "UIPanelButtonTemplate")
  settingsArea.resetBtn:SetPoint("LEFT", 10, 0)
  settingsArea.resetBtn:SetSize(140, 28)
  settingsArea.resetBtn:SetText("Reset All Overrides")
  settingsArea.resetBtn:SetScript("OnClick", function()
    if settingsArea.currentIdentifier and previewCurrentKey then
      -- Clear both pending and saved overrides
      settingsArea:ClearPendingChanges(settingsArea.currentIdentifier)
      ClearIconOverrides(previewCurrentKey, settingsArea.currentIdentifier)
      -- Pass existing texture from selectedIcon since we already have it displayed
      local existingTexture = settingsArea.selectedIcon.texture:GetTexture()
      settingsArea:RefreshForIcon(settingsArea.currentIdentifier, settingsArea.currentSpellID, settingsArea.currentItemID, settingsArea.currentEntry, settingsArea.currentSlotIndex, existingTexture)
      PopulatePreview(previewCurrentKey)
      relayoutOne(previewCurrentKey)
      
      -- For buffs tracker, force refresh visual states immediately
      if previewCurrentKey == "buffs" and GetSetting("buffs", "persistentDisplay") then
        UpdateAllBuffVisuals(true)  -- Force update to apply reset
      end
    end
  end)
  
  settingsArea.applyBtn = CreateFrame("Button", nil, settingsArea.buttonPane, "UIPanelButtonTemplate")
  settingsArea.applyBtn:SetPoint("RIGHT", -10, 0)
  settingsArea.applyBtn:SetSize(140, 28)
  settingsArea.applyBtn:SetText("Apply to Tracker")
  settingsArea.applyBtn:SetScript("OnClick", function()
    if previewCurrentKey then
      -- Commit pending changes to saved profile
      settingsArea:CommitPendingChanges(previewCurrentKey)
      
      -- Update the live tracker
      relayoutOne(previewCurrentKey)
      
      -- For buffs tracker, force refresh visual states immediately
      if previewCurrentKey == "buffs" and GetSetting("buffs", "persistentDisplay") then
        UpdateAllBuffVisuals(true)  -- Force update to apply changes
      end
      
      -- Update preview to reflect saved values (pending was cleared)
      UpdatePreviewLayout(previewCurrentKey)
    end
  end)
  
  -- Scroll frame for controls (adjusted to leave room for button pane)
  local scrollFrame = CreateFrame("ScrollFrame", nil, settingsArea, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 8, -65)
  scrollFrame:SetPoint("BOTTOMRIGHT", -28, 52)
  
  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetSize(440, 700)  -- Height for controls (increased for timer/count section)
  scrollFrame:SetScrollChild(scrollChild)
  
  settingsArea.scrollFrame = scrollFrame
  settingsArea.controls = scrollChild
  scrollFrame:Hide()
  
  -- Placeholder when no icon selected
  settingsArea.placeholder = settingsArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  settingsArea.placeholder:SetPoint("CENTER", 0, -20)
  settingsArea.placeholder:SetText("Click an icon in the preview above\nto customize its settings")
  settingsArea.placeholder:SetTextColor(0.4, 0.4, 0.4)
  settingsArea.placeholder:SetJustifyH("CENTER")
  
  local controls = scrollChild
  local yOffset = 0
  local ROW_HEIGHT = 30
  local CONTROL_WIDTH = 200
  
  -- Helper: Create label
  local function MakeLabel(text, x, y, color)
    local label = controls:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    label:SetTextColor(color and color[1] or 1, color and color[2] or 0.82, color and color[3] or 0)
    return label
  end
  
  -- Helper: Create checkbox
  local function MakeCheckbox(x, y, labelText, onChange)
    local cb = CreateFrame("CheckButton", nil, controls, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetSize(24, 24)
    cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cb.text:SetText(labelText)
    cb.text:SetTextColor(0.9, 0.9, 0.9)
    cb:SetScript("OnClick", function(self) if onChange then onChange(self:GetChecked()) end end)
    return cb
  end
  
  -- Helper: Create slider
  local function MakeSlider(x, y, width, minV, maxV, step, fmt, onChange)
    local container = CreateFrame("Frame", nil, controls)
    container:SetPoint("TOPLEFT", x, y)
    container:SetSize(width, 35)
    
    container.label = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    container.label:SetPoint("TOPLEFT", 0, 0)
    container.label:SetTextColor(0.9, 0.9, 0.9)
    
    local slider = CreateFrame("Slider", nil, container, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 0, -12)
    slider:SetSize(width - 10, 16)
    slider:SetMinMaxValues(minV, maxV)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.Low:SetText(""); slider.High:SetText(""); slider.Text:SetText("")
    
    slider:SetScript("OnValueChanged", function(self, value)
      value = math.floor(value / step + 0.5) * step
      container.label:SetText(fmt(value))
      if onChange then onChange(value) end
    end)
    
    container.slider = slider
    return container
  end
  
  -- Helper: Create dropdown  
  local function MakeDropdown(x, y, width, options, onChange)
    local dropdown = CreateFrame("Frame", nil, controls, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", x - 16, y)
    UIDropDownMenu_SetWidth(dropdown, width)
    
    dropdown.options = options
    dropdown.onChange = onChange
    dropdown.currentValue = nil
    
    local function InitializeMenu(self, level)
      for _, opt in ipairs(options) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = opt.text
        info.value = opt.value
        info.checked = (dropdown.currentValue == opt.value)
        info.func = function()
          dropdown.currentValue = opt.value
          UIDropDownMenu_SetSelectedValue(dropdown, opt.value)
          UIDropDownMenu_SetText(dropdown, opt.text)
          if onChange then onChange(opt.value) end
        end
        UIDropDownMenu_AddButton(info, level)
      end
    end
    
    UIDropDownMenu_Initialize(dropdown, InitializeMenu)
    
    dropdown.SetValue = function(self, value)
      dropdown.currentValue = value
      UIDropDownMenu_SetSelectedValue(dropdown, value)
      for _, opt in ipairs(options) do
        if opt.value == value then
          UIDropDownMenu_SetText(dropdown, opt.text)
          break
        end
      end
    end
    
    -- Keep Initialize for compatibility but just update value
    dropdown.Initialize = function(self, selectedValue)
      dropdown:SetValue(selectedValue)
    end
    
    return dropdown
  end
  
  -- Helper: Create color buttons row
  local function MakeColorButtons(x, y, onChange)
    local buttons = {}
    local btnX = x
    for i, preset in ipairs(BORDER_COLOR_PRESETS) do
      local btn = CreateFrame("Button", nil, controls, "BackdropTemplate")
      btn:SetPoint("TOPLEFT", btnX, y)
      btn:SetSize(48, 20)
      btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
      })
      if preset.color then
        btn:SetBackdropColor(preset.color[1], preset.color[2], preset.color[3], 1)
      else
        btn:SetBackdropColor(0.25, 0.25, 0.25, 1)
      end
      btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
      
      btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      btn.label:SetPoint("CENTER")
      btn.label:SetText(preset.name)
      if preset.color and (preset.color[1] + preset.color[2] + preset.color[3]) > 2 then
        btn.label:SetTextColor(0, 0, 0)
      else
        btn.label:SetTextColor(1, 1, 1)
      end
      
      btn.presetName = preset.name
      btn:SetScript("OnClick", function(self)
        if onChange then onChange(self.presetName) end
        for _, b in ipairs(buttons) do b:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end
        self:SetBackdropBorderColor(1, 0.82, 0, 1)
      end)
      
      btn.Select = function(self, isSelected)
        if isSelected then
          self:SetBackdropBorderColor(1, 0.82, 0, 1)
        else
          self:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end
      end
      
      table.insert(buttons, btn)
      btnX = btnX + 52
      if i == 4 then btnX = x; y = y - 24 end
    end
    return buttons, y
  end
  
  -- Callback wrapper for settings changes
  local function OnSettingChanged(property, value)
    if not settingsArea.currentIdentifier or not previewCurrentKey then return end
    
    -- Skip saving if we're just refreshing controls (loading values)
    if settingsArea.isRefreshing then return end
    
    -- Store in pending changes (not saved to profile until Apply)
    local identifier = settingsArea.currentIdentifier
    settingsArea.pendingChanges[identifier] = settingsArea.pendingChanges[identifier] or {}
    
    -- For buffs tracker, route ALL settings to the current state
    if previewCurrentKey == "buffs" then
      local stateKey = settingsArea.currentBuffState .. "State"
      settingsArea.pendingChanges[identifier][stateKey] = settingsArea.pendingChanges[identifier][stateKey] or {}
      settingsArea.pendingChanges[identifier][stateKey][property] = value
    else
      -- Non-buffs trackers: save to main override
      settingsArea.pendingChanges[identifier][property] = value
    end
    
    -- Only update preview layout, don't save to profile yet
    UpdatePreviewLayout(previewCurrentKey)
  end
  
  -- ===================== VISIBILITY SECTION =====================
  MakeLabel("Visibility", 0, yOffset)
  yOffset = yOffset - 22
  
  controls.desaturateCB = MakeCheckbox(0, yOffset, "Desaturate (grayscale)", function(checked)
    OnSettingChanged("desaturate", checked)
  end)
  yOffset = yOffset - ROW_HEIGHT - 5
  
  -- ===================== SIZE/APPEARANCE SECTION =====================
  MakeLabel("Size & Appearance", 0, yOffset)
  yOffset = yOffset - 22
  
  -- Size multiplier
  controls.sizeSlider = MakeSlider(0, yOffset, CONTROL_WIDTH, 50, 200, 10, 
    function(v) return string.format("Size: %d%%", v) end,
    function(v) OnSettingChanged("sizeMultiplier", v / 100) end)
  
  controls.sizeReset = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
  controls.sizeReset:SetPoint("LEFT", controls.sizeSlider, "RIGHT", 10, -6)
  controls.sizeReset:SetSize(50, 20)
  controls.sizeReset:SetText("Reset")
  controls.sizeReset:SetScript("OnClick", function()
    controls.sizeSlider.slider:SetValue(100)
    OnSettingChanged("sizeMultiplier", 1.0)
  end)
  yOffset = yOffset - ROW_HEIGHT - 8
  
  -- Opacity (moved up, before nudge)
  controls.opacitySlider = MakeSlider(0, yOffset, CONTROL_WIDTH, 0, 100, 10,
    function(v) return string.format("Opacity: %d%%", v) end,
    function(v) OnSettingChanged("opacity", v / 100) end)
  yOffset = yOffset - ROW_HEIGHT - 8
  
  -- Nudge controls (moved up, before zoom/aspect)
  MakeLabel("Position Nudge", 0, yOffset)
  yOffset = yOffset - 20
  
  -- X offset - full width slider with reset button
  local FULL_WIDTH = 350
  controls.nudgeXSlider = MakeSlider(0, yOffset, FULL_WIDTH, -200, 200, 1,
    function(v) return string.format("X Offset: %d px", v) end,
    function(v) OnSettingChanged("nudgeX", v) end)
  
  controls.nudgeXReset = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
  controls.nudgeXReset:SetPoint("LEFT", controls.nudgeXSlider, "RIGHT", 10, -6)
  controls.nudgeXReset:SetSize(40, 20)
  controls.nudgeXReset:SetText("0")
  controls.nudgeXReset:SetScript("OnClick", function()
    controls.nudgeXSlider.slider:SetValue(0)
    OnSettingChanged("nudgeX", 0)
  end)
  yOffset = yOffset - ROW_HEIGHT - 5
  
  -- Y offset - full width slider with reset button (positive = up, negative = down)
  controls.nudgeYSlider = MakeSlider(0, yOffset, FULL_WIDTH, -200, 200, 1,
    function(v) return string.format("Y Offset: %d px", v) end,
    function(v) OnSettingChanged("nudgeY", -v) end)  -- Negate so positive = up
  
  controls.nudgeYReset = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
  controls.nudgeYReset:SetPoint("LEFT", controls.nudgeYSlider, "RIGHT", 10, -6)
  controls.nudgeYReset:SetSize(40, 20)
  controls.nudgeYReset:SetText("0")
  controls.nudgeYReset:SetScript("OnClick", function()
    controls.nudgeYSlider.slider:SetValue(0)
    OnSettingChanged("nudgeY", 0)
  end)
  yOffset = yOffset - ROW_HEIGHT - 10
  
  -- Zoom override
  controls.zoomDefaultCB = MakeCheckbox(0, yOffset, "Use tracker zoom", function(checked)
    if checked then
      OnSettingChanged("zoomOverride", nil)
      controls.zoomSlider:Hide()
    else
      controls.zoomSlider:Show()
      local current = GetSetting(previewCurrentKey, "zoom") or 1.0
      controls.zoomSlider.slider:SetValue(current * 100)
      OnSettingChanged("zoomOverride", current)
    end
  end)
  controls.zoomDefaultCB:SetChecked(true)
  
  controls.zoomSlider = MakeSlider(0, yOffset - 25, CONTROL_WIDTH, 100, 300, 10,
    function(v) return string.format("Zoom: %d%%", v) end,
    function(v) OnSettingChanged("zoomOverride", v / 100) end)
  controls.zoomSlider:Hide()
  yOffset = yOffset - ROW_HEIGHT - 30
  
  -- Aspect ratio override
  controls.aspectDefaultCB = MakeCheckbox(0, yOffset, "Use tracker aspect ratio", function(checked)
    if checked then
      OnSettingChanged("aspectOverride", nil)
      controls.aspectDropdown:Hide()
      controls.customAspectInputs:Hide()
    else
      controls.aspectDropdown:Show()
      local current = GetSetting(previewCurrentKey, "aspectRatio") or "1:1"
      controls.aspectDropdown:SetValue(current)
      OnSettingChanged("aspectOverride", current)
    end
  end)
  controls.aspectDefaultCB:SetChecked(true)
  
  local aspectOptions = {
    { text = "1:1 Square", value = "1:1" },
    { text = "16:9 Wide", value = "16:9" },
    { text = "9:16 Tall", value = "9:16" },
    { text = "21:9 Ultra", value = "21:9" },
    { text = "4:3", value = "4:3" },
    { text = "3:4", value = "3:4" },
    { text = "Custom...", value = "custom" },
  }
  controls.aspectDropdown = MakeDropdown(0, yOffset - 25, 120, aspectOptions, function(v)
    if v == "custom" then
      controls.customAspectInputs:Show()
      -- Don't apply yet - wait for user to click Apply
    else
      controls.customAspectInputs:Hide()
      OnSettingChanged("aspectOverride", v)
    end
  end)
  controls.aspectDropdown:Hide()
  
  -- Custom aspect input container for per-icon override - positioned to the RIGHT of dropdown
  controls.customAspectInputs = CreateFrame("Frame", nil, controls)
  controls.customAspectInputs:SetPoint("LEFT", controls.aspectDropdown, "RIGHT", -10, 0)
  controls.customAspectInputs:SetSize(180, 25)
  controls.customAspectInputs:Hide()
  
  local perIconWidthLabel = controls.customAspectInputs:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  perIconWidthLabel:SetPoint("LEFT", 0, 0)
  perIconWidthLabel:SetText("W:")
  
  controls.customAspectW = CreateFrame("EditBox", nil, controls.customAspectInputs, "InputBoxTemplate")
  controls.customAspectW:SetPoint("LEFT", perIconWidthLabel, "RIGHT", 2, 0)
  controls.customAspectW:SetSize(35, 18)
  controls.customAspectW:SetAutoFocus(false)
  controls.customAspectW:SetNumeric(true)
  controls.customAspectW:SetMaxLetters(3)
  controls.customAspectW:SetText("40")
  
  local perIconHeightLabel = controls.customAspectInputs:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  perIconHeightLabel:SetPoint("LEFT", controls.customAspectW, "RIGHT", 6, 0)
  perIconHeightLabel:SetText("H:")
  
  controls.customAspectH = CreateFrame("EditBox", nil, controls.customAspectInputs, "InputBoxTemplate")
  controls.customAspectH:SetPoint("LEFT", perIconHeightLabel, "RIGHT", 2, 0)
  controls.customAspectH:SetSize(35, 18)
  controls.customAspectH:SetAutoFocus(false)
  controls.customAspectH:SetNumeric(true)
  controls.customAspectH:SetMaxLetters(3)
  controls.customAspectH:SetText("40")
  
  local perIconApplyBtn = CreateFrame("Button", nil, controls.customAspectInputs, "UIPanelButtonTemplate")
  perIconApplyBtn:SetPoint("LEFT", controls.customAspectH, "RIGHT", 5, 0)
  perIconApplyBtn:SetSize(40, 18)
  perIconApplyBtn:SetText("Set")
  perIconApplyBtn:SetScript("OnClick", function()
    local w = tonumber(controls.customAspectW:GetText()) or 40
    local h = tonumber(controls.customAspectH:GetText()) or 40
    w = math.max(10, math.min(200, w))
    h = math.max(10, math.min(200, h))
    local customValue = FormatCustomAspectRatio(w, h)
    OnSettingChanged("aspectOverride", customValue)
  end)
  
  controls.customAspectW:SetScript("OnEnterPressed", function() perIconApplyBtn:Click() end)
  controls.customAspectH:SetScript("OnEnterPressed", function() perIconApplyBtn:Click() end)
  
  yOffset = yOffset - ROW_HEIGHT - 30
  
  -- Border section header
  MakeLabel("Custom Border", 0, yOffset)
  yOffset = yOffset - 22
  
  -- Enable custom border checkbox
  controls.borderEnabledCB = MakeCheckbox(0, yOffset, "Add custom border to this icon", function(checked)
    if checked then
      controls.borderWidthSlider:Show()
      controls.borderAlphaSlider:Show()
      controls.borderColorContainer:Show()
      -- Set defaults if not already set
      local currentWidth = controls.borderWidthSlider.slider:GetValue()
      local currentAlpha = controls.borderAlphaSlider.slider:GetValue()
      OnSettingChanged("borderWidth", currentWidth)
      OnSettingChanged("borderAlpha", currentAlpha / 100)
      OnSettingChanged("borderColor", "White")  -- Default to white border
    else
      controls.borderWidthSlider:Hide()
      controls.borderAlphaSlider:Hide()
      controls.borderColorContainer:Hide()
      OnSettingChanged("borderWidth", nil)
      OnSettingChanged("borderAlpha", nil)
      OnSettingChanged("borderColor", nil)
    end
  end)
  yOffset = yOffset - ROW_HEIGHT
  
  -- Border width slider
  controls.borderWidthSlider = MakeSlider(0, yOffset, CONTROL_WIDTH, 1, 6, 1,
    function(v) return string.format("Border Width: %d px", v) end,
    function(v) OnSettingChanged("borderWidth", v) end)
  controls.borderWidthSlider.slider:SetValue(2)
  controls.borderWidthSlider:Hide()
  yOffset = yOffset - ROW_HEIGHT - 8
  
  -- Border alpha slider
  controls.borderAlphaSlider = MakeSlider(0, yOffset, CONTROL_WIDTH, 10, 100, 10,
    function(v) return string.format("Border Opacity: %d%%", v) end,
    function(v) OnSettingChanged("borderAlpha", v / 100) end)
  controls.borderAlphaSlider.slider:SetValue(100)
  controls.borderAlphaSlider:Hide()
  yOffset = yOffset - ROW_HEIGHT - 10
  
  -- Border color container
  controls.borderColorContainer = CreateFrame("Frame", nil, controls)
  controls.borderColorContainer:SetPoint("TOPLEFT", 0, yOffset)
  controls.borderColorContainer:SetSize(440, 70)
  controls.borderColorContainer:Hide()
  
  local borderLabel = controls.borderColorContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  borderLabel:SetPoint("TOPLEFT", 0, 0)
  borderLabel:SetText("Border Color:")
  borderLabel:SetTextColor(0.9, 0.9, 0.9)
  
  -- Create color buttons inside container
  local colorBtnY = -18
  local colorBtnX = 0
  controls.colorButtons = {}
  for i, preset in ipairs(BORDER_COLOR_PRESETS) do
    local btn = CreateFrame("Button", nil, controls.borderColorContainer, "BackdropTemplate")
    btn:SetPoint("TOPLEFT", colorBtnX, colorBtnY)
    btn:SetSize(48, 20)
    btn:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8x8",
      edgeFile = "Interface\\Buttons\\WHITE8x8",
      edgeSize = 1,
    })
    if preset.color then
      btn:SetBackdropColor(preset.color[1], preset.color[2], preset.color[3], 1)
    else
      btn:SetBackdropColor(0.25, 0.25, 0.25, 1)
    end
    btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.label:SetPoint("CENTER")
    btn.label:SetText(preset.name)
    if preset.color and (preset.color[1] + preset.color[2] + preset.color[3]) > 2 then
      btn.label:SetTextColor(0, 0, 0)
    else
      btn.label:SetTextColor(1, 1, 1)
    end
    
    btn.presetName = preset.name
    btn:SetScript("OnClick", function(self)
      OnSettingChanged("borderColor", self.presetName == "Default" and nil or self.presetName)
      for _, b in ipairs(controls.colorButtons) do b:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end
      self:SetBackdropBorderColor(1, 0.82, 0, 1)
    end)
    
    table.insert(controls.colorButtons, btn)
    colorBtnX = colorBtnX + 52
    if i == 4 then colorBtnX = 0; colorBtnY = colorBtnY - 24 end
  end
  yOffset = yOffset - 70
  
  -- ===================== TIMER & COUNT TEXT SECTION =====================
  MakeLabel("Timer & Count Text", 0, yOffset)
  yOffset = yOffset - 22
  
  -- Timer text scale
  controls.timerScaleSlider = MakeSlider(0, yOffset, CONTROL_WIDTH, 50, 200, 10,
    function(v) return string.format("Timer Size: %d%%", v) end,
    function(v) OnSettingChanged("timerScale", v / 100) end)
  controls.timerScaleSlider.slider:SetValue(100)
  
  controls.timerScaleReset = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
  controls.timerScaleReset:SetPoint("LEFT", controls.timerScaleSlider, "RIGHT", 10, -6)
  controls.timerScaleReset:SetSize(50, 20)
  controls.timerScaleReset:SetText("Reset")
  controls.timerScaleReset:SetScript("OnClick", function()
    controls.timerScaleSlider.slider:SetValue(100)
    OnSettingChanged("timerScale", nil)
  end)
  yOffset = yOffset - ROW_HEIGHT - 8
  
  -- Timer color selection
  local timerColorLabel = controls:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  timerColorLabel:SetPoint("TOPLEFT", 0, yOffset)
  timerColorLabel:SetText("Timer Color:")
  timerColorLabel:SetTextColor(0.9, 0.9, 0.9)
  
  local TEXT_COLOR_PRESETS = {
    { name = "Default", color = nil },
    { name = "White", color = {1, 1, 1} },
    { name = "Yellow", color = {1, 0.82, 0} },
    { name = "Red", color = {1, 0.3, 0.3} },
    { name = "Green", color = {0.3, 1, 0.3} },
    { name = "Blue", color = {0.3, 0.7, 1} },
    { name = "Orange", color = {1, 0.5, 0} },
    { name = "Purple", color = {0.8, 0.4, 1} },
  }
  
  local timerColorBtnX = 0
  local timerColorBtnY = yOffset - 18
  controls.timerColorButtons = {}
  for i, preset in ipairs(TEXT_COLOR_PRESETS) do
    local btn = CreateFrame("Button", nil, controls, "BackdropTemplate")
    btn:SetPoint("TOPLEFT", timerColorBtnX, timerColorBtnY)
    btn:SetSize(48, 20)
    btn:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8x8",
      edgeFile = "Interface\\Buttons\\WHITE8x8",
      edgeSize = 1,
    })
    if preset.color then
      btn:SetBackdropColor(preset.color[1], preset.color[2], preset.color[3], 1)
    else
      btn:SetBackdropColor(0.25, 0.25, 0.25, 1)
    end
    btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.label:SetPoint("CENTER")
    btn.label:SetText(preset.name)
    if preset.color and (preset.color[1] + preset.color[2] + preset.color[3]) > 2 then
      btn.label:SetTextColor(0, 0, 0)
    else
      btn.label:SetTextColor(1, 1, 1)
    end
    
    btn.presetName = preset.name
    btn.presetColor = preset.color
    btn:SetScript("OnClick", function(self)
      OnSettingChanged("timerColor", self.presetColor)
      for _, b in ipairs(controls.timerColorButtons) do b:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end
      self:SetBackdropBorderColor(1, 0.82, 0, 1)
    end)
    
    table.insert(controls.timerColorButtons, btn)
    timerColorBtnX = timerColorBtnX + 52
    if i == 4 then timerColorBtnX = 0; timerColorBtnY = timerColorBtnY - 24 end
  end
  yOffset = yOffset - 70
  
  -- Count text scale
  controls.countScaleSlider = MakeSlider(0, yOffset, CONTROL_WIDTH, 50, 200, 10,
    function(v) return string.format("Count Size: %d%%", v) end,
    function(v) OnSettingChanged("countScale", v / 100) end)
  controls.countScaleSlider.slider:SetValue(100)
  
  controls.countScaleReset = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
  controls.countScaleReset:SetPoint("LEFT", controls.countScaleSlider, "RIGHT", 10, -6)
  controls.countScaleReset:SetSize(50, 20)
  controls.countScaleReset:SetText("Reset")
  controls.countScaleReset:SetScript("OnClick", function()
    controls.countScaleSlider.slider:SetValue(100)
    OnSettingChanged("countScale", nil)
  end)
  yOffset = yOffset - ROW_HEIGHT - 8
  
  -- Count color selection
  local countColorLabel = controls:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  countColorLabel:SetPoint("TOPLEFT", 0, yOffset)
  countColorLabel:SetText("Count Color:")
  countColorLabel:SetTextColor(0.9, 0.9, 0.9)
  
  local countColorBtnX = 0
  local countColorBtnY = yOffset - 18
  controls.countColorButtons = {}
  for i, preset in ipairs(TEXT_COLOR_PRESETS) do
    local btn = CreateFrame("Button", nil, controls, "BackdropTemplate")
    btn:SetPoint("TOPLEFT", countColorBtnX, countColorBtnY)
    btn:SetSize(48, 20)
    btn:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8x8",
      edgeFile = "Interface\\Buttons\\WHITE8x8",
      edgeSize = 1,
    })
    if preset.color then
      btn:SetBackdropColor(preset.color[1], preset.color[2], preset.color[3], 1)
    else
      btn:SetBackdropColor(0.25, 0.25, 0.25, 1)
    end
    btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.label:SetPoint("CENTER")
    btn.label:SetText(preset.name)
    if preset.color and (preset.color[1] + preset.color[2] + preset.color[3]) > 2 then
      btn.label:SetTextColor(0, 0, 0)
    else
      btn.label:SetTextColor(1, 1, 1)
    end
    
    btn.presetName = preset.name
    btn.presetColor = preset.color
    btn:SetScript("OnClick", function(self)
      OnSettingChanged("countColor", self.presetColor)
      for _, b in ipairs(controls.countColorButtons) do b:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end
      self:SetBackdropBorderColor(1, 0.82, 0, 1)
    end)
    
    table.insert(controls.countColorButtons, btn)
    countColorBtnX = countColorBtnX + 52
    if i == 4 then countColorBtnX = 0; countColorBtnY = countColorBtnY - 24 end
  end
  yOffset = yOffset - 70
  
  -- Initialize dropdown
  controls.aspectDropdown:Initialize("1:1")
  
  -- Function to refresh all controls from current state (for buffs) or main override
  settingsArea.RefreshStateControls = function(self)
    if not self.currentIdentifier or not previewCurrentKey then return end
    
    -- Prevent OnSettingChanged from saving while we're loading values
    self.isRefreshing = true
    
    -- Use GetPendingOverride to show pending (unsaved) changes in controls
    local override = self:GetPendingOverride(previewCurrentKey, self.currentIdentifier)
    local settings
    local isSimulatingMissing = false
    
    -- For buffs, load from current state; otherwise load from main override
    if previewCurrentKey == "buffs" then
      local stateKey = settingsArea.currentBuffState .. "State"
      settings = override[stateKey] or {}
      isSimulatingMissing = (settingsArea.currentBuffState == "inactive")
    else
      settings = override
    end
    
    -- Desaturate - inherit from global greyscaleInactive if not explicitly set
    local desaturateValue = settings.desaturate
    if desaturateValue == nil then
      if isSimulatingMissing then
        local globalGreyscale = GetSetting("buffs", "greyscaleInactive")
        if globalGreyscale == nil then globalGreyscale = true end
        desaturateValue = globalGreyscale
      else
        desaturateValue = false
      end
    end
    controls.desaturateCB:SetChecked(desaturateValue)
    
    -- Size
    controls.sizeSlider.slider:SetValue((settings.sizeMultiplier or 1.0) * 100)
    
    -- Opacity - inherit from global inactiveAlpha if not set and buff is inactive
    local opacityValue = settings.opacity
    if opacityValue == nil then
      if isSimulatingMissing then
        opacityValue = GetSetting("buffs", "inactiveAlpha") or 0.5
      else
        opacityValue = 1.0
      end
    end
    controls.opacitySlider.slider:SetValue(opacityValue * 100)
    
    -- Nudge
    controls.nudgeXSlider.slider:SetValue(settings.nudgeX or 0)
    controls.nudgeYSlider.slider:SetValue(-(settings.nudgeY or 0))  -- Negate so positive = up
    
    -- Zoom
    if settings.zoomOverride then
      controls.zoomDefaultCB:SetChecked(false)
      controls.zoomSlider:Show()
      controls.zoomSlider.slider:SetValue(settings.zoomOverride * 100)
    else
      controls.zoomDefaultCB:SetChecked(true)
      controls.zoomSlider:Hide()
    end
    
    -- Aspect
    if settings.aspectOverride then
      controls.aspectDefaultCB:SetChecked(false)
      controls.aspectDropdown:Show()
      -- Check if it's a custom aspect ratio
      if IsCustomAspectRatio(settings.aspectOverride) then
        local w, h = ParseAspectRatio(settings.aspectOverride)
        controls.aspectDropdown:SetValue("custom")
        controls.customAspectInputs:Show()
        controls.customAspectW:SetText(tostring(w))
        controls.customAspectH:SetText(tostring(h))
      else
        controls.aspectDropdown:SetValue(settings.aspectOverride)
        controls.customAspectInputs:Hide()
      end
    else
      controls.aspectDefaultCB:SetChecked(true)
      controls.aspectDropdown:Hide()
      controls.customAspectInputs:Hide()
    end
    
    -- Custom border
    local hasBorder = settings.borderColor ~= nil or settings.borderWidth ~= nil
    controls.borderEnabledCB:SetChecked(hasBorder)
    if hasBorder then
      controls.borderWidthSlider:Show()
      controls.borderAlphaSlider:Show()
      controls.borderColorContainer:Show()
      controls.borderWidthSlider.slider:SetValue(settings.borderWidth or 2)
      controls.borderAlphaSlider.slider:SetValue((settings.borderAlpha or 1.0) * 100)
    else
      controls.borderWidthSlider:Hide()
      controls.borderAlphaSlider:Hide()
      controls.borderColorContainer:Hide()
    end
    
    -- Border color selection
    local borderColor = settings.borderColor or "White"
    for _, btn in ipairs(controls.colorButtons) do
      if btn.presetName == borderColor then
        btn:SetBackdropBorderColor(1, 0.82, 0, 1)
      else
        btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
      end
    end
    
    -- Timer scale
    controls.timerScaleSlider.slider:SetValue((settings.timerScale or 1.0) * 100)
    
    -- Timer color selection
    local timerColor = settings.timerColor
    for _, btn in ipairs(controls.timerColorButtons) do
      local matches = false
      if timerColor == nil and btn.presetColor == nil then
        matches = true
      elseif timerColor and btn.presetColor then
        matches = (timerColor[1] == btn.presetColor[1] and timerColor[2] == btn.presetColor[2] and timerColor[3] == btn.presetColor[3])
      end
      if matches then
        btn:SetBackdropBorderColor(1, 0.82, 0, 1)
      else
        btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
      end
    end
    
    -- Count scale
    controls.countScaleSlider.slider:SetValue((settings.countScale or 1.0) * 100)
    
    -- Count color selection
    local countColor = settings.countColor
    for _, btn in ipairs(controls.countColorButtons) do
      local matches = false
      if countColor == nil and btn.presetColor == nil then
        matches = true
      elseif countColor and btn.presetColor then
        matches = (countColor[1] == btn.presetColor[1] and countColor[2] == btn.presetColor[2] and countColor[3] == btn.presetColor[3])
      end
      if matches then
        btn:SetBackdropBorderColor(1, 0.82, 0, 1)
      else
        btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
      end
    end
    
    -- Done refreshing, allow saves again
    self.isRefreshing = false
  end
  
  -- Main refresh function for selected icon
  settingsArea.RefreshForIcon = function(self, identifier, spellID, itemID, entry, slotIndex, passedTexture)
    local previousIdentifier = self.currentIdentifier
    self.currentIdentifier = identifier
    self.currentSpellID = spellID
    self.currentItemID = itemID
    self.currentEntry = entry
    self.currentSlotIndex = slotIndex
    
    if not identifier then
      self.placeholder:Show()
      self.scrollFrame:Hide()
      self.buttonPane:Hide()
      self.buffStateTabs:Hide()
      self.selectedIcon.texture:SetTexture(nil)
      self.selectedName:SetText("No icon selected")
      self.overrideIndicator:SetText("")
      return
    end
    
    -- Track if this is a new icon selection or just a refresh
    local isNewSelection = (previousIdentifier ~= identifier)
    
    self.placeholder:Hide()
    self.scrollFrame:Show()
    
    -- Set icon texture and name
    local iconName = "Unknown"
    local iconTexture = passedTexture  -- Use passed texture first
    
    -- For Blizzard trackers (slot-based)
    if slotIndex and previewCurrentKey ~= "items" then
      iconName = "Slot " .. slotIndex
      -- If we have a spell showing in this slot, add its name
      if spellID then
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
          iconName = "Slot " .. slotIndex .. " - " .. spellInfo.name
          if not iconTexture then iconTexture = spellInfo.iconID end
        end
      end
    elseif spellID then
      local spellInfo = C_Spell.GetSpellInfo(spellID)
      if spellInfo then
        iconName = spellInfo.name
        if not iconTexture then iconTexture = spellInfo.iconID end
      end
    elseif itemID then
      local itemName = C_Item.GetItemNameByID(itemID)
      iconName = itemName or ("Item " .. itemID)
      if not iconTexture then iconTexture = C_Item.GetItemIconByID(itemID) end
    elseif entry then
      if entry.type == "spell" then
        local spellInfo = C_Spell.GetSpellInfo(entry.id)
        if spellInfo then
          iconName = spellInfo.name
          if not iconTexture then iconTexture = spellInfo.iconID end
        end
      elseif entry.type == "item" then
        local itemName = C_Item.GetItemNameByID(entry.id)
        iconName = itemName or ("Item " .. entry.id)
        if not iconTexture then iconTexture = C_Item.GetItemIconByID(entry.id) end
      end
    end
    
    self.selectedIcon.texture:SetTexture(iconTexture)
    self.selectedName:SetText(iconName)
    
    -- Show override indicator
    if HasIconOverrides(previewCurrentKey, identifier) then
      self.overrideIndicator:SetText("(has overrides)")
    else
      self.overrideIndicator:SetText("")
    end
    
    -- Show button pane when icon is selected
    settingsArea.buttonPane:Show()
    
    -- Show/hide buff state tabs, adjust scroll frame
    if previewCurrentKey == "buffs" then
      settingsArea.buffStateTabs:Show()
      settingsArea.scrollFrame:SetPoint("TOPLEFT", 8, -95)  -- Lower to make room for tabs
      -- Only reset to Active tab when selecting a DIFFERENT icon
      if isNewSelection then
        settingsArea.currentBuffState = "active"
        settingsArea.buffActiveTab:SetSelected(true)
        settingsArea.buffMissingTab:SetSelected(false)
      end
    else
      settingsArea.buffStateTabs:Hide()
      settingsArea.scrollFrame:SetPoint("TOPLEFT", 8, -65)  -- Normal position
    end
    
    -- Load all settings (handles both buffs state-based and regular)
    self:RefreshStateControls()
  end
  
  -- Store references
  previewArea.previewBox = previewBox
  previewArea.settingsArea = settingsArea
  
  -- Create icon pool in the preview box
  for i = 1, PREVIEW_ICON_POOL_SIZE do
    previewIcons[i] = CreatePreviewIcon(previewBox.iconContainer, i)
  end
  
  return previewArea
end

-- Hide all preview icons and reset state
-- Note: Does NOT reset previewSelectedSlot - that persists across repopulates
local function ClearPreview()
  for i = 1, PREVIEW_ICON_POOL_SIZE do
    if previewIcons[i] then
      previewIcons[i]:Hide()
      previewIcons[i].texture:SetTexture(nil)
      previewIcons[i].texture:SetVertexColor(1, 1, 1, 1)
      previewIcons[i].texture:SetAlpha(1)
      previewIcons[i].texture:SetDesaturated(false)
      previewIcons[i].indexText:Hide()
      previewIcons[i].selected:Hide()
      previewIcons[i].sourceIcon = nil
      previewIcons[i].spellID = nil
      previewIcons[i].itemID = nil
      previewIcons[i].entry = nil
      previewIcons[i].slotIndex = nil
      if previewIcons[i].customBorder then
        previewIcons[i].customBorder:Hide()
      end
    end
  end
  if previewPanel and previewPanel.previewBox and previewPanel.previewBox.statusText then
    previewPanel.previewBox.statusText:Hide()
  end
end

-- Populate preview icons - using EXACT same order as layoutCustomGrid
PopulatePreview = function(key)
  if not previewPanel then return end
  
  ClearPreview()
  previewCurrentKey = key
  
  local previewBox = previewPanel.previewBox
  if not previewBox then return end
  
  -- Update subtitle with Masque indicator if active
  local trackerInfo = getTrackerInfoByKey(key)
  if trackerInfo then
    local masqueActive = MasqueModule and MasqueModule.ControlsVisualsForTracker and MasqueModule.ControlsVisualsForTracker(key)
    if masqueActive then
      previewBox.subtitle:SetText("- " .. trackerInfo.displayName .. "\n|cff88ff88(Masque active - spacing may vary, check actual tracker)|r")
    else
      previewBox.subtitle:SetText("- " .. trackerInfo.displayName)
    end
  end
  
  local iconDataList = {}
  local hasRealIcons = false
  
  -- Handle Items tracker (CMT-owned)
  if key == "items" then
    local entries = GetCurrentSpecEntries and GetCurrentSpecEntries() or {}
    for i, entry in ipairs(entries) do
      if i <= PREVIEW_ICON_POOL_SIZE then
        local texture = nil
        local itemID, spellID = nil, nil
        
        if entry.type == "item" then
          itemID = entry.id
          -- Try cache first, then use C_Item API as fallback
          local cache = CMT_CharDB.itemCache and CMT_CharDB.itemCache[entry.id]
          if cache and cache.texture then 
            texture = cache.texture 
          elseif C_Item and C_Item.GetItemIconByID then
            texture = C_Item.GetItemIconByID(entry.id)
          end
        elseif entry.type == "spell" then
          spellID = entry.id
          local spellInfo = C_Spell.GetSpellInfo(entry.id)
          if spellInfo then texture = spellInfo.iconID end
        end
        
        table.insert(iconDataList, {
          texture = texture,
          index = i,
          spellID = spellID,
          itemID = itemID,
          sourceIcon = nil,
          entry = entry  -- Store full entry for Custom Tracker
        })
        if texture then hasRealIcons = true end
      end
    end
  else
    -- Blizzard trackers - collect current visible icons fresh
    local viewerName = getTrackerNameByKey(key)
    local viewer = viewerName and _G[viewerName]
    
    if viewer and viewer:IsShown() then
      -- Collect icons fresh from the viewer (same as collectIcons does)
      local allIcons = collectIcons(viewer)
      
      -- Filter to only shown icons
      local shownIcons = {}
      for _, icon in ipairs(allIcons) do
        if icon:IsShown() then
          table.insert(shownIcons, icon)
        end
      end
      
      -- Sort by visual position to get consistent order
      -- BUT prefer stored slot index if available (accounts for nudged icons)
      table.sort(shownIcons, function(a, b)
        -- If both icons have slot indices, use those for stable ordering
        if a._CMT_slotIndex and b._CMT_slotIndex then
          return a._CMT_slotIndex < b._CMT_slotIndex
        end
        -- Fall back to visual position for initial ordering
        local at, bt = a:GetTop() or 0, b:GetTop() or 0
        local al, bl = a:GetLeft() or 0, b:GetLeft() or 0
        if math.abs(at - bt) > 5 then return at > bt end
        return al < bl
      end)
      
      -- Apply reverseOrder if enabled (SAME as live tracker)
      local reverseOrderSetting = key ~= "buffs" and GetSetting(key, "reverseOrder") or false
      local ordered = shownIcons
      if reverseOrderSetting and #shownIcons > 0 then
        ordered = {}
        for i = #shownIcons, 1, -1 do
          table.insert(ordered, shownIcons[i])
        end
      end
      
      if #ordered > 0 then
        hasRealIcons = true
        for i, icon in ipairs(ordered) do
          if i <= PREVIEW_ICON_POOL_SIZE then
            local texture = nil
            local spellID = icon.spellID
            
            if icon.Icon and icon.Icon.GetTexture then
              local success, tex = pcall(function() return icon.Icon:GetTexture() end)
              if success and tex then texture = tex end
            end
            
            table.insert(iconDataList, {
              texture = texture,
              index = i,
              spellID = spellID,
              itemID = nil,
              sourceIcon = icon
            })
          end
        end
      end
    end
  end
  
  -- Fallback: placeholders based on pattern
  if #iconDataList == 0 then
    local pattern = GetSetting(key, "rowPattern") or {1,3,4,3}
    local totalIcons = 0
    for _, count in ipairs(pattern) do
      totalIcons = totalIcons + count
    end
    totalIcons = math.min(totalIcons, PREVIEW_ICON_POOL_SIZE)
    
    for i = 1, totalIcons do
      table.insert(iconDataList, {
        texture = nil,
        index = i,
        isPlaceholder = true
      })
    end
    
    previewBox.statusText:Show()
  end
  
  -- Update icon count
  previewBox.iconCount:SetText(#iconDataList .. " icons")
  
  -- Apply to preview icons
  for i, data in ipairs(iconDataList) do
    local previewIcon = previewIcons[i]
    if previewIcon then
      previewIcon.sourceIcon = data.sourceIcon
      previewIcon.spellID = data.spellID
      previewIcon.itemID = data.itemID
      previewIcon.entry = data.entry  -- Store entry for Custom Tracker
      previewIcon.slotIndex = data.index  -- Store slot position for Blizzard trackers
      
      if data.texture then
        previewIcon.texture:SetTexture(data.texture)
        previewIcon.texture:SetVertexColor(1, 1, 1, 1)
        previewIcon.indexText:Hide()
      else
        previewIcon.texture:SetTexture("Interface\\Buttons\\WHITE8x8")
        previewIcon.texture:SetVertexColor(0.2, 0.2, 0.2, 1)
        previewIcon.indexText:SetText(tostring(data.index))
        previewIcon.indexText:Show()
      end
      previewIcon:Show()
    end
  end
  
  UpdatePreviewLayout(key)
end

-- Apply layout - EXACT same logic as layoutCustomGrid, with scaling to fit
UpdatePreviewLayout = function(key)
  if not previewPanel or not previewPanel.previewBox then return end
  if not key then key = previewCurrentKey end
  if not key then return end
  
  local previewBox = previewPanel.previewBox
  local container = previewBox.iconContainer
  if not container then return end
  
  -- Gather visible icons in order
  local ordered = {}
  for i = 1, PREVIEW_ICON_POOL_SIZE do
    if previewIcons[i] and previewIcons[i]:IsShown() then
      table.insert(ordered, previewIcons[i])
    end
  end
  
  if #ordered == 0 then return end
  
  -- Get settings (EXACT same as layoutCustomGrid)
  local pattern = GetSetting(key, "rowPattern") or {1,3,4,3}
  local compactMode = GetSetting(key, "compactMode") or false
  local iconSize = GetSetting(key, "iconSize") or 40
  local aspectRatio = GetSetting(key, "aspectRatio") or "1:1"
  local layoutDirection = GetSetting(key, "layoutDirection") or "ROWS"
  local alignment = GetSetting(key, "alignment") or "CENTER"
  local zoom = GetSetting(key, "zoom") or 1.0
  local borderAlpha = GetSetting(key, "borderAlpha") or 1.0
  
  -- Calculate spacing
  local h, v
  if compactMode then
    local off = GetSetting(key, "compactOffset") or -4
    h, v = off, off
  else
    h = GetSetting(key, "hSpacing") or 2
    v = GetSetting(key, "vSpacing") or 2
  end
  
  -- Check if Masque is controlling visuals for this tracker
  local masqueControlsVisuals = MasqueModule and MasqueModule.ControlsVisualsForTracker and MasqueModule.ControlsVisualsForTracker(key)
  
  -- Calculate icon dimensions from aspect ratio
  -- When Masque is active, force square icons (Masque expects square)
  local iconWidth, iconHeight = iconSize, iconSize
  if not masqueControlsVisuals and aspectRatio and aspectRatio ~= "1:1" then
    local aspectW, aspectH = ParseAspectRatio(aspectRatio)
    if aspectW and aspectH and aspectW > 0 and aspectH > 0 then
      if aspectW > aspectH then
        iconWidth = iconSize
        iconHeight = (iconSize * aspectH) / aspectW
      elseif aspectH > aspectW then
        iconWidth = (iconSize * aspectW) / aspectH
        iconHeight = iconSize
      end
    end
  end
  
  -- Note: When Masque is active, icons are still positioned based on iconSize
  -- The Masque skin adds visual borders but doesn't change frame positions
  -- So we use iconSize for both width and height (square icons with Masque)
  
  -- Build grid structure (EXACT same logic as layoutCustomGrid)
  local grid = {}
  local idx = 1
  
  if layoutDirection == "COLUMNS" then
    local maxRows = 0
    for _, count in ipairs(pattern) do
      if count > maxRows then maxRows = count end
    end
    
    for rowIdx = 1, maxRows do
      grid[rowIdx] = {}
      grid[rowIdx]._size = #pattern
      for colIdx, colCount in ipairs(pattern) do
        if rowIdx <= colCount and idx <= #ordered then
          grid[rowIdx][colIdx] = ordered[idx]
          idx = idx + 1
        end
      end
    end
  else
    for rowIdx, rowCount in ipairs(pattern) do
      grid[rowIdx] = {}
      grid[rowIdx]._size = rowCount
      for colIdx = 1, rowCount do
        if idx <= #ordered then
          grid[rowIdx][colIdx] = ordered[idx]
          idx = idx + 1
        end
      end
    end
  end
  
  -- Calculate total layout dimensions at actual size
  local totalWidth, totalHeight = 0, 0
  
  if layoutDirection == "COLUMNS" then
    totalWidth = (#pattern * iconWidth) + ((#pattern - 1) * h)
    local maxRows = 0
    for _, count in ipairs(pattern) do
      if count > maxRows then maxRows = count end
    end
    totalHeight = (maxRows * iconHeight) + ((maxRows - 1) * v)
  else
    local maxCols = 0
    for _, count in ipairs(pattern) do
      if count > maxCols then maxCols = count end
    end
    totalWidth = (maxCols * iconWidth) + ((maxCols - 1) * h)
    totalHeight = (#pattern * iconHeight) + ((#pattern - 1) * v)
  end
  
  -- Calculate bounds expansion from per-icon overrides (same as actual tracker)
  local maxNudgeLeft, maxNudgeRight, maxNudgeUp, maxNudgeDown, maxSizeMult = CalculateMaxBoundsExpansion(key)
  local sizeExpansion = iconSize * (maxSizeMult - 1) / 2
  local padLeft = maxNudgeLeft + sizeExpansion
  local padRight = maxNudgeRight + sizeExpansion
  local padTop = maxNudgeUp + sizeExpansion
  local padBottom = maxNudgeDown + sizeExpansion
  
  -- Add padding to total dimensions (this is what the actual tracker does)
  local expandedWidth = totalWidth + padLeft + padRight
  local expandedHeight = totalHeight + padTop + padBottom
  
  -- Calculate scale to fit in preview area (use expanded dimensions)
  local availWidth = container:GetWidth() - 10
  local availHeight = container:GetHeight() - 10
  local scale = 1.0
  
  if expandedWidth > availWidth then
    scale = math.min(scale, availWidth / expandedWidth)
  end
  if expandedHeight > availHeight then
    scale = math.min(scale, availHeight / expandedHeight)
  end
  scale = math.max(scale, 0.25)  -- Minimum 25% scale
  
  -- Scale the padding too
  local scaledPadLeft = padLeft * scale
  local scaledPadTop = padTop * scale
  
  -- Update scale indicator
  if scale < 1.0 then
    previewBox.scaleText:SetText(string.format("Preview: %.0f%% scale", scale * 100))
  else
    previewBox.scaleText:SetText("Preview: Actual size")
  end
  
  -- Apply scale to dimensions
  local scaledIconWidth = iconWidth * scale
  local scaledIconHeight = iconHeight * scale
  local scaledH = h * scale
  local scaledV = v * scale
  
  -- Recalculate maxW for alignment at scaled size
  local maxW = 0
  for _, row in ipairs(grid) do
    local rowSize = row._size or #row
    local rowIconCount = 0
    for i = 1, rowSize do
      if row[i] then rowIconCount = rowIconCount + 1 end
    end
    local rowW = (rowIconCount * scaledIconWidth) + ((rowIconCount - 1) * scaledH)
    if rowW > maxW then maxW = rowW end
  end
  
  -- Column heights for column mode alignment
  local columnHeights = {}
  local maxColumnHeight = 0
  if layoutDirection == "COLUMNS" and grid[1] then
    local rowSize = grid[1]._size or #grid[1]
    for colIdx = 1, rowSize do
      local colHeight = 0
      for rowIdx = 1, #grid do
        local row = grid[rowIdx]
        local rs = row._size or #row
        if colIdx <= rs and row[colIdx] then
          colHeight = colHeight + 1
        end
      end
      columnHeights[colIdx] = colHeight
      if colHeight > maxColumnHeight then
        maxColumnHeight = colHeight
      end
    end
  end
  
  -- Calculate centering offset for the entire layout in the container
  -- Use expanded dimensions to match actual tracker behavior
  local scaledExpandedWidth = expandedWidth * scale
  local scaledExpandedHeight = expandedHeight * scale
  local centerOffsetX = (availWidth - scaledExpandedWidth) / 2
  local centerOffsetY = (availHeight - scaledExpandedHeight) / 2
  
  -- Position icons (EXACT same logic as layoutCustomGrid)
  local y = 0
  local iconCounter = 0  -- Track sequential icon position for frame level
  for rowIdx, row in ipairs(grid) do
    local rowSize = row._size or #row
    local iconCountRow = 0
    for i = 1, rowSize do
      if row[i] then iconCountRow = iconCountRow + 1 end
    end
    local rowW = (iconCountRow * scaledIconWidth) + ((iconCountRow - 1) * scaledH)
    local x0 = 0
    
    if layoutDirection ~= "COLUMNS" then
      if alignment == "CENTER" then
        x0 = (maxW - rowW) / 2
      elseif alignment == "RIGHT" then
        x0 = maxW - rowW
      end
    end
    
    for colIdx = 1, rowSize do
      local icon = row[colIdx]
      if icon then
        -- Get per-icon override for this slot
        local identifier = nil
        if key == "items" and icon.entry then
          identifier = GetIconIdentifier(key, icon.entry)
        elseif icon.slotIndex then
          identifier = GetIconIdentifier(key, nil, icon.slotIndex)
        end
        
        -- Use pending overrides (if settings panel is open) to show unsaved changes in preview
        local override
        if previewPanel and previewPanel.settingsArea and previewPanel.settingsArea.GetPendingOverride then
          override = identifier and previewPanel.settingsArea:GetPendingOverride(key, identifier) or {}
        else
          override = identifier and GetIconOverride(key, identifier) or {}
        end
        
        -- For buffs tracker, use state-specific settings based on current tab
        local settings
        local isSimulatingMissing = false
        if key == "buffs" and previewPanel and previewPanel.settingsArea then
          local currentState = previewPanel.settingsArea.currentBuffState or "active"
          local stateKey = currentState .. "State"
          settings = override[stateKey] or {}
          isSimulatingMissing = (currentState == "inactive")
        else
          settings = override
        end
        
        local iconSizeMultiplier = settings.sizeMultiplier or 1.0
        local iconZoom = settings.zoomOverride or zoom
        -- For "Buff Missing" state, inherit global inactiveAlpha if not explicitly set
        local iconOpacity = settings.opacity
        if iconOpacity == nil then
          if isSimulatingMissing then
            iconOpacity = GetSetting("buffs", "inactiveAlpha") or 0.5
          else
            iconOpacity = 1.0
          end
        end
        local iconBorderColor = settings.borderColor
        local iconBorderAlpha = settings.borderAlpha or 1.0
        local iconBorderWidth = settings.borderWidth or 2
        local iconNudgeX = (settings.nudgeX or 0) * scale  -- Scale nudge with preview
        local iconNudgeY = (settings.nudgeY or 0) * scale
        local iconAspect = settings.aspectOverride or aspectRatio  -- Use override or tracker default
        -- For "Buff Missing" state, inherit global greyscaleInactive if not explicitly set
        local iconDesaturate = settings.desaturate
        if iconDesaturate == nil then
          if isSimulatingMissing then
            local globalGreyscale = GetSetting("buffs", "greyscaleInactive")
            if globalGreyscale == nil then globalGreyscale = true end
            iconDesaturate = globalGreyscale
          else
            iconDesaturate = false
          end
        end
        
        -- Calculate this icon's size based on aspect ratio (with size multiplier)
        local thisIconWidth, thisIconHeight
        local baseSize = iconSize * scale * iconSizeMultiplier
        
        -- When Masque is active, force square icons
        if masqueControlsVisuals then
          thisIconWidth = baseSize
          thisIconHeight = baseSize
        else
          -- Parse aspect ratio (supports both "W:H" preset and "WxH" custom formats)
          local aspectW, aspectH = ParseAspectRatio(iconAspect)
          
          -- Size the frame based on aspect ratio
          if aspectW > aspectH then
            thisIconWidth = baseSize
            thisIconHeight = (baseSize * aspectH) / aspectW
          elseif aspectH > aspectW then
            thisIconWidth = (baseSize * aspectW) / aspectH
            thisIconHeight = baseSize
          else
            thisIconWidth = baseSize
            thisIconHeight = baseSize
          end
        end
        
        local x, y_pos
        
        if layoutDirection == "COLUMNS" then
          local colHeight = columnHeights[colIdx] or 0
          local colTotalHeight = (colHeight * scaledIconHeight) + ((colHeight - 1) * scaledV)
          local maxTotalHeight = (maxColumnHeight * scaledIconHeight) + ((maxColumnHeight - 1) * scaledV)
          
          local colYOffset = 0
          if alignment == "MIDDLE" then
            colYOffset = (maxTotalHeight - colTotalHeight) / 2
          elseif alignment == "BOTTOM" then
            colYOffset = maxTotalHeight - colTotalHeight
          end
          
          x = (colIdx - 1) * (scaledIconWidth + scaledH)
          y_pos = colYOffset + ((rowIdx - 1) * (scaledIconHeight + scaledV))
        else
          x = x0 + ((colIdx - 1) * (scaledIconWidth + scaledH))
          y_pos = y
        end
        
        -- Position with centering offset, padding offset, and nudge
        -- The padding offset matches how the actual tracker positions icons within the expanded frame
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", container, "TOPLEFT", centerOffsetX + scaledPadLeft + x + iconNudgeX, -(centerOffsetY + scaledPadTop + y_pos) - iconNudgeY)
        icon:SetSize(thisIconWidth, thisIconHeight)
        icon:SetScale(1.0)  -- Reset any previous scale
        
        -- Track iteration order
        iconCounter = iconCounter + 1
        
        -- Set frame level based on slot index so earlier slots are always on top
        -- This ensures clicking works correctly when icons overlap due to nudge
        local baseLevel = container:GetFrameLevel() + 1
        local slotIdx = icon.slotIndex or iconCounter
        -- Earlier slots get HIGHER frame level so they're on top (slot 1 = highest)
        local iconLevel = baseLevel + (100 - slotIdx)
        icon:SetFrameLevel(iconLevel)
        
        -- Apply aspect ratio cropping and zoom to texture (same logic as real tracker)
        -- Skip when Masque is active - just use standard square texture coords
        if masqueControlsVisuals then
          icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- Standard icon crop
        else
          local left, right, top, bottom = 0, 1, 0, 1
          
          -- Determine cropping based on aspect ratio
          local aspectW, aspectH = ParseAspectRatio(iconAspect)
          local cropVertical = aspectW > aspectH
          local cropHorizontal = aspectH > aspectW
          
          if cropVertical then
            -- Wider than tall (16:9, 21:9, 4:3) - crop top/bottom
            local targetRatio = aspectW / aspectH
            local cropAmount = 1.0 - (1.0 / targetRatio)
            local offset = cropAmount / 2.0
            top = offset
            bottom = 1.0 - offset
          elseif cropHorizontal then
            -- Taller than wide (9:16, 3:4) - crop left/right
            local targetRatio = aspectH / aspectW
            local cropAmount = 1.0 - (1.0 / targetRatio)
            local offset = cropAmount / 2.0
            left = offset
            right = 1.0 - offset
          end
          
          -- Apply zoom on top of aspect ratio
          if iconZoom and iconZoom > 1.0 then
            local visibleSize = 1.0 / iconZoom
            local currentWidth = right - left
            local currentHeight = bottom - top
            local zoomedWidth = currentWidth * visibleSize
            local zoomedHeight = currentHeight * visibleSize
            local centerX = (left + right) / 2.0
            local centerY = (top + bottom) / 2.0
            left = centerX - (zoomedWidth / 2.0)
            right = centerX + (zoomedWidth / 2.0)
            top = centerY - (zoomedHeight / 2.0)
            bottom = centerY + (zoomedHeight / 2.0)
          end
          
          icon.texture:SetTexCoord(left, right, top, bottom)
        end
        
        -- Apply opacity
        icon.texture:SetAlpha(iconOpacity)
        
        -- Apply custom border if set (skip if Masque active - it controls borders)
        if iconBorderColor and not masqueControlsVisuals then
          -- Get or create border frame for preview icon
          if not icon.customBorder then
            icon.customBorder = CreateFrame("Frame", nil, icon, "BackdropTemplate")
            icon.customBorder:SetFrameLevel(icon:GetFrameLevel() + 5)
            icon.customBorder:EnableMouse(false)  -- Don't intercept clicks
          end
          
          -- Find color
          local color = {1, 1, 1}
          for _, preset in ipairs(BORDER_COLOR_PRESETS) do
            if preset.name == iconBorderColor and preset.color then
              color = preset.color
              break
            end
          end
          
          -- Scale border width with preview
          local scaledWidth = math.max(1, math.floor(iconBorderWidth * scale))
          
          icon.customBorder:ClearAllPoints()
          icon.customBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -scaledWidth, scaledWidth)
          icon.customBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", scaledWidth, -scaledWidth)
          icon.customBorder:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = scaledWidth,
          })
          icon.customBorder:SetBackdropBorderColor(color[1], color[2], color[3], iconBorderAlpha)
          icon.customBorder:Show()
        else
          -- Hide custom border if exists
          if icon.customBorder then
            icon.customBorder:Hide()
          end
        end
        
        -- Apply desaturate setting
        icon.texture:SetDesaturated(iconDesaturate)
      end
    end
    
    if layoutDirection ~= "COLUMNS" then
      y = y + scaledIconHeight + scaledV
    end
  end
end

-- Show/hide preview panel based on current tab
local function ShowPreviewForTab(key)
  if not previewPanel then return end
  
  -- Only show preview for layout tabs (Essential, Utility, Buffs, Custom Layout)
  local layoutTabs = { essential = true, utility = true, buffs = true, items = true }
  
  if layoutTabs[key] then
    -- Clear selection when switching tabs
    previewSelectedSlot = nil
    if previewPanel.settingsArea and previewPanel.settingsArea.RefreshForIcon then
      previewPanel.settingsArea:RefreshForIcon(nil, nil, nil, nil, nil)
    end
    
    previewPanel:Show()
    PopulatePreview(key)
  else
    -- Hide preview area for non-layout tabs
    previewPanel:Hide()
    previewSelectedSlot = nil
  end
end

-- Refresh preview (called when settings change)
local function RefreshPreview()
  if previewPanel and previewPanel:IsShown() and previewCurrentKey then
    UpdatePreviewLayout(previewCurrentKey)
  end
end

-- Full refresh including icon population
local function FullRefreshPreview()
  if previewPanel and previewPanel:IsShown() and previewCurrentKey then
    PopulatePreview(previewCurrentKey)
  end
end


local function CreateConfigPanel()
  if configPanel then return configPanel end
  
  -- ============================================================
  -- CONSTANTS
  -- ============================================================
  local HUB_WIDTH = 220
  local HUB_HEIGHT = 405
  local BUTTON_WIDTH = 180
  local BUTTON_HEIGHT = 32
  local BUTTON_SPACING = 8
  local SECTION_SPACING = 20
  
  local TRACKER_PANEL_WIDTH = 460
  local TRACKER_PANEL_HEIGHT = 750
  local SIDE_PANEL_WIDTH = 510
  local ITEMS_PANEL_WIDTH = 500
  local ITEMS_PANEL_HEIGHT = 700
  local PROFILES_PANEL_WIDTH = 480
  local PROFILES_PANEL_HEIGHT = 900
  local GENERAL_PANEL_WIDTH = 450
  local GENERAL_PANEL_HEIGHT = 750
  
  -- ============================================================
  -- DARK BACKDROP TEMPLATE
  -- ============================================================
  local darkBackdrop = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
  }
  
  -- ============================================================
  -- MAIN HUB PANEL
  -- ============================================================
  local panel = CreateFrame("Frame", "CMT_ConfigPanel", UIParent, "BackdropTemplate")
  panel:SetSize(HUB_WIDTH, HUB_HEIGHT)
  
  -- Restore saved position or use default
  if CMT_DB.hubPosition then
    panel:SetPoint(CMT_DB.hubPosition.point, UIParent, CMT_DB.hubPosition.relPoint, CMT_DB.hubPosition.x, CMT_DB.hubPosition.y)
  else
    panel:SetPoint("CENTER", -400, 0)
  end
  
  panel:SetBackdrop(darkBackdrop)
  panel:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
  panel:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
  panel:SetMovable(true)
  panel:EnableMouse(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
  panel:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    CMT_DB.hubPosition = { point = point, relPoint = relPoint, x = x, y = y }
  end)
  panel:Hide()
  panel:SetFrameStrata("HIGH")
  
  tinsert(UISpecialFrames, "CMT_ConfigPanel")
  
  -- Close button
  panel.CloseButton = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  panel.CloseButton:SetPoint("TOPRIGHT", -2, -2)
  
  -- Title
  panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  panel.title:SetPoint("TOP", 0, -12)
  panel.title:SetText("CMT")
  panel.title:SetTextColor(1, 0.82, 0)
  
  local ver = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ver:SetPoint("TOP", panel.title, "BOTTOM", 0, -2)
  ver:SetText("v" .. VERSION)
  ver:SetTextColor(0.6, 0.6, 0.6)
  
  -- Track all panels for cleanup
  local allPanels = {}
  
  -- ============================================================
  -- HELPER: Create a dockable panel
  -- ============================================================
  local function CreateDockedPanel(name, width, height, headerText)
    local p = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    p:SetSize(width, height)
    p:SetBackdrop(darkBackdrop)
    p:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    p:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    p:SetFrameStrata("HIGH")
    p:Hide()
    
    local header = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOP", 0, -12)
    header:SetText(headerText)
    header:SetTextColor(1, 0.82, 0)
    p.header = header
    
    local closeBtn = CreateFrame("Button", nil, p, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() p:Hide() end)
    
    -- When a tracker panel closes, re-dock the per-icon side panel to the main hub
    p:SetScript("OnHide", function(self)
      if sidePanel and sidePanel:IsShown() then
        -- Re-dock sidePanel to the main hub instead of closing it
        sidePanel:ClearAllPoints()
        sidePanel:SetPoint("TOPLEFT", panel, "TOPRIGHT", 0, 0)
      end
    end)
    
    table.insert(allPanels, p)
    return p
  end
  
  -- ============================================================
  -- HELPER: Position panel next to hub
  -- ============================================================
  local function PositionPanelNextToHub(targetPanel)
    targetPanel:ClearAllPoints()
    targetPanel:SetPoint("TOPLEFT", panel, "TOPRIGHT", 0, 0)
  end
  
  -- ============================================================
  -- HELPER: Hide all panels
  -- ============================================================
  local function HideAllPanels()
    for _, p in ipairs(allPanels) do
      p:Hide()
    end
    if sidePanel then sidePanel:Hide() end
  end
  
  -- ============================================================
  -- HELPER: Open a panel (close others first)
  -- ============================================================
  local function OpenPanel(targetPanel, trackerKey)
    -- Check if sidePanel is currently showing for this tracker
    local sidePanelWasShowing = sidePanel and sidePanel:IsShown() and sidePanel.currentTrackerKey == trackerKey
    
    -- If sidePanel is showing for a DIFFERENT tracker, hide it
    if sidePanel and sidePanel:IsShown() and sidePanel.currentTrackerKey ~= trackerKey then
      sidePanel:Hide()
    end
    
    -- Hide all panels except preserve sidePanel state
    for _, p in ipairs(allPanels) do
      if p ~= sidePanel then
        p:Hide()
      end
    end
    
    PositionPanelNextToHub(targetPanel)
    targetPanel:Show()
    
    -- If sidePanel was showing for this tracker, re-dock it to the tracker panel
    if sidePanelWasShowing and sidePanel then
      sidePanel:ClearAllPoints()
      sidePanel:SetPoint("TOPLEFT", targetPanel, "TOPRIGHT", 0, 0)
    end
    
    -- Update preview if it's a tracker panel
    if trackerKey then
      ShowPreviewForTab(trackerKey)
    else
      ShowPreviewForTab(nil)
    end
  end
  
  -- ============================================================
  -- CREATE TRACKER PANELS
  -- Each uses CreateTrackerTab which includes visibility settings
  -- ============================================================
  
  -- Essential Cooldowns Panel
  local essentialPanel = CreateDockedPanel("CMT_EssentialPanel", TRACKER_PANEL_WIDTH, TRACKER_PANEL_HEIGHT, "Essential Cooldowns")
  local essentialContent = CreateTrackerTab(essentialPanel, "essential", "Essential Cooldowns")
  essentialContent:SetPoint("TOPLEFT", 10, -35)
  essentialContent:SetPoint("BOTTOMRIGHT", -10, 50)
  essentialContent:Show()
  
  local essentialPerIconBtn = CreateFrame("Button", nil, essentialPanel, "UIPanelButtonTemplate")
  essentialPerIconBtn:SetSize(160, 28)
  essentialPerIconBtn:SetPoint("BOTTOM", 0, 12)
  essentialPerIconBtn:SetText("Per-Icon Settings")
  essentialPerIconBtn.trackerKey = "essential"
  
  -- Utility Cooldowns Panel
  local utilityPanel = CreateDockedPanel("CMT_UtilityPanel", TRACKER_PANEL_WIDTH, TRACKER_PANEL_HEIGHT, "Utility Cooldowns")
  local utilityContent = CreateTrackerTab(utilityPanel, "utility", "Utility Cooldowns")
  utilityContent:SetPoint("TOPLEFT", 10, -35)
  utilityContent:SetPoint("BOTTOMRIGHT", -10, 50)
  utilityContent:Show()
  
  local utilityPerIconBtn = CreateFrame("Button", nil, utilityPanel, "UIPanelButtonTemplate")
  utilityPerIconBtn:SetSize(160, 28)
  utilityPerIconBtn:SetPoint("BOTTOM", 0, 12)
  utilityPerIconBtn:SetText("Per-Icon Settings")
  utilityPerIconBtn.trackerKey = "utility"
  
  -- Buff Tracker Panel
  local buffsPanel = CreateDockedPanel("CMT_BuffsPanel", TRACKER_PANEL_WIDTH, TRACKER_PANEL_HEIGHT, "Buff Tracker")
  local buffsContent = CreateTrackerTab(buffsPanel, "buffs", "Buff Tracker")
  buffsContent:SetPoint("TOPLEFT", 10, -35)
  buffsContent:SetPoint("BOTTOMRIGHT", -10, 50)
  buffsContent:Show()
  
  local buffsPerIconBtn = CreateFrame("Button", nil, buffsPanel, "UIPanelButtonTemplate")
  buffsPerIconBtn:SetSize(160, 28)
  buffsPerIconBtn:SetPoint("BOTTOM", 0, 12)
  buffsPerIconBtn:SetText("Per-Icon Settings")
  buffsPerIconBtn.trackerKey = "buffs"
  
  -- Custom Tracker Panel
  local customPanel = CreateDockedPanel("CMT_CustomPanel", TRACKER_PANEL_WIDTH, TRACKER_PANEL_HEIGHT, "Custom Tracker")
  local customContent = CreateTrackerTab(customPanel, "items", "Custom Tracker")
  customContent:SetPoint("TOPLEFT", 10, -35)
  customContent:SetPoint("BOTTOMRIGHT", -10, 50)
  customContent:Show()
  
  local customPerIconBtn = CreateFrame("Button", nil, customPanel, "UIPanelButtonTemplate")
  customPerIconBtn:SetSize(160, 28)
  customPerIconBtn:SetPoint("BOTTOM", 0, 12)
  customPerIconBtn:SetText("Per-Icon Settings")
  customPerIconBtn.trackerKey = "items"
  
  -- ============================================================
  -- CREATE SIDE PANEL (Per-Icon Settings with Preview)
  -- ============================================================
  sidePanel = CreateDockedPanel("CMT_SidePanel", SIDE_PANEL_WIDTH, TRACKER_PANEL_HEIGHT, "Per-Icon Settings")
  sidePanel.currentTrackerKey = nil
  
  -- Create the preview area inside the side panel
  previewPanel = CreatePreviewArea(sidePanel)
  previewPanel:ClearAllPoints()
  previewPanel:SetPoint("TOPLEFT", sidePanel, "TOPLEFT", 10, -35)
  previewPanel:SetPoint("BOTTOMRIGHT", sidePanel, "BOTTOMRIGHT", -10, 10)
  
  -- Wire up per-icon buttons
  local function SetupPerIconButton(btn, trackerPanel)
    btn:SetScript("OnClick", function()
      if sidePanel:IsShown() and sidePanel.currentTrackerKey == btn.trackerKey then
        sidePanel:Hide()
      else
        sidePanel:ClearAllPoints()
        sidePanel:SetPoint("TOPLEFT", trackerPanel, "TOPRIGHT", 0, 0)
        sidePanel.currentTrackerKey = btn.trackerKey
        sidePanel:Show()
        ShowPreviewForTab(btn.trackerKey)
      end
    end)
  end
  
  SetupPerIconButton(essentialPerIconBtn, essentialPanel)
  SetupPerIconButton(utilityPerIconBtn, utilityPanel)
  SetupPerIconButton(buffsPerIconBtn, buffsPanel)
  SetupPerIconButton(customPerIconBtn, customPanel)
  
  -- ============================================================
  -- CREATE ITEMS & SPELLS PANEL
  -- ============================================================
  local itemsPanel = CreateDockedPanel("CMT_ItemsPanel", ITEMS_PANEL_WIDTH, ITEMS_PANEL_HEIGHT, "Items & Spells")
  
  local itemsContent = CreateFrame("Frame", nil, itemsPanel)
  itemsContent:SetPoint("TOPLEFT", 15, -40)
  itemsContent:SetPoint("BOTTOMRIGHT", -15, 15)
  
  local iy = 0
  local iinfo = itemsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  iinfo:SetPoint("TOPLEFT", 0, iy)
  iinfo:SetWidth(ITEMS_PANEL_WIDTH - 50)
  iinfo:SetJustifyH("LEFT")
  iinfo:SetText("Track items (potions, trinkets) and spells (racials, abilities). Drag items from your bags to add them, or use slash commands for spells.")
  iy = iy - 50
  
  -- Drop zone
  local dropZoneLabel = itemsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  dropZoneLabel:SetPoint("TOPLEFT", 0, iy)
  dropZoneLabel:SetText("Drag & Drop Items Here:")
  iy = iy - 22
  
  local dropZone = CreateFrame("Frame", nil, itemsContent, "BackdropTemplate")
  dropZone:SetPoint("TOPLEFT", 0, iy)
  dropZone:SetSize(ITEMS_PANEL_WIDTH - 50, 180)
  dropZone:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  dropZone:SetBackdropColor(0.1, 0.1, 0.15, 0.8)
  dropZone:SetBackdropBorderColor(0.3, 0.3, 0.4, 1)
  dropZone:EnableMouse(true)
  
  local dropText = dropZone:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  dropText:SetPoint("CENTER")
  dropText:SetText("Drag items or spells here")
  dropText:SetTextColor(0.5, 0.5, 0.6)
  
  local iconContainer = CreateFrame("Frame", nil, dropZone)
  iconContainer:SetPoint("TOPLEFT", 10, -10)
  iconContainer:SetPoint("BOTTOMRIGHT", -10, 10)
  
  -- Refresh function for item display
  local function RefreshItemDisplay()
    if iconContainer.displayIcons then
      for _, frame in ipairs(iconContainer.displayIcons) do
        frame:Hide()
        frame:SetParent(nil)
      end
    end
    iconContainer.displayIcons = {}
    
    local specItems = GetCurrentSpecEntries()
    if not specItems or #specItems == 0 then
      dropText:Show()
      return
    end
    dropText:Hide()
    
    local iconSize, spacing, iconsPerRow = 36, 4, 11
    for idx, entry in ipairs(specItems) do
      local entryType, actualID = entry.type, entry.id
      local entryName, entryTexture
      
      CMT_CharDB.trackerCache = CMT_CharDB.trackerCache or {}
      
      if entryType == "item" then
        local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(actualID)
        entryName = itemName
        entryTexture = itemTexture
        if not entryTexture then
          local cache = CMT_CharDB.trackerCache["item_" .. actualID]
          if cache then entryName, entryTexture = cache.name, cache.texture end
        end
      elseif entryType == "spell" then
        local spellInfo = C_Spell.GetSpellInfo(actualID)
        if spellInfo then
          entryName = spellInfo.name
          entryTexture = C_Spell.GetSpellTexture(actualID)
        else
          local cache = CMT_CharDB.trackerCache["spell_" .. actualID]
          if cache then entryName, entryTexture = cache.name, cache.texture end
        end
      end
      
      if entryTexture then
        local row = math.floor((idx - 1) / iconsPerRow)
        local col = (idx - 1) % iconsPerRow
        
        local frame = CreateFrame("Frame", nil, iconContainer)
        frame:SetSize(iconSize, iconSize)
        frame:SetPoint("TOPLEFT", col * (iconSize + spacing), -row * (iconSize + spacing))
        
        local border = frame:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints()
        border:SetColorTexture(0.3, 0.3, 0.3, 1)
        
        local bg = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
        bg:SetPoint("TOPLEFT", 1, -1)
        bg:SetPoint("BOTTOMRIGHT", -1, 1)
        bg:SetColorTexture(0, 0, 0, 0.8)
        
        local icon = frame:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", -1, 1)
        icon:SetTexture(entryTexture)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        
        frame:EnableMouse(true)
        frame:SetScript("OnEnter", function(self)
          if not InCombatLockdown() then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if entryType == "item" then
              GameTooltip:SetItemByID(actualID)
            else
              GameTooltip:SetSpellByID(actualID)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Right-click to remove", 1, 0.5, 0.5)
            GameTooltip:Show()
          end
        end)
        frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
        frame:SetScript("OnMouseUp", function(self, button)
          if button == "RightButton" then
            RemoveTrackedEntry(entryType, actualID)
            RefreshItemDisplay()
            relayoutOne("items")
          end
        end)
        
        table.insert(iconContainer.displayIcons, frame)
      end
    end
  end
  
  itemsPanel.RefreshItemDisplay = RefreshItemDisplay
  
  -- Drop zone handlers
  dropZone:SetScript("OnReceiveDrag", function()
    local infoType, id, subType = GetCursorInfo()
    if infoType == "item" then
      AddTrackedEntry("item", id)
      ClearCursor()
      RefreshItemDisplay()
      relayoutOne("items")
    elseif infoType == "spell" then
      AddTrackedEntry("spell", id)
      ClearCursor()
      RefreshItemDisplay()
      relayoutOne("items")
    end
  end)
  dropZone:SetScript("OnMouseUp", dropZone:GetScript("OnReceiveDrag"))
  
  iy = iy - 195
  
  local cmdLabel = itemsContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  cmdLabel:SetPoint("TOPLEFT", 0, iy)
  cmdLabel:SetText("Slash Commands:")
  iy = iy - 20
  
  local cmdInfo = itemsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  cmdInfo:SetPoint("TOPLEFT", 0, iy)
  cmdInfo:SetWidth(ITEMS_PANEL_WIDTH - 50)
  cmdInfo:SetJustifyH("LEFT")
  cmdInfo:SetSpacing(3)
  cmdInfo:SetText("/cmt addspell [id] - Add a spell by its ID\n/cmt additem [id] - Add an item by its ID\n/cmt remove [id] - Remove an entry\n/cmt clear - Remove all entries")
  iy = iy - 75
  
  local tipLabel = itemsContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  tipLabel:SetPoint("TOPLEFT", 0, iy)
  tipLabel:SetText("Finding Spell/Item IDs:")
  iy = iy - 20
  
  local tipInfo = itemsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  tipInfo:SetPoint("TOPLEFT", 0, iy)
  tipInfo:SetWidth(ITEMS_PANEL_WIDTH - 50)
  tipInfo:SetJustifyH("LEFT")
  tipInfo:SetSpacing(3)
  tipInfo:SetText("Visit Wowhead.com and search for the spell or item. The ID is the number in the URL (e.g., wowhead.com/spell=12345).")
  
  -- ============================================================
  -- CREATE PROFILES PANEL (reuse existing profile content logic)
  -- ============================================================
  local profilesPanel = CreateDockedPanel("CMT_ProfilesPanel", PROFILES_PANEL_WIDTH, PROFILES_PANEL_HEIGHT, "Profiles")
  
  local profileContent = CreateFrame("Frame", nil, profilesPanel)
  profileContent:SetPoint("TOPLEFT", 15, -40)
  profileContent:SetPoint("BOTTOMRIGHT", -15, 15)
  
  -- Profile dropdown and controls will be populated here
  local py = 0
  
  local profileDesc = profileContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  profileDesc:SetPoint("TOPLEFT", 0, py)
  profileDesc:SetWidth(PROFILES_PANEL_WIDTH - 50)
  profileDesc:SetJustifyH("LEFT")
  profileDesc:SetText("Profiles store all your tracker settings. Each character can use different profiles, and you can auto-switch based on spec.")
  py = py - 45
  
  -- Active profile section
  local activeLabel = profileContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  activeLabel:SetPoint("TOPLEFT", 0, py)
  activeLabel:SetText("Active Profile:")
  py = py - 25
  
  local profileDropdown = CreateFrame("Frame", "CMT_ProfileDropdown", profileContent, "UIDropDownMenuTemplate")
  profileDropdown:SetPoint("TOPLEFT", -15, py)
  UIDropDownMenu_SetWidth(profileDropdown, 200)
  
  local function refreshProfileDropdown()
    UIDropDownMenu_Initialize(profileDropdown, function(self, level)
      for name, _ in pairs(CMT_DB.profiles or {}) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = name
        info.value = name
        info.checked = (name == CMT_CharDB.currentProfile)
        info.func = function()
          CMT_CharDB.currentProfile = name
          UIDropDownMenu_SetText(profileDropdown, name)
          StaticPopup_Show("PROFILE_RELOAD_UI")
        end
        UIDropDownMenu_AddButton(info, level)
      end
    end)
    UIDropDownMenu_SetText(profileDropdown, CMT_CharDB.currentProfile or "Default")
  end
  refreshProfileDropdown()
  py = py - 35
  
  local saveBtn = CreateFrame("Button", nil, profileContent, "UIPanelButtonTemplate")
  saveBtn:SetSize(180, 24)
  saveBtn:SetPoint("TOPLEFT", 0, py)
  saveBtn:SetText("Save Current Settings")
  saveBtn:SetScript("OnClick", function()
    local profileName = CMT_CharDB.currentProfile
    if not CMT_DB.profiles[profileName] then
      CMT_DB.profiles[profileName] = {}
    end
    
    -- Save current settings from all trackers to the active profile
    for _,t in ipairs(TRACKERS) do
      CMT_DB.profiles[profileName][t.key] = {
        rowPattern        = GetSetting(t.key,"rowPattern"),
        alignment         = GetSetting(t.key,"alignment"),
        reverseOrder      = GetSetting(t.key,"reverseOrder"),
        compactMode       = GetSetting(t.key,"compactMode"),
        compactOffset     = GetSetting(t.key,"compactOffset"),
        hSpacing          = GetSetting(t.key,"hSpacing"),
        vSpacing          = GetSetting(t.key,"vSpacing"),
        barSpacing        = GetSetting(t.key,"barSpacing"),
        barIconSide       = GetSetting(t.key,"barIconSide"),
        barIconGap        = GetSetting(t.key,"barIconGap"),
        zoom              = GetSetting(t.key,"zoom"),
        layoutDirection   = GetSetting(t.key,"layoutDirection"),
        iconSize          = GetSetting(t.key,"iconSize"),
        iconOpacity       = GetSetting(t.key,"iconOpacity"),
        aspectRatio       = GetSetting(t.key,"aspectRatio"),
        customAspectW     = GetSetting(t.key,"customAspectW"),
        customAspectH     = GetSetting(t.key,"customAspectH"),
        borderAlpha       = GetSetting(t.key,"borderAlpha"),
        cooldownTextScale = GetSetting(t.key,"cooldownTextScale"),
        countTextScale    = GetSetting(t.key,"countTextScale"),
        -- Persistent Buff Display settings (v3.2.0)
        persistentDisplay = GetSetting(t.key,"persistentDisplay"),
        greyscaleInactive = GetSetting(t.key,"greyscaleInactive"),
        inactiveAlpha     = GetSetting(t.key,"inactiveAlpha"),
        -- Visibility settings (v4.4.0)
        visibilityEnabled       = GetSetting(t.key,"visibilityEnabled"),
        visibilityCombat        = GetSetting(t.key,"visibilityCombat"),
        visibilityMouseover     = GetSetting(t.key,"visibilityMouseover"),
        visibilityTarget        = GetSetting(t.key,"visibilityTarget"),
        visibilityGroup         = GetSetting(t.key,"visibilityGroup"),
        visibilityInstance      = GetSetting(t.key,"visibilityInstance"),
        visibilityInstanceTypes = GetSetting(t.key,"visibilityInstanceTypes"),
        visibilityFadeAlpha     = GetSetting(t.key,"visibilityFadeAlpha"),
        visibilityOverrideEMT   = GetSetting(t.key,"visibilityOverrideEMT"),
        -- Per-icon settings (v4.3.0)
        iconOverrides           = GetSetting(t.key,"iconOverrides"),
      }
    end
    
    print("CMT: Saved current settings to profile: " .. profileName)
  end)
  py = py - 45
  
  -- Create new profile section
  local newHeader = profileContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  newHeader:SetPoint("TOPLEFT", 0, py)
  newHeader:SetText("Create New Profile:")
  py = py - 25
  
  local newLabel = profileContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  newLabel:SetPoint("TOPLEFT", 0, py)
  newLabel:SetText("Name:")
  
  local newBox = CreateFrame("EditBox", nil, profileContent, "InputBoxTemplate")
  newBox:SetSize(180, 22)
  newBox:SetPoint("LEFT", newLabel, "RIGHT", 10, 0)
  newBox:SetAutoFocus(false)
  
  local createBtn = CreateFrame("Button", nil, profileContent, "UIPanelButtonTemplate")
  createBtn:SetSize(70, 22)
  createBtn:SetPoint("LEFT", newBox, "RIGHT", 8, 0)
  createBtn:SetText("Create")
  createBtn:SetScript("OnClick", function()
    local name = newBox:GetText()
    if not name or name == "" then
      print("CMT: Please enter a profile name")
      return
    end
    if CMT_DB.profiles[name] then
      print("CMT: Profile '" .. name .. "' already exists")
      return
    end
    
    local current = GetCurrentProfile()
    CMT_DB.profiles[name] = deepCopy(current)
    
    newBox:SetText("")
    refreshProfileDropdown()
    print("CMT: Created profile: " .. name)
  end)
  py = py - 45
  
  -- Delete profile section
  local deleteHeader = profileContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  deleteHeader:SetPoint("TOPLEFT", 0, py)
  deleteHeader:SetText("Delete Profile:")
  py = py - 25
  
  local deleteDropdown = CreateFrame("Frame", "CMT_DeleteProfileDropdown", profileContent, "UIDropDownMenuTemplate")
  deleteDropdown:SetPoint("TOPLEFT", -15, py)
  UIDropDownMenu_SetWidth(deleteDropdown, 150)
  UIDropDownMenu_SetText(deleteDropdown, "Select...")
  
  local selectedDeleteProfile = nil
  UIDropDownMenu_Initialize(deleteDropdown, function(self, level)
    for name, _ in pairs(CMT_DB.profiles or {}) do
      if name ~= CMT_CharDB.currentProfile then
        local info = UIDropDownMenu_CreateInfo()
        info.text = name
        info.value = name
        info.func = function()
          selectedDeleteProfile = name
          UIDropDownMenu_SetText(deleteDropdown, name)
        end
        UIDropDownMenu_AddButton(info, level)
      end
    end
  end)
  
  local deleteBtn = CreateFrame("Button", nil, profileContent, "UIPanelButtonTemplate")
  deleteBtn:SetSize(70, 22)
  deleteBtn:SetPoint("LEFT", deleteDropdown, "RIGHT", 0, 2)
  deleteBtn:SetText("Delete")
  deleteBtn:SetScript("OnClick", function()
    if selectedDeleteProfile and CMT_DB.profiles[selectedDeleteProfile] then
      CMT_DB.profiles[selectedDeleteProfile] = nil
      print("CMT: Deleted profile: " .. selectedDeleteProfile)
      selectedDeleteProfile = nil
      UIDropDownMenu_SetText(deleteDropdown, "Select...")
      refreshProfileDropdown()
    end
  end)
  py = py - 50
  
  -- Import/Export section
  local ieHeader = profileContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  ieHeader:SetPoint("TOPLEFT", 0, py)
  ieHeader:SetText("Import / Export:")
  py = py - 25
  
  local ieInfo = profileContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ieInfo:SetPoint("TOPLEFT", 0, py)
  ieInfo:SetWidth(PROFILES_PANEL_WIDTH - 50)
  ieInfo:SetTextColor(0.7, 0.7, 0.7)
  ieInfo:SetText("Export your profile to share, or import a profile string.")
  py = py - 22
  
  local exportBtn = CreateFrame("Button", nil, profileContent, "UIPanelButtonTemplate")
  exportBtn:SetSize(120, 24)
  exportBtn:SetPoint("TOPLEFT", 0, py)
  exportBtn:SetText("Export Profile")
  
  local importBtn = CreateFrame("Button", nil, profileContent, "UIPanelButtonTemplate")
  importBtn:SetSize(120, 24)
  importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0)
  importBtn:SetText("Import Profile")
  
  -- Export functionality
  exportBtn:SetScript("OnClick", function()
    local exportData = {
      version = VERSION,
      profileName = CMT_CharDB.currentProfile,
      trackers = {}
    }
    
    for _, t in ipairs(TRACKERS) do
      local function getSetting(name)
        local val = GetSetting(t.key, name)
        if val ~= nil then return val else return DEFAULTS[name] end
      end
      
      exportData.trackers[t.key] = {
        rowPattern        = getSetting("rowPattern"),
        alignment         = getSetting("alignment"),
        reverseOrder      = getSetting("reverseOrder"),
        compactMode       = getSetting("compactMode"),
        compactOffset     = getSetting("compactOffset"),
        hSpacing          = getSetting("hSpacing"),
        vSpacing          = getSetting("vSpacing"),
        barSpacing        = getSetting("barSpacing"),
        barIconSide       = getSetting("barIconSide"),
        barIconGap        = getSetting("barIconGap"),
        zoom              = getSetting("zoom"),
        layoutDirection   = getSetting("layoutDirection"),
        iconSize          = getSetting("iconSize"),
        iconOpacity       = getSetting("iconOpacity"),
        aspectRatio       = getSetting("aspectRatio"),
        customAspectW     = getSetting("customAspectW"),
        customAspectH     = getSetting("customAspectH"),
        borderAlpha       = getSetting("borderAlpha"),
        cooldownTextScale = getSetting("cooldownTextScale"),
        countTextScale    = getSetting("countTextScale"),
        persistentDisplay = getSetting("persistentDisplay"),
        greyscaleInactive = getSetting("greyscaleInactive"),
        inactiveAlpha     = getSetting("inactiveAlpha"),
        visibilityEnabled       = getSetting("visibilityEnabled"),
        visibilityCombat        = getSetting("visibilityCombat"),
        visibilityMouseover     = getSetting("visibilityMouseover"),
        visibilityTarget        = getSetting("visibilityTarget"),
        visibilityGroup         = getSetting("visibilityGroup"),
        visibilityInstance      = getSetting("visibilityInstance"),
        visibilityInstanceTypes = getSetting("visibilityInstanceTypes"),
        visibilityFadeAlpha     = getSetting("visibilityFadeAlpha"),
        visibilityOverrideEMT   = getSetting("visibilityOverrideEMT"),
        iconOverrides           = getSetting("iconOverrides"),
      }
    end
    
    local serialized = serializeProfile(exportData)
    ShowProfileExportWindow(serialized, CMT_CharDB.currentProfile)
  end)
  
  importBtn:SetScript("OnClick", function()
    ShowProfileImportWindow()
  end)
  py = py - 50
  
  -- Spec assignment section
  local specHeader = profileContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  specHeader:SetPoint("TOPLEFT", 0, py)
  specHeader:SetText("Auto-Switch by Spec:")
  py = py - 22
  
  local specInfo = profileContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  specInfo:SetPoint("TOPLEFT", 0, py)
  specInfo:SetWidth(PROFILES_PANEL_WIDTH - 50)
  specInfo:SetTextColor(0.7, 0.7, 0.7)
  specInfo:SetText("Assign profiles to each spec for automatic switching:")
  py = py - 25
  
  local numSpecs = GetNumSpecializations() or 0
  for i = 1, numSpecs do
    local _, specName = GetSpecializationInfo(i)
    if specName then
      local specLabel = profileContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      specLabel:SetPoint("TOPLEFT", 0, py)
      specLabel:SetText(specName .. ":")
      
      local specDropdown = CreateFrame("Frame", "CMT_SpecDropdown" .. i, profileContent, "UIDropDownMenuTemplate")
      specDropdown:SetPoint("LEFT", specLabel, "RIGHT", 0, -2)
      UIDropDownMenu_SetWidth(specDropdown, 150)
      
      local currentAssigned = CMT_CharDB.specProfiles and CMT_CharDB.specProfiles[i]
      UIDropDownMenu_SetText(specDropdown, currentAssigned or "(Use Active)")
      
      UIDropDownMenu_Initialize(specDropdown, function(self, level)
        -- None option
        local noneInfo = UIDropDownMenu_CreateInfo()
        noneInfo.text = "(Use Active)"
        noneInfo.value = nil
        noneInfo.func = function()
          CMT_CharDB.specProfiles = CMT_CharDB.specProfiles or {}
          CMT_CharDB.specProfiles[i] = nil
          UIDropDownMenu_SetText(specDropdown, "(Use Active)")
        end
        UIDropDownMenu_AddButton(noneInfo, level)
        
        for name, _ in pairs(CMT_DB.profiles or {}) do
          local info = UIDropDownMenu_CreateInfo()
          info.text = name
          info.value = name
          info.checked = (currentAssigned == name)
          info.func = function()
            CMT_CharDB.specProfiles = CMT_CharDB.specProfiles or {}
            CMT_CharDB.specProfiles[i] = name
            UIDropDownMenu_SetText(specDropdown, name)
          end
          UIDropDownMenu_AddButton(info, level)
        end
      end)
      
      py = py - 30
    end
  end
  
  -- ============================================================
  -- CREATE GENERAL SETTINGS PANEL
  -- ============================================================
  local generalPanel = CreateDockedPanel("CMT_GeneralPanel", GENERAL_PANEL_WIDTH, GENERAL_PANEL_HEIGHT, "General Settings")
  
  local generalContent = CreateFrame("Frame", nil, generalPanel)
  generalContent:SetPoint("TOPLEFT", 15, -40)
  generalContent:SetPoint("BOTTOMRIGHT", -15, 15)
  
  local gy = 0
  
  -- Minimap button toggle
  local minimapCB = CreateFrame("CheckButton", nil, generalContent, "ChatConfigCheckButtonTemplate")
  minimapCB:SetPoint("TOPLEFT", 0, gy)
  minimapCB.Text:SetText("Show Minimap Button")
  minimapCB:SetChecked(CMT_DB.showMinimapButton ~= false)
  minimapCB:SetScript("OnClick", function(self)
    CMT_DB.showMinimapButton = self:GetChecked()
    if minimapButton then
      if CMT_DB.showMinimapButton then minimapButton:Show() else minimapButton:Hide() end
    end
  end)
  gy = gy - 25
  
  local minimapNote = generalContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  minimapNote:SetPoint("TOPLEFT", 20, gy)
  minimapNote:SetText("You can always access settings with /cmt")
  minimapNote:SetTextColor(0.6, 0.6, 0.6)
  gy = gy - 30
  
  -- Masque support toggle (using do block to limit local scope)
  do
    local masqueCB = CreateFrame("CheckButton", nil, generalContent, "ChatConfigCheckButtonTemplate")
    masqueCB:SetPoint("TOPLEFT", 0, gy)
    masqueCB.Text:SetText("Enable Masque Skin Support")
    
    local masqueAvailable = MasqueModule and MasqueModule.IsAvailable and MasqueModule.IsAvailable()
    
    if masqueAvailable then
      masqueCB:SetChecked(CMT_DB.masqueEnabled ~= false)
      masqueCB:SetScript("OnClick", function(self)
        if self:GetChecked() then
          if MasqueModule.Enable then MasqueModule.Enable() end
        else
          if MasqueModule.Disable then MasqueModule.Disable() end
        end
      end)
    else
      masqueCB:SetChecked(false)
      masqueCB:Disable()
      masqueCB.Text:SetTextColor(0.5, 0.5, 0.5)
    end
    gy = gy - 25
    
    local masqueNote = generalContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    masqueNote:SetPoint("TOPLEFT", 20, gy)
    if masqueAvailable then
      masqueNote:SetText("Apply custom button skins via /msq")
      masqueNote:SetTextColor(0.6, 0.6, 0.6)
    else
      masqueNote:SetText("Masque addon not installed")
      masqueNote:SetTextColor(0.6, 0.4, 0.4)
    end
  end
  gy = gy - 30
  
  -- Edit Mode info
  local editModeHeader = generalContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  editModeHeader:SetPoint("TOPLEFT", 0, gy)
  editModeHeader:SetText("Edit Mode Configuration:")
  gy = gy - 22
  
  local editModeInfo = generalContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  editModeInfo:SetPoint("TOPLEFT", 0, gy)
  editModeInfo:SetWidth(GENERAL_PANEL_WIDTH - 50)
  editModeInfo:SetJustifyH("LEFT")
  editModeInfo:SetSpacing(2)
  editModeInfo:SetText("CMT works best with these Edit Mode settings:\n• Essential Cooldowns: Horizontal, Columns = 1\n• Utility Cooldowns: Horizontal, Columns = 1\n• Tracked Buffs: Horizontal")
  gy = gy - 75
  
  local checkSettingsBtn = CreateFrame("Button", nil, generalContent, "UIPanelButtonTemplate")
  checkSettingsBtn:SetSize(150, 24)
  checkSettingsBtn:SetPoint("TOPLEFT", 0, gy)
  checkSettingsBtn:SetText("Check Settings")
  checkSettingsBtn:SetScript("OnClick", function()
    if ShowEditModeSetupAssistant then ShowEditModeSetupAssistant()
    else print("CMT: Edit Mode assistant not available") end
  end)
  gy = gy - 50
  
  -- Health monitoring
  local healthHeader = generalContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  healthHeader:SetPoint("TOPLEFT", 0, gy)
  healthHeader:SetText("Health Monitoring:")
  gy = gy - 22
  
  local healthInfo = generalContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  healthInfo:SetPoint("TOPLEFT", 0, gy)
  healthInfo:SetWidth(GENERAL_PANEL_WIDTH - 50)
  healthInfo:SetText("CMT monitors all trackers and automatically fixes issues.")
  gy = gy - 25
  
  local healthBtn = CreateFrame("Button", nil, generalContent, "UIPanelButtonTemplate")
  healthBtn:SetSize(150, 24)
  healthBtn:SetPoint("TOPLEFT", 0, gy)
  healthBtn:SetText("View Health Log")
  healthBtn:SetScript("OnClick", function()
    if ShowHealthLogWindow then ShowHealthLogWindow() end
  end)
  gy = gy - 50
  
  -- Patch notes
  local patchHeader = generalContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  patchHeader:SetPoint("TOPLEFT", 0, gy)
  patchHeader:SetText("What's New:")
  gy = gy - 22
  
  local patchInfo = generalContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  patchInfo:SetPoint("TOPLEFT", 0, gy)
  patchInfo:SetText("View the latest changes and features.")
  gy = gy - 25
  
  local patchBtn = CreateFrame("Button", nil, generalContent, "UIPanelButtonTemplate")
  patchBtn:SetSize(150, 24)
  patchBtn:SetPoint("TOPLEFT", 0, gy)
  patchBtn:SetText("View Patch Notes")
  patchBtn:SetScript("OnClick", function()
    if ShowPatchNotesDialog then ShowPatchNotesDialog() end
  end)
  
  -- ============================================================
  -- HUB BUTTONS
  -- ============================================================
  local y = -50
  
  -- Trackers section
  local trackersLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  trackersLabel:SetPoint("TOP", 0, y)
  trackersLabel:SetText("— Trackers —")
  trackersLabel:SetTextColor(0.7, 0.7, 0.7)
  y = y - 20
  
  local function CreateHubButton(yOffset, text, onClick)
    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    btn:SetPoint("TOP", 0, yOffset)
    btn:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
  end
  
  CreateHubButton(y, "Essential Cooldowns", function() OpenPanel(essentialPanel, "essential") end)
  y = y - BUTTON_HEIGHT - BUTTON_SPACING
  
  CreateHubButton(y, "Utility Cooldowns", function() OpenPanel(utilityPanel, "utility") end)
  y = y - BUTTON_HEIGHT - BUTTON_SPACING
  
  CreateHubButton(y, "Buff Tracker", function() OpenPanel(buffsPanel, "buffs") end)
  y = y - BUTTON_HEIGHT - BUTTON_SPACING
  
  CreateHubButton(y, "Custom Tracker", function() OpenPanel(customPanel, "items") end)
  y = y - BUTTON_HEIGHT - SECTION_SPACING
  
  -- Configuration section
  local configLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  configLabel:SetPoint("TOP", 0, y)
  configLabel:SetText("— Configuration —")
  configLabel:SetTextColor(0.7, 0.7, 0.7)
  y = y - 20
  
  CreateHubButton(y, "Items & Spells", function()
    OpenPanel(itemsPanel, nil)
    RefreshItemDisplay()
  end)
  y = y - BUTTON_HEIGHT - BUTTON_SPACING
  
  CreateHubButton(y, "Profiles", function() OpenPanel(profilesPanel, nil) end)
  y = y - BUTTON_HEIGHT - BUTTON_SPACING
  
  CreateHubButton(y, "General Settings", function() OpenPanel(generalPanel, nil) end)
  
  -- ============================================================
  -- CLOSE BUTTON HANDLER
  -- ============================================================
  panel.CloseButton:SetScript("OnClick", function()
    HideAllPanels()
    panel:Hide()
  end)
  
  -- ============================================================
  -- ONHIDE HANDLER - Ensure all panels close when hub closes
  -- This handles Escape key, clicking outside, etc.
  -- ============================================================
  panel:SetScript("OnHide", function()
    -- Hide the side panel (per-icon settings) when main hub closes
    if sidePanel and sidePanel:IsShown() then
      sidePanel:Hide()
    end
    -- Hide all docked tracker panels
    for _, p in ipairs(allPanels) do
      if p and p:IsShown() then
        p:Hide()
      end
    end
  end)
  
  configPanel = panel
  return panel
end


-- --------------------------------------------------------------------
-- Minimap Button
-- --------------------------------------------------------------------
minimapButton = CreateFrame("Button", "CMT_MinimapButton", Minimap)
minimapButton:SetSize(31, 31)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)
minimapButton:RegisterForClicks("AnyUp")
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Icon
local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
icon:SetSize(22, 22)
icon:SetPoint("CENTER", 0, 0)
icon:SetTexture("Interface\\AddOns\\CooldownManagerTweaks\\CMT_MinimapIcon")

-- Create circular mask
local mask = minimapButton:CreateMaskTexture()
mask:SetTexture("Interface\\Minimap\\UI-Minimap-Background", "CLAMPTOBLACKADDITIVE")
mask:SetAllPoints(icon)
icon:AddMaskTexture(mask)

-- Border
local overlay = minimapButton:CreateTexture(nil, "OVERLAY")
overlay:SetSize(53, 53)
overlay:SetPoint("TOPLEFT")
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

-- Tooltip
minimapButton:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:AddLine("Cooldown Manager Tweaks", 1, 1, 1)
  GameTooltip:AddLine("Click to open settings", 0.8, 0.8, 0.8)
  GameTooltip:AddLine("Drag to move", 0.6, 0.6, 0.6)
  GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)

-- Click to open config
minimapButton:SetScript("OnClick", function(self, button)
  if button == "LeftButton" then
    local p = CreateConfigPanel()
    if p:IsShown() then
      HideUIPanel(p)
    else
      ShowUIPanel(p)
    end
  end
end)

-- Dragging
local function UpdateMinimapButtonPosition()
  local angle = CMT_DB.minimapButtonAngle or 225
  
  -- Dynamically calculate radius based on minimap size
  -- Get minimap width/height and use the smaller dimension to handle square minimaps
  local minimapWidth = Minimap:GetWidth() or 140
  local minimapHeight = Minimap:GetHeight() or 140
  local minimapRadius = math.min(minimapWidth, minimapHeight) / 2
  
  -- Position button at the edge (radius) with a small offset so it sits ON the edge
  local radius = minimapRadius + 5  -- +5 to sit slightly outside the edge
  
  local x = radius * cos(angle)
  local y = radius * sin(angle)
  minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local isDragging = false
minimapButton:SetScript("OnDragStart", function(self)
  isDragging = true
  self:SetScript("OnUpdate", function()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    local angle = math.deg(math.atan2(py - my, px - mx))
    CMT_DB.minimapButtonAngle = angle
    UpdateMinimapButtonPosition()
  end)
end)

minimapButton:SetScript("OnDragStop", function(self)
  isDragging = false
  self:SetScript("OnUpdate", nil)
end)

-- Initialize position
local function InitMinimapButton()
  CMT_DB.minimapButtonAngle = CMT_DB.minimapButtonAngle or 225
  UpdateMinimapButtonPosition()
  if CMT_DB.showMinimapButton then
    minimapButton:Show()
  else
    minimapButton:Hide()
  end
  
  -- Update position when minimap size changes (Edit Mode resizing)
  Minimap:HookScript("OnSizeChanged", function()
    UpdateMinimapButtonPosition()
  end)
end

-- Call this after PLAYER_LOGIN
C_Timer.After(0.5, InitMinimapButton)

-- --------------------------------------------------------------------
-- Debug Window
-- --------------------------------------------------------------------
local function CreateDebugWindow()
  if debugFrame then 
    debugFrame:Show()
    return debugFrame
  end
  
  local f = CreateFrame("Frame", "CMT_DebugFrame", UIParent, "BasicFrameTemplateWithInset")
  f:SetSize(700, 500)
  f:SetPoint("CENTER")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetFrameStrata("DIALOG")
  f.title = f:CreateFontString(nil, "OVERLAY")
  f.title:SetFontObject("GameFontHighlight")
  f.title:SetPoint("LEFT", f.TitleBg, "LEFT", 5, 0)
  f.title:SetText("CMT Debug Log")
  
  -- Scroll frame
  local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", f.InsetBg or f, "TOPLEFT", 4, -8)
  scroll:SetPoint("BOTTOMRIGHT", f.InsetBg or f, "BOTTOMRIGHT", -3, 35) -- Leave room for buttons
  
  -- Edit box for text
  local editBox = CreateFrame("EditBox", nil, scroll)
  editBox:SetSize(scroll:GetWidth(), 5000) -- Tall enough for scrolling
  editBox:SetMultiLine(true)
  editBox:SetAutoFocus(false)
  editBox:SetFontObject("ChatFontNormal")
  editBox:SetScript("OnEscapePressed", function() f:Hide() end)
  scroll:SetScrollChild(editBox)
  f.text = editBox
  
  -- Copy All button
  local copyBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  copyBtn:SetSize(100, 22)
  copyBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 5, 5)
  copyBtn:SetText("Select All")
  copyBtn:SetScript("OnClick", function()
    editBox:SetFocus()
    editBox:HighlightText()
  end)
  
  -- Clear button
  local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  clearBtn:SetSize(100, 22)
  clearBtn:SetPoint("LEFT", copyBtn, "RIGHT", 5, 0)
  clearBtn:SetText("Clear Log")
  clearBtn:SetScript("OnClick", function()
    debugLog = {}
    editBox:SetText("")
  end)
  
  -- Close button
  f.CloseButton:SetScript("OnClick", function() f:Hide() end)
  
  debugFrame = f
  return f
end


-- --------------------------------------------------------------------
-- Slash
-- --------------------------------------------------------------------
SLASH_CMT1="/cmt"
SlashCmdList.CMT=function(msg)
  msg=(msg or ""):lower():gsub("^%s+",""):gsub("%s+$","")
  
  if msg=="health" then
    ShowHealthLogWindow()
    return
  end
  
  if msg=="clearpos" then
    iconPositions = {}
    print("CMT: Position tracking cleared - fresh baseline will be established")
    return
  end
  
  if msg=="apply" then
    for _,t in ipairs(TRACKERS) do
      local v=_G[t.name]
      if v then
        local layoutFunc = t.isBarType and layoutBars or layoutCustomGrid
        layoutFunc(v, t.key, v._CMT_baseOrder)
      end
    end
    print("CMT: Applied layouts")
    return
  end
  
  if msg=="recapture" or msg=="reset" then
    print("CMT: Recapturing icon order...")
    for _,t in ipairs(TRACKERS) do
      forceRecaptureOrder(t.key)
    end
    return
  end
  
  if msg=="rehook" or msg=="fix" then
    print("CMT: Re-initializing addon...")
    -- Clear all state
    for _,t in ipairs(TRACKERS) do
      local v=_G[t.name]
      if v then
        v._CMT_Hooked = nil
        v._CMT_pointsHooked = nil
        v._CMT_lifeHooked = nil
        v._CMT_applying = nil
        v._CMT_manualLayout = nil
        v._CMT_skipNextLayout = nil
        v._CMT_lastLayoutTime = nil
        v._CMT_wasVisible = nil
        v._CMT_desiredSig = nil
        v._CMT_pending = nil
        v._CMT_drift = nil
        -- Keep _CMT_baseOrder - don't lose icon order!
      end
    end
    -- Re-bootstrap
    bootstrap()
    -- Force apply after delay
    C_Timer.After(1, function()
      for _,t in ipairs(TRACKERS) do
        local v=_G[t.name]
        if v and v._CMT_baseOrder and #v._CMT_baseOrder > 0 then
          local layoutFunc = t.isBarType and layoutBars or layoutCustomGrid
          layoutFunc(v, t.key, v._CMT_baseOrder)
        end
      end
      print("CMT: Re-initialization complete")
    end)
    return
  end
  
  if msg=="resetwarning" or msg=="resetdismiss" then
    CMT_DB.editModeSetupDismissed = false
    print("CMT: Reset Edit Mode setup warning - it will show again on next login if settings are incorrect")
    return
  end
  
  if msg=="resetanchorwarning" then
    CMT_DB.anchorWarningDismissed = false
    print("CMT: Reset anchor warning - it will show again on next login if frames are still anchored to Essential Cooldowns")
    return
  end
  
  if msg=="checkanchors" then
    local anchoredFrames = CheckForAnchoredFrames()
    if #anchoredFrames == 0 then
      print("CMT: No frames are currently anchored to Essential Cooldowns")
    else
      print("CMT: The following frames are anchored to Essential Cooldowns:")
      for _, info in ipairs(anchoredFrames) do
        print("  • " .. info.name)
      end
      print("Use '/cmt fixanchors' to automatically fix these")
    end
    return
  end
  
  if msg=="fixanchors" then
    local fixed = FixAnchoredFrames()
    if not fixed then
      print("CMT: No anchored frames to fix")
    end
    return
  end
  
  if msg=="clear" then
    print("CMT: Clearing all addon state - you'll need to recapture!")
    for _,t in ipairs(TRACKERS) do
      local v=_G[t.name]
      if v then
        -- Clear EVERYTHING
        v._CMT_Hooked = nil
        v._CMT_pointsHooked = nil
        v._CMT_lifeHooked = nil
        v._CMT_applying = nil
        v._CMT_manualLayout = nil
        v._CMT_skipNextLayout = nil
        v._CMT_lastLayoutTime = nil
        v._CMT_wasVisible = nil
        v._CMT_desiredSig = nil
        v._CMT_pending = nil
        v._CMT_drift = nil
        v._CMT_baseOrder = nil  -- Clear this too
      end
    end
    print("CMT: State cleared. Please /reload, then /cmt recapture")
    return
  end
  
  if msg=="dump" or msg=="debug" then
    print("=== CMT Saved Settings ===")
    print("Current Profile: " .. (CMT_CharDB.currentProfile or "Default"))
    local profile = GetCurrentProfile()
    for _, t in ipairs(TRACKERS) do
      if profile[t.key] then
        print("\n[" .. t.displayName .. "]")
        for setting, value in pairs(profile[t.key]) do
          if type(value) == "table" then
            print("  " .. setting .. ": {" .. table.concat(value, ", ") .. "}")
          else
            print("  " .. setting .. ": " .. tostring(value))
          end
        end
      end
    end
    print("\nUse /cmtdebug on to enable detailed logging")
    return
  end
  
  if msg=="dumpall" then
    print("=== ALL CMT Profiles ===")
    for profileName, profileData in pairs(CMT_DB.profiles) do
      print("\n==== Profile: " .. profileName .. " ====")
      for _, t in ipairs(TRACKERS) do
        if profileData[t.key] then
          print("\n[" .. t.displayName .. "]")
          for setting, value in pairs(profileData[t.key]) do
            if type(value) == "table" then
              print("  " .. setting .. ": {" .. table.concat(value, ", ") .. "}")
            else
              print("  " .. setting .. ": " .. tostring(value))
            end
          end
        end
      end
    end
    return
  end
  
  if msg=="patchnotes" or msg=="whatsnew" or msg=="news" then
    ShowPatchNotesDialog(true)  -- forceShow=true for manual slash command
    return
  end
  
  if msg=="verbose" or msg=="showfixes" then
    VERBOSE_FIXES = not VERBOSE_FIXES
    if VERBOSE_FIXES then
      print("|cff00ff00CMT:|r Verbose mode enabled - will show guardian fix messages (resets on /reload)")
    else
      print("|cff00ff00CMT:|r Verbose mode disabled - guardian will fix issues silently")
    end
    return
  end
  
  if msg=="posdebug" or msg=="pdebug" then
    POSITION_DEBUG = not POSITION_DEBUG
    if POSITION_DEBUG then
      print("|cffff9900CMT:|r Position debug ENABLED - will show drift/restore events")
      print("  Look for |cffff9900CMT POS:|r messages in chat")
      print("  Also monitoring screen position changes via GetCenter()")
      local settlingRemaining = _positionSettlingUntil - GetTime()
      if settlingRemaining > 0 then
        print(string.format("  |cffff0000SETTLING PERIOD ACTIVE|r - %.1f seconds remaining (position restoration disabled)", settlingRemaining))
      else
        print("  Settling period complete - position restoration active")
      end
      -- Reset screen position tracking so we start fresh
      for _, t in ipairs(TRACKERS) do
        local v = _G[t.name]
        if v then
          v._CMT_lastScreenPos = nil
        end
      end
      -- Show current known good positions
      for _, t in ipairs(TRACKERS) do
        local v = _G[t.name]
        if v then
          local pos = v._CMT_knownGoodPosition
          if pos then
            local _, _, _, currentX, currentY = v:GetPoint(1)
            local cx, cy = v:GetCenter()
            print(string.format("  [%s] Known good: %.1f, %.1f | Current anchor: %.1f, %.1f | Screen: %.1f, %.1f", 
              t.key, pos.x, pos.y, currentX or 0, currentY or 0, cx or 0, cy or 0))
          else
            print(string.format("  [%s] No known good position saved", t.key))
          end
        end
      end
    else
      print("|cffff9900CMT:|r Position debug disabled")
    end
    return
  end
  
  if msg=="poswatch" or msg=="pwatch" then
    POSITION_WATCH = not POSITION_WATCH
    if POSITION_WATCH then
      print("|cffff00ffCMT:|r Position WATCH ENABLED - will show ALL SetPoint/ClearAllPoints calls")
      print("  Look for |cffff00ffCMT WATCH:|r messages in chat")
      print("  WARNING: This can be very spammy!")
    else
      print("|cffff00ffCMT:|r Position watch disabled")
    end
    return
  end
  
  if msg=="posshow" or msg=="pshow" then
    print("|cffff9900CMT:|r Current tracker positions:")
    print("  Edit Mode Active: " .. tostring(IsEditModeActive()))
    local settlingRemaining = _positionSettlingUntil - GetTime()
    if settlingRemaining > 0 then
      print(string.format("  |cffff0000Settling Period:|r %.1f seconds remaining", settlingRemaining))
    else
      print("  Settling Period: Complete")
    end
    for _, t in ipairs(TRACKERS) do
      local v = _G[t.name]
      if v then
        local pos = v._CMT_knownGoodPosition
        local staticPos = v._CMT_staticPosition
        local point, relativeTo, relativePoint, currentX, currentY = v:GetPoint(1)
        local cx, cy = v:GetCenter()
        local shown = v:IsShown() and "shown" or "hidden"
        
        -- Get relative frame name
        local relativeToName = "nil"
        if relativeTo then
          relativeToName = relativeTo.GetName and relativeTo:GetName() or tostring(relativeTo)
        end
        
        print(string.format("  [%s] (%s)", t.key, shown))
        print(string.format("    Anchor: %s relative to %s at %s", point or "?", relativeToName, relativePoint or "?"))
        print(string.format("    Offset: %.1f, %.1f | Screen center: %.1f, %.1f", 
          currentX or 0, currentY or 0, cx or 0, cy or 0))
        
        if pos then
          local driftX = currentX and math.abs(currentX - pos.x) or 0
          local driftY = currentY and math.abs(currentY - pos.y) or 0
          local driftStr = (driftX > 0.5 or driftY > 0.5) and "|cffff0000DRIFTED|r" or "|cff00ff00OK|r"
          print(string.format("    Known good: %.1f, %.1f | %s", pos.x, pos.y, driftStr))
        else
          print("    |cffff0000No known good position!|r")
        end
        
        if staticPos then
          local staticDriftX = currentX and math.abs(currentX - staticPos.x) or 0
          local staticDriftY = currentY and math.abs(currentY - staticPos.y) or 0
          local staticDriftStr = (staticDriftX > 0.5 or staticDriftY > 0.5) and "|cffff0000DRIFTED|r" or "|cff00ff00OK|r"
          print(string.format("    Static: %.1f, %.1f | %s", staticPos.x, staticPos.y, staticDriftStr))
        end
        
        if v._CMT_lastScreenPos then
          print(string.format("    Last screen: %.1f, %.1f", v._CMT_lastScreenPos.x, v._CMT_lastScreenPos.y))
        end
      end
    end
    return
  end
  
  if msg=="posreset" or msg=="preset" then
    print("|cffff9900CMT:|r Resetting known good positions to current positions...")
    for _, t in ipairs(TRACKERS) do
      local v = _G[t.name]
      if v and v:IsShown() then
        local point, relativeTo, relativePoint, x, y = v:GetPoint(1)
        if point and x and y then
          v._CMT_knownGoodPosition = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            x = x,
            y = y
          }
          print(string.format("  [%s] Set known good to: %.1f, %.1f", t.key, x, y))
        end
      end
    end
    return
  end
  
  if msg=="poslock" or msg=="plock" then
    print("|cffff9900CMT:|r Locking STATIC positions (won't auto-update)...")
    for _, t in ipairs(TRACKERS) do
      local v = _G[t.name]
      if v and v:IsShown() then
        local point, relativeTo, relativePoint, x, y = v:GetPoint(1)
        if point and x and y then
          v._CMT_staticPosition = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            x = x,
            y = y
          }
          print(string.format("  [%s] Locked static position: %.1f, %.1f", t.key, x, y))
        end
      end
    end
    print("  Use /cmt posshow to compare current vs static position")
    return
  end
  
  if msg=="possettle" or msg=="settle" then
    if IsSettlingPeriod() then
      _positionSettlingUntil = 0
      print("|cffff9900CMT:|r Settling period ended manually. Capturing current positions...")
      for _, t in ipairs(TRACKERS) do
        local v = _G[t.name]
        if v and v:IsShown() then
          local point, relativeTo, relativePoint, x, y = v:GetPoint(1)
          local cx, cy = v:GetCenter()
          if point and x and y then
            v._CMT_knownGoodPosition = {
              point = point,
              relativeTo = relativeTo,
              relativePoint = relativePoint,
              x = x,
              y = y
            }
            v._CMT_positionSettled = true
            print(string.format("  [%s] Captured: offset %.1f,%.1f screen %.1f,%.1f", 
              t.key, x, y, cx or 0, cy or 0))
          end
        end
      end
      print("  Position restoration is now active")
    else
      print("|cffff9900CMT:|r Settling period already complete")
    end
    return
  end
  
  -- Items tracker commands (v3.1.0)
  if msg=="additems" or msg:match("^additem%s+") then
    local itemID = tonumber(msg:match("^additem%s+(%d+)")) or tonumber(msg:match("^additems%s+(%d+)"))
    if itemID then
      AddCustomItem(itemID)
    else
      print("CMT: Usage: /cmt additem <itemID>")
      print("Example: /cmt additem 211880 (Algari Healing Potion)")
    end
    return
  end
  
  if msg:match("^removeitem%s+") then
    local itemID = tonumber(msg:match("^removeitem%s+(%d+)"))
    if itemID then
      RemoveCustomItem(itemID)
    else
      print("CMT: Usage: /cmt removeitem <itemID>")
    end
    return
  end
  
  if msg:match("^addspell%s+") then
    local spellID = tonumber(msg:match("^addspell%s+(%d+)"))
    if spellID then
      AddCustomSpell(spellID)
    else
      print("CMT: Usage: /cmt addspell <spellID>")
      print("Example: /cmt addspell 20549 (War Stomp)")
      print("Find spell IDs on Wowhead or use /dump C_Spell.GetSpellInfo(\"Spell Name\")")
    end
    return
  end
  
  if msg:match("^removespell%s+") then
    local spellID = tonumber(msg:match("^removespell%s+(%d+)"))
    if spellID then
      RemoveCustomSpell(spellID)
    else
      print("CMT: Usage: /cmt removespell <spellID>")
    end
    return
  end
  
  if msg=="listitems" then
    print("CMT: Currently tracked entries for current spec:")
    local specEntries = GetCurrentSpecEntries()
    if specEntries then
      if #specEntries == 0 then
        print("  (none)")
      else
        for _, entry in ipairs(specEntries) do
          if entry.type == "item" then
            local itemName = GetItemInfo(entry.id)
            print(string.format("  Item: %s (ID: %d)", itemName or "Unknown", entry.id))
          elseif entry.type == "spell" then
            local spellInfo = C_Spell.GetSpellInfo(entry.id)
            local spellName = spellInfo and spellInfo.name or "Unknown"
            print(string.format("  Spell: %s (ID: %d)", spellName, entry.id))
          end
        end
      end
    end
    return
  end
  
  if msg=="listitems_old" then
    print("CMT: Currently tracked items for current spec:")
    local specItems = GetCurrentSpecItems()
    if specItems then
      if #specItems == 0 then
        print("  (none)")
      else
        for _, itemID in ipairs(specItems) do
          local itemName = GetItemInfo(itemID)
          print(string.format("  - %s (ID: %d)", itemName or "Unknown", itemID))
        end
      end
    else
      print("  (none)")
    end
    return
  end
  
  if msg=="clearitems" then
    ClearAllCustomItems()
    return
  end
  
  -- Masque support commands (v4.6.0)
  if msg=="masque" or msg=="msq" then
    if MasqueModule and MasqueModule.Toggle then
      MasqueModule.Toggle()
    else
      print("|cff00ff00CMT:|r Masque support not available")
    end
    return
  end
  
  if msg=="masque status" then
    if MasqueModule and MasqueModule.IsAvailable then
      local available = MasqueModule.IsAvailable()
      local enabled = CMT_DB.masqueEnabled
      if not available then
        print("|cff00ff00CMT:|r Masque addon is |cffff0000not installed|r")
      elseif enabled then
        print("|cff00ff00CMT:|r Masque support is |cff00ff00enabled|r - use /msq to configure skins")
        print("|cff00ff00CMT:|r API initialized: " .. tostring(MasqueModule.API ~= nil))
        print("|cff00ff00CMT:|r Groups created: " .. (MasqueModule.groups and #(function() local c=0 for _ in pairs(MasqueModule.groups) do c=c+1 end return c end)() or 0))
        local iconCount = 0
        for _ in pairs(MasqueModule.registeredIcons or {}) do iconCount = iconCount + 1 end
        print("|cff00ff00CMT:|r Registered icons: " .. iconCount)
      else
        print("|cff00ff00CMT:|r Masque support is |cffff0000disabled|r - use /cmt masque to enable")
      end
    else
      print("|cff00ff00CMT:|r Masque module not loaded")
    end
    return
  end
  
  if msg=="masque debug" then
    print("|cff00ff00CMT Masque Debug:|r")
    print("  API: " .. tostring(MasqueModule.API))
    print("  Global Enabled: " .. tostring(CMT_DB.masqueEnabled))
    print("  Available: " .. tostring(MasqueModule.IsAvailable()))
    
    -- Count groups
    local groupCount = 0
    for key, group in pairs(MasqueModule.groups or {}) do
      groupCount = groupCount + 1
      print("  Group [" .. key .. "]: " .. tostring(group))
    end
    print("  Total groups: " .. groupCount)
    
    -- Count registered icons
    local iconCount = 0
    local iconsByTracker = {}
    for icon, trackerKey in pairs(MasqueModule.registeredIcons or {}) do
      iconCount = iconCount + 1
      iconsByTracker[trackerKey] = (iconsByTracker[trackerKey] or 0) + 1
    end
    print("  Total registered icons: " .. iconCount)
    for tracker, count in pairs(iconsByTracker) do
      print("    " .. tracker .. ": " .. count)
    end
    
    -- Check per-tracker status
    print("  Per-tracker status:")
    for _, t in ipairs(TRACKERS) do
      local isEnabled = MasqueModule.IsEnabledForTracker and MasqueModule.IsEnabledForTracker(t.key)
      local masqueDisabled = GetSetting(t.key, "masqueDisabled") or false
      local savedAspect = GetSetting(t.key, "masqueSavedAspect")
      local currentAspect = GetSetting(t.key, "aspectRatio") or "1:1"
      print(string.format("    %s: enabled=%s, disabled=%s, aspect=%s, saved=%s", 
        t.key, tostring(isEnabled), tostring(masqueDisabled), currentAspect, tostring(savedAspect)))
    end
    
    -- Check if trackers have icons
    for _, t in ipairs(TRACKERS) do
      local viewer = _G[t.name]
      if viewer then
        local baseOrderCount = viewer._CMT_baseOrder and #viewer._CMT_baseOrder or 0
        print("  Tracker [" .. t.key .. "] baseOrder: " .. baseOrderCount .. " icons")
      else
        print("  Tracker [" .. t.key .. "] NOT FOUND")
      end
    end
    return
  end
  
  if msg=="masque register" then
    print("|cff00ff00CMT:|r Force registering all icons with Masque...")
    if MasqueModule.API then
      for _, t in ipairs(TRACKERS) do
        if t.key == "items" then
          MasqueModule.RegisterCustomTracker()
        else
          MasqueModule.RegisterTracker(t.key)
        end
      end
      local iconCount = 0
      for _ in pairs(MasqueModule.registeredIcons or {}) do iconCount = iconCount + 1 end
      print("|cff00ff00CMT:|r Registered " .. iconCount .. " icons")
    else
      print("|cff00ff00CMT:|r Masque API not initialized - try /cmt masque first")
    end
    return
  end
  
  -- Persistent buff display commands (v3.2.0)
  if msg=="persistentbuffs" or msg=="pbuffs" then
    local enabled = GetSetting("buffs", "persistentDisplay")
    enabled = not enabled
    SetSetting("buffs", "persistentDisplay", enabled)
    RefreshPersistentBuffDisplay()
    
    if enabled then
      print("|cff00ff00CMT:|r Persistent buff display |cff00ff00enabled|r - inactive buffs will be desaturated")
    else
      print("|cff00ff00CMT:|r Persistent buff display |cffff0000disabled|r - buffs show normally")
    end
    return
  end
  
  
  local p=CreateConfigPanel(); if p:IsShown() then HideUIPanel(p) else ShowUIPanel(p) end
end

-- Add /cdm as a convenient shortcut to open Blizzard's Cooldown Manager settings
SLASH_CDM1="/cdm"
SlashCmdList.CDM=function()
  -- Toggle the Cooldown Settings panel
  if CooldownViewerSettings then
    CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
  else
    print("CMT: Cooldown Settings panel not found")
  end
end

-- Add /cmtpanel command for panel management
SLASH_CMTPANEL1="/cmtpanel"
SlashCmdList.CMTPANEL=function(msg)
  msg = (msg or ""):lower():gsub("^%s+",""):gsub("%s+$","")
  
  if msg == "reset" then
    -- Reset the panel position to center of screen
    CMT_DB.hubPosition = nil
    local panel = _G["CMT_ConfigPanel"]
    if panel then
      panel:ClearAllPoints()
      panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
      print("|cff00ff00CMT:|r Control panel position reset to center of screen.")
      if not panel:IsShown() then
        ShowUIPanel(panel)
      end
    else
      print("|cff00ff00CMT:|r Panel will be centered on next open.")
    end
  else
    print("|cff00ff00CMT Panel Commands:|r")
    print("  /cmtpanel reset - Reset panel position to center of screen")
  end
end

SLASH_CMTDEBUG1="/cmtdebug"
SlashCmdList.CMTDEBUG=function(msg)
  msg = (msg or ""):lower():gsub("^%s+",""):gsub("%s+$","")
  
  if msg == "on" then
    DEBUG_MODE = true
    debugLog = {}
    print("CMT: Debug mode enabled. Use /cmtdebug show to view log.")
  elseif msg == "off" then
    DEBUG_MODE = false
    if debugFrame then debugFrame:Hide() end
    print("CMT: Debug mode disabled.")
  elseif msg == "show" then
    if not DEBUG_MODE then
      print("CMT: Debug mode is off. Use /cmtdebug on first.")
      return
    end
    local f = CreateDebugWindow()
    f.text:SetText(table.concat(debugLog, "\n"))
    f:Show()
  elseif msg == "clear" then
    debugLog = {}
    if debugFrame then debugFrame.text:SetText("") end
    print("CMT: Debug log cleared.")
  else
    -- Toggle or show status
    if DEBUG_MODE then
      local f = CreateDebugWindow()
      f.text:SetText(table.concat(debugLog, "\n"))
      if f:IsShown() then
        f:Hide()
      else
        f:Show()
      end
    else
      print("CMT Debug Commands:")
      print("  /cmtdebug on   - Enable debug mode")
      print("  /cmtdebug off  - Disable debug mode")
      print("  /cmtdebug show - Show debug window")
      print("  /cmtdebug      - Toggle debug window (when enabled)")
    end
  end
end

SLASH_CMTINSPECT1="/cmtinspect"
SlashCmdList.CMTINSPECT=function()
  local viewer = _G["BuffBarCooldownViewer"]
  if not viewer then
    print("CMT: BuffBarCooldownViewer not found!")
    return
  end
  
  print("=== BuffBarCooldownViewer Structure ===")
  print("Viewer:", viewer:GetName() or "unnamed")
  print("NumChildren:", viewer:GetNumChildren() or 0)
  
  local numChildren = viewer:GetNumChildren() or 0
  for i = 1, math.min(numChildren, 5) do -- Only show first 5
    local child = select(i, viewer:GetChildren())
    if child then
      print("\n--- Bar", i, "---")
      print("  Name:", child:GetName() or "unnamed")
      print("  Type:", child:GetObjectType())
      print("  Size:", string.format("%.1f x %.1f", child:GetWidth() or 0, child:GetHeight() or 0))
      print("  Shown:", child:IsShown())
      
      -- Check for common fields
      print("  child.Icon:", type(child.Icon))
      print("  child.Bar:", type(child.Bar))
      print("  child.StatusBar:", type(child.StatusBar))
      
      -- List child frames
      local numGrandChildren = (child.GetNumChildren and child:GetNumChildren()) or 0
      if numGrandChildren > 0 then
        print("  Child Frames:", numGrandChildren)
        for j = 1, math.min(numGrandChildren, 3) do
          local grandchild = select(j, child:GetChildren())
          if grandchild then
            print("    ", j, grandchild:GetObjectType(), grandchild:GetName() or "unnamed")
          end
        end
      end
    end
  end
  print("=== End Structure ===")
end

-- Shortcut for /reload
SLASH_RL1="/rl"
SlashCmdList.RL=function()
  ReloadUI()
end

