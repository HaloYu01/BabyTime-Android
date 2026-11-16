import 'package:dio/dio.dart';

import 'settings_store.dart';

class AiConfigException implements Exception {
  final String message;
  const AiConfigException(this.message);
  @override
  String toString() => message;
}

class AiService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
  ));

  /// OpenAI 兼容 Chat Completions 调用，兼容智谱 GLM / DeepSeek / 通义千问 / Kimi 等。
  Future<String> chat({
    required AiConfig config,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
  }) async {
    if (!config.ready) {
      throw const AiConfigException('请先在「设置」中配置 AI 服务（API Key 与模型）');
    }
    final url = '${config.effectiveBaseUrl}/chat/completions';
    try {
      final resp = await _dio.post(
        url,
        options: Options(headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': config.effectiveModel,
          'messages': messages,
          'temperature': temperature,
        },
      );
      final data = resp.data;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw const AiConfigException('AI 返回内容为空，请检查模型名称是否正确');
      }
      final message = choices.first['message'];
      return message['content']?.toString() ?? '';
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = e.response?.data is Map
          ? ((e.response!.data as Map)['error']?['message']?.toString() ??
              e.message)
          : e.message;
      if (code == 401) {
        throw const AiConfigException('API Key 无效或已过期，请检查设置');
      }
      throw AiConfigException('AI 请求失败(${code ?? '无网络'})：$msg');
    }
  }
}