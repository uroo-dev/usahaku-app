import 'package:drift/drift.dart';

/// Kategori dinamis (produk / kas) — bisa dibuat, rename, dan dihapus.
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  /// 'product' | 'cash'
  TextColumn get type => text().withDefault(const Constant('product'))();
  /// Nama icon Material (hanya dipakai kategori kas)
  TextColumn get icon => text().withDefault(const Constant('label'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get barcode => text().nullable()();
  IntColumn get categoryId => integer().nullable()();
  RealColumn get purchasePrice => real().withDefault(const Constant(0.0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0.0))();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  IntColumn get minStock => integer().withDefault(const Constant(5))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  TextColumn get imagePath => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

enum TransactionType { income, expense }
enum PaymentMethod { cash, qris, transfer, debt }

/// Transaksi kas masuk / kas keluar.
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => textEnum<TransactionType>()();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  TextColumn get description => text().withLength(min: 1, max: 500)();
  IntColumn get categoryId => integer().nullable()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get paymentMethod => textEnum<PaymentMethod>().withDefault(const Constant('cash'))();
  IntColumn get customerId => integer().nullable()();
  IntColumn get supplierId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Penjualan (POS header).
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNo => text()();
  IntColumn get customerId => integer().nullable()();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  TextColumn get paymentMethod => textEnum<PaymentMethod>().withDefault(const Constant('cash'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Item penjualan.
class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer()();
  IntColumn get productId => integer()();
  IntColumn get quantity => integer()();
  RealColumn get price => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
}

enum DebtType { piutang, utang }
enum DebtStatus { pending, partial, paid }

/// Piutang (dari pelanggan) & Utang (ke supplier).
class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => textEnum<DebtType>()();
  IntColumn get relatedId => integer()();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => textEnum<DebtStatus>().withDefault(const Constant('pending'))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Riwayat pembayaran piutang/utang.
class DebtPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debtId => integer()();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
}

/// Profil bisnis + pengaturan (1 baris pertama).
class BusinessProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant('Usaha Saya'))();
  TextColumn get owner => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get npwp => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  TextColumn get theme => text().withDefault(const Constant('light'))();
  TextColumn get qrisImagePath => text().nullable()();
  TextColumn get logoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
