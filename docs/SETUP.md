# Setup Guide - BizAgent

## Požiadavky

### Flutter SDK
```bash
flutter --version
# Required: Flutter 3.10+ | Dart 3.2+
```

**Inštalácia Flutter:**
- macOS: `brew install --cask flutter`
- Windows/Linux: https://docs.flutter.dev/get-started/install

### Platform Requirements

**Android:**
- Android Studio 2023.2+
- Android SDK 34+
- JDK 17+

**iOS:**
- Xcode 15.0+
- CocoaPods: `sudo gem install cocoapods`
- iOS 13.0+ target

**Web:**
- Moderný browser (Chrome, Firefox, Safari)

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/youh4ck3dme/BizAgent.git
cd BizAgent
```

### 2. Install Dependencies

```bash
flutter pub get
```

**Očakávaný output:**
```
Resolving dependencies...
+ firebase_core ^4.3.0
+ flutter_riverpod ^2.6.1
...
Changed 87 dependencies!
```

### 3. Firebase Setup

#### a) Získaj Firebase konfiguráciu

1. Navštív [Firebase Console](https://console.firebase.google.com/)
2. Vytvor nový projekt alebo použi existujúci
3. Pridaj Android/iOS/Web app
4. Stiahni konfiguračné súbory:
   - **Android:** `google-services.json` → `android/app/`
   - **iOS:** `GoogleService-Info.plist` → `ios/Runner/`

#### b) Aktualizuj firebase_options.dart

```bash
# Generuj pomocou FlutterFire CLI
dart pub global activate flutterfire_cli
flutterfire configure
```

**Alebo manuálne** edituj `lib/firebase_options.dart`:
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_BUCKET.appspot.com',
);
```

⚠️ **DÔLEŽITÉ:** Nikdy necommituj reálne API keys do git!

### 4. Firestore Security Rules

Deploy security rules:
```bash
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

Alebo cez Firebase Console → Firestore → Rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /invoices/{userId}/invoices/{invoiceId} {
      allow read, write: if request.auth.uid == userId;
    }
    match /expenses/{userId}/expenses/{expenseId} {
      allow read, write: if request.auth.uid == userId;
    }
    match /users/{userId}/settings/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
    match /invoice_numbering/{userId}/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

## Run Aplikáciu

### Web (Najrýchlejšie pre vývoj)

```bash
flutter run -d chrome --web-port 9006
```

Otvorí sa na `http://localhost:9006`

### Android Emulator

```bash
# Spusť emulator
emulator -avd Pixel_7_API_34

# Run app
flutter run -d emulator-5554
```

### iOS Simulator

```bash
# Spusť simulator
open -a Simulator

# Run app
flutter run -d iPhone
```

### Physical Device

```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

## Common Setup Issues

### Issue: "cd: no such file or directory: BizAgent"
**Riešenie:**
```bash
pwd  # Skontroluj aktuálny adresár
cd /Users/youh4ck3dme/projekty-pwa/BizAgent
```

### Issue: "Starship took longer than 5000ms to compute prompt"
**Riešenie:** Zrýchli Starship prompt:
```bash
# ~/.config/starship.toml
[git_status]
disabled = false
ahead = "⇡"
behind = "⇣"
```

### Issue: "Compilation failed: ParenthesesWrongException"
**Príčina:** Pravdepodobne nezavreté zátvorky v kóde.
**Riešenie:**
```bash
flutter analyze
# Oprav syntax errors označené v outpute
```

### Issue: "firebase_core plugin not available"
**Riešenie:**
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: "CocoaPods not installed" (iOS)
**Riešenie:**
```bash
sudo gem install cocoapods
cd ios && pod install && cd ..
```

### Issue: "Multiple hero tags detected"
**Symptom:** Hero animation error pri navigácii.
**Riešenie:** Skontroluj FAB hero tags v `InvoicesScreen` a `ExpensesScreen`.

## IDE Setup

### VS Code

**Odporúčané Extensions:**
```json
{
  "recommendations": [
    "Dart-Code.dart-code",
    "Dart-Code.flutter",
    "usernamehw.errorlens",
    "GitHub.copilot"
  ]
}
```

**Settings (.vscode/settings.json):**
```json
{
  "dart.flutterSdkPath": "/Users/youh4ck3dme/flutter",
  "dart.lineLength": 120,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  }
}
```

### Android Studio

1. Install Flutter plugin: **Preferences → Plugins → Flutter**
2. Set Flutter SDK path: **Preferences → Languages & Frameworks → Flutter**
3. Enable Dart analysis: **Preferences → Languages & Frameworks → Dart**

## Development Commands

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Run tests
flutter test

# Run specific test
flutter test test/features/dashboard/dashboard_quick_actions_test.dart

# Check outdated packages
flutter pub outdated

# Upgrade packages
flutter pub upgrade

# Clean build artifacts
flutter clean
```

## Environment Variables (Optional)

Pre viacero prostredí (dev/staging/prod):

```bash
# .env.dev
FIREBASE_PROJECT_ID=bizagent-dev
API_BASE_URL=https://dev-api.bizagent.sk

# .env.prod
FIREBASE_PROJECT_ID=bizagent-prod
API_BASE_URL=https://api.bizagent.sk
```

Load pomocou `flutter_dotenv`:
```dart
await dotenv.load(fileName: ".env.${flavor}");
```

## Emulator Setup

### Android AVD

```bash
# List AVDs
emulator -list-avds

# Create new AVD
flutter emulators --create --name pixel_7

# Launch AVD
flutter emulators --launch pixel_7
```

### iOS Simulator

```bash
# List simulators
xcrun simctl list devices

# Boot simulator
xcrun simctl boot "iPhone 15 Pro"
```

## Database Setup (Local Development)

Pre local Firestore emulator:

```bash
# Install Firebase tools
npm install -g firebase-tools

# Initialize emulators
firebase init emulators

# Start emulators
firebase emulators:start --only firestore,auth
```

V `main.dart` connect k emulator:
```dart
if (kDebugMode) {
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
}
```

## Next Steps

1. ✅ Skontroluj že `flutter doctor` nehlási žiadne issues
2. ✅ Spusti `flutter test` - všetky testy musia byť zelené
3. ✅ Nakonfiguruj Firebase projekt (pozri Firebase Console)
4. ✅ Prečítaj [ARCHITECTURE.md](./ARCHITECTURE.md) pre pochopenie štruktúry
5. ✅ Začni s featurom development - pozri [CONTRIBUTING.md](../CONTRIBUTING.md)

## Troubleshooting

Pre ďalšie problémy pozri [TROUBLESHOOTING.md](./TROUBLESHOOTING.md).
