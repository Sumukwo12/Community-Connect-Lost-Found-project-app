import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passwordCtrl = TextEditingController();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AuthProvider>();
    final response = await provider.login(
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    if (response.success) {
      AppHelpers.showSuccess(context, 'Login successful! Welcome back.');
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      AppHelpers.showError(context, response.message);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Logo & Welcome
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, Color(0xFF9B8FFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.manage_search_rounded, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Community Connect',
                    style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w700, fontFamily: 'Outfit',
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Lost & Found for your community',
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Outfit'),
                  ),
                ),
                const SizedBox(height: 48),
                Text('Welcome Back 👋',
                    style: AppTheme.headline2.copyWith(
                      color: Theme.of(context).colorScheme.onBackground,
                    )),
                const SizedBox(height: 6),
                Text('Sign in to your account',
                    style: AppTheme.body2.copyWith(color: Colors.grey.shade500)),
                const SizedBox(height: 28),

                // Email
                CustomTextField(
                  label:       'Email Address',
                  hint:        'you@example.com',
                  controller:  _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon:  const Icon(Icons.email_rounded, size: 20),
                  validator:   Validators.email,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  label:       'Password',
                  hint:        'Enter your password',
                  controller:  _passwordCtrl,
                  obscureText: true,
                  prefixIcon:  const Icon(Icons.lock_rounded, size: 20),
                  validator:   Validators.password,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    ),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),

                // Login button
                ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  child: isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
                const SizedBox(height: 32),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ",
                        style: AppTheme.body2.copyWith(color: Colors.grey.shade500)),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text('Create Account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
