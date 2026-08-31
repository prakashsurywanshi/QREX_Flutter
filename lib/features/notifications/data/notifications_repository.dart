import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/app_notification.dart';

class NotificationsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<NotificationIndex> fetch() async {
    try {
      final res = await _dio.get(ApiEndpoints.notifications);
      return NotificationIndex.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load notifications.');
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _dio.post(ApiEndpoints.notificationRead(id));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update notification.');
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post(ApiEndpoints.notificationsReadAll);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update notifications.');
    }
  }
}