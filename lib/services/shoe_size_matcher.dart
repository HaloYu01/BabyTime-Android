import '../core/constants.dart';

/// 尺码匹配结果。
class ShoeSizeMatch {
  final ShoeSizeRow row;
  final double requiredInnerCm;
  final bool clampedLow;
  final bool clampedHigh;
  final String? note;

  const ShoeSizeMatch({
    required this.row,
    required this.requiredInnerCm,
    this.clampedLow = false,
    this.clampedHigh = false,
    this.note,
  });

  String get requiredInnerText => requiredInnerCm.toStringAsFixed(1);
  String get rowFootText => row.footLengthCm.toStringAsFixed(1);
  String get rowInnerText => (row.footLengthCm + 1).toStringAsFixed(1);
}

/// 脚长（0.1cm 粒度）→ 童鞋尺码档位匹配。
///
/// 规则：
///  - 输入粒度为 0.1cm；内部用「十分之一厘米」整数运算，避免浮点误差；
///  - 尺码档位沿用对照表的 0.5cm 档（童鞋没有 0.1 档）；
///  - 匹配原则：用「所需内长 = 脚长 + 放量」，选择**内长 ≥ 所需内长的最小档位**
///    （向上取档，避免宝宝脚趾顶鞋）；所需内长恰等于档位内长时包含在该档（闭区间）；
///  - 超出下限/上限时取边界档并给出提示。
class ShoeSizeMatcher {
  static const double minFootLength = 10.0;
  static const double maxFootLength = 20.0;
  static const double step = 0.1;

  static int _tenths(double cm) => (cm * 10).round();

  /// 归整到 0.1cm 并限制在 [10.0, 20.0]。
  static double clampFootLength(double cm) {
    final t = _tenths(cm).clamp(_tenths(minFootLength), _tenths(maxFootLength));
    return t / 10;
  }

  static ShoeSizeMatch recommend({
    required double footLengthCm,
    required double allowanceCm,
  }) {
    final required = _tenths(footLengthCm) + _tenths(allowanceCm);
    final firstRow = shoeSizeTable.first;
    final belowTable =
        _tenths(footLengthCm) < _tenths(firstRow.footLengthCm);

    for (final row in shoeSizeTable) {
      final rowInner = _tenths(row.footLengthCm + 1);
      if (rowInner >= required) {
        if (belowTable && row == firstRow) {
          return ShoeSizeMatch(
            row: row,
            requiredInnerCm: required / 10,
            clampedLow: true,
            note: '脚长低于对照表下限（10.5cm），当前为最小档参考，建议实际试穿确认',
          );
        }
        return ShoeSizeMatch(row: row, requiredInnerCm: required / 10);
      }
    }

    return ShoeSizeMatch(
      row: shoeSizeTable.last,
      requiredInnerCm: required / 10,
      clampedHigh: true,
      note: '所需内长超过对照表上限，建议按实际试穿或选择大童码',
    );
  }
}