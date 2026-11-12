-- private and public share the same print call. This is just to be able to call them with self.
local addonName, private = ...
local public = _G[addonName]

local Printer = {
  Print = function(msg)
    _G.print(addonName .. ": " .. msg)
  end,
  PrintSkinLoadingError = function(self, msg)
    self.Print("Skin " .. msg .. " failed to load. Please contact the Author.")
  end,
  PrintSkinRuntimeError = function(self, msg)
    self.Print("Skin " .. msg .. " failed during runtime. Please contact the Author.")
  end,
}

for _, v in pairs({
  private,
  public,
}) do
  Mixin(v, Printer)
end



