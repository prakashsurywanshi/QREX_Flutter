import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_helper.dart';

class UnitsRepository {
  UnitsRepository(this._client);
  final ApiClient _client;

  Future<List<dynamic>> list({int? projectId}) async {
    try {
      final res = await _client.get(ApiEndpoints.units, queryParameters: {if (projectId != null) 'project_id': projectId});
      final data = unwrapData(res.data);
      return (data is Map ? (data['data'] ?? []) : data) as List;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> hold(int id) async {
    try {
      await _client.post(ApiEndpoints.unitHold(id));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> release(int id) async {
    try {
      await _client.post(ApiEndpoints.unitRelease(id));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
