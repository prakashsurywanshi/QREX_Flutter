import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/booking.dart';

class BookingIndex {
  final List<Booking> bookings;
  final BookingSummary summary;

  const BookingIndex({this.bookings = const [], this.summary = const BookingSummary()});
}

class BookingsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<BookingIndex> fetch() async {
    try {
      final res = await _dio.get(ApiEndpoints.bookings);
      final body = res.data['data'] as Map<String, dynamic>;
      final list = (body['bookings'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Booking.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return BookingIndex(
        bookings: list,
        summary: BookingSummary.fromList(list),
      );
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load bookings.');
    }
  }

  Future<BookingDetail> show(int id) async {
    try {
      final res = await _dio.get(ApiEndpoints.booking(id));
      return BookingDetail.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load booking.');
    }
  }

  Future<Booking> create(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post(ApiEndpoints.bookings, data: payload);
      final d = res.data['data'];
      return Booking.fromJson(
          d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{});
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to create booking.');
    }
  }

  Future<Booking> update(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put(ApiEndpoints.booking(id), data: payload);
      final d = res.data['data'];
      return Booking.fromJson(
          d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{});
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update booking.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete(ApiEndpoints.booking(id));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to delete booking.');
    }
  }
}