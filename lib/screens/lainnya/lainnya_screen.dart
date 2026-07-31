import 'package:flutter/material.dart';
import 'package:usahaku/controllers/settings_controller.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/database/db.dart';
import 'package:usahaku/screens/hutang/debt_list_screen.dart';
import 'package:usahaku/screens/laporan/laporan_screen.dart';
import 'package:usahaku/screens/master/kalkulator_screen.dart';
import 'package:usahaku/screens/master/kategori_kas_screen.dart';
import 'package:usahaku/screens/master/kategori_produk_screen.dart';
import 'package:usahaku/screens/master/satuan_produk_screen.dart';
import 'package:usahaku/screens/pelanggan/customer_screen.dart';
import 'package:usahaku/screens/pengaturan/business_info_screen.dart';
import 'package:usahaku/screens/pengaturan/qris_screen.dart';
import 'package:usahaku/screens/suplier/supplier_screen.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/widgets/app_about_dialog.dart';
import 'package:usahaku/widgets/list_menu_tile.dart';

/// Lainnya — menu lengkap: DATA MASTER, KEUANGAN, PENGATURAN.
class LainnyaScreen extends StatefulWidget {
  const LainnyaScreen({super.key});

  @override
  State<LainnyaScreen> createState() => _LainnyaScreenState();
}

class _LainnyaScreenState extends State<LainnyaScreen> {
  String _businessName = 'Usaha Ku';
  final SettingsController _settingsC = SettingsController();

  @override
  void initState() {
    super.initState();
    _load();
    _settingsC.load();
  }

  @override
  void dispose() {
    _settingsC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = DB.instance;
    final profile = await db.select(db.businessProfiles).getSingleOrNull();
    if (profile != null && profile.name.isNotEmpty) {
      setState(() => _businessName = profile.name);
    }
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Data?'),
        content: const Text('Semua produk, penjualan, kas, piutang & utang akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DB.instance.deleteAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua data berhasil dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu, size: 20),
            SizedBox(width: 8),
            Text('Lainnya'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _businessCard(),
          const SizedBox(height: 20),
          _sectionLabel('📂 DATA MASTER'),
          const SizedBox(height: 8),
          _group(
            children: [
              ListMenuTile(
                icon: Icons.group_outlined,
                iconBg: AppColor.secondary.withValues(alpha: 0.12),
                iconColor: AppColor.secondary,
                title: '👥 Pelanggan',
                subtitle: 'Kelola data pelanggan',
                onTap: () => _push(const CustomerScreen()),
              ),
              ListMenuTile(
                icon: Icons.local_shipping_outlined,
                iconBg: AppColor.tertiary.withValues(alpha: 0.12),
                iconColor: AppColor.tertiary,
                title: '🚚 Supplier',
                subtitle: 'Kelola data supplier',
                onTap: () => _push(const SupplierScreen()),
              ),
              ListMenuTile(
                icon: Icons.category_outlined,
                iconBg: AppColor.primary.withValues(alpha: 0.12),
                iconColor: AppColor.primary,
                title: '📂 Kategori Produk',
                subtitle: 'Kelola kategori produk',
                onTap: () => _push(const KategoriProdukScreen()),
              ),
              ListMenuTile(
                icon: Icons.straighten,
                iconBg: AppColor.secondaryFixed,
                iconColor: AppColor.onSecondaryFixedVariant,
                title: '📏 Satuan Produk',
                subtitle: 'Kelola satuan: pcs, kg, liter',
                onTap: () => _push(const SatuanProdukScreen()),
              ),
              ListMenuTile(
                icon: Icons.label_outline,
                iconBg: AppColor.tertiaryFixed,
                iconColor: AppColor.onTertiaryFixedVariant,
                title: '💵 Kategori Kas',
                subtitle: 'Kelola kategori pemasukan & pengeluaran',
                onTap: () => _push(const KategoriKasScreen()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel('💳 KEUANGAN'),
          const SizedBox(height: 8),
          _group(
            children: [
              ListMenuTile(
                icon: Icons.receipt_long_outlined,
                iconBg: AppColor.error.withValues(alpha: 0.12),
                iconColor: AppColor.error,
                title: '📄 Piutang',
                subtitle: 'Tagihan kepada pelanggan',
                onTap: () => _push(DebtListScreen(type: DebtType.piutang)),
              ),
              ListMenuTile(
                icon: Icons.account_balance_wallet_outlined,
                iconBg: AppColor.primary.withValues(alpha: 0.12),
                iconColor: AppColor.primary,
                title: '🧾 Utang',
                subtitle: 'Kewajiban kepada supplier',
                onTap: () => _push(DebtListScreen(type: DebtType.utang)),
              ),
              ListMenuTile(
                icon: Icons.insert_chart_outlined,
                iconBg: AppColor.primary.withValues(alpha: 0.12),
                iconColor: AppColor.primary,
                title: '📊 Laporan',
                subtitle: 'Laba rugi, penjualan, arus kas',
                onTap: () => _push(const LaporanScreen()),
              ),
              ListMenuTile(
                icon: Icons.calculate_outlined,
                iconBg: AppColor.secondary.withValues(alpha: 0.12),
                iconColor: AppColor.secondary,
                title: '🧮 Kalkulator',
                subtitle: 'Kalkulator cepat untuk menghitung',
                onTap: () => _push(const KalkulatorScreen()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel('⚙ PENGATURAN'),
          const SizedBox(height: 8),
          _group(
            children: [
              ListMenuTile(
                icon: Icons.store_outlined,
                iconBg: AppColor.primary.withValues(alpha: 0.12),
                iconColor: AppColor.primary,
                title: '🏪 Profil Usaha',
                subtitle: 'Nama, pemilik, alamat bisnis',
                onTap: () => _push(BusinessInfoScreen(controller: _settingsC)),
              ),
              ListMenuTile(
                icon: Icons.qr_code_2,
                iconBg: AppColor.tertiary.withValues(alpha: 0.12),
                iconColor: AppColor.tertiary,
                title: '💳 QRIS',
                subtitle: 'Pasang kode QR pembayaran',
                onTap: () => _push(QrisScreen(controller: _settingsC)),
              ),
              ListMenuTile(
                icon: Icons.info_outline,
                iconBg: AppColor.primaryFixed,
                iconColor: AppColor.onPrimaryFixedVariant,
                title: 'ℹ Tentang',
                subtitle: 'UsahaKu v1.0.0',
                onTap: () => showAppAboutDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _confirmDeleteAll,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.error,
                side: const BorderSide(color: AppColor.errorContainer),
                backgroundColor: AppColor.errorContainer.withValues(alpha: 0.5),
              ),
              icon: const Icon(Icons.delete_forever_outlined, size: 20),
              label: const Text('Hapus Semua Data'),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'UsahaKu v1.0.0',
              style: TextStyle(fontSize: 12, color: AppColor.outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _businessCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColor.primary, Color(0xFF0058BE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColor.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.storefront, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bisnis Anda',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 2),
                Text(
                  _businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColor.onSurfaceVariant),
    );
  }

  Widget _group({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(children: children),
    );
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
