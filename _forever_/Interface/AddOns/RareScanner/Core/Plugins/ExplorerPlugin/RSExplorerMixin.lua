-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local LibStub = _G.LibStub
local ADDON_NAME, private = ...

-- Locales
local AL = LibStub("AceLocale-3.0"):GetLocale("RareScanner");

-- RareScanner database libraries
local RSNpcDB = private.ImportLib("RareScannerNpcDB")
local RSContainerDB = private.ImportLib("RareScannerContainerDB")
local RSCollectionsDB = private.ImportLib("RareScannerCollectionsDB")
local RSGeneralDB = private.ImportLib("RareScannerGeneralDB")
local RSMapDB = private.ImportLib("RareScannerMapDB")
local RSConfigDB = private.ImportLib("RareScannerConfigDB")
local RSAchievementDB = private.ImportLib("RareScannerAchievementDB")

-- RareScanner general libraries
local RSConstants = private.ImportLib("RareScannerConstants")
local RSLogger = private.ImportLib("RareScannerLogger")
local RSUtils = private.ImportLib("RareScannerUtils")

-- RareScanner service libraries
local RSMap = private.ImportLib("RareScannerMap")
local RSNpcPOI = private.ImportLib("RareScannerNpcPOI")
local RSContainerPOI = private.ImportLib("RareScannerContainerPOI")
local RSLootTooltip = private.ImportLib("RareScannerLootTooltip")
local RSLoot = private.ImportLib("RareScannerLoot")
local RSTooltipScanners = private.ImportLib("RareScannerTooltipScanners")
local RSRoutines = private.ImportLib("RareScannerRoutines")

-- Thirdparty
local LibDialog = LibStub("LibDialog-1.0RS")

-----------------------------------------------------
-- Filters panel
-----------------------------------------------------

RSExplorerFilters = { };

local filters = { }

local currentContinentDropDownValues = { }

local function MapByName_Sort(mapIDs)
	local comparison = function(mapID1, mapID2)
		local mapName1 = RSMapDB.GetMapName(mapID1) or ""
		local mapName2 = RSMapDB.GetMapName(mapID2) or ""

		-- Otherwise order by name
		local strCmpResult = strcmputf8i(mapName1, mapName2);
		if (strCmpResult ~= 0) then
			return strCmpResult < 0;
		end
	end
				
	table.sort(mapIDs, comparison)
end

local explorerContinentOfMap = {}

local function GetExplorerContinentOfMap(mapID)
	-- It is called for every entity, so the result is cached
	local continentID = explorerContinentOfMap[mapID]
	if (continentID == nil) then
		continentID = false

		-- Dungeons, delves... only appear in their own section, not inside the zone where they are
		for _, ownContinentID in ipairs(RSConstants.EXPLORER_OWN_SECTION_CONTINENTS) do
			if (RSMapDB.IsMapInAnyContinent(mapID, { ownContinentID })) then
				continentID = ownContinentID
				break
			end
		end

		-- Temporary versions of a zone (quests that can't be repeated) don't appear
		if (not continentID and not RSMapDB.IsHiddenZone(mapID)) then
			continentID = RSMapDB.GetContinentOfMap(mapID) or false
		end

		explorerContinentOfMap[mapID] = continentID
	end

	return continentID or nil
end

-- A map is available if it has results or it contains maps with results
local function IsExplorerMapAvailable(continentID, mapID)
	local mapIDs = currentContinentDropDownValues[continentID]
	if (not mapIDs) then
		return false
	end

	if (RSUtils.Contains(mapIDs, mapID)) then
		return true
	end

	for _, listedMapID in ipairs(mapIDs) do
		if (RSMapDB.IsMapInParentMap(mapID, listedMapID)) then
			return true
		end
	end

	return false
end

local function AddMapDropDownValue(mapID, continentDropDownValuesNotSorted)
	local continentID = GetExplorerContinentOfMap(mapID)
	if (continentID) then
		if (not continentDropDownValuesNotSorted[continentID]) then
			continentDropDownValuesNotSorted[continentID] = {}
		end
		if (not RSUtils.Contains(continentDropDownValuesNotSorted[continentID], mapID)) then
			table.insert(continentDropDownValuesNotSorted[continentID], mapID)
		end
	end
end

local function AddContinentDropDownValue(entityID, entityInfo, continentDropDownValuesNotSorted, source)
	if ((source == RSConstants.ITEM_SOURCE.NPC and RSNpcDB.IsInternalNpcMultiZone(entityID)) or (source == RSConstants.ITEM_SOURCE.CONTAINER and RSContainerDB.IsInternalContainerMultiZone(entityID))) then
		for mapID, _ in pairs (entityInfo.zoneID) do
			AddMapDropDownValue(mapID, continentDropDownValuesNotSorted)
		end
	else
		AddMapDropDownValue(entityInfo.zoneID, continentDropDownValuesNotSorted)
	end
end

local function AddEntityContinentDropDownValue(entityID, entityInfo, continentDropDownValuesNotSorted, source)
	local collectionsLoot = RSCollectionsDB.GetAllEntitiesCollectionsLoot()[source]

	-- Ignoring the collectibles every entity is shown
	if (filters[RSConstants.EXPLORER_FILTER_IGNORE_COLLECTIBLES]) then
		AddContinentDropDownValue(entityID, entityInfo, continentDropDownValuesNotSorted, source)
		return
	end

	local alreadyAdded = false
	if (not alreadyAdded and filters[RSConstants.EXPLORER_FILTER_DROP_MOUNTS] and collectionsLoot and collectionsLoot[entityID] and RSUtils.GetTableLength(collectionsLoot[entityID][RSConstants.ITEM_TYPE.MOUNT]) > 0) then
		AddContinentDropDownValue(entityID, entityInfo, continentDropDownValuesNotSorted, source)
		alreadyAdded = true
	end
	
	if (not alreadyAdded and filters[RSConstants.EXPLORER_FILTER_DROP_PETS] and collectionsLoot and collectionsLoot[entityID] and RSUtils.GetTableLength(collectionsLoot[entityID][RSConstants.ITEM_TYPE.PET]) > 0) then
		AddContinentDropDownValue(entityID, entityInfo, continentDropDownValuesNotSorted, source)
		alreadyAdded = true
	end
	
	if (not alreadyAdded and filters[RSConstants.EXPLORER_FILTER_DROP_TOYS] and collectionsLoot and collectionsLoot[entityID] and RSUtils.GetTableLength(collectionsLoot[entityID][RSConstants.ITEM_TYPE.TOY]) > 0) then
		AddContinentDropDownValue(entityID, entityInfo, continentDropDownValuesNotSorted, source)
		alreadyAdded = true
	end
	
	if (not alreadyAdded and filters[RSConstants.EXPLORER_FILTER_DROP_APPEARANCES] and collectionsLoot and collectionsLoot[entityID] and RSUtils.GetTableLength(collectionsLoot[entityID][RSConstants.ITEM_TYPE.APPEARANCE]) > 0) then
		if (filters[RSConstants.EXPLORER_FILTER_DROP_CLASS_APPEARANCES]) then
			for _, itemID in pairs(collectionsLoot[entityID][RSConstants.ITEM_TYPE.APPEARANCE]) do
				if (RSCollectionsDB.IsNotCollectedClassAppearance(itemID)) then
					AddContinentDropDownValue(entityID, entityInfo, continentDropDownValuesNotSorted, source)
					alreadyAdded = true
					break
				end
			end
		else
			AddContinentDropDownValue(entityID, entityInfo, continentDropDownValuesNotSorted, source)
			alreadyAdded = true
		end
	end
	
	if (not alreadyAdded) then
		if (filters[RSConstants.EXPLORER_FILTER_WITHOUT_COLLECTIBLES] and (not collectionsLoot or not collectionsLoot[entityID])) then
			AddContinentDropDownValue(entityID, entityInfo, continentDropDownValuesNotSorted, source)
			alreadyAdded = true
		else
			for groupKey, _ in pairs(RSCollectionsDB.GetItemGroups()) do	
				if (filters[string.format(RSConstants.EXPLORER_FILTER_DROP_CUSTOM, groupKey)] and collectionsLoot and collectionsLoot[entityID] and RSUtils.GetTableLength(collectionsLoot[entityID][string.format(RSConstants.ITEM_TYPE.CUSTOM, groupKey)]) > 0) then
					AddContinentDropDownValue(entityID, entityInfo, continentDropDownValuesNotSorted, source)
					alreadyAdded = true
				end
			end
		end
	end
end

local function PopulateContinentDropDown(mainFrame, continentDropDown, callback)    
    currentContinentDropDownValues = {}
    local continentDropDownValuesNotSorted = {}
    
    if (RSUtils.GetTableLength(filters) == 0) then
        continentDropDown:GenerateMenu()
        mainFrame:HideContentPanels()
        mainFrame.ScanRequired.ScanRequiredText:SetText(AL["EXPLORER_NO_RESULTS"])
        mainFrame.ScanRequired.StartScanningButton:Hide()
        mainFrame.ScanRequired:Show()
        mainFrame.Filters:Show()
        
        if (callback) then
        	callback()
        end
        return
    end

    local routines = {}

    -- Check NPCs
    local npcScanRoutine = RSRoutines.LoopRoutineNew()
    npcScanRoutine:Init(
        RSNpcDB.GetAllInternalNpcInfo,
        function(context, npcID, npcInfo)
            local filtered = false
            
            -- Ignore if part of a disabled event
            if (not filters[RSConstants.EXPLORER_FILTER_TYPE_NPC] or RSNpcDB.IsDisabledEvent(npcID)) then
                filtered = true
            end
            
            -- Ignore if dead
            if (not filtered and not filters[RSConstants.EXPLORER_FILTER_DEAD] and RSNpcDB.IsNpcKilled(npcID)) then
                filtered = true
            end
            
            -- Ignore if filtered
            if (not filtered and not filters[RSConstants.EXPLORER_FILTER_FILTERED] and RSConfigDB.GetNpcFiltered(npcID) ~= nil) then
                filtered = true
            end
            
            -- Add if matches collections
            if (not filtered) then
                AddEntityContinentDropDownValue(npcID, npcInfo, continentDropDownValuesNotSorted, RSConstants.ITEM_SOURCE.NPC)
            end
        end
    )
    table.insert(routines, npcScanRoutine)

    -- Check containers
    local containerScanRoutine = RSRoutines.LoopRoutineNew()
    containerScanRoutine:Init(
        RSContainerDB.GetAllInternalContainerInfo,
        function(context, containerID, containerInfo)
            local filtered = false
            
            -- Ignore if part of a disabled event
            if (not filters[RSConstants.EXPLORER_FILTER_TYPE_CONTAINER] or RSContainerDB.IsDisabledEvent(containerID)) then
                filtered = true
            end
            
            -- Ignore if dead
            if (not filtered and not filters[RSConstants.EXPLORER_FILTER_DEAD] and RSContainerDB.IsContainerOpened(containerID)) then
                filtered = true
            end
            
            -- Ignore if filtered
            if (not filtered and not filters[RSConstants.EXPLORER_FILTER_FILTERED] and RSConfigDB.GetContainerFiltered(containerID) ~= nil) then
                filtered = true
            end
            
            -- Add if matches collections
            if (not filtered) then
                AddEntityContinentDropDownValue(containerID, containerInfo, continentDropDownValuesNotSorted, RSConstants.ITEM_SOURCE.CONTAINER)
            end
        end
    )
    table.insert(routines, containerScanRoutine)

    -- Process everything
    local chainRoutines = RSRoutines.ChainLoopRoutineNew()
    chainRoutines:Init(routines)
    chainRoutines:Run(function(context)
        -- Sort continents by name
        local continentsSorted = {}
        for continentID, _ in pairs(continentDropDownValuesNotSorted) do
            table.insert(continentsSorted, continentID)
        end
        MapByName_Sort(continentsSorted)

        -- Sort maps by name
        for continentID, mapIDs in pairs(continentDropDownValuesNotSorted) do
            MapByName_Sort(mapIDs)
            currentContinentDropDownValues[continentID] = mapIDs
        end
        
        -- If player is locking current map check if available and selects it
        if (RSConfigDB.IsLockingCurrentMap()) then
            -- Gets players map ID
            local currentPlayerMapID = C_Map.GetBestMapForUnit("player")
            if (currentPlayerMapID) then
                -- The map of the player, or the first one that contains it with results
                local candidateMapIDs = { currentPlayerMapID }
                for _, ancestorMapID in ipairs(RSMapDB.GetMapAncestors(currentPlayerMapID)) do
                    table.insert(candidateMapIDs, ancestorMapID)
                end

                for _, candidateMapID in ipairs(candidateMapIDs) do
                    local candidateContinentID = GetExplorerContinentOfMap(candidateMapID)
                    if (candidateContinentID and IsExplorerMapAvailable(candidateContinentID, candidateMapID)) then
                        RSConfigDB.SetExplorerContinentMapID(candidateContinentID)
                        RSConfigDB.SetExplorerMapID(candidateMapID)
                        break
                    end
                end
            end
        end
        
        -- Tries to select the previous continent/map
        local previousContinentID = RSConfigDB.GetExplorerContinentMapID()
        local previousMapID = RSConfigDB.GetExplorerMapID()

        if (previousContinentID and previousMapID and RSUtils.Contains(continentsSorted, previousContinentID) and IsExplorerMapAvailable(previousContinentID, previousMapID)) then
            continentDropDown:GenerateMenu()
            mainFrame:ShowContentPanels()
            mainFrame.ScanRequired:Hide()
            mainFrame.CustomLoot:Hide()
        -- Otherwise select the first map available
        elseif (RSUtils.GetTableLength(continentsSorted) > 0) then
            for _, continentID in ipairs(continentsSorted) do
                RSConfigDB.SetExplorerContinentMapID(continentID)
                local mapID = currentContinentDropDownValues[continentID][1]
                RSConfigDB.SetExplorerMapID(mapID)
                continentDropDown:GenerateMenu()
                break
            end
            
            mainFrame:ShowContentPanels()
            mainFrame.ScanRequired:Hide()
            mainFrame.CustomLoot:Hide()
        else
            continentDropDown:GenerateMenu()
            mainFrame:HideContentPanels()
            mainFrame.ScanRequired.ScanRequiredText:SetText(AL["EXPLORER_NO_RESULTS"])
            mainFrame.ScanRequired.StartScanningButton:Hide()
            mainFrame.ScanRequired:Show()
            mainFrame.Filters:Show()
        end
        
        if (callback) then
        	callback()
        end
    end)
end

-- While ignoring the missing collectibles the collections filters are shown unchecked and disabled
local function GetCollectionFilterValue(filterKey)
	return not filters[RSConstants.EXPLORER_FILTER_IGNORE_COLLECTIBLES] and filters[filterKey]
end

local function IsCollectionFilterEnabled()
	return not filters[RSConstants.EXPLORER_FILTER_IGNORE_COLLECTIBLES]
end

local function FilterDropDownMenu_SetupMenu(dropDown, rootDescription)	
	-- Collections menu
	local collectionsSubmenu = rootDescription:CreateButton(AL["EXPLORER_FILTER_COLLECTIONS"]);

	-- Ignore missing collectibles
	local ignoreCollectiblesFilter = collectionsSubmenu:CreateRadio(AL["EXPLORER_FILTER_IGNORE_COLLECTIBLES"],
		function(filterKey) return filters[filterKey] end,
		function(filterKey)
			-- Overriden by SetResponder
		end,
		RSConstants.EXPLORER_FILTER_IGNORE_COLLECTIBLES)
	ignoreCollectiblesFilter:SetResponder(function(filterKey)
		if (filters[filterKey]) then
			RSConfigDB.SetIgnoreMissingCollectibles(false)
			filters[filterKey] = nil
		else
			RSConfigDB.SetIgnoreMissingCollectibles(true)
			filters[filterKey] = true
		end

		return MenuResponse.Refresh;
	end)
	collectionsSubmenu:CreateDivider()

	local mountsFilter = collectionsSubmenu:CreateRadio(AL["EXPLORER_FILTER_MOUNTS"], 
		GetCollectionFilterValue, 
		function(filterKey) 
			-- Overriden by SetResponder
		end,
		RSConstants.EXPLORER_FILTER_DROP_MOUNTS)
	mountsFilter:SetResponder(function(filterKey)
		if (filters[filterKey]) then
			RSConfigDB.SetSearchingMounts(false)
			filters[filterKey] = nil
		else
			RSConfigDB.SetSearchingMounts(true)
			filters[filterKey] = true
		end
			
		return MenuResponse.Refresh;
	end)
	mountsFilter:SetEnabled(IsCollectionFilterEnabled)
	
	local petsFilter = collectionsSubmenu:CreateRadio(AL["EXPLORER_FILTER_PETS"], 
		GetCollectionFilterValue, 
		function(filterKey)
			-- Overriden by SetResponder
		end,
		RSConstants.EXPLORER_FILTER_DROP_PETS)
	petsFilter:SetResponder(function(filterKey)
		if (filters[filterKey]) then
			RSConfigDB.SetSearchingPets(false)
			filters[filterKey] = nil
		else
			RSConfigDB.SetSearchingPets(true)
			filters[filterKey] = true
		end
			
		return MenuResponse.Refresh;
	end)
	petsFilter:SetEnabled(IsCollectionFilterEnabled)
	
	local toysFilter = collectionsSubmenu:CreateRadio(AL["EXPLORER_FILTER_TOYS"], 
		GetCollectionFilterValue, 
		function(filterKey)
			-- Overriden by SetResponder
		end,
		RSConstants.EXPLORER_FILTER_DROP_TOYS)
	toysFilter:SetResponder(function(filterKey)
		if (filters[filterKey]) then
			RSConfigDB.SetSearchingToys(false)
			filters[filterKey] = nil
		else
			RSConfigDB.SetSearchingToys(true)
			filters[filterKey] = true
		end
			
		return MenuResponse.Refresh;
	end)
	toysFilter:SetEnabled(IsCollectionFilterEnabled)
	
	local appearancesFilter = collectionsSubmenu:CreateRadio(AL["EXPLORER_FILTER_APPEARANCES"], 
		GetCollectionFilterValue, 
		function(filterKey)
			-- Overriden by SetResponder
		end,
		RSConstants.EXPLORER_FILTER_DROP_APPEARANCES)
	appearancesFilter:SetResponder(function(filterKey)
		if (filters[filterKey]) then
			RSConfigDB.SetSearchingAppearances(false)
			filters[filterKey] = nil
			
			-- Also disables searching for appearances for the current class
			filters[RSConstants.EXPLORER_FILTER_DROP_CLASS_APPEARANCES] = false
			RSConfigDB.SetSearchingClassAppearances(false)
		else
			RSConfigDB.SetSearchingAppearances(true)
			filters[filterKey] = true
		end
		
		return MenuResponse.Refresh;
	end)
	appearancesFilter:SetEnabled(IsCollectionFilterEnabled)
	
	local appearancesClassFilter = collectionsSubmenu:CreateRadio(AL["EXPLORER_FILTER_CLASS_APPEARANCES"], 
		GetCollectionFilterValue, 
		function(filterKey)
			-- Overriden by SetResponder
		end,
		RSConstants.EXPLORER_FILTER_DROP_CLASS_APPEARANCES)
	appearancesClassFilter:SetResponder(function(filterKey)
		if (filters[filterKey]) then
			RSConfigDB.SetSearchingClassAppearances(false)
			filters[filterKey] = nil
		else
			RSConfigDB.SetSearchingClassAppearances(true)
			filters[filterKey] = true
		end
		
		return MenuResponse.Refresh;
	end)
	appearancesClassFilter:SetEnabled(function() return IsCollectionFilterEnabled() and RSConfigDB.IsSearchingAppearances() end)

	local itemGroups = RSCollectionsDB.GetItemGroups()
	if (itemGroups) then
		for groupKey, groupName in pairs (itemGroups) do
			if (RSCollectionsDB.HasGroupItems(groupKey)) then
				local customFilter = collectionsSubmenu:CreateRadio(string.format(AL["EXPLORER_FILTER_CUSTOM"], groupName), 
					GetCollectionFilterValue, 
					function(filterKey)
						-- Overriden by SetResponder
					end,
					string.format(RSConstants.EXPLORER_FILTER_DROP_CUSTOM, groupKey))
				customFilter:SetResponder(function(filterKey)
					if (filters[filterKey]) then
						RSConfigDB.SetSearchingCustom(groupKey, false)
						filters[filterKey] = nil
					else
						RSConfigDB.SetSearchingCustom(groupKey, true)
						filters[filterKey] = true
					end
					
					return MenuResponse.Refresh;
				end)
				customFilter:SetEnabled(IsCollectionFilterEnabled)
			end
		end
	end

	-- Entities without missing collectibles
	local noCollectiblesFilter = collectionsSubmenu:CreateRadio(AL["EXPLORER_FILTER_WITHOUT_COLLECTIBLES"],
		GetCollectionFilterValue,
		function(filterKey)
			-- Overriden by SetResponder
		end,
		RSConstants.EXPLORER_FILTER_WITHOUT_COLLECTIBLES)
	noCollectiblesFilter:SetResponder(function(filterKey)
		if (filters[filterKey]) then
			RSConfigDB.SetShowWithoutCollectibles(false)
			filters[filterKey] = nil
		else
			RSConfigDB.SetShowWithoutCollectibles(true)
			filters[filterKey] = true
		end

		return MenuResponse.Refresh;
	end)
	noCollectiblesFilter:SetEnabled(IsCollectionFilterEnabled)

	-- Type menu
	local typeSubmenu = rootDescription:CreateButton(AL["EXPLORER_FILTER_TYPE"]);
	local npcFilter = typeSubmenu:CreateRadio(AL["EXPLORER_FILTER_TYPE_NPC"],
		function(filterKey) return filters[filterKey] end,
		function(filterKey)
			-- Overriden by SetResponder
		end,
		RSConstants.EXPLORER_FILTER_TYPE_NPC)
	npcFilter:SetResponder(function(filterKey)
		if (filters[filterKey]) then
			RSConfigDB.SetShowNpcs(false)
			filters[filterKey] = nil
		else
			RSConfigDB.SetShowNpcs(true)
			filters[filterKey] = true
		end

		return MenuResponse.Refresh;
	end)

	local containerFilter = typeSubmenu:CreateRadio(AL["EXPLORER_FILTER_TYPE_CONTAINER"],
		function(filterKey) return filters[filterKey] end,
		function(filterKey)
			-- Overriden by SetResponder
		end,
		RSConstants.EXPLORER_FILTER_TYPE_CONTAINER)
	containerFilter:SetResponder(function(filterKey)
		if (filters[filterKey]) then
			RSConfigDB.SetShowContainers(false)
			filters[filterKey] = nil
		else
			RSConfigDB.SetShowContainers(true)
			filters[filterKey] = true
		end

		return MenuResponse.Refresh;
	end)

	-- State menu
	local stateSubmenu = rootDescription:CreateButton(AL["EXPLORER_FILTER_STATE"]);
	local deadFilter = stateSubmenu:CreateRadio("|TInterface/RaidFrame/ReadyCheck-Ready:16|t "..AL["EXPLORER_FILTER_DEAD"],
		function(filterKey) return filters[filterKey] end, 
		function(filterKey) 
			-- Overriden by SetResponder
		end,
		RSConstants.EXPLORER_FILTER_DEAD)
	deadFilter:SetResponder(function(filterKey)
		if (filters[filterKey]) then
			RSConfigDB.SetShowDead(false)
			filters[filterKey] = nil
		else
			RSConfigDB.SetShowDead(true)
			filters[filterKey] = true
		end
			
		return MenuResponse.Refresh;
	end)
	
	local filteredFilter = stateSubmenu:CreateRadio("|TInterface/PaperDollInfoFrame/UI-GearManager-LeaveItem-Opaque:16|t "..AL["EXPLORER_FILTER_FILTERED"],
		function(filterKey) return filters[filterKey] end, 
		function(filterKey) 
			-- Overriden by SetResponder
		end,
		RSConstants.EXPLORER_FILTER_FILTERED)
	filteredFilter:SetResponder(function(filterKey)
		if (filters[filterKey]) then
			RSConfigDB.SetShowFiltered(false)
			filters[filterKey] = nil
		else
			RSConfigDB.SetShowFiltered(true)
			filters[filterKey] = true
		end
			
		return MenuResponse.Refresh;
	end)
	
end

-- Every map is nested inside the maps that contain it (cave > zone)
local function BuildMapsTree(mapIDs)
	local nodes = {}
	local rootMapIDs = {}

	local function GetNode(mapID)
		if (not nodes[mapID]) then
			nodes[mapID] = { mapID = mapID, childMapIDs = {} }
		end
		return nodes[mapID]
	end

	for _, mapID in ipairs(mapIDs) do
		GetNode(mapID)

		local currentMapID = mapID
		for _, parentMapID in ipairs(RSMapDB.GetMapAncestors(mapID)) do
			local parentNode = GetNode(parentMapID)
			if (not RSUtils.Contains(parentNode.childMapIDs, currentMapID)) then
				table.insert(parentNode.childMapIDs, currentMapID)
			end
			currentMapID = parentMapID
		end

		if (not RSUtils.Contains(rootMapIDs, currentMapID)) then
			table.insert(rootMapIDs, currentMapID)
		end
	end

	MapByName_Sort(rootMapIDs)
	return nodes, rootMapIDs
end

-- A map is marked if it is the selected one or contains it
local function IsMapNodeSelected(nodes, mapID)
	if (mapID == RSConfigDB.GetExplorerMapID()) then
		return true
	end

	for _, childMapID in ipairs(nodes[mapID].childMapIDs) do
		if (IsMapNodeSelected(nodes, childMapID)) then
			return true
		end
	end

	return false
end

local function AddMapToMenu(parentDescription, nodes, mapID, continentID, dropDown)
	local description = parentDescription:CreateRadio(RSMapDB.GetMapName(mapID) or tostring(mapID), 
		function(mapID) return IsMapNodeSelected(nodes, mapID) end, 
		function(mapID) 
			RSConfigDB.SetExplorerContinentMapID(continentID)
			RSConfigDB.SetExplorerMapID(mapID)
			
			-- Refresh list
			dropDown:GetParent().mainFrame.RareNPCList:RefreshDataProvider()
		end,
		mapID)

	-- Otherwise the menu doesn't close when selecting a map that has maps inside
	description:SetShouldRespondIfSubmenu(true)

	MapByName_Sort(nodes[mapID].childMapIDs)
	for _, childMapID in ipairs(nodes[mapID].childMapIDs) do
		AddMapToMenu(description, nodes, childMapID, continentID, dropDown)
	end
end

local function ContinentDropDownMenu_SetupMenu(dropDown, rootDescription)
	local continentsSorted = { }
   	for continentID, _ in pairs(currentContinentDropDownValues) do
   		table.insert(continentsSorted, continentID)
   	end
	MapByName_Sort(continentsSorted)
	
	-- Continents submenu
	for _, continentID in ipairs(continentsSorted) do
		local continentName = RSMapDB.GetMapName(continentID)
		if (continentName) then
			local continentSubmenu = rootDescription:CreateRadio(continentName, 
				function(continentID) return continentID == RSConfigDB.GetExplorerContinentMapID() end, 
				function(continentID) end,
				continentID)
				
			-- Maps submenu
			local nodes, rootMapIDs = BuildMapsTree(currentContinentDropDownValues[continentID])
			for _, mapID in ipairs(rootMapIDs) do
				AddMapToMenu(continentSubmenu, nodes, mapID, continentID, dropDown)
			end
  		end
	end
end

function RSExplorerFilters:Initialize(mainFrame)
	if (mainFrame.initialized) then
		mainFrame:Refresh()
	else
		self.mainFrame = mainFrame
		
		self.FilterDropDown:SetText(AL["EXPLORER_FILTERS"]);
		self.FilterDropDown:SetupMenu(FilterDropDownMenu_SetupMenu)
		self.FilterDropDown:SetUpdateCallback(function() mainFrame:Refresh() end)
		
		self.ContinentDropDown:SetDefaultText(AL["EXPLORER_NO_RESULTS"])
		PopulateContinentDropDown(self.mainFrame, self.ContinentDropDown, function()
			mainFrame.RareNPCList:RefreshDataProvider()
		end)
		self.ContinentDropDown:SetupMenu(ContinentDropDownMenu_SetupMenu)
		
		self.LockCurrentZoneCheckButton.Text:SetText(AL["EXPLORER_LOCK_CURRENT_ZONE"])
		self.LockCurrentZoneCheckButton.tooltip = AL["EXPLORER_LOCK_CURRENT_ZONE_DESC"]
		self.LockCurrentZoneCheckButton:SetChecked(RSConfigDB.IsLockingCurrentMap())
		self.LockCurrentZoneCheckButton.func = function(self, checked)
			RSConfigDB.SetLockingCurrentMap(checked)
		end
		
		self.RestartScanningButton:SetText(AL["EXPLORER_RESCANN"])
		self.RestartScanningButton.tooltip = AL["EXPLORER_RESCANN_DESC"]
	end
end

function RSExplorerFilters:RestartScanning(self, button)
	local mainFrame = self:GetParent().mainFrame
	mainFrame.ScanRequired.ScanRequiredText:SetText(AL["EXPLORER_SCAN_MANUAL"])
	mainFrame.ScanRequired.StartScanningButton:SetText(AL["EXPLORER_START_SCAN"])
	mainFrame.ScanRequired.StartScanningButton:Show()
	mainFrame.ScanRequired:Show()
	mainFrame:ShowCustomLootPanels()
	mainFrame:HideContentPanels()
end

-----------------------------------------------------
-- Rare list panel
-----------------------------------------------------

RSExplorerRareList = { };

local RARE_TEXTURE_OFFSET = -24;

-- Bosses first, then NPCs from the highest to the lowest level, NPCs without level and containers
local function GetSortGroup(element)
	if (element.isContainer) then
		return 4
	elseif (not element.level) then
		return 3
	elseif (element.level == RSConstants.NPC_BOSS_LEVEL) then
		return 1
	end

	return 2
end

local function RSExplorerRareList_Sort(e1, e2)
	local group1 = GetSortGroup(e1)
	local group2 = GetSortGroup(e2)
	if (group1 ~= group2) then
		return group1 < group2
	end

	if (group1 == 2 and e1.level ~= e2.level) then
		return e1.level > e2.level
	end

	-- Otherwise order by name
	local strCmpResult = strcmputf8i(e1.name, e2.name);
	if (strCmpResult ~= 0) then
		return strCmpResult < 0;
	end
end

function RSExplorerRareList:Initialize(mainFrame)
	if (mainFrame.initialized) then
		return
	end
	
	self.mainFrame = mainFrame
	self.scrollView = CreateScrollBoxListLinearView();
    self.scrollView:SetElementInitializer("RSExplorerListButtonTemplate", GenerateClosure(self.OnElementInitialize, self));
	ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.scrollView);
	
	self.selectionBehavior = ScrollUtil.AddSelectionBehavior(self.scrollBox);
    self.selectionBehavior:RegisterCallback("OnSelectionChanged", self.OnElementSelectionChanged, self);
	
	self.dataProvider = CreateDataProvider()
	self.dataProvider:SetSortComparator(RSExplorerRareList_Sort)
	self.scrollBox:SetDataProvider(self.dataProvider);
end

local function ToggleButtonTexture(activeTextures, texture, hasMissingType)
	if (hasMissingType) then
		texture:ClearAllPoints();
		texture:SetPoint("TOPRIGHT", -2 + (activeTextures * RARE_TEXTURE_OFFSET), -2)
		texture:Show()
		return activeTextures + 1
	else
		texture:Hide()
		return activeTextures
	end
end

local COMPLETED_ICON = "|TInterface/RaidFrame/ReadyCheck-Ready:16|t "

local function SetEntityName(element, elementData)
	local level = elementData.level
	-- Completed icon in front of the name
	local prefix = elementData.dead and COMPLETED_ICON or ""
	if (not level) then
		element.Name:SetText(prefix .. elementData.name)
		if (elementData.isContainer) then
			element.Name:SetTextColor(1, 1, 1, 1)
		else
			element.Name:SetTextColor(1, 0.85, 0, 1)
		end
		return
	end

	local levelText = level
	local color
	if (level == RSConstants.NPC_BOSS_LEVEL) then
		levelText = "??"
		color = QuestDifficultyColors["impossible"]
	else
		color = GetCreatureDifficultyColor(level)
		-- White instead of gray
		if (color == QuestDifficultyColors["trivial"]) then
			color = { r = 1, g = 1, b = 1 }
		end
	end

	element.Name:SetText(prefix .. levelText .. " - " .. elementData.name)
	element.Name:SetTextColor(color.r, color.g, color.b, 1)
end

local function ToggleEntityState(element, elementData)
	SetEntityName(element, elementData)

	-- Filtered icon above the name
	element.StateIcon:SetShown(elementData.filtered)
	
	if (elementData.filtered) then
		if (elementData.isNpc) then
			element.PortraitFrame.Portrait:SetDesaturated(1)
		else
			element.PortraitFrame.Treasure:SetDesaturated(1)
		end
		element.MountTexture:SetDesaturated(1)
		element.PetTexture:SetDesaturated(1)
		element.ToyTexture:SetDesaturated(1)
		element.AppearanceTexture:SetDesaturated(1)
		element.DecorTexture:SetDesaturated(1)
		element.CustomTexture:SetDesaturated(1)
	else
		if (elementData.isNpc) then
			element.PortraitFrame.Portrait:SetDesaturated(nil)
		else
			element.PortraitFrame.Treasure:SetDesaturated(nil)
		end
		element.MountTexture:SetDesaturated(nil)
		element.PetTexture:SetDesaturated(nil)
		element.ToyTexture:SetDesaturated(nil)
		element.AppearanceTexture:SetDesaturated(nil)
		element.DecorTexture:SetDesaturated(nil)
		element.CustomTexture:SetDesaturated(nil)
	end
end

function RSExplorerRareList:OnElementInitialize(element, elementData)
	local activeTextures = 0
	activeTextures = ToggleButtonTexture(activeTextures, element.MountTexture, elementData.hasMissingMount)
	activeTextures = ToggleButtonTexture(activeTextures, element.PetTexture, elementData.hasMissingPet)
	activeTextures = ToggleButtonTexture(activeTextures, element.ToyTexture, elementData.hasMissingToy)
	activeTextures = ToggleButtonTexture(activeTextures, element.AppearanceTexture, elementData.hasMissingAppearance)
	activeTextures = ToggleButtonTexture(activeTextures, element.DecorTexture, elementData.hasMissingDecor)
	activeTextures = ToggleButtonTexture(activeTextures, element.CustomTexture, elementData.hasMissingCustom)
	
	if (self.selectionBehavior:IsSelected(element)) then
		element.Selected:Show()
	else
		element.Selected:Hide()
	end
	
	if (elementData.isContainer) then
		element.PortraitFrame.Treasure:Show()
		element.PortraitFrame.Portrait:Hide()
		element.PortraitFrame.RareOverlay:Hide()
		element.PortraitFrame.CustomOverlay:Hide()
	else
		element.PortraitFrame.Portrait:Show()
		element.PortraitFrame.Treasure:Hide()
		
		local retOk, _ = pcall(SetPortraitTextureFromCreatureDisplayID, element.PortraitFrame.Portrait, elementData.displayID)
		if (not retOk) then
			RSLogger:PrintDebugMessage(string.format("RSExplorerRareList:UpdateData: [npcID=%s][displayID=%s] Error al cargar el portaretrato.", elementData.entityID, elementData.displayID or "nil"))
		end
	
		if (elementData.custom) then
			element.PortraitFrame.RareOverlay:Hide()
			element.PortraitFrame.CustomOverlay:Show()
		else
			element.PortraitFrame.RareOverlay:Show()
			element.PortraitFrame.CustomOverlay:Hide()
		end
	end
	
	ToggleEntityState(element, elementData)
	
	element:RegisterForClicks("LeftButtonUp", "RightButtonDown");
	element:SetScript("OnClick", function(element, button) self:OnElementClick(element, elementData, button) end);
	element:SetScript("OnEnter", function(element) self:OnElementEnter(element, elementData) end);
	element:SetScript("OnLeave", function(element) self:OnElementLeave(element, elementData) end);
end

function RSExplorerRareList:OnElementClick(element, elementData, button)
	local mainFrame = self:GetParent()
	if (button == "LeftButton") then
		self.selectionBehavior:ClearSelections()
		self.selectionBehavior:Select(element);
	elseif (button == "RightButton") then
		if (elementData.isNpc) then
			if (RSConfigDB.GetNpcFiltered(elementData.entityID) ~= nil) then
				RSLogger:PrintMessage(AL["ENABLED_SEARCHING_ENTITIE"]..elementData.name)
				RSConfigDB.DeleteNpcFiltered(elementData.entityID)
				elementData.filtered = false
			else
				RSLogger:PrintMessage(AL["DISABLED_SEARCHING_ENTITIE"]..elementData.name)
				RSConfigDB.SetNpcFiltered(elementData.entityID)
				elementData.filtered = true
			end
		else
			if (RSConfigDB.GetContainerFiltered(elementData.entityID) ~= nil) then
				RSLogger:PrintMessage(AL["ENABLED_SEARCHING_ENTITIE"]..elementData.name)
				RSConfigDB.DeleteContainerFiltered(elementData.entityID)
				elementData.filtered = false
			else
				RSLogger:PrintMessage(AL["DISABLED_SEARCHING_ENTITIE"]..elementData.name)
				RSConfigDB.SetContainerFiltered(elementData.entityID)
				elementData.filtered = true
			end
		end
		
		ToggleEntityState(element, elementData)
	end
end

function RSExplorerRareList:OnElementEnter(element, elementData)
	local mainFrame = self:GetParent()
	local tooltip = mainFrame.Tooltip
	tooltip:SetOwner(element, "ANCHOR_LEFT")
	tooltip:SetText(elementData.name)
	tooltip:AddLine(AL["EXPLORER_BUTTON_TOOLTIP1"], 1, 1, 1)
	if (RSConfigDB.GetNpcFiltered(elementData.entityID) ~= nil) then
		tooltip:AddLine(AL["EXPLORER_BUTTON_TOOLTIP2"], 1, 1, 1)
	else
		tooltip:AddLine(AL["EXPLORER_BUTTON_TOOLTIP3"], 1, 1, 1)
	end
	tooltip:Show()
end

function RSExplorerRareList:OnElementLeave(element, elementData)
	local mainFrame = self:GetParent()
	local tooltip = mainFrame.Tooltip
	tooltip:Hide()
end

local function SetDungeonMapTexture(texture, info)
	texture:SetTexture(string.format(RSConstants.DUNGEON_MAP_TEXTURE_PATH, info.file))
	-- The image is anchored to the top left corner of a texture with power of 2 dimensions
	texture:SetTexCoord(0, info.width / info.textureWidth, 0, info.height / info.textureHeight)
	texture:Show()
end

local function HideDungeonMap(mapFrame)
	mapFrame.iconArea = nil
	if (mapFrame.DungeonBackground) then
		mapFrame.DungeonBackground:Hide()
		mapFrame.DungeonMap:Hide()
	end
end

local function InitMapPools(mapFrame)
	if (not mapFrame.detailLayerPool) then
		mapFrame.detailLayerPool = CreateFramePool("FRAME", mapFrame, "RSMapCanvasDetailLayerTemplate");
		mapFrame.iconsPool = CreateFramePool("FRAME", mapFrame, "RSMapCanvasDetailIconsTemplate");
		mapFrame.overlayIconsPool = CreateFramePool("FRAME", mapFrame, "RSMapCanvasDetailIconsTemplate");
	end
end

--- The dungeons don't have a map in the game, so their map is the composition of the minimap of the dungeon
--- (generated with the textures) centered over a blank parchment
local function RSExplorerLoadDungeonMap(mapID, mapFrame)
	InitMapPools(mapFrame)
	mapFrame.detailLayerPool:ReleaseAll()
	mapFrame.mapID = mapID
	mapFrame.mapArtID = nil

	if (not mapFrame.DungeonBackground) then
		mapFrame.DungeonBackground = mapFrame:CreateTexture(nil, "BACKGROUND")
		mapFrame.DungeonBackground:SetAllPoints(mapFrame)
		mapFrame.DungeonMap = mapFrame:CreateTexture(nil, "BORDER")
		mapFrame.DungeonMap:SetPoint("CENTER", mapFrame, "CENTER")
	end
	SetDungeonMapTexture(mapFrame.DungeonBackground, private.DUNGEON_MAPS_BACKGROUND)

	local dungeonMap = private.DUNGEON_MAPS[mapID]
	if (not dungeonMap) then
		mapFrame.DungeonMap:Hide()
		mapFrame.iconArea = nil
		return
	end

	-- Fits inside the parchment keeping its proportions
	local maxWidth = mapFrame:GetWidth() * RSConstants.DUNGEON_MAP_MAX_SIZE
	local maxHeight = mapFrame:GetHeight() * RSConstants.DUNGEON_MAP_MAX_SIZE
	local scale = math.min(maxWidth / dungeonMap.width, maxHeight / dungeonMap.height, RSConstants.DUNGEON_MAP_MAX_SCALE)
	local width = dungeonMap.width * scale
	local height = dungeonMap.height * scale
	mapFrame.DungeonMap:SetSize(width, height)
	SetDungeonMapTexture(mapFrame.DungeonMap, dungeonMap)

	-- The coordinates of the entities in the dungeons are relative to the dungeon map
	mapFrame.iconArea = { left = (mapFrame:GetWidth() - width) / 2, top = (mapFrame:GetHeight() - height) / 2, width = width, height = height }
end

local function RSExplorerLoadMap(mapID, mapFrame)
	if (private.DUNGEONS_IDS[mapID]) then
		RSExplorerLoadDungeonMap(mapID, mapFrame)
		return
	end
	HideDungeonMap(mapFrame)

	-- Avoid refreshing only if the map art & map did not change
    local mapArtID = C_Map.GetMapArtID(mapID)
    if (mapFrame.mapID and mapFrame.mapID == mapID and mapFrame.mapArtID == mapArtID) then
        return
    end

    mapFrame.mapID = mapID
    mapFrame.mapArtID = mapArtID
	
	-- Initialize variables
	InitMapPools(mapFrame)

	-- Load map frame
	mapFrame.detailLayerPool:ReleaseAll();
	
	local layers = C_Map.GetMapArtLayers(mapID);	
	for layerIndex, layerInfo in ipairs(layers) do
		local detailLayer = mapFrame.detailLayerPool:Acquire();
		detailLayer:SetAllPoints(mapFrame);
		detailLayer:SetMapAndLayer(mapID, layerIndex, mapFrame);
		detailLayer:Show();
	end
end

local function AddIcon(icon, texture, x, y, r, g, b)
	if (not x or not y) then
		return
	end
	
	icon.Texture:SetTexture(texture)
	if (r and g and b) then
		icon.Texture:SetVertexColor(r, g, b, 0.4)
		icon.Texture:SetDrawLayer("ARTWORK");
	else
		icon.Texture:SetDrawLayer("OVERLAY");
	end
	
	-- In the dungeons the coordinates are relative to the dungeon map, centered inside the frame
	local area = icon:GetParent().iconArea
	local left = area and area.left or 0
	local top = area and area.top or 0
	local width = area and area.width or icon:GetParent():GetWidth()
	local height = area and area.height or icon:GetParent():GetHeight()

	local xOffset = 0
	local yOffset = 0
	if (x > 1) then
		xOffset = ((x / 100) * width) / 100
		yOffset = ((y / 100) * height) / 100
	else
		xOffset = x * width
		yOffset = y * height
	end

	icon:SetPoint("CENTER", icon:GetParent(), "TOPLEFT", left + xOffset, -(top + yOffset))
	icon:Show()
end

-- Information of the entity in the map, or in the subzone of the map where it is (if it has only one zone)
local function GetEntityInfoInMap(isNpc, entityID, mapID)
	if (isNpc) then
		return RSNpcDB.GetInternalNpcInfoByMapID(entityID, mapID) or (RSNpcDB.IsInternalNpcMonoZone(entityID) and RSNpcDB.GetInternalNpcInfo(entityID)) or nil
	end

	return RSContainerDB.GetInternalContainerInfoByMapID(entityID, mapID) or (RSContainerDB.IsInternalContainerMonoZone(entityID) and RSContainerDB.GetInternalContainerInfo(entityID)) or nil
end

function RSExplorerRareList:OnElementSelectionChanged(elementData, selected)
    local element = self.scrollView:FindFrame(elementData);
    
    if (not element) then
    	return
    end
    
    -- Avoid refreshing UI for deselected elements
    if (not selected) then
    	element.Selected:Hide()
    	return
    else
   		element.Selected:Show()
   	end
    
    local mainFrame = self:GetParent()	
	local internalInfo = GetEntityInfoInMap(elementData.isNpc, elementData.entityID, self.mapID)
	if (not internalInfo) then
		return
	end

	-- The map where the entity is, that can be a subzone of the selected one
	local entityMapID = type(internalInfo.zoneID) == "number" and internalInfo.zoneID or self.mapID

	-- Name
	mainFrame.RareInfo.Name:SetText(elementData.name)

	-- Map
	local mapFrame = mainFrame.RareInfo.Map
	RSExplorerLoadMap(entityMapID, mapFrame)
	
	-- Icons / Spawning points
	mapFrame.overlayIconsPool:ReleaseAll()
	if (internalInfo.overlay) then
		local r, g, b = RSConfigDB.GetWorldMapOverlayColour(1)
		
		for _, coordinates in ipairs (internalInfo.overlay) do
			local x, y = strsplit("-", coordinates)
			local overlayIcon = mapFrame.overlayIconsPool:Acquire();
			AddIcon(overlayIcon, RSConstants.OVERLAY_SPOT_TEXTURE, tonumber(x), tonumber(y), r, g, b)
		end
	end
		
	-- Icons / Skull
	mapFrame.iconsPool:ReleaseAll()
	local entityPOI
	if (elementData.isNpc) then
		entityPOI = RSNpcPOI.GetNpcPOI(elementData.entityID, entityMapID, internalInfo,RSGeneralDB.GetAlreadyFoundEntity(elementData.entityID, RSConstants.NPC_VIGNETTE))
	else
		entityPOI = RSContainerPOI.GetContainerPOI(elementData.entityID, entityMapID, internalInfo,RSGeneralDB.GetAlreadyFoundEntity(elementData.entityID, RSConstants.CONTAINER_VIGNETTE))
	end
	
	if (entityPOI) then
		local mainIcon = mapFrame.iconsPool:Acquire();
		AddIcon(mainIcon, entityPOI.Texture, tonumber(internalInfo.x), tonumber(internalInfo.y))
	
		-- Achievement
		if (RSUtils.GetTableLength(entityPOI.achievementIDs) > 0) then
			for _, achievementID in ipairs(entityPOI.achievementIDs) do
				mainFrame.RareInfo.AchievementIcon.achievementLink = RSAchievementDB.GetCachedAchievementLink(achievementID)
				mainFrame.RareInfo.AchievementIcon:Show()
				break
			end
		else
			mainFrame.RareInfo.AchievementIcon:Hide()
		end
	else
		mainFrame.RareInfo.AchievementIcon:Hide()
	end
	
	-- Loot
	mainFrame.lootItemsPool:ReleaseAll();
	self:AddItems(elementData, mainFrame.RareInfo.Mounts, RSConstants.ITEM_TYPE.MOUNT)
	self:AddItems(elementData, mainFrame.RareInfo.Pets, RSConstants.ITEM_TYPE.PET)
	self:AddItems(elementData, mainFrame.RareInfo.Toys, RSConstants.ITEM_TYPE.TOY)
	self:AddItems(elementData, mainFrame.RareInfo.Appearances, RSConstants.ITEM_TYPE.APPEARANCE)
	self:AddItems(elementData, mainFrame.RareInfo.Decor, RSConstants.ITEM_TYPE.DECOR)
	
	-- Loot list with drop chances
	mainFrame.RareLoot:Refresh(elementData)

	-- Refresh internal loot grid
	mainFrame.RareInfo.Custom.grid = nil
	
	-- With custom items take into account only if not filtered
	local customGroupKeys = {}
	for groupKey, _ in pairs(RSCollectionsDB.GetItemGroups()) do
		if (RSConfigDB.IsSearchingCustom(groupKey)) then
			tinsert(customGroupKeys, string.format(RSConstants.ITEM_TYPE.CUSTOM, groupKey))
		end
	end
	
	for _, customGroupKey in ipairs(customGroupKeys) do
		self:AddItems(elementData, mainFrame.RareInfo.Custom, customGroupKey, customGroupKeys)
	end
end

function RSExplorerRareList:AddEntityToDataProvider(entityID, entityInfo, entityName, source)
	-- Ignoring the collectibles every entity is shown
	if (filters[RSConstants.EXPLORER_FILTER_IGNORE_COLLECTIBLES]) then
		self:AddToDataProvider(entityID, entityInfo, entityName, source)
		return
	end

	local collectionsLoot = RSCollectionsDB.GetAllEntitiesCollectionsLoot()[source]
	local alreadyAdded = false
	
	if (not alreadyAdded and filters[RSConstants.EXPLORER_FILTER_DROP_MOUNTS] and collectionsLoot and collectionsLoot[entityID] and RSUtils.GetTableLength(collectionsLoot[entityID][RSConstants.ITEM_TYPE.MOUNT]) > 0) then
		self:AddToDataProvider(entityID, entityInfo, entityName, source)
		alreadyAdded = true
	end
		
	if (not alreadyAdded and filters[RSConstants.EXPLORER_FILTER_DROP_PETS] and collectionsLoot and collectionsLoot[entityID] and RSUtils.GetTableLength(collectionsLoot[entityID][RSConstants.ITEM_TYPE.PET]) > 0) then
		self:AddToDataProvider(entityID, entityInfo, entityName, source)
		alreadyAdded = true
	end
				
	if (not alreadyAdded and filters[RSConstants.EXPLORER_FILTER_DROP_TOYS] and collectionsLoot and collectionsLoot[entityID] and RSUtils.GetTableLength(collectionsLoot[entityID][RSConstants.ITEM_TYPE.TOY]) > 0) then
		self:AddToDataProvider(entityID, entityInfo, entityName, source)
		alreadyAdded = true
	end
				
	if (not alreadyAdded and filters[RSConstants.EXPLORER_FILTER_DROP_APPEARANCES] and collectionsLoot and collectionsLoot[entityID] and RSUtils.GetTableLength(collectionsLoot[entityID][RSConstants.ITEM_TYPE.APPEARANCE]) > 0) then
		if (filters[RSConstants.EXPLORER_FILTER_DROP_CLASS_APPEARANCES]) then
			for _, itemID in pairs(collectionsLoot[entityID][RSConstants.ITEM_TYPE.APPEARANCE]) do
				if (RSCollectionsDB.IsNotCollectedClassAppearance(itemID)) then
					self:AddToDataProvider(entityID, entityInfo, entityName, source)
					alreadyAdded = true
					break
				end
			end
		else
			self:AddToDataProvider(entityID, entityInfo, entityName, source)
			alreadyAdded = true
		end
	end
				
	if (not alreadyAdded) then
		for groupKey, _ in pairs(RSCollectionsDB.GetItemGroups()) do	
			if (filters[string.format(RSConstants.EXPLORER_FILTER_DROP_CUSTOM, groupKey)] and collectionsLoot and collectionsLoot[entityID] and RSUtils.GetTableLength(collectionsLoot[entityID][string.format(RSConstants.ITEM_TYPE.CUSTOM, groupKey)]) > 0) then
				self:AddToDataProvider(entityID, entityInfo, entityName, source)
				alreadyAdded = true
			end
		end
	end
				
	if (not alreadyAdded and filters[RSConstants.EXPLORER_FILTER_WITHOUT_COLLECTIBLES]) then
		if (not collectionsLoot or not collectionsLoot[entityID]) then
			self:AddToDataProvider(entityID, entityInfo, entityName, source)
			alreadyAdded = true
		elseif (filters[RSConstants.EXPLORER_FILTER_DROP_CLASS_APPEARANCES] and collectionsLoot and collectionsLoot[entityID] and RSUtils.GetTableLength(collectionsLoot[entityID][RSConstants.ITEM_TYPE.APPEARANCE]) > 0) then
			for _, itemID in pairs(collectionsLoot[entityID][RSConstants.ITEM_TYPE.APPEARANCE]) do
				if (not RSCollectionsDB.IsNotCollectedClassAppearance(itemID)) then
					self:AddToDataProvider(entityID, entityInfo, entityName, source)
					alreadyAdded = true
					break
				end
			end
		end
	end
end

function RSExplorerRareList:AddToDataProvider(entityID, entityInfo, entityName, itemSource)
	local elementData = {}
	elementData.entityID = entityID
	elementData.mapID = entityInfo.zoneID
	elementData.name = entityName and entityName or entityID
	
	if (itemSource == RSConstants.ITEM_SOURCE.NPC) then
		elementData.displayID = entityInfo.displayID
		elementData.filtered = RSConfigDB.GetNpcFiltered(entityID) ~= nil
		elementData.dead = RSNpcDB.IsNpcKilled(entityID)
		elementData.custom = entityInfo.custom
		elementData.isNpc = true
		elementData.level = RSNpcDB.GetNpcLevel(entityID)
	else
		elementData.filtered = RSConfigDB.GetContainerFiltered(entityID) ~= nil
		elementData.dead = RSContainerDB.IsContainerOpened(entityID)
		elementData.custom = false
		elementData.isContainer = true
	end
	
	-- add extra information
	local collectionsLoot = RSCollectionsDB.GetAllEntitiesCollectionsLoot()
	if (collectionsLoot[itemSource] and collectionsLoot[itemSource][entityID]) then
		if (RSUtils.GetTableLength(collectionsLoot[itemSource][entityID][RSConstants.ITEM_TYPE.MOUNT]) > 0) then
			elementData.hasMissingMount = true
		else
			elementData.hasMissingMount = false
		end
		if (RSUtils.GetTableLength(collectionsLoot[itemSource][entityID][RSConstants.ITEM_TYPE.PET]) > 0) then
			elementData.hasMissingPet = true
		else
			elementData.hasMissingPet = false
		end
		if (RSUtils.GetTableLength(collectionsLoot[itemSource][entityID][RSConstants.ITEM_TYPE.TOY]) > 0) then
			elementData.hasMissingToy = true
		else
			elementData.hasMissingToy = false
		end
		if (RSUtils.GetTableLength(collectionsLoot[itemSource][entityID][RSConstants.ITEM_TYPE.APPEARANCE]) > 0) then
			if (RSConfigDB.IsSearchingClassAppearances()) then
				local found = false
				for _, itemID in pairs(collectionsLoot[itemSource][entityID][RSConstants.ITEM_TYPE.APPEARANCE]) do
					if (RSCollectionsDB.IsNotCollectedClassAppearance(itemID)) then
						found = true
						break
					end
				end
				
				if (found) then
					elementData.hasMissingAppearance = true
				end
			else
				elementData.hasMissingAppearance = true
			end
		else
			elementData.hasMissingAppearance = false
		end
		if (RSUtils.GetTableLength(collectionsLoot[itemSource][entityID][RSConstants.ITEM_TYPE.DECOR]) > 0) then
			elementData.hasMissingDecor = true
		else
			elementData.hasMissingDecor = false
		end
		
		-- for custom items we show the texture only if they user is not filtering for an specific group
		for groupKey, _ in pairs(RSCollectionsDB.GetItemGroups()) do	
			if (RSUtils.GetTableLength(collectionsLoot[itemSource][entityID][string.format(RSConstants.ITEM_TYPE.CUSTOM, groupKey)]) > 0 and RSConfigDB.IsSearchingCustom(groupKey)) then
				elementData.hasMissingCustom = true
				break
			else
				elementData.hasMissingCustom = false
			end
		end
	end
	
	self.dataProvider:Insert(elementData);
end

function RSExplorerRareList:RefreshDataProvider()
	-- Deletes everything in the dataprovider
	self.dataProvider:Flush()

	self.mapID = RSConfigDB.GetExplorerMapID()
	
	-- Load rare NPC list
	for npcID, npcName in pairs(RSNpcDB.GetAllNpcNames()) do
		if (filters[RSConstants.EXPLORER_FILTER_TYPE_NPC] and RSNpcDB.IsInternalNpcInMap(npcID, self.mapID, true, true)) then
			-- A NPC of one zone in a subzone of the selected map is not found by mapID
			local npcInfo = GetEntityInfoInMap(true, npcID, self.mapID)
			
			if (npcInfo and npcInfo.displayID) then
				local filtered = false
				-- Ignore if dead
				if (not filters[RSConstants.EXPLORER_FILTER_DEAD] and RSNpcDB.IsNpcKilled(npcID)) then
					filtered = true
				end
				
				-- Ignore if filtered
				if (not filtered and not filters[RSConstants.EXPLORER_FILTER_FILTERED] and RSConfigDB.GetNpcFiltered(npcID) ~= nil) then
					filtered = true
				end
			
				if (not filtered) then
					self:AddEntityToDataProvider(npcID, npcInfo, npcName, RSConstants.ITEM_SOURCE.NPC)
				end
			else
				RSLogger:PrintDebugMessage(string.format("RSExplorerRareList:RefreshDataProvider: [npcID=%s]. Saltado por no tener informacion o displayID", npcID))
			end
		end
	end
	
	-- Load container list
	for containerID, _ in pairs(RSContainerDB.GetAllInternalContainerInfo()) do
		if (filters[RSConstants.EXPLORER_FILTER_TYPE_CONTAINER] and RSContainerDB.IsInternalContainerInMap(containerID, self.mapID, true, true)) then
			local containerInfo = GetEntityInfoInMap(false, containerID, self.mapID)
			
			if (containerInfo) then
				local filtered = false
				-- Ignore if opened
				if (not filters[RSConstants.EXPLORER_FILTER_DEAD] and RSContainerDB.IsContainerOpened(containerID)) then
					filtered = true
				end
				
				-- Ignore if filtered
				if (not filtered and not filters[RSConstants.EXPLORER_FILTER_FILTERED] and RSConfigDB.GetContainerFiltered(containerID) ~= nil) then
					filtered = true
				end
			
				if (not filtered) then
					self:AddEntityToDataProvider(containerID, containerInfo, RSContainerDB.GetContainerName(containerID), RSConstants.ITEM_SOURCE.CONTAINER)
				end
			else
				RSLogger:PrintDebugMessage(string.format("RSExplorerRareList:RefreshDataProvider: [containerID=%s]. Saltado por no tener informacion", containerID))
			end
		end
	end
	
	-- Autoselects the first element
	self.selectionBehavior:SelectFirstElementData()
end

function RSExplorerRareList:AddItems(elementData, parentFrame, itemType, customGroupKeys)
	local mainFrame = self:GetParent()
	
	local collectionsLoot
	if (elementData.isNpc) then
		collectionsLoot = RSCollectionsDB.GetAllEntitiesCollectionsLoot()[RSConstants.ITEM_SOURCE.NPC]
	else
		collectionsLoot = RSCollectionsDB.GetAllEntitiesCollectionsLoot()[RSConstants.ITEM_SOURCE.CONTAINER]
	end
	
	if (collectionsLoot and collectionsLoot[elementData.entityID]) then
		local itemIDs = collectionsLoot[elementData.entityID][itemType]
		
	    if (RSUtils.GetTableLength(itemIDs) > 0) then
			local xOffset = 0
			local yOffset = -8
			local numColumn = 0
			local numRow = 0
			local maxLines = 1
			local maxItemsPerRow
    		if (itemType ~= RSConstants.ITEM_TYPE.APPEARANCE and not RSUtils.Contains(customGroupKeys, itemType)) then
    			maxItemsPerRow = 3
 			else
 				maxLines = 4
    			maxItemsPerRow = 7
 			end
 			
	    	-- Custom settings reuse grid properties
	    	if (RSUtils.Contains(customGroupKeys, itemType) and mainFrame.RareInfo.Custom.grid) then
	    		xOffset, yOffset, numRow, numColumn, maxItemsPerRow = unpack(mainFrame.RareInfo.Custom.grid)
	    	end
   
	    	for _, itemID in ipairs(itemIDs) do
	    		-- If appearance only add if not filtering by class
	    		if (itemType ~= RSConstants.ITEM_TYPE.APPEARANCE or not RSConfigDB.IsSearchingClassAppearances() or RSCollectionsDB.IsNotCollectedClassAppearance(itemID)) then
		    		local _, _, _, _, icon, _, _ = C_Item.GetItemInfoInstant(itemID)
		    		local lootItem = mainFrame.lootItemsPool:Acquire();
		    		
		    		if (math.fmod(numColumn, maxItemsPerRow) == 0) then
		    			xOffset = xOffset + 10
		    		else
		    			xOffset = xOffset + lootItem:GetWidth() + 2
		    		end
		    		
		    		lootItem.itemID = itemID
		    		lootItem.Icon:SetTexture(icon)
		    		lootItem.isMount = itemType == RSConstants.ITEM_TYPE.MOUNT
		    		lootItem.isPet = itemType == RSConstants.ITEM_TYPE.PET
		    		lootItem.istoy = itemType == RSConstants.ITEM_TYPE.TOY
		    		lootItem.isAppearance = itemType == RSConstants.ITEM_TYPE.APPEARANCE
		    		lootItem.isDecor = itemType == RSConstants.ITEM_TYPE.DECOR
		    		lootItem.isCustom = RSUtils.Contains(customGroupKeys, itemType)
		    		
		    		lootItem:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", xOffset, yOffset)
		    		lootItem:Show()
		    		
		    		numColumn = numColumn + 1
		    		
		    		if (math.fmod(numColumn, maxItemsPerRow) == 0) then
	    				numRow = numRow + 1
	    				if (numRow == maxLines) then	
	    					break
	    				end
	    				
	    				xOffset = 0
	    				numColumn = 0
	    				if (numRow > 1 and not lootItem.isAppearance and not lootItem.isCustom) then			
			    			break
			    		else	
			    			maxItemsPerRow = 8
			    			yOffset = yOffset - lootItem:GetHeight() - 2 
			    		end
	    			end
	    		end
	    	end
 			
	    	-- Custom settings save current grid properties
	    	if (RSUtils.Contains(customGroupKeys, itemType)) then
	    		mainFrame.RareInfo.Custom.grid = { xOffset, yOffset, numRow, numColumn, maxItemsPerRow }
	    	end
		end
	end
end

-----------------------------------------------------
-- Rare loot
-----------------------------------------------------

function RSExplorerRareInfoLootItem_OnEnter(self)
	local mainFrame = self:GetParent():GetParent()
	local tooltip = mainFrame.Tooltip
	local itemIcon = self
	local item = Item:CreateFromItemID(self.itemID)
	item:ContinueOnItemLoad(function()
		tooltip:SetOwner(itemIcon, "BOTTOM_LEFT")
		tooltip:SetHyperlink(item:GetItemLink())
		
		-- Adds extra information
		RSLootTooltip.AddRareScannerInformation(tooltip, item:GetItemLink(), self.itemID)

		tooltip:Show()
	end)
end

function RSExplorerRareInfoLootItem_OnLeave(self)
	local mainFrame = self:GetParent():GetParent()
	local tooltip = mainFrame.Tooltip
	tooltip:Hide()
end

function RSExplorerRareInfoAchievement_OnEnter(self)
	local mainFrame = self:GetParent():GetParent()
	local tooltip = mainFrame.Tooltip
	tooltip:SetOwner(self, "BOTTOM_LEFT")
	tooltip:SetHyperlink(self.achievementLink)
	tooltip:Show()
end

function RSExplorerRareInfoAchievement_OnLeave(self)
	local mainFrame = self:GetParent():GetParent()
	local tooltip = mainFrame.Tooltip
	tooltip:Hide()
end

function RSExplorerRareInfoLootItem_OnClick(self, button)
	local itemIcon = self
	local item = Item:CreateFromItemID(self.itemID)
	item:ContinueOnItemLoad(function()
		if (IsControlKeyDown()) then
			if (itemIcon.isMount) then
				DressUpMountLink(item:GetItemLink())
			elseif (itemIcon.isPet) then
				DressUpBattlePetLink(item:GetItemLink())
			elseif (itemIcon.isAppearance or itemIcon.isDecor) then
				DressUpItemLink(item:GetItemLink())
			end
		elseif (IsShiftKeyDown()) then
			ChatEdit_LinkItem(self.itemID, item:GetItemLink())
		end
	end)
end

-----------------------------------------------------
-- Rare loot list (with drop chances)
-----------------------------------------------------

RSExplorerRareLoot = { };

local function RSExplorerRareLoot_Sort(e1, e2)
	-- Order by quality
	if (e1.quality ~= e2.quality) then
		return e1.quality > e2.quality
	end

	-- Then by drop chance
	if (e1.chance ~= e2.chance) then
		return e1.chance > e2.chance
	end

	-- Otherwise by name
	return strcmputf8i(e1.name, e2.name) < 0
end

function RSExplorerRareLoot:IsItemShown(item)
	if (RSConfigDB.IsExplorerLootQualityHidden(item.quality)) then
		return false
	end

	-- Equipment that doesn't improve what the player wears
	if (RSConfigDB.IsExplorerLootHideNonUpgrades() and item.isGear and not item.upgrade) then
		return false
	end

	if (RSConfigDB.IsExplorerLootOnlyEquipable() and not item.isEquipable) then
		return false
	end

	if (RSConfigDB.IsExplorerLootOnlyUsable() and not item.isUsable) then
		return false
	end

	if (RSConfigDB.IsExplorerLootOnlyMyLevel() and not item.isMyLevel) then
		return false
	end

	if (not RSConfigDB.IsExplorerLootShowFiltered() and RSConfigDB.GetItemFiltered(item.itemID)) then
		return false
	end

	-- Drop chance range
	local minChance = RSConfigDB.GetExplorerLootMinChance()
	if (minChance and item.chance < minChance) then
		return false
	end

	local maxChance = RSConfigDB.GetExplorerLootMaxChance()
	if (maxChance and item.chance > maxChance) then
		return false
	end

	if (self.searchText ~= "" and not strfind(strlower(item.name), self.searchText, 1, true)) then
		return false
	end

	return not RSConfigDB.IsExplorerLootCategoryHidden(item.classID .. "-" .. item.subClassID)
end

function RSExplorerRareLoot:ApplyFilters()
	self.dataProvider:Flush()

	local shownItems = {}
	for _, item in ipairs(self.items) do
		if (self:IsItemShown(item)) then
			tinsert(shownItems, item)
		end
	end

	self.dataProvider:InsertTable(shownItems)
	self:UpdateFilterAllCheck()
end

-- The header check is marked when every item shown in the list is filtered individually
function RSExplorerRareLoot:UpdateFilterAllCheck()
	local allFiltered = false
	for _, item in self.dataProvider:Enumerate() do
		if (not RSConfigDB.GetItemFiltered(item.itemID)) then
			allFiltered = false
			break
		end
		allFiltered = true
	end

	self.FilterAllCheck:SetChecked(allFiltered)
end

-- Filters (or unfilters) individually all the items shown in the list
function RSExplorerRareLoot:SetAllShownItemsFiltered(filtered)
	for _, item in self.dataProvider:Enumerate() do
		RSConfigDB.SetItemFiltered(item.itemID, filtered)
	end

	if (filtered and not RSConfigDB.IsExplorerLootShowFiltered()) then
		self:ApplyFilters()
	else
		-- Nothing is added or removed, so the list keeps its scroll
		self.scrollBox:ForEachFrame(function(element)
			element.FilterCheck:SetChecked(filtered)
		end)
		self:UpdateFilterAllCheck()
	end
end

function RSExplorerRareLoot:SetupFilterMenu(rootDescription)
	-- Quality
	local qualitySubmenu = rootDescription:CreateButton(AL["EXPLORER_LOOT_FILTER_QUALITY"])
	for quality = Enum.ItemQuality.Poor, Enum.ItemQuality.Heirloom do
		local name = ITEM_QUALITY_COLORS[quality].color:WrapTextInColorCode(private.ITEM_QUALITY[quality])
		local qualityFilter = qualitySubmenu:CreateCheckbox(name,
			function() return not RSConfigDB.IsExplorerLootQualityHidden(quality) end,
			function()
				-- Overriden by SetResponder
			end)
		qualityFilter:SetResponder(function()
			RSConfigDB.SetExplorerLootQualityHidden(quality, not RSConfigDB.IsExplorerLootQualityHidden(quality))
			self:ApplyFilters()
			return MenuResponse.Refresh;
		end)
	end

	-- Category / subcategory
	local categorySubmenu = rootDescription:CreateButton(AL["EXPLORER_LOOT_FILTER_CATEGORY"])
	local classIDs = {}
	for classID, _ in pairs(private.ITEM_CLASSES) do
		tinsert(classIDs, classID)
	end
	sort(classIDs)

	for _, classID in ipairs(classIDs) do
		local subClassKeys = {}
		for _, subClassID in ipairs(private.ITEM_CLASSES[classID]) do
			if (C_Item.GetItemSubClassInfo(classID, subClassID)) then
				tinsert(subClassKeys, classID .. "-" .. subClassID)
			end
		end

		-- The main category selects/unselects all its subcategories
		local classFilter = categorySubmenu:CreateCheckbox(C_Item.GetItemClassInfo(classID),
			function()
				for _, key in ipairs(subClassKeys) do
					if (RSConfigDB.IsExplorerLootCategoryHidden(key)) then
						return false
					end
				end
				return true
			end,
			function()
				-- Overriden by SetResponder
			end)
		classFilter:SetResponder(function()
			local anyHidden = false
			for _, key in ipairs(subClassKeys) do
				anyHidden = anyHidden or RSConfigDB.IsExplorerLootCategoryHidden(key)
			end

			for _, key in ipairs(subClassKeys) do
				RSConfigDB.SetExplorerLootCategoryHidden(key, not anyHidden)
			end
			self:ApplyFilters()
			return MenuResponse.Refresh;
		end)

		for _, subClassID in ipairs(private.ITEM_CLASSES[classID]) do
			local subClassName = C_Item.GetItemSubClassInfo(classID, subClassID)
			if (subClassName) then
				local key = classID .. "-" .. subClassID
				local subClassFilter = classFilter:CreateCheckbox(subClassName,
					function() return not RSConfigDB.IsExplorerLootCategoryHidden(key) end,
					function()
						-- Overriden by SetResponder
					end)
				subClassFilter:SetResponder(function()
					RSConfigDB.SetExplorerLootCategoryHidden(key, not RSConfigDB.IsExplorerLootCategoryHidden(key))
					self:ApplyFilters()
					return MenuResponse.Refresh;
				end)
			end
		end
	end

	-- Lower item level
	local lowerIlvlFilter = rootDescription:CreateCheckbox(AL["EXPLORER_LOOT_FILTER_LOWER_ILVL"],
		function() return RSConfigDB.IsExplorerLootHideNonUpgrades() end,
		function()
			-- Overriden by SetResponder
		end)
	lowerIlvlFilter:SetResponder(function()
		RSConfigDB.SetExplorerLootHideNonUpgrades(not RSConfigDB.IsExplorerLootHideNonUpgrades())
		self:ApplyFilters()
		return MenuResponse.Refresh;
	end)

	-- Is equipable
	local equipableFilter = rootDescription:CreateCheckbox(AL["EXPLORER_LOOT_FILTER_EQUIPABLE"],
		function() return RSConfigDB.IsExplorerLootOnlyEquipable() end,
		function()
			-- Overriden by SetResponder
		end)
	equipableFilter:SetResponder(function()
		RSConfigDB.SetExplorerLootOnlyEquipable(not RSConfigDB.IsExplorerLootOnlyEquipable())
		self:ApplyFilters()
		return MenuResponse.Refresh;
	end)

	-- Is usable
	local usableFilter = rootDescription:CreateCheckbox(AL["EXPLORER_LOOT_FILTER_USABLE"],
		function() return RSConfigDB.IsExplorerLootOnlyUsable() end,
		function()
			-- Overriden by SetResponder
		end)
	usableFilter:SetResponder(function()
		RSConfigDB.SetExplorerLootOnlyUsable(not RSConfigDB.IsExplorerLootOnlyUsable())
		self:ApplyFilters()
		return MenuResponse.Refresh;
	end)

	-- Is my level
	local myLevelFilter = rootDescription:CreateCheckbox(AL["EXPLORER_LOOT_FILTER_MY_LEVEL"],
		function() return RSConfigDB.IsExplorerLootOnlyMyLevel() end,
		function()
			-- Overriden by SetResponder
		end)
	myLevelFilter:SetResponder(function()
		RSConfigDB.SetExplorerLootOnlyMyLevel(not RSConfigDB.IsExplorerLootOnlyMyLevel())
		self:ApplyFilters()
		return MenuResponse.Refresh;
	end)

	-- Show filtered items
	local showFilteredFilter = rootDescription:CreateCheckbox(AL["EXPLORER_LOOT_FILTER_SHOW_FILTERED"],
		function() return RSConfigDB.IsExplorerLootShowFiltered() end,
		function()
			-- Overriden by SetResponder
		end)
	showFilteredFilter:SetResponder(function()
		RSConfigDB.SetExplorerLootShowFiltered(not RSConfigDB.IsExplorerLootShowFiltered())
		self:ApplyFilters()
		return MenuResponse.Refresh;
	end)

	-- Drop chance range
	local function AddChanceBox(label, getter, setter)
		local row = rootDescription:CreateTemplate("RSExplorerLootChanceFilterTemplate")
		row:AddInitializer(function(frame)
			frame.Label:SetText(label)
			local value = getter()
			frame.Value:SetText(value and tostring(value) or "")
			frame.Value:SetScript("OnTextChanged", function(editBox, userInput)
				if (userInput) then
					-- Only digits and one decimal separator (dot or comma) are allowed
					local text = editBox:GetText()
					local clean = text:gsub("[^%d%.,]", "")
					local separatorPos = clean:find("[%.,]")
					if (separatorPos) then
						clean = clean:sub(1, separatorPos) .. clean:sub(separatorPos + 1):gsub("[%.,]", "")
					end
					if (clean ~= text) then
						local cursor = editBox:GetCursorPosition()
						editBox:SetText(clean)
						editBox:SetCursorPosition(math.max(0, cursor - (#text - #clean)))
					end

					-- Empty or invalid text means no limit
					local number = tonumber((editBox:GetText():gsub(",", ".")))
					setter(number and math.max(0, math.min(100, number)) or nil)
					self:ApplyFilters()
				end
			end)
			frame.Value:SetScript("OnEnterPressed", function(editBox)
				editBox:ClearFocus()
			end)
		end)
	end

	AddChanceBox(AL["EXPLORER_LOOT_FILTER_CHANCE_MIN"], RSConfigDB.GetExplorerLootMinChance, RSConfigDB.SetExplorerLootMinChance)
	AddChanceBox(AL["EXPLORER_LOOT_FILTER_CHANCE_MAX"], RSConfigDB.GetExplorerLootMaxChance, RSConfigDB.SetExplorerLootMaxChance)
end

function RSExplorerRareLoot:Initialize(mainFrame)
	self.mainFrame = mainFrame
	self.scrollView = CreateScrollBoxListLinearView();
	self.scrollView:SetElementInitializer("RSExplorerLootListButtonTemplate", GenerateClosure(self.OnElementInitialize, self));
	ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.scrollView);

	self.dataProvider = CreateDataProvider()
	self.dataProvider:SetSortComparator(RSExplorerRareLoot_Sort)
	self.scrollBox:SetDataProvider(self.dataProvider);
	self.items = {}
	self.searchText = ""
	self.SearchBox:HookScript("OnTextChanged", function(searchBox)
		self.searchText = strlower(strtrim(searchBox:GetText()))
		self:ApplyFilters()
	end)
	self.FilterAllCheck.tooltip = AL["EXPLORER_LOOT_FILTER_ALL_DESC"]
	self.FilterAllCheck:SetScript("OnEnter", function(check)
		self.mainFrame:ShowTooltip(check)
	end)
	self.FilterAllCheck:SetScript("OnLeave", function(check)
		self.mainFrame:HideTooltip(check)
	end)
	self.FilterAllCheck:SetScript("OnClick", function(check)
		self:SetAllShownItemsFiltered(check:GetChecked())
	end)
	self.FilterDropDown:SetText(AL["EXPLORER_FILTERS"])
	self.FilterDropDown:SetupMenu(function(dropDown, rootDescription)
		self:SetupFilterMenu(rootDescription)
	end)
end

-- Tooltips used to compare items with the equipped ones
local function EnsureCompareTooltips(tooltip)
	if (not tooltip.shoppingTooltips) then
		local compare1 = CreateFrame("GameTooltip", "RSExplorerCompareTooltip1", tooltip, "ShoppingTooltipTemplate")
		local compare2 = CreateFrame("GameTooltip", "RSExplorerCompareTooltip2", tooltip, "ShoppingTooltipTemplate")
		compare1:SetFrameStrata(tooltip:GetFrameStrata())
		compare2:SetFrameStrata(tooltip:GetFrameStrata())
		compare1:SetFrameLevel(tooltip:GetFrameLevel())
		compare2:SetFrameLevel(tooltip:GetFrameLevel())
		tooltip.shoppingTooltips = { compare1, compare2 }
	end
end

function RSExplorerRareLoot:OnElementInitialize(element, elementData)
	local _, _, _, _, icon = C_Item.GetItemInfoInstant(elementData.itemID)
	element.Icon:SetTexture(icon)
	element.Name:SetText(ITEM_QUALITY_COLORS[elementData.quality].color:WrapTextInColorCode(elementData.name))
	element.Upgrade:SetShown(elementData.upgrade)

	-- Individual filter (the same used by the world map tooltips)
	local filterCheck = element.FilterCheck
	filterCheck.tooltip = AL["EXPLORER_LOOT_FILTER_ITEM_DESC"]
	filterCheck:SetChecked(RSConfigDB.GetItemFiltered(elementData.itemID))
	filterCheck:SetScript("OnEnter", function(check)
		self.mainFrame:ShowTooltip(check)
	end)
	filterCheck:SetScript("OnLeave", function(check)
		self.mainFrame:HideTooltip(check)
	end)
	filterCheck:SetScript("OnClick", function(check)
		RSConfigDB.SetItemFiltered(elementData.itemID, check:GetChecked())

		-- Only the clicked item is removed, so the list keeps its scroll
		if (check:GetChecked() and not RSConfigDB.IsExplorerLootShowFiltered()) then
			self.dataProvider:Remove(elementData)
		end
		self:UpdateFilterAllCheck()
	end)
	if (elementData.chance > 0) then
		element.Chance:SetText(elementData.chance .. "%")
	else
		element.Chance:SetText("")
	end

	element:SetScript("OnEnter", function(element)
		local tooltip = self.mainFrame.Tooltip
		EnsureCompareTooltips(tooltip)
		tooltip:SetOwner(element, "ANCHOR_LEFT")
		tooltip:SetHyperlink(elementData.link)
		tooltip:Show()

		-- Comparison with the equipped items while holding shift
		element:RegisterEvent("MODIFIER_STATE_CHANGED")
		if (IsShiftKeyDown()) then
			GameTooltip_ShowCompareItem(tooltip)
		end
	end);
	element:SetScript("OnLeave", function(element)
		element:UnregisterEvent("MODIFIER_STATE_CHANGED")
		local tooltip = self.mainFrame.Tooltip
		EnsureCompareTooltips(tooltip)
		GameTooltip_HideShoppingTooltips(tooltip)
		tooltip:Hide()
	end);
	element:SetScript("OnEvent", function(_, event, key, down)
		local tooltip = self.mainFrame.Tooltip
		if (event == "MODIFIER_STATE_CHANGED" and (key == "LSHIFT" or key == "RSHIFT") and tooltip:IsShown()) then
			if (down == 1) then
				GameTooltip_ShowCompareItem(tooltip)
			else
				GameTooltip_HideShoppingTooltips(tooltip)
			end
		end
	end);
	element:SetScript("OnClick", function()
		if (IsControlKeyDown()) then
			DressUpLink(elementData.link)
		elseif (IsShiftKeyDown()) then
			ChatEdit_LinkItem(elementData.itemID, elementData.link)
		end
	end);
end

function RSExplorerRareLoot:Refresh(elementData)
	self.items = {}
	self.dataProvider:Flush()

	local itemIDs
	local chances = {}
	if (elementData.isNpc) then
		itemIDs = RSNpcDB.GetNpcLoot(elementData.entityID)
		chances = RSNpcDB.GetNpcLootChance(elementData.entityID) or {}
	else
		itemIDs = RSContainerDB.GetContainerLoot(elementData.entityID)
		chances = RSContainerDB.GetContainerLootChance(elementData.entityID) or {}
	end

	if (not itemIDs) then
		return
	end

	-- Items info can be not cached yet, so the list is filled when all of them are loaded
	local request = (self.request or 0) + 1
	self.request = request
	local pending = #itemIDs
	local items = {}
	for _, itemID in ipairs(itemIDs) do
		local item = Item:CreateFromItemID(itemID)
		item:ContinueOnItemLoad(function()
			local _, _, _, equipLoc, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
			local name = item:GetItemName()
			local link = item:GetItemLink()
			local restrictions = RSTooltipScanners.GetItemRestrictions(itemID)

			-- Items without data in the client cannot be shown
			if (name and link and classID) then
				tinsert(items, { itemID = itemID, name = name, link = link, quality = item:GetItemQuality() or 1, chance = tonumber(chances[itemID]) or 0, classID = classID, subClassID = subClassID, isGear = RSLoot.EQUIP_SLOTS[equipLoc] ~= nil, isEquipable = restrictions.isEquipable, isUsable = restrictions.isUsable, isMyLevel = restrictions.isMyLevel, upgrade = RSLoot.IsUpgrade(itemID, link) })
			end
			pending = pending - 1
			if (pending == 0 and self.request == request) then
				self.items = items
				self:ApplyFilters()
			end
		end)
	end
end

-----------------------------------------------------
-- Rare detail frame
-----------------------------------------------------

RSExplorerDetailMap = { };

function RSExplorerDetailMap:OnLoad()
	self.detailTilePool = CreateTexturePool(self, "BACKGROUND", -7, "MapCanvasDetailTileTemplate");
	self.overlayTexturePool = CreateTexturePool(self, "ARTWORK", 0);
	self.textureLoadGroup = CreateFromMixins(TextureLoadingGroupMixin);
	self.detailedTextureLoadGroup = CreateFromMixins(TextureLoadingGroupMixin);
end

function RSExplorerDetailMap:IsFullyLoaded()
	return not self.isWaitingForLoad;
end

function RSExplorerDetailMap:SetMapAndLayer(mapID, layerIndex, mapFrame)
	local mapArtID = C_Map.GetMapArtID(mapID) -- phased map art may be different for the same mapID
	if (self.mapID ~= mapID or self.mapArtID ~= mapArtID or self.layerIndex ~= layerIndex) then
		self.mapID = mapID;
		self.mapArtID = mapArtID;
		self.layerIndex = layerIndex;
		self:RefreshDetailTiles(mapFrame);
	end
end

function RSExplorerDetailMap:RefreshDetailTiles(mapFrame)
	self.detailTilePool:ReleaseAll();
	self.overlayTexturePool:ReleaseAll();
	self.textureLoadGroup:Reset();
	self.detailedTextureLoadGroup:Reset();
	self.isWaitingForLoad = true;
	self:SetAlpha(0);
	
	local layers = C_Map.GetMapArtLayers(self.mapID);
	local layerInfo = layers[self.layerIndex];
	local numDetailTilesRows = math.ceil(layerInfo.layerHeight / layerInfo.tileHeight);
	local numDetailTilesCols = math.ceil(layerInfo.layerWidth / layerInfo.tileWidth);
	local textures = C_Map.GetMapArtLayerTextures(self.mapID, self.layerIndex);
	local exploredMapTextures = C_MapExplorationInfo.GetExploredMapTextures(self.mapID)
	
	local prevRowDetailTile;
	local prevColDetailTile;
	
	-- Add unexplored layer
	for tileCol = 1, numDetailTilesCols do
		for tileRow = 1, numDetailTilesRows do
			if tileRow == 1 then
				prevRowDetailTile = nil;
			end
			local detailTile = self.detailTilePool:Acquire();
			detailTile:ClearAllPoints()
			self.textureLoadGroup:AddTexture(detailTile);
			
			local textureIndex = (tileRow - 1) * numDetailTilesCols + tileCol;
			detailTile:SetTexture(textures[textureIndex], nil, nil, "TRILINEAR");
			detailTile:ClearAllPoints();
			if prevRowDetailTile then
				detailTile:SetPoint("TOPLEFT", prevRowDetailTile, "BOTTOMLEFT");
			else
				if prevColDetailTile then
					detailTile:SetPoint("TOPLEFT", prevColDetailTile, "TOPRIGHT");
				else
					detailTile:SetPoint("TOPLEFT", self);
				end
			end
			detailTile:SetDrawLayer("BACKGROUND", -8 + self.layerIndex);
			detailTile:Show();			
			prevRowDetailTile = detailTile;
			if tileRow == 1 then
				prevColDetailTile = detailTile;
			end
		end
	end
	
	-- Add explored overlay
	if (exploredMapTextures) then
		local TILE_SIZE_WIDTH = layerInfo.tileWidth;
		local TILE_SIZE_HEIGHT = layerInfo.tileHeight;
		for i, exploredTextureInfo in ipairs(exploredMapTextures) do
			local numTexturesWide = ceil(exploredTextureInfo.textureWidth/TILE_SIZE_WIDTH);
			local numTexturesTall = ceil(exploredTextureInfo.textureHeight/TILE_SIZE_HEIGHT);
			local texturePixelWidth, textureFileWidth, texturePixelHeight, textureFileHeight;
			for j = 1, numTexturesTall do
				if ( j < numTexturesTall ) then
					texturePixelHeight = TILE_SIZE_HEIGHT;
					textureFileHeight = TILE_SIZE_HEIGHT;
				else
					texturePixelHeight = mod(exploredTextureInfo.textureHeight, TILE_SIZE_HEIGHT);
					if ( texturePixelHeight == 0 ) then
						texturePixelHeight = TILE_SIZE_HEIGHT;
					end
					textureFileHeight = 16;
					while(textureFileHeight < texturePixelHeight) do
						textureFileHeight = textureFileHeight * 2;
					end
				end
				for k = 1, numTexturesWide do
					local overlayTile = self.overlayTexturePool:Acquire();
					overlayTile:ClearAllPoints()
					
					self.detailedTextureLoadGroup:AddTexture(overlayTile);
					if (k < numTexturesWide) then
						texturePixelWidth = TILE_SIZE_WIDTH;
						textureFileWidth = TILE_SIZE_WIDTH;
					else
						texturePixelWidth = mod(exploredTextureInfo.textureWidth, TILE_SIZE_WIDTH);
						if (texturePixelWidth == 0) then
							texturePixelWidth = TILE_SIZE_WIDTH;
						end
						textureFileWidth = 16;
						while(textureFileWidth < texturePixelWidth) do
							textureFileWidth = textureFileWidth * 2;
						end
					end
					overlayTile:SetWidth(texturePixelWidth);
					overlayTile:SetHeight(texturePixelHeight);
					overlayTile:SetTexCoord(0, texturePixelWidth/textureFileWidth, 0, texturePixelHeight/textureFileHeight);
					overlayTile:SetPoint("TOPLEFT", exploredTextureInfo.offsetX + (TILE_SIZE_WIDTH * (k-1)), -(exploredTextureInfo.offsetY + (TILE_SIZE_HEIGHT * (j - 1))));
					overlayTile:SetTexture(exploredTextureInfo.fileDataIDs[((j - 1) * numTexturesWide) + k], nil, nil, "TRILINEAR");
					overlayTile:SetDrawLayer("ARTWORK", -1);
					overlayTile:Show();
				end
			end
		end
	end
	
	-- Rescale
	self:SetScale(1)
	local mapWidth = layerInfo.layerWidth
	if (mapWidth ~= mapFrame:GetWidth()) then
		local scaleFactor = mapFrame:GetWidth() / mapWidth
		self:SetScale(scaleFactor)
	end
end

function RSExplorerDetailMap:OnUpdate()
	if (self.isWaitingForLoad and self.textureLoadGroup:IsFullyLoaded() and self.detailedTextureLoadGroup:IsFullyLoaded()) then
        self.isWaitingForLoad = nil;
        self:RefreshAlpha();
        self.textureLoadGroup:Reset();
       	self.detailedTextureLoadGroup:Reset();
    end
end

function RSExplorerDetailMap:RefreshAlpha()
	if (self:IsFullyLoaded()) then
		self:SetAlpha(1);
	else
		self:SetAlpha(0);
	end
end

-----------------------------------------------------
-- Control frames
-----------------------------------------------------

RSExplorerControl = {}

function RSExplorerControl:Initialize(mainFrame)
	if (mainFrame.initialized) then
		return
	end
	
	self.mainFrame = mainFrame
	self.ApplyFiltersButton:SetText(AL["EXPLORER_FILTERING"])
	self.ApplyFiltersButton.tooltip = string.format(AL["EXPLORER_FILTERING_DESC"], AL["EXPLORER_FILTERS"], AL["EXPLORER_FILTER_COLLECTIONS"])
	self.CreateProfilesBackupCheckButton.Text:SetText(AL["EXPLORER_CREATE_BACKUP"])
	self.CreateProfilesBackupCheckButton.tooltip = string.format(AL["EXPLORER_CREATE_BACKUP_DESC"], AL["EXPLORER_FILTERING"])
	self.CreateProfilesBackupCheckButton:SetChecked(RSConfigDB.IsCreateProfileBackup())
	self.CreateProfilesBackupCheckButton.func = function(self, checked)
		RSConfigDB.SetCreateProfileBackup(checked)
	end
	
	self.AutoFilterCheckButton.Text:SetText(AL["EXPLORER_AUTO_FILTER"])
	self.AutoFilterCheckButton.tooltip = AL["EXPLORER_AUTO_FILTER_DESC"]
	self.AutoFilterCheckButton:SetChecked(RSConfigDB.IsAutoFilteringOnCollect())
	self.AutoFilterCheckButton.func = function(self, checked)
		RSConfigDB.SetAutoFilteringOnCollect(checked)
	end
end

function RSExplorerControl:StartScanning(self, button)
	if (self:IsShown()) then
		local mainFrame = self:GetParent():GetParent()
		
		self:Hide()
		self:GetParent().ScanProcessText:Show()
		mainFrame:HideCustomLootPanels()
		
		local manualScan = self:GetParent().ScanRequiredText:GetText() == AL["EXPLORER_SCAN_MANUAL"]
		
		RSCollectionsDB.ApplyCollectionsEntitiesFilters(function()
	    	self:GetParent():Hide()
			self:GetParent().ScanProcessText:Hide()
    		mainFrame.RareInfo:Show()
			mainFrame:Initialize()
	    end, self:GetParent().ScanProcessText, manualScan)
	end
end

function RSExplorerControl:ApplyFilters(self, button)
	local mainFrame = self:GetParent().mainFrame
	local data = {
		callback = function()
			mainFrame:Refresh()
			local subdata = {
				filters = filters
			}
			LibDialog:Spawn(RSConstants.APPLY_COLLECTIONS_LOOT_FILTERS, subdata)
		end,
		filters = filters
	}
	LibDialog:Spawn(RSConstants.EXPLORER_FILTERING_DIALOG, data)
end

-----------------------------------------------------
-- Custom loot panel
-----------------------------------------------------

RSExplorerLoot = { };

local function LootGroupDropDown_SetupMenu(dropDown, rootDescription)
	local itemGroups = RSCollectionsDB.GetItemGroups()
	
	for key, name in pairs(itemGroups) do
		rootDescription:CreateRadio(name, 
			function(key)
				return dropDown.selectedGroupKey == key
			end, 
			function(key)
				dropDown.selectedGroupKey = key
			end,
			key)
	end
	
	-- Selects the first value
 	if (not dropDown.selectedGroupKey) then
	 	for key, name in pairs (itemGroups) do
			dropDown.selectedGroupKey = key
			break
		end
	end
end

function RSExplorerLoot:AddNewGroup(editbox)
	local value = editbox:GetText()
	if (value and strtrim(value) ~= '') then
		local key = RSCollectionsDB.AddItemGroup(value)
		if (key) then
			editbox:GetParent().LootGroupDropDown.selectedGroupKey = key
			editbox:GetParent().LootGroupDropDown:GenerateMenu()
			editbox:SetText("")
			editbox:ClearFocus()
			self:RefreshDataProvider()
		end
	end
end

function RSExplorerLoot:EditGroupName(editbox)
	local mainFrame = editbox:GetParent():GetParent()
	local controlFrame = mainFrame.ControlFrame
	local newGroupName = editbox:GetText()
	local elementData = self.selectionBehavior:GetFirstSelectedElementData()
	
	-- Change name
	RSCollectionsDB.SetGroupName(elementData.key, newGroupName)
	
	-- Refresh group dropdown if selected
	if (self.ControlFrame.LootGroupDropDown.selectedGroupKey == elementData.key) then
		controlFrame.LootGroupDropDown:GenerateMenu()
	end
	
	self:RefreshDataProvider()
end

function RSExplorerLoot:DeleteGroup(buttonFrame, button)
	local mainFrame = self
	local elementData = self.selectionBehavior:GetFirstSelectedElementData()
	
	local data = {
		callback = function()
			RSCollectionsDB.DeleteItemGroup(elementData.key)
	
			-- Selects the first item in the list
			for key, name in pairs(RSCollectionsDB.GetItemGroups()) do
				mainFrame.ControlFrame.LootGroupDropDown.selectedGroupKey = key
				mainFrame.ControlFrame.LootGroupDropDown:GenerateMenu()
				break
			end
			
			mainFrame.GroupInfo.lootItemsPool:ReleaseAll();
			mainFrame:RefreshDataProvider()
		end
	}
	LibDialog:Spawn(RSConstants.DELETE_GROUP_CONFIRMATION, data)
end

function RSExplorerLoot:AddItems(editbox)
	local value = editbox:GetText()
	local elementData = self.selectionBehavior:GetFirstSelectedElementData()
	
	if (value and strtrim(value) ~= '') then
		-- Validates string
		if (string.match(value, "[^0-9,]")) then
			LibDialog:Spawn(RSConstants.ITEM_LIST_VALIDATION_ERROR);
			return
		end
		
		-- Validates items
		local errorIDs = {}
		for itemIDstring in string.gmatch(value, '([^,]+)') do
			local itemID = tonumber(itemIDstring)
			local ret, _, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID = pcall(C_Item.GetItemInfoInstant, itemID)
			if (not ret or not icon) then
				tinsert(errorIDs, itemID)
			else
				RSCollectionsDB.AddGroupItem(elementData.key, itemID)
			end
		end
		
		-- Prints wrong IDs
		if (RSUtils.GetTableLength(errorIDs) > 0) then
			LibDialog:Spawn(RSConstants.ITEM_LIST_WRONG_IDS_ERROR);
			local errorIDsString
			for _, itemID in ipairs(errorIDs) do
				if (not errorIDsString) then
					errorIDsString = itemID
				else
					errorIDsString = string.format("%s, %s", errorIDsString, itemID)
				end
			end
			RSLogger:PrintMessage(string.format(AL["EXPLORER_CUSTOM_ITEMS_WRONG_IDS_CHAT"], errorIDsString))
			return
		end
		
		-- Clean inputfield
		editbox:SetText("")
		
		-- Refresh info panel
		self:Refresh()
	end
end

function RSExplorerLoot:Refresh()
	local elementData = self.selectionBehavior:GetFirstSelectedElementData()
	if (not elementData) then
		return
	end
	
	self:OnElementSelectionChanged(elementData, true)
end

function RSExplorerCustomLootItem_OnEnter(self)
	local customLoot = self:GetParent():GetParent()
	local tooltip = customLoot.mainFrame.Tooltip
	local itemIcon = self
	local item = Item:CreateFromItemID(self.itemID)
	item:ContinueOnItemLoad(function()
		tooltip:SetOwner(itemIcon, "BOTTOM_LEFT")
		tooltip:SetHyperlink(item:GetItemLink())
		
		-- Adds extra information only for this tooltip
		tooltip:AddLine(RSUtils.TextColor(string.format(AL["EXPLORER_CUSTOM_ITEMS_TOOLTIP_ID"], item:GetItemID()), "FFFF00"))
		tooltip:AddLine(" ")
		tooltip:AddLine("|TInterface\\AddOns\\RareScanner\\Media\\Textures\\tooltip_shortcuts:18:60:::256:256:0:96:0:32|t "..RSUtils.TextColor(AL["EXPLORER_CUSTOM_ITEMS_TOOLTIP_DROP"], "00FF00"))
		
		tooltip:Show()
	end)
end

function RSExplorerCustomLootItem_OnLeave(self)
	local customLoot = self:GetParent():GetParent()
	local tooltip = customLoot.mainFrame.Tooltip
	tooltip:Hide()
end

function RSExplorerCustomLootItem_OnClick(self, button)
	local customLoot = self:GetParent():GetParent()
	local itemIcon = self
	
	if (button == "LeftButton" and not IsAltKeyDown() and IsShiftKeyDown()) then
		local item = Item:CreateFromItemID(itemIcon.itemID)
		item:ContinueOnItemLoad(function()
			ChatEdit_LinkItem(self.itemID, item:GetItemLink())
		end)
	elseif (button == "LeftButton" and IsAltKeyDown() and IsShiftKeyDown()) then
		RSCollectionsDB.DeleteGroupItem(self.groupKey, itemIcon.itemID)
		customLoot:Refresh()
	end
end

local function RSRexplorerGroupList_Sort(e1, e2)
	local strCmpResult = strcmputf8i(e1.name, e2.name);
	if (strCmpResult ~= 0) then
		return strCmpResult < 0;
	end
	
	return false
end

function RSExplorerLoot:Initialize(mainFrame)
	if (self.initialized) then
		return
	end
	
	self.initialized = true
	self.mainFrame = mainFrame
	self.mainFrame.Tooltip = CreateFrame("GameTooltip", "ExplorerTooltip", nil, "GameTooltipTemplate")
	self.mainFrame.Tooltip:SetScale(UIParent:GetScale())
	self.mainFrame.Tooltip.minimumWidth = 150
	self.ControlFrame.mainFrame = mainFrame
	
	-- Control panel
	self.ControlFrame.LootGroupLabel:SetText(AL["EXPLORER_CUSTOM_ITEMS_GROUP"])
	self.ControlFrame.LootNewGroupLabel:SetText(AL["EXPLORER_CUSTOM_ITEMS_ADD_GROUP"])
	self.ControlFrame.LootGroupDropDown.tooltip = AL["EXPLORER_CUSTOM_ITEMS_GROUP_DESC"]
	self.ControlFrame.LootGroupDropDown:SetupMenu(LootGroupDropDown_SetupMenu)
	self.ControlFrame.NewGroup.tooltip = AL["EXPLORER_CUSTOM_ITEMS_ADD_GROUP_DESC"]
	self.ControlFrame.ItemListLabel:SetText(AL["EXPLORER_CUSTOM_ITEMS_LIST"])
	self.ControlFrame.ItemList.tooltip = AL["EXPLORER_CUSTOM_ITEMS_LIST_DESC"]
	
	-- Group info
	self.GroupInfo.mainFrame = mainFrame
	self.GroupInfo.DeleteGroup:SetText(AL["EXPLORER_CUSTOM_ITEMS_DELETE_GROUP"])
	self.GroupInfo.EditGroupName.tooltip = AL["EXPLORER_CUSTOM_ITEMS_EDIT_GROUP"]
	self.GroupInfo.NoItems:SetText(AL["EXPLORER_CUSTOM_ITEMS_GROUP_EMPTY"])
	self.GroupInfo.lootItemsPool = CreateFramePool("Button", self.GroupInfo, "RSExplorerCustomLootItemTemplate");
	
	-- Group list
	self.GroupList.scrollView = CreateScrollBoxListLinearView();
    self.GroupList.scrollView:SetElementInitializer("RSExplorerGroupButtonTemplate", GenerateClosure(self.OnElementInitialize, self));
	ScrollUtil.InitScrollBoxListWithScrollBar(self.GroupList.scrollBox, self.GroupList.scrollBar, self.GroupList.scrollView);
	
	self.selectionBehavior = ScrollUtil.AddSelectionBehavior(self.GroupList.scrollBox);
    self.selectionBehavior:RegisterCallback("OnSelectionChanged", self.OnElementSelectionChanged, self);
	
	self.dataProvider = CreateDataProvider()
	self.dataProvider:SetSortComparator(RSRexplorerGroupList_Sort)
	self.GroupList.scrollBox:SetDataProvider(self.dataProvider);
	self:RefreshDataProvider();
	
	-- Starts hidding it
	mainFrame:HideCustomLootPanels()
end

function RSExplorerLoot:OnElementInitialize(element, elementData)
	element.Name:SetText(elementData.name)
	
	if (self.selectionBehavior:IsSelected(element)) then
		element.Selected:Show()
	else
		element.Selected:Hide()
	end
	
	element:SetScript("OnClick", function(element, button) self:OnElementClick(element, elementData, button) end);
end

function RSExplorerLoot:OnElementSelectionChanged(elementData, selected)
    local element = self.GroupList.scrollView:FindFrame(elementData);
    
    if (not element) then
    	return
    end
    
    -- Avoid refreshing UI for deselected elements
    if (not selected) then
    	element.Selected:Hide()
    	return
    else
   		element.Selected:Show()
   	end
   	
	self.GroupInfo.EditGroupName:SetText(elementData.name)
	
	-- Cleans current list
	self.GroupInfo.lootItemsPool:ReleaseAll();
		
	-- Name
	local itemIDs = RSCollectionsDB.GetGroupItems(elementData.key)
	if (RSUtils.GetTableLength(itemIDs) == 0) then
		self.GroupInfo.NoItems:Show()
	else
		self.GroupInfo.NoItems:Hide()
		
		local xOffset = 0
		local yOffset = -2
		local numColumn = 0
		local numRow = 0
		local maxLines = 8
		local maxItemsPerRow = 17
    	for _, itemID in ipairs(itemIDs) do
    		local _, _, _, _, icon, _, _ = C_Item.GetItemInfoInstant(itemID)
    		local lootItem = self.GroupInfo.lootItemsPool:Acquire();
    		
    		if (math.fmod(numColumn, maxItemsPerRow) ~= 0) then
    			xOffset = xOffset + lootItem:GetWidth() + 2
    		end
    		
    		lootItem.itemID = itemID
    		lootItem.groupKey = elementData.key
    		lootItem.Icon:SetTexture(icon)
    		lootItem:SetPoint("TOPLEFT", self.GroupInfo.ItemPanel, "TOPLEFT", xOffset, yOffset)
    		lootItem:Show()
    		
    		numColumn = numColumn + 1
    		
    		if (math.fmod(numColumn, maxItemsPerRow) == 0) then
				numRow = numRow + 1
				if (numRow == maxLines) then
					break
				end
				
				xOffset = 0
				numColumn = 0
				yOffset = yOffset - lootItem:GetHeight() - 2
			end
    	end
	end
end

function RSExplorerLoot:OnElementClick(element, elementData, button)
	self.selectionBehavior:ClearSelections()
	self.selectionBehavior:Select(element);
end

function RSExplorerLoot:RefreshDataProvider()
	-- Deletes everything in the dataprovider
	self.dataProvider:Flush()
	
	for key, name in pairs(RSCollectionsDB.GetItemGroups()) do
		local elementData = {}
		elementData.name = name
		elementData.key = key
		self.dataProvider:Insert(elementData);
	end
	
	-- Autoselects the first element
	self.selectionBehavior:SelectFirstElementData()
end

-----------------------------------------------------
-- Explorer main frame
-----------------------------------------------------

local LOOT_PANEL_WIDTH = 305
local LOOT_PANEL_ANIMATION_DURATION = 0.25

RSExplorerMixin = { };

function RSExplorerMixin:OnLoad()
	self.collapsedWidth = self:GetWidth() - LOOT_PANEL_WIDTH
	self.lootItemsPool = CreateFramePool("Button", self.RareInfo, "RSExplorerRareInfoLootItemTemplate");
	self.RareInfo.Mounts.Texture:SetTexture("Interface\\AddOns\\RareScanner\\Media\\Textures\\MountsCorner.blp")
	self.RareInfo.Mounts.Texture:SetVertexColor(1,1,1,0.5)
	self.RareInfo.Mounts.Texture.tooltip = AL["EXPLORER_MOUNTS"]
	self.RareInfo.Pets.Texture:SetTexture("Interface\\AddOns\\RareScanner\\Media\\Textures\\PetsCorner.blp")
	self.RareInfo.Pets.Texture:SetVertexColor(1,1,1,0.5)
	self.RareInfo.Pets.Texture.tooltip = AL["EXPLORER_PETS"]
	self.RareInfo.Toys.Texture:SetTexture("Interface\\AddOns\\RareScanner\\Media\\Textures\\ToysCorner.blp")
	self.RareInfo.Toys.Texture:SetVertexColor(1,1,1,0.5)
	self.RareInfo.Toys.Texture.tooltip = AL["EXPLORER_TOYS"]
	self.RareInfo.Appearances.Texture:SetTexture("Interface\\AddOns\\RareScanner\\Media\\Textures\\AppearancesCorner.blp")
	self.RareInfo.Appearances.Texture:SetVertexColor(1,1,1,0.5)
	self.RareInfo.Appearances.Texture.tooltip = AL["EXPLORER_APPEARANCES"]
	self.RareInfo.Custom.Texture:SetTexture("Interface\\AddOns\\RareScanner\\Media\\Textures\\CustomCorner.blp")
	self.RareInfo.Custom.Texture:SetVertexColor(1,1,1,0.5)
	self.RareInfo.Custom.Texture.tooltip = AL["EXPLORER_CUSTOM"]
	--self.RareInfo.Decor.Texture:SetTexture("Interface\\AddOns\\RareScanner\\Media\\Textures\\DecorCorner.blp")
	--self.RareInfo.Decor.Texture:SetVertexColor(1,1,1,0.5)
	--self.RareInfo.Decor.Texture.tooltip = AL["EXPLORER_DECOR"]
	self:RegisterForDrag("LeftButton");
	tinsert(UISpecialFrames, self:GetName());
end

function RSExplorerMixin:HideCustomLootPanels()
	self.CustomLoot:Hide()
	
	-- Move to the center
	self.ScanRequired:SetPoint("TOPLEFT")
	self.ScanRequired:SetPoint("TOPRIGHT")
	self.ScanRequired.moved = false
end

function RSExplorerMixin:ShowCustomLootPanels()
	self.CustomLoot:Show()
	
	-- Move to the bottom
	if (not self.ScanRequired.moved) then
		local pointte, relativeTote, relativePointte, xOfste, yOfste = self.ScanRequired:GetPoint()
		self.ScanRequired:SetPoint(pointte, relativeTote, relativePointte, xOfste, yOfste - 300)
		self.ScanRequired.moved = true
	end
end

function RSExplorerMixin:UpdateLootButton()
	local button = self.Filters.ToggleLootButton
	if (self.lootCollapsed) then
		button.Arrow:SetAtlas("common-icon-forwardarrow")
		button.tooltip = AL["EXPLORER_SHOW_LOOT"]
	else
		button.Arrow:SetAtlas("common-icon-backarrow")
		button.tooltip = AL["EXPLORER_HIDE_LOOT"]
	end
end

-- Shrinks/expands the window keeping its left side in place and fades the loot panel
function RSExplorerMixin:ToggleLootPanel()
	self.lootCollapsed = not self.lootCollapsed
	RSConfigDB.SetExplorerLootCollapsed(self.lootCollapsed)
	self:UpdateLootButton()

	if (not self.animationFrame) then
		self.animationFrame = CreateFrame("Frame", nil, self)
	end

	local expand = not self.lootCollapsed
	local startProgress = self.lootProgress or 1
	local endProgress = expand and 1 or 0
	local startWidth = self:GetWidth()
	local collapsedWidth = self.collapsedWidth
	local point, relativeTo, relativePoint, x, y = self:GetPoint()
	local elapsed = 0

	if (expand and self.RareInfo:IsShown()) then
		self.RareLoot:Show()
	end

	self.animationFrame:SetScript("OnUpdate", function(_, delta)
		elapsed = elapsed + delta
		local t = math.min(elapsed / LOOT_PANEL_ANIMATION_DURATION, 1)
		t = t * t * (3 - 2 * t)

		local progress = startProgress + (endProgress - startProgress) * t
		local width = collapsedWidth + LOOT_PANEL_WIDTH * progress
		self.lootProgress = progress
		self:SetWidth(width)
		self:SetPoint(point, relativeTo, relativePoint, x + (width - startWidth) / 2, y)
		self.RareLoot:SetAlpha(progress)

		if (elapsed >= LOOT_PANEL_ANIMATION_DURATION) then
			self.animationFrame:SetScript("OnUpdate", nil)
			if (not expand) then
				self.RareLoot:Hide()
			end
		end
	end)
end

function RSExplorerMixin:HideContentPanels()
	self.RareInfo:Hide()
	self.RareLoot:Hide()
	self.RareNPCList:Hide()
	self.Filters:Hide()
	self.Control:Hide()
end

function RSExplorerMixin:ShowContentPanels()
	self.RareInfo:Show()
	if (not self.lootCollapsed) then
		self.RareLoot:Show()
	end
	self.RareNPCList:Show()
	self.Filters:Show()
	self.Control:Show()
end

function RSExplorerMixin:Initialize()
	filters[RSConstants.EXPLORER_FILTER_DROP_MOUNTS] = RSConfigDB.IsSearchingMounts()
	filters[RSConstants.EXPLORER_FILTER_DROP_PETS] = RSConfigDB.IsSearchingPets()
	filters[RSConstants.EXPLORER_FILTER_DROP_TOYS] = RSConfigDB.IsSearchingToys()
	filters[RSConstants.EXPLORER_FILTER_DROP_APPEARANCES] = RSConfigDB.IsSearchingAppearances()
	filters[RSConstants.EXPLORER_FILTER_DROP_CLASS_APPEARANCES] = RSConfigDB.IsSearchingClassAppearances()
	filters[RSConstants.EXPLORER_FILTER_DEAD] = RSConfigDB.IsShowDead()
	filters[RSConstants.EXPLORER_FILTER_TYPE_NPC] = RSConfigDB.IsShowNpcs()
	filters[RSConstants.EXPLORER_FILTER_TYPE_CONTAINER] = RSConfigDB.IsShowContainers()
	filters[RSConstants.EXPLORER_FILTER_FILTERED] = RSConfigDB.IsShowFiltered()
	filters[RSConstants.EXPLORER_FILTER_WITHOUT_COLLECTIBLES] = RSConfigDB.IsShowWithoutCollectibles()
	filters[RSConstants.EXPLORER_FILTER_IGNORE_COLLECTIBLES] = RSConfigDB.IsIgnoreMissingCollectibles()
	
	for groupKey, _ in pairs(RSCollectionsDB.GetItemGroups()) do
		filters[string.format(RSConstants.EXPLORER_FILTER_DROP_CUSTOM, groupKey)] = RSConfigDB.IsSearchingCustom(groupKey)
	end
	
	-- Restores the loot panel state (without animation)
	self.lootCollapsed = RSConfigDB.IsExplorerLootCollapsed()
	if (self.lootCollapsed) then
		local startWidth = self:GetWidth()
		local point, relativeTo, relativePoint, x, y = self:GetPoint()
		self.lootProgress = 0
		self:SetWidth(self.collapsedWidth)
		self:SetPoint(point, relativeTo, relativePoint, x + (self.collapsedWidth - startWidth) / 2, y)
		self.RareLoot:SetAlpha(0)
		self.RareLoot:Hide()
	end

	self.RareNPCList:Initialize(self);
	self.RareLoot:Initialize(self);
	self.Filters:Initialize(self);
	self.Control:Initialize(self);
	self.CustomLoot:Initialize(self);
	self:UpdateLootButton()
	self.initialized = true
end

function RSExplorerMixin:OnShow()
    -- check if there is a new database and it requires a new scan
    if (not RSCollectionsDB.IsCollectionsScanDoneWithCurrentVersion()) then
    	self.ScanRequired.ScanRequiredText:SetText(AL["EXPLORER_SCAN_REQUIRED"])
    	self.ScanRequired.StartScanningButton:SetText(AL["EXPLORER_START_SCAN"])
    	self.ScanRequired.StartScanningButton:Show()		
    	self.ScanRequired:Show()
    	self:HideContentPanels()
		self.CustomLoot:Initialize(self);
    	self:ShowCustomLootPanels()
    elseif (not self.initialized) then
		self:Initialize()
	end
	-- change to player's zone
	if (RSConfigDB.IsLockingCurrentMap()) then
		-- Hides the previous map until the refresh selects the current one
		if (self.initialized) then
			self:HideContentPanels()
		end
		self:Refresh()
	end

	self:Show()
end

function RSExplorerMixin:Refresh()
	if (self.initialized) then
		PopulateContinentDropDown(self, self.Filters.ContinentDropDown, function()
			self.RareNPCList:RefreshDataProvider()
		end)
	end
end

function RSExplorerMixin:ShowTooltip(frame, message)
	if (frame.tooltip or message) then
		local tooltip = self.Tooltip
		tooltip:SetOwner(frame, "ANCHOR_BOTTOM")
		tooltip:AddLine(message or frame.tooltip, 1, 1, 1, true)
		tooltip:Show()
	end
end

function RSExplorerMixin:HideTooltip(frame)
	if (frame.tooltip) then
		local tooltip = self.Tooltip
		tooltip:Hide()
	end
end

