import 'package:firebase_auth/firebase_auth.dart';

typedef OtpCodeSent = void Function(
  String verificationId,
  int? resendToken,
);

typedef AutomaticVerificationCompleted = Future<void> Function(
  String firebaseIdToken,
);

typedef PhoneVerificationError = void Function(
  String message,
);

class FirebasePhoneAuthService {
  FirebasePhoneAuthService({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  String toQatarE164(String phone) {
    final String digits = phone.replaceAll(RegExp(r'\D'), '');

    if (RegExp(r'^[3567]\d{7}$').hasMatch(digits)) {
      return '+974$digits';
    }

    if (RegExp(r'^974[3567]\d{7}$').hasMatch(digits)) {
      return '+$digits';
    }

    throw const FormatException(
      'Enter a valid 8-digit Qatar mobile number',
    );
  }

  Future<void> sendOtp({
    required String phone,
    required OtpCodeSent onCodeSent,
    required AutomaticVerificationCompleted onAutomaticVerificationCompleted,
    required PhoneVerificationError onError,
    int? forceResendingToken,
  }) async {
    final String firebasePhone;

    try {
      firebasePhone = toQatarE164(phone);
    } on FormatException catch (error) {
      onError(error.message);
      return;
    }

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: firebasePhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final String token = await _signInAndGetIdToken(credential);

            await onAutomaticVerificationCompleted(
              token,
            );
          } on FirebaseAuthException catch (error) {
            onError(_firebaseErrorMessage(error));
          } catch (_) {
            onError(
              'Automatic phone verification failed',
            );
          }
        },
        verificationFailed: (FirebaseAuthException error) {
          onError(_firebaseErrorMessage(error));
        },
        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          onCodeSent(
            verificationId,
            resendToken,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // The user may still enter the OTP manually.
        },
      );
    } on FirebaseAuthException catch (error) {
      onError(_firebaseErrorMessage(error));
    } catch (_) {
      onError(
        'Unable to start phone verification',
      );
    }
  }

  Future<String> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final String code = smsCode.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const FormatException(
        'Enter the 6-digit verification code',
      );
    }

    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );

    try {
      return await _signInAndGetIdToken(
        credential,
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(
        _firebaseErrorMessage(error),
      );
    }
  }

  Future<String> _signInAndGetIdToken(
    PhoneAuthCredential credential,
  ) async {
    final UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(
      credential,
    );

    final User? user = userCredential.user;

    if (user == null) {
      throw StateError(
        'Firebase did not return a verified user',
      );
    }

    final String? token = await user.getIdToken(true);

    if (token == null || token.isEmpty) {
      throw StateError(
        'Firebase did not return an ID token',
      );
    }

    return token;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  String _firebaseErrorMessage(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Enter a valid Qatar phone number';

      case 'invalid-verification-code':
        return 'The verification code is incorrect';

      case 'session-expired':
        return 'The verification code has expired. Request a new code.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'quota-exceeded':
        return 'The SMS verification limit has been reached.';

      case 'network-request-failed':
        return 'Check your internet connection and try again.';

      case 'app-not-authorized':
        return 'This Android app is not authorized in Firebase. Check the package name and SHA fingerprints.';

      case 'missing-client-identifier':
        return 'Firebase could not verify this Android app. Check the SHA fingerprints.';

      default:
        return error.message ?? 'Phone verification failed';
    }
  }
}
