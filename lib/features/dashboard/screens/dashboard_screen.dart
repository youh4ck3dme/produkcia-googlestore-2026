import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/scheduler.dart'; // For SchedulerBinding
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../../invoices/models/invoice_model.dart';
import '../widgets/dashboard_tax_widget.dart';
import '../providers/revenue_provider.dart';
import '../providers/profit_provider.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../shared/widgets/biz_section_header.dart';
import '../widgets/smart_dashboard_empty_state.dart';
import '../widgets/smart_insights_widget.dart';
import '../../../core/services/tutorial_service.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../shared/widgets/biz_widgets.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../shared/widgets/biz_glass_appbar.dart';
import '../../../core/demo_mode/demo_mode.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Global Keys for Tutorial
  final GlobalKey _dashboardKey = GlobalKey();
  final GlobalKey _scanKey = GlobalKey();
  final GlobalKey _invoiceKey = GlobalKey();
  final GlobalKey _botKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Schedule tutorial check after layout
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial();
    });
  }

  Future<void> _checkAndShowTutorial() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    // Show tutorial if user is Anonymous (Demo) OR if it's a fresh install check
    // Ideally we use SharedPreferences to check if tutorial was already shown
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial =
        prefs.getBool('hasSeenTutorial_${user.id}') ?? false;

    if (!hasSeenTutorial) {
      if (!mounted) return;
      TutorialService.showDashboardTutorial(
        context: context,
        dashboardKey: _dashboardKey,
        scanKey: _scanKey,
        invoiceKey: _invoiceKey,
        botKey: _botKey,
        onFinish: () {
          prefs.setBool('hasSeenTutorial_${user.id}', true);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final invoicesAsync = ref.watch(invoicesProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final revenueAsync = ref.watch(revenueMetricsProvider);
    final profitAsync = ref.watch(profitMetricsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: BizGlassAppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: GestureDetector(
                onTap: () {
                  final demo = DemoModeService.instance;
                  demo.recordLogoTap();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          demo.isDemoMode ? 'Demo mód zapnutý' : 'Demo mód vypnutý',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text(
                  context.t(AppStr.spdTitle),
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ListenableBuilder(
              listenable: DemoModeService.instance,
              builder: (context, _) {
                if (!DemoModeService.instance.isDemoMode) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: const Text('Demo'),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              },
            ),
            const ZenLock(),
          ],
        ),
        actions: [
          const NotificationBell(), 
          BizTutorialButton(
            onPressed: () {
              TutorialService.showDashboardTutorial(
                context: context,
                dashboardKey: _dashboardKey,
                scanKey: _scanKey,
                invoiceKey: _invoiceKey,
                botKey: _botKey,
                onFinish: () {},
              );
            },
            tooltip: 'Zobraziť tutoriál',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
            tooltip: 'Odhlásiť sa',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
          
          final double padding = isDesktop ? 32.0 : 16.0;
          final int crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(invoicesProvider);
              ref.invalidate(expensesProvider);
              await Future.wait([
                ref.read(invoicesProvider.future),
                ref.read(expensesProvider.future),
              ]);
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ahoj, ${user?.displayName ?? 'Používateľ'}!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ).animate().fade().moveY(begin: 10, duration: 400.ms),
                      const SizedBox(height: 4),
                      Text(context.t(AppStr.spdDisclaimer),
                          style: Theme.of(context).textTheme.bodySmall).animate().fade(delay: 100.ms),
                      const SizedBox(height: 24),

                      // First-run banner
                      if (!(invoicesAsync.isLoading || expensesAsync.isLoading) &&
                          !(invoicesAsync.hasError || expensesAsync.hasError) &&
                          (invoicesAsync.value?.isEmpty ?? true) &&
                          (expensesAsync.value?.isEmpty ?? true))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: SmartDashboardEmptyState(key: _dashboardKey),
                        ).animate().fade(),

                      // Overdue Alerts
                      if (invoicesAsync.value != null)
                        _buildOverdueAlert(context, invoicesAsync.value!)
                            .animate()
                            .fade(delay: 200.ms)
                            .slideX(begin: 0.1),

                      // Financial Summary (Responsive Grid)
                      if (revenueAsync.isLoading || profitAsync.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (revenueAsync.hasError || profitAsync.hasError)
                        Text(context.t(AppStr.errorGeneric))
                      else if (revenueAsync.value != null && profitAsync.value != null)
                        _buildExecutiveDashboard(
                          context,
                          revenueAsync.value!,
                          profitAsync.value!,
                          expensesAsync.value ?? [],
                          crossAxisCount: crossAxisCount, // Dynamic Column Count
                        ).animate().fade(delay: 300.ms),

                      const SizedBox(height: 24),
                      // AI Insights
                      const SmartInsightsWidget().animate().fade(delay: 400.ms),

                      const SizedBox(height: 16),
                      // BizBot Quick Chat Card
                      _buildBizBotCard(context).animate().fade(delay: 450.ms),

                      const SizedBox(height: 16),
                      // Tax Widget
                      const DashboardTaxWidget().animate().fade(delay: 500.ms),

                      const SizedBox(height: 32),

                      // Quick Actions
                      BizSectionHeader(title: context.t(AppStr.quickActions))
                          .animate()
                          .fade(delay: 600.ms),
                      const SizedBox(height: 16),
                      
                      // Using Wrap for responsive Quick Actions on large screens
                      if (isDesktop)
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(width: 250, child: _buildActionTile(context, title: context.t(AppStr.invoiceTitle), subtitle: 'Nová faktúra pre klienta', icon: Icons.add_circle_outline, color: BizTheme.slovakBlue, onTap: () => context.push('/create-invoice'), widgetKey: _invoiceKey)),
                            SizedBox(width: 300, child: _buildActionTile(context, title: context.t(AppStr.magicScan), subtitle: context.t(AppStr.magicScanSubtitle), icon: Icons.auto_awesome, color: BizTheme.blueDark, onTap: () => context.push('/ai-tools'), widgetKey: _scanKey)),
                            SizedBox(width: 250, child: _buildActionTile(context, title: 'Pridať výdavok', subtitle: 'Evidencia nákladov', icon: Icons.shopping_bag_outlined, color: BizTheme.nationalRed, onTap: () => context.push('/create-expense'))),
                            SizedBox(width: 250, child: _buildActionTile(context, title: 'Import bank CSV', subtitle: 'Automatické párovanie faktúr', icon: Icons.upload_file, color: BizTheme.gray500, onTap: () => context.push('/bank-import'))),
                            SizedBox(width: 250, child: _buildActionTile(context, title: 'Export pre účtovníka', subtitle: 'Zostava faktúr a výdavkov', icon: Icons.download, color: BizTheme.gray800, onTap: () => context.push('/export'))),
                          ],
                        ).animate().fade(delay: 700.ms)
                      else
                        Column(
                          children: [
                            _buildActionTile(
                              context,
                              title: context.t(AppStr.invoiceTitle),
                              subtitle: 'Nová faktúra pre klienta',
                              icon: Icons.add_circle_outline,
                              color: BizTheme.slovakBlue, // Use theme color
                              onTap: () => context.push('/create-invoice'),
                              widgetKey: _invoiceKey,
                            ),
                            _buildActionTile(
                              context,
                              title: context.t(AppStr.magicScan),
                              subtitle: context.t(AppStr.magicScanSubtitle),
                              icon: Icons.auto_awesome,
                              color: BizTheme.blueDark,
                              onTap: () => context.push('/ai-tools'),
                              widgetKey: _scanKey,
                            ),
                            _buildActionTile(
                              context,
                              title: 'Pridať výdavok',
                              subtitle: 'Evidencia nákladov',
                              icon: Icons.shopping_bag_outlined,
                              color: BizTheme.nationalRed, // Use theme color
                              onTap: () => context.push('/create-expense'),
                            ),
                            _buildActionTile(
                              context,
                              title: 'Import bank CSV',
                              subtitle: 'Automatické párovanie faktúr',
                              icon: Icons.upload_file,
                              color: BizTheme.gray500, // Use theme color
                              onTap: () => context.push('/bank-import'),
                            ),
                            _buildActionTile(
                              context,
                              title: 'Export pre účtovníka',
                              subtitle: 'Zostava faktúr a výdavkov',
                              icon: Icons.download,
                              color: BizTheme.gray800, // Use theme color
                              onTap: () => context.push('/export'),
                            ),
                          ].animate(interval: 50.ms).fade(duration: 300.ms).slideX(begin: 0.1),
                        ),

                      const SizedBox(height: 32),
                      // Recent Invoices
                      const BizSectionHeader(title: 'Posledné faktúry').animate().fade(delay: 900.ms),
                      const SizedBox(height: 16),
                      if (invoicesAsync.value != null)
                         ...invoicesAsync.value!.take(5).map((invoice) => 
                            BizInvoiceCard(
                              title: invoice.clientName,
                              subtitle: invoice.number,
                              amount: invoice.totalAmount,
                              date: invoice.dateDue, 
                              status: invoice.status.toSlovak(),
                              statusColor: invoice.status.color(context),
                              onTap: () => context.push('/invoices/detail', extra: invoice),
                            ).animate().fade().slideY(begin: 0.2)
                         ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverdueAlert(BuildContext context, List<InvoiceModel> invoices) {
    final overdueCount = invoices
        .where((i) =>
            i.status == InvoiceStatus.overdue ||
            (i.status == InvoiceStatus.sent &&
                i.dateDue.isBefore(DateTime.now())))
        .length;

    if (overdueCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: BizTheme.accentRedLight,
        borderRadius: BorderRadius.circular(BizTheme.radiusLg),
        child: InkWell(
          onTap: () => context.push('/invoices/reminders'),

          borderRadius: BorderRadius.circular(BizTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: BizTheme.nationalRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Máte $overdueCount faktúr po lehote splatnosti!',
                    style: const TextStyle(
                      color: BizTheme.nationalRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: BizTheme.nationalRed),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildExecutiveDashboard(BuildContext context, RevenueMetrics revenue,
      ProfitMetrics profit, List<dynamic> expenses, {int crossAxisCount = 2}) {
    final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Column(
      children: [
         GridView.count(
          crossAxisCount: crossAxisCount, // Use dynamic count
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            BizStatsCard(
              title: 'Príjmy (Celkovo)',
              metric: NumberFormat.currency(symbol: '€').format(revenue.totalRevenue),
              color: BizTheme.slovakBlue,
              icon: Icons.account_balance_wallet_outlined,
            ),
            BizStatsCard(
              title: 'Čistý Zisk',
              metric: NumberFormat.currency(symbol: '€').format(profit.profit),
              color: BizTheme.blueLight,
              icon: Icons.savings_outlined,
              trend: 'Marža: ${(profit.profitMargin * 100).toStringAsFixed(1)}%',
              isPositive: profit.profit > 0,
            ),
            BizStatsCard(
              title: 'Neuhradené',
              metric: NumberFormat.currency(symbol: '€').format(revenue.unpaidAmount),
              color: BizTheme.nationalRed,
              icon: Icons.pending_actions_outlined,
              trend: '${revenue.overdueCount} po lehote',
              isPositive: false,
            ),
            BizStatsCard(
              title: 'Výdavky',
              metric: NumberFormat.currency(symbol: '€').format(totalExpenses),
              color: BizTheme.accentRed,
              icon: Icons.shopping_cart_outlined,
              isPositive: false,
            ),
            BizStatsCard(
              title: 'Tento mesiac',
              metric: NumberFormat.currency(symbol: '€').format(revenue.thisMonthRevenue),
              color: BizTheme.gray500,
              icon: Icons.calendar_today_outlined,
            ),
            BizStatsCard(
              title: 'Priemerná faktúra',
              metric: NumberFormat.currency(symbol: '€').format(revenue.averageInvoiceValue),
              color: BizTheme.gray800,
              icon: Icons.bar_chart_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Pie Chart
        if (revenue.totalRevenue > 0 || totalExpenses > 0)
          GestureDetector(
            onTap: () => context.push('/analytics'),
            child: BizChartContainer(
              title: 'Pomer Príjmy vs Výdavky',
              height: 250,
              chart: Column(
                children: [
                   SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            color: BizTheme.slovakBlue,
                            value: revenue.totalRevenue,
                            title: '',
                            radius: 50,
                          ),
                          PieChartSectionData(
                            color: BizTheme.nationalRed,
                            value: totalExpenses,
                            title: '',
                            radius: 50,
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendItem(
                          context, context.t(AppStr.incomeTotal), BizTheme.slovakBlue),
                      const SizedBox(width: 16),
                      _legendItem(
                          context, context.t(AppStr.expensesTotal), BizTheme.nationalRed),
                    ],
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _legendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }



  Widget _buildBizBotCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      key: _botKey,
      color: isDark ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1) : BizTheme.slovakBlue.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () => context.push('/ai-tools/biz-bot'),
        child: Padding(
          padding: const EdgeInsets.all(BizTheme.spacingMd),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BizTheme.slovakBlue,
                  borderRadius: BorderRadius.circular(BizTheme.radiusLg),
                ),
                child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: BizTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pýtaj sa BizBota',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'AI analýza tvojich financií v reálnom čase.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: BizTheme.slovakBlue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Key? widgetKey,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      key: widgetKey,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(BizTheme.spacingMd),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BizTheme.radiusLg),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: BizTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, 
                size: 14, 
                color: isDark ? BizTheme.darkDisabled : BizTheme.gray300,
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.easeOut);
  }
}
