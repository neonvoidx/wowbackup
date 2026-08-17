local addonName, addon = ...

if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
  -- Retail only
  return
end

local AddonFrame = CreateFrame("Frame")
local LEADER_ICON = "Interface\\GroupFrame\\UI-Group-LeaderIcon"

local leaderIcons = {}
local markerIcons = {}

local function UpdateIcon(icon, frame, settings)
	if not icon or not frame then
		return
	end

	local anchor = settings.anchor or "CENTER"
	local size = settings.size or 16
	local offsetX = settings.offsetX or 0
	local offsetY = settings.offsetY or 0

	icon:SetSize(size, size)
	icon:ClearAllPoints()
	icon:SetPoint("CENTER", frame, anchor, offsetX, offsetY)
end

local function EnsureIcon(frame, iconTable, texture)
	if not frame then
		return nil
	end

	if iconTable[frame] then
		return iconTable[frame]
	end

	local icon = frame:CreateTexture(nil, "OVERLAY")
	if texture then
		icon:SetTexture(texture)
	end
	icon:Hide()

	iconTable[frame] = icon
	return icon
end

local function ClearAllIcons()
  for _, icon in pairs(leaderIcons) do
    icon:Hide()
  end
  for _, icon in pairs(markerIcons) do
    icon:Hide()
  end
end

local function CollectFrames()
    local frames = {}

    -- Compact Raid Groups
    for groupIndex = 1, 8 do
        for memberIndex = 1, 5 do
            local frame = _G["CompactRaidGroup" .. groupIndex .. "Member" .. memberIndex]
            if frame then
                frames[#frames + 1] = frame
            end
        end
    end

    -- Compact Raid Frames
    for i = 1, 40 do
        local frame = _G["CompactRaidFrame" .. i]
        if frame then
            frames[#frames + 1] = frame
        end
    end

    -- Compact Party Frames
    for i = 1, 5 do
        local frame = _G["CompactPartyFrameMember" .. i]
        if frame then
            frames[#frames + 1] = frame
        end
    end

    return frames
end

local function UpdateAll()
  ClearAllIcons()

  -- if not IsInGroup() then
  --   return
  -- end

  local frames = CollectFrames()

  for _, frame in ipairs(frames) do
    local unit = frame.unit
    if unit and UnitExists(unit) then
      -- Leader icon
      if RaidLeaderMarkerDB.leaderIcon.enabled and UnitIsGroupLeader(unit) then
        local leaderIcon = EnsureIcon(frame, leaderIcons, LEADER_ICON)
        if leaderIcon then
          leaderIcon:Show()
          UpdateIcon(leaderIcon, frame, RaidLeaderMarkerDB.leaderIcon)
        end
      end

      -- Target marker icon
      if RaidLeaderMarkerDB.targetMarker.enabled then
        local markerIcon = EnsureIcon(frame, markerIcons)
				if markerIcon then
					local markerIndex = GetRaidTargetIndex(unit)
					if markerIndex then
						markerIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons");
						SetRaidTargetIconTexture(markerIcon, markerIndex);
						markerIcon:Show()
						UpdateIcon(markerIcon, frame, RaidLeaderMarkerDB.targetMarker)
					else
						markerIcon:Hide()
					end
				end
      end
    end
  end
end

addon.UpdateAll = UpdateAll

AddonFrame:RegisterEvent("ADDON_LOADED")
AddonFrame:RegisterEvent("PLAYER_LOGIN")
AddonFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
AddonFrame:RegisterEvent("PARTY_LEADER_CHANGED")
AddonFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
AddonFrame:RegisterEvent("RAID_TARGET_UPDATE")

AddonFrame:SetScript("OnEvent", function(self, event, ...)
  if event == "ADDON_LOADED" and ... == addonName then
    addon.InitializeDB()
    addon.InitializeSettings()
  end

  UpdateAll()
end)
