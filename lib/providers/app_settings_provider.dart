import 'package:flutter/material.dart';
import 'package:usahaku/database/db.dart';
import 'package:usahaku/models/settings_model.dart';

/// Notifier global untuk data settings yang dipakai di seluruh app.
/// Load satu kali saat startup, rebuild otomatis saat refresh dipanggil.
class AppSettingsNotifier extends ChangeNotifier {
  SettingsModel _settings = SettingsModel();
  bool _loaded = false;

  SettingsModel get settings => _settings;
  bool get loaded => _loaded;

  String get businessName =>
      _settings.businessName.isNotEmpty ? _settings.businessName : 'Usaha Saya';
  String get ownerName => _settings.owner;
  String get phone => _settings.phone;
  String get address => _settings.address;

  Future<void> load() async {
    try {
      final db = DB.instance;
      final rows = await db.select(db.businessProfiles).get();
      if (rows.isNotEmpty) {
        _settings = SettingsModel.fromRow(rows.first);
      }
      _loaded = true;
      notifyListeners();
    } catch (_) {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Dipanggil setelah save settings agar seluruh UI langsung update.
  void refresh() => load();
}

/// InheritedWidget pembungkus — dipasang di atas MaterialApp.
class AppSettingsProvider extends InheritedNotifier<AppSettingsNotifier> {
  const AppSettingsProvider({
    super.key,
    required AppSettingsNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Ambil notifier; widget yang memanggil ini akan rebuild saat data berubah.
  static AppSettingsNotifier of(BuildContext context) {
    final w = context
        .dependOnInheritedWidgetOfExactType<AppSettingsProvider>();
    assert(w != null, 'AppSettingsProvider tidak ada di widget tree');
    return w!.notifier!;
  }

  /// Shortcut paling sering dipakai.
  static String businessNameOf(BuildContext context) =>
      of(context).businessName;
}
