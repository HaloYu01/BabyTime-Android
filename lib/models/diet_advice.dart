import 'prediction_result.dart';

class MealSuggestion {
  final String meal;
  final String food;
  final String reason;

  /// 该建议的最低适用月龄（AI 输出字段 min_month），0 表示未提供。
  final int minMonth;

  const MealSuggestion({
    required this.meal,
    required this.food,
    required this.reason,
    this.minMonth = 0,
  });

  factory MealSuggestion.fromJson(Map<String, dynamic> j) => MealSuggestion(
        meal: j['meal']?.toString() ?? '',
        food: j['food']?.toString() ?? '',
        reason: j['reason']?.toString() ?? '',
        minMonth: int.tryParse(j['min_month']?.toString() ?? '') ?? 0,
      );
}

/// 饮食建议结果：携带生成依据（月龄/阶段）与校验信息，便于 UI 展示与验收。
class DietAdvice {
  final List<MealSuggestion> suggestions;
  final String sleepImpact;
  final List<String> advice;
  final String summary;
  final int months;
  final String stageName;
  final int filteredCount;
  final bool isFallback;

  const DietAdvice({
    required this.suggestions,
    required this.sleepImpact,
    required this.advice,
    required this.summary,
    required this.months,
    required this.stageName,
    this.filteredCount = 0,
    this.isFallback = false,
  });

  factory DietAdvice.fromRawJson(
    String raw, {
    required int months,
    required String stageName,
  }) {
    final map = PredictionResult.parseLooseJson(raw);
    return DietAdvice(
      suggestions: (map['today_suggestions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MealSuggestion.fromJson)
          .toList(),
      sleepImpact: map['sleep_impact']?.toString() ?? '',
      advice: (map['advice'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      summary: map['summary']?.toString() ?? '',
      months: months,
      stageName: stageName,
    );
  }

  DietAdvice copyWith({
    List<MealSuggestion>? suggestions,
    int? filteredCount,
    bool? isFallback,
  }) =>
      DietAdvice(
        suggestions: suggestions ?? this.suggestions,
        sleepImpact: sleepImpact,
        advice: advice,
        summary: summary,
        months: months,
        stageName: stageName,
        filteredCount: filteredCount ?? this.filteredCount,
        isFallback: isFallback ?? this.isFallback,
      );

  /// 依据标签：如「依据：8 个月 · 泥糊期」。
  String get basisLabel => '依据：$months 个月 · $stageName';
}