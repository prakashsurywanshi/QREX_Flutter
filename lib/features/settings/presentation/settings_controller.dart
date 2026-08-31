import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/settings.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

class SettingsState {
  final SettingsIndex index;
  final bool loading;
  final String? error;

  const SettingsState({
    this.index = const SettingsIndex(),
    this.loading = false,
    this.error,
  });

  SettingsState copyWith({
    SettingsIndex? index,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return SettingsState(
      index: index ?? this.index,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  final SettingsRepository _repo;

  SettingsController(this._repo) : super(const SettingsState());

  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final idx = await _repo.fetch();
      state = state.copyWith(index: idx, loading: false);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> save(Map<String, dynamic> payload) async {
    await _repo.update(payload);
    final merged = state.index.settings.mergedWith(payload);
    state = state.copyWith(
      index: SettingsIndex(
        settings: SettingsData.fromJson(merged),
        smtp: state.index.smtp,
      ),
    );
  }

  Future<void> saveSmtp(Map<String, dynamic> payload) async {
    await _repo.updateSmtp(payload);
    final s = state.index.smtp;
    state = state.copyWith(
      index: SettingsIndex(
        settings: state.index.settings,
        smtp: SmtpConfig(
          enabled: payload['enabled'] ?? s.enabled,
          host: payload['host'] ?? s.host,
          port: payload['port'] ?? s.port,
          username: payload['username'] ?? s.username,
          password: payload['password'] ?? s.password,
          encryption: payload['encryption'] ?? s.encryption,
          fromAddress: payload['from_address'] ?? s.fromAddress,
          fromName: payload['from_name'] ?? s.fromName,
          testEmail: payload['test_email'] ?? s.testEmail,
        ),
      ),
    );
  }

  Future<void> testMail(String email) async {
    await _repo.testMail(email);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController(ref.watch(settingsRepositoryProvider));
});