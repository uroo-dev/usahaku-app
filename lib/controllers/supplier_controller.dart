import 'package:drift/drift.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/database/db.dart';
import 'package:usahaku/models/supplier_model.dart';

import 'base_controller.dart';

/// Kelola supplier (opsional).
class SupplierController extends BaseController {
  List<SupplierModel> _suppliers = [];
  List<SupplierModel> _filtered = [];
  String _query = '';

  List<SupplierModel> get suppliers => _filtered;
  String get query => _query;

  Future<void> load() async {
    setLoading(true);
    try {
      final db = DB.instance;
      final rows = await (db.select(db.suppliers)
            ..orderBy([(c) => OrderingTerm(expression: c.name)]))
          .get();
      _suppliers = rows.map(SupplierModel.fromRow).toList();
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
    _filtered = _suppliers.where((s) {
      return _query.isEmpty ||
          s.name.toLowerCase().contains(_query.toLowerCase()) ||
          s.phone.toLowerCase().contains(_query.toLowerCase());
    }).toList();
  }

  Future<void> add(SupplierModel s) async {
    await DB.instance.into(DB.instance.suppliers).insert(s.toCompanion());
    await load();
  }

  Future<void> update(SupplierModel s) async {
    await (DB.instance.update(DB.instance.suppliers)..where((t) => t.id.equals(s.id!))).write(s.toCompanion());
    await load();
  }

  Future<void> delete(int id) async {
    await (DB.instance.delete(DB.instance.suppliers)..where((t) => t.id.equals(id))).go();
    await load();
  }

  Future<double> remainingPayable(int supplierId) async {
    final db = DB.instance;
    final debts = await (db.select(db.debts)
          ..where((d) => d.type.equalsValue(DebtType.utang) & d.relatedId.equals(supplierId)))
        .get();
    double total = 0;
    for (final d in debts) {
      total += d.amount - d.paidAmount;
    }
    return total;
  }
}
