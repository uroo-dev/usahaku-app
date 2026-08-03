import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:usahaku/screens/dashboard/dashboard_screen.dart';
import 'package:usahaku/screens/lainnya/lainnya_screen.dart';
import 'package:usahaku/screens/kas/kas_screen.dart';
import 'package:usahaku/screens/penjualan/sales_screen.dart';
import 'package:usahaku/screens/produk/produk_screen.dart';
import 'package:usahaku/widgets/bottom_nav.dart';

const _salesTabIndex = 2;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _salesLandscape = false;

  Future<void> _switchTab(int index) async {
    // Keluar dari tab Penjualan -> kembali ke portrait
    if (_currentIndex == _salesTabIndex && index != _salesTabIndex) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    // Masuk ke tab Penjualan -> terapkan orientasi yang tersimpan
    if (index == _salesTabIndex) {
      await SystemChrome.setPreferredOrientations(
        _salesLandscape
            ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
            : [DeviceOrientation.portraitUp],
      );
    }
    if (!mounted) return;
    setState(() => _currentIndex = index);
  }

  void _onSalesLandscapeChanged(bool landscape) {
    _salesLandscape = landscape;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onSwitchTab: _switchTab),
      const ProdukScreen(),
      SalesScreen(
        landscape: _salesLandscape,
        onLandscapeChanged: _onSalesLandscapeChanged,
      ),
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
