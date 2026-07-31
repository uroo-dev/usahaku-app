import 'package:flutter/material.dart';
import 'package:usahaku/theme/app_theme.dart';

/// Bottom navigation dengan tombol tengah menonjol (POS) — sesuai template.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AppColor.outlineVariant.withValues(alpha: 0.3))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _navItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
              _navItem(1, Icons.inventory_2_outlined, Icons.inventory_2, 'Produk'),
              _centerButton(),
              _navItem(3, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Kas'),
              _navItem(4, Icons.menu, Icons.menu, 'Lainnya'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final selected = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: selected ? AppColor.primary : AppColor.onSurfaceVariant, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColor.primary : AppColor.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerButton() {
    final selected = currentIndex == 2;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColor.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColor.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.point_of_sale, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 4),
            Text(
              'Penjualan',
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColor.primary : AppColor.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
