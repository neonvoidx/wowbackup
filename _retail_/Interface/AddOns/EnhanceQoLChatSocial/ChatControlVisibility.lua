local addon = _G.EnhanceQoL
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local M = { controls = {
	{ name = "ChatFrameChannelButton", key = "chatChannelButtonVisibility" },
	{ name = "ChatFrameMenuButton", key = "chatMenuButtonVisibility" },
	{ name = "ChatFrame1Tab", key = "chatMainTabVisibility" },
} }
addon.ChatControlVisibility = M

function M.Mode(control)
	local mode = addon.db and addon.db[control.key]
	return (mode == "hide" or mode == "mouseover") and mode or "default"
end

function M.Apply(control)
	local frame = control.frame
	if not frame or control.writing or frame:IsForbidden() then return end
	if InCombatLockdown() and frame:IsProtected() then return end
	local mode = M.Mode(control)
	local visible = mode == "default" or (mode == "mouseover" and M.hover)
	local alpha = mode == "default" and control.alpha or (visible and 1 or 0)
	local mouse = visible and control.mouse or false
	control.writing = true
	if frame:GetAlpha() ~= alpha then frame:SetAlpha(alpha) end
	if frame:IsMouseEnabled() ~= mouse then frame:EnableMouse(mouse) end
	control.writing = nil
end

function M.Attach(control)
	local frame = _G[control.name]
	if not frame or frame:IsForbidden() or control.frame == frame then return end
	control.frame = frame
	control.alpha, control.mouse = frame:GetAlpha(), frame:IsMouseEnabled()
	hooksecurefunc(frame, "SetAlpha", function(_, alpha)
		if control.writing then return end
		control.alpha = alpha
		M.Apply(control)
	end)
	hooksecurefunc(frame, "EnableMouse", function(_, enabled)
		if control.writing then return end
		control.mouse = enabled
		M.Apply(control)
	end)
end

function M.IsHovered()
	local chat = _G.ChatFrame1
	if _G.FCFDock_GetSelectedWindow and _G.GENERAL_CHAT_DOCK then
		chat = _G.FCFDock_GetSelectedWindow(_G.GENERAL_CHAT_DOCK) or chat
	end
	if chat and chat:IsShown() and chat:IsMouseOver() then return true end
	for _, control in ipairs(M.controls) do
		local frame = control.frame
		if frame and frame:IsShown() and M.Mode(control) ~= "hide" then
			if frame:IsMouseOver() or (frame.IsMenuOpen and frame:IsMenuOpen()) then return true end
		end
	end
	return false
end

function M.Update()
	M.hover = M.IsHovered()
	for _, control in ipairs(M.controls) do M.Apply(control) end
end

function M.Refresh()
	if not addon.db then return end
	local active = false
	for _, control in ipairs(M.controls) do
		if M.Mode(control) ~= "default" then M.Attach(control); active = true end
	end
	M.Update()
	M.elapsed = 0
	M.watcher:SetScript("OnUpdate", active and function(_, elapsed)
		M.elapsed = M.elapsed + elapsed
		if M.elapsed < 0.05 then return end
		M.elapsed = 0
		M.Update()
	end or nil)
end

function M.RegisterSettings(category, section, indent)
	for _, control in ipairs(M.controls) do
		local key = control.key
		addon.functions.SettingsCreateScrollDropdown(category, {
			var = key, text = L[key], desc = L["chatControlVisibilityDesc"], indent = indent,
			list = { default = L["Default"], hide = L["chatControlVisibilityHide"], mouseover = L["Mouseover"] },
			order = { "default", "mouseover", "hide" },
			get = function() return M.Mode(control) end,
			set = function(value) addon.db[key] = value; M.Refresh() end,
			default = "default", type = Settings.VarType.String, parentSection = section, newTagID = key,
		})
	end
end

function M.Initialize()
	for _, control in ipairs(M.controls) do addon.functions.InitDBValue(control.key, "default") end
	M.Refresh()
end

M.watcher = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "UPDATE_CHAT_WINDOWS", "PLAYER_REGEN_ENABLED" }) do M.watcher:RegisterEvent(event) end
M.watcher:SetScript("OnEvent", M.Refresh)
