import 'dart:io';

import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:printing/printing.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/models/sale_model.dart';
import 'package:usahaku/models/settings_model.dart';
import 'package:usahaku/utils/format_util.dart';

/// Pencetak struk invoice.
///
/// Mendukung dua metode (dipilih lewat Pengaturan → Print Struk):
/// - `system`  → print ke dialog sistem Android (Save as PDF, printer WiFi/kabel
///               lewat layanan print yang terpasang) dan browser print di web.
/// - `bluetooth` → print langsung ke printer thermal nota 58/80mm via Bluetooth.
class ReceiptPrinter {
  // Tinggi halaman struk (pt) — printer thermal memotong sesuai isi.
  static const double _kPageHeight = 1600;

  /// Cetak struk invoice sesuai pengaturan.
  ///
  /// [onStatus] dipanggil untuk memberi umpan balik selama proses (mis. snackbar).
  static Future<void> printReceipt({
    required SaleModel sale,
    required SettingsModel settings,
    void Function(String message)? onStatus,
  }) async {
    if (settings.printerType == 'bluetooth') {
      await _printBluetooth(sale, settings, onStatus);
    } else {
      await _printPdf(sale, settings);
    }
  }

  // ---------------------------------------------------------------------------
  // Print via sistem (PDF / printer jaringan / layanan print Android)
  // ---------------------------------------------------------------------------

  static Future<void> _printPdf(SaleModel sale, SettingsModel s) async {
    final doc = pw.Document();
    final pageFormat = _thermalPageFormat(s.receiptPaperWidth);
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) => _pdfReceipt(sale, s),
      ),
    );
    await Printing.layoutPdf(
      name: sale.invoiceNo,
      format: pageFormat,
      onLayout: (format) => doc.save(),
    );
  }

  static PdfPageFormat _thermalPageFormat(String width) {
    // 58mm ≈ 164 pt, 80mm ≈ 227 pt
    final w = width == '80' ? 227.0 : 164.0;
    return PdfPageFormat(w, _kPageHeight, marginAll: 0);
  }

  static pw.Widget _pdfReceipt(SaleModel sale, SettingsModel s) {
    final contents = <pw.Widget>[];

    // Header usaha
    contents.add(pw.Center(
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (s.receiptShowLogo && s.logoPath != null && File(s.logoPath!).existsSync())
            pw.Image(
              pw.MemoryImage(File(s.logoPath!).readAsBytesSync()),
              width: 40,
              height: 40,
              fit: pw.BoxFit.contain,
            ),
          if (s.logoPath != null && File(s.logoPath!).existsSync())
            pw.SizedBox(height: 3),
          pw.Text(
            s.businessName,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          if (s.receiptShowAddress) ...[
            if (s.address.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 1),
                child: pw.Text(
                  s.address,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
            if (s.phone.isNotEmpty)
              pw.Text(
                s.phone,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 7),
              ),
          ],
        ],
      ),
    ));
    contents.add(pw.SizedBox(height: 4));
    contents.add(_pdfDivider());

    // Info invoice
    contents.add(_pdfInfoRow('Invoice', sale.invoiceNo));
    contents.add(_pdfInfoRow('Tanggal', FormatUtil.dateTime(sale.date)));
    if (sale.customerName.isNotEmpty && sale.customerName != 'Pelanggan Umum') {
      contents.add(_pdfInfoRow('Pelanggan', sale.customerName));
    }
    contents.add(_pdfInfoRow('Kasir', s.owner.isNotEmpty ? s.owner : '-'));
    contents.add(_pdfInfoRow('Metode', sale.paymentMethodLabel));
    contents.add(_pdfDivider());

    // Item
    for (final item in sale.items) {
      contents.add(_pdfItemRow(item));
    }
    contents.add(_pdfDivider());

    // Ringkasan
    contents.add(_pdfInfoRow('Subtotal', FormatUtil.rupiah(sale.subtotal)));
    if (sale.discount > 0) {
      contents.add(_pdfInfoRow('Diskon', '- ${FormatUtil.rupiah(sale.discount)}'));
    }
    contents.add(_pdfInfoRow('TOTAL', FormatUtil.rupiah(sale.total), bold: true));
    if (sale.paymentMethod == PaymentMethod.cash) {
      contents.add(_pdfInfoRow('Dibayar', FormatUtil.rupiah(sale.paidAmount)));
      if (sale.changeAmount >= 0) {
        contents.add(_pdfInfoRow('Kembalian', FormatUtil.rupiah(sale.changeAmount)));
      } else {
        contents.add(_pdfInfoRow('Sisa Piutang', FormatUtil.rupiah(-sale.changeAmount)));
      }
    }
    if (sale.notes != null && sale.notes!.isNotEmpty) {
      contents.add(_pdfInfoRow('Catatan', sale.notes!));
    }

    // QRIS (jika diaktifkan & tersedia)
    if (s.receiptShowQris && s.qrisImagePath != null && File(s.qrisImagePath!).existsSync()) {
      contents.add(pw.SizedBox(height: 4));
      contents.add(pw.Center(
        child: pw.Image(
          pw.MemoryImage(File(s.qrisImagePath!).readAsBytesSync()),
          width: 46,
          height: 46,
          fit: pw.BoxFit.contain,
        ),
      ));
      contents.add(pw.Center(
        child: pw.Text('Scan untuk pembayaran',
            style: const pw.TextStyle(fontSize: 6)),
      ));
    }

    // Footer
    if (s.receiptFooter.isNotEmpty) {
      contents.add(pw.SizedBox(height: 4));
      contents.add(_pdfDivider());
      contents.add(pw.Text(
        s.receiptFooter,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 7),
      ));
    }

    contents.add(pw.SizedBox(height: 6));
    contents.add(pw.Text(
      'Terima kasih atas kunjungan Anda',
      textAlign: pw.TextAlign.center,
      style: const pw.TextStyle(fontSize: 6),
    ));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      mainAxisSize: pw.MainAxisSize.min,
      children: contents,
    );
  }

  static pw.Widget _pdfDivider() {
    return pw.Divider(height: 6, thickness: 0.6, color: PdfColors.grey600);
  }

  static pw.Widget _pdfInfoRow(String label, String value, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
        ),
      ],
    );
  }

  static pw.Widget _pdfItemRow(SaleItemModel item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.productName,
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${item.quantity} x ${FormatUtil.rupiah(item.price)}',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.Text(
                FormatUtil.rupiah(item.total),
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Print langsung ke printer thermal nota via Bluetooth
  // ---------------------------------------------------------------------------

  static Future<void> _printBluetooth(
    SaleModel sale,
    SettingsModel s,
    void Function(String message)? onStatus,
  ) async {
    final address = s.printerAddress;
    if (address == null || address.isEmpty) {
      throw Exception('Belum ada printer Bluetooth dipilih di Pengaturan → Print Struk');
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(
      s.receiptPaperWidth == '80' ? PaperSize.mm80 : PaperSize.mm58,
      profile,
    );

    List<int> bytes = <int>[];
    bytes += generator.text(
      s.businessName,
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    if (s.receiptShowAddress && s.address.isNotEmpty) {
      bytes += generator.text(s.address, styles: PosStyles(align: PosAlign.center));
    }
    if (s.receiptShowAddress && s.phone.isNotEmpty) {
      bytes += generator.text(s.phone, styles: PosStyles(align: PosAlign.center));
    }
    bytes += generator.text('', styles: const PosStyles());
    bytes += generator.hr();

    bytes += _escInfo(generator, 'Invoice', sale.invoiceNo);
    bytes += _escInfo(generator, 'Tanggal', FormatUtil.dateTime(sale.date));
    if (sale.customerName.isNotEmpty && sale.customerName != 'Pelanggan Umum') {
      bytes += _escInfo(generator, 'Pelanggan', sale.customerName);
    }
    bytes += _escInfo(generator, 'Metode', sale.paymentMethodLabel);
    bytes += generator.hr();

    for (final item in sale.items) {
      bytes += generator.text(
        item.productName,
        styles: PosStyles(bold: true),
      );
      bytes += generator.row([
        PosColumn(
          text: '${item.quantity} x ${FormatUtil.rupiah(item.price)}',
          width: 12,
          styles: const PosStyles(),
        ),
        PosColumn(
          text: FormatUtil.rupiah(item.total),
          width: 12,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    bytes += generator.hr();

    bytes += _escInfo(generator, 'Subtotal', FormatUtil.rupiah(sale.subtotal));
    if (sale.discount > 0) {
      bytes += _escInfo(generator, 'Diskon', '- ${FormatUtil.rupiah(sale.discount)}');
    }
    bytes += _escInfo(generator, 'TOTAL', FormatUtil.rupiah(sale.total), bold: true);
    if (sale.paymentMethod == PaymentMethod.cash) {
      bytes += _escInfo(generator, 'Dibayar', FormatUtil.rupiah(sale.paidAmount));
      if (sale.changeAmount >= 0) {
        bytes += _escInfo(generator, 'Kembalian', FormatUtil.rupiah(sale.changeAmount));
      } else {
        bytes += _escInfo(generator, 'Piutang', FormatUtil.rupiah(-sale.changeAmount));
      }
    }
    if (sale.notes != null && sale.notes!.isNotEmpty) {
      bytes += _escInfo(generator, 'Catatan', sale.notes!);
    }

    if (s.receiptFooter.isNotEmpty) {
      bytes += generator.text('');
      bytes += generator.text(s.receiptFooter, styles: PosStyles(align: PosAlign.center));
    }
    bytes += generator.text('');
    bytes += generator.text(
      'Terima kasih atas kunjungan Anda',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    onStatus?.call('Menghubungkan printer Bluetooth...');
    final connected = await PrintBluetoothThermal.connect(macPrinterAddress: address);
    if (!connected) {
      throw Exception('Gagal terhubung ke printer Bluetooth');
    }
    try {
      onStatus?.call('Mencetak struk...');
      final ok = await PrintBluetoothThermal.writeBytes(bytes);
      if (!ok) {
        throw Exception('Gagal mengirim data ke printer');
      }
    } finally {
      await PrintBluetoothThermal.disconnect;
    }
  }

  static List<int> _escInfo(
    Generator gen,
    String label,
    String value, {
    bool bold = false,
  }) {
    return gen.row([
      PosColumn(
        text: label,
        width: 6,
        styles: const PosStyles(),
      ),
      PosColumn(
        text: value,
        width: 18,
        styles: PosStyles(align: PosAlign.right, bold: bold),
      ),
    ]);
  }
}
