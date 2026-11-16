import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/nexio.dart';
import '../../providers/baby_provider.dart';
import '../../providers/diet_provider.dart';
import '../../providers/sleep_provider.dart';
import '../../services/joint_sleep_predictor.dart';
import '../../services/parenting_tips.dart';
import '../../widgets/nexio_glass.dart';
import '../diet/widgets/meal_record_edit_sheet.dart';
import '../sleep/sleep_record_edit_page.dart';

class HomePage extends StatelessWidget {
  final void Function(int tabIndex) onNavigate;
  const HomePage({super.key, required this.onNavigate});

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _quickRecord(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bedtime_outlined),
              title: const Text('记录睡眠'),
              onTap: () => Navigator.pop(ctx, 'sleep'),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_outlined),
              title: const Text('记录饮食'),
              onTap: () => Navigator.pop(ctx, 'diet'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'sleep') {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SleepRecordEditPage()));
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const MealRecordEditSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final baby = context.watch<BabyProvider>();
    final sleep = context.watch<SleepProvider>();
    final diet = context.watch<DietProvider>();
    final now = DateTime.now();
    final greet = now.hour < 6
        ? '夜深了'
        : now.hour < 12
            ? '早上好'
            : now.hour < 18
                ? '下午好'
                : '晚上好';

    final joint = JointSleepPredictor.predict(
      sleepRecords: sleep.records,
      mealRecords: diet.records,
      profile: baby.profile,
    );
    final todayMeals =
        diet.records.where((m) => _isSameDay(m.time, now)).length;
    final sleepToday = sleep.records.any(
        (r) => _isSameDay(r.date, now) || _isSameDay(r.bedTime, now));
    final tip = ParentingTips.forToday(months: baby.profile.monthsOld);

    return NexioPageScaffold(
      title: '$greet，${baby.profile.name}',
      children: [
        _TodayOverviewCard(
          joint: joint,
          todayMeals: todayMeals,
          sleepToday: sleepToday,
          onNavigate: onNavigate,
          onQuickRecord: () => _quickRecord(context),
        ),
        _TipCard(tip: tip),
      ],
    );
  }
}

/// 今日概览：把“今晚预测 + 今日饮食 + 记录动作”聚合成一屏结论（非功能复制）。
class _TodayOverviewCard extends StatelessWidget {
  final JointPrediction joint;
  final int todayMeals;
  final bool sleepToday;
  final void Function(int tabIndex) onNavigate;
  final VoidCallback onQuickRecord;

  const _TodayOverviewCard({
    required this.joint,
    required this.todayMeals,
    required this.sleepToday,
    required this.onNavigate,
    required this.onQuickRecord,
  });

  @override
  Widget build(BuildContext context) {
    final hasSleep = joint.sleepSamples > 0;
    return NexioCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NexioCardHeader(
            icon: Icons.today_outlined,
            title: '今日概览',
            trailing: NexioTag(
              text: '置信度 ${joint.confidencePercent}%',
              color: joint.confidence >= 0.6
                  ? NexioColors.primary
                  : NexioColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => onNavigate(1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.nightlight_round,
                      size: 20, color: NexioColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sleepToday ? '今晚睡眠（已有记录）' : '今晚睡眠预测',
                            style: NexioType.footnote1),
                        Text(
                          hasSleep
                              ? '预计夜醒 ${joint.predictedWakings} 次 · 概率 ${joint.probabilityPercent}% · 哭闹风险${joint.cryRiskLevel}'
                              : '记录第一晚睡眠，即可获得今晚的预测',
                          style: NexioType.headline2,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: NexioColors.textAction),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
          InkWell(
            onTap: () => onNavigate(2),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_outlined,
                      size: 20, color: NexioColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('今日饮食', style: NexioType.footnote1),
                        Text(
                          todayMeals > 0
                              ? '已记录 $todayMeals 餐'
                              : '还没有记录，顺手记一餐吧',
                          style: NexioType.headline2,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: NexioColors.textAction),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onQuickRecord,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('快速记录'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final ParentingTip tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return NexioCard(
      color: NexioColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NexioColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_outline,
                size: 22, color: NexioColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今日育儿贴士', style: NexioType.footnote1),
                const SizedBox(height: 3),
                Text(tip.title, style: NexioType.headline1),
                const SizedBox(height: 3),
                Text(tip.body, style: NexioType.body2.copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}