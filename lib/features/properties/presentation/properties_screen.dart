import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/property.dart';
import '../../../core/notifiers/paged_state.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/feedback.dart';
import '../../../widgets/filter_sheet.dart';
import '../../../widgets/pagination_bar.dart';
import '../../../widgets/status_pill.dart';
import 'properties_controller.dart';
import 'property_detail_screen.dart';
import 'property_form_sheet.dart';

class PropertiesScreen extends ConsumerStatefulWidget {
  const PropertiesScreen({super.key});

  @override
  ConsumerState<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends ConsumerState<PropertiesScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(propertiesControllerProvider.notifier);
      if (ref.read(propertiesControllerProvider).items.isEmpty) c.load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(propertiesControllerProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(propertiesControllerProvider);
    final controller = ref.read(propertiesControllerProvider.notifier);
    final user = ref.watch(currentUserProvider);
    final can = user?.can;
    final canCreate = can?.canCreate('properties') == true;
    final lookups = controller.lookups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties'),
        actions: [
          if (state.total > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${state.total}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Property'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search title, city, ID…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          controller.search('');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: 'Status: ${state.filters['status'] ?? 'All'}',
                  onTap: () async {
                    final opts = [
                      for (final s in ['All', ...lookups.statuses]) (s, s),
                    ];
                    final v = await showFilterSheet(
                      context,
                      title: 'Filter by Status',
                      options: opts,
                      current: state.filters['status'] ?? 'All',
                    );
                    if (v != null) controller.setFilter('status', v);
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Type: ${state.filters['type'] ?? 'All'}',
                  onTap: () async {
                    final opts = [
                      for (final t in ['All', ...lookups.types]) (t, t),
                    ];
                    final v = await showFilterSheet(
                      context,
                      title: 'Filter by Type',
                      options: opts,
                      current: state.filters['type'] ?? 'All',
                    );
                    if (v != null) controller.setFilter('type', v);
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Featured: ${state.filters['featured'] ?? 'All'}',
                  onTap: () async {
                    const opts = [
                      ('All', 'All'),
                      ('Featured', 'Featured'),
                      ('Regular', 'Regular'),
                    ];
                    final v = await showFilterSheet(
                      context,
                      title: 'Featured only',
                      options: opts,
                      current: state.filters['featured'] ?? 'All',
                    );
                    if (v != null) controller.setFilter('featured', v);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildList(
              context,
              state,
              controller,
              can?.canEdit('properties') == true,
              can?.canDelete('properties') == true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    PagedState<Property> state,
    PropertiesController controller,
    bool canEdit,
    bool canDelete,
  ) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        message: state.error!,
        action: FilledButton(
          onPressed: controller.refresh,
          child: const Text('Retry'),
        ),
      );
    }
    if (state.items.isEmpty) {
      return const EmptyState(
        icon: Icons.apartment,
        message: 'No properties found',
        hint: 'Adjust filters or add your first property.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        controller.refresh();
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
        itemCount: state.items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          if (i == state.items.length) {
            if (state.loadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return PaginationBar(
              currentPage: state.currentPage,
              lastPage: state.lastPage,
              total: state.total,
              onPage: (p) {
                _loadPage(p);
              },
            );
          }
          final p = state.items[i];
          return _PropertyTile(
            property: p,
            onTap: () => _openDetail(context, p, canEdit, canDelete),
            onShare: () => _shareProperty(context, p),
          );
        },
      ),
    );
  }

  Future<void> _loadPage(int page) async {
    await ref.read(propertiesControllerProvider.notifier).loadPage(page);
  }

  Future<void> _openDetail(
    BuildContext context,
    Property p,
    bool canEdit,
    bool canDelete,
  ) async {
    await context.push(
      '/properties/${p.id}',
      extra: PropertyDetailArgs(
        property: p,
        canEdit: canEdit,
        canDelete: canDelete,
      ),
    );
  }

  Future<void> _shareProperty(BuildContext context, Property p) async {
    if (p.publicId.isEmpty) {
      showToast(context, 'Property link unavailable. Please update the app.',
          isError: true);
      return;
    }
    final url = '${AppConfig.propertyBaseUrl}/${p.publicId}';
    try {
      await Share.share('${p.shareSummary}\n$url', subject: p.title);
    } catch (_) {
      if (context.mounted) {
        showToast(context, 'Unable to share.', isError: true);
      }
    }
  }

  Future<void> _openForm(BuildContext context) async {
    final user = ref.read(currentUserProvider);
    final can = user?.can;
    final canCreate = can?.canCreate('properties') == true;
    if (!canCreate) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => PropertyFormSheet(
        onSaved: () =>
            ref.read(propertiesControllerProvider.notifier).refresh(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.filter_list, size: 16),
      onPressed: onTap,
      labelStyle: Theme.of(context).textTheme.labelMedium,
    );
  }
}

class _PropertyTile extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final VoidCallback onShare;
  const _PropertyTile({
    required this.property,
    required this.onTap,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverUrl = property.coverImageUrl;
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: coverUrl == null || coverUrl.isEmpty
                    ? Container(
                        width: 64,
                        height: 64,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.apartment,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Image.network(
                        coverUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_not_supported,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            property.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onShare,
                          icon: Icon(
                            Icons.share_outlined,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          tooltip: 'Share',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        if (property.featured)
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Color(0xFFF9A825),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      property.subtitleBits,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            property.priceLabel ??
                                Formatters.inrLabel(property.price),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        StatusPill(label: property.status),
                      ],
                    ),
                    if (property.city != null && property.city!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${property.propertyId} · ${property.city}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
