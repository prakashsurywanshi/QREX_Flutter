import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../widgets/dashboard_charts.dart';
import '../../../widgets/stat_card.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load on entry if no data yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(dashboardControllerProvider.notifier);
      final state = ref.read(dashboardControllerProvider);
      if (state.data == null) controller.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);
    final stats = state.data?.stats;

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardControllerProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _RangeSelector(
            selected: state.range,
            onSelected: (r) =>
                ref.read(dashboardControllerProvider.notifier).selectRange(r),
          ),
          const SizedBox(height: 12),
          if (state.loading && state.data == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null && stats == null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Text(state.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref
                          .read(dashboardControllerProvider.notifier)
                          .load(range: state.range),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (stats != null) ...[
            _StatGrid(stats: stats),
            const SizedBox(height: 16),
            DashboardCharts(data: state.data!.chartData),
            const SizedBox(height: 12),
            if (state.data!.recentLeads.isNotEmpty) ...[
              _SectionCard(
                title: 'Recent Leads',
                trailing: Text('${state.data!.stats.newLeads} new in range',
                    style: Theme.of(context).textTheme.bodySmall),
                child: _RecentLeads(leads: state.data!.recentLeads),
              ),
              const SizedBox(height: 12),
            ],
            if (state.data!.upcomingVisits.isNotEmpty) ...[
              _SectionCard(
                title: 'Upcoming Site Visits',
                child: _UpcomingVisits(visits: state.data!.upcomingVisits),
              ),
              const SizedBox(height: 12),
            ],
            if (state.data!.topAgents.isNotEmpty) ...[
              _SectionCard(
                title: 'Top Agents',
                child: _TopAgents(agents: state.data!.topAgents),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  const _RangeSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = DashboardController.ranges;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((o) {
          final isSel = o.$1 == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(o.$2),
              selected: isSel,
              onSelected: (_) => onSelected(o.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final dynamic stats;
  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        StatCard(
          label: 'Revenue (Won)',
          value: Formatters.inrLabel((stats.revenue as num).toDouble()),
          icon: Icons.currency_rupee,
          color: Colors.green.shade700,
        ),
        StatCard(
          label: 'Pending Payments',
          value: Formatters.inrLabel((stats.pendingPayments as num).toDouble()),
          icon: Icons.pending_actions,
          color: Colors.orange.shade800,
        ),
        StatCard(
          label: 'Received',
          value: Formatters.inrLabel((stats.received as num).toDouble()),
          icon: Icons.account_balance_wallet,
          color: Colors.teal.shade700,
        ),
        StatCard(
          label: 'Active Leads',
          value: '${stats.activeLeads}',
          icon: Icons.people_alt,
          color: Colors.indigo.shade600,
        ),
        StatCard(
          label: 'Active Deals',
          value: '${stats.activeDeals}',
          icon: Icons.view_kanban,
          color: Colors.purple.shade600,
        ),
        StatCard(
          label: 'Site Visits',
          value: '${stats.siteVisits}',
          icon: Icons.event_available,
          color: Colors.blueGrey.shade600,
        ),
        StatCard(
          label: 'Properties',
          value: '${stats.totalProperties}',
          icon: Icons.apartment,
          color: Colors.brown.shade600,
        ),
        StatCard(
          label: 'Sold',
          value: '${stats.soldProperties}',
          icon: Icons.check_circle,
          color: Colors.cyan.shade700,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _RecentLeads extends StatelessWidget {
  final List<Map<String, dynamic>> leads;
  const _RecentLeads({required this.leads});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: leads.map((l) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(_initials(l['name'] ?? ''))),
          title: Text(l['name'] ?? ''),
          subtitle: Text(l['source'] ?? ''),
          trailing: _StatusPill(label: l['status'] ?? ''),
        );
      }).toList(),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).take(2);
    return parts.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join();
  }
}

class _UpcomingVisits extends StatelessWidget {
  final List<Map<String, dynamic>> visits;
  const _UpcomingVisits({required this.visits});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: visits.map((v) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event_available),
          title: Text(v['customer_name'] ?? ''),
          subtitle: Text('${v['property_name'] ?? ''} · ${Formatters.date(v['visit_date'])} ${v['visit_time'] ?? ''}'),
          trailing: _StatusPill(label: v['status'] ?? ''),
        );
      }).toList(),
    );
  }
}

class _TopAgents extends StatelessWidget {
  final List<Map<String, dynamic>> agents;
  const _TopAgents({required this.agents});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: agents.map((a) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(a['initials'] ?? '')),
          title: Text(a['name'] ?? ''),
          subtitle: Text('${a['deals'] ?? 0} closed deals'),
          trailing: Text(
            Formatters.inrLabel((a['revenue'] as num?)?.toDouble() ?? 0),
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer)),
    );
  }
}
