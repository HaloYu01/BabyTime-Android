# 设计令牌 Design Tokens

全部取自 NexioSchedule 快照 `28a99a3` 的 `miuix/.../theme/Colors.kt`、`TextStyles.kt`、各组件常量。颜色为 `0xAARRGGBB`，未标 alpha 即不透明。

## 1 颜色

### 1.1 浅色（lightColorScheme）

| 语义 | 值 | 用在哪 |
|---|---|---|
| primary | `#3482FF` | 主按钮、开关、开关选中、链接、今日高亮 |
| onPrimary | `#FFFFFF` | 主按钮文字 |
| primaryVariant | `#3482FF` | 卡片强调 |
| onPrimaryVariant | `#AECDFF` | 强调上的次级文字 |
| primaryContainer | `#5D9BFF` | 强调容器 |
| onPrimaryContainer | `#FFFFFF` | 强调容器文字 |
| secondary | `#F4F4F4` | 次级按钮底 |
| onSecondary | `#FFFFFF` | 次级按钮文字 |
| secondaryVariant | `#F0F0F0` | 次级容器 |
| onSecondaryVariant | `#303030` | 次级容器文字 |
| secondaryContainer | `#ECECEC` | 灰面容器（中性 chip） |
| onSecondaryContainer | `#A9A9A9` | 灰面容器文字 |
| tertiaryContainer | `#EAF2FF` | 蓝色浅容器 |
| onTertiaryContainer | `#3482FF` | 蓝色浅容器文字 |
| background | `#FFFFFF` | 页面底 |
| onBackground | `#000000` | 标题 |
| onBackgroundVariant | `#8C93B0` | 副标题（偏蓝的灰） |
| surface | `#F4F4F4` | 分组列表底、页面 surface |
| onSurface | `#000000` | 正文 |
| surfaceVariant | `#FFFFFF` | 分组列表内的行底 |
| onSurfaceSecondary | `#CC000000`（80%） | 二级文字 |
| onSurfaceVariantSummary | `#99000000`（60%） | 设置行摘要 |
| onSurfaceVariantActions | `#66000000`（40%） | 末端动作/箭头、日期 |
| disabledOnSurface | `#B2B2B2` | 禁用文字 |
| surfaceContainer | `#FFFFFF` | 卡片底（Card 默认） |
| onSurfaceContainer | `#000000` | 卡片文字 |
| surfaceContainerVariant | `#959595` | 卡片内次要 |
| surfaceContainerHigh | `#E8E8E8` | 高一级容器 |
| surfaceContainerHighest | `#E8E8E8` | 最高容器 |
| outline | `#D9D9D9` | 描边 |
| dividerLine | `#E0E0E0` | 行分隔线 |
| windowDimming | `#000000` @30% | 弹窗/菜单遮罩 |
| error / onError | `#E94634` / `#FFFFFF` | 错误、危险按钮 |
| errorContainer / onErrorContainer | `#FDF6F4` / `#410002` | 错误提示底 |
| disabledPrimary | `#C2D9FF` | 禁用开关 |
| disabledOnPrimary | `#F3F8FF` | 禁用开关滑块 |
| disabledPrimarySlider | `#B8CFF5` | 禁用滑杆 |
| sliderKeyPoint / Foreground / Background | `#4DA3B3CD` / `#6EB5FF` / `#0F000000` | 滑杆 |

### 1.2 深色（darkColorScheme）

| 语义 | 值 |
|---|---|
| primary | `#277AF7` |
| onPrimary | `#FFFFFF` |
| primaryVariant | `#0073DD` |
| onPrimaryVariant | `#99C7F1` |
| primaryContainer | `#338FE4` |
| onPrimaryContainer | `#FFFFFF` |
| secondary | `#363636` |
| onSecondary | `#FFFFFF` |
| secondaryVariant | `#434343` |
| onSecondaryVariant | `#D9D9D9` |
| secondaryContainer | `#434343` |
| onSecondaryContainer | `#7C7C7C` |
| tertiaryContainer | `#2B3B54` |
| onTertiaryContainer | `#4788FF` |
| background | `#242424` |
| onBackground | `#E6FFFFFF`（90%） |
| onBackgroundVariant | `#787E96` |
| surface | `#000000` |
| onSurface | `#F2F2F2` |
| surfaceVariant | `#242424` |
| onSurfaceSecondary | `#CCFFFFFF` |
| onSurfaceVariantSummary | `#80FFFFFF`（50%） |
| onSurfaceVariantActions | `#66FFFFFF`（40%） |
| disabledOnSurface | `#666666` |
| surfaceContainer | `#242424` |
| onSurfaceContainer | `#E6FFFFFF` |
| surfaceContainerVariant | `#737373` |
| surfaceContainerHigh | `#242424` |
| onSurfaceContainerHigh | `#666666` |
| surfaceContainerHighest | `#2D2D2D` |
| onSurfaceContainerHighest | `#E9E9E9` |
| outline | `#404040` |
| dividerLine | `#393939` |
| windowDimming | `#000000` @60% |
| error / onError | `#F12522` / `#FFFFFF` |
| errorContainer / onErrorContainer | `#2E0603` / `#FFDAD6` |
| disabledPrimary | `#253E64` |
| disabledOnPrimary | `#677993` |
| disabledPrimarySlider | `#44587C` |
| sliderKeyPoint / Foreground / Background | `#4D7A8AA6` / `#5DAAFF` / `#26FFFFFF` |

### 1.3 构件专用色（不在主题里，硬编码在这些位置）

| 用途 | 浅色 | 深色 |
|---|---|---|
| 分组小标题 SmallTitle | `#8F9CAE`（有壁纸时叠阴影） | 同左 |
| 底栏胶囊 / 圆钮实底 | `#FAFAFA` @50%（无材质档 @100%） | `#242424` @60% |
| 分段控件静止底 | `#FFFFFF` | `#242424` |
| 分段控件文字 | 黑 @80% | 白 @80% |
| 顶栏按钮 / 底栏图标着色 | 黑 @85% | 白 @85% |
| 选中滑块 | 黑 @6% | 白 @10% |
| 玻璃按钮实底（无材质档用） | `#FAFAFA` @76%（柔光档降到约 0.56） | `#242424` @84%（柔光档约 0.52） |
| 玻璃按钮阴影 | `#12000000`（黑 7%） | `#20000000`（黑 13%） |
| 分段胶囊模糊投影 | `#12000000` | `#20000000` |
| 课程卡描边（未上色） | 黑 @(见 6.3) | 白 @(见 6.3) |
| 非本周/已取消课程文字 | 黑 @30–45% | 白 @28–40% |

### 1.4 取色（莫奈 Monet，Android 12+ 可选）

- 开关打开后 primary / surfaceContainer / secondaryContainer / tertiaryContainer 跟随系统壁纸，`surface` 走系统动态色，其它档位保持本表结构。
- 课程/标签类颜色按名称映射：`name.hashCode() % 3` → 0 用 primary、1 用 secondaryContainer、2 用 tertiaryContainer。
- 由此派生卡片着色：`Hct.fromInt(seed)` 取 hue/chroma，深色亮度 80、浅色亮度 40 → 得到"半透明着色层"（不必很淡，要看得见）。
- 文字色对比度兜底：着色过深时按 WCAG 对比度算，≥4.5 才用原色，否则在黑白里挑对比更高的。
- 关闭莫奈后回到课程自定义色（本项目课程卡色板为马卡龙系，见 `assets/preview/主课程表.png`）。

## 2 字号（Miuix TextStyles）

`TextStyle(fontSize)`，行高默认不写；paragraph 例外 `lineHeight = 1.2em`。

| 名称 | 大小 | 用途 |
|---|---|---|
| title1 | 32sp | 页面大标题（超大数字/日期） |
| title2 | 24sp | 弹窗大标题、空态标题 |
| title3 | 20sp | 段落标题 |
| title4 | 18sp | 次级标题 |
| main | 17sp | 默认正文（**组件默认字号**） |
| paragraph | 17sp / 1.2em | 长段落（说明文字） |
| headline1 | 17sp | 设置行标题、按钮字 |
| button | 17sp | 按钮 |
| headline2 | 16sp | 卡片标题 |
| body1 | 16sp | 正文 |
| body2 | 14sp | 摘要、说明、菜单行 |
| subtitle | 14sp **Bold** | 分组小标题 |
| footnote1 | 13sp | 星期名、角标说明 |
| footnote2 | 11sp | 日期、极弱提示、底栏 tab 文字 |

补充约定：
- 字体：沿用系统无衬线（Android / HyperOS 上即 MiSans；iOS 为 SF；Web 用 `-apple-system, "MiSans", "SF Pro Text", "Segoe UI", Roboto, "Noto Sans SC"`）。项目**不内置**字体文件，不要为一个 App 塞 10MB 字体。
- 设置行标题固定 `headline1 + FontWeight.Medium`；摘要 `body2`。
- 底栏 tab 文字 11sp；分段胶囊文字 14sp `Medium`。
- 顶栏标题（折叠态）用 `title4`~`title2` 之间的视觉重量，按平台调；课表周标题实际用 `title3/Bold` 观感。

## 3 几何

### 3.1 高度

| 元素 | 值 |
|---|---|
| 折叠顶栏 CollapsedHeight | **52dp** |
| 圆形顶栏按钮 | **42dp**（图标 24dp；长按拖拽时按压放大 2dp） |
| 底栏容器 / 圆钮 | **56dp** |
| 底栏选中滑块 | **48dp**（上下合计内缩 8dp：56 → 48） |
| 分段控件容器 | **42dp**（滑块 34dp，同规则 −8dp） |
| 列表行 / BasicComponent | **≥56dp**（可用高度 56dp 起） |
| 课表星期行 | **40dp** |
| 设置图标块 | **28dp**（内图标 17–22dp） |
| 工作表拖拽把手 | 容器 22dp，把手 4dp 高、圆角 2dp |
| 平板侧栏项 | **52dp**，行间 4dp，图标 26dp，顶部工具条 48dp |

### 3.2 圆角

**全部使用连续曲率（G2 squircle），不用 `RoundedCornerShape`。**

| 元素 | 半径 |
|---|---|
| 卡片 Card | **20dp** |
| 课表课程卡 | **10dp**（平板 ×1.3 ≈ 13dp） |
| 设置项图标底 | **8dp** |
| 角标 / 小 chip | **4dp** |
| 菜单 / 级联弹层 | **16dp** |
| 对话框（贴底） | `屏幕圆角 - 外边距`，下限 **32dp** |
| 胶囊（分段、底栏、圆钮、按钮） | 全圆角（`ContinuousCapsule`） |
| 屏幕级裁切（morph / 开洞） | 用设备真实屏幕圆角，做圆角补偿 `/scale` |

### 3.3 间距

| 场景 | 值 |
|---|---|
| 页面左右内边距 | 16dp（手机）/ 20dp（平板） |
| 列表行内边距 | 16dp（`BasicComponentDefaults.InsideMargin`） |
| 卡片内容内边距 | 16dp（`Card` 自身 `InsideMargin` 默认 0，由调用方给） |
| 分组之间 | **12dp** |
| 行内图标与文字 | 8dp（顶栏按钮之间也 8dp） |
| 分段控件内部 | 4dp 边距 |
| 底栏胶囊与圆钮 | **10dp** |
| 底栏每格占屏 | 21%（两格 42%，原版"3 格 63%"） |
| 底部悬浮留白 | `max(navBarInset + 2dp, 22dp)` |
| 顶栏与内容 | 折叠顶栏 52dp + 状态栏；课表页额外 40dp 星期行 + 2dp |
| 文档页首块顶部额外留白 | 有小标题：平板 12 / 手机 0；无小标题：平板 24 / 手机 12 |
| 页面底部内边距 | 60dp（或原生栏 inset + 24dp） |
| 小标题内边距 | 12dp 水平 / 8dp 垂直 |

## 4 屏幕与壁纸

- **屏幕圆角**：读设备真实圆角（Android `RoundedCorner`，iOS `UIScreen`），作为 `LocalScreenCornerRadius` 下发；morph 时按 `radius / scale` 补偿，预测返回时补偿为 1。取不到则退回 0，不做假圆角。
- **壁纸**：可选本地图片。参数：亮度、模糊；玻璃采样的是"壁纸按缩放/偏移映射后的坐标"，`wallpaperTexMap` 负责把窗口坐标还原到壁纸层。
- **页面底色**：无壁纸时用 `surface`；有壁纸时页面底透明，玻璃与白色文字压在壁纸上，故浅色元素需按有壁纸规则加阴影（如 SmallTitle 用 0.92 alpha 的 12px 模糊阴影）。
- **状态栏/导航栏**：edge-to-edge。顶栏糊带高度按是否有状态栏切换：有状态栏 `120dp + sb`，无 `160dp`，折叠屏竖排 tab 形态 `120dp - 8dp`。

## 5 阴影

| 元素 | 参数 |
|---|---|
| 玻璃件默认投影（softglass 内建） | 模糊 24dp、黑 10%、y 偏移 +4dp；传 `null` 关闭 |
| 顶栏圆按钮滚动阴影 | 半径 10dp × alpha、spread 2dp × alpha，颜色 alpha ×3.2（上限 1） |
| 分段胶囊滚动阴影 | 半径 10dp × alpha，min 0.1px |
| 卡片 | 无投影（靠表面色与玻璃边缘光区分层级） |

## 6 透明度约定（容易做错的地方）

1. **文字不要直接降黑**：正文 100%、二级 80%、摘要 50–60%、动作/箭头 40%、禁用 `#B2B2B2`（浅）/`#666666`（深）。
2. **玻璃面上的文字要反向提亮**：深色玻璃上白字 74%–85%；浅色玻璃上黑字 74%–85%；非当前周课程文字 28–45%。
3. **玻璃有材质时不要叠实色底**：`onDrawSurface` 传 `null`；只有无材质档才传实色 `drawRect`。
4. **图标 tint 用 alpha 而不是灰**：`Color.Black.copy(alpha=.85f)` 保留玻璃透出的层次。
5. **遮罩**：弹窗/菜单用 `windowDimming`（浅 30% / 深 60%），不要自造 0.5 黑。

## 7 主题提供的 Local（Compose 侧）

| Local | 含义 |
|---|---|
| `LocalScreenCornerRadius` / `LocalScreenTopCornerRadii` | 设备圆角（dp / 上两角） |
| `LocalAppSettingDark` | App 级深浅（可能被壁纸锁成浅色而系统是深色） |
| `LocalMonetColorEnabled` | 取色是否**生效**（偏好 && 平台支持） |
| `LocalMaterialNoneEnabled` | 是否无材质档 |
| `LocalGlassBlurDp` / `LocalGlassPanelBlurDp` / `LocalGlassDialogBlurDp` | 三档模糊半径 |
| `LocalGlassSurfaceAlphaDrop` | 底色 alpha 降幅（浅/深各一） |
| `LocalSoftGlassLayer` | 注入给组件库的柔光 shader 层 |
| `LocalUseFakeProgressiveBlur` | 顶栏假渐进模糊开关 |
| `LocalHapticFeedback`（被门控包装） | 全局触感开关 |
| `LocalTopBarMaterial` | 页面级材质状态（顶栏与头部构件共用） |

**主题接线顺序**（`Theme.kt` 结论）：先 `MiuixTheme` → 再 `CompositionLocalProvider(全部 Local)` → 再 `MaterialTheme` → **最后把 `LocalIndication` 与 `LocalTextStyle` 写回 miuix 的值**。因为 `MaterialTheme` 会用 `ripple()` 和 `bodyLarge` 覆盖掉 miuix 的指示器与文字样式，不写回就会丢失按压反馈与行高。
