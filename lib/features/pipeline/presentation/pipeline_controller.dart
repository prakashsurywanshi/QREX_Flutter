import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/deal.dart';
import '../../../core/models/lead.dart';
import '../data/pipeline_repository.dart';

final pipelineRepositoryProvider = Provider<PipelineRepository>((ref) {
  return PipelineRepository();
});

class PipelineState {
  final List<Deal> deals;
  final List<String> stages;
  final PipelineSummary summary;
  final List<LeadOption> agents;
  final List<LeadOption> properties;
  final List<LeadOption> customers;
  final List<LeadOption> leads;
  final bool loading;
  final String? error;

  const PipelineState({
    this.deals = const [],
    this.stages = const [],
    this.summary = const PipelineSummary(),
    this.agents = const [],
    this.properties = const [],
    this.customers = const [],
    this.leads = const [],
    this.loading = false,
    this.error,
  });

  List<Deal> dealsIn(String stage) =>
      deals.where((d) => d.stage == stage).toList();

  PipelineState copyWith({
    List<Deal>? deals,
    List<String>? stages,
    PipelineSummary? summary,
    List<LeadOption>? agents,
    List<LeadOption>? properties,
    List<LeadOption>? customers,
    List<LeadOption>? leads,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return PipelineState(
      deals: deals ?? this.deals,
      stages: stages ?? this.stages,
      summary: summary ?? this.summary,
      agents: agents ?? this.agents,
      properties: properties ?? this.properties,
      customers: customers ?? this.customers,
      leads: leads ?? this.leads,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PipelineController extends StateNotifier<PipelineState> {
  final PipelineRepository _repo;

  PipelineController(this._repo) : super(const PipelineState());

  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final idx = await _repo.fetch();
      state = state.copyWith(
        deals: idx.deals,
        stages: idx.stages,
        summary: idx.summary,
        agents: idx.agents,
        properties: idx.properties,
        customers: idx.customers,
        leads: idx.leads,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<Deal> moveStage(int id, String stage) async {
    final updated = await _repo.moveStage(id, stage);
    await load();
    return updated;
  }

  Future<void> createDeal(Map<String, dynamic> payload) async {
    await _repo.create(payload);
    await load();
  }

  Future<void> updateDeal(int id, Map<String, dynamic> payload) async {
    await _repo.update(id, payload);
    await load();
  }

  Future<void> deleteDeal(int id) async {
    await _repo.delete(id);
    await load();
  }
}

final pipelineControllerProvider =
    StateNotifierProvider<PipelineController, PipelineState>((ref) {
  return PipelineController(ref.watch(pipelineRepositoryProvider));
});