local _, addon = ...

local ComboPoints = { hookedFrames = setmetatable({}, { __mode = "k" }) }
addon.PersonalResourceComboPoints = ComboPoints

function ComboPoints:IsEnabled() return addon.db and addon.db.personalResourceComboPointsCentered == true and addon.variables.unitClass == "ROGUE" end

function ComboPoints:Apply(frame)
	local display = _G.PersonalResourceDisplayFrame
	if self.applying or not self:IsEnabled() or not display or frame ~= display.classFrame then return end

	self.applying = true
	-- The player-frame template adds negative padding above five points. The
	-- personal display already centers the frame, so its point row needs no padding.
	frame.leftPadding = 0
	frame:Layout()
	self.managedFrame = frame
	self.applying = nil
end

function ComboPoints:Install()
	if not self:IsEnabled() then return false end
	local display = _G.PersonalResourceDisplayFrame
	if not display then return false end
	if self.display ~= display then
		self.display = display
		hooksecurefunc(display, "SetupClassBar", function() self:Install() end)
		display:HookScript("OnShow", function() self:Install() end)
	end

	local frame = display.classFrame
	if frame and frame.UpdateMaxPower and frame.Layout then
		if not self.hookedFrames[frame] then
			self.hookedFrames[frame] = true
			hooksecurefunc(frame, "UpdateMaxPower", function(bar) self:Apply(bar) end)
		end
		self:Apply(frame)
	end
	return true
end

function ComboPoints:Update()
	if self:IsEnabled() then
		if not self:Install() then
			if not self.watcher then
				self.watcher = CreateFrame("Frame")
				self.watcher:SetScript("OnEvent", function(_, _, name)
					if name == "Blizzard_PersonalResourceDisplay" then self:Update() end
				end)
			end
			self.watcher:RegisterEvent("ADDON_LOADED")
			return
		end
	else
		local frame = self.managedFrame
		self.managedFrame = nil
		if frame then
			-- UpdateMaxPower restores Blizzard's padding, but may skip Layout when
			-- the maximum hasn't changed. Relayout explicitly when disabling.
			frame:UpdateMaxPower()
			frame:Layout()
		end
	end
	if self.watcher then self.watcher:UnregisterAllEvents() end
end
