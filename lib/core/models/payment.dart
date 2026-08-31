import '../utils/num_parsers.dart';

class Payment {
  final int id;
  final String paymentId;
  final String customerName;
  final String propertyName;
  final double amount;
  final String? amountLabel;
  final String mode;
  final String txnId;
  final String status;
  final String? paidDate;
  final String? dueDate;
  final String? createdAt;

  const Payment({
    required this.id,
    this.paymentId = '',
    this.customerName = '',
    this.propertyName = '',
    this.amount = 0,
    this.amountLabel,
    this.mode = '',
    this.txnId = '',
    this.status = 'Pending',
    this.paidDate,
    this.dueDate,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      paymentId: json['payment_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      propertyName: json['property_name'] ?? '',
      amount: parseDouble(json['amount']),
      amountLabel: json['amount_label'],
      mode: json['mode'] ?? '',
      txnId: json['txn_id'] ?? '',
      status: json['status'] ?? 'Pending',
      paidDate: json['paid_date'],
      dueDate: json['due_date'],
      createdAt: json['created_at'],
    );
  }
}

class PaymentSummary {
  final double total;
  final double received;
  final double receivable;
  final double pending;
  final double overdue;
  final double cancelled;

  const PaymentSummary({
    this.total = 0,
    this.received = 0,
    this.receivable = 0,
    this.pending = 0,
    this.overdue = 0,
    this.cancelled = 0,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    double n(String k) => parseDouble(json[k]);
    return PaymentSummary(
      total: n('total'),
      received: n('received'),
      receivable: n('receivable'),
      pending: n('pending'),
      overdue: n('overdue'),
      cancelled: n('cancelled'),
    );
  }
}