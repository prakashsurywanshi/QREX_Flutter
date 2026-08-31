import '../utils/num_parsers.dart';

class UserRecord {
  final int id;
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String roleName;
  final int? roleId;
  final String branch;
  final String status;
  final String? lastLogin;

  const UserRecord({
    required this.id,
    this.userId = '',
    this.name = '',
    this.email = '',
    this.phone,
    this.role = '',
    this.roleName = '',
    this.roleId,
    this.branch = '',
    this.status = 'Active',
    this.lastLogin,
  });

  factory UserRecord.fromJson(Map<String, dynamic> json) {
    return UserRecord(
      id: json['id'],
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
      roleName: json['roleName'] ?? json['role'] ?? '',
      roleId: json['roleId'],
      branch: json['branch'] ?? '',
      status: json['status'] ?? 'Active',
      lastLogin: json['last_login'],
    );
  }
}

class RoleSummary {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final bool isSystem;
  final int permissionsCount;

  const RoleSummary({
    required this.id,
    this.name = '',
    this.slug = '',
    this.description,
    this.isSystem = false,
    this.permissionsCount = 0,
  });

  factory RoleSummary.fromJson(Map<String, dynamic> json) {
    return RoleSummary(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      isSystem: (json['is_system'] == true || json['is_system'] == 1),
      permissionsCount: parseInt(json['permissions_count']),
    );
  }
}

class UsersIndex {
  final List<UserRecord> users;
  final List<RoleSummary> roles;
  final Map<String, Map<String, List<String>>> rolePermissions;

  const UsersIndex({
    this.users = const [],
    this.roles = const [],
    this.rolePermissions = const {},
  });

  factory UsersIndex.fromJson(Map<String, dynamic> json) {
    return UsersIndex(
      users: (json['users'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => UserRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      roles: (json['roles'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => RoleSummary.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      rolePermissions:
          (json['rolePermissions'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(
          k,
          (v as Map<String, dynamic>? ?? {}).map(
            (mk, mv) => MapEntry(
              mk,
              (mv as List<dynamic>? ?? [])
                  .map((e) => e.toString())
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}