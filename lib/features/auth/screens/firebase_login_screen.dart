import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../core/debug/agent_log.dart';
import '../providers/auth_repository.dart';

class FirebaseLoginScreen extends ConsumerStatefulWidget {
  const FirebaseLoginScreen({super.key});

  @override
  ConsumerState<FirebaseLoginScreen> createState() => _FirebaseLoginScreenState();
}

class _FirebaseLoginScreenState extends ConsumerState<FirebaseLoginScreen> {
  bool _isSignIn = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Force light status bar for consistent design
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Vyplňte všetky polia');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      _showError(_getFirebaseErrorMessage(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Vyplňte všetky polia');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Heslá sa nezhodujú');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Heslo musí mať aspoň 6 znakov');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      _showError(_getFirebaseErrorMessage(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // #region agent log
      agentLog(
        hypothesisId: 'H2',
        location: 'lib/features/auth/screens/firebase_login_screen.dart:_signInWithGoogle:tap',
        message: 'User tapped Google sign-in button',
        data: {'isSignIn': _isSignIn},
      );
      // #endregion agent log

      // Single source of truth: AuthRepository handles web/native specifics.
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (user == null) {
        // Cancelled or failed without FirebaseAuthException.
        // #region agent log
        agentLog(
          hypothesisId: 'H2',
          location: 'lib/features/auth/screens/firebase_login_screen.dart:_signInWithGoogle:nullUser',
          message: 'Google sign-in returned null user (cancel/fail)',
          data: const {},
        );
        // #endregion agent log
        _showError('Prihlásenie bolo zrušené alebo zlyhalo.');
      }
    } on FirebaseAuthException catch (e) {
      // #region agent log
      agentLog(
        hypothesisId: 'H3',
        location: 'lib/features/auth/screens/firebase_login_screen.dart:_signInWithGoogle:FirebaseAuthException',
        message: 'FirebaseAuthException during Google sign-in',
        data: {'code': e.code},
      );
      // #endregion agent log
      _showError(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      // #region agent log
      agentLog(
        hypothesisId: 'H4',
        location: 'lib/features/auth/screens/firebase_login_screen.dart:_signInWithGoogle:catch',
        message: 'Non-Firebase exception during Google sign-in',
        data: {
          'type': e.runtimeType.toString(),
          'msg': e.toString().substring(0, e.toString().length.clamp(0, 200)),
        },
      );
      // #endregion agent log
      _showError('Došlo k chybe pri prihlasovaní: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BizTheme.nationalRed,
      ),
    );
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Používateľ s týmto emailom neexistuje';
      case 'wrong-password':
        return 'Nesprávne heslo';
      case 'email-already-in-use':
        return 'Tento email je už registrovaný';
      case 'weak-password':
        return 'Heslo je príliš slabé';
      case 'invalid-email':
        return 'Neplatný email';
      case 'too-many-requests':
        return 'Príliš veľa pokusov. Skúste neskôr';
      default:
        return 'Došlo k chybe. Skúste znovu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Clean White Background
          // Centered Login Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo/Icon Section
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [BizTheme.slovakBlue, BizTheme.nationalRed],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: BizTheme.slovakBlue.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.business_center_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'BizAgent',
                      style: GoogleFonts.outfit(
                        fontSize: 25.6, // Reduced by 20% (32 * 0.8)
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      _isSignIn
                          ? 'Vitajte späť!\nPrihláste sa do svojho účtu'
                          : 'Začnite svoju\npodnikateľskú cestu',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12.8, // Reduced by 20% (16 * 0.8)
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Email Field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: 0.05),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Heslo',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: 0.05),
                      ),
                    ),

                    // Confirm Password (only for sign up)
                    if (!_isSignIn) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Potvrďte heslo',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.withValues(alpha: 0.05),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Sign In/Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : (_isSignIn ? _signInWithEmail : _signUpWithEmail),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BizTheme.slovakBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: BizTheme.slovakBlue.withValues(alpha: 0.3),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                _isSignIn ? 'Prihlásiť sa' : 'Vytvoriť účet',
                                style: GoogleFonts.inter(
                                  fontSize: 12.8, // Reduced by 20% (16 * 0.8)
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'alebo',
                            style: TextStyle(color: Colors.grey.withValues(alpha: 0.6)),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Google Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        icon: Image.asset(
                          'assets/icons/google_g.png',
                          height: 24,
                          width: 24,
                        ),
                        label: Text(
                          'Pokračovať s Google',
                          style: GoogleFonts.inter(
                            fontSize: 12.8, // Reduced by 20% (16 * 0.8)
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Toggle Sign In/Sign Up
                    TextButton(
                      onPressed: () => setState(() => _isSignIn = !_isSignIn),
                      child: Text(
                        _isSignIn
                            ? 'Nemáte účet? Vytvorte si ho'
                            : 'Už máte účet? Prihláste sa',
                        style: GoogleFonts.inter(
                          color: BizTheme.slovakBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Terms
                    Text(
                      'Používaním aplikácie súhlasíte s našimi podmienkami používania.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.6),
                        fontSize: 9.6, // Reduced by 20% (12 * 0.8)
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top Promo Badge (same as onboarding)
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "7 Dní Zdarma",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
