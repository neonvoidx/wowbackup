-- Housing_HoverInfoPanel.lua
-- 功能：悬停信息面板 - 显示在 QuickBar 顶部，展示当前悬停/选中装饰的信息
-- 设计：简洁无边框，居中布局，底部信息一行显示

local ADDON_NAME, ADT = ...
if not ADT or not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local L = ADT.L or {}

--------------------------------------------------------------------------------
-- 配置读取（单一权威：从 Housing_Config.HoverInfoPanel 读取）
--------------------------------------------------------------------------------
local function GetCFG()
    local cfg = ADT and ADT.HousingInstrCFG and ADT.HousingInstrCFG.HoverInfoPanel
    return cfg or {}
end

--------------------------------------------------------------------------------
-- 模块
--------------------------------------------------------------------------------
local HoverInfoPanel = {}
ADT.HoverInfoPanel = HoverInfoPanel

local panelFrame = nil

--------------------------------------------------------------------------------
-- 辅助函数
--------------------------------------------------------------------------------
local function D(msg)
    if ADT and ADT.DebugPrint then ADT.DebugPrint(msg) end
end

-- 从配置读取颜色
local function Colorize(key, text)
    local cfg = ADT and ADT.HousingInstrCFG
    local colors = cfg and cfg.Colors
    local hex = colors and colors[key]
    if not hex then return tostring(text or "") end
    return "|c" .. hex .. tostring(text or "") .. "|r"
end

-- 获取目录装饰信息
local function GetCatalogDecorInfo(decorID)
    if not C_HousingCatalog or not C_HousingCatalog.GetCatalogEntryInfoByRecordID then return nil end
    return C_HousingCatalog.GetCatalogEntryInfoByRecordID(Enum.HousingCatalogEntryType.Decor, decorID, true)
end

-- 获取当前悬停/选中的装饰信息
local function GetActiveDecorInfo()
    if C_HousingDecor then
        if C_HousingDecor.IsHoveringDecor and C_HousingDecor.IsHoveringDecor() then
            local info = C_HousingDecor.GetHoveredDecorInfo and C_HousingDecor.GetHoveredDecorInfo()
            if info then return info end
        end
        if C_HousingDecor.IsDecorSelected and C_HousingDecor.IsDecorSelected() then
            local info = C_HousingDecor.GetSelectedDecorInfo and C_HousingDecor.GetSelectedDecorInfo()
            if info then return info end
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- 创建圆角染色色块
--------------------------------------------------------------------------------
local function CreateDyeSwatch(parent, index)
    local cfg = GetCFG()
    local size = cfg.DyeSwatchSize or 14
    
    local swatch = CreateFrame("Frame", nil, parent)
    swatch:SetSize(size, size)
    
    -- 背景色块
    local bg = swatch:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.3, 0.3, 0.3, 1)
    swatch.Background = bg
    
    -- 颜色纹理
    local color = swatch:CreateTexture(nil, "ARTWORK")
    color:SetPoint("TOPLEFT", 1, -1)
    color:SetPoint("BOTTOMRIGHT", -1, 1)
    color:SetColorTexture(1, 1, 1, 1)
    swatch.ColorTexture = color
    
    -- 边框（模拟圆角效果）
    local border = swatch:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints()
    border:SetAtlas("Tooltip-Gray-CornerAccent", true)
    border:SetAlpha(0.5)
    swatch.Border = border
    
    swatch.index = index
    
    function swatch:SetColor(r, g, b, a)
        self.ColorTexture:SetColorTexture(r or 0.5, g or 0.5, b or 0.5, a or 1)
    end
    
    function swatch:SetEmpty()
        self.ColorTexture:SetColorTexture(0.25, 0.25, 0.25, 0.8)
    end
    
    return swatch
end

--------------------------------------------------------------------------------
-- 创建面板
--------------------------------------------------------------------------------
function HoverInfoPanel:Create()
    if panelFrame then return panelFrame end
    
    D("[HoverInfoPanel] Creating...")
    
    local cfg = GetCFG()
    
    -- 获取 QuickBar 框架以确定宽度
    local quickbar = ADT.QuickbarUI and _G["ADTQuickbarFrame"]
    local panelWidth = quickbar and quickbar:GetWidth() or 700
    local panelHeight = cfg.Height or 56
    
    panelFrame = CreateFrame("Frame", "ADTHoverInfoPanel", UIParent)
    panelFrame:SetSize(panelWidth, panelHeight)
    panelFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    panelFrame:SetFrameLevel(99)
    
    -- 标题（装饰名称，居中）
    local titleFontSize = cfg.TitleFontSize or 18
    local title = panelFrame:CreateFontString(nil, "OVERLAY")
    -- 使用游戏默认字体族，确保中文客户端可显示
    local titleFontPath, _, titleFontFlags = GameFontNormalLarge:GetFont()
    title:SetFont(titleFontPath, titleFontSize, titleFontFlags)
    title:SetPoint("TOP", panelFrame, "TOP", 0, -4)
    title:SetJustifyH("CENTER")
    title:SetTextColor(1, 0.82, 0)  -- 金色
    title:SetShadowColor(0, 0, 0, 1)
    title:SetShadowOffset(1, -1)
    panelFrame.Title = title
    
    -- 分隔线（使用 evergreen-weeklyrewards-header）
    local dividerInsetX = cfg.DividerInsetX or 20
    local dividerHeight = cfg.DividerHeight or 8
    local dividerOffsetY = cfg.DividerOffsetY or -28
    local divider = panelFrame:CreateTexture(nil, "ARTWORK")
    divider:SetAtlas("evergreen-weeklyrewards-header")
    divider:SetHeight(dividerHeight)
    divider:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", dividerInsetX, dividerOffsetY)
    divider:SetPoint("TOPRIGHT", panelFrame, "TOPRIGHT", -dividerInsetX, dividerOffsetY)
    panelFrame.Divider = divider
    
    -- 信息行容器（居中布局）
    local infoRowOffsetY = cfg.InfoRowOffsetY or -4
    local infoRow = CreateFrame("Frame", nil, panelFrame)
    infoRow:SetHeight(20)
    infoRow:SetPoint("TOP", divider, "BOTTOM", 0, infoRowOffsetY)
    infoRow:SetPoint("LEFT", panelFrame, "LEFT", 0, 0)
    infoRow:SetPoint("RIGHT", panelFrame, "RIGHT", 0, 0)
    panelFrame.InfoRow = infoRow
    
    -- 位置文本（室内/外）
    local locText = infoRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    locText:SetJustifyH("LEFT")
    panelFrame.LocationText = locText
    
    -- 分隔符1
    local sep1 = infoRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sep1:SetText(Colorize('separatorMuted', ' | '))
    panelFrame.Sep1 = sep1
    
    -- 库存文本
    local stockText = infoRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stockText:SetJustifyH("LEFT")
    panelFrame.StockText = stockText
    
    -- 分隔符2
    local sep2 = infoRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sep2:SetText(Colorize('separatorMuted', ' | '))
    panelFrame.Sep2 = sep2
    
    -- 预算图标
    local budgetIconSize = cfg.BudgetIconSize or 16
    local budgetIcon = infoRow:CreateTexture(nil, "ARTWORK")
    budgetIcon:SetSize(budgetIconSize, budgetIconSize)
    budgetIcon:SetAtlas("house-decor-budget-icon")
    panelFrame.BudgetIcon = budgetIcon
    
    -- 预算数值
    local budgetText = infoRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    budgetText:SetJustifyH("LEFT")
    budgetText:SetTextColor(232/255, 215/255, 140/255)  -- 金色
    panelFrame.BudgetText = budgetText
    
    -- 分隔符3（仅染色时显示）
    local sep3 = infoRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sep3:SetText(Colorize('separatorMuted', ' | '))
    panelFrame.Sep3 = sep3
    
    -- 染色板容器
    local dyeSwatchSize = cfg.DyeSwatchSize or 14
    local dyeContainer = CreateFrame("Frame", nil, infoRow)
    dyeContainer:SetSize(100, dyeSwatchSize)
    panelFrame.DyeContainer = dyeContainer
    
    -- 染色图标
    local dyeIconSize = cfg.DyeIconSize or 16
    local dyeIcon = dyeContainer:CreateTexture(nil, "ARTWORK")
    dyeIcon:SetSize(dyeIconSize, dyeIconSize)
    dyeIcon:SetAtlas("catalog-palette-icon")
    dyeIcon:SetPoint("LEFT", dyeContainer, "LEFT", 0, 0)
    panelFrame.DyeIcon = dyeIcon
    
    -- 创建 3 个染色色块
    local dyeIconSpacing = cfg.DyeIconSpacing or 4
    local dyeSwatchSpacing = cfg.DyeSwatchSpacing or 2
    panelFrame.DyeSwatches = {}
    for i = 1, 3 do
        local swatch = CreateDyeSwatch(dyeContainer, i)
        swatch:SetPoint("LEFT", dyeIcon, "RIGHT", dyeIconSpacing + (i-1) * (dyeSwatchSize + dyeSwatchSpacing), 0)
        panelFrame.DyeSwatches[i] = swatch
    end
    
    panelFrame:Hide()
    
    D("[HoverInfoPanel] Created successfully")
    return panelFrame
end

--------------------------------------------------------------------------------
-- 更新布局（居中排列信息行）
--------------------------------------------------------------------------------
function HoverInfoPanel:UpdateLayout(hasDye)
    if not panelFrame then return end
    
    local cfg = GetCFG()
    local budgetIconSize = cfg.BudgetIconSize or 16
    local budgetIconSpacing = cfg.BudgetIconSpacing or 4
    local dyeSwatchSize = cfg.DyeSwatchSize or 14
    local dyeSwatchSpacing = cfg.DyeSwatchSpacing or 2
    
    local infoRow = panelFrame.InfoRow
    local locText = panelFrame.LocationText
    local sep1 = panelFrame.Sep1
    local stockText = panelFrame.StockText
    local sep2 = panelFrame.Sep2
    local budgetIcon = panelFrame.BudgetIcon
    local budgetText = panelFrame.BudgetText
    local sep3 = panelFrame.Sep3
    local dyeContainer = panelFrame.DyeContainer
    
    local totalWidth = 0
    
    -- 位置
    local locW = locText:GetStringWidth() or 0
    totalWidth = totalWidth + locW
    
    -- 分隔符1
    local sep1W = sep1:GetStringWidth() or 0
    totalWidth = totalWidth + sep1W
    
    -- 库存
    local stockW = stockText:GetStringWidth() or 0
    totalWidth = totalWidth + stockW
    
    -- 分隔符2
    local sep2W = sep2:GetStringWidth() or 0
    totalWidth = totalWidth + sep2W
    
    -- 预算图标 + 数值
    local budgetW = budgetIconSize + budgetIconSpacing + (budgetText:GetStringWidth() or 0)
    totalWidth = totalWidth + budgetW
    
    -- 染色（如果有）
    local dyeW = 0
    if hasDye then
        local sep3W = sep3:GetStringWidth() or 0
        totalWidth = totalWidth + sep3W
        
        local numSlots = 0
        for i, swatch in ipairs(panelFrame.DyeSwatches) do
            if swatch:IsShown() then numSlots = numSlots + 1 end
        end
        local dyeIconSize = cfg.DyeIconSize or 16
        local dyeIconSpacing = cfg.DyeIconSpacing or 4
        dyeW = dyeIconSize + dyeIconSpacing + (numSlots * dyeSwatchSize) + ((numSlots - 1) * dyeSwatchSpacing)
        totalWidth = totalWidth + dyeW
    end
    
    -- 计算起始 X 使整体居中
    local startX = -totalWidth / 2
    local currentX = startX
    
    -- 位置
    locText:ClearAllPoints()
    locText:SetPoint("LEFT", infoRow, "CENTER", currentX, 0)
    currentX = currentX + locW
    
    -- 分隔符1
    sep1:ClearAllPoints()
    sep1:SetPoint("LEFT", infoRow, "CENTER", currentX, 0)
    currentX = currentX + sep1W
    
    -- 库存
    stockText:ClearAllPoints()
    stockText:SetPoint("LEFT", infoRow, "CENTER", currentX, 0)
    currentX = currentX + stockW
    
    -- 分隔符2
    sep2:ClearAllPoints()
    sep2:SetPoint("LEFT", infoRow, "CENTER", currentX, 0)
    currentX = currentX + sep2W
    
    -- 预算图标
    budgetIcon:ClearAllPoints()
    budgetIcon:SetPoint("LEFT", infoRow, "CENTER", currentX, 0)
    currentX = currentX + budgetIconSize + budgetIconSpacing
    
    -- 预算数值
    budgetText:ClearAllPoints()
    budgetText:SetPoint("LEFT", infoRow, "CENTER", currentX, 0)
    currentX = currentX + (budgetText:GetStringWidth() or 0)
    
    -- 染色（如果有）
    if hasDye then
        sep3:ClearAllPoints()
        sep3:SetPoint("LEFT", infoRow, "CENTER", currentX, 0)
        sep3:Show()
        currentX = currentX + (sep3:GetStringWidth() or 0)
        
        dyeContainer:ClearAllPoints()
        dyeContainer:SetPoint("LEFT", infoRow, "CENTER", currentX, 0)
        dyeContainer:SetWidth(dyeW)
        dyeContainer:Show()
    else
        sep3:Hide()
        dyeContainer:Hide()
    end
end

--------------------------------------------------------------------------------
-- 更新显示内容
--------------------------------------------------------------------------------
local lastInfo, lastNonEmptyAt

function HoverInfoPanel:Update()
    -- 传统界面下不显示信息面板
    if ADT.InterfaceStyle and ADT.InterfaceStyle:IsClassic() then
        self:Hide()
        return
    end
    
    if not C_HouseEditor or not C_HouseEditor.IsHouseEditorActive or not C_HouseEditor.IsHouseEditorActive() then
        self:Hide()
        return
    end
    
    if not panelFrame then self:Create() end
    
    local cfg = GetCFG()
    local clearDelay = cfg.ClearDelay or 0.15
    
    local info = GetActiveDecorInfo()
    
    -- 防抖
    if info then
        lastInfo, lastNonEmptyAt = info, GetTime()
    elseif lastNonEmptyAt and (GetTime() - lastNonEmptyAt) <= clearDelay then
        return
    end
    
    if not info then
        self._wantVisible = false
        self:Hide()
        return
    end
    
    -- 标题
    local displayName = info.name or ""
    if ADT.Housing and ADT.Housing.Protection and ADT.Housing.Protection.IsProtected then
        local isProtected = ADT.Housing.Protection:IsProtected(info.decorGUID, info.decorID)
        if isProtected then
            displayName = "|A:BonusChest-Lock:16:16|a " .. displayName
        end
    end
    panelFrame.Title:SetText(displayName)
    
    -- 位置
    local indoor = not not info.isAllowedIndoors
    local outdoor = not not info.isAllowedOutdoors
    local placeText = (indoor and outdoor) and (L["Indoor & Outdoor"] or "室内外")
        or (indoor and (L["Indoor"] or "室内"))
        or (outdoor and (L["Outdoor"] or "室外"))
        or (L["Indoor"] or "室内")
    panelFrame.LocationText:SetText(Colorize('labelMuted', placeText))
    
    -- 库存
    local entryInfo = info.decorID and GetCatalogDecorInfo(info.decorID)
    local stored = 0
    local placementCost = 0
    if entryInfo then
        stored = (entryInfo.quantity or 0) + (entryInfo.remainingRedeemable or 0)
        placementCost = entryInfo.placementCost or 0
    end
    
    local stockLabel = L["Stock"] or "库存"
    local stockVal = (stored and stored > 0)
        and Colorize('valueGood', tostring(stored))
        or Colorize('valueBad', tostring(stored or 0))
    panelFrame.StockText:SetText(Colorize('labelMuted', stockLabel .. ": ") .. stockVal)
    
    -- 预算
    panelFrame.BudgetText:SetText(tostring(placementCost))
    
    -- 染色
    local slots = info.dyeSlots or {}
    local hasDye = #slots > 0
    
    if hasDye then
        -- 按 orderIndex 排序
        local sortedSlots = {}
        for i, s in ipairs(slots) do sortedSlots[i] = s end
        table.sort(sortedSlots, function(a, b)
            return (a.orderIndex or 0) < (b.orderIndex or 0)
        end)
        
        -- 更新色块
        for i = 1, 3 do
            local swatch = panelFrame.DyeSwatches[i]
            local slot = sortedSlots[i]
            if slot then
                local colorID = slot.dyeColorID
                if colorID and colorID > 0 and C_DyeColor and C_DyeColor.GetDyeColorInfo then
                    local colorData = C_DyeColor.GetDyeColorInfo(colorID)
                    if colorData and colorData.swatchColorStart then
                        local r, g, b = colorData.swatchColorStart:GetRGB()
                        swatch:SetColor(r, g, b, 1)
                    else
                        swatch:SetEmpty()
                    end
                else
                    swatch:SetEmpty()
                end
                swatch:Show()
            else
                swatch:Hide()
            end
        end
    end
    
    -- 更新布局
    self:UpdateLayout(hasDye)
    
    -- 显示并定位
    self._wantVisible = true
    self:Show()
end

--------------------------------------------------------------------------------
-- 显示/隐藏
--------------------------------------------------------------------------------
function HoverInfoPanel:Show()
    if not panelFrame then self:Create() end
    
    local cfg = GetCFG()
    local gapToQuickbar = cfg.GapToQuickbar or 4
    
    -- 定位到 QuickBar 顶部
    local function DoShow()
        if not self._wantVisible then return end
        local quickbar = _G["ADTQuickbarFrame"]
        if quickbar and quickbar:IsShown() then
            panelFrame:ClearAllPoints()
            panelFrame:SetPoint("BOTTOM", quickbar, "TOP", 0, gapToQuickbar)
            panelFrame:SetWidth(quickbar:GetWidth())
            panelFrame:SetParent(quickbar:GetParent())
            panelFrame:SetFrameStrata(quickbar:GetFrameStrata())
            panelFrame:SetFrameLevel(quickbar:GetFrameLevel() - 1)
            panelFrame:Show()
        else
            panelFrame:Hide()
        end
    end

    if ADT.QuickbarUI and ADT.QuickbarUI.WhenStable then
        if ADT.QuickbarUI:IsStable() then
            DoShow()
        elseif not self._pendingShow then
            self._pendingShow = true
            ADT.QuickbarUI:WhenStable(function()
                self._pendingShow = nil
                DoShow()
            end)
            panelFrame:Hide()
        end
    else
        DoShow()
    end
end

function HoverInfoPanel:Hide()
    self._pendingShow = nil
    if panelFrame then
        panelFrame:Hide()
    end
end

--------------------------------------------------------------------------------
-- 事件监听
--------------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("HOUSE_EDITOR_MODE_CHANGED")
eventFrame:RegisterEvent("HOUSING_BASIC_MODE_HOVERED_TARGET_CHANGED")
eventFrame:RegisterEvent("HOUSING_EXPERT_MODE_HOVERED_TARGET_CHANGED")
eventFrame:RegisterEvent("HOUSING_BASIC_MODE_SELECTED_TARGET_CHANGED")
eventFrame:RegisterEvent("HOUSING_EXPERT_MODE_SELECTED_TARGET_CHANGED")
eventFrame:RegisterEvent("HOUSING_CUSTOMIZE_MODE_HOVERED_TARGET_CHANGED")
eventFrame:RegisterEvent("HOUSING_CUSTOMIZE_MODE_SELECTED_TARGET_CHANGED")
eventFrame:RegisterEvent("HOUSING_DECOR_CUSTOMIZATION_CHANGED")
eventFrame:RegisterEvent("HOUSING_CLEANUP_MODE_HOVERED_TARGET_CHANGED")
eventFrame:RegisterEvent("HOUSING_CLEANUP_MODE_TARGET_SELECTED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    HoverInfoPanel:Update()
end)

D("[HoverInfoPanel] Module loaded")
