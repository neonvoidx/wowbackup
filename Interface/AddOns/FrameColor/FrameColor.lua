local _, private = ...

local function LoadDataBase()
  private:InitializeDataBase()
end

local function LoadAddon()
  private.IterateSkins(function(skin)
    local skinName = skin:GetName()
    if FrameColor:IsSkinEnabled(skinName) then
      FrameColor:EnableSkin(skinName)
    end
  end)
end

local function OnEvent(self, event, addOnName)
  if event == "ADDON_LOADED" and addOnName == "FrameColor" then
    LoadDataBase()
    self:UnregisterEvent("ADDON_LOADED")
  elseif event == "PLAYER_LOGIN" then
    LoadAddon()
    self:UnregisterEvent("PLAYER_LOGIN")
  end
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", OnEvent)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

-- Also used by addon compartment.
function FrameColor_OpenSettings()
  if InCombatLockdown() then
    return
  end

  if not C_AddOns.IsAddOnLoaded("FrameColorOptions") then
    C_AddOns.LoadAddOn("FrameColorOptions")
  end

  FrameColorOptions:Show()
end

-- Register slash commands.
SLASH_FRAME_COLOR1, SLASH_FRAME_COLOR2 = '/framecolor', '/fc';
SlashCmdList.FRAME_COLOR = FrameColor_OpenSettings
