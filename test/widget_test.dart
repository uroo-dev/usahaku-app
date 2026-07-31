import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:usahaku/main.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const UsahaKuApp());
    await tester.pump();
    expect(find.byType(Scaffold), findsWidgets);
  });
}
