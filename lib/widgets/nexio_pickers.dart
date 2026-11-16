import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/nexio.dart';

/// Miuix 风格下拉字段：锚定浮层 + 圆角选项面板，不使用 Material Dropdown。
class NexioDropdownField<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final String? helperText;
  final String? errorText;

  const NexioDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.helperText,
    this.errorText,
  });

  @override
  State<NexioDropdownField<T>> createState() => _NexioDropdownFieldState<T>();
}

class _NexioDropdownFieldState<T> extends State<NexioDropdownField<T>> {
  final LayerLink _link = LayerLink();
  VoidCallback? _closeActive;

  Future<void> _open() async {
    final box = context.findRenderObject() as RenderBox?;
    final width = (box?.size.width ?? 240).clamp(160.0, 420.0);
    final offsetY = (box?.size.height ?? 56) + 6;
    final selected = await _showNexioDropdown<T>(
      context: context,
      link: _link,
      width: width,
      offsetY: offsetY,
      items: widget.items,
      itemLabel: widget.itemLabel,
      current: widget.value,
      onCloseReady: (close) => _closeActive = close,
    );
    _closeActive = null;
    if (selected != null && mounted) widget.onChanged(selected);
  }

  @override
  void dispose() {
    _closeActive?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: _link,
          child: Material(
            color: NexioColors.surface,
            shape: NexioShape.squircle(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _open,
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.label,
                              style: NexioType.footnote2.copyWith(
                                  color: hasError
                                      ? NexioColors.error
                                      : NexioColors.textSummary)),
                          const SizedBox(height: 2),
                          Text(
                            widget.value == null
                                ? '请选择'
                                : widget.itemLabel(widget.value as T),
                            style: NexioType.main,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.expand_more,
                        size: 20, color: NexioColors.textAction),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(widget.errorText!,
                style:
                    NexioType.footnote1.copyWith(color: NexioColors.error)),
          )
        else if (widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(widget.helperText!, style: NexioType.footnote1),
          ),
      ],
    );
  }
}

Future<T?> _showNexioDropdown<T>({
  required BuildContext context,
  required LayerLink link,
  required double width,
  required double offsetY,
  required List<T> items,
  required String Function(T) itemLabel,
  T? current,
  ValueChanged<VoidCallback>? onCloseReady,
}) {
  final overlay = Overlay.of(context);
  final completer = Completer<T?>();
  late OverlayEntry entry;
  var closed = false;

  void close(T? value) {
    if (closed) return;
    closed = true;
    entry.remove();
    if (!completer.isCompleted) completer.complete(value);
  }

  entry = OverlayEntry(
    builder: (ctx) => Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => close(null),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.04),
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: link,
                showWhenUnlinked: false,
                offset: Offset(0, offsetY),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _DropdownPanel<T>(
                    width: width,
                    items: items,
                    itemLabel: itemLabel,
                    current: current,
                    onSelected: close,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  onCloseReady?.call(() => close(null));
  return completer.future;
}

class _DropdownPanel<T> extends StatelessWidget {
  final double width;
  final List<T> items;
  final String Function(T) itemLabel;
  final T? current;
  final ValueChanged<T> onSelected;

  const _DropdownPanel({
    required this.width,
    required this.items,
    required this.itemLabel,
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: NexioMotion.dismiss,
      curve: NexioMotion.cubicOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
            offset: Offset(0, -4 * (1 - t)), child: child),
      ),
      child: Material(
        color: NexioColors.surfaceContainer,
        elevation: 10,
        shadowColor: Colors.black26,
        shape: NexioShape.squircle(16),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: width,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                for (final item in items)
                  InkWell(
                    onTap: () => onSelected(item),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: item == current
                          ? NexioColors.tertiaryContainer
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              itemLabel(item),
                              style: item == current
                                  ? NexioType.main.copyWith(
                                      color: NexioColors.primary,
                                      fontWeight: FontWeight.w600)
                                  : NexioType.main.copyWith(
                                      color: NexioColors.textSecondary),
                            ),
                          ),
                          if (item == current)
                            const Icon(Icons.check,
                                size: 18, color: NexioColors.primary),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Miuix 风格时间选择器：双列滚轮（时/分）。
Future<TimeOfDay?> showNexioTimePicker(
  BuildContext context, {
  TimeOfDay? initial,
  String title = '选择时间',
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TimePickerSheet(initial: initial, title: title),
  );
}

class _TimePickerSheet extends StatefulWidget {
  final TimeOfDay? initial;
  final String title;
  const _TimePickerSheet({this.initial, required this.title});

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late int _hour = widget.initial?.hour ?? 21;
  late int _minute = widget.initial?.minute ?? 0;
  late final FixedExtentScrollController _hourCtrl =
      FixedExtentScrollController(initialItem: _hour);
  late final FixedExtentScrollController _minuteCtrl =
      FixedExtentScrollController(initialItem: _minute);

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: max(16, bottom)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(widget.title, style: NexioType.t3),
          ),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Wheel(
                  width: 76,
                  itemCount: 24,
                  labelOf: (i) => i.toString().padLeft(2, '0'),
                  controller: _hourCtrl,
                  onChanged: (i) => setState(() => _hour = i),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('时', style: NexioType.footnote1),
                ),
                const SizedBox(width: 16),
                _Wheel(
                  width: 76,
                  itemCount: 60,
                  labelOf: (i) => i.toString().padLeft(2, '0'),
                  controller: _minuteCtrl,
                  onChanged: (i) => setState(() => _minute = i),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('分', style: NexioType.footnote1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                        context, TimeOfDay(hour: _hour, minute: _minute)),
                    child: const Text('确定'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Miuix 风格日期选择器：年/月/日三列滚轮联动。
Future<DateTime?> showNexioDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String title = '选择日期',
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _DatePickerSheet(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
    ),
  );
}

class _DatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String title;
  const _DatePickerSheet({
    required this.initialDate,
    this.firstDate,
    this.lastDate,
    required this.title,
  });

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late final int _firstYear =
      widget.firstDate?.year ?? DateTime.now().year - 6;
  late final int _lastYear = max(_firstYear, widget.lastDate?.year ?? DateTime.now().year);
  late int _year = widget.initialDate.year.clamp(
      widget.firstDate?.year ?? DateTime.now().year - 6,
      max(widget.firstDate?.year ?? DateTime.now().year - 6,
          widget.lastDate?.year ?? DateTime.now().year));
  late int _month = widget.initialDate.month;
  late int _day = widget.initialDate.day
      .clamp(1, _daysInMonth(_year, widget.initialDate.month));

  late final FixedExtentScrollController _yearCtrl =
      FixedExtentScrollController(initialItem: _year - _firstYear);
  late final FixedExtentScrollController _monthCtrl =
      FixedExtentScrollController(initialItem: _month - 1);
  late FixedExtentScrollController _dayCtrl =
      FixedExtentScrollController(initialItem: _day - 1);

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  void _rebuildDayWheel() {
    final maxDay = _daysInMonth(_year, _month);
    if (_day > maxDay) _day = maxDay;
    final old = _dayCtrl;
    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  DateTime _result() {
    var result = DateTime(_year, _month, _day);
    final first = widget.firstDate;
    final last = widget.lastDate;
    if (first != null &&
        result.isBefore(DateTime(first.year, first.month, first.day))) {
      result = DateTime(first.year, first.month, first.day);
    }
    if (last != null &&
        result.isAfter(DateTime(last.year, last.month, last.day))) {
      result = DateTime(last.year, last.month, last.day);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: max(16, bottom)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(widget.title, style: NexioType.t3),
          ),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Wheel(
                  width: 90,
                  itemCount: _lastYear - _firstYear + 1,
                  labelOf: (i) => '${_firstYear + i}',
                  controller: _yearCtrl,
                  onChanged: (i) => setState(() {
                    _year = _firstYear + i;
                    _rebuildDayWheel();
                  }),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('年', style: NexioType.footnote1),
                ),
                const SizedBox(width: 12),
                _Wheel(
                  width: 62,
                  itemCount: 12,
                  labelOf: (i) => '${i + 1}'.padLeft(2, '0'),
                  controller: _monthCtrl,
                  onChanged: (i) => setState(() {
                    _month = i + 1;
                    _rebuildDayWheel();
                  }),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('月', style: NexioType.footnote1),
                ),
                const SizedBox(width: 12),
                _Wheel(
                  key: ValueKey('day-$_year-$_month'),
                  width: 62,
                  itemCount: _daysInMonth(_year, _month),
                  labelOf: (i) => '${i + 1}'.padLeft(2, '0'),
                  controller: _dayCtrl,
                  onChanged: (i) => _day = i + 1,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('日', style: NexioType.footnote1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _result()),
                    child: const Text('确定'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 单列滚轮：40dp 行高、选中高亮、上下渐隐。
class _Wheel extends StatefulWidget {
  final int itemCount;
  final String Function(int) labelOf;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onChanged;
  final double width;

  const _Wheel({
    super.key,
    required this.itemCount,
    required this.labelOf,
    required this.controller,
    required this.onChanged,
    required this.width,
  });

  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> {
  late int _selected = widget.controller.initialItem;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: 200,
      child: Stack(
        children: [
          Center(
            child: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: NexioColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: widget.controller,
            itemExtent: 40,
            diameterRatio: 1.5,
            perspective: 0.002,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) {
              setState(() => _selected = i);
              widget.onChanged(i);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.itemCount,
              builder: (context, index) {
                final selected = index == _selected;
                return Center(
                  child: Text(
                    widget.labelOf(index),
                    style: selected
                        ? NexioType.main.copyWith(fontWeight: FontWeight.w600)
                        : NexioType.main
                            .copyWith(color: NexioColors.textAction),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 52,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      NexioColors.surfaceContainer,
                      NexioColors.surfaceContainer.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 52,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      NexioColors.surfaceContainer,
                      NexioColors.surfaceContainer.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}