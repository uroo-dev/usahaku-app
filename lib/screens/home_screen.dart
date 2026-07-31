import 'package:flutter/material.dart';
import 'package:usahaku/screens/dashboard/dashboard_screen.dart';
import 'package:usahaku/screens/lainnya/lainnya_screen.dart';
import 'package:usahaku/screens/kas/kas_screen.dart';
import 'package:usahaku/screens/penjualan/sales_screen.dart';
import 'package:usahaku/screens/produk/produk_screen.dart';
import 'package:usahaku/widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onSwitchTab: _switchTab),
      const ProdukScreen(),
      const SalesScreen(),
      const KasScreen(),
      const LainnyaScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _switchTab,
      ),
    );
  }
}
