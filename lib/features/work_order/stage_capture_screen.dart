import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/photo_capture_service.dart';
import 'image_preview_screen.dart';
import 'review_send_screen.dart';

class StageCaptureScreen extends StatefulWidget {
  final String workOrderNumber;
  final String assetId;
  final bool progressOnly;
  final bool editMode;
  final String? existingLocalOrderId;
  final String? existingServerWorkOrderId;
  final String? existingStatus;

  const StageCaptureScreen({
    super.key,
    required this.workOrderNumber,
    required this.assetId,
    required this.progressOnly,
    this.editMode = false,
    this.existingLocalOrderId,
    this.existingServerWorkOrderId,
    this.existingStatus,
  });

  @override
  State<StageCaptureScreen> createState() => _StageCaptureScreenState();
}

class _StageCaptureScreenState extends State<StageCaptureScreen> {
  final PhotoCaptureService photoCaptureService = PhotoCaptureService();

  final List<Map<String, String>> capturedPhotos = [];

  bool isCapturing = false;
  int selectedStageIndex = 0;

  List<String> get stages {
    return widget.progressOnly ? ['Progress'] : ['Before', 'During', 'After'];
  }

  String get selectedStage {
    return stages[selectedStageIndex];
  }

  Color get stageColor {
    switch (selectedStage) {
      case 'Before':
        return const Color(0xFF0D6EFD);
      case 'During':
        return const Color(0xFFFF8A00);
      case 'After':
        return const Color(0xFF009879);
      case 'Progress':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF0D6EFD);
    }
  }

  int get totalPhotos {
    return capturedPhotos.length;
  }

  Future<void> capturePhoto(String stage) async {
    if (isCapturing) return;

    setState(() {
      isCapturing = true;
    });

    try {
      final Map<String, String>? photoData =
          await photoCaptureService.captureAndSavePhoto(
        workOrderNumber: widget.workOrderNumber,
        assetId: widget.assetId,
        stage: stage,
      );

      if (photoData == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        capturedPhotos.add(photoData);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$stage photo added'),
          duration: const Duration(milliseconds: 700),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo capture failed: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCapturing = false;
        });
      }
    }
  }

  Future<void> deletePhotoFile(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;

    final file = File(imagePath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> removePhoto(int index) async {
    final photo = capturedPhotos[index];

    setState(() {
      capturedPhotos.removeAt(index);
    });

    await deletePhotoFile(photo['imagePath']);
  }

  Future<void> previewExistingPhoto(int index) async {
    final photo = capturedPhotos[index];

    final String? result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreviewScreen(
          photo: photo,
          title: '${photo['stage']} Photo',
          showDeleteButton: true,
        ),
      ),
    );

    if (!mounted) return;

    if (result == 'delete') {
      await removePhoto(index);
    }
  }

  void goToReview() {
    if (capturedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture at least one photo')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewSendScreen(
          workOrderNumber: widget.workOrderNumber,
          assetId: widget.assetId,
          photos: capturedPhotos,
          editMode: widget.editMode,
          existingLocalOrderId: widget.existingLocalOrderId,
          existingServerWorkOrderId: widget.existingServerWorkOrderId,
          existingStatus: widget.existingStatus,
        ),
      ),
    );
  }

  int countStage(String stage) {
    return capturedPhotos.where((photo) => photo['stage'] == stage).length;
  }

  void previousStage() {
    if (stages.length <= 1) return;

    setState(() {
      selectedStageIndex =
          selectedStageIndex == 0 ? stages.length - 1 : selectedStageIndex - 1;
    });
  }

  void nextStage() {
    if (stages.length <= 1) return;

    setState(() {
      selectedStageIndex =
          selectedStageIndex == stages.length - 1 ? 0 : selectedStageIndex + 1;
    });
  }

  String? latestPhotoPathForStage(String stage) {
    final photos = capturedPhotos
        .where((photo) => photo['stage'] == stage)
        .toList()
        .reversed
        .toList();

    if (photos.isEmpty) return null;

    return photos.first['imagePath'];
  }

  Widget buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(100),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.close, color: Colors.white, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            decoration: BoxDecoration(
              color: stageColor,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: stageColor.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              selectedStage.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Capture photos stage-wise, then tap Review & Send.',
                  ),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.white, size: 18),
                  SizedBox(width: 5),
                  Text(
                    'HELP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWorkOrderInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        children: [
          Text(
            'WO-\n${widget.workOrderNumber}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '$totalPhotos photos',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStageSelector() {
    final String? latestPath = latestPhotoPathForStage(selectedStage);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          IconButton(
            onPressed: stages.length <= 1 ? null : previousStage,
            icon: const Icon(Icons.chevron_left),
            color: Colors.white,
            iconSize: 34,
          ),
          Expanded(
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: stages.map((stage) {
                  final bool active = stage == selectedStage;
                  final int count = countStage(stage);
                  final Color color = active ? stageColor : Colors.white24;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedStageIndex = stages.indexOf(stage);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      height: active ? 58 : 46,
                      width: active ? 58 : 46,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withOpacity(0.16)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: color,
                          width: active ? 2 : 1,
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: stageColor.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              latestPath != null && active
                                  ? Icons.image_outlined
                                  : Icons.camera_alt_outlined,
                              color: active ? Colors.white : Colors.white38,
                              size: active ? 28 : 24,
                            ),
                          ),
                          if (count > 0)
                            Positioned(
                              right: 3,
                              top: 3,
                              child: Container(
                                height: 18,
                                width: 18,
                                decoration: BoxDecoration(
                                  color: active ? stageColor : Colors.white30,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    count.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          IconButton(
            onPressed: stages.length <= 1 ? null : nextStage,
            icon: const Icon(Icons.chevron_right),
            color: Colors.white,
            iconSize: 34,
          ),
        ],
      ),
    );
  }

  Widget buildInstructionBox() {
    String instruction;

    if (selectedStage == 'Before') {
      instruction = 'PLEASE, TRY TO\ncapture the site before starting the work';
    } else if (selectedStage == 'During') {
      instruction = 'PLEASE, TRY TO\ncapture the work progress clearly';
    } else if (selectedStage == 'After') {
      instruction = 'PLEASE, TRY TO\ncapture the final completed work clearly';
    } else {
      instruction = 'PLEASE, TRY TO\ncapture the latest progress clearly';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 42),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.74),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white10),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: instruction.split('\n').first,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            TextSpan(
              text: '\n${instruction.split('\n').last}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(stages.length, (index) {
        final bool active = index == selectedStageIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 7),
          height: 13,
          width: 13,
          decoration: BoxDecoration(
            color: active ? stageColor : Colors.white38,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget buildShutterButton() {
    return GestureDetector(
      onTap: isCapturing ? null : () => capturePhoto(selectedStage),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 82,
        width: 82,
        decoration: BoxDecoration(
          color: isCapturing ? Colors.white60 : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.20),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: isCapturing
            ? Padding(
                padding: const EdgeInsets.all(22),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: stageColor,
                ),
              )
            : Icon(
                Icons.camera_alt,
                color: Colors.grey.shade800,
                size: 34,
              ),
      ),
    );
  }

  Widget buildCapturedPhotosStrip() {
    if (capturedPhotos.isEmpty) {
      return const SizedBox(
        height: 74,
        child: Center(
          child: Text(
            'No photos captured yet',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 82,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: capturedPhotos.length,
        itemBuilder: (context, index) {
          final photo = capturedPhotos[index];
          final imagePath = photo['imagePath'] ?? '';
          final stage = photo['stage'] ?? '';

          Color photoStageColor = Colors.blue;
          if (stage == 'During') photoStageColor = const Color(0xFFFF8A00);
          if (stage == 'After') photoStageColor = const Color(0xFF009879);
          if (stage == 'Progress') photoStageColor = const Color(0xFF7C3AED);

          return GestureDetector(
            onTap: () => previewExistingPhoto(index),
            child: Container(
              width: 72,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: photoStageColor, width: 2),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(imagePath),
                      height: 78,
                      width: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 78,
                          width: 72,
                          color: Colors.white12,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        stage.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => removePhoto(index),
                      child: Container(
                        height: 22,
                        width: 22,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(9),
                            bottomLeft: Radius.circular(9),
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildReviewButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: capturedPhotos.isEmpty ? null : goToReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D6EFD),
            disabledBackgroundColor: Colors.white12,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            capturedPhotos.isEmpty
                ? 'Capture photos to continue'
                : 'Review & Send ($totalPhotos)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCameraArea() {
    return Expanded(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF050505),
              Color(0xFF111111),
              Color(0xFF050505),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const Spacer(flex: 1),
            buildStageSelector(),
            const Spacer(flex: 2),
            buildInstructionBox(),
            const SizedBox(height: 28),
            buildDots(),
            const Spacer(flex: 2),
            buildShutterButton(),
            const SizedBox(height: 22),
            buildCapturedPhotosStrip(),
            buildReviewButton(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            buildTopBar(),
            buildWorkOrderInfo(),
            buildCameraArea(),
          ],
        ),
      ),
    );
  }
}
