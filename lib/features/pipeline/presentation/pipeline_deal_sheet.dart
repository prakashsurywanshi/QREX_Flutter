// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/deal.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/feedback.dart';
import '../../../widgets/filter_sheet.dart';
import '../../../widgets/initials_avatar.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_pill.dart';
import 'pipeline_controller.dart';
import 'pipeline_form_sheet.dart';

class PipelineDealSheet extends ConsumerStatefulWidget {
  final Deal initial;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onChanged;

  const PipelineDealSheet({
    super.key,
    required this.initial,
    required this.canEdit,
    required this.canDelete,
    required this.onChanged,
  });

  @override
  ConsumerState<PipelineDealSheet> createState() => _PipelineDealSheetState();
}

class _PipelineDealSheetState extends ConsumerState<PipelineDealSheet> {
  Deal? _deal;

  @override
  void initState() {
    super.initState();
    _deal = widget.initial;
  }

  Future<void> _moveStage() async {
    final deal = _deal!;
    final controller = ref.read(pipelineControllerProvider.notifier);
    final stages = ref.read(pipelineControllerProvider).stages;
    if (stages.isEmpty) return;
    final v = await showFilterSheet(
      context,
      title: 'Move to stage',
      options: [for (final s in stages) (s, s)],
      current: deal.stage,
    );
    if (v == null || v == deal.stage) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await controller.moveStage(deal.id, v);
      if (mounted) setState(() => _deal = updated);
      widget.onChanged();
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
            content: Text('Deal moved to $v'),
            behavior: SnackBarBehavior.floating));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _edit() async {
    final stages = ref.read(pipelineControllerProvider).stages;
    final lookups = ref.read(pipelineControllerProvider);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => PipelineFormSheet(
        initial: _deal,
        stages: stages,
        properties: lookups.properties,
        customers: lookups.customers,
        agents: lookups.agents,
        onSaved: () {
          widget.onChanged();
          _reload();
        },
      ),
    );
  }

  Future<void> _reload() async {
    widget.onChanged();
    try {
      final fresh = ref.read(pipelineControllerProvider).deals
          .firstWhere((d) => d.id == widget.initial.id);
      if (mounted) setState(() => _deal = fresh);
    } catch (_) {
      // deleted or not yet refreshed; ignore
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirm(
      context,
      title: 'Delete deal?',
      content:
          '${_deal!.customerName} (${_deal!.dealId}) will be removed from the pipeline.',
      confirmLabel: 'Delete',
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (!ok) return;
    try {
      await ref
          .read(pipelineControllerProvider.notifier)
          .deleteDeal(_deal!.id);
      widget.onChanged();
      if (mounted) {
        Navigator.of(context).pop();
        showToast(context, 'Deal deleted.');
      }
    } catch (e) {
      if (mounted) showToast(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deal = _deal!;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      builder: (ctx, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialsAvatar(name: deal.customerName, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deal.dealId,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: theme.colorScheme.primary)),
                    Text(deal.customerName,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              StatusPill(label: deal.stage),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.payments, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                deal.valueLabel ?? Formatters.inrLabel(deal.dealValue),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text('${deal.probability}% probable',
                  style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.canEdit)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Move Stage'),
                  onPressed: _moveStage,
                ),
                ActionChip(
                  avatar: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  onPressed: _edit,
                ),
              ],
            ),
          if (widget.canDelete)
            TextButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete'),
              style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error),
            ),
          const SizedBox(height: 4),
          SectionCard(
            title: 'Details',
            child: Column(
              children: [
                for (final (k, v) in _rows(deal))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(k, style: theme.textTheme.bodySmall),
                        Flexible(
                          child: Text(v,
                              textAlign: TextAlign.right,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            title: 'Progress',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hourglass_bottom, size: 16),
                    const SizedBox(width: 8),
                    Text('${deal.daysInStage} days in stage',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (deal.probability / 100).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<(String, String)> _rows(Deal deal) {
    return [
      if (deal.propertyName != null && deal.propertyName!.isNotEmpty)
        ('Property', deal.propertyName!),
      if (deal.agentName != null) ('Agent', deal.agentName!),
      if (deal.nextFollowup != null && deal.nextFollowup!.isNotEmpty)
        ('Next follow-up', deal.nextFollowup!),
      if (deal.lastActivity != null && deal.lastActivity!.isNotEmpty)
        ('Last activity', deal.lastActivity!),
      ('Created', Formatters.date(deal.createdAt)),
    ];
  }
}