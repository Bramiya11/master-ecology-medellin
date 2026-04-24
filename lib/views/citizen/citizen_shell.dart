import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class CitizenShell extends StatelessWidget {
  final Widget child;
  const CitizenShell({super.key, required this.child});

  static const _tabs = [
    (label: 'Mapa', icon: Icons.map_outlined, route: '/citizen/map'),
    (label: 'Reportar', icon: Icons.add_location_alt, route: '/citizen/report'),
    (label: 'Mi Perfil', icon: Icons.person_outline, route: '/citizen/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex =
        _tabs.indexWhere((t) => t.route == location).clamp(0, _tabs.length - 1);
    final isWide = MediaQuery.of(context).size.width >= 720;

    if (isWide) {
      return _DesktopScaffold(
        currentIndex: currentIndex,
        tabs: _tabs,
        child: child,
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].route),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DesktopScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final List<({String label, IconData icon, String route})> tabs;

  const _DesktopScaffold({
    required this.child,
    required this.currentIndex,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: (i) => context.go(tabs[i].route),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 24),
              ),
            ),
            destinations: tabs
                .map(
                  (t) => NavigationRailDestination(
                    icon: Icon(t.icon),
                    label: Text(t.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
