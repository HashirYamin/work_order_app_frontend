import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/auth_api_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';

  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthApiService authApiService = AuthApiService();

  final fullNameController = TextEditingController();
  final qidController = TextEditingController();
  final jobTitleController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    fullNameController.dispose();
    qidController.dispose();
    jobTitleController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool isValidQatarPhone(String phone) {
    return RegExp(r'^\d{8}$').hasMatch(phone.trim());
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

  Future<void> submitRegistration() async {
    final String fullName = fullNameController.text.trim();
    final String qidNumber = qidController.text.trim();
    final String jobTitle = jobTitleController.text.trim();
    final String phone = phoneController.text.trim();
    final String password = passwordController.text.trim();
    final String confirmPassword = confirmPasswordController.text.trim();

    if (fullName.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    if (!RegExp(r'^\d{8}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 8-digit Qatar phone number.'),
        ),
      );
      return;
    }

    final String? passwordError = validatePassword(password);

    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError)),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password and confirm password must match')),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final Map<String, dynamic> response = await authApiService.register(
        fullName: fullName,
        qidNumber: qidNumber,
        jobTitle: jobTitle,
        phone: phone,
        password: password,
      );

      final bool success = response['success'] == true;

      if (!success) {
        throw Exception(response['message'] ?? 'Registration failed');
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Registration Submitted'),
            content: const Text(
              'The Registration is submitted succesfully, Please wait for Administrator approval',
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

  Widget passwordField() {
    return TextField(
      controller: passwordController,
      obscureText: obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              obscurePassword = !obscurePassword;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Text(
                'Fill in your details below',
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              AppTextField(
                label: 'Full Name',
                controller: fullNameController,
                prefixIcon: Icons.person,
              ),

              const SizedBox(height: 12),

              AppTextField(
                label: 'QID Number',
                controller: qidController,
                prefixIcon: Icons.badge,
              ),

              const SizedBox(height: 12),

              AppTextField(
                label: 'Job Title / Designation',
                controller: jobTitleController,
                prefixIcon: Icons.work,
              ),

              const SizedBox(height: 12),

              qatarPhoneField(),

              const SizedBox(height: 12),

              passwordField(),

              const SizedBox(height: 12),

              confirmPasswordField(),

              const SizedBox(height: 12),

              const Text(
                'Password must contain uppercase, lowercase, number, special character and minimum 8 characters.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 22),

              AppButton(
                title: 'Submit Registration',
                loading: loading,
                onTap: submitRegistration,
              ),
            ],
          ),
        ),
      ),
    );
  }
}