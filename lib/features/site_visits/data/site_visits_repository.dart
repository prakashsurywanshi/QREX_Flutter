import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/site_visit.dart';

class SiteVisitsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<SiteVisitItem>> fetch() async {
    try {
      final res = await _dio.get(ApiEndpoints.siteVisits);
      final data = (res.data['data'] as Map<String, dynamic>)['siteVisits'];
      return (data as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => SiteVisitItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load site visits.');
    }
  }

  Future<void> create(Map<String, dynamic> payload) async {
    try {
      await _dio.post(ApiEndpoints.siteVisits, data: payload);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to schedule visit.');
    }
  }

  Future<void> update(int id, Map<String, dynamic> payload) async {
    try {
      await _dio.put(ApiEndpoints.siteVisit(id), data: payload);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update visit.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete(ApiEndpoints.siteVisit(id));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to delete visit.');
    }
  }
}