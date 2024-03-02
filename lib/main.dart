import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/screens/settings/editDefaultSettings.dart';
import 'package:kakrarahu/screens/nest/editEgg.dart';
import 'package:kakrarahu/screens/experiment/editExperiment.dart';
import 'package:kakrarahu/screens/bird/editBird.dart';
import 'package:kakrarahu/screens/homepage.dart';
import 'package:kakrarahu/screens/bird/listBirds.dart';
import 'package:kakrarahu/screens/experiment/listExperiments.dart';
import 'package:kakrarahu/screens/nest/listNests.dart';
import 'package:kakrarahu/screens/settings/listSpecies.dart';
import 'package:kakrarahu/screens/nest/nestManage.dart';
import 'package:kakrarahu/screens/settings/settings.dart';
import 'package:kakrarahu/screens/statistics.dart';
import 'screens/settings/editSpecies.dart';
import 'screens/listDatas.dart';
import 'services/sharedPreferencesService.dart';
import 'design/styles.dart';
import 'package:kakrarahu/screens/nest/findNest.dart';
import 'package:kakrarahu/screens/nest/nestCreate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/nest/nestsMap.dart';
import 'screens/nest/mapforcreate.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

late FirebaseApp firebaseApp;
const bool useEmulator = false; // Set to true to use emulators not the real Production Firestore
const String appName = 'Kakrarahu nests';



void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  if (useEmulator) {
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
  }

  final sharedPreferences = await SharedPreferences.getInstance();
  final firestore = FirebaseFirestore.instance;

  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    handleAuthStateChanges(user, sharedPreferences);
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => SharedPreferencesService(sharedPreferences),
      child: MyApp(firestore: firestore),
    ),
  );
}

void handleAuthStateChanges(User? user, SharedPreferences sharedPreferences) {
  if (user == null) {
    //print('User is currently signed out!');
    sharedPreferences.setBool('isLoggedIn', false);
  } else {
    //print('User is signed in as ' + user.displayName.toString());
    sharedPreferences.setBool('isLoggedIn', true);
    sharedPreferences.setString('userName', user.displayName.toString());
  }
}


class MyApp extends StatelessWidget {
  final FirebaseFirestore firestore;
  MyApp({Key? key, required this.firestore}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context)=>MyHomePage(title: appName),
        '/editEgg': (context)=>EditEgg(firestore: firestore),
        '/nestCreate':(context)=> NestCreate(firestore: firestore),
        //'/nestsNearby':(context)=> const NestsNearby(),
        '/nestManage':(context)=>  NestManage(firestore: firestore),
        '/settings':(context)=>  SettingsPage(firestore: firestore),
        '/map':(context)=> NestsMap(firestore: firestore),
        '/statistics':(context)=> Statistics(firestore: firestore),
        '/mapforcreate':(context)=>MapForCreate(firestore: firestore),
        '/findNest':(context)=>FindNest(firestore: firestore),
        '/editBird':(context)=>EditBird(firestore: firestore),
        '/listBirds':(context)=>ListBirds(firestore: firestore),
        '/listExperiments':(context)=>ListExperiments(firestore: firestore),
        '/listNests':(context)=>ListNests(firestore: firestore),
        '/editExperiment':(context)=>EditExperiment(firestore: firestore),
        '/editDefaultSettings':(context)=>EditDefaultSettings(firestore: firestore),
        '/listDatas':(context)=>ListDatas(firestore: firestore),
        '/listSpecies':(context)=>ListSpecies(firestore: firestore),
        '/editSpecies':(context)=>EditSpecies(firestore: firestore),


      },
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(selectionColor: Colors.green[100]),
        hintColor: Colors.yellow,
        textTheme: Typography.whiteCupertino,
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
        primarySwatch: Colors.orange,
        textButtonTheme: TextButtonThemeData(style: flatButtonStyle),
        elevatedButtonTheme: ElevatedButtonThemeData(style: raisedButtonStyle),
        outlinedButtonTheme: OutlinedButtonThemeData(style: outlineButtonStyle),
        listTileTheme: listTileTheme,
        appBarTheme: AppBarTheme(
          color: Colors.black, // This is your AppBar background color
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
    );
  }




}



