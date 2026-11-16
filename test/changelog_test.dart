import 'package:flutter_test/flutter_test.dart';

import 'package:babytime/core/app_info.dart';
import 'package:babytime/models/changelog.dart';

void main() {
  const json = '''
  {
    "entries": [
      {"version": "1.0.0", "date": "2026-11-14", "items": [{"type": "added", "title": "初始版本"}]},
      {"version": "1.0.1", "date": "2026-11-16", "items": [
        {"type": "新增", "title": "首页今日概览", "detail": "聚合信息", "scope": "首页", "ref": "REQ-7"},
        {"type": "fixed", "title": "数据库升级"},
        {"type": "unknown", "title": "未知类型"}
      ]}
    ]
  }
  ''';

  test('解析并按版本倒序（当前版本在最前）', () {
    final entries = ChangelogParser.parse(json);
    expect(entries.length, 2);
    expect(entries.first.version, '1.0.1');
    expect(entries.last.version, '1.0.0');
  });

  test('类型解析容错与字段解析', () {
    final entries = ChangelogParser.parse(json);
    final items = entries.first.items;
    expect(items[0].type, ChangelogType.added);
    expect(items[1].type, ChangelogType.fixed);
    expect(items[2].type, ChangelogType.changed);
    expect(items[0].scope, '首页');
    expect(items[0].ref, 'REQ-7');
    expect(items[0].detail, '聚合信息');
  });

  test('版本号比较（含多位数与段数差异）', () {
    expect(ChangelogParser.compareVersions('1.0.1', '1.0.0'), greaterThan(0));
    expect(ChangelogParser.compareVersions('1.0.10', '1.0.9'), greaterThan(0));
    expect(ChangelogParser.compareVersions('1.1.0', '1.0.9'), greaterThan(0));
    expect(ChangelogParser.compareVersions('1.0.0', '1.0.0'), 0);
  });

  test('当前版本识别与版本常量一致', () {
    final entries = ChangelogParser.parse(json);
    final current = ChangelogParser.findCurrent(entries, AppInfo.version);
    expect(AppInfo.version, '1.0.1');
    expect(current?.version, '1.0.1');
  });

  test('兜底列表非空且字段缺失容错', () {
    expect(ChangelogParser.fallbackEntries(), isNotEmpty);
    final broken = ChangelogParser.parse(
        '{"entries":[{"version":"","items":[]},'
        '{"version":"1.0.0","date":"bad","items":[{"title":""},{"type":"fixed","title":"ok"}]}]}');
    expect(broken.length, 1);
    expect(broken.first.items.length, 1);
    expect(broken.first.date, DateTime(2000));
  });
}