import 'dart:io';

import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:usahaku/controllers/settings_controller.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/models/sale_model.dart';
import 'package:usahaku/models/settings_model.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/receipt_printer.dart';

/// Pengaturan cetak struk — lebar kertas, metode printer, dan isi struk.
class PrintStrukScreen extends StatefulWidget {
  final SettingsController controller;
  const PrintStrukScreen({super.key, required this.controller});

  @override
  State<PrintStrukScreen> createState() => _PrintStrukScreenState();
}

class _PrintStrukScreenState extends State<PrintStrukScreen> {
  late String _paperWidth;
  late String _printerType;
  late bool _showLogo;
  late bool _showAddress;
  late bool _showQris;
  late final TextEditingController _footerCtrl;
  String? _printerAddress;
  String? _printerName;

  bool _saving = false;
  bool _scanning = false;
  List<BluetoothInfo> _devices = [];

  SettingsController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    final s = c.settings;
    _paperWidth = s.receiptPaperWidth;
    _printerType = s.printerType;
    _showLogo = s.receiptShowLogo;
    _showAddress = s.receiptShowAddress;
    _showQris = s.receiptShowQris;
    _footerCtrl = TextEditingController(text: s.receiptFooter);
    _printerAddress = s.printerAddress;
    _printerName = s.printerName;
  }

  @override
  void dispose() {
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await c.save(SettingsModel(
        id: c.settings.id,
        businessName: c.settings.businessName,
        owner: c.settings.owner,
        phone: c.settings.phone,
        address: c.settings.address,
        npwp: c.settings.npwp,
        currency: c.settings.currency,
        theme: c.settings.theme,
        qrisImagePath: c.settings.qrisImagePath,
        logoPath: c.settings.logoPath,
        receiptPaperWidth: _paperWidth,
        receiptShowLogo: _showLogo,
        receiptShowAddress: _showAddress,
        receiptShowQris: _showQris,
        receiptFooter: _footerCtrl.text.trim(),
        printerType: _printerType,
        printerAddress: _printerAddress,
        printerName: _printerName,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan print struk tersimpan')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _scanBluetooth() async {
    setState(() => _scanning = true);
    try {
      if (Platform.isAndroid) {
        final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin Bluetooth belum diberikan')),
            );
          }
          setState(() => _scanning = false);
          return;
        }
      }
      final enabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!enabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nyalakan Bluetooth terlebih dahulu')),
          );
        }
        setState(() => _scanning = false);
        return;
      }
      final devices = await PrintBluetoothThermal.pairedBluetooths;
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _scanning = false;
      });
      if (devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada perangkat Bluetooth terpasang. Pasangkan printer lewat pengaturan Bluetooth perangkat Anda.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _scanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memindai Bluetooth: $e')),
        );
      }
    }
  }

  Future<void> _selectDevice(BluetoothInfo device) async {
    setState(() {
      _printerAddress = device.macAdress;
      _printerName = device.name;
      _printerType = 'bluetooth';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printer dipilih: ${device.name}')),
      );
    }
  }

  /// Cetak struk uji (dummy) untuk memastikan printer bekerja.
  Future<void> _testPrint() async {
    final now = DateTime.now();
    final testSale = SaleModel(
      invoiceNo: 'TEST-PRINT',
      date: now,
      subtotal: 25000,
      discount: 0,
      total: 25000,
      paidAmount: 25000,
      paymentMethod: PaymentMethod.cash,
      customerName: 'Pelanggan Umum',
      items: [
        SaleItemModel(
          productId: 0,
          productName: 'Test Produk',
          quantity: 1,
          price: 25000,
          total: 25000,
        ),
      ],
    );
    final settings = SettingsModel(
      businessName: c.settings.businessName,
      owner: c.settings.owner,
      phone: c.settings.phone,
      address: c.settings.address,
      qrisImagePath: c.settings.qrisImagePath,
      logoPath: c.settings.logoPath,
      receiptPaperWidth: _paperWidth,
      receiptShowLogo: _showLogo,
      receiptShowAddress: _showAddress,
      receiptShowQris: _showQris,
      receiptFooter: _footerCtrl.text.trim(),
      printerType: _printerType,
      printerAddress: _printerAddress,
      printerName: _printerName,
    );
    try {
      await ReceiptPrinter.printReceipt(
        sale: testSale,
        settings: settings,
        onStatus: (msg) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
            );
          }
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print uji terkirim')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print uji gagal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Print Struk')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _infoBanner(),
            const SizedBox(height: 20),
            _sectionLabel('Metode Printer'),
            const SizedBox(height: 8),
            _card([
              _radioOption(
                value: 'system',
                groupValue: _printerType,
                icon: Icons.print_outlined,
                title: 'Cetak Sistem / PDF',
                subtitle: 'Muncul dialog print Android — bisa simpan PDF atau kirim ke printer WiFi/kabel lewat layanan print',
                onChanged: (v) => setState(() => _printerType = v!),
              ),
              _radioOption(
                value: 'bluetooth',
                groupValue: _printerType,
                icon: Icons.bluetooth_connected,
                title: 'Printer Bluetooth',
                subtitle: 'Cetak langsung ke printer thermal nota 58/80mm',
                onChanged: (v) => setState(() => _printerType = v!),
              ),
            ]),
            if (_printerType == 'bluetooth') ...[
              const SizedBox(height: 12),
              _bluetoothSection(),
            ],
            const SizedBox(height: 20),
            _sectionLabel('Ukuran Kertas'),
            const SizedBox(height: 8),
            _card([
              _radioOption(
                value: '58',
                groupValue: _paperWidth,
                icon: Icons.receipt_long_outlined,
                title: 'Struk 58mm',
                subtitle: 'Printer thermal kecil standar (2 inch)',
                onChanged: (v) => setState(() => _paperWidth = v!),
              ),
              _radioOption(
                value: '80',
                groupValue: _paperWidth,
                icon: Icons.receipt_outlined,
                title: 'Struk 80mm',
                subtitle: 'Printer thermal lebar (3 inch)',
                onChanged: (v) => setState(() => _paperWidth = v!),
              ),
            ]),
            const SizedBox(height: 20),
            _sectionLabel('Isi Struk'),
            const SizedBox(height: 8),
            _card([
              SwitchListTile(
                value: _showLogo,
                onChanged: (v) => setState(() => _showLogo = v),
                activeThumbColor: AppColor.primary,
                title: const Text('Tampilkan Logo',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Logo bisnis di bagian atas struk',
                    style: TextStyle(fontSize: 12)),
              ),
              SwitchListTile(
                value: _showAddress,
                onChanged: (v) => setState(() => _showAddress = v),
                activeThumbColor: AppColor.primary,
                title: const Text('Tampilkan Alamat & Telepon',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Alamat dan nomor telepon bisnis',
                    style: TextStyle(fontSize: 12)),
              ),
              SwitchListTile(
                value: _showQris,
                onChanged: (v) => setState(() => _showQris = v),
                activeThumbColor: AppColor.primary,
                title: const Text('Tampilkan QRIS',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Gambar QRIS di bagian bawah struk',
                    style: TextStyle(fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 20),
            _sectionLabel('Pesan Footer'),
            const SizedBox(height: 8),
            _card([
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _footerCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Pesan footer',
                    hintText: 'contoh: Barang yang sudah dibeli tidak dapat dikembalikan',
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined, size: 20),
                label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _testPrint,
                icon: const Icon(Icons.print_outlined, size: 20),
                label: const Text('Cetak Uji'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.print_outlined, size: 20, color: AppColor.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Atur tampilan struk yang dicetak dari invoice. Pilih metode printer, ukuran kertas, dan isi yang ingin ditampilkan.',
              style: TextStyle(fontSize: 13, color: AppColor.onPrimaryContainer, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bluetoothSection() {
    final connected = _printerAddress != null;
    return _card([
      if (connected)
        ListTile(
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColor.green50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle, color: AppColor.green700, size: 22),
          ),
          title: Text(_printerName ?? 'Printer terhubung',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(_printerAddress ?? '',
              style: const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant)),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() {
              _printerAddress = null;
              _printerName = null;
            }),
          ),
        ),
      if (!connected)
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Belum ada printer dipilih',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.onSurfaceVariant),
          ),
        ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _scanning ? null : _scanBluetooth,
            icon: _scanning
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth_searching, size: 20),
            label: Text(_scanning ? 'Memindai...' : 'Cari Printer Bluetooth'),
          ),
        ),
      ),
      if (_devices.isNotEmpty)
        ..._devices.map(
          (d) => ListTile(
            dense: true,
            leading: const Icon(Icons.bluetooth, size: 20, color: AppColor.primary),
            title: Text(d.name, style: const TextStyle(fontSize: 13)),
            subtitle: Text(d.macAdress, style: const TextStyle(fontSize: 11, color: AppColor.onSurfaceVariant)),
            trailing: _printerAddress == d.macAdress
                ? const Icon(Icons.check_circle, color: AppColor.green700, size: 18)
                : null,
            onTap: () => _selectDevice(d),
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Text(
          'Tips: pastikan printer sudah dipasangkan (pairing) lewat pengaturan Bluetooth perangkat sebelum dicari di sini.',
          style: TextStyle(fontSize: 11, color: AppColor.onSurfaceVariant.withValues(alpha: 0.9)),
        ),
      ),
    ]);
  }

  Widget _radioOption({
    required String value,
    required String groupValue,
    required IconData icon,
    required String title,
    required String subtitle,
    required ValueChanged<String?> onChanged,
  }) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? AppColor.primaryContainer
                    : AppColor.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: selected ? AppColor.primary : AppColor.outline),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant)),
                ],
              ),
            ),
            RadioGroup<String>(
              groupValue: groupValue,
              onChanged: onChanged,
              child: Radio<String>(value: value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.primary),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(children: children),
    );
  }
}
