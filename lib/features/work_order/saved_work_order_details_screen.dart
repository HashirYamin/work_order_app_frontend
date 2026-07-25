import 'package:flutter/material.dart';

import '../../core/services/local_work_order_service.dart';
import 'image_preview_screen.dart';

class SavedWorkOrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> workOrder;

  const SavedWorkOrderDetailsScreen({
    super.key,
    required this.workOrder,
  });

  @override
  State<SavedWorkOrderDetailsScreen> createState() =>
      _SavedWorkOrderDetailsScreenState();
}

class _SavedWorkOrderDetailsScreenState
    extends State<SavedWorkOrderDetailsScreen> {
  final LocalWorkOrderService localWorkOrderService = LocalWorkOrderService();

  late Map<String, dynamic> order;

  @override
  void initState() {
    super.initState();
    order = Map<String, dynamic>.from(widget.workOrder);
  }

  List<Map<String, String>> getPhotos() {
    final dynamic rawPhotos = order['photos'];

    if (rawPhotos is! List) {
      return [];
    }

    return rawPhotos.map((photo) {
      return Map<String, String>.from(photo);
    }).toList();
  }

  
  Future<void> fakeMarkUploaded() async {
    final String id = order['id'] ?? '';

    if (id.isEmpty) return;

    await localWorkOrderService.markAsUploaded(id);

    setState(() {
      order['status'] = 'Uploaded';
      order['isSynced'] = true;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked as uploaded locally for testing'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> photos = getPhotos();

    final String workOrderNumber = order['workOrderNumber'] ?? '';
    final String assetId = order['assetId'] ?? '';
    final String status = order['status'] ?? 'Pending Upload';
    final String submittedAt = order['submittedAt'] ?? '';
    final String notes = order['notes'] ?? '';

    final bool isUploaded = status == 'Uploaded';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Order Details'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workOrderNumber,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text('Asset ID: $assetId'),

                  const SizedBox(height: 8),

                  Text('Submitted At: $submittedAt'),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        isUploaded ? Icons.cloud_done : Icons.cloud_upload,
                        color: isUploaded ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status,
                        style: TextStyle(
                          color: isUploaded ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Notes: $notes'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Saved Photos (${photos.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            GridView.builder(
              itemCount: photos.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final Map<String, String> photo = photos[index];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImagePreviewScreen(
                          photo: photo,
                          title: '${photo['stage']} Photo Preview',
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.image,
                          size: 42,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          photo['stage'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          photo['displayTime'] ?? '',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap to preview',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: fakeMarkUploaded,
              icon: const Icon(Icons.cloud_done),
              label: const Text('Mark Uploaded For Testing'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),

            const SizedBox(height: 12),

            
          ],
        ),
      ),
    );
  }
}