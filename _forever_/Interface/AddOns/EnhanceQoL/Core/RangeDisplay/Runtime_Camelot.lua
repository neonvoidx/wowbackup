local _, addon = ...
local R = addon.RangeDisplay
R.id = "rangeDisplay"
R.flavor = "forever"
R.checks = R.flavors.forever.checks
R.defaults = {
	point = "CENTER", relativePoint = "CENTER", x = 0, y = -80,
	width = 180, height = 40, fontSize = 20,
	font = "__EQOL_GLOBAL_FONT__", fontStyle = "__EQOL_GLOBAL_FONT_STYLE__",
	color = { r = 1, g = 1, b = 1, a = 1 },
	backgroundTexture = "", backgroundUseCustomTexture = false, backgroundCustomTexture = "", borderTexture = "",
	backgroundWidthOffset = 0, backgroundHeightOffset = 0,
	borderWidthOffset = 0, borderHeightOffset = 0,
	background = false, backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
	border = false, borderColor = { r = 1, g = 1, b = 1, a = 1 }, borderSize = 1,
	alpha = 1, strata = "MEDIUM", onlyCombat = false,
}
local function public(v) return not (issecretvalue and issecretvalue(v)) end

local positionFields = { point = true, relativePoint = true, x = true, y = true }

function R:Value(key)
	local value
	if positionFields[key] then
		value = addon.EditMode:GetValue(self.id, key)
	else
		value = addon.db and addon.db.rangeDisplayConfig and addon.db.rangeDisplayConfig[key]
	end
	if value == nil then return self.defaults[key] end
	return value
end

function R:SetSetting(key, value)
	if type(value) == "table" then value = CopyTable(value) end
	if not positionFields[key] then
		addon.db.rangeDisplayConfig = addon.db.rangeDisplayConfig or {}
		addon.db.rangeDisplayConfig[key] = value
	end
	addon.EditMode:SetValue(self.id, key, value)
end

function R:StopTimer()
	if self.ticker then self.ticker:Cancel(); self.ticker = nil end
end

function R:Measure()
	local lower, upper, known = 0, nil, false
	for _, item in ipairs(self.checks) do
		if C_Item.IsItemDataCachedByID(item.id) then
			local result = C_Item.IsItemInRange(item.id, "target")
			if public(result) and type(result) == "boolean" then
				known = true
				if result then upper = upper and math.min(upper, item.yards) or item.yards
				else lower = math.max(lower, item.yards) end
			end
		end
	end
	local melee
	lower, upper, melee = self.RefineWithSpells(lower, upper)
	if (upper and lower >= upper) or (not known and not upper and lower == 0 and not melee) then return "?" end
	if melee then return _G.MELEE end
	if upper then return string.format("%g–%g", lower, upper) end
	return string.format(">%g", lower)
end

function R:HasTarget()
	if not self.active then return false end
	if self:Value("onlyCombat") and not UnitAffectingCombat("player") then return false end
	local exists, attack, dead = UnitExists("target"), UnitCanAttack("player", "target"), UnitIsDeadOrGhost("target")
	return public(exists) and exists and public(attack) and attack and public(dead) and not dead
end

function R:Tick()
	if self.preview then return end
	if not self:HasTarget() then self:StopTimer(); self.frame:Hide(); return end
	local visible = UnitIsVisible("target")
	if not public(visible) or not visible then self.frame:Hide(); return end
	local text = self:Measure()
	if text ~= self.lastText then self.frame.text:SetText(text); self.lastText = text end
	self.frame:Show()
end

function R:RefreshTarget()
	if not self.active then return end
	if self.preview then
		self:StopTimer()
		self.frame.text:SetText("10–20")
		self.lastText = nil
		self.frame:Show()
		return
	end
	self:Tick()
	if self:HasTarget() and not self.ticker then self.ticker = C_Timer.NewTicker(0.1, function() R:Tick() end) end
end

function R:MediaTexture(kind, key)
	local media = LibStub("LibSharedMedia-3.0", true)
	return (key ~= "" and media and media:Fetch(kind, key, true)) or "Interface\\Buttons\\WHITE8x8"
end

function R:ApplyBackgroundTexture()
	local texture = self.frame.background
	local custom = self:Value("backgroundUseCustomTexture") and self:Value("backgroundCustomTexture") or ""
	custom = custom:match("^%s*(.-)%s*$")
	if custom ~= "" and not tonumber(custom) and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(custom) then
		texture:SetAtlas(custom, false)
	else
		texture:SetTexture(custom ~= "" and (tonumber(custom) or custom) or self:MediaTexture("statusbar", self:Value("backgroundTexture")))
		texture:SetTexCoord(0, 1, 0, 1)
	end
end

function R:ApplyStyle()
	if not self.active or not self.frame then return end
	local f = self.frame
	f:SetSize(self:Value("width"), self:Value("height"))
	f:SetAlpha(self:Value("alpha"))
	f:SetFrameStrata(self:Value("strata"))
	addon.functions.ApplyFontString(f.text, self:Value("font"), self:Value("fontSize"), self:Value("fontStyle"), STANDARD_TEXT_FONT, "OUTLINE")
	local c = self:Value("color")
	f.text:SetTextColor(c.r, c.g, c.b, c.a)
	local bg, edge = self:Value("background"), self:Value("border")
	f.background:SetSize(math.max(1, self:Value("width") + self:Value("backgroundWidthOffset")), math.max(1, self:Value("height") + self:Value("backgroundHeightOffset")))
	c = self:Value("backgroundColor")
	self:ApplyBackgroundTexture()
	f.background:SetVertexColor(c.r, c.g, c.b, c.a)
	f.background:SetShown(bg)
	local borderSize = self:Value("borderSize")
	f.border:SetSize(math.max(2 * borderSize, self:Value("width") + self:Value("borderWidthOffset")), math.max(2 * borderSize, self:Value("height") + self:Value("borderHeightOffset")))
	-- Fixed-size, unprotected decoration; no secret-derived geometry.
	if edge then
		f.border:SetBackdrop({ edgeFile = self:MediaTexture("border", self:Value("borderTexture")), edgeSize = borderSize })
		c = self:Value("borderColor"); f.border:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
	end
	f.border:SetShown(edge)
end

function R:EnsureFrame()
	if self.frame then return end
	self.frame = CreateFrame("Frame", "EQOLRangeDisplay", UIParent)
	self.frame:SetClampedToScreen(true)
	self.frame:EnableMouse(false)
	self.frame:Hide()
	self.frame.background = self.frame:CreateTexture(nil, "BACKGROUND")
	self.frame.background:SetPoint("CENTER")
	self.frame.border = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
	self.frame.border:SetPoint("CENTER")
	self.frame.border:EnableMouse(false)
	self.frame.text = self.frame:CreateFontString(nil, "OVERLAY")
	self.frame.text:SetPoint("CENTER")
	self.frame.text:SetJustifyH("CENTER")
end

function R.RefreshSpells()
	R.RebuildSpells()
	R:RefreshTarget()
end

function R:Refresh()
	local enabled = addon.db and addon.db.rangeDisplayEnabled == true
	if not enabled then
		self.active, self.preview = false, false
		self.SetSpellCacheConsumer("display", nil)
		self:StopTimer()
		if self.events then self.events:UnregisterAllEvents(); self.events:SetScript("OnEvent", nil) end
		if self.registered then addon.EditMode:UnregisterFrame(self.id); self.registered = nil end
		if self.frame then self.frame:Hide() end
		return
	end
	local starting = not self.active
	self.active = true
	self:EnsureFrame()
	if not self.registered then self:RegisterEditor() end
	self:ApplyStyle()
	self.playerClass = select(2, UnitClass("player"))
	self.SetSpellCacheConsumer("display", R.RefreshSpells)
	self.RebuildSpells()
	if starting then
		for _, item in ipairs(self.checks) do C_Item.RequestLoadItemDataByID(item.id) end
		self.events = self.events or CreateFrame("Frame")
		self.events:SetScript("OnEvent", function(_, event, unit)
			if not R.active then return end
			if (event == "UNIT_FACTION" or event == "UNIT_FLAGS") and unit ~= "target" then return end
			R:RefreshTarget()
		end)
		for _, event in ipairs({ "PLAYER_TARGET_CHANGED", "UNIT_FACTION", "UNIT_FLAGS", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
			self.events:RegisterEvent(event)
		end
	end
	self:RefreshTarget()
end

function R:Initialize()
	addon.functions.InitDBValue("rangeDisplayEnabled", false)
	addon.functions.InitDBValue("rangeDisplayConfig", {})
	self:Refresh()
end
