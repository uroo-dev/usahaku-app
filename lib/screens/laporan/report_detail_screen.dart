import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:usahaku/controllers/reports_controller.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';

/// Detail laporan — sesuai detail-laporan.html: tren, produk terlaris, ekspor.
class ReportDetailScreen extends StatefulWidget {
  final String type;
  final ReportsController controller;
  const ReportDetailScreen({super.key, required this.type, required this.controller});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  ReportsController get c => widget.controller;

  Future<void> _export() async {
    final sales = await c.allSales();
    final buffer = StringBuffer();
    buffer.writeln('Invoice;Tanggal;Pelanggan;Subtotal;Diskon;Total;Metode;Catatan');
    for (final s in sales) {
      buffer.writeln('${s.invoiceNo};${FormatUtil.dateTime(s.date)};${s.customerName};${s.subtotal};${s.discount};${s.total};${s.paymentMethodLabel};${s.notes ?? ''}');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/laporan_penjualan_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], subject: 'Laporan Penjualan UsahaKu');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: _export,
            tooltip: 'Ekspor Laporan',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final s = c.summary;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _summaryRow('Total Pendapatan', FormatUtil.rupiah(s.totalRevenue)),
              _summaryRow('Laba Bersih', FormatUtil.rupiah(s.totalProfit)),
              _summaryRow('Pengeluaran', FormatUtil.rupiah(s.totalExpense)),
              _summaryRow('Transaksi', '${s.totalTransactions}'),
              const SizedBox(height: 24),
              const Text(
                'TREN PENJUALAN (7 HARI)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              _trendChart(s.daily),
              const SizedBox(height: 24),
              const Text(
                'PRODUK TERLARIS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              if (s.topProducts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Belum ada data penjualan.', style: TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant)),
                )
              else
                ...s.topProducts.asMap().entries.map((e) => _productRow(e.key, e.value)),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.onSurface)),
        ],
      ),
    );
  }

  Widget _trendChart(List<DailyPoint> daily) {
    final maxVal = daily.fold<double>(0, (m, d) => d.revenue > m ? d.revenue : m);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: daily.map((d) {
            final h = (d.revenue / safeMax * 120).clamp(2.0, 120.0);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: h,
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: d.revenue > 0 ? 1 : 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      FormatUtil.dayShort(d.date),
                      style: const TextStyle(fontSize: 9, color: AppColor.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _productRow(int rank, MapEntry<String, int> entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank == 0 ? AppColor.amber100 : AppColor.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${rank + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: rank == 0 ? AppColor.amber800 : AppColor.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.key,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.onSurface),
            ),
          ),
          Text(
            '${entry.value} Pcs',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.onSurface),
          ),
        ],
      ),
    );
  }
}
