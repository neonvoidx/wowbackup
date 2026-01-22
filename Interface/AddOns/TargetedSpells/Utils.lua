---@type string, TargetedSpells
local addonName, Private = ...

---@class TargetedSpellsUtils
Private.Utils = {}

function Private.Utils.CalculateCoordinate(index, dimension, gap, parentDimension, total, offset, grow)
	if grow == Private.Enum.Grow.Start then
		return (index - 1) * (dimension + gap) - parentDimension / 2 + offset
	elseif grow == Private.Enum.Grow.Center then
		return (index - 1) * (dimension + gap) - total / 2 + offset
	elseif grow == Private.Enum.Grow.End then
		return parentDimension / 2 - index * (dimension + gap) + offset
	end

	return 0
end

function Private.Utils.SortFrames(frames, sortOrder)
	local isAscending = sortOrder == Private.Enum.SortOrder.Ascending

	table.sort(frames, function(a, b)
		if isAscending then
			return a:GetStartTime() < b:GetStartTime()
		end

		return a:GetStartTime() > b:GetStartTime()
	end)
end

function Private.Utils.RollDice()
	return math.random(1, 6) == 6
end

function Private.Utils.FindThirdPartyGroupFrameForUnit(unit, kind)
	if Grid2 and Grid2LayoutFrame and Grid2LayoutHeader1 then
		for i = 1, 5 do
			local name = string.format("Grid2LayoutHeader1UnitButton%d", i)
			local maybeFrame = _G[name]

			if maybeFrame and maybeFrame.unit == unit then
				return maybeFrame
			end
		end

		return nil
	elseif DandersFrames and DandersFrames.Api and DandersFrames.Api.GetFrameForUnit then
		local frame = DandersFrames.Api.GetFrameForUnit(unit, kind)

		if frame then
			return frame
		end
	end

	return nil
end

function Private.Utils.ShowStaticPopup(args)
	args.id = addonName
	args.whileDead = true

	StaticPopupDialogs[addonName] = args

	StaticPopup_Hide(addonName)
	StaticPopup_Show(addonName)
end

do
	---@type table<string, Frame|nil>
	local editModeFrameByKind = {
		[Private.Enum.FrameKind.Self] = nil,
		[Private.Enum.FrameKind.Party] = nil,
	}

	function Private.Utils.RegisterEditModeFrame(frameKind, frame)
		editModeFrameByKind[frameKind] = frame
	end

	function Private.Utils.Import(string)
		local ok, result = pcall(function()
			return C_EncodingUtil.DeserializeCBOR(C_EncodingUtil.DecodeBase64(string))
		end, string)

		if not ok then
			if result ~= nil then
				print(result)
			end

			return false
		end

		-- just a type check
		if result == nil then
			return false
		end

		local hasAnyChange = false

		for kind, kindString in pairs(Private.Enum.FrameKind) do
			local tableRef = TargetedSpellsSaved.Settings[kind]

			if kindString == Private.Enum.FrameKind.Self then
				local frame = editModeFrameByKind[kindString]

				local point, x, y = result[kind].Position.point, result[kind].Position.x, result[kind].Position.y

				if
					frame ~= nil
					and (point ~= tableRef.Position.point or x ~= tableRef.Position.x or y ~= tableRef.Position.y)
				then
					frame:ClearAllPoints()
					frame:SetPoint(point, x, y)
					tableRef.Position.point = point
					tableRef.Position.x = x
					tableRef.Position.y = y
				end
			end

			local anyPrimaryLoadConditionIsDisabled = false

			local defaults = kindString == Private.Enum.FrameKind.Self and Private.Settings.GetSelfDefaultSettings()
				or Private.Settings.GetPartyDefaultSettings()
			local eventKeys = kindString == Private.Enum.FrameKind.Self and Private.Settings.Keys.Self
				or Private.Settings.Keys.Party

			for key, defaultValue in pairs(defaults) do
				local newValue = result[kind][key]
				local expectedType = type(defaultValue)

				if newValue and type(newValue) == expectedType then
					local eventKey = eventKeys[key]
					local hasChanges = false

					if expectedType == "table" then
						local enumToCompareAgainst = nil
						if key == "LoadConditionContentType" then
							enumToCompareAgainst = Private.Enum.ContentType
						elseif key == "LoadConditionRole" then
							enumToCompareAgainst = Private.Enum.Role
						end

						-- only other case is Position but that's taken care of above

						if enumToCompareAgainst then
							local newTable = {}
							local allDisabled = true

							for _, id in pairs(enumToCompareAgainst) do
								if newValue[id] == nil then
									newTable[id] = tableRef[key][id]
								else
									newTable[id] = newValue[id]

									if newValue[id] ~= tableRef[key][id] then
										hasChanges = true
									end

									if newValue[id] then
										allDisabled = false
									end
								end
							end

							if allDisabled then
								anyPrimaryLoadConditionIsDisabled = true
							end

							if hasChanges then
								tableRef[key] = newTable
								Private.EventRegistry:TriggerEvent(
									Private.Enum.Events.SETTING_CHANGED,
									eventKey,
									newTable
								)
							end
						end
					elseif newValue ~= tableRef[key] then
						tableRef[key] = newValue
						hasChanges = true

						if eventKey and hasChanges then
							Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, eventKey, newValue)
						end
					end

					if hasChanges then
						hasAnyChange = true
					end
				end
			end

			if anyPrimaryLoadConditionIsDisabled then
				tableRef.Enabled = false
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, eventKeys.Enabled, false)
			end
		end

		return hasAnyChange
	end

	function Private.Utils.Export()
		return C_EncodingUtil.EncodeBase64(C_EncodingUtil.SerializeCBOR(TargetedSpellsSaved.Settings))
	end
end

_G.TargetedSpellsAPI = {
	Import = Private.Utils.Import,
	Export = Private.Utils.Export,
}
