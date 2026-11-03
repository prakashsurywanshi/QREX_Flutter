class Commission {
  Commission({
    required this.id,
    this.agentId,
    this.agentName,
    this.dealId,
    this.bookingId,
    this.propertyId,
    this.commissionType,
    this.commissionRate,
    this.commissionAmount,
    this.baseAmount,
    this.splitType,
    this.status,
    this.paymentReference,
    this.notes,
    this.createdAt,
    this.approvedAt,
    this.paidAt,
    this.splits = const [],
  });

  final int id;
  final int? agentId;
  final String? agentName;
  final int? dealId;
  final int? bookingId;
  final int? propertyId;
  final String? commissionType;
  final double? commissionRate;
  final double? commissionAmount;
  final double? baseAmount;
  final String? splitType;
  final String? status;
  final String? paymentReference;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? paidAt;
  final List<CommissionSplit> splits;

  factory Commission.fromJson(Map<String, dynamic> json) {
    return Commission(
      id: json['id'] as int,
      agentId: json['agent_id'] as int?,
      agentName: json['agent'] is Map ? (json['agent']['name'] as String?) : null,
      dealId: json['deal_id'] as int?,
      bookingId: json['booking_id'] as int?,
      propertyId: json['property_id'] as int?,
      commissionType: json['commission_type'] as String?,
      commissionRate: (json['commission_rate'] as num?)?.toDouble(),
      commissionAmount: (json['commission_amount'] as num?)?.toDouble(),
      baseAmount: (json['base_amount'] as num?)?.toDouble(),
      splitType: json['split_type'] as String?,
      status: json['status'] as String?,
      paymentReference: json['payment_reference'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      approvedAt: json['approved_at'] != null ? DateTime.tryParse(json['approved_at'].toString()) : null,
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'].toString()) : null,
      splits: (json['splits'] as List<dynamic>? ?? [])
          .map((e) => CommissionSplit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CommissionSplit {
  CommissionSplit({
    required this.id,
    this.userId,
    this.userName,
    this.sharePercentage,
    this.shareAmount,
    this.role,
  });

  final int id;
  final int? userId;
  final String? userName;
  final double? sharePercentage;
  final double? shareAmount;
  final String? role;

  factory CommissionSplit.fromJson(Map<String, dynamic> json) {
    return CommissionSplit(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      userName: json['user'] is Map ? (json['user']['name'] as String?) : null,
      sharePercentage: (json['share_percentage'] as num?)?.toDouble(),
      shareAmount: (json['share_amount'] as num?)?.toDouble(),
      role: json['role'] as String?,
    );
  }
}
