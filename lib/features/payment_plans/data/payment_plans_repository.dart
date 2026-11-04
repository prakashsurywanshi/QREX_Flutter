import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/payment_plan.dart';

class PaymentPlansRepository {
  PaymentPlansRepository(this._client);
  final ApiClient _client;

  Future<List<PaymentPlan>> list() async {
    try {
      final res = await _client.get(ApiEndpoints.paymentPlans);
      final data = unwrapData(res.data);
      final items = (data is Map ? (data['data'] ?? []) : data) as List;
      return items.map((e) => PaymentPlan.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<PaymentPlan> show(int id) async {
    try {
      final res = await _client.get(ApiEndpoints.paymentPlan(id));
      final data = unwrapData(res.data);
      return PaymentPlan.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
