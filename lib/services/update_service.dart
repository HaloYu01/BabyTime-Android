import 'package:dio/dio.dart';

import '../core/app_info.dart';
import '../models/changelog.dart';

enum UpdateStatus {
  /// 有新版本可用
  hasUpdate,

  /// 已是最新版本
  upToDate,

  /// 仓库存在但没有任何 Release / Tag
  noPublicRelease,

  /// 检查失败（网络/限流/仓库不可达）
  error,
}

class UpdateCheckResult {
  final UpdateStatus status;
  final String currentVersion;
  final String? latestVersion;
  final String? releaseUrl;
  final String? notes;
  final DateTime? publishedAt;
  final String? error;

  const UpdateCheckResult({
    required this.status,
    required this.currentVersion,
    this.latestVersion,
    this.releaseUrl,
    this.notes,
    this.publishedAt,
    this.error,
  });
}

class UpdateRepository {
  static const owner = 'HaloYu01';
  static const repo = 'BabyTime-Android';
  static const repoUrl = 'https://github.com/HaloYu01/BabyTime-Android';
  static const releasesUrl = '$repoUrl/releases';
  static const apiBase = 'https://api.github.com/repos/$owner/$repo';
}

/// 基于 GitHub Releases / Tags 的版本检查（只读、手动触发）。
class UpdateService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: const {
      'User-Agent': 'BabyTime-Android',
      'Accept': 'application/vnd.github+json',
    },
    validateStatus: (status) => status != null && status < 500,
  ));

  static Future<UpdateCheckResult> check() async {
    final current = AppInfo.version;
    try {
      final releaseResp =
          await _dio.get('${UpdateRepository.apiBase}/releases/latest');
      final releaseCode = releaseResp.statusCode;
      if (_isRateLimited(releaseCode)) {
        return _error(current, '请求过于频繁（GitHub 限流），请稍后再试');
      }
      if (releaseCode == 200 && releaseResp.data is Map) {
        final map = releaseResp.data as Map;
        final version = normalizeVersion(
            (map['tag_name'] ?? map['name'] ?? '').toString());
        if (version != null) {
          final url = (map['html_url'] ?? '').toString();
          final published =
              DateTime.tryParse((map['published_at'] ?? '').toString());
          final notes = (map['body'] ?? '').toString().trim();
          return _build(
            current: current,
            latest: version,
            url: url.isEmpty ? UpdateRepository.releasesUrl : url,
            publishedAt: published,
            notes: notes.isEmpty ? null : notes,
          );
        }
      }

      // 回退：标签（许多个人仓库只打 tag 不发 Release）
      final tagsResp = await _dio.get('${UpdateRepository.apiBase}/tags');
      final tagsCode = tagsResp.statusCode;
      if (_isRateLimited(tagsCode)) {
        return _error(current, '请求过于频繁（GitHub 限流），请稍后再试');
      }
      if (tagsCode == 200 && tagsResp.data is List) {
        final versions = (tagsResp.data as List)
            .whereType<Map>()
            .map((m) => normalizeVersion((m['name'] ?? '').toString()))
            .whereType<String>()
            .toList();
        final latest = latestOf(versions);
        if (latest != null) {
          return _build(
            current: current,
            latest: latest,
            url: UpdateRepository.releasesUrl,
          );
        }
      }

      return UpdateCheckResult(
        status: UpdateStatus.noPublicRelease,
        currentVersion: current,
        releaseUrl: UpdateRepository.repoUrl,
      );
    } on DioException catch (e) {
      return _error(current, _describe(e));
    } catch (e) {
      return _error(current, '检查失败：$e');
    }
  }

  /// 从 tag / 名称中提取语义化版本：v1.2.0 → 1.2.0；release-2.0 → 2.0.0
  static String? normalizeVersion(String raw) {
    final match = RegExp(r'(\d+)(?:\.(\d+))?(?:\.(\d+))?').firstMatch(raw.trim());
    if (match == null) return null;
    final major = match.group(1)!;
    final minor = match.group(2) ?? '0';
    final patch = match.group(3) ?? '0';
    return '$major.$minor.$patch';
  }

  /// 在版本列表中取最大者（语义化比较）。
  static String? latestOf(List<String> versions) {
    if (versions.isEmpty) return null;
    final sorted = [...versions]..sort(ChangelogParser.compareVersions);
    return sorted.last;
  }

  static bool _isRateLimited(int? code) => code == 403 || code == 429;

  static UpdateCheckResult _build({
    required String current,
    required String latest,
    required String url,
    DateTime? publishedAt,
    String? notes,
  }) {
    final hasUpdate = ChangelogParser.compareVersions(latest, current) > 0;
    return UpdateCheckResult(
      status: hasUpdate ? UpdateStatus.hasUpdate : UpdateStatus.upToDate,
      currentVersion: current,
      latestVersion: latest,
      releaseUrl: url,
      publishedAt: publishedAt,
      notes: notes,
    );
  }

  static UpdateCheckResult _error(String current, String message) =>
      UpdateCheckResult(
        status: UpdateStatus.error,
        currentVersion: current,
        error: message,
      );

  static String _describe(DioException e) {
    final code = e.response?.statusCode;
    if (_isRateLimited(code)) return '请求过于频繁（GitHub 限流），请稍后再试';
    if (code == 404) return '仓库不存在或暂未发布';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return '网络超时，请检查网络后重试';
    }
    if (e.type == DioExceptionType.connectionError) return '无法连接网络';
    return '网络错误（${code ?? e.message}）';
  }
}