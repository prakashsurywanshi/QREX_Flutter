import '../utils/num_parsers.dart';
import 'property.dart';

class Campaign {
  final int id;
  final String campaignId;
  final String name;
  final String channel;
  final double budget;
  final double spent;
  final int leads;
  final int conversions;
  final double revenue;
  final String revenueLabel;
  final String? roi;
  final String? startDate;
  final String? endDate;
  final String status;
  final String? createdAt;

  const Campaign({
    required this.id,
    this.campaignId = '',
    this.name = '',
    this.channel = '',
    this.budget = 0,
    this.spent = 0,
    this.leads = 0,
    this.conversions = 0,
    this.revenue = 0,
    this.revenueLabel = '—',
    this.roi,
    this.startDate,
    this.endDate,
    this.status = 'Scheduled',
    this.createdAt,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'],
      campaignId: json['campaign_id'] ?? '',
      name: json['name'] ?? '',
      channel: json['channel'] ?? '',
      budget: parseDouble(json['budget']),
      spent: parseDouble(json['spent']),
      leads: parseInt(json['leads']),
      conversions: parseInt(json['conversions']),
      revenue: parseDouble(json['revenue']),
      revenueLabel: json['revenue_label'] ?? '—',
      roi: json['roi'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      status: json['status'] ?? 'Scheduled',
      createdAt: json['created_at'],
    );
  }
}

class SourceDatum {
  final String name;
  final int value;

  const SourceDatum({required this.name, this.value = 0});

  factory SourceDatum.fromJson(Map<String, dynamic> json) {
    return SourceDatum(
      name: json['name'] ?? '',
      value: parseInt(json['value']),
    );
  }
}

class LandingLead {
  final String name;
  final String phone;
  final String status;
  final String created;

  const LandingLead({
    this.name = '',
    this.phone = '',
    this.status = '',
    this.created = '',
  });

  factory LandingLead.fromJson(Map<String, dynamic> json) {
    return LandingLead(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? '',
      created: json['created'] ?? '',
    );
  }
}

class ConversionStat {
  final String name;
  final int leads;
  final int conversions;
  final double revenue;

  const ConversionStat({
    this.name = '',
    this.leads = 0,
    this.conversions = 0,
    this.revenue = 0,
  });

  factory ConversionStat.fromJson(Map<String, dynamic> json) {
    return ConversionStat(
      name: json['name'] ?? '',
      leads: parseInt(json['leads']),
      conversions: parseInt(json['conversions']),
      revenue: parseDouble(json['revenue']),
    );
  }
}

class MarketingIndex {
  final List<Campaign> campaigns;
  final List<SourceDatum> leadSources;
  final List<Property> promotions;
  final List<LandingLead> landingLeads;
  final List<ConversionStat> conversions;

  const MarketingIndex({
    this.campaigns = const [],
    this.leadSources = const [],
    this.promotions = const [],
    this.landingLeads = const [],
    this.conversions = const [],
  });

  factory MarketingIndex.fromJson(Map<String, dynamic> json) {
    return MarketingIndex(
      campaigns: (json['campaigns'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Campaign.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      leadSources: (json['leadSources'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => SourceDatum.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      promotions: (json['propertyPromotions'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Property.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      landingLeads: (json['landingLeads'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => LandingLead.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      conversions: (json['conversionData'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => ConversionStat.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}