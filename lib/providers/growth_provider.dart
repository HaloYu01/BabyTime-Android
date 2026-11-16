import 'package:flutter/foundation.dart';

import '../models/growth_record.dart';
import '../services/database_service.dart';

class GrowthProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  final List<GrowthRecord> records = [];
  bool loaded = false;

  GrowthRecord? get latest => records.isEmpty ? null : records.first;

  Future<void> load() async {
    final list = await _db.getGrowthRecords();
    records
      ..clear()
      ..addAll(list);
    loaded = true;
    notifyListeners();
  }

  Future<void> add(GrowthRecord record) async {
    final id = await _db.insertGrowthRecord(record);
    records.add(GrowthRecord(
      id: id,
      date: record.date,
      heightCm: record.heightCm,
      weightKg: record.weightKg,
      headCm: record.headCm,
      note: record.note,
    ));
    records.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await _db.deleteGrowthRecord(id);
    records.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}