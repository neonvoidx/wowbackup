-- Housing_ExportImport.lua：装饰清单导出/导入核心模块
-- 功能：
-- 1. 导出当前放置清单（recordID + 数量）
-- 2. 导出临时板内容
-- 3. 导入至临时板（解析压缩字符串）

local ADDON_NAME, ADT = ...
local L = ADT.L

local C_HouseEditor = C_HouseEditor
local C_HousingDecor = C_HousingDecor
local C_HousingCatalog = C_HousingCatalog
local GetDecorInstanceInfoForGUID = C_HousingDecor and C_HousingDecor.GetDecorInstanceInfoForGUID
local GetCatalogEntryInfoByRecordID = C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByRecordID
local IsHouseEditorActive = C_HouseEditor and C_HouseEditor.IsHouseEditorActive
local DECOR_ENTRY_TYPE = Enum and Enum.HousingCatalogEntryType and Enum.HousingCatalogEntryType.Decor

-- 导出格式（ADT v2）
-- 字符串格式：
--   ADT:<payload>
-- payload = EncodeForPrint(Deflate("v=2|t=placed|ts=...|e=...|a=..."))
local EXPORT_PREFIX = "ADT"
local EXPORT_VERSION = 2
local EXPORT_TYPES = {
    placed = true,
    clipboard = true,
}

-- ============================================================================
-- LibDeflate 加载（内嵌或共享）
-- ============================================================================
local LibDeflate
do
    -- 尝试从 LibStub 获取共享版本
    if LibStub then
        local ok, lib = pcall(LibStub.GetLibrary, LibStub, "LibDeflate", true)
        if ok and lib then
            LibDeflate = lib
        end
    end
    -- 回退：使用全局表（由 libs/LibDeflate.lua 注册）
    if not LibDeflate and _G.LibDeflate then
        LibDeflate = _G.LibDeflate
    end
end

-- ============================================================================
-- v2 payload 编解码
-- ============================================================================
local function IsPositiveInt(n)
    return type(n) == "number" and n > 0 and n % 1 == 0
end

local function URLEncode(str)
    return (tostring(str or ""):gsub("([^%w%._%-])", function(ch)
        return string.format("%%%02X", string.byte(ch))
    end))
end

local function URLDecode(str)
    return (tostring(str or ""):gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end))
end

local function JSONEscape(str)
    return (str:gsub("[\"\\%z\1-\31]", function(ch)
        local byte = string.byte(ch)
        if ch == "\"" then return "\\\"" end
        if ch == "\\" then return "\\\\" end
        if ch == "\b" then return "\\b" end
        if ch == "\f" then return "\\f" end
        if ch == "\n" then return "\\n" end
        if ch == "\r" then return "\\r" end
        if ch == "\t" then return "\\t" end
        return string.format("\\u%04X", byte)
    end))
end

local function EncodeJSON(value)
    local t = type(value)
    if t == "nil" then
        return "null"
    end
    if t == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return "null"
        end
        return tostring(value)
    end
    if t == "boolean" then
        return value and "true" or "false"
    end
    if t == "string" then
        return "\"" .. JSONEscape(value) .. "\""
    end
    if t == "table" then
        local isArray = true
        local maxIndex = 0
        for k in pairs(value) do
            if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
                isArray = false
                break
            end
            if k > maxIndex then maxIndex = k end
        end
        if isArray then
            for i = 1, maxIndex do
                if value[i] == nil then
                    isArray = false
                    break
                end
            end
        end
        if isArray then
            local parts = {}
            for i = 1, maxIndex do
                parts[#parts + 1] = EncodeJSON(value[i])
            end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        local keys = {}
        for k in pairs(value) do
            if type(k) == "string" then
                keys[#keys + 1] = k
            end
        end
        table.sort(keys)
        local parts = {}
        for i = 1, #keys do
            local k = keys[i]
            parts[#parts + 1] = "\"" .. JSONEscape(k) .. "\":" .. EncodeJSON(value[k])
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "null"
end

local function BuildEntriesString(entries)
    local parts = {}
    for i = 1, #entries do
        local entry = entries[i]
        if type(entry) ~= "table" then
            return nil, L["Invalid data structure"]
        end
        local recordID = entry[1]
        local count = entry[2]
        if not IsPositiveInt(recordID) then
            return nil, L["Invalid data structure"]
        end
        if count == nil then
            count = 1
        end
        if not IsPositiveInt(count) then
            return nil, L["Invalid data structure"]
        end
        if count == 1 then
            parts[#parts + 1] = tostring(recordID)
        else
            parts[#parts + 1] = recordID .. "," .. count
        end
    end
    return table.concat(parts, ";")
end

local function BuildPayload(exportData)
    if type(exportData) ~= "table" then
        return nil, L["Invalid data structure"]
    end
    local v = exportData.v
    if not IsPositiveInt(v) then
        return nil, L["Invalid data structure"]
    end
    local exportType = exportData.t
    if not EXPORT_TYPES[exportType] then
        return nil, L["Invalid export type"]
    end
    local ts = exportData.ts
    if not IsPositiveInt(ts) then
        return nil, L["Invalid data structure"]
    end
    local entries = exportData.e
    if type(entries) ~= "table" then
        return nil, L["Invalid data structure"]
    end

    local entryStr, err = BuildEntriesString(entries)
    if not entryStr then
        return nil, err
    end

    local parts = {
        "v=" .. v,
        "t=" .. exportType,
        "ts=" .. ts,
        "e=" .. entryStr,
    }

    if exportData.a ~= nil then
        if type(exportData.a) ~= "string" then
            return nil, L["Invalid data structure"]
        end
        parts[#parts + 1] = "a=" .. URLEncode(exportData.a)
    end

    return table.concat(parts, "|")
end

local function ParseEntriesString(entriesPart)
    if entriesPart == "" then
        return nil, L["Invalid data structure"]
    end
    local entries = {}
    for token in string.gmatch(entriesPart, "([^;]+)") do
        local idStr, countStr = token:match("^(%d+),(%d+)$")
        local recordID
        local count
        if idStr then
            recordID = tonumber(idStr)
            count = tonumber(countStr)
        else
            idStr = token:match("^(%d+)$")
            if not idStr then
                return nil, L["Invalid data structure"]
            end
            recordID = tonumber(idStr)
            count = 1
        end
        if not IsPositiveInt(recordID) or not IsPositiveInt(count) then
            return nil, L["Invalid data structure"]
        end
        entries[#entries + 1] = { recordID, count }
    end
    return entries
end

local function ParsePayload(payload)
    if type(payload) ~= "string" or payload == "" then
        return nil, L["Invalid data structure"]
    end
    local map = {}
    for seg in string.gmatch(payload, "([^|]+)") do
        local k, v = seg:match("^([^=]+)=(.*)$")
        if not k then
            return nil, L["Invalid data structure"]
        end
        map[k] = v
    end

    local v = tonumber(map.v)
    if not IsPositiveInt(v) then
        return nil, L["Invalid data structure"]
    end
    if v ~= EXPORT_VERSION then
        return nil, string.format(L["Unsupported version detail"], v, EXPORT_VERSION)
    end
    local exportType = map.t
    if not EXPORT_TYPES[exportType] then
        return nil, L["Invalid export type"]
    end
    local ts = tonumber(map.ts)
    if not IsPositiveInt(ts) then
        return nil, L["Invalid data structure"]
    end
    local entriesPart = map.e or ""
    local entries, err = ParseEntriesString(entriesPart)
    if not entries then
        return nil, err
    end

    local adtPayload
    if map.a and map.a ~= "" then
        adtPayload = URLDecode(map.a)
    end

    return {
        v = v,
        ts = ts,
        t = exportType,
        e = entries,
        a = adtPayload,
    }
end

local EXPORT_SETTINGS_KEYS = {
    "EnableDupe",
    "EnableCopy",
    "EnableCut",
    "EnablePaste",
    "EnableBatchPlace",
    "EnableResetT",
    "EnableResetAll",
    "EnableLock",
    "EnableDyeCopy",
    "EnableHoverHighlight",
    "EnableProtection",
    "EnableIndoorOutdoorBypass",
    "EnableQERotate",
    "DuplicateKey",
    "EnableAutoRotateOnCtrlPlace",
    "AutoRotateMode",
    "AutoRotatePresetDegrees",
    "AutoRotateSequence",
    "AutoRotateApplyScope",
    "AutoRotateStepDegrees",
    "AutoRotateIncrementDegrees",
    "EnableIncrementRotate",
    "IncrementRotateDegrees",
    "EnablePulseRotate",
    "ExpertPulseDegrees",
    "EnableDockAutoOpenInEditor",
    "EnableQuickbar",
    "QuickbarSize",
    "InterfaceStyle",
    "SelectedLanguage",
    "VisitAutoRemoveFriend",
    "VisitFriendWaitSec",
}

local function GetAddonVersion()
    local ver
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        ver = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
    elseif GetAddOnMetadata then
        ver = GetAddOnMetadata(ADDON_NAME, "Version")
    end
    return ver
end

local function BuildMetaInfo()
    local meta = {}
    local ver = GetAddonVersion()
    if ver and ver ~= "" then
        meta.adtVersion = ver
    end
    if GetBuildInfo then
        local wv, wb, wd, wt = GetBuildInfo()
        if wv and wv ~= "" then meta.wowVersion = wv end
        if wb and wb ~= "" then meta.wowBuild = wb end
        if wd and wd ~= "" then meta.wowBuildDate = wd end
        if wt then meta.wowToc = wt end
    end
    if GetLocale then
        local loc = GetLocale()
        if loc and loc ~= "" then meta.locale = loc end
    end
    if next(meta) then return meta end
    return nil
end

local function BuildSettingsExport()
    if not ADT or not ADT.GetDBValue then return nil end
    local out = {}
    for i = 1, #EXPORT_SETTINGS_KEYS do
        local key = EXPORT_SETTINGS_KEYS[i]
        local v = ADT.GetDBValue(key)
        local t = type(v)
        if v ~= nil and (t == "boolean" or t == "number" or t == "string") then
            out[key] = v
        end
    end
    if next(out) then return out end
    return nil
end

local function BuildKeybindsExport()
    if not ADT or not ADT.GetDBValue then return nil end
    local db = ADT.GetDBValue("Keybinds")
    if type(db) ~= "table" then return nil end
    local out = {}
    for k, v in pairs(db) do
        if type(k) == "string" and type(v) == "string" then
            out[k] = v
        end
    end
    if next(out) then return out end
    return nil
end

local function BuildQuickbarExport()
    if not ADT or not ADT.GetDBValue then return nil end
    local db = ADT.GetDBValue("Quickbar")
    if type(db) ~= "table" then return nil end
    local out = {}
    local has = false
    for i = 1, 8 do
        local slot = db[i]
        local rid = slot and slot.recordID
        if IsPositiveInt(rid) then
            out[i] = rid
            has = true
        else
            out[i] = 0
        end
    end
    if not has then return nil end
    return out
end

local function BuildRecentExport()
    if not ADT or not ADT.GetDBValue then return nil end
    local db = ADT.GetDBValue("PlacementHistory")
    if type(db) ~= "table" then return nil end
    local out = {}
    for _, item in ipairs(db) do
        local rid = item and item.decorID
        if IsPositiveInt(rid) then
            out[#out + 1] = rid
        end
    end
    if #out == 0 then return nil end
    return out
end

local function BuildExtraClipboardExport()
    if not ADT or not ADT.GetDBValue then return nil end
    local db = ADT.GetDBValue("ExtraClipboard")
    if type(db) ~= "table" then return nil end
    local out = {}
    for _, item in ipairs(db) do
        local rid = item and item.decorID
        if IsPositiveInt(rid) then
            local count = item.count
            if not IsPositiveInt(count) then
                count = 1
            end
            out[#out + 1] = { rid, count }
        end
    end
    if #out == 0 then return nil end
    return out
end

local function CopyDockPos(pos)
    if type(pos) ~= "table" or not pos.point then return nil end
    return {
        point = pos.point,
        rel = pos.rel,
        relPoint = pos.relPoint,
        x = pos.x,
        y = pos.y,
    }
end

local function CopyDockSize(sz)
    if type(sz) ~= "table" or not sz.w or not sz.h then return nil end
    return { w = sz.w, h = sz.h }
end

local function BuildDockExport()
    if not ADT or not ADT.GetDBValue then return nil end
    local dock = {}
    local pos = CopyDockPos(ADT.GetDBValue("SettingsPanelPos"))
    if pos then dock.pos = pos end
    local size = CopyDockSize(ADT.GetDBValue("SettingsPanelSize"))
    if size then dock.size = size end
    local collapsed = ADT.GetDBValue("DockCollapsed")
    if collapsed ~= nil then dock.collapsed = not not collapsed end
    local lastCategory = ADT.GetDBValue("LastCategoryKey")
    if lastCategory ~= nil then dock.lastCategory = lastCategory end
    if next(dock) then return dock end
    return nil
end

local function BuildADTExportPayload()
    if not ADT or not ADT.GetDBValue then return nil end
    local adt = {}
    local meta = BuildMetaInfo()
    if meta then adt.meta = meta end
    local settings = BuildSettingsExport()
    if settings then adt.settings = settings end
    local keybinds = BuildKeybindsExport()
    if keybinds then adt.keybinds = keybinds end
    local quickbar = BuildQuickbarExport()
    if quickbar then adt.quickbar = quickbar end
    local recent = BuildRecentExport()
    if recent then adt.recent = recent end
    local extraClipboard = BuildExtraClipboardExport()
    if extraClipboard then adt.extraClipboard = extraClipboard end
    local dock = BuildDockExport()
    if dock then adt.dock = dock end
    if not next(adt) then return nil end
    return EncodeJSON(adt)
end

-- ============================================================================
-- 导出模块
-- ============================================================================
local ExportImport = {}
ADT.ExportImport = ExportImport

local function GetPlacedDecorListFrame()
    local hf = _G.HouseEditorFrame
    if not hf then return nil end
    if hf.activeModeFrame and hf.activeModeFrame.PlacedDecorList then
        return hf.activeModeFrame.PlacedDecorList
    end
    if hf.ExpertDecorModeFrame and hf.ExpertDecorModeFrame.PlacedDecorList then
        return hf.ExpertDecorModeFrame.PlacedDecorList
    end
    return nil
end

local function GetPlacedListDataProvider(list)
    if not (list and list.ScrollBox and list.ScrollBox.GetDataProvider) then
        return nil
    end
    return list.ScrollBox:GetDataProvider()
end

local function IsPlacedListOpen(list)
    return list and list.IsShown and list:IsShown()
end

local function IsPlacedListReady(list)
    return IsPlacedListOpen(list) and GetPlacedListDataProvider(list) ~= nil
end

local function CollectPlacedListEntriesFromUI()
    local list = GetPlacedDecorListFrame()
    if not IsPlacedListReady(list) then
        return nil, L["Placed list not ready"]
    end
    local dp = GetPlacedListDataProvider(list)
    local entries = {}
    if dp.ForEach then
        dp:ForEach(function(entry)
            entries[#entries + 1] = entry
        end)
    elseif dp.Enumerate then
        for _, entry in dp:Enumerate() do
            entries[#entries + 1] = entry
        end
    else
        return nil, L["Placed list not ready"]
    end

    if #entries == 0 then
        return nil, L["No placed decorations"]
    end
    return entries
end

--- 获取当前房屋已放置装饰列表
--- @return table: { {recordID=number, count=number}, ... }
function ExportImport:GetPlacedDecorList()
    if not GetDecorInstanceInfoForGUID then
        return nil, L["API not available"]
    end
    if IsHouseEditorActive and not IsHouseEditorActive() then
        return nil, L["Not in house editor"]
    end
    
    local placedList, err = CollectPlacedListEntriesFromUI()
    if not placedList then
        return nil, err
    end
    
    -- 统计每个 recordID 的数量（API 字段名为 decorID）
    local decorCounts = {}
    for _, entry in ipairs(placedList) do
        local guid = entry.decorGUID
        if guid then
            local info = GetDecorInstanceInfoForGUID(guid)
            if info and info.decorID then
                decorCounts[info.decorID] = (decorCounts[info.decorID] or 0) + 1
            end
        end
    end
    
    -- 转换为数组格式
    local result = {}
    for decorID, count in pairs(decorCounts) do
        result[#result + 1] = { decorID, count }
    end
    
    -- 按 decorID 排序
    table.sort(result, function(a, b) return a[1] < b[1] end)
    
    return result
end

--- 获取临时板内容
--- @return table: { {recordID=number, count=number}, ... }
function ExportImport:GetClipboardList()
    if not ADT.Clipboard or not ADT.Clipboard.GetAll then
        return nil, L["Clipboard not available"]
    end
    
    local clipboardData = ADT.Clipboard:GetAll()
    if not clipboardData or #clipboardData == 0 then
        return nil, L["Clipboard is empty"]
    end
    
    local result = {}
    for _, item in ipairs(clipboardData) do
        if item.decorID then
            result[#result + 1] = { item.decorID, item.count or 1 }
        end
    end
    
    return result
end

--- 构建导出数据
--- @param exportType string: "placed" | "clipboard"
--- @return table: 导出数据，或 nil + 错误信息
function ExportImport:BuildExportData(exportType)
    local entries, err
    if exportType == "placed" then
        entries, err = self:GetPlacedDecorList()
    elseif exportType == "clipboard" then
        entries, err = self:GetClipboardList()
    else
        return nil, L["Invalid export type"]
    end
    
    if not entries then
        return nil, err
    end
    local adtPayload = BuildADTExportPayload()
    return {
        v = EXPORT_VERSION,
        ts = time(),
        t = exportType,
        e = entries,
        a = adtPayload,
    }
end

--- 序列化并编码导出数据
--- @param exportData table
--- @return string: 压缩后的导出字符串，或 nil + 错误信息
function ExportImport:EncodeExportData(exportData)
    if not LibDeflate then
        return nil, L["LibDeflate not loaded"]
    end
    if not exportData then
        return nil, L["Invalid data structure"]
    end
    
    -- 构建 payload
    local payload, perr = BuildPayload(exportData)
    if not payload then
        return nil, perr
    end
    
    -- 压缩
    local compressed = LibDeflate:CompressDeflate(payload, { level = 9 })
    if not compressed then
        return nil, L["Compression failed"]
    end
    
    -- 编码为可打印字符
    local encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then
        return nil, L["Encoding failed"]
    end
    
    -- 添加前缀
    return EXPORT_PREFIX .. ":" .. encoded
end

--- 生成导出字符串
--- @param exportType string: "placed" | "clipboard"
--- @return string: 压缩后的导出字符串，或 nil + 错误信息
function ExportImport:GenerateExportString(exportType)
    local exportData, err = self:BuildExportData(exportType)
    if not exportData then
        return nil, err
    end
    return self:EncodeExportData(exportData)
end

--- 解析导入字符串
-- @param importString string: 导出字符串
-- @return table: 导入数据，或 nil + 错误信息
function ExportImport:ParseImportString(importString)
    if not LibDeflate then
        return nil, L["LibDeflate not loaded"]
    end
    
    if not importString or importString == "" then
        return nil, L["Empty import string"]
    end
    
    -- 移除首尾空白
    importString = importString:match("^%s*(.-)%s*$")
    
    -- 检查前缀
    local prefix, payload = importString:match("^(%u+):(.+)$")
    if not prefix or prefix ~= EXPORT_PREFIX then
        return nil, L["Invalid format prefix"]
    end
    
    -- 解码
    local decoded = LibDeflate:DecodeForPrint(payload)
    if not decoded then
        return nil, L["Decoding failed"]
    end
    
    -- 解压
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return nil, L["Decompression failed"]
    end

    local data, perr = ParsePayload(decompressed)
    if not data then
        return nil, perr
    end
    return data
end

--- 导入到临时板
-- @param importString string: 导出字符串
-- @param mode string: "replace" | "merge" (默认 merge)
-- @return number: 成功导入的条目数，或 nil + 错误信息
function ExportImport:ImportToClipboard(importString, mode)
    local data, err = self:ParseImportString(importString)
    if not data then
        return nil, err
    end
    
    if not data.e or type(data.e) ~= "table" then
        return nil, L["Invalid data structure"]
    end
    
    if not ADT.Clipboard or not ADT.Clipboard.AddBatch then
        return nil, L["Clipboard not available"]
    end
    
    mode = mode or "merge"
    local items = {}
    for _, entry in ipairs(data.e) do
        local recordID = entry[1]
        local itemCount = entry[2] or 1
        
        if recordID then
            -- 尝试获取装饰信息
            local info
            if GetCatalogEntryInfoByRecordID and DECOR_ENTRY_TYPE then
                info = GetCatalogEntryInfoByRecordID(
                    DECOR_ENTRY_TYPE,
                    recordID,
                    true
                )
            end
            
            local name = info and info.name or (L["Unknown"] .. " #" .. recordID)
            local icon = info and (info.iconTexture or info.iconAtlas) or nil
            
            items[#items + 1] = {
                decorID = recordID,
                name = name,
                icon = icon,
                count = itemCount,
            }
        end
    end
    
    local count = ADT.Clipboard:AddBatch(items, {
        reset = (mode == "replace"),
        insertAtTop = true,
        preserveOrder = true,
    })
    
    return count
end

--- 获取导入预览信息
-- @param importString string: 导出字符串
-- @return table: 预览数据，或 nil + 错误信息
function ExportImport:GetImportPreview(importString)
    local data, err = self:ParseImportString(importString)
    if not data then
        return nil, err
    end
    
    if not data.e or type(data.e) ~= "table" then
        return nil, L["Invalid data structure"]
    end
    
    local preview = {
        version = data.v,
        timestamp = data.ts,
        exportType = data.t,
        items = {},
        totalItems = #data.e,
        availableItems = 0,
        unavailableItems = 0,
    }
    
    for _, entry in ipairs(data.e) do
        local decorID = entry[1]
        local count = entry[2] or 1
        
        local info
        local available = 0
        if GetCatalogEntryInfoByRecordID and DECOR_ENTRY_TYPE then
            info = GetCatalogEntryInfoByRecordID(
                DECOR_ENTRY_TYPE,
                decorID,
                true
            )
            if info then
                available = (info.quantity or 0) + (info.remainingRedeemable or 0)
            end
        end
        
        local itemInfo = {
            decorID = decorID,
            name = info and info.name or (L["Unknown"] .. " #" .. decorID),
            icon = info and (info.iconTexture or info.iconAtlas) or nil,
            count = count,
            available = available,
            hasStock = available > 0,
        }
        
        preview.items[#preview.items + 1] = itemInfo
        
        if available > 0 then
            preview.availableItems = preview.availableItems + 1
        else
            preview.unavailableItems = preview.unavailableItems + 1
        end
    end
    
    return preview
end

-- ============================================================================
-- 导入/导出 UI
-- ============================================================================
local function GetDialogParent()
    return (HouseEditorFrame and HouseEditorFrame:IsShown()) and HouseEditorFrame or UIParent
end

local function UpdateDialogParent(frame)
    if not frame or not frame.SetParent then return end
    local parent = GetDialogParent()
    if frame:GetParent() ~= parent then
        frame:SetParent(parent)
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", parent, "CENTER")
    end
end

local function CreateMultiLineEditBox(scrollFrame, onEscape)
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetMaxBytes(0)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetScript("OnEscapePressed", function()
        if onEscape then onEscape() end
    end)
    editBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    editBox:SetScript("OnMouseUp", function(self)
        self:HighlightText()
    end)
    scrollFrame:SetScrollChild(editBox)

    scrollFrame:SetScript("OnSizeChanged", function(self, width, height)
        if editBox then
            editBox:SetSize(width, height)
        end
    end)
    C_Timer.After(0, function()
        if editBox and scrollFrame and scrollFrame.GetWidth then
            editBox:SetSize(scrollFrame:GetWidth(), scrollFrame:GetHeight())
        end
    end)

    return editBox
end

local function EnsureDialog()
    if ExportImport._dialog and ExportImport._dialog.SetParent then
        return ExportImport._dialog
    end

    local frame = CreateFrame("Frame", "ADT_ExportImportFrame", GetDialogParent(), "BasicFrameTemplateWithInset")
    frame:SetSize(540, 360)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetToplevel(true)

    if frame.TitleText then
        frame.TitleText:SetText(L["Clipboard Import/Export"])
    end

    local info = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    info:SetPoint("TOP", 0, -30)
    frame.info = info

    local sub = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetPoint("TOP", 0, -48)
    sub:SetTextColor(0.7, 0.7, 0.7)
    frame.sub = sub

    -- Export ScrollFrame
    local exportScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    exportScroll:SetPoint("TOPLEFT", 12, -74)
    exportScroll:SetPoint("BOTTOMRIGHT", -30, 70)
    frame.exportScroll = exportScroll
    frame.exportBox = CreateMultiLineEditBox(exportScroll, function() frame:Hide() end)
    frame.exportBox:SetScript("OnTextChanged", function(self)
        if not self.ignoreTextChanged then
            self:HighlightText()
            self.ignoreTextChanged = true
        end
    end)

    -- Import ScrollFrame
    local importScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    importScroll:SetPoint("TOPLEFT", 12, -74)
    importScroll:SetPoint("BOTTOMRIGHT", -30, 70)
    frame.importScroll = importScroll
    frame.importBox = CreateMultiLineEditBox(importScroll, function() frame:Hide() end)
    frame.importBox:SetScript("OnTextChanged", function(self)
        -- 输入中不自动全选
    end)

    -- Stats
    local stats = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stats:SetPoint("BOTTOM", 0, 36)
    frame.stats = stats

    -- 导出：全选
    local selectAllBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    selectAllBtn:SetSize(120, 22)
    selectAllBtn:SetPoint("BOTTOM", 0, 10)
    selectAllBtn:SetText(L["Select All"])
    selectAllBtn:SetScript("OnClick", function()
        if frame.exportBox then
            frame.exportBox:SetFocus()
            frame.exportBox:HighlightText()
        end
    end)
    frame.selectAllBtn = selectAllBtn

    -- 导入：预览 / 合并 / 替换
    local previewBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    previewBtn:SetSize(90, 22)
    previewBtn:SetPoint("BOTTOMLEFT", 20, 10)
    previewBtn:SetText(L["Preview"])
    frame.previewBtn = previewBtn

    local mergeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    mergeBtn:SetSize(110, 22)
    mergeBtn:SetPoint("LEFT", previewBtn, "RIGHT", 8, 0)
    mergeBtn:SetText(L["Import Merge"])
    frame.mergeBtn = mergeBtn

    local replaceBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    replaceBtn:SetSize(110, 22)
    replaceBtn:SetPoint("LEFT", mergeBtn, "RIGHT", 8, 0)
    replaceBtn:SetText(L["Import Replace"])
    frame.replaceBtn = replaceBtn

    -- 先隐藏导入区域，避免首次闪烁
    importScroll:Hide()
    previewBtn:Hide()
    mergeBtn:Hide()
    replaceBtn:Hide()

    ExportImport._dialog = frame
    return frame
end

local function SetDialogMode(frame, mode)
    if not frame then return end
    local isExport = mode == "export"
    frame.mode = mode

    frame.exportScroll:SetShown(isExport)
    frame.selectAllBtn:SetShown(isExport)
    frame.importScroll:SetShown(not isExport)
    frame.previewBtn:SetShown(not isExport)
    frame.mergeBtn:SetShown(not isExport)
    frame.replaceBtn:SetShown(not isExport)
end

function ExportImport:ShowExportDialog(exportType)
    local frame = EnsureDialog()
    UpdateDialogParent(frame)
    SetDialogMode(frame, "export")

    self._exportRequestId = (self._exportRequestId or 0) + 1
    local requestId = self._exportRequestId

    local sourceText = (exportType == "placed") and L["Export Source Placed"] or L["Export Source Clipboard"]
    if frame.info then frame.info:SetText(L["Export Hint"]) end
    if frame.sub then frame.sub:SetText(sourceText) end
    if frame.TitleText then frame.TitleText:SetText(L["Clipboard Import/Export"]) end

    local function ApplyExportData(exportData, err)
        if self._exportRequestId ~= requestId then return end
        if not exportData then
            if ADT.Notify then ADT.Notify(err or L["Export failed"], "error") end
            if frame.stats then frame.stats:SetText(err or L["Export failed"]) end
            return
        end
        local exportString, serr = self:EncodeExportData(exportData)
        if not exportString then
            if ADT.Notify then ADT.Notify(serr or L["Export failed"], "error") end
            if frame.stats then frame.stats:SetText(serr or L["Export failed"]) end
            return
        end
        if frame.exportBox then
            frame.exportBox.ignoreTextChanged = false
            frame.exportBox:SetText(exportString)
            frame.exportBox:SetCursorPosition(0)
        end
        if frame.stats then
            frame.stats:SetText(string.format(L["Export Stats"], #exportData.e, #exportString))
        end

        frame:Show()
        C_Timer.After(0.05, function()
            if frame:IsShown() and frame.exportBox then
                frame.exportBox:SetFocus()
                frame.exportBox:HighlightText()
            end
        end)
    end

    if exportType == "placed" then
        if frame.exportBox then
            frame.exportBox.ignoreTextChanged = false
            frame.exportBox:SetText("")
            frame.exportBox:SetCursorPosition(0)
        end
        if frame.stats then frame.stats:SetText(L["Export Scanning"]) end
        frame:Show()

        local exportData, err = self:BuildExportData(exportType)
        ApplyExportData(exportData, err)
        return
    end

    local exportData, err = self:BuildExportData(exportType)
    ApplyExportData(exportData, err)
end

function ExportImport:ShowImportDialog(importString)
    local frame = EnsureDialog()
    UpdateDialogParent(frame)
    SetDialogMode(frame, "import")

    if frame.info then frame.info:SetText(L["Import Hint"]) end
    if frame.sub then frame.sub:SetText(L["Import Hint Sub"]) end
    if frame.TitleText then frame.TitleText:SetText(L["Clipboard Import/Export"]) end
    if frame.stats then frame.stats:SetText(L["Import Stats Empty"]) end

    if frame.importBox then
        if importString and importString ~= "" then
            frame.importBox:SetText(importString)
            frame.importBox:SetCursorPosition(0)
        else
            frame.importBox:SetText("")
        end
    end

    frame.previewBtn:SetScript("OnClick", function()
        if not frame.importBox then return end
        local text = frame.importBox:GetText()
        local preview, perr = self:GetImportPreview(text)
        if preview then
            frame.stats:SetText(string.format(
                L["Import Preview Stats"],
                preview.totalItems,
                preview.availableItems,
                preview.unavailableItems
            ))
        else
            frame.stats:SetText(L["Import Preview Failed"] .. (perr and (": " .. perr) or ""))
            if ADT.Notify then ADT.Notify(perr or L["Import Preview Failed"], "error") end
        end
    end)

    local function DoImport(mode)
        if not frame.importBox then return end
        local text = frame.importBox:GetText()
        local count, ierr = self:ImportToClipboard(text, mode)
        if count then
            if ADT.Notify then ADT.Notify(string.format(L["Import Done"], count), "success") end
            frame.stats:SetText(string.format(L["Import Done"], count))
        else
            if ADT.Notify then ADT.Notify(ierr or L["Import failed"], "error") end
            frame.stats:SetText(L["Import failed"] .. (ierr and (": " .. ierr) or ""))
        end
    end

    frame.mergeBtn:SetScript("OnClick", function() DoImport("merge") end)
    frame.replaceBtn:SetScript("OnClick", function() DoImport("replace") end)

    frame:Show()
    C_Timer.After(0.05, function()
        if frame:IsShown() and frame.importBox then
            frame.importBox:SetFocus()
        end
    end)
end

-- ============================================================================
-- 斜杠命令（调试用）
-- ============================================================================
SLASH_ADTEXPORT1 = "/adtexport"
SlashCmdList["ADTEXPORT"] = function(msg)
    msg = (msg or ""):lower()
    
    if msg == "placed" or msg == "" then
        if ExportImport.ShowExportDialog then
            ExportImport:ShowExportDialog("placed")
        end
    elseif msg == "clipboard" then
        if ExportImport.ShowExportDialog then
            ExportImport:ShowExportDialog("clipboard")
        end
    else
        print("|cff00ff00[ADT Export]|r 用法: /adtexport [placed|clipboard]")
    end
end

SLASH_ADTIMPORT1 = "/adtimport"
SlashCmdList["ADTIMPORT"] = function(msg)
    if ExportImport.ShowImportDialog then
        ExportImport:ShowImportDialog(msg)
    end
end
