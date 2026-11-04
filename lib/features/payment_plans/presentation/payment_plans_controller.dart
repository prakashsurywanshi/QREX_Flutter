import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/payment_plan.dart';
import '../../../core/providers/auth_providers.dart';
import '../data/payment_plans_repository.dart';

final paymentPlansRepositoryProvider = Provider((ref) => PaymentPlansRepository(ref.watch(apiClientProvider)));
final paymentPlansListProvider = FutureProvider.autoDispose<List<PaymentPlan>>((ref) async {
  return ref.watch(paymentPlansRepositoryProvider).list();
});
