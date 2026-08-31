import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/admin_user.dart';
import '../data/users_repository.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository();
});

class UsersState {
  final List<UserRecord> users;
  final List<RoleSummary> roles;
  final Map<String, Map<String, List<String>>> rolePermissions;
  final String roleFilter;
  final bool loading;
  final String? error;

  const UsersState({
    this.users = const [],
    this.roles = const [],
    this.rolePermissions = const {},
    this.roleFilter = 'All',
    this.loading = false,
    this.error,
  });

  List<UserRecord> get filtered => roleFilter == 'All'
      ? users
      : users.where((u) => u.role == roleFilter).toList();

  UsersState copyWith({
    List<UserRecord>? users,
    List<RoleSummary>? roles,
    Map<String, Map<String, List<String>>>? rolePermissions,
    String? roleFilter,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return UsersState(
      users: users ?? this.users,
      roles: roles ?? this.roles,
      rolePermissions: rolePermissions ?? this.rolePermissions,
      roleFilter: roleFilter ?? this.roleFilter,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UsersController extends StateNotifier<UsersState> {
  final UsersRepository _repo;

  UsersController(this._repo) : super(const UsersState());

  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final idx = await _repo.fetch();
      state = state.copyWith(
        users: idx.users,
        roles: idx.roles,
        rolePermissions: idx.rolePermissions,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void filterRole(String role) {
    state = state.copyWith(roleFilter: role);
  }

  Future<void> invite(Map<String, dynamic> payload) async {
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

final usersControllerProvider =
    StateNotifierProvider<UsersController, UsersState>((ref) {
  return UsersController(ref.watch(usersRepositoryProvider));
});