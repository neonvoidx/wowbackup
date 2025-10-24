local GetTime = GetTime
local isRetail = sArenaMixin.isRetail
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture

if isRetail then
	sArenaMixin.dispelData = {
		[527] = { texture = GetSpellTexture(527), name = "Purify", classes = "Disc/Holy Priest", cooldown = 8, healer = true },
		[213634] = { texture = GetSpellTexture(213634), name = "Purify Disease", classes = "Shadow Priest", cooldown = 8, showAfterUse = true },
		[4987] = { texture = GetSpellTexture(4987), name = "Cleanse", classes = "Holy Paladin", cooldown = 8, healer = true },
		[213644] = { texture = GetSpellTexture(213644), name = "Cleanse Toxins", classes = "Prot/Ret Paladin", cooldown = 8, showAfterUse = true },
		[77130] = { texture = GetSpellTexture(77130), name = "Purify Spirit", classes = "Resto Shaman", cooldown = 8, healer = true },
		[51886] = { texture = GetSpellTexture(51886), name = "Cleanse Spirit", classes = "Enh/Ele Shaman", cooldown = 8, showAfterUse = true },
		[88423] = { texture = GetSpellTexture(88423), name = "Nature's Cure", classes = "Resto Druid", cooldown = 8, healer = true },
		[2782] = { texture = GetSpellTexture(2782), name = "Remove Corruption", classes = "Balance/Feral/Guardian Druid", cooldown = 8, showAfterUse = true },
		[475] = { texture = GetSpellTexture(475), name = "Remove Curse", classes = "Mage", cooldown = 8, showAfterUse = true },
		[218164] = { texture = GetSpellTexture(218164), name = "Detox", classes = "Monk", cooldown = 8, showAfterUse = true },
		[115450] = { texture = GetSpellTexture(115450), name = "Detox", classes = "Mistweaver Monk", cooldown = 8, healer = true },
		[360823] = { texture = GetSpellTexture(360823), name = "Naturalize", classes = "Evoker", cooldown = 8, healer = true },
		[374251] = { texture = GetSpellTexture(374251), name = "Cauterizing Flame", classes = "Dev Evoker", cooldown = 60, showAfterUse = true },
		[119905] = { texture = GetSpellTexture(119905), name = "Singe Magic", classes = "Warlock Pet", cooldown = 15, showAfterUse = true },
		[132411] = { texture = GetSpellTexture(132411), name = "Singe Magic", classes = "Warlock (Grimoire)", cooldown = 15, showAfterUse = true },
		[212640] = { texture = GetSpellTexture(212640), name = "Mending Bandage", classes = "Survival Hunter", cooldown = 25, showAfterUse = true },
	}

	sArenaMixin.specToDispel = {
		-- Druid
		[102] = 2782,   -- Balance -> Remove Corruption
		[103] = 2782,   -- Feral -> Remove Corruption  
		[104] = 2782,   -- Guardian -> Remove Corruption
		[105] = 88423,  -- Restoration -> Nature's Cure

		-- Evoker
		[1467] = 374251, -- Devastation -> Cauterizing Flame
		[1468] = 360823, -- Preservation -> Naturalize

		-- Hunter
		[255] = 212640,  -- Survival -> Mending Bandage

		-- Mage
		[62] = 475,     -- Arcane -> Remove Curse
		[63] = 475,     -- Fire -> Remove Curse
		[64] = 475,     -- Frost -> Remove Curse

		-- Monk
		[268] = 218164, -- Brewmaster -> Detox
		[269] = 218164, -- Windwalker -> Detox
		[270] = 115450, -- Mistweaver -> Detox

		-- Paladin
		[65] = 4987,    -- Holy -> Cleanse
		[66] = 213644,  -- Protection -> Cleanse Toxins
		[70] = 213644,  -- Retribution -> Cleanse Toxins

		-- Priest
		[256] = 527,    -- Discipline -> Purify
		[257] = 527,    -- Holy -> Purify
		[258] = 213634, -- Shadow -> Purify Disease

		-- Shaman
		[262] = 51886,  -- Elemental -> Cleanse Spirit
		[263] = 51886,  -- Enhancement -> Cleanse Spirit
		[264] = 77130,  -- Restoration -> Purify Spirit

		-- Warlock (both pet and grimoire variants)
		[265] = {119905, 132411}, -- Affliction -> Singe Magic (both pet and grimoire)
		[266] = {119905, 132411}, -- Demonology -> Singe Magic (both pet and grimoire)
		[267] = {119905, 132411}, -- Destruction -> Singe Magic (both pet and grimoire)
	}

	-- Default dispel categories for retail
	sArenaMixin.defaultSettings.profile.dispelCategories = {
		[527] = true,     -- Purify (Priest - Discipline/Holy)
		[4987] = true,    -- Cleanse (Holy Paladin)
		[77130] = true,   -- Purify Spirit (Resto Shaman)
		[88423] = true,   -- Nature's Cure (Resto Druid)
		[115450] = true,  -- Detox (Mistweaver Monk)
		[360823] = true,  -- Naturalize (Preservation Evoker)
	}

else
	sArenaMixin.dispelData = {
		[527] = { texture = GetSpellTexture(527), name = "Purify", classes = "Priest", cooldown = 8, healer = true },
		[4987] = { texture = GetSpellTexture(4987), name = "Cleanse", classes = "Holy Paladin", cooldown = 8, sharedSpecSpellID = true },
		[77130] = { texture = GetSpellTexture(77130), name = "Purify Spirit", classes = "Resto Shaman", cooldown = 8, healer = true },
		[51886] = { texture = GetSpellTexture(51886), name = "Cleanse Spirit", classes = "Enh/Ele Shaman", cooldown = 8, showAfterUse = true },
		[88423] = { texture = GetSpellTexture(88423), name = "Nature's Cure", classes = "Resto Druid", cooldown = 8, healer = true },
		[2782] = { texture = GetSpellTexture(2782), name = "Remove Corruption", classes = "Druid", cooldown = 8, showAfterUse = true },
		[475] = { texture = GetSpellTexture(475), name = "Remove Curse", classes = "Mage", cooldown = 8, showAfterUse = true },
		[115450] = { texture = GetSpellTexture(115450), name = "Detox", classes = "Monk", cooldown = 8, sharedSpecSpellID = true },
		[103150] = { texture = GetSpellTexture(103150), name = "Singe Magic", classes = "Warlock Pet", cooldown = 10, showAfterUse = true },
		[132411] = { texture = GetSpellTexture(132411), name = "Singe Magic", classes = "Warlock (Grimoire)", cooldown = 10, showAfterUse = true },
		[32375] = { texture = GetSpellTexture(32375), name = "Mass Dispel", classes = "Shadow Priest", cooldown = 15, showAfterUse = true },
	}

	sArenaMixin.specToDispel = {
		-- Druid
		[102] = 2782, -- Balance -> Remove Corruption
		[103] = 2782, -- Feral -> Remove Corruption
		[104] = 2782, -- Guardian -> Remove Corruption
		[105] = 88423, -- Restoration -> Nature's Cure

		-- Hunter
		[255] = 212640, -- Survival -> Mending Bandage

		-- Mage
		[62] = 475, -- Arcane -> Remove Curse
		[63] = 475, -- Fire -> Remove Curse
		[64] = 475, -- Frost -> Remove Curse

		-- Monk
		[268] = 115450, -- Brewmaster -> Detox
		[269] = 115450, -- Windwalker -> Detox
		[270] = 115450, -- Mistweaver -> Detox

		-- Paladin
		[65] = 4987, -- Holy -> Cleanse
		[66] = 4987, -- Protection -> Cleanse
		[70] = 4987, -- Retribution -> Cleanse

		-- Priest
		[256] = 527, -- Discipline -> Purify
		[257] = 527, -- Holy -> Purify
		[258] = 32375, -- Shadow -> Mass Dispel

		-- Shaman
		[262] = 51886, -- Elemental -> Cleanse Spirit
		[263] = 51886, -- Enhancement -> Cleanse Spirit
		[264] = 77130, -- Restoration -> Purify Spirit

		-- Warlock (both pet and grimoire variants)
		[265] = { 103150, 132411 }, -- Affliction -> Singe Magic (both pet and grimoire)
		[266] = { 103150, 132411 }, -- Demonology -> Singe Magic (both pet and grimoire)
		[267] = { 103150, 132411 }, -- Destruction -> Singe Magic (both pet and grimoire)
	}

	-- Default dispel categories for MoP  
	sArenaMixin.defaultSettings.profile.dispelCategories = {
		-- Healer spells (enabled by default)
		[77130] = true,   -- Purify Spirit (Resto Shaman)
		[88423] = true,   -- Nature's Cure (Resto Druid)
		[527] = true,   -- Purify (Priest healers)

		-- Shared spells - healer variants (enabled by default)
		["4987_healer"] = true,    -- Cleanse (Holy Paladin)
		["115450_healer"] = true,  -- Detox (Mistweaver)
	}
end

local detectedDispels = {}
local dispelStacks = {}

local function updateDispelStacksForFrame(frame)
	local unit = frame.unit
	local data = dispelStacks[unit]
	if not data then
		if frame.DispelStacks then
			frame.DispelStacks:SetText("")
		end
		return
	end

	local now = GetTime()

	local newUses = {}
	for _, u in ipairs(data.uses) do
		if u.endt > now then
			table.insert(newUses, u)
		end
	end
	data.uses = newUses

	local maxCharges = 2
	data.count = maxCharges - #data.uses
	if data.count < 0 then data.count = 0 end

	if frame.DispelStacks then
		if data.detected then
			frame.DispelStacks:SetText(tostring(data.count))
		else
			frame.DispelStacks:SetText("")
		end
	end

	-- Update desaturation: when dispelStacks is a numeric value (we've detected multi-charge behavior),
	-- only desaturate when 0 stacks remain. If dispelStacks hasn't detected multi-charge (""),
	-- fall back to regular behaviour (desaturate whenever a cooldown is active if configured).
	if frame.Dispel and frame.Dispel.Texture then
		local db = frame.parent and frame.parent.db
		local desaturateSetting = db and db.profile and db.profile.desaturateDispelCD
		if data.detected then
			-- data.count exists and should be 0/1/2
			frame.Dispel.Texture:SetDesaturated(desaturateSetting and data.count == 0)
		else
			-- No multi-charge detected; keep prior behaviour based on cooldown presence
			local onCooldown = desaturateSetting and frame.Dispel.Cooldown and frame.Dispel.Cooldown:GetCooldownDuration() > 0
			frame.Dispel.Texture:SetDesaturated(onCooldown)
		end
	end

	-- If there are still uses on cooldown, schedule the next check at the soonest cooldown end
	if #data.uses > 0 then
		-- data.uses stores entries with an .end field (absolute time when that charge will be back)
		local soonest = math.huge
		for _, u in ipairs(data.uses) do
			if u.endt < soonest then soonest = u.endt end
		end
		-- Update the visual cooldown to show time until the next charge returns
		if frame.Dispel and frame.Dispel.Cooldown then
			local timeUntil = math.max(0, soonest - now)
			frame.Dispel.Cooldown:SetCooldown(now, timeUntil)
		end
		local delay = math.max(0, soonest - now) + 0.01
		C_Timer.After(delay, function()
			updateDispelStacksForFrame(frame)
		end)
	else
		-- No uses on cooldown: clear the UI cooldown
		if frame.Dispel and frame.Dispel.Cooldown then
			frame.Dispel.Cooldown:Clear()
		end
	end
end

function sArenaFrameMixin:FindDispel(spellID)
	if not sArenaMixin.dispelData[spellID] then return end

	if not detectedDispels[self.unit] then
		detectedDispels[self.unit] = {}
	end
	detectedDispels[self.unit][spellID] = true

	-- Handle stacks for priest Purify (527) which can have 2 charges via talent.
	if spellID == 527 then
		if not dispelStacks[self.unit] then
			dispelStacks[self.unit] = { detected = false, uses = {}, count = nil }
		end

		local data = dispelStacks[self.unit]
		local now = GetTime()
		local dispelInfo = sArenaMixin.dispelData[spellID]
		local cooldown = dispelInfo and dispelInfo.cooldown or 8

		local endt
		if #data.uses == 0 then
			endt = now + cooldown
		else
			local lastEnd = data.uses[#data.uses].endt
			if lastEnd < now then
				endt = now + cooldown
			else
				endt = lastEnd + cooldown
			end
		end

		table.insert(data.uses, { usedAt = now, endt = endt })

		-- If this is the second use that occurs before the first use finished cooldown (based on usedAt), detect the two-use talent
		if not data.detected and #data.uses >= 2 then
			local lastUsed = data.uses[#data.uses].usedAt
			local prevUsed = data.uses[#data.uses - 1].usedAt
			if lastUsed - prevUsed < cooldown then
				data.detected = true
			end
		end

		updateDispelStacksForFrame(self)
	end

	local dispelInfo = sArenaMixin.dispelData[spellID]
	local cooldown = dispelInfo and dispelInfo.cooldown or 8


	self.Dispel.Cooldown:SetCooldown(GetTime(), cooldown)
	self:UpdateDispel()
end

function sArenaFrameMixin:GetDispelData()
	local specID = self.specID
	if not specID then return end

	local spellData = sArenaMixin.specToDispel[specID]
	if not spellData then return end

	local spellIDs = type(spellData) == "table" and spellData or {spellData}

	for _, spellID in ipairs(spellIDs) do
		if sArenaMixin.dispelData[spellID] then
			local dispelInfo = sArenaMixin.dispelData[spellID]
			local isValid = true

			-- For MoP shared spells, DPS specs need to have used the spell first
			if not isRetail and dispelInfo.sharedSpecSpellID then
				local isHealer = sArenaMixin.healerSpecIDs[specID]
				if not isHealer then
					-- DPS specs need to use the spell first
					if not detectedDispels[self.unit] or not detectedDispels[self.unit][spellID] then
						isValid = false
					end
				end
			elseif dispelInfo.showAfterUse then
				-- Regular showAfterUse logic for unique DPS spells
				if not detectedDispels[self.unit] or not detectedDispels[self.unit][spellID] then
					isValid = false
				end
			end

			if isValid then
				local isEnabled = false

				if isRetail then
					-- Retail: use simple spell-based categories
					isEnabled = self.parent.db.profile.dispelCategories[spellID]
				else
					-- MoP: check if this spell is available for this spec type
					local isHealer = sArenaMixin.healerSpecIDs[specID]

					-- For shared spells, use separate settings
					if dispelInfo.sharedSpecSpellID then
						local settingKey = spellID .. (isHealer and "_healer" or "_dps")
						isEnabled = self.parent.db.profile.dispelCategories[settingKey]
					else
						-- For unique spells, use regular spell setting but check spec type match
						isEnabled = self.parent.db.profile.dispelCategories[spellID]
						if isEnabled then
							local availableForSpec = false
							if isHealer and dispelInfo.healer then
								availableForSpec = true
							elseif not isHealer and not dispelInfo.healer then
								availableForSpec = true
							end

							if not availableForSpec then
								isEnabled = false
							end
						end
					end
				end

				if not isEnabled then
					isValid = false
				end
			end

			if isValid then
				return {
					spellID = spellID,
					texture = dispelInfo.texture,
					name = dispelInfo.name,
				}
			end
		end
	end

	return nil
end

function sArenaFrameMixin:GetTestModeDispelData()
	local class = self.tempClass
	if not class then return nil end

	local classToSpellID = {
		["DRUID"] = 88423,   -- Nature's Cure (Resto)
		["EVOKER"] = 360823, -- Naturalize (Preservation)  
		["MAGE"] = 475,      -- Remove Curse
		["MONK"] = 115450,   -- Detox (Mistweaver)
		["PALADIN"] = 4987,  -- Cleanse (Holy)
		["PRIEST"] = 527,    -- Purify
		["SHAMAN"] = 77130,  -- Purify Spirit (Resto)
	}

	local classToTestSpec = {
		["DRUID"] = 105,     -- Restoration
		["EVOKER"] = 1468,   -- Preservation
		["MAGE"] = 62,       -- Arcane
		["MONK"] = 270,      -- Mistweaver
		["PALADIN"] = 65,    -- Holy
		["PRIEST"] = 256,    -- Discipline
		["SHAMAN"] = 264,    -- Restoration
	}

	local spellID = classToSpellID[class]
	local testSpecID = classToTestSpec[class]
	if not spellID or not testSpecID then return nil end

	local dispelInfo = sArenaMixin.dispelData[spellID]
	if not dispelInfo then return nil end

	if self.parent and self.parent.db then
		local isEnabled = false

		if isRetail then
			-- Retail: use simple spell-based categories
			isEnabled = self.parent.db.profile.dispelCategories[spellID]
		else
			-- MoP: check if this spell is available for this spec type
			local isHealer = sArenaMixin.healerSpecIDs[testSpecID]

			-- For shared spells, use separate settings
			if dispelInfo.sharedSpecSpellID then
				local settingKey = spellID .. (isHealer and "_healer" or "_dps")
				isEnabled = self.parent.db.profile.dispelCategories[settingKey]
			else
				-- For unique spells, use regular spell setting but check spec type match
				isEnabled = self.parent.db.profile.dispelCategories[spellID]
				if isEnabled then
					local availableForSpec = false
					if isHealer and dispelInfo.healer then
						availableForSpec = true
					elseif not isHealer and not dispelInfo.healer then
						availableForSpec = true
					end

					if not availableForSpec then
						isEnabled = false
					end
				end
			end
		end

		if isEnabled then
			return {
				spellID = spellID,
				texture = dispelInfo.texture,
				name = dispelInfo.name,
			}
		end
	end
end

function sArenaFrameMixin:UpdateDispel()
	local dispel = self.Dispel
	local db = self.parent.db
	local dispelEnabled = db.profile.showDispels
	local dispelInfo = self:GetDispelData()

	local shouldShow = dispelEnabled and dispelInfo ~= nil
	dispel:SetShown(shouldShow)

	--print("6: UpdateDispel called for", self.unit, "shouldShow:", shouldShow)
	if not dispelInfo then
		dispel.Texture:SetTexture(nil)
		return
	end

	dispel.spellID = dispelInfo.spellID
	dispel.Texture:SetTexture(dispelInfo.texture)

	--print("7: Dispel icon set for", self.unit, "spellID:", dispelInfo.spellID)

	local onCooldown = db.profile.desaturateDispelCD and dispel.Cooldown:GetCooldownDuration() > 0
	dispel.Texture:SetDesaturated(onCooldown)

	updateDispelStacksForFrame(self)
end


function sArenaMixin:ResetDetectedDispels()
	wipe(detectedDispels)
	wipe(dispelStacks)
end

function sArenaFrameMixin:ResetDispel()
	local dispel = self.Dispel

	dispel.spellID = nil
	dispel.Texture:SetTexture(nil)
	dispel.Cooldown:Clear()
	detectedDispels[self.unit] = nil
	dispelStacks[self.unit] = nil
	dispel.Texture:SetDesaturated(false)

	self.DispelStacks:SetText("")
end