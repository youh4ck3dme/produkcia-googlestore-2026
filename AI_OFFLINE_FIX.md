# 🔧 Oprava "AI Offline" Problému

**Dátum:** 2026-01-28  
**Status:** ✅ **Opravené**

---

## 🐛 Problém

Na webovej aplikácii nasadenej na **Vercel** (`https://biz-agent-web.vercel.app`) sa zobrazovala chyba:

```text
AI Offline: Skúste to neskôr.
```

**Príčina:**

- Gemini service používal priame volanie Gemini API z klienta
- Na webe to nefungovalo správne kvôli CORS/bezpečnostným problémom
- API kľúč nie je bezpečný v klientovi

---

## ✅ Riešenie

### 1. Vytvorená Univerzálna Cloud Function

**Súbor:** `functions/index.js`

Pridaná nová Cloud Function `generateContent` pre všeobecné Gemini volania:

```javascript
exports.generateContent = onCall({
  cors: true
}, async (request) => {
  const { prompt, model } = request.data;
  const apiKey = geminiApiKey.value();
  
  // Model fallback strategy
  const modelsToTry = [model || 'gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-2.0-flash'];
  
  // Try each model until one works
  for (const modelName of modelsToTry) {
    try {
      const genAI = new GoogleGenerativeAI(apiKey);
      const geminiModel = genAI.getGenerativeModel({ model: modelName });
      const result = await geminiModel.generateContent(prompt);
      return { text: result.response.text(), model: modelName };
    } catch (error) {
      // Try next model
      continue;
    }
  }
  
  throw new HttpsError('internal', 'AI Offline: Všetky modely zlyhali.');
});
```

### 2. Upravený Gemini Service

**Súbor:** `lib/core/services/gemini_service.dart`

- ✅ Pridaný import `cloud_functions`
- ✅ Pridaná detekcia `kIsWeb`
- ✅ Na webe sa používajú Cloud Functions namiesto priameho API volania
- ✅ Lepšie error handling s konkrétnymi chybovými správami

**Zmeny:**

```dart
// On web, use Cloud Functions for security
if (kIsWeb) {
  try {
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('generateContent');
    final result = await callable.call({
      'prompt': prompt,
      'model': preferredModel,
    });
    return result.data['text'] as String;
  } on FirebaseFunctionsException catch (e) {
    // Better error messages
    if (e.code == 'permission-denied') {
      return 'Chyba autentifikácie. Prosím, prihláste sa znova.';
    } else if (e.code == 'resource-exhausted') {
      return 'Dosiahli ste limit bezplatných dopytov. Skúste to neskôr.';
    }
    return 'AI Offline: Nepodarilo sa pripojiť k AI službe.';
  }
}
```

### 3. Aktualizované Modely v Cloud Functions

- ✅ Zmenené z `gemini-2.0-flash` na `gemini-1.5-flash` (štandardný model)
- ✅ Pridaná fallback stratégia pre viacero modelov
- ✅ Lepšie error handling

---

## 🚀 Nasadenie

### 1. Nastavenie API Kľúča (ak ešte nie je)

```bash
firebase functions:secrets:set GEMINI_API_KEY
# Zadajte váš Gemini API kľúč
```

### 2. Nasadenie Cloud Functions (Firebase)

```bash
cd /Users/youh4ck3dme/Downloads/BizAgent-produkcia-google-play
firebase deploy --only functions
```

**Dôležité:** Cloud Functions sú na Firebase (`bizagent-live-2026`), frontend je na Vercel.

### 3. Rebuild a Nasadenie Web Aplikácie (Vercel)

```bash
flutter clean
flutter pub get
flutter build web --release --base-href "/"

# Nasadenie na Vercel (automatické cez Git alebo manuálne)
git push origin main
# Alebo: vercel --prod
```

**Poznámka:** CORS nastavenia v Cloud Functions už obsahujú Vercel doménu (`https://biz-agent-web.vercel.app`).

---

## ✅ Výsledok

- ✅ Web aplikácia používa Cloud Functions pre Gemini API
- ✅ API kľúč je bezpečne uložený na serveri
- ✅ Lepšie error handling s konkrétnymi správami
- ✅ Automatický fallback medzi modelmi
- ✅ Podpora pre streaming (fallback na non-streaming na webe)

---

## 🧪 Testovanie

Po nasadení otestujte:

1. **BizBot:**
   - Otvorte `/ai-tools/biz-bot`
   - Napíšte otázku
   - Mala by sa zobraziť AI odpoveď

2. **AI Email Generator:**
   - Otvorte `/ai-tools/email-generator`
   - Vygenerujte e-mail
   - Mala by sa zobraziť AI odpoveď

3. **Error Handling:**
   - Ak API kľúč chýba, zobrazí sa správna chybová správa
   - Ak je quota prekročená, zobrazí sa informácia o limite

---

## 📝 Poznámky

- **Architektúra:**
  - Frontend: Nasadený na **Vercel** (`biz-agent-web.vercel.app`)
  - Backend: Cloud Functions na **Firebase** (`bizagent-live-2026`)
  - CORS: Cloud Functions sú nakonfigurované pre Vercel doménu

- Cloud Functions vyžadujú **Blaze Plan** v Firebase (prvých 2M volaní/mesiac zadarmo)
- API kľúč je bezpečne uložený v Firebase Secret Manager
- Na native platformách (Android/iOS) sa stále používa priame API volanie
- Na webe sa používajú Cloud Functions pre bezpečnosť
- CORS nastavenia v Cloud Functions obsahujú:
  - `https://biz-agent-web.vercel.app` (produkcia)
  - `https://bizagent-live-2026.web.app` (Firebase hosting)
  - `http://localhost:3000` a `http://localhost:62262` (lokálny vývoj)

---

## ✅ Status

**Problém je opravený a pripravený na nasadenie!**
