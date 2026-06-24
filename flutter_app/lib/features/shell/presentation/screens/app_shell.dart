import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  const _NavItem(this.label, this.icon, this.activeIcon, this.route);
}

const _navItems = [
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

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _getSelectedIndex(currentRoute);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile: < 600
        if (constraints.maxWidth < 600) {
          return _MobileShell(
            selectedIndex: selectedIndex,
            child: child,
            onLogout: () => _logout(ref, context),
          );
        }
        // Tablet: 600-1100
        if (constraints.maxWidth < 1100) {
          return _TabletShell(
            selectedIndex: selectedIndex,
            child: child,
            onLogout: () => _logout(ref, context),
          );
        }
        // Desktop: >= 1100
        return _DesktopShell(
          selectedIndex: selectedIndex,
          child: child,
          onLogout: () => _logout(ref, context),
          userName: ref.watch(authStateProvider).valueOrNull?.name ?? '',
        );
      },
    );
  }

  static int _getSelectedIndex(String route) {
    for (int i = 0; i < _navItems.length; i++) {
      if (route.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }

  static void _navigate(BuildContext context, int index) {
    context.go(_navItems[index].route);
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

// ─── Mobile: Bottom Navigation ──────────────────────────────────────
class _MobileShell extends StatelessWidget {
  final int selectedIndex;
  final Widget child;
  final VoidCallback onLogout;

  const _MobileShell({required this.selectedIndex, required this.child, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    // Show only first 5 items in bottom nav, rest in drawer
    final bottomIndex = selectedIndex < 5 ? selectedIndex : 0;

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
                  children: _navItems.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    return ListTile(
                      leading: Icon(i == selectedIndex ? item.activeIcon : item.icon),
                      title: Text(item.label),
                      selected: i == selectedIndex,
                      onTap: () {
                        Navigator.pop(context);
                        AppShell._navigate(context, i);
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
        onDestinationSelected: (i) => AppShell._navigate(context, i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 65,
        destinations: _navItems.take(5).map((item) => NavigationDestination(
          icon: Icon(item.icon, size: 22),
          selectedIcon: Icon(item.activeIcon, size: 22),
          label: item.label,
        )).toList(),
      ),
    );
  }
}

// ─── Tablet: NavigationRail ─────────────────────────────────────────
class _TabletShell extends StatelessWidget {
  final int selectedIndex;
  final Widget child;
  final VoidCallback onLogout;

  const _TabletShell({required this.selectedIndex, required this.child, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => AppShell._navigate(context, i),
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
            destinations: _navItems.map((item) => NavigationRailDestination(
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

// ─── Desktop: Full Sidebar ──────────────────────────────────────────
class _DesktopShell extends StatelessWidget {
  final int selectedIndex;
  final Widget child;
  final VoidCallback onLogout;
  final String userName;

  const _DesktopShell({required this.selectedIndex, required this.child, required this.onLogout, required this.userName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Full sidebar
          Container(
            width: 240,
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                // Logo
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
                  child: Text('Inventory Management', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 8),
                // Nav items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: _navItems.asMap().entries.map((e) {
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
                            onTap: () => AppShell._navigate(context, i),
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
                // User & Logout
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          userName.isNotEmpty ? userName : 'User',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
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
