# 动效 Motion

全部参数摘自 `OobeMotion.kt` / `MorphTransition.kt` / `TextMotion.kt` / `CardReveal.kt` / `InteractiveHighlight.kt` / `CapsuleSlider.kt` / `TopBarMaterial.kt`。**只改数值不改结构**时按本表对表；不理解某条就先用默认。

## 1 曲线库（OobeMotion）

Compose 侧用 `Easing { fraction -> … }` 手写，Web 侧对应值见右列。

| 名称 | 公式 | CSS 近似 | 用途 |
|---|---|---|---|
| `OobeQuadraticOutEasing` | `1-(1-t)²` | `cubic-bezier(.25,.46,.45,.94)` | 退出/收起 |
| `OobeCubicOutEasing` | `1-(1-t)³` | `cubic-bezier(.215,.61,.355,1)` | 退出主用 |
| `OobeQuartOutEasing` | `1-(1-t)⁴` | `cubic-bezier(.165,.84,.44,1)` | 入场主用（morph 展开） |
| `OobeFifthpowerOutEasing` | `1-(1-t)⁵` | `cubic-bezier(.23,1,.32,1)` | 位移主用（trans 展开） |
| `OobeQuartOutSoftStartEasing` | 前 48%（k=0.48）先加速、之后四次缓出 | — | 大位移起步不"猛" |
| `SecondaryPageExitEasing` | `CubicBezier(0.36, 0.18, 0.3, 0.85)` | 同左 | 二级页出场 |
| `CustomizePageEasing` | `CubicBezier(0.3, 0.5, 0.2, 1.0)` | 同左 | 外观页（开洞）进出 |
| `FastOutSlowInEasing` | 标准 | `cubic-bezier(.4,0,.2,1)` | 文字换字、卡片入场 |

**弹簧换算**：`folmeSpring(damping, response)` 的 stiffness = `(2π / response)²`。response 0.6s → ≈109.7；0.4s → ≈246.7。Compose 的 `spring(stiffness=…)` 直接用这个数。

## 2 弹簧总表

| 场景 | 参数 | 备注 |
|---|---|---|
| 顶栏材质淡入 | `dampingRatio=1.0, response=0.6s`（stiffness≈110） | 无回弹，宁慢不弹 |
| 顶栏材质淡出 | `dampingRatio=1.0, response=0.4s`（≈247） | 退出要更快 |
| 按压高光 / 按下进度 | `dampingRatio=0.5, stiffness=300`，阈值 0.001 | `InteractiveHighlight` |
| 高光位置跟随 | 同上，阈值 `Offset(0.001,0.001)` | 手指拖动时光斑追手 |
| 拖动位移 / 拉伸 | 同 spring + `stretchRatio=0.012`、`translationDamping=0.032` | `computeDragTransform` |
| 卡片高度补间 | `dampingRatio=0.9, stiffness=StiffnessMediumLow` | 首帧不播，高度是布局量必须 spring |
| 底栏切 tab | `spring(stiffness=320)` | 点选 |
| 底栏手势落页 | `spring(stiffness=300)` | 松手吸附 |
| 侧栏展开 | 与切页同族（spring） | 面板宽度动画 |
| 滑块边界（分段/底栏） | 左右两条独立弹簧，位移中撑开再收回 | `CapsuleSelector` |

## 3 时长总表

| 场景 | 时长 | 曲线 |
|---|---|---|
| 卡片入场 | **260ms** | FastOutSlowIn |
| 卡片退场 | **200ms** | FastOutSlowIn |
| 卡片入场错开 | 首张 **120ms**，之后每张 **+56ms** | — |
| 文字换字（交叉） | **320ms** | FastOutSlowIn |
| 文字模糊攻击 | **140ms**（重复触发最少 40ms） | 已在模糊中：LinearOutSlowIn；从清晰：FastOutSlowIn |
| 文字模糊释放 | **180ms** | FastOutSlowIn |
| 卡片→全屏 morph 展开 | **540ms** | 四次缓出（`OobeQuartOut`） |
| morph 位移 | **500ms** | `MorphTransOpenEase`（五次缓出） |
| morph 收起 | **320ms** | 三次缓出 |
| 手势拖拽松手落位 | **180ms**（settle） / **140ms**（release） | — |
| 外观页遮盖保持 | 32ms（hold）+ 400ms（scale）+ 120ms（fade） | CustomizePageEasing |

## 4 入场/退场的"质感三件套"

卡片、列表、弹层入场统一用这三个量，缺一个就像"网页 fadeIn"：

| 量 | 值 |
|---|---|
| 位移 | 从 **下方 8dp** 上浮到 0 |
| 缩放 | **0.97 → 1.0** |
| 模糊 | **12dp → 0**（`RenderEffect` 可用时；不可用就省掉，不做假模糊） |

文字换字：**模糊 8dp** + 交叉淡入淡出，最大并发 48 个字块（超出直接切换，防止长列表滚动时炸 GPU）。`LocalTextMotionInstant = true` 可让某段文字**不做**模糊交叉（例如一周 7 个日期同帧全变，一起糊反而像闪帧）。

## 5 卡片⇄全屏 morph（可预测返回）

用于"点卡片 → 详情页"且要能手势返回到卡片：

- 起止状态：卡片 bounds → 全屏（或反向）。半径从卡片圆角插值到**设备屏幕圆角**，并做圆角补偿 `radius/scale`。
- 展开 540ms 四次缓出；位移单独 500ms 五次缓出（位移比尺寸"晚一点到"，收尾更稳）。
- 收起 320ms 三次缓出；边缘按起点方向裁切（LEFT / RIGHT / NONE 三种边缘）。
- 手势返回：滑动位移映射到 `gesture` 进度，松手按速度决定回弹或补齐；`PREDICTIVE_BACK_SCALE = 0.4`、`PREDICTIVE_ANCHOR_SHIFT = 1.0`（预测返回时锚点与缩放的基准）。
- 中途可打断：`Animatable` 从当前值继续，不要 `snapTo` 后重播。

## 6 切页与滚动

| 场景 | 规则 |
|---|---|
| 顶部 tab 页切换（今日⇄课程表） | 跟手 `HorizontalPager`；点选用 320 弹簧，手势落页 300 |
| 翻周 | 星期行文字带按"动画中的列数"摊开/收拢（5↔6↔7 天），课表网格瞬时重排 |
| 列表滚动 | 顶栏材质 10dp 阈值；回顶归零，不清零则永远"有材质" |
| 大标题折叠 | 顶栏高度随滚动连续插值，标题缩放/淡入按高度比例；不要用两态切换 |
| 过度滚动 | 允许 overScroll 拉伸；分段胶囊读 `LocalOverScrollState` 让滑块随过滚轻微位移 |

## 7 拖尾与手势物理（分段胶囊 / 底栏）

| 参数 | 值 |
|---|---|
| 拖尾上限 | 20dp |
| 拖尾增益 | 4×（原系统 `min(4 × 单帧位移, 60px)`） |
| 一阶低通 | 0.55（直接吃每帧 dx 会哆嗦） |
| 抓滑块判定 | 半格宽 0.55 以内算抓滑块，以外算点格 |
| 快甩阈值 | 420dp/s，超过即补一格 |
| 按压收缩 | 四周各 2dp（总量 4dp），`PressScale = 78/56 ≈ 1.393` |
| 到位阈值 | 0.001 |
| 方向判定 | `trailVelocity > 0.5 → 1`，`< -0.5 → -1`，之间 0 |

禁止：把拖尾做成"整块跟随"（那是 Material 的 indicator）；Nexio 的拖尾是**先撑开再收回**的橡皮筋。

## 8 触感

| 动作 | 类型 |
|---|---|
| 顶栏按钮、主操作、切换确认 | `HapticFeedbackType.Confirm` |
| 滑块落格 / tab 切换 | `TextHandleMove`（轻） |
| 危险操作 | `LongPress` |
| 全局开关 | 主题里有 `LocalHapticFeedback` 门控，关闭后所有组件不再震 |

## 9 可访问性 / 降级（本节是**落地建议**，非源码常量；前三项是必须处理的平台事实）

1. **减少动效**：系统开启"移除动画"时，入场时长 → 0，只保留透明度切换；morph 退化为淡入淡出。
2. **无 RenderEffect**（API<31 或桌面某些后端）：去掉模糊量（卡片入场不模糊、文字换字只交叉、顶栏用假渐进模糊），其它参数不变。
3. **无 RuntimeShader**（API<33）：玻璃降 `NONE` 或 `FROSTED`；不要保留"半套折射"。
4. **低端机（建议值）**：卡片错开延迟减半、并发文字块上限降到 16；顶栏材质弹簧 response 加到 0.8s 以减少重绘。
5. 动效**不得**阻塞首帧：入场动画首帧就画最终布局（`animateEnter=false` 时直接 p=1），避免"先空白再出现"。
