import 'package:flutter/material.dart';

/// A modal bottom sheet listing filter options as selectable chips plus an
/// optional search field. Returns the selected option when "Apply" is tapped.
///
/// [options] is a list of (value, label). Selecting an option radio-style.
Future<String?> showFilterSheet(
  BuildContext context, {
  required String title,
  required List<(String, String)> options,
  String? current,
  bool Function(String)? enabled,
}) async {
  String? selected = current;
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((o) {
                    final isSel = o.$1 == selected;
                    final isEnabled = enabled?.call(o.$1) ?? true;
                    return ChoiceChip(
                      label: Text(o.$2),
                      selected: isSel,
                      onSelected: isEnabled
                          ? (_) => setSheetState(() => selected = o.$1)
                          : null,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(selected),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}