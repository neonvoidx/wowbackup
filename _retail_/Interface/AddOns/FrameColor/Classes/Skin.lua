local addonName, private = ...
local public = _G[addonName]
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- API
local type = type

local registeredSkins = {}

local followSkins = {}

local function addFollowSkin(lead, follower)
  if not followSkins[lead] then
    followSkins[lead] = {}
  end
  followSkins[lead][follower] = true
end

local function validateOptions(options)
  if type(options) ~= "table" then
    return false
  end

  local expectedTypes = {
    name = "string",
    displayedName = "string",
    category = "string",
    colors = "table",
    toggles = "table"
  }

  for key, expectedType in pairs(expectedTypes) do
    if type(options[key]) ~= expectedType then
      if key == "toggles" then
        options.toggles = {}
      elseif key == "colors" then
        options.colors = {}
      else
        return false
      end
    end
  end

  local locale_name = L[options.name]
  if locale_name ~= options.name then -- Silent fail will return the key.
    options.displayedName = locale_name
  end

  -- Chck if the subtable is indeed a table and return false otherwise.
  -- Add locale name if exists.
  for _, subTbl in pairs({
    "colors",
    "toggles",
  }) do
    for key, option in pairs(options[subTbl]) do
      if type(option) == "table" then
        local locale_name = L[key]
        if locale_name ~= key then
          options[subTbl][key].name = locale_name
        end
      else
        return false
      end
    end
  end

  return true
end

function private:RegisterSkin(options, isReplacement)
  -- Check if a skin with the same name is already registered.
  -- If it isReplacement then disable old and overwrite the skin.
  if registeredSkins[options.name] then
    if isReplacement then
      public:DisableSkin(registeredSkins[options.name])
    else
      return {}
    end
  end

  -- Validate the options table.
  if not validateOptions(options) then
    -- Get the path of the file that called this function
    local stack = debugstack(2, 1, 0)  -- Get the second level in the stack (caller)
    local path = stack:match("@(.-):%d+") or "Unknown File"
    private:PrintSkinLoadingError(path)
    return {}
  end

  -- Register the default settins.
  self.RegisterModuleDefaults(options)

  -- Create the Skin table.
  local skin = {}

  -- Define the Skin functions.
  skin.name = options.name

  function skin:GetName()
    return self.name
  end

  skin.category = options.category

  function skin:GetCategory()
    return self.category
  end

  -- Mixin the Mixins. This means all Skins will also have the methods of those Mixins.
  for _, mixin in pairs(private.mixins) do
    Mixin(skin, mixin)
  end

  -- This will always return a color. If a name (the key as set in the module options table) is provided it will return the correct color set by the user.
  function skin:GetColor(name)
    local colorObj = public:DB_GetColorObj(self.name, name)
    if not colorObj then
      return private.colors.defaultColor
    end

    local globalColorEnabled = public.db.profile.protected.leadingColors.global.enabled
    local categoryColorEnabled = public.db.profile.protected.leadingColors[self.category] and public.db.profile.protected.leadingColors[self.category].enabled

    if not colorObj.lockedColor and ( globalColorEnabled or categoryColorEnabled ) then
      if categoryColorEnabled then
        colorObj = public.db.profile.protected.leadingColors[self.category].colors[name] or public.db.profile.protected.leadingColors[self.category].colors["fallback"]
      else
        colorObj = public.db.profile.protected.leadingColors.global.colors.main
      end
    end

    -- Set the color
    local color
    if colorObj.followClassColor then
      color = public.db.global.ClassColors[private.playerInfo.class]
    else
      color = colorObj.rgbaValues
    end

    return color
  end

  function skin:GetToggleState(name)
    return public:DB_GetToggleKey(self.name, name)
  end

  function skin:Enable()
    self:OnEnable()
    self.enabled = true
  end

  function skin:OnEnable()
    -- Defined by the Skin.
  end

  function skin:Disable()
    self:DisableHooks()
    self:UnregisterFromAllEvents()
    self:OnDisable()
    self.enabled = false
  end

  function skin:OnDisable()
    -- Defined by the Skin.
  end

  function skin:IsEnabled()
    return self.enabled
  end

  if type(options.followSkin) == "string" then
    addFollowSkin(options.followSkin, options.name)
    function skin:GetLeaderColor(name)
      local leadingSkin = registeredSkins[options.followSkin]

      if not leadingSkin then
        return private.colors.defaultColor
      end

      return leadingSkin:GetColor(name)
    end
  end

  registeredSkins[options.name] = skin

  return skin
end

function public:EnableSkin(name)
  local skin = registeredSkins[name]

  if not skin or skin:IsEnabled() then
    return
  end

  local retOK = pcall(skin.Enable, skin)
  if not retOK then
    self:PrintSkinLoadingError(name)
  end

  if followSkins[name] then
    for follower in pairs(followSkins[name]) do
      self:EnableSkin(follower)
    end
  end
end

function public:DisableSkin(name)
  local skin = registeredSkins[name]

  if not skin or not skin:IsEnabled() then
    return
  end

  local retOK = pcall(skin.Disable, skin)
  if not retOK then
    self:PrintSkinLoadingError(name)
  end

  if followSkins[name] then
    for follower in pairs(followSkins[name]) do
      self:DisableSkin(follower)
    end
  end
end

-- Raload the skin or diable it.
function public:ReloadSkin(name)
  self:DisableSkin(name)
  if self:IsSkinEnabled(name) then
    self:EnableSkin(name)
  end
end

function private.IterateSkins(callback)
  for _, skin in pairs(registeredSkins) do
    callback(skin)
  end
end

-- Public functions
function public:ReloadAllSkins()
  private.IterateSkins(function(skin)
    self:ReloadSkin(skin:GetName())
  end)
end

function public:ReloadAllSkinsOfCategory(category)
  if category == "global" then
    self:ReloadAllSkins()
  else
    private.IterateSkins(function(skin)
      if skin:GetCategory() == category then
        self:ReloadSkin(skin:GetName())
      end
    end)
  end
end
