local _, addon = ...

local Defaults = {}
addon.EditModeNavigationDefaults = Defaults

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end

-- Callers provide factory values, never the active profile or layout snapshot.
function Defaults.Set(data, value)
	data.default = copy(value)
	data.navigationDefaultVerified = true
	if value == nil and data.set then
		data.navigationReset = function()
			local lib = addon.EditModeLib
			data.set(nil, nil, lib:GetActiveLayoutIndex())
		end
	elseif type(value) == "table" and data.setSelected and not data.set then
		data.navigationReset = function()
			local lib = addon.EditModeLib
			local options = type(data.values) == "function" and data.values() or data.values or {}
			local selection = data.default
			for _, option in ipairs(options) do
				local key = option.value
				if key ~= nil then data.setSelected(nil, key, selection[key] == true, lib:GetActiveLayoutIndex()) end
			end
		end
	end
	return data
end

function Defaults.Prepare(settings, values, verifiedExisting)
	for _, data in ipairs(settings or {}) do
		local field = data.navigationField or data.field
		if field and values and values[field] ~= nil then Defaults.Set(data, values[field])
		elseif verifiedExisting and (data.default ~= nil or data.colorDefault ~= nil) then data.navigationDefaultVerified = true end
	end
	return settings
end

function Defaults.Link(settings, links)
	local fields = {}
	for _, data in ipairs(settings or {}) do
		local field = data.navigationField or data.field
		if field then fields[field] = data end
	end
	for field, targetField in pairs(links or {}) do
		local data, target = fields[field], fields[targetField]
		if data and target and data.isShown then
			data.navigationHint = function()
				if target.isShown and not target.isShown() and target.navigationHint then return target.navigationHint() end
				return target.name, nil, target.parentId
			end
		end
	end
	return settings
end
