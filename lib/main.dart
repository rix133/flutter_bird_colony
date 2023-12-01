import 'package:flutter/material.dart';
import 'package:kakrarahu/homepage.dart';
import 'package:kakrarahu/nestManage.dart';
import 'package:kakrarahu/nestsNearby.dart';
import 'package:kakrarahu/statistics.dart';
import 'design/styles.dart';
import 'findNest.dart';
import "nestCreate.dart";
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'map.dart';
import 'eggs.dart';
import 'bird.dart';
import 'mapforcreate.dart';



void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
class MyApp extends StatelessWidget {


  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    _determinePosition();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context)=>MyHomePage(),
        '/eggs': (context)=>const Eggs(),
        '/pesa':(context)=>const Pesa(),
        '/nestsNearby':(context)=> const NestsNearby(),
        '/nestManage':(context)=> const NestManage(),
        '/map':(context)=> Map(),
        '/statistics':(context)=> Statistics(),
        '/mapforcreate':(context)=>MapForCreate(),
        '/findnest':(context)=>FindNearby(),
        '/individual':(context)=>Individual(),

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
      ),
    );
  }




}


