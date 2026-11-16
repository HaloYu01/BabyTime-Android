import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/nexio.dart';
import '../../core/text_utils.dart';
import '../../models/sleep_record.dart';
import '../../providers/sleep_provider.dart';
import '../../widgets/nexio_glass.dart';
import '../../widgets/nexio_pickers.dart';

class SleepRecordEditPage extends StatefulWidget {
  const SleepRecordEditPage({super.key});

  @override
  State<SleepRecordEditPage> createState() => _SleepRecordEditPageState();
}

class _SleepRecordEditPageState extends State<SleepRecordEditPage> {
  DateTime _date = DateTime.now();
  TimeOfDay _bedTime = const TimeOfDay(hour: 21, minute: 0);
  TimeOfDay? _wakeTime;
  int _wakings = 1;
  final _latencyCtrl = TextEditingController();
  final _healthCtrl = TextEditingController();
  final _cryingCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _activity;

  @override
  void dispose() {
    _latencyCtrl.dispose();
    _healthCtrl.dispose();
    _cryingCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showNexioDatePicker(
      context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      title: '选择日期',
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickBedTime() async {
    final t = await showNexioTimePicker(context, initial: _bedTime, title: '入睡时间');
    if (t != null) setState(() => _bedTime = t);
  }

  Future<void> _pickWakeTime() async {
    final t = await showNexioTimePicker(
      context,
      initial: _wakeTime ?? const TimeOfDay(hour: 7, minute: 0),
      title: '醒来时间',
    );
    if (t != null) setState(() => _wakeTime = t);
  }

  Future<void> _save() async {
    final bed = DateTime(
        _date.year, _date.month, _date.day, _bedTime.hour, _bedTime.minute);
    DateTime? wake;
    if (_wakeTime != null) {
      wake = DateTime(_date.year, _date.month, _date.day, _wakeTime!.hour,
          _wakeTime!.minute);
      if (wake.isBefore(bed)) wake = wake.add(const Duration(days: 1));
    }
    final latency = int.tryParse(_latencyCtrl.text.trim());
    final health = _healthCtrl.text.trim();
    await context.read<SleepProvider>().addRecord(SleepRecord(
          date: _date,
          bedTime: bed,
          wakeTime: wake,
          nightWakings: _wakings,
          cryingNote:
              _cryingCtrl.text.trim().isEmpty ? null : _cryingCtrl.text.trim(),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          sleepLatencyMinutes: latency?.clamp(0, 180),
          daytimeActivity: _activity,
          healthNote: health.isEmpty ? null : health,
        ));
    if (mounted) Navigator.pop(context);
  }

  Widget _activityChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: activityLevels.map((a) {
        final active = _activity == a;
        return NexioChoiceChip(
          label: a,
          selected: active,
          onTap: () => setState(() => _activity = active ? null : a),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NexioPageScaffold(
      title: '记录睡眠',

      bottomInset: 40,
      leading: GlassCircleButton(
        icon: Icons.arrow_back,
        semanticLabel: '返回',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      children: [
        NexioCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              NexioFormRow(
                icon: Icons.calendar_today_outlined,
                label: '日期',
                value:
                    '${_date.year}-${twoDigits(_date.month)}-${twoDigits(_date.day)}',
                onTap: _pickDate,
              ),
              const Divider(),
              NexioFormRow(
                icon: Icons.dark_mode_outlined,
                label: '入睡时间',
                value: '${twoDigits(_bedTime.hour)}:${twoDigits(_bedTime.minute)}',
                onTap: _pickBedTime,
              ),
              const Divider(),
              NexioFormRow(
                icon: Icons.wb_twilight_outlined,
                label: '最终醒来',
                value: _wakeTime == null
                    ? '未选（可选）'
                    : '${twoDigits(_wakeTime!.hour)}:${twoDigits(_wakeTime!.minute)}',
                onTap: _pickWakeTime,
              ),
            ],
          ),
        ),
        NexioCard(
          child: Row(
            children: [
              const Icon(Icons.snooze_outlined,
                  size: 22, color: NexioColors.primary),
              const SizedBox(width: 12),
              Text('夜间醒来次数', style: NexioType.headline1),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    setState(() => _wakings = (_wakings - 1).clamp(0, 99)),
                icon: const Icon(Icons.remove_circle_outline,
                    color: NexioColors.textAction),
              ),
              Text('$_wakings', style: NexioType.t3),
              IconButton(
                onPressed: () =>
                    setState(() => _wakings = (_wakings + 1).clamp(0, 99)),
                icon: const Icon(Icons.add_circle_outline,
                    color: NexioColors.primary),
              ),
            ],
          ),
        ),
        NexioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _latencyCtrl,
                keyboardType: TextInputType.number,
                maxLength: 3,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '入睡耗时（分钟，可选）',
                  helperText: '从放到床上到睡着的大致时间',
                ),
              ),
              const SizedBox(height: 4),
              Text('白天活动（可选）', style: NexioType.footnote1),
              const SizedBox(height: 6),
              _activityChips(),
              const SizedBox(height: 12),
              TextField(
                controller: _healthCtrl,
                decoration: const InputDecoration(
                  labelText: '健康事件（可选）',
                  hintText: '如：出牙、疫苗、发烧',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cryingCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: '哭闹情况（如：凌晨3点哭闹约10分钟，喂奶后安抚入睡）',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: '备注（如：白天午睡2小时、疫苗当天情绪差等）',
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: _save, child: const Text('保存记录')),
        ),
      ],
    );
  }
}