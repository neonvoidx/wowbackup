-- PageRouter.lua
-- 页面路由模块：统一管理页面切换逻辑
-- 从 DockUI.lua 中提取，实现 Controller 层与 View 层的解耦

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local CommandDock = ADT.CommandDock

-- ============================================================================
-- PageRouter 单例
-- ============================================================================

local PageRouter = {}
ADT.PageRouter = PageRouter

-- 当前活动的分类信息
PageRouter.currentCategory = nil
PageRouter.currentCategoryType = nil

-- ============================================================================
-- 核心路由方法
-- ============================================================================

--- 根据分类键和类型路由到对应页面
--- @param categoryKey string 分类键名
--- @param categoryType string|nil 分类类型（可选，会自动从 CommandDock 获取）
--- @return boolean 是否成功路由
function PageRouter:Route(categoryKey, categoryType)
    local MainFrame = ADT.CommandDock and ADT.CommandDock.SettingsPanel
    if not MainFrame then
        ADT.DebugPrint("[PageRouter] MainFrame not found")
        return false
    end
    
    -- 获取分类信息
    if not categoryType then
        local cat = CommandDock:GetCategoryByKey(categoryKey)
        categoryType = cat and cat.categoryType or "settings"
    end
    
    ADT.DebugPrint(string.format("[PageRouter] Route: key=%s type=%s", 
        tostring(categoryKey), tostring(categoryType)))
    
    -- 记录当前分类
    self.currentCategory = categoryKey
    self.currentCategoryType = categoryType
    
    -- 查找页面并渲染
    local page = ADT.DockPages:Get(categoryKey)
    if not page then
        -- 回退到类型匹配
        local typeMap = {
            decorList = "Clipboard",
            dyePresetList = "DyePresets",
            about = "About",
            keybinds = "Keybinds",
            settings = "Housing",
        }
        local fallbackKey = typeMap[categoryType] or "Housing"
        page = ADT.DockPages:Get(fallbackKey)
    end
    
    if page and page.Render then
        local success = page:Render(MainFrame, categoryKey)
        if success then
            -- 触发页面渲染完成事件
            if ADT.EventBus then
                ADT.EventBus:Fire(ADT.EventBus.Events.CATEGORY_RENDERED, categoryKey, categoryType)
            end
        end
        return success
    end
    
    ADT.DebugPrint(string.format("[PageRouter] No page found for %s", tostring(categoryKey)))
    return false
end

--- 显示设置类分类
--- @param categoryKey string 分类键名
function PageRouter:ShowSettings(categoryKey)
    return self:Route(categoryKey, "settings")
end

--- 显示装饰列表类分类
--- @param categoryKey string 分类键名
function PageRouter:ShowDecorList(categoryKey)
    return self:Route(categoryKey, "decorList")
end

--- 显示染色预设类分类
--- @param categoryKey string 分类键名
function PageRouter:ShowDyePresets(categoryKey)
    return self:Route(categoryKey, "dyePresetList")
end

--- 显示关于类分类
--- @param categoryKey string 分类键名
function PageRouter:ShowAbout(categoryKey)
    return self:Route(categoryKey, "about")
end

--- 显示快捷键类分类
--- @param categoryKey string 分类键名
function PageRouter:ShowKeybinds(categoryKey)
    return self:Route(categoryKey, "keybinds")
end

-- ============================================================================
-- 便捷查询方法
-- ============================================================================

--- 获取当前活动的分类键
--- @return string|nil
function PageRouter:GetCurrentCategory()
    return self.currentCategory
end

--- 获取当前活动的分类类型
--- @return string|nil
function PageRouter:GetCurrentCategoryType()
    return self.currentCategoryType
end

--- 判断指定分类是否为当前活动分类
--- @param categoryKey string 分类键名
--- @return boolean
function PageRouter:IsActive(categoryKey)
    return self.currentCategory == categoryKey
end

-- ============================================================================
-- 导出
-- ============================================================================

ADT.PageRouter = PageRouter

return PageRouter
