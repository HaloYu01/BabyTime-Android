import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/app_info.dart';
import '../core/text_utils.dart';
import 'database_service.dart';

/// 导出数据载荷（尚未落盘）。
class DataExportPayload {
  final String json;
  final String fileName;
  final int sleepCount;
  final int mealCount;
  final int photoCount;
  final int growthCount;
  final int feedingCount;

  const DataExportPayload({
    required this.json,
    required this.fileName,
    required this.sleepCount,
    required this.mealCount,
    required this.photoCount,
    required this.growthCount,
    required this.feedingCount,
  });

  int get total =>
      sleepCount + mealCount + photoCount + growthCount + feedingCount;
}

/// 保存结果（区分成功 / 取消 / 失败）。
class ExportSaveOutcome {
  final bool saved;
  final bool cancelled;
  final String? location;
  final String? error;

  const ExportSaveOutcome({
    required this.saved,
    this.cancelled = false,
    this.location,
    this.error,
  });
}

/// 本地数据导出（JSON 文件）。不经过服务器，不上传任何数据。
class DataExportService {
  static Future<DataExportPayload> create() async {
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

    final now = DateTime.now();
    final fileName = 'babytime_export_${now.year}${twoDigits(now.month)}'
        '${twoDigits(now.day)}_${twoDigits(now.hour)}${twoDigits(now.minute)}'
        '${twoDigits(now.second)}.json';

    return DataExportPayload(
      json: const JsonEncoder.withIndent('  ').convert(payload),
      fileName: fileName,
      sleepCount: sleep.length,
      mealCount: meals.length,
      photoCount: photos.length,
      growthCount: growth.length,
      feedingCount: feeding.length,
    );
  }

  /// 弹出系统保存对话框，让用户选择「下载 / 文档」等公共目录。
  /// 保存后文件可在手机文件管理器中找到。
  static Future<ExportSaveOutcome> saveToUserLocation(
      DataExportPayload payload) async {
    try {
      final uri = await FilePicker.saveFile(
        dialogTitle: '保存导出文件',
        fileName: payload.fileName,
        mimeType: 'application/json',
        bytes: Uint8List.fromList(utf8.encode(payload.json)),
      );
      if (uri == null) {
        return const ExportSaveOutcome(saved: false, cancelled: true);
      }
      return ExportSaveOutcome(saved: true, location: uri.toString());
    } catch (e) {
      return ExportSaveOutcome(saved: false, error: '保存失败：$e');
    }
  }

  /// 兜底：写入应用文档目录（文件管理器不可见，仅供复制/分享使用）。
  static Future<String> saveToAppDocuments(DataExportPayload payload) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, payload.fileName));
    await file.writeAsString(payload.json);
    return file.path;
  }
}