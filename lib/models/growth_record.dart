/// 生长记录（身高/体重/头围）。
class GrowthRecord {
  final int? id;
  final DateTime date;
  final double heightCm;
  final double weightKg;
  final double? headCm;
  final String? note;

  const GrowthRecord({
    this.id,
    required this.date,
    required this.heightCm,
    required this.weightKg,
    this.headCm,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'head_cm': headCm,
        'note': note,
      };

  static GrowthRecord fromMap(Map<String, dynamic> map) => GrowthRecord(
        id: map['id'] as int?,
        date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
        heightCm: (map['height_cm'] as num?)?.toDouble() ?? 0,
        weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 0,
        headCm: (map['head_cm'] as num?)?.toDouble(),
        note: map['note'] as String?,
      );

  String get dateText =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}