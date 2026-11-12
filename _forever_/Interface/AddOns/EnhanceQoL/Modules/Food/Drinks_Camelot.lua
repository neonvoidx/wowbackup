local addon = _G.EnhanceQoL or select(2, ...)
local C = addon.ForeverConsumables
local D = addon.Drinks

D.drinkList = {}
D.manaPotions = {}
D.mageFood = {}
D._wrapped = {}
for _, entry in ipairs(C.items) do
	if C.Matches(entry, "food") or C.Matches(entry, "drink") then D.drinkList[#D.drinkList + 1] = entry end
	if C.Matches(entry, "mana") then D.manaPotions[#D.manaPotions + 1] = entry end
	if entry.isMageFood then D.mageFood[entry.id] = true end
end

function addon.functions.updateAllowedDrinks()
	local filtered = D.filteredDrinks
	wipe(filtered)
	if not addon.db then return end
	local mana = UnitPowerMax("player", 0)
	if issecretvalue and issecretvalue(mana) then return end
	if type(mana) ~= "number" or mana <= 0 then return end
	local minimum = mana * (tonumber(addon.db.minManaFoodValue) or 0) / 100
	local entries = {}
	for _, entry in ipairs(D.drinkList) do
		if C.Matches(entry, "drink") and C.IsEligible(entry) and C.GetRecovery(entry, "mana") >= minimum then entries[#entries + 1] = entry end
	end
	table.sort(entries, function(a, b) return C.IsBetter(a, b, "mana", addon.db.preferMageFood, 0, 0) end)
	for _, entry in ipairs(entries) do
		local wrapped = D._wrapped[entry.id]
		if not wrapped then
			wrapped = addon.functions.newItem(entry.id, nil, false)
			D._wrapped[entry.id] = wrapped
		end
		filtered[#filtered + 1] = wrapped
	end
end
