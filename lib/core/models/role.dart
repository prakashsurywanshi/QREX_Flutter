import '../utils/num_parsers.dart';

class RoleRecord {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final bool isSystem;
  final int permissionCount;
  final int userCount;
  final List<String> permissionSlugs;

  const RoleRecord({
    required this.id,
    this.name = '',
    this.slug = '',
    this.description,
    this.isSystem = false,
    this.permissionCount = 0,
    this.userCount = 0,
    this.permissionSlugs = const [],
  });

  factory RoleRecord.fromJson(Map<String, dynamic> json) {
    return RoleRecord(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      isSystem: (json['is_system'] == true || json['is_system'] == 1),
      permissionCount: parseInt(json['permission_count']),
      userCount: parseInt(json['user_count']),
      permissionSlugs: (json['permission_slugs'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class PermissionAction {
  final String slug;
  final String action;
  final String label;

  const PermissionAction({
    required this.slug,
    this.action = '',
    this.label = '',
  });

  factory PermissionAction.fromJson(Map<String, dynamic> json) {
    return PermissionAction(
      slug: json['slug'] ?? '',
      action: json['action'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

class FieldPermission {
  final String slug;
  final String field;
  final String label;

  const FieldPermission({
    required this.slug,
    this.field = '',
    this.label = '',
  });

  factory FieldPermission.fromJson(Map<String, dynamic> json) {
    return FieldPermission(
      slug: json['slug'] ?? '',
      field: json['field'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

class FieldAction {
  final String action;
  final List<FieldPermission> fields;

  const FieldAction({this.action = '', this.fields = const []});

  factory FieldAction.fromJson(Map<String, dynamic> json) {
    return FieldAction(
      action: json['action'] ?? '',
      fields: (json['fields'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => FieldPermission.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class PermissionNode {
  final String module;
  final String label;
  final List<PermissionAction> actions;
  final List<FieldAction> fields;

  const PermissionNode({
    this.module = '',
    this.label = '',
    this.actions = const [],
    this.fields = const [],
  });

  factory PermissionNode.fromJson(Map<String, dynamic> json) {
    return PermissionNode(
      module: json['module'] ?? '',
      label: json['label'] ?? '',
      actions: (json['actions'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => PermissionAction.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      fields: (json['fields'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => FieldAction.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class RolesIndex {
  final List<RoleRecord> roles;
  final List<PermissionNode> permissionTree;

  const RolesIndex({
    this.roles = const [],
    this.permissionTree = const [],
  });

  factory RolesIndex.fromJson(Map<String, dynamic> json) {
    return RolesIndex(
      roles: (json['roles'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => RoleRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      permissionTree: (json['permissions'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => PermissionNode.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}