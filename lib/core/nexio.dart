import 'package:flutter/material.dart';

/// Nexio 设计令牌（源自 nexio-liquid-glass-ui / miuix-skill，浅色方案）。
class NexioColors {
  static const primary = Color(0xFF3482FF);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF5D9BFF);

  static const tertiaryContainer = Color(0xFFEAF2FF);
  static const onTertiaryContainer = Color(0xFF3482FF);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F4F4);
  static const surfaceContainer = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFECECEC);
  static const onSecondaryContainer = Color(0xFFA9A9A9);
  static const onBackground = Color(0xFF000000);
  static const textSecondary = Color(0xCC000000);
  static const textSummary = Color(0x99000000);
  static const textAction = Color(0x66000000);
  static const smallTitle = Color(0xFF8F9CAE);
  static const divider = Color(0xFFE0E0E0);
  static const outline = Color(0xFFD9D9D9);
  static const error = Color(0xFFE94634);
  static const errorContainer = Color(0xFFFDF6F4);
  static const disabled = Color(0xFFB2B2B2);
  static const iconTint = Color(0xD9000000);

// 模糊构件与选择态
  static const selectorFill = Color(0x0F000000);
  static const blurFill = Color(0x1AFFFFFF); // 白 10%
  static const barBlurFill = Color(0x1FFFFFFF); // 白 12%


  // 柔光背景光斑
  static const glowBlue = Color(0x336C8EF5);
  static const glowWarm = Color(0x2EFFA693);
  static const glowMint = Color(0x1FA8E6CF);
}

/// 字号体系（title1..footnote2）。
class NexioType {
  static const TextStyle t1 =
      TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2, color: NexioColors.onBackground);
  static const TextStyle t2 =
      TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25, color: NexioColors.onBackground);
  static const TextStyle t3 =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3, color: NexioColors.onBackground);
  static const TextStyle t4 =
      TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3, color: NexioColors.onBackground);
  static const TextStyle main =
      TextStyle(fontSize: 17, fontWeight: FontWeight.w400, height: 1.4, color: NexioColors.onBackground);
  static const TextStyle headline1 =
      TextStyle(fontSize: 17, fontWeight: FontWeight.w500, height: 1.3, color: NexioColors.onBackground);
  static const TextStyle headline2 =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3, color: NexioColors.onBackground);
  static const TextStyle body1 =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: NexioColors.onBackground);
  static const TextStyle body2 = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: NexioColors.textSummary);
  static const TextStyle subtitle =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.3, color: NexioColors.smallTitle);
  static const TextStyle footnote1 = TextStyle(
      fontSize: 13, fontWeight: FontWeight.w400, height: 1.4, color: NexioColors.textAction);
  static const TextStyle footnote2 = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w400, height: 1.3, color: NexioColors.textAction);
}

/// 连续曲率（G2 squircle）形状工具。
class NexioShape {
  static RoundedSuperellipseBorder squircle(double radius) =>
      RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius));

  static RoundedSuperellipseBorder pill() =>
      RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(999));

  static ShapeBorderClipper clipper(double radius) =>
      ShapeBorderClipper(shape: squircle(radius));
}

/// 动效曲线与时长。
class NexioMotion {
  static const quartOut = Cubic(0.165, 0.84, 0.44, 1.0);
  static const cubicOut = Cubic(0.215, 0.61, 0.355, 1.0);
  static const page = Cubic(0.3, 0.5, 0.2, 1.0);
  static const overshoot = Cubic(0.34, 1.36, 0.64, 1.0);

  static const Duration reveal = Duration(milliseconds: 260);
  static const Duration dismiss = Duration(milliseconds: 200);
  static const Duration tabSwitch = Duration(milliseconds: 300);
  static const Duration press = Duration(milliseconds: 180);

  static Duration revealDelay(int index) =>
      Duration(milliseconds: 120 + index * 56);
}