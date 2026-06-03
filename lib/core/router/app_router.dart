import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';

import '../../core/services/initialization_service.dart';
import '../../features/splash/screens/splash_screen.dart';
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
import '../../features/expenses/screens/voice_expense_screen.dart';


import '../../features/export/screens/export_screen.dart';
import '../../features/legal/screens/terms_and_conditions_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/tools/screens/icoatlas_home_screen.dart';
import '../../shared/widgets/scaffold_with_navbar.dart';
import '../../shared/widgets/biz_auth_required.dart';
import '../../core/config/play_release_scope.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final firebaseAnalyticsProvider = Provider((ref) => FirebaseAnalytics.instance);

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingState = ref.watch(onboardingProvider);
  final analytics = ref.watch(firebaseAnalyticsProvider);
  final init = ref.watch(initializationServiceProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    observers: [
      FirebaseAnalyticsObserver(analytics: analytics),
    ],
    redirect: (context, state) {
      final path = state.uri.path;

      // 1. Loading states
      if (authState.isLoading || onboardingState.isLoading) {
        return path == '/splash' ? null : '/splash';
      }

      // 1b. Initialization (Force Splash)
      // This ensures the splash screen runs its course even if auth loads fast.
      if (!init.isCompleted) {
        return path == '/splash' ? null : '/splash';
      }

      // 2. Auth error
      if (authState.hasError) {
        return path == '/login' ? null : '/login';
      }

      final isLoggedIn = authState.valueOrNull != null;
      final seenOnboarding = onboardingState.valueOrNull ?? false;

      // 3. Onboarding Flow
      if (!seenOnboarding) {
        return path == '/onboarding' ? null : '/onboarding';
      }

      // 4. Not Logged In
      if (!isLoggedIn) {
        if (path == '/login' || path == '/onboarding') return null;
        return '/login';
      }

      // 5. Already Logged In
      if (path == '/login' || path == '/splash' || path == '/onboarding') {
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
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
        path: '/voice-expense',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VoiceExpenseScreen(),
      ),

      GoRoute(
        path: '/export',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(authStateProvider).valueOrNull;
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
                builder: (context, state) => const AiToolsScreen(),
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
