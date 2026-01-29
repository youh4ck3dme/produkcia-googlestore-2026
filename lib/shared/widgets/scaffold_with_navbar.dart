import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/biz_theme.dart';
import '../../features/ai_tools/screens/biz_bot_screen.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    // Breakpoints
    final isDesktop = width >= 1240;
    final isTablet = width >= 600 && width < 1240;
    final isMobile = width < 600;

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Faktúry',
      ),
      const NavigationDestination(
        icon: Icon(Icons.attach_money),
        selectedIcon: Icon(Icons.attach_money),
        label: 'Výdavky',
      ),
      const NavigationDestination(
        icon: Icon(Icons.auto_awesome_outlined),
        selectedIcon: Icon(Icons.auto_awesome),
        label: 'AI Tools',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Nastavenia',
      ),
    ];

    // Shared Destinations for Rail/Drawer need generic type mapping if strict, 
    // but here we manually map to RailDestination/DrawerDestination for simplicity.

    if (isMobile) {
      return Scaffold(
        body: navigationShell,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BizBotScreen()),
            );
          },
          backgroundColor: BizTheme.slovakBlue,
          child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          destinations: destinations,
          backgroundColor: theme.colorScheme.surface,
          elevation: 3,
          indicatorColor: theme.colorScheme.primaryContainer,
        ),
      );
    }
    
    return Scaffold(
      body: Row(
        children: [
          if (isTablet)
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              labelType: NavigationRailLabelType.all,
              backgroundColor: theme.colorScheme.surface,
              indicatorColor: theme.colorScheme.primaryContainer,
              destinations: destinations.map((d) => NavigationRailDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon,
                label: Text(d.label),
              )).toList(),
            ),
            
          if (isDesktop)
            NavigationDrawer(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              backgroundColor: theme.colorScheme.surface,
              indicatorColor: theme.colorScheme.primaryContainer,
              children: [
                 Padding(
                   padding: const EdgeInsets.all(BizTheme.spacingLg),
                   child: Text(
                     'BizAgent',
                     style: theme.textTheme.headlineSmall?.copyWith(
                       color: theme.colorScheme.primary, 
                       fontWeight: FontWeight.bold
                     ),
                   ),
                 ),
                 ...destinations.map((d) => NavigationDrawerDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                )),
              ],
            ),
            
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
