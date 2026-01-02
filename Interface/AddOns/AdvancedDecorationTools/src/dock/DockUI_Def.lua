-- DockUI_Def.lua
-- DockUI 配置常量与共享定义（单一权威）

local ADDON_NAME, ADT = ...
if not ADT.IsToCVersionEqualOrNewerThan(110000) then return end

-- 初始化 DockUI 命名空间
ADT.DockUI = ADT.DockUI or {}

-- ============================================================================
-- 核心配置常量
-- ============================================================================
local Def = {
    ButtonSize = 28,
    CategoryHeight = 22,
    WidgetGap = 14,
    PageHeight = 380,
    CategoryGap = 10,
    TabButtonHeight = 40,

    -- 颜色定义
    TextColorNormal = {215/255, 192/255, 163/255},
    TitleColorPaleGold = {0.95, 0.86, 0.55},
    TextColorHighlight = {1, 1, 1},
    TextColorNonInteractable = {148/255, 124/255, 102/255},
    TextColorDisabled = {0.5, 0.5, 0.5},
    TextColorReadable = {163/255, 157/255, 147/255},

    -- 右侧内容区域布局
    RightContentPaddingLeft = 14,
    CategoryLabelToCountGap = 8,
    CountTextWidthReserve = 22,
    EntryLabelLeftInset = 28,
    HeaderLeftNudge = 8,
    AboutTextExtraLeft = 0,

    -- 高亮条配置
    HighlightTextPaddingLeft = 10,
    HighlightRightInset = 2,
    HighlightMinHeight = 18,
    HighlightTextPadX = 6,
    HighlightRightBias = -2,

    -- 右侧停靠配置
    ScreenRightMargin = 0,
    StaticRightAttachOffset = 0,
    LeftPanelPadTop = 14,
    LeftPanelPadBottom = 14,

    -- Header/顶部区域配置
    HeaderHeight = 68,
    ShowHeaderTitle = false,
    HeaderTitleOffsetX = 22,
    HeaderTitleOffsetY = -10,
    CloseBtnOffsetX = -1,
    CloseBtnOffsetY = -1,

    -- PlacedListButton 配置
    PlacedListBtnPoint = "LEFT",
    PlacedListBtnRelPoint = "LEFT",
    PlacedListBtnOffsetX = 40,
    PlacedListBtnOffsetY = -1,
    PlacedListBtnRaiseAboveBorder = 1,

    -- 滚动区域边距
    ScrollViewInsetTop = 2,
    ScrollViewInsetBottom = 18,
    RightBGInsetRight = 0,
    RightBGInsetBottom = 0,
    CenterBGInsetBottom = 0,

    -- 空状态配置
    EmptyStateTopGap = 6,

    -- 左侧分类按钮配置
    CategoryButtonLabelOffset = 9,
    CategoryCountRightInset = 2,

    -- ============================================================================
    -- 统一内容行布局配置（单一权威）
    -- 所有页面内容行必须使用此配置，禁止硬编码布局参数
    -- ============================================================================
    RowLayout = {
        -- 标签锚定于行左侧
        LabelLeftInset = 0,
        -- 控件锚定于行右侧
        ControlRightInset = 4,
        -- 下拉按钮默认宽度（文本过长时动态扩展）
        DropdownMinWidth = 80,
        -- 下拉按钮最大宽度限制
        DropdownMaxWidth = 140,
        -- 下拉按钮额外内边距（箭头+文字边距）
        DropdownPadding = 24,
        -- 行高
        RowHeight = 28,
        -- 滑块标签宽度
        SliderLabelWidth = 120,
        -- 滑块标签最小宽度（过窄时优先保证标签可见）
        SliderLabelMinWidth = 64,
        -- 滑块是否默认使用两行布局（标题一行，滑块+数值一行）
        SliderTwoLine = true,
        -- 滑块行高度（两行布局）
        SliderRowHeight = 44,
        -- 标题行高度
        SliderLabelLineHeight = 16,
        -- 标题行与滑块行间距
        SliderLabelLineGap = 4,
        -- 滑块控件高度
        SliderControlHeight = 20,
        -- 滑块数值宽度
        SliderValueWidth = 34,
        -- 滑块与标签/数值间距
        SliderGap = 2,
        -- 滑块最小可视宽度（不足时压缩标签宽度）
        SliderMinWidth = 110,
        -- 滑块轨道内边距（控制按钮占位）
        SliderTrackInset = 10,
        -- 滑块行右侧内边距（用于贴边数值）
        SliderLineRightInset = 0,
        -- 数值右侧内边距
        SliderValueRightInset = 0,
    },
}

-- ============================================================================
-- 工具函数
-- ============================================================================

-- 单一权威：右侧内容起始的左内边距
local function GetRightPadding()
    return Def.WidgetGap
end

-- ============================================================================
-- 导出
-- ============================================================================
ADT.DockUI.Def = Def
ADT.DockUI.GetRightPadding = GetRightPadding

-- 全局访问器：解决子模块无法访问 DockUI.lua 中局部变量 MainFrame 的问题
-- 所有子模块通过此函数获取 MainFrame 引用
function ADT.DockUI.GetMainFrame()
    return ADT.CommandDock and ADT.CommandDock.SettingsPanel
end

-- 快捷别名
function ADT.DockUI.GetCommandDock()
    return ADT.CommandDock
end
