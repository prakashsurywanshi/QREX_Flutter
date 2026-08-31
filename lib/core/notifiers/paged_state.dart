/// Reusable loading/error/list state used by list-feature controllers.
class PagedState<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final String search;
  final Map<String, String> filters;

  const PagedState({
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.search = '',
    this.filters = const {},
  });

  bool get isEmpty => items.isEmpty;

  PagedState<T> copyWith({
    List<T>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
    String? search,
    Map<String, String>? filters,
  }) {
    return PagedState<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      filters: filters ?? this.filters,
    );
  }
}