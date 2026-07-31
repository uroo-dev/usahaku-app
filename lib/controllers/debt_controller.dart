import 'package:drift/drift.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/database/db.dart';
import 'package:usahaku/models/debt_model.dart';

import 'base_controller.dart';

/// Dasar piutang & utang.
abstract class DebtBaseController extends BaseController {
  List<DebtModel> _debts = [];
  List<DebtModel> _filtered = [];
  String _statusFilter = 'Semua'; // Semua | Belum Lunas | Sebagian | Lunas

  List<DebtModel> get debts => _filtered;
  String get statusFilter => _statusFilter;

  Future<void> load() async {
    setLoading(true);
    try {
      _debts = await _fetch();
      _applyFilter();
      setError(null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<List<DebtModel>> _fetch();

  void setStatusFilter(String f) {
    _statusFilter = f;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filtered = _debts.where((d) {
      switch (_statusFilter) {
        case 'Belum Lunas':
          return d.status == DebtStatus.pending;
        case 'Sebagian':
          return d.status == DebtStatus.partial;
        case 'Lunas':
          return d.status == DebtStatus.paid;
      }
      return true;
    }).toList();
  }

  double get totalRemaining => _debts.fold(0.0, (s, d) => s + (d.amount - d.paidAmount));
  double get totalPaidThisMonth {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return _debts.where((d) => d.createdAt != null && !d.createdAt!.isBefore(start)).fold(
          0,
          (s, d) => s + d.paidAmount,
        );
  }

  double get overdueTotal => _debts.where((d) => d.isOverdue).fold(0.0, (s, d) => s + (d.amount - d.paidAmount));
  double get comingTotal => _debts.where((d) => !d.isOverdue && d.status != DebtStatus.paid).fold(0.0, (s, d) => s + (d.amount - d.paidAmount));

  Future<void> recordPayment(int debtId, double amount, {String? notes}) async {
    final db = DB.instance;
    final debt = await (db.select(db.debts)..where((d) => d.id.equals(debtId))).getSingle();
    final newPaid = debt.paidAmount + amount;
    final newStatus = newPaid >= debt.amount ? DebtStatus.paid : DebtStatus.partial;

    await db.transaction(() async {
      await (db.update(db.debts)..where((d) => d.id.equals(debtId))).write(DebtsCompanion(
            paidAmount: Value(newPaid),
            status: Value(newStatus),
          ));
      await db.into(db.debtPayments).insert(DebtPaymentsCompanion.insert(
            debtId: debtId,
            amount: Value(amount),
            notes: Value(notes),
          ));
      // Catat transaksi kas
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
            type: debt.type == DebtType.piutang ? TransactionType.income : TransactionType.expense,
            amount: Value(amount),
            description: notes ?? (debt.type == DebtType.piutang ? 'Pembayaran piutang' : 'Pembayaran utang'),
          ));
    });
    await load();
  }

  Future<List<DebtPaymentModel>> paymentHistory(int debtId) async {
    final rows = await (DB.instance.select(DB.instance.debtPayments)
          ..where((d) => d.debtId.equals(debtId))
          ..orderBy([(d) => OrderingTerm.desc(d.date)]))
        .get();
    return rows.map(DebtPaymentModel.fromRow).toList();
  }
}

/// Piutang (tagihan ke pelanggan).
class ReceivableController extends DebtBaseController {
  @override
  Future<List<DebtModel>> _fetch() async {
    final db = DB.instance;
    final rows = await (db.select(db.debts)
          ..where((d) => d.type.equalsValue(DebtType.piutang))
          ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
        .get();
    final customers = await db.select(db.customers).get();
    final map = {for (final c in customers) c.id: c};
    return rows.map((d) {
      final c = map[d.relatedId];
      return DebtModel.fromRow(d, relatedName: c?.name ?? 'Pelanggan Umum', relatedPhone: c?.phone ?? '');
    }).toList();
  }
}

/// Utang (kewajiban ke supplier).
class PayableController extends DebtBaseController {
  @override
  Future<List<DebtModel>> _fetch() async {
    final db = DB.instance;
    final rows = await (db.select(db.debts)
          ..where((d) => d.type.equalsValue(DebtType.utang))
          ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
        .get();
    final suppliers = await db.select(db.suppliers).get();
    final map = {for (final s in suppliers) s.id: s};
    return rows.map((d) {
      final s = map[d.relatedId];
      return DebtModel.fromRow(d, relatedName: s?.name ?? 'Supplier', relatedPhone: s?.phone ?? '');
    }).toList();
  }
}
