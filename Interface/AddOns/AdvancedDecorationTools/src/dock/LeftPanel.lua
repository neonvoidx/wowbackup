-- 左侧面板（LeftPanel）独立模块：负责分类列表/高亮/静态弹窗定位
-- 约束：不处理右侧/中央逻辑；不感知业务内容，仅依赖 CommandDock 提供的数据

local ADDON_NAME, ADT = ...
if not ADT or not ADT.IsToCVersionEqualOrNewerThan or not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

local API = ADT.API
local CommandDock = ADT.CommandDock

ADT.DockLeft = ADT.DockLeft or {}
local DockLeft = ADT.DockLeft

-- 配置与常量来自 DockUI 的 Def（单一权威）
local function Def()
    return (ADT.DockUI and ADT.DockUI.Def) or {}
end

-- 模式：当前仅支持“静态左窗”（与主面板同级，不滑动）
local USE_STATIC_LEFT_PANEL = true
function DockLeft.IsStatic()
    return USE_STATIC_LEFT_PANEL
end

-- 临时排障：将左侧面板整体左移的像素值。
-- 验证思路：若移动后可点击，说明原位置上有透明可点层覆盖；若仍不可点，问题在层级/代理或父子关系。
-- 调试偏移（静态左窗已定位正确，恢复为 0；如需再次排障可暂改为负值）
local DEBUG_LEFT_SHIFT_X = 0

-- 侧栏目标宽度（按语言 + 文本测量）：
-- KISS 最小化修复：以配置的 locale 宽度为下限，
-- 再用“当前语言下的分类名称”做一次文本测宽，取二者较大值。
do
    local measureFrame, measureFS
    local function EnsureMeter()
        if measureFS and measureFS.GetStringWidth then return measureFS end
        measureFrame = measureFrame or CreateFrame("Frame")
        measureFrame:Hide()
        measureFS = measureFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        if measureFS.SetWordWrap then measureFS:SetWordWrap(false) end
        if measureFS.SetNonSpaceWrap then measureFS:SetNonSpaceWrap(false) end
        if measureFS.SetMaxLines then measureFS:SetMaxLines(1) end
        return measureFS
    end

    local function GetConfiguredSideWidth()
        local cfgGetter = ADT and ADT.GetHousingCFG
        local C = cfgGetter and cfgGetter() or nil
        local map = C and C.Layout and C.Layout.DockWidthByLocale
        local locale = (ADT and ADT.GetActiveLocale and ADT.GetActiveLocale())
                        or ((type(GetLocale) == 'function' and GetLocale()) or "default")
        local entry = map and (map[locale] or map.default)
        local side = entry and tonumber(entry.side) or 180
        return API.Round(side)
    end

    local function MeasureCategoriesMaxTextWidth()
        local fs = EnsureMeter()
        local maxW = 0
        -- 与分类按钮一致的字体对象
        if GameFontNormal and fs.SetFontObject then fs:SetFontObject(GameFontNormal) end
        -- 从 CommandDock 读取“当前语言”的分类名称列表（不依赖已构建的 UI）
        local list = CommandDock and CommandDock.GetSortedModules and CommandDock:GetSortedModules() or {}
        for _, cat in ipairs(list) do
            local txt = (cat and cat.categoryName) or ""
            fs:SetText(txt)
            local w
            if fs.GetUnboundedStringWidth then
                w = math.ceil(fs:GetUnboundedStringWidth() or 0)
            else
                w = math.ceil(fs:GetStringWidth() or 0)
            end
            if w > maxW then maxW = w end
        end
        return maxW
    end

    function DockLeft.ComputeSideSectionWidth()
        -- 文本测量：最长分类名 + 左右标签内边距 + 左窗左右留白
        local d = Def()
        local labelPad = tonumber(d.CategoryButtonLabelOffset) or 9
        local sidePad = 2 * (tonumber(d.WidgetGap) or 14)
        local want = MeasureCategoriesMaxTextWidth()
        if want and want > 0 then
            -- 纯按文本 + 内边距计算；增加额外裕量避免重音/字距舍入造成省略
            local fudge = 6
            want = API.Round(want + 2 * labelPad + sidePad + fudge)
            return want
        end
        -- 兜底：若无法测得文本宽度，则回退到按语言的固定配置
        return GetConfiguredSideWidth()
    end

end

-- 分类按钮模板
local function CreateCategoryButton(parent)
    local d = Def()
    local f = CreateFrame("Button", nil, parent)
    f:SetSize(120, d.CategoryHeight or d.ButtonSize or 28)
    f.labelOffset = 9
    if f.RegisterForClicks then f:RegisterForClicks("AnyUp") end

    f.Label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.Label:SetJustifyH("LEFT")
    f.Label:SetPoint("LEFT", f, "LEFT", f.labelOffset, 0)
    -- 强制“单行且不自动断词/不省略”：超长通过面板增宽解决
    if f.Label.SetWordWrap then f.Label:SetWordWrap(false) end
    if f.Label.SetNonSpaceWrap then f.Label:SetNonSpaceWrap(false) end
    if f.Label.SetIndentedWordWrap then f.Label:SetIndentedWordWrap(false) end
    if f.Label.SetMaxLines then f.Label:SetMaxLines(1) end
    if f.Label.SetTextTruncation then f.Label:SetTextTruncation(0) end
    -- 右侧再加一个锚点，宽度随按钮变化而变化（不再直接 SetWidth）
    f.Label:SetPoint("RIGHT", f, "RIGHT", -f.labelOffset, 0)
    f.Label:SetTextColor((d.TextColorNormal or {1,1,1})[1], (d.TextColorNormal or {1,1,1})[2], (d.TextColorNormal or {1,1,1})[3])

    -- 可选计数（默认隐藏；不再为其预留任何右侧空间）
    local CountContainer = CreateFrame("Frame", nil, f)
    f.CountContainer = CountContainer
    CountContainer:SetSize(d.CountTextWidthReserve or 22, d.ButtonSize or 28)
    CountContainer:SetPoint("RIGHT", f, "RIGHT", -f.labelOffset, 0)
    CountContainer:Hide()
    f.Count = CountContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.Count:SetJustifyH("RIGHT")
    f.Count:SetPoint("RIGHT", CountContainer, "RIGHT", -2, 0)

    local function SetTextColor(fs, color)
        if not fs or not color then return end
        fs:SetTextColor(color[1] or 1, color[2] or 1, color[3] or 1)
    end

    function f:UpdateLabelWidth()
        -- 仅保证左右锚点存在；不再主动设定具体像素宽，避免被 UI 层触发省略
        self.Label:ClearAllPoints()
        self.Label:SetPoint("LEFT", self, "LEFT", self.labelOffset, 0)
        self.Label:SetPoint("RIGHT", self, "RIGHT", -self.labelOffset, 0)
    end

    function f:ShowCount(count)
        -- 当前视觉要求：不展示计数，保持左右完全对称
        self.CountContainer:Hide()
        self:UpdateLabelWidth()
    end

    -- New 标记（小圆点），与原样保持
    local newTag = f:CreateTexture(nil, "OVERLAY")
    newTag:SetTexture("Interface/AddOns/AdvancedDecorationTools/Art/CommandDock/NewFeatureTag", nil, nil, "TRILINEAR")
    newTag:SetSize(16, 16)
    newTag:SetPoint("CENTER", f, "LEFT", 0, 0)
    newTag:SetTexCoord(0.5, 1, 0, 1)
    newTag:Hide()
    f.NewTag = newTag

    function f:SetCategory(key, text, anyNewFeature)
        text = (ADT.API and ADT.API.StringTrim and ADT.API.StringTrim(text or "")) or tostring(text or ""):match("^%s*(.-)%s*$")
        self.Label:SetText(text)
        self.cateogoryName = string.lower(text)
        self.categoryKey = key
        self.NewTag:ClearAllPoints()
        self.NewTag:SetPoint("CENTER", self, "LEFT", 0, 0)
        self.NewTag:SetShown(anyNewFeature)
        self:UpdateLabelWidth()
    end

    function f:OnEnter()
        local main = self._main
        if main and main.HighlightButton then main:HighlightButton(self) end
        SetTextColor(self.Label, d.TextColorHighlight or {1,1,1})
        if ADT and ADT.DebugPrint and ADT.IsDebugEnabled and ADT.IsDebugEnabled() then
            ADT.DebugPrint("[DockLeft] OnEnter key="..tostring(self.categoryKey))
        end
    end

    function f:OnLeave()
        local main = self._main
        if main and main.HighlightButton then main:HighlightButton() end
        SetTextColor(self.Label, d.TextColorNormal or {0.9,0.9,0.9})
    end

    function f:OnClick()
        local main = self._main
        if not (main and CommandDock and CommandDock.GetCategoryByKey) then return end
        local cat = CommandDock:GetCategoryByKey(self.categoryKey)
        local categoryType = cat and cat.categoryType or "settings"
        
        -- 仅通过 EventBus 上报分类选择（单一权威事件通路）
        if ADT.EventBus then
            ADT.EventBus:Fire(ADT.EventBus.Events.CATEGORY_SELECTED, self.categoryKey, categoryType)
        end
        
        if ADT.UI and ADT.UI.PlaySoundCue then ADT.UI.PlaySoundCue('ui.scroll.step') end
        if main and main.HighlightButton then main:HighlightButton(self) end
        if ADT.DebugPrint and ADT.IsDebugEnabled and ADT.IsDebugEnabled() then
            ADT.DebugPrint("[DockLeft] OnClick key="..tostring(self.categoryKey).." via EventBus")
        end
    end

    function f:OnMouseDown()
        self.Label:SetPoint("LEFT", self, "LEFT", self.labelOffset + 1, -1)
    end

    function f:OnMouseUp()
        self:ResetOffset()
    end

    function f:ResetOffset()
        self.Label:SetPoint("LEFT", self, "LEFT", self.labelOffset, 0)
    end

    f:SetScript("OnEnter", f.OnEnter)
    f:SetScript("OnLeave", f.OnLeave)
    f:SetScript("OnClick", f.OnClick)
    f:SetScript("OnMouseDown", f.OnMouseDown)
    f:SetScript("OnMouseUp", f.OnMouseUp)

    return f
end

-- 选中高亮（纯色矩形）
-- 高亮容器改为复用 DockUI 的单一权威构造

-- 初始化并构建左侧面板（静态）
function DockLeft.Build(MainFrame, sideSectionWidth)
    local d = Def()
    local LeftSection = MainFrame.LeftSection
    LeftSection:SetClipsChildren(true)

    -- 为避免跨父级锚点带来的坐标/同步问题，这里改回挂在 MainFrame 下，
    -- 同时我们已在 DockUI.lua 禁用会遮挡的小部件鼠标，确保点击不被拦截。
    local LeftSlideParent = MainFrame
    local LeftSlide = CreateFrame("Frame", nil, LeftSlideParent)
    MainFrame.LeftSlideContainer = LeftSlide
    LeftSlide:ClearAllPoints()
    -- 顶部贴合到 Header 底部，小窗高度不占满父面板
    -- 临时排障：整体左移 DEBUG_LEFT_SHIFT_X 像素
    if MainFrame.Header then
        LeftSlide:SetPoint("TOPRIGHT", MainFrame.Header, "BOTTOMLEFT", (d.StaticRightAttachOffset or 0) + DEBUG_LEFT_SHIFT_X, -2)
    else
        LeftSlide:SetPoint("TOPRIGHT", MainFrame, "TOPLEFT", (d.StaticRightAttachOffset or 0) + DEBUG_LEFT_SHIFT_X, 0)
    end
    LeftSlide:SetWidth(sideSectionWidth)
    -- 层级策略（稳定可点）：
    -- 1) 左窗必须永远压在 Dock 右侧各容器之上，避免被无意的背景/占位层拦截。
    -- 2) 但又不能影响游戏其他顶层 UI，因此仅抬升到 TOOLTIP strata；
    --    右侧主面板统一处于 FULLSCREEN_DIALOG（见 DockUI），两者不会互相遮挡。
    LeftSlide:SetFrameStrata("TOOLTIP")
    LeftSlide:SetFrameLevel((MainFrame:GetFrameLevel() or 0) + 600)
    LeftSlide:SetToplevel(true)
    -- 关键：左侧小窗自身要参与命中测试，避免父级/兄弟框体“透明覆盖”导致子按钮无法收到点击
    LeftSlide:EnableMouse(true)
    LeftSlide:EnableMouseMotion(true)
    LeftSlide:Show()

    -- The War Within 卡片风格：ui-frame-thewarwithin-cardparchmentwider
    local container = LeftSlide:CreateTexture(nil, "ARTWORK")
    MainFrame.LeftPanelContainer = container
    container:SetAtlas("ui-frame-thewarwithin-cardparchmentwider")
    container:SetTextureSliceMargins(32, 32, 32, 32)
    container:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    container:SetAllPoints(LeftSlide)

    -- 分类按钮池
    local categoryButtonWidth = sideSectionWidth - 2 * (d.WidgetGap or 14)
    local function Category_Create()
        local obj = CreateCategoryButton(LeftSlide)
        obj:SetSize(categoryButtonWidth, d.CategoryHeight or d.ButtonSize or 28)
        if obj.UpdateLabelWidth then obj:UpdateLabelWidth() end
        return obj
    end
    local function Category_Acquire(obj)
        obj:Show()
        obj:EnableMouse(true)
        obj._main = MainFrame
        local base = (LeftSlide and LeftSlide.GetFrameLevel and LeftSlide:GetFrameLevel()) or 10000
        pcall(obj.SetFrameLevel, obj, base + 10)
        pcall(obj.SetToplevel, obj, false)
        -- 移除顶层点击代理（会造成越界覆盖）；保持按钮自身命中即可
        if obj._proxy then
            obj._proxy:Hide()
            obj._proxy:SetScript('OnEnter', nil)
            obj._proxy:SetScript('OnLeave', nil)
            obj._proxy:SetScript('OnClick', nil)
        end
        -- 移除调试背景，避免出现“文本背后绿色矩形”
        -- 安全注入：旧对象池的遗留对象可能缺少方法，这里兜底补齐
        if type(obj.SetCategory) ~= 'function' then
            function obj:SetCategory(key, text, anyNewFeature)
                text = (ADT.API and ADT.API.StringTrim and ADT.API.StringTrim(text or "")) or tostring(text or ""):match("^%s*(.-)%s*$")
                self.Label:SetText(text)
                self.cateogoryName = string.lower(text)
                self.categoryKey = key
                if self.NewTag then
                    self.NewTag:ClearAllPoints(); self.NewTag:SetPoint("CENTER", self, "LEFT", 0, 0); self.NewTag:SetShown(anyNewFeature)
                end
                if self.UpdateLabelWidth then self:UpdateLabelWidth() end
            end
        end
    end
    MainFrame.primaryCategoryPool = API.CreateObjectPool(Category_Create, Category_Acquire, nil)
    MainFrame.primaryCategoryPool.leftListFromY = -(d.WidgetGap or 14)
    MainFrame.primaryCategoryPool.offsetX = d.WidgetGap or 14

    -- 初始高度：按当前分类数量估算一次，避免第一帧小窗高度错误
    do
        local n = 0
        if CommandDock and CommandDock.GetSortedModules then
            for _ in ipairs(CommandDock:GetSortedModules() or {}) do n = n + 1 end
        end
        local topPad = d.LeftPanelPadTop or d.WidgetGap or 14
        local bottomPad = d.LeftPanelPadBottom or d.WidgetGap or 14
        local rowH = d.CategoryHeight or d.ButtonSize or 28
        local wanted = topPad + n * rowH + bottomPad
        LeftSlide:SetHeight(wanted)
    end

    -- 高亮：不在 LeftPanel 复写；使用 DockUI.lua 定义的 MainFrame:HighlightButton

    -- 动态左侧高度（按分类数量）
    function MainFrame:UpdateLeftSectionHeight()
        local n = 0
        if self.primaryCategoryPool and self.primaryCategoryPool.EnumerateActive then
            for _ in self.primaryCategoryPool:EnumerateActive() do n = n + 1 end
        end
        local topPad = d.WidgetGap or 14
        local catH = d.CategoryHeight or d.ButtonSize or 28
        local height = math.max(catH, topPad + n * catH + topPad)
        LeftSection:SetHeight(height)
    end

    -- 静态模式：更新独立左窗的定位（跟随右侧主面板）
    function MainFrame:UpdateStaticLeftPlacement()
        if not DockLeft.IsStatic() then return end
        if not (self and self:IsShown()) then return end
        -- 基于“已生成按钮的真实文本宽度”精确计算；
        -- 优先使用 GetUnboundedStringWidth（11.0+），保证不受当前 Label 宽度限制；
        -- 对旧版本回退到 GetStringWidth。
        local maxLabel = 0
        if self.primaryCategoryPool and self.primaryCategoryPool.EnumerateActive then
            for _, btn in self.primaryCategoryPool:EnumerateActive() do
                local fs = btn and btn.Label
                if fs then
                    local w = 0
                    if fs.GetUnboundedStringWidth then
                        w = tonumber(fs:GetUnboundedStringWidth()) or 0
                    elseif fs.GetStringWidth then
                        w = tonumber(fs:GetStringWidth()) or 0
                    end
                    w = math.ceil(w)
                    if w > maxLabel then maxLabel = w end
                end
            end
        end
        local dcalc = Def()
        local w = nil
        if maxLabel > 0 then
            local labelPad = tonumber(dcalc.CategoryButtonLabelOffset) or 9
            local sidePad  = 2 * (tonumber(dcalc.WidgetGap) or 14)
            w = API.Round(maxLabel + 2 * labelPad + sidePad + 2)
        else
            w = DockLeft.ComputeSideSectionWidth()
        end
        if w and w > 0 then
            -- 记录到 MainFrame 以便 DockUI 其余逻辑复用
            self.sideSectionWidth = w
            -- 统一调用 DockUI 的侧宽应用（同步按钮/高亮/滚动区域等）。
            if type(self._ApplySideWidth) == 'function' then self:_ApplySideWidth(w) end
        end
        local d2 = Def()
        LeftSlide:ClearAllPoints()
        -- 与 Build 中保持一致：左移 DEBUG_LEFT_SHIFT_X 的排障偏移
        if self.Header then
            LeftSlide:SetPoint("TOPRIGHT", self.Header, "BOTTOMLEFT", (d2.StaticRightAttachOffset or 0) + DEBUG_LEFT_SHIFT_X, -2)
        else
            LeftSlide:SetPoint("TOPRIGHT", self, "TOPLEFT", (d2.StaticRightAttachOffset or 0) + DEBUG_LEFT_SHIFT_X, 0)
        end
        -- 依据分类数量重算高度，避免小窗拉满
        local n = 0
        if self.primaryCategoryPool and self.primaryCategoryPool.EnumerateActive then
            for _ in self.primaryCategoryPool:EnumerateActive() do n = n + 1 end
        end
        local topPad = d2.LeftPanelPadTop or d2.WidgetGap or 14
        local bottomPad = d2.LeftPanelPadBottom or d2.WidgetGap or 14
        local rowH = d2.CategoryHeight or d2.ButtonSize or 28
        local wanted = topPad + n * rowH + bottomPad
        LeftSlide:SetHeight(wanted)
    end

    -- 工具方法：导出给外界复用
    function MainFrame:HighlightCategoryByKey(key)
        if not key or not self.primaryCategoryPool then return end
        for _, button in self.primaryCategoryPool:EnumerateActive() do
            if button and button.categoryKey == key then
                self:HighlightButton(button)
                break
            end
        end
    end

    -- 保持代理层级与左窗对齐（防止被覆盖）
    LeftSlide:HookScript('OnUpdate', function()
        local base = (LeftSlide and LeftSlide.GetFrameLevel and LeftSlide:GetFrameLevel()) or 10000
        if MainFrame and MainFrame.primaryCategoryPool and MainFrame.primaryCategoryPool.EnumerateActive then
            for _, btn in MainFrame.primaryCategoryPool:EnumerateActive() do
                if btn and btn._proxy and btn._proxy.SetFrameLevel then
                    btn._proxy:SetFrameLevel(base + 20)
                end
            end
        end
    end)

    -- 调试：快速观察按钮是否能收到 Hover/Click（受 /adt debug on 控制）
    local function dprint(...)
        if ADT and ADT.DebugPrint and ADT.IsDebugEnabled and ADT.IsDebugEnabled() then ADT.DebugPrint(...) end
    end
    hooksecurefunc(_G, 'CreateFrame', function() end) -- 占位，确保可用 hooksecurefunc
    -- 给新建的分类按钮补充调试输出
    local origCreate = CreateCategoryButton
    if origCreate and not DockLeft.__patched_debug then
        DockLeft.__patched_debug = true
        -- 不改变对象结构，仅在 OnEnter/OnClick 输出
        -- 已在上方定义，不重复包裹；这里仅确保函数存在
    end
end

-- 兼容旧引用：将计算函数同步到 DockUI 命名空间
ADT.DockUI = ADT.DockUI or {}
ADT.DockUI.ComputeSideSectionWidth = DockLeft.ComputeSideSectionWidth
