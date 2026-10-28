import '../utils/num_parsers.dart';

class Customer {
  final int id;
  final String customerId;
  final String name;
  final String phone;
  final String? email;
  final String? type;
  final String status;
  final String? city;
  final String? requirements;
  final int? propertyCount;
  final double? totalValue;
  final int? agentId;
  final String? agentName;
  final String? createdAt;

  const Customer({
    required this.id,
    this.customerId = '',
    required this.name,
    this.phone = '',
    this.email,
    this.type,
    this.status = 'Prospect',
    this.city,
    this.requirements,
    this.propertyCount,
    this.totalValue,
    this.agentId,
    this.agentName,
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    final tv = json['total_value'];
    final props = json['properties'];
    return Customer(
      id: json['id'],
      customerId: json['customer_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      type: json['type'],
      status: json['status'] ?? 'Prospect',
      city: json['city'],
      requirements: json['requirements'],
      propertyCount: props is List ? props.length : null,
      totalValue: tv == null ? null : parseDouble(tv),
      agentId: json['agent_id'],
      agentName: json['agent_name'],
      createdAt: json['created_at'],
    );
  }
}