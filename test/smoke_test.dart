// Test example for screens

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/screens/experiment/editExperiment.dart';
import 'package:kakrarahu/screens/experiment/listExperiments.dart';
import 'package:kakrarahu/screens/homepage.dart';
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

  getInitApp(dynamic arguments) {
    return ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
        initialRoute: '/editExperiment',
        onGenerateRoute: (settings) {
          if (settings.name == '/editExperiment') {
            return MaterialPageRoute(
              builder: (context) => EditExperiment(
                firestore: firestore,
              ),
              settings: RouteSettings(
                arguments: arguments, // get initial nest from object
              ),
            );
          }
          if (settings.name == '/listExperiments') {
            return MaterialPageRoute(
              builder: (context) => ListExperiments(
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
  }

  setUpAll(() async {
    AuthService.instance = authService;
  });

  testWidgets('Smoke test', (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    expect(find.text("Edit Experiment"), findsOneWidget);
  });
}
