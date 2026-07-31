import 'package:flutter/material.dart';
import 'package:usahaku/theme/app_theme.dart';

/// Dialog "Tentang Aplikasi" — dipakai halaman Pengaturan & Lainnya.
Future<void> showAppAboutDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Tentang Aplikasi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColor.primaryFixed,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.storefront, color: AppColor.primary, size: 36),
          ),
          const SizedBox(height: 12),
          const Text(
            'UsahaKu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColor.onSurface),
          ),
          const SizedBox(height: 4),
          const Text(
            'v1.0.0',
            style: TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          const Text(
            'Aplikasi pencatatan usaha sederhana untuk UMKM. Bekerja offline, semua data tersimpan aman di perangkat Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
      ],
    ),
  );
}
