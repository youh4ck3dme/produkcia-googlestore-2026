import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/ui/biz_theme.dart';
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
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOAuthCallbackErrorIfAny());
    }
  }

  void _showOAuthCallbackErrorIfAny() {
    final params = Uri.base.queryParameters;
    final error = params['error_description'] ?? params['error'];
    if (error == null || error.isEmpty || !mounted) return;
    _showError(
      error.contains('access_denied')
          ? context.t(AppStr.authGoogleCancelled)
          : Uri.decodeComponent(error.replaceAll('+', ' ')),
    );
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
      _showError(context.t(AppStr.authFillAllFields));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authRepositoryProvider).signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (user == null && mounted) {
        _showError(context.t(AppStr.authSignInFailed));
      }
    } on AuthException catch (e) {
      _showError(_getAuthErrorMessage(e));
    } on StateError catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(context.t(AppStr.authErrorGeneric));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _googleSignInAvailable =>
      SupabaseConfig.isReady &&
      (kIsWeb || SupabaseConfig.googleWebClientId.isNotEmpty);

  Future<void> _signInWithGoogle() async {
    if (!_googleSignInAvailable) {
      _showError(context.t(AppStr.authGoogleNotConfigured));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on AuthException catch (e) {
      _showError(_getAuthErrorMessage(e));
    } catch (e) {
      _showError(context.t(AppStr.authGoogleFailed));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError(context.t(AppStr.authFillAllFields));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError(context.t(AppStr.authPasswordMismatch));
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError(context.t(AppStr.authPasswordMinLength));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signUp(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } on AuthException catch (e) {
      _showError(_getAuthErrorMessage(e));
    } catch (e) {
      _showError(context.t(AppStr.authErrorGeneric));
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

  String _getAuthErrorMessage(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return context.t(AppStr.authWrongCredentials);
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return context.t(AppStr.authEmailRegistered);
    }
    if (msg.contains('password') && msg.contains('weak')) {
      return context.t(AppStr.authWeakPassword);
    }
    if (msg.contains('password') && (msg.contains('least') || msg.contains('6'))) {
      return context.t(AppStr.authPasswordMinLength);
    }
    if (msg.contains('email') && msg.contains('valid')) {
      return context.t(AppStr.authInvalidEmail);
    }
    if (msg.contains('confirm') || msg.contains('not confirmed')) {
      return context.t(AppStr.authConfirmEmail);
    }
    if (msg.contains('rate') || msg.contains('too many')) {
      return context.t(AppStr.authRateLimited);
    }
    return e.message.isNotEmpty ? e.message : context.t(AppStr.authErrorGeneric);
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
                          ? context.t(AppStr.authSignInSubtitle)
                          : context.t(AppStr.authSignUpSubtitle),
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
                        labelText: context.t(AppStr.authEmail),
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
                        labelText: context.t(AppStr.authPassword),
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
                          labelText: context.t(AppStr.authConfirmPassword),
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

                    // Google Sign-In
                    if (_googleSignInAvailable) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF111827),
                            side: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.35),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: Image.network(
                            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                            width: 22,
                            height: 22,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.g_mobiledata_rounded,
                              size: 28,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                          label: Text(
                            context.t(AppStr.authGoogleSignIn),
                            style: GoogleFonts.inter(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.withValues(alpha: 0.35),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              context.t(AppStr.authOrEmail),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

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
                                _isSignIn
                                    ? context.t(AppStr.authSignIn)
                                    : context.t(AppStr.authCreateAccount),
                                style: GoogleFonts.inter(
                                  fontSize: 12.8, // Reduced by 20% (16 * 0.8)
                                  fontWeight: FontWeight.w600,
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
                            ? context.t(AppStr.authNoAccountCreate)
                            : context.t(AppStr.authHasAccountSignIn),
                        style: GoogleFonts.inter(
                          color: BizTheme.slovakBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Terms
                    Text(
                      context.t(AppStr.authTermsAgree),
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
                    context.t(AppStr.authFreeTrialBadge),
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
