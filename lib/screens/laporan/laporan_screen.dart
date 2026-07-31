import 'package:flutter/material.dart';
import 'package:usahaku/controllers/reports_controller.dart';
import 'package:usahaku/screens/laporan/report_detail_screen.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';
import 'package:usahaku/widgets/filter_chip.dart';

/// Laporan — sesuai laporan.html: ringkasan + menu jenis laporan.
class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final ReportsController _c = ReportsController();

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          if (_c.isLoading) return const Center(child: CircularProgressIndicator());
          final s = _c.summary;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _periodChips(),
              const SizedBox(height: 16),
              _revenueCard(s),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _miniCard('Laba Bersih', FormatUtil.rupiahShort(s.totalProfit), Icons.trending_up, AppColor.success)),
                  const SizedBox(width: 12),
                  Expanded(child: _miniCard('Transaksi', '${s.totalTransactions}', Icons.receipt_long, AppColor.primary)),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'PILIH LAPORAN',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              _reportGroup([
                _reportTile(Icons.point_of_sale, AppColor.primary, 'Penjualan', 'Rincian transaksi penjualan'),
                _reportTile(Icons.trending_up, AppColor.success, 'Laba & Rugi', 'Pendapatan dikurangi modal & biaya'),
                _reportTile(Icons.account_balance_wallet, AppColor.secondary, 'Arus Kas', 'Pemasukan & pengeluaran kas'),
                _reportTile(Icons.receipt_long, AppColor.error, 'Piutang & Utang', 'Tagihan dan kewajiban'),
                _reportTile(Icons.inventory_2, AppColor.tertiary, 'Stok Produk', 'Ketersediaan stok'),
                _reportTile(Icons.emoji_events_outlined, AppColor.amber800, 'Produk Terlaris', 'Top 5 produk terlaris'),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _periodChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ['Hari ini', 'Minggu ini', 'Bulan ini', 'Tahun ini'].map((p) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChipWidget(
              label: p,
              selected: _c.period == p,
              onTap: () => _c.setPeriod(p),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _revenueCard(ReportSummary s) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColor.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL PENDAPATAN',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.onPrimaryContainer),
          ),
          const SizedBox(height: 6),
          Text(
            FormatUtil.rupiah(s.totalRevenue),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColor.onPrimaryContainer),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColor.onPrimaryContainer),
              const SizedBox(width: 4),
              Text(
                '${s.totalTransactions} transaksi',
                style: const TextStyle(fontSize: 12, color: AppColor.onPrimaryContainer),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColor.onSurface),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColor.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _reportGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(children: children),
    );
  }

  Widget _reportTile(IconData icon, Color color, String title, String subtitle) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReportDetailScreen(type: title, controller: _c)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColor.onSurface)),
                  const SizedBox(height: 1),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColor.outlineVariant),
          ],
        ),
      ),
    );
  }
}
