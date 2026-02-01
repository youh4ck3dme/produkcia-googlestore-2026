# BizAgent 🚀

## AI Business Assistant pre SZČO a malé firmy na Slovensku

[![Flutter](https://img.shields.io/badge/Flutter-3.13.0+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Passing-success)](https://github.com/youh4ck3dme/BizAgent/actions)

> Kompletné riešenie pre faktúry, výdavky a účtovníctvo – špeciálne navrhnuté pre slovenský trh a legislatívu.

---

## 📚 Dokumentácia

* **[Google Play Submission Guide](docs/GOOGLE_PLAY_SUBMISSION.md):** Podrobný návod, ako vyplniť formuláre (Data Safety, App Access) v Play Console.
* **[Privacy Policy Template](docs/PRIVACY_POLICY.md):** Pripravený text pre Zásady ochrany súkromia (potrebné pre Play Store).
* **[Release Checklist](docs/RELEASE_CHECKLIST.md):** Finálny checklist pred publikovaním.
* **[Demo Account Setup](docs/DEMO_ACCOUNT_SETUP.md):** Návod na vytvorenie demo účtu pre Google Play review.
* **[Testovacia stratégia](docs/TESTING_STRATEGY.md):** Čo testovať a ako.
* **[Testovanie (TESTING.md)](docs/TESTING.md):** Unit/widget testy, **Demo Mode & AI E2E testy**, golden a performance testy.
* **[Špecifikácia AI Accountant](docs/AI_ACCOUNTANT_SPEC.md):** Architektúra a požiadavky pre modul AI účtovníka (predikcie, daňové odporúčania, anomálie, chat).
* **[Finálny stav testov](TESTING_FINAL_STATUS.md):** Štatistiky a prehľad testov (262+ prechádza).

---

## 📂 Setup po rozbalení projektu (unzip)

Ak máš projekt ako **zip** (napr. `BizAgent_GooglePlay_Release.zip`):

1. **Rozbaľ** zip do priečinka (napr. `~/Projects/BizAgent`).
2. **Otvor v editore** presne ten priečinok, kde je v koreni súbor **`pubspec.yaml`** (a priečinky `lib/`, `test/`, `android/`, …). Ten je koreňom Flutter projektu.
3. **Nainštaluj závislosti a spusti:**

   ```bash
   cd /cesta/k/priečinku/s/pubspec.yaml
   flutter pub get
   flutter run -d chrome   # alebo -d android
   ```

4. **Testy:** `flutter test` (vrátane demo/E2E testov).

---

## 🚀 Ako to všetko spustiť a otestovať

### Prerekvizity

* **Flutter SDK** 3.13+ ([flutter.dev](https://flutter.dev))
* **Firebase CLI** (voliteľné pre emulator / deploy): `npm install -g firebase-tools`
* **Node.js** (pre Cloud Functions): odporúča sa LTS (napr. 20.x)

### 1. Inštalácia

```bash
# Závislosti Flutter
flutter pub get

# Cloud Functions (ak budeš spúšťať alebo testovať funkcie)
cd functions && npm install && npm run build && cd ..
```

### 2. Spustenie aplikácie

**Web (Chrome, port 5050):**

```bash
flutter run -d chrome --web-port=5050
```

**Android (emulátor alebo zariadenie):**

```bash
flutter run -d android
```

**iOS (Mac + Xcode):**

```bash
flutter run -d ios
```

### 3. Spustenie unit testov

**Všetky unit/widget testy (odporúčané pred každým release):**

```bash
flutter test
```

**Len konkrétna skupina (rýchle overenie):**

```bash
# Billing + Receipt Storage
flutter test test/features/billing/ test/features/expenses/receipt_storage_service_test.dart

# Auth
flutter test test/features/auth/

# Core služby
flutter test test/core/
```

**S coverage reportom:**

```bash
flutter test --coverage
# Otvor coverage: open coverage/lcov.info (alebo použiť napr. lcov/genhtml)
```

### 4. Komplexná kontrola (skript)

Skript overí súbory, konfiguráciu a odporúčané kroky pred release:

```bash
./comprehensive_test.sh
```

### 5. Integračné a E2E testy

**Integračné testy** (vyžadujú spustenú aplikáciu alebo emulátor):

```bash
flutter test integration_test/
```

**E2E / Demo / Performance / Golden testy** (bežia bez emulátora, odporúčané pred release):

```bash
flutter test test/e2e/          # Demo mode, AI insights, Receipt Detective
flutter test test/integration/  # DemoScenarioRunner, konzistencia dát
flutter test test/performance/  # Časové limity generátorov
flutter test test/golden/       # UI regression (SmartInsightsWidget)
```

Podrobnosti: [docs/TESTING.md – Demo Mode & AI Testing Module](docs/TESTING.md).

### 5b. Demo mód v aplikácii

Pre **prezentácie a testovanie** bez reálnych dát:

* **Aktivácia:** **triple tap** na názov aplikácie v AppBar (dashboard).
* **Správanie:** výdavky, faktúry a AI insighty sa nahradia realistickými demo dátami (6 mesiacov, viac scenárov).
* **Indikátor:** v AppBar sa zobrazí chip **„Demo“**.
* **Vypnutie:** opätovný triple tap.

### 6. Firebase Emulator (voliteľné)

Pre lokálne testovanie Firestore / Storage / Functions bez produkčných dát:

```bash
firebase emulators:start --only firestore,storage,functions
```

V aplikácii potom treba smerovať na emulator (napr. cez `FIRESTORE_EMULATOR_HOST` alebo konfig v kóde).  
Plný upload napr. Receipt Storage sa dá otestovať s `--only storage`.

### 7. Rýchle príkazy – súhrn

| Úloha | Príkaz |
| ----- | ------ |
| Spustiť web | `flutter run -d chrome --web-port=5050` |
| Spustiť Android | `flutter run -d android` |
| Všetky testy | `flutter test` |
| E2E / demo testy | `flutter test test/e2e/` |
| Golden testy | `flutter test test/golden/` |
| Komplexná kontrola | `./comprehensive_test.sh` |
| Build AAB (release) | `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols` |
| Viac testovacích príkazov | Pozri [QUICK_TEST_COMMANDS.md](QUICK_TEST_COMMANDS.md) |

---

## 🚀 Rýchly Štart (Development) – skrátený

1. **Prerekvizity:** Flutter 3.13+, voliteľne Firebase CLI a Node.js (pre functions).
2. **Inštalácia:** `flutter pub get` (a v `functions/` pri potrebe `npm install && npm run build`).
3. **Spustenie (Web):** `flutter run -d chrome --web-port=5050`.
4. **Spustenie (Android):** `flutter run -d android`.
5. **Testy:** `flutter test` (pred release odporúčané).

---

## 📦 Build & Release (Production)

### 🤖 Android (Google Play)

Toto vytvorí optimalizovaný, obfuskovaný `.aab` balíček pripravený na upload.

#### Podpisovanie (Upload key) – 100% nutné pre Google Play

Google Play vyžaduje **podpísaný** release build. Tento projekt používa Android signing cez:

- **Keystore**: `android/app/upload-keystore.jks` *(NECOMMITOVAŤ)*
- **Config**: `android/key.properties` *(NECOMMITOVAŤ)*
- **Šablóna**: `android/key.properties.example`

Rýchly spôsob (vytvorí nový upload keystore + config, bez vypisovania hesla do terminálu):

```bash
./setup_android_play_signing.sh
```

Poznámka: Skript uloží informáciu o cestách do `android/KEYSTORE_SECRETS.txt` (tento súbor je tiež v `.gitignore`).

Ak chceš manuálne:

1) Skopíruj šablónu:

```bash
cp android/key.properties.example android/key.properties
```

2) Vytvor `android/app/upload-keystore.jks` (alebo použi vlastný) a nastav hodnoty v `android/key.properties`.

Odporúčanie: maj zapnuté **Play App Signing** a tento kľúč používaj ako **upload key**.

```bash
flutter build appbundle \
  --release \
  --obfuscate \
  --split-debug-info=build/symbols
```

* **Výstup:** `build/app/outputs/bundle/release/app-release.aab`
* **Next Step:** Upload do [Google Play Console](https://play.google.com/console). Pozri [Submission Guide](docs/GOOGLE_PLAY_SUBMISSION.md).

### 🌐 Web (PWA)

```bash
flutter build web --release \
  --web-renderer canvaskit \
  --pwa-strategy offline-first \
  --dart-define=FLUTTER_WEB_USE_SKIA=true
```

* **Deploy:** `firebase deploy --only hosting`

---

## 🚀 Google Play Upload

**Status:** ✅ Pripravené na upload

### Finálny Checklist

* [ ] **[GOOGLE_PLAY_UPLOAD_CHECKLIST.md](./GOOGLE_PLAY_UPLOAD_CHECKLIST.md)** - Kompletný krok-za-krokom návod
* [ ] Demo účet: `bizbizagent@bizbizagent.com` (pozri [DEMO_ACCOUNT_SETUP.md](./docs/DEMO_ACCOUNT_SETUP.md))
* [ ] Android build: `flutter build appbundle --release`
* [ ] Všetky testy prešli: `./comprehensive_test.sh`

### Dokumentácia

* **[Google Play Upload Checklist](./GOOGLE_PLAY_UPLOAD_CHECKLIST.md):** Finálny checklist pre upload
* **[Google Play Submission Guide](./docs/GOOGLE_PLAY_SUBMISSION.md):** Podrobný návod na formuláre
* **[Release Checklist](./docs/RELEASE_CHECKLIST.md):** Pre-launch kontrola
* **[Demo Account Setup](./docs/DEMO_ACCOUNT_SETUP.md):** Vytvorenie demo účtu

---

## ✅ TODO: Čo treba ešte dokončiť? (Post-Release)

Tieto kroky sú potrebné pre plnú produkčnú prevádzku, ale aplikácia funguje aj bez nich (v obmedzenom alebo testovacom režime).

### 1. 🛡️ ReCaptcha Enterprise (Security)

* **[Setup Guide](docs/RECAPTCHA_SETUP.md):** Podrobné inštrukcie a API kľúče pre tvoj projekt (`bizagent-live-2026`).
* Configurované v `web/index.html`.
* [ ] **Backend Verification:** Implementuj Cloud Function podľa návodu v `docs/RECAPTCHA_SETUP.md` (ak nepoužívaš Firebase App Check).

### 2. 📧 Production Mail Server (SendGrid/Postmark)

Momentálne emaily (faktúry) chodia cez predvolený Firebase/Google SMTP alebo testovací server.

* [ ] Integrovať dedikovanú službu (napr. SendGrid) pre vyššiu doručiteľnosť faktúr klientom.

### 3. 🍎 iOS Verzia (Apple App Store)

Android (`.aab`) je hotový. Pre iOS treba:

* [ ] Mac s Xcode.
* [ ] Apple Developer Account (99$/rok).
* [ ] Spustiť `flutter build ipa`.

### 4. 💳 IČ DPH Validácia (VIES API)

Súčasné overovanie IČO je napojené na Slovensko.Digital.

* [ ] Pre obchodovanie s EU pridať validáciu cez VIES (EU Commission API) pre automatické overenie DPH.

---

## ✨ Kľúčové Funkcie (Features)

### 📄 Faktúry

* Generovanie **PDF** v reálnom čase.
* **QR kódy (PAY by square)** pre slovenské banky.
* Automatické číslovanie a sledovanie splatnosti.

### 🤖 AI Magic Scan

* Skenovanie bločkov kamerou.
* Vyčítanie sumy, dátumu a firmy cez Google ML Kit / Gemini.

### 📊 Daňový Teplomer

* Sledovanie obratu za 12 mesiacov vs. limit **49 790 €**.
* Upozornenie na povinnosť registrácie DPH.

### 🔒 Bezpečnosť

* Dáta uložené v **Cloud Firestore** (Google Cloud).
* Šifrovaný prenos (SSL).
* Prihlásenie cez Google / Apple / Email.

---

## Made with ❤️ for Slovak entrepreneurs
