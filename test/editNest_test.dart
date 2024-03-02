
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/findNest.dart';

import 'package:kakrarahu/homepage.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/models/nest.dart';
import 'package:kakrarahu/nest/nestManage.dart';
import 'package:kakrarahu/services/authService.dart';
import 'package:kakrarahu/services/locationService.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockLocationService.dart';
import 'mocks/mockSharedPreferencesService.dart';


void main() {
  final authService = MockAuthService();
  final sharedPreferencesService = MockSharedPreferencesService();
  final firestore = FakeFirebaseFirestore();
  MockLocationAccuracy10 locationAccuracy10 = MockLocationAccuracy10();
  late Widget myApp;
  final userEmail = "test@example.com";
  final Nest nest = Nest(
    id: "1",
    coordinates: GeoPoint(0, 0),
    accuracy: "12.22m",
    last_modified: DateTime.now(),
    discover_date: DateTime.now(),
    responsible: "Admin",
    species: "test",
    measures: [Measure.note()],
  );

  setUpAll(() async {
    AuthService.instance = authService;
    LocationService.instance = locationAccuracy10;


    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});
    myApp = ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
        initialRoute: '/nestManage',
        onGenerateRoute: (settings) {
          if (settings.name == '/nestManage') {
            return MaterialPageRoute(
              builder: (context) => NestManage(
                firestore: firestore,
              ),
              settings: RouteSettings(
                arguments: {'nest': nest}, // initial nest object
              ),
            );
          } else if (settings.name == '/findNest') {
            return MaterialPageRoute(
              builder: (context) => FindNest(
                firestore: firestore,
              ),
            );
          }
          // Other routes...
          return MaterialPageRoute(
            builder: (context) => MyHomePage(title: "Nest app"),
          );
        },
      ),
    );


  });

  setUp(() async {
    //reset the database
    await firestore.collection('recent').doc("nest").set({"id":"1"});
    await firestore.collection(DateTime.now().year.toString()).doc(nest.id).set(nest.toJson());

  });

  testWidgets("Will display add egg button", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    expect(find.text('(long press for chick)'), findsOneWidget);
  });

}