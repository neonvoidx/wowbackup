local addon = _G.EnhanceQoL
if not addon or not (C_AddOns and C_AddOns.IsAddOnLoaded("ElvUI")) then return end

local engine = _G.ElvUI and _G.ElvUI[1]
local unitFrames = engine and engine.GetModule and engine:GetModule("UnitFrames", true)
if not unitFrames or type(unitFrames.CreateAndUpdateUF) ~= "function" then return end

local pendingTargets = {}
local refreshQueued = false

local function refreshAnchors()
	refreshQueued = false
	local targets = pendingTargets
	pendingTargets = {}

	local mythicPlus = addon.MythicPlus
	local reapplyTrackers = mythicPlus and mythicPlus.functions and mythicPlus.functions.ReapplyTrackerAnchorsForTarget
	if reapplyTrackers then
		for target in pairs(targets) do
			reapplyTrackers(target)
		end
	end

	local panels = addon.Aura and addon.Aura.CooldownPanels
	local root = panels and panels.GetRoot and panels:GetRoot()
	if root and root.panels and panels.ApplyPanelPosition then
		for panelId, panel in pairs(root.panels) do
			local target = panel.anchor and panel.anchor.relativeFrame
			if target and targets[target] then panels:ApplyPanelPosition(panelId) end
		end
	end
end

local function queueFrame(frame)
	local name = frame and frame.GetName and frame:GetName()
	if type(name) ~= "string" or not name:match("^ElvUF_") then return end
	pendingTargets[name] = true
	if refreshQueued then return end
	refreshQueued = true
	-- Wait until the current frame setup and mover updates have finished.
	C_Timer.After(0, refreshAnchors)
end

hooksecurefunc(unitFrames, "CreateAndUpdateUF", function(self, unit) queueFrame(self[unit]) end)
if type(unitFrames.CreateAndUpdateUFGroup) == "function" then
	hooksecurefunc(unitFrames, "CreateAndUpdateUFGroup", function(self, group, count)
		for index = 1, count do
			queueFrame(self[group .. index])
		end
	end)
end

for _, frame in pairs(unitFrames.units or {}) do
	queueFrame(frame)
end
for unit in pairs(unitFrames.groupunits or {}) do
	queueFrame(unitFrames[unit])
end
