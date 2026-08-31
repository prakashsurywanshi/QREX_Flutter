import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/property.dart';
import '../../../core/notifiers/paged_state.dart';
import '../data/properties_repository.dart';

final propertiesRepositoryProvider = Provider<PropertiesRepository>((ref) {
  return PropertiesRepository();
});

/// Populated lazily after the first index fetch (used by forms + filters).
class PropertyLookups {
  final List<String> statuses;
  final List<String> types;
  const PropertyLookups({this.statuses = const [], this.types = const []});
}

class PropertiesController
    extends StateNotifier<PagedState<Property>> {
  final PropertiesRepository _repo;

  PropertiesController(this._repo) : super(const PagedState());

  List<String> _statuses = const [];
  List<String> _types = const [];

  PropertyLookups get lookups => PropertyLookups(statuses: _statuses, types: _types);

  Future<void> load({bool reset = false}) async {
    if (state.loading) return;
    final page = reset ? 1 : state.currentPage;

    state = state.copyWith(
      loading: true,
      currentPage: page,
      clearError: true,
    );
    try {
      final idx = await _repo.fetch(
        page: page,
        search: state.search,
        filters: state.filters,
      );
      _statuses = idx.statuses;
      _types = idx.types;
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
    state = state.copyWith(
      loading: true,
      currentPage: page,
      clearError: true,
    );
    try {
      final idx = await _repo.fetch(
        page: page,
        search: state.search,
        filters: state.filters,
      );
      _statuses = idx.statuses;
      _types = idx.types;
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

  Future<void> createProperty(Map<String, dynamic> payload) async {
    await _repo.create(payload);
    refresh();
  }

  Future<void> updateProperty(int id, Map<String, dynamic> payload) async {
    await _repo.update(id, payload);
    refresh();
  }

  Future<void> deleteProperty(int id) async {
    await _repo.delete(id);
    refresh();
  }
}

final propertiesControllerProvider =
    StateNotifierProvider<PropertiesController, PagedState<Property>>((ref) {
  return PropertiesController(ref.watch(propertiesRepositoryProvider));
});