import '../utils/num_parsers.dart';
import 'payment.dart';

class Booking {
  final int id;
  final String bookingId;
  final String customerName;
  final String propertyName;
  final String agentName;
  final String? bookingDate;
  final double dealValue;
  final String? dealLabel;
  final double bookingAmount;
  final String? bookingAmountLabel;
  final String status;
  final String agreementStatus;
  final String possessionStatus;
  final String? createdAt;

  const Booking({
    required this.id,
    this.bookingId = '',
    this.customerName = '',
    this.propertyName = '',
    this.agentName = '',
    this.bookingDate,
    this.dealValue = 0,
    this.dealLabel,
    this.bookingAmount = 0,
    this.bookingAmountLabel,
    this.status = 'Booking Pending',
    this.agreementStatus = 'Pending',
    this.possessionStatus = 'Pending',
    this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      bookingId: json['booking_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      propertyName: json['property_name'] ?? '',
      agentName: json['agent_name'] ?? '',
      bookingDate: json['booking_date'],
      dealValue: parseDouble(json['deal_value']),
      dealLabel: json['deal_label'],
      bookingAmount: parseDouble(json['booking_amount']),
      bookingAmountLabel: json['booking_amount_label'],
      status: json['status'] ?? 'Booking Pending',
      agreementStatus: json['agreement_status'] ?? 'Pending',
      possessionStatus: json['possession_status'] ?? 'Pending',
      createdAt: json['created_at'],
    );
  }
}

class BookingDetail {
  final Booking booking;
  final List<Payment> payments;

  const BookingDetail({required this.booking, this.payments = const []});

  factory BookingDetail.fromJson(Map<String, dynamic> json) {
    return BookingDetail(
      booking: Booking.fromJson(
          json['booking'] as Map<String, dynamic>? ?? {}),
      payments: (json['payments'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Payment.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class BookingSummary {
  final int total;
  final int agreementsSigned;
  final int possessionHandedOver;

  const BookingSummary({
    this.total = 0,
    this.agreementsSigned = 0,
    this.possessionHandedOver = 0,
  });

  factory BookingSummary.fromList(List<Booking> bookings) {
    return BookingSummary(
      total: bookings.length,
      agreementsSigned:
          bookings.where((b) => b.agreementStatus == 'Signed').length,
      possessionHandedOver:
          bookings.where((b) => b.possessionStatus == 'Handed Over').length,
    );
  }
}