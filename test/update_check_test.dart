import 'package:flutter_test/flutter_test.dart';

import 'package:babytime/services/update_service.dart';

void main() {
  group('版本解析 normalizeVersion', () {
    test('常见 tag 形式归一化', () {
      expect(UpdateService.normalizeVersion('v1.2.0'), '1.2.0');
      expect(UpdateService.normalizeVersion('1.2.0'), '1.2.0');
      expect(UpdateService.normalizeVersion('release-2.0'), '2.0.0');
      expect(UpdateService.normalizeVersion('1.0'), '1.0.0');
      expect(UpdateService.normalizeVersion('v1.0.1-beta'), '1.0.1');
    });

    test('无法解析时返回 null', () {
      expect(UpdateService.normalizeVersion('abc'), isNull);
      expect(UpdateService.normalizeVersion(''), isNull);
      expect(UpdateService.normalizeVersion('v'), isNull);
    });
  });

  group('版本列表取最大 latestOf', () {
    test('语义化最大值（支持多位数）', () {
      expect(UpdateService.latestOf(['1.0.0', '1.0.10', '1.0.9']), '1.0.10');
      expect(UpdateService.latestOf(['0.9.0', '1.0.0']), '1.0.0');
      expect(UpdateService.latestOf(['2.0.0', '1.9.9']), '2.0.0');
    });

    test('空列表返回 null', () {
      expect(UpdateService.latestOf(const []), isNull);
    });
  });
}