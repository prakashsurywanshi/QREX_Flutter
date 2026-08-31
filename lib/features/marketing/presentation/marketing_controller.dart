import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/campaign.dart';
import '../../../core/models/property.dart';
import '../data/marketing_repository.dart';

final marketingRepositoryProvider = Provider<MarketingRepository>((ref) {
  return MarketingRepository();
});

const campaignStatuses = ['Scheduled', 'Active', 'Paused', 'Completed'];
const campaignChannels = [
  'Facebook + Instagram',
  'Google Ads',
  'LinkedIn + Email',
  'Print Media',
  'Referral Program',
  'Website SEO',
];

class MarketingState {
  final List<Campaign> campaigns;
  final List<SourceDatum> leadSources;
  final List<Property> promotions;
  final List<LandingLead> landingLeads;
  final List<ConversionStat> conversions;
  final bool loading;
  final String? error;

  const MarketingState({
    this.campaigns = const [],
    this.leadSources = const [],
    this.promotions = const [],
    this.landingLeads = const [],
    this.conversions = const [],
    this.loading = false,
    this.error,
  });

  MarketingState copyWith({
    List<Campaign>? campaigns,
    List<SourceDatum>? leadSources,
    List<Property>? promotions,
    List<LandingLead>? landingLeads,
    List<ConversionStat>? conversions,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return MarketingState(
      campaigns: campaigns ?? this.campaigns,
      leadSources: leadSources ?? this.leadSources,
      promotions: promotions ?? this.promotions,
      landingLeads: landingLeads ?? this.landingLeads,
      conversions: conversions ?? this.conversions,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MarketingController extends StateNotifier<MarketingState> {
  final MarketingRepository _repo;

  MarketingController(this._repo) : super(const MarketingState());

  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final idx = await _repo.fetch();
      state = state.copyWith(
        campaigns: idx.campaigns,
        leadSources: idx.leadSources,
        promotions: idx.promotions,
        landingLeads: idx.landingLeads,
        conversions: idx.conversions,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> createCampaign(Map<String, dynamic> payload) async {
    await _repo.create(payload);
    await load();
  }

  Future<void> updateCampaign(int id, Map<String, dynamic> payload) async {
    await _repo.update(id, payload);
    await load();
  }

  Future<void> setStatus(int id, String status) async {
    await _repo.update(id, {'status': status});
    await load();
  }

  Future<void> deleteCampaign(int id) async {
    await _repo.delete(id);
    await load();
  }
}

final marketingControllerProvider =
    StateNotifierProvider<MarketingController, MarketingState>((ref) {
  return MarketingController(ref.watch(marketingRepositoryProvider));
});