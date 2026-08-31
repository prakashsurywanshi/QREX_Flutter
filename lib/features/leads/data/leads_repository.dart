import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/lead.dart';
import '../../../core/models/paged.dart';

class LeadIndex {
  final Paged<Lead> paged;
  final List<String> statuses;
  final List<String> sources;
  final List<LeadOption> campaigns;

  const LeadIndex({
    required this.paged,
    this.statuses = const [],
    this.sources = const [],
    this.campaigns = const [],
  });
}

class LeadDetail {
  final Lead lead;
  final List<LeadActivity> activities;
  final List<Map<String, dynamic>> handovers;
  final List<Map<String, dynamic>> recommendations;
  final List<LeadOption> agents;
  final List<LeadOption> owners;
  final List<LeadOption> campaigns;

  const LeadDetail({
    required this.lead,
    this.activities = const [],
    this.handovers = const [],
    this.recommendations = const [],
    this.agents = const [],
    this.owners = const [],
    this.campaigns = const [],
  });

  factory LeadDetail.fromJson(Map<String, dynamic> json) {
    List<LeadOption> options(String key) => (json[key] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => LeadOption.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    List<Map<String, dynamic>> rows(String key) =>
        (json[key] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

    return LeadDetail(
      lead: Lead.fromJson(
          Map<String, dynamic>.from(json['lead'] as Map)),
      activities:
          rows('activities').map(LeadActivity.fromJson).toList(),
      handovers: rows('handovers'),
      recommendations: rows('recommendations'),
      agents: options('agents'),
      owners: options('owners'),
      campaigns: options('campaigns'),
    );
  }
}

class LeadsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<LeadIndex> fetch({
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
      final res = await _dio.get(ApiEndpoints.leads, queryParameters: query);
      final body = res.data['data'] as Map<String, dynamic>;
      final meta = body['meta'] as Map<String, dynamic>? ?? {};
      return LeadIndex(
        paged: Paged<Lead>(
          items: (body['data'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map((e) => Lead.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
          currentPage: meta['current_page'] ?? 1,
          lastPage: meta['last_page'] ?? 1,
          perPage: meta['per_page'] ?? perPage,
          total: meta['total'] ?? 0,
        ),
        statuses: (body['statuses'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        sources: (body['sources'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        campaigns: (body['campaigns'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => LeadOption.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load leads.');
    }
  }

  Future<LeadDetail> show(int id) async {
    try {
      final res = await _dio.get(ApiEndpoints.lead(id));
      return LeadDetail.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load lead.');
    }
  }

  Future<void> create(Map<String, dynamic> payload) async {
    try {
      await _dio.post(ApiEndpoints.leads, data: payload);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to create lead.');
    }
  }

  Future<void> update(int id, Map<String, dynamic> payload) async {
    try {
      await _dio.put(ApiEndpoints.lead(id), data: payload);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update lead.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete(ApiEndpoints.lead(id));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to delete lead.');
    }
  }

  Future<void> reassign(int id, {int? agentId, String? reason, String? notes}) async {
    try {
      await _dio.post(
        ApiEndpoints.leadReassign(id),
        data: {
          if (agentId != null) 'assigned_agent_id': agentId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to reassign lead.');
    }
  }

  Future<void> addActivity(int id, {required String type, required String title, String? description}) async {
    try {
      await _dio.post(
        ApiEndpoints.leadAddActivity(id),
        data: {'type': type, 'title': title, if (description != null) 'description': description},
      );
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to log activity.');
    }
  }

  Future<void> changeStatus(int id, String status) async {
    try {
      await _dio.post(ApiEndpoints.leadStatus(id), data: {'status': status});
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update status.');
    }
  }

  Future<void> convertToDeal(int id, {required double dealValue, int? propertyId, String? stage}) async {
    try {
      await _dio.post(
        ApiEndpoints.leadConvert(id),
        data: {
          'deal_value': dealValue,
          if (propertyId != null) 'property_id': propertyId,
          if (stage != null) 'stage': stage,
        },
      );
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to convert lead.');
    }
  }
}