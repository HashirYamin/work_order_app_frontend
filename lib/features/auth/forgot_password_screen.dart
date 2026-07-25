import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/auth_api_service.dart';
import '../../shared/widgets/app_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const routeName = '/forgot-password';

  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthApiService authApiService = AuthApiService();

  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool otpSent = false;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  String message = '';
  String testingOtp = '';

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
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

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=]').hasMatch(password)) {
      return 'Password must contain one special character';
    }

    return null;
  }

  Future<void> sendOtp() async {
    final String phone = phoneController.text.trim();

    if (!RegExp(r'^\d{8}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 8-digit Qatar phone number.'),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
      message = '';
      testingOtp = '';
    });

    try {
      final Map<String, dynamic> response =
          await authApiService.forgotPassword(phone: phone);

      final bool success = response['success'] == true;

      if (!success) {
        throw Exception(response['message'] ?? 'Failed to generate OTP');
      }

      if (!mounted) return;

      setState(() {
        otpSent = true;
        message = response['message']?.toString() ??
            'OTP generated successfully. Please enter the OTP below.';
        testingOtp = response['devOtp']?.toString() ?? '';
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> resetPassword() async {
    final String phone = phoneController.text.trim();
    final String otp = otpController.text.trim();
    final String newPassword = newPasswordController.text.trim();
    final String confirmPassword = confirmPasswordController.text.trim();

    if (!RegExp(r'^\d{8}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 8-digit Qatar phone number.'),
        ),
      );
      return;
    }

    if (otp.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill OTP and password fields')),
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
        const SnackBar(content: Text('Password and confirm password must match')),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final Map<String, dynamic> response =
          await authApiService.resetPassword(
        phone: phone,
        otp: otp,
        newPassword: newPassword,
      );

      final bool success = response['success'] == true;

      if (!success) {
        throw Exception(response['message'] ?? 'Password reset failed');
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Password Reset Successful'),
            content: const Text(
              'Your password has been reset successfully. Please login with your new password.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
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
      enabled: !otpSent && !loading,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      decoration: InputDecoration(
        labelText: 'Phone Number',
        hintText: '8-digit Qatar number',
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget otpField() {
    return TextField(
      controller: otpController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        labelText: 'OTP',
        hintText: 'Enter OTP',
        prefixIcon: const Icon(Icons.password),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget newPasswordField() {
    return TextField(
      controller: newPasswordController,
      obscureText: obscureNewPassword,
      decoration: InputDecoration(
        labelText: 'New Password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            obscureNewPassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              obscureNewPassword = !obscureNewPassword;
            });
          },
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
      obscureText: obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              obscureConfirmPassword = !obscureConfirmPassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget testingOtpBox() {
    if (testingOtp.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Testing OTP',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            testingOtp,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'For this demo version, OTP is shown on screen. In production, OTP can be sent by SMS.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget messageBox() {
    if (message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Enter your registered 8-digit Qatar phone number. For this demo version, the OTP will be shown on screen for testing. In production, OTP can be sent by SMS.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 22),

              qatarPhoneField(),

              const SizedBox(height: 14),

              if (!otpSent)
                AppButton(
                  title: 'Send OTP',
                  loading: loading,
                  onTap: sendOtp,
                ),

              if (otpSent) ...[
                messageBox(),

                const SizedBox(height: 12),

                testingOtpBox(),

                const SizedBox(height: 14),

                otpField(),

                const SizedBox(height: 14),

                newPasswordField(),

                const SizedBox(height: 14),

                confirmPasswordField(),

                const SizedBox(height: 12),

                const Text(
                  'Password must contain uppercase, lowercase, number, special character and minimum 8 characters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 22),

                AppButton(
                  title: 'Reset Password',
                  loading: loading,
                  onTap: resetPassword,
                ),

                const SizedBox(height: 12),

                Center(
                  child: TextButton(
                    onPressed: loading
                        ? null
                        : () {
                            setState(() {
                              otpSent = false;
                              message = '';
                              testingOtp = '';
                              otpController.clear();
                              newPasswordController.clear();
                              confirmPasswordController.clear();
                            });
                          },
                    child: const Text('Change phone number'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}