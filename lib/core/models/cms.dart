import 'property.dart';

class CmsSection {
  final String id;
  final String label;
  final bool visible;
  final String icon;

  const CmsSection({
    required this.id,
    this.label = '',
    this.visible = true,
    this.icon = '',
  });

  factory CmsSection.fromJson(Map<String, dynamic> json) {
    return CmsSection(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      visible: json['visible'] == true || json['visible'] == 1,
      icon: json['icon'] ?? '',
    );
  }

  CmsSection copyWith({bool? visible}) {
    return CmsSection(
      id: id,
      label: label,
      visible: visible ?? this.visible,
      icon: icon,
    );
  }
}

class CmsAgent {
  final int id;
  final String name;
  final String role;
  final String branch;

  const CmsAgent({
    required this.id,
    this.name = '',
    this.role = '',
    this.branch = '',
  });

  factory CmsAgent.fromJson(Map<String, dynamic> json) {
    return CmsAgent(
      id: json['id'],
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      branch: json['branch'] ?? '',
    );
  }
}

class CmsProperty {
  final int id;
  final String title;
  final String? image;
  final String? priceLabel;
  final String status;

  const CmsProperty({
    required this.id,
    this.title = '',
    this.image,
    this.priceLabel,
    this.status = '',
  });

  factory CmsProperty.fromJson(Map<String, dynamic> json) {
    return CmsProperty(
      id: json['id'],
      title: json['title'] ?? '',
      image: json['image'],
      priceLabel: json['price_label'],
      status: json['status'] ?? '',
    );
  }
}

class CmsIndex {
  final List<Property> featuredProperties;
  final List<CmsProperty> allProperties;
  final List<CmsAgent> agents;
  final List<CmsSection> sections;
  final List<int> featuredIds;

  const CmsIndex({
    this.featuredProperties = const [],
    this.allProperties = const [],
    this.agents = const [],
    this.sections = const [],
    this.featuredIds = const [],
  });

  factory CmsIndex.fromJson(Map<String, dynamic> json) {
    return CmsIndex(
      featuredProperties: (json['featuredProperties'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Property.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      allProperties: (json['allProperties'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => CmsProperty.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      agents: (json['agents'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => CmsAgent.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      sections: (json['sections'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => CmsSection.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      featuredIds: (json['featuredIds'] as List<dynamic>? ?? [])
          .whereType<num>()
          .map((e) => e.toInt())
          .toList(),
    );
  }
}