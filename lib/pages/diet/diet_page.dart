import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/nexio.dart';
import '../../models/diet_advice.dart';
import '../../models/meal_record.dart';
import '../../providers/baby_provider.dart';
import '../../providers/diet_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/nexio_glass.dart';
import 'widgets/meal_record_edit_sheet.dart';

class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final diet = context.read<DietProvider>();
      if (!diet.loaded) diet.load();
    });
  }

  Future<void> _ask() async {
    final diet = context.read<DietProvider>();
    final settings = context.read<SettingsProvider>();
    if (!settings.aiConfig.ready) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('请先在「设置」中配置 AI 服务的 API Key')));
      return;
    }
    final ok = await diet.askAdvice();
    if (!mounted) return;
    if (!ok && diet.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(diet.error!)));
    }
  }

  void _openSheet({MealRecord? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MealRecordEditSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diet = context.watch<DietProvider>();
    final baby = context.watch<BabyProvider>();
    final advice = diet.advice;

    return NexioPageScaffold(

      actions: [
        GlassCircleButton(
          icon: Icons.add,
          semanticLabel: '记录饮食',
          onPressed: _openSheet,
        ),
      ],
      children: [
        NexioCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NexioCardHeader(
                icon: Icons.auto_awesome,
                title: 'AI 今日饮食建议 · ${baby.profile.region}',
                trailing: FilledButton(
                  onPressed: diet.loading ? null : _ask,
                  child: diet.loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('生成建议'),
                ),
              ),
              const SizedBox(height: 12),
              if (advice == null)
                Text(
                  diet.records.isEmpty
                      ? '先记录宝宝吃了什么，AI 将结合「${baby.profile.region}」的饮食差异（如面食/米饭对睡眠的影响）给出建议'
                      : '点击「生成建议」，AI 会结合${baby.profile.region}饮食差异与睡眠情况给出今日餐食建议',
                  style: NexioType.body2,
                )
              else ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    NexioTag(text: advice.basisLabel),
                    if (advice.filteredCount > 0)
                      NexioTag(
                        text: '已过滤 ${advice.filteredCount} 条不适龄建议',
                        color: NexioColors.error,
                      ),
                    if (advice.isFallback)
                      NexioTag(
                        text: advice.months < 6 ? '奶类期固定建议' : '内置安全建议',
                        color: NexioColors.textSecondary,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _AdviceBody(advice: advice),
              ],
            ],
          ),
        ),
        NexioSection(
          title: '饮食记录',
          trailing: Text('${diet.records.length} 条',
              style: NexioType.footnote1),
          child: diet.records.isEmpty
              ? const NexioCard(
                  child: EmptyState(
                      icon: Icons.restaurant_outlined, text: '点右上角 + 记录宝宝的饮食'),
                )
              : Column(
                  children: [
                    for (final r in diet.records.take(10))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: _MealTile(
                            record: r, onTap: () => _openSheet(existing: r)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MealTile extends StatelessWidget {
  final MealRecord record;
  final VoidCallback onTap;
  const _MealTile({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hh = record.time.hour.toString().padLeft(2, '0');
    final mm = record.time.minute.toString().padLeft(2, '0');
    final meta = <String>[
      if (record.portion != null && record.portion!.isNotEmpty)
        record.portion!,
      if (record.afterEffect != null &&
          record.afterEffect!.isNotEmpty &&
          record.afterEffect != '无异常')
        record.afterEffect!,
    ];
    return NexioCard(
      radius: 10,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.time.month}/${record.time.day} $hh:$mm · ${record.foodLabel}',
                  style: NexioType.headline2,
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(meta.join(' · '), style: NexioType.footnote2),
                ],
                if (record.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(record.description, style: NexioType.body2),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: NexioColors.textAction),
            onPressed: () =>
                context.read<DietProvider>().deleteRecord(record.id!),
          ),
        ],
      ),
    );
  }
}

class _AdviceBody extends StatelessWidget {
  final DietAdvice advice;
  const _AdviceBody({required this.advice});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (advice.summary.isNotEmpty)
          Text(advice.summary, style: NexioType.main.copyWith(height: 1.5)),
        if (advice.suggestions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('今日餐食建议', style: NexioType.headline2),
          const SizedBox(height: 8),
          for (final s in advice.suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NexioColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        NexioTag(text: s.meal),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(s.food, style: NexioType.headline2)),
                        if (s.minMonth > 0)
                          Text('≥${s.minMonth}月', style: NexioType.footnote2),
                      ],
                    ),
                    if (s.reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(s.reason, style: NexioType.body2),
                    ],
                  ],
                ),
              ),
            ),
        ],
        if (advice.sleepImpact.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('对睡眠的影响', style: NexioType.headline2),
          const SizedBox(height: 6),
          Text(advice.sleepImpact, style: NexioType.body2),
        ],
        if (advice.advice.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('调整建议', style: NexioType.headline2),
          const SizedBox(height: 6),
          for (final a in advice.advice)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: NexioType.body2),
                  Expanded(
                      child:
                          Text(a, style: NexioType.body2.copyWith(height: 1.5))),
                ],
              ),
            ),
        ],
      ],
    );
  }
}