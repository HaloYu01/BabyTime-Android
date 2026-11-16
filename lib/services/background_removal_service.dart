import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class RemoveBgException implements Exception {
  final String message;
  const RemoveBgException(this.message);
  @override
  String toString() => message;
}

/// remove.bg 去背景服务：上传图片 -> 返回透明底 PNG。
class BackgroundRemovalService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 90),
  ));

  Future<String> removeBackground({
    required String imagePath,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty) {
      throw const RemoveBgException('请先在「设置」中配置 remove.bg API Key');
    }
    try {
      final form = FormData.fromMap({
        'image_file': await MultipartFile.fromFile(imagePath),
        'size': 'auto',
      });
      final resp = await _dio.post(
        'https://api.remove.bg/v1.0/removebg',
        data: form,
        options: Options(
          headers: {'X-Api-Key': apiKey},
          responseType: ResponseType.bytes,
        ),
      );
      final bytes = resp.data as List<int>;
      if (bytes.isEmpty) throw const RemoveBgException('去背景服务返回空结果');
      final dir = await getApplicationDocumentsDirectory();
      final outPath = p.join(
          dir.path, 'cutout_${DateTime.now().millisecondsSinceEpoch}.png');
      await File(outPath).writeAsBytes(bytes);
      return outPath;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        throw const RemoveBgException('remove.bg API Key 无效，请检查设置');
      }
      if (code == 402) {
        throw const RemoveBgException('remove.bg 额度已用完（免费额度每月 50 张）');
      }
      throw RemoveBgException('去背景失败(${code ?? '无网络'})：${e.message}');
    }
  }
}