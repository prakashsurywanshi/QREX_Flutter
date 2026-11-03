import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/commission.dart';

class CommissionsRepository {
  CommissionsRepository(this._client);

  final ApiClient _client;

  Future<({List<Commission> items, Map<String, dynamic> meta, Map<String, dynamic> summary})> list({
    int page = 1,
    String? status,
    int? agentId,
  }) async {
    try {
      final res = await _client.get(
        ApiEndpoints.commissions,
        queryParameters: {
          'page': page,
          if (status != null && status.isNotEmpty && status != 'All') 'status': status,
          if (agentId != null) 'agent_id': agentId,
        },
      );
      final data = unwrapData(res.data);
      final list = (data['commissions']?['data'] as List<dynamic>? ?? [])
          .map((e) => Commission.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = Map<String, dynamic>.from(data['commissions']?['meta'] ?? {});
      final summary = Map<String, dynamic>.from(data['summary'] ?? {});
      return (items: list, meta: meta, summary: summary);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Commission> show(int id) async {
    try {
      final res = await _client.get(ApiEndpoints.commission(id));
      final data = unwrapData(res.data);
      return Commission.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Commission> create(Map<String, dynamic> payload) async {
    try {
      final res = await _client.post(ApiEndpoints.commissions, data: payload);
      final data = unwrapData(res.data);
      return Commission.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> approve(int id) async {
    try {
      await _client.post(ApiEndpoints.commissionApprove(id));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> pay(int id, {String? reference}) async {
    try {
      await _client.post(ApiEndpoints.commissionPay(id), data: {if (reference != null) 'payment_reference': reference});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> reject(int id, {String? notes}) async {
    try {
      await _client.post(ApiEndpoints.commissionReject(id), data: {if (notes != null) 'notes': notes});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> calculate({required double baseAmount, required String commissionType, double? commissionRate, double? commissionAmount}) async {
    try {
      final res = await _client.post(ApiEndpoints.commissionCalculate, data: {
        'base_amount': baseAmount,
        'commission_type': commissionType,
        if (commissionRate != null) 'commission_rate': commissionRate,
        if (commissionAmount != null) 'commission_amount': commissionAmount,
      });
      return Map<String, dynamic>.from(unwrapData(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
