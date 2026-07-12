import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/play_release_scope.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/l10n.dart';
import '../../core/ui/biz_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../core/router/app_router.dart';
import '../../core/debug/perf_probe.dart';

enum _FabMode { bizbot, icoatlas }

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  StreamSubscription<List<SharedMediaFile>>? _shareIntentSub;
  Timer? _fabToggleTimer;
  _FabMode _fabMode = _FabMode.bizbot;

  /// Play MVP: shell má 5 vetiev, AI (index 3) nie je v bottom nav.
  static const int _aiToolsShellIndex = 3;
  static const int _settingsShellIndex = 4;

  int _shellIndexForNav(int navIndex) {
    if (!PlayReleaseScope.showAssistantNav && navIndex >= 3) {
      return _settingsShellIndex;
    }
    return navIndex;
  }

  int _navIndexFromShell(int shellIndex) {
    if (!PlayReleaseScope.showAssistantNav) {
      if (shellIndex == _settingsShellIndex) return 3;
      if (shellIndex == _aiToolsShellIndex) return 0;
      return shellIndex;
    }
    return shellIndex;
  }

  void _startFabToggleTimer() {
    _fabToggleTimer?.cancel();
    _fabToggleTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      // #region agent log
      perfProbe('E', 'scaffold_with_navbar.dart', 'fab_timer_setstate');
      // #endregion
      setState(() {
        _fabMode = _fabMode == _FabMode.bizbot ? _FabMode.icoatlas : _FabMode.bizbot;
      });
    });
  }

  void _goBranch(int navIndex) {
    final shellIndex = _shellIndexForNav(navIndex);
    widget.navigationShell.goBranch(
      shellIndex,
      initialLocation: shellIndex == widget.navigationShell.currentIndex,
    );
  }

  List<NavigationDestination> _destinations(BuildContext context) {
    return [
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: context.t(AppStr.navDashboard),
      ),
      NavigationDestination(
        icon: const Icon(Icons.receipt_long_outlined),
        selectedIcon: const Icon(Icons.receipt_long),
        label: context.t(AppStr.navInvoices),
      ),
      NavigationDestination(
        icon: const Icon(Icons.attach_money),
        selectedIcon: const Icon(Icons.attach_money),
        label: context.t(AppStr.navExpenses),
      ),
      if (PlayReleaseScope.showAssistantNav)
        PlayReleaseScope.showAiToolsNav
            ? NavigationDestination(
                icon: const Icon(Icons.auto_awesome_outlined),
                selectedIcon: const Icon(Icons.auto_awesome),
                label: context.t(AppStr.navAiTools),
              )
            : NavigationDestination(
                icon: const Icon(Icons.smart_toy_outlined),
                selectedIcon: const Icon(Icons.smart_toy),
                label: context.t(AppStr.navAssistant),
              ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: context.t(AppStr.navSettings),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final width = MediaQuery.of(context).size.width;
      final isMobile = width < 600;
      if (isMobile && PlayReleaseScope.showMobilePromoFab) {
        _startFabToggleTimer();
      }
    });

    if (!kIsWeb) {
      ReceiveSharingIntent.instance.getInitialMedia().then((list) {
        if (!mounted || list.isEmpty) return;
        final path = list.first.path.trim();
        if (path.isEmpty) return;
        ref.read(routerProvider).go('/create-expense', extra: {'sharedImagePath': path});
        ReceiveSharingIntent.instance.reset();
      });

      _shareIntentSub = ReceiveSharingIntent.instance.getMediaStream().listen((list) {
        if (!mounted || list.isEmpty) return;
        final path = list.first.path.trim();
        if (path.isEmpty) return;
        ref.read(routerProvider).go('/create-expense', extra: {'sharedImagePath': path});
        ReceiveSharingIntent.instance.reset();
      });
    }
  }

  @override
  void dispose() {
    _shareIntentSub?.cancel();
    _fabToggleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // #region agent log
    perfProbe('E', 'scaffold_with_navbar.dart:build', 'shell_rebuild');
    // #endregion

    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    final isDesktop = width >= 1240;
    final isTablet = width >= 600 && width < 1240;
    final isMobile = width < 600;

    final destinations = _destinations(context);
    final selectedNavIndex = _navIndexFromShell(widget.navigationShell.currentIndex);

    if (isMobile) {
      return Scaffold(
        body: widget.navigationShell,
        floatingActionButton: PlayReleaseScope.showMobilePromoFab
            ? FloatingActionButton(
                onPressed: () {
                  final router = ref.read(routerProvider);
                  switch (_fabMode) {
                    case _FabMode.bizbot:
                      router.push('/ai-tools/biz-bot');
                      break;
                    case _FabMode.icoatlas:
                      router.push('/icoatlas');
                      break;
                  }
                },
                backgroundColor: BizTheme.slovakBlue,
                child: _fabMode == _FabMode.bizbot
                    ? const Icon(Icons.smart_toy_outlined, color: Colors.white)
                    : Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/icons/icoatlas-logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedNavIndex,
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
              selectedIndex: selectedNavIndex,
              onDestinationSelected: _goBranch,
              labelType: NavigationRailLabelType.all,
              backgroundColor: theme.colorScheme.surface,
              indicatorColor: theme.colorScheme.primaryContainer,
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
          if (isDesktop)
            NavigationDrawer(
              selectedIndex: selectedNavIndex,
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...destinations.map(
                  (d) => NavigationDrawerDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: Text(d.label),
                  ),
                ),
              ],
            ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }
}
