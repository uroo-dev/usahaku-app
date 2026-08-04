import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:usahaku/database/app_database.dart';

/// Test migrasi database & seeding default.
///
/// Memastikan:
/// 1. Install baru (schema 3) membuat kategori/satuan/profil default.
/// 2. Upgrade dari schema v2 -> v3 (commit print 77fcf92) TIDAK merusak data
///    lama dan menambahkan kolom printer dengan nilai default.
/// 3. Sisa tabel migrasi lama yang gagal ikut dibersihkan.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('usahaku_db_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('fresh install: kategori, satuan, profil bisnis ter-seed', () async {
    final file = File('${tempDir.path}/fresh.db');
    final db = AppDatabase(NativeDatabase(file));
    try {
      final cats = await db.select(db.categories).get();
      expect(cats.length, greaterThanOrEqualTo(6));
      expect(cats.map((c) => c.name), containsAll(['Makanan', 'Minuman', 'Camilan']));

      final units = await db.select(db.units).get();
      expect(units, isNotEmpty);

      final profile = await db.select(db.businessProfiles).getSingle();
      expect(profile.receiptPaperWidth, '58');
      expect(profile.receiptShowLogo, isTrue);
      expect(profile.printerType, 'system');
      expect(profile.receiptFooter, isNull);

      // CRUD kategori jalan
      await db.into(db.categories).insert(
            CategoriesCompanion.insert(name: 'Test Baru', type: const Value('product')),
          );
      final updated = await db.select(db.categories).get();
      expect(updated.length, cats.length + 1);
    } finally {
      await db.close();
    }
  });

  test('upgrade v2 -> v3: data lama tetap ada + kolom printer ada', () async {
    final file = File('${tempDir.path}/upgrade.db');

    // 1) Bangun database versi 2 persis seperti yang dibuat drift schema v2.
    await _createV2Database(file);

    // 2) Buka dengan AppDatabase (schema 3) -> onUpgrade(2, 3) dijalankan.
    final db = AppDatabase(NativeDatabase(file));
    try {
      // Data lama tetap utuh
      final cats = await db.select(db.categories).get();
      expect(cats.length, 2);
      expect(cats.map((c) => c.name), containsAll(['Makanan', 'Minuman']));

      final products = await db.select(db.products).get();
      expect(products.single.name, 'Nasi Goreng');
      expect(products.single.stock, 20);

      final profile = await db.select(db.businessProfiles).getSingle();
      expect(profile.name, 'Usaha Saya');
      expect(profile.owner, 'Uroo');
      // Kolom baru tersedia dengan nilai default
      expect(profile.receiptPaperWidth, '58');
      expect(profile.receiptShowLogo, isTrue);
      expect(profile.receiptShowAddress, isTrue);
      expect(profile.receiptShowQris, isTrue);
      expect(profile.receiptFooter, isNull);
      expect(profile.printerType, 'system');
      expect(profile.printerAddress, isNull);
      expect(profile.printerName, isNull);

      // CRUD tetap berfungsi setelah upgrade
      await db.into(db.products).insert(
            ProductsCompanion.insert(
              name: 'Es Teh',
              sellPrice: const Value(5000),
              stock: const Value(10),
            ),
          );
      final updated = await db.select(db.products).get();
      expect(updated.length, 2);

      // Update pengaturan printer tersimpan
      final profile2 = await db.select(db.businessProfiles).getSingle();
      await (db.update(db.businessProfiles)..where((b) => b.id.equals(profile2.id))).write(
            const BusinessProfilesCompanion(printerType: Value('bluetooth')),
          );
      final profile3 = await db.select(db.businessProfiles).getSingle();
      expect(profile3.printerType, 'bluetooth');
    } finally {
      await db.close();
    }
  });

  test('upgrade v2 -> v3 dengan sisa tabel tmp migrasi gagal', () async {
    final file = File('${tempDir.path}/recovery.db');

    // Simulasikan pengguna yang sudah sempat mencoba upgrade 1.0.4 yang gagal:
    // database v2 masih ada + tabel sementara `tmp_for_copy_business_profiles`.
    await _createV2Database(file);
    final raw = sqlite3.open(file.path);
    raw.execute(
      'CREATE TABLE tmp_for_copy_business_profiles (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
    );
    raw.dispose();

    // Harus tetap bisa dibuka & bermigrasi dengan bersih.
    final db = AppDatabase(NativeDatabase(file));
    try {
      final cats = await db.select(db.categories).get();
      expect(cats.length, 2);
      final profile = await db.select(db.businessProfiles).getSingle();
      expect(profile.printerType, 'system');
      expect(profile.receiptPaperWidth, '58');
    } finally {
      await db.close();
    }
  });
}

/// Membuat file database dengan skema drift v2 (sebelum commit print)
/// beserta data seed dan `PRAGMA user_version = 2`.
Future<void> _createV2Database(File file) async {
  final db = sqlite3.open(file.path);
  db.execute('PRAGMA user_version = 2');
  db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL DEFAULT 'product',
      icon TEXT NOT NULL DEFAULT 'label',
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))
    )
  ''');
  db.execute('''
    CREATE TABLE units (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))
    )
  ''');
  db.execute('''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      barcode TEXT,
      category_id INTEGER,
      purchase_price REAL NOT NULL DEFAULT 0,
      sell_price REAL NOT NULL DEFAULT 0,
      stock INTEGER NOT NULL DEFAULT 0,
      min_stock INTEGER NOT NULL DEFAULT 5,
      unit TEXT NOT NULL DEFAULT 'pcs',
      image_path TEXT,
      description TEXT,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)),
      updated_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))
    )
  ''');
  db.execute('''
    CREATE TABLE business_profiles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL DEFAULT 'Usaha Saya',
      owner TEXT,
      phone TEXT,
      address TEXT,
      npwp TEXT,
      currency TEXT NOT NULL DEFAULT 'IDR',
      theme TEXT NOT NULL DEFAULT 'light',
      qris_image_path TEXT,
      logo_path TEXT,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)),
      updated_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))
    )
  ''');

  db.execute(
    "INSERT INTO categories (name, type, icon, created_at) VALUES "
    "('Makanan', 'product', 'label', strftime('%s','now')), "
    "('Minuman', 'product', 'label', strftime('%s','now'))",
  );
  db.execute("INSERT INTO units (name, created_at) VALUES ('pcs', strftime('%s','now'))");
  db.execute(
    "INSERT INTO products (name, sell_price, stock, unit, created_at, updated_at) "
    "VALUES ('Nasi Goreng', 15000, 20, 'pcs', strftime('%s','now'), strftime('%s','now'))",
  );
  db.execute(
    "INSERT INTO business_profiles (name, owner, created_at, updated_at) "
    "VALUES ('Usaha Saya', 'Uroo', strftime('%s','now'), strftime('%s','now'))",
  );
  db.dispose();
}
