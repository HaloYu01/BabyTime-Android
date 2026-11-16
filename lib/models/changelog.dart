import 'dart:convert';
import 'dart:math' as math;

/// 更新类型（展示与归档用）。
enum ChangelogType {
  added('新增'),
  changed('优化'),
  fixed('修复'),
  removed('移除'),
  security('安全');

  final String label;
  const ChangelogType(this.label);

  static ChangelogType parse(Object? raw) {
    final text = (raw ?? '').toString().toLowerCase();
    if (text.contains('add') || text.contains('new') || text.contains('新增')) {
      return ChangelogType.added;
    }
    if (text.contains('fix') || text.contains('修复')) return ChangelogType.fixed;
    if (text.contains('remov') ||
        text.contains('移除') ||
        text.contains('删除')) {
      return ChangelogType.removed;
    }
    if (text.contains('secur') || text.contains('安全')) {
      return ChangelogType.security;
    }
    return ChangelogType.changed;
  }
}

class ChangelogItem {
  final ChangelogType type;
  final String title;
  final String? detail;
  final String? scope;
  final String? ref;

  const ChangelogItem({
    required this.type,
    required this.title,
    this.detail,
    this.scope,
    this.ref,
  });

  static ChangelogItem? fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? '').toString().trim();
    if (title.isEmpty) return null;
    return ChangelogItem(
      type: ChangelogType.parse(json['type']),
      title: title,
      detail: _nullIfEmpty(json['detail']),
      scope: _nullIfEmpty(json['scope']),
      ref: _nullIfEmpty(json['ref']),
    );
  }

  static String? _nullIfEmpty(Object? raw) {
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }
}

class ChangelogEntry {
  final String version;
  final DateTime date;
  final List<ChangelogItem> items;

  const ChangelogEntry({
    required this.version,
    required this.date,
    required this.items,
  });

  Map<ChangelogType, int> get typeCounts {
    final counts = <ChangelogType, int>{};
    for (final item in items) {
      counts[item.type] = (counts[item.type] ?? 0) + 1;
    }
    return counts;
  }

  static ChangelogEntry? fromJson(Map<String, dynamic> json) {
    final version = (json['version'] ?? '').toString().trim();
    if (version.isEmpty) return null;
    final date =
        DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime(2000);
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(ChangelogItem.fromJson)
            .whereType<ChangelogItem>()
            .toList()
        : <ChangelogItem>[];
    if (items.isEmpty) return null;
    return ChangelogEntry(version: version, date: date, items: items);
  }
}

/// 更新日志解析与排序（纯 Dart，便于单测）。
class ChangelogParser {
  static List<ChangelogEntry> parse(String jsonText) {
    final decoded = jsonDecode(jsonText);
    final rawEntries = decoded is Map<String, dynamic>
        ? decoded['entries']
        : decoded;
    if (rawEntries is! List) return const [];
    final entries = rawEntries
        .whereType<Map<String, dynamic>>()
        .map(ChangelogEntry.fromJson)
        .whereType<ChangelogEntry>()
        .toList();
    return sortEntries(entries);
  }

  /// 版本号倒序（语义化 x.y.z 比较），同版本按日期倒序。
  static List<ChangelogEntry> sortEntries(List<ChangelogEntry> entries) {
    final result = [...entries]
      ..sort((a, b) {
        final byVersion = compareVersions(b.version, a.version);
        if (byVersion != 0) return byVersion;
        return b.date.compareTo(a.date);
      });
    return result;
  }

  static int compareVersions(String a, String b) {
    List<int> parts(String v) => v
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final pa = parts(a);
    final pb = parts(b);
    final len = math.max(pa.length, pb.length);
    for (var i = 0; i < len; i++) {
      final left = i < pa.length ? pa[i] : 0;
      final right = i < pb.length ? pb[i] : 0;
      if (left != right) return left.compareTo(right);
    }
    return 0;
  }

  static ChangelogEntry? findCurrent(
      List<ChangelogEntry> entries, String currentVersion) {
    for (final entry in entries) {
      if (entry.version == currentVersion) return entry;
    }
    return null;
  }

  /// 数据文件缺失/解析失败时的兜底列表（保证页面不空白）。
  static List<ChangelogEntry> fallbackEntries() => [
        ChangelogEntry(
          version: '1.0.1',
          date: DateTime(2026, 11, 16),
          items: const [
            ChangelogItem(
                type: ChangelogType.added,
                title: '首页今日概览、快速记录与育儿贴士'),
            ChangelogItem(type: ChangelogType.changed, title: '食物类型改为自由填写'),
            ChangelogItem(type: ChangelogType.fixed, title: '数据库升级 v2→v3'),
          ],
        ),
        ChangelogEntry(
          version: '1.0.0',
          date: DateTime(2026, 11, 14),
          items: const [
            ChangelogItem(
                type: ChangelogType.added,
                title: 'AI 睡眠预测、地域饮食建议、选鞋助手与照片记录'),
          ],
        ),
      ];
}