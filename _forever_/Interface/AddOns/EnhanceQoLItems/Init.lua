local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

-- No inventory ownership, collectors or SavedVariables: callers own their snapshots.
addon.Items = { apiVersion = 1, schemaVersion = 1, fields = {}, aliases = {} }
local I = addon.Items
I.internal = { listeners = {}, revision = 0 }
local P = I.internal
function P.Safe(value) return not (_G.issecretvalue and _G.issecretvalue(value)) end
function P.Copy(value, seen)
	if not P.Safe(value) then return nil end
	if type(value) ~= "table" then return value end
	seen = seen or {}
	if seen[value] then return seen[value] end
	local out = {}; seen[value] = out
	for key, child in pairs(value) do
		if P.Safe(key) and P.Safe(child) then out[key] = P.Copy(child, seen) end
	end
	return out
end
function P.Error(code, position, args)
	return nil, { code = code, message = code, position = position or 1, args = args }
end
function P.Number(value)
	return P.Safe(value) and type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end
function P.Native(name) return (_G.C_Item and _G.C_Item[name]) or _G[name] end
function P.Now() return _G.GetTime and _G.GetTime() or 0 end
function I.Subscribe(callback)
	if type(callback) ~= "function" then return nil end
	local token = {}; P.listeners[token] = callback; return token
end
function I.Unsubscribe(token) P.listeners[token] = nil end
function P.Emit(payload)
	P.revision = P.revision + 1; payload.revision = P.revision
	local listeners = {}; for token, callback in pairs(P.listeners) do listeners[token] = callback end
	for token, callback in pairs(listeners) do
		if P.listeners[token] == callback then pcall(callback, P.Copy(payload)) end
	end
end
