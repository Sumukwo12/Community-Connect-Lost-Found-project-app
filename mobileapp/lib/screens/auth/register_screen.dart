import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _confirmPwdCtrl  = TextEditingController();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AuthProvider>();
    final response = await provider.register(
      fullName:        _nameCtrl.text.trim(),
      email:           _emailCtrl.text.trim(),
      phone:           _phoneCtrl.text.trim(),
      password:        _passwordCtrl.text,
      confirmPassword: _confirmPwdCtrl.text,
    );
    if (!mounted) return;
    if (response.success) {
      AppHelpers.showSuccess(context, 'Account created successfully!');
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      AppHelpers.showError(context, response.message);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPwdCtrl.dispose();
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
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Create Account',  style: AppTheme.headline2),
                const SizedBox(height: 6),
                Text('Join your local community',
                    style: AppTheme.body2.copyWith(color: Colors.grey.shade500)),
                const SizedBox(height: 28),

                // Full Name
                CustomTextField(
                  label:      'Full Name',
                  hint:       'John Doe',
                  controller: _nameCtrl,
                  prefixIcon: const Icon(Icons.person_rounded, size: 20),
                  validator:  (v) => Validators.minLength(v, 2, 'Full name'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

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

                // Phone
                CustomTextField(
                  label:       'Phone Number',
                  hint:        '+1 234 567 8900',
                  controller:  _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  prefixIcon:  const Icon(Icons.phone_rounded, size: 20),
                  validator:   Validators.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  label:       'Password',
                  hint:        'At least 8 characters',
                  controller:  _passwordCtrl,
                  obscureText: true,
                  prefixIcon:  const Icon(Icons.lock_rounded, size: 20),
                  validator:   Validators.password,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                CustomTextField(
                  label:       'Confirm Password',
                  hint:        'Repeat your password',
                  controller:  _confirmPwdCtrl,
                  obscureText: true,
                  prefixIcon:  const Icon(Icons.lock_outline_rounded, size: 20),
                  validator:   (v) => Validators.confirmPassword(v, _passwordCtrl.text),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: isLoading ? null : _register,
                  child: isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: AppTheme.body2.copyWith(color: Colors.grey.shade500)),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text('Sign In'),
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
