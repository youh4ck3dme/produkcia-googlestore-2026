#!/bin/bash

# 🚀 BizAgent Flutter - UPGRADE SCRIPT
# Upgrades the project structure to a fully navigational app.

set -e

cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║       🚀 BizAgent - ARCHITECTURE UPGRADE v1.0 🚀         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF

echo "🎯 Starting BizAgent upgrade..."
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

progress() { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

# 1. Check Project Root
if [ ! -f "pubspec.yaml" ]; then
    error "pubspec.yaml not found! Please run this script in the project root."
    exit 1
fi

# 2. Update pubspec.yaml (preserving name)
progress "Updating dependencies..."
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
  firebase_analytics: ^10.8.0
  firebase_crashlytics: ^3.4.8
  cloud_functions: ^4.5.0

  # State Management
  flutter_riverpod: ^2.4.9

  # UI
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  lottie: ^2.7.0
  animations: ^2.0.11
  shimmer: ^3.0.0
  
  # Navigation
  go_router: ^13.0.0

  # Utils
  intl: ^0.18.1
  uuid: ^4.2.2
  dio: ^5.4.0
  shared_preferences: ^2.2.2
  permission_handler: ^11.1.0
  path_provider: ^2.1.1
  
  # PDF & Print
  pdf: ^3.10.7
  printing: ^5.11.1

  # Camera & ML
  google_mlkit_text_recognition: ^0.11.0
  camera: ^0.10.5+7
  image_picker: ^1.0.5

  # Charts
  fl_chart: ^0.65.0

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
success "pubspec.yaml updated"

# 3. Create Directories
progress "Ensuring directory structure..."
mkdir -p lib/core/{constants,theme,utils,services,router}
mkdir -p lib/features/{auth,dashboard,invoices,expenses,documents,ai_tools,cashflow,settings}/{models,providers,screens,widgets}
mkdir -p lib/shared/{widgets,models}
success "Directories created"

# 4. Create App Theme
progress "Creating App Theme..."
cat > lib/core/theme/app_theme.dart << 'THEME_EOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
THEME_EOF

# 5. Create Core Constants
cat > lib/core/constants/app_constants.dart << 'CONST_EOF'
class AppConstants {
  static const String appName = 'BizAgent';
}
CONST_EOF

# 6. Create Feature Screens (Scaffolds)
progress "Creating Feature Screens..."

# Auth Screen
cat > lib/features/auth/screens/login_screen.dart << 'EOF'
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text('Login Screen', style: Theme.of(context).textTheme.headlineMedium),
            // TODO: Implement Auth
          ],
        ),
      ),
    );
  }
}
EOF

# Dashboard Screen
cat > lib/features/dashboard/screens/dashboard_screen.dart << 'EOF'
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(child: Text('Dashboard Content')),
    );
  }
}
EOF

# Invoices Screen
cat > lib/features/invoices/screens/invoices_screen.dart << 'EOF'
import 'package:flutter/material.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faktúry')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: const Center(child: Text('Zoznam faktúr')),
    );
  }
}
EOF

# Expenses Screen
cat > lib/features/expenses/screens/expenses_screen.dart << 'EOF'
import 'package:flutter/material.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Výdavky')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.camera_alt),
      ),
      body: const Center(child: Text('Zoznam výdavkov')),
    );
  }
}
EOF

# Documents Screen
cat > lib/features/documents/screens/documents_screen.dart << 'EOF'
import 'package:flutter/material.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dokumenty')),
      body: const Center(child: Text('Správca dokumentov')),
    );
  }
}
EOF

# AI Tools Screen
cat > lib/features/ai_tools/screens/ai_tools_screen.dart << 'EOF'
import 'package:flutter/material.dart';

class AiToolsScreen extends StatelessWidget {
  const AiToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Nástroje')),
      body: const Center(child: Text('AI Generátor Emailov & Poradca')),
    );
  }
}
EOF

# Settings Screen
cat > lib/features/settings/screens/settings_screen.dart << 'EOF'
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nastavenia')),
      body: const Center(child: Text('Profil a nastavenia')),
    );
  }
}
EOF

# 7. Create Shell (Bottom Navigation)
progress "Creating Navigation Shell..."
cat > lib/shared/widgets/scaffold_with_navbar.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Faktúry',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money),
            selectedIcon: Icon(Icons.attach_money),
            label: 'Výdavky',
          ),
           NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Nastavenia',
          ),
        ],
      ),
    );
  }
}
EOF

# 8. Setup Router
progress "Configuring GoRouter..."
cat > lib/core/router/app_router.dart << 'ROUTER_EOF'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/invoices/screens/invoices_screen.dart';
import '../../features/expenses/screens/expenses_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/ai_tools/screens/ai_tools_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../shared/widgets/scaffold_with_navbar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/invoices',
                builder: (context, state) => const InvoicesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                builder: (context, state) => const ExpensesScreen(),
              ),
            ],
          ),
           StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ai-tools',
                builder: (context, state) => const AiToolsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
ROUTER_EOF

# 9. Update App Entry Point
progress "Updating App Entry Point..."
cat > lib/app.dart << 'APP_EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

class BizAgentApp extends ConsumerWidget {
  const BizAgentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'BizAgent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
APP_EOF

# 10. Update Main (just to be safe, keep firebase init)
cat > lib/main.dart << 'MAIN_EOF'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase init warning: $e');
  }
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  runApp(const ProviderScope(child: BizAgentApp()));
}
MAIN_EOF

progress "Running flutter pub get..."
flutter pub get

echo ""
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                  ✅ UPGRADE COMPLETE! ✅                 ║
╚═══════════════════════════════════════════════════════════╝
EOF
success "BizAgent has been upgraded to Feature-First Architecture!"
echo "Run 'flutter run' to see the new navigation structure."
