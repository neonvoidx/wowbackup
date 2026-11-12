local addon = _G.EnhanceQoL
local ChannelHistory = addon.ChatIM.ChannelHistory
local S = addon.ChatHistoryStorage

function ChannelHistory:CancelHistoryView()
	local runtime = self.runtime
	local job = runtime and runtime.historyViewJob
	if job and S.readerThread == job then S.readerThread = nil end
	if runtime then runtime.historyViewJob = nil end
	if self.historyViewDriver then self.historyViewDriver:SetScript("OnUpdate", nil) end
end

function ChannelHistory:StepHistoryView()
	local job = self.runtime and self.runtime.historyViewJob
	if not job then return end
	if not self.debugFrame or not self.debugFrame:IsShown() then self:CancelHistoryView(); return end
	S.readerThread, S.readDeadline = job, S.ReadClock() + 3
	local ok, message = coroutine.resume(job)
	if not ok or coroutine.status(job) == "dead" then
		self:CancelHistoryView()
		if not ok then S.Report(message) end
		if self.runtime.historyRefreshAfterLoad then
			self.runtime.historyRefreshAfterLoad = nil
			self:RequestLogRefresh()
		end
	end
end

function ChannelHistory:RunHistoryView(collect, render)
	self:CancelHistoryView()
	self.runtime = self.runtime or {}
	self.runtime.historyRefreshAfterLoad = nil
	self.runtime.historyViewJob = coroutine.create(function() render(collect()) end)
	if not self.historyViewDriver then self.historyViewDriver = CreateFrame("Frame") end
	self.historyViewDriver:SetScript("OnUpdate", function() self:StepHistoryView() end)
	self:StepHistoryView()
end
