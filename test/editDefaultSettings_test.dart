import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/design/speciesRawAutocomplete.dart';
import 'package:kakrarahu/models/firestore/defaultSettings.dart';
import 'package:kakrarahu/screens/listMeasures.dart';
import 'package:kakrarahu/screens/settings/editDefaultSettings.dart';
import 'package:kakrarahu/screens/settings/listMarkerColorGroups.dart';
import 'package:kakrarahu/screens/settings/settings.dart';
import 'package:kakrarahu/services/authService.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockSharedPreferencesService.dart';

void main() {
  final authService = MockAuthService();
  final sharedPreferencesService = MockSharedPreferencesService();
  final firestore = FakeFirebaseFirestore();
  late Widget myApp;
  final userEmail = "test@example.com";

  setUpAll(() async {
    AuthService.instance = authService;
    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});
    myApp = ChangeNotifierProvider<SharedPreferencesService>(
        create: (_) => sharedPreferencesService,
        child: MaterialApp(
            home: EditDefaultSettings(firestore: firestore),
            routes: {
              '/settings': (context) => SettingsPage(firestore: firestore),
            }));
  });

  testWidgets('displays some default settings', (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    expect(find.byType(ListMeasures), findsOneWidget);
    expect(find.text("Desired accuracy (m)"), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byType(SpeciesRawAutocomplete), findsOneWidget);
    expect(find.byType(ListMarkerColorGroups), findsOneWidget);
  });

  testWidgets(
      'updates default settings in firestore when save button is pressed',
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(Key("desiredAccuracy")), "3.2");

    final saveButton = find.byKey(Key("saveButton"));
    expect(saveButton, findsOneWidget);

    //ensure visible
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(
        await firestore
            .collection('settings')
            .doc("default")
            .get()
            .then((value) => value.exists),
        true);

    DefaultSettings ds = await firestore
        .collection('settings')
        .doc("default")
        .get()
        .then((value) => DefaultSettings.fromDocSnapshot(value));
    expect(ds.desiredAccuracy, 3.2);
    expect(ds.selectedYear, DateTime.now().year);
  });
  testWidgets(
      'updates default settings in sharedPrefrencesService when save button is pressed',
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key("desiredAccuracy")), "5.2");

    final saveButton = find.byKey(Key("saveButton"));
    expect(saveButton, findsOneWidget);

    //ensure visible
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(sharedPreferencesService.desiredAccuracy, 5.2);
  });

  testWidgets("saves default settings to firestore",
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key("desiredAccuracy")), "3.2");

    //add a measure
    final addMeasureButton = find.byKey(Key("addMeasureButton"));
    expect(addMeasureButton, findsOneWidget);

    //essure the button is visble
    await tester.ensureVisible(addMeasureButton);
    await tester.tap(addMeasureButton);
    await tester.pumpAndSettle();

    //find the edit button under added measure
    final editButton = find.byIcon(Icons.edit);
    expect(editButton, findsNWidgets(2));
    await tester.ensureVisible(editButton.last);
    await tester.tap(editButton.last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key("nameMeasureEdit")), "test measure");

    Finder typeDropdown = find.byKey(Key("typeMeasureEdit"));
    await tester.tap(typeDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text("nest").last);
    await tester.pumpAndSettle();

    //find the 3 switchListTiles  in the alertdialog and toggle them
    final alertDialog = find.byType(AlertDialog);
    final switchListTiles = find.descendant(
      of: alertDialog,
      matching: find.byType(SwitchListTile),
    );
    expect(switchListTiles, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      await tester.tap(switchListTiles.at(i));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(Key("doneMeasureEditButton")));
    await tester.pumpAndSettle();

    final saveButton = find.byKey(Key("saveButton"));
    expect(saveButton, findsOneWidget);

    //ensure visible
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(
        await firestore
            .collection('settings')
            .doc("default")
            .get()
            .then((value) => value.exists),
        true);
    DefaultSettings dfObj = await firestore
        .collection('settings')
        .doc("default")
        .get()
        .then((value) => DefaultSettings.fromDocSnapshot(value));

    expect(dfObj.desiredAccuracy, 3.2);
    expect(dfObj.selectedYear, DateTime.now().year);
    expect(dfObj.autoNextBand, false);
    expect(dfObj.autoNextBandParent, false);
    expect(dfObj.measures.length, 2);
    expect(dfObj.measures[1].name, "test measure");
    expect(dfObj.measures[1].isNumber, true);
    expect(dfObj.measures[1].type, "nest");
    expect(dfObj.measures[1].unit, "");
    expect(dfObj.measures[1].value, "");
    expect(dfObj.measures[1].required, true);
    expect(dfObj.measures[1].repeated, true);
  });
}
