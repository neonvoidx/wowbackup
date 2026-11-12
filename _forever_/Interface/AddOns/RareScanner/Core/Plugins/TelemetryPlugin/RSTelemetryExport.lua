-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local RSTelemetryExport = private.NewLib("RareScannerTelemetryExport")

local AL = LibStub("AceLocale-3.0"):GetLocale("RareScanner", false)

-- RareScanner libraries
local RSConstants = private.ImportLib("RareScannerConstants")
local RSTelemetryDB = private.ImportLib("RareScannerTelemetryDB")
local RSLogger = private.ImportLib("RareScannerLogger")

---============================================================================
-- Export of the telemetry, to be uploaded to the portal. Format (one item per line):
--   RSTELEMETRY,<format version>,<addon version>,<game build>
--   S,npcID,spawnTime,deathTime,mapID,gap,shard,offline,live,sender,game
--   K,npcID,shard,timestamp,mapID,game
-- The text is compressed (deflate) and encoded in Base64, so it can be copied as one string
---============================================================================

local function GetAddonVersion()
	local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "0"
	return string.sub(string.gsub(version, "[^%w%._%-]", ""), 1, 20)
end

local function GetSampleLine(npcID, sample)
	return string.format("S,%d,%d,%s,%s,%d,%s,%s,%d,%s,%s", npcID, sample.spawnTime, sample.deathTime or "", sample.mapID or "", sample.gap and 1 or 0, sample.shard or "", sample.offline or "", sample.live and 1 or 0, sample.sender or "", RSConstants.TELEMETRY_GAME)
end

--- Returns the text of the export and the number of samples.
-- If there are too many lines the newest samples go first. The kills are not exported: with the obfuscated GUIDs they can't be paired
function RSTelemetryExport.BuildText()
	local samples = {}
	for npcID, npcData in pairs(RSTelemetryDB.GetAllTelemetryNpcs()) do
		for _, sample in ipairs(npcData.samples) do
			table.insert(samples, { npcID = npcID, sample = sample })
		end
	end

	table.sort(samples, function(a, b)
		if (a.sample.spawnTime ~= b.sample.spawnTime) then
			return a.sample.spawnTime > b.sample.spawnTime
		end
		return a.npcID < b.npcID
	end)

	local lines = { string.format("RSTELEMETRY,%d,%s,%d", RSConstants.TELEMETRY_EXPORT_VERSION, GetAddonVersion(), select(4, GetBuildInfo()) or 0) }
	local samplesCount = 0
	for _, item in ipairs(samples) do
		if (#lines > RSConstants.TELEMETRY_EXPORT_MAX_LINES) then
			break
		end

		table.insert(lines, GetSampleLine(item.npcID, item.sample))
		samplesCount = samplesCount + 1
	end

	return table.concat(lines, "\n"), samplesCount
end

--- Compresses and encodes the text. Returns nil if it can't be done
function RSTelemetryExport.Encode(text)
	local isCompressed, compressedText = pcall(C_EncodingUtil.CompressString, text, Enum.CompressionMethod.Deflate)
	if (not isCompressed or not compressedText) then
		return nil
	end

	local isEncoded, encodedText = pcall(C_EncodingUtil.EncodeBase64, compressedText)
	if (not isEncoded) then
		return nil
	end

	return encodedText
end

---============================================================================
-- Window with the text to copy
---============================================================================

local exportFrame

local function CreateExportFrame()
	local frame = CreateFrame("Frame", "RareScannerTelemetryExportFrame", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(560, 180)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame.TitleText:SetText(AL["TELEMETRY_EXPORT_TITLE"])
	tinsert(UISpecialFrames, frame:GetName())

	frame.Help = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.Help:SetPoint("TOPLEFT", 14, -32)
	frame.Help:SetPoint("TOPRIGHT", -14, -32)
	frame.Help:SetJustifyH("LEFT")
	frame.Help:SetText(AL["TELEMETRY_EXPORT_HELP"])

	frame.PortalHelp = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.PortalHelp:SetPoint("TOPLEFT", 14, -52)
	frame.PortalHelp:SetText(AL["TELEMETRY_EXPORT_PORTAL"])

	-- The addons can't open the browser, so the link is selected with a click to be copied
	frame.PortalUrl = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	frame.PortalUrl:SetAutoFocus(false)
	frame.PortalUrl:SetHeight(20)
	frame.PortalUrl:SetPoint("LEFT", frame.PortalHelp, "RIGHT", 12, 0)
	frame.PortalUrl:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
	frame.PortalUrl:SetTextColor(0.3, 0.65, 1)
	frame.PortalUrl:SetText(RSConstants.TELEMETRY_PORTAL_URL)
	frame.PortalUrl:SetCursorPosition(0)
	frame.PortalUrl:SetScript("OnTextChanged", function(self, isUserInput)
		if (isUserInput) then
			self:SetText(RSConstants.TELEMETRY_PORTAL_URL)
			self:HighlightText()
		end
	end)

	frame.Summary = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.Summary:SetPoint("BOTTOMLEFT", 14, 12)

	frame.TextArea = CreateFrame("ScrollFrame", nil, frame, "InputScrollFrameTemplate")
	frame.TextArea:SetPoint("TOPLEFT", 14, -82)
	frame.TextArea:SetPoint("BOTTOMRIGHT", -14, 34)
	frame.TextArea.CharCount:Hide()

	-- The text can't be edited, but it can be selected and copied
	local editBox = frame.TextArea.EditBox
	editBox:SetMaxLetters(0)
	editBox:HookScript("OnTextChanged", function(self, isUserInput)
		if (isUserInput and frame.exportedText) then
			self:SetText(frame.exportedText)
			self:HighlightText()
		end
	end)

	-- With the focus in the text box the first ESC would only take the focus out
	editBox:HookScript("OnEscapePressed", function()
		frame:Hide()
	end)
	frame.PortalUrl:HookScript("OnEscapePressed", function()
		frame:Hide()
	end)

	frame:Hide()
	return frame
end

function RSTelemetryExport.ShowWindow()
	local text, samplesCount = RSTelemetryExport.BuildText()
	if (samplesCount == 0) then
		RSLogger:PrintTelemetryMessage(AL["TELEMETRY_EXPORT_NO_DATA"])
		return
	end

	local encodedText = RSTelemetryExport.Encode(text)
	if (not encodedText) then
		RSLogger:PrintTelemetryMessage(AL["TELEMETRY_EXPORT_ERROR"])
		return
	end

	if (not exportFrame) then
		exportFrame = CreateExportFrame()
	end

	exportFrame.exportedText = encodedText
	exportFrame.Summary:SetText(string.format(AL["TELEMETRY_EXPORT_SUMMARY"], samplesCount, 0))
	exportFrame.TextArea.EditBox:SetText(encodedText)
	exportFrame:Show()
	exportFrame.TextArea.EditBox:SetFocus()
	exportFrame.TextArea.EditBox:HighlightText()
end
