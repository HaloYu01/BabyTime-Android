class SleepRecord {
  final int? id;
  final DateTime date;
  final DateTime bedTime;
  final DateTime? wakeTime;
  final int nightWakings;
  final String? cryingNote;
  final String? note;

  /// 入睡耗时（分钟，可选，用于联合建模）。
  final int? sleepLatencyMinutes;

  /// 白天活动量（很少/一般/充足，可选）。
  final String? daytimeActivity;

  /// 健康事件备注（出牙/疫苗/生病等，可选）。
  final String? healthNote;

  const SleepRecord({
    this.id,
    required this.date,
    required this.bedTime,
    this.wakeTime,
    this.nightWakings = 0,
    this.cryingNote,
    this.note,
    this.sleepLatencyMinutes,
    this.daytimeActivity,
    this.healthNote,
  });

  /// 夜间睡眠总时长（小时），含夜醒片段。
  double durationHours() {
    if (wakeTime == null) return 0;
    final diff = wakeTime!.difference(bedTime);
    if (diff.isNegative) return 0;
    return diff.inMinutes / 60.0;
  }

  /// 睡眠效率（0-1 近似：仅在有醒来时间时有效，入睡耗时扣除）。
  double sleepEfficiency() {
    final duration = durationHours();
    if (duration <= 0) return 0;
    final latency = (sleepLatencyMinutes ?? 0) / 60.0;
    final effective = (duration - latency).clamp(0, duration);
    return effective / duration;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': _fmtDate(date),
        'bed_time': bedTime.toIso8601String(),
        'wake_time': wakeTime?.toIso8601String(),
        'night_wakings': nightWakings,
        'crying_note': cryingNote,
        'note': note,
        'sleep_latency_minutes': sleepLatencyMinutes,
        'daytime_activity': daytimeActivity,
        'health_note': healthNote,
      };

  static SleepRecord fromMap(Map<String, dynamic> map) => SleepRecord(
        id: map['id'] as int?,
        date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
        bedTime:
            DateTime.tryParse(map['bed_time'] as String? ?? '') ?? DateTime.now(),
        wakeTime: DateTime.tryParse(map['wake_time'] as String? ?? ''),
        nightWakings: (map['night_wakings'] as int?) ?? 0,
        cryingNote: map['crying_note'] as String?,
        note: map['note'] as String?,
        sleepLatencyMinutes: map['sleep_latency_minutes'] as int?,
        daytimeActivity: map['daytime_activity'] as String?,
        healthNote: map['health_note'] as String?,
      );

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String bedtimeText() =>
      '${bedTime.hour.toString().padLeft(2, '0')}:${bedTime.minute.toString().padLeft(2, '0')}';

  String waketimeText() {
    final w = wakeTime;
    if (w == null) return '未醒';
    return '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
  }

  String durationText() {
    final h = durationHours();
    if (h <= 0) return '--';
    final hh = h.floor();
    final mm = ((h - hh) * 60).round();
    return mm == 0 ? '$hh小时' : '$hh小时$mm分';
  }
}