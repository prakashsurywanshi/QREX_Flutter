import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

import '../updates/in_app_update_service.dart';

final inAppUpdateServiceProvider = Provider<InAppUpdateService>((ref) {
  return InAppUpdateService();
});

/// What the UI should do with the update found by Play.
enum UpdatePrompt {
  /// No action needed / nothing available.
  none,

  /// A normal update is available -- offer it (flexible download).
  flexible,

  /// The update is critical -- drive the full-screen immediate flow. The user
  /// cannot dismiss it; Play re-prompts whenever it is not completed.
  immediateRequired,
}

class AppUpdateState {
  final bool checking;
  final AppUpdateInfo? info;
  final UpdatePrompt prompt;

  /// A flexible update has finished downloading and just needs to be installed
  /// (done automatically the next time the app resumes).
  final bool installDownloaded;

  const AppUpdateState({
    this.checking = false,
    this.info,
    this.prompt = UpdatePrompt.none,
    this.installDownloaded = false,
  });
}

/// Coordinates Google Play In-App Updates for the app.
///
/// Decision rule (matching Google's guidance):
///  * `updatePriority >= 2`  -> immediate (forced full-screen) update.
///  * otherwise               -> flexible update, surfaced as a soft prompt.
class AppUpdateController extends StateNotifier<AppUpdateState> {
  final InAppUpdateService _service;
  bool _checking = false;
  StreamSubscription<InstallStatus>? _installSub;

  AppUpdateController(this._service) : super(const AppUpdateState()) {
    _installSub = _service.installStatusStream.listen(
      _onInstallStatus,
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _installSub?.cancel();
    super.dispose();
  }

  /// Checks Play for an available update and acts on it once per call. Safe to
  /// call repeatedly (from startup and on every app resume).
  Future<void> checkForUpdate() async {
    if (_checking) return;
    _checking = true;
    try {
      final info = await _service.checkForUpdate();
      if (!mounted) return;
      _apply(info);
    } finally {
      _checking = false;
    }
  }

  void _apply(AppUpdateInfo? info) {
    if (info == null ||
        info.updateAvailability != UpdateAvailability.updateAvailable) {
      state = AppUpdateState(info: info);
      return;
    }

    final isCritical = info.updatePriority >= 2;

    if (isCritical && info.immediateUpdateAllowed) {
      state = AppUpdateState(
        info: info,
        prompt: UpdatePrompt.immediateRequired,
      );
      _runImmediateUpdate();
    } else if (info.flexibleUpdateAllowed) {
      state = AppUpdateState(info: info, prompt: UpdatePrompt.flexible);
    } else {
      state = AppUpdateState(info: info);
    }
  }

  Future<void> _runImmediateUpdate() async {
    final result = await _service.performImmediateUpdate();
    if (!mounted) return;

    if (result == AppUpdateResult.userDeniedUpdate) {
      // Keep the prompt as "required" so the next app resume drives the
      // immediate flow again (Play throttles how often the UI can appear).
      state = AppUpdateState(
        info: state.info,
        prompt: UpdatePrompt.immediateRequired,
        installDownloaded: state.installDownloaded,
      );
    } else {
      state = AppUpdateState(
        info: state.info,
        installDownloaded: state.installDownloaded,
      );
    }
  }

  /// Starts downloading the available update (after the user taps "Update"
  /// on the soft prompt).
  Future<void> startFlexibleUpdate() async {
    final result = await _service.startFlexibleUpdate();
    if (!mounted) return;

    if (result == AppUpdateResult.success) {
      state = AppUpdateState(info: state.info);
    } else {
      // Download could not start (user denied or Play failed); keep the prompt
      // so the user can try again.
      state = AppUpdateState(info: state.info, prompt: UpdatePrompt.flexible);
    }
  }

  void _onInstallStatus(InstallStatus status) {
    if (status == InstallStatus.downloaded && mounted) {
      state = AppUpdateState(info: state.info, installDownloaded: true);
    }
  }

  /// Called when the app returns to the foreground:
  ///  * install a finished flexible download, or
  ///  * re-drive the immediate flow if it was dismissed, or
  ///  * re-check for updates silently.
  Future<void> onAppResumed() async {
    if (state.installDownloaded) {
      try {
        await _service.completeFlexibleUpdate();
      } catch (_) {
        // Ignore: the update will be retried on the next resume.
      }
      if (mounted) {
        state = AppUpdateState(info: state.info, installDownloaded: false);
      }
      return;
    }

    if (state.prompt == UpdatePrompt.immediateRequired) {
      await _runImmediateUpdate();
      return;
    }

    await checkForUpdate();
  }
}

final appUpdateControllerProvider =
    StateNotifierProvider<AppUpdateController, AppUpdateState>((ref) {
      return AppUpdateController(ref.watch(inAppUpdateServiceProvider));
    });
