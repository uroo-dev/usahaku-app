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

  final _screens = const [
    DashboardScreen(),
    ProdukScreen(),
    SalesScreen(),
    KasScreen(),
    LainnyaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}