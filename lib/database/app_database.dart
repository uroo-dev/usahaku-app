import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Categories,
  Units,
  Products,
  Customers,
  Suppliers,
  Transactions,
  Sales,
  SaleItems,
  Debts,
  DebtPayments,
  BusinessProfiles,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedDefaults();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(units);
            await _seedUnits();
          }
          if (from < 3) {
            // Sisa tabel dari migrasi v3 lama yang gagal (jika ada) harus
            // dibersihkan sebelum menambah kolom baru.
            await customStatement('DROP TABLE IF EXISTS tmp_for_copy_business_profiles');
            await m.addColumn(businessProfiles, businessProfiles.receiptPaperWidth);
            await m.addColumn(businessProfiles, businessProfiles.receiptShowLogo);
            await m.addColumn(businessProfiles, businessProfiles.receiptShowAddress);
            await m.addColumn(businessProfiles, businessProfiles.receiptShowQris);
            await m.addColumn(businessProfiles, businessProfiles.receiptFooter);
            await m.addColumn(businessProfiles, businessProfiles.printerType);
            await m.addColumn(businessProfiles, businessProfiles.printerAddress);
            await m.addColumn(businessProfiles, businessProfiles.printerName);
          }
        },
      );

  /// Data awal: kategori produk & kas default, satuan, profil bisnis kosong.
  Future<void> _seedDefaults() async {
    await categories.insertAll([
      CategoriesCompanion.insert(name: 'Makanan', type: Value('product')),
      CategoriesCompanion.insert(name: 'Minuman', type: Value('product')),
      CategoriesCompanion.insert(name: 'Camilan', type: Value('product')),
      CategoriesCompanion.insert(name: 'Elektronik', type: Value('product')),
      CategoriesCompanion.insert(name: 'Pakaian', type: Value('product')),
      CategoriesCompanion.insert(name: 'Lainnya', type: Value('product')),
      CategoriesCompanion.insert(name: 'Penjualan', type: Value('cash'), icon: Value('point_of_sale')),
      CategoriesCompanion.insert(name: 'Pembelian Stok', type: Value('cash'), icon: Value('shopping_cart')),
      CategoriesCompanion.insert(name: 'Operasional', type: Value('cash'), icon: Value('receipt_long')),
      CategoriesCompanion.insert(name: 'Gaji', type: Value('cash'), icon: Value('payments')),
      CategoriesCompanion.insert(name: 'Lainnya', type: Value('cash'), icon: Value('category')),
    ]);
    await _seedUnits();
    await into(businessProfiles).insert(BusinessProfilesCompanion.insert());
  }

  Future<void> _seedUnits() async {
    await units.insertAll([
      UnitsCompanion.insert(name: 'Pcs (Biji)'),
      UnitsCompanion.insert(name: 'Kg (Kilogram)'),
      UnitsCompanion.insert(name: 'Box (Kotak)'),
      UnitsCompanion.insert(name: 'Liter'),
      UnitsCompanion.insert(name: 'Botol'),
      UnitsCompanion.insert(name: 'Dus'),
      UnitsCompanion.insert(name: 'Lusin'),
      UnitsCompanion.insert(name: 'Pack'),
      UnitsCompanion.insert(name: 'Set'),
    ]);
  }

  Future<void> deleteAllData() async {
    await delete(saleItems).go();
    await delete(sales).go();
    await delete(transactions).go();
    await delete(debtPayments).go();
    await delete(debts).go();
    await delete(products).go();
    await delete(customers).go();
    await delete(suppliers).go();
    await delete(businessProfiles).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = p.join(dbFolder.path, 'usahaku.db');
    return NativeDatabase.createInBackground(File(file));
  });
}
