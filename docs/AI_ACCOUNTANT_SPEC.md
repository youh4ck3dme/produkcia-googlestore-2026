# Špecifikácia AI Accountant – BizAgent

Architektúra a požiadavky pre modul AI účtovníka. Projekt používa **Riverpod** a existujúce **ExpenseInsight** / **SmartInsightsWidget**; nový modul ich rozširuje alebo integruje.

---

## ARCHITEKTÚRA PROJEKTU

```text
lib/
├── features/
│   └── ai_accountant/
│       ├── data/
│       │   ├── models/
│       │   │   ├── financial_insight.dart
│       │   │   ├── prediction_model.dart
│       │   │   ├── tax_recommendation.dart
│       │   │   └── anomaly_alert.dart
│       │   ├── repositories/
│       │   │   ├── ai_repository.dart
│       │   │   └── financial_data_repository.dart
│       │   └── datasources/
│       │       ├── claude_api_datasource.dart   # alebo gemini_datasource (existuje ExpenseInsightsService)
│       │       ├── firebase_datasource.dart
│       │       └── local_ml_datasource.dart
│       ├── domain/
│       │   ├── entities/
│       │   ├── usecases/
│       │   │   ├── generate_predictions.dart
│       │   │   ├── analyze_spending_patterns.dart
│       │   │   ├── get_tax_recommendations.dart
│       │   │   └── detect_anomalies.dart
│       │   └── repositories/
│       ├── presentation/
│       │   ├── bloc/  # alebo Riverpod providers (projekt používa Riverpod)
│       │   │   ├── ai_accountant_bloc.dart
│       │   │   ├── ai_accountant_event.dart
│       │   │   └── ai_accountant_state.dart
│       │   ├── widgets/
│       │   │   ├── insight_card.dart
│       │   │   ├── prediction_timeline.dart
│       │   │   ├── tax_advisor_widget.dart
│       │   │   ├── anomaly_alert_banner.dart
│       │   │   └── ai_chat_interface.dart
│       │   └── pages/
│       │       ├── ai_dashboard_page.dart
│       │       └── insights_detail_page.dart
│       └── di/
│           └── ai_accountant_injection.dart
```

**Súvis s existujúcim kódom:**

- `lib/features/analytics/` – **ExpenseInsight**, **ExpenseInsightsService** (Gemini), **expenseInsightsProvider**, **SmartInsightsWidget** sú predchodca AI insightov. Nový modul môže rozšíriť tieto modely a provider alebo pridať nové (predikcie, daňové odporúčania, anomálie).
- **Demo mode** (`lib/core/demo_mode/`) – **DemoDataGenerator** má zásobovať aj nové AI modely (predikcie, daňové odporúčania, anomálie) pre prezentácie a testy.

**State management:** Projekt používa **Riverpod**; nový modul by mal používať Riverpod (providery) namiesto BLoC, pokiaľ nie je dôvod pre BLoC.

**AI provider:** V projekte je **Gemini** (ExpenseInsightsService). Špec môže použiť **Claude** alebo **Gemini**; odporúča sa jedna vrstva „AI datasource“, ktorá môže byť Claude alebo Gemini.

---

## FÁZY IMPLEMENTÁCIE (odporúčané)

1. **Fáza 1:** Modely (predikcia, daňové odporúčanie, anomália) + jeden datasource (Gemini/Claude) + jeden use case (napr. get_tax_recommendations) + AI Dashboard page so sekciami (insights, predikcie, daňové tipy).
2. **Fáza 2:** Predikcie (generate_predictions), detekcia anomálií (detect_anomalies), rozšírenie demo dát.
3. **Fáza 3:** AI chat, push notifikácie, Cloud Functions (generateDailyInsights, processNewTransaction, atď.).

---

## POŽIADAVKY NA IMPLEMENTÁCIU

### 1. Claude / Gemini API (claude_api_datasource.dart alebo gemini_datasource.dart)

- `analyzeFinancialData(List transactions, UserProfile profile) -> FinancialInsight`
- `generatePredictions(FinancialHistory history, int daysAhead) -> List<Prediction>`
- `getTaxOptimization(TaxContext context) -> TaxRecommendation`
- `detectAnomalies(List recent) -> List<AnomalyAlert>`
- `answerFinancialQuestion(String question, FinancialContext context) -> String`

**System prompt (slovenčina, €):** Profesionálny finančný poradca pre SZČO, slovenské daňové zákony, DPH, odvody SZP/ZP; úlohy: analýza, predikcie, daňové optimalizácie, anomálie, odpovede na otázky. Uvádzať konkrétne čísla, disclaimer pri daňových radách.

### 2. Predikčný model (prediction_model.dart)

- **Prediction:** id, type (EXPENSE, INCOME, CASHFLOW, TAX), title, description, predictedAmount, confidence 0–1, predictedDate, createdAt, basedOn, RecommendedAction?
- **RecommendedAction:** type (TRANSFER, PURCHASE, SAVE, ALERT), description, amount?, targetAccount?, priority 1–5.
- Logika: analýza 6 mesiacov, recurring expenses, exponential smoothing, kombinácia s AI pre kontext.

### 3. Daňový stratég (tax_recommendation.dart)

- **TaxRecommendation:** id, taxType (INCOME_TAX, VAT, SOCIAL, HEALTH), title, explanation, potentialSaving, actionRequired, deadline, urgency (LOW–CRITICAL), legalReferences.
- SK pravidlá: paušál 60 % (max 20 000 €/rok), DPH od 49 790 €/rok, zdravotné 15 %, sociálne 33,15 % (ak > 6 798 €/rok), daň z príjmu 15 % / 25 %.
- Odporúčania: „Kúp teraz, ušetri na daniach“, optimálny čas fakturácie, DPH alert, odvody forecast.

### 4. Anomálie (anomaly_alert.dart)

- **AnomalyAlert:** id, type (DUPLICATE, UNUSUAL_AMOUNT, SUSPICIOUS_VENDOR, TIMING), title, description, relatedTransaction, anomalyScore 0–1, reasons, SuggestedResolution.
- Algoritmy: duplicate (rovnaká suma + vendor v krátkom čase), amount anomaly, timing anomaly, vendor anomaly, pattern break.

### 5. AI Chat (ai_chat_interface.dart)

- Podporované otázky: investície, najväčšie výdavky, odvody, DPH registrácia, porovnanie s minulým rokom.
- UI: FAB, bottom sheet, typing indicator, quick reply chips, voice input (speech_to_text).

### 6. Insight Dashboard (ai_dashboard_page.dart)

- Sekcie: „Dnes pre teba“ (top 3 insighty), „Predikcie na 30 dní“, „Daňové odporúčania“, „Zdravie financií“ (score 0–100), „Anomálie“ (alert bannery).
- Animácie: staggered, shimmer, pull-to-refresh, hero.

---

## FIREBASE ŠTRUKTÚRA

```text
users/{userId}/
  ├── ai_insights/
  ├── predictions/
  ├── tax_recommendations/
  ├── anomaly_alerts/
  ├── ai_conversations/
  └── learning_profile/
```

**Cloud Functions (fáza 3):** generateDailyInsights (6:00), processNewTransaction (trigger), sendPredictionNotification, monthlyTaxAnalysis (1. v mesiaci).

**Security rules:** Čítanie/zápis len pre prihláseného `userId` (žiadne verejné čítanie).

---

## PUSH NOTIFICÁCIE

- Predikcia: „O 3 dni ti príde faktúra ~€340“
- Daňový tip: „Kúp XY do konca mesiaca, ušetríš €95“
- Anomália: „Detekovaná nezvyčajná platba €500“
- Report: „Týždenný report je pripravený“

Použiť firebase_messaging + flutter_local_notifications, notification channels (Android), provisional authorization (iOS).

---

## TESTOVANIE

- Unit: prediction engine, tax rules, anomaly algoritmy.
- Integration: AI API (mock alebo test kľúč), Firebase.
- Widget: insight card, dashboard sekcie (loading, data, error, empty).
- Golden: AI dashboard, confidence meter.
- **Demo dáta:** DemoDataGenerator rozšíriť o predikcie, daňové odporúčania, anomálie (už čiastočne v demo_mode).

---

## BEZPEČNOSŤ A KONFIGURÁCIA

- **API kľúče:** Nikdy necommituť. Použiť `--dart-define`, Flutter env alebo CI secrets.
- **Príklad .env:** V `functions/` je `.env.example`; pre Flutter použiť napr. `--dart-define=GEMINI_API_KEY=xxx` alebo env súbor mimo repozitár.

---

## VÝSTUP IMPLEMENTÁCIE

1. README alebo sekcia v docs s inštrukciami na setup AI modulu.
2. Zoznam dependencies v pubspec.yaml (riverpod, http/dio, firebase_*, flutter_local_notifications, speech_to_text, …).
3. Firebase security rules pre nové kolekcie.
4. Príklad .env / dart-define pre API kľúče.
