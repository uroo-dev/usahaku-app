import 'package:flutter/material.dart';
import 'package:usahaku/theme/app_theme.dart';

/// Kartu berisi ikon + teks, bisa ditekan (untuk menu list & laporan).
class ListMenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ListMenuTile({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 22),
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
            trailing ?? const Icon(Icons.chevron_right, color: AppColor.outlineVariant),
          ],
        ),
      ),
    );
  }
}
