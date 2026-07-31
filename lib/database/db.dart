import 'package:usahaku/database/app_database.dart';

/// Singleton akses database. Controller memakai ini langsung (tanpa repository).
class DB {
  DB._();
  static AppDatabase instance = AppDatabase();

  /// Tutup & buat ulang koneksi (dipakai setelah restore backup).
  static Future<void> recreate() async {
    await instance.close();
    instance = AppDatabase();
  }
}
