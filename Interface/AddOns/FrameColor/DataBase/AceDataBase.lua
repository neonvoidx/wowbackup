-- Setup the AceDBObject.
local addonName, private = ...
local public = _G[addonName]

function private:InitializeDataBase()
  local defaults = self.GetDefaults()

  public.db = LibStub("AceDB-3.0"):New("FrameColor4DB", defaults, true)
  public.db.RegisterCallback(public, "OnProfileChanged", "ReloadAllSkins")
  public.db.RegisterCallback(public, "OnProfileCopied", "ReloadAllSkins")
  public.db.RegisterCallback(public, "OnProfileReset", "ReloadAllSkins")

  -- Clean up old db values. This is done to remove colors that modules no longer use, otherwise the old key would still create a color option for a non-existent color.
  for moduleName, moduleTable in pairs(public.db.profile) do
    for _, visibleSetting in pairs({
      "colors",
      "toggles",
    }) do
      if type(moduleTable) == "table" and type(moduleTable[visibleSetting]) == "table" then
        for key, _ in pairs(moduleTable[visibleSetting]) do
          if type(defaults.profile[moduleName]) == "table" and type(defaults.profile[moduleName][visibleSetting]) == "table" then
            if not defaults.profile[moduleName][visibleSetting][key] then
              public.db.profile[moduleName][visibleSetting][key] = nil
            end
          end
        end
      end
    end
  end
end

function private:UpdateDefaults()
  local defaults = self.GetDefaults()
  public.db:RegisterDefaults(defaults)
end

--- Get the data for an entire module.
--- @param name string The name of the module.
--- @return table or nil The module data if the module exists.
function public:DB_GetModuleObj(name)
  return CopyTable(self.db.profile[name])
end

---comment
---@param category any
---@return table
function public:GetAllSkinsOfCategory(category)
  local categorizedModuleList = {}

  for _, skin in pairs(self.db.profile) do
    if type(skin) == "table" and skin.category == category then
      table.insert(categorizedModuleList, CopyTable(skin)) -- pass a copy to not have changes made by the ui processing affect the db.
    end
  end

  return categorizedModuleList
end

---comment
---@param name any
---@return boolean
function public:IsSkinEnabled(name)
  local skin = self.db.profile[name]
  return type(skin) == "table" and skin.enabled ~= false -- nil is treated as enabled.
end

--- Get the value for a given key.
--- @param name string The name of the module.
--- @param key any The key which value is requested.
--- @return unknown
function public:DB_GetModuleKey(name, key)
  if self.db.profile[name] then
    return self.db.profile[name][key]
  end
end

--- Set a key value pair for a module.
--- @param name string The name of the module.
--- @param key any The key to set.
--- @param value any The value it will hold.
function public:DB_SetModuleKey(name, key, value)
  if self.db.profile[name] then
    self.db.profile[name][key] = value
    self:ReloadSkin(name)
  end
end

--- Get the color table, containing keys and the actual kolor values.
--- @param moduleName string the module which color is requested.
--- @param colorName string the color of the module that is requested.
--- @return unknown
function public:DB_GetColorObj(moduleName, colorName)
  local colors = self.db.profile[moduleName] and self.db.profile[moduleName].colors
  return type(colors) == "table" and colors[colorName] or nil
end

--- Get the RGBA color values for a given color.
--- @param moduleName string the module which color is requested.
--- @param colorName string the color of the module that is requested.
--- @return number r, g ,b, a The color values.
function public:DB_GetColor(moduleName, colorName)
  local module = self.db.profile[moduleName]
  local colorObj = module and type(module.colors) == "table" and module.colors[colorName]

  if type(colorObj) == "table" and type(colorObj.rgbaValues) == "table" then
    return unpack(colorObj.rgbaValues)
  end
end

--- Set the RGBA values for a given color.
--- @param moduleName string The name of the module.
--- @param colorName string The name of the color.
--- @param r number
--- @param g number
--- @param b number
--- @param a number
function public:DB_SetColor(moduleName, colorName, r, g, b, a)
  -- Ensure all color components are numbers
  for _, v in pairs({r, g, b, a}) do
    if type(v) ~= "number" then
      return
    end
  end

  local module = self.db.profile[moduleName]
  local colorObj = module and type(module.colors) == "table" and module.colors[colorName]

  if type(colorObj) == "table" and type(colorObj.rgbaValues) == "table" then
    self.db.profile[moduleName].colors[colorName].rgbaValues = {r, g, b, a}
  end

  self:ReloadSkin(moduleName)
end

function public:DB_SetColorKey(moduleName, colorName, key, value)
  local module = self.db.profile[moduleName]
  local exists = module and type(module.colors) == "table" and module.colors[colorName]

  if exists then
    self.db.profile[moduleName].colors[colorName][key] = value
    self:ReloadSkin(moduleName)
  end
end

-- [[ Skin Toggles ]] --

---comment
---@param moduleName any
---@param toggleName any
---@return unknown
function public:DB_GetToggleKey(moduleName, toggleName)
  local module = self.db.profile[moduleName]
  local toggleObj = module and type(module.toggles) == "table" and module.toggles[toggleName]

  if type(toggleObj) == "table" then
    return toggleObj.isChecked
  end
end

---comment
---@param moduleName any
---@param toggleName any
---@param key any
---@param value any
function public:DB_SetToggleKey(moduleName, toggleName, value)
  if not type(value) == "boolean" then
    return
  end

  local module = self.db.profile[moduleName]
  local exists = module and type(module.toggles) == "table" and module.toggles[toggleName]

  if exists then
    self.db.profile[moduleName].toggles[toggleName].isChecked = value
    self:ReloadSkin(moduleName)
  end
end
