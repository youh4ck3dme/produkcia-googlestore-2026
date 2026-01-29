#!/usr/bin/env bash

set -euo pipefail

# BizAgent Flutter - Auto Setup (production-grade, idempotent-ish)

PROJECT_NAME_DEFAULT="bizagent"
ORG_DEFAULT="com.bizagent"

PROJECT_NAME="${PROJECT_NAME_DEFAULT}"
ORG="${ORG_DEFAULT}"
SKIP_PUB_GET=0
SKIP_GIT=0
INSTALL_FIREBASE_TOOLS=0

usage() {
  cat <<'EOF'
Usage: ./setup_bizagent.sh [options]

Options:
  --project-name <name>        Flutter project name (default: bizagent)
  --org <reverse-domain>       Organization identifier (default: com.bizagent)
  --skip-pub-get               Do not run "flutter pub get"
  --skip-git                   Do not init/commit git
  --install-firebase-tools     Install firebase-tools via npm if missing
  -h, --help                   Show help

Notes:
  - Run this script from the repo root.
  - It creates the Flutter project IN PLACE ("flutter create .") if the directory is empty.
  - Firebase configuration requires interactive steps (firebase login / flutterfire configure).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-name)
      PROJECT_NAME="$2"; shift 2;;
    --org)
      ORG="$2"; shift 2;;
    --skip-pub-get)
      SKIP_PUB_GET=1; shift;;
    --skip-git)
      SKIP_GIT=1; shift;;
    --install-firebase-tools)
      INSTALL_FIREBASE_TOOLS=1; shift;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

progress() { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

require_cmd() {
  local cmd="$1"
  local hint="${2:-}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "$cmd not found"
    [[ -n "$hint" ]] && echo "$hint" >&2
    exit 1
  fi
}

FLUTTER_CMD="flutter"
if ! command -v flutter >/dev/null 2>&1; then
  for p in "$HOME/flutter/bin/flutter" "/opt/homebrew/bin/flutter" "/usr/local/bin/flutter"; do
    if [[ -x "$p" ]]; then
      FLUTTER_CMD="$p"
      break
    fi
  done
fi

in_repo_root_sanity() {
  if [[ ! -d ".git" ]]; then
    warning "No .git directory found yet (this is OK if fresh)."
  fi
}

progress "Checking prerequisites..."
if [[ "$FLUTTER_CMD" == "flutter" ]]; then
  require_cmd flutter "Install Flutter: https://flutter.dev/docs/get-started/install"
else
  success "Flutter detected at: $FLUTTER_CMD"
fi
require_cmd git "Install Git and ensure it's in PATH"
success "Flutter is available"
success "Git available"

if command -v firebase >/dev/null 2>&1; then
  success "Firebase CLI available"
else
  if [[ "$INSTALL_FIREBASE_TOOLS" -eq 1 ]]; then
    require_cmd npm "Install Node.js (npm) to install firebase-tools"
    progress "Installing firebase-tools (global) via npm..."
    npm install -g firebase-tools
    success "Firebase CLI installed"
  else
    warning "Firebase CLI not found. Install later if needed: npm install -g firebase-tools"
  fi
fi

in_repo_root_sanity

# If pubspec.yaml doesn't exist, try to create Flutter project in-place.
if [[ -f "pubspec.yaml" ]]; then
  success "Flutter project detected (pubspec.yaml exists). Skipping flutter create."
else
  # Safety: flutter create . expects an empty directory (or will refuse).
  # We check if directory has any non-hidden files.
  shopt -s nullglob dotglob
  entries=(*)
  shopt -u nullglob dotglob

  # Allow only .git and setup script itself to exist
  allowed=(".git" "setup_bizagent.sh" "flutter_complete_setup.sh")
  for e in "${entries[@]}"; do
    skip=0
    for a in "${allowed[@]}"; do
      [[ "$e" == "$a" ]] && skip=1
    done
    if [[ "$skip" -eq 0 ]]; then
      error "Repo root is not empty (found: $e). Refusing to run flutter create ."
      echo "Either remove extra files or run setup in a new empty directory." >&2
      exit 1
    fi
  done

  progress "Creating Flutter project in-place..."
  "$FLUTTER_CMD" create --org "$ORG" --project-name "$PROJECT_NAME" .
  success "Flutter project created"
fi

progress "Writing pubspec.yaml (overwriting to ensure consistent deps)..."
cat > pubspec.yaml << 'PUBSPEC_EOF'
name: bizagent
description: AI Business Assistant pre SZČO a malé firmy
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  firebase_analytics: ^10.7.4
  firebase_crashlytics: ^3.4.8
  firebase_messaging: ^14.7.9
  cloud_functions: ^4.5.12

  # State Management
  flutter_riverpod: ^2.4.9

  # UI
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  lottie: ^2.7.0
  animations: ^2.0.11
  shimmer: ^3.0.0
  cached_network_image: ^3.3.0

  # PDF
  pdf: ^3.10.7
  printing: ^5.11.1
  syncfusion_flutter_pdf: ^24.1.41
  path_provider: ^2.1.1

  # OCR & Camera
  google_mlkit_text_recognition: ^0.11.0
  camera: ^0.10.5+7
  image_picker: ^1.0.5

  # Charts
  fl_chart: ^0.65.0

  # Utils
  intl: ^0.18.1
  uuid: ^4.2.2
  dio: ^5.4.0
  shared_preferences: ^2.2.2
  go_router: ^13.0.0
  permission_handler: ^11.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
PUBSPEC_EOF
success "pubspec.yaml configured"

progress "Creating directory structure..."
mkdir -p lib/{core/{constants,theme,utils,services,router},features/{auth/{models,providers,screens,widgets},dashboard/{models,providers,screens,widgets},invoices/{models,providers,screens,widgets},expenses/{models,providers,screens,widgets},documents/{models,providers,screens,widgets},ai_tools/{models,providers,screens,widgets},cashflow/{models,providers,screens,widgets},settings/{screens,widgets}},shared/{widgets,models}}
mkdir -p assets/{images,icons,fonts/Inter}
mkdir -p firebase/functions
mkdir -p test
success "Directory structure ready"

progress "Creating main application files..."
cat > lib/main.dart << 'MAIN_EOF'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const ProviderScope(child: BizAgentApp()));
}
MAIN_EOF

cat > lib/app.dart << 'APP_EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class BizAgentApp extends ConsumerWidget {
  const BizAgentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'BizAgent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BizAgent'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rocket_launch,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'BizAgent je pripravený!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI asistent pre SZČO a malé firmy',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Začať'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
APP_EOF

cat > lib/core/constants/app_constants.dart << 'CONST_EOF'
class AppConstants {
  static const String appName = 'BizAgent';
  static const String appVersion = '1.0.0';

  static const String usersCollection = 'users';
  static const String invoicesCollection = 'invoices';
  static const String expensesCollection = 'expenses';

  static const Map<String, String> expenseCategories = {
    'food': 'Stravovanie',
    'transport': 'Doprava a PHM',
    'material': 'Materiál a tovar',
    'software': 'Software',
    'marketing': 'Marketing',
    'office': 'Kancelária',
    'other': 'Ostatné',
  };

  static const Map<String, double> vatRates = {
    'standard': 20.0,
    'reduced': 10.0,
    'none': 0.0,
  };
}
CONST_EOF

# firebase_options.dart placeholder (keeps project compiling; flutterfire configure should overwrite)
cat > lib/firebase_options.dart << 'FIREBASE_EOF'
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    authDomain: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME',
    iosBundleId: 'com.bizagent.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME',
    iosBundleId: 'com.bizagent.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
  );
}
FIREBASE_EOF

success "Core app files created"

progress "Writing Firebase rules..."
mkdir -p firebase
cat > firebase/firestore.rules << 'RULES_EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    match /users/{userId} {
      allow read, write: if isOwner(userId);
    }

    match /invoices/{invoiceId} {
      allow create: if isOwner(request.resource.data.userId);
      allow read, update, delete: if isOwner(resource.data.userId);
    }

    match /expenses/{expenseId} {
      allow create: if isOwner(request.resource.data.userId);
      allow read, update, delete: if isOwner(resource.data.userId);
    }
  }
}
RULES_EOF

cat > firebase/storage.rules << 'STORAGE_EOF'
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
STORAGE_EOF
success "Firebase rules created"

progress "Writing README + PROMPTS.md..."
cat > README.md << 'README_EOF'
# BizAgent - AI Business Assistant

AI asistent pre SZČO a malé firmy na Slovensku.

## Setup

1. Install dependencies:

   flutter pub get

2. Configure Firebase (interactive):

   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure

3. Run:

   flutter run
README_EOF

cat > PROMPTS.md << 'PROMPTS_EOF'
# 🎯 10 Essential Prompts to Complete BizAgent

Copy-paste these prompts to Claude to build features:

## 1. Invoice Form Screen
```
Create a complete InvoiceForm widget for BizAgent Flutter app with:
- Client selector (with autocomplete)
- Dynamic items list (add/remove rows)
- Auto-calculation of subtotal, VAT, total
- Date pickers for issue/due date
- Form validation
- Save as draft or send
Use Riverpod for state management and Material 3 design
```

## 2. Camera Scanner with OCR
```
Build a CameraScanner widget for expense receipt scanning:
- Live camera preview
- Capture button with animation
- OCR processing with google_mlkit_text_recognition
- Extract: amount, date, vendor
- Show preview with detected fields
- Edit/confirm functionality
Material 3 UI with smooth animations
```

## 3. Dashboard with Charts
```
Create Dashboard screen with:
- Monthly revenue/expense cards
- Cashflow chart (last 6 months) using fl_chart
- Recent invoices list (last 5)
- Quick actions (new invoice, scan receipt)
- Overdue invoices alert
Use shimmer loading states, Riverpod providers
```

## 4. Expense List with Categories
```
Build ExpenseList screen featuring:
- Grouped by month
- Category chips (filterable)
- Swipe to delete
- Pull to refresh
- Empty state illustration
- FAB for quick add
Material 3 cards, smooth animations
```

## 5. PDF Preview & Share
```
Create PDFPreview screen:
- Render PDF using flutter_pdfview
- Zoom/pan controls
- Share button (share_plus)
- Download to device
- Print option
- Loading indicator
Modern UI with Material 3
```

## 6. AI Email Generator
```
Build AI Email Generator screen:
- Purpose selector (invoice reminder, quote, etc)
- Context input field
- Tone selector (formal, friendly, urgent)
- Generate button (calls Claude API)
- Copy to clipboard
- Save as template
Loading states, error handling
```

## 7. Settings & Profile
```
Create Settings screens:
- Profile (name, company, IČO, DIČ)
- Company address form
- Bank account details
- Subscription tier display
- Theme toggle (light/dark)
- Language selector (SK/EN)
Validation, save indicators
```

## 8. Authentication Flow
```
Build complete auth flow:
- Splash screen with animation
- Login (email/password)
- Register with company details
- Password reset
- Biometric login option
Firebase Auth integration, error handling
```

## 9. Cashflow Chart & Analytics
```
Create Cashflow Analytics screen:
- Income vs Expenses chart (bar/line)
- Category breakdown (pie chart)
- Month-over-month comparison
- Profit/loss indicator
- Export to PDF/Excel
Use fl_chart, beautiful gradients
```

## 10. Payment Reminders List
```
Build Payment Reminders screen:
- List of overdue invoices
- Days overdue badge
- Send reminder button
- Auto-reminder settings
- Reminder history
- Mark as paid quick action
Material 3, swipe actions
```

---

## 🚀 Bonus Prompts

### 11. Onboarding Flow
```
Create 3-screen onboarding with:
- SVG illustrations
- Feature highlights
- Skip button
- Get Started CTA
Use PageView, dots indicator, animations
```

### 12. Document Manager
```
Build Documents screen:
- File upload (image/pdf)
- Grid/list view toggle
- Search functionality
- Share/delete actions
- Storage usage indicator
Firebase Storage integration
```

---

## 💡 How to Use

1. Copy one prompt at a time
2. Paste to Claude
3. Review generated code
4. Add to your project
5. Test & iterate

Each prompt builds on the foundation - do them in order for best results!
PROMPTS_EOF
success "README and PROMPTS.md created"

progress "Writing .gitignore (before any git add)..."
cat > .gitignore << 'GITIGNORE_EOF'
# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/

# Firebase
**/.firebase/

# Environment
.env
.env.local

# IDE
.idea/
.vscode/
*.iml
*.code-workspace

# OS
.DS_Store
Thumbs.db
GITIGNORE_EOF
success ".gitignore written"

if [[ "$SKIP_PUB_GET" -eq 0 ]]; then
  progress "Running flutter pub get..."
  "$FLUTTER_CMD" pub get
  success "Dependencies installed"
else
  warning "Skipped flutter pub get"
fi

if [[ "$SKIP_GIT" -eq 0 ]]; then
  progress "Initializing Git (if needed)..."
  if [[ ! -d ".git" ]]; then
    git init
  fi

  git add .

  if git diff --cached --quiet; then
    warning "No changes to commit"
  else
    git commit -m "Initial BizAgent setup"
    success "Committed initial setup"
  fi
else
  warning "Skipped git init/commit"
fi

progress "Final checks..."
"$FLUTTER_CMD" --version >/dev/null
success "Setup complete"

echo ""
echo "Next steps:"
echo "- firebase login"
echo "- dart pub global activate flutterfire_cli"
echo "- flutterfire configure"
echo "- flutter run"
