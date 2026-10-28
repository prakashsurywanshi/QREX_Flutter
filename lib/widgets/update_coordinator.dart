import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/providers/app_update_providers.dart';

/// App-level [ScaffoldMessenger] used to surface the flexible-update banner.
/// Passed to `MaterialApp.scaffoldMessengerKey` so [UpdateCoordinator] can
/// show UI from above the Navigator.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Drives Google Play In-App Updates for the lifetime of the app:
///  * performs the first update check shortly after startup,
///  * shows a non-blocking banner when a normal (flexible) update is
///    available,
///  * hands critical (priority >= 2) updates to Play's full-screen immediate
///    flow, which is non-dismissable,
///  * completes a finished download and re-checks when the app resumes.
class UpdateCoordinator extends ConsumerStatefulWidget {
  final Widget child;

  const UpdateCoordinator({super.key, required this.child});

  @override
  ConsumerState<UpdateCoordinator> createState() => _UpdateCoordinatorState();
}

class _UpdateCoordinatorState extends ConsumerState<UpdateCoordinator>
    with WidgetsBindingObserver {
  Timer? _startupTimer;

  @override
  void initState() {
    super.initState();
    // Play In-App Updates is Android-only, so on every other platform we skip
    // the startup timer and the lifecycle observer entirely. That also keeps
    // platform-channel calls out of widget tests.
    if (!Platform.isAndroid) return;

    WidgetsBinding.instance.addObserver(this);
    // Defer the first check so it doesn't fight the cold-start/login flow.
    _startupTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        ref.read(appUpdateControllerProvider.notifier).checkForUpdate();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _startupTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(appUpdateControllerProvider.notifier).onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppUpdateState>(appUpdateControllerProvider, (prev, next) {
      if (next.prompt == UpdatePrompt.flexible &&
          prev?.prompt != UpdatePrompt.flexible) {
        _showFlexibleUpdateBanner();
      }
    });

    return widget.child;
  }

  void _showFlexibleUpdateBanner() {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        leading: const Icon(Icons.system_update_alt),
        content: Text('A new version of ${AppConfig.appName} is available.'),
        actions: [
          TextButton(
            onPressed: () {
              messenger.clearMaterialBanners();
              ref
                  .read(appUpdateControllerProvider.notifier)
                  .startFlexibleUpdate();
            },
            child: const Text('Update'),
          ),
          TextButton(
            onPressed: () => messenger.clearMaterialBanners(),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }
}
