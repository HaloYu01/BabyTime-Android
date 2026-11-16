import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';


import '../models/baby_profile.dart';
import '../models/prediction_result.dart';
import '../models/sleep_record.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/settings_store.dart';
import 'settings_provider.dart';

class SleepProvider extends ChangeNotifier {
  AiConfig _config = const AiConfig();
  final AiService _ai = AiService();
  final DatabaseService _db = DatabaseService.instance;

  final List<SleepRecord> records = [];
  PredictionResult? prediction;
  bool loadingPrediction = false;
  String? error;
  bool loaded = false;

  void updateSettings(SettingsProvider settings) {
    _config = settings.aiConfig;
  }

  Future<void> load() async {
    final list = await _db.getSleepRecords();
    records
      ..clear()
      ..addAll(list);
    try {
      prediction = await _db.latestPrediction();
    } catch (_) {
      prediction = null;
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> addRecord(SleepRecord record) async {
    final id = await _db.insertSleepRecord(record);
    records.insert(0, SleepRecord(
      id: id,
      date: record.date,
      bedTime: record.bedTime,
      wakeTime: record.wakeTime,
      nightWakings: record.nightWakings,
      cryingNote: record.cryingNote,
      note: record.note,
    ));
    notifyListeners();
  }

  Future<void> deleteRecord(int id) async {
    await _db.deleteSleepRecord(id);
    records.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  String _fmtRecords() {
    final df = DateFormat('MM-dd');
    return records.take(7).map((r) {
      final crying = (r.cryingNote?.isNotEmpty ?? false)
          ? '，哭闹情况：${r.cryingNote}'
          : '';
      final note = (r.note?.isNotEmpty ?? false) ? '，备注：${r.note}' : '';
      return '- ${df.format(r.date)}：入睡 ${r.bedtimeText()}，最终醒来 '
          '${r.waketimeText()}，夜醒 ${r.nightWakings} 次，'
          '总时长约 ${r.durationText()}$crying$note';
    }).join('\n');
  }

  Future<bool> predict(BabyProfile baby) async {
    if (records.length < 2) {
      error = '请先记录至少 2 天的睡眠情况，AI 才能学习宝宝的作息规律';
      notifyListeners();
      return false;
    }
    loadingPrediction = true;
    error = null;
    notifyListeners();
    try {
      final userPrompt = '''
请根据以下宝宝的作息记录，预测今晚的睡眠情况。

【宝宝信息】${baby.describe()}

【最近作息记录】（按时间倒序）
${_fmtRecords()}

【任务】
1. 预测今晚最可能的夜醒时间点（wake_predictions，1~3 个）
2. 预测哭闹高风险时段（cry_risk_periods，1~3 个）
3. 给出今晚及近期的改善建议（advice，3~5 条，具体可执行）
4. 用一句话总结宝宝的睡眠规律（summary）

【重要】只输出一个 JSON 对象，不要输出任何其他文字，格式如下：
{"wake_predictions":[{"time":"HH:mm","probability":"高|中|低","reason":"简要原因"}],"cry_risk_periods":[{"period":"HH:mm-HH:mm","probability":"高|中|低","reason":"简要原因"}],"advice":["建议1","建议2"],"summary":"一句话总结"}''';
      final raw = await _ai.chat(
        config: _config,
        messages: [
          const {
            'role': 'system',
            'content':
                '你是一位专业的婴幼儿睡眠顾问，擅长通过作息数据分析睡眠规律、预测夜醒和哭闹时间，并给出科学可执行的改善建议。回答始终使用简体中文。',
          },
          {'role': 'user', 'content': userPrompt},
        ],
      );
      prediction = PredictionResult.fromRawJson(raw);
      await _db.savePrediction(prediction!);
      loadingPrediction = false;
      notifyListeners();
      return true;
    } on AiConfigException catch (e) {
      error = e.message;
      loadingPrediction = false;
      notifyListeners();
      return false;
    } catch (e) {
      error = '预测失败，请重试：$e';
      loadingPrediction = false;
      notifyListeners();
      return false;
    }
  }
}