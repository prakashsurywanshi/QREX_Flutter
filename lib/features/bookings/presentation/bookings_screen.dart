import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/booking.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_pill.dart';
import 'booking_detail_sheet.dart';
import 'booking_form_sheet.dart';
import 'bookings_controller.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(bookingsControllerProvider.notifier);
      if (ref.read(bookingsControllerProvider).bookings.isEmpty) c.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingsControllerProvider);
    final controller = ref.read(bookingsControllerProvider.notifier);
    final can = ref.watch(currentUserProvider)?.can;
    final canCreate = can?.canCreate('bookings') == true;
    final canEdit = can?.canEdit('bookings') == true;
    final canDelete = can?.canDelete('bookings') == true;

    final summary = BookingSummary.fromList(state.bookings);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
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
              icon: const Icon(Icons.event_seat),
              label: const Text('New Booking'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                _Stat(
                    label: 'Total Bookings',
                    value: '${summary.total}',
                    icon: Icons.event_seat),
                _Stat(
                    label: 'Agreements Signed',
                    value: '${summary.agreementsSigned}',
                    icon: Icons.description),
                _Stat(
                    label: 'Possession Handed Over',
                    value: '${summary.possessionHandedOver}',
                    icon: Icons.key),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final s in ['All', ...bookingStatuses])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: _statusFilter == s,
                      onSelected: (_) =>
                          setState(() => _statusFilter = s),
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

  Widget _buildList(BuildContext context, BookingsState state,
      BookingsController controller, bool canEdit, bool canDelete) {
    if (state.loading && state.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.bookings.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        message: state.error!,
        action: FilledButton(
            onPressed: controller.load, child: const Text('Retry')),
      );
    }
    final list = state.filtered;
    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.event_seat,
        message: 'No bookings',
        hint: 'Create your first booking.',
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final b = list[i];
          return _BookingTile(
            booking: b,
            onTap: canEdit || canDelete
                ? () => _openDetail(context, b, canEdit, canDelete)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, Booking b, bool canEdit,
      bool canDelete) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => BookingDetailSheet(
        initial: b,
        canEdit: canEdit,
        canDelete: canDelete,
        onChanged: () => ref.read(bookingsControllerProvider.notifier).load(),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => BookingFormSheet(
        onSaved: () => ref.read(bookingsControllerProvider.notifier).load(),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Stat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: theme.textTheme.titleMedium),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  const _BookingTile({required this.booking, this.onTap});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  StatusPill(label: booking.status),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${booking.bookingId} · ${booking.propertyName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Deal ${booking.dealLabel ?? Formatters.inrLabel(booking.dealValue)}',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                  Text(
                    '${Formatters.date(booking.bookingDate)}'
                    '${booking.agentName.isNotEmpty ? ' · ${booking.agentName}' : ''}',
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