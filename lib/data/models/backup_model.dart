/// Pterodactyl Backup Model
class BackupModel {
  final String uuid;
  final String name;
  final bool isSuccessful;
  final bool isLocked;
  final int bytes;
  final DateTime createdAt;
  final DateTime? completedAt;

  BackupModel({
    required this.uuid,
    required this.name,
    required this.isSuccessful,
    required this.isLocked,
    required this.bytes,
    required this.createdAt,
    this.completedAt,
  });

  factory BackupModel.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] ?? json;
    return BackupModel(
      uuid: attributes['uuid'] ?? '',
      name: attributes['name'] ?? '',
      isSuccessful: attributes['is_successful'] ?? false,
      isLocked: attributes['is_locked'] ?? false,
      bytes: attributes['bytes'] ?? 0,
      createdAt: DateTime.parse(
          attributes['created_at'] ?? DateTime.now().toIso8601String()),
      completedAt: attributes['completed_at'] != null
          ? DateTime.parse(attributes['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'is_successful': isSuccessful,
      'is_locked': isLocked,
      'bytes': bytes,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  String get sizeFormatted {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}
