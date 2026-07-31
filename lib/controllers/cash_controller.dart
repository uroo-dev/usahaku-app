import 'package:drift/drift.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/database/db.dart';
import 'package:usahaku/models/cash_transaction_model.dart';

import 'base_controller.dart';

/// Manajemen kas: pemasukan, pengeluaran, filter, kategori dinamis.
class CashController extends BaseController {
  List<CashTransactionModel> _transactions = [];
  List<CashTransactionModel> _filtered = [];
  List<CashCategoryModel> _categories = [];
  String _query = '';
  TransactionType? _typeFilter; // null = semua
  int? _categoryId;
  String _period = 'Semua'; // Hari ini | Minggu ini | Bulan ini | Semua

  List<CashTransactionModel> get transactions => _filtered;
  List<CashCategoryModel> get categories => _categories;
  String get query => _query;
  TransactionType? get typeFilter => _typeFilter;
  int? get categoryId => _categoryId;
  String get period => _period;

  Future<void> load() async {
    setLoading(true);
    try {
      final db = DB.instance;
      final catRows = await (db.select(db.categories)
            ..where((c) => c.type.equals('cash'))
            ..orderBy([(c) => OrderingTerm(expression: c.name)]))
          .get();
      _categories = catRows.map(CashCategoryModel.fromRow).toList();
      final rows = await (db.select(db.transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();
      final catMap = {for (final c in _categories) c.id: c};
      _transactions = rows
          .map((r) => CashTransactionModel.fromRow(
                r,
                categoryName: catMap[r.categoryId]?.name ?? 'Lainnya',
                categoryIcon: catMap[r.categoryId]?.icon ?? 'label',
              ))
          .toList();
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

  void setTypeFilter(TransactionType? t) {
    _typeFilter = t;
    _applyFilter();
    notifyListeners();
  }

  void setCategoryFilter(int? id) {
    _categoryId = id;
    _applyFilter();
    notifyListeners();
  }

  void setPeriod(String p) {
    _period = p;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    _filtered = _transactions.where((t) {
      final matchQuery = _query.isEmpty || t.description.toLowerCase().contains(_query.toLowerCase());
      final matchType = _typeFilter == null || t.type == _typeFilter;
      final matchCat = _categoryId == null || t.categoryId == _categoryId;
      bool matchPeriod = true;
      switch (_period) {
        case 'Hari ini':
          matchPeriod = !t.date.isBefore(today);
          break;
        case 'Minggu ini':
          matchPeriod = !t.date.isBefore(weekStart);
          break;
        case 'Bulan ini':
          matchPeriod = !t.date.isBefore(monthStart);
          break;
      }
      return matchQuery && matchType && matchCat && matchPeriod;
    }).toList();
    notifyListeners();
  }

  double get incomeTotal => _filtered.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
  double get expenseTotal => _filtered.where((t) => !t.isIncome).fold(0, (s, t) => s + t.amount);
  double get balanceTotal => _transactions.fold(0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));

  Future<void> add(CashTransactionModel t) async {
    await DB.instance.into(DB.instance.transactions).insert(t.toCompanion());
    await load();
  }

  Future<void> delete(int id) async {
    await (DB.instance.delete(DB.instance.transactions)..where((t) => t.id.equals(id))).go();
    await load();
  }

  // --- Kategori dinamis ---
  Future<void> addCategory(String name, String icon) async {
    await DB.instance.into(DB.instance.categories).insert(
          CategoriesCompanion.insert(name: name, type: Value('cash'), icon: Value(icon)),
        );
    await load();
  }

  Future<void> renameCategory(int id, String newName) async {
    await (DB.instance.update(DB.instance.categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(name: Value(newName)));
    await load();
  }

  Future<void> updateCategoryIcon(int id, String icon) async {
    await (DB.instance.update(DB.instance.categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(icon: Value(icon)));
    await load();
  }

  Future<void> deleteCategory(int id) async {
    await (DB.instance.delete(DB.instance.categories)..where((c) => c.id.equals(id))).go();
    await load();
  }
}
