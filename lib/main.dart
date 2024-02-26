import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/editDefaultSettings.dart';
import 'package:kakrarahu/editEgg.dart';
import 'package:kakrarahu/editExperiment.dart';
import 'package:kakrarahu/editBird.dart';
import 'package:kakrarahu/homepage.dart';
import 'package:kakrarahu/listBirds.dart';
import 'package:kakrarahu/listExperiments.dart';
import 'package:kakrarahu/nest/listNests.dart';
import 'package:kakrarahu/listSpecies.dart';
import 'package:kakrarahu/nest/nestManage.dart';
//import 'package:kakrarahu/nestsNearby.dart';
import 'package:kakrarahu/settings.dart';
import 'package:kakrarahu/statistics.dart';
import 'editSpecies.dart';
import 'listDatas.dart';
import 'services/sharedPreferencesService.dart';
import 'design/styles.dart';
import 'findNest.dart';
import 'nest/nestCreate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'nestsMap.dart';
import 'mapforcreate.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

late FirebaseApp firebaseApp;
const bool useEmulator = false;



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

  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    handleAuthStateChanges(user, sharedPreferences);
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => SharedPreferencesService(sharedPreferences),
      child: MyApp(),
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context)=>MyHomePage(),
        '/editEgg': (context)=>const EditEgg(),
        '/nestCreate':(context)=>const nestCreate(),
        //'/nestsNearby':(context)=> const NestsNearby(),
        '/nestManage':(context)=> const NestManage(),
        '/settings':(context)=>  SettingsPage(),
        '/map':(context)=> NestsMap(),
        '/statistics':(context)=> Statistics(),
        '/mapforcreate':(context)=>MapForCreate(),
        '/findNest':(context)=>FindNest(),
        '/editBird':(context)=>EditBird(),
        '/listBirds':(context)=>ListBirds(),
        '/listExperiments':(context)=>ListExperiments(),
        '/listNests':(context)=>ListNests(),
        '/editExperiment':(context)=>EditExperiment(),
        '/editDefaultSettings':(context)=>EditDefaultSettings(),
        '/listDatas':(context)=>ListDatas(),
        '/listSpecies':(context)=>ListSpecies(),
        '/editSpecies':(context)=>EditSpecies(),


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



