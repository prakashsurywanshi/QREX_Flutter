import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/project.dart';

class ProjectsRepository {
  ProjectsRepository(this._client);
  final ApiClient _client;

  Future<List<Project>> list() async {
    try {
      final res = await _client.get(ApiEndpoints.projects);
      final data = unwrapData(res.data);
      final items = (data is Map ? (data['data'] ?? []) : data) as List;
      return items.map((e) => Project.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
