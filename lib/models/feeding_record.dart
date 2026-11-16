/// 喂养记录（母乳左/右、瓶喂）。
class FeedingRecord {
  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// 母乳-左 / 母乳-右 / 瓶喂
  final String feedType;

  /// 瓶喂奶量（ml，可选）
  final int? amountMl;
  final String? note;

  const FeedingRecord({
    this.id,
    required this.startedAt,
    this.endedAt,
    required this.feedType,
    this.amountMl,
    this.note,
  });

  Duration get duration {
    final end = endedAt;
    if (end == null) return Duration.zero;
    final d = end.difference(startedAt);
    return d.isNegative ? Duration.zero : d;
  }

  String get durationText {
    final d = duration;
    if (d.inSeconds == 0) return '--';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return m > 0 ? '$m分${s.toString().padLeft(2, '0')}秒' : '$s秒';
  }

  String get startedText =>
      '${startedAt.month}/${startedAt.day} ${startedAt.hour.toString().padLeft(2, '0')}:${startedAt.minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
        'id': id,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'feed_type': feedType,
        'amount_ml': amountMl,
        'note': note,
      };

  static FeedingRecord fromMap(Map<String, dynamic> map) => FeedingRecord(
        id: map['id'] as int?,
        startedAt: DateTime.tryParse(map['started_at'] as String? ?? '') ??
            DateTime.now(),
        endedAt: DateTime.tryParse(map['ended_at'] as String? ?? ''),
        feedType: map['feed_type'] as String? ?? '母乳-左',
        amountMl: map['amount_ml'] as int?,
        note: map['note'] as String?,
      );
}