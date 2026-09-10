local frame
local initialised = false
local bgBlitzText
local soloShuffleText
local arena2v2Text
local arena3v3Text
local rbgText
local bracket = {
	SoloShuffle = 7,
	Blitz = 9,
	Arena2v2 = 1,
	Arena3v3 = 2,
	Rbg = 3,
}

local function GetWinLoss(index)
	local data = { GetPersonalRatedInfo(index) }

	if #data < 13 then
		return 0, 0, 0
	end

	local playedIndex = 4
	local winsIndex = 5

	-- for some reason shuffle uses different indexes
	if index == bracket.SoloShuffle then
		playedIndex = 12
		winsIndex = 13
	end

	local played = data[playedIndex] or 0
	local wins = data[winsIndex] or 0
	local losses = played - wins
	local winRate = played > 0 and (wins / played) * 100 or 0

	return wins, losses, winRate
end

local function Format(wins, losses, winRate)
	return string.format("%d - %d (%.1f%%)", wins, losses, winRate)
end

local function ConfigureFontString(fs, parent)
	fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	fs:SetTextColor(1, 1, 1, 1)
	fs:SetPoint("BOTTOMLEFT", parent, "CENTER", 20, 8)
end

local function Update()
	if bgBlitzText then
		local wins, losses, winRate = GetWinLoss(bracket.Blitz)
		bgBlitzText:SetText(Format(wins, losses, winRate))
	end

	if soloShuffleText then
		local wins, losses, winRate = GetWinLoss(bracket.SoloShuffle)
		soloShuffleText:SetText(Format(wins, losses, winRate))
	end

	if arena2v2Text then
		local wins, losses, winRate = GetWinLoss(bracket.Arena2v2)
		arena2v2Text:SetText(Format(wins, losses, winRate))
	end

	if arena3v3Text then
		local wins, losses, winRate = GetWinLoss(bracket.Arena3v3)
		arena3v3Text:SetText(Format(wins, losses, winRate))
	end

	if rbgText then
		local wins, losses, winRate = GetWinLoss(bracket.Rbg)
		rbgText:SetText(Format(wins, losses, winRate))
	end
end

local function Init()
	if not C_AddOns.IsAddOnLoaded("Blizzard_PVPUI") then
		return false
	end

	if not ConquestFrame then
		return false
	end

	local createdAny = false

	if ConquestFrame.RatedBGBlitz and not bgBlitzText then
		bgBlitzText = ConquestFrame.RatedBGBlitz:CreateFontString(nil, "OVERLAY")
		ConfigureFontString(bgBlitzText, ConquestFrame.RatedBGBlitz)
		createdAny = true
	end

	if ConquestFrame.RatedSoloShuffle and not soloShuffleText then
		soloShuffleText = ConquestFrame.RatedSoloShuffle:CreateFontString(nil, "OVERLAY")
		ConfigureFontString(soloShuffleText, ConquestFrame.RatedSoloShuffle)
		createdAny = true
	end

	if ConquestFrame.Arena2v2 and not arena2v2Text then
		arena2v2Text = ConquestFrame.Arena2v2:CreateFontString(nil, "OVERLAY")
		ConfigureFontString(arena2v2Text, ConquestFrame.Arena2v2)
		createdAny = true
	end

	if ConquestFrame.Arena3v3 and not arena3v3Text then
		arena3v3Text = ConquestFrame.Arena3v3:CreateFontString(nil, "OVERLAY")
		ConfigureFontString(arena3v3Text, ConquestFrame.Arena3v3)
		createdAny = true
	end

	if ConquestFrame.RatedBG and not rbgText then
		rbgText = ConquestFrame.RatedBG:CreateFontString(nil, "OVERLAY")
		ConfigureFontString(rbgText, ConquestFrame.RatedBG)
		createdAny = true
	end

	return createdAny
end

frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PVP_RATED_STATS_UPDATE")
frame:SetScript("OnEvent", function(_, event)
	if not initialised then
		initialised = Init()
	end

	if initialised then
		Update()
	end
end)
