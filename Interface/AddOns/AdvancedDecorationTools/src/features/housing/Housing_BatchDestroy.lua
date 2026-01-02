-- Housing_BatchDestroy.lua
-- 功能：批量摧毁指定数量的装饰品
-- 原理：暴雪 API 仅支持 DestroyEntry(entryID, destroyAll)，无法指定数量，
--       本模块通过循环调用 + 延迟防节流实现"摧毁 N 个"。

local ADDON_NAME, ADT = ...
if not ADT then return end

local L = ADT.L or function(k) return k end
ADT.BatchDestroy = ADT.BatchDestroy or {}
local BatchDestroy = ADT.BatchDestroy

-- ============ 配置 ============
local CONFIG = {
    DELAY_PER_DESTROY = 0.5,   -- 每次摧毁间隔（秒），防止服务器节流
    MAX_BATCH_SIZE = 100,       -- 单次批量上限，避免误操作
}

-- ============ 状态 ============
local isDestroying = false
local destroyQueue = {}
local currentCallback = nil

-- ============ 工具函数 ============
local function CanDestroyEntry(entryID)
    if not entryID then return false end
    if C_HousingCatalog and C_HousingCatalog.CanDestroyEntry then
        return C_HousingCatalog.CanDestroyEntry(entryID)
    end
    return false
end

local function GetEntryInfo(entryID)
    if not entryID then return nil end
    if C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfo then
        return C_HousingCatalog.GetCatalogEntryInfo(entryID)
    end
    return nil
end

-- ============ 核心逻辑 ============

-- 安全执行单次摧毁，带延迟递归
local function ProcessDestroyQueue()
    if #destroyQueue == 0 then
        isDestroying = false
        if currentCallback then
            currentCallback(true, L["Batch destroy completed"])
            currentCallback = nil
        end
        return
    end

    local entry = table.remove(destroyQueue, 1)
    local entryID = entry.entryID
    local current = entry.total - #destroyQueue

    -- 执行摧毁（不再每次检查 CanDestroyEntry，开始时已验证）
    if ADT.DebugPrint then
        ADT.DebugPrint(string.format("[BatchDestroy] 摧毁 %d/%d, entryID=%s", current, entry.total, tostring(entryID)))
    end
    
    C_HousingCatalog.DestroyEntry(entryID, false)  -- destroyAll = false

    -- 更新进度
    if entry.onProgress then
        entry.onProgress(current, entry.total)
    end

    -- 延迟处理下一个（增加到 0.3s 给暴雪足够时间更新状态）
    C_Timer.After(CONFIG.DELAY_PER_DESTROY, ProcessDestroyQueue)
end

--- 批量摧毁指定数量的装饰品
-- @param entryID HousingCatalogEntryID 装饰品 ID
-- @param count number 要摧毁的数量
-- @param callbacks table|nil { onProgress = func(current, total), onComplete = func(success, message) }
-- @return boolean 是否成功开始
function BatchDestroy:Start(entryID, count, callbacks)
    if isDestroying then
        if ADT.Notify then ADT.Notify(L["Batch destroy in progress"], "warning") end
        return false
    end

    -- 验证参数
    if not entryID then
        if ADT.Notify then ADT.Notify(L["Invalid decor ID"], "error") end
        return false
    end

    local info = GetEntryInfo(entryID)
    if not info then
        if ADT.Notify then ADT.Notify(L["Cannot get decor info"], "error") end
        return false
    end

    if not CanDestroyEntry(entryID) then
        if ADT.Notify then ADT.Notify(L["This decor cannot be destroyed"], "error") end
        return false
    end

    local available = info.quantity or 0
    local toDestroy = math.min(count, available, CONFIG.MAX_BATCH_SIZE)

    if toDestroy <= 0 then
        if ADT.Notify then ADT.Notify(L["Nothing to destroy"], "warning") end
        return false
    end

    -- 构建队列
    wipe(destroyQueue)
    for i = 1, toDestroy do
        table.insert(destroyQueue, {
            entryID = entryID,
            total = toDestroy,
            onProgress = callbacks and callbacks.onProgress,
        })
    end

    isDestroying = true
    currentCallback = callbacks and callbacks.onComplete

    if ADT.Notify then
        ADT.Notify(string.format(L["Starting to destroy %d items..."], toDestroy), "info")
    end

    -- 开始处理
    ProcessDestroyQueue()
    return true
end

--- 取消正在进行的批量摧毁
function BatchDestroy:Cancel()
    if not isDestroying then return end
    wipe(destroyQueue)
    isDestroying = false
    if currentCallback then
        currentCallback(false, L["Batch destroy cancelled"])
        currentCallback = nil
    end
    if ADT.Notify then ADT.Notify(L["Batch destroy cancelled"], "info") end
end

--- 检查是否正在摧毁
function BatchDestroy:IsProcessing()
    return isDestroying
end

-- ============ 弹窗 UI ============
local POPUP_KEY = "ADT_BATCH_DESTROY"

-- 当前弹窗上下文（使用闭包捕获）
local currentPopupData = nil

local function InitPopup()
    if StaticPopupDialogs and StaticPopupDialogs[POPUP_KEY] then return end
    if not StaticPopupDialogs then return end

    StaticPopupDialogs[POPUP_KEY] = {
        text = L["Enter the quantity to destroy (Current stock: %d)"],
        button1 = ACCEPT,
        button2 = CANCEL,
        hasEditBox = true,
        maxLetters = 5,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        exclusive = true,

        OnShow = function(self)
            local editBox = self.editBox or _G[self:GetName() .. "EditBox"]
            if editBox then
                editBox:SetText("")
                editBox:SetFocus()
            end
            self.button1:Disable()
        end,

        OnAccept = function(self)
            local editBox = self.editBox or _G[self:GetName() .. "EditBox"]
            local count = editBox and tonumber(editBox:GetText()) or 0
            
            if count > 0 and currentPopupData and currentPopupData.entryID then
                BatchDestroy:Start(currentPopupData.entryID, count, {
                    onComplete = function(success, msg)
                        if ADT.Notify then ADT.Notify(msg, success and "success" or "error") end
                    end
                })
            end
            currentPopupData = nil
        end,

        OnCancel = function(self)
            currentPopupData = nil
        end,

        OnHide = function(self)
            currentPopupData = nil
        end,

        EditBoxOnTextChanged = function(self)
            local parent = self:GetParent()
            local text = self:GetText()
            local num = tonumber(text)
            local max = currentPopupData and currentPopupData.maxCount or 0

            if num and num > 0 and num <= max then
                parent.button1:Enable()
            else
                parent.button1:Disable()
            end
        end,

        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            if parent.button1:IsEnabled() then
                parent.button1:Click()
            end
        end,

        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
    }
end

--- 显示批量摧毁弹窗
-- @param entryID HousingCatalogEntryID
-- @param entryInfo table|nil 装饰品信息（可选，会自动获取）
function BatchDestroy:ShowDialog(entryID, entryInfo)
    InitPopup()

    local info = entryInfo or GetEntryInfo(entryID)
    if not info then
        if ADT.Notify then ADT.Notify(L["Cannot get decor info"], "error") end
        return
    end

    local maxCount = info.quantity or 0
    if maxCount <= 0 then
        if ADT.Notify then ADT.Notify(L["No stock to destroy"], "warning") end
        return
    end

    -- 保存上下文数据到模块级变量（闭包捕获）
    currentPopupData = {
        entryID = entryID,
        maxCount = maxCount,
        name = info.name or L["Unknown"],
    }

    StaticPopup_Show(POPUP_KEY, maxCount)
end

-- ============ Hook 原生右键菜单 ============

local function InjectContextMenu()
    -- 使用 Menu.ModifyMenu 在暴雪原生菜单上追加选项
    -- 参考 Housing_Tags.lua 的实现方式
    if not Menu or not Menu.ModifyMenu then
        if ADT.DebugPrint then
            ADT.DebugPrint("[BatchDestroy] Menu API 不可用，跳过菜单注入")
        end
        return
    end
    
    Menu.ModifyMenu("MENU_HOUSING_CATALOG_ENTRY", function(owner, rootDescription, contextData)
        -- 获取条目信息
        local entryInfo = owner and owner.entryInfo
        if not entryInfo then return end
        
        local entryID = owner.entryID
        if not entryID then return end
        
        local quantity = entryInfo.quantity or 0
        
        -- 只对库存 > 1 的装饰显示
        if quantity <= 1 then return end
        
        -- 检查是否可摧毁
        if not CanDestroyEntry(entryID) then return end
        
        -- 只在存储视图显示（非 Market 视图）
        if owner.IsInMarketView and owner:IsInMarketView() then return end
        
        -- 添加分隔线和"摧毁指定数量"按钮
        rootDescription:CreateDivider()
        rootDescription:CreateButton(L["Destroy specific quantity..."], function()
            BatchDestroy:ShowDialog(entryID, entryInfo)
        end)
    end)
    
    if ADT.DebugPrint then
        ADT.DebugPrint("[BatchDestroy] 右键菜单注入完成（使用 Menu.ModifyMenu）")
    end
end

-- ============ 初始化 ============

local Loader = CreateFrame("Frame")
Loader:RegisterEvent("ADDON_LOADED")
Loader:SetScript("OnEvent", function(self, event, addonName)
    if addonName == ADDON_NAME then
        InitPopup()
        -- 延迟注入右键菜单（确保暴雪 Menu API 已加载）
        C_Timer.After(0.5, InjectContextMenu)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- 导出给其他模块使用
ADT.BatchDestroy = BatchDestroy
