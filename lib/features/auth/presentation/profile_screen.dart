import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/models/user.dart';
import '../../../core/providers/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _savingProfile = false;
  String? _profileNotice;

  // Change password fields
  final _currentPwd = TextEditingController();
  final _newPwd = TextEditingController();
  final _confirmPwd = TextEditingController();
  bool _savingPassword = false;
  String? _pwdError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _currentPwd.dispose();
    _newPwd.dispose();
    _confirmPwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: SizedBox.shrink());
    _syncFields(user);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Header(user: user),
        const SizedBox(height: 24),
        _buildProfileCard(),
        const SizedBox(height: 16),
        _buildPasswordCard(),
        _buildMetadata(user),
      ],
    );
  }

  void _syncFields(User user) {
    if (_nameCtrl.text != user.name) _nameCtrl.text = user.name;
    if (_phoneCtrl.text != (user.phone ?? '')) _phoneCtrl.text = user.phone ?? '';
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            if (_profileNotice != null) ...[
              const SizedBox(height: 8),
              Text(_profileNotice!,
                  style: TextStyle(color: Colors.green.shade700)),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _savingProfile ? null : _saveProfile,
                child: _savingProfile
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change Password',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _currentPwd,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPwd,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password (min 6 chars)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPwd,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                border: OutlineInputBorder(),
              ),
            ),
            if (_pwdError != null) ...[
              const SizedBox(height: 8),
              Text(_pwdError!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: _savingPassword ? null : _savePassword,
                child: _savingPassword
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Update Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata(User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(user.email),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Role'),
            subtitle: Text(user.role),
          ),
          if (user.branch != null)
            ListTile(
              dense: true,
              leading: const Icon(Icons.store_outlined),
              title: const Text('Branch'),
              subtitle: Text(user.branch!),
            ),
          if (user.lastLoginAt != null)
            ListTile(
              dense: true,
              leading: const Icon(Icons.schedule),
              title: const Text('Last login'),
              subtitle: Text(user.lastLoginAt!),
            ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() {
      _savingProfile = true;
      _profileNotice = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim());
      // Refresh provider user
      await ref.read(authControllerProvider.notifier).refresh();
      setState(() => _profileNotice = 'Profile updated.');
    } on ApiException catch (e) {
      setState(() => _profileNotice = null);
      _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _savePassword() async {
    final newPwd = _newPwd.text;
    if (newPwd.length < 6) {
      setState(() => _pwdError = 'Password must be at least 6 characters.');
      return;
    }
    if (newPwd != _confirmPwd.text) {
      setState(() => _pwdError = 'Passwords do not match.');
      return;
    }
    setState(() {
      _savingPassword = true;
      _pwdError = null;
    });
    try {
      await ref.read(authRepositoryProvider).changePassword(
          currentPassword: _currentPwd.text, newPassword: newPwd);
      _currentPwd.clear();
      _newPwd.clear();
      _confirmPwd.clear();
      _showSnack('Password changed.');
    } on ApiException catch (e) {
      setState(() => _pwdError = e.message);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  final User user;
  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            user.initials ?? '',
            style: TextStyle(
              fontSize: 22,
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: theme.textTheme.titleLarge),
              Text(user.role, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
