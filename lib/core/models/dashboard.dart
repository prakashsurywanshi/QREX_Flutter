import '../utils/num_parsers.dart';

class DashboardStats {
  final int totalProperties;
  final int availableProperties;
  final int soldProperties;
  final int activeLeads;
  final int newLeads;
  final int siteVisits;
  final int activeDeals;
  final double revenue;
  final double pendingPayments;
  final double received;

  DashboardStats({
    required this.totalProperties,
    required this.availableProperties,
    required this.soldProperties,
    required this.activeLeads,
    required this.newLeads,
    required this.siteVisits,
    required this.activeDeals,
    required this.revenue,
    required this.pendingPayments,
    required this.received,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalProperties: parseInt(json['totalProperties']),
      availableProperties: parseInt(json['availableProperties']),
      soldProperties: parseInt(json['soldProperties']),
      activeLeads: parseInt(json['activeLeads']),
      newLeads: parseInt(json['newLeads']),
      siteVisits: parseInt(json['siteVisits']),
      activeDeals: parseInt(json['activeDeals']),
      revenue: parseDouble(json['revenue']),
      pendingPayments: parseDouble(json['pendingPayments']),
      received: parseDouble(json['received']),
    );
  }
}

class DashboardChartData {
  final List<RevenuePoint> revenueByMonth;
  final List<LeadSource> leadSources;
  final List<PipelineStage> pipelineFunnel;
  final List<AgentPerformance> agentPerformance;
  final List<MonthlyBooking> monthlyBookings;

  DashboardChartData({
    required this.revenueByMonth,
    required this.leadSources,
    required this.pipelineFunnel,
    required this.agentPerformance,
    required this.monthlyBookings,
  });

  factory DashboardChartData.fromJson(Map<String, dynamic> json) {
    return DashboardChartData(
      revenueByMonth: (json['revenueByMonth'] as List? ?? [])
          .map((e) => RevenuePoint.fromJson(e))
          .toList(),
      leadSources: (json['leadSources'] as List? ?? [])
          .map((e) => LeadSource.fromJson(e))
          .toList(),
      pipelineFunnel: (json['pipelineFunnel'] as List? ?? [])
          .map((e) => PipelineStage.fromJson(e))
          .toList(),
      agentPerformance: (json['agentPerformance'] as List? ?? [])
          .map((e) => AgentPerformance.fromJson(e))
          .toList(),
      monthlyBookings: (json['monthlyBookings'] as List? ?? [])
          .map((e) => MonthlyBooking.fromJson(e))
          .toList(),
    );
  }
}

class RevenuePoint {
  final String month;
  final double revenue;
  final int leads;

  RevenuePoint({required this.month, required this.revenue, required this.leads});

  factory RevenuePoint.fromJson(Map<String, dynamic> json) => RevenuePoint(
        month: json['month'] ?? '',
        revenue: parseDouble(json['revenue']),
        leads: parseInt(json['leads']),
      );
}

class LeadSource {
  final String name;
  final int value;

  LeadSource({required this.name, required this.value});

  factory LeadSource.fromJson(Map<String, dynamic> json) => LeadSource(
        name: json['name'] ?? '',
        value: parseInt(json['value']),
      );
}

class PipelineStage {
  final String stage;
  final int count;

  PipelineStage({required this.stage, required this.count});

  factory PipelineStage.fromJson(Map<String, dynamic> json) => PipelineStage(
        stage: json['stage'] ?? '',
        count: parseInt(json['count']),
      );
}

class AgentPerformance {
  final String name;
  final double revenue;

  AgentPerformance({required this.name, required this.revenue});

  factory AgentPerformance.fromJson(Map<String, dynamic> json) =>
      AgentPerformance(
        name: json['name'] ?? '',
        revenue: parseDouble(json['revenue']),
      );
}

class MonthlyBooking {
  final String month;
  final int bookings;

  MonthlyBooking({required this.month, required this.bookings});

  factory MonthlyBooking.fromJson(Map<String, dynamic> json) => MonthlyBooking(
        month: json['month'] ?? '',
        bookings: parseInt(json['bookings']),
      );
}

class DashboardData {
  final String range;
  final DashboardStats stats;
  final DashboardChartData chartData;
  final List<Map<String, dynamic>> recentLeads;
  final List<Map<String, dynamic>> upcomingVisits;
  final List<Map<String, dynamic>> recentBookings;
  final List<Map<String, dynamic>> recentPayments;
  final List<Map<String, dynamic>> topAgents;
  final List<Map<String, dynamic>> followUpsDue;
  final List<Map<String, dynamic>> recentActivity;
  final List<Map<String, dynamic>> featuredProperties;

  DashboardData({
    required this.range,
    required this.stats,
    required this.chartData,
    required this.recentLeads,
    required this.upcomingVisits,
    required this.recentBookings,
    required this.recentPayments,
    required this.topAgents,
    required this.followUpsDue,
    required this.recentActivity,
    required this.featuredProperties,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> list(String key) =>
        (json[key] as List? ?? []).whereType<Map>().cast<Map<String, dynamic>>().toList();

    return DashboardData(
      range: json['range'] ?? 'month',
      stats: DashboardStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      chartData: DashboardChartData.fromJson(
          json['chartData'] as Map<String, dynamic>? ?? {}),
      recentLeads: list('recentLeads'),
      upcomingVisits: list('upcomingVisits'),
      recentBookings: list('recentBookings'),
      recentPayments: list('recentPayments'),
      topAgents: list('topAgents'),
      followUpsDue: list('followUpsDue'),
      recentActivity: list('recentActivity'),
      featuredProperties: list('featuredProperties'),
    );
  }
}
