import 'permission_map.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final List<String> roleSlugs;
  final String? branch;
  final String? avatar;
  final String? initials;
  final String status;
  final String? lastLoginAt;
  final int unreadNotifications;
  final PermissionMap can;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.roleSlugs,
    this.branch,
    this.avatar,
    this.initials,
    required this.status,
    this.lastLoginAt,
    required this.unreadNotifications,
    required this.can,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
      roleSlugs: (json['role_slugs'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      branch: json['branch'],
      avatar: json['avatar'],
      initials: json['initials'],
      status: json['status'] ?? 'Active',
      lastLoginAt: json['last_login_at'],
      unreadNotifications: json['unread_notifications'] ?? 0,
      can: PermissionMap.fromJson(json['can'] as Map<String, dynamic>? ?? {}),
    );
  }

  bool hasRole(String slug) => roleSlugs.contains(slug);

  bool hasAnyRole(List<String> slugs) => roleSlugs.any(slugs.contains);

  bool get isSuperAdmin => hasRole('super-admin');

  bool get isAdmin => hasRole('admin');

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'role_slugs': roleSlugs,
        'branch': branch,
        'avatar': avatar,
        'initials': initials,
        'status': status,
        'last_login_at': lastLoginAt,
        'unread_notifications': unreadNotifications,
        'can': can.toJson(),
      };
}
