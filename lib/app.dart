import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'main.dart';
import 'widgets/update_coordinator.dart';

/// Root widget. Sets up the MaterialApp with the role-aware router
/// and auto-update checks.
class QrexApp extends ConsumerWidget {
  const QrexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);

    return SessionBootstrap(
      child: MaterialApp.router(
        title: 'QREX',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        scaffoldMessengerKey: scaffoldMessengerKey,
        builder: (context, child) =>
            UpdateCoordinator(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
