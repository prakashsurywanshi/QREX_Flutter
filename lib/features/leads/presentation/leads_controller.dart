import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/lead.dart';
import '../../../core/notifiers/paged_state.dart';
import '../data/leads_repository.dart';

final leadsRepositoryProvider = Provider<LeadsRepository>((ref) {
  return LeadsRepository();
});

class LeadLookups {
  final List<String> statuses;
  final List<String> sources;
  final List<LeadOption> campaigns;

  const LeadLookups({
    this.statuses = const [],
    this.sources = const [],
    this.campaigns = const [],
  });
}

class LeadsController extends StateNotifier<PagedState<Lead>> {
  final LeadsRepository _repo;

  LeadsController(this._repo) : super(const PagedState());

  List<String> _statuses = const [];
  List<String> _sources = const [];
  List<LeadOption> _campaigns = const [];

  LeadLookups get lookups => LeadLookups(
      statuses: _statuses, sources: _sources, campaigns: _campaigns);

  Future<void> load({bool reset = false}) async {
    if (state.loading) return;
    final page = reset ? 1 : state.currentPage;

    state = state.copyWith(loading: true, currentPage: page, clearError: true);
    try {
      final idx = await _repo.fetch(
        page: page,
        search: state.search,
        filters: state.filters,
      );
      _statuses = idx.statuses;
      _sources = idx.sources;
      _campaigns = idx.campaigns;
      state = state.copyWith(
        items: reset ? idx.paged.items : [...state.items, ...idx.paged.items],
        currentPage: idx.paged.currentPage,
        lastPage: idx.paged.lastPage,
        total: idx.paged.total,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void refresh() => load(reset: true);

  Future<void> loadPage(int page) async {
    if (state.loading) return;
    state = state.copyWith(loading: true, currentPage: page, clearError: true);
    try {
      final idx = await _repo.fetch(
        page: page,
        search: state.search,
        filters: state.filters,
      );
      _statuses = idx.statuses;
      _sources = idx.sources;
      _campaigns = idx.campaigns;
      state = state.copyWith(
        items: idx.paged.items,
        currentPage: idx.paged.currentPage,
        lastPage: idx.paged.lastPage,
        total: idx.paged.total,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void search(String term) {
    state = state.copyWith(search: term);
    load(reset: true);
  }

  Future<void> setFilter(String key, String value) async {
    final next = {...state.filters, key: value};
    if (value.isEmpty || value == 'All') next.remove(key);
    state = state.copyWith(filters: next);
    await load(reset: true);
  }

  Future<void> createLead(Map<String, dynamic> payload) async {
    await _repo.create(payload);
    refresh();
  }

  Future<void> deleteLead(int id) async {
    await _repo.delete(id);
    refresh();
  }
}

final leadsControllerProvider =
    StateNotifierProvider<LeadsController, PagedState<Lead>>((ref) {
  return LeadsController(ref.watch(leadsRepositoryProvider));
});