# 📱 Google Play Store Submission Guide

Tento dokument obsahuje **presné odpovede a texty**, ktoré budeš potrebovať pri vypĺňaní formulárov v **Google Play Console**. Postupuj krok za krokom, aby nám to nezamietli.

---

## 1. Store Listing (Záznam v obchode)

Toto vidia používatelia v obchode. Aktuálne texty sú tiež v `GooglePlay_Release_Content/STORE_LISTING_SK.md`.

*   **App Name:** `BizAgent: Faktúry, AI & Dane`
*   **Short Description (max 80 znakov):** `Všetko pre SZČO: Faktúry, výdavky, dane a AI účtovný poradca v jednom.`
*   **Full Description:**
    ```text
    BizAgent je váš digitálny partner pre podnikanie na Slovensku. Inteligentná aplikácia pre moderných SZČO, freelancerov a malé firmy.

    Zabudnite na zložité excelovské tabuľky, krabice plné bločkov a drahé účtovné softvéry, ktorým nerozumiete. BizAgent vám pomôže riadiť celé podnikanie jednoducho, rýchlo a efektívne – priamo z vášho vrecka.

    Majte svoje financie pod kontrolou a nechajte umelú inteligenciu, nech vám pomôže s byrokraciou.

    ⭐ HLAVNÉ FUNKCIE:

    ✅ Profesionálna fakturácia: Vytvárajte faktúry a cenové ponuky v PDF na pár klikov. Posielajte ich klientom priamo z mobilu a sledujte, kto už zaplatil a kto mešká.

    ✅ Inteligentná evidencia výdavkov: Odfoťte blok a aplikácia si údaje uloží. Majte okamžitý poriadok v nákladoch bez prepisovania údajov.

    ✅ Osobný AI Účtovný Asistent: Váš poradca, ktorý nikdy nespí. Pýtajte sa nášho AI bota na dane, odvody, legislatívne zmeny alebo podnikateľské tipy 24/7.

    ✅ Prehľadné štatistiky: Sledujte svoje príjmy, výdavky, očakávané dane a cashflow v reálnom čase cez intuitívne grafy.

    ✅ Okamžitá kontrola firiem: Overte si IČO a DIČ obchodných partnerov cez slovenské verejné registre priamo v aplikácii. Vyhnite sa rizikovým spoluprácam.

    ✅ Maximálna bezpečnosť: Vaše dáta sú šifrované, bezpečne chránené a pravidelne zálohované.

    🎯 PRE KOHO JE BIZAGENT URČENÝ?
    • Živnostníci a SZČO (paušálne aj reálne výdavky)
    • Freelanceri a slobodné povolania
    • Majitelia malých s.r.o.
    • Každý, kto chce mať poriadok v podnikateľských financiách bez stresu.

    💡 PREČO SI VYBRAŤ BIZAGENT?
    • Navrhnuté špeciálne pre slovenskú legislatívu a podnikateľské prostredie.
    • Moderný dizajn a intuitívne ovládanie, ktoré zvládne každý.
    • Všetky dôležité nástroje v jednej aplikácii – ušetríte čas aj peniaze za viacero softvérov.

    Stiahnite si BizAgent ešte dnes a posuňte svoje podnikanie na vyššiu úroveň! Fakturujte jednoduchšie, podnikajte múdrejšie.
    ```

*   **Graphics:**
    *   **App Icon:** 512x512 PNG (máš v `assets/icon/app_icon_1024.png` - zmenši na 512)
    *   **Feature Graphic:** 1024x500 PNG – prompty v `GooglePlay_Release_Content/FEATURE_GRAPHIC_PROMPT.md`
    *   **Screenshots:** Rich Screenshots – prompty v `GooglePlay_Release_Content/SCREENSHOTS_PROMPTS.md`

---

## 2. App Content (Povinné formuláre)

V menu vľavo dole nájdeš sekciu **"App Content"** (Obsah aplikácie). Toto musíš vyplniť:

### 2.1 Privacy Policy (Zásady ochrany súkromia)
Pokiaľ nemáš web, otvor súbor `docs/PRIVACY_POLICY.md`, skopíruj text a vlož ho na [Flycricket](https://www.flycricket.com/) alebo Firebase Hosting.
*   **ODPORÚČANIE:** Play Store vyžaduje funkčnú URL. Lokálny súbor neakceptujú.
*   **Obsah:** Použi pripravený text z `docs/PRIVACY_POLICY.md`. Obsahuje všetky potrebné klauzuly pre "Finance" a "Camera" permissions.

### 2.2 Ads (Reklamy)
*   Otázka: *Does your app contain ads?*
*   Odpoveď: **No, my app does not contain ads.**

### 2.3 App Access (Prístup k aplikácii)
Pretože máme prihlásenie, Google Reviewer sa **MUSÍ** vedieť prihlásiť.
*   Vyber: **All or some functionality is restricted.**
*   Pridaj inštrukcie:
    *   **Username:** `bizbizagent@bizbizagent.com`
    *   **Password:** *(demo heslo; drž lokálne v `DEMO_ACCOUNT_SECRETS.txt`, neuvádzať do repozitára)*
    *   **Notes:** `This is a test account strictly for review purposes. It comes with pre-populated dummy data.`

### 🛑 2.3.1 Krok naviac: VYTVORENIE DEMO ÚČTU (Overenie funkčnosti)
Aby sa Google vedel prihlásiť, tento účet **MUSÍ EXISTOVAŤ** a byť typu **Email/Password**.

1.  Choď do **Firebase Console** -> **Authentication** -> **Users**.
2.  Klikni **"Add User"**.
3.  Email: `bizbizagent@bizbizagent.com`
4.  Heslo: *(použi lokálne demo heslo)*
5.  Klikni **"Add User"**.
6.  **Uisti sa**, že v stĺpci "Provider" vidíš ikonu obálky (Email), nie G (Google).
7.  **Hotovo.** Teraz je to na 100%.

### 2.4 Data Safety (Bezpečnosť údajov) - **KRITICKÉ**
Toto určuje, čo sa zobrazí v sekcii "Data Safety".

1.  **Data Collection:**
    *   *Does your app collect or share any of the required user data types?* -> **NEXT** (Áno, budeme špecifikovať).
2.  **Encryption:**
    *   *Is all of the user data collected by your app encrypted in transit?* -> **YES**.
3.  **Account Deletion:**
    *   *Do you provide a way for users to request that their data is deleted?* -> **YES** (zvyčajne cez email supportu v nastaveniach).

**Specific Data Types to Select:**

*   **Personal Info -> Email Address:**
    *   *Collected?* **Yes**
    *   *Shared?* **No**
    *   *Purpose:* **App functionality, Account management**
*   **Personal Info -> User IDs:**
    *   *Collected?* **Yes**
    *   *Shared?* **No** (ID v databáze sa neráta ako sharing 3. strane)
    *   *Purpose:* **App functionality**
*   **Financial Info -> Purchase History (Faktúry/Výdavky):**
    *   *Collected?* **Yes**
    *   *Shared?* **No**
    *   *Purpose:* **App functionality**
*   **Photos and Videos -> Photos:** (Pre skenovanie bločkov)
    *   *Collected?* **Yes**
    *   *Shared?* **No**
    *   *Purpose:* **App functionality**

### 2.5 Target Audience (Cieľová skupina)
*   Vyber: **18 and over**.
*   *Could your store listing appeal to children?* -> **No**.

### 2.6 News Apps (Spravodajstvo)
*   *Is your app a news app?* -> **No**.

### 2.7 COVID-19
*   *Is your app a COVID-19 app?* -> **My app is not a publicly available COVID-19 contact tracing or status app.**

---

## 3. Technické nastavenie (Release)

Keď vytvoríš **Production** alebo **Internal Testing** release:

1.  **Signing Key:** Ak sa pýta, zvoľ **Google Play App Signing** (odporúčané).
2.  **Upload:** Nahraj súbor `build/app/outputs/bundle/release/app-release.aab`.
3.  **Release Notes (SK):**
    ```text
    🎉 Prvé vydanie BizAgent!
    - Inteligentná správa faktúr a výdavkov
    - AI skenovanie bločkov
    - Daňové prehľady pre rok 2026
    ```

---

## 4. Čo ak to zamietnu? (Troubleshooting)

*   **"Login credentials missing":** Skontroluj sekciu 2.3 App Access. Uisti sa, že demo heslo máš uložené lokálne (napr. `DEMO_ACCOUNT_SECRETS.txt`) a v Play Console zadáš funkčné údaje.
*   **"Broken Functionality":** Uisti sa, že backend (Firebase) má nastavené pravidlá (Firestore Rules) tak, aby review účet mohol čítať/zapisovať.
*   **"Data Safety mismatch":** Skontroluj sekciu 2.4. Zvyčajne zabudnú ľudia priznať "Photos" pre skenovanie.

