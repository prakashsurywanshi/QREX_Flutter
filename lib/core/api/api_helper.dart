import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Parses any thrown value into a user-friendly [ApiException].
class ApiHelper {
  ApiHelper._();

  static ApiException toException(Object e,
      [String fallback = 'Something went wrong. Please try again.']) {
    if (e is ApiException) return e;
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          final errors = data['errors'];
          return ApiException(
            message,
            statusCode: e.response?.statusCode,
            errors: errors is Map ? Map<String, dynamic>.from(errors) : null,
          );
        }
      }
      return ApiException(e.message ?? fallback,
          statusCode: e.response?.statusCode);
    }
    return ApiException(fallback);
  }
}