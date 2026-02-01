# 🧪 Rýchle Testovacie Príkazy

## 0. Demo & AI modul (všetky prechádzajú)

```bash
flutter test test/e2e/ test/integration/demo_integration_test.dart test/performance/ test/golden/
```

*Poznámka:* Pri plnom `flutter test` môžu zlyhať 2 existujúce testy (`create_invoice_screen_ai_test`, `dashboard_quick_actions_test`); nie sú súčasťou demo/AI modulu.

---

## 1. Test Cloud Functions (Bash)

```bash
./test_cloud_functions.sh
```

## 2. Test Gemini API (Node.js)

```bash
node test_gemini_direct.js
```

## 3. Test Gemini API (Dart)

```bash
dart test_firebase_functions.dart
```

## 4. Manuálne Testy v Konzole

### A) Overenie nasadených funkcií

```bash
firebase functions:list --project bizagent-live-2026
```

### B) Overenie API kľúča

```bash
firebase functions:secrets:access GEMINI_API_KEY --project bizagent-live-2026
```

### C) Test volania funkcie (curl)

```bash
curl -X POST \
  https://us-central1-bizagent-live-2026.cloudfunctions.net/generateContent \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "prompt": "Napíš krátku odpoveď: Čo je BizAgent?",
      "model": "gemini-1.5-flash"
    }
  }'
```

### D) Test v Browser Console (JavaScript)

```javascript
// Otvorte https://biz-agent-web.vercel.app a spustite v konzole:

const testGemini = async () => {
  const functions = firebase.functions();
  const generateContent = functions.httpsCallable('generateContent');
  
  try {
    const result = await generateContent({
      prompt: 'Napíš krátku odpoveď: Čo je BizAgent?',
      model: 'gemini-1.5-flash'
    });
    
    console.log('✅ ÚSPECH:', result.data);
    return result.data.text;
  } catch (error) {
    console.error('❌ CHYBA:', error);
    return null;
  }
};

testGemini();
```

## 5. Test v Flutter App (Debug Console)

```dart
// V debug konzole Flutter aplikácie:

import 'package:cloud_functions/cloud_functions.dart';

final functions = FirebaseFunctions.instance;
final callable = functions.httpsCallable('generateContent');

final result = await callable.call({
  'prompt': 'Napíš krátku odpoveď: Čo je BizAgent?',
  'model': 'gemini-1.5-flash',
});

print('✅ Odpoveď: ${result.data['text']}');
```

## 6. Test v Firebase Console

1. Otvorte: <https://console.firebase.google.com/project/bizagent-live-2026/functions>
2. Kliknite na `generateContent` funkciu
3. Kliknite na "Test" tab
4. Zadajte test data:

```json
{
  "prompt": "Napíš krátku odpoveď: Čo je BizAgent?",
  "model": "gemini-1.5-flash"
}
```

1. Kliknite "Test the function"

---

## ✅ Očakávané Výsledky

- **Status 200**: Funkcia funguje správne Funkcia funguje správne
- **Status 403/401**: Chýba autentifikácia alebo API kľúč
- **Status 500**: Chyba v Cloud Function (skontrolujte logs)

## 📋 Kontrola Logov

```bash
firebase functions:log --project bizagent-live-2026
```

Alebo v Firebase Console: <https://console.firebase.google.com/project/bizagent-live-2026/functions/logs>
