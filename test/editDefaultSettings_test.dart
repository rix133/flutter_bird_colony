import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/design/speciesRawAutocomplete.dart';
import 'package:kakrarahu/models/firestore/defaultSettings.dart';
import 'package:kakrarahu/screens/listMeasures.dart';
import 'package:kakrarahu/screens/settings/editDefaultSettings.dart';
import 'package:kakrarahu/screens/settings/listMarkerColorGroups.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

import 'mocks/mockSharedPreferencesService.dart';

void main() {
  final sharedPreferencesService = MockSharedPreferencesService();
  final firestore = FakeFirebaseFirestore();
  late Widget myApp;
  final userEmail = "test@example.com";

  setUpAll(() async {
    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});
    myApp = ChangeNotifierProvider<SharedPreferencesService>(
        create: (_) => sharedPreferencesService,
        child: MaterialApp(home: EditDefaultSettings(firestore: firestore)));
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

  testWidgets('updates default settings when save button is pressed',
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
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

    DefaultSettings ds = await firestore
        .collection('settings')
        .doc("default")
        .get()
        .then((value) => DefaultSettings.fromDocSnapshot(value));
    expect(ds.desiredAccuracy, 4.0);
    expect(ds.selectedYear, DateTime.now().year);
  });
}
