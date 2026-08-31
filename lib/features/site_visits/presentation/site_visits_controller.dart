import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/site_visit.dart';
import '../data/site_visits_repository.dart';

final siteVisitsRepositoryProvider = Provider<SiteVisitsRepository>((ref) {
  return SiteVisitsRepository();
});

class SiteVisitsState {
  final List<SiteVisitItem> visits;
  final bool loading;
  final String? error;

  const SiteVisitsState({
    this.visits = const [],
    this.loading = false,
    this.error,
  });

  SiteVisitsState copyWith({
    List<SiteVisitItem>? visits,
    bool? loading,
    String? error,
  }) {
    return SiteVisitsState(
      visits: visits ?? this.visits,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  List<SiteVisitItem> byStatus(String status) =>
      visits.where((v) => v.status == status).toList();
}

class SiteVisitsController extends StateNotifier<SiteVisitsState> {
  final SiteVisitsRepository _repo;

  SiteVisitsController(this._repo) : super(const SiteVisitsState());

  static const statuses = ['Scheduled', 'Completed', 'Cancelled', 'Rescheduled'];

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final visits = await _repo.fetch();
      state = state.copyWith(visits: visits, loading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> createVisit(Map<String, dynamic> payload) async {
    await _repo.create(payload);
    await load();
  }

  Future<void> updateVisit(int id, Map<String, dynamic> payload) async {
    await _repo.update(id, payload);
    await load();
  }

  Future<void> deleteVisit(int id) async {
    await _repo.delete(id);
    await load();
  }
}

final siteVisitsControllerProvider =
    StateNotifierProvider<SiteVisitsController, SiteVisitsState>((ref) {
  return SiteVisitsController(ref.watch(siteVisitsRepositoryProvider));
});