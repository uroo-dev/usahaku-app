import 'package:flutter/material.dart';
import 'package:usahaku/controllers/dashboard_controller.dart';
import 'package:usahaku/models/dashboard_model.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';
import 'package:usahaku/widgets/section_header.dart';
import 'package:usahaku/widgets/stat_card.dart';

/// Dashboard — sesuai dashboard.html.
class DashboardScreen extends StatefulWidget {
  /// Callback untuk berpindah tab di HomeScreen.
  /// Index: 0=Dashboard, 1=Produk, 2=Penjualan, 3=Kas, 4=Lainnya
  final void Function(int index)? onSwitchTab;

  const DashboardScreen({super.key, this.onSwitchTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController _c = DashboardController();

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: AppColor.primary, borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.storefront, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('UsahaKu'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotif(context),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColor.surfaceContainerHigh,
              child: Icon(Icons.person, size: 18, color: AppColor.onSurfaceVariant),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          final data = _c.data;
          final now = DateTime.now();

          return RefreshIndicator(
            onRefresh: _c.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                // Greeting
                Text(
                  FormatUtil.dateLong(now).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _greeting(now),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColor.onSurface),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Warung Berkah Jaya',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.onSurfaceVariant),
                ),
                const SizedBox(height: 20),

                // Today summary card
                _summaryCard(data),
                const SizedBox(height: 24),

                // Quick actions
                const SectionHeader(title: 'Aksi Cepat'),
                const SizedBox(height: 12),
                _quickActions(context),
                const SizedBox(height: 24),

                // Reminder
                _reminderCard(data),
                const SizedBox(height: 24),

                // Business overview
                const SectionHeader(title: 'Ringkasan Bisnis'),
                const SizedBox(height: 12),
                _overviewGrid(data),
                const SizedBox(height: 24),

                // Low stock
                const SectionHeader(title: 'Stok Rendah', actionLabel: 'Lihat Semua'),
                const SizedBox(height: 12),
                _lowStockList(data),
                const SizedBox(height: 24),

                // Recent activity
                const SectionHeader(title: 'Aktivitas Hari Ini', actionLabel: 'Semua'),
                const SizedBox(height: 12),
                _recentSales(data),

                const SizedBox(height: 24),
                const SectionHeader(title: 'Produk Terlaris'),
                const SizedBox(height: 12),
                _topProducts(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard(DashboardModel data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColor.primary.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pendapatan Hari Ini',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
                child: const Text(
                  'Terupdate',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            FormatUtil.rupiah(data.todayRevenue),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trending_up, size: 14, color: AppColor.green100),
              const SizedBox(width: 4),
              Text(
                '+8% dari kemarin',
                style: TextStyle(fontSize: 12, color: AppColor.green100, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryRow('LABA BERSIH', FormatUtil.rupiah(data.todayProfit)),
              ),
              Expanded(
                child: _summaryRow('TRANSAKSI', '${data.todayTransactions} Trx'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ],
    );
  }

  Widget _quickActions(BuildContext context) {
    return Row(
      children: [
        _actionItem(
          icon: Icons.add_shopping_cart,
          label: 'Jual Baru',
          bg: AppColor.primaryContainer,
          color: AppColor.primary,
          // Pindah ke tab Penjualan (index 2) agar BottomNavBar tetap tampil
          onTap: () => widget.onSwitchTab?.call(2),
        ),
        const SizedBox(width: 12),
        _actionItem(
          icon: Icons.inventory_2,
          label: 'Tambah Produk',
          bg: AppColor.surfaceContainerHigh,
          color: AppColor.onSurfaceVariant,
          // Pindah ke tab Produk (index 1) agar BottomNavBar tetap tampil
          onTap: () => widget.onSwitchTab?.call(1),
        ),
        const SizedBox(width: 12),
        _actionItem(
          icon: Icons.account_balance_wallet,
          label: 'Kas Masuk',
          bg: AppColor.green50,
          color: AppColor.green600,
          // Pindah ke tab Kas (index 3)
          onTap: () => widget.onSwitchTab?.call(3),
        ),
        const SizedBox(width: 12),
        _actionItem(
          icon: Icons.payments,
          label: 'Kas Keluar',
          bg: AppColor.red50,
          color: AppColor.red600,
          // Pindah ke tab Kas (index 3)
          onTap: () => widget.onSwitchTab?.call(3),
        ),
      ],
    );
  }

  Widget _actionItem({
    required IconData icon,
    required String label,
    required Color bg,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reminderCard(DashboardModel data) {
    final hasWarning = data.overdueReceivableCount > 0 || data.overduePayableCount > 0;
    if (!hasWarning) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.amber50,
        border: Border.all(color: AppColor.amber100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColor.amber100, shape: BoxShape.circle),
            child: const Icon(Icons.notification_important, color: AppColor.amber700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perlu Perhatian',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.amber900),
                ),
                Text(
                  '${data.overdueReceivableCount} Piutang belum dibayar & ${data.overduePayableCount} Hutang jatuh tempo.',
                  style: const TextStyle(fontSize: 13, color: AppColor.amber800),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColor.amber700),
        ],
      ),
    );
  }

  Widget _overviewGrid(DashboardModel data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.55,
      children: [
        StatCard(
          title: 'Stok Produk',
          value: '${data.totalProducts} Item',
          icon: Icons.inventory_2,
          badge: data.lowStockCount > 0 ? '${data.lowStockCount} Rendah' : 'Normal',
          badgeColor: data.lowStockCount > 0 ? AppColor.red700 : AppColor.green700,
        ),
        StatCard(
          title: 'Pelanggan',
          value: '${data.customerCount} Orang',
          icon: Icons.group,
        ),
        StatCard(
          title: 'Saldo Kas',
          value: FormatUtil.rupiahShort(data.cashBalance),
          icon: Icons.account_balance,
        ),
        StatCard(
          title: 'Hutang/Piutang',
          value: FormatUtil.rupiahShort(data.totalReceivable + data.totalPayable),
          icon: Icons.history_edu,
          badge: 'Perhatian',
          badgeColor: AppColor.red700,
          valueColor: AppColor.error,
        ),
      ],
    );
  }

  Widget _lowStockList(DashboardModel data) {
    if (data.lowStockProducts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: AppColor.onSurfaceVariant),
                SizedBox(width: 6),
                Text('Stok semua aman', style: TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant)),
              ],
            ),
      );
    }
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: data.lowStockProducts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = data.lowStockProducts[i];
          return Container(
            width: 168,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColor.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: AppColor.surfaceContainer, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.lunch_dining, color: AppColor.primary, size: 20),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColor.red50, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        'Sisa ${p.stock}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.red600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {},
                    child: const Text('Restok', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _recentSales(DashboardModel data) {
    if (data.recentSales.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Belum ada penjualan hari ini.', style: TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant)),
      );
    }
    return Column(
      children: data.recentSales.take(3).map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColor.green50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.receipt_long, color: AppColor.green600, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.invoiceNo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.onSurface),
                    ),
                    Text(
                      '${FormatUtil.time(s.date)} • ${s.paymentMethod.label}',
                      style: const TextStyle(fontSize: 11, color: AppColor.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    FormatUtil.rupiah(s.total),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.onSurface),
                  ),
                  Text(
                    'SUKSES',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColor.green700),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _topProducts(DashboardModel data) {
    if (data.topProducts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Belum ada data.', style: TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant)),
      );
    }
    return Column(
      children: List.generate(data.topProducts.length, (i) {
        final p = data.topProducts[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColor.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '#${i + 1}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.invoiceNo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.onSurface),
                    ),
                    Text(
                      'Terjual ${p.itemCount} kali',
                      style: const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Text(
                'Rp 75k',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.primary),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showNotif(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak ada notifikasi baru')),
    );
  }

  String _greeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 4 && hour < 11) return 'Halo, Selamat Pagi!';
    if (hour >= 11 && hour < 15) return 'Halo, Selamat Siang!';
    if (hour >= 15 && hour < 18) return 'Halo, Selamat Sore!';
    return 'Halo, Selamat Malam!';
  }
}
