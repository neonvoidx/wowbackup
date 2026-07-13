-- Overachiever2: Tooltips
-- Modern tooltip enhancement using TooltipDataProcessor

local _, ns = ...

local Utils = Overachiever2.Utils

local COLOR_COMPLETE = CreateColorFromHexString(Utils.BlizzardGreenColor)
local COLOR_INCOMPLETE = CreateColorFromHexString(Utils.BlizzardRedColor)
local COLOR_GRAY = CreateColorFromHexString(Utils.GrayColor)
local COLOR_ID = CreateColorFromHexString(Utils.WhiteColor)

-- Private tooltip frame for addon-owned achievement tooltips.
-- The frame itself is created in Utils.lua so Core.lua and History.lua can share it.
-- Using a private frame (instead of GameTooltip) avoids tainting GameTooltip's widget
-- layout state, which causes "attempt to compare a secret number value" errors
-- (WoWUIBugs #811). https://github.com/Stanzilla/WoWUIBugs/issues/811
local OA2Tooltip = Utils.OA2Tooltip

-- Persistent tooltip for clicking achievement links in chat.
-- Stays visible until the user clicks the X close button.
local OA2ClickTooltip = CreateFrame("GameTooltip", "Overachiever2ClickTooltip", UIParent, "GameTooltipTemplate")
OA2ClickTooltip:SetFrameStrata("TOOLTIP")
OA2ClickTooltip:SetClampedToScreen(true)
OA2ClickTooltip:EnableMouse(true)
OA2ClickTooltip:SetMovable(true)
OA2ClickTooltip:RegisterForDrag("LeftButton")
OA2ClickTooltip:SetScript("OnDragStart", OA2ClickTooltip.StartMoving)
OA2ClickTooltip:SetScript("OnDragStop", OA2ClickTooltip.StopMovingOrSizing)

-- Close button (X) at top-right corner
local closeBtn = CreateFrame("Button", nil, OA2ClickTooltip, "UIPanelCloseButtonNoScripts")
closeBtn:SetSize(24, 24)
closeBtn:SetPoint("TOPRIGHT", OA2ClickTooltip, "TOPRIGHT", 4, 4)
closeBtn:SetFrameLevel(OA2ClickTooltip:GetFrameLevel() + 10)
closeBtn:SetScript("OnClick", function()
    OA2ClickTooltip:Hide()
end)

-- Sidecar tooltip for unit/item enrichment.
-- Any write from addon code to the global GameTooltip (even after the existing
-- CanModifyTooltip guard) can taint its persistent widgetContainer, because
-- Blizzard attaches widget sets AFTER ProcessTooltipPostCalls runs — leaving
-- our addon writes on the same call stack that later registers the widget set.
-- The taint manifests as "attempt to compare a secret number value" in
-- LayoutFrame.lua:491 when a later widget-set tooltip (AreaPOI, world quest)
-- is hidden. Render enrichment into OA2Tooltip anchored beside GameTooltip
-- so the global tooltip is never touched.
-- https://github.com/Stanzilla/WoWUIBugs/issues/811
local function ShowSidecar(sourceTooltip, populateFn)
    OA2Tooltip:SetOwner(sourceTooltip, "ANCHOR_NONE")
    OA2Tooltip:ClearAllPoints()
    OA2Tooltip:ClearLines()
    -- Reset alpha in case the previous hide came from a fade animation,
    -- which leaves alpha at 0 even after Hide().
    OA2Tooltip:SetAlpha(1)
    populateFn(OA2Tooltip)

    -- Anchor to the right by default, then Show() so the tooltip lays out and we
    -- can measure its width. This all runs inside a TooltipPostCall (before the
    -- frame is drawn), so re-anchoring below produces no visible flicker.
    OA2Tooltip:SetPoint("TOPLEFT", sourceTooltip, "TOPRIGHT", 0, 0)
    OA2Tooltip:Show()

    -- Flip to the left of the source tooltip when the right side would run off
    -- the screen and the left side has more room. Normalize to physical pixels
    -- because the source tooltip and the sidecar may run at different scales.
    -- In WoW 12.0's secret-value system the region rect getters (GetRight/GetLeft/
    -- GetWidth/...) return *secret* numbers when the frame has "secret anchoring
    -- information" — true for the bag-item GameTooltip when queried from this
    -- tainted post-call, and inherited by OA2Tooltip because it's anchored to it.
    -- Arithmetic on a secret value throws, so only run the flip when the
    -- measurements are real; otherwise keep the default right-side anchor above.
    local srcRight, srcLeft = sourceTooltip:GetRight(), sourceTooltip:GetLeft()
    local width = OA2Tooltip:GetWidth()
    if srcRight and srcLeft and width
       and not issecretvalue(srcRight)
       and not issecretvalue(srcLeft)
       and not issecretvalue(width) then
        local srcScale = sourceTooltip:GetEffectiveScale()
        local rightPx  = srcRight * srcScale
        local leftPx   = srcLeft * srcScale
        local widthPx  = width * OA2Tooltip:GetEffectiveScale()
        local screenPx = GetScreenWidth() * UIParent:GetEffectiveScale()

        local fitsRight = rightPx + widthPx <= screenPx
        local roomLeft, roomRight = leftPx, screenPx - rightPx
        if not fitsRight and roomLeft > roomRight then
            OA2Tooltip:ClearAllPoints()
            OA2Tooltip:SetPoint("TOPRIGHT", sourceTooltip, "TOPLEFT", 0, 0)
        end
    end
end

local function HideSidecar(sourceTooltip)
    if OA2Tooltip:IsShown() and OA2Tooltip:GetOwner() == sourceTooltip then
        OA2Tooltip:Hide()
    end
end

-- Mirror GameTooltip's visibility so the sidecar doesn't linger after the
-- underlying unit/item tooltip closes. HookScript is taint-safe.
GameTooltip:HookScript("OnHide", function()
    HideSidecar(GameTooltip)
end)

-- Mirror GameTooltip's fade-out so the sidecar fades alongside it instead of
-- snapping off when GameTooltip's fade finishes (OnHide fires post-fade).
-- hooksecurefunc is taint-safe; OA2Tooltip inherits :FadeOut from GameTooltipTemplate.
hooksecurefunc(GameTooltip, "FadeOut", function()
    if OA2Tooltip:IsShown() and OA2Tooltip:GetOwner() == GameTooltip then
        OA2Tooltip:FadeOut()
    end
end)

-- Guard for TooltipDataProcessor callbacks that modify shared Blizzard tooltips (e.g., GameTooltip).
-- Addon code calling AddLine/AddDoubleLine on a tooltip taints its layout state. If the tooltip
-- also carries a widget set (common on AreaPOI map tooltips), Blizzard's secure widget cleanup
-- will later choke on the tainted values (LayoutFrame.lua "secret number" error).
-- https://github.com/Stanzilla/WoWUIBugs/issues/811
-- Centralizing these checks here so new tooltip hooks get the same protection automatically.
local function CanModifyTooltip(tooltip)
    -- Blizzard attaches widget sets via GameTooltip_AddWidgetSet, which stores the ID on
    -- tooltip.widgetContainer.widgetSetID (NOT on the tooltip itself — the old check here
    -- never fired). The widget set is also attached AFTER ProcessTooltipPostCalls runs,
    -- so even the corrected field can still be nil when our callback fires.
    if tooltip.widgetContainer and tooltip.widgetContainer.widgetSetID then return false end

    -- Fallback: tooltips owned by a frame under WorldMapFrame or Minimap commonly get
    -- widget sets attached after our callback (AreaPOI pins, vignettes, world quests).
    -- Touching the shared GameTooltip in those contexts taints its persistent
    -- widgetContainer child and triggers "secret number" errors on hide.
    local owner = tooltip:GetOwner()
    while owner and owner ~= UIParent do
        if owner == WorldMapFrame or owner == Minimap then return false end
        local ok, parent = pcall(owner.GetParent, owner)
        if not ok or not parent then break end
        owner = parent
    end

    return true
end

-- Helper: Add a line with the achievement icon and its criteria
local function AppendAchievementLine(tooltip, match)
    local achName = match.achName
    local achStatusStr = match.achCompleted and Utils.CheckAtlasText() or Utils.RedxAtlasText()
    if Utils.IsDebugMode() then
        achName = achName .. " [achID: " .. match.achID .. "]"
    end
    tooltip:AddDoubleLine(Utils.AchievementIconText() .. " " .. Utils.BlizzardGoldText(achName), achStatusStr)

    -- Display each criteria entry under this achievement
    for _, crit in ipairs(match.criteria) do
        local critName = nil
        if crit.criteriaString and crit.criteriaString ~= "" then
            critName = crit.criteriaString
        end
        if critName then
            critName = crit.criteriaCompleted and Utils.WhiteText(critName) or Utils.GrayText(critName)
            critName = Utils.AchievementIconSpacerText() .. " " .. Utils.GrayText(Utils.DotIconText()) .. " " .. critName
            local critStatusStr = crit.criteriaCompleted and Utils.CheckAtlasText() or Utils.RedxAtlasText()
            if Utils.IsDebugMode() then
                critName = critName .. " [critID: " .. crit.criteriaID .. "]"
            end
            tooltip:AddDoubleLine(critName, critStatusStr)
        end
    end
end

-- Helper: Add all criteria lines for an achievement
local function AddCriteriaLines(tooltip, achID)
    local numCriteria = ns.GetAchievementNumCriteria(achID)
    if numCriteria == 0 then return end

    tooltip:AddLine(" ") -- Spacing

    local isSingleCriteria = numCriteria == 1
    local criteriaInfo = {} -- contains formatted lines to be added to tooltip
    local progressBarInfo = { enable = false, max = 0, value = 0, text = "" }
    local debugCriteriaInfo = {} -- contains all values of GetAchievementCriteriaInfo call

    for i = 1, numCriteria do
        local criteriaString, criteriaType, completed, quantity, reqQuantity, charName, flags, assetID, quantityString = ns.GetAchievementCriteriaInfo(achID, i)

        -- If it's a single criteria achievement with a required quantity > 1, we should display a progress bar.
        -- E.g., "2500 World Quests Completed".
        if isSingleCriteria and reqQuantity > 1 then
            progressBarInfo.enable = true
            progressBarInfo.max = reqQuantity
            progressBarInfo.value = quantity
            progressBarInfo.text = quantityString
        end

        if criteriaString and (criteriaString ~= "") then
            local color = completed and COLOR_COMPLETE or COLOR_INCOMPLETE
            local text = criteriaString
            local statusIcon = completed and (" " .. Utils.CheckAtlasText()) or (" " .. Utils.RedxAtlasText())
            table.insert(criteriaInfo, { text = text .. statusIcon, color = color })
        end

        if Utils.IsDebugMode() then
            local debugLine = string.format("[%d]: 1=%s, 2=%s, 3=%s, 4=%s, 5=%s, 6=%s, 7=%s, 8=%s, 9=%s",
                i,
                Utils.ColorByType(criteriaString),
                Utils.ColorByType(criteriaType),
                Utils.ColorByType(completed),
                Utils.ColorByType(quantity),
                Utils.ColorByType(reqQuantity),
                Utils.ColorByType(charName),
                Utils.ColorByType(flags),
                Utils.ColorByType(assetID),
                Utils.ColorByType(quantityString)
            )
            table.insert(debugCriteriaInfo, debugLine)
        end
    end

    -- Display criteria in two columns
    for i = 1, #criteriaInfo, 2 do
        local left = criteriaInfo[i]
        local right = criteriaInfo[i+1]
        local lr, lg, lb = left.color:GetRGB()
        if right then
            local rr, rg, rb = right.color:GetRGB()
            tooltip:AddDoubleLine(left.text, right.text, lr, lg, lb, rr, rg, rb)
        else
            tooltip:AddLine(left.text, lr, lg, lb)
        end
    end

    -- Add progress bar
    if progressBarInfo.enable then
        GameTooltip_ShowStatusBar(tooltip, 0, progressBarInfo.max, progressBarInfo.value, progressBarInfo.text)

        -- Text-based fallback (kept for reference):
        -- GameTooltip_ShowStatusBar creates child layout frames that carry addon taint,
        -- causing "attempt to compare a secret number value" errors in LayoutFrame.lua
        -- when Blizzard's secure code later hides GameTooltip and cleans up widget sets.
        -- This was the original workaround before switching to a private tooltip frame.
        -- local pct = math.floor(progressBarInfo.value / progressBarInfo.max * 100)
        -- local progressText = progressBarInfo.text or (progressBarInfo.value .. " / " .. progressBarInfo.max)
        -- local colorFn = pct >= 98 and Utils.BlizzardLegendaryColorText
        --     or pct >= 90 and Utils.BlizzardEpicColorText
        --     or pct >= 80 and Utils.BlizzardRareColorText
        --     or pct >= 50 and Utils.BlizzardUncommonColorText
        --     or Utils.BlizzardCommonColorText
        -- tooltip:AddLine(Utils.WhiteText(progressText) .. colorFn("  (" .. pct .. "%)"), 1, 0.82, 0, false)
    end

    -- Display debug info for criteria
    if Utils.IsDebugMode() and #debugCriteriaInfo > 0 then
        tooltip:AddLine(" ")
        tooltip:AddLine(Utils.DebugIconText() .. " " .. Utils.BlizzardGreenText("Criteria Debug Info"), 1, 1, 1)
        tooltip:AddLine(Utils.DarkGrayText("1=criteriaString, 2=criteriaType, 3=completed, 4=quantity, 5=reqQuantity, 6=charName, 7=flags, 8=assetID, 9=quantityString"), 1, 1, 1)
        for _, line in ipairs(debugCriteriaInfo) do
            tooltip:AddLine(line, 0.7, 0.7, 0.7, false) -- false = don't wrap lines
        end
    end
end

-- Helper: Popoulate achievement tooltip
local function TooltipSetAchievementCommon(tooltip, achID)
    -- Clear existing lines and status bars from previous tooltip content
    tooltip:ClearLines()
    GameTooltip_ClearStatusBars(tooltip)

    -- Achievement Name
    local _, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = ns.GetAchievementInfo(achID)
    local achievementName = Utils.AchievementIconText() .. " " .. (name or "???")
    local completeness = ""
    if completed then
        local completionDate = FormatShortDate(day, month, year)
        if earnedBy and (earnedBy ~= "") then
            completionDate = completionDate .. " - " .. earnedBy
        end
        completeness = Utils.BlizzardGreenText(_G.ACHIEVEMENT_UNLOCKED .. " " .. completionDate)
    else
        completeness = Utils.GrayText(_G.IN_PROGRESS)
    end
    if Utils.IsDebugMode() then
        -- Append an achievement ID to the achievement name
        achievementName = achievementName .. " (" .. Utils.DebugIconText() .. Utils.BlizzardGreenText("Achievement ID:") .. " " .. achID .. ")"
    end
    tooltip:AddLine(achievementName)
    tooltip:AddLine(completeness)

    -- Description
    tooltip:AddLine(" ") -- Spacing
    local r, g, b = COLOR_ID:GetRGB()
    tooltip:AddLine(description, r, g, b, true)

    -- Display debug info for achievement
    if Utils.IsDebugMode() then
        tooltip:AddLine(" ") -- Spacing
        tooltip:AddLine(Utils.DebugIconText() .. " " .. Utils.BlizzardGreenText("Achievement Debug Info"), 1, 1, 1)
        tooltip:AddLine(Utils.DarkGrayText("1=id, 2=name, 3=points, 4=completed, 5=month, 6=day, 7=year, 8=description, 9=flags, 10=icon, 11=rewardText, 12=isGuild, 13=wasEarnedByMe, 14=earnedBy"), 1, 1, 1)
        local debugLine = string.format("1=%s, 2=%s, 3=%s, 4=%s, 5=%s, 6=%s, 7=%s, 8=%s, 9=%s, 10=%s, 11=%s, 12=%s, 13=%s, 14=%s",
            Utils.ColorByType(achID),
            Utils.ColorByType(name),
            Utils.ColorByType(points),
            Utils.ColorByType(completed),
            Utils.ColorByType(month),
            Utils.ColorByType(day),
            Utils.ColorByType(year),
            Utils.ColorByType(description),
            Utils.ColorByType(flags),
            Utils.ColorByType(icon),
            Utils.ColorByType(rewardText),
            Utils.ColorByType(isGuild),
            Utils.ColorByType(wasEarnedByMe),
            Utils.ColorByType(earnedBy)
        )
        tooltip:AddLine(debugLine, 0.7, 0.7, 0.7, false) -- false = don't wrap lines
    end

    -- Criteria
    AddCriteriaLines(tooltip, achID)

    -- Series
    if GetNextAchievement(achID) or GetPreviousAchievement(achID) then
        tooltip:AddLine(" ") -- Spacing
        tooltip:AddLine(ns.L["SERIESTIP"])
        local curAchID = GetPreviousAchievement(achID)
        local first
        while (curAchID) do  -- Find first achievement in the series:
            first = curAchID
            curAchID = GetPreviousAchievement(curAchID)
        end
        curAchID = first or achID
        local curCompleted = select(4, ns.GetAchievementInfo(curAchID))
        local curAchNum = 1
        while (curAchID) do
            local _, curAchName = ns.GetAchievementInfo(curAchID)
            local color;
            curAchName = curAchNum .. ". " .. curAchName
            if (curAchID == achID) then
                color = COLOR_ID
            elseif (curCompleted) then
                color = COLOR_COMPLETE
            else
                color = COLOR_GRAY
            end

            if curCompleted then
                curAchName = curAchName .. " " .. Utils.CheckAtlasText()
            end

            local r, g, b = color:GetRGB()
            tooltip:AddLine(curAchName, r, g, b, false) -- false = don't wrap lines
            curAchID, curCompleted = GetNextAchievement(curAchID)
            curAchNum = curAchNum + 1
        end
    end

    -- Criteria of
    local entries = ns.DB.Meta[achID]
    if entries then
        tooltip:AddLine(" ") -- Spacing
        tooltip:AddLine(ns.L["META_ACHIEVEMENT"])
        for _, parentAchID in ipairs(entries) do
            local _, name, _, completed = ns.GetAchievementInfo(parentAchID)
            local color;
            if (completed) then
                color = COLOR_COMPLETE
                name = name .. " " .. Utils.CheckAtlasText()
            else
                color = COLOR_GRAY
            end

            name = Utils.DotIconText() .. " " .. name

            local r, g, b = color:GetRGB()
            tooltip:AddLine(name, r, g, b, false) -- false = don't wrap lines
        end
    end

    -- Reward
    if rewardText and rewardText ~= "" then
        tooltip:AddLine(" ") -- Spacing
        tooltip:AddLine(rewardText)
    end

    -- Add ID to tooltip (like original ShowID option, Debug Mode Only)
    tooltip:AddLine(" ") -- Spacing
    tooltip:AddDoubleLine(Utils.DebugIconText() .. " " .. Utils.BlizzardGreenText("Achievement ID"), tostring(achID), nil, nil, nil, r, g, b)
    if Utils.IsDebugMode() then
        local categoryID = GetAchievementCategory(achID)
        tooltip:AddDoubleLine(Utils.DebugIconText() .. " " .. Utils.BlizzardGreenText("Category ID"), tostring(categoryID), nil, nil, nil, r, g, b)
    end
end

-- 1. Unit Tooltips (Critters, etc.)
local function OnTooltipSetUnit(tooltip, data)
    -- Writes to the global GameTooltip are unsafe (taint widgetContainer);
    -- redirect to a sidecar tooltip in that case. For other tooltips that
    -- pass through this callback, fall back to the per-tooltip guard.
    local useSidecar = (tooltip == GameTooltip)
    if not useSidecar and not CanModifyTooltip(tooltip) then return end

    -- tooltip:GetUnit() calls TooltipUtil.GetDisplayedUnit, which calls
    -- UnitName(UnitTokenFromGUID(data.guid)). On WORLD_CURSOR_TOOLTIP_UPDATE
    -- paths the GUID and derived unit token are secret values, and our
    -- callback is forceinsecure'd (TooltipDataHandler.lua AddCall path),
    -- so UnitName raises "Secret values are only allowed during untainted
    -- execution". Swallow that — we can't safely enrich world-cursor
    -- tooltips because every downstream unit API fails on those tokens too.
    local ok, unitName, unit = pcall(tooltip.GetUnit, tooltip)
    if not ok or not unit then
        if useSidecar then HideSidecar(tooltip) end
        return
    end

    -- Players don't have NPC achievements, so early return.
    -- UnitIsPlayer can also fail on secret unit tokens, so pcall it.
    local okP, isPlayer = pcall(UnitIsPlayer, unit)
    if okP and isPlayer then
        if useSidecar then HideSidecar(tooltip) end
        return
    end

    local matches = Overachiever2_Settings.EnableNPCTooltip
        and ns.GetUnitAchievements(unit, unitName) or {}

    local npcID
    local okG, guid = pcall(UnitGUID, unit)
    if okG and guid then npcID = ns.GetIDFromGUID(guid) end

    local debugMode = Utils.IsDebugMode()
    local hasContent = #matches > 0 or (debugMode and npcID)
    if not hasContent then
        if useSidecar then HideSidecar(tooltip) end
        return
    end

    local function populate(target)
        for _, match in ipairs(matches) do
            AppendAchievementLine(target, match)
        end
        if debugMode and npcID then
            if target:NumLines() > 0 then
                target:AddLine(" ") -- Spacing
            end
            local r, g, b = COLOR_ID:GetRGB()
            target:AddDoubleLine(Utils.DebugIconText() .. " " .. Utils.BlizzardGreenText("NPC ID"), npcID, nil, nil, nil, r, g, b)
        end
    end

    if useSidecar then
        ShowSidecar(tooltip, populate)
    else
        populate(tooltip)
    end
end

-- 2. Item Tooltips (Food, Drink, etc.)
local function OnTooltipSetItem(tooltip, data)
    local useSidecar = (tooltip == GameTooltip)
    if not useSidecar and not CanModifyTooltip(tooltip) then return end

    local itemID = data.id
    if not itemID then
        if useSidecar then HideSidecar(tooltip) end
        return
    end

    local matches = Overachiever2_Settings.EnableItemTooltip
        and ns.GetItemAchievements(itemID, GetItemInfo(itemID)) or {}

    local debugMode = Utils.IsDebugMode()
    local hasContent = #matches > 0 or debugMode
    if not hasContent then
        if useSidecar then HideSidecar(tooltip) end
        return
    end

    local function populate(target)
        for _, match in ipairs(matches) do
            AppendAchievementLine(target, match)
        end
        if debugMode then
            local r, g, b = COLOR_ID:GetRGB()
            target:AddDoubleLine(Utils.DebugIconText() .. " " .. Utils.BlizzardGreenText("Item ID"), itemID, nil, nil, nil, r, g, b)
        end
    end

    if useSidecar then
        ShowSidecar(tooltip, populate)
    else
        populate(tooltip)
    end
end
-- Register hooks for modern WoW (10.0.2+)
if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
end

-- 3. Achievement Tooltips when *CLICKING* links in chat
-- Uses OA2ClickTooltip (persistent, with close button) to avoid tainting GameTooltip.
local function OnItemRefSetHyperlink(self, link)
    if not Overachiever2_Settings.EnableAchievementTooltip or not Overachiever2_Settings.EnableChatClickAchievementTooltip then return end

    local achID = tonumber(link:match("^achievement:(%d+)"))
    if not achID then return end

    -- Signaled by ChatLinkClick.lua on middle-click: skip showing our click tooltip
    -- so the middle-click "open frame" action doesn't disturb any existing tooltip.
    if ns.suppressOA2ClickTooltip then
        ns.suppressOA2ClickTooltip = nil
        return
    end

    -- Hide the default ItemRefTooltip and replace with our persistent tooltip
    local anchor = { self:GetPoint(1) }
    self:Hide()

    OA2ClickTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    OA2ClickTooltip:ClearAllPoints()
    if anchor[1] then
        OA2ClickTooltip:SetPoint(unpack(anchor))
    else
        OA2ClickTooltip:SetPoint("TOPLEFT", UIParent, "CENTER")
    end
    TooltipSetAchievementCommon(OA2ClickTooltip, achID)
    OA2ClickTooltip:Show()
end
-- Hooks ItemRefTooltip:SetHyperlink instead of using TooltipDataProcessor to avoid
-- conflicts with addons like Prat-3.0 that call GameTooltip:SetHyperlink on hover,
-- which would also trigger TooltipDataProcessor achievement callbacks.
hooksecurefunc(ItemRefTooltip, "SetHyperlink", OnItemRefSetHyperlink)

-- 4. Achievement Category Tooltips (Achievement UI Side Menu)
-- These don't use TooltipDataProcessor, so we hook the Blizzard function directly.
local function HookCategoryTooltips()
    local function addonHook(button)
        if not Utils.IsDebugMode() then return end
        -- Even in debug mode, never decorate a tooltip Blizzard will attach a widget set
        -- to (map/minimap pins) — the AddLine writes below would taint its layout state.
        if not CanModifyTooltip(GameTooltip) then return end
        -- categoryID is set on the parent frame (AchievementCategoryTemplate)
        local frame = button:GetParent()
        local id = button.categoryID or (frame and frame.categoryID)

        if id then
            local r, g, b = COLOR_ID:GetRGB()
            GameTooltip:AddLine(" ") -- Spacing
            GameTooltip:AddDoubleLine(Utils.DebugIconText() .. " " .. Utils.BlizzardGreenText("Category ID"), tostring(id), nil, nil, nil, r, g, b)
            GameTooltip:Show()
        end
    end

    if AchievementFrameCategory_StatusBarTooltip then
        hooksecurefunc("AchievementFrameCategory_StatusBarTooltip", addonHook)
    end
    if AchievementFrameCategory_FeatOfStrengthTooltip then
        hooksecurefunc("AchievementFrameCategory_FeatOfStrengthTooltip", addonHook)
    end
end

-- 5. Main Achievement List Tooltips
local function OnAchievementListEnter(self)
    if not Overachiever2_Settings.EnableAchievementTooltip or not Overachiever2_Settings.EnableAchievementWindowTooltip then return end

    local achID = self.id
    if not achID then return end

    -- if DevTool and Utils.IsDebugMode() then
    --     DevTool:AddData(self, "OA2 Ach: " .. self.Label:GetText())
    -- end

    OA2Tooltip:SetOwner(self, Overachiever2_Settings.AchWindowTooltipAnchor)
    TooltipSetAchievementCommon(OA2Tooltip, achID)

    if Utils.IsDebugMode() then
        OA2Tooltip:AddLine(" ") -- Spacing
        local r, g, b = COLOR_ID:GetRGB()
        OA2Tooltip:AddDoubleLine(Utils.DebugIconText() .. " " .. Utils.BlizzardGreenText("List Index"), tostring(self.index), nil, nil, nil, r, g, b)
    end

    OA2Tooltip:Show()
end

local function OnAchievementListLeave(self)
    if not Overachiever2_Settings.EnableAchievementTooltip or not Overachiever2_Settings.EnableAchievementWindowTooltip then return end
    OA2Tooltip:Hide()
end

local function HookAchievementList()
    if AchievementTemplateMixin then
        hooksecurefunc(AchievementTemplateMixin, "OnEnter", OnAchievementListEnter)
        hooksecurefunc(AchievementTemplateMixin, "OnLeave", OnAchievementListLeave)
    end
end

-- 6. Meta Achievement Objective Tooltips (sub-achievements inside expanded objectives)
-- Full mixin override (not hooksecurefunc): Blizzard's OnEnter shows GameTooltip with
-- the completion date when self.date is set, so a hooksecurefunc would have to call
-- GameTooltip:Hide() afterwards to suppress that default tooltip — and Hide() taints
-- GameTooltip's layout state via OnHide → ClearWidgetSet → UpdateWidgetLayout.
-- Overriding lets us decide whether Blizzard's original runs at all, so when our
-- tooltip is enabled we never touch GameTooltip; when disabled we tail-call into
-- Blizzard's original and the writes inside it stay tagged Blizzard.
local origMetaCriteriaOnEnter, origMetaCriteriaOnLeave

local function OnMetaCriteriaEnter(self)
    if not Overachiever2_Settings.EnableAchievementTooltip
       or not Overachiever2_Settings.EnableAchievementWindowTooltip then
        if origMetaCriteriaOnEnter then return origMetaCriteriaOnEnter(self) end
        return
    end

    local achID = self.id
    if not achID then
        if origMetaCriteriaOnEnter then return origMetaCriteriaOnEnter(self) end
        return
    end

    OA2Tooltip:SetOwner(self, Overachiever2_Settings.AchWindowTooltipAnchor)
    TooltipSetAchievementCommon(OA2Tooltip, achID)
    OA2Tooltip:Show()
end

local function OnMetaCriteriaLeave(self)
    if not Overachiever2_Settings.EnableAchievementTooltip
       or not Overachiever2_Settings.EnableAchievementWindowTooltip then
        if origMetaCriteriaOnLeave then return origMetaCriteriaOnLeave(self) end
        return
    end
    OA2Tooltip:Hide()
end

local function HookMetaCriteria()
    if AchievementMetaCriteriaMixin then
        origMetaCriteriaOnEnter = AchievementMetaCriteriaMixin.OnEnter
        origMetaCriteriaOnLeave = AchievementMetaCriteriaMixin.OnLeave
        AchievementMetaCriteriaMixin.OnEnter = OnMetaCriteriaEnter
        AchievementMetaCriteriaMixin.OnLeave = OnMetaCriteriaLeave
    end
end

-- 7. Tracked Achievement Objective Tooltips (right-side objective tracker)
-- Override OnBlockHeaderEnter/Leave on the AchievementObjectiveTracker module instance.
-- These are empty stub methods on the base ObjectiveTrackerModuleMixin, designed to be overridden.
local function HookTrackedAchievements()
    if not AchievementObjectiveTracker then return end

    AchievementObjectiveTracker.OnBlockHeaderEnter = function(self, block)
        if not Overachiever2_Settings.EnableAchievementTooltip or not Overachiever2_Settings.EnableTrackedAchievementTooltip then return end
        local achID = block.id
        if not achID then return end
        OA2Tooltip:SetOwner(block, Overachiever2_Settings.TrackedTooltipAnchor)
        TooltipSetAchievementCommon(OA2Tooltip, achID)
        OA2Tooltip:Show()
    end

    AchievementObjectiveTracker.OnBlockHeaderLeave = function(self, block)
        if not Overachiever2_Settings.EnableAchievementTooltip or not Overachiever2_Settings.EnableTrackedAchievementTooltip then return end
        OA2Tooltip:Hide()
    end
end

-- 8. Chat Hyperlink Tooltips when *HOVERING* links in chat (achievement links only)
local function OnChatHyperlinkEnter(chatFrame, link)
    if not Overachiever2_Settings.EnableAchievementTooltip or not Overachiever2_Settings.EnableChatHoverAchievementTooltip then return end
    local achID = tonumber(link:match("^achievement:(%d+)"))
    if not achID then return end
    OA2Tooltip:SetOwner(chatFrame, "ANCHOR_CURSOR")
    TooltipSetAchievementCommon(OA2Tooltip, achID)
    OA2Tooltip:Show()
end

local function OnChatHyperlinkLeave()
    if not Overachiever2_Settings.EnableAchievementTooltip or not Overachiever2_Settings.EnableChatHoverAchievementTooltip then return end
    OA2Tooltip:Hide()
end

local function HookChatHyperlinks()
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            chatFrame:HookScript("OnHyperlinkEnter", OnChatHyperlinkEnter)
            chatFrame:HookScript("OnHyperlinkLeave", OnChatHyperlinkLeave)
        end
    end
end

-- Lastly. Hook everything
local function HookAllAchievementUI()
    HookCategoryTooltips()
    HookAchievementList()
    HookMetaCriteria()
end

if C_AddOns.IsAddOnLoaded("Blizzard_AchievementUI") then
    HookAllAchievementUI()
else
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, event, addonName)
        if addonName == "Blizzard_AchievementUI" then
            HookAllAchievementUI()
            self:UnregisterAllEvents()
        end
    end)
end

-- These don't depend on Blizzard_AchievementUI, hook immediately
HookTrackedAchievements()
HookChatHyperlinks()
