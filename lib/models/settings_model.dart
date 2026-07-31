import 'package:drift/drift.dart' show Value;
import 'package:usahaku/database/app_database.dart';

/// Profil bisnis + pengaturan aplikasi.
class SettingsModel {
  final int? id;
  final String businessName;
  final String owner;
  final String phone;
  final String address;
  final String npwp;
  final String currency;
  final String theme;
  final String? qrisImagePath;
  final String? logoPath;

  SettingsModel({
    this.id,
    this.businessName = 'Usaha Saya',
    this.owner = '',
    this.phone = '',
    this.address = '',
    this.npwp = '',
    this.currency = 'IDR',
    this.theme = 'light',
    this.qrisImagePath,
    this.logoPath,
  });

  BusinessProfilesCompanion toCompanion() {
    return BusinessProfilesCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      name: Value(businessName),
      owner: Value(owner),
      phone: Value(phone),
      address: Value(address),
      npwp: Value(npwp),
      currency: Value(currency),
      theme: Value(theme),
      qrisImagePath: Value(qrisImagePath),
      logoPath: Value(logoPath),
    );
  }

  factory SettingsModel.fromRow(BusinessProfile row) {
    return SettingsModel(
      id: row.id,
      businessName: row.name,
      owner: row.owner ?? '',
      phone: row.phone ?? '',
      address: row.address ?? '',
      npwp: row.npwp ?? '',
      currency: row.currency,
      theme: row.theme,
      qrisImagePath: row.qrisImagePath,
      logoPath: row.logoPath,
    );
  }

  SettingsModel copyWith({
    int? id,
    String? businessName,
    String? owner,
    String? phone,
    String? address,
    String? npwp,
    String? currency,
    String? theme,
    String? Function()? qrisImagePath,
    String? Function()? logoPath,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      owner: owner ?? this.owner,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      npwp: npwp ?? this.npwp,
      currency: currency ?? this.currency,
      theme: theme ?? this.theme,
      qrisImagePath: qrisImagePath != null ? qrisImagePath() : this.qrisImagePath,
      logoPath: logoPath != null ? logoPath() : this.logoPath,
    );
  }
}
