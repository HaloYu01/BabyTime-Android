import 'package:flutter/foundation.dart';

import '../services/settings_store.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsStore _store = SettingsStore();

  AiConfig aiConfig = const AiConfig();
  String removeBgKey = '';
  bool loaded = false;

  Future<void> load() async {
    aiConfig = await _store.loadAiConfig();
    removeBgKey = await _store.loadRemoveBgKey();
    loaded = true;
    notifyListeners();
  }

  Future<void> updateAiConfig(AiConfig config) async {
    aiConfig = config;
    await _store.saveAiConfig(config);
    notifyListeners();
  }

  Future<void> updateRemoveBgKey(String key) async {
    removeBgKey = key;
    await _store.saveRemoveBgKey(key);
    notifyListeners();
  }
}