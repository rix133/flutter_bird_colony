// Test for listMarkerColorGroups.dart

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/design/minMaxInput.dart';
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

  setUp(() async {
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

    testWidgets('edits  a marker day range  group edit is pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      final editButton = find.byIcon(Icons.edit);
      expect(editButton, findsNWidgets(2));

      await tester.tap(editButton.first);
      await tester.pumpAndSettle();

      //find the minAge input
      final minmax = find.byType(MinMaxInput);
      expect(minmax, findsOneWidget);

      final ages =
          find.descendant(of: minmax, matching: find.byType(TextField));

      await tester.enterText(ages.first, "10");
      await tester.enterText(ages.last, "20");

      //find the text save
      final saveButton = find.text("Save");
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text("species1 parent trapping"), findsOneWidget);
      expect(find.text("First egg age: 10-20 days"), findsOneWidget);
    });

    testWidgets('edits  a marker color  group edit is pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      final editButton = find.byIcon(Icons.edit);
      expect(editButton, findsNWidgets(2));

      await tester.tap(editButton.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text("Pick color"));
      await tester.pumpAndSettle();

      final colorPicker = find.byType(ColorPicker);
      expect(colorPicker, findsOneWidget);

      //change the color to red

      // Cast the widget to ColorPicker and then change the color to red
      (colorPicker.evaluate().first.widget as ColorPicker)
          .onColorChanged(Colors.red);
      await tester.pumpAndSettle();

      await tester.tap(find.text("Got it"));
      await tester.pumpAndSettle();

      //find the text save
      final saveButton = find.text("Save");
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text("species1 parent trapping"), findsOneWidget);
      // Check the edit button background color
      final editButtonAfter = find.byIcon(Icons.edit);
      expect(editButtonAfter, findsNWidgets(2));
      final ListTile tile2 =
          find.byType(ListTile).last.evaluate().first.widget as ListTile;
      expect(
          (tile2.trailing as ElevatedButton)
              .style!
              .backgroundColor!
              .resolve({})!.value,
          4294902015);
      //the colors are different for tiles so the color is changed
      final ListTile tile =
          find.byType(ListTile).first.evaluate().first.widget as ListTile;
      expect(
          (tile.trailing as ElevatedButton)
              .style!
              .backgroundColor!
              .resolve({})!.value,
          4294906112);
    });
  });
}
