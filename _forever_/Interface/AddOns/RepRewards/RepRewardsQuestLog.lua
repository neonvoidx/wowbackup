-------------------------------------------------------------------------
-- RepRewardsQuestLog.lua
-- Appends quest reputation to the bottom of the quest description or objectives.
-------------------------------------------------------------------------

local Data = RepRewards_Data

local repBlock

local function Enabled()
	if RepRewards and RepRewards.ShowQuestLogReputation then
		return RepRewards:ShowQuestLogReputation()
	end
	local db = RepRewards_DB
	if type(db) ~= "table" then
		db = ReputationRewards_DB
	end
	if type(db) ~= "table" or db.showQuestLogReputation == nil then
		return true
	end
	return not not db.showQuestLogReputation
end

local function SafeNumber(value)
	if type(issecretvalue) == "function" and issecretvalue(value) then
		return nil
	end
	if type(value) ~= "number" then
		if type(IsSecret) == "function" then
			local ok, secret = pcall(IsSecret, value)
			if ok and secret then return nil end
		end
		value = tonumber(value)
	end
	return value
end

local function FactionLabel(factionID)
	factionID = SafeNumber(factionID)
	if not factionID then return nil end

	if C_Reputation and C_Reputation.GetFactionDataByID then
		local ok, info = pcall(C_Reputation.GetFactionDataByID, factionID)
		if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
			local isHeader = info.isHeader and not info.isHeaderWithRep
			local hasRep = info.isHeaderWithRep or info.hasRep or not info.isHeader
			return info.name, isHeader, hasRep
		end
	end

	if type(GetFactionInfoByID) == "function" then
		local ok, name, _, _, _, _, _, _, _, isHeader, _, hasRep = pcall(GetFactionInfoByID, factionID)
		if ok and type(name) == "string" and name ~= "" then
			return name, isHeader, hasRep
		end
	end

	local meta = Data and Data.factions and Data.factions[factionID]
	if meta and meta.name then
		return meta.name, false, true
	end

	return "Faction " .. factionID, false, true
end

local function AddReward(results, seen, factionID, amount, scaled)
	factionID = SafeNumber(factionID)
	amount = SafeNumber(amount)
	if not factionID or not amount or amount == 0 or seen[factionID] then return end

	-- GetQuestLogRewardFactionInfo reports standing in hundredths (25000 = 250).
	if scaled then
		amount = math.floor(amount / 100)
	else
		amount = math.floor(amount + 0.5)
	end
	if amount == 0 then return end

	local name, isHeader, hasRep = FactionLabel(factionID)
	if not name or (isHeader and not hasRep) then return end

	seen[factionID] = true
	results[#results + 1] = { name = name, amount = amount }
end

local function CollectRepRewards()
	local results, seen = {}, {}

	if type(ProcessQuestLogRewardFactions) == "function" then
		pcall(ProcessQuestLogRewardFactions)
	end

	if type(GetNumQuestLogRewardFactions) == "function" and type(GetQuestLogRewardFactionInfo) == "function" then
		local ok, count = pcall(GetNumQuestLogRewardFactions)
		count = ok and SafeNumber(count) or 0
		for i = 1, count or 0 do
			local infoOk, factionID, amount = pcall(GetQuestLogRewardFactionInfo, i)
			if infoOk then
				AddReward(results, seen, factionID, amount, true)
			end
		end
	end

	if #results > 0 then return results end

	local questID
	if type(GetQuestLogSelectedID) == "function" then
		local ok, id = pcall(GetQuestLogSelectedID)
		if ok then questID = SafeNumber(id) end
	end
	if not questID and C_QuestLog and type(C_QuestLog.GetSelectedQuest) == "function" then
		local ok, id = pcall(C_QuestLog.GetSelectedQuest)
		if ok then questID = SafeNumber(id) end
	end
	if not questID then return results end

	if C_QuestLog and type(C_QuestLog.GetQuestLogMajorFactionReputationRewards) == "function" then
		local ok, rewards = pcall(C_QuestLog.GetQuestLogMajorFactionReputationRewards, questID)
		if ok and type(rewards) == "table" then
			for _, reward in ipairs(rewards) do
				if type(reward) == "table" then
					AddReward(results, seen, reward.factionID, reward.rewardAmount, false)
				end
			end
		end
	end

	return results
end

local function FormatAmount(amount)
	local number = tostring(math.abs(amount))
	if type(BreakUpLargeNumbers) == "function" then
		local ok, formatted = pcall(BreakUpLargeNumbers, math.abs(amount))
		if ok and type(formatted) == "string" and formatted ~= "" then
			number = formatted
		end
	end
	if amount > 0 then
		return "|cff1a7f1a+" .. number .. "|r"
	end
	return "|cffaa2200-" .. number .. "|r"
end

local function EnsureBlock(parent)
	if repBlock and repBlock:GetParent() ~= parent then
		repBlock:SetParent(parent)
	end
	if repBlock then return repBlock end

	repBlock = CreateFrame("Frame", nil, parent)
	repBlock:SetSize(250, 16)
	repBlock.lines = {}
	return repBlock
end

local function Line(block, index)
	local line = block.lines[index]
	if line then return line end
	line = block:CreateFontString(nil, "OVERLAY", QuestFont and "QuestFont" or "GameFontHighlight")
	line:SetJustifyH("LEFT")
	line:SetJustifyV("TOP")
	line:SetWordWrap(true)
	line:SetTextColor(0, 0, 0)
	block.lines[index] = line
	return line
end

local function FillLines(block, rewards, width)
	local y = 0
	for i, reward in ipairs(rewards) do
		local line = Line(block, i)
		line:ClearAllPoints()
		line:SetWidth(width)
		if i == 1 then
			line:SetPoint("TOPLEFT", block, "TOPLEFT", 0, 0)
		else
			line:SetPoint("TOPLEFT", block.lines[i - 1], "BOTTOMLEFT", 0, -2)
		end
		line:SetText(FormatAmount(reward.amount) .. " reputation with " .. reward.name)
		line:Show()
		local lineHeight = 14
		local heightOk, measured = pcall(line.GetStringHeight, line)
		if heightOk and type(measured) == "number" and measured > 0 then
			lineHeight = measured
		end
		y = y + lineHeight + 2
	end
	for i = #rewards + 1, #block.lines do
		block.lines[i]:Hide()
	end
	block:SetHeight(math.max(14, y))
end

local function HideBlock()
	if repBlock then repBlock:Hide() end
end

-- IsShown, not IsVisible. Reward rows are shown during layout before the
-- parent chain reports visible, and IsVisible was skipping every anchor.
local function IsOnScreen(frame)
	if not frame or not frame.IsShown then return false end
	return frame:IsShown()
end

local lastAnnounce

local function Announce(rewards)
	-- local lines = {}
	-- if not rewards or #rewards == 0 then
	-- 	lines[1] = "This quest has no reputation rewards."
	-- else
	-- 	lines[1] = "This quest should show:"
	-- 	for _, reward in ipairs(rewards) do
	-- 		local amount = reward.amount or 0
	-- 		local sign = amount > 0 and "+" or ""
	-- 		lines[#lines + 1] = string.format("  %s%d reputation with %s", sign, amount, reward.name)
	-- 	end
	-- end
	-- local text = table.concat(lines, "\n")
	-- if text == lastAnnounce then return end
	-- lastAnnounce = text
	-- if RepRewards and RepRewards.Print then
	-- 	for _, line in ipairs(lines) do
	-- 		RepRewards:Print(line)
	-- 	end
	-- else
	-- 	for _, line in ipairs(lines) do
	-- 		print("|cff33ff99RepRewards|r: " .. line)
	-- 	end
	-- end
end

local function Numeric(fn, obj)
	if type(fn) ~= "function" or not obj then return nil end
	local ok, value = pcall(fn, obj)
	if ok and type(value) == "number" then return value end
	return nil
end

local function FrameName(frame)
	if not frame or not frame.GetName then return "unnamed" end
	local ok, name = pcall(frame.GetName, frame)
	if ok and type(name) == "string" and name ~= "" then return name end
	return "unnamed"
end

local function ReadText(frame)
	if not frame or not frame.GetText then return nil end
	local ok, text = pcall(frame.GetText, frame)
	if ok and type(text) == "string" then return text end
	return nil
end

local function BottomEdge(frame)
	if not IsOnScreen(frame) then return nil end
	return Numeric(frame.GetBottom, frame)
end

local function IsFontString(frame)
	if not frame or not frame.GetObjectType then return false end
	local ok, kind = pcall(frame.GetObjectType, frame)
	return ok and kind == "FontString"
end

local QUEST_TEXT_NAMES = {
	"QuestInfoObjectivesText",
	"QuestLogObjectivesText",
	"QuestInfoDescriptionText",
	"QuestLogQuestDescription",
}

local function EachRegion(root, visitor)
	if not root then return end
	local seen = {}
	local function walk(frame, depth)
		if not frame or seen[frame] or depth > 6 then return end
		seen[frame] = true
		visitor(frame)
		if frame.GetRegions then
			local ok, regions = pcall(function() return { frame:GetRegions() } end)
			if ok and type(regions) == "table" then
				for _, region in ipairs(regions) do
					if region and not seen[region] then
						seen[region] = true
						visitor(region)
					end
				end
			end
		end
		if frame.GetChildren then
			local ok, children = pcall(function() return { frame:GetChildren() } end)
			if ok and type(children) == "table" then
				for _, child in ipairs(children) do
					walk(child, depth + 1)
				end
			end
		end
	end
	walk(root, 0)
end

local function IsReputationLine(line)
	if not line or not line:find(" reputation with ", 1, true) then return false end
	return line:find("|cff1a7f1a", 1, true) or line:find("|cffaa2200", 1, true)
end

local function StripSuffix(text)
	if not text then return "" end
	text = text:gsub("|Hrrep|h|h", ""):gsub("|Hrrep", "")
	local lines = { strsplit("\n", text) }
	local cut
	for i, line in ipairs(lines) do
		if IsReputationLine(line) then
			cut = i
			break
		end
	end
	if not cut then
		return (text:gsub("%s+$", ""))
	end
	while cut > 1 do
		local previous = lines[cut - 1]
		local plain = previous:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
		plain = plain:gsub("^%s+", ""):gsub("%s+$", "")
		if plain ~= "" and plain ~= "Reputation Awarded" and plain ~= "Reputation Awarded:" then break end
		cut = cut - 1
	end
	local kept = {}
	for i = 1, cut - 1 do
		kept[#kept + 1] = lines[i]
	end
	return (table.concat(kept, "\n"):gsub("%s+$", ""))
end

local function SkipText(text)
	if not text or text == "" then return true end
	text = StripSuffix(text)
	if text == "" then return true end
	local plain = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
	plain = plain:gsub("^%s+", ""):gsub("%s+$", "")
	local heading = plain:lower()
	if plain == "" or #plain < 8 then return true end
	if heading == "description" or heading == "objectives" or heading == "rewards" then
		return true
	end
	if plain:find("^You will receive") or plain:find("^You will also receive") or plain:find("^Choose one") then
		return true
	end
	return false
end

-- Lowest description or objectives font string currently drawn in the quest log.
local function QuestTextBottom()
	local names = {}
	for _, name in ipairs(QUEST_TEXT_NAMES) do
		names[#names + 1] = name
	end
	for i = 1, 10 do
		names[#names + 1] = "QuestInfoObjective" .. i
		names[#names + 1] = "QuestLogObjective" .. i
	end

	local best, bestBottom
	local function consider(frame)
		if not IsFontString(frame) or not IsOnScreen(frame) then return end
		if frame == repBlock then return end
		local name = FrameName(frame)
		if name:find("Reward") or name:find("Item") or name:find("Money") or name:find("Honor") or name:find("Spell") or name:find("Header") or name:find("Title") then
			return
		end
		local text = ReadText(frame)
		if text and SkipText(text) then return end
		local bottom = BottomEdge(frame)
		if bottom and (not bestBottom or bottom < bestBottom) then
			best, bestBottom = frame, bottom
		elseif not best then
			best = frame
		end
	end

	for _, name in ipairs(names) do
		consider(_G[name])
	end
	if best then return best end

	local roots = {
		_G.QuestLogDetailScrollChildFrame,
		_G.QuestInfoFrame,
		_G.QuestLogFrame,
	}
	for _, root in ipairs(roots) do
		EachRegion(root, consider)
		if best then return best end
	end
	return nil
end

local function ScrollChildOf(frame)
	local current = frame
	for _ = 1, 8 do
		if not current then break end
		local parent = current.GetParent and current:GetParent()
		if parent and parent.UpdateScrollChildRect then
			return current
		end
		current = parent
	end
	return _G.QuestLogDetailScrollChildFrame
end

local function RepSuffix(rewards)
	local lines = { "\n\nReputation Awarded:\n" }
	for _, reward in ipairs(rewards) do
		lines[#lines + 1] = FormatAmount(reward.amount) .. " reputation with " .. reward.name
	end
	return table.concat(lines, "\n") .. "\n\n"
end

local lastNote

local function Note(message)
	-- if message == lastNote then return end
	-- lastNote = message
	-- if RepRewards and RepRewards.Print then
	-- 	RepRewards:Print(message)
	-- else
	-- 	print("|cff33ff99RepRewards|r: " .. message)
	-- end
end

local function DrawBlock(anchor, rewards)
	local parent = ScrollChildOf(anchor)
	if not parent and anchor.GetParent then
		parent = anchor:GetParent()
	end
	if not parent then return false end
	local block = EnsureBlock(parent)
	local width = Numeric(anchor.GetWidth, anchor) or Numeric(parent.GetWidth, parent) or 260
	if width > 500 then width = 260 end
	width = math.max(180, width - 8)
	block:SetWidth(width)
	FillLines(block, rewards, width)
	block:ClearAllPoints()
	block:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
	block:Show()
	return true
end

local function HasReputationBlock(frame)
	local text = ReadText(frame)
	return text and text:find("Reputation Awarded:", 1, true) ~= nil
end

local function GiverIsOpen()
	local giver = _G.QuestFrame
	return giver and giver.IsShown and giver:IsShown()
end

local function FitToText(frame, force)
	if not frame or not frame.SetHeight then return end
	if not force and HasReputationBlock(frame) then return end
	if force and frame.SetText then
		local text = ReadText(frame)
		if text then
			local base = StripSuffix(text)
			if base ~= text then
				pcall(frame.SetText, frame, base)
			end
		end
	end
	if frame.SetJustifyV then
		pcall(frame.SetJustifyV, frame, "TOP")
	end
	-- Height 0 tells a font string to size itself to its text again.
	pcall(frame.SetHeight, frame, 0)
	local height = Numeric(frame.GetStringHeight, frame)
	if height and height > 1 then
		pcall(frame.SetHeight, frame, height)
	end
end

-- Trailing blank lines are not included in GetStringHeight, so the last
-- reputation line is clipped and drawn with an ellipsis. Measure the text,
-- then add room for those two lines.
local function EnsureRoom(textFrame)
	if not textFrame or not textFrame.SetHeight then return end
	if textFrame.SetJustifyV then
		pcall(textFrame.SetJustifyV, textFrame, "TOP")
	end
	if textFrame.SetMaxLines then
		pcall(textFrame.SetMaxLines, textFrame, 0)
	end
	if textFrame.SetWordWrap then
		pcall(textFrame.SetWordWrap, textFrame, true)
	end
	pcall(textFrame.SetHeight, textFrame, 0)
	local height = Numeric(textFrame.GetStringHeight, textFrame)
	if height and height > 1 then
		pcall(textFrame.SetHeight, textFrame, height + 36)
	end
end

-- A previous quest can leave the description header stretched. The body is
-- anchored under that header, so the extra height shows up as blank space.
local function ReleaseStretchedText(force)
	local names = {
		"QuestInfoDescriptionHeader",
		"QuestInfoObjectivesHeader",
		"QuestLogDescriptionTitle",
		"QuestInfoDescriptionText",
		"QuestLogQuestDescription",
		"QuestInfoObjectivesText",
		"QuestLogObjectivesText",
	}
	for _, name in ipairs(names) do
		FitToText(_G[name], force)
	end
end

local function ShowReputation(rewards)
	-- QuestFrame uses the same description widget as the quest log.
	if GiverIsOpen() then
		HideBlock()
		ReleaseStretchedText(true)
		return
	end
	if not Enabled() or not rewards or #rewards == 0 then
		HideBlock()
		ReleaseStretchedText()
		return
	end

	local textFrame = QuestTextBottom()
	if not textFrame or not textFrame.SetText then
		HideBlock()
		Note("Could not find the quest text to attach reputation to.")
		return
	end

	local text = ReadText(textFrame)
	if not text then
		if DrawBlock(textFrame, rewards) then
			Note("Drew reputation under " .. FrameName(textFrame) .. ".")
		else
			Note("Found " .. FrameName(textFrame) .. ", but its quest text could not be read.")
		end
		return
	end

	local suffix = RepSuffix(rewards)
	local newText = StripSuffix(text) .. suffix
	if newText ~= text then
		local before = Numeric(textFrame.GetStringHeight, textFrame)
		local ok = pcall(textFrame.SetText, textFrame, newText)
		if not ok then
			if DrawBlock(textFrame, rewards) then
				Note("Drew reputation under " .. FrameName(textFrame) .. ".")
			else
				Note("Could not write reputation onto " .. FrameName(textFrame) .. ".")
			end
			return
		end
		local after = Numeric(textFrame.GetStringHeight, textFrame)
		if textFrame.SetJustifyV then
			pcall(textFrame.SetJustifyV, textFrame, "TOP")
		end
		local target
		if type(after) == "number" and after > 1 then
			target = after + 32
		elseif type(before) == "number" and before > 0 then
			target = before + ((#rewards + 3) * 16) + 32
		end
		if target and textFrame.SetHeight then
			pcall(textFrame.SetHeight, textFrame, target)
		end
	end

	EnsureRoom(textFrame)

	HideBlock()
	Note("Added reputation to the bottom of " .. FrameName(textFrame) .. ".")
end

local showPending = false
local pendingRewards
local function ShowSoon(rewards)
	pendingRewards = rewards
	if showPending or not (C_Timer and C_Timer.After) then
		local ok, err = pcall(ShowReputation, rewards)
		if not ok then
			Note("Could not add reputation to the quest text: " .. tostring(err))
		end
		return
	end
	showPending = true
	C_Timer.After(0, function()
		showPending = false
		if not pendingRewards then return end
		local ok, err = pcall(ShowReputation, pendingRewards)
		if not ok then
			Note("Could not add reputation to the quest text: " .. tostring(err))
		end
	end)
end

local function OnQuestLogItemsUpdate(questState)
	if questState ~= "QuestLog" then
		ReleaseStretchedText(true)
		return
	end
	local rewards = CollectRepRewards()
	Announce(rewards)
	ShowSoon(rewards)
end

local function OnQuestInfoDisplay(template)
	if not template or not template.questLog then
		ReleaseStretchedText(true)
		if C_Timer and C_Timer.After then
			C_Timer.After(0, function()
				if GiverIsOpen() then
					ReleaseStretchedText(true)
				end
			end)
		end
		return
	end
	local rewards = CollectRepRewards()
	if not rewards or #rewards == 0 then
		ReleaseStretchedText()
		return
	end
	Announce(rewards)
	ShowSoon(rewards)
end

function RepRewards:RefreshQuestLogReputation()
	if _G.QuestLogFrame and _G.QuestLogFrame.IsShown and _G.QuestLogFrame:IsShown()
		and type(_G.QuestFrameItems_Update) == "function" then
		_G.QuestFrameItems_Update("QuestLog")
		return
	end
	ShowReputation(CollectRepRewards())
end

local installed = false
local function Install()
	if installed or type(hooksecurefunc) ~= "function" then return end
	local hooked = false
	if type(QuestFrameItems_Update) == "function" then
		hooksecurefunc("QuestFrameItems_Update", OnQuestLogItemsUpdate)
		hooked = true
	end
	if type(QuestLog_Update) == "function" then
		hooksecurefunc("QuestLog_Update", function()
			local rewards = CollectRepRewards()
			Announce(rewards)
			ShowSoon(rewards)
		end)
		hooked = true
	end
	if type(QuestInfo_Display) == "function" then
		hooksecurefunc("QuestInfo_Display", OnQuestInfoDisplay)
		hooked = true
	end
	installed = hooked
end

local giverWatcher = CreateFrame("Frame")
giverWatcher:RegisterEvent("QUEST_DETAIL")
giverWatcher:RegisterEvent("QUEST_PROGRESS")
giverWatcher:RegisterEvent("QUEST_COMPLETE")
giverWatcher:RegisterEvent("QUEST_GREETING")
giverWatcher:RegisterEvent("GOSSIP_SHOW")
giverWatcher:SetScript("OnEvent", function()
	ReleaseStretchedText(true)
	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			ReleaseStretchedText(true)
		end)
	end
end)

Install()

local waiter = CreateFrame("Frame")
waiter:RegisterEvent("ADDON_LOADED")
waiter:RegisterEvent("PLAYER_LOGIN")
waiter:SetScript("OnEvent", function()
	Install()
	if installed then
		waiter:UnregisterAllEvents()
		waiter:SetScript("OnEvent", nil)
	end
end)
