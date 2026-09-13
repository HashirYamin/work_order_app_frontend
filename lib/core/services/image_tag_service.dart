import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageTagService {
  Future<String> createTaggedImage({
    required String originalImagePath,
    required List<String> tagLines,
    required String tagPosition,
    required String tagSize,
    required String filePrefix,
  }) async {
    final inputBytes = await File(originalImagePath).readAsBytes();
    final decodedImage = img.decodeImage(inputBytes);

    if (decodedImage == null) {
      throw Exception('Could not read captured image');
    }

    final font = _fontBySize(tagSize);
    final fontHeight = _fontHeight(tagSize);
    final padding = _paddingBySize(tagSize);
    final gap = math.max(3, padding ~/ 2);
    final longestLineLength = tagLines.fold<int>(0, (previous, line) {
      return line.length > previous ? line.length : previous;
    });

    final estimatedTextWidth = (longestLineLength * fontHeight * 0.60).round();
    final boxWidth =
        math.min(decodedImage.width - 24, estimatedTextWidth + (padding * 2));
    final boxHeight = (tagLines.length * fontHeight) +
        ((tagLines.length - 1) * gap) +
        (padding * 2);

    final offset = _calculatePosition(
      imageWidth: decodedImage.width,
      imageHeight: decodedImage.height,
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      tagPosition: tagPosition,
      margin: 18,
    );

    img.drawRect(
      decodedImage,
      x1: offset.x,
      y1: offset.y,
      x2: offset.x + boxWidth,
      y2: offset.y + boxHeight,
      color: img.ColorRgba8(0, 0, 0, 135),
    );

    int y = offset.y + padding;
    for (final line in tagLines) {
      img.drawString(
        decodedImage,
        line,
        font: font,
        x: offset.x + padding,
        y: y,
        color: img.ColorRgb8(255, 255, 255),
      );
      y += fontHeight + gap;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final outputPath =
        '${appDir.path}/${filePrefix}_${DateTime.now().millisecondsSinceEpoch}_tagged.jpg';
    final outputBytes = img.encodeJpg(decodedImage, quality: 88);
    await File(outputPath).writeAsBytes(outputBytes, flush: true);

    return outputPath;
  }

  img.BitmapFont _fontBySize(String tagSize) {
    switch (tagSize) {
      case 'small':
        return img.arial14;
      case 'large':
        return img.arial24;
      case 'medium':
      default:
        return img.arial14;
    }
  }

  int _fontHeight(String tagSize) {
    switch (tagSize) {
      case 'small':
        return 16;
      case 'large':
        return 28;
      case 'medium':
      default:
        return 20;
    }
  }

  int _paddingBySize(String tagSize) {
    switch (tagSize) {
      case 'small':
        return 8;
      case 'large':
        return 14;
      case 'medium':
      default:
        return 10;
    }
  }

  _Offset _calculatePosition({
    required int imageWidth,
    required int imageHeight,
    required int boxWidth,
    required int boxHeight,
    required String tagPosition,
    required int margin,
  }) {
    switch (tagPosition) {
      case 'topLeft':
        return _Offset(margin, margin);
      case 'topRight':
        return _Offset(imageWidth - boxWidth - margin, margin);
      case 'bottomLeft':
        return _Offset(margin, imageHeight - boxHeight - margin);
      case 'bottomRight':
      default:
        return _Offset(
            imageWidth - boxWidth - margin, imageHeight - boxHeight - margin);
    }
  }
}

class _Offset {
  final int x;
  final int y;

  const _Offset(this.x, this.y);
}
