import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:usahaku/screens/home_screen.dart';
import 'package:usahaku/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  Intl.defaultLocale = 'id_ID';
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
