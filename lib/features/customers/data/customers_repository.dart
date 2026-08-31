import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/paged.dart';

class CustomerIndex {
  final Paged<Customer> paged;
  final List<String> statuses;
  const CustomerIndex({required this.paged, this.statuses = const []});
}

class CustomersRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<CustomerIndex> fetch({
    int page = 1,
    int perPage = 10,
    String? search,
    Map<String, String> filters = const {},
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    filters.forEach((k, v) {
      if (v.isNotEmpty && v != 'All') query[k] = v;
    });

    try {
      final res = await _dio.get(ApiEndpoints.customers, queryParameters: query);
      final body = res.data['data'] as Map<String, dynamic>;
      final meta = body['meta'] as Map<String, dynamic>? ?? {};
      return CustomerIndex(
        paged: Paged<Customer>(
          items: (body['data'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map((e) => Customer.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
          currentPage: meta['current_page'] ?? 1,
          lastPage: meta['last_page'] ?? 1,
          perPage: meta['per_page'] ?? perPage,
          total: meta['total'] ?? 0,
        ),
        statuses: (body['statuses'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load customers.');
    }
  }

  Future<void> create(Map<String, dynamic> payload) async {
    try {
      await _dio.post(ApiEndpoints.customers, data: payload);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to create customer.');
    }
  }

  Future<void> update(int id, Map<String, dynamic> payload) async {
    try {
      await _dio.put(ApiEndpoints.customer(id), data: payload);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update customer.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete(ApiEndpoints.customer(id));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to delete customer.');
    }
  }
}