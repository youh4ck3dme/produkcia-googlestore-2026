import 'demo_mode_service.dart';
import 'demo_scenarios.dart';

/// Spúšťa kompletný demo scenár s naratívom pre prezentácie investorom.
class DemoScenarioRunner {
  DemoScenarioRunner._();
  static final DemoScenarioRunner instance = DemoScenarioRunner._();

  final DemoModeService _demo = DemoModeService.instance;

  /// Spustí kompletný demo beh (scenáre za sebou, s výstupom do konzoly).
  Future<void> runFullDemo() async {
    // ignore: avoid_print
    print('🎬 Starting BizAgent AI Demo...\n');

    // Scene 1: AI Dashboard (insights)
    // ignore: avoid_print
    print('📊 Scene 1: AI Dashboard');
    _demo.activateDemoMode(DemoScenario.standard);
    await Future<void>.delayed(const Duration(seconds: 3));

    // Scene 2: Predikcia
    // ignore: avoid_print
    print('🔮 Scene 2: Prediction Alert');
    _demo.setScenario(DemoScenario.standard);
    await Future<void>.delayed(const Duration(seconds: 3));

    // Scene 3: Tax Optimization
    // ignore: avoid_print
    print('💰 Scene 3: Tax Optimization');
    _demo.setScenario(DemoScenario.taxOptimization);
    await Future<void>.delayed(const Duration(seconds: 3));

    // Scene 4: Anomaly Detection
    // ignore: avoid_print
    print('⚠️ Scene 4: Anomaly Detection');
    _demo.setScenario(DemoScenario.anomalyDetection);
    await Future<void>.delayed(const Duration(seconds: 3));

    // Scene 5: Receipt Detective (missing receipts)
    // ignore: avoid_print
    print('🔍 Scene 5: Receipt Detective');
    _demo.setScenario(DemoScenario.receiptMissing);
    await Future<void>.delayed(const Duration(seconds: 5));

    // Scene 6: AI Chat (app would show chat; here we only switch scenario)
    // ignore: avoid_print
    print('💬 Scene 6: AI Chat');
    _demo.setScenario(DemoScenario.standard);
    await Future<void>.delayed(const Duration(seconds: 2));

    // ignore: avoid_print
    print('\n✅ Demo Complete!');
  }
}
