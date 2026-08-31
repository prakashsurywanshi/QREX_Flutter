import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/customer.dart';
import '../../../core/notifiers/paged_state.dart';
import '../data/customers_repository.dart';

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository();
});

class CustomersController extends StateNotifier<PagedState<Customer>> {
  final CustomersRepository _repo;

  CustomersController(this._repo) : super(const PagedState());

  List<String> _statuses = const [];

  List<String> get statuses => _statuses;

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

  Future<void> createCustomer(Map<String, dynamic> payload) async {
    await _repo.create(payload);
    refresh();
  }

  Future<void> deleteCustomer(int id) async {
    await _repo.delete(id);
    refresh();
  }
}

final customersControllerProvider =
    StateNotifierProvider<CustomersController, PagedState<Customer>>((ref) {
  return CustomersController(ref.watch(customersRepositoryProvider));
});