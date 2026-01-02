-- Housing_IndoorBypass.lua
-- 目标：当“室外解禁”开启且玩家处于室外时，在官方仓库清单中补回“仅限室内”的已拥有装饰条目。
-- 展示为灰态（沿用官方失效视觉），但点击时通过 ADT 的单一权威 API 直接抓取到鼠标。
-- 约束：
-- - 不篡改官方判定与样式，只做数据补回与点击改道；
-- - 仅作用于“仓库（Owned/Storage）”视图；不影响市场/专题等其它自定义视图；
-- - 全链路以 decor recordID 为唯一权威，不做兼容映射（禁止 entryID/句柄驱动）。

local ADDON_NAME, ADT = ...
if not ADT then return end

local M = {}
ADT.IndoorBypass = M

local function Debug(msg)
    if ADT and ADT.DebugPrint then ADT.DebugPrint("[IndoorBypass] " .. tostring(msg)) end
end

local function IsBypassActive()
    local on = ADT and ADT.GetDBBool and ADT.GetDBBool("EnableIndoorOutdoorBypass")
    if not on then return false end
    if not (C_HouseEditor and C_HouseEditor.IsHouseEditorActive and C_HouseEditor.IsHouseEditorActive()) then
        return false
    end
    -- 仅当处于“室外”时启用补回
    local inside = C_Housing and C_Housing.IsInsideHouse and C_Housing.IsInsideHouse()
    return not inside
end

-- 与 Quickbar 行为保持一致：仅“进入抓取态”，不直接在鼠标位置落地
local function IsPlacingDecor()
    if C_HousingBasicMode and C_HousingBasicMode.IsPlacingNewDecor and C_HousingBasicMode.IsPlacingNewDecor() then
        return true
    end
    if C_HousingBasicMode and C_HousingBasicMode.IsDecorSelected and C_HousingBasicMode.IsDecorSelected() then
        return true
    end
    if C_HousingExpertMode and C_HousingExpertMode.IsDecorSelected and C_HousingExpertMode.IsDecorSelected() then
        return true
    end
    if C_HousingBasicMode and C_HousingBasicMode.HasCurrentPlacement and C_HousingBasicMode.HasCurrentPlacement() then
        return true
    end
    return false
end

local function CancelActiveEditing()
    if ADT and ADT.Housing and ADT.Housing.CancelActiveEditing then
        return ADT.Housing:CancelActiveEditing()
    end
    return false
end

-- 统一抓取流程：切到基础模式 → 清除 commitOnMouseUp →（必要时）取消当前抓取 → 下一帧再 StartPlacing
local function BeginGrabByRecordID(recordID)
    if not recordID then return end

    local function clearCommitFlag()
        local hf = _G.HouseEditorFrame
        local af = hf and hf.GetActiveModeFrame and hf:GetActiveModeFrame()
        if af and af.commitNewDecorOnMouseUp ~= false then
            af.commitNewDecorOnMouseUp = false
        end
    end

    local function doStart()
        clearCommitFlag()
        if ADT and ADT.Housing and ADT.Housing.StartPlacingByRecordID then
            ADT.Housing:StartPlacingByRecordID(recordID)
        end
    end

    local basic = Enum and Enum.HouseEditorMode and Enum.HouseEditorMode.BasicDecor
    local cur = C_HouseEditor.GetActiveHouseEditorMode and C_HouseEditor.GetActiveHouseEditorMode()
    if cur ~= basic then
        pcall(C_HouseEditor.ActivateHouseEditorMode, basic)
        C_Timer.After(0, doStart)
        return
    end

    if IsPlacingDecor() then
        CancelActiveEditing()
        C_Timer.After(0, doStart)
    else
        C_Timer.After(0, doStart)
    end
end

-- 复制当前 searcher 的筛选上下文（分类/子分类/搜索文本/标签等）到新 searcher，
-- 但显式允许“室内”条目进入候选集，再由我们筛掉可室外的，仅保留“室内-only”。
local function CloneSearcherForIndoorOnly(source)
    local s = C_HousingCatalog and C_HousingCatalog.CreateCatalogSearcher and C_HousingCatalog.CreateCatalogSearcher()
    if not s then return nil end
    pcall(s.SetAutoUpdateOnParamChanges, s, false)

    -- 分类/子分类/文本/排序（排序对我们合并无强约束，可交由官方二次排序；此处不显式设置）
    if source.GetFilteredCategoryID then pcall(s.SetFilteredCategoryID, s, source:GetFilteredCategoryID()) end
    if source.GetFilteredSubcategoryID then pcall(s.SetFilteredSubcategoryID, s, source:GetFilteredSubcategoryID()) end
    if source.GetSearchText then pcall(s.SetSearchText, s, source:GetSearchText()) end
    if source.GetEditorModeContext then pcall(s.SetEditorModeContext, s, source:GetEditorModeContext()) end

    -- 与仓库一致：必须是“仅已拥有（且在仓库中有存量/可兑换）”
    pcall(s.SetOwnedOnly, s, true)

    -- 标签开关尽量对齐（若存在）
    if source.IsCustomizableOnlyActive and source:IsCustomizableOnlyActive() then pcall(s.SetCustomizableOnly, s, true) end
    if source.IsCollectedActive and source:IsCollectedActive() then pcall(s.SetCollected, s, true) end
    if source.IsUncollectedActive and source:IsUncollectedActive() then pcall(s.SetUncollected, s, true) end

    -- 关键：允许“室内”，不强制排除“室外”——最终由我们按 isAllowedOutdoors 过滤成“室内-only”。
    pcall(s.SetAllowedIndoors, s, true)

    pcall(s.RunSearch, s)
    return s
end

-- 生成“官方结果 ∪ 室内-only补回”的合并列表（元素为 HousingCatalogEntryID）
local function BuildMergedEntries(storagePanel)
    if not (storagePanel and storagePanel.catalogSearcher) then return nil end
    if not IsBypassActive() then return nil end
    if storagePanel.IsInMarketTab and storagePanel:IsInMarketTab() then return nil end

    local base = storagePanel.catalogSearcher:GetCatalogSearchResults() or {}
    local existRID = {}
    for _, id in ipairs(base) do
        if id.entryType == Enum.HousingCatalogEntryType.Decor then
            existRID[id.recordID] = true
        end
    end

    local s = CloneSearcherForIndoorOnly(storagePanel.catalogSearcher)
    if not s then return nil end
    local list = s:GetCatalogSearchResults() or {}

    local extras = {}
    for _, id in ipairs(list) do
        if id.entryType == Enum.HousingCatalogEntryType.Decor and not existRID[id.recordID] then
            local info = C_HousingCatalog.GetCatalogEntryInfo and C_HousingCatalog.GetCatalogEntryInfo(id)
            if info and info.isAllowedIndoors and not info.isAllowedOutdoors then
                local stored = (info.quantity or 0) + (info.remainingRedeemable or 0)
                if stored > 0 then
                    table.insert(extras, id)
                end
            end
        end
    end

    if #extras == 0 then return nil end

    local merged = {}
    for _, v in ipairs(base) do table.insert(merged, v) end
    for _, v in ipairs(extras) do table.insert(merged, v) end
    Debug(string.format("merge base=%d extras=%d", #base, #extras))
    return merged
end

-- 在解禁+室外时，强制令“室内”筛选为开启（避免暴雪默认在室外关闭该项）。
local function EnsureIndoorsFilterOn(storagePanel)
    if not storagePanel or not storagePanel.catalogSearcher then return end
    if not IsBypassActive() then return end
    -- 仅仓库视图
    if storagePanel.IsInMarketTab and storagePanel:IsInMarketTab() then return end
    -- 若已是 true 则不重复
    local isOn = storagePanel.catalogSearcher.IsAllowedIndoorsActive and storagePanel.catalogSearcher:IsAllowedIndoorsActive()
    if not isOn then
        pcall(storagePanel.catalogSearcher.SetAllowedIndoors, storagePanel.catalogSearcher, true)
        pcall(storagePanel.catalogSearcher.SetAllowedOutdoors, storagePanel.catalogSearcher, true)
        -- 刷新筛选 UI
        local fd = storagePanel.Filters and storagePanel.Filters.FilterDropdown
        if fd and fd.ValidateResetState then pcall(fd.ValidateResetState, fd) end
        local menu = fd and rawget(fd, "menu")
        if menu and menu.ReinitializeAll then pcall(menu.ReinitializeAll, menu) end
        -- 刷新结果
        if storagePanel.catalogSearcher.RunSearch then storagePanel.catalogSearcher:RunSearch() end
        Debug("Force AllowedIndoors=true while bypass active")
    end
end

-- 判断是否应当把条目视作“有效”（用于取消灰显与提示）
local function ShouldForceValid(self)
    if not IsBypassActive() then return false end
    -- 仅在仓库视图生效
    if self.IsInStorageView and (not self:IsInStorageView()) then return false end
    local info = self.entryInfo or (self.GetEntryData and self:GetEntryData())
    if not info then return false end
    return (info.isAllowedIndoors and not info.isAllowedOutdoors)
end

-- 覆写 GetIsValid：在解禁+室外时，把“仅室内”条目标记为有效，从而取消灰显与错误行
local function EnsureGetIsValidBypass()
    if not (_G.HousingCatalogEntryMixin and not HousingCatalogEntryMixin._ADT_GetIsValidHooked) then return end
    local orig = HousingCatalogEntryMixin.GetIsValid
    if type(orig) ~= 'function' then return end
    HousingCatalogEntryMixin._ADT_OrigGetIsValid = orig
    function HousingCatalogEntryMixin:GetIsValid(...)
        local isValid, invalidTooltip, invalidError = orig(self, ...)
        if not isValid and ShouldForceValid(self) then
            return true, nil, nil
        end
        return isValid, invalidTooltip, invalidError
    end
    HousingCatalogEntryMixin._ADT_GetIsValidHooked = true
    Debug("Installed GetIsValid bypass")
end

-- 将“灰态但可点击抓取”的点击改道安装到当前可见的目录按钮上
local function SweepAndInstallClickBypass(scrollBox)
    if not (scrollBox and scrollBox.ForEachFrame) then return end
    if not IsBypassActive() then return end
    scrollBox:ForEachFrame(function(frame)
        local ed = frame.GetElementData and frame:GetElementData()
        if not ed or ed.templateKey ~= "CATALOG_ENTRY_DECOR" then return end

        -- 取到 entryInfo（官方模板在 Init/Update 后会挂载）
        local info = frame.entryInfo or (frame.GetEntryData and frame:GetEntryData())
        local rid = info and info.entryID and info.entryID.recordID
        if info and rid and info.isAllowedIndoors and not info.isAllowedOutdoors then
            -- 改道左键点击：直接用 recordID 抓取（单一权威）
            if not frame._ADT_OrigOnClick then frame._ADT_OrigOnClick = frame:GetScript("OnClick") end
            if not frame._ADT_BypassClickInstalled then
                frame:SetScript("OnClick", function(self, button)
                    if button == "RightButton" then
                        if self._ADT_OrigOnClick then self._ADT_OrigOnClick(self, button) end
                        return
                    end
                    local data = self.entryInfo or (self.GetEntryData and self:GetEntryData())
                    local recordID = data and data.entryID and data.entryID.recordID
                    BeginGrabByRecordID(recordID)
                end)
                frame._ADT_BypassClickInstalled = true
            end
            -- 视觉灰态由官方模板依据 GetIsValid 自动处理；此处不额外覆写。
        else
            -- 非目标条目：恢复原行为（如先前曾被安装改道）
            if frame._ADT_BypassClickInstalled and frame._ADT_OrigOnClick then
                frame:SetScript("OnClick", frame._ADT_OrigOnClick)
                frame._ADT_BypassClickInstalled = nil
            end
        end
    end)
end

-- 在 StoragePanel 可用时安装所有钩子
local function TryInstall()
    local hf = _G.HouseEditorFrame
    local sp = hf and hf.StoragePanel
    local oc = sp and sp.OptionsContainer
    local sb = oc and oc.ScrollBox
    if not sb then return false end

    if not sp._ADT_IndoorBypass_Hooked then
        -- 结果集更新：按需合并“室内-only补回”
        hooksecurefunc(sp, "OnEntryResultsUpdated", function(self)
            EnsureIndoorsFilterOn(self)
            local merged = BuildMergedEntries(self)
            if merged then
                -- 保持滚动位置（retain=true）
                self.OptionsContainer:SetCatalogData(merged, true)
                if self.OptionsContainer.RefreshFrames then self.OptionsContainer:RefreshFrames() end
            end
        end)
        sp._ADT_IndoorBypass_Hooked = true
    end

    if not sb._ADT_IndoorBypass_Sweep then
        hooksecurefunc(sb, "Update", function(box)
            SweepAndInstallClickBypass(box)
        end)
        -- 首帧也跑一次
        C_Timer.After(0, function() SweepAndInstallClickBypass(sb) end)
        sb._ADT_IndoorBypass_Sweep = true
    end

    return true
end

-- 外部触发：强制刷新一次（用于设置开关切换等）
function M.RefreshCatalog()
    local hf = _G.HouseEditorFrame
    local sp = hf and hf.StoragePanel
    if not sp then return end
    if not TryInstall() then return end
    if IsBypassActive() then
        EnsureIndoorsFilterOn(sp)
        local merged = BuildMergedEntries(sp)
        if merged then
            sp.OptionsContainer:SetCatalogData(merged, true)
        else
            -- 若没有补回项，则让官方自己刷新
            if sp.catalogSearcher and sp.catalogSearcher.RunSearch then sp.catalogSearcher:RunSearch() end
        end
    else
        -- 关闭解禁：还原官方列表
        if sp.catalogSearcher and sp.catalogSearcher.RunSearch then sp.catalogSearcher:RunSearch() end
    end
end

-- 事件驱动安装/刷新
function M:Init()
    local f = CreateFrame("Frame")
    f:RegisterEvent("HOUSE_EDITOR_MODE_CHANGED")
    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        C_Timer.After(0, function()
            EnsureGetIsValidBypass()
            if TryInstall() then M.RefreshCatalog() end
        end)
    end)

    -- 监听设置变化：开关改变即刷新一次
    if ADT.Settings and ADT.Settings.On then
        ADT.Settings.On("EnableIndoorOutdoorBypass", function()
            EnsureGetIsValidBypass()
            M.RefreshCatalog()
        end)
    end
end

M:Init()
