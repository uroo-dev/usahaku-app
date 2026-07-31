import 'package:drift/drift.dart' show Value;
import 'package:usahaku/database/app_database.dart';

/// Model produk (membungkus data Drift).
class ProductModel {
  final int? id;
  final String name;
  final String barcode;
  final int? categoryId;
  final String categoryName;
  final double purchasePrice;
  final double sellPrice;
  final int stock;
  final int minStock;
  final String unit;
  final String? imagePath;
  final String? description;

  ProductModel({
    this.id,
    required this.name,
    this.barcode = '',
    this.categoryId,
    this.categoryName = 'Umum',
    this.purchasePrice = 0.0,
    this.sellPrice = 0.0,
    this.stock = 0,
    this.minStock = 5,
    this.unit = 'pcs',
    this.imagePath,
    this.description,
  });

  bool get isLowStock => stock <= minStock && stock > 0;
  bool get isOutOfStock => stock <= 0;

  String get statusLabel {
    if (isOutOfStock) return 'Habis';
    if (isLowStock) return 'Menipis';
    return 'Tersedia';
  }

  ProductsCompanion toCompanion() {
    return ProductsCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      name: Value(name),
      barcode: Value(barcode),
      categoryId: Value(categoryId),
      purchasePrice: Value(purchasePrice),
      sellPrice: Value(sellPrice),
      stock: Value(stock),
      minStock: Value(minStock),
      unit: Value(unit),
      imagePath: Value(imagePath),
      description: Value(description),
    );
  }

  factory ProductModel.fromRow(Product row, {String categoryName = 'Umum'}) {
    return ProductModel(
      id: row.id,
      name: row.name,
      barcode: row.barcode ?? '',
      categoryId: row.categoryId,
      categoryName: categoryName,
      purchasePrice: row.purchasePrice,
      sellPrice: row.sellPrice,
      stock: row.stock,
      minStock: row.minStock,
      unit: row.unit,
      imagePath: row.imagePath,
      description: row.description,
    );
  }
}
