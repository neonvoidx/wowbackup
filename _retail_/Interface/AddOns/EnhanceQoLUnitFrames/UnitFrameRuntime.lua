local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local Runtime = addon.UnitFrameRuntime or {}
addon.UnitFrameRuntime = Runtime
local CompactRaidFrameContainer = _G.CompactRaidFrameContainer
local eventFrame = CreateFrame("Frame")

local function registerDeferredCombatCallback()
	if addon.variables.pendingPartyFrameScale or addon.variables.pendingPartyFrameTitle ~= nil then eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED") end
end

local function applyRestingVisuals()
	if not PlayerFrame or not PlayerFrame.PlayerFrameContent then return end
	local content = PlayerFrame.PlayerFrameContent
	local main = content.PlayerFrameContentMain
	local contextual = content.PlayerFrameContentContextual
	local statusTexture = main and main.StatusTexture
	local playerRestLoop = contextual and contextual.PlayerRestLoop
	if addon.db["hideRestingGlow"] and IsResting() then
		if statusTexture and statusTexture.Hide then statusTexture:Hide() end
		if playerRestLoop and playerRestLoop.Hide then
			playerRestLoop:Hide()
			if playerRestLoop.PlayerRestLoopAnim and playerRestLoop.PlayerRestLoopAnim.Stop then playerRestLoop.PlayerRestLoopAnim:Stop() end
		end
	else
		if PlayerFrame_UpdateStatus then PlayerFrame_UpdateStatus(PlayerFrame) end
	end
end

local function togglePartyFrameTitle(value)
	if InCombatLockdown and InCombatLockdown() then
		addon.variables.pendingPartyFrameTitle = value
		registerDeferredCombatCallback()
		return
	end
	if not CompactPartyFrameTitle then return end
	if value then
		CompactPartyFrameTitle:Hide()
	else
		CompactPartyFrameTitle:Show()
	end
end

local function updatePartyFrameScale()
	if not addon.db["unitFrameScaleEnabled"] or not addon.db["unitFrameScale"] then return end
	if InCombatLockdown and InCombatLockdown() then
		addon.variables.pendingPartyFrameScale = true
		registerDeferredCombatCallback()
		return
	end
	addon.variables.pendingPartyFrameScale = nil
	local scale = addon.db["unitFrameScale"]
	if CompactPartyFrame and CompactPartyFrame.SetScale then CompactPartyFrame:SetScale(scale) end
	if CompactRaidFrameContainer and CompactRaidFrameContainer.SetScale then CompactRaidFrameContainer:SetScale(scale) end
end

addon.functions.ApplyRestingVisuals = applyRestingVisuals
addon.functions.togglePartyFrameTitle = togglePartyFrameTitle
addon.functions.updatePartyFrameScale = updatePartyFrameScale

eventFrame:SetScript("OnEvent", function()
	if addon.variables.pendingPartyFrameScale then
		addon.variables.pendingPartyFrameScale = nil
		updatePartyFrameScale()
	end
	if addon.variables.pendingPartyFrameTitle ~= nil then
		local pending = addon.variables.pendingPartyFrameTitle
		addon.variables.pendingPartyFrameTitle = nil
		togglePartyFrameTitle(pending)
	end
	if addon.variables.pendingPartyFrameScale == nil and addon.variables.pendingPartyFrameTitle == nil then eventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED") end
end)

function Runtime:Initialize()
	if self.initialized then return end
	self.initialized = true

	addon.functions.InitDBValue("hideHitIndicatorPlayer", false)
	addon.functions.InitDBValue("hideHitIndicatorPet", false)
	addon.functions.InitDBValue("hideRestingGlow", false)
	addon.functions.InitDBValue("hidePartyFrameTitle", false)
	addon.functions.InitDBValue("unitFrameScaleEnabled", false)
	addon.functions.InitDBValue("unitFrameScale", 1)
	addon.functions.InitDBValue("healthTextPlayerMode", addon.db["healthTextPlayerMode"] or "OFF")
	addon.functions.InitDBValue("healthTextTargetMode", addon.db["healthTextTargetMode"] or "OFF")
	addon.functions.InitDBValue("healthTextBossMode", addon.db["healthTextBossMode"] or addon.db["bossHealthMode"] or "OFF")

	local playerHitIndicator = PlayerFrame and PlayerFrame.PlayerFrameContent and PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
	playerHitIndicator = playerHitIndicator and playerHitIndicator.HitIndicator
	if addon.db["hideHitIndicatorPlayer"] and playerHitIndicator then playerHitIndicator:Hide() end

	if PetHitIndicator then
		hooksecurefunc(PetHitIndicator, "Show", function(self)
			if addon.db["hideHitIndicatorPet"] then self:Hide() end
		end)
	end

	if PlayerFrame_UpdateStatus then
		hooksecurefunc("PlayerFrame_UpdateStatus", function()
			if not addon.db or not addon.db["hideRestingGlow"] or not IsResting() then return end
			local content = PlayerFrame and PlayerFrame.PlayerFrameContent
			local main = content and content.PlayerFrameContentMain
			local statusTexture = main and main.StatusTexture
			if statusTexture and statusTexture.Hide then statusTexture:Hide() end
			if PlayerFrame_UpdatePlayerRestLoop then PlayerFrame_UpdatePlayerRestLoop(true) end
		end)
	end

	if PlayerFrame_UpdatePlayerRestLoop then
		hooksecurefunc("PlayerFrame_UpdatePlayerRestLoop", function(state)
			if not addon.db or not addon.db["hideRestingGlow"] or not state then return end
			local content = PlayerFrame and PlayerFrame.PlayerFrameContent
			local contextual = content and content.PlayerFrameContentContextual
			local playerRestLoop = contextual and contextual.PlayerRestLoop
			if playerRestLoop and playerRestLoop.Hide then
				playerRestLoop:Hide()
				if playerRestLoop.PlayerRestLoopAnim and playerRestLoop.PlayerRestLoopAnim.Stop then playerRestLoop.PlayerRestLoopAnim:Stop() end
			end
		end)
	end

	if CompactPartyFrameTitle then
		CompactPartyFrameTitle:HookScript("OnShow", function(self)
			if addon.db["hidePartyFrameTitle"] then self:Hide() end
		end)
	end

	addon.functions.togglePartyFrameTitle(addon.db["hidePartyFrameTitle"])
	if addon.db["unitFrameScaleEnabled"] then addon.functions.updatePartyFrameScale() end
	if addon.db["hideRestingGlow"] then applyRestingVisuals() end

	if addon.HealthText and addon.HealthText.SetMode then
		addon.HealthText:SetMode("player", addon.db["healthTextPlayerMode"])
		addon.HealthText:SetMode("target", addon.db["healthTextTargetMode"])
		addon.HealthText:SetMode("boss", addon.db["healthTextBossMode"])
	end
end

Runtime:Initialize()
