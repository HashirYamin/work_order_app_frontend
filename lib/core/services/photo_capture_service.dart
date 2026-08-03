import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'location_service.dart';
import 'tag_preferences_service.dart';

class PhotoCaptureService {
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();
  final TagPreferencesService _tagPreferencesService = TagPreferencesService();

  static const int captureMaxWidth = 1280;
  static const int captureMaxHeight = 1280;
  static const int pickerImageQuality = 65;
  static const int finalJpegQuality = 72;

  Future<Map<String, String>?> captureAndSavePhoto({
    required String workOrderNumber,
    required String assetId,
    required String stage,
  }) async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      maxWidth: captureMaxWidth.toDouble(),
      maxHeight: captureMaxHeight.toDouble(),
      imageQuality: pickerImageQuality,
      requestFullMetadata: false,
    );

    if (pickedImage == null) {
      return null;
    }

    final DateTime now = DateTime.now();

    final List<dynamic> results = await Future.wait<dynamic>([
      _getLocationFast(),
      _tagPreferencesService.getTagPosition(),
      _tagPreferencesService.getTagSize(),
    ]);

    final Position? position = results[0] as Position?;
    final String tagPosition = results[1] as String;
    final String tagSize = results[2] as String;

    final List<String> tagLines = _buildTagLines(
      workOrderNumber: workOrderNumber,
      assetId: assetId,
      stage: stage,
      now: now,
      position: position,
    );

    final File originalFile = File(pickedImage.path);
    final Uint8List originalBytes = await originalFile.readAsBytes();

    final Uint8List taggedPngBytes = await _writeTagOnImageUsingCanvas(
      imageBytes: originalBytes,
      tagLines: tagLines,
      tagPosition: tagPosition,
      tagSize: tagSize,
    );

    final Uint8List finalImageBytes = await _compressToJpg(taggedPngBytes);

    final Directory appDirectory = await getApplicationDocumentsDirectory();

    final String safeWorkOrder = _safeFileName(workOrderNumber);
    final String safeAssetId = _safeFileName(assetId);
    final String safeStage = _safeFileName(stage);

    final String fileName =
        '${safeWorkOrder}_${safeAssetId}_${safeStage}_${now.millisecondsSinceEpoch}.jpg';

    final String savedPath = '${appDirectory.path}/$fileName';

    final File savedFile = File(savedPath);
    await savedFile.writeAsBytes(finalImageBytes);

    try {
      if (await originalFile.exists()) {
        await originalFile.delete();
      }
    } catch (_) {}

    return {
      'stage': stage,
      'time': now.toIso8601String(),
      'displayTime': DateFormat('dd MMM yyyy hh:mm:ss a').format(now),
      'imagePath': savedFile.path,
      'latitude': position?.latitude.toString() ?? '',
      'longitude': position?.longitude.toString() ?? '',
    };
  }

  Future<Position?> _getLocationFast() async {
    try {
      return await _locationService
          .getCurrentLocation()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _compressToJpg(Uint8List imageBytes) async {
    try {
      final Uint8List compressedBytes =
          await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: captureMaxWidth,
        minHeight: captureMaxHeight,
        quality: finalJpegQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      if (compressedBytes.isNotEmpty) {
        return compressedBytes;
      }

      return imageBytes;
    } catch (_) {
      return imageBytes;
    }
  }

  Future<Uint8List> _writeTagOnImageUsingCanvas({
    required Uint8List imageBytes,
    required List<String> tagLines,
    required String tagPosition,
    required String tagSize,
  }) async {
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image originalImage = frameInfo.image;

    final double imageWidth = originalImage.width.toDouble();
    final double imageHeight = originalImage.height.toDouble();

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    canvas.drawImage(originalImage, Offset.zero, Paint());

    final double fontSize = _getFontSize(imageWidth, tagSize);
    final double padding = fontSize * 0.65;
    final double radius = fontSize * 0.35;

    final String tagText = tagLines.join('\n');

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: tagText,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: tagLines.length,
    );

    textPainter.layout(
      maxWidth: imageWidth * 0.78,
    );

    final double boxWidth = textPainter.width + (padding * 2);
    final double boxHeight = textPainter.height + (padding * 2);

    final Offset boxOffset = _getBoxOffset(
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      padding: padding,
      tagPosition: tagPosition,
    );

    final Rect backgroundRect = Rect.fromLTWH(
      boxOffset.dx,
      boxOffset.dy,
      boxWidth,
      boxHeight,
    );

    final RRect roundedRect = RRect.fromRectAndRadius(
      backgroundRect,
      Radius.circular(radius),
    );

    final Paint backgroundPaint = Paint()
      ..color = const Color.fromARGB(185, 0, 0, 0);

    canvas.drawRRect(roundedRect, backgroundPaint);

    textPainter.paint(
      canvas,
      Offset(
        boxOffset.dx + padding,
        boxOffset.dy + padding,
      ),
    );

    final ui.Picture picture = recorder.endRecording();

    final ui.Image finalImage = await picture.toImage(
      originalImage.width,
      originalImage.height,
    );

    final ByteData? byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception('Failed to convert tagged image');
    }

    originalImage.dispose();
    finalImage.dispose();
    picture.dispose();
    codec.dispose();

    return byteData.buffer.asUint8List();
  }

  Offset _getBoxOffset({
    required double imageWidth,
    required double imageHeight,
    required double boxWidth,
    required double boxHeight,
    required double padding,
    required String tagPosition,
  }) {
    switch (tagPosition) {
      case 'Top Left':
        return Offset(padding, padding);

      case 'Top Right':
        return Offset(
          imageWidth - boxWidth - padding,
          padding,
        );

      case 'Bottom Left':
        return Offset(
          padding,
          imageHeight - boxHeight - padding,
        );

      case 'Bottom Right':
      default:
        return Offset(
          imageWidth - boxWidth - padding,
          imageHeight - boxHeight - padding,
        );
    }
  }

  double _getFontSize(double imageWidth, String tagSize) {
    if (tagSize == 'Small') {
      return imageWidth * 0.026;
    }

    if (tagSize == 'Large') {
      return imageWidth * 0.044;
    }

    return imageWidth * 0.035;
  }

  List<String> _buildTagLines({
    required String workOrderNumber,
    required String assetId,
    required String stage,
    required DateTime now,
    required Position? position,
  }) {
    final String dateText = DateFormat('dd MMM yyyy hh:mm:ss a').format(now);

    final String gpsText = position == null
        ? 'GPS unavailable'
        : '${_formatLatitude(position.latitude)} ${_formatLongitude(position.longitude)}';

    return [
      dateText,
      gpsText,
      'WO: $workOrderNumber',
      'Asset: $assetId',
      '#$stage',
    ];
  }

  String _formatLatitude(double value) {
    final String direction = value >= 0 ? 'N' : 'S';
    return '${value.abs().toStringAsFixed(6)}$direction';
  }

  String _formatLongitude(double value) {
    final String direction = value >= 0 ? 'E' : 'W';
    return '${value.abs().toStringAsFixed(6)}$direction';
  }

  String _safeFileName(String value) {
    return value
        .trim()
        .replaceAll(' ', '_')
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll(':', '_');
  }
}
