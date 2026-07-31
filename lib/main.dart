import 'package:flutter/material.dart';
import 'package:usahaku/screens/home_screen.dart';
import 'package:usahaku/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UsahaKuApp());
}

class UsahaKuApp extends StatelessWidget {
  const UsahaKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UsahaKu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
