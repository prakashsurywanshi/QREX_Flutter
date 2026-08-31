import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/site_visit.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_pill.dart';
import 'site_visit_detail_sheet.dart';
import 'site_visit_form_sheet.dart';
import 'site_visits_controller.dart';

class SiteVisitsScreen extends ConsumerStatefulWidget {
  const SiteVisitsScreen({super.key});

  @override
  ConsumerState<SiteVisitsScreen> createState() => _SiteVisitsScreenState();
}

class _SiteVisitsScreenState extends ConsumerState<SiteVisitsScreen> {
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(siteVisitsControllerProvider.notifier);
      if (ref.read(siteVisitsControllerProvider).visits.isEmpty) c.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(siteVisitsControllerProvider);
    final controller = ref.read(siteVisitsControllerProvider.notifier);
    final can = ref.watch(currentUserProvider)?.can;
    final canCreate = can?.canCreate('site_visits') == true;
    final canEdit = can?.canEdit('site_visits') == true;
    final canDelete = can?.canDelete('site_visits') == true;

    final filtered = _statusFilter == 'All'
        ? state.visits
        : state.visits.where((v) => v.status == _statusFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Visits'),
        actions: [
          IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: controller.load),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.event_available),
              label: const Text('Schedule'),
            )
          : null,
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                for (final s in ['All', ...SiteVisitsController.statuses])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: _statusFilter == s,
                      onSelected: (_) =>
                          setState(() => _statusFilter = s),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildList(context, state, filtered, controller,
              canEdit, canDelete)),
        ],
      ),
    );
  }

  Widget _buildList(
      BuildContext context,
      SiteVisitsState state,
      List<SiteVisitItem> visits,
      SiteVisitsController controller,
      bool canEdit,
      bool canDelete) {
    if (state.loading && state.visits.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.visits.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        message: state.error!,
        action: FilledButton(
            onPressed: controller.load, child: const Text('Retry')),
      );
    }
    if (visits.isEmpty) {
      return const EmptyState(
        icon: Icons.event_note,
        message: 'No site visits',
        hint: 'Schedule a visit for your leads.',
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
        itemCount: visits.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final v = visits[i];
          return _VisitTile(
            visit: v,
            onTap: canEdit || canDelete
                ? () => _openDetail(context, v, canEdit, canDelete)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, SiteVisitItem v,
      bool canEdit, bool canDelete) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SiteVisitDetailSheet(
        initial: v,
        canEdit: canEdit,
        canDelete: canDelete,
        onChanged: () =>
            ref.read(siteVisitsControllerProvider.notifier).load(),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SiteVisitFormSheet(
        onSaved: () =>
            ref.read(siteVisitsControllerProvider.notifier).load(),
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  final SiteVisitItem visit;
  final VoidCallback? onTap;
  const _VisitTile({required this.visit, this.onTap});

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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_available),
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
                            visit.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        StatusPill(label: visit.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      visit.propertyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Formatters.date(visit.visitDate)} · ${visit.visitTime}'
                      '${visit.agentName.isNotEmpty ? ' · ${visit.agentName}' : ''}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.outline),
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