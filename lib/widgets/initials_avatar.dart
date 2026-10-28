import 'package:flutter/material.dart';

/// The CRM's 2-letter initials avatar (navy circle, white text).
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final String? initials;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.radius = 18,
    this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarText = initials != null && initials!.isNotEmpty
        ? initials!
        : _initials(name);

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      child: Text(
        avatarText,
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    return parts.map((p) => p[0].toUpperCase()).join();
  }
}