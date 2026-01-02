-- Housing_Config.lua
-- 目的：为“说明文本 + 按键气泡”的样式提供单一权威配置来源。
-- 规范：
-- - 使用 AddOn 命名空间在同一插件内共享（参见 Warcraft Wiki: Using the AddOn namespace）。
-- - 不做 JSON/外部文件读取（WoW 插件运行时无文件 I/O；配置须以内嵌 Lua 形式提供）。

local ADDON_NAME, ADT = ...
if not ADT then return end

-- ===========================
-- 样式配置（单一权威）
-- ===========================
local CFG = {
    -- Dock 与官方面板的布局参数
    Layout = {
        -- ============ 右侧两层纵向布局（LayoutManager 单一权威） ============
        -- DockUI 最小高度（像素）：必须保证 Header + 基本交互可见
        dockMinHeightPx = 160,
        -- DockUI 最小临界高度（像素）：再小会破坏交互；溢出时 Dock 不得低于该值
        dockMinHeightCriticalPx = 160,
        -- DockUI 最大高度占屏幕比例（0~1）：仅作为 max-height 防爆，不做主分配
        dockMaxHeightViewportRatio = 0.32,
        -- 官方面板最小高度（像素）：默认允许为 0
        blizzardMinHeightPx = 0,
        -- 两层之间的统一垂直间距（像素，默认 0 表示相切）
        verticalGapPx = 0,
        -- 视口安全边距（像素）
        topSafeMarginPx = 0,
        bottomSafeMarginPx = 8,
        -- 说明：布局为“Dock 固定右上 + 官方面板向下堆叠”。
        -- ============ 新增：宽度约束（Dock 统一权威） ============
        -- 中央区域（不含左侧分类栏）的最小宽度，避免短文案把面板压窄导致换行/省略。
        -- 对应 DockUI.UpdateAutoWidth 中的 minCenter。
        dockMinCenterWidth = 300,
        -- Dock 主体“总宽度”相对当前视口宽度的最大占比（0~1）。
        -- 设为 0 或 nil 表示不以比例限制，仅受屏幕边距与内容驱动。
        dockMaxTotalWidthRatio = 0.5,

        -- ============ 重要变更：DockUI 固定宽度（按语言） ============
        -- 目的：彻底删除 DockUI 的“自动动态调整宽度”逻辑，改为每个语言一组固定宽度。
        -- 设计：单一权威配置表，键为暴雪 Locale（GetLocale() 返回值），fallback 使用 "default"。
        -- 说明：
        -- - center 表示 Dock 右侧主体（中央列表区域）的固定宽度（像素）；
        -- - side   表示左侧分类面板（静态左窗）的固定宽度（像素）。
        -- - 若某语言未显式给出，则回退到 default；开发/测试阶段如需微调，仅改本表。
        DockWidthByLocale = {
            -- 基线（大多数拉丁语系适用）
            default = { center = 360, side = 180 },
            -- 中文：字面密度高，列表与分类建议更宽一些
            zhCN    = { center = 300, side = 200 },
            zhTW    = { center = 300, side = 200 },
            -- 韩语：略放宽中央区域与侧栏
            koKR    = { center = 380, side = 190 },
            -- 俄语/德语/法语：单词较长，适当放宽中央区域
            ruRU    = { center = 420, side = 200 },
            deDE    = { center = 420, side = 200 },
            frFR    = { center = 420, side = 200 },
            -- 南欧/南美语种：适度放宽
            esES    = { center = 400, side = 190 },
            esMX    = { center = 400, side = 190 },
            ptBR    = { center = 400, side = 190 },
            itIT    = { center = 400, side = 190 },
        },
    },
    -- 每一“行”说明（HouseEditorInstructionTemplate）的视觉参数
    Row = {
        -- 行高与间距需要兼顾多语言与字号缩放，否则会造成键帽文本挤压/堆叠。
        minHeight = 22,   -- 行最小高度：与 24px 键帽高度协调
        hSpacing  = 8,    -- 左右两列之间的间距（默认 10）
        vSpacing  = 2,    -- 不同行之间的垂直间距（容器级）
        vPadEach  = 1,    -- 每行上下额外内边距（topPadding/bottomPadding）
        -- 左侧与 Dock 内容区对齐：默认采用 DockUI 的统一左右留白（GetRightPadding），
        -- 以便与 Header.Divider 左/右缩进保持一致；若需更贴边，可改为 0。
        leftPad   = nil,       -- nil 表示使用 DockUI 统一留白；设为数字则显式覆盖
        textLeftNudge = 0,     -- 仅信息文字的额外 X 偏移（单位像素，正值→向右，负值→向左）
        textYOffset   = 0,     -- 仅信息文字的额外 Y 偏移（单位像素，正值→向上，负值→向下）
        -- 右侧仍与 DockUI 的统一右内边距一致
        rightPad  = 6,
    },
    -- 右侧“按键气泡”
    Control = {
        height      = 24,  -- 整个 Control 容器高度（默认 45）
        bgHeight    = 22,  -- 背景九宫格的高度（默认 40）
        textPad     = 22,  -- 气泡左右总留白，原逻辑约 26
        minScale    = 0.70, -- 进一步收缩按钮文本的下限
        -- 视觉右侧微调：按键气泡的九宫格右端存在外延/光晕，看起来会更靠边；
        -- 为了让“视觉上的右侧留白”与左侧文本留白一致，这里额外收回 4px。
        rightEdgeBias = 12,
    },
    -- 字体（像素级，单一权威）
    -- 说明：弃用“缩放系数”写法，改为显式像素值，便于美术/策划直接按像素调整。
    Typography = {
        instructionFontPx = 16, -- 左列信息文字字号（像素）
        controlFontPx     = 13, -- 右列键帽文字字号（像素）
        minFontSize       = 9,  -- 任意字体允许的最小像素（用于自动收缩下限）
    },
    -- 颜色（单一权威）：用于 HoverHUD 信息行的语义配色
    -- 说明：统一提供 ARGB Hex（|cAARRGGBB）的 8 位十六进制，不带前缀 |c。
    -- 设计准则（2025 UI）：
    -- - Label 使用“柔和中性色”；
    -- - 数值使用语义色：好=绿、警告=琥珀、危险/不可用=红；
    -- - 次要分隔符使用更淡的中性灰以降低竞争；
    Colors = {
        labelMuted     = "FFCCCCCC", -- 次要标签/说明
        separatorMuted = "FFAAAAAA", -- 分隔符，如 “|”、“/”、“：”
        valueGood      = "FF2AD46F", -- 良好/可用（库存>0、染色已满）
        valueWarn      = "FFFFC233", -- 部分/进行中（染色部分已用）
        valueBad       = "FFFF6B6B", -- 不可用/告警（库存=0）
        valueNeutral   = "FFB8C0CC", -- 中性数值（如 0/0、未染色）
    },
    -- 暴雪“放置的装饰清单”对齐 DockUI 的配置（单一权威）
    PlacedList = {
        -- 说明：官方清单木质边框相对 Frame 有约 ±4px 的外扩；
        -- 为与 DockUI 右侧面板的“0 外扩”对齐，这里仅在锚点上做等量补偿。
        anchorLeftCompensation  = 6,   -- 清单锚点 LEFT 方向的 +像素偏移
        anchorRightCompensation = -6,  -- 清单锚点 RIGHT 方向的 -像素偏移
        -- 垂直间距由 Layout.verticalGapPx 统一裁决（单一权威）
    },
    -- 悬停提示淡入/淡出节奏（配置驱动，单一权威）
    Fading = {
        -- 悬停开始：立即满不透明，避免“刚出现半透明”的错觉
        fadeInInstant = true,
        -- 如需动画淡入，将 fadeInInstant 设为 false，并用下列速率（每秒增量）
        fadeInRate  = 10,
        -- 淡出速度（每秒衰减量），与上面独立可配
        fadeOutRate = 3,
        -- 注意：淡出延时由调用方传入，不在此固化固定秒数
    },
    -- 染料弹窗（DyeSelectionPopout）锚点与边界（单一权威）
    DyePopout = {
        -- 与“自定义面板”左侧相切时的水平留白：0 表示严丝合缝；大于 0 则留出间距
        horizontalGap = 0,
        -- 顶部对齐的额外 Y 微调（正值向下，负值向上）
        verticalTopNudge = 0,
        -- 防止越出屏幕底部的安全边距
        safetyBottomPad = 8,
    },

    -- 住宅“库存/上限”计数（暴雪 DecorCount）在 Dock.Header 内的定位与尺寸（单一权威）
    DecorCount = {
        -- 锚点：将官方 DecorCount 贴到 Dock.Header 的哪个点位
        point    = "CENTER",
        relPoint = "CENTER",
        offsetX  = -10,
        offsetY  = -2,
        -- 缩放：整体缩放比（不改变父级/显隐）
        scale    = 0.65,
        -- 层级：为避免被木框/背景半透明影响，默认提升到最前层
        strata   = "TOOLTIP",      -- 可选：FULLSCREEN_DIALOG / DIALOG / TOOLTIP ...
        levelBias = 10,            -- 在 Header 基础上额外提升的 FrameLevel
        -- 是否忽略父级透明/缩放（避免被父级 alpha/scale 影响视觉）
        ignoreParentAlpha = true,
        ignoreParentScale = true,
    },

    -- 暴雪“放置的装饰清单”按钮（PlacedDecorListButton）在 Dock.Header 内的定位（单一权威）
    PlacedListButton = {
        point    = "RIGHT",
        relPoint = "RIGHT",
        offsetX  = -30,
        offsetY  = -3,
        scale    = 1.0,
        strata   = nil,      -- nil=跟随 Dock 主体；也可指定 "FULLSCREEN_DIALOG" 等
        levelBias = 0,       -- 基于 Header 的提升量
        levelBiasOverBorder = 1, -- 若存在 Dock.BorderFrame，则在其之上再提升的量
    },

    -- Header 齿轮按钮（折叠/展开 Dock 主体）的定位与尺寸（单一权威）
    GearButton = {
        -- 统一锚到 Dock.Header 的右上角附近，保持与关闭按钮、DecorCount 的相对关系稳定
        point    = "LEFT",
        relPoint = "LEFT",
        offsetX  = 30,
        offsetY  = -3,
        -- 尺寸（像素）：若未设置，则回落到 DockUI 的 Def.ButtonSize
        size     = 28,
        -- 层级（可选）：nil 表示跟随 Header；若需要可指定 "FULLSCREEN_DIALOG"/"TOOLTIP" 等
        strata   = nil,
        -- 基于 Header 的 FrameLevel 偏移（正数抬高）
        levelBias = 2,
    },
    -- Header 左侧“眼睛按钮”（Alt+Z 等效）：仅住宅编辑模式显示
    EyeButton = {
        -- 锚点：位于 Header 外部的左侧
        point    = "RIGHT",
        relPoint = "LEFT",
        offsetX  = -8,
        offsetY  = -2,
        -- 尺寸（像素）
        size     = 36,
        -- 层级：按钮父级为 WorldFrame，需要手动指定层级以避免被 UI 遮挡
        strata   = "TOOLTIP",
        -- 基于 Header 的 FrameLevel 偏移（正数抬高）
        levelBias = 10,
        -- Atlas：默认使用 GM-icon-visible 系列
        atlasNormal  = "GM-icon-visible",
        atlasHover   = "GM-icon-visible-hover",
        atlasPressed = "GM-icon-visible-pressed",
        -- 高亮透明度（0~1）
        highlightAlpha = 0.35,
    },
    -- Dock 列表（Clipboard/Recent）的库存数字与名称间距（配置驱动，分类可独立）
    DockDecorList = {
        -- 通用默认（各分类未覆写则继承本组）
        Common = {
            countRightInset = 20,   -- 库存数字距右边框的内缩像素
            nameToCountGap  = 8,   -- 名称与库存数字之间的间距
            countWidth      = 32,  -- 库存数字区域固定宽度（影响测宽与文本锚点）
        },
        -- 两个装饰列表型分类可分别调整
        Clipboard = {
            -- 不写表示继承 Common
            -- 示例：countRightInset = 8, nameToCountGap = 6, countWidth = 28
        },
        Recent = {
            -- 示例：countRightInset = 6, nameToCountGap = 10
        },
    },
    -- 轴悬停提示（AxisHoverHint）视觉与行为（配置驱动，单一权威）
    AxisHint = {
        -- 字体像素大小
        fontPx = 16,
        -- 光标相对偏移（屏幕空间，像素）
        cursorOffsetX = 12,
        cursorOffsetY = 16,
        -- 颜色（ARGB）
        colors = {
            X = "FFFF5A5A", -- 红
            Y = "FF2ECC71", -- 绿
            Z = "FF3498DB", -- 蓝
            Fallback = "FFFFFFFF",
        },
        -- 透明度（0~1）
        alpha = 1.0,
        -- 分层：在编辑器内置 UI 之上渲染
        strata = "TOOLTIP",
        -- 淡入/出节奏（继承通用 Fading，可单独覆盖）
        fadeInInstant = true,
        fadeInRate  = 10,
        fadeOutRate = 4,
        -- 哪些子模式显示提示：Rotate/Translate
        submodes = { Rotate = true, Translate = true },
    },
    -- Dock 选项条目/左侧分类 悬停高亮（三段贴片）参数：配置驱动，单一权威
    DockHighlight = {
        -- 三段贴片颜色（RGBA，0~1）
        color = { r = 0.96, g = 0.84, b = 0.32, a = 0.15 },
        -- 覆盖按钮的内收边距（像素；正数向内收）
        insetLeft   = 0,
        insetRight  = 0,
        insetTop    = -0,
        insetBottom = -0,
        -- 淡入控制：enabled=false 时立即显示
        fade = {
            enabled   = true,
            inDuration = 0.15,   -- 秒
        },
    },
    -- 快捷键设置 UI（KeybindUI）布局与样式参数（配置驱动，单一权威）
    KeybindUI = {
        -- 动作名称列宽度
        actionLabelWidth = 120,
        -- 按键框尺寸
        keyBoxWidth   = 100,
        keyBoxHeight  = 22,
        -- 按键框与动作名之间的间距
        actionToKeyGap = 8,
        -- 列表行内左右内边距（与行内视觉对称相关）
        rowLeftPad  = 8,
        rowRightPad = 8,
        -- Header 区域提示文本偏移（相对 Header 右侧）
        headerHintOffsetX = -50,   -- 负值向左
        headerHintOffsetY = 120,    -- 正值向上
        -- 边框颜色（RGBA 0~1）
        borderNormal    = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
        borderHover     = { r = 0.8, g = 0.6, b = 0, a = 1 },
        borderRecording = { r = 1, g = 0.82, b = 0, a = 1 },
        -- 背景颜色
        bgColor = { r = 0.08, g = 0.08, b = 0.08, a = 1 },
        -- 按键文本颜色（正常 / 未设置 / 录制中）
        keyTextNormal   = { r = 1, g = 0.82, b = 0 },      -- 金色
        keyTextEmpty    = { r = 0.5, g = 0.5, b = 0.5 },   -- 灰色
        keyTextRecording = { r = 1, g = 0.82, b = 0 },     -- 金色
        -- Header 提示文本颜色（悬停 / 录制中）
        hintHover     = { r = 0.6, g = 0.8, b = 1 },       -- 浅蓝色
        hintRecording = { r = 1, g = 0.82, b = 0 },        -- 金色
    },
    -- 快捷栏 QuickbarUI 的定位与间距（配置驱动，单一权威）
    QuickbarUI = {
        -- 说明：Quickbar 始终相对 UIParent 定位；不在配置中暴露“父级 Frame”。
        -- 锚点：通常贴底（BOTTOM/BOTTOM），如需靠上/居中可改为其他点位。
        anchor = {
            point    = "BOTTOM",  -- Quickbar 自身锚点
            relPoint = "BOTTOM",  -- 相对 UIParent 的锚点
            x        = 0,          -- 水平偏移（像素；正值→向右）
            bottomMargin = 5,      -- 底边距（像素；正值→向上）。当 point/relPoint 不是 BOTTOM 时同样作为 Y 偏移使用
        },
        -- 暴雪 ModesBar 与 Quickbar 之间的垂直间距（Quickbar 顶到 ModesBar 底）
        modeBarGap = 1,
        -- 动作栏整体缩放：与设置面板“动作栏大小”一致（配置驱动，单一权威）
        scaleBySize = {
            large  = 1.35,
            medium = 1.00,
            small  = 0.65,
        },
        -- 槽位内文本（右上角按键、右下角库存）内收像素：统一权威
        SlotTextInsets = {
            keyRight  = 6,  -- 按键文本距右侧内收
            keyTop    = 6,  -- 按键文本距顶部内收
            qtyRight  = 6,  -- 库存数字距右侧内收
            qtyBottom = 6,  -- 库存数字距底部内收
        },
    },

    -- “最近放置”快捷槽（RecentSlot）视觉参数（配置驱动，单一权威）
    RecentSlot = {
        -- 槽位尺寸与与 Quickbar 间距
        sizePx    = 80,
        spacingPx = 8,
        -- 顶部标签（“最近放置”）
        Label = {
            point    = "TOP",
            relPoint = "TOP",
            offsetX  = 0,
            offsetY  = -4,
            fontTemplate = "GameFontNormalSmall",
            fontPx       = 12,
            fontFlags    = nil,
            color = { r = 0.9, g = 0.75, b = 0.3, a = 1 }, -- 金色
        },
        -- 右下角库存数量
        Quantity = {
            point    = "BOTTOMRIGHT",
            relPoint = "BOTTOMRIGHT",
            offsetX  = -6,
            offsetY  = 6,
            fontTemplate = "GameFontNormalSmall",
            fontPx       = 12,
            fontFlags    = nil,
            colorNormal = { r = 1, g = 1, b = 1, a = 1 },
            colorZero   = { r = 1, g = 0.3, b = 0.3, a = 1 },
        },
    },

    -- DockUI 边框装饰（木框九宫格 + 藤蔓角落装饰）视觉参数（配置驱动，单一权威）
    DockBorder = {
        -- 主体木框（housing-wood-frame 九宫格）
        WoodFrame = {
            atlas = "housing-wood-frame",
            sliceMargins = 16,  -- 九宫格边距（四边统一）
        },
        -- 四个角落藤蔓装饰（housing-dashboard-filigree-corner-*）
        -- 基础尺寸（素材原始尺寸约为 54×42 / 66×50）
        CornerBaseSize = { width = 54, height = 42 },
        -- 缩放系数：1.0 = 原始大小，1.5 = 放大 50%，0.8 = 缩小 20%
        CornerScale = 1.2,
        -- 各角落偏移（相对 BorderFrame 边缘）
        CornerTL = { x = -4, y = 2 },   -- 左上角
        CornerTR = { x = 4, y = 2 },    -- 右上角
        CornerBL = { x = -4, y = -6 },  -- 左下角
        CornerBR = { x = 4, y = -6 },   -- 右下角
    },

    -- 模式栏重排布局（ModeBarRelocate）视觉参数（配置驱动，单一权威）
    ModeBarRelocate = {
        -- 主模式栏位置（相对于 UIParent 右下角）
        AnchorOffsetX = -20,  -- 距右边缘像素（负值向左）
        AnchorOffsetY = 30,   -- 距底边缘像素（正值向上）
        -- 主按钮之间的间距（负值表示重叠）
        ButtonSpacing = -8,
        -- 子模式栏与主按钮之间的间距
        SubBarOffset = -10,
        -- 箭头锚点偏移（相对于子模式栏右侧）
        ArrowOffsetX = -60,    -- 箭头 LEFT 锚点距子模式栏 RIGHT 的 X 偏移
        ArrowOffsetY = 0,     -- 箭头 Y 偏移（正值向上）
        -- 背景框内边距
        BackgroundPadding = 8,
        -- 楼层切换 UI（LayoutModeFrame.FloorSelect）位置微调
        -- 说明：现代布局下避免与右下角模式栏重叠
        FloorSelectOffsetX = -60, -- 水平偏移（负值向左）
        FloorSelectOffsetY = 0,   -- 垂直偏移（正值向上）
    },

    -- 悬停信息面板（HoverInfoPanel）配置（配置驱动，单一权威）
    HoverInfoPanel = {
        -- 面板尺寸
        Height = 56,                    -- 面板高度
        GapToQuickbar = 10,              -- 距离 QuickBar 顶部的间距
        DividerInsetX = 20,             -- 分隔线左右内缩
        DividerHeight = 8,              -- 分隔线高度
        DividerOffsetY = -28,           -- 分隔线 Y 偏移（相对于面板顶部）
        InfoRowOffsetY = -4,            -- 信息行距分隔线底部的间距

        -- 字体大小
        TitleFontSize = 18,             -- 标题字体大小
        InfoFontSize = 12,              -- 信息行字体大小

        -- 预算图标
        BudgetIconSize = 16,            -- 预算图标尺寸
        BudgetIconSpacing = 4,          -- 预算图标与数值的间距

        -- 染色色块
        DyeSwatchSize = 14,             -- 色块尺寸
        DyeSwatchSpacing = 2,           -- 色块之间的间距
        DyeIconSize = 16,               -- 染料图标尺寸
        DyeIconSpacing = 4,             -- 染料图标与色块的间距

        -- 防抖延迟（秒）
        ClearDelay = 0.15,
    },

    -- 悬停 HUD 整体位置（HoverHUD）配置（配置驱动，单一权威）
    -- 说明：控制整个 HoverHUD 区域的位置偏移，包括：
    -- - 暴雪的"选择装饰+鼠标"提示
    -- - ADT 自定义的按键气泡（重复、剪切、复制、粘贴等）
    -- - CustomizeMode 染料提示
    HoverHUD = {
        -- === BasicDecorMode 主区域 ===
        -- 锚点：相对于 HouseEditorFrame.BasicDecorModeFrame 右侧
        point    = "RIGHT",
        relPoint = "RIGHT",
        offsetX  = -100,     -- 水平偏移（负值向左）
        offsetY  = 200,       -- 垂直偏移（正值向上）
        width    = 420,     -- 容器宽度（用于文本换行）

        -- === CustomizeMode 染料提示区域 ===
        -- 锚点：相对于 HouseEditorFrame.CustomizeModeFrame 右侧
        DyeHint = {
            point    = "RIGHT",
            relPoint = "RIGHT",
            offsetX  = -30,     -- 水平偏移（负值向左）
            offsetY  = -60,     -- 垂直偏移（负值向下，避开暴雪"选中装饰"提示）
            width    = 420,
        },
    },

    -- ============ 入场/离场过渡动画配置（单一权威） ============
    -- 说明：控制进入/离开住宅编辑模式时 ADT 自定义 UI 的动画效果
    TransitionAnimations = {
        -- 总开关
        enabled = true,

        -- DockUI（右上角向下滑入）
        DockUI = {
            motion = "slide",       -- 入场/离场：滑入/滑出（避免交叉淡入）
            slideMode = "anchor",   -- slide 模式：anchor(改锚点) | translate(视觉平移)
            enterDuration = 0.5,    -- 入场动画时长（秒）
            leaveDuration = 0.35,    -- 离场动画时长（秒）
            enterDelay = 0,         -- 入场延迟（秒）
            offsetY = 200,           -- 从上方 80px 处滑入（正值 = 从屏幕外上方）
            smoothingIn = "OUT_QUART",    -- 入场缓动曲线（丝滑着陆）
            smoothingOut = "IN_SINE",    -- 离场缓动曲线（平滑减速）
        },

        -- QuickBar（底部向上滑入）
        QuickBar = {
            motion = "slide",
            slideMode = "translate",
            enterDuration = 0.5,
            leaveDuration = 0.35,
            enterDelay = 0,         -- 与 DockUI 同步入场
            offsetY = -100,          -- 从下方 60px 处滑入（负值 = 从屏幕外下方）
            smoothingIn = "OUT_QUART",
            smoothingOut = "IN_SINE",
        },

        -- ModeBar（右下角向上溶解淡入）
        ModeBar = {
            enterDuration = 0.5,
            leaveDuration = 0.35,
            enterDelay = 0.15,      -- 比 QuickBar 延迟 50ms
            offsetY = 100,          -- 从下方 100px 处淡入
            smoothingIn = "OUT_QUART",
            smoothingOut = "IN_SINE",
        },

        -- DockUI 折叠/展开动画（Header 不变，主体向上收缩/向下展开）
        DockCollapse = {
            enabled = true,
            collapseDuration = 0.35,    -- 折叠动画时长（秒）
            expandDuration = 0.4,       -- 展开动画时长（秒）
            smoothingIn = "OUT_QUART",  -- 展开缓动曲线
            smoothingOut = "IN_OUT_SINE", -- 折叠缓动曲线
        },
    },
}

-- 导出为全局唯一权威
ADT.HousingInstrCFG = CFG

-- 便捷访问器（避免外部直接覆写表结构）
function ADT.GetHousingCFG()
    return ADT.HousingInstrCFG
end
