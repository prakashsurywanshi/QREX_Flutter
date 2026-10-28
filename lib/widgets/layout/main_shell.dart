import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user.dart';
import '../../core/providers/auth_providers.dart';

/// A single navigable destination shown to role-eligible users.
class NavDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
  final String module; // permission module this maps to

  const NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
    required this.module,
  });
}

/// Builds the ordered list of destinations a user may access.
///
/// Mirrors the web AdminLayout: only modules where the user has `module.view`
/// permission are shown. Role-specific tweaks (e.g. hidden flags) are applied.
List<NavDestination> destinationsForUser(User user) {
  final can = user.can;
  final list = <NavDestination>[];

  void add({
    required String label,
    required IconData icon,
    required IconData selected,
    required String path,
    required String module,
  }) {
    // Only show if the user can view this module.
    if (!can.canView(module)) return;
    list.add(NavDestination(
      label: label,
      icon: icon,
      selectedIcon: selected,
      path: path,
      module: module,
    ));
  }

  add(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selected: Icons.dashboard,
    path: '/dashboard',
    module: 'dashboard',
  );
  add(
    label: 'Properties',
    icon: Icons.apartment_outlined,
    selected: Icons.apartment,
    path: '/properties',
    module: 'properties',
  );
  add(
    label: 'Leads',
    icon: Icons.people_alt_outlined,
    selected: Icons.people_alt,
    path: '/leads',
    module: 'leads',
  );
  add(
    label: 'Pipeline',
    icon: Icons.view_kanban_outlined,
    selected: Icons.view_kanban,
    path: '/pipeline',
    module: 'sales',
  );
  add(
    label: 'Customers',
    icon: Icons.contacts_outlined,
    selected: Icons.contacts,
    path: '/customers',
    module: 'customers',
  );
  add(
    label: 'Tasks',
    icon: Icons.checklist_outlined,
    selected: Icons.checklist,
    path: '/tasks',
    module: 'tasks',
  );
  add(
    label: 'Site Visits',
    icon: Icons.event_available,
    selected: Icons.event_available,
    path: '/site-visits',
    module: 'site_visits',
  );
  add(
    label: 'Bookings',
    icon: Icons.event_seat_outlined,
    selected: Icons.event_seat,
    path: '/bookings',
    module: 'bookings',
  );
  add(
    label: 'Payments',
    icon: Icons.payments_outlined,
    selected: Icons.payments,
    path: '/payments',
    module: 'payments',
  );
  add(
    label: 'Media',
    icon: Icons.photo_library_outlined,
    selected: Icons.photo_library,
    path: '/media',
    module: 'media',
  );
  add(
    label: 'Marketing',
    icon: Icons.campaign_outlined,
    selected: Icons.campaign,
    path: '/marketing',
    module: 'marketing',
  );
  add(
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
    selected: Icons.bar_chart,
    path: '/reports',
    module: 'reports',
  );
  add(
    label: 'CMS',
    icon: Icons.web_outlined,
    selected: Icons.web,
    path: '/cms',
    module: 'cms',
  );
  add(
    label: 'Users',
    icon: Icons.group_outlined,
    selected: Icons.group,
    path: '/users',
    module: 'users',
  );
  add(
    label: 'Roles',
    icon: Icons.admin_panel_settings_outlined,
    selected: Icons.admin_panel_settings,
    path: '/roles',
    module: 'roles',
  );
  add(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selected: Icons.settings,
    path: '/settings',
    module: 'settings',
  );

  return list;
}

/// Main shell: holds a responsive navigation shell (drawer on narrow,
/// permanent rail on wide) plus the content area. Navigation entries are
/// derived from the user's permissions.
class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  final String currentLocation;

  const MainShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final destinations = user == null ? <NavDestination>[] : destinationsForUser(user);

    // Determine selected index (best match by path prefix).
    int selectedIndex = 0;
    for (var i = 0; i < destinations.length; i++) {
      if (widget.currentLocation == destinations[i].path ||
          widget.currentLocation.startsWith('${destinations[i].path}/')) {
        selectedIndex = i;
      }
    }

    onSelect(int index) {
      final dest = destinations[index];
      if (dest.path != widget.currentLocation) {
        context.go(dest.path);
      }
    }

    final drawer = Drawer(
      child: SafeArea(
        child: user == null
            ? const SizedBox.shrink()
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerHeader(user: user),
                  const Divider(height: 1),
                  ...destinations.asMap().entries.map((e) {
                    final d = e.value;
                    final isSelected = e.key == selectedIndex;
                    return ListTile(
                      leading: Icon(
                        isSelected ? d.selectedIcon : d.icon,
                        color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      ),
                      title: Text(d.label),
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelect(e.key);
                      },
                    );
                  }),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            destinations.isEmpty ? 'QREX' : destinations[selectedIndex].label,
          ),
          leading: destinations.isNotEmpty
              ? Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                )
              : null,
          actions: [
            _NotificationBell(user: user),
            _ProfileAvatar(user: user),
            const SizedBox(width: 8),
          ],
        ),
        drawer: destinations.isNotEmpty ? drawer : null,
        body: widget.child,
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class _DrawerHeader extends StatelessWidget {
  final User user;
  const _DrawerHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return UserAccountsDrawerHeader(
      currentAccountPicture: CircleAvatar(
        child: Text(user.initials ?? '' , style: const TextStyle(fontSize: 20)),
      ),
      accountName: Text(user.name),
      accountEmail: Text(user.role),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  final User? user;
  const _NotificationBell({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = user?.unreadNotifications ?? 0;
    if (count == 0) {
      return IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => context.go('/notifications'),
      );
    }
    return IconButton(
      icon: Badge(
        label: Text('$count'),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () => context.go('/notifications'),
    );
  }
}

class _ProfileAvatar extends ConsumerWidget {
  final User? user;
  const _ProfileAvatar({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.go('/profile'),
      child: CircleAvatar(
        radius: 16,
        child: Text(user?.initials ?? '', style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
