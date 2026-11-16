import 'package:flutter_test/flutter_test.dart';

import 'package:babytime/models/baby_profile.dart';
import 'package:babytime/models/meal_record.dart';
import 'package:babytime/models/sleep_record.dart';
import 'package:babytime/services/food_features.dart';
import 'package:babytime/services/joint_sleep_predictor.dart';

void main() {
  group('FoodTypeFeatureMapper 自由类型映射', () {
    test('面食/米类/奶制品', () {
      expect(FoodTypeFeatureMapper.map('西红柿鸡蛋面').isWheat, isTrue);
      expect(FoodTypeFeatureMapper.map('米饭').isRice, isTrue);
      expect(FoodTypeFeatureMapper.map('小米粥').isRice, isTrue);
      expect(FoodTypeFeatureMapper.map('小米粥').isLiquid, isTrue);
      expect(FoodTypeFeatureMapper.map('酸奶').isDairy, isTrue);
      expect(FoodTypeFeatureMapper.map('酸奶').isLiquid, isTrue);
    });

    test('胀气/含糖/致敏/蛋白', () {
      final broccoli = FoodTypeFeatureMapper.map('西兰花泥');
      expect(broccoli.isGassy, isTrue);
      expect(broccoli.isVeg, isTrue);
      expect(FoodTypeFeatureMapper.map('小蛋糕').isSugary, isTrue);
      expect(FoodTypeFeatureMapper.map('蒸蛋').isAllergen, isTrue);
      expect(FoodTypeFeatureMapper.map('鳕鱼泥').isProtein, isTrue);
    });

    test('未知类型不误判', () {
      expect(FoodTypeFeatureMapper.map('神秘食物').isEmpty, isTrue);
      expect(FoodTypeFeatureMapper.map('').isEmpty, isTrue);
      expect(FoodTypeFeatureMapper.map('零食').isEmpty, isTrue);
    });
  });

  group('JointSleepPredictor 联合预测', () {
    final profile = BabyProfile(
        birthday: DateTime.now().subtract(const Duration(days: 240)));

    SleepRecord sleepRecord({
      required DateTime bed,
      int wakings = 1,
      String? health,
      String? activity,
      int? latency,
      String? crying,
    }) =>
        SleepRecord(
          date: bed,
          bedTime: bed,
          wakeTime: bed.add(const Duration(hours: 9)),
          nightWakings: wakings,
          healthNote: health,
          daytimeActivity: activity,
          sleepLatencyMinutes: latency,
          cryingNote: crying,
        );

    MealRecord meal(DateTime time, String type,
            {String? portion, String? after}) =>
        MealRecord(
            time: time, foodType: type, portion: portion, afterEffect: after);

    test('无睡眠记录时低置信度且不崩溃', () {
      final p = JointSleepPredictor.predict(
          sleepRecords: const [], mealRecords: const [], profile: profile);
      expect(p.confidence, lessThan(0.2));
      expect(p.sleepSamples, 0);
      expect(p.summary, contains('睡眠记录'));
      expect(p.predictedWakings, greaterThanOrEqualTo(0));
    });

    test('健康事件 + 睡前短间隔 + 晚餐面食 → 风险升高且有归因', () {
      final bed = DateTime(2026, 11, 15, 21, 0);
      final records = [
        sleepRecord(
            bed: bed,
            wakings: 2,
            health: '出牙',
            activity: '很少',
            latency: 40),
        sleepRecord(bed: bed.subtract(const Duration(days: 1)), wakings: 2),
        sleepRecord(bed: bed.subtract(const Duration(days: 2)), wakings: 1),
      ];
      final meals = [
        meal(DateTime(2026, 11, 15, 19, 30), '西红柿鸡蛋面', portion: '偏多'),
      ];
      final p = JointSleepPredictor.predict(
          sleepRecords: records, mealRecords: meals, profile: profile);
      expect(p.factors, isNotEmpty);
      expect(p.factors.any((f) => f.label.contains('面食')), isTrue);
      expect(p.factors.any((f) => f.label.contains('健康事件')), isTrue);
      expect(p.predictedWakings, greaterThanOrEqualTo(2));
      expect(p.wakeProbability, greaterThan(0.4));
    });

    test('间隔合理 + 活动充足 → 出现负向因素', () {
      final bed = DateTime(2026, 11, 15, 21, 0);
      final records = [sleepRecord(bed: bed, wakings: 1, activity: '充足')];
      final meals = [meal(DateTime(2026, 11, 15, 17, 0), '米饭 + 蔬菜')];
      final p = JointSleepPredictor.predict(
          sleepRecords: records, mealRecords: meals, profile: profile, now: bed);
      expect(p.factors.any((f) => f.isNegative), isTrue);
      expect(p.factors.any((f) => f.label.contains('进食间隔合理')), isTrue);
    });

    test('餐后不适显著提升风险', () {
      final bed = DateTime(2026, 11, 15, 21, 0);
      final records = [sleepRecord(bed: bed)];
      final meals = [
        meal(DateTime(2026, 11, 15, 18, 0), '西兰花泥', after: '胀气'),
      ];
      final p = JointSleepPredictor.predict(
          sleepRecords: records, mealRecords: meals, profile: profile);
      expect(p.factors.any((f) => f.label.contains('餐后不适')), isTrue);
    });

    test('置信度随数据量提升', () {
      final bed = DateTime(2026, 11, 15, 21, 0);
      final one = JointSleepPredictor.predict(
          sleepRecords: [sleepRecord(bed: bed)],
          mealRecords: const [],
          profile: profile);
      final many = JointSleepPredictor.predict(
          sleepRecords: List.generate(
              7, (i) => sleepRecord(bed: bed.subtract(Duration(days: i)))),
          mealRecords: List.generate(
              10, (i) => meal(DateTime(2026, 11, 15 - i, 18), '米饭')),
          profile: profile);
      expect(many.confidence, greaterThan(one.confidence));
    });

    test('预测输出在合理范围', () {
      final bed = DateTime(2026, 11, 15, 21, 0);
      final records = List.generate(
          5, (i) => sleepRecord(bed: bed.subtract(Duration(days: i)), wakings: i % 4));
      final p = JointSleepPredictor.predict(
          sleepRecords: records, mealRecords: const [], profile: profile);
      expect(p.predictedWakings, inInclusiveRange(0, 8));
      expect(p.wakeProbability, inInclusiveRange(0.05, 0.95));
      expect(['高', '中', '低'], contains(p.cryRiskLevel));
      expect(p.confidencePercent, inInclusiveRange(0, 100));
    });
  });

  group('模型字段扩展', () {
    test('MealRecord 份量/反应/有效名称与序列化', () {
      final r = MealRecord(
          time: DateTime(2026, 11, 15),
          foodType: '山药泥',
          portion: '正常',
          afterEffect: '无异常');
      expect(r.effectiveFoodName, '山药泥');
      final back = MealRecord.fromMap(r.toMap());
      expect(back.portion, '正常');
      expect(back.afterEffect, '无异常');
    });

    test('旧「其他」记录取自定义名称', () {
      final r = MealRecord(
          time: DateTime(2026), foodType: '其他', customFoodName: '鳕鱼泥');
      expect(r.effectiveFoodName, '鳕鱼泥');
    });

    test('SleepRecord 新字段与睡眠效率', () {
      final r = SleepRecord(
        date: DateTime(2026, 11, 15),
        bedTime: DateTime(2026, 11, 15, 21),
        wakeTime: DateTime(2026, 11, 16, 7),
        sleepLatencyMinutes: 30,
        daytimeActivity: '一般',
        healthNote: '疫苗',
      );
      expect(r.sleepLatencyMinutes, 30);
      expect(r.sleepEfficiency(), lessThan(1));
      final back = SleepRecord.fromMap(r.toMap());
      expect(back.healthNote, '疫苗');
      expect(back.daytimeActivity, '一般');
    });
  });
}