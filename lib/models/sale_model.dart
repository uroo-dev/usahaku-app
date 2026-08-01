import 'package:drift/drift.dart' show Value;
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/models/customer_model.dart' show defaultCustomerName;

/// Header penjualan (POS).
class SaleModel {
  final int? id;
  final String invoiceNo;
  final int? customerId;
  final String customerName;
  final double subtotal;
  final double discount;
  final double total;
  final double paidAmount; // jumlah yang dibayar (cash)
  final PaymentMethod paymentMethod;
  final String? notes;
  final DateTime date;
  final List<SaleItemModel> items;

  SaleModel({
    this.id,
    required this.invoiceNo,
    this.customerId,
    this.customerName = defaultCustomerName,
    this.subtotal = 0,
    this.discount = 0,
    this.total = 0,
    this.paidAmount = 0,
    this.paymentMethod = PaymentMethod.cash,
    this.notes,
    required this.date,
    this.items = const [],
  });

  double get profit {
    final modal = items.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
    return total - modal;
  }

  double get changeAmount => paidAmount - total; // positif = kembalian, negatif = sisa hutang

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Tunai';
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.transfer:
        return 'Transfer';
      case PaymentMethod.debt:
        return 'Hutang';
    }
  }

  factory SaleModel.fromRow(
    Sale row, {
    String customerName = defaultCustomerName,
    List<SaleItemModel> items = const [],
  }) {
    return SaleModel(
      id: row.id,
      invoiceNo: row.invoiceNo,
      customerId: row.customerId,
      customerName: customerName,
      subtotal: row.subtotal,
      discount: row.discount,
      total: row.total,
      paymentMethod: row.paymentMethod,
      notes: row.notes,
      date: row.date,
      items: items,
    );
  }
}

/// Item dalam penjualan.
class SaleItemModel {
  final int? id;
  final int? saleId;
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final double total;

  SaleItemModel({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  SaleItemsCompanion toCompanion() {
    return SaleItemsCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      saleId: saleId != null ? Value(saleId!) : const Value.absent(),
      productId: Value(productId),
      quantity: Value(quantity),
      price: Value(price),
      total: Value(total),
    );
  }

  factory SaleItemModel.fromRow(SaleItem row, {String productName = ''}) {
    return SaleItemModel(
      id: row.id,
      saleId: row.saleId,
      productId: row.productId,
      productName: productName,
      quantity: row.quantity,
      price: row.price,
      total: row.total,
    );
  }
}

