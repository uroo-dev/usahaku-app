import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:usahaku/providers/app_settings_provider.dart';
import 'package:usahaku/screens/home_screen.dart';
import 'package:usahaku/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  Intl.defaultLocale = 'id_ID';
  runApp(const UsahaKuApp());
}

class UsahaKuApp extends StatefulWidget {
  const UsahaKuApp({super.key});

  @override
  State<UsahaKuApp> createState() => _UsahaKuAppState();
}

class _UsahaKuAppState extends State<UsahaKuApp> {
  final AppSettingsNotifier _settingsNotifier = AppSettingsNotifier();

  @override
  void initState() {
    super.initState();
    _settingsNotifier.load();
  }

  @override
  void dispose() {
    _settingsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsProvider(
      notifier: _settingsNotifier,
      child: MaterialApp(
        title: 'UsahaKu',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
