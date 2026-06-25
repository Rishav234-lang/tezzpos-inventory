import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  const _NavItem(this.label, this.icon, this.activeIcon, this.route);
}

const _ownerNavItems = [
  _NavItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard, '/dashboard'),
  _NavItem('Products', Icons.shopping_bag_outlined, Icons.shopping_bag, '/products'),
  _NavItem('Vendors', Icons.people_outlined, Icons.people, '/vendors'),
  _NavItem('Purchases', Icons.receipt_long_outlined, Icons.receipt_long, '/purchases'),
  _NavItem('Customers', Icons.person_outlined, Icons.person, '/customers'),
  _NavItem('Sales', Icons.point_of_sale_outlined, Icons.point_of_sale, '/sales'),
  _NavItem('Inventory', Icons.inventory_outlined, Icons.inventory_2, '/inventory'),
  _NavItem('Payments', Icons.payment_outlined, Icons.payment, '/payments'),
  _NavItem('Reports', Icons.bar_chart_outlined, Icons.bar_chart, '/reports'),
  _NavItem('Settings', Icons.settings_outlined, Icons.settings, '/settings'),
];

const _superAdminNavItems = [
  _NavItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard, '/super-admin/dashboard'),
  _NavItem('Companies', Icons.business_outlined, Icons.business, '/super-admin/companies'),
  _NavItem('Plans', Icons.workspace_premium_outlined, Icons.workspace_premium, '/super-admin/plans'),
  _NavItem('Settings', Icons.settings_outlined, Icons.settings, '/settings'),
];

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final isSuperAdmin = authUser?.role == 'super_admin';
    final navItems = isSuperAdmin ? _superAdminNavItems : _ownerNavItems;
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _getSelectedIndex(currentRoute, navItems);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _MobileShell(
            selectedIndex: selectedIndex,
            navItems: navItems,
            child: child,
            onLogout: () => _logout(ref, context),
            isSuperAdmin: isSuperAdmin,
          );
        }
        if (constraints.maxWidth < 1100) {
          return _TabletShell(
            selectedIndex: selectedIndex,
            navItems: navItems,
            child: child,
            onLogout: () => _logout(ref, context),
          );
        }
        return _DesktopShell(
          selectedIndex: selectedIndex,
          navItems: navItems,
          child: child,
          onLogout: () => _logout(ref, context),
          userName: authUser?.name ?? '',
          userRole: isSuperAdmin ? 'Super Admin' : 'Owner',
          isSuperAdmin: isSuperAdmin,
        );
      },
    );
  }

  static int _getSelectedIndex(String route, List<_NavItem> navItems) {
    for (int i = 0; i < navItems.length; i++) {
      if (route.startsWith(navItems[i].route)) return i;
    }
    return 0;
  }

  static void _navigate(BuildContext context, int index, List<_NavItem> navItems) {
    context.go(navItems[index].route);
  }

  static Future<void> _logout(WidgetRef ref, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }
}

class _MobileShell extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> navItems;
  final Widget child;
  final VoidCallback onLogout;
  final bool isSuperAdmin;

  const _MobileShell({required this.selectedIndex, required this.navItems, required this.child, required this.onLogout, required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    final bottomItems = navItems.take(isSuperAdmin ? 3 : 5).toList();
    final bottomIndex = selectedIndex < bottomItems.length ? selectedIndex : 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icons/app_icon.png', height: 28),
            const SizedBox(width: 8),
            const Text('TezzPOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          if (isSuperAdmin)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Super Admin', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          IconButton(icon: const Icon(Icons.logout_outlined), onPressed: onLogout),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Image.asset('assets/icons/app_logo.png', height: 40),
                    const SizedBox(width: 12),
                    Text('TezzPOS', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: navItems.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    return ListTile(
                      leading: Icon(i == selectedIndex ? item.activeIcon : item.icon),
                      title: Text(item.label),
                      selected: i == selectedIndex,
                      onTap: () {
                        Navigator.pop(context);
                        AppShell._navigate(context, i, navItems);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: bottomIndex,
        onDestinationSelected: (i) => AppShell._navigate(context, i, navItems),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 65,
        destinations: bottomItems.map((item) => NavigationDestination(
          icon: Icon(item.icon, size: 22),
          selectedIcon: Icon(item.activeIcon, size: 22),
          label: item.label,
        )).toList(),
      ),
    );
  }
}

class _TabletShell extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> navItems;
  final Widget child;
  final VoidCallback onLogout;

  const _TabletShell({required this.selectedIndex, required this.navItems, required this.child, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => AppShell._navigate(context, i, navItems),
            labelType: NavigationRailLabelType.selected,
            backgroundColor: Theme.of(context).colorScheme.surface,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Image.asset('assets/icons/app_icon.png', height: 36),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: IconButton(
                    icon: const Icon(Icons.logout_outlined),
                    tooltip: 'Logout',
                    onPressed: onLogout,
                  ),
                ),
              ),
            ),
            destinations: navItems.map((item) => NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: Text(item.label, style: const TextStyle(fontSize: 11)),
            )).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> navItems;
  final Widget child;
  final VoidCallback onLogout;
  final String userName;
  final String userRole;
  final bool isSuperAdmin;

  const _DesktopShell({required this.selectedIndex, required this.navItems, required this.child, required this.onLogout, required this.userName, required this.userRole, required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 240,
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    children: [
                      Image.asset('assets/icons/app_icon.png', height: 32),
                      const SizedBox(width: 10),
                      Text('TezzPOS', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        isSuperAdmin ? 'Super Admin Panel' : 'Inventory Management',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      if (isSuperAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('SA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: navItems.asMap().entries.map((e) {
                      final i = e.key;
                      final item = e.value;
                      final isSelected = i == selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Material(
                          color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => AppShell._navigate(context, i, navItems),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    size: 20,
                                    color: isSelected ? theme.colorScheme.primary : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? theme.colorScheme.primary : Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isSuperAdmin
                            ? AppColors.primary.withOpacity(0.15)
                            : theme.colorScheme.primary.withOpacity(0.15),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName.isNotEmpty ? userName : 'User',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(userRole, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_outlined, size: 20),
                        tooltip: 'Logout',
                        onPressed: onLogout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
