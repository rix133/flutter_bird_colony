//backend selection items
import 'package:flutter_bird_colony/models/firebaseOptionsSelector.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/screens/bird/editBird.dart';
import 'package:flutter_bird_colony/screens/bird/listBirds.dart';
import 'package:flutter_bird_colony/screens/experiment/editExperiment.dart';
import 'package:flutter_bird_colony/screens/experiment/listExperiments.dart';
import 'package:flutter_bird_colony/screens/homepage.dart';
import 'package:flutter_bird_colony/screens/nest/createNest.dart';
import 'package:flutter_bird_colony/screens/nest/editEgg.dart';
import 'package:flutter_bird_colony/screens/nest/editNest.dart';
import 'package:flutter_bird_colony/screens/nest/findNest.dart';
import 'package:flutter_bird_colony/screens/nest/listNests.dart';
import 'package:flutter_bird_colony/screens/settings/editDefaultSettings.dart';
import 'package:flutter_bird_colony/screens/settings/listSpecies.dart';
import 'package:flutter_bird_colony/screens/settings/settings.dart';
import 'package:flutter_bird_colony/screens/statistics.dart';
import 'package:flutter_bird_colony/services/birdsService.dart';
import 'package:flutter_bird_colony/services/experimentsService.dart';
import 'package:flutter_bird_colony/services/speciesService.dart';
import 'package:flutter_bird_colony/services/authService.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'design/styles.dart';
import 'firebase_options_default.dart' as manageBirdColony;
import 'firebase_options_kakrarahu.dart' as kakrarahuColony;
import 'firebase_options_redsquirrel.dart' as redSquirrelColony;
import 'screens/listDatas.dart';
import 'screens/nest/mapCreateNest.dart';
import 'screens/nest/mapNests.dart';
import 'screens/settings/editSpecies.dart';
import 'services/nestsService.dart';
import 'services/sharedPreferencesService.dart';

late FirebaseApp firebaseApp;
String appName = 'unknown';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  String colonyName = sharedPreferences.getString('colonyName') ?? 'testing';

  firebaseApp = await FirebaseOptionsSelector.initialize(colonyName, {
    "testing": manageBirdColony.DefaultFirebaseOptions.currentPlatform,
    "Kakrarahu": kakrarahuColony.DefaultFirebaseOptions.currentPlatform,
    "RedSquirrel": redSquirrelColony.DefaultFirebaseOptions.currentPlatform,
  });
  appName = await FirebaseOptionsSelector.getCurrentSelection();

  final firestore = FirebaseFirestore.instanceFor(app: firebaseApp);
  final auth = FirebaseAuth.instanceFor(app: firebaseApp);

  final authService = AuthService(auth);

  auth.authStateChanges().listen((User? user) {
    handleAuthStateChanges(user, sharedPreferences);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SharedPreferencesService(sharedPreferences),
        ),
        ChangeNotifierProvider(
          create: (_) => NestsService(firestore),
        ),
        ChangeNotifierProvider(
          create: (_) => BirdsService(firestore),
        ),
        ChangeNotifierProvider(create: (_) => ExperimentsService(firestore)),
        ChangeNotifierProvider(create: (_) => SpeciesService(firestore)),
      ],
      child: MyApp(firestore: firestore, authService: authService),
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
  final AuthService authService;

  MyApp({Key? key, required this.firestore, required this.authService})
      : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => MyHomePage(title: appName, auth: authService),
        '/editEgg': (context)=>EditEgg(firestore: firestore),
        '/createNest':(context)=> CreateNest(firestore: firestore),
        '/editNest':(context)=>  EditNest(firestore: firestore),
        '/settings': (context) => SettingsPage(
            firestore: firestore,
            auth: authService,
            testApp: appName == 'testing'),
        '/mapNests': (context) =>
            MapNests(firestore: firestore, auth: authService),
        '/statistics':(context)=> Statistics(firestore: firestore),
        '/mapCreateNest': (context) =>
            MapCreateNest(firestore: firestore, auth: authService),
        '/findNest':(context)=>FindNest(firestore: firestore),
        '/editBird':(context)=>EditBird(firestore: firestore),
        '/listBirds':(context)=>ListBirds(firestore: firestore),
        '/listExperiments':(context)=>ListExperiments(firestore: firestore),
        '/listNests':(context)=>ListNests(firestore: firestore),
        '/editExperiment':(context)=>EditExperiment(firestore: firestore),
        '/editDefaultSettings': (context) =>
            EditDefaultSettings(firestore: firestore, auth: authService),
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
        inputDecorationTheme: inputDecorationTheme,
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



