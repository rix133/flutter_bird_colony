import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/experimentDropdown.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/screens/nest/editNest.dart';
import 'package:flutter_bird_colony/screens/nest/findNest.dart';
import 'package:flutter_bird_colony/screens/nest/mapNests.dart';
import 'package:flutter_bird_colony/services/locationService.dart';
import 'package:flutter_bird_colony/utils/year.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockLocationService.dart';
import 'mocks/mockSharedPreferencesService.dart';
import 'testApp.dart';

void main() {
  final authService = MockAuthService();
  final storage = MockFirebaseStorage();
  final sharedPreferencesService = MockSharedPreferencesService();
  final locationAccuracy10 = MockLocationAccuracy10();
  late FakeFirebaseFirestore firestore;

  Bird buildBird({
    required String band,
    String? colorBand,
  }) {
    return Bird(
      ringed_date: DateTime.now(),
      ringed_as_chick: false,
      band: band,
      color_band: colorBand,
      measures: [Measure.note()],
      experiments: [],
    );
  }

  Nest buildNest({required String id}) {
    return Nest(
      id: id,
      coordinates: GeoPoint(58.766218, 23.430432),
      accuracy: "3.22m",
      last_modified: DateTime.now(),
      discover_date: DateTime.now(),
      responsible: "Admin",
      species: "Common gull",
      measures: [Measure.note()],
    );
  }

  TestApp buildApp() {
    return TestApp(
      firestore: firestore,
      sps: sharedPreferencesService,
      app: MaterialApp(
        initialRoute: '/findNest',
        routes: {
          '/findNest': (context) => FindNest(firestore: firestore),
          '/mapNests': (context) =>
              MapNests(firestore: firestore, auth: authService),
          '/editNest': (context) =>
              const Scaffold(body: Text('EditNestScreen')),
          '/editBird': (context) =>
              const Scaffold(body: Text('EditBirdScreen')),
        },
      ),
    );
  }

  TestApp buildAppWithRealEditNest() {
    return TestApp(
      firestore: firestore,
      sps: sharedPreferencesService,
      app: MaterialApp(
        initialRoute: '/findNest',
        routes: {
          '/findNest': (context) => FindNest(firestore: firestore),
          '/editNest': (context) =>
              EditNest(firestore: firestore, storage: storage),
        },
      ),
    );
  }

  setUpAll(() async {
    LocationService.instance = locationAccuracy10;
  });

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore
        .collection('Birds')
        .doc('AA123')
        .set(buildBird(band: 'AA123', colorBand: 'RED1').toJson());
    await firestore
        .collection('Birds')
        .doc('BB234')
        .set(buildBird(band: 'BB234', colorBand: 'RED1').toJson());
    await firestore
        .collection('Birds')
        .doc('CC345')
        .set(buildBird(band: 'CC345', colorBand: 'BLUE2').toJson());

    final nestCollection =
        yearToNestCollectionName(sharedPreferencesService.selectedYear);
    await firestore
        .collection(nestCollection)
        .doc('1')
        .set(buildNest(id: '1').toJson());
    await firestore.collection('experiments').doc('exp1').set(Experiment(
          id: 'exp1',
          name: 'New Experiment',
          description: 'Find nest flow experiment',
          last_modified: DateTime.now(),
          created: DateTime.now(),
          year: sharedPreferencesService.selectedYear,
          responsible: 'Admin',
          type: 'nest',
          nests: [],
          measures: [],
        ).toJson());
  });

  testWidgets("Find nest navigates to edit nest", (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '1');
    await tester.tap(find.byKey(Key('findNestButton')));
    await tester.pumpAndSettle();

    expect(find.text('EditNestScreen'), findsOneWidget);
  });

  testWidgets("Find nest add experiment then save returns to find nest",
      (WidgetTester tester) async {
    await tester.pumpWidget(buildAppWithRealEditNest());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '1');
    await tester.tap(find.byKey(Key('findNestButton')));
    await tester.pumpAndSettle();

    expect(find.byType(EditNest), findsOneWidget);

    await tester.longPress(find.text("(long press to add experiment)"));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    final addButton = find.widgetWithText(ElevatedButton, "Add");
    expect(tester.widget<ElevatedButton>(addButton).onPressed, isNull);

    final experimentDropdownFinder = find.byType(ExperimentDropdown);
    final dropdownButtonFinder = find.descendant(
      of: experimentDropdownFinder,
      matching: find.byType(DropdownButton<String>),
    );
    final dropdownButton =
        tester.widget<DropdownButton<String>>(dropdownButtonFinder);
    dropdownButton.onChanged?.call('New Experiment');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(addButton).onPressed, isNotNull);

    await tester.tap(addButton);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, "Cancel"))
            .onPressed,
        isNull);
    await tester.pumpAndSettle();

    expect(find.byType(EditNest), findsOneWidget);
    expect(find.byType(FindNest), findsNothing);

    final saveButton = find.byKey(Key("saveButton"));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.byType(FindNest), findsOneWidget);
    expect(find.byType(EditNest), findsNothing);
  });

  testWidgets("Find on map navigates to map", (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '1');
    await tester.tap(find.byKey(Key('findNestOnMapButton')));
    await tester.pumpAndSettle();

    expect(find.byType(MapNests), findsOneWidget);
  });

  testWidgets("Can search bird by metal band", (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('findTargetDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bird metal band').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'AA123');
    await tester.tap(find.byKey(Key('findNestButton')));
    await tester.pumpAndSettle();

    expect(find.text('EditBirdScreen'), findsOneWidget);
  });

  testWidgets("Can search bird by color band and select from list",
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('findTargetDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bird color band').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'RED1');
    await tester.tap(find.byKey(Key('findNestButton')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.text('EditBirdScreen'), findsOneWidget);
  });

  testWidgets("Shows snackbar when bird is not found",
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('findTargetDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bird metal band').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'ZZ999');
    await tester.tap(find.byKey(Key('findNestButton')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
        find.text('Bird with metal band ZZ999 does not exist'), findsOneWidget);
  });
}
