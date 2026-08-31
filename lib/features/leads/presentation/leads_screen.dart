import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/lead.dart';
import '../../../core/notifiers/paged_state.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/filter_sheet.dart';
import '../../../widgets/initials_avatar.dart';
import '../../../widgets/pagination_bar.dart';
import '../../../widgets/status_pill.dart';
import 'lead_detail_sheet.dart';
import 'lead_form_sheet.dart';
import 'leads_controller.dart';

class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key});

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(leadsControllerProvider.notifier);
      if (ref.read(leadsControllerProvider).items.isEmpty) c.load();
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
      ref.read(leadsControllerProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leadsControllerProvider);
    final controller = ref.read(leadsControllerProvider.notifier);
    final lookups = controller.lookups;
    final user = ref.watch(currentUserProvider);
    final can = user?.can;
    final canCreate = can?.canCreate('leads') == true;
    final canEdit = can?.canEdit('leads') == true;
    final canDelete = can?.canDelete('leads') == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        actions: [
          if (state.total > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('${state.total}',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Lead'),
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
                hintText: 'Search name, phone, email…',
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
                    borderRadius: BorderRadius.circular(12)),
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
                    final v = await showFilterSheet(context,
                        title: 'Filter by Status',
                        options: opts,
                        current: state.filters['status'] ?? 'All');
                    if (v != null) controller.setFilter('status', v);
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Source: ${state.filters['source'] ?? 'All'}',
                  onTap: () async {
                    final opts = [
                      for (final s in ['All', ...lookups.sources]) (s, s),
                    ];
                    final v = await showFilterSheet(context,
                        title: 'Filter by Source',
                        options: opts,
                        current: state.filters['source'] ?? 'All');
                    if (v != null) controller.setFilter('source', v);
                  },
                ),
                if (lookups.campaigns.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Campaign: ${state.filters['campaign'] ?? 'All'}',
                    onTap: () async {
                      final opts = [
                        ('All', 'All'),
                        for (final c in lookups.campaigns)
                          ('${c.id}', c.name),
                      ];
                      final v = await showFilterSheet(context,
                          title: 'Filter by Campaign',
                          options: opts,
                          current: state.filters['campaign'] ?? 'All');
                      if (v != null) controller.setFilter('campaign', v);
                    },
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: _buildList(context, state, controller, canEdit, canDelete)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, PagedState<Lead> state,
      LeadsController controller, bool canEdit, bool canDelete) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        message: state.error!,
        action: FilledButton(
            onPressed: controller.refresh, child: const Text('Retry')),
      );
    }
    if (state.items.isEmpty) {
      return const EmptyState(
        icon: Icons.person_search,
        message: 'No leads found',
        hint: 'Adjust filters or add your first lead.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async { controller.refresh(); },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
        itemCount: state.items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          if (i == state.items.length) {
            return PaginationBar(
              currentPage: state.currentPage,
              lastPage: state.lastPage,
              total: state.total,
              onPage: (p) { controller.loadPage(p); },
            );
          }
          final lead = state.items[i];
          return _LeadTile(
            lead: lead,
            onTap: () => _openDetail(context, lead, canEdit, canDelete),
          );
        },
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, Lead lead,
      bool canEdit, bool canDelete) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => LeadDetailSheet(
        initial: lead,
        canEdit: canEdit,
        canDelete: canDelete,
        onChanged: () =>
            ref.read(leadsControllerProvider.notifier).refresh(),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => LeadFormSheet(
        onSaved: () =>
            ref.read(leadsControllerProvider.notifier).refresh(),
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

class _LeadTile extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;
  const _LeadTile({required this.lead, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              InitialsAvatar(name: lead.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lead.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (lead.score > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${lead.score}',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: theme.colorScheme.primary)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lead.phone + (lead.budget != null ? ' · ${lead.budget!}' : ''),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            [lead.source, lead.preferredLocation]
                                .where((e) => e != null && e.isNotEmpty)
                                .join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: theme.colorScheme.outline),
                          ),
                        ),
                        StatusPill(label: lead.status),
                      ],
                    ),
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