// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/role.dart';
import '../../../widgets/form_fields.dart';
import 'roles_controller.dart';

class RoleFormSheet extends ConsumerStatefulWidget {
  final RoleRecord? editing;
  final List<PermissionNode> permissionTree;
  final VoidCallback onSaved;

  const RoleFormSheet({
    super.key,
    this.editing,
    this.permissionTree = const [],
    required this.onSaved,
  });

  @override
  ConsumerState<RoleFormSheet> createState() => _RoleFormSheetState();
}

class _RoleFormSheetState extends ConsumerState<RoleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  late final Set<String> _selected;
  bool _saving = false;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _selected = {...?widget.editing?.permissionSlugs};
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Set<String> _slugsFor(String module, String action) {
    final node = widget.permissionTree
        .where((n) => n.module == module)
        .firstOrNull;
    if (node == null) return {};

    final fieldSlugs = <String>{};
    for (final fa in node.fields) {
      if (fa.action == action) {
        for (final f in fa.fields) {
          fieldSlugs.add(f.slug);
        }
      }
    }

    final actionNode = node.actions.where((a) => a.action == action).firstOrNull;
    final slugs = <String>{...fieldSlugs};
    final mainSlug = actionNode?.slug;
    if (mainSlug != null && mainSlug.isNotEmpty) {
      slugs.add(mainSlug);
    }
    return slugs;
  }

  void _toggle(String module, String action, bool value) {
    final slugs = _slugsFor(module, action);
    setState(() {
      if (value) {
        _selected.addAll(slugs);
      } else {
        _selected.removeAll(slugs);
        _selected.removeAll(
          _selected.where((s) => s.startsWith('$module.$action.')),
        );
      }
    });
  }

  bool _isSelected(String module, String action) {
    final slugs = _slugsFor(module, action);
    if (slugs.isEmpty) return false;
    return slugs.any(_selected.contains);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final payload = {
        'name': _name.text.trim(),
        if (_description.text.trim().isNotEmpty)
          'description': _description.text.trim(),
        'permissions': _selected.toList(),
      };
      if (_isEdit) {
        await ref
            .read(rolesControllerProvider.notifier)
            .update(widget.editing!.id, payload);
      } else {
        await ref.read(rolesControllerProvider.notifier).create(payload);
      }
      widget.onSaved();
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Role updated.' : 'Role created.'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = ['view', 'create', 'edit', 'delete', 'export', 'approve'];
    final totalPerms = widget.permissionTree.fold<int>(
        0,
        (a, n) =>
            a +
            n.actions.length +
            n.fields.fold<int>(0, (b, fa) => b + fa.fields.length));

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Form(
        key: _formKey,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Text(_isEdit ? 'Edit Role' : 'Create Role',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Role Name *',
              controller: _name,
              icon: Icons.shield_outlined,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Name is required'
                  : null,
            ),
            AppTextField(
              label: 'Description',
              controller: _description,
              icon: Icons.notes,
              multiline: true,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_selected.length} of $totalPerms permissions selected',
                    style: theme.textTheme.labelMedium),
                TextButton(
                  onPressed: () => setState(() {
                    if (_selected.length == totalPerms) {
                      _selected.clear();
                    } else {
                      _selected.clear();
                      for (final n in widget.permissionTree) {
                        for (final a in n.actions) {
                          _selected.addAll(_slugsFor(n.module, a.action));
                        }
                        for (final fa in n.fields) {
                          for (final f in fa.fields) {
                            _selected.add(f.slug);
                          }
                        }
                      }
                    }
                  }),
                  child: Text(_selected.length == totalPerms
                      ? 'Clear All'
                      : 'Select All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final node in widget.permissionTree)
              Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(node.label,
                          style: theme.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          for (final a in actions)
                            Expanded(
                              child: Column(
                                children: [
                                  Checkbox(
                                    value:
                                        _isSelected(node.module, a),
                                    onChanged: (v) =>
                                        _toggle(node.module, a, v ?? false),
                                  ),
                                  Text(a,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(fontSize: 9)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Update Role' : 'Create Role'),
            ),
          ],
        ),
      ),
    );
  }
}