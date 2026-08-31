import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/campaign.dart';

class CampaignSummary {
  final double totalBudget;
  final double totalSpent;
  final int totalLeads;
  final double totalRevenue;

  const CampaignSummary({
    this.totalBudget = 0,
    this.totalSpent = 0,
    this.totalLeads = 0,
    this.totalRevenue = 0,
  });
}

class MarketingRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<MarketingIndex> fetch() async {
    try {
      final res = await _dio.get(ApiEndpoints.campaigns);
      return MarketingIndex.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load campaigns.');
    }
  }

  Future<Campaign> create(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post(ApiEndpoints.campaigns, data: payload);
      final d = res.data['data'];
      return Campaign.fromJson(
          d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{});
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to create campaign.');
    }
  }

  Future<Campaign> update(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put(ApiEndpoints.campaign(id), data: payload);
      final d = res.data['data'];
      return Campaign.fromJson(
          d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{});
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update campaign.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete(ApiEndpoints.campaign(id));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to delete campaign.');
    }
  }
}