import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakrarahu/findNest.dart';
import 'package:kakrarahu/firebase_options.dart';
import 'package:kakrarahu/homepage.dart';
import 'package:kakrarahu/models/nest.dart';
import 'package:kakrarahu/services/authService.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:kakrarahu/settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

//run emulator with the following command:
//firebase emulators:start --only firestore,auth
//to run the test, run the following command in the terminal:
//flutter drive --driver=test_driver/integration_test.dart --target=integration_test/findNest_test.dart -d web-server

late FirebaseApp firebaseApp;
const String appName = 'Kakrarahu nests';

void main() async{
  final sharedPreferences = await SharedPreferences.getInstance();
  final authService = AuthService();
  final sharedPreferencesService = SharedPreferencesService(sharedPreferences);
  late Widget myApp;

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();



  setUpAll(() async {
    firebaseApp = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
      try {
        // Firestore
        FirebaseFirestore.instanceFor(app: firebaseApp)
            .useFirestoreEmulator('localhost', 8080);
        // Auth
        FirebaseAuth.instanceFor(app: firebaseApp)
            .useAuthEmulator('localhost', 9099);
      } catch (e) {
        print('Error using emulators: $e');
      }
      Nest newNest = Nest(
        coordinates: GeoPoint(0, 0),
        accuracy: "5.4m",
        last_modified: DateTime.now(),
        discover_date: DateTime.now(),
        responsible: "Test User",
        measures: [],
      );
    await FirebaseFirestore.instance.collection(DateTime.now().year.toString()).doc('1').set(
      newNest.toJson()
    );

    // Create a new user
    try {
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: firebaseApp).createUserWithEmailAndPassword(
          email: "testuser@example.com",
          password: "testpassword123"
      );
      FirebaseFirestore.instance.collection('users').doc("testuser@example.com").set({'isAdmin': false});

      print("User created with ID: ${userCredential.user?.uid}");
    } catch (e) {
      print('Failed to create user: $e');
    }

    AuthService.instance = authService;
    myApp = ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
    '/': (context)=>MyHomePage(title: appName),
    '/settings':(context)=> SettingsPage(),
    '/findNest':(context)=>FindNest(),
    },
      ),
    );
  });
  testWidgets("FindNest: search for a nest that does not exist", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);

    //wait for redirects to complete
    await Future.delayed(Duration(seconds: 5));

    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    // Tap the 'Login with email' button
    await tester.tap(find.text('Login with email'));
    await tester.pumpAndSettle();

    // Enter email and password
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'testuser@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'testpassword123');
    await tester.pumpAndSettle();


    // Tap the 'Login' button
    await tester.tap(find.byKey(Key('loginButton')));
    await tester.pumpAndSettle();

    // Wait for the login flow to complete
    await Future.delayed(Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Kakrarahu nests'), findsOneWidget);

    //find the find nest button on homepage
    await tester.tap(find.text("find nest"));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '2');
    await tester.tap(find.text("Find nest"));
    await tester.pumpAndSettle();

    expect(find.text('Nest 2 does not exist'), findsOneWidget);
  });

}
