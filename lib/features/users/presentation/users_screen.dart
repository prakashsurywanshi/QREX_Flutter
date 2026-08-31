// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/admin_user.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/initials_avatar.dart';
import '../../../widgets/status_pill.dart';
import 'user_form_sheet.dart';
import 'users_controller.dart';

const userBranches = ['HQ Mumbai', 'Mumbai', 'Bangalore', 'Gurugram'];

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(usersControllerProvider.notifier);
      if (ref.read(usersControllerProvider).users.isEmpty) c.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersControllerProvider);
    final controller = ref.read(usersControllerProvider.notifier);
    final can = ref.watch(currentUserProvider)?.can;
    final canCreate = can?.canCreate('users') == true;
    final canEdit = can?.canEdit('users') == true;
    final canDelete = can?.canDelete('users') == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users & Roles'),
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
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Invite User'),
            )
          : null,
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final r in ['All', ...state.roles.map((e) => e.name)])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(r),
                      selected: state.roleFilter == r,
                      onSelected: (_) => controller.filterRole(r),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _buildList(context, state, controller, canEdit, canDelete),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, UsersState state,
      UsersController controller, bool canEdit, bool canDelete) {
    if (state.loading && state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.users.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        message: state.error!,
        action:
            FilledButton(onPressed: controller.load, child: const Text('Retry')),
      );
    }
    if (state.filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.group_outlined,
        message: 'No users found',
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
        itemCount: state.filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final u = state.filtered[i];
          return _UserTile(
            user: u,
            onTap: canEdit || canDelete
                ? () => _openForm(context, u, canEdit, canDelete)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context,
      [UserRecord? editing, bool canEdit = false, bool canDelete = false]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => UserFormSheet(
        editing: editing,
        roles: ref.read(usersControllerProvider).roles,
        canEdit: canEdit,
        canDelete: canDelete,
        onSaved: () => ref.read(usersControllerProvider.notifier).load(),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserRecord user;
  final VoidCallback? onTap;
  const _UserTile({required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              InitialsAvatar(name: user.name, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text('${user.email} · ${user.userId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(user.role,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: theme.colorScheme.primary)),
                        ),
                        Text(user.branch,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusPill(label: user.status),
                  const SizedBox(height: 4),
                  Text(
                    user.lastLogin == null
                        ? '—'
                        : user.lastLogin!.isEmpty
                            ? '—'
                            : 'Last login ${user.lastLogin}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}