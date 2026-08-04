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
  /// Lebar kertas struk: '58' atau '80' (mm).
  final String receiptPaperWidth;
  /// Tampilkan logo bisnis di struk.
  final bool receiptShowLogo;
  /// Tampilkan alamat & telepon bisnis di struk.
  final bool receiptShowAddress;
  /// Tampilkan QRIS pembayaran di struk.
  final bool receiptShowQris;
  /// Pesan footer struk.
  final String receiptFooter;
  /// Metode print: 'system' | 'bluetooth' | 'usb'.
  final String printerType;
  /// Alamat perangkat printer (MAC Bluetooth / path USB).
  final String? printerAddress;
  /// Nama perangkat printer.
  final String? printerName;

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
    this.receiptPaperWidth = '58',
    this.receiptShowLogo = true,
    this.receiptShowAddress = true,
    this.receiptShowQris = true,
    this.receiptFooter = '',
    this.printerType = 'system',
    this.printerAddress,
    this.printerName,
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
      receiptPaperWidth: Value(receiptPaperWidth),
      receiptShowLogo: Value(receiptShowLogo),
      receiptShowAddress: Value(receiptShowAddress),
      receiptShowQris: Value(receiptShowQris),
      receiptFooter: Value(receiptFooter.isEmpty ? null : receiptFooter),
      printerType: Value(printerType),
      printerAddress: Value(printerAddress),
      printerName: Value(printerName),
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
      receiptPaperWidth: row.receiptPaperWidth,
      receiptShowLogo: row.receiptShowLogo,
      receiptShowAddress: row.receiptShowAddress,
      receiptShowQris: row.receiptShowQris,
      receiptFooter: row.receiptFooter ?? '',
      printerType: row.printerType,
      printerAddress: row.printerAddress,
      printerName: row.printerName,
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
    String? receiptPaperWidth,
    bool? receiptShowLogo,
    bool? receiptShowAddress,
    bool? receiptShowQris,
    String? receiptFooter,
    String? printerType,
    String? Function()? printerAddress,
    String? Function()? printerName,
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
      receiptPaperWidth: receiptPaperWidth ?? this.receiptPaperWidth,
      receiptShowLogo: receiptShowLogo ?? this.receiptShowLogo,
      receiptShowAddress: receiptShowAddress ?? this.receiptShowAddress,
      receiptShowQris: receiptShowQris ?? this.receiptShowQris,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      printerType: printerType ?? this.printerType,
      printerAddress: printerAddress != null ? printerAddress() : this.printerAddress,
      printerName: printerName != null ? printerName() : this.printerName,
    );
  }
}
