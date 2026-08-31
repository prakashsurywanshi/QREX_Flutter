import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/role.dart';
import '../data/roles_repository.dart';

final rolesRepositoryProvider = Provider<RolesRepository>((ref) {
  return RolesRepository();
});

class RolesState {
  final List<RoleRecord> roles;
  final List<PermissionNode> permissionTree;
  final bool loading;
  final String? error;

  const RolesState({
    this.roles = const [],
    this.permissionTree = const [],
    this.loading = false,
    this.error,
  });

  RolesState copyWith({
    List<RoleRecord>? roles,
    List<PermissionNode>? permissionTree,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return RolesState(
      roles: roles ?? this.roles,
      permissionTree: permissionTree ?? this.permissionTree,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RolesController extends StateNotifier<RolesState> {
  final RolesRepository _repo;

  RolesController(this._repo) : super(const RolesState());

  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final idx = await _repo.fetch();
      state = state.copyWith(
        roles: idx.roles,
        permissionTree: idx.permissionTree,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await _repo.create(payload);
    await load();
  }

  Future<void> update(int id, Map<String, dynamic> payload) async {
    await _repo.update(id, payload);
    await load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load();
  }
}

final rolesControllerProvider =
    StateNotifierProvider<RolesController, RolesState>((ref) {
  return RolesController(ref.watch(rolesRepositoryProvider));
});