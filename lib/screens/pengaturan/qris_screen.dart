import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:usahaku/controllers/settings_controller.dart';
import 'package:usahaku/theme/app_theme.dart';

/// Kelola gambar QRIS untuk metode bayar QRIS di POS.
class QrisScreen extends StatefulWidget {
  final SettingsController controller;
  const QrisScreen({super.key, required this.controller});

  @override
  State<QrisScreen> createState() => _QrisScreenState();
}

class _QrisScreenState extends State<QrisScreen> {
  SettingsController get c => widget.controller;

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final supported = picker.supportsImageSource(ImageSource.camera);
    if (!supported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera tidak tersedia di perangkat ini. Membuka galeri...')),
        );
      }
      return _pickFromGallery();
    }
    final file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 95,
    );
    if (file == null) return;
    await _saveQris(file.path);
  }

  Future<void> _pickFromGallery() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 95,
    );
    if (file == null) return;
    await _saveQris(file.path);
  }

  Future<void> _saveQris(String sourcePath) async {
    final docs = await getApplicationDocumentsDirectory();
    final dest = '${docs.path}/qris_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(sourcePath).copy(dest);
    await c.saveQris(dest);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QRIS berhasil disimpan')),
      );
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus QRIS?'),
        content: const Text('QRIS akan dihapus dari aplikasi. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColor.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await c.removeQris();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QRIS dihapus')),
      );
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Tambah Gambar QRIS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColor.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.camera_alt_outlined, color: AppColor.primary),
              ),
              title: const Text('Kamera'),
              subtitle: const Text('Foto langsung kertas QRIS'),
              onTap: () { Navigator.pop(ctx); _pickFromCamera(); },
            ),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColor.secondaryContainer, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.photo_library_outlined, color: AppColor.secondary),
              ),
              title: const Text('Galeri'),
              subtitle: const Text('Pilih gambar QRIS tersimpan'),
              onTap: () { Navigator.pop(ctx); _pickFromGallery(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QRIS Pembayaran')),
      body: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColor.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColor.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Unggah gambar QRIS Anda. Kode QR akan ditampilkan saat pelanggan memilih pembayaran QRIS di kasir, tanpa perlu koneksi internet.',
                        style: TextStyle(fontSize: 13, color: AppColor.onPrimaryContainer, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Preview QRIS
              Container(
                height: 260,
                decoration: BoxDecoration(
                  color: AppColor.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: c.qrExists && c.settings.qrisImagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(c.settings.qrisImagePath!),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(Icons.qr_code_2, size: 96, color: AppColor.outlineVariant),
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColor.surfaceContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.qr_code_2, size: 44, color: AppColor.outlineVariant),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada QRIS',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tambahkan gambar QRIS di bawah',
                            style: TextStyle(fontSize: 12, color: AppColor.outline),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              // Tombol aksi
              if (!c.qrExists)
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _showSourceSheet,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                    label: const Text('Tambah Gambar QRIS'),
                  ),
                )
              else ...[
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _showSourceSheet,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Ganti QRIS'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _remove,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.error,
                      side: const BorderSide(color: AppColor.error),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('Hapus QRIS'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
