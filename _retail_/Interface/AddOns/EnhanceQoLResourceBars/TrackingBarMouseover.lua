local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local ResourceBars = addon.Aura.ResourceBars
local Mouseover = { frames = {} }
ResourceBars.TrackingMouseover = Mouseover

function Mouseover:GetRuleOptions()
	if self.options then return self.options end
	local options = {}
	for _, option in ipairs(ResourceBars.GetVisibilityRuleOptions()) do
		options[#options + 1] = option
	end
	local metadata = addon.functions.GetVisibilityRuleMetadata().MOUSEOVER
	options[#options + 1] = { value = "MOUSEOVER", text = metadata.label, label = metadata.label, order = metadata.order, group = metadata.group, groupOrder = metadata.groupOrder, menuSection = metadata.menuSection }
	table.sort(options, function(a, b) return (a.order or 999) < (b.order or 999) end)
	self.options = options
	return options
end

function Mouseover:Clear(frame)
	if not self.frames[frame] then return end
	self.frames[frame] = nil
	ResourceBars.ApplyMouseoverAlphaToFrame(frame, false)
	if not next(self.frames) and self.watcher then self.watcher:Hide() end
end

function Mouseover:Update(frame, record)
	local shown = record.logic:ShouldShowManual(record.cfg, record.visibility, frame)
	if (frame._rbMouseoverAlphaHidden == true) ~= (not shown) then ResourceBars.ApplyMouseoverAlphaToFrame(frame, not shown) end
end

function Mouseover:Apply(frame, cfg, visibility, logic)
	local record = { cfg = cfg, visibility = visibility, logic = logic }
	self.frames[frame] = record
	if not self.watcher then
		self.watcher = CreateFrame("Frame")
		self.watcher.elapsed = 0
		self.watcher:SetScript("OnUpdate", function(watcher, elapsed)
			watcher.elapsed = watcher.elapsed + elapsed
			if watcher.elapsed < 0.1 then return end
			watcher.elapsed = 0
			for trackedFrame, trackedRecord in pairs(self.frames) do
				self:Update(trackedFrame, trackedRecord)
			end
		end)
	end
	self.watcher:Show()
	-- Keep the frame shown so its screen area remains available for mouseover.
	logic:ApplyManualFrameVisibility(frame, true)
	if not frame:IsShown() then frame:Show() end
	self:Update(frame, record)
end
