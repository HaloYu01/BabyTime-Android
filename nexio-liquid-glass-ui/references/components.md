# 组件 Components

逐件给出**几何、颜色、交互**与落地方式。括号内是该件在 NexioSchedule 的源文件，便于回查；没写路径的属于 Miuix 原生组件，直接用库。

## 1 顶栏 CollapsibleTopAppBar

```kotlin
CollapsibleTopAppBar(
    title = "第9周",
    showLargeTitle = false,          // 课表页不用大标题
    titleStartAligned = isTablet,    // 手机居中，平板左对齐（避让侧栏）
    scrollBehavior = sharedScrollBehavior(),
    materialState = material,        // 与页面头部构件共用同一实例
    startAction = { _, _ -> WeatherBadge() },
    endAction = { alpha, shadow -> TopBarActions(alpha, shadow) },
)
```

| 项 | 值 |
|---|---|
| 折叠高 | 52dp（`TopAppBarDefaults.CollapsedHeight`） |
| 标题内边距 | 26dp（左右一致，居中时视觉不偏） |
| 导航图标内边距 | 16dp 起始；动作图标 16dp 结束 |
| 大标题底部留白 | 无副标题 4dp / 有副标题 8dp |
| 小顶栏居中高度 | 50dp |
| 折叠阈值 | 滚动 10dp 后进入"有材质"态 |

规则：
- **滚动行为必须是全页共享的单例**（`SharedScrollBehavior`）。每页各建一个，顶栏高度会互相打架、切页时内容跳一帧。
- 标题/副标题区不参与 blur 采样；blur 层在顶栏**之下**，动作按钮在其上。
- 顶栏不透明化后要收掉按钮阴影（`shadowAlpha` 与材质同源），否则"玻璃已消失但阴影还在"。

## 2 圆形玻璃按钮 LiquidTopBarButton

| 项 | 值 |
|---|---|
| 尺寸 | 42dp（直径 = 高），全圆角 `ContinuousCapsule` |
| 图标 | 24dp 默认；切换课表 27dp、周跳转/外观 23dp |
| 图标色 | 浅：黑 85% / 深：白 85% |
| 按压 | 缩小 2dp（`pressScaleDp = 2f`）+ 高光跟随；拉伸比 `GlassDragStretchRatio`、位移阻尼 `GlassDragTranslationDamping` |
| 阴影 | 环形差集路径，半径 10dp × shadowAlpha、spread 2dp × shadowAlpha，颜色 alpha ×3.2（上限 1） |
| 触感 | `HapticFeedbackType.Confirm`，可关 |
| 层级 | 玻璃层 z0 → 高光层 z1（clip 到胶囊）→ 图标 z2 |
| fill / tone | `ThemeFill` / `BrightTone`（只有图标的按钮不压暗） |

必须遵守的两点：
1. 高光层**不能挂在玻璃节点上**：`drawBackdrop` 的 `layerBlock` 会把整节点 alpha 乘上 `backdropAlpha`，顶栏滚动时高光会跟着消失。高光与玻璃**平级**。
2. 玻璃节点不 `clip`（拉伸会超出 bounds），只给高光层 `clip(ContinuousCapsule())`。

顶栏右侧两颗按钮间距 8dp；"更多"按钮是本组件 + 下拉菜单的组合体（收起态即那颗 42dp 按钮）。

## 3 渐进模糊带 ProgressiveBlurTopBar

| 参数 | 值 |
|---|---|
| 高度 | 有状态栏 `120dp + sb`；无状态栏 `160dp`；竖排 tab 折叠态 `120dp - 8dp` |
| 着色强度 tintIntensity | 0.2 |
| 渐隐起点 edgeFadeStart | 0.88（钳在 0.4–0.95） |
| 遮罩 alpha | 与顶栏材质同源（无材质档时它是唯一材质） |
| 假渐进模糊 | 低端/无 shader 平台用分层遮罩近似（`LocalUseFakeProgressiveBlur`） |

高度是**装饰值**，内容顶部永远对齐"星期行底 + 2dp"，不要用模糊带高度推内容，否则折叠屏上内容会被拽上去。

## 4 顶栏材质状态 TopBarMaterialState

| 项 | 值 |
|---|---|
| 触发阈值 | 内容累计滚动 **10dp** |
| 淡入 | `folmeSpring(dampingRatio = 1.0, response = 0.6)` |
| 淡出 | `folmeSpring(dampingRatio = 1.0, response = 0.4)` |
| 输出 | `alpha`（0–1）与 `shadowAlpha` |
| 读取时机 | **绘制期/布局期**读 `currentHeightPx`、组合期只读 `alpha` 状态 |

`folmeSpring` 的 stiffness 由 response 换算：`stiffness = (2π / response)²`。别用 tween，回顶时会"顿一下"。

## 5 分段胶囊 CapsuleSegmentedControl

| 项 | 值 |
|---|---|
| 容器 | 42dp 高，全圆角，玻璃（`Common_Small_Regular` 近亲：edge 18） |
| 停靠底 | 浅 `#FFFFFF` / 深 `#242424`；有材质时叠在玻璃上 |
| 文字 | 14sp，80% 黑白 |
| 选中滑块 | 34dp 高（−8dp），宽 = 格宽 −1dp（`Inset` 0.5 ×2） |
| 滑块色 | 浅 黑 6% / 深 白 10% |
| 内边距 | 左右各 4dp（`padPx`） |
| 滑块运动 | 左右边界两条弹簧，位移中先撑开再收回；拖尾上限 20dp、增益 4×、低通 0.55 |
| 手势 | 抓滑块半格宽比例 0.55；快甩 420dp/s 补一格；按压四周缩 2dp，`PressScale = 78/56` |
| 材质 | 与所在页顶栏读同一 `TopBarMaterialState`（否则与返回键差一帧） |

用于：时间范围筛选、视图切换、"开发进度"。别用它做三态以上复杂筛选（超过 4 格文字会挤）。

## 6 底栏 LiquidBottomTabs + 圆钮

```
[ 56dp 胶囊：tab × N，每格占屏 21% ]  10dp  [ 56dp 圆钮 ]
```

| 项 | 值 |
|---|---|
| 容器高 | 56dp；圆钮 56dp（同高） |
| 选中滑块 | 48dp 高，横向 −1dp |
| 每格宽 | 屏宽 **21%**（3 格 = 63% 的密度） |
| 图标 | 26dp 左右，浅黑 85% / 深白 85% |
| 标签 | 11sp，与图标同色（80% `onSurfaceContainer`） |
| 底 | 浅 `#FAFAFA` @50% / 深 `#242424` @60%（`solidSurfaceAlpha`）；无材质档 100% |
| 间距 | 10dp，**两块独立玻璃**，不做融合 |
| 浮起 | 底 = `max(navBarInset + 2dp, 22dp)` |
| 内容预留 | `56dp + bottomFloatingPadding()` |

规则：
- 胶囊与圆钮是**两块玻璃**，各自的 shader key 必须分开（尺寸不同）。
- 圆钮是"设置"入口，与 tab 同高、同在一条水平线；不要用 FAB 60dp。
- 平板不用底栏，改侧栏（见 `page-patterns.md`）。
- 运行中切换 tab：滑块用 `spring(stiffness = 320)`，手势落页用 300。

## 7 卡片 Card

| 项 | 值 |
|---|---|
| 圆角 | 20dp 连续曲率 |
| 底色 | `surfaceContainer`（浅白 / 深 `#242424`） |
| 内容色 | `onSurfaceContainer` |
| 内边距 | `InsideMargin` 默认 0，**实际由调用方给 16dp** |
| 高度补间 | `spring(dampingRatio=0.9, stiffness=StiffnessMediumLow)`，首帧不播 |
| 点击 | `clickable` / `combinedClickable`（长按）；按压反馈走 `InteractionSource` + Sink/Tilt，是否涟漪由传入的 `indication` 决定 |

用法：
- 分组结构：`Card(insideMargin = PaddingValues(0.dp))` 里纵向堆多个 `BasicComponent` / 设置行，**不画分隔线**（Nexio 的设置页就是靠 16dp 行内边距与分组间距区分；`dividerLine` 只在确实需要强分隔的表单/详情里用）。
- 卡片内不要再套卡片；需要分层用 `surfaceContainerHigh` 或玻璃。
- 卡片不投影。

## 8 设置行 BasicComponent

| 项 | 值 |
|---|---|
| 内边距 | 16dp（`BasicComponentDefaults.InsideMargin`） |
| 标题 | `headline1` 17sp Medium，`onBackground` |
| 摘要 | `body2` 14sp，`onSurfaceVariantSummary`（浅 60% 黑 / 深 50% 白） |
| 末端动作 | 箭头/值 `onSurfaceVariantActions`（40%） |
| 开关 | `Switch`，主色 `primary`，禁用 `disabledPrimary` |
| 图标块 | 28dp 连续圆角 **8dp**，图标 17–22dp |
| 行高 | 内容驱动，通常 56dp |

分组：
- `SmallTitle`（14sp Bold，`#8F9CAE`）在组上方，内边距 12dp/8dp；有壁纸时加 12px 模糊阴影。
- 组与组间距 **12dp**；页面左右 16dp（平板 20dp）；底部 60dp 或 `原生栏 inset + 24dp`。
- 行文字与图标垂直居中；图标与文字间距 8dp。

## 9 课程/内容卡 CourseCard

| 项 | 值 |
|---|---|
| 圆角 | 10dp（平板 ×1.3 ≈ 13dp） |
| 内边距 | 水平 4dp / 垂直 6dp |
| 着色 | 课程色 tint + 表面色 `compositeOver`，`cardSurfaceAlpha` 可调 |
| 描边 | 进行中 2dp 呼吸描边；普通卡 1dp 以内、饱和度过低时用黑白 8–10% |
| 文字 | 名称 12–13sp Medium；地点/教师 10–11sp；非本周 28–45% alpha |
| 角标 | 4dp 圆角 chip，底色 = 文字色 10%，内边距 4/1dp |
| 状态点 | 8dp 圆点，右下角，内边距 5dp（平板 6dp） |
| 拖拽 | 水平 slop 5dp 起判；拖起时原卡 alpha → 0 |
| 玻璃 | 有壁纸时才挂 `softGlassBackdrop`（radiusPx = 卡圆角，sigma = `smallBlurRadius`） |

内容是"卡"不是"表"时（记账流水、待办、歌单）沿用同一套：10dp 圆角、4/6dp 内边距、右上角状态、底部一行弱信息。列表页卡片之间留 2dp，靠表面色区分。

## 10 弹层：底表 / 对话框 / 菜单

| 组件 | 关键值 |
|---|---|
| BlurBottomSheet | 拖拽把手：命中区 22dp、可视条 4dp、圆角 2dp；顶部圆角随屏幕圆角；detent 高度由内容决定 |
| Dialog | 贴底时底角 = `屏幕圆角 − 外边距`，下限 **32dp**；四角连续曲率 |
| 遮罩 | `windowDimming` 浅 30% / 深 60% |
| 下拉菜单 / 级联 | 圆角 **16dp**；展开时从触发按钮"长大"（morph，见 motion） |
| Snackbar | 内边距 12dp，胶囊形，浮在底栏之上一个 `bottomFloatingPadding` |

弹层玻璃：面板型用 `TokenTone` + `ThemeFill`，保证文字可读；不要用 `NoneFill` 的纯透玻璃承载长文本。

## 11 按钮

| 类型 | 参数 |
|---|---|
| 主按钮 | `Button`，`MinHeight 40dp`，内边距 16/13dp，胶囊，`primary` 底 + `onPrimary` 字；外观页"应用"即此 |
| 次按钮 | 同形，`secondary` 底（浅 `#F4F4F4`）；外观页"取消"实际用玻璃胶囊 |
| 图标按钮 | `IconButton` 40dp |
| 危险按钮 | `error` 底 + `onError` 字；外观页右下红色圆形"×"即此 |
| 胶囊图标按钮（底栏圆钮） | 56dp，见 §6 |
| FAB | 60dp（Miuix 默认），本项目基本不用，改用底栏圆钮 |

按钮文字 17sp；两字按钮不设最小宽，靠 16dp 内边距撑开。

## 12 空态 / 加载

- 空态：`title2` 标题 + `body2` 说明 + 一个主按钮，垂直居中，图标 64dp 可选。
- 加载：骨架块用 `surfaceContainerHigh`，圆角与真实内容一致（不要用圆角矩形冒充卡片）。
- 列表刷新：下拉的指示器用主色，位移与卡片入场同一弹簧族。

## 13 图标

- 用 Miuix 图标集（`MiuixIcons.Basic` / `.Normal` / `.Extended`），线宽与 HyperOS 一致；**不要混用 Material Icons**。
- 同一屏幕内图标尺寸不超过 3 档（24 / 26 / 28）。
- 图标与文字不用"色块底 + 白图标"以外的强调方式；色块底圆角 8dp。

## 14 交互与可访问性

| 项 | 做法 |
|---|---|
| 命中区 | 视觉 42dp 的圆钮，命中区补到 ≥48dp（`minimumInteractiveComponentSize` 或外层 padding）；行 56dp 达标；分段 42dp 高度偏小，靠横向宽度补偿，别再缩小 |
| 无障碍语义 | 纯图标按钮必须 `contentDescription`；`Role.Button`；卡片用 `isTraversalGroup` 让读屏先读标题再读详情 |
| 对比度 | 玻璃上文字用 `100% onSurface` 或白 90%，不用 60% 摘要色压玻璃；`NONE` 档必须复查对比度 |
| 触感 | 确认类用 `Confirm`（顶栏按钮、主操作、底栏 tab）、滚动/滑块用 `TextHandleMove`、长按用 `LongPress`；提供全局开关 |
| 焦点 | 桌面/键盘：focus ring 用 2dp `primary` 描边（连续曲率），不改变几何 |
| 动画降级 | 系统"减少动态效果" → 入场只保留 80ms alpha，去掉位移/缩放/模糊；玻璃降 `FROSTED` |
| 文案 | 标题短、摘要一行；玻璃上的字不换行超过 1 行（折射会切字） |

## 15 图表 / 数据可视化（记账、待办等衍生页面）

项目本身没有图表，以下**不是源码内容**，是按同一套令牌推导的约束，供记账/待办等衍生页面使用：

- 网格线 `dividerLine` 0.75dp；坐标轴文字 `footnote1` 13sp `textAction`。
- 主序列 `primary`，对比序列用马卡龙课程色的去饱和版（`HSL` 同亮度），最多 5 条。
- 柱/环的圆角与卡片一致（内圆角 = 外圆角 − padding），不要用 0 圆角柱子。
- 数值用 `title3` 20sp 半粗 + 单位 `footnote1` 13sp；涨跌不要只靠红绿，配箭头/文字。
- 图表卡不做玻璃（折射会让色带失真），用 `surfaceContainer`；浮在壁纸上的概览小卡才用玻璃。
