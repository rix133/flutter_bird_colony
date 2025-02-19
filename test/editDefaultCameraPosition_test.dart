import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/defaultSettings.dart';
import 'package:flutter_bird_colony/screens/settings/editDefaultSettings.dart';
import 'package:flutter_bird_colony/screens/settings/settings.dart';
import 'package:flutter_bird_colony/services/authService.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  setUp(() async {
    sharedPreferencesService.defaultLocation = CameraPosition(
      target: LatLng(58.766218, 23.430432),
      bearing: 0,
      zoom: 6,
    );
  });

  testWidgets(
      'updates default  camera position in firestore when default settings are saved',
      (WidgetTester tester) async {
    sharedPreferencesService.defaultLocation = CameraPosition(
      target: LatLng(0, 0),
      bearing: 120,
      zoom: 12,
    );
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //find the map button setDefaultLocation and tap it
    final mapButton = find.byKey(Key("setDefaultMap"));
    expect(mapButton, findsOneWidget);

    await tester.ensureVisible(mapButton);
    await tester.tap(mapButton);
    await tester.pumpAndSettle();

    //find the  setDefaultLocation in the map and tap it
    final setDefaultLocation = find.byKey(Key("setDefaultLocation"));
    expect(setDefaultLocation, findsOneWidget);
    await tester.tap(setDefaultLocation);
    await tester.pumpAndSettle();

    sharedPreferencesService.defaultLocation = CameraPosition(
      target: LatLng(1, 1),
      bearing: 0,
      zoom: 6,
    );

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
    expect(ds.defaultLocation.latitude, 0);
    expect(ds.defaultLocation.longitude, 0);
    expect(ds.defaultCameraZoom, 12);
    expect(ds.defaultCameraBearing, 120);
  });
  testWidgets(
      'updates default camera position in sharedPrefrencesService when default settings are saved',
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //find the map button setDefaultLocation and tap it
    final mapButton = find.byKey(Key("setDefaultMap"));
    expect(mapButton, findsOneWidget);

    await tester.ensureVisible(mapButton);
    await tester.tap(mapButton);
    await tester.pumpAndSettle();

    //find the  setDefaultLocation in the map and tap it
    final setDefaultLocation = find.byKey(Key("setDefaultLocation"));
    expect(setDefaultLocation, findsOneWidget);
    await tester.tap(setDefaultLocation);
    await tester.pumpAndSettle();

    sharedPreferencesService.defaultLocation = CameraPosition(
      target: LatLng(1, 1),
      bearing: 0,
      zoom: 6,
    );

    final saveButton = find.byKey(Key("saveButton"));
    expect(saveButton, findsOneWidget);

    //ensure visible
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(sharedPreferencesService.defaultLocation.target.latitude, 58.766218);
    expect(
        sharedPreferencesService.defaultLocation.target.longitude, 23.430432);
    expect(sharedPreferencesService.defaultLocation.zoom, 6);
    expect(sharedPreferencesService.defaultLocation.bearing, 0);
  });
}
