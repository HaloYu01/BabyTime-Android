import 'package:flutter/services.dart' show rootBundle;

import '../models/changelog.dart';

/// 加载内置更新日志（assets/changelog.json）；失败时回退兜底列表。
class ChangelogService {
  static const String assetPath = 'assets/changelog.json';

  static Future<List<ChangelogEntry>> load() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final entries = ChangelogParser.parse(raw);
      if (entries.isNotEmpty) return entries;
      return ChangelogParser.fallbackEntries();
    } catch (_) {
      return ChangelogParser.fallbackEntries();
    }
  }
}