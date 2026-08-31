// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/admin_user.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../widgets/feedback.dart';
import '../../../widgets/form_fields.dart';
import 'users_controller.dart';
import 'users_screen.dart';

class UserFormSheet extends ConsumerStatefulWidget {
  final UserRecord? editing;
  final List<RoleSummary> roles;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onSaved;

  const UserFormSheet({
    super.key,
    this.editing,
    this.roles = const [],
    this.canEdit = true,
    this.canDelete = false,
    required this.onSaved,
  });

  @override
  ConsumerState<UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends ConsumerState<UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  int? _roleId;
  String _branch = 'HQ Mumbai';
  String _status = 'Active';
  bool _saving = false;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _name.text = e.name;
      _email.text = e.email;
      _phone.text = e.phone ?? '';
      _roleId = e.roleId;
      _branch = e.branch.isEmpty ? 'HQ Mumbai' : e.branch;
      _status = e.status.isEmpty ? 'Active' : e.status;
    } else if (widget.roles.isNotEmpty) {
      _roleId = widget.roles.first.id;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
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

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_roleId == null) {
      _toast('Select a role.', isError: true);
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      if (_isEdit) {
        final payload = <String, dynamic>{
          if (_name.text.trim().isNotEmpty) 'name': _name.text.trim(),
          if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
          'role_id': _roleId,
          'branch': _branch,
          'status': _status,
          if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
          if (_password.text.trim().isNotEmpty)
            'password': _password.text.trim(),
        };
        await ref
            .read(usersControllerProvider.notifier)
            .update(widget.editing!.id, payload);
      } else {
        if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) {
          _toast('Name and email are required.', isError: true);
          return;
        }
        await ref.read(usersControllerProvider.notifier).invite({
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          'role_id': _roleId,
          'branch': _branch,
        });
      }
      widget.onSaved();
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(_isEdit
              ? 'User updated.'
              : 'User invited. They will receive an email to set their password.'),
          behavior: SnackBarBehavior.floating,
        ));
      if (mounted) navigator.pop();
    } catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirm(context,
        title: 'Delete User?',
        content:
            'Delete ${widget.editing!.name}? This cannot be undone.',
        confirmLabel: 'Delete');
    if (ok != true) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(usersControllerProvider.notifier)
          .delete(widget.editing!.id);
      widget.onSaved();
      if (mounted) navigator.pop();
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('User deleted.'),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSuperAdmin = ref.watch(currentUserProvider)?.isSuperAdmin ?? false;
    final roles = widget.roles.where((r) =>
        isSuperAdmin || r.slug != 'super-admin');
    final isSystemRole = widget.editing?.role == 'Admin' ||
        widget.editing?.role == 'Super Admin';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Form(
        key: _formKey,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Text(_isEdit ? 'Edit User' : 'Invite Team Member',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Full Name *',
              controller: _name,
              icon: Icons.person_outline,
              validator: (v) => !_isEdit && (v == null || v.trim().isEmpty)
                  ? 'Name is required'
                  : null,
            ),
            AppTextField(
              label: 'Email *',
              controller: _email,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => !_isEdit && (v == null || v.trim().isEmpty)
                  ? 'Email is required'
                  : null,
            ),
            AppTextField(
              label: 'Phone',
              controller: _phone,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            AppDropdownField<int>(
              label: 'Role',
              value: _roleId,
              options: [for (final r in roles) (r.id, r.name)],
              onChanged: (v) => setState(() => _roleId = v),
            ),
            AppDropdownField<String>(
              label: 'Branch',
              value: _branch,
              options: [for (final b in userBranches) (b, b)],
              onChanged: (v) => setState(() => _branch = v ?? 'HQ Mumbai'),
            ),
            if (_isEdit) ...[
              AppDropdownField<String>(
                label: 'Status',
                value: _status,
                options: [
                  for (final s in ['Active', 'Inactive', 'Pending', 'Suspended'])
                    (s, s),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'Active'),
              ),
              AppTextField(
                label: 'New Password (optional)',
                controller: _password,
                icon: Icons.lock_outline,
                obscureText: true,
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Save Changes' : 'Invite User'),
            ),
            if (_isEdit && widget.canDelete && !isSystemRole) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _delete,
                style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete User'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}