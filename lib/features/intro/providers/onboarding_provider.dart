import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/gemini_service.dart';

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, AsyncValue<bool>>((ref) {
  return OnboardingNotifier(ref);
});

class OnboardingNotifier extends StateNotifier<AsyncValue<bool>> {
  OnboardingNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadStatus();
  }

  OnboardingNotifier.test(this.ref, {required bool seen})
      : super(AsyncValue.data(seen));

  final Ref ref;
  static const _key = 'seen_onboarding';

  Future<void> _loadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_key) ?? false;
      state = AsyncValue.data(seen);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// New provider for onboarding demo data
final onboardingDemoProvider = StateNotifierProvider<OnboardingDemoNotifier, AsyncValue<OnboardingDemoData?>>((ref) {
  return OnboardingDemoNotifier(ref);
});

class OnboardingDemoNotifier extends StateNotifier<AsyncValue<OnboardingDemoData?>> {
  OnboardingDemoNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> generateDemoInvoice(String businessType) async {
    state = const AsyncValue.loading();

    try {
      // Use Gemini to generate demo invoice data
      final geminiService = ref.read(geminiServiceProvider);

      final prompt = '''
Vytvor ukážkovú faktúru pre typ podnikania: "$businessType"

POŽIADAVKY:
- Slovenský kontext, reálne názvy firiem
- Profesionálne služby/prvky pre daný typ podnikania
- 2-3 položky faktúry
- Realistické ceny v EUR
- Dátumy: dnešný dátum + 14 dní splatnosť

VRÁŤ JSON v tomto formáte:
{
  "invoiceNumber": "FA-2026001",
  "clientName": "Názov firmy s.r.o.",
  "clientIco": "12345678",
  "clientAddress": "Adresa, Mesto",
  "items": [
    {"description": "Popis služby", "quantity": 1, "price": 150.0}
  ],
  "notes": "Ďakujeme za obchod"
}
''';

      final response = await geminiService.analyzeJson(prompt, '''
{
  "invoiceNumber": "string",
  "clientName": "string",
  "clientIco": "string",
  "clientAddress": "string",
  "items": [{"description": "string", "quantity": "number", "price": "number"}],
  "notes": "string"
}
''');

      final invoiceData = response as Map<String, dynamic>;

      final demoData = OnboardingDemoData(
        businessType: businessType,
        generatedInvoice: invoiceData,
        suggestedFeatures: [
          'AI skenovanie bločkov',
          'Automatické pripomienky',
          'Daňové predpovede',
          'Real-time prehľady'
        ],
        generatedAt: DateTime.now(),
      );

      state = AsyncValue.data(demoData);
    } catch (e) {
      // Fallback to static demo data
      final fallbackData = _getFallbackDemoData(businessType);
      state = AsyncValue.data(fallbackData);
    }
  }

  OnboardingDemoData _getFallbackDemoData(String businessType) {
    Map<String, dynamic> invoiceData;

    switch (businessType) {
      case 'IT služby':
        invoiceData = {
          "invoiceNumber": "FA-2026001",
          "clientName": "Webové riešenia s.r.o.",
          "clientIco": "12345678",
          "clientAddress": "Hlavná 123, Bratislava",
          "items": [
            {"description": "Tvorba webovej stránky", "quantity": 1, "price": 1200.0},
            {"description": "SEO optimalizácia", "quantity": 1, "price": 300.0}
          ],
          "notes": "Ďakujeme za spoluprácu"
        };
        break;
      case 'Obchod':
        invoiceData = {
          "invoiceNumber": "FA-2026001",
          "clientName": "Stavebniny Plus s.r.o.",
          "clientIco": "87654321",
          "clientAddress": "Priemyselná 45, Košice",
          "items": [
            {"description": "Stavebný materiál - cement", "quantity": 10, "price": 15.0},
            {"description": "Doprava tovaru", "quantity": 1, "price": 50.0}
          ],
          "notes": "Platba do 14 dní"
        };
        break;
      case 'Remeslo':
        invoiceData = {
          "invoiceNumber": "FA-2026001",
          "clientName": "Kúrenie a Voda s.r.o.",
          "clientIco": "11223344",
          "clientAddress": "Technická 67, Žilina",
          "items": [
            {"description": "Inštalácia kúrenia", "quantity": 1, "price": 850.0},
            {"description": "Materiál - rúry a fittingy", "quantity": 1, "price": 120.0}
          ],
          "notes": "Záruka 2 roky na práce"
        };
        break;
      default:
        invoiceData = {
          "invoiceNumber": "FA-2026001",
          "clientName": "Oatmeal Digital s.r.o.",
          "clientIco": "53123456",
          "clientAddress": "Mýtna 1, 811 07 Bratislava",
          "items": [
            {"description": "Mesačný paušál - správa kampaní", "quantity": 1, "price": 450.0}
          ],
          "notes": "Ďakujeme za obchod"
        };
    }

    return OnboardingDemoData(
      businessType: businessType,
      generatedInvoice: invoiceData,
      suggestedFeatures: [
        'AI skenovanie bločkov',
        'Automatické pripomienky',
        'Daňové predpovede',
        'Real-time prehľady'
      ],
      generatedAt: DateTime.now(),
    );
  }
}

class OnboardingDemoData {
  final String businessType;
  final Map<String, dynamic> generatedInvoice;
  final List<String> suggestedFeatures;
  final DateTime generatedAt;

  OnboardingDemoData({
    required this.businessType,
    required this.generatedInvoice,
    required this.suggestedFeatures,
    required this.generatedAt,
  });
}
