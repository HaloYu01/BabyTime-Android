import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:babytime/core/constants.dart';
import 'package:babytime/core/nexio.dart';
import 'package:babytime/models/baby_profile.dart';
import 'package:babytime/models/prediction_result.dart';
import 'package:babytime/models/sleep_record.dart';

void main() {
  group('Nexio 设计令牌', () {
    test('主色与浅色令牌符合规范', () {
      expect(NexioColors.primary, const Color(0xFF3482FF));
      expect(NexioColors.background, const Color(0xFFFFFFFF));
      expect(NexioColors.smallTitle, const Color(0xFF8F9CAE));
      expect(NexioShape.squircle(20), isA<RoundedSuperellipseBorder>());
    });

    test('字号体系 32/24/20/18/17/16/14/13/11', () {
      expect(NexioType.t1.fontSize, 32);
      expect(NexioType.t2.fontSize, 24);
      expect(NexioType.t3.fontSize, 20);
      expect(NexioType.t4.fontSize, 18);
      expect(NexioType.main.fontSize, 17);
      expect(NexioType.body1.fontSize, 16);
      expect(NexioType.body2.fontSize, 14);
      expect(NexioType.footnote1.fontSize, 13);
      expect(NexioType.footnote2.fontSize, 11);
    });
  });

  group('AI 预测 JSON 容错解析', () {
    test('支持 ```json 围栏与前后杂质文字', () {
      final result = PredictionResult.fromRawJson('''
分析如下：
```json
{"wake_predictions":[{"time":"02:30","probability":"高","reason":"连续夜醒"}],
 "cry_risk_periods":[{"period":"22:00-23:00","probability":"中","reason":"入睡困难"}],
 "advice":["提前哄睡"],"summary":"规律稳定"}
```
以上。''');
      expect(result.wakePredictions.single.time, '02:30');
      expect(result.cryRiskPeriods.single.period, '22:00-23:00');
      expect(result.advice.single, '提前哄睡');
      expect(result.summary, '规律稳定');
    });

    test('序列化往返', () {
      final r = PredictionResult(
        wakePredictions: const [
          WakePrediction(time: '01:00', probability: '高', reason: '测试'),
        ],
        cryRiskPeriods: const [],
        advice: const ['a'],
        summary: 's',
        createdAt: DateTime(2026, 11, 14),
      );
      final restored = PredictionResult.fromMap(r.toMap());
      expect(restored.wakePredictions.single.time, '01:00');
      expect(restored.summary, 's');
    });
  });

  group('睡眠时长计算', () {
    test('跨天睡眠 9 小时 20 分', () {
      final record = SleepRecord(
        date: DateTime(2026, 11, 14),
        bedTime: DateTime(2026, 11, 13, 21, 30),
        wakeTime: DateTime(2026, 11, 14, 6, 50),
        nightWakings: 2,
      );
      expect(record.durationHours(), closeTo(9.33, 0.01));
      expect(record.durationText(), '9小时20分');
    });

    test('未记录醒来时间', () {
      final record = SleepRecord(
          date: DateTime.now(), bedTime: DateTime.now());
      expect(record.durationText(), '--');
      expect(record.waketimeText(), '未醒');
    });
  });

  group('业务数据', () {
    test('鞋码对照表覆盖 10.5~20cm', () {
      expect(shoeSizeTable.length, 20);
      for (final row in shoeSizeTable) {
        expect(row.footLengthCm, inInclusiveRange(10.5, 20));
        expect(row.cnSize, isNotEmpty);
        expect(row.euSize, isNotEmpty);
        expect(row.usSize, isNotEmpty);
      }
    });

    test('地域饮食特征库', () {
      expect(regionDietTraits.length, greaterThanOrEqualTo(25));
      expect(regionDietTraits['广东'], contains('粥'));
      expect(regionDietTraits['山西'], contains('面食'));
    });

    test('宝宝月龄计算', () {
      final baby = BabyProfile(
        birthday: DateTime.now().subtract(const Duration(days: 180)),
        name: '测试宝宝',
      );
      expect(baby.monthsOld, inInclusiveRange(5, 6));
      expect(baby.describe(), contains('测试宝宝'));
    });
  });
}