import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateProfileInfo() async {
    if (!_profileFormKey.currentState!.validate()) return;

    final provider = context.read<AuthProvider>();
    final res = await provider.updateProfile(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    if (res.success) {
      AppHelpers.showSuccess(context, 'Profile information updated successfully.');
    } else {
      AppHelpers.showError(context, res.message);
    }
  }

  Future<void> _updatePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final provider = context.read<AuthProvider>();
    final res = await provider.updateProfile(
      currentPassword: _currentPwdCtrl.text,
      newPassword: _newPwdCtrl.text,
    );

    if (!mounted) return;
    if (res.success) {
      _currentPwdCtrl.clear();
      _newPwdCtrl.clear();
      _confirmPwdCtrl.clear();
      AppHelpers.showSuccess(context, 'Password changed successfully.');
    } else {
      AppHelpers.showError(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final user = context.watch<AuthProvider>().user;

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Section
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 16),
              Form(
                key: _profileFormKey,
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      controller: _nameCtrl,
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      validator: (v) => Validators.minLength(v, 2, 'Full name'),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Email (Cannot be changed)',
                      hint: user?.email ?? '',
                      enabled: false,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: isLoading ? null : _updateProfileInfo,
                      child: const Text('Save Personal Info'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),
              const Divider(),
              const SizedBox(height: 24),

              // Change Password Section
              const Text(
                'Change Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your current password and choose a new one.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 16),
              Form(
                key: _passwordFormKey,
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Current Password',
                      hint: 'Enter your current password',
                      controller: _currentPwdCtrl,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      validator: (v) => Validators.required(v, 'Current password'),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'New Password',
                      hint: 'Minimum 8 characters',
                      controller: _newPwdCtrl,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Confirm New Password',
                      hint: 'Re-enter new password',
                      controller: _confirmPwdCtrl,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.check_rounded),
                      validator: (v) => Validators.confirmPassword(v, _newPwdCtrl.text),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                      ),
                      onPressed: isLoading ? null : _updatePassword,
                      child: const Text('Update Password'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
