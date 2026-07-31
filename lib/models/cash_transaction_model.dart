import 'package:drift/drift.dart' show Value;
import 'package:usahaku/database/app_database.dart';

/// Transaksi kas masuk / kas keluar.
class CashTransactionModel {
  final int? id;
  final TransactionType type;
  final double amount;
  final String description;
  final int? categoryId;
  final String categoryName;
  final String categoryIcon;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final int? customerId;
  final int? supplierId;

  CashTransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.categoryId,
    this.categoryName = 'Lainnya',
    this.categoryIcon = 'label',
    required this.date,
    this.paymentMethod = PaymentMethod.cash,
    this.customerId,
    this.supplierId,
  });

  bool get isIncome => type == TransactionType.income;

  TransactionsCompanion toCompanion() {
    return TransactionsCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      type: Value(type),
      amount: Value(amount),
      description: Value(description),
      categoryId: Value(categoryId),
      date: Value(date),
      paymentMethod: Value(paymentMethod),
      customerId: Value(customerId),
      supplierId: Value(supplierId),
    );
  }

  factory CashTransactionModel.fromRow(
    Transaction row, {
    String categoryName = 'Lainnya',
    String categoryIcon = 'label',
  }) {
    return CashTransactionModel(
      id: row.id,
      type: row.type,
      amount: row.amount,
      description: row.description,
      categoryId: row.categoryId,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      date: row.date,
      paymentMethod: row.paymentMethod,
      customerId: row.customerId,
      supplierId: row.supplierId,
    );
  }
}

/// Kategori kas (dinamis, dapat dipilih ikon Material).
class CashCategoryModel {
  final int? id;
  final String name;
  final String icon;

  CashCategoryModel({this.id, required this.name, this.icon = 'label'});

  factory CashCategoryModel.fromRow(Category row) {
    return CashCategoryModel(id: row.id, name: row.name, icon: row.icon);
  }
}
