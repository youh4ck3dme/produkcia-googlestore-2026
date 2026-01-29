# 📝 Registrácia Firebase & Google Cloud pre BizAgent

Tento návod ťa krok za krokom prevedie vytvorením a nastavením Firebase projektu, ktorý je potrebný pre fungovanie aplikácie (prihlásenie, databáza, úložisko faktúr).

---

## 1. Vytvorenie Firebase Projektu
1.  Otvori v prehliadači [Firebase Console](https://console.firebase.google.com/).
2.  Klikni na **"Create a project"** (alebo "Add project").
3.  Zadaj názov projektu: `BizAgent`.
4.  Klikni na **Continue**.
5.  V kroku "Google Analytics" vypni prepínač **Enable Google Analytics for this project** (pre MVP to nepotrebujeme) a klikni na **Create project**.
6.  Počkajte chvíľu a keď bude projekt hotový, klikni na **Continue**.

---

## 2. Aktivácia Autentifikácie (Google Login)
1.  V ľavom menu klikni na **Build** -> **Authentication**.
2.  Klikni na **Get started**.
3.  V záložke **Sign-in method** vyber **Google**.
4.  Zapni prepínač **Enable**.
5.  Vyber "Project support email" (tvoj Gmail) zo zoznamu.
6.  Klikni na **Save**.

---

## 3. Vytvorenie Databázy (Firestore)
1.  V ľavom menu klikni na **Build** -> **Firestore Database**.
2.  Klikni na **Create database**.
3.  Vyber lokalitu (Location). Odporúčam **`eur3 (europe-west)`** pre najlepšiu odozvu na Slovensku.
4.  Klikni na **Next**.
5.  Vyber **Start in production mode**.
6.  Klikni na **Create**.

---

## 4. Nastavenie Úložiska (Storage)
Slúži na ukladanie fotiek bločkov.
1.  V ľavom menu klikni na **Build** -> **Storage**.
2.  Klikni na **Get started**.
3.  Zvoľ **Start in production mode**.
4.  Klikni na **Next**.
5.  Lokalitu nechaj rovnakú ako pri databáze (`eur3`) a klikni na **Done**.

---

## 5. Získanie Konfiguračných Kľúčov (Pre Web/PWA)
Teraz prepojíme Firebase s tvojou aplikáciou.
1.  V ľavom hornom rohu (vedľa nápisu "Project Overview") klikni na **ozubené koliesko** ⚙️ -> **Project settings**.
2.  Scrolluj dole k sekcii **Your apps**.
3.  Klikni na ikonu **Web** (symbol `</>`).
4.  Do "App nickname" napíš `BizAgent Web`.
5.  Klikni na **Register app**.
6.  Zobrazí sa ti kód `const firebaseConfig = { ... }`. Z tade budeš potrebovať hodnoty.

---

## 6. Vloženie kľúčov do aplikácie
Otvori súbor `lib/firebase_options.dart` v tvojom projekte a nahraď hodnoty `REPLACE_ME` v sekcii `static const FirebaseOptions web` týmito údajmi z Firebase konzoly:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'SEM_VLOZ_API_KEY',           // apiKey
  authDomain: 'SEM_VLOZ_AUTH_DOMAIN',   // authDomain
  projectId: 'SEM_VLOZ_PROJECT_ID',     // projectId
  storageBucket: 'SEM_VLOZ_STORAGE',    // storageBucket
  messagingSenderId: 'SEM_VLOZ_SENDER', // messagingSenderId
  appId: 'SEM_VLOZ_APP_ID',             // appId
);
```

> **Poznámka:** Ostatné platformy (android, ios, macos) môžeš nechať s `REPLACE_ME`, ak budeš aplikáciu používať len ako Web/PWA.

---

## 7. Hotovo! 🚀
Teraz stačí aplikáciu reštartovať (`R` v termináli) a prihlásiť sa cez Google tlačidlo. Dáta sa budú ukladať do tvojej novej databázy.
