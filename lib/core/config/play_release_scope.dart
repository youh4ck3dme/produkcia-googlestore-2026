/// Play MVP scope — vypnuté featury zostávajú v kóde, ale nie v release UX.
class PlayReleaseScope {
  PlayReleaseScope._();

  /// Play release cut. Dev full app: `flutter run --dart-define=PLAY_MVP=false`
  static bool get playMvp =>
      const bool.fromEnvironment('PLAY_MVP', defaultValue: true);

  // --- Navigácia ---
  static bool get showAiToolsNav => !playMvp;
  static bool get showMobilePromoFab => !playMvp;

  // --- Dashboard ---
  static bool get showSmartInsights => !playMvp;
  static bool get showBizBotCard => !playMvp;
  static bool get showTaxWidget => !playMvp;
  static bool get showNotificationBell => !playMvp;
  static bool get showDemoModeGesture => !playMvp;
  static bool get showMagicScanQuickAction => !playMvp;
  static bool get showPaymentReminders => !playMvp;
  static bool get showCoachMarkTutorials => !playMvp;

  // --- Faktúry ---
  static bool get showInvoiceAiFeatures => !playMvp;
  static bool get showIcoRiskVerdict => !playMvp;

  // --- Moduly (route redirect ak false) ---
  static bool get showAiToolsRoutes => !playMvp;
  static bool get showIcoAtlas => !playMvp;
  static bool get showCashflowAnalytics => !playMvp;
  static bool get showExpenseAnalytics => !playMvp;
  static bool get showVoiceExpense => !playMvp;

  static bool get showExpenseAiBranding => !playMvp;

  // --- Background / experimenty ---
  static bool get showBackgroundMonitoring => !playMvp;

  // --- Onboarding ---
  static bool get simplifiedOnboarding => playMvp;

  /// Demo mode len v debug/dev — nikdy v Play release builde.
  static bool get allowDemoMode => !playMvp;

  /// Cesty, ktoré v Play MVP presmerujú na dashboard.
  static bool isRouteDisabled(String path) {
    if (!playMvp) return false;
    if (path.startsWith('/ai-tools')) return true;
    if (path == '/icoatlas') return true;
    if (path.startsWith('/analytics')) return true;
    if (path == '/voice-expense') return true;
    if (path == '/expenses/analytics') return true;
    if (path.contains('/reminders')) return true;
    return false;
  }
}
