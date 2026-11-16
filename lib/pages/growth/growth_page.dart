import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/nexio.dart';
import '../../models/growth_record.dart';
import '../../providers/growth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/nexio_glass.dart';
import '../../widgets/nexio_pickers.dart';

class GrowthPage extends StatefulWidget {
  const GrowthPage({super.key});

  @override
  State<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<GrowthPage> {
  int _metric = 0; // 0 身高 1 体重 2 头围

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final growth = context.read<GrowthProvider>();
      if (!growth.loaded) growth.load();
    });
  }

  String get _metricUnit => _metric == 1 ? 'kg' : 'cm';
  String get _metricName =>
      _metric == 0 ? '身高' : _metric == 1 ? '体重' : '头围';

  double? _valueOf(GrowthRecord r) =>
      _metric == 0 ? r.heightCm : _metric == 1 ? r.weightKg : r.headCm;

  String _fmt(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);

  void _openSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _GrowthEditSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final growth = context.watch<GrowthProvider>();
    final records = growth.records;
    final series = records.reversed.map(_valueOf).toList(growable: false);
    final latest = records.isEmpty ? null : _valueOf(records.first);
    final first = records.isEmpty ? null : _valueOf(records.last);
    final delta = (latest != null && first != null && records.length > 1)
        ? latest - first
        : null;

    return NexioPageScaffold(
      title: '成长记录',
      bottomInset: 40,
      leading: GlassCircleButton(
        icon: Icons.arrow_back,
        semanticLabel: '返回',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        GlassCircleButton(
          icon: Icons.add,
          semanticLabel: '录入成长数据',
          onPressed: _openSheet,
        ),
      ],
      children: [
        NexioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NexioCardHeader(
                  icon: Icons.trending_up, title: '生长曲线'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['身高', '体重', '头围'].asMap().entries.map((e) {
                  final active = _metric == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: active,
                    shape: NexioShape.pill(),
                    selectedColor: NexioColors.tertiaryContainer,
                    backgroundColor: NexioColors.surface,
                    labelStyle: NexioType.body2.copyWith(
                        color: active
                            ? NexioColors.primary
                            : NexioColors.textSecondary),
                    side: BorderSide.none,
                    onSelected: (_) => setState(() => _metric = e.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              if (series.whereType<double>().length < 2)
                const EmptyState(
                    icon: Icons.show_chart, text: '记录 2 次以上后显示趋势曲线')
              else
                _GrowthChart(values: series, unit: _metricUnit),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  NexioStat(
                      label: '最新$_metricName',
                      value: latest == null
                          ? '--'
                          : '${_fmt(latest)}$_metricUnit'),
                  NexioStat(
                      label: '累计变化',
                      value: delta == null
                          ? '--'
                          : '${delta >= 0 ? '+' : ''}${_fmt(delta)}$_metricUnit'),
                  NexioStat(
                      label: '记录次数', value: '${records.length}次'),
                ],
              ),
            ],
          ),
        ),
        NexioSection(
          title: '历史记录',
          trailing: Text('${records.length} 条', style: NexioType.footnote1),
          child: records.isEmpty
              ? const NexioCard(
                  child: EmptyState(
                      icon: Icons.monitor_weight_outlined,
                      text: '点右上角 + 录入第一次成长数据'),
                )
              : Column(
                  children: [
                    for (final r in records)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: _GrowthTile(record: r),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _GrowthTile extends StatelessWidget {
  final GrowthRecord record;
  const _GrowthTile({required this.record});

  @override
  Widget build(BuildContext context) {
    String fmt(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
    final parts = <String>[
      '身高 ${fmt(record.heightCm)}cm',
      '体重 ${fmt(record.weightKg)}kg',
      if (record.headCm != null) '头围 ${fmt(record.headCm!)}cm',
    ];
    return NexioCard(
      radius: 10,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.dateText, style: NexioType.headline2),
                const SizedBox(height: 3),
                Text(parts.join(' · '), style: NexioType.body2),
                if (record.note != null && record.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(record.note!, style: NexioType.footnote2),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: NexioColors.textAction),
            onPressed: () =>
                context.read<GrowthProvider>().delete(record.id!),
          ),
        ],
      ),
    );
  }
}

class _GrowthChart extends StatelessWidget {
  final List<double?> values;
  final String unit;
  const _GrowthChart({required this.values, required this.unit});

  @override
  Widget build(BuildContext context) {
    final points = values.whereType<double>().toList(growable: false);
    return SizedBox(
      height: 150,
      child: CustomPaint(
        size: Size.infinite,
        painter: _ChartPainter(points: points, unit: unit),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> points;
  final String unit;
  _ChartPainter({required this.points, required this.unit});

  @override
  void paint(Canvas canvas, Size size) {
    const left = 6.0;
    const right = 46.0;
    const top = 14.0;
    const bottom = 10.0;
    final plot = Rect.fromLTRB(
        left, top, math.max(left + 1, size.width - right), size.height - bottom);

    final grid = Paint()
      ..color = NexioColors.divider
      ..strokeWidth = 0.75;
    for (var i = 0; i <= 2; i++) {
      final y = plot.top + plot.height * i / 2;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }

    final minV = points.reduce(math.min);
    final maxV = points.reduce(math.max);
    final range = (maxV - minV).abs() < 0.1 ? 1.0 : (maxV - minV);

    final spots = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? plot.left + plot.width / 2
          : plot.left + plot.width * i / (points.length - 1);
      final y = plot.bottom - (points[i] - minV) / range * plot.height;
      spots.add(Offset(x, y));
    }

    final line = Paint()
      ..color = NexioColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(spots.first.dx, spots.first.dy);
    for (final s in spots.skip(1)) {
      path.lineTo(s.dx, s.dy);
    }
    canvas.drawPath(path, line);

    final dot = Paint()..color = NexioColors.primary;
    for (final s in spots) {
      canvas.drawCircle(s, 3, dot);
    }

    final label = TextPainter(
      text: TextSpan(
        text: '${points.last.toStringAsFixed(1)}$unit',
        style: NexioType.footnote1.copyWith(
            color: NexioColors.primary, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var labelX = spots.last.dx + 6;
    if (labelX + label.width > size.width) {
      labelX = spots.last.dx - label.width - 6;
    }
    label.paint(
      canvas,
      Offset(labelX, (spots.last.dy - label.height / 2).clamp(0, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.unit != unit;
}

class _GrowthEditSheet extends StatefulWidget {
  const _GrowthEditSheet();

  @override
  State<_GrowthEditSheet> createState() => _GrowthEditSheetState();
}

class _GrowthEditSheetState extends State<_GrowthEditSheet> {
  DateTime _date = DateTime.now();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _headCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _error;

  static final _decimalFilter =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _headCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showNexioDatePicker(
      context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 6)),
      lastDate: DateTime.now(),
      title: '选择测量日期',
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final height = double.tryParse(_heightCtrl.text.trim());
    final weight = double.tryParse(_weightCtrl.text.trim());
    final head = double.tryParse(_headCtrl.text.trim());
    if (height == null || height <= 0 || weight == null || weight <= 0) {
      setState(() => _error = '请填写有效的身高与体重');
      return;
    }
    await context.read<GrowthProvider>().add(GrowthRecord(
          date: _date,
          heightCm: height,
          weightKg: weight,
          headCm: head != null && head > 0 ? head : null,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('录入成长数据', style: NexioType.t3),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(
                  '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
              onPressed: _pickDate,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [_decimalFilter],
                    decoration:
                        const InputDecoration(labelText: '身高（cm）*'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [_decimalFilter],
                    decoration:
                        const InputDecoration(labelText: '体重（kg）*'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _headCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_decimalFilter],
              decoration: const InputDecoration(
                  labelText: '头围（cm，可选）'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                  labelText: '备注（可选）', hintText: '如：6 月龄体检'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: NexioType.footnote1
                      .copyWith(color: NexioColors.error)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _save, child: const Text('保存记录')),
            ),
          ],
        ),
      ),
    );
  }
}