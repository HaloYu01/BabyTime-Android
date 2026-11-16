# Compose 落地指南 Implementation Guide

给已在 Compose Multiplatform / Android Compose 上做项目的落地顺序与坑。**先读 `glass-material.md` 的参数，再按本文接线。**

## 1 依赖与版本匹配

| 依赖 | 版本（快照） | 说明 |
|---|---|---|
| Kotlin | 2.4.10 | 含 Compose 编译插件 |
| Compose Multiplatform | 1.12.0 | 桌面/iOS 走 CMP；Android 映射回 AndroidX Compose |
| Compose BOM（Android） | 2026.05.01 | 统一 AndroidX 版本 |
| Miuix（`top.yukonga.miuix.kmp`） | **0.9.4** | `miuix-ui` / `miuix-preference` / `miuix-icons` / `miuix-blur` |
| Miuix Navigation3 | **0.9.3**（独立版本线，maven 无 0.9.4） | 导航 |
| Material3 | 1.5.0-alpha19 | 需要 `MotionScheme` 公开 API |
| material-color-utilities | 4.1.1 | Miuix 主题的取色依赖 |
| softglass | **0.1.1**（JitPack，独立仓库） | 玻璃引擎；本地有 `../softglass` 时走复合构建 |

**硬约束**：Miuix 必须与 CMP 版本**成对升级**。0.9.3 是用 Compose 1.11.1 构建的，在 CMP 1.12.0 的 skiko 0.150.1 上会 `NoSuchMethodError`（`Image.makeShader` 的 `Matrix33` 签名变了）。桌面端是第一个真跑 skiko 的目标，最先炸。

## 2 主题接线（顺序不能错）

```kotlin
@Composable
fun NexioGlassTheme(
    level: NexioMaterialLevel,      // SOFT / FROSTED / NONE
    isDark: Boolean,
    screenCorner: Dp?,              // 设备圆角，可空
    content: @Composable () -> Unit,
) {
    MiuixTheme(colorScheme = if (isDark) darkColorScheme() else lightColorScheme()) {
        CompositionLocalProvider(
            LocalAppSettingDark provides isDark,
            LocalScreenCornerRadius provides screenCorner,
            LocalMaterialNoneEnabled provides (level == NONE),
            LocalGlassBlurDp provides level.blurDp,
            LocalGlassPanelBlurDp provides level.panelBlurDp,
            LocalGlassDialogBlurDp provides level.dialogBlurDp,
            LocalGlassSurfaceAlphaDrop provides level.alphaDrop,
            // …其它 Local（见 design-tokens §7）
        ) {
            MaterialTheme(/* 只为兼容依赖 Material 的库 */) {
                // ★ 必须写回，否则 MaterialTheme 会把它们覆盖掉
                CompositionLocalProvider(
                    LocalIndication provides MiuixIndication,
                    LocalTextStyle provides MiuixTheme.textStyles.main,
                ) { content() }
            }
        }
    }
}
```

为什么最后要写回：`MaterialTheme` 会用 `ripple()` 覆盖 `LocalIndication`、用 `bodyLarge` 覆盖 `LocalTextStyle`。不写回 → 所有 Miuix 组件失去按压反馈、行高错乱。这是"看起来都换了主题但还是不对"的最常见原因。

**不要**在页面里再套 `MaterialTheme`；需要 Material 组件时只借组件，不借主题。

## 3 材质档位与持久化

| 用户档 | 枚举 | 行为 |
|---|---|---|
| 最佳（best） | `SOFT` | 完整柔光：折射 + 方向光 + 模糊 |
| 均衡（balanced） | `FROSTED` | 模糊 + 实底，**关折射与方向光**（冷启动默认） |
| 关闭（none） | `NONE` | 无 shader、实底 + 0.8dp 描边 |

- 存量键名沿用 `best` / `balanced` / `none`，不要改名。
- 平台能力不足时**自动降级**（API<31 无 RenderEffect → 无模糊；API<33 无 RuntimeShader → 无折射），但 UI 上的档位选择不自动改，避免用户设置"跳变"。
- 三档模糊值都是 6/12/12dp；差异只在折射/方向光/实底。不要给 `NONE` 留一点点模糊，那会变成"半套玻璃"。

## 4 采样层接线

```kotlin
val backdrop = rememberLayerBackdrop()
Box {
    // 内容层：被录制
    Box(Modifier.fillMaxSize().layerBackdrop(
        backdrop,
        recordKey = uiState.version,                 // 覆盖所有会改变像素的因素
        mustRecord = { scrollBehavior.state.heightOffset != last }, // 绘制期求值
    )) { PageContent() }

    // 顶栏层：不录制，只画玻璃带与按钮
    TopBarLayer(backdrop)
}
```

| 规则 | 原因 |
|---|---|
| 采样层只包内容 | 采到自己会形成反馈、且第一次绘制时层为空 |
| `recordKey` 必填且覆盖全部变化源 | 给 `null` = 每帧重录（滚动掉帧）；给错 = 玻璃停在旧帧 |
| `mustRecord` 只在绘制期读状态 | 组合期读 `heightOffset` 会每帧重组 |
| 壁纸与页面叠玻璃 | 用 `rememberCombinedBackdrop(wallpaperLayer, pageLayer)` |
| 玻璃上再叠玻璃 | 不要互采，改用明暗叠层 |

## 5 玻璃 Modifier 的两种用法

```kotlin
// A. 静态壁纸路径（开销最低）：预先算一张"壁纸在此位置的样子"
val surface = rememberGlassSurface(bitmap, scale, offset, screenWpx, screenHpx, spec, origin)
Image(surface.image, Modifier.softGlass(surface, style, circle = false, radiusPx = 20.dp.toPx()))

// B. 实时采样路径（内容会滚/会动时）
Box(Modifier.drawBackdrop(
    backdrop = backdrop,
    shadow = null,
    shape = { ContinuousRoundedRectangle(20.dp) },
    effects = {                     // 必须 remember，不能每帧新建 lambda
        blur(6.dp.toPx())
        runtimeShaderEffect(key = "NexioSoftGlassLiveCard_${w}x${h}", shader = SOFT_GLASS_LIVE_SHADER) {
            applySoftGlass(style, width = size.width, height = size.height)
        }
    },
    layerBlock = { alpha = backdropAlpha },   // 进离场
    onDrawSurface = null,                     // 有材质档：不叠实色（会盖住折射）
))
```

要点：
- `effects` / `shape` / `onDrawSurface` 全部 `remember`（按引用比较，每帧新建 = 每帧重录）。
- `onDrawSurface` 只在 `NONE` 档给实色。
- 进离场 alpha 走 `layerBlock`；若还有投影，外层 `graphicsLayer` 必须 `ModulateAlpha`。
- `shadow = null` 表示关闭；不传用默认 24dp/10%/y+4。

## 6 shader key 与尺寸

**同一个 key 的多块玻璃会同帧互相覆盖 uniform。** 命名规则：`NexioSoftGlassLive<用途>_<宽>x<高>` 或按固定用途（`...TopBar` / `...BottomBarPill` / `...BottomBarButton` / `...SegmentPill`）。

判断方法：两块玻璃**只要可能同帧可见且尺寸不同**，就必须不同 key；同尺寸同用途可共用。课程卡尺寸随课长变化 → key 必带 `w x h`。

## 7 相位与状态读取（最容易写成"慢一帧"）

| 数据 | 正确读取相位 |
|---|---|
| 顶栏当前高度 `currentHeightPx` | 布局期（`Modifier.layout`）或绘制期 |
| 材质 alpha | 组合期（它是 `Animatable` 状态） |
| 滚动偏移 | `scrollBehavior.state`，绘制期 |
| 屏幕尺寸 | 组合期 + 变更时重算 |
| 采样重录谓词 | 绘制期 |

症状：切 tab 时内容"慢一帧就位"、标题比内容晚出现。原因几乎都是组合期读了未测量的高度。

## 8 形状：连续曲率

```kotlin
val shape = remember { ContinuousRoundedRectangle(20.dp) }   // 不是 RoundedCornerShape
val capsule = remember { ContinuousCapsule() }
```

- 形状对象必须 `remember`，否则按引用比较的绘制层每帧失效。
- 对话框贴底时底角要跟屏幕圆角走：`(screenCorner - outsideMargin).coerceAtLeast(32.dp)`。
- Compose 的 `Modifier.shadow` / `clip(RoundedCornerShape)` 会破坏连续曲率，玻璃件不用。

## 9 性能预算

| 项 | 建议 |
|---|---|
| 同帧可见的实时玻璃件 | ≤ 6（顶栏 2 按钮 + 底栏 2 块 + 头部 1 块 = 5，已接近上限） |
| 课程卡/列表卡的玻璃 | 只给"少而大"的卡片（≤ 8 张），不要给每行 |
| 模糊半径 | 顶栏 6dp 足够；>12dp 在 iOS 掉帧明显 |
| shader program 缓存 | 32 个上限，key 数量要收敛 |
| 录制层 | 静止不录；滚动时按帧差录 |
| 首帧 | 玻璃先画"实底占位"，采样就绪后交叉 1 帧淡入，避免白块闪 |

## 10 自研替代（闭源分发时）

不想引入 AGPL 的 softglass，只沿用参数，用最少的自研实现拿到 80% 观感：

1. **模糊**：`Modifier.blur(radius)` 或 `RenderEffect.createBlurEffect`；API<31 用降采样 + 缩放近似。
2. **边缘光**：`drawWithContent` 画两层 1dp 内描边——上/左 `White 0.55`、下/右 `Black 0.18`，按 `edgeWidth` 做 alpha 渐变。
3. **厚度感**：在玻璃内侧再画一条 8–12px 的径向渐变（中心亮、边缘暗），alpha 0.06–0.12。
4. **方向光**：一张可复用的线性渐变（方向 `(-0.42, 0.74)`），`blendMode = Screen`，alpha 0.1。
5. **折射**：只有 RuntimeShader 能做。做不到就**不要假装**——关掉折射，把模糊与边缘光做扎实（这就是 `FROSTED` 档）。
6. **投影**：`Paint.setShadowLayer` / `MaskFilter` 画模糊形状，形状必须与玻璃同源（同一 shape）。

## 11 验收（换项目也照跑）

- [ ] 深/浅两套逐屏截图，颜色对 `design-tokens.md`（尤其 60%/40% 的灰阶）
- [ ] 所有转角放大 4 倍看：无折角 → 连续曲率生效
- [ ] 滚动 10dp：材质出现；回顶：材质消失，**按钮阴影同步消失**
- [ ] 快速切 tab 5 次：顶栏/按钮/底栏同帧出现，无慢一帧
- [ ] 玻璃下滚过一张彩色卡片：玻璃里应能看到它的模糊色，不是纯灰
- [ ] `NONE` 档全页可读、按钮不是"透空圆孔"
- [ ] 低端机（API 30）不崩、无 shader 编译错误
- [ ] 详情页返回手势：能回到卡片原位，中途可打断
- [ ] `grep RoundedCornerShape` = 0（玻璃与卡片范围内）

## 12 许可

NexioSchedule 与 softglass 均为 **AGPL-3.0**。复制其实现进自家项目并对外提供网络服务，需要公开对应源码；只沿用**数值与几何参数**（颜色、dp、时长、弹簧）不构成复制。闭源项目按下节 §10 自研。
