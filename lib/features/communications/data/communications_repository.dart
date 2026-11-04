import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_helper.dart';

class CommunicationsRepository {
  CommunicationsRepository(this._client);
  final ApiClient _client;

  Future<List<dynamic>> list({String? type, String? communicableType, int? communicableId}) async {
    try {
      final res = await _client.get(ApiEndpoints.communications, queryParameters: {
        if (type != null) 'type': type,
        if (communicableType != null) 'communicable_type': communicableType,
        if (communicableId != null) 'communicable_id': communicableId,
      });
      final data = unwrapData(res.data);
      return (data is Map ? (data['data'] ?? []) : data) as List;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<dynamic> create(Map<String, dynamic> payload) async {
    try {
      final res = await _client.post(ApiEndpoints.communications, data: payload);
      return unwrapData(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
