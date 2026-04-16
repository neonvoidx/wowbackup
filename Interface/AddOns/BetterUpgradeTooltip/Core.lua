local ADDON_NAME = ...
local Private = select(2, ...)
Private.frame = Private.frame or CreateFrame("Frame", ADDON_NAME)
local frame = Private.frame

------------------------------------------------------------
-- Defaults / SavedVariables
------------------------------------------------------------
local defaults = {
    colorRange = true,
    colorRank = true,
    showUpgradeCurrency = true,
    ilvlRangeColor = { 1, 1, 1, 1 }, -- RGBA
}

local function CopyDefaults(src, dst)
    if type(dst) ~= "table" then dst = {} end
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

------------------------------------------------------------
-- Versioned data loader
------------------------------------------------------------
-- `CRESTS` and `UPGRADE_TIERS` will be populated from `VersionedData.lua` when the addon loads.
local CRESTS, UPGRADE_TIERS

local function SelectVersionDataForToc(toc)
    local versioned = Private.VersionedData or {}

    -- Collect numeric keys
    local keys = {}
    for k in pairs(versioned) do
        table.insert(keys, tonumber(k))
    end
    table.sort(keys)

    -- Pick largest key <= toc
    local selectedKey
    for _, k in ipairs(keys) do
        if k <= toc then selectedKey = k end
    end

    if not selectedKey then
        -- Fallback to lowest available or warn if none
        selectedKey = keys[1]
        if selectedKey then
            print(ADDON_NAME .. ": no versioned dataset <= " .. tostring(toc) .. "; falling back to " .. tostring(selectedKey))
        else
            print(ADDON_NAME .. ": no versioned datasets found")
            return
        end
    end

    local data = versioned[selectedKey]
    CRESTS = data.CRESTS or {}
    UPGRADE_TIERS = data.UPGRADE_TIERS or {}

    -- Normalize crestLevel numeric refs to actual crest tables
    for _, tier in ipairs(UPGRADE_TIERS) do
        if tier.crestLevels then
            for level, v in pairs(tier.crestLevels) do
                if type(v) == "number" then
                    tier.crestLevels[level] = CRESTS[v]
                end
            end
        end
    end

    -- Basic validation: ensure crest entries are tables when present
    for _, tier in ipairs(UPGRADE_TIERS) do
        if tier.crestLevels then
            for level, crest in pairs(tier.crestLevels) do
                if crest and type(crest) ~= "table" then
                    print(ADDON_NAME .. ": warning: invalid crest reference in tier '" .. (tier.name or "?") .. "' level " .. tostring(level))
                end
            end
        end
    end

    Private.selectedVersionKey = selectedKey
end

-- Expose selector for testing and other files via the addon namespace
Private.SelectVersionDataForToc = SelectVersionDataForToc

local function GetAvailableVersionKeys()
    local versioned = Private.VersionedData or {}
    local keys = {}
    for k in pairs(versioned) do table.insert(keys, tonumber(k)) end
    table.sort(keys)
    return keys
end
Private.GetAvailableVersionKeys = GetAvailableVersionKeys

function Private:GetSelectedVersionKey()
    return self.selectedVersionKey
end


------------------------------------------------------------
-- Helper logic
------------------------------------------------------------
local function GetCrestForLevel(crestLevels, current, maxUpgrade)
    if current == maxUpgrade then
        return nil
    end
    local selectedCrest
    for level, crest in pairs(crestLevels) do
        if current >= level then
            selectedCrest = crest
        end
    end
    return selectedCrest
end

local function GetUpgradeTierData(ilvl, current, total)
    for _, tier in ipairs(UPGRADE_TIERS) do
        if ilvl >= tier.minIlvl and ilvl <= tier.maxIlvl and total == tier.maxUpgrade then
            local step = (tier.maxIlvl - tier.minIlvl) / (tier.maxUpgrade - 1)
            local expectedIlvl = tier.minIlvl + (current - 1) * step
            if math.abs(ilvl - expectedIlvl) <= step then
                return {
                    name = tier.name,
                    minIlvl = tier.minIlvl,
                    maxIlvl = tier.maxIlvl,
                    color = tier.color,
                    crest = GetCrestForLevel(tier.crestLevels, current, tier.maxUpgrade)
                }
            end
        end
    end
end

------------------------------------------------------------
-- Tooltip processing
------------------------------------------------------------
local function ProcessTooltip(tooltip, tooltipData)
    if tooltip:IsForbidden() then return end

    local _, itemLink = TooltipUtil.GetDisplayedItem(tooltip)
    if not itemLink then return end

    local item = Item:CreateFromItemLink(itemLink)
    if item:IsItemEmpty() then return end

    local itemLevel = item:GetCurrentItemLevel()
    local itemHighWatermark = C_ItemUpgrade.GetHighWatermarkForItem(itemLink)

    local upgradePattern = ITEM_UPGRADE_TOOLTIP_FORMAT_STRING:gsub("%%s %%d/%%d", "(%%D+ %%d+/%%d+)")
    local tierPattern = ITEM_UPGRADE_TOOLTIP_FORMAT_STRING:gsub("%%s %%d/%%d", "(%%D+) (%%d+)/(%%d+)")

    for i = 1, tooltip:NumLines() do
        if tooltipData and tooltipData.lines and tooltipData.lines[i] and tooltipData.lines[i].type == Enum.TooltipDataLineType.ItemUpgradeLevel then

            local left = _G[tooltip:GetName().."TextLeft"..i]
            local text = left and left:GetText()

            if text and not issecretvalue(text) and string.find(text, upgradePattern) then
                local tier, current, total = string.match(text, tierPattern)

                local tierData = GetUpgradeTierData(itemLevel, tonumber(current), tonumber(total))
                if not tierData then return end

                local rangeColor = ""
                local tierColor = ""

                if BetterUpgradeTooltipDB.colorRange then
                    rangeColor = CreateColor(unpack(BetterUpgradeTooltipDB.ilvlRangeColor))
                        :GenerateHexColorMarkup()
                end

                if BetterUpgradeTooltipDB.colorRank then
                    tierColor = tierData.color:GenerateHexColorMarkup()
                end

                left:SetText(string.format(
                    "%s%d/%d %s|r %s(%d-%d)|r",
                    tierColor, current, total, tier,
                    rangeColor, tierData.minIlvl, tierData.maxIlvl
                ))

                if tierData.crest and BetterUpgradeTooltipDB.showUpgradeCurrency then
                    local right = _G[tooltip:GetName().."TextRight"..i]
                    if right then
                        local crest = tierData.crest
                        local achieved = crest.achieve and select(13, GetAchievementInfo(crest.achieve))
                        local crestText
                        if itemLevel < itemHighWatermark then
                            crestText = CRESTS[0].color:WrapTextInColorCode("|TInterface\\MoneyFrame\\UI-GoldIcon:12:12|t Gold")
                        else
                            crestText = not achieved and crest.color:WrapTextInColorCode(crest.shortName) or CRESTS[0].color:WrapTextInColorCode(crest.shortName)
                        end
                        right:SetText("|A:2329:20:20:1:-1|a" .. crestText)
                        right:Show()
                    end
                end
            end
        end
    end
end

------------------------------------------------------------
-- Init
------------------------------------------------------------
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, _, name)
    if name ~= ADDON_NAME then return end


    BetterUpgradeTooltipDB = CopyDefaults(defaults, BetterUpgradeTooltipDB)

    -- Select versioned data that best matches the current game build/tocversion
    do
        local currentToc = select(4, GetBuildInfo()) or 0
        SelectVersionDataForToc(currentToc)
    end

    TooltipDataProcessor.AddTooltipPostCall(
        Enum.TooltipDataType.Item,
        ProcessTooltip
    )
end)
frame:HookScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == ADDON_NAME then
        if Private.InitSettings then
            Private:InitSettings()
        end
    end
end)