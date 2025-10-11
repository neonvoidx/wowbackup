local _, private = ...
-- This mixin allows modules to hook/unhook functions and frames.
local HookRegistry = {}
private.mixins["HookRegistry"] = HookRegistry

-- API

-- Use weak tables for hooked objects and callbacks to avoid memory leaks.
-- (Objects used as keys will be collected if there are no other strong references.)
local hooked = setmetatable({}, { __mode = "k" })
local callbacks = setmetatable({}, { __mode = "k" })
local registry = setmetatable({}, { __mode = "k" })

-- Generates a unique hook ID by concatenating string representations of module, object, and function/script name.
local function getHookID(module, obj, func_name)
  return tostring(module) .. "|" .. tostring(obj) .. "|" .. tostring(func_name)
end

-- Prepare the callback table for a given object and function/script name.
local function prepareCallbackTable(obj, func_name)
  if not callbacks[obj] then
    callbacks[obj] = {}
  end
  if not callbacks[obj][func_name] then
    callbacks[obj][func_name] = {}
  end
end

-- Check if an object has already been hooked for a given function/script.
local function isHooked(obj, func_name)
  return hooked[obj] and hooked[obj][func_name]
end

-- Mark an object as hooked for a given function/script.
local function registerHook(obj, func_name)
  if not hooked[obj] then
    hooked[obj] = {}
  end
  hooked[obj][func_name] = true
end

-- Register a hook for the module in the registry so it can be unhooked later.
local function registerModuleHook(module, id, obj, func_name)
  if not registry[module] then
    registry[module] = {}
  end
  registry[module][id] = {
    key1 = obj,
    key2 = func_name,
  }
end

-- Wrap a callback so that if it is a string, it is converted to a function that calls the module’s method.
local function wrapCallback(module, callback_func)
  if type(callback_func) == "string" then
    local method = module[callback_func]
    if type(method) ~= "function" then
      error("Method '" .. callback_func .. "' not found in module")
    end
    -- Return a function that calls the method with the module as its self.
    return function(...)
      return method(module, ...)
    end
  elseif type(callback_func) == "function" then
    return callback_func
  else
    error("Invalid callback type: " .. type(callback_func))
  end
end

--------------------------
--- HookScript Wrapper ---
--------------------------

--- Wrapper around the HookScript function.
--- This allows multiple callbacks per module for a given script hook.
--- @param ScriptObject table  The widget or frame to hook.
--- @param scriptTypeName string  The name of the script (e.g. "OnShow", "OnHide").
--- @param callback_func function|string  The function or method name (as a string) to be called.
function HookRegistry:HookScript(ScriptObject, scriptTypeName, callback_func)
  local callback = wrapCallback(self, callback_func)
  local id = getHookID(self, ScriptObject, scriptTypeName)
  prepareCallbackTable(ScriptObject, scriptTypeName)

  -- Ensure there is a list to hold multiple callbacks for this module.
  if not callbacks[ScriptObject][scriptTypeName][self] then
    callbacks[ScriptObject][scriptTypeName][self] = {}
  end
  table.insert(callbacks[ScriptObject][scriptTypeName][self], callback)

  -- Hook the script if it hasn't been hooked already.
  if not isHooked(ScriptObject, scriptTypeName) then
    ScriptObject:HookScript(scriptTypeName, function(...)
      -- Iterate over all modules and call each of their callbacks.
      for module, callbackList in next, callbacks[ScriptObject][scriptTypeName] do
        for _, cb in ipairs(callbackList) do
          local retOK = pcall(cb, ...)
          if not retOK then
            module:Disable()
            private:PrintSkinRuntimeError(module:GetName())
          end
        end
      end
    end)
    registerHook(ScriptObject, scriptTypeName)
  end

  -- Register the hook in the module registry for easy unhooking.
  registerModuleHook(self, id, ScriptObject, scriptTypeName)
end

------------------------------
--- hooksecurefunc Wrapper ---
------------------------------

--- Wrapper around hooksecurefunc.
--- This allows multiple callbacks per module for a given function hook.
--- @param arg1 table|string  The table where the function is stored, or the function name if omitted (defaults to _G).
--- @param arg2 string|function  The name of the function to hook, or the callback if arg1 is a string.
--- @param arg3 function|string  The callback function or method name (as a string) to be called.
function HookRegistry:HookFunc(arg1, arg2, arg3)
  local obj, func_name, callback_func
  if type(arg1) == "table" then
    obj = arg1
    func_name = arg2
    callback_func = arg3
  else
    obj = _G
    func_name = arg1
    callback_func = arg2
  end

  local id = getHookID(self, obj, func_name)
  local callback = wrapCallback(self, callback_func)
  prepareCallbackTable(obj, func_name)

  -- Ensure there is a list to hold multiple callbacks for this module.
  if not callbacks[obj][func_name][self] then
    callbacks[obj][func_name][self] = {}
  end
  table.insert(callbacks[obj][func_name][self], callback)

  -- Hook the function if it hasn't been hooked already.
  if not isHooked(obj, func_name) then
    hooksecurefunc(obj, func_name, function(...)
      for module, callbackList in next, callbacks[obj][func_name] do
        for _, cb in ipairs(callbackList) do
          local retOK = pcall(cb, ...)
          if not retOK then
            module:Disable()
            private:PrintSkinRuntimeError(module:GetName())
          end
        end
      end
    end)
    registerHook(obj, func_name)
  end

  -- Register the hook in the module registry for easy unhooking.
  registerModuleHook(self, id, obj, func_name)
end

--------------
--- Unhook ---
--------------

--- Unhook a previously hooked script or function.
--- This removes all callbacks associated with the module for the given hook.
--- (Note that the underlying hook remains in place, as unhooking is not possible in WoW.)
--- @param arg1 any  Either the hooked ScriptObject (table) or the hooked function name (string).
--- @param arg2 any  If arg1 is a table, then arg2 is the function/script name to unhook.
function HookRegistry:Unhook(arg1, arg2)
  if not registry[self] then
    return
  end

  local obj, func_name
  if type(arg1) == "table" then
    obj = arg1
    func_name = arg2
  else
    obj = _G
    func_name = arg1
  end

  local id = getHookID(self, obj, func_name)
  local entry = registry[self][id]
  if not entry then
    -- No hook registered for this module on the given object/function.
    return
  end

  -- Remove all callbacks for this module for the given hook.
  if callbacks[entry.key1] and callbacks[entry.key1][entry.key2] then
    callbacks[entry.key1][entry.key2][self] = nil
  end

  -- Clean up the module's registry entry.
  registry[self][id] = nil
  if next(registry[self]) == nil then
    registry[self] = nil
  end
end

--- Disable all hooks for the module.
--- This removes all callbacks that the module has registered.
--- (The underlying hooks remain active.)
function HookRegistry:DisableHooks()
  if not registry[self] then
    return
  end

  for id, entry in next, registry[self] do
    if callbacks[entry.key1] and callbacks[entry.key1][entry.key2] then
      callbacks[entry.key1][entry.key2][self] = nil
    end
    registry[self][id] = nil
  end
  registry[self] = nil
end


