class TagSettings {
  final String position;
  final String size;

  const TagSettings({
    required this.position,
    required this.size,
  });

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'size': size,
    };
  }

  factory TagSettings.fromJson(Map<String, dynamic> json) {
    return TagSettings(
      position: json['position'] ?? 'bottomRight',
      size: json['size'] ?? 'medium',
    );
  }
}
