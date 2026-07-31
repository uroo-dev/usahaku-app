import 'package:flutter/material.dart';
import 'package:usahaku/models/sale_model.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';

/// Halaman sukses pembayaran — sesuai pembayaran-success.html.
/// Menampilkan detail struk + opsi cetak struk / transaksi baru.
class PaymentSuccessScreen extends StatelessWidget {
  final SaleModel sale;
  const PaymentSuccessScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Cegah back gesture langsung — harus lewat tombol agar result terbawa
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _done(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                      color: AppColor.successContainer, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: AppColor.onSuccessContainer, size: 56),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pembayaran Berhasil',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColor.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  '${sale.invoiceNo} • ${FormatUtil.date(sale.date)} ${FormatUtil.time(sale.date)}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColor.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                _receipt(context),
                const Spacer(),
                // Transaksi Baru — pop semua sampai SalesScreen, bawa result true
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () => _done(context),
                    icon: const Icon(Icons.add_shopping_cart, size: 20),
                    label: const Text('Transaksi Baru'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
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

  /// Pop sampai SalesScreen (route pertama di stack HomeScreen) sambil
  /// membawa result = true agar SalesScreen reload stok produk.
  void _done(BuildContext context) {
    // Pop CheckoutScreen (result true) → Pop akan sampai ke SalesScreen
    // CheckoutScreen pakai pushReplacement, jadi stack: HomeScreen → CheckoutScreen → PaymentSuccessScreen
    // Kita pop dua kali: pertama PaymentSuccessScreen, lalu CheckoutScreen → kembali ke SalesScreen
    Navigator.of(context).pop(true); // pop PaymentSuccessScreen → CheckoutScreen sudah diganti
  }

  Widget _receipt(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColor.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Pembayaran',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColor.onSurface),
          ),
          const SizedBox(height: 16),
          _row('Subtotal', FormatUtil.rupiah(sale.subtotal)),
          if (sale.discount > 0)
            _row('Diskon', '- ${FormatUtil.rupiah(sale.discount)}'),
          _row('Total', FormatUtil.rupiah(sale.total)),
          _row('Metode', sale.paymentMethodLabel),
          if (sale.notes != null && sale.notes!.isNotEmpty)
            _row('Catatan', sale.notes!),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColor.onSurfaceVariant)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColor.onSurface)),
        ],
      ),
    );
  }
}
