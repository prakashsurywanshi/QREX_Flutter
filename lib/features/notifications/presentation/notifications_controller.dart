import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/app_notification.dart';
import '../../../core/providers/auth_providers.dart';
import '../data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository(ref.watch(apiClientProvider)));
final notificationsListProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  return ref.watch(notificationsRepositoryProvider).list();
});
