-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local RSLootDB = private.NewLib("RareScannerLootDB")
local RSUtils = private.ImportLib("RareScannerUtils")


---============================================================================
-- Collections
---============================================================================

function RSLootDB.SetItemAsToy(itemID)
	if (itemID) then
		if (not private.dbglobal.toys) then
			private.dbglobal.toys = {}
		end
		
		if (not RSUtils.Contains(private.dbglobal.toys, itemID)) then
			table.insert(private.dbglobal.toys, itemID)
		end
	end
end

function RSLootDB.IsToy(itemID)
	if (itemID and private.dbglobal.toys and RSUtils.Contains(private.dbglobal.toys, itemID)) then
		return true;
	end
	
	return false
end