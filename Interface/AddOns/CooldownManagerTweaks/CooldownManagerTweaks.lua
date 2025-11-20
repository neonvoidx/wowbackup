-- Cooldown Manager Tweaks (Retail 11.x-12.x, Lua 5.1)
-- Grid re-layout for Blizzard cooldown viewers with preserved order,
-- optional Reverse, custom row pattern, alignment, and spacing.
-- v2.8.0: FIX Utility Frame Order changing with abilities that morph on essentials bar.
-- v3.0.1: FIX Buff icons jumping when buffs refresh/update (same morph fix as utility)
-- v3.0.2: FIX Aspect ratio reverting on buff refresh - now hooks new children and retries aspect application
-- v3.0.3: FIX Aspect ratio not applying when entering combat - now applies with retries on visibility changes
local ADDON_NAME = "CooldownManagerTweaks"
local VERSION    = "3.0.3"

-- Debug mode (toggle with /cmtdebug)
local DEBUG_MODE = false
local debugLog = {}
local debugFrame = nil

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
  -- Note: BuffIconCooldownViewer is Blizzard's buff tracker in the Cooldown Manager system
  -- It shows player buffs from Blizzard's curated list, positioned by Blizzard
  -- We detect and layout these the same way we do Essential/Utility cooldowns
}

-- Saved vars (declared in TOC: ## SavedVariables: CMT_DB)
CMT_DB = CMT_DB or {}
CMT_DB.profiles = CMT_DB.profiles or {}
CMT_DB.currentProfile = CMT_DB.currentProfile or "Default"
CMT_DB.specProfiles = CMT_DB.specProfiles or {} -- Maps specID to profileName
CMT_DB.showMinimapButton = (CMT_DB.showMinimapButton == nil) and true or CMT_DB.showMinimapButton -- Default to true
CMT_DB.editModeSetupDismissed = CMT_DB.editModeSetupDismissed or false -- Track if user dismissed Edit Mode setup

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
  zoom          = 1.0,            -- Icon texture zoom (1.0 to 3.0) - zooms into center
  aspectRatio   = "1:1",          -- Icon aspect ratio: "1:1", "16:9", "9:16", "21:9", "4:3", "3:4"
  layoutDirection = "ROWS",       -- "ROWS" or "COLUMNS"
  borderAlpha   = 1.0,            -- Border/frame alpha (0.0 to 1.0) - 0 = invisible, 1 = fully visible
  cooldownTextScale = 1.0,        -- Cooldown text scale multiplier (0.5 to 2.0)
  -- Bar-specific settings
  barIconSide   = "LEFT",     -- "LEFT" or "RIGHT"
  barSpacing    = 2,          -- vertical spacing between bars
  barIconGap    = 0,          -- horizontal gap between icon and bar
}

local function ensureDefaults()
  -- Ensure basic structure exists first
  CMT_DB.profiles = CMT_DB.profiles or {}
  CMT_DB.currentProfile = CMT_DB.currentProfile or "Default"
  CMT_DB.specProfiles = CMT_DB.specProfiles or {}  -- Initialize spec profiles mapping
  
  -- Ensure current profile exists
  local profileName = CMT_DB.currentProfile
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

-- Helper functions for tracker info (must be defined early)
local function getTrackerNameByKey(key)
  for _,t in ipairs(TRACKERS) do if t.key==key then return t.name end end
end

local function getTrackerInfoByKey(key)
  for _,t in ipairs(TRACKERS) do if t.key==key then return t end end
end

local _fastRepairUntil = 0

-- --------------------------------------------------------------------
-- Helpers
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
      parts[#parts+1] = r2(f:GetLeft() or 0) .. ":" .. r2(f:GetTop() or 0) .. ":" ..
                        r2(f:GetWidth() or 0) .. "x" .. r2(f:GetHeight() or 0)
    end
  end
  return table.concat(parts, "|")
end

local function setApplying(viewer, on) viewer._CMT_applying = on and true or nil end

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
    -- Parse aspect ratio
    local aspectW, aspectH = 1, 1
    if aspectRatio and type(aspectRatio) == "string" then
      local w, h = aspectRatio:match("^(%d+):(%d+)$")
      if w and h then
        aspectW = tonumber(w)
        aspectH = tonumber(h)
      end
    end
    
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

local function GetCurrentProfile()
  local profileName = CMT_DB.currentProfile or "Default"
  CMT_DB.profiles[profileName] = CMT_DB.profiles[profileName] or {}
  return CMT_DB.profiles[profileName]
end

local function GetSetting(key, name)
  local profile = GetCurrentProfile()
  local value = nil
  if profile[key] and profile[key][name] ~= nil then
    value = profile[key][name]
  end
  -- Debug: Show what we're retrieving
  if DEBUG_MODE then
    dprint("CMT: GetSetting(%s, %s) -> %s from profile '%s'", 
      tostring(key), tostring(name), tostring(value), CMT_DB.currentProfile or "Default")
  end
  return value
end

local function SetSetting(key, name, val)
  local profile = GetCurrentProfile()
  profile[key] = profile[key] or {}
  profile[key][name] = val
  
  -- Verify the value is actually in CMT_DB (only log errors)
  if DEBUG_MODE then
    local profileName = CMT_DB.currentProfile or "Default"
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

local function copyArray(src) local out = {}; for i=1,#src do out[i]=src[i] end; return out end

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
  
  -- For buffs: Collect ALL direct children (shown and hidden) to maintain positions
  -- This ensures that when a buff falls off, its spot stays reserved
  if key == "buffs" and viewer and viewer.GetNumChildren then
    local n = viewer:GetNumChildren() or 0
    dprint("getBlizzardOrderedIcons [%s]: checking %d direct children (including hidden)", key, n)
    
    for i=1,n do
      local c = select(i, viewer:GetChildren())
      if c and isIcon(c) then
        shown[#shown+1] = c
        dprint("  Child %d is icon: shown=%s (added as #%d)", i, tostring(c:IsShown()), #shown)
      elseif c then
        dprint("  Child %d: not an icon", i)
      end
    end
    
    dprint("getBlizzardOrderedIcons [%s]: collected %d buff icons (shown+hidden) in child order", key, #shown)
    return shown
  end
  
  -- For non-buffs: Use standard collection
  -- Filter to only shown icons
  for _,f in ipairs(all) do 
    if f:IsShown() then shown[#shown+1]=f end 
  end
  
  dprint("getBlizzardOrderedIcons [%s]: collected %d icons, %d shown", 
    tostring(key), #all, #shown)
  
  -- For other trackers: Sort by visual position (reading order: top-to-bottom, left-to-right)
  table.sort(shown, sortVisual)
  
  return shown
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
    
    -- Get settings
    local iconSize = GetSetting(key,"iconSize") or 40
    local zoom = GetSetting(key,"zoom") or 1.0
    local aspectRatio = GetSetting(key,"aspectRatio") or "1:1"
    local borderAlpha = GetSetting(key,"borderAlpha") or 1.0
    local cooldownTextScale = GetSetting(key,"cooldownTextScale") or 1.0
    
    -- Calculate icon dimensions
    local iconWidth = iconSize
    local iconHeight = iconSize
    if aspectRatio and aspectRatio ~= "1:1" then
      local aspectW, aspectH = aspectRatio:match("^(%d+):(%d+)$")
      if aspectW and aspectH then
        aspectW, aspectH = tonumber(aspectW), tonumber(aspectH)
        if aspectW and aspectH then
          if aspectW > aspectH then
            iconWidth = iconSize
            iconHeight = (iconSize * aspectH) / aspectW
          elseif aspectH > aspectW then
            iconWidth = (iconSize * aspectW) / aspectH
            iconHeight = iconSize
          end
        end
      end
    end
    
    -- Apply settings to all visible icons
    local allIcons = getBlizzardOrderedIcons(viewer, false, false, key)
    for _, icon in ipairs(allIcons) do
      if icon and icon:IsShown() then
        icon:SetSize(iconWidth, iconHeight)
        applyBorderAlpha(icon, borderAlpha)
        applyCooldownTextScale(icon, cooldownTextScale)
        applyIconAspectAndZoom(icon, aspectRatio, zoom)
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
  local zoom   = GetSetting(key,"zoom") or 1.0
  local aspectRatio = GetSetting(key,"aspectRatio") or "1:1"
  local layoutDirection = GetSetting(key,"layoutDirection") or "ROWS"
  
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
    local aspectW, aspectH = aspectRatio:match("^(%d+):(%d+)$")
    if aspectW and aspectH then
      aspectW, aspectH = tonumber(aspectW), tonumber(aspectH)
      if aspectW and aspectH then
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
  end
  
  dprint("CMT: Calculated icon dimensions for [%s]: %.1fx%.1f (aspect=%s, baseSize=%d)", 
    key, iconWidth, iconHeight, aspectRatio, baseSize)
  
  -- Apply aspect ratio to all icons using our calculated dimensions
  for _, icon in ipairs(ordered) do
    icon:SetSize(iconWidth, iconHeight)
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
          
          icon:ClearAllPoints()
          icon:SetPoint("TOPLEFT", viewer, "TOPLEFT", x, -y_pos)
          
          -- Debug: Show first few icon placements in column mode
          if layoutDirection == "COLUMNS" and rowIdx <= 2 and idx <= 4 then
            dprint("CMT Column [%s]: grid[%d][%d] = icon at x=%.1f, y=%.1f (col=%d, row=%d)", 
              key, rowIdx, idx, x, -y_pos, idx, rowIdx)
          end
          
          -- Apply border alpha (controls icon frame/border visibility)
          local borderAlpha = GetSetting(key,"borderAlpha") or 1.0
          applyBorderAlpha(icon, borderAlpha)
          
          -- Apply cooldown text scale
          local cooldownTextScale = GetSetting(key,"cooldownTextScale") or 1.0
          applyCooldownTextScale(icon, cooldownTextScale)
          
          -- Apply texture zoom and aspect cropping (icon frame already resized above)
          applyIconAspectAndZoom(icon, aspectRatio, zoom)
          
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
  
  -- CRITICAL FIX: Apply settings to ALL visible icons, not just ones in our ordered list
  -- This ensures new buffs that appear get aspect ratio/zoom even if they're not in baseOrder yet
  local allCurrentIcons = getBlizzardOrderedIcons(viewer, false, false, key)
  for _, icon in ipairs(allCurrentIcons) do
    if icon and icon:IsShown() then
      -- Apply size
      icon:SetSize(iconWidth, iconHeight)
      
      -- Apply border alpha
      local borderAlpha = GetSetting(key,"borderAlpha") or 1.0
      applyBorderAlpha(icon, borderAlpha)
      
      -- Apply cooldown text scale
      local cooldownTextScale = GetSetting(key,"cooldownTextScale") or 1.0
      applyCooldownTextScale(icon, cooldownTextScale)
      
      -- Apply texture zoom and aspect
      applyIconAspectAndZoom(icon, aspectRatio, zoom)
    end
  end
  
  end) -- End of pcall for layoutCustomGrid
  
  setApplying(viewer,false)
  
  -- Set grace period to allow Blizzard's post-layout cleanup without triggering drift
  viewer._CMT_blizzCleanup = true
  C_Timer.After(0.2, function()
    if viewer then viewer._CMT_blizzCleanup = nil end
  end)
  
  if not success then
    dprint("CMT ERROR: layoutCustomGrid for [%s] failed: %s", key, tostring(err))
    return false
  end
  
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
  return true
end

-- --------------------------------------------------------------------
-- Watchdog
-- --------------------------------------------------------------------
local function ensureFrozen(viewer, key)
  if not viewer or not viewer:IsShown() or not viewer._CMT_desiredSig then return end
  
  -- Prevent rapid re-layout loops - only check once every 0.5 seconds
  local now = GetTime()
  if viewer._CMT_lastEnsureFrozen and (now - viewer._CMT_lastEnsureFrozen) < 0.5 then
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
      _fastRepairUntil = GetTime()+0.2
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

local function relayoutOne(key)
  local trackerInfo = getTrackerInfoByKey(key)
  if trackerInfo then
    local v=_G[trackerInfo.name]
    if v then
      -- Set flag to prevent the Layout hook from overriding this manual change
      v._CMT_manualLayout = true
      
      if trackerInfo.isBarType then
        local success, err = pcall(layoutBars, v, key, baselineOrderFor(v))
        if not success then
          print("CMT ERROR in layoutBars: " .. tostring(err))
        end
      else
        local success, err = pcall(layoutCustomGrid, v, key, baselineOrderFor(v))
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
end

local function hookViewer(viewer, key)
  if viewer._CMT_Hooked then return end
  viewer._CMT_Hooked=true; viewer._CMT_Key=key
  
  local trackerInfo = getTrackerInfoByKey(key)
  local layoutFunc = (trackerInfo and trackerInfo.isBarType) and layoutBars or layoutCustomGrid
  local isBarType = trackerInfo and trackerInfo.isBarType

  -- Capture Blizzard baseline ONLY here (never from our own layout)
  if type(viewer.Layout)=="function" then
    hooksecurefunc(viewer,"Layout", function(s)
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
      
      -- Check if this is a rapid spam (multiple Layout calls within 0.2 seconds)
      -- BUT: Always process if icons morphed (must reapply layout after morph)
      local now = GetTime()
      if s._CMT_lastLayoutTime and (now - s._CMT_lastLayoutTime) < 0.2 and not iconsMorphed then
        -- Rapid spam detected and no morph - completely ignore it
        dprint("CMT: Ignoring rapid Layout spam for [%s] (%.3fs since last)", key, now - s._CMT_lastLayoutTime)
        return
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
      -- 1. No baseline exists yet
      -- 2. Icon count changed (icons added/removed)
      -- BUT NOT: Icon identities changed (ability morphing) - preserve custom order!
      local needsRecapture = not s._CMT_baseOrder or #s._CMT_baseOrder == 0 or #currentIcons ~= #s._CMT_baseOrder
      
      -- If count is same but icon references changed, check if it's ACTUAL morphing
      -- (same spell IDs, different icon frames) vs REORDERING (different spell IDs)
      if not needsRecapture and s._CMT_baseOrder and #currentIcons == #s._CMT_baseOrder then
        -- Build a map from current icons (visual order from Blizzard)
        -- For buffs: use auraInstanceID as identifier
        -- For cooldowns: use spellID as identifier
        local currentIdentifierMap = {}
        for i = 1, #currentIcons do
          local identifier = currentIcons[i].auraInstanceID or currentIcons[i].spellID
          if identifier then
            -- Store the icon frame for each identifier
            currentIdentifierMap[identifier] = currentIcons[i]
          end
        end
        
        -- Build a set of identifiers from cached baseline (our custom order)
        local baselineIdentifiers = {}
        for i = 1, #s._CMT_baseOrder do
          local identifier = s._CMT_baseOrder[i].auraInstanceID or s._CMT_baseOrder[i].spellID
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
            local identifier = oldFrame.auraInstanceID or oldFrame.spellID
            local newFrame = currentIdentifierMap[identifier]
            
            -- If the frame reference changed for this identifier, update it
            if newFrame and newFrame ~= oldFrame then
              morphDetected = true
              dprint("CMT: Updating frame reference for %s %d at position %d in [%s]", 
                oldFrame.auraInstanceID and "aura" or "spell", identifier or 0, i, key)
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
          -- Identifiers don't match - icons were added/removed, need to recapture
          dprint("CMT: Identifier set changed for [%s] - icons added/removed", key)
          needsRecapture = true
        end
      end
      
      if needsRecapture then
        s._CMT_baseOrder = currentIcons
        s._CMT_desiredSig = nil
        dprint("CMT: Recaptured baseline for [%s]: %d icons (was %d)", 
          key, #currentIcons, s._CMT_baseOrder and #s._CMT_baseOrder or 0)
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
        end
      end)
      
      -- Also set fast repair mode so the watchdog catches any further drift immediately
      _fastRepairUntil = GetTime() + 0.3
    end)
  end

  -- Re-layout from cached baseline; never overwrite it here
  -- Add recursion protection to prevent feedback loops
  -- CRITICAL: Don't pass orderFromBlizz parameter - always use cached _CMT_baseOrder
  viewer:HookScript("OnSizeChanged", function(s)
    if not s._CMT_applying and s._CMT_baseOrder then
      layoutFunc(s, key, nil) -- nil = use cached order
    end
  end)
  viewer:HookScript("OnShow", function(s)
    if not s._CMT_applying and s._CMT_baseOrder then
      -- Apply multiple times with short delays to ensure aspect ratio sticks
      -- This is especially important when entering combat and buffs appear
      local function applyWithRetry(attempt)
        if attempt > 3 then return end
        
        C_Timer.After(attempt * 0.05, function()
          if s and s:IsShown() and not s._CMT_applying and s._CMT_baseOrder then
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

local function bootstrap()
  ensureDefaults()
  for _,t in ipairs(TRACKERS) do
    local v=_G[t.name]
    if v then hookViewer(v, t.key) end
  end
end

local ev_loaded = CreateFrame("Frame")
ev_loaded:RegisterEvent("ADDON_LOADED")
ev_loaded:SetScript("OnEvent", function(_, addon)
  if addon == ADDON_NAME then
    ensureDefaults()
  end
end)

local ev_login = CreateFrame("Frame")
ev_login:RegisterEvent("PLAYER_LOGIN")
ev_login:SetScript("OnEvent", function() 
  bootstrap()
  
  -- Check Edit Mode settings after a delay (let UI settle)
  C_Timer.After(3, function()
    ShowEditModeSetupDialog()
  end)
  
  -- Show welcome message
  C_Timer.After(2, function()
    print("|cff00ff00Cooldown Manager Tweaks Loaded: Cooldown Manager Tweaks is in active development by one person, if you have any issues or feedback please send a private message to the author on Curseforge. If you like CMT you might also want to check out our other addon Edit Mode Tweaks.|r")
  end)
end)

-- Force initial layout after entering world
local ev_world = CreateFrame("Frame")
ev_world:RegisterEvent("PLAYER_ENTERING_WORLD")
ev_world:SetScript("OnEvent", function(self, event, isInitialLogin, isReloadingUi)
  if isInitialLogin or isReloadingUi then
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
end)

-- Spec change handler for auto-switching profiles
local ev_spec = CreateFrame("Frame")
ev_spec:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
ev_spec:SetScript("OnEvent", function()
  local specIndex = GetSpecialization()
  if not specIndex then return end
  
  local specID = GetSpecializationInfo(specIndex)
  if not specID then return end
  
  -- Check if this spec has an assigned profile
  local profileName = CMT_DB.specProfiles[specID]
  if profileName and CMT_DB.profiles[profileName] then
    CMT_DB.currentProfile = profileName
    
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
  end
end)

-- watchdog ticker
local tick=CreateFrame("Frame"); local acc,interval=0,0.25
tick:SetScript("OnUpdate", function(_,dt)
  local now=GetTime(); local iv=(now<_fastRepairUntil) and 0 or interval
  acc=acc+dt; if acc<iv then return end; acc=0
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
      if v._CMT_drift then v._CMT_drift=nil; ensureFrozen(v, t.key)
      elseif v._CMT_desiredSig then ensureFrozen(v, t.key) end
    end
  end
end)

local regen=CreateFrame("Frame")
regen:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Leaving combat
regen:SetScript("OnEvent", function(self, event)
  -- Apply pending layouts after leaving combat
  if not CMT_DB._pendingApply then return end
  for _,t in ipairs(TRACKERS) do
    if CMT_DB._pendingApply[t.key] then
      local v=_G[t.name]
      if v then
        local layoutFunc = t.isBarType and layoutBars or layoutCustomGrid
        layoutFunc(v, t.key, baselineOrderFor(v))
        v._CMT_drift=nil
      end
    end
  end
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

local function CreateTrackerTab(parent, key, display)
  local content=CreateFrame("Frame", nil, parent); content:SetSize(420, 680)
  local y=-15

  local title=content:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  title:SetPoint("TOPLEFT",15,y); title:SetText(display); y=y-30

  -- Profile Display (read-only, managed in Profiles tab)
  local profileLabel=content:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  profileLabel:SetPoint("TOPLEFT",15,y)
  profileLabel:SetText("Current Profile: " .. (CMT_DB.currentProfile or "Default"))
  profileLabel:SetTextColor(0.7, 0.7, 0.7)
  y=y-25

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
  }
  
  UIDropDownMenu_Initialize(aspectDD, function()
    local currentAspect = GetSetting(key,"aspectRatio") or "1:1"
    for _, opt in ipairs(aspectOptions) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = opt.text
      info.value = opt.value
      info.func = function()
        SetSetting(key,"aspectRatio", opt.value)
        UIDropDownMenu_SetSelectedValue(aspectDD, opt.value)
        UIDropDownMenu_SetText(aspectDD, opt.text)
        relayoutOne(key)
        CloseDropDownMenus()
      end
      info.checked = (currentAspect == opt.value)
      UIDropDownMenu_AddButton(info)
    end
  end)
  
  -- Set initial text
  local currentAspect = GetSetting(key,"aspectRatio") or "1:1"
  for _, opt in ipairs(aspectOptions) do
    if opt.value == currentAspect then
      UIDropDownMenu_SetText(aspectDD, opt.text)
      break
    end
  end
  y=y-40
  
  -- Border Alpha Slider
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
  y=y-40
  
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

  return content
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

local function CreateConfigPanel()
  if configPanel then return configPanel end
  local panel=CreateFrame("Frame","CMT_ConfigPanel",UIParent,"BasicFrameTemplateWithInset")
  panel:SetSize(520,750); panel:SetPoint("CENTER"); panel:SetMovable(true); panel:EnableMouse(true)
  panel:RegisterForDrag("LeftButton"); panel:SetScript("OnDragStart", panel.StartMoving)
  panel:SetScript("OnDragStop", panel.StopMovingOrSizing); panel:Hide()

  panel.title=panel:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  panel.title:SetPoint("TOP",0,-5); panel.title:SetText("Cooldown Manager Tweaks")

  local ver=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  ver:SetPoint("TOPRIGHT", panel.CloseButton, "TOPLEFT", -5, -2); ver:SetText("v"..VERSION)
  ver:SetTextColor(0.6,0.6,0.6)

  tabHeader=panel:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  tabHeader:SetPoint("TOPLEFT",16,-28); tabHeader:SetText("")

  local tabs={}; panel.Tabs=panel.Tabs or {}
  
  local function makeTab(id,label,key,disp)
    local btn=CreateFrame("Button", nil, panel, "PanelTabButtonTemplate")
    btn:SetID(id); btn:SetText(label)
    if not btn.Text and btn.GetFontString then local fs=btn:GetFontString(); if fs then btn.Text=fs end end
    btn:SetPoint("TOPLEFT", 10+(id-1)*110, -46)
    SafeTabResize(btn,20)
    btn:SetScript("OnClick", function()
      PanelTemplates_SetTab(panel, id)
      for _,t in ipairs(tabs) do if t.content then t.content:Hide() end end
      tabHeader:SetText(disp); btn.content:Show()
    end)
    btn.content=CreateTrackerTab(panel,key,disp); btn.content:SetPoint("TOPLEFT",10,-95); btn.content:Hide()
    tabs[id]=btn; panel.Tabs[id]=btn
  end

  makeTab(1,"Essential","essential","Essential Cooldowns")
  makeTab(2,"Utility","utility","Utility Cooldowns")
  
  -- Buffs tab (special case for layout) - Second row, left side
  local buffsBtn=CreateFrame("Button", nil, panel, "PanelTabButtonTemplate")
  buffsBtn:SetID(3); buffsBtn:SetText("Buffs")
  if not buffsBtn.Text and buffsBtn.GetFontString then local fs=buffsBtn.GetFontString(); if fs then buffsBtn.Text=fs end end
  buffsBtn:SetPoint("TOPLEFT", 10, -70) -- Second row, left side
  SafeTabResize(buffsBtn,20)
  buffsBtn:SetScript("OnClick", function()
    PanelTemplates_SetTab(panel, 3)
    for _,t in ipairs(tabs) do if t.content then t.content:Hide() end end
    tabHeader:SetText("Buff Tracker"); buffsBtn.content:Show()
  end)
  buffsBtn.content=CreateTrackerTab(panel,"buffs","Buff Tracker")
  buffsBtn.content:SetPoint("TOPLEFT",10,-95); buffsBtn.content:Hide()
  tabs[3]=buffsBtn; panel.Tabs[3]=buffsBtn
  
  -- Profiles tab (special case - not a tracker) - Second row, middle
  local profileBtn=CreateFrame("Button", nil, panel, "PanelTabButtonTemplate")
  profileBtn:SetID(4); profileBtn:SetText("Profiles")
  if not profileBtn.Text and profileBtn.GetFontString then local fs=profileBtn:GetFontString(); if fs then profileBtn.Text=fs end end
  profileBtn:SetPoint("TOPLEFT", 90, -70) -- Second row, middle (moved right to make room for Buffs)
  SafeTabResize(profileBtn,20)
  
  -- Create Profiles content
  local profileContent=CreateFrame("Frame", nil, panel); profileContent:SetSize(420, 545)
  profileContent:SetPoint("TOPLEFT",10,-95); profileContent:Hide()
  
  local py=-15
  local ptitle=profileContent:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  ptitle:SetPoint("TOPLEFT",15,py); ptitle:SetText("Profiles"); py=py-30
  
  local pinfo=profileContent:CreateFontString(nil,"OVERLAY","GameFontNormal")
  pinfo:SetPoint("TOPLEFT",15,py); pinfo:SetWidth(390); pinfo:SetJustifyH("LEFT")
  pinfo:SetText("Profiles let you save multiple layout configurations and switch between them. Each profile stores settings for all trackers.")
  py=py-50
  
  -- Profile selector dropdown
  local profileLabel=profileContent:CreateFontString(nil,"OVERLAY","GameFontNormal")
  profileLabel:SetPoint("TOPLEFT",15,py); profileLabel:SetText("Active Profile:")
  
  local profileDD=CreateFrame("Frame", nil, profileContent, "UIDropDownMenuTemplate")
  profileDD:SetPoint("LEFT", profileLabel, "RIGHT", -10, -5)
  
  local function refreshProfileDropdown()
    UIDropDownMenu_Initialize(profileDD, function()
      for profileName in pairs(CMT_DB.profiles) do
        local info=UIDropDownMenu_CreateInfo()
        info.text=profileName
        info.func=function()
          CMT_DB.currentProfile = profileName
          UIDropDownMenu_SetSelectedValue(profileDD, profileName)
          UIDropDownMenu_SetText(profileDD, profileName)
          
          -- Force a small delay to ensure profile data is fully accessible
          C_Timer.After(0.05, function()
            -- Reapply all layouts with new profile
            for _,t in ipairs(TRACKERS) do
              local v=_G[t.name]
              if v and v._CMT_baseOrder then
                -- Force recapture to ensure clean state
                v._CMT_desiredSig = nil
                local layoutFunc = t.isBarType and layoutBars or layoutCustomGrid
                layoutFunc(v, t.key, v._CMT_baseOrder)
              end
            end
          end)
          
          print("CMT: Switched to profile: " .. profileName)
        end
        info.checked=(CMT_DB.currentProfile == profileName)
        UIDropDownMenu_AddButton(info)
      end
    end)
    
    UIDropDownMenu_SetWidth(profileDD, 200)
    UIDropDownMenu_SetSelectedValue(profileDD, CMT_DB.currentProfile)
    UIDropDownMenu_SetText(profileDD, CMT_DB.currentProfile)
  end
  
  refreshProfileDropdown(); py=py-50
  
  -- Save current settings to active profile button
  local saveBtn=CreateFrame("Button", nil, profileContent, "UIPanelButtonTemplate")
  saveBtn:SetSize(180,24); saveBtn:SetPoint("TOPLEFT", 15, py); saveBtn:SetText("Save Current Settings")
  saveBtn:SetScript("OnClick", function()
    local profileName = CMT_DB.currentProfile
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
        aspectRatio       = GetSetting(t.key,"aspectRatio"),
        borderAlpha       = GetSetting(t.key,"borderAlpha"),
        cooldownTextScale = GetSetting(t.key,"cooldownTextScale"),
      }
    end
    
    print("CMT: Saved current settings to profile: " .. profileName)
  end)
  py=py-40
  
  -- Create new profile section
  local newHeader=profileContent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  newHeader:SetPoint("TOPLEFT",15,py); newHeader:SetText("Create New Profile:")
  py=py-25
  
  local newLabel=profileContent:CreateFontString(nil,"OVERLAY","GameFontNormal")
  newLabel:SetPoint("TOPLEFT",15,py); newLabel:SetText("Profile Name:")
  
  local newBox=CreateFrame("EditBox", nil, profileContent, "InputBoxTemplate")
  newBox:SetSize(200,25); newBox:SetPoint("LEFT",newLabel,"RIGHT",10,0)
  newBox:SetAutoFocus(false)
  
  local createBtn=CreateFrame("Button", nil, profileContent, "UIPanelButtonTemplate")
  createBtn:SetSize(80,24); createBtn:SetPoint("LEFT",newBox,"RIGHT",10,0); createBtn:SetText("Create")
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
    
    -- Copy current profile
    local current = GetCurrentProfile()
    CMT_DB.profiles[name] = deepCopy(current)
    
    newBox:SetText("")
    refreshProfileDropdown()
    print("CMT: Created profile: " .. name)
  end)
  
  py=py-40
  
  -- Delete profile section
  local delHeader=profileContent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  delHeader:SetPoint("TOPLEFT",15,py); delHeader:SetText("Delete Profile:")
  py=py-25
  
  local delLabel=profileContent:CreateFontString(nil,"OVERLAY","GameFontNormal")
  delLabel:SetPoint("TOPLEFT",15,py); delLabel:SetText("Select profile to delete:")
  
  local delDD=CreateFrame("Frame", nil, profileContent, "UIDropDownMenuTemplate")
  delDD:SetPoint("LEFT", delLabel, "RIGHT", -10, -5)
  
  local function refreshDeleteDropdown()
    UIDropDownMenu_Initialize(delDD, function()
      for profileName in pairs(CMT_DB.profiles) do
        if profileName ~= "Default" and profileName ~= CMT_DB.currentProfile then
          local info=UIDropDownMenu_CreateInfo()
          info.text=profileName
          info.func=function()
            UIDropDownMenu_SetSelectedValue(delDD, profileName)
            UIDropDownMenu_SetText(delDD, profileName)
          end
          UIDropDownMenu_AddButton(info)
        end
      end
    end)
    
    UIDropDownMenu_SetWidth(delDD, 150)
    UIDropDownMenu_SetText(delDD, "Select...")
  end
  
  refreshDeleteDropdown()
  
  local delBtn=CreateFrame("Button", nil, profileContent, "UIPanelButtonTemplate")
  delBtn:SetSize(80,24); delBtn:SetPoint("LEFT",delDD,"RIGHT",10,0); delBtn:SetText("Delete")
  delBtn:SetScript("OnClick", function()
    local name = UIDropDownMenu_GetSelectedValue(delDD)
    if not name then
      print("CMT: Please select a profile to delete")
      return
    end
    if name == "Default" then
      print("CMT: Cannot delete Default profile")
      return
    end
    if name == CMT_DB.currentProfile then
      print("CMT: Cannot delete active profile")
      return
    end
    
    CMT_DB.profiles[name] = nil
    refreshProfileDropdown()
    refreshDeleteDropdown()
    print("CMT: Deleted profile: " .. name)
  end)
  
  py=py-60
  
  -- Import/Export section
  local ieHeader=profileContent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  ieHeader:SetPoint("TOPLEFT",15,py); ieHeader:SetText("Share Profile:")
  py=py-25
  
  local ieInfo=profileContent:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  ieInfo:SetPoint("TOPLEFT",15,py); ieInfo:SetWidth(390); ieInfo:SetJustifyH("LEFT")
  ieInfo:SetText("Export your current profile to share with others, or import a profile string.")
  py=py-35
  
  local exportBtn=CreateFrame("Button", nil, profileContent, "UIPanelButtonTemplate")
  exportBtn:SetSize(120,24); exportBtn:SetPoint("TOPLEFT", 15, py); exportBtn:SetText("Export Profile")
  
  local importBtn=CreateFrame("Button", nil, profileContent, "UIPanelButtonTemplate")
  importBtn:SetSize(120,24); importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0); importBtn:SetText("Import Profile")
  
  -- Export functionality
  exportBtn:SetScript("OnClick", function()
    local exportData = {
      version = VERSION,
      profileName = CMT_DB.currentProfile,
      trackers = {}
    }
    
    -- Explicitly gather all current settings for each tracker
    -- Use ternary-like logic to handle nil properly (especially for booleans)
    for _, t in ipairs(TRACKERS) do
      local function getSetting(name)
        local val = GetSetting(t.key, name)
        if val ~= nil then
          return val
        else
          return DEFAULTS[name]
        end
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
        aspectRatio       = getSetting("aspectRatio"),
        borderAlpha       = getSetting("borderAlpha"),
        cooldownTextScale = getSetting("cooldownTextScale"),
      }
    end
    
    -- Serialize to string
    local serialized = serializeProfile(exportData)
    
    -- Show export window
    ShowProfileExportWindow(serialized, CMT_DB.currentProfile)
  end)
  
  -- Import functionality
  importBtn:SetScript("OnClick", function()
    ShowProfileImportWindow()
  end)
  
  py=py-50
  
  -- Spec assignment section
  local specHeader=profileContent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  specHeader:SetPoint("TOPLEFT",15,py); specHeader:SetText("Auto-Switch by Spec:")
  py=py-25
  
  local specInfo=profileContent:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  specInfo:SetPoint("TOPLEFT",15,py); specInfo:SetWidth(390); specInfo:SetJustifyH("LEFT")
  specInfo:SetTextColor(0.7,0.7,0.7)
  specInfo:SetText("Assign profiles to specs for automatic switching:")
  py=py-25
  
  -- Create dropdowns for each spec
  local specDropdowns = {}
  for i=1, GetNumSpecializations() do
    local specID, specName = GetSpecializationInfo(i)
    if specID and specName then
      local specLabel=profileContent:CreateFontString(nil,"OVERLAY","GameFontNormal")
      specLabel:SetPoint("TOPLEFT",25,py)
      specLabel:SetText(specName .. ":")
      specLabel:SetWidth(100)
      specLabel:SetJustifyH("LEFT")
      
      local specDD=CreateFrame("Frame", nil, profileContent, "UIDropDownMenuTemplate")
      specDD:SetPoint("LEFT", specLabel, "RIGHT", -10, -5)
      
      specDropdowns[specID] = specDD
      
      local function setupSpecDD()
        UIDropDownMenu_Initialize(specDD, function()
          -- Add "None" option
          local info=UIDropDownMenu_CreateInfo()
          info.text="(None)"
          info.func=function()
            CMT_DB.specProfiles[specID] = nil
            UIDropDownMenu_SetSelectedValue(specDD, nil)
            UIDropDownMenu_SetText(specDD, "(None)")
          end
          info.checked=(CMT_DB.specProfiles[specID] == nil)
          UIDropDownMenu_AddButton(info)
          
          -- Add profile options
          for profileName in pairs(CMT_DB.profiles) do
            local info2=UIDropDownMenu_CreateInfo()
            info2.text=profileName
            info2.func=function()
              CMT_DB.specProfiles[specID] = profileName
              UIDropDownMenu_SetSelectedValue(specDD, profileName)
              UIDropDownMenu_SetText(specDD, profileName)
            end
            info2.checked=(CMT_DB.specProfiles[specID] == profileName)
            UIDropDownMenu_AddButton(info2)
          end
        end)
        
        UIDropDownMenu_SetWidth(specDD, 150)
        local assigned = CMT_DB.specProfiles[specID]
        if assigned then
          UIDropDownMenu_SetText(specDD, assigned)
          UIDropDownMenu_SetSelectedValue(specDD, assigned)
        else
          UIDropDownMenu_SetText(specDD, "(None)")
        end
      end
      
      setupSpecDD()
      py=py-35
    end
  end
  
  py=py-10
  
  -- Info text
  local helpText=profileContent:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  helpText:SetPoint("TOPLEFT",15,py); helpText:SetWidth(390); helpText:SetJustifyH("LEFT")
  helpText:SetTextColor(0.7,0.7,0.7)
  helpText:SetText("Note: New profiles are created as a copy of your currently active profile. Configure settings in the other tabs, then create a new profile to save that configuration.")
  
  profileBtn:SetScript("OnClick", function()
    PanelTemplates_SetTab(panel, 4)
    for _,t in ipairs(tabs) do if t.content then t.content:Hide() end end
    tabHeader:SetText("Profiles"); profileBtn.content:Show()
    -- Refresh dropdowns when tab is shown
    refreshProfileDropdown()
    refreshDeleteDropdown()
    -- Refresh spec dropdowns
    for specID, dd in pairs(specDropdowns) do
      UIDropDownMenu_Initialize(dd, function()
        local info=UIDropDownMenu_CreateInfo()
        info.text="(None)"
        info.func=function()
          CMT_DB.specProfiles[specID] = nil
          UIDropDownMenu_SetSelectedValue(dd, nil)
          UIDropDownMenu_SetText(dd, "(None)")
        end
        info.checked=(CMT_DB.specProfiles[specID] == nil)
        UIDropDownMenu_AddButton(info)
        
        for profileName in pairs(CMT_DB.profiles) do
          local info2=UIDropDownMenu_CreateInfo()
          info2.text=profileName
          info2.func=function()
            CMT_DB.specProfiles[specID] = profileName
            UIDropDownMenu_SetSelectedValue(dd, profileName)
            UIDropDownMenu_SetText(dd, profileName)
          end
          info2.checked=(CMT_DB.specProfiles[specID] == profileName)
          UIDropDownMenu_AddButton(info2)
        end
      end)
      
      local assigned = CMT_DB.specProfiles[specID]
      if assigned then
        UIDropDownMenu_SetText(dd, assigned)
      else
        UIDropDownMenu_SetText(dd, "(None)")
      end
    end
  end)
  
  profileBtn.content = profileContent
  tabs[4]=profileBtn; panel.Tabs[4]=profileBtn
  
  -- General Settings tab (special case - not a tracker) - Second row
  local generalBtn=CreateFrame("Button", nil, panel, "PanelTabButtonTemplate")
  generalBtn:SetID(5); generalBtn:SetText("Settings")
  if not generalBtn.Text and generalBtn.GetFontString then local fs=generalBtn:GetFontString(); if fs then generalBtn.Text=fs end end
  generalBtn:SetPoint("TOPLEFT", 190, -70) -- Second row, right of Profiles
  SafeTabResize(generalBtn,20)
  
  -- Create General Settings content
  local generalContent=CreateFrame("Frame", nil, panel); generalContent:SetSize(420, 545)
  generalContent:SetPoint("TOPLEFT",10,-95); generalContent:Hide()
  
  local gy=-15
  local gtitle=generalContent:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  gtitle:SetPoint("TOPLEFT",15,gy); gtitle:SetText("General Settings"); gy=gy-35
  
  -- Minimap button checkbox
  local minimapCheckbox = CreateFrame("CheckButton", nil, generalContent, "InterfaceOptionsCheckButtonTemplate")
  minimapCheckbox:SetPoint("TOPLEFT", 15, gy)
  minimapCheckbox.Text:SetText("Show Minimap Button")
  minimapCheckbox:SetChecked(CMT_DB.showMinimapButton)
  minimapCheckbox:SetScript("OnClick", function(self)
    CMT_DB.showMinimapButton = self:GetChecked()
    if CMT_DB.showMinimapButton then
      minimapButton:Show()
    else
      minimapButton:Hide()
    end
  end)
  gy = gy - 30
  
  local minimapInfo = generalContent:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  minimapInfo:SetPoint("TOPLEFT",35,gy); minimapInfo:SetWidth(370); minimapInfo:SetJustifyH("LEFT")
  minimapInfo:SetTextColor(0.7,0.7,0.7)
  minimapInfo:SetText("Show or hide the minimap button. You can still access settings with /cmt")
  gy = gy - 50
  
  -- Edit Mode Setup Assistant section
  local editModeHeader = generalContent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  editModeHeader:SetPoint("TOPLEFT",15,gy); editModeHeader:SetText("Edit Mode Configuration:")
  gy = gy - 25
  
  local editModeInfo = generalContent:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  editModeInfo:SetPoint("TOPLEFT",15,gy); editModeInfo:SetWidth(390); editModeInfo:SetJustifyH("LEFT")
  editModeInfo:SetTextColor(0.7,0.7,0.7)
  editModeInfo:SetText("CMT works best when Blizzard's Edit Mode is configured with these optimal settings:")
  gy = gy - 30
  
  -- Display optimal settings
  local optimalSettings = generalContent:CreateFontString(nil,"OVERLAY","GameFontNormal")
  optimalSettings:SetPoint("TOPLEFT",25,gy); optimalSettings:SetWidth(380); optimalSettings:SetJustifyH("LEFT")
  optimalSettings:SetTextColor(1, 1, 1)
  optimalSettings:SetText("• Essential Cooldowns: Orientation = Horizontal, Columns = 1\n• Utility Cooldowns: Orientation = Horizontal, Columns = 1\n• Tracked Buffs: Orientation = Horizontal")
  gy = gy - 55
  
  local checkInfo = generalContent:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  checkInfo:SetPoint("TOPLEFT",15,gy); checkInfo:SetWidth(390); checkInfo:SetJustifyH("LEFT")
  checkInfo:SetTextColor(0.7,0.7,0.7)
  checkInfo:SetText("Use the button below to check if your settings match these optimal values:")
  gy = gy - 30
  
  local setupAssistantBtn = CreateFrame("Button", nil, generalContent, "UIPanelButtonTemplate")
  setupAssistantBtn:SetSize(150,24); setupAssistantBtn:SetPoint("TOPLEFT", 15, gy)
  setupAssistantBtn:SetText("Check Settings")
  setupAssistantBtn:SetScript("OnClick", function()
    ShowEditModeSetupAssistant()
  end)
  gy = gy - 30
  
  generalBtn:SetScript("OnClick", function()
    PanelTemplates_SetTab(panel, 5)
    for _,t in ipairs(tabs) do if t.content then t.content:Hide() end end
    tabHeader:SetText("General Settings"); generalBtn.content:Show()
  end)
  
  generalBtn.content = generalContent
  tabs[5]=generalBtn; panel.Tabs[5]=generalBtn

  PanelTemplates_SetNumTabs(panel, #tabs)
  PanelTemplates_SetTab(panel,1); tabs[1].content:Show(); tabHeader:SetText("Essential Cooldowns")

  -- Apply button removed - all changes are now real-time

  panel.CloseButton:SetScript("OnClick", function() HideUIPanel(panel) end)

  configPanel=panel; return panel
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
    print("Current Profile: " .. (CMT_DB.currentProfile or "Default"))
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
  
  local p=CreateConfigPanel(); if p:IsShown() then HideUIPanel(p) else ShowUIPanel(p) end
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

