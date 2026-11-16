---
name: nexio-liquid-glass-ui
description: Nexio / HyperOS 4 液态玻璃（liquid glass）界面规范与落地指南：源自 NexioSchedule 课程表项目的 Miuix + Compose Multiplatform 设计系统。用于给任意新项目（课程表、记账、待办、播放器、工具类 App、平板双栏应用）套用同一套视觉语言——悬浮胶囊构件的顶栏与底栏、采样真玻璃（模糊/折射/边缘光）、连续曲率圆角、滚动即出材质、按压高光与拖尾、卡片从模糊中上浮、开洞式外观页、折叠大标题文档页、平板侧栏。也用于审查/改造已有界面使其符合该风格，或把该风格迁移到 HTML/CSS/Web 项目（近似实现）。触发词：Nexio 风格、HyperOS 4、Miuix、液态玻璃、liquid glass、柔光玻璃、squircle、连续圆角、玻璃胶囊、小米风格 UI、nexio-liquid-glass、把 Nexio 的 UI 用到我的项目。
---

# Nexio 液态玻璃 UI

NexioSchedule（HyperOS 4 风格课程表，Compose Multiplatform + Miuix + softglass）的 UI 体系。目标不是"抄一张图"，而是**让新项目拿到同一套可复现的设计决策**：构件几何、玻璃光学参数、圆角形状、动效时序、页面骨架。

## 先判断任务类型

| 用户要什么 | 走哪条路 |
|---|---|
| 新做 App / 页面，用这套风格 | 本文件 → `references/design-tokens.md` + `references/components.md` + `references/page-patterns.md`；Compose 项目再加 `references/implementation-guide.md` |
| 审查 / 改造已有界面（"太丑了，调成小米风格"） | `references/design-tokens.md` 对表 + `references/components.md` 逐件替换；只改构件与令牌，不重写业务 |
| 要真玻璃（模糊、折射、边缘高光） | `references/glass-material.md`（光学参数与降级）+ `references/implementation-guide.md`（接线与坑） |
| 网页 / HTML / 小程序 / 非 Compose | `references/web-adapter.md`（CSS 近似方案、透明度换算、明确取舍） |
| 只写动效 | `references/motion.md`（全部弹簧、缓动、时长、错开延迟） |
| 项目更新了，要同步这套规范 | `references/source-map.md` + `scripts/fetch-source.ps1` + `scripts/snapshot-tokens.py` |

## 五条不可丢的视觉判据

任何页面套完风格后，自检这五条；缺一条就会"有玻璃没灵魂"：

1. **构件悬浮在内容之上**。顶栏动作是 42dp 圆形玻璃按钮，底栏是 56dp 胶囊 + 一颗独立 56dp 圆钮，两者只留 10dp 间距。不用贴边通栏底栏、不用 48dp 圆按钮。
2. **玻璃是"采样"出来的，不是半透明色块**。玻璃面下真正模糊/折射了它脚下的壁纸或页面内容；有材质档下玻璃体不叠实色底（叠了就盖住折射），无材质档才退成实色。
3. **所有形状走连续曲率（G2 squircle）**，不用 `RoundedCornerShape`。卡片 20dp、课卡 10dp、设置图标 8dp、胶囊即全圆角。
4. **材质跟着滚动出现**。滚动过 10dp 才淡入按钮玻璃与阴影，弹簧 `damping=1.0`、显 `response=0.6s`、隐 `0.4s`；回到顶部就消失。
5. **动效是"短、准、有阻尼"**。入场 260–320ms 的多次方缓出，按压用 `damping=0.5 / stiffness=300` 的弹簧，位移带拖尾与拉伸，全部动画只读绘制期值、不进组合期。

## 快速上手（Compose，4 步）

```kotlin
// 1) 依赖：Miuix（组件与主题）+ softglass（玻璃引擎）
//    compose-miuix-ui/miuix 0.9.4（必须与 CMP 版本成对）；com.haooz.softglass:softglass:0.1.1（JitPack）
// 2) 主题：封一个 NexioGlassTheme 包住整个 App（材质档 + 深浅 + 屏幕圆角 + 触感开关）
//    注意：这是新项目要自己封的壳，不是源码里的现成 API；接线见 implementation-guide §2
NexioGlassTheme(materialLevel = NexioMaterialLevel.FROSTED) { App() }
// 3) 页面骨架：DocumentPageScaffold 式（采集层 → 内容 → 顶栏层 → 浮层）
// 4) 构件：LiquidTopBarButton / LiquidBottomTabs / CapsuleSegmentedControl / Card
```

细节见 `references/implementation-guide.md`；组件清单见 `references/components.md`。

## 令牌速查（完整表在 references/design-tokens.md）

| 项 | 浅色 | 深色 |
|---|---|---|
| 背景 background | `#FFFFFF` | `#242424` |
| 卡片/表面 surface | `#F4F4F4`（容器用 `#FFFFFF`） | `#000000`（容器用 `#242424`） |
| 主色 primary | `#3482FF` | `#277AF7` |
| 正文 onBackground | `#000000` | `#E6FFFFFF` |
| 摘要文字 | `#99000000` | `#80FFFFFF` |
| 分隔线 dividerLine | `#E0E0E0` | `#393939` |
| 底栏胶囊底 | `#FAFAFA` @50% | `#242424` @60% |
| 分段控件静止底 | `#FFFFFF` | `#242424` |
| 图标着色 | 黑 @85% | 白 @85% |
| 滑块指示 | 黑 @6% | 白 @10% |

| 几何 | 值 |
|---|---|
| 折叠顶栏高 CollapsedHeight | 52dp（展开大标题另算） |
| 圆形顶栏按钮 | 42dp，图标 24dp（默认） |
| 底栏胶囊 / 圆钮 | 56dp；选中滑块 48dp；间距 10dp |
| 分段胶囊 | 42dp 高 |
| 卡片圆角 | 20dp；内容内边距 16dp |
| 列表行高 | ≥56dp，行内边距 16dp |
| 分组间距 | 12dp；页面左右 16dp（平板 20dp） |
| 底部悬浮留白 | `max(导航栏 inset + 2dp, 22dp)` |
| 字号 | 32 / 24 / 20 / 18 / 17 / 16 / 14 / 13 / 11 sp（title1..footnote2） |

## 动效速查（完整表在 references/motion.md）

| 场景 | 参数 |
|---|---|
| 顶栏材质淡入/淡出 | `folmeSpring(damping=1.0, response=0.6 / 0.4)`，阈值 10dp |
| 按压高光 / 拉伸 | `spring(dampingRatio=0.5, stiffness=300)`，可见阈值 0.001 |
| 卡片入场 | 260ms（退场 200ms）`FastOutSlowIn`，下移 8dp、缩放 0.97、模糊 12dp，首张延迟 120ms + 每张 56ms |
| 文字换字 | 交叉 320ms，模糊攻击 140ms → 散焦 180ms，半径 8dp，并发上限 48 |
| 卡片⇄全屏 morph | 展开 540ms（位移 500ms，四次/五次缓出），收起 320ms |
| 切页 | 点选 `spring(stiffness=320)`，手势落页 `spring(stiffness=300)`，阻尼无回弹 |
| 拖尾 | 增益 4×、一阶低通 0.55、上限 20dp；快甩阈值 420dp/s |
| 缓动 | 三次/四次/五次缓出；外观页 `cubic-bezier(.3,.5,.2,1)`；二级页出场 `cubic-bezier(.36,.18,.3,.85)` |

## 交付前检查清单

- [ ] 所有圆角都是连续曲率（squircle），没有 `RoundedCornerShape` 残留
- [ ] 有壁纸/滚动内容的页面，玻璃下真是模糊内容，不是 `Color.copy(alpha=.5)`
- [ ] 玻璃件之间不共用 shader key（尺寸不同必须分开，否则同帧 uniform 互相覆盖）
- [ ] 玻璃件的进离场 alpha 用 `graphicsLayer` + `CompositingStrategy.ModulateAlpha`，否则投影被裁掉
- [ ] 顶栏与页面头部构件读**同一个**材质状态（同帧出现）
- [ ] 无材质档（API<31 / 用户选择）下页面仍成立：实色面、收窄模糊带、不带折射
- [ ] 文字、图标着色在深浅两套都按上表取 alpha，不写死黑色
- [ ] 按压有触感反馈（确认/落项用 `Confirm`、`TextHandleMove`），且可全局关闭

## 参考文件

| 文件 | 内容 |
|---|---|
| `references/design-tokens.md` | 颜色（浅/深全表）、字号、几何、圆角、间距、透明度约定、壁纸处理 |
| `references/glass-material.md` | 13 档系统玻璃参数、默认档、三档质量、模糊半径、降级策略、性能与缓存规则 |
| `references/components.md` | 顶栏、按钮、分段胶囊、底栏、卡片、设置行、弹层、菜单、课程卡、空态 |
| `references/motion.md` | 全部弹簧/缓动/时长、手势物理（拖尾、快甩、吸附）、可访问性降级 |
| `references/page-patterns.md` | 首页、文档页、设置页、平板侧栏与双栏、开洞式外观页、导入/分享弹窗骨架 |
| `references/implementation-guide.md` | Compose 落地：依赖、主题接线顺序、采样层契约、重绘信号、常见坑 |
| `references/web-adapter.md` | 非 Compose 场景的 CSS 近似方案与取舍 |
| `references/source-map.md` | 每条结论对应的源文件路径、快照版本、同步清单 |
| `assets/preview/` | 6 张真机界面截图（主课表 / 外观页 / 添加课程 / 教务导入 / 提醒 / 小部件）+ 样张页浅/深两种渲染 |
| `assets/template/` | `nexio-tokens.css`、`nexio-tokens.json`、`NexioTokens.kt`（纯常量）、`specimen.html`（令牌与构件预览页，浏览器直接打开） |
| `scripts/` | `fetch-source.ps1`（拉取源码快照）、`snapshot-tokens.py`（扫出关键常量，供同步比对） |

## 来源与许可

规范来自 `HaoZai000/NexioSchedule`（AGPL-3.0，快照 commit `28a99a3`，见 `references/source-map.md`）。**尺寸、颜色值、时序参数属于事实性设计数据，可直接用于任意项目**；若整段复制其 Kotlin 实现进自己的项目，须遵守 AGPL-3.0（网络分发也要提供对应源码）。需要闭源分发时，按 `references/implementation-guide.md` 的"自研替代"路线重写玻璃引擎，只沿用参数。
