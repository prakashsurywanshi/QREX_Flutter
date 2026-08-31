import '../utils/num_parsers.dart';

class Property {
  final int id;
  final String propertyId;
  final String title;
  final String type;
  final String transactionType;
  final String status;
  final double price;
  final String? priceLabel;
  final double area;
  final int bedrooms;
  final int bathrooms;
  final int floors;
  final int parking;
  final String? furnishing;
  final String? possessionDate;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final List<String> amenities;
  final bool featured;
  final bool isWebsiteVisible;
  final String? description;
  final String? image;
  final int? agentId;
  final String? agentName;

  const Property({
    required this.id,
    this.propertyId = '',
    required this.title,
    this.type = '',
    this.transactionType = '',
    this.status = '',
    this.price = 0,
    this.priceLabel,
    this.area = 0,
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.floors = 1,
    this.parking = 0,
    this.furnishing,
    this.possessionDate,
    this.address,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.amenities = const [],
    this.featured = false,
    this.isWebsiteVisible = false,
    this.description,
    this.image,
    this.agentId,
    this.agentName,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      propertyId: json['property_id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      status: json['status'] ?? '',
      price: parseDouble(json['price']),
      priceLabel: json['price_label'],
      area: parseDouble(json['area']),
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      floors: json['floors'] ?? 1,
      parking: json['parking'] ?? 0,
      furnishing: json['furnishing'],
      possessionDate: json['possession_date'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
      amenities: (json['amenities'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      featured: json['featured'] ?? false,
      isWebsiteVisible: json['is_website_visible'] ?? false,
      description: json['description'],
      image: json['image'],
      agentId: json['agent_id'],
      agentName: json['agent_name'],
    );
  }

  String get subtitleBits {
    final parts = <String>[
      if (type.isNotEmpty) type,
      if (bedrooms > 0) '$bedrooms BHK',
      if (area > 0) '$area sq.ft',
    ];
    return parts.join(' · ');
  }
}