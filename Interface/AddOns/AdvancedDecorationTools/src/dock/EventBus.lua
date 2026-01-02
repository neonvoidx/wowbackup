-- EventBus.lua
-- DockUI 事件总线：解耦 View 与 Controller 的双向依赖
-- 设计原则：单向数据流，View 发出事件 → Controller 监听并响应

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

-- ============================================================================
-- EventBus 单例
-- ============================================================================

local EventBus = {}
EventBus._handlers = {}
EventBus._pendingEvents = {}

ADT.EventBus = EventBus

-- ============================================================================
-- 事件定义（集中管理）
-- ============================================================================

--- 分类切换事件
--- @field CATEGORY_SELECTED 用户选择分类（从 LeftPanel 点击）
---   参数: categoryKey, categoryType
EventBus.Events = {
    -- 分类相关
    CATEGORY_SELECTED = "CATEGORY_SELECTED",
    CATEGORY_RENDERED = "CATEGORY_RENDERED",
    
    -- 数据变化
    CLIPBOARD_CHANGED = "CLIPBOARD_CHANGED",
    HISTORY_CHANGED = "HISTORY_CHANGED",
    DYE_PRESET_CHANGED = "DYE_PRESET_CHANGED",
    
    -- UI 状态
    DOCK_SHOWN = "DOCK_SHOWN",
    DOCK_HIDDEN = "DOCK_HIDDEN",
    LANGUAGE_CHANGED = "LANGUAGE_CHANGED",
    
    -- 设置变化
    SETTING_CHANGED = "SETTING_CHANGED",
}

-- ============================================================================
-- 核心 API
-- ============================================================================

--- 注册事件处理器
--- @param event string 事件名称
--- @param handler function 处理函数
--- @param priority number|nil 优先级（数字越小越先执行，默认 100）
--- @return function 返回取消注册的函数
function EventBus:Register(event, handler, priority)
    if not event or not handler then return function() end end
    
    priority = priority or 100
    self._handlers[event] = self._handlers[event] or {}
    
    local entry = { handler = handler, priority = priority }
    table.insert(self._handlers[event], entry)
    
    -- 按优先级排序
    table.sort(self._handlers[event], function(a, b)
        return a.priority < b.priority
    end)
    
    -- 返回取消注册函数
    return function()
        self:Unregister(event, handler)
    end
end

--- 取消注册事件处理器
--- @param event string 事件名称
--- @param handler function 处理函数
function EventBus:Unregister(event, handler)
    if not self._handlers[event] then return end
    
    for i = #self._handlers[event], 1, -1 do
        if self._handlers[event][i].handler == handler then
            table.remove(self._handlers[event], i)
            break
        end
    end
end

--- 触发事件
--- @param event string 事件名称
--- @param ... any 事件参数
function EventBus:Fire(event, ...)
    if not self._handlers[event] then return end
    
    if ADT.DebugPrint then
        ADT.DebugPrint(string.format("[EventBus] Fire: %s", event))
    end
    
    for _, entry in ipairs(self._handlers[event]) do
        local ok, err = pcall(entry.handler, ...)
        if not ok and ADT.DebugPrint then
            ADT.DebugPrint(string.format("[EventBus] Error in %s handler: %s", event, tostring(err)))
        end
    end
end

--- 延迟触发事件（下一帧执行）
--- @param event string 事件名称
--- @param ... any 事件参数
function EventBus:FireDeferred(event, ...)
    local args = {...}
    C_Timer.After(0, function()
        self:Fire(event, unpack(args))
    end)
end

--- 清除指定事件的所有处理器
--- @param event string 事件名称
function EventBus:ClearEvent(event)
    self._handlers[event] = nil
end

--- 清除所有事件处理器
function EventBus:ClearAll()
    wipe(self._handlers)
end

-- ============================================================================
-- 便捷注册方法（链式调用）
-- ============================================================================

--- 监听分类选择事件
--- @param handler function(categoryKey, categoryType)
--- @return function 取消注册函数
function EventBus:OnCategorySelected(handler)
    return self:Register(self.Events.CATEGORY_SELECTED, handler)
end

--- 监听语言变化事件
--- @param handler function()
--- @return function 取消注册函数
function EventBus:OnLanguageChanged(handler)
    return self:Register(self.Events.LANGUAGE_CHANGED, handler)
end

--- 监听设置变化事件
--- @param handler function(key, value)
--- @return function 取消注册函数
function EventBus:OnSettingChanged(handler)
    return self:Register(self.Events.SETTING_CHANGED, handler)
end

-- ============================================================================
-- 调试工具
-- ============================================================================

--- 打印当前注册的处理器
function EventBus:DumpHandlers()
    print("|cFF00FF00[ADT EventBus] Registered handlers:|r")
    for event, handlers in pairs(self._handlers) do
        print(string.format("  %s: %d handlers", event, #handlers))
    end
end

-- ============================================================================
-- 导出
-- ============================================================================

ADT.EventBus = EventBus

return EventBus
