import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/screens/nest/mapNests.dart';
import 'package:flutter_bird_colony/screens/statistics.dart';
import 'package:flutter_bird_colony/services/locationService.dart';
import 'package:flutter_bird_colony/utils/year.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockLocationService.dart';
import 'mocks/mockSharedPreferencesService.dart';
import 'testApp.dart';

void main() {
  final authService = MockAuthService();
  final sharedPreferencesService = MockSharedPreferencesService();
  final firestore = FakeFirebaseFirestore();
  MockLocationAccuracy10 locationAccuracy10 = MockLocationAccuracy10();

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

  final Nest nest2 = Nest(
    id: "12",
    coordinates: GeoPoint(0, 0),
    accuracy: "3.22m",
    last_modified: DateTime.now(),
    discover_date: DateTime.now().subtract(Duration(days: 1)),
    responsible: "Admin",
    species: "Common gull",
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

  late TestApp myApp;

  TestApp getStatisticsApp(
      FakeFirebaseFirestore firestore, MockSharedPreferencesService sps) {
    return TestApp(
      firestore: firestore,
      sps: sps,
      app: MaterialApp(initialRoute: '/statistics', routes: {
        '/statistics': (context) => Statistics(firestore: firestore),
        '/mapNests': (context) =>
            MapNests(firestore: firestore, auth: authService),
      }),
    );
  }

  DateTime dayOffset(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
  }

  setUpAll(() async {
    //AuthService.instance = authService;
    LocationService.instance = locationAccuracy10;
    //add 2 common gull nest to firestore nests
    await nest3.save(firestore);
    await nest2.save(firestore);
    await firestore.collection('Birds').doc(parent.band).set(parent.toJson());
    await chick.save(firestore);
    myApp = TestApp(
      firestore: firestore,
      sps: sharedPreferencesService,
      app: MaterialApp(initialRoute: '/statistics', routes: {
        '/statistics': (context) => Statistics(firestore: firestore),
        '/mapNests': (context) =>
            MapNests(firestore: firestore, auth: authService),
      }),
    );
  });

  setUp(() async {
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
    expect(find.byKey(Key("statisticsNameFilterField")), findsNothing);

    // Tap on the dropdown button to select a different user
    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Me').last);
    await tester.pumpAndSettle();

    // Verify that the selected user has been updated
    expect(find.text('Me'), findsOneWidget);
    expect(find.byKey(Key("statisticsNameFilterField")), findsNothing);

    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Person').last);
    await tester.pumpAndSettle();

    expect(find.byKey(Key("statisticsNameFilterField")), findsOneWidget);
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

  testWidgets(
      'Map icon tap should navigate to the Map screen with the correct nest',
      (WidgetTester tester) async {
    // Initialize the app
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Check if the 'Common gull ringed' statistic is correct
    final commonGullRingedTile =
        find.widgetWithText(ListTile, 'Common gull nests');
    expect(find.descendant(of: commonGullRingedTile, matching: find.text('1')),
        findsOneWidget);

    // Verify the presence of 'Common gull ringed' statistic
    expect(find.text("Common gull nests"), findsOneWidget);

    expect(
        find.descendant(
            of: commonGullRingedTile, matching: find.byIcon(Icons.map)),
        findsOneWidget,
        reason: "Map icon not found");

    // Tap on the map icon that it is in the common gull ringed tile
    await tester.tap(find.byIcon(Icons.map));
    await tester.pumpAndSettle();

    // Verify that the Map screen is displayed
    expect(find.byType(MapNests), findsOneWidget);
  });

  testWidgets('Statistics can filter yesterday and show narrowed bird items',
      (WidgetTester tester) async {
    final localFirestore = FakeFirebaseFirestore();
    final localSps = MockSharedPreferencesService();
    localSps.speciesList = LocalSpeciesList.fromStringList(["Common gull"]);
    final yesterday = dayOffset(-1);
    final today = dayOffset(0);

    await localFirestore.collection('Birds').doc('YEST1').set(Bird(
          ringed_date: yesterday,
          band: 'YEST1',
          ringed_as_chick: true,
          measures: [],
          responsible: 'Test User',
          species: 'Common gull',
        ).toJson());
    await localFirestore.collection('Birds').doc('TODAY1').set(Bird(
          ringed_date: today,
          band: 'TODAY1',
          ringed_as_chick: true,
          measures: [],
          responsible: 'Test User',
          species: 'Common gull',
        ).toJson());

    await tester.pumpWidget(getStatisticsApp(localFirestore, localSps));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yesterday').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Me').last);
    await tester.pumpAndSettle();

    final totalRingedTile = find.widgetWithText(ListTile, 'Total ringed');
    expect(find.descendant(of: totalRingedTile, matching: find.text('1')),
        findsOneWidget);

    await tester.longPress(totalRingedTile);
    await tester.pumpAndSettle();

    expect(find.byKey(Key("copyStatisticsBirdIdsButton")), findsOneWidget);
    expect(find.text('YEST1'), findsWidgets);
    expect(find.text('TODAY1'), findsNothing);
  });

  testWidgets(
      'Statistics person filter narrows nests and broad total long press is blocked',
      (WidgetTester tester) async {
    final localFirestore = FakeFirebaseFirestore();
    final localSps = MockSharedPreferencesService();
    localSps.speciesList = LocalSpeciesList.fromStringList(["Common gull"]);
    final year = DateTime.now().year;
    final collection =
        localFirestore.collection(yearToNestCollectionName(year));

    await collection.doc('YN1').set(Nest(
          id: 'YN1',
          coordinates: GeoPoint(0, 0),
          accuracy: '3m',
          last_modified: dayOffset(-1),
          discover_date: DateTime(year, 5, 1),
          responsible: 'Other User',
          species: 'Common gull',
          measures: [],
        ).toJson());
    await collection.doc('OTHER1').set(Nest(
          id: 'OTHER1',
          coordinates: GeoPoint(0, 0),
          accuracy: '3m',
          last_modified: dayOffset(-1),
          discover_date: DateTime(year, 5, 1),
          responsible: 'Test User',
          species: 'Common gull',
          measures: [],
        ).toJson());

    await tester.pumpWidget(getStatisticsApp(localFirestore, localSps));
    await tester.pumpAndSettle();

    final totalNestsTile = find.widgetWithText(ListTile, 'Total nests');
    await tester.longPress(totalNestsTile);
    await tester.pumpAndSettle();
    expect(find.text('Narrow filters first'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byKey(Key("statisticsNameFilterField")), findsNothing);
    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Person').last);
    await tester.pumpAndSettle();
    expect(find.byKey(Key("statisticsNameFilterField")), findsOneWidget);

    await tester.enterText(find.byKey(Key("statisticsNameFilterField")), 'YN1');
    await tester.pumpAndSettle();

    expect(find.descendant(of: totalNestsTile, matching: find.text('0')),
        findsOneWidget);

    await tester.enterText(
        find.byKey(Key("statisticsNameFilterField")), 'Test User');
    await tester.pumpAndSettle();

    expect(find.descendant(of: totalNestsTile, matching: find.text('1')),
        findsOneWidget);

    await tester.longPress(totalNestsTile);
    await tester.pumpAndSettle();

    expect(find.byKey(Key("copyStatisticsNestIdsButton")), findsOneWidget);
    expect(find.text('1 nests'), findsOneWidget);
    expect(find.text('ID: OTHER1, Common gull'), findsOneWidget);
    expect(find.text('ID: YN1, Common gull'), findsNothing);
  });
}
