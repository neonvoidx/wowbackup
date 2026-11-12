-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LibTime = LibStub("LibTime-1.0")

local RSLogger = private.NewLib("RareScannerLogger")

-- RareScanner libraries
local RSConstants = private.ImportLib("RareScannerConstants")

function RSLogger:CreateChatFrame(name)
	-- Closes current window if exists
	if (self.RARESCANNER_CHAT_FRAME) then
		local curChatName = GetChatWindowInfo(self.RARESCANNER_CHAT_FRAME:GetID());
		-- Avoids closing General or Combat Log
		if (curChatName ~= COMBAT_LOG and curChatName ~= COMMUNITIES_DEFAULT_CHANNEL_NAME) then
			FCF_Close(self.RARESCANNER_CHAT_FRAME);
		end
	end
		
	if (name) then		
		-- Show if it already exists
		local exists = false
		for i = 1, Constants.ChatFrameConstants.MaxChatWindows do
			local chatName, _, _, _, _, _, shown, _, _, _ = GetChatWindowInfo(i);
			if (chatName == name) then
				self.RARESCANNER_CHAT_FRAME = _G["ChatFrame"..i]
				if (not shown) then
					SetChatWindowShown(i, true);
					FCF_DockFrame(self.RARESCANNER_CHAT_FRAME, i, true)
					if (ChatFrame1) then
						FCF_SelectDockFrame(ChatFrame1)
					end
				end
				exists = true
				break
			end
		end
		
		-- Creates a new window if it doesnt exist
		if (not exists) then
			self.RARESCANNER_CHAT_FRAME = FCF_OpenNewWindow(name)
			self.RARESCANNER_CHAT_FRAME:RemoveAllMessageGroups()
			self.RARESCANNER_CHAT_FRAME:RemoveAllChannels()
			
			if (ChatFrame1) then
				FCF_SelectDockFrame(ChatFrame1)
			end
		end
	else		
		self.RARESCANNER_CHAT_FRAME = nil
	end
end

local function PrintHeaderMessage(self, header, message)
	-- Cannot use RSConfigDB in this class
	local printMessage
	if (private.db.display.displayTimestampChatMessage) then
		local timeStamp = LibTime.GetTimeString("LocalTime",true,true)
		printMessage = string.format("|cFFFCD6CD[%s] |cFF00FF00[%s]: |cFFFFFFFF%s", timeStamp, header, message)
	else
		printMessage = string.format("|cFF00FF00[%s]: |cFFFFFFFF%s", header, message)
	end

	-- Prints to custom chat frame or default
	if (self.RARESCANNER_CHAT_FRAME) then
		self.RARESCANNER_CHAT_FRAME:AddMessage(printMessage)
	else
		print(printMessage)
	end
end

function RSLogger:PrintMessage(message)
	PrintHeaderMessage(self, "RareScanner", message)
end

-- Same chat as the rest of messages, but with the name of the telemetry in the header
function RSLogger:PrintTelemetryMessage(message)
	PrintHeaderMessage(self, "RareScanner Telemetry", message)
end

function RSLogger:PrintDebugMessage(message)
	if (RSConstants.DEBUG_MODE) then
		local printMessage = string.format("|cFFDC143C[RareScanner]: |cFFFFFFFF%s", tostring(message))
	
		-- Prints to custom chat frame or default
		if (self.RARESCANNER_CHAT_FRAME) then
			self.RARESCANNER_CHAT_FRAME:AddMessage(printMessage)
		else
			print(printMessage)
		end
	end
end

local TELEMETRY_CHAT_FRAME_NAME = "RareScanner Telemetry"

--- Returns the chat window where the debug messages of the telemetry are printed. It is created if it doesn't exist
function RSLogger:GetTelemetryChatFrame()
	-- The player can close the window, or its place can be used by another one, so the one saved must still be ours and open
	if (self.TELEMETRY_CHAT_FRAME) then
		local chatName, _, _, _, _, _, shown = GetChatWindowInfo(self.TELEMETRY_CHAT_FRAME:GetID())
		if (chatName == TELEMETRY_CHAT_FRAME_NAME and shown) then
			return self.TELEMETRY_CHAT_FRAME
		end

		self.TELEMETRY_CHAT_FRAME = nil
	end

	-- A chat window can't be created during combat
	if (InCombatLockdown()) then
		return nil
	end

	for i = 1, Constants.ChatFrameConstants.MaxChatWindows do
		local chatName, _, _, _, _, _, shown = GetChatWindowInfo(i)
		if (chatName == TELEMETRY_CHAT_FRAME_NAME) then
			self.TELEMETRY_CHAT_FRAME = _G["ChatFrame"..i]
			if (not shown) then
				SetChatWindowShown(i, true)
				FCF_DockFrame(self.TELEMETRY_CHAT_FRAME, i, true)
				if (ChatFrame1) then
					FCF_SelectDockFrame(ChatFrame1)
				end
			end

			return self.TELEMETRY_CHAT_FRAME
		end
	end

	-- It returns nothing if all the chat windows are in use
	local chatFrame = FCF_OpenNewWindow(TELEMETRY_CHAT_FRAME_NAME)
	if (not chatFrame) then
		return nil
	end

	chatFrame:RemoveAllMessageGroups()
	chatFrame:RemoveAllChannels()
	if (ChatFrame1) then
		FCF_SelectDockFrame(ChatFrame1)
	end

	self.TELEMETRY_CHAT_FRAME = chatFrame
	return chatFrame
end

--- Debug messages of the telemetry, in their own chat window so they are not mixed with the rest
function RSLogger:PrintTelemetryDebugMessage(message)
	if (not RSConstants.DEBUG_MODE) then
		return
	end

	local printMessage = string.format("|cFFFCD6CD[%s] |cFFDC143C[RareScanner Telemetry]: |cFFFFFFFF%s", date("%H:%M:%S"), tostring(message))
	local chatFrame = self:GetTelemetryChatFrame()
	if (chatFrame) then
		chatFrame:AddMessage(printMessage)
	else
		-- It couldn't be created (combat), so it goes to the default one
		print(printMessage)
	end
end

function RSLogger:PrintDebugMessageEntityID(receivedEntityID, message)
	if (RSConstants.DEBUG_MODE and receivedEntityID and RSConstants.MAP_ENTITY_ID) then
		if (receivedEntityID == RSConstants.MAP_ENTITY_ID) then
			RSLogger:PrintDebugMessage(message)
		end
	end
end

function RSLogger:PrintDebugMessageItemID(receivedItemID, message)
	if (RSConstants.DEBUG_MODE and receivedItemID and RSConstants.LOOT_ITEM_ID) then
		if (receivedItemID == RSConstants.LOOT_ITEM_ID) then
			RSLogger:PrintDebugMessage(message)
		end
	end
end
