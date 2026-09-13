import 'package:connectivity_plus/connectivity_plus.dart';

import 'api_config.dart';
import 'local_work_order_service.dart';
import 'work_order_api_service.dart';

class SyncService {
  final LocalWorkOrderService localWorkOrderService = LocalWorkOrderService();
  final WorkOrderApiService workOrderApiService = WorkOrderApiService();

  // Flag to prevent double-call sync execution
  bool _isSyncing = false;

  Future<bool> hasInternetConnection() async {
    if (ApiConfig.useFakeApi) {
      return true;
    }

    final List<ConnectivityResult> results =
        await Connectivity().checkConnectivity();

    return results.any(
      (result) => result != ConnectivityResult.none,
    );
  }

  Future<bool> syncSingleWorkOrder(Map<String, dynamic> order) async {
    final String id = order['id'] ?? '';

    if (id.isEmpty) {
      return false;
    }

    try {
      final bool hasInternet = await hasInternetConnection();

      if (!hasInternet) {
        await localWorkOrderService.markAsFailed(
          id,
          'No internet connection',
        );
        return false;
      }

      await localWorkOrderService.markAsUploading(id);

      final Map<String, dynamic> response =
          await workOrderApiService.uploadWorkOrder(
        workOrder: order,
      );

      final bool success = response['success'] == true;

      if (success) {
        await localWorkOrderService.markAsUploaded(id);
        return true;
      }

      await localWorkOrderService.markAsFailed(
        id,
        response['message']?.toString() ?? 'Upload failed',
      );

      return false;
    } catch (error) {
      await localWorkOrderService.markAsFailed(
        id,
        error.toString(),
      );

      return false;
    }
  }

  Future<int> syncAllPendingWorkOrders() async {
    // Guard against duplicate concurrent calls
    if (_isSyncing) {
      print('Sync already running. Skipping duplicate sync call.');
      return 0;
    }

    _isSyncing = true;

    try {
      final List<Map<String, dynamic>> pendingOrders =
          await localWorkOrderService.getPendingWorkOrders();

      int uploadedCount = 0;

      for (final Map<String, dynamic> order in pendingOrders) {
        final bool success = await syncSingleWorkOrder(order);

        if (success) {
          uploadedCount++;
        }
      }

      return uploadedCount;
    } finally {
      // Always reset the lock flag when sync completion finishes or errors out
      _isSyncing = false;
    }
  }
}
