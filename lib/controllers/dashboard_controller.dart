import 'package:drift/drift.dart' hide isNull;
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/database/db.dart';
import 'package:usahaku/models/dashboard_model.dart';

import 'base_controller.dart';

/// Mengumpulkan ringkasan dari SQLite untuk Dashboard.
class DashboardController extends BaseController {
  DashboardModel? _data;
  DashboardModel get data => _data ?? DashboardModel();

  Future<void> load() async {
    setLoading(true);
    try {
      final db = DB.instance;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final monthStart = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);

      // Pendapatan hari ini dari sales
      final todayRevExpr = db.sales.total.sum();
      final qRev = db.selectOnly(db.sales)
        ..addColumns([todayRevExpr])
        ..where(db.sales.date.isBiggerOrEqualValue(today) & db.sales.date.isSmallerThanValue(tomorrow));
      final todayRevenue = await qRev.getSingle().then((r) => r.read(todayRevExpr) ?? 0.0);

      final todayCountExpr = db.sales.id.count();
      final qCount = db.selectOnly(db.sales)
        ..addColumns([todayCountExpr])
        ..where(db.sales.date.isBiggerOrEqualValue(today) & db.sales.date.isSmallerThanValue(tomorrow));
      final todayTransactions = await qCount.getSingle().then((r) => r.read(todayCountExpr) ?? 0);

      // Laba hari ini: total - harga modal item
      double todayModal = 0;
      final itemRows = await (db.selectOnly(db.saleItems)
            ..addColumns([db.saleItems.productId, db.saleItems.price, db.saleItems.quantity])
            ..join([
              innerJoin(db.sales, db.sales.id.equalsExp(db.saleItems.saleId)),
            ])
            ..where(db.sales.date.isBiggerOrEqualValue(today) & db.sales.date.isSmallerThanValue(tomorrow)))
          .get();
      final prices = await _productPrices(db);
      for (final row in itemRows) {
        final pid = row.read(db.saleItems.productId)!;
        todayModal += (prices[pid] ?? 0) * row.read(db.saleItems.quantity)!;
      }
      final todayProfit = todayRevenue - todayModal;

      // Saldo kas = income - expense
      final incomeExpr = db.transactions.amount.sum();
      final qIn = db.selectOnly(db.transactions)
        ..addColumns([incomeExpr])
        ..where(db.transactions.type.equalsValue(TransactionType.income));
      final income = await qIn.getSingle().then((r) => r.read(incomeExpr) ?? 0.0);

      final qOut = db.selectOnly(db.transactions)
        ..addColumns([incomeExpr])
        ..where(db.transactions.type.equalsValue(TransactionType.expense));
      final expense = await qOut.getSingle().then((r) => r.read(incomeExpr) ?? 0.0);
      final cashBalance = income - expense;

      // Stok rendah
      final lowProducts = await (db.select(db.products)
            ..where((p) => p.stock.isSmallerOrEqual(p.minStock))
            ..orderBy([(p) => OrderingTerm(expression: p.stock)]))
          .get();

      // Piutang & utang
      final debts = await db.select(db.debts).get();
      double receivable = 0;
      double payable = 0;
      int overdueReceivable = 0;
      int overduePayable = 0;
      for (final d in debts) {
        final remaining = d.amount - d.paidAmount;
        if (remaining <= 0) continue;
        final isLate = d.dueDate.isBefore(now);
        if (d.type == DebtType.piutang) {
          receivable += remaining;
          if (isLate) overdueReceivable++;
        } else {
          payable += remaining;
          if (isLate) overduePayable++;
        }
      }

      // Penjualan terbaru
      final recentSalesRows = await (db.select(db.sales)
            ..orderBy([(s) => OrderingTerm.desc(s.date)])
            ..limit(5))
          .get();
      final customerNames = await _customerNames(db);
      final recentSales = <DashboardSale>[];
      for (final s in recentSalesRows) {
        final itemCount = await _saleItemCount(db, s.id);
        recentSales.add(DashboardSale(
          id: s.id,
          invoiceNo: s.invoiceNo,
          total: s.total,
          paymentMethod: s.paymentMethod == PaymentMethod.cash
              ? PaymentMethodLabel.cash
              : s.paymentMethod == PaymentMethod.qris
                  ? PaymentMethodLabel.qris
                  : s.paymentMethod == PaymentMethod.transfer
                      ? PaymentMethodLabel.transfer
                      : PaymentMethodLabel.debt,
          date: s.date,
          itemCount: itemCount,
          customerName: s.customerId != null ? customerNames[s.customerId] ?? 'Pelanggan Umum' : 'Pelanggan Umum',
        ));
      }

      // Produk terlaris (bulan ini)
      final topExpr = db.saleItems.quantity.sum();
      final qTop = db.selectOnly(db.saleItems)
        ..addColumns([db.saleItems.productId, topExpr])
        ..join([innerJoin(db.sales, db.sales.id.equalsExp(db.saleItems.saleId))])
        ..where(db.sales.date.isBiggerOrEqualValue(monthStart) & db.sales.date.isSmallerThanValue(nextMonth))
        ..groupBy([db.saleItems.productId])
        ..orderBy([OrderingTerm.desc(topExpr)])
        ..limit(5);
      final topRows = await qTop.get();
      final topProducts = <DashboardSale>[];
      final productNames = await _productNames(db);
      for (final row in topRows) {
        final pid = row.read(db.saleItems.productId);
        if (pid == null) continue;
        final qty = row.read(topExpr) ?? 0;
        topProducts.add(DashboardSale(
          id: pid,
          invoiceNo: productNames[pid] ?? 'Produk',
          total: qty.toDouble(),
          paymentMethod: PaymentMethodLabel.cash,
          date: now,
          itemCount: qty,
        ));
      }

      _data = DashboardModel(
        todayRevenue: todayRevenue,
        todayProfit: todayProfit,
        todayTransactions: todayTransactions,
        cashBalance: cashBalance,
        lowStockCount: lowProducts.length,
        lowStockProducts: lowProducts
            .map((p) => DashboardProduct(
                  id: p.id,
                  name: p.name,
                  stock: p.stock,
                  minStock: p.minStock,
                  imagePath: p.imagePath,
                ))
            .toList(),
        totalReceivable: receivable,
        overdueReceivableCount: overdueReceivable,
        totalPayable: payable,
        overduePayableCount: overduePayable,
        recentSales: recentSales,
        topProducts: topProducts,
      );
      setError(null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<Map<int, double>> _productPrices(AppDatabase db) async {
    final rows = await db.select(db.products).get();
    return {for (final r in rows) r.id: r.purchasePrice};
  }

  Future<Map<int, String>> _productNames(AppDatabase db) async {
    final rows = await db.select(db.products).get();
    return {for (final r in rows) r.id: r.name};
  }

  Future<Map<int, String>> _customerNames(AppDatabase db) async {
    final rows = await db.select(db.customers).get();
    return {for (final r in rows) r.id: r.name};
  }

  Future<int> _saleItemCount(AppDatabase db, int saleId) async {
    final expr = db.saleItems.quantity.sum();
    final q = db.selectOnly(db.saleItems)
      ..addColumns([expr])
      ..where(db.saleItems.saleId.equals(saleId));
    return await q.getSingle().then((r) => r.read(expr) ?? 0);
  }
}

/// List statistik kecil untuk bento grid.
class MiniStat {
  final double value;
  final double trend;
  MiniStat(this.value, this.trend);
}
