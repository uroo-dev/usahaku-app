import 'package:drift/drift.dart' show Value;
import 'package:usahaku/database/app_database.dart';

/// Supplier / pemasok — fitur opsional.
class SupplierModel {
  final int? id;
  final String name;
  final String phone;
  final String address;

  SupplierModel({
    this.id,
    required this.name,
    this.phone = '',
    this.address = '',
  });

  SuppliersCompanion toCompanion() {
    return SuppliersCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      name: Value(name),
      phone: Value(phone),
      address: Value(address),
    );
  }

  factory SupplierModel.fromRow(Supplier row) {
    return SupplierModel(
      id: row.id,
      name: row.name,
      phone: row.phone ?? '',
      address: row.address ?? '',
    );
  }
}
