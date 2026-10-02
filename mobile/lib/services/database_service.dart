import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  // Return the existing database or initialize it.
  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'tourkare.db');

    _database = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            destination TEXT NOT NULL,
            days INTEGER NOT NULL,
            budget REAL NOT NULL,
            interests TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
      ''');

        await db.execute('''
          CREATE TABLE itineraries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            trip_id INTEGER NOT NULL,
            status TEXT NOT NULL,
            data TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (trip_id)
              REFERENCES trips(id)
              ON DELETE CASCADE
          )
      ''');
      },
    );

    return _database!;
  }

  static Future<int> createTrip({
    required String userId,
    required String destination,
    required int days,
    required double budget,
    required List<String> interests,
  }) async {
    final db = await database;

    return await db.insert('trips', {
      'user_id': userId,
      'destination': destination,
      'days': days,
      'budget': budget,
      'interests': jsonEncode(interests),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<int> saveItinerary({
    required int tripId,
    required Map<String, dynamic> itinerary,
    String status = 'completed',
  }) async {
    final db = await database;

    return await db.insert('itineraries', {
      'trip_id': tripId,
      'status': status,
      'data': jsonEncode(itinerary),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getTrips(String userId) async {
    final db = await database;

    return await db.query(
      'trips',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  static Future<Map<String, dynamic>?> getItinerary(int tripId) async {
    final db = await database;

    final results = await db.query(
      'itineraries',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return jsonDecode(results.first['data'] as String) as Map<String, dynamic>;
  }

  static Future<int> deleteTrip(int tripId) async {
    final db = await database;

    return await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
  }
}
