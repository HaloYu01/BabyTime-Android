import '../core/constants.dart';
import '../models/diet_advice.dart';

class DietValidationResult {
  final List<MealSuggestion> kept;
  final List<MealSuggestion> removed;
  const DietValidationResult(this.kept, this.removed);

  int get removedCount => removed.length;
}

/// 确定性饮食安全校验：把模型输出与真实月龄做规则比对，命中即拦截。
class DietSafetyValidator {
  /// 返回违规原因；null 表示该条建议在当前月龄下安全。
  static String? violationOf(MealSuggestion suggestion, int months) {
    if (suggestion.minMonth > 0 && suggestion.minMonth > months) {
      return '标注最少适用 ${suggestion.minMonth} 个月';
    }
    final food = suggestion.food;
    for (final f in forbiddenFoods) {
      if (months >= f.minMonth) continue;
      if (food.contains(f.keyword)) {
        return '「${f.keyword}」${f.reason}';
      }
    }
    return null;
  }

  static DietValidationResult validate(
      List<MealSuggestion> suggestions, int months) {
    final kept = <MealSuggestion>[];
    final removed = <MealSuggestion>[];
    for (final s in suggestions) {
      if (violationOf(s, months) == null) {
        kept.add(s);
      } else {
        removed.add(s);
      }
    }
    return DietValidationResult(kept, removed);
  }

  /// 内置分阶段安全模板：AI 全部被拦截或解析失败时兜底。
  static List<MealSuggestion> fallbackSuggestions(int months) {
    if (months < 6) {
      return const [
        MealSuggestion(
          meal: '喂养',
          food: '母乳或配方奶',
          reason: '6 月龄前以奶类为主，无需添加辅食',
          minMonth: 0,
        ),
      ];
    }
    if (months < 8) {
      return const [
        MealSuggestion(
          meal: '午餐',
          food: '高铁米粉糊 + 南瓜泥',
          reason: '泥糊状单一食材，观察 2~3 天过敏反应',
          minMonth: 6,
        ),
        MealSuggestion(
          meal: '加餐',
          food: '苹果泥',
          reason: '水果泥补充维生素，质地细腻',
          minMonth: 6,
        ),
        MealSuggestion(
          meal: '晚餐',
          food: '西兰花米糊',
          reason: '蔬菜泥搭配米粉，不加盐糖',
          minMonth: 6,
        ),
      ];
    }
    if (months < 12) {
      return const [
        MealSuggestion(
          meal: '午餐',
          food: '软烂粥 + 碎菜 + 肉末',
          reason: '小颗粒锻炼咀嚼，肉末补铁',
          minMonth: 8,
        ),
        MealSuggestion(
          meal: '加餐',
          food: '香蕉小块',
          reason: '软质水果易抓握，注意切小',
          minMonth: 8,
        ),
        MealSuggestion(
          meal: '晚餐',
          food: '豆腐碎 + 碎面条',
          reason: '软烂易消化，不加盐',
          minMonth: 8,
        ),
      ];
    }
    if (months < 24) {
      return const [
        MealSuggestion(
          meal: '午餐',
          food: '软饭 + 碎肉 + 蔬菜',
          reason: '软烂家常，可少量盐（<1.5g/日）',
          minMonth: 12,
        ),
        MealSuggestion(
          meal: '加餐',
          food: '原味酸奶 + 水果小块',
          reason: '补充蛋白与钙，水果切小块',
          minMonth: 12,
        ),
        MealSuggestion(
          meal: '晚餐',
          food: '蔬菜面条',
          reason: '易咀嚼消化，睡前留足间隔',
          minMonth: 12,
        ),
      ];
    }
    return const [
      MealSuggestion(
        meal: '午餐',
        food: '家常软烂饭菜',
        reason: '接近家庭饮食，荤素搭配',
        minMonth: 24,
      ),
      MealSuggestion(
        meal: '加餐',
        food: '水果 / 原味酸奶',
        reason: '控糖零食，避免含糖饮料',
        minMonth: 24,
      ),
      MealSuggestion(
        meal: '晚餐',
        food: '清淡家常菜 + 米饭',
        reason: '控盐控油，晚餐与睡前间隔 1 小时以上',
        minMonth: 24,
      ),
    ];
  }
}