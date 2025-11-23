/// Pterodactyl File Model
class FileModel {
  final String name;
  final String mode;
  final int size;
  final bool isFile;
  final bool isSymlink;
  final String mimetype;
  final DateTime createdAt;
  final DateTime modifiedAt;

  FileModel({
    required this.name,
    required this.mode,
    required this.size,
    required this.isFile,
    required this.isSymlink,
    required this.mimetype,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] ?? json;
    return FileModel(
      name: attributes['name'] ?? '',
      mode: attributes['mode'] ?? '',
      size: attributes['size'] ?? 0,
      isFile: attributes['is_file'] ?? false,
      isSymlink: attributes['is_symlink'] ?? false,
      mimetype: attributes['mimetype'] ?? 'application/octet-stream',
      createdAt: DateTime.parse(
          attributes['created_at'] ?? DateTime.now().toIso8601String()),
      modifiedAt: DateTime.parse(
          attributes['modified_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mode': mode,
      'size': size,
      'is_file': isFile,
      'is_symlink': isSymlink,
      'mimetype': mimetype,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
    }
    return '${(size / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  String get fileExtension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
}
