# 🧪 Production API Test Guide

Tento dokument popisuje, ako otestovať všetky produkčné API a Firebase nastavenia pred Google Play uploadom.

## 📋 Prehľad Testov

### 1. Firebase Konfigurácia
- ✅ Firebase CLI nainštalované
- ✅ Prihlásený do Firebase
- ✅ Projekt nastavený na `bizagent-live-2026`
- ✅ `firebase_options.dart` obsahuje správne API kľúče

### 2. Firestore Databáza
- ✅ Security Rules sú správne nastavené
- ✅ Kolekcie: `users`, `invoices`, `expenses`
- ✅ Pravidlá pre autentifikáciu a autorizáciu

### 3. Firebase Storage
- ✅ Security Rules sú správne nastavené
- ✅ User-scoped prístup (`/users/{userId}/`)

### 4. Cloud Functions
- ✅ `generateEmail` - Generovanie e-mailov cez Gemini
- ✅ `analyzeReceipt` - Analýza bločkov cez Gemini
- ✅ `lookupCompany` - Hľadanie firiem podľa IČO

### 5. Firebase Auth
- ✅ Demo účet existuje: `bizbizagent@bizbizagent.com`
- ✅ Heslo: `1369#1369#1369#`
- ✅ Provider: Email/Password (nie Google Sign-In)

## 🚀 Spustenie Testov

### Automatický Test (Bash Script)

```bash
chmod +x test_production_firebase.sh
./test_production_firebase.sh
```

Tento skript automaticky:
- Skontroluje Firebase CLI
- Overí prihlásenie
- Skontroluje Security Rules
- Overí Cloud Functions
- Skontroluje API kľúče v Secrets

### Manuálny Test (Dart Script)

```bash
dart test_production_api.dart
```

## 📝 Manuálne Kontroly

### 1. Demo Účet v Firebase Console

1. Choď na [Firebase Console](https://console.firebase.google.com/project/bizagent-live-2026)
2. **Authentication** > **Users**
3. Skontroluj, že existuje user `bizbizagent@bizbizagent.com`
4. Over, že **Provider** je `password` (nie `google.com`)
5. Skús sa prihlásiť v aplikácii s týmito údajmi

### 2. Cloud Functions Deployment

```bash
# Skontroluj, či sú funkcie nasadené
firebase functions:list

# Ak nie sú nasadené, nasaď ich
cd functions
npm install
cd ..
firebase deploy --only functions
```

### 3. API Keys (Secrets)

```bash
# Skontroluj Gemini API Key
firebase functions:secrets:access GEMINI_API_KEY

# Skontroluj IcoAtlas API Key (voliteľné)
firebase functions:secrets:access ICOATLAS_API_KEY

# Ak chýbajú, nastav ich
firebase functions:secrets:set GEMINI_API_KEY
firebase functions:secrets:set ICOATLAS_API_KEY
```

### 4. Testovanie Cloud Functions

#### Test lookupCompany (bez autentifikácie)

```bash
# V termináli
curl -X POST https://us-central1-bizagent-live-2026.cloudfunctions.net/lookupCompany \
  -H "Content-Type: application/json" \
  -d '{"data": {"ico": "36396567"}}'
```

Očakávaný výsledok:
```json
{
  "name": "Google Slovakia, s. r. o.",
  "ico": "36396567",
  "dic": "2020102636",
  "icDph": "SK2020102636",
  "address": "Karadžičova 8/A, Bratislava 821 08"
}
```

#### Test generateEmail (s autentifikáciou)

Toto vyžaduje Firebase Auth token. Najlepšie otestovať priamo v aplikácii.

### 5. Firestore Security Rules Test

```bash
# Deploy rules
firebase deploy --only firestore:rules

# Test rules (ak máš emulator)
firebase emulators:start --only firestore
```

### 6. Storage Rules Test

```bash
# Deploy storage rules
firebase deploy --only storage
```

## 🔍 Kontrola Logov

### Cloud Functions Logs

```bash
# Zobraz všetky logy
firebase functions:log

# Logy pre konkrétnu funkciu
firebase functions:log --only generateEmail

# Sleduj logy v reálnom čase
firebase functions:log --follow
```

### Firestore Logs

V Firebase Console > Firestore > Usage > Logs

## ⚠️ Časté Problémy

### 1. "Function not found"
**Riešenie:** Deploy Cloud Functions:
```bash
firebase deploy --only functions
```

### 2. "Permission denied" pri volaní funkcií
**Riešenie:** Skontroluj, či je používateľ prihlásený a má správny token.

### 3. "API key not found"
**Riešenie:** Nastav secrets:
```bash
firebase functions:secrets:set GEMINI_API_KEY
```

### 4. Demo účet nefunguje
**Riešenie:**
1. Skontroluj v Firebase Console, či účet existuje (`bizbizagent@bizbizagent.com`)
2. Over, že provider je `password` (nie `google.com`)
3. Skús resetovať heslo alebo vytvoriť nový účet pomocou `create_demo_account.sh`

### 5. Firestore Rules nefungujú
**Riešenie:**
1. Deploy rules: `firebase deploy --only firestore:rules`
2. Skontroluj syntax v `firebase/firestore.rules`
3. Použi Rules Playground v Firebase Console na testovanie

## ✅ Checklist Pred Google Play Upload

- [ ] Všetky automatické testy prešli (`./test_production_firebase.sh`)
- [ ] Demo účet existuje a funguje
- [ ] Cloud Functions sú nasadené a fungujú
- [ ] API kľúče sú nastavené v Secrets
- [ ] Firestore Rules sú nasadené
- [ ] Storage Rules sú nasadené
- [ ] Firebase projekt je na Blaze plan (pre Cloud Functions)
- [ ] Všetky logy sú čisté (žiadne kritické chyby)

## 📞 Ďalšia Pomoc

Ak máš problémy:
1. Skontroluj [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Pozri Firebase Console > Functions > Logs
3. Skontroluj [Firebase Status](https://status.firebase.google.com/)
