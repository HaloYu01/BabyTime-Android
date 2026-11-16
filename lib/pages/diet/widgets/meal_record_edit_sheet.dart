import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/nexio.dart';
import '../../../models/meal_record.dart';
import '../../../providers/diet_provider.dart';
import '../../../widgets/nexio_pickers.dart';

/// 记录/编辑一次饮食的底部弹层。
/// 食物类型由家长自由填写（吃什么不固定），常用/最近类型只作为快捷标签。
class MealRecordEditSheet extends StatefulWidget {
  final MealRecord? existing;
  const MealRecordEditSheet({super.key, this.existing});

  @override
  State<MealRecordEditSheet> createState() => _MealRecordEditSheetState();
}

class _MealRecordEditSheetState extends State<MealRecordEditSheet> {
  static final RegExp _emojiPattern = RegExp(
    r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{200D}]',
    unicode: true,
  );

  late final TextEditingController _typeCtrl;
  late final TextEditingController _descCtrl;
  late DateTime _time;
  String? _portion;
  String? _afterEffect;
  String? _typeError;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _typeCtrl =
        TextEditingController(text: existing?.effectiveFoodName ?? '');
    _descCtrl = TextEditingController(text: existing?.description ?? '');
    _time = existing?.time ?? DateTime.now();
    _portion = existing?.portion;
    _afterEffect = existing?.afterEffect;
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final d = await showNexioDatePicker(
      context,
      initialDate: _time,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    final t = await showNexioTimePicker(
      context,
      initial: TimeOfDay.fromDateTime(_time),
    );
    if (!mounted) return;
    setState(() => _time = DateTime(d.year, d.month, d.day,
        t?.hour ?? _time.hour, t?.minute ?? _time.minute));
  }

  String _clean(String raw) => raw.trim().replaceAll(_emojiPattern, '').trim();

  Future<void> _submit() async {
    final type = _clean(_typeCtrl.text);
    if (type.isEmpty) {
      setState(() => _typeError = '请填写食物类型');
      return;
    }
    if (type.runes.length > 12) {
      setState(() => _typeError = '类型名称不能超过 12 个字符');
      return;
    }
    final record = MealRecord(
      id: widget.existing?.id,
      time: _time,
      foodType: type,
      customFoodName: null,
      portion: _portion,
      afterEffect: _afterEffect,
      description: _descCtrl.text.trim(),
    );
    final diet = context.read<DietProvider>();
    if (_isEditing) {
      await diet.updateRecord(record);
    } else {
      await diet.addRecord(record);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _applyQuickTag(String tag) {
    setState(() {
      _typeCtrl.text = tag;
      _typeCtrl.selection =
          TextSelection.collapsed(offset: _typeCtrl.text.length);
      _typeError = null;
    });
  }

  Widget _chips(List<String> options, String? selected,
      ValueChanged<String?> onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: options.map((o) {
        final active = selected == o;
        return ChoiceChip(
          label: Text(o),
          selected: active,
          shape: NexioShape.pill(),
          selectedColor: NexioColors.tertiaryContainer,
          backgroundColor: NexioColors.surface,
          labelStyle: NexioType.body2.copyWith(
              color: active ? NexioColors.primary : NexioColors.textSecondary),
          side: BorderSide.none,
          onSelected: (_) => onChanged(active ? null : o),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diet = context.watch<DietProvider>();
    final quick = <String>[];
    final seen = <String>{};
    for (final t in [...diet.recentFoodTypes, ...commonFoodTypes]) {
      if (seen.add(t)) quick.add(t);
      if (quick.length >= 10) break;
    }
    final media = MediaQuery.of(context);
    final sheetHeight = math.min(
      media.size.height * 0.7,
      media.size.height - media.viewInsets.bottom - 24,
    );

    return SizedBox(
      height: sheetHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isEditing ? '编辑饮食记录' : '记录一次饮食',
                  style: NexioType.t3),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(
                    '${_time.month}/${_time.day} ${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
                onPressed: _pickTime,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _typeCtrl,
                maxLength: 12,
                onChanged: (_) {
                  if (_typeError != null) setState(() => _typeError = null);
                },
                decoration: InputDecoration(
                  labelText: '食物类型 *',
                  hintText: '如：西红柿鸡蛋面、山药泥',
                  errorText: _typeError,
                  helperText: '自由填写，12 个字符以内',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: quick.map((tag) {
                  final active = _typeCtrl.text.trim() == tag;
                  return ChoiceChip(
                    label: Text(tag),
                    selected: active,
                    shape: NexioShape.pill(),
                    selectedColor: NexioColors.tertiaryContainer,
                    backgroundColor: NexioColors.surface,
                    labelStyle: NexioType.body2.copyWith(
                        color: active
                            ? NexioColors.primary
                            : NexioColors.textSecondary),
                    side: BorderSide.none,
                    onSelected: (_) => _applyQuickTag(tag),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('份量（可选）', style: NexioType.footnote1),
              const SizedBox(height: 6),
              _chips(mealPortions, _portion,
                  (v) => setState(() => _portion = v)),
              const SizedBox(height: 12),
              Text('餐后反应（可选）', style: NexioType.footnote1),
              const SizedBox(height: 6),
              _chips(mealAfterEffects, _afterEffect,
                  (v) => setState(() => _afterEffect = v)),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    hintText: '描述（如：晚餐吃了一小碗西红柿鸡蛋面）'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(_isEditing ? '保存修改' : '保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}