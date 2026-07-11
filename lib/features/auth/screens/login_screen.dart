import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/biz_fullscreen_loader.dart';
import '../providers/auth_provider.dart';
import '../../../core/ui/biz_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLogin) {
        await ref.read(authControllerProvider.notifier).signIn(email, password);
      } else {
        await ref.read(authControllerProvider.notifier).signUp(email, password);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: BizTheme.silverMist,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo or Title
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 64,
                        color: BizTheme.slovakBlue,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _isLogin ? 'Vitajte späť' : 'Vytvoriť účet',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Zadajte platný email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Heslo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Heslo musí mať aspoň 6 znakov';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Main Action Button
                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BizTheme.slovakBlue,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: BizTheme.slovakBlue.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isLogin ? 'Prihlásiť sa' : 'Registrovať',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),

                      // Error Display
                      if (authState.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authState.error.toString(),
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                        child: Text(
                          _isLogin
                              ? 'Nemáte účet? Registrujte sa'
                              : 'Už máte účet? Prihláste sa',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (authState.isLoading)
            const BizFullscreenLoader(label: 'Spracovávam...'),
        ],
      ),
    );
  }
}
