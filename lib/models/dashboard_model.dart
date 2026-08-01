/// Data ringkasan untuk Dashboard — semua dari database, tidak ada nilai statis.
class DashboardModel {
  final double todayRevenue;
  final double yesterdayRevenue;   // untuk hitung % perubahan
  final double todayProfit;
  final int todayTransactions;
  final int yesterdayTransactions; // untuk hitung % perubahan transaksi
  final double cashBalance;
  final int lowStockCount;
  final List<DashboardProduct> lowStockProducts;
  final double totalReceivable;
  final int overdueReceivableCount;
  final double totalPayable;
  final int overduePayableCount;
  final List<DashboardSale> recentSales;
  final List<DashboardSale> topProducts;
  final int customerCount;
  final int totalProducts;
  final String businessName;       // dari BusinessProfiles
  final List<double> weeklyRevenue; // pendapatan 7 hari terakhir, index 0 = hari tertua
  final List<DateTime> weeklyDates; // tanggal tiap hari pada weeklyRevenue

  DashboardModel({
    this.todayRevenue = 0,
    this.yesterdayRevenue = 0,
    this.todayProfit = 0,
    this.todayTransactions = 0,
    this.yesterdayTransactions = 0,
    this.cashBalance = 0,
    this.lowStockCount = 0,
    this.lowStockProducts = const [],
    this.totalReceivable = 0,
    this.overdueReceivableCount = 0,
    this.totalPayable = 0,
    this.overduePayableCount = 0,
    this.recentSales = const [],
    this.topProducts = const [],
    this.customerCount = 0,
    this.totalProducts = 0,
    this.businessName = 'Usaha Saya',
    this.weeklyRevenue = const [],
    this.weeklyDates = const [],
  });

  /// Persentase perubahan pendapatan vs kemarin.
  /// Positif = naik, negatif = turun, null = tidak bisa dihitung (kemarin = 0).
  double? get revenueChangePercent {
    if (yesterdayRevenue == 0) return null;
    return ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;
  }

  /// Label perubahan pendapatan siap pakai di UI, misal "+12% dari kemarin".
  String get revenueChangeLabel {
    final pct = revenueChangePercent;
    if (pct == null) {
      if (todayRevenue > 0) return 'Hari pertama ada penjualan';
      return 'Belum ada penjualan';
    }
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}% dari kemarin';
  }

  /// True jika pendapatan hari ini >= kemarin.
  bool get isRevenueUp => todayRevenue >= yesterdayRevenue;
}

class DashboardProduct {
  final int id;
  final String name;
  final int stock;
  final int minStock;
  final String category;
  final String? imagePath;

  DashboardProduct({
    required this.id,
    required this.name,
    required this.stock,
    required this.minStock,
    this.category = '',
    this.imagePath,
  });
}

class DashboardSale {
  final int id;
  final String invoiceNo;
  final double total;
  final PaymentMethodLabel paymentMethod;
  final DateTime date;
  final int itemCount;
  final String customerName;

  DashboardSale({
    required this.id,
    required this.invoiceNo,
    required this.total,
    required this.paymentMethod,
    required this.date,
    this.itemCount = 0,
    this.customerName = 'Pelanggan Umum',
  });
}

enum PaymentMethodLabel { cash, qris, transfer, debt }

extension PaymentMethodLabelX on PaymentMethodLabel {
  String get label {
    switch (this) {
      case PaymentMethodLabel.cash:
        return 'Tunai';
      case PaymentMethodLabel.qris:
        return 'QRIS';
      case PaymentMethodLabel.transfer:
        return 'Transfer';
      case PaymentMethodLabel.debt:
        return 'Hutang';
    }
  }
}
