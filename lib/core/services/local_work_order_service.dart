import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'user_session_service.dart';

class LocalWorkOrderService {
  final UserSessionService userSessionService = UserSessionService();

  static const String _guestKey = 'local_work_orders_guest';

  Future<String> _getStorageKey() async {
    final Map<String, dynamic>? user = await userSessionService.getUser();

    if (user == null) {
      return _guestKey;
    }

    final String userId = user['id']?.toString() ?? '';
    final String phone = user['phone']?.toString() ?? '';

    final String identifier = userId.isNotEmpty ? userId : phone;

    if (identifier.isEmpty) {
      return _guestKey;
    }

    final String safeIdentifier = identifier.replaceAll(
      RegExp(r'[^a-zA-Z0-9]'),
      '_',
    );

    return 'local_work_orders_$safeIdentifier';
  }

  Future<List<Map<String, dynamic>>> getWorkOrders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String storageKey = await _getStorageKey();

    final List<String> savedOrders = prefs.getStringList(storageKey) ?? [];

    return savedOrders.map((orderJson) {
      return Map<String, dynamic>.from(jsonDecode(orderJson));
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getPendingWorkOrders() async {
    final List<Map<String, dynamic>> orders = await getWorkOrders();

    return orders.where((order) {
      final String status = order['status']?.toString() ?? 'Pending Upload';
      return status != 'Uploaded';
    }).toList();
  }

  Future<void> saveWorkOrder(Map<String, dynamic> workOrder) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String storageKey = await _getStorageKey();

    final Map<String, dynamic>? user = await userSessionService.getUser();

    final Map<String, dynamic> updatedOrder = Map<String, dynamic>.from(
      workOrder,
    );

    if (user != null) {
      updatedOrder['technicianId'] = user['id']?.toString() ?? '';
      updatedOrder['technicianName'] = user['name']?.toString() ?? '';
      updatedOrder['technicianPhone'] = user['phone']?.toString() ?? '';
    }

    final List<Map<String, dynamic>> orders = await getWorkOrders();

    final int existingIndex = orders.indexWhere(
      (order) => order['id'] == updatedOrder['id'],
    );

    if (existingIndex >= 0) {
      orders[existingIndex] = updatedOrder;
    } else {
      orders.insert(0, updatedOrder);
    }

    final List<String> encodedOrders = orders.map((order) {
      return jsonEncode(order);
    }).toList();

    await prefs.setStringList(storageKey, encodedOrders);
  }

  Future<void> deleteWorkOrder(String id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String storageKey = await _getStorageKey();

    final List<Map<String, dynamic>> orders = await getWorkOrders();

    orders.removeWhere((order) => order['id'] == id);

    final List<String> encodedOrders = orders.map((order) {
      return jsonEncode(order);
    }).toList();

    await prefs.setStringList(storageKey, encodedOrders);
  }

  Future<void> updateWorkOrderStatus({
    required String id,
    required String status,
    required bool isSynced,
    String errorMessage = '',
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String storageKey = await _getStorageKey();

    final List<Map<String, dynamic>> orders = await getWorkOrders();

    final int index = orders.indexWhere((order) => order['id'] == id);

    if (index == -1) {
      return;
    }

    orders[index]['status'] = status;
    orders[index]['isSynced'] = isSynced;
    orders[index]['errorMessage'] = errorMessage;
    orders[index]['lastSyncAttemptAt'] = DateTime.now().toIso8601String();

    final List<String> encodedOrders = orders.map((order) {
      return jsonEncode(order);
    }).toList();

    await prefs.setStringList(storageKey, encodedOrders);
  }

  Future<void> markAsUploaded(String id) async {
    await updateWorkOrderStatus(
      id: id,
      status: 'Uploaded',
      isSynced: true,
    );
  }

  Future<void> markAsUploading(String id) async {
    await updateWorkOrderStatus(
      id: id,
      status: 'Uploading',
      isSynced: false,
    );
  }

  Future<void> markAsFailed(String id, String message) async {
    await updateWorkOrderStatus(
      id: id,
      status: 'Upload Failed',
      isSynced: false,
      errorMessage: message,
    );
  }

  Future<void> addPhotosToExistingWorkOrder({
    required String id,
    required List<Map<String, String>> newPhotos,
    String status = 'Uploaded',
    bool isSynced = true,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String storageKey = await _getStorageKey();

    final List<Map<String, dynamic>> orders = await getWorkOrders();

    final int index = orders.indexWhere((order) => order['id'] == id);

    if (index == -1) {
      return;
    }

    final List<dynamic> existingPhotos = orders[index]['photos'] ?? [];

    orders[index]['photos'] = [
      ...existingPhotos,
      ...newPhotos,
    ];

    orders[index]['status'] = status;
    orders[index]['isSynced'] = isSynced;
    orders[index]['lastEditedAt'] = DateTime.now().toIso8601String();

    final List<String> encodedOrders = orders.map((order) {
      return jsonEncode(order);
    }).toList();

    await prefs.setStringList(storageKey, encodedOrders);
  }

  int getPhotoCount(Map<String, dynamic> order) {
    final List<dynamic> photos = order['photos'] ?? [];
    return photos.length;
  }
}
