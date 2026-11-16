import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/feeding_record.dart';
import '../models/growth_record.dart';
import '../models/meal_record.dart';
import '../models/photo_memory.dart';
import '../models/prediction_result.dart';
import '../models/sleep_record.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get db async {
    final d = _db;
    if (d != null && d.isOpen) return d;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'babytime.db'),
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sleep_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        bed_time TEXT NOT NULL,
        wake_time TEXT,
        night_wakings INTEGER NOT NULL DEFAULT 0,
        crying_note TEXT,
        note TEXT,
        sleep_latency_minutes INTEGER,
        daytime_activity TEXT,
        health_note TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE meal_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        time TEXT NOT NULL,
        food_type TEXT NOT NULL,
        custom_food_name TEXT,
        portion TEXT,
        after_effect TEXT,
        description TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE photo_memories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        original_path TEXT NOT NULL,
        cutout_path TEXT,
        note TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE predictions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        payload TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE growth_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        height_cm REAL NOT NULL,
        weight_kg REAL NOT NULL,
        head_cm REAL,
        note TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE feeding_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        feed_type TEXT NOT NULL,
        amount_ml INTEGER,
        note TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE meal_records ADD COLUMN custom_food_name TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE meal_records ADD COLUMN portion TEXT');
      await db.execute('ALTER TABLE meal_records ADD COLUMN after_effect TEXT');
      await db.execute(
          'ALTER TABLE sleep_records ADD COLUMN sleep_latency_minutes INTEGER');
      await db.execute(
          'ALTER TABLE sleep_records ADD COLUMN daytime_activity TEXT');
      await db.execute('ALTER TABLE sleep_records ADD COLUMN health_note TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS growth_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          height_cm REAL NOT NULL,
          weight_kg REAL NOT NULL,
          head_cm REAL,
          note TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS feeding_logs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          started_at TEXT NOT NULL,
          ended_at TEXT,
          feed_type TEXT NOT NULL,
          amount_ml INTEGER,
          note TEXT
        )
      ''');
    }
  }

  // ---- Sleep records ----
  Future<int> insertSleepRecord(SleepRecord r) async {
    final d = await db;
    return d.insert('sleep_records', r.toMap()..remove('id'));
  }

  Future<int> deleteSleepRecord(int id) async {
    final d = await db;
    return d.delete('sleep_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SleepRecord>> getSleepRecords({int limit = 60}) async {
    final d = await db;
    final rows = await d.query('sleep_records',
        orderBy: 'bed_time DESC', limit: limit);
    return rows.map(SleepRecord.fromMap).toList();
  }

  // ---- Meal records ----
  Future<int> insertMealRecord(MealRecord r) async {
    final d = await db;
    return d.insert('meal_records', r.toMap()..remove('id'));
  }

  Future<void> updateMealRecord(MealRecord r) async {
    final d = await db;
    await d.update('meal_records', r.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [r.id]);
  }

  Future<int> deleteMealRecord(int id) async {
    final d = await db;
    return d.delete('meal_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MealRecord>> getMealRecords({int limit = 60}) async {
    final d = await db;
    final rows =
        await d.query('meal_records', orderBy: 'time DESC', limit: limit);
    return rows.map(MealRecord.fromMap).toList();
  }

  // ---- Photo memories ----
  Future<int> insertPhotoMemory(PhotoMemory r) async {
    final d = await db;
    return d.insert('photo_memories', r.toMap()..remove('id'));
  }

  Future<void> updatePhotoMemory(PhotoMemory r) async {
    final d = await db;
    await d.update('photo_memories', r.toMap(),
        where: 'id = ?', whereArgs: [r.id]);
  }

  Future<int> deletePhotoMemory(int id) async {
    final d = await db;
    return d.delete('photo_memories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PhotoMemory>> getPhotoMemories() async {
    final d = await db;
    final rows =
        await d.query('photo_memories', orderBy: 'created_at DESC', limit: 200);
    return rows.map(PhotoMemory.fromMap).toList();
  }

  // ---- Prediction cache ----
  Future<void> savePrediction(PredictionResult result) async {
    final d = await db;
    final map = result.toMap();
    await d.insert('predictions', {
      'created_at': result.createdAt.toIso8601String(),
      'payload': predictionToJson(map),
    });
    // 只保留最近一条
    final rows = await d.query('predictions', orderBy: 'id DESC');
    if (rows.length > 1) {
      for (final row in rows.skip(1)) {
        await d.delete('predictions',
            where: 'id = ?', whereArgs: [row['id']]);
      }
    }
  }

  Future<PredictionResult?> latestPrediction() async {
    final d = await db;
    final rows = await d.query('predictions', orderBy: 'id DESC', limit: 1);
    if (rows.isEmpty) return null;
    return PredictionResult.fromMap(predictionFromJson(rows.first['payload'] as String));
  }

  // ---- Growth records ----
  Future<int> insertGrowthRecord(GrowthRecord r) async {
    final d = await db;
    return d.insert('growth_records', r.toMap()..remove('id'));
  }

  Future<int> deleteGrowthRecord(int id) async {
    final d = await db;
    return d.delete('growth_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<GrowthRecord>> getGrowthRecords({int limit = 200}) async {
    final d = await db;
    final rows =
        await d.query('growth_records', orderBy: 'date DESC', limit: limit);
    return rows.map(GrowthRecord.fromMap).toList();
  }

  // ---- Feeding logs ----
  Future<int> insertFeedingRecord(FeedingRecord r) async {
    final d = await db;
    return d.insert('feeding_logs', r.toMap()..remove('id'));
  }

  Future<int> deleteFeedingRecord(int id) async {
    final d = await db;
    return d.delete('feeding_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FeedingRecord>> getFeedingRecords({int limit = 200}) async {
    final d = await db;
    final rows = await d.query('feeding_logs',
        orderBy: 'started_at DESC', limit: limit);
    return rows.map(FeedingRecord.fromMap).toList();
  }

  String predictionToJson(Map<String, dynamic> map) => jsonEncode(map);

  Map<String, dynamic> predictionFromJson(String s) =>
      Map<String, dynamic>.from(jsonDecode(s) as Map);
}