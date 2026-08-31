// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/lead.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/feedback.dart';
import '../../../widgets/filter_sheet.dart';
import '../../../widgets/initials_avatar.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_pill.dart';
import '../data/leads_repository.dart';
import 'lead_form_sheet.dart';
import 'leads_controller.dart';

class LeadDetailSheet extends ConsumerStatefulWidget {
  final Lead initial;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onChanged;

  const LeadDetailSheet({
    super.key,
    required this.initial,
    required this.canEdit,
    required this.canDelete,
    required this.onChanged,
  });

  @override
  ConsumerState<LeadDetailSheet> createState() => _LeadDetailSheetState();
}

class _LeadDetailSheetState extends ConsumerState<LeadDetailSheet> {
  LeadDetail? _detail;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final d = await ref.read(leadsRepositoryProvider).show(widget.initial.id);
      if (mounted) {
        setState(() {
          _detail = d;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<LeadDetail> _ensureDetail() async {
    if (_detail == null) await _reload();
    return _detail!;
  }

  Future<void> _changeStatus() async {
    final detail = await _ensureDetail();
    final statuses = ref
        .read(leadsControllerProvider.notifier)
        .lookups
        .statuses;
    final opts = [
      for (final s in (statuses.isEmpty ? ['New', 'Contacted', 'Qualified', 'Site Visit Scheduled', 'Site Visit Completed', 'Negotiation', 'Converted', 'Lost'] : statuses))
        (s, s),
    ];
    final v = await showFilterSheet(context,
        title: 'Change Status', options: opts, current: detail.lead.status);
    if (v == null || v == detail.lead.status) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(leadsRepositoryProvider).changeStatus(detail.lead.id, v);
      widget.onChanged();
      await _reload();
      messenger.showSnackBar(SnackBar(
          content: Text('Status changed to $v'),
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      messenger.clearSnackBars();
      messenger.showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _convertToDeal() async {
    final detail = await _ensureDetail();
    if (const ['Converted', 'Lost'].contains(detail.lead.status)) {
      showToast(context,
          'This lead cannot be converted in its current status.',
          isError: true);
      return;
    }
    final valueCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? stage;
    final stages = const [
      'Qualified', 'Property Shortlisted', 'Site Visit Scheduled',
      'Site Visit Completed', 'Negotiation', 'Booking',
    ];
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Form(
        key: formKey,
        child: AlertDialog(
          title: const Text('Convert to Deal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: valueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Deal value (₹) *'),
                  validator: (v) =>
                      num.tryParse((v ?? '').trim()) == null
                          ? 'Enter a valid amount'
                          : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: stage,
                  decoration: const InputDecoration(labelText: 'Stage'),
                  items: [
                    for (final s in stages)
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: (v) => stage = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.of(ctx).pop(true);
                },
                child: const Text('Convert')),
          ],
        ),
      ),
    );
    if (result != true) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(leadsRepositoryProvider).convertToDeal(
            detail.lead.id,
            dealValue: num.tryParse(valueCtrl.text.trim())?.toDouble() ?? 0,
            stage: stage,
          );
      widget.onChanged();
      await _reload();
      messenger.showSnackBar(const SnackBar(
          content: Text('Lead converted to deal.'),
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _reassign() async {
    final detail = await _ensureDetail();
    final whyCtrl = TextEditingController();
    int? agentId;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reassign Lead'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: agentId,
              decoration: const InputDecoration(labelText: 'Assign to'),
              items: [
                for (final a in detail.agents)
                  DropdownMenuItem(value: a.id, child: Text(a.name)),
              ],
              onChanged: (v) => agentId = v,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: whyCtrl,
              decoration: const InputDecoration(
                  labelText: 'Reason (optional)', hintText: 'e.g. Visiting another city'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Reassign')),
        ],
      ),
    );
    if (result != true) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(leadsRepositoryProvider).reassign(
            detail.lead.id,
            agentId: agentId,
            reason: whyCtrl.text.trim().isEmpty ? null : whyCtrl.text.trim(),
          );
      widget.onChanged();
      await _reload();
      messenger.showSnackBar(const SnackBar(
          content: Text('Lead reassigned.'),
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _logActivity() async {
    final detail = await _ensureDetail();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? type;
    final types = const [
      'Call', 'WhatsApp', 'Email', 'Site Visit', 'Meeting', 'Follow-up', 'Note', 'Other',
    ];
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final t in types)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => type = v,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Description', alignLabelWithHint: true),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                type = type ?? 'Note';
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Log')),
        ],
      ),
    );
    if (result != true) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(leadsRepositoryProvider).addActivity(
            detail.lead.id,
            type: type ?? 'Note',
            title: titleCtrl.text.trim(),
            description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          );
      await _reload();
      messenger.showSnackBar(const SnackBar(
          content: Text('Activity logged.'),
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _edit() async {
    final detail = await _ensureDetail();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => LeadFormSheet(
        initial: detail.lead,
        agents: detail.agents,
        onSaved: () {
          widget.onChanged();
          _reload();
        },
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showConfirm(
      context,
      title: 'Delete lead?',
      content:
          '${widget.initial.name} (${widget.initial.leadId}) will be removed.',
      confirmLabel: 'Delete',
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (!ok) return;
    try {
      await ref
          .read(leadsControllerProvider.notifier)
          .deleteLead(widget.initial.id);
      widget.onChanged();
      if (mounted) {
        Navigator.of(context).pop();
        showToast(context, 'Lead deleted.');
      }
    } catch (e) {
      if (mounted) showToast(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lead = widget.initial;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
              InitialsAvatar(name: lead.name, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lead.leadId,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: theme.colorScheme.primary)),
                    Text(lead.name,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              StatusPill(label: lead.status),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChip(
                  icon: Icons.phone, label: lead.phone,
                  onTap: () {}),
              if (lead.email != null && lead.email!.isNotEmpty)
                _ActionChip(
                    icon: Icons.mail_outline, label: lead.email!,
                    onTap: () {}),
              if (lead.budget != null && lead.budget!.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.currency_rupee, size: 16),
                  label: Text(lead.budget!),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.canEdit)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Nurture Status'),
                  onPressed: _changeStatus,
                ),
                ActionChip(
                  avatar: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Reassign'),
                  onPressed: _reassign,
                ),
                ActionChip(
                  avatar: const Icon(Icons.login, size: 16),
                  label: const Text('Convert to Deal'),
                  onPressed: _convertToDeal,
                ),
                ActionChip(
                  avatar: const Icon(Icons.event_note, size: 16),
                  label: const Text('Log Activity'),
                  onPressed: _logActivity,
                ),
                ActionChip(
                  avatar: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  onPressed: _edit,
                ),
              ],
            ),
          if (widget.canDelete)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error),
                ),
              ),
            ),
          const SizedBox(height: 4),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_detail != null) ...[
            SectionCard(
              title: 'Details',
              child: Column(
                children: [
                  for (final (k, v) in _detailRows())
                    Padding(
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
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SectionCard(
              title: 'Activities',
              child: _detail!.activities.isEmpty
                  ? const EmptyState(
                      icon: Icons.history,
                      message: 'No activities yet')
                  : Column(
                      children: [
                        for (final a in _detail!.activities)
                          _ActivityRow(activity: a),
                      ],
                    ),
            ),
            if (_detail!.handovers.isNotEmpty) ...[
              const SizedBox(height: 10),
              SectionCard(
                title: 'Handovers',
                child: Column(
                  children: [
                    for (final h in _detail!.handovers)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.swap_horiz, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${h['from_name']} → ${h['to_name']}'
                                '${h['created_at'] != null ? ' · ${h['created_at']}' : ''}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (_detail!.recommendations.isNotEmpty) ...[
              const SizedBox(height: 10),
              SectionCard(
                title: 'Recommended Properties',
                child: Column(
                  children: [
                    for (final r in _detail!.recommendations)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(r['title'] ?? '',
                                  style: theme.textTheme.bodySmall),
                            ),
                            Text(r['price_label'] ?? '',
                                style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  List<(String, String)> _detailRows() {
    final l = _detail!.lead;
    return [
      if (l.email != null && l.email!.isNotEmpty) ('Email', l.email!),
      ('Source', l.source),
      ('Score', '${l.score}'),
      if (l.preferredLocation != null && l.preferredLocation!.isNotEmpty)
        ('Location', l.preferredLocation!),
      if (l.requirements != null && l.requirements!.isNotEmpty)
        ('Requirements', l.requirements!),
      if (l.agentName != null) ('Agent', l.agentName!),
      if (l.propertyTitle != null) ('Interested Property', l.propertyTitle!),
      if (l.campaignName != null) ('Campaign', l.campaignName!),
      if (l.nextFollowup != null) ('Follow-up', l.nextFollowup!),
      if (l.createdBy != null) ('Added by', l.createdBy!),
      ('Created', Formatters.date(l.createdAt)),
    ];
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final LeadActivity activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(activity.createdAt,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${activity.title} · ${activity.type}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (activity.description != null &&
                    activity.description!.isNotEmpty)
                  Text(activity.description!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                if (activity.userName != 'System')
                  Text(activity.userName,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}