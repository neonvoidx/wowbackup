-- Azta'rec Helper, copyright 2026 Rothirr, all rights reserved.
-- Read it if you want. Copying any of it into another addon is theft, and
-- running it through an AI tool first does not change that. The timings and
-- coordinates were measured by hand. Nothing here is licensed to anyone.

local _, AZT = ...

-- Shared plumbing for the floating windows.

--#region Art
-- An svg from Media on the given parent and layer. A 12.1 client draws
-- these straight from disk, a 12.0 client has no CreateVectorGraphics and
-- gets a flat white square that tints the same way, so nothing else has
-- to care which it got
local MEDIA = "Interface\\AddOns\\AztarecHelper\\Media\\"

function AZT.SvgArt(parent, file, layer)
    if parent.CreateVectorGraphics then
        local v = parent:CreateVectorGraphics()
        v:SetSVG(MEDIA .. file)
        v:SetDrawLayer(layer)
        return v
    end
    local t = parent:CreateTexture(nil, layer)
    t:SetColorTexture(1, 1, 1)
    return t
end
--#endregion

--#region Locks
-- Each floating window carries a padlock in its corner. A locked window
-- can't be dragged and lets clicks pass through it. Only the padlock itself,
-- the room view's buttons and the quarter icon menus still take the mouse.
-- While locked the padlock hides until the cursor crosses it.

local lockApply = {}

local function locks()
    AztarecHelperDB.locks = AztarecHelperDB.locks or {}
    return AztarecHelperDB.locks
end

function AZT.AttachLock(frame, key, alsoUnclick, ox, oy)
    local btn = CreateFrame("Button", nil, frame)
    btn:SetSize(16, 16)
    btn:SetPoint("TOPRIGHT", ox or -3, oy or -3)
    btn:SetNormalTexture("Interface\\AddOns\\AztarecHelper\\Media\\lock")
    btn:SetHighlightTexture("Interface\\AddOns\\AztarecHelper\\Media\\lock", "ADD")

    local function apply()
        local locked = locks()[key] and true or false
        frame:EnableMouse(not locked)
        for _, f in ipairs(alsoUnclick or {}) do
            f:EnableMouse(not locked)
        end
        btn:SetAlpha(locked and 0 or 0.85)
    end
    btn:SetScript("OnClick", function()
        locks()[key] = not locks()[key] or nil
        apply()
        btn:SetAlpha(1) -- the cursor is still on it so keep it readable
    end)
    btn:SetScript("OnEnter", function()
        btn:SetAlpha(1)
    end)
    btn:SetScript("OnLeave", function()
        btn:SetAlpha(locks()[key] and 0 or 0.85)
    end)
    lockApply[key] = apply
    apply()
end

function AZT.GetWindowLock(key)
    return locks()[key] and true or false
end

function AZT.SetWindowLock(key, v)
    locks()[key] = v and true or nil
    if lockApply[key] then
        lockApply[key]()
    end
end
--#endregion

--#region Dragging and size

-- Each floating window has a size of its own, keyed the same way as its
-- lock and saved under its position as "<key>Pos". Anchor offsets are kept
-- in screen units rather than the window's own scaled ones, so resizing
-- leaves the anchor where it was and the window grows around that point
-- instead of slidng off toward it. Positions saved before the sizes existed were
-- written at scale 1, which is the same thing, so nothing needs migrating.
local windows = {}

local function scale(key)
    return AztarecHelperDB.windowScale[key] or 1
end

local function place(w)
    local s = scale(w.key)
    local pos = AztarecHelperDB[w.key .. "Pos"]
    w.frame:ClearAllPoints()
    if pos and pos.point then
        w.frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, (pos.x or 0) / s, (pos.y or 0) / s)
    else
        w.frame:SetPoint(w.defPoint, UIParent, w.defPoint, w.defX / s, w.defY / s)
    end
end

-- shared drag wiring for the floating windows
function AZT.MakeMovable(frame, key, defPoint, defX, defY)
    local w = { frame = frame, key = key, defPoint = defPoint, defX = defX, defY = defY }
    windows[key] = w
    frame:SetScale(scale(key))
    place(w)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local point, _, relPoint, x, y = f:GetPoint(1)
        local s = scale(key)
        AztarecHelperDB[key .. "Pos"] = { point = point, relPoint = relPoint, x = x * s, y = y * s }
    end)
end

function AZT.GetWindowScale(key)
    return scale(key)
end

-- a window not built yet picks its size up in MakeMovable
function AZT.SetWindowScale(key, v)
    AztarecHelperDB.windowScale[key] = v
    local w = windows[key]
    if w then
        w.frame:SetScale(v)
        place(w)
    end
end
--#endregion
