import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/commission.dart';
import '../../../core/providers/auth_providers.dart';
import '../data/commissions_repository.dart';

final commissionsRepositoryProvider = Provider<CommissionsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CommissionsRepository(client);
});

final commissionsListProvider = FutureProvider.autoDispose.family<({List<Commission> items, Map<String, dynamic> meta, Map<String, dynamic> summary}), ({int page, String? status, int? agentId})>((ref, params) async {
  final repo = ref.watch(commissionsRepositoryProvider);
  return repo.list(page: params.page, status: params.status, agentId: params.agentId);
});

final commissionDetailProvider = FutureProvider.autoDispose.family<Commission, int>((ref, id) async {
  final repo = ref.watch(commissionsRepositoryProvider);
  return repo.show(id);
});
