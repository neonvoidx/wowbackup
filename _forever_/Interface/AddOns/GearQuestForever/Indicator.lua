local _, GQ = ...

GQ.Indicator = GQ.Indicator or {}

local ARROW_TEXTURE = "Interface\\BUTTONS\\Arrow-Up-Up"
local ARROW_WIDTH = 16
local ARROW_HEIGHT = 21
local ARROW_OVERLAP = -2
local ARROW_COLOR = { 0.12, 1, 0.12 }
local ARROW_GLOW_COLOR = { 0.45, 1, 0.45 }
local ARROW_GLOW_SCALE = 1.24
local ARROW_LAYOUT_VERSION = 4
local PULSE_SPEED = 3.2
local PULSE_ALPHA_MIN = 0.82
local PULSE_ALPHA_MAX = 1.0
local PULSE_GLOW_MIN = 0.12
local PULSE_GLOW_MAX = 0.38

local function GetItemIdFromLink(link)
    if not link then
        return nil
    end
    return tonumber(link:match("item:(%d+)"))
end

local function ResolveLinkFromTooltip(setter)
    if not setter or not GameTooltip or not GameTooltip.GetItem then
        return nil
    end

    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    setter()
    if GameTooltip.Show then
        GameTooltip:Show()
    end
    local _, link = GameTooltip:GetItem()
    GameTooltip:Hide()
    return link
end

local TRAINER_SERVICE_TYPES = {
    header = true,
    available = true,
    unavailable = true,
    used = true,
}

local function GetTrainerServiceType(index)
    if not GetTrainerServiceInfo or not index or index <= 0 then
        return nil
    end

    local name, second, third = GetTrainerServiceInfo(index)
    if not name then
        return nil
    end

    if TRAINER_SERVICE_TYPES[second] then
        return second
    end

    if TRAINER_SERVICE_TYPES[third] then
        return third
    end

    return second
end

function GQ.Indicator:ResolveTradeSkillOutputLink(index)
    if not index or index <= 0 then
        return nil
    end

    if GetTradeSkillItemLink then
        local link = GetTradeSkillItemLink(index)
        if link then
            return link
        end
    end

    if GameTooltip and GameTooltip.SetTradeSkillItem then
        return ResolveLinkFromTooltip(function()
            GameTooltip:SetTradeSkillItem(index)
        end)
    end

    return nil
end

function GQ.Indicator:ResolveCraftOutputLink(index)
    if not index or index <= 0 then
        return nil
    end

    if GetCraftItemLink then
        local link = GetCraftItemLink(index)
        if link then
            return link
        end
    end

    if GameTooltip and GameTooltip.SetCraftItem then
        return ResolveLinkFromTooltip(function()
            GameTooltip:SetCraftItem(index)
        end)
    end

    return nil
end

local function IsExpandCollapseTexture(texture)
    if not texture or not texture.GetTexture then
        return false
    end

    local path = texture:GetTexture()
    if not path then
        return false
    end

    path = tostring(path)
    return path:find("PlusButton", 1, true) ~= nil
        or path:find("MinusButton", 1, true) ~= nil
        or path:find("UI-PlusMinus", 1, true) ~= nil
end

local function IsTrainerListRow(button)
    if not button or not button.GetName then
        return false
    end

    local name = button:GetName() or ""
    if name:find("ClassTrainerSkill", 1, true) and name ~= "ClassTrainerSkillIcon" then
        return true
    end

    if ClassTrainerFrame and ClassTrainerFrame.ScrollBox and button.GetParent then
        local parent = button:GetParent()
        if parent == ClassTrainerFrame.ScrollBox or (parent and parent.GetParent and parent:GetParent() == ClassTrainerFrame.ScrollBox) then
            return true
        end
    end

    return false
end

local function IsTradeSkillListRow(button)
    if not button or not button.GetName then
        return false
    end

    local name = button:GetName() or ""
    if name:match("^TradeSkillSkill%d+$") then
        return true
    end

    if TradeSkillFrame and TradeSkillFrame.RecipeList and button.GetParent then
        local parent = button:GetParent()
        if parent == TradeSkillFrame.RecipeList or (parent and parent.GetParent and parent:GetParent() == TradeSkillFrame.RecipeList) then
            return true
        end
    end

    if TradeSkillFrame and TradeSkillFrame.ScrollBox and button.GetParent then
        local parent = button:GetParent()
        if parent == TradeSkillFrame.ScrollBox or (parent and parent.GetParent and parent:GetParent() == TradeSkillFrame.ScrollBox) then
            return true
        end
    end

    return false
end

local function IsCraftListRow(button)
    if not button or not button.GetName then
        return false
    end

    local name = button:GetName() or ""
    return name:match("^Craft%d+$") ~= nil
end

local function IsProfessionListRow(button)
    return IsTrainerListRow(button) or IsTradeSkillListRow(button) or IsCraftListRow(button)
end

local function GetTrainerServiceName(index)
    if not GetTrainerServiceInfo or not index or index <= 0 then
        return nil
    end

    return select(1, GetTrainerServiceInfo(index))
end

local function IsTrainerDetailIconHost(button)
    if not button then
        return false
    end

    local name = button.GetName and button:GetName() or ""
    if name == "ClassTrainerSkillIcon" then
        return true
    end

    if ClassTrainerFrame and (button == ClassTrainerFrame.Icon or button == ClassTrainerFrame.skillIcon) then
        return true
    end

    local inset = ClassTrainerFrame and (ClassTrainerFrame.bottomInset or ClassTrainerFrame.BottomInset)
    if inset and button.GetParent then
        local parent = button:GetParent()
        if parent == inset and not IsTrainerListRow(button) then
            local width = button:GetWidth() or 0
            local height = button:GetHeight() or 0
            return width >= 28 and height >= 28 and width <= 80 and height <= 80
        end
    end

    return false
end

local function IsTradeSkillDetailIconHost(button)
    if not button then
        return false
    end

    local name = button.GetName and button:GetName() or ""
    if name == "TradeSkillSkillIcon" or name == "TradeSkillDetailIcon" or name == "TradeSkillDetailItemIcon" then
        return true
    end

    if TradeSkillFrame and (button == TradeSkillFrame.DetailIcon or button == TradeSkillFrame.SkillIcon) then
        return true
    end

    local detailFrame = TradeSkillFrame and (TradeSkillFrame.Details or TradeSkillFrame.detailsFrame or TradeSkillFrame.DetailsFrame)
    if detailFrame and button.GetParent then
        local parent = button:GetParent()
        if parent == detailFrame and not IsTradeSkillListRow(button) then
            local width = button:GetWidth() or 0
            local height = button:GetHeight() or 0
            return width >= 28 and height >= 28 and width <= 80 and height <= 80
        end
    end

    return false
end

local function IsCraftDetailIconHost(button)
    if not button then
        return false
    end

    local name = button.GetName and button:GetName() or ""
    if name == "CraftIcon" then
        return true
    end

    return CraftFrame and button == CraftFrame.DetailIcon
end

local function IsDetailIconHost(button)
    return IsTrainerDetailIconHost(button) or IsTradeSkillDetailIconHost(button) or IsCraftDetailIconHost(button)
end

local function IsUsableIconTexture(texture, hostButton)
    if not texture or not texture.GetObjectType or texture:GetObjectType() ~= "Texture" then
        return false
    end

    if IsExpandCollapseTexture(texture) then
        return false
    end

    local width = texture:GetWidth() or 0
    local height = texture:GetHeight() or 0
    if width >= 14 and height >= 14 then
        return true
    end

    local sizeHost = hostButton or (texture.GetParent and texture:GetParent())
    if sizeHost and IsDetailIconHost(sizeHost) and sizeHost.GetWidth and sizeHost.GetHeight then
        local hostWidth = sizeHost:GetWidth() or 0
        local hostHeight = sizeHost:GetHeight() or 0
        if hostWidth >= 28 and hostHeight >= 28 and hostWidth <= 80 and hostHeight <= 80 then
            return true
        end
    end

    return false
end

local function AcceptIconAnchor(texture, hostButton)
    if IsUsableIconTexture(texture, hostButton) then
        return texture
    end
    return nil
end

local function GetSelectedTrainerServiceIndex()
    if ClassTrainerFrame and ClassTrainerFrame.selectedService then
        return ClassTrainerFrame.selectedService
    end

    if GetTrainerSelectionIndex then
        return GetTrainerSelectionIndex()
    end
end

local function IsTrainerServiceHeader(serviceIndex)
    return GetTrainerServiceType(serviceIndex) == "header"
end

function GQ.Indicator:PrimeDataItemInfo()
    -- Only prime upgrade-tracked IDs; never walk all BiS rows (10k+).
    self.itemNameCache = self.itemNameCache or {}
    if not self.upgradeItems then
        return
    end

    for itemId in pairs(self.upgradeItems) do
        local name = GQ.Data and GQ.Data.GetItemDisplayName and GQ.Data:GetItemDisplayName(itemId)
        if name then
            self.itemNameCache[itemId] = name
        end
    end
end

function GQ.Indicator:PrimeUpgradeItemInfo()
    if not self.upgradeItems then
        return
    end

    for itemId in pairs(self.upgradeItems) do
        if GQ.Data and GQ.Data.RequestItemInfo then
            GQ.Data:RequestItemInfo(itemId)
        else
            GetItemInfo(itemId)
        end
    end
end

function GQ.Indicator:MatchTrainerServiceName(serviceName)
    if not serviceName then
        return nil
    end

    local trimmed = strtrim(serviceName)
    local keys = { trimmed:lower() }
    local stripped = trimmed:match("^[^:]+:%s*(.+)$")
    if stripped then
        keys[#keys + 1] = strtrim(stripped):lower()
    end

    for _, key in ipairs(keys) do
        if self.upgradeItemNames and self.upgradeItemNames[key] then
            return self.upgradeItemNames[key]
        end
    end

    self.itemNameCache = self.itemNameCache or {}

    for _, key in ipairs(keys) do
        for itemId, name in pairs(self.itemNameCache) do
            if self.upgradeItems[itemId] and name:lower() == key then
                return itemId
            end
        end
    end

    if self.upgradeItems then
        for itemId in pairs(self.upgradeItems) do
            local name = (GQ.Data and GQ.Data.GetItemDisplayName and GQ.Data:GetItemDisplayName(itemId))
                or self.itemNameCache[itemId]
            if name and not (GQ.Data and GQ.Data.IsPlaceholderItemName and GQ.Data:IsPlaceholderItemName(name, itemId)) then
                self.itemNameCache[itemId] = name
                local lowerName = name:lower()
                for _, key in ipairs(keys) do
                    if lowerName == key then
                        self.upgradeItemNames = self.upgradeItemNames or {}
                        self.upgradeItemNames[key] = itemId
                        return itemId
                    end
                end
            end
        end
    end

    return nil
end

function GQ.Indicator:ResolveTrainerServiceItemId(index)
    local link = self:ResolveTrainerServiceLink(index)
    return link and GetItemIdFromLink(link) or nil
end

function GQ.Indicator:ResolveTrainerServiceLink(index)
    return nil
end

function GQ.Indicator:UpdateTrainerDetailIcon()
end

function GQ.Indicator:FindTrainerDetailIconHost()
    if _G.ClassTrainerSkillIcon and _G.ClassTrainerSkillIcon:IsShown() then
        return _G.ClassTrainerSkillIcon
    end

    if not ClassTrainerFrame then
        return _G.ClassTrainerSkillIcon
    end

    local inset = ClassTrainerFrame.bottomInset or ClassTrainerFrame.BottomInset
    if inset then
        local bestHost
        local bestSize = 0

        local function ScanFrame(frame, depth)
            if not frame or depth > 8 then
                return
            end

            if frame.IsObjectType and (frame:IsObjectType("Button") or frame:IsObjectType("Frame")) then
                if IsTrainerDetailIconHost(frame) or (not IsTrainerListRow(frame) and self:GetIconAnchor(frame)) then
                    local width = frame:GetWidth() or 0
                    if width > bestSize then
                        bestHost = frame
                        bestSize = width
                    end
                end
            end

            if frame.GetChildren then
                local ok, children = pcall(frame.GetChildren, frame)
                if ok and children then
                    for _, child in ipairs(children) do
                        ScanFrame(child, depth + 1)
                    end
                end
            end
        end

        ScanFrame(inset, 0)
        if bestHost then
            return bestHost
        end
    end

    if _G.ClassTrainerSkillIcon then
        return _G.ClassTrainerSkillIcon
    end

    for _, key in ipairs({ "Icon", "skillIcon", "SkillIcon", "detailIcon" }) do
        if ClassTrainerFrame[key] then
            return ClassTrainerFrame[key]
        end
    end

    return nil
end

function GQ.Indicator:FindTradeSkillDetailIconHost()
    local candidates = {
        _G.TradeSkillSkillIcon,
        _G.TradeSkillDetailIcon,
        _G.TradeSkillDetailItemIcon,
        TradeSkillFrame and TradeSkillFrame.DetailIcon,
        TradeSkillFrame and TradeSkillFrame.SkillIcon,
    }

    for _, candidate in ipairs(candidates) do
        if candidate and candidate.IsShown and candidate:IsShown() then
            return candidate
        end
    end

    for _, candidate in ipairs(candidates) do
        if candidate then
            return candidate
        end
    end

    return nil
end

function GQ.Indicator:GetTradeSkillSelectionIndex()
    if TradeSkillFrame and TradeSkillFrame.selectedSkill then
        return TradeSkillFrame.selectedSkill
    end

    if GetTradeSkillSelectionIndex then
        return GetTradeSkillSelectionIndex()
    end
end

local function IsTradeSkillHeader(index)
    if not index or index <= 0 or not GetTradeSkillInfo then
        return true
    end

    local _, skillType = GetTradeSkillInfo(index)
    return skillType == "header"
end

function GQ.Indicator:UpdateTradeSkillDetailIcon()
    local detailIcon = self:FindTradeSkillDetailIconHost()
    if detailIcon then
        self:HideButton(detailIcon)
    end
end

function GQ.Indicator:HideProfessionListRows(getButton, count)
    count = count or 0
    for i = 1, count do
        local button = getButton(i)
        if button then
            self:HideButton(button)
        end
    end
end

function GQ.Indicator:UpdateClassTrainerFrame()
end

function GQ.Indicator:ScheduleTrainerRefresh()
end

function GQ.Indicator:StartTrainerDetailWatcher()
end

function GQ.Indicator:StopTrainerDetailWatcher()
    if self.trainerDetailWatcher then
        self.trainerDetailWatcher:SetScript("OnUpdate", nil)
        self.trainerDetailWatcher = nil
    end
end

function GQ.Indicator:EnsureTrainerListButtonHooks()
end

function GQ.Indicator:EnsureTrainerFrameHooks()
end

function GQ.Indicator:OnTrainerOpen()
end

function GQ.Indicator:GetIconAnchor(button)
    if not button then
        return nil
    end

    if IsProfessionListRow(button) then
        return nil
    end

    if button.IsObjectType and button:IsObjectType("Texture") then
        local parent = button.GetParent and button:GetParent()
        if IsUsableIconTexture(button, parent) then
            return button
        end
        return nil
    end

    if IsDetailIconHost(button) then
        if button.icon and not IsExpandCollapseTexture(button.icon) then
            return button.icon
        end
        if button.IconTexture and not IsExpandCollapseTexture(button.IconTexture) then
            return button.IconTexture
        end
        if button.GetNormalTexture then
            local normal = button:GetNormalTexture()
            if normal and not IsExpandCollapseTexture(normal) then
                return normal
            end
        end
        return button
    end

    if button.icon then
        local anchor = AcceptIconAnchor(button.icon, button)
        if anchor then
            return anchor
        end
    end

    if button.Icon then
        local anchor = AcceptIconAnchor(button.Icon, button)
        if anchor then
            return anchor
        end
        if button.Icon.icon then
            anchor = AcceptIconAnchor(button.Icon.icon, button.Icon)
            if anchor then
                return anchor
            end
        end
        if button.Icon.GetNormalTexture then
            local normal = button.Icon:GetNormalTexture()
            anchor = AcceptIconAnchor(normal, button.Icon)
            if anchor then
                return anchor
            end
        end
    end

    if button.IconTexture then
        local anchor = AcceptIconAnchor(button.IconTexture, button)
        if anchor then
            return anchor
        end
    end

    local name = button.GetName and button:GetName()
    if name then
        local named = _G[name .. "IconTexture"] or _G[name .. "Icon"]
        local anchor = AcceptIconAnchor(named, button)
        if anchor then
            return anchor
        end
        local iconButton = _G[name .. "Icon"]
        if iconButton and iconButton ~= button then
            local tex = iconButton.icon or iconButton.Icon
            if (not tex or not tex.GetObjectType or tex:GetObjectType() ~= "Texture") and iconButton.GetNormalTexture then
                tex = iconButton:GetNormalTexture()
            end
            anchor = AcceptIconAnchor(tex, iconButton)
            if anchor then
                return anchor
            end
        end
    end

    if button.IconFrame then
        local frameIcon = button.IconFrame.icon or button.IconFrame.Icon
        local anchor = AcceptIconAnchor(frameIcon, button)
        if anchor then
            return anchor
        end
    end

    if IsDetailIconHost(button) and button.GetNormalTexture then
        local normal = button:GetNormalTexture()
        local anchor = AcceptIconAnchor(normal, button)
        if anchor then
            return anchor
        end
    end

    return nil
end

function GQ.Indicator:EnsurePulseTicker()
    if self.pulseTicker then
        return
    end

    self.pulseOverlays = {}

    local ticker = CreateFrame("Frame")
    ticker:Hide()
    ticker:SetScript("OnUpdate", function()
        local tracker = GQ.Indicator
        local overlays = tracker.pulseOverlays
        if not overlays or not next(overlays) then
            ticker:Hide()
            return
        end

        local wave = 0.5 + 0.5 * math.sin(GetTime() * PULSE_SPEED)
        local arrowAlpha = PULSE_ALPHA_MIN + (PULSE_ALPHA_MAX - PULSE_ALPHA_MIN) * wave
        local glowAlpha = PULSE_GLOW_MIN + (PULSE_GLOW_MAX - PULSE_GLOW_MIN) * wave
        local glowScale = ARROW_GLOW_SCALE + (0.1 * wave)

        for overlay in pairs(overlays) do
            if overlay:IsShown() and overlay.gqArrow then
                overlay.gqArrow:SetAlpha(arrowAlpha)
                if overlay.gqGlow then
                    overlay.gqGlow:SetAlpha(glowAlpha)
                    overlay.gqGlow:SetSize(ARROW_WIDTH * glowScale, ARROW_HEIGHT * glowScale)
                end
            else
                overlays[overlay] = nil
            end
        end
    end)

    self.pulseTicker = ticker
end

function GQ.Indicator:RegisterOverlayPulse(overlay)
    if not overlay then
        return
    end

    self:EnsurePulseTicker()
    self.pulseOverlays[overlay] = true
    self.pulseTicker:Show()
end

function GQ.Indicator:UnregisterOverlayPulse(overlay)
    if not overlay then
        return
    end

    if self.pulseOverlays then
        self.pulseOverlays[overlay] = nil
    end

    if overlay.gqArrow then
        overlay.gqArrow:SetAlpha(1)
    end
    if overlay.gqGlow then
        overlay.gqGlow:SetAlpha(0)
    end
end

function GQ.Indicator:CreateOverlayTextures(overlay)
    local glow = overlay:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture(ARROW_TEXTURE)
    glow:SetTexCoord(0.08, 0.92, 0.02, 0.72)
    glow:SetVertexColor(ARROW_GLOW_COLOR[1], ARROW_GLOW_COLOR[2], ARROW_GLOW_COLOR[3])
    if glow.SetBlendMode then
        glow:SetBlendMode("ADD")
    end
    glow:SetAlpha(0)

    local arrow = overlay:CreateTexture(nil, "ARTWORK")
    arrow:SetTexture(ARROW_TEXTURE)
    arrow:SetTexCoord(0.08, 0.92, 0.02, 0.72)
    arrow:SetVertexColor(ARROW_COLOR[1], ARROW_COLOR[2], ARROW_COLOR[3])

    overlay.gqGlow = glow
    overlay.gqArrow = arrow
    overlay.gqArrowVersion = ARROW_LAYOUT_VERSION
end

function GQ.Indicator:ApplyOverlayLayout(overlay, anchor)
    local arrow = overlay.gqArrow
    local glow = overlay.gqGlow
    if not arrow then
        return
    end

    overlay:SetSize(ARROW_WIDTH, ARROW_HEIGHT)
    overlay:ClearAllPoints()
    if overlay.gqInset then
        -- Sit on the icon. A scroll frame clips anything drawn above the row.
        overlay:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 1, 1)
    else
        overlay:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, ARROW_OVERLAP)
    end

    arrow:ClearAllPoints()
    arrow:SetAllPoints(overlay)

    if glow then
        glow:ClearAllPoints()
        glow:SetPoint("CENTER", arrow, "CENTER", 0, 0)
        glow:SetSize(ARROW_WIDTH * ARROW_GLOW_SCALE, ARROW_HEIGHT * ARROW_GLOW_SCALE)
    end
end

local function AncestorClips(frame)
    local current = frame
    for _ = 1, 12 do
        if not current or not current.GetParent then
            break
        end
        local name = current.GetName and current:GetName() or ""
        if name:find("Scroll", 1, true) or current.ScrollBar or current.scrollBar then
            return true
        end
        current = current:GetParent()
    end
    return false
end

local function IsQuestSurface(frame)
    local current = frame
    for _ = 1, 16 do
        if not current then
            break
        end
        local name = current.GetName and current:GetName() or ""
        if name:find("Quest", 1, true) or name:find("WorldMap", 1, true) then
            return true
        end
        current = current.GetParent and current:GetParent()
    end
    return false
end

function GQ.Indicator:EnsureOverlay(button)
    if not button then
        return nil
    end

    local anchor = self:GetIconAnchor(button)
    if not anchor then
        self:HideButton(button)
        return nil
    end

    local parent = anchor.GetParent and anchor:GetParent() or button
    if not parent or (parent.IsObjectType and not parent:IsObjectType("Frame") and not parent:IsObjectType("Button")) then
        parent = button
    end

    local overlay = button.gqUpgradeOverlay
    if overlay and overlay.gqArrowVersion ~= ARROW_LAYOUT_VERSION then
        overlay:Hide()
        overlay:SetParent(nil)
        button.gqUpgradeOverlay = nil
        overlay = nil
    end

    if not overlay then
        overlay = CreateFrame("Frame", nil, parent)
        local frameLevel = parent.GetFrameLevel and parent:GetFrameLevel() or 1
        if ClassTrainerFrame and ClassTrainerFrame.GetFrameLevel then
            frameLevel = math.max(frameLevel, ClassTrainerFrame:GetFrameLevel() + 12)
        end
        if TradeSkillFrame and TradeSkillFrame.GetFrameLevel then
            frameLevel = math.max(frameLevel, TradeSkillFrame:GetFrameLevel() + 12)
        end
        overlay:SetFrameLevel(frameLevel + 10)
        if IsTrainerDetailIconHost(button) then
            overlay:SetFrameStrata("HIGH")
            overlay:SetFrameLevel(frameLevel + 25)
        elseif IsTradeSkillDetailIconHost(button) then
            overlay:SetFrameStrata("HIGH")
            overlay:SetFrameLevel(frameLevel + 25)
        end
        local buttonName = button.GetName and button:GetName()
        if IsQuestSurface(button) or (buttonName and (buttonName:find("QuestLog", 1, true) or buttonName:find("QuestInfo", 1, true) or buttonName:find("QuestReward", 1, true))) then
            overlay:SetFrameStrata("HIGH")
            overlay:SetFrameLevel(frameLevel + 20)
        end
        self:CreateOverlayTextures(overlay)
        button.gqUpgradeOverlay = overlay
        overlay.gqAnchor = anchor
    elseif overlay.gqAnchor ~= anchor then
        overlay.gqAnchor = anchor
    end

    if IsQuestSurface(button) then
        overlay:SetFrameStrata("HIGH")
    end
    local onQuestGiver = false
    if QuestFrame then
        local current = button
        for _ = 1, 16 do
            if not current then
                break
            end
            if current == QuestFrame then
                onQuestGiver = true
                break
            end
            current = current.GetParent and current:GetParent()
        end
    end
    overlay.gqInset = (not onQuestGiver) and (AncestorClips(button) or IsQuestSurface(button))
    self:ApplyOverlayLayout(overlay, anchor)
    overlay:Hide()
    return overlay
end

function GQ.Indicator:HideButton(button)
    if button and button.gqUpgradeOverlay then
        self:UnregisterOverlayPulse(button.gqUpgradeOverlay)
        button.gqUpgradeOverlay:Hide()
    end
end

function GQ.Indicator:UpgradeArrowsHidden()
    -- Simulation compares another class. An arrow there marks gear that is
    -- not ranked for the class being played, so none are painted.
    if GQ.IsPreviewEnabled and GQ:IsPreviewEnabled() then
        return true
    end
    local settings = GearQuestForeverDB and GearQuestForeverDB.settings
    return settings and settings.hideUpgradeArrows and true or false
end

function GQ.Indicator:ClearUpgradeArrowCache()
    if self._rebuildCacheTimer and self._rebuildCacheTimer.Cancel then
        self._rebuildCacheTimer:Cancel()
        self._rebuildCacheTimer = nil
    end
    self._rebuildGen = (self._rebuildGen or 0) + 1
    self._rebuildItems = nil
    self._rebuildNames = nil
    self.upgradeItems = {}
    self.upgradeItemNames = {}
end

function GQ.Indicator:ApplyArrowVisibility()
    if self:UpgradeArrowsHidden() and self.pulseOverlays then
        for overlay in pairs(self.pulseOverlays) do
            self:UnregisterOverlayPulse(overlay)
            overlay:Hide()
        end
    end
    if self.RefreshAll then
        self:RefreshAll()
    end
end

function GQ.Indicator:UpdateButton(button, link)
    if not button then
        return
    end

    if self:UpgradeArrowsHidden() then
        self:HideButton(button)
        return
    end

    -- No upgrade arrows on profession windows (craft / trade skill): avoids
    -- link resolution and full cache rebuilds while browsing recipes.
    if IsProfessionListRow(button) or IsTradeSkillDetailIconHost(button) or IsCraftDetailIconHost(button) then
        self:HideButton(button)
        return
    end

    local itemId = GetItemIdFromLink(link)
    local overlay = self:EnsureOverlay(button)
    if not overlay then
        return
    end

    local isUpgrade = itemId and self:IsUpgradeItem(itemId)
    local isObtained = itemId and GQ.Log and GQ.Log.IsItemIdObtained and GQ.Log:IsItemIdObtained(itemId)

    if isUpgrade and not isObtained then
        overlay:Show()
        self:RegisterOverlayPulse(overlay)
    else
        self:UnregisterOverlayPulse(overlay)
        overlay:Hide()
    end
end

local REBUILD_DEBOUNCE = 0.35

function GQ.Indicator:ScheduleRebuildCache()
    if self._rebuildDebounce then
        return
    end
    self._rebuildDebounce = true
    local function fire()
        self._rebuildDebounce = false
        if self.RebuildCacheAsync then
            self:RebuildCacheAsync(function()
                self:RefreshAll()
            end)
        else
            self:RebuildCache()
            self:RefreshAll()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(REBUILD_DEBOUNCE, fire)
    else
        fire()
    end
end

function GQ.Indicator:RebuildCache()
    if GQ.IsPreviewEnabled and GQ:IsPreviewEnabled() then
        self:ClearUpgradeArrowCache()
        return
    end
    self._rebuildGen = (self._rebuildGen or 0) + 1
    self._rebuildItems = nil
    self._rebuildNames = nil
    self.upgradeItems = {}
    self.upgradeItemNames = {}
    self.itemNameCache = self.itemNameCache or {}

    if not GQ.Data or not GQ.Data.GetSlotsForClass then
        return
    end

    local classFile = GQ:GetEffectiveClass()
    if not classFile then
        return
    end

    for _, slotName in ipairs(GQ.Data:GetSlotsForClass(classFile)) do
        self:RebuildCacheForSlot(slotName)
    end
end

function GQ.Indicator:RebuildCacheForSlot(slotName)
    local items = self._rebuildItems or self.upgradeItems
    local names = self._rebuildNames or self.upgradeItemNames
    if not items then
        self.upgradeItems = {}
        items = self.upgradeItems
    end
    if not names then
        self.upgradeItemNames = {}
        names = self.upgradeItemNames
    end
    self.itemNameCache = self.itemNameCache or {}

    local maxUpgrades = GQ.Data.GetMaxUpgradesForSlot and GQ.Data:GetMaxUpgradesForSlot(slotName) or 3

    local function mark(entry)
        local hide = GQ.Log and GQ.Log.ShouldHideFromActiveList
            and GQ.Log:ShouldHideFromActiveList(entry, slotName)
        if not entry or not entry.itemId or hide or items[entry.itemId] then
            return
        end
        if GQ.Log and GQ.Log.EntryIsListedUpgrade and not GQ.Log:EntryIsListedUpgrade(entry, slotName) then
            return
        end
        items[entry.itemId] = true
        local itemName = (GQ.Data.GetItemDisplayName and GQ.Data:GetItemDisplayName(entry.itemId))
            or self.itemNameCache[entry.itemId]
        if itemName and GQ.Data.IsPlaceholderItemName and GQ.Data:IsPlaceholderItemName(itemName, entry.itemId) then
            itemName = nil
        end
        if itemName then
            self.itemNameCache[entry.itemId] = itemName
            names[itemName:lower()] = entry.itemId
        elseif GQ.Data and GQ.Data.RequestItemInfo then
            GQ.Data:RequestItemInfo(entry.itemId)
        else
            GetItemInfo(entry.itemId)
        end
    end

    -- Unfiltered rank 1–3 keep the arrow when a filter or a play style
    -- hides them, and only when the piece is an upgrade. The rows still on
    -- the hunt list keep one too, including a later rank the slider showed,
    -- again only when it beats what is worn.
    -- Weapons stay on the weapon list. Armor and ranged fill from the rank
    -- list, so owning one rank still leaves an arrow on the piece that replaced it.
    local weaponSlot = slotName == "MainHand" or slotName == "SecondaryHand"
    if weaponSlot or not (GQ.Log and GQ.Log.RankedHuntEntries) then
        for _, entry in ipairs(GQ.Data:GetTopUpgradesForSlot(slotName, maxUpgrades, true)) do
            mark(entry)
        end
        if GQ.Log and GQ.Log.UsesWideHuntList and GQ.Log:UsesWideHuntList() and GQ.Log.GetActiveSlotListEntries then
            for _, entry in ipairs(GQ.Log:GetActiveSlotListEntries(slotName)) do
                mark(entry)
            end
        end
    else
        for _, entry in ipairs(GQ.Log:RankedHuntEntries(slotName, false)) do
            mark(entry)
        end
        if GQ.Log.GetActiveSlotListEntries then
            for _, entry in ipairs(GQ.Log:GetActiveSlotListEntries(slotName)) do
                mark(entry)
            end
        end
    end
end

local REBUILD_SLOTS_PER_FRAME = 2

function GQ.Indicator:RebuildCacheAsync(onComplete, slotsPerFrame)
    if GQ.IsPreviewEnabled and GQ:IsPreviewEnabled() then
        self:ClearUpgradeArrowCache()
        if onComplete then
            onComplete()
        end
        if self.RefreshAll then
            self:RefreshAll()
        end
        return
    end

    if not GQ.Data or not GQ.Data.GetSlotsForClass then
        if onComplete then
            onComplete()
        end
        return
    end

    local classFile = GQ:GetEffectiveClass()
    if not classFile then
        if onComplete then
            onComplete()
        end
        return
    end

    if self._rebuildCacheTimer and self._rebuildCacheTimer.Cancel then
        self._rebuildCacheTimer:Cancel()
        self._rebuildCacheTimer = nil
    end

    -- Build beside the arrows that are already showing, then swap. A zone
    -- change or a vendor must not blank the arrows for the whole rebuild.
    self._rebuildGen = (self._rebuildGen or 0) + 1
    local gen = self._rebuildGen
    self._rebuildItems = {}
    self._rebuildNames = {}
    self.itemNameCache = self.itemNameCache or {}

    local slots = GQ.Data:GetSlotsForClass(classFile)
    local index = 1
    local perFrame = tonumber(slotsPerFrame) or REBUILD_SLOTS_PER_FRAME
    if perFrame < 1 then
        perFrame = 1
    end

    local function step()
        if gen ~= self._rebuildGen then
            return
        end
        local last = math.min(index + perFrame - 1, #slots)
        for i = index, last do
            self:RebuildCacheForSlot(slots[i])
        end
        index = last + 1

        if index <= #slots then
            if C_Timer and C_Timer.After then
                self._rebuildCacheTimer = C_Timer.After(0, step)
            else
                step()
            end
            return
        end

        self._rebuildCacheTimer = nil
        local function done()
            if gen ~= self._rebuildGen then
                return
            end
            self.upgradeItems = self._rebuildItems or {}
            self.upgradeItemNames = self._rebuildNames or {}
            self._rebuildItems = nil
            self._rebuildNames = nil
            if onComplete then
                onComplete()
            end
            self:RefreshAll()
        end
        -- A ding already spent this frame on the last slot. Paint next frame.
        if perFrame < REBUILD_SLOTS_PER_FRAME and C_Timer and C_Timer.After then
            C_Timer.After(0, done)
        else
            done()
        end
    end

    if C_Timer and C_Timer.After then
        self._rebuildCacheTimer = C_Timer.After(0, step)
    else
        step()
    end
end

function GQ.Indicator:IsUpgradeItem(itemId)
    return itemId and self.upgradeItems and self.upgradeItems[itemId] == true
end

function GQ.Indicator:CollectItemButtons(root, results, depth, seen)
    if not root or depth > 8 then
        return
    end

    seen = seen or {}
    if seen[root] then
        return
    end
    seen[root] = true

    local typeOk, objectType = pcall(function()
        return root:GetObjectType()
    end)
    if not typeOk then
        return
    end

    if objectType == "Button" and self:GetIconAnchor(root) then
        table.insert(results, root)
    end

    if root.GetNumChildren then
        local ok, count = pcall(root.GetNumChildren, root)
        if ok and count then
            for i = 1, count do
                local okChild, child = pcall(root.GetChild, root, i)
                if okChild and child then
                    self:CollectItemButtons(child, results, depth + 1, seen)
                end
            end
        end
    end
end

local function FrameShown(frame)
    if not frame then
        return false
    end
    local ok, shown = pcall(function()
        return frame:IsShown()
    end)
    return ok and shown and true or false
end

function GQ.Indicator:AddShownRewardButton(results, seen, btn)
    if not btn or seen[btn] or not FrameShown(btn) then
        return
    end
    seen[btn] = true
    table.insert(results, btn)
end

function GQ.Indicator:QuestLogWindowShown()
    if FrameShown(QuestFrame) then
        return false
    end
    local map = _G.QuestMapFrame
    local details = map and (map.DetailsFrame or (map.QuestsFrame and map.QuestsFrame.DetailsFrame))
    if FrameShown(details) or FrameShown(_G.QuestLogPopupDetailFrame) or FrameShown(_G.QuestLogFrame) or FrameShown(_G.QuestLogDetailFrame) or FrameShown(_G.MapQuestInfoRewardsFrame) then
        return true
    end
    return FrameShown(_G.QuestInfoRewardsFrame)
end

function GQ.Indicator:QuestLogDetailShown()
    return self:QuestLogWindowShown()
end

function GQ.Indicator:AddQuestRewardRoots(frame, roots, seen, depth)
    if not frame or depth > 8 or seen[frame] then
        return
    end
    seen[frame] = true

    local ok, name = pcall(function()
        return frame.GetName and frame:GetName() or ""
    end)
    name = ok and name or ""
    local rewards = frame.RewardsFrame or frame.rewardsFrame
    if rewards then
        roots[rewards] = true
    end
    local rewardsContainer = frame.RewardsFrameContainer
    if rewardsContainer then
        roots[rewardsContainer] = true
        if rewardsContainer.RewardsFrame then
            roots[rewardsContainer.RewardsFrame] = true
        end
    end
    if frame.RewardButtons or frame.rewardButtons or frame.RewardFrames
        or name:find("Reward", 1, true) or name:find("QuestInfo", 1, true) then
        roots[frame] = true
    end

    local details = frame.DetailsFrame or frame.detailsFrame
    if details then
        self:AddQuestRewardRoots(details, roots, seen, depth + 1)
    end
    if frame.QuestsFrame then
        self:AddQuestRewardRoots(frame.QuestsFrame, roots, seen, depth + 1)
    end
    local scroll = frame.ScrollFrame or frame.scrollFrame
    if scroll then
        local child = scroll.Contents or scroll.ScrollChild or scroll.scrollChild
        if child then
            self:AddQuestRewardRoots(child, roots, seen, depth + 1)
        end
    end
end

function GQ.Indicator:GetQuestLogRewardButtons()
    local results = {}
    local seen = {}
    local roots = {}
    local function consider(frame)
        if frame then
            self:AddQuestRewardRoots(frame, roots, {}, 0)
        end
    end

    consider(_G.QuestLogFrame)
    consider(_G.QuestLogQuestDetail)
    consider(_G.QuestLogDetailScrollChildFrame)
    consider(_G.QuestLogDetailScrollFrameScrollChild)
    consider(QuestLogDetailScrollFrame and QuestLogDetailScrollFrame.ScrollChild)
    consider(_G.QuestLogPopupDetailFrame)
    consider(_G.QuestLogDetailFrame)
    consider(_G.QuestMapFrame)
    consider(_G.MapQuestInfoRewardsFrame)
    consider(_G.QuestInfoRewardsFrame)
    local mapDetails = _G.QuestMapFrame and _G.QuestMapFrame.DetailsFrame
    if mapDetails and mapDetails.RewardsFrameContainer then
        consider(mapDetails.RewardsFrameContainer.RewardsFrame or mapDetails.RewardsFrameContainer)
    end

    for root in pairs(roots) do
        if root.RewardButtons then
            for _, btn in ipairs(root.RewardButtons) do
                self:AddShownRewardButton(results, seen, btn)
            end
        end
        if root.RewardFrames then
            for _, frame in ipairs(root.RewardFrames) do
                self:AddShownRewardButton(results, seen, frame.Item or frame.item or frame)
            end
        end
        for i = 1, 12 do
            self:AddShownRewardButton(results, seen, root["Item" .. i])
            self:AddShownRewardButton(results, seen, root["QuestInfoItem" .. i])
        end
        self:CollectItemButtons(root, results, 0, seen)
    end

    for i = 1, 20 do
        self:AddShownRewardButton(results, seen, _G["QuestLogItem" .. i])
    end

    local shown = {}
    for _, btn in ipairs(results) do
        if not FrameShown(btn) then
            -- Hidden reward rows stay unpainted.
        else
            local nested = false
            local parent = btn.GetParent and btn:GetParent()
            while parent and not nested do
                for _, other in ipairs(results) do
                    if other == parent then
                        nested = true
                        break
                    end
                end
                parent = parent.GetParent and parent:GetParent()
            end
            if not nested then
                table.insert(shown, btn)
            end
        end
    end

    return shown
end

function GQ.Indicator:CollectQuestOfferButtons()
    local results = {}
    local seen = {}
    local function add(btn)
        if btn and not seen[btn] then
            seen[btn] = true
            table.insert(results, btn)
        end
    end

    local rewards = _G.QuestInfoRewardsFrame
        or (QuestInfoFrame and (QuestInfoFrame.rewardsFrame or QuestInfoFrame.RewardsFrame))
    if rewards then
        if rewards.RewardButtons then
            for _, btn in ipairs(rewards.RewardButtons) do
                add(btn)
            end
        end
        for i = 1, 12 do
            add(rewards["Item" .. i] or rewards["QuestInfoItem" .. i])
        end
    end

    for i = 1, 10 do
        add(_G["QuestInfoItem" .. i])
        add(_G["QuestRewardItem" .. i])
        add(_G["QuestProgressItem" .. i])
    end

    if #results == 0 and QuestFrame then
        self:CollectItemButtons(QuestFrame, results, 0, seen)
    end
    return results
end

function GQ.Indicator:UpdateQuestOfferRewards()
    if not QuestFrame or not QuestFrame:IsShown() then
        return
    end
    if not GetQuestItemLink then
        return
    end

    local buttons = self:CollectQuestOfferButtons()
    local buttonIndex = 1

    local function ApplyLinks(itemType, countFn)
        local count = countFn and countFn() or 0
        for i = 1, count do
            local link = GetQuestItemLink(itemType, i)
            local button = buttons[buttonIndex]
            if button and link then
                self:UpdateButton(button, link)
                buttonIndex = buttonIndex + 1
            elseif link then
                buttonIndex = buttonIndex + 1
            end
        end
    end

    ApplyLinks("choice", GetNumQuestChoices)
    ApplyLinks("reward", GetNumQuestRewards)

    for i = buttonIndex, #buttons do
        if buttons[i] then
            self:HideButton(buttons[i])
        end
    end
end

function GQ.Indicator:EnsureQuestLogHooks()
    -- Do not paint during the hook. Opening or closing the world map with a
    -- gamepad clears focus through SetPreferredGamepadInteractTarget, and
    -- addon work on that same call blocks jump and NPC talk until /reload.
    local function refresh()
        if not (C_Timer and C_Timer.After) then
            return
        end
        C_Timer.After(0, function()
            if GQ.Indicator then
                GQ.Indicator:UpdateQuestLogRewards()
            end
        end)
    end

    if not self._mapWatch then
        self._mapWatch = CreateFrame("Frame")
        local wasShown = false
        self._mapWatch:SetScript("OnUpdate", function()
            local shown = WorldMapFrame and WorldMapFrame:IsShown() and true or false
            if shown and not wasShown then
                refresh()
            end
            wasShown = shown
        end)
    end
end

function GQ.Indicator:MatchUpgradeName(text)
    if type(text) ~= "string" or text == "" or not self.upgradeItemNames then
        return nil
    end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
        return nil
    end
    local id = self.upgradeItemNames[text:lower()]
    if id then
        return id
    end
    local stripped = text:lower():gsub("%s*x%d+$", ""):gsub("^%d+%s*x%s*", "")
    return self.upgradeItemNames[stripped]
end

function GQ.Indicator:LinkFromHost(host)
    if not host then
        return nil
    end
    local itemId = host.itemID or host.itemId
    if type(itemId) == "number" and itemId > 0 then
        return "item:" .. itemId
    end
    if type(host.itemLink) == "string" then
        return host.itemLink
    end
    local itemType = host.type or host.rewardType
    local index = host.GetID and host:GetID() or 0
    if (itemType == "choice" or itemType == "reward") and index > 0 then
        local query = itemType == "choice" and GetQuestLogChoiceInfo or GetQuestLogRewardInfo
        if query then
            local queried, name, _, _, _, _, itemID = pcall(query, index)
            if queried and type(itemID) == "number" and itemID > 0 then
                return "item:" .. itemID
            end
            if queried then
                local namedId = self:MatchUpgradeName(name)
                if namedId then
                    return "item:" .. namedId
                end
            end
        end
        if GetQuestLogItemLink then
            local linked, link = pcall(GetQuestLogItemLink, itemType, index)
            if linked and type(link) == "string" then
                return link
            end
        end
    end
    local fields = { host.Name, host.name, host.Text, host.ItemName }
    local hostName = host.GetName and host:GetName()
    if hostName then
        table.insert(fields, _G[hostName .. "Name"])
    end
    for _, fs in ipairs(fields) do
        if fs and fs.GetText then
            local id = self:MatchUpgradeName(fs:GetText())
            if id then
                return "item:" .. id
            end
        end
    end
    if host.GetRegions then
        local ok, regions = pcall(function()
            return { host:GetRegions() }
        end)
        if ok and type(regions) == "table" then
            for _, region in ipairs(regions) do
                if region.GetObjectType and region:GetObjectType() == "FontString" and region.GetText then
                    local id = self:MatchUpgradeName(region:GetText())
                    if id then
                        return "item:" .. id
                    end
                end
            end
        end
    end
    return nil
end

function GQ.Indicator:LinkFromQuestButton(button)
    if not button then
        return nil
    end
    local current = button
    for _ = 1, 4 do
        local ok, link = pcall(self.LinkFromHost, self, current)
        if ok and type(link) == "string" then
            return link
        end
        local parentOk, parent = pcall(function()
            return current:GetParent()
        end)
        if not parentOk or not parent then
            break
        end
        current = parent
    end
    return nil
end

function GQ.Indicator:UpdateQuestLogRewards()
    self:EnsureQuestLogHooks()
    if not self:QuestLogDetailShown() then
        return
    end

    if not GetQuestLogItemLink and not self.upgradeItemNames then
        return
    end

    local buttons = self:GetQuestLogRewardButtons()
    for _, button in ipairs(buttons) do
        local ok, link = pcall(self.LinkFromQuestButton, self, button)
        if ok and link then
            pcall(self.UpdateButton, self, button, link)
        else
            pcall(self.HideButton, self, button)
        end
    end
end

function GQ.Indicator:UpdateLootFrame()
    if not LootFrame or not LootFrame:IsShown() or not GetLootSlotLink then
        return
    end

    local numLootItems = LootFrame.numLootItems or 0
    local numLootToShow = LOOTFRAME_NUMBUTTONS or 4
    if numLootItems > numLootToShow then
        numLootToShow = numLootToShow - 1
    end

    local page = LootFrame.page or 1
    for i = 1, LOOTFRAME_NUMBUTTONS or 4 do
        local button = _G["LootButton" .. i]
        if button then
            if button:IsShown() then
                local slot = ((page - 1) * numLootToShow) + i
                if slot <= numLootItems and GetLootSlotLink then
                    self:UpdateButton(button, GetLootSlotLink(slot))
                else
                    self:HideButton(button)
                end
            else
                self:HideButton(button)
            end
        end
    end
end

function GQ.Indicator:UpdateGroupLootFrames()
    local maxFrames = NUM_GROUP_LOOT_FRAMES or 4
    for i = 1, maxFrames do
        local frame = _G["GroupLootFrame" .. i]
        if frame and frame:IsShown() and frame.rollID and GetLootRollItemLink then
            self:UpdateButton(frame, GetLootRollItemLink(frame.rollID))
        elseif frame then
            self:HideButton(frame)
        end
    end
end

function GQ.Indicator:UpdateTradeSkillFrame()
    if not TradeSkillFrame or not TradeSkillFrame:IsShown() then
        return
    end

    local displayed = TRADE_SKILLS_DISPLAYED or 8
    self:HideProfessionListRows(function(i)
        return _G["TradeSkillSkill" .. i]
    end, displayed)

    if TradeSkillFrame.ScrollBox and TradeSkillFrame.ScrollBox.ForEachFrame then
        TradeSkillFrame.ScrollBox:ForEachFrame(function(button)
            GQ.Indicator:HideButton(button)
        end)
    end

    self:UpdateTradeSkillDetailIcon()
end

function GQ.Indicator:IsMerchantBuybackTab()
    if not MerchantFrame then
        return false
    end

    if MerchantFrame.selectedTab == 2 then
        return true
    end

    local tab = _G.MerchantFrameTab2
    if tab and tab.IsEnabled and tab:IsEnabled() and tab.GetButtonState then
        return tab:GetButtonState() == "PUSHED"
    end

    return false
end

function GQ.Indicator:GetMerchantSlotIndex(slotOnPage)
    local itemsPerPage = MERCHANT_ITEMS_PER_PAGE or 10
    local page = (MerchantFrame and MerchantFrame.page) or 1
    return ((page - 1) * itemsPerPage) + slotOnPage
end

function GQ.Indicator:ResolveMerchantLink(index, itemButton)
    if itemButton and itemButton.link then
        return itemButton.link
    end

    if index and index > 0 and GetMerchantItemLink then
        local link = GetMerchantItemLink(index)
        if link then
            return link
        end
    end

    if index and index > 0 and GameTooltip and GameTooltip.SetMerchantItem then
        GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        GameTooltip:SetMerchantItem(index)
        local _, link = GameTooltip:GetItem()
        GameTooltip:Hide()
        return link
    end

    return nil
end

function GQ.Indicator:UpdateMerchantFrame()
    if not MerchantFrame or not MerchantFrame:IsShown() then
        return
    end

    local itemsPerPage = MERCHANT_ITEMS_PER_PAGE or 10

    if self:IsMerchantBuybackTab() and GetBuybackItemLink then
        for i = 1, itemsPerPage do
            local itemButton = _G["MerchantItem" .. i .. "ItemButton"]
            if itemButton then
                if itemButton:IsShown() then
                    self:UpdateButton(itemButton, GetBuybackItemLink(i))
                else
                    self:HideButton(itemButton)
                end
            end
        end
        return
    end

    for i = 1, itemsPerPage do
        local itemButton = _G["MerchantItem" .. i .. "ItemButton"]
        if itemButton then
            if itemButton:IsShown() then
                local index = itemButton.GetID and itemButton:GetID()
                if not index or index <= 0 then
                    index = self:GetMerchantSlotIndex(i)
                end
                self:UpdateButton(itemButton, self:ResolveMerchantLink(index, itemButton))
            else
                self:HideButton(itemButton)
            end
        end
    end
end

function GQ.Indicator:UpdateCraftFrame()
    if not CraftFrame or not CraftFrame:IsShown() then
        return
    end

    local displayed = CRAFTS_DISPLAYED or 8
    self:HideProfessionListRows(function(i)
        return _G["Craft" .. i]
    end, displayed)

    local detailIcon = _G.CraftIcon or (CraftFrame and CraftFrame.DetailIcon)
    if detailIcon then
        self:HideButton(detailIcon)
    end
end

function GQ.Indicator:ScheduleProfessionRefresh()
    self:UpdateTradeSkillFrame()
    self:UpdateCraftFrame()
end

function GQ.Indicator:RefreshAll()
    self:UpdateLootFrame()
    self:UpdateGroupLootFrames()
    self:UpdateQuestLogRewards()
    self:UpdateQuestOfferRewards()
    self:UpdateTradeSkillFrame()
    self:UpdateCraftFrame()
    self:UpdateMerchantFrame()
end

-- Gamepad UI calls SetPreferredGamepadInteractTarget from the quest giver's
-- own update. Showing arrows inside that call taints it, and the action bar
-- then stays blocked until /reload. Paint on the next frame instead.
function GQ.Indicator:ScheduleRefreshAll()
    if self._refreshAllQueued then
        return
    end
    self._refreshAllQueued = true
    local function fire()
        self._refreshAllQueued = false
        if GQ.Indicator then
            GQ.Indicator:RefreshAll()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, fire)
    else
        fire()
    end
end

function GQ.Indicator:EnsureTrainerHooks()
end

function GQ.Indicator:EnsureMerchantHooks()
    if self.merchantHooksReady then
        return
    end

    if type(MerchantFrame_Update) ~= "function" then
        return
    end

    self.merchantHooksReady = true

    self:HookFunction("MerchantFrame_Update", function()
        GQ.Indicator:UpdateMerchantFrame()
    end)

    if type(MerchantFrame_UpdateMerchantInfo) == "function" then
        self:HookFunction("MerchantFrame_UpdateMerchantInfo", function()
            GQ.Indicator:UpdateMerchantFrame()
        end)
    end
end

function GQ.Indicator:HookFunction(name, handler)
    if type(_G[name]) == "function" and not self.hooks[name] then
        self.hooks[name] = true
        hooksecurefunc(name, handler)
    end
end

function GQ.Indicator:Init()
    self.hooks = {}
    self.itemNameCache = {}

    self:RebuildCacheAsync(function()
        self:PrimeUpgradeItemInfo()
    end)

    self:HookFunction("LootFrame_Update", function()
        self:UpdateLootFrame()
    end)

    self:HookFunction("GroupLootFrame_OpenNewFrame", function()
        self:UpdateGroupLootFrames()
    end)

    self:HookFunction("QuestLog_UpdateQuestDetails", function()
        self:UpdateQuestLogRewards()
    end)

    self:HookFunction("QuestLog_Update", function()
        self:UpdateQuestLogRewards()
    end)

    self:HookFunction("QuestInfo_ShowRewards", function()
        self:UpdateQuestOfferRewards()
        self:UpdateQuestLogRewards()
    end)

    self:HookFunction("QuestFrameItems_Update", function()
        self:UpdateQuestOfferRewards()
    end)

    self:HookFunction("QuestFrame_UpdatePortrait", function()
        self:UpdateQuestOfferRewards()
    end)

    self:HookFunction("TradeSkillFrame_Update", function()
        self:UpdateTradeSkillFrame()
    end)

    self:HookFunction("CraftFrame_Update", function()
        self:UpdateCraftFrame()
    end)

    self:HookFunction("TradeSkillFrame_SetSelection", function()
        self:ScheduleProfessionRefresh()
    end)

    self:HookFunction("CraftFrame_SetSelection", function()
        self:ScheduleProfessionRefresh()
    end)

    self:EnsureMerchantHooks()

    local eventFrame = CreateFrame("Frame")
    local events = {
        "ADDON_LOADED",
        "START_LOOT_ROLL",
        "LOOT_OPENED",
        "LOOT_CLOSED",
        "MERCHANT_SHOW",
        "MERCHANT_UPDATE",
        "TRADE_SKILL_SHOW",
        "TRADE_SKILL_UPDATE",
        "TRADE_SKILL_LIST_UPDATE",
        "TRADE_SKILL_DATA_SOURCE_CHANGED",
        "TRADE_SKILL_DETAILS_UPDATE",
        "CRAFT_SHOW",
        "CRAFT_UPDATE",
        "GET_ITEM_INFO_RECEIVED",
        "PLAYER_ENTERING_WORLD",
        "QUEST_DETAIL",
        "QUEST_PROGRESS",
        "QUEST_COMPLETE",
        "QUEST_FINISHED",
        "QUEST_LOG_UPDATE",
    }
    for i = 1, #events do
        GQ.RegisterEvent(eventFrame, events[i])
    end
    eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
        if event == "ADDON_LOADED" and (arg1 == "Blizzard_WorldMap" or arg1 == "Blizzard_QuestLog") then
            GQ.Indicator:EnsureQuestLogHooks()
            return
        end

        if event == "ADDON_LOADED" and arg1 == "Blizzard_TradeSkillUI" then
            GQ.Indicator:HookFunction("TradeSkillFrame_Update", function()
                GQ.Indicator:UpdateTradeSkillFrame()
            end)
            GQ.Indicator:HookFunction("TradeSkillFrame_SetSelection", function()
                GQ.Indicator:ScheduleProfessionRefresh()
            end)
            return
        end

        if event == "MERCHANT_SHOW" then
            GQ.Indicator:EnsureMerchantHooks()
            GQ.Indicator:RebuildCacheAsync()
        end

        if event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE"
            or event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_DATA_SOURCE_CHANGED"
            or event == "TRADE_SKILL_DETAILS_UPDATE"
            or event == "CRAFT_SHOW" or event == "CRAFT_UPDATE"
        then
            if event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW" then
                if GQ.Log and GQ.Log.ReleaseMouseForGameUI then
                    GQ.Log:ReleaseMouseForGameUI()
                end
                if GQ.Popup and GQ.Popup.Hide and (not CharacterFrame or not CharacterFrame:IsShown()) then
                    GQ.Popup:Hide()
                end
                if GQ.Tracker and GQ.Tracker.ClampRowMouse then
                    GQ.Tracker:ClampRowMouse()
                end
            end
            GQ.Indicator:ScheduleProfessionRefresh()
            return
        end

        if event == "PLAYER_ENTERING_WORLD" then
            GQ.Indicator:RebuildCacheAsync(function()
                GQ.Indicator:PrimeDataItemInfo()
                GQ.Indicator:PrimeUpgradeItemInfo()
            end)
            return
        end

        if event == "GET_ITEM_INFO_RECEIVED" then
            local itemId = arg1
            if itemId then
                GQ.Indicator.itemNameCache = GQ.Indicator.itemNameCache or {}
                local name = GQ.Data and GQ.Data.GetItemDisplayName and GQ.Data:GetItemDisplayName(itemId)
                if name then
                    GQ.Indicator.itemNameCache[itemId] = name
                end
            end
            return
        end

        GQ.Indicator:RefreshAll()

        if event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" then
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    if GQ.Indicator then
                        GQ.Indicator:UpdateQuestOfferRewards()
                    end
                end)
            end
        end

        if event == "QUEST_LOG_UPDATE" and C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if GQ.Indicator then
                    GQ.Indicator:UpdateQuestLogRewards()
                end
            end)
            C_Timer.After(0.2, function()
                if GQ.Indicator then
                    GQ.Indicator:UpdateQuestLogRewards()
                end
            end)
        end

        if (event == "MERCHANT_SHOW" or event == "MERCHANT_UPDATE") and C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if GQ.Indicator then
                    GQ.Indicator:UpdateMerchantFrame()
                end
            end)
        end
    end)
end
