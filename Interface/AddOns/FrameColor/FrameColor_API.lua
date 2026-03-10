local addonName, private = ...
local public = _G["FrameColor"]
public.API = {}



--[[
  @TODO: Add documentation.
--]]

--- Register a skin.
---@param skin table The skin table.
---@param options table The options table as explained above.
---@param isReplacement boolean If the skin is a replacement for a default skin or not.
function public.API:RegisterSkin(skin, options, isReplacement)
  if type(skin) ~= "table" or type(options) ~= "table" then
    return
  end

  -- Register the skin.
  local internalSkin = private:RegisterSkin(options, isReplacement)

  -- If the validation failed an empty table will be returned.
  if next(internalSkin) == nil then
    return
  end

  Mixin(internalSkin, skin)
end

--- Reload a skin.
---@param name string The name of the skin to reload.
function public.API:ReloadSkin(name)
  if type(name) ~= "string" then
    return
  end

  public:ReloadSkin(name)
end

-- Request the locale from the addon. This will not be needed by most skins.
-- If you stick with the default color scheme as mentioned above the correct color names will be set automatically.
function public.API:GetLocale()
  return LibStub("AceLocale-3.0"):GetLocale(addonName)
end

-- Update the current Ace3DB defaults to fetch changes.
function public.API:UpdateDefaults()
  private:UpdateDefaults()
end



-- [[ Deprecated ]] --
-- This will just stay here for a while to not break things.
function FrameColor_CreateSkinModule(info)
  local name = type(info) == "table" and info.moduleName or "No Name provided."
  private.Print("The skin (" .. name .. ") tried to create a skin module with an deprecated function. You should uninstall the skin.")
  return {}
end
