import 'package:drift/drift.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/database/db.dart';
import 'package:usahaku/models/customer_model.dart';

import 'base_controller.dart';

/// Kelola pelanggan (opsional).
class CustomerController extends BaseController {
  List<CustomerModel> _customers = [];
  List<CustomerModel> _filtered = [];
  String _query = '';

  List<CustomerModel> get customers => _filtered;
  String get query => _query;

  Future<void> load() async {
    setLoading(true);
    try {
      final db = DB.instance;
      final rows = await (db.select(db.customers)
            ..orderBy([(c) => OrderingTerm(expression: c.name)]))
          .get();
      _customers = rows.map(CustomerModel.fromRow).toList();
      _applyFilter();
      setError(null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  void setQuery(String q) {
    _query = q;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filtered = _customers.where((c) {
      return _query.isEmpty ||
          c.name.toLowerCase().contains(_query.toLowerCase()) ||
          c.phone.toLowerCase().contains(_query.toLowerCase());
    }).toList();
  }

  Future<void> add(CustomerModel c) async {
    await DB.instance.into(DB.instance.customers).insert(c.toCompanion());
    await load();
  }

  Future<void> update(CustomerModel c) async {
    await (DB.instance.update(DB.instance.customers)..where((t) => t.id.equals(c.id!))).write(c.toCompanion());
    await load();
  }

  Future<void> delete(int id) async {
    await (DB.instance.delete(DB.instance.customers)..where((t) => t.id.equals(id))).go();
    await load();
  }

  /// Total belanja pelanggan dari tabel sales.
  Future<double> totalSpending(int customerId) async {
    final db = DB.instance;
    final expr = db.sales.total.sum();
    final q = db.selectOnly(db.sales)
      ..addColumns([expr])
      ..where(db.sales.customerId.equals(customerId));
    return await q.getSingle().then((r) => r.read(expr) ?? 0);
  }

  /// Sisa piutang pelanggan.
  Future<double> remainingReceivable(int customerId) async {
    final db = DB.instance;
    final debts = await (db.select(db.debts)
          ..where((d) => d.type.equalsValue(DebtType.piutang) & d.relatedId.equals(customerId)))
        .get();
    double total = 0;
    for (final d in debts) {
      total += d.amount - d.paidAmount;
    }
    return total;
  }
}
