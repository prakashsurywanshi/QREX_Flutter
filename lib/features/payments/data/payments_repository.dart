import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/payment.dart';

class PaymentIndex {
  final List<Payment> payments;
  final PaymentSummary summary;

  const PaymentIndex({
    this.payments = const [],
    this.summary = const PaymentSummary(),
  });
}

class PaymentsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<PaymentIndex> fetch() async {
    try {
      final res = await _dio.get(ApiEndpoints.payments);
      final body = res.data['data'] as Map<String, dynamic>;
      return PaymentIndex(
        payments: (body['payments'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => Payment.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        summary: PaymentSummary.fromJson(
            body['widgets'] as Map<String, dynamic>? ?? {}),
      );
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load payments.');
    }
  }

  Future<Payment> create(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post(ApiEndpoints.payments, data: payload);
      final d = res.data['data'];
      return Payment.fromJson(
          d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{});
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to record payment.');
    }
  }

  Future<Payment> update(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put(ApiEndpoints.payment(id), data: payload);
      final d = res.data['data'];
      return Payment.fromJson(
          d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{});
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update payment.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete(ApiEndpoints.payment(id));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to delete payment.');
    }
  }
}