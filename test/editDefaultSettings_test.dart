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
}
