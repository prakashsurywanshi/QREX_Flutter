import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dashboard.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

/// Holds the current range selection + fetched dashboard data.
class DashboardState {
  final String range;
  final DashboardData? data;
  final bool loading;
  final String? error;

  const DashboardState({
    this.range = 'month',
    this.data,
    this.loading = false,
    this.error,
  });

  DashboardState copyWith({
    String? range,
    DashboardData? data,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      range: range ?? this.range,
      data: data ?? this.data,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  final DashboardRepository _repo;

  DashboardController(this._repo) : super(const DashboardState());

  static const ranges = [
    ('today', 'Today'),
    ('week', 'This Week'),
    ('month', 'This Month'),
    ('year', 'This Year'),
    ('all', 'All Time'),
  ];

  Future<void> load({String? range}) async {
    final target = range ?? state.range;
    if (state.loading) return;

    state = state.copyWith(range: target, loading: true, clearError: true);
    try {
      final data = await _repo.fetch(range: target);
      state = state.copyWith(data: data, loading: false);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void selectRange(String range) => load(range: range);
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  return DashboardController(ref.watch(dashboardRepositoryProvider));
});
