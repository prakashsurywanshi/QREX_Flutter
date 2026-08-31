import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/report.dart';
import '../data/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository();
});

const reportRanges = ['today', '7d', '30d', '90d', 'ytd', 'all'];
const reportRangesLabels = {
  'today': 'Today',
  '7d': '7 Days',
  '30d': '30 Days',
  '90d': '90 Days',
  'ytd': 'YTD',
  'all': 'All',
};

class ReportsState {
  final ReportsData data;
  final String range;
  final int agentId;
  final int propertyId;
  final bool loading;
  final String? error;

  const ReportsState({
    this.data = const ReportsData(),
    this.range = 'all',
    this.agentId = 0,
    this.propertyId = 0,
    this.loading = false,
    this.error,
  });

  ReportsState copyWith({
    ReportsData? data,
    String? range,
    int? agentId,
    int? propertyId,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return ReportsState(
      data: data ?? this.data,
      range: range ?? this.range,
      agentId: agentId ?? this.agentId,
      propertyId: propertyId ?? this.propertyId,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReportsController extends StateNotifier<ReportsState> {
  final ReportsRepository _repo;

  ReportsController(this._repo) : super(const ReportsState());

  Future<void> load() async {
    if (state.loading) return;
    await _fetch();
  }

  Future<void> applyFilter({String? range, int? agentId, int? propertyId}) async {
    final next = state.copyWith(
      range: range ?? state.range,
      agentId: agentId ?? state.agentId,
      propertyId: propertyId ?? state.propertyId,
      loading: true,
      clearError: true,
    );
    state = next;
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await _repo.fetch(
        range: state.range,
        agentId: state.agentId,
        propertyId: state.propertyId,
      );
      state = state.copyWith(data: data, loading: false);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<String> export({required String type, bool pdf = false}) async {
    return pdf
        ? _repo.exportPdf(
            type: type,
            range: state.range,
            agentId: state.agentId,
            propertyId: state.propertyId,
          )
        : _repo.exportCsv(
            type: type,
            range: state.range,
            agentId: state.agentId,
            propertyId: state.propertyId,
          );
  }
}

final reportsControllerProvider =
    StateNotifierProvider<ReportsController, ReportsState>((ref) {
  return ReportsController(ref.watch(reportsRepositoryProvider));
});