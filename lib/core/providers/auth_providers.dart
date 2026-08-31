import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/user.dart';
import '../../features/auth/data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Whether we're still restoring a cached session on cold start.
final sessionRestoringProvider = StateProvider<bool>((ref) => true);

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  factory AuthState.unknown() => const AuthState(status: AuthStatus.unknown);
  factory AuthState.unauthenticated({String? error}) =>
      AuthState(status: AuthStatus.unauthenticated, error: error);
  factory AuthState.authenticated(User user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthController(this._repo, this._ref) : super(AuthState.unknown());

  /// Restore a cached user from secure storage (non-blocking, offline-safe).
  ///
  /// Guarded by a timeout for two reasons: on cold start we want the splash to
  /// resolve quickly, and on some platforms (e.g. desktop without a running
  /// keyring daemon) the secure-storage read can hang indefinitely.
  Future<void> restoreSession() async {
    try {
      final cached = await _repo
          .cachedUser()
          .timeout(const Duration(seconds: 3));
      if (cached != null) {
        state = AuthState.authenticated(cached);
        _refreshFromServer();
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      // Storage read failed/timed out: treat as no cached session.
      state = AuthState.unauthenticated();
    } finally {
      _ref.read(sessionRestoringProvider.notifier).state = false;
    }
  }

  /// Fetches the freshest user + permissions from the server after restore.
  Future<void> _refreshFromServer() async {
    try {
      final fresh = await _repo.me();
      if (mounted) state = AuthState.authenticated(fresh);
    } catch (_) {
      // Keep cached session if server unreachable.
    }
  }

  /// Public helper: refresh the current user from the server.
  Future<void> refresh() => _refreshFromServer();

  Future<void> login(String email, String password) async {
    try {
      final result = await _repo.login(email: email, password: password);
      state = AuthState.authenticated(result.user);
    } catch (e) {
      // Any failure (ApiException or otherwise) must leave the user on the
      // login form with an error - never linger in the "unknown" state, which
      // would otherwise bounce the router onto the splash screen.
      final msg = e is ApiException ? e.message : 'Unable to log in. Please try again.';
      state = AuthState.unauthenticated(error: msg);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthState.unauthenticated();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref);
});

/// Convenience read-only providers for the current user and convenience
/// permission/role helpers.
final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authControllerProvider);
  return state.user;
});

final currentUserAsyncProvider =
    StreamProvider<User?>((ref) => Stream.value(ref.watch(currentUserProvider)));
