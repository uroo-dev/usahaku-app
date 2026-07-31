import 'package:drift/drift.dart' show Value;
import 'package:usahaku/database/app_database.dart';

/// Piutang (tagihan ke pelanggan) & Utang (kewajiban ke supplier).
class DebtModel {
  final int? id;
  final DebtType type;
  final int relatedId;
  final String relatedName;
  final String relatedPhone;
  final double amount;
  final double paidAmount;
  final DateTime dueDate;
  final DebtStatus status;
  final String? description;
  final DateTime? createdAt;

  DebtModel({
    this.id,
    required this.type,
    required this.relatedId,
    this.relatedName = '',
    this.relatedPhone = '',
    required this.amount,
    this.paidAmount = 0,
    required this.dueDate,
    this.status = DebtStatus.pending,
    this.description,
    this.createdAt,
  });

  double get remaining => amount - paidAmount;
  bool get isOverdue => status != DebtStatus.paid && dueDate.isBefore(DateTime.now());
  bool get isLunas => status == DebtStatus.paid;

  String get statusLabel {
    switch (status) {
      case DebtStatus.paid:
        return 'Lunas';
      case DebtStatus.partial:
        return isOverdue ? 'Sebagian • Telat' : 'Sebagian';
      case DebtStatus.pending:
        return isOverdue ? 'Terlambat' : 'Belum Lunas';
    }
  }

  DebtsCompanion toCompanion() {
    return DebtsCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      type: Value(type),
      relatedId: Value(relatedId),
      amount: Value(amount),
      paidAmount: Value(paidAmount),
      dueDate: Value(dueDate),
      status: Value(status),
      description: Value(description),
    );
  }

  factory DebtModel.fromRow(
    Debt row, {
    String relatedName = '',
    String relatedPhone = '',
  }) {
    return DebtModel(
      id: row.id,
      type: row.type,
      relatedId: row.relatedId,
      relatedName: relatedName,
      relatedPhone: relatedPhone,
      amount: row.amount,
      paidAmount: row.paidAmount,
      dueDate: row.dueDate,
      status: row.status,
      description: row.description,
      createdAt: row.createdAt,
    );
  }
}

/// Riwayat pembayaran piutang/utang.
class DebtPaymentModel {
  final int? id;
  final int debtId;
  final double amount;
  final DateTime date;
  final String? notes;

  DebtPaymentModel({
    this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    this.notes,
  });

  DebtPaymentsCompanion toCompanion() {
    return DebtPaymentsCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      debtId: Value(debtId),
      amount: Value(amount),
      date: Value(date),
      notes: Value(notes),
    );
  }

  factory DebtPaymentModel.fromRow(DebtPayment row) {
    return DebtPaymentModel(
      id: row.id,
      debtId: row.debtId,
      amount: row.amount,
      date: row.date,
      notes: row.notes,
    );
  }
}
