import 'package:drift/drift.dart' show Value;
import 'package:usahaku/database/app_database.dart';

/// Pelanggan — fitur opsional. Jika transaksi tanpa pelanggan, pakai "Pelanggan Umum".
class CustomerModel {
  final int? id;
  final String name;
  final String phone;
  final String address;

  CustomerModel({
    this.id,
    required this.name,
    this.phone = '',
    this.address = '',
  });

  CustomersCompanion toCompanion() {
    return CustomersCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      name: Value(name),
      phone: Value(phone),
      address: Value(address),
    );
  }

  factory CustomerModel.fromRow(Customer row) {
    return CustomerModel(
      id: row.id,
      name: row.name,
      phone: row.phone ?? '',
      address: row.address ?? '',
    );
  }
}

const String defaultCustomerName = 'Pelanggan Umum';
