import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'nexio.dart';

class NexioPageTransitionsBuilder extends PageTransitionsBuilder {
  const NexioPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved =
        CurvedAnimation(parent: animation, curve: NexioMotion.page);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.015),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: NexioColors.primary,
      primary: NexioColors.primary,
      onPrimary: NexioColors.onPrimary,
      surface: NexioColors.background,
    ).copyWith(
      primary: NexioColors.primary,
      onPrimary: NexioColors.onPrimary,
      primaryContainer: NexioColors.tertiaryContainer,
      onPrimaryContainer: NexioColors.onTertiaryContainer,
      secondaryContainer: NexioColors.secondaryContainer,
      onSecondaryContainer: NexioColors.textSecondary,
      surface: NexioColors.background,
      onSurface: NexioColors.onBackground,
      onSurfaceVariant: NexioColors.textSummary,
      outline: NexioColors.outline,
      outlineVariant: NexioColors.divider,
      error: NexioColors.error,
      errorContainer: NexioColors.errorContainer,
    );

    const textTheme = TextTheme(
      displaySmall: NexioType.t1,
      headlineMedium: NexioType.t2,
      headlineSmall: NexioType.t3,
      titleLarge: NexioType.t4,
      titleMedium: NexioType.headline1,
      titleSmall: NexioType.headline2,
      bodyLarge: NexioType.main,
      bodyMedium: NexioType.body1,
      bodySmall: NexioType.body2,
      labelLarge: NexioType.subtitle,
      labelMedium: NexioType.footnote1,
      labelSmall: NexioType.footnote2,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: null,
      textTheme: textTheme,
      scaffoldBackgroundColor: NexioColors.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: NexioColors.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: NexioColors.surfaceContainer,
        margin: EdgeInsets.zero,
        shape: NexioShape.squircle(20),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NexioColors.surface,
        hintStyle: NexioType.body2,
        labelStyle: NexioType.body2,
        helperStyle: NexioType.footnote1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NexioColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: NexioColors.primary,
          foregroundColor: NexioColors.onPrimary,
          textStyle: NexioType.headline1.copyWith(color: NexioColors.onPrimary),
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: const RoundedSuperellipseBorder(
              borderRadius: BorderRadius.all(Radius.circular(999))),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NexioColors.primary,
          textStyle: NexioType.headline1.copyWith(color: NexioColors.primary),
          shape: const RoundedSuperellipseBorder(
              borderRadius: BorderRadius.all(Radius.circular(999))),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NexioColors.onBackground,
          textStyle: NexioType.headline1,
          side: const BorderSide(color: NexioColors.outline),
          minimumSize: const Size(40, 40),
          shape: const RoundedSuperellipseBorder(
              borderRadius: BorderRadius.all(Radius.circular(999))),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: NexioColors.surfaceContainer,
        elevation: 0,
        shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(28))),
        titleTextStyle: NexioType.t3,
        contentTextStyle: NexioType.main,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: NexioColors.surfaceContainer,
        elevation: 0,
        showDragHandle: true,
        shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: NexioColors.onBackground.withValues(alpha: 0.88),
        contentTextStyle: NexioType.body2.copyWith(color: Colors.white),
        shape: NexioShape.squircle(22),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      ),
      dividerTheme: const DividerThemeData(
        color: NexioColors.divider,
        thickness: 0.75,
        space: 0.75,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: NexioColors.primary,
        inactiveTrackColor: NexioColors.primary.withValues(alpha: 0.16),
        thumbColor: NexioColors.primary,
        overlayColor: NexioColors.primary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? NexioColors.primary
                : NexioColors.disabled),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: NexioColors.primary),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: NexioPageTransitionsBuilder(),
          TargetPlatform.iOS: NexioPageTransitionsBuilder(),
        },
      ),
    );
  }
}