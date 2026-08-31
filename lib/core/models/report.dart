import '../utils/num_parsers.dart';

class MonthPoint {
  final String month;
  final double revenue;
  final int leads;

  const MonthPoint({this.month = '', this.revenue = 0, this.leads = 0});

  factory MonthPoint.fromJson(Map<String, dynamic> json) => MonthPoint(
        month: json['month'] ?? '',
        revenue: parseDouble(json['revenue']),
        leads: parseInt(json['leads']),
      );
}

class NamedValue {
  final String name;
  final int value;

  const NamedValue({this.name = '', this.value = 0});

  factory NamedValue.fromJson(Map<String, dynamic> json) => NamedValue(
        name: json['name'] ?? '',
        value: parseInt(json['value']),
      );
}

class FunnelStage {
  final String stage;
  final int count;
  final double value;

  const FunnelStage({this.stage = '', this.count = 0, this.value = 0});

  factory FunnelStage.fromJson(Map<String, dynamic> json) => FunnelStage(
        stage: json['stage'] ?? '',
        count: parseInt(json['count']),
        value: parseDouble(json['value']),
      );
}

class AgentPerformance {
  final String name;
  final int deals;
  final double revenue;

  const AgentPerformance({this.name = '', this.deals = 0, this.revenue = 0});

  factory AgentPerformance.fromJson(Map<String, dynamic> json) =>
      AgentPerformance(
        name: json['name'] ?? '',
        deals: parseInt(json['deals']),
        revenue: parseDouble(json['revenue']),
      );
}

class MonthBookings {
  final String month;
  final int bookings;
  final double value;

  const MonthBookings({this.month = '', this.bookings = 0, this.value = 0});

  factory MonthBookings.fromJson(Map<String, dynamic> json) => MonthBookings(
        month: json['month'] ?? '',
        bookings: parseInt(json['bookings']),
        value: parseDouble(json['value']),
      );
}

class MonthPayment {
  final String month;
  final double collected;
  final double pending;

  const MonthPayment(
      {this.month = '', this.collected = 0, this.pending = 0});

  factory MonthPayment.fromJson(Map<String, dynamic> json) => MonthPayment(
        month: json['month'] ?? '',
        collected: parseDouble(json['collected']),
        pending: parseDouble(json['pending']),
      );
}

class PropertyPerformance {
  final String name;
  final int views;
  final int leads;
  final int deals;

  const PropertyPerformance(
      {this.name = '', this.views = 0, this.leads = 0, this.deals = 0});

  factory PropertyPerformance.fromJson(Map<String, dynamic> json) =>
      PropertyPerformance(
        name: json['name'] ?? '',
        views: parseInt(json['views']),
        leads: parseInt(json['leads']),
        deals: parseInt(json['deals']),
      );
}

class VisitStat {
  final int total;
  final int completed;
  final int scheduled;
  final int cancelled;
  final int rescheduled;

  const VisitStat({
    this.total = 0,
    this.completed = 0,
    this.scheduled = 0,
    this.cancelled = 0,
    this.rescheduled = 0,
  });

  factory VisitStat.fromJson(Map<String, dynamic> json) => VisitStat(
        total: parseInt(json['total']),
        completed: parseInt(json['completed']),
        scheduled: parseInt(json['scheduled']),
        cancelled: parseInt(json['cancelled']),
        rescheduled: parseInt(json['rescheduled']),
      );
}

class LostLeadStat {
  final int totalLost;
  final int converted;
  final int total;
  final List<NamedValue> bySource;

  const LostLeadStat({
    this.totalLost = 0,
    this.converted = 0,
    this.total = 0,
    this.bySource = const [],
  });

  factory LostLeadStat.fromJson(Map<String, dynamic> json) => LostLeadStat(
        totalLost: parseInt(json['totalLost']),
        converted: parseInt(json['converted']),
        total: parseInt(json['total']),
        bySource: (json['bySource'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => NamedValue.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class CampaignPerf {
  final String name;
  final String channel;
  final double budget;
  final double spent;
  final int leads;
  final int conversions;
  final double revenue;
  final String roi;
  final String status;
  final String start;
  final String end;

  const CampaignPerf({
    this.name = '',
    this.channel = '',
    this.budget = 0,
    this.spent = 0,
    this.leads = 0,
    this.conversions = 0,
    this.revenue = 0,
    this.roi = '',
    this.status = '',
    this.start = '',
    this.end = '',
  });

  factory CampaignPerf.fromJson(Map<String, dynamic> json) => CampaignPerf(
        name: json['name'] ?? '',
        channel: json['channel'] ?? '',
        budget: parseDouble(json['budget']),
        spent: parseDouble(json['spent']),
        leads: parseInt(json['leads']),
        conversions: parseInt(json['conversions']),
        revenue: parseDouble(json['revenue']),
        roi: json['roi'] ?? '',
        status: json['status'] ?? '',
        start: json['start'] ?? '',
        end: json['end'] ?? '',
      );
}

class VisitRow {
  final String id;
  final String customer;
  final String property;
  final String date;
  final String status;

  const VisitRow({
    this.id = '',
    this.customer = '',
    this.property = '',
    this.date = '',
    this.status = '',
  });

  factory VisitRow.fromJson(Map<String, dynamic> json) => VisitRow(
        id: json['id'] ?? '',
        customer: json['customer'] ?? '',
        property: json['property'] ?? '',
        date: json['date'] ?? '',
        status: json['status'] ?? '',
      );
}

class ReportDealRow {
  final String customer;
  final String property;
  final double value;
  final String stage;
  final int probability;
  final String agent;

  const ReportDealRow({
    this.customer = '',
    this.property = '',
    this.value = 0,
    this.stage = '',
    this.probability = 0,
    this.agent = '',
  });

  factory ReportDealRow.fromJson(Map<String, dynamic> json) => ReportDealRow(
        customer: json['customer'] ?? '',
        property: json['property'] ?? '',
        value: parseDouble(json['value']),
        stage: json['stage'] ?? '',
        probability: parseInt(json['probability']),
        agent: json['agent'] ?? '',
      );
}

class ReportPaymentRow {
  final String customer;
  final double amount;
  final String status;
  final String due;
  final String paid;

  const ReportPaymentRow({
    this.customer = '',
    this.amount = 0,
    this.status = '',
    this.due = '',
    this.paid = '',
  });

  factory ReportPaymentRow.fromJson(Map<String, dynamic> json) =>
      ReportPaymentRow(
        customer: json['customer'] ?? '',
        amount: parseDouble(json['amount']),
        status: json['status'] ?? '',
        due: json['due'] ?? '',
        paid: json['paid'] ?? '',
      );
}

class ReportLeadRow {
  final String name;
  final String phone;
  final String source;
  final String status;
  final String created;

  const ReportLeadRow({
    this.name = '',
    this.phone = '',
    this.source = '',
    this.status = '',
    this.created = '',
  });

  factory ReportLeadRow.fromJson(Map<String, dynamic> json) => ReportLeadRow(
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        source: json['source'] ?? '',
        status: json['status'] ?? '',
        created: json['created'] ?? '',
      );
}

class ReportTables {
  final List<ReportLeadRow> leads;
  final List<ReportDealRow> deals;
  final List<ReportPaymentRow> payments;

  const ReportTables({
    this.leads = const [],
    this.deals = const [],
    this.payments = const [],
  });

  factory ReportTables.fromJson(Map<String, dynamic> json) => ReportTables(
        leads: (json['leads'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => ReportLeadRow.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        deals: (json['deals'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => ReportDealRow.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        payments: (json['payments'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => ReportPaymentRow.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class ReportNameId {
  final int id;
  final String name;

  const ReportNameId({this.id = 0, this.name = ''});

  factory ReportNameId.fromJson(Map<String, dynamic> json) => ReportNameId(
        id: parseInt(json['id']),
        name: json['name'] ?? '',
      );
}

class ReportsData {
  final String range;
  final List<ReportNameId> agents;
  final List<ReportNameId> properties;
  final List<MonthPoint> revenueByMonth;
  final List<NamedValue> leadSourceData;
  final List<FunnelStage> pipelineFunnel;
  final List<AgentPerformance> agentPerformance;
  final List<MonthBookings> monthlyBookings;
  final List<MonthPayment> paymentData;
  final List<PropertyPerformance> propertyPerformance;
  final VisitStat siteVisitReport;
  final LostLeadStat lostLeadReport;
  final List<CampaignPerf> campaignPerformance;
  final List<VisitRow> siteVisits;
  final ReportTables reportTables;

  const ReportsData({
    this.range = 'all',
    this.agents = const [],
    this.properties = const [],
    this.revenueByMonth = const [],
    this.leadSourceData = const [],
    this.pipelineFunnel = const [],
    this.agentPerformance = const [],
    this.monthlyBookings = const [],
    this.paymentData = const [],
    this.propertyPerformance = const [],
    this.siteVisitReport = const VisitStat(),
    this.lostLeadReport = const LostLeadStat(),
    this.campaignPerformance = const [],
    this.siteVisits = const [],
    this.reportTables = const ReportTables(),
  });

  factory ReportsData.fromJson(Map<String, dynamic> json) {
    List<T> parse<T>(
        dynamic raw, T Function(Map<String, dynamic>) mapper) {
      return (raw as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => mapper(Map<String, dynamic>.from(e)))
          .toList();
    }
    return ReportsData(
      range: json['range'] ?? 'all',
      agents: parse(json['agents'], ReportNameId.fromJson),
      properties: parse(json['properties'], ReportNameId.fromJson),
      revenueByMonth: parse(json['revenueByMonth'], MonthPoint.fromJson),
      leadSourceData: parse(json['leadSourceData'], NamedValue.fromJson),
      pipelineFunnel: parse(json['pipelineFunnel'], FunnelStage.fromJson),
      agentPerformance:
          parse(json['agentPerformance'], AgentPerformance.fromJson),
      monthlyBookings: parse(json['monthlyBookings'], MonthBookings.fromJson),
      paymentData: parse(json['paymentData'], MonthPayment.fromJson),
      propertyPerformance:
          parse(json['propertyPerformance'], PropertyPerformance.fromJson),
      siteVisitReport:
          VisitStat.fromJson(json['siteVisitReport'] as Map<String, dynamic>? ?? {}),
      lostLeadReport:
          LostLeadStat.fromJson(json['lostLeadReport'] as Map<String, dynamic>? ?? {}),
      campaignPerformance:
          parse(json['campaignPerformance'], CampaignPerf.fromJson),
      siteVisits: parse(json['siteVisits'], VisitRow.fromJson),
      reportTables:
          ReportTables.fromJson(json['reportTables'] as Map<String, dynamic>? ?? {}),
    );
  }
}