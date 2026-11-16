import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/photo_memory.dart';
import '../services/background_removal_service.dart';
import '../services/database_service.dart';
import 'settings_provider.dart';

class GalleryProvider extends ChangeNotifier {
  SettingsProvider? _settings;
  final DatabaseService _db = DatabaseService.instance;
  final BackgroundRemovalService _remover = BackgroundRemovalService();
  final ImagePicker _picker = ImagePicker();

  final List<PhotoMemory> photos = [];
  bool processing = false;
  int processingIndex = -1;
  String? lastError;
  bool loaded = false;

  void updateSettings(SettingsProvider settings) {
    _settings = settings;
  }

  Future<void> load() async {
    final list = await _db.getPhotoMemories();
    photos
      ..clear()
      ..addAll(list);
    loaded = true;
    notifyListeners();
  }

  Future<String?> pickImage({required bool fromCamera}) async {
    try {
      final source =
          fromCamera ? ImageSource.camera : ImageSource.gallery;
      final x = await _picker.pickImage(source: source, imageQuality: 90);
      return x?.path;
    } catch (e) {
      lastError = '获取图片失败：$e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> addPhoto(String path, {String? note}) async {
    final memory = PhotoMemory(
      createdAt: DateTime.now(),
      originalPath: path,
      note: note,
    );
    final id = await _db.insertPhotoMemory(memory);
    photos.insert(0, PhotoMemory(
      id: id,
      createdAt: memory.createdAt,
      originalPath: memory.originalPath,
      note: memory.note,
    ));
    notifyListeners();
    return true;
  }

  /// 对指定记录做去背景处理，成功返回 true。
  Future<bool> cutout(PhotoMemory photo) async {
    final settings = _settings;
    if (settings == null) return false;
    processing = true;
    processingIndex = photo.id ?? -1;
    lastError = null;
    notifyListeners();
    try {
      final outPath = await _remover.removeBackground(
        imagePath: photo.originalPath,
        apiKey: settings.removeBgKey,
      );
      final updated = photo.copyWith(cutoutPath: outPath);
      await _db.updatePhotoMemory(updated);
      final idx = photos.indexWhere((p) => p.id == photo.id);
      if (idx >= 0) photos[idx] = updated;
      processing = false;
      processingIndex = -1;
      notifyListeners();
      return true;
    } on RemoveBgException catch (e) {
      lastError = e.message;
      processing = false;
      processingIndex = -1;
      notifyListeners();
      return false;
    } catch (e) {
      lastError = '处理失败：$e';
      processing = false;
      processingIndex = -1;
      notifyListeners();
      return false;
    }
  }

  Future<void> delete(PhotoMemory photo) async {
    if (photo.id != null) await _db.deletePhotoMemory(photo.id!);
    photos.removeWhere((p) => p.id == photo.id);
    notifyListeners();
  }

  void clearError() {
    lastError = null;
    notifyListeners();
  }
}