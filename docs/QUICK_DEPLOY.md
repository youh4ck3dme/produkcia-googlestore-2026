# 🚀 Rýchly Deploy Guide - BizAgent

Kompletný návod na rýchle nasadenie všetkých komponentov BizAgent aplikácie.

## 📋 Prehľad Komponentov

1. **Firebase Functions** - Backend API (Gemini AI, IcoAtlas)
2. **Firebase Hosting** - Web aplikácia
3. **Android App Bundle** - Mobilná aplikácia pre Google Play

## 🔥 Firebase Functions (Backend)

### Jeden príkaz deploy

```bash
cd ~/Projects/02_Products/bizagent && firebase use live && ./deploy_functions.sh
```

### Čo sa stane

1. ✅ Kontrola `.env` súboru
2. ✅ Inštalácia závislostí (`npm install`)
3. ✅ Build TypeScript (`npm run build`)
4. ✅ Deploy na Firebase (`firebase deploy --only functions`)

### Prvé nastavenie secrets

```bash
cd ~/Projects/02_Products/bizagent
firebase use live

# Secrets nastav interaktívne (hodnoty drž v functions/.env — gitignored)
firebase functions:secrets:set GEMINI_API_KEY
firebase functions:secrets:set ICOATLAS_API_KEY
firebase functions:secrets:set RECAPTCHA_API_KEY
```

## 🌐 Firebase Hosting (Web)

### Deploy web aplikácie

```bash
cd /Users/youh4ck3dme/Downloads/BizAgent-produkcia-google-play

# Build Flutter web
flutter build web --release --base-href "/"

# Deploy na Firebase Hosting
firebase deploy --only hosting
```

### Jeden príkaz

```bash
cd /Users/youh4ck3dme/Downloads/BizAgent-produkcia-google-play && flutter build web --release --base-href "/" && firebase deploy --only hosting
```

## 📱 Android App Bundle (Google Play)

### Build AAB

```bash
cd /Users/youh4ck3dme/Downloads/BizAgent-produkcia-google-play

# Increment version v pubspec.yaml ak treba
# version: 1.0.1+2

# Build AAB
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### Upload do Play Console

1. Otvorte [Play Console](https://play.google.com/console)
2. **Release → Production**
3. **Create new release**
4. Upload `app-release.aab`
5. **Review and roll out**

## 🎯 Kompletný Deploy (Všetko naraz)

### Skript pre kompletný deploy

```bash
#!/bin/bash
# deploy_all.sh

set -e

echo "🚀 Starting complete BizAgent deployment..."

# 1. Firebase Functions
echo "📦 Deploying Firebase Functions..."
./deploy_functions.sh

# 2. Web App
echo "🌐 Building and deploying Web App..."
flutter build web --release --base-href "/"
firebase deploy --only hosting

# 3. Android (voliteľné)
read -p "Build Android AAB? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📱 Building Android App Bundle..."
    flutter build appbundle --release
    echo "✅ AAB ready: build/app/outputs/bundle/release/app-release.aab"
    echo "📤 Upload to Play Console manually"
fi

echo "✅ Deployment complete!"
```

## ⚡ Rýchle Príkazy

### Len Functions
```bash
./deploy_functions.sh
```

### Len Web
```bash
flutter build web --release --base-href "/" && firebase deploy --only hosting
```

### Len Android
```bash
flutter build appbundle --release
```

### Všetko naraz
```bash
./deploy_functions.sh && flutter build web --release --base-href "/" && firebase deploy --only hosting
```

## 🔍 Kontrola po Deployi

### Firebase Functions
```bash
firebase functions:list
firebase functions:log
```

### Firebase Hosting
```bash
# URL: https://bizagent-live-2026.web.app
firebase hosting:channel:list
```

### Android
- Play Console → Release → Production
- Skontrolujte status release

## 📚 Ďalšie Dokumenty

- [FIREBASE_SECRETS_SETUP.md](./FIREBASE_SECRETS_SETUP.md) - Detailný návod na secrets
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Kompletný deployment guide
- [FIREBASE_GEMINI.md](./FIREBASE_GEMINI.md) - Gemini AI setup
