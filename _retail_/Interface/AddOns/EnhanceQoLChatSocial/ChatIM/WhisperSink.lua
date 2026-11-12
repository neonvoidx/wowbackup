-- luacheck: globals FCF_GetNextOpenChatWindowIndex FCF_GetChatFrameByID FCF_StopAlertFlash GetChatWindowInfo SetChatWindowName SetChatWindowShown
local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.ChatIM = addon.ChatIM or {}
local ChatIM = addon.ChatIM
-- Loaded by Retail and Forever. TBC keeps its existing chat handling.
ChatIM.UsesNativeWhisperSink = true
local Sink = { name = "EQOL_WhisperSink", hooked = {} }
ChatIM.WhisperSink = Sink

function Sink:Hide()
	local window = self.window
	if not window then return end
	-- The native setter runs before this timer is read. Keep its sound silent;
	-- ChatIM retains ownership of custom sounds and notification visibility rules.
	window.tellTimer = math.huge
	window:Hide()
	local tab = _G[window:GetName() .. "Tab"]
	if tab then tab:Hide() end
	if window.buttonFrame then window.buttonFrame:Hide() end
	if window.minFrame then window.minFrame:Hide() end
	FCF_StopAlertFlash(window)
end

function Sink:KeepInlineMode()
	local mode = GetCVar("whisperMode")
	if mode ~= "inline" then
		-- A non-dedicated window is skipped in popout mode, before last-tell updates.
		-- Remember changes made while active so disabling ChatIM restores that choice.
		self.restoreMode = mode
		SetCVar("whisperMode", "inline")
	end
end

function Sink:Refresh()
	if not ChatIM.enabled or self.busy or InCombatLockdown() then return end
	if not (FCF_GetNextOpenChatWindowIndex and FCF_GetChatFrameByID and SetChatWindowName) then return end
	if self.window and (GetChatWindowInfo(self.window:GetID()) ~= self.name or not select(7, GetChatWindowInfo(self.window:GetID()))) then
		-- Chat reset/reconfiguration may reclaim this window. Never hide or close it.
		self.window.tellTimer = nil
		self.window, self.active = nil, false
	end
	if not self.window then
		self.busy = true
		local index = FCF_GetNextOpenChatWindowIndex()
		local window = index and FCF_GetChatFrameByID(index)
		if window then
			self.window = window
			SetChatWindowName(index, self.name)
			SetChatWindowShown(index, true)
			window:Clear()
			window:RemoveAllMessageGroups()
			window:RemoveAllChannels()
			window:ReceiveAllPrivateMessages()
			window:AddMessageGroup("WHISPER")
			window:AddMessageGroup("BN_WHISPER")
			if not self.hooked[window] then
				-- Preserve the native OnEvent and AddMessage implementations. Post-hooks
				-- hide the window and reset its sound timer after native processing.
				window:HookScript("OnEvent", function()
					if Sink.active and Sink.window == window then Sink:Hide() end
				end)
				window:HookScript("OnShow", function()
					if Sink.active and Sink.window == window then Sink:Hide() end
				end)
				local tab = _G[window:GetName() .. "Tab"]
				if tab then
					tab:HookScript("OnShow", function()
						if Sink.active and Sink.window == window then tab:Hide() end
					end)
				end
				self.hooked[window] = true
			end
		end
		self.busy = false
	end
	if not self.window then return end -- No free slot: keep native visible chat available.
	if not self.window:ContainsMessageGroup("WHISPER") then self.window:AddMessageGroup("WHISPER") end
	if not self.window:ContainsMessageGroup("BN_WHISPER") then self.window:AddMessageGroup("BN_WHISPER") end
	self.active = true
	self:KeepInlineMode()
	self:Hide()
end

function Sink:Disable()
	self.active = false
	local window = self.window
	if window and GetChatWindowInfo(window:GetID()) == self.name then
		window:RemoveAllMessageGroups()
		window:RemoveAllChannels()
		window:ReceiveAllPrivateMessages()
		self:Hide()
		window.tellTimer = nil
		SetChatWindowShown(window:GetID(), false)
	end
	self.window = nil
	if self.restoreMode and GetCVar("whisperMode") == "inline" then SetCVar("whisperMode", self.restoreMode) end
	self.restoreMode = nil
	self.events:UnregisterAllEvents()
end

Sink.events = CreateFrame("Frame")
Sink.events:SetScript("OnEvent", function(_, event, name)
	if event == "PLAYER_LOGOUT" then
		Sink:Disable()
	elseif event == "CVAR_UPDATE" then
		if Sink.active and name and name:lower() == "whispermode" then Sink:KeepInlineMode() end
	else
		Sink:Refresh()
	end
end)

function Sink:Enable()
	for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "UPDATE_CHAT_WINDOWS", "PLAYER_REGEN_ENABLED", "CVAR_UPDATE", "PLAYER_LOGOUT" }) do
		self.events:RegisterEvent(event)
	end
	self:Refresh()
end
