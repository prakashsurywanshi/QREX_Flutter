import 'package:in_app_update/in_app_update.dart';

/// Thin wrapper around Google's Play In-App Updates API.
///
/// Every platform call is guarded so a failure (e.g. the app was installed
/// from a sideloaded APK rather than Play, or the device can't reach Play)
/// degrades gracefully to "no update" instead of crashing the app.
class InAppUpdateService {
  /// Asks Play whether an update is available for this app.
  ///
  /// Returns `null` when the API is unavailable or the request failed.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      return await InAppUpdate.checkForUpdate();
    } catch (_) {
      return null;
    }
  }

  /// Starts the full-screen, non-dismissable immediate update flow. Used for
  /// critical (high-priority) releases.
  Future<AppUpdateResult> performImmediateUpdate() =>
      InAppUpdate.performImmediateUpdate();

  /// Starts downloading the update in the background. Call
  /// [completeFlexibleUpdate] once the download has finished.
  Future<AppUpdateResult> startFlexibleUpdate() =>
      InAppUpdate.startFlexibleUpdate();

  /// Installs an already-downloaded flexible update (triggers an app restart).
  Future<void> completeFlexibleUpdate() => InAppUpdate.completeFlexibleUpdate();

  /// Live install/download progress for in-flight flexible updates.
  Stream<InstallStatus> get installStatusStream =>
      InAppUpdate.installUpdateListener;
}
