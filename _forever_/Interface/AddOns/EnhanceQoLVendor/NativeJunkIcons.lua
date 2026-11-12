local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local Junk = { buttons = setmetatable({}, { __mode = "k" }) }

function Junk.IsNativeButton(button)
	local parent = button and button.GetParent and button:GetParent()
	if not parent then return false end
	if parent == _G.ContainerFrameCombinedBags then return true end
	local frames = _G.ContainerFrameContainer and _G.ContainerFrameContainer.ContainerFrames
	for _, frame in ipairs(frames or {}) do
		if parent == frame then return true end
	end
	local name = parent.GetName and parent:GetName()
	return name and name:match("^ContainerFrame%d+$") ~= nil
end

function Junk.GetInfo(button)
	if not (button and button.GetID and C_Container and C_Container.GetContainerItemInfo) then return nil end
	local parent = button.GetParent and button:GetParent()
	local bag = button.GetBagID and button:GetBagID() or (parent and parent.GetID and parent:GetID())
	local slot = button:GetID()
	if issecretvalue and (issecretvalue(bag) or issecretvalue(slot)) then return nil end
	if type(bag) ~= "number" or type(slot) ~= "number" or slot < 1 then return nil end
	return C_Container.GetContainerItemInfo(bag, slot)
end

function Junk.Apply(button)
	if not (addon.db and addon.db.vendorAlwaysShowJunkIcon) then return end
	if not (Junk.IsNativeButton(button) and button.JunkIcon and button.JunkIcon.SetShown) then return end
	if not button._eqolNativeJunkHook and type(button.UpdateJunkItem) == "function" then
		hooksecurefunc(button, "UpdateJunkItem", Junk.Apply)
		button._eqolNativeJunkHook = true
	end
	local info = Junk.GetInfo(button)
	local show = false
	if info and not (issecretvalue and (issecretvalue(info.quality) or issecretvalue(info.hasNoValue))) then
		show = info.quality == 0 and not info.hasNoValue
	end
	button.JunkIcon:SetShown(show)
	Junk.buttons[button] = true
end

function Junk.VisitFrame(frame)
	if not frame or not (addon.db and addon.db.vendorAlwaysShowJunkIcon) then return end
	if frame.EnumerateValidItems then
		for _, button in frame:EnumerateValidItems() do Junk.Apply(button) end
	else
		local name = frame.GetName and frame:GetName()
		for index = 1, frame.size or 0 do
			local button = (name and _G[name .. "Item" .. index]) or frame["Item" .. index]
			if button then Junk.Apply(button) end
		end
	end
end

function Junk.VisitFrames(callback)
	local seen = {}
	local function visit(frame)
		if frame and not seen[frame] then
			seen[frame] = true
			callback(frame)
		end
	end
	visit(_G.ContainerFrameCombinedBags)
	for _, frame in ipairs((_G.ContainerFrameContainer and _G.ContainerFrameContainer.ContainerFrames) or {}) do visit(frame) end
	for index = 1, _G.NUM_CONTAINER_FRAMES or 13 do visit(_G["ContainerFrame" .. index]) end
end

function Junk.InstallHooks()
	local mixin = _G.ContainerFrameItemButtonMixin
	if not Junk.modernHook and mixin and type(mixin.UpdateJunkItem) == "function" then
		hooksecurefunc(mixin, "UpdateJunkItem", function(button)
			if not button._eqolNativeJunkHook then Junk.Apply(button) end
		end)
		Junk.modernHook = true
	end
	if not Junk.classicHook and type(_G.ContainerFrame_Update) == "function" then
		hooksecurefunc("ContainerFrame_Update", Junk.VisitFrame)
		Junk.classicHook = true
	end
end

function Junk.Restore()
	for button in pairs(Junk.buttons) do
		if button.JunkIcon then
			local info = Junk.GetInfo(button)
			if button.UpdateJunkItem then
				button:UpdateJunkItem(info and info.quality, info and info.hasNoValue)
			else
				button.JunkIcon:Hide()
			end
		end
		Junk.buttons[button] = nil
	end
	if Junk.classicHook then
		Junk.VisitFrames(function(frame)
			if not frame.UpdateItems and frame.IsShown and frame:IsShown() then _G.ContainerFrame_Update(frame) end
		end)
	end
end

function addon.Vendor.functions.RefreshNativeJunkIcons()
	local enabled = addon.db and addon.db.vendorAlwaysShowJunkIcon == true
	if not enabled then
		if Junk.eventFrame then Junk.eventFrame:UnregisterAllEvents() end
		if Junk.enabled then Junk.Restore() end
		Junk.enabled = false
		return
	end
	Junk.enabled = true
	Junk.InstallHooks()
	if not Junk.eventFrame then
		Junk.eventFrame = CreateFrame("Frame")
		Junk.eventFrame:SetScript("OnEvent", function() addon.Vendor.functions.RefreshNativeJunkIcons() end)
	end
	for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED", "MERCHANT_SHOW", "MERCHANT_CLOSED" }) do Junk.eventFrame:RegisterEvent(event) end
	if not Junk.modernHook and not Junk.classicHook then
		Junk.eventFrame:RegisterEvent("ADDON_LOADED")
	else
		Junk.eventFrame:UnregisterEvent("ADDON_LOADED")
	end
	Junk.VisitFrames(Junk.VisitFrame)
end
