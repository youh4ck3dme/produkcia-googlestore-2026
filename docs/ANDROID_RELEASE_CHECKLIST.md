# Android Release Checklist (Manuálny Build)

Keďže na vašom Macu chýba **Android SDK**, posledný krok (build) musíte spraviť vy po inštalácii Android Studia.

## 1. Príprava Prostredia
- [ ] Stiahnite a nainštalujte **[Android Studio](https://developer.android.com/studio)**.
- [ ] Otvorte Android Studio -> Settings -> Languages & Frameworks -> Android SDK.
- [ ] Uistite sa, že máte nainštalované **SDK Platforms** (Android 14/15) a **SDK Tools** (Command line tools).
- [ ] Nastavte premennú `ANDROID_HOME` (ak treba).

## 2. Dokončenie Buildu
Otvorte terminál v projekte `BizAgent` a spustite:

```bash
flutter build appbundle --release
```

Ak všetko prebehne úspešne, nájdete súbor tu:
`build/app/outputs/bundle/release/app-release.aab`
*(Tento súbor sa nahráva do Google Play).*

## 3. Google Play Console ("Papierovačky")

### Vytvorenie Aplikácie
- [ ] Choďte na [Google Play Console](https://play.google.com/console).
- [ ] Vytvorte novú aplikáciu ("BizAgent").
- [ ] Jazyk: **Slovenčina (sk)**.

### Store Listing
- [ ] **App Name:** BizAgent
- [ ] **Short Description:** AI Asistent pre SZČO
- [ ] **Full Description:** (Popíšte funkcie OCR, AI Email, Faktúry...)
- [ ] **Graphics:**
    - Ikona: `google_play_assets/icon/hi-res-icon.png` (512x512)
    - Feature Graphic: `google_play_assets/feature_graphic.png` (1024x500 - *treba vytvoriť*)
    - Screenshots: `google_play_assets/screenshots/` (Phone & Tablet).

### Data Safety (Dôležité!)
Google sa bude pýtať na dáta. Odpovede:
- [ ] **Does your app collect or share any user data?** -> **Yes**
- [ ] **Is all of the user data collected encrypted in transit?** -> **Yes** (Firebase HTTPS)
- [ ] **Can users request that their data be deleted?** -> **Yes**
- [ ] **Data Types:**
    - Name, Email, User IDs (App Functionality, Account Management).
    - Photos/Videos (ak používate OCR bločkov).

### Privacy Policy
- [ ] Vložte URL na Privacy Policy.
- [ ] *Tip:* Môžete použiť text z `docs/PRIVACY_POLICY.md` a dať ho na web (napr. `https://bizagent-live-2026.web.app/privacy-policy.html`).

## 4. Internal Testing
- [ ] V menu "Testing" -> "Internal testing".
- [ ] "Create new release".
- [ ] Nahrajte `app-release.aab`.
- [ ] Pridajte testerov (svoj email).
- [ ] Hotovo! Link pošlite sebe a stiahnite appku do mobilu.
