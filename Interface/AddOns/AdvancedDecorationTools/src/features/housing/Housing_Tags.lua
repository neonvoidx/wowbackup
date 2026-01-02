-- Housing_Tags.lua
-- ADT 多标签收藏系统核心模块
-- 设计原则：
-- 1) 支持多个自定义标签（类似 macOS Finder）
-- 2) 前 7 个标签显示在右键菜单快捷区
-- 3) 数据持久化到 ADT_DB.Tags 和 ADT_DB.DecorTags
-- 4) 兼容迁移旧版 FavoritesByRID

local ADDON_NAME, ADT = ...
if not ADT then return end

local Tags = {}
ADT.Tags = Tags

--------------------------------------------------------------------------------
-- 常量定义
--------------------------------------------------------------------------------

-- 预设颜色（7 色 + 收藏黄）
local TAG_COLORS = {
    yellow = {1.0, 0.85, 0},
    red    = {0.9, 0.3, 0.3},
    orange = {1.0, 0.6, 0.2},
    green  = {0.3, 0.8, 0.3},
    blue   = {0.3, 0.6, 1.0},
    purple = {0.7, 0.4, 0.9},
    gray   = {0.6, 0.6, 0.6},
}

-- 默认标签列表（首次加载时创建）
local function GetDefaultTags()
    local L = ADT.L or {}
    return {
        { id = "favorite", name = L["Favorites"] or "收藏",  color = "yellow", isDefault = true },
        { id = "red",      name = L["Red"] or "红色",       color = "red"    },
        { id = "orange",   name = L["Orange"] or "橙色",    color = "orange" },
        { id = "green",    name = L["Green"] or "绿色",     color = "green"  },
        { id = "blue",     name = L["Blue"] or "蓝色",      color = "blue"   },
        { id = "purple",   name = L["Purple"] or "紫色",    color = "purple" },
        { id = "gray",     name = L["Gray"] or "灰色",      color = "gray"   },
    }
end

-- 数据库键名
local KEY_TAGS = "Tags"
local KEY_DECOR_TAGS = "DecorTags"
local KEY_OLD_FAV = "FavoritesByRID"  -- 旧版收藏，需迁移

-- 右键菜单快捷区最大数量
local MAX_QUICK_TAGS = 7

--------------------------------------------------------------------------------
-- 数据访问
--------------------------------------------------------------------------------

local function GetDB()
    _G.ADT_DB = _G.ADT_DB or {}
    return _G.ADT_DB
end

local function GetTagsList()
    local db = GetDB()
    if not db[KEY_TAGS] then
        db[KEY_TAGS] = GetDefaultTags()
    end
    return db[KEY_TAGS]
end

local function GetDecorTagsMap()
    local db = GetDB()
    db[KEY_DECOR_TAGS] = db[KEY_DECOR_TAGS] or {}
    return db[KEY_DECOR_TAGS]
end

--------------------------------------------------------------------------------
-- 初始化与迁移
--------------------------------------------------------------------------------

function Tags:Init()
    local db = GetDB()
    
    -- 1. 初始化 Tags 列表
    if not db[KEY_TAGS] then
        db[KEY_TAGS] = GetDefaultTags()
    end
    
    -- 2. 初始化 DecorTags
    if not db[KEY_DECOR_TAGS] then
        db[KEY_DECOR_TAGS] = {}
    end
    
    -- 3. 迁移旧版 FavoritesByRID
    if db[KEY_OLD_FAV] then
        local decorTags = db[KEY_DECOR_TAGS]
        for recordID, _ in pairs(db[KEY_OLD_FAV]) do
            local rid = tonumber(recordID) or recordID
            if not decorTags[rid] then
                decorTags[rid] = {}
            end
            -- 检查是否已有 favorite 标签
            local hasFav = false
            for _, tagID in ipairs(decorTags[rid]) do
                if tagID == "favorite" then
                    hasFav = true
                    break
                end
            end
            if not hasFav then
                table.insert(decorTags[rid], "favorite")
            end
        end
        db[KEY_OLD_FAV] = nil  -- 迁移后删除
        if ADT.DebugPrint then
            ADT.DebugPrint("[Tags] 已迁移旧版收藏数据")
        end
    end
end

--------------------------------------------------------------------------------
-- 标签列表操作
--------------------------------------------------------------------------------

--- 获取所有标签
function Tags:GetAll()
    return GetTagsList()
end

--- 获取前 N 个标签（用于右键菜单快捷区）
function Tags:GetQuickTags()
    local all = GetTagsList()
    local result = {}
    for i = 1, math.min(MAX_QUICK_TAGS, #all) do
        table.insert(result, all[i])
    end
    return result
end

--- 根据 ID 获取标签
function Tags:GetByID(tagID)
    if not tagID then return nil end
    for _, tag in ipairs(GetTagsList()) do
        if tag.id == tagID then
            return tag
        end
    end
    return nil
end

--- 根据 ID 获取索引
function Tags:GetIndexByID(tagID)
    if not tagID then return nil end
    for i, tag in ipairs(GetTagsList()) do
        if tag.id == tagID then
            return i
        end
    end
    return nil
end

--- 获取颜色 RGB
function Tags:GetColorRGB(colorName)
    return TAG_COLORS[colorName] or TAG_COLORS.gray
end

--- 获取所有可用颜色
function Tags:GetAllColors()
    return TAG_COLORS
end

--------------------------------------------------------------------------------
-- 标签 CRUD
--------------------------------------------------------------------------------

--- 创建新标签
function Tags:Create(name, color)
    local tags = GetTagsList()
    local id = "tag_" .. time() .. "_" .. math.random(1000, 9999)
    local newTag = {
        id = id,
        name = name or (ADT.L and ADT.L["New Tag"] or "新标签"),
        color = color or "gray",
        isDefault = false,
    }
    table.insert(tags, newTag)
    return newTag
end

--- 删除标签
function Tags:Delete(tagID)
    if not tagID then return false end
    
    local tags = GetTagsList()
    local index = nil
    for i, tag in ipairs(tags) do
        if tag.id == tagID then
            if tag.isDefault then
                return false  -- 默认标签不可删除
            end
            index = i
            break
        end
    end
    
    if index then
        table.remove(tags, index)
        -- 清理 DecorTags 中的引用
        local decorTags = GetDecorTagsMap()
        for recordID, tagList in pairs(decorTags) do
            for i = #tagList, 1, -1 do
                if tagList[i] == tagID then
                    table.remove(tagList, i)
                end
            end
        end
        return true
    end
    return false
end

--- 重命名标签
function Tags:Rename(tagID, newName)
    if not tagID or not newName then return false end
    local tag = self:GetByID(tagID)
    if tag then
        tag.name = newName
        return true
    end
    return false
end

--- 设置标签颜色
function Tags:SetColor(tagID, newColor)
    if not tagID or not newColor then return false end
    if not TAG_COLORS[newColor] then return false end
    local tag = self:GetByID(tagID)
    if tag then
        tag.color = newColor
        return true
    end
    return false
end

--- 上移标签
function Tags:MoveUp(tagID)
    if not tagID then return false end
    local tags = GetTagsList()
    local index = self:GetIndexByID(tagID)
    if index and index > 1 then
        tags[index], tags[index - 1] = tags[index - 1], tags[index]
        return true
    end
    return false
end

--- 下移标签
function Tags:MoveDown(tagID)
    if not tagID then return false end
    local tags = GetTagsList()
    local index = self:GetIndexByID(tagID)
    if index and index < #tags then
        tags[index], tags[index + 1] = tags[index + 1], tags[index]
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- 装饰物标签操作
--------------------------------------------------------------------------------

--- 获取装饰物的所有标签 ID 列表
function Tags:GetDecorTags(recordID)
    if not recordID then return {} end
    local decorTags = GetDecorTagsMap()
    return decorTags[recordID] or {}
end

--- 检查装饰物是否有某个标签
function Tags:HasTag(recordID, tagID)
    if not recordID or not tagID then return false end
    local tagList = self:GetDecorTags(recordID)
    for _, id in ipairs(tagList) do
        if id == tagID then
            return true
        end
    end
    return false
end

--- 设置装饰物标签
function Tags:SetDecorTag(recordID, tagID, state)
    if not recordID or not tagID then return false end
    
    local decorTags = GetDecorTagsMap()
    if not decorTags[recordID] then
        decorTags[recordID] = {}
    end
    
    local tagList = decorTags[recordID]
    local currentIndex = nil
    for i, id in ipairs(tagList) do
        if id == tagID then
            currentIndex = i
            break
        end
    end
    
    if state then
        -- 添加标签
        if not currentIndex then
            table.insert(tagList, tagID)
        end
    else
        -- 移除标签
        if currentIndex then
            table.remove(tagList, currentIndex)
        end
    end
    
    -- 清理空列表
    if #tagList == 0 then
        decorTags[recordID] = nil
    end
    
    return true
end

--- 切换装饰物标签
function Tags:ToggleDecorTag(recordID, tagID)
    local hasTag = self:HasTag(recordID, tagID)
    return self:SetDecorTag(recordID, tagID, not hasTag)
end

--- 清除装饰物所有标签
function Tags:ClearDecorTags(recordID)
    if not recordID then return false end
    local decorTags = GetDecorTagsMap()
    decorTags[recordID] = nil
    return true
end

--- 检查装饰物是否有任何标签
function Tags:HasAnyTag(recordID)
    if not recordID then return false end
    local tagList = self:GetDecorTags(recordID)
    return #tagList > 0
end

--- 获取装饰物的标签（带完整信息）
function Tags:GetDecorTagsWithInfo(recordID)
    local tagIDs = self:GetDecorTags(recordID)
    local result = {}
    for _, tagID in ipairs(tagIDs) do
        local tag = self:GetByID(tagID)
        if tag then
            table.insert(result, tag)
        end
    end
    return result
end

--------------------------------------------------------------------------------
-- 筛选功能
--------------------------------------------------------------------------------

--- 筛选有指定标签的 recordID 集合
function Tags:FilterByTag(tagID)
    if not tagID then return {} end
    local result = {}
    local decorTags = GetDecorTagsMap()
    for recordID, tagList in pairs(decorTags) do
        for _, id in ipairs(tagList) do
            if id == tagID then
                result[recordID] = true
                break
            end
        end
    end
    return result
end

--- 筛选有任一指定标签的 recordID 集合（OR 模式）
function Tags:FilterByAnyTags(tagIDs)
    if not tagIDs or #tagIDs == 0 then return {} end
    local result = {}
    local decorTags = GetDecorTagsMap()
    for recordID, tagList in pairs(decorTags) do
        for _, id in ipairs(tagList) do
            for _, filterID in ipairs(tagIDs) do
                if id == filterID then
                    result[recordID] = true
                    break
                end
            end
            if result[recordID] then break end
        end
    end
    return result
end

--------------------------------------------------------------------------------
-- 兼容旧版 Favorites 模块
--------------------------------------------------------------------------------

--- 检查是否已收藏（兼容旧接口）
function Tags:IsFavorited(recordID)
    return self:HasTag(recordID, "favorite")
end

--- 设置收藏状态（兼容旧接口）
function Tags:SetFavorited(recordID, state)
    return self:SetDecorTag(recordID, "favorite", state)
end

--- 切换收藏状态（兼容旧接口）
function Tags:ToggleFavorited(recordID)
    return self:ToggleDecorTag(recordID, "favorite")
end

--------------------------------------------------------------------------------
-- Page_Tags 专用方法
--------------------------------------------------------------------------------

--- 获取所有可用颜色名称列表
function Tags:GetAvailableColors()
    return { "yellow", "red", "orange", "green", "blue", "purple", "gray" }
end

--- 按索引移动标签
function Tags:MoveTag(fromIndex, toIndex)
    if not fromIndex or not toIndex then return false end
    local tags = GetTagsList()
    if fromIndex < 1 or fromIndex > #tags then return false end
    if toIndex < 1 or toIndex > #tags then return false end
    if fromIndex == toIndex then return false end
    
    local tag = table.remove(tags, fromIndex)
    table.insert(tags, toIndex, tag)
    return true
end

--- 获取某标签关联的装饰物数量
function Tags:GetDecorCountByTag(tagID)
    if not tagID then return 0 end
    local count = 0
    local decorTags = GetDecorTagsMap()
    for recordID, tagList in pairs(decorTags) do
        for _, id in ipairs(tagList) do
            if id == tagID then
                count = count + 1
                break
            end
        end
    end
    return count
end

--- 创建标签（别名）
function Tags:CreateTag(name, color)
    return self:Create(name, color)
end

--- 删除标签（别名，返回 ok, err）
function Tags:DeleteTag(tagID)
    local tag = self:GetByID(tagID)
    if not tag then
        return false, "Tag not found"
    end
    if tag.isDefault then
        return false, ADT.L and ADT.L["Cannot delete default tag"] or "Cannot delete default tag"
    end
    local ok = self:Delete(tagID)
    return ok, nil
end

--- 重命名标签（别名）
function Tags:RenameTag(tagID, newName)
    return self:Rename(tagID, newName)
end

--- 设置标签颜色（别名）
function Tags:SetTagColor(tagID, newColor)
    return self:SetColor(tagID, newColor)
end

--------------------------------------------------------------------------------
-- 右键菜单注入
--------------------------------------------------------------------------------

local function InjectTagsContextMenu()
    if not HousingCatalogDecorEntryMixin then return end
    
    local L = ADT.L or {}
    
    -- 使用 Menu.ModifyMenu 在暴雪原生菜单上追加标签选项
    -- 这样不会覆盖原始菜单，只是在其基础上添加内容
    Menu.ModifyMenu("MENU_HOUSING_CATALOG_ENTRY", function(owner, rootDescription, contextData)
        -- 获取 recordID（从 owner 即装饰条目按钮获取）
        local entryInfo = owner and owner.entryInfo
        if not entryInfo then return end
        
        local recordID = entryInfo.entryID and entryInfo.entryID.recordID
        if not recordID then return end
        
        -- 在菜单最前面插入标签子菜单
        local insertIndex = 1
        
        -- 创建标签子菜单
        local tagsSubmenu = rootDescription:CreateButton(L["Tags"] or "标签")
        
        -- 尝试将标签菜单移动到最前面
        -- Note: MenuUtil API 可能不支持直接移动，所以标签会出现在最后
        -- 但这已经是最安全的做法，不会破坏暴雪原生菜单
        
        -- 添加前 7 个快捷标签（带勾选框）
        local quickTags = Tags:GetQuickTags()
        for _, tag in ipairs(quickTags) do
            local rgb = Tags:GetColorRGB(tag.color)
            local colorCode = string.format("|cff%02x%02x%02x", 
                math.floor(rgb[1] * 255), 
                math.floor(rgb[2] * 255), 
                math.floor(rgb[3] * 255))
            local displayName = colorCode .. "● |r" .. tag.name
            
            local function IsSelected()
                return Tags:HasTag(recordID, tag.id)
            end
            
            local function SetSelected()
                Tags:ToggleDecorTag(recordID, tag.id)
                -- 刷新星标/圆点显示
                if ADT.Favorites and ADT.Favorites.RefreshCatalog then
                    ADT.Favorites:RefreshCatalog()
                end
            end
            
            tagsSubmenu:CreateCheckbox(displayName, IsSelected, SetSelected)
        end
        
        -- 分隔线
        tagsSubmenu:CreateDivider()
        
        -- "全部标签..." 按钮（打开 DockUI Tags 页面）
        tagsSubmenu:CreateButton(L["All Tags"] or "全部标签...", function()
            -- 打开 ADT 设置界面的标签页
            if ADT.CommandDock and ADT.CommandDock.Show then
                ADT.CommandDock:Show("Tags")
            end
        end)
        
        -- "清除所有标签" 按钮
        if Tags:HasAnyTag(recordID) then
            tagsSubmenu:CreateDivider()
            tagsSubmenu:CreateButton(L["Clear All Tags"] or "清除所有标签", function()
                Tags:ClearDecorTags(recordID)
                -- 刷新星标/圆点显示
                if ADT.Favorites and ADT.Favorites.RefreshCatalog then
                    ADT.Favorites:RefreshCatalog()
                end
            end)
        end
    end)
    
    if ADT.DebugPrint then
        ADT.DebugPrint("[Tags] 右键菜单注入完成（使用 Menu.ModifyMenu）")
    end
end

--------------------------------------------------------------------------------
-- 初始化钩子
--------------------------------------------------------------------------------

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == ADDON_NAME then
        Tags:Init()
        -- 延迟注入右键菜单（确保暴雪 Mixin 已加载）
        C_Timer.After(0.5, InjectTagsContextMenu)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
