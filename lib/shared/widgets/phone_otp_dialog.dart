import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/firebase_phone_auth_service.dart';

Future<String?> showPhoneOtpDialog({
  required BuildContext context,
  required String phone,
  required FirebasePhoneAuthService phoneAuthService,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return PhoneOtpDialog(
        phone: phone,
        phoneAuthService: phoneAuthService,
      );
    },
  );
}

class PhoneOtpDialog extends StatefulWidget {
  const PhoneOtpDialog({
    required this.phone,
    required this.phoneAuthService,
    super.key,
  });

  final String phone;
  final FirebasePhoneAuthService phoneAuthService;

  @override
  State<PhoneOtpDialog> createState() => _PhoneOtpDialogState();
}

class _PhoneOtpDialogState extends State<PhoneOtpDialog> {
  final TextEditingController otpController = TextEditingController();

  String? verificationId;
  int? resendToken;

  bool sendingCode = true;
  bool verifyingCode = false;

  String? errorMessage;

  int resendSeconds = 30;
  Timer? resendTimer;

  bool get busy => sendingCode || verifyingCode;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      sendCode();
    });
  }

  @override
  void dispose() {
    resendTimer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  void startResendTimer() {
    resendTimer?.cancel();

    setState(() {
      resendSeconds = 30;
    });

    resendTimer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (resendSeconds <= 1) {
          timer.cancel();

          setState(() {
            resendSeconds = 0;
          });

          return;
        }

        setState(() {
          resendSeconds--;
        });
      },
    );
  }

  Future<void> sendCode({
    bool resend = false,
  }) async {
    if (sendingCode) {
      // Allow the initial request started from initState.
    }

    if (mounted) {
      setState(() {
        sendingCode = true;
        errorMessage = null;
      });
    }

    await widget.phoneAuthService.sendOtp(
      phone: widget.phone,
      forceResendingToken: resend ? resendToken : null,
      onCodeSent: (
        String newVerificationId,
        int? newResendToken,
      ) {
        if (!mounted) return;

        setState(() {
          verificationId = newVerificationId;
          resendToken = newResendToken;
          sendingCode = false;
          errorMessage = null;
        });

        startResendTimer();
      },
      onAutomaticVerificationCompleted: (
        String firebaseIdToken,
      ) async {
        if (!mounted) return;

        Navigator.of(context).pop(firebaseIdToken);
      },
      onError: (String message) {
        if (!mounted) return;

        setState(() {
          sendingCode = false;
          verifyingCode = false;
          errorMessage = message;
        });
      },
    );
  }

  Future<void> verifyCode() async {
    final String code = otpController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        errorMessage = 'Enter the 6-digit verification code';
      });
      return;
    }

    final String? currentVerificationId = verificationId;

    if (currentVerificationId == null) {
      setState(() {
        errorMessage = 'Request a verification code first';
      });
      return;
    }

    setState(() {
      verifyingCode = true;
      errorMessage = null;
    });

    try {
      final String firebaseIdToken = await widget.phoneAuthService.verifyOtp(
        verificationId: currentVerificationId,
        smsCode: code,
      );

      if (!mounted) return;

      Navigator.of(context).pop(firebaseIdToken);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        verifyingCode = false;
        errorMessage = error
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('FormatException: ', '');
      });
    }
  }

  Future<void> cancelVerification() async {
    await widget.phoneAuthService.signOut();

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedPhone =
        widget.phoneAuthService.toQatarE164(widget.phone);

    return AlertDialog(
      title: const Text('Verify Phone Number'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sendingCode
                  ? 'Requesting a verification code for $formattedPhone...'
                  : 'Enter the 6-digit code sent to $formattedPhone.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Your phone number is processed by Firebase Authentication for verification and abuse prevention.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 18),
            if (sendingCode)
              const Center(
                child: CircularProgressIndicator(),
              )
            else ...[
              TextField(
                controller: otpController,
                enabled: !busy,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  hintText: '123456',
                  prefixIcon: Icon(Icons.sms_outlined),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  if (!busy) {
                    verifyCode();
                  }
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: busy || resendSeconds > 0
                      ? null
                      : () {
                          otpController.clear();
                          sendCode(resend: true);
                        },
                  child: Text(
                    resendSeconds > 0
                        ? 'Resend in ${resendSeconds}s'
                        : 'Resend Code',
                  ),
                ),
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : cancelVerification,
          child: const Text('Cancel'),
        ),
        if (!sendingCode)
          FilledButton(
            onPressed: busy ? null : verifyCode,
            child: verifyingCode
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Verify'),
          ),
        if (!sendingCode && verificationId == null && errorMessage != null)
          TextButton(
            onPressed: busy ? null : sendCode,
            child: const Text('Retry'),
          ),
      ],
    );
  }
}
