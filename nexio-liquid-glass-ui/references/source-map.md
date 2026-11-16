# 源码地图与同步 Source Map

快照版本：`HaoZai000/NexioSchedule`，`master`，commit **`28a99a3b23458a0d39741b9841c9755f5374fba2`**（2026-11）。
玻璃引擎为独立仓库 `HaoZai000/softglass`（JitPack `0.1.1`），本 skill 只记录其**参数与用法**。

## 1 结论 → 源文件

路径均相对仓库根。

| skill 中的结论 | 源文件 |
|---|---|
| 深浅两套色、全部语义色 | `miuix/src/commonMain/kotlin/top/yukonga/miuix/kmp/theme/Colors.kt` |
| 字号阶梯、paragraph 行高 1.2em | `miuix/.../theme/TextStyles.kt` |
| 组件内边距、行文字色（16dp / 60% / 40%） | `miuix/.../basic/Component.kt`（`BasicComponentDefaults`） |
| 卡片 20dp、surfaceContainer、高度 spring | `miuix/.../basic/Card.kt` |
| 小标题 14sp Bold `#8F9CAE`、12/8dp、壁纸阴影 | `miuix/.../basic/SmallTitle.kt` |
| 顶栏折叠 52dp、标题 26dp、图标 16dp | `miuix/.../basic/TopAppBar.kt`（`TopAppBarDefaults`） |
| 折叠顶栏、大标题行为 | `miuix/.../layout/CollapsibleTopAppBar.kt` |
| 渐进模糊带、tint 0.2、fade 0.88、高度规则 | `miuix/.../layout/ProgressiveBlurTopBar.kt` |
| 材质阈值 10dp、folmeSpring 0.6/0.4 | `miuix/.../layout/TopBarMaterial.kt` |
| 底表把手 22dp/4dp | `miuix/.../overlay/BlurBottomSheetDetent.kt` |
| 对话框底角 `screen - margin ≥32dp` | `miuix/.../layout/DialogContentLayout.kt` |
| 菜单/级联 16dp 圆角 | `miuix/.../layout/CascadingConstants.kt`、`CascadingMorphContent.kt` |
| 拖拽拉伸 0.012 / 阻尼 0.032 | `miuix/.../interactive/DropdownPanelDragSelect.kt` |
| 主题接线顺序、Local 下发、Material 覆盖回写 | `ui-shared/src/commonMain/kotlin/com/haooz/chedule/ui/theme/Theme.kt` |
| 课程/标签取色、Hct 映射 | `ui-shared/src/portable/kotlin/com/haooz/chedule/ui/theme/ScheduleColors.kt` |
| 材质档持久化、`NONE` 0.8dp 描边、档位→Local 映射 | `ui-shared/.../ui/utils/AppMaterialSettings.kt` |
| 模糊 6/12/12dp、alpha 降幅 0.2/0.32（`tuning()` 的实际值） | `docs/SOFTGLASS_LIBRARY_PLAN.md` §2.3（值在 softglass 的 `GlassMaterialLevel.tuning()`，App 只读取） |
| 玻璃绘制入口、光的强度 0.8/0.45、falloff 0.86 | `ui-shared/.../ui/components/SoftGlassSurface.kt`、`glass/ScheduleGlassSurface.kt` |
| 玻璃样式（Nexio 档）、三档质量 | `docs/SOFTGLASS_LIBRARY_PLAN.md` §2.3 / §4 |
| 13 档系统玻璃数值、35 档全表 | `docs/hyperos-glass-token.md` |
| 顶栏材质审计、实底与折射取舍 | `docs/topbar-material-audit.md` |
| 圆形玻璃按钮 42dp、高光分层、阴影 ×3.2 | `ui-shared/.../ui/basic/LiquidTopBarButton.kt` |
| 分段胶囊 42dp、14sp、滑块 34dp | `ui-shared/.../ui/components/CapsuleSegmentedControl.kt` |
| 滑块常量（Inset 0.5 / 8dp / 20dp / 420dp/s / 0.55） | `ui-shared/.../ui/components/CapsuleSlider.kt` |
| 滑块边界弹簧、撑开再收回 | `ui-shared/.../ui/components/CapsuleSelector.kt` |
| 底栏 56/48、gap 10、21% 宽、11sp | `ui-shared/.../ui/components/LiquidBottomTabs.kt`、`ScheduleBottomBar.kt` |
| 文档页骨架、糊带 72+72、返回键 25dp | `ui-shared/.../ui/components/DocumentPageScaffold.kt` |
| 平板侧栏 84+12、22%、200dp、600dp 断点 | `ui-shared/.../ui/components/TabletNavPadding.kt`、`TabletNavSideBar.kt` |
| 底栏浮起 `max(inset+2, 22)` | `ui-shared/.../ui/utils/BottomBarSpacing.kt` |
| 课卡 10dp、4/6dp、2dp 进行中描边 | `ui-shared/src/portable/kotlin/.../classschedule/CourseCard.kt` |
| 文字换字 320/140/180/8dp/48 | `ui-shared/src/portable/kotlin/.../components/text/TextMotion.kt` |
| 卡片入场 260/200/120/56/8dp/0.97/12dp | `ui-shared/src/portable/kotlin/.../components/CardReveal.kt` |
| morph 540/500/320、预测返回 | `ui-shared/.../ui/effects/motion/MorphTransition.kt` |
| 缓动库、外观页 32/400/120 | `ui-shared/.../ui/effects/motion/OobeMotion.kt` |
| 高光弹簧 0.5/300 | `ui-shared/.../ui/effects/liquidglass/InteractiveHighlight.kt` |
| 切页 320/300 | `ui-shared/.../ui/components/PageSwitchState.kt` |
| 依赖版本与 Miuix/CMP 匹配坑 | `gradle/libs.versions.toml`、`README.md` §技术栈 |

## 2 拉取源码

```powershell
# 仓库根在 D:\nexio-ui-skill 时
pwsh -File scripts\fetch-source.ps1 -Dest "D:\nexio-ui-skill\NexioSchedule"
```

脚本走 `codeload` 的 zip（直连 `git clone` 在国内常失败），支持 `-Branch` / `-Commit`。拉完会打印顶层目录与 Kotlin 文件数。

## 3 扫描关键常量

```powershell
python scripts\snapshot-tokens.py "D:\nexio-ui-skill\NexioSchedule"
```

输出一份"当前值"清单（颜色、52/42/56/48/20/10、320/300/260/540、10dp 阈值……）。**同步时先跑它，再与本文档/`design-tokens.md` 的数值逐条 diff**；变了就改参考文件，没变就不用动。

## 4 同步清单（按影响面排序）

| 优先级 | 改这些就要更新 skill | 检查点 |
|---|---|---|
| P0 | `Theme.kt` 的 Local 名单与接线顺序 | design-tokens §7、implementation-guide §2 |
| P0 | `Colors.kt` / `TextStyles.kt` | design-tokens §1–2 |
| P0 | `docs/hyperos-glass-token.md`、`SOFTGLASS_LIBRARY_PLAN.md` §2.3 | glass-material §2–5 |
| P1 | `AppMaterialSettings.kt` 的档位与模糊值 | glass-material §4 |
| P1 | `CapsuleSlider` / `CapsuleSegmentedControl` / `LiquidBottomTabs` | components §5–6、motion §7 |
| P1 | `OobeMotion` / `TextMotion` / `CardReveal` / `MorphTransition` | motion 全表 |
| P2 | `TabletNavPadding` / `TabletNavSideBar` | page-patterns §4 |
| P2 | `CourseCard`（课卡几何） | components §9 |
| P3 | `README.md` 依赖表、`libs.versions.toml` | implementation-guide §1 |
| P3 | 新截图进 `docs/picture/` | 复制到 `assets/preview/` 并更新 SKILL.md 索引 |

## 5 变更判定：什么算"规范变了"

- **数值微调**（如 20dp → 18dp）：只改对应表，不动结构。
- **新增组件**：在 `components.md` 加一节 + `source-map.md` 加一行；若引起"五条视觉判据"变化，才改 SKILL.md。
- **新增材质档 / 改玻璃引擎 API**：改 `glass-material.md` 与 `implementation-guide.md` 的接线段，并核对 `assets/template/nexio-tokens.json` 是否需要新增字段。
- **只改业务页面**（课表网格、教务导入流程）：**不属于 UI 规范**，不进 skill。
- **玻璃引擎内部实现**（softglass 仓库）：只在参数或 API 变动时同步；内部 shader 不进本 skill。

## 6 截图来源

`docs/picture/` 下：`主课程表.png`、`课表外观.png`、`添加课程.png`、`教务导入.png`、`课程提醒.png`、`桌面小部件.png`（已复制到 `assets/preview/`）。这些是**真机效果基准**，改完新项目拿它并排比对，比任何参数表都直接。

## 7 引用与授权

- 仓库 LICENSE：**AGPL-3.0**。设计参数（颜色、dp、时长）按事实引用；代码片段若整段移植需遵守 AGPL。
- 截图来自项目 README，仅作视觉对照；对外分发 skill 时保留出处说明。
