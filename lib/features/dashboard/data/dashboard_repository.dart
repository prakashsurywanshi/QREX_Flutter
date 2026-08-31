import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/dashboard.dart';

class DashboardRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<DashboardData> fetch({String range = 'month'}) async {
    final res = await _dio.get(
      ApiEndpoints.dashboard,
      queryParameters: {'range': range},
    );
    return DashboardData.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
