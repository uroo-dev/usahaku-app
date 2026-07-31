import 'package:drift/drift.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/database/db.dart';

import 'base_controller.dart';

/// Manajemen satuan produk (master data).
class UnitController extends BaseController {
  List<Unit> _units = [];
  List<Unit> get units => _units;

  Future<void> load() async {
    setLoading(true);
    try {
      final db = DB.instance;
      _units = await (db.select(db.units)..orderBy([(u) => OrderingTerm(expression: u.name)])).get();
      setError(null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> add(String name) async {
    await DB.instance.into(DB.instance.units).insert(UnitsCompanion.insert(name: name));
    await load();
  }

  Future<void> rename(int id, String newName) async {
    await (DB.instance.update(DB.instance.units)..where((u) => u.id.equals(id)))
        .write(UnitsCompanion(name: Value(newName)));
    await load();
  }

  Future<void> delete(int id) async {
    await (DB.instance.delete(DB.instance.units)..where((u) => u.id.equals(id))).go();
    await load();
  }
}
