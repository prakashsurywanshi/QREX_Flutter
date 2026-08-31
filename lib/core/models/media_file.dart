import '../utils/num_parsers.dart';

class MediaFile {
  final int id;
  final String name;
  final String folder;
  final String? propertyName;
  final String? size;
  final String type;
  final String? url;
  final String? uploadedBy;
  final String? createdAt;

  const MediaFile({
    required this.id,
    this.name = '',
    this.folder = 'General',
    this.propertyName,
    this.size,
    this.type = 'document',
    this.url,
    this.uploadedBy,
    this.createdAt,
  });

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id'],
      name: json['name'] ?? '',
      folder: json['folder'] ?? 'General',
      propertyName: json['property_name'],
      size: json['size'],
      type: json['type'] ?? 'document',
      url: json['url'],
      uploadedBy: json['uploaded_by'],
      createdAt: json['created_at'],
    );
  }
}

class MediaIndex {
  final List<MediaFile> files;
  final List<String> folders;
  final double storageUsed;
  final int storageEntries;

  const MediaIndex({
    this.files = const [],
    this.folders = const [],
    this.storageUsed = 0,
    this.storageEntries = 0,
  });

  factory MediaIndex.fromJson(Map<String, dynamic> json) {
    final storage = json['storage'] as Map<String, dynamic>? ?? {};
    return MediaIndex(
      files: (json['mediaFiles'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => MediaFile.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      folders: (json['folders'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      storageUsed: parseDouble(storage['used']),
      storageEntries: storage['entries'] ?? 0,
    );
  }
}