/// Spec rules for one property type, mirroring the backend `spec_rules`.
///
/// When the catalog has not been loaded (or a type is unknown) [visible] is
/// empty and [shows] returns true for every field, so the form degrades to the
/// "show everything" behaviour instead of hiding inputs.
class SpecRuleSet {
  final List<String> visible;
  final List<String> required;
  final List<String> hidden;
  final Map<String, Object?> defaults;
  final String areaLabel;

  const SpecRuleSet({
    this.visible = const [],
    this.required = const [],
    this.hidden = const [],
    this.defaults = const {},
    this.areaLabel = 'Area (sq.ft)',
  });

  factory SpecRuleSet.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SpecRuleSet();

    List<String> strings(String key) => _stringList(json[key]);

    return SpecRuleSet(
      visible: strings('visible'),
      required: strings('required'),
      hidden: strings('hidden'),
      defaults: (json['defaults'] as Map<dynamic, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k.toString(), v)),
      areaLabel: json['area_label']?.toString().isNotEmpty == true
          ? json['area_label'].toString()
          : 'Area (sq.ft)',
    );
  }

  bool shows(String field) => visible.isEmpty || visible.contains(field);

  bool hides(String field) => hidden.contains(field);

  bool isRequired(String field) => required.contains(field);

  /// The unit in the trailing parentheses of [areaLabel], e.g. "acres" for
  /// "Land Area (acres)".
  String get areaUnit {
    final m = RegExp(r'\((.*)\)').firstMatch(areaLabel);
    return m?.group(1) ?? 'sq.ft';
  }

  /// [areaLabel] without its parenthetical unit, e.g. "Land Area".
  String get areaName => areaLabel.replaceAll(RegExp(r'\s*\(.*\)'), '');
}

/// One entry of the property-type catalog returned by the properties index.
class PropertyTypeMeta {
  final String name;
  final String slug;
  final String? description;
  final List<String> amenities;
  final SpecRuleSet spec;

  const PropertyTypeMeta({
    required this.name,
    required this.slug,
    this.description,
    this.amenities = const [],
    this.spec = const SpecRuleSet(),
  });

  factory PropertyTypeMeta.fromJson(Map<String, dynamic> json) {
    return PropertyTypeMeta(
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      amenities: _stringList(json['amenities']),
      spec: SpecRuleSet.fromJson(_map(json['spec'])),
    );
  }
}

/// The `type_options` payload for a single property, returned by the show
/// endpoint: the amenity catalog and spec rules for that property's type.
class PropertyTypeOptions {
  final List<String> amenities;
  final SpecRuleSet spec;

  const PropertyTypeOptions({
    this.amenities = const [],
    this.spec = const SpecRuleSet(),
  });

  factory PropertyTypeOptions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PropertyTypeOptions();

    return PropertyTypeOptions(
      amenities: _stringList(json['amenities']),
      spec: SpecRuleSet.fromJson(_map(json['spec'])),
    );
  }
}

/// Tolerates a value that is not a list / map instead of throwing.
List<String> _stringList(Object? v) {
  if (v is! List) return const [];
  return v.map((e) => e.toString()).toList();
}

Map<String, dynamic>? _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;
