import 'package:flutter/material.dart';

/// 设计 tokens：亮暗主题从同一组 token 派生（02 文档 §4.3，禁止裸色值）。
abstract final class AgendumTokens {
  static const seed = Color(0xFF3A6FF0); // 主品牌蓝
  static const accentGreen = Color(0xFF34A853);
  static const energyHigh = Color(0xFFE8590C);
  static const energyLow = Color(0xFF7048E8);

  // 中性色
  static const surfaceLight = Color(0xFFFBFBFD);
  static const surfaceDark = Color(0xFF17191E);
  static const cardDark = Color(0xFF1F2228);
}

abstract final class AgendumTheme {
  /// [fontFamily] 供 golden 走查注入系统 CJK 字体(生产走平台默认)。
  static ThemeData light({String? fontFamily}) =>
      _base(Brightness.light, fontFamily);

  static ThemeData dark({String? fontFamily}) =>
      _base(Brightness.dark, fontFamily);

  static ThemeData _base(Brightness brightness, String? fontFamily) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AgendumTokens.seed,
      brightness: brightness,
      surface: brightness == Brightness.light
          ? AgendumTokens.surfaceLight
          : AgendumTokens.surfaceDark,
    );
    final dark = brightness == Brightness.dark;
    return ThemeData(
      colorScheme: scheme,
      fontFamily: fontFamily,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? AgendumTokens.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: dark ? Colors.white10 : Colors.black.withValues(alpha: .06),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: .12),
        height: 64,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurface.withValues(alpha: .55),
        ),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: dark ? Colors.white10 : Colors.black.withValues(alpha: .06),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
