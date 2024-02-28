import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakrarahu/editBird.dart';
import 'package:kakrarahu/editDefaultSettings.dart';
import 'package:kakrarahu/editEgg.dart';
import 'package:kakrarahu/editExperiment.dart';
import 'package:kakrarahu/editSpecies.dart';
import 'package:kakrarahu/findNest.dart';
import 'package:kakrarahu/firebase_options.dart';
import 'package:kakrarahu/homepage.dart';
import 'package:kakrarahu/listBirds.dart';
import 'package:kakrarahu/listDatas.dart';
import 'package:kakrarahu/listExperiments.dart';
import 'package:kakrarahu/listSpecies.dart';
import 'package:kakrarahu/mapforcreate.dart';
import 'package:kakrarahu/nest/listNests.dart';
import 'package:kakrarahu/nest/nestCreate.dart';
import 'package:kakrarahu/nest/nestManage.dart';
import 'package:kakrarahu/nestsMap.dart';
import 'package:kakrarahu/services/authService.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:kakrarahu/settings.dart';
import 'package:kakrarahu/statistics.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

//run emulator with the following command:
//firebase emulators:start --only firestore,auth
//to run the test, run the following command in the terminal:
//flutter drive --driver=test_driver/integration_test.dart --target=integration_test/logInFirstUser_test.dart -d web-server

late FirebaseApp firebaseApp;
const String appName = 'Kakrarahu nests';

void main() async{
  final sharedPreferences = await SharedPreferences.getInstance();
  final authService = AuthService();
  final sharedPreferencesService = SharedPreferencesService(sharedPreferences);
  late Widget myApp;

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();



  setUpAll(() async {
    // Initialize Firebase app
    firebaseApp = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Use emulators for Firestore and Auth
    try {
      FirebaseFirestore.instanceFor(app: firebaseApp)
          .useFirestoreEmulator('localhost', 8080);
      FirebaseAuth.instanceFor(app: firebaseApp)
          .useAuthEmulator('localhost', 9099);
    } catch (e) {
      print('Error using emulators: $e');
    }


    // Set up the app
    AuthService.instance = authService;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    myApp = ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
          routes: {
            '/': (context) => MyHomePage(title: appName),
            '/editEgg': (context) => const EditEgg(),
            '/nestCreate': (context) => const nestCreate(),
            '/nestManage': (context) => const NestManage(),
            '/settings': (context) => SettingsPage(firestore: firestore),
            '/map': (context) => NestsMap(),
            '/statistics': (context) => Statistics(),
            '/mapforcreate': (context) => MapForCreate(),
            '/findNest': (context) => FindNest(),
            '/editBird': (context) => EditBird(),
            '/listBirds': (context) => ListBirds(),
            '/listExperiments': (context) => ListExperiments(),
            '/listNests': (context) => ListNests(),
            '/editExperiment': (context) => EditExperiment(),
            '/editDefaultSettings': (context) => EditDefaultSettings(),
            '/listDatas': (context) => ListDatas(),
            '/listSpecies': (context) => ListSpecies(),
            '/editSpecies': (context) => EditSpecies(),
          }
      ),
    );
  });

  Future<WidgetTester> runLoginFlow(WidgetTester tester) async {
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
    await tester.tap(find.text("Create new account"));
    // Wait for the login flow to complete
    await Future.delayed(Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Kakrarahu nests'), findsOneWidget);


    return tester;
  }

  testWidgets("New user login creates an admin user", (WidgetTester tester) async {
    await runLoginFlow(tester);

    // Check if the user is an admin
    final user = FirebaseAuth.instance.currentUser;
    expect(user, isNotNull);
    expect(user!.uid, isNotNull);
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.email).get();
    expect(userDoc.exists, isTrue);
    expect(userDoc.get('isAdmin'), isTrue);
  });



}
