import 'package:flutter/material.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/models/sale_model.dart';
import 'package:usahaku/screens/penjualan/invoice_detail_screen.dart';
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InvoiceDetailScreen(sale: sale),
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
            'Rincian Pesanan',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColor.onSurface),
          ),
          const SizedBox(height: 12),
          // Daftar item
          if (sale.items.isNotEmpty) ...[
            ...sale.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(fontSize: 13, color: AppColor.onSurface, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${item.quantity}x',
                        style: const TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        FormatUtil.rupiah(item.total),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.onSurface),
                      ),
                    ],
                  ),
                )),
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
              _row('Kembalian', FormatUtil.rupiah(sale.changeAmount), valueColor: AppColor.green700)
            else
              _row('Piutang', FormatUtil.rupiah(-sale.changeAmount), valueColor: AppColor.error),
          ],
          if (sale.customerName.isNotEmpty && sale.customerName != 'Pelanggan Umum')
            _row('Pelanggan', sale.customerName),
          if (sale.notes != null && sale.notes!.isNotEmpty)
            _row('Catatan', sale.notes!),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColor.onSurfaceVariant)),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 15 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                  color: valueColor ?? AppColor.onSurface)),
        ],
      ),
    );
  }
}
