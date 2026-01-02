local ADDON_NAME, ADT = ...
ADT = ADT or {}
ADT.API = ADT.API or {}
local API = ADT.API

-- 轻量通用 API（单一权威，供 UI/功能层复用）

function API.Mixin(object, ...)
    for i = 1, select('#', ...) do
        local mixin = select(i, ...)
        for k, v in pairs(mixin) do
            object[k] = v
        end
    end
    return object
end

function API.Round(n) return math.floor((n or 0) + 0.5) end

function API.Clamp(v, a, b)
    if v > b then return b elseif v < a then return a end
    return v
end

function API.Saturate(x)
    if x < 0 then return 0 elseif x > 1 then return 1 else return x end
end

function API.Lerp(a, b, t) return (1 - t) * (a or 0) + (t or 0) * (b or 0) end

function API.DisableSharpening(obj)
    if not obj then return end
    if obj.SetSnapToPixelGrid then pcall(obj.SetSnapToPixelGrid, obj, false) end
    if obj.SetTexelSnappingBias then pcall(obj.SetTexelSnappingBias, obj, 0) end
end

function API.StringTrim(str)
    if not str or str == "" then return nil end
    return str:match("^%s*(.-)%s*$")
end

-- 简单对象池（UI 复用）
function API.CreateObjectPool(createFunc, onAcquire, onRelease)
    local pool = {}
    local free, used = {}, {}
    local function attachRelease(obj)
        obj.Release = function(o)
            for i, v in ipairs(used) do
                if v == o then
                    table.remove(used, i)
                    if onRelease then onRelease(o) end
                    o:Hide(); o:ClearAllPoints()
                    free[#free+1] = o
                    break
                end
            end
        end
    end
    function pool:Acquire()
        local obj = table.remove(free)
        if not obj then obj = createFunc() end
        used[#used+1] = obj
        attachRelease(obj)
        obj:Show()
        if onAcquire then onAcquire(obj) end
        return obj
    end
    function pool:ReleaseAll()
        if #used == 0 then return end
        for i = #used, 1, -1 do
            local obj = used[i]
            if onRelease then onRelease(obj) end
            obj:Hide(); obj:ClearAllPoints()
            free[#free+1] = obj
            used[i] = nil
        end
    end
    function pool:EnumerateActive() return ipairs(used) end
    function pool:CallMethod(method, ...)
        for _, obj in ipairs(used) do
            local fn = obj and obj[method]
            if fn then fn(obj, ...) end
        end
    end
    return pool
end

