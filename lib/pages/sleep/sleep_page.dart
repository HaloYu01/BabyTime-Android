import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/nexio.dart';
import '../../models/prediction_result.dart';
import '../../models/sleep_record.dart';
import '../../providers/baby_provider.dart';
import '../../providers/diet_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sleep_provider.dart';
import '../../services/joint_sleep_predictor.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/nexio_glass.dart';
import 'sleep_record_edit_page.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sleep = context.read<SleepProvider>();
      if (!sleep.loaded) sleep.load();
    });
  }

  Future<void> _predict() async {
    final sleep = context.read<SleepProvider>();
    final baby = context.read<BabyProvider>();
    final settings = context.read<SettingsProvider>();
    if (!settings.aiConfig.ready) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('请先在「设置」中配置 AI 服务的 API Key')));
      return;
    }
    final ok = await sleep.predict(baby.profile);
    if (!mounted) return;
    if (!ok && sleep.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(sleep.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sleep = context.watch<SleepProvider>();
    final baby = context.watch<BabyProvider>();
    final meals = context.watch<DietProvider>().records;
    final prediction = sleep.prediction;
    final joint = JointSleepPredictor.predict(
      sleepRecords: sleep.records,
      mealRecords: meals,
      profile: baby.profile,
    );

    return NexioPageScaffold(
      actions: [
        GlassCircleButton(
          icon: Icons.add,
          semanticLabel: '记录睡眠',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SleepRecordEditPage()),
          ),
        ),
      ],
      children: [
        _ForecastCard(
          joint: joint,
          prediction: prediction,
          loading: sleep.loadingPrediction,
          onAi: _predict,
        ),
        NexioSection(
          title: '作息记录',
          trailing: Text('${sleep.records.length} 条',
              style: NexioType.footnote1),
          child: sleep.records.isEmpty
              ? const NexioCard(
                  child: EmptyState(
                      icon: Icons.bedtime_outlined, text: '点右上角 + 记录第一条作息'),
                )
              : Column(
                  children: [
                    for (final r in sleep.records.take(10))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: _RecordTile(record: r),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// 合并后的单一预测卡：本地联合分析（自动）+ 可选的 AI 深度分析。
class _ForecastCard extends StatelessWidget {
  final JointPrediction joint;
  final PredictionResult? prediction;
  final bool loading;
  final VoidCallback onAi;

  const _ForecastCard({
    required this.joint,
    required this.prediction,
    required this.loading,
    required this.onAi,
  });

  @override
  Widget build(BuildContext context) {
    return NexioCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NexioCardHeader(
            icon: Icons.insights,
            title: '今晚睡眠预测',
            trailing: FilledButton(
              onPressed: loading ? null : onAi,
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('AI 深度分析'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              NexioStat(label: '预计夜醒', value: '${joint.predictedWakings}次'),
              NexioStat(label: '夜醒概率', value: '${joint.probabilityPercent}%'),
              NexioStat(label: '哭闹风险', value: joint.cryRiskLevel),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              NexioTag(
                text: '置信度 ${joint.confidencePercent}%',
                color: joint.confidence >= 0.6
                    ? NexioColors.primary
                    : NexioColors.textSecondary,
              ),
              const Spacer(),
              Text('本地模型', style: NexioType.footnote2),
            ],
          ),
          const SizedBox(height: 8),
          Text(joint.summary, style: NexioType.body2.copyWith(height: 1.5)),
          if (joint.factors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('主要影响因素', style: NexioType.headline2),
            const SizedBox(height: 6),
            for (final f in joint.factors)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        f.deltaText,
                        style: NexioType.footnote1.copyWith(
                          color: f.isNegative
                              ? const Color(0xFF30A46C)
                              : f.delta > 0
                                  ? NexioColors.error
                                  : NexioColors.textAction,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.label,
                              style: NexioType.body2.copyWith(
                                  color: NexioColors.textSecondary,
                                  fontWeight: FontWeight.w500)),
                          if (f.detail.isNotEmpty)
                            Text(f.detail, style: NexioType.footnote2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (prediction != null) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 16, color: NexioColors.primary),
                const SizedBox(width: 6),
                Text('AI 深度分析', style: NexioType.headline2),
              ],
            ),
            const SizedBox(height: 8),
            _PredictionBody(prediction: prediction!),
          ],
          const SizedBox(height: 4),
          Text('本地模型自动计算；「AI 深度分析」需在设置中配置 API Key。',
              style: NexioType.footnote2),
        ],
      ),
    );
  }
}

class _PredictionBody extends StatelessWidget {
  final PredictionResult prediction;
  const _PredictionBody({required this.prediction});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (prediction.summary.isNotEmpty)
          Text(prediction.summary, style: NexioType.main.copyWith(height: 1.5)),
        if (prediction.wakePredictions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('预计夜醒时间点', style: NexioType.headline2),
          const SizedBox(height: 8),
          ...prediction.wakePredictions.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(w.time,
                          style: NexioType.headline2
                              .copyWith(color: NexioColors.primary)),
                    ),
                    const SizedBox(width: 4),
                    ProbabilityChip(probability: w.probability),
                    const SizedBox(width: 10),
                    Expanded(child: Text(w.reason, style: NexioType.body2)),
                  ],
                ),
              )),
        ],
        if (prediction.cryRiskPeriods.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('哭闹高风险时段', style: NexioType.headline2),
          const SizedBox(height: 8),
          ...prediction.cryRiskPeriods.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(c.period,
                          style: NexioType.headline2
                              .copyWith(color: NexioColors.primary)),
                    ),
                    const SizedBox(width: 4),
                    ProbabilityChip(probability: c.probability),
                    const SizedBox(width: 10),
                    Expanded(child: Text(c.reason, style: NexioType.body2)),
                  ],
                ),
              )),
        ],
        if (prediction.advice.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('改善建议', style: NexioType.headline2),
          const SizedBox(height: 8),
          for (final (i, advice) in prediction.advice.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}. ',
                      style: NexioType.body2.copyWith(
                          color: NexioColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                  Expanded(
                      child: Text(advice,
                          style: NexioType.body2.copyWith(height: 1.5))),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  final SleepRecord record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return NexioCard(
      radius: 10,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.date.month}/${record.date.day}  ${record.bedtimeText()} ~ ${record.waketimeText()}（${record.durationText()}）',
                  style: NexioType.headline2,
                ),
                const SizedBox(height: 3),
                Text(
                  '夜醒 ${record.nightWakings} 次'
                  '${record.cryingNote != null && record.cryingNote!.isNotEmpty ? ' · 哭闹：${record.cryingNote}' : ''}',
                  style: NexioType.body2,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: NexioColors.textAction),
            onPressed: () =>
                context.read<SleepProvider>().deleteRecord(record.id!),
          ),
        ],
      ),
    );
  }
}