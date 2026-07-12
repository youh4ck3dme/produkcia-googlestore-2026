import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';

import '../../core/services/initialization_service.dart';

import '../../features/invoices/screens/invoices_screen.dart';
import '../../features/expenses/screens/expenses_screen.dart';
import '../../features/expenses/screens/expense_analytics_screen.dart';
import '../../features/expenses/screens/receipt_viewer_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/trash_screen.dart';
import '../../features/expenses/screens/expense_detail_screen.dart';
import '../../features/ai_tools/screens/ai_tools_screen.dart';

import '../../features/ai_tools/screens/biz_bot_screen.dart';
import '../../features/ai_tools/screens/ai_email_generator_screen.dart';
import '../../features/tax/screens/cashflow_analytics_screen.dart';
import '../../features/auth/screens/firebase_login_screen.dart';
// import '../../features/auth/screens/chameleon_login_screen.dart'; // No longer used as default login
import '../../features/auth/providers/auth_repository.dart';
import '../../features/intro/providers/onboarding_provider.dart';
import '../../features/invoices/screens/create_invoice_screen.dart';
import '../../features/invoices/screens/invoice_detail_screen.dart';
import '../../features/invoices/screens/payment_reminders_screen.dart';
import '../../features/invoices/screens/pdf_preview_screen.dart';

import '../../features/intro/screens/modern_onboarding_screen.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../../features/expenses/models/expense_model.dart';
import '../../features/expenses/screens/create_expense_screen.dart';


import '../../features/export/screens/export_screen.dart';
import '../../features/legal/screens/terms_and_conditions_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/tools/screens/icoatlas_home_screen.dart';
import '../../shared/widgets/scaffold_with_navbar.dart';
import '../../shared/widgets/biz_auth_required.dart';
import '../../core/config/play_release_scope.dart';
import '../../core/debug/perf_probe.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final firebaseAnalyticsProvider = Provider((ref) => FirebaseAnalytics.instance);

/// Notifies [GoRouter] to re-run redirects without recreating the router instance.
class GoRouterRefresh extends ChangeNotifier {
  GoRouterRefresh(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(onboardingProvider, (_, __) => notifyListeners());
    _ref.listen(initializationServiceProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

final goRouterRefreshProvider = Provider<GoRouterRefresh>((ref) {
  final refresh = GoRouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return refresh;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(goRouterRefreshProvider);
  final analytics = ref.watch(firebaseAnalyticsProvider);

  // #region agent log
  perfProbe('A', 'app_router.dart:routerProvider', 'go_router_created');
  // #endregion

  return GoRouter(
    refreshListenable: refresh,
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    observers: [
      FirebaseAnalyticsObserver(analytics: analytics),
    ],
    redirect: (context, state) {
      final path = state.uri.path;
      final authState = ref.read(authStateProvider);
      final onboardingState = ref.read(onboardingProvider);
      final init = ref.read(initializationServiceProvider);

      // 1. Auth / onboarding stream ešte nenačítané
      if (authState.isLoading || onboardingState.isLoading) {
        if (path == '/login' || path == '/onboarding') return null;
        return '/login';
      }

      // 2. Auth error
      if (authState.hasError) {
        return path == '/login' ? null : '/login';
      }

      final isLoggedIn = authState.value != null;
      final seenOnboarding = onboardingState.value ?? false;

      // OAuth návrat: ?code= v URL — drž login len kým nemáme session
      if (kIsWeb && Uri.base.queryParameters.containsKey('code') && !isLoggedIn) {
        return path == '/login' ? null : '/login';
      }

      // 3. Init (kozmetický splash) — neblokuj prihláseného používateľa
      if (!init.isCompleted && !isLoggedIn) {
        if (path == '/login' || path == '/onboarding') return null;
        return '/login';
      }

      // 4. Onboarding Flow
      if (!seenOnboarding) {
        return path == '/onboarding' ? null : '/onboarding';
      }

      // 5. Not Logged In
      if (!isLoggedIn) {
        if (path == '/login' || path == '/onboarding') return null;
        return '/login';
      }

      // 6. Already Logged In
      if (path == '/login' || path == '/onboarding') {
        return '/dashboard';
      }

      // Play MVP: skryté moduly → dashboard
      if (PlayReleaseScope.isRouteDisabled(path)) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const FirebaseLoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const ModernOnboardingScreen(),
      ),
      GoRoute(
        path: '/create-invoice',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return CreateInvoiceScreen(initialData: data);
        },
      ),
      GoRoute(
        path: '/create-expense',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is String) {
            return CreateExpenseScreen(initialText: extra);
          }
          if (extra is Map) {
            final initialText = extra['initialText'] as String?;
            final sharedImagePath = extra['sharedImagePath'] as String?;
            return CreateExpenseScreen(
              initialText: initialText,
              sharedImagePath: sharedImagePath,
            );
          }
          return const CreateExpenseScreen();
        },
      ),

      GoRoute(
        path: '/export',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(authStateProvider).value;
              if (user == null) return const BizAuthRequired();
              return ExportScreen(uid: user.id);
            },
          );
        },
      ),
      GoRoute(
        path: '/analytics/cashflow',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CashflowAnalyticsScreen(),
      ),
      GoRoute(
        path: '/legal/terms',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        path: '/legal/privacy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/icoatlas',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const IcoAtlasHomeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/invoices',
                builder: (context, state) => const InvoicesScreen(),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final invoice = state.extra as InvoiceModel;
                      return InvoiceDetailScreen(invoice: invoice);
                    },
                  ),
                  GoRoute(
                    path: 'reminders',
                    builder: (context, state) => const PaymentRemindersScreen(),
                  ),
                  GoRoute(
                    path: 'preview',
                    builder: (context, state) {
                      final invoice = state.extra as InvoiceModel;
                      return PdfPreviewScreen(invoice: invoice);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                builder: (context, state) => const ExpensesScreen(),
                routes: [
                  GoRoute(
                    path: 'analytics',
                    builder: (context, state) => const ExpenseAnalyticsScreen(),
                  ),
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final expense = state.extra as ExpenseModel;
                      return ExpenseDetailScreen(expense: expense);
                    },
                  ),
                  GoRoute(
                    path: 'receipt-viewer',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final extras = state.extra as Map<String, dynamic>;
                      return ReceiptViewerScreen(
                        imageUrl: extras['url'],
                        isLocal: extras['isLocal'] ?? false,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ai-tools',
                // Play MVP: vetva slúži ako „Asistent" → priamo BizBot.
                // Dev/full build: plný AI hub.
                builder: (context, state) => PlayReleaseScope.playMvp
                    ? const BizBotScreen()
                    : const AiToolsScreen(),
                routes: [

                  GoRoute(
                    path: 'biz-bot',
                    builder: (context, state) => const BizBotScreen(),
                  ),
                  GoRoute(
                    path: 'email-generator',
                    builder: (context, state) {
                      final extra = state.extra;
                      if (extra is Map<String, dynamic>) {
                        return AiEmailGeneratorScreen(
                          initialType: extra['type'] as String?,
                          initialContext: extra['context'] as String?,
                        );
                      }
                      return const AiEmailGeneratorScreen();
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'trash',
                    builder: (context, state) => const TrashScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
