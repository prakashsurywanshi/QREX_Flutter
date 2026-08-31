import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_notification.dart';
import '../data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository();
});

class NotificationsState {
  final List<AppNotification> notifications;
  final int unread;
  final bool loading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.unread = 0,
    this.loading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    int? unread,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unread: unread ?? this.unread,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsController extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repo;

  NotificationsController(this._repo) : super(const NotificationsState());

  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final idx = await _repo.fetch();
      state = state.copyWith(
        notifications: idx.notifications,
        unread: idx.unread,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> markRead(int id) async {
    await _repo.markRead(id);
    state = state.copyWith(
      notifications: [
        for (final n in state.notifications)
          n.id == id ? AppNotification.fromJson({..._toJson(n), 'is_read': true}) : n,
      ],
      unread: state.unread > 0 ? state.unread - 1 : 0,
    );
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    state = state.copyWith(
      notifications: [
        for (final n in state.notifications)
          AppNotification.fromJson({..._toJson(n), 'is_read': true}),
      ],
      unread: 0,
    );
  }

  Map<String, dynamic> _toJson(AppNotification n) => {
        'id': n.id,
        'title': n.title,
        'message': n.message,
        'type': n.type,
        'related_id': n.relatedId,
        'url': n.url,
        'is_read': n.isRead,
        'created_at': n.createdAt,
      };
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
  return NotificationsController(ref.watch(notificationsRepositoryProvider));
});