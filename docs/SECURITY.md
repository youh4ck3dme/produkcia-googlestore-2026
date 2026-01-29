# Security - BizAgent

## Secrets Management

### ❌ NIKDY NEcommituj do GIT:

- API keys (Firebase, third-party services)
- Keystore passwords
- Private keys
- Service account JSONs
- `.env` files s produkčnými údajmi

### Scan pre Secrets

```bash
# Gitleaks scan
git grep -nE "apiKey|AIza|secret|token|PRIVATE_KEY|BEGIN PRIVATE KEY|firebaseConfig|GOOGLE_API_KEY|OPENAI_API_KEY" -- ':!*.lock' ':!*.json' || echo "✅ No hardcoded secrets found"
```

**Aktuálny stav projektu:**
```
lib/firebase_options.dart:22:    apiKey: 'REPLACE_ME',
```
✅ Placeholder hodnoty sú OK - reálne keys sú mimo git.

### .gitignore Setup

```gitignore
# Secrets & Keys
*.jks
*.keystore
key.properties
.env
.env.*
!.env.example
google-services.json
GoogleService-Info.plist
firebase_options_real.dart

# Build artifacts
/build/
/android/app/debug/
/android/app/profile/
/android/app/release/

# IDE
.vscode/launch.json
.idea/workspace.xml
```

### Firebase Config Pattern

```dart
// lib/firebase_options.dart (v gite)
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'REPLACE_ME',  // ✅ Placeholder
  appId: 'REPLACE_ME',
  // ...
);

// firebase_options_real.dart (v .gitignore)
// Real values loaded at runtime
```

## Firebase Security Rules

### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User môže pristupovať len k vlastným dátam
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }
    
    // Invoices
    match /invoices/{userId}/invoices/{invoiceId} {
      allow read, write: if isOwner(userId);
      
      allow create: if isOwner(userId) 
        && request.resource.data.keys().hasAll(['number', 'clientName', 'totalAmount'])
        && request.resource.data.totalAmount >= 0;
      
      allow update: if isOwner(userId)
        && request.resource.data.keys().hasAll(['number', 'clientName', 'totalAmount']);
      
      allow delete: if isOwner(userId);
    }
    
    // Expenses
    match /expenses/{userId}/expenses/{expenseId} {
      allow read, write: if isOwner(userId);
      
      allow create: if isOwner(userId)
        && request.resource.data.amount >= 0;
    }
    
    // Settings
    match /users/{userId}/settings/{document=**} {
      allow read, write: if isOwner(userId);
    }
    
    // Invoice numbering (atomic increment)
    match /invoice_numbering/{userId}/{document=**} {
      allow read: if isOwner(userId);
      allow write: if isOwner(userId) 
        && request.resource.data.counter is int;
    }
    
    // Deny everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

**Test rules:**
```bash
firebase emulators:start --only firestore
# Then run integration tests
```

### Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Expense photos
    match /expenses/{userId}/{filename} {
      allow read: if request.auth.uid == userId;
      
      allow write: if request.auth.uid == userId
        && request.resource.size < 10 * 1024 * 1024  // Max 10MB
        && request.resource.contentType.matches('image/.*');
      
      allow delete: if request.auth.uid == userId;
    }
    
    // Invoice PDFs
    match /invoices/{userId}/{filename} {
      allow read: if request.auth.uid == userId;
      
      allow write: if request.auth.uid == userId
        && request.resource.size < 5 * 1024 * 1024  // Max 5MB
        && request.resource.contentType == 'application/pdf';
    }
    
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

## Authentication Security

### Firebase Auth Best Practices

```dart
// Email enumeration protection
try {
  await _auth.signInWithEmailAndPassword(email: email, password: password);
} catch (e) {
  // Generic error message - don't reveal if email exists
  throw 'Neplatné prihlasovacie údaje';
}

// Password requirements (enforced by Firebase)
// - Min 6 characters
// - Recommendation: 8+ chars, mixed case, numbers, symbols
```

### Session Management

```dart
// Auto logout after inactivity
class SessionManager {
  static const _timeout = Duration(minutes: 30);
  Timer? _timer;
  
  void resetTimer(FirebaseAuth auth) {
    _timer?.cancel();
    _timer = Timer(_timeout, () => auth.signOut());
  }
}
```

## Data Privacy & GDPR

### User Data Collection

**Zbierané dáta:**
- Email (authentication)
- Company info (IČO, DIČ, adresa)
- Invoices, expenses (business records)
- Bank transactions (imported CSV)

**NIE sú zbierané:**
- Payment card details
- Personal identification numbers (rodné čísla)
- Health data
- Biometric data

### Data Retention

```dart
// User-initiated deletion
Future<void> deleteAccount(String userId) async {
  // 1. Delete Firestore data
  await _firestore.collection('invoices').doc(userId).delete();
  await _firestore.collection('expenses').doc(userId).delete();
  await _firestore.collection('users').doc(userId).delete();
  
  // 2. Delete Storage files
  await _storage.ref('expenses/$userId').delete();
  await _storage.ref('invoices/$userId').delete();
  
  // 3. Delete Auth account
  await FirebaseAuth.instance.currentUser?.delete();
}
```

**Auto-deletion policy:**
- Inactive accounts (2+ years): Email notification → 30-day grace period → deletion

### Privacy Policy Links

- SK: `https://youh4ck3dme.github.io/BizAgent/privacy.html`
- EN: `https://youh4ck3dme.github.io/BizAgent/privacy-en.html`

Linked in:
- Settings screen (`lib/features/settings/screens/settings_screen.dart`)
- Play Store listing
- App Store listing

## Logging & Monitoring

### Crashlytics

```dart
// main.dart
void main() async {
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(const BizAgentApp());
}
```

**⚠️ PII Scrubbing:**
```dart
// Nikdy neloguj sensitive data
FirebaseCrashlytics.instance.log('Invoice created');  // ✅ OK
FirebaseCrashlytics.instance.log('User: $email');     // ❌ PII leak

// Custom keys (sanitized)
FirebaseCrashlytics.instance.setCustomKey('feature', 'invoices');
FirebaseCrashlytics.instance.setCustomKey('user_id_hash', sha256(userId));
```

### Analytics Privacy

```dart
// Disable analytics pre opt-out users
await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);

// Anonymize user data
await FirebaseAnalytics.instance.setUserId(null);  // Don't track user ID
```

## Dependency Security

### Regular Audits

```bash
# Check for known vulnerabilities
flutter pub outdated

# Update dependencies
flutter pub upgrade

# Check for breaking changes
flutter pub upgrade --major-versions
```

**Monthly audit schedule:**
- Week 1: `flutter pub outdated`
- Week 2: Test upgrades in dev branch
- Week 3: Merge if tests pass
- Week 4: Deploy new version

### Pinned Dependencies

```yaml
# pubspec.yaml - Use specific versions pre critical packages
dependencies:
  firebase_core: 4.3.0  # ✅ Pinned
  flutter_riverpod: ^2.6.1  # ⚠️ Allow minor updates
```

## Network Security

### HTTPS Only

```dart
// Enforce HTTPS for all API calls
final dio = Dio(
  BaseOptions(
    baseUrl: 'https://api.bizagent.sk',  // ✅ HTTPS
    connectTimeout: const Duration(seconds: 10),
  ),
);
```

### Certificate Pinning (Optional)

```dart
// For high-security apps
import 'package:dio/dio.dart';
import 'package:dio_certificate_pinning/dio_certificate_pinning.dart';

final dio = Dio();
dio.interceptors.add(
  CertificatePinningInterceptor(
    allowedSHAFingerprints: [
      'AA:BB:CC:DD:...',  // Your server's cert fingerprint
    ],
  ),
);
```

## Code Security

### Input Validation

```dart
// Validate user input
String sanitizeInput(String input) {
  return input
      .trim()
      .replaceAll(RegExp(r'[<>]'), '')  // Prevent XSS
      .substring(0, min(input.length, 1000));  // Limit length
}

// Invoice number validation
final invoiceNumberRegex = RegExp(r'^\d{4}/\d{3}$');
if (!invoiceNumberRegex.hasMatch(number)) {
  throw 'Invalid invoice number format';
}
```

### SQL Injection Prevention

✅ **Firestore je query injection-safe** - používa strongly-typed queries.

```dart
// ✅ Safe - Firestore automatically escapes
await _firestore
    .collection('invoices/$userId/invoices')
    .where('number', isEqualTo: userInput)  // Safe
    .get();
```

## Incident Response

### Security Issue Reporting

**Email:** youh4ck3dme@gmail.com  
**Subject:** `[SECURITY] BizAgent Vulnerability`

**Response SLA:**
- Critical: 24 hours
- High: 72 hours
- Medium: 1 week
- Low: 2 weeks

### Incident Checklist

1. **Acknowledge** - Potvrdenie prijatia reportu
2. **Assess** - Severity rating (CVSS score)
3. **Fix** - Patch development + testing
4. **Deploy** - Emergency hotfix release
5. **Notify** - User communication (ak treba)
6. **Document** - Postmortem report

## Compliance

### GDPR Compliance

- ✅ Data minimization (collect only necessary data)
- ✅ Right to access (user can export data)
- ✅ Right to erasure (account deletion)
- ✅ Privacy policy link in app
- ✅ Consent for data processing (ToS acceptance)

### Slovak Business Law

- ✅ Invoice data retention: 10 years
- ✅ Accounting records: 10 years
- ✅ Tax documents: 10 years

**Implementation:** Soft delete + archive to cold storage after 1 year.

## Security Checklist (Pre-Release)

- [ ] Gitleaks scan passed
- [ ] Firestore rules deployed & tested
- [ ] Storage rules deployed & tested
- [ ] Crashlytics PII scrubbing enabled
- [ ] Privacy policy links working
- [ ] HTTPS enforced
- [ ] Dependencies updated
- [ ] Penetration testing completed
- [ ] Security review by 2nd developer
- [ ] Incident response plan documented
