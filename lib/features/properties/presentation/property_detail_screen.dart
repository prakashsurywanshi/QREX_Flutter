// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/property.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/feedback.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_pill.dart';
import 'properties_controller.dart';
import 'property_form_sheet.dart';

class PropertyDetailArgs {
  final Property property;
  final bool canEdit;
  final bool canDelete;
  const PropertyDetailArgs({
    required this.property,
    required this.canEdit,
    required this.canDelete,
  });
}

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final Property initial;
  final bool canEdit;
  final bool canDelete;

  const PropertyDetailScreen({
    super.key,
    required this.initial,
    required this.canEdit,
    required this.canDelete,
  });

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  Property? _property;

  @override
  void initState() {
    super.initState();
    _property = widget.initial;
  }

  void _refreshList() =>
      ref.read(propertiesControllerProvider.notifier).refresh();

  Future<void> _reload() async {
    try {
      final fresh = await ref
          .read(propertiesRepositoryProvider)
          .show(widget.initial.id);
      if (mounted) setState(() => _property = fresh);
    } catch (_) {}
  }

  Future<void> _edit() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => PropertyFormSheet(
        initial: _property,
        onSaved: () {
          _refreshList();
          _reload();
        },
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showConfirm(
      context,
      title: 'Delete property?',
      content: '${_property!.title} (${_property!.propertyId}) will be removed.',
      confirmLabel: 'Delete',
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (!ok) return;
    try {
      await ref
          .read(propertiesControllerProvider.notifier)
          .deleteProperty(_property!.id);
      _refreshList();
      if (mounted) {
        Navigator.of(context).pop();
        showToast(context, 'Property deleted.');
      }
    } catch (e) {
      if (mounted) showToast(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _property!;
    final theme = Theme.of(context);

    final rows = <(String, String)>[
      ('Type', p.type),
      ('Transaction', p.transactionType),
      ('Price', p.priceLabel ?? Formatters.inrLabel(p.price)),
      if (p.area > 0) ('Area', '${p.area} sq.ft'),
      if (p.bedrooms > 0) ('Bedrooms', '${p.bedrooms}'),
      if (p.bathrooms > 0) ('Bathrooms', '${p.bathrooms}'),
      if (p.furnishing != null) ('Furnishing', p.furnishing!),
      if (p.possessionDate != null) ('Possession', p.possessionDate!),
      if (p.city != null) ('City', p.city!),
      if (p.state != null) ('State', p.state!),
      if (p.address != null) ('Address', p.address!),
      if (p.agentName != null) ('Agent', p.agentName!),
      ('Website visible', p.isWebsiteVisible ? 'Yes' : 'No'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Property Details')),
      bottomNavigationBar: (widget.canEdit || widget.canDelete)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    if (widget.canEdit) ...[
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _edit,
                          child: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (widget.canDelete) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _delete,
                          style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error),
                          child: const Text('Delete'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.propertyId,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: theme.colorScheme.primary)),
                    Text(p.title,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              StatusPill(label: p.status),
            ],
          ),
          if (p.description != null && p.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(p.description!, style: theme.textTheme.bodySmall),
          ],
          if (p.amenities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: p.amenities
                  .map((a) => Chip(
                        label: Text(a),
                        labelStyle: theme.textTheme.labelSmall,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          SectionCard(
            title: 'Details',
            child: Column(
              children: [
                for (final (k, v) in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(k, style: theme.textTheme.bodySmall),
                        Flexible(
                          child: Text(v,
                              textAlign: TextAlign.right,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
