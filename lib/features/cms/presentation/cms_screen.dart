// ignore_for_file: use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/cms.dart';
import '../../../core/models/property.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/initials_avatar.dart';
import '../../../widgets/section_card.dart';
import 'cms_controller.dart';

class CmsScreen extends ConsumerStatefulWidget {
  const CmsScreen({super.key});

  @override
  ConsumerState<CmsScreen> createState() => _CmsScreenState();
}

class _CmsScreenState extends ConsumerState<CmsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(cmsControllerProvider.notifier);
      if (ref.read(cmsControllerProvider).sections.isEmpty) c.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(cmsControllerProvider);
    final controller = ref.read(cmsControllerProvider.notifier);
    final canEdit = ref.watch(currentUserProvider)?.can.canEdit('cms') == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CMS / Website'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: controller.load,
          ),
        ],
      ),
      body: state.loading && state.sections.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.sections.isEmpty
          ? EmptyState(
              icon: Icons.cloud_off,
              message: state.error!,
              action: FilledButton(
                onPressed: controller.load,
                child: const Text('Retry'),
              ),
            )
          : RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  SectionCard(
                    title: 'Homepage Sections',
                    child: Column(
                      children: [
                        for (final s in state.sections)
                          _SectionRow(
                            section: s,
                            enabled: canEdit,
                            onChanged: (v) => controller.toggleSection(s.id, v),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Agents Shown on Website',
                    child: state.agents.isEmpty
                        ? Text(
                            'No agents.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Column(
                            children: [
                              for (final a in state.agents)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      InitialsAvatar(name: a.name, radius: 16),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a.name,
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                            Text(
                                              a.role,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .outline,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        a.branch,
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Featured on Homepage',
                    trailing: canEdit
                        ? TextButton(
                            onPressed: () => _openFeaturedManager(context),
                            child: const Text('Manage'),
                          )
                        : null,
                    child: state.featuredProperties.isEmpty
                        ? const EmptyState(
                            icon: Icons.star_outline,
                            message: 'No featured properties',
                            hint:
                                'Choose properties to feature on the homepage.',
                          )
                        : Column(
                            children: [
                              for (final p in state.featuredProperties)
                                _FeaturedRow(property: p),
                            ],
                          ),
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
    );
  }

  Future<void> _openFeaturedManager(BuildContext context) async {
    final controller = ref.read(cmsControllerProvider.notifier);
    final state = ref.read(cmsControllerProvider);
    final current = state.featuredProperties.map((p) => p.id).toSet();
    final selected = <int>{...current};
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Widget tile(CmsProperty item) {
            final isSel = selected.contains(item.id);
            return InkWell(
              onTap: () => setSheetState(() {
                if (isSel) {
                  selected.remove(item.id);
                } else {
                  selected.add(item.id);
                }
              }),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSel
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12)
                      : Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSel ? Icons.star : Icons.star_border,
                      color: isSel
                          ? Colors.amber.shade700
                          : Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      item.priceLabel ?? '',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.4,
            expand: false,
            builder: (_, sc) => ListView(
              controller: sc,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Manage Featured Properties',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${selected.length} of ${state.allProperties.length} selected',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 12),
                for (final p in state.allProperties) tile(p),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    try {
                      await controller.setFeatured(selected.toList());
                      messenger
                        ..clearSnackBars()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Featured properties updated.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    } catch (e) {
                      messenger
                        ..clearSnackBars()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    }
                  },
                  child: const Text('Save Featured'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final CmsSection section;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SectionRow({
    required this.section,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        '${section.icon}  ${section.label}',
        style: theme.textTheme.bodyMedium,
      ),
      value: section.visible,
      activeTrackColor: theme.colorScheme.primary,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _FeaturedRow extends StatelessWidget {
  final Property property;
  const _FeaturedRow({required this.property});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 44,
              height: 36,
              color: theme.colorScheme.surfaceContainerHigh,
              child: property.coverImageUrl == null
                  ? Icon(
                      Icons.apartment,
                      size: 20,
                      color: theme.colorScheme.outline,
                    )
                  : CachedNetworkImage(
                      imageUrl: property.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Icon(
                        Icons.apartment,
                        size: 20,
                        color: theme.colorScheme.outline,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  property.status,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.star, color: Colors.amber.shade700, size: 18),
          const SizedBox(width: 6),
          Text(
            property.priceLabel ?? Formatters.inrLabel(property.price),
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
