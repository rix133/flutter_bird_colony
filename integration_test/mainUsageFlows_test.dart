import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/firebase_options.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
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
//flutter drive --driver=test_driver/integration_test.dart --target=integration_test/mainUsageFlows_test.dart -d web-server

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

    Nest newNest = Nest(
      coordinates: GeoPoint(0, 0),
      accuracy: "5.4m",
      last_modified: DateTime.now(),
      discover_date: DateTime.now(),
      responsible: "testuser",
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

    // Log in the user
    try {
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: firebaseApp).signInWithEmailAndPassword(
          email: "testuser@example.com",
          password: "testpassword123"
      );

      print("User logged in with ID: ${userCredential.user?.uid}");
    } catch (e) {
      print('Failed to log in user: $e');
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


  testWidgets("FindNest: search for a nest that does not exist", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //find the find nest button on homepage
    await tester.tap(find.text("find nest"));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '2');
    await tester.tap(find.text("Find nest"));
    await tester.pump(Duration(seconds: 2));
    // Check for the SnackBar
    expect(find.byType(SnackBar), findsOneWidget);
    // Check the text inside the SnackBar
    expect(find.text('Nest 2 does not exist'), findsOneWidget);
  });

  testWidgets("FindNest: search for a nest that exists", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //find the find nest button on homepage
    await tester.tap(find.text("find nest"));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '1');
    await tester.tap(find.text("Find nest"));

    await tester.pump(Duration(seconds: 2));
    await tester.pumpAndSettle();
    //check if routed to nestManage
    expect(find.text('(long press for chick)'), findsOneWidget);


  });

  testWidgets("New nest creation", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //find the add nest button on homepage
    await tester.tap(find.text("add nest"));
    await tester.pumpAndSettle();

    //allow location access
    //await tester.tap(find.text("Allow"));
    //await tester.pumpAndSettle();

  });

}
