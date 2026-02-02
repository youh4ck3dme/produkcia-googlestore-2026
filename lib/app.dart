import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/ui/biz_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/demo_mode/demo_mode_service.dart';
import 'core/i18n/l10n.dart';
import 'core/services/review_service.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/notifications/services/notification_scheduler.dart';
import 'features/expenses/providers/expenses_provider.dart';
import 'features/invoices/providers/invoices_provider.dart';
import 'features/analytics/providers/expense_insights_provider.dart';

class BizAgentApp extends ConsumerStatefulWidget {
  const BizAgentApp({super.key});

  @override
  ConsumerState<BizAgentApp> createState() => _BizAgentAppState();
}

class _BizAgentAppState extends ConsumerState<BizAgentApp> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    // Initialize Review Monitoring
    ref.read(reviewServiceProvider).monitorMilestones();

    // Initialize Notifications
    ref.read(notificationServiceProvider).init().then((_) {
      if (!mounted) return;
      ref.read(notificationServiceProvider).requestPermissions();
      ref.read(notificationSchedulerProvider).scheduleAllAlerts();
      
      // Start Monitoring (Firestore Listener)
      // ref.read(monitoringServiceProvider).notifications(); // Stream is lazy loaded by UI
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final demo = DemoModeService.instance;

    return ListenableBuilder(
      listenable: demo,
      builder: (context, _) {
        final overrides = <Override>[];
        if (demo.isDemoMode && !kReleaseMode) {
          overrides.addAll([
            expensesProvider.overrideWith((ref) => Stream.value(demo.getDemoExpenses())),
            invoicesProvider.overrideWith((ref) => Stream.value(demo.getDemoInvoices())),
            expenseInsightsProvider.overrideWith((ref) => Future.value(demo.getDemoInsights())),
          ]);
        }
        final child = L10n(
          locale: AppLocale.sk,
          child: MaterialApp.router(
            title: 'BizAgent',
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            debugShowCheckedModeBanner: false,
            theme: BizTheme.light(),
            darkTheme: BizTheme.dark(),
            themeMode: themeMode,
            routerConfig: router,
            builder: (context, child) {
              if (child != null) return child;
              return const SizedBox.shrink();
            },
          ),
        );
        if (overrides.isEmpty) return child;
        return ProviderScope(
          overrides: overrides,
          child: child,
        );
      },
    );
  }
}
