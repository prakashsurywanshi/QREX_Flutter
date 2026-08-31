// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/campaign.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/feedback.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_pill.dart';
import 'marketing_controller.dart';

class CampaignDetailSheet extends ConsumerStatefulWidget {
  final Campaign initial;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onChanged;

  const CampaignDetailSheet({
    super.key,
    required this.initial,
    this.canEdit = false,
    this.canDelete = false,
    required this.onChanged,
  });

  @override
  ConsumerState<CampaignDetailSheet> createState() =>
      _CampaignDetailSheetState();
}

class _CampaignDetailSheetState extends ConsumerState<CampaignDetailSheet> {
  String? _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initial.status;
  }

  Future<void> _setStatus(String? v) async {
    if (v == null || v == _status) return;
    setState(() {
      _status = v;
      _saving = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      await ref
          .read(marketingControllerProvider.notifier)
          .setStatus(widget.initial.id, v);
      widget.onChanged();
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Campaign status updated.'),
          behavior: SnackBarBehavior.floating,
        ));
    } catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ));
      setState(() => _status = widget.initial.status);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirm(context,
        title: 'Delete Campaign?',
        content: 'Delete "${widget.initial.name}"?',
        confirmLabel: 'Delete');
    if (ok != true) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      await ref
          .read(marketingControllerProvider.notifier)
          .deleteCampaign(widget.initial.id);
      widget.onChanged();
      if (mounted) navigator.pop();
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Campaign deleted.'),
          behavior: SnackBarBehavior.floating,
        ));
    } catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.initial;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: theme.textTheme.titleLarge),
                    Text('${c.campaignId} · ${c.channel}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline)),
                  ],
                ),
              ),
              StatusPill(label: c.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                    label: 'Budget',
                    value: Formatters.inrLabel(c.budget),
                    icon: Icons.account_balance_wallet,
                    color: theme.colorScheme.primary),
              ),
              Expanded(
                child: _MetricCard(
                    label: 'Spent',
                    value: Formatters.inrLabel(c.spent),
                    icon: Icons.payments,
                    color: theme.colorScheme.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                    label: 'Leads',
                    value: '${c.leads}',
                    icon: Icons.groups,
                    color: Colors.green.shade700),
              ),
              Expanded(
                child: _MetricCard(
                    label: 'Conversions',
                    value: '${c.conversions}',
                    icon: Icons.check_circle_outline,
                    color: theme.colorScheme.tertiary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Performance',
            child: Column(
              children: [
                _row(theme, 'Revenue',
                    c.revenueLabel == '—'
                        ? Formatters.inrLabel(c.revenue)
                        : c.revenueLabel),
                _row(theme, 'ROI', c.roi == null || c.roi == '' ? '—' : c.roi!),
                _row(theme, 'Start Date', Formatters.date(c.startDate)),
                _row(theme, 'End Date', Formatters.date(c.endDate)),
                _row(theme, 'Created', Formatters.date(c.createdAt)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (widget.canEdit) ...[
            SectionCard(
              title: 'Update Status',
              child: DropdownButtonFormField<String>(
                initialValue: _status,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Status',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  isDense: true,
                ),
                items: [
                  for (final s in campaignStatuses)
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: _saving ? null : _setStatus,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.canDelete)
            OutlinedButton.icon(
              onPressed: _delete,
              style:
                  OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Campaign'),
            ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label:  ',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
            TextSpan(
              text: value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
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
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}