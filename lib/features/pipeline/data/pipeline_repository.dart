import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/deal.dart';
import '../../../core/models/lead.dart';

class PipelineIndex {
  final List<Deal> deals;
  final List<String> stages;
  final PipelineSummary summary;
  final List<LeadOption> agents;
  final List<LeadOption> properties;
  final List<LeadOption> customers;
  final List<LeadOption> leads;

  const PipelineIndex({
    this.deals = const [],
    this.stages = const [],
    this.summary = const PipelineSummary(),
    this.agents = const [],
    this.properties = const [],
    this.customers = const [],
    this.leads = const [],
  });

  factory PipelineIndex.fromJson(Map<String, dynamic> json) {
    List<LeadOption> options(String key) => (json[key] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => LeadOption.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return PipelineIndex(
      deals: (json['deals'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Deal.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      stages: (json['stages'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      summary: PipelineSummary.fromJson(
          json['summary'] as Map<String, dynamic>? ?? {}),
      agents: options('agents'),
      properties: options('properties'),
      customers: options('customers'),
      leads: options('leads'),
    );
  }
}

class PipelineRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<PipelineIndex> fetch() async {
    try {
      final res = await _dio.get(ApiEndpoints.pipeline);
      return PipelineIndex.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load pipeline.');
    }
  }

  Future<Deal> create(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post(ApiEndpoints.pipeline, data: payload);
      return Deal.fromJson(
          Map<String, dynamic>.from(res.data['data'] as Map));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to create deal.');
    }
  }

  Future<Deal> update(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put(ApiEndpoints.deal(id), data: payload);
      return Deal.fromJson(
          Map<String, dynamic>.from(res.data['data'] as Map));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update deal.');
    }
  }

  Future<Deal> moveStage(int id, String stage) async {
    try {
      final res = await _dio.post(ApiEndpoints.dealMoveStage(id),
          data: {'stage': stage});
      return Deal.fromJson(
          Map<String, dynamic>.from(res.data['data'] as Map));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to move deal.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete(ApiEndpoints.deal(id));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to delete deal.');
    }
  }
}