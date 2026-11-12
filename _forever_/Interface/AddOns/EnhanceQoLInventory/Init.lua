local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then addon = _G[parentAddonName] else error(parentAddonName .. " is not loaded") end

-- Search observes the current character only while requested. Item metadata and
-- filter execution belong to the shared Items service, never an inventory DB.
addon.Inventory = { API = {}, state = { bankOpen = false }, listeners = {} }
local I = addon.Inventory
function I.Safe(value) return not (_G.issecretvalue and _G.issecretvalue(value)) end
function I.Copy(value)
 if not I.Safe(value) then return nil end
 if type(value) ~= "table" then return value end
 local result = {}; for key, child in pairs(value) do if I.Safe(key) then result[key] = I.Copy(child) end end
 return result
end
function I.Initialize()
 local saved = _G.EnhanceQoLInventoryDB
 if type(saved) ~= "table" then saved = {}; _G.EnhanceQoLInventoryDB = saved end
 if addon.functions.CleanupItemSearchData then addon.functions.CleanupItemSearchData(saved) end
 I.db = saved
 if saved.savedSearches == nil then saved.savedSearches = { version = 1, serial = 0, entries = {} } end
 return true
end
function I.API.GetStatus() return { ready = addon.Items ~= nil, revision = I.state.revision or 0 } end
function I.API.Subscribe(event, callback)
 if type(callback) ~= "function" then return end
 local token = {}; I.listeners[token] = { event = event, callback = callback }; return token
end
function I.API.Unsubscribe(token) I.listeners[token] = nil end
function I.Emit(event)
 for token, entry in pairs(I.listeners) do if I.listeners[token] == entry and entry.event == event then entry.callback() end end
end
