import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/auth_api_service.dart';
import '../../core/services/firebase_phone_auth_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/phone_otp_dialog.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const routeName = '/forgot-password';

  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthApiService authApiService = AuthApiService();

  final FirebasePhoneAuthService phoneAuthService = FirebasePhoneAuthService();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController newPasswordController = TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool loading = false;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    phoneController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool isValidQatarPhone(String phone) {
    return RegExp(r'^[3567]\d{7}$').hasMatch(phone.trim());
  }

  String? validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain one uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain one lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain one number';
    }

    if (!RegExp(
      r'[!@#$%^&*(),.?":{}|<>_\-+=]',
    ).hasMatch(password)) {
      return 'Password must contain one special character';
    }

    return null;
  }

  Future<void> resetPassword() async {
    final String phone = phoneController.text.trim();

    final String newPassword = newPasswordController.text.trim();

    final String confirmPassword = confirmPasswordController.text.trim();

    if (!isValidQatarPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid 8-digit Qatar mobile number',
          ),
        ),
      );
      return;
    }

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter and confirm your new password',
          ),
        ),
      );
      return;
    }

    final String? passwordError = validatePassword(newPassword);

    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError)),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password and confirm password must match',
          ),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final String? firebaseIdToken = await showPhoneOtpDialog(
        context: context,
        phone: phone,
        phoneAuthService: phoneAuthService,
      );

      if (firebaseIdToken == null) {
        return;
      }

      final Map<String, dynamic> response =
          await authApiService.resetPasswordWithPhone(
        firebaseIdToken: firebaseIdToken,
        newPassword: newPassword,
      );

      final bool success = response['success'] == true;

      if (!success) {
        throw Exception(
          response['message'] ?? 'Password reset failed',
        );
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text(
              'Password Reset Successful',
            ),
            content: Text(
              response['message']?.toString() ??
                  'Your password has been reset. Please login with your new password.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      await phoneAuthService.signOut();

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Widget qatarPhoneField() {
    return TextField(
      controller: phoneController,
      enabled: !loading,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      decoration: InputDecoration(
        labelText: 'Registered Phone Number',
        hintText: '8-digit Qatar mobile number',
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget newPasswordField() {
    return TextField(
      controller: newPasswordController,
      enabled: !loading,
      obscureText: obscureNewPassword,
      decoration: InputDecoration(
        labelText: 'New Password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          onPressed: loading
              ? null
              : () {
                  setState(() {
                    obscureNewPassword = !obscureNewPassword;
                  });
                },
          icon: Icon(
            obscureNewPassword ? Icons.visibility_off : Icons.visibility,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget confirmPasswordField() {
    return TextField(
      controller: confirmPasswordController,
      enabled: !loading,
      obscureText: obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: 'Confirm New Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: loading
              ? null
              : () {
                  setState(() {
                    obscureConfirmPassword = !obscureConfirmPassword;
                  });
                },
          icon: Icon(
            obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Icon(
                Icons.lock_reset,
                size: 72,
              ),
              const SizedBox(height: 14),
              const Text(
                'Verify your registered phone number to set a new password.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              qatarPhoneField(),
              const SizedBox(height: 14),
              newPasswordField(),
              const SizedBox(height: 14),
              confirmPasswordField(),
              const SizedBox(height: 12),
              const Text(
                'Password must contain uppercase lowercase number special character and at least 8 characters.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                title: 'Verify Phone & Reset Password',
                loading: loading,
                onTap: resetPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
