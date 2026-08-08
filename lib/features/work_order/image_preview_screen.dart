import 'dart:io';

import 'package:flutter/material.dart';

class ImagePreviewScreen extends StatelessWidget {
  final Map<String, String> photo;
  final String title;
  final bool showKeepButton;
  final bool showDeleteButton;

  const ImagePreviewScreen({
    super.key,
    required this.photo,
    required this.title,
    this.showKeepButton = false,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final String imagePath = photo['imagePath'] ?? '';
    final String imageUrl = photo['url'] ?? '';
    final bool isServerPhoto = imageUrl.isNotEmpty;
    final String stage = photo['stage'] ?? '';
    final String displayTime = photo['displayTime'] ?? '';
    final String latitude = photo['latitude'] ?? '';
    final String longitude = photo['longitude'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: isServerPhoto
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (
                            context,
                            child,
                            loadingProgress,
                          ) {
                            if (loadingProgress == null) {
                              return child;
                            }

                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Center(
                              child: Text(
                                'Unable to load server image',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        )
                      : Image.file(
                          File(imagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Center(
                              child: Text(
                                'Image preview failed',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tagged Photo Preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stage: $stage',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Time: $displayTime',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    latitude.isEmpty || longitude.isEmpty
                        ? 'GPS: unavailable'
                        : 'GPS: $latitude, $longitude',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  if (showKeepButton)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context, 'remove');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(
                                color: Colors.redAccent,
                              ),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text('Remove Photo'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, 'keep');
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text('Keep Photo'),
                          ),
                        ),
                      ],
                    )
                  else if (showDeleteButton)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, 'delete');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text('Delete'),
                          ),
                        ),
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Close Preview'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
