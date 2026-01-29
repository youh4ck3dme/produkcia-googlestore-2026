import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_repository.dart';
import '../../../features/intro/providers/onboarding_provider.dart';
import '../../../core/services/initialization_service.dart';
import '../../../core/ui/biz_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start initialization when screen mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(initializationServiceProvider.notifier).initializeApp();
    });
  }

  void _checkAuth() {
     // Don't redirect if initialization is still in progress
     final init = ref.read(initializationServiceProvider);
     if (!init.isCompleted) return;

     final authState = ref.read(authStateProvider);
     final onboardingState = ref.read(onboardingProvider);
     
     if (authState.valueOrNull != null) {
       if (onboardingState.valueOrNull == true) {
         context.go('/dashboard');
       } else {
         context.go('/onboarding');
       }
     } else {
       context.go('/login');
     }
  }

  @override
  Widget build(BuildContext context) {
    final initState = ref.watch(initializationServiceProvider);

    // Listen for completion
    ref.listen(initializationServiceProvider, (previous, next) {
      if (next.isCompleted) {
        _checkAuth();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Branding Image (Fullscreen or large)
          Image.asset(
            'assets/images/splash_branding.webp',
            fit: BoxFit.cover,
          ),
          
          // 2. Overlay Gradient for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),

          // 3. Loading Content at Bottom
          Positioned(
            left: 20,
            right: 20,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  initState.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: initState.progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      BizTheme.slovakBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${(initState.progress * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
