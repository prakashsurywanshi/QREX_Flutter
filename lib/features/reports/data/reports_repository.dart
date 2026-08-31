import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/report.dart';

class ReportsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<ReportsData> fetch({
    String range = 'all',
    int agentId = 0,
    int propertyId = 0,
  }) async {
    try {
      final res = await _dio.get(ApiEndpoints.reports, queryParameters: {
        if (range != 'all') 'range': range,
        if (agentId > 0) 'agent_id': agentId,
        if (propertyId > 0) 'property_id': propertyId,
      });
      return ReportsData.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load reports.');
    }
  }

  Future<String> exportCsv({
    String type = 'revenue',
    String range = 'all',
    int agentId = 0,
    int propertyId = 0,
  }) async {
    try {
      final dir = await getDownloadsDirectory();
      final savePath = '${dir?.path ?? Directory.systemTemp.path}/$type-${DateTime.now().millisecondsSinceEpoch}.csv';
      await _dio.download(
        ApiEndpoints.reportExport,
        savePath,
        queryParameters: {
          'type': type,
          if (range != 'all') 'range': range,
          if (agentId > 0) 'agent_id': agentId,
          if (propertyId > 0) 'property_id': propertyId,
        },
      );
      return savePath;
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to export CSV.');
    }
  }

  Future<String> exportPdf({
    String type = 'revenue',
    String range = 'all',
    int agentId = 0,
    int propertyId = 0,
  }) async {
    try {
      final dir = await getDownloadsDirectory();
      final savePath = '${dir?.path ?? Directory.systemTemp.path}/$type-${DateTime.now().millisecondsSinceEpoch}.pdf';
      await _dio.download(
        ApiEndpoints.reportExportPdf,
        savePath,
        queryParameters: {
          'type': type,
          if (range != 'all') 'range': range,
          if (agentId > 0) 'agent_id': agentId,
          if (propertyId > 0) 'property_id': propertyId,
        },
      );
      return savePath;
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to export PDF.');
    }
  }
}