import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/cms.dart';

class CmsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<CmsIndex> fetch() async {
    try {
      final res = await _dio.get(ApiEndpoints.cms);
      return CmsIndex.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load CMS.');
    }
  }

  Future<void> setSectionVisible(String section, bool visible) async {
    try {
      await _dio.put(ApiEndpoints.cmsSection(section),
          data: {'visible': visible});
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update section.');
    }
  }

  Future<void> setFeatured(List<int> ids) async {
    try {
      await _dio.put(ApiEndpoints.cmsFeatured, data: {'ids': ids});
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update featured properties.');
    }
  }
}