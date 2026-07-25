import 'captured_photo.dart';

class WorkOrderModel {
  final String id;
  final String workOrderNumber;
  final String assetId;
  final bool progressOnly;
  final String notes;
  final String status;
  final String createdAtIso;
  final String? submittedAtIso;
  final bool isSynced;
  final List<CapturedPhoto> photos;

  const WorkOrderModel({
    required this.id,
    required this.workOrderNumber,
    required this.assetId,
    required this.progressOnly,
    required this.notes,
    required this.status,
    required this.createdAtIso,
    required this.submittedAtIso,
    required this.isSynced,
    required this.photos,
  });

  WorkOrderModel copyWith({
    String? notes,
    String? status,
    String? submittedAtIso,
    bool? isSynced,
    List<CapturedPhoto>? photos,
  }) {
    return WorkOrderModel(
      id: id,
      workOrderNumber: workOrderNumber,
      assetId: assetId,
      progressOnly: progressOnly,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAtIso: createdAtIso,
      submittedAtIso: submittedAtIso ?? this.submittedAtIso,
      isSynced: isSynced ?? this.isSynced,
      photos: photos ?? this.photos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workOrderNumber': workOrderNumber,
      'assetId': assetId,
      'progressOnly': progressOnly,
      'notes': notes,
      'status': status,
      'createdAtIso': createdAtIso,
      'submittedAtIso': submittedAtIso,
      'isSynced': isSynced,
      'photos': photos.map((photo) => photo.toJson()).toList(),
    };
  }

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'];
    final photoList = rawPhotos is List ? rawPhotos : <dynamic>[];

    return WorkOrderModel(
      id: json['id'] ?? '',
      workOrderNumber: json['workOrderNumber'] ?? '',
      assetId: json['assetId'] ?? '',
      progressOnly: json['progressOnly'] ?? false,
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'Draft',
      createdAtIso: json['createdAtIso'] ?? '',
      submittedAtIso: json['submittedAtIso'],
      isSynced: json['isSynced'] ?? false,
      photos: photoList
          .map((item) => CapturedPhoto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
