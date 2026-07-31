/// Data ringkasan untuk Dashboard.
class DashboardModel {
  final double todayRevenue;
  final double todayProfit;
  final int todayTransactions;
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

  DashboardModel({
    this.todayRevenue = 0,
    this.todayProfit = 0,
    this.todayTransactions = 0,
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
  });
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
