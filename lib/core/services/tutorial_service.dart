import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/i18n/app_strings.dart';

class TutorialService {
  static void showDashboardTutorial({
    required BuildContext context,
    required GlobalKey dashboardKey,
    required GlobalKey scanKey,
    required GlobalKey invoiceKey,
    required GlobalKey botKey,
    required VoidCallback onFinish,
  }) {
    final List<TargetFocus> targets = [];

    // 1. Dashboard Checklist (Smart Empty State)
    if (dashboardKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "dashboard_empty_state",
          keyTarget: dashboardKey,
          alignSkip: Alignment.topRight,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t(AppStr.tutorialWelcomeTitle),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.t(AppStr.tutorialWelcomeBody),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          shape: ShapeLightFocus.RRect,
          radius: 12,
        ),
      );
    }

    // 2. Scan Receipt
    if (scanKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "scan_receipt",
          keyTarget: scanKey,
          alignSkip: Alignment.topRight,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "✨ ${context.t(AppStr.magicScan)}",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.t(AppStr.magicScanSubtitle),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          shape: ShapeLightFocus.RRect,
          radius: 12,
        ),
      );
    }

    // 3. Create Invoice
    if (invoiceKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "create_invoice",
          keyTarget: invoiceKey,
          alignSkip: Alignment.topRight,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📝 ${context.t(AppStr.invoiceTitle)}",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Vytvorte profesionálnu faktúru s QR kódom pre klienta za pár sekúnd.",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          shape: ShapeLightFocus.RRect,
          radius: 12,
        ),
      );
    }

    // 4. BizBot
    if (botKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "biz_bot",
          keyTarget: botKey,
          alignSkip: Alignment.topRight,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🤖 ${context.t(AppStr.tutorialBotTitle)}",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.t(AppStr.tutorialBotBody),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          shape: ShapeLightFocus.RRect,
          radius: 16,
        ),
      );
    }

    if (targets.isEmpty) {
      onFinish();
      return;
    }

    TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF0038A8), // Slovak Blue
      textSkip: "PRESKOČIŤ",
      paddingFocus: 15,
      opacityShadow: 0.9,
      onFinish: onFinish,
      hideSkip: false,
      onSkip: () {
        onFinish();
        return true;
      },
    ).show(context: context);
  }

  static void showInvoicesTutorial({
    required BuildContext context,
    required GlobalKey fabKey,
    required GlobalKey remindersKey,
  }) {
    final List<TargetFocus> targets = [];

    // 1. Create Invoice
    if (fabKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "invoice_create",
          keyTarget: fabKey,
          alignSkip: Alignment.topLeft,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📝 ${context.t(AppStr.invoiceEmptyCta)}",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Vytvorte novú faktúru kliknutím na toto tlačidlo.",
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ],
                );
              },
            ),
          ],
          shape: ShapeLightFocus.RRect,
          radius: 16,
        ),
      );
    }

    // 2. Reminders
    if (remindersKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "invoice_reminders",
          keyTarget: remindersKey,
          alignSkip: Alignment.bottomRight,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🔔 ${context.t(AppStr.reminderVatTitle)}", // Reusing generic reminder title
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Tu nájdete prehľad upomienok a nezaplatených faktúr po splatnosti.",
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ],
                );
              },
            ),
          ],
          shape: ShapeLightFocus.Circle,
          radius: 10,
        ),
      );
    }

    _showTutorial(context, targets);
  }

  static void showExpensesTutorial({
    required BuildContext context,
    required GlobalKey fabKey,
    required GlobalKey filterKey,
    required GlobalKey analyticsKey,
  }) {
    final List<TargetFocus> targets = [];

    // 1. Create Expense
    if (fabKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "expense_create",
          keyTarget: fabKey,
          alignSkip: Alignment.topLeft,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "💸 ${context.t(AppStr.expensesEmptyCta)}",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Zaevidujte nový výdavok alebo naskenujte blok.",
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ],
                );
              },
            ),
          ],
          shape: ShapeLightFocus.RRect,
          radius: 16,
        ),
      );
    }

    // 2. Filters
    if (filterKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "expense_filter",
          keyTarget: filterKey,
          alignSkip: Alignment.bottomRight,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🔍 Filtrovanie",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Filtrujte výdavky podľa kategórie, sumy alebo dátumu.",
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ],
                );
              },
            ),
          ],
          shape: ShapeLightFocus.Circle,
          radius: 10,
        ),
      );
    }

    // 3. Analytics
    if (analyticsKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "expense_analytics",
          keyTarget: analyticsKey,
          alignSkip: Alignment.bottomRight,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📊 Analytika",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Pozrite si grafy a prehľady, kde utrácate najviac.",
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ],
                );
              },
            ),
          ],
          shape: ShapeLightFocus.Circle,
          radius: 10,
        ),
      );
    }

    _showTutorial(context, targets);
  }

  static void showSettingsTutorial({
    required BuildContext context,
    required GlobalKey saveKey,
    required GlobalKey sectionKey,
  }) {
    final List<TargetFocus> targets = [];

    // 1. Company Info
    if (sectionKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "settings_company",
          keyTarget: sectionKey,
          alignSkip: Alignment.bottomRight,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🏢 Firemné údaje",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Tu nastavte svoje fakturačné údaje. IČO sa dá načítať automaticky.",
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ],
                );
              },
            ),
          ],
          shape: ShapeLightFocus.RRect,
          radius: 4,
        ),
      );
    }

    // 2. Save
    if (saveKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "settings_save",
          keyTarget: saveKey,
          alignSkip: Alignment.bottomRight,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "💾 Uložiť zmeny",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Nezabudnite po úprave údajov kliknúť na tlačidlo uložiť.",
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ],
                );
              },
            ),
          ],
          shape: ShapeLightFocus.Circle,
          radius: 10,
        ),
      );
    }

    _showTutorial(context, targets);
  }

  static void _showTutorial(BuildContext context, List<TargetFocus> targets) {
    if (targets.isEmpty) return;
    TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF0038A8), // Slovak Blue
      textSkip: "PRESKOČIŤ",
      paddingFocus: 15,
      opacityShadow: 0.9,
      onFinish: () {},
      hideSkip: false,
      onSkip: () {
        return true;
      },
    ).show(context: context);
  }
}
