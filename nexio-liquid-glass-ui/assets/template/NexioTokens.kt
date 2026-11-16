package com.example.nexio.design

/*
 * Nexio 液态玻璃 · 设计令牌（纯常量，无 Compose 依赖）
 * 来源：HaoZai000/NexioSchedule（AGPL-3.0）设计参数，快照 commit 28a99a3
 *
 * 用法（Compose）：
 *   Color(NexioColor.Light.Primary)                    // 0xAARRGGBB → Color
 *   NexioSize.CardCornerRadius.dp
 *   spring(NexioMotion.PressDamping, NexioMotion.PressStiffness)
 *   tween(NexioMotion.CardEnterMillis, easing = FastOutSlowInEasing)
 *
 * 颜色为 0xAARRGGBB 的 Long，转 Int 时注意：Color(value) 接受 Long。
 */

object NexioColor {

    object Light {
        const val Primary = 0xFF3482FF
        const val OnPrimary = 0xFFFFFFFF
        const val PrimaryVariant = 0xFF3482FF
        const val OnPrimaryVariant = 0xFFAECDFF
        const val PrimaryContainer = 0xFF5D9BFF
        const val OnPrimaryContainer = 0xFFFFFFFF
        const val Secondary = 0xFFF4F4F4
        const val OnSecondary = 0xFFFFFFFF
        const val SecondaryContainer = 0xFFECECEC
        const val OnSecondaryContainer = 0xFFA9A9A9
        const val TertiaryContainer = 0xFFEAF2FF
        const val OnTertiaryContainer = 0xFF3482FF
        const val Background = 0xFFFFFFFF
        const val OnBackground = 0xFF000000
        const val OnBackgroundVariant = 0xFF8C93B0
        const val Surface = 0xFFF4F4F4
        const val OnSurface = 0xFF000000
        const val SurfaceVariant = 0xFFFFFFFF
        const val SurfaceContainer = 0xFFFFFFFF
        const val OnSurfaceContainer = 0xFF000000
        const val SurfaceContainerHigh = 0xFFE8E8E8
        const val OnSurfaceSecondary = 0xCC000000
        const val TextSummary = 0x99000000
        const val TextAction = 0x66000000
        const val DisabledOnSurface = 0xFFB2B2B2
        const val Outline = 0xFFD9D9D9
        const val Divider = 0xFFE0E0E0
        const val SmallTitle = 0xFF8F9CAE
        const val Error = 0xFFE94634
        const val OnError = 0xFFFFFFFF
        const val ErrorContainer = 0xFFFDF6F4
        const val WindowDimming = 0x4D000000
        const val BarSurface = 0xFFFAFAFA
        const val SegmentIdle = 0xFFFFFFFF
        const val SegmentLabel = 0xCC000000
        const val IconTint = 0xD9000000
        const val Selector = 0x0F000000
        const val GlassButtonFill = 0xFFFAFAFA
        const val GlassButtonShadow = 0x12000000
    }

    object Dark {
        const val Primary = 0xFF277AF7
        const val OnPrimary = 0xFFFFFFFF
        const val PrimaryVariant = 0xFF0073DD
        const val OnPrimaryVariant = 0xFF99C7F1
        const val PrimaryContainer = 0xFF338FE4
        const val OnPrimaryContainer = 0xFFFFFFFF
        const val Secondary = 0xFF363636
        const val OnSecondary = 0xFFFFFFFF
        const val SecondaryContainer = 0xFF434343
        const val OnSecondaryContainer = 0xFF7C7C7C
        const val TertiaryContainer = 0xFF2B3B54
        const val OnTertiaryContainer = 0xFF4788FF
        const val Background = 0xFF242424
        const val OnBackground = 0xE6FFFFFF
        const val OnBackgroundVariant = 0xFF787E96
        const val Surface = 0xFF000000
        const val OnSurface = 0xFFF2F2F2
        const val SurfaceVariant = 0xFF242424
        const val SurfaceContainer = 0xFF242424
        const val OnSurfaceContainer = 0xFFE6FFFFFF
        const val SurfaceContainerHigh = 0xFF242424
        const val OnSurfaceSecondary = 0xCCFFFFFF
        const val TextSummary = 0x80FFFFFF
        const val TextAction = 0x66FFFFFF
        const val DisabledOnSurface = 0xFF666666
        const val Outline = 0xFF404040
        const val Divider = 0xFF393939
        const val SmallTitle = 0xFF8F9CAE
        const val Error = 0xFFF12522
        const val OnError = 0xFFFFFFFF
        const val ErrorContainer = 0xFF2E0603
        const val WindowDimming = 0x99000000
        const val BarSurface = 0xFF242424
        const val SegmentIdle = 0xFF242424
        const val SegmentLabel = 0xCCFFFFFF
        const val IconTint = 0xD9FFFFFF
        const val Selector = 0x1AFFFFFF
        const val GlassButtonFill = 0xFF242424
        const val GlassButtonShadow = 0x20000000
    }

    /** 底栏实底 alpha（浅 0.5 / 深 0.6）；叠加在 [BarSurface] 上 */
    const val BarAlphaLight = 0.5f
    const val BarAlphaDark = 0.6f

    /** 玻璃按钮实底 alpha（浅 0.76 / 深 0.84） */
    const val GlassFillAlphaLight = 0.76f
    const val GlassFillAlphaDark = 0.84f
}

object NexioType {
    const val Title1 = 32f
    const val Title2 = 24f
    const val Title3 = 20f
    const val Title4 = 18f
    const val Main = 17f
    const val Headline1 = 17f
    const val Headline2 = 16f
    const val Body1 = 16f
    const val Body2 = 14f
    const val Subtitle = 14f
    const val Footnote1 = 13f
    const val Footnote2 = 11f
    const val SegmentLabel = 14f
    const val TabLabel = 11f
    const val ParagraphLineHeightEm = 1.2f
}

object NexioSize {
    // 顶栏
    const val TopBarCollapsed = 52f
    const val TopBarTitlePadding = 26f
    const val TopBarIconPadding = 16f
    const val TopBarBlurBase = 72f
    const val TopBarBlurHeaderExtra = 72f

    // 按钮 / 底栏
    const val CircleButton = 42f
    const val CircleButtonIcon = 24f
    const val BottomBarHeight = 56f
    const val BottomBarSelector = 48f
    const val BottomBarGap = 10f
    const val BottomTabWidthFraction = 0.21f
    const val FloatBottomMin = 22f

    // 分段
    const val SegmentHeight = 42f
    const val SegmentSelectorHeight = 34f
    const val SegmentPadding = 4f

    // 行 / 卡片
    const val RowMinHeight = 56f
    const val RowPadding = 16f
    const val CardInsidePadding = 16f
    const val CardCornerRadius = 20f
    const val ItemCornerRadius = 10f
    const val ItemCornerRadiusTablet = 13f
    const val IconBoxSize = 28f
    const val IconBoxRadius = 8f
    const val MenuCornerRadius = 16f
    const val DialogMinCornerRadius = 32f
    const val SheetHandleHitHeight = 22f
    const val SheetHandleBarHeight = 4f

    // 页面
    const val WeekRowHeight = 40f
    const val GroupGap = 12f
    const val PagePadding = 16f
    const val PagePaddingTablet = 20f
    const val PageBottomPadding = 60f
    const val SmallTitlePaddingX = 12f
    const val SmallTitlePaddingY = 8f

    // 平板
    const val TabletBreakpoint = 600f
    const val TabletRailWidth = 84f
    const val TabletRailInset = 12f
    const val TabletExpandedFraction = 0.22f
    const val TabletExpandedMinWidth = 200f
    const val TabletItemHeight = 52f
}

object NexioGlass {
    // GlassPreset.Nexio（单位 px，不是 dp）
    const val EdgeWidthPx = 60f
    const val ThicknessPx = 96f
    const val Saturation = 2.0f
    const val SmallBlurRadiusPx = 32f
    const val BigBlurRadiusPx = 500f
    const val RefractIOR = 3.0f
    const val LightX = -0.42f
    const val LightY = 0.74f
    const val LightZ = -1.15f
    const val LightIntensity = 0.8f
    const val LightOppositeIntensity = 0.45f
    const val AngleRange = 1.78f
    const val EdgeLightFalloff = 0.86f
    const val ColorPow = 1.2f
    const val ReflectionLighten = 1.0f
    const val ReflectionStrength = 0.8f
    const val Darker = 0.2f

    // 投影
    const val ShadowBlurDp = 24f
    const val ShadowAlpha = 0.10f
    const val ShadowOffsetYDp = 4f

    // 三档质量
    const val BlurDp = 6f
    const val PanelBlurDp = 12f
    const val DialogBlurDp = 12f
    const val AlphaDropLight = 0.2f
    const val AlphaDropDark = 0.32f
    const val NoneStrokeDp = 0.8f
}

object NexioMotion {
    // 时长（ms）
    const val CardEnterMillis = 260
    const val CardExitMillis = 200
    const val CardStartDelayMillis = 120L
    const val CardStepDelayMillis = 56L
    const val TextCrossfadeMillis = 320
    const val TextBlurAttackMillis = 140
    const val TextBlurReleaseMillis = 180
    const val MorphOpenMillis = 540
    const val MorphMoveMillis = 500
    const val MorphExitMillis = 320
    const val GestureSettleMillis = 180
    const val GestureReleaseMillis = 140
    const val TopBarMaterialInMillis = 600
    const val TopBarMaterialOutMillis = 400

    // 弹簧
    const val TopBarDamping = 1.0f
    const val TopBarResponseSec = 0.6f
    const val TopBarExitResponseSec = 0.4f
    const val PressDamping = 0.5f
    const val PressStiffness = 300f
    const val CardSizeDamping = 0.9f
    const val TabTapStiffness = 320f
    const val TabSettleStiffness = 300f

    // 入场三件套
    const val RevealOffsetDp = 8f
    const val RevealScaleFrom = 0.97f
    const val RevealBlurDp = 12f
    const val TextBlurDp = 8f
    const val MaxConcurrentText = 48

    // 手势物理
    const val MaterialThresholdDp = 10f
    const val TrailMaxDp = 20f
    const val TrailGain = 4f
    const val TrailSmoothing = 0.55f
    const val GrabHalfWidthRatio = 0.55f
    const val FlingVelocityDpPerSec = 420f
    const val PressShrinkDp = 2f
    const val PressScale = 78f / 56f
    const val StretchRatio = 0.012f
    const val TranslationDamping = 0.032f
    const val VisibilityThreshold = 0.001f

    /** folmeSpring 的 response → Compose stiffness 换算 */
    fun stiffnessFromResponse(responseSec: Float): Float {
        val omega = (2.0 * kotlin.math.PI / responseSec).toFloat()
        return omega * omega
    }
}

object NexioEasing {
    // 与 references/motion.md 的公式一致；Compose 侧可写成 Easing { t -> ... }
    fun quadraticOut(t: Float): Float = 1f - (1f - t) * (1f - t)
    fun cubicOut(t: Float): Float = 1f - (1f - t).let { it * it * it }
    fun quartOut(t: Float): Float = 1f - (1f - t).let { val i = it * it; i * i }
    fun quintOut(t: Float): Float = 1f - (1f - t).let { val i2 = it * it; val i4 = i2 * i2; i4 * it }
}
