// ignore_for_file: use_build_context_synchronously

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/report.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_pill.dart';
import 'reports_controller.dart';

const _exportTypes = [
  ('revenue', 'Revenue'),
  ('leads', 'Leads'),
  ('payments', 'Payments'),
  ('agents', 'Agents'),
  ('properties', 'Properties'),
  ('sitevisits', 'Site Visits'),
  ('campaigns', 'Campaigns'),
];

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(reportsControllerProvider.notifier);
      if (ref.read(reportsControllerProvider).data.revenueByMonth.isEmpty) {
        c.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsControllerProvider);
    final controller = ref.read(reportsControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [_ExportMenu(pdf: false), _ExportMenu(pdf: true)],
      ),
      body: state.loading && state.data.revenueByMonth.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.data.revenueByMonth.isEmpty
              ? EmptyState(
                  icon: Icons.cloud_off,
                  message: state.error!,
                  action: FilledButton(
                      onPressed: controller.load, child: const Text('Retry')),
                )
              : RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                    children: [
                      _FilterBar(state: state, controller: controller),
                      const SizedBox(height: 12),
                      _KpiStrip(data: state.data),
                      const SizedBox(height: 16),
                      if (state.data.revenueByMonth.isNotEmpty) ...[
                        SectionCard(
                          title: 'Revenue Trend',
                          child: SizedBox(
                            height: 180,
                            child: _RevenueChart(data: state.data),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (state.data.leadSourceData.isNotEmpty) ...[
                        SectionCard(
                          title: 'Lead Sources',
                          child: SizedBox(
                            height: 180,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _LeadSourcesPie(
                                      sources: state.data.leadSourceData),
                                ),
                                Expanded(
                                  child: _SourceLegend(
                                      sources: state.data.leadSourceData),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (state.data.pipelineFunnel.isNotEmpty) ...[
                        SectionCard(
                          title: 'Pipeline Funnel',
                          child: _FunnelBars(funnel: state.data.pipelineFunnel),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (state.data.paymentData.isNotEmpty) ...[
                        SectionCard(
                          title: 'Collections vs Pending',
                          child: SizedBox(
                            height: 180,
                            child: _PaymentChart(data: state.data),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SectionCard(
                        title: 'Deals',
                        child: state.data.reportTables.deals.isEmpty
                            ? const EmptyState(
                                icon: Icons.view_kanban_outlined,
                                message: 'No deals in this range')
                            : Column(
                                children: [
                                  for (final d in state.data.reportTables.deals)
                                    _DealRow(deal: d),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),
                      SectionCard(
                        title: 'Payments',
                        child: state.data.reportTables.payments.isEmpty
                            ? const EmptyState(
                                icon: Icons.payments_outlined,
                                message: 'No payments in this range')
                            : Column(
                                children: [
                                  for (final p
                                      in state.data.reportTables.payments)
                                    _PaymentRow(row: p),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),
                      if (state.data.campaignPerformance.isNotEmpty) ...[
                        SectionCard(
                          title: 'Campaigns',
                          child: Column(
                            children: [
                              for (final c in state.data.campaignPerformance)
                                _CampaignRow(c: c),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (state.data.siteVisits.isNotEmpty) ...[
                        SectionCard(
                          title: 'Site Visits',
                          child: Column(
                            children: [
                              _visitStats(theme, state.data.siteVisitReport),
                              for (final v in state.data.siteVisits)
                                _VisitRow(row: v),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _visitStats(ThemeData theme, VisitStat s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 10,
        children: [
          for (final entry in [
            ('Total', s.total, theme.colorScheme.primary),
            ('Scheduled', s.scheduled, Colors.orange.shade700),
            ('Completed', s.completed, Colors.green.shade700),
            ('Rescheduled', s.rescheduled, Colors.blue.shade700),
            ('Cancelled', s.cancelled, Colors.red.shade700),
          ])
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${entry.$2}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: entry.$3)),
                  const SizedBox(width: 4),
                  Text(entry.$1, style: theme.textTheme.labelSmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ExportMenu extends ConsumerWidget {
  final bool pdf;
  const _ExportMenu({required this.pdf});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);
    return PopupMenuButton<String>(
      tooltip: pdf ? 'Export PDF' : 'Export CSV',
      icon: Icon(pdf ? Icons.picture_as_pdf_outlined : Icons.download_outlined),
      onSelected: (type) async {
        try {
          final path = await ref
              .read(reportsControllerProvider.notifier)
              .export(type: type, pdf: pdf);
          messenger
            ..clearSnackBars()
            ..showSnackBar(SnackBar(
              content: Text('Exported to $path'),
              behavior: SnackBarBehavior.floating,
            ));
        } catch (e) {
          messenger
            ..clearSnackBars()
            ..showSnackBar(SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ));
        }
      },
      itemBuilder: (_) => [
        for (final t in _exportTypes)
          PopupMenuItem(value: t.$1, child: Text(t.$2)),
      ],
    );
  }
}

class _FilterBar extends ConsumerWidget {
  final ReportsState state;
  final ReportsController controller;
  const _FilterBar({required this.state, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final r in reportRanges)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(reportRangesLabels[r]!),
                    selected: state.range == r,
                    onSelected: (_) =>
                        controller.applyFilter(range: r),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _FilterDropdown(
                label: 'Agent',
                value: state.agentId,
                items: [
                  (0, 'All Agents'),
                  for (final a in state.data.agents) (a.id, a.name),
                ],
                onChanged: (v) => controller.applyFilter(agentId: v ?? 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterDropdown(
                label: 'Property',
                value: state.propertyId,
                items: [
                  (0, 'All Properties'),
                  for (final p in state.data.properties) (p.id, p.name),
                ],
                onChanged: (v) => controller.applyFilter(propertyId: v ?? 0),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final int value;
  final List<(int, String)> items;
  final ValueChanged<int?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: [for (final it in items) DropdownMenuItem(value: it.$1, child: Text(it.$2, overflow: TextOverflow.ellipsis))],
      onChanged: onChanged,
    );
  }
}

class _KpiStrip extends StatelessWidget {
  final ReportsData data;
  const _KpiStrip({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final revenue = data.revenueByMonth.fold<double>(
        0, (a, m) => a + m.revenue);
    final leads = data.leadSourceData.fold<int>(0, (a, s) => a + s.value);
    final bookings = data.monthlyBookings.fold<int>(0, (a, m) => a + m.bookings);
    final closedWon = data.pipelineFunnel
        .where((s) => s.stage == 'Closed Won')
        .fold<int>(0, (a, s) => a + s.count);

    Widget cell(String label, String value, IconData icon, Color color) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall),
                    Text(label,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        cell('Revenue', '${revenue.toStringAsFixed(2)} Cr',
            Icons.trending_up, theme.colorScheme.primary),
        cell('Leads', '$leads', Icons.people_alt_outlined,
            Colors.green.shade700),
        cell('Bookings', '$bookings', Icons.event_seat,
            Colors.orange.shade700),
        cell('Closed Won', '$closedWon', Icons.verified_outlined,
            theme.colorScheme.tertiary),
      ],
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final ReportsData data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = data.revenueByMonth;
    if (months.isEmpty) return const SizedBox.shrink();
    final maxV =
        months.fold<double>(0, (a, m) => math.max(a, m.revenue));
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxV == 0 ? 1 : maxV * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxV == 0 ? 1 : maxV * 1.2 / 4,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= months.length) {
                  return const SizedBox.shrink();
                }
                return Text(months[i].month,
                    style: theme.textTheme.labelSmall);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (v, meta) => Text(v.toInt().toString(),
                  style: theme.textTheme.labelSmall),
            ),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: true),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < months.length; i++)
                FlSpot(i.toDouble(), months[i].revenue),
            ],
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentChart extends StatelessWidget {
  final ReportsData data;
  const _PaymentChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = data.paymentData;
    if (months.isEmpty) return const SizedBox.shrink();
    final maxV = months.fold<double>(
        0, (a, m) => math.max(a, math.max(m.collected, m.pending)));
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxV == 0 ? 1 : maxV * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxV == 0 ? 1 : maxV * 1.2 / 4,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= months.length) {
                  return const SizedBox.shrink();
                }
                return Text(months[i].month,
                    style: theme.textTheme.labelSmall);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (v, meta) => Text(v.toInt().toString(),
                  style: theme.textTheme.labelSmall),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < months.length; i++)
                FlSpot(i.toDouble(), months[i].collected),
            ],
            isCurved: true,
            color: Colors.green.shade700,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: [
              for (var i = 0; i < months.length; i++)
                FlSpot(i.toDouble(), months[i].pending),
            ],
            isCurved: true,
            color: Colors.red.shade400,
            barWidth: 2.5,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class _LeadSourcesPie extends StatelessWidget {
  final List<NamedValue> sources;
  const _LeadSourcesPie({required this.sources});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = [
      theme.colorScheme.primary,
      theme.colorScheme.tertiary,
      theme.colorScheme.secondary,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade400,
    ];
    final total = sources.fold<int>(0, (a, s) => a + s.value);
    if (total == 0) return const SizedBox.shrink();
    return PieChart(
      PieChartData(
        sections: [
          for (var i = 0; i < sources.length; i++)
            PieChartSectionData(
              value: sources[i].value / total,
              title: '',
              color: palette[i % palette.length],
              radius: 46,
            ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 24,
      ),
    );
  }
}

class _SourceLegend extends StatelessWidget {
  final List<NamedValue> sources;
  const _SourceLegend({required this.sources});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = [
      theme.colorScheme.primary,
      theme.colorScheme.tertiary,
      theme.colorScheme.secondary,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade400,
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < sources.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: palette[i % palette.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(sources[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall),
                ),
                Text('${sources[i].value}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}

class _FunnelBars extends StatelessWidget {
  final List<FunnelStage> funnel;
  const _FunnelBars({required this.funnel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount =
        funnel.fold<int>(0, (a, s) => math.max(a, s.count));
    return Column(
      children: [
        for (final s in funnel)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  child: Text(s.stage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxCount == 0 ? 0 : s.count / maxCount,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: Text('${s.count} · ${s.value.toStringAsFixed(1)}Cr',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelSmall),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DealRow extends StatelessWidget {
  final ReportDealRow deal;
  const _DealRow({required this.deal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deal.customer, style: theme.textTheme.bodyMedium),
                Text('${deal.property} · ${deal.agent}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
          StatusPill(label: deal.stage),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Formatters.inrLabel(deal.value),
                  style: theme.textTheme.titleSmall),
              Text('${deal.probability}%',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final ReportPaymentRow row;
  const _PaymentRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.customer, style: theme.textTheme.bodyMedium),
                Text('Due ${row.due} · Paid ${row.paid}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
          StatusPill(label: row.status),
          const SizedBox(width: 8),
          Text(Formatters.inrLabel(row.amount),
              style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _CampaignRow extends StatelessWidget {
  final CampaignPerf c;
  const _CampaignRow({required this.c});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: theme.textTheme.bodyMedium),
                Text(c.channel,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
          Text(
              '${Formatters.inrLabel(c.spent)} · ${c.leads} leads · ${c.conversions} conv',
              style: theme.textTheme.labelSmall),
          const SizedBox(width: 8),
          StatusPill(label: c.status),
        ],
      ),
    );
  }
}

class _VisitRow extends StatelessWidget {
  final VisitRow row;
  const _VisitRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${row.id} · ${row.customer}',
                    style: theme.textTheme.bodyMedium),
                Text(row.property,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
          Text(row.date, style: theme.textTheme.labelSmall),
          const SizedBox(width: 8),
          StatusPill(label: row.status),
        ],
      ),
    );
  }
}