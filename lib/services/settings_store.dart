import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class AiConfig {
  final String presetId;
  final String baseUrl;
  final String apiKey;
  final String model;

  const AiConfig({
    this.presetId = 'zhipu',
    this.baseUrl = '',
    this.apiKey = '',
    this.model = '',
  });

  bool get ready => apiKey.isNotEmpty && _effectiveBaseUrl.isNotEmpty && _effectiveModel.isNotEmpty;

  String get _effectiveBaseUrl {
    if (baseUrl.isNotEmpty) return baseUrl;
    for (final p in aiPresets) {
      if (p.id == presetId) return p.baseUrl;
    }
    return '';
  }

  String get _effectiveModel {
    if (model.isNotEmpty) return model;
    for (final p in aiPresets) {
      if (p.id == presetId) return p.defaultModel;
    }
    return '';
  }

  String get effectiveBaseUrl => _effectiveBaseUrl;
  String get effectiveModel => _effectiveModel;
}

class SettingsStore {
  static const _kAiPreset = 'ai_preset';
  static const _kAiBaseUrl = 'ai_base_url';
  static const _kAiApiKey = 'ai_api_key';
  static const _kAiModel = 'ai_model';
  static const _kRemoveBgKey = 'removebg_api_key';

  Future<AiConfig> loadAiConfig() async {
    final sp = await SharedPreferences.getInstance();
    return AiConfig(
      presetId: sp.getString(_kAiPreset) ?? 'zhipu',
      baseUrl: sp.getString(_kAiBaseUrl) ?? '',
      apiKey: sp.getString(_kAiApiKey) ?? '',
      model: sp.getString(_kAiModel) ?? '',
    );
  }

  Future<void> saveAiConfig(AiConfig c) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAiPreset, c.presetId);
    await sp.setString(_kAiBaseUrl, c.baseUrl);
    await sp.setString(_kAiApiKey, c.apiKey);
    await sp.setString(_kAiModel, c.model);
  }

  Future<String> loadRemoveBgKey() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kRemoveBgKey) ?? '';
  }

  Future<void> saveRemoveBgKey(String key) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kRemoveBgKey, key);
  }

  static String encodeProfile(Map<String, dynamic> map) => jsonEncode(map);
  static Map<String, dynamic> decodeProfile(String s) =>
      Map<String, dynamic>.from(jsonDecode(s) as Map);
}