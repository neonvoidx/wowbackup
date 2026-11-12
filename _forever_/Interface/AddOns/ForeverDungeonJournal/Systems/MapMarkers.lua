local ADDON_NAME, FDJ = ...
FDJ = FDJ or _G.ForeverDungeonJournal_NS
local QUEST_START_MAPS = FDJ.QUEST_START_MAPS or {}
local function L(key, ...)
    if FDJ and FDJ.L then return FDJ.L(key, ...) end
    return key
end
local function FreeText(text)
    return FDJ.LocalizeFreeText and FDJ.LocalizeFreeText(text) or text
end

-- Forever currently exposes the map canvas, but its user-waypoint API is not
-- reliable. Use our own pins on the Blizzard map instead of C_Map.SetUserWaypoint.
-- Multiple pins are kept at once so players can mark several quest givers/starts
-- before planning a route through the zone.
local mapTargets = {}
local mapMarkers = {}
local questStartMapTicker

-- Optional full-route overlay used by travel guides. The route is stored as a
-- series of zone-local points and translated to the requested continent map.
local activeRouteMap
local routeOverlayParent
local routeOverlayCanvas
local routeOverlayFrame
local routeOverlayLines = {}
local routeOverlayShadows = {}
local routeOverlayDots = {}

-- Quest-giver raid-target priority requested for navigation:
-- Blue Square, Diamond, Triangle, Circle, Skull, Moon, Star.
-- Red X is intentionally skipped.
local QUEST_GIVER_MARK_PRIORITY = { 6, 3, 4, 2, 8, 5, 1 }
local QUEST_GIVER_MARK_NAMES = {
    [1] = "Star",
    [2] = "Circle",
    [3] = "Diamond",
    [4] = "Triangle",
    [5] = "Moon",
    [6] = "Square",
    [8] = "Skull",
}

local function GetWorldMapCanvasChild()
    if not WorldMapFrame then return nil end
    if type(WorldMapFrame.GetCanvas) == "function" then
        local ok, canvas = pcall(WorldMapFrame.GetCanvas, WorldMapFrame)
        if ok and canvas then return canvas end
    end
    if WorldMapFrame.ScrollContainer then
        return WorldMapFrame.ScrollContainer.Child or WorldMapFrame.ScrollContainer
    end
    return nil
end

local function TargetKey(loc)
    if not loc then return nil end
    return table.concat({
        tostring(loc.mapID or ""),
        string.format("%.5f", tonumber(loc.x) or 0),
        string.format("%.5f", tonumber(loc.y) or 0),
        tostring(loc.markerType or "quest"),
        tostring(loc.label or "")
    }, "|")
end

local function IsTargetableNPCMarker(target)
    if not target then return false end
    return target.markerType ~= "dungeon" and target.markerType ~= "location"
end

local function RemoveTarget(target)
    if not target then return end
    local key = target._fdjKey or TargetKey(target)
    if key then mapTargets[key] = nil end
    if FDJ.ClearWaypointArrow then FDJ.ClearWaypointArrow(target) end -- arrow
    local marker = key and mapMarkers[key]
    if marker then
        marker:Hide()
        marker.target = nil
    end
    GameTooltip:Hide()
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd36bDungeonJournal:|r " .. L("MAP_MARKER_REMOVED"))
    end
end

local function QuestGiverName(target)
    if not IsTargetableNPCMarker(target) then return nil end
    local name = target.targetName or target.label
    if type(name) ~= "string" then return nil end
    -- Labels may include a location after an em dash, e.g.
    -- "Guard Berton — Lakeshire". Only the NPC name belongs in /targetexact.
    name = name:match("^%s*(.-)%s+—%s+.+$") or name
    name = name:gsub("[\r\n]", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end
    return name
end

local function RaidMarkIndexForTarget(target)
    local npcName = QuestGiverName(target)
    if not npcName then return nil end

    -- Reuse the same icon when two active quest pins point at the same NPC.
    local used = {}
    for _, active in pairs(mapTargets) do
        if active and IsTargetableNPCMarker(active) then
            local activeName = QuestGiverName(active)
            if activeName == npcName and active.raidMarkIndex then
                return active.raidMarkIndex
            end
            if active.raidMarkIndex then
                used[active.raidMarkIndex] = true
            end
        end
    end

    for _, index in ipairs(QUEST_GIVER_MARK_PRIORITY) do
        if not used[index] then return index end
    end
    return nil
end

local function PlayerIsNearRecordedLocation(target)
    if not target or not target.mapID or not C_Map then return false end
    if type(C_Map.GetBestMapForUnit) ~= "function" or type(C_Map.GetPlayerMapPosition) ~= "function" then
        return false
    end

    local okMap, playerMapID = pcall(C_Map.GetBestMapForUnit, "player")
    if not okMap or not playerMapID or playerMapID ~= target.mapID then return false end

    local okPos, pos = pcall(C_Map.GetPlayerMapPosition, target.mapID, "player")
    if not okPos or not pos then return false end

    local px, py
    if type(pos.GetXY) == "function" then
        local okXY, x, y = pcall(pos.GetXY, pos)
        if okXY then px, py = x, y end
    elseif type(pos.x) == "number" and type(pos.y) == "number" then
        px, py = pos.x, pos.y
    end
    if type(px) ~= "number" or type(py) ~= "number" then return false end

    local dx = px - (tonumber(target.x) or 0)
    local dy = py - (tonumber(target.y) or 0)
    -- Keep automatic targeting deliberately short-range. The recorded map point
    -- is for navigation; once the player is roughly within local targeting range
    -- we enable /targetexact. Distant Show on Map clicks remain map-only.
    return (dx * dx + dy * dy) <= (0.04 * 0.04)
end

local function BuildTargetAndMarkMacro(target)
    local npcName = QuestGiverName(target)
    if not npcName then return nil, nil end
    local markIndex = target.raidMarkIndex or RaidMarkIndexForTarget(target)
    if not markIndex then return nil, nil end

    -- Keep targeting and raid marking inside the hardware-click macro. The '~'
    -- form applies the icon only when the target does not already have one, so
    -- repeated clicks never toggle an existing marker off. This also avoids
    -- reading UnitName/GetRaidTargetIndex values that may be secret on Forever.
    local text = "/targetexact " .. npcName .. "\n/tm ~" .. tostring(markIndex)
    return text, markIndex
end

local function ApplyQuestGiverRaidMark(button, target)
    -- Targeting and marking are handled by the secure click macro above. Do not
    -- inspect UnitName/GetRaidTargetIndex here: those values can be secret on
    -- tainted execution paths and comparing them raises a Lua error.
end

local function ConfigureTargetAndMarkAction(button, target, requireNearby)
    if not button or not button._fdjCanTarget then return end
    if InCombatLockdown and InCombatLockdown() then
        button._fdjPendingTarget = target
        return
    end

    button._fdjPendingTarget = nil
    if not IsTargetableNPCMarker(target) or (requireNearby and not PlayerIsNearRecordedLocation(target)) then
        button:SetAttribute("type1", nil)
        button:SetAttribute("macrotext1", nil)
        button:SetAttribute("macrotext", nil)
        button._fdjTargetName = nil
        button._fdjRaidMarkIndex = nil
        button._fdjTargetEnabled = false
        return
    end

    local macroText, markIndex = BuildTargetAndMarkMacro(target)
    if macroText then
        button:SetAttribute("type1", "macro")
        button:SetAttribute("macrotext1", macroText)
        button:SetAttribute("useOnKeyDown", false)
        button._fdjTargetName = QuestGiverName(target)
        button._fdjRaidMarkIndex = markIndex
        button._fdjTargetEnabled = true
    else
        button:SetAttribute("type1", nil)
        button:SetAttribute("macrotext1", nil)
        button:SetAttribute("macrotext", nil)
        button._fdjTargetName = nil
        button._fdjRaidMarkIndex = nil
        button._fdjTargetEnabled = false
    end
end

local function ConfigureMarkerTargetAction(marker, target)
    -- Map pins should only try to target when the player is close to the recorded
    -- quest giver. Distant pins remain navigation-only and produce no target error.
    ConfigureTargetAndMarkAction(marker, target, true)
end

-- The dungeon entrance icon is drawn this much larger than the Blizzard
-- "Dungeon" atlas' native size (which is what the old marker showed).
local DUNGEON_ENTRANCE_ICON_SCALE = 1.4
local DUNGEON_ENTRANCE_ICON_FALLBACK = 24

-- Turn-in pins use the game's own quest button for a quest to hand in (as
-- on the world map and in the objective tracker): round dark button with a
-- gold ring and the yellow ?, lit up on mouse-over. A game without that art
-- gets the journal's own drawing of it (Media/TurnInMark.tga).
-- (One table, not separate locals: this file is at Lua's 200-local limit.)
local TURN_IN = {
    size = 38,
    ring = "UI-QuestPoi-QuestNumber",
    lit = "UI-QuestPoi-InnerGlow",
    icon = "UI-QuestIcon-TurnIn-Normal",
    art = "Interface\\AddOns\\ForeverDungeonJournal\\Media\\TurnInMark",
}
function TURN_IN.HasAtlas()
    if TURN_IN.hasAtlas == nil then
        local get = C_Texture and C_Texture.GetAtlasInfo
        local ok = type(get) == "function"
        for _, atlas in ipairs({ TURN_IN.ring, TURN_IN.lit, TURN_IN.icon }) do
            if ok then
                local fine, info = pcall(get, atlas)
                ok = fine and info ~= nil
            end
        end
        TURN_IN.hasAtlas = ok
    end
    return TURN_IN.hasAtlas
end

local function CreateMapMarker(key)
    local parent = GetWorldMapCanvasChild()
    if not parent then return nil end

    -- Use the insecure action template when available so a real hardware click can
    -- run /targetexact without turning the Blizzard world-map canvas into a
    -- protected frame. It only performs the target action out of combat.
    local marker
    local ok, created = pcall(CreateFrame, "Button", nil, parent, "InsecureActionButtonTemplate")
    if ok and created then
        marker = created
        marker._fdjCanTarget = true
    else
        marker = CreateFrame("Button", nil, parent)
        marker._fdjCanTarget = false
    end
    marker:SetSize(44, 44)
    marker:SetFrameLevel(10000)
    marker:EnableMouse(true)
    marker._fdjKey = key

    -- Dark disc behind the X so it reads on pale parts of the map.
    marker.backing = marker:CreateTexture(nil, "BACKGROUND", nil, -2)
    marker.backing:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    marker.backing:SetVertexColor(0, 0, 0, 0.62)
    marker.backing:SetSize(32, 32)
    marker.backing:SetPoint("CENTER")

    -- Soft ring that ripples outwards, so the pin catches the eye.
    marker.pulse = marker:CreateTexture(nil, "BACKGROUND", nil, -3)
    marker.pulse:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    marker.pulse:SetVertexColor(1.00, 0.30, 0.10, 0.55)
    marker.pulse:SetBlendMode("ADD")
    marker.pulse:SetSize(32, 32)
    marker.pulse:SetPoint("CENTER")
    -- The ring rests invisible; each ripple fades in, expands and fades out,
    -- then pauses. Nothing snaps back into view when the loop restarts.
    marker.pulse:SetAlpha(0)
    pcall(function()
        local group = marker.pulse:CreateAnimationGroup()
        group:SetLooping("REPEAT")
        local grow = group:CreateAnimation("Scale")
        grow:SetDuration(1.8)
        if grow.SetScaleFrom then grow:SetScaleFrom(0.9, 0.9); grow:SetScaleTo(2.0, 2.0) else grow:SetScale(2.0, 2.0) end
        grow:SetOrigin("CENTER", 0, 0)
        grow:SetEndDelay(0.7)
        local fadeIn = group:CreateAnimation("Alpha")
        fadeIn:SetDuration(0.45)
        fadeIn:SetFromAlpha(0)
        fadeIn:SetToAlpha(0.55)
        local fadeOut = group:CreateAnimation("Alpha")
        fadeOut:SetStartDelay(0.45)
        fadeOut:SetDuration(1.35)
        fadeOut:SetFromAlpha(0.55)
        fadeOut:SetToAlpha(0)
        fadeOut:SetEndDelay(0.7)
        marker.pulseAnim = group
    end)

    marker.glow = marker:CreateFontString(nil, "BACKGROUND", "GameFontNormalLarge")
    marker.glow:SetPoint("CENTER", marker, "CENTER", 0, 0)
    marker.glow:SetText("X")
    marker.glow:SetTextColor(1.00, 0.82, 0.20, 0.32)
    marker.glow:SetScale(1.80)

    marker.outline = {}
    local offsets = { {-1, 0}, {1, 0}, {0, -1}, {0, 1} }
    for i = 1, #offsets do
        local shadow = marker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        shadow:SetPoint("CENTER", marker, "CENTER", offsets[i][1], offsets[i][2])
        shadow:SetText("X")
        shadow:SetTextColor(0, 0, 0, 1)
        shadow:SetScale(1.35)
        marker.outline[i] = shadow
    end

    marker.x = marker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    marker.x:SetPoint("CENTER", marker, "CENTER", 0, 0)
    marker.x:SetText("X")
    marker.x:SetTextColor(1.00, 0.88, 0.10, 1)
    marker.x:SetScale(1.35)

    -- Turn-in pin: the game's quest button instead of the X.
    do
        local button = CreateFrame("Frame", nil, marker)
        marker.turnInButton = button
        button:SetSize(TURN_IN.size, TURN_IN.size)
        button:SetPoint("CENTER")
        button:EnableMouse(false)
        if TURN_IN.HasAtlas() then
            button.ring = button:CreateTexture(nil, "ARTWORK")
            button.ring:SetAtlas(TURN_IN.ring)
            button.ring:SetSize(TURN_IN.size, TURN_IN.size)
            button.ring:SetPoint("CENTER")
            button.lit = button:CreateTexture(nil, "OVERLAY", nil, 1)
            button.lit:SetAtlas(TURN_IN.lit)
            button.lit:SetBlendMode("ADD")
            button.lit:SetSize(TURN_IN.size, TURN_IN.size)
            button.lit:SetPoint("CENTER")
            button.lit:Hide()
            button.icon = button:CreateTexture(nil, "OVERLAY", nil, 2)
            button.icon:SetAtlas(TURN_IN.icon)
            button.icon:SetSize(TURN_IN.size, TURN_IN.size)
            button.icon:SetPoint("CENTER")
        else
            button.icon = button:CreateTexture(nil, "OVERLAY")
            button.icon:SetTexture(TURN_IN.art)
            button.icon:SetSize(TURN_IN.size, TURN_IN.size)
            button.icon:SetPoint("CENTER")
        end
        button:Hide()
    end

    marker.dungeonIcon = marker:CreateTexture(nil, "OVERLAY")
    marker.dungeonIcon:SetPoint("CENTER")
    local atlasOK = false
    if marker.dungeonIcon.SetAtlas then
        atlasOK = pcall(marker.dungeonIcon.SetAtlas, marker.dungeonIcon, "Dungeon", true)
    end
    -- SetAtlas(..., true) resizes the texture to the atlas' small native size,
    -- which is why the entrance icon looked tiny. Force the size afterwards.
    local nativeSize = atlasOK and marker.dungeonIcon:GetWidth() or 0
    if not nativeSize or nativeSize < 8 then nativeSize = DUNGEON_ENTRANCE_ICON_FALLBACK / DUNGEON_ENTRANCE_ICON_SCALE end
    local iconSize = math.floor(nativeSize * DUNGEON_ENTRANCE_ICON_SCALE + 0.5)
    marker.dungeonIcon:SetSize(iconSize, iconSize)
    if not atlasOK then
        marker.dungeonIcon:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
        marker.dungeonIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    marker.dungeonIcon:Hide()

    marker.dungeonGlow = marker:CreateTexture(nil, "BACKGROUND")
    marker.dungeonGlow:SetPoint("CENTER")
    local glowAtlasOK = false
    if marker.dungeonGlow.SetAtlas then
        glowAtlasOK = pcall(marker.dungeonGlow.SetAtlas, marker.dungeonGlow, "Dungeon", true)
    end
    marker.dungeonGlow:SetSize(iconSize + 8, iconSize + 8)
    if not glowAtlasOK then
        marker.dungeonGlow:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
        marker.dungeonGlow:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    marker.dungeonGlow:SetBlendMode("ADD")
    marker.dungeonGlow:SetVertexColor(1.00, 0.86, 0.35, 0.42)
    marker.dungeonGlow:SetAlpha(0.55)
    marker.dungeonGlow:Hide()

    marker:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    if marker._fdjCanTarget then
        marker:SetAttribute("useOnKeyDown", false)
        -- PostClick preserves the action template's own click handler. The previous
        -- OnClick override was why left-click targeting never actually fired.
        marker:SetScript("PostClick", function(self, button)
            if button == "RightButton" then
                RemoveTarget(self.target)
            end
        end)
    else
        marker:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                RemoveTarget(self.target)
            end
        end)
    end
    marker:SetScript("OnEnter", function(self)
        local target = self.target
        if not target then return end
        -- Refresh immediately before the hardware click. This also picks up a
        -- newly assigned symbol after other quest pins have been added/removed.
        ConfigureMarkerTargetAction(self, target)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local labelText = FreeText(target.label)
        local detailText = FreeText(target.detail)
        -- Dungeon entrance markers: when the label has no translation of its own,
        -- build it from the translated dungeon name.
        if target.markerType == "dungeon" and type(target.label) == "string" and labelText == target.label then
            local dungeonName = target.label:gsub(" Entrance$", "")
            if FDJ.DB and not FDJ.DB[dungeonName] and FDJ.DB[dungeonName .. ": Graveyard"] then
                dungeonName = dungeonName .. ": Graveyard"
            end
            local localName = FDJ.LocalizeDungeonName and FDJ.LocalizeDungeonName(dungeonName) or dungeonName
            if FDJ.DB and FDJ.DB[dungeonName] and localName and localName ~= dungeonName then
                labelText = localName
                if detailText == target.detail then
                    local place = FDJ.LocalizeDungeonField and FDJ.LocalizeDungeonField(dungeonName, "location", nil)
                    detailText = L("DUNGEON_ENTRANCE")
                    if type(place) == "string" and place ~= "" then detailText = detailText .. ": " .. place end
                end
            end
        end
        -- Quest pins read "NPC — Quest title" instead of "NPC — place".
        if target.markerType ~= "dungeon" and type(target.questTitle) == "string" and target.questTitle ~= "" and type(labelText) == "string" then
            local dash = " \226\128\148 "
            local cut = labelText:find(dash, 1, true)
            local npc = cut and labelText:sub(1, cut - 1) or labelText
            labelText = npc .. dash .. target.questTitle
        end
        GameTooltip:SetText(labelText or (target.markerType == "dungeon" and L("DUNGEON_ENTRANCE") or L("QUEST_GIVER")))
        local fallbackDetail = target.markerType == "dungeon" and L("DUNGEON_ENTRANCE") or L("QUEST_STARTS_HERE")
        if target.turnIn then detailText, fallbackDetail = nil, L("TURN_IN_HERE") end
        GameTooltip:AddLine(detailText or fallbackDetail, 1, 0.82, 0.05)
        if type(target.patrol) == "table" then
            GameTooltip:AddLine(L("MAP_PATROL"), 1.00, 0.86, 0.35, true)
        end
        if IsTargetableNPCMarker(target) and self._fdjCanTarget then
            GameTooltip:AddLine(L("MAP_LEFT_TARGET"), 0.35, 1.00, 0.35)
        end
        GameTooltip:AddLine(L("MAP_RIGHT_REMOVE"), 1, 1, 1)
        GameTooltip:Show()
    end)
    marker:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- The turn-in button lights up on mouse-over, like the game's.
    marker:HookScript("OnEnter", function(self)
        local lit = self.turnInButton and self.turnInButton.lit
        if lit and self.turnInButton:IsShown() then lit:Show() end
    end)
    marker:HookScript("OnLeave", function(self)
        local lit = self.turnInButton and self.turnInButton.lit
        if lit then lit:Hide() end
    end)
    marker:Hide()
    return marker
end

local function EnsureMarkerForTarget(target)
    local key = target and target._fdjKey
    if not key then return nil end
    local marker = mapMarkers[key]
    if not marker then
        marker = CreateMapMarker(key)
        mapMarkers[key] = marker
    end
    return marker
end

local function GetCurrentMapID()
    if not WorldMapFrame or type(WorldMapFrame.GetMapID) ~= "function" then return nil end
    local ok, value = pcall(WorldMapFrame.GetMapID, WorldMapFrame)
    if ok then return value end
    return nil
end

local function PositionMarker(marker, target, parent)
    if not marker or not target or not parent then return end
    if marker:GetParent() ~= parent then marker:SetParent(parent) end
    marker:SetFrameLevel(10000)
    if marker.target ~= target then
        marker.target = target
        ConfigureMarkerTargetAction(marker, target)
    elseif marker._fdjPendingTarget and (not InCombatLockdown or not InCombatLockdown()) then
        ConfigureMarkerTargetAction(marker, target)
    end

    -- patrolpath: the pin of an NPC that walks around walks its path.
    local px, py = target.x, target.y
    if type(target.patrol) == "table" and FDJ.MapPatrol and FDJ.MapPatrol.Position then
        local ok, ax, ay = pcall(FDJ.MapPatrol.Position, target, marker, parent)
        if ok and ax and ay then px, py = ax, ay end
    end
    local positioned = false
    if type(WorldMapFrame.SetPinPosition) == "function" then
        local ok = pcall(WorldMapFrame.SetPinPosition, WorldMapFrame, marker, px, py)
        positioned = ok
    end
    if not positioned then
        local width, height = parent:GetWidth(), parent:GetHeight()
        if not width or not height or width <= 1 or height <= 1 then return end
        marker:ClearAllPoints()
        marker:SetPoint("CENTER", parent, "TOPLEFT", width * px, -height * py)
    end

    local isDungeon = target.markerType == "dungeon"
    local isTurnIn = not isDungeon and target.turnIn and marker.turnInButton ~= nil
    local showX = not isDungeon and not isTurnIn
    marker.dungeonIcon:SetShown(isDungeon)
    marker.dungeonGlow:SetShown(isDungeon)
    if marker.turnInButton then marker.turnInButton:SetShown(isTurnIn and true or false) end
    marker.glow:SetShown(showX)
    marker.x:SetShown(showX)
    for _, shadow in ipairs(marker.outline) do shadow:SetShown(showX) end
    if marker.backing then marker.backing:SetShown(showX) end
    if marker.pulse then
        marker.pulse:SetShown(not isDungeon)
        if marker.pulseAnim then
            if isDungeon then marker.pulseAnim:Stop() elseif not marker.pulseAnim:IsPlaying() then marker.pulseAnim:Play() end
        end
    end

    marker:Show()
end

-- patrolpath: an NPC that walks around (target.patrol = points on the pin's
-- own map, x/y 0-1) gets its path drawn as a closed loop, in the travel
-- route's style (a line with a dark edge), and its pin walks along it so it
-- reads as a patrol. The pin stops while the mouse is on it, so it can be
-- clicked. target.patrolLoop = false: walked back and forth, not a loop.
-- (In a do-block, reached through FDJ.MapPatrol: this file is at Lua's
-- 200-locals limit.)
do
local Patrol = {
    lines = {}, shadowLines = {}, joints = {}, shadowJoints = {},
    state = setmetatable({}, { __mode = "k" }),
    COLOR = { 1.00, 0.55, 0.15 }, SHADOW_COLOR = { 0.05, 0.01, 0.01, 0.75 },
    THICK = 3, SHADOW_THICK = 6,
}
FDJ.MapPatrol = Patrol

function Patrol.Hide()
    Patrol.key = nil
    for _, pool in ipairs({ Patrol.lines, Patrol.shadowLines, Patrol.joints, Patrol.shadowJoints }) do
        for _, piece in ipairs(pool) do piece:Hide() end
    end
end

function Patrol.Line(index, shadow)
    local pool = shadow and Patrol.shadowLines or Patrol.lines
    local line = pool[index]
    if not line and type(Patrol.frame.CreateLine) == "function" then
        line = Patrol.frame:CreateLine(nil, "OVERLAY", nil, shadow and 5 or 6)
        if shadow then
            local c = Patrol.SHADOW_COLOR
            line:SetColorTexture(c[1], c[2], c[3], c[4])
        else
            local c = Patrol.COLOR
            line:SetColorTexture(c[1], c[2], c[3], 1)
        end
        line:SetThickness(shadow and Patrol.SHADOW_THICK or Patrol.THICK)
        pool[index] = line
    end
    return line
end

-- Round joints, like the route's: no notches where the short pieces meet.
function Patrol.Joint(index, shadow)
    local pool = shadow and Patrol.shadowJoints or Patrol.joints
    local dot = pool[index]
    if not dot then
        dot = Patrol.frame:CreateTexture(nil, "OVERLAY", nil, shadow and 5 or 6)
        dot:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
        local c = shadow and Patrol.SHADOW_COLOR or Patrol.COLOR
        dot:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
        local size = shadow and Patrol.SHADOW_THICK or Patrol.THICK
        dot:SetSize(size, size)
        pool[index] = dot
    end
    return dot
end

-- Catmull-Rom through the points (pixels), closed for a loop.
function Patrol.Curve(points, loop)
    local n = #points
    local function P(i)
        if loop then return points[(i - 1) % n + 1] end
        if i < 1 then i = 1 elseif i > n then i = n end
        return points[i]
    end
    local out = {}
    for i = 1, loop and n or (n - 1) do
        local p0, p1, p2, p3 = P(i - 1), P(i), P(i + 1), P(i + 2)
        for s = 0, 15 do
            local t = s / 16
            local t2, t3 = t * t, t * t * t
            out[#out + 1] = {
                x = 0.5 * (2 * p1.x + (p2.x - p0.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2
                    + (3 * p1.x - p0.x - 3 * p2.x + p3.x) * t3),
                y = 0.5 * (2 * p1.y + (p2.y - p0.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2
                    + (3 * p1.y - p0.y - 3 * p2.y + p3.y) * t3),
            }
        end
    end
    local last = loop and points[1] or points[n]
    out[#out + 1] = { x = last.x, y = last.y }
    return out
end

-- The path of a target on a canvas of this size, in canvas units, with the
-- distance along it at every point (cached on the target).
function Patrol.Path(target, width, height)
    if type(target.patrol) ~= "table" or not width or not height or width <= 1 or height <= 1 then return nil end
    local key = math.floor(width + 0.5) .. "x" .. math.floor(height + 0.5)
    local cached = target._fdjPatrolPath
    if cached and cached.key == key then return cached end
    local points = {}
    for _, p in ipairs(target.patrol) do
        local px, py = tonumber(p[1] or p.x), tonumber(p[2] or p.y)
        if px and py then points[#points + 1] = { x = px * width, y = py * height } end
    end
    if #points < 2 then return nil end
    local curve = Patrol.Curve(points, target.patrolLoop ~= false)
    local cum, total = { 0 }, 0
    for i = 2, #curve do
        local dx, dy = curve[i].x - curve[i - 1].x, curve[i].y - curve[i - 1].y
        total = total + math.sqrt(dx * dx + dy * dy)
        cum[i] = total
    end
    if total <= 0 then return nil end
    cached = { key = key, curve = curve, cum = cum, total = total, loop = target.patrolLoop ~= false }
    target._fdjPatrolPath = cached
    return cached
end

-- Where the walking pin is now (x/y 0-1). One lap takes 6-16 seconds.
function Patrol.Position(target, marker, parent)
    local width, height = parent:GetWidth(), parent:GetHeight()
    local path = Patrol.Path(target, width, height)
    if not path then return nil end
    local now = (GetTime and GetTime()) or 0
    local st = Patrol.state[target]
    if not st then
        st = { dist = 0, last = now }
        Patrol.state[target] = st
    end
    local dt = now - st.last
    st.last = now
    if dt < 0 or dt > 0.5 then dt = 0 end -- the map was closed: carry on from there
    local lap = math.max(6, math.min(16, path.total / 16))
    local span = path.loop and path.total or path.total * 2
    if not (marker and marker.IsMouseOver and marker:IsMouseOver()) then
        st.dist = (st.dist + dt * path.total / lap) % span
    end
    local d = st.dist
    if not path.loop and d > path.total then d = span - d end -- on the way back
    local cum, curve = path.cum, path.curve
    local lo, hi = 1, #cum
    while hi - lo > 1 do
        local mid = math.floor((lo + hi) / 2)
        if cum[mid] <= d then lo = mid else hi = mid end
    end
    local seg = cum[hi] - cum[lo]
    local f = seg > 0 and (d - cum[lo]) / seg or 0
    local a, b = curve[lo], curve[hi]
    return (a.x + (b.x - a.x) * f) / width, (a.y + (b.y - a.y) * f) / height
end

function Patrol.Update(parent, currentMapID)
    local list = {}
    for _, target in pairs(mapTargets) do
        if type(target.patrol) == "table" and #target.patrol >= 2 and target.mapID == currentMapID then
            list[#list + 1] = target
        end
    end
    local width, height = parent:GetWidth(), parent:GetHeight()
    if #list == 0 or not width or not height or width <= 1 or height <= 1 then
        Patrol.Hide()
        return
    end
    table.sort(list, function(a, b) return tostring(a._fdjKey) < tostring(b._fdjKey) end)
    local key = tostring(currentMapID) .. ":" .. math.floor(width + 0.5) .. "x" .. math.floor(height + 0.5)
    for _, target in ipairs(list) do key = key .. ":" .. tostring(target._fdjKey) end
    if not Patrol.frame then
        Patrol.frame = CreateFrame("Frame", nil, parent)
        Patrol.frame:EnableMouse(false)
    end
    local frame = Patrol.frame
    if frame:GetParent() ~= parent then
        frame:SetParent(parent)
        Patrol.key = nil
    end
    frame:ClearAllPoints()
    frame:SetAllPoints(parent)
    frame:SetFrameLevel(9990) -- under the pins (10000)
    frame:Show()
    if Patrol.key == key then return end
    Patrol.key = key

    local usedLines, usedJoints = 0, 0
    for _, target in ipairs(list) do
        local path = Patrol.Path(target, width, height)
        local curve = path and path.curve or {}
        for i = 1, #curve do
            local a = curve[i]
            usedJoints = usedJoints + 1
            for _, shadow in ipairs({ true, false }) do
                local dot = Patrol.Joint(usedJoints, shadow)
                dot:ClearAllPoints()
                dot:SetPoint("CENTER", frame, "TOPLEFT", a.x, -a.y)
                dot:Show()
            end
            local b = curve[i + 1]
            if b then
                usedLines = usedLines + 1
                for _, shadow in ipairs({ true, false }) do
                    local line = Patrol.Line(usedLines, shadow)
                    if line then
                        line:SetStartPoint("TOPLEFT", frame, a.x, -a.y)
                        line:SetEndPoint("TOPLEFT", frame, b.x, -b.y)
                        line:Show()
                    end
                end
            end
        end
    end
    for i = usedLines + 1, #Patrol.lines do Patrol.lines[i]:Hide() end
    for i = usedLines + 1, #Patrol.shadowLines do Patrol.shadowLines[i]:Hide() end
    for i = usedJoints + 1, #Patrol.joints do Patrol.joints[i]:Hide() end
    for i = usedJoints + 1, #Patrol.shadowJoints do Patrol.shadowJoints[i]:Hide() end
end
end

-- The smoothed polyline only depends on the route, the open map and the canvas
-- size, so it is rebuilt only when one of those changes (the map ticker runs
-- every 50 ms).
local routeGeometryCache = { key = nil, segments = nil }

-- Route colours and hover state (the line turns orange while hovered).
local ROUTE_COLOR = { 0.95, 0.08, 0.05 }
local ROUTE_HOVER_COLOR = { 1.00, 0.55, 0.15 }
local ROUTE_HOVER_DISTANCE = 8 -- UI units from the line that count as "on it"
local routeHovered = false

local HideRouteWaypointsHook -- set once the waypoint code below is defined

local function HideRouteOverlay()
    routeGeometryCache.key = nil
    routeGeometryCache.segments = nil
    if HideRouteWaypointsHook then HideRouteWaypointsHook() end
    for _, line in ipairs(routeOverlayLines) do line:Hide() end
    for _, line in ipairs(routeOverlayShadows) do line:Hide() end
    for _, dot in ipairs(routeOverlayDots) do dot:Hide() end
end

-- Rectangle of `mapID` expressed in the coordinates of `onMapID`, cached.
-- Returns minX, maxX, minY, maxY or nil.
local routeRectCache = {}
local function MapRectOn(mapID, onMapID)
    if mapID == onMapID then return 0, 1, 0, 1 end
    local key = tostring(mapID) .. ":" .. tostring(onMapID)
    local cached = routeRectCache[key]
    if cached ~= nil then
        if cached == false then return nil end
        return cached[1], cached[2], cached[3], cached[4]
    end
    local result = false
    if C_Map and type(C_Map.GetMapRectOnMap) == "function" then
        local ok, minX, maxX, minY, maxY = pcall(C_Map.GetMapRectOnMap, mapID, onMapID)
        if ok and minX and maxX and minY and maxY and maxX > minX and maxY > minY then
            result = { minX, maxX, minY, maxY }
        end
    end
    routeRectCache[key] = result
    if not result then return nil end
    return result[1], result[2], result[3], result[4]
end

-- World-position round trip, used when the client exposes no rectangle for a
-- map pair (some city maps). Results are cached per point and target map.
local function WorldRoundTrip(pointMapID, x, y, targetMapID)
    if not (C_Map and type(C_Map.GetWorldPosFromMapPos) == "function"
        and type(C_Map.GetMapPosFromWorldPos) == "function") then
        return nil
    end
    local pos = (type(CreateVector2D) == "function" and CreateVector2D(x, y)) or { x = x, y = y }
    local okWorld, continentID, worldPos = pcall(C_Map.GetWorldPosFromMapPos, pointMapID, pos)
    if not okWorld or not continentID or not worldPos then return nil end
    local okMap, _, mapPos = pcall(C_Map.GetMapPosFromWorldPos, continentID, worldPos, targetMapID)
    if not okMap or not mapPos then return nil end
    local mx, my = mapPos.x, mapPos.y
    if (not mx or not my) and mapPos.GetXY then mx, my = mapPos:GetXY() end
    return mx, my
end

-- Project one stored route point (native zone/city coordinates) onto the map
-- that is currently open. The route's continent is used as the common frame,
-- so points from neighbouring zones land in the right place when zoomed in.
-- True when `ancestorID` is the world map (or any map) that contains the
-- route continent, e.g. Azeroth (947) for Eastern Kingdoms (1415).
local routeAncestorCache = {}
local function MapIsAncestorOf(ancestorID, mapID)
    if not ancestorID or not mapID or ancestorID == mapID then return false end
    local key = tostring(ancestorID) .. "<" .. tostring(mapID)
    local cached = routeAncestorCache[key]
    if cached ~= nil then return cached end
    local found = false
    if C_Map and type(C_Map.GetMapInfo) == "function" then
        local id, guard = mapID, 0
        while id and id ~= 0 and guard < 12 do
            local ok, info = pcall(C_Map.GetMapInfo, id)
            if not ok or not info then break end
            if info.parentMapID == ancestorID then found = true; break end
            id = info.parentMapID
            guard = guard + 1
        end
    end
    routeAncestorCache[key] = found
    return found
end

local function ProjectRoutePoint(point, targetMapID, continentID)
    local px, py = tonumber(point.x), tonumber(point.y)
    if not point.mapID or not px or not py then return nil end
    if point.mapID == targetMapID then return px, py end

    -- World map (or anything above the continent): go point -> continent ->
    -- the continent's rectangle on that map. No world-position fallback here,
    -- because that is what used to drop the line into the sea.
    if MapIsAncestorOf(targetMapID, continentID) then
        local aMinX, aMaxX, aMinY, aMaxY = MapRectOn(point.mapID, continentID)
        local cMinX, cMaxX, cMinY, cMaxY = MapRectOn(continentID, targetMapID)
        if not aMinX or not cMinX then return nil end
        local cx = aMinX + (aMaxX - aMinX) * px
        local cy = aMinY + (aMaxY - aMinY) * py
        return cMinX + (cMaxX - cMinX) * cx, cMinY + (cMaxY - cMinY) * cy
    end

    local aMinX, aMaxX, aMinY, aMaxY = MapRectOn(point.mapID, continentID)
    local tMinX, tMaxX, tMinY, tMaxY = MapRectOn(targetMapID, continentID)
    if aMinX and tMinX then
        local cx = aMinX + (aMaxX - aMinX) * px
        local cy = aMinY + (aMaxY - aMinY) * py
        return (cx - tMinX) / (tMaxX - tMinX), (cy - tMinY) / (tMaxY - tMinY)
    end
    return WorldRoundTrip(point.mapID, px, py, targetMapID)
end

-- Kept for callers elsewhere in the file / addon.
local function RoutePointOnMap(routeMapID, point)
    return ProjectRoutePoint(point, routeMapID, routeMapID)
end

-- Draw the travel route on a dedicated high-level frame above the Blizzard
-- map canvas. Map-reveal addons commonly add their own full-zone textures on
-- top of the normal map artwork; drawing directly on the canvas can leave our
-- route hidden underneath those textures, which looks like broken/missing
-- line sections. Keeping a transparent overlay frame above the canvas makes
-- the route remain continuous with both explored and reveal-all map addons.
local function GetRouteOverlayFrame(canvas)
    if not canvas then return nil end

    if not routeOverlayFrame then
        routeOverlayFrame = CreateFrame("Frame", nil, canvas)
        routeOverlayFrame:EnableMouse(false)
    elseif routeOverlayCanvas ~= canvas then
        routeOverlayFrame:SetParent(canvas)
    end

    routeOverlayCanvas = canvas
    routeOverlayFrame:ClearAllPoints()
    routeOverlayFrame:SetAllPoints(canvas)

    -- Keep this comfortably above map reveal / fog textures while remaining
    -- confined to the map canvas itself.
    if type(routeOverlayFrame.SetFrameStrata) == "function" then
        routeOverlayFrame:SetFrameStrata("HIGH")
    end
    if type(routeOverlayFrame.SetFrameLevel) == "function" then
        local baseLevel = (type(canvas.GetFrameLevel) == "function" and canvas:GetFrameLevel()) or 0
        routeOverlayFrame:SetFrameLevel(math.max(baseLevel + 500, 10000))
    end
    routeOverlayFrame:Show()
    return routeOverlayFrame
end

local function ResetRouteOverlayForParent(parent)
    if routeOverlayParent == parent then return end
    HideRouteOverlay()
    routeOverlayParent = parent
    routeOverlayLines = {}
    routeOverlayShadows = {}
    routeOverlayDots = {}
end

local ROUTE_LINE_THICKNESS = 3
local ROUTE_SHADOW_THICKNESS = 6

local function EnsureRouteLine(parent, index, shadow)
    local pool = shadow and routeOverlayShadows or routeOverlayLines
    local line = pool[index]
    if not line and parent and type(parent.CreateLine) == "function" then
        line = parent:CreateLine(nil, "OVERLAY", nil, shadow and 5 or 6)
        if shadow then
            line:SetColorTexture(0.05, 0.01, 0.01, 0.75)
        else
            local c = routeHovered and ROUTE_HOVER_COLOR or ROUTE_COLOR
            line:SetColorTexture(c[1], c[2], c[3], 1.00)
        end
        pool[index] = line
    end
    if line then
        line:SetThickness(shadow and ROUTE_SHADOW_THICKNESS or ROUTE_LINE_THICKNESS)
    end
    return line
end

-- Round joint caps. Short Line segments leave small notches where they meet
-- at an angle; a disc the width of the line at every vertex closes them so
-- the route reads as one continuous stroke.
local function EnsureRouteDot(parent, index, shadow)
    local slot = index * 2 - (shadow and 1 or 0)
    local dot = routeOverlayDots[slot]
    if not dot and parent then
        dot = parent:CreateTexture(nil, "OVERLAY", nil, shadow and 5 or 6)
        dot:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
        if shadow then
            dot:SetVertexColor(0.05, 0.01, 0.01, 0.75)
        else
            local c = routeHovered and ROUTE_HOVER_COLOR or ROUTE_COLOR
            dot:SetVertexColor(c[1], c[2], c[3], 1.00)
        end
        routeOverlayDots[slot] = dot
    end
    if dot then
        local size = shadow and ROUTE_SHADOW_THICKNESS or ROUTE_LINE_THICKNESS
        dot:SetSize(size, size)
    end
    return dot
end

-- Centripetal Catmull-Rom through the traced road points, split at points
-- flagged `corner` (junctions) so real turns stay sharp. Output is in pixels
-- and densified so each drawn segment is only a few pixels long.
local function CatmullRomRun(run, out, stepPx)
    local n = #run
    if n == 1 then out[#out + 1] = run[1]; return end
    local function P(i)
        if i < 1 then
            return { x = 2 * run[1].x - run[2].x, y = 2 * run[1].y - run[2].y }
        elseif i > n then
            return { x = 2 * run[n].x - run[n - 1].x, y = 2 * run[n].y - run[n - 1].y }
        end
        return run[i]
    end
    local function tj(ti, a, b)
        local dx, dy = b.x - a.x, b.y - a.y
        local d = math.sqrt(dx * dx + dy * dy)
        return ti + math.max(math.sqrt(d), 1e-4)
    end
    for i = 1, n - 1 do
        local p0, p1, p2, p3 = P(i - 1), P(i), P(i + 1), P(i + 2)
        local t0 = 0
        local t1 = tj(t0, p0, p1)
        local t2 = tj(t1, p1, p2)
        local t3 = tj(t2, p2, p3)
        local dx, dy = p2.x - p1.x, p2.y - p1.y
        local steps = math.max(1, math.min(24, math.floor(math.sqrt(dx * dx + dy * dy) / stepPx + 0.5)))
        out[#out + 1] = { x = p1.x, y = p1.y }
        for s = 1, steps - 1 do
            local t = t1 + (t2 - t1) * (s / steps)
            local a1x = (t1 - t) / (t1 - t0) * p0.x + (t - t0) / (t1 - t0) * p1.x
            local a1y = (t1 - t) / (t1 - t0) * p0.y + (t - t0) / (t1 - t0) * p1.y
            local a2x = (t2 - t) / (t2 - t1) * p1.x + (t - t1) / (t2 - t1) * p2.x
            local a2y = (t2 - t) / (t2 - t1) * p1.y + (t - t1) / (t2 - t1) * p2.y
            local a3x = (t3 - t) / (t3 - t2) * p2.x + (t - t2) / (t3 - t2) * p3.x
            local a3y = (t3 - t) / (t3 - t2) * p2.y + (t - t2) / (t3 - t2) * p3.y
            local b1x = (t2 - t) / (t2 - t0) * a1x + (t - t0) / (t2 - t0) * a2x
            local b1y = (t2 - t) / (t2 - t0) * a1y + (t - t0) / (t2 - t0) * a2y
            local b2x = (t3 - t) / (t3 - t1) * a2x + (t - t1) / (t3 - t1) * a3x
            local b2y = (t3 - t) / (t3 - t1) * a2y + (t - t1) / (t3 - t1) * a3y
            out[#out + 1] = {
                x = (t2 - t) / (t2 - t1) * b1x + (t - t1) / (t2 - t1) * b2x,
                y = (t2 - t) / (t2 - t1) * b1y + (t - t1) / (t2 - t1) * b2y,
            }
        end
    end
    out[#out + 1] = { x = run[n].x, y = run[n].y }
end

local function SmoothRoutePixels(points, stepPx)
    local out = {}
    local run = {}
    for i, p in ipairs(points) do
        run[#run + 1] = p
        if (p.corner and #run > 1) or i == #points then
            local seg = {}
            CatmullRomRun(run, seg, stepPx)
            local startIndex = (#out > 0) and 2 or 1
            for k = startIndex, #seg do out[#out + 1] = seg[k] end
            run = { p }
        end
    end
    return out
end

-- Liang-Barsky clip of a segment to the canvas (pixels, y down as positive).
local function ClipSegment(x1, y1, x2, y2, w, h)
    local dx, dy = x2 - x1, y2 - y1
    local t0, t1 = 0, 1
    local p = { -dx, dx, -dy, dy }
    local q = { x1, w - x1, y1, h - y1 }
    for i = 1, 4 do
        if p[i] == 0 then
            if q[i] < 0 then return nil end
        else
            local r = q[i] / p[i]
            if p[i] < 0 then
                if r > t1 then return nil end
                if r > t0 then t0 = r end
            else
                if r < t0 then return nil end
                if r < t1 then t1 = r end
            end
        end
    end
    return x1 + t0 * dx, y1 + t0 * dy, x1 + t1 * dx, y1 + t1 * dy
end

local function BuildRouteSegments(currentMapID, width, height)
    local continentID = activeRouteMap.mapID
    local projected = {}
    for _, point in ipairs(activeRouteMap.points or {}) do
        local x, y = ProjectRoutePoint(point, currentMapID, continentID)
        if x and y then
            projected[#projected + 1] = { x = x * width, y = y * height, corner = point.corner }
        end
    end
    if #projected < 2 then return {} end

    -- Skip the route entirely on maps it never comes near.
    local near = false
    for _, p in ipairs(projected) do
        if p.x >= -width * 0.05 and p.x <= width * 1.05 and p.y >= -height * 0.05 and p.y <= height * 1.05 then
            near = true
            break
        end
    end
    if not near then return {} end

    -- Keep the drawn pieces around 4 px long regardless of zoom level.
    local smooth = SmoothRoutePixels(projected, 4)
    local segments = {}
    for i = 1, #smooth - 1 do
        local a, b = smooth[i], smooth[i + 1]
        local x1, y1, x2, y2 = ClipSegment(a.x, a.y, b.x, b.y, width, height)
        if x1 and ((x2 - x1) ~= 0 or (y2 - y1) ~= 0) then
            segments[#segments + 1] = { x1, y1, x2, y2 }
        end
    end
    return segments
end

-- ---------------------------------------------------------------------------
-- Route waypoints (e.g. the Tarren Mill flight path) and hover-to-remove.
-- ---------------------------------------------------------------------------
local routeWaypointFrames = {}
local routeHoverButton
local routeHoverDriver
local ClearRouteOnMap -- forward declaration

local function SetRouteTint(color)
    for _, line in ipairs(routeOverlayLines) do
        line:SetColorTexture(color[1], color[2], color[3], 1.00)
    end
    for slot, dot in pairs(routeOverlayDots) do
        if slot % 2 == 0 then dot:SetVertexColor(color[1], color[2], color[3], 1.00) end
    end
end

local WAYPOINT_ICONS = {
    flightpath = "Interface\\Minimap\\Tracking\\FlightMaster",
}

local function EnsureWaypointFrame(parent, index)
    local frame = routeWaypointFrames[index]
    if frame and frame:GetParent() ~= parent then frame:SetParent(parent) end
    if not frame then
        frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(22, 22)
        frame:EnableMouse(true)
        frame.icon = frame:CreateTexture(nil, "ARTWORK")
        frame.icon:SetPoint("CENTER")
        frame.icon:SetSize(20, 20)
        frame:SetScript("OnEnter", function(self)
            if not GameTooltip or not self.waypoint then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L(self.waypoint.titleKey), 1, 0.82, 0)
            if self.waypoint.textKey then
                GameTooltip:AddLine(L(self.waypoint.textKey), 1, 1, 1, true)
            end
            GameTooltip:AddLine(L("ROUTE_REMOVE_HINT"), 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end)
        frame:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        frame:SetScript("OnMouseUp", function(self, button)
            if button == "RightButton" then
                if ClearRouteOnMap then ClearRouteOnMap() end
            elseif button == "LeftButton" and self.opensMapID and WorldMapFrame
                and type(WorldMapFrame.SetMapID) == "function" then
                if GameTooltip then GameTooltip:Hide() end
                pcall(WorldMapFrame.SetMapID, WorldMapFrame, self.opensMapID)
            end
        end)
        routeWaypointFrames[index] = frame
    end
    frame:SetFrameLevel(10001)
    return frame
end

local function HideRouteWaypoints()
    for _, frame in ipairs(routeWaypointFrames) do frame:Hide() end
end
HideRouteWaypointsHook = HideRouteWaypoints

-- Runs every map tick: cheap (a handful of points) and needs to follow zoom,
-- because the icon is counter-scaled to keep a constant on-screen size.
local function UpdateRouteWaypoints(parent, currentMapID, width, height)
    local waypoints = activeRouteMap and activeRouteMap.waypoints
    if not waypoints or #waypoints == 0 then HideRouteWaypoints(); return end
    local canvasScale = parent:GetScale() or 1
    if canvasScale <= 0 then canvasScale = 1 end
    local shown = 0
    for i, waypoint in ipairs(waypoints) do
        local frame = EnsureWaypointFrame(parent, i)
        local x, y = ProjectRoutePoint(waypoint, currentMapID, activeRouteMap.mapID)
        if frame and x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
            frame.waypoint = waypoint
            if waypoint.mapID ~= currentMapID then
                frame.opensMapID = waypoint.mapID
            else
                frame.opensMapID = nil
            end
            frame.icon:SetTexture(WAYPOINT_ICONS[waypoint.icon] or WAYPOINT_ICONS.flightpath)
            frame:SetScale(1 / canvasScale)
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", parent, "TOPLEFT", width * x * canvasScale, -height * y * canvasScale)
            frame:Show()
            shown = i
        elseif frame then
            frame:Hide()
        end
    end
    for i = #waypoints + 1, #routeWaypointFrames do routeWaypointFrames[i]:Hide() end
end

local function DistanceToSegmentSq(px, py, x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    local len = dx * dx + dy * dy
    local t = 0
    if len > 0 then
        t = ((px - x1) * dx + (py - y1) * dy) / len
        if t < 0 then t = 0 elseif t > 1 then t = 1 end
    end
    local qx, qy = x1 + t * dx - px, y1 + t * dy - py
    return qx * qx + qy * qy
end

local function EnsureRouteHoverButton(parent)
    if not routeHoverButton then
        routeHoverButton = CreateFrame("Button", nil, parent)
        routeHoverButton:SetSize(24, 24)
        routeHoverButton:RegisterForClicks("RightButtonUp")
        -- Let left clicks through to the map where the client supports it.
        if type(routeHoverButton.SetPassThroughButtons) == "function" then
            pcall(routeHoverButton.SetPassThroughButtons, routeHoverButton, "LeftButton", "MiddleButton")
        end
        routeHoverButton:SetScript("OnClick", function(_, button)
            if button == "RightButton" and ClearRouteOnMap then ClearRouteOnMap() end
        end)
        routeHoverButton:Hide()
    end
    if routeHoverButton:GetParent() ~= parent then routeHoverButton:SetParent(parent) end
    routeHoverButton:SetFrameLevel(9999)
    return routeHoverButton
end

local function SetRouteHovered(hovered, parent)
    if hovered == routeHovered then return end
    routeHovered = hovered
    SetRouteTint(hovered and ROUTE_HOVER_COLOR or ROUTE_COLOR)
    if hovered then
        if GameTooltip and routeHoverButton then
            GameTooltip:SetOwner(routeHoverButton, "ANCHOR_NONE")
            GameTooltip:ClearAllPoints()
            -- Sit to the right of the cursor so the tooltip never covers the line.
            GameTooltip:SetPoint("LEFT", routeHoverButton, "RIGHT", 10, 0)
            GameTooltip:SetText(L("ROUTE_REMOVE_HINT"), 1, 1, 1)
            GameTooltip:Show()
        end
    else
        if routeHoverButton then routeHoverButton:Hide() end
        if GameTooltip and routeHoverButton and GameTooltip:GetOwner() == routeHoverButton then
            GameTooltip:Hide()
        end
    end
end

local function UpdateRouteHover()
    local segments = routeGeometryCache.segments
    local parent = routeOverlayParent
    if not activeRouteMap or not segments or #segments == 0 or not parent
        or not WorldMapFrame or not WorldMapFrame:IsShown() or not parent:IsVisible() then
        SetRouteHovered(false)
        return
    end
    -- Ignore the cursor while it is over our own waypoint icons.
    for _, frame in ipairs(routeWaypointFrames) do
        if frame:IsShown() and frame:IsMouseOver() then SetRouteHovered(false); return end
    end
    local scroll = WorldMapFrame.ScrollContainer
    if (scroll and not scroll:IsMouseOver()) or (not scroll and not parent:IsMouseOver()) then
        SetRouteHovered(false)
        return
    end

    local scale = parent:GetEffectiveScale()
    local left, top = parent:GetLeft(), parent:GetTop()
    if not scale or scale <= 0 or not left or not top then SetRouteHovered(false); return end
    local cx, cy = GetCursorPosition()
    local px, py = cx / scale - left, top - cy / scale

    local uiScale = (UIParent and UIParent:GetEffectiveScale()) or 1
    local threshold = ROUTE_HOVER_DISTANCE * uiScale / scale
    local thresholdSq = threshold * threshold
    local near = false
    for _, seg in ipairs(segments) do
        if DistanceToSegmentSq(px, py, seg[1], seg[2], seg[3], seg[4]) <= thresholdSq then
            near = true
            break
        end
    end

    if near then
        local button = EnsureRouteHoverButton(parent)
        local canvasScale = parent:GetScale() or 1
        if canvasScale <= 0 then canvasScale = 1 end
        button:SetScale(1 / canvasScale)
        button:ClearAllPoints()
        button:SetPoint("CENTER", parent, "TOPLEFT", px * canvasScale, -py * canvasScale)
        button:Show()
        SetRouteHovered(true, parent)
    else
        SetRouteHovered(false)
    end
end

local function StartRouteHoverDriver()
    if routeHoverDriver then routeHoverDriver:Show(); return end
    routeHoverDriver = CreateFrame("Frame")
    routeHoverDriver.elapsed = 0
    routeHoverDriver:SetScript("OnUpdate", function(self, elapsed)
        if not activeRouteMap then self:Hide(); SetRouteHovered(false); return end
        self.elapsed = self.elapsed + elapsed
        if self.elapsed < 0.02 then return end
        self.elapsed = 0
        UpdateRouteHover()
    end)
end

-- Draw on the route's continent, the maps inside it, and the world map above
-- it (handled by ProjectRoutePoint). Other continents never show the route.
local routeMapInsideCache = {}
local function MapIsInsideContinent(mapID, continentID)
    if mapID == continentID then return true end
    local key = tostring(mapID) .. ">" .. tostring(continentID)
    local cached = routeMapInsideCache[key]
    if cached ~= nil then return cached end
    local inside = false
    if C_Map and type(C_Map.GetMapInfo) == "function" then
        local id, guard = mapID, 0
        while id and id ~= 0 and guard < 12 do
            local ok, info = pcall(C_Map.GetMapInfo, id)
            if not ok or not info then break end
            if info.parentMapID == continentID then inside = true; break end
            id = info.parentMapID
            guard = guard + 1
        end
    end
    routeMapInsideCache[key] = inside
    return inside
end

-- When the player switches maps, the Blizzard canvas can report the new map ID
-- for a frame while its size/scale still belong to the previous map. Drawing
-- in that frame put the route in the wrong place for a split second. The map
-- state must therefore be seen unchanged on two consecutive checks before the
-- route is drawn.
local routeStability = { key = nil, stable = false }
local routeMapChangeHooked = false
local function HookRouteMapChanges()
    if routeMapChangeHooked or not WorldMapFrame or type(hooksecurefunc) ~= "function" then return end
    if type(WorldMapFrame.OnMapChanged) == "function" then
        routeMapChangeHooked = pcall(hooksecurefunc, WorldMapFrame, "OnMapChanged", function()
            routeStability.key = nil
            routeStability.stable = false
            HideRouteOverlay()
        end)
    end
end

local function UpdateRouteOverlay()
    if not activeRouteMap or not WorldMapFrame or not WorldMapFrame:IsShown() then
        routeStability.key = nil
        routeStability.stable = false
        HideRouteOverlay()
        return
    end

    local currentMapID = GetCurrentMapID()
    if not currentMapID or not (MapIsInsideContinent(currentMapID, activeRouteMap.mapID)
        or MapIsAncestorOf(currentMapID, activeRouteMap.mapID)) then
        routeStability.key = nil
        routeStability.stable = false
        HideRouteOverlay()
        return
    end

    local canvas = GetWorldMapCanvasChild()
    if not canvas then return end
    local parent = GetRouteOverlayFrame(canvas)
    if not parent then return end
    if routeOverlayParent ~= parent then routeGeometryCache.key = nil end
    ResetRouteOverlayForParent(parent)

    -- Geometry is still measured from the actual map canvas. The dedicated
    -- overlay is anchored 1:1 to it, so these coordinates remain identical.
    local width, height = canvas:GetWidth(), canvas:GetHeight()
    if not width or not height or width <= 1 or height <= 1 then return end

    local key = tostring(activeRouteMap) .. ":" .. currentMapID .. ":" .. math.floor(width + 0.5) .. "x" .. math.floor(height + 0.5)

    if routeStability.key ~= key then
        -- Map (or canvas size) just changed: hide now, draw on the next check.
        routeStability.key = key
        routeStability.stable = false
        HideRouteOverlay()
        return
    end
    routeStability.stable = true

    -- Some reveal-map addons rebuild/re-level their overlay frames when the
    -- zone changes. Re-assert our route layer after the map has stabilised.
    if routeOverlayFrame then
        if type(routeOverlayFrame.SetFrameStrata) == "function" then
            routeOverlayFrame:SetFrameStrata("HIGH")
        end
        if type(routeOverlayFrame.SetFrameLevel) == "function" then
            local baseLevel = (type(canvas.GetFrameLevel) == "function" and canvas:GetFrameLevel()) or 0
            routeOverlayFrame:SetFrameLevel(math.max(baseLevel + 500, 10000))
        end
    end

    UpdateRouteWaypoints(parent, currentMapID, width, height)
    if routeGeometryCache.key == key and routeGeometryCache.drawn then return end

    local segments = BuildRouteSegments(currentMapID, width, height)
    routeGeometryCache.key = key
    routeGeometryCache.segments = segments

    if #segments == 0 then
        HideRouteOverlay()
        routeGeometryCache.key = key
        routeGeometryCache.drawn = true
        return
    end

    for i, seg in ipairs(segments) do
        local x1, y1, x2, y2 = seg[1], -seg[2], seg[3], -seg[4]

        local shadow = EnsureRouteLine(parent, i, true)
        if shadow then
            shadow:SetStartPoint("TOPLEFT", parent, x1, y1)
            shadow:SetEndPoint("TOPLEFT", parent, x2, y2)
            shadow:Show()
        end
        local line = EnsureRouteLine(parent, i, false)
        if line then
            line:SetStartPoint("TOPLEFT", parent, x1, y1)
            line:SetEndPoint("TOPLEFT", parent, x2, y2)
            line:Show()
        end

        for _, isShadow in ipairs({ true, false }) do
            local dot = EnsureRouteDot(parent, i, isShadow)
            if dot then
                dot:ClearAllPoints()
                dot:SetPoint("CENTER", parent, "TOPLEFT", x1, y1)
                dot:Show()
            end
        end
    end

    local n = #segments
    for i = n + 1, #routeOverlayLines do routeOverlayLines[i]:Hide() end
    for i = n + 1, #routeOverlayShadows do routeOverlayShadows[i]:Hide() end
    for slot = n * 2 + 1, #routeOverlayDots do
        if routeOverlayDots[slot] then routeOverlayDots[slot]:Hide() end
    end
    routeGeometryCache.drawn = true
    SetRouteTint(routeHovered and ROUTE_HOVER_COLOR or ROUTE_COLOR)
end

local function UpdateMapMarkers()
    if not WorldMapFrame or not WorldMapFrame:IsShown() then
        for _, marker in pairs(mapMarkers) do marker:Hide() end
        FDJ.MapPatrol.Hide()
        return false
    end

    local currentMapID = GetCurrentMapID()
    local parent = GetWorldMapCanvasChild()
    if not parent then return true end

    for key, target in pairs(mapTargets) do
        local marker = EnsureMarkerForTarget(target)
        if marker then
            if currentMapID and currentMapID ~= target.mapID then
                marker:Hide()
            else
                PositionMarker(marker, target, parent)
            end
        end
    end

    -- Hide any orphaned marker frames whose targets were removed.
    for key, marker in pairs(mapMarkers) do
        if not mapTargets[key] then marker:Hide() end
    end
    pcall(FDJ.MapPatrol.Update, parent, currentMapID)
    UpdateRouteOverlay()
    return true
end

local function StartQuestStartMapTicker()
    if questStartMapTicker then return end
    questStartMapTicker = CreateFrame("Frame")
    questStartMapTicker.elapsed = 0
    questStartMapTicker:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed < 0.05 then return end
        self.elapsed = 0
        UpdateMapMarkers()
    end)
end

local function ForceWorldMapMapID(mapID)
    if not WorldMapFrame or not mapID then return false end
    if not WorldMapFrame:IsShown() then
        -- In combat only the game itself opens the map (M key, or the secure
        -- click Show on Map uses); trying from here would just be blocked.
        if InCombatLockdown and InCombatLockdown() then return false end
        local shown = false
        if type(ShowUIPanel) == "function" then shown = pcall(ShowUIPanel, WorldMapFrame) end
        if not shown then pcall(WorldMapFrame.Show, WorldMapFrame) end
    end
    if type(WorldMapFrame.SetMapID) == "function" then
        local ok = pcall(WorldMapFrame.SetMapID, WorldMapFrame, mapID)
        if ok then return true end
    end
    return false
end

local function ShowRecordedLocationOnMap(loc, fallbackText)
    if not loc then return end

    local key = TargetKey(loc)
    if not key then return end
    local target = {}
    for k, v in pairs(loc) do target[k] = v end
    target._fdjKey = key
    -- The journal names the quest this pin was opened for; the tooltip shows it.
    target.questTitle = FDJ.pendingMarkerQuestTitle
    FDJ.pendingMarkerQuestTitle = nil
    -- Opened from a Show Turn In button: the pin is where it is handed in.
    target.turnIn = FDJ.pendingMarkerTurnIn and true or nil
    FDJ.pendingMarkerTurnIn = nil
    -- autoclear: the quest this pin is for; the pin goes away by itself
    -- once that quest is picked up / handed in / its objective done.
    target.fdjAutoQuest = tonumber(FDJ.pendingMarkerQuestID)
    target.fdjAutoObjective = FDJ.pendingMarkerObjective and true or nil
    FDJ.pendingMarkerQuestID, FDJ.pendingMarkerObjective = nil, nil
    if target.fdjAutoQuest and FDJ.MapMarkers.SnapshotAutoClear then FDJ.MapMarkers.SnapshotAutoClear(target) end
    local existing = mapTargets[key]
    if existing and existing.raidMarkIndex then
        target.raidMarkIndex = existing.raidMarkIndex
    elseif IsTargetableNPCMarker(target) then
        target.raidMarkIndex = RaidMarkIndexForTarget(target)
    end
    mapTargets[key] = target
    -- arrow: the waypoint arrow points here too (see the end of this file).
    if FDJ.SetWaypointArrow then FDJ.SetWaypointArrow(target) end

    local opened = false
    local inCombat = InCombatLockdown and InCombatLockdown()
    if inCombat then
        -- The map is only open now if Show on Map's secure click opened it (or
        -- the player did); otherwise jump to the spot when they open it.
        opened = ForceWorldMapMapID(target.mapID)
        if not opened and FDJ.RememberCombatMapSpot then FDJ.RememberCombatMapSpot(target.mapID) end
    else
        if C_Map and type(C_Map.OpenWorldMap) == "function" then
            local ok = pcall(C_Map.OpenWorldMap, target.mapID)
            opened = ok
        elseif type(OpenWorldMap) == "function" then
            local ok = pcall(OpenWorldMap, target.mapID)
            opened = ok
        end
        opened = ForceWorldMapMapID(target.mapID) or opened
    end
    StartQuestStartMapTicker()
    UpdateMapMarkers()

    if C_Timer and type(C_Timer.After) == "function" then
        for _, delay in ipairs({0.03, 0.10, 0.25, 0.50}) do
            C_Timer.After(delay, function()
                if not mapTargets[key] then return end
                ForceWorldMapMapID(target.mapID)
                UpdateMapMarkers()
            end)
        end
    end

    if DEFAULT_CHAT_FRAME then
        local mapText = FreeText(target.label or fallbackText or "recorded location")
        -- Short dash in chat ("Alba Fairmoon - Sentinel Hill inn"), like the game's own lines.
        mapText = tostring(mapText):gsub("%s*\226\128\148%s*", " - "):gsub("%s*\226\128\147%s*", " - ")
        -- Labels without a place ("Thrall") get the zone name: "Thrall - Orgrimmar".
        if not mapText:find(" - ", 1, true) and target.mapID and C_Map and C_Map.GetMapInfo then
            local ok, info = pcall(C_Map.GetMapInfo, target.mapID)
            if ok and info and info.name and info.name ~= "" then mapText = mapText .. " - " .. info.name end
        end
        if opened then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd36bDungeonJournal:|r " .. L("MAP_MARKED", mapText))
        elseif inCombat then
            local key = GetBindingKey and GetBindingKey("TOGGLEWORLDMAP")
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd36bDungeonJournal:|r " .. L("MAP_COMBAT", key or "M"))
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd36bDungeonJournal:|r " .. L("MAP_OPEN_FAILED"))
        end
    end
end

local function ShowRouteOnMap(routeMap)
    if not routeMap or not routeMap.mapID or not routeMap.points or #routeMap.points < 2 then return end
    activeRouteMap = routeMap
    routeGeometryCache.key = nil
    HookRouteMapChanges()
    StartRouteHoverDriver()

    local opened = false
    if not (InCombatLockdown and InCombatLockdown()) then
        if C_Map and type(C_Map.OpenWorldMap) == "function" then
            opened = pcall(C_Map.OpenWorldMap, routeMap.mapID)
        elseif type(OpenWorldMap) == "function" then
            opened = pcall(OpenWorldMap, routeMap.mapID)
        end
    elseif FDJ.RememberCombatMapSpot and not (WorldMapFrame and WorldMapFrame:IsShown()) then
        FDJ.RememberCombatMapSpot(routeMap.mapID)
    end

    ForceWorldMapMapID(routeMap.mapID)
    StartQuestStartMapTicker()
    UpdateMapMarkers()

    if C_Timer and type(C_Timer.After) == "function" then
        for _, delay in ipairs({0.03, 0.10, 0.25, 0.50}) do
            C_Timer.After(delay, function()
                if activeRouteMap ~= routeMap then return end
                ForceWorldMapMapID(routeMap.mapID)
                UpdateMapMarkers()
            end)
        end
    end
end

-- Removes the travel-route overlay (right-click on the line or a route icon).
ClearRouteOnMap = function()
    activeRouteMap = nil
    SetRouteHovered(false)
    if routeHoverButton then routeHoverButton:Hide() end
    HideRouteOverlay()
    if GameTooltip then GameTooltip:Hide() end
end

local function ShowQuestStartOnMap(quest)
    if not quest then return end
    local loc = QUEST_START_MAPS[quest.id]
    if not loc then return end
    ShowRecordedLocationOnMap(loc, quest.pickup or quest.name)
end

FDJ.MapMarkers = FDJ.MapMarkers or {}
FDJ.MapMarkers.ShowRecordedLocationOnMap = ShowRecordedLocationOnMap
FDJ.MapMarkers.ShowRouteOnMap = ShowRouteOnMap
FDJ.MapMarkers.ClearRouteOnMap = ClearRouteOnMap
FDJ.MapMarkers.ShowQuestStartOnMap = ShowQuestStartOnMap
FDJ.MapMarkers.UpdateMapMarkers = UpdateMapMarkers
FDJ.MapMarkers.ConfigureTargetAndMarkAction = ConfigureTargetAndMarkAction
FDJ.MapMarkers.ApplyQuestGiverRaidMark = ApplyQuestGiverRaidMark
FDJ.MapMarkers.RaidMarkIndexForTarget = RaidMarkIndexForTarget
FDJ.MapMarkers.QuestGiverName = QuestGiverName

-- BEGIN autoclear
-- A pin put on the map for a quest clears itself: a quest giver's once the
-- quest is picked up, a turn-in pin once it is handed in, an objective pin
-- (Sputtervalve) once the objective is done. Only a change after the pin was
-- placed counts (marking the giver of a quest already in the log leaves the
-- pin until that quest is handed in). Built inside a function: this file is
-- at Lua's 200-local limit.
FDJ.MapMarkers.InitAutoClear = function()
    local justTurnedIn = {}
    local function State(id)
        return {
            log = (FDJ.IsQuestInLog and FDJ.IsQuestInLog(id)) and true or false,
            done = (justTurnedIn[id] or (FDJ.QuestTurnedIn and FDJ.QuestTurnedIn(id))) and true or false,
            finished = (FDJ.IsQuestFinished and FDJ.IsQuestFinished(id)) and true or false,
        }
    end
    FDJ.MapMarkers.SnapshotAutoClear = function(target)
        if target and target.fdjAutoQuest then target.fdjAutoWas = State(target.fdjAutoQuest) end
    end
    local function Sweep()
        local gone = {}
        for _, target in pairs(mapTargets) do
            local id, was = target.fdjAutoQuest, target.fdjAutoWas
            if id and was then
                local now = State(id)
                local handedIn = now.done and not was.done
                local clear
                if target.turnIn then
                    clear = handedIn
                elseif target.fdjAutoObjective then
                    clear = handedIn or (now.finished and not was.finished)
                else
                    clear = handedIn or (now.log and not was.log)
                end
                if clear then gone[#gone + 1] = target end
            end
        end
        for _, target in ipairs(gone) do RemoveTarget(target) end
        if #gone > 0 then UpdateMapMarkers() end
    end
    local watch = CreateFrame("Frame")
    watch:RegisterEvent("QUEST_ACCEPTED")
    watch:RegisterEvent("QUEST_TURNED_IN")
    watch:RegisterEvent("QUEST_LOG_UPDATE")
    watch:SetScript("OnEvent", function(_, event, a)
        if event == "QUEST_TURNED_IN" and tonumber(a) then justTurnedIn[tonumber(a)] = true end
        if next(mapTargets) == nil then return end
        local ok = pcall(Sweep)
        if not ok then return end
    end)
end
FDJ.MapMarkers.InitAutoClear()
-- END autoclear
FDJ.MapMarkers.QUEST_GIVER_MARK_PRIORITY = QUEST_GIVER_MARK_PRIORITY
FDJ.MapMarkers.QUEST_GIVER_MARK_NAMES = QUEST_GIVER_MARK_NAMES

-- BEGIN combatmap
-- ------------------------------------------------ Show on Map in combat
-- The game blocks addon code from opening the world map in combat, but a
-- secure click on its own map button (what the M key does) is allowed. A
-- protected button can't sit inside the journal (the journal would then be
-- stuck open or closed during combat), so when combat starts with a quest page
-- open, an invisible secure button is laid over Show on Map and Show Turn In
-- for the fight. It presses the game's map button, then the spot is marked as
-- usual. Secure buttons can't move during combat: if the journal closes,
-- scrolls or changes page in the fight, a plain frame covers the old spot so
-- no stray click toggles the map, and the real button falls back to "press M"
-- (the map then jumps to the spot when it opens). All of it ends with combat.
local GAME_MAP_BUTTONS = { "WorldMapMicroButton", "MiniMapWorldMapButton" }
local combatClicks = {}

local function GameMapButtonName()
    for _, name in ipairs(GAME_MAP_BUTTONS) do
        local b = _G[name]
        if type(b) == "table" and b.Click then return name end
    end
end

-- Show on Map pressed in combat with the map closed: when the player opens
-- the map (within two minutes), show the zone of that spot.
local pendingSpot
local mapShowHooked = false
function FDJ.RememberCombatMapSpot(mapID)
    if not mapID then return end
    pendingSpot = { mapID = mapID, at = GetTime and GetTime() or 0 }
    if mapShowHooked or not (WorldMapFrame and WorldMapFrame.HookScript) then return end
    mapShowHooked = true
    WorldMapFrame:HookScript("OnShow", function()
        local spot = pendingSpot
        pendingSpot = nil
        if not spot or (GetTime and GetTime() - spot.at > 120) then return end
        local function Apply()
            if WorldMapFrame:IsShown() and WorldMapFrame.SetMapID then
                pcall(WorldMapFrame.SetMapID, WorldMapFrame, spot.mapID)
            end
        end
        Apply()
        if C_Timer and C_Timer.After then
            for _, delay in ipairs({ 0.03, 0.10, 0.25 }) do C_Timer.After(delay, Apply) end
        end
    end)
end

-- Screen rectangle of a journal button, in UIParent units.
local function CoverRect(real)
    local l, b, w, h = real:GetLeft(), real:GetBottom(), real:GetWidth(), real:GetHeight()
    if not (l and b and w and h) then return nil end
    local s = real:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return l * s, b * s, w * s, h * s
end

local function MakeCombatClick(i)
    if InCombatLockdown and InCombatLockdown() then return nil end
    local ok, o = pcall(CreateFrame, "Button", "ForeverDungeonJournalMapClick" .. i, UIParent, "SecureActionButtonTemplate")
    if not ok or not o then return nil end
    o:Hide()
    o:RegisterForClicks("LeftButtonUp")
    o:SetAttribute("useOnKeyDown", false)
    -- Looks and tooltip of the journal button underneath.
    o:SetScript("OnEnter", function(self)
        local real = self.fdjReal
        if not (real and real:IsVisible()) then return end
        local enter = real:GetScript("OnEnter")
        if enter then pcall(enter, real) end
        if real.LockHighlight then real:LockHighlight() end
    end)
    o:SetScript("OnLeave", function(self)
        local real = self.fdjReal
        if real and real.UnlockHighlight then real:UnlockHighlight() end
        GameTooltip:Hide()
    end)
    -- After the secure click has opened the map: mark the spot as usual.
    o:SetScript("PostClick", function(self)
        local real = self.fdjReal
        if not (real and real:IsVisible()) then return end
        local open = real:GetScript("PostClick") or real:GetScript("OnClick")
        if open then pcall(open, real, "LeftButton", false) end
    end)
    local blocker = CreateFrame("Frame", nil, UIParent)
    blocker:EnableMouse(true)
    blocker:Hide()
    o.fdjBlocker = blocker
    return o
end

-- While armed: cover a secure button whose journal button is gone or moved.
local combatWatch = CreateFrame("Frame")
combatWatch:Hide()
combatWatch.t = 0
combatWatch:SetScript("OnUpdate", function(self, elapsed)
    self.t = self.t + elapsed
    if self.t < 0.1 then return end
    self.t = 0
    for _, o in pairs(combatClicks) do
        if o:IsShown() then
            local real, r = o.fdjReal, o.fdjRect
            local stray = true
            if real and r and real:IsVisible() then
                local l, b, w, h = CoverRect(real)
                stray = not l or math.abs(l - r[1]) > 1 or math.abs(b - r[2]) > 1
                    or math.abs(w - r[3]) > 1 or math.abs(h - r[4]) > 1
            end
            if o.fdjBlocker:IsShown() ~= stray then o.fdjBlocker:SetShown(stray) end
        end
    end
end)

-- PLAYER_REGEN_DISABLED comes just before the combat lock: last chance to
-- place secure buttons for this fight.
local function ArmCombatClicks()
    if InCombatLockdown and InCombatLockdown() then return end
    local journal = _G.ForeverDungeonJournalFrame
    local mapButton = GameMapButtonName()
    if not (journal and journal:IsVisible() and mapButton) then return end
    local armed = false
    for i, real in ipairs({ journal.questMapButton, journal.questTurninMapButton }) do
        if real and real:IsVisible() then
            combatClicks[i] = combatClicks[i] or MakeCombatClick(i)
            local o = combatClicks[i]
            local l, b, w, h = CoverRect(real)
            if o and l then
                o.fdjReal = real
                o.fdjRect = { l, b, w, h }
                o:SetAttribute("type", "macro")
                o:SetAttribute("macrotext", "/click " .. mapButton)
                o:SetFrameStrata(journal:GetFrameStrata())
                o:SetFrameLevel(math.min(9000, journal:GetFrameLevel() + 300))
                o:ClearAllPoints()
                o:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l, b)
                o:SetSize(w, h)
                o:Show()
                local blocker = o.fdjBlocker
                blocker:SetFrameStrata(o:GetFrameStrata())
                blocker:SetFrameLevel(o:GetFrameLevel() + 1)
                blocker:ClearAllPoints()
                blocker:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l, b)
                blocker:SetSize(w, h)
                blocker:Hide()
                armed = true
            end
        end
    end
    if armed then combatWatch:Show() end
end

local function DisarmCombatClicks()
    combatWatch:Hide()
    for _, o in pairs(combatClicks) do
        o:Hide()
        o.fdjBlocker:Hide()
        if o.fdjReal and o.fdjReal.UnlockHighlight then o.fdjReal:UnlockHighlight() end
        o.fdjReal = nil
    end
end

local combatEvents = CreateFrame("Frame")
combatEvents:RegisterEvent("PLAYER_LOGIN")
combatEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
combatEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
combatEvents:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        pcall(ArmCombatClicks)
    elseif event == "PLAYER_REGEN_ENABLED" then
        pcall(DisarmCombatClicks)
    elseif event == "PLAYER_LOGIN" then
        for i = 1, 2 do combatClicks[i] = combatClicks[i] or MakeCombatClick(i) end
        -- Dev: /dj devmap says what the combat path found (off for release).
        local base = SlashCmdList and SlashCmdList.FOREVERDUNGEONJOURNAL
        if false and base then
            SlashCmdList.FOREVERDUNGEONJOURNAL = function(msg, ...)
                local cmd = tostring(msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
                if cmd == "devmap" then
                    local made, armed = 0, 0
                    for _, o in pairs(combatClicks) do
                        made = made + 1
                        if o:IsShown() then armed = armed + 1 end
                    end
                    local protected = WorldMapFrame and WorldMapFrame.IsProtected and WorldMapFrame:IsProtected()
                    print("|cffd8a83cDungeon Journal:|r map in combat (dev): game map button "
                        .. tostring(GameMapButtonName() or "NOT FOUND") .. ", secure buttons " .. made
                        .. ", armed now " .. armed .. ", world map protected " .. tostring(protected))
                    return
                end
                return base(msg, ...)
            end
        end
    end
end)
-- END combatmap

-- BEGIN devmapdump
-- Test builds 1.6.9 and 1.6.10 saved every map floor for research. That is
-- done: drop the saved copy.
local dumpCleanup = CreateFrame("Frame")
dumpCleanup:RegisterEvent("PLAYER_LOGIN")
dumpCleanup:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if type(ForeverDungeonJournalDB) == "table" then ForeverDungeonJournalDB.devMapDump = nil end
end)
-- END devmapdump


-- BEGIN mapquests
-- Quest spots on the dungeon maps (FDJ.MAP_QUEST_PINS, Data/QuestMaps.lua):
-- a yellow ! where a quest starts, a yellow ? where one is handed in or
-- done on the spot (an object to loot or use, a place to explore). Only
-- the quests the quest list shows (its faction, class quests as set, RPG
-- Mode's unlocked ones). Hover: what to do there; click: the quest's page.
-- pinlog: a spot with something to do for a quest in the player's log (hand
-- it in, loot, use, explore) shows ?, like the game's own NPCs, even when
-- another quest also starts there (Daewyn Songblade: Songblade Search is
-- handed in, Fallen in the Fen starts); a quest already taken or done does
-- not make a !. The pins follow the quest log while the map is open.
do
    local pool = {}

    -- A thin black edge around a ! / ? icon, so it stands out on the light
    -- map parchment: eight black copies of the icon just behind it.
    local STROKE = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 }, { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }
    function FDJ.StrokeIcon(owner, icon, size)
        if not owner or not icon then return end
        local tex = icon.GetTexture and icon:GetTexture()
        if not tex then return end
        local w = math.max(1, math.floor((size or 24) * 0.06 + 0.5))
        owner.fdjStroke = owner.fdjStroke or {}
        for i, o in ipairs(STROKE) do
            local s = owner.fdjStroke[i]
            if not s then
                s = owner:CreateTexture(nil, "ARTWORK")
                owner.fdjStroke[i] = s
            end
            s:SetTexture(tex)
            s:SetVertexColor(0, 0, 0, 1)
            s:ClearAllPoints()
            s:SetPoint("TOPLEFT", icon, "TOPLEFT", o[1] * w, o[2] * w)
            s:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", o[1] * w, o[2] * w)
            s:Show()
        end
    end

    local function L(key, ...)
        if FDJ.L then return FDJ.L(key, ...) end
        return key
    end

    local function Plain(v)
        if type(issecretvalue) == "function" and issecretvalue(v) then return nil end
        return v
    end

    -- The quest's entry in the journal (a chain step: its chain's entry).
    local function Entry(q)
        local d = FDJ.DB and FDJ.DB[q.dungeon]
        local want = q.main or q.id
        for _, quest in ipairs((d and d.quests) or {}) do
            if type(quest) == "table" and quest.id == want then return quest end
        end
    end

    local function Shown(q, faction)
        local entry = Entry(q)
        if not entry then return false end
        if faction and FDJ.QuestMatchesFaction and not FDJ.QuestMatchesFaction(entry, faction) then return false end
        if FDJ.RPGQuestHidden and FDJ.RPGQuestHidden(q.dungeon, entry) then return false end
        return true
    end

    local function ItemName(id, fallback)
        local name
        if id and GetItemInfo then
            local ok, n = pcall(GetItemInfo, id)
            if ok then name = Plain(n) end
        end
        if not name and id and C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
        if type(name) == "string" and name ~= "" then return name end
        return fallback or ""
    end

    local function Title(q)
        if FDJ.LocalizeQuestField then
            local ok, name = pcall(FDJ.LocalizeQuestField, q.id, "name", q.name)
            if ok and type(name) == "string" and name ~= "" then return name end
        end
        return q.name or ""
    end

    -- What to do there, one line per thing.
    local function Lines(q)
        if q.textKey then return { L(q.textKey) } end
        local out = {}
        for _, act in ipairs(q.acts or {}) do
            if act == "start" then
                out[#out + 1] = L("QUEST_STARTS_HERE")
            elseif act == "end" then
                out[#out + 1] = L("TURN_IN_HERE")
            elseif act == "loot" then
                out[#out + 1] = L("MAP_OBJ_LOOT", ItemName(q.item, q.itemName))
            elseif act == "use" then
                out[#out + 1] = L("MAP_OBJ_USE")
            elseif act == "explore" then
                out[#out + 1] = L("MAP_OBJ_EXPLORE")
            end
        end
        return out
    end

    local function OnEnter(self)
        local spots = self.fdjSpots
        if not spots then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local first = true
        local function Add(text, r, g, b, wrap)
            if first then
                GameTooltip:SetText(text, r, g, b, 1, wrap)
                first = false
            else
                GameTooltip:AddLine(text, r, g, b, wrap)
            end
        end
        for i, spot in ipairs(spots) do
            if i > 1 then GameTooltip:AddLine(" ") end
            if spot.name and spot.name ~= "" then
                Add(FDJ.LocalizeFreeText and FDJ.LocalizeFreeText(spot.name) or spot.name, 1, 1, 1)
            end
            for _, q in ipairs(spot.shown) do
                Add(Title(q), 1, 0.82, 0)
                for _, line in ipairs(Lines(q)) do Add(line, 0.92, 0.92, 0.92, true) end
            end
        end
        GameTooltip:Show()
    end

    local function OnClick(self)
        local q = self.fdjFirst
        if not q then return end
        local main = q.main or q.id
        local step = q.main and q.id or nil
        GameTooltip:Hide()
        -- On the world map (the dungeon map shown over M): the journal opens.
        if FDJ.IsWorldMapOverlayAttached and FDJ.IsWorldMapOverlayAttached() and FDJ.OpenQuestFromWorldMap then
            FDJ.OpenQuestFromWorldMap(q.dungeon, main, step)
            return
        end
        if step and FDJ.OpenQuestChainStep then
            FDJ.OpenQuestChainStep(q.dungeon, main, step)
        elseif FDJ.OpenQuestPage then
            FDJ.OpenQuestPage(q.dungeon, main)
        end
    end

    local last -- the last call's arguments, to redraw the pins alone
    -- Called by the dungeon map (Core/Journal.lua) for the level it shows.
    function FDJ.RenderMapQuestPins(dungeonName, floorIndex, holder, artW, artH, baseH, faction)
        last = { dungeonName, floorIndex, holder, artW, artH, baseH, faction }
        local list = (FDJ.MAP_QUEST_PINS and FDJ.MAP_QUEST_PINS[dungeonName]) or {}
        -- The quest tracker's ? / ! for a quest already marks it here: no
        -- second one for that quest.
        local mapData = FDJ.DUNGEON_MAPS and FDJ.DUNGEON_MAPS[dungeonName]
        local tracked = mapData and FDJ.dungeonTurnIns and FDJ.dungeonTurnIns[mapData]
        local skip = tracked and (tracked.floor or 1) == floorIndex and tracked.questID or nil
        local n = 0
        local inLog = FDJ.IsQuestInLog or function() return false end
        local turnedIn = FDJ.QuestTurnedIn or function() return false end
        for _, pin in ipairs(list) do
            if (pin.floor or 1) == floorIndex then
                local spots, start, firstQuest = {}, false, nil
                local logged, available, firstLogged = false, false, nil -- pinlog
                for _, spot in ipairs(pin.spots or {}) do
                    local shown = {}
                    for _, q in ipairs(spot.quests or {}) do
                        if q.id ~= skip and Shown(q, faction) then
                            shown[#shown + 1] = q
                            firstQuest = firstQuest or q
                            local have = inLog(q.id) and true or false
                            for _, act in ipairs(q.acts or {}) do
                                if act == "start" then
                                    start = true
                                    if not have and not turnedIn(q.id) then available = true end
                                elseif have then
                                    logged = true
                                    firstLogged = firstLogged or q
                                end
                            end
                        end
                    end
                    if #shown > 0 then spots[#spots + 1] = { name = spot.name, shown = shown } end
                end
                -- pinlog: ? for a quest in the log, else ! for one to take;
                -- nothing to do there now (quests not taken yet, or taken or
                -- done already): its usual icon, greyed.
                local bang = (not logged) and (available or start)
                local idle = not logged and not available
                firstQuest = firstLogged or firstQuest
                if #spots > 0 then
                    n = n + 1
                    local b = pool[n]
                    if not b then
                        b = CreateFrame("Button", nil, holder)
                        b.icon = b:CreateTexture(nil, "OVERLAY")
                        b.icon:SetAllPoints()
                        b:SetScript("OnEnter", OnEnter)
                        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
                        b:SetScript("OnClick", OnClick)
                        pool[n] = b
                    end
                    if b:GetParent() ~= holder then b:SetParent(holder) end
                    b.fdjSpots, b.fdjFirst, b.fdjStart = spots, firstQuest, bang
                    b.fdjFloor, b.fdjX, b.fdjY = pin.floor or 1, pin.x, pin.y -- mapfocus
                    b.icon:SetTexture(bang and "Interface\\GossipFrame\\AvailableQuestIcon" or "Interface\\GossipFrame\\ActiveQuestIcon")
                    if b.icon.SetDesaturated then b.icon:SetDesaturated(idle) end
                    b.icon:SetAlpha(idle and 0.75 or 1)
                    local size = math.max(22, math.floor((baseH or 0) * 0.07))
                    b:SetSize(size, size)
                    FDJ.StrokeIcon(b, b.icon, size)
                    b:SetFrameLevel(holder:GetFrameLevel() + 15)
                    b:ClearAllPoints()
                    b:SetPoint("CENTER", holder, "TOPLEFT", pin.x * artW, -(pin.y * artH))
                    b:Show()
                end
            end
        end
        for i = n + 1, #pool do pool[i]:Hide() end
        return n
    end

    -- The quest tracker's ? taken off the map (right-click): its quest's
    -- own spot comes back.
    function FDJ.RefreshMapQuestPins()
        if last then return FDJ.RenderMapQuestPins(unpack(last, 1, 7)) end
    end

    -- pinlog: a quest taken, handed in or dropped while the map is open
    -- turns its spot's ! into ? (and back) right away.
    local watcher = CreateFrame("Frame")
    for _, event in ipairs({ "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED" }) do
        pcall(watcher.RegisterEvent, watcher, event)
    end
    local pending = false
    watcher:SetScript("OnEvent", function()
        if pending or not last or not (last[3] and last[3].IsVisible and last[3]:IsVisible()) then return end
        pending = true
        local function Redraw()
            pending = false
            if last and last[3] and last[3]:IsVisible() then pcall(FDJ.RefreshMapQuestPins) end
        end
        if C_Timer and C_Timer.After then C_Timer.After(0.5, Redraw) else Redraw() end
    end)

    -- The pins (shown ones first), for the tests.
    function FDJ.MapQuestPinButtons() return pool end

    -- A quest item found on one of these spots (the BFD manuscript's chest):
    -- the dungeon map and level where it is, for the item's click.
    function FDJ.MapQuestItemSpot(questID, itemID)
        if not questID or not itemID then return nil end
        for name, list in pairs(FDJ.MAP_QUEST_PINS or {}) do
            for _, pin in ipairs(list) do
                for _, spot in ipairs(pin.spots or {}) do
                    for _, q in ipairs(spot.quests or {}) do
                        if q.item == itemID and (q.id == questID or q.main == questID) then
                            return { dungeon = name, floor = pin.floor or 1, x = pin.x, y = pin.y, label = spot.name, questID = questID }
                        end
                    end
                end
            end
        end
    end
end
-- END mapquests

-- BEGIN arrow
-- The waypoint arrow. A spot shown with Show on Map, Show Turn In, a
-- dungeon's Show Location or a ! / ? in the quest tracker also gets an arrow
-- on the screen that points the way, with the distance, under the quest's
-- name. A tracked quest chain page (the Cozy Sleeping Bag) moves it on by
-- itself: to where the next step is picked up, then to where it is handed in.
-- On another continent it points to the boat or zeppelin that gets there
-- first ("Take the boat to Darkshore"), then on from where it lands. When a
-- flight point the character has found saves enough of the way, it points to
-- the flight master first ("Fly to The Sepulcher"), and in the air counts
-- down the flight (as long as it took last time; the first time, from the
-- length of the flight's path). Near an NPC who stands well
-- below or above the ground around (a crypt, a tower top), it says so ("Below
-- ground: find the way down") and does not take standing over them as there.
-- Close to a quest NPC, a click on it targets and marks the NPC; elsewhere a
-- click shows the spot on the map. Drag it (by the arrow itself) anywhere;
-- right-click hides it; it goes away on arrival (a chain's spot only
-- steps aside until the step moves on) and is not shown inside instances.
do
    local ART = "Interface\\AddOns\\ForeverDungeonJournal\\Media\\WaypointArrow"
    local FALLBACK_ART = "Interface\\Minimap\\MinimapArrow" -- until the game has seen the new file
    local ARRIVED = 8      -- yards: there
    local STEP = 0.05      -- seconds between redraws
    local PLAN_EVERY = 0.5 -- seconds between working out the way again
    local DOCK = 25        -- yards: at the boat's or zeppelin's dock
    local OFF_DOCK = 1000  -- yards: that far from the dock again, not on the boat after all
    local NEAR_NPC = 120   -- yards: a click targets and marks the NPC
    local AT_MASTER = 12   -- yards: at the flight master
    local FLY_SPEED = 2.5  -- a flight covers the ground this many times faster
    local FLY_EXTRA = 100  -- yards' worth of time a flight costs on top (the flight master, landing)
    local FLY_MIN = 500    -- yards: shorter ways are not worth a flight
    local FLY_WORTH = 0.85 -- fly when that takes less than this share of the way there
    local FLIGHT_SPEED = 30  -- yards a second along a flight's path (Classic gryphons and wind riders)
    local FLIGHT_STOP = 2    -- seconds each hop costs on top (taking off, landing)
    local FLIGHT_CURVE = 1.4 -- a path not known: this many times the straight line (known paths: half are under 1.38)
    local FAR_ZONE = 500   -- yards: a flight point in another zone than where one stands (or is going) counts this much farther (zone borders are mostly mountains: Brackenwall is not 750 yards from the Field of Giants)
    local FLOOR_NEAR = 100 -- yards: near enough for "below / above ground" to matter

    do
        local strings = {
            enUS = { ARROW_DISTANCE = "%d yds", ARROW_TIP_MOVE = "Drag to move.", ARROW_TIP_HIDE = "Right-click to hide the arrow.",
                ARROW_BOAT = "Take the boat to %s", ARROW_ZEPPELIN = "Take the zeppelin to %s", ARROW_FLY = "Fly to %s" },
            deDE = { ARROW_DISTANCE = "%d m", ARROW_TIP_MOVE = "Ziehen zum Verschieben.", ARROW_TIP_HIDE = "Rechtsklick blendet den Pfeil aus.",
                ARROW_BOAT = "Nimm das Schiff nach %s", ARROW_ZEPPELIN = "Nimm den Zeppelin nach %s", ARROW_FLY = "Flieg nach %s" },
            frFR = { ARROW_DISTANCE = "%d m", ARROW_TIP_MOVE = "Faites glisser pour déplacer.", ARROW_TIP_HIDE = "Clic droit pour masquer la flèche.",
                ARROW_BOAT = "Prenez le bateau pour %s", ARROW_ZEPPELIN = "Prenez le zeppelin pour %s", ARROW_FLY = "Volez vers %s" },
            esES = { ARROW_DISTANCE = "%d m", ARROW_TIP_MOVE = "Arrastra para mover.", ARROW_TIP_HIDE = "Clic derecho para ocultar la flecha.",
                ARROW_BOAT = "Toma el barco a %s", ARROW_ZEPPELIN = "Toma el zepelín a %s", ARROW_FLY = "Vuela a %s" },
            itIT = { ARROW_DISTANCE = "%d m", ARROW_TIP_MOVE = "Trascina per spostare.", ARROW_TIP_HIDE = "Clic destro per nascondere la freccia.",
                ARROW_BOAT = "Prendi la nave per %s", ARROW_ZEPPELIN = "Prendi lo zeppelin per %s", ARROW_FLY = "Vola a %s" },
            ptBR = { ARROW_DISTANCE = "%d m", ARROW_TIP_MOVE = "Arraste para mover.", ARROW_TIP_HIDE = "Clique com o botão direito para ocultar a seta.",
                ARROW_BOAT = "Pegue o barco para %s", ARROW_ZEPPELIN = "Pegue o zepelim para %s", ARROW_FLY = "Voe para %s" },
            ruRU = { ARROW_DISTANCE = "%d м", ARROW_TIP_MOVE = "Перетащите, чтобы переместить.", ARROW_TIP_HIDE = "Щелкните правой кнопкой, чтобы скрыть стрелку.",
                ARROW_BOAT = "Корабль: %s", ARROW_ZEPPELIN = "Дирижабль: %s", ARROW_FLY = "Полёт: %s" },
            koKR = { ARROW_DISTANCE = "%d미터", ARROW_TIP_MOVE = "드래그하여 이동합니다.", ARROW_TIP_HIDE = "오른쪽 클릭으로 화살표를 숨깁니다.",
                ARROW_BOAT = "%s행 배를 타세요", ARROW_ZEPPELIN = "%s행 비행선을 타세요", ARROW_FLY = "%s(으)로 비행하세요" },
            zhCN = { ARROW_DISTANCE = "%d码", ARROW_TIP_MOVE = "拖动以移动。", ARROW_TIP_HIDE = "右键点击隐藏箭头。",
                ARROW_BOAT = "乘船前往%s", ARROW_ZEPPELIN = "乘坐飞艇前往%s", ARROW_FLY = "飞往%s" },
            zhTW = { ARROW_DISTANCE = "%d碼", ARROW_TIP_MOVE = "拖曳以移動。", ARROW_TIP_HIDE = "右鍵點擊隱藏箭頭。",
                ARROW_BOAT = "搭船前往%s", ARROW_ZEPPELIN = "搭乘飛艇前往%s", ARROW_FLY = "飛往%s" },
        }
        local more = {
            enUS = { ARROW_FLYING = "Flying to %s", ARROW_BELOW = "Below ground: find the way down", ARROW_ABOVE = "Upstairs: find the way up", ARROW_TIP_MAP = "Click to show it on the map.",
                ARROW_PORTAL = "Take the portal to %s", ARROW_HEARTH = "Hearth to %s" },
            deDE = { ARROW_FLYING = "Flug nach %s", ARROW_BELOW = "Unter der Erde: such den Weg nach unten", ARROW_ABOVE = "Weiter oben: such den Weg nach oben", ARROW_TIP_MAP = "Klicken zeigt es auf der Karte.",
                ARROW_PORTAL = "Nimm das Portal nach %s", ARROW_HEARTH = "Ruhestein nach %s" },
            frFR = { ARROW_FLYING = "Vol vers %s", ARROW_BELOW = "Sous terre : trouvez le chemin pour descendre", ARROW_ABOVE = "En hauteur : trouvez le chemin pour monter", ARROW_TIP_MAP = "Cliquez pour l'afficher sur la carte.",
                ARROW_PORTAL = "Prenez le portail vers %s", ARROW_HEARTH = "Pierre de foyer vers %s" },
            esES = { ARROW_FLYING = "Volando a %s", ARROW_BELOW = "Bajo tierra: busca el camino para bajar", ARROW_ABOVE = "Arriba: busca el camino para subir", ARROW_TIP_MAP = "Haz clic para verlo en el mapa.",
                ARROW_PORTAL = "Toma el portal a %s", ARROW_HEARTH = "Piedra de hogar a %s" },
            itIT = { ARROW_FLYING = "In volo verso %s", ARROW_BELOW = "Sottoterra: trova la via per scendere", ARROW_ABOVE = "Più in alto: trova la via per salire", ARROW_TIP_MAP = "Clicca per vederlo sulla mappa.",
                ARROW_PORTAL = "Prendi il portale per %s", ARROW_HEARTH = "Pietra del ritorno: %s" },
            ptBR = { ARROW_FLYING = "Voando para %s", ARROW_BELOW = "No subsolo: encontre o caminho para descer", ARROW_ABOVE = "Mais acima: encontre o caminho para subir", ARROW_TIP_MAP = "Clique para ver no mapa.",
                ARROW_PORTAL = "Pegue o portal para %s", ARROW_HEARTH = "Pedra de regresso para %s" },
            ruRU = { ARROW_FLYING = "Полёт: %s", ARROW_BELOW = "Под землёй: найдите спуск", ARROW_ABOVE = "Выше: найдите подъём", ARROW_TIP_MAP = "Щелкните, чтобы показать на карте.",
                ARROW_PORTAL = "Портал: %s", ARROW_HEARTH = "Камень возвращения: %s" },
            koKR = { ARROW_FLYING = "%s(으)로 비행 중", ARROW_BELOW = "지하: 내려가는 길을 찾으세요", ARROW_ABOVE = "위층: 올라가는 길을 찾으세요", ARROW_TIP_MAP = "클릭하면 지도에 표시합니다.",
                ARROW_PORTAL = "%s행 차원문을 타세요", ARROW_HEARTH = "귀환석: %s" },
            zhCN = { ARROW_FLYING = "正在飞往%s", ARROW_BELOW = "在地下：找路下去", ARROW_ABOVE = "在上方：找路上去", ARROW_TIP_MAP = "点击在地图上显示。",
                ARROW_PORTAL = "使用传送门前往%s", ARROW_HEARTH = "炉石回到%s" },
            zhTW = { ARROW_FLYING = "正在飛往%s", ARROW_BELOW = "在地下：找路下去", ARROW_ABOVE = "在上方：找路上去", ARROW_TIP_MAP = "點擊在地圖上顯示。",
                ARROW_PORTAL = "使用傳送門前往%s", ARROW_HEARTH = "爐石回到%s" },
        }
        for locale, entries in pairs(more) do
            for key, value in pairs(entries) do strings[locale][key] = value end
        end
        for locale, entries in pairs(strings) do
            local t = FDJ.Locales and FDJ.Locales[locale]
            if t then
                for key, value in pairs(entries) do
                    if t[key] == nil then t[key] = value end
                end
            end
        end
    end

    local function Number(v)
        if type(issecretvalue) == "function" and issecretvalue(v) then return nil end
        return type(v) == "number" and v or nil
    end
    local function Saved()
        if type(ForeverDungeonJournalDB) ~= "table" then ForeverDungeonJournalDB = {} end
        if type(ForeverDungeonJournalDB.arrow) ~= "table" then ForeverDungeonJournalDB.arrow = {} end
        return ForeverDungeonJournalDB.arrow
    end
    -- The followed spots the character has reached or hidden, by source.
    local function Done()
        if type(ForeverDungeonJournalCharacterDB) ~= "table" then ForeverDungeonJournalCharacterDB = {} end
        local db = ForeverDungeonJournalCharacterDB
        if type(db.arrowDone) ~= "table" then db.arrowDone = {} end
        return db.arrowDone
    end

    local function SpotKey(spot)
        return string.format("%s|%.4f|%.4f", tostring(spot.mapID), tonumber(spot.x) or 0, tonumber(spot.y) or 0)
    end

    -- Map spot -> world position (yards) and continent.
    local function World(mapID, x, y)
        if not (C_Map and type(C_Map.GetWorldPosFromMapPos) == "function") then return nil end
        if type(x) ~= "number" or type(y) ~= "number" then return nil end
        local vector = (type(CreateVector2D) == "function" and CreateVector2D(x, y)) or { x = x, y = y }
        local ok, continent, pos = pcall(C_Map.GetWorldPosFromMapPos, mapID, vector)
        if not ok or type(pos) ~= "table" then return nil end
        local wx, wy = pos.x, pos.y
        if (wx == nil or wy == nil) and pos.GetXY then wx, wy = pos:GetXY() end
        wx, wy = Number(wx), Number(wy)
        if not wx or not wy then return nil end
        return wx, wy, Number(continent)
    end
    local worldCache = {}
    local function SpotWorld(spot)
        local key = SpotKey(spot)
        local hit = worldCache[key]
        if hit == nil then
            local wx, wy, continent = World(spot.mapID, tonumber(spot.x) or 0, tonumber(spot.y) or 0)
            hit = wx and { wx, wy, continent, map = tonumber(spot.mapID) } or false
            worldCache[key] = hit
        end
        return hit or nil
    end

    local function PlayerWorld()
        if type(UnitPosition) == "function" then
            local ok, px, py, _, continent = pcall(UnitPosition, "player")
            if ok then
                px, py = Number(px), Number(py)
                if px and py then return px, py, Number(continent) end
            end
        end
        if C_Map and type(C_Map.GetBestMapForUnit) == "function" and type(C_Map.GetPlayerMapPosition) == "function" then
            local okMap, mapID = pcall(C_Map.GetBestMapForUnit, "player")
            mapID = okMap and Number(mapID) or nil
            if mapID then
                local okPos, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
                if okPos and type(pos) == "table" then
                    local mx, my = pos.x, pos.y
                    if (mx == nil or my == nil) and pos.GetXY then mx, my = pos:GetXY() end
                    mx, my = Number(mx), Number(my)
                    if mx and my then return World(mapID, mx, my) end
                end
            end
        end
        return nil
    end

    local function InInstance()
        if type(IsInInstance) ~= "function" then return false end
        local ok, inside = pcall(IsInInstance)
        if not ok or (type(issecretvalue) == "function" and issecretvalue(inside)) then return false end
        return inside == true or inside == 1
    end
    local function OnTaxi()
        if type(UnitOnTaxi) ~= "function" then return false end
        local ok, flying = pcall(UnitOnTaxi, "player")
        if not ok or (type(issecretvalue) == "function" and issecretvalue(flying)) then return false end
        return flying == true or flying == 1
    end

    local function Indoors()
        if type(IsIndoors) ~= "function" then return false end
        local ok, inside = pcall(IsIndoors)
        if not ok or (type(issecretvalue) == "function" and issecretvalue(inside)) then return false end
        return inside == true or inside == 1
    end

    local function Yards(ax, ay, bx, by)
        local dx, dy = ax - bx, ay - by
        return math.sqrt(dx * dx + dy * dy)
    end
    local function Faction()
        if type(UnitFactionGroup) ~= "function" then return nil end
        local ok, faction = pcall(UnitFactionGroup, "player")
        if not ok or (type(issecretvalue) == "function" and issecretvalue(faction)) then return nil end
        return faction
    end

    -- way (1.9.2): places the straight line cannot be walked out of. Each is
    -- a region of its own, joined to the rest only by RIDES (portals, boats)
    -- and flights: Darnassus and the top of Teldrassil (1001), and Rut'theran
    -- Village at the foot of the tree (1002: the Teldrassil map south of
    -- SHORE). Anywhere else a region is the continent.
    local Way = {
        ISLANDS = { [1457] = 1001, [1438] = 1001 },
        SHORE = { [1438] = { 0.84, 1002 } },
        axes = {},
        RIDE_COST = { boat = 1200, zeppelin = 1200, portal = 30 }, -- yards' worth of time: waiting for it and the crossing
        RIDE_WORTH = 3000,  -- yards: a way this long in one region also looks for boats on the way
        HEARTH_ITEM = 6948, HEARTH_SPELL = 8690,
        HEARTH_CAST = 100,  -- yards' worth: casting it
        HEARTH_SAVES = 800, -- yards: only said when it saves this much
        HEARTH_NEAR = 300,  -- yards: standing about there already
        NAME_NEAR = 600,    -- yards: a flight point this close to where a ride lands names the place
        -- The capitals' innkeepers (Wowhead Forever): where a hearthstone
        -- set there lands, with the English names of the place.
        INNS = {
            { 1457, 0.672, 0.156, "Craftsmen's Terrace", "Darnassus" },
            { 1453, 0.526, 0.656, "Trade District", "Stormwind", "Stormwind City" },
            { 1455, 0.185, 0.515, "The Commons", "Ironforge" },
            { 1454, 0.541, 0.685, "Valley of Strength", "Orgrimmar" },
            { 1456, 0.457, 0.640, "Thunder Bluff" },
            { 1458, 0.674, 0.382, "Trade Quarter", "Undercity" },
        },
    }
    -- Map y (0 north .. 1 south) of a world point on a map.
    function Way.MapY(mapID, wx, wy)
        local axis = Way.axes[mapID]
        if axis == nil then
            local ax, ay = World(mapID, 0, 0)
            local bx, by = World(mapID, 0, 1)
            axis = (ax and bx) and { ax, ay, bx - ax, by - ay } or false
            Way.axes[mapID] = axis
        end
        if not axis then return nil end
        local len2 = axis[3] * axis[3] + axis[4] * axis[4]
        if len2 == 0 then return nil end
        return ((wx - axis[1]) * axis[3] + (wy - axis[2]) * axis[4]) / len2
    end
    function Way.Region(continent, mapID, wx, wy)
        local region = mapID and Way.ISLANDS[mapID]
        if not region or not continent then return continent end
        local shore = Way.SHORE[mapID]
        if shore and wx and wy then
            local y = Way.MapY(mapID, wx, wy)
            if y and y >= shore[1] then return shore[2] end
        end
        return region
    end

    -- Boats and zeppelins between the continents (WoW Forever's own routes,
    -- Auberdine -> Menethil -> Southshore -> Auberdine being one way round):
    -- from where it leaves to where it lands, { map, x, y }: where the game's
    -- own NPCs stand at each dock (dock and zeppelin masters, sentries, the
    -- dock's world marker; SOURCES.txt).
    local RIDES = {
        { kind = "boat", faction = "Alliance", from = { 1453, 0.2322, 0.5505 }, to = { 1439, 0.3079, 0.4082 } }, -- Stormwind Harbor -> Auberdine
        { kind = "boat", faction = "Alliance", from = { 1439, 0.3079, 0.4082 }, to = { 1453, 0.2322, 0.5505 } }, -- Auberdine -> Stormwind Harbor
        { kind = "boat", faction = "Alliance", from = { 1439, 0.3230, 0.4376 }, to = { 1437, 0.0483, 0.5704 } }, -- Auberdine -> Menethil Harbor
        { kind = "boat", faction = "Alliance", from = { 1424, 0.5068, 0.6935 }, to = { 1439, 0.3230, 0.4376 } }, -- Southshore -> Auberdine
        { kind = "boat", faction = "Alliance", from = { 1437, 0.0521, 0.6371 }, to = { 1445, 0.7128, 0.5629 } }, -- Menethil Harbor -> Theramore
        { kind = "boat", faction = "Alliance", from = { 1445, 0.7128, 0.5629 }, to = { 1437, 0.0521, 0.6371 } }, -- Theramore -> Menethil Harbor
        { kind = "boat", from = { 1434, 0.2608, 0.7335 }, to = { 1413, 0.6374, 0.3850 } }, -- Booty Bay -> Ratchet
        { kind = "boat", from = { 1413, 0.6374, 0.3850 }, to = { 1434, 0.2608, 0.7335 } }, -- Ratchet -> Booty Bay
        { kind = "boat", from = { 1446, 0.6757, 0.2310 }, to = { 2548, 0.7938, 0.5341 } }, -- Steamwheedle Port -> Powderfuse Port
        { kind = "boat", from = { 2548, 0.7938, 0.5341 }, to = { 1446, 0.6757, 0.2310 } }, -- Powderfuse Port -> Steamwheedle Port
        { kind = "zeppelin", faction = "Horde", from = { 1411, 0.5082, 0.1354 }, to = { 1420, 0.6074, 0.5887 } }, -- Orgrimmar -> Undercity
        { kind = "zeppelin", faction = "Horde", from = { 1420, 0.6074, 0.5887 }, to = { 1411, 0.5082, 0.1354 } }, -- Undercity -> Orgrimmar
        { kind = "zeppelin", faction = "Horde", from = { 1411, 0.5069, 0.1289 }, to = { 1434, 0.3143, 0.2991 } }, -- Orgrimmar -> Grom'gol
        { kind = "zeppelin", faction = "Horde", from = { 1434, 0.3143, 0.2991 }, to = { 1411, 0.5069, 0.1289 } }, -- Grom'gol -> Orgrimmar
        { kind = "zeppelin", faction = "Alliance", from = { 2521, 0.6569, 0.8322 }, to = { 1416, 0.1230, 0.5649 } }, -- Zephras Isle -> Dalaran
        { kind = "zeppelin", faction = "Horde", from = { 2521, 0.5798, 0.8057 }, to = { 1412, 0.3340, 0.2250 } }, -- Zephras Isle -> Mulgore
        -- way (1.9.2): Teldrassil. The portals: west of the Temple Gardens
        -- in Darnassus (30, 41) and on the hill in Rut'theran Village (55,
        -- 89); the Moonspray's piers in Rut'theran (south of Nessa
        -- Shadowsong, 56.2, 92.4) and Auberdine (the northern pier): where
        -- they are on the maps, to a few yards.
        { kind = "portal", from = { 1457, 0.3000, 0.4120 }, to = { 1438, 0.5530, 0.8930 } }, -- Darnassus -> Rut'theran Village
        { kind = "portal", from = { 1438, 0.5520, 0.8920 }, to = { 1457, 0.3010, 0.4130 } }, -- Rut'theran Village -> Darnassus
        { kind = "boat", from = { 1438, 0.5560, 0.9650 }, to = { 1439, 0.3240, 0.3980 } }, -- Rut'theran Village -> Auberdine
        { kind = "boat", from = { 1439, 0.3240, 0.3980 }, to = { 1438, 0.5560, 0.9650 } }, -- Auberdine -> Rut'theran Village
    }
    local rideWorld = {}
    -- Both ends in world yards { x, y, continent } (nil: not on this client).
    local function Ends(ride)
        local hit = rideWorld[ride]
        if hit == nil then
            local fx, fy, fc = World(ride.from[1], ride.from[2], ride.from[3])
            local tx, ty, tc = World(ride.to[1], ride.to[2], ride.to[3])
            -- way: each end's region and map too.
            hit = (fx and fc and tx and tc) and {
                { fx, fy, fc, region = Way.Region(fc, ride.from[1], fx, fy), map = ride.from[1] },
                { tx, ty, tc, region = Way.Region(tc, ride.to[1], tx, ty), map = ride.to[1] } } or false
            rideWorld[ride] = hit
        end
        if hit then return hit[1], hit[2] end
        return nil
    end
    local function Rides(faction, ride)
        return not ride.faction or ride.faction == faction
    end

    -- The flight points the character has found, by continent: the game's own
    -- list (the world map's flight points), { x, y, name } in world yards.
    local CONTINENT_MAPS = { 1415, 1414, 2665 } -- Eastern Kingdoms, Kalimdor, the Skyborne's isles
    local flights, flightsAt = nil, 0
    local function PlaceName(name)
        if type(name) ~= "string" then return "" end
        return name:match("^%s*(.-)%s*,") or name
    end
    local function OurSide(nodeFaction, faction)
        if nodeFaction == 1 then return faction == "Horde" end
        if nodeFaction == 2 then return faction == "Alliance" end
        return true
    end
    -- The flight points this character has found, by the flight map's names
    -- (lower case): the ones a flight master's map listed as where the
    -- character is (CURRENT) or can fly to (REACHABLE), kept in the
    -- character's saved variables. Only the flight map tells: the world
    -- map's isUndiscovered is not to be trusted on WoW Forever. 1.7.4: the
    -- list kept before took more than that, so it is started again once
    -- (flightPointsVersion) and filled at the next flight master.
    local FLIGHT_POINTS_VERSION = 2
    local flightsLearned = 0 -- goes up when the flight map shows a newly found one
    local function FoundFlights()
        if type(ForeverDungeonJournalCharacterDB) ~= "table" then ForeverDungeonJournalCharacterDB = {} end
        local db = ForeverDungeonJournalCharacterDB
        if db.flightPointsVersion ~= FLIGHT_POINTS_VERSION or type(db.flightPoints) ~= "table" then
            db.flightPoints = {}
            db.flightPointsVersion = FLIGHT_POINTS_VERSION
        end
        return db.flightPoints
    end
    local function RecordFlightMap()
        if type(NumTaxiNodes) ~= "function" or type(TaxiNodeName) ~= "function" then return end
        local ok, count = pcall(NumTaxiNodes)
        local found, any = FoundFlights(), false
        if type(TaxiNodeGetType) ~= "function" then return end -- no way to tell which are found
        for i = 1, (ok and Number(count)) or 0 do
            local okType, kind = pcall(TaxiNodeGetType, i)
            local okName, name = pcall(TaxiNodeName, i)
            if type(issecretvalue) == "function" and issecretvalue(name) then name = nil end
            if okType and (kind == "CURRENT" or kind == "REACHABLE") and okName and type(name) == "string" and name ~= "" then
                if not found[string.lower(name)] then any = true flightsLearned = flightsLearned + 1 end
                found[string.lower(name)] = true
            end
        end
        if any then flights = nil end
    end
    local function Found(node)
        local name = type(node.name) == "string" and string.lower(node.name) or nil
        return name ~= nil and FoundFlights()[name] == true
    end
    local function ReadFlights()
        flights = {}
        if not (C_TaxiMap and type(C_TaxiMap.GetTaxiNodesForMap) == "function") then return end
        local faction, seen = Faction(), {}
        local function Add(mapID, zoned)
            local ok, nodes = pcall(C_TaxiMap.GetTaxiNodesForMap, mapID)
            if not ok or type(nodes) ~= "table" then return 0 end
            local added = 0
            for _, node in ipairs(nodes) do
                local id = type(node) == "table" and Number(node.nodeID)
                if id and Found(node) and OurSide(node.faction, faction) and type(node.position) == "table" then
                    if seen[id] then
                        if seen[id].maps then seen[id].maps[mapID] = true end -- the same flight point on another map (a city's and its zone's)
                    else
                        local nx, ny = node.position.x, node.position.y
                        if (nx == nil or ny == nil) and node.position.GetXY then nx, ny = node.position:GetXY() end
                        local wx, wy, c = World(mapID, Number(nx), Number(ny))
                        if wx and c then
                            local entry = { wx, wy, name = PlaceName(node.name), c = c, maps = zoned and { [mapID] = true } or nil,
                                region = Way.Region(c, zoned and mapID or nil, wx, wy) } -- way: Rut'theran's is on its own
                            seen[id] = entry
                            flights[c] = flights[c] or {}
                            table.insert(flights[c], entry)
                            added = added + 1
                        end
                    end
                end
            end
            return added
        end
        -- Zone by zone (cities too), so each flight point knows the maps it
        -- is on; the continent's own list only when a game has no zone lists.
        for _, mapID in ipairs(CONTINENT_MAPS) do
            local added = 0
            if C_Map and type(C_Map.GetMapChildrenInfo) == "function" then
                local ok, zones = pcall(C_Map.GetMapChildrenInfo, mapID, 3, true)
                if ok and type(zones) == "table" then
                    for _, zone in ipairs(zones) do
                        if type(zone) == "table" and zone.mapID then added = added + Add(zone.mapID, true) end
                    end
                end
            end
            if added == 0 then Add(mapID) end
        end
    end
    local function FlightPoints(continent)
        local now = (GetTime and GetTime()) or 0
        if not flights or now - flightsAt > 60 then
            ReadFlights()
            flightsAt = now
        end
        return flights[continent]
    end
    do
        -- A flight point found, or the flight map opened: read them again.
        local watch = CreateFrame("Frame")
        for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "TAXIMAP_OPENED", "TAXIMAP_CLOSED", "TAXI_NODE_STATUS_CHANGED", "UI_INFO_MESSAGE" }) do
            pcall(watch.RegisterEvent, watch, event)
        end
        watch:SetScript("OnEvent", function(_, event)
            if event == "TAXIMAP_OPENED" or event == "TAXI_NODE_STATUS_CHANGED" then pcall(RecordFlightMap) end
            flights = nil
        end)
    end

    -- The flight under way: from / to (the flight map's names), at (when
    -- picked), up (when it took off), guess (seconds, a first guess). How long
    -- each flight took is kept (ForeverDungeonJournalDB.flightTimes, by
    -- "from>to") for the count-down next time.
    local flight
    local function FlightTimes()
        if type(ForeverDungeonJournalDB) ~= "table" then ForeverDungeonJournalDB = {} end
        if type(ForeverDungeonJournalDB.flightTimes) ~= "table" then ForeverDungeonJournalDB.flightTimes = {} end
        return ForeverDungeonJournalDB.flightTimes
    end
    local function NodeNamed(name)
        if not name then return nil end
        FlightPoints(0)
        for _, list in pairs(flights or {}) do
            for _, node in ipairs(list) do
                if node.name == name then return node end
            end
        end
        return nil
    end
    -- The flight map's names of where the player is and of the picked slot.
    local function TaxiName(i)
        if type(TaxiNodeName) ~= "function" or i == nil then return nil end
        local ok, name = pcall(TaxiNodeName, i)
        if not ok or (type(issecretvalue) == "function" and issecretvalue(name)) then return nil end
        return type(name) == "string" and name ~= "" and name or nil
    end
    local function TaxiNames(slot)
        local Name = TaxiName
        local from
        if type(NumTaxiNodes) == "function" and type(TaxiNodeGetType) == "function" then
            local ok, count = pcall(NumTaxiNodes)
            for i = 1, (ok and Number(count)) or 0 do
                local okType, kind = pcall(TaxiNodeGetType, i)
                if okType and kind == "CURRENT" then
                    from = Name(i)
                    break
                end
            end
        end
        return from, Name(slot)
    end
    -- How long a flight takes the first time (1.8.5): the yards it flies
    -- along its path, from Blizzard's TaxiPath tables of Classic Era (by way
    -- of Polestar's travel data, GPL-3.0-or-later): the flight masters
    -- { continent, wx, wy } by node id, and the one-way flights from, to,
    -- yards. A flight that changes gryphons on the way flies each hop.
    local TAXI_NODES = {
        [2] = { 0, -8840.6, 489.7 }, [4] = { 0, -10628.9, 1036.7 }, [5] = { 0, -9429.1, -2231.4 }, [6] = { 0, -4821.8, -1155.4 },
        [7] = { 0, -3792.3, -783.3 }, [8] = { 0, -5421.9, -2930 }, [10] = { 0, 478.9, 1536.6 }, [11] = { 0, 1568.6, 268 },
        [12] = { 0, -10515.5, -1261.7 }, [13] = { 0, -0.1, -859.9 }, [14] = { 0, -711.5, -515.5 }, [16] = { 0, -1240.5, -2515.1 },
        [17] = { 0, -916.3, -3496.9 }, [18] = { 0, -14444.3, 509.6 }, [19] = { 0, -14473, 464.1 }, [20] = { 0, -12414.2, 146.3 },
        [21] = { 0, -6634, -2180.1 }, [22] = { 1, -1197.2, 29.7 }, [23] = { 1, 1677.6, -4315.7 }, [25] = { 1, -441.8, -2596.1 },
        [26] = { 1, 6341.4, 557.7 }, [27] = { 1, 8643.6, 841 }, [28] = { 1, 2827.3, -289.2 }, [29] = { 1, 966.6, 1040.3 },
        [30] = { 1, -5407.7, -2414.3 }, [31] = { 1, -4491.9, -775.9 }, [32] = { 1, -3825.4, -4516.6 }, [33] = { 1, 2681.1, 1461.7 },
        [37] = { 1, 139.2, 1325.8 }, [38] = { 1, -1767.6, 3263.9 }, [39] = { 1, -7224, -3734.6 }, [40] = { 1, -7048.9, -3780.4 },
        [41] = { 1, -4373.8, 3338.6 }, [42] = { 1, -4419.9, 199.3 }, [43] = { 0, 283.7, -2002.8 }, [44] = { 1, 3661.5, -4390.4 },
        [45] = { 0, -11112.2, -3435.7 }, [48] = { 1, 5068.4, -337.2 }, [49] = { 1, 7458.5, -2487.2 }, [52] = { 1, 6799.2, -4742.4 },
        [53] = { 1, 6813.1, -4611.1 }, [55] = { 1, -3147.4, -2842.2 }, [56] = { 0, -10457, -3279.2 }, [58] = { 1, 3374.7, 997 },
        [61] = { 1, 2302.4, -2524.6 }, [62] = { 1, 7793.6, -2403.5 }, [63] = { 1, 7787.7, -2404.1 }, [64] = { 1, 2722, -3880.6 },
        [65] = { 1, 6205.9, -1949.6 }, [66] = { 0, 931.3, -1430.1 }, [67] = { 0, 2271.1, -5340.8 }, [68] = { 0, 2327.4, -5286.9 },
        [69] = { 1, 7470.4, -2123.4 }, [70] = { 0, -7504, -2187.5 }, [71] = { 0, -8364.6, -2738.4 }, [72] = { 1, -6811.4, 836.7 },
        [73] = { 1, -6761.8, 772 }, [74] = { 0, -6552.6, -1168.3 }, [75] = { 0, -6554.9, -1100.1 }, [76] = { 0, -635.3, -4720.5 },
        [77] = { 1, -2380.7, -1882.7 }, [79] = { 1, -6113.8, -1142.7 }, [80] = { 1, -894.6, -3773 },
    }
    local TAXI_FLOWN = {
        2, 4, 2319, 2, 5, 3368, 2, 6, 7748, 2, 12, 3469, 2, 19, 7317, 2, 45, 5268, 2, 71, 4700, 4, 2, 2565,
        4, 5, 3890, 4, 12, 2897, 4, 19, 5561, 5, 2, 3374, 5, 4, 4003, 5, 12, 1812, 5, 71, 1825, 6, 2, 6307,
        6, 7, 3861, 6, 8, 3037, 6, 14, 7938, 6, 16, 7585, 6, 43, 8941, 6, 66, 8816, 6, 67, 10440, 6, 74, 2594,
        7, 6, 2658, 7, 8, 4877, 7, 14, 3215, 7, 16, 3388, 8, 6, 3266, 8, 7, 4564, 8, 16, 4902, 10, 11, 3345,
        10, 13, 2847, 11, 10, 3180, 11, 13, 4224, 11, 17, 9014, 11, 21, 14630, 11, 68, 7849, 11, 76, 8530, 12, 2, 2629,
        12, 4, 2794, 12, 5, 1787, 12, 19, 5135, 12, 45, 2903, 13, 10, 2969, 13, 11, 4172, 13, 17, 3532, 13, 76, 5840,
        14, 6, 6174, 14, 7, 3301, 14, 16, 2214, 14, 43, 2139, 14, 66, 2418, 16, 6, 8109, 16, 7, 3776, 16, 8, 5113,
        16, 14, 2596, 16, 43, 2152, 17, 11, 7763, 17, 13, 3493, 17, 21, 7760, 17, 76, 2705, 18, 20, 3047, 18, 21, 12190,
        18, 56, 7986, 19, 2, 6585, 19, 4, 5439, 19, 12, 5242, 20, 18, 2422, 20, 21, 9802, 20, 56, 6151, 21, 11, 14918,
        21, 17, 7881, 21, 18, 12493, 21, 20, 9376, 21, 56, 8424, 21, 70, 2593, 21, 75, 1682, 22, 23, 6213, 22, 25, 4752,
        22, 29, 5439, 22, 30, 6113, 22, 38, 4772, 22, 40, 8693, 22, 42, 7563, 22, 44, 8070, 22, 55, 7149, 22, 77, 2599,
        23, 22, 6745, 23, 25, 3304, 23, 40, 12500, 23, 44, 2965, 23, 48, 7558, 23, 53, 9582, 23, 55, 6853, 23, 61, 2680,
        25, 22, 5461, 25, 23, 4252, 25, 29, 4495, 25, 30, 5532, 25, 40, 9093, 25, 42, 7547, 25, 44, 5051, 25, 48, 7603,
        25, 55, 4878, 25, 58, 6902, 25, 61, 4871, 25, 77, 2705, 25, 80, 1545, 26, 27, 2525, 26, 28, 5270, 26, 32, 20249,
        26, 33, 5432, 26, 37, 8723, 26, 41, 14168, 26, 49, 4525, 26, 64, 8981, 26, 65, 5682, 27, 26, 2551, 28, 26, 4426,
        28, 33, 4599, 28, 64, 4428, 29, 22, 5227, 29, 25, 4477, 29, 38, 4297, 30, 22, 6764, 30, 25, 5810, 30, 40, 2782,
        30, 42, 3685, 30, 77, 4111, 31, 32, 4780, 31, 39, 5122, 31, 41, 5335, 32, 26, 18600, 32, 31, 4887, 32, 37, 10013,
        32, 39, 4694, 32, 64, 7052, 32, 80, 3446, 33, 26, 5304, 33, 28, 4613, 33, 37, 3803, 37, 26, 8458, 37, 32, 9220,
        37, 33, 3581, 37, 41, 6949, 38, 22, 5342, 38, 29, 5966, 38, 42, 5873, 39, 31, 5304, 39, 32, 4606, 39, 73, 5907,
        39, 79, 3115, 40, 22, 9107, 40, 23, 10495, 40, 25, 9008, 40, 30, 2602, 40, 42, 5973, 40, 55, 6647, 40, 72, 6976,
        40, 79, 3218, 41, 26, 14014, 41, 31, 4635, 41, 37, 6797, 41, 73, 4774, 42, 22, 7777, 42, 25, 7915, 42, 30, 3215,
        42, 38, 6016, 42, 40, 6024, 42, 72, 3897, 43, 6, 7658, 43, 14, 2039, 43, 16, 2267, 43, 66, 1590, 43, 67, 4922,
        44, 22, 7700, 44, 23, 3622, 44, 25, 5163, 44, 48, 6955, 44, 53, 3905, 44, 61, 2795, 45, 2, 5672, 45, 12, 2748,
        45, 71, 6251, 48, 23, 7747, 48, 25, 7227, 48, 44, 7221, 48, 53, 5700, 48, 69, 4947, 49, 26, 4247, 49, 52, 3900,
        49, 65, 1840, 52, 49, 3639, 52, 64, 5265, 52, 65, 3670, 53, 23, 9115, 53, 44, 4041, 53, 48, 5853, 53, 69, 4016,
        55, 22, 6729, 55, 23, 6496, 55, 25, 4848, 55, 40, 6660, 56, 18, 7798, 56, 20, 5646, 56, 21, 8555, 56, 70, 5916,
        58, 25, 6827, 58, 61, 5013, 61, 23, 2869, 61, 25, 4806, 61, 44, 2870, 61, 58, 4995, 62, 27, 4559, 63, 22, 16313,
        64, 26, 9038, 64, 28, 4578, 64, 32, 7242, 64, 52, 5355, 64, 65, 8502, 64, 80, 4062, 65, 26, 5622, 65, 49, 2005,
        65, 52, 3601, 65, 64, 8465, 66, 6, 7782, 66, 14, 2559, 66, 43, 1958, 66, 67, 4390, 67, 6, 11024, 67, 43, 4871,
        67, 66, 4484, 68, 11, 7837, 68, 76, 4232, 69, 48, 4713, 69, 53, 4256, 70, 21, 2994, 70, 56, 6376, 70, 75, 2154,
        71, 2, 4528, 71, 5, 1884, 71, 45, 6288, 71, 74, 3090, 72, 40, 7224, 72, 42, 3895, 72, 79, 2896, 73, 39, 5652,
        73, 41, 5239, 73, 79, 2745, 74, 6, 2802, 74, 71, 2865, 75, 21, 2090, 75, 70, 2297, 76, 11, 8538, 76, 13, 4767,
        76, 17, 2785, 76, 68, 4159, 77, 22, 3410, 77, 25, 2380, 77, 30, 3750, 79, 39, 3100, 79, 40, 3396, 79, 72, 3003,
        79, 73, 2823, 80, 25, 2041, 80, 32, 3149, 80, 64, 3960,
    }
    local flown
    local function Flown()
        if not flown then
            flown = {}
            for i = 1, #TAXI_FLOWN - 2, 3 do
                local a = TAXI_FLOWN[i]
                flown[a] = flown[a] or {}
                flown[a][TAXI_FLOWN[i + 1]] = TAXI_FLOWN[i + 2]
            end
        end
        return flown
    end
    -- The node id of a flight point (one of FlightPoints'), by where it is.
    local function TaxiID(node)
        if type(node) ~= "table" then return nil end
        for id, n in pairs(TAXI_NODES) do
            if n[1] == node.c and Yards(node[1], node[2], n[2], n[3]) <= 60 then return id end
        end
        return nil
    end
    -- The shortest way from node id a to b through the flights (only
    -- through ids in allowed, when given): yards and hops.
    local function ShortestFlight(a, b, allowed)
        local graph = Flown()
        local dist, hops, done = { [a] = 0 }, { [a] = 0 }, {}
        while true do
            local u, best
            for id, d in pairs(dist) do
                if not done[id] and (not best or d < best) then u, best = id, d end
            end
            if not u then return nil end
            if u == b then return best, hops[u] end
            done[u] = true
            for v, yards in pairs(graph[u] or {}) do
                if (v == b or not allowed or allowed[v]) and not done[v] and (not dist[v] or best + yards < dist[v]) then
                    dist[v], hops[v] = best + yards, hops[u] + 1
                end
            end
        end
    end
    -- Seconds a picked flight takes: hop by hop as the flight map lists
    -- them, else the shortest way through the flight points the character
    -- has found, else the straight line bent by FLIGHT_CURVE.
    local function FlightGuess(slot, from, to)
        local function Node(name) return name and NodeNamed(PlaceName(name)) or nil end
        if type(GetNumRoutes) == "function" and type(TaxiGetNodeSlot) == "function" then
            local ok, count = pcall(GetNumRoutes, slot)
            count = ok and Number(count) or 0
            local total = 0
            for hop = 1, count do
                local okA, sa = pcall(TaxiGetNodeSlot, slot, hop, true)
                local okB, sb = pcall(TaxiGetNodeSlot, slot, hop, false)
                local a, b = okA and Node(TaxiName(sa)), okB and Node(TaxiName(sb))
                local ia, ib = TaxiID(a), TaxiID(b)
                local yards = ia and ib and Flown()[ia] and Flown()[ia][ib]
                if not yards and a and b then yards = Yards(a[1], a[2], b[1], b[2]) * FLIGHT_CURVE end
                if not yards then total = nil break end
                total = total + yards / FLIGHT_SPEED + FLIGHT_STOP
            end
            if total and count > 0 then return total end
        end
        local a, b = Node(from), Node(to)
        local ia, ib = TaxiID(a), TaxiID(b)
        if ia and ib then
            local allowed = {}
            for _, list in pairs(flights or {}) do
                for _, node in ipairs(list) do
                    local id = TaxiID(node)
                    if id then allowed[id] = true end
                end
            end
            local yards, hops = ShortestFlight(ia, ib, allowed)
            if not yards then yards, hops = ShortestFlight(ia, ib) end
            if yards then return yards / FLIGHT_SPEED + FLIGHT_STOP * hops end
        end
        if a and b then return Yards(a[1], a[2], b[1], b[2]) * FLIGHT_CURVE / FLIGHT_SPEED + FLIGHT_STOP end
        return nil
    end
    local function Clock(seconds)
        seconds = math.max(0, math.floor(seconds + 0.5))
        return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
    end
    -- Watches a picked flight take off and land (also with the arrow hidden).
    local clock = CreateFrame("Frame")
    clock:Hide()
    clock:SetScript("OnUpdate", function(self, elapsed)
        self.fdjWait = (self.fdjWait or 0) - (elapsed or 0)
        if self.fdjWait > 0 then return end
        self.fdjWait = 0.5
        local now = (GetTime and GetTime()) or 0
        if not flight then
            self:Hide()
        elseif OnTaxi() then
            flight.up = flight.up or now
        elseif flight.up then
            local took = now - flight.up
            if flight.from and flight.to and took >= 5 then
                FlightTimes()[flight.from .. ">" .. flight.to] = math.floor(took + 0.5)
            end
            flight = nil
            self:Hide()
        elseif now - (flight.at or now) > 20 then
            flight = nil -- never took off
            self:Hide()
        end
    end)
    local function Watch(new)
        flight = new
        clock.fdjWait = 0
        clock:Show()
    end
    if type(hooksecurefunc) == "function" and type(TakeTaxiNode) == "function" then
        hooksecurefunc("TakeTaxiNode", function(slot)
            local from, to = TaxiNames(slot)
            local picked = { from = from, to = to, at = (GetTime and GetTime()) or 0 }
            picked.guess = FlightGuess(slot, from, to)
            Watch(picked)
        end)
    end

    -- The map the player stands on (a zone, or a city), for the zone rule.
    local function PlayerMap()
        if not (C_Map and type(C_Map.GetBestMapForUnit) == "function") then return nil end
        local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
        return ok and Number(mapID) or nil
    end
    -- What a flight point costs on top when it is not on the given map
    -- (nil map, or a flight point whose maps are not known: nothing).
    local function Far(node, mapID)
        if not mapID or not node.maps then return 0 end
        return node.maps[mapID] and 0 or FAR_ZONE
    end

    -- The three flight points nearest to (x, y).
    local function Nearest(nodes, x, y)
        local a, b, c, da, db, dc
        for _, node in ipairs(nodes) do
            local d = Yards(x, y, node[1], node[2])
            if not da or d < da then
                c, dc, b, db, a, da = b, db, a, da, node, d
            elseif not db or d < db then
                c, dc, b, db = b, db, node, d
            elseif not dc or d < dc then
                c, dc = node, d
            end
        end
        return { a, b, c }
    end
    -- The best flight from (px, py) to (qx, qy) on continent c: from, to and
    -- what it costs (in yards on foot), counting the walks to and from it.
    -- fromMap / toMap: the maps (zones) where (px, py) and (qx, qy) are; a
    -- flight point on another map counts FAR_ZONE yards farther.
    -- way: fromR / toR, the regions the flight leaves from and lands in
    -- (nil: any).
    local function FlyCost(c, px, py, qx, qy, fromMap, toMap, fromR, toR)
        local nodes = FlightPoints(c)
        if not nodes or #nodes < 2 then return nil end
        local starts, ends = nodes, nodes
        if fromR or toR then
            starts, ends = {}, {}
            for _, node in ipairs(nodes) do
                local r = node.region or node.c
                if not fromR or r == fromR then starts[#starts + 1] = node end
                if not toR or r == toR then ends[#ends + 1] = node end
            end
        end
        local best, bestTo, least
        for _, a in ipairs(Nearest(starts, px, py)) do
            for _, b in ipairs(Nearest(ends, qx, qy)) do
                if a ~= b then
                    local cost = Yards(px, py, a[1], a[2]) + Far(a, fromMap) + Yards(a[1], a[2], b[1], b[2]) / FLY_SPEED + FLY_EXTRA + Yards(b[1], b[2], qx, qy) + Far(b, toMap)
                    if not least or cost < least then best, bestTo, least = a, b, cost end
                end
            end
        end
        return best, bestTo, least
    end
    -- How long the way is, in yards on foot: walking, or flying when quicker.
    -- way: between two regions only a flight gets there (nil: none).
    local function Travel(c, px, py, qx, qy, fromMap, toMap, fromR, toR)
        if fromR and toR and fromR ~= toR then
            local _, _, cost = FlyCost(c, px, py, qx, qy, fromMap, toMap, fromR, toR)
            return cost
        end
        local walk = Yards(px, py, qx, qy)
        if walk < FLY_MIN then return walk end
        local _, _, cost = FlyCost(c, px, py, qx, qy, fromMap, toMap, fromR, toR)
        return (cost and cost < walk) and cost or walk
    end
    -- The flight to take from (px, py) to (qx, qy), when it saves enough of
    -- the way (keep: the one already chosen, kept while it saves any).
    -- way: between two regions (fromR, toR) the flight is the only way.
    local function Flight(c, px, py, qx, qy, keep, fromMap, toMap, fromR, toR)
        local across = fromR ~= nil and toR ~= nil and fromR ~= toR
        local walk = across and math.huge or Yards(px, py, qx, qy)
        if keep and keep[1].c == c and (not fromR or (keep[1].region or keep[1].c) == fromR)
            and (not toR or (keep[2].region or keep[2].c) == toR) then
            local a, b = keep[1], keep[2]
            local cost = Yards(px, py, a[1], a[2]) + Far(a, fromMap) + Yards(a[1], a[2], b[1], b[2]) / FLY_SPEED + FLY_EXTRA + Yards(b[1], b[2], qx, qy) + Far(b, toMap)
            if cost < walk then return a, b end
        end
        if not across and walk < FLY_MIN then return nil end
        local a, b, cost = FlyCost(c, px, py, qx, qy, fromMap, toMap, fromR, toR)
        if a and (across or cost < walk * FLY_WORTH) then return a, b end
        return nil
    end

    -- way (1.9.2): the quickest way from p to t, points { x, y, continent,
    -- region =, map = }: on foot or by flight, and through as many boats,
    -- zeppelins and portals as it takes (Darnassus -> the portal -> the
    -- Moonspray -> Auberdine -> the boat to Stormwind). Returns the first
    -- ride to take (nil: none, straight there or by flight) and what the
    -- whole way costs in yards on foot (nil: no way known).
    function Way.Leg(a, b)
        if not a[3] or a[3] ~= b[3] then return nil end
        return Travel(a[3], a[1], a[2], b[1], b[2], a.map, b.map, a.region, b.region)
    end
    -- Ride end to ride end: the same until another flight point is found.
    function Way.CachedLeg(a, b)
        if Way.cacheFlights ~= flights then Way.cache, Way.cacheFlights = {}, flights end
        local row = Way.cache[a]
        if not row then
            row = {}
            Way.cache[a] = row
        end
        local hit = row[b]
        if hit == nil then
            hit = Way.Leg(a, b) or false
            row[b] = hit
        end
        return hit or nil
    end
    function Way.Search(p, t)
        local faction = Faction()
        local best = Way.Leg(p, t)
        local bestFirst
        local rides = {}
        for _, ride in ipairs(RIDES) do
            if Rides(faction, ride) then
                local from, to = Ends(ride)
                if from then rides[#rides + 1] = { ride = ride, from = from, to = to } end
            end
        end
        local cost, first, done = {}, {}, {}
        for i, r in ipairs(rides) do
            local leg = r.from[3] == p[3] and Way.Leg(p, r.from) or nil
            if leg then cost[i], first[i] = leg + (Way.RIDE_COST[r.ride.kind] or 0), r.ride end
        end
        while true do
            local u
            for i, c in pairs(cost) do
                if not done[i] and (not u or c < cost[u]) then u = i end
            end
            if not u or (best and cost[u] >= best) then break end
            done[u] = true
            local land = rides[u].to
            local rest = land[3] == t[3] and Way.Leg(land, t) or nil
            if rest and (not best or cost[u] + rest < best) then best, bestFirst = cost[u] + rest, first[u] end
            for i, r in ipairs(rides) do
                if not done[i] and r.from[3] == land[3] then
                    local leg = Way.CachedLeg(land, r.from)
                    if leg then
                        local c = cost[u] + leg + (Way.RIDE_COST[r.ride.kind] or 0)
                        if not cost[i] or c < cost[i] then cost[i], first[i] = c, first[u] end
                    end
                end
            end
        end
        return bestFirst, best
    end

    -- way: the hearthstone. Where it goes: where this character last set
    -- it or came out of it (ForeverDungeonJournalCharacterDB.hearthSpot,
    -- under the game's own name of the place), else the flight point of
    -- that name (most inns stand by one), else a capital's inn.
    function Way.MapName(mapID)
        if not (C_Map and type(C_Map.GetMapInfo) == "function") then return "" end
        local ok, info = pcall(C_Map.GetMapInfo, mapID)
        local name = ok and type(info) == "table" and info.name or nil
        if type(issecretvalue) == "function" and issecretvalue(name) then name = nil end
        return type(name) == "string" and name or ""
    end
    function Way.BindName()
        if type(GetBindLocation) ~= "function" then return nil end
        local ok, name = pcall(GetBindLocation)
        if not ok or (type(issecretvalue) == "function" and issecretvalue(name)) then return nil end
        return type(name) == "string" and name ~= "" and name or nil
    end
    function Way.Point(mapID, x, y)
        local w = SpotWorld({ mapID = mapID, x = x, y = y })
        if not w then return nil end
        return { w[1], w[2], w[3], region = Way.Region(w[3], mapID, w[1], w[2]), map = mapID }
    end
    -- Every flight point of the world (found or not), for their names.
    function Way.AllNodes()
        if Way.nodes then return Way.nodes end
        local list = {}
        if C_TaxiMap and type(C_TaxiMap.GetTaxiNodesForMap) == "function" and C_Map and type(C_Map.GetMapChildrenInfo) == "function" then
            local seen = {}
            for _, continentMap in ipairs(CONTINENT_MAPS) do
                local okZones, zones = pcall(C_Map.GetMapChildrenInfo, continentMap, 3, true)
                for _, zone in ipairs((okZones and type(zones) == "table") and zones or {}) do
                    local okNodes, nodes = pcall(C_TaxiMap.GetTaxiNodesForMap, zone.mapID)
                    for _, node in ipairs((okNodes and type(nodes) == "table") and nodes or {}) do
                        local id = type(node) == "table" and Number(node.nodeID)
                        if id and not seen[id] and type(node.position) == "table" and type(node.name) == "string" then
                            local nx, ny = node.position.x, node.position.y
                            if (nx == nil or ny == nil) and node.position.GetXY then nx, ny = node.position:GetXY() end
                            local point = Way.Point(zone.mapID, Number(nx), Number(ny))
                            if point then
                                seen[id] = true
                                point.name = PlaceName(node.name)
                                list[#list + 1] = point
                            end
                        end
                    end
                end
            end
        end
        if #list > 0 then Way.nodes = list end
        return list
    end
    -- The place a ride lands at, by the flight point there ("Rut'theran
    -- Village", "Menethil Harbor"), else the zone or city.
    function Way.PlaceAt(mapID, x, y)
        local point = Way.Point(mapID, x, y)
        local best, bestD
        if point then
            for _, node in ipairs(Way.AllNodes()) do
                if node[3] == point[3] then
                    local d = Yards(node[1], node[2], point[1], point[2])
                    if d <= Way.NAME_NEAR and (not bestD or d < bestD) then best, bestD = node, d end
                end
            end
        end
        if best and best.name ~= "" then return best.name end
        return Way.MapName(mapID)
    end
    function Way.CharDB()
        if type(ForeverDungeonJournalCharacterDB) ~= "table" then ForeverDungeonJournalCharacterDB = {} end
        return ForeverDungeonJournalCharacterDB
    end
    function Way.BindSpot()
        local name = Way.BindName()
        if not name then return nil end
        local saved = Way.CharDB().hearthSpot
        if type(saved) == "table" and saved.name == name and saved.mapID and saved.x and saved.y then
            local point = Way.Point(saved.mapID, saved.x, saved.y)
            if point then return name, point end
        end
        local lower = string.lower(name)
        for _, inn in ipairs(Way.INNS) do
            local match = string.lower(Way.MapName(inn[1])) == lower
            for i = 4, #inn do
                if string.lower(inn[i]) == lower then match = true end
            end
            if match then return name, Way.Point(inn[1], inn[2], inn[3]) end
        end
        for _, node in ipairs(Way.AllNodes()) do
            if string.lower(node.name) == lower then return name, node end
        end
        return nil
    end
    function Way.HearthReady()
        local count = (C_Item and C_Item.GetItemCount) or GetItemCount
        if type(count) ~= "function" then return false end
        local ok, n = pcall(count, Way.HEARTH_ITEM)
        n = ok and Number(n) or nil
        if not n or n < 1 then return false end
        local cooldown = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
        if type(cooldown) ~= "function" then return true end
        local okCD, start, duration, enable = pcall(cooldown, Way.HEARTH_ITEM)
        if not okCD then return true end
        start, duration = Number(start) or 0, Number(duration) or 0
        if enable == 0 or enable == false then return false end -- held back (in combat)
        if start == 0 or duration <= 1.5 then return true end -- 1.5: the global cooldown
        return start + duration - ((GetTime and GetTime()) or 0) <= 0
    end
    -- plan.hearth = the place's name when the hearthstone is ready and
    -- going from there is the quicker way by HEARTH_SAVES at least (looked
    -- at every 2 seconds).
    function Way.Hearth(entry, plan, p, t, cost)
        local now = (GetTime and GetTime()) or 0
        if entry.hearthAt and now - entry.hearthAt < 2 then
            plan.hearth = entry.hearth
            return
        end
        entry.hearthAt, entry.hearth = now, nil
        if not cost or cost < Way.HEARTH_SAVES + Way.HEARTH_CAST or not Way.HearthReady() then return end
        local name, spot = Way.BindSpot()
        if not spot then return end
        if spot[3] == p[3] and Yards(p[1], p[2], spot[1], spot[2]) < Way.HEARTH_NEAR then return end
        local _, from = Way.Search(spot, t)
        if from and Way.HEARTH_CAST + from + Way.HEARTH_SAVES <= cost then entry.hearth = name end
        plan.hearth = entry.hearth
    end
    do
        -- Where the hearthstone goes: the inn where it is set, and where it
        -- lands (any language: under the game's own name of the place).
        local pending
        local function Record()
            local name = Way.BindName()
            if not name or InInstance() or OnTaxi() then return end
            if not (C_Map and type(C_Map.GetBestMapForUnit) == "function" and type(C_Map.GetPlayerMapPosition) == "function") then return end
            local okMap, mapID = pcall(C_Map.GetBestMapForUnit, "player")
            mapID = okMap and Number(mapID) or nil
            if not mapID then return end
            local okPos, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
            if not okPos or type(pos) ~= "table" then return end
            local mx, my = pos.x, pos.y
            if (mx == nil or my == nil) and pos.GetXY then mx, my = pos:GetXY() end
            mx, my = Number(mx), Number(my)
            if not mx or not my then return end
            Way.CharDB().hearthSpot = { name = name, mapID = mapID, x = mx, y = my }
        end
        local watch = CreateFrame("Frame")
        for _, event in ipairs({ "HEARTHSTONE_BOUND", "UNIT_SPELLCAST_SUCCEEDED", "PLAYER_ENTERING_WORLD" }) do
            pcall(watch.RegisterEvent, watch, event)
        end
        watch:SetScript("OnEvent", function(_, event, unit, _, spellID)
            local now = (GetTime and GetTime()) or 0
            if event == "HEARTHSTONE_BOUND" then
                if C_Timer and C_Timer.After then C_Timer.After(0.5, Record) else Record() end
            elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
                if unit == "player" and spellID == Way.HEARTH_SPELL then
                    pending = now
                    if C_Timer and C_Timer.After then
                        C_Timer.After(2, function()
                            if pending then
                                pending = nil
                                Record()
                            end
                        end)
                    end
                end
            elseif event == "PLAYER_ENTERING_WORLD" and pending and now - pending < 60 then
                pending = nil
                Record()
            end
        end)
    end

    -- What to do next on the way to the spot: x, y where the arrow points;
    -- ride: the boat or zeppelin to take (aboard: at its dock or on it);
    -- fly: the flight point to fly to (atMaster: at the flight master);
    -- final: the arrow points at the spot itself. nil: no way known.
    -- way (1.9.2): by regions (Teldrassil's portals and pier), through any
    -- number of rides, and with the hearthstone when it is the quicker way.
    local function Plan(entry, px, py, here, target)
        local gx, gy = target[1], target[2]
        local playerMap, goalMap = PlayerMap(), target.map
        local hereR = Way.Region(here, playerMap, px, py)
        local goalR = Way.Region(target[3], goalMap, gx, gy)
        local plan = { here = hereR }
        if not target[3] or not here then
            plan.final, plan.x, plan.y = true, gx, gy
            return plan
        end
        local p = { px, py, here, region = hereR, map = playerMap }
        local t = { gx, gy, target[3], region = goalR, map = goalMap }
        -- On the boat or zeppelin taken, until well away from where it left.
        local ride = entry.ride
        if ride then
            local from = Ends(ride)
            if from and from.region == hereR and Yards(px, py, from[1], from[2]) <= OFF_DOCK then
                plan.ride, plan.aboard = ride, true
                return plan
            end
            entry.ride = nil
        end
        local cost = hereR == goalR and Way.Leg(p, t) or nil
        if hereR ~= goalR or not cost or cost > Way.RIDE_WORTH then
            ride, cost = Way.Search(p, t)
            if not cost then return nil end
        else
            ride = nil
        end
        local toR = goalR
        if ride then
            plan.ride = ride
            local from = Ends(ride)
            if ride.kind ~= "portal" and Yards(px, py, from[1], from[2]) <= DOCK then
                entry.ride = ride
                plan.aboard = true
                return plan
            end
            gx, gy = from[1], from[2]
            goalMap, toR = ride.from[1], from.region
        else
            plan.final = true
        end
        local a, b = Flight(here, px, py, gx, gy, entry.fly, playerMap, goalMap, hereR, toR)
        entry.fly = a and { a, b } or nil
        if a then
            plan.final, plan.fly = nil, b
            if Yards(px, py, a[1], a[2]) <= AT_MASTER then
                plan.atMaster = true
                return plan
            end
            gx, gy = a[1], a[2]
        end
        plan.x, plan.y = gx, gy
        Way.Hearth(entry, plan, p, t, cost)
        return plan
    end

    -- arrowvia: the way to a spot the straight line does not reach
    -- (FDJ.ARROW_VIAS[SpotKey]: a mountain in the way, a Horde post to go
    -- round): the arrow leads to each point of a route in turn, then to
    -- the spot. A spot has one route (a list of points) or several
    -- ({ routes = { list, list } }: from each place players come from); the
    -- route followed is the one whose next point is the quickest to reach
    -- (on foot or by flight), and it is only changed for one whose next
    -- point is much quicker (VIA_SWITCH). A point
    -- counts as passed within VIA_REACHED yards of it, and so does every
    -- point before it on its route (a player joining the route halfway).
    local VIA_REACHED = 30
    local VIA_LEG = 25      -- yards from the way between a point and the next: already past the point
    local VIA_AT_SPOT = 60  -- yards from the spot itself: no point on the way is left
    local VIA_SWITCH = 0.5
    local VIA_JUMP = 200    -- yards moved since the last look (a flight, a hearthstone): the route is chosen afresh
    local function ViaRoutes(entry)
        local vias = FDJ.ARROW_VIAS and entry.spot and FDJ.ARROW_VIAS[SpotKey(entry.spot)]
        if type(vias) ~= "table" then return nil end
        if type(vias.routes) == "table" then return vias.routes end
        return { vias }
    end
    -- Yards from (px, py) to the line between two points.
    local function LegYards(px, py, ax, ay, bx, by)
        local dx, dy = bx - ax, by - ay
        local len2 = dx * dx + dy * dy
        local t = 0
        if len2 > 0 then t = math.max(0, math.min(1, ((px - ax) * dx + (py - ay) * dy) / len2)) end
        return Yards(px, py, ax + t * dx, ay + t * dy)
    end
    -- climb (1.8.4): a point passed only once the player is up there (the
    -- fallen cart at Thoradin's Wall). The game gives no height, so a small
    -- grid of the place from walking maps (via.climb: rows of '#' only
    -- raised ground, '.' only plain ground, '+' both or beside it) says it
    -- by where the player stands: the cell under the player, or nil off the
    -- grid.
    local climbFrames = setmetatable({}, { __mode = "k" })
    local function ClimbCell(grid, px, py, here)
        if type(grid) ~= "table" or type(grid.rows) ~= "table" then return nil end
        local f = climbFrames[grid]
        if f == nil then
            local a = SpotWorld({ mapID = grid.mapID, x = grid.x0, y = grid.y0 })
            local b = SpotWorld({ mapID = grid.mapID, x = grid.x0 + grid.step, y = grid.y0 })
            local c = SpotWorld({ mapID = grid.mapID, x = grid.x0, y = grid.y0 + grid.step })
            f = false
            if a and b and c and a[3] == b[3] and a[3] == c[3] then
                local ux, uy, vx, vy = b[1] - a[1], b[2] - a[2], c[1] - a[1], c[2] - a[2]
                local det = ux * vy - uy * vx
                if det ~= 0 then f = { a[1], a[2], ux, uy, vx, vy, det, a[3] } end
            end
            climbFrames[grid] = f
        end
        if not f or f[8] ~= here then return nil end
        local dx, dy = px - f[1], py - f[2]
        local i = math.floor((dx * f[6] - dy * f[5]) / f[7] + 0.5) + 1
        local j = math.floor((f[3] * dy - f[4] * dx) / f[7] + 0.5) + 1
        local line = grid.rows[j]
        if type(line) ~= "string" or i < 1 or i > #line then return nil end
        return line:sub(i, i)
    end

    -- The route's next point for this player: its world position and the
    -- point; nil when the route is walked or not for this faction. A point
    -- is passed within VIA_REACHED yards of it, or VIA_LEG yards of the way
    -- from it to the route's next point. A climb point only within its
    -- reach (yards) or on its grid's raised ground; it is taken back on its
    -- grid's plain ground and after a jump (the spirit healer, a flight).
    local function RouteNext(route, done, px, py, here, faction, jumped)
        local worlds = {}
        for i, via in ipairs(route) do
            if type(via) == "table" and (not via.faction or via.faction == faction) then worlds[i] = SpotWorld(via) end
        end
        for i, via in ipairs(route) do
            if worlds[i] and via.climb and (jumped or ClimbCell(via.climb, px, py, here) == ".") then done[i] = nil end
        end
        local reached
        for i = #route, 1, -1 do
            local w, via = worlds[i], route[i]
            if w and w[3] == here then
                if via.climb then
                    if ClimbCell(via.climb, px, py, here) == "#"
                        or (tonumber(via.reach) and Yards(px, py, w[1], w[2]) <= tonumber(via.reach)) then
                        reached = i
                        break
                    end
                else
                    if Yards(px, py, w[1], w[2]) <= VIA_REACHED then reached = i break end
                    local n
                    for j = i + 1, #route do if worlds[j] then n = worlds[j] break end end
                    if n and n[3] == here and LegYards(px, py, w[1], w[2], n[1], n[2]) <= VIA_LEG then reached = i break end
                end
            end
        end
        if reached then
            for i = 1, reached do done[i] = true end
        end
        for i, via in ipairs(route) do
            if not done[i] and worlds[i] then return worlds[i], via end
        end
        return nil
    end
    local function NextVia(entry, px, py, here)
        local routes = ViaRoutes(entry)
        if not routes then return nil end
        local target = SpotWorld(entry.spot)
        local nearSpot = target and target[3] == here and Yards(px, py, target[1], target[2]) <= VIA_AT_SPOT
        local faction = Faction()
        entry.viaDone = entry.viaDone or {}
        local jumped = entry.viaX and Yards(px, py, entry.viaX, entry.viaY) > VIA_JUMP or false
        if jumped then entry.viaRoute = nil end
        -- A flight point newly found: the route is chosen afresh (flying
        -- there may now be the quicker way).
        if entry.viaLearned ~= flightsLearned then entry.viaRoute, entry.viaLearned = nil, flightsLearned end
        entry.viaX, entry.viaY = px, py
        local best, bestW, bestVia, bestD
        local playerMap = PlayerMap()
        for r, route in ipairs(routes) do
            if type(route) == "table" then
                if type(entry.viaDone[r]) ~= "table" then entry.viaDone[r] = {} end
                local w, via = RouteNext(route, entry.viaDone[r], px, py, here, faction, jumped)
                if not w and r == entry.viaRoute then return nil end -- the route followed is walked: the spot itself
                if w then
                    -- the way there on foot or by flight (Travel): from
                    -- Orgrimmar the Sun Rock Retreat route, by wind rider
                    local d = w[3] == here and Travel(here, px, py, w[1], w[2], playerMap, w.map) or Yards(px, py, w[1], w[2]) + FAR_ZONE * 10
                    if r == entry.viaRoute then d = d * VIA_SWITCH end -- the route being followed keeps the arrow
                    if not bestD or d < bestD then best, bestW, bestVia, bestD = r, w, via, d end
                end
            end
        end
        entry.viaRoute = best
        -- Near the spot: straight to it, unless a climb comes first (the
        -- Messenger Bag is up on the wall, over the heads of those below).
        if nearSpot and not (bestVia and bestVia.climb) then return nil end
        return bestW, bestVia
    end

    -- Distance (yards) and the turn from where the player faces to where the
    -- arrow points, and the plan (Plan above). nil: no position, or no way.
    local function Measure(entry)
        local target = SpotWorld(entry.spot)
        if not target then return nil end
        local px, py, here = PlayerWorld()
        if not px then return nil end
        local viaWorld, via = NextVia(entry, px, py, here) -- arrowvia
        if viaWorld then target = viaWorld end
        -- Worked out again every half second, or sooner after a jump (a
        -- hearthstone, a landing).
        local now = (GetTime and GetTime()) or 0
        local plan = entry.plan
        local moved = entry.plannedX and Yards(px, py, entry.plannedX, entry.plannedY) or math.huge
        local region = Way.Region(here, PlayerMap(), px, py) -- way
        if plan == nil or now - (entry.plannedAt or 0) >= PLAN_EVERY or moved > 25 or (plan and plan.here ~= region) then
            plan = Plan(entry, px, py, here, target) or false
            if plan and via then plan.via, plan.final = via, nil end -- arrowvia: not the spot itself yet
            entry.plan, entry.plannedAt, entry.plannedX, entry.plannedY = plan, now, px, py
        end
        if not plan then return nil end
        if plan.aboard or plan.atMaster then return nil, nil, plan end
        local distance = Yards(plan.x, plan.y, px, py)
        local turn
        if type(GetPlayerFacing) == "function" then
            local ok, facing = pcall(GetPlayerFacing)
            facing = ok and Number(facing) or nil
            if facing then turn = math.atan2(plan.y - py, plan.x - px) - facing end
        end
        return distance, turn, plan
    end

    local function FreeText(text)
        if type(text) ~= "string" then return nil end
        return FDJ.LocalizeFreeText and FDJ.LocalizeFreeText(text) or text
    end
    -- "Burned-Out Remains — Westfall" -> "Burned-Out Remains"
    local function SpotName(spot)
        local label = FreeText(spot.label) or ""
        return label:match("^(.-)%s+\226\128\148") or label
    end
    local function ZoneName(mapID)
        if not (C_Map and type(C_Map.GetMapInfo) == "function") then return "" end
        local ok, info = pcall(C_Map.GetMapInfo, mapID)
        local name = ok and type(info) == "table" and info.name or nil
        if type(issecretvalue) == "function" and issecretvalue(name) then name = nil end
        return type(name) == "string" and name or ""
    end
    local function QuestName(spot)
        local title = spot.questTitle
        if spot.markerType ~= "dungeon" and type(title) == "string" and title ~= "" then return title end
        return nil
    end
    -- What the NPC is called for /targetexact (nil: not an NPC).
    local function NPC(spot)
        if not spot or not IsTargetableNPCMarker(spot) then return nil end
        return QuestGiverName(spot)
    end
    -- How far below (-) or above (+) the ground around it the spot's NPC
    -- stands, in yards (nil: at ground level, or not known): FDJ.NPC_FLOORS
    -- (Data/QuestUpdates.lua), and all of Undercity, under the ruins.
    local FLOOR_MAPS = { [1458] = -100 }
    local function Floor(entry)
        if entry.floor ~= nil then return entry.floor or nil end
        local spot = entry.spot
        local found = FLOOR_MAPS[tonumber(spot.mapID) or 0] or false
        local here = SpotWorld(spot)
        if not found and here and type(FDJ.NPC_FLOORS) == "table" then
            local name, best = NPC(spot), nil
            for npc, list in pairs(FDJ.NPC_FLOORS) do
                for _, e in ipairs(list) do
                    if e[1] == here[3] then
                        local d = Yards(e[2], e[3], here[1], here[2])
                        if d <= (npc == name and 20 or 5) and (not best or d < best) then best, found = d, e[4] end
                    end
                end
            end
        end
        entry.floor = found
        return found or nil
    end

    -- The plan's next thing to do, in words ("" when it is just walking).
    local function Doing(plan)
        if not plan then return "" end
        if plan.fly then return FDJ.L("ARROW_FLY", plan.fly.name or "") end
        local ride = plan.ride
        if not ride then return plan.via and FreeText(plan.via.label) or "" end -- arrowvia: the point on the way
        -- way: the place it lands at ("Rut'theran Village", "Auberdine").
        if not ride.toName or ride.toName == "" then ride.toName = Way.PlaceAt(ride.to[1], ride.to[2], ride.to[3]) end
        if ride.kind == "portal" then return FDJ.L("ARROW_PORTAL", ride.toName) end
        return FDJ.L(ride.kind == "zeppelin" and "ARROW_ZEPPELIN" or "ARROW_BOAT", ride.toName)
    end

    local manual          -- the spot last shown on the map
    local follows = {}    -- [source] = the spot a tracked chain page is at
    local shown           -- what the arrow points at now
    local frame
    local Choose

    local function Reached(entry)
        if not entry then return end
        if entry.source == "manual" then
            if manual == entry then manual = nil end
        else
            Done()[entry.source] = entry.key
        end
        Choose()
    end

    -- Right-click: a chain followed since Show on Map (1.9.9, not tracked)
    -- stops, its spot shown on the map and all; else as when reached (a
    -- tracked chain's spot steps aside until its next step).
    local function Dismiss(entry)
        if not entry then return end
        local chain = entry.chain or (entry.source ~= "manual" and entry.source) or nil
        if chain and FDJ.StopChainArrow and FDJ.StopChainArrow(chain) then
            if manual and (manual == entry or manual.chain == chain) then manual = nil end
            follows[chain] = nil
            Choose()
            return
        end
        Reached(entry)
    end

    -- A click targets and marks the NPC (the map pins' own macro), set up
    -- out of combat only (the click does nothing in combat).
    local NOTHING = { markerType = "location" }
    local function ClickTargets(f, spot)
        if not f._fdjCanTarget then return end
        local name = NPC(spot)
        local key = name and (name .. "|" .. tostring(spot.raidMarkIndex)) or ""
        if key == f.fdjClickKey then return end
        if InCombatLockdown and InCombatLockdown() then return end
        ConfigureTargetAndMarkAction(f, name and spot or NOTHING, false)
        f.fdjClickKey = key
        f.fdjTargets = name ~= nil -- a left-click targets the NPC (and does not open the map)
    end

    local function Redraw(f)
        local entry = shown
        if not entry then
            f:Hide()
            return
        end
        local inside = InInstance()
        if not inside and OnTaxi() then
            -- In the air: how long the flight still takes (as long as it took
            -- last time; a guess the first time; else the time so far).
            ClickTargets(f, nil)
            f.arrow:Hide()
            if f.fdjHidden then
                f.fdjHidden = false
                f:SetAlpha(1)
                f:EnableMouse(true)
            end
            local now = (GetTime and GetTime()) or 0
            if not flight then Watch({ at = now }) end
            flight.up = flight.up or now
            local gone = now - flight.up
            local took = flight.from and flight.to and FlightTimes()[flight.from .. ">" .. flight.to]
            -- Past the count-down's end (a slower flight than thought):
            -- nothing, not 0:00 for the rest of the way.
            if type(took) == "number" then
                f.distance:SetText(took - gone >= 0 and Clock(took - gone) or "")
            elseif flight.guess then
                f.distance:SetText(flight.guess - gone >= 0 and ("~" .. Clock(flight.guess - gone)) or "")
            else
                f.distance:SetText(Clock(gone))
            end
            f.route:SetText(flight.to and FDJ.L("ARROW_FLYING", PlaceName(flight.to)) or "")
            f.hearth:SetText("")
            return
        end
        local distance, turn, plan
        if not inside then distance, turn, plan = Measure(entry) end
        local final = plan and plan.final
        -- An NPC under the ground (or up a tower): standing over them outside
        -- is not there yet.
        local floor = final and distance and distance <= FLOOR_NEAR and Floor(entry) or nil
        local below = floor ~= nil and floor < 0 and not Indoors()
        local above = floor ~= nil and floor > 0
        if distance and final and not below and distance <= ARRIVED and entry.source == "manual" then
            Reached(entry)
            return
        end
        -- A chain's spot steps out of the way while the player stands at it,
        -- and comes back if they walk off before the step moves on.
        local near = distance ~= nil and final and not below and (distance <= ARRIVED or (f.fdjNear and distance <= ARRIVED + 4)) or false
        f.fdjNear = near
        local hide = inside or near
        if hide ~= f.fdjHidden then
            f.fdjHidden = hide
            f:SetAlpha(hide and 0 or 1)
            f:EnableMouse(not hide)
        end
        ClickTargets(f, (not hide and final and distance and distance <= NEAR_NPC) and entry.spot or nil)
        if hide then return end
        local doing = Doing(plan)
        -- way: the hearthstone, when it is the quicker way: a line of its
        -- own under the next step (or in its place when there is none).
        local hearth = plan and plan.hearth and FDJ.L("ARROW_HEARTH", plan.hearth) or ""
        if plan and (plan.aboard or plan.atMaster) then
            f.distance:SetText(doing)
            f.route:SetText("")
            f.hearth:SetText("")
        elseif distance then
            f.distance:SetText(FDJ.L("ARROW_DISTANCE", math.floor(distance + 0.5)))
            local step = (below and FDJ.L("ARROW_BELOW")) or (above and FDJ.L("ARROW_ABOVE")) or doing
            if step == "" and hearth ~= "" then step, hearth = "|cff8fd0ff" .. hearth .. "|r", "" end
            f.route:SetText(step)
            f.hearth:SetText(hearth)
        else
            f.distance:SetText(entry.zone)
            f.route:SetText("")
            f.hearth:SetText("")
        end
        if turn then
            if f.arrow.SetRotation then f.arrow:SetRotation(turn) end
            f.arrow:Show()
        else
            f.arrow:Hide()
        end
    end

    -- A left-click on the arrow: its spot (the objective, not a point on
    -- the way) on the world map, as Show on Map does. The arrow keeps where
    -- it was on the way (the points passed).
    local function ShowOnMap(entry)
        local show = FDJ.MapMarkers and FDJ.MapMarkers.ShowRecordedLocationOnMap
        if not entry or type(entry.spot) ~= "table" or not show then return end
        local spot = {}
        for k, v in pairs(entry.spot) do spot[k] = v end
        FDJ.pendingMarkerQuestTitle = QuestName(entry.spot)
        FDJ.pendingMarkerTurnIn = entry.spot.turnIn and true or nil
        show(spot, spot.label)
        local now = shown
        if now and now ~= entry and SpotKey(now.spot) == SpotKey(entry.spot) then
            now.viaDone, now.viaRoute, now.viaX, now.viaY = entry.viaDone, entry.viaRoute, entry.viaX, entry.viaY
        end
    end

    local function Build()
        if frame then return frame end
        -- The insecure action template lets a click run the target-and-mark
        -- macro out of combat without making the arrow a protected frame.
        local ok, made = pcall(CreateFrame, "Button", "ForeverDungeonJournalArrow", UIParent, "InsecureActionButtonTemplate")
        local f = ok and made or CreateFrame("Button", "ForeverDungeonJournalArrow", UIParent)
        frame = f
        f._fdjCanTarget = (ok and made) and true or false
        if f._fdjCanTarget then f:SetAttribute("useOnKeyDown", false) end
        f:SetSize(150, 84)
        -- Only the arrow itself (52 x 52 at the top) takes the mouse: not the
        -- text under it nor the space round it.
        if f.SetHitRectInsets then f:SetHitRectInsets(49, 49, 0, 32) end
        f:SetFrameStrata("MEDIUM")
        f:SetClampedToScreen(true)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        local point = Saved().point
        if type(point) == "table" and type(point[1]) == "string" and tonumber(point[3]) and tonumber(point[4]) then
            f:SetPoint(point[1], UIParent, point[2] or point[1], tonumber(point[3]), tonumber(point[4]))
        else
            f:SetPoint("TOP", UIParent, "TOP", 0, -150)
        end
        f.arrow = f:CreateTexture(nil, "ARTWORK")
        f.arrow:SetSize(52, 52)
        f.arrow:SetPoint("TOP", f, "TOP", 0, 0)
        if f.arrow:SetTexture(ART) == false then f.arrow:SetTexture(FALLBACK_ART) end
        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.title:SetPoint("TOP", f.arrow, "BOTTOM", 0, -1)
        f.distance = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.distance:SetPoint("TOP", f.title, "BOTTOM", 0, -2)
        f.route = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.route:SetPoint("TOP", f.distance, "BOTTOM", 0, -2)
        -- way: "Hearth to Auberdine", in the hearthstone's blue.
        f.hearth = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.hearth:SetPoint("TOP", f.route, "BOTTOM", 0, -2)
        f.hearth:SetTextColor(0.56, 0.82, 1.00)
        f:SetScript("OnDragStart", function(self)
            self.fdjDragging = true
            self:StartMoving()
        end)
        f:SetScript("OnDragStop", function(self)
            self.fdjDragging = nil
            self.fdjDragEnd = (GetTime and GetTime()) or 0
            self:StopMovingOrSizing()
            local p, _, rp, x, y = self:GetPoint(1)
            if p then Saved().point = { p, rp, x, y } end
        end)
        -- PostClick keeps the template's own click (the target macro).
        f:SetScript(f._fdjCanTarget and "PostClick" or "OnClick", function(self, button)
            if button == "RightButton" then
                GameTooltip:Hide()
                Dismiss(shown)
            elseif button == "LeftButton" and not self.fdjTargets and not self.fdjDragging
                and ((GetTime and GetTime()) or 0) - (self.fdjDragEnd or -10) > 0.3 then
                GameTooltip:Hide()
                ShowOnMap(shown)
            end
        end)
        f:SetScript("OnEnter", function(self)
            local entry = shown
            if not entry then return end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(FreeText(entry.spot.label) or SpotName(entry.spot), 1, 0.82, 0.27)
            local quest = QuestName(entry.spot)
            if quest then GameTooltip:AddLine(quest, 1, 1, 1) end
            local detail = FreeText(entry.spot.detail)
            if detail and detail ~= "" then GameTooltip:AddLine(detail, 0.85, 0.85, 0.85, true) end
            if self.fdjTargets then
                GameTooltip:AddLine(FDJ.L("MAP_LEFT_TARGET"), 0.35, 1.00, 0.35)
            else
                GameTooltip:AddLine(FDJ.L("ARROW_TIP_MAP"), 0.55, 0.55, 0.55)
            end
            GameTooltip:AddLine(FDJ.L("ARROW_TIP_MOVE"), 0.55, 0.55, 0.55)
            GameTooltip:AddLine(FDJ.L("ARROW_TIP_HIDE"), 0.55, 0.55, 0.55)
            GameTooltip:Show()
        end)
        f:SetScript("OnLeave", function() GameTooltip:Hide() end)
        f:SetScript("OnUpdate", function(self, elapsed)
            self.fdjWait = (self.fdjWait or 0) - (elapsed or 0)
            if self.fdjWait > 0 then return end
            self.fdjWait = STEP
            Redraw(self)
        end)
        f:Hide()
        return f
    end

    -- The spot shown on the map first, else the one a tracked chain is at.
    Choose = function()
        local pick = manual
        if not pick then
            local done = Done()
            for source, entry in pairs(follows) do
                if done[source] ~= entry.key then pick = entry break end
            end
        end
        shown = pick
        if not pick then
            if frame then frame:Hide() end
            return
        end
        local f = Build()
        -- A quest's spot says whether it is picked up (!) or handed in (?)
        -- there: the same object can be both, in two places (the Burned-Out
        -- Remains). The arrow carries the quest's name; the spot's own name is
        -- in its tooltip.
        local quest = QuestName(pick.spot)
        local mark = ""
        if pick.spot.turnIn then
            mark = "|TInterface\\GossipFrame\\ActiveQuestIcon:0|t "
        elseif quest then
            mark = "|TInterface\\GossipFrame\\AvailableQuestIcon:0|t "
        end
        f.title:SetText(mark .. (quest or SpotName(pick.spot)))
        pick.zone = pick.zone or ZoneName(pick.spot.mapID)
        pick.plan, pick.plannedAt, pick.plannedX, pick.plannedY = nil, nil, nil, nil
        f.fdjWait, f.fdjNear = 0, nil
        f:Show()
        Redraw(f)
    end

    local function Copy(spot)
        local copy = {}
        for k, v in pairs(spot) do copy[k] = v end
        return copy
    end

    -- Show on Map and the rest (Systems/MapMarkers.lua above). Off for now
    -- (1.9.0) but for the Cozy Sleeping Bag: Show on Map on one of its spots
    -- (1.9.7, FDJ.IsSleepingBagSpot) and its tracked chain page
    -- (FDJ.FollowWaypoint). FDJ.ARROW_MANUAL = true turns it on everywhere.
    -- 1.9.9: after the spot shown, the arrow goes on with the chain (picked
    -- up, handed in, the next step...) as for a tracked chain, until it is
    -- right-clicked away (Systems/QuestText.lua: FDJ.FollowChainArrow).
    function FDJ.SetWaypointArrow(spot)
        local chain = FDJ.IsSleepingBagSpot and FDJ.IsSleepingBagSpot(spot) and FDJ.SLEEPING_BAG_PAGE or nil
        if not FDJ.ARROW_MANUAL and not chain then return end
        if type(spot) ~= "table" or not spot.mapID or not tonumber(spot.x) or not tonumber(spot.y) then return end
        if chain and FDJ.FollowChainArrow then
            Done()[chain] = nil
            FDJ.FollowChainArrow(chain)
        end
        manual = { spot = Copy(spot), source = "manual", key = SpotKey(spot), chain = chain }
        Choose()
    end
    -- Its map pin removed: the arrow goes too (a chain followed since Show
    -- on Map with it, unless tracked).
    function FDJ.ClearWaypointArrow(spot)
        if type(spot) ~= "table" or not manual or manual.key ~= SpotKey(spot) then return end
        local chain = manual.chain
        manual = nil
        if chain and FDJ.StopChainArrow and FDJ.StopChainArrow(chain) then follows[chain] = nil end
        Choose()
    end
    -- A followed chain page's next spot (nil: nothing more, or not followed).
    -- The chain moving on or ending takes its spot shown on the map along.
    function FDJ.FollowWaypoint(source, spot, questTitle, turnIn)
        if source == nil then return end
        if type(spot) ~= "table" or not spot.mapID then
            if follows[source] then
                follows[source] = nil
                if manual and manual.chain == source then manual = nil end
                Choose()
            end
            return
        end
        local key = SpotKey(spot) .. (turnIn and "|in" or "|up")
        local old = follows[source]
        if old and old.key == key then return end
        if old and manual and manual.chain == source then manual = nil end
        local copy = Copy(spot)
        copy.questTitle = questTitle
        copy.turnIn = turnIn and true or nil
        follows[source] = { spot = copy, source = source, key = key }
        Choose()
    end
    function FDJ.WaypointArrowTarget()
        return shown and shown.spot or nil, shown and shown.source or nil
    end
end
-- END arrow
