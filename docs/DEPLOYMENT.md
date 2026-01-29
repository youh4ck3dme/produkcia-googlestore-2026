# Deployment Guide - BizAgent

## Android Build & Release

### 1. Nastavenie Signing Key

#### Vytvorenie Keystore

```bash
keytool -genkey -v -keystore ~/bizagent-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias bizagent
```

**Bezpečne ulož:**
- Keystore súbor (`bizagent-release-key.jks`)
- Keystore password
- Key alias password

#### Konfigurácia key.properties

Vytvor `android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=bizagent
storeFile=/Users/youh4ck3dme/bizagent-release-key.jks
```

⚠️ **Pridaj do `.gitignore`:**
```bash
echo "android/key.properties" >> .gitignore
```

### 2. Build Android App Bundle (AAB)

```bash
# Increment version v pubspec.yaml
# version: 1.0.1+2  (1.0.1 = versionName, 2 = versionCode)

# Build AAB
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### 3. Test AAB Lokálne

```bash
# Install bundletool
brew install bundletool  # macOS

# Generate APKs from AAB
bundletool build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=bizagent.apks \
  --mode=universal

# Extract APK
unzip -p bizagent.apks universal.apk > bizagent-universal.apk

# Install na device
adb install bizagent-universal.apk
```

### 4. Upload do Play Console

1. **Play Console** → https://play.google.com/console
2. **Release → Production/Internal testing**
3. **Create new release**
4. Upload `app-release.aab`
5. **Release notes** (SK + EN):
```
Verzia 1.0.1
- Pridané pull-to-refresh funkcie
- Opravené undo akcie pri mazaní
- Vylepšená validácia emailu
- Stability improvements
```
6. **Review and roll out**

### 5. Versioning Strategy

**Semantic Versioning:** `MAJOR.MINOR.PATCH+BUILD`

```yaml
# pubspec.yaml
version: 1.0.1+2
#        ↑   ↑ ↑
#        │   │ └─ BUILD (versionCode) - increment každý release
#        │   └─── PATCH - bug fixes
#        └─────── MINOR - new features
```

**Rules:**
- **BUILD** (+1): Každý nový release (aj hotfix)
- **PATCH** (.0.1): Bug fixes, minor improvements
- **MINOR** (.1.0): Nové features, UX improvements
- **MAJOR** (2.0.0): Breaking changes, redizajn

## iOS Build & Release

### 1. Xcode Setup

```bash
cd ios
pod install
open Runner.xcworkspace
```

**V Xcode:**
1. **Signing & Capabilities** → Select team
2. **Bundle Identifier:** `sk.bizagent.app`
3. **Version:** `1.0.1` (sync s pubspec.yaml)
4. **Build:** `2`

### 2. Archive & Upload

```bash
# Build iOS archive
flutter build ipa --release

# Output: build/ios/ipa/bizagent.ipa
```

**Alebo cez Xcode:**
1. **Product → Archive**
2. **Distribute App → App Store Connect**
3. Upload

### 3. App Store Connect

1. **App Store Connect** → https://appstoreconnect.apple.com
2. **My Apps → BizAgent**
3. **+ Version**
4. Fill metadata:
   - **What's New:** Release notes (SK + EN)
   - **Screenshots:** 6.7", 6.5", 5.5" (iPhone)
   - **App Privacy:** Link k `https://youh4ck3dme.github.io/BizAgent/privacy.html`
5. **Submit for Review**

## Firebase Functions Deployment

### 1. Nastavenie Secrets

Firebase Functions používajú Secrets Manager pre bezpečné uloženie API kľúčov.

#### Automatické nastavenie (ak máte kľúče v `.env`)

```bash
cd /Users/youh4ck3dme/Downloads/BizAgent-produkcia-google-play

# Nastavenie secrets z .env súboru
echo "your_gemini_key" | firebase functions:secrets:set GEMINI_API_KEY
echo "your_icoatlas_key" | firebase functions:secrets:set ICOATLAS_API_KEY
echo "your_recaptcha_key" | firebase functions:secrets:set RECAPTCHA_API_KEY
```

#### Manuálne nastavenie

```bash
firebase functions:secrets:set GEMINI_API_KEY
# Vložte kľúč keď vás systém vyzve
```

### 2. Deploy Funkcií

#### Použitie deploy skriptu (odporúčané)

```bash
cd /Users/youh4ck3dme/Downloads/BizAgent-produkcia-google-play
./deploy_functions.sh
```

Tento skript automaticky:
- ✅ Skontroluje `.env` súbor
- ✅ Nainštaluje závislosti (`npm install`)
- ✅ Zbuildí TypeScript (`npm run build`)
- ✅ Deployne funkcie (`firebase deploy --only functions`)

#### Manuálny deploy

```bash
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions
```

### 3. Požiadavky

- **Node.js verzia:** 20 (nie 25!) - skontrolujte `functions/package.json`
- **`.env` súbor:** Musí existovať v `functions/.env` počas deployu
- **Firebase Blaze Plan:** Vyžaduje sa pre Cloud Functions

### 4. Kontrola Deployu

```bash
# Zoznam nasadených funkcií
firebase functions:list

# Logy funkcií
firebase functions:log

# Test funkcie
firebase functions:shell
```

### 5. Riešenie Problémov

**"Node engine 25 is not supported"**
- Zmeňte v `functions/package.json`: `"node": "20"`

**"Secret environment variable overlaps"**
- Zmazajte staré funkcie: `firebase functions:delete generateEmail analyzeReceipt --region us-central1 --force`

**"In non-interactive mode but have no value"**
- Skontrolujte, či existuje `functions/.env` súbor

Viac informácií: [FIREBASE_SECRETS_SETUP.md](./FIREBASE_SECRETS_SETUP.md)

## Web Deployment

### 1. Build Web App

```bash
flutter build web --release --base-href /BizAgent/

# Output: build/web/
```

### 2. Firebase Hosting

#### Setup

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize hosting
firebase init hosting
```

**firebase.json:**
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  }
}
```

#### Deploy

```bash
firebase deploy --only hosting

# Deployed URL: https://bizagent-XXXXX.web.app
```

### 3. GitHub Pages (Alternatíva)

```bash
# Build
flutter build web --base-href /BizAgent/

# Deploy
cd build/web
git init
git add .
git commit -m "Deploy web"
git remote add origin https://github.com/youh4ck3dme/BizAgent.git
git push -f origin HEAD:gh-pages
```

**GitHub Settings:**
- **Settings → Pages**
- **Source:** gh-pages branch
- **URL:** https://youh4ck3dme.github.io/BizAgent/

## Privacy Policy Hosting

### Firebase Hosting pre Privacy Pages

```bash
# Vytvor public adresár
mkdir -p public
cp web/privacy.html public/
cp web/privacy-en.html public/

# Deploy
firebase deploy --only hosting
```

**URLs:**
- SK: `https://bizagent.web.app/privacy.html`
- EN: `https://bizagent.web.app/privacy-en.html`

⚠️ **Update odkazy v Settings:**
```dart
// lib/features/settings/screens/settings_screen.dart
final url = Uri.parse('https://bizagent.web.app/privacy.html');
```

## CI/CD Pipeline (GitHub Actions)

### .github/workflows/deploy.yml

```yaml
name: Deploy

on:
  push:
    tags:
      - 'v*'

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.7'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test
      
      - name: Build AAB
        run: flutter build appbundle --release
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
      
      - name: Upload to Play Console
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: sk.bizagent.app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: production
          status: completed

  deploy-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      - run: flutter pub get
      - run: flutter build web --release
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: bizagent-prod
```

### GitHub Secrets Setup

**Settings → Secrets and variables → Actions:**

```bash
KEYSTORE_PASSWORD=your_keystore_password
KEY_PASSWORD=your_key_password
GOOGLE_PLAY_SERVICE_ACCOUNT=<json_content>
FIREBASE_SERVICE_ACCOUNT=<json_content>
```

## Rollout Strategy

### Internal Testing (Alpha)

```bash
# Build & upload
flutter build appbundle --release

# Play Console → Internal testing
# Add testers: youh4ck3dme@gmail.com
```

**Duration:** 1-2 dni, 5-10 testerov

### Closed Testing (Beta)

**Play Console → Closed testing**
- Audience: 50-100 beta testerov
- Feedback form: Google Forms link
- **Duration:** 1 týždeň

### Production (Staged Rollout)

1. **Day 1:** 10% users
2. **Day 3:** 25% users (ak 0 crashov)
3. **Day 5:** 50% users
4. **Day 7:** 100% rollout

**Monitor:**
- Crashlytics crash-free rate (target: >99%)
- Play Console vitals (ANR, crashes)
- User reviews

## Hotfix Procedure

```bash
# 1. Fix bug on hotfix branch
git checkout -b hotfix/1.0.2

# 2. Increment version
# pubspec.yaml: version: 1.0.2+3

# 3. Test
flutter test

# 4. Build & deploy
flutter build appbundle --release

# 5. Upload to Play Console → Production
# Enable "Emergency release" option

# 6. Merge hotfix
git checkout main
git merge hotfix/1.0.2
git tag v1.0.2
git push --tags
```

## Post-Release Checklist

- [ ] Tag release: `git tag v1.0.1 && git push --tags`
- [ ] Update [CHANGELOG.md](../CHANGELOG.md)
- [ ] Announce na Slack/Discord
- [ ] Monitor Crashlytics 48h
- [ ] Check Play Console reviews
- [ ] Update dokumentáciu ak treba

## Monitoring & Analytics

### Firebase Crashlytics

```dart
// main.dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

**Dashboard:** Firebase Console → Crashlytics

### Firebase Analytics

**Key Events:**
- `invoice_created`
- `expense_added`
- `bank_csv_imported`
- `export_generated`

**Check:** Firebase Console → Analytics → Events

## Rollback Procedure

Ak release má critical bug:

1. **Play Console → Production → Releases**
2. **Halt rollout** (stops at current percentage)
3. **Release hotfix** (nová verzia)
4. **Alebo:** Promote predchádzajúcu verziu

⚠️ **Poznámka:** iOS rollback nie je možný - musíš submitnúť novú verziu.
