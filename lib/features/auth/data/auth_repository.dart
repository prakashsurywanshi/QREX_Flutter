import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/user.dart';
import '../../../core/storage/secure_storage.dart';

class AuthResult {
  final String token;
  final User user;

  AuthResult({required this.token, required this.user});
}

class AuthRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<AuthResult> login({required String email, required String password}) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final data = res.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);

      await _persistSession(token, user);

      return AuthResult(token: token, user: user);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<User> me() async {
    try {
      final res = await _dio.get(ApiEndpoints.me);
      final user = User.fromJson(
          res.data['data']['user'] as Map<String, dynamic>);
      await _persistUser(user);
      return user;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<User> updateProfile({
    required String name,
    String? phone,
  }) async {
    try {
      final res = await _dio.put(
        ApiEndpoints.updateProfile,
        data: {'name': name, 'phone': phone},
      );
      final user = User.fromJson(res.data['data'] as Map<String, dynamic>);
      await _persistUser(user);
      return user;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.put(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> sendResetLink({required String email}) async {
    try {
      await _dio.post(ApiEndpoints.sendReset, data: {'email': email});
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } on DioException catch (_) {
      // ignore network errors on logout; always clear local state
    } finally {
      await SecureStorage.clear();
    }
  }

  /// Restore a previously cached user (from secure storage) on cold start.
  Future<User?> cachedUser() async {
    final raw = await SecureStorage.getUser();
    if (raw == null || raw.isEmpty) return null;
    try {
      return User.fromJson(_decode(raw));
    } catch (_) {
      return null;
    }
  }

  /// Best-effort persistence; a secure-storage failure/timeout must never
  /// fail a successful login.
  static Future<void> _persistSession(String token, User user) async {
    try {
      await SecureStorage.saveToken(token);
      await SecureStorage.saveUser(_encode(user));
    } catch (_) {
      // Ignore: session still works for this app run.
    }
  }

  static Future<void> _persistUser(User user) async {
    try {
      await SecureStorage.saveUser(_encode(user));
    } catch (_) {
      // Ignore: only a cache refresh.
    }
  }

  static String _encode(User user) {
    return jsonEncode(user.toJson());
  }

  static Map<String, dynamic> _decode(String raw) {
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  ApiException _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Something went wrong. Please try again.';

    if (data is Map<String, dynamic>) {
      message = data['message']?.toString() ?? message;

      final errors = data['errors'];
      if (errors is Map) {
        // Take the first validation error for display.
        for (final v in errors.values) {
          if (v is List && v.isNotEmpty) {
            message = v.first.toString();
            break;
          }
        }
      }
    }

    if (status == 401) {
      message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Session expired. Please login again.';
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      message = 'Unable to reach the server. Check your connection.';
    }

    return ApiException(message, statusCode: status);
  }
}
