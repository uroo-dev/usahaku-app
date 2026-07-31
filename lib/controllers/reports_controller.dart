import 'package:drift/drift.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/database/db.dart';
import 'package:usahaku/models/sale_model.dart';

import 'base_controller.dart';

/// Statistik laporan dari SQLite.
class ReportSummary {
  final double totalRevenue;
  final double totalModal;
  final double totalProfit;
  final int totalTransactions;
  final double totalExpense;
  final double netCash;
  final List<DailyPoint> daily;
  final List<MapEntry<String, int>> topProducts;

  ReportSummary({
    this.totalRevenue = 0,
    this.totalModal = 0,
    this.totalProfit = 0,
    this.totalTransactions = 0,
    this.totalExpense = 0,
    this.netCash = 0,
    this.daily = const [],
    this.topProducts = const [],
  });
}

class DailyPoint {
  final DateTime date;
  final double revenue;
  final double expense;
  DailyPoint(this.date, this.revenue, this.expense);
}

/// Laporan: penjualan, laba rugi, arus kas, produk terlaris.
class ReportsController extends BaseController {
  ReportSummary _summary = ReportSummary();
  ReportSummary get summary => _summary;

  String _period = 'Bulan ini'; // Hari ini | Minggu ini | Bulan ini | Tahun ini

  String get period => _period;

  void setPeriod(String p) {
    _period = p;
    load();
  }

  Future<void> load() async {
    setLoading(true);
    try {
      final db = DB.instance;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);
      final yearStart = DateTime(now.year, 1, 1);

      DateTime start;
      switch (_period) {
        case 'Hari ini':
          start = today;
          break;
        case 'Minggu ini':
          start = weekStart;
          break;
        case 'Bulan ini':
          start = monthStart;
          break;
        default:
          start = yearStart;
      }

      // Penjualan
      final sales = await (db.select(db.sales)
            ..where((s) => s.date.isBiggerOrEqualValue(start))
            ..orderBy([(s) => OrderingTerm(expression: s.date)]))
          .get();
      final totalRevenue = sales.fold(0.0, (s, x) => s + x.total);
      final totalTransactions = sales.length;

      // Modal dari item
      double totalModal = 0;
      final saleIds = sales.map((s) => s.id).toList();
      if (saleIds.isNotEmpty) {
        final items = await (db.select(db.saleItems)
              ..where((i) => i.saleId.isIn(saleIds)))
            .get();
        final products = await db.select(db.products).get();
        final priceMap = {for (final p in products) p.id: p.purchasePrice};
        for (final item in items) {
          totalModal += (priceMap[item.productId] ?? 0) * item.quantity;
        }
      }

      // Pengeluaran
      final expExpr = db.transactions.amount.sum();
      final qExp = db.selectOnly(db.transactions)
        ..addColumns([expExpr])
        ..where(db.transactions.type.equalsValue(TransactionType.expense) &
            db.transactions.date.isBiggerOrEqualValue(start));
      final totalExpense = await qExp.getSingle().then((r) => r.read(expExpr) ?? 0.0);

      // Arus kas (semua waktu)
      final allIncome = await _allCashSum(db, TransactionType.income);
      final allExpense = await _allCashSum(db, TransactionType.expense);

      // Seri harian
      final daily = <DailyPoint>[];
      for (var i = 0; i < 7; i++) {
        final day = today.subtract(Duration(days: 6 - i));
        final nextDay = day.add(const Duration(days: 1));
        final rev = sales
            .where((s) => !s.date.isBefore(day) && s.date.isBefore(nextDay))
            .fold(0.0, (sum, s) => sum + s.total);
        daily.add(DailyPoint(day, rev, 0));
      }

      // Produk terlaris
      final top = <MapEntry<String, int>>[];
      if (saleIds.isNotEmpty) {
        final q = db.selectOnly(db.saleItems)
          ..addColumns([db.saleItems.productId, db.saleItems.quantity.sum()])
          ..where(db.saleItems.saleId.isIn(saleIds))
          ..groupBy([db.saleItems.productId])
          ..orderBy([OrderingTerm.desc(db.saleItems.quantity.sum())])
          ..limit(5);
        final rows = await q.get();
        final products = await db.select(db.products).get();
        final nameMap = {for (final p in products) p.id: p.name};
        for (final r in rows) {
          final pid = r.read(db.saleItems.productId);
          final qty = r.read(db.saleItems.quantity.sum()) ?? 0;
          if (pid != null) top.add(MapEntry(nameMap[pid] ?? 'Produk', qty));
        }
      }

      _summary = ReportSummary(
        totalRevenue: totalRevenue,
        totalModal: totalModal,
        totalProfit: totalRevenue - totalModal,
        totalTransactions: totalTransactions,
        totalExpense: totalExpense,
        netCash: allIncome - allExpense,
        daily: daily,
        topProducts: top,
      );
      setError(null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<double> _allCashSum(AppDatabase db, TransactionType type) async {
    final expr = db.transactions.amount.sum();
    final q = db.selectOnly(db.transactions)
      ..addColumns([expr])
      ..where(db.transactions.type.equalsValue(type));
    return await q.getSingle().then((r) => r.read(expr) ?? 0.0);
  }

  /// Semua penjualan untuk laporan detail / ekspor.
  Future<List<SaleModel>> allSales({DateTime? from, DateTime? to}) async {
    final db = DB.instance;
    final q = db.select(db.sales)..orderBy([(s) => OrderingTerm.desc(s.date)]);
    if (from != null) q.where((s) => s.date.isBiggerOrEqualValue(from));
    if (to != null) q.where((s) => s.date.isSmallerOrEqualValue(to));
    final rows = await q.get();
    final customers = await db.select(db.customers).get();
    final cMap = {for (final c in customers) c.id: c.name};

    final result = <SaleModel>[];
    for (final s in rows) {
      final items = await (db.select(db.saleItems)..where((i) => i.saleId.equals(s.id))).get();
      result.add(SaleModel.fromRow(
        s,
        customerName: cMap[s.customerId] ?? 'Pelanggan Umum',
        items: items.map((i) => SaleItemModel.fromRow(i)).toList(),
      ));
    }
    return result;
  }
}
