// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/site_visit.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/feedback.dart';
import '../../../widgets/filter_sheet.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_pill.dart';
import 'site_visits_controller.dart';

class SiteVisitDetailSheet extends ConsumerStatefulWidget {
  final SiteVisitItem initial;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onChanged;

  const SiteVisitDetailSheet({
    super.key,
    required this.initial,
    required this.canEdit,
    required this.canDelete,
    required this.onChanged,
  });

  @override
  ConsumerState<SiteVisitDetailSheet> createState() =>
      _SiteVisitDetailSheetState();
}

class _SiteVisitDetailSheetState extends ConsumerState<SiteVisitDetailSheet> {
  Future<void> _updateStatus() async {
    final opts = [
      for (final s in SiteVisitsController.statuses) (s, s),
    ];
    final v = await showFilterSheet(context,
        title: 'Update Visit Status',
        options: opts,
        current: widget.initial.status);
    if (v == null || v == widget.initial.status) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(siteVisitsRepositoryProvider)
          .update(widget.initial.id, {'status': v});
      widget.onChanged();
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
            content: Text('Visit marked $v'),
            behavior: SnackBarBehavior.floating));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirm(
      context,
      title: 'Delete site visit?',
      content: 'Visit for ${widget.initial.customerName} will be removed.',
      confirmLabel: 'Delete',
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (!ok) return;
    try {
      await ref
          .read(siteVisitsControllerProvider.notifier)
          .deleteVisit(widget.initial.id);
      widget.onChanged();
      if (mounted) {
        Navigator.of(context).pop();
        showToast(context, 'Site visit deleted.');
      }
    } catch (e) {
      if (mounted) showToast(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.initial;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.visitId,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: theme.colorScheme.primary)),
                    Text(v.customerName,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              StatusPill(label: v.status),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Where & When',
            child: Column(
              children: [
                _row('Property', v.propertyName),
                _row('Date', Formatters.date(v.visitDate)),
                _row('Time', v.visitTime),
                if (v.location != null && v.location!.isNotEmpty)
                  _row('Location', v.location!),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            title: 'Details',
            child: Column(
              children: [
                _row('Agent', v.agentName.isEmpty ? '—' : v.agentName),
                if (v.notes != null && v.notes!.isNotEmpty)
                  _row('Notes', v.notes!),
                if (v.feedback != null && v.feedback!.isNotEmpty)
                  _row('Feedback', v.feedback!),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (widget.canEdit)
            FilledButton.tonal(
              onPressed: _updateStatus,
              child: const Text('Update Status'),
            ),
          if (widget.canDelete)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: OutlinedButton(
                onPressed: _delete,
                style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error),
                child: const Text('Delete'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: theme.textTheme.bodySmall),
          Flexible(
            child: Text(v,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}