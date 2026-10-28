import 'package:flutter/material.dart';

/// Central theme definitions for QREX: Light, Dark, and Gray.
class AppTheme {
  AppTheme._();

  // ── Brand colours ──────────────────────────────────────────────────
  static const Color _navy = Color(0xFF1B3A5C);
  static const Color _gold = Color(0xFFC9A227);

  // Light surfaces
  static const Color _lightScaffold = Color(0xFFFFFFFF);
  static const Color _lightCard = Color(0xFFF8F9FA);
  static const Color _lightCardElevated = Color(0xFFFFFFFF);
  static const Color _lightAppBar = Color(0xFFFFFFFF);
  static const Color _lightDrawer = Color(0xFFFFFFFF);
  static const Color _lightInputFill = Color(0xFFF3F4F6);
  static const Color _lightDivider = Color(0xFFE5E7EB);
  static const Color _lightTextPrimary = Color(0xFF1C1C1E);
  static const Color _lightTextSecondary = Color(0xFF6B7280);

  // Dark surfaces – premium black
  static const Color _darkScaffold = Color(0xFF000000);
  static const Color _darkCard = Color(0xFF1A1A1A);
  static const Color _darkCardElevated = Color(0xFF222222);
  static const Color _darkAppBar = Color(0xFF0A0A0A);
  static const Color _darkDrawer = Color(0xFF111111);
  static const Color _darkInputFill = Color(0xFF1E1E1E);
  static const Color _darkDivider = Color(0xFF2C2C2C);
  static const Color _darkTextPrimary = Color(0xFFF0F0F0);
  static const Color _darkTextSecondary = Color(0xFF9CA3AF);
  static const Color _darkPrimary = Color(0xFF6B9FD4);
  static const Color _darkGold = Color(0xFFD4AF37);

  // Gray surfaces
  static const Color _grayScaffold = Color(0xFFF2F2F2);
  static const Color _grayCard = Color(0xFFE8E8E8);
  static const Color _grayCardElevated = Color(0xFFF0F0F0);
  static const Color _grayAppBar = Color(0xFFE8E8E8);
  static const Color _grayDrawer = Color(0xFFE0E0E0);
  static const Color _grayInputFill = Color(0xFFEDEDED);
  static const Color _grayDivider = Color(0xFFD1D1D1);
  static const Color _grayTextPrimary = Color(0xFF1C1C1E);
  static const Color _grayTextSecondary = Color(0xFF6B7280);

  // ── Shared component themes ────────────────────────────────────────

  static AppBarTheme _appBarTheme(Color bg, Color fg) => AppBarTheme(
        centerTitle: false,
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      );

  static InputDecorationTheme _inputTheme(Color fill, Color border, Color label) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: TextStyle(color: label),
      );

  static CardThemeData _cardTheme(Color bg) => CardThemeData(
        elevation: 0,
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      );

  static DividerThemeData _dividerTheme(Color color) =>
      DividerThemeData(color: color, thickness: 1, space: 1);

  static ListTileThemeData _listTileTheme(Color iconColor) =>
      ListTileThemeData(iconColor: iconColor);

  // ──────────────────────────────────────────────────────────────────
  //  LIGHT THEME
  // ──────────────────────────────────────────────────────────────────

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _navy,
      brightness: Brightness.light,
      primary: _navy,
      secondary: _gold,
      surface: _lightScaffold,
      onSurface: _lightTextPrimary,
      surfaceContainerLow: _lightCard,
      outline: _lightDivider,
      onSurfaceVariant: _lightTextSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _lightScaffold,
      appBarTheme: _appBarTheme(_lightAppBar, _lightTextPrimary),
      inputDecorationTheme:
          _inputTheme(_lightInputFill, _lightDivider, _lightTextSecondary),
      cardTheme: _cardTheme(_lightCard),
      dividerTheme: _dividerTheme(_lightDivider),
      listTileTheme: _listTileTheme(_lightTextSecondary),
      drawerTheme: const DrawerThemeData(backgroundColor: _lightDrawer),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightCardElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _lightCardElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightTextPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _lightInputFill,
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _lightScaffold,
        indicatorColor: colorScheme.primaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _lightScaffold,
        indicatorColor: colorScheme.primaryContainer,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  DARK THEME – Premium Black
  // ──────────────────────────────────────────────────────────────────

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _navy,
      brightness: Brightness.dark,
      primary: _darkPrimary,
      secondary: _darkGold,
      surface: _darkScaffold,
      onSurface: _darkTextPrimary,
      surfaceContainerLow: _darkCard,
      outline: _darkDivider,
      onSurfaceVariant: _darkTextSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkScaffold,
      appBarTheme: _appBarTheme(_darkAppBar, _darkTextPrimary),
      inputDecorationTheme:
          _inputTheme(_darkInputFill, _darkDivider, _darkTextSecondary),
      cardTheme: _cardTheme(_darkCard),
      dividerTheme: _dividerTheme(_darkDivider),
      listTileTheme: _listTileTheme(_darkTextSecondary),
      drawerTheme: const DrawerThemeData(backgroundColor: _darkDrawer),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkCardElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkCardElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkCardElevated,
        contentTextStyle: const TextStyle(color: _darkTextPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkInputFill,
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _darkScaffold,
        indicatorColor: colorScheme.primaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _darkScaffold,
        indicatorColor: colorScheme.primaryContainer,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkPrimary,
        foregroundColor: _darkScaffold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  GRAY THEME
  // ──────────────────────────────────────────────────────────────────

  static ThemeData gray() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _navy,
      brightness: Brightness.light,
      primary: _navy,
      secondary: _gold,
      surface: _grayScaffold,
      onSurface: _grayTextPrimary,
      surfaceContainerLow: _grayCard,
      outline: _grayDivider,
      onSurfaceVariant: _grayTextSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _grayScaffold,
      appBarTheme: _appBarTheme(_grayAppBar, _grayTextPrimary),
      inputDecorationTheme:
          _inputTheme(_grayInputFill, _grayDivider, _grayTextSecondary),
      cardTheme: _cardTheme(_grayCard),
      dividerTheme: _dividerTheme(_grayDivider),
      listTileTheme: _listTileTheme(_grayTextSecondary),
      drawerTheme: const DrawerThemeData(backgroundColor: _grayDrawer),
      dialogTheme: DialogThemeData(
        backgroundColor: _grayCardElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _grayCardElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _grayTextPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _grayInputFill,
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _grayScaffold,
        indicatorColor: colorScheme.primaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _grayScaffold,
        indicatorColor: colorScheme.primaryContainer,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
