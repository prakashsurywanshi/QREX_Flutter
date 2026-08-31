import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/customer.dart';
import '../../../core/notifiers/paged_state.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/filter_sheet.dart';
import '../../../widgets/initials_avatar.dart';
import '../../../widgets/pagination_bar.dart';
import '../../../widgets/status_pill.dart';
import 'customer_detail_sheet.dart';
import 'customer_form_sheet.dart';
import 'customers_controller.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(customersControllerProvider.notifier);
      if (ref.read(customersControllerProvider).items.isEmpty) c.load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(customersControllerProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersControllerProvider);
    final controller = ref.read(customersControllerProvider.notifier);
    final can = ref.watch(currentUserProvider)?.can;
    final canCreate = can?.canCreate('customers') == true;
    final canEdit = can?.canEdit('customers') == true;
    final canDelete = can?.canDelete('customers') == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          if (state.total > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('${state.total}',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Customer'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search name, email, phone…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          controller.search('');
                        },
                      ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: 'Status: ${state.filters['status'] ?? 'All'}',
                  onTap: () async {
                    final opts = [
                      for (final s in ['All', ...controller.statuses]) (s, s),
                    ];
                    final v = await showFilterSheet(context,
                        title: 'Filter by Status',
                        options: opts,
                        current: state.filters['status'] ?? 'All');
                    if (v != null) controller.setFilter('status', v);
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _buildList(context, state, controller, canEdit, canDelete)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, PagedState<Customer> state,
      CustomersController controller, bool canEdit, bool canDelete) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        message: state.error!,
        action: FilledButton(
            onPressed: controller.refresh, child: const Text('Retry')),
      );
    }
    if (state.items.isEmpty) {
      return const EmptyState(
        icon: Icons.group_outlined,
        message: 'No customers found',
        hint: 'Adjust filters or add your first customer.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async { controller.refresh(); },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
        itemCount: state.items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          if (i == state.items.length) {
            return PaginationBar(
              currentPage: state.currentPage,
              lastPage: state.lastPage,
              total: state.total,
              onPage: (p) { controller.loadPage(p); },
            );
          }
          final c = state.items[i];
          return _CustomerTile(
            customer: c,
            onTap: () => _openDetail(context, c, canEdit, canDelete),
          );
        },
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, Customer c,
      bool canEdit, bool canDelete) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CustomerDetailSheet(
        initial: c,
        canEdit: canEdit,
        canDelete: canDelete,
        onChanged: () =>
            ref.read(customersControllerProvider.notifier).refresh(),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CustomerFormSheet(
        onSaved: () =>
            ref.read(customersControllerProvider.notifier).refresh(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.filter_list, size: 16),
      onPressed: onTap,
      labelStyle: Theme.of(context).textTheme.labelMedium,
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  const _CustomerTile({required this.customer, required this.onTap});

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
              InitialsAvatar(name: customer.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        StatusPill(label: customer.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        customer.phone,
                        if (customer.email != null) customer.email!,
                        if (customer.city != null) customer.city!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (customer.type != null) 'Type: ${customer.type!}',
                        if (customer.agentName != null)
                          'Agent: ${customer.agentName!}',
                      ].join(' · '),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}