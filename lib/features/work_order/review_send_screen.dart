import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/local_work_order_service.dart';
import '../../core/services/work_order_api_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import 'image_preview_screen.dart';
import 'success_screen.dart';
import 'package:share_plus/share_plus.dart';

class ReviewSendScreen extends StatefulWidget {
  final String workOrderNumber;
  final String assetId;
  final List<Map<String, String>> photos;

  final bool editMode;
  final String? existingLocalOrderId;
  final String? existingServerWorkOrderId;
  final String? existingStatus;

  const ReviewSendScreen({
    super.key,
    required this.workOrderNumber,
    required this.assetId,
    required this.photos,
    this.editMode = false,
    this.existingLocalOrderId,
    this.existingServerWorkOrderId,
    this.existingStatus,
  });

  @override
  State<ReviewSendScreen> createState() => _ReviewSendScreenState();
}

class _ReviewSendScreenState extends State<ReviewSendScreen> {
  final notesController = TextEditingController();
  final LocalWorkOrderService localWorkOrderService = LocalWorkOrderService();
  final WorkOrderApiService workOrderApiService = WorkOrderApiService();

  bool submitting = false;
String buildWhatsAppMessage() {
  final String remarks = notesController.text.trim().isEmpty
      ? '-'
      : notesController.text.trim();

  return '''
*Work Order Report*

Asset ID: ${widget.assetId}
Work Order Number: ${widget.workOrderNumber}
Remarks: $remarks
''';
}

Future<void> shareWorkOrderToWhatsApp() async {
  try {
    final String message = buildWhatsAppMessage();

    final List<XFile> files = widget.photos
        .map((photo) => photo['imagePath'] ?? '')
        .where((path) => path.isNotEmpty && File(path).existsSync())
        .map((path) => XFile(path))
        .toList();

    if (files.isEmpty) {
      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: 'Work Order ${widget.workOrderNumber}',
        ),
      );
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: files,
        text: message,
        subject: 'Work Order ${widget.workOrderNumber}',
      ),
    );
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to share work order: $error'),
      ),
    );
  }
}
  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      submitting = true;
    });

    try {
      if (widget.editMode) {
        await submitEditPhotos();
      } else {
        await submitNewWorkOrder();
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        submitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> submitNewWorkOrder() async {
    final String now = DateTime.now().toIso8601String();

    final Map<String, dynamic> workOrder = {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'workOrderNumber': widget.workOrderNumber,
      'assetId': widget.assetId,
      'notes': notesController.text.trim(),
      'status': 'Pending Upload',
      'isSynced': false,
      'createdAt': now,
      'submittedAt': now,
      'photos': widget.photos,
    };

    await localWorkOrderService.saveWorkOrder(workOrder);

    if (!mounted) return;

    setState(() {
      submitting = false;
    });

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => SuccessScreen(
          workOrderNumber: widget.workOrderNumber,
          photoCount: widget.photos.length,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> submitEditPhotos() async {
    final String now = DateTime.now().toIso8601String();
    final String localOrderId = widget.existingLocalOrderId ?? '';

    if (localOrderId.isEmpty) {
      throw Exception('Local work order ID is missing');
    }

    final bool isAlreadyUploaded = widget.existingStatus == 'Uploaded';

    final Map<String, dynamic> editWorkOrder = {
      'id': localOrderId,
      'serverWorkOrderId': widget.existingServerWorkOrderId ?? '',
      'workOrderNumber': widget.workOrderNumber,
      'assetId': widget.assetId,
      'notes': notesController.text.trim(),
      'status': isAlreadyUploaded ? 'Uploaded' : 'Pending Upload',
      'isSynced': isAlreadyUploaded,
      'submittedAt': now,
      'photos': widget.photos,
    };

    if (isAlreadyUploaded) {
      final Map<String, dynamic> response =
          await workOrderApiService.addPhotosToExistingWorkOrder(
        workOrder: editWorkOrder,
      );

      final bool success = response['success'] == true;

      if (!success) {
        throw Exception(response['message'] ?? 'Failed to add photos');
      }

      await localWorkOrderService.addPhotosToExistingWorkOrder(
        id: localOrderId,
        newPhotos: widget.photos,
        status: 'Uploaded',
        isSynced: true,
      );
    } else {
      await localWorkOrderService.addPhotosToExistingWorkOrder(
        id: localOrderId,
        newPhotos: widget.photos,
        status: 'Pending Upload',
        isSynced: false,
      );
    }

    if (!mounted) return;

    setState(() {
      submitting = false;
    });

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => SuccessScreen(
          workOrderNumber: widget.workOrderNumber,
          photoCount: widget.photos.length,
        ),
      ),
      (route) => false,
    );
  }

  int countStage(String stage) {
    return widget.photos.where((photo) => photo['stage'] == stage).length;
  }

  @override
  Widget build(BuildContext context) {
    final stages = widget.photos
        .map((photo) => photo['stage'] ?? '')
        .where((stage) => stage.isNotEmpty)
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editMode ? 'Review Added Photos' : 'Review & Send'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.editMode)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Text(
                    'You are adding new photos to an existing work order. Existing photos will not be removed.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: stages.map((stage) {
                  return Container(
                    width: 105,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${countStage(stage)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(stage),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              Text(
                'Work Order: ${widget.workOrderNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text('Asset ID: ${widget.assetId}'),

              const SizedBox(height: 18),

              AppTextField(
                label: 'Notes Optional',
                controller: notesController,
                maxLines: 3,
                prefixIcon: Icons.note,
              ),

              const SizedBox(height: 20),

              Text(
                widget.editMode
                    ? 'New Photos to Add'
                    : 'Captured Photos with Metadata Tag',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              GridView.builder(
                itemCount: widget.photos.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final photo = widget.photos[index];
                  final imagePath = photo['imagePath'] ?? '';
                  final latitude = photo['latitude'] ?? '';
                  final longitude = photo['longitude'] ?? '';

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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14),
                              ),
                              child: Image.file(
                                File(imagePath),
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Text(
                                  photo['stage'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  photo['displayTime'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  latitude.isEmpty || longitude.isEmpty
                                      ? 'GPS unavailable'
                                      : 'GPS saved',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: latitude.isEmpty || longitude.isEmpty
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tap to preview',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

OutlinedButton.icon(
  onPressed: submitting ? null : shareWorkOrderToWhatsApp,
  icon: const Icon(Icons.share),
  label: const Text('Send to WhatsApp Chat / Group'),
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.green,
    side: const BorderSide(color: Colors.green),
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
),

const SizedBox(height: 12),

AppButton(
  title: widget.editMode
      ? 'Add Photos to Work Order'
      : 'Save Locally / Submit for Upload',
  loading: submitting,
  onTap: submit,
),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  widget.editMode
                      ? 'After adding photos, the PPT should be generated again from the admin panel.'
                      : 'This saves locally as Pending Upload and syncs automatically when internet is available.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}