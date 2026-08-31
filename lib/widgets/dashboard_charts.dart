import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/models/dashboard.dart';
import '../core/utils/formatters.dart';

/// Charts column mirroring the web dashboard Recharts widgets.
class DashboardCharts extends StatelessWidget {
  final DashboardChartData data;
  const DashboardCharts({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.revenueByMonth.length > 1) ...[
          _Card(
            title: 'Revenue vs Leads (Monthly)',
            child: SizedBox(
              height: 220,
              child: _RevenueBarChart(points: data.revenueByMonth),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (data.leadSources.isNotEmpty)
          Row(
            children: [
              _Card(
                title: 'Lead Sources',
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: _LeadSourcePieChart(sources: data.leadSources),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Card(
                  title: 'Legend',
                  child: _Legend(items: data.leadSources
                      .map((s) => (s.name, s.value.toString()))
                      .toList()),
                ),
              ),
            ],
          ),
        if (data.leadSources.isNotEmpty) const SizedBox(height: 12),
        if (data.pipelineFunnel.isNotEmpty) ...[
          _Card(
            title: 'Pipeline Funnel',
            child: _FunnelBars(stages: data.pipelineFunnel),
          ),
          const SizedBox(height: 12),
        ],
        if (data.monthlyBookings.length > 1) ...[
          _Card(
            title: 'Monthly Bookings',
            child: SizedBox(
              height: 180,
              child: _BookingsLineChart(bookings: data.monthlyBookings),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (data.agentPerformance.isNotEmpty) ...[
          _Card(
            title: 'Agent Performance',
            child: _AgentBars(agents: data.agentPerformance),
          ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  final List<RevenuePoint> points;
  const _RevenueBarChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = points.fold<double>(0,
        (m, p) => p.revenue > m ? p.revenue : m);

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    points[i].month,
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].revenue,
                  width: 10,
                  borderRadius: BorderRadius.circular(3),
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LeadSourcePieChart extends StatelessWidget {
  final List<LeadSource> sources;
  const _LeadSourcePieChart({required this.sources});

  static const _palette = [
    Color(0xFF1E3A5F),
    Color(0xFF2E7D32),
    Color(0xFFF9A825),
    Color(0xFF1976D2),
    Color(0xFF6A1B9A),
    Color(0xFFC62828),
    Color(0xFF00838F),
    Color(0xFF4E342E),
  ];

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 8,
        sections: [
          for (var i = 0; i < sources.length; i++)
            PieChartSectionData(
              value: sources[i].value.toDouble(),
              color: _palette[i % _palette.length],
              radius: 34,
              showTitle: false,
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<(String, String)> items;
  const _Legend({required this.items});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((i) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _LeadSourcePieChart
                        ._palette[items.indexOf(i) %
                            _LeadSourcePieChart._palette.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(i.$1,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                Text(i.$2, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FunnelBars extends StatelessWidget {
  final List<PipelineStage> stages;
  const _FunnelBars({required this.stages});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = stages.fold<int>(0, (m, s) => s.count > m ? s.count : m);
    if (max == 0) {
      return Text('No deals in progress.',
          style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.outline));
    }

    return Column(
      children: stages.reversed.map((s) {
        final fraction = s.count / max;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.stage, style: theme.textTheme.bodySmall),
                  Text('${s.count}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                      fraction > 0.66
                          ? Colors.green.shade700
                          : fraction > 0.33
                              ? Colors.orange.shade700
                              : Colors.red.shade700),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _BookingsLineChart extends StatelessWidget {
  final List<MonthlyBooking> bookings;
  const _BookingsLineChart({required this.bookings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = bookings.fold<int>(0, (m, b) => b.bookings > m ? b.bookings : m);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY * 1.3,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (v) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= bookings.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    bookings[i].month,
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < bookings.length; i++)
                FlSpot(i.toDouble(), bookings[i].bookings.toDouble()),
            ],
            isCurved: true,
            color: Colors.green.shade700,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.shade700.withValues(alpha: 0.12),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class _AgentBars extends StatelessWidget {
  final List<AgentPerformance> agents;
  const _AgentBars({required this.agents});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: agents.map((a) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(width: 80, child: Text(a.name, style: theme.textTheme.bodySmall)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: agents.first.revenue == 0
                        ? 0
                        : (a.revenue / agents.first.revenue),
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 70,
                child: Text(
                  Formatters.inrLabel(a.revenue),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}