import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_config.dart';
import 'user_session_service.dart';

class WorkOrderApiService {
  final UserSessionService userSessionService = UserSessionService();

  Future<Map<String, dynamic>> uploadWorkOrder({
    required Map<String, dynamic> workOrder,
  }) async {
    if (ApiConfig.useFakeApi) {
      await Future.delayed(const Duration(seconds: 2));

      return {
        'success': true,
        'message': 'Fake upload successful',
        'serverWorkOrderId': workOrder['id'],
        'pptStatus': 'pending_generation',
      };
    }

    return _sendMultipartWorkOrderRequest(
      endpoint: ApiConfig.uploadWorkOrder,
      workOrder: workOrder,
      extraFields: {
        'localId': workOrder['id']?.toString() ?? '',
      },
    );
  }

  Future<Map<String, dynamic>> addPhotosToExistingWorkOrder({
    required Map<String, dynamic> workOrder,
  }) async {
    if (ApiConfig.useFakeApi) {
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'message': 'Fake photos added successfully',
        'serverWorkOrderId': workOrder['serverWorkOrderId'],
        'pptStatus': 'not_generated',
      };
    }

    return _sendMultipartWorkOrderRequest(
      endpoint: ApiConfig.addPhotosToExistingWorkOrder,
      workOrder: workOrder,
      extraFields: {
        'workOrderId': workOrder['serverWorkOrderId']?.toString() ?? '',
      },
    );
  }

  Future<Map<String, dynamic>> getMyWorkOrders() async {
    if (ApiConfig.useFakeApi) {
      return {
        'success': true,
        'data': <Map<String, dynamic>>[],
      };
    }

    try {
      final String? token = await userSessionService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication token is missing',
          'data': <Map<String, dynamic>>[],
        };
      }

      final response = await http.get(
        Uri.parse(ApiConfig.myWorkOrders),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Server returned an empty response',
          'statusCode': response.statusCode,
          'data': <Map<String, dynamic>>[],
        };
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return {
          'success': false,
          'message': 'Invalid server response',
          'data': <Map<String, dynamic>>[],
        };
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Failed to load work orders',
          'statusCode': response.statusCode,
          'data': <Map<String, dynamic>>[],
        };
      }

      return {
        'success': decoded['success'] == true,
        'data': decoded['data'] ?? <dynamic>[],
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Failed to load work orders: $error',
        'data': <Map<String, dynamic>>[],
      };
    }
  }

  Future<Map<String, dynamic>> getWorkOrderDetails({
    required int workOrderId,
  }) async {
    if (ApiConfig.useFakeApi) {
      return {
        'success': false,
        'message': 'Work order details are unavailable in fake API mode',
      };
    }

    try {
      final String? token = await userSessionService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication token is missing',
        };
      }

      final Uri uri = Uri.parse(
        '${ApiConfig.baseUrl}/work-orders/$workOrderId',
      );

      final http.Response response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Server returned an empty response',
          'statusCode': response.statusCode,
        };
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        return {
          'success': false,
          'message': 'Invalid server response',
        };
      }

      final Map<String, dynamic> result = Map<String, dynamic>.from(decoded);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to load work order details',
          'statusCode': response.statusCode,
        };
      }

      return result;
    } catch (error) {
      return {
        'success': false,
        'message': 'Failed to load work order details: $error',
      };
    }
  }

  Future<Map<String, dynamic>> _sendMultipartWorkOrderRequest({
    required String endpoint,
    required Map<String, dynamic> workOrder,
    required Map<String, String> extraFields,
  }) async {
    try {
      final List<dynamic> photos = workOrder['photos'] ?? [];
      final String? token = await userSessionService.getToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(endpoint),
      );

      request.headers['Accept'] = 'application/json';

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll(extraFields);

      request.fields['workOrderNumber'] =
          workOrder['workOrderNumber']?.toString() ?? '';
      request.fields['assetId'] = workOrder['assetId']?.toString() ?? '';
      request.fields['notes'] = workOrder['notes']?.toString() ?? '';
      request.fields['submittedAt'] =
          workOrder['submittedAt']?.toString() ?? '';
      request.fields['metadata'] = jsonEncode(workOrder);

      for (int i = 0; i < photos.length; i++) {
        final Map<String, dynamic> photo = Map<String, dynamic>.from(
          photos[i],
        );

        final String imagePath = photo['imagePath']?.toString() ?? '';

        if (imagePath.isEmpty) continue;

        final File file = File(imagePath);

        if (!await file.exists()) continue;

        request.files.add(
          await http.MultipartFile.fromPath(
            'photos',
            file.path,
            contentType: _getMediaType(file.path),
          ),
        );

        request.fields['photo_${i}_stage'] = photo['stage']?.toString() ?? '';
        request.fields['photo_${i}_time'] = photo['time']?.toString() ?? '';
        request.fields['photo_${i}_displayTime'] =
            photo['displayTime']?.toString() ?? '';
        request.fields['photo_${i}_latitude'] =
            photo['latitude']?.toString() ?? '';
        request.fields['photo_${i}_longitude'] =
            photo['longitude']?.toString() ?? '';
        request.fields['photo_${i}_imagePath'] =
            photo['imagePath']?.toString() ?? '';
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.body.isEmpty) {
        return {
          'success': response.statusCode >= 200 && response.statusCode < 300,
          'message': 'Request completed with empty response',
          'statusCode': response.statusCode,
        };
      }

      Map<String, dynamic> decoded = {};

      try {
        decoded = Map<String, dynamic>.from(jsonDecode(response.body));
      } catch (error) {
        return {
          'success': false,
          'message':
              'Server returned invalid response. Please check backend deployment and API route.',
          'statusCode': response.statusCode,
          'rawResponse': response.body.length > 300
              ? response.body.substring(0, 300)
              : response.body,
        };
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Request failed',
          'statusCode': response.statusCode,
        };
      }

      return decoded;
    } catch (error) {
      return {
        'success': false,
        'message': 'Request failed: $error',
      };
    }
  }
}

MediaType _getMediaType(String path) {
  final String lowerPath = path.toLowerCase();

  if (lowerPath.endsWith('.png')) {
    return MediaType('image', 'png');
  }

  if (lowerPath.endsWith('.webp')) {
    return MediaType('image', 'webp');
  }

  return MediaType('image', 'jpeg');
}
