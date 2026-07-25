import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tag_settings.dart';
import '../models/work_order_model.dart';

class LocalStorageService {
  static const String _workOrdersKey = 'work_orders';
  static const String _tagSettingsKey = 'tag_settings';

  Future<List<WorkOrderModel>> getWorkOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_workOrdersKey);

    if (rawData == null || rawData.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawData);
    if (decoded is! List) return [];

    return decoded
        .map((item) => WorkOrderModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> saveWorkOrder(WorkOrderModel order) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getWorkOrders();
    final existingIndex = orders.indexWhere((item) => item.id == order.id);

    if (existingIndex >= 0) {
      orders[existingIndex] = order;
    } else {
      orders.add(order);
    }

    final encoded = jsonEncode(orders.map((item) => item.toJson()).toList());
    await prefs.setString(_workOrdersKey, encoded);
  }

  Future<TagSettings> getTagSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_tagSettingsKey);

    if (rawData == null || rawData.isEmpty) {
      return const TagSettings(position: 'bottomRight', size: 'medium');
    }

    return TagSettings.fromJson(Map<String, dynamic>.from(jsonDecode(rawData)));
  }

  Future<void> saveTagSettings(TagSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tagSettingsKey, jsonEncode(settings.toJson()));
  }
}
