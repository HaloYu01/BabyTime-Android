import 'package:flutter_test/flutter_test.dart';

import 'package:babytime/core/constants.dart';
import 'package:babytime/models/diet_advice.dart';
import 'package:babytime/models/meal_record.dart';
import 'package:babytime/services/diet_safety_validator.dart';

void main() {
  group('月龄阶段映射', () {
    test('边界月份映射正确', () {
      expect(stageForMonths(0).name, '奶类期');
      expect(stageForMonths(5).name, '奶类期');
      expect(stageForMonths(6).name, '泥糊期');
      expect(stageForMonths(7).name, '泥糊期');
      expect(stageForMonths(8).name, '颗粒期');
      expect(stageForMonths(11).name, '颗粒期');
      expect(stageForMonths(12).name, '软烂期');
      expect(stageForMonths(23).name, '软烂期');
      expect(stageForMonths(24).name, '常规期');
      expect(stageForMonths(60).name, '常规期');
    });

    test('禁用清单随月龄收敛', () {
      expect(forbiddenKeywordsFor(8), contains('蜂蜜'));
      expect(forbiddenKeywordsFor(8), contains('盐'));
      expect(forbiddenKeywordsFor(12), isNot(contains('蜂蜜')));
      expect(forbiddenKeywordsFor(24), isNot(contains('坚果')));
      expect(forbiddenKeywordsFor(24), contains('果冻'));
      expect(forbiddenKeywordsFor(36), isNot(contains('果冻')));
    });
  });

  group('DietSafetyValidator 月龄校验', () {
    test('8 月龄拦截蜂蜜与加盐建议', () {
      const honey =
          MealSuggestion(meal: '加餐', food: '蜂蜜水', reason: '');
      const salt = MealSuggestion(meal: '晚餐', food: '菠菜粥（加盐）', reason: '');
      expect(DietSafetyValidator.violationOf(honey, 8), isNotNull);
      expect(DietSafetyValidator.violationOf(salt, 8), isNotNull);
    });

    test('24 月龄放行蜂蜜', () {
      const honey =
          MealSuggestion(meal: '加餐', food: '蜂蜜水', reason: '');
      expect(DietSafetyValidator.violationOf(honey, 24), isNull);
    });

    test('min_month 超过当前月龄被拦截', () {
      const s = MealSuggestion(
          meal: '午餐', food: '软饭', reason: '', minMonth: 18);
      expect(DietSafetyValidator.violationOf(s, 8), isNotNull);
      expect(DietSafetyValidator.violationOf(s, 24), isNull);
    });

    test('批量校验保留安全项并统计过滤数', () {
      const list = [
        MealSuggestion(meal: '午餐', food: '南瓜泥', reason: '', minMonth: 6),
        MealSuggestion(meal: '加餐', food: '蜂蜜水', reason: ''),
        MealSuggestion(meal: '晚餐', food: '苹果泥', reason: '', minMonth: 6),
      ];
      final r = DietSafetyValidator.validate(list, 8);
      expect(r.kept.length, 2);
      expect(r.removedCount, 1);
      expect(r.removed.single.food, '蜂蜜水');
    });

    test('兜底模板各阶段非空且全部合规', () {
      for (final m in [5, 7, 10, 18, 30]) {
        final list = DietSafetyValidator.fallbackSuggestions(m);
        expect(list, isNotEmpty, reason: '阶段 $m 模板为空');
        for (final s in list) {
          expect(DietSafetyValidator.violationOf(s, m), isNull,
              reason: '阶段 $m 的兜底建议「${s.food}」不符合月龄');
        }
      }
    });
  });

  group('MealRecord 自定义食物名称', () {
    test('其他类型展示与提示词格式', () {
      final r = MealRecord(
          time: DateTime(2026, 11, 15),
          foodType: '其他',
          customFoodName: '山药泥');
      expect(r.foodLabel, '其他 · 山药泥');
      expect(r.promptLabel, '其他（山药泥）');
    });

    test('非其他类型忽略自定义名称', () {
      final r = MealRecord(time: DateTime(2026, 11, 15), foodType: '米饭');
      expect(r.foodLabel, '米饭');
      expect(r.promptLabel, '米饭');
    });

    test('序列化往返保留 custom_food_name', () {
      final r = MealRecord(
        id: 3,
        time: DateTime(2026, 11, 15),
        foodType: '其他',
        customFoodName: '山药泥',
        description: '一小碗',
      );
      final back = MealRecord.fromMap(r.toMap());
      expect(back.id, 3);
      expect(back.customFoodName, '山药泥');
      expect(back.foodLabel, '其他 · 山药泥');
    });
  });

  group('DietAdvice 依据标签与解析', () {
    test('basisLabel 携带真实月龄与阶段', () {
      final advice = DietAdvice.fromRawJson(
        '{"today_suggestions":[{"meal":"午餐","food":"南瓜泥","reason":"","min_month":6}],'
        '"sleep_impact":"","advice":[],"summary":"s"}',
        months: 8,
        stageName: '泥糊期',
      );
      expect(advice.basisLabel, '依据：8 个月 · 泥糊期');
      expect(advice.suggestions.single.minMonth, 6);
    });
  });
}