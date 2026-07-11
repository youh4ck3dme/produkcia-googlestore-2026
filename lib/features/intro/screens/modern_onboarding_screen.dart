import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../core/config/play_release_scope.dart';
import '../providers/onboarding_provider.dart';
import '../../../core/services/analytics_service.dart';

class ModernOnboardingScreen extends ConsumerStatefulWidget {
  const ModernOnboardingScreen({super.key});

  @override
  ConsumerState<ModernOnboardingScreen> createState() => _ModernOnboardingScreenState();
}

class _ModernOnboardingScreenState extends ConsumerState<ModernOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedBusinessType = 'IT služby';

  static const _legacySteps = [
    ModernOnboardingStep(
      titleKey: AppStr.onboardingLegacyWelcomeTitle,
      subtitleKey: AppStr.onboardingLegacyWelcomeSubtitle,
      type: OnboardingStepType.welcome,
    ),
    ModernOnboardingStep(
      titleKey: AppStr.onboardingLegacyInvoiceTitle,
      subtitleKey: AppStr.onboardingLegacyInvoiceSubtitle,
      type: OnboardingStepType.welcome,
    ),
    ModernOnboardingStep(
      titleKey: AppStr.onboardingLegacyExpensesTitle,
      subtitleKey: AppStr.onboardingLegacyExpensesSubtitle,
      type: OnboardingStepType.welcome,
    ),
    ModernOnboardingStep(
      titleKey: AppStr.onboardingLegacyBusinessTitle,
      subtitleKey: AppStr.onboardingLegacyBusinessSubtitle,
      type: OnboardingStepType.businessType,
    ),
    ModernOnboardingStep(
      titleKey: AppStr.onboardingLegacyDemoTitle,
      subtitleKey: AppStr.onboardingLegacyDemoSubtitle,
      type: OnboardingStepType.demo,
    ),
    ModernOnboardingStep(
      titleKey: AppStr.onboardingLegacyFinishTitle,
      subtitleKey: AppStr.onboardingLegacyFinishSubtitle,
      type: OnboardingStepType.finish,
    ),
  ];

  List<ModernOnboardingStep> get _steps {
    if (PlayReleaseScope.simplifiedOnboarding) {
      return const [
        ModernOnboardingStep(
          titleKey: AppStr.onboardingSimpleWelcomeTitle,
          subtitleKey: AppStr.onboardingSimpleWelcomeSubtitle,
          type: OnboardingStepType.welcome,
        ),
        ModernOnboardingStep(
          titleKey: AppStr.onboardingSimpleHowTitle,
          subtitleKey: AppStr.onboardingSimpleHowSubtitle,
          type: OnboardingStepType.welcome,
        ),
        ModernOnboardingStep(
          titleKey: AppStr.onboardingSimpleFinishTitle,
          subtitleKey: AppStr.onboardingSimpleFinishSubtitle,
          type: OnboardingStepType.finish,
        ),
      ];
    }
    return _legacySteps;
  }

  // legacy field removed — use getter _steps above

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logOnboardingStarted();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipToDemo() {
    if (PlayReleaseScope.simplifiedOnboarding) {
      _completeOnboarding();
      return;
    }
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 600),
      curve: Curves.fastOutSlowIn,
    );
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    ref.read(analyticsServiceProvider).logOnboardingCompleted();

    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _steps.length,
            itemBuilder: (context, index) => _OnboardingPage(
              step: _steps[index],
              selectedBusinessType: _selectedBusinessType,
              onBusinessTypeChanged: (type) => setState(() => _selectedBusinessType = type),
              onGenerateDemo: () => ref.read(onboardingDemoProvider.notifier).generateDemoInvoice(_selectedBusinessType),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _steps.length,
                        (index) => _ProgressDot(
                          isActive: index == _currentPage,
                          isCompleted: index < _currentPage,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (_currentPage == 0) ...[
                          TextButton(
                            onPressed: _skipToDemo,
                            child: Text(
                              context.t(AppStr.onboardingSkip),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12.8), // Reduced by 20% (16 * 0.8)
                            ),
                          ),
                          const Spacer(),
                        ] else ...[
                          const Spacer(),
                        ],
                        ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BizTheme.slovakBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentPage == _steps.length - 1
                                ? context.t(AppStr.onboardingStartUsing)
                                : context.t(AppStr.onboardingContinue),
                            style: const TextStyle(fontSize: 12.8, fontWeight: FontWeight.w600), // Reduced by 20% (16 * 0.8)
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends ConsumerWidget {
  const _OnboardingPage({
    required this.step,
    required this.selectedBusinessType,
    required this.onBusinessTypeChanged,
    required this.onGenerateDemo,
  });

  final ModernOnboardingStep step;
  final String selectedBusinessType;
  final ValueChanged<String> onBusinessTypeChanged;
  final VoidCallback onGenerateDemo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            context.t(step.titleKey),
            style: const TextStyle(
              fontSize: 25.6, // Reduced by 20% (32 * 0.8)
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            context.t(step.subtitleKey),
            style: TextStyle(
              fontSize: 14.4, // Reduced by 20% (18 * 0.8)
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 1),
          Flexible(
            flex: 4,
            child: _buildStepContent(ref),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildStepContent(WidgetRef ref) {
    switch (step.type) {
      case OnboardingStepType.welcome:
        return step.image != null ? _ImageContent(imagePath: step.image!) : _WelcomeContent();
      case OnboardingStepType.features:
        return step.image != null ? _ImageContent(imagePath: step.image!) : _WelcomeContent();
      case OnboardingStepType.businessType:
        return _BusinessTypeSelector(
          selectedType: selectedBusinessType,
          onChanged: onBusinessTypeChanged,
        );
      case OnboardingStepType.demo:
        return _DemoPreview(
          businessType: selectedBusinessType,
          onGenerateDemo: onGenerateDemo,
        );
      case OnboardingStepType.finish:
        return _FinishContent();
    }
  }
}

class _WelcomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: BizTheme.slovakBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 80,
            color: BizTheme.slovakBlue,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          context.t(AppStr.onboardingWelcomeBody),
          style: TextStyle(
            fontSize: 12.8, // Reduced by 20% (16 * 0.8)
            color: Colors.grey[700],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ImageContent extends StatelessWidget {
  const _ImageContent({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _BusinessTypeSelector extends StatefulWidget {
  const _BusinessTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  final String selectedType;
  final ValueChanged<String> onChanged;

  @override
  State<_BusinessTypeSelector> createState() => _BusinessTypeSelectorState();
}

class _BusinessTypeSelectorState extends State<_BusinessTypeSelector> {
  static const _businessTypeIds = ['IT služby', 'Obchod', 'Remeslo', 'Iné'];

  List<({String id, IconData icon, AppStr label, AppStr description})> _types(
    BuildContext context,
  ) {
    return [
      (
        id: _businessTypeIds[0],
        icon: Icons.computer,
        label: AppStr.onboardingBizTypeIt,
        description: AppStr.onboardingBizTypeItDesc,
      ),
      (
        id: _businessTypeIds[1],
        icon: Icons.store,
        label: AppStr.onboardingBizTypeTrade,
        description: AppStr.onboardingBizTypeTradeDesc,
      ),
      (
        id: _businessTypeIds[2],
        icon: Icons.build,
        label: AppStr.onboardingBizTypeCraft,
        description: AppStr.onboardingBizTypeCraftDesc,
      ),
      (
        id: _businessTypeIds[3],
        icon: Icons.business,
        label: AppStr.onboardingBizTypeOther,
        description: AppStr.onboardingBizTypeOtherDesc,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._types(context).map((type) {
            final isSelected = type.id == widget.selectedType;

            return GestureDetector(
              onTap: () => widget.onChanged(type.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? BizTheme.slovakBlue.withValues(alpha: 0.1) : Colors.white,
                  border: Border.all(
                    color: isSelected ? BizTheme.slovakBlue : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? BizTheme.slovakBlue : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        type.icon,
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t(type.label),
                            style: TextStyle(
                              fontSize: 14.4, // Reduced by 20% (18 * 0.8)
                              fontWeight: FontWeight.w600,
                              color: isSelected ? BizTheme.slovakBlue : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.t(type.description),
                            style: TextStyle(
                              fontSize: 11.2, // Reduced by 20% (14 * 0.8)
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: BizTheme.slovakBlue,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }),
          // Pridané padding na spodku, aby sa nič nezachádzalo pod navigáciu
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DemoPreview extends ConsumerWidget {
  const _DemoPreview({
    required this.businessType,
    required this.onGenerateDemo,
  });

  final String businessType;
  final VoidCallback onGenerateDemo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoAsync = ref.watch(onboardingDemoProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (demoAsync.value == null && !demoAsync.isLoading) {
        onGenerateDemo();
      }
    });

    return demoAsync.when(
      loading: () => _LoadingDemo(),
      error: (error, stack) => _ErrorDemo(onRetry: onGenerateDemo),
      data: (demoData) => demoData != null
          ? _InvoiceDemo(invoiceData: demoData.generatedInvoice)
          : _LoadingDemo(),
    );
  }
}

class _LoadingDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BizTheme.slovakBlue),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.t(AppStr.onboardingDemoGenerating),
            style: TextStyle(
              fontSize: 12.8, // Reduced by 20% (16 * 0.8)
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorDemo extends StatelessWidget {
  const _ErrorDemo({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            context.t(AppStr.onboardingDemoError),
            style: TextStyle(
              fontSize: 14.4, // Reduced by 20% (18 * 0.8)
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t(AppStr.onboardingDemoFallback),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(context.t(AppStr.retry)),
          ),
        ],
      ),
    );
  }
}

class _InvoiceDemo extends StatelessWidget {
  const _InvoiceDemo({required this.invoiceData});

  final Map<String, dynamic> invoiceData;

  @override
  Widget build(BuildContext context) {
    final items = invoiceData['items'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                invoiceData['invoiceNumber'] ?? 'FA-XXXXXX',
                style: const TextStyle(
                  fontSize: 19.2, // Reduced by 20% (24 * 0.8)
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: BizTheme.slovakBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.t(AppStr.onboardingDraftBadge),
                  style: const TextStyle(
                    fontSize: 9.6, // Reduced by 20% (12 * 0.8)
                    fontWeight: FontWeight.w600,
                    color: BizTheme.slovakBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            invoiceData['clientName'] ?? context.t(AppStr.onboardingClientDefault),
            style: const TextStyle(
              fontSize: 14.4, // Reduced by 20% (18 * 0.8)
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'IČO: ${invoiceData['clientIco'] ?? 'XXXXXXXX'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ...items.map((item) {
            final description = item['description'] ?? '';
            final quantity = item['quantity'] ?? 1;
            final price = item['price'] ?? 0.0;
            final total = quantity * price;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      description,
                      style: const TextStyle(fontSize: 11.2), // Reduced by 20% (14 * 0.8)
                    ),
                  ),
                  Text(
                    '${quantity}x ${NumberFormat.currency(symbol: '€').format(price)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    NumberFormat.currency(symbol: '€').format(total),
                    style: const TextStyle(
                      fontSize: 11.2, // Reduced by 20% (14 * 0.8)
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                context.t(AppStr.onboardingTotal, params: {
                  'amount': NumberFormat.currency(symbol: '€').format(_calculateTotal(items)),
                }),
                style: const TextStyle(
                  fontSize: 14.4, // Reduced by 20% (18 * 0.8)
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 16,
                color: BizTheme.slovakBlue,
              ),
              const SizedBox(width: 8),
              Text(
                context.t(AppStr.onboardingAiGenerated),
                style: const TextStyle(
                  fontSize: 12,
                  color: BizTheme.slovakBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateTotal(List<dynamic> items) {
    return items.fold(0.0, (total, item) {
      final quantity = item['quantity'] ?? 1;
      final price = item['price'] ?? 0.0;
      return total + (quantity * price);
    });
  }
}

class _FinishContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      (icon: Icons.document_scanner, key: AppStr.onboardingFeatureScan),
      (icon: Icons.notifications_active, key: AppStr.onboardingFeatureReminders),
      (icon: Icons.analytics, key: AppStr.onboardingFeatureTaxPredict),
      (icon: Icons.show_chart, key: AppStr.onboardingFeatureRealtime),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: BizTheme.slovakBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: BizTheme.slovakBlue,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            context.t(AppStr.onboardingFinishQuestion),
            style: TextStyle(
              fontSize: 12.8, // Reduced by 20% (16 * 0.8)
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BizTheme.slovakBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    feature.icon,
                    color: BizTheme.slovakBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    context.t(feature.key),
                    style: const TextStyle(
                      fontSize: 12.8, // Reduced by 20% (16 * 0.8)
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({
    required this.isActive,
    required this.isCompleted,
  });

  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isCompleted
            ? BizTheme.slovakBlue
            : isActive
                ? BizTheme.slovakBlue
                : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

enum OnboardingStepType {
  welcome,
  features,
  businessType,
  demo,
  finish,
}

class ModernOnboardingStep {
  final AppStr titleKey;
  final AppStr subtitleKey;
  final String? image;
  final OnboardingStepType type;

  const ModernOnboardingStep({
    required this.titleKey,
    required this.subtitleKey,
    this.image,
    required this.type,
  });
}
