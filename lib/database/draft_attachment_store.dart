import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Local draft media (camera captures before server upload).
/// SQLite is the source of truth for what exists; files live on disk under
/// [draftSubDir] or legacy timestamp-named files in the app storage root.
class DraftAttachmentRow {
  final int id;
  final String localPath;
  final String kind;
  final String status;
  final int createdAtMs;
  final String? remoteUrl;
  final String? lastError;

  const DraftAttachmentRow({
    required this.id,
    required this.localPath,
    required this.kind,
    required this.status,
    required this.createdAtMs,
    this.remoteUrl,
    this.lastError,
  });

  factory DraftAttachmentRow.fromMap(Map<String, Object?> map) {
    return DraftAttachmentRow(
      id: map['id'] as int,
      localPath: map['local_path'] as String,
      kind: map['kind'] as String,
      status: map['status'] as String,
      createdAtMs: map['created_at_ms'] as int,
      remoteUrl: map['remote_url'] as String?,
      lastError: map['last_error'] as String?,
    );
  }
}

class DraftAttachmentStore {
  DraftAttachmentStore._();
  static final DraftAttachmentStore instance = DraftAttachmentStore._();

  static const _dbName = 'patrol_draft_attachments.db';
  static const _dbVersion = 1;
  static const _prefsMigrationKey = 'draft_attachments_legacy_import_v2';

  /// Subfolder for new captures (avoids scanning unrelated files in storage root).
  static const draftSubDir = 'patrol_draft_media';

  static const table = 'draft_attachments';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    return _initDb();
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE $table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  local_path TEXT NOT NULL UNIQUE,
  kind TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at_ms INTEGER NOT NULL,
  remote_url TEXT,
  last_error TEXT
)
''');
      },
    );
    await _importLegacyLooseCapturesOnce(_db!);
    return _db!;
  }

  /// Same base directory historically used by [CaptureImagesScreen].
  Future<Directory> appMediaRoot() async {
    if (Platform.isAndroid) {
      return getExternalStorageDirectory().then((v) => v!);
    }
    return getApplicationDocumentsDirectory();
  }

  Future<Directory> draftMediaDirectory() async {
    final base = await appMediaRoot();
    final d = Directory(p.join(base.path, draftSubDir));
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return d;
  }

  bool _looksLikeDraftTimestampFile(String path) {
    final name = p.basename(path).toLowerCase();
    return RegExp(r'^\d+\.(jpe?g|mp4|mov|m4v)$').hasMatch(name);
  }

  /// One-time: register legacy timestamp-named files already in the app root.
  Future<void> _importLegacyLooseCapturesOnce(Database db) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsMigrationKey) == true) return;

    final base = await appMediaRoot();
    final draftDirPath = p.join(base.path, draftSubDir);

    await for (final entity in base.list(followLinks: false)) {
      if (entity is! File) continue;
      final filePath = entity.path;
      if (p.normalize(filePath).startsWith(p.normalize(draftDirPath))) {
        continue;
      }
      if (!_looksLikeDraftTimestampFile(filePath)) continue;

      final existing = await db.query(
        table,
        columns: ['id'],
        where: 'local_path = ?',
        whereArgs: [filePath],
        limit: 1,
      );
      if (existing.isNotEmpty) continue;

      final lower = filePath.toLowerCase();
      final kind = lower.endsWith('.mp4') ||
              lower.endsWith('.mov') ||
              lower.endsWith('.m4v')
          ? 'video'
          : 'image';
      try {
        await db.insert(table, {
          'local_path': filePath,
          'kind': kind,
          'status': 'pending',
          'created_at_ms': DateTime.now().millisecondsSinceEpoch,
          'remote_url': null,
          'last_error': null,
        });
      } on DatabaseException {
        // ignore duplicate
      }
    }

    await prefs.setBool(_prefsMigrationKey, true);
  }

  /// Rows shown in draft UI (excludes removed rows; successful uploads delete rows).
  Future<List<DraftAttachmentRow>> listForUi() async {
    final db = await database;
    final maps = await db.query(
      table,
      where: "status IN ('pending', 'failed', 'uploading')",
      orderBy: 'created_at_ms ASC',
    );
    return maps.map(DraftAttachmentRow.fromMap).toList();
  }

  Future<int> countForUi() async {
    final list = await listForUi();
    return list.length;
  }

  Future<void> insertDraft({
    required String localPath,
    required String kind,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(table, {
      'local_path': localPath,
      'kind': kind,
      'status': 'pending',
      'created_at_ms': now,
      'remote_url': null,
      'last_error': null,
    });
  }

  /// Removes DB row and deletes the file on disk.
  Future<void> deleteDraft(String localPath) async {
    final db = await database;
    await db.delete(
      table,
      where: 'local_path = ?',
      whereArgs: [localPath],
    );
    final f = File(localPath);
    if (await f.exists()) {
      await f.delete();
    }
  }

  Future<void> markUploading(String localPath) async {
    final db = await database;
    await db.update(
      table,
      {'status': 'uploading', 'last_error': null},
      where: 'local_path = ?',
      whereArgs: [localPath],
    );
  }

  Future<void> markFailed(String localPath, String? error) async {
    final db = await database;
    await db.update(
      table,
      {
        'status': 'failed',
        'last_error': error,
      },
      where: 'local_path = ?',
      whereArgs: [localPath],
    );
  }

  Future<void> removeAfterSuccessfulUpload(String localPath) async {
    await deleteDraft(localPath);
  }

  /// Completely resets local draft state to first-use conditions.
  /// - Deletes tracked media files and legacy loose capture files.
  /// - Clears all rows in [table].
  /// - Recreates [draftSubDir] as an empty directory.
  Future<void> resetAllDraftData() async {
    final db = await database;
    final prefs = await SharedPreferences.getInstance();
    final base = await appMediaRoot();
    final draftDir = Directory(p.join(base.path, draftSubDir));

    final rows = await db.query(table, columns: ['local_path']);
    for (final row in rows) {
      final path = row['local_path'] as String?;
      if (path == null || path.isEmpty) continue;
      await tryDeleteFile(path);
    }

    // Remove loose legacy draft captures kept in app root.
    await for (final entity in base.list(followLinks: false)) {
      if (entity is! File) continue;
      if (_looksLikeDraftTimestampFile(entity.path)) {
        await tryDeleteFile(entity.path);
      }
    }

    if (await draftDir.exists()) {
      await draftDir.delete(recursive: true);
    }

    await db.delete(table);
    await draftDir.create(recursive: true);

    // Keep legacy import disabled after reset to preserve clean state.
    await prefs.setBool(_prefsMigrationKey, true);
  }

  static Future<void> tryDeleteFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
  }
}
