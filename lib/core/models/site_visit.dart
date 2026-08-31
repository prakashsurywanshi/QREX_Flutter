class SiteVisitItem {
  final int id;
  final String visitId;
  final int? leadId;
  final String customerName;
  final String propertyName;
  final String agentName;
  final String visitDate;
  final String visitTime;
  final String status;
  final String? location;
  final String? notes;
  final String? feedback;
  final String? createdAt;

  const SiteVisitItem({
    required this.id,
    this.visitId = '',
    this.leadId,
    this.customerName = '',
    this.propertyName = '',
    this.agentName = '',
    this.visitDate = '',
    this.visitTime = '',
    this.status = 'Scheduled',
    this.location,
    this.notes,
    this.feedback,
    this.createdAt,
  });

  factory SiteVisitItem.fromJson(Map<String, dynamic> json) {
    return SiteVisitItem(
      id: json['id'],
      visitId: json['visit_id'] ?? '',
      leadId: json['lead_id'],
      customerName: json['customer_name'] ?? '',
      propertyName: json['property_name'] ?? '',
      agentName: json['agent_name'] ?? '',
      visitDate: json['visit_date'] ?? '',
      visitTime: json['visit_time'] ?? '',
      status: json['status'] ?? 'Scheduled',
      location: json['location'],
      notes: json['notes'],
      feedback: json['feedback'],
      createdAt: json['created_at'],
    );
  }
}