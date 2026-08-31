// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/role.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../widgets/empty_state.dart';
import 'role_form_sheet.dart';
import 'roles_controller.dart';

class RolesScreen extends ConsumerStatefulWidget {
  const RolesScreen({super.key});

  @override
  ConsumerState<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends ConsumerState<RolesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(rolesControllerProvider.notifier);
      if (ref.read(rolesControllerProvider).roles.isEmpty) c.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rolesControllerProvider);
    final controller = ref.read(rolesControllerProvider.notifier);
    final can = ref.watch(currentUserProvider)?.can;
    final canCreate = can?.canCreate('roles') == true;
    final canEdit = can?.canEdit('roles') == true;
    final canDelete = can?.canDelete('roles') == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles & Permissions'),
        actions: [
          IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: controller.load),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Role'),
            )
          : null,
      body: state.loading && state.roles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.roles.isEmpty
              ? EmptyState(
                  icon: Icons.cloud_off,
                  message: state.error!,
                  action: FilledButton(
                      onPressed: controller.load, child: const Text('Retry')),
                )
              : RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                    itemCount: state.roles.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      if (i == 0) {
                        return _helpCard(context);
                      }
                      final r = state.roles[i - 1];
                      return _RoleTile(
                        role: r,
                        onEdit: canEdit && !r.isSystem
                            ? () => _openForm(context, r)
                            : null,
                        onDelete: canDelete && !r.isSystem
                            ? () => _confirmDelete(r)
                            : null,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _helpCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.admin_panel_settings_outlined,
                color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Control access with module-level (view/create/edit/delete) and action-level (export, approve) permissions. Super Admin and Admin are system roles and cannot be modified.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, [RoleRecord? editing]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => RoleFormSheet(
        editing: editing,
        permissionTree: ref.read(rolesControllerProvider).permissionTree,
        onSaved: () => ref.read(rolesControllerProvider.notifier).load(),
      ),
    );
  }

  Future<void> _confirmDelete(RoleRecord r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Role?'),
        content: Text('Delete role "${r.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(rolesControllerProvider.notifier).delete(r.id);
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Role deleted.'),
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
}

class _RoleTile extends StatelessWidget {
  final RoleRecord role;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _RoleTile({required this.role, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.shield_outlined,
                color: theme.colorScheme.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(role.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      if (role.isSystem) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.lock,
                            size: 14,
                            color: Colors.amber.shade700),
                      ],
                    ],
                  ),
                  Text(role.slug,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.outline)),
                  Text(role.description ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${role.permissionCount} perms · ${role.userCount} users',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (onEdit != null)
                      IconButton(
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: onEdit),
                    if (onDelete != null)
                      IconButton(
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          icon: Icon(Icons.delete_outline,
                              color: theme.colorScheme.error),
                          onPressed: onDelete),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}