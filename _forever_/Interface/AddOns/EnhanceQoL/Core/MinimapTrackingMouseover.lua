local _, addon = ...
local M = { targets = {}, hookedFrames = {} }

function M.Refresh()
	local minimapHovered = Minimap and Minimap:IsVisible() and addon.functions.MouseIsOver(Minimap)
	for frame, state in pairs(M.targets) do
		local hovered = state.hoverFrame:IsVisible() and (minimapHovered or addon.functions.MouseIsOver(state.hoverFrame))
		if state.hovered ~= hovered then
			state.hovered = hovered
			frame:SetAlpha(hovered and state.originalAlpha or 0)
		end
	end
end

function M.UpdateWatcher()
	if not next(M.targets) then
		if M.watcher then M.watcher:Hide() end
		return
	end
	if not M.watcher then
		M.watcher = CreateFrame("Frame")
		M.watcher:SetScript("OnUpdate", function(_, elapsed)
			M.elapsed = (M.elapsed or 0) + elapsed
			if M.elapsed < 0.1 then return end
			M.elapsed = 0
			-- Child buttons can consume minimap enter/leave events.
			M.Refresh()
		end)
		if Minimap then
			Minimap:HookScript("OnEnter", M.Refresh)
			Minimap:HookScript("OnLeave", M.Refresh)
		end
	end
	M.watcher:Show()
end

function addon.functions.ApplyMinimapElementMouseover(frame, enabled, hoverFrame)
	if not frame then return end
	local state = M.targets[frame]
	if not enabled then
		if state then
			M.targets[frame] = nil
			frame:SetAlpha(state.originalAlpha)
		end
	else
		hoverFrame = hoverFrame or frame
		if not state then
			state = { originalAlpha = frame:GetAlpha() }
			M.targets[frame] = state
		end
		state.hoverFrame = hoverFrame
		state.hovered = nil
		if not M.hookedFrames[hoverFrame] then
			M.hookedFrames[hoverFrame] = true
			for _, event in ipairs({ "OnEnter", "OnLeave", "OnShow", "OnHide" }) do
				hoverFrame:HookScript(event, M.Refresh)
			end
		end
		M.Refresh()
	end
	M.UpdateWatcher()
end

function addon.functions.ApplyMinimapTrackingMouseover(frame, button)
	local enabled = addon.db and addon.db.minimapTrackingMouseover == true and frame ~= nil and button ~= nil
	if M.trackingFrame and (not enabled or M.trackingFrame ~= frame) then
		addon.functions.ApplyMinimapElementMouseover(M.trackingFrame, false)
		M.trackingFrame = nil
	end
	if not enabled then return end
	M.trackingFrame = frame
	addon.functions.ApplyMinimapElementMouseover(frame, true, button)
end
