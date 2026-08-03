import 'package:flutter/material.dart';

import '../../core/services/local_work_order_service.dart';
import 'saved_work_order_details_screen.dart';
import '../../core/services/sync_service.dart';

class UploadQueueScreen extends StatefulWidget {
  const UploadQueueScreen({super.key});

  @override
  State<UploadQueueScreen> createState() => _UploadQueueScreenState();
}

class _UploadQueueScreenState extends State<UploadQueueScreen> {
  final LocalWorkOrderService localWorkOrderService = LocalWorkOrderService();
  final SyncService syncService = SyncService();

  bool loading = true;
  bool syncingAll = false;

  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    loadQueue();
  }

  Future<void> loadQueue() async {
    final List<Map<String, dynamic>> localOrders =
        await localWorkOrderService.getWorkOrders();

    localOrders.sort((a, b) {
      final String aDate = a['submittedAt'] ?? '';
      final String bDate = b['submittedAt'] ?? '';
      return bDate.compareTo(aDate);
    });

    if (!mounted) return;

    setState(() {
      orders = localOrders;
      loading = false;
    });
  }

  Future<void> syncSingleOrder(Map<String, dynamic> order) async {
    final bool success = await syncService.syncSingleWorkOrder(order);

    await loadQueue();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${order['workOrderNumber']} uploaded successfully'
              : '${order['workOrderNumber']} upload failed',
        ),
      ),
    );
  }

  Future<void> syncAllPending() async {
    setState(() {
      syncingAll = true;
    });

    final int uploadedCount = await syncService.syncAllPendingWorkOrders();

    await loadQueue();

    if (!mounted) return;

    setState(() {
      syncingAll = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$uploadedCount pending work orders uploaded'),
      ),
    );
  }

  int get pendingCount {
    return orders.where((order) => order['status'] != 'Uploaded').length;
  }

  int get uploadedCount {
    return orders.where((order) => order['status'] == 'Uploaded').length;
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

  void openDetails(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedWorkOrderDetailsScreen(
          workOrder: order,
        ),
      ),
    ).then((_) => loadQueue());
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> pendingOrders =
        orders.where((order) => order['status'] != 'Uploaded').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Queue'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadQueue,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _QueueStatCard(
                      title: 'Pending',
                      value: '$pendingCount',
                      icon: Icons.cloud_upload,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QueueStatCard(
                      title: 'Uploaded',
                      value: '$uploadedCount',
                      icon: Icons.cloud_done,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'This screen prepares the offline upload queue. For now, Sync marks orders as uploaded locally. Later it will upload photos and metadata to the Node.js backend.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed:
                    pendingOrders.isEmpty || syncingAll ? null : syncAllPending,
                icon: syncingAll
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(
                  syncingAll ? 'Syncing...' : 'Sync All Pending',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Pending Uploads',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (pendingOrders.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Text(
                    'No pending uploads. All local work orders are uploaded.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ListView.separated(
                  itemCount: pendingOrders.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final Map<String, dynamic> order = pendingOrders[index];

                    final String status = order['status'] ?? 'Pending Upload';

                    final String workOrderNo =
                        order['workOrderNumber'] ?? 'Unknown WO';

                    final String assetId = order['assetId'] ?? 'N/A';

                    final int photoCount =
                        localWorkOrderService.getPhotoCount(order);

                    return Container(
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
                            child: InkWell(
                              onTap: () => openDetails(order),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workOrderNo,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
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
                                      color: getStatusColor(status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: status == 'Uploading'
                                ? null
                                : () => syncSingleOrder(order),
                            child: const Text('Sync'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _QueueStatCard({
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
