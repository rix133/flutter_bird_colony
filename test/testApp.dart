import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/services/birdsService.dart';
import 'package:flutter_bird_colony/services/experimentsService.dart';
import 'package:flutter_bird_colony/services/nestsService.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_bird_colony/services/speciesService.dart';
import 'package:provider/provider.dart';

class TestApp extends StatelessWidget {
  final FirebaseFirestore firestore;
  final SharedPreferencesService sps;
  final MaterialApp app;

  const TestApp(
      {Key? key, required this.firestore, required this.sps, required this.app})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => sps,
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
      child: app,
    );
  }
}
