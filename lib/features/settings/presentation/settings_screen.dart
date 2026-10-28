// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/settings.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/form_fields.dart';
import '../../../widgets/section_card.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _project = TextEditingController();
  final _agency = TextEditingController();
  final _tagline = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String _currency = 'INR (₹)';
  String _timezone = 'Asia/Kolkata';
  String _dateFormat = 'DD MMM YYYY';
  final _primary = TextEditingController();
  final _accent = TextEditingController();
  final Map<String, bool> _toggles = {};

  // SMTP
  final _smtpHost = TextEditingController();
  final _smtpPort = TextEditingController();
  final _smtpUser = TextEditingController();
  final _smtpPass = TextEditingController();
  final _smtpFromAddr = TextEditingController();
  final _smtpFromName = TextEditingController();
  final _smtpTest = TextEditingController();
  bool _smtpEnabled = false;
  String _smtpEncryption = 'tls';

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(settingsControllerProvider.notifier);
      if (ref.read(settingsControllerProvider).index.settings.values.isEmpty) {
        c.load();
      }
    });
  }

  void _hydrate(SettingsIndex index) {
    final s = index.settings;
    _project.text = s.projectName;
    _agency.text = s.agencyName;
    _tagline.text = s.tagline;
    _email.text = s.contactEmail;
    _phone.text = s.contactPhone;
    _address.text = s.address;
    _currency = s.currency.isEmpty ? 'INR (₹)' : s.currency;
    _timezone = s.timezone.isEmpty ? 'Asia/Kolkata' : s.timezone;
    _dateFormat = s.dateFormat.isEmpty ? 'DD MMM YYYY' : s.dateFormat;
    _primary.text = s.primaryColor;
    _accent.text = s.accentColor;
    _toggles['enable_contact_form'] = s.enableContactForm;
    _toggles['maintenance_mode'] = s.maintenanceMode;
    _toggles['two_factor'] = s.twoFactor;
    _toggles['lead_auto_assign'] = s.leadAutoAssign;
    _toggles['visit_reminders'] = s.visitReminders;
    _toggles['payment_alerts'] = s.paymentAlerts;
    _toggles['low_inventory_alert'] = s.lowInventoryAlert;

    final smtp = index.smtp;
    _smtpEnabled = smtp.enabled;
    _smtpHost.text = smtp.host;
    _smtpPort.text = smtp.port == 0 ? '' : '${smtp.port}';
    _smtpUser.text = smtp.username;
    _smtpPass.text = smtp.password;
    _smtpEncryption = smtp.encryption;
    _smtpFromAddr.text = smtp.fromAddress;
    _smtpFromName.text = smtp.fromName;
    _smtpTest.text = smtp.testEmail;
  }

  @override
  void dispose() {
    _project.dispose();
    _agency.dispose();
    _tagline.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _primary.dispose();
    _accent.dispose();
    _smtpHost.dispose();
    _smtpPort.dispose();
    _smtpUser.dispose();
    _smtpPass.dispose();
    _smtpFromAddr.dispose();
    _smtpFromName.dispose();
    _smtpTest.dispose();
    super.dispose();
  }

  void _toast(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    try {
      final controller = ref.read(settingsControllerProvider.notifier);
      final current = ref.read(settingsControllerProvider);
      _hydrate(current.index);
      final payload = <String, dynamic>{
        'project_name': _project.text.trim(),
        'agency_name': _agency.text.trim(),
        'tagline': _tagline.text.trim(),
        'contact_email': _email.text.trim(),
        'contact_phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'currency': _currency,
        'timezone': _timezone,
        'date_format': _dateFormat,
        'primary_color': _primary.text.trim(),
        'accent_color': _accent.text.trim(),
        ..._toggles.map((k, v) => MapEntry(k, v)),
      };
      await controller.save(payload);
      _toast('Settings saved.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveSmtp() async {
    try {
      await ref.read(settingsControllerProvider.notifier).saveSmtp({
        'enabled': _smtpEnabled,
        'host': _smtpHost.text.trim(),
        'port': int.tryParse(_smtpPort.text.trim()) ?? 587,
        'username': _smtpUser.text.trim(),
        'password': _smtpPass.text,
        'encryption': _smtpEncryption,
        'from_address': _smtpFromAddr.text.trim(),
        'from_name': _smtpFromName.text.trim(),
        'test_email': _smtpTest.text.trim(),
      });
      _toast('SMTP settings saved.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _testMail() async {
    final target = _smtpTest.text.trim();
    if (target.isEmpty) {
      _toast('Set a Test Email address first.', isError: true);
      return;
    }
    try {
      await ref.read(settingsControllerProvider.notifier).testMail(target);
      _toast('Test email sent successfully.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final isSuperAdmin = ref.watch(currentUserProvider)?.isSuperAdmin ?? false;

    if (state.loading && state.index.settings.values.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (state.error != null && state.index.settings.values.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: EmptyState(
          icon: Icons.cloud_off,
          message: state.error!,
          action:
              FilledButton(onPressed: controller.load, child: const Text('Retry')),
        ),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hydrated && !state.loading) {
        _hydrated = true;
        _hydrate(state.index);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _saving ? null : _saveAll,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_saving ? 'Saving…' : 'Save Changes'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            SectionCard(
              title: 'Appearance',
              child: _buildAppearanceSection(theme),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'General Information',
              child: Column(
                children: [
                  if (isSuperAdmin)
                    AppTextField(
                      label: 'Project Name',
                      controller: _project,
                      icon: Icons.apps,
                      hint: 'Only Super Admin can edit this',
                    ),
                  AppTextField(
                      label: 'Agency Name',
                      controller: _agency,
                      icon: Icons.business_outlined),
                  AppTextField(
                      label: 'Tagline',
                      controller: _tagline,
                      icon: Icons.format_quote),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                            label: 'Contact Email',
                            controller: _email,
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                            label: 'Contact Phone',
                            controller: _phone,
                            icon: Icons.phone_outlined),
                      ),
                    ],
                  ),
                  AppTextField(
                      label: 'Office Address',
                      controller: _address,
                      icon: Icons.location_on_outlined,
                      multiline: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Branding',
              child: Column(
                children: [
                  AppDropdownField<String>(
                    label: 'Currency',
                    value: _currency,
                    options: [
                      for (final c in [
                        'INR (₹)',
                        'USD (\$)',
                        'EUR (€)',
                        'AED',
                      ])
                        (c, c),
                    ],
                    onChanged: (v) =>
                        setState(() => _currency = v ?? 'INR (₹)'),
                  ),
                  AppDropdownField<String>(
                    label: 'Timezone',
                    value: _timezone,
                    options: [
                      for (final t in ['Asia/Kolkata', 'Asia/Dubai', 'UTC'])
                        (t, t),
                    ],
                    onChanged: (v) =>
                        setState(() => _timezone = v ?? 'Asia/Kolkata'),
                  ),
                  AppDropdownField<String>(
                    label: 'Date Format',
                    value: _dateFormat,
                    options: [
                      for (final d in [
                        'DD MMM YYYY',
                        'MM/DD/YYYY',
                        'DD/MM/YYYY',
                      ])
                        (d, d),
                    ],
                    onChanged: (v) =>
                        setState(() => _dateFormat = v ?? 'DD MMM YYYY'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                            label: 'Primary Color',
                            controller: _primary,
                            icon: Icons.color_lens_outlined),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                            label: 'Accent Color',
                            controller: _accent,
                            icon: Icons.format_paint_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Notifications',
              child: Column(
                children: [
                  _toggleTile(theme, 'Lead Auto-Assignment',
                      'Automatically assign new leads.', 'lead_auto_assign'),
                  _toggleTile(theme, 'Site Visit Reminders',
                      'Remind agents about upcoming visits.', 'visit_reminders'),
                  _toggleTile(theme, 'Payment Alerts',
                      'Alert on due and overdue payments.', 'payment_alerts'),
                  _toggleTile(theme, 'Low Inventory Alerts',
                      'Warn when property inventory is low.', 'low_inventory_alert'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Security',
              child: Column(
                children: [
                  _toggleTile(theme, 'Two-Factor Authentication',
                      'Require OTP for sign-in.', 'two_factor'),
                  _toggleTile(theme, 'Maintenance Mode',
                      'Temporarily disable the website.', 'maintenance_mode'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (isSuperAdmin) ...[
              _buildSmtpCard(theme),
              const SizedBox(height: 12),
              const Center(
                child: Text('SMTP settings are only visible to Super Admin.'),
              ),
            ] else
              Center(
                child: Text(
                  'SMTP configuration requires Super Admin.',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  bool _hydrated = false;

  Widget _buildAppearanceSection(ThemeData theme) {
    return RadioGroup<QrexTheme>(
      groupValue: ref.watch(qrexThemeProvider),
      onChanged: (v) {
        if (v != null) selectTheme(ref, v);
      },
      child: Column(
        children: QrexTheme.values.map((t) {
          final isSelected = ref.read(qrexThemeProvider) == t;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                t.icon,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            title: Text(t.label, style: theme.textTheme.bodyLarge),
            subtitle: Text(_themeDescription(t),
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            trailing: Radio<QrexTheme>(value: t),
            onTap: () => selectTheme(ref, t),
          );
        }).toList(),
      ),
    );
  }

  String _themeDescription(QrexTheme t) {
    switch (t) {
      case QrexTheme.light:
        return 'Clean white surfaces with navy and gold accents.';
      case QrexTheme.dark:
        return 'Premium black with elegant dark surfaces.';
      case QrexTheme.gray:
        return 'Soft gray surfaces for a muted, professional look.';
    }
  }

  Widget _toggleTile(ThemeData theme, String title, String subtitle, String key) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: theme.textTheme.bodyMedium),
      subtitle: Text(subtitle, style: theme.textTheme.labelSmall),
      value: _toggles[key] ?? false,
      onChanged: (v) => setState(() => _toggles[key] = v),
    );
  }

  Widget _buildSmtpCard(ThemeData theme) {
    return SectionCard(
      title: 'SMTP / Email Configuration',
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable SMTP'),
            value: _smtpEnabled,
            onChanged: (v) => setState(() => _smtpEnabled = v),
          ),
          AppTextField(
              label: 'Mail Host', controller: _smtpHost, icon: Icons.dns_outlined),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                    label: 'Port', controller: _smtpPort, icon: Icons.router),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppDropdownField<String>(
                  label: 'Encryption',
                  value: _smtpEncryption,
                  options: [
                    ('tls', 'TLS'),
                    ('ssl', 'SSL'),
                    ('', 'None'),
                  ],
                  onChanged: (v) =>
                      setState(() => _smtpEncryption = v ?? 'tls'),
                ),
              ),
            ],
          ),
          AppTextField(
              label: 'Username', controller: _smtpUser, icon: Icons.person_outline),
          AppTextField(
              label: 'Password',
              controller: _smtpPass,
              icon: Icons.lock_outline,
              obscureText: true),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                    label: 'From Address',
                    controller: _smtpFromAddr,
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTextField(
                    label: 'From Name', controller: _smtpFromName, icon: Icons.badge_outlined),
              ),
            ],
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _saveSmtp,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save SMTP Settings'),
          ),
          const Divider(height: 24),
          Text('Test Mail', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          AppTextField(
              label: 'Test Email Address',
              controller: _smtpTest,
              icon: Icons.send_outlined,
              keyboardType: TextInputType.emailAddress),
          FilledButton.tonalIcon(
            onPressed: _testMail,
            icon: const Icon(Icons.send_outlined, size: 18),
            label: const Text('Send Test Email'),
          ),
        ],
      ),
    );
  }
}