// Test for listMarkerColorGroups.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/models/markerColorGroup.dart';
import 'package:kakrarahu/screens/settings/listMarkerColorGroups.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

import 'mocks/mockSharedPreferencesService.dart';

void main() {
  final sharedPreferencesService = MockSharedPreferencesService();
  late Widget myApp;
  final MarkerColorGroup markerColorGroup1 =
      MarkerColorGroup.magenta("species1");
  final MarkerColorGroup markerColorGroup2 =
      MarkerColorGroup.magenta("species2");

  setUpAll(() async {
    myApp = ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
        home: Scaffold(
            body: ListMarkerColorGroups(
          markers: [markerColorGroup1, markerColorGroup2],
          onMarkersUpdated: (List<MarkerColorGroup> markers) {},
        )),
      ),
    );
  });

  group('ListMarkerColorGroups', () {
    testWidgets('displays all marker color groups',
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);

      expect(find.text("species1 parent trapping"), findsOneWidget);
      expect(find.text("species2 parent trapping"), findsOneWidget);
    });
    // Add the following tests to your existing listMarkerColorGroups_test.dart file

    testWidgets('adds a new marker color group when add button is pressed',
        (WidgetTester tester) async {
      sharedPreferencesService.defaultSpecies = "species3";
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      final addButton = find.byKey(Key("addMeasureButton"));
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      await tester.pump();

      expect(find.text("species3 parent trapping"), findsOneWidget);
    });

    testWidgets('adds a new marker color group when defaultSpecies is empty',
        (WidgetTester tester) async {
      sharedPreferencesService.defaultSpecies = "";
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      final addButton = find.byKey(Key("addMeasureButton"));
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      await tester.pump();

      expect(find.text(" parent trapping"), findsOneWidget);
    });
  });
}
