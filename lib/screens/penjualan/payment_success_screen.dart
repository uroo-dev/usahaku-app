import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/database/db.dart';
import 'package:usahaku/models/sale_model.dart';
import 'package:usahaku/models/settings_model.dart';
import 'package:usahaku/screens/penjualan/invoice_detail_screen.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';
import 'package:usahaku/utils/receipt_printer.dart';

/// Halaman sukses pembayaran dengan animasi tenang + suara cengkereng.
class PaymentSuccessScreen extends StatefulWidget {
  final SaleModel sale;
  const PaymentSuccessScreen({super.key, required this.sale});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  // Animasi scale untuk ikon centang
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  // Satu gelombang lembut yang memudar (tidak berulang)
  late final AnimationController _pulseCtrl;

  static const MethodChannel _channel =
      MethodChannel('id.uroo.usahaku/audio');

  @override
  void initState() {
    super.initState();

    // --- Scale pop-in untuk lingkaran ikon ---
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleCtrl,
      curve: Curves.elasticOut,
    );

    // --- Satu gelombang lembut (forward sekali saja) ---
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Mulai animasi scale + play suara setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaleCtrl.forward();
      _pulseCtrl.forward();
      _playSuccessSound();
    });
  }

  /// Suara "cengkereng" dari res/raw/cha_ching.mp3 via native.
  void _playSuccessSound() {
    try {
      _channel.invokeMethod('playSuccess');
    } catch (_) {
      // Abaikan jika native tidak mendukung — transaksi tetap selesai.
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _done(BuildContext context) {
    Navigator.of(context).pop(true);
  }

  Future<void> _printReceipt() async {
    try {
      final db = DB.instance;
      final rows = await db.select(db.businessProfiles).get();
      final settings = rows.isEmpty ? SettingsModel() : SettingsModel.fromRow(rows.first);
      await ReceiptPrinter.printReceipt(
        sale: widget.sale,
        settings: settings,
        onStatus: (msg) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencetak: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _done(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Lingkaran sonar + ikon centang
                _pulseIcon(),
                const SizedBox(height: 24),
                const Text(
                  'Pembayaran Berhasil',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColor.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.sale.invoiceNo} • ${FormatUtil.date(widget.sale.date)} ${FormatUtil.time(widget.sale.date)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColor.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                _receipt(),
                const SizedBox(height: 24),
                // Tombol aksi
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () => _done(context),
                    icon: const Icon(Icons.add_shopping_cart, size: 20),
                    label: const Text('Transaksi Baru'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _printReceipt,
                    icon: const Icon(Icons.print_outlined, size: 20),
                    label: const Text('Cetak Struk'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              InvoiceDetailScreen(sale: widget.sale),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_outlined, size: 20),
                    label: const Text('Lihat Detail Invoice'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton.icon(
                    onPressed: () => _done(context),
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('Selesai'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget lingkaran dengan satu gelombang lembut memudar + ikon centang.
  Widget _pulseIcon() {
    const double iconSize = 96;
    const double maxPulse = iconSize + 56; // radius maksimal gelombang

    return SizedBox(
      width: maxPulse,
      height: maxPulse,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Satu gelombang lembut yang membesar lalu memudar (sekali saja)
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) {
              final t = _pulseCtrl.value; // 0.0 → 1.0
              final size = iconSize + (maxPulse - iconSize) * t;
              final opacity = 0.25 * (1.0 - t);
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.successContainer.withValues(
                      alpha: opacity.clamp(0.0, 1.0)),
                ),
              );
            },
          ),
          // Lingkaran utama + ikon — scale pop-in
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: AppColor.successContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColor.success.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColor.onSuccessContainer,
                size: 56,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receipt() {
    final sale = widget.sale;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColor.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Pesanan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColor.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (sale.items.isNotEmpty) ...[
            ...sale.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColor.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${item.quantity}x',
                      style: const TextStyle(
                          fontSize: 13, color: AppColor.onSurfaceVariant),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      FormatUtil.rupiah(item.total),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColor.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
          ],
          _row('Subtotal', FormatUtil.rupiah(sale.subtotal)),
          if (sale.discount > 0)
            _row('Diskon', '- ${FormatUtil.rupiah(sale.discount)}'),
          const Divider(height: 16),
          _row('Total', FormatUtil.rupiah(sale.total), bold: true),
          _row('Metode', sale.paymentMethodLabel),
          if (sale.paymentMethod == PaymentMethod.cash) ...[
            _row('Dibayar', FormatUtil.rupiah(sale.paidAmount)),
            if (sale.changeAmount >= 0)
              _row(
                'Kembalian',
                FormatUtil.rupiah(sale.changeAmount),
                valueColor: AppColor.green700,
              )
            else
              _row(
                'Piutang',
                FormatUtil.rupiah(-sale.changeAmount),
                valueColor: AppColor.error,
              ),
          ],
          if (sale.customerName.isNotEmpty &&
              sale.customerName != 'Pelanggan Umum')
            _row('Pelanggan', sale.customerName),
          if (sale.notes != null && sale.notes!.isNotEmpty)
            _row('Catatan', sale.notes!),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColor.onSurfaceVariant)),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: valueColor ?? AppColor.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
