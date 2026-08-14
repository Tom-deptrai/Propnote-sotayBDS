import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../services/app_directories.dart';
import 'database_schema.dart';

class AppDatabase {
  final AppDirectories directories;
  final DatabaseFactory factory;

  Database? _database;
  Completer<void>? _maintenance;

  AppDatabase({required this.directories, DatabaseFactory? factory})
    : factory = factory ?? databaseFactory;

  String get path => directories.databasePath;
  Database? get openedDatabase => _database;

  Future<Database> open() async {
    final maintenance = _maintenance;
    if (maintenance != null) await maintenance.future;
    return _open();
  }

  Future<Database> _open() async {
    final current = _database;
    if (current != null && current.isOpen) return current;

    await directories.ensureCreated();
    final database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: DatabaseSchema.version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) => DatabaseSchema.create(db),
        onUpgrade: DatabaseSchema.upgrade,
        onDowngrade: (db, oldVersion, newVersion) {
          throw StateError(
            'Không hỗ trợ hạ schema từ v$oldVersion xuống v$newVersion',
          );
        },
      ),
    );
    _database = database;
    return database;
  }

  Future<void> checkpoint() async {
    final database = await open();
    await database.rawQuery('PRAGMA wal_checkpoint(FULL)');
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    if (database != null && database.isOpen) {
      await database.close();
    }
  }

  Future<void> reopen() async {
    await close();
    await open();
  }

  Future<T> runWhileClosed<T>(Future<T> Function() operation) async {
    while (_maintenance != null) {
      await _maintenance!.future;
    }
    final maintenance = Completer<void>();
    _maintenance = maintenance;
    try {
      final current = await _open();
      await current.rawQuery('PRAGMA wal_checkpoint(FULL)');
      await close();
      return await operation();
    } finally {
      try {
        await _open();
      } finally {
        _maintenance = null;
        maintenance.complete();
      }
    }
  }
}
