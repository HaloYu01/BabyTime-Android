import 'package:flutter_test/flutter_test.dart';

import 'package:babytime/services/shoe_size_matcher.dart';

void main() {
  group('0.1cm 粒度分档与边界', () {
    test('所需内长恰等于档位内长 → 取该档（闭区间）', () {
      final m =
          ShoeSizeMatcher.recommend(footLengthCm: 12.0, allowanceCm: 1.0);
      expect(m.row.footLengthCm, 12.0);
      expect(m.requiredInnerCm, closeTo(13.0, 1e-9));
      expect(m.clampedLow, isFalse);
      expect(m.clampedHigh, isFalse);
    });

    test('12.1cm + 1.0 = 13.1 → 向上取 12.5 档（防挤脚）', () {
      final m =
          ShoeSizeMatcher.recommend(footLengthCm: 12.1, allowanceCm: 1.0);
      expect(m.row.footLengthCm, 12.5);
      expect(m.rowInnerText, '13.5');
      expect(m.clampedHigh, isFalse);
    });

    test('0.1cm 浮点无误差：12.1 + 0.9 = 13.0 → 12.0 档', () {
      final m =
          ShoeSizeMatcher.recommend(footLengthCm: 12.1, allowanceCm: 0.9);
      expect(m.requiredInnerCm, closeTo(13.0, 1e-9));
      expect(m.row.footLengthCm, 12.0);
    });

    test('19.9 + 1.0 = 20.9 → 20.0 档（表内上限）', () {
      final m =
          ShoeSizeMatcher.recommend(footLengthCm: 19.9, allowanceCm: 1.0);
      expect(m.row.footLengthCm, 20.0);
      expect(m.clampedHigh, isFalse);
    });

    test('20.0 + 1.5 = 21.5 → 超出上限取最大档并提示', () {
      final m =
          ShoeSizeMatcher.recommend(footLengthCm: 20.0, allowanceCm: 1.5);
      expect(m.row.footLengthCm, 20.0);
      expect(m.clampedHigh, isTrue);
      expect(m.note, isNotNull);
    });

    test('10.0cm（低于表格最小脚长）→ 最小档 + 下限提示', () {
      final m =
          ShoeSizeMatcher.recommend(footLengthCm: 10.0, allowanceCm: 0.5);
      expect(m.row.footLengthCm, 10.5);
      expect(m.clampedLow, isTrue);
      expect(m.note, isNotNull);
    });

    test('10.5cm（表格最小档脚长）→ 正常匹配、不提示下限', () {
      final m =
          ShoeSizeMatcher.recommend(footLengthCm: 10.5, allowanceCm: 0.5);
      expect(m.row.footLengthCm, 10.5);
      expect(m.clampedLow, isFalse);
      expect(m.note, isNull);
    });

    test('clampFootLength 归整到 0.1 并限制范围', () {
      expect(ShoeSizeMatcher.clampFootLength(12.34), closeTo(12.3, 1e-9));
      expect(ShoeSizeMatcher.clampFootLength(9.5), closeTo(10.0, 1e-9));
      expect(ShoeSizeMatcher.clampFootLength(20.5), closeTo(20.0, 1e-9));
    });
  });
}