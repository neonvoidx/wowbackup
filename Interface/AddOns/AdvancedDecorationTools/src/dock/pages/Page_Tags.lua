-- Page_Tags.lua
-- 标签管理页面：创建/删除/重命名/颜色/排序/查看装饰物
-- 使用 PageBase 基类

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local PageBase = ADT.DockUI.PageBase
local L = ADT.L or {}

-- ============================================================================
-- 创建页面实例（继承 PageBase）
-- ============================================================================

local PageTags = PageBase:New("Tags", { categoryType = "tagManager" })

-- ============================================================================
-- 颜色圆点纹理资源
-- ============================================================================

local DOT_ATLAS = "LevelUp-Dot-Gold"  -- 使用金色圆点并通过 SetVertexColor 着色
local DOT_SIZE = 14

-- ============================================================================
-- 辅助函数
-- ============================================================================

local function Ls(key)
    return L[key] or key
end

local function GetTags()
    if ADT.Tags and ADT.Tags.GetAll then
        return ADT.Tags:GetAll()
    end
    return {}
end

-- ============================================================================
-- 创建标签行模板
-- ============================================================================

local function CreateTagRowTemplate(parent, width)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(width, 36)
    row:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = nil,
        tile = false,
        tileSize = 0,
        edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    row:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
    
    -- 颜色圆点
    row.dot = row:CreateTexture(nil, "OVERLAY")
    row.dot:SetAtlas(DOT_ATLAS)
    row.dot:SetSize(DOT_SIZE, DOT_SIZE)
    row.dot:SetPoint("LEFT", row, "LEFT", 8, 0)
    
    -- 标签名称
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.nameText:SetPoint("LEFT", row.dot, "RIGHT", 8, 0)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWidth(width - 100)
    
    -- 装饰物数量
    row.countText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.countText:SetPoint("RIGHT", row, "RIGHT", -50, 0)
    row.countText:SetJustifyH("RIGHT")
    row.countText:SetTextColor(0.7, 0.7, 0.7)
    
    -- 上移按钮
    row.upBtn = CreateFrame("Button", nil, row)
    row.upBtn:SetSize(16, 16)
    row.upBtn:SetPoint("RIGHT", row, "RIGHT", -28, 0)
    row.upBtn:SetNormalAtlas("common-icon-moveup")
    row.upBtn:SetHighlightAtlas("common-icon-moveup")
    row.upBtn:SetScript("OnClick", function()
        if row._tagIndex and row._tagIndex > 1 then
            if ADT.Tags and ADT.Tags.MoveTag then
                ADT.Tags:MoveTag(row._tagIndex, row._tagIndex - 1)
                if ADT.DockPages and ADT.DockPages.PageTags then
                    ADT.DockPages.PageTags:Refresh()
                end
            end
        end
    end)
    
    -- 下移按钮
    row.downBtn = CreateFrame("Button", nil, row)
    row.downBtn:SetSize(16, 16)
    row.downBtn:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.downBtn:SetNormalAtlas("common-icon-movedown")
    row.downBtn:SetHighlightAtlas("common-icon-movedown")
    row.downBtn:SetScript("OnClick", function()
        if row._tagIndex then
            local tags = GetTags()
            if row._tagIndex < #tags then
                if ADT.Tags and ADT.Tags.MoveTag then
                    ADT.Tags:MoveTag(row._tagIndex, row._tagIndex + 1)
                    if ADT.DockPages and ADT.DockPages.PageTags then
                        ADT.DockPages.PageTags:Refresh()
                    end
                end
            end
        end
    end)
    
    -- 悬停高亮
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.25, 0.25, 0.7)
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
    end)
    
    -- 右键菜单
    row:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and self._tagData then
            MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
                rootDescription:SetTag("MENU_ADT_TAG_MANAGE")
                
                -- 重命名
                rootDescription:CreateButton(Ls("Rename"), function()
                    -- 打开重命名对话框
                    StaticPopupDialogs["ADT_RENAME_TAG"] = {
                        text = Ls("New Tag") .. ":",
                        button1 = OKAY,
                        button2 = CANCEL,
                        hasEditBox = true,
                        OnShow = function(dialog)
                            dialog.editBox:SetText(self._tagData.name or "")
                            dialog.editBox:HighlightText()
                        end,
                        OnAccept = function(dialog)
                            local newName = dialog.editBox:GetText()
                            if newName and newName ~= "" and ADT.Tags and ADT.Tags.RenameTag then
                                ADT.Tags:RenameTag(self._tagData.id, newName)
                                if ADT.DockPages and ADT.DockPages.PageTags then
                                    ADT.DockPages.PageTags:Refresh()
                                end
                            end
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        preferredIndex = 3,
                    }
                    StaticPopup_Show("ADT_RENAME_TAG")
                end)
                
                -- 更换颜色子菜单
                local colorSubmenu = rootDescription:CreateButton(Ls("Tag Color") or "更换颜色")
                local colors = ADT.Tags and ADT.Tags:GetAvailableColors() or {}
                for _, colorKey in ipairs(colors) do
                    local rgb = ADT.Tags:GetColorRGB(colorKey)
                    local colorCode = string.format("|cff%02x%02x%02x", 
                        math.floor(rgb[1] * 255), 
                        math.floor(rgb[2] * 255), 
                        math.floor(rgb[3] * 255))
                    local displayName = colorCode .. "● |r" .. Ls(colorKey)
                    
                    local function IsSelected()
                        return self._tagData.color == colorKey
                    end
                    
                    local function SetSelected()
                        if ADT.Tags and ADT.Tags.SetTagColor then
                            ADT.Tags:SetTagColor(self._tagData.id, colorKey)
                            if ADT.DockPages and ADT.DockPages.PageTags then
                                ADT.DockPages.PageTags:Refresh()
                            end
                        end
                    end
                    
                    colorSubmenu:CreateCheckbox(displayName, IsSelected, SetSelected)
                end
                
                rootDescription:CreateDivider()
                
                -- 删除（收藏标签不可删除）
                if self._tagData.id ~= "favorite" then
                    rootDescription:CreateButton("|cffff4444" .. Ls("Delete Tag") .. "|r", function()
                        if ADT.Tags and ADT.Tags.DeleteTag then
                            local ok, err = ADT.Tags:DeleteTag(self._tagData.id)
                            if ok then
                                if ADT.DockPages and ADT.DockPages.PageTags then
                                    ADT.DockPages.PageTags:Refresh()
                                end
                            else
                                print("|cffff0000[ADT]|r " .. (err or Ls("Cannot delete default tag")))
                            end
                        end
                    end)
                else
                    local deleteBtn = rootDescription:CreateButton("|cff666666" .. Ls("Delete Tag") .. "|r", function() end)
                    deleteBtn:SetEnabled(false)
                end
            end)
        end
    end)
    
    return row
end

-- ============================================================================
-- 渲染方法
-- ============================================================================

function PageTags:Render(mainFrame, categoryKey)
    local ok, ctx = self:PreRender(mainFrame, categoryKey)
    if not ok then return false end
    
    -- 设置分类状态
    self:SetCategoryState(ctx, "currentSettingsCategory")
    
    local sv = ctx.mainFrame.ModuleTab.ScrollView
    local totalWidth = ctx.mainFrame.centerButtonWidth or 300
    local panelWidth = totalWidth - ctx.offsetX * 2
    
    -- 渲染标题
    self:RenderHeader(ctx, Ls("Tags"), { showDivider = true })
    
    -- "新建标签" 按钮
    local newTagKey = "TagsNewTagButton"
    if sv and sv._templates then
        sv._templates[newTagKey] = nil
        sv:AddTemplate(newTagKey, function()
            local cached = self:GetCachedFrame(newTagKey)
            if cached then return cached end
            
            local btn = CreateFrame("Button", nil, sv, "UIPanelButtonTemplate")
            btn:SetSize(panelWidth, 28)
            btn:SetText(Ls("New Tag"))
            btn:SetScript("OnClick", function()
                -- 打开新建标签对话框
                StaticPopupDialogs["ADT_NEW_TAG"] = {
                    text = Ls("New Tag") .. ":",
                    button1 = OKAY,
                    button2 = CANCEL,
                    hasEditBox = true,
                    OnAccept = function(dialog)
                        local name = dialog.editBox:GetText()
                        if name and name ~= "" and ADT.Tags and ADT.Tags.CreateTag then
                            ADT.Tags:CreateTag(name)
                            if ADT.DockPages and ADT.DockPages.PageTags then
                                ADT.DockPages.PageTags:Refresh()
                            end
                        end
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,
                }
                StaticPopup_Show("ADT_NEW_TAG")
            end)
            
            self:RegisterCachedFrame(newTagKey, btn)
            return btn
        end)
    end
    
    self:AddContentItem(ctx, {
        templateKey = newTagKey,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        top = ctx.offsetY,
        bottom = ctx.offsetY + 28,
        offsetX = ctx.offsetX,
    })
    self:AdvanceOffset(ctx, 28 + 8)
    
    -- 提示文本
    local tipKey = "TagsTipText"
    if sv and sv._templates then
        sv._templates[tipKey] = nil
        sv:AddTemplate(tipKey, function()
            local cached = self:GetCachedFrame(tipKey)
            if cached then return cached end
            
            local tipFrame = CreateFrame("Frame", nil, sv)
            tipFrame:SetSize(panelWidth, 16)
            local tip = tipFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            tip:SetAllPoints(tipFrame)
            tip:SetWidth(panelWidth)
            tip:SetJustifyH("LEFT")
            tip:SetTextColor(0.6, 0.6, 0.6)
            tipFrame.text = tip
            self:RegisterCachedFrame(tipKey, tipFrame)
            return tipFrame
        end)
    end
    
    self:AddContentItem(ctx, {
        templateKey = tipKey,
        setupFunc = function(obj)
            if obj.text then
                obj.text:SetText(Ls("First 7 tags shown in menu"))
            elseif obj.SetText then
                obj:SetText(Ls("First 7 tags shown in menu"))
            end
        end,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        top = ctx.offsetY,
        bottom = ctx.offsetY + 16,
        offsetX = ctx.offsetX,
    })
    self:AdvanceOffset(ctx, 16 + 8)
    
    -- 渲染标签列表
    local tags = GetTags()
    for i, tag in ipairs(tags) do
        local rowKey = "TagRow_" .. tostring(i)
        
        if sv and sv._templates then
            sv._templates[rowKey] = nil
            sv:AddTemplate(rowKey, function()
                local cached = self:GetCachedFrame(rowKey)
                if cached then return cached end
                
                local row = CreateTagRowTemplate(sv, panelWidth)
                self:RegisterCachedFrame(rowKey, row)
                return row
            end)
        end
        
        local tagData = tag
        local tagIndex = i
        local totalTags = #tags
        
        self:AddContentItem(ctx, {
            templateKey = rowKey,
            setupFunc = function(obj)
                obj._tagData = tagData
                obj._tagIndex = tagIndex
                
                -- 更新颜色
                local rgb = ADT.Tags and ADT.Tags:GetColorRGB(tagData.color) or {1, 1, 1}
                obj.dot:SetVertexColor(rgb[1], rgb[2], rgb[3])
                
                -- 更新名称（收藏标签显示本地化名称）
                local displayName = tagData.name
                if tagData.id == "favorite" then
                    displayName = Ls("Favorites")
                end
                obj.nameText:SetText(displayName)
                
                -- 更新装饰物数量
                local count = ADT.Tags and ADT.Tags:GetDecorCountByTag(tagData.id) or 0
                obj.countText:SetText(tostring(count))
                
                -- 更新上下移动按钮可用性
                obj.upBtn:SetEnabled(tagIndex > 1)
                obj.upBtn:SetAlpha(tagIndex > 1 and 1 or 0.3)
                obj.downBtn:SetEnabled(tagIndex < totalTags)
                obj.downBtn:SetAlpha(tagIndex < totalTags and 1 or 0.3)
            end,
            point = "TOPLEFT",
            relativePoint = "TOPLEFT",
            top = ctx.offsetY,
            bottom = ctx.offsetY + 36,
            offsetX = ctx.offsetX,
        })
        self:AdvanceOffset(ctx, 36 + 2)
    end
    
    -- 提交
    self:CommitRender(ctx)
    
    return true
end

-- ============================================================================
-- 刷新方法
-- ============================================================================

function PageTags:Refresh()
    -- 获取当前 mainFrame
    local mainFrame = ADT.CommandDock and ADT.CommandDock.SettingsPanel
    if mainFrame then
        self:Render(mainFrame, "Tags")
    end
end

-- ============================================================================
-- 注册页面
-- ============================================================================

ADT.DockPages:Register("Tags", PageTags)
ADT.DockPages.PageTags = PageTags
