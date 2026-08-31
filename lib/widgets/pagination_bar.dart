import 'package:flutter/material.dart';

/// Compact Previous/Next pagination bar (mirrors web pagination).
class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final int total;
  final ValueChanged<int> onPage;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPrev = currentPage > 1;
    final hasNext = currentPage < lastPage;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$total item(s)',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Row(
            children: [
              IconButton(
                onPressed: hasPrev ? () => onPage(currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
              ),
              Text(
                '${currentPage > 0 ? currentPage : 1} / ${lastPage > 0 ? lastPage : 1}',
                style: theme.textTheme.bodySmall,
              ),
              IconButton(
                onPressed: hasNext ? () => onPage(currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next',
              ),
            ],
          ),
        ],
      ),
    );
  }
}