
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../providers/auth_provider.dart';
import '../../../shared/widgets/biz_fullscreen_loader.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../core/services/biometric_service.dart';

class ChameleonLoginScreen extends ConsumerStatefulWidget {
  const ChameleonLoginScreen({super.key});

  @override
  ConsumerState<ChameleonLoginScreen> createState() => _ChameleonLoginScreenState();
}

class _ChameleonLoginScreenState extends ConsumerState<ChameleonLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isBiometricSupported = false;

  // 🦎 Cameleon State
  double _gyroX = 0;
  double _gyroY = 0;
  StreamSubscription? _promoSubscription;
  Color _ambientColor = BizTheme.slovakBlue; // Initial Blue

  // 🌀 Animation Controllers
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _startSensors();
    _checkBiometrics();

    _rotationController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))..repeat();
    
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
  }

  Future<void> _checkBiometrics() async {
    final service = ref.read(biometricServiceProvider);
    final isSupported = await service.isBiometricAvailable();
    if (mounted) {
      setState(() => _isBiometricSupported = isSupported);
    }
  }

  Future<void> _authenticateBiometric() async {
    final service = ref.read(biometricServiceProvider);
    final authenticated = await service.authenticate(
      localizedReason: 'Overenie identity pre vstup do BizAgent aplikácie',
    );
    
    if (authenticated) {
      // For the prototype, we assume success logs you in to the dashboard
      // In a real app, this would use a stored token
      ref.read(authControllerProvider.notifier).mockSuccessLogin();
    }
  }

  void _startSensors() {
    if (kIsWeb) {
      // On Web, use Mouse Region instead of Gyro (simulated via Listener in build)
      return;
    }
    // Mobile Gyro
    _promoSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      setState(() {
        _gyroX += event.y * 0.1;
        _gyroY += event.y * 0.1;
        // Clamp values
        _gyroX = _gyroX.clamp(-20.0, 20.0);
        _gyroY = _gyroY.clamp(-20.0, 20.0);
      });
    });
  }

  @override
  void dispose() {
    _promoSubscription?.cancel();
    _rotationController.dispose();
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateAmbientColor(Color color) {
    setState(() => _ambientColor = color);
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      // Flash effect on submit
      _updateAmbientColor(const Color(0xFF0F9D58)); // Success Green hint

      if (_isLogin) {
        await ref.read(authControllerProvider.notifier).signIn(email, password);
      } else {
        await ref.read(authControllerProvider.notifier).signUp(email, password);
      }
    } else {
      _updateAmbientColor(BizTheme.richCrimson); // Error -> Crimson
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: MouseRegion(
        onHover: (event) {
          if (kIsWeb) {
            final size = MediaQuery.of(context).size;
            setState(() {
              _gyroX = (event.localPosition.dx - size.width / 2) * -0.05;
              _gyroY = (event.localPosition.dy - size.height / 2) * -0.05;
            });
          }
        },
        child: Stack(
          children: [
            // 🖱️ 2. Parallax Floating Elements (Removed for clean white look)
            // _buildParallaxOrbs(),

            // 🔐 3. Animated Neon Card
            Center(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutExpo,
                builder: (context, val, child) {
                  return Transform.scale(
                    scale: 0.9 + (0.1 * val),
                    child: Opacity(
                      opacity: val,
                      child: child,
                    ),
                  );
                },
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(3), // Border width
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26), // 24 + padding
                        gradient: SweepGradient(
                          transform: GradientRotation(_rotationController.value * 2 * 3.14159),
                          colors: const [
                            Colors.white,
                            BizTheme.slovakBlue, // Blue
                            Colors.white,
                            BizTheme.nationalRed, // Red
                            Colors.white,
                          ],
                          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: BizTheme.slovakBlue.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        width: math.min(MediaQuery.of(context).size.width * 0.9, 420),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _ambientColor.withValues(alpha: 0.1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _ambientColor.withValues(alpha: 0.2),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                      )
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.verified_user_outlined,
                                    size: 48,
                                    color: _ambientColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Title
                                Text(
                                  _isLogin ? 'BizAgent Portal' : 'Nová Registrácia',
                                  style: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Inteligentná správa podnikania',
                                  style: TextStyle(color: Colors.black54, fontSize: 14),
                                ),
                                const SizedBox(height: 32),

                                // Inputs
                                _buildChameleonInput(
                                  controller: _emailController,
                                  icon: Icons.alternate_email,
                                  label: 'Emailová adresa',
                                  onFocus: () => _updateAmbientColor(BizTheme.fusionAzure),
                                ),
                                const SizedBox(height: 16),
                                _buildChameleonInput(
                                  controller: _passwordController,
                                  icon: Icons.key_outlined,
                                  label: 'Prístupové heslo',
                                  isPassword: true,
                                  onFocus: () => _updateAmbientColor(BizTheme.nationalRed),
                                ),
                                const SizedBox(height: 24),

                                // Action Button
                                _buildNeonButton(
                                  label: _isLogin ? 'VSTÚPIŤ DO SYSTÉMU' : 'VYTVORIŤ ÚČET',
                                  onTap: authState.isLoading ? null : _submit,
                                ),

                                if (_isLogin && _isBiometricSupported) ...[
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: _authenticateBiometric,
                                    icon: const Icon(Icons.fingerprint),
                                    label: const Text('Prihlásiť biometriou'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 48),
                                      side: BorderSide(color: _ambientColor.withValues(alpha: 0.3)),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 24),
                                
                                // Google Sign In
                                _buildGoogleNeonButton(authState.isLoading),

                                const SizedBox(height: 24),
                                
                                // Toggle
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                      // Reset color
                                      _ambientColor = BizTheme.slovakBlue;
                                    });
                                  },
                                  child: Text(
                                    _isLogin ? 'Ešte nemáte účet? Registrácia' : 'Späť na prihlásenie',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            if (authState.isLoading)
             const BizFullscreenLoader(label: 'Overujem biometriu...'),
          ],
        ),
      ),
    );
  }

  Widget _buildChameleonInput({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    bool isPassword = false,
    required VoidCallback onFocus,
  }) {
    return Focus(
      onFocusChange: (focused) {
        if (focused) onFocus();
      },
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black45),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _ambientColor, width: 2),
            gapPadding: 4,
          ),
          filled: true,
          fillColor: Colors.grey.withValues(alpha: 0.05),
        ),
        validator: (v) => (v?.isEmpty ?? true) ? 'Povinné pole' : null,
      ),
    );
  }

  Widget _buildNeonButton({required String label, required VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _ambientColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _ambientColor, // Adapts to context
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleNeonButton(bool isLoading) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Rotating Neon Gradient
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: SweepGradient(
                    transform: GradientRotation(_rotationController.value * 2 * 3.14159),
                    colors: const [
                       Colors.white,
                       BizTheme.slovakBlue, // Blue
                       Colors.white,
                       BizTheme.nationalRed, // Red
                       Colors.white,
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BizTheme.slovakBlue.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              );
            },
          ),
          // 2. The Button (White Overlay for Light Mode)
          Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(10),
            ),
            child: OutlinedButton(
               onPressed: isLoading
                  ? null
                  : () async {
                      await ref.read(authControllerProvider.notifier).signInWithGoogle();
                    },
              style: OutlinedButton.styleFrom(
                splashFactory: NoSplash.splashFactory,
                overlayColor: Colors.transparent,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Image.asset('assets/icons/google_g.png'),
                  ),
                  const SizedBox(width: 12),
                  const Flexible(
                    child: Text(
                      'Cez Google',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
