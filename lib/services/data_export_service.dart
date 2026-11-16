import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/app_info.dart';
import 'database_service.dart';

class DataExportResult {
  final String filePath;
  final String json;
  final int sleepCount;
  final int mealCount;
  final int photoCount;
  final int growthCount;
  final int feedingCount;

  const DataExportResult({
    required this.filePath,
    required this.json,
    required this.sleepCount,
    required this.mealCount,
    required this.photoCount,
    required this.growthCount,
    required this.feedingCount,
  });

  int get total =>
      sleepCount + mealCount + photoCount + growthCount + feedingCount;
}

/// 本地数据导出（JSON 文件）。不经过服务器，不上传任何数据。
class DataExportService {
  static Future<DataExportResult> exportAll() async {
    final db = DatabaseService.instance;
    final sleep = await db.getSleepRecords(limit: 10000);
    final meals = await db.getMealRecords(limit: 10000);
    final photos = await db.getPhotoMemories();
    final growth = await db.getGrowthRecords(limit: 10000);
    final feeding = await db.getFeedingRecords(limit: 10000);

    final payload = <String, dynamic>{
      'app': AppInfo.name,
      'version': AppInfo.version,
      'exported_at': DateTime.now().toIso8601String(),
      'sleep_records': sleep.map((r) => r.toMap()).toList(),
      'meal_records': meals.map((r) => r.toMap()).toList(),
      'photo_memories': photos.map((r) => r.toMap()).toList(),
      'growth_records': growth.map((r) => r.toMap()).toList(),
      'feeding_logs': feeding.map((r) => r.toMap()).toList(),
    };

    final json = const JsonEncoder.withIndent('  ').convert(payload);
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path,
        'babytime_export_${DateTime.now().millisecondsSinceEpoch}.json'));
    await file.writeAsString(json);

    return DataExportResult(
      filePath: file.path,
      json: json,
      sleepCount: sleep.length,
      mealCount: meals.length,
      photoCount: photos.length,
      growthCount: growth.length,
      feedingCount: feeding.length,
    );
  }
}