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

  Future<void> _pickQris() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (file == null) return;
    final docs = await getApplicationDocumentsDirectory();
    final dest = '${docs.path}/qris_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(file.path).copy(dest);
    await c.saveQris(dest);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QRIS berhasil disimpan')),
      );
    }
  }

  Future<void> _remove() async {
    await c.removeQris();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QRIS dihapus')),
      );
    }
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
              Text(
                'Gunakan QRIS saat pelanggan membayar lewat metode QRIS di POS. Kode QR ditampilkan tanpa koneksi internet.',
                style: const TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 20),
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
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2, size: 80, color: AppColor.outlineVariant),
                            SizedBox(height: 12),
                            Text(
                              'Belum ada QRIS',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              if (!c.qrExists)
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _pickQris,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                    label: const Text('Unggah Gambar QRIS'),
                  ),
                )
              else ...[
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _pickQris,
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
