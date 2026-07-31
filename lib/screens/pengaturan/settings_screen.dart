import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:usahaku/controllers/settings_controller.dart';
import 'package:usahaku/models/settings_model.dart';
import 'package:usahaku/screens/pengaturan/business_info_screen.dart';
import 'package:usahaku/screens/pengaturan/qris_screen.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/widgets/list_menu_tile.dart';

/// Pengaturan — sesuai pengaturan.html: profil, umum, data, dukungan.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController _c = SettingsController();

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

  Future<void> _backup() async {
    try {
      final path = await _c.backup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup tersimpan: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal backup: $e')));
      }
    }
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pulihkan Data?'),
        content: const Text('Data saat ini akan ditimpa dengan data backup. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pulihkan')),
        ],
      ),
    );
    if (confirmed != true) return;
    final file = await _pickBackupFile();
    if (file == null) return;
    try {
      await _c.restore(file.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dipulihkan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memulihkan: $e')));
      }
    }
  }

  Future<XFile?> _pickBackupFile() async {
    return ImagePicker().pickImage(source: ImageSource.gallery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          final s = _c.settings;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _profileCard(s),
              const SizedBox(height: 20),
              _sectionLabel('Pengaturan Umum'),
              const SizedBox(height: 8),
              _group([
                ListMenuTile(
                  icon: Icons.store_outlined,
                  iconBg: AppColor.secondaryFixed,
                  iconColor: AppColor.onSecondaryFixedVariant,
                  title: 'Informasi Bisnis',
                  subtitle: s.businessName,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BusinessInfoScreen(controller: _c)),
                    );
                    _c.load();
                  },
                ),
                ListMenuTile(
                  icon: Icons.qr_code_2,
                  iconBg: AppColor.tertiaryFixed,
                  iconColor: AppColor.onTertiaryFixedVariant,
                  title: 'QRIS Pembayaran',
                  subtitle: _c.qrExists ? 'QRIS sudah terpasang' : 'Belum ada QRIS',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => QrisScreen(controller: _c)),
                    );
                    _c.load();
                  },
                ),
                ListMenuTile(
                  icon: Icons.payments_outlined,
                  iconBg: AppColor.secondaryFixed,
                  iconColor: AppColor.onSecondaryFixedVariant,
                  title: 'Mata Uang',
                  subtitle: 'IDR - Rupiah',
                  onTap: () {},
                ),
                ListMenuTile(
                  icon: Icons.language,
                  iconBg: AppColor.secondaryFixed,
                  iconColor: AppColor.onSecondaryFixedVariant,
                  title: 'Bahasa',
                  subtitle: 'Indonesia',
                  onTap: () {},
                ),
                ListMenuTile(
                  icon: Icons.dark_mode_outlined,
                  iconBg: AppColor.secondaryFixed,
                  iconColor: AppColor.onSecondaryFixedVariant,
                  title: 'Mode Gelap',
                  subtitle: 'Belum tersedia',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 20),
              _sectionLabel('Manajemen Data'),
              const SizedBox(height: 8),
              _group([
                ListMenuTile(
                  icon: Icons.cloud_upload_outlined,
                  iconBg: AppColor.tertiaryFixed,
                  iconColor: AppColor.onTertiaryFixedVariant,
                  title: 'Cadangkan',
                  subtitle: 'Simpan salinan database',
                  onTap: _backup,
                ),
                ListMenuTile(
                  icon: Icons.cloud_download_outlined,
                  iconBg: AppColor.tertiaryFixed,
                  iconColor: AppColor.onTertiaryFixedVariant,
                  title: 'Pulihkan',
                  subtitle: 'Timpa data dari backup',
                  onTap: _restore,
                ),
              ]),
              const SizedBox(height: 20),
              _sectionLabel('Dukungan & Info'),
              const SizedBox(height: 8),
              _group([
                ListMenuTile(
                  icon: Icons.help_outline,
                  iconBg: AppColor.primaryFixed,
                  iconColor: AppColor.onPrimaryFixedVariant,
                  title: 'Pusat Bantuan',
                  subtitle: 'Cara menggunakan UsahaKu',
                  onTap: () {},
                ),
                ListMenuTile(
                  icon: Icons.info_outline,
                  iconBg: AppColor.primaryFixed,
                  iconColor: AppColor.onPrimaryFixedVariant,
                  title: 'Tentang Aplikasi',
                  subtitle: 'UsahaKu v1.0.0',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _profileCard(SettingsModel s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColor.primaryFixed,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.storefront, color: AppColor.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColor.onSurface),
                    ),
                    Text(
                      s.owner.isEmpty ? 'Belum diatur' : s.owner,
                      style: const TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.call_outlined, size: 16, color: AppColor.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.phone.isEmpty ? 'No HP belum diatur' : s.phone,
                  style: const TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColor.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.address.isEmpty ? 'Alamat belum diatur' : s.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BusinessInfoScreen(controller: _c)),
                );
                _c.load();
              },
              child: const Text('Ubah Profil Bisnis'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.primary),
    );
  }

  Widget _group(List<Widget> children) {
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
