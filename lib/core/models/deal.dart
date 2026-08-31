import '../utils/num_parsers.dart';

class Deal {
  final int id;
  final String dealId;
  final String customerName;
  final String? propertyName;
  final double dealValue;
  final String? valueLabel;
  final String stage;
  final int probability;
  final int daysInStage;
  final String? agentName;
  final int? agentId;
  final int? propertyId;
  final int? leadId;
  final String? lastActivity;
  final String? nextFollowup;
  final String? createdAt;

  const Deal({
    required this.id,
    this.dealId = '',
    this.customerName = '',
    this.propertyName,
    this.dealValue = 0,
    this.valueLabel,
    this.stage = 'New Lead',
    this.probability = 10,
    this.daysInStage = 0,
    this.agentName,
    this.agentId,
    this.propertyId,
    this.leadId,
    this.lastActivity,
    this.nextFollowup,
    this.createdAt,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'],
      dealId: json['deal_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      propertyName: json['property_name'],
      dealValue: parseDouble(json['deal_value']),
      valueLabel: json['value_label'],
      stage: json['stage'] ?? 'New Lead',
      probability: json['probability'] ?? 10,
      daysInStage: json['days_in_stage'] ?? 0,
      agentName: json['agent_name'] == '—' ? null : json['agent_name'],
      agentId: json['agent_id'],
      propertyId: json['property_id'],
      leadId: json['lead_id'],
      lastActivity: json['last_activity'],
      nextFollowup: json['next_followup'],
      createdAt: json['created_at'],
    );
  }

  bool get isClosed => stage == 'Closed Won' || stage == 'Closed Lost';
}

class PipelineSummary {
  final int total;
  final double pipelineValue;
  final int activeCount;
  final double expectedRevenue;
  final double wonValue;
  final int wonCount;
  final double lostValue;
  final double conversionRate;

  const PipelineSummary({
    this.total = 0,
    this.pipelineValue = 0,
    this.activeCount = 0,
    this.expectedRevenue = 0,
    this.wonValue = 0,
    this.wonCount = 0,
    this.lostValue = 0,
    this.conversionRate = 0,
  });

  factory PipelineSummary.fromJson(Map<String, dynamic> json) {
    return PipelineSummary(
      total: json['total'] ?? 0,
      pipelineValue: parseDouble(json['pipelineValue']),
      activeCount: json['activeCount'] ?? 0,
      expectedRevenue: parseDouble(json['expectedRevenue']),
      wonValue: parseDouble(json['wonValue']),
      wonCount: json['wonCount'] ?? 0,
      lostValue: parseDouble(json['lostValue']),
      conversionRate: parseDouble(json['conversionRate']),
    );
  }
}