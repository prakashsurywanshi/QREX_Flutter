import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/property.dart';
import '../../../core/models/property_image.dart';
import '../../../core/models/property_type.dart';
import '../../../core/notifiers/paged_state.dart';
import '../data/properties_repository.dart';

final propertiesRepositoryProvider = Provider<PropertiesRepository>((ref) {
  return PropertiesRepository();
});

/// Populated lazily after the first index fetch (used by forms + filters).
class PropertyLookups {
  final List<String> statuses;
  final List<String> types;
  final List<PropertyTypeMeta> typeOptions;
  const PropertyLookups({
    this.statuses = const [],
    this.types = const [],
    this.typeOptions = const [],
  });
}

class PropertiesController extends StateNotifier<PagedState<Property>> {
  final PropertiesRepository _repo;

  PropertiesController(this._repo) : super(const PagedState());

  List<String> _statuses = const [];
  List<String> _types = const [];
  List<PropertyTypeMeta> _typeOptions = const [];

  PropertyLookups get lookups => PropertyLookups(
    statuses: _statuses,
    types: _types,
    typeOptions: _typeOptions,
  );

  PropertyTypeMeta? metaFor(String? type) {
    if (type == null || type.isEmpty) return null;
    for (final m in _typeOptions) {
      if (m.name == type) return m;
    }
    return null;
  }

  /// Catalog options for a type, falling back to the show-endpoint payload
  /// when it has been loaded for the property being viewed.
  PropertyTypeOptions? optionsFor(String? type, {PropertyTypeOptions? fallback}) {
    final meta = metaFor(type);
    if (meta != null) {
      return PropertyTypeOptions(amenities: meta.amenities, spec: meta.spec);
    }
    return fallback;
  }

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
      _statuses = idx.statuses;      _types = idx.types;
      _typeOptions = idx.typeOptions;
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
      _statuses = idx.statuses;      _types = idx.types;
      _typeOptions = idx.typeOptions;
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

  Future<Property> createProperty(Map<String, dynamic> payload) async {
    final created = await _repo.create(payload);
    refresh();
    return created;
  }

  Future<Property> updateProperty(int id, Map<String, dynamic> payload) async {
    final updated = await _repo.update(id, payload);
    refresh();
    return updated;
  }

  Future<void> deleteProperty(int id) async {
    await _repo.delete(id);
    refresh();
  }

  Future<void> uploadPropertyImages(int propertyId, List<String> paths) async {
    await _repo.uploadImages(propertyId, paths);
    refresh();
  }

  Future<List<PropertyImage>> uploadPropertyImagesWithReturn(
    int propertyId,
    List<String> paths,
  ) async {
    final created = await _repo.uploadImages(propertyId, paths);
    refresh();
    return created;
  }

  Future<void> deletePropertyImage(int propertyId, int imageId) async {
    await _repo.deleteImage(propertyId, imageId);
    refresh();
  }

  Future<void> setCoverImage(int propertyId, int imageId) async {
    await _repo.setCover(propertyId, imageId);
    refresh();
  }
}

final propertiesControllerProvider =
    StateNotifierProvider<PropertiesController, PagedState<Property>>((ref) {
      return PropertiesController(ref.watch(propertiesRepositoryProvider));
    });
