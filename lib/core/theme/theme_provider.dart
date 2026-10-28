import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage.dart';
import 'app_theme.dart';

/// Names for the three built-in QREX themes.
enum QrexTheme {
  light('light', 'Light', Icons.light_mode_outlined),
  dark('dark', 'Dark', Icons.dark_mode_outlined),
  gray('gray', 'Gray', Icons.palette_outlined);

  final String id;
  final String label;
  final IconData icon;

  const QrexTheme(this.id, this.label, this.icon);

  @override
  String toString() => id;

  static QrexTheme fromId(String? id) =>
      QrexTheme.values.firstWhere((t) => t.id == id, orElse: () => QrexTheme.light);
}

/// Current selected QREX theme (light / dark / gray).
final qrexThemeProvider = StateProvider<QrexTheme>((ref) => QrexTheme.light);

/// The `ThemeMode` backing [qrexThemeProvider].
final themeModeProvider = Provider<ThemeMode>((ref) {
  switch (ref.watch(qrexThemeProvider)) {
    case QrexTheme.dark:
      return ThemeMode.dark;
    case QrexTheme.light:
    case QrexTheme.gray:
      return ThemeMode.light;
  }
});

/// The active light `ThemeData`: white for [QrexTheme.light], gray otherwise.
final lightThemeProvider = Provider<ThemeData>((ref) {
  return ref.watch(qrexThemeProvider) == QrexTheme.light
      ? AppTheme.light()
      : AppTheme.gray();
});

/// The dark `ThemeData` (only enabled when [QrexTheme.dark] is selected).
final darkThemeProvider = Provider<ThemeData>((ref) => AppTheme.dark());

/// Restores the persisted theme selection at startup.
Future<void> restoreTheme(WidgetRef ref) async {
  final saved = await SecureStorage.getThemeMode();
  if (saved == null) return;
  ref.read(qrexThemeProvider.notifier).state = QrexTheme.fromId(saved);
}

/// Persists the selected theme.
Future<void> selectTheme(WidgetRef ref, QrexTheme theme) async {
  ref.read(qrexThemeProvider.notifier).state = theme;
  await SecureStorage.saveThemeMode(theme.id);
}
