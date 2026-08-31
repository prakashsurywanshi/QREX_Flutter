import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/booking.dart';
import '../data/bookings_repository.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return BookingsRepository();
});

const bookingStatuses = [
  'Booking Pending',
  'Booking Confirmed',
  'Under Agreement',
  'Agreement Signed',
  'Cancelled',
];

const agreementStatuses = ['Pending', 'Under Review', 'Signed'];
const possessionStatuses = ['Pending', 'In Process', 'Handed Over'];

class BookingsState {
  final List<Booking> bookings;
  final String statusFilter;
  final bool loading;
  final String? error;

  const BookingsState({
    this.bookings = const [],
    this.statusFilter = 'All',
    this.loading = false,
    this.error,
  });

  List<Booking> get filtered => statusFilter == 'All'
      ? bookings
      : bookings.where((b) => b.status == statusFilter).toList();

  BookingsState copyWith({
    List<Booking>? bookings,
    String? statusFilter,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return BookingsState(
      bookings: bookings ?? this.bookings,
      statusFilter: statusFilter ?? this.statusFilter,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BookingsController extends StateNotifier<BookingsState> {
  final BookingsRepository _repo;

  BookingsController(this._repo) : super(const BookingsState());

  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final idx = await _repo.fetch();
      state = state.copyWith(bookings: idx.bookings, loading: false);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void filterStatus(String status) {
    state = state.copyWith(statusFilter: status);
  }

  Future<void> createBooking(Map<String, dynamic> payload) async {
    await _repo.create(payload);
    await load();
  }

  Future<void> updateBooking(int id, Map<String, dynamic> payload) async {
    await _repo.update(id, payload);
    await load();
  }

  Future<void> deleteBooking(int id) async {
    await _repo.delete(id);
    await load();
  }
}

final bookingsControllerProvider =
    StateNotifierProvider<BookingsController, BookingsState>((ref) {
  return BookingsController(ref.watch(bookingsRepositoryProvider));
});