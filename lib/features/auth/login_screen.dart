import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/auth_api_service.dart';
import '../../core/services/user_session_service.dart';
import '../../shared/widgets/app_button.dart';
import '../work_order/work_order_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthApiService authApiService = AuthApiService();
  final UserSessionService userSessionService = UserSessionService();

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool rememberMe = true;
  bool loading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool isValidQatarPhone(String phone) {
    return RegExp(r'^\d{8}$').hasMatch(phone.trim());
  }

  void clearPasswordAfterFailedAttempt() {
    passwordController.clear();

    if (mounted) {
      setState(() {
        obscurePassword = true;
      });
    }
  }

  void showPendingApprovalDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Account Pending Approval'),
          content: const Text(
            'Your account request is under review. Please wait for Administrator approval.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> login() async {
    final String phone = phoneController.text.trim();
    final String password = passwordController.text.trim();

    if (!RegExp(r'^\d{8}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 8-digit Qatar phone number.'),
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter password')),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final Map<String, dynamic> response = await authApiService.login(
        phone: phone,
        password: password,
      );

      final bool success = response['success'] == true;

      if (!success) {
        final String message = response['message']?.toString() ?? 'Login failed';

        clearPasswordAfterFailedAttempt();

        if (message.toLowerCase().contains('pending') ||
            message.toLowerCase().contains('approval') ||
            message.toLowerCase().contains('under review')) {
          if (!mounted) return;
          showPendingApprovalDialog();
          return;
        }

        throw Exception(message);
      }

      final String token = response['token']?.toString() ?? '';
      final Map<String, dynamic> user = Map<String, dynamic>.from(
        response['user'] ?? {},
      );

      await userSessionService.saveSession(
        token: token,
        user: user,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkOrderScreen()),
      );
    } catch (error) {
      if (!mounted) return;

      clearPasswordAfterFailedAttempt();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const SizedBox(height: 45),

              Container(
                height: 82,
                width: 82,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 42,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Work Order Flow',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Sign in to continue',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 26),

              qatarPhoneField(),

              const SizedBox(height: 14),

              passwordField(),

              const SizedBox(height: 8),

              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (value) {
                      setState(() {
                        rememberMe = value ?? false;
                      });
                    },
                  ),
                  const Text('Remember me'),
                ],
              ),

              const SizedBox(height: 10),

              AppButton(
                title: 'Login',
                loading: loading,
                onTap: login,
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: loading
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              RegisterScreen.routeName,
                            );
                          },
                    child: const Text('Register'),
                  ),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              ForgotPasswordScreen.routeName,
                            );
                          },
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}