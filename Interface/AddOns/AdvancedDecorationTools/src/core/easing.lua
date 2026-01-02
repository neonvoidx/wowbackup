local ADDON_NAME, ADT = ...
ADT = ADT or {}
ADT.EasingFunctions = ADT.EasingFunctions or {}
local API = ADT.API or {}

function ADT.EasingFunctions.outQuart(t, b, c, d)
    t = t / d - 1
    return -c * (t*t*t*t - 1) + b
end

function ADT.EasingFunctions.outQuint(t, b, c, d)
    t = t / d - 1
    return c * (t*t*t*t*t + 1) + b
end

-- 简易弹簧
function API.SpringStep(x, v, target, stiffness, damping, dt)
    stiffness = tonumber(stiffness) or 260
    damping   = tonumber(damping)   or 28
    dt = math.min(math.max(dt or 0, 0), 1/30)
    local a = -stiffness * (x - target) - damping * v
    v = v + a * dt
    x = x + v * dt
    return x, v
end

function API.CreateSpringDriver(opts, onUpdate)
    local driver = {}
    driver.x = (opts and opts.x) or 0
    driver.v = 0
    driver.target = (opts and opts.target) or driver.x
    driver.stiffness = (opts and opts.stiffness) or 280
    driver.damping = (opts and opts.damping) or 30
    driver.onUpdate = onUpdate
    function driver:SetTarget(t) self.target = tonumber(t) or 0; self:_ensureTick() end
    function driver:_tick(_, elapsed)
        local nx, nv = API.SpringStep(self.x, self.v, self.target, self.stiffness, self.damping, elapsed)
        self.x, self.v = nx, nv
        if self.onUpdate then pcall(self.onUpdate, self.x) end
        if math.abs(self.x - self.target) < 0.5 and math.abs(self.v) < 2 then
            self.x = self.target; self.v = 0
            if self.onUpdate then pcall(self.onUpdate, self.x) end
            self:_stopTick()
        end
    end
    function driver:_ensureTick()
        if self.frame and not self.ticking then
            self.ticking = true
            self.frame:SetScript("OnUpdate", function(_, e) driver:_tick(_, e) end)
        end
    end
    function driver:_stopTick()
        if self.frame and self.ticking then
            self.ticking = false
            self.frame:SetScript("OnUpdate", nil)
        end
    end
    function driver:AttachFrame(frame)
        self.frame = frame
        if self.ticking then
            self.frame:SetScript("OnUpdate", function(_, e) driver:_tick(_, e) end)
        end
    end
    return driver
end

