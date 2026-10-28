class PropertyImage {
  final int id;
  final String path;
  final String type;
  final bool isCover;
  final int sortOrder;

  const PropertyImage({
    required this.id,
    this.path = '',
    this.type = 'image',
    this.isCover = false,
    this.sortOrder = 0,
  });

  factory PropertyImage.fromJson(Map<String, dynamic> json) {
    return PropertyImage(
      id: json['id'],
      path: json['path'] ?? '',
      type: json['type'] ?? 'image',
      isCover: json['is_cover'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}