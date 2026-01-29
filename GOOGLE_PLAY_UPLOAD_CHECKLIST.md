# 🚀 Google Play Upload - Finálny Checklist

**Dátum:** 2026-01-28  
**Verzia:** 1.0.1+2

## ✅ Pred Uploadom

### 1. Demo Účet v Firebase
- [ ] **Účet existuje:** `bizbizagent@bizbizagent.com`
- [ ] **Heslo:** `1369#1369#1369#`
- [ ] **Provider:** Email/Password (nie Google Sign-In!)
- [ ] **Overenie:** Skús sa prihlásiť v aplikácii s týmito údajmi
- [ ] **Pozri:** [DEMO_ACCOUNT_SETUP.md](./docs/DEMO_ACCOUNT_SETUP.md) pre podrobnosti

### 2. Android Build
- [ ] **Vytvoriť AAB súbor:**
  ```bash
  flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
  ```
- [ ] **Overiť súbor:** `build/app/outputs/bundle/release/app-release.aab`
- [ ] **Veľkosť:** Mala by byť < 50MB

### 3. Testovanie
- [ ] **Spustiť komplexný test:**
  ```bash
  ./comprehensive_test.sh
  ```
- [ ] **Všetky testy prešli:** 35+ passed, 0 failed

## 📱 Google Play Console - Krok za Krokom

### Krok 1: Vytvorenie Aplikácie
- [ ] Choď na [Google Play Console](https://play.google.com/console)
- [ ] Klikni **"Create app"** (Vytvoriť aplikáciu)
- [ ] **App name:** `BizAgent - Faktúry a Výdavky`
- [ ] **Default language:** Slovenčina (sk)
- [ ] **App or game:** App
- [ ] **Free or paid:** Free
- [ ] Klikni **"Create"**

### Krok 2: Store Listing
- [ ] **App name:** `BizAgent - Faktúry a Výdavky`
- [ ] **Short description:** `AI asistent pre slovenských podnikateľov. Faktúry, skenovanie bločkov a daňové prehľady.`
- [ ] **Full description:** Skopíruj z [GOOGLE_PLAY_SUBMISSION.md](./docs/GOOGLE_PLAY_SUBMISSION.md#1-store-listing-záznam-v-obchode)
- [ ] **App icon:** 512x512 PNG (`assets/icon/app_icon_1024.png` - zmenšiť)
- [ ] **Feature graphic:** 1024x500 PNG (treba vytvoriť)
- [ ] **Screenshots:** Nahraj screenshoty z Dashboardu, Faktúry a Skenovania
- [ ] **Kategória:** Business / Finance
- [ ] **Contact email:** Tvoj email

### Krok 3: App Content (KRITICKÉ!)

#### 3.1 Privacy Policy
- [ ] **Privacy Policy URL:** 
  - Vlož URL na Privacy Policy (musí byť verejne dostupná!)
  - Text je v `docs/PRIVACY_POLICY.md`
  - Môžeš ho dať na Firebase Hosting alebo iný web

#### 3.2 Ads
- [ ] **Does your app contain ads?** → **No**

#### 3.3 App Access (DÔLEŽITÉ!)
- [ ] **All or some functionality is restricted?** → **Yes**
- [ ] **Username:** `bizbizagent@bizbizagent.com`
- [ ] **Password:** `1369#1369#1369#`
- [ ] **Notes:** `This is a test account strictly for review purposes. It comes with pre-populated dummy data.`

#### 3.4 Data Safety (KRITICKÉ!)
- [ ] **Does your app collect or share any user data?** → **Yes**
- [ ] **Is all data encrypted in transit?** → **Yes**
- [ ] **Can users request data deletion?** → **Yes**

**Data Types to Select:**
- [ ] **Personal Info → Email Address:**
  - Collected: **Yes**
  - Shared: **No**
  - Purpose: **App functionality, Account management**
- [ ] **Personal Info → User IDs:**
  - Collected: **Yes**
  - Shared: **No**
  - Purpose: **App functionality**
- [ ] **Financial Info → Purchase History:**
  - Collected: **Yes** (Faktúry/Výdavky)
  - Shared: **No**
  - Purpose: **App functionality**
- [ ] **Photos and Videos → Photos:**
  - Collected: **Yes** (Pre skenovanie bločkov)
  - Shared: **No**
  - Purpose: **App functionality**

#### 3.5 Target Audience
- [ ] **Age:** 18 and over
- [ ] **Could your store listing appeal to children?** → **No**

#### 3.6 News Apps
- [ ] **Is your app a news app?** → **No**

#### 3.7 COVID-19
- [ ] **Is your app a COVID-19 app?** → **My app is not a publicly available COVID-19 contact tracing or status app.**

### Krok 4: Release

#### 4.1 Internal Testing (Odporúčané najprv)
- [ ] Choď na **Testing → Internal testing**
- [ ] Klikni **"Create new release"**
- [ ] **Upload AAB:** Nahraj `build/app/outputs/bundle/release/app-release.aab`
- [ ] **Release notes (SK):**
  ```
  🎉 Prvé vydanie BizAgent!
  - Inteligentná správa faktúr a výdavkov
  - AI skenovanie bločkov
  - Daňové prehľady pre rok 2026
  ```
- [ ] **Add testers:** Pridaj svoj email
- [ ] **Review and release**
- [ ] **Otestuj:** Stiahni aplikáciu cez testovací link

#### 4.2 Production Release
- [ ] Po úspešnom teste v Internal testing
- [ ] Choď na **Production**
- [ ] Klikni **"Create new release"**
- [ ] **Upload AAB:** Nahraj rovnaký súbor
- [ ] **Release notes:** Rovnaké ako vyššie
- [ ] **Review and release**

## ⚠️ Časté Problémy a Riešenia

### "Login credentials missing"
- Skontroluj, že demo účet existuje v Firebase Console
- Over, že provider je Email/Password (nie Google)
- Skús sa prihlásiť manuálne v aplikácii

### "Broken Functionality"
- Skontroluj Firebase Security Rules
- Over, že Cloud Functions sú nasadené
- Skontroluj Firebase Console logs

### "Data Safety mismatch"
- Skontroluj, že máš zaškrtnuté všetky zbierané dáta
- Nezabudni na "Photos" pre OCR skenovanie
- Over, že "Email" je zaškrtnuté pre Auth

### "Privacy Policy URL not accessible"
- URL musí byť verejne dostupná (bez prihlásenia)
- Skontroluj, že URL funguje v Incognito móde
- Môžeš použiť Firebase Hosting alebo GitHub Pages

## 📋 Post-Upload Checklist

Po nahratí aplikácie:

- [ ] **Monitoruj:** Firebase Console > Analytics > Events
- [ ] **Sleduj:** Firebase Console > Crashlytics
- [ ] **Kontroluj:** Google Play Console > Statistics
- [ ] **Odpovedaj:** Na recenzie používateľov (ak nejaké budú)

## 🎯 Finálny Status

- [ ] Všetky checkboxy sú zaškrtnuté
- [ ] Demo účet funguje
- [ ] AAB súbor je nahraný
- [ ] Všetky formuláre sú vyplnené
- [ ] Aplikácia je v Production release

**Ak všetko vyššie je hotové, aplikácia je pripravená na publikovanie! 🚀**

---

## 📚 Súvisiace Dokumenty

- [GOOGLE_PLAY_SUBMISSION.md](./docs/GOOGLE_PLAY_SUBMISSION.md) - Podrobný návod
- [RELEASE_CHECKLIST.md](./docs/RELEASE_CHECKLIST.md) - Pre-launch checklist
- [DEMO_ACCOUNT_SETUP.md](./docs/DEMO_ACCOUNT_SETUP.md) - Demo účet setup
- [PRIVACY_POLICY.md](./docs/PRIVACY_POLICY.md) - Privacy Policy text
