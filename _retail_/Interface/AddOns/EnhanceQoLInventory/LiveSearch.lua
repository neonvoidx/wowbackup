-- luacheck: globals C_Bank BAGS EQUIPPED
local addon = _G.EnhanceQoL
local I, API = addon.Inventory, addon.Inventory.API
local function call(fn, ...)
 if type(fn) ~= "function" then return end
 local ok, result = pcall(fn, ...)
 if ok and I.Safe(result) then return result end
end
local function appendBag(items, bagID, source)
 local container = C_Container
 local count = container and call(container.GetContainerNumSlots, bagID)
 if type(count) ~= "number" or count <= 0 then return end
 for slotID = 1, count do
  local info = call(container.GetContainerItemInfo, bagID, slotID)
  if type(info) == "table" and I.Safe(info.itemID) and type(info.itemID) == "number" and info.itemID > 0 then
   local link = I.Safe(info.hyperlink) and info.hyperlink or call(container.GetContainerItemLink, bagID, slotID)
   local item = { itemID = info.itemID, link = link, bagID = bagID, slotID = slotID, source = source,
    count = I.Safe(info.stackCount) and info.stackCount or 1, isBound = I.Safe(info.isBound) and info.isBound or nil,
    isLocked = I.Safe(info.isLocked) and info.isLocked or nil, quality = I.Safe(info.quality) and info.quality or nil }
   if I.Safe(info.isBound) then item.isBound = info.isBound end
   if I.Safe(info.isLocked) then item.isLocked = info.isLocked end
   items[#items + 1] = item
  end
 end
end
function API.GetSources()
 return { { value = "all", label = addon.L["itemSearchCurrent"] }, { value = "bags", label = BAGS },
  { value = "equipped", label = EQUIPPED }, { value = "bank", label = BANK, available = I.state.bankOpen } }
end
function API.Snapshot(source)
 local items, seen = {}, {}
 local function bag(id, kind) if type(id) == "number" and not seen[id] then seen[id] = true; appendBag(items, id, kind) end end
 if source == nil or source == "all" or source == "bags" then
  for id = 0, (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do bag(id, "bags") end
  local ids = Enum and Enum.BagIndex
  if ids and ids.Keyring then bag(ids.Keyring, "bags") end
 end
 if source == nil or source == "all" or source == "equipped" then
  for slotID = 1, 19 do
   local itemID = call(GetInventoryItemID, "player", slotID)
   if type(itemID) == "number" then
    items[#items + 1] = { itemID = itemID, link = call(GetInventoryItemLink, "player", slotID), inventorySlot = slotID,
     source = "equipped", count = 1, isBound = true }
   end
  end
 end
 if (source == nil or source == "all" or source == "bank") and I.state.bankOpen then
  local types = Enum and Enum.BankType
  local modern = false
  if C_Bank and C_Bank.FetchPurchasedBankTabData and types then
   for _, bankType in ipairs({ types.Character, types.Account }) do
    if bankType ~= nil and call(C_Bank.CanViewBank, bankType) then
     local tabs = call(C_Bank.FetchPurchasedBankTabData, bankType)
     if type(tabs) == "table" then
      modern = true
      for _, tab in ipairs(tabs) do if I.Safe(tab.ID) then bag(tab.ID, "bank") end end
     end
    end
   end
  end
  if not modern then
   local ids = Enum and Enum.BagIndex or {}
   bag(ids.Bank or -1, "bank")
   local lastBag = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4
   for id = lastBag + 1, lastBag + (NUM_BANKBAGSLOTS or 7) do bag(id, "bank") end
   if ids.Reagentbank and call(IsReagentBankUnlocked) then bag(ids.Reagentbank, "bank") end
  end
 end
 return items
end
function I.Context(item)
 local context = { player = { level = call(UnitLevel, "player") }, observations = item }
 if item and item.bagID ~= nil and ItemLocation and ItemLocation.CreateFromBagAndSlot then context.itemLocation = ItemLocation:CreateFromBagAndSlot(item.bagID, item.slotID) end
 if item and item.inventorySlot and ItemLocation and ItemLocation.CreateFromEquipmentSlot then context.itemLocation = ItemLocation:CreateFromEquipmentSlot(item.inventorySlot) end
 return context
end
function I.SearchQuery(query)
 if not addon.Items then return nil, { code = "unavailable" } end
 if type(query) == "string" and query:match("^%s*$") then return addon.Items.Compile({ constant = true }) end
 return addon.Items.Compile(query)
end
function API.Search(query, options)
 if not addon.Items then return { matches = {}, unresolved = {}, error = { code = "item_service_unavailable" } } end
 options = options or {}
 local normalized = type(query) == "string" and query:match("^%s*(.-)%s*$")
 local inspectItem
 if options.inspect and normalized then
  local isReference = normalized:match("^%d+$") or normalized:match("^item:%d+[:%d%-]*$")
   or normalized:match("^|Hitem:[^|]+|h.*|h$") or normalized:match("^|c%x+|Hitem:[^|]+|h.*|h|r$")
  if isReference then inspectItem = addon.Items.NormalizeItem(normalized) end
 end
 local compiled, err = I.SearchQuery(inspectItem and { field = "itemID", op = "=", value = inspectItem.itemID } or query)
 if not compiled then return { matches = {}, unresolved = {}, error = err } end
 local result = { matches = {}, unresolved = {}, total = 0, compiled = compiled }
 local items = options.items or API.Snapshot(options.source)
 if inspectItem then inspectItem.source = "inspect"; items = { inspectItem } end
 for _, item in ipairs(items) do
  local context = I.Context(item)
  local facts, statuses = addon.Items.Get(item, compiled.fields, context)
  local match = addon.Items.Evaluate(compiled, facts, statuses)
  result.total = result.total + 1
  local row = { item = item, facts = facts, statuses = statuses }
  if match == true then result.matches[#result.matches + 1] = row
  elseif match == nil then result.unresolved[#result.unresolved + 1] = row end
  if match == nil and options.request then
   addon.Items.Request(item, compiled.fields, context, function(_, updated)
    local changed = false
    for field, status in pairs(statuses or {}) do
     if updated and updated[field] ~= status and updated[field] ~= "pending" then changed = true; break end
    end
    if changed and options.onReady then options.onReady() end
   end)
  end
 end
 return result
end
function API.Inspect(item, callback)
 local fields = {}; for _, field in ipairs(addon.Items.ListFields(I.Context(item))) do fields[#fields + 1] = field.name or field.id end
 local facts, statuses = addon.Items.Get(item, fields, I.Context(item))
 if callback then addon.Items.Request(item, fields, I.Context(item), callback) end
 return facts, statuses, fields
end
function API.ParseQuery(query) return addon.Items.Parse(query) end
function API.FormatQuery(query) return addon.Items.Format(query) end
function API.CompileQuery(query) return I.SearchQuery(query) end
function API.ListSearchFields() return addon.Items.ListFields() end
local function legacy(query, depth)
 if type(query) ~= "table" or (depth or 0) > 32 then return query end
 if query.kind == "predicate" then return { field = query.field, op = query.op, value = I.Copy(query.value) } end
 if query.kind == "and" or query.kind == "or" then return { [query.kind == "and" and "all" or "any"] = { legacy(query.left, (depth or 0) + 1), legacy(query.right, (depth or 0) + 1) } } end
 if query.kind == "not" then return { ["not"] = legacy(query.child or query.value, (depth or 0) + 1) } end
 return I.Copy(query)
end
function API.ListSavedSearches()
 I.Initialize()
 local store = I.db.savedSearches
 if type(store) ~= "table" or store.version ~= 1 or type(store.entries) ~= "table" then return {} end
 local entries = {}
 for id, entry in pairs(store.entries) do
  if type(entry) == "table" and type(entry.name) == "string" then
   local query = legacy(entry.query)
   local compiled, err = I.SearchQuery(query)
   entries[#entries + 1] = { id = id, name = entry.name, query = query, unavailable = not compiled, issue = err }
  end
 end
 table.sort(entries, function(a, b) return a.name == b.name and tostring(a.id) < tostring(b.id) or a.name < b.name end)
 return entries
end
function API.SaveSearch(name, query, _, id)
 if type(name) ~= "string" then return nil end
 name = name:match("^%s*(.-)%s*$")
 if #name == 0 or #name > 80 then return nil end
 local compiled, err = I.SearchQuery(query)
 if not compiled then return nil, err end
 I.Initialize()
 local store = I.db.savedSearches
 if type(store) ~= "table" or store.version ~= 1 or type(store.entries) ~= "table" then return nil end
 local count = 0
 for key, entry in pairs(store.entries) do
  count = count + 1
  if type(entry) == "table" and entry.name == name and not id then id = key end
 end
 if not id and count >= 128 then return nil end
 if not id then
  store.serial = math.max(0, tonumber(store.serial) or 0) + 1
  id = "search:" .. tostring(store.serial)
 end
 store.entries[id] = { id = id, name = name, query = I.Copy(compiled.ast) }
 I.Emit("SavedSearchesChanged")
 return id
end
function API.GetSavedSearch(id) for _, entry in ipairs(API.ListSavedSearches()) do if entry.id == id then return entry end end end
function API.DeleteSavedSearch(id)
 I.Initialize()
 local store = I.db.savedSearches
 if type(store) ~= "table" or type(store.entries) ~= "table" or not store.entries[id] then return false end
 store.entries[id] = nil; I.Emit("SavedSearchesChanged"); return true
end
