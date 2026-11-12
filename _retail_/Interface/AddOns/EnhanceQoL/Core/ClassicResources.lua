local _, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local M = { defaults = { lowAmmo = false, hunterOnly = true, threshold = 200, durability = 20, itemID = 0, talents = false } }
addon.ClassicResources = M
M.frames, M.preview = {}, {}
M.reminders = {
	ammo = { id = "lowAmmoReminder", flag = "lowAmmo", title = "lowAmmoReminder", y = 160 },
	talents = { id = "unspentTalentReminder", flag = "talents", title = "unspentTalentReminder", y = 220 },
}
M.styleDefaults = { fontFace = "__EQOL_GLOBAL_FONT__", fontStyle = "__EQOL_GLOBAL_FONT_STYLE__", fontSize = 24, width = 440, height = 100, scale = 1, alignment = "CENTER", strata = "HIGH", color = { r = 1, g = 0.75, b = 0.2, a = 1 } }
function M.Copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = M.Copy(child) end
	return result
end

function M.Options()
	if not addon.db then return M.defaults end
	if addon.functions and addon.functions.CleanupClassicResourceProfile then addon.functions.CleanupClassicResourceProfile(addon.db) end
	addon.db.classicResources = addon.db.classicResources or {}
	local db = addon.db.classicResources
	for key, value in pairs(M.defaults) do if db[key] == nil then db[key] = value end end
	return db
end

function M.IsPublic(value) return not (issecretvalue and issecretvalue(value)) end

function M.Read()
	local result = {}
	local rangedSlot = _G.INVSLOT_RANGED or 18
	local rangedID = GetInventoryItemID("player", rangedSlot)
	if M.IsPublic(rangedID) and rangedID then
		local _, _, _, equipLoc, icon, _, subclass = C_Item.GetItemInfoInstant(rangedID)
		result.weaponID, result.weaponIcon = rangedID, icon
		local current, maximum = GetInventoryItemDurability(rangedSlot)
		if M.IsPublic(current) and M.IsPublic(maximum) and current and maximum and maximum > 0 then
			result.durability = math.floor(current / maximum * 100 + 0.5)
		end
		if equipLoc == "INVTYPE_THROWN" then
			result.itemID, result.icon = rangedID, icon
			-- Reusable thrown weapons consume durability; stackable ones consume items.
			if not result.durability then result.count = GetInventoryItemCount("player", rangedSlot) end
		elseif subclass == 2 or subclass == 3 or subclass == 18 then
			result.usesAmmo = true
			local ammoSlot = GetInventorySlotInfo("AmmoSlot")
			local itemID = ammoSlot and GetInventoryItemID("player", ammoSlot)
			result.count = 0
			if M.IsPublic(itemID) and itemID then
				local _, _, _, _, ammoIcon, ammoClass, ammoSubclass = C_Item.GetItemInfoInstant(itemID)
				local expectedSubclass = subclass == 3 and 3 or 2
				if ammoClass == 6 and ammoSubclass == expectedSubclass then
					result.itemID, result.icon = itemID, ammoIcon
					result.count = C_Item.GetItemCount(itemID, false, false, false)
				end
			end
		end
	end
	if not M.IsPublic(result.count) then result.count = nil end
	local customID = tonumber(M.Options().itemID) or 0
	if customID > 0 then
		result.customID = customID
		result.customCount = C_Item.GetItemCount(customID, false, false, false)
		if not M.IsPublic(result.customCount) then result.customCount = nil end
	end
	return result
end

function M.HasTalentPoints()
	if addon.variables.isTBC then
		if _G.GetUnspentTalentPoints then return (_G.GetUnspentTalentPoints() or 0) > 0 end
		return false
	end
	return C_ClassTalents and C_ClassTalents.HasUnspentTalentPoints and C_ClassTalents.HasUnspentTalentPoints() == true
end

function M.Warning(data)
	local opts = M.Options()
	if not opts.lowAmmo or (opts.hunterOnly and select(2, UnitClass("player")) ~= "HUNTER") then return end
	local lines = {}
	if data.count and data.count <= opts.threshold then lines[#lines + 1] = L["ammoLow"]:format(data.count) end
	if data.durability and data.durability <= opts.durability then lines[#lines + 1] = L["ammoDurabilityLow"]:format(data.durability) end
	if data.customCount and data.customCount <= opts.threshold then
		local name = C_Item.GetItemNameByID(data.customID) or tostring(data.customID)
		lines[#lines + 1] = name .. ": " .. data.customCount
	end
	if #lines > 0 then return table.concat(lines, "\n") end
end

function M.Style(kind)
	local db = M.Options()
	local key = kind .. "Style"
	db[key] = db[key] or {}
	for field, value in pairs(M.styleDefaults) do if db[key][field] == nil then db[key][field] = M.Copy(value) end end
	return db[key]
end

function M.ApplyStyle(kind)
	local frame = M.frames[kind]
	if not frame then return end
	local style = M.Style(kind)
	frame:SetSize(style.width * style.scale, style.height * style.scale)
	frame.content:SetSize(style.width, style.height)
	frame.content:SetScale(style.scale)
	frame:SetFrameStrata(style.strata)
	addon.functions.ApplyFontString(frame.text, style.fontFace, style.fontSize, style.fontStyle)
	frame.text:SetTextColor(style.color.r, style.color.g, style.color.b, style.color.a)
	frame.text:SetJustifyH(style.alignment)
end

function M.FontOptions()
	local options = { { value = M.styleDefaults.fontFace, label = addon.functions.GetGlobalFontConfigLabel() } }
	local hash = addon.functions.GetLSMMediaHash("font") or {}
	for _, name in ipairs(addon.functions.GetLSMMediaNames("font") or {}) do
		if hash[name] then options[#options + 1] = { value = hash[name], label = name } end
	end
	return options
end

function M.BuildSettings(kind)
	local editMode = addon.EditMode
	local types = editMode.lib.SettingType
	local spec = M.reminders[kind]
	local list = {}
	local function enabled() return M.Options()[spec.flag] == true end
	local function add(field, name, settingKind, options)
		local data = {
			name = name, kind = settingKind, field = field, navigationField = field,
			default = M.Copy(M.styleDefaults[field]), navigationDefaultVerified = true,
			get = function() return M.Style(kind)[field] end,
			set = function(_, value) M.Style(kind)[field] = M.Copy(value); M.ApplyStyle(kind) end,
			isEnabled = enabled,
		}
		for key, value in pairs(options or {}) do data[key] = value end
		list[#list + 1] = data
		return data
	end
	local function dropdown(field, label, options)
		return add(field, label, types.Dropdown, { generator = function(_, root)
			local entries = type(options) == "function" and options() or options
			for _, option in ipairs(entries) do
				root:CreateRadio(option.label, function() return M.Style(kind)[field] == option.value end, function()
					M.Style(kind)[field] = option.value
					M.ApplyStyle(kind)
				end)
			end
		end })
	end
	if kind == "ammo" then
		for _, row in ipairs({
			{ "hunterOnly", "ammoHunterOnly", types.Checkbox },
			{ "threshold", "ammoThreshold", types.Slider, 0, 5000 },
			{ "durability", "ammoDurabilityThreshold", types.Slider, 0, 100 },
			{ "itemID", "ammoCustomItem", types.Input },
		}) do
			local key = row[1]
			add(key, L[row[2]], row[3], {
				default = M.defaults[key], minValue = row[4], maxValue = row[5], valueStep = 1, allowInput = true,
				get = function() return key == "itemID" and tostring(M.Options()[key]) or M.Options()[key] end,
				set = function(_, value)
					if key == "hunterOnly" then value = value == true
					else
						value = tonumber(value)
						local maximum = key == "itemID" and 2147483647 or row[5]
						if not value or value < 0 or value > maximum or value ~= math.floor(value) then return end
					end
					M.Options()[key] = value
					if key == "itemID" and addon.DataHub and addon.DataHub.RequestUpdate then addon.DataHub:RequestUpdate("ammo") end
					M.RequestUpdate()
				end,
			})
		end
	end
	for _, field in ipairs({ "x", "y" }) do
		local fallback = field == "y" and spec.y or 0
		list[#list + 1] = { name = L[field == "x" and "Offset X" or "Offset Y"], kind = types.Slider, field = field,
			minValue = -4000, maxValue = 4000, valueStep = 1, allowInput = true, default = fallback, navigationDefaultVerified = true,
			get = function() return editMode:GetValue(spec.id, field) or fallback end,
			set = function(_, value) editMode:SetValue(spec.id, field, value) end, isEnabled = enabled,
			navigationReset = field == "x" and function()
				-- Dragging can store TOP/BOTTOM anchors; factory offsets are relative to CENTER.
				editMode:SetValue(spec.id, "point", "CENTER", nil, true)
				editMode:SetValue(spec.id, "relativePoint", "CENTER", nil, true)
				editMode:SetValue(spec.id, "x", 0, nil, true)
				editMode:SetValue(spec.id, "y", spec.y)
			end or nil,
		}
	end
	for _, row in ipairs({ { "width", "Width", 100, 1500, 1 }, { "height", "Height", 30, 500, 1 }, { "scale", "Scale", 0.5, 3, 0.05 }, { "fontSize", false, 8, 96, 1 } }) do
		add(row[1], row[2] and L[row[2]] or FONT_SIZE, types.Slider, {
			minValue = row[3], maxValue = row[4], valueStep = row[5], allowInput = true,
			formatter = row[1] == "scale" and function(value) return string.format("%.2f", value) end or nil,
		})
	end
	dropdown("fontFace", L["Font"], M.FontOptions)
	dropdown("fontStyle", L["Font outline"], function() return addon.functions.GetFontStyleOptionList(true) end)
	dropdown("alignment", L["classicReminderAlignment"], { { value = "LEFT", label = L["Left"] }, { value = "CENTER", label = L["Center"] }, { value = "RIGHT", label = L["Right"] } })
	add("color", L["Text color"], types.Color, { hasOpacity = true })
	dropdown("strata", L["Strata"], { { value = "LOW", label = "LOW" }, { value = "MEDIUM", label = "MEDIUM" }, { value = "HIGH", label = "HIGH" }, { value = "DIALOG", label = "DIALOG" } })
	return list
end

function M.EnsureFrame(kind)
	if M.frames[kind] then return end
	local spec = M.reminders[kind]
	local frame = CreateFrame("Frame", "EQOL" .. spec.id, UIParent)
	frame:SetClampedToScreen(true)
	M.frames[kind] = frame
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, spec.y)
	frame:EnableMouse(false)
	frame.content = CreateFrame("Frame", nil, frame)
	frame.content:SetPoint("CENTER", frame, "CENTER", 0, 0)
	frame.text = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.text:SetAllPoints()
	frame:Hide()
	M.ApplyStyle(kind)
	local editMode = addon.EditMode
	if editMode and editMode.RegisterFrame then
		editMode:RegisterFrame(spec.id, {
			frame = frame, title = L[spec.title], managerCategory = "trackers",
			layoutDefaults = { point = "CENTER", relativePoint = "CENTER", x = 0, y = spec.y },
			isEnabled = function() return M.Options()[spec.flag] == true end,
			manageVisibilityOutsideEditMode = false, showOutsideEditMode = false,
			settings = M.BuildSettings(kind), settingsFactoryDefaults = M.styleDefaults,
			onApply = function() M.ApplyStyle(kind) end,
			onEnter = function() M.preview[kind] = true; M.Refresh() end,
			onExit = function() M.preview[kind] = false; M.Refresh() end,
		})
	end
end

function M.Refresh()
	if not addon.db then return end
	local opts = M.Options()
	local allowed = not UnitIsDeadOrGhost("player") and not InCombatLockdown()
	for _, kind in ipairs({ "ammo", "talents" }) do
		local spec = M.reminders[kind]
		local enabled = opts[spec.flag] == true
		if enabled then M.EnsureFrame(kind) end
		local frame = M.frames[kind]
		if frame then
			local message
			if enabled then
				if M.preview[kind] then
					message = kind == "ammo" and L["ammoLow"]:format(120) or L["unspentTalentReminder"]
				elseif allowed then
					if kind == "ammo" then message = M.Warning(M.Read())
					elseif M.HasTalentPoints() then message = L["unspentTalentReminder"] end
				end
			end
			M.ApplyStyle(kind)
			frame.text:SetText(message or "")
			frame:SetShown(message ~= nil)
		end
	end
end

function M.RequestUpdate()
	if M.queued then return end
	M.queued = true
	C_Timer.After(0, function() M.queued = false; M.Refresh() end)
end

M.events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "UPDATE_INVENTORY_DURABILITY", "PLAYER_LEVEL_UP", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "GET_ITEM_INFO_RECEIVED" }) do M.events:RegisterEvent(event) end
if addon.variables.isTBC then
	M.events:RegisterEvent("CHARACTER_POINTS_CHANGED")
	M.events:RegisterEvent("PLAYER_TALENT_UPDATE")
else
	M.events:RegisterEvent("TRAIT_CONFIG_UPDATED")
	M.events:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
end
M.events:SetScript("OnEvent", function() M.RequestUpdate() end)
