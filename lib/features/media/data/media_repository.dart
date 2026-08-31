import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/media_file.dart';

class MediaRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<MediaIndex> fetch() async {
    try {
      final res = await _dio.get(ApiEndpoints.media);
      return MediaIndex.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load media.');
    }
  }

  Future<MediaFile> upload({
    required String filePath,
    required String fileName,
    String? name,
    String folder = 'General',
    String? propertyName,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'folder': folder,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (propertyName != null && propertyName.trim().isNotEmpty)
          'property_name': propertyName.trim(),
      });
      final res = await _dio.post(ApiEndpoints.media, data: form);
      final d = res.data['data'];
      return MediaFile.fromJson(
          d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{});
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to upload file.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete(ApiEndpoints.mediaItem(id));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to delete file.');
    }
  }
}