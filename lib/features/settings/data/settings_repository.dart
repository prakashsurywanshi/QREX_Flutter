import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/settings.dart';

class SettingsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<SettingsIndex> fetch() async {
    try {
      final res = await _dio.get(ApiEndpoints.settings);
      return SettingsIndex.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load settings.');
    }
  }

  Future<void> update(Map<String, dynamic> payload) async {
    try {
      await _dio.put(ApiEndpoints.settings, data: payload);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to save settings.');
    }
  }

  Future<void> updateSmtp(Map<String, dynamic> payload) async {
    try {
      await _dio.put(ApiEndpoints.settingsSmtp, data: payload);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to save SMTP settings.');
    }
  }

  Future<void> testMail(String email) async {
    try {
      await _dio.post(ApiEndpoints.testSmtp, data: {'email': email});
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to send test email.');
    }
  }
}