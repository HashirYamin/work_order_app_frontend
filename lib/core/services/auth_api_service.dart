import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class AuthApiService {
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    if (ApiConfig.useFakeApi) {
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'message': 'Fake login successful',
        'token': 'fake_token_for_testing',
        'user': {
          'id': '1',
          'name': 'Technician User',
          'phone': phone,
          'role': 'technician',
        },
      };
    }

    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phone': phone,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String qidNumber,
    required String jobTitle,
    required String phone,
    required String password,
  }) async {
    if (ApiConfig.useFakeApi) {
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'message': 'Registration submitted. Admin approval required.',
      };
    }

    final response = await http.post(
      Uri.parse(ApiConfig.register),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fullName': fullName,
        'qidNumber': qidNumber,
        'jobTitle': jobTitle,
        'phone': phone,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String phone,
  }) async {
    if (ApiConfig.useFakeApi) {
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'message': 'OTP generated for testing.',
        'devOtp': '123456',
      };
    }

    final response = await http.post(
      Uri.parse(ApiConfig.forgotPassword),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phone': phone,
      }),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteAccount({
    required String token,
    required String password,
  }) async {
    if (ApiConfig.useFakeApi) {
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'message': 'Your account has been permanently deleted',
      };
    }

    final http.Response response = await http.delete(
      Uri.parse(ApiConfig.deleteAccount),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'password': password,
      }),
    );

    try {
      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (_) {
      return {
        'success': false,
        'message': 'Unexpected response from the server',
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    if (ApiConfig.useFakeApi) {
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'message': 'Password reset successful.',
      };
    }

    final response = await http.post(
      Uri.parse(ApiConfig.resetPassword),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phone': phone,
        'otp': otp,
        'newPassword': newPassword,
      }),
    );

    return jsonDecode(response.body);
  }
}
