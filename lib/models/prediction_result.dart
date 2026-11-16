import 'dart:convert';

class WakePrediction {
  final String time;
  final String probability;
  final String reason;
  const WakePrediction({required this.time, required this.probability, required this.reason});

  factory WakePrediction.fromJson(Map<String, dynamic> j) => WakePrediction(
        time: j['time']?.toString() ?? '--',
        probability: j['probability']?.toString() ?? '中',
        reason: j['reason']?.toString() ?? '',
      );
}

class CryRiskPeriod {
  final String period;
  final String probability;
  final String reason;
  const CryRiskPeriod({required this.period, required this.probability, required this.reason});

  factory CryRiskPeriod.fromJson(Map<String, dynamic> j) => CryRiskPeriod(
        period: j['period']?.toString() ?? '--',
        probability: j['probability']?.toString() ?? '中',
        reason: j['reason']?.toString() ?? '',
      );
}

/// AI 睡眠预测结果（夜醒时间点 + 哭闹风险时段 + 建议）。
class PredictionResult {
  final List<WakePrediction> wakePredictions;
  final List<CryRiskPeriod> cryRiskPeriods;
  final List<String> advice;
  final String summary;
  final DateTime createdAt;

  const PredictionResult({
    required this.wakePredictions,
    required this.cryRiskPeriods,
    required this.advice,
    required this.summary,
    required this.createdAt,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> j) => PredictionResult(
        wakePredictions: (j['wake_predictions'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(WakePrediction.fromJson)
            .toList(),
        cryRiskPeriods: (j['cry_risk_periods'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CryRiskPeriod.fromJson)
            .toList(),
        advice: (j['advice'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        summary: j['summary']?.toString() ?? '',
        createdAt: DateTime.now(),
      );

  factory PredictionResult.fromRawJson(String raw) =>
      PredictionResult.fromJson(parseLooseJson(raw));

  Map<String, dynamic> toMap() => {
        'wake_predictions': wakePredictions
            .map((e) => {'time': e.time, 'probability': e.probability, 'reason': e.reason})
            .toList(),
        'cry_risk_periods': cryRiskPeriods
            .map((e) => {'period': e.period, 'probability': e.probability, 'reason': e.reason})
            .toList(),
        'advice': advice,
        'summary': summary,
        'created_at': createdAt.toIso8601String(),
      };

  static PredictionResult fromMap(Map<String, dynamic> map) => PredictionResult(
        wakePredictions: (map['wake_predictions'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(WakePrediction.fromJson)
            .toList(),
        cryRiskPeriods: (map['cry_risk_periods'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CryRiskPeriod.fromJson)
            .toList(),
        advice: (map['advice'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        summary: map['summary']?.toString() ?? '',
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  /// 容错解析：支持 ```json 围栏或混有说明文字的输出。
  static Map<String, dynamic> parseLooseJson(String raw) {
    var text = raw.trim();
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
    final m = fence.firstMatch(text);
    if (m != null) text = m.group(1)!.trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) text = text.substring(start, end + 1);
    return Map<String, dynamic>.from(jsonDecode(text) as Map);
  }
}