class AppLogger {
  AppLogger._();
  static void info(String message) {
    // ignore: avoid_print
    print('[INFO] $message');
  }
  static void error(String message, [Object? error]) {
    // ignore: avoid_print
    print('[ERROR] $message ${error ?? ''}');
  }
}
