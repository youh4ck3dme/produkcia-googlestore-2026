# 📜 Privacy Policy / Zásady ochrany súkromia

**English version follows Slovak.**
**Slovenská verzia nasleduje po anglickej.**

---

## English Version

**Last updated: July 11, 2026**

This Privacy Policy describes how BizAgent ("we", "us", or "our") collects, uses, and discloses your information when you use our mobile application (the "App").

### 1. Information Collection and Use
For a better experience, while using our Service, we may require you to provide us with certain personally identifiable information:
*   **Email Address and Account Credentials:** Used for account authentication via Supabase Auth (email/password or Google Sign-In). Passwords are stored in hashed form.
*   **Business and Financial Data:** Invoices, expenses, client details, and business settings you enter are stored in Supabase PostgreSQL (EU region, eu-central-1) for synchronization across your devices.
*   **Receipt Images:** Photos of receipts you capture or upload are stored in Supabase Storage (`receipts/{userId}/…`).
*   **Camera and Photos:** Used to scan receipts and business documents. Text recognition runs on-device via Google ML Kit. Extracted text may be sent to our AI service for refinement (not the original image, unless you upload it as a receipt).
*   **AI Prompts and Chat History:** When you use AI features (BizBot, tax assistant, email generator, expense insights, etc.), your text prompts and relevant business context are sent to our Supabase Edge Function `generate-content`. BizBot conversation history is stored in Supabase (`bizbot_messages`).
*   **Analytics:** Anonymous usage statistics via Firebase Analytics (e.g., feature usage, onboarding funnel).
*   **In-App Purchases:** Subscription and one-time purchases are processed by Apple App Store or Google Play. We do not receive or store your payment card details.
*   **Encryption:** All data is transmitted over encrypted connections (HTTPS/TLS).

### 2. Service Providers
We employ third-party companies to operate the App:
*   **Supabase Inc.** (EU — eu-central-1): Authentication, database, file storage, and Edge Functions.
*   **Mistral AI** and **Google (Gemini):** Processing of AI prompts when you actively use AI features. Prompts are routed through our Supabase Edge Function; the primary provider is Mistral, with Gemini as fallback.
*   **Google:** ML Kit (on-device OCR), Firebase Analytics.
*   **Apple App Store / Google Play:** Payment processing for subscriptions and in-app purchases.
*   **Google Firebase / Firestore** (limited legacy use): IČO company lookup cache and expense categorization history.
*   **icoatlas.sk** (optional): Company registry lookups when enabled.

These third parties have access to your Personal Information only to perform these tasks on our behalf and are obligated not to disclose or use it for any other purpose.

### 3. AI Processing
When you use AI features, your text content is sent to our Supabase Edge Function, which forwards prompts to Mistral AI (primary) or Google Gemini (fallback). Prompts are limited to 10,000 characters and require an authenticated session. AI responses are informational only and do not constitute legal, tax, or professional advice. BizBot chat history is stored in our database until you delete your account.

### 4. Subscriptions and In-App Purchases
The App offers optional paid plans processed through Apple App Store or Google Play Billing:
*   `sub_pro_monthly`, `sub_pro_year` — Pro subscription
*   `sub_business_monthly` — Business subscription
*   `one_time_starter` — One-time purchase

Payment details are handled entirely by the platform store. You can manage or cancel subscriptions in your Apple or Google account settings.

### 5. Data Deletion
You can request deletion of your account and associated data at any time:
*   **In-app:** Settings → "Delete account and all data" (processed immediately via our `delete-account` Edge Function).
*   **Email:** `support@bizagent.sk` (GDPR requests: `gdpr@bizagent.sk`).
*   **Web:** https://bizagent.sk/delete-account.html

Upon request, account credentials, invoices, expenses, receipt files, BizBot history, and app settings are permanently removed from our databases.

### 6. Security
We take the security of your data seriously:
*   All data in transit is encrypted (TLS/SSL).
*   User data is stored on Supabase servers in the EU (eu-central-1), protected by authentication and Row Level Security (RLS).
*   Edge Functions require a valid authenticated session (JWT).

### 7. Contact Us
If you have any questions, contact us at `support@bizagent.sk` or `gdpr@bizagent.sk`. We respond within 30 days.

---

## Slovenská verzia

**Posledná aktualizácia: 11. júla 2026**

Tieto Zásady ochrany súkromia popisujú, ako BizAgent („my") zhromažďuje, používa a spracúva vaše informácie pri používaní mobilnej aplikácie („Aplikácia").

### 1. Zhromažďovanie a používanie informácií
Pre správne fungovanie aplikácie spracúvame tieto údaje:
*   **E-mailová adresa a prihlasovacie údaje:** Slúžia na autentifikáciu cez Supabase Auth (e-mail/heslo alebo Google Sign-In). Heslá sú uložené v hashovanej forme.
*   **Obchodné a finančné údaje:** Faktúry, výdavky, údaje o klientoch a nastavenia firmy, ktoré zadáte, sú uložené v Supabase PostgreSQL (región EÚ, eu-central-1) pre synchronizáciu medzi zariadeniami.
*   **Fotografie účteniek:** Snímky bločkov, ktoré odfotíte alebo nahrajete, sú uložené v Supabase Storage (`receipts/{userId}/…`).
*   **Fotoaparát a fotky:** Používajú sa na skenovanie bločkov a dokumentov. Rozpoznávanie textu prebieha na zariadení cez Google ML Kit. Extrahovaný text môže byť odoslaný na AI službu na spresnenie (nie pôvodný obrázok, pokiaľ ho nenahrajete ako účtenku).
*   **AI prompty a história chatu:** Pri používaní AI funkcií (BizBot, daňový asistent, generátor e-mailov, analýzy výdavkov atď.) sa vaše textové prompty a relevantný obchodný kontext odosielajú na Supabase Edge Function `generate-content`. História BizBot konverzácie je uložená v Supabase (`bizbot_messages`).
*   **Analytika:** Anonymné štatistiky používania cez Firebase Analytics (napr. použitie funkcií, onboarding).
*   **In-app nákupy:** Predplatné a jednorazové nákupy spracúva Apple App Store alebo Google Play. Neukladáme ani neprijímame údaje o platobnej karte.
*   **Šifrovanie:** Všetky údaje sú prenášané výhradne cez šifrované spojenia (HTTPS/TLS).

### 2. Poskytovatelia služieb
Aplikácia využíva služby tretích strán:
*   **Supabase Inc.** (EÚ — eu-central-1): Autentifikácia, databáza, úložisko súborov a Edge Functions.
*   **Mistral AI** a **Google (Gemini):** Spracovanie AI promptov pri aktívnom používaní AI funkcií. Prompty prechádzajú cez našu Supabase Edge Function; primárny poskytovateľ je Mistral, záložný Gemini.
*   **Google:** ML Kit (OCR na zariadení), Firebase Analytics.
*   **Apple App Store / Google Play:** Spracovanie platieb za predplatné a in-app nákupy.
*   **Google Firebase / Firestore** (obmedzené legacy použitie): Cache IČO lookupov a história kategorizácie výdavkov.
*   **icoatlas.sk** (voliteľné): Vyhľadávanie v obchodnom registri, ak je povolené.

Tieto strany majú prístup k vašim údajom len v nevyhnutnom rozsahu na vykonanie týchto úloh a sú viazané mlčanlivosťou.

### 3. Spracovanie AI
Pri používaní AI funkcií sa váš textový obsah odosiela na našu Supabase Edge Function, ktorá forwarduje prompty na Mistral AI (primárne) alebo Google Gemini (záložne). Prompty sú limitované na 10 000 znakov a vyžadujú prihlásenú reláciu. AI odpovede sú iba informatívne a nenahrádzajú právne, daňové ani odborné poradenstvo. História BizBot chatu je uložená v databáze do zmazania účtu.

### 4. Predplatné a in-app nákupy
Aplikácia ponúka voliteľné platené plány spracované cez Apple App Store alebo Google Play Billing:
*   `sub_pro_monthly`, `sub_pro_year` — Pro predplatné
*   `sub_business_monthly` — Business predplatné
*   `one_time_starter` — Jednorazový nákup

Platobné údaje spracúva výhradne platforma obchodu. Predplatné môžete spravovať alebo zrušiť v nastaveniach Apple alebo Google účtu.

### 5. Vymazanie údajov
O vymazanie účtu a súvisiacich údajov môžete požiadať kedykoľvek:
*   **V aplikácii:** Nastavenia → „Zmazať účet a všetky dáta" (spracované okamžite cez Edge Function `delete-account`).
*   **E-mail:** `support@bizagent.sk` (GDPR žiadosti: `gdpr@bizagent.sk`).
*   **Web:** https://bizagent.sk/delete-account.html

Po spracovaní žiadosti sú prihlasovacie údaje, faktúry, výdavky, súbory účteniek, história BizBot a nastavenia aplikácie trvalo odstránené z našich databáz.

### 6. Zabezpečenie
Bezpečnosť vašich údajov berieme vážne:
*   Všetky údaje pri prenose sú šifrované (TLS/SSL).
*   Údaje používateľov sú uložené na serveroch Supabase v EÚ (eu-central-1), chránené autentifikáciou a Row Level Security (RLS).
*   Edge Functions vyžadujú platnú prihlásenú reláciu (JWT).

### 7. Kontakt
V prípade otázok nás kontaktujte na `support@bizagent.sk` alebo `gdpr@bizagent.sk`. Odpovieme do 30 dní.
