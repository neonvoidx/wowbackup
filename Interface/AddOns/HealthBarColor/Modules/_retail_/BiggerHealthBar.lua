local _, addonTable = ...
local addon = addonTable.addon

local module = addon:NewModule("BiggerHealthBar")
Mixin(module, addonTable.hooks)

local textures =
{
  frameTexture =
  {
    path = addonTable.texturePaths.biggerHealthBarTexture,
    coords =
    {
      0.00048828125, --left
      0.19384765625, --right
      0.1669921875, --top
      0.3056640625 -- bottom
    },
  },
  frameFlash =
  {
    path = addonTable.texturePaths.biggerHealthBarTexture,
    coords =
    {
      0.57568359375, --left
      0.76318359375, --right
      0.1669921875, --top
      0.3056640625, -- bottom
    },
  },
  alternateFrameTexture =
  {
    path = addonTable.texturePaths.biggerHealthBarTexture,
    coords =
    {
      0.78466796875, --left
      0.97802734375, --right
      0.0009765625, --top
      0.1455078125, -- bottom
    },
  },
  alternateFrameFlash =
  {
    path = addonTable.texturePaths.biggerHealthBarTexture,
    coords =
    {
      0.38720703125, --left
      0.57470703125, --right
      0.1669921875, --top
      0.3056640625, -- bottom
    },
  },
  healthBarMask =
  {
    path = addonTable.texturePaths.biggerHealthBarMask,
    coords =
    {
      2/128, --left
      126/128, --right
      15/64, --top
      52/64, -- bottom
    },
  },
}

local resourceBars =
{
	addonTable.globalUnitVariables.player.powerBar,
	InsanityBarFrame,
	AlternatePowerBar,
	MonkStaggerBar,
  DemonHunterSoulFragmentsBar,
  EvokerEbonMightBar,
}

local function onToPlayerArt()
  if InCombatLockdown() then
    --Player's health bar is protected.
    addon:DelayUntilAfterCombat(onToPlayerArt)
    return
  end
  local isAlterntePowerFrame = PlayerFrame.activeAlternatePowerBar
	local frameTexture = isAlterntePowerFrame and PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture or PlayerFrame.PlayerFrameContainer.FrameTexture
  local frameFlash =  PlayerFrame.PlayerFrameContainer.FrameFlash
  frameTexture:SetTexture(textures.frameTexture.path)
  frameFlash:SetTexture(textures.frameFlash.path)
  if isAlterntePowerFrame then
    frameTexture:SetTexCoord(unpack(textures.alternateFrameTexture.coords))
    frameFlash:SetTexCoord(unpack(textures.alternateFrameFlash.coords))
  else
    frameTexture:SetTexCoord(unpack(textures.frameTexture.coords))
    frameFlash:SetTexCoord(unpack(textures.frameFlash.coords))
  end
  local mask = addonTable.globalUnitVariables.player.healthBarMask
  local healthBar = addonTable.globalUnitVariables.player.healthBar
	mask:SetTexture(textures.healthBarMask.path)
	mask:SetPoint("TOPLEFT",healthBar,-3,7)
	mask:SetPoint("BOTTOMRIGHT",healthBar,2,-12)
  mask:Show()
  healthBar:SetHeight(30.5)
  -- Font since tww the halth text is anchored to the container.
  local healthTextLeft = addonTable.globalUnitVariables.player.healthTextLeft
  local healthTextMiddle = addonTable.globalUnitVariables.player.healthTextMiddle
  local healthTextRight = addonTable.globalUnitVariables.player.healthTextRight
  healthTextLeft:SetPoint("LEFT", healthBar, "LEFT")
  healthTextMiddle:SetPoint("CENTER", healthBar, "CENTER")
  healthTextRight:SetPoint("RIGHT", healthBar, "RIGHT")
end

local function onToVehicleArt()
  PlayerFrame.PlayerFrameContainer.FrameFlash:SetTexCoord(0,1,0,1)
  addonTable.globalUnitVariables.player.healthBarMask:Hide()
end

function module:OnEnable()
  self:HookFunc("PlayerFrame_ToPlayerArt", onToPlayerArt)
  self:HookFunc("PlayerFrame_ToVehicleArt", onToVehicleArt)

  -- This will avoid distorting the vehicle art when entering a vehicle but as a trade off there is no vehicle art :D. Worth it for me.
  for _, event in pairs({
    "UNIT_ENTERED_VEHICLE",
    "UNIT_EXITING_VEHICLE",
    "UNIT_EXITED_VEHICLE",
  }) do
    PlayerFrame:UnregisterEvent(event)
  end
  -- This will avoid changing the bar art on druid shape shift.
  AlternatePowerBar:UnregisterEvent("UNIT_DISPLAYPOWER")

  for i=1, #resourceBars do
		local statusBar = resourceBars[i]
		statusBar:SetAlpha(0) --hiding it can cause taint
		self:HookScript(statusBar, "OnShow", function()
			statusBar:SetAlpha(0)
		end)
	end
  onToPlayerArt()
end

function module:OnDisable()
	self:DisableHooks()
  local isAlterntePowerFrame = PlayerFrame.activeAlternatePowerBar
	local frameTexture = isAlterntePowerFrame and PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture or PlayerFrame.PlayerFrameContainer.FrameTexture
  local frameFlash =  PlayerFrame.PlayerFrameContainer.FrameFlash
  local mask = addonTable.globalUnitVariables.player.healthBarMask
  local healthBar = addonTable.globalUnitVariables.player.healthBar
  if isAlterntePowerFrame then
		frameTexture:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-ClassResource")
    frameTexture:SetTexCoord(0,1,0,1)
		frameFlash:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-ClassResource-InCombat")
    frameFlash:SetTexCoord(0,1,0,1)
	else
		frameTexture:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn")
    frameTexture:SetTexCoord(0,1,0,1)
		frameFlash:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-InCombat")
    frameFlash:SetTexCoord(0,1,0,1)
	end
  mask:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health-Mask")

  for _, event in pairs({
    "UNIT_ENTERED_VEHICLE",
    "UNIT_EXITING_VEHICLE",
    "UNIT_EXITED_VEHICLE",
  }) do
    PlayerFrame:RegisterEvent(event)
  end
  AlternatePowerBar:RegisterEvent("UNIT_DISPLAYPOWER")

	healthBar:SetHeight(20)
	for i=1, #resourceBars do
		resourceBars[i]:SetAlpha(1)
	end
end

