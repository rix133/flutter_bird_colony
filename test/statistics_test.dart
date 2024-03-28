import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/screens/statistics.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'mocks/mockSharedPreferencesService.dart';

void main() {
  final sharedPreferencesService = MockSharedPreferencesService();
  final firestore = FakeFirebaseFirestore();
  final Nest nest1 = Nest(
    id: "1",
    coordinates: GeoPoint(0, 0),
    accuracy: "3.22m",
    last_modified: DateTime(2023, 6, 1),
    discover_date: DateTime(2023, 5, 1),
    responsible: "Admin",
    species: "Common Gull",
    measures: [],
  );

  final Nest nest3 = Nest(
    id: "234",
    coordinates: GeoPoint(0, 0),
    accuracy: "3.22m",
    last_modified: DateTime(2023, 6, 1),
    discover_date: DateTime(2023, 5, 1),
    responsible: "Admin",
    species: "Common gull",
    measures: [],
  );

  final parent = Bird(
      ringed_date: DateTime(2023, 6, 1),
      band: 'AA1234',
      ringed_as_chick: true,
      measures: [],
      nest: "234",
      //2022 was the nest
      nest_year: 2023,
      responsible: 'Admin',
      last_modified: DateTime(2023, 6, 1),
      species: 'Common gull');

  final chick = Bird(
      ringed_date: DateTime.now().subtract(Duration(days: 3)),
      band: 'AA1235',
      ringed_as_chick: true,
      measures: [],
      nest: "1",
      //3 years ago this was the nest
      nest_year: DateTime.now().year,
      responsible: 'Admin',
      last_modified: DateTime.now().subtract(Duration(days: 3)),
      species: 'Common gull');

  late Widget myApp;

  setUpAll(() async {
    //add one common gull nest to firestore nests
    await nest3.save(firestore);
    await firestore.collection('Birds').doc(parent.band).set(parent.toJson());
    await chick.save(firestore);

    myApp = ChangeNotifierProvider<SharedPreferencesService>(
        create: (_) => sharedPreferencesService,
        child: MaterialApp(home: Statistics(firestore: firestore)));
  });

  //run after each test
  tearDown(() async {
    await firestore.collection('Nest').doc(nest1.id).delete();
    sharedPreferencesService.speciesList =
        LocalSpeciesList.fromStringList(["Common gull"]);
  });

  testWidgets('Statistics widget should build correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    expect(find.text('Some statistics'), findsOneWidget);
    expect(find.byType(DropdownButton<int>), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsNWidgets(2));
  });

  testWidgets('Statistics widget should update selected year correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);

    // Verify initial selected year
    expect(find.text(DateTime.now().year.toString()), findsOneWidget);

    // Tap on the dropdown button to select a different year
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2023').last);
    await tester.pumpAndSettle();

    // Verify that the selected year has been updated
    expect(find.text('2023'), findsOneWidget);
  });

  testWidgets('Statistics widget should update selected timeframe correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Verify initial selected timeframe
    expect(find.text('All'), findsOneWidget);

    // Tap on the dropdown button to select a different timeframe
    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today').last);
    await tester.pumpAndSettle();

    // Verify that the selected timeframe has been updated
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('Statistics widget should update selected user correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Verify initial selected user
    expect(find.text('Everybody'), findsOneWidget);

    // Tap on the dropdown button to select a different user
    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Me').last);
    await tester.pumpAndSettle();

    // Verify that the selected user has been updated
    expect(find.text('Me'), findsOneWidget);
  });

  testWidgets('Statistics widget should display correct nest statistics',
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Verify initial selected year
    expect(find.text(DateTime.now().year.toString()), findsOneWidget);

    // Tap on the dropdown button to select a different year
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2023').last);
    await tester.pumpAndSettle();

    // Verify that the selected year has been updated
    expect(find.text('2023'), findsOneWidget);

    // Verify initial nest statistics
    expect(find.text('Total nests'), findsOneWidget);
    //find the listTile that has the text Total nests
    final totNests = find.widgetWithText(ListTile, 'Total nests');
    expect(find.descendant(of: totNests, matching: find.text('1')),
        findsOneWidget);

    expect(find.text("Experiment nests"), findsNothing);
    expect(find.text("Common gull nests"), findsOneWidget);
    // Add more assertions to verify the correctness of nest statistics
  });

  testWidgets(
      'Statistics widget should display correct nest statistics for Common Gull',
      (WidgetTester tester) async {
    sharedPreferencesService.speciesList =
        LocalSpeciesList.fromStringList(["Common Gull"]);
    nest1.save(firestore);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Verify initial selected year
    expect(find.text(DateTime.now().year.toString()), findsOneWidget);

    // Tap on the dropdown button to select a different year
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2023').last);
    await tester.pumpAndSettle();

    // Verify that the selected year has been updated
    expect(find.text('2023'), findsOneWidget);

    // Verify initial nest statistics
    expect(find.text('Total nests'), findsOneWidget);
    //find the listTile that has the text Total nests
    final totNests = find.widgetWithText(ListTile, 'Total nests');
    expect(find.descendant(of: totNests, matching: find.text('2')),
        findsOneWidget);

    expect(find.text("Experiment nests"), findsNothing);
    expect(find.text("Common Gull nests"), findsOneWidget);
    // Add more assertions to verify the correctness of nest statistics
  });

  testWidgets(
      'Bird statistics should be correctly displayed in the Statistics widget',
      (WidgetTester tester) async {
    // Initialize the app
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Check initial bird statistics
    expect(find.text('Total ringed'), findsOneWidget);

    // Check if the 'Total ringed' statistic is correct
    final totalRingedTile = find.widgetWithText(ListTile, 'Total ringed');
    expect(find.descendant(of: totalRingedTile, matching: find.text('1')),
        findsOneWidget);

    // Check if the 'Common gull ringed' statistic is correct
    final commonGullRingedTile =
        find.widgetWithText(ListTile, 'Common gull ringed');
    expect(find.descendant(of: commonGullRingedTile, matching: find.text('1')),
        findsOneWidget);

    // Verify the presence of 'Common gull ringed' statistic
    expect(find.text("Common gull ringed"), findsOneWidget);

    // Add more checks to ensure the accuracy of bird statistics
  });
}
