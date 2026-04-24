import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const _tabs = [
    (label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/admin/dashboard'),
    (label: 'Reportes', icon: Icons.assignment_outlined, route: '/admin/reports'),
    (label: 'Mapa', icon: Icons.map_outlined, route: '/admin/map'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex =
        _tabs.indexWhere((t) => t.route == location).clamp(0, _tabs.length - 1);
    final isWide = MediaQuery.of(context).size.width >= 720;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 240,
              child: NavigationDrawer(
                selectedIndex: currentIndex,
                onDestinationSelected: (i) => context.go(_tabs[i].route),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.forestGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.eco,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Master Ecology',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Text('Admin Panel',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ..._tabs.map(
                    (t) => NavigationDrawerDestination(
                      icon: Icon(t.icon),
                      label: Text(t.label),
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

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].route),
        destinations: _tabs
            .map((t) =>
                NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}
