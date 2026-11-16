import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/baby_profile.dart';
import '../services/settings_store.dart';

class BabyProvider extends ChangeNotifier {
  static const _kProfile = 'baby_profile';


  BabyProfile profile = BabyProfile();
  bool loaded = false;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kProfile);
    if (raw != null && raw.isNotEmpty) {
      try {
        profile = BabyProfile.fromJson(SettingsStore.decodeProfile(raw));
      } catch (_) {
        profile = BabyProfile();
      }
    }
    loaded = true;
    notifyListeners();
  }

  void update(BabyProfile p) {
    profile = p;
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kProfile, SettingsStore.encodeProfile(profile.toJson()));
  }
}