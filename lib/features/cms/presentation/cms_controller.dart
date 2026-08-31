import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/cms.dart';
import '../../../core/models/property.dart';
import '../data/cms_repository.dart';

final cmsRepositoryProvider = Provider<CmsRepository>((ref) {
  return CmsRepository();
});

class CmsState {
  final List<Property> featuredProperties;
  final List<CmsProperty> allProperties;
  final List<CmsAgent> agents;
  final List<CmsSection> sections;
  final bool loading;
  final String? error;

  const CmsState({
    this.featuredProperties = const [],
    this.allProperties = const [],
    this.agents = const [],
    this.sections = const [],
    this.loading = false,
    this.error,
  });

  CmsState copyWith({
    List<Property>? featuredProperties,
    List<CmsProperty>? allProperties,
    List<CmsAgent>? agents,
    List<CmsSection>? sections,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return CmsState(
      featuredProperties: featuredProperties ?? this.featuredProperties,
      allProperties: allProperties ?? this.allProperties,
      agents: agents ?? this.agents,
      sections: sections ?? this.sections,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CmsController extends StateNotifier<CmsState> {
  final CmsRepository _repo;

  CmsController(this._repo) : super(const CmsState());

  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final idx = await _repo.fetch();
      state = state.copyWith(
        featuredProperties: idx.featuredProperties,
        allProperties: idx.allProperties,
        agents: idx.agents,
        sections: idx.sections,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> toggleSection(String id, bool visible) async {
    await _repo.setSectionVisible(id, visible);
    state = state.copyWith(
      sections: [
        for (final s in state.sections)
          s.id == id ? s.copyWith(visible: visible) : s,
      ],
    );
  }

  Future<void> setFeatured(List<int> ids) async {
    await _repo.setFeatured(ids);
    await load();
  }
}

final cmsControllerProvider =
    StateNotifierProvider<CmsController, CmsState>((ref) {
  return CmsController(ref.watch(cmsRepositoryProvider));
});