# 液态玻璃材质 Glass Material

"柔光玻璃"是一套**采样真背景 + 折射 + 边缘光**的渲染管线，不是 `Color.copy(alpha)` 叠层。引擎在独立仓库 `HaoZai000/softglass`（`com.haooz.softglass:softglass:0.1.1`，JitPack）；本文只给**使用口径与参数**，引擎内部（金字塔模糊、AGSL/SkSL、SDF 圆角）不在本 skill。

## 1 三层概念，别混

| 层 | 是什么 | 谁来决定 |
|---|---|---|
| `GlassSpec` | 一份完整渲染参数（style + tone + fill） | 应用按场景挑（卡片 / 顶栏 / 底栏 / 浮层各一份） |
| `GlassToken` | HyperOS 4 系统原值 13 档 | 只在"想贴近系统某个原件"时用 |
| `GlassMaterialLevel` | 质量三档 `SOFT` / `FROSTED` / `NONE` | 用户设置 + 平台能力 |

```kotlin
SoftGlassTheme(preset = GlassPreset.Nexio, level = level, isDark = isDark) { App() }
// 组件侧只读 Local，不再自己算：LocalSoftGlassLayer / LocalGlassBlurDp / LocalMaterialNoneEnabled …
```

## 2 默认档 GlassPreset.Nexio（App 全站基准）

| 字段 | 值 | 说明 |
|---|---|---|
| edgeWidth | **60** px | 倒角带宽度 |
| thickness | **96** px | 玻璃厚度（折射偏移量） |
| saturation | **2.0** | 背景饱和度（要通透就 >1） |
| smallBlurRadius | **32** px | 玻璃面自身模糊 |
| bigBlurRadius | **500** px | 背景大模糊 |
| refractIOR | **3.0** | 折射率，全族统一 |
| lightDirection | **(-0.42, 0.74, -1.15)** | 光方向（左上偏前） |
| lightIntensity / opposite | **0.8 / 0.45**（App 侧 ScheduleGlassSurface） | 正面光强 / 反向光强 |
| angleRange | **1.0**（App 侧 1.78） | 方向光角度范围 |
| edgeLightFalloff | **0.86** | 边缘光衰减 |
| colorPow | 1.2 | 内色幂 |
| reflectionLighten / Strength | 1.0 / 0.8 | 反射提亮 / 强度 |
| darker | 0（App 侧浮层 0.2） | 压暗量 |

> `edge` / `thickness` / `reflectOffset` / `smallBlur` / `bigBlur` 的**单位是 px，不是 dp**。换算 `px = dp * density`，但样式表本身按 px 写。

**与系统档 `Common_Large_Regular` 故意不同**：系统档是 50 / 80 / 2.2 / 80 / 1.4，Nexio 档是 60 / 96 / 2.0 / 32 / 1.0。不要"对齐"两者。

## 3 基调与填充

### 3.1 GlassTone 三档

| 基调 | 含义 | 用在哪 |
|---|---|---|
| `TokenTone` | darker 0.08，深紫黑基调（最贴系统） | 大面板、需要压暗保证文字可读：底栏、弹层、菜单 |
| `BrightTone` | 纯黑基调、不额外压暗 | **只有图标的圆形按钮**（压暗会让它在浅色页上变灰块） |
| `BrightLargeTone` | edge 75 / thickness 120 | 更大的亮面（大号浮层、外观页预览框） |

### 3.2 GlassFill 四策略

| 策略 | 深色 | 浅色 | 说明 |
|---|---|---|---|
| `NoneFill` | — | — | 完全透出玻璃色，最通透 |
| `ThemeFill` | 0.45 | 0.55 | 跟主题表面色，默认按钮用 |
| `BarFill` | 0.45 | 0.55 | 底栏/bar 语义，与 ThemeFill 同值但语义分开 |
| `CustomizeFill` | 0.55 | 0.65 | 自定义实底 |

所有 fill 都钳 `saturation ≤ 2.0`，避免叠色后背景变脏。

## 4 质量三档（用户可切换，也是平台降级）

| 档位 | UI 名 | 模糊 blur/panel/dialog | 底色 alpha 降幅（浅/深） | 折射 | 方向光 | 描边 |
|---|---|---|---|---|---|---|
| `SOFT` | 柔光玻璃（完整） | 6 / 12 / 12 dp | 0.20 / 0.32 | 开 | 开 | 无（shader 自带边缘光） |
| `FROSTED` | 磨砂玻璃（默认） | 6 / 12 / 12 dp | 0.20 / 0.32 | **关** | **关** | 无 |
| `NONE` | 无材质 | 0 | 1.0（实底） | 关 | 关 | **0.8dp 纯色描边，SrcOver** |

要点：
- 三档模糊数值一致，差异在折射/方向光与实底；`FROSTED` 是冷启动默认。
- `NONE` 下玻璃层不跑 shader，必须补 `onDrawSurface = { drawRect(containerColor) }`，否则按钮变成"透空圆孔"。
- 平台门禁内置：Android API 31 才有 RenderEffect（模糊），API 33 才有 RuntimeShader（折射）。低于门禁自动降 `NONE`；不要在调用点判断。
- 有材质档时，玻璃体**不叠实色底**（`onDrawSurface = null`），只在玻璃外再画一层"容器色 alpha"会盖住折射。

## 5 13 档系统玻璃（GlassToken）

三族：`Bionic_Medium_*`（仿生）、`Common_{Small,Medium,Large}_*`（常规）、`Tint_*`（彩色）。全族统一：`ior 3.0`、`angleRange 1.4`、`reflectionLighten 1.0`、`reflectionStrength 0.8`、`colorPow 1.2`、`luminanceValues [0,2,0.5,0.8]`、`darkerRange [0.6,1.0]`、`innerColor [1,1,1,0.15]`、`direction [-0.4,0.6,-0.8]`、`pressRingStrength [0,0]`。

| 档位 | edge | thick | reflOff | inten | opp | satur | brigh | darker | cWhite | cMix | bgSat | burn | sBlur | bBlur |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Bionic_Medium_Thin | 60 | 60 | 1000 | 1.2 | 0.8 | 1.4 | 0.08 | 0.20 | 0.15 | 0.40 | 2.4 | 0.0 | 40 | 500* |
| Bionic_Medium_Normal | 60 | 80 | 1200 | 1.6 | 0.8 | 1.4 | -0.02 | 0.30 | 0.20 | 0.30 | 2.6 | 0.0 | 120 | 120 |
| Bionic_Medium_Regular | 60 | 80 | 600 | 2.6 | 1.2 | 1.8 | -0.18 | 0.10 | 0.16 | 0.30 | 2.0 | 1.0 | 36 | 500* |
| Bionic_Semibold_Motion | 60 | 80 | 1200 | 3.0 | 2.0 | 2.0 | -0.02 | 0.30 | 0.15 | 0.90 | 2.6 | 0.0 | 120 | 120 |
| Common_Small_Regular | 18 | 100 | 110 | 1.1 | 0.5 | 1.4 | 0.14 | 0.20 | 0.30 | 0.50 | 1.0 | 0.0 | 8 | 500* |
| Common_Small_Bold | 60 | 80 | 1200 | 1.6 | 0.8 | 1.4 | 0.28 | 0.40 | 0.20 | 0.30 | 2.6 | 0.0 | 120 | 120 |
| Common_Medium_Thin_Low | 60 | 60 | 600 | 1.2 | 0.8 | 1.5 | 0.20 | 0.10 | 0.00 | 0.30 | 1.0 | 0.0 | 36 | 500* |
| Common_Medium_Regular_Dark | 60 | 80 | 600 | 2.4 | 1.6 | 3.0 | 0.20 | 0.00 | 0.00 | 0.80 | 0.0 | 0.0 | 36 | 500* |
| Common_Large_Regular | 50 | 80 | 600 | 1.6 | 0.8 | 2.2 | 0.08 | 0.20 | 0.15 | 0.40 | 0.0 | 0.0 | 80 | 500* |
| Common_Large_Demibold | 50 | 80 | 600 | 2.0 | 1.0 | 2.0 | 0.18 | 0.26 | 0.60 | 0.90 | 0.0 | 0.0 | 50 | 500* |
| Tint_Purple | 60 | 80 | 600 | 1.4 | 1.0 | 1.0 | 0.60 | 0.20 | 0.50 | 0.80 | 0.0 | 0.0 | 36 | 500* |
| Tint_Black_Regular | 60 | 80 | 1200 | 3.4 | 2.6 | 1.4 | 0.10 | 0.30 | 0.20 | 0.30 | 4.0 | 0.0 | 120 | 120 |
| Tint_Black_Heavy | 72 | 80 | 1000 | 1.6 | 1.0 | 1.2 | 0.00 | 0.40 | 0.26 | 0.30 | 0.0 | 0.0 | 40 | 500* |

`*` 500 是反汇编中寄存器继承值，不是该档字面量；实现时统一按 500 记录。

选档直觉：
- 小控件（≤48dp）：`Common_Small_Regular`（edge 18，倒角窄，小尺寸才不糊）。
- 常规面板 / 卡片：`Common_Large_Regular` 或 `Nexio`。
- 黑玻璃浮层（菜单、HUD）：`Tint_Black_Regular`（bgSat 4.0、burn 0）。
- 需要"厚"的深色大板：`Tint_Black_Heavy`（edge 72、darker 0.4）。

## 6 投影与边缘光

- 投影由库自绘（离屏层 + 模糊轮廓挖空，形状与玻璃同源，三端一致）：默认 **24dp / 黑 10% / y +4dp**；传 `shadow = null` 关闭。App 内 14 处显式关、2 处 30% 黑、7 处吃默认。
- **带投影的玻璃件做进离场 alpha 时，外层 `graphicsLayer` 必须 `compositingStrategy = ModulateAlpha`**。`Auto` 会离屏合成并按节点 bounds 裁掉整圈投影（实测 alpha=0.5 时形状外像素回到纯白）。
- 边缘光分两种，别搞混：
  1. **shader 内倒角带方向光**（`edgeHighlight` / `processLighting`）：始终存在，是玻璃"厚边"的光。
  2. **卡片描边式边缘高光**（旧 `EdgeLight` 一整套）：**已整体删除**，不要加回来。外观页的 `cardRim` 开关控制的仍是 (1)。

## 7 采样：玻璃看到的是谁

| 场景 | 采样源 | 备注 |
|---|---|---|
| 静态壁纸 | `rememberGlassSurface(wallpaper, scale, offset, screenW, screenH, spec, originTransform)` | 壁纸坐标映射，按窗口位置还原 |
| 页面内容（滚动列表上方的顶栏） | `LayerBackdrop`（`Modifier.layerBackdrop` 录本页内容） | 滚动/动画时按 `recordKey` 重录 |
| 弹窗/菜单浮在页面之上 | `rememberCombinedBackdrop(壁纸层, 页面层)` | 防止采到自己 |
| 玻璃上下叠玻璃 | 不采样，改用"更亮/更暗"的同色叠层 | 互相采样会递归、且视觉脏 |

## 8 性能与正确性硬规则

1. **shader key 与尺寸绑定**：同 key 的多个玻璃件会同帧互相覆盖 uniform。本项目按尺寸分 key：`NexioSoftGlassLiveTopBar` / `...BottomBarPill` / `...BottomBarButton` / `...SegmentPill` / `...CourseCard_{w}x{h}`。新项目只要有两块不同尺寸的玻璃，就必须分开 key。
2. **不要每帧重建 lambda**：`drawBackdrop` 的 element 按引用比较 `shape` / `effects` / `onDrawSurface`；lambda 每次新建会让节点每帧 invalidate、重录采样层。全部 `remember`。
3. **录制层要"该录才录"**：用 `contentRecordKey` / `contentMustRecord` 控制；滚动时刷新、静止不录。
4. **模糊金字塔**：`BASE_MAX_EDGE=1024`、`LEVEL_COUNT=7`、`LEVEL1_SIGMA=3`、program 缓存 32、`σ=(r-0.5)/0.57735`。r 越大选层级越粗；不要每帧新建 program。
5. **小玻璃少用大 blur**：`smallBlurRadius` 32px 已经够"奶"，调到 80+ 会糊成一片白。
6. **阴影不用 `Modifier.shadow`**：Compose 的 shadow 用普通圆角、会破坏连续曲率，改用库自绘。
7. **无材质档必须能看**：所有玻璃件的可读性不能靠"有模糊"成立；`NONE` 下文字与图标要仍达对比度（这也是为什么按钮默认 `BrightTone` 而不是压暗）。

## 9 玻璃之上的文字

| 位置 | 颜色 | 阴影 |
|---|---|---|
| 浅色玻璃上的黑字 | 黑 85% | 无 |
| 深色玻璃上的白字 | 白 85% | 无 |
| 壁纸上的小标题 | `#8F9CAE` | 黑/白 92%、模糊 12px（浅色壁纸用白影、深色用黑影） |
| 玻璃上的长文本 | 正文 100% | 无；靠 `TokenTone` 压暗保证对比 |

## 10 参数改动的影响面（调参前读）

| 改动 | 后果 |
|---|---|
| `edge` ↑ | 玻璃倒角更宽，小控件会显得"胖"且糊边 |
| `thickness` ↑ | 折射位移更大，圆角处会出现明显拉伸 |
| `saturation` ↑ | 背景更艳更"果冻"，超过 2.0 被 fill 钳制 |
| `smallBlur` ↑ | 玻璃内部内容更糊，文字边缘开始发虚 |
| `darker` ↑ | 更黑更沉，白字对比更好，但浅色页上会成灰块 |
| `blur(dp)` ↑ | 顶栏后面内容彻底不可辨；iOS/低端机会掉帧 |
| `blur(dp)` ↓ | 出现"能看清字"的脏感，必须配 `tintIntensity` 补色 |
