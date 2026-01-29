# Expense Intelligence & Analytics

Tento modul zabezpečuje inteligentné spracovanie a vizualizáciu firemných výdavkov.

## 1. Automatická Kategorizácia (`CategorizationService`)
Služba využíva sadu pravidiel (Heuristics & Regex) na priradenie kategórie na základe názvu dodávateľa.

### Úrovne istoty (Confidence Scores):
- **VYSOKÁ (95%)**: Presná zhoda s overeným dodávateľom (napr. Slovnaft -> Palivo, O2 -> Telekomunikácie).
- **STREDNÁ (70%)**: Zhoda na základe kľúčových slov v popise.
- **NÍZKA (30-50%)**: Odhad na základe analýzy textu.

### Implementácia:
Nachádza sa v `lib/features/expenses/services/categorization_service.dart`. Podporuje viac ako 35 kategórií špecifických pre slovenský trh.

## 2. Expense Analytics
Vizualizácia dát pomocou knižnice `fl_chart`.

- **Pie Chart**: Zobrazuje percentuálne rozdelenie výdavkov podľa kategórií. Sekcie sú interaktívne.
- **Bar Chart**: Zobrazuje vývoj výdavkov v čase (týždenný/mesačný pohľad).
- **Summary Cards**: Rýchly prehľad celkovej sumy a počtu transakcií za zvolené obdobie.

Obrazovka: `lib/features/expenses/screens/expense_analytics_screen.dart`.

## 3. Pokročilé Filtrovanie (`ExpenseFilterSheet`)
Umožňuje používateľom dynamicky zužovať zoznam výdavkov bez straty dát.

- **Kategórie**: Multi-výber kategórií.
- **Dátumový rozsah**: Vyhľadávanie v konkrétnom období (ShowDateRangePicker).
- **Rozsah sumy**: Range Slider pre sumu od-do.
- **Zoradenie**: Podľa dátumu (najnovšie/najstaršie) a sumy (vzostupne/zostupne).

## 4. Správa Účteniek
- **OCR Skenovanie**: Integrované s ML Kit pre extrakciu textu a sumy.
- **Cloud Storage**: Účtenky sú nahrávané do Firebase Storage v štruktúre `users/{id}/receipts/`.
- **Receipt Viewer**: Realizovaný pomocou `InteractiveViewer` pre plynulý zoom a panovanie na mobile aj webe.
