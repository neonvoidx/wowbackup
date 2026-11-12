local _, addon = ...
addon = _G.EnhanceQoL or addon
local UF = addon.Aura.UF
local Colors = {}
UF.GroupHealthColors = Colors
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

Colors.defaults = {
	usePercentColorCurve = false,
	percentColorCurveType = "COSINE",
	percentColorCurvePointCount = 2,
	percentColorCurvePoints = {
		{ percent = 0, color = { 0.9, 0, 0, 1 } },
		{ percent = 60, color = { 0.9, 0.9, 0, 1 } },
		{ percent = 80, color = { 0.6, 0.85, 0, 1 } },
		{ percent = 40, color = { 0.95, 0.6, 0, 1 } },
		{ percent = 20, color = { 0.95, 0.25, 0, 1 } },
	},
}

local function config(cfg, background)
	cfg.health = cfg.health or {}
	if not background then return cfg.health end
	cfg.health.backdrop = cfg.health.backdrop or {}
	return cfg.health.backdrop
end

function Colors.Invalidate(st)
	if st._groupHealthCurve then st._groupHealthCurve._healthPercentCurveDirty = true end
	if st._groupBackdropCurve then st._groupBackdropCurve._healthPercentCurveDirty = true end
end

local function tintPoint(st, r, g, b, a)
	if UF.GroupFramesHealerBuffs and UF.GroupFramesHealerBuffs.ApplyHealthTint then return UF.GroupFramesHealerBuffs.ApplyHealthTint(st, r, g, b, a) end
	return r, g, b, a
end

function Colors.ApplyHealth(st, unit, hc, r, g, b, a)
	if hc.usePercentColorCurve ~= true then return false end
	st._groupHealthCurve = st._groupHealthCurve or {}
	local cache = st._groupHealthCurve
	-- Blend public curve control points before evaluation, never the secret result.
	if cache.tintR ~= st._hbHealthTintR or cache.tintG ~= st._hbHealthTintG or cache.tintB ~= st._hbHealthTintB or cache.tintA ~= st._hbHealthTintA then
		cache.tintR, cache.tintG, cache.tintB, cache.tintA = st._hbHealthTintR, st._hbHealthTintG, st._hbHealthTintB, st._hbHealthTintA
		cache._healthPercentCurveDirty = true
	end
	local cr, cg, cb, ca = UF.getHealthPercentCurveColor(cache, unit, hc, Colors.defaults, r, g, b, a, tintPoint, st)
	if not cr then return false end
	st.health:SetStatusBarColor(cr, cg, cb, ca)
	-- The static-color path must repaint when the gradient is disabled.
	st._lastHealthRenderR, st._lastHealthRenderG, st._lastHealthRenderB, st._lastHealthRenderA = nil, nil, nil, nil
	return true
end

function Colors.ApplyBackdrop(st, unit, hc, deadOrGhost, connected, defH)
	local bd = hc.backdrop or {}
	local defBd = defH and defH.backdrop or {}
	local tex = st.health and st.health._eqolBackdropTexture
	if bd.usePercentColorCurve ~= true or bd.enabled == false or not tex then return end
	local deadColorEnabled = bd.deadColorEnabled
	if deadColorEnabled == nil then deadColorEnabled = defBd.deadColorEnabled end
	if deadOrGhost and deadColorEnabled then
		local c = bd.deadColor or defBd.deadColor or { 0.35, 0.05, 0.05, 0.85 }
		tex:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
		return
	end
	local c = bd.color or defBd.color or { 0, 0, 0, 0.6 }
	if connected == false or not unit or (UnitExists and not UnitExists(unit)) then
		tex:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
		return
	end
	st._groupBackdropCurve = st._groupBackdropCurve or {}
	local r, g, b, a = UF.getHealthPercentCurveColor(st._groupBackdropCurve, unit, bd, Colors.defaults, c[1], c[2], c[3], c[4])
	if r then tex:SetVertexColor(r, g, b, a) end
end

local function descriptors(background)
	local prefix = background and "healthBackdropGradient" or "healthGradient"
	local list = {
		{ field = prefix .. "Enabled", key = "usePercentColorCurve", default = false, label = L["UFHealthPercentGradient"], kind = "Checkbox" },
		{ field = prefix .. "Type", key = "percentColorCurveType", default = "COSINE", label = L["UFHealthGradientCurveType"], kind = "Dropdown",
			values = { { "COSINE", L["UFCurveTypeCosine"] }, { "LINEAR", L["UFCurveTypeLinear"] }, { "STEP", L["UFCurveTypeStep"] } } },
		{ field = prefix .. "PointCount", key = "percentColorCurvePointCount", default = 2, label = L["UFHealthGradientPointCount"], kind = "Dropdown",
			values = { { 1, "1" }, { 2, "2" }, { 3, "3" }, { 4, "4" }, { 5, "5" } } },
	}
	for i, point in ipairs(Colors.defaults.percentColorCurvePoints) do
		list[#list + 1] = { field = prefix .. "Point" .. i .. "Percent", key = "percent", index = i, default = point.percent, label = string.format(L["UFHealthGradientPointPercent"], i), kind = "Slider" }
		list[#list + 1] = { field = prefix .. "Point" .. i .. "Color", key = "color", index = i, default = point.color, label = string.format(L["Point %d color"], i), kind = "Color" }
	end
	return list
end

Colors.barFields = descriptors(false)
Colors.backdropFields = descriptors(true)

local function read(c, d)
	if d.index then c = c.percentColorCurvePoints and c.percentColorCurvePoints[d.index] or {} end
	local value = c[d.key]
	if value == nil then value = d.default end
	return value
end

local function write(c, d, value)
	if d.index then
		c.percentColorCurvePoints = c.percentColorCurvePoints or {}
		c.percentColorCurvePoints[d.index] = c.percentColorCurvePoints[d.index] or CopyTable(Colors.defaults.percentColorCurvePoints[d.index])
		c = c.percentColorCurvePoints[d.index]
	end
	c[d.key] = type(value) == "table" and CopyTable(value) or value
end

function Colors.AddLayoutDefaults(values, cfg)
	for _, background in ipairs({ false, true }) do
		local c = config(cfg, background)
		for _, d in ipairs(background and Colors.backdropFields or Colors.barFields) do
			local value = read(c, d)
			values[d.field] = type(value) == "table" and CopyTable(value) or value
		end
	end
	return values
end

function Colors.ApplyLayout(cfg, values)
	for _, background in ipairs({ false, true }) do
		for _, d in ipairs(background and Colors.backdropFields or Colors.barFields) do
			if values[d.field] ~= nil then write(config(cfg, background), d, values[d.field]) end
		end
	end
end

function Colors.AppendSettings(settings, kind, editModeId, getCfg)
	local editMode = addon.EditMode
	local types = editMode.lib.SettingType
	for _, background in ipairs({ false, true }) do
		local additions = {}
		for _, d in ipairs(background and Colors.backdropFields or Colors.barFields) do
			local function current() return config(getCfg(kind), background) end
			local function get() return read(current(), d) end
			local function set(_, value)
				if d.kind == "Color" then value = { value.r or value[1], value.g or value[2], value.b or value[3], value.a or value[4] or 1 } end
				write(current(), d, value)
				editMode:SetValue(editModeId, d.field, value, nil, true)
				UF.GroupFrames:ApplyHeaderAttributes(kind)
			end
			local data = {
				name = d.label, field = d.field, parentId = "health", kind = types[d.kind], default = d.default,
				get = get, set = set,
				isEnabled = function()
					local c = current()
					return (not background or c.enabled ~= false) and (d.kind == "Checkbox" or c.usePercentColorCurve == true)
				end,
			}
			if d.index then
				data.isShown = function() return d.index <= (tonumber(current().percentColorCurvePointCount) or 2) end
				data.navigationHint = function() return L["UFHealthGradientPointCount"], nil, background and "healthBackdrop" or "healthColors" end
			end
			if d.kind == "Color" then
				data.hasOpacity = true
				data.get = function() local c = get(); return { r = c[1], g = c[2], b = c[3], a = c[4] or 1 } end
			elseif d.kind == "Slider" then
				data.minValue, data.maxValue, data.valueStep = 0, 99, 1
				data.formatter = function(value) return tostring(value) .. "%" end
			elseif d.kind == "Dropdown" then
				data.values = {}
				for _, option in ipairs(d.values) do data.values[#data.values + 1] = { value = option[1], label = option[2] } end
			end
			additions[#additions + 1] = data
		end
		local after = background and "healthBackdropColor" or "healthColor"
		for i, setting in ipairs(settings) do
			if setting.field == after then
				for j = #additions, 1, -1 do table.insert(settings, i + 1, additions[j]) end
				break
			end
		end
	end
end
