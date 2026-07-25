import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../core/services/local_work_order_service.dart';
import '../../core/services/sync_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../settings/screens/settings_screen.dart';

import 'saved_work_order_details_screen.dart';
import 'stage_capture_screen.dart';
import 'upload_queue_screen.dart';

class WorkOrderScreen extends StatefulWidget {
  const WorkOrderScreen({super.key});

  @override
  State<WorkOrderScreen> createState() => _WorkOrderScreenState();
}

class _WorkOrderScreenState extends State<WorkOrderScreen> {
  final workOrderController = TextEditingController();
  final assetIdController = TextEditingController();

  final LocalWorkOrderService localWorkOrderService = LocalWorkOrderService();
  final SyncService syncService = SyncService();

  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;

  bool progressOnly = false;
  bool loadingOrders = true;
  bool autoSyncing = false;

  String autoSyncMessage = '';

  List<Map<String, dynamic>> recentWorkOrders = [];

  @override
  void initState() {
    super.initState();
    loadRecentWorkOrders();
    runAutoSync();

    connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final bool hasInternet = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (hasInternet) {
        runAutoSync();
      }
    });
  }

  @override
  void dispose() {
    connectivitySubscription?.cancel();
    workOrderController.dispose();
    assetIdController.dispose();
    super.dispose();
  }

  Future<void> loadRecentWorkOrders() async {
    final List<Map<String, dynamic>> orders =
        await localWorkOrderService.getWorkOrders();

    orders.sort((a, b) {
      final String aDate = a['submittedAt'] ?? '';
      final String bDate = b['submittedAt'] ?? '';
      return bDate.compareTo(aDate);
    });

    if (!mounted) return;

    setState(() {
      recentWorkOrders = orders;
      loadingOrders = false;
    });
  }

  Future<void> runAutoSync() async {
    if (autoSyncing) return;

    final List<Map<String, dynamic>> pendingOrders =
        await localWorkOrderService.getPendingWorkOrders();

    if (pendingOrders.isEmpty) {
      return;
    }

    if (!mounted) return;

    setState(() {
      autoSyncing = true;
      autoSyncMessage =
          'Auto sync running for ${pendingOrders.length} pending work order(s)...';
    });

    final int uploadedCount = await syncService.syncAllPendingWorkOrders();

    await loadRecentWorkOrders();

    if (!mounted) return;

    setState(() {
      autoSyncing = false;
      autoSyncMessage = uploadedCount > 0
          ? 'Auto sync completed: $uploadedCount work order(s) uploaded.'
          : 'Auto sync checked pending uploads.';
    });

    if (uploadedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$uploadedCount work order(s) auto synced'),
        ),
      );
    }
  }

  void continueToStages() {
    final String workOrder = workOrderController.text.trim();
    final String assetId = assetIdController.text.trim();

    if (workOrder.isEmpty || assetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Work Order Number and Asset ID are required'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StageCaptureScreen(
          workOrderNumber: workOrder,
          assetId: assetId,
          progressOnly: progressOnly,
        ),
      ),
    ).then((_) {
      loadRecentWorkOrders();
      runAutoSync();
    });
  }

  void continueWithoutWorkOrder() {
    workOrderController.text = 'NO-WO-${DateTime.now().millisecondsSinceEpoch}';
    assetIdController.text = 'N/A';
    continueToStages();
  }

  void openSavedOrder(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedWorkOrderDetailsScreen(
          workOrder: order,
        ),
      ),
    ).then((_) {
      loadRecentWorkOrders();
      runAutoSync();
    });
  }
  void editSavedOrder(Map<String, dynamic> order) {
  final String workOrderNo = order['workOrderNumber']?.toString() ?? '';
  final String assetId = order['assetId']?.toString() ?? '';
  final String localOrderId = order['id']?.toString() ?? '';
  final String status = order['status']?.toString() ?? 'Pending Upload';

  final String serverWorkOrderId =
      order['serverWorkOrderId']?.toString() ??
      order['server_work_order_id']?.toString() ??
      order['serverId']?.toString() ??
      '';

  if (workOrderNo.isEmpty || assetId.isEmpty || localOrderId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cannot edit this work order. Required data is missing.'),
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => StageCaptureScreen(
        workOrderNumber: workOrderNo,
        assetId: assetId,
        progressOnly: false,
        editMode: true,
        existingLocalOrderId: localOrderId,
        existingServerWorkOrderId: serverWorkOrderId,
        existingStatus: status,
      ),
    ),
  ).then((_) {
    loadRecentWorkOrders();
    runAutoSync();
  });
}

  Color getStatusColor(String status) {
    if (status == 'Uploaded') return Colors.green;
    if (status == 'Uploading') return Colors.blue;
    if (status == 'Upload Failed') return Colors.red;

    return Colors.orange;
  }

  IconData getStatusIcon(String status) {
    if (status == 'Uploaded') return Icons.cloud_done;
    if (status == 'Uploading') return Icons.sync;
    if (status == 'Upload Failed') return Icons.error;

    return Icons.cloud_upload;
  }

  @override
  Widget build(BuildContext context) {
    final int pendingCount = recentWorkOrders
        .where((order) => order['status'] != 'Uploaded')
        .length;

    final int uploadedCount = recentWorkOrders
        .where((order) => order['status'] == 'Uploaded')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Order'),
        actions: [
          IconButton(
            tooltip: 'Upload Queue',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UploadQueueScreen(),
                ),
              ).then((_) {
                loadRecentWorkOrders();
                runAutoSync();
              });
            },
            icon: const Icon(Icons.cloud_sync),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushNamed(context, SettingsScreen.routeName);
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await loadRecentWorkOrders();
            await runAutoSync();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Container(
                  height: 76,
                  width: 76,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.work_outline,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Enter WO number or continue',
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                AppTextField(
                  label: 'Work Order Number',
                  controller: workOrderController,
                  prefixIcon: Icons.assignment,
                ),

                const SizedBox(height: 12),

                AppTextField(
                  label: 'Asset ID',
                  controller: assetIdController,
                  prefixIcon: Icons.confirmation_number,
                ),

                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Progress photos only'),
                  subtitle: const Text(
                    'Use when Before / During / After stages are not required',
                  ),
                  value: progressOnly,
                  onChanged: (value) {
                    setState(() {
                      progressOnly = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                AppButton(
                  title: 'Continue',
                  onTap: continueToStages,
                ),

                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: continueWithoutWorkOrder,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: const Text('Continue Without Work Order'),
                ),

                if (autoSyncMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: autoSyncing
                          ? Colors.blue.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: autoSyncing
                            ? Colors.blue.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (autoSyncing)
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            autoSyncMessage,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: _DashboardCard(
                        title: 'Pending',
                        value: '$pendingCount',
                        icon: Icons.cloud_upload,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DashboardCard(
                        title: 'Uploaded',
                        value: '$uploadedCount',
                        icon: Icons.cloud_done,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'My Recent Work Orders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),

                const SizedBox(height: 12),

                if (loadingOrders)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  )
                else if (recentWorkOrders.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Text(
                      'No local work orders yet. Submitted work orders will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ListView.separated(
                    itemCount: recentWorkOrders.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final Map<String, dynamic> order =
                          recentWorkOrders[index];

                      final String workOrderNo =
                          order['workOrderNumber'] ?? 'Unknown WO';
                      final String assetId = order['assetId'] ?? 'N/A';
                      final String status =
                          order['status'] ?? 'Pending Upload';

                      final int photoCount =
                          localWorkOrderService.getPhotoCount(order);

                      return InkWell(
                        onTap: () => openSavedOrder(order),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                getStatusIcon(status),
                                color: getStatusColor(status),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      workOrderNo,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Asset: $assetId • $photoCount photos',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: getStatusColor(status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Column(
  children: [
    IconButton(
      tooltip: 'Open',
      onPressed: () => openSavedOrder(order),
      icon: const Icon(Icons.chevron_right),
    ),
    TextButton.icon(
      onPressed: () => editSavedOrder(order),
      icon: const Icon(Icons.add_a_photo, size: 16),
      label: const Text(
        'Edit',
        style: TextStyle(fontSize: 12),
      ),
    ),
  ],
),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}