local AceLocale = LibStub("AceLocale-3.0")

-- Initialize the locale system for RdysCrateTracker
-- This will automatically select the appropriate locale based on the client's language
local L = AceLocale:GetLocale("RdysCrateTracker", true) -- true = silent if not found

-- Debug: Print current locale for Spanish clients
local clientLocale = GetLocale()
if clientLocale == "esES" or clientLocale == "esMX" then
    print("[RCT] Client locale: " .. clientLocale)
    if L and L["ADDON_TITLE"] then
        print("[RCT] Spanish locale active - Title: " .. (L["ADDON_TITLE"] or "fallback"))
    else
        print("[RCT] Spanish locale not active, using English")
    end
end

-- Make the locale table available globally for the addon
_G.RCT_LOCALE = L