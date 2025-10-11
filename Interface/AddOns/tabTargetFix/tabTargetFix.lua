local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EventFrame:SetScript("OnEvent", function(self,event,...) 
	if select(2, IsInInstance()) == "arena" then
		SetBinding("TAB","TARGETNEARESTENEMYPLAYER")
	else
		SetBinding("TAB","TARGETNEARESTENEMY")
	end
end)

