import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/database/db.dart';
import 'package:usahaku/models/settings_model.dart';

import 'base_controller.dart';

/// Pengaturan: profil bisnis, QRIS, tema, backup/restore.
class SettingsController extends BaseController {
  SettingsModel _settings = SettingsModel();
  SettingsModel get settings => _settings;
  bool _qrExists = false;
  bool get qrExists => _qrExists;

  Future<void> load() async {
    setLoading(true);
    try {
      final db = DB.instance;
      final rows = await db.select(db.businessProfiles).get();
      if (rows.isNotEmpty) {
        _settings = SettingsModel.fromRow(rows.first);
      } else {
        final id = await db.into(db.businessProfiles).insert(BusinessProfilesCompanion.insert());
        _settings = SettingsModel(id: id);
      }
      _qrExists = _settings.qrisImagePath != null && await _fileExists(_settings.qrisImagePath!);
      setError(null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<bool> _fileExists(String path) async => await File(path).exists();

  Future<void> save(SettingsModel s) async {
    final db = DB.instance;
    if (_settings.id == null) {
      await db.into(db.businessProfiles).insert(s.toCompanion());
    } else {
      await (db.update(db.businessProfiles)..where((t) => t.id.equals(_settings.id!))).write(s.toCompanion());
    }
    _settings = s.copyWith(id: _settings.id);
    _qrExists = _settings.qrisImagePath != null && await _fileExists(_settings.qrisImagePath!);
    notifyListeners();
  }

  Future<void> saveQris(String path) async {
    final updated = _settings.copyWith(qrisImagePath: () => path);
    await save(updated);
  }

  Future<void> removeQris() async {
    final updated = _settings.copyWith(qrisImagePath: () => null);
    await save(updated);
  }

  /// Salin database ke file backup di Documents.
  Future<String> backup() async {
    final dbPath = await _dbPath();
    if (!await File(dbPath).exists()) throw Exception('Database tidak ditemukan');
    final docs = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dest = '${docs.path}/usahaku_backup_$stamp.db';
    await File(dbPath).copy(dest);
    return dest;
  }

  /// Pulihkan dari file backup.
  Future<void> restore(String backupPath) async {
    final dbPath = await _dbPath();
    await File(backupPath).copy(dbPath);
    await DB.recreate();
  }

  Future<String> _dbPath() async {
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/usahaku.db';
  }
}
