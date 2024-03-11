import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/screens/statistics.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

import 'mocks/mockSharedPreferencesService.dart';

void main() {
  final sharedPreferencesService = MockSharedPreferencesService();
  final firestore = FakeFirebaseFirestore();

  late Widget myApp;

    setUpAll(() {
      myApp = ChangeNotifierProvider<SharedPreferencesService>(
          create: (_) => sharedPreferencesService,
          child: MaterialApp(home: Statistics(firestore: firestore)));
    });
    testWidgets('Statistics widget should build correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    expect(find.text('Some statistics'), findsOneWidget);
      expect(find.byType(DropdownButton<int>), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsNWidgets(2));

    // Add more tests for other functionalities of the Statistics widget
  });
}
