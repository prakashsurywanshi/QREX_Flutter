import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/payment.dart';
import '../data/payments_repository.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository();
});

const paymentStatuses = ['Paid', 'Pending', 'Partially Paid', 'Overdue', 'Cancelled'];
const paymentModes = ['RTGS', 'NEFT', 'IMPS', 'UPI', 'Cheque', 'Bank Transfer', 'Cash'];

class PaymentsState {
  final List<Payment> payments;
  final PaymentSummary summary;
  final String statusFilter;
  final bool loading;
  final String? error;

  const PaymentsState({
    this.payments = const [],
    this.summary = const PaymentSummary(),
    this.statusFilter = 'All',
    this.loading = false,
    this.error,
  });

  List<Payment> get filtered => statusFilter == 'All'
      ? payments
      : payments.where((p) => p.status == statusFilter).toList();

  PaymentsState copyWith({
    List<Payment>? payments,
    PaymentSummary? summary,
    String? statusFilter,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return PaymentsState(
      payments: payments ?? this.payments,
      summary: summary ?? this.summary,
      statusFilter: statusFilter ?? this.statusFilter,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PaymentsController extends StateNotifier<PaymentsState> {
  final PaymentsRepository _repo;

  PaymentsController(this._repo) : super(const PaymentsState());

  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final idx = await _repo.fetch();
      state = state.copyWith(
        payments: idx.payments,
        summary: idx.summary,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void filterStatus(String status) {
    state = state.copyWith(statusFilter: status);
  }

  Future<void> createPayment(Map<String, dynamic> payload) async {
    await _repo.create(payload);
    await load();
  }

  Future<void> updatePayment(int id, Map<String, dynamic> payload) async {
    await _repo.update(id, payload);
    await load();
  }

  Future<void> setStatus(int id, String status) async {
    await _repo.update(id, {'status': status});
    await load();
  }

  Future<void> deletePayment(int id) async {
    await _repo.delete(id);
    await load();
  }
}

final paymentsControllerProvider =
    StateNotifierProvider<PaymentsController, PaymentsState>((ref) {
  return PaymentsController(ref.watch(paymentsRepositoryProvider));
});