import 'package:flutter/material.dart';

/// Colour-coded status pill mirroring the web CRM's status colour map.
class StatusPill extends StatelessWidget {
  final String label;
  final Color? overriddenColor;

  const StatusPill({super.key, required this.label, this.overriddenColor});

  static const Map<String, Color> _colors = {
    'Available': Color(0xFF1B5E20),
    'Ready to Move': Color(0xFF1B5E20),
    'Active': Color(0xFF1B5E20),
    'Paid': Color(0xFF1B5E20),
    'Completed': Color(0xFF1B5E20),
    'Closed Won': Color(0xFF1B5E20),
    'Converted': Color(0xFF1B5E20),
    'Qualified': Color(0xFF1B5E20),
    'Confirmed': Color(0xFF1B5E20),
    'Contacted': Color(0xFF1565C0),
    'New': Color(0xFF1565C0),
    'In Progress': Color(0xFF1565C0),
    'Scheduled': Color(0xFF1565C0),
    'Booking Pending': Color(0xFFB45309),
    'Under Negotiation': Color(0xFFB45309),
    'Negotiation': Color(0xFFB45309),
    'Reserved': Color(0xFFB45309),
    'Pending': Color(0xFFB45309),
    'Partially Paid': Color(0xFFB45309),
    'Partial': Color(0xFFB45309),
    'Pending Agreement': Color(0xFFB45309),
    'Receivable': Color(0xFFB45309),
    'Overdue': Color(0xFFC62828),
    'Lost': Color(0xFFC62828),
    'Closed Lost': Color(0xFFC62828),
    'Cancelled': Color(0xFFC62828),
    'Inactive': Color(0xFF757575),
    'Draft': Color(0xFF757575),
    'Rented': Color(0xFF6A1B9A),
    'Sold': Color(0xFF2E7D32),
    'Rescheduled': Color(0xFFEF6C00),
    'Urgent': Color(0xFFC62828),
    'High': Color(0xFFEF6C00),
    'Medium': Color(0xFFB45309),
    'Low': Color(0xFF2E7D32),
    'Site Visit Scheduled': Color(0xFF1565C0),
    'Site Visit Completed': Color(0xFF1B5E20),
    'Agreement': Color(0xFF6A1B9A),
    'Booking': Color(0xFFB45309),
    'Payment': Color(0xFF2E7D32),
    'Property Shortlisted': Color(0xFF6A1B9A),
    'New Lead': Color(0xFF1565C0),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final key = label.trim();
    final color = overriddenColor ??
        _colors[key] ??
        theme.colorScheme.secondary;

    final bg = color.withValues(alpha: 0.12);
    final fg = Color.alphaBlend(color, theme.colorScheme.surface).withValues(alpha: 0.95);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}