-- Housing_ClipboardCore.lua：临时板核心逻辑（ADT 独立实现）
-- 额外剪切板（可视化）：从“选集/悬停/当前选中”采集装饰，列表化保存；
-- 点击列表项即可进入放置（同最近放置的行为）。

local ADDON_NAME, ADT = ...
local L = ADT.L

local C_HousingDecor = C_HousingDecor
local C_HousingCatalog = C_HousingCatalog
local GetDecorInstanceInfoForGUID = C_HousingDecor and C_HousingDecor.GetDecorInstanceInfoForGUID
local GetAllPlacedDecor = C_HousingDecor and C_HousingDecor.GetAllPlacedDecor
local GetCatalogEntryInfoByRecordID = C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByRecordID

local IsHouseEditorActive = C_HouseEditor and C_HouseEditor.IsHouseEditorActive

local Clipboard = {}
ADT.Clipboard = Clipboard

-- 数据源：保存在 SavedVariables 的 ExtraClipboard 中
local function GetList()
    local t = ADT.GetDBValue("ExtraClipboard")
    if type(t) ~= "table" then
        t = {}
        ADT.SetDBValue("ExtraClipboard", t)
    end
    return t
end

-- 导出：获取/清空/删除
function Clipboard:GetAll()
    return GetList()
end

function Clipboard:Clear()
    local list = GetList(); wipe(list)
    if type(self.OnChanged) == 'function' then self:OnChanged() end
end

local CLEAR_POPUP_KEY = "ADT_CLEAR_CLIPBOARD"

local function EnsureClearPopup()
    if StaticPopupDialogs and StaticPopupDialogs[CLEAR_POPUP_KEY] then return end
    if not StaticPopupDialogs then return end
    StaticPopupDialogs[CLEAR_POPUP_KEY] = {
        text = L["Clear Clipboard Confirm"],
        button1 = L["Clear"],
        button2 = L["Cancel"],
        OnAccept = function()
            Clipboard:Clear()
            if ADT and ADT.Notify then
                ADT.Notify(L["Clipboard cleared"], 'success')
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function Clipboard:ClearWithConfirm()
    local list = GetList()
    if #list == 0 then
        if ADT and ADT.Notify then ADT.Notify(L["Clipboard is empty"], 'info') end
        return
    end
    EnsureClearPopup()
    if StaticPopup_Show then
        StaticPopup_Show(CLEAR_POPUP_KEY)
    end
end

function Clipboard:RemoveAt(index)
    local list = GetList()
    if type(index) == 'number' and index >=1 and index <= #list then
        table.remove(list, index)
        if type(self.OnChanged) == 'function' then self:OnChanged() end
    end
end

local function FindByDecorID(list, decorID)
    for i, v in ipairs(list) do
        if v.decorID == decorID then return i, v end
    end
end

-- 单一权威：统一的“写入/合并”逻辑，避免多处重复实现
local function UpsertItem(list, decorID, name, icon, count, opts)
    if not decorID then return nil end
    local n = count or 1
    local idx, item = FindByDecorID(list, decorID)
    local moveToTop = not (opts and opts.moveToTop == false)
    local insertAtTop = not (opts and opts.insertAtTop == false)

    if idx and item then
        item.count = (item.count or 1) + n
        if name then item.name = name end
        if icon then item.icon = icon end
        if moveToTop and idx ~= 1 then
            table.remove(list, idx)
            table.insert(list, 1, item)
        end
        return item
    end

    local insertIndex = insertAtTop and 1 or (#list + 1)
    local newItem = { decorID = decorID, name = name, icon = icon, count = n }
    table.insert(list, insertIndex, newItem)
    return newItem
end

function Clipboard:AddItem(decorID, name, icon, count)
    if not decorID then return end
    local list = GetList()
    local n = count or 1
    -- 作为“临时板”，最近加入的元素应当置顶
    UpsertItem(list, decorID, name, icon, n, { moveToTop = true, insertAtTop = true })
    if ADT and ADT.Notify and name then
        ADT.Notify(string.format(ADT.L["Added to clipboard: %s x%d"], name, n), 'success')
    end
    if type(self.OnChanged) == 'function' then self:OnChanged() end
end

-- 批量写入（导入/同步等场景）
-- @param items table: { {decorID=number, name=string|nil, icon=texture|nil, count=number|nil}, ... }
-- @param opts table|nil: { reset=true|false, insertAtTop=true|false, preserveOrder=true|false }
-- @return number: 成功处理的条目数
function Clipboard:AddBatch(items, opts)
    if type(items) ~= "table" then return 0 end
    local list = GetList()
    if opts and opts.reset then
        wipe(list)
    end

    local insertAtTop = not (opts and opts.insertAtTop == false)
    local preserveOrder = opts and opts.preserveOrder
    local count = 0

    if insertAtTop and preserveOrder then
        for i = #items, 1, -1 do
            local item = items[i]
            if item and item.decorID then
                UpsertItem(list, item.decorID, item.name, item.icon, item.count or 1, { moveToTop = true, insertAtTop = true })
                count = count + 1
            end
        end
    else
        for _, item in ipairs(items) do
            if item and item.decorID then
                UpsertItem(list, item.decorID, item.name, item.icon, item.count or 1, { moveToTop = insertAtTop, insertAtTop = insertAtTop })
                count = count + 1
            end
        end
    end

    if count > 0 and type(self.OnChanged) == 'function' then self:OnChanged() end
    return count
end

-- 从“当前选中”存入临时板并移除现实中的物体（Ctrl+S）
function Clipboard:StoreSelectedAndRemove()
    if not (IsHouseEditorActive and IsHouseEditorActive()) then return end
    if not ADT.Housing or not ADT.Housing.GetSelectedDecorRecordIDAndName then return end
    local id, name, icon = ADT.Housing:GetSelectedDecorRecordIDAndName()
    if not id then
        if ADT.Notify then ADT.Notify(ADT.L["Please select a decor to store"], 'info') end
        return
    end
    -- 尝试移除当前选中（由 Housing 模块提供单一权威的移除实现）
    if ADT.Housing and ADT.Housing.RemoveSelectedDecor then
        local ok = ADT.Housing:RemoveSelectedDecor()
        if not ok then
            if ADT.Notify then ADT.Notify(ADT.L["Cannot remove, check mode"], 'error') end
            return
        end
    end
    -- 移除成功后加入临时板置顶
    self:AddItem(id, name, icon, 1)
end

-- 从“当前选中”仅复制到临时板（不移除现实中的物体）
function Clipboard:StoreSelectedOnly()
    if not (IsHouseEditorActive and IsHouseEditorActive()) then return end
    if not ADT.Housing then return end
    local id, name, icon
    if ADT.Housing.GetHoveredDecorRecordIDAndName then
        id, name, icon = ADT.Housing:GetHoveredDecorRecordIDAndName()
    end
    if not id and ADT.Housing.GetSelectedDecorRecordIDAndName then
        id, name, icon = ADT.Housing:GetSelectedDecorRecordIDAndName()
    end
    if not id then
        if ADT.Notify then ADT.Notify(ADT.L["Please select a decor to store"], 'info') end
        return
    end
    self:AddItem(id, name, icon, 1)
end

-- 取出临时板最顶上的物体并开始放置（Ctrl+R）
function Clipboard:RecallTopStartPlacing()
    local list = GetList()
    if #list == 0 then
        if ADT and ADT.Notify then ADT.Notify(ADT.L["Clipboard is empty"], 'info') end
        return
    end
    local top = list[1]
    if top and top.decorID then
        self:StartPlacing(top.decorID)
    end
end

-- 计算当前库存数量（与历史相同口径）
function Clipboard:GetAvailableCount(decorID)
    local info = GetCatalogEntryInfoByRecordID and GetCatalogEntryInfoByRecordID(1, decorID, true)
    if info then
        return (info.quantity or 0) + (info.remainingRedeemable or 0)
    end
    return 0
end

-- 从剪切板进入放置：在放置成功后减少剪切板计数，计数为 0 则移除
Clipboard._placingDecorID = nil

-- 采集：悬停 / 当前选中（委托 Housing 模块提供的统一接口）
function Clipboard:AddFromHovered()
    if not (IsHouseEditorActive and IsHouseEditorActive()) then return end
    if not ADT.Housing or not ADT.Housing.GetHoveredDecorRecordIDAndName then return end
    local id, name, icon = ADT.Housing:GetHoveredDecorRecordIDAndName()
    if id then self:AddItem(id, name, icon, 1) else if ADT.Notify then ADT.Notify(ADT.L["No hovered decor"], 'info') end end
end

function Clipboard:AddFromSelected()
    if not (IsHouseEditorActive and IsHouseEditorActive()) then return end
    if not ADT.Housing or not ADT.Housing.GetSelectedDecorRecordIDAndName then return end
    local id, name, icon = ADT.Housing:GetSelectedDecorRecordIDAndName()
    if id then self:AddItem(id, name, icon, 1) else if ADT.Notify then ADT.Notify(ADT.L["No selected decor"], 'info') end end
end

-- 进入放置
function Clipboard:StartPlacing(decorID)
    if not (ADT and ADT.Housing and ADT.Housing.StartPlacingByRecordIDSafe) then return end
    -- 与历史一致：延后 0.05s，避免点击同帧触发“确认放置”
    C_Timer.After(0.05, function()
        ADT.Housing:StartPlacingByRecordIDSafe(decorID, {
            ensureBasic = true,
            switchDelay = 0.2,
            onResult = function(ok)
                if ok then
                    Clipboard._placingDecorID = decorID
                else
                    if ADT.Notify then ADT.Notify(ADT.L["Cannot start placing 2"], 'error') end
                end
            end,
        })
    end)
end

-- 事件监听：放置成功 & 仓库变化 时同步剪切板
local Watcher = CreateFrame("Frame")
Watcher:RegisterEvent("HOUSING_DECOR_PLACE_SUCCESS")
Watcher:RegisterEvent("HOUSING_STORAGE_UPDATED")
Watcher:RegisterEvent("HOUSING_STORAGE_ENTRY_UPDATED")
Watcher:RegisterEvent("HOUSE_DECOR_ADDED_TO_CHEST")
Watcher:RegisterEvent("HOUSING_DECOR_REMOVED")
Watcher:SetScript("OnEvent", function(_, event)
    if event == "HOUSING_DECOR_PLACE_SUCCESS" and Clipboard._placingDecorID then
        local list = GetList()
        local idx, item = FindByDecorID(list, Clipboard._placingDecorID)
        Clipboard._placingDecorID = nil
        if idx and item then
            item.count = math.max(0, (item.count or 1) - 1)
            if item.count <= 0 then
                table.remove(list, idx)
            end
            if type(Clipboard.OnChanged) == 'function' then Clipboard:OnChanged() end
        end
    else
        -- 其他与库存相关的事件：仅刷新展示，不清理临时板条目
        if type(Clipboard.OnChanged) == 'function' then Clipboard:OnChanged() end
    end
end)

-- UI 迁移到 ClipboardPopup；此处保留后备入口
function Clipboard:Toggle()
    -- 弹窗已彻底移除；改为打开 Dock 并切换到“临时板”分类
    local Main = ADT and ADT.CommandDock and ADT.CommandDock.SettingsPanel
    if not Main then return end
    if Main:IsShown() and Main.currentDecorCategory == 'Clipboard' then
        Main:Hide(); return
    end
    local mode = (HouseEditorFrame and HouseEditorFrame:IsShown()) and "editor" or "standalone"
    Main:ShowUI(mode)
    if Main.ShowDecorListCategory then Main:ShowDecorListCategory('Clipboard') end
end

-- 启动提示命令
SLASH_ADTCB1 = "/adtcb"
SlashCmdList["ADTCB"] = function(msg)
    local sub = (msg or ""):lower()
    if sub == "hov" then Clipboard:AddFromHovered(); return end
    if sub == "cur" then Clipboard:AddFromSelected(); return end
    Clipboard:Toggle()
end
