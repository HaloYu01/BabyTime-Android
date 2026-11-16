import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/nexio.dart';
import '../../models/feeding_record.dart';
import '../../providers/feeding_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/nexio_glass.dart';

class FeedingPage extends StatefulWidget {
  const FeedingPage({super.key});

  @override
  State<FeedingPage> createState() => _FeedingPageState();
}

class _FeedingPageState extends State<FeedingPage> {
  static const _types = ['母乳-左', '母乳-右', '瓶喂'];

  String _type = '母乳-左';
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  final _amountCtrl = TextEditingController();

  bool get _running => _startedAt != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feeding = context.read<FeedingProvider>();
      if (!feeding.loaded) feeding.load();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _startedAt = DateTime.now();
      _elapsed = Duration.zero;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final start = _startedAt;
      if (start == null) return;
      setState(() => _elapsed = DateTime.now().difference(start));
    });
  }

  void _cancel() {
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _startedAt = null;
      _elapsed = Duration.zero;
    });
  }

  Future<void> _stopAndSave() async {
    final start = _startedAt;
    if (start == null) return;
    final now = DateTime.now();
    _ticker?.cancel();
    _ticker = null;
    final amount =
        _type == '瓶喂' ? int.tryParse(_amountCtrl.text.trim()) : null;
    await context.read<FeedingProvider>().add(FeedingRecord(
          startedAt: start,
          endedAt: now,
          feedType: _type,
          amountMl: amount,
        ));
    if (!mounted) return;
    setState(() {
      _startedAt = null;
      _elapsed = Duration.zero;
      _amountCtrl.clear();
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('喂养记录已保存')));
  }

  String get _elapsedText {
    final d = _elapsed;
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '${h.toString().padLeft(2, '0')}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final feeding = context.watch<FeedingProvider>();
    final start = _startedAt;
    final startText = start == null
        ? null
        : '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} 开始';

    return NexioPageScaffold(
      title: '喂养计时器',
      bottomInset: 40,
      leading: GlassCircleButton(
        icon: Icons.arrow_back,
        semanticLabel: '返回',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      children: [
        NexioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NexioCardHeader(
                icon: Icons.timer_outlined,
                title: _running ? '计时中' : '准备开始',
                trailing: startText == null
                    ? null
                    : Text(startText, style: NexioType.footnote1),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(_elapsedText,
                    style: NexioType.t1.copyWith(
                        fontSize: 44, color: NexioColors.primary)),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                children: _types.map((t) {
                  final active = _type == t;
                  return ChoiceChip(
                    label: Text(t),
                    selected: active,
                    shape: NexioShape.pill(),
                    selectedColor: NexioColors.tertiaryContainer,
                    backgroundColor: NexioColors.surface,
                    labelStyle: NexioType.body2.copyWith(
                        color: active
                            ? NexioColors.primary
                            : NexioColors.textSecondary),
                    side: BorderSide.none,
                    onSelected: (_) => setState(() => _type = t),
                  );
                }).toList(),
              ),
              if (_type == '瓶喂') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 4,
                  decoration: const InputDecoration(
                      labelText: '奶量（ml，可选）', counterText: ''),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: _running
                    ? FilledButton.icon(
                        onPressed: _stopAndSave,
                        icon: const Icon(Icons.stop_circle_outlined, size: 18),
                        label: const Text('结束并保存'),
                      )
                    : FilledButton.icon(
                        onPressed: _start,
                        icon: const Icon(Icons.play_circle_outline, size: 18),
                        label: const Text('开始计时'),
                      ),
              ),
              if (_running) ...[
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: _cancel,
                    child: const Text('取消本次计时'),
                  ),
                ),
              ],
            ],
          ),
        ),
        NexioSection(
          title: '最近喂养',
          trailing:
              Text('${feeding.records.length} 条', style: NexioType.footnote1),
          child: feeding.records.isEmpty
              ? const NexioCard(
                  child: EmptyState(
                      icon: Icons.local_drink_outlined,
                      text: '开始一次计时，自动生成喂养记录'),
                )
              : Column(
                  children: [
                    for (final r in feeding.records.take(20))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: _FeedingTile(record: r),
                      ),
                  ],
                ),
        ),
        NexioCard(
          color: NexioColors.surface,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 18, color: NexioColors.textAction),
              const SizedBox(width: 10),
              Expanded(
                child: Text('时长按开始/结束时间计算，切到后台也不会丢失；瓶喂可填写奶量。',
                    style: NexioType.body2.copyWith(height: 1.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedingTile extends StatelessWidget {
  final FeedingRecord record;
  const _FeedingTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      record.startedText,
      if (record.amountMl != null && record.amountMl! > 0)
        '${record.amountMl}ml',
    ].join(' · ');
    return NexioCard(
      radius: 10,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${record.feedType} · ${record.durationText}',
                    style: NexioType.headline2),
                const SizedBox(height: 3),
                Text(meta, style: NexioType.body2),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: NexioColors.textAction),
            onPressed: () =>
                context.read<FeedingProvider>().delete(record.id!),
          ),
        ],
      ),
    );
  }
}