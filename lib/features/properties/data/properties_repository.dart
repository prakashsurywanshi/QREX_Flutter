import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/paged.dart';
import '../../../core/models/property.dart';
import '../../../core/models/property_image.dart';
import '../../../core/models/property_type.dart';
import '../../../core/utils/num_parsers.dart';

class PropertyIndex {
  final Paged<Property> paged;
  final List<String> statuses;
  final List<String> types;

  /// Full property-type catalog (spec rules + valid amenities per type).
  final List<PropertyTypeMeta> typeOptions;

  const PropertyIndex({
    required this.paged,
    this.statuses = const [],
    this.types = const [],
    this.typeOptions = const [],
  });
}

/// A single property plus the catalog options for its type.
class PropertyDetail {
  final Property property;
  final PropertyTypeOptions typeOptions;

  const PropertyDetail({required this.property, this.typeOptions = const PropertyTypeOptions()});
}

class PropertiesRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<PropertyIndex> fetch({
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
      final res = await _dio.get(
        ApiEndpoints.properties,
        queryParameters: query,
      );
      final body = res.data['data'] as Map<String, dynamic>;
      final meta = body['meta'] as Map<String, dynamic>? ?? {};

      return PropertyIndex(
        paged: Paged<Property>(
          items: (body['data'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map((e) => Property.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
          currentPage: meta['current_page'] ?? 1,
          lastPage: meta['last_page'] ?? 1,
          perPage: meta['per_page'] ?? perPage,
          total: meta['total'] ?? 0,
        ),
        statuses: (body['statuses'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        types: (body['types'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        typeOptions: (body['type_options'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => PropertyTypeMeta.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load properties.');
    }
  }

  Future<PropertyDetail> show(int id) async {
    try {
      final res = await _dio.get(ApiEndpoints.property(id));
      final data = res.data['data'] as Map<String, dynamic>;
      return PropertyDetail(
        property: Property.fromJson(data['property'] as Map<String, dynamic>),
        typeOptions: PropertyTypeOptions.fromJson(
          data['type_options'] as Map<String, dynamic>? ??
              (data['type_options'] is Map
                  ? Map<String, dynamic>.from(data['type_options'] as Map)
                  : null),
        ),
      );
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load property.');
    }
  }

  Future<Property> create(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post(ApiEndpoints.properties, data: payload);
      final d = res.data['data'];
      return Property.fromJson(
        d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
      );
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to create property.');
    }
  }

  Future<Property> update(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put(ApiEndpoints.property(id), data: payload);
      final d = res.data['data'];
      return Property.fromJson(
        d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
      );
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update property.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete(ApiEndpoints.property(id));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to delete property.');
    }
  }

  Future<List<PropertyImage>> uploadImages(
    int propertyId,
    List<String> imagePaths,
  ) async {
    if (imagePaths.isEmpty) return [];
    try {
      final form = FormData.fromMap({
        'images[]': [
          for (final path in imagePaths)
            await MultipartFile.fromFile(path, filename: path.split('/').last),
        ],
      });
      final res = await _dio.post(
        ApiEndpoints.propertyImages(propertyId),
        data: form,
      );
      final d = res.data['data'];
      if (d is List) {
        return d
            .whereType<Map>()
            .map((e) => PropertyImage.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to upload images.');
    }
  }

  Future<void> deleteImage(int propertyId, int imageId) async {
    try {
      await _dio.delete(ApiEndpoints.propertyImage(propertyId, imageId));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to delete image.');
    }
  }

  Future<void> setCover(int propertyId, int imageId) async {
    try {
      await _dio.post(ApiEndpoints.propertyCover(propertyId, imageId));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to set cover image.');
    }
  }

  Future<List<(int, String)>> agents() async {
    try {
      final res = await _dio.get(ApiEndpoints.propertyAgents);
      final list =
          (res.data['data'] as Map<String, dynamic>)['agents']
              as List<dynamic>?;
      return (list ?? [])
          .whereType<Map>()
          .map((e) => (parseInt(e['id']), e['name'].toString()))
          .toList();
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load agents.');
    }
  }
}
