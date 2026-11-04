class PaymentPlan {
  PaymentPlan({required this.id, this.planName, this.totalAmount, this.planType, this.status, this.installments = const []});
  final int id;
  final String? planName;
  final double? totalAmount;
  final String? planType;
  final String? status;
  final List<Installment> installments;

  factory PaymentPlan.fromJson(Map<String, dynamic> json) {
    return PaymentPlan(
      id: json['id'],
      planName: json['plan_name'],
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      planType: json['plan_type'],
      status: json['status'],
      installments: (json['installments'] as List<dynamic>? ?? []).map((e) => Installment.fromJson(e)).toList(),
    );
  }
}

class Installment {
  Installment({required this.id, this.milestoneName, this.dueDate, this.amount, this.paidAmount, this.balanceAmount, this.status});
  final int id;
  final String? milestoneName;
  final String? dueDate;
  final double? amount;
  final double? paidAmount;
  final double? balanceAmount;
  final String? status;

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id'],
      milestoneName: json['milestone_name'],
      dueDate: json['due_date'],
      amount: (json['amount'] as num?)?.toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble(),
      balanceAmount: (json['balance_amount'] as num?)?.toDouble(),
      status: json['status'],
    );
  }
}
