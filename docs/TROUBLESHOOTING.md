# Troubleshooting - BizAgent

## Známe Problémy a Riešenia

### Build & Compilation Issues

#### 1. "cd: no such file or directory: BizAgent"

**Symptom:**
```bash
cd BizAgent
cd: no such file or directory: BizAgent
```

**Riešenie:**
```bash
pwd  # Check where you are
cd /Users/youh4ck3dme/projekty-pwa/BizAgent
```

#### 2. "ParenthesesWrongException"

**Symptom:**
```bash
Compilation failed
Error: ParenthesesWrongException
```

**Príčina:** Nezavreté zátvorky v Dart kóde.

**Riešenie:**
```bash
flutter analyze
# Fix syntax errors shown in output
# Check for missing ), }, ]
```

**VS Code tip:** Install "Bracket Pair Colorizer" extension.

#### 3. "Multiple hero tags detected"

**Symptom:**
```
There are multiple heroes that share the same tag within a subtree.
tag: <default FloatingActionButton tag>
```

**Príčina:** Dva FABs v bottom navigation majú rovnaký tag.

**Riešenie:**
```dart
// lib/features/invoices/screens/invoices_screen.dart
FloatingActionButton(
  heroTag: 'invoices_fab',  // ✅ Unique tag
  onPressed: () => context.push('/create-invoice'),
  child: const Icon(Icons.add),
)
```

### Firebase Issues

#### 4. "firebase_core plugin not available"

**Symptom:**
```
MissingPluginException(No implementation found for method Firebase#initializeCore)
```

**Riešenie:**
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..  # iOS only
flutter run
```

#### 5. "FirebaseOptions.apiKey is REPLACE_ME"

**Symptom:**
```
[ERROR:flutter/runtime/dart_vm_initializer.cc] Unhandled Exception: 
Firebase: API key is invalid (app/invalid-api-key)
```

**Riešenie:**
```bash
# 1. Get real Firebase config
# Firebase Console → Project Settings → Your apps

# 2. Run FlutterFire CLI
dart pub global activate flutterfire_cli
flutterfire configure

# 3. Restart app
flutter run
```

⚠️ **NEVER commit real API keys to git!**

### Test Failures

#### 6. "L10n not found. Wrap app with L10n"

**Symptom:**
```
The following assertion was thrown:
L10n not found. Wrap app with L10n.
```

**Riešenie:**
```dart
// test/features/dashboard/dashboard_test.dart
await tester.pumpWidget(
  L10n(  // ✅ Add this wrapper
    locale: AppLocale.sk,
    child: const MaterialApp(home: DashboardScreen()),
  ),
);
```

#### 7. "overrideWithValue is deprecated"

**Symptom:**
```
The method 'overrideWithValue' isn't defined for the class 'StreamProvider'
```

**Riešenie:**
```dart
// OLD (deprecated)
invoicesProvider.overrideWithValue(const AsyncData([])),

// NEW (correct)
invoicesProvider.overrideWith((ref) => Stream.value([])),
```

### Platform-Specific Issues

#### 8. "CocoaPods not installed" (iOS)

**Symptom:**
```
CocoaPods not installed or not in valid state
```

**Riešenie:**
```bash
sudo gem install cocoapods
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter run
```

#### 9. "Gradle build failed" (Android)

**Symptom:**
```
FAILURE: Build failed with an exception.
* What went wrong:
Execution failed for task ':app:processDebugGoogleServices'
```

**Riešenie:**
```bash
# 1. Check google-services.json exists
ls -la android/app/google-services.json

# 2. Clean and rebuild
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Runtime Errors

#### 10. "Starship took longer than 5000ms"

**Symptom:**
```bash
warning: Starship took 5123ms to compute prompt
```

**Riešenie:**

**Option 1** - Disable git status in large repos:
```bash
# ~/.config/starship.toml
[git_status]
disabled = true
```

**Option 2** - Faster git config:
```toml
[git_status]
disabled = false
ahead = "⇡"
behind = "⇣"
conflicted = "="
deleted = "✘"
diverged = "⇕"
```

#### 11. "Auth redirect loop"

**Symptom:** App infinitely redirects medzi `/login` a `/dashboard`.

**Príčina:** `authState.isLoading` nie je správne handled v router redirect.

**Riešenie:**
```dart
// lib/core/router/app_router.dart
redirect: (context, state) {
  if (authState.isLoading || authState.hasError) {
    return null;  // ✅ Wait for auth state to load
  }
  
  final isLoggedIn = authState.valueOrNull != null;
  final isLoggingIn = state.uri.path == '/login';
  
  if (!isLoggedIn && !isLoggingIn) return '/login';
  if (isLoggedIn && isLoggingIn) return '/dashboard';
  
  return null;
}
```

### Data Issues

#### 12. "Invoice numbering collision"

**Symptom:** Dve faktúry majú rovnaké číslo.

**Príčina:** Race condition pri concurrent vytváraní faktúr.

**Riešenie:**

**Already implemented** - Atomic increment:
```dart
// lib/features/invoices/services/invoice_numbering_service.dart
final docRef = _firestore.collection('invoice_numbering/$uid/state');

await _firestore.runTransaction((transaction) async {
  final snapshot = await transaction.get(docRef);
  final newCounter = (snapshot.data()?['counter'] ?? 0) + 1;
  
  transaction.set(docRef, {'counter': newCounter});
  
  return '$year/${newCounter.toString().padLeft(3, '0')}';
});
```

#### 13. "Bank CSV parsing fails"

**Symptom:**
```
FormatException: Invalid CSV format
```

**Debug:**
```dart
// Check CSV encoding
final file = await File(path).readAsBytes();
final encoding = detectEncoding(file);
print('CSV encoding: $encoding');  // Should be UTF-8 or Windows-1250

// Check delimiter
final firstLine = await File(path).readAsLines().first;
print('Delimiters: ${firstLine.contains(';') ? 'semicolon' : 'comma'}');
```

**Riešenie:** Convert CSV to UTF-8 semicolon-delimited format.

### Performance Issues

#### 14. "App is slow / laggy"

**Debug:**
```bash
# Enable performance overlay
flutter run --profile

# Check for:
# - Red/yellow frames (>16ms)
# - Memory leaks
# - Excessive rebuilds
```

**Common fixes:**
```dart
// 1. Use const constructors
const Text('Hello');  // ✅ vs Text('Hello')

// 2. Avoid rebuilding entire tree
ConsumerWidget vs Consumer  // Rebuild only needed parts

// 3. ListView.builder instead of Column
ListView.builder(  // ✅ Lazy loading
  itemCount: items.length,
  itemBuilder: (context, index) => ...
)
```

### Web-Specific Issues

#### 15. "CORS error when calling API"

**Symptom:**
```
Access to XMLHttpRequest blocked by CORS policy
```

**Riešenie:**

**Backend (Firebase Cloud Functions):**
```dart
import 'package:functions_framework/functions_framework.dart';
import 'package:shelf/shelf.dart';

@CloudFunction()
Response handleRequest(Request request) {
  return Response.ok(
    json.encode({'data': 'value'}),
    headers: {
      'Access-Control-Allow-Origin': '*',  // ✅ Enable CORS
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    },
  );
}
```

#### 16. "Flutter web white screen"

**Symptom:** Blank white page po `flutter build web`.

**Debug:**
```bash
# Check browser console for errors
# Common: Failed to load CanvasKit / WASM

# Build with HTML renderer (fallback)
flutter build web --web-renderer html
```

## Debug Tools

### Flutter DevTools

```bash
# Start DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Run app with DevTools
flutter run --observatory-port=9100
# Open http://localhost:9100 in DevTools
```

**Features:**
- Widget Inspector
- Memory Profiler
- Performance Timeline
- Network Inspector

### Crashlytics Debugging

```bash
# View crashes
# Firebase Console → Crashlytics

# Force test crash
FirebaseCrashlytics.instance.crash();

# Custom crash logging
try {
  riskyOperation();
} catch (e, stack) {
  FirebaseCrashlytics.instance.recordError(e, stack);
  rethrow;
}
```

### Network Debugging (Charles Proxy)

```bash
# 1. Install Charles Proxy
brew install --cask charles

# 2. Set proxy in app
final dio = Dio();
dio.httpClientAdapter = HttpClientAdapter();

# 3. View HTTP traffic in Charles
```

## Getting Help

### 1. Check Existing Issues

**GitHub Issues:** https://github.com/youh4ck3dme/BizAgent/issues

Search pre podobné problémy.

### 2. Gather Debug Info

```bash
# System info
flutter doctor -v

# Package versions
flutter pub deps --style=compact

# Crash logs
flutter logs

# Build logs
flutter build apk --verbose
```

### 3. Create Bug Report

Use `/reportbug` command in IDE alebo:

**GitHub Issue Template:**
```markdown
**Describe the bug**
Clear description...

**To Reproduce**
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What should happen...

**Screenshots**
If applicable...

**Environment:**
- OS: macOS 14.2
- Flutter: 3.10.7
- Device: iPhone 15 Pro / Pixel 7

**Additional context**
- Firebase config: OK
- Test coverage: 75%
- Error logs: [attached]
```

### 4. Emergency Support

**Critical production bug:**
- **Email:** youh4ck3dme@gmail.com
- **Subject:** `[URGENT] Production Issue - BizAgent`
- **Response:** <24h

## Preventive Measures

### Pre-Commit Checklist

```bash
# 1. Run tests
flutter test

# 2. Analyze code
flutter analyze

# 3. Format code
dart format lib/ test/

# 4. Check for secrets
git grep -nE "apiKey|secret|token" -- ':!*.lock'
```

### Pre-Release Checklist

- [ ] All tests passing (17/17)
- [ ] No analyzer warnings
- [ ] Firebase config valid
- [ ] Privacy policy links working
- [ ] Crashlytics enabled
- [ ] Version bumped in pubspec.yaml
- [ ] CHANGELOG.md updated
- [ ] Release notes prepared

## FAQ

**Q: Prečo mi nefunguje hot reload?**  
A: `flutter clean && flutter pub get` zvyčajne pomôže. Alebo reštartuj IDE.

**Q: Ako zistím prečo test failuje?**  
A: Spusti s verbose: `flutter test --reporter expanded test/path/to/test.dart`

**Q: Firebase rules mi blokujú requesty?**  
A: Check Firestore → Rules tab. Test s emulatorom lokálne.

**Q: App crashuje len na iOS?**  
A: Check iOS logs: `flutter logs` alebo Xcode → Window → Devices → View Device Logs.

**Q: Ako debugnem production crash?**  
A: Firebase Console → Crashlytics → Stack trace + user info.

## Still Stuck?

1. ✅ Read [ARCHITECTURE.md](./ARCHITECTURE.md) - pochop data flow
2. ✅ Read [TESTING.md](./TESTING.md) - write failing test first
3. ✅ Search GitHub issues
4. ✅ Ask on Discord/Slack
5. ✅ Create new GitHub issue
