class CapturedPhoto {
  final String id;
  final String workOrderNumber;
  final String assetId;
  final String stage;
  final String imagePath;
  final String capturedAtIso;
  final double? latitude;
  final double? longitude;
  final String tagPosition;
  final String tagSize;

  const CapturedPhoto({
    required this.id,
    required this.workOrderNumber,
    required this.assetId,
    required this.stage,
    required this.imagePath,
    required this.capturedAtIso,
    required this.tagPosition,
    required this.tagSize,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workOrderNumber': workOrderNumber,
      'assetId': assetId,
      'stage': stage,
      'imagePath': imagePath,
      'capturedAtIso': capturedAtIso,
      'latitude': latitude,
      'longitude': longitude,
      'tagPosition': tagPosition,
      'tagSize': tagSize,
    };
  }

  factory CapturedPhoto.fromJson(Map<String, dynamic> json) {
    return CapturedPhoto(
      id: json['id'] ?? '',
      workOrderNumber: json['workOrderNumber'] ?? '',
      assetId: json['assetId'] ?? '',
      stage: json['stage'] ?? '',
      imagePath: json['imagePath'] ?? '',
      capturedAtIso: json['capturedAtIso'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      tagPosition: json['tagPosition'] ?? 'bottomRight',
      tagSize: json['tagSize'] ?? 'medium',
    );
  }
}
