import 'dart:convert';

class PhotoMemory {
  final int? id;
  final DateTime createdAt;
  final String originalPath;
  final String? cutoutPath;
  final String? note;

  const PhotoMemory({
    this.id,
    required this.createdAt,
    required this.originalPath,
    this.cutoutPath,
    this.note,
  });

  PhotoMemory copyWith({String? cutoutPath, String? note}) => PhotoMemory(
        id: id,
        createdAt: createdAt,
        originalPath: originalPath,
        cutoutPath: cutoutPath ?? this.cutoutPath,
        note: note ?? this.note,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'original_path': originalPath,
        'cutout_path': cutoutPath,
        'note': note,
      };

  static PhotoMemory fromMap(Map<String, dynamic> map) => PhotoMemory(
        id: map['id'] as int?,
        createdAt:
            DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
        originalPath: map['original_path'] as String? ?? '',
        cutoutPath: map['cutout_path'] as String?,
        note: map['note'] as String?,
      );

  String encode() => jsonEncode(toMap());
}