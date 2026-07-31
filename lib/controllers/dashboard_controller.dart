import 'package:drift/drift.dart' hide isNull;
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/database/db.dart';
import 'package:usahaku/models/dashboard_model.dart';

import 'base_controller.dart';

/// Mengumpulkan ringkasan dari SQLite untuk Dashboard.
/// Semua nilai dihitung dari data real — tidak ada yang hardcoded.
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
      final yesterday = today.subtract(const Duration(days: 1));
      final monthStart = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);

      // ── Pendapatan hari ini ──────────────────────────────────────
      final todayRevExpr = db.sales.total.sum();
      final todayRevenue = await (db.selectOnly(db.sales)
            ..addColumns([todayRevExpr])
            ..where(db.sales.date.isBiggerOrEqualValue(today) &
                db.sales.date.isSmallerThanValue(tomorrow)))
          .getSingle()
          .then((r) => r.read(todayRevExpr) ?? 0.0);

      // ── Pendapatan kemarin ──────────────────────────────────────
      final yesterdayRevenue = await (db.selectOnly(db.sales)
            ..addColumns([todayRevExpr])
            ..where(db.sales.date.isBiggerOrEqualValue(yesterday) &
                db.sales.date.isSmallerThanValue(today)))
          .getSingle()
          .then((r) => r.read(todayRevExpr) ?? 0.0);

      // ── Jumlah transaksi hari ini ────────────────────────────────
      final countExpr = db.sales.id.count();
      final todayTransactions = await (db.selectOnly(db.sales)
            ..addColumns([countExpr])
            ..where(db.sales.date.isBiggerOrEqualValue(today) &
                db.sales.date.isSmallerThanValue(tomorrow)))
          .getSingle()
          .then((r) => r.read(countExpr) ?? 0);

      // ── Jumlah transaksi kemarin ────────────────────────────────
      final yesterdayTransactions = await (db.selectOnly(db.sales)
            ..addColumns([countExpr])
            ..where(db.sales.date.isBiggerOrEqualValue(yesterday) &
                db.sales.date.isSmallerThanValue(today)))
          .getSingle()
          .then((r) => r.read(countExpr) ?? 0);

      // ── Laba hari ini (revenue - harga modal item) ───────────────
      double todayModal = 0;
      final itemRows = await (db.selectOnly(db.saleItems)
            ..addColumns([
              db.saleItems.productId,
              db.saleItems.price,
              db.saleItems.quantity,
            ])
            ..join([
              innerJoin(db.sales, db.sales.id.equalsExp(db.saleItems.saleId)),
            ])
            ..where(db.sales.date.isBiggerOrEqualValue(today) &
                db.sales.date.isSmallerThanValue(tomorrow)))
          .get();
      final prices = await _productPrices(db);
      for (final row in itemRows) {
        final pid = row.read(db.saleItems.productId)!;
        todayModal += (prices[pid] ?? 0) * row.read(db.saleItems.quantity)!;
      }
      final todayProfit = todayRevenue - todayModal;

      // ── Saldo kas = total income - total expense ─────────────────
      final amountExpr = db.transactions.amount.sum();
      final income = await (db.selectOnly(db.transactions)
            ..addColumns([amountExpr])
            ..where(
                db.transactions.type.equalsValue(TransactionType.income)))
          .getSingle()
          .then((r) => r.read(amountExpr) ?? 0.0);
      final expense = await (db.selectOnly(db.transactions)
            ..addColumns([amountExpr])
            ..where(
                db.transactions.type.equalsValue(TransactionType.expense)))
          .getSingle()
          .then((r) => r.read(amountExpr) ?? 0.0);
      final cashBalance = income - expense;

      // ── Stok rendah ──────────────────────────────────────────────
      final lowProducts = await (db.select(db.products)
            ..where((p) => p.stock.isSmallerOrEqual(p.minStock))
            ..orderBy([(p) => OrderingTerm(expression: p.stock)]))
          .get();

      // ── Piutang & utang ──────────────────────────────────────────
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

      // ── Penjualan terbaru ────────────────────────────────────────
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
          paymentMethod: _toLabel(s.paymentMethod),
          date: s.date,
          itemCount: itemCount,
          customerName: s.customerId != null
              ? customerNames[s.customerId] ?? 'Pelanggan Umum'
              : 'Pelanggan Umum',
        ));
      }

      // ── Produk terlaris bulan ini ────────────────────────────────
      final topExpr = db.saleItems.quantity.sum();
      final topRows = await (db.selectOnly(db.saleItems)
            ..addColumns([db.saleItems.productId, topExpr])
            ..join([
              innerJoin(db.sales, db.sales.id.equalsExp(db.saleItems.saleId))
            ])
            ..where(db.sales.date.isBiggerOrEqualValue(monthStart) &
                db.sales.date.isSmallerThanValue(nextMonth))
            ..groupBy([db.saleItems.productId])
            ..orderBy([OrderingTerm.desc(topExpr)])
            ..limit(5))
          .get();
      final productNames = await _productNames(db);
      final topProducts = topRows.map((row) {
        final pid = row.read(db.saleItems.productId) ?? 0;
        final qty = row.read(topExpr) ?? 0;
        return DashboardSale(
          id: pid,
          invoiceNo: productNames[pid] ?? 'Produk',
          total: qty.toDouble(),
          paymentMethod: PaymentMethodLabel.cash,
          date: now,
          itemCount: qty,
        );
      }).toList();

      // ── Jumlah pelanggan ─────────────────────────────────────────
      final custExpr = db.customers.id.count();
      final customerCount = await (db.selectOnly(db.customers)
            ..addColumns([custExpr]))
          .getSingle()
          .then((r) => r.read(custExpr) ?? 0);

      // ── Total produk ─────────────────────────────────────────────
      final prodExpr = db.products.id.count();
      final totalProducts = await (db.selectOnly(db.products)
            ..addColumns([prodExpr]))
          .getSingle()
          .then((r) => r.read(prodExpr) ?? 0);

      // ── Nama bisnis dari database ────────────────────────────────
      final profile =
          await (db.select(db.businessProfiles)..limit(1)).getSingleOrNull();
      final businessName = (profile?.name.isNotEmpty == true)
          ? profile!.name
          : 'Usaha Saya';

      _data = DashboardModel(
        todayRevenue: todayRevenue,
        yesterdayRevenue: yesterdayRevenue,
        todayProfit: todayProfit,
        todayTransactions: todayTransactions,
        yesterdayTransactions: yesterdayTransactions,
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
        customerCount: customerCount,
        totalProducts: totalProducts,
        businessName: businessName,
      );
      setError(null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  PaymentMethodLabel _toLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return PaymentMethodLabel.cash;
      case PaymentMethod.qris:
        return PaymentMethodLabel.qris;
      case PaymentMethod.transfer:
        return PaymentMethodLabel.transfer;
      case PaymentMethod.debt:
        return PaymentMethodLabel.debt;
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
    return await (db.selectOnly(db.saleItems)
          ..addColumns([expr])
          ..where(db.saleItems.saleId.equals(saleId)))
        .getSingle()
        .then((r) => r.read(expr) ?? 0);
  }
}
