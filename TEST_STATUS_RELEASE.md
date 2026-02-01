# Stav testov pred release (BizAgent_GooglePlay_Release)

ZIP **BizAgent_GooglePlay_Release.zip** by mal byť vytvorený **až po kompletnom otestovaní všetkých funkcií**.

## Aktuálny stav Flutter testov

- **Prešlo:** 261 testov  
- **Zlyhalo:** 7 testov  
- **Preskočené:** 2 testy  

Kým týchto 7 testov neprejde (alebo nie sú relevantné pre release), odporúčame buď ich opraviť, alebo vytvoriť ZIP so skriptom `./create_bizagent_googleplay_release_zip.sh --force` až po manuálnom otestovaní aplikácie.

---

## Zlyhávajúce testy

### 1. Kompilácia / API (test súbory nie sú v súlade s kódom)

- **`test/core/services/export_service_test.dart`**  
  - Chýbajúce/zmenené API: `ExportFormat`, `ExportType`, `ExportDataSource`, metódy ako `exportInvoicesToCSV`, `exportInvoicesToPDF`, `getSuggestedFileName`.  
  - Úprava: zosúladiť test s aktuálnym `ExportService` v `lib/`.

- **`test/firebase_functions/rate_limiting_cors_auth_test.dart`**  
  - `Undefined name 'anyString'` – pravdepodobne chýba import z mockovacej knižnice.  
  - Úprava: doplniť import alebo nahradiť `anyString` za konkrétny matcher.

- **`test/firebase_functions/error_handling_test.dart`**  
  - `package:firebase_functions/firebase_functions.dart` nie je nájdený; typy `FirebaseFunctions`, `HttpsCallable`, `FirebaseFunctionsException` atď.  
  - Úprava: pridať závislosť alebo spúšťať tento test len v prostredí s Firebase Functions SDK.

### 2. Widget / layout

- **`test/features/dashboard/dashboard_quick_actions_test.dart`**  
  - „RenderFlex overflowed by 99296 pixels“ v `BizGlassAppBar` (riadok v AppBar).  
  - Pravdepodobne neobmedzená šírka v testovom kontexte.  
  - Úprava: v teste obmedziť viewport (napr. `tester.binding.window.physicalSize`) alebo upraviť `biz_glass_appbar.dart` tak, aby sa obsah zmestil (napr. `Flexible`/`Expanded` alebo orezanie).

---

## Odporúčanie

1. **Opraviť** aspoň widget test (dashboard) a export_service_test, aby `flutter test` prebehol bez chýb.  
2. **Spustiť** `./comprehensive_test.sh` – mal by prejsť (Firestore/Storage rules už hľadajú v root).  
3. **Spustiť** `./create_bizagent_googleplay_release_zip.sh` (bez `--force`) – vytvorí sa ZIP len ak testy prejdú.  
4. Ak potrebuješ ZIP ešte pred opravou testov, po manuálnom otestovaní môžeš použiť `./create_bizagent_googleplay_release_zip.sh --force`.
