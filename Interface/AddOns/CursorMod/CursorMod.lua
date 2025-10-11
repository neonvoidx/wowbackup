local config, UIParent, GetCursorPosition = CursorModConfig, UIParent, GetCursorPosition
config.cursorFrame = CreateFrame("FRAME", nil, UIParent)
local cursorFrame = config.cursorFrame
cursorFrame:SetFrameStrata("TOOLTIP")
config.cursor = cursorFrame:CreateTexture(nil, "OVERLAY")
config.cursor:SetPoint("CENTER")
cursorFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT")
cursorFrame:Hide()
cursorFrame[1], cursorFrame[2] = true, true


local function show(n)
	cursorFrame[n] = false
	if cursorFrame[3] then return end
	local x, y = GetCursorPosition()
	local scale = cursorFrame.scale
	cursorFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
	cursorFrame:Show()
end


local function hide(n)
	cursorFrame[n] = true
	if cursorFrame[1] and cursorFrame[2] or cursorFrame[3] then cursorFrame:Hide() end
end


function cursorFrame:PLAYER_STARTED_LOOKING() show(1) end
function cursorFrame:PLAYER_STARTED_TURNING() show(2) end
function cursorFrame:PLAYER_STOPPED_LOOKING() hide(1) end
function cursorFrame:PLAYER_STOPPED_TURNING() hide(2) end
function cursorFrame:PLAYER_REGEN_DISABLED() show(3) end
function cursorFrame:PLAYER_REGEN_ENABLED() hide(3) end
cursorFrame:SetScript("OnEvent", function(self, event) self[event](self) end)