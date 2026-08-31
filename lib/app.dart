import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'main.dart';

/// Root widget. Sets up the MaterialApp with the role-aware router.
class QrexApp extends ConsumerWidget {
  const QrexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return SessionBootstrap(
      child: MaterialApp.router(
        title: 'QREX',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B3A5C), // deep navy brand
            primary: const Color(0xFF1B3A5C),
            secondary: const Color(0xFFC9A227), // gold accent
          ),
          appBarTheme: const AppBarTheme(centerTitle: false),
        ),
        routerConfig: router,
      ),
    );
  }
}
