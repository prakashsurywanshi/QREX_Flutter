import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/admin_user.dart';

class UsersRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<UsersIndex> fetch() async {
    try {
      final res = await _dio.get(ApiEndpoints.users);
      return UsersIndex.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load users.');
    }
  }

  Future<void> create(Map<String, dynamic> payload) async {
    try {
      await _dio.post(ApiEndpoints.users, data: payload);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to invite user.');
    }
  }

  Future<void> update(int id, Map<String, dynamic> payload) async {
    try {
      await _dio.put(ApiEndpoints.user(id), data: payload);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update user.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete(ApiEndpoints.user(id));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to delete user.');
    }
  }
}