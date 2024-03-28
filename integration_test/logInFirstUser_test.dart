import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/firebase_options.dart';
import 'package:flutter_bird_colony/screens/bird/editBird.dart';
import 'package:flutter_bird_colony/screens/bird/listBirds.dart';
import 'package:flutter_bird_colony/screens/experiment/editExperiment.dart';
import 'package:flutter_bird_colony/screens/experiment/listExperiments.dart';
import 'package:flutter_bird_colony/screens/homepage.dart';
import 'package:flutter_bird_colony/screens/listDatas.dart';
import 'package:flutter_bird_colony/screens/nest/createNest.dart';
import 'package:flutter_bird_colony/screens/nest/editEgg.dart';
import 'package:flutter_bird_colony/screens/nest/editNest.dart';
import 'package:flutter_bird_colony/screens/nest/findNest.dart';
import 'package:flutter_bird_colony/screens/nest/listNests.dart';
import 'package:flutter_bird_colony/screens/nest/mapCreateNest.dart';
import 'package:flutter_bird_colony/screens/nest/mapNests.dart';
import 'package:flutter_bird_colony/screens/settings/editDefaultSettings.dart';
import 'package:flutter_bird_colony/screens/settings/editSpecies.dart';
import 'package:flutter_bird_colony/screens/settings/listSpecies.dart';
import 'package:flutter_bird_colony/screens/settings/settings.dart';
import 'package:flutter_bird_colony/screens/statistics.dart';
import 'package:flutter_bird_colony/services/authService.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

//run emulator with the following command:
//firebase emulators:start --only firestore,auth
//to run the test, run the following command in the terminal:
//flutter drive --driver=test_driver/integration_test.dart --target=integration_test/logInFirstUser_test.dart -d web-server

late FirebaseApp firebaseApp;
const String appName = 'Bird Colony nests';

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
            '/editEgg': (context) =>  EditEgg(firestore: firestore),
            '/createNest': (context) =>  CreateNest(firestore: firestore),
            '/editNest': (context) =>  EditNest(firestore: firestore),
            '/settings': (context) => SettingsPage(firestore: firestore),
            '/mapNests': (context) => MapNests(firestore: firestore),
            '/statistics': (context) => Statistics(firestore: firestore),
            '/mapCreateNest': (context) => MapCreateNest(firestore: firestore),
            '/findNest': (context) => FindNest(firestore: firestore),
            '/editBird': (context) => EditBird(firestore: firestore),
            '/listBirds': (context) => ListBirds(firestore: firestore),
            '/listExperiments': (context) => ListExperiments(firestore: firestore),
            '/listNests': (context) => ListNests(firestore: firestore),
            '/editExperiment': (context) => EditExperiment(firestore: firestore),
            '/editDefaultSettings': (context) => EditDefaultSettings(firestore: firestore),
            '/listDatas': (context) => ListDatas(firestore: firestore),
            '/listSpecies': (context) => ListSpecies(firestore: firestore),
            '/editSpecies': (context) => EditSpecies(firestore: firestore),
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
    expect(find.text('Bird Colony nests'), findsOneWidget);

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
