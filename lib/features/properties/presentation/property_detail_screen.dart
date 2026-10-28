// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/property.dart';
import '../../../core/models/property_type.dart';
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
  PropertyTypeOptions? _typeOptions;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _property = widget.initial;
    // The list payload carries no type catalog; fall back to the loaded one.
    _typeOptions = ref
        .read(propertiesControllerProvider.notifier)
        .optionsFor(widget.initial.type);
  }

  void _refreshList() =>
      ref.read(propertiesControllerProvider.notifier).refresh();

  Future<void> _reload() async {
    try {
      final fresh = await ref
          .read(propertiesRepositoryProvider)
          .show(widget.initial.id);
      if (mounted) {
        setState(() {
          _property = fresh.property;
          _typeOptions = fresh.typeOptions;
          _imageIndex = 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _share() async {
    final p = _property!;
    if (p.publicId.isEmpty) {
      showToast(context, 'Property link unavailable. Please update the app.',
          isError: true);
      return;
    }
    final url = '${AppConfig.propertyBaseUrl}/${p.publicId}';
    try {
      final result = await Share.share(
        '${p.shareSummary}\n$url',
        subject: p.title,
      );
      if (result.status == ShareResultStatus.dismissed && mounted) {
        showToast(context, 'Share cancelled.');
      }
    } catch (e) {
      if (mounted) showToast(context, 'Unable to share.', isError: true);
    }
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
      content:
          '${_property!.title} (${_property!.propertyId}) will be removed.',
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

  Widget _networkImage(String url, ThemeData theme) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _property!;
    final theme = Theme.of(context);
    final spec =
        _typeOptions?.spec ??
        ref
            .read(propertiesControllerProvider.notifier)
            .optionsFor(p.type)
            ?.spec ??
        const SpecRuleSet();

    final rows = <(String, String)>[
      ('Type', p.type),
      ('Transaction', p.transactionType),
      ('Price', p.priceLabel ?? Formatters.inrLabel(p.price)),
      if (p.area > 0) (spec.areaName, '${p.area} ${spec.areaUnit}'),
      if (spec.shows('bedrooms') && p.bedrooms > 0)
        ('Bedrooms', '${p.bedrooms}'),
      if (spec.shows('bathrooms') && p.bathrooms > 0)
        ('Bathrooms', '${p.bathrooms}'),
      if (spec.shows('floors') && p.floors > 0) ('Floors', '${p.floors}'),
      if (spec.shows('parking') && p.parking > 0) ('Parking', '${p.parking}'),
      if (spec.shows('furnishing') && p.furnishing != null)
        ('Furnishing', p.furnishing!),
      if (spec.shows('possession_date') && p.possessionDate != null)
        ('Possession', Formatters.date(p.possessionDate)),
      if (p.city != null) ('City', p.city!),
      if (p.state != null) ('State', p.state!),
      if (p.address != null) ('Address', p.address!),
      if (p.agentName != null) ('Agent', p.agentName!),
      ('Website visible', p.isWebsiteVisible ? 'Yes' : 'No'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
        actions: [
          IconButton(
            onPressed: _share,
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share property',
          ),
        ],
      ),
      bottomNavigationBar: (widget.canEdit || widget.canDelete)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _share,
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share'),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                            foregroundColor: theme.colorScheme.error,
                          ),
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
                    Text(
                      p.propertyId,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      p.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                  .map(
                    (a) => Chip(
                      label: Text(a),
                      labelStyle: theme.textTheme.labelSmall,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
          if (p.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: p.imageUrls.length == 1
                        ? _networkImage(p.imageUrls.first, theme)
                        : PageView.builder(
                            itemCount: p.imageUrls.length,
                            onPageChanged: (i) =>
                                setState(() => _imageIndex = i),
                            itemBuilder: (_, i) =>
                                _networkImage(p.imageUrls[i], theme),
                          ),
                  ),
                ),
                if (p.imageUrls.length > 1) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < p.imageUrls.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _imageIndex ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _imageIndex
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
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
                          child: Text(
                            v,
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
