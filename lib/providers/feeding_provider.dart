import 'package:flutter/foundation.dart';

import '../models/feeding_record.dart';
import '../services/database_service.dart';

class FeedingProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  final List<FeedingRecord> records = [];
  bool loaded = false;

  FeedingRecord? get latest => records.isEmpty ? null : records.first;

  Future<void> load() async {
    final list = await _db.getFeedingRecords();
    records
      ..clear()
      ..addAll(list);
    loaded = true;
    notifyListeners();
  }

  Future<void> add(FeedingRecord record) async {
    final id = await _db.insertFeedingRecord(record);
    records.insert(0, FeedingRecord(
      id: id,
      startedAt: record.startedAt,
      endedAt: record.endedAt,
      feedType: record.feedType,
      amountMl: record.amountMl,
      note: record.note,
    ));
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await _db.deleteFeedingRecord(id);
    records.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}