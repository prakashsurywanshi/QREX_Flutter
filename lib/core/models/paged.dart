/// A simple paginated result from the API's `data` + `meta` envelope.
class Paged<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const Paged({
    required this.items,
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 10,
    this.total = 0,
  });

  bool get hasNext => currentPage < lastPage;
  bool get isEmpty => items.isEmpty;
}

/// Filters that clutter API index endpoints (shared surface).
class PagedFilters {
  final String? search;
  final Map<String, String> values;

  const PagedFilters({this.search, this.values = const {}});

  Map<String, dynamic> toQuery({int page = 1, int perPage = 10}) {
    final q = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
    };
    values.forEach((k, v) {
      if (v.isNotEmpty && v != 'All') q[k] = v;
    });
    return q;
  }
}