import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/deal.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/initials_avatar.dart';
import 'pipeline_controller.dart';
import 'pipeline_deal_sheet.dart';
import 'pipeline_form_sheet.dart';

class PipelineScreen extends ConsumerStatefulWidget {
  const PipelineScreen({super.key});

  @override
  ConsumerState<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends ConsumerState<PipelineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(pipelineControllerProvider.notifier);
      final state = ref.read(pipelineControllerProvider);
      if (!state.loading && state.deals.isEmpty) c.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pipelineControllerProvider);
    final controller = ref.read(pipelineControllerProvider.notifier);
    final theme = Theme.of(context);
    final can = ref.watch(currentUserProvider)?.can;
    final canCreate = can?.canCreate('sales') == true;
    final canEdit = can?.canEdit('sales') == true;
    final canDelete = can?.canDelete('sales') == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pipeline'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: controller.load,
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Deal'),
            )
          : null,
      body: Column(
        children: [
          _SummaryStrip(summary: state.summary),
          const Divider(height: 1),
          Expanded(
            child: state.loading && state.deals.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.stages.isEmpty
                    ? EmptyState(
                        icon: Icons.view_kanban,
                        message: 'No deals in the pipeline',
                        action: FilledButton(
                            onPressed: controller.load,
                            child: const Text('Retry')),
                      )
                    : RefreshIndicator(
                        onRefresh: controller.load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 100),
                          children: [
                            SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: state.stages.map((stage) {
                                  final count = state
                                      .dealsIn(stage)
                                      .length;
                                  final isClosed =
                                      stage == 'Closed Won' ||
                                          stage == 'Closed Lost';
                                  return InputChip(
                                    selected: count > 0,
                                    showCheckmark: false,
                                    label: Text('$stage ($count)'),
                                    avatar: Icon(
                                      isClosed
                                          ? (stage == 'Closed Won'
                                              ? Icons.check_circle
                                              : Icons.cancel)
                                          : Icons.trending_up,
                                      size: 16,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            for (final stage in state.stages) ...[
                              _StageHeader(
                                  stage: stage,
                                  count: state.dealsIn(stage).length),
                              if (state.dealsIn(stage).isEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                                  child: Text('No deals in this stage',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .outline)),
                                )
                              else
                                for (final deal in state.dealsIn(stage))
                                  _DealCard(
                                    deal: deal,
                                    onTap: canEdit || canDelete
                                        ? () => _openDeal(context, deal,
                                            canEdit, canDelete)
                                        : null,
                                  ),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDeal(BuildContext context, Deal deal,
      bool canEdit, bool canDelete) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => PipelineDealSheet(
        initial: deal,
        canEdit: canEdit,
        canDelete: canDelete,
        onChanged: () =>
            ref.read(pipelineControllerProvider.notifier).load(),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => PipelineFormSheet(
        onSaved: () =>
            ref.read(pipelineControllerProvider.notifier).load(),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final PipelineSummary summary;
  const _SummaryStrip({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cells = <(IconData, Color, String, String)>[
      (Icons.payments, Colors.orange.shade800,
          'Pipeline Value', Formatters.inrLabel(summary.pipelineValue)),
      (Icons.trending_up, Colors.indigo.shade600,
          'Expected', Formatters.inrLabel(summary.expectedRevenue)),
      (Icons.emoji_events, Colors.green.shade700,
          'Won', Formatters.inrLabel(summary.wonValue)),
      (Icons.sync, Colors.purple.shade600,
          'Conversion', '${summary.conversionRate}%'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        children: cells.map((c) {
          return Expanded(
            child: Column(
              children: [
                Icon(c.$1, color: c.$2, size: 20),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(c.$3,
                      maxLines: 1,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Text(c.$4,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StageHeader extends StatelessWidget {
  final String stage;
  final int count;

  const _StageHeader({
    required this.stage,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Row(
        children: [
          Text(stage,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
          ),
        ],
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final Deal deal;
  final VoidCallback? onTap;
  const _DealCard({required this.deal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              InitialsAvatar(name: deal.customerName, radius: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(deal.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        Text(
                          deal.valueLabel ??
                              Formatters.inrLabel(deal.dealValue),
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (deal.propertyName != null) deal.propertyName!,
                        '${deal.probability}%',
                        if (deal.agentName != null) deal.agentName!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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