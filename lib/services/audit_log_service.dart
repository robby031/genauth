import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AuditLogService {
  AuditLogService._();

  static final AuditLogService instance = AuditLogService._();

  Database? _db;

  Future<Database> _database() async {
    if (_db != null) return _db!;

    final basePath = await getDatabasesPath();
    final dbPath = p.join(basePath, 'genauth_audit.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE audit_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action TEXT NOT NULL,
            status TEXT NOT NULL,
            detail TEXT,
            metadata TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );

    return _db!;
  }

  Future<void> log(
    String action, {
    String status = 'success',
    String? detail,
    Map<String, Object?>? metadata,
  }) async {
    try {
      final db = await _database();
      await db.insert('audit_logs', {
        'action': action,
        'status': status,
        'detail': detail,
        'metadata': metadata == null ? null : jsonEncode(metadata),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      // Audit logging must never break the user flow.
    }
  }

  Future<List<Map<String, Object?>>> recent({int limit = 200}) async {
    final db = await _database();
    final rows = await db.query(
      'audit_logs',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map((row) => Map<String, Object?>.from(row)).toList();
  }

  Future<void> clearAll() async {
    final db = await _database();
    await db.delete('audit_logs');
  }
}
