-- ManaRise - Minimap.lua
-- A small draggable button on the minimap edge.
--   Left-click: options panel.  Right-click: a small menu (options,
--   unlock/lock the position, reset the position, hide the button).
--   Drag: move it around the minimap, only while the position is unlocked.
--   /mr minimap on|off shows or hides it.
-- The button is a plain frame (no secure code). It is created out of combat
-- only, and while it is being dragged one OnUpdate follows the cursor; the
-- script is removed again when the drag ends, so nothing runs per frame
-- otherwise.

local _, ns = ...
local L = ns.L

local M = {}
ns.Minimap = M

local SIZE = 31

local function Settings() return ns.root and ns.root.minimap end

-- Place the button on the minimap edge at the saved angle (degrees).
function M:Position()
    local btn, set = self.button, Settings()
    if not btn or not set or not Minimap then return end
    local angle = math.rad(set.angle or 215)
    local cx, cy = math.cos(angle), math.sin(angle)
    local half = (Minimap:GetWidth() or 140) / 2
    local x, y
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    if shape == "SQUARE" then
        -- square minimaps (e.g. ElvUI): slide along the edge
        local k = half * 1.4142
        x = math.max(-half, math.min(half, cx * k))
        y = math.max(-half, math.min(half, cy * k))
    else
        x, y = cx * (half + 5), cy * (half + 5)
    end
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function FollowCursor()
    local set = Settings()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    if not (set and mx and cx) then return end
    local scale = Minimap:GetEffectiveScale()
    set.angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx)) % 360
    M:Position()
end

---------------------------------------------------------------------------
-- Right-click menu: plain frames, no Blizzard dropdown code. A transparent
-- full-screen button behind it closes the menu on any outside click.
---------------------------------------------------------------------------
local ROW_H, MENU_W, PAD = 19, 170, 12
local TITLE_H, SEP_H = 22, 12
local GOLD = { 1, 0.82, 0 }

local function CloseMenu()
    if M.menu then M.menu:Hide(); M.catcher:Hide() end
end

local function MenuItems()
    local set = Settings()
    return {
        { L.MM_MENU_OPTIONS, function() ns.Options:Open() end },
        { set.locked and L.MM_MENU_UNLOCK or L.MM_MENU_LOCK, function()
            set.locked = not set.locked
            ns:Print(set.locked and L.MM_LOCKED or L.MM_UNLOCKED)
        end },
        { L.MM_MENU_RESET, function() set.angle = 215; M:Position() end },
        { L.MM_MENU_HIDE, function()
            ns:SetOption("minimap", false)
            ns:Print(L.MM_HIDDEN_HINT)
        end },
    }
end

local function BuildMenu()
    local catcher = CreateFrame("Button", "ManaRiseMinimapMenuCatcher", UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("DIALOG")
    catcher:RegisterForClicks("AnyUp")
    catcher:SetScript("OnClick", CloseMenu)
    catcher:Hide()

    -- Same frame style as the game's own mouse-over tooltip: try the tooltip
    -- backdrop template, then a plain backdrop with the tooltip textures, then
    -- flat textures.
    local menu
    local ok, f = pcall(CreateFrame, "Frame", "ManaRiseMinimapMenu", UIParent, "TooltipBackdropTemplate")
    if ok and f then menu = f end
    if not menu then
        local tpl = BackdropTemplateMixin and "BackdropTemplate" or nil
        menu = CreateFrame("Frame", "ManaRiseMinimapMenu", UIParent, tpl)
        if menu.SetBackdrop then
            menu:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 },
            })
            menu:SetBackdropColor(0, 0, 0, 0.95)
            menu:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
        else
            local bg = menu:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(menu)
            bg:SetColorTexture(0, 0, 0, 0.95)
        end
    end
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetSize(MENU_W, PAD + TITLE_H + ROW_H * 4 + SEP_H + PAD - 6)
    menu:EnableMouse(true)

    local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", menu, "TOPLEFT", PAD, -PAD)
    title:SetText("ManaRise")
    title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    menu.title = title

    local sep = menu:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(0.4, 0.4, 0.4, 0.6)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", menu, "TOPLEFT", PAD, -(PAD + TITLE_H + ROW_H + SEP_H / 2))
    sep:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -PAD, -(PAD + TITLE_H + ROW_H + SEP_H / 2))

    menu.rows = {}
    for i = 1, 4 do
        local y = PAD + TITLE_H + (i - 1) * ROW_H + (i > 1 and SEP_H or 0)
        local row = CreateFrame("Button", nil, menu)
        row:SetSize(MENU_W - PAD * 2, ROW_H)
        row:SetPoint("TOPLEFT", menu, "TOPLEFT", PAD, -y)
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
        row:SetScript("OnEnter", function(self) self.label:SetTextColor(GOLD[1], GOLD[2], GOLD[3]) end)
        row:SetScript("OnLeave", function(self) self.label:SetTextColor(1, 1, 1) end)
        row:SetScript("OnClick", function(self)
            CloseMenu()
            if self.action then self.action() end
        end)
        menu.rows[i] = row
    end
    menu:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, "ManaRiseMinimapMenu") end
    M.menu, M.catcher = menu, catcher
end

function M:OpenMenu()
    if ns:InCombat() and not self.menu then return end   -- build it out of combat only
    if not self.menu then BuildMenu() end
    local items = MenuItems()
    for i, row in ipairs(self.menu.rows) do
        row.label:SetText(items[i][1])
        row.action = items[i][2]
        row.label:SetTextColor(1, 1, 1)
    end
    if GameTooltip then GameTooltip:Hide() end
    self.menu:ClearAllPoints()
    local bx = self.button:GetCenter()
    local sw = UIParent:GetWidth() or 0
    if bx and sw > 0 and bx > sw / 2 then
        self.menu:SetPoint("TOPRIGHT", self.button, "BOTTOM", 8, 4)   -- near the right edge: open leftwards
    else
        self.menu:SetPoint("TOPLEFT", self.button, "BOTTOM", -8, 4)
    end
    self.catcher:Show()
    self.menu:Show()
end

local function ShowTooltip(btn)
    if not GameTooltip then return end
    GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
    GameTooltip:AddLine("ManaRise v" .. tostring(ns.version))
    GameTooltip:AddLine(ns.db and ns.db.enabled and L.ENABLED or L.DISABLED, 1, 1, 1)
    GameTooltip:AddLine(L.MM_LEFT)
    GameTooltip:AddLine(L.MM_MENU_HINT)
    if not (Settings() and Settings().locked) then GameTooltip:AddLine(L.MM_DRAG) end
    GameTooltip:Show()
end

local function Build()
    local btn = CreateFrame("Button", "ManaRiseMinimapButton", Minimap)
    btn:SetSize(SIZE, SIZE)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\ManaRise\\Media\\minimap_icon")
    icon:SetSize(19, 19)
    icon:SetPoint("CENTER", btn, "CENTER", 0, 1)
    btn.icon = icon

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT")

    local hover = btn:CreateTexture(nil, "HIGHLIGHT")
    hover:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    hover:SetBlendMode("ADD")
    hover:SetAllPoints(btn)

    btn:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            M:OpenMenu()
        elseif ns.Options then
            ns.Options:Open()
        end
    end)
    btn:SetScript("OnDragStart", function(self)
        if Settings().locked then return end
        if GameTooltip then GameTooltip:Hide() end
        self:SetScript("OnUpdate", FollowCursor)
    end)
    btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    btn:SetScript("OnEnter", ShowTooltip)
    btn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    return btn
end

-- Create (out of combat) and show or hide according to the saved setting.
function M:Update()
    local set = Settings()
    if not set or not Minimap then return end
    if not self.button then
        if ns:InCombat() or set.hide then return end   -- build it when first needed
        self.button = Build()
        self:Position()
    end
    if set.hide then CloseMenu() end
    if set.hide then self.button:Hide() else self.button:Show(); self:Position() end
end
