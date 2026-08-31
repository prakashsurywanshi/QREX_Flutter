import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/role.dart';

class RolesRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<RolesIndex> fetch() async {
    try {
      final res = await _dio.get(ApiEndpoints.roles);
      return RolesIndex.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load roles.');
    }
  }

  Future<void> create(Map<String, dynamic> payload) async {
    try {
      await _dio.post(ApiEndpoints.roles, data: payload);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to create role.');
    }
  }

  Future<void> update(int id, Map<String, dynamic> payload) async {
    try {
      await _dio.put(ApiEndpoints.role(id), data: payload);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update role.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete(ApiEndpoints.role(id));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to delete role.');
    }
  }
}