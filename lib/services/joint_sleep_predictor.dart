import '../models/baby_profile.dart';
import '../models/meal_record.dart';
import '../models/sleep_record.dart';
import 'food_features.dart';

/// 单一因素对预测的贡献（可解释归因）。
class FactorContribution {
  final String label;
  final double delta; // 正值提高夜醒风险，负值降低
  final String detail;
  const FactorContribution(this.label, this.delta, this.detail);

  bool get isNegative => delta < 0;
  String get deltaText => delta == 0
      ? '—'
      : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(2)}';
}

/// 饮食 × 睡眠联合预测结果（本地可解释模型，不依赖网络）。
class JointPrediction {
  final int predictedWakings;
  final double wakeProbability;
  final String cryRiskLevel; // 高/中/低
  final List<FactorContribution> factors;
  final double confidence; // 0-1
  final int sleepSamples;
  final int mealSamples;
  final String summary;
  final DateTime generatedAt;

  const JointPrediction({
    required this.predictedWakings,
    required this.wakeProbability,
    required this.cryRiskLevel,
    required this.factors,
    required this.confidence,
    required this.sleepSamples,
    required this.mealSamples,
    required this.summary,
    required this.generatedAt,
  });

  int get confidencePercent => (confidence * 100).round();
  int get probabilityPercent => (wakeProbability * 100).round();
}

/// 联合建模：把饮食作为睡眠的时变协变量，在同一时间轴上做可解释加权评分。
///
/// 设计要点：
///  - 冷启动：数据不足时返回月龄基线的低置信度预测，而不是空结果；
///  - 交互项：面食×进食间隔、胀气×低月龄、甜食×活动量等组合因素；
///  - 可解释：每项因素都有方向与权重，直接用于 UI 归因；
///  - 自由类型：饮食特征由 [FoodTypeFeatureMapper] 从自由文本提取，不依赖固定枚举。
class JointSleepPredictor {
  static JointPrediction predict({
    required List<SleepRecord> sleepRecords,
    required List<MealRecord> mealRecords,
    required BabyProfile profile,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final months = profile.monthsOld;
    final base = _baseWakings(months);
    final sorted =
        [...sleepRecords]..sort((a, b) => b.bedTime.compareTo(a.bedTime));
    final sleepSamples = sorted.length;
    final mealSamples = mealRecords.length;

    if (sleepSamples == 0) {
      return JointPrediction(
        predictedWakings: base.round(),
        wakeProbability: 0.5,
        cryRiskLevel: '中',
        factors: const [
          FactorContribution('数据不足', 0, '先记录 2~3 天睡眠与饮食，联合分析会逐步可用'),
        ],
        confidence: 0.1,
        sleepSamples: 0,
        mealSamples: mealSamples,
        summary: '还没有睡眠记录，暂时无法做饮食 × 睡眠的联合分析。',
        generatedAt: reference,
      );
    }

    final latest = sorted.first;
    final recent = sorted.take(3).toList();
    final avgWakings =
        recent.map((r) => r.nightWakings).reduce((a, b) => a + b) /
            recent.length;

    // 饮食窗口：入睡前 14 小时内的进餐
    final windowStart = latest.bedTime.subtract(const Duration(hours: 14));
    final meals = mealRecords
        .where((m) =>
            m.time.isAfter(windowStart) && m.time.isBefore(latest.bedTime))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    final lastMeal = meals.isEmpty ? null : meals.last;
    final gapHours = lastMeal == null
        ? null
        : latest.bedTime.difference(lastMeal.time).inMinutes / 60.0;
    final evening = meals.where((m) => m.time.hour >= 18).toList();

    final factors = <FactorContribution>[];
    double score = 0;

    void add(String label, double delta, String detail) {
      score += delta;
      factors.add(FactorContribution(label, delta, detail));
    }

    // 1) 进食-入睡间隔
    if (gapHours != null) {
      if (gapHours < 2) {
        add('睡前 2 小时内进食', 0.5, '最后一餐距入睡 ${_fmtGap(gapHours)}');
      } else if (gapHours < 3) {
        add('睡前 3 小时内进食', 0.25, '最后一餐距入睡 ${_fmtGap(gapHours)}');
      } else {
        add('进食间隔合理', -0.10, '最后一餐距入睡 ${_fmtGap(gapHours)}');
      }
    }

    // 2) 面食（小麦）——联合交互：面食 × 间隔短
    final wheatEvening = evening.any(
        (m) => FoodTypeFeatureMapper.map(m.effectiveFoodName).isWheat);
    final wheatAny = meals.any(
        (m) => FoodTypeFeatureMapper.map(m.effectiveFoodName).isWheat);
    if (wheatEvening && gapHours != null && gapHours < 3) {
      add('晚餐面食 + 进食间隔短', 0.35, '小麦主食且距入睡较近，夜间血糖波动风险');
    } else if (wheatEvening) {
      add('晚餐面食（小麦）', 0.15, '小麦碳水比例较高的晚餐');
    } else if (wheatAny) {
      factors.add(const FactorContribution('白天面食', 0, '白天摄入小麦，对夜间影响相对小'));
    }

    // 3) 含糖
    final sugaryAny = meals.any(
        (m) => FoodTypeFeatureMapper.map(m.effectiveFoodName).isSugary);
    if (sugaryAny) {
      add('含糖零食/甜食', 0.30, '血糖波动可能增加夜间觉醒');
    }

    // 4) 睡前液体
    final liquidLate = lastMeal != null &&
        FoodTypeFeatureMapper.map(lastMeal.effectiveFoodName).isLiquid &&
        (gapHours ?? 99) < 1.5;
    if (liquidLate) {
      add('睡前液体摄入', 0.20, '可能增加夜间排尿或饥饿性醒来');
    }

    // 5) 易胀气 × 低月龄
    final gassyAny = meals.any(
        (m) => FoodTypeFeatureMapper.map(m.effectiveFoodName).isGassy);
    if (gassyAny && months < 12) {
      add('易胀气食物（低月龄）', 0.30, '$months 月龄对豆类/十字花科更敏感');
    } else if (gassyAny) {
      add('易胀气食物', 0.10, '豆类/十字花科等食物');
    }

    // 6) 致敏食物
    final allergenAny = meals.any(
        (m) => FoodTypeFeatureMapper.map(m.effectiveFoodName).isAllergen);
    if (allergenAny && months < 12) {
      add('常见致敏食物（低月龄）', 0.20, '新引入食材建议观察 2~3 天');
    }

    // 7) 餐后反应
    final badEffects = meals
        .where((m) =>
            m.afterEffect != null &&
            m.afterEffect!.isNotEmpty &&
            m.afterEffect != '无异常')
        .toList();
    if (badEffects.isNotEmpty) {
      add('餐后不适（${badEffects.first.afterEffect}）', 0.45,
          '进食后出现 ${badEffects.first.afterEffect}，与夜间不适高度相关');
    }

    // 8) 晚餐份量
    final bigEvening = evening.any((m) => m.portion == '偏多');
    if (bigEvening) {
      add('晚餐份量偏多', 0.15, '过量进食增加消化负担');
    }

    // 9) 白天活动
    if (latest.daytimeActivity == '很少') {
      add('白天活动很少', 0.20, '活动不足可能降低夜间睡眠压力');
    } else if (latest.daytimeActivity == '充足') {
      add('白天活动充足', -0.15, '有助于夜间进入深睡');
    }

    // 10) 入睡耗时
    final latency = latest.sleepLatencyMinutes ?? 0;
    if (latency > 30) {
      add('入睡耗时偏长', 0.25, '入睡耗时 $latency 分钟');
    }

    // 11) 健康事件
    final health = latest.healthNote?.trim() ?? '';
    if (health.isNotEmpty) {
      add('健康事件：$health', 0.50, '出牙/疫苗/生病等会显著影响夜间睡眠');
    }

    // 12) 节律稳定性（近 3 次入睡时间波动）
    final variance = _bedtimeVarianceMinutes(recent);
    if (variance <= 30) {
      add('作息规律', -0.20, '近 3 次入睡时间波动 ≤30 分钟');
    } else if (variance >= 90) {
      add('入睡时间波动大', 0.25, '近 3 次入睡时间波动约 ${variance.round()} 分钟');
    }

    // 综合：基线 + 近期回归 + 当日因素
    final predictedWakings =
        (base + (avgWakings - base) * 0.6 + score * 1.5).round().clamp(0, 8);
    final probability =
        (0.15 + avgWakings * 0.22 + score * 0.30).clamp(0.05, 0.95);

    final cryBase = (latest.cryingNote?.isNotEmpty == true ? 0.40 : 0.0) +
        score * 0.40 +
        (predictedWakings >= 3 ? 0.25 : 0.0) +
        (badEffects.isNotEmpty ? 0.20 : 0.0);
    final cryLevel = cryBase >= 0.70
        ? '高'
        : cryBase >= 0.35
            ? '中'
            : '低';

    var confidence = (sleepSamples / 7).clamp(0.0, 1.0) * 0.6 +
        (mealSamples / 10).clamp(0.0, 1.0) * 0.4;
    if (sleepSamples < 2) confidence *= 0.6;
    if (meals.isEmpty) confidence *= 0.7;
    confidence = confidence.clamp(0.05, 1.0);

    final sortedFactors = [...factors]
      ..sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
    final topFactors = sortedFactors.take(5).toList();

    return JointPrediction(
      predictedWakings: predictedWakings,
      wakeProbability: probability,
      cryRiskLevel: cryLevel,
      factors: topFactors,
      confidence: confidence,
      sleepSamples: sleepSamples,
      mealSamples: mealSamples,
      summary: _buildSummary(
        predictedWakings: predictedWakings,
        probability: probability,
        cryLevel: cryLevel,
        sleepSamples: sleepSamples,
        hasMeals: meals.isNotEmpty,
        topFactors: topFactors,
      ),
      generatedAt: reference,
    );
  }

  static double _baseWakings(int months) {
    if (months < 6) return 2.6;
    if (months < 12) return 1.9;
    if (months < 24) return 1.3;
    return 0.8;
  }

  /// 入睡时间波动（分钟），按夜间归一化避免跨 0 点误差。
  static double _bedtimeVarianceMinutes(List<SleepRecord> recent) {
    if (recent.length < 2) return 0;
    final minutes =
        recent.map((r) => _normMinutes(r.bedTime)).toList(growable: false);
    final avg = minutes.reduce((a, b) => a + b) / minutes.length;
    final deviation =
        minutes.map((m) => (m - avg).abs()).reduce((a, b) => a + b) /
            minutes.length;
    return deviation;
  }

  static int _normMinutes(DateTime bed) {
    var m = bed.hour * 60 + bed.minute;
    if (bed.hour < 12) m += 24 * 60;
    return m;
  }

  static String _fmtGap(double hours) => hours < 1
      ? '${(hours * 60).round()} 分钟'
      : '${hours.toStringAsFixed(1)} 小时';

  static String _buildSummary({
    required int predictedWakings,
    required double probability,
    required String cryLevel,
    required int sleepSamples,
    required bool hasMeals,
    required List<FactorContribution> topFactors,
  }) {
    if (sleepSamples < 2) {
      return '记录还少（$sleepSamples 天），今晚预测仅供参考；连续记录 3 天以上会明显更准。';
    }
    final main = topFactors
        .where((f) => f.delta.abs() >= 0.15)
        .take(2)
        .map((f) => f.label)
        .join('、');
    final sb = StringBuffer(
        '预计今晚夜醒约 $predictedWakings 次（概率 ${(probability * 100).round()}%），哭闹风险$cryLevel');
    if (main.isNotEmpty) sb.write('；主要影响因素：$main');
    if (!hasMeals) sb.write('；今天还没有饮食记录，加入晚餐信息后预测会更准');
    sb.write('。');
    return sb.toString();
  }
}