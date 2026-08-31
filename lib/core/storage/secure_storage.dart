import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage to persist the auth token safely.
///
/// Every operation is guarded by a short timeout: on platforms without a
/// functioning keyring/keychain (e.g. a bare Linux desktop without a Secret
/// Service daemon) the underlying native call can hang indefinitely, which
/// would otherwise stall login/session flow. Timeouts fail fast instead.
class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  /// Upper bound for any single native secure-storage operation.
  static const _timeout = Duration(seconds: 2);

  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token).timeout(_timeout);

  static Future<String?> getToken() =>
      _storage.read(key: _tokenKey).timeout(_timeout);

  static Future<void> deleteToken() =>
      _storage.delete(key: _tokenKey).timeout(_timeout);

  static Future<void> saveUser(String json) =>
      _storage.write(key: _userKey, value: json).timeout(_timeout);

  static Future<String?> getUser() =>
      _storage.read(key: _userKey).timeout(_timeout);

  static Future<void> clear() async {
    await _storage.delete(key: _tokenKey).timeout(_timeout);
    await _storage.delete(key: _userKey).timeout(_timeout);
  }
}
