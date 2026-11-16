import 'package:flutter_test/flutter_test.dart';

import 'package:babytime/models/feeding_record.dart';
import 'package:babytime/models/growth_record.dart';

void main() {
  group('GrowthRecord 序列化', () {
    test('完整字段往返', () {
      final r = GrowthRecord(
        id: 1,
        date: DateTime(2026, 11, 16, 9),
        heightCm: 72.5,
        weightKg: 8.6,
        headCm: 44.2,
        note: '6月龄体检',
      );
      final back = GrowthRecord.fromMap(r.toMap());
      expect(back.id, 1);
      expect(back.heightCm, 72.5);
      expect(back.weightKg, 8.6);
      expect(back.headCm, 44.2);
      expect(back.note, '6月龄体检');
      expect(back.dateText, '2026-11-16');
    });

    test('头围/备注可空', () {
      final r = GrowthRecord(
          date: DateTime(2026, 11, 16), heightCm: 70, weightKg: 8);
      final back = GrowthRecord.fromMap(r.toMap());
      expect(back.headCm, isNull);
      expect(back.note, isNull);
    });
  });

  group('FeedingRecord 时长与序列化', () {
    test('时长按开始/结束计算', () {
      final r = FeedingRecord(
        startedAt: DateTime(2026, 11, 16, 8, 0),
        endedAt: DateTime(2026, 11, 16, 8, 12, 30),
        feedType: '母乳-左',
      );
      expect(r.duration.inSeconds, 750);
      expect(r.durationText, '12分30秒');
    });

    test('未结束返回 0 时长', () {
      final r = FeedingRecord(
          startedAt: DateTime(2026, 11, 16, 8), feedType: '瓶喂');
      expect(r.duration, Duration.zero);
      expect(r.durationText, '--');
    });

    test('序列化往返（含奶量）', () {
      final r = FeedingRecord(
        id: 3,
        startedAt: DateTime(2026, 11, 16, 8, 0),
        endedAt: DateTime(2026, 11, 16, 8, 15),
        feedType: '瓶喂',
        amountMl: 120,
        note: '睡前',
      );
      final back = FeedingRecord.fromMap(r.toMap());
      expect(back.id, 3);
      expect(back.feedType, '瓶喂');
      expect(back.amountMl, 120);
      expect(back.duration.inMinutes, 15);
      expect(back.note, '睡前');
    });
  });
}