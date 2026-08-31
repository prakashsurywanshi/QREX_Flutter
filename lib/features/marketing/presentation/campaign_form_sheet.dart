import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/form_fields.dart';
import 'marketing_controller.dart';

class CampaignFormSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;

  const CampaignFormSheet({super.key, required this.onSaved});

  @override
  ConsumerState<CampaignFormSheet> createState() => _CampaignFormSheetState();
}

class _CampaignFormSheetState extends ConsumerState<CampaignFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _budget = TextEditingController();
  String? _channel = campaignChannels.first;
  String? _status = 'Scheduled';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      await ref.read(marketingControllerProvider.notifier).createCampaign({
        'name': _name.text.trim(),
        'channel': _channel,
        'budget': num.tryParse(_budget.text.trim())?.toDouble() ?? 0,
        'status': _status,
      });
      widget.onSaved();
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Campaign created.'),
          behavior: SnackBarBehavior.floating,
        ));
      if (mounted) navigator.pop();
    } catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Form(
        key: _formKey,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Text('New Campaign',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Campaign Name *',
              controller: _name,
              icon: Icons.campaign_outlined,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Name is required'
                  : null,
            ),
            AppTextField(
              label: 'Budget (₹)',
              controller: _budget,
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
            ),
            AppDropdownField<String>(
              label: 'Channel',
              value: _channel,
              options: [for (final c in campaignChannels) (c, c)],
              onChanged: (v) => setState(() => _channel = v),
            ),
            AppDropdownField<String>(
              label: 'Status',
              value: _status,
              options: [for (final s in campaignStatuses) (s, s)],
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Campaign'),
            ),
          ],
        ),
      ),
    );
  }
}