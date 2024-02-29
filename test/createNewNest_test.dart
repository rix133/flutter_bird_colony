
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:kakrarahu/homepage.dart';
import 'package:kakrarahu/mapforcreate.dart';
import 'package:kakrarahu/nest/nestCreate.dart';
import 'package:kakrarahu/services/authService.dart';
import 'package:kakrarahu/services/locationService.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:kakrarahu/settings.dart';
import 'package:provider/provider.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockLocationService.dart';
import 'mocks/mockSharedPreferencesService.dart';


void main() {
  final authService = MockAuthService();
  final sharedPreferencesService = MockSharedPreferencesService();
  final firestore = FakeFirebaseFirestore();
  final locationAccuracy10 = MockLocationAccuracy10();
  late Widget myApp;
  final userEmail = "test@example.com";

  setUpAll(() async {
    AuthService.instance = authService;
    LocationService.instance = locationAccuracy10;


    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});
    myApp = ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (context) => MyHomePage(title: "Nest app"),
            '/settings': (context) => SettingsPage(firestore: firestore),
            '/mapforcreate': (context) => MapForCreate(firestore: firestore),
            '/nestCreate':(context)=>const NestCreate(),
          }
      ),
    );
  });

  testWidgets("Can go to add nest map page", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    await tester.tap(find.text("add nest"));
    await tester.pumpAndSettle();

    expect(find.byType(MapForCreate), findsOneWidget);
  });




}