import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../models/diet_advice.dart';
import '../models/meal_record.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/diet_safety_validator.dart';
import '../services/settings_store.dart';
import 'baby_provider.dart';
import 'settings_provider.dart';
import 'sleep_provider.dart';

class DietProvider extends ChangeNotifier {
  AiConfig? _config;
  BabyProvider? _baby;
  SleepProvider? _sleep;
  final AiService _ai = AiService();
  final DatabaseService _db = DatabaseService.instance;

  final List<MealRecord> records = [];
  DietAdvice? advice;
  bool loading = false;
  String? error;
  bool loaded = false;

  void updateDeps(
      SettingsProvider settings, BabyProvider baby, SleepProvider sleep) {
    _config = settings.aiConfig;
    _baby = baby;
    _sleep = sleep;
  }

  Future<void> load() async {
    final list = await _db.getMealRecords();
    records
      ..clear()
      ..addAll(list);
    loaded = true;
    notifyListeners();
  }

  Future<void> addRecord(MealRecord record) async {
    final id = await _db.insertMealRecord(record);
    records.insert(
      0,
      MealRecord(
        id: id,
        time: record.time,
        foodType: record.foodType,
        customFoodName: record.customFoodName,
        description: record.description,
      ),
    );
    notifyListeners();
  }

  Future<void> updateRecord(MealRecord record) async {
    await _db.updateMealRecord(record);
    final index = records.indexWhere((r) => r.id == record.id);
    if (index >= 0) records[index] = record;
    notifyListeners();
  }

  Future<void> deleteRecord(int id) async {
    await _db.deleteMealRecord(id);
    records.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  /// 最近使用过的食物类型（含旧「其他」记录的自定义名称），按最近使用顺序。
  List<String> get recentFoodTypes {
    final seen = <String>{};
    final result = <String>[];
    for (final r in records) {
      final name = r.effectiveFoodName.trim();
      if (name.isEmpty || name == '未记录' || name == '其他') continue;
      if (seen.add(name)) result.add(name);
    }
    return result;
  }

  String _fmtMealRecords() {
    final df = DateFormat('MM-dd HH:mm');
    return records.take(10).map((r) {
      final desc = r.description.isNotEmpty ? '（${r.description}）' : '';
      return '- ${df.format(r.time)} ${r.promptLabel}$desc';
    }).join('\n');
  }

  String _fmtSleepSummary() {
    final sp = _sleep;
    if (sp == null || sp.records.isEmpty) return '暂无睡眠记录';
    final df = DateFormat('MM-dd');
    return sp.records.take(5).map((r) {
      return '- ${df.format(r.date)}：入睡 ${r.bedtimeText()}，夜醒 ${r.nightWakings} 次，'
          '总时长 ${r.durationText()}';
    }).join('\n');
  }

  Future<bool> askAdvice() async {
    final config = _config;
    final baby = _baby;
    if (config == null || baby == null) return false;

    final profile = baby.profile;
    final months = profile.monthsOld;
    if (profile.birthday.isAfter(DateTime.now()) || months > 72) {
      error = '宝宝出生日期异常，请先在「设置」中完善真实出生日期';
      notifyListeners();
      return false;
    }
    if (records.isEmpty) {
      error = '请先记录宝宝的饮食情况，AI 才能给出有针对性的建议';
      notifyListeners();
      return false;
    }

    final stage = stageForMonths(months);
    loading = true;
    error = null;
    notifyListeners();
    try {
      // 月龄 < 6：不调用 AI，直接返回奶类为主的固定建议。
      if (months < 6) {
        advice = DietAdvice(
          suggestions: DietSafetyValidator.fallbackSuggestions(months),
          sleepImpact: '纯奶阶段饮食对睡眠影响较小，保证按需喂养即可。',
          advice: const [
            '6 月龄前无需添加辅食，按需喂养母乳或配方奶',
            '睡前避免过度喂养，喂奶后拍嗝再入睡',
          ],
          summary: '该阶段以奶类为主，暂不需要辅食建议',
          months: months,
          stageName: stage.name,
          isFallback: true,
        );
        loading = false;
        notifyListeners();
        return true;
      }

      final region = profile.region;
      final trait = regionDietTraits[region] ?? '饮食特征未知';
      final forbidden = forbiddenKeywordsFor(months).join('、');
      final userPrompt = '''
【最高优先级：月龄安全规则】宝宝当前 $months 个月龄，处于【${stage.name}】（${stage.form}）。
1. 所有建议必须适合 $months 个月宝宝：${stage.guidance}
2. 当前月龄绝对不得推荐：$forbidden
3. today_suggestions 的每一条都必须输出 min_month 字段（整数，该食物建议的最低适用月龄）。
以上规则优先级高于其他一切要求；宁可少给建议，也不得违反。

【任务】结合地区饮食差异，为宝宝给出今日饮食建议，并分析饮食对睡眠质量的影响。

【宝宝信息】${profile.describe()}

【所在地区饮食特征】$region（$trait）

【最近饮食记录】（按时间倒序）
${_fmtMealRecords()}

【最近睡眠概况】
${_fmtSleepSummary()}

【输出要求】
1. today_suggestions：2~4 条（早餐/午餐/晚餐/加餐），结合地域饮食特点说明食物选择原因
2. sleep_impact：分析最近饮食（如面食/米饭、晚餐时间、进食量）对今晚睡眠质量的影响
3. advice：3~5 条可执行的饮食调整建议
4. summary：一句话总结

【重要】只输出一个 JSON 对象，不要输出任何其他文字，格式如下：
{"today_suggestions":[{"meal":"晚餐","food":"具体食物","reason":"简要原因","min_month":$months}],"sleep_impact":"影响分析","advice":["建议1","建议2"],"summary":"一句话总结"}''';

      final raw = await _ai.chat(
        config: config,
        messages: [
          const {
            'role': 'system',
            'content':
                '你是一位精通中国各地饮食文化的婴幼儿营养顾问，严格按宝宝的真实月龄给出建议，熟悉不同地域主食（面食、米饭等）和烹饪习惯对婴幼儿消化与睡眠的影响。回答始终使用简体中文。',
          },
          {'role': 'user', 'content': userPrompt},
        ],
      );

      final parsed = DietAdvice.fromRawJson(
        raw,
        months: months,
        stageName: stage.name,
      );
      final result =
          DietSafetyValidator.validate(parsed.suggestions, months);

      // 全部被拦截（或 AI 未给出条目）：回退内置分阶段安全模板。
      if (result.kept.isEmpty) {
        advice = DietAdvice(
          suggestions: DietSafetyValidator.fallbackSuggestions(months),
          sleepImpact: parsed.sleepImpact,
          advice: parsed.advice.isEmpty
              ? const ['保持清淡饮食，晚餐与睡前间隔 1 小时以上']
              : parsed.advice,
          summary: parsed.summary.isEmpty
              ? 'AI 建议与当前月龄不符，已切换为内置安全建议'
              : '${parsed.summary}（部分建议已按安全规则调整）',
          months: months,
          stageName: stage.name,
          filteredCount: result.removedCount,
          isFallback: true,
        );
      } else {
        advice = DietAdvice(
          suggestions: result.kept,
          sleepImpact: parsed.sleepImpact,
          advice: parsed.advice,
          summary: parsed.summary,
          months: months,
          stageName: stage.name,
          filteredCount: result.removedCount,
        );
      }
      loading = false;
      notifyListeners();
      return true;
    } on AiConfigException catch (e) {
      error = e.message;
      loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      error = '获取建议失败，请重试：$e';
      loading = false;
      notifyListeners();
      return false;
    }
  }
}